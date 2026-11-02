/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_deeplearning.h"
#include "value_internal.h"
#include <stdlib.h>
extern int hm_neural_apply(const char *,void *const *,size_t,void **);
static hmath_status invoke(hmath_context *context,const char *name,const hmath_value *const *arguments,size_t count,hmath_value **out) {
    if(!out || (count && !arguments))return hm_error(HMATH_INVALID_ARGUMENT,"NULL neural argument/output");
    if(count>(size_t)PTRDIFF_MAX/sizeof(void *))return hm_error(HMATH_OVERFLOW,"neural argument span overflow");
    for(size_t i=0;i<count;++i)if(!arguments[i])return hm_error(HMATH_INVALID_ARGUMENT,"NULL neural Value");
    void **stable=malloc((count?count:1)*sizeof *stable);
    if(!stable)return hm_error(HMATH_ALLOCATION_FAILED,"neural argument allocation failed");
    for(size_t i=0;i<count;++i)stable[i]=hm_value_stable(arguments[i]);
    hmath_value *result;
    hmath_status status=hm_value_begin(context,&result);
    if(status){free(stable);return status;}
    int code=hm_neural_apply(name,stable,count,&result->stable);
    free(stable);
    return hm_value_finish(result,code,out);
}
/* BEGIN GENERATED */
hmath_status hmath_neural_core_sigmoid_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.Sigmoid", NULL, 0, out);
}

hmath_status hmath_neural_core_tanh_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.Tanh", NULL, 0, out);
}

hmath_status hmath_neural_core_relu_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.ReLU", NULL, 0, out);
}

hmath_status hmath_neural_core_selu_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.SELU", NULL, 0, out);
}

hmath_status hmath_neural_core_gelu_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.GELU", NULL, 0, out);
}

hmath_status hmath_neural_core_silu_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.SiLU", NULL, 0, out);
}

hmath_status hmath_neural_core_mish_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.Mish", NULL, 0, out);
}

hmath_status hmath_neural_core_softplus_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.Softplus", NULL, 0, out);
}

hmath_status hmath_neural_core_softsign_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.Softsign", NULL, 0, out);
}

hmath_status hmath_neural_core_hard_sigmoid_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.HardSigmoid", NULL, 0, out);
}

hmath_status hmath_neural_core_hard_swish_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.HardSwish", NULL, 0, out);
}

hmath_status hmath_neural_core_leaky_relu_create(
    hmath_context *context,
    const hmath_value *parameter,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={parameter};
    return invoke(context, "HMath.DeepLearning.Core.LeakyReLU", hm_arguments, 1, out);
}

hmath_status hmath_neural_core_prelu_create(
    hmath_context *context,
    const hmath_value *parameter,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={parameter};
    return invoke(context, "HMath.DeepLearning.Core.PReLU", hm_arguments, 1, out);
}

hmath_status hmath_neural_core_elu_create(
    hmath_context *context,
    const hmath_value *parameter,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={parameter};
    return invoke(context, "HMath.DeepLearning.Core.ELU", hm_arguments, 1, out);
}

hmath_status hmath_neural_core_sum_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.Sum", NULL, 0, out);
}

hmath_status hmath_neural_core_mean_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.Mean", NULL, 0, out);
}

hmath_status hmath_neural_core_mean_squared_error_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.MeanSquaredError", NULL, 0, out);
}

hmath_status hmath_neural_core_mean_absolute_error_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.MeanAbsoluteError", NULL, 0, out);
}

hmath_status hmath_neural_core_binary_cross_entropy_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.BinaryCrossEntropy", NULL, 0, out);
}

hmath_status hmath_neural_core_categorical_cross_entropy_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.CategoricalCrossEntropy", NULL, 0, out);
}

hmath_status hmath_neural_core_negative_log_likelihood_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.NegativeLogLikelihood", NULL, 0, out);
}

hmath_status hmath_neural_core_kl_divergence_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.KLDivergence", NULL, 0, out);
}

hmath_status hmath_neural_core_cosine_loss_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Core.CosineLoss", NULL, 0, out);
}

hmath_status hmath_neural_core_huber_create(
    hmath_context *context,
    const hmath_value *parameter,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={parameter};
    return invoke(context, "HMath.DeepLearning.Core.Huber", hm_arguments, 1, out);
}

