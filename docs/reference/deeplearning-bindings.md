# Neural numerical primitives

The `deeplearning_core`, `deeplearning_layers`, `deeplearning_precision` and
`deeplearning_metrics` namespaces call the original Haskell APIs. C/C++ include
`hmath_deeplearning.h` and pass owned shared Values. Selectors, parameters,
training state, random continuations, AD graphs, exact INT8 accumulation and
result diagnostics retain original behavior.

```python
from hmath import deeplearning_core as core
from hmath import deeplearning_layers as layers
from hmath import tensor

with tensor.tensor([1, 2], [1, 2]) as inputs:
    with tensor.tensor([1, 2], [3, 4]) as weights:
        with layers.dense(inputs, weights, [1]) as output:
            assert output.values == [12.0]

assert core.activation(core.Sigmoid, 0.0) == 0.5
```

## Types, layouts and state

The original neural functions use **Double**; their Tensor parameters require
actual `tensor.TensorDouble` objects (Value161). Typed Float tensors are rejected
rather than silently widened. Use explicit tensor promotion when converting a
source type. Reduced precision and INT8 are selected through the original
precision APIs described below.

Dense inputs use trailing feature dimensions; weights use `[output,input]`.
Convolution/pooling input layout is `[N,C,spatial...]`, with one to three spatial
axes. Convolution weights use `[Cout,Cin/groups,kernel...]`; transpose convolution
uses `[Cin,Cout/groups,kernel...]`. Padding is symmetric zero padding. Attention
uses `[sequence,feature]`; `True` in a mask permits a key. Original fully masked
attention rows produce exact zero output and weights.

Training mode is explicit: `Training.TRAINING` or `Training.INFERENCE` (also
`Inference`). Functions do not consult ambient model state. Dropout returns
`(output, mask, next_rng)`. Its input/output RNG is the complete original
`hmath.random.RNG` continuation, retaining the selected generator and pending
state. Inference dropout consumes no random values.

```python
from hmath import random

with random.pcg32() as generator:
    with random.seed_rng(generator, 42) as rng:
        with tensor.tensor([1, 2], [1, 2]) as inputs:
            output, mask, advanced = layers.dropout(
                layers.Training.TRAINING, 0.5, rng, inputs
            )
            try:
                print(output.values, mask.values)
            finally:
                output.close()
                mask.close()
                advanced.close()
```

## Selectors and records

Activation selectors are `Sigmoid`, `Tanh`, `ReLU`, `LeakyReLU(parameter)`,
`PReLU(parameter)`, `ELU(parameter)`, `SELU`, `GELU`, `SiLU`, `Mish`, `Softplus`,
`Softsign`, `HardSigmoid`, `HardSwish`. The original analytic derivatives and
kink conventions are preserved. `activation_expr` embeds the source activation
and its source reverse rule in an existing Autodiff Expr.

Loss selectors are `MeanSquaredError`, `MeanAbsoluteError`, `Huber(parameter)`,
`SmoothL1(parameter)`, `BinaryCrossEntropy`, `CategoricalCrossEntropy`,
`NegativeLogLikelihood`, `KLDivergence`, `CosineLoss`, `Hinge(parameter)`.
Reduction is `Sum` or `Mean`. Probability-domain errors remain explicit;
impossible events are not silently clipped. Logit functions retain original
stable formulas. CTC blank indices, label sequences, log-probability matrices,
value/gradient outputs and unsupported cases remain unchanged.

Initializers are `XavierUniform`, `XavierNormal`, `KaimingUniform`,
`KaimingNormal`, `Orthogonal(scale)`,
`TruncatedNormal(mean, standard_deviation, bound)`. Fans and RNG are explicit;
`initialize_weights` returns `(tensor, next_rng)`.

| Python record | Fields in constructor order |
| --- | --- |
| `BatchNormState` | `running_mean`, `running_variance`, `batches_seen` |
| `ConvOptions` | `stride`, `padding`, `dilation`, `groups` |
| `LossScaler` | `scale`, `growth_interval`, `finite_steps` |
| `ClassificationMetrics` | `accuracy`, `precision`, `recall`, `f1` |

These immutable Python records copy every original field; corresponding
original selector functions remain available. Constructor calls do not invent
validation absent from source constructors. Checked operations retain original
parameter validation and errors. Batch normalization preserves its population
variance for normalization and unbiased running-variance update. Layer, instance,
group, RMS and weight normalization retain original axis and epsilon rules.

