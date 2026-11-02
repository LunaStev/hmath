# SPDX-License-Identifier: MPL-2.0
"""Generate direct named adapters for every original DeepLearning public symbol."""

import argparse
import ast
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
S = []


def snake(name):
    special = {
        "ReLU": "relu",
        "LeakyReLU": "leaky_relu",
        "PReLU": "prelu",
        "SiLU": "silu",
    }
    return special.get(
        name,
        re.sub(
            r"([a-z0-9])([A-Z])",
            r"\1_\2",
            re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", name),
        ).lower(),
    )


def add(module, name, args, result):
    S.append(
        {
            "module": "HMath.DeepLearning." + module,
            "name": name,
            "arguments": args,
            "result": result,
            "python": snake(name),
            "c": "hmath_neural_"
            + module.lower()
            + "_"
            + snake(name)
            + ("_create" if name[0].isupper() else ""),
            "expression": {
                "Core": "C",
                "Layers": "L",
                "Precision": "P",
                "Metrics": "M",
            }[module]
            + "."
            + name,
        }
    )


for name in [
    "Sigmoid",
    "Tanh",
    "ReLU",
    "SELU",
    "GELU",
    "SiLU",
    "Mish",
    "Softplus",
    "Softsign",
    "HardSigmoid",
    "HardSwish",
]:
    add("Core", name, [], "Activation")
for name in ["LeakyReLU", "PReLU", "ELU"]:
    add("Core", name, [("parameter", "Double")], "Activation")
for name in ["Sum", "Mean"]:
    add("Core", name, [], "Reduction")
for name in [
    "MeanSquaredError",
    "MeanAbsoluteError",
    "BinaryCrossEntropy",
    "CategoricalCrossEntropy",
    "NegativeLogLikelihood",
    "KLDivergence",
    "CosineLoss",
]:
    add("Core", name, [], "Loss")
for name in ["Huber", "SmoothL1", "Hinge"]:
    add("Core", name, [("parameter", "Double")], "Loss")
for name in ["activation", "activationDerivative"]:
    add("Core", name, [("method", "Activation"), ("value", "Double")], "Double")
add("Core", "activationExpr", [("method", "Activation"), ("value", "ADExpr")], "ADExpr")
for name in ["softmax", "logSoftmax", "sparsemax"]:
    add("Core", name, [("values", "[Double]")], "[Double]")
add(
    "Core",
    "gatedLinearUnit",
    [("values", "[Double]"), ("gate", "[Double]")],
    "[Double]",
)
for name in ["softmaxExpr", "logSoftmaxExpr", "sparsemaxExpr"]:
    add("Core", name, [("values", "[ADExpr]")], "[ADExpr]")
for name, result in [("loss", "Double"), ("lossGradient", "[Double]")]:
    add(
        "Core",
        name,
        [
            ("method", "Loss"),
            ("reduction", "Reduction"),
            ("target", "[Double]"),
            ("prediction", "[Double]"),
        ],
        result,
    )
add(
    "Core",
    "lossExpr",
    [
        ("method", "Loss"),
        ("reduction", "Reduction"),
        ("target", "[Double]"),
        ("prediction", "[ADExpr]"),
    ],
    "ADExpr",
)
add(
    "Core",
    "binaryCrossEntropyLogits",
    [("reduction", "Reduction"), ("target", "[Double]"), ("logits", "[Double]")],
    "Double",
)
add(
    "Core",
    "categoricalCrossEntropyLogits",
    [("target", "[Double]"), ("logits", "[Double]")],
    "Double",
)
add(
    "Core",
    "regularization",
    [("l1", "Double"), ("l2", "Double"), ("weights", "[Double]")],
    "Double",
)
add(
    "Core",
    "contrastiveLoss",
    [
        ("margin", "Double"),
        ("similar", "Bool"),
        ("left", "[Double]"),
        ("right", "[Double]"),
    ],
    "Double",
)
add(
    "Core",
    "tripletLoss",
    [
        ("margin", "Double"),
        ("anchor", "[Double]"),
        ("positive", "[Double]"),
        ("negative", "[Double]"),
    ],
    "Double",
)
add(
    "Core",
    "focalLoss",
    [
        ("alpha", "Double"),
        ("gamma", "Double"),
        ("target", "[Double]"),
        ("prediction", "[Double]"),
    ],
    "Double",
)
for name in ["diceLoss", "iouLoss"]:
    add(
        "Core",
        name,
        [("smooth", "Double"), ("target", "[Double]"), ("prediction", "[Double]")],
        "Double",
    )
