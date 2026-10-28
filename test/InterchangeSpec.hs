{-# LANGUAGE ScopedTypeVariables #-}

-- SPDX-License-Identifier: MPL-2.0

{- | Format models and parser regressions. The separate interchange_driver.hs
and interchange_differential.py exercise independent NumPy/SciPy, ZIP/zlib,
streaming/mmap and optional HDF5/Arrow/ONNX implementations.
-}
module InterchangeSpec (interchangeTests) where

import Data.Binary.Put
import Data.Bits (xor)
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as C
import qualified Data.ByteString.Lazy as L
import Data.Complex (Complex ((:+)))
import Data.Int
import Data.Word
import GHC.Float (castFloatToWord32, castWord32ToFloat)
import HMath.Interchange
import qualified HMath.Matrix as M
import qualified HMath.Tensor as T

lim :: Limits
lim = defaultLimits
ok :: Either a Bool -> Bool
ok = either (const False) id
bad :: Either a b -> Bool
bad (Left _) = True
bad _ = False
same :: Array -> Array -> Bool
same a b =
    arrayDType a == arrayDType b
        && arrayShape a == arrayShape b
        && rawEncode lim LittleEndian COrder a == rawEncode lim LittleEndian COrder b
mk :: DType -> Endian -> [Int] -> Either InterchangeError Array
mk dt en sh = case dt of
    Bool8 -> fromValues lim en sh (take n (cycle [True, False]))
    I8 -> fromValues lim en sh (take n (cycle [minBound, -1, 0, 1, maxBound] :: [Int8]))
    U8 -> fromValues lim en sh (take n (cycle [minBound, 17, 0, 1, maxBound] :: [Word8]))
    I16 -> fromValues lim en sh (take n (cycle [minBound, -1, 0, 1, maxBound] :: [Int16]))
    U16 -> fromValues lim en sh (take n (cycle [minBound, 12345, 0, 1, maxBound] :: [Word16]))
    I32 -> fromValues lim en sh (take n (cycle [minBound, -1, 0, 1, maxBound] :: [Int32]))
    U32 -> fromValues lim en sh (take n (cycle [minBound, 123456789, 0, 1, maxBound] :: [Word32]))
    I64 -> fromValues lim en sh (take n (cycle [minBound, -1, 0, 1, maxBound] :: [Int64]))
    U64 -> fromValues lim en sh (take n (cycle [minBound, 123456789123456789, 0, 1, maxBound] :: [Word64]))
    F32 -> fromValues lim en sh (take n (cycle [-0, 1 / 3, -1e30, 1e-37, 42] :: [Float]))
    F64 -> fromValues lim en sh (take n (cycle [-0, 1 / 3, -1e300, 1e-307, 42] :: [Double]))
    C64 ->
        fromValues lim en sh (take n (cycle [1 :+ (-2), (-0) :+ 3.25, (-5e30) :+ 1e-37] :: [Complex Float]))
    C128 ->
        fromValues
            lim
            en
            sh
            (take n (cycle [1 :+ (-2), (-0) :+ 3.25, (-5e300) :+ 1e-307] :: [Complex Double]))
  where
    n = product sh

interchangeTests :: [(String, Bool)]
interchangeTests =
    roundTrips
        ++ viewModels
        ++ binaryCases
        ++ textCases
        ++ float32TextCases
        ++ numpyCases
        ++ edgeCases
        ++ emptyShapeCases
roundTrips :: [(String, Bool)]
roundTrips =
    [ ( "interchange all-dtype formats " ++ show (dt, en, sh)
      , ok $ do
            a <- mk dt en sh
            b <- encodeBinary lim a >>= decodeBinary lim
            t <- encodeText lim a >>= decodeText lim
            c <- encodeNpy lim COrder a >>= decodeNpy lim
            f <- encodeNpy lim FOrder a >>= decodeNpy lim
            packed <- repack lim (if en == LittleEndian then BigEndian else LittleEndian) FOrder a
            Right (a == b && all (same a) [t, c, f, packed])
      )
    | dt <- [minBound .. maxBound]
    , en <- [LittleEndian, BigEndian]
    , sh <- [[], [0], [2, 0], [3], [2, 3], [2, 1, 2]]
    ]
viewModels :: [(String, Bool)]
viewModels =
    [ ( "interchange view interval model " ++ show (s, t, off)
      , let
            expected = [off + i * s + j * t | i <- [0, 1], j <- [0, 1, 2]]
            valid = all (\i -> i >= 0 && i < 16) expected
            result = array lim U8 LittleEndian [2, 3] [s, t] off (B.pack [0 .. 15])
         in
            if valid
                then
                    ok
                        ( result >>= (toValues :: Array -> Either InterchangeError [Word8]) >>= \xs -> Right (xs == map fromIntegral expected :: Bool)
                        )
                else bad result
      )
    | s <- [-5, -1, 0, 1, 5]
    , t <- [-3, -1, 0, 1, 3]
    , off <- [0, 3, 7, 15]
    ]
binaryCases :: [(String, Bool)]
binaryCases = case fixture of
    Left _ -> [("interchange binary fixture", False)]
    Right bytes ->
        [ ("interchange binary every truncation " ++ show n, bad (decodeBinary lim (B.take n bytes)))
        | n <- [0 .. B.length bytes - 1]
        ]
            ++ [ ( "interchange binary corruption " ++ show n
                 , bad
                    (decodeBinary lim (B.take n bytes <> B.singleton (B.index bytes n `xor` 1) <> B.drop (n + 1) bytes))
                 )
               | n <- [0 .. B.length bytes - 1]
               ]
            ++ [ ("interchange binary future version", bad (decodeBinary lim (rechecksum (replaceByte 8 2 bytes))))
               , ("interchange binary future flags", bad (decodeBinary lim (rechecksum (replaceByte 13 1 bytes))))
               , ("interchange binary invalid dtype", bad (decodeBinary lim (rechecksum (replaceByte 10 255 bytes))))
               , ("interchange binary input byte budget", bad (decodeBinary (lim{maxBytes = 20}) bytes))
               , ("interchange binary rank budget", bad (decodeBinary (lim{maxRank = 1}) bytes))
               ]
  where
    fixture =
        mk F64 BigEndian [2, 3]
            >>= withMetadata lim [("unit", "m/s"), ("title", "온도 λ")]
            >>= encodeBinary lim
    replaceByte i x bytes = B.take i bytes <> B.singleton x <> B.drop (i + 1) bytes
    rechecksum bytes =
        let payload = B.take (B.length bytes - 4) bytes
         in payload <> L.toStrict (runPut (putWord32le (crc32 payload)))

-- The conversion must retain IEEE semantics in debug builds as well as release
-- builds. Compare finite/infinite bits exactly; textual NaNs have no payload.
float32TextCases :: [(String, Bool)]
float32TextCases =
    [ ( "interchange float32 IEEE text " ++ show en
      , ok $ do
            a <- fromValues lim en [1, length values] values
            b <- encodeText lim a >>= decodeText lim
            xs <- toValues b
            Right (length xs == length values && and (zipWith sameFloat values xs))
      )
    | en <- [LittleEndian, BigEndian]
    ]
        ++ [ ( "interchange complex64 IEEE text " ++ show en
             , ok $ do
                let complex = zipWith (:+) values (reverse values)
                a <- fromValues lim en [length complex] complex
                b <- encodeText lim a >>= decodeText lim
                xs <- toValues b
                Right
                    ( length xs == length complex
                        && and (zipWith sameComplex complex xs)
                    )
             )
           | en <- [LittleEndian, BigEndian]
           ]
        ++ [ ( "interchange float32 IEEE delimited " ++ show separator
             , ok $ do
                a <- fromValues lim LittleEndian [1, length values] values
                b <- encodeDelimited lim separator a >>= decodeDelimited lim separator F32
                xs <- toValues b
                Right (length xs == length values && and (zipWith sameFloat values xs))
             )
           | separator <- [',', '\t']
           ]
  where
    values = [castWord32ToFloat 0x80000000, 0, 1 / 0, -1 / 0, 0 / 0, castWord32ToFloat 1]
    sameFloat a b = (isNaN a && isNaN b) || castFloatToWord32 a == castFloatToWord32 b
    sameComplex (a :+ b) (c :+ d) = sameFloat a c && sameFloat b d

textCases :: [(String, Bool)]
textCases =
    [
        ( "interchange CSV exact int64"
        , ok $ do
            a <- fromValues lim LittleEndian [2, 2] [minBound, 9007199254740993, 0, maxBound :: Int64]
            b <- encodeDelimited lim ',' a >>= decodeDelimited lim ',' I64
            Right (same a b)
        )
    ,
        ( "interchange TSV quoted fields"
        , ok $ do
            a <- decodeDelimited lim '\t' F64 (C.pack "\"1.5\"\t-2\r\n3\t\"4\"\n")
            xs <- toValues a
            Right (arrayShape a == [2, 2] && xs == [1.5, -2, 3, 4 :: Double])
        )
    , ("interchange CSV rejects ragged", bad (decodeDelimited lim ',' F64 (C.pack "1,2\n3\n")))
    , ("interchange CSV rejects empty field", bad (decodeDelimited lim ',' F64 (C.pack "1,,2\n")))
    ,
        ( "interchange CSV does not drop shape"
        , ok (mk F64 LittleEndian [0, 3] >>= \a -> Right (bad (encodeDelimited lim ',' a)))
        )
    ,
        ( "interchange zero CSV"
        , ok (decodeDelimited lim ',' F64 B.empty >>= \a -> Right (arrayShape a == [0, 0]))
        )
    ,
        ( "interchange CSV bounded exponent"
        , bad (decodeDelimited lim ',' F64 (C.pack "1e9999999999999999999\n"))
        )
    , ("interchange CSV float overflow", bad (decodeDelimited lim ',' F32 (C.pack "1e300\n")))
    , ("interchange CSV uint overflow", bad (decodeDelimited lim ',' U8 (C.pack "256\n")))
    ,
        ( "interchange MM dense column-major"
        , ok $ do
            a <-
                decodeMatrixMarket
                    lim
                    (C.pack "%%MatrixMarket matrix array real general\n% comment\n2 3\n1\n4\n2\n5\n3\n6\n")
            xs <- toValues a
            Right (xs == [1, 2, 3, 4, 5, 6 :: Double])
        )
    ,
        ( "interchange MM symmetric duplicates"
        , ok $ do
            a <-
                decodeMatrixMarket
                    lim
                    (C.pack "%%MatrixMarket matrix coordinate integer symmetric\n2 2 3\n1 1 2\n2 1 3\n2 1 4\n")
            xs <- toValues a
            Right (xs == [2, 7, 7, 0 :: Int64])
        )
    ,
        ( "interchange MM Hermitian"
        , ok $ do
            a <-
                decodeMatrixMarket
                    lim
                    (C.pack "%%MatrixMarket matrix coordinate complex hermitian\n2 2 2\n1 1 3 0\n2 1 1 2\n")
            xs <- toValues a
            Right (xs == [3 :+ 0, 1 :+ (-2), 1 :+ 2, 0 :+ 0 :: Complex Double])
        )
    ,
        ( "interchange MM skew array"
        , ok $ do
            a <-
                decodeMatrixMarket lim (C.pack "%%MatrixMarket matrix array real skew-symmetric\n3 3\n1\n2\n3\n")
            xs <- toValues a
            Right (xs == [0, -1, -2, 1, 0, -3, 2, 3, 0 :: Double])
        )
    ,
        ( "interchange MM pattern"
        , ok $ do
            a <-
                decodeMatrixMarket lim (C.pack "%%MatrixMarket matrix coordinate pattern general\n2 2 1\n1 2\n")
            xs <- toValues a
            Right (xs == [0, 1, 0, 0 :: Double])
        )
    ,
        ( "interchange MM upper symmetry rejected"
        , bad
            (decodeMatrixMarket lim (C.pack "%%MatrixMarket matrix coordinate real symmetric\n2 2 1\n1 2 1\n"))
        )
    ,
        ( "interchange MM diagonal skew rejected"
        , bad
            ( decodeMatrixMarket
                lim
                (C.pack "%%MatrixMarket matrix coordinate real skew-symmetric\n1 1 1\n1 1 2\n")
            )
        )
    ,
        ( "interchange MM imaginary diagonal rejected"
        , bad
            ( decodeMatrixMarket
                lim
                (C.pack "%%MatrixMarket matrix coordinate complex hermitian\n1 1 1\n1 1 1 1\n")
            )
        )
    ,
        ( "interchange MM dense budget before allocation"
        , bad
            ( decodeMatrixMarket
                lim
                (C.pack "%%MatrixMarket matrix coordinate real general\n999999999 999999999 0\n")
            )
        )
    ,
        ( "interchange MM int duplicate overflow"
        , bad
            ( decodeMatrixMarket
                lim
                (C.pack "%%MatrixMarket matrix coordinate integer general\n1 1 2\n1 1 9223372036854775807\n1 1 1\n")
            )
        )
    ,
        ( "interchange MM float duplicate overflow"
        , bad
            ( decodeMatrixMarket
                lim
                (C.pack "%%MatrixMarket matrix coordinate real general\n1 1 2\n1 1 1e308\n1 1 1e308\n")
            )
        )
    ]
        ++ [ ( "interchange Matrix Market roundtrip " ++ show dt
             , ok $ do
                a <- mk dt BigEndian [2, 3]
                b <- encodeMatrixMarket lim a >>= decodeMatrixMarket lim
                Right (same a b)
             )
           | dt <- [I64, F64, C128]
           ]
numpyCases :: [(String, Bool)]
numpyCases =
    [
        ( "interchange NPY unsupported objects"
        , bad (decodeNpy lim (npy "{'descr':'|O8','shape':(1,), 'fortran_order':False}" (B.replicate 8 0)))
        )
    ,
        ( "interchange NPY duplicate key"
        , bad
            ( decodeNpy
                lim
                (npy "{'descr':'<f8','descr':'<i8','shape':(), 'fortran_order':False}" (B.replicate 8 0))
            )
        )
    ,
        ( "interchange NPY malicious expression"
        , bad (decodeNpy lim (npy "{'descr':__import__('os'),'shape':(), 'fortran_order':False}" B.empty))
        )
    ,
        ( "interchange NPY negative shape"
        , bad (decodeNpy lim (npy "{'descr':'<f8','shape':(-1,), 'fortran_order':False}" B.empty))
        )
    ,
        ( "interchange NPY shape overflow"
        , bad
            (decodeNpy lim (npy "{'descr':'<f8','shape':(99999999999999999999,), 'fortran_order':False}" B.empty))
        )
    ,
        ( "interchange NPY bool payload"
        , bad (decodeNpy lim (npy "{'descr':'|b1','shape':(1,), 'fortran_order':False}" (B.singleton 2)))
        )
    ,
        ( "interchange NPY empty-dimensional preserve"
        , ok
            ( decodeNpy lim (npy "{\"shape\":(2,0), \"fortran_order\":True, \"descr\":\">f8\",}" B.empty) >>= \a -> Right (arrayShape a == [2, 0])
            )
        )
    ]
  where
    npy header payload =
        let pad = (16 - (10 + length header + 1) `mod` 16) `mod` 16
            h = C.pack (header ++ replicate pad ' ' ++ "\n")
         in B.pack [147, 78, 85, 77, 80, 89, 1, 0]
                <> L.toStrict (runPut (putWord16le (fromIntegral (B.length h))))
                <> h
                <> payload
edgeCases :: [(String, Bool)]
edgeCases =
    [ ("interchange CRC independent known answer", crc32 (C.pack "123456789") == 0xcbf43926)
    ,
        ( "interchange raw endian known bytes"
        , ok $ do
            a <- fromValues lim BigEndian [2] [0x1234, 0xabcd :: Word16]
            b <- rawEncode lim LittleEndian COrder a
            Right (arrayBytes a == B.pack [0x12, 0x34, 0xab, 0xcd] && b == B.pack [0x34, 0x12, 0xcd, 0xab])
        )
    ,
        ( "interchange signed-zero IEEE bits"
        , ok $ do
            a <- fromValues lim LittleEndian [] [-0 :: Double]
            Right (arrayBytes a == B.pack [0, 0, 0, 0, 0, 0, 0, 128])
        )
    ,
        ( "interchange NaN payload preserved"
        , ok $ do
            let bytes = B.pack [1, 0, 0, 0, 0, 0, 248, 127]
            a <- rawDecode lim F64 LittleEndian COrder [] bytes
            b <- encodeBinary lim a >>= decodeBinary lim
            c <- encodeNpy lim FOrder a >>= decodeNpy lim
            Right (arrayBytes b == bytes && arrayBytes c == bytes)
        )
    ,
        ( "interchange immutable metadata"
        , ok $ do
            a <- mk U8 LittleEndian [3] >>= withMetadata lim [("x", "m")]
            Right (arrayMetadata a == [("x", "m")] && bad (withMetadata lim [("x", "a"), ("x", "b")] a))
        )
    ,
        ( "interchange metadata surrogate"
        , ok (mk U8 LittleEndian [] >>= \a -> Right (bad (withMetadata lim [("a", ['\xD800'])] a)))
        )
    , ("interchange malformed boolean", bad (array lim Bool8 LittleEndian [1] [1] 0 (B.singleton 2)))
    , ("interchange negative dimension", bad (rawDecode lim I64 LittleEndian COrder [-1] B.empty))
    , ("interchange offset overflow", bad (array lim U64 LittleEndian [2] [maxBound] maxBound B.empty))
    ,
        ( "interchange logical broadcast budget"
        , bad (array (lim{maxElements = 3}) U8 LittleEndian [4] [0] 0 (B.singleton 7))
        )
    , ("interchange infinite shape budget", bad (rawDecode lim U8 LittleEndian COrder (repeat 1) B.empty))
    , ("interchange infinite values budget", bad (fromValues lim LittleEndian [3] (repeat (0 :: Double))))
    ,
        ( "interchange type mismatch"
        , ok (mk F64 LittleEndian [] >>= \a -> Right (bad (toValues a :: Either InterchangeError [Word64])))
        )
    ,
        ( "interchange matrix bridge empty shape"
        , ok $ do
            m <- either (Left . InvalidData . show) Right (M.fromListChecked 0 3 ([] :: [Double]))
            a <- fromMatrix lim LittleEndian m
            n <- toMatrix a
            Right (M.shape n == (0, 3) && M.toList n == ([] :: [Double]))
        )
    ,
        ( "interchange tensor bridge strided"
        , ok $ do
            t <-
                either (Left . InvalidData . show) Right (T.tensor [2, 3] [0 .. 5 :: Double] >>= T.swapAxes 0 1)
            a <- fromTensor lim BigEndian t
            n <- toTensor a
            Right (T.tensorShape n == [3, 2] && T.tensorValues n == [0, 3, 1, 4, 2, 5 :: Double])
        )
    ]

-- A zero inner axis must make work independent of the outer dimension.
emptyShapeCases :: [(String, Bool)]
emptyShapeCases =
    [ ( "interchange huge empty shape " ++ show (dt, sh)
      , ok $ do
            a <- rawDecode lim dt LittleEndian COrder sh B.empty
            encoded <- encodeBinary lim a >>= decodeBinary lim
            packed <- repack lim BigEndian FOrder a
            raw <- rawEncode lim LittleEndian COrder packed
            text <- encodeText lim a >>= decodeText lim
            npy <- encodeNpy lim FOrder a >>= decodeNpy lim
            Right (all ((== sh) . arrayShape) [encoded, packed, text, npy] && B.null raw)
      )
    | dt <- [Bool8, U8, F64]
    , sh <- [[maxBound, 0], [0, maxBound], [maxBound, 0, maxBound]]
    ]
        ++ [ ( "interchange huge empty Matrix Market " ++ show (dt, sh)
             , ok $ do
                a <- rawDecode lim dt LittleEndian COrder sh B.empty
                b <- encodeMatrixMarket lim a >>= decodeMatrixMarket lim
                Right (arrayShape b == sh && elementCount b == 0)
             )
           | dt <- [I64, F64, C128]
           , sh <- [[maxBound, 0], [0, maxBound]]
           ]
        ++ [
               ( "interchange huge empty tensor bridge"
               , ok $ do
                    t <- either (Left . InvalidData . show) Right (T.tensor [maxBound, 0] ([] :: [Double]))
                    a <- fromTensor lim LittleEndian t
                    Right (arrayShape a == [maxBound, 0] && B.null (arrayBytes a))
               )
           ]
