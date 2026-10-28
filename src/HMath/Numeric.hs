-- SPDX-License-Identifier: MPL-2.0

-- | Numeric representations and deterministic IEEE utilities. Standard integer,
-- rational, binary32/64 and complex types are re-exported. Conversions never
-- silently promote precision: 'BigFloat' operations explicitly select the larger
-- operand precision, decimal/fixed operations the larger scale. The host IEEE
-- rounding environment is not modified. Explicit rounding returns software flags.
module HMath.Numeric
    ( Int8, Int16, Int32, Int64, Word8, Word16, Word32, Word64
    , Float32, Float64, Complex(..), Rational
    , RoundingMode(..), NumericException(..), Rounded(..), roundRational
    , IEEEClass(..), classify, NumericLimits(..), numericLimits, integerLimits, float16Limits, bfloat16Limits
    , nextAfter, frexp, ldexp, ulpDistance, withinULPs
    , safeIntegralCast, saturatingCast, realToIntegral, narrowFloat
    , Float16, float16, fromFloat16, float16Bits, float16FromBits
    , BFloat16, bfloat16, fromBFloat16, bfloat16Bits, bfloat16FromBits
    , BigFloat, bigFloat, bigPrecision, bigRational, bigToDouble
    , bigAdd, bigSubtract, bigMultiply, bigDivide, bigSqrt, bigExp, bigLog
    , extended, mixedAdd, mixedMultiply
    , Fixed, fixed, fixedScale, fixedCoefficient, fixedRational, fixedAdd, fixedMultiply, fixedDivide
    , Decimal, decimal, decimalRational, decimalAdd, decimalMultiply, decimalDivide
    , Interval, interval, intervalBounds, intervalAdd, intervalSubtract, intervalMultiply, intervalDivide
    , intervalContains, Dual(..), derivative
    , Quaternion(..), quaternionConjugate, quaternionNorm, quaternionInverse, rotateVector
    , DualQuaternion(..), dualQuaternionMultiply, dualQuaternionInverse, rigidTransform, transformPoint
    , kahanSum, neumaierSum, pairwiseSum, logsumexp, sumErrorBound
    ) where

import Data.Bits ((.&.), (.|.), shiftL, shiftR, testBit)
import Data.Complex (Complex(..))
import Data.Int (Int8,Int16,Int32,Int64)
import qualified Data.List as L
import Data.Ratio (numerator,denominator,(%))
import Data.Word (Word8,Word16,Word32,Word64)
import GHC.Float (castDoubleToWord64)
import HMath.Error (MathError(..))

type Float32 = Float
type Float64 = Double

data RoundingMode = NearestEven | TowardZero | TowardPositive | TowardNegative
    deriving (Eq,Show)
data NumericException = InvalidOperation | DivisionByZero | NumericOverflow | NumericUnderflow | Inexact
    deriving (Eq,Show)
data Rounded a = Rounded { roundedValue :: a, numericalExceptions :: [NumericException] }
    deriving (Eq,Show)

roundRational :: RoundingMode -> Rational -> Integer
roundRational NearestEven = round
roundRational TowardZero = truncate
roundRational TowardPositive = ceiling
roundRational TowardNegative = floor

data IEEEClass = NotANumber | PositiveInfinity | NegativeInfinity | PositiveZero | NegativeZero | Subnormal | Normal
    deriving (Eq,Show)
classify :: RealFloat a => a -> IEEEClass
classify x | isNaN x = NotANumber
           | isInfinite x = if x > 0 then PositiveInfinity else NegativeInfinity
           | x == 0 = if isNegativeZero x then NegativeZero else PositiveZero
           | isDenormalized x = Subnormal
           | otherwise = Normal

data NumericLimits a = NumericLimits
    { minimumNormal :: a, minimumSubnormal :: a, maximumFinite :: a, machineEpsilon :: a
    , significandDigits :: Int, minimumExponent :: Int, maximumExponent :: Int }
    deriving (Eq,Show)