`KVCache` is an owned immutable original object. `empty_cache` fixes positive
capacity and key/value feature widths; `append_cache` returns a new cache and
rejects overflow or incompatible shapes without truncating history.
`cache_values` returns independently owned accumulated key/value tensors.

## Automatic differentiation

`activation_expr`, `loss_expr`, softmax/log-softmax/sparsemax Expr functions,
`ctc_loss_expr`, `dense_ad`, `convolution_ad`, `layer_norm_ad`, `rms_norm_ad` and
`scaled_dot_product_attention_ad` accept and return the existing
`hmath.autodiff.Expr` / `ADTensor` owners. They retain the original graphs and
reverse rules; no derivative is reconstructed by the binding. Callback owners
remain alive transitively through derived graphs. The additive
`hmath_ad_value_import`/`export` C functions interchange legacy AD handles with
Values287/288; original Autodiff Dual uses separate Value289 and never becomes
Numeric.Dual.

## Quantization and reduced precision

`quantize(Symmetric | Asymmetric, axis_or_none, tensor)` creates the actual
original `QuantizedTensor`, including exact INT8 values, scales, zero points,
shape and axis. `quantized_values`, `quantization_scales`,
`quantization_zero_points` expose the original fields; `dequantize` returns an
owned Double tensor. `int8_gemm` performs the original exact integer accumulation
with signed-32-bit overflow checks and original scale/axis restrictions.

`reduced_gemm(FP16 | BF16, left, right)` retains the software format rounding,
ties-to-even input conversion, FP32 accumulation and final Double conversion.
`initial_loss_scaler`, `scale_loss`, `unscale_gradients`, `update_loss_scaler`
retain the original dynamic state transitions. Overflow decisions happen before
an update; original master-weight and scaling conventions are unchanged.

## Metrics and errors

Confusion-matrix rows are truth, columns prediction. Classification diagnostics
retain accuracy and per-class precision/recall/F1 with original zero-denominator
conventions. Top-k ties prefer smaller class indices. ROC ties count one half;
PR AUC uses grouped-threshold trapezoids from `(recall=0, precision=1)`, matching
the original algorithm. Empty/nonfinite/shape/label failures remain the source
MathError constructors. A C checked failure is status11; Python HMathError
retains the complete `.math_error` value.

## Ownership and C calling convention

C wrappers use context first, original arguments in source order, owned
`hmath_value **out` last. Selectors/records are actual immutable source objects;
constructor wrappers end in `_create`. Inputs are borrowed for the call; outputs
remain untouched on error. Release every result and every handle nested in
lists or tuples. Python Tensor/RNG/cache/quantized/AD owners support `.close()`
and context managers. Record fields containing ordinary copied numbers/lists
require no native cleanup.

Source object kinds are Activation274, Loss275, Reduction276, Training277,
BatchNormState278, Initializer279, ConvOptions280, PoolMode281, KVCache282,
Quantization283, reduced Precision284, QuantizedTensor285, LossScaler286,
ClassificationMetrics290. They share actual Tensor161, RNG240 and AD287/288
payloads across namespaces. All live owned handles reserve the runtime.

## Function reference

The source references document original formulas, validation and parameter
semantics: [Core](haskell/HMath-DeepLearning-Core.md),
[Layers](haskell/HMath-DeepLearning-Layers.md),
[Precision](haskell/HMath-DeepLearning-Precision.md),
[Metrics](haskell/HMath-DeepLearning-Metrics.md).

### HMath.DeepLearning.Core

