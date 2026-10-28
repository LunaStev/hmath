-- SPDX-License-Identifier: MPL-2.0

{- | Exact rational unit conversion and API-level dimensional safety. Opaque
quantities store SI values; addition/conversion reject incompatible dimensions.
Seven SI base exponents are augmented by data and plane-angle tags, so bytes
cannot be added to lengths and angles cannot be added to plain scalars.
Absolute temperatures and differences are distinct: absolute + absolute and
products of absolutes are rejected; subtracting absolutes produces a difference.
-}
module HMath.Units (
    Dimension,
    dimension,
    dimensionExponents,
    dimensionless,
    lengthDimension,
    massDimension,
    timeDimension,
    temperatureDimension,
    angleDimension,
    dataDimension,
    Unit,
    unit,
    unitName,
    unitDimension,
    unitScale,
    unitOffset,
    unitProduct,
    unitQuotient,
    unitPower,
    Quantity,
    quantity,
    temperatureDifference,
    quantityDimension,
    siValue,
    inUnit,
    convert,
    addQuantity,
    subtractQuantity,
    multiplyQuantity,
    divideQuantity,
    SIPrefix (..),
    siPrefixes,
    prefixed,
    metre,
    kilometre,
    centimetre,
    millimetre,
    inch,
    foot,
    yard,
    mile,
    nauticalMile,
    squareMetre,
    hectare,
    cubicMetre,
    litre,
    millilitre,
    kilogram,
    gram,
    tonne,
    pound,
    second,
    minute,
    hour,
    day,
    metresPerSecond,
    kilometresPerHour,
    milesPerHour,
    metresPerSecondSquared,
    newton,
    joule,
    watt,
    pascal,
    bar,
    atmosphere,
    kelvin,
    celsius,
    fahrenheit,
    hertz,
    bit,
    byte,
    kibibyte,
    mebibyte,
    gigabyte,
    radian,
    degree,
    gradian,
    radiansToDegrees,
    degreesToRadians,
    radiansToGradians,
    gradiansToRadians,
) where

import HMath.Constants (constantName, constantValue, mathematicalConstants)
import HMath.Error (MathError (..))

{- | Opaque nine-exponent dimensional witness: seven SI bases plus data and plane-angle
tags. Construct with dimension.
-}
newtype Dimension = Dimension [Integer] deriving (Eq, Show)

{- | Exponents in order length, mass, time, current, temperature, amount,
luminous intensity, data, plane angle. Require exactly nine exponents.
-}
dimension :: [Integer] -> Either MathError Dimension
dimension xs
    | length xs /= 9 = Left (InvalidArgument "dimension requires nine exponents")
    | otherwise = Right (Dimension xs)

{- | Return nine exact integer exponents ordered as length, mass, time, current,
temperature, amount, luminous intensity, data, plane angle.
-}
dimensionExponents :: Dimension -> [Integer]
dimensionExponents (Dimension xs) = xs

dimensionless
    , lengthDimension
    , massDimension
    , timeDimension
    , temperatureDimension
    , angleDimension
    , dataDimension ::
        Dimension

{- | Dimension witness with all nine exponents zero; all unspecified exponents are zero. Use
to construct or compare dimension-safe units/quantities.
-}
dimensionless = Dimension (replicate 9 0)

{- | Dimension witness with length exponent one; all unspecified exponents are zero. Use to
construct or compare dimension-safe units/quantities.
-}
lengthDimension = base 0

{- | Dimension witness with mass exponent one; all unspecified exponents are zero. Use to
construct or compare dimension-safe units/quantities.
-}
massDimension = base 1

{- | Dimension witness with time exponent one; all unspecified exponents are zero. Use to
construct or compare dimension-safe units/quantities.
-}
timeDimension = base 2

{- | Dimension witness with temperature exponent one; all unspecified exponents are zero.
Use to construct or compare dimension-safe units/quantities.
-}
temperatureDimension = base 4

{- | Dimension witness with data tag exponent one; all unspecified exponents are zero. Use
to construct or compare dimension-safe units/quantities.
-}
dataDimension = base 7

{- | Dimension witness with plane-angle tag exponent one; all unspecified exponents are
zero. Use to construct or compare dimension-safe units/quantities.
-}
angleDimension = base 8

