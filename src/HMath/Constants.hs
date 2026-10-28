-- SPDX-License-Identifier: MPL-2.0

{- | Constants with machine-readable provenance and uncertainty. Mathematical
decimal literals carry an absolute truncation bound of 10^-50; conversion to
Float/Double adds the target format's rounding error. Physical values are the
CODATA 2022 adjustment (NIST SRD 121), not an unversioned latest-value promise.
-}
module HMath.Constants (
    piConstant,
    eConstant,
    tau,
    goldenRatio,
    eulerMascheroni,
    catalanConstant,
    aperyConstant,
    sqrt2,
    sqrt3,
    ln2,
    ln10,
    infinity,
    nan,
    Constant (..),
    constantAs,
    mathematicalConstants,
    physicalConstants,
    speedOfLight,
    planckConstant,
    elementaryCharge,
    boltzmannConstant,
    avogadroConstant,
    gravitationalConstant,
    electronMass,
    astronomicalUnit,
    NumericLimits (..),
    numericLimits,
    integerLimits,
) where

import HMath.Numeric (NumericLimits (..), integerLimits, numericLimits)

piConstant
    , eConstant
    , tau
    , goldenRatio
    , eulerMascheroni
    , catalanConstant
    , aperyConstant
    , sqrt2
    , sqrt3
    , ln2
    , ln10 ::
        (Floating a) => a

{- | The circle constant pi at the target Floating precision. Example: piConstant :: Double.
For decimal provenance and an approximation bound, use mathematicalConstants.
-}
piConstant = pi

{- | Euler number exp(1) at the target Floating precision. Use mathematicalConstants for
rational decimal provenance.
-}
eConstant = exp 1

-- | One full turn in radians, 2*pi, at target Floating precision.
tau = 2 * pi

-- | Golden ratio (1+sqrt 5)/2 at the target Floating precision.
goldenRatio = (1 + sqrt 5) / 2

{- | Euler-Mascheroni constant from the stored 50-decimal-place literal, rounded to the
chosen Floating type. Provenance is in mathematicalConstants.
-}
eulerMascheroni = 0.57721566490153286060651209008240243104215933593992

{- | Catalan constant from a 50-decimal-place literal, rounded to the target Floating type;
distinct from the integer Catalan-number sequence.
-}
catalanConstant = 0.91596559417721901505460351493238411077414937428167

{- | Apery constant zeta(3), from a 50-decimal-place literal rounded to the chosen Floating
type.
-}
aperyConstant = 1.20205690315959428539973816151144999076498629234049

-- | Positive square root of two in the target Floating type.
sqrt2 = sqrt 2

-- | Positive square root of three in the target Floating type.
sqrt3 = sqrt 3

-- | Natural logarithm of two in the target Floating type.
ln2 = log 2

-- | Natural logarithm of ten in the target Floating type.
ln10 = log 10

infinity, nan :: (RealFloat a) => a

{- | Positive IEEE infinity (1/0) for a RealFloat type. This value is intentionally
non-finite and is rejected by checked finite-input APIs.
-}
infinity = 1 / 0

{- | IEEE not-a-number (0/0) for a RealFloat type. NaN is not equal to itself; use isNaN to
inspect it.
-}
nan = 0 / 0

{- | Exact stored decimal Rational with name,unit,provenance,measurement uncertainty,and
separate approximation bound. constantAs converts the value without its metadata.
-}
data Constant = Constant
    { constantName :: String
    -- ^ Human-readable name of this mathematical or physical constant.
    , constantValue :: Rational
    -- ^ Exact Rational representation of the stored decimal value; measurement/approximation uncertainties are separate fields.
    , standardUncertainty :: Rational
    -- ^ Absolute one-standard-deviation measurement uncertainty; zero for definitions.
    , approximationBound :: Rational
    -- ^ Absolute decimal truncation bound, separate from measurement uncertainty.
    , constantUnit :: String
    -- ^ Display unit string; mathematical dimensionless constants use 1.
    , constantSource :: String
    -- ^ Provenance URL and adjustment/definition identifier for the stored value.
    }
    deriving (Eq, Show)

{- | Convert a Constant record's exact stored Rational decimal to the target Fractional
type. The result omits its uncertainty metadata; retain the record when reporting
measurements.
-}
constantAs :: (Fractional a) => Constant -> a
constantAs = fromRational . constantValue