hmath_status hmath_neural_core_smooth_l1_create(
    hmath_context *context,
    const hmath_value *parameter,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={parameter};
    return invoke(context, "HMath.DeepLearning.Core.SmoothL1", hm_arguments, 1, out);
}

hmath_status hmath_neural_core_hinge_create(
    hmath_context *context,
    const hmath_value *parameter,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={parameter};
    return invoke(context, "HMath.DeepLearning.Core.Hinge", hm_arguments, 1, out);
}

hmath_status hmath_neural_core_activation(
    hmath_context *context,
    const hmath_value *method,
    const hmath_value *value,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={method, value};
    return invoke(context, "HMath.DeepLearning.Core.activation", hm_arguments, 2, out);
}

hmath_status hmath_neural_core_activation_derivative(
    hmath_context *context,
    const hmath_value *method,
    const hmath_value *value,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={method, value};
    return invoke(context, "HMath.DeepLearning.Core.activationDerivative", hm_arguments, 2, out);
}

hmath_status hmath_neural_core_activation_expr(
    hmath_context *context,
    const hmath_value *method,
    const hmath_value *value,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={method, value};
    return invoke(context, "HMath.DeepLearning.Core.activationExpr", hm_arguments, 2, out);
}

hmath_status hmath_neural_core_softmax(
    hmath_context *context,
    const hmath_value *values,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={values};
    return invoke(context, "HMath.DeepLearning.Core.softmax", hm_arguments, 1, out);
}

hmath_status hmath_neural_core_log_softmax(
    hmath_context *context,
    const hmath_value *values,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={values};
    return invoke(context, "HMath.DeepLearning.Core.logSoftmax", hm_arguments, 1, out);
}

hmath_status hmath_neural_core_sparsemax(
    hmath_context *context,
    const hmath_value *values,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={values};
    return invoke(context, "HMath.DeepLearning.Core.sparsemax", hm_arguments, 1, out);
}

hmath_status hmath_neural_core_gated_linear_unit(
    hmath_context *context,
    const hmath_value *values,
    const hmath_value *gate,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={values, gate};
    return invoke(context, "HMath.DeepLearning.Core.gatedLinearUnit", hm_arguments, 2, out);
}

hmath_status hmath_neural_core_softmax_expr(
    hmath_context *context,
    const hmath_value *values,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={values};
    return invoke(context, "HMath.DeepLearning.Core.softmaxExpr", hm_arguments, 1, out);
}

hmath_status hmath_neural_core_log_softmax_expr(
    hmath_context *context,
    const hmath_value *values,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={values};
    return invoke(context, "HMath.DeepLearning.Core.logSoftmaxExpr", hm_arguments, 1, out);
}

hmath_status hmath_neural_core_sparsemax_expr(
    hmath_context *context,
    const hmath_value *values,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={values};
    return invoke(context, "HMath.DeepLearning.Core.sparsemaxExpr", hm_arguments, 1, out);
}

hmath_status hmath_neural_core_loss(
    hmath_context *context,
    const hmath_value *method,
    const hmath_value *reduction,
    const hmath_value *target,
    const hmath_value *prediction,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={method, reduction, target, prediction};
    return invoke(context, "HMath.DeepLearning.Core.loss", hm_arguments, 4, out);
}

hmath_status hmath_neural_core_loss_gradient(
    hmath_context *context,
    const hmath_value *method,
    const hmath_value *reduction,
    const hmath_value *target,
    const hmath_value *prediction,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={method, reduction, target, prediction};
    return invoke(context, "HMath.DeepLearning.Core.lossGradient", hm_arguments, 4, out);
}

hmath_status hmath_neural_core_loss_expr(
    hmath_context *context,
    const hmath_value *method,
    const hmath_value *reduction,
    const hmath_value *target,
    const hmath_value *prediction,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={method, reduction, target, prediction};
    return invoke(context, "HMath.DeepLearning.Core.lossExpr", hm_arguments, 4, out);
}

hmath_status hmath_neural_core_binary_cross_entropy_logits(
    hmath_context *context,
    const hmath_value *reduction,
    const hmath_value *target,
    const hmath_value *logits,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={reduction, target, logits};
    return invoke(context, "HMath.DeepLearning.Core.binaryCrossEntropyLogits", hm_arguments, 3, out);
}

hmath_status hmath_neural_core_categorical_cross_entropy_logits(
    hmath_context *context,
    const hmath_value *target,
    const hmath_value *logits,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={target, logits};
    return invoke(context, "HMath.DeepLearning.Core.categoricalCrossEntropyLogits", hm_arguments, 2, out);
}

