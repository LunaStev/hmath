{-# LANGUAGE ScopedTypeVariables #-}

-- SPDX-License-Identifier: MPL-2.0

{- | Bounded ASCII numeric formats. HMath text v1 preserves dtype, shape and
endian, packing values in row order; metadata/padding/NaN payload bits are
binary-only. CSV/TSV are strict rectangular numeric tables, with optional
quoted scalar fields, no header or comments. Matrix Market follows NIST's
column-order array and one-based coordinate conventions:
<https://math.nist.gov/MatrixMarket/formats.html>.
-}
module HMath.Interchange.Text (
    encodeText,
    decodeText,
    encodeDelimited,
    decodeDelimited,
    encodeMatrixMarket,
    decodeMatrixMarket,
) where

import Control.Monad (unless)
import qualified Data.Array as A
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as C
import Data.Complex (Complex ((:+)), conjugate, imagPart, realPart)
import Data.Int
import Data.List (intercalate)
import qualified Data.Map.Strict as M
import Data.Word
import GHC.Float (double2Float)
import HMath.Interchange.Array
import Text.Read (readMaybe)

ascii :: Limits -> B.ByteString -> Either InterchangeError String
ascii lim bytes = do
    checkLimits lim
    guardI (B.length bytes <= maxBytes lim) (LimitExceeded "text bytes")
    guardI
        (B.all (\x -> x == 9 || x == 10 || x == 13 || x >= 32 && x <= 126) bytes)
        (InvalidData "expected ASCII numeric text")
    Right (C.unpack bytes)
output :: Limits -> String -> Either InterchangeError B.ByteString
output lim s = do
    checkLimits lim
    guardI (length (take (maxBytes lim + 1) s) <= maxBytes lim) (LimitExceeded "text output bytes")
    Right (C.pack s)
readInteger :: String -> Either InterchangeError Integer
readInteger s = do
    guardI
        ( not (null s)
            && length (take 130 s) <= 129
            && all (\c -> c >= '0' && c <= '9') (if take 1 s == "-" || take 1 s == "+" then drop 1 s else s)
        )
        (InvalidData "invalid integer")
    maybe
        (Left (InvalidData "invalid integer"))
        Right
        (readMaybe (if take 1 s == "+" then drop 1 s else s))
readBounded :: forall a. (Integral a, Bounded a) => String -> Either InterchangeError a
readBounded s = do
    n <- readInteger s
    guardI
        (n >= toInteger (minBound :: a) && n <= toInteger (maxBound :: a))
        (InvalidData "integer dtype overflow")
    Right (fromInteger n)
readReal :: String -> Either InterchangeError Double
readReal "nan" = Right (0 / 0)
readReal "inf" = Right (1 / 0)
readReal "+inf" = Right (1 / 0)
readReal "-inf" = Right (-1 / 0)
readReal s = do
    guardI (length (take 129 s) <= 128) (LimitExceeded "numeric token")
    let exponentPart = dropWhile (\c -> c /= 'e' && c /= 'E') s
    unless (null exponentPart) $ do
        e <- readInteger (drop 1 exponentPart)
        guardI (abs e <= 10000) (LimitExceeded "decimal exponent")
    x <-
        maybe
            (Left (InvalidData "invalid floating number"))
            Right
            (readMaybe (if take 1 s == "+" then drop 1 s else s))
    guardI (not (isNaN x || isInfinite x)) (InvalidData "numeric overflow; use explicit inf/nan")
    Right x
showReal :: (RealFloat a, Show a) => a -> String
showReal x | isNaN x = "nan" | isInfinite x = if x > 0 then "inf" else "-inf" | otherwise = show x
readComplex :: String -> Either InterchangeError (Complex Double)
readComplex s = case break (== ',') s of
    (a, ',' : b) -> (:+) <$> readReal a <*> readReal b
    _ -> Left (InvalidData "complex token must be real,imaginary")
showComplex :: (RealFloat a, Show a) => Complex a -> String
showComplex (a :+ b) = showReal a ++ "," ++ showReal b
valueTokens :: Array -> Either InterchangeError [String]
valueTokens a = case arrayDType a of
    Bool8 -> map (\x -> if x then "1" else "0") <$> (toValues a :: Either InterchangeError [Bool])
    I8 -> map show <$> (toValues a :: Either InterchangeError [Int8])
    U8 -> map show <$> (toValues a :: Either InterchangeError [Word8])
    I16 -> map show <$> (toValues a :: Either InterchangeError [Int16])
    U16 -> map show <$> (toValues a :: Either InterchangeError [Word16])
    I32 -> map show <$> (toValues a :: Either InterchangeError [Int32])
    U32 -> map show <$> (toValues a :: Either InterchangeError [Word32])
    I64 -> map show <$> (toValues a :: Either InterchangeError [Int64])
    U64 -> map show <$> (toValues a :: Either InterchangeError [Word64])
    F32 -> map showReal <$> (toValues a :: Either InterchangeError [Float])
    F64 -> map showReal <$> (toValues a :: Either InterchangeError [Double])
    C64 -> map showComplex <$> (toValues a :: Either InterchangeError [Complex Float])
    C128 -> map showComplex <$> (toValues a :: Either InterchangeError [Complex Double])
parseValues :: Limits -> DType -> Endian -> [Int] -> [String] -> Either InterchangeError Array
parseValues lim dt en sh ss = do
    n <- validateShape lim sh
    guardI (length (take (n + 1) ss) == n) (InvalidData "numeric value count mismatch")
    case dt of
        Bool8 ->
            mapM
                ( \s -> case s of
                    "0" -> Right False
                    "1" -> Right True
                    _ -> Left (InvalidData "invalid bool")
                )
                ss
                >>= fromValues lim en sh
        I8 -> (mapM readBounded ss :: Either InterchangeError [Int8]) >>= fromValues lim en sh
        U8 -> (mapM readBounded ss :: Either InterchangeError [Word8]) >>= fromValues lim en sh
        I16 -> (mapM readBounded ss :: Either InterchangeError [Int16]) >>= fromValues lim en sh
        U16 -> (mapM readBounded ss :: Either InterchangeError [Word16]) >>= fromValues lim en sh
        I32 -> (mapM readBounded ss :: Either InterchangeError [Int32]) >>= fromValues lim en sh
        U32 -> (mapM readBounded ss :: Either InterchangeError [Word32]) >>= fromValues lim en sh
        I64 -> (mapM readBounded ss :: Either InterchangeError [Int64]) >>= fromValues lim en sh
        U64 -> (mapM readBounded ss :: Either InterchangeError [Word64]) >>= fromValues lim en sh
        F32 -> mapM (readReal >=> floatChecked) ss >>= fromValues lim en sh
        F64 -> mapM readReal ss >>= fromValues lim en sh
        C64 -> mapM (readComplex >=> complexChecked) ss >>= fromValues lim en sh
        C128 -> mapM readComplex ss >>= fromValues lim en sh
  where
    (>=>) f g x = f x >>= g
    floatChecked x =
        -- realToFrac falls back to a rational conversion without optimization,
        -- which loses signed zero and does not preserve NaN or infinity.
        let y = double2Float x
         in if not (isInfinite x || isNaN x) && isInfinite y
                then Left (InvalidData "float32 overflow")
                else Right y
    complexChecked (a :+ b) = (:+) <$> floatChecked a <*> floatChecked b
encodeText :: Limits -> Array -> Either InterchangeError B.ByteString
encodeText lim a = do
    values <- valueTokens a
    let sh = arrayShape a
    output
        lim
        ( unwords
            ( [ "HMATH-TEXT"
              , "1"
              , show (arrayDType a)
              , if arrayEndian a == LittleEndian then "little" else "big"
              , show (length sh)
              ]
                ++ map show sh
            )
            ++ "\n"
            ++ unlines values
        )
decodeText :: Limits -> B.ByteString -> Either InterchangeError Array
decodeText lim bs = do
    s <- ascii lim bs
    case lines s of
        header : rest -> case words header of
            "HMATH-TEXT" : "1" : dt : en : r : ds -> do
                typ <-
                    maybe
                        (Left (Unsupported "text dtype"))
                        Right
                        (lookup dt [(show t, t) | t <- [minBound .. maxBound]])
                endian <- case en of
                    "little" -> Right LittleEndian
                    "big" -> Right BigEndian
                    _ -> Left (InvalidData "text endian")
                rank <- readInteger r >>= boundedInt "text rank" (toInteger (maxRank lim))
                guardI (length ds == rank) (InvalidData "shape rank mismatch")
                sh <- mapM (readInteger >=> boundedInt "dimension" (toInteger (maxBound :: Int))) ds
                parseValues lim typ endian sh (words (unlines rest))
            _ -> Left (Unsupported "text header/version")
        _ -> Left (InvalidData "empty text")
  where
    (>=>) f g x = f x >>= g
encodeDelimited :: Limits -> Char -> Array -> Either InterchangeError B.ByteString
encodeDelimited lim separator a = do
    guardI (separator == ',' || separator == '\t') (InvalidData "separator must be comma or tab")
    guardI
        (arrayDType a /= C64 && arrayDType a /= C128)
        (Unsupported "complex CSV requires an explicit column schema")
    case arrayShape a of
        [r, c] -> do
            guardI
                ((r > 0 && c > 0) || (r == 0 && c == 0))
                (Unsupported "CSV cannot preserve a single zero dimension")
            values <- valueTokens a
            let rows [] = []
                rows xs = let (row, rest) = splitAt c xs in row : rows rest
            output lim (concatMap ((++ "\n") . intercalate [separator]) (rows values))
        _ -> Left (InvalidData "CSV requires rank two")
decodeDelimited :: Limits -> Char -> DType -> B.ByteString -> Either InterchangeError Array
decodeDelimited lim separator dt bs = do
    guardI (separator == ',' || separator == '\t') (InvalidData "separator must be comma or tab")
    guardI (dt /= C64 && dt /= C128) (Unsupported "complex CSV")
    s <- ascii lim bs
    let rows = map (split separator . filter (/= '\r')) (lines s)
        cols = case rows of
            [] -> 0
            row : _ -> length row
    guardI
        (all ((== cols) . length) rows && all (all (not . null)) rows)
        (InvalidData "ragged/empty CSV field")
    tokens <- mapM quoted (concat rows)
    parseValues lim dt LittleEndian [length rows, cols] tokens
  where
    split c s = case break (== c) s of
        (a, []) -> [a]
        (a, _ : rest) -> a : split c rest
    trim = reverse . dropWhile (== ' ') . reverse . dropWhile (== ' ')
    quoted field =
        let t = trim field
         in case t of
                '"' : xs | not (null xs) && last xs == '"' && '"' `notElem` init xs -> Right (init xs)
                _ | '"' `notElem` t -> Right t
                _ -> Left (InvalidData "invalid quoted numeric CSV field")

-- | Dense general Matrix Market; exact Int64, Float64, or Complex128.
encodeMatrixMarket :: Limits -> Array -> Either InterchangeError B.ByteString
encodeMatrixMarket lim a = do
    field <- case arrayDType a of
        I64 -> Right "integer"
        F64 -> Right "real"
        C128 -> Right "complex"
        _ -> Left (Unsupported "Matrix Market output dtype")
    case arrayShape a of
        [r, c] -> do
            vals <- valueTokens a
            guardI
                (all (all (`notElem` ["nan", "inf", "-inf"]) . splitComplex) vals)
                (InvalidData "nonfinite Matrix Market output")
            let table = A.listArray (0, length vals - 1) vals
            output
                lim
                ( "%%MatrixMarket matrix array "
                    ++ field
                    ++ " general\n"
                    ++ show r
                    ++ " "
                    ++ show c
                    ++ "\n"
                    ++ unlines
                        [ map (\x -> if x == ',' then ' ' else x) (table A.! (i * c + j))
                        | (i, j) <- columnIndices r c
                        ]
                )
        _ -> Left (InvalidData "Matrix Market requires rank two")
  where
    splitComplex s = case break (== ',') s of
        (x, []) -> [x]
        (x, _ : y) -> [x, y]

{- | Array and coordinate input, real/integer/complex/pattern fields and
general/symmetric/skew-symmetric/Hermitian storage. Coordinate duplicates
are added exactly for integers and checked for finite overflow for floats.
Dense output is bounded by maxElements even for sparse input.
-}
decodeMatrixMarket :: Limits -> B.ByteString -> Either InterchangeError Array
decodeMatrixMarket lim bs = do
    s <- ascii lim bs
    case lines s of
        header : rest -> case words header of
            ["%%MatrixMarket", "matrix", storage, field, sym] -> do
                guardI
                    ( storage `elem` ["array", "coordinate"]
                        && field `elem` ["real", "integer", "complex", "pattern"]
                        && sym `elem` ["general", "symmetric", "skew-symmetric", "hermitian"]
                    )
                    (Unsupported "Matrix Market schema")
                guardI (storage == "coordinate" || field /= "pattern") (InvalidData "array pattern is invalid")
                let meaningful = [words l | l <- rest, not (null (words l)), take 1 (dropWhile (== ' ') l) /= "%"]
                case meaningful of
                    dims : entries -> do
                        sizes <- mapM (readInteger >=> boundedInt "Matrix Market size" (toInteger (maxBound :: Int))) dims
                        (r, c, n) <- case (storage, sizes) of
                            ("array", [r, c]) -> Right (r, c, length entries)
                            ("coordinate", [r, c, n]) -> Right (r, c, n)
                            _ -> Left (InvalidData "Matrix Market dimensions")
                        _ <- validateShape lim [r, c]
                        guardI (sym == "general" || r == c) (InvalidData "symmetric matrix must be square")
                        guardI
                            (n <= maxElements lim && length (take (n + 1) entries) == n)
                            (InvalidData "Matrix Market entry count")
                        let positions =
                                [ (i, j)
                                | (i, j) <- columnIndices r c
                                , sym == "general" || if sym == "skew-symmetric" then i > j else i >= j
                                ]
                        coords <-
                            if storage == "array"
                                then do
                                    guardI (length (take (n + 1) positions) == n) (InvalidData "Matrix Market array count")
                                    Right (zip positions entries)
                                else mapM (coordinate r c) entries
                        if field == "integer" then decodeInts r c sym coords else decodeFloats r c field sym coords
                    _ -> Left (InvalidData "missing Matrix Market dimensions")
            _ -> Left (InvalidData "Matrix Market header")
        _ -> Left (InvalidData "empty Matrix Market")
  where
    (>=>) f g x = f x >>= g
    coordinate r c (i : j : xs) = do
        row <- readInteger i
        col <- readInteger j
        guardI
            (row >= 1 && row <= toInteger r && col >= 1 && col <= toInteger c)
            (InvalidData "coordinate out of range")
        Right ((fromInteger row - 1, fromInteger col - 1), xs)
    coordinate _ _ _ = Left (InvalidData "coordinate record")
    expand sym ((i, j), x)
        | sym == "general" || i == j = [((i, j), x)]
        | sym == "skew-symmetric" = [((i, j), x), ((j, i), negate x)]
        | otherwise = [((i, j), x), ((j, i), x)]
    lower sym ((i, j), _) = guardI (sym == "general" || i >= j) (InvalidData "symmetric entries must be lower triangular")
    one [s] = Right s
    one _ = Left (InvalidData "scalar record arity")
    decodeInts r c sym coords = do
        mapM_ (lower sym) coords
        parsed <-
            mapM
                ( \(ij, xs) -> do
                    token <- one xs
                    x <- readInteger token
                    Right (ij, x)
                )
                coords
        guardI
            (sym /= "skew-symmetric" || all (\((i, j), x) -> i /= j || x == 0) parsed)
            (InvalidData "skew diagonal must be zero")
        let table = M.fromListWith (+) (concatMap (expand sym) parsed)
        xs <-
            mapM
                (\ij -> readBounded (show (M.findWithDefault 0 ij table)))
                (rowIndices r c)
        fromValues lim LittleEndian [r, c] (xs :: [Int64])
    decodeFloats r c field sym coords = do
        mapM_ (lower sym) coords
        parsed <-
            mapM
                ( \(ij, xs) -> do
                    x <- case (field, xs) of
                        ("pattern", []) -> Right (1 :+ 0)
                        ("complex", [a, b]) -> (:+) <$> readReal a <*> readReal b
                        (_, [_]) -> (:+ 0) <$> (one xs >>= readReal)
                        _ -> Left (InvalidData "numeric record arity")
                    guardI
                        (not (any (\z -> isNaN z || isInfinite z) [realPart x, imagPart x]))
                        (InvalidData "nonfinite Matrix Market value")
                    Right (ij, x)
                )
                coords
        guardI
            ( all
                ( \((i, j), x) -> i /= j || if sym == "skew-symmetric" then x == 0 else sym /= "hermitian" || imagPart x == 0
                )
                parsed
            )
            (InvalidData "invalid symmetry diagonal")
        let expanded =
                if sym == "hermitian"
                    then
                        concatMap
                            (\((i, j), x) -> if i == j then [((i, j), x)] else [((i, j), x), ((j, i), conjugate x)])
                            parsed
                    else concatMap (expand sym) parsed
            table = M.fromListWith (+) expanded
            values = [M.findWithDefault 0 ij table | ij <- rowIndices r c]
        guardI
            (all (\x -> all (\z -> not (isNaN z || isInfinite z)) [realPart x, imagPart x]) values)
            (InvalidData "duplicate accumulation overflow")
        if field == "complex"
            then fromValues lim LittleEndian [r, c] values
            else fromValues lim LittleEndian [r, c] (map realPart values)

-- Empty rectangular matrices must not enumerate a huge outer axis just to
-- discover an empty inner axis. Dimensions are already validated above.
rowIndices :: Int -> Int -> [(Int, Int)]
rowIndices r c
    | r == 0 || c == 0 = []
    | otherwise = [(i, j) | i <- [0 .. r - 1], j <- [0 .. c - 1]]

columnIndices :: Int -> Int -> [(Int, Int)]
columnIndices r c = [(i, j) | (j, i) <- rowIndices c r]
