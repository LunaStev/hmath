{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeSynonymInstances #-}

-- SPDX-License-Identifier: MPL-2.0

{- | Small law-oriented numeric interfaces. Ring operations obey the usual
associative/distributive laws for exact instances; IEEE instances approximate
them and retain ordinary rounding/overflow. Field inversion is checked.
Instances are open, so custom exact domains can use the same generic Horner
and inner-product algorithms without pretending to be RealFloat.
-}
module HMath.API.Algebra (
    Ring (..),
    Field (..),
    Scalar (..),
    FloatingPoint (..),
    Numeric (..),
    MatrixLike (..),
    TensorLike (..),
    VectorSpace (..),
    Differentiable (..),
    horner,
    innerProduct,
    Exact (..),
) where

import Data.Complex (Complex ((:+)), conjugate, imagPart, realPart)
import qualified Data.Ratio as R
import qualified HMath.Autodiff as AD
import HMath.Error
import qualified HMath.Matrix as M
import qualified HMath.Tensor as T
import qualified HMath.Vector as V

{- | Implement zero, one, additive inverse, addition, multiplication and integer
embedding. No ordering or approximate division is imposed on exact rings.
-}
class (Eq a) => Ring a where
    zero :: a
    one :: a
    plus :: a -> a -> a
    times :: a -> a -> a
    negative :: a -> a
    integer :: Integer -> a

class (Ring a) => Field a where
    invert :: a -> Either MathError a
class (Ring a) => Scalar a where
    conjugateScalar :: a -> a
class (Scalar a) => FloatingPoint a where
    machineEpsilon :: proxy a -> Double
    finiteScalar :: a -> Bool

{- | A numeric domain's conversion from a rational may fail, for example when
an exact ring cannot represent a non-integral value.
-}
class (Ring a) => Numeric a where
    rational :: Rational -> Either MathError a

instance Ring Integer where
    zero = 0
    one = 1
    plus = (+)
    times = (*)
    negative = negate
    integer = id
instance Scalar Integer where conjugateScalar = id
instance Numeric Integer where
    rational q
        | R.denominator q == 1 = Right (R.numerator q)
        | otherwise = Left (DomainError "Integer cannot represent a non-integral rational")
instance Ring Rational where
    zero = 0
    one = 1
    plus = (+)
    times = (*)
    negative = negate
    integer = fromInteger
instance Field Rational where
    invert x
        | x == 0 = Left (DomainError "field inverse of zero")
        | otherwise = Right (recip x)
instance Scalar Rational where conjugateScalar = id
instance Numeric Rational where rational = Right
instance Ring Double where
    zero = 0
    one = 1
    plus = (+)
    times = (*)
    negative = negate
    integer = fromInteger
instance Field Double where
    invert x
        | x == 0 || not (finiteScalar x) = Left (DomainError "finite nonzero field inverse required")
        | otherwise = let y = recip x in if finiteScalar y then Right y else Left NonFiniteResult
instance Scalar Double where conjugateScalar = id
instance FloatingPoint Double where
    machineEpsilon _ = 2 ** (-52)
    finiteScalar x = not (isNaN x || isInfinite x)
instance Numeric Double where
    rational q = let x = fromRational q in if finiteScalar x then Right x else Left NonFiniteResult
instance Ring Float where
    zero = 0
    one = 1
    plus = (+)
    times = (*)
    negative = negate
    integer = fromInteger
instance Field Float where
    invert x
        | x == 0 || not (finiteScalar x) = Left (DomainError "finite nonzero field inverse required")
        | otherwise = let y = recip x in if finiteScalar y then Right y else Left NonFiniteResult
instance Scalar Float where conjugateScalar = id
instance FloatingPoint Float where
    machineEpsilon _ = 2 ** (-23)
    finiteScalar x = not (isNaN x || isInfinite x)
instance Numeric Float where
    rational q = let x = fromRational q in if finiteScalar x then Right x else Left NonFiniteResult
instance Ring (Complex Double) where
    zero = 0
    one = 1
    plus = (+)
    times = (*)
    negative = negate
    integer = fromInteger
instance Scalar (Complex Double) where conjugateScalar = conjugate
instance FloatingPoint (Complex Double) where
    machineEpsilon _ = 2 ** (-52)
    finiteScalar z = finiteScalar (realPart z) && finiteScalar (imagPart z)
instance Field (Complex Double) where
    invert z
        | z == 0 || not (finiteScalar z) = Left (DomainError "finite nonzero complex inverse required")
        | otherwise =
            let a = realPart z
                b = imagPart z
                s = max (abs a) (abs b)
                x = a / s
                y = b / s
                d = x * x + y * y
                w = ((x / d) / s) :+ ((-y / d) / s)
             in if finiteScalar w then Right w else Left NonFiniteResult
instance Numeric (Complex Double) where
    rational q = (:+ 0) <$> (rational q :: Either MathError Double)

{- | An example user-definable domain, exact rationals with the explicit algebra
contracts. It deliberately does not need a Num or RealFloat instance.
-}
newtype Exact = Exact {getExact :: Rational} deriving (Eq, Ord, Show)

instance Ring Exact where
    zero = Exact 0
    one = Exact 1
    plus (Exact a) (Exact b) = Exact (a + b)
    times (Exact a) (Exact b) = Exact (a * b)
    negative (Exact a) = Exact (-a)
    integer = Exact . fromInteger
instance Field Exact where invert (Exact a) = Exact <$> invert a
instance Scalar Exact where conjugateScalar = id
instance Numeric Exact where rational = Right . Exact

-- | Coefficients are highest degree first; an empty polynomial is zero.
horner :: (Ring a) => [a] -> a -> a
horner coefficients x = foldl (\value coefficient -> plus (times value x) coefficient) zero coefficients

innerProduct :: (Scalar a) => [a] -> [a] -> Either MathError a
innerProduct a b
    | length a /= length b = Left (VectorLengthMismatch (length a) (length b))
    | otherwise = Right (foldl plus zero (zipWith (\x y -> times (conjugateScalar x) y) a b))
class MatrixLike m where
    matrixDimensions :: m a -> (Int, Int)
    matrixElements :: m a -> [a]
    matrixConstruct :: Int -> Int -> [a] -> Either MathError (m a)
instance MatrixLike M.Matrix where
    matrixDimensions = M.shape
    matrixElements = M.toList
    matrixConstruct = M.fromListChecked
class TensorLike t where
    tensorDimensions :: t a -> [Int]
    tensorElements :: t a -> [a]
    tensorConstruct :: [Int] -> [a] -> Either MathError (t a)
instance TensorLike T.Tensor where
    tensorDimensions = T.tensorShape
    tensorElements = T.tensorValues
    tensorConstruct = T.tensor
class VectorSpace v where
    vectorPlus :: (Num a) => v a -> v a -> Either MathError (v a)
    vectorScale :: (Num a) => a -> v a -> v a
instance VectorSpace V.Vector where vectorPlus = V.vectorAdd; vectorScale = V.vectorScale
instance VectorSpace M.Matrix where vectorPlus = M.addMatrixChecked; vectorScale = M.scaleMatrix

-- | Differential extraction reuses the existing nested forward-mode Dual type.
class Differentiable a where
    type Differential a
    differential :: a -> Differential a

instance Differentiable (AD.Dual a) where
    type Differential (AD.Dual a) = a
    differential = AD.tangent