-- | Derived from 'RealFloat' radix/digits/range, not hardcoded for Double.
numericLimits :: RealFloat a => a -> NumericLimits a
numericLimits witness = NumericLimits (encodeFloat 1 (lo-1)) (encodeFloat 1 (lo-p))
    (encodeFloat (b^p-1) (hi-p)) (encodeFloat 1 (1-p)) p lo hi
  where b=toInteger (floatRadix witness); p=floatDigits witness; (lo,hi)=floatRange witness
-- | Limits returned as exact binary64 values for the two 16-bit storage formats.
float16Limits, bfloat16Limits :: NumericLimits Double
float16Limits=NumericLimits (2**(-14)) (2**(-24)) 65504 (2**(-10)) 11 (-13) 16
bfloat16Limits=NumericLimits (2**(-126)) (2**(-133)) (encodeFloat 255 120) (2**(-7)) 8 (-125) 128
integerLimits :: (Integral a,Bounded a) => a -> (Integer,Integer)
integerLimits x = (toInteger (minBound `asTypeOf` x),toInteger (maxBound `asTypeOf` x))

-- | Adjacent representable value toward target, including gradual underflow.
-- Equal signed zeros return the target; NaN propagates. Supports binary formats.
nextAfter :: RealFloat a => a -> a -> a
nextAfter x target
    | isNaN x || isNaN target = 0/0
    | x == target = target
    | isInfinite x = if x > 0 then maximumFinite lim else negate (maximumFinite lim)
    | x == 0 = if target > 0 then minimumSubnormal lim else negate (minimumSubnormal lim)
    | otherwise = signum x * fromRational (toRational ax + (if increase then unit else negate unit))
  where
    lim=numericLimits x
    ax=abs x
    increase=(target > x) == (x > 0)
    (m,e)=decodeFloat ax
    p=floatDigits x
    b=toInteger (floatRadix x)
    quantum=max (minimumExponent lim-p) (if not increase && m == b^(p-1) then e-1 else e)
    unit=if quantum >= 0 then fromInteger (b^quantum) else 1/fromInteger (b^negate quantum)

-- | x=m*2^e, with abs m in [1/2,1) for nonzero finite binary inputs.
frexp :: RealFloat a => a -> (a,Int)
frexp x | x == 0 || isNaN x || isInfinite x = (x,0)
        | otherwise = let (_,e)=decodeFloat x; k=e+floatDigits x in (scaleFloat (-k) x,k)
ldexp :: RealFloat a => a -> Int -> a
ldexp x n = scaleFloat n x

-- | IEEE binary64 distance. Signed zeros compare equal; NaN is rejected.
ulpDistance :: Double -> Double -> Either MathError Integer
ulpDistance a b
    | isNaN a || isNaN b = Left (DomainError "ULP distance is undefined for NaN")
    | otherwise = Right (abs (ordered a-ordered b))
  where
    ordered x = let bits=castDoubleToWord64 x; mag=toInteger (bits .&. 0x7fffffffffffffff)
                 in if testBit bits 63 then negate mag else mag
withinULPs :: Integer -> Double -> Double -> Bool
withinULPs n a b = n >= 0 && either (const False) (<=n) (ulpDistance a b)

safeIntegralCast :: (Integral a,Integral b,Bounded b) => a -> Either MathError b
safeIntegralCast x = r where
    y=fromIntegral x
    r=if toInteger x < toInteger (minBound `asTypeOf` y) || toInteger x > toInteger (maxBound `asTypeOf` y)
        then Left (DomainError "integral cast out of range") else Right y
saturatingCast :: (Integral a,Integral b,Bounded b) => a -> b
saturatingCast x = y where y=fromInteger (max (toInteger (minBound `asTypeOf` y)) (min (toInteger (maxBound `asTypeOf` y)) (toInteger x)))
realToIntegral :: (RealFloat a,Integral b,Bounded b) => RoundingMode -> a -> Either MathError b
realToIntegral mode x
    | isNaN x || isInfinite x = Left (DomainError "non-finite integral cast")
    | otherwise = safeIntegralCast (roundRational mode (toRational x))
