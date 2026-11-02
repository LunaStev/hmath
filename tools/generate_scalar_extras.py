# SPDX-License-Identifier: MPL-2.0
"""Complete the remaining Complex, Trigonometry, exact NT and SFResult APIs."""

import argparse
import json
import re
from pathlib import Path

from generate_graph_bindings import snake, source_prose

ROOT = Path(__file__).resolve().parent.parent
ELEMENTARY = [
    "Exp",
    "Log",
    "Sqrt",
    "Sin",
    "Cos",
    "Tan",
    "Sinh",
    "Cosh",
    "Tanh",
    "Asin",
    "Acos",
    "Atan",
    "Asinh",
    "Acosh",
    "Atanh",
]
COMPLEX_FUNCTION = [
    "CSin",
    "CCos",
    "CTan",
    "CAsin",
    "CAcos",
    "CAtan",
    "CSinh",
    "CCosh",
    "CTanh",
    "CAsinh",
    "CAcosh",
    "CAtanh",
    "CSec",
    "CCsc",
    "CCot",
    "CSech",
    "CCsch",
    "CCoth",
]
SPECS = []


def add(namespace, module, name, args, result, expression, signature, checked=True):
    SPECS.append(
        {
            "namespace": namespace,
            "module": module,
            "name": name,
            "args": args,
            "result": result,
            "expression": expression,
            "signature": signature,
            "checked": checked,
        }
    )


for name in ELEMENTARY:
    add(
        "complex",
        "HMath.Complex",
        name,
        [],
        "Elementary",
        "pure (elementary C." + name + ")",
        "Elementary",
        False,
    )
for name in COMPLEX_FUNCTION:
    add(
        "trigonometry",
        "HMath.Trigonometry",
        name,
        [],
        "ComplexFunction",
        "pure (complexFunction T." + name + ")",
        "ComplexFunction",
        False,
    )
add(
    "complex",
    "HMath.Complex",
    "elementary",
    [("operation", "Elementary"), ("value", "ComplexDouble")],
    "ComplexDouble",
    "source (C.elementary operation value) >>= pure . complexDoubleValue",
    "Elementary -> Complex Double -> Either MathError (Complex Double)",
)
add(
    "complex",
    "HMath.Complex",
    "complexMatrix",
    [("rows", "Int"), ("columns", "Int"), ("values", "[ComplexDouble]")],
    "ComplexMatrix",
    "source (C.complexMatrix rows columns values) >>= pure . matrix",
    "Int -> Int -> [Complex Double] -> Either MathError (Matrix (Complex Double))",
)
add(
    "complex",
    "HMath.Complex",
    "multiplyMatrices",
    [("a", "ComplexMatrix"), ("b", "ComplexMatrix")],
    "ComplexMatrix",
    "source (C.multiplyMatrices a b) >>= pure . matrix",
    "Matrix (Complex Double) -> Matrix (Complex Double) -> Either MathError (Matrix (Complex Double))",
)
add(
    "complex",
    "HMath.Complex",
    "conjugateTranspose",
    [("value", "ComplexMatrix")],
    "ComplexMatrix",
    "source (C.conjugateTranspose value) >>= pure . matrix",
    "Matrix (Complex Double) -> Either MathError (Matrix (Complex Double))",
)
for name in ["complexFFT", "complexIFFT"]:
    add(
        "complex",
        "HMath.Complex",
        name,
        [("values", "[ComplexDouble]")],
        "[ComplexDouble]",
        "source (C." + name + " values) >>= pure . V.List . map complexDoubleValue",
        "[Complex Double] -> Either MathError [Complex Double]",
    )