base :: Int -> Dimension
base i = Dimension [if i == j then 1 else 0 | j <- [0 .. 8]]
combine :: (Integer -> Integer -> Integer) -> Dimension -> Dimension -> Dimension
combine op (Dimension a) (Dimension b) = Dimension (zipWith op a b)
scaleDimension :: Integer -> Dimension -> Dimension
scaleDimension n (Dimension xs) = Dimension (map (n *) xs)

{- | Opaque exact affine unit definition SI=value*scale+offset. Nonzero offsets are
restricted to absolute-temperature units.
-}
data Unit = Unit String Dimension Rational Rational deriving (Eq, Show)

-- | Return the display name/symbol of a Unit, for example "m". No conversion is performed.
unitName :: Unit -> String
unitName (Unit name _ _ _) = name

{- | Return the dimensional-exponent witness of a Unit. Compatible conversions require equal
dimensions.
-}
unitDimension :: Unit -> Dimension
unitDimension (Unit _ dim _ _) = dim

{- | Return exact Rational scale in the conversion SI = value*scale + offset. All public
Unit constructors require a positive scale.
-}
unitScale :: Unit -> Rational
unitScale (Unit _ _ scale _) = scale

{- | Return exact Rational affine offset in SI = value*scale + offset. Only temperature
units may have a nonzero offset.
-}
unitOffset :: Unit -> Rational
unitOffset (Unit _ _ _ offset) = offset

-- | SI = value * scale + offset. Only temperature units may have an offset.
unit :: String -> Dimension -> Rational -> Rational -> Either MathError Unit
unit name dim scale offset
    | scale <= 0 = Left (InvalidArgument "unit scale must be positive")
    | offset /= 0 && dim /= temperatureDimension =
        Left (DomainError "affine offset requires temperature dimension")
    | otherwise = Right (Unit name dim scale offset)

unitProduct, unitQuotient :: Unit -> Unit -> Either MathError Unit

{- | Multiply two zero-offset units: add dimension exponents and multiply Rational scales.
Any affine offset returns Left DomainError. This constructs a Unit, not a Quantity.
-}
unitProduct a b
    | unitOffset a /= 0 || unitOffset b /= 0 = Left (DomainError "cannot multiply affine units")
    | otherwise =
        Right
            ( Unit
                (unitName a ++ " " ++ unitName b)
                (combine (+) (unitDimension a) (unitDimension b))
                (unitScale a * unitScale b)
                0
            )

{- | Divide two zero-offset units: subtract dimension exponents and divide their positive
scales. Affine units fail with DomainError.
-}
unitQuotient a b
    | unitOffset a /= 0 || unitOffset b /= 0 = Left (DomainError "cannot divide affine units")
    | otherwise =
        Right
            ( Unit
                (unitName a ++ "/" ++ unitName b)
                (combine (-) (unitDimension a) (unitDimension b))
                (unitScale a / unitScale b)
                0
            )

{- | Given zero-offset Unit then Integer exponent, multiply its exponents and raise its
positive scale to that power. Negative powers are valid; affine units fail.
-}
unitPower :: Unit -> Integer -> Either MathError Unit
unitPower a n
    | unitOffset a /= 0 = Left (DomainError "cannot exponentiate affine units")
    | otherwise =
        Right (Unit (unitName a ++ "^" ++ show n) (scaleDimension n (unitDimension a)) (unitScale a ^^ n) 0)

{- | Opaque exact SI-valued dimensional quantity,tagging absolute temperatures separately
from differences. Construct with quantity or temperatureDifference.
-}
data Quantity = Quantity Dimension Rational Bool deriving (Eq, Show)

{- | Given Unit then Rational value, construct an exact SI-valued Quantity using its scale
and offset. A temperature unit constructs an absolute temperature; use
temperatureDifference for differences.
-}
quantity :: Unit -> Rational -> Quantity
quantity u x =
    Quantity
        (unitDimension u)
        (x * unitScale u + unitOffset u)
        (unitDimension u == temperatureDimension)

{- | Given temperature Unit then Rational difference, multiply by its scale while ignoring
its affine offset. A non-temperature unit returns Left DomainError. The result is not
an absolute temperature.
-}
temperatureDifference :: Unit -> Rational -> Either MathError Quantity
temperatureDifference u x
    | unitDimension u /= temperatureDimension =
        Left (DomainError "temperature difference requires temperature unit")
    | otherwise = Right (Quantity temperatureDimension (x * unitScale u) False)

