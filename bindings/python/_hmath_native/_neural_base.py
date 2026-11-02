# SPDX-License-Identifier: MPL-2.0
"""Original neural selectors, state records and exact AD/Tensor/RNG ownership."""

from dataclasses import dataclass
from enum import IntEnum

from . import _value as v
from . import (
    random_values as _random_values,  # noqa: F401 - register full original RNG240
)
from ._compat import zip_equal
from ._neural_catalog import CATALOG
from ._numeric import _int
from ._tensor_core import _typed as _tensor_typed

_SPEC = {entry["module"] + "." + entry["name"]: entry for entry in CATALOG}


@dataclass(frozen=True)
class _Constructor:
    name: str
    arguments: tuple = ()


class Activation(_Constructor):
    pass


class Loss(_Constructor):
    pass


class Initializer(_Constructor):
    pass


class Reduction(IntEnum):
    SUM = 0
    MEAN = 1


class Training(IntEnum):
    TRAINING = 0
    INFERENCE = 1


class PoolMode(IntEnum):
    MAX_POOL = 0
    AVERAGE_POOL = 1


class Quantization(IntEnum):
    SYMMETRIC = 0
    ASYMMETRIC = 1


class Precision(IntEnum):
    FP16 = 0
    BF16 = 1


@dataclass(frozen=True)
class BatchNormState:
    running_mean: list
    running_variance: list
    batches_seen: int


@dataclass(frozen=True)
class ConvOptions:
    stride: list
    padding: list
    dilation: list
    groups: int


@dataclass(frozen=True)
class LossScaler:
    scale: float
    growth_interval: int
    finite_steps: int


@dataclass(frozen=True)
class ClassificationMetrics:
    accuracy: float
    precision: list
    recall: list
    f1: list


class KVCache(v.Value):
    """Original immutable owned key/value cache. Construct with empty_cache."""


class QuantizedTensor(v.Value):
    """Actual original INT8 tensor and calibration, not reconstructed metadata."""

    @property
    def values(self):
        return quantized_values(self)

    @property
    def scales(self):
        return quantization_scales(self)

    @property
    def zero_points(self):
        return quantization_zero_points(self)


_ENUMS = {
    "Reduction": (Reduction, "Core", ["Sum", "Mean"]),
    "Training": (Training, "Layers", ["Training", "Inference"]),
    "PoolMode": (PoolMode, "Layers", ["MaxPool", "AveragePool"]),
    "Quantization": (Quantization, "Precision", ["Symmetric", "Asymmetric"]),
    "Precision": (Precision, "Precision", ["FP16", "BF16"]),
}
_RECORDS = {
    "BatchNormState": (
        BatchNormState,
        "Layers",
        ["running_mean", "running_variance", "batches_seen"],
        ["runningMean", "runningVariance", "batchesSeen"],
    ),
    "ConvOptions": (
        ConvOptions,
        "Layers",
        ["stride", "padding", "dilation", "groups"],
        [
            "convolutionStride",
            "convolutionPadding",
            "convolutionDilation",
            "convolutionGroups",
        ],
    ),
    "LossScaler": (
        LossScaler,
        "Precision",
        ["scale", "growth_interval", "finite_steps"],
        ["lossScale", "scaleGrowthInterval", "finiteSteps"],
    ),
    "ClassificationMetrics": (
        ClassificationMetrics,
        "Metrics",
        ["accuracy", "precision", "recall", "f1"],
        ["accuracy", "precisionByClass", "recallByClass", "f1ByClass"],
    ),
}


def _sequence(values, hint):
    encoded = []
    try:
        for value in values:
            encoded.append(_typed(value, hint))
        return v.encode(encoded)
    finally:
        for value in encoded:
            value.close()