hmath_status hmath_neural_core_regularization(
    hmath_context *context,
    const hmath_value *l1,
    const hmath_value *l2,
    const hmath_value *weights,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={l1, l2, weights};
    return invoke(context, "HMath.DeepLearning.Core.regularization", hm_arguments, 3, out);
}

hmath_status hmath_neural_core_contrastive_loss(
    hmath_context *context,
    const hmath_value *margin,
    const hmath_value *similar,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={margin, similar, left, right};
    return invoke(context, "HMath.DeepLearning.Core.contrastiveLoss", hm_arguments, 4, out);
}

hmath_status hmath_neural_core_triplet_loss(
    hmath_context *context,
    const hmath_value *margin,
    const hmath_value *anchor,
    const hmath_value *positive,
    const hmath_value *negative,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={margin, anchor, positive, negative};
    return invoke(context, "HMath.DeepLearning.Core.tripletLoss", hm_arguments, 4, out);
}

hmath_status hmath_neural_core_focal_loss(
    hmath_context *context,
    const hmath_value *alpha,
    const hmath_value *gamma,
    const hmath_value *target,
    const hmath_value *prediction,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={alpha, gamma, target, prediction};
    return invoke(context, "HMath.DeepLearning.Core.focalLoss", hm_arguments, 4, out);
}

hmath_status hmath_neural_core_dice_loss(
    hmath_context *context,
    const hmath_value *smooth,
    const hmath_value *target,
    const hmath_value *prediction,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={smooth, target, prediction};
    return invoke(context, "HMath.DeepLearning.Core.diceLoss", hm_arguments, 3, out);
}

hmath_status hmath_neural_core_iou_loss(
    hmath_context *context,
    const hmath_value *smooth,
    const hmath_value *target,
    const hmath_value *prediction,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={smooth, target, prediction};
    return invoke(context, "HMath.DeepLearning.Core.iouLoss", hm_arguments, 3, out);
}

hmath_status hmath_neural_core_ctc_loss(
    hmath_context *context,
    const hmath_value *blank,
    const hmath_value *labels,
    const hmath_value *log_probabilities,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={blank, labels, log_probabilities};
    return invoke(context, "HMath.DeepLearning.Core.ctcLoss", hm_arguments, 3, out);
}

hmath_status hmath_neural_core_ctc_loss_gradient(
    hmath_context *context,
    const hmath_value *blank,
    const hmath_value *labels,
    const hmath_value *log_probabilities,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={blank, labels, log_probabilities};
    return invoke(context, "HMath.DeepLearning.Core.ctcLossGradient", hm_arguments, 3, out);
}

hmath_status hmath_neural_core_ctc_loss_expr(
    hmath_context *context,
    const hmath_value *blank,
    const hmath_value *labels,
    const hmath_value *log_probabilities,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={blank, labels, log_probabilities};
    return invoke(context, "HMath.DeepLearning.Core.ctcLossExpr", hm_arguments, 3, out);
}

hmath_status hmath_neural_layers_training_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Layers.Training", NULL, 0, out);
}

hmath_status hmath_neural_layers_inference_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Layers.Inference", NULL, 0, out);
}

hmath_status hmath_neural_layers_dropout(
    hmath_context *context,
    const hmath_value *mode,
    const hmath_value *probability,
    const hmath_value *rng,
    const hmath_value *input,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={mode, probability, rng, input};
    return invoke(context, "HMath.DeepLearning.Layers.dropout", hm_arguments, 4, out);
}

hmath_status hmath_neural_layers_spatial_dropout(
    hmath_context *context,
    const hmath_value *mode,
    const hmath_value *probability,
    const hmath_value *rng,
    const hmath_value *input,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={mode, probability, rng, input};
    return invoke(context, "HMath.DeepLearning.Layers.spatialDropout", hm_arguments, 4, out);
}

hmath_status hmath_neural_layers_batch_norm_state_create(
    hmath_context *context,
    const hmath_value *running_mean,
    const hmath_value *running_variance,
    const hmath_value *batches_seen,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={running_mean, running_variance, batches_seen};
    return invoke(context, "HMath.DeepLearning.Layers.BatchNormState", hm_arguments, 3, out);
}

