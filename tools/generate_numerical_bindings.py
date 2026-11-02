# SPDX-License-Identifier: MPL-2.0
"""Generate typed adapters for original calculus, root, ODE and PDE operations."""

import argparse
import json
import re
from pathlib import Path

from generate_graph_bindings import argument_names, snake, source_prose, split_top

ROOT = Path(__file__).resolve().parent.parent
# source module, original type, kind, public record selectors
TYPES = {
    "EstimateValue": ("calculus", "C.Estimate V.Value", 200, []),
    "Tolerance": (
        "calculus",
        "C.Tolerance",
        201,
        ["absoluteTolerance", "relativeTolerance", "maximumEvaluations"],
    ),
    "Difference": ("calculus", "C.Difference", 202, []),
    "Quadrature": ("calculus", "C.Quadrature", 203, []),
    "RootOptions": (
        "root",
        "R.RootOptions",
        204,
        [
            "rootMaxIterations",
            "rootMaxEvaluations",
            "rootTolerance",
            "rootStepTolerance",
        ],
    ),
    "RootResult": (
        "root",
        "R.RootResult",
        205,
        [
            "rootValue",
            "rootResidual",
            "rootErrorBound",
            "rootIterations",
            "rootEvaluations",
        ],
    ),
    "Bracket": ("root", "R.Bracket", 206, []),
    "BracketMethod": ("root", "R.BracketMethod", 207, []),
    "DerivativeMethod": ("root", "R.DerivativeMethod", 208, []),
    "FixedPointMethod": ("root", "R.FixedPointMethod", 209, []),
    "SystemMethod": ("root", "R.SystemMethod", 210, []),
    "SystemRootResult": (
        "root",
        "R.SystemRootResult",
        211,
        ["systemRoot", "systemResidual", "systemIterations", "systemEvaluations"],
    ),
    "ODEMethod": ("ode", "O.Method", 212, []),
    "ODEOptions": (
        "ode",
        "O.ODEOptions",
        213,
        [
            "odeAbsoluteTolerance",
            "odeRelativeTolerance",
            "initialStep",
            "minimumStep",
            "maximumStep",
            "maximumSteps",
            "newtonIterations",
        ],
    ),
    "Trajectory": (
        "ode",
        "O.Trajectory",
        214,
        ["trajectoryTimes", "trajectoryStates", "trajectoryDerivatives"],
    ),
    "EventDirection": ("ode", "O.EventDirection", 215, []),
    "Event": ("ode", "O.Event", 216, ["eventTime", "eventState"]),
    "HamiltonianMethod": ("ode", "O.HamiltonianMethod", 217, []),
    "Grid": ("pde", "P.Grid", 218, ["gridShape", "gridSpacing"]),
    "Boundary": ("pde", "P.Boundary", 219, []),
    "Discretization": ("pde", "P.Discretization", 220, []),
    "PDEOperator": (
        "pde",
        "P.PDEOperator",
        221,
        ["pdeStiffness", "pdeMass", "pdeBoundaryLoad"],
    ),
    "PDEResult": (
        "pde",
        "P.PDEResult",
        222,
        ["pdeValues", "pdeResidual", "pdeErrorEstimate"],
    ),
}
MODULES = {"calculus": "C", "root": "R", "ode": "O", "pde": "P"}


def normalize(text, namespace):
    text = text.replace("C.Estimate", "Estimate").replace("C.Tolerance", "Tolerance")
    text = text.replace("P.Polynomial (Complex Double)", "ComplexPolynomial")
    text = text.replace("P.Polynomial Rational", "RationalPolynomial")
    text = text.replace("Matrix Double", "MatrixDouble").replace(
        "S.Sparse Double", "SparseDouble"
    )
    text = text.replace("Complex Double", "ComplexDouble")
    text = text.replace("Estimate a", "EstimateValue").replace(
        "Estimate Double", "EstimateDouble"
    )
    text = text.replace("O.Method", "ODEMethod").replace("O.Trajectory", "Trajectory")
    text = re.sub(r"\bMethod\b", "ODEMethod", text) if namespace == "ode" else text
    text = re.sub(r"\bODE\b", "(Double -> [Double] -> [Double])", text)
    return re.sub(r"\ba\b", "Value", text)


