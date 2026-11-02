{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Typed opaque storage. Numerical operations call HMath.Numeric directly.
module HMath.FFI.NumericTypes.Core where

import Control.Exception (Exception, bracket, catch, evaluate, throw, throwIO)
import Data.Char (chr)
import Data.Proxy (Proxy (..))
import Data.Typeable (cast, typeOf)
import Foreign
import Foreign.C
import System.IO.Unsafe (unsafePerformIO)
import HMath.Error (MathError)
import HMath.FFI.Boundary (boundary, checked)
import HMath.FFI.Coefficient
import qualified HMath.FFI.Value as V
import qualified HMath.Numeric as N
import qualified HMath.Constants as K

-- Generic records carry their original Haskell record constructors with boxed
-- fields; fields are representation adapters, never converted through Double.
data Object
    = Scalar SomeCoefficient
    | Half N.Float16
    | BHalf N.BFloat16
    | Big N.BigFloat
    | Fixed N.Fixed
    | Decimal N.Decimal
    | Interval N.Interval
    | Rounded (N.Rounded Object)
    | Limits (N.NumericLimits Object)
    | Constant K.Constant
    | Sequence Bool String [Object]
    | Class N.IEEEClass
    | Flag N.NumericException
    | Boolean Bool
    | Text String
    | QuaternionData SomeQuaternion
    | DualQuaternionData SomeDualQuaternion
    | Raw V.Value

data SomeQuaternion where
    SomeQuaternion :: Coefficient a => ScalarType a -> N.Quaternion a -> SomeQuaternion
data SomeDualQuaternion where
    SomeDualQuaternion :: Coefficient a => ScalarType a -> N.DualQuaternion a -> SomeDualQuaternion

data BindingError = BindingError CInt String deriving (Show)
instance Exception BindingError
data CallbackStatus = CallbackStatus CInt deriving (Show)
instance Exception CallbackStatus
foreign import ccall unsafe "hm_error" setError :: CInt -> CString -> IO CInt

numericBoundary :: IO CInt -> IO CInt
numericBoundary action = boundary $
    (action `catch` (\(BindingError code message) -> withCString message (setError code)))
        `catch` (\(CallbackStatus code) -> pure code)
bad :: String -> IO a
bad = throwIO . BindingError 1
unsupported :: String -> IO a
unsupported = throwIO . BindingError 10

scalar :: Coefficient a => ScalarType a -> a -> Object
scalar witness value = Scalar (SomeCoefficient witness value)
nint :: Int -> Object
nint = scalar SInt
ninteger :: Integer -> Object
ninteger = scalar SInteger
nrational :: Rational -> Object
nrational = scalar SRational
nfloat :: Float -> Object
nfloat = scalar SFloat
ndouble :: Double -> Object
ndouble = scalar SDouble

getScalar :: Object -> IO SomeCoefficient
getScalar (Scalar value) = pure value
getScalar (QuaternionData (SomeQuaternion witness (value :: N.Quaternion a))) =
    case realFloatDict (Proxy :: Proxy a) of
        Just Dict -> pure (SomeCoefficient (SQuaternion witness) value)
        Nothing -> unsupported "Quaternion Num requires a RealFloat component type"
getScalar _ = bad "expected a numeric coefficient"
getAs :: forall a. Coefficient a => Object -> IO a
getAs object = do
    SomeCoefficient _ value <- getScalar object
    maybe (bad "coefficient types differ") pure (cast value)
getRational :: Object -> IO Rational
getRational = getAs
getBig :: Object -> IO N.BigFloat
getBig (Big value) = pure value
getBig _ = bad "expected BigFloat"
getFixed :: Object -> IO N.Fixed
getFixed (Fixed value) = pure value
getFixed _ = bad "expected Fixed"
getDecimal :: Object -> IO N.Decimal
getDecimal (Decimal value) = pure value
getDecimal _ = bad "expected Decimal"
getInterval :: Object -> IO N.Interval
getInterval (Interval value) = pure value
getInterval _ = bad "expected Interval"
getConstant :: Object -> IO K.Constant
getConstant (Constant value) = pure value
getConstant _ = bad "expected Constant"
getText :: Object -> IO String
getText (Text value) = pure value
getText _ = bad "expected text"
getSequence :: Object -> IO [Object]
getSequence (Sequence _ _ values) = pure values
getSequence _ = bad "expected sequence"
getQuaternion :: Object -> IO SomeQuaternion
getQuaternion (QuaternionData value) = pure value
getQuaternion (Scalar (SomeCoefficient (SQuaternion witness) value)) = pure (SomeQuaternion witness value)
getQuaternion _ = bad "expected Quaternion"
getDualQuaternion :: Object -> IO SomeDualQuaternion
getDualQuaternion (DualQuaternionData value) = pure value
getDualQuaternion _ = bad "expected DualQuaternion"

forceObject :: Object -> IO ()
forceObject object = case object of
    Raw value -> V.forceValue value
    Scalar (SomeCoefficient _ value) -> forceCoefficient value
    Half value -> evaluate (N.float16Bits value) >> pure ()
    BHalf value -> evaluate (N.bfloat16Bits value) >> pure ()
    Big value -> evaluate (N.bigPrecision value) >> forceCoefficient (N.bigRational value)
    Fixed value -> evaluate (N.fixedScale value) >> evaluate (N.fixedCoefficient value) >> pure ()
    Decimal value -> forceCoefficient (N.decimalRational value)
    Interval value -> let (a,b)=N.intervalBounds value in evaluate a >> evaluate b >> pure ()
    Rounded value -> forceObject (N.roundedValue value) >> mapM_ evaluate (N.numericalExceptions value)
    Limits value -> mapM_ forceObject [N.minimumNormal value,N.minimumSubnormal value,N.maximumFinite value,N.machineEpsilon value] >> mapM_ evaluate [N.significandDigits value,N.minimumExponent value,N.maximumExponent value]
    Constant value -> mapM_ (evaluate . length) [K.constantName value,K.constantUnit value,K.constantSource value] >> mapM_ forceCoefficient [K.constantValue value,K.standardUncertainty value,K.approximationBound value]
    Sequence _ _ values -> mapM_ forceObject values
    Class value -> evaluate value >> pure ()
    Flag value -> evaluate value >> pure ()
    Boolean value -> evaluate value >> pure ()
    Text value -> evaluate (length value) >> pure ()
    QuaternionData (SomeQuaternion _ (N.Quaternion a b c d)) -> mapM_ forceCoefficient [a,b,c,d]
    DualQuaternionData (SomeDualQuaternion witness (N.DualQuaternion a b)) -> forceObject (QuaternionData (SomeQuaternion witness a)) >> forceObject (QuaternionData (SomeQuaternion witness b))

publish :: Object -> Ptr (Handle) -> IO ()
publish value out = V.publish (sharedObject value) out
rounded :: (a -> Object) -> N.Rounded a -> Object
rounded wrap value = Rounded (N.Rounded (wrap (N.roundedValue value)) (N.numericalExceptions value))
limits :: Coefficient a => ScalarType a -> N.NumericLimits a -> Object
limits witness value = Limits (N.NumericLimits (scalar witness (N.minimumNormal value)) (scalar witness (N.minimumSubnormal value)) (scalar witness (N.maximumFinite value)) (scalar witness (N.machineEpsilon value)) (N.significandDigits value) (N.minimumExponent value) (N.maximumExponent value))

roundingMode :: CInt -> IO N.RoundingMode
roundingMode value = case value of
    0 -> pure N.NearestEven
    1 -> pure N.TowardZero
    2 -> pure N.TowardPositive
    3 -> pure N.TowardNegative
    _ -> bad "invalid RoundingMode"
exception :: CInt -> IO N.NumericException
exception value = case value of
    0 -> pure N.InvalidOperation
    1 -> pure N.DivisionByZero
    2 -> pure N.NumericOverflow
    3 -> pure N.NumericUnderflow
    4 -> pure N.Inexact
    _ -> bad "invalid NumericException"
exceptionCode :: N.NumericException -> CInt
exceptionCode value = case value of N.InvalidOperation -> 0; N.DivisionByZero -> 1; N.NumericOverflow -> 2; N.NumericUnderflow -> 3; N.Inexact -> 4
classCode :: N.IEEEClass -> CInt
classCode value = case value of N.NotANumber -> 0; N.PositiveInfinity -> 1; N.NegativeInfinity -> 2; N.PositiveZero -> 3; N.NegativeZero -> 4; N.Subnormal -> 5; N.Normal -> 6

foreign export ccall "hm_numeric_types_free" release :: Handle -> IO ()
release :: Handle -> IO ()
release = freeStablePtr
foreign export ccall "hm_numeric_types_clone" clone :: Handle -> Ptr (Handle) -> IO CInt
clone :: Handle -> Ptr (Handle) -> IO CInt
clone pointer out = numericBoundary $ dereference pointer >>= \value -> checked (Right value) (`publish` out)

scalarCode :: Object -> IO Int
scalarCode object = do SomeCoefficient witness _ <- getScalar object; pure (scalarTypeCode witness)
objectType :: Object -> String
objectType object = case object of
    Raw value -> let (kind,dtype,_) = V.valueInfo value in "Value " ++ show kind ++ ":" ++ show dtype
    Scalar (SomeCoefficient _ value) -> show (typeOf value)
    QuaternionData (SomeQuaternion _ value) -> show (typeOf value)
    DualQuaternionData (SomeDualQuaternion _ value) -> show (typeOf value)
    Half _ -> "Float16"; BHalf _ -> "BFloat16"; Big _ -> "BigFloat"; Fixed _ -> "Fixed"; Decimal _ -> "Decimal"; Interval _ -> "Interval"
    Rounded value -> "Rounded (" ++ objectType (N.roundedValue value) ++ ")"
    Limits value -> "NumericLimits (" ++ objectType (N.minimumNormal value) ++ ")"
    Constant _ -> "Constant"
    Sequence tuple element _ -> (if tuple then "Tuple " else "List ") ++ element
    Class _ -> "IEEEClass"; Flag _ -> "NumericException"; Boolean _ -> "Bool"; Text _ -> "String"

-- Original numeric instance operations, including recursive Numeric.Dual.
binary :: CInt -> Object -> Object -> IO Object
binary operation first second = do
    SomeCoefficient witness (a :: a) <- getScalar first
    b <- getAs second :: IO a
    case operation of
        0 -> pure (scalar witness (a+b))
        1 -> pure (scalar witness (a-b))
        2 -> pure (scalar witness (a*b))
        3 -> case fractionalDict (Proxy :: Proxy a) of Just Dict -> pure (scalar witness (a/b)); Nothing -> unsupported "Fractional instance unavailable"
        4 -> case floatingDict (Proxy :: Proxy a) of Just Dict -> pure (scalar witness (a**b)); Nothing -> unsupported "Floating instance unavailable"
        _ -> bad "invalid numeric binary operation"
unary :: CInt -> Object -> IO Object
unary operation first = do
    SomeCoefficient witness (a :: a) <- getScalar first
    case operation of
        0 -> pure (scalar witness (negate a))
        1 -> pure (scalar witness (abs a))
        2 -> pure (scalar witness (signum a))
        3 -> case fractionalDict (Proxy :: Proxy a) of Just Dict -> pure (scalar witness (recip a)); Nothing -> unsupported "Fractional instance unavailable"
        _ -> case floatingDict (Proxy :: Proxy a) of
            Nothing -> unsupported "Floating instance unavailable"
            Just Dict -> case operation of
                4 -> pure (scalar witness (exp a)); 5 -> pure (scalar witness (log a)); 6 -> pure (scalar witness (sqrt a)); 7 -> pure (scalar witness (sin a)); 8 -> pure (scalar witness (cos a)); 9 -> pure (scalar witness (tan a)); 10 -> pure (scalar witness (asin a)); 11 -> pure (scalar witness (acos a)); 12 -> pure (scalar witness (atan a)); 13 -> pure (scalar witness (sinh a)); 14 -> pure (scalar witness (cosh a)); 15 -> pure (scalar witness (tanh a)); 16 -> pure (scalar witness (asinh a)); 17 -> pure (scalar witness (acosh a)); 18 -> pure (scalar witness (atanh a)); _ -> bad "invalid numeric unary operation"

makeDual :: Object -> Object -> IO Object
makeDual first second = do
    SomeCoefficient witness (a :: a) <- getScalar first
    b <- getAs second :: IO a
    pure (scalar (SDual witness) (N.Dual a b))
primal :: Object -> IO Object
primal (Scalar (SomeCoefficient (SDual witness) value)) = case coefficientDict witness of Dict -> pure (scalar witness (N.primal value))
primal _ = bad "expected Numeric.Dual"
tangent :: Object -> IO Object
tangent (Scalar (SomeCoefficient (SDual witness) value)) = case coefficientDict witness of Dict -> pure (scalar witness (N.tangent value))
tangent _ = bad "expected Numeric.Dual"

getQuaternionAs :: forall a. Coefficient a => Object -> IO (N.Quaternion a)
getQuaternionAs object = do SomeQuaternion _ value <- getQuaternion object; maybe (bad "Quaternion component types differ") pure (cast value)
getDualQuaternionAs :: forall a. Coefficient a => Object -> IO (N.DualQuaternion a)
getDualQuaternionAs object = do SomeDualQuaternion _ value <- getDualQuaternion object; maybe (bad "DualQuaternion component types differ") pure (cast value)
makeQuaternion :: Object -> Object -> Object -> Object -> IO Object
makeQuaternion first second third fourth = do
    SomeCoefficient witness (a :: a) <- getScalar first
    b <- getAs second :: IO a; c <- getAs third; d <- getAs fourth
    pure (QuaternionData (SomeQuaternion witness (N.Quaternion a b c d)))
makeDualQuaternion :: Object -> Object -> IO Object
makeDualQuaternion first second = do
    SomeQuaternion witness (a :: N.Quaternion a) <- getQuaternion first
    b <- getQuaternionAs second :: IO (N.Quaternion a)
    pure (DualQuaternionData (SomeDualQuaternion witness (N.DualQuaternion a b)))
quaternionConjugate :: Object -> IO Object
quaternionConjugate object = do SomeQuaternion witness value <- getQuaternion object; pure (QuaternionData (SomeQuaternion witness (N.quaternionConjugate value)))
quaternionNorm :: Object -> IO Object
quaternionNorm object = do
    SomeQuaternion witness (value :: N.Quaternion a) <- getQuaternion object
    case realFloatDict (Proxy :: Proxy a) of Just Dict -> pure (scalar witness (N.quaternionNorm value)); Nothing -> unsupported "RealFloat Quaternion component required"
quaternionInverse :: Object -> IO (Either MathError Object)
quaternionInverse object = do
    SomeQuaternion witness (value :: N.Quaternion a) <- getQuaternion object
    case realFloatDict (Proxy :: Proxy a) of Just Dict -> pure (QuaternionData . SomeQuaternion witness <$> N.quaternionInverse value); Nothing -> unsupported "RealFloat Quaternion component required"
quaternionComponent :: CPtrdiff -> Object -> IO Object
quaternionComponent index object = do
    SomeQuaternion witness (N.Quaternion a b c d) <- getQuaternion object
    case index of 0 -> pure (scalar witness a); 1 -> pure (scalar witness b); 2 -> pure (scalar witness c); 3 -> pure (scalar witness d); _ -> bad "Quaternion component index"
dualQuaternionComponent :: CPtrdiff -> Object -> IO Object
dualQuaternionComponent index object = do
    SomeDualQuaternion witness (N.DualQuaternion a b) <- getDualQuaternion object
    case index of 0 -> pure (QuaternionData (SomeQuaternion witness a)); 1 -> pure (QuaternionData (SomeQuaternion witness b)); _ -> bad "DualQuaternion component index"

makeLimits :: Object -> Object -> Object -> Object -> CPtrdiff -> CPtrdiff -> CPtrdiff -> IO Object
makeLimits a b c d digits lo hi = do
    if any ((/= objectType a) . objectType) [b,c,d] then bad "NumericLimits field types differ" else pure ()
    pure (Limits (N.NumericLimits a b c d (fromIntegral digits) (fromIntegral lo) (fromIntegral hi)))
numericLimits :: Object -> IO Object
numericLimits object = do
    SomeCoefficient witness (value :: a) <- getScalar object
    case realFloatDict (Proxy :: Proxy a) of Just Dict -> pure (limits witness (N.numericLimits value)); Nothing -> unsupported "RealFloat witness required"

readText :: Ptr Word32 -> CSize -> IO Object
readText dataPointer count = Text . map (chr . fromIntegral) <$> peekArray (fromIntegral count) dataPointer

boundedCast :: Bool -> CInt -> Object -> IO (Either MathError Object)
boundedCast saturate target object = do
    SomeCoefficient _ (value :: a) <- getScalar object
    case integralDict (Proxy :: Proxy a) of
        Nothing -> unsupported "Integral source required"
        Just Dict -> boundedDestination target $ \witness ->
            pure $ if saturate then Right (scalar witness (N.saturatingCast value)) else scalar witness <$> N.safeIntegralCast value

boundedDestination :: CInt -> (forall a. (Coefficient a, Integral a, Bounded a) => ScalarType a -> IO r) -> IO r
boundedDestination target action = case target of
    6 -> action SInt8; 7 -> action SInt16; 8 -> action SInt32; 9 -> action SInt64
    10 -> action SWord8; 11 -> action SWord16; 12 -> action SWord32; 13 -> action SWord64
    14 -> action SInt; 15 -> action SWord
    _ -> bad "bounded integral destination dtype required"

realToIntegral :: N.RoundingMode -> CInt -> Object -> IO (Either MathError Object)
realToIntegral mode target object = do
    SomeCoefficient _ (value :: a) <- getScalar object
    case realFloatDict (Proxy :: Proxy a) of
        Nothing -> unsupported "RealFloat source required"
        Just Dict -> boundedDestination target $ \witness -> pure (scalar witness <$> N.realToIntegral mode value)

narrowFloat :: CInt -> Object -> IO (Either MathError Object)
narrowFloat target object = do
    SomeCoefficient _ (value :: a) <- getScalar object
    case realFloatDict (Proxy :: Proxy a) of
        Nothing -> unsupported "RealFloat source required"
        Just Dict -> case target of
            0 -> pure (ndouble <$> N.narrowFloat value)
            1 -> pure (nfloat <$> N.narrowFloat value)
            _ -> bad "Float or Double destination required"

classify :: Object -> IO Object
classify object = do
    SomeCoefficient _ (value :: a) <- getScalar object
    case realFloatDict (Proxy :: Proxy a) of
        Just Dict -> pure (Class (N.classify value))
        Nothing -> unsupported "RealFloat value required"
frexp :: Object -> IO Object
frexp object = do
    SomeCoefficient witness (value :: a) <- getScalar object
    case realFloatDict (Proxy :: Proxy a) of
        Just Dict -> let (mantissa,power)=N.frexp value in pure (Sequence True "" [scalar witness mantissa,nint power])
        Nothing -> unsupported "RealFloat value required"
integerLimits :: Object -> IO Object
integerLimits object = do
    SomeCoefficient _ (value :: a) <- getScalar object
    case (integralDict (Proxy :: Proxy a), boundedDict (Proxy :: Proxy a)) of
        (Just Dict,Just Dict) -> let (lo,hi)=N.integerLimits value in pure (Sequence True "" [ninteger lo,ninteger hi])
        _ -> unsupported "Bounded Integral witness required"

makeRounded :: Object -> [N.NumericException] -> Object
makeRounded value flags = Rounded (N.Rounded value flags)
roundedValue :: Object -> IO Object
roundedValue (Rounded value) = pure (N.roundedValue value)
roundedValue _ = bad "expected Rounded"
numericalExceptions :: Object -> IO Object
numericalExceptions (Rounded value) = pure (Sequence False "NumericException" (map Flag (N.numericalExceptions value)))
numericalExceptions _ = bad "expected Rounded"
limitsField :: CInt -> Object -> IO Object
limitsField field (Limits value) = case field of
    0 -> pure (N.minimumNormal value); 1 -> pure (N.minimumSubnormal value); 2 -> pure (N.maximumFinite value); 3 -> pure (N.machineEpsilon value)
    4 -> pure (nint (N.significandDigits value)); 5 -> pure (nint (N.minimumExponent value)); 6 -> pure (nint (N.maximumExponent value)); _ -> bad "invalid NumericLimits field"
limitsField _ _ = bad "expected NumericLimits"

constantAs :: CInt -> Object -> IO Object
constantAs target object = do
    value <- getConstant object
    case target of
        0 -> pure (ndouble (K.constantAs value))
        1 -> pure (nfloat (K.constantAs value))
        3 -> pure (nrational (K.constantAs value))
        4 -> pure (scalar SComplexDouble (K.constantAs value))
        5 -> pure (scalar SComplexFloat (K.constantAs value))
        _ -> bad "constantAs requires a supported Fractional dtype"

constantAsLike :: Object -> Object -> IO Object
constantAsLike prototype object = do
    value <- getConstant object
    SomeCoefficient witness (_ :: a) <- getScalar prototype
    case fractionalDict (Proxy :: Proxy a) of
        Just Dict -> pure (scalar witness (K.constantAs value :: a))
        Nothing -> unsupported "constantAs requires a Fractional prototype"

getVector :: forall a. Coefficient a => Object -> Object -> Object -> IO (a,a,a)
getVector x y z = (,,) <$> getAs x <*> getAs y <*> getAs z
vectorObject :: Coefficient a => ScalarType a -> (a,a,a) -> Object
vectorObject witness (x,y,z) = Sequence True "" [scalar witness x,scalar witness y,scalar witness z]
rotateVector :: Object -> Object -> Object -> Object -> IO (Either MathError Object)
rotateVector object x y z = do
    SomeQuaternion witness (value :: N.Quaternion a) <- getQuaternion object
    case realFloatDict (Proxy :: Proxy a) of
        Just Dict -> do vector <- getVector x y z :: IO (a,a,a); pure (vectorObject witness <$> N.rotateVector value vector)
        Nothing -> unsupported "RealFloat Quaternion component required"
rigidTransform :: Object -> Object -> Object -> Object -> IO (Either MathError Object)
rigidTransform object x y z = do
    SomeQuaternion witness (value :: N.Quaternion a) <- getQuaternion object
    case realFloatDict (Proxy :: Proxy a) of
        Just Dict -> do vector <- getVector x y z :: IO (a,a,a); pure (DualQuaternionData . SomeDualQuaternion witness <$> N.rigidTransform value vector)
        Nothing -> unsupported "RealFloat Quaternion component required"
transformPoint :: Object -> Object -> Object -> Object -> IO (Either MathError Object)
transformPoint object x y z = do
    SomeDualQuaternion witness (value :: N.DualQuaternion a) <- getDualQuaternion object
    case realFloatDict (Proxy :: Proxy a) of
        Just Dict -> do vector <- getVector x y z :: IO (a,a,a); pure (vectorObject witness <$> N.transformPoint value vector)
        Nothing -> unsupported "RealFloat DualQuaternion component required"
dualQuaternionMultiply :: Object -> Object -> IO Object
dualQuaternionMultiply first second = do
    SomeDualQuaternion witness (value :: N.DualQuaternion a) <- getDualQuaternion first
    other <- getDualQuaternionAs second :: IO (N.DualQuaternion a)
    case realFloatDict (Proxy :: Proxy a) of
        Just Dict -> pure (DualQuaternionData (SomeDualQuaternion witness (N.dualQuaternionMultiply value other)))
        Nothing -> unsupported "RealFloat DualQuaternion component required"
dualQuaternionInverse :: Object -> IO (Either MathError Object)
dualQuaternionInverse object = do
    SomeDualQuaternion witness (value :: N.DualQuaternion a) <- getDualQuaternion object
    case realFloatDict (Proxy :: Proxy a) of
        Just Dict -> pure (DualQuaternionData . SomeDualQuaternion witness <$> N.dualQuaternionInverse value)
        Nothing -> unsupported "RealFloat DualQuaternion component required"

literalInteger :: Object -> Integer -> IO Object
literalInteger object integer = do SomeCoefficient witness (_ :: a) <- getScalar object; pure (scalar witness (fromInteger integer :: a))
literalRational :: Object -> Rational -> IO Object
literalRational object rational = do
    SomeCoefficient witness (_ :: a) <- getScalar object
    case fractionalDict (Proxy :: Proxy a) of Just Dict -> pure (scalar witness (fromRational rational :: a)); Nothing -> unsupported "Fractional instance unavailable"

integerPower :: Object -> Integer -> IO Object
integerPower object power = do
    SomeCoefficient witness (value :: a) <- getScalar object
    if power >= 0 then pure (scalar witness (value ^ power)) else
        case fractionalDict (Proxy :: Proxy a) of
            Just Dict -> pure (scalar witness (value ^^ power))
            Nothing -> unsupported "negative exponent requires a Fractional instance"

sequenceItem :: CPtrdiff -> Object -> IO Object
sequenceItem index (Sequence _ _ values)
    | index < 0 || toInteger index >= toInteger (length values) = throwIO (BindingError 8 "sequence index out of bounds")
    | otherwise = pure (values !! fromIntegral index)
sequenceItem _ _ = bad "expected sequence"

makeConstant :: Object -> Object -> Object -> Object -> Object -> Object -> IO Object
makeConstant name value uncertainty approximation unit source = do
    name' <- getText name; value' <- getRational value
    uncertainty' <- getRational uncertainty; approximation' <- getRational approximation
    unit' <- getText unit; source' <- getText source
    pure (Constant (K.Constant name' value' uncertainty' approximation' unit' source'))
constantField :: CInt -> Object -> IO Object
constantField field object = do
    value <- getConstant object
    case field of
        0 -> pure (Text (K.constantName value)); 1 -> pure (nrational (K.constantValue value))
        2 -> pure (nrational (K.standardUncertainty value)); 3 -> pure (nrational (K.approximationBound value))
        4 -> pure (Text (K.constantUnit value)); 5 -> pure (Text (K.constantSource value))
        _ -> bad "invalid Constant field"

instance Eq Object where
    Scalar (SomeCoefficient _ a) == Scalar (SomeCoefficient _ b) = maybe False (a ==) (cast b)
    Half a == Half b = a == b
    BHalf a == BHalf b = a == b
    Big a == Big b = a == b
    Fixed a == Fixed b = a == b
    Decimal a == Decimal b = a == b
    Interval a == Interval b = a == b
    Rounded a == Rounded b = a == b
    Limits a == Limits b = a == b
    Constant a == Constant b = a == b
    Sequence tuple element a == Sequence tuple' element' b = tuple == tuple' && element == element' && a == b
    Class a == Class b = a == b
    Flag a == Flag b = a == b
    Boolean a == Boolean b = a == b
    Text a == Text b = a == b
    QuaternionData (SomeQuaternion _ a) == QuaternionData (SomeQuaternion _ b) = maybe False (a ==) (cast b)
    DualQuaternionData (SomeDualQuaternion _ a) == DualQuaternionData (SomeDualQuaternion _ b) = maybe False (a ==) (cast b)
    Raw V.None == Raw V.None = True
    Raw (V.Dense (V.SomeMatrix _ a)) == Raw (V.Dense (V.SomeMatrix _ b)) = maybe False (a ==) (cast b)
    Raw _ == Raw _ = throw (BindingError 10 "Eq dictionary unavailable for foreign opaque values")
    _ == _ = False

-- The callback runs only when the original Numeric.derivative evaluates its
-- supplied function. Its immutable argument/result are actual Numeric.Duals.
type NumericCallback = Ptr () -> Ptr () -> Ptr (Ptr ()) -> IO CInt
foreign import ccall safe "hm_numeric_types_invoke"
    invokeCallback :: FunPtr NumericCallback -> Ptr () -> Handle -> Ptr (Handle) -> IO CInt

callbackObject :: FunPtr NumericCallback -> Ptr () -> Object -> IO Object
callbackObject callback userdata input = do
    forceObject input
    pointer <- newStablePtr (sharedObject input)
    -- C consumes pointer on every path; on success it returns a new stable
    -- reference cloned before releasing the callback's transferred result.
    alloca $ \out -> do
        code <- invokeCallback callback userdata pointer out
        -- Preserve the callback's thread-local structured MathError payload.
        -- Reporting a new generic error here would erase that original record.
        if code /= 0 then throwIO (CallbackStatus code) else pure ()
        result <- peek out
        bracket (pure result) freeStablePtr dereference

derivative :: FunPtr NumericCallback -> Ptr () -> Object -> IO Object
derivative callback userdata object = do
    SomeCoefficient witness (value :: a) <- getScalar object
    let function dual = unsafePerformIO $ do
            result <- callbackObject callback userdata (scalar (SDual witness) dual)
            getAs result :: IO (N.Dual a)
    pure (scalar witness (N.derivative function value))
getHalf :: Object -> IO N.Float16
getHalf (Half value) = pure value
getHalf _ = bad "expected Float16"
getBHalf :: Object -> IO N.BFloat16
getBHalf (BHalf value) = pure value
getBHalf _ = bad "expected BFloat16"


type Handle = StablePtr V.Value

dereference :: Handle -> IO Object
dereference pointer = deRefStablePtr pointer >>= objectFromShared

objectFromShared :: V.Value -> IO Object
objectFromShared value = case value of
    V.Scalar witness number -> pure (scalar witness number)
    V.Index number -> pure (nint number)
    V.Boolean result -> pure (Boolean result)
    V.Text text -> pure (Text text)
    V.List values -> Sequence False "" <$> mapM objectFromShared values
    V.Tuple values -> Sequence True "" <$> mapM objectFromShared values
    V.Opaque kind _ _ _ payload | kind >= 40 && kind <= 59 -> maybe (bad "NumericTypes payload mismatch") pure (cast payload)
    _ -> pure (Raw value)

sharedObject :: Object -> V.Value
sharedObject object = case object of
    Raw value -> value
    Scalar (SomeCoefficient witness number) -> V.Scalar witness number
    Boolean result -> V.Boolean result
    Text text -> V.Text text
    Sequence tuple _ values -> (if tuple then V.Tuple else V.List) (map sharedObject values)
    QuaternionData (SomeQuaternion witness (value :: N.Quaternion a)) ->
        case realFloatDict (Proxy :: Proxy a) of
            Just Dict -> V.Scalar (SQuaternion witness) value
            Nothing -> opaque 52 object
    Half _ -> opaque 40 object
    BHalf _ -> opaque 41 object
    Big _ -> opaque 42 object
    Fixed _ -> opaque 43 object
    Decimal _ -> opaque 44 object
    Interval _ -> opaque 45 object
    Rounded _ -> opaque 46 object
    Limits _ -> opaque 47 object
    Constant _ -> opaque 48 object
    Class _ -> opaque 49 object
    Flag _ -> opaque 50 object
    DualQuaternionData _ -> opaque 53 object
  where
    opaque kind payload = V.Opaque kind (-1) 0 (forceObject payload) payload

foreign export ccall "hm_numeric_types_enum_value" enumValue :: Handle -> Ptr CInt -> IO CInt
enumValue :: Handle -> Ptr CInt -> IO CInt
enumValue pointer out = numericBoundary $ do
    object <- dereference pointer
    value <- case object of Class x -> pure (classCode x); Flag x -> pure (exceptionCode x); _ -> bad "expected IEEEClass or NumericException"
    checked (Right value) (poke out)

-- | Equality transport for generic Eq callers. Existing source records retain
-- their original Eq dictionaries; opaque generic fields recurse through the
-- caller's native value equality resolver, avoiding a dependency cycle.
equalValueWith :: (V.Value -> V.Value -> IO Bool) -> V.Value -> V.Value -> IO Bool
equalValueWith recurse left right = do
    a <- objectFromShared left
    b <- objectFromShared right
    equalObjectWith recurse a b

data EqualityObject = EqualityObject (Object -> Object -> IO Bool) Object
instance Eq EqualityObject where
    EqualityObject compareObject a == EqualityObject _ b = unsafePerformIO(compareObject a b)

equalObjectWith :: (V.Value -> V.Value -> IO Bool) -> Object -> Object -> IO Bool
equalObjectWith recurse left right = case(left,right)of
    (Scalar(SomeCoefficient _ a),Scalar(SomeCoefficient _ b)) -> maybe (V.invalid "numeric equality coefficient types differ") (pure . (a==)) (cast b)
    (Half a,Half b) -> pure(a==b)
    (BHalf a,BHalf b) -> pure(a==b)
    (Big a,Big b) -> pure(a==b)
    (Fixed a,Fixed b) -> pure(a==b)
    (Decimal a,Decimal b) -> pure(a==b)
    (Interval a,Interval b) -> pure(a==b)
    (Rounded a,Rounded b) -> pure(mapRounded a==mapRounded b)
    (Limits a,Limits b) -> pure(mapLimits a==mapLimits b)
    (Constant a,Constant b) -> pure(a==b)
    (Class a,Class b) -> pure(a==b)
    (Flag a,Flag b) -> pure(a==b)
    (Boolean a,Boolean b) -> pure(a==b)
    (Text a,Text b) -> pure(a==b)
    (Sequence tuple _ a,Sequence other _ b)
        | tuple==other -> pure(map field a==map field b)
        | otherwise -> V.invalid "numeric equality sequence types differ"
    (QuaternionData(SomeQuaternion _ a),QuaternionData(SomeQuaternion _ b)) -> maybe (V.invalid "numeric quaternion equality coefficient types differ") (pure . (a==)) (cast b)
    (DualQuaternionData(SomeDualQuaternion _ a),DualQuaternionData(SomeDualQuaternion _ b)) -> maybe (V.invalid "numeric dual-quaternion equality coefficient types differ") (pure . (a==)) (cast b)
    (Raw a,Raw b) -> recurse a b
    _ -> V.invalid "numeric equality source types differ"
  where
    field=EqualityObject(equalObjectWith recurse)
    mapRounded value=N.Rounded(field(N.roundedValue value))(N.numericalExceptions value)
    mapLimits value=N.NumericLimits(field(N.minimumNormal value))(field(N.minimumSubnormal value))(field(N.maximumFinite value))(field(N.machineEpsilon value))(N.significandDigits value)(N.minimumExponent value)(N.maximumExponent value)
