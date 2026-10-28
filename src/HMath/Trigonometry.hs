-- SPDX-License-Identifier: MPL-2.0

{- | Radian-based checked trigonometry. Real inverse branches: asin [-pi/2,pi/2],
acos [0,pi], atan (-pi/2,pi/2), acot (0,pi). Nonfinite inputs and undefined
real domains return errors. Poles at represented multiples of pi and pi/2 are
rejected; near poles remain finite when representable. Complex functions use
the principal branches of Data.Complex (NIST DLMF sections 4.23 and 4.37).
-}
module HMath.Trigonometry (
    sinChecked,
    cosChecked,
    tanChecked,
    asinChecked,
    acosChecked,
    atanChecked,
    atan2Checked,
    sec,
    csc,
    cot,
    asec,
    acsc,
    acot,
    sinhChecked,
    coshChecked,
    tanhChecked,
    asinhChecked,
    acoshChecked,
    atanhChecked,
    sech,
    csch,
    coth,
    asech,
    acsch,
    acoth,
    sincos,
    wrap,
    normalizeAngle,
    normalizeSignedAngle,
    angleDifference,
    versine,
    haversine,
    sinc,
    cosc,
    greatCircleAngle,
    greatCircleDistance,
    sphericalSide,
    sphericalAngles,
    sphericalExcess,
    ComplexFunction (..),
    complexFunction,
    complexSin,
    complexCos,
    complexTan,
    complexAsin,
    complexAcos,
    complexAtan,
    complexSinh,
    complexCosh,
    complexTanh,
    complexAsinh,
    complexAcosh,
    complexAtanh,
    periodicSawtooth,
    periodicTriangle,
    periodicSquare,
) where

import Data.Complex (Complex (..), imagPart, realPart)
import HMath.Error (MathError (..))

finite :: (RealFloat a) => a -> Bool
finite x = not (isNaN x || isInfinite x)
checked :: (RealFloat a) => (a -> a) -> a -> Either MathError a
checked f x
    | not (finite x) = Left (DomainError "non-finite angular input")
    | not (finite y) = Left NonFiniteResult
    | otherwise = Right y
  where
    y = f x
restricted :: (RealFloat a) => (a -> Bool) -> String -> (a -> a) -> a -> Either MathError a
restricted domain message f x
    | not (finite x) || not (domain x) = Left (DomainError message)
    | otherwise = checked f x
sinChecked
    , cosChecked
    , tanChecked
    , asinChecked
    , acosChecked
    , atanChecked ::
        (RealFloat a) => a -> Either MathError a
sinChecked = checked sin
cosChecked = checked cos
tanChecked x = do
    a <- normalizeSignedAngle x
    if abs a == pi / 2 then Left (DomainError "tangent pole") else checked tan x
asinChecked = restricted (\x -> abs x <= 1) "asin needs abs x <= 1" asin
acosChecked = restricted (\x -> abs x <= 1) "acos needs abs x <= 1" acos
atanChecked = checked atan

-- | Conventional atan2(y,x), range [-pi,pi]. Rejects the undefined origin.
atan2Checked :: (RealFloat a) => a -> a -> Either MathError a
atan2Checked y x
    | not (all finite [x, y]) || (x == 0 && y == 0) = Left (DomainError "invalid atan2 point")
    | otherwise = Right (atan2 y x)

sec, csc, cot, asec, acsc, acot :: (RealFloat a) => a -> Either MathError a
sec x = do
    a <- normalizeSignedAngle x
    if abs a == pi / 2 then Left (DomainError "secant pole") else checked (\v -> 1 / cos v) x
csc x = do
    a <- wrap 0 pi x
    if a == 0 then Left (DomainError "cosecant pole") else checked (\v -> 1 / sin v) x
cot x = do
    a <- wrap 0 pi x
    if a == 0 then Left (DomainError "cotangent pole") else checked (\v -> cos v / sin v) x
asec = restricted (\x -> abs x >= 1) "asec needs abs x >= 1" (acos . recip)
acsc = restricted (\x -> abs x >= 1) "acsc needs abs x >= 1" (asin . recip)
acot = checked (atan2 1)
sinhChecked
    , coshChecked
    , tanhChecked
    , asinhChecked
    , acoshChecked
    , atanhChecked ::
        (RealFloat a) => a -> Either MathError a
