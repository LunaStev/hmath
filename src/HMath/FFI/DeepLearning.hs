{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Original checked neural functions, records and AD/RNG/Tensor interoperability.
module HMath.FFI.DeepLearning where

import Control.Exception (evaluate,throwIO)
import Data.Typeable (Typeable,cast)
import Foreign
import Foreign.C
import HMath.Error (MathError)
import HMath.FFI.Boundary
import HMath.FFI.MathError (CallbackFailure(..))
import HMath.FFI.Coefficient (ScalarType(SDouble,SInt8))
import HMath.FFI.Value (Value(..),asScalar,asIndex,asList,asTuple,asBoolean,invalid,publish,forceValue)
import HMath.FFI.TensorCodec (Element(Numeric),asTensorType,fromTensor)
import HMath.FFI.AutodiffValue (asADExpr,fromADExpr,asADTensor,fromADTensor)
import HMath.FFI.RandomCodec (asRNG,rng)
import qualified HMath.Autodiff as A
import qualified HMath.Random as R
import qualified HMath.Tensor as T
import qualified HMath.DeepLearning.Core as C
import qualified HMath.DeepLearning.Layers as L
import qualified HMath.DeepLearning.Precision as P
import qualified HMath.DeepLearning.Metrics as M

class FromValue a where fromValue :: Value -> IO a
class ToValue a where toValue :: a -> IO Value
instance FromValue Double where fromValue = asScalar
instance ToValue Double where toValue = pure . Scalar SDouble
instance FromValue Int where fromValue = asIndex
instance ToValue Int where toValue = pure . Index
instance ToValue Int8 where toValue = pure . Scalar SInt8
instance FromValue Bool where fromValue = asBoolean
instance ToValue Bool where toValue = pure . Boolean
instance FromValue a => FromValue [a] where fromValue value = asList value >>= mapM fromValue
instance ToValue a => ToValue [a] where toValue values = List <$> mapM toValue values
instance FromValue a => FromValue(Maybe a) where fromValue None = pure Nothing; fromValue value = Just <$> fromValue value
instance ToValue a => ToValue(Maybe a) where toValue = maybe(pure None)toValue
instance ToValue a => ToValue(Either MathError a) where
    toValue(Left err) = throwIO(CallbackMathError err)
    toValue(Right value) = toValue value
instance (FromValue a,FromValue b)=>FromValue(a,b) where
    fromValue value = do [a,b]<-asTuple 2 value; (,) <$> fromValue a <*> fromValue b
instance (ToValue a,ToValue b)=>ToValue(a,b) where toValue(a,b) = Tuple <$> sequence[toValue a,toValue b]
instance (ToValue a,ToValue b,ToValue c)=>ToValue(a,b,c) where toValue(a,b,c) = Tuple <$> sequence[toValue a,toValue b,toValue c]
instance FromValue(T.Tensor Double) where fromValue = asTensorType
instance ToValue(T.Tensor Double) where toValue = pure . fromTensor(Numeric SDouble)
instance FromValue A.Expr where fromValue = asADExpr
instance ToValue A.Expr where toValue = pure . fromADExpr
instance FromValue A.ADTensor where fromValue = asADTensor
instance ToValue A.ADTensor where toValue = pure . fromADTensor
instance FromValue R.RNG where fromValue = asRNG
instance ToValue R.RNG where toValue = pure . rng

opaque :: Typeable a => Int -> a -> IO () -> Value
opaque kind value force = Opaque kind (-1) 0 force value
unbox :: forall a. Typeable a => Int -> Value -> IO a
unbox expected(Opaque actual _ _ _ payload) | expected==actual = maybe(invalid "neural object type differs")pure(cast payload)
unbox _ _ = invalid "neural object kind differs"
forceFields :: [IO Value] -> IO ()
forceFields actions = sequence actions >>= mapM_ forceValue

instance FromValue C.Activation where fromValue = unbox 274
instance ToValue C.Activation where toValue value = pure(opaque 274 value (evaluate value >> pure ()))

instance FromValue C.Loss where fromValue = unbox 275
instance ToValue C.Loss where toValue value = pure(opaque 275 value (evaluate value >> pure ()))

instance FromValue C.Reduction where fromValue = unbox 276
instance ToValue C.Reduction where toValue value = pure(opaque 276 value (evaluate value >> pure ()))

instance FromValue L.Training where fromValue = unbox 277
instance ToValue L.Training where toValue value = pure(opaque 277 value (evaluate value >> pure ()))

instance FromValue L.BatchNormState where fromValue = unbox 278
instance ToValue L.BatchNormState where toValue value = pure(opaque 278 value (forceFields [toValue((L.runningMean) value),toValue((L.runningVariance) value),toValue((L.batchesSeen) value)]))

instance FromValue L.Initializer where fromValue = unbox 279
instance ToValue L.Initializer where toValue value = pure(opaque 279 value (evaluate value >> pure ()))

instance FromValue L.ConvOptions where fromValue = unbox 280
instance ToValue L.ConvOptions where toValue value = pure(opaque 280 value (forceFields [toValue((L.convolutionStride) value),toValue((L.convolutionPadding) value),toValue((L.convolutionDilation) value),toValue((L.convolutionGroups) value)]))

instance FromValue L.PoolMode where fromValue = unbox 281
instance ToValue L.PoolMode where toValue value = pure(opaque 281 value (evaluate value >> pure ()))

instance FromValue L.KVCache where fromValue = unbox 282
instance ToValue L.KVCache where toValue value = pure(opaque 282 value (forceFields [toValue((fst . L.cacheValues) value),toValue((snd . L.cacheValues) value)]))

instance FromValue P.Quantization where fromValue = unbox 283
instance ToValue P.Quantization where toValue value = pure(opaque 283 value (evaluate value >> pure ()))

instance FromValue P.Precision where fromValue = unbox 284
instance ToValue P.Precision where toValue value = pure(opaque 284 value (evaluate value >> pure ()))

instance FromValue P.QuantizedTensor where fromValue = unbox 285
instance ToValue P.QuantizedTensor where toValue value = pure(opaque 285 value (forceFields [toValue((P.quantizedValues) value),toValue((P.quantizationScales) value),toValue((P.quantizationZeroPoints) value)]))

instance FromValue P.LossScaler where fromValue = unbox 286
instance ToValue P.LossScaler where toValue value = pure(opaque 286 value (forceFields [toValue((P.lossScale) value),toValue((P.scaleGrowthInterval) value),toValue((P.finiteSteps) value)]))

instance FromValue M.ClassificationMetrics where fromValue = unbox 290
instance ToValue M.ClassificationMetrics where toValue value = pure(opaque 290 value (forceFields [toValue((M.accuracy) value),toValue((M.precisionByClass) value),toValue((M.recallByClass) value),toValue((M.f1ByClass) value)]))

class Apply a where apply :: a -> [Value] -> IO Value
instance {-# OVERLAPPABLE #-} ToValue a => Apply a where
    apply value [] = toValue value
    apply _ _ = invalid "too many neural arguments"
instance {-# OVERLAPPING #-} (FromValue a,Apply b)=>Apply(a -> b) where
    apply function(value:rest) = fromValue value >>= \argument -> apply(function argument)rest
    apply _ [] = invalid "missing neural argument"
foreign export ccall "hm_neural_apply" ffiApply :: CString -> Ptr(StablePtr Value) -> CSize -> Ptr(StablePtr Value) -> IO CInt
ffiApply :: CString -> Ptr(StablePtr Value) -> CSize -> Ptr(StablePtr Value) -> IO CInt
ffiApply namePointer inputs count out = boundary $ do
    name<-peekCString namePointer
    arguments<-peekArray(fromIntegral count)inputs >>= mapM deRefStablePtr
    result<-dispatch name arguments
    checked(Right())(\_ -> publish result out)
dispatch :: String -> [Value] -> IO Value
dispatch name arguments = case name of
-- BEGIN GENERATED
    "HMath.DeepLearning.Core.Sigmoid" -> apply C.Sigmoid arguments
    "HMath.DeepLearning.Core.Tanh" -> apply C.Tanh arguments
    "HMath.DeepLearning.Core.ReLU" -> apply C.ReLU arguments
    "HMath.DeepLearning.Core.SELU" -> apply C.SELU arguments
    "HMath.DeepLearning.Core.GELU" -> apply C.GELU arguments
    "HMath.DeepLearning.Core.SiLU" -> apply C.SiLU arguments
    "HMath.DeepLearning.Core.Mish" -> apply C.Mish arguments
    "HMath.DeepLearning.Core.Softplus" -> apply C.Softplus arguments
    "HMath.DeepLearning.Core.Softsign" -> apply C.Softsign arguments
    "HMath.DeepLearning.Core.HardSigmoid" -> apply C.HardSigmoid arguments
    "HMath.DeepLearning.Core.HardSwish" -> apply C.HardSwish arguments
    "HMath.DeepLearning.Core.LeakyReLU" -> apply C.LeakyReLU arguments
    "HMath.DeepLearning.Core.PReLU" -> apply C.PReLU arguments
    "HMath.DeepLearning.Core.ELU" -> apply C.ELU arguments
    "HMath.DeepLearning.Core.Sum" -> apply C.Sum arguments
    "HMath.DeepLearning.Core.Mean" -> apply C.Mean arguments
    "HMath.DeepLearning.Core.MeanSquaredError" -> apply C.MeanSquaredError arguments
    "HMath.DeepLearning.Core.MeanAbsoluteError" -> apply C.MeanAbsoluteError arguments
    "HMath.DeepLearning.Core.BinaryCrossEntropy" -> apply C.BinaryCrossEntropy arguments
    "HMath.DeepLearning.Core.CategoricalCrossEntropy" -> apply C.CategoricalCrossEntropy arguments
    "HMath.DeepLearning.Core.NegativeLogLikelihood" -> apply C.NegativeLogLikelihood arguments
    "HMath.DeepLearning.Core.KLDivergence" -> apply C.KLDivergence arguments
    "HMath.DeepLearning.Core.CosineLoss" -> apply C.CosineLoss arguments
    "HMath.DeepLearning.Core.Huber" -> apply C.Huber arguments
    "HMath.DeepLearning.Core.SmoothL1" -> apply C.SmoothL1 arguments
    "HMath.DeepLearning.Core.Hinge" -> apply C.Hinge arguments
    "HMath.DeepLearning.Core.activation" -> apply C.activation arguments
    "HMath.DeepLearning.Core.activationDerivative" -> apply C.activationDerivative arguments
    "HMath.DeepLearning.Core.activationExpr" -> apply C.activationExpr arguments
    "HMath.DeepLearning.Core.softmax" -> apply C.softmax arguments
    "HMath.DeepLearning.Core.logSoftmax" -> apply C.logSoftmax arguments
    "HMath.DeepLearning.Core.sparsemax" -> apply C.sparsemax arguments
    "HMath.DeepLearning.Core.gatedLinearUnit" -> apply C.gatedLinearUnit arguments
    "HMath.DeepLearning.Core.softmaxExpr" -> apply C.softmaxExpr arguments
    "HMath.DeepLearning.Core.logSoftmaxExpr" -> apply C.logSoftmaxExpr arguments
    "HMath.DeepLearning.Core.sparsemaxExpr" -> apply C.sparsemaxExpr arguments
    "HMath.DeepLearning.Core.loss" -> apply C.loss arguments
    "HMath.DeepLearning.Core.lossGradient" -> apply C.lossGradient arguments
    "HMath.DeepLearning.Core.lossExpr" -> apply C.lossExpr arguments
    "HMath.DeepLearning.Core.binaryCrossEntropyLogits" -> apply C.binaryCrossEntropyLogits arguments
    "HMath.DeepLearning.Core.categoricalCrossEntropyLogits" -> apply C.categoricalCrossEntropyLogits arguments
    "HMath.DeepLearning.Core.regularization" -> apply C.regularization arguments
    "HMath.DeepLearning.Core.contrastiveLoss" -> apply C.contrastiveLoss arguments
    "HMath.DeepLearning.Core.tripletLoss" -> apply C.tripletLoss arguments
    "HMath.DeepLearning.Core.focalLoss" -> apply C.focalLoss arguments
    "HMath.DeepLearning.Core.diceLoss" -> apply C.diceLoss arguments
    "HMath.DeepLearning.Core.iouLoss" -> apply C.iouLoss arguments
    "HMath.DeepLearning.Core.ctcLoss" -> apply C.ctcLoss arguments
    "HMath.DeepLearning.Core.ctcLossGradient" -> apply C.ctcLossGradient arguments
    "HMath.DeepLearning.Core.ctcLossExpr" -> apply C.ctcLossExpr arguments
    "HMath.DeepLearning.Layers.Training" -> apply L.Training arguments
    "HMath.DeepLearning.Layers.Inference" -> apply L.Inference arguments
    "HMath.DeepLearning.Layers.dropout" -> apply L.dropout arguments
    "HMath.DeepLearning.Layers.spatialDropout" -> apply L.spatialDropout arguments
    "HMath.DeepLearning.Layers.BatchNormState" -> apply L.BatchNormState arguments
    "HMath.DeepLearning.Layers.runningMean" -> apply L.runningMean arguments
    "HMath.DeepLearning.Layers.runningVariance" -> apply L.runningVariance arguments
    "HMath.DeepLearning.Layers.batchesSeen" -> apply L.batchesSeen arguments
    "HMath.DeepLearning.Layers.batchNorm" -> apply L.batchNorm arguments
    "HMath.DeepLearning.Layers.layerNorm" -> apply L.layerNorm arguments
    "HMath.DeepLearning.Layers.rmsNorm" -> apply L.rmsNorm arguments
    "HMath.DeepLearning.Layers.instanceNorm" -> apply L.instanceNorm arguments
    "HMath.DeepLearning.Layers.groupNorm" -> apply L.groupNorm arguments
    "HMath.DeepLearning.Layers.weightNorm" -> apply L.weightNorm arguments
    "HMath.DeepLearning.Layers.XavierUniform" -> apply L.XavierUniform arguments
    "HMath.DeepLearning.Layers.XavierNormal" -> apply L.XavierNormal arguments
    "HMath.DeepLearning.Layers.KaimingUniform" -> apply L.KaimingUniform arguments
    "HMath.DeepLearning.Layers.KaimingNormal" -> apply L.KaimingNormal arguments
    "HMath.DeepLearning.Layers.Orthogonal" -> apply L.Orthogonal arguments
    "HMath.DeepLearning.Layers.TruncatedNormal" -> apply L.TruncatedNormal arguments
    "HMath.DeepLearning.Layers.initializeWeights" -> apply L.initializeWeights arguments
    "HMath.DeepLearning.Layers.embedding" -> apply L.embedding arguments
    "HMath.DeepLearning.Layers.dense" -> apply L.dense arguments
    "HMath.DeepLearning.Layers.denseAD" -> apply L.denseAD arguments
    "HMath.DeepLearning.Layers.ConvOptions" -> apply L.ConvOptions arguments
    "HMath.DeepLearning.Layers.convolutionStride" -> apply L.convolutionStride arguments
    "HMath.DeepLearning.Layers.convolutionPadding" -> apply L.convolutionPadding arguments
    "HMath.DeepLearning.Layers.convolutionDilation" -> apply L.convolutionDilation arguments
    "HMath.DeepLearning.Layers.convolutionGroups" -> apply L.convolutionGroups arguments
    "HMath.DeepLearning.Layers.convolution" -> apply L.convolution arguments
    "HMath.DeepLearning.Layers.depthwiseConvolution" -> apply L.depthwiseConvolution arguments
    "HMath.DeepLearning.Layers.convolutionAD" -> apply L.convolutionAD arguments
    "HMath.DeepLearning.Layers.transposedConvolution" -> apply L.transposedConvolution arguments
    "HMath.DeepLearning.Layers.MaxPool" -> apply L.MaxPool arguments
    "HMath.DeepLearning.Layers.AveragePool" -> apply L.AveragePool arguments
    "HMath.DeepLearning.Layers.pooling" -> apply L.pooling arguments
    "HMath.DeepLearning.Layers.adaptivePooling" -> apply L.adaptivePooling arguments
    "HMath.DeepLearning.Layers.globalPooling" -> apply L.globalPooling arguments
    "HMath.DeepLearning.Layers.scaledDotProductAttention" -> apply L.scaledDotProductAttention arguments
    "HMath.DeepLearning.Layers.multiheadAttention" -> apply L.multiheadAttention arguments
    "HMath.DeepLearning.Layers.causalMask" -> apply L.causalMask arguments
    "HMath.DeepLearning.Layers.rotaryEmbedding" -> apply L.rotaryEmbedding arguments
    "HMath.DeepLearning.Layers.sinusoidalEncoding" -> apply L.sinusoidalEncoding arguments
    "HMath.DeepLearning.Layers.alibiBias" -> apply L.alibiBias arguments
    "HMath.DeepLearning.Layers.emptyCache" -> apply L.emptyCache arguments
    "HMath.DeepLearning.Layers.appendCache" -> apply L.appendCache arguments
    "HMath.DeepLearning.Layers.cacheValues" -> apply L.cacheValues arguments
    "HMath.DeepLearning.Layers.transformerFeedForward" -> apply L.transformerFeedForward arguments
    "HMath.DeepLearning.Layers.layerNormAD" -> apply L.layerNormAD arguments
    "HMath.DeepLearning.Layers.rmsNormAD" -> apply L.rmsNormAD arguments
    "HMath.DeepLearning.Layers.scaledDotProductAttentionAD" -> apply L.scaledDotProductAttentionAD arguments
    "HMath.DeepLearning.Precision.Symmetric" -> apply P.Symmetric arguments
    "HMath.DeepLearning.Precision.Asymmetric" -> apply P.Asymmetric arguments
    "HMath.DeepLearning.Precision.quantize" -> apply P.quantize arguments
    "HMath.DeepLearning.Precision.dequantize" -> apply P.dequantize arguments
    "HMath.DeepLearning.Precision.quantizedValues" -> apply P.quantizedValues arguments
    "HMath.DeepLearning.Precision.quantizationScales" -> apply P.quantizationScales arguments
    "HMath.DeepLearning.Precision.quantizationZeroPoints" -> apply P.quantizationZeroPoints arguments
    "HMath.DeepLearning.Precision.int8Gemm" -> apply P.int8Gemm arguments
    "HMath.DeepLearning.Precision.FP16" -> apply P.FP16 arguments
    "HMath.DeepLearning.Precision.BF16" -> apply P.BF16 arguments
    "HMath.DeepLearning.Precision.reducedGemm" -> apply P.reducedGemm arguments
    "HMath.DeepLearning.Precision.LossScaler" -> apply P.LossScaler arguments
    "HMath.DeepLearning.Precision.lossScale" -> apply P.lossScale arguments
    "HMath.DeepLearning.Precision.scaleGrowthInterval" -> apply P.scaleGrowthInterval arguments
    "HMath.DeepLearning.Precision.finiteSteps" -> apply P.finiteSteps arguments
    "HMath.DeepLearning.Precision.initialLossScaler" -> apply P.initialLossScaler arguments
    "HMath.DeepLearning.Precision.scaleLoss" -> apply P.scaleLoss arguments
    "HMath.DeepLearning.Precision.unscaleGradients" -> apply P.unscaleGradients arguments
    "HMath.DeepLearning.Precision.updateLossScaler" -> apply P.updateLossScaler arguments
    "HMath.DeepLearning.Precision.gradientNorm" -> apply P.gradientNorm arguments
    "HMath.DeepLearning.Precision.clipGradients" -> apply P.clipGradients arguments
    "HMath.DeepLearning.Metrics.ClassificationMetrics" -> apply M.ClassificationMetrics arguments
    "HMath.DeepLearning.Metrics.accuracy" -> apply M.accuracy arguments
    "HMath.DeepLearning.Metrics.precisionByClass" -> apply M.precisionByClass arguments
    "HMath.DeepLearning.Metrics.recallByClass" -> apply M.recallByClass arguments
    "HMath.DeepLearning.Metrics.f1ByClass" -> apply M.f1ByClass arguments
    "HMath.DeepLearning.Metrics.confusionMatrix" -> apply M.confusionMatrix arguments
    "HMath.DeepLearning.Metrics.classificationMetrics" -> apply M.classificationMetrics arguments
    "HMath.DeepLearning.Metrics.topKAccuracy" -> apply M.topKAccuracy arguments
    "HMath.DeepLearning.Metrics.rocAUC" -> apply M.rocAUC arguments
    "HMath.DeepLearning.Metrics.prAUC" -> apply M.prAUC arguments
    "HMath.DeepLearning.Metrics.perplexity" -> apply M.perplexity arguments
    "HMath.DeepLearning.Metrics.cosineSimilarityMatrix" -> apply M.cosineSimilarityMatrix arguments
    "HMath.DeepLearning.Metrics.marginRankingLoss" -> apply M.marginRankingLoss arguments
-- END GENERATED
    _ -> invalid "invalid neural operation"
