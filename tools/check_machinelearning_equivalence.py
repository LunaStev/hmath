# SPDX-License-Identifier: MPL-2.0
"""Compare the complete ML bridge against independent original Haskell calls."""

import argparse
import math
import os
import struct
import subprocess
import sys
import tempfile
from fractions import Fraction
from pathlib import Path

from generate_graph_bindings import snake, split_top
from generate_machinelearning_bindings import metadata

ROOT = Path(__file__).resolve().parent.parent


def fp(value):
    return (
        "nan"
        if math.isnan(value)
        else str(struct.unpack("!Q", struct.pack("!d", value))[0])
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", type=Path, required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(args.library.resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    from _hmath_native import autodiff as ad
    from _hmath_native import backend, graph
    from _hmath_native import expression as expr_module
    from _hmath_native import machinelearning as m
    from _hmath_native import numeric_types as numeric
    from _hmath_native._math_error import MathError, MathErrorKind
    from _hmath_native._value import Value

    data = metadata()
    types = {e["name"] for e in data["types"]}
    owners = []

    def own(x):
        owners.append(x)
        return x

    xs = [[0.1, 0.2], [0.3, 0.4], [0.6, 0.1], [1.1, 1.3], [1.4, 1.8], [1.8, 1.2]]
    zs = [[0.2, 0.1], [0.4, 0.3], [0.1, 0.7], [1.3, 1.1], [1.8, 1.4], [1.2, 1.8]]
    ys = [0.4, 0.9, 1.3, 2.6, 3.2, 4.0]
    labels = [0, 0, 0, 1, 1, 1]
    binary = [0.0, 0.0, 0.0, 1.0, 1.0, 1.0]
    signed = [-1.0, -1.0, -1.0, 1.0, 1.0, 1.0]
    cfg = own(m.ml_config(8, 1e-7, 0.05, 42))
    badcfg = own(m.ml_config(-1, 1e-7, 0.05, 42))
    cache = {"MLConfig": cfg}
    lines = [
        "import qualified HMath.MachineLearning as M",
        "import qualified HMath.Autodiff as A",
        "import qualified HMath.Backend as B",
        "import qualified HMath.Graph.Core as G",
        "import qualified HMath.Expression as E",
        "import HMath.Error (MathError)",
        "import Data.List (intercalate)",
        "import Data.Ratio",
        "import Data.Word (Word64)",
        "import GHC.Float",
        'fp x=if isNaN x then "nan" else show (castDoubleToWord64 x)',
        'list e xs="["++intercalate "," (map e xs)++"]"',
        "right (Right x)=x",
        "right (Left e)=error (show e)",
        "emit :: (a->String)->Either MathError a->IO ()",
        'emit e (Right x)=putStrLn ("OK:"++e x)',
        'emit _ (Left e)=putStrLn ("ERR:"++show e)',
        "cfg=M.MLConfig 8 1e-7 0.05 42",
        "badcfg=M.MLConfig (-1) 1e-7 0.05 42",
        "xs=" + str(xs),
        "zs=" + str(zs),
        "ys=" + str(ys),
        "labels=[0,0,0,1,1,1::Int]",
        "binary=[0,0,0,1,1,1::Double]",
        "signed=[-1,-1,-1,1,1,1::Double]",
        "encoder=right (M.fitEncoder [1,10^100+1,1::Integer])",
        "genericFit=M.Fit xs 3 0.25 False",
        "foldA=M.Fold [0,1,2] [3,4,5]",
        "folds=right (M.kFold 42 2 6)",
        "hierarchy=right (M.hierarchical M.Average xs)",
    ]
    recipe = {
        "Penalty": ("M.Lasso 0.1", lambda: m.lasso(0.1)),
        "LinearModel": (
            "M.fitted (right (M.fitLinear cfg (M.Lasso 0.1) xs ys))",
            lambda: m.fitted(m.fit_linear(cfg, m.lasso(0.1), xs, ys)),
        ),
        "BayesianLinear": (
            "right (M.fitBayesian 1 1 xs ys)",
            lambda: m.fit_bayesian(1, 1, xs, ys),
        ),
        "RecursiveLS": (
            "right (M.recursiveLS 2 0.99 1)",
            lambda: m.recursive_ls(2, 0.99, 1),
        ),
        "GLMFamily": ("M.BinomialLogit", m.binomial_logit),
        "GLM": (
            "M.fitted (right (M.fitGLM cfg M.BinomialLogit 0.1 xs binary))",
            lambda: m.fitted(m.fit_glm(cfg, m.binomial_logit(), 0.1, xs, binary)),
        ),
        "MultinomialModel": (
            "M.fitted (right (M.fitMultinomial cfg 0.1 xs labels))",
            lambda: m.fitted(m.fit_multinomial(cfg, 0.1, xs, labels)),
        ),
        "Kernel": ("M.RBFKernel 0.5", lambda: m.rbf_kernel(0.5)),
        "SVM": (
            "M.fitted (right (M.fitSVM cfg (M.RBFKernel 0.5) 1 xs signed))",
            lambda: m.fitted(m.fit_svm(cfg, m.rbf_kernel(0.5), 1, xs, signed)),
        ),
        "GaussianProcess": (
            "right (M.fitGaussianProcess (M.RBFKernel 0.5) 0.1 xs ys)",
            lambda: m.fit_gaussian_process(m.rbf_kernel(0.5), 0.1, xs, ys),
        ),
        "GPClassifier": (
            "M.fitted (right (M.fitGPClassifier cfg (M.RBFKernel 0.5) xs binary))",
            lambda: m.fitted(m.fit_gp_classifier(cfg, m.rbf_kernel(0.5), xs, binary)),
        ),
        "BayesFamily": ("M.GaussianBayes", m.gaussian_bayes),
        "NaiveBayes": (
            "right (M.fitNaiveBayes M.GaussianBayes 1 xs labels)",
            lambda: m.fit_naive_bayes(m.gaussian_bayes(), 1, xs, labels),
        ),
        "Discriminant": (
            "right (M.fitDiscriminant False 0.1 xs labels)",
            lambda: m.fit_discriminant(False, 0.1, xs, labels),
        ),
        "IndexKind": ("M.KDTree", m.kd_tree),
        "SpatialIndex": (
            "right (M.buildIndex M.KDTree 2 xs)",
            lambda: m.build_index(m.kd_tree(), 2, xs),
        ),
        "NeighborResult": (
            "M.NeighborResult [(0,0.1),(1,0.2)] 2 True",
            lambda: m.neighbor_result([(0, 0.1), (1, 0.2)], 2, True),
        ),
        "LSH": ("right (M.buildLSH 42 2 2 1 xs)", lambda: m.build_lsh(42, 2, 2, 1, xs)),
        "IsolationForest": (
            "right (M.fitIsolationForest 42 3 4 xs)",
            lambda: m.fit_isolation_forest(42, 3, 4, xs),
        ),
        "OneClassSVM": (
            "M.fitted (right (M.fitOneClassSVM cfg (M.RBFKernel 0.5) 0.5 xs))",
            lambda: m.fitted(m.fit_one_class_svm(cfg, m.rbf_kernel(0.5), 0.5, xs)),
        ),
        "PCA": ("right (M.fitPCA 1 xs)", lambda: m.fit_pca(1, xs)),
        "IncrementalPCA": (
            "right (M.incrementalPCA 2 >>= (`M.updatePCA` xs))",
            lambda: m.update_pca(m.incremental_pca(2), xs),
        ),
        "KernelPCA": (
            "right (M.fitKernelPCA 1 (M.RBFKernel 0.5) xs)",
            lambda: m.fit_kernel_pca(1, m.rbf_kernel(0.5), xs),
        ),
        "ICA": (
            "M.fitted (right (M.fitICA cfg 1 xs))",
            lambda: m.fitted(m.fit_ica(cfg, 1, xs)),
        ),
        "FactorAnalysis": (
            "M.fitted (right (M.fitFactorAnalysis cfg 1 0.1 xs))",
            lambda: m.fitted(m.fit_factor_analysis(cfg, 1, 0.1, xs)),
        ),
        "CCA": ("right (M.fitCCA 1 0.1 xs zs)", lambda: m.fit_cca(1, 0.1, xs, zs)),
        "PLS": (
            "M.fitted (right (M.fitPLS cfg 1 xs zs))",
            lambda: m.fitted(m.fit_pls(cfg, 1, xs, zs)),
        ),
        "Scaling": ("M.Standardize", m.standardize),
        "Scaler": (
            "right (M.fitScaler M.Standardize xs)",
            lambda: m.fit_scaler(m.standardize(), xs),
        ),
        "QuantileTransformer": (
            "right (M.fitQuantileTransformer xs)",
            lambda: m.fit_quantile_transformer(xs),
        ),
        "PowerTransform": ("M.YeoJohnson 0.5", lambda: m.yeo_johnson(0.5)),
        "Imputation": ("M.MeanImpute", m.mean_impute),
        "Imputer": (
            "right (M.fitImputer M.MeanImpute xs)",
            lambda: m.fit_imputer(m.mean_impute(), xs),
        ),
        "UnknownCategory": ("M.RejectUnknown", m.reject_unknown),
        "Fold": ("foldA", lambda: m.fold([0, 1, 2], [3, 4, 5])),
        "ClusterModel": (
            "M.fitted (right (M.kMeans cfg 2 xs))",
            lambda: m.fitted(m.k_means(cfg, 2, xs)),
        ),
        "GaussianMixture": (
            "M.fitted (right (M.fitGaussianMixture cfg 2 0.1 xs))",
            lambda: m.fitted(m.fit_gaussian_mixture(cfg, 2, 0.1, xs)),
        ),
        "Linkage": ("M.Average", m.average),
        "Merge": ("M.Merge 0 1 0.5 2", lambda: m.merge(0, 1, 0.5, 2)),
    }
    encoder = own(m.fit_encoder([1, 10**100 + 1, 1]))
    generic_fit = own(m.fit(xs, 3, 0.25, False))
    hierarchy = m.hierarchical(m.average(), xs)
    owners.extend(hierarchy)
    for name, (expression, call) in recipe.items():
        variable = "value" + name
        lines.append(variable + "=" + expression)
        cache[name] = own(call())
    cache["Encoder Value"] = encoder

    def encoder_kind(kind):
        kind = kind.strip()
        if kind == "a":
            return "Dataset"
        if kind == "p":
            return "Integer"
        if kind.startswith("Fit "):
            return "Fit " + encoder_kind(kind[4:])
        if kind == "Encoder a":
            return "Encoder Integer"
        if kind.startswith("["):
            return "[" + encoder_kind(kind[1:-1]) + "]"
        if kind.startswith("("):
            return (
                "("
                + ",".join(encoder_kind(t) for t in split_top(kind[1:-1], ","))
                + ")"
            )
        return kind

    def hse(kind):
        kind = kind.strip()
        if kind == "Dataset":
            return "(list (list fp))"
        if kind.startswith("Fit "):
            return "(fit " + hse(kind[4:].strip("()")) + ")"
        if kind.startswith("Encoder "):
            return "encoderWire"
        if kind in types:
            return "show"
        if kind == "Double":
            return "fp"
        if kind in ("Int", "Word64", "Integer", "Bool"):
            return "(show :: " + kind + " -> String)"
        if kind.startswith("Maybe "):
            return '(maybe "Nothing" (\\x -> "Just("++' + hse(kind[6:]) + ' x++")"))'
        if kind.startswith("["):
            return "(list " + hse(kind[1:-1]) + ")"
        if kind.startswith("("):
            fields = split_top(kind[1:-1], ",")
            if len(fields) == 1:
                return hse(fields[0])
            vs = ["v" + str(k) for k in range(len(fields))]
            return (
                "(\\("
                + ",".join(vs)
                + ') -> "("++intercalate ";" ['
                + ",".join(hse(t) + " " + v for t, v in zip(fields, vs))
                + ']++")")'
            )
        raise AssertionError(kind)

    def encode(kind, value):
        kind = kind.strip()
        if kind == "Dataset":
            return encode("[[Double]]", value)
        if kind.startswith("Fit "):
            payload = m.fitted(value)
            try:
                return (
                    "F("
                    + encode(kind[4:].strip("()"), payload)
                    + ";"
                    + str(m.fit_iterations(value))
                    + ";"
                    + fp(m.fit_residual(value))
                    + ";"
                    + str(m.fit_converged(value))
                    + ")"
                )
            finally:
                if isinstance(payload, Value):
                    payload.close()
        if kind.startswith("Encoder "):
            return encode("[Integer]", m.label_decode(value, [0, 1]))
        if kind in types:
            return m.describe(value)
        if kind == "Double":
            return fp(value)
        if kind in ("Int", "Word64", "Integer", "Bool"):
            return str(value)
        if kind.startswith("Maybe "):
            return (
                "Nothing" if value is None else "Just(" + encode(kind[6:], value) + ")"
            )
        if kind.startswith("["):
            return "[" + ",".join(encode(kind[1:-1], x) for x in value) + "]"
        if kind.startswith("("):
            fields = split_top(kind[1:-1], ",")
            return (
                encode(fields[0], value)
                if len(fields) == 1
                else "(" + ";".join(encode(t, x) for t, x in zip(fields, value)) + ")"
            )
        raise AssertionError(kind)

    def fixture(entry, typ, k, bad):
        name = entry["name"]
        raw = split_top(entry["signature"].split("=>")[-1].strip(), "->")[:-1]
        if typ == "MLConfig":
            return (badcfg, "badcfg") if bad else (cfg, "cfg")
        if typ == "Fit a":
            return generic_fit, "genericFit"
        if typ == "Encoder a":
            return encoder, "encoder"
        if typ in recipe:
            return cache[typ], "value" + typ
        if typ == "Dataset":
            if bad:
                return [], "[]"
            if name == "inversePCA":
                return [[0.1], [0.2]], "[[0.1],[0.2]]"
            return (zs, "zs") if k > 0 and raw[k - 1] == "Dataset" else (xs, "xs")
        if typ == "Word64":
            return 42, "42"
        if typ == "Int":
            if bad:
                return -1, "(-1)"
            if name == "recursiveLS" or name == "buildLSH":
                value = 2
            elif name == "fitIsolationForest":
                value = 3 if k == 1 else 4
            elif name == "nearestNeighbors":
                value = 2 if k == 0 else 20
            elif name in (
                "knnRegress",
                "knnClassify",
                "queryLSH",
                "localOutlierFactor",
            ):
                value = 2
            elif name == "trainTestSplit":
                value = 6
            elif name == "kFold":
                value = 2 if k == 1 else 6
            elif name == "stratifiedKFold":
                value = 2
            elif name == "cutHierarchy":
                value = 2 if k == 0 else 6
            elif name == "dbscan" or name == "optics":
                value = 2
            elif name in ("isomap", "umap"):
                value = 2 if k == 1 else 1
            else:
                value = 1
            return value, str(value)
        if typ == "Double":
            if bad:
                return math.inf, "(1/0)"
            value = 0.25
            if name in ("recursiveLS",):
                value = 0.99 if k == 1 else 1
            elif name == "fitBayesian":
                value = 1
            elif name in (
                "fitSVM",
                "fitGaussianProcess",
                "fitDiscriminant",
                "fitCCA",
                "fitFactorAnalysis",
            ):
                value = 0.1 if name != "fitSVM" else 1
            elif name == "fitOneClassSVM":
                value = 0.5
            elif name in ("fitNaiveBayes", "kernel", "queryLSH", "fitGaussianMixture"):
                value = 0.1 if name == "fitGaussianMixture" else 1
            elif name in ("fitGLM", "fitMultinomial", "fitRobust"):
                value = 0.1
            elif name == "trainTestSplit":
                value = 0.33
            elif name == "tsne":
                value = 2
            elif name == "umap":
                value = 0.1 if k == 3 else 1
            elif name == "affinityPropagation":
                value = 0.5 if k == 1 else -1
            elif name in (
                "spectralClustering",
                "meanShift",
                "dbscan",
                "optics",
                "extractOPTICS",
            ):
                value = 1
            return value, "(" + str(value) + ")"
        if typ == "Bool":
            return not bad, "False" if bad else "True"
        if typ == "a":
            return xs, "xs"
        if typ == "[Double]":
            if bad:
                return [], "[]"
            if name in ("kernel", "updateRecursiveLS", "nearestNeighbors", "queryLSH"):
                return [0.25, 0.3], "[0.25,0.3]"
            if name in ("fitGLM", "fitGPClassifier"):
                return binary, "binary"
            if name == "fitSVM":
                return signed, "signed"
            if name == "fitWeighted" and k == 2:
                return [1.0] * 6, "replicate 6 1"
            return ys, "ys"
        if typ == "[Int]":
            return ([], "[]") if bad else (labels, "labels")
        if typ == "[a]":
            if bad:
                return ([], "[]") if name == "fitEncoder" else ([2], "[2::Integer]")
            if name == "stratifiedKFold":
                return labels, "map toInteger labels"
            return [1, 10**100 + 1, 1], "[1,10^100+1,1::Integer]"
        if typ == "[p]":
            return ([], "[]") if bad else ([1, 2, 3], "[1,2,3::Integer]")
        if typ == "[Fold]":
            return ([], "[]") if bad else ([cache["Fold"]], "[foldA]")
        if typ == "[Merge]":
            return hierarchy, "hierarchy"
        if typ == "[(Int, Double)]":
            return [(0, 0.1), (1, 0.2)], "[(0,0.1),(1,0.2)]"
        if typ == "[(Int, Maybe Double, Maybe Double)]":
            return [
                (0, None, None),
                (1, 1.0, 1.0),
            ], "[(0,Nothing,Nothing),(1,Just 1,Just 1)]"
        if "->" in typ:
            return (
                (lambda _p, _f: math.nan, "(\\_ _ -> Right (0/0))")
                if bad
                else (
                    lambda p, f: p + len(m.validation_indices(f)),
                    "(\\p f -> Right (fromInteger p+fromIntegral (length (M.validationIndices f))))",
                )
            )
        raise AssertionError((name, typ))

    lines += [
        'fit e x="F("++e (M.fitted x)++";"++show (M.fitIterations x)++";"++fp (M.fitResidual x)++";"++show (M.fitConverged x)++")"',
        "encoderWire :: M.Encoder Integer -> String",
        "encoderWire x=list show (right (M.labelDecode x [0,1]))",
        "main=do",
    ]
    cases = []
    for entry in data["functions"]:
        pieces = split_top(entry["signature"].split("=>")[-1].strip(), "->")
        arguments = pieces[:-1]
        result = pieces[-1]
        checked = result.startswith("Either MathError ")
        result = result.removeprefix("Either MathError ")
        for bad in (False, True):
            values = [fixture(entry, t, k, bad) for k, t in enumerate(arguments)]
            call = "M." + entry["name"] + "".join(" (" + hs + ")" for _, hs in values)
            if not checked:
                call = "Right (" + call + ")"
            kind = encoder_kind(result)
            if entry["name"] == "labelDecode":
                kind = "[Integer]"
            lines.append("  emit " + hse(kind) + " (" + call + ")")
            cases.append((entry, kind, [value for value, _ in values], bad))
    ad_labels = [
        own(ad.Dual(1, 2, dtype="integer")),
        own(ad.Dual(1, 1, dtype="integer")),
        own(ad.Dual(0, 9, dtype="integer")),
    ]
    provider_labels = [
        own(backend.pure()),
        own(backend.blis()),
        own(backend.open_blas()),
    ]
    edge_labels = [own(graph.edge(2, 0, 1, 0.5)), own(graph.edge(1, 0, 1, 0.5))]
    expr_labels = [
        own(expr_module.variable("x")),
        own(expr_module.parse_expression(expr_module.default_limits(), " x ")),
        own(expr_module.variable("y")),
    ]
    extras = [
        (
            "AD original Ord",
            "let xs=[A.Dual 1 2,A.Dual 1 1,A.Dual 0 9::A.Dual Integer] in M.fitEncoder xs >>= \\enc -> M.labelEncode enc xs",
            ad_labels,
        ),
        (
            "Backend original Ord",
            "let xs=[B.Pure,B.BLIS,B.OpenBLAS] in M.fitEncoder xs >>= \\enc -> M.labelEncode enc xs",
            provider_labels,
        ),
        (
            "Graph Edge original Ord",
            "let xs=[G.Edge 2 0 1 0.5,G.Edge 1 0 1 0.5] in M.fitEncoder xs >>= \\enc -> M.labelEncode enc xs",
            edge_labels,
        ),
        (
            "Expr position-insensitive Eq",
            'let xs=[E.variable "x",right (E.parseExpression E.defaultLimits " x "),E.variable "y"] in M.fitEncoder xs >>= \\enc -> M.labelEncode enc xs',
            expr_labels,
        ),
    ]
    for _, call, _ in extras:
        lines.append("  emit (list show) (" + call + ")")
    with tempfile.TemporaryDirectory(prefix="hmath-ml-oracle-") as directory:
        path = Path(directory)
        source = path / "Main.hs"
        source.write_text("\n".join(lines) + "\n")
        subprocess.run(
            [
                "ghc",
                "-O0",
                "-isrc",
                "-Iinclude",
                "-optc-std=c11",
                "-outputdir",
                directory,
                "-stubdir",
                directory,
                str(source),
                "cbits/backend.c",
                "-o",
                str(path / "oracle"),
            ],
            cwd=ROOT,
            check=True,
            stdout=subprocess.DEVNULL,
        )
        expected = subprocess.check_output(
            [str(path / "oracle")], text=True
        ).splitlines()
    assert len(expected) == len(cases) + len(extras)

    def close(value):
        if isinstance(value, Value) or hasattr(value, "close"):
            value.close()
        elif isinstance(value, (list, tuple)):
            for child in value:
                close(child)

    for k, (entry, kind, values, bad) in enumerate(cases):
        result = None
        try:
            result = getattr(m, snake(entry["name"]))(*values)
            actual = "OK:" + encode(kind, result)
        except hmath.HMathError as error:
            assert error.math_error is not None, (entry["name"], error)
            actual = "ERR:" + str(error.math_error)
        finally:
            close(result)
        assert actual == expected[k], (entry["name"], bad, actual, expected[k])
    for k, (label, _, labels_input) in enumerate(extras, len(cases)):
        with m.fit_encoder(labels_input) as encoded:
            actual = "OK:" + encode("[Int]", m.label_encode(encoded, labels_input))
            assert actual == expected[k], (label, actual, expected[k])
    # Exact/generic categorical dictionaries and independent retained owners.
    for labels_in in [
        [10**200, 1, 10**200],
        [Fraction(1, 3), Fraction(1, 7), Fraction(1, 3)],
        ["λ\0", "a\ud800", "λ\0"],
        [True, False, True],
        [(2, "a"), (1, "b"), (2, "a")],
        [[2, 1], [1, 2], [2, 1]],
    ]:
        with m.fit_encoder(labels_in) as enc:
            codes = m.label_encode(enc, labels_in)
            assert m.label_decode(enc, codes) == labels_in
    with (
        numeric.number(1, "float32") as scalar,
        m.fit_encoder([scalar, numeric.number(2, "float32")]) as enc,
    ):
        assert m.label_decode(enc, [0, 1]) == [1.0, 2.0]
    with m.fit_encoder([[], []], prototype=[0]) as enc:
        assert m.label_encode(enc, [[]]) == [0]
    with m.fit_encoder([None, None], prototype=0) as enc:
        assert m.label_decode(enc, [0]) == [None]

    def failure(_p, _f):
        raise LookupError("ML callback failed")

    try:
        m.grid_search([1], [cache["Fold"]], failure)
        raise AssertionError("callback error swallowed")
    except LookupError as error:
        assert str(error) == "ML callback failed"

    def domain(_p, _f):
        raise MathError(MathErrorKind.DOMAIN_ERROR, message="validation failed")

    try:
        m.grid_search([1], [cache["Fold"]], domain)
        raise AssertionError("MathError swallowed")
    except hmath.HMathError as error:
        assert (
            error.math_error.kind == MathErrorKind.DOMAIN_ERROR
            and error.math_error.message == "validation failed"
        )
    record = m.fit(cache["LinearModel"], 3, 0.25, False)
    child = m.fitted(record)
    record.close()
    assert m.predict_linear(child, xs) == m.predict_linear(cache["LinearModel"], xs)
    child.close()
    for owner in owners:
        owner.close()
    print(
        f"MachineLearning: {len(expected)} direct Haskell cases plus exact labels, prototypes, checked callbacks and model ownership passed."
    )


if __name__ == "__main__":
    main()