hmath_status hmath_neural_layers_running_mean(
    hmath_context *context,
    const hmath_value *state,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={state};
    return invoke(context, "HMath.DeepLearning.Layers.runningMean", hm_arguments, 1, out);
}

hmath_status hmath_neural_layers_running_variance(
    hmath_context *context,
    const hmath_value *state,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={state};
    return invoke(context, "HMath.DeepLearning.Layers.runningVariance", hm_arguments, 1, out);
}

hmath_status hmath_neural_layers_batches_seen(
    hmath_context *context,
    const hmath_value *state,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={state};
    return invoke(context, "HMath.DeepLearning.Layers.batchesSeen", hm_arguments, 1, out);
}

hmath_status hmath_neural_layers_batch_norm(
    hmath_context *context,
    const hmath_value *mode,
    const hmath_value *momentum,
    const hmath_value *epsilon,
    const hmath_value *gamma,
    const hmath_value *beta,
    const hmath_value *state,
    const hmath_value *input,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={mode, momentum, epsilon, gamma, beta, state, input};
    return invoke(context, "HMath.DeepLearning.Layers.batchNorm", hm_arguments, 7, out);
}

hmath_status hmath_neural_layers_layer_norm(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *epsilon,
    const hmath_value *input,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={axes, epsilon, input};
    return invoke(context, "HMath.DeepLearning.Layers.layerNorm", hm_arguments, 3, out);
}

hmath_status hmath_neural_layers_rms_norm(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *epsilon,
    const hmath_value *input,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={axes, epsilon, input};
    return invoke(context, "HMath.DeepLearning.Layers.rmsNorm", hm_arguments, 3, out);
}

hmath_status hmath_neural_layers_instance_norm(
    hmath_context *context,
    const hmath_value *epsilon,
    const hmath_value *input,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={epsilon, input};
    return invoke(context, "HMath.DeepLearning.Layers.instanceNorm", hm_arguments, 2, out);
}

hmath_status hmath_neural_layers_group_norm(
    hmath_context *context,
    const hmath_value *groups,
    const hmath_value *epsilon,
    const hmath_value *input,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={groups, epsilon, input};
    return invoke(context, "HMath.DeepLearning.Layers.groupNorm", hm_arguments, 3, out);
}

hmath_status hmath_neural_layers_weight_norm(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *scales,
    const hmath_value *input,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={axis, scales, input};
    return invoke(context, "HMath.DeepLearning.Layers.weightNorm", hm_arguments, 3, out);
}

hmath_status hmath_neural_layers_xavier_uniform_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Layers.XavierUniform", NULL, 0, out);
}

hmath_status hmath_neural_layers_xavier_normal_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Layers.XavierNormal", NULL, 0, out);
}

hmath_status hmath_neural_layers_kaiming_uniform_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Layers.KaimingUniform", NULL, 0, out);
}

hmath_status hmath_neural_layers_kaiming_normal_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Layers.KaimingNormal", NULL, 0, out);
}

hmath_status hmath_neural_layers_orthogonal_create(
    hmath_context *context,
    const hmath_value *scale,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={scale};
    return invoke(context, "HMath.DeepLearning.Layers.Orthogonal", hm_arguments, 1, out);
}

hmath_status hmath_neural_layers_truncated_normal_create(
    hmath_context *context,
    const hmath_value *mean,
    const hmath_value *standard_deviation,
    const hmath_value *bound,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={mean, standard_deviation, bound};
    return invoke(context, "HMath.DeepLearning.Layers.TruncatedNormal", hm_arguments, 3, out);
}

hmath_status hmath_neural_layers_initialize_weights(
    hmath_context *context,
    const hmath_value *method,
    const hmath_value *fan_in,
    const hmath_value *fan_out,
    const hmath_value *shape,
    const hmath_value *rng,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={method, fan_in, fan_out, shape, rng};
    return invoke(context, "HMath.DeepLearning.Layers.initializeWeights", hm_arguments, 5, out);
}

hmath_status hmath_neural_layers_embedding(
    hmath_context *context,
    const hmath_value *weights,
    const hmath_value *indices,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={weights, indices};
    return invoke(context, "HMath.DeepLearning.Layers.embedding", hm_arguments, 2, out);
}

hmath_status hmath_neural_layers_dense(
    hmath_context *context,
    const hmath_value *input,
    const hmath_value *weights,
    const hmath_value *bias,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={input, weights, bias};
    return invoke(context, "HMath.DeepLearning.Layers.dense", hm_arguments, 3, out);
}

