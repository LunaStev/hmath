{-# LANGUAGE ForeignFunctionInterface #-}

-- SPDX-License-Identifier: MPL-2.0

{- | Optional zlib codecs with an explicit hard decompression budget. No shell
process, temporary files, or implicit fallback. A disabled build returns
Unsupported. gzip decoding accepts one member and rejects trailing bytes.
-}
module HMath.Interchange.Compression (Compression (..), compressionAvailable, compress, decompress) where

import qualified Data.ByteString as B
import qualified Data.ByteString.Internal as BI
import Foreign
import Foreign.C.Types
import HMath.Interchange.Array

-- | Wire wrappers around the same DEFLATE coding.
data Compression = RawDeflate | Zlib | Gzip deriving (Eq, Show, Enum)

foreign import ccall unsafe "hmath_interchange_has_zlib" c_available :: IO CInt
foreign import ccall safe "hmath_interchange_compress"
    c_compress :: CInt -> CInt -> Ptr Word8 -> CSize -> Ptr Word8 -> CSize -> Ptr CSize -> IO CInt
compressionAvailable :: IO Bool
compressionAvailable = (/= 0) <$> c_available
compress :: Limits -> Compression -> B.ByteString -> IO (Either InterchangeError B.ByteString)
compress lim wrapper input =
    -- zlib's conservative deflate bound plus wrapper slack, capped by the
    -- caller budget. This avoids allocating the entire budget for tiny data.
    let n = toInteger (B.length input)
        bound = n + (n + 7) `div` 8 + (n + 63) `div` 64 + 64
        capacity = fromInteger (min (toInteger (maxBytes lim)) bound)
     in codec lim False wrapper capacity input

{- | The output length may be smaller than the budget. Archives additionally
compare it to the declared member size before accepting their payload.
-}
decompress ::
    Limits -> Compression -> Int -> B.ByteString -> IO (Either InterchangeError B.ByteString)
decompress lim wrapper cap = codec lim True wrapper cap

codec ::
    Limits -> Bool -> Compression -> Int -> B.ByteString -> IO (Either InterchangeError B.ByteString)
codec lim decode wrapper cap input = case valid of
    Left err -> pure (Left err)
    Right () -> do
        available <- compressionAvailable
        if not available
            then pure (Left (Unsupported "built without interchange-zlib"))
            else B.useAsCStringLen input $ \(source, len) -> alloca $ \written -> do
                -- One spare byte distinguishes an exact zero-size decode from
                -- an output that requires bytes, without a zero-sized buffer.
                let capacity = max 1 cap
                (bytes, status) <- BI.createAndTrim' capacity $ \dest -> do
                    poke written 0
                    result <-
                        c_compress
                            (if decode then 1 else 0)
                            (fromIntegral (fromEnum wrapper))
                            (castPtr source)
                            (fromIntegral len)
                            dest
                            (fromIntegral capacity)
                            written
                    size <- peek written
                    pure (0, if result == 0 && size <= fromIntegral cap then fromIntegral size else 0, (result, size))
                pure $ case status of
                    (0, n) | n <= fromIntegral cap -> Right bytes
                    (-3, _) -> Left (LimitExceeded "decompressed/compressed output budget")
                    (0, _) -> Left (LimitExceeded "decompressed output budget")
                    _ -> Left (InvalidData "invalid/truncated compressed stream or trailing bytes")
  where
    valid = do
        checkLimits lim
        guardI
            ( B.length input <= maxBytes lim
                && cap >= 0
                && cap <= maxBytes lim
                && toInteger cap < toInteger (maxBound :: Word32)
                && toInteger (B.length input) < toInteger (maxBound :: Word32)
            )
            (LimitExceeded "compression input/output size")