{- | Catalog of mathematical constants with names, Rational decimal values, source URLs, and
absolute decimal truncation bounds of 10^-50. Measurement uncertainties are zero;
target Float/Double conversion adds rounding error.
-}
mathematicalConstants :: [Constant]
mathematicalConstants =
    [ math "pi" 3.14159265358979323846264338327950288419716939937510 "https://dlmf.nist.gov/4.19"
    , math "e" 2.71828182845904523536028747135266249775724709369995 "https://dlmf.nist.gov/4.2"
    , math "tau" 6.28318530717958647692528676655900576839433879875021 "https://dlmf.nist.gov/4.19"
    , math
        "golden ratio"
        1.61803398874989484820458683436563811772030917980576
        "https://dlmf.nist.gov/3.10"
    , math
        "Euler-Mascheroni"
        0.57721566490153286060651209008240243104215933593992
        "https://dlmf.nist.gov/5.2"
    , math "Catalan" 0.91596559417721901505460351493238411077414937428167 "https://dlmf.nist.gov/25.11"
    , math "Apery" 1.20205690315959428539973816151144999076498629234049 "https://dlmf.nist.gov/25.6"
    , math "sqrt 2" 1.41421356237309504880168872420969807856967187537694 "https://dlmf.nist.gov/4.2"
    , math "sqrt 3" 1.73205080756887729352744634150587236694280525381038 "https://dlmf.nist.gov/4.2"
    , math "ln 2" 0.69314718055994530941723212145817656807550013436025 "https://dlmf.nist.gov/4.2"
    , math "ln 10" 2.30258509299404568401799145468436420760110148862877 "https://dlmf.nist.gov/4.2"
    ]
  where
    math name value source = Constant name value 0 (1 / 10 ^ (50 :: Int)) "1" source

speedOfLight
    , planckConstant
    , elementaryCharge
    , boltzmannConstant
    , avogadroConstant
    , gravitationalConstant
    , electronMass
    , astronomicalUnit ::
        Constant

{- | Speed of light in vacuum: stored value 299792458 m s^-1, absolute standard uncertainty
0, from CODATA 2022. Returns a Constant metadata record; use constantAs for a numeric
conversion.
-}
speedOfLight = physical "speed of light in vacuum" 299792458 0 "m s^-1"

{- | Planck constant: stored value 6.62607015e-34 J s, absolute standard uncertainty 0, from
CODATA 2022. Returns a Constant metadata record; use constantAs for a numeric
conversion.
-}
planckConstant = physical "Planck constant" 6.62607015e-34 0 "J s"

{- | Elementary charge: stored value 1.602176634e-19 C, absolute standard uncertainty 0,
from CODATA 2022. Returns a Constant metadata record; use constantAs for a numeric
conversion.
-}
elementaryCharge = physical "elementary charge" 1.602176634e-19 0 "C"

{- | Boltzmann constant: stored value 1.380649e-23 J K^-1, absolute standard uncertainty 0,
from CODATA 2022. Returns a Constant metadata record; use constantAs for a numeric
conversion.
-}
boltzmannConstant = physical "Boltzmann constant" 1.380649e-23 0 "J K^-1"

{- | Avogadro constant: stored value 6.02214076e23 mol^-1, absolute standard uncertainty 0,
from CODATA 2022. Returns a Constant metadata record; use constantAs for a numeric
conversion.
-}
avogadroConstant = physical "Avogadro constant" 6.02214076e23 0 "mol^-1"

{- | Newtonian constant of gravitation: stored value 6.67430e-11 m^3 kg^-1 s^-2, absolute
standard uncertainty 0.00015e-11, from CODATA 2022. Returns a Constant metadata record;
use constantAs for a numeric conversion.
-}
gravitationalConstant = physical "Newtonian constant of gravitation" 6.67430e-11 0.00015e-11 "m^3 kg^-1 s^-2"

{- | Electron mass: stored value 9.1093837139e-31 kg, absolute standard uncertainty
0.0000000028e-31, from CODATA 2022. Returns a Constant metadata record; use constantAs
for a numeric conversion.
-}
electronMass = physical "electron mass" 9.1093837139e-31 0.0000000028e-31 "kg"

{- | IAU 2012 exact astronomical unit: 149597870700 metres, with zero measurement
uncertainty and approximation bound. Returns a Constant record with its source URL.
-}
astronomicalUnit =
    Constant
        "astronomical unit"
        149597870700
        0
        0
        "m"
        "https://www.iau.org/static/resolutions/IAU2012_English.pdf (Resolution B2)"

physical :: String -> Rational -> Rational -> String -> Constant
physical name value uncertainty unit =
    Constant
        name
        value
        uncertainty
        0
        unit
        "https://physics.nist.gov/cuu/Constants/Table/allascii.txt (CODATA 2022)"

{- | Catalog of supported physical constants, retaining unit, source, standard measurement
uncertainty, and approximation-bound metadata. Values use CODATA 2022 except the
IAU-defined astronomical unit.
-}
physicalConstants :: [Constant]
physicalConstants =
    [ speedOfLight
    , planckConstant
    , elementaryCharge
    , boltzmannConstant
    , avogadroConstant
    , gravitationalConstant
    , electronMass
    , astronomicalUnit
    ]