def spec(text, known=None):
    known = TYPES if known is None else known
    text = text.strip()
    arrows = split_top(text, "->")
    if len(arrows) > 1:
        parts = [spec(arrow, known) for arrow in arrows]
        if parts[-1][0] == "function":
            parts = parts[:-1] + parts[-1][1:]
        return ["function", *parts]
    if text.startswith("Either MathError "):
        return ["either", spec(text[17:], known)]
    if text.startswith("Maybe "):
        inner = spec(text[6:], known)
        if inner[0] == "maybe":
            raise ValueError("nested Maybe requires a tagged representation")
        return ["maybe", inner]
    if text.startswith("[") and text.endswith("]"):
        return ["list", spec(text[1:-1], known)]
    if text.startswith("(") and text.endswith(")"):
        fields = split_top(text[1:-1], ",")
        if len(fields) > 1:
            return ["tuple", *[spec(field, known) for field in fields]]
        if not fields[0]:
            return ["unit"]
        return spec(text[1:-1], known)
    if text in {
        *known,
        "EstimateDouble",
        "Tolerance",
        "GaussianState",
        "Value",
        "Double",
        "Int",
        "Integer",
        "Rational",
        "ComplexDouble",
        "Bool",
        "String",
        "MatrixDouble",
        "SparseDouble",
        "ComplexPolynomial",
        "RationalPolynomial",
    }:
        return [text]
    raise ValueError("unsupported numerical representation: " + text)