| Python callable/constructor | Result | C wrapper |
| --- | --- | --- |
| `Sigmoid` | `Activation` | `hmath_neural_core_sigmoid_create` |
| `Tanh` | `Activation` | `hmath_neural_core_tanh_create` |
| `ReLU` | `Activation` | `hmath_neural_core_relu_create` |
| `SELU` | `Activation` | `hmath_neural_core_selu_create` |
| `GELU` | `Activation` | `hmath_neural_core_gelu_create` |
| `SiLU` | `Activation` | `hmath_neural_core_silu_create` |
| `Mish` | `Activation` | `hmath_neural_core_mish_create` |
| `Softplus` | `Activation` | `hmath_neural_core_softplus_create` |
| `Softsign` | `Activation` | `hmath_neural_core_softsign_create` |
| `HardSigmoid` | `Activation` | `hmath_neural_core_hard_sigmoid_create` |
| `HardSwish` | `Activation` | `hmath_neural_core_hard_swish_create` |
| `LeakyReLU(parameter)` | `Activation` | `hmath_neural_core_leaky_relu_create` |
| `PReLU(parameter)` | `Activation` | `hmath_neural_core_prelu_create` |
| `ELU(parameter)` | `Activation` | `hmath_neural_core_elu_create` |
| `Sum` | `Reduction` | `hmath_neural_core_sum_create` |
| `Mean` | `Reduction` | `hmath_neural_core_mean_create` |
| `MeanSquaredError` | `Loss` | `hmath_neural_core_mean_squared_error_create` |
| `MeanAbsoluteError` | `Loss` | `hmath_neural_core_mean_absolute_error_create` |
| `BinaryCrossEntropy` | `Loss` | `hmath_neural_core_binary_cross_entropy_create` |
| `CategoricalCrossEntropy` | `Loss` | `hmath_neural_core_categorical_cross_entropy_create` |
| `NegativeLogLikelihood` | `Loss` | `hmath_neural_core_negative_log_likelihood_create` |
| `KLDivergence` | `Loss` | `hmath_neural_core_kl_divergence_create` |
| `CosineLoss` | `Loss` | `hmath_neural_core_cosine_loss_create` |
| `Huber(parameter)` | `Loss` | `hmath_neural_core_huber_create` |
| `SmoothL1(parameter)` | `Loss` | `hmath_neural_core_smooth_l1_create` |
| `Hinge(parameter)` | `Loss` | `hmath_neural_core_hinge_create` |
| `activation(method, value)` | `Double` | `hmath_neural_core_activation` |
| `activation_derivative(method, value)` | `Double` | `hmath_neural_core_activation_derivative` |
| `activation_expr(method, value)` | `ADExpr` | `hmath_neural_core_activation_expr` |
| `softmax(values)` | `[Double]` | `hmath_neural_core_softmax` |
| `log_softmax(values)` | `[Double]` | `hmath_neural_core_log_softmax` |
| `sparsemax(values)` | `[Double]` | `hmath_neural_core_sparsemax` |
| `gated_linear_unit(values, gate)` | `[Double]` | `hmath_neural_core_gated_linear_unit` |
| `softmax_expr(values)` | `[ADExpr]` | `hmath_neural_core_softmax_expr` |
| `log_softmax_expr(values)` | `[ADExpr]` | `hmath_neural_core_log_softmax_expr` |
| `sparsemax_expr(values)` | `[ADExpr]` | `hmath_neural_core_sparsemax_expr` |
| `loss(method, reduction, target, prediction)` | `Double` | `hmath_neural_core_loss` |
| `loss_gradient(method, reduction, target, prediction)` | `[Double]` | `hmath_neural_core_loss_gradient` |
| `loss_expr(method, reduction, target, prediction)` | `ADExpr` | `hmath_neural_core_loss_expr` |
| `binary_cross_entropy_logits(reduction, target, logits)` | `Double` | `hmath_neural_core_binary_cross_entropy_logits` |
| `categorical_cross_entropy_logits(target, logits)` | `Double` | `hmath_neural_core_categorical_cross_entropy_logits` |
| `regularization(l1, l2, weights)` | `Double` | `hmath_neural_core_regularization` |
| `contrastive_loss(margin, similar, left, right)` | `Double` | `hmath_neural_core_contrastive_loss` |
| `triplet_loss(margin, anchor, positive, negative)` | `Double` | `hmath_neural_core_triplet_loss` |
| `focal_loss(alpha, gamma, target, prediction)` | `Double` | `hmath_neural_core_focal_loss` |
| `dice_loss(smooth, target, prediction)` | `Double` | `hmath_neural_core_dice_loss` |
| `iou_loss(smooth, target, prediction)` | `Double` | `hmath_neural_core_iou_loss` |
| `ctc_loss(blank, labels, log_probabilities)` | `Double` | `hmath_neural_core_ctc_loss` |
| `ctc_loss_gradient(blank, labels, log_probabilities)` | `(Double,[[Double]])` | `hmath_neural_core_ctc_loss_gradient` |
| `ctc_loss_expr(blank, labels, log_probabilities)` | `ADExpr` | `hmath_neural_core_ctc_loss_expr` |

