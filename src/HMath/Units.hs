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

newtype Dimension = Dimension [Integer] deriving (Eq, Show)

{- | Exponents in order length, mass, time, current, temperature, amount,
luminous intensity, data, plane angle. Require exactly nine exponents.
-}
dimension :: [Integer] -> Either MathError Dimension
dimension xs
    | length xs /= 9 = Left (InvalidArgument "dimension requires nine exponents")
    | otherwise = Right (Dimension xs)

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
dimensionless = Dimension (replicate 9 0)
lengthDimension = base 0
massDimension = base 1
timeDimension = base 2
temperatureDimension = base 4
dataDimension = base 7
angleDimension = base 8
base :: Int -> Dimension
base i = Dimension [if i == j then 1 else 0 | j <- [0 .. 8]]
combine :: (Integer -> Integer -> Integer) -> Dimension -> Dimension -> Dimension
combine op (Dimension a) (Dimension b) = Dimension (zipWith op a b)
scaleDimension :: Integer -> Dimension -> Dimension
scaleDimension n (Dimension xs) = Dimension (map (n *) xs)

data Unit = Unit String Dimension Rational Rational deriving (Eq, Show)
unitName :: Unit -> String
unitName (Unit name _ _ _) = name
unitDimension :: Unit -> Dimension
unitDimension (Unit _ dim _ _) = dim
unitScale :: Unit -> Rational
unitScale (Unit _ _ scale _) = scale
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
unitPower :: Unit -> Integer -> Either MathError Unit
unitPower a n
    | unitOffset a /= 0 = Left (DomainError "cannot exponentiate affine units")
    | otherwise =
        Right (Unit (unitName a ++ "^" ++ show n) (scaleDimension n (unitDimension a)) (unitScale a ^^ n) 0)

data Quantity = Quantity Dimension Rational Bool deriving (Eq, Show)
quantity :: Unit -> Rational -> Quantity
quantity u x =
    Quantity
        (unitDimension u)
        (x * unitScale u + unitOffset u)
        (unitDimension u == temperatureDimension)
temperatureDifference :: Unit -> Rational -> Either MathError Quantity
temperatureDifference u x
    | unitDimension u /= temperatureDimension =
        Left (DomainError "temperature difference requires temperature unit")
    | otherwise = Right (Quantity temperatureDimension (x * unitScale u) False)
quantityDimension :: Quantity -> Dimension
quantityDimension (Quantity d _ _) = d
siValue :: Quantity -> Rational
siValue (Quantity _ x _) = x
inUnit :: Unit -> Quantity -> Either MathError Rational
inUnit u (Quantity d x absoluteTemp)
    | unitDimension u /= d = Left (DomainError "incompatible dimensions")
    | otherwise = Right ((x - (if absoluteTemp then unitOffset u else 0)) / unitScale u)
convert :: Unit -> Unit -> Rational -> Either MathError Rational
convert a b x = inUnit b (quantity a x)
addQuantity
    , subtractQuantity
    , multiplyQuantity
    , divideQuantity ::
        Quantity -> Quantity -> Either MathError Quantity
addQuantity (Quantity d a absA) (Quantity e b absB)
    | d /= e = Left (DomainError "incompatible dimensions")
    | absA && absB = Left (DomainError "cannot add absolute temperatures")
    | otherwise = Right (Quantity d (a + b) (absA || absB))
subtractQuantity (Quantity d a absA) (Quantity e b absB)
    | d /= e = Left (DomainError "incompatible dimensions")
    | not absA && absB = Left (DomainError "cannot subtract absolute temperature from difference")
    | otherwise = Right (Quantity d (a - b) (absA && not absB))
multiplyQuantity (Quantity d a absA) (Quantity e b absB)
    | absA || absB = Left (DomainError "cannot multiply absolute temperatures")
    | otherwise = Right (Quantity (combine (+) d e) (a * b) False)
divideQuantity (Quantity d a absA) (Quantity e b absB)
    | absA || absB = Left (DomainError "cannot divide absolute temperatures")
    | b == 0 = Left (DomainError "quantity division by zero")
    | otherwise = Right (Quantity (combine (-) d e) (a / b) False)

data SIPrefix = SIPrefix {prefixName :: String, prefixSymbol :: String, prefixExponent :: Int}
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

prefixed :: SIPrefix -> Unit -> Either MathError Unit
prefixed p u
    | unitOffset u /= 0 = Left (DomainError "cannot prefix affine unit")
    | abs (toInteger (prefixExponent p)) > 10000 =
        Left (InvalidArgument "prefix exponent exceeds resource limit")
    | otherwise =
        let e = prefixExponent p; s = if e >= 0 then fromInteger (10 ^ e) else 1 / fromInteger (10 ^ negate e)
         in Right (Unit (prefixSymbol p ++ unitName u) (unitDimension u) (s * unitScale u) 0)

