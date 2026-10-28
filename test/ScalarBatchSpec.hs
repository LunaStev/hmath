-- SPDX-License-Identifier: MPL-2.0
module ScalarBatchSpec (scalarBatchTests) where

import Data.Bits ((.&.))
import Data.Complex (Complex (..), magnitude)
import Data.Int (Int8)
import Data.Ratio ((%))
import Data.Word (Word16, Word8)
import GHC.Float (castDoubleToWord64, castWord64ToDouble)
import qualified HMath.Constants as C
import HMath.Error (MathError (..))
import qualified HMath.Numeric as N
import qualified HMath.Scalar as S
import qualified HMath.Trigonometry as T
import qualified HMath.Units as U

near :: Double -> Double -> Bool
near a b = abs (a - b) <= 1e-12 * max 1 (max (abs a) (abs b))
rightNear :: Either MathError Double -> Double -> Bool
rightNear x expected = either (const False) (`near` expected) x
left :: Either a b -> Bool
left (Left _) = True
left _ = False
must :: Either a Bool -> Bool
must = either (const False) id

scalarBatchTests :: [(String, Bool)]
scalarBatchTests =
    [
        ( "scalar arithmetic and Euclidean division"
        , and
            [ S.add (2 :: Integer) 3 == 5
            , S.subtractScalar (2 :: Integer) 3 == -1
            , S.multiply (2 :: Integer) 3 == 6
            , S.divide (7 :: Double) 2 == Right 3.5
            , left (S.divide (1 :: Double) 0)
            , all
                ( \(a, b) -> must $ do (q, r) <- S.euclideanDivision a b; Right (a == q * b + r && r >= 0 && r < abs b)
                )
                [(a, b) | a <- [-20 .. 20], b <- [-7 .. 7], b /= 0]
            , S.quotientRemainder (-7) 3 == Right (-2, -1)
            , S.euclideanDivision (-7) 3 == Right (-3, 2)
            , left (S.quotientRemainder 1 0)
            , left (S.euclideanDivision 1 0)
            ]
        )
    ,
        ( "scalar absolute/sign/min/max"
        , S.absolute (-4 :: Integer) == 4
            && S.sign (-3 :: Double) == -1
            && S.minimumScalar (3 :: Int) 5 == 3
            && S.maximumScalar (3 :: Int) 5 == 5
        )
    ,
        ( "clamp and interpolation domains"
        , S.clampChecked (0 :: Double) 1 2 == Right 1
            && left (S.clampChecked (2 :: Double) 1 0)
            && left (S.inverseLerp (1 :: Double) 1 2)
            && S.lerpChecked (-1e308 :: Double) 1e308 0.5 == Right 0
            && S.inverseLerp (-1e308 :: Double) 1e308 0 == Right 0.5
            && S.remap (0 :: Double) 10 20 40 5 == Right 30
        )
    ,
        ( "step and smooth interpolation"
        , S.step (0 :: Double) 0 == Right 1
            && S.smoothstep (0 :: Double) 1 0.5 == Right 0.5
            && S.smootherstep (0 :: Double) 1 0.5 == Right 0.5
            && S.smoothstep (0 :: Double) 1 (-2) == Right 0
            && S.smootherstep (0 :: Double) 1 2 == Right 1
            && left (S.smoothstep (1 :: Double) 1 0)
        )
    ,
        ( "scalar powers and roots"
        , S.integerPower (2 :: Double) (-3) == Right 0.125
            && S.power (2 :: Double) 3 == Right 8
            && left (S.integerPower (0 :: Double) (-1))
            && S.modularPower 7 560 561 == Right 1
            && left (S.modularPower 2 (-1) 5)
            && rightNear (S.nthRoot 3 (-27)) (-3)
            && rightNear (S.cubeRoot 125) 5
            && S.sqrtChecked (4 :: Double) == Right 2
            && S.reciprocalSqrt (4 :: Double) == Right 0.5
            && left (S.nthRoot 2 (-1 :: Double))
            && left (S.nthRoot 0 (1 :: Double))
        )
    ,
        ( "scalar exp/log domains"
        , rightNear (S.logChecked (exp 2)) 2
            && rightNear (S.expChecked 2) (exp 2)
            && left (S.logChecked (0 :: Double))
            && left (S.log1p (-1 :: Double))
            && left (S.expChecked (1000 :: Double))
        )
    ,
        ( "expm1/log1p cancellation-sensitive references"
        , all tinyAccurate [1e-18, -1e-18, 1e-10, -1e-10, 0.1, -0.1, 0.49, -0.49]
        )
    ,
        ( "expm1/log1p signed zero"
        , either (const False) isNegativeZero (S.expm1 (-0 :: Double))
            && either (const False) isNegativeZero (S.log1p (-0 :: Double))
        )
    ,
        ( "scaled hypot avoids intermediate overflow"
        , rightNear (S.hypot 3e200 4e200) 5e200
            && S.hypot (0 :: Double) 0 == Right 0
            && left (S.hypot (1 / 0 :: Double) 1)
        )
    ,
        ( "rounding modes and negative decimal digits"
        , S.bankersRound (2.5 :: Double) == Right 2
            && S.bankersRound (3.5 :: Double) == Right 4
            && S.bankersRound (-2.5 :: Double) == Right (-2)
            && S.floorChecked (-1.2 :: Double) == Right (-2)
            && S.ceilChecked (-1.2 :: Double) == Right (-1)
            && S.truncateChecked (-1.8 :: Double) == Right (-1)
            && S.roundDigits (-2) (1250 :: Double) == Right 1200
            && S.roundDigits 2 (2.675 :: Double) == Right 2.67
            && left (S.roundDigits minBound (1 :: Double))
        )
    ,
        ( "fraction and positive modulo"
        , S.integerFraction (-3.25 :: Double) == Right (-3, -0.25)
            && S.positiveModulo (-7 :: Integer) 3 == Right 2
            && left (S.positiveModulo (1 :: Integer) 0)
        )
    ,
        ( "relative and absolute errors"
        , rightNear (S.absoluteError 1.1 1) 0.1
            && rightNear (S.relativeError 11 10) 0.1
            && left (S.relativeError (0 :: Double) 0)
        )
    ,
        ( "exact factorial families"
        , S.factorialChecked 20 == Right 2432902008176640000
            && S.doubleFactorial 9 == Right 945
            && S.doubleFactorial 0 == Right 1
            && S.doubleFactorial (-1) == Right 1
            && S.risingFactorial 3 4 == Right 360
            && S.fallingFactorial 5 3 == Right 60
            && left (S.factorialChecked (-1))
        )
    ,
        ( "fast Fibonacci and Lucas"
        , S.fibonacciChecked 100 == Right 354224848179261915075
            && S.lucas 0 == Right 2
            && S.lucas 10 == Right 123
            && left (S.fibonacciChecked (-1))
        )
    ,
        ( "exact combinatorics"
        , S.permutations 5 3 == Right 60
            && S.combinations 100 50 == Right 100891344545564193334812497256
            && S.combinations 5 8 == Right 0
            && S.multinomial [2, 3, 1] == Right 60
            && S.catalan 10 == Right 16796
            && S.bernoulli 0 == Right 1
            && S.bernoulli 1 == Right (-1 / 2)
            && S.bernoulli 2 == Right (1 / 6)
            && S.bernoulli 4 == Right (-1 / 30)
            && S.bernoulli 12 == Right (-691 / 2730)
            && S.harmonic 5 == Right (137 / 60)
        )
    ,
        ( "cumulative operations"
        , S.cumulativeSum ([1, 2, 3] :: [Integer]) == [1, 3, 6]
            && S.prefixSum ([1, 2, 3] :: [Integer]) == [0, 1, 3, 6]
            && S.cumulativeProduct ([1, 2, 3] :: [Integer]) == [1, 2, 6]
            && S.cumulativeSum ([] :: [Int]) == []
        )
    ,
        ( "single-rounding exact FMA"
        , S.fusedMultiplyAdd (1 + 2 ** (-27) :: Double) (1 - 2 ** (-27)) (-1) == Right (-2 ** (-54))
            && S.fusedMultiplyAdd (1e308 :: Double) 2 (-1e308) == Right 1e308
            && left (S.fusedMultiplyAdd (1 / 0 :: Double) 0 1)
        )
    ,
        ( "bounded saturating arithmetic"
        , S.saturatingAdd (120 :: Int8) 30 == 127
            && S.saturatingSubtract (2 :: Word8) 3 == 0
            && S.saturatingMultiply (-100 :: Int8) 2 == -128
            && left (S.checkedAdd (127 :: Int8) 1)
            && S.checkedMultiply (10 :: Int8) 12 == Right 120
        )
    ,
        ( "finite overflow and underflow"
        , left (S.checkedFloatMultiply (1e308 :: Double) 2)
            && left (S.checkedFloatMultiply (encodeFloat 1 (-1074) :: Double) 0.5)
            && S.checkedFloatMultiply (0 :: Double) 1 == Right 0
        )
    ,
        ( "nonfinite scalar rejection"
        , and
            [ left (S.clampChecked (0 :: Double) 1 (0 / 0))
            , left (S.floorChecked (1 / 0 :: Double))
            , left (S.inverseLerp (0 :: Double) 1 (1 / 0))
            , left (S.nthRoot 3 (1 / 0 :: Double))
            ]
        )
    ,
        ( "type-specific IEEE limits"
        , let d = N.numericLimits (0 :: Double); f = N.numericLimits (0 :: Float)
           in N.machineEpsilon d == 2 ** (-52)
                && N.machineEpsilon f == 2 ** (-23)
                && N.minimumSubnormal d == encodeFloat 1 (-1074)
                && N.minimumNormal f == encodeFloat 1 (-126)
                && N.maximumFinite d == castWord64ToDouble 0x7fefffffffffffff
                && N.integerLimits (0 :: Int8) == (-128, 127)
        )
    ,
        ( "IEEE classification and signed zero"
        , map N.classify ([0, -0, 1 / 0, -1 / 0, 0 / 0, encodeFloat 1 (-1074), 1] :: [Double])
            == [ N.PositiveZero
               , N.NegativeZero
               , N.PositiveInfinity
               , N.NegativeInfinity
               , N.NotANumber
               , N.Subnormal
               , N.Normal
               ]
        )
    ,
        ( "nextafter exact binary64 bit neighbours"
        , all
            adjacent
            [ 1
            , 0x0010000000000000
            , 0x3ff0000000000000
            , 0x3fefffffffffffff
            , 0x7fefffffffffffff
            , 0x8000000000000001
            , 0xbff0000000000000
            , 0xffefffffffffffff
            ]
        )
    ,
        ( "nextafter zero/infinity/NaN endpoints"
        , isNegativeZero (N.nextAfter (0 :: Double) (-0))
            && N.nextAfter (0 :: Double) 1 == encodeFloat 1 (-1074)
            && N.nextAfter (1 / 0 :: Double) 0 == N.maximumFinite (N.numericLimits (0 :: Double))
            && isNaN (N.nextAfter (0 / 0 :: Double) 1)
        )
    ,
        ( "Float nextafter boundaries"
        , N.nextAfter (1 :: Float) 0 == 1 - 2 ** (-24)
            && N.nextAfter (1 :: Float) 2 == 1 + 2 ** (-23)
            && N.nextAfter (encodeFloat 1 (-149) :: Float) 0 == 0
        )
    ,
        ( "frexp/ldexp round trips"
        , all
            (\x -> let (m, e) = N.frexp x in N.ldexp m e == x && (x == 0 || abs m >= 0.5 && abs m < 1))
            ([0, -0, 1, -12.5, 1e300, encodeFloat 1 (-1074)] :: [Double])
        )
    ,
        ( "ULP comparison"
        , N.ulpDistance 1 (N.nextAfter 1 2) == Right 1
            && N.withinULPs 0 0 (-0)
            && not (N.withinULPs 100 (0 / 0) 1)
            && left (N.ulpDistance (0 / 0) 1)
        )
    ,
        ( "safe and saturating casts"
        , (N.safeIntegralCast (128 :: Integer) :: Either MathError Int8)
            == Left (DomainError "integral cast out of range")
            && (N.saturatingCast (300 :: Integer) :: Word8) == 255
            && (N.realToIntegral N.NearestEven (2.5 :: Double) :: Either MathError Int8) == Right 2
            && (N.realToIntegral N.TowardNegative (-2.1 :: Double) :: Either MathError Int8) == Right (-3)
            && (N.narrowFloat (0.5 :: Double) :: Either MathError Float) == Right 0.5
            && left (N.narrowFloat (0.1 :: Double) :: Either MathError Float)
        )
    ,
        ( "binary16 exhaustive finite/infinite storage roundtrip"
        , all halfRoundtrip ([0 .. 65535] :: [Word16])
        )
    ,
        ( "bfloat16 exhaustive finite/infinite storage roundtrip"
        , all bfloatRoundtrip ([0 .. 65535] :: [Word16])
        )
    , ("binary16 exhaustive adjacent midpoint ties", all halfMidpoint ([0 .. 0x7bfe] :: [Word16]))
    , ("bfloat16 exhaustive adjacent midpoint ties", all bfloatMidpoint ([0 .. 0x7f7e] :: [Word16]))
    ,
        ( "binary16 ties-even and directed rounding"
        , N.float16Bits (N.roundedValue (N.float16 N.NearestEven (1 + 2 ** (-11)))) == 0x3c00
            && N.float16Bits (N.roundedValue (N.float16 N.TowardPositive (1 + 2 ** (-12)))) == 0x3c01
            && N.float16Bits (N.roundedValue (N.float16 N.TowardNegative (-1 - 2 ** (-12)))) == 0xbc01
        )
    ,
        ( "binary16 exception flags and extremes"
        , let overflow = N.float16 N.NearestEven 65520
              under = N.float16 N.NearestEven (2 ** (-25))
              zero = N.float16 N.NearestEven (-0)
           in N.NumericOverflow `elem` N.numericalExceptions overflow
                && N.float16Bits (N.roundedValue overflow) == 0x7c00
                && N.NumericUnderflow `elem` N.numericalExceptions under
                && N.float16Bits (N.roundedValue zero) == 0x8000
                && isNaN (N.fromFloat16 (N.roundedValue (N.float16 N.NearestEven (0 / 0))))
        )
    ,
        ( "binary16 saturation rounding"
        , N.float16Bits (N.roundedValue (N.float16 N.TowardZero (1e300))) == 0x7bff
            && N.float16Bits (N.roundedValue (N.float16 N.TowardPositive (-1e300))) == 0xfbff
        )
    ,
        ( "arbitrary precision exceeds Double resolution"
        , must $ do
            N.Rounded a _ <- N.bigFloat 200 N.NearestEven (1 + 1 % 2 ^ (120 :: Int))
            N.Rounded b _ <- N.bigFloat 200 N.NearestEven 1
            c <- N.bigSubtract a b
            Right (N.bigRational c == 1 % 2 ^ (120 :: Int) && N.bigToDouble a == 1)
        )
    ,
        ( "BigFloat explicit rounding and precision promotion"
        , must $ do
            N.Rounded a flags <- N.bigFloat 3 N.TowardPositive (17 / 16)
            N.Rounded b _ <- N.bigFloat 100 N.NearestEven (1 / 2)
            c <- N.bigAdd a b
            d <- N.mixedMultiply a 2
            Right
                ( N.bigRational a == 5 / 4
                    && N.Inexact `elem` flags
                    && N.bigPrecision c == 100
                    && N.bigPrecision d == 53
                    && N.bigRational d == 5 / 2
                )
        )
    ,
        ( "BigFloat sqrt/exp/log 150-bit independent identities"
        , must $ do
            N.Rounded two _ <- N.bigFloat 150 N.NearestEven 2
            root <- N.bigSqrt two
            square <- N.bigMultiply root root
            logTwo <- N.bigLog two
            back <- N.bigExp logTwo
            N.Rounded one _ <- N.bigFloat 150 N.NearestEven 1
            exponential <- N.bigExp one
            Right
                ( abs (N.bigRational square - 2) < 1 % 2 ^ (140 :: Int)
                    && abs (N.bigRational back - 2) < 1 % 2 ^ (140 :: Int)
                    && abs
                        (N.bigRational exponential - 271828182845904523536028747135266249775724709369995 % 10 ^ (50 :: Int))
                        < 1 % 2 ^ (140 :: Int)
                )
        )
    ,
        ( "BigFloat domains"
        , left (N.bigFloat 1 N.NearestEven 1)
            && must
                ( do
                    N.Rounded a _ <- N.bigFloat 64 N.NearestEven (-1); Right (left (N.bigSqrt a) && left (N.bigLog a))
                )
        )
    ,
        ( "fixed/decimal exact tenths and rounding"
        , must $ do
            N.Rounded a _ <- N.decimal 2 N.NearestEven (1 / 10)
            N.Rounded b _ <- N.decimal 2 N.NearestEven (2 / 10)
            N.Rounded c _ <- N.decimalAdd a b
            N.Rounded f flags <- N.fixed 2 N.NearestEven (1 / 3)
            N.Rounded g _ <- N.fixed 4 N.NearestEven 2
            N.Rounded h _ <- N.fixedMultiply N.NearestEven f g
            Right
                ( N.decimalRational c == 3 / 10
                    && N.fixedRational f == 33 / 100
                    && N.Inexact `elem` flags
                    && N.fixedRational h == 66 / 100
                    && N.fixedScale h == 4
                )
        )
    ,
        ( "outward interval arithmetic"
        , must $ do
            a <- N.interval 0.1 0.2
            b <- N.interval 0.3 0.4
            s <- N.intervalAdd a b
            p <- N.intervalMultiply a b
            q <- N.intervalDivide a b
            z <- N.interval (-1) 1
            let (sl, sh) = N.intervalBounds s; (pl, ph) = N.intervalBounds p; (ql, qh) = N.intervalBounds q
            Right
                ( toRational sl <= toRational (0.1 :: Double) + toRational (0.3 :: Double)
                    && toRational sh >= toRational (0.2 :: Double) + toRational (0.4 :: Double)
                    && toRational pl <= toRational (0.1 :: Double) * toRational (0.3 :: Double)
                    && toRational ph >= toRational (0.2 :: Double) * toRational (0.4 :: Double)
                    && toRational ql <= toRational (0.1 :: Double) / toRational (0.4 :: Double)
                    && toRational qh >= toRational (0.2 :: Double) / toRational (0.3 :: Double)
                    && left (N.intervalDivide a z)
                )
        )
    ,
        ( "dual arithmetic and automatic derivatives"
        , near (N.derivative (\x -> sin x * exp x) 0.7) (exp 0.7 * (sin 0.7 + cos 0.7))
            && near (N.derivative (\x -> x * x * x + 3 * x) 2) 15
            && near (N.derivative (\x -> log x + sqrt x) 4) 0.5
            && near (N.derivative (\x -> atan x + asinh x) 0) 2
        )
    ,
        ( "Hamilton quaternion noncommutativity and inverse"
        , let i = N.Quaternion 0 1 0 0 :: N.Quaternion Double; j = N.Quaternion 0 0 1 0; k = N.Quaternion 0 0 0 1
           in i * j == k
                && j * i == negate k
                && i * i == -1
                && must (do qi <- N.quaternionInverse i; Right (i * qi == 1))
        )
    ,
        ( "dual quaternion rigid transformation"
        , must $ do
            let q = N.Quaternion (sqrt 0.5) 0 0 (sqrt 0.5)
            t <- N.rigidTransform q (1, 2, 3)
            (x, y, z) <- N.transformPoint t (1, 0, 0)
            ti <- N.dualQuaternionInverse t
            (a, b, c) <- N.transformPoint ti (x, y, z)
            Right (near x 1 && near y 3 && near z 3 && near a 1 && near b 0 && near c 0)
        )
    ,
        ( "quaternion normalization across dynamic range"
        , must $ do
            t <- N.rigidTransform (N.Quaternion 1e-300 0 0 1e-300) (0, 0, 0)
            (x, y, z) <- N.transformPoint t (1, 0, 0)
            Right (near x 0 && near y 1 && near z 0)
        )
    ,
        ( "stable reciprocal hyperbolic near zero"
        , rightNear (T.csch 1e-20) 1e20
            && rightNear (T.acsch 1e-300) (log 2 - log 1e-300)
            && rightNear (T.asech 1e-300) (log 2 - log 1e-300)
        )
    ,
        ( "stable summation cancellation"
        , N.neumaierSum ([1e16, 1, -1e16] :: [Double]) == 1
            && N.kahanSum (1 : replicate 10000 (1e-16 :: Double)) == 1.000000000001
            && N.pairwiseSum ([1 .. 10000] :: [Double]) == 50005000
        )
    ,
        ( "summation bound contains exact error"
        , let xs = [1e16, 1, 2, -1e16, 1e-100] :: [Double]
           in must
                ( do
                    bound <- N.sumErrorBound xs
                    Right (abs (toRational (sum xs) - sum (map toRational xs)) <= toRational bound)
                )
        )
    ,
        ( "logsumexp dynamic range and infinities"
        , rightNear (N.logsumexp [1000, 1000]) (1000 + log 2)
            && N.logsumexp ([] :: [Double]) == Right (-1 / 0)
            && N.logsumexp ([-1 / 0, -1 / 0] :: [Double]) == Right (-1 / 0)
            && N.logsumexp ([1 / 0, 1] :: [Double]) == Right (1 / 0)
            && left (N.logsumexp ([0 / 0, 1] :: [Double]))
        )
    ,
        ( "mathematical constants and precision metadata"
        , near (C.tau :: Double) (2 * pi)
            && near (C.goldenRatio :: Double) ((1 + sqrt 5) / 2)
            && near (C.eulerMascheroni :: Double) 0.5772156649015329
            && near (C.catalanConstant :: Double) 0.915965594177219
            && near (C.aperyConstant :: Double) 1.202056903159594
            && all
                (\c -> C.approximationBound c == 1 % 10 ^ (50 :: Int) && not (null (C.constantSource c)))
                C.mathematicalConstants
        )
    ,
        ( "physical constants uncertainty and exact definitions"
        , C.constantValue C.speedOfLight == 299792458
            && C.constantValue C.planckConstant == 662607015 % 10 ^ (42 :: Int)
            && C.standardUncertainty C.gravitationalConstant == 15 % 10 ^ (16 :: Int)
            && C.standardUncertainty C.electronMass == 28 % 10 ^ (41 :: Int)
            && C.constantValue C.astronomicalUnit == 149597870700
        )
    ,
        ( "angle and unit conversion exact roundtrips"
        , all
            unitRoundtrip
            [ U.metre
            , U.inch
            , U.mile
            , U.litre
            , U.pound
            , U.hour
            , U.kilometresPerHour
            , U.bar
            , U.celsius
            , U.fahrenheit
            , U.kibibyte
            ]
            && near (U.radiansToDegrees pi) 180
            && near (U.gradiansToRadians 200) pi
        )
    ,
        ( "affine temperatures and differences"
        , U.convert U.celsius U.fahrenheit 0 == Right 32
            && U.convert U.fahrenheit U.kelvin (-459.67) == Right 0
            && must
                ( do
                    diff <- U.subtractQuantity (U.quantity U.celsius 100) (U.quantity U.celsius 0)
                    val <- U.inUnit U.fahrenheit diff
                    Right (val == 180 && left (U.addQuantity (U.quantity U.kelvin 10) (U.quantity U.kelvin 20)))
                )
        )
    ,
        ( "dimensional rejection and algebra"
        , left (U.addQuantity (U.quantity U.metre 1) (U.quantity U.second 1))
            && left (U.convert U.metre U.kilogram 1)
            && must
                ( do
                    force <- U.multiplyQuantity (U.quantity U.kilogram 2) (U.quantity U.metresPerSecondSquared 3)
                    v <- U.inUnit U.newton force
                    Right (v == 6)
                )
            && left (U.unitProduct U.celsius U.metre)
            && left (U.dimension [1, 2])
        )
    ,
        ( "SI prefixes include 2022 extreme additions"
        , length U.siPrefixes == 24
            && must
                ( do
                    q <- U.prefixed (U.SIPrefix "quetta" "Q" 30) U.metre
                    r <- U.prefixed (U.SIPrefix "quecto" "q" (-30)) U.metre
                    a <- U.convert q U.metre 1
                    b <- U.convert r U.metre 1
                    Right (a == 10 ^ (30 :: Int) && b == 1 % 10 ^ (30 :: Int))
                )
        )
    ,
        ( "trig inverse identities and combined results"
        , all trigIdentities [-0.9, -0.3, 0, 0.4, 0.9]
            && T.sincos (0 :: Double) == Right (0, 1)
            && left (T.asinChecked (1.01 :: Double))
            && T.atan2Checked (1 :: Double) 0 == Right (pi / 2)
            && left (T.atan2Checked (0 :: Double) 0)
        )
    ,
        ( "reciprocal trig branches and poles"
        , rightNear (T.asec 2) (pi / 3)
            && rightNear (T.acsc 2) (pi / 6)
            && rightNear (T.acot (-1)) (3 * pi / 4)
            && left (T.sec (pi / 2 :: Double))
            && left (T.csc (pi :: Double))
            && left (T.cot (0 :: Double))
            && left (T.tanChecked (pi / 2 :: Double))
        )
    ,
        ( "hyperbolic identities and stable large reciprocal"
        , all
            (\x -> rightNear (T.sinhChecked (asinh x)) x && rightNear (T.tanhChecked (atanh x)) x)
            [-0.9, -0.2, 0, 0.7]
            && rightNear (T.sech 1000) 0
            && rightNear (T.coth (-1000)) (-1)
            && left (T.acoshChecked (0.5 :: Double))
            && left (T.atanhChecked (1 :: Double))
        )
    ,
        ( "wrapping endpoints/large values"
        , T.normalizeSignedAngle (pi :: Double) == Right (-pi)
            && T.normalizeAngle (-2 * pi :: Double) == Right 0
            && T.wrap (-1e308 :: Double) 1e308 1e308 == Right (-1e308)
            && rightNear (T.angleDifference (-pi + 0.1) (pi - 0.1)) 0.2
            && left (T.normalizeAngle (1 / 0 :: Double))
        )
    ,
        ( "stable trig identities near zero"
        , rightNear (T.versine 1e-10) 5e-21
            && rightNear (T.haversine 1e-10) 2.5e-21
            && T.sinc (0 :: Double) == Right 1
            && rightNear (T.cosc 1e-10) 5e-11
        )
    ,
        ( "spherical analytic triangles and geodesics"
        , rightNear (T.greatCircleAngle (0, 0) (0, pi / 2)) (pi / 2)
            && rightNear (T.greatCircleAngle (pi / 2, 0) (-pi / 2, 0)) pi
            && rightNear (T.sphericalSide (pi / 2) (pi / 2) (pi / 2)) (pi / 2)
            && rightNear (T.sphericalExcess (pi / 2) (pi / 2) (pi / 2)) (pi / 2)
            && left (T.sphericalAngles (0.1 :: Double) 0.1 1)
        )
    ,
        ( "complex analytic reference and principal branches"
        , complexNear (T.complexSin (0 :+ 1)) (0 :+ sinh 1)
            && complexNear (T.complexCos (0 :+ 1)) (cosh 1 :+ 0)
            && complexNear (T.complexAsin (0 :+ 1)) (0 :+ asinh 1)
            && complexNear (T.complexAcosh (2 :+ 0)) (acosh 2 :+ 0)
            && left (T.complexSin ((1 / 0) :+ 0 :: Complex Double))
        )
    ,
        ( "periodic waves endpoints"
        , T.periodicSawtooth (2 :: Double) 0 == Right (-1)
            && T.periodicTriangle (2 :: Double) 1 == Right 1
            && T.periodicSquare (2 :: Double) 1 == Right (-1)
            && T.periodicSquare (2 :: Double) (-2) == Right 1
            && left (T.periodicSquare (0 :: Double) 1)
        )
    ]
  where
    tinyAccurate x =
        let q = toRational x
            fact n = product [1 .. toInteger n]
            expRef = fromRational (sum [q ^ n / fromIntegral (fact n) | n <- [1 .. 24 :: Int]])
            logRef = fromRational (sum [(-1) ^ (n + 1) * q ^ n / fromIntegral n | n <- [1 .. 64 :: Int]])
         in either (const False) (N.withinULPs 8 expRef) (S.expm1 x)
                && either (const False) (N.withinULPs 8 logRef) (S.log1p x)
    adjacent bits =
        let x = castWord64ToDouble bits
            up = if x > 0 then bits + 1 else bits - 1
            down = if x > 0 then bits - 1 else bits + 1
         in castDoubleToWord64 (N.nextAfter x (1 / 0)) == up
                && castDoubleToWord64 (N.nextAfter x (-1 / 0)) == down
    halfRoundtrip w =
        w .&. 0x7c00 == 0x7c00 && w .&. 0x03ff /= 0
            || N.float16Bits (N.roundedValue (N.float16 N.NearestEven (N.fromFloat16 (N.float16FromBits w)))) == w
    bfloatRoundtrip w =
        w .&. 0x7f80 == 0x7f80 && w .&. 0x007f /= 0
            || N.bfloat16Bits (N.roundedValue (N.bfloat16 N.NearestEven (N.fromBFloat16 (N.bfloat16FromBits w))))
                == w
    halfMidpoint w =
        let a = N.fromFloat16 (N.float16FromBits w)
            b = N.fromFloat16 (N.float16FromBits (w + 1))
            m = (a + b) / 2
            expected = if even w then w else w + 1
         in N.float16Bits (N.roundedValue (N.float16 N.NearestEven m)) == expected
                && N.float16Bits (N.roundedValue (N.float16 N.TowardPositive m)) == w + 1
                && N.float16Bits (N.roundedValue (N.float16 N.TowardNegative m)) == w
    bfloatMidpoint w =
        let a = N.fromBFloat16 (N.bfloat16FromBits w)
            b = N.fromBFloat16 (N.bfloat16FromBits (w + 1))
            m = (a + b) / 2
            expected = if even w then w else w + 1
         in N.bfloat16Bits (N.roundedValue (N.bfloat16 N.NearestEven m)) == expected
                && N.bfloat16Bits (N.roundedValue (N.bfloat16 N.TowardPositive m)) == w + 1
                && N.bfloat16Bits (N.roundedValue (N.bfloat16 N.TowardNegative m)) == w
    unitRoundtrip u =
        all
            (\x -> must $ do y <- U.convert u u x; Right (x == y))
            [-10 ^ (100 :: Int), -1, 0, 1, 10 ^ (100 :: Int)]
    trigIdentities x =
        rightNear (T.sinChecked (asin x)) x
            && rightNear (T.cosChecked (acos x)) x
            && rightNear (T.tanChecked (atan x)) x
            && must (do (s, c) <- T.sincos x; Right (near (s * s + c * c) 1))
    complexNear :: Either MathError (Complex Double) -> Complex Double -> Bool
    complexNear result expected = either (const False) (\z -> magnitude (z - expected) < 1e-12) result