#### `activation(method, value)`

Given Activation selector then finite scalar, evaluate the selected activation. Parameterized LeakyReLU/PReLU slopes must be finite and ELU alpha positive. Invalid input/parameters or non-finite output returns Left MathError.

#### `activation_derivative(method, value)`

Evaluate the analytic first derivative with documented kink conventions and stable saturated sigmoid/tanh behavior.

#### `activation_expr(method, value)`

Embed the checked activation and analytic custom reverse rule in an automatic differentiation graph.

#### `softmax(values)`

Exponentiate stable log-softmax values; the output sums to one within floating error.

#### `log_softmax(values)`

Normalize a nonempty finite vector in log space after subtracting its maximum.

#### `sparsemax(values)`

Project a finite vector onto the probability simplex using sorted active-support thresholds.

#### `gated_linear_unit(values, gate)`

Multiply values by sigmoid(gates), requiring equal vector lengths.

#### `softmax_expr(values)`

First-order softmax reverse rule, including cross-coordinate coupling.

#### `log_softmax_expr(values)`

First-order stable log-softmax rule; gradient rows sum to zero.

#### `sparsemax_expr(values)`

Sparsemax's piecewise-linear Jacobian. At a support boundary its inactive coordinate convention chooses zero, giving a defined subgradient.

#### `loss(method, reduction, target, prediction)`

Evaluate the selected checked loss. Mean divides elementwise losses by count; CosineLoss is one vector loss.

#### `loss_gradient(method, reduction, target, prediction)`

Analytic derivatives with respect to predictions under the exact loss/reduction convention.

#### `loss_expr(method, reduction, target, prediction)`

Use a constant target with symbolic prediction inputs and the matching analytic reverse rule.

#### `binary_cross_entropy_logits(reduction, target, logits)`

Stable binary cross entropy from logits and [0,1] targets, including extreme finite logits.

#### `categorical_cross_entropy_logits(target, logits)`

Cross entropy from one class-logit vector; nonnegative targets must sum to one.

#### `regularization(l1, l2, weights)`

Return l1*sum(abs(w)) + l2/2*sum(w*w); both coefficients must be finite and nonnegative.

#### `contrastive_loss(margin, similar, left, right)`

Pairwise Euclidean contrastive loss; similar=True penalizes squared distance and dissimilar pairs use the positive margin.

#### `triplet_loss(margin, anchor, positive, negative)`

Return max(0,positiveDistance-negativeDistance+margin) for equal nonempty vector dimensions.

#### `focal_loss(alpha, gamma, target, prediction)`

Mean binary focal loss with alpha in [0,1], gamma>=0, and exact zero/one targets.

#### `ctc_loss(blank, labels, log_probabilities)`

Single sequence, time-major log-probabilities [time,class]. Blank index is explicit; labels exclude blank. The forward/backward dynamic program sums alignments in log space, including adjacent repeated-label restrictions. Gradients are with respect to independent log probabilities, before a log-softmax chain rule. Impossible alignments return DomainError.

#### `ctc_loss_gradient(blank, labels, log_probabilities)`

Given blank class index, target labels, then rectangular time-by-class log probabilities, return CTC negative log likelihood and gradient rows. Validate class indices, finite/log-probability constraints and alignment feasibility. Empty time permits only empty labels; invalid/impossible inputs return Left MathError.

#### `ctc_loss_expr(blank, labels, log_probabilities)`

CTC graph operation on rectangular time-major log probabilities. Its custom backward uses forward/backward occupancies, rather than numerical differences.

### HMath.DeepLearning.Layers