hmath_status hmath_neural_layers_dense_ad(
    hmath_context *context,
    const hmath_value *input,
    const hmath_value *weights,
    const hmath_value *bias,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={input, weights, bias};
    return invoke(context, "HMath.DeepLearning.Layers.denseAD", hm_arguments, 3, out);
}

hmath_status hmath_neural_layers_conv_options_create(
    hmath_context *context,
    const hmath_value *stride,
    const hmath_value *padding,
    const hmath_value *dilation,
    const hmath_value *groups,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={stride, padding, dilation, groups};
    return invoke(context, "HMath.DeepLearning.Layers.ConvOptions", hm_arguments, 4, out);
}

hmath_status hmath_neural_layers_convolution_stride(
    hmath_context *context,
    const hmath_value *options,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={options};
    return invoke(context, "HMath.DeepLearning.Layers.convolutionStride", hm_arguments, 1, out);
}

hmath_status hmath_neural_layers_convolution_padding(
    hmath_context *context,
    const hmath_value *options,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={options};
    return invoke(context, "HMath.DeepLearning.Layers.convolutionPadding", hm_arguments, 1, out);
}

hmath_status hmath_neural_layers_convolution_dilation(
    hmath_context *context,
    const hmath_value *options,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={options};
    return invoke(context, "HMath.DeepLearning.Layers.convolutionDilation", hm_arguments, 1, out);
}

hmath_status hmath_neural_layers_convolution_groups(
    hmath_context *context,
    const hmath_value *options,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={options};
    return invoke(context, "HMath.DeepLearning.Layers.convolutionGroups", hm_arguments, 1, out);
}

hmath_status hmath_neural_layers_convolution(
    hmath_context *context,
    const hmath_value *options,
    const hmath_value *input,
    const hmath_value *weights,
    const hmath_value *bias,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={options, input, weights, bias};
    return invoke(context, "HMath.DeepLearning.Layers.convolution", hm_arguments, 4, out);
}

hmath_status hmath_neural_layers_depthwise_convolution(
    hmath_context *context,
    const hmath_value *options,
    const hmath_value *input,
    const hmath_value *weights,
    const hmath_value *bias,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={options, input, weights, bias};
    return invoke(context, "HMath.DeepLearning.Layers.depthwiseConvolution", hm_arguments, 4, out);
}

hmath_status hmath_neural_layers_convolution_ad(
    hmath_context *context,
    const hmath_value *options,
    const hmath_value *input,
    const hmath_value *weights,
    const hmath_value *bias,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={options, input, weights, bias};
    return invoke(context, "HMath.DeepLearning.Layers.convolutionAD", hm_arguments, 4, out);
}

hmath_status hmath_neural_layers_transposed_convolution(
    hmath_context *context,
    const hmath_value *output_padding,
    const hmath_value *options,
    const hmath_value *input,
    const hmath_value *weights,
    const hmath_value *bias,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={output_padding, options, input, weights, bias};
    return invoke(context, "HMath.DeepLearning.Layers.transposedConvolution", hm_arguments, 5, out);
}

hmath_status hmath_neural_layers_max_pool_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Layers.MaxPool", NULL, 0, out);
}

hmath_status hmath_neural_layers_average_pool_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Layers.AveragePool", NULL, 0, out);
}

hmath_status hmath_neural_layers_pooling(
    hmath_context *context,
    const hmath_value *mode,
    const hmath_value *kernel,
    const hmath_value *stride,
    const hmath_value *padding,
    const hmath_value *input,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={mode, kernel, stride, padding, input};
    return invoke(context, "HMath.DeepLearning.Layers.pooling", hm_arguments, 5, out);
}

hmath_status hmath_neural_layers_adaptive_pooling(
    hmath_context *context,
    const hmath_value *mode,
    const hmath_value *shape,
    const hmath_value *input,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={mode, shape, input};
    return invoke(context, "HMath.DeepLearning.Layers.adaptivePooling", hm_arguments, 3, out);
}

hmath_status hmath_neural_layers_global_pooling(
    hmath_context *context,
    const hmath_value *mode,
    const hmath_value *input,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={mode, input};
    return invoke(context, "HMath.DeepLearning.Layers.globalPooling", hm_arguments, 2, out);
}