def _typed(value, hint):
    if isinstance(value, v.Value):
        return value.clone()
    if isinstance(value, _Constructor):
        return _raw(value.name, *value.arguments)
    if hint == "Double":
        return v.scalar(value, "float64")
    if hint == "Int":
        return _tensor_typed(_int(value), "Int")
    if hint == "Bool":
        return _tensor_typed(value, "Bool")
    if hint in _ENUMS:
        cls, module, names = _ENUMS[hint]
        kind = cls(value)
        return _raw("HMath.DeepLearning." + module + "." + names[kind])
    if hint in _RECORDS:
        cls, module, fields, _ = _RECORDS[hint]
        if not isinstance(value, cls):
            raise TypeError("expected " + hint)
        return _raw(
            "HMath.DeepLearning." + module + "." + hint,
            *[getattr(value, field) for field in fields],
        )
    if hint == "ADExpr":
        from . import autodiff as ad

        if isinstance(value, ad.Expr):
            return v.encode(value)
        with ad.constant(value) as expression:
            return v.encode(expression)
    if hint.startswith("Maybe"):
        return v.encode(None) if value is None else _typed(value, hint[5:])
    if hint.startswith("["):
        return _sequence(value, hint[1:-1])
    return v.encode(value)


def _raw(name, *arguments):
    entry = _SPEC[name]
    if len(arguments) != len(entry["arguments"]):
        raise TypeError(name + " argument count differs")
    values = []
    try:
        for value, (_, hint) in zip_equal(arguments, entry["arguments"]):
            values.append(_typed(value, hint))
        return v.invoke(entry["c"], *values)
    finally:
        for value in values:
            value.close()


def _invoke(name, *arguments):
    return v.decode(_raw(name, *arguments))


def _record(value, name):
    cls, module, _, selectors = _RECORDS[name]
    try:
        return cls(
            *[
                _invoke("HMath.DeepLearning." + module + "." + selector, value)
                for selector in selectors
            ]
        )
    finally:
        value.close()


v.register(278, lambda value: _record(value, "BatchNormState"))
v.register(280, lambda value: _record(value, "ConvOptions"))
v.register(282, KVCache)
v.register(285, QuantizedTensor)
v.register(286, lambda value: _record(value, "LossScaler"))
v.register(290, lambda value: _record(value, "ClassificationMetrics"))

# BEGIN GENERATED
Sigmoid = Activation("HMath.DeepLearning.Core.Sigmoid")

Activation.SIGMOID = Sigmoid

Tanh = Activation("HMath.DeepLearning.Core.Tanh")

Activation.TANH = Tanh

ReLU = Activation("HMath.DeepLearning.Core.ReLU")

Activation.RELU = ReLU

SELU = Activation("HMath.DeepLearning.Core.SELU")

Activation.SELU = SELU

GELU = Activation("HMath.DeepLearning.Core.GELU")

Activation.GELU = GELU

SiLU = Activation("HMath.DeepLearning.Core.SiLU")

Activation.SILU = SiLU

Mish = Activation("HMath.DeepLearning.Core.Mish")

Activation.MISH = Mish

Softplus = Activation("HMath.DeepLearning.Core.Softplus")

Activation.SOFTPLUS = Softplus

Softsign = Activation("HMath.DeepLearning.Core.Softsign")

Activation.SOFTSIGN = Softsign

HardSigmoid = Activation("HMath.DeepLearning.Core.HardSigmoid")

Activation.HARD_SIGMOID = HardSigmoid

HardSwish = Activation("HMath.DeepLearning.Core.HardSwish")

Activation.HARD_SWISH = HardSwish


def LeakyReLU(parameter):
    return Activation("HMath.DeepLearning.Core.LeakyReLU", (parameter,))


Activation.LEAKY_RELU = staticmethod(LeakyReLU)


def PReLU(parameter):
    return Activation("HMath.DeepLearning.Core.PReLU", (parameter,))


Activation.PRELU = staticmethod(PReLU)


def ELU(parameter):
    return Activation("HMath.DeepLearning.Core.ELU", (parameter,))


Activation.ELU = staticmethod(ELU)

Sum = Reduction.SUM

Mean = Reduction.MEAN

MeanSquaredError = Loss("HMath.DeepLearning.Core.MeanSquaredError")

Loss.MEAN_SQUARED_ERROR = MeanSquaredError

MeanAbsoluteError = Loss("HMath.DeepLearning.Core.MeanAbsoluteError")

Loss.MEAN_ABSOLUTE_ERROR = MeanAbsoluteError

BinaryCrossEntropy = Loss("HMath.DeepLearning.Core.BinaryCrossEntropy")

Loss.BINARY_CROSS_ENTROPY = BinaryCrossEntropy