def generate(entries=None, aliases=True):
    if entries is None:
        entries = json.loads(
            (ROOT / "bindings/schema/numerical-functions.json").read_text()
        )["functions"]
    header = [
        '/* SPDX-License-Identifier: MPL-2.0 */\n/* Generated by tools/generate_numerical_bindings.py. */\n#ifndef HMATH_NUMERICAL_H\n#define HMATH_NUMERICAL_H\n#include "hmath_linear.h"\n#ifdef __cplusplus\nextern "C" {\n#endif\n',
        "/* Original checked numerical solvers and diagnostics. All arguments are\n * borrowed Value handles; success transfers one output reference. Outputs\n * remain untouched on failure. Function arguments use kind101 callbacks from\n * hmath_linear_callback, with a tuple of positional arguments. Keep callback\n * function/userdata valid while any object retaining it remains alive.\n * Source formulas, defaults, finite checks, limits and error variants are\n * preserved. Source Left MathError returns status11. Inputs/outputs may share\n * immutable handles; output addresses must be distinct from input storage.\n * Independent readers keep references alive, contexts remain per-call. */\n",
    ]
    c = [
        '/* SPDX-License-Identifier: MPL-2.0 */\n/* Generated; do not edit. */\n#include "hmath_numerical.h"\n#include "value_internal.h"\nextern int hm_numerical_apply(int,void *const *,size_t,void **);\n'
    ]
    hs = [
        "{-# LANGUAGE ForeignFunctionInterface #-}\n{-# LANGUAGE FlexibleInstances #-}\n{-# OPTIONS_GHC -Wno-orphans #-}\n-- SPDX-License-Identifier: MPL-2.0\n-- Generated representation adapters; numerical functions are the originals.\nmodule HMath.FFI.NumericalAll where\nimport Foreign\nimport Foreign.C\nimport qualified HMath.FFI.Boundary as B\nimport HMath.FFI.NumericalCodec\nimport qualified HMath.FFI.Value as V\nimport qualified HMath.Calculus as C\nimport qualified HMath.Root as R\nimport qualified HMath.ODE as O\nimport qualified HMath.PDE as P\n"
    ]
    py = {
        namespace: [
            "# SPDX-License-Identifier: MPL-2.0\n# Generated by tools/generate_numerical_bindings.py.\nfrom ._numerical_base import _invoke\nfrom ._value import Value, register\n"
        ]
        for namespace in MODULES
    }
    mappings = []
    source_names = {e["module"] + "." + e["name"] for e in entries}
    for name, (namespace, typ, tag, fields) in TYPES.items():
        public = (
            "Estimate"
            if name == "EstimateValue"
            else "Method"
            if name == "ODEMethod"
            else name
        )
        module = (
            "HMath." + namespace.capitalize()
            if namespace not in ("ode", "pde")
            else "HMath." + namespace.upper()
        )
        py[namespace].append(
            f'\n\nclass {public}(Value):\n    """Owned immutable original {module}.{public}."""\n\n\nregister({tag}, {public})\n'
        )
        symbol = "hmath_" + namespace + "_" + snake(public) + "_object"
        header.append(f"typedef hmath_value {symbol}; /* kind{tag} */\n")
        if name != "EstimateValue":
            qualifier = MODULES[namespace]
            hs.append(
                f"instance From {typ} where from = unbox {tag}\ninstance To {typ} where\n    to value = pure (box {tag} value ["
                + ",".join(f"to ({qualifier}.{field} value)" for field in fields)
                + "])\n"
            )
        if module + "." + public not in source_names:
            mappings.append(
                {
                    "symbol": module + "." + public,
                    "c": [symbol],
                    "python": "hmath." + namespace + "." + public,
                    "specializations": ["original concrete type"],
                }
            )
    # The type alias is represented by an ordinary curried-function callback.
    if aliases:
        py["ode"].append(
            "\n\nfrom typing import Callable as _Callable\nODE = _Callable[[float, list[float]], list[float]]\n"
        )
        mappings.append(
            {
                "symbol": "HMath.ODE.ODE",
                "c": ["hmath_linear_callback_fn"],
                "python": "hmath.ode.ODE",
                "specializations": [
                    "Double -> [Double] -> [Double], flat positional callback"
                ],
            }
        )
    hs.append(
        'foreign export ccall "hm_numerical_apply" dispatch :: CInt -> Ptr (StablePtr V.Value) -> CSize -> Ptr (StablePtr V.Value) -> IO CInt\ndispatch :: CInt -> Ptr (StablePtr V.Value) -> CSize -> Ptr (StablePtr V.Value) -> IO CInt\ndispatch operation input arity out = B.boundary $ do\n    values <- peekArray (fromIntegral arity) input >>= mapM deRefStablePtr\n    result <- case operation of\n'
    )
    docs = [
        "# Numerical solvers\n\nPython exposes `hmath.calculus`, `hmath.root`, `hmath.ode` and `hmath.pde`. C includes `hmath_numerical.h`. Every named operation invokes the original Haskell function with its original argument order, defaults, budgets, diagnostic fields, finite checks and errors.\n\n",
        "Inputs are borrowed, successful outputs own a [structured value](values.md), and failure leaves output pointers untouched. Immutable handles can be shared by concurrent readers retaining their own references. Source `Left MathError` returns status11 with its full structured payload. Cancellation is checked before entry; source evaluation/step limits govern the solver.\n\n",
        "Function arguments are kind101 objects constructed with `hmath_linear_callback`. Their input is a tuple of the source's curried arguments flattened into positional order; their output transfers one owned value. Callbacks may reenter checked APIs and must not unwind through C. Python accepts normal callables and re-raises their original exceptions after cleanup. An actual source `Either MathError` callback may return a recoverable mathematical error; pure callbacks propagate it to the outer boundary. Callback function/userdata must remain valid for all objects retaining them. Python propagates these owners automatically.\n\n",
        "`Estimate` retains an arbitrary structured payload; its value is never implicitly converted to binary64. Numerical estimates produced by these solvers have their original binary64 payload. `Matrix Double`, sparse operators and exact polynomial inputs interoperate with their existing typed binding owners.\n\n",
    ]
    for operation, entry in enumerate(entries):
        namespace = entry["module"].removeprefix("HMath.").lower()
        normalized = normalize(entry["signature"], namespace)
        parts = split_top(normalized, "->")
        arguments = parts[:-1]
        specifications = [spec(t) for t in arguments]
        spec(parts[-1])
        names = argument_names(entry, len(arguments))
        record = next(
            (
                fields
                for key, (ns, _, _, fields) in TYPES.items()
                if ns == namespace
                and ("Estimate" if key == "EstimateValue" else key) == entry["name"]
            ),
            [],
        )
        if record and len(record) == len(arguments):
            names = [snake(field) for field in record]
        if namespace == "calculus" and entry["name"] == "Estimate":
            names = ["value", "error", "evaluations"]
        name = snake(entry["name"])
        source = entry["module"] + "." + entry["name"]
        symbol = "hmath_" + namespace + "_" + name
        prototype = (
            "hmath_status "
            + symbol
            + "("
            + ", ".join(
                [
                    "hmath_context *context",
                    *["const hmath_value *" + n for n in names],
                    "hmath_value **out",
                ]
            )
            + ")"
        )
        header.append(
            f"/* {source} :: {entry['signature']} */\nHMATH_API {prototype};\n"
        )
        c.append(
            prototype
            + " {\n    if (!out"
            + "".join(" || !" + n for n in names)
            + ') return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");\n    hmath_value *temporary=NULL;\n    hmath_status status=hm_value_begin(context,&temporary);\n    if (status) return status;\n    void *arguments[]={'
            + (", ".join("hm_value_stable(" + n + ")" for n in names) or "NULL")
            + f"}};\n    int code=hm_numerical_apply({operation},arguments,{len(names)},&temporary->stable);\n    return hm_value_finish(temporary,code,out);\n}}\n"
        )
        call = MODULES[namespace] + "." + entry["name"]
        if namespace == "calculus" and entry["name"] in (
            "Estimate",
            "estimateValue",
            "estimateError",
            "evaluations",
        ):
            signature = {
                "Estimate": "V.Value -> Double -> Int -> C.Estimate V.Value",
                "estimateValue": "C.Estimate V.Value -> V.Value",
                "estimateError": "C.Estimate V.Value -> Double",
                "evaluations": "C.Estimate V.Value -> Int",
            }[entry["name"]]
            call = "(" + call + " :: " + signature + ")"
        hs.append(f"        {operation} -> apply {call} values\n")
        py[namespace].append(
            f'\n\ndef {name}({", ".join(names)}):\n    """{source} :: {entry["signature"]}."""\n    return _invoke({symbol!r}, {specifications!r}, [{", ".join(names)}])\n'
        )
        mappings.append(
            {
                "symbol": source,
                "c": [symbol],
                "python": "hmath." + namespace + "." + name,
                "specializations": [
                    "original binary64/exact/structured source types; Estimate payload remains generic"
                ],
            }
        )
        docs.append(
            f"## `{namespace}.{name}`\n\n`{namespace}.{name}({', '.join(names)})`\n\n{source_prose(entry)}\n\nOriginal: [`{source}`](haskell/{entry['module'].replace('.', '-')}.md#v:{entry['name']}).\n\n```haskell\n{entry['signature']}\n```\n\n```c\n{prototype};\n```\n\n"
        )
    hs.append(
        '        _ -> V.invalid "unknown numerical operation"\n    V.forceValue result\n    B.checked (Right ()) (\\_ -> V.publish result out)\n'
    )
    header.append("#ifdef __cplusplus\n}\n#endif\n#endif\n")
    return {
        "include/hmath_numerical.h": "".join(header),
        "cbits/numerical.c": "".join(c),
        "src/HMath/FFI/NumericalAll.hs": "".join(hs),
        **{
            "bindings/python/_hmath_native/" + n + ".py": "".join(lines)
            for n, lines in py.items()
        },
        "bindings/schema/numerical-objects.json": json.dumps(
            {"schema": 1, "bindings": mappings}, indent=2
        )
        + "\n",
        "docs/reference/numerical-solvers.md": "".join(docs),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    for name, content in generate().items():
        path = ROOT / name
        if args.check:
            if not path.exists() or path.read_text() != content:
                parser.exit(1, "Stale numerical binding: " + name + "\n")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)


if __name__ == "__main__":
    main()
