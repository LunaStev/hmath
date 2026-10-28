-- SPDX-License-Identifier: MPL-2.0

{- | Scalar utilities. Generic Num arithmetic follows the chosen numeric type.
Checked real operations require finite inputs and report domain failures and
finite-result overflow explicitly. Exact combinatorics use 'Integer'.
expm1/log1p use convergent series near zero to avoid cancellation; their target
is a few ulps for ordinary IEEE binary32/64 inputs, not correct rounding.
-}
module HMath.Scalar (
    add,
    subtractScalar,
    multiply,
    divide,
    quotientRemainder,
    euclideanDivision,
    absolute,
    sign,
    minimumScalar,
    maximumScalar,
    clampChecked,
    lerpChecked,
    inverseLerp,
    remap,
    step,
    smoothstep,
    smootherstep,
    power,
    integerPower,
    modularPower,
    sqrtChecked,
    cubeRoot,
    nthRoot,
    reciprocalSqrt,
    expChecked,
    logChecked,
    expm1,
    log1p,
    hypot,
    floorChecked,
    ceilChecked,
    roundChecked,
    truncateChecked,
    bankersRound,
    roundDigits,
    integerFraction,
    positiveModulo,
    absoluteError,
    relativeError,
    factorialChecked,
    doubleFactorial,
    risingFactorial,
    fallingFactorial,
    fibonacciChecked,
    lucas,
    permutations,
    combinations,
    multinomial,
    catalan,
    bernoulli,
    harmonic,
    cumulativeSum,
    cumulativeProduct,
    prefixSum,
    fusedMultiplyAdd,
    saturatingAdd,
    saturatingSubtract,
    saturatingMultiply,
    checkedAdd,
    checkedSubtract,
    checkedMultiply,
    checkedFloatMultiply,
) where

import qualified Data.List as L
import Data.Ratio ((%))
import HMath.Error (MathError (..))

add, subtractScalar, multiply :: (Num a) => a -> a -> a

{- | Add two values using their Num instance. No overflow check is added; bounded integral
types retain their usual arithmetic behavior. Example: add 2 3 == 5.
-}
add = (+)

{- | Subtract the second value from the first using Num arithmetic. Example: subtractScalar
5 2 == 3; use checkedSubtract to reject bounded integer overflow.
-}
subtractScalar = (-)

{- | Multiply two values using Num arithmetic. Example: multiply 3 4 == 12; use
checkedMultiply or checkedFloatMultiply for explicit overflow checks.
-}
multiply = (*)

finite :: (RealFloat a) => a -> Bool
finite x = not (isNaN x || isInfinite x)

result :: (RealFloat a) => a -> Either MathError a
result x
    | finite x = Right x
    | otherwise = Left NonFiniteResult

inputs :: (RealFloat a) => [a] -> Either MathError ()
inputs xs
    | all finite xs = Right ()
    | otherwise = Left (DomainError "non-finite scalar input")

{- | Divide the first finite real value by the second. Return Left DomainError for
non-finite input or a zero divisor, and Left NonFiniteResult for overflow. Example:
divide 6 2 == Right 3.
-}
divide :: (RealFloat a) => a -> a -> Either MathError a
divide a b = do
    inputs [a, b]
    if b == 0 then Left (DomainError "division by zero") else result (a / b)

quotientRemainder, euclideanDivision :: Integer -> Integer -> Either MathError (Integer, Integer)

{- | Return integer quotient and remainder using quotRem (quotient truncates toward zero). A
zero divisor returns Left DomainError. Example: quotientRemainder (-7) 3 == Right
(-2,-1).
-}
quotientRemainder _ 0 = Left (DomainError "division by zero")
quotientRemainder a b = Right (quotRem a b)

-- | Euclidean remainder satisfies 0 <= r < abs divisor, for either divisor sign.
euclideanDivision _ 0 = Left (DomainError "division by zero")
euclideanDivision a b = let r = a `mod` abs b in Right ((a - r) `quot` b, r)

absolute, sign :: (Num a) => a -> a