hmath_status hmath_neural_layers_scaled_dot_product_attention(
    hmath_context *context,
    const hmath_value *query,
    const hmath_value *key,
    const hmath_value *value,
    const hmath_value *mask,
    const hmath_value *bias,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={query, key, value, mask, bias};
    return invoke(context, "HMath.DeepLearning.Layers.scaledDotProductAttention", hm_arguments, 5, out);
}

hmath_status hmath_neural_layers_multihead_attention(
    hmath_context *context,
    const hmath_value *heads,
    const hmath_value *query,
    const hmath_value *key,
    const hmath_value *value,
    const hmath_value *mask,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={heads, query, key, value, mask};
    return invoke(context, "HMath.DeepLearning.Layers.multiheadAttention", hm_arguments, 5, out);
}

hmath_status hmath_neural_layers_causal_mask(
    hmath_context *context,
    const hmath_value *queries,
    const hmath_value *keys,
    const hmath_value *offset,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={queries, keys, offset};
    return invoke(context, "HMath.DeepLearning.Layers.causalMask", hm_arguments, 3, out);
}

hmath_status hmath_neural_layers_rotary_embedding(
    hmath_context *context,
    const hmath_value *base,
    const hmath_value *offset,
    const hmath_value *input,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={base, offset, input};
    return invoke(context, "HMath.DeepLearning.Layers.rotaryEmbedding", hm_arguments, 3, out);
}

hmath_status hmath_neural_layers_sinusoidal_encoding(
    hmath_context *context,
    const hmath_value *length,
    const hmath_value *dimensions,
    const hmath_value *offset,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={length, dimensions, offset};
    return invoke(context, "HMath.DeepLearning.Layers.sinusoidalEncoding", hm_arguments, 3, out);
}

hmath_status hmath_neural_layers_alibi_bias(
    hmath_context *context,
    const hmath_value *slope,
    const hmath_value *queries,
    const hmath_value *keys,
    const hmath_value *offset,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={slope, queries, keys, offset};
    return invoke(context, "HMath.DeepLearning.Layers.alibiBias", hm_arguments, 4, out);
}

hmath_status hmath_neural_layers_empty_cache(
    hmath_context *context,
    const hmath_value *capacity,
    const hmath_value *key_dimensions,
    const hmath_value *value_dimensions,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={capacity, key_dimensions, value_dimensions};
    return invoke(context, "HMath.DeepLearning.Layers.emptyCache", hm_arguments, 3, out);
}

hmath_status hmath_neural_layers_append_cache(
    hmath_context *context,
    const hmath_value *cache,
    const hmath_value *key,
    const hmath_value *value,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={cache, key, value};
    return invoke(context, "HMath.DeepLearning.Layers.appendCache", hm_arguments, 3, out);
}

hmath_status hmath_neural_layers_cache_values(
    hmath_context *context,
    const hmath_value *cache,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={cache};
    return invoke(context, "HMath.DeepLearning.Layers.cacheValues", hm_arguments, 1, out);
}

hmath_status hmath_neural_layers_transformer_feed_forward(
    hmath_context *context,
    const hmath_value *activation,
    const hmath_value *input,
    const hmath_value *first_weights,
    const hmath_value *first_bias,
    const hmath_value *second_weights,
    const hmath_value *second_bias,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={activation, input, first_weights, first_bias, second_weights, second_bias};
    return invoke(context, "HMath.DeepLearning.Layers.transformerFeedForward", hm_arguments, 6, out);
}

hmath_status hmath_neural_layers_layer_norm_ad(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *epsilon,
    const hmath_value *input,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={axes, epsilon, input};
    return invoke(context, "HMath.DeepLearning.Layers.layerNormAD", hm_arguments, 3, out);
}

hmath_status hmath_neural_layers_rms_norm_ad(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *epsilon,
    const hmath_value *input,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={axes, epsilon, input};
    return invoke(context, "HMath.DeepLearning.Layers.rmsNormAD", hm_arguments, 3, out);
}

hmath_status hmath_neural_layers_scaled_dot_product_attention_ad(
    hmath_context *context,
    const hmath_value *query,
    const hmath_value *key,
    const hmath_value *value,
    const hmath_value *mask,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={query, key, value, mask};
    return invoke(context, "HMath.DeepLearning.Layers.scaledDotProductAttentionAD", hm_arguments, 4, out);
}

hmath_status hmath_neural_precision_symmetric_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Precision.Symmetric", NULL, 0, out);
}

