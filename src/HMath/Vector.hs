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

import qualified Data.IntMap.Strict as IM
import Data.Proxy (Proxy (..))
import GHC.TypeLits (KnownNat, Nat, natVal)
import HMath.Error
import HMath.Matrix (Matrix, fromListChecked)
import HMath.Matrix.Internal (finiteValues, stableNorm)

newtype Vector a = Vector [a] deriving (Eq, Show)
newtype FixedVector (n :: Nat) a = FixedVector [a] deriving (Eq, Show)
data SparseVector a = SparseVector Int (IM.IntMap a) deriving (Eq, Show)
vector :: [a] -> Vector a
vector = Vector
vectorValues :: Vector a -> [a]
vectorValues (Vector xs) = xs
vectorDimension :: Vector a -> Int
vectorDimension = length . vectorValues
fixedVector :: forall n a. (KnownNat n) => [a] -> Either MathError (FixedVector n a)
fixedVector xs
    | toInteger (length xs) == toInteger (natVal (Proxy :: Proxy n)) = Right (FixedVector xs)
    | otherwise = Left (InvalidArgument "fixedVector: dimension differs from type-level size")
fixedValues :: FixedVector n a -> [a]
fixedValues (FixedVector xs) = xs
sparseVector :: (Eq a, Num a) => Int -> [(Int, a)] -> Either MathError (SparseVector a)
sparseVector n xs
    | n < 0 || any (\(i, _) -> i < 0 || i >= n) xs =
        Left (InvalidArgument "sparseVector: invalid dimension/index")
    | otherwise = Right (SparseVector n (IM.filter (/= 0) (IM.fromListWith (+) xs)))
sparseVectorValues :: (Num a) => SparseVector a -> [a]
sparseVectorValues (SparseVector n xs) = [IM.findWithDefault 0 i xs | i <- [0 .. n - 1]]
vectorSlice :: Int -> Int -> Vector a -> Either MathError (Vector a)
vectorSlice start count (Vector xs)
    | start < 0 || count < 0 || start > n || count > n - start =
        Left (InvalidArgument "vectorSlice: invalid bounds")
    | otherwise = Right (Vector (take count (drop start xs)))
  where
    n = length xs
vectorConcat :: [Vector a] -> Either MathError (Vector a)
vectorConcat vs
    | sum (map (toInteger . vectorDimension) vs) > toInteger (maxBound :: Int) =
        Left (InvalidArgument "vectorConcat: size overflow")
    | otherwise = Right (Vector (concatMap vectorValues vs))
zipVector :: (a -> b -> c) -> Vector a -> Vector b -> Either MathError (Vector c)
zipVector f (Vector a) (Vector b)
    | length a /= length b = Left (VectorLengthMismatch (length a) (length b))
    | otherwise = Right (Vector (zipWith f a b))
vectorAdd :: (Num a) => Vector a -> Vector a -> Either MathError (Vector a)
vectorAdd = zipVector (+)
vectorSubtract :: (Num a) => Vector a -> Vector a -> Either MathError (Vector a)
vectorSubtract = zipVector (-)
vectorScale :: (Num a) => a -> Vector a -> Vector a
vectorScale s (Vector xs) = Vector (map (s *) xs)
vectorDot :: (Num a) => Vector a -> Vector a -> Either MathError a
vectorDot a b = sum . vectorValues <$> zipVector (*) a b
cross :: (Num a) => Vector a -> Vector a -> Either MathError (Vector a)
cross (Vector [a, b, c]) (Vector [d, e, f]) = Right (Vector [b * f - c * e, c * d - a * f, a * e - b * d])
cross _ _ = Left (InvalidArgument "cross: vectors must have dimension three")
outer :: (Num a) => Vector a -> Vector a -> Either MathError (Matrix a)
outer (Vector a) (Vector b) = fromListChecked (length a) (length b) [x * y | x <- a, y <- b]
triple :: (Num a) => Vector a -> Vector a -> Vector a -> Either MathError a
triple a b c = cross b c >>= vectorDot a
norm0 :: (Eq a, Num a) => Vector a -> Int
norm0 = length . filter (/= 0) . vectorValues
norm1 :: (Num a) => Vector a -> a
norm1 = sum . map abs . vectorValues
norm2 :: (RealFloat a) => Vector a -> a
norm2 = stableNorm . vectorValues
normInfinity :: (Ord a, Num a) => Vector a -> a
normInfinity v = case [x | x <- vectorValues v, x /= x] of
    x : _ -> x
    [] -> maximum (0 : map abs (vectorValues v))
normP :: (RealFloat a) => a -> Vector a -> Either MathError a
normP p v@(Vector xs)
    | isNaN p || p <= 0 = Left (DomainError "normP: p must be positive")
    | isInfinite p = finiteValues xs >> Right (normInfinity v)
    | otherwise = do
        finiteValues xs
        let s = normInfinity v
        Right (if s == 0 then 0 else s * (sum [abs (x / s) ** p | x <- xs]) ** (1 / p))
normalizeVector :: (RealFloat a) => Vector a -> Either MathError (Vector a)
normalizeVector v@(Vector xs) = do
    finiteValues xs
    let n = norm2 v
    if n == 0
        then Left (DomainError "normalizeVector: zero vector")
        else if isInfinite n then Left NonFiniteResult else Right (vectorScale (1 / n) v)
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
reflect :: (RealFloat a) => Vector a -> Vector a -> Either MathError (Vector a)
reflect incident normal = do
    p <- project incident normal
    vectorSubtract incident (vectorScale 2 p) >>= checkedVector
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
distance :: (RealFloat a) => Vector a -> Vector a -> Either MathError a
distance a b = do
    finiteValues (vectorValues a ++ vectorValues b)
    difference <- vectorSubtract a b >>= checkedVector
    let result = norm2 difference
    if isNaN result || isInfinite result then Left NonFiniteResult else Right result
cosineSimilarity :: (RealFloat a) => Vector a -> Vector a -> Either MathError a
cosineSimilarity a b = do
    u <- normalizeVector a
    v <- normalizeVector b
    max (-1) . min 1 <$> vectorDot u v
angle :: (RealFloat a) => Vector a -> Vector a -> Either MathError a
angle a b = acos <$> cosineSimilarity a b
gramSchmidt :: (RealFloat a) => a -> [Vector a] -> Either MathError [Vector a]
gramSchmidt tolerance vs
    | tolerance < 0 || isNaN tolerance || isInfinite tolerance = Left InvalidTolerance
    | otherwise = foldl' step (Right []) vs
  where
    step acc v = do
        basis <- acc
        -- Two modified Gram-Schmidt passes reduce loss of orthogonality.
        w <- foldl' remove (Right v) (basis ++ basis)
        if norm2 w <= tolerance * max 1 (norm2 v)
            then Left (RankDeficient (length basis))
            else do u <- normalizeVector w; Right (basis ++ [u])
    remove acc u = do w <- acc; p <- project w u; vectorSubtract w p
