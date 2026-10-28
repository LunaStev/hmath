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
    -- | Additive identity of this ring.
    zero :: a

    -- | Multiplicative identity of this ring.
    one :: a

    -- | Add two ring elements; exact instances obey ring laws and IEEE instances retain host rounding.
    plus :: a -> a -> a

    -- | Multiply two ring elements using the instance arithmetic.
    times :: a -> a -> a

    -- | Return the additive inverse of a ring element.
    negative :: a -> a

    -- | Embed an unbounded Integer into the domain; instance representation/rounding rules apply.
    integer :: Integer -> a

{- | Ring supporting checked multiplicative inversion. Invalid zero/domain or
unrepresentable inverse returns MathError.
-}
class (Ring a) => Field a where
    -- | Return multiplicative inverse of a nonzero domain element, or Left MathError for zero/invalid/nonrepresentable inverse.
    invert :: a -> Either MathError a

-- | Ring with conjugation,used by Hermitian inner-product algorithms.
class (Ring a) => Scalar a where
    -- | Return scalar conjugate; real/exact instances use identity and complex instances conjugate imaginary components.
    conjugateScalar :: a -> a

{- | Scalar domain exposing precision epsilon and finite-value classification,including
complex component checks.
-}
class (Scalar a) => FloatingPoint a where
    -- | Given a type proxy, return floating precision epsilon as Double (2^-52 for Double,2^-23 for Float).
    machineEpsilon :: proxy a -> Double

    -- | Test whether all real/complex components are finite for this instance.
    finiteScalar :: a -> Bool

{- | A numeric domain's conversion from a rational may fail, for example when
an exact ring cannot represent a non-integral value.
-}
class (Ring a) => Numeric a where
    -- | Convert exact Rational into the domain, returning Left MathError if it cannot be represented under the instance contract.
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
newtype Exact = Exact
    { getExact :: Rational
    -- ^ Extract the exact Rational stored in the example Exact algebra domain.
    }
    deriving (Eq, Ord, Show)

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

{- | Return sum(conjugate a[i] * b[i]) using the Scalar and Ring operations. Equal list
lengths are required; mismatch returns VectorLengthMismatch. Empty lists give the ring
zero; instance arithmetic controls precision/overflow.
-}
innerProduct :: (Scalar a) => [a] -> [a] -> Either MathError a
innerProduct a b
    | length a /= length b = Left (VectorLengthMismatch (length a) (length b))
    | otherwise = Right (foldl plus zero (zipWith (\x y -> times (conjugateScalar x) y) a b))

-- | Container interface for matrix dimensions,row-major elements,and checked construction.
class MatrixLike m where
    -- | Return logical (rows,columns) of a matrix-like container.
    matrixDimensions :: m a -> (Int, Int)

    -- | Return matrix elements in logical row-major order.
    matrixElements :: m a -> [a]

    -- | Given rows,columns,flat row-major elements, construct a matrix-like value or return checked shape/count failure.
    matrixConstruct :: Int -> Int -> [a] -> Either MathError (m a)

instance MatrixLike M.Matrix where
    matrixDimensions = M.shape
    matrixElements = M.toList
    matrixConstruct = M.fromListChecked

{- | Container interface for tensor dimensions,row-major logical elements,and checked
construction.
-}
class TensorLike t where
    -- | Return tensor-like dimensions in axis order; [] denotes scalar.
    tensorDimensions :: t a -> [Int]

    -- | Return tensor-like elements in logical row-major coordinate order.
    tensorElements :: t a -> [a]

    -- | Given dimensions then flat values, construct a tensor-like value or return shape/count failure.
    tensorConstruct :: [Int] -> [a] -> Either MathError (t a)

instance TensorLike T.Tensor where
    tensorDimensions = T.tensorShape
    tensorElements = T.tensorValues
    tensorConstruct = T.tensor

-- | Container interface for checked shape-compatible addition and scalar multiplication.
class VectorSpace v where
    -- | Add identically shaped vector-space values, returning checked dimension errors on mismatch.
    vectorPlus :: (Num a) => v a -> v a -> Either MathError (v a)

    -- | Given scalar then vector-space value, return its coordinatewise scalar multiple.
    vectorScale :: (Num a) => a -> v a -> v a

instance VectorSpace V.Vector where vectorPlus = V.vectorAdd; vectorScale = V.vectorScale
instance VectorSpace M.Matrix where vectorPlus = M.addMatrixChecked; vectorScale = M.scaleMatrix

-- | Differential extraction reuses the existing nested forward-mode Dual type.
class Differentiable a where
    type Differential a

    -- | Extract associated differential; the Dual instance returns its tangent component.
    differential :: a -> Differential a

instance Differentiable (AD.Dual a) where
    type Differential (AD.Dual a) = a
    differential = AD.tangent