{- | Return abs using the supplied Num instance, including that instance's overflow
behavior. Example: absolute (-3) == 3.
-}
absolute = abs

-- | Return signum using the supplied Num instance. Example: sign (-3) == -1; sign 0 == 0.
sign = signum

minimumScalar, maximumScalar :: (Ord a) => a -> a -> a

{- | Return the smaller of two values under their Ord instance. Example: minimumScalar 2 5
== 2.
-}
minimumScalar = min

{- | Return the larger of two values under their Ord instance. Example: maximumScalar 2 5 ==
5.
-}
maximumScalar = max

{- | Given lower bound, upper bound, then value, clamp to the closed interval. Non-finite
inputs or reversed bounds return Left DomainError. Example: clampChecked 0 1 2 == Right
1.
-}
clampChecked :: (RealFloat a) => a -> a -> a -> Either MathError a
clampChecked lo hi x = do
    inputs [lo, hi, x]
    if lo > hi then Left (DomainError "reversed clamp bounds") else Right (max lo (min hi x))

{- | Uses exact rational interpolation followed by one rounding. Extrapolation
is allowed; finite overflow is reported instead of silently producing infinity.
-}
lerpChecked :: (RealFloat a) => a -> a -> a -> Either MathError a
lerpChecked a b t = do
    inputs [a, b, t]
    result (fromRational (toRational a + toRational t * (toRational b - toRational a)))

{- | Given endpoints a,b then value x, return (x-a)/(b-a) using rational intermediates and
one conversion. Equal endpoints/non-finite inputs fail; extrapolation is allowed.
Example: inverseLerp 10 20 15 == Right 0.5.
-}
inverseLerp :: (RealFloat a) => a -> a -> a -> Either MathError a
inverseLerp a b x = do
    inputs [a, b, x]
    if a == b
        then Left (DomainError "equal interpolation endpoints")
        else result (fromRational ((toRational x - toRational a) / (toRational b - toRational a)))

{- | Given source endpoints a,b, destination endpoints c,d, then x, map x from the source
interval to the destination interval. Extrapolation is allowed. Fails on equal source
endpoints, non-finite input/result. Example: remap 0 10 0 100 5 == Right 50.
-}
remap :: (RealFloat a) => a -> a -> a -> a -> a -> Either MathError a
remap a b c d x = inverseLerp a b x >>= lerpChecked c d

{- | Given edge then x, return 0 below the edge and 1 at/above it. Non-finite inputs return
Left DomainError. Example: step 2 2 == Right 1.
-}
step :: (RealFloat a) => a -> a -> Either MathError a
step edge x = inputs [edge, x] >> Right (if x < edge then 0 else 1)

smoothstep, smootherstep :: (RealFloat a) => a -> a -> a -> Either MathError a

{- | Given strictly increasing edges then x, clamp t=(x-a)/(b-a) to [0,1] and return
t*t*(3-2*t). Invalid edges/non-finite values fail. Example: smoothstep 0 1 0.5 == Right
0.5.
-}
smoothstep a b x = do
    t <- boundedParameter a b x
    result (t * t * (3 - 2 * t))

{- | Given increasing edges then x, apply the quintic 6t^5-15t^4+10t^3 to the clamped
interpolation parameter. Invalid edges/non-finite values fail. Example: smootherstep 0
1 0.5 == Right 0.5.
-}
smootherstep a b x = do
    t <- boundedParameter a b x
    result (t * t * t * (t * (t * 6 - 15) + 10))

boundedParameter :: (RealFloat a) => a -> a -> a -> Either MathError a
boundedParameter a b x
    | a >= b = Left (DomainError "smoothstep requires increasing edges")
    | otherwise = inverseLerp a b x >>= clampChecked 0 1

{- | Raise a finite real base to a finite real exponent using (**). Non-real/domain results
and overflow return Left NonFiniteResult; non-finite input fails. Example: power 2 3 ==
Right 8.
-}
power :: (RealFloat a) => a -> a -> Either MathError a
power a b = inputs [a, b] >> result (a ** b)