add(
    "trigonometry",
    "HMath.Trigonometry",
    "complexFunction",
    [("operation", "ComplexFunction"), ("value", "TypedComplex")],
    "TypedComplex",
    "trigonometric operation value",
    "RealFloat a => ComplexFunction -> Complex a -> Either MathError (Complex a)",
)
for name, args, result, signature in [
    (
        "chineseRemainder",
        [("congruences", "[(Integer,Integer)]")],
        "(Integer,Integer)",
        "[(Integer,Integer)] -> Either MathError (Integer,Integer)",
    ),
    (
        "linearDiophantine",
        [("a", "Integer"), ("b", "Integer"), ("c", "Integer")],
        "(Integer,Integer,Integer,Integer)",
        "Integer -> Integer -> Integer -> Either MathError (Integer,Integer,Integer,Integer)",
    ),
    (
        "perfectPower",
        [("value", "Integer")],
        "Maybe (Integer,Int)",
        "Integer -> Maybe (Integer,Int)",
    ),
    (
        "primeFactorization",
        [("budget", "Int"), ("value", "Integer")],
        "[(Integer,Int)]",
        "Int -> Integer -> Either MathError [(Integer,Int)]",
    ),
    ("partitions", [("value", "Int")], "[[Int]]", "Int -> Either MathError [[Int]]"),
]:
    add(
        "numbertheory",
        "HMath.NumberTheory",
        name,
        args,
        result,
        (
            "source (N." + name + "".join(" " + n for n, t in args) + ")"
            if name != "perfectPower"
            else "pure (N.perfectPower value)"
        )
        + " >>= pure . W.wire",
        signature,
        name != "perfectPower",
    )
add(
    "special",
    "HMath.Special",
    "SFResult",
    [("value", "Double"), ("error", "Double")],
    "SFResult",
    "pure (sfResult (S.SFResult value error))",
    "Double -> Double -> SFResult",
    False,
)
add(
    "special",
    "HMath.Special",
    "sfValue",
    [("value", "SFResult")],
    "Double",
    "pure (W.wire (S.sfValue value))",
    "SFResult -> Double",
    False,
)
add(
    "special",
    "HMath.Special",
    "sfError",
    [("value", "SFResult")],
    "Double",
    "pure (W.wire (S.sfError value))",
    "SFResult -> Double",
    False,
)

PREFIX = """{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE ScopedTypeVariables #-}
-- SPDX-License-Identifier: MPL-2.0
-- Generated by tools/generate_scalar_extras.py; all mathematics is original.
module HMath.FFI.ScalarExtras where
import Control.Exception (evaluate,throwIO)
import Data.Complex (Complex)
import Data.Typeable (cast)
import Foreign
import Foreign.C
import HMath.FFI.Boundary
import HMath.FFI.Coefficient (ScalarType(SComplexDouble,SComplexFloat))
import HMath.FFI.MathError (CallbackFailure(..))
import qualified HMath.FFI.Value as V
import qualified HMath.FFI.GraphCodec as W
import qualified HMath.Complex as C
import qualified HMath.Trigonometry as T
import qualified HMath.NumberTheory as N
import qualified HMath.Special as S
import qualified HMath.Matrix as M
source :: Either HMathError a -> IO a
source = either (throwIO . CallbackMathError) pure
""".replace("HMathError", "MathError")
PREFIX = PREFIX.replace(
    "import HMath.FFI.Boundary",
    "import HMath.Error (MathError)\nimport HMath.FFI.Boundary",
)
PREFIX += """elementary :: C.Elementary -> V.Value
elementary value = V.Opaque 352 (-1) 0 (evaluate value >> pure ()) value
complexFunction :: T.ComplexFunction -> V.Value
complexFunction value = V.Opaque 353 (-1) 0 (evaluate value >> pure ()) value
getElementary :: V.Value -> IO C.Elementary
getElementary = W.unboxed 352
getComplexFunction :: V.Value -> IO T.ComplexFunction
getComplexFunction = W.unboxed 353
complexDoubleValue :: Complex Double -> V.Value
complexDoubleValue = V.Scalar SComplexDouble
matrix :: M.Matrix (Complex Double) -> V.Value
matrix = V.Dense . V.SomeMatrix SComplexDouble
getMatrix :: V.Value -> IO (M.Matrix (Complex Double))
getMatrix (V.Dense (V.SomeMatrix _ value)) = maybe (V.invalid "Complex Double matrix required") pure (cast value)
getMatrix _ = V.invalid "dense complex matrix required"
sfResult :: S.SFResult -> V.Value
sfResult value = V.Tuple [W.wire (S.sfValue value),W.wire (S.sfError value)]
getSFResult :: V.Value -> IO S.SFResult
getSFResult value = do
    fields <- V.asTuple 2 value
    case fields of [a,b] -> S.SFResult <$> W.unwire a <*> W.unwire b;_ -> V.invalid "SFResult field count differs"
trigonometric :: T.ComplexFunction -> V.Value -> IO V.Value
trigonometric operation value = case value of
    V.Scalar SComplexDouble x -> source (T.complexFunction operation x) >>= pure . V.Scalar SComplexDouble
    V.Scalar SComplexFloat x -> source (T.complexFunction operation x) >>= pure . V.Scalar SComplexFloat
    _ -> V.invalid "complexFunction requires actual Complex Float or Complex Double"
"""