-- | A narrowing conversion must be finite and exact; choose explicit quantized
-- Float16/BigFloat rounding APIs when loss of precision is intentional.
narrowFloat :: (RealFloat a,RealFloat b) => a -> Either MathError b
narrowFloat x
    | isNaN x || isInfinite x = Left (DomainError "non-finite float cast")
    | isInfinite y = Left NonFiniteResult
    | toRational y /= toRational x = Left (DomainError "inexact float cast")
    | otherwise = Right y
  where y=if x == 0 && isNegativeZero x then -0 else fromRational (toRational x)

-- | IEEE binary16 and bfloat16 storage. Conversion rounds directly from the
-- exact binary64 value (no intermediate binary32 rounding), preserving signed
-- zero and infinity. NaNs are canonical quiet NaNs. All four rounding modes
-- report inexact, overflow and tininess-after-rounding underflow flags.
newtype Float16 = Float16 Word16 deriving (Eq,Show)
newtype BFloat16 = BFloat16 Word16 deriving (Eq,Show)
float16Bits :: Float16 -> Word16
float16Bits (Float16 w)=w
float16FromBits :: Word16 -> Float16
float16FromBits=Float16
bfloat16Bits :: BFloat16 -> Word16
bfloat16Bits (BFloat16 w)=w
bfloat16FromBits :: Word16 -> BFloat16
bfloat16FromBits=BFloat16
float16 :: RoundingMode -> Double -> Rounded Float16
float16 mode x = let Rounded w flags=encodeSmall 5 10 mode x in Rounded (Float16 w) flags
bfloat16 :: RoundingMode -> Double -> Rounded BFloat16
bfloat16 mode x = let Rounded w flags=encodeSmall 8 7 mode x in Rounded (BFloat16 w) flags
fromFloat16 :: Float16 -> Double
fromFloat16 (Float16 w)=decodeSmall 5 10 w
fromBFloat16 :: BFloat16 -> Double
fromBFloat16 (BFloat16 w)=decodeSmall 8 7 w

powerTwo :: Int -> Rational
powerTwo e | e >= 0 = fromInteger (2^e)
           | otherwise = 1 % (2^negate e)
integerBits :: Integer -> Int
integerBits n = go (abs n) 0 where go 0 k=k; go v k=go (v `quot` 2) (k+1)
floorLog2 :: Rational -> Int
floorLog2 x = let candidate=integerBits (numerator x)-integerBits (denominator x)
               in if x < powerTwo candidate then candidate-1 else candidate
encodeSmall :: Int -> Int -> RoundingMode -> Double -> Rounded Word16
encodeSmall eb fb mode x
    | isNaN x = Rounded (expMask .|. fromIntegral (2^(fb-1)::Int)) [InvalidOperation | not (testBit (castDoubleToWord64 x) 51)]
    | isInfinite x = Rounded (sgn .|. expMask) []
    | x == 0 = Rounded sgn []
    | otherwise =
        let q=toRational x; e=max emin (floorLog2 (abs q)); quantum=powerTwo (e-fb)
            mant=roundRational mode (q/quantum); rounded=fromInteger mant*quantum
            inexact=rounded /= q
            maxValue=fromInteger (2^(fb+1)-1)*powerTwo (emax-fb)
            overflow=abs rounded > maxValue
            toInf=mode == NearestEven || (mode == TowardPositive && x > 0) || (mode == TowardNegative && x < 0)
            magnitude=abs mant
            (expField,frac)=if magnitude < 2^fb then (0,magnitude)
                else if magnitude >= 2^(fb+1) then (e+1+bias,0) else (e+bias,magnitude-2^fb)
            bits=if overflow then (if toInf then expMask else expMask-1)
                else fromIntegral ((toInteger expField `shiftL` fb)+frac)
            flags=[NumericOverflow | overflow]++[NumericUnderflow | inexact && abs rounded < powerTwo emin]++[Inexact | inexact || overflow]
        in Rounded (sgn .|. bits) flags
  where
    bias=2^(eb-1)-1; emin=1-bias; emax=bias
    expMask=fromIntegral (((2^eb-1)::Int) `shiftL` fb)
    sgn=if x < 0 || isNegativeZero x then 0x8000 else 0

