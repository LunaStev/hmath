-- SPDX-License-Identifier: MPL-2.0

{- | Checked finite complex arithmetic over "Data.Complex". Angles are radians,
positive rotations are counterclockwise, and logarithms/powers use the principal
branch (argument in (-pi,pi], with IEEE signed-zero behavior inherited from
"Data.Complex"). Poles, zero reciprocals, and nonfinite results are errors.
Matrices use the existing row-major @M.Matrix@; FFTs use the existing negative
forward-exponent convention. The reference matrix budget is 256 per dimension.
-}
module HMath.Complex (
    Complex,
    complex,
    realPart,
    imagPart,
    magnitude,
    phase,
    conjugate,
    reciprocal,
    add,
    subtractComplex,
    multiply,
    divide,
    power,
    Elementary (..),
    elementary,
    fromPolar,
    toPolar,
    rotate,
    complexMatrix,
    multiplyMatrices,
    conjugateTranspose,
    complexFFT,
    complexIFFT,
) where

import Data.Complex (Complex ((:+)), conjugate, imagPart, magnitude, phase, realPart)
import qualified Data.Complex as C
import HMath.Error (MathError (..))
import qualified HMath.Fourier as F
import qualified HMath.Matrix as M

finite :: Double -> Bool
finite x = not (isNaN x || isInfinite x)
valid :: Complex Double -> Bool
valid z = finite (realPart z) && finite (imagPart z)
checked :: Complex Double -> Either MathError (Complex Double)
checked z = if valid z then Right z else Left NonFiniteResult
inputs :: [Complex Double] -> Either MathError ()
inputs zs = if all valid zs then Right () else Left (DomainError "nonfinite complex input")

-- | Construct a finite number from real and imaginary parts.
complex :: Double -> Double -> Either MathError (Complex Double)
complex x y = checked (x :+ y)

-- | Reciprocal using scaled division to avoid squaring a large norm.
reciprocal :: Complex Double -> Either MathError (Complex Double)
reciprocal z = divide (1 :+ 0) z

-- | Checked sum.
add :: Complex Double -> Complex Double -> Either MathError (Complex Double)
add a b = inputs [a, b] >> checked (a + b)

-- | Checked difference.
subtractComplex :: Complex Double -> Complex Double -> Either MathError (Complex Double)
subtractComplex a b = inputs [a, b] >> checked (a - b)

-- | Checked product.
multiply :: Complex Double -> Complex Double -> Either MathError (Complex Double)
multiply a b = inputs [a, b] >> checked (a * b)

-- | Smith scaled division. A zero divisor is rejected.
divide :: Complex Double -> Complex Double -> Either MathError (Complex Double)
divide a b = do
    inputs [a, b]
    if b == 0
        then Left (DomainError "zero complex divisor")
        else
            let ar = realPart a
                ai = imagPart a
                br = realPart b
                bi = imagPart b
                -- Normalize both numerator and denominator before forming products.
                s = max (abs br) (abs bi)
                u = br / s
                v = bi / s
                den = u * u + v * v
             in checked (((ar / s * u + ai / s * v) / den) :+ ((ai / s * u - ar / s * v) / den))

-- | Principal complex power. 0^0 is 1; other zero-base exponents must be positive real.
power :: Complex Double -> Complex Double -> Either MathError (Complex Double)
power a b = do
    inputs [a, b]
    if a == 0
        then
            if b == 0
                then Right 1
                else
                    if imagPart b == 0 && realPart b > 0
                        then Right 0
                        else Left (DomainError "undefined zero complex power")
        else checked (a ** b)

-- | Elementary functions with principal inverse-function branches.
data Elementary
    = Exp
    | Log
    | Sqrt
    | Sin
    | Cos
    | Tan
    | Sinh
    | Cosh
    | Tanh
    | Asin
    | Acos
    | Atan
    | Asinh
    | Acosh
    | Atanh
    deriving (Eq, Show)

-- | Apply an elementary function, rejecting poles and nonfinite results.
elementary :: Elementary -> Complex Double -> Either MathError (Complex Double)
elementary op z = do
    inputs [z]
    if op == Log && z == 0
        then Left (DomainError "logarithm of zero")
        else checked $ case op of
            Exp -> exp z
            Log -> log z
            Sqrt -> sqrt z
            Sin -> sin z
            Cos -> cos z
            Tan -> tan z
            Sinh -> sinh z
            Cosh -> cosh z
            Tanh -> tanh z
            Asin -> asin z
            Acos -> acos z
            Atan -> atan z
            Asinh -> asinh z
            Acosh -> acosh z
            Atanh -> atanh z

-- | Polar construction with nonnegative finite radius.
fromPolar :: Double -> Double -> Either MathError (Complex Double)
fromPolar radius angle
    | not (finite radius && finite angle) || radius < 0 = Left (DomainError "invalid polar coordinates")
    | otherwise = checked (C.mkPolar radius angle)

-- | Radius and principal phase; the phase of zero is defined by Data.Complex.
toPolar :: Complex Double -> Either MathError (Double, Double)
toPolar z = inputs [z] >> if finite (magnitude z) then Right (magnitude z, phase z) else Left NonFiniteResult

-- | Counterclockwise rotation in the complex plane.
rotate :: Double -> Complex Double -> Either MathError (Complex Double)
rotate angle z = fromPolar 1 angle >>= multiply z

-- | Checked finite complex matrix, at most 256 rows and columns.
complexMatrix :: Int -> Int -> [Complex Double] -> Either MathError (M.Matrix (Complex Double))
complexMatrix rows cols xs
    | rows > 256 || cols > 256 = Left (InvalidArgument "complex matrix exceeds reference budget")
    | otherwise = inputs xs >> M.fromListChecked rows cols xs

-- | Matrix multiplication with finite-result validation.
multiplyMatrices ::
    M.Matrix (Complex Double) ->
    M.Matrix (Complex Double) ->
    Either MathError (M.Matrix (Complex Double))
multiplyMatrices a b = do
    let (r, k) = M.shape a; (_, c) = M.shape b
    _ <- complexMatrix r k (M.toList a)
    let (br, bc) = M.shape b
    _ <- complexMatrix br bc (M.toList b)
    out <- M.multiplyChecked a b
    complexMatrix r c (M.toList out)

-- | Hermitian transpose with finite-input validation.
conjugateTranspose :: M.Matrix (Complex Double) -> Either MathError (M.Matrix (Complex Double))
conjugateTranspose a =
    let t = M.transposeMatrix a; (r, c) = M.shape t
     in complexMatrix r c (map conjugate (M.toList t))

-- | Existing checked mixed-radix/Bluestein forward FFT.
complexFFT :: [Complex Double] -> Either MathError [Complex Double]
complexFFT = F.fft

-- | Existing checked inverse FFT, normalized by sample count.
complexIFFT :: [Complex Double] -> Either MathError [Complex Double]
complexIFFT = F.ifft
