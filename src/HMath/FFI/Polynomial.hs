{-# LANGUAGE GADTs #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Representation adapters only; every mathematical operation calls the public source module.
module HMath.FFI.Polynomial where
import Control.Exception (throwIO)
import Data.Coerce (coerce)
import Data.Proxy (Proxy (..))
import Data.Typeable (cast)
import Foreign
import Foreign.C
import System.IO.Unsafe (unsafePerformIO)
import qualified HMath.Polynomial as P
import HMath.Error (MathError)
import HMath.FFI.Coefficient
import qualified HMath.FFI.Value as V
import qualified HMath.FFI.Boundary as B
import HMath.FFI.MathError

data SomePolynomial where
    SomePolynomial :: Coefficient a => ScalarType a -> P.Polynomial a -> SomePolynomial
data SomeSeries where
    SomeSeries :: Coefficient a => ScalarType a -> P.PowerSeries a -> SomeSeries

poly :: Coefficient a => ScalarType a -> P.Polynomial a -> V.Value
poly witness p = V.Opaque 6 (scalarTypeCode witness) (length (P.coefficients p)) (mapM_ forceCoefficient (P.coefficients p)) (SomePolynomial witness p)
series :: Coefficient a => ScalarType a -> P.PowerSeries a -> V.Value
series witness p = V.Opaque 7 (scalarTypeCode witness) (length (P.seriesCoefficients p)) (mapM_ forceCoefficient (P.seriesCoefficients p)) (SomeSeries witness p)
rationalFunction :: P.RationalFunction -> V.Value
rationalFunction f = V.Opaque 8 3 0 (V.forceValue (poly SRational (P.rationalNumerator f)) >> V.forceValue (poly SRational (P.rationalDenominator f))) f
withPolynomial :: V.Value -> (forall a. Coefficient a => ScalarType a -> P.Polynomial a -> IO V.Value) -> IO V.Value
withPolynomial (V.Opaque 6 _ _ _ payload) action = case cast payload of
    Just (SomePolynomial witness p) -> action witness p
    Nothing -> V.invalid "invalid Polynomial payload"
withPolynomial _ _ = V.invalid "expected Polynomial"
withSeries :: V.Value -> (forall a. Coefficient a => ScalarType a -> P.PowerSeries a -> IO V.Value) -> IO V.Value
withSeries (V.Opaque 7 _ _ _ payload) action = case cast payload of
    Just (SomeSeries witness p) -> action witness p
    Nothing -> V.invalid "invalid PowerSeries payload"
withSeries _ _ = V.invalid "expected PowerSeries"
asPolynomial :: forall a. Coefficient a => V.Value -> IO (P.Polynomial a)
asPolynomial (V.Opaque 6 _ _ _ payload) = case cast payload of
    Just (SomePolynomial _ p) -> maybe (V.invalid "Polynomial coefficient types differ") pure (cast p)
    Nothing -> V.invalid "invalid Polynomial payload"
asPolynomial _ = V.invalid "expected Polynomial"
asSeries :: forall a. Coefficient a => V.Value -> IO (P.PowerSeries a)
asSeries (V.Opaque 7 _ _ _ payload) = case cast payload of
    Just (SomeSeries _ p) -> maybe (V.invalid "PowerSeries coefficient types differ") pure (cast p)
    Nothing -> V.invalid "invalid PowerSeries payload"
asSeries _ = V.invalid "expected PowerSeries"
asRationalFunction :: V.Value -> IO P.RationalFunction
asRationalFunction (V.Opaque 8 _ _ _ payload) = maybe (V.invalid "invalid RationalFunction payload") pure (cast payload)
asRationalFunction _ = V.invalid "expected RationalFunction"
withWitness :: V.Value -> (forall a. Coefficient a => ScalarType a -> IO V.Value) -> IO V.Value
withWitness (V.Scalar witness _) action = action witness
withWitness _ _ = V.invalid "expected typed coefficient prototype"
scalars :: Coefficient a => V.Value -> IO [a]
scalars input = V.asList input >>= mapM V.asScalar
points :: Coefficient a => V.Value -> IO [(a,a)]
points input = V.asList input >>= mapM (\v -> do
    pair <- V.asTuple 2 v
    case pair of
        [a,b] -> (,) <$> V.asScalar a <*> V.asScalar b
        _ -> V.invalid "point tuple arity differs")
source :: Either MathError a -> IO a
source = either (throwIO . CallbackMathError) pure
fractional :: forall a. Coefficient a => ScalarType a -> (Fractional a => IO V.Value) -> IO V.Value
fractional _ action = case fractionalDict (Proxy :: Proxy a) of
    Just Dict -> action
    Nothing -> V.unsupported "operation requires the original Fractional coefficient instance"
floating :: forall a. Coefficient a => ScalarType a -> (Floating a => IO V.Value) -> IO V.Value
floating _ action = case floatingDict (Proxy :: Proxy a) of
    Just Dict -> action
    Nothing -> V.unsupported "operation requires the original Floating coefficient instance"
realFloat :: forall a. Coefficient a => ScalarType a -> (RealFloat a => IO V.Value) -> IO V.Value
realFloat _ action = case realFloatDict (Proxy :: Proxy a) of
    Just Dict -> action
    Nothing -> V.unsupported "operation requires the original RealFloat coefficient instance"
ordered :: forall a. Coefficient a => ScalarType a -> (Ord a => IO V.Value) -> IO V.Value
ordered _ action = case orderingDict (Proxy :: Proxy a) of
    Just Dict -> action
    Nothing -> V.unsupported "operation requires the original Ord coefficient instance"
factors :: [(P.Polynomial Rational,Int)] -> V.Value
factors = V.List . map (\(p,n) -> V.Tuple [poly SRational p,V.Index n])

apply :: Int -> [V.Value] -> IO V.Value
apply op args = case (op,args) of
    (0,[prototype,xs]) -> withWitness prototype $ \w -> poly w . P.polynomial <$> scalars xs
    (1,[p]) -> withPolynomial p $ \w x -> pure (V.List (map (V.Scalar w) (P.coefficients x)))
    (2,[p]) -> withPolynomial p $ \_ x -> pure (maybe V.None V.Index (P.polynomialDegree x))
    (3,[p,x]) -> withPolynomial p $ \w a -> V.Scalar w . P.evaluatePolynomial a <$> V.asScalar x
    (4,[p,q]) -> withPolynomial p $ \w a -> poly w . P.addPolynomial a <$> asPolynomial q
    (5,[p,q]) -> withPolynomial p $ \w a -> poly w . P.subtractPolynomial a <$> asPolynomial q
    (6,[x,p]) -> withPolynomial p $ \w a -> (\s -> poly w (P.scalePolynomial s a)) <$> V.asScalar x
    (7,[p,q]) -> withPolynomial p $ \w a -> poly w . P.multiplyPolynomial a <$> asPolynomial q
    (8,[p,q]) -> withPolynomial p $ \w a -> poly w . P.composePolynomial a <$> asPolynomial q
    (9,[p,q]) -> withPolynomial p $ \w a -> fractional w $ do
        b <- asPolynomial q
        (quotient,remainder) <- source (P.dividePolynomial a b)
        pure (V.Tuple [poly w quotient,poly w remainder])
    (10,[p]) -> withPolynomial p $ \w a -> fractional w $ pure (poly w (P.monicPolynomial a))
    (11,[p,q]) -> withPolynomial p $ \w a -> fractional w $ poly w . P.gcdPolynomial a <$> asPolynomial q
    (12,[p]) -> withPolynomial p $ \w a -> pure (poly w (P.differentiatePolynomial a))
    (13,[c,p]) -> withPolynomial p $ \w a -> fractional w $ (\x -> poly w (P.integratePolynomial x a)) <$> V.asScalar c
    (14,[p]) -> factors . P.squareFreeFactors <$> asPolynomial p
    (15,[budget,p]) -> do
        n <- V.asIndex budget; a <- asPolynomial p
        result <- source (P.rationalRoots n a)
        pure (V.List [V.Tuple [V.Scalar SRational root,V.Index count] | (root,count) <- result])
    (16,[budget,p]) -> do
        n <- V.asIndex budget; a <- asPolynomial p
        (coefficient,result) <- source (P.factorRationalPolynomial n a)
        pure (V.Tuple [V.Scalar SRational coefficient,factors result])
    (17,[p]) -> asPolynomial p >>= source . P.sturmSequence >>= pure . V.List . map (poly SRational)
    (18,[p,left,right]) -> do
        a <- asPolynomial p; b <- V.asScalar left; c <- V.asScalar right
        V.Index <$> source (P.countRealRoots a b c)
    (19,[depth,width,p]) -> do
        d <- V.asIndex depth; w <- V.asScalar width; a <- asPolynomial p
        result <- source (P.isolateRealRoots d w a)
        pure (V.List [V.Tuple [V.Scalar SRational left,V.Scalar SRational right] | (left,right) <- result])
    (20,[iterations,tolerance,p]) -> roots P.durandKerner iterations tolerance p
    (21,[iterations,tolerance,p]) -> roots P.aberthEhrlich iterations tolerance p
    (22,[p]) -> withPolynomial p $ \w a -> fractional w $ V.Dense . V.SomeMatrix w <$> source (P.companionMatrix a)
    (23,[prototype,ps]) -> withWitness prototype $ \w -> fractional w $ points ps >>= source . P.lagrangeInterpolation >>= pure . poly w
    (24,[prototype,ps]) -> withWitness prototype $ \w -> fractional w $ points ps >>= source . P.newtonInterpolation >>= pure . poly w
    (25,[prototype,degree]) -> orthogonal P.chebyshevPolynomial prototype degree
    (26,[prototype,degree]) -> orthogonal P.legendrePolynomial prototype degree
    (27,[prototype,degree]) -> orthogonal P.hermitePolynomial prototype degree
    (28,[prototype,degree]) -> orthogonal P.laguerrePolynomial prototype degree
    (29,[prototype,degree,index]) -> withWitness prototype $ \w -> fractional w $ do
        n <- V.asIndex degree; k <- V.asIndex index
        poly w <$> source (P.bernsteinPolynomial n k)
    (30,[prototype,degree,ps]) -> withWitness prototype $ \w -> realFloat w $ do
        n <- V.asIndex degree; values <- points ps
        poly w <$> source (P.polynomialRegression n values)
    (31,[prototype,xs]) -> withWitness prototype $ \w -> series w . P.powerSeries <$> scalars xs
    (32,[s]) -> withSeries s $ \w a -> pure (V.List (map (V.Scalar w) (P.seriesCoefficients a)))
    (33,[p,q]) -> withSeries p $ \w a -> series w . P.addSeries a <$> asSeries q
    (34,[p,q]) -> withSeries p $ \w a -> series w . P.multiplySeries a <$> asSeries q
    (35,[p]) -> withSeries p $ \w a -> fractional w $ series w <$> source (P.reciprocalSeries a)
    (36,[p,q]) -> withSeries p $ \w a -> fractional w $ asSeries q >>= source . P.divideSeries a >>= pure . series w
    (37,[p,q]) -> withSeries p $ \w a -> asSeries q >>= source . P.composeSeries a >>= pure . series w
    (38,[p]) -> withSeries p $ \w a -> pure (series w (P.differentiateSeries a))
    (39,[c,p]) -> withSeries p $ \w a -> fractional w $ (\x -> series w (P.integrateSeries x a)) <$> V.asScalar c
    (40,[p]) -> withSeries p $ \w a -> floating w $ pure (series w (P.expSeries a))
    (41,[p]) -> withSeries p $ \w a -> floating w $ ordered w $ series w <$> source (P.logSeries a)
    (42,[p,q]) -> do
        a <- asPolynomial p; b <- asPolynomial q
        rationalFunction <$> source (P.rationalFunction a b)
    (43,[f]) -> poly SRational . P.rationalNumerator <$> asRationalFunction f
    (44,[f]) -> poly SRational . P.rationalDenominator <$> asRationalFunction f
    (45,[f,x]) -> do
        a <- asRationalFunction f; b <- V.asScalar x
        V.Scalar SRational <$> source (P.evaluateRationalFunction a b)
    (46,[f,g]) -> do
        a <- asRationalFunction f; b <- asRationalFunction g
        rationalFunction <$> source (P.addRationalFunction a b)
    (47,[f,g]) -> do
        a <- asRationalFunction f; b <- asRationalFunction g
        rationalFunction <$> source (P.multiplyRationalFunction a b)
    (48,[budget,f]) -> do
        n <- V.asIndex budget; a <- asRationalFunction f
        (whole,result) <- source (P.partialFractions n a)
        pure (V.Tuple [poly SRational whole,V.List [V.Tuple [poly SRational p,poly SRational q,V.Index k] | (p,q,k) <- result]])
    (49,[p,q]) -> withPolynomial p $ \_ a -> V.Boolean . (a==) <$> asPolynomial q
    (50,[p,q]) -> withSeries p $ \_ a -> V.Boolean . (a==) <$> asSeries q
    (51,[f,g]) -> do
        a <- asRationalFunction f; b <- asRationalFunction g
        pure (V.Boolean (a==b))
    _ -> V.invalid "invalid Polynomial operation or argument count"
  where
    roots algorithm iterations tolerance p = do
        n <- V.asIndex iterations; t <- V.asScalar tolerance; a <- asPolynomial p
        result <- source (algorithm n t a)
        pure (V.List (map (V.Scalar SComplexDouble) result))

orthogonal :: (forall a. (Eq a,Fractional a) => Int -> Either MathError (P.Polynomial a)) -> V.Value -> V.Value -> IO V.Value
orthogonal algorithm prototype degree = withWitness prototype $ \w -> fractional w $ do
    n <- V.asIndex degree
    poly w <$> source (algorithm n)

polynomialBoundary :: IO CInt -> IO CInt
polynomialBoundary action = B.boundary $ callbackBoundary (\e -> B.checked (Left e) (const (pure ()))) action
foreign export ccall "hm_polynomial_apply" ffiApply :: CInt -> Ptr (StablePtr V.Value) -> CSize -> Ptr (StablePtr V.Value) -> IO CInt
ffiApply :: CInt -> Ptr (StablePtr V.Value) -> CSize -> Ptr (StablePtr V.Value) -> IO CInt
ffiApply opcode pointers count out = polynomialBoundary $ do
    args <- peekArray (fromIntegral count) pointers >>= mapM deRefStablePtr
    value <- apply (fromIntegral opcode) args
    B.checked (Right ()) (const (V.publish value out))

type ApproximationCallback = CDouble -> Ptr CDouble -> Ptr () -> Ptr () -> IO CInt
foreign import ccall "dynamic" dynamicApproximation :: FunPtr ApproximationCallback -> ApproximationCallback
callbackFunction :: FunPtr ApproximationCallback -> Ptr () -> Double -> Double
callbackFunction pointer userdata input = unsafePerformIO $ alloca $ \out -> withMathErrorWire $ \wire -> do
    status <- dynamicApproximation pointer (coerce input) out userdata wire
    if status==0 then coerce <$> peek out
    else if status==11 then readMathError wire >>= throwIO . CallbackMathError
    else readWireMessage wire >>= throwIO . CallbackFailure status
{-# NOINLINE callbackFunction #-}
foreign export ccall "hm_polynomial_chebyshev_approximation" approximation :: CPtrdiff -> FunPtr ApproximationCallback -> Ptr () -> Ptr (StablePtr V.Value) -> IO CInt
approximation :: CPtrdiff -> FunPtr ApproximationCallback -> Ptr () -> Ptr (StablePtr V.Value) -> IO CInt
approximation degree callback userdata out = polynomialBoundary $ do
    result <- source (P.chebyshevApproximation (fromIntegral degree) (callbackFunction callback userdata))
    B.checked (Right ()) (const (V.publish (poly SDouble result) out))