| Python callable/constructor | Result | C wrapper |
| --- | --- | --- |
| `Training.TRAINING` | `Training` | `hmath_neural_layers_training_create` |
| `Inference` | `Training` | `hmath_neural_layers_inference_create` |
| `dropout(mode, probability, rng, input)` | `(Tensor,Tensor,RNG)` | `hmath_neural_layers_dropout` |
| `spatial_dropout(mode, probability, rng, input)` | `(Tensor,Tensor,RNG)` | `hmath_neural_layers_spatial_dropout` |
| `BatchNormState(running_mean, running_variance, batches_seen)` | `BatchNormState` | `hmath_neural_layers_batch_norm_state_create` |
| `running_mean(state)` | `[Double]` | `hmath_neural_layers_running_mean` |
| `running_variance(state)` | `[Double]` | `hmath_neural_layers_running_variance` |
| `batches_seen(state)` | `Int` | `hmath_neural_layers_batches_seen` |
| `batch_norm(mode, momentum, epsilon, gamma, beta, state, input)` | `(Tensor,BatchNormState)` | `hmath_neural_layers_batch_norm` |
| `layer_norm(axes, epsilon, input)` | `Tensor` | `hmath_neural_layers_layer_norm` |
| `rms_norm(axes, epsilon, input)` | `Tensor` | `hmath_neural_layers_rms_norm` |
| `instance_norm(epsilon, input)` | `Tensor` | `hmath_neural_layers_instance_norm` |
| `group_norm(groups, epsilon, input)` | `Tensor` | `hmath_neural_layers_group_norm` |
| `weight_norm(axis, scales, input)` | `Tensor` | `hmath_neural_layers_weight_norm` |
| `XavierUniform` | `Initializer` | `hmath_neural_layers_xavier_uniform_create` |
| `XavierNormal` | `Initializer` | `hmath_neural_layers_xavier_normal_create` |
| `KaimingUniform` | `Initializer` | `hmath_neural_layers_kaiming_uniform_create` |
| `KaimingNormal` | `Initializer` | `hmath_neural_layers_kaiming_normal_create` |
| `Orthogonal(scale)` | `Initializer` | `hmath_neural_layers_orthogonal_create` |
| `TruncatedNormal(mean, standard_deviation, bound)` | `Initializer` | `hmath_neural_layers_truncated_normal_create` |
| `initialize_weights(method, fan_in, fan_out, shape, rng)` | `(Tensor,RNG)` | `hmath_neural_layers_initialize_weights` |
| `embedding(weights, indices)` | `Tensor` | `hmath_neural_layers_embedding` |
| `dense(input, weights, bias)` | `Tensor` | `hmath_neural_layers_dense` |
| `dense_ad(input, weights, bias)` | `ADTensor` | `hmath_neural_layers_dense_ad` |
| `ConvOptions(stride, padding, dilation, groups)` | `ConvOptions` | `hmath_neural_layers_conv_options_create` |
| `convolution_stride(options)` | `[Int]` | `hmath_neural_layers_convolution_stride` |
| `convolution_padding(options)` | `[Int]` | `hmath_neural_layers_convolution_padding` |
| `convolution_dilation(options)` | `[Int]` | `hmath_neural_layers_convolution_dilation` |
| `convolution_groups(options)` | `Int` | `hmath_neural_layers_convolution_groups` |
| `convolution(options, input, weights, bias)` | `Tensor` | `hmath_neural_layers_convolution` |
| `depthwise_convolution(options, input, weights, bias)` | `Tensor` | `hmath_neural_layers_depthwise_convolution` |
| `convolution_ad(options, input, weights, bias)` | `ADTensor` | `hmath_neural_layers_convolution_ad` |
| `transposed_convolution(output_padding, options, input, weights, bias)` | `Tensor` | `hmath_neural_layers_transposed_convolution` |
| `MaxPool` | `PoolMode` | `hmath_neural_layers_max_pool_create` |
| `AveragePool` | `PoolMode` | `hmath_neural_layers_average_pool_create` |
| `pooling(mode, kernel, stride, padding, input)` | `Tensor` | `hmath_neural_layers_pooling` |
| `adaptive_pooling(mode, shape, input)` | `Tensor` | `hmath_neural_layers_adaptive_pooling` |
| `global_pooling(mode, input)` | `Tensor` | `hmath_neural_layers_global_pooling` |
| `scaled_dot_product_attention(query, key, value, mask, bias)` | `(Tensor,Tensor)` | `hmath_neural_layers_scaled_dot_product_attention` |
| `multihead_attention(heads, query, key, value, mask)` | `Tensor` | `hmath_neural_layers_multihead_attention` |
| `causal_mask(queries, keys, offset)` | `[[Bool]]` | `hmath_neural_layers_causal_mask` |
| `rotary_embedding(base, offset, input)` | `Tensor` | `hmath_neural_layers_rotary_embedding` |
| `sinusoidal_encoding(length, dimensions, offset)` | `Tensor` | `hmath_neural_layers_sinusoidal_encoding` |
| `alibi_bias(slope, queries, keys, offset)` | `[[Double]]` | `hmath_neural_layers_alibi_bias` |
| `empty_cache(capacity, key_dimensions, value_dimensions)` | `KVCache` | `hmath_neural_layers_empty_cache` |
| `append_cache(cache, key, value)` | `KVCache` | `hmath_neural_layers_append_cache` |
| `cache_values(cache)` | `(Tensor,Tensor)` | `hmath_neural_layers_cache_values` |
| `transformer_feed_forward(activation, input, first_weights, first_bias, second_weights, second_bias)` | `Tensor` | `hmath_neural_layers_transformer_feed_forward` |
| `layer_norm_ad(axes, epsilon, input)` | `ADTensor` | `hmath_neural_layers_layer_norm_ad` |
| `rms_norm_ad(axes, epsilon, input)` | `ADTensor` | `hmath_neural_layers_rms_norm_ad` |
| `scaled_dot_product_attention_ad(query, key, value, mask)` | `ADTensor` | `hmath_neural_layers_scaled_dot_product_attention_ad` |

