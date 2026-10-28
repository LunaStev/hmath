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
piConstant = pi
eConstant = exp 1
tau = 2 * pi
goldenRatio = (1 + sqrt 5) / 2
eulerMascheroni = 0.57721566490153286060651209008240243104215933593992
catalanConstant = 0.91596559417721901505460351493238411077414937428167
aperyConstant = 1.20205690315959428539973816151144999076498629234049
sqrt2 = sqrt 2
sqrt3 = sqrt 3
ln2 = log 2
ln10 = log 10
infinity, nan :: (RealFloat a) => a
infinity = 1 / 0
nan = 0 / 0

data Constant = Constant
    { constantName :: String
    , constantValue :: Rational
    , standardUncertainty :: Rational
    -- ^ Absolute one-standard-deviation measurement uncertainty; zero for definitions.
    , approximationBound :: Rational
    -- ^ Absolute decimal truncation bound, separate from measurement uncertainty.
    , constantUnit :: String
    , constantSource :: String
    }
    deriving (Eq, Show)
constantAs :: (Fractional a) => Constant -> a
constantAs = fromRational . constantValue

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
speedOfLight = physical "speed of light in vacuum" 299792458 0 "m s^-1"
planckConstant = physical "Planck constant" 6.62607015e-34 0 "J s"
elementaryCharge = physical "elementary charge" 1.602176634e-19 0 "C"
boltzmannConstant = physical "Boltzmann constant" 1.380649e-23 0 "J K^-1"
avogadroConstant = physical "Avogadro constant" 6.02214076e23 0 "mol^-1"
gravitationalConstant = physical "Newtonian constant of gravitation" 6.67430e-11 0.00015e-11 "m^3 kg^-1 s^-2"
electronMass = physical "electron mass" 9.1093837139e-31 0.0000000028e-31 "kg"
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
