-- SPDX-License-Identifier: MPL-2.0

{- | HMath array wire format version 1. All structural integers are little
endian, independent of the explicit payload endian. Header fields: 8-byte
magic @HMARRAY\\0@, u16 version, u8 dtype/endian/rank/flags, u64 offset and
backing length, u32 metadata length, rank*(u64 shape,i64 byte stride), UTF-8
length-prefixed metadata, backing bytes, u32 CRC-32/ISO-HDLC of everything
preceding the checksum. Unknown versions, flags and trailing bytes fail.
CRC detects accidental corruption, not malicious modification.
-}
module HMath.Interchange.Binary (encodeBinary, decodeBinary, crc32, runDecoder) where

import Control.Monad (replicateM, unless, when)
import Data.Array.Unboxed (UArray, listArray, (!))
import Data.Binary.Get
import Data.Binary.Put
import Data.Bits
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as C
import qualified Data.ByteString.Lazy as L
import qualified Data.Text as T
import qualified Data.Text.Encoding as E
import Data.Word
import HMath.Interchange.Array

-- | Standard CRC-32, compatible with ZIP and zlib, with a fixed 256-entry table.
crc32 :: B.ByteString -> Word32
crc32 = complement . B.foldl' step 0xffffffff
  where
    step c x = (c `shiftR` 8) `xor` (crcTable ! fromIntegral ((c `xor` fromIntegral x) .&. 255))

crcTable :: UArray Int Word32
crcTable = listArray (0, 255) [iterate bitStep (fromIntegral n) !! 8 | n <- [0 :: Int .. 255]]
  where
    bitStep x = if x .&. 1 == 1 then (x `shiftR` 1) `xor` 0xedb88320 else x `shiftR` 1

-- | Strict, exact decoder: trailing bytes are an error rather than ignored.
runDecoder :: Get a -> B.ByteString -> Either InterchangeError a
runDecoder parser bytes = case runGetOrFail parser (L.fromStrict bytes) of
    Left (_, offset, err) -> Left (InvalidData ("byte " ++ show offset ++ ": " ++ err))
    Right (rest, _, value) | L.null rest -> Right value
    _ -> Left (InvalidData "trailing bytes")

magic :: B.ByteString
magic = C.pack "HMARRAY\0"
putMeta :: [(String, String)] -> Put
putMeta meta = do
    putWord32le (fromIntegral (length meta))
    mapM_ (\(k, v) -> putString k >> putString v) meta
  where
    putString s = let b = E.encodeUtf8 (T.pack s) in putWord32le (fromIntegral (B.length b)) >> putByteString b
encodeBinary :: Limits -> Array -> Either InterchangeError B.ByteString
encodeBinary lim a = do
    _ <-
        array
            lim
            (arrayDType a)
            (arrayEndian a)
            (arrayShape a)
            (arrayStrides a)
            (arrayOffset a)
            (arrayBytes a)
    _ <- withMetadata lim (arrayMetadata a) a
    let meta = L.toStrict (runPut (putMeta (arrayMetadata a)))
        total =
            38
                + 16 * toInteger (length (arrayShape a))
                + toInteger (B.length meta)
                + toInteger (B.length (arrayBytes a))
    guardI
        (B.length meta <= maxMetadata lim && total <= toInteger (maxBytes lim))
        (LimitExceeded "binary output bytes")
    let content =
            L.toStrict
                ( runPut $ do
                    putByteString magic
                    putWord16le 1
                    putWord8 (fromIntegral (fromEnum (arrayDType a)))
                    putWord8 (if arrayEndian a == LittleEndian then 0 else 1)
                    putWord8 (fromIntegral (length (arrayShape a)))
                    putWord8 0
                    putWord64le (fromIntegral (arrayOffset a))
                    putWord64le (fromIntegral (B.length (arrayBytes a)))
                    putWord32le (fromIntegral (B.length meta))
                    sequence_
                        [ putWord64le (fromIntegral d) >> putInt64le (fromIntegral s)
                        | (d, s) <- zip (arrayShape a) (arrayStrides a)
                        ]
                    putByteString meta
                    putByteString (arrayBytes a)
                )
    Right (content <> L.toStrict (runPut (putWord32le (crc32 content))))
decodeBinary :: Limits -> B.ByteString -> Either InterchangeError Array
decodeBinary lim input = do
    checkLimits lim
    guardI (B.length input <= maxBytes lim) (LimitExceeded "binary input bytes")
    guardI (B.length input >= 42) (InvalidData "truncated binary header")
    let (content, checksum) = B.splitAt (B.length input - 4) input
    stored <- runDecoder getWord32le checksum
    guardI (stored == crc32 content) (InvalidData "CRC-32 mismatch")
    (dt, en, sh, st, off, payload, meta) <- runDecoder parser content
    a <- array lim dt en sh st off payload
    withMetadata lim meta a
  where
    failUnless b s = unless b (fail s)
    size :: String -> Int -> Word64 -> Get Int
    size name cap n =
        if n <= fromIntegral cap && n <= fromIntegral (maxBound :: Int)
            then pure (fromIntegral n)
            else fail (name ++ " limit")
    parser = do
        m <- getByteString 8
        failUnless (m == magic) "bad magic"
        version <- getWord16le
        failUnless (version == 1) "unsupported format version"
        typ <- getWord8
        failUnless (fromIntegral typ <= fromEnum (maxBound :: DType)) "unsupported dtype"
        endian <- getWord8
        failUnless (endian <= 1) "invalid endian"
        rank <- getWord8
        failUnless (fromIntegral rank <= maxRank lim) "rank limit"
        flags <- getWord8
        failUnless (flags == 0) "unsupported flags"
        off <- getWord64le >>= size "offset" (maxBytes lim)
        len <- getWord64le >>= size "payload" (maxBytes lim)
        mlen <- getWord32le >>= size "metadata" (maxMetadata lim) . fromIntegral
        ds <-
            replicateM
                (fromIntegral rank)
                ( do
                    d <- getWord64le >>= size "dimension" (maxBound :: Int)
                    s <- getInt64le
                    failUnless
                        (toInteger s >= toInteger (minBound :: Int) && toInteger s <= toInteger (maxBound :: Int))
                        "stride integer overflow"
                    pure (d, fromIntegral s)
                )
        let sh = map fst ds
            st = map snd ds
        either (fail . show) (const (pure ())) (validateShape lim sh)
        mb <- getByteString mlen
        meta <- either (fail . show) pure (runDecoder metaParser mb)
        payload <- getByteString len
        pure
            ( toEnum (fromIntegral typ)
            , if endian == 0 then LittleEndian else BigEndian
            , sh
            , st
            , off
            , payload
            , meta
            )
    metaParser = do
        count <- getWord32le
        when (toInteger count > toInteger (maxMetadata lim `div` 8)) (fail "metadata entry count")
        replicateM (fromIntegral count) ((,) <$> getString <*> getString)
    getString = do
        len <- getWord32le >>= size "metadata string" (maxMetadata lim) . fromIntegral
        bytes <- getByteString len
        either (const (fail "invalid UTF-8")) (pure . T.unpack) (E.decodeUtf8' bytes)