for name, result, values in [
    ("ctcLoss", "Double", "[[Double]]"),
    ("ctcLossGradient", "(Double,[[Double]])", "[[Double]]"),
    ("ctcLossExpr", "ADExpr", "[[ADExpr]]"),
]:
    add(
        "Core",
        name,
        [("blank", "Int"), ("labels", "[Int]"), ("log_probabilities", values)],
        result,
    )
for name in ["Training", "Inference"]:
    add("Layers", name, [], "Training")
for name in ["dropout", "spatialDropout"]:
    add(
        "Layers",
        name,
        [
            ("mode", "Training"),
            ("probability", "Double"),
            ("rng", "RNG"),
            ("input", "Tensor"),
        ],
        "(Tensor,Tensor,RNG)",
    )
add(
    "Layers",
    "BatchNormState",
    [
        ("running_mean", "[Double]"),
        ("running_variance", "[Double]"),
        ("batches_seen", "Int"),
    ],
    "BatchNormState",
)
for name, result in [
    ("runningMean", "[Double]"),
    ("runningVariance", "[Double]"),
    ("batchesSeen", "Int"),
]:
    add("Layers", name, [("state", "BatchNormState")], result)
add(
    "Layers",
    "batchNorm",
    [
        ("mode", "Training"),
        ("momentum", "Double"),
        ("epsilon", "Double"),
        ("gamma", "[Double]"),
        ("beta", "[Double]"),
        ("state", "BatchNormState"),
        ("input", "Tensor"),
    ],
    "(Tensor,BatchNormState)",
)
for name in ["layerNorm", "rmsNorm"]:
    add(
        "Layers",
        name,
        [("axes", "Int"), ("epsilon", "Double"), ("input", "Tensor")],
        "Tensor",
    )
add("Layers", "instanceNorm", [("epsilon", "Double"), ("input", "Tensor")], "Tensor")
add(
    "Layers",
    "groupNorm",
    [("groups", "Int"), ("epsilon", "Double"), ("input", "Tensor")],
    "Tensor",
)
add(
    "Layers",
    "weightNorm",
    [("axis", "Int"), ("scales", "[Double]"), ("input", "Tensor")],
    "Tensor",
)
for name in ["XavierUniform", "XavierNormal", "KaimingUniform", "KaimingNormal"]:
    add("Layers", name, [], "Initializer")
add("Layers", "Orthogonal", [("scale", "Double")], "Initializer")
add(
    "Layers",
    "TruncatedNormal",
    [("mean", "Double"), ("standard_deviation", "Double"), ("bound", "Double")],
    "Initializer",
)
add(
    "Layers",
    "initializeWeights",
    [
        ("method", "Initializer"),
        ("fan_in", "Int"),
        ("fan_out", "Int"),
        ("shape", "[Int]"),
        ("rng", "RNG"),
    ],
    "(Tensor,RNG)",
)
add("Layers", "embedding", [("weights", "Tensor"), ("indices", "[Int]")], "Tensor")
for suffix, hint in [("", "Tensor"), ("AD", "ADTensor")]:
    add(
        "Layers",
        "dense" + suffix,
        [
            ("input", hint),
            ("weights", hint),
            ("bias", "[ADExpr]" if suffix else "[Double]"),
        ],
        hint,
    )
add(
    "Layers",
    "ConvOptions",
    [
        ("stride", "[Int]"),
        ("padding", "[Int]"),
        ("dilation", "[Int]"),
        ("groups", "Int"),
    ],
    "ConvOptions",
)
for name, result in [
    ("convolutionStride", "[Int]"),
    ("convolutionPadding", "[Int]"),
    ("convolutionDilation", "[Int]"),
    ("convolutionGroups", "Int"),
]:
    add("Layers", name, [("options", "ConvOptions")], result)
for name in ["convolution", "depthwiseConvolution", "convolutionAD"]:
    hint = "ADTensor" if name.endswith("AD") else "Tensor"
    add(
        "Layers",
        name,
        [
            ("options", "ConvOptions"),
            ("input", hint),
            ("weights", hint),
            ("bias", "[ADExpr]" if hint == "ADTensor" else "[Double]"),
        ],
        hint,
    )
add(
    "Layers",
    "transposedConvolution",
    [
        ("output_padding", "[Int]"),
        ("options", "ConvOptions"),
        ("input", "Tensor"),
        ("weights", "Tensor"),
        ("bias", "[Double]"),
    ],
    "Tensor",
)
for name in ["MaxPool", "AveragePool"]:
    add("Layers", name, [], "PoolMode")
