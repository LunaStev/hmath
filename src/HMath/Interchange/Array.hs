{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- SPDX-License-Identifier: MPL-2.0

{- | Fixed-width, typed array interchange. Strides and offsets count bytes;
negative/zero strides, unaligned samples, scalars and empty axes are valid.
The immutable backing bytes may contain padding. Construction validates the
entire reachable interval with Integer arithmetic before indexing. This is
an interchange representation, not the boxed numerical kernel storage.
-}
module HMath.Interchange.Array (
    Array,
    DType (..),
    Endian (..),
    Order (..),
    Limits (..),
    defaultLimits,
    InterchangeError (..),
    Element (..),
    array,
    contiguousArray,
    validateShape,
    arrayDType,
    arrayEndian,
    arrayShape,
    arrayStrides,
    arrayOffset,
    arrayBytes,
    arrayMetadata,
    withMetadata,
    elementBytes,
    elementCount,
    denseStrides,
    fromValues,
    toValues,
    fromTensor,
    toTensor,
    fromMatrix,
    toMatrix,
    repack,
    rawEncode,
    rawDecode,
    byteOffsets,
    guardI,
    checkLimits,
    boundedInt,
) where

import Control.Monad (unless)
import Data.Binary.Get
import Data.Binary.Put
import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as L
import Data.Complex (Complex ((:+)))
import Data.Int
import Data.List (nub)
import Data.Proxy
import Data.Word
import qualified HMath.Matrix as M
import qualified HMath.Tensor as T

-- | Numeric wire types; no platform-dependent Int, object or record dtype.
data DType = Bool8 | I8 | U8 | I16 | U16 | I32 | U32 | I64 | U64 | F32 | F64 | C64 | C128
    deriving (Eq, Ord, Show, Enum, Bounded)

-- | Explicit byte order. Single-byte types ignore it.
data Endian = LittleEndian | BigEndian deriving (Eq, Show)

-- | Physical order of a packed output; logical values are always row major.
data Order = COrder | FOrder deriving (Eq, Show)

{- | Caller-configurable finite resource budgets, checked before allocations.
Byte budgets include metadata/file overhead as well as raw payload. The
archive budget applies to the SUM of uncompressed members, preventing bombs.
-}
data Limits = Limits
    { maxBytes :: Int
    -- ^ Maximum aggregate encoded/input/backing bytes, including relevant format overhead.
    , maxElements :: Int
    -- ^ Maximum logical scalar element count.
    , maxRank :: Int
    -- ^ Maximum array dimension count (implementation cap 255).
    , maxMetadata :: Int
    -- ^ Maximum descriptive metadata/header byte budget.
    , maxArchiveEntries :: Int
    -- ^ Maximum archive member count; aggregate uncompressed bytes are also bounded.
    }
    deriving (Eq, Show)

-- | 128 MiB of bytes, 8 million samples, rank 16, 64 KiB metadata, 256 members.
defaultLimits :: Limits
defaultLimits = Limits (128 * 1024 * 1024) (8 * 1024 * 1024) 16 65536 256

-- | Decoders never throw on malformed bytes; IO failures have their own case.
data InterchangeError
    = InvalidData String
    | Unsupported String
    | LimitExceeded String
    | InterchangeIOError String
    deriving (Eq, Show)

-- | Opaque validated bytes and descriptive UTF-8 metadata (key/value strings).
data Array = Array DType Endian [Int] [Int] Int B.ByteString [(String, String)] deriving (Eq, Show)

{- | Return the fixed-width wire dtype of an Array; this is independent of Haskell host
Int/Double defaults.
-}
arrayDType :: Array -> DType
arrayDType (Array x _ _ _ _ _ _) = x

-- | Return explicit payload byte order; single-byte dtypes are endian-independent.
arrayEndian :: Array -> Endian
arrayEndian (Array _ x _ _ _ _ _) = x

-- | Return logical dimensions in axis order; [] is scalar and zero axes are valid.
arrayShape :: Array -> [Int]
arrayShape (Array _ _ x _ _ _ _) = x

{- | Return signed byte strides for each axis. Unlike HMath.Tensor strides, these are bytes,
not elements.
-}
arrayStrides :: Array -> [Int]
arrayStrides (Array _ _ _ x _ _ _) = x

-- | Return byte offset of logical origin within arrayBytes backing storage.
arrayOffset :: Array -> Int
arrayOffset (Array _ _ _ _ x _ _) = x

{- | Return immutable backing bytes, which may include padding or data not reached by the
logical strided view. Use toValues or repack for logical contents.
-}
arrayBytes :: Array -> B.ByteString
arrayBytes (Array _ _ _ _ _ x _) = x

{- | Return descriptive UTF-8-compatible key/value metadata strings in stored order;
metadata is not executable.
-}
arrayMetadata :: Array -> [(String, String)]
arrayMetadata (Array _ _ _ _ _ _ x) = x

{- | Given condition then InterchangeError, return Right () when True and Left that error
otherwise. This helper performs no IO.
-}
guardI :: Bool -> InterchangeError -> Either InterchangeError ()
guardI p e = unless p (Left e)

{- | Validate nonnegative finite resource caps, rank\<=255 and Int-safe
byte/element/metadata/archive budgets. Invalid settings return InvalidData.
-}
checkLimits :: Limits -> Either InterchangeError ()
checkLimits lim =
    guardI
        ( maxBytes lim >= 0
            && maxBytes lim < maxBound
            && maxElements lim >= 0
            && maxElements lim < maxBound
            && maxRank lim >= 0
            && maxRank lim <= 255
            && maxMetadata lim >= 0
            && maxMetadata lim < maxBound
            && maxArchiveEntries lim >= 0
            && maxArchiveEntries lim < maxBound
        )
        (InvalidData "invalid resource limits")

{- | Given diagnostic name,nonnegative upper bound,then Integer value, convert only if value
lies in [0,upper] and fits Int. Otherwise return LimitExceeded with that name.
-}
boundedInt :: String -> Integer -> Integer -> Either InterchangeError Int
boundedInt name upper x = do
    guardI (x >= 0 && x <= upper && x <= toInteger (maxBound :: Int)) (LimitExceeded name)
    Right (fromInteger x)

{- | Return fixed byte width of a DType, including complex pairs (C64=8,C128=16) and
Bool8=1.
-}
elementBytes :: DType -> Int
elementBytes dt = case dt of
    Bool8 -> 1
    I8 -> 1
    U8 -> 1
    I16 -> 2
    U16 -> 2
    I32 -> 4
    U32 -> 4
    I64 -> 8
    U64 -> 8
    F32 -> 4
    F64 -> 8
    C64 -> 8
    C128 -> 16

{- | Given limits then dimensions, validate rank, nonnegative axes and element product,
returning Int element count. Invalid data or exceeded limits return InterchangeError.
-}
validateShape :: Limits -> [Int] -> Either InterchangeError Int
validateShape lim sh = do
    checkLimits lim
    guardI (length (take (maxRank lim + 1) sh) <= maxRank lim) (LimitExceeded "array rank")
    guardI (all (>= 0) sh) (InvalidData "negative dimension")
    boundedInt "array element count" (toInteger (maxElements lim)) (product (map toInteger sh))

-- | Return logical shape product; scalar arrays have one element and empty axes have zero.
elementCount :: Array -> Int
elementCount = product . arrayShape

{- | Dense strides use Integer arithmetic before conversion. Call only on
validated shape/byte sizes; zero axes use zero strides to avoid overflow.
-}
denseStrides :: Order -> Int -> [Int] -> [Int]
denseStrides _ _ sh | 0 `elem` sh = replicate (length sh) 0
denseStrides COrder w sh = map fromInteger (drop 1 (scanr (*) (toInteger w) (map toInteger sh)))
denseStrides FOrder w sh = map fromInteger (take (length sh) (scanl (*) (toInteger w) (map toInteger sh)))

{- | Construct a bounded view. Bool8 bytes reachable through the view must be
0 or 1. Floating payloads preserve IEEE NaNs, signed zero and infinities.
-}
array ::
    Limits -> DType -> Endian -> [Int] -> [Int] -> Int -> B.ByteString -> Either InterchangeError Array
array lim dt en sh st off bs = do
    n <- validateShape lim sh
    guardI (length (take (length sh + 1) st) == length sh) (InvalidData "stride rank mismatch")
    guardI (B.length bs <= maxBytes lim) (LimitExceeded "array backing bytes")
    guardI
        (toInteger n * toInteger (elementBytes dt) <= toInteger (maxBytes lim))
        (LimitExceeded "logical array bytes")
    let extent = zipWith (\d s -> toInteger (max 0 (d - 1)) * toInteger s) sh st
        low = toInteger off + sum (map (min 0) extent)
        high = toInteger off + sum (map (max 0) extent) + toInteger (elementBytes dt)
    guardI
        (off >= 0 && if n == 0 then off <= B.length bs else low >= 0 && high <= toInteger (B.length bs))
        (InvalidData "strided view exceeds backing bytes")
    let a = Array dt en sh st off bs []
    guardI
        (dt /= Bool8 || all (\i -> B.index bs i <= 1) (byteOffsets a))
        (InvalidData "noncanonical boolean")
    Right a

{- | Given limits,dtype,endian,physical order,shape,then exact packed bytes, construct a
canonical byte-strided array. Require exact byte count; invalid shape/data/limits fail.
-}
contiguousArray ::
    Limits -> DType -> Endian -> Order -> [Int] -> B.ByteString -> Either InterchangeError Array
contiguousArray lim dt en order sh bs = do
    n <- validateShape lim sh
    guardI
        (toInteger n * toInteger (elementBytes dt) == toInteger (B.length bs))
        (InvalidData "raw byte count does not match shape/dtype")
    array lim dt en sh (denseStrides order (elementBytes dt) sh) 0 bs

{- | Metadata is UTF-8 in binary files; keys must be unique and nonempty. The
four-byte-per-codepoint bound is intentionally conservative before encoding.
-}
withMetadata :: Limits -> [(String, String)] -> Array -> Either InterchangeError Array
withMetadata lim meta (Array dt en sh st off bs _) = do
    checkLimits lim
    let charBudget = maxMetadata lim `div` 4
        bounded s = length (take (charBudget + 1) s)
        count = sum [toInteger (bounded k) + toInteger (bounded v) | (k, v) <- take (charBudget + 1) meta]
    guardI
        (length (take (charBudget + 1) meta) <= charBudget && count <= toInteger charBudget)
        (LimitExceeded "metadata")
    guardI
        (all (not . null . fst) meta && length (nub (map fst meta)) == length meta)
        (InvalidData "empty/duplicate metadata key")
    guardI
        (all (all (\c -> c < '\xD800' || c > '\xDFFF')) (concatMap (\(k, v) -> [k, v]) meta))
        (InvalidData "surrogate in metadata")
    Right (Array dt en sh st off bs meta)

{- | Return backing byte offsets for each logical element in row-major coordinate order,
honoring signed strides and offset.
-}
byteOffsets :: Array -> [Int]
-- An inner zero axis must short-circuit before traversing outer dimensions.
-- Those outer dimensions can be huge even when the logical size is zero.
byteOffsets a | elementCount a == 0 = []
byteOffsets a = offsets (arrayOffset a) (zip (arrayShape a) (arrayStrides a))
  where
    offsets p [] = [p]
    offsets p ((d, s) : rest) =
        [q | i <- [0 .. d - 1], q <- offsets (fromInteger (toInteger p + toInteger i * toInteger s)) rest]

{- | Fixed-width element encoding. Instances deliberately exclude machine Int.
Custom instances must write exactly elementBytes bytes and use a bounded
decoder. Built-in instances preserve floating-point bit representations.
-}
class Element a where
    -- | Given a Haskell Element type proxy, return its exact fixed-width wire DType.
    elementType :: proxy a -> DType

    -- | Given byte order then one typed Element, emit its binary representation with Data.Binary.Put.
    putElement :: Endian -> a -> Put

    -- | Given byte order, decode one typed Element with Data.Binary.Get; surrounding array decoders enforce byte/storage budgets.
    getElement :: Endian -> Get a

put16 :: Endian -> Word16 -> Put
put16 LittleEndian = putWord16le
put16 BigEndian = putWord16be
put32 :: Endian -> Word32 -> Put
put32 LittleEndian = putWord32le
put32 BigEndian = putWord32be
put64 :: Endian -> Word64 -> Put
put64 LittleEndian = putWord64le
put64 BigEndian = putWord64be
get16 :: Endian -> Get Word16
get16 LittleEndian = getWord16le
get16 BigEndian = getWord16be
get32 :: Endian -> Get Word32
get32 LittleEndian = getWord32le
get32 BigEndian = getWord32be
get64 :: Endian -> Get Word64
get64 LittleEndian = getWord64le
get64 BigEndian = getWord64be
instance Element Bool where
    elementType _ = Bool8
    putElement _ x = putWord8 (if x then 1 else 0)
    getElement _ = do
        x <- getWord8
        if x <= 1 then pure (x == 1) else fail "invalid boolean"
instance Element Word8 where
    elementType _ = U8
    putElement _ = putWord8
    getElement _ = getWord8
instance Element Int8 where
    elementType _ = I8
    putElement _ = putInt8
    getElement _ = getInt8
instance Element Word16 where
    elementType _ = U16
    putElement = put16
    getElement = get16
instance Element Int16 where
    elementType _ = I16
    putElement e = put16 e . fromIntegral
    getElement e = fromIntegral <$> get16 e
instance Element Word32 where
    elementType _ = U32
    putElement = put32
    getElement = get32
instance Element Int32 where
    elementType _ = I32
    putElement e = put32 e . fromIntegral
    getElement e = fromIntegral <$> get32 e
instance Element Word64 where
    elementType _ = U64
    putElement = put64
    getElement = get64
instance Element Int64 where
    elementType _ = I64
    putElement e = put64 e . fromIntegral
    getElement e = fromIntegral <$> get64 e
instance Element Float where
    elementType _ = F32
    putElement LittleEndian = putFloatle
    putElement BigEndian = putFloatbe
    getElement LittleEndian = getFloatle
    getElement BigEndian = getFloatbe
instance Element Double where
    elementType _ = F64
    putElement LittleEndian = putDoublele
    putElement BigEndian = putDoublebe
    getElement LittleEndian = getDoublele
    getElement BigEndian = getDoublebe
instance Element (Complex Float) where
    elementType _ = C64
    putElement en (a :+ b) = putElement en a >> putElement en b
    getElement en = (:+) <$> getElement en <*> getElement en
instance Element (Complex Double) where
    elementType _ = C128
    putElement en (a :+ b) = putElement en a >> putElement en b
    getElement en = (:+) <$> getElement en <*> getElement en

{- | Given limits,endian,shape,then typed Element list, encode to a contiguous array with
that Element dtype. Require exact shape/count match and resource bounds; failures
return InterchangeError.
-}
fromValues ::
    forall a. (Element a) => Limits -> Endian -> [Int] -> [a] -> Either InterchangeError Array
fromValues lim en sh xs = do
    n <- validateShape lim sh
    let dt = elementType (Proxy :: Proxy a)
    guardI
        (toInteger n * toInteger (elementBytes dt) <= toInteger (maxBytes lim))
        (LimitExceeded "encoded values")
    guardI (length (take (n + 1) xs) == n) (InvalidData "value count does not match shape")
    contiguousArray lim dt en COrder sh (L.toStrict (runPut (mapM_ (putElement en) xs)))

{- | Decode logical row-major values as the requested Element type, requiring an exact dtype
match. No silent numeric cast occurs; mismatch returns Unsupported/InvalidData.
-}
toValues :: forall a. (Element a) => Array -> Either InterchangeError [a]
toValues a = do
    guardI
        (arrayDType a == elementType (Proxy :: Proxy a))
        (InvalidData "requested element type differs from dtype")
    mapM sample (byteOffsets a)
  where
    sample i = case runGetOrFail
        (getElement (arrayEndian a))
        (L.fromStrict (B.take (elementBytes (arrayDType a)) (B.drop i (arrayBytes a)))) of
        Left (_, _, err) -> Left (InvalidData err)
        Right (rest, _, x) | L.null rest -> Right x
        _ -> Left (InvalidData "element decoder size mismatch")

{- | Given limits,endian,then typed Haskell Tensor, encode logical row-major values and
preserve shape. The Element instance determines wire dtype; resource bounds can fail.
-}
fromTensor :: (Element a) => Limits -> Endian -> T.Tensor a -> Either InterchangeError Array
fromTensor lim en t =
    fromValues lim en (T.tensorShape t) (if T.numel t == 0 then [] else T.tensorValues t)

{- | Decode an Array of matching Element dtype to a contiguous Haskell Tensor, preserving
logical shape/order. Dtype or checked tensor-construction failure returns
InterchangeError.
-}
toTensor :: (Element a) => Array -> Either InterchangeError (T.Tensor a)
toTensor a = toValues a >>= either (Left . InvalidData . show) Right . T.tensor (arrayShape a)

{- | Given limits,endian,then typed Matrix, encode its row-major values as a rank-two Array.
Dtype comes from Element; resource limits can fail.
-}
fromMatrix :: (Element a) => Limits -> Endian -> M.Matrix a -> Either InterchangeError Array
fromMatrix lim en m = let (r, c) = M.shape m in fromValues lim en [r, c] (M.toList m)

{- | Decode a matching typed rank-two Array to Matrix. Rank/dtype or checked shape
conversion failures return InterchangeError.
-}
toMatrix :: (Element a) => Array -> Either InterchangeError (M.Matrix a)
toMatrix a = case arrayShape a of
    [r, c] -> toValues a >>= either (Left . InvalidData . show) Right . M.fromListChecked r c
    _ -> Left (InvalidData "matrix requires rank two")

{- | Pack arbitrary views, preserving dtype and exact component bits. Complex
byte swapping reverses each real/imaginary component separately.
-}
repack :: Limits -> Endian -> Order -> Array -> Either InterchangeError Array
repack lim en order a = do
    let dt = arrayDType a
        width = elementBytes dt
        component = if dt == C64 || dt == C128 then width `div` 2 else width
        swap b
            | en == arrayEndian a || component == 1 = b
            | otherwise =
                B.concat [B.reverse (B.take component (B.drop k b)) | k <- [0, component .. width - 1]]
        offsets = case order of
            COrder -> byteOffsets a
            FOrder ->
                byteOffsets
                    ( Array
                        dt
                        (arrayEndian a)
                        (reverse (arrayShape a))
                        (reverse (arrayStrides a))
                        (arrayOffset a)
                        (arrayBytes a)
                        []
                    )
    _ <- validateShape lim (arrayShape a)
    guardI
        (toInteger (elementCount a) * toInteger width <= toInteger (maxBytes lim))
        (LimitExceeded "repacked bytes")
    b <-
        contiguousArray
            lim
            dt
            en
            order
            (arrayShape a)
            (B.concat [swap (B.take width (B.drop i (arrayBytes a))) | i <- offsets])
    withMetadata lim (arrayMetadata a) b

{- | Given limits,destination endian,physical order,then Array, repack its logical payload
and return raw bytes without shape/header metadata. Checked resource/layout failures
propagate.
-}
rawEncode :: Limits -> Endian -> Order -> Array -> Either InterchangeError B.ByteString
rawEncode lim en order = fmap arrayBytes . repack lim en order

{- | Given limits,dtype,endian,order,shape,then bytes, construct a packed Array. Caller
supplies all metadata; exact byte-count and shape/resource validation is enforced.
-}
rawDecode ::
    Limits -> DType -> Endian -> Order -> [Int] -> B.ByteString -> Either InterchangeError Array
rawDecode = contiguousArray
