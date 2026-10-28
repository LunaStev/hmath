-- SPDX-License-Identifier: MPL-2.0

-- | Scalar utilities. Generic Num arithmetic follows the chosen numeric type.
-- Checked real operations require finite inputs and report domain failures and
-- finite-result overflow explicitly. Exact combinatorics use 'Integer'.
-- expm1/log1p use convergent series near zero to avoid cancellation; their target
-- is a few ulps for ordinary IEEE binary32/64 inputs, not correct rounding.
module HMath.Scalar
    ( add, subtractScalar, multiply, divide, quotientRemainder, euclideanDivision
    , absolute, sign, minimumScalar, maximumScalar, clampChecked, lerpChecked
    , inverseLerp, remap, step, smoothstep, smootherstep, power, integerPower
    , modularPower, sqrtChecked, cubeRoot, nthRoot, reciprocalSqrt
    , expChecked, logChecked, expm1, log1p, hypot
    , floorChecked, ceilChecked, roundChecked, truncateChecked, bankersRound
    , roundDigits, integerFraction, positiveModulo, absoluteError, relativeError
    , factorialChecked, doubleFactorial, risingFactorial, fallingFactorial
    , fibonacciChecked, lucas, permutations, combinations, multinomial
    , catalan, bernoulli, harmonic, cumulativeSum, cumulativeProduct, prefixSum
    , fusedMultiplyAdd, saturatingAdd, saturatingSubtract, saturatingMultiply
    , checkedAdd, checkedSubtract, checkedMultiply, checkedFloatMultiply
    ) where

import qualified Data.List as L
import Data.Ratio ((%))
import HMath.Error (MathError(..))

add, subtractScalar, multiply :: Num a => a -> a -> a
add = (+)
subtractScalar = (-)
multiply = (*)

finite :: RealFloat a => a -> Bool
finite x = not (isNaN x || isInfinite x)

result :: RealFloat a => a -> Either MathError a
result x | finite x = Right x
         | otherwise = Left NonFiniteResult

inputs :: RealFloat a => [a] -> Either MathError ()
inputs xs | all finite xs = Right ()
          | otherwise = Left (DomainError "non-finite scalar input")

divide :: RealFloat a => a -> a -> Either MathError a
divide a b = do
    inputs [a,b]
    if b == 0 then Left (DomainError "division by zero") else result (a/b)

quotientRemainder, euclideanDivision :: Integer -> Integer -> Either MathError (Integer,Integer)
quotientRemainder _ 0 = Left (DomainError "division by zero")
quotientRemainder a b = Right (quotRem a b)
-- | Euclidean remainder satisfies 0 <= r < abs divisor, for either divisor sign.
euclideanDivision _ 0 = Left (DomainError "division by zero")
euclideanDivision a b = let r = a `mod` abs b in Right ((a-r) `quot` b,r)

absolute, sign :: Num a => a -> a
absolute = abs
sign = signum
minimumScalar, maximumScalar :: Ord a => a -> a -> a
minimumScalar = min
maximumScalar = max

clampChecked :: RealFloat a => a -> a -> a -> Either MathError a
clampChecked lo hi x = do
    inputs [lo,hi,x]
    if lo > hi then Left (DomainError "reversed clamp bounds") else Right (max lo (min hi x))

-- | Uses exact rational interpolation followed by one rounding. Extrapolation
-- is allowed; finite overflow is reported instead of silently producing infinity.
lerpChecked :: RealFloat a => a -> a -> a -> Either MathError a
lerpChecked a b t = do
    inputs [a,b,t]
    result (fromRational (toRational a + toRational t * (toRational b-toRational a)))

inverseLerp :: RealFloat a => a -> a -> a -> Either MathError a
inverseLerp a b x = do
    inputs [a,b,x]
    if a == b then Left (DomainError "equal interpolation endpoints")
      else result (fromRational ((toRational x-toRational a)/(toRational b-toRational a)))

remap :: RealFloat a => a -> a -> a -> a -> a -> Either MathError a
remap a b c d x = inverseLerp a b x >>= lerpChecked c d
step :: RealFloat a => a -> a -> Either MathError a
step edge x = inputs [edge,x] >> Right (if x < edge then 0 else 1)
smoothstep, smootherstep :: RealFloat a => a -> a -> a -> Either MathError a
smoothstep a b x = do
    t <- boundedParameter a b x
    result (t*t*(3-2*t))
smootherstep a b x = do
    t <- boundedParameter a b x
    result (t*t*t*(t*(t*6-15)+10))
boundedParameter :: RealFloat a => a -> a -> a -> Either MathError a
boundedParameter a b x
    | a >= b = Left (DomainError "smoothstep requires increasing edges")
    | otherwise = inverseLerp a b x >>= clampChecked 0 1