{- | Raise a finite real base to an Integer exponent, allowing negative powers except for a
zero base. Invalid zero reciprocal/non-finite input fails; overflow is NonFiniteResult.
Example: integerPower 2 (-2) == Right 0.25.
-}
integerPower :: (RealFloat a) => a -> Integer -> Either MathError a
integerPower a n = do
    inputs [a]
    if a == 0 && n < 0 then Left (DomainError "negative power of zero") else result (a ^^ n)

{- | Given base, nonnegative exponent, positive modulus, compute modular exponentiation by
squaring. Invalid exponent/modulus returns Left DomainError. Example: modularPower 2 10
1000 == Right 24.
-}
modularPower :: Integer -> Integer -> Integer -> Either MathError Integer
modularPower a n m
    | n < 0 || m <= 0 =
        Left (DomainError "modular power needs nonnegative exponent and positive modulus")
    | otherwise = Right (go (a `mod` m) n (1 `mod` m))
  where
    go _ 0 acc = acc
    go b k acc = go ((b * b) `mod` m) (k `quot` 2) (if odd k then (acc * b) `mod` m else acc)

sqrtChecked, cubeRoot, reciprocalSqrt :: (RealFloat a) => a -> Either MathError a

{- | Return the nonnegative square root of a finite nonnegative input; reject
negatives/non-finite values. Example: sqrtChecked 9 == Right 3.
-}
sqrtChecked x = inputs [x] >> if x < 0 then Left (DomainError "negative square root") else result (sqrt x)

{- | Return the signed real cube root of a finite input, including negative values, through
nthRoot 3. Example: cubeRoot (-8) is approximately Right (-2).
-}
cubeRoot x = nthRoot 3 x

{- | Return 1/sqrt(x) for finite strictly positive x. Zero/negative/non-finite inputs fail,
as does a non-finite result. Example: reciprocalSqrt 4 == Right 0.5.
-}
reciprocalSqrt x =
    inputs [x]
        >> if x <= 0
            then Left (DomainError "reciprocal square root needs positive input")
            else result (1 / sqrt x)

{- | Given positive integer degree n then finite x, return its signed real n-th root. Even
roots of negative x and nonpositive degrees fail. Example: nthRoot 3 (-8) is
approximately Right (-2).
-}
nthRoot :: (RealFloat a) => Int -> a -> Either MathError a
nthRoot n x = do
    inputs [x]
    if n <= 0 || (x < 0 && even n)
        then Left (DomainError "invalid real root")
        else if x == 0 then Right x else result (signum x * exp (log (abs x) / fromIntegral n))

expChecked, logChecked :: (RealFloat a) => a -> Either MathError a

{- | Compute exp of a finite input, reporting non-finite output as Left NonFiniteResult.
Finite underflow to zero is allowed. Example: expChecked 0 == Right 1.
-}
expChecked x = inputs [x] >> result (exp x)

{- | Compute the natural logarithm of finite positive x. Zero/negative/non-finite input
fails. Example: logChecked 1 == Right 0.
-}
logChecked x =
    inputs [x] >> if x <= 0 then Left (DomainError "logarithm needs positive input") else result (log x)

expm1, log1p :: (RealFloat a) => a -> Either MathError a

{- | Compute exp(x)-1, using a convergent series near zero to reduce cancellation. Reject
non-finite input/output; preserve signed zero. Example: expm1 0 == Right 0. This is not
a correct-rounding guarantee.
-}
expm1 x = do
    inputs [x]
    if x == 0 then Right x else result (if abs x < 0.5 then expSeries 1 x x else exp x - 1)
  where
    expSeries k term acc
        | k >= 256 || next == acc = acc
        | otherwise = expSeries (k + 1) term' next
      where
        term' = term * x / fromIntegral (k + 1 :: Int)
        next = acc + term'

{- | Compute log(1+x), using a series near zero. Require finite x greater than -1; preserve
signed zero and reject non-finite output. Example: log1p 0 == Right 0.
-}
log1p x = do
    inputs [x]
    if x <= -1
        then Left (DomainError "log1p needs input greater than -1")
        else
            if x == 0
                then Right x
                else result (if abs x < 0.5 then series 1 y y else log (1 + x))
  where
    y = x / (2 + x)
    series k term acc
        | k >= 256 || next == acc = 2 * acc
        | otherwise = series (k + 1) term' next
      where
        term' = term * y * y
        next = acc + term' / fromIntegral (2 * k + 1 :: Int)