def generate():
    hs = [
        PREFIX,
        'foreign export ccall "hm_scalar_extras_apply" apply :: CInt -> Ptr (StablePtr V.Value) -> CSize -> Ptr (StablePtr V.Value) -> IO CInt\napply :: CInt -> Ptr (StablePtr V.Value) -> CSize -> Ptr (StablePtr V.Value) -> IO CInt\napply operation inputs arity out = boundary $ do\n    values <- peekArray (fromIntegral arity) inputs >>= mapM deRefStablePtr\n    result <- case (operation,values) of\n',
    ]
    h = [
        '/* SPDX-License-Identifier: MPL-2.0 */\n/* Generated by tools/generate_scalar_extras.py. */\n#ifndef HMATH_SCALAR_EXTRAS_H\n#define HMATH_SCALAR_EXTRAS_H\n#include "hmath_value.h"\n#ifdef __cplusplus\nextern "C" {\n#endif\n',
        "/* Borrowed immutable inputs; outputs transfer one Value owner on success and\n * remain untouched on failure. Release with hmath_value_release. Selector\n * objects use actual Elementary(kind352)/ComplexFunction(kind353) payloads.\n * Complex arithmetic/FFT/matrices and SFResult use original Double precision;\n * trigonometric complexFunction retains either actual Complex Float or Double\n * input/output, without intermediate widening. Exact integer transport never\n * uses floating point; nested tuple/list/Maybe results retain source shape.\n * Source bounds, budgets, principal branches, flags and MathError/status11 are\n * unchanged. Independent readers retain references per participating thread. */\n",
        "typedef hmath_value hmath_complex_elementary_object;\ntypedef hmath_value hmath_trigonometry_complex_function_object;\ntypedef hmath_value hmath_special_sf_result_value; /* tuple(Double,Double) */\n",
    ]
    c = [
        '/* SPDX-License-Identifier: MPL-2.0 */\n/* Generated by tools/generate_scalar_extras.py. */\n#include "hmath_scalar_extras.h"\n#include "value_internal.h"\nextern int hm_scalar_extras_apply(int,void *const *,size_t,void **);\n'
    ]
    mods = {}
    mapping = []
    symbols = []
    getters = {
        "Elementary": "getElementary",
        "ComplexFunction": "getComplexFunction",
        "ComplexDouble": "V.asScalar",
        "[ComplexDouble]": "(\\value -> V.asList value >>= mapM V.asScalar)",
        "ComplexMatrix": "getMatrix",
        "SFResult": "getSFResult",
        "TypedComplex": "pure",
    }
    for op, e in enumerate(SPECS):
        namespace = e["namespace"]
        name = snake(e["name"])
        public = "hmath_" + namespace + "_" + name
        params = [n for n, t in e["args"]]
        prototype = (
            "hmath_status "
            + public
            + "("
            + ", ".join(
                ["hmath_context *context"]
                + ["const hmath_value *" + n for n in params]
                + ["hmath_value **out"]
            )
            + ")"
        )
        h.append(
            "/* "
            + e["module"]
            + "."
            + e["name"]
            + " :: "
            + e["signature"]
            + " */\nHMATH_API "
            + prototype
            + ";\n"
        )
        c.append(
            prototype
            + " {\n    if(!out"
            + "".join(" || !" + n for n in params)
            + ')return hm_error(HMATH_INVALID_ARGUMENT,"NULL scalar adapter argument");\n    hmath_value *result=NULL;\n    hmath_status status=hm_value_begin(context,&result);\n    if(status)return status;\n    void *arguments[]={'
            + (",".join("hm_value_stable(" + n + ")" for n in params) or "NULL")
            + "};\n    return hm_value_finish(result,hm_scalar_extras_apply("
            + str(op)
            + ",arguments,"
            + str(len(params))
            + ",&result->stable),out);\n}\n"
        )
        hs.append(
            "        ("
            + str(op)
            + ",["
            + ",".join("v" + n for n in params)
            + "]) -> do\n"
        )
        expression = e["expression"]
        for n, t in e["args"]:
            getter = getters.get(t, "W.unwire")
            argument = "arg" + n[0].upper() + n[1:]
            hs.append("            " + argument + " <- " + getter + " v" + n + "\n")
            expression = re.sub(r"\b" + re.escape(n) + r"\b", argument, expression)
        hs.append("            " + expression + "\n")
        mods.setdefault(namespace, []).append(e)
        mapping.append(
            {
                "symbol": e["module"] + "." + e["name"],
                "c": [public],
                "python": "hmath."
                + namespace
                + "."
                + ("SFResult" if e["name"] == "SFResult" else name),
                "specializations": [
                    "actual Complex Float/Double RealFloat instances"
                    if e["name"] == "complexFunction"
                    else "original concrete source type/structure"
                ],
            }
        )
        symbols.append(public)
    hs.append(
        '        _ -> V.invalid "scalar adapter identifier or arity differs"\n    checked (Right result) (`V.publish` out)\n'
    )
    hs.append(
        'foreign export ccall "hm_scalar_selector_name" selectorName :: StablePtr V.Value -> Ptr (StablePtr V.Value) -> IO CInt\nselectorName :: StablePtr V.Value -> Ptr (StablePtr V.Value) -> IO CInt\nselectorName input out = boundary $ do\n    value <- deRefStablePtr input\n    name <- case V.valueInfo value of\n        (352,_,_) -> show <$> getElementary value\n        (353,_,_) -> show <$> getComplexFunction value\n        _ -> V.invalid "expected complex selector"\n    checked (Right (V.Text name)) (`V.publish` out)\nforeign export ccall "hm_scalar_selector_equal" selectorEqual :: StablePtr V.Value -> StablePtr V.Value -> Ptr (StablePtr V.Value) -> IO CInt\nselectorEqual :: StablePtr V.Value -> StablePtr V.Value -> Ptr (StablePtr V.Value) -> IO CInt\nselectorEqual left right out = boundary $ do\n    a <- deRefStablePtr left\n    b <- deRefStablePtr right\n    equal <- case (V.valueInfo a,V.valueInfo b) of\n        ((352,_,_),(352,_,_)) -> (==) <$> getElementary a <*> getElementary b\n        ((353,_,_),(353,_,_)) -> (==) <$> getComplexFunction a <*> getComplexFunction b\n        _ -> pure False\n    checked (Right (V.Boolean equal)) (`V.publish` out)\n'
    )
    for helper, arity in [("name", 1), ("equal", 2)]:
        prototype = (
            "hmath_status hmath_scalar_selector_"
            + helper
            + "(hmath_context *context"
            + "".join(",const hmath_value *value" + str(k) for k in range(arity))
            + ",hmath_value **out)"
        )
        h.append("HMATH_API " + prototype + ";\n")
        c.append(
            "extern int hm_scalar_selector_"
            + helper
            + "("
            + ",".join(["void *"] * arity + ["void **"])
            + ");\n"
            + prototype
            + " {\n    if(!out"
            + "".join(" || !value" + str(k) for k in range(arity))
            + ')return hm_error(HMATH_INVALID_ARGUMENT,"NULL selector argument");\n    hmath_value *result=NULL;\n    hmath_status status=hm_value_begin(context,&result);\n    if(status)return status;\n    return hm_value_finish(result,hm_scalar_selector_'
            + helper
            + "("
            + ",".join("hm_value_stable(value" + str(k) + ")" for k in range(arity))
            + ",&result->stable),out);\n}\n"
        )
        symbols.append("hmath_scalar_selector_" + helper)
    mapping.append(
        {
            "symbol": "HMath.Complex.Elementary",
            "c": ["hmath_complex_elementary_object"],
            "python": "hmath.complex.Elementary",
            "specializations": ["actual original selector"],
        }
    )
    mapping.append(
        {
            "symbol": "HMath.Trigonometry.ComplexFunction",
            "c": ["hmath_trigonometry_complex_function_object"],
            "python": "hmath.trigonometry.ComplexFunction",
            "specializations": ["actual original selector"],
        }
    )
    h.append("#ifdef __cplusplus\n}\n#endif\n#endif\n")
    out = {
        "include/hmath_scalar_extras.h": "".join(h),
        "cbits/scalar_extras.c": "".join(c),
        "src/HMath/FFI/ScalarExtras.hs": "".join(hs),
        "bindings/schema/scalar-extras-objects.json": json.dumps(
            {"schema": 1, "bindings": mapping}, indent=2
        )
        + "\n",
        "bindings/schema/scalar-extras-symbols.txt": "\n".join(symbols) + "\n",
    }
    docs = [
        '# Complete scalar-domain adapters\n\nThese functions call the original Complex, Trigonometry, NumberTheory and Special APIs. C includes `hmath_scalar_extras.h`; Python namespaces extend existing modules without replacing earlier numerical functions. Complex selectors are owned immutable original objects, constructed with `complex.exp()`/`trigonometry.c_sin()` etc. The `complex_function` adapter accepts `dtype="float32"` or `"float64"`; actual typed Complex Float inputs remain Float through the original RealFloat algorithm. Other complex operations/SFResult retain original Double precision. No principal-branch, pole/nonfinite, error-estimate or integer-budget policy is changed.\n\nValues use the [owned structured protocol](values.md): inputs borrowed, outputs owned/untouched on failure, each reference pins the runtime. Exact integers have no fixed precision or floating conversion. Variable-length/nested lists and tuples keep their original order/shape; Maybe uses None. Checked source errors retain complete MathError/status11. Selectors use kinds352/353. SFResult uses a tuple of two Doubles, interoperable with existing SFResult(value,error) named tuples; its raw constructor does not normalize or certify the error field.\n\n'
    ]
    for namespace, items in mods.items():
        class_name = (
            "Elementary"
            if namespace == "complex"
            else "ComplexFunction"
            if namespace == "trigonometry"
            else None
        )
        py = [
            "# SPDX-License-Identifier: MPL-2.0\n# Generated by tools/generate_scalar_extras.py; do not edit.\nfrom ._scalar_extras_base import "
            + (class_name + ", _invoke" if class_name else "_invoke")
            + "\n"
        ]
        exports = [class_name] if class_name else []
        for e in items:
            name = snake(e["name"])
            params = [n for n, t in e["args"]]
            extra = ["*", "dtype=None"] if e["name"] == "complexFunction" else []
            py.append(
                "\n\ndef "
                + name
                + "("
                + ", ".join(params + extra)
                + '):\n    """'
                + e["module"]
                + "."
                + e["name"]
                + " :: "
                + e["signature"]
                + '."""\n    return _invoke('
                + repr("hmath_" + namespace + "_" + name)
                + ", "
                + repr([t for n, t in e["args"]])
                + ", ["
                + ", ".join(params)
                + "], "
                + repr(e["result"])
                + (", dtype=dtype" if extra else "")
                + ")\n"
            )
            exports.append(name)
            docs.append(
                "## `"
                + namespace
                + "."
                + name
                + "`\n\n"
                + source_prose(e)
                + "\n\n```haskell\n"
                + e["signature"]
                + "\n```\n\n```c\n"
                + (
                    "hmath_status hmath_"
                    + namespace
                    + "_"
                    + name
                    + "("
                    + ", ".join(
                        ["hmath_context *context"]
                        + ["const hmath_value *" + n for n in params]
                        + ["hmath_value **out"]
                    )
                    + ");"
                )
                + "\n```\n\n"
            )
        py.append("\n\n__all__ = " + json.dumps(sorted(exports), indent=4) + "\n")
        out["bindings/python/_hmath_native/" + namespace + "_extras.py"] = "".join(py)
    out["docs/reference/scalar-extras.md"] = "".join(docs)
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    for name, content in generate().items():
        path = ROOT / name
        if args.check:
            if not path.exists() or path.read_text() != content:
                parser.exit(1, "Stale scalar extra binding: " + name + "\n")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)


if __name__ == "__main__":
    main()