CategoricalCrossEntropy = Loss("HMath.DeepLearning.Core.CategoricalCrossEntropy")

Loss.CATEGORICAL_CROSS_ENTROPY = CategoricalCrossEntropy

NegativeLogLikelihood = Loss("HMath.DeepLearning.Core.NegativeLogLikelihood")

Loss.NEGATIVE_LOG_LIKELIHOOD = NegativeLogLikelihood

KLDivergence = Loss("HMath.DeepLearning.Core.KLDivergence")

Loss.KL_DIVERGENCE = KLDivergence

CosineLoss = Loss("HMath.DeepLearning.Core.CosineLoss")

Loss.COSINE_LOSS = CosineLoss


def Huber(parameter):
    return Loss("HMath.DeepLearning.Core.Huber", (parameter,))


Loss.HUBER = staticmethod(Huber)


def SmoothL1(parameter):
    return Loss("HMath.DeepLearning.Core.SmoothL1", (parameter,))


Loss.SMOOTH_L1 = staticmethod(SmoothL1)


def Hinge(parameter):
    return Loss("HMath.DeepLearning.Core.Hinge", (parameter,))


Loss.HINGE = staticmethod(Hinge)


def activation(method, value):
    """HMath.DeepLearning.Core.activation: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Core.activation", method, value)


def activation_derivative(method, value):
    """HMath.DeepLearning.Core.activationDerivative: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Core.activationDerivative", method, value)


def activation_expr(method, value):
    """HMath.DeepLearning.Core.activationExpr: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Core.activationExpr", method, value)


def softmax(values):
    """HMath.DeepLearning.Core.softmax: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Core.softmax", values)


def log_softmax(values):
    """HMath.DeepLearning.Core.logSoftmax: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Core.logSoftmax", values)


def sparsemax(values):
    """HMath.DeepLearning.Core.sparsemax: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Core.sparsemax", values)


def gated_linear_unit(values, gate):
    """HMath.DeepLearning.Core.gatedLinearUnit: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Core.gatedLinearUnit", values, gate)


def softmax_expr(values):
    """HMath.DeepLearning.Core.softmaxExpr: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Core.softmaxExpr", values)


def log_softmax_expr(values):
    """HMath.DeepLearning.Core.logSoftmaxExpr: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Core.logSoftmaxExpr", values)


def sparsemax_expr(values):
    """HMath.DeepLearning.Core.sparsemaxExpr: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Core.sparsemaxExpr", values)


def loss(method, reduction, target, prediction):
    """HMath.DeepLearning.Core.loss: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Core.loss", method, reduction, target, prediction
    )


def loss_gradient(method, reduction, target, prediction):
    """HMath.DeepLearning.Core.lossGradient: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Core.lossGradient", method, reduction, target, prediction
    )


def loss_expr(method, reduction, target, prediction):
    """HMath.DeepLearning.Core.lossExpr: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Core.lossExpr", method, reduction, target, prediction
    )


def binary_cross_entropy_logits(reduction, target, logits):
    """HMath.DeepLearning.Core.binaryCrossEntropyLogits: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Core.binaryCrossEntropyLogits", reduction, target, logits
    )


def categorical_cross_entropy_logits(target, logits):
    """HMath.DeepLearning.Core.categoricalCrossEntropyLogits: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Core.categoricalCrossEntropyLogits", target, logits
    )


def regularization(l1, l2, weights):
    """HMath.DeepLearning.Core.regularization: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Core.regularization", l1, l2, weights)


def contrastive_loss(margin, similar, left, right):
    """HMath.DeepLearning.Core.contrastiveLoss: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Core.contrastiveLoss", margin, similar, left, right
    )


def triplet_loss(margin, anchor, positive, negative):
    """HMath.DeepLearning.Core.tripletLoss: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Core.tripletLoss", margin, anchor, positive, negative
    )


def focal_loss(alpha, gamma, target, prediction):
    """HMath.DeepLearning.Core.focalLoss: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Core.focalLoss", alpha, gamma, target, prediction
    )


def dice_loss(smooth, target, prediction):
    """HMath.DeepLearning.Core.diceLoss: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Core.diceLoss", smooth, target, prediction)