{- | Return sqrt(a*a+b*b) with scaling to avoid avoidable intermediate overflow. Require
finite inputs and result. Example: hypot 3 4 == Right 5.
-}
hypot :: (RealFloat a) => a -> a -> Either MathError a
hypot a b = do
    inputs [a, b]
    let hi = max (abs a) (abs b); lo = min (abs a) (abs b)
    if hi == 0 then Right 0 else result (hi * sqrt (1 + (lo / hi) ^ (2 :: Int)))

floorChecked
    , ceilChecked
    , roundChecked
    , truncateChecked
    , bankersRound ::
        (RealFloat a) => a -> Either MathError Integer

{- | Convert a finite real to the greatest Integer no larger than it. Non-finite input
fails. Example: floorChecked (-1.2) == Right (-2).
-}
floorChecked x = inputs [x] >> Right (floor x)

{- | Convert a finite real to the least Integer no smaller than it. Non-finite input fails.
Example: ceilChecked 1.2 == Right 2.
-}
ceilChecked x = inputs [x] >> Right (ceiling x)

{- | Round a finite real to Integer with ties to even, as bankersRound. Non-finite input
fails. Example: roundChecked 2.5 == Right 2.
-}
roundChecked = bankersRound

{- | Convert finite real to Integer toward zero. Non-finite input fails. Example:
truncateChecked (-1.8) == Right (-1).
-}
truncateChecked x = inputs [x] >> Right (truncate x)

{- | Round a finite real to nearest Integer, resolving exact half ties to even. Non-finite
input fails. Example: bankersRound 3.5 == Right 4.
-}
bankersRound x = inputs [x] >> Right (round x)

{- | Decimal-place rounding with exact rational scaling and ties to even. Negative
digits round to tens, hundreds, etc. Digits are bounded to avoid huge allocation.
-}
roundDigits :: (RealFloat a) => Int -> a -> Either MathError a
roundDigits n x = do
    inputs [x]
    if abs (toInteger n) > 10000
        then Left (InvalidArgument "rounding digit count exceeds 10000")
        else
            let scale = if n >= 0 then fromInteger (10 ^ n) else 1 / fromInteger (10 ^ negate n)
             in result (fromRational (fromInteger (round (toRational x * scale)) / scale))

{- | Split finite x into its truncated Integer and signed fractional remainder. Non-finite
input fails. Example: integerFraction (-1.5) == Right (-1,-0.5).
-}
integerFraction :: (RealFloat a) => a -> Either MathError (Integer, a)
integerFraction x = do
    inputs [x]
    let n = truncate x
    Right (n, if x == 0 then x else x - fromInteger n)

{- | Given integral value then strictly positive modulus, return the nonnegative remainder.
Nonpositive modulus fails. Example: positiveModulo (-1) 5 == Right 4.
-}
positiveModulo :: (Integral a) => a -> a -> Either MathError a
positiveModulo _ m | m <= 0 = Left (DomainError "modulus must be positive")
positiveModulo a m = Right (a `mod` m)

absoluteError, relativeError :: (RealFloat a) => a -> a -> Either MathError a

{- | Given actual then expected finite values, return abs(actual-expected); reject
non-finite input/result. Example: absoluteError 3 2 == Right 1.
-}
absoluteError actual expected = inputs [actual, expected] >> result (abs (actual - expected))

{- | Given actual then expected, return absolute error divided by abs(expected). Expected
must be nonzero and inputs/results finite. Example: relativeError 3 2 == Right 0.5.
-}
relativeError actual expected =
    if expected == 0
        then Left (DomainError "zero reference for relative error")
        else absoluteError actual expected >>= \e -> result (e / abs expected)

nonnegative :: Integer -> Either MathError ()
nonnegative n
    | n < 0 = Left (DomainError "negative integer argument")
    | otherwise = Right ()