sinhChecked = checked sinh
coshChecked = checked cosh
tanhChecked = checked tanh
asinhChecked = checked asinh
acoshChecked = restricted (>= 1) "acosh needs x >= 1" acosh
atanhChecked = restricted (\x -> abs x < 1) "atanh needs abs x < 1" atanh
sech, csch, coth, asech, acsch, acoth :: (RealFloat a) => a -> Either MathError a
-- exponential formulas avoid overflowing cosh/sinh for large finite arguments.
sech = checked (\x -> let e = exp (-abs x) in 2 * e / (1 + e * e))
csch =
    restricted
        (/= 0)
        "csch pole"
        (\x -> if abs x < 1 then 1 / sinh x else let e = exp (-abs x) in signum x * 2 * e / (1 - e * e))
coth = restricted (/= 0) "coth pole" (recip . tanh)
asech =
    restricted
        (\x -> x > 0 && x <= 1)
        "asech needs 0 < x <= 1"
        (\x -> log (1 + sqrt (1 - x * x)) - log x)
acsch =
    restricted
        (/= 0)
        "acsch needs x /= 0"
        (\x -> if abs x < 1e-15 then signum x * (log 2 - log (abs x)) else asinh (1 / x))
acoth = restricted (\x -> abs x > 1) "acoth needs abs x > 1" (atanh . recip)
sincos :: (RealFloat a) => a -> Either MathError (a, a)
sincos x = do s <- sinChecked x; c <- cosChecked x; Right (s, c)

{- | Wrap to [lo,hi). Exact rational reduction avoids overflowing x-lo and
preserves the interval contract even for huge finite values. The period is
the represented endpoints' difference; no accuracy claim is made for reducing
enormous angles modulo the mathematical irrational 2*pi.
-}
wrap :: (RealFloat a) => a -> a -> a -> Either MathError a
wrap lo hi x
    | not (all finite [lo, hi, x]) || lo >= hi = Left (DomainError "invalid wrapping interval")
    | otherwise =
        let a = toRational lo
            b = toRational hi
            period = b - a
            v = toRational x - a
            r = fromRational (a + v - fromInteger (floor (v / period)) * period)
         in Right (if r >= hi then lo else max lo r)

normalizeAngle, normalizeSignedAngle :: (RealFloat a) => a -> Either MathError a
normalizeAngle = wrap 0 (2 * pi)
normalizeSignedAngle = wrap (-pi) pi
angleDifference :: (RealFloat a) => a -> a -> Either MathError a
angleDifference a b
    | not (all finite [a, b]) = Left (DomainError "non-finite angle")
    | otherwise = do x <- normalizeSignedAngle a; y <- normalizeSignedAngle b; normalizeSignedAngle (x - y)
versine, haversine, sinc, cosc :: (RealFloat a) => a -> Either MathError a
versine = checked (\x -> 2 * sin (x / 2) ^ (2 :: Int))
haversine = checked (\x -> sin (x / 2) ^ (2 :: Int))
sinc x
    | x == 0 = Right 1
    | otherwise = checked (\v -> sin v / v) x

-- | (1-cos x)/x with its continuous value 0 at x=0.
cosc x
    | x == 0 = Right x
    | otherwise = checked (\v -> (2 * sin (v / 2) / v) * sin (v / 2)) x

-- | Latitudes in [-pi/2,pi/2], longitudes any finite radians. Central angle [0,pi].
greatCircleAngle :: (RealFloat a) => (a, a) -> (a, a) -> Either MathError a
greatCircleAngle (lat1, lon1) (lat2, lon2)
    | not (all finite [lat1, lon1, lat2, lon2]) || abs lat1 > pi / 2 || abs lat2 > pi / 2 =
        Left (DomainError "invalid spherical coordinates")
    | otherwise = do
        dl <- angleDifference lon2 lon1
        let a = sin ((lat2 - lat1) / 2) ^ (2 :: Int) + cos lat1 * cos lat2 * sin (dl / 2) ^ (2 :: Int)
            h = max 0 (min 1 a)
        Right (2 * atan2 (sqrt h) (sqrt (1 - h)))