decodeSmall :: Int -> Int -> Word16 -> Double
decodeSmall eb fb w
    | e == 2^eb-1 = if f == 0 then s/0 else 0/0
    | e == 0 = if f == 0 then (if testBit w 15 then -0 else 0) else s*encodeFloat (toInteger f) (1-bias-fb)
    | otherwise = s*encodeFloat (toInteger (2^fb+f)) (e-bias-fb)
  where
    e=fromIntegral ((w `shiftR` fb) .&. fromIntegral ((2^eb-1)::Int))
    f=fromIntegral (w .&. fromIntegral ((2^fb-1)::Int)) :: Int
    bias=2^(eb-1)-1
    s=if testBit w 15 then -1 else 1

-- | An unbounded-exponent binary floating value backed by an exact Rational,
-- rounded to a runtime number of significant bits (2..1,000,000). Unlike Double,
-- this is genuinely configurable precision. No NaN/infinity or hidden CPU flags.
-- Algebraic operations round once, nearest-even; explicit construction can select
-- any 'RoundingMode'. Transcendentals use guard bits and rational series.
data BigFloat = BigFloat Int Rational deriving (Eq,Show)
bigPrecision :: BigFloat -> Int
bigPrecision (BigFloat p _)=p
bigRational :: BigFloat -> Rational
bigRational (BigFloat _ x)=x
bigFloat :: Int -> RoundingMode -> Rational -> Either MathError (Rounded BigFloat)
bigFloat p mode x
    | p < 2 || p > 1000000 = Left (InvalidArgument "precision must be 2..1000000 bits")
    | x == 0 = Right (Rounded (BigFloat p 0) [])
    | otherwise = let quantum=powerTwo (floorLog2 (abs x)-p+1)
                      y=fromInteger (roundRational mode (x/quantum))*quantum
                  in Right (Rounded (BigFloat p y) [Inexact | x /= y])
-- | Software extended precision: 64 significant bits, unbounded exponent.
extended :: Rational -> Either MathError BigFloat
extended x=roundedValue <$> bigFloat 64 NearestEven x
bigToDouble :: BigFloat -> Double
bigToDouble=fromRational . bigRational
bigResult :: Int -> Rational -> Either MathError BigFloat
bigResult p x=roundedValue <$> bigFloat p NearestEven x
bigAdd, bigSubtract, bigMultiply, bigDivide :: BigFloat -> BigFloat -> Either MathError BigFloat
bigAdd a b=bigResult (max (bigPrecision a) (bigPrecision b)) (bigRational a+bigRational b)
bigSubtract a b=bigResult (max (bigPrecision a) (bigPrecision b)) (bigRational a-bigRational b)
bigMultiply a b=bigResult (max (bigPrecision a) (bigPrecision b)) (bigRational a*bigRational b)
bigDivide _ (BigFloat _ 0)=Left (DomainError "BigFloat division by zero")
bigDivide a b=bigResult (max (bigPrecision a) (bigPrecision b)) (bigRational a/bigRational b)
mixedAdd, mixedMultiply :: BigFloat -> Double -> Either MathError BigFloat
mixedAdd a x
    | isNaN x || isInfinite x = Left (DomainError "non-finite mixed operand")
    | otherwise = bigResult (max 53 (bigPrecision a)) (bigRational a+toRational x)
mixedMultiply a x
    | isNaN x || isInfinite x = Left (DomainError "non-finite mixed operand")
    | otherwise = bigResult (max 53 (bigPrecision a)) (bigRational a*toRational x)

integerSqrt :: Integer -> Integer
integerSqrt n | n < 2 = n
              | otherwise = go (2^((integerBits n+1) `quot` 2))
  where go x=let y=(x+n `quot` x) `quot` 2 in if y >= x then x else go y