factorialChecked
    , doubleFactorial
    , fibonacciChecked
    , lucas
    , catalan ::
        Integer -> Either MathError Integer

{- | Return exact n! for nonnegative Integer n; negatives fail with DomainError. Example:
factorialChecked 5 == Right 120. No fixed-size arithmetic overflow occurs.
-}
factorialChecked n = nonnegative n >> Right (product [1 .. n])

{- | Return n*(n-2)*... exactly for n >= 0; (-1)!! is also 1. Other negative n fail.
Example: doubleFactorial 5 == Right 15.
-}
doubleFactorial n
    | n == -1 = Right 1
    | otherwise = nonnegative n >> Right (product [n, n - 2 .. 1])

risingFactorial, fallingFactorial :: Integer -> Integer -> Either MathError Integer

{- | Given integer x then nonnegative length n, return x*(x+1)*...*(x+n-1). Negative length
fails; length zero gives 1. Example: risingFactorial 3 2 == Right 12.
-}
risingFactorial x n = nonnegative n >> Right (product [x .. x + n - 1])

{- | Given integer x then nonnegative length n, return x*(x-1)*...*(x-n+1). Negative length
fails; length zero gives 1. Example: fallingFactorial 3 2 == Right 6.
-}
fallingFactorial x n = nonnegative n >> Right (product [x - n + 1 .. x])

{- | Return exact zero-based Fibonacci number using fast doubling (F0=0,F1=1). Negative
index fails. Example: fibonacciChecked 10 == Right 55.
-}
fibonacciChecked n = nonnegative n >> Right (fst (fibPair n))

fibPair :: Integer -> (Integer, Integer)
fibPair 0 = (0, 1)
fibPair n =
    let (a, b) = fibPair (n `quot` 2); c = a * (2 * b - a); d = a * a + b * b
     in if even n then (c, d) else (d, c + d)

{- | Return exact zero-based Lucas number (L0=2,L1=1). Negative index fails. Example: lucas
5 == Right 11.
-}
lucas n = nonnegative n >> let (a, b) = fibPair n in Right (2 * b - a)

permutations, combinations :: Integer -> Integer -> Either MathError Integer

{- | Given nonnegative n,k, return n!/(n-k)!; k>n gives zero. Negative inputs fail. Example:
permutations 4 2 == Right 12.
-}
permutations n k = do
    nonnegative n
    nonnegative k
    if k > n then Right 0 else Right (product [n - k + 1 .. n])

{- | Given nonnegative n,k, return the exact binomial coefficient; k>n gives zero. Negative
inputs fail. Example: combinations 4 2 == Right 6.
-}
combinations n k = do
    nonnegative n
    nonnegative k
    if k > n
        then Right 0
        else let j = min k (n - k) in Right (product [n - j + 1 .. n] `quot` product [1 .. j])

{- | Given nonnegative group sizes, return factorial(sum sizes)/product(factorial sizes).
Negative entries fail. Example: multinomial [2,1] == Right 3.
-}
multinomial :: [Integer] -> Either MathError Integer
multinomial ks = do
    mapM_ nonnegative ks
    f <- factorialChecked (sum ks)
    fs <- mapM factorialChecked ks
    Right (f `quot` product fs)

{- | Return exact n-th Catalan number for nonnegative Integer n; negative input fails.
Example: catalan 3 == Right 5.
-}
catalan n = nonnegative n >> fmap (`quot` (n + 1)) (combinations (2 * n) n)

