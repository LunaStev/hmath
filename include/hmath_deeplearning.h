/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_DEEPLEARNING_H
#define HMATH_DEEPLEARNING_H
#include "hmath_value.h"
#include "hmath_error.h"
#include "hmath_autodiff.h"
#include "hmath_tensor_bindings.h"
#ifdef __cplusplus
extern "C" {
#endif
/* All functions invoke original fixed-Double neural primitives. Tensor inputs
 * use actual original Tensor Double Value161; Float tensors are not silently
 * widened. ADExpr287/ADTensor288 share original graphs; RNG240 retains the full
 * explicit original random continuation. Constructor/method/state values are
 * immutable and independently owned. Release every Value output and nested
 * handle; preserve callback owners through AD interchange. Checked MathError
 * failures retain all21 constructors; outputs remain untouched on failure. */
/* BEGIN GENERATED */
/* HMath.DeepLearning.Core.Sigmoid -> Activation. */
HMATH_API hmath_status hmath_neural_core_sigmoid_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.Tanh -> Activation. */
HMATH_API hmath_status hmath_neural_core_tanh_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.ReLU -> Activation. */
HMATH_API hmath_status hmath_neural_core_relu_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.SELU -> Activation. */
HMATH_API hmath_status hmath_neural_core_selu_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.GELU -> Activation. */
HMATH_API hmath_status hmath_neural_core_gelu_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.SiLU -> Activation. */
HMATH_API hmath_status hmath_neural_core_silu_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.Mish -> Activation. */
HMATH_API hmath_status hmath_neural_core_mish_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.Softplus -> Activation. */
HMATH_API hmath_status hmath_neural_core_softplus_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.Softsign -> Activation. */
HMATH_API hmath_status hmath_neural_core_softsign_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.HardSigmoid -> Activation. */
HMATH_API hmath_status hmath_neural_core_hard_sigmoid_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.HardSwish -> Activation. */
HMATH_API hmath_status hmath_neural_core_hard_swish_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.LeakyReLU -> Activation. */
HMATH_API hmath_status hmath_neural_core_leaky_relu_create(
    hmath_context *context,
    const hmath_value *parameter,
    hmath_value **out);

/* HMath.DeepLearning.Core.PReLU -> Activation. */
HMATH_API hmath_status hmath_neural_core_prelu_create(
    hmath_context *context,
    const hmath_value *parameter,
    hmath_value **out);

/* HMath.DeepLearning.Core.ELU -> Activation. */
HMATH_API hmath_status hmath_neural_core_elu_create(
    hmath_context *context,
    const hmath_value *parameter,
    hmath_value **out);

/* HMath.DeepLearning.Core.Sum -> Reduction. */
HMATH_API hmath_status hmath_neural_core_sum_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.Mean -> Reduction. */
HMATH_API hmath_status hmath_neural_core_mean_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.MeanSquaredError -> Loss. */
HMATH_API hmath_status hmath_neural_core_mean_squared_error_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.MeanAbsoluteError -> Loss. */
HMATH_API hmath_status hmath_neural_core_mean_absolute_error_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.BinaryCrossEntropy -> Loss. */
HMATH_API hmath_status hmath_neural_core_binary_cross_entropy_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.CategoricalCrossEntropy -> Loss. */
HMATH_API hmath_status hmath_neural_core_categorical_cross_entropy_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.NegativeLogLikelihood -> Loss. */
HMATH_API hmath_status hmath_neural_core_negative_log_likelihood_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.KLDivergence -> Loss. */
HMATH_API hmath_status hmath_neural_core_kl_divergence_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.CosineLoss -> Loss. */
HMATH_API hmath_status hmath_neural_core_cosine_loss_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Core.Huber -> Loss. */
HMATH_API hmath_status hmath_neural_core_huber_create(
    hmath_context *context,
    const hmath_value *parameter,
    hmath_value **out);

/* HMath.DeepLearning.Core.SmoothL1 -> Loss. */
HMATH_API hmath_status hmath_neural_core_smooth_l1_create(
    hmath_context *context,
    const hmath_value *parameter,
    hmath_value **out);

/* HMath.DeepLearning.Core.Hinge -> Loss. */
HMATH_API hmath_status hmath_neural_core_hinge_create(
    hmath_context *context,
    const hmath_value *parameter,
    hmath_value **out);

/* HMath.DeepLearning.Core.activation -> Double. */
HMATH_API hmath_status hmath_neural_core_activation(
    hmath_context *context,
    const hmath_value *method,
    const hmath_value *value,
    hmath_value **out);

/* HMath.DeepLearning.Core.activationDerivative -> Double. */
HMATH_API hmath_status hmath_neural_core_activation_derivative(
    hmath_context *context,
    const hmath_value *method,
    const hmath_value *value,
    hmath_value **out);

/* HMath.DeepLearning.Core.activationExpr -> ADExpr. */
HMATH_API hmath_status hmath_neural_core_activation_expr(
    hmath_context *context,
    const hmath_value *method,
    const hmath_value *value,
    hmath_value **out);

/* HMath.DeepLearning.Core.softmax -> [Double]. */
HMATH_API hmath_status hmath_neural_core_softmax(
    hmath_context *context,
    const hmath_value *values,
    hmath_value **out);

/* HMath.DeepLearning.Core.logSoftmax -> [Double]. */
HMATH_API hmath_status hmath_neural_core_log_softmax(
    hmath_context *context,
    const hmath_value *values,
    hmath_value **out);

/* HMath.DeepLearning.Core.sparsemax -> [Double]. */
HMATH_API hmath_status hmath_neural_core_sparsemax(
    hmath_context *context,
    const hmath_value *values,
    hmath_value **out);

/* HMath.DeepLearning.Core.gatedLinearUnit -> [Double]. */
HMATH_API hmath_status hmath_neural_core_gated_linear_unit(
    hmath_context *context,
    const hmath_value *values,
    const hmath_value *gate,
    hmath_value **out);

/* HMath.DeepLearning.Core.softmaxExpr -> [ADExpr]. */
HMATH_API hmath_status hmath_neural_core_softmax_expr(
    hmath_context *context,
    const hmath_value *values,
    hmath_value **out);

/* HMath.DeepLearning.Core.logSoftmaxExpr -> [ADExpr]. */
HMATH_API hmath_status hmath_neural_core_log_softmax_expr(
    hmath_context *context,
    const hmath_value *values,
    hmath_value **out);

/* HMath.DeepLearning.Core.sparsemaxExpr -> [ADExpr]. */
HMATH_API hmath_status hmath_neural_core_sparsemax_expr(
    hmath_context *context,
    const hmath_value *values,
    hmath_value **out);

/* HMath.DeepLearning.Core.loss -> Double. */
HMATH_API hmath_status hmath_neural_core_loss(
    hmath_context *context,
    const hmath_value *method,
    const hmath_value *reduction,
    const hmath_value *target,
    const hmath_value *prediction,
    hmath_value **out);

/* HMath.DeepLearning.Core.lossGradient -> [Double]. */
HMATH_API hmath_status hmath_neural_core_loss_gradient(
    hmath_context *context,
    const hmath_value *method,
    const hmath_value *reduction,
    const hmath_value *target,
    const hmath_value *prediction,
    hmath_value **out);

/* HMath.DeepLearning.Core.lossExpr -> ADExpr. */
HMATH_API hmath_status hmath_neural_core_loss_expr(
    hmath_context *context,
    const hmath_value *method,
    const hmath_value *reduction,
    const hmath_value *target,
    const hmath_value *prediction,
    hmath_value **out);

/* HMath.DeepLearning.Core.binaryCrossEntropyLogits -> Double. */
HMATH_API hmath_status hmath_neural_core_binary_cross_entropy_logits(
    hmath_context *context,
    const hmath_value *reduction,
    const hmath_value *target,
    const hmath_value *logits,
    hmath_value **out);

/* HMath.DeepLearning.Core.categoricalCrossEntropyLogits -> Double. */
HMATH_API hmath_status hmath_neural_core_categorical_cross_entropy_logits(
    hmath_context *context,
    const hmath_value *target,
    const hmath_value *logits,
    hmath_value **out);

/* HMath.DeepLearning.Core.regularization -> Double. */
HMATH_API hmath_status hmath_neural_core_regularization(
    hmath_context *context,
    const hmath_value *l1,
    const hmath_value *l2,
    const hmath_value *weights,
    hmath_value **out);

/* HMath.DeepLearning.Core.contrastiveLoss -> Double. */
HMATH_API hmath_status hmath_neural_core_contrastive_loss(
    hmath_context *context,
    const hmath_value *margin,
    const hmath_value *similar,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out);

/* HMath.DeepLearning.Core.tripletLoss -> Double. */
HMATH_API hmath_status hmath_neural_core_triplet_loss(
    hmath_context *context,
    const hmath_value *margin,
    const hmath_value *anchor,
    const hmath_value *positive,
    const hmath_value *negative,
    hmath_value **out);

/* HMath.DeepLearning.Core.focalLoss -> Double. */
HMATH_API hmath_status hmath_neural_core_focal_loss(
    hmath_context *context,
    const hmath_value *alpha,
    const hmath_value *gamma,
    const hmath_value *target,
    const hmath_value *prediction,
    hmath_value **out);

/* HMath.DeepLearning.Core.diceLoss -> Double. */
HMATH_API hmath_status hmath_neural_core_dice_loss(
    hmath_context *context,
    const hmath_value *smooth,
    const hmath_value *target,
    const hmath_value *prediction,
    hmath_value **out);

/* HMath.DeepLearning.Core.iouLoss -> Double. */
HMATH_API hmath_status hmath_neural_core_iou_loss(
    hmath_context *context,
    const hmath_value *smooth,
    const hmath_value *target,
    const hmath_value *prediction,
    hmath_value **out);

/* HMath.DeepLearning.Core.ctcLoss -> Double. */
HMATH_API hmath_status hmath_neural_core_ctc_loss(
    hmath_context *context,
    const hmath_value *blank,
    const hmath_value *labels,
    const hmath_value *log_probabilities,
    hmath_value **out);

/* HMath.DeepLearning.Core.ctcLossGradient -> (Double,[[Double]]). */
HMATH_API hmath_status hmath_neural_core_ctc_loss_gradient(
    hmath_context *context,
    const hmath_value *blank,
    const hmath_value *labels,
    const hmath_value *log_probabilities,
    hmath_value **out);

/* HMath.DeepLearning.Core.ctcLossExpr -> ADExpr. */
HMATH_API hmath_status hmath_neural_core_ctc_loss_expr(
    hmath_context *context,
    const hmath_value *blank,
    const hmath_value *labels,
    const hmath_value *log_probabilities,
    hmath_value **out);

/* HMath.DeepLearning.Layers.Training -> Training. */
HMATH_API hmath_status hmath_neural_layers_training_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Layers.Inference -> Training. */
HMATH_API hmath_status hmath_neural_layers_inference_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Layers.dropout -> (Tensor,Tensor,RNG). */
HMATH_API hmath_status hmath_neural_layers_dropout(
    hmath_context *context,
    const hmath_value *mode,
    const hmath_value *probability,
    const hmath_value *rng,
    const hmath_value *input,
    hmath_value **out);

/* HMath.DeepLearning.Layers.spatialDropout -> (Tensor,Tensor,RNG). */
HMATH_API hmath_status hmath_neural_layers_spatial_dropout(
    hmath_context *context,
    const hmath_value *mode,
    const hmath_value *probability,
    const hmath_value *rng,
    const hmath_value *input,
    hmath_value **out);

/* HMath.DeepLearning.Layers.BatchNormState -> BatchNormState. */
HMATH_API hmath_status hmath_neural_layers_batch_norm_state_create(
    hmath_context *context,
    const hmath_value *running_mean,
    const hmath_value *running_variance,
    const hmath_value *batches_seen,
    hmath_value **out);

/* HMath.DeepLearning.Layers.runningMean -> [Double]. */
HMATH_API hmath_status hmath_neural_layers_running_mean(
    hmath_context *context,
    const hmath_value *state,
    hmath_value **out);

/* HMath.DeepLearning.Layers.runningVariance -> [Double]. */
HMATH_API hmath_status hmath_neural_layers_running_variance(
    hmath_context *context,
    const hmath_value *state,
    hmath_value **out);

/* HMath.DeepLearning.Layers.batchesSeen -> Int. */
HMATH_API hmath_status hmath_neural_layers_batches_seen(
    hmath_context *context,
    const hmath_value *state,
    hmath_value **out);

/* HMath.DeepLearning.Layers.batchNorm -> (Tensor,BatchNormState). */
HMATH_API hmath_status hmath_neural_layers_batch_norm(
    hmath_context *context,
    const hmath_value *mode,
    const hmath_value *momentum,
    const hmath_value *epsilon,
    const hmath_value *gamma,
    const hmath_value *beta,
    const hmath_value *state,
    const hmath_value *input,
    hmath_value **out);

/* HMath.DeepLearning.Layers.layerNorm -> Tensor. */
HMATH_API hmath_status hmath_neural_layers_layer_norm(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *epsilon,
    const hmath_value *input,
    hmath_value **out);

/* HMath.DeepLearning.Layers.rmsNorm -> Tensor. */
HMATH_API hmath_status hmath_neural_layers_rms_norm(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *epsilon,
    const hmath_value *input,
    hmath_value **out);

/* HMath.DeepLearning.Layers.instanceNorm -> Tensor. */
HMATH_API hmath_status hmath_neural_layers_instance_norm(
    hmath_context *context,
    const hmath_value *epsilon,
    const hmath_value *input,
    hmath_value **out);

/* HMath.DeepLearning.Layers.groupNorm -> Tensor. */
HMATH_API hmath_status hmath_neural_layers_group_norm(
    hmath_context *context,
    const hmath_value *groups,
    const hmath_value *epsilon,
    const hmath_value *input,
    hmath_value **out);

/* HMath.DeepLearning.Layers.weightNorm -> Tensor. */
HMATH_API hmath_status hmath_neural_layers_weight_norm(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *scales,
    const hmath_value *input,
    hmath_value **out);

/* HMath.DeepLearning.Layers.XavierUniform -> Initializer. */
HMATH_API hmath_status hmath_neural_layers_xavier_uniform_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Layers.XavierNormal -> Initializer. */
HMATH_API hmath_status hmath_neural_layers_xavier_normal_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Layers.KaimingUniform -> Initializer. */
HMATH_API hmath_status hmath_neural_layers_kaiming_uniform_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Layers.KaimingNormal -> Initializer. */
HMATH_API hmath_status hmath_neural_layers_kaiming_normal_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Layers.Orthogonal -> Initializer. */
HMATH_API hmath_status hmath_neural_layers_orthogonal_create(
    hmath_context *context,
    const hmath_value *scale,
    hmath_value **out);

/* HMath.DeepLearning.Layers.TruncatedNormal -> Initializer. */
HMATH_API hmath_status hmath_neural_layers_truncated_normal_create(
    hmath_context *context,
    const hmath_value *mean,
    const hmath_value *standard_deviation,
    const hmath_value *bound,
    hmath_value **out);

/* HMath.DeepLearning.Layers.initializeWeights -> (Tensor,RNG). */
HMATH_API hmath_status hmath_neural_layers_initialize_weights(
    hmath_context *context,
    const hmath_value *method,
    const hmath_value *fan_in,
    const hmath_value *fan_out,
    const hmath_value *shape,
    const hmath_value *rng,
    hmath_value **out);

/* HMath.DeepLearning.Layers.embedding -> Tensor. */
HMATH_API hmath_status hmath_neural_layers_embedding(
    hmath_context *context,
    const hmath_value *weights,
    const hmath_value *indices,
    hmath_value **out);

/* HMath.DeepLearning.Layers.dense -> Tensor. */
HMATH_API hmath_status hmath_neural_layers_dense(
    hmath_context *context,
    const hmath_value *input,
    const hmath_value *weights,
    const hmath_value *bias,
    hmath_value **out);

/* HMath.DeepLearning.Layers.denseAD -> ADTensor. */
HMATH_API hmath_status hmath_neural_layers_dense_ad(
    hmath_context *context,
    const hmath_value *input,
    const hmath_value *weights,
    const hmath_value *bias,
    hmath_value **out);

/* HMath.DeepLearning.Layers.ConvOptions -> ConvOptions. */
HMATH_API hmath_status hmath_neural_layers_conv_options_create(
    hmath_context *context,
    const hmath_value *stride,
    const hmath_value *padding,
    const hmath_value *dilation,
    const hmath_value *groups,
    hmath_value **out);

/* HMath.DeepLearning.Layers.convolutionStride -> [Int]. */
HMATH_API hmath_status hmath_neural_layers_convolution_stride(
    hmath_context *context,
    const hmath_value *options,
    hmath_value **out);

/* HMath.DeepLearning.Layers.convolutionPadding -> [Int]. */
HMATH_API hmath_status hmath_neural_layers_convolution_padding(
    hmath_context *context,
    const hmath_value *options,
    hmath_value **out);

/* HMath.DeepLearning.Layers.convolutionDilation -> [Int]. */
HMATH_API hmath_status hmath_neural_layers_convolution_dilation(
    hmath_context *context,
    const hmath_value *options,
    hmath_value **out);

/* HMath.DeepLearning.Layers.convolutionGroups -> Int. */
HMATH_API hmath_status hmath_neural_layers_convolution_groups(
    hmath_context *context,
    const hmath_value *options,
    hmath_value **out);

/* HMath.DeepLearning.Layers.convolution -> Tensor. */
HMATH_API hmath_status hmath_neural_layers_convolution(
    hmath_context *context,
    const hmath_value *options,
    const hmath_value *input,
    const hmath_value *weights,
    const hmath_value *bias,
    hmath_value **out);

/* HMath.DeepLearning.Layers.depthwiseConvolution -> Tensor. */
HMATH_API hmath_status hmath_neural_layers_depthwise_convolution(
    hmath_context *context,
    const hmath_value *options,
    const hmath_value *input,
    const hmath_value *weights,
    const hmath_value *bias,
    hmath_value **out);

/* HMath.DeepLearning.Layers.convolutionAD -> ADTensor. */
HMATH_API hmath_status hmath_neural_layers_convolution_ad(
    hmath_context *context,
    const hmath_value *options,
    const hmath_value *input,
    const hmath_value *weights,
    const hmath_value *bias,
    hmath_value **out);

/* HMath.DeepLearning.Layers.transposedConvolution -> Tensor. */
HMATH_API hmath_status hmath_neural_layers_transposed_convolution(
    hmath_context *context,
    const hmath_value *output_padding,
    const hmath_value *options,
    const hmath_value *input,
    const hmath_value *weights,
    const hmath_value *bias,
    hmath_value **out);

/* HMath.DeepLearning.Layers.MaxPool -> PoolMode. */
HMATH_API hmath_status hmath_neural_layers_max_pool_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Layers.AveragePool -> PoolMode. */
HMATH_API hmath_status hmath_neural_layers_average_pool_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Layers.pooling -> Tensor. */
HMATH_API hmath_status hmath_neural_layers_pooling(
    hmath_context *context,
    const hmath_value *mode,
    const hmath_value *kernel,
    const hmath_value *stride,
    const hmath_value *padding,
    const hmath_value *input,
    hmath_value **out);

/* HMath.DeepLearning.Layers.adaptivePooling -> Tensor. */
HMATH_API hmath_status hmath_neural_layers_adaptive_pooling(
    hmath_context *context,
    const hmath_value *mode,
    const hmath_value *shape,
    const hmath_value *input,
    hmath_value **out);

/* HMath.DeepLearning.Layers.globalPooling -> Tensor. */
HMATH_API hmath_status hmath_neural_layers_global_pooling(
    hmath_context *context,
    const hmath_value *mode,
    const hmath_value *input,
    hmath_value **out);

/* HMath.DeepLearning.Layers.scaledDotProductAttention -> (Tensor,Tensor). */
HMATH_API hmath_status hmath_neural_layers_scaled_dot_product_attention(
    hmath_context *context,
    const hmath_value *query,
    const hmath_value *key,
    const hmath_value *value,
    const hmath_value *mask,
    const hmath_value *bias,
    hmath_value **out);

/* HMath.DeepLearning.Layers.multiheadAttention -> Tensor. */
HMATH_API hmath_status hmath_neural_layers_multihead_attention(
    hmath_context *context,
    const hmath_value *heads,
    const hmath_value *query,
    const hmath_value *key,
    const hmath_value *value,
    const hmath_value *mask,
    hmath_value **out);

/* HMath.DeepLearning.Layers.causalMask -> [[Bool]]. */
HMATH_API hmath_status hmath_neural_layers_causal_mask(
    hmath_context *context,
    const hmath_value *queries,
    const hmath_value *keys,
    const hmath_value *offset,
    hmath_value **out);

/* HMath.DeepLearning.Layers.rotaryEmbedding -> Tensor. */
HMATH_API hmath_status hmath_neural_layers_rotary_embedding(
    hmath_context *context,
    const hmath_value *base,
    const hmath_value *offset,
    const hmath_value *input,
    hmath_value **out);

/* HMath.DeepLearning.Layers.sinusoidalEncoding -> Tensor. */
HMATH_API hmath_status hmath_neural_layers_sinusoidal_encoding(
    hmath_context *context,
    const hmath_value *length,
    const hmath_value *dimensions,
    const hmath_value *offset,
    hmath_value **out);

/* HMath.DeepLearning.Layers.alibiBias -> [[Double]]. */
HMATH_API hmath_status hmath_neural_layers_alibi_bias(
    hmath_context *context,
    const hmath_value *slope,
    const hmath_value *queries,
    const hmath_value *keys,
    const hmath_value *offset,
    hmath_value **out);

/* HMath.DeepLearning.Layers.emptyCache -> KVCache. */
HMATH_API hmath_status hmath_neural_layers_empty_cache(
    hmath_context *context,
    const hmath_value *capacity,
    const hmath_value *key_dimensions,
    const hmath_value *value_dimensions,
    hmath_value **out);

/* HMath.DeepLearning.Layers.appendCache -> KVCache. */
HMATH_API hmath_status hmath_neural_layers_append_cache(
    hmath_context *context,
    const hmath_value *cache,
    const hmath_value *key,
    const hmath_value *value,
    hmath_value **out);

/* HMath.DeepLearning.Layers.cacheValues -> (Tensor,Tensor). */
HMATH_API hmath_status hmath_neural_layers_cache_values(
    hmath_context *context,
    const hmath_value *cache,
    hmath_value **out);

/* HMath.DeepLearning.Layers.transformerFeedForward -> Tensor. */
HMATH_API hmath_status hmath_neural_layers_transformer_feed_forward(
    hmath_context *context,
    const hmath_value *activation,
    const hmath_value *input,
    const hmath_value *first_weights,
    const hmath_value *first_bias,
    const hmath_value *second_weights,
    const hmath_value *second_bias,
    hmath_value **out);

/* HMath.DeepLearning.Layers.layerNormAD -> ADTensor. */
HMATH_API hmath_status hmath_neural_layers_layer_norm_ad(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *epsilon,
    const hmath_value *input,
    hmath_value **out);

/* HMath.DeepLearning.Layers.rmsNormAD -> ADTensor. */
HMATH_API hmath_status hmath_neural_layers_rms_norm_ad(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *epsilon,
    const hmath_value *input,
    hmath_value **out);

/* HMath.DeepLearning.Layers.scaledDotProductAttentionAD -> ADTensor. */
HMATH_API hmath_status hmath_neural_layers_scaled_dot_product_attention_ad(
    hmath_context *context,
    const hmath_value *query,
    const hmath_value *key,
    const hmath_value *value,
    const hmath_value *mask,
    hmath_value **out);

/* HMath.DeepLearning.Precision.Symmetric -> Quantization. */
HMATH_API hmath_status hmath_neural_precision_symmetric_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Precision.Asymmetric -> Quantization. */
HMATH_API hmath_status hmath_neural_precision_asymmetric_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Precision.quantize -> QuantizedTensor. */
HMATH_API hmath_status hmath_neural_precision_quantize(
    hmath_context *context,
    const hmath_value *scheme,
    const hmath_value *axis,
    const hmath_value *input,
    hmath_value **out);

/* HMath.DeepLearning.Precision.dequantize -> Tensor. */
HMATH_API hmath_status hmath_neural_precision_dequantize(
    hmath_context *context,
    const hmath_value *quantized,
    hmath_value **out);

/* HMath.DeepLearning.Precision.quantizedValues -> [Int8]. */
HMATH_API hmath_status hmath_neural_precision_quantized_values(
    hmath_context *context,
    const hmath_value *quantized,
    hmath_value **out);

/* HMath.DeepLearning.Precision.quantizationScales -> [Double]. */
HMATH_API hmath_status hmath_neural_precision_quantization_scales(
    hmath_context *context,
    const hmath_value *quantized,
    hmath_value **out);

/* HMath.DeepLearning.Precision.quantizationZeroPoints -> [Int]. */
HMATH_API hmath_status hmath_neural_precision_quantization_zero_points(
    hmath_context *context,
    const hmath_value *quantized,
    hmath_value **out);

/* HMath.DeepLearning.Precision.int8Gemm -> Tensor. */
HMATH_API hmath_status hmath_neural_precision_int8_gemm(
    hmath_context *context,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out);

/* HMath.DeepLearning.Precision.FP16 -> Precision. */
HMATH_API hmath_status hmath_neural_precision_fp16_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Precision.BF16 -> Precision. */
HMATH_API hmath_status hmath_neural_precision_bf16_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.DeepLearning.Precision.reducedGemm -> Tensor. */
HMATH_API hmath_status hmath_neural_precision_reduced_gemm(
    hmath_context *context,
    const hmath_value *precision,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out);

/* HMath.DeepLearning.Precision.LossScaler -> LossScaler. */
HMATH_API hmath_status hmath_neural_precision_loss_scaler_create(
    hmath_context *context,
    const hmath_value *scale,
    const hmath_value *growth_interval,
    const hmath_value *finite_steps,
    hmath_value **out);

/* HMath.DeepLearning.Precision.lossScale -> Double. */
HMATH_API hmath_status hmath_neural_precision_loss_scale(
    hmath_context *context,
    const hmath_value *state,
    hmath_value **out);

/* HMath.DeepLearning.Precision.scaleGrowthInterval -> Int. */
HMATH_API hmath_status hmath_neural_precision_scale_growth_interval(
    hmath_context *context,
    const hmath_value *state,
    hmath_value **out);

/* HMath.DeepLearning.Precision.finiteSteps -> Int. */
HMATH_API hmath_status hmath_neural_precision_finite_steps(
    hmath_context *context,
    const hmath_value *state,
    hmath_value **out);

/* HMath.DeepLearning.Precision.initialLossScaler -> LossScaler. */
HMATH_API hmath_status hmath_neural_precision_initial_loss_scaler(
    hmath_context *context,
    const hmath_value *scale,
    const hmath_value *growth_interval,
    hmath_value **out);

/* HMath.DeepLearning.Precision.scaleLoss -> Double. */
HMATH_API hmath_status hmath_neural_precision_scale_loss(
    hmath_context *context,
    const hmath_value *state,
    const hmath_value *loss,
    hmath_value **out);

/* HMath.DeepLearning.Precision.unscaleGradients -> (Bool,[Double]). */
HMATH_API hmath_status hmath_neural_precision_unscale_gradients(
    hmath_context *context,
    const hmath_value *state,
    const hmath_value *gradients,
    hmath_value **out);

/* HMath.DeepLearning.Precision.updateLossScaler -> LossScaler. */
HMATH_API hmath_status hmath_neural_precision_update_loss_scaler(
    hmath_context *context,
    const hmath_value *finite,
    const hmath_value *state,
    hmath_value **out);

/* HMath.DeepLearning.Precision.gradientNorm -> Double. */
HMATH_API hmath_status hmath_neural_precision_gradient_norm(
    hmath_context *context,
    const hmath_value *gradient,
    hmath_value **out);

/* HMath.DeepLearning.Precision.clipGradients -> [Double]. */
HMATH_API hmath_status hmath_neural_precision_clip_gradients(
    hmath_context *context,
    const hmath_value *maximum,
    const hmath_value *gradient,
    hmath_value **out);

/* HMath.DeepLearning.Metrics.ClassificationMetrics -> ClassificationMetrics. */
HMATH_API hmath_status hmath_neural_metrics_classification_metrics_create(
    hmath_context *context,
    const hmath_value *accuracy,
    const hmath_value *precision,
    const hmath_value *recall,
    const hmath_value *f1,
    hmath_value **out);

/* HMath.DeepLearning.Metrics.accuracy -> Double. */
HMATH_API hmath_status hmath_neural_metrics_accuracy(
    hmath_context *context,
    const hmath_value *metrics,
    hmath_value **out);

/* HMath.DeepLearning.Metrics.precisionByClass -> [Double]. */
HMATH_API hmath_status hmath_neural_metrics_precision_by_class(
    hmath_context *context,
    const hmath_value *metrics,
    hmath_value **out);

/* HMath.DeepLearning.Metrics.recallByClass -> [Double]. */
HMATH_API hmath_status hmath_neural_metrics_recall_by_class(
    hmath_context *context,
    const hmath_value *metrics,
    hmath_value **out);

/* HMath.DeepLearning.Metrics.f1ByClass -> [Double]. */
HMATH_API hmath_status hmath_neural_metrics_f1_by_class(
    hmath_context *context,
    const hmath_value *metrics,
    hmath_value **out);

/* HMath.DeepLearning.Metrics.confusionMatrix -> [[Int]]. */
HMATH_API hmath_status hmath_neural_metrics_confusion_matrix(
    hmath_context *context,
    const hmath_value *classes,
    const hmath_value *truth,
    const hmath_value *prediction,
    hmath_value **out);

/* HMath.DeepLearning.Metrics.classificationMetrics -> ClassificationMetrics. */
HMATH_API hmath_status hmath_neural_metrics_classification_metrics(
    hmath_context *context,
    const hmath_value *classes,
    const hmath_value *truth,
    const hmath_value *prediction,
    hmath_value **out);

/* HMath.DeepLearning.Metrics.topKAccuracy -> Double. */
HMATH_API hmath_status hmath_neural_metrics_top_k_accuracy(
    hmath_context *context,
    const hmath_value *k,
    const hmath_value *truth,
    const hmath_value *scores,
    hmath_value **out);

/* HMath.DeepLearning.Metrics.rocAUC -> Double. */
HMATH_API hmath_status hmath_neural_metrics_roc_auc(
    hmath_context *context,
    const hmath_value *truth,
    const hmath_value *scores,
    hmath_value **out);

/* HMath.DeepLearning.Metrics.prAUC -> Double. */
HMATH_API hmath_status hmath_neural_metrics_pr_auc(
    hmath_context *context,
    const hmath_value *truth,
    const hmath_value *scores,
    hmath_value **out);

/* HMath.DeepLearning.Metrics.perplexity -> Double. */
HMATH_API hmath_status hmath_neural_metrics_perplexity(
    hmath_context *context,
    const hmath_value *negative_log_probabilities,
    hmath_value **out);

/* HMath.DeepLearning.Metrics.cosineSimilarityMatrix -> Tensor. */
HMATH_API hmath_status hmath_neural_metrics_cosine_similarity_matrix(
    hmath_context *context,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out);

/* HMath.DeepLearning.Metrics.marginRankingLoss -> Double. */
HMATH_API hmath_status hmath_neural_metrics_margin_ranking_loss(
    hmath_context *context,
    const hmath_value *margin,
    const hmath_value *left,
    const hmath_value *right,
    const hmath_value *labels,
    hmath_value **out);
/* END GENERATED */
#ifdef __cplusplus
}
#endif
#endif
