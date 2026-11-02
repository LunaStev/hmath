{-# LANGUAGE GADTs #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Shared lossless value/ownership representation, not a mathematical engine.
module HMath.FFI.Value where
import Control.Exception (bracketOnError, evaluate, throwIO)
import Data.Coerce (coerce)
import Data.Char (chr, ord)
import Data.Complex (Complex ((:+)), imagPart, realPart)
import Data.Ratio ((%), numerator, denominator)
import Data.Proxy (Proxy (..))
import Data.Typeable (Typeable, cast)
import Foreign
import Foreign.C
import HMath.FFI.Coefficient
import HMath.FFI.Boundary
import HMath.FFI.MathError (CallbackFailure (..))
import qualified HMath.Matrix as M

data SomeMatrix where
    SomeMatrix :: Coefficient a => ScalarType a -> M.Matrix a -> SomeMatrix
    StructuralMatrix :: Typeable a => Int -> (a -> IO Value) -> (Value -> IO a) -> (a -> IO ()) -> M.Matrix a -> SomeMatrix

booleanMatrix :: M.Matrix Bool -> Value
booleanMatrix = Dense . StructuralMatrix 16 (pure . Boolean) asBoolean (\x -> evaluate x >> pure ())
stringMatrix :: M.Matrix String -> Value
stringMatrix = Dense . StructuralMatrix 17 (pure . Text) asText (mapM_ evaluate)

-- Structural matrices do not pretend to have a Num instance. This accessor
-- exposes the original Matrix type while callers retain their own constraints.
asMatrix :: forall a. Typeable a => Value -> IO (M.Matrix a)
asMatrix (Dense (SomeMatrix _ matrix)) = maybe (invalid "Matrix element types differ") pure (cast matrix)
asMatrix (Dense (StructuralMatrix _ _ _ _ matrix)) = maybe (invalid "Matrix element types differ") pure (cast matrix)
asMatrix _ = invalid "expected Matrix value"


data Value where
    None :: Value
    Scalar :: Coefficient a => ScalarType a -> a -> Value
    Index :: Int -> Value
    Boolean :: Bool -> Value
    List :: [Value] -> Value
    Tuple :: [Value] -> Value
    Dense :: SomeMatrix -> Value
    Text :: String -> Value
    Opaque :: Typeable a => Int -> Int -> Int -> IO () -> a -> Value

valueInfo :: Value -> (Int,Int,Int)
valueInfo value = case value of
    None -> (0,-1,0)
    Scalar witness _ -> (1,scalarTypeCode witness,0)
    Index _ -> (2,-1,0)
    Boolean _ -> (3,-1,0)
    List values -> (4,-1,length values)
    Tuple values -> (5,-1,length values)
    Dense (SomeMatrix witness matrix) -> (9,scalarTypeCode witness,length (M.toList matrix))
    Dense (StructuralMatrix dtype _ _ _ matrix) -> (9,dtype,length (M.toList matrix))
    Text text -> (10,-1,length text)
    Opaque kind dtype count _ _ -> (kind,dtype,count)

forceValue :: Value -> IO ()
forceValue value = case value of
    None -> pure ()
    Scalar _ x -> forceCoefficient x
    Index x -> evaluate x >> pure ()
    Boolean x -> evaluate x >> pure ()
    List xs -> mapM_ forceValue xs
    Tuple xs -> mapM_ forceValue xs
    Dense (SomeMatrix _ matrix) -> mapM_ forceCoefficient (M.toList matrix)
    Dense (StructuralMatrix _ _ _ force matrix) -> mapM_ force (M.toList matrix)
    Text text -> mapM_ evaluate text
    Opaque _ _ count force _ -> evaluate count >> force

publish :: Value -> Ptr (StablePtr Value) -> IO ()
publish value out = forceValue value >> bracketOnError (newStablePtr value) freeStablePtr (poke out)
invalid :: String -> IO a
invalid = throwIO . CallbackFailure 1
unsupported :: String -> IO a
unsupported = throwIO . CallbackFailure 10
asScalar :: forall a. Coefficient a => Value -> IO a
asScalar (Scalar _ value) = maybe (invalid "coefficient types differ") pure (cast value)
asScalar _ = invalid "expected a scalar coefficient"
asIndex :: Value -> IO Int
asIndex (Index n) = pure n
asIndex (Scalar (_ :: ScalarType a) value) = case integralDict (Proxy :: Proxy a) of
    Just Dict -> let n = toInteger value in
        if n >= toInteger (minBound :: Int) && n <= toInteger (maxBound :: Int)
            then pure (fromInteger n)
            else throwIO (CallbackFailure 3 "integral scalar is outside the Haskell Int representation")
    Nothing -> invalid "expected an integral Haskell Int representation"
asIndex _ = invalid "expected a Haskell Int"
asList :: Value -> IO [Value]
asList (List xs) = pure xs
asList _ = invalid "expected a list value"
asTuple :: Int -> Value -> IO [Value]
asTuple count (Tuple xs) | length xs == count = pure xs
asTuple _ _ = invalid "tuple arity differs"

asBoolean :: Value -> IO Bool
asBoolean (Boolean value) = pure value
asBoolean _ = invalid "expected Boolean value"
asText :: Value -> IO String
asText (Text value) = pure value
asText _ = invalid "expected String value"
foreign export ccall "hm_value_text" textValue :: Ptr Word32 -> CSize -> Ptr (StablePtr Value) -> IO CInt
textValue :: Ptr Word32 -> CSize -> Ptr (StablePtr Value) -> IO CInt
textValue input count out = boundary $ do
    points <- peekArray (fromIntegral count) input
    checked (Right ()) $ \_ -> publish (Text (map (chr . fromIntegral) points)) out
foreign export ccall "hm_value_get_text" getText :: StablePtr Value -> Ptr Word32 -> IO CInt
getText :: StablePtr Value -> Ptr Word32 -> IO CInt
getText pointer out = boundary $ do
    value <- deRefStablePtr pointer >>= asText
    checked (Right ()) $ \_ -> pokeArray out (map (fromIntegral . ord) value)

foreign export ccall "hm_value_free" freeValue :: StablePtr Value -> IO ()
freeValue :: StablePtr Value -> IO ()
freeValue = freeStablePtr
foreign export ccall "hm_value_info" info :: StablePtr Value -> Ptr CInt -> Ptr CInt -> Ptr CSize -> IO CInt
info :: StablePtr Value -> Ptr CInt -> Ptr CInt -> Ptr CSize -> IO CInt
info pointer kind dtype count = boundary $ do
    value <- deRefStablePtr pointer
    let (k,t,n)=valueInfo value
    _ <- evaluate k >> evaluate t >> evaluate n
    checked (Right ()) $ \_ -> poke kind (fromIntegral k) >> poke dtype (fromIntegral t) >> poke count (fromIntegral n)
foreign export ccall "hm_value_sequence" sequenceValue :: CInt -> Ptr (StablePtr Value) -> CSize -> Ptr (StablePtr Value) -> IO CInt
sequenceValue :: CInt -> Ptr (StablePtr Value) -> CSize -> Ptr (StablePtr Value) -> IO CInt
sequenceValue tuple pointers count out = boundary $ do
    values <- peekArray (fromIntegral count) pointers >>= mapM deRefStablePtr
    checked (Right ()) $ \_ -> publish (if tuple==0 then List values else Tuple values) out
foreign export ccall "hm_value_item" item :: StablePtr Value -> CSize -> Ptr (StablePtr Value) -> IO CInt
item :: StablePtr Value -> CSize -> Ptr (StablePtr Value) -> IO CInt
item pointer index out = boundary $ do
    value <- deRefStablePtr pointer
    let xs = case value of List values -> values; Tuple values -> values; _ -> error "value item kind mismatch"
    checked (Right ()) $ \_ -> publish (xs !! fromIntegral index) out
foreign export ccall "hm_value_none" noneValue :: Ptr (StablePtr Value) -> IO CInt
noneValue :: Ptr (StablePtr Value) -> IO CInt
noneValue out = boundary $ checked (Right ()) $ \_ -> publish None out
foreign export ccall "hm_value_boolean" booleanValue :: CInt -> Ptr (StablePtr Value) -> IO CInt
booleanValue :: CInt -> Ptr (StablePtr Value) -> IO CInt
booleanValue value out = boundary $ checked (Right ()) $ \_ -> publish (Boolean (value/=0)) out
foreign export ccall "hm_value_index" indexValue :: CPtrdiff -> Ptr (StablePtr Value) -> IO CInt
indexValue :: CPtrdiff -> Ptr (StablePtr Value) -> IO CInt
indexValue value out = boundary $ checked (Right ()) $ \_ -> publish (Index (fromIntegral value)) out
foreign export ccall "hm_value_get_index" getIndex :: StablePtr Value -> Ptr CPtrdiff -> IO CInt
getIndex :: StablePtr Value -> Ptr CPtrdiff -> IO CInt
getIndex pointer out = boundary $ do
    value <- deRefStablePtr pointer >>= asIndex
    checked (Right ()) $ \_ -> poke out (fromIntegral value)
foreign export ccall "hm_value_get_boolean" getBoolean :: StablePtr Value -> Ptr CInt -> IO CInt
getBoolean :: StablePtr Value -> Ptr CInt -> IO CInt
getBoolean pointer out = boundary $ do
    value <- deRefStablePtr pointer
    case value of
        Boolean result -> checked (Right ()) $ \_ -> poke out (if result then 1 else 0)
        _ -> invalid "expected Boolean value"
boundedInteger :: forall a. (Coefficient a, Integral a, Bounded a) => ScalarType a -> Integer -> IO Value
boundedInteger witness value
    | value < toInteger (minBound :: a) || value > toInteger (maxBound :: a) =
        throwIO (CallbackFailure 3 "coefficient exceeds its bounded integral representation")
    | otherwise = pure (Scalar witness (fromInteger value))

foreign export ccall "hm_value_exact" exact :: CInt -> CString -> CString -> Ptr (StablePtr Value) -> IO CInt
exact :: CInt -> CString -> CString -> Ptr (StablePtr Value) -> IO CInt
exact dtype numeratorPointer denominatorPointer out = boundary $ do
    n <- readInteger numeratorPointer
    if dtype==3 then do
        d <- readInteger denominatorPointer
        if d==0 then invalid "zero Rational denominator" else checked (Right ()) $ \_ -> publish (Scalar SRational (n % d)) out
    else case dtype of
        2 -> checked (Right ()) $ \_ -> publish (Scalar SInteger n) out
        6 -> boundedInteger SInt8 n >>= \value -> checked (Right ()) $ \_ -> publish value out
        7 -> boundedInteger SInt16 n >>= \value -> checked (Right ()) $ \_ -> publish value out
        8 -> boundedInteger SInt32 n >>= \value -> checked (Right ()) $ \_ -> publish value out
        9 -> boundedInteger SInt64 n >>= \value -> checked (Right ()) $ \_ -> publish value out
        10 -> boundedInteger SWord8 n >>= \value -> checked (Right ()) $ \_ -> publish value out
        11 -> boundedInteger SWord16 n >>= \value -> checked (Right ()) $ \_ -> publish value out
        12 -> boundedInteger SWord32 n >>= \value -> checked (Right ()) $ \_ -> publish value out
        13 -> boundedInteger SWord64 n >>= \value -> checked (Right ()) $ \_ -> publish value out
        14 -> boundedInteger SInt n >>= \value -> checked (Right ()) $ \_ -> publish value out
        15 -> boundedInteger SWord n >>= \value -> checked (Right ()) $ \_ -> publish value out
        _ -> invalid "exact scalar type not implemented"
foreign export ccall "hm_value_get_exact" getExact :: StablePtr Value -> Ptr CString -> Ptr CString -> IO CInt
getExact :: StablePtr Value -> Ptr CString -> Ptr CString -> IO CInt
getExact pointer numeratorOut denominatorOut = boundary $ do
    value <- deRefStablePtr pointer
    case value of
        Scalar SInteger n -> checked (Right ()) $ \_ -> writeStrings [show n,"1"] $ \xs -> poke numeratorOut (xs!!0) >> poke denominatorOut (xs!!1)
        Scalar SRational n -> checked (Right ()) $ \_ -> writeStrings [show (numerator n),show (denominator n)] $ \xs -> poke numeratorOut (xs!!0) >> poke denominatorOut (xs!!1)
        Scalar (_ :: ScalarType a) n -> case integralDict (Proxy :: Proxy a) of
            Just Dict -> checked (Right ()) $ \_ -> writeStrings [show (toInteger n),"1"] $ \xs -> poke numeratorOut (xs!!0) >> poke denominatorOut (xs!!1)
            Nothing -> invalid "expected integral/Rational scalar"
        _ -> invalid "expected integral/Rational scalar"

foreign export ccall "hm_value_real_f32" real32 :: CFloat -> CFloat -> CInt -> Ptr (StablePtr Value) -> IO CInt
real32 :: CFloat -> CFloat -> CInt -> Ptr (StablePtr Value) -> IO CInt
real32 real imaginary complex out = boundary $ checked (Right ()) $ \_ ->
    if complex==0 then publish (Scalar SFloat (coerce real :: Float)) out
    else publish (Scalar SComplexFloat ((coerce real :: Float) :+ coerce imaginary)) out
foreign export ccall "hm_value_get_real_f32" getReal32 :: StablePtr Value -> Ptr CFloat -> Ptr CFloat -> IO CInt
getReal32 :: StablePtr Value -> Ptr CFloat -> Ptr CFloat -> IO CInt
getReal32 pointer realOut imaginaryOut = boundary $ do
    value <- deRefStablePtr pointer
    case value of
        Scalar SFloat real -> checked (Right ()) $ \_ -> poke realOut (coerce real) >> poke imaginaryOut 0
        Scalar SComplexFloat z -> checked (Right ()) $ \_ -> poke realOut (coerce (realPart z)) >> poke imaginaryOut (coerce (imagPart z))
        _ -> invalid "coefficient type differs from typed accessor"

foreign export ccall "hm_value_real_f64" real64 :: CDouble -> CDouble -> CInt -> Ptr (StablePtr Value) -> IO CInt
real64 :: CDouble -> CDouble -> CInt -> Ptr (StablePtr Value) -> IO CInt
real64 real imaginary complex out = boundary $ checked (Right ()) $ \_ ->
    if complex==0 then publish (Scalar SDouble (coerce real :: Double)) out
    else publish (Scalar SComplexDouble ((coerce real :: Double) :+ coerce imaginary)) out
foreign export ccall "hm_value_get_real_f64" getReal64 :: StablePtr Value -> Ptr CDouble -> Ptr CDouble -> IO CInt
getReal64 :: StablePtr Value -> Ptr CDouble -> Ptr CDouble -> IO CInt
getReal64 pointer realOut imaginaryOut = boundary $ do
    value <- deRefStablePtr pointer
    case value of
        Scalar SDouble real -> checked (Right ()) $ \_ -> poke realOut (coerce real) >> poke imaginaryOut 0
        Scalar SComplexDouble z -> checked (Right ()) $ \_ -> poke realOut (coerce (realPart z)) >> poke imaginaryOut (coerce (imagPart z))
        _ -> invalid "coefficient type differs from typed accessor"