bigSqrt :: BigFloat -> Either MathError BigFloat
bigSqrt (BigFloat p x)
    | x < 0 = Left (DomainError "negative BigFloat square root")
    | x == 0 = bigResult p 0
    | otherwise = let e=floorLog2 x `div` 2-p-8; q=powerTwo e
                      n=integerSqrt (floor (x/(q*q)))
                  in bigResult p (fromInteger n*q)
-- | Absolute tail controlled rational series; final rounding is accurate to
-- the requested precision up to one final ulp, not a correctly-rounded promise.
bigExp :: BigFloat -> Either MathError BigFloat
bigExp (BigFloat p x)
    | abs x > 100000 = Left (InvalidArgument "BigFloat exponential argument exceeds resource limit 100000")
    | x < 0 = do y <- bigExp (BigFloat (p+16) (-x)); bigResult p (1/bigRational y)
    | otherwise = let reductions=max 0 (floorLog2 (max 1 x)+2)
                      y=x/powerTwo reductions
                      eps=powerTwo (negate (p+reductions+24))
                      series k term acc=let term'=term*y/fromIntegral k; acc'=acc+term'
                          in if abs term' < eps then acc' else series (k+1) term' acc'
                      initial=series (1::Integer) 1 1
                      sq 0 v=Right v
                      sq k v=do rounded <- bigResult (p+reductions+24) (v*v); sq (k-1) (bigRational rounded)
                  in sq reductions initial >>= bigResult p
bigLog :: BigFloat -> Either MathError BigFloat
bigLog (BigFloat p x)
    | x <= 0 = Left (DomainError "BigFloat logarithm needs positive input")
    | otherwise = let e=floorLog2 x; mant=x/powerTwo e
                      eps=powerTwo (negate (p+integerBits (toInteger (abs e)+1)+24))
                      atanhSeries y=go (1::Integer) y y where
                          go k term acc=let term'=term*y*y; add=term'/fromIntegral (2*k+1)
                              in if abs add < eps then 2*(acc+add) else go (k+1) term' (acc+add)
                      l2=atanhSeries (1/3)
                  in bigResult p (atanhSeries ((mant-1)/(mant+1))+fromIntegral e*l2)

-- | Runtime-scale base-ten fixed point: coefficient * 10^(-scale). All
-- constructors and arithmetic use explicit rounding and report inexactness.
data Fixed = Fixed Int Integer deriving (Eq,Show)
fixedScale :: Fixed -> Int
fixedScale (Fixed s _)=s
fixedCoefficient :: Fixed -> Integer
fixedCoefficient (Fixed _ c)=c
fixedRational :: Fixed -> Rational
fixedRational (Fixed s n)=n % (10^s)
fixed :: Int -> RoundingMode -> Rational -> Either MathError (Rounded Fixed)
fixed s mode x
    | s < 0 || s > 10000 = Left (InvalidArgument "fixed scale must be 0..10000")
    | otherwise = let c=roundRational mode (x*fromInteger (10^s)); v=Fixed s c
                  in Right (Rounded v [Inexact | fixedRational v /= x])
fixedAdd :: Fixed -> Fixed -> Either MathError (Rounded Fixed)
fixedAdd a b=fixed (max (fixedScale a) (fixedScale b)) NearestEven (fixedRational a+fixedRational b)
fixedMultiply :: RoundingMode -> Fixed -> Fixed -> Either MathError (Rounded Fixed)
fixedMultiply mode a b=fixed (max (fixedScale a) (fixedScale b)) mode (fixedRational a*fixedRational b)
fixedDivide :: RoundingMode -> Fixed -> Fixed -> Either MathError (Rounded Fixed)
fixedDivide mode a b
    | fixedCoefficient b == 0 = Left (DomainError "fixed division by zero")
    | otherwise = fixed (max (fixedScale a) (fixedScale b)) mode (fixedRational a/fixedRational b)
