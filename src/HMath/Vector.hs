{-# LANGUAGE DataKinds #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- SPDX-License-Identifier: MPL-2.0

{- | Immutable dynamically sized and type-indexed vectors. All indices are
zero based. Checked operations reject mismatched dimensions and zero norms.
-}
module HMath.Vector (
    Vector,
    vector,
    vectorValues,
    vectorDimension,
    FixedVector,
    SparseVector,
    fixedVector,
    fixedValues,
    sparseVector,
    sparseVectorValues,
    vectorSlice,
    vectorConcat,
    vectorAdd,
    vectorSubtract,
    vectorScale,
    vectorDot,
    cross,
    outer,
    triple,
    norm0,
    norm1,
    norm2,
    normP,
    normInfinity,
    normalizeVector,
    project,
    reflect,
    refract,
    distance,
    angle,
    cosineSimilarity,
    gramSchmidt,
) where

import qualified Data.Foldable as Foldable (foldl')
import qualified Data.IntMap.Strict as IM
import Data.Proxy (Proxy (..))
import GHC.TypeLits (KnownNat, Nat, natVal)
import HMath.Error
import HMath.Matrix (Matrix, fromListChecked)
import HMath.Matrix.Internal (finiteValues, stableNorm)

{- | Immutable dynamically sized coordinate list. Construct with vector; checked binary
operations reject dimension mismatch.
-}
newtype Vector a = Vector [a] deriving (Eq, Show)

{- | Opaque vector whose length matches its KnownNat type index. Construct with fixedVector
for a checked dynamic/static boundary.
-}
newtype FixedVector (n :: Nat) a = FixedVector [a] deriving (Eq, Show)

{- | Opaque dynamic vector with canonical nonzero coordinate entries. Construct with
sparseVector; duplicate indices add.
-}
data SparseVector a = SparseVector Int (IM.IntMap a) deriving (Eq, Show)

{- | Wrap a list as an immutable dynamic vector without numeric validation. The list order
is preserved. Example: vectorValues (vector [1,2]) == [1,2].
-}
vector :: [a] -> Vector a
vector = Vector

{- | Extract the immutable list of vector values in order; no shape conversion or numeric
validation occurs.
-}
vectorValues :: Vector a -> [a]
vectorValues (Vector xs) = xs

{- | Return the number of coordinates in a dynamic vector. Empty vectors have dimension
zero.
-}
vectorDimension :: Vector a -> Int
vectorDimension = length . vectorValues

{- | Construct a vector whose list length equals the type-level KnownNat size. A mismatch
returns Left InvalidArgument. For example, fixedVector @3 requires exactly three
values.
-}
fixedVector :: forall n a. (KnownNat n) => [a] -> Either MathError (FixedVector n a)
fixedVector xs
    | toInteger (length xs) == toInteger (natVal (Proxy :: Proxy n)) = Right (FixedVector xs)
    | otherwise = Left (InvalidArgument "fixedVector: dimension differs from type-level size")

{- | Extract the ordered coordinates of a type-indexed vector; its length is the type-level
size.
-}
fixedValues :: FixedVector n a -> [a]
fixedValues (FixedVector xs) = xs

{- | Given nonnegative dimension and (zero-based index,value) entries, sum duplicate indices
and remove explicit zeros. Reject out-of-range indices or negative dimension.
-}
sparseVector :: (Eq a, Num a) => Int -> [(Int, a)] -> Either MathError (SparseVector a)
sparseVector n xs
    | n < 0 || any (\(i, _) -> i < 0 || i >= n) xs =
        Left (InvalidArgument "sparseVector: invalid dimension/index")
    | otherwise = Right (SparseVector n (IM.filter (/= 0) (IM.fromListWith (+) xs)))

{- | Expand a sparse vector to a dense list of its declared dimension, filling absent
entries with zero.
-}
sparseVectorValues :: (Num a) => SparseVector a -> [a]
sparseVectorValues (SparseVector n xs) = [IM.findWithDefault 0 i xs | i <- [0 .. n - 1]]

{- | Given start, count, then vector, return the half-open slice [start,start+count). Reject
negative or out-of-range bounds; an empty end slice is valid.
-}
vectorSlice :: Int -> Int -> Vector a -> Either MathError (Vector a)
vectorSlice start count (Vector xs)
    | start < 0 || count < 0 || start > n || count > n - start =
        Left (InvalidArgument "vectorSlice: invalid bounds")
    | otherwise = Right (Vector (take count (drop start xs)))
  where
    n = length xs

{- | Concatenate a list of vectors in order. Return Left InvalidArgument if the combined
dimension would overflow Int; an empty list gives an empty vector.
-}
vectorConcat :: [Vector a] -> Either MathError (Vector a)
vectorConcat vs
    | sum (map (toInteger . vectorDimension) vs) > toInteger (maxBound :: Int) =
        Left (InvalidArgument "vectorConcat: size overflow")
    | otherwise = Right (Vector (concatMap vectorValues vs))

zipVector :: (a -> b -> c) -> Vector a -> Vector b -> Either MathError (Vector c)
zipVector f (Vector a) (Vector b)
    | length a /= length b = Left (VectorLengthMismatch (length a) (length b))
    | otherwise = Right (Vector (zipWith f a b))

{- | Add corresponding values of equally sized vectors, returning a new vector. Unequal
dimensions return VectorLengthMismatch. Generic Num arithmetic is unchecked.
-}
vectorAdd :: (Num a) => Vector a -> Vector a -> Either MathError (Vector a)
vectorAdd = zipVector (+)

{- | Subtract corresponding right-hand coordinates from left-hand coordinates. Unequal
dimensions return VectorLengthMismatch; Num arithmetic is unchecked.
-}
vectorSubtract :: (Num a) => Vector a -> Vector a -> Either MathError (Vector a)
vectorSubtract = zipVector (-)

{- | Given scalar then vector, multiply every coordinate by the scalar. Return a new vector,
retaining the original dimension and Num arithmetic behavior.
-}
vectorScale :: (Num a) => a -> Vector a -> Vector a
vectorScale s (Vector xs) = Vector (map (s *) xs)

{- | Sum coordinatewise products of equally sized vectors. Empty vectors give zero; unequal
dimensions return VectorLengthMismatch. No floating-point finiteness check is added.
-}
vectorDot :: (Num a) => Vector a -> Vector a -> Either MathError a
vectorDot a b = sum . vectorValues <$> zipVector (*) a b

{- | Compute the right-handed cross product of two three-dimensional vectors. Any other
dimension returns Left InvalidArgument.
-}
cross :: (Num a) => Vector a -> Vector a -> Either MathError (Vector a)
cross (Vector [a, b, c]) (Vector [d, e, f]) = Right (Vector [b * f - c * e, c * d - a * f, a * e - b * d])
cross _ _ = Left (InvalidArgument "cross: vectors must have dimension three")

{- | Return the matrix of pairwise products a[i]*b[j], with shape (dimension a,dimension b).
Matrix construction can return shape/count errors.
-}
outer :: (Num a) => Vector a -> Vector a -> Either MathError (Matrix a)
outer (Vector a) (Vector b) = fromListChecked (length a) (length b) [x * y | x <- a, y <- b]

{- | Given a,b,c, compute scalar triple product a dot (b cross c). All three vectors must
have dimension three; dimension errors propagate.
-}
triple :: (Num a) => Vector a -> Vector a -> Vector a -> Either MathError a
triple a b c = cross b c >>= vectorDot a

{- | Count nonzero coordinates, returning Int. This is the usual sparsity count rather than
a norm satisfying homogeneity.
-}
norm0 :: (Eq a, Num a) => Vector a -> Int
norm0 = length . filter (/= 0) . vectorValues

{- | Sum absolute coordinate values. Empty vector returns zero; arithmetic follows the
chosen Num type.
-}
norm1 :: (Num a) => Vector a -> a
norm1 = sum . map abs . vectorValues

{- | Compute Euclidean length using a scaled stable norm to reduce intermediate
overflow/underflow. Empty vector returns zero; the result itself is not wrapped in
Either.
-}
norm2 :: (RealFloat a) => Vector a -> a
norm2 = stableNorm . vectorValues

{- | Return maximum absolute coordinate, or zero for an empty vector. NaN coordinates
propagate rather than being silently discarded.
-}
normInfinity :: (Ord a, Num a) => Vector a -> a
normInfinity v = case [x | x <- vectorValues v, x /= x] of
    x : _ -> x
    [] -> maximum (0 : map abs (vectorValues v))

{- | Given positive exponent p then finite vector, compute the scaled p-norm. Positive
infinity selects normInfinity. NaN/nonpositive p or non-finite coordinates fail; p\<1 is
accepted as a quasi-norm.
-}
normP :: (RealFloat a) => a -> Vector a -> Either MathError a
normP p v@(Vector xs)
    | isNaN p || p <= 0 = Left (DomainError "normP: p must be positive")
    | isInfinite p = finiteValues xs >> Right (normInfinity v)
    | otherwise = do
        finiteValues xs
        let s = normInfinity v
        Right (if s == 0 then 0 else s * (sum [abs (x / s) ** p | x <- xs]) ** (1 / p))

{- | Return a unit-length vector in the same direction. Reject non-finite coordinates, zero
norm, or non-finite resulting norm. Empty input is a zero vector and fails.
-}
normalizeVector :: (RealFloat a) => Vector a -> Either MathError (Vector a)
normalizeVector v@(Vector xs) = do
    finiteValues xs
    let n = norm2 v
    if n == 0
        then Left (DomainError "normalizeVector: zero vector")
        else if isInfinite n then Left NonFiniteResult else Right (vectorScale (1 / n) v)

{- | Given a then b, return the projection of a onto b. Dimensions must agree and b must
have nonzero finite norm; non-finite input/result fails.
-}
project :: (RealFloat a) => Vector a -> Vector a -> Either MathError (Vector a)
project a b = do
    u <- normalizeVector b
    s <- vectorDot a u
    finiteValues (vectorValues a)
    checkedVector (vectorScale s u)

checkedVector :: (RealFloat a) => Vector a -> Either MathError (Vector a)
checkedVector v
    | any (\x -> isNaN x || isInfinite x) (vectorValues v) = Left NonFiniteResult
    | otherwise = Right v

{- | Given incident vector then surface normal, return incident minus twice its projection
onto the normal. The normal is normalized internally; invalid dimensions, zero normal,
or non-finite values fail.
-}
reflect :: (RealFloat a) => Vector a -> Vector a -> Either MathError (Vector a)
reflect incident normal = do
    p <- project incident normal
    vectorSubtract incident (vectorScale 2 p) >>= checkedVector

{- | Given positive finite refractive-index ratio, incident vector, then normal, return the
refracted unit-direction expression. Normalize both inputs; reject invalid dimensions,
zero vectors, non-finite values, or total internal reflection.
-}
refract :: (RealFloat a) => a -> Vector a -> Vector a -> Either MathError (Vector a)
refract eta incident normal
    | eta <= 0 || isNaN eta || isInfinite eta =
        Left (DomainError "refract: positive finite index ratio required")
    | otherwise = do
        i <- normalizeVector incident
        n <- normalizeVector normal
        d <- vectorDot i n
        let k = 1 - eta * eta * (1 - d * d)
        if k < 0
            then Left (DomainError "refract: total internal reflection")
            else vectorSubtract (vectorScale eta i) (vectorScale (eta * d + sqrt k) n) >>= checkedVector

{- | Return Euclidean distance between equal-sized finite vectors. Dimension mismatch and
non-finite input/intermediate/result return Left MathError.
-}
distance :: (RealFloat a) => Vector a -> Vector a -> Either MathError a
distance a b = do
    finiteValues (vectorValues a ++ vectorValues b)
    difference <- vectorSubtract a b >>= checkedVector
    let result = norm2 difference
    if isNaN result || isInfinite result then Left NonFiniteResult else Right result

{- | Return normalized dot product clamped to [-1,1]. Equal dimensions and nonzero finite
vectors are required; validation errors propagate.
-}
cosineSimilarity :: (RealFloat a) => Vector a -> Vector a -> Either MathError a
cosineSimilarity a b = do
    u <- normalizeVector a
    v <- normalizeVector b
    max (-1) . min 1 <$> vectorDot u v

{- | Return the angle in radians, acos of cosineSimilarity, between two nonzero finite
equally sized vectors. Invalid dimensions or zero/non-finite vectors fail.
-}
angle :: (RealFloat a) => Vector a -> Vector a -> Either MathError a
angle a b = acos <$> cosineSimilarity a b

{- | Given finite nonnegative relative tolerance then vectors, perform two-pass modified
Gram-Schmidt, returning an orthonormal basis in input order. Reject unequal dimensions,
zero/dependent vectors (RankDeficient), invalid tolerance, or non-finite data.
-}
gramSchmidt :: (RealFloat a) => a -> [Vector a] -> Either MathError [Vector a]
gramSchmidt tolerance vs
    | tolerance < 0 || isNaN tolerance || isInfinite tolerance = Left InvalidTolerance
    | otherwise = Foldable.foldl' step (Right []) vs
  where
    step acc v = do
        basis <- acc
        -- Two modified Gram-Schmidt passes reduce loss of orthogonality.
        w <- Foldable.foldl' remove (Right v) (basis ++ basis)
        if norm2 w <= tolerance * max 1 (norm2 v)
            then Left (RankDeficient (length basis))
            else do u <- normalizeVector w; Right (basis ++ [u])
    remove acc u = do w <- acc; p <- project w u; vectorSubtract w p
