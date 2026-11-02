# SPDX-License-Identifier: MPL-2.0
"""Compare deep-learning bindings directly with original Haskell algorithms."""

import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from check_tensor_equivalence import SOURCE as TENSOR_SOURCE
from check_tensor_equivalence import close, encode

ROOT = Path(__file__).resolve().parent.parent
SOURCE = (
    TENSOR_SOURCE.split("checked=")[0]
    + r"""
import_placeholder
instance(Enc a,Enc b,Enc c)=>Enc(a,b,c) where enc(a,b,c)="T["++enc a++","++enc b++","++enc c++"]"
instance Enc R.RNG where enc=enc.R.serializeRNG
instance Enc L.BatchNormState where enc s=enc(L.runningMean s,L.runningVariance s,L.batchesSeen s)
instance Enc L.ConvOptions where enc s="Options["++enc(L.convolutionStride s)++","++enc(L.convolutionPadding s)++","++enc(L.convolutionDilation s)++","++enc(L.convolutionGroups s)++"]"
instance Enc P.QuantizedTensor where enc s=enc(P.quantizedValues s,P.quantizationScales s,P.quantizationZeroPoints s)
instance Enc P.LossScaler where enc s=enc(P.lossScale s,P.scaleGrowthInterval s,P.finiteSteps s)
instance Enc Q.ClassificationMetrics where enc s="Metrics["++enc(Q.accuracy s)++","++enc(Q.precisionByClass s)++","++enc(Q.recallByClass s)++","++enc(Q.f1ByClass s)++"]"
instance Enc L.KVCache where enc=enc.L.cacheValues
checked=either(error.show)id
make dims xs=checked(T.tensor dims xs)::T.Tensor Double
x=make[2,2][1.1,-2.3,3.7,4.2]
w=make[2,2][0.5,0.7,-0.8,1.2]
image=make[1,1,4][1,2,3,4]
kernel=make[1,1,2][0.3,0.7]
options=L.ConvOptions[1][0][1]1
rng=R.seedRNG R.PCG32 42
state=L.BatchNormState[0,0][1,1]0
scale=P.LossScaler 128 2 0
admake dims xs=checked(A.adTensor dims xs)
adresult point out=out >>= (\result->A.valueAndGradient(\_->A.adSum result)point)
adx=admake[2,2](map A.variable[0..3])
adw=admake[2,2](map A.constant[0.5,0.7,-0.8,1.2])
main=sequence_(map(>>=putStrLn)[CASES])
"""
)
SOURCE = SOURCE.replace("import_placeholder\n", "").replace(
    "class Enc a",
    "import qualified HMath.DeepLearning.Core as C\nimport qualified HMath.DeepLearning.Layers as L\nimport qualified HMath.DeepLearning.Precision as P\nimport qualified HMath.DeepLearning.Metrics as Q\nimport qualified HMath.Autodiff as A\nimport qualified HMath.Random as R\nclass Enc a",
)