{- | Return a Quantity's dimensional-exponent witness, without changing its SI value or
absolute-temperature tag.
-}
quantityDimension :: Quantity -> Dimension
quantityDimension (Quantity d _ _) = d

{- | Return exact Rational SI value of a Quantity. For absolute temperature this is an
absolute kelvin value; preserve quantityDimension when interpreting the number.
-}
siValue :: Quantity -> Rational
siValue (Quantity _ x _) = x

{- | Given destination Unit then Quantity, convert its SI value to that unit. Reject
incompatible dimensions. Apply affine offsets only for absolute temperatures, not
differences.
-}
inUnit :: Unit -> Quantity -> Either MathError Rational
inUnit u (Quantity d x absoluteTemp)
    | unitDimension u /= d = Left (DomainError "incompatible dimensions")
    | otherwise = Right ((x - (if absoluteTemp then unitOffset u else 0)) / unitScale u)

{- | Given source Unit, destination Unit, then Rational value, convert exactly through SI.
Incompatible dimensions fail. Example: convert kilometre metre 2 == Right 2000.
-}
convert :: Unit -> Unit -> Rational -> Either MathError Rational
convert a b x = inUnit b (quantity a x)

addQuantity
    , subtractQuantity
    , multiplyQuantity
    , divideQuantity ::
        Quantity -> Quantity -> Either MathError Quantity

{- | Add equal-dimension quantities. Two absolute temperatures cannot be added; absolute
plus difference produces an absolute temperature. Incompatible dimensions return Left
DomainError.
-}
addQuantity (Quantity d a absA) (Quantity e b absB)
    | d /= e = Left (DomainError "incompatible dimensions")
    | absA && absB = Left (DomainError "cannot add absolute temperatures")
    | otherwise = Right (Quantity d (a + b) (absA || absB))

{- | Subtract equal-dimension quantities. Absolute minus absolute produces a difference;
difference minus absolute is invalid. Incompatible dimensions return Left DomainError.
-}
subtractQuantity (Quantity d a absA) (Quantity e b absB)
    | d /= e = Left (DomainError "incompatible dimensions")
    | not absA && absB = Left (DomainError "cannot subtract absolute temperature from difference")
    | otherwise = Right (Quantity d (a - b) (absA && not absB))

{- | Multiply SI values and add dimension exponents. Any absolute-temperature operand fails
with DomainError; temperature differences can participate in products.
-}
multiplyQuantity (Quantity d a absA) (Quantity e b absB)
    | absA || absB = Left (DomainError "cannot multiply absolute temperatures")
    | otherwise = Right (Quantity (combine (+) d e) (a * b) False)

{- | Divide SI values and subtract dimension exponents. Reject a zero divisor or
absolute-temperature operands. Result preserves exact Rational arithmetic.
-}
divideQuantity (Quantity d a absA) (Quantity e b absB)
    | absA || absB = Left (DomainError "cannot divide absolute temperatures")
    | b == 0 = Left (DomainError "quantity division by zero")
    | otherwise = Right (Quantity (combine (-) d e) (a / b) False)

-- | SI prefix name,symbol,and power-of-ten exponent. prefixed rejects affine units.
data SIPrefix = SIPrefix
    { prefixName :: String
    -- ^ SI prefix name, such as kilo.
    , prefixSymbol :: String
    -- ^ SI prefix symbol, such as k; micro uses ASCII u in this catalog.
    , prefixExponent :: Int
    -- ^ Integer power of ten multiplying the base unit scale.
    }
    deriving (Eq, Show)

{- | BIPM prefixes through the 2022 quetta/ronna and ronto/quecto additions.
Source: https://www.bipm.org/en/measurement-units/si-prefixes
-}
siPrefixes :: [SIPrefix]
siPrefixes =
    [ SIPrefix n s e
    | (n, s, e) <-
        [ ("quetta", "Q", 30)
        , ("ronna", "R", 27)
        , ("yotta", "Y", 24)
        , ("zetta", "Z", 21)
        , ("exa", "E", 18)
        , ("peta", "P", 15)
        , ("tera", "T", 12)
        , ("giga", "G", 9)
        , ("mega", "M", 6)
        , ("kilo", "k", 3)
        , ("hecto", "h", 2)
        , ("deca", "da", 1)
        , ("deci", "d", -1)
        , ("centi", "c", -2)
        , ("milli", "m", -3)
        , ("micro", "u", -6)
        , ("nano", "n", -9)
        , ("pico", "p", -12)
        , ("femto", "f", -15)
        , ("atto", "a", -18)
        , ("zepto", "z", -21)
        , ("yocto", "y", -24)
        , ("ronto", "r", -27)
        , ("quecto", "q", -30)
        ]
    ]