#### `dropout(mode, probability, rng, input)`

Inverted dropout. Inference consumes no random numbers. Return a separate multiplicative mask so its exact graph can be replayed by backpropagation.

#### `spatial_dropout(mode, probability, rng, input)`

Sample one inverted dropout mask per N,C pair and share it across every spatial position.

#### `batch_norm(mode, momentum, epsilon, gamma, beta, state, input)`

Population variance normalizes a training batch; unbiased sample variance updates runningVariance (a one-element batch uses population variance).

#### `layer_norm(axes, epsilon, input)`

Normalize the selected number of trailing axes independently for each remaining prefix index.

#### `rms_norm(axes, epsilon, input)`

Divide trailing-axis groups by sqrt(mean(x*x)+epsilon), without subtracting a mean.

#### `instance_norm(epsilon, input)`

Normalize spatial axes separately per batch/channel in N,C,spatial layout.

#### `group_norm(groups, epsilon, input)`

Normalize channels/spatial positions per batch and channel group; channel count must be divisible by groups.

#### `weight_norm(axis, scales, input)`

Normalize each selected-axis slice and multiply it by the matching explicit magnitude; zero directions fail.

#### `initialize_weights(method, fan_in, fan_out, shape, rng)`

Generate an immutable tensor and advanced RNG. Fans are explicit; orthogonal initialization requires a positive matrix shape.

#### `embedding(weights, indices)`

Gather checked row indices from [vocabulary,features] weights in requested order.

#### `dense(input, weights, bias)`

Apply x*transpose(weights)+bias to [batch,in] inputs and [out,in] weights.

#### `dense_ad(input, weights, bias)`

Symbolic dense layer with gradients through inputs, weights, and explicit bias expressions.

#### `convolution(options, input, weights, bias)`

Direct checked 1D/2D/3D cross-correlation with grouped channels and explicit stride/padding/dilation.

#### `depthwise_convolution(options, input, weights, bias)`

Set groups to input channels; output channel multipliers remain explicit in the weight shape.

#### `convolution_ad(options, input, weights, bias)`

Construct the same direct convolution from scalar graph arithmetic, with automatic input/kernel/bias gradients.

#### `transposed_convolution(output_padding, options, input, weights, bias)`

Direct adjoint-layout convolution; output padding is per-axis and strictly less than stride.

#### `pooling(mode, kernel, stride, padding, input)`

Windowed max/average pooling. Padded elements are excluded from the average; entirely padded windows fail.

#### `adaptive_pooling(mode, shape, input)`

Partition spatial axes by floor/ceil output-bin boundaries, then reduce each bin.

#### `global_pooling(mode, input)`

Reduce all spatial positions to one value per N,C pair.

#### `scaled_dot_product_attention(query, key, value, mask, bias)`

Return attended values and normalized weights for Q[N,D],K[M,D],V[M,F]; True masks permit keys.

#### `multihead_attention(heads, query, key, value, mask)`