def iou_loss(smooth, target, prediction):
    """HMath.DeepLearning.Core.iouLoss: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Core.iouLoss", smooth, target, prediction)


def ctc_loss(blank, labels, log_probabilities):
    """HMath.DeepLearning.Core.ctcLoss: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Core.ctcLoss", blank, labels, log_probabilities)


def ctc_loss_gradient(blank, labels, log_probabilities):
    """HMath.DeepLearning.Core.ctcLossGradient: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Core.ctcLossGradient", blank, labels, log_probabilities
    )


def ctc_loss_expr(blank, labels, log_probabilities):
    """HMath.DeepLearning.Core.ctcLossExpr: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Core.ctcLossExpr", blank, labels, log_probabilities
    )


Inference = Training.INFERENCE


def dropout(mode, probability, rng, input):
    """HMath.DeepLearning.Layers.dropout: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.dropout", mode, probability, rng, input)


def spatial_dropout(mode, probability, rng, input):
    """HMath.DeepLearning.Layers.spatialDropout: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Layers.spatialDropout", mode, probability, rng, input
    )


def running_mean(state):
    """HMath.DeepLearning.Layers.runningMean: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.runningMean", state)


def running_variance(state):
    """HMath.DeepLearning.Layers.runningVariance: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.runningVariance", state)


def batches_seen(state):
    """HMath.DeepLearning.Layers.batchesSeen: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.batchesSeen", state)


def batch_norm(mode, momentum, epsilon, gamma, beta, state, input):
    """HMath.DeepLearning.Layers.batchNorm: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Layers.batchNorm",
        mode,
        momentum,
        epsilon,
        gamma,
        beta,
        state,
        input,
    )


def layer_norm(axes, epsilon, input):
    """HMath.DeepLearning.Layers.layerNorm: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.layerNorm", axes, epsilon, input)


def rms_norm(axes, epsilon, input):
    """HMath.DeepLearning.Layers.rmsNorm: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.rmsNorm", axes, epsilon, input)


def instance_norm(epsilon, input):
    """HMath.DeepLearning.Layers.instanceNorm: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.instanceNorm", epsilon, input)


def group_norm(groups, epsilon, input):
    """HMath.DeepLearning.Layers.groupNorm: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.groupNorm", groups, epsilon, input)


def weight_norm(axis, scales, input):
    """HMath.DeepLearning.Layers.weightNorm: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.weightNorm", axis, scales, input)


XavierUniform = Initializer("HMath.DeepLearning.Layers.XavierUniform")

Initializer.XAVIER_UNIFORM = XavierUniform

XavierNormal = Initializer("HMath.DeepLearning.Layers.XavierNormal")

Initializer.XAVIER_NORMAL = XavierNormal

KaimingUniform = Initializer("HMath.DeepLearning.Layers.KaimingUniform")

Initializer.KAIMING_UNIFORM = KaimingUniform

KaimingNormal = Initializer("HMath.DeepLearning.Layers.KaimingNormal")

Initializer.KAIMING_NORMAL = KaimingNormal


def Orthogonal(scale):
    return Initializer("HMath.DeepLearning.Layers.Orthogonal", (scale,))


Initializer.ORTHOGONAL = staticmethod(Orthogonal)


def TruncatedNormal(mean, standard_deviation, bound):
    return Initializer(
        "HMath.DeepLearning.Layers.TruncatedNormal", (mean, standard_deviation, bound)
    )


Initializer.TRUNCATED_NORMAL = staticmethod(TruncatedNormal)


def initialize_weights(method, fan_in, fan_out, shape, rng):
    """HMath.DeepLearning.Layers.initializeWeights: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Layers.initializeWeights",
        method,
        fan_in,
        fan_out,
        shape,
        rng,
    )


def embedding(weights, indices):
    """HMath.DeepLearning.Layers.embedding: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.embedding", weights, indices)


def dense(input, weights, bias):
    """HMath.DeepLearning.Layers.dense: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.dense", input, weights, bias)


def dense_ad(input, weights, bias):
    """HMath.DeepLearning.Layers.denseAD: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.denseAD", input, weights, bias)


def convolution_stride(options):
    """HMath.DeepLearning.Layers.convolutionStride: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.convolutionStride", options)


def convolution_padding(options):
    """HMath.DeepLearning.Layers.convolutionPadding: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.convolutionPadding", options)


def convolution_dilation(options):
    """HMath.DeepLearning.Layers.convolutionDilation: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.convolutionDilation", options)