add(
    "Layers",
    "pooling",
    [
        ("mode", "PoolMode"),
        ("kernel", "[Int]"),
        ("stride", "[Int]"),
        ("padding", "[Int]"),
        ("input", "Tensor"),
    ],
    "Tensor",
)
add(
    "Layers",
    "adaptivePooling",
    [("mode", "PoolMode"), ("shape", "[Int]"), ("input", "Tensor")],
    "Tensor",
)
add("Layers", "globalPooling", [("mode", "PoolMode"), ("input", "Tensor")], "Tensor")
add(
    "Layers",
    "scaledDotProductAttention",
    [
        ("query", "Tensor"),
        ("key", "Tensor"),
        ("value", "Tensor"),
        ("mask", "Maybe[[Bool]]"),
        ("bias", "Maybe[[Double]]"),
    ],
    "(Tensor,Tensor)",
)
add(
    "Layers",
    "multiheadAttention",
    [
        ("heads", "Int"),
        ("query", "Tensor"),
        ("key", "Tensor"),
        ("value", "Tensor"),
        ("mask", "Maybe[[Bool]]"),
    ],
    "Tensor",
)
add(
    "Layers",
    "causalMask",
    [("queries", "Int"), ("keys", "Int"), ("offset", "Int")],
    "[[Bool]]",
)
add(
    "Layers",
    "rotaryEmbedding",
    [("base", "Double"), ("offset", "Int"), ("input", "Tensor")],
    "Tensor",
)
add(
    "Layers",
    "sinusoidalEncoding",
    [("length", "Int"), ("dimensions", "Int"), ("offset", "Int")],
    "Tensor",
)
add(
    "Layers",
    "alibiBias",
    [("slope", "Double"), ("queries", "Int"), ("keys", "Int"), ("offset", "Int")],
    "[[Double]]",
)
add(
    "Layers",
    "emptyCache",
    [("capacity", "Int"), ("key_dimensions", "Int"), ("value_dimensions", "Int")],
    "KVCache",
)
add(
    "Layers",
    "appendCache",
    [("cache", "KVCache"), ("key", "Tensor"), ("value", "Tensor")],
    "KVCache",
)
add("Layers", "cacheValues", [("cache", "KVCache")], "(Tensor,Tensor)")
add(
    "Layers",
    "transformerFeedForward",
    [
        ("activation", "Activation"),
        ("input", "Tensor"),
        ("first_weights", "Tensor"),
        ("first_bias", "[Double]"),
        ("second_weights", "Tensor"),
        ("second_bias", "[Double]"),
    ],
    "Tensor",
)
for name in ["layerNormAD", "rmsNormAD"]:
    add(
        "Layers",
        name,
        [("axes", "Int"), ("epsilon", "Double"), ("input", "ADTensor")],
        "ADTensor",
    )
add(
    "Layers",
    "scaledDotProductAttentionAD",
    [
        ("query", "ADTensor"),
        ("key", "ADTensor"),
        ("value", "ADTensor"),
        ("mask", "Maybe[[Bool]]"),
    ],
    "ADTensor",
)
for name in ["Symmetric", "Asymmetric"]:
    add("Precision", name, [], "Quantization")
add(
    "Precision",
    "quantize",
    [("scheme", "Quantization"), ("axis", "MaybeInt"), ("input", "Tensor")],
    "QuantizedTensor",
)
add("Precision", "dequantize", [("quantized", "QuantizedTensor")], "Tensor")
for name, result in [
    ("quantizedValues", "[Int8]"),
    ("quantizationScales", "[Double]"),
    ("quantizationZeroPoints", "[Int]"),
]:
    add("Precision", name, [("quantized", "QuantizedTensor")], result)
add(
    "Precision",
    "int8Gemm",
    [("left", "QuantizedTensor"), ("right", "QuantizedTensor")],
    "Tensor",
)
for name in ["FP16", "BF16"]:
    add("Precision", name, [], "Precision")
add(
    "Precision",
    "reducedGemm",
    [("precision", "Precision"), ("left", "Tensor"), ("right", "Tensor")],
    "Tensor",
)
add(
    "Precision",
    "LossScaler",
    [("scale", "Double"), ("growth_interval", "Int"), ("finite_steps", "Int")],
    "LossScaler",
)
for name, result in [
    ("lossScale", "Double"),
    ("scaleGrowthInterval", "Int"),
    ("finiteSteps", "Int"),
]:
    add("Precision", name, [("state", "LossScaler")], result)