metre, kilometre, centimetre, millimetre, inch, foot, yard, mile, nauticalMile :: Unit
metre = Unit "m" lengthDimension 1 0
kilometre = Unit "km" lengthDimension 1000 0
centimetre = Unit "cm" lengthDimension 0.01 0
millimetre = Unit "mm" lengthDimension 0.001 0
inch = Unit "in" lengthDimension 0.0254 0
foot = Unit "ft" lengthDimension 0.3048 0
yard = Unit "yd" lengthDimension 0.9144 0
mile = Unit "mi" lengthDimension 1609.344 0
nauticalMile = Unit "nmi" lengthDimension 1852 0
squareMetre, hectare, cubicMetre, litre, millilitre :: Unit
squareMetre = Unit "m^2" (scaleDimension 2 lengthDimension) 1 0
hectare = Unit "ha" (scaleDimension 2 lengthDimension) 10000 0
cubicMetre = Unit "m^3" (scaleDimension 3 lengthDimension) 1 0
litre = Unit "L" (scaleDimension 3 lengthDimension) 0.001 0
millilitre = Unit "mL" (scaleDimension 3 lengthDimension) 0.000001 0
kilogram, gram, tonne, pound, second, minute, hour, day :: Unit
kilogram = Unit "kg" massDimension 1 0
gram = Unit "g" massDimension 0.001 0
tonne = Unit "t" massDimension 1000 0
pound = Unit "lb" massDimension 0.45359237 0
second = Unit "s" timeDimension 1 0
minute = Unit "min" timeDimension 60 0
hour = Unit "h" timeDimension 3600 0
day = Unit "d" timeDimension 86400 0
metresPerSecond, kilometresPerHour, milesPerHour, metresPerSecondSquared :: Unit
metresPerSecond = Unit "m/s" (combine (-) lengthDimension timeDimension) 1 0
kilometresPerHour = Unit "km/h" (unitDimension metresPerSecond) (1000 / 3600) 0
milesPerHour = Unit "mi/h" (unitDimension metresPerSecond) (1609.344 / 3600) 0
metresPerSecondSquared = Unit "m/s^2" (combine (-) lengthDimension (scaleDimension 2 timeDimension)) 1 0
newton, joule, watt, pascal, bar, atmosphere :: Unit
newton = Unit "N" (combine (+) massDimension (unitDimension metresPerSecondSquared)) 1 0
joule = Unit "J" (combine (+) (unitDimension newton) lengthDimension) 1 0
watt = Unit "W" (combine (-) (unitDimension joule) timeDimension) 1 0
pascal = Unit "Pa" (combine (-) (unitDimension newton) (unitDimension squareMetre)) 1 0
bar = Unit "bar" (unitDimension pascal) 100000 0
atmosphere = Unit "atm" (unitDimension pascal) 101325 0
kelvin, celsius, fahrenheit, hertz, bit, byte, kibibyte, mebibyte, gigabyte :: Unit
kelvin = Unit "K" temperatureDimension 1 0
celsius = Unit "degC" temperatureDimension 1 273.15
fahrenheit = Unit "degF" temperatureDimension (5 / 9) (273.15 - 32 * 5 / 9)
hertz = Unit "Hz" (scaleDimension (-1) timeDimension) 1 0
bit = Unit "bit" dataDimension 1 0
byte = Unit "B" dataDimension 8 0
kibibyte = Unit "KiB" dataDimension (8 * 1024) 0
mebibyte = Unit "MiB" dataDimension (8 * 1024 * 1024) 0
gigabyte = Unit "GB" dataDimension (8 * 10 ^ (9 :: Int)) 0
radian, degree, gradian :: Unit
radian = Unit "rad" angleDimension 1 0
degree = Unit "deg" angleDimension (piR / 180) 0
gradian = Unit "grad" angleDimension (piR / 200) 0
piR :: Rational
piR = case filter ((== "pi") . constantName) mathematicalConstants of
    c : _ -> constantValue c
    [] -> 3.14159265358979323846264338327950288419716939937510
radiansToDegrees, degreesToRadians, radiansToGradians, gradiansToRadians :: (Floating a) => a -> a
radiansToDegrees x = x * 180 / pi
degreesToRadians x = x * pi / 180
radiansToGradians x = x * 200 / pi
gradiansToRadians x = x * pi / 200