def convolution_groups(options):
    """HMath.DeepLearning.Layers.convolutionGroups: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.convolutionGroups", options)


def convolution(options, input, weights, bias):
    """HMath.DeepLearning.Layers.convolution: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Layers.convolution", options, input, weights, bias
    )


def depthwise_convolution(options, input, weights, bias):
    """HMath.DeepLearning.Layers.depthwiseConvolution: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Layers.depthwiseConvolution", options, input, weights, bias
    )


def convolution_ad(options, input, weights, bias):
    """HMath.DeepLearning.Layers.convolutionAD: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Layers.convolutionAD", options, input, weights, bias
    )


def transposed_convolution(output_padding, options, input, weights, bias):
    """HMath.DeepLearning.Layers.transposedConvolution: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Layers.transposedConvolution",
        output_padding,
        options,
        input,
        weights,
        bias,
    )


MaxPool = PoolMode.MAX_POOL

AveragePool = PoolMode.AVERAGE_POOL


def pooling(mode, kernel, stride, padding, input):
    """HMath.DeepLearning.Layers.pooling: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Layers.pooling", mode, kernel, stride, padding, input
    )


def adaptive_pooling(mode, shape, input):
    """HMath.DeepLearning.Layers.adaptivePooling: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.adaptivePooling", mode, shape, input)


def global_pooling(mode, input):
    """HMath.DeepLearning.Layers.globalPooling: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.globalPooling", mode, input)


def scaled_dot_product_attention(query, key, value, mask, bias):
    """HMath.DeepLearning.Layers.scaledDotProductAttention: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Layers.scaledDotProductAttention",
        query,
        key,
        value,
        mask,
        bias,
    )


def multihead_attention(heads, query, key, value, mask):
    """HMath.DeepLearning.Layers.multiheadAttention: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Layers.multiheadAttention", heads, query, key, value, mask
    )


def causal_mask(queries, keys, offset):
    """HMath.DeepLearning.Layers.causalMask: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.causalMask", queries, keys, offset)


def rotary_embedding(base, offset, input):
    """HMath.DeepLearning.Layers.rotaryEmbedding: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.rotaryEmbedding", base, offset, input)


def sinusoidal_encoding(length, dimensions, offset):
    """HMath.DeepLearning.Layers.sinusoidalEncoding: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Layers.sinusoidalEncoding", length, dimensions, offset
    )


def alibi_bias(slope, queries, keys, offset):
    """HMath.DeepLearning.Layers.alibiBias: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.alibiBias", slope, queries, keys, offset)


def empty_cache(capacity, key_dimensions, value_dimensions):
    """HMath.DeepLearning.Layers.emptyCache: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Layers.emptyCache",
        capacity,
        key_dimensions,
        value_dimensions,
    )


def append_cache(cache, key, value):
    """HMath.DeepLearning.Layers.appendCache: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.appendCache", cache, key, value)


def cache_values(cache):
    """HMath.DeepLearning.Layers.cacheValues: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.cacheValues", cache)


def transformer_feed_forward(
    activation, input, first_weights, first_bias, second_weights, second_bias
):
    """HMath.DeepLearning.Layers.transformerFeedForward: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Layers.transformerFeedForward",
        activation,
        input,
        first_weights,
        first_bias,
        second_weights,
        second_bias,
    )


def layer_norm_ad(axes, epsilon, input):
    """HMath.DeepLearning.Layers.layerNormAD: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.layerNormAD", axes, epsilon, input)


def rms_norm_ad(axes, epsilon, input):
    """HMath.DeepLearning.Layers.rmsNormAD: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Layers.rmsNormAD", axes, epsilon, input)


def scaled_dot_product_attention_ad(query, key, value, mask):
    """HMath.DeepLearning.Layers.scaledDotProductAttentionAD: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Layers.scaledDotProductAttentionAD", query, key, value, mask
    )


Symmetric = Quantization.SYMMETRIC

Asymmetric = Quantization.ASYMMETRIC


def quantize(scheme, axis, input):
    """HMath.DeepLearning.Precision.quantize: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Precision.quantize", scheme, axis, input)