Split feature dimension into equal heads, attend independently, concatenate. Projection matrices are explicit dense layers composed by the caller.

#### `causal_mask(queries, keys, offset)`

Build a query-by-key allowed mask, with an explicit cached-prefix offset.

#### `rotary_embedding(base, offset, input)`

Rotate adjacent feature pairs at sequence positions offset+i; feature dimension must be even.

#### `sinusoidal_encoding(length, dimensions, offset)`

Return [position,feature] sine/cosine positional encoding with base 10000.

#### `alibi_bias(slope, queries, keys, offset)`

Return nonpositive slope-scaled absolute position offsets; combine with a causal allowed mask if required.

#### `empty_cache(capacity, key_dimensions, value_dimensions)`

Create an owned immutable key/value cache with fixed positive capacity and feature widths.

#### `append_cache(cache, key, value)`

Append equal-length key/value sequences without truncating history; reject capacity or feature mismatches.

#### `cache_values(cache)`

Return immutable accumulated key/value tensors, preserving insertion order.

#### `transformer_feed_forward(activation, input, first_weights, first_bias, second_weights, second_bias)`

Compose dense, checked elementwise activation, and dense layers with explicit parameters.

#### `layer_norm_ad(axes, epsilon, input)`

Symbolic trailing-axis layer normalization. Affine gamma/beta can be composed with broadcast multiplication/addition in HMath.Autodiff.

#### `rms_norm_ad(axes, epsilon, input)`

Symbolic RMS normalization; its denominator includes all trailing axes.

#### `scaled_dot_product_attention_ad(query, key, value, mask)`

First-order reverse attention graph, including Q/K score and V gradients. Masks have the same True=allowed semantics as the checked numeric operation; a fully masked row is a constant zero graph and backpropagates exact zeros.

### HMath.DeepLearning.Precision

| Python callable/constructor | Result | C wrapper |
| --- | --- | --- |
| `Symmetric` | `Quantization` | `hmath_neural_precision_symmetric_create` |
| `Asymmetric` | `Quantization` | `hmath_neural_precision_asymmetric_create` |
| `quantize(scheme, axis, input)` | `QuantizedTensor` | `hmath_neural_precision_quantize` |
| `dequantize(quantized)` | `Tensor` | `hmath_neural_precision_dequantize` |
| `quantized_values(quantized)` | `[Int8]` | `hmath_neural_precision_quantized_values` |
| `quantization_scales(quantized)` | `[Double]` | `hmath_neural_precision_quantization_scales` |
| `quantization_zero_points(quantized)` | `[Int]` | `hmath_neural_precision_quantization_zero_points` |
| `int8_gemm(left, right)` | `Tensor` | `hmath_neural_precision_int8_gemm` |
| `FP16` | `Precision` | `hmath_neural_precision_fp16_create` |
| `BF16` | `Precision` | `hmath_neural_precision_bf16_create` |
| `reduced_gemm(precision, left, right)` | `Tensor` | `hmath_neural_precision_reduced_gemm` |
| `LossScaler(scale, growth_interval, finite_steps)` | `LossScaler` | `hmath_neural_precision_loss_scaler_create` |
| `loss_scale(state)` | `Double` | `hmath_neural_precision_loss_scale` |
| `scale_growth_interval(state)` | `Int` | `hmath_neural_precision_scale_growth_interval` |
| `finite_steps(state)` | `Int` | `hmath_neural_precision_finite_steps` |
| `initial_loss_scaler(scale, growth_interval)` | `LossScaler` | `hmath_neural_precision_initial_loss_scaler` |
| `scale_loss(state, loss)` | `Double` | `hmath_neural_precision_scale_loss` |
| `unscale_gradients(state, gradients)` | `(Bool,[Double])` | `hmath_neural_precision_unscale_gradients` |
| `update_loss_scaler(finite, state)` | `LossScaler` | `hmath_neural_precision_update_loss_scaler` |
| `gradient_norm(gradient)` | `Double` | `hmath_neural_precision_gradient_norm` |
| `clip_gradients(maximum, gradient)` | `[Double]` | `hmath_neural_precision_clip_gradients` |

#### `quantize(scheme, axis, input)`

Calibrate finite nonempty values per tensor or selected axis. Symmetric uses [-127,127], asymmetric [-128,127], with ties-to-even rounding.

