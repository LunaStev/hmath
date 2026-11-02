{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Original optimization functions with typed value/record/callback adapters.
module HMath.FFI.OptimizationAll where
import Control.Exception (bracket, bracketOnError, evaluate, throwIO)
import Data.Typeable (Typeable, cast)
import Foreign
import Foreign.C
import System.IO.Unsafe (unsafePerformIO)
import HMath.Error (MathError)
import HMath.FFI.Boundary
import HMath.FFI.MathError
import HMath.FFI.Coefficient (ScalarType (SDouble,SWord64))
import HMath.FFI.Value (Value (..), asIndex, asList, asScalar, invalid, publish, forceValue)
import qualified HMath.Optimization.Common as C
import qualified HMath.Optimization.FirstOrder as F
import qualified HMath.Optimization.Local as L
import qualified HMath.Optimization.Constrained as K
import qualified HMath.Optimization.Global as G

class FromValue a where fromValue :: Value -> IO a
class ToValue a where toValue :: a -> IO Value
instance FromValue Value where fromValue = pure
instance ToValue Value where toValue = pure
instance FromValue Double where fromValue = asScalar
instance ToValue Double where toValue = pure . Scalar SDouble
instance FromValue Int where fromValue = asIndex
instance ToValue Int where toValue = pure . Index
instance FromValue Word64 where fromValue = asScalar
instance ToValue Word64 where toValue = pure . Scalar SWord64
instance FromValue Bool where
    fromValue (Boolean value) = pure value
    fromValue _ = invalid "expected Bool"
instance ToValue Bool where toValue = pure . Boolean
instance ToValue () where toValue () = pure None
instance (FromValue a) => FromValue [a] where fromValue value = asList value >>= mapM fromValue
instance (ToValue a) => ToValue [a] where toValue values = List <$> mapM toValue values
instance (FromValue a) => FromValue (Maybe a) where
    fromValue None = pure Nothing
    fromValue value = Just <$> fromValue value
instance (ToValue a) => ToValue (Maybe a) where toValue = maybe (pure None) toValue
instance (ToValue a) => ToValue (Either MathError a) where
    toValue (Left err) = throwIO (CallbackMathError err)
    toValue (Right value) = toValue value
instance (ToValue a,ToValue b) => ToValue (a,b) where toValue (a,b) = Tuple <$> sequence [toValue a,toValue b]
instance (ToValue a,ToValue b,ToValue c,ToValue d) => ToValue (a,b,c,d) where
    toValue (a,b,c,d) = Tuple <$> sequence [toValue a,toValue b,toValue c,toValue d]

opaque :: Typeable a => Int -> Int -> a -> IO () -> Value
opaque kind count value force = Opaque kind (-1) count force value
unbox :: forall a. Typeable a => Int -> Value -> IO a
unbox kind (Opaque actual _ _ _ value) | kind == actual = maybe (invalid "optimization object type differs") pure (cast value)
unbox _ _ = invalid "optimization object kind differs"
forceFields :: [IO Value] -> IO ()
forceFields fields = sequence fields >>= mapM_ forceValue

instance FromValue C.OptimizeOptions where fromValue = unbox 20
instance ToValue C.OptimizeOptions where
    toValue value = pure (opaque 20 4 value (forceFields [toValue(C.optMaxIterations value),toValue(C.optMaxEvaluations value),toValue(C.optTolerance value),toValue(C.optLearningRate value)]))
instance FromValue C.OptimizeResult where fromValue = unbox 21
instance ToValue C.OptimizeResult where
    toValue value = pure (opaque 21 6 value (forceFields [toValue(C.optPoint value),toValue(C.optValue value),toValue(C.optGradientNorm value),toValue(C.optIterations value),toValue(C.optEvaluations value),toValue(C.optConverged value)]))
instance FromValue K.LPResult where fromValue = unbox 22
instance ToValue K.LPResult where
    toValue value = pure (opaque 22 4 value (forceFields [toValue(K.lpPoint value),toValue(K.lpValue value),toValue(K.lpBasis value),toValue(K.lpIterations value)]))
instance FromValue C.LearningRate where fromValue = unbox 23
instance ToValue C.LearningRate where toValue value = pure (opaque 23 0 value (evaluate value >> pure ()))
instance FromValue C.EarlyStopping where fromValue = unbox 24
instance ToValue C.EarlyStopping where
    toValue value = pure (opaque 24 3 value (forceFields [toValue(C.bestScore value),toValue(C.staleSteps value),toValue(C.stopped value)]))
instance FromValue F.GradientMethod where fromValue = unbox 25
instance ToValue F.GradientMethod where toValue value = pure (opaque 25 0 value (evaluate value >> pure ()))
instance FromValue L.ScalarMethod where fromValue = unbox 26
instance ToValue L.ScalarMethod where toValue value = pure (opaque 26 0 value (evaluate value >> pure ()))
instance FromValue L.QuasiNewton where fromValue = unbox 27
instance ToValue L.QuasiNewton where toValue value = pure (opaque 27 0 value (evaluate value >> pure ()))
instance FromValue L.NewtonMethod where fromValue = unbox 28
instance ToValue L.NewtonMethod where toValue value = pure (opaque 28 0 value (evaluate value >> pure ()))
instance FromValue L.LeastSquaresLoss where fromValue = unbox 29
instance ToValue L.LeastSquaresLoss where toValue value = pure (opaque 29 0 value (evaluate value >> pure ()))
instance FromValue K.Constraint where fromValue = unbox 30
instance ToValue K.Constraint where toValue value = pure (opaque 30 0 value (evaluate value >> pure ()))
instance FromValue K.PenaltyMethod where fromValue = unbox 31
instance ToValue K.PenaltyMethod where toValue value = pure (opaque 31 0 value (evaluate value >> pure ()))
instance FromValue G.GlobalMethod where fromValue = unbox 32
instance ToValue G.GlobalMethod where toValue value = pure (opaque 32 0 value (evaluate value >> pure ()))
instance FromValue C.LineSearch where fromValue = unbox 33
instance ToValue C.LineSearch where toValue value = pure (opaque 33 0 value (evaluate value >> pure ()))
instance FromValue F.OptimizerState where fromValue = unbox 34
instance ToValue F.OptimizerState where toValue value = pure (opaque 34 0 value (evaluate value >> pure ()))

data Function
    = ObjectiveFn C.Objective
    | GradientFn C.Gradient
    | HessianFn C.Hessian
    | ProxFn (Double -> [Double] -> Either MathError [Double])
    | MonitorFn (C.OptimizeResult -> Either MathError Bool)
functionValue :: Function -> Value
functionValue function = Opaque 35 (-1) (case function of { ObjectiveFn _ -> 0; GradientFn _ -> 1; HessianFn _ -> 2; ProxFn _ -> 3; MonitorFn _ -> 4 }) (pure ()) function
instance FromValue Function where fromValue = unbox 35
instance FromValue ([Double] -> Either MathError Double) where
    fromValue value = do f <- fromValue value; case f of { ObjectiveFn g -> pure g; _ -> invalid "expected Objective callback" }
instance FromValue (Double -> Either MathError Double) where
    fromValue value = do f <- fromValue value; case f of { ObjectiveFn g -> pure (\x -> g [x]); _ -> invalid "expected scalar Objective callback" }
instance FromValue ([Double] -> Either MathError [Double]) where
    fromValue value = do f <- fromValue value; case f of { GradientFn g -> pure g; _ -> invalid "expected Gradient/projection callback" }
instance FromValue ([Double] -> Either MathError [[Double]]) where
    fromValue value = do f <- fromValue value; case f of { HessianFn g -> pure g; _ -> invalid "expected Hessian/Jacobian callback" }
instance FromValue (Double -> [Double] -> Either MathError [Double]) where
    fromValue value = do f <- fromValue value; case f of { ProxFn g -> pure g; _ -> invalid "expected proximal callback" }
instance FromValue (C.OptimizeResult -> Either MathError Bool) where
    fromValue value = do f <- fromValue value; case f of { MonitorFn g -> pure g; _ -> invalid "expected monitor callback" }

class Apply a where apply :: a -> [Value] -> IO Value
instance {-# OVERLAPPABLE #-} (ToValue a) => Apply a where
    apply value [] = toValue value
    apply _ _ = invalid "too many optimization arguments"
instance {-# OVERLAPPING #-} (FromValue a,Apply b) => Apply (a -> b) where
    apply function (value:rest) = fromValue value >>= \argument -> apply (function argument) rest
    apply _ [] = invalid "missing optimization argument"

-- The C helper passes an owned result and independent borrowed input handle.
foreign import ccall safe "hm_opt_invoke_callback"
    invokeCallback :: FunPtr () -> Ptr () -> StablePtr Value -> Ptr (StablePtr Value) -> Ptr () -> IO CInt
{-# NOINLINE callback #-}
callback :: (ToValue a,FromValue b) => FunPtr () -> Ptr () -> a -> Either MathError b
callback function userdata argument = unsafePerformIO $ do
    encoded <- toValue argument
    forceValue encoded
    bracket (newStablePtr encoded) freeStablePtr $ \input ->
        alloca $ \out -> withMathErrorWire $ \errorWire -> do
            status <- invokeCallback function userdata input out errorWire
            if status == 11 then Left <$> readMathError errorWire
            else if status /= 0 then readCallbackFailure status errorWire >>= throwIO
            else do
                pointer <- peek out
                bracket (pure pointer) freeStablePtr $ \result -> deRefStablePtr result >>= fmap Right . fromValue

foreign export ccall "hm_opt_callback"
    createCallback :: CInt -> FunPtr () -> Ptr () -> Ptr (StablePtr Value) -> IO CInt
createCallback :: CInt -> FunPtr () -> Ptr () -> Ptr (StablePtr Value) -> IO CInt
createCallback kind function userdata out = boundary $ do
    let result = case kind of
            0 -> ObjectiveFn (callback function userdata)
            1 -> GradientFn (callback function userdata)
            2 -> HessianFn (callback function userdata)
            3 -> ProxFn (\rate point -> callback function userdata (rate,point))
            4 -> MonitorFn (callback function userdata)
            _ -> error "invalid optimization callback kind"
    checked (Right ()) $ \_ -> publish (functionValue result) out

-- Callback arguments include pairs; tuple decoding is structural and lossless.
instance (FromValue a,FromValue b) => FromValue (a,b) where
    fromValue (Tuple [a,b]) = (,) <$> fromValue a <*> fromValue b
    fromValue _ = invalid "expected pair"

foreign export ccall "hm_opt_invoke"
    invoke :: CString -> Ptr (StablePtr Value) -> CSize -> Ptr (StablePtr Value) -> IO CInt
invoke :: CString -> Ptr (StablePtr Value) -> CSize -> Ptr (StablePtr Value) -> IO CInt
invoke namePointer arguments count out = boundary $ do
    name <- peekCString namePointer
    values <- peekArray (fromIntegral count) arguments >>= mapM deRefStablePtr
    result <- dispatch name values
    checked (Right ()) $ \_ -> publish result out

foreign export ccall "hm_opt_clone" cloneValue :: StablePtr Value -> Ptr (StablePtr Value) -> IO CInt
cloneValue :: StablePtr Value -> Ptr (StablePtr Value) -> IO CInt
cloneValue pointer out = boundary $ deRefStablePtr pointer >>= \value -> checked (Right ()) (\_ -> publish value out)

foreign export ccall "hm_opt_import_state"
    importState :: StablePtr F.OptimizerState -> Ptr (StablePtr Value) -> IO CInt
importState :: StablePtr F.OptimizerState -> Ptr (StablePtr Value) -> IO CInt
importState pointer out = boundary $ do value <- deRefStablePtr pointer; encoded <- toValue value; checked (Right ()) $ \_ -> publish encoded out
foreign export ccall "hm_opt_export_state"
    exportState :: StablePtr Value -> Ptr (StablePtr F.OptimizerState) -> IO CInt
exportState :: StablePtr Value -> Ptr (StablePtr F.OptimizerState) -> IO CInt
exportState pointer out = boundary $ do
    state <- deRefStablePtr pointer >>= fromValue
    checked (Right ()) $ \_ -> bracketOnError (newStablePtr state) freeStablePtr (\p -> poke out p >> pure ())

dispatch :: String -> [Value] -> IO Value
dispatch name arguments = case name of
    "OptimizeOptions" -> apply C.OptimizeOptions arguments
    "defaultOptimizeOptions" -> apply C.defaultOptimizeOptions arguments
    "OptimizeResult" -> apply C.OptimizeResult arguments
    "EarlyStopping" -> apply C.EarlyStopping arguments
    "ConstantRate" -> apply C.ConstantRate arguments
    "StepDecay" -> apply C.StepDecay arguments
    "ExponentialDecay" -> apply C.ExponentialDecay arguments
    "CosineAnnealing" -> apply C.CosineAnnealing arguments
    "Warmup" -> apply C.Warmup arguments
    "Armijo" -> apply C.Armijo arguments
    "StrongWolfe" -> apply C.StrongWolfe arguments
    "checkedOptions" -> apply C.checkedOptions arguments
    "checkedPoint" -> apply C.checkedPoint arguments
    "checkedValue" -> apply C.checkedValue arguments
    "checkedGradient" -> apply C.checkedGradient arguments
    "checkBudget" -> apply C.checkBudget arguments
    "dot" -> apply C.dot arguments
    "add" -> apply C.add arguments
    "sub" -> apply C.sub arguments
    "outer" -> apply C.outer arguments
    "norm" -> apply C.norm arguments
    "scale" -> apply C.scale arguments
    "identity" -> apply C.identity arguments
    "matVec" -> apply C.matVec arguments
    "matMul" -> apply C.matMul arguments
    "transpose" -> apply (C.transpose :: [[Value]] -> [[Value]]) arguments
    "solveDense" -> apply C.solveDense arguments
    "result" -> apply C.result arguments
    "learningRate" -> apply C.learningRate arguments
    "earlyStopping" -> apply C.earlyStopping arguments
    "lineSearch" -> apply C.lineSearch arguments
    "optMaxIterations" -> apply C.optMaxIterations arguments
    "optMaxEvaluations" -> apply C.optMaxEvaluations arguments
    "optTolerance" -> apply C.optTolerance arguments
    "optLearningRate" -> apply C.optLearningRate arguments
    "optPoint" -> apply C.optPoint arguments
    "optValue" -> apply C.optValue arguments
    "optGradientNorm" -> apply C.optGradientNorm arguments
    "optIterations" -> apply C.optIterations arguments
    "optEvaluations" -> apply C.optEvaluations arguments
    "optConverged" -> apply C.optConverged arguments
    "bestScore" -> apply C.bestScore arguments
    "staleSteps" -> apply C.staleSteps arguments
    "stopped" -> apply C.stopped arguments
    "GradientDescent" -> apply F.GradientDescent arguments
    "Momentum" -> apply F.Momentum arguments
    "Nesterov" -> apply F.Nesterov arguments
    "AdaGrad" -> apply F.AdaGrad arguments
    "RMSProp" -> apply F.RMSProp arguments
    "AdaDelta" -> apply F.AdaDelta arguments
    "Adam" -> apply F.Adam arguments
    "AdamW" -> apply F.AdamW arguments
    "AMSGrad" -> apply F.AMSGrad arguments
    "AdaMax" -> apply F.AdaMax arguments
    "Nadam" -> apply F.Nadam arguments
    "RAdam" -> apply F.RAdam arguments
    "initializeOptimizer" -> apply F.initializeOptimizer arguments
    "optimizerStep" -> apply F.optimizerStep arguments
    "minimizeGradient" -> apply F.minimizeGradient arguments
    "minimizeGradientWithCallback" -> apply F.minimizeGradientWithCallback arguments
    "stochasticGradient" -> apply F.stochasticGradient arguments
    "miniBatchGradient" -> apply (\values -> functionValue (GradientFn (F.miniBatchGradient values))) arguments
    "projectedGradient" -> apply F.projectedGradient arguments
    "proximalGradient" -> apply F.proximalGradient arguments
    "fista" -> apply F.fista arguments
    "coordinateDescent" -> apply F.coordinateDescent arguments
    "GoldenSection" -> apply L.GoldenSection arguments
    "TernarySearch" -> apply L.TernarySearch arguments
    "BrentSearch" -> apply L.BrentSearch arguments
    "minimizeScalar" -> apply L.minimizeScalar arguments
    "BFGS" -> apply L.BFGS arguments
    "DFP" -> apply L.DFP arguments
    "SR1" -> apply L.SR1 arguments
    "LBFGS" -> apply L.LBFGS arguments
    "minimizeQuasiNewton" -> apply L.minimizeQuasiNewton arguments
    "Newton" -> apply L.Newton arguments
    "NewtonCG" -> apply L.NewtonCG arguments
    "TrustRegion" -> apply L.TrustRegion arguments
    "Dogleg" -> apply L.Dogleg arguments
    "minimizeNewton" -> apply L.minimizeNewton arguments
    "nonlinearCG" -> apply L.nonlinearCG arguments
    "SquaredLoss" -> apply L.SquaredLoss arguments
    "HuberLoss" -> apply L.HuberLoss arguments
    "CauchyLoss" -> apply L.CauchyLoss arguments
    "SoftL1" -> apply L.SoftL1 arguments
    "leastSquares" -> apply L.leastSquares arguments
    "nelderMead" -> apply L.nelderMead arguments
    "powell" -> apply L.powell arguments
    "Equality" -> apply K.Equality arguments
    "LessEqual" -> apply K.LessEqual arguments
    "feasibility" -> apply K.feasibility arguments
    "QuadraticPenalty" -> apply K.QuadraticPenalty arguments
    "LogBarrier" -> apply K.LogBarrier arguments
    "InteriorPoint" -> apply K.InteriorPoint arguments
    "AugmentedLagrangian" -> apply K.AugmentedLagrangian arguments
    "constrainedMinimize" -> apply K.constrainedMinimize arguments
    "LPResult" -> apply K.LPResult arguments
    "linearProgramming" -> apply K.linearProgramming arguments
    "revisedSimplex" -> apply K.revisedSimplex arguments
    "quadraticProgramming" -> apply K.quadraticProgramming arguments
    "slsqp" -> apply K.slsqp arguments
    "cobyla" -> apply K.cobyla arguments
    "weightedObjective" -> apply (\weights functions -> functionValue (ObjectiveFn (K.weightedObjective weights functions))) arguments
    "paretoFront" -> apply K.paretoFront arguments
    "lpPoint" -> apply K.lpPoint arguments
    "lpValue" -> apply K.lpValue arguments
    "lpBasis" -> apply K.lpBasis arguments
    "lpIterations" -> apply K.lpIterations arguments
    "SimulatedAnnealing" -> apply G.SimulatedAnnealing arguments
    "DifferentialEvolution" -> apply G.DifferentialEvolution arguments
    "GeneticAlgorithm" -> apply G.GeneticAlgorithm arguments
    "ParticleSwarm" -> apply G.ParticleSwarm arguments
    "CMAES" -> apply G.CMAES arguments
    "globalMinimize" -> apply G.globalMinimize arguments
    "basinHopping" -> apply G.basinHopping arguments
    "__apply" -> case arguments of
        function:rest -> do
            target <- fromValue function
            case target of
                ObjectiveFn f -> apply f rest
                GradientFn f -> apply f rest
                HessianFn f -> apply f rest
                ProxFn f -> apply f rest
                MonitorFn f -> apply f rest
        _ -> invalid "missing function argument"
    _ -> invalid "unknown optimization operation"