def dequantize(quantized):
    """HMath.DeepLearning.Precision.dequantize: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Precision.dequantize", quantized)


def quantized_values(quantized):
    """HMath.DeepLearning.Precision.quantizedValues: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Precision.quantizedValues", quantized)


def quantization_scales(quantized):
    """HMath.DeepLearning.Precision.quantizationScales: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Precision.quantizationScales", quantized)


def quantization_zero_points(quantized):
    """HMath.DeepLearning.Precision.quantizationZeroPoints: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Precision.quantizationZeroPoints", quantized)


def int8_gemm(left, right):
    """HMath.DeepLearning.Precision.int8Gemm: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Precision.int8Gemm", left, right)


FP16 = Precision.FP16

BF16 = Precision.BF16


def reduced_gemm(precision, left, right):
    """HMath.DeepLearning.Precision.reducedGemm: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Precision.reducedGemm", precision, left, right)


def loss_scale(state):
    """HMath.DeepLearning.Precision.lossScale: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Precision.lossScale", state)


def scale_growth_interval(state):
    """HMath.DeepLearning.Precision.scaleGrowthInterval: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Precision.scaleGrowthInterval", state)


def finite_steps(state):
    """HMath.DeepLearning.Precision.finiteSteps: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Precision.finiteSteps", state)


def initial_loss_scaler(scale, growth_interval):
    """HMath.DeepLearning.Precision.initialLossScaler: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Precision.initialLossScaler", scale, growth_interval
    )


def scale_loss(state, loss):
    """HMath.DeepLearning.Precision.scaleLoss: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Precision.scaleLoss", state, loss)


def unscale_gradients(state, gradients):
    """HMath.DeepLearning.Precision.unscaleGradients: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Precision.unscaleGradients", state, gradients)


def update_loss_scaler(finite, state):
    """HMath.DeepLearning.Precision.updateLossScaler: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Precision.updateLossScaler", finite, state)


def gradient_norm(gradient):
    """HMath.DeepLearning.Precision.gradientNorm: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Precision.gradientNorm", gradient)


def clip_gradients(maximum, gradient):
    """HMath.DeepLearning.Precision.clipGradients: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Precision.clipGradients", maximum, gradient)


def accuracy(metrics):
    """HMath.DeepLearning.Metrics.accuracy: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Metrics.accuracy", metrics)


def precision_by_class(metrics):
    """HMath.DeepLearning.Metrics.precisionByClass: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Metrics.precisionByClass", metrics)


def recall_by_class(metrics):
    """HMath.DeepLearning.Metrics.recallByClass: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Metrics.recallByClass", metrics)


def f1_by_class(metrics):
    """HMath.DeepLearning.Metrics.f1ByClass: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Metrics.f1ByClass", metrics)


def confusion_matrix(classes, truth, prediction):
    """HMath.DeepLearning.Metrics.confusionMatrix: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Metrics.confusionMatrix", classes, truth, prediction
    )


def classification_metrics(classes, truth, prediction):
    """HMath.DeepLearning.Metrics.classificationMetrics: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Metrics.classificationMetrics", classes, truth, prediction
    )


def top_k_accuracy(k, truth, scores):
    """HMath.DeepLearning.Metrics.topKAccuracy: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Metrics.topKAccuracy", k, truth, scores)


def roc_auc(truth, scores):
    """HMath.DeepLearning.Metrics.rocAUC: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Metrics.rocAUC", truth, scores)


def pr_auc(truth, scores):
    """HMath.DeepLearning.Metrics.prAUC: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Metrics.prAUC", truth, scores)


def perplexity(negative_log_probabilities):
    """HMath.DeepLearning.Metrics.perplexity: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Metrics.perplexity", negative_log_probabilities)


def cosine_similarity_matrix(left, right):
    """HMath.DeepLearning.Metrics.cosineSimilarityMatrix: original defaults, errors, state and graph rules."""
    return _invoke("HMath.DeepLearning.Metrics.cosineSimilarityMatrix", left, right)


def margin_ranking_loss(margin, left, right, labels):
    """HMath.DeepLearning.Metrics.marginRankingLoss: original defaults, errors, state and graph rules."""
    return _invoke(
        "HMath.DeepLearning.Metrics.marginRankingLoss", margin, left, right, labels
    )


# END GENERATED