greatCircleDistance :: (RealFloat a) => a -> (a, a) -> (a, a) -> Either MathError a
greatCircleDistance radius a b
    | not (finite radius) || radius < 0 = Left (DomainError "invalid sphere radius")
    | otherwise =
        greatCircleAngle a b >>= \v -> if finite (radius * v) then Right (radius * v) else Left NonFiniteResult

-- | Two spherical sides and their included angle, all in [0,pi].
sphericalSide :: (RealFloat a) => a -> a -> a -> Either MathError a
sphericalSide a b included
    | not (all finite [a, b, included]) || any (\x -> x < 0 || x > pi) [a, b, included] =
        Left (DomainError "invalid spherical sides/angle")
    | otherwise = Right (acos (max (-1) (min 1 (cos a * cos b + sin a * sin b * cos included))))

-- | Interior angles for a nondegenerate minor spherical triangle, sides (0,pi).
sphericalAngles :: (RealFloat a) => a -> a -> a -> Either MathError (a, a, a)
sphericalAngles a b c
    | not (all finite [a, b, c])
        || any (\x -> x <= 0 || x >= pi) [a, b, c]
        || a + b <= c
        || a + c <= b
        || b + c <= a
        || a + b + c >= 2 * pi =
        Left (DomainError "degenerate spherical triangle")
    | otherwise = Right (angle a b c, angle b a c, angle c a b)
  where
    angle x y z = acos (max (-1) (min 1 ((cos x - cos y * cos z) / (sin y * sin z))))

sphericalExcess :: (RealFloat a) => a -> a -> a -> Either MathError a
sphericalExcess a b c = do (x, y, z) <- sphericalAngles a b c; Right (x + y + z - pi)

data ComplexFunction
    = CSin
    | CCos
    | CTan
    | CAsin
    | CAcos
    | CAtan
    | CSinh
    | CCosh
    | CTanh
    | CAsinh
    | CAcosh
    | CAtanh
    | CSec
    | CCsc
    | CCot
    | CSech
    | CCsch
    | CCoth
    deriving (Eq, Show)
complexFunction :: (RealFloat a) => ComplexFunction -> Complex a -> Either MathError (Complex a)
complexFunction name z
    | not (finite (realPart z) && finite (imagPart z)) =
        Left (DomainError "non-finite complex argument")
    | not (finite (realPart value) && finite (imagPart value)) =
        Left (DomainError "complex pole or overflow")
    | otherwise = Right value
  where
    value = case name of
        CSin -> sin z
        CCos -> cos z
        CTan -> tan z
        CAsin -> asin z
        CAcos -> acos z
        CAtan -> atan z
        CSinh -> sinh z
        CCosh -> cosh z
        CTanh -> tanh z
        CAsinh -> asinh z
        CAcosh -> acosh z
        CAtanh -> atanh z
        CSec -> 1 / cos z
        CCsc -> 1 / sin z
        CCot -> cos z / sin z
        CSech -> 1 / cosh z
        CCsch -> 1 / sinh z
        CCoth -> cosh z / sinh z
complexSin
    , complexCos
    , complexTan
    , complexAsin
    , complexAcos
    , complexAtan
    , complexSinh
    , complexCosh
    , complexTanh
    , complexAsinh
    , complexAcosh
    , complexAtanh ::
        (RealFloat a) => Complex a -> Either MathError (Complex a)
complexSin = complexFunction CSin
complexCos = complexFunction CCos
complexTan = complexFunction CTan
complexAsin = complexFunction CAsin
complexAcos = complexFunction CAcos
complexAtan = complexFunction CAtan
complexSinh = complexFunction CSinh
complexCosh = complexFunction CCosh
complexTanh = complexFunction CTanh
complexAsinh = complexFunction CAsinh
complexAcosh = complexFunction CAcosh
complexAtanh = complexFunction CAtanh

{- | Unit-amplitude periodic waves. Period must be positive and finite. Square
wave is +1 on the first half-cycle, -1 on the second, including midpoint.
-}
periodicSawtooth, periodicTriangle, periodicSquare :: (RealFloat a) => a -> a -> Either MathError a
periodicSawtooth period x = do t <- wrap 0 period x; Right (2 * (t / period) - 1)
periodicTriangle period x = do t <- wrap 0 period x; Right (1 - 4 * abs (t / period - 0.5))
periodicSquare period x = do t <- wrap 0 period x; Right (if t / period < 0.5 then 1 else -1)