newtype Decimal = Decimal Fixed deriving (Eq,Show)
decimal :: Int -> RoundingMode -> Rational -> Either MathError (Rounded Decimal)
decimal p mode x = do Rounded v flags <- fixed p mode x; Right (Rounded (Decimal v) flags)
decimalRational :: Decimal -> Rational
decimalRational (Decimal f)=fixedRational f
decimalAdd :: Decimal -> Decimal -> Either MathError (Rounded Decimal)
decimalAdd (Decimal a) (Decimal b)=do Rounded v flags <- fixedAdd a b; Right (Rounded (Decimal v) flags)
decimalMultiply, decimalDivide :: RoundingMode -> Decimal -> Decimal -> Either MathError (Rounded Decimal)
decimalMultiply mode (Decimal a) (Decimal b)=do Rounded v flags <- fixedMultiply mode a b; Right (Rounded (Decimal v) flags)
decimalDivide mode (Decimal a) (Decimal b)=do Rounded v flags <- fixedDivide mode a b; Right (Rounded (Decimal v) flags)

-- | Finite closed binary64 intervals. Arithmetic endpoints are rounded outward
-- using exact rationals, so results enclose exact real arithmetic. Unbounded
-- output is rejected; division rejects denominators containing zero.
data Interval = Interval Double Double deriving (Eq,Show)
interval :: Double -> Double -> Either MathError Interval
interval a b
    | any (\x -> isNaN x || isInfinite x) [a,b] || a > b = Left (DomainError "invalid finite interval")
    | otherwise = Right (Interval a b)
intervalBounds :: Interval -> (Double,Double)
intervalBounds (Interval a b)=(a,b)
intervalContains :: Interval -> Double -> Bool
intervalContains (Interval a b) x=a <= x && x <= b
outward :: Rational -> Rational -> Either MathError Interval
outward lo hi = interval (down lo) (up hi)
  where
    down q=let x=fromRational q in if isInfinite x then x else if toRational x > q then nextAfter x (-1/0) else x
    up q=let x=fromRational q in if isInfinite x then x else if toRational x < q then nextAfter x (1/0) else x
intervalAdd, intervalSubtract, intervalMultiply, intervalDivide :: Interval -> Interval -> Either MathError Interval
intervalAdd (Interval a b) (Interval c d)=outward (toRational a+toRational c) (toRational b+toRational d)
intervalSubtract (Interval a b) (Interval c d)=outward (toRational a-toRational d) (toRational b-toRational c)
intervalMultiply (Interval a b) (Interval c d)=let xs=[toRational x*toRational y | x<-[a,b],y<-[c,d]] in outward (minimum xs) (maximum xs)
intervalDivide (Interval a b) (Interval c d)
    | c <= 0 && d >= 0 = Left (DomainError "interval divisor contains zero")
    | otherwise = let xs=[toRational x/toRational y | x<-[a,b],y<-[c,d]] in outward (minimum xs) (maximum xs)

-- | Forward-mode automatic differentiation, f(a+b epsilon), epsilon^2=0.
-- Elementary functions follow host IEEE domains; checked algorithms can inspect
-- both components. abs at zero uses derivative zero (a chosen subgradient).
data Dual a = Dual { primal :: a, tangent :: a } deriving (Eq,Show)
instance Num a => Num (Dual a) where
    Dual a b + Dual c d=Dual (a+c) (b+d)
    Dual a b - Dual c d=Dual (a-c) (b-d)
    Dual a b * Dual c d=Dual (a*c) (a*d+b*c)
    negate (Dual a b)=Dual (negate a) (negate b)
    abs (Dual a b)=Dual (abs a) (signum a*b)
    signum (Dual a _)=Dual (signum a) 0
    fromInteger n=Dual (fromInteger n) 0
instance Fractional a => Fractional (Dual a) where
    recip (Dual a b)=Dual (recip a) (-b/(a*a))
    fromRational r=Dual (fromRational r) 0