{- | Given SIPrefix then zero-offset Unit, multiply its scale by 10^prefixExponent and
prepend its symbol. Reject affine units or absolute exponent above 10000.
-}
prefixed :: SIPrefix -> Unit -> Either MathError Unit
prefixed p u
    | unitOffset u /= 0 = Left (DomainError "cannot prefix affine unit")
    | abs (toInteger (prefixExponent p)) > 10000 =
        Left (InvalidArgument "prefix exponent exceeds resource limit")
    | otherwise =
        let e = prefixExponent p; s = if e >= 0 then fromInteger (10 ^ e) else 1 / fromInteger (10 ^ negate e)
         in Right (Unit (prefixSymbol p ++ unitName u) (unitDimension u) (s * unitScale u) 0)

metre, kilometre, centimetre, millimetre, inch, foot, yard, mile, nauticalMile :: Unit

{- | The metre Unit: 1 metre. Non-temperature definitions use an exact Rational scale and
zero affine offset. Use quantity or convert to construct/convert values; temperature
differences use temperatureDifference.
-}
metre = Unit "m" lengthDimension 1 0

{- | The kilometre Unit: 1000 metres. Non-temperature definitions use an exact Rational
scale and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
kilometre = Unit "km" lengthDimension 1000 0

{- | The centimetre Unit: 0.01 metre. Non-temperature definitions use an exact Rational
scale and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
centimetre = Unit "cm" lengthDimension 0.01 0

{- | The millimetre Unit: 0.001 metre. Non-temperature definitions use an exact Rational
scale and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
millimetre = Unit "mm" lengthDimension 0.001 0

{- | The inch Unit: 0.0254 metre. Non-temperature definitions use an exact Rational scale
and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
inch = Unit "in" lengthDimension 0.0254 0

{- | The foot Unit: 0.3048 metre. Non-temperature definitions use an exact Rational scale
and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
foot = Unit "ft" lengthDimension 0.3048 0

{- | The yard Unit: 0.9144 metre. Non-temperature definitions use an exact Rational scale
and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
yard = Unit "yd" lengthDimension 0.9144 0

{- | The mile Unit: 1609.344 metres. Non-temperature definitions use an exact Rational scale
and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
mile = Unit "mi" lengthDimension 1609.344 0

{- | The nauticalMile Unit: 1852 metres. Non-temperature definitions use an exact Rational
scale and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
nauticalMile = Unit "nmi" lengthDimension 1852 0

squareMetre, hectare, cubicMetre, litre, millilitre :: Unit

{- | The squareMetre Unit: 1 square metre. Non-temperature definitions use an exact Rational
scale and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
squareMetre = Unit "m^2" (scaleDimension 2 lengthDimension) 1 0

{- | The hectare Unit: 10000 square metres. Non-temperature definitions use an exact
Rational scale and zero affine offset. Use quantity or convert to construct/convert
values; temperature differences use temperatureDifference.
-}
hectare = Unit "ha" (scaleDimension 2 lengthDimension) 10000 0

{- | The cubicMetre Unit: 1 cubic metre. Non-temperature definitions use an exact Rational
scale and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
cubicMetre = Unit "m^3" (scaleDimension 3 lengthDimension) 1 0

{- | The litre Unit: 0.001 cubic metre. Non-temperature definitions use an exact Rational
scale and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
litre = Unit "L" (scaleDimension 3 lengthDimension) 0.001 0

{- | The millilitre Unit: 0.000001 cubic metre. Non-temperature definitions use an exact
Rational scale and zero affine offset. Use quantity or convert to construct/convert
values; temperature differences use temperatureDifference.
-}
millilitre = Unit "mL" (scaleDimension 3 lengthDimension) 0.000001 0

kilogram, gram, tonne, pound, second, minute, hour, day :: Unit

{- | The kilogram Unit: 1 kilogram. Non-temperature definitions use an exact Rational scale
and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
kilogram = Unit "kg" massDimension 1 0

{- | The gram Unit: 0.001 kilogram. Non-temperature definitions use an exact Rational scale
and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
gram = Unit "g" massDimension 0.001 0

{- | The tonne Unit: 1000 kilograms. Non-temperature definitions use an exact Rational scale
and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
tonne = Unit "t" massDimension 1000 0

{- | The pound Unit: 0.45359237 kilogram. Non-temperature definitions use an exact Rational
scale and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
pound = Unit "lb" massDimension 0.45359237 0

{- | The second Unit: 1 second. Non-temperature definitions use an exact Rational scale and
zero affine offset. Use quantity or convert to construct/convert values; temperature
differences use temperatureDifference.
-}
second = Unit "s" timeDimension 1 0

{- | The minute Unit: 60 seconds. Non-temperature definitions use an exact Rational scale
and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
minute = Unit "min" timeDimension 60 0

{- | The hour Unit: 3600 seconds. Non-temperature definitions use an exact Rational scale
and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
hour = Unit "h" timeDimension 3600 0

{- | The day Unit: 86400 seconds. Non-temperature definitions use an exact Rational scale
and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
day = Unit "d" timeDimension 86400 0

metresPerSecond, kilometresPerHour, milesPerHour, metresPerSecondSquared :: Unit

{- | The metresPerSecond Unit: 1 metre per second. Non-temperature definitions use an exact
Rational scale and zero affine offset. Use quantity or convert to construct/convert
values; temperature differences use temperatureDifference.
-}
metresPerSecond = Unit "m/s" (combine (-) lengthDimension timeDimension) 1 0

{- | The kilometresPerHour Unit: 1000/3600 metres per second. Non-temperature definitions
use an exact Rational scale and zero affine offset. Use quantity or convert to
construct/convert values; temperature differences use temperatureDifference.
-}
kilometresPerHour = Unit "km/h" (unitDimension metresPerSecond) (1000 / 3600) 0

{- | The milesPerHour Unit: 1609.344/3600 metres per second. Non-temperature definitions use
an exact Rational scale and zero affine offset. Use quantity or convert to
construct/convert values; temperature differences use temperatureDifference.
-}
milesPerHour = Unit "mi/h" (unitDimension metresPerSecond) (1609.344 / 3600) 0

{- | The metresPerSecondSquared Unit: 1 metre per second squared. Non-temperature
definitions use an exact Rational scale and zero affine offset. Use quantity or convert
to construct/convert values; temperature differences use temperatureDifference.
-}
metresPerSecondSquared = Unit "m/s^2" (combine (-) lengthDimension (scaleDimension 2 timeDimension)) 1 0

newton, joule, watt, pascal, bar, atmosphere :: Unit

{- | The newton Unit: 1 kg*m/s^2. Non-temperature definitions use an exact Rational scale
and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
newton = Unit "N" (combine (+) massDimension (unitDimension metresPerSecondSquared)) 1 0

{- | The joule Unit: 1 newton metre. Non-temperature definitions use an exact Rational scale
and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
joule = Unit "J" (combine (+) (unitDimension newton) lengthDimension) 1 0

{- | The watt Unit: 1 joule per second. Non-temperature definitions use an exact Rational
scale and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
watt = Unit "W" (combine (-) (unitDimension joule) timeDimension) 1 0

{- | The pascal Unit: 1 newton per square metre. Non-temperature definitions use an exact
Rational scale and zero affine offset. Use quantity or convert to construct/convert
values; temperature differences use temperatureDifference.
-}
pascal = Unit "Pa" (combine (-) (unitDimension newton) (unitDimension squareMetre)) 1 0

{- | The bar Unit: 100000 pascals. Non-temperature definitions use an exact Rational scale
and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
bar = Unit "bar" (unitDimension pascal) 100000 0

{- | The atmosphere Unit: 101325 pascals. Non-temperature definitions use an exact Rational
scale and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
atmosphere = Unit "atm" (unitDimension pascal) 101325 0

kelvin, celsius, fahrenheit, hertz, bit, byte, kibibyte, mebibyte, gigabyte :: Unit

{- | The kelvin Unit: absolute temperature with SI=value. Non-temperature definitions use an
exact Rational scale and zero affine offset. Use quantity or convert to
construct/convert values; temperature differences use temperatureDifference.
-}
kelvin = Unit "K" temperatureDimension 1 0

{- | The celsius Unit: absolute temperature with SI=value+273.15 kelvin. Non-temperature
definitions use an exact Rational scale and zero affine offset. Use quantity or convert
to construct/convert values; temperature differences use temperatureDifference.
-}
celsius = Unit "degC" temperatureDimension 1 273.15

{- | The fahrenheit Unit: absolute temperature with SI=(value-32)*5/9+273.15 kelvin.
Non-temperature definitions use an exact Rational scale and zero affine offset. Use
quantity or convert to construct/convert values; temperature differences use
temperatureDifference.
-}
fahrenheit = Unit "degF" temperatureDimension (5 / 9) (273.15 - 32 * 5 / 9)

{- | The hertz Unit: 1 inverse second. Non-temperature definitions use an exact Rational
scale and zero affine offset. Use quantity or convert to construct/convert values;
temperature differences use temperatureDifference.
-}
hertz = Unit "Hz" (scaleDimension (-1) timeDimension) 1 0

{- | The bit Unit: 1 data bit. Non-temperature definitions use an exact Rational scale and
zero affine offset. Use quantity or convert to construct/convert values; temperature
differences use temperatureDifference.
-}
bit = Unit "bit" dataDimension 1 0

{- | The byte Unit: 8 data bits. Non-temperature definitions use an exact Rational scale and
zero affine offset. Use quantity or convert to construct/convert values; temperature
differences use temperatureDifference.
-}
byte = Unit "B" dataDimension 8 0

{- | The kibibyte Unit: 8192 data bits (1024 bytes). Non-temperature definitions use an
exact Rational scale and zero affine offset. Use quantity or convert to
construct/convert values; temperature differences use temperatureDifference.
-}
kibibyte = Unit "KiB" dataDimension (8 * 1024) 0

{- | The mebibyte Unit: 8388608 data bits (1024^2 bytes). Non-temperature definitions use an
exact Rational scale and zero affine offset. Use quantity or convert to
construct/convert values; temperature differences use temperatureDifference.
-}
mebibyte = Unit "MiB" dataDimension (8 * 1024 * 1024) 0

{- | The gigabyte Unit: 8000000000 data bits (10^9 bytes). Non-temperature definitions use
an exact Rational scale and zero affine offset. Use quantity or convert to
construct/convert values; temperature differences use temperatureDifference.
-}
gigabyte = Unit "GB" dataDimension (8 * 10 ^ (9 :: Int)) 0

radian, degree, gradian :: Unit

{- | The radian Unit: 1 radian. Non-temperature definitions use an exact Rational scale and
zero affine offset. Use quantity or convert to construct/convert values; temperature
differences use temperatureDifference.
-}
radian = Unit "rad" angleDimension 1 0

{- | The degree Unit: pi/180 radian, using the stored 50-place Rational pi approximation.
Non-temperature definitions use an exact Rational scale and zero affine offset. Use
quantity or convert to construct/convert values; temperature differences use
temperatureDifference.
-}
degree = Unit "deg" angleDimension (piR / 180) 0

{- | The gradian Unit: pi/200 radian, using the stored Rational pi approximation.
Non-temperature definitions use an exact Rational scale and zero affine offset. Use
quantity or convert to construct/convert values; temperature differences use
temperatureDifference.
-}
gradian = Unit "grad" angleDimension (piR / 200) 0

piR :: Rational
piR = case filter ((== "pi") . constantName) mathematicalConstants of
    c : _ -> constantValue c
    [] -> 3.14159265358979323846264338327950288419716939937510
radiansToDegrees, degreesToRadians, radiansToGradians, gradiansToRadians :: (Floating a) => a -> a

{- | Convert radians to degrees by multiplying by 180/pi in the chosen Floating type. No
finite-input validation is added.
-}
radiansToDegrees x = x * 180 / pi

-- | Convert degrees to radians by multiplying by pi/180 in the chosen Floating type.
degreesToRadians x = x * pi / 180

-- | Convert radians to gradians (400 per full turn) by multiplying by 200/pi.
radiansToGradians x = x * 200 / pi

-- | Convert gradians to radians by multiplying by pi/200.
gradiansToRadians x = x * pi / 200