add(
    "Precision",
    "initialLossScaler",
    [("scale", "Double"), ("growth_interval", "Int")],
    "LossScaler",
)
add("Precision", "scaleLoss", [("state", "LossScaler"), ("loss", "Double")], "Double")
add(
    "Precision",
    "unscaleGradients",
    [("state", "LossScaler"), ("gradients", "[Double]")],
    "(Bool,[Double])",
)
add(
    "Precision",
    "updateLossScaler",
    [("finite", "Bool"), ("state", "LossScaler")],
    "LossScaler",
)
add("Precision", "gradientNorm", [("gradient", "[Double]")], "Double")
add(
    "Precision",
    "clipGradients",
    [("maximum", "Double"), ("gradient", "[Double]")],
    "[Double]",
)
add(
    "Metrics",
    "ClassificationMetrics",
    [
        ("accuracy", "Double"),
        ("precision", "[Double]"),
        ("recall", "[Double]"),
        ("f1", "[Double]"),
    ],
    "ClassificationMetrics",
)
for name, result in [
    ("accuracy", "Double"),
    ("precisionByClass", "[Double]"),
    ("recallByClass", "[Double]"),
    ("f1ByClass", "[Double]"),
]:
    add("Metrics", name, [("metrics", "ClassificationMetrics")], result)
for name, result in [
    ("confusionMatrix", "[[Int]]"),
    ("classificationMetrics", "ClassificationMetrics"),
]:
    add(
        "Metrics",
        name,
        [("classes", "Int"), ("truth", "[Int]"), ("prediction", "[Int]")],
        result,
    )
add(
    "Metrics",
    "topKAccuracy",
    [("k", "Int"), ("truth", "[Int]"), ("scores", "[[Double]]")],
    "Double",
)
for name in ["rocAUC", "prAUC"]:
    add("Metrics", name, [("truth", "[Bool]"), ("scores", "[Double]")], "Double")
add("Metrics", "perplexity", [("negative_log_probabilities", "[Double]")], "Double")
add(
    "Metrics",
    "cosineSimilarityMatrix",
    [("left", "Tensor"), ("right", "Tensor")],
    "Tensor",
)
add(
    "Metrics",
    "marginRankingLoss",
    [
        ("margin", "Double"),
        ("left", "[Double]"),
        ("right", "[Double]"),
        ("labels", "[Double]"),
    ],
    "Double",
)