instance Floating a => Floating (Dual a) where
    pi=Dual pi 0
    exp (Dual a b)=Dual (exp a) (b*exp a)
    log (Dual a b)=Dual (log a) (b/a)
    sqrt (Dual a b)=Dual (sqrt a) (b/(2*sqrt a))
    sin (Dual a b)=Dual (sin a) (b*cos a)
    cos (Dual a b)=Dual (cos a) (-b*sin a)
    tan (Dual a b)=Dual (tan a) (b/(cos a*cos a))
    asin (Dual a b)=Dual (asin a) (b/sqrt (1-a*a))
    acos (Dual a b)=Dual (acos a) (-b/sqrt (1-a*a))
    atan (Dual a b)=Dual (atan a) (b/(1+a*a))
    sinh (Dual a b)=Dual (sinh a) (b*cosh a)
    cosh (Dual a b)=Dual (cosh a) (b*sinh a)
    tanh (Dual a b)=Dual (tanh a) (b/(cosh a*cosh a))
    asinh (Dual a b)=Dual (asinh a) (b/sqrt (1+a*a))
    acosh (Dual a b)=Dual (acosh a) (b/sqrt (a*a-1))
    atanh (Dual a b)=Dual (atanh a) (b/(1-a*a))
derivative :: Num a => (Dual a -> Dual a) -> a -> a
derivative f x=tangent (f (Dual x 1))

-- | Hamilton quaternion (real, i, j, k); multiplication is noncommutative.
data Quaternion a = Quaternion a a a a deriving (Eq,Show)
instance RealFloat a => Num (Quaternion a) where
    Quaternion a b c d + Quaternion e f g h=Quaternion (a+e) (b+f) (c+g) (d+h)
    Quaternion a b c d - Quaternion e f g h=Quaternion (a-e) (b-f) (c-g) (d-h)
    Quaternion a b c d * Quaternion e f g h=Quaternion (a*e-b*f-c*g-d*h) (a*f+b*e+c*h-d*g) (a*g-b*h+c*e+d*f) (a*h+b*g-c*f+d*e)
    negate (Quaternion a b c d)=Quaternion (-a) (-b) (-c) (-d)
    fromInteger n=Quaternion (fromInteger n) 0 0 0
    abs q=Quaternion (quaternionNorm q) 0 0 0
    signum q=let n=quaternionNorm q in if n == 0 then Quaternion 0 0 0 0 else qScale (1/n) q
quaternionConjugate :: Num a => Quaternion a -> Quaternion a
quaternionConjugate (Quaternion a b c d)=Quaternion a (-b) (-c) (-d)
quaternionNorm :: RealFloat a => Quaternion a -> a
quaternionNorm (Quaternion a b c d)
    | scale == 0 = 0
    | otherwise = scale*sqrt (sum [let v=x/scale in v*v | x<-[a,b,c,d]])
  where scale=maximum (map abs [a,b,c,d])
qScale :: Num a => a -> Quaternion a -> Quaternion a
qScale s (Quaternion a b c d)=Quaternion (s*a) (s*b) (s*c) (s*d)
qDivide :: Fractional a => Quaternion a -> a -> Quaternion a
qDivide (Quaternion a b c d) s=Quaternion (a/s) (b/s) (c/s) (d/s)
quaternionInverse :: RealFloat a => Quaternion a -> Either MathError (Quaternion a)
quaternionInverse q@(Quaternion a b c d)
    | any (\x -> isNaN x || isInfinite x) [a,b,c,d] || maximum (map abs [a,b,c,d]) == 0 = Left (DomainError "invalid quaternion inverse")
    | otherwise = let scale=maximum (map abs [a,b,c,d]); qs=qDivide q scale
                      Quaternion e f g h=qs; denom=e*e+f*f+g*g+h*h
                      out=qDivide (qDivide (quaternionConjugate qs) denom) scale
                  in if qFinite out then Right out else Left NonFiniteResult
qFinite :: RealFloat a => Quaternion a -> Bool
qFinite (Quaternion a b c d)=all (\x -> not (isNaN x || isInfinite x)) [a,b,c,d]
rotateVector :: RealFloat a => Quaternion a -> (a,a,a) -> Either MathError (a,a,a)
rotateVector q (x,y,z)=do
    qi <- quaternionInverse q
    let Quaternion _ a b c=q*Quaternion 0 x y z*qi
    if all (\v -> not (isNaN v || isInfinite v)) [a,b,c] then Right (a,b,c) else Left NonFiniteResult