power :: RealFloat a => a -> a -> Either MathError a
power a b = inputs [a,b] >> result (a**b)
integerPower :: RealFloat a => a -> Integer -> Either MathError a
integerPower a n = do
    inputs [a]
    if a == 0 && n < 0 then Left (DomainError "negative power of zero") else result (a^^n)
modularPower :: Integer -> Integer -> Integer -> Either MathError Integer
modularPower a n m
    | n < 0 || m <= 0 = Left (DomainError "modular power needs nonnegative exponent and positive modulus")
    | otherwise = Right (go (a `mod` m) n (1 `mod` m))
  where
    go _ 0 acc = acc
    go b k acc = go ((b*b) `mod` m) (k `quot` 2) (if odd k then (acc*b) `mod` m else acc)

sqrtChecked, cubeRoot, reciprocalSqrt :: RealFloat a => a -> Either MathError a
sqrtChecked x = inputs [x] >> if x < 0 then Left (DomainError "negative square root") else result (sqrt x)
cubeRoot x = nthRoot 3 x
reciprocalSqrt x = inputs [x] >> if x <= 0 then Left (DomainError "reciprocal square root needs positive input") else result (1/sqrt x)
nthRoot :: RealFloat a => Int -> a -> Either MathError a
nthRoot n x = do
    inputs [x]
    if n <= 0 || (x < 0 && even n) then Left (DomainError "invalid real root")
      else if x == 0 then Right x else result (signum x * exp (log (abs x)/fromIntegral n))
expChecked, logChecked :: RealFloat a => a -> Either MathError a
expChecked x = inputs [x] >> result (exp x)
logChecked x = inputs [x] >> if x <= 0 then Left (DomainError "logarithm needs positive input") else result (log x)

expm1, log1p :: RealFloat a => a -> Either MathError a
expm1 x = do
    inputs [x]
    if x == 0 then Right x else result (if abs x < 0.5 then expSeries 1 x x else exp x-1)
  where
    expSeries k term acc
        | k >= 256 || next == acc = acc
        | otherwise = expSeries (k+1) term' next
      where term' = term*x/fromIntegral (k+1 :: Int)
            next = acc+term'
log1p x = do
    inputs [x]
    if x <= -1 then Left (DomainError "log1p needs input greater than -1")
      else if x == 0 then Right x
      else result (if abs x < 0.5 then series 1 y y else log (1+x))
  where
    y = x/(2+x)
    series k term acc
        | k >= 256 || next == acc = 2*acc
        | otherwise = series (k+1) term' next
      where term' = term*y*y
            next = acc+term'/fromIntegral (2*k+1 :: Int)

hypot :: RealFloat a => a -> a -> Either MathError a
hypot a b = do
    inputs [a,b]
    let hi = max (abs a) (abs b); lo = min (abs a) (abs b)
    if hi == 0 then Right 0 else result (hi*sqrt (1+(lo/hi)^ (2::Int)))

floorChecked, ceilChecked, roundChecked, truncateChecked, bankersRound :: RealFloat a => a -> Either MathError Integer
floorChecked x = inputs [x] >> Right (floor x)
ceilChecked x = inputs [x] >> Right (ceiling x)
roundChecked = bankersRound
truncateChecked x = inputs [x] >> Right (truncate x)
bankersRound x = inputs [x] >> Right (round x)
-- | Decimal-place rounding with exact rational scaling and ties to even. Negative
-- digits round to tens, hundreds, etc. Digits are bounded to avoid huge allocation.
roundDigits :: RealFloat a => Int -> a -> Either MathError a
roundDigits n x = do
    inputs [x]
    if abs (toInteger n) > 10000 then Left (InvalidArgument "rounding digit count exceeds 10000")
      else let scale = if n >= 0 then fromInteger (10^n) else 1/fromInteger (10^negate n)
           in result (fromRational (fromInteger (round (toRational x*scale))/scale))
integerFraction :: RealFloat a => a -> Either MathError (Integer,a)
integerFraction x = do
    inputs [x]
    let n=truncate x
    Right (n, if x == 0 then x else x-fromInteger n)
positiveModulo :: Integral a => a -> a -> Either MathError a
positiveModulo _ m | m <= 0 = Left (DomainError "modulus must be positive")
positiveModulo a m = Right (a `mod` m)
absoluteError, relativeError :: RealFloat a => a -> a -> Either MathError a
absoluteError actual expected = inputs [actual,expected] >> result (abs (actual-expected))
relativeError actual expected = if expected == 0 then Left (DomainError "zero reference for relative error") else absoluteError actual expected >>= \e -> result (e/abs expected)

nonnegative :: Integer -> Either MathError ()
nonnegative n | n < 0 = Left (DomainError "negative integer argument")
              | otherwise = Right ()