-- | Bernoulli convention B1 = -1/2. Akiyama-Tanigawa exact rational recurrence.
bernoulli :: Int -> Either MathError Rational
bernoulli n
    | n < 0 = Left (DomainError "negative Bernoulli index")
    | otherwise = Right (if n == 1 then -1 / 2 else first (L.foldl' advance [] [0 .. n]))
  where
    first (x : _) = x
    first [] = 0
    advance acc m = update (acc ++ [1 % fromIntegral (m + 1)]) m
    update xs 0 = xs
    update xs j = update (take (j - 1) xs ++ [fromIntegral j * (xs !! (j - 1) - xs !! j)] ++ drop j xs) (j - 1)

{- | Return exact Rational sum 1+1/2+...+1/n; n=0 gives 0 and negatives fail. Example:
harmonic 2 == Right (3/2).
-}
harmonic :: Integer -> Either MathError Rational
harmonic n = nonnegative n >> Right (sum [1 % k | k <- [1 .. n]])

cumulativeSum, prefixSum, cumulativeProduct :: (Num a) => [a] -> [a]

{- | Return inclusive running sums without a leading zero; output has input length.
Arithmetic follows Num. Example: cumulativeSum [1,2,3] == [1,3,6].
-}
cumulativeSum = drop 1 . scanl (+) 0

{- | Return running sums including a leading zero; output length is input length plus one.
Example: prefixSum [1,2] == [0,1,3].
-}
prefixSum = scanl (+) 0

{- | Return inclusive running products without a leading one. Arithmetic follows Num.
Example: cumulativeProduct [2,3,4] == [2,6,24].
-}
cumulativeProduct = drop 1 . scanl (*) 1

{- | Software single-rounding FMA for finite inputs using exact 'Rational'. This
avoids intermediate overflow and cancellation; it does not change CPU flags.
-}
fusedMultiplyAdd :: (RealFloat a) => a -> a -> a -> Either MathError a
fusedMultiplyAdd a b c = do
    inputs [a, b, c]
    let r = toRational a * toRational b + toRational c
    result (if r == 0 && a * b == 0 && c == 0 then a * b + c else fromRational r)

saturatingAdd, saturatingSubtract, saturatingMultiply :: (Integral a, Bounded a) => a -> a -> a

{- | Add bounded integers through an exact Integer intermediate and clamp to the destination
minBound/maxBound. Example: saturatingAdd (127 :: Int8) 1 == 127.
-}
saturatingAdd a b = saturate (toInteger a + toInteger b)

{- | Subtract bounded integers through Integer and clamp to type bounds instead of wrapping.
Example: saturatingSubtract (0 :: Word8) 1 == 0.
-}
saturatingSubtract a b = saturate (toInteger a - toInteger b)

{- | Multiply bounded integers through Integer and clamp to type bounds instead of wrapping.
Example: saturatingMultiply (100 :: Int8) 2 == 127.
-}
saturatingMultiply a b = saturate (toInteger a * toInteger b)

saturate :: (Integral a, Bounded a) => Integer -> a
saturate n = x
  where
    x = fromInteger (max (toInteger (minBound `asTypeOf` x)) (min (toInteger (maxBound `asTypeOf` x)) n))
checkedAdd
    , checkedSubtract
    , checkedMultiply ::
        (Integral a, Bounded a) => a -> a -> Either MathError a

{- | Add bounded integers using an exact intermediate. Out-of-range results return Left
DomainError, never wrap. Example: checkedAdd (2 :: Int8) 3 == Right 5.
-}
checkedAdd a b = boundedResult (toInteger a + toInteger b)

{- | Subtract bounded integers using an exact intermediate, returning Left DomainError on
underflow/overflow. Example: checkedSubtract (0 :: Word8) 1 fails.
-}
checkedSubtract a b = boundedResult (toInteger a - toInteger b)

{- | Multiply bounded integers using an exact intermediate and reject out-of-range results.
Example: checkedMultiply (100 :: Int8) 2 fails.
-}
checkedMultiply a b = boundedResult (toInteger a * toInteger b)

boundedResult :: (Integral a, Bounded a) => Integer -> Either MathError a
boundedResult n = r
  where
    r =
        if n < toInteger (minBound `asTypeOf` x) || n > toInteger (maxBound `asTypeOf` x)
            then Left (DomainError "integer overflow")
            else Right x
    x = fromInteger n

-- | Report finite overflow and any nonzero exact product rounded to zero.
checkedFloatMultiply :: (RealFloat a) => a -> a -> Either MathError a
checkedFloatMultiply a b = do
    inputs [a, b]
    v <- result (a * b)
    if v == 0 && a /= 0 && b /= 0 then Left (DomainError "floating-point underflow") else Right v