def outputs():
    files = {
        ROOT / "bindings/schema/deeplearning.json": json.dumps(
            {"schema": 1, "functions": S}, indent=2
        )
        + "\n",
        ROOT
        / "bindings/python/_hmath_native/_neural_catalog.py": "# SPDX-License-Identifier: MPL-2.0\n# Generated by tools/generate_deeplearning_bindings.py.\nimport json\nCATALOG=json.loads("
        + repr(json.dumps(S, separators=(",", ":")))
        + ")\n",
    }
    headers = []
    native = []
    dispatch = []
    for item in S:
        parameters = (
            ["hmath_context *context"]
            + ["const hmath_value *" + name for name, _ in item["arguments"]]
            + ["hmath_value **out"]
        )
        signature = (
            "hmath_status " + item["c"] + "(\n    " + ",\n    ".join(parameters) + ")"
        )
        headers.append(
            "/* "
            + item["module"]
            + "."
            + item["name"]
            + " -> "
            + item["result"]
            + ". */\nHMATH_API "
            + signature
            + ";\n"
        )
        names = [name for name, _ in item["arguments"]]
        native.append(
            signature
            + " {\n"
            + (
                "    const hmath_value *hm_arguments[]={" + ", ".join(names) + "};\n"
                if names
                else ""
            )
            + '    return invoke(context, "'
            + item["module"]
            + "."
            + item["name"]
            + '", '
            + ("hm_arguments" if names else "NULL")
            + ", "
            + str(len(names))
            + ", out);\n}\n"
        )
        dispatch.append(
            '    "'
            + item["module"]
            + "."
            + item["name"]
            + '" -> apply '
            + item["expression"]
            + " arguments\n"
        )
    for path, mark, end, body in [
        (
            ROOT / "include/hmath_deeplearning.h",
            "/* BEGIN GENERATED */",
            "/* END GENERATED */",
            "\n".join(headers),
        ),
        (
            ROOT / "cbits/deeplearning.c",
            "/* BEGIN GENERATED */",
            "/* END GENERATED */",
            "\n".join(native),
        ),
        (
            ROOT / "src/HMath/FFI/DeepLearning.hs",
            "-- BEGIN GENERATED",
            "-- END GENERATED",
            "".join(dispatch),
        ),
    ]:
        text = path.read_text()
        a = text.index(mark) + len(mark)
        b = text.index(end)
        files[path] = text[:a] + "\n" + body + text[b:]
    enum_names = {"Reduction", "Training", "PoolMode", "Quantization", "Precision"}
    record_names = {
        "BatchNormState",
        "ConvOptions",
        "LossScaler",
        "ClassificationMetrics",
    }
    descriptors = {"Activation", "Loss", "Initializer"}
    tails = []
    exports = {module: set() for module in ["Core", "Layers", "Precision", "Metrics"]}
    for module, names in {
        "Core": ["Activation", "Loss", "Reduction"],
        "Layers": [
            "Training",
            "BatchNormState",
            "Initializer",
            "ConvOptions",
            "PoolMode",
            "KVCache",
        ],
        "Precision": ["Quantization", "Precision", "QuantizedTensor", "LossScaler"],
        "Metrics": ["ClassificationMetrics"],
    }.items():
        exports[module].update(names)
    for entry in S:
        name = entry["name"]
        module = entry["module"].split(".")[-1]
        hint = entry["result"]
        public = name if name[0].isupper() else entry["python"]
        exports[module].add(public)
        if name in record_names or name == "Training":
            continue
        if name[0].isupper() and hint in enum_names:
            tails.append(name + " = " + hint + "." + snake(name).upper() + "\n")
            continue
        parameters = ", ".join(param for param, _ in entry["arguments"])
        if name[0].isupper() and hint in descriptors:
            expression = (
                hint
                + "("
                + repr(entry["module"] + "." + name)
                + (
                    ", ("
                    + parameters
                    + ("," if len(entry["arguments"]) == 1 else "")
                    + "))"
                    if parameters
                    else ")"
                )
            )
            if not parameters:
                tails.append(name + " = " + expression + "\n")
            else:
                tails.append(
                    "def "
                    + name
                    + "("
                    + parameters
                    + "):\n    return "
                    + expression
                    + "\n"
                )
            tails.append(
                hint
                + "."
                + snake(name).upper()
                + " = "
                + ("staticmethod(" + name + ")" if parameters else name)
                + "\n"
            )
            continue
        tails.append(
            "def "
            + public
            + "("
            + parameters
            + '):\n    """'
            + entry["module"]
            + "."
            + name
            + ': original defaults, errors, state and graph rules."""\n    return _invoke('
            + repr(entry["module"] + "." + name)
            + (", " + parameters if parameters else "")
            + ")\n"
        )
    path = ROOT / "bindings/python/_hmath_native/_neural_base.py"
    text = path.read_text()
    a = text.index("# BEGIN GENERATED") + len("# BEGIN GENERATED")
    b = text.index("# END GENERATED")
    files[path] = text[:a] + "\n" + "\n".join(tails) + text[b:]
    numeric = json.loads((ROOT / "bindings/schema/numeric.json").read_text())[
        "functions"
    ]
    for module, public in exports.items():
        excluded = {
            entry["python"]
            for entry in numeric
            if entry["module"] == "HMath.DeepLearning." + module
        }
        path = ROOT / (
            "bindings/python/_hmath_native/"
            + (
                "deeplearning_layers"
                if module == "Layers"
                else "_neural_" + module.lower()
            )
            + ".py"
        )
        files[path] = (
            '# SPDX-License-Identifier: MPL-2.0\n"""Original HMath.DeepLearning.'
            + module
            + ' complete typed adapters."""\nfrom ._neural_base import (\n'
            + "".join(
                "    " + name + ",\n"
                for name in sorted(
                    public - excluded,
                    key=lambda name: (not name.isupper(), name[0].islower(), name.casefold()),
                )
            )
            + ")\n\n__all__ = "
            + repr(
                sorted(public - excluded, key=lambda name: (not name.isupper(), name))
            )
            + "\n"
        )
    return files


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    for path, text in outputs().items():
        if args.check:
            same = (
                ast.dump(ast.parse(path.read_text())) == ast.dump(ast.parse(text))
                if path.suffix == ".py"
                else path.read_text() == text
            )
            if not same:
                raise SystemExit(str(path.relative_to(ROOT)) + " is stale")
        else:
            path.write_text(text)
    print(
        f"DeepLearning: {len(S)} direct original constructor/function/selector dispatches."
    )


if __name__ == "__main__":
    main()