hmath_status hmath_neural_precision_asymmetric_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Precision.Asymmetric", NULL, 0, out);
}

hmath_status hmath_neural_precision_quantize(
    hmath_context *context,
    const hmath_value *scheme,
    const hmath_value *axis,
    const hmath_value *input,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={scheme, axis, input};
    return invoke(context, "HMath.DeepLearning.Precision.quantize", hm_arguments, 3, out);
}

hmath_status hmath_neural_precision_dequantize(
    hmath_context *context,
    const hmath_value *quantized,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={quantized};
    return invoke(context, "HMath.DeepLearning.Precision.dequantize", hm_arguments, 1, out);
}

hmath_status hmath_neural_precision_quantized_values(
    hmath_context *context,
    const hmath_value *quantized,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={quantized};
    return invoke(context, "HMath.DeepLearning.Precision.quantizedValues", hm_arguments, 1, out);
}

hmath_status hmath_neural_precision_quantization_scales(
    hmath_context *context,
    const hmath_value *quantized,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={quantized};
    return invoke(context, "HMath.DeepLearning.Precision.quantizationScales", hm_arguments, 1, out);
}

hmath_status hmath_neural_precision_quantization_zero_points(
    hmath_context *context,
    const hmath_value *quantized,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={quantized};
    return invoke(context, "HMath.DeepLearning.Precision.quantizationZeroPoints", hm_arguments, 1, out);
}

hmath_status hmath_neural_precision_int8_gemm(
    hmath_context *context,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={left, right};
    return invoke(context, "HMath.DeepLearning.Precision.int8Gemm", hm_arguments, 2, out);
}

hmath_status hmath_neural_precision_fp16_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Precision.FP16", NULL, 0, out);
}

hmath_status hmath_neural_precision_bf16_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "HMath.DeepLearning.Precision.BF16", NULL, 0, out);
}

hmath_status hmath_neural_precision_reduced_gemm(
    hmath_context *context,
    const hmath_value *precision,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={precision, left, right};
    return invoke(context, "HMath.DeepLearning.Precision.reducedGemm", hm_arguments, 3, out);
}

hmath_status hmath_neural_precision_loss_scaler_create(
    hmath_context *context,
    const hmath_value *scale,
    const hmath_value *growth_interval,
    const hmath_value *finite_steps,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={scale, growth_interval, finite_steps};
    return invoke(context, "HMath.DeepLearning.Precision.LossScaler", hm_arguments, 3, out);
}

hmath_status hmath_neural_precision_loss_scale(
    hmath_context *context,
    const hmath_value *state,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={state};
    return invoke(context, "HMath.DeepLearning.Precision.lossScale", hm_arguments, 1, out);
}

hmath_status hmath_neural_precision_scale_growth_interval(
    hmath_context *context,
    const hmath_value *state,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={state};
    return invoke(context, "HMath.DeepLearning.Precision.scaleGrowthInterval", hm_arguments, 1, out);
}

hmath_status hmath_neural_precision_finite_steps(
    hmath_context *context,
    const hmath_value *state,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={state};
    return invoke(context, "HMath.DeepLearning.Precision.finiteSteps", hm_arguments, 1, out);
}

hmath_status hmath_neural_precision_initial_loss_scaler(
    hmath_context *context,
    const hmath_value *scale,
    const hmath_value *growth_interval,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={scale, growth_interval};
    return invoke(context, "HMath.DeepLearning.Precision.initialLossScaler", hm_arguments, 2, out);
}

hmath_status hmath_neural_precision_scale_loss(
    hmath_context *context,
    const hmath_value *state,
    const hmath_value *loss,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={state, loss};
    return invoke(context, "HMath.DeepLearning.Precision.scaleLoss", hm_arguments, 2, out);
}

hmath_status hmath_neural_precision_unscale_gradients(
    hmath_context *context,
    const hmath_value *state,
    const hmath_value *gradients,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={state, gradients};
    return invoke(context, "HMath.DeepLearning.Precision.unscaleGradients", hm_arguments, 2, out);
}

hmath_status hmath_neural_precision_update_loss_scaler(
    hmath_context *context,
    const hmath_value *finite,
    const hmath_value *state,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={finite, state};
    return invoke(context, "HMath.DeepLearning.Precision.updateLossScaler", hm_arguments, 2, out);
}