#### `dequantize(quantized)`

Decode owned INT8 values using scale*(q-zeroPoint), rejecting floating arithmetic overflow.

#### `quantized_values(quantized)`

Return signed INT8 storage in logical row-major order.

#### `quantization_scales(quantized)`

Return one positive scale per calibrated channel, or a single per-tensor scale.

#### `quantization_zero_points(quantized)`

Return integer zero offsets under the selected symmetric/asymmetric calibration.

#### `int8_gemm(left, right)`

Multiply two INT8 matrices with exact integer accumulation; supports per-row A/per-column B or per-tensor scales.

#### `reduced_gemm(precision, left, right)`

Round operands to the chosen 16-bit format, accumulate in Float32, and return checked Double values.

#### `initial_loss_scaler(scale, growth_interval)`

Create a positive finite loss scale and positive growth interval; zero accumulated finite steps.

#### `scale_loss(state, loss)`

Multiply a finite loss by the checked current scale; overflow is a structured failure.

#### `unscale_gradients(state, gradients)`

False means overflow: every caller must skip the entire optimizer update. Gradients are returned only when every scaled gradient is finite.

#### `update_loss_scaler(finite, state)`

Halve scale after overflow; double after growthInterval finite updates, with a bounded maximum.

#### `gradient_norm(gradient)`

Compute a checked scaled Euclidean norm; unrepresentable final norms fail explicitly.

#### `clip_gradients(maximum, gradient)`

Clip norm through the shared overflow-safe automatic-differentiation gradient utility.

### HMath.DeepLearning.Metrics

| Python callable/constructor | Result | C wrapper |
| --- | --- | --- |
| `ClassificationMetrics(accuracy, precision, recall, f1)` | `ClassificationMetrics` | `hmath_neural_metrics_classification_metrics_create` |
| `accuracy(metrics)` | `Double` | `hmath_neural_metrics_accuracy` |
| `precision_by_class(metrics)` | `[Double]` | `hmath_neural_metrics_precision_by_class` |
| `recall_by_class(metrics)` | `[Double]` | `hmath_neural_metrics_recall_by_class` |
| `f1_by_class(metrics)` | `[Double]` | `hmath_neural_metrics_f1_by_class` |
| `confusion_matrix(classes, truth, prediction)` | `[[Int]]` | `hmath_neural_metrics_confusion_matrix` |
| `classification_metrics(classes, truth, prediction)` | `ClassificationMetrics` | `hmath_neural_metrics_classification_metrics` |
| `top_k_accuracy(k, truth, scores)` | `Double` | `hmath_neural_metrics_top_k_accuracy` |
| `roc_auc(truth, scores)` | `Double` | `hmath_neural_metrics_roc_auc` |
| `pr_auc(truth, scores)` | `Double` | `hmath_neural_metrics_pr_auc` |
| `perplexity(negative_log_probabilities)` | `Double` | `hmath_neural_metrics_perplexity` |
| `cosine_similarity_matrix(left, right)` | `Tensor` | `hmath_neural_metrics_cosine_similarity_matrix` |
| `margin_ranking_loss(margin, left, right, labels)` | `Double` | `hmath_neural_metrics_margin_ranking_loss` |

#### `confusion_matrix(classes, truth, prediction)`

Count [trueClass,predictedClass] pairs for a positive explicit class count.

#### `classification_metrics(classes, truth, prediction)`

Return accuracy and per-class precision, recall, and F1 with zero for undefined class denominators.

#### `top_k_accuracy(k, truth, scores)`

Measure whether truth lies among descending top-k scores; equal scores prefer the smaller class index.

#### `roc_auc(truth, scores)`

Compute the exact positive/negative rank-pair ROC area; both classes are required and ties count half.

#### `pr_auc(truth, scores)`

Integrate the precision-recall curve by grouped-score trapezoids, requiring at least one positive example.

#### `perplexity(negative_log_probabilities)`

Exponentiate the negative mean true-token log probability; empty or positive log probabilities fail.

#### `cosine_similarity_matrix(left, right)`

Compare every [M,D] row with every [N,D] row using scale-safe unit vectors; zero vectors fail.

#### `margin_ranking_loss(margin, left, right, labels)`

Mean hinge on signed (+/-1) pair ordering with a nonnegative finite margin.