def cases(n, t, ad, r):
    owned = []

    def keep(value):
        owned.append(value)
        return value

    def make(shape, data):
        return keep(t.tensor(shape, data))

    x = make([2, 2], [1.1, -2.3, 3.7, 4.2])
    w = make([2, 2], [0.5, 0.7, -0.8, 1.2])
    image = make([1, 1, 4], [1, 2, 3, 4])
    kernel = make([1, 1, 2], [0.3, 0.7])
    options = n.ConvOptions([1], [0], [1], 1)
    state = n.BatchNormState([0, 0], [1, 1], 0)
    scale = n.LossScaler(128, 2, 0)
    generator = keep(r.pcg32())
    rng = keep(r.seed_rng(generator, 42))
    selected = []

    def add(name, hs, call):
        selected.append((name, "pure(enc(" + hs + "))", call))

    def scalar_ad(method, point):
        return ad.value_and_gradient(
            lambda xs: n.activation_expr(method, xs[0]), [point]
        )

    activations = [
        ("Sigmoid", n.Sigmoid),
        ("Tanh", n.Tanh),
        ("ReLU", n.ReLU),
        ("LeakyReLU 0.2", n.LeakyReLU(0.2)),
        ("PReLU 0.3", n.PReLU(0.3)),
        ("ELU 0.8", n.ELU(0.8)),
        ("SELU", n.SELU),
        ("GELU", n.GELU),
        ("SiLU", n.SiLU),
        ("Mish", n.Mish),
        ("Softplus", n.Softplus),
        ("Softsign", n.Softsign),
        ("HardSigmoid", n.HardSigmoid),
        ("HardSwish", n.HardSwish),
    ]
    for hs, method in activations:
        for point in [-0.75, 0, 1.25]:
            add(
                "activation " + hs + str(point),
                "C.activation(C." + hs + ")(" + str(point) + ")",
                lambda method=method, point=point: n.activation(method, point),
            )
            add(
                "activationDerivative " + hs + str(point),
                "C.activationDerivative(C." + hs + ")(" + str(point) + ")",
                lambda method=method, point=point: n.activation_derivative(
                    method, point
                ),
            )
        add(
            "activationExpr " + hs,
            "A.valueAndGradient(\\xs->C.activationExpr(C." + hs + ")(head xs))[-0.75]",
            lambda method=method: scalar_ad(method, -0.75),
        )
    losses = [
        ("MeanSquaredError", n.MeanSquaredError, [0.2, 0.8], [0.4, 0.6]),
        ("MeanAbsoluteError", n.MeanAbsoluteError, [0.2, 0.8], [0.4, 0.6]),
        ("Huber 0.3", n.Huber(0.3), [0.2, 0.8], [0.4, 0.6]),
        ("SmoothL1 0.3", n.SmoothL1(0.3), [0.2, 0.8], [0.4, 0.6]),
        ("BinaryCrossEntropy", n.BinaryCrossEntropy, [0.2, 0.8], [0.4, 0.6]),
        ("CategoricalCrossEntropy", n.CategoricalCrossEntropy, [0.2, 0.8], [0.4, 0.6]),
        ("NegativeLogLikelihood", n.NegativeLogLikelihood, [0.2, 0.8], [-0.4, -0.6]),
        ("KLDivergence", n.KLDivergence, [0.2, 0.8], [0.4, 0.6]),
        ("CosineLoss", n.CosineLoss, [0.2, 0.8], [0.4, 0.6]),
        ("Hinge 1", n.Hinge(1), [-1, 1], [0.4, 0.6]),
    ]
    for hs, method, target, prediction in losses:
        args = str(target) + str(prediction)
        for hsfn, pyfn in [("loss", n.loss), ("lossGradient", n.loss_gradient)]:
            add(
                hsfn + hs,
                "C." + hsfn + "(C." + hs + ")C.Mean " + args,
                lambda method=method, target=target, prediction=prediction, pyfn=pyfn: (
                    pyfn(method, n.Mean, target, prediction)
                ),
            )
        add(
            "lossExpr" + hs,
            "A.valueAndGradient(C.lossExpr(C."
            + hs
            + ")C.Mean "
            + str(target)
            + ")"
            + str(prediction),
            lambda method=method, target=target, prediction=prediction: (
                ad.value_and_gradient(
                    lambda xs: n.loss_expr(method, n.Mean, target, xs), prediction
                )
            ),
        )
    for hsfn, pyfn in [
        ("softmax", n.softmax),
        ("logSoftmax", n.log_softmax),
        ("sparsemax", n.sparsemax),
    ]:
        add(hsfn, "C." + hsfn + "[-3,1,2]", lambda pyfn=pyfn: pyfn([-3, 1, 2]))
    for hsfn, pyfn in [
        ("softmaxExpr", n.softmax_expr),
        ("logSoftmaxExpr", n.log_softmax_expr),
        ("sparsemaxExpr", n.sparsemax_expr),
    ]:
        add(
            hsfn,
            "A.jacobian(C." + hsfn + ")[-3,1,2]",
            lambda pyfn=pyfn: ad.jacobian(pyfn, [-3, 1, 2]),
        )
    entries = [
        ("gatedLinearUnit", "gated_linear_unit", "[1,2][-1,3]", ([1, 2], [-1, 3])),
        (
            "binaryCrossEntropyLogits",
            "binary_cross_entropy_logits",
            "C.Sum[0,1][-1000,1000]",
            (n.Sum, [0, 1], [-1000, 1000]),
        ),
        (
            "categoricalCrossEntropyLogits",
            "categorical_cross_entropy_logits",
            "[0.2,0.8][1000,1001]",
            ([0.2, 0.8], [1000, 1001]),
        ),
        ("regularization", "regularization", "0.3 0.4[-2,3]", (0.3, 0.4, [-2, 3])),
        (
            "contrastiveLoss",
            "contrastive_loss",
            "2 False[1,2][1.5,3]",
            (2, False, [1, 2], [1.5, 3]),
        ),
        (
            "tripletLoss",
            "triplet_loss",
            "0.5[1,2][1.5,2][2,3]",
            (0.5, [1, 2], [1.5, 2], [2, 3]),
        ),
        (
            "focalLoss",
            "focal_loss",
            "0.25 2[0,1][0.2,0.8]",
            (0.25, 2, [0, 1], [0.2, 0.8]),
        ),
        ("diceLoss", "dice_loss", "0.1[0,1][0.2,0.8]", (0.1, [0, 1], [0.2, 0.8])),
        ("iouLoss", "iou_loss", "0.1[0,1][0.2,0.8]", (0.1, [0, 1], [0.2, 0.8])),
        (
            "ctcLoss",
            "ctc_loss",
            "0[1][[-0.3,-1.3],[-0.2,-1.7]]",
            (0, [1], [[-0.3, -1.3], [-0.2, -1.7]]),
        ),
        (
            "ctcLossGradient",
            "ctc_loss_gradient",
            "0[1][[-0.3,-1.3],[-0.2,-1.7]]",
            (0, [1], [[-0.3, -1.3], [-0.2, -1.7]]),
        ),
    ]
    for hs, py, args, values in entries:
        add(
            hs,
            "C." + hs + " " + args,
            lambda py=py, values=values: getattr(n, py)(*values),
        )
    add(
        "ctcLossExpr",
        r"A.valueAndGradient(\xs->checked(C.ctcLossExpr 0[1][take 2 xs,drop 2 xs]))[-0.3,-1.3,-0.2,-1.7]",
        lambda: ad.value_and_gradient(
            lambda xs: n.ctc_loss_expr(0, [1], [xs[:2], xs[2:]]),
            [-0.3, -1.3, -0.2, -1.7],
        ),
    )
    add(
        "dropout training",
        "L.dropout L.Training 0.3 rng x",
        lambda: n.dropout(n.Training.TRAINING, 0.3, rng, x),
    )
    add(
        "dropout inference",
        "L.dropout L.Inference 0.3 rng x",
        lambda: n.dropout(n.Inference, 0.3, rng, x),
    )
    add(
        "spatial dropout",
        "L.spatialDropout L.Training 0.4 rng image",
        lambda: n.spatial_dropout(n.Training.TRAINING, 0.4, rng, image),
    )
    for mode, tag in [(n.Training.TRAINING, "Training"), (n.Inference, "Inference")]:
        add(
            "batch norm" + tag,
            "L.batchNorm L." + tag + " 0.1 1e-5[1,2][0,0]state x",
            lambda mode=mode: n.batch_norm(mode, 0.1, 1e-5, [1, 2], [0, 0], state, x),
        )
    for hs, py, args, values in [
        ("layerNorm", "layer_norm", "1 1e-5 x", (1, 1e-5, x)),
        ("rmsNorm", "rms_norm", "1 1e-5 x", (1, 1e-5, x)),
        ("instanceNorm", "instance_norm", "1e-5 image", (1e-5, image)),
        ("groupNorm", "group_norm", "1 1e-5 image", (1, 1e-5, image)),
        ("weightNorm", "weight_norm", "0[1,2]x", (0, [1, 2], x)),
    ]:
        add(
            hs,
            "L." + hs + " " + args,
            lambda py=py, values=values: getattr(n, py)(*values),
        )
    initializers = [
        ("XavierUniform", n.XavierUniform),
        ("XavierNormal", n.XavierNormal),
        ("KaimingUniform", n.KaimingUniform),
        ("KaimingNormal", n.KaimingNormal),
        ("Orthogonal 0.9", n.Orthogonal(0.9)),
        ("TruncatedNormal 0 1 2", n.TruncatedNormal(0, 1, 2)),
    ]
    for hs, method in initializers:
        add(
            "initialize" + hs,
            "L.initializeWeights(L." + hs + ")2 2[2,2]rng",
            lambda method=method: n.initialize_weights(method, 2, 2, [2, 2], rng),
        )
    add("embedding", "L.embedding x[1,0,1]", lambda: n.embedding(x, [1, 0, 1]))
    add("dense", "L.dense x w[0.1,0.2]", lambda: n.dense(x, w, [0.1, 0.2]))
    for hs, py in [
        ("convolution", "convolution"),
        ("depthwiseConvolution", "depthwise_convolution"),
    ]:
        add(
            hs,
            "L." + hs + " options image kernel[0.1]",
            lambda py=py: getattr(n, py)(options, image, kernel, [0.1]),
        )
    add(
        "transposed conv",
        "L.transposedConvolution[0]options image kernel[0.1]",
        lambda: n.transposed_convolution([0], options, image, kernel, [0.1]),
    )
    for hs, py, args, values in [
        (
            "pooling",
            "pooling",
            "L.MaxPool[2][1][0]image",
            (n.MaxPool, [2], [1], [0], image),
        ),
        (
            "pooling",
            "pooling",
            "L.AveragePool[2][1][1]image",
            (n.AveragePool, [2], [1], [1], image),
        ),
        (
            "adaptivePooling",
            "adaptive_pooling",
            "L.MaxPool[2]image",
            (n.MaxPool, [2], image),
        ),
        (
            "globalPooling",
            "global_pooling",
            "L.AveragePool image",
            (n.AveragePool, image),
        ),
    ]:
        add(
            hs + args,
            "L." + hs + " " + args,
            lambda py=py, values=values: getattr(n, py)(*values),
        )
    add(
        "attention",
        "L.scaledDotProductAttention x w x(Just[[True,False],[False,False]])(Just[[0.1,0.2],[0,0]])",
        lambda: n.scaled_dot_product_attention(
            x, w, x, [[True, False], [False, False]], [[0.1, 0.2], [0, 0]]
        ),
    )
    add(
        "multihead",
        "L.multiheadAttention 2 x w x Nothing",
        lambda: n.multihead_attention(2, x, w, x, None),
    )
    add("causal", "L.causalMask 2 3 1", lambda: n.causal_mask(2, 3, 1))
    add(
        "rotary", "L.rotaryEmbedding 10000 3 x", lambda: n.rotary_embedding(10000, 3, x)
    )
    add(
        "sinusoidal",
        "L.sinusoidalEncoding 3 5 2",
        lambda: n.sinusoidal_encoding(3, 5, 2),
    )
    add("alibi", "L.alibiBias 0.4 2 3 1", lambda: n.alibi_bias(0.4, 2, 3, 1))
    add("empty cache", "L.emptyCache 4 2 2", lambda: n.empty_cache(4, 2, 2))
    cache = keep(n.empty_cache(4, 2, 2))
    appended = keep(n.append_cache(cache, x, w))
    add(
        "append cache",
        r"L.emptyCache 4 2 2 >>= \c->L.appendCache c x w",
        lambda: n.append_cache(cache, x, w),
    )
    add(
        "cache values",
        r"L.cacheValues(checked(L.emptyCache 4 2 2 >>= \c->L.appendCache c x w))",
        lambda: n.cache_values(appended),
    )
    add(
        "feed forward",
        "L.transformerFeedForward C.GELU x w[0.1,0.2]w[0.3,0.4]",
        lambda: n.transformer_feed_forward(n.GELU, x, w, [0.1, 0.2], w, [0.3, 0.4]),
    )

    def adtensor_result(operation, point=(1.1, -2.3, 3.7, 4.2)):
        def objective(xs):
            with (
                ad.ad_tensor([2, 2], xs) as tx,
                ad.ad_tensor([2, 2], [0.5, 0.7, -0.8, 1.2]) as tw,
                operation(tx, tw) as result,
            ):
                return ad.ad_sum(result)

        return ad.value_and_gradient(objective, point)

    add(
        "denseAD",
        "adresult[1.1,-2.3,3.7,4.2](L.denseAD adx adw[0.1,0.2])",
        lambda: adtensor_result(lambda tx, tw: n.dense_ad(tx, tw, [0.1, 0.2])),
    )
    for hs, py in [("layerNormAD", "layer_norm_ad"), ("rmsNormAD", "rms_norm_ad")]:
        add(
            hs,
            "adresult[1.1,-2.3,3.7,4.2](L." + hs + " 1 1e-5 adx)",
            lambda py=py: adtensor_result(lambda tx, tw: getattr(n, py)(1, 1e-5, tx)),
        )
    add(
        "attentionAD",
        "adresult[1.1,-2.3,3.7,4.2](L.scaledDotProductAttentionAD adx adw adx(Just[[True,False],[True,True]]))",
        lambda: adtensor_result(
            lambda tx, tw: n.scaled_dot_product_attention_ad(
                tx, tw, tx, [[True, False], [True, True]]
            )
        ),
    )

    def convad():
        def objective(xs):
            with (
                ad.ad_tensor([1, 1, 4], xs) as tx,
                ad.ad_tensor([1, 1, 2], [0.3, 0.7]) as tw,
                n.convolution_ad(options, tx, tw, [0.1]) as out,
            ):
                return ad.ad_sum(out)

        return ad.value_and_gradient(objective, [1, 2, 3, 4])

    add(
        "convolutionAD",
        "adresult[1,2,3,4](L.convolutionAD options(admake[1,1,4](map A.variable[0..3]))(admake[1,1,2](map A.constant[0.3,0.7]))[0.1])",
        convad,
    )
    for scheme, tag in [(n.Symmetric, "Symmetric"), (n.Asymmetric, "Asymmetric")]:
        for axis in [None, 0]:
            hs = (
                "P.quantize P."
                + tag
                + (" Nothing" if axis is None else "(Just 0)")
                + " x"
            )
            qt = keep(n.quantize(scheme, axis, x))
            add(
                "quantize" + tag + str(axis),
                hs,
                lambda scheme=scheme, axis=axis: n.quantize(scheme, axis, x),
            )
            add(
                "dequantize" + tag + str(axis),
                hs + " >>= P.dequantize",
                lambda qt=qt: n.dequantize(qt),
            )
    left = keep(n.quantize(n.Symmetric, 0, x))
    right = keep(n.quantize(n.Asymmetric, 1, w))
    add(
        "int8Gemm",
        "do a<-P.quantize P.Symmetric(Just 0)x;b<-P.quantize P.Asymmetric(Just 1)w;P.int8Gemm a b",
        lambda: n.int8_gemm(left, right),
    )
    for precision, tag in [(n.FP16, "FP16"), (n.BF16, "BF16")]:
        add(
            "reducedGemm" + tag,
            "P.reducedGemm P." + tag + " x w",
            lambda precision=precision: n.reduced_gemm(precision, x, w),
        )
    for hs, py, args, values in [
        ("initialLossScaler", "initial_loss_scaler", "128 2", (128, 2)),
        ("scaleLoss", "scale_loss", "scale 0.3", (scale, 0.3)),
        (
            "unscaleGradients",
            "unscale_gradients",
            "scale[128,256]",
            (scale, [128, 256]),
        ),
        (
            "unscaleGradients",
            "unscale_gradients",
            "scale[1/0]",
            (scale, [float("inf")]),
        ),
        ("updateLossScaler", "update_loss_scaler", "True scale", (True, scale)),
        ("updateLossScaler", "update_loss_scaler", "False scale", (False, scale)),
        ("gradientNorm", "gradient_norm", "[3,4]", ([3, 4],)),
        ("clipGradients", "clip_gradients", "2[3,4]", (2, [3, 4])),
    ]:
        add(
            hs + args,
            "P." + hs + " " + args,
            lambda py=py, values=values: getattr(n, py)(*values),
        )
    for hs, py, args, values in [
        (
            "confusionMatrix",
            "confusion_matrix",
            "3[0,1,1,2][0,2,1,2]",
            (3, [0, 1, 1, 2], [0, 2, 1, 2]),
        ),
        (
            "classificationMetrics",
            "classification_metrics",
            "3[0,1,1,2][0,2,1,2]",
            (3, [0, 1, 1, 2], [0, 2, 1, 2]),
        ),
        (
            "topKAccuracy",
            "top_k_accuracy",
            "2[0,2][[1,2,3],[2,1,3]]",
            (2, [0, 2], [[1, 2, 3], [2, 1, 3]]),
        ),
        (
            "rocAUC",
            "roc_auc",
            "[False,True,False,True][0.1,0.8,0.4,0.8]",
            ([False, True, False, True], [0.1, 0.8, 0.4, 0.8]),
        ),
        (
            "prAUC",
            "pr_auc",
            "[False,True,False,True][0.1,0.8,0.4,0.8]",
            ([False, True, False, True], [0.1, 0.8, 0.4, 0.8]),
        ),
        ("perplexity", "perplexity", "[0.2,0.7,1.1]", ([0.2, 0.7, 1.1],)),
        ("cosineSimilarityMatrix", "cosine_similarity_matrix", "x w", (x, w)),
        (
            "marginRankingLoss",
            "margin_ranking_loss",
            "0.3[1,2][0.5,3][1,-1]",
            (0.3, [1, 2], [0.5, 3], [1, -1]),
        ),
    ]:
        add(
            hs,
            "Q." + hs + " " + args,
            lambda py=py, values=values: getattr(n, py)(*values),
        )
    for name, hs, call in [
        ("badELU", "C.activation(C.ELU 0)1", lambda: n.activation(n.ELU(0), 1)),
        ("emptySoftmax", "C.softmax[]", lambda: n.softmax([])),
        (
            "badProbability",
            "C.loss C.BinaryCrossEntropy C.Mean[1][0]",
            lambda: n.loss(n.BinaryCrossEntropy, n.Mean, [1], [0]),
        ),
        (
            "badDropout",
            "L.dropout L.Training 1 rng x",
            lambda: n.dropout(n.Training.TRAINING, 1, rng, x),
        ),
        ("badCache", "L.emptyCache 0 1 1", lambda: n.empty_cache(0, 1, 1)),
        (
            "badQuantization",
            "P.quantize P.Symmetric(Just 7)x",
            lambda: n.quantize(n.Symmetric, 7, x),
        ),
        (
            "badMetric",
            "Q.rocAUC[True,True][0.1,0.2]",
            lambda: n.roc_auc([True, True], [0.1, 0.2]),
        ),
    ]:
        add(name, hs, call)
    return selected, owned


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", required=True, type=Path)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(args.library.resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    from _hmath_native import _neural_base as n
    from _hmath_native import _tensor_core as t
    from _hmath_native import autodiff as ad
    from _hmath_native import random_values as r

    def enc(value):
        if isinstance(value, n.QuantizedTensor):
            return enc((value.values, value.scales, value.zero_points))
        if isinstance(value, n.KVCache):
            outputs = n.cache_values(value)
            try:
                return enc(outputs)
            finally:
                close(outputs)
        if isinstance(value, r.RNG):
            return enc(value.serialize())
        if isinstance(value, n.BatchNormState):
            return enc((value.running_mean, value.running_variance, value.batches_seen))
        if isinstance(value, n.LossScaler):
            return enc((value.scale, value.growth_interval, value.finite_steps))
        if isinstance(value, n.ClassificationMetrics):
            return (
                "Metrics["
                + ",".join(
                    enc(x)
                    for x in [value.accuracy, value.precision, value.recall, value.f1]
                )
                + "]"
            )
        if isinstance(value, (list, tuple)):
            return (
                ("T[" if isinstance(value, tuple) else "L[")
                + ",".join(enc(x) for x in value)
                + "]"
            )
        return encode(value, t)

    selected, owned = cases(n, t, ad, r)
    try:
        with tempfile.TemporaryDirectory(prefix="hmath-neural-oracle-") as temporary:
            path = Path(temporary)
            source = path / "Main.hs"
            source.write_text(
                SOURCE.replace("CASES", ",\n  ".join(expr for _, expr, _ in selected))
            )
            subprocess.run(
                [
                    "ghc",
                    "-XHaskell2010",
                    "-O1",
                    "-i" + str(ROOT / "src"),
                    "-outputdir",
                    temporary,
                    str(source),
                    "-o",
                    str(path / "oracle"),
                ],
                check=True,
                stdout=subprocess.DEVNULL,
            )
            expected = subprocess.check_output(
                [str(path / "oracle")], text=True
            ).splitlines()
        for (name, _, call), reference in zip(selected, expected, strict=True):
            value = None
            try:
                value = call()
                actual = enc(value)
            except hmath.HMathError as error:
                if error.math_error is None:
                    raise
                actual = "ERR" + str(error.math_error)
            finally:
                close(value)
            if actual != reference:
                raise AssertionError(f"{name}: native {actual}, original {reference}")
        print(
            f"Deep-learning equivalence: {len(selected)} independent original Haskell sequences match IEEE bits, full state/RNG, graph values/gradients and errors."
        )
    finally:
        close(owned)


if __name__ == "__main__":
    main()