hmath_status hmath_neural_precision_gradient_norm(
    hmath_context *context,
    const hmath_value *gradient,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={gradient};
    return invoke(context, "HMath.DeepLearning.Precision.gradientNorm", hm_arguments, 1, out);
}

hmath_status hmath_neural_precision_clip_gradients(
    hmath_context *context,
    const hmath_value *maximum,
    const hmath_value *gradient,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={maximum, gradient};
    return invoke(context, "HMath.DeepLearning.Precision.clipGradients", hm_arguments, 2, out);
}

hmath_status hmath_neural_metrics_classification_metrics_create(
    hmath_context *context,
    const hmath_value *accuracy,
    const hmath_value *precision,
    const hmath_value *recall,
    const hmath_value *f1,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={accuracy, precision, recall, f1};
    return invoke(context, "HMath.DeepLearning.Metrics.ClassificationMetrics", hm_arguments, 4, out);
}

hmath_status hmath_neural_metrics_accuracy(
    hmath_context *context,
    const hmath_value *metrics,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={metrics};
    return invoke(context, "HMath.DeepLearning.Metrics.accuracy", hm_arguments, 1, out);
}

hmath_status hmath_neural_metrics_precision_by_class(
    hmath_context *context,
    const hmath_value *metrics,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={metrics};
    return invoke(context, "HMath.DeepLearning.Metrics.precisionByClass", hm_arguments, 1, out);
}

hmath_status hmath_neural_metrics_recall_by_class(
    hmath_context *context,
    const hmath_value *metrics,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={metrics};
    return invoke(context, "HMath.DeepLearning.Metrics.recallByClass", hm_arguments, 1, out);
}

hmath_status hmath_neural_metrics_f1_by_class(
    hmath_context *context,
    const hmath_value *metrics,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={metrics};
    return invoke(context, "HMath.DeepLearning.Metrics.f1ByClass", hm_arguments, 1, out);
}

hmath_status hmath_neural_metrics_confusion_matrix(
    hmath_context *context,
    const hmath_value *classes,
    const hmath_value *truth,
    const hmath_value *prediction,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={classes, truth, prediction};
    return invoke(context, "HMath.DeepLearning.Metrics.confusionMatrix", hm_arguments, 3, out);
}

hmath_status hmath_neural_metrics_classification_metrics(
    hmath_context *context,
    const hmath_value *classes,
    const hmath_value *truth,
    const hmath_value *prediction,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={classes, truth, prediction};
    return invoke(context, "HMath.DeepLearning.Metrics.classificationMetrics", hm_arguments, 3, out);
}

hmath_status hmath_neural_metrics_top_k_accuracy(
    hmath_context *context,
    const hmath_value *k,
    const hmath_value *truth,
    const hmath_value *scores,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={k, truth, scores};
    return invoke(context, "HMath.DeepLearning.Metrics.topKAccuracy", hm_arguments, 3, out);
}

hmath_status hmath_neural_metrics_roc_auc(
    hmath_context *context,
    const hmath_value *truth,
    const hmath_value *scores,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={truth, scores};
    return invoke(context, "HMath.DeepLearning.Metrics.rocAUC", hm_arguments, 2, out);
}

hmath_status hmath_neural_metrics_pr_auc(
    hmath_context *context,
    const hmath_value *truth,
    const hmath_value *scores,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={truth, scores};
    return invoke(context, "HMath.DeepLearning.Metrics.prAUC", hm_arguments, 2, out);
}

hmath_status hmath_neural_metrics_perplexity(
    hmath_context *context,
    const hmath_value *negative_log_probabilities,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={negative_log_probabilities};
    return invoke(context, "HMath.DeepLearning.Metrics.perplexity", hm_arguments, 1, out);
}

hmath_status hmath_neural_metrics_cosine_similarity_matrix(
    hmath_context *context,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={left, right};
    return invoke(context, "HMath.DeepLearning.Metrics.cosineSimilarityMatrix", hm_arguments, 2, out);
}

hmath_status hmath_neural_metrics_margin_ranking_loss(
    hmath_context *context,
    const hmath_value *margin,
    const hmath_value *left,
    const hmath_value *right,
    const hmath_value *labels,
    hmath_value **out) {
    const hmath_value *hm_arguments[]={margin, left, right, labels};
    return invoke(context, "HMath.DeepLearning.Metrics.marginRankingLoss", hm_arguments, 4, out);
}
/* END GENERATED */