factorialChecked, doubleFactorial, fibonacciChecked, lucas, catalan :: Integer -> Either MathError Integer
factorialChecked n = nonnegative n >> Right (product [1..n])
doubleFactorial n | n == -1 = Right 1
                  | otherwise = nonnegative n >> Right (product [n,n-2..1])
risingFactorial, fallingFactorial :: Integer -> Integer -> Either MathError Integer
risingFactorial x n = nonnegative n >> Right (product [x..x+n-1])
fallingFactorial x n = nonnegative n >> Right (product [x-n+1..x])
fibonacciChecked n = nonnegative n >> Right (fst (fibPair n))
fibPair :: Integer -> (Integer,Integer)
fibPair 0 = (0,1)
fibPair n = let (a,b)=fibPair (n `quot` 2); c=a*(2*b-a); d=a*a+b*b
            in if even n then (c,d) else (d,c+d)
lucas n = nonnegative n >> let (a,b)=fibPair n in Right (2*b-a)
permutations, combinations :: Integer -> Integer -> Either MathError Integer
permutations n k = do
    nonnegative n; nonnegative k
    if k > n then Right 0 else Right (product [n-k+1..n])
combinations n k = do
    nonnegative n; nonnegative k
    if k > n then Right 0 else let j=min k (n-k) in Right (product [n-j+1..n] `quot` product [1..j])
multinomial :: [Integer] -> Either MathError Integer
multinomial ks = do
    mapM_ nonnegative ks
    f <- factorialChecked (sum ks)
    fs <- mapM factorialChecked ks
    Right (f `quot` product fs)
catalan n = nonnegative n >> fmap (`quot` (n+1)) (combinations (2*n) n)
-- | Bernoulli convention B1 = -1/2. Akiyama-Tanigawa exact rational recurrence.
bernoulli :: Int -> Either MathError Rational
bernoulli n
    | n < 0 = Left (DomainError "negative Bernoulli index")
    | otherwise = Right (if n == 1 then -1/2 else first (L.foldl' advance [] [0..n]))
  where
    first (x:_) = x
    first [] = 0
    advance acc m = update (acc++[1 % fromIntegral (m+1)]) m
    update xs 0 = xs
    update xs j = update (take (j-1) xs ++ [fromIntegral j*(xs!!(j-1)-xs!!j)] ++ drop j xs) (j-1)
harmonic :: Integer -> Either MathError Rational
harmonic n = nonnegative n >> Right (sum [1 % k | k <- [1..n]])
cumulativeSum, prefixSum, cumulativeProduct :: Num a => [a] -> [a]
cumulativeSum = drop 1 . scanl (+) 0
prefixSum = scanl (+) 0
cumulativeProduct = drop 1 . scanl (*) 1

-- | Software single-rounding FMA for finite inputs using exact 'Rational'. This
-- avoids intermediate overflow and cancellation; it does not change CPU flags.
fusedMultiplyAdd :: RealFloat a => a -> a -> a -> Either MathError a
fusedMultiplyAdd a b c = do
    inputs [a,b,c]
    let r=toRational a*toRational b+toRational c
    result (if r == 0 && a*b == 0 && c == 0 then a*b+c else fromRational r)

saturatingAdd, saturatingSubtract, saturatingMultiply :: (Integral a, Bounded a) => a -> a -> a
saturatingAdd a b = saturate (toInteger a+toInteger b)
saturatingSubtract a b = saturate (toInteger a-toInteger b)
saturatingMultiply a b = saturate (toInteger a*toInteger b)
saturate :: (Integral a, Bounded a) => Integer -> a
saturate n = x where x=fromInteger (max (toInteger (minBound `asTypeOf` x)) (min (toInteger (maxBound `asTypeOf` x)) n))
checkedAdd, checkedSubtract, checkedMultiply :: (Integral a, Bounded a) => a -> a -> Either MathError a
checkedAdd a b = boundedResult (toInteger a+toInteger b)
checkedSubtract a b = boundedResult (toInteger a-toInteger b)
checkedMultiply a b = boundedResult (toInteger a*toInteger b)
boundedResult :: (Integral a, Bounded a) => Integer -> Either MathError a
boundedResult n = r where
    r = if n < toInteger (minBound `asTypeOf` x) || n > toInteger (maxBound `asTypeOf` x)
          then Left (DomainError "integer overflow") else Right x
    x=fromInteger n
-- | Report finite overflow and any nonzero exact product rounded to zero.
checkedFloatMultiply :: RealFloat a => a -> a -> Either MathError a
checkedFloatMultiply a b = do
    inputs [a,b]
    v <- result (a*b)
    if v == 0 && a /= 0 && b /= 0 then Left (DomainError "floating-point underflow") else Right v