data DualQuaternion a = DualQuaternion (Quaternion a) (Quaternion a) deriving (Eq,Show)
dualQuaternionMultiply :: RealFloat a => DualQuaternion a -> DualQuaternion a -> DualQuaternion a
dualQuaternionMultiply (DualQuaternion a b) (DualQuaternion c d)=DualQuaternion (a*c) (a*d+b*c)
dualQuaternionInverse :: RealFloat a => DualQuaternion a -> Either MathError (DualQuaternion a)
dualQuaternionInverse (DualQuaternion a b)=do ai <- quaternionInverse a; Right (DualQuaternion ai (negate (ai*b*ai)))
-- | Construct a rigid transform from a nonzero rotation quaternion and translation.
rigidTransform :: RealFloat a => Quaternion a -> (a,a,a) -> Either MathError (DualQuaternion a)
rigidTransform q (x,y,z)=do
    _ <- quaternionInverse q
    let Quaternion a b c d=q
        scale=maximum (map abs [a,b,c,d]); qs=qDivide q scale
        r=qDivide qs (quaternionNorm qs)
        dual=Quaternion 0 (x/2) (y/2) (z/2)*r
    if qFinite r && qFinite dual then Right (DualQuaternion r dual) else Left NonFiniteResult
transformPoint :: RealFloat a => DualQuaternion a -> (a,a,a) -> Either MathError (a,a,a)
transformPoint (DualQuaternion r d) v=do
    (a,b,c) <- rotateVector r v
    ri <- quaternionInverse r
    let Quaternion _ x y z=qScale 2 (d*ri)
    if all (\u -> not (isNaN u || isInfinite u)) [a+x,b+y,c+z] then Right (a+x,b+y,c+z) else Left NonFiniteResult

kahanSum :: Num a => [a] -> a
kahanSum xs=fst (L.foldl' step (0,0) xs) where
    step (s,c) x=let y=x-c; t=s+y in (t,(t-s)-y)
neumaierSum :: (Num a,Ord a) => [a] -> a
neumaierSum xs=let (s,c)=L.foldl' step (0,0) xs in s+c where
    step (s,c) x=let t=s+x; correction=if abs s >= abs x then (s-t)+x else (x-t)+s in (t,c+correction)
pairwiseSum :: Num a => [a] -> a
pairwiseSum []=0
pairwiseSum [x]=x
pairwiseSum xs=let (a,b)=splitAt (length xs `quot` 2) xs in pairwiseSum a+pairwiseSum b
-- | Empty input is -infinity; +infinity dominates finite/-infinite inputs.
-- NaN is rejected, and an all -infinity input is -infinity.
logsumexp :: RealFloat a => [a] -> Either MathError a
logsumexp []=Right (-1/0)
logsumexp xs
    | any isNaN xs = Left (DomainError "logsumexp NaN input")
    | any (==1/0) xs = Right (1/0)
    | m == -1/0 = Right m
    | otherwise = Right (m+log (neumaierSum (map (\x -> exp (x-m)) xs)))
  where m=maximum xs
-- | Conservative sequential sum bound gamma_(n-1) * sum abs x. Returns infinity
-- when n*u >= 1 or finite inputs overflow the bound. Does not claim bounds in
-- the presence of underflow; an extra (n-1)*minimumSubnormal term covers it.
sumErrorBound :: RealFloat a => [a] -> Either MathError a
sumErrorBound xs
    | any (\x -> isNaN x || isInfinite x) xs = Left (DomainError "non-finite summation input")
    | null xs = Right 0
    | otherwise = let lim=numericLimits (sum xs); n=toInteger (length xs-1)
                      u=toRational (machineEpsilon lim)/2; nu=fromInteger n*u
                      absoluteSum=sum (map (abs . toRational) xs)
                      exactBound=nu/(1-nu)*absoluteSum+fromInteger n*toRational (minimumSubnormal lim)
                      rounded=fromRational exactBound
                  in Right (if nu >= 1 || isInfinite rounded then 1/0
                            else if toRational rounded < exactBound then nextAfter rounded (1/0) else rounded)
