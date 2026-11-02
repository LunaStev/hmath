# SPDX-License-Identifier: MPL-2.0
"""Original shape witnesses backed by real reified Haskell type indices."""

import argparse
import json
from pathlib import Path

from generate_foundation_bindings import format_c
from generate_linear_bindings import snake
from generate_stochastic_bindings import fmt

ROOT = Path(__file__).resolve().parent.parent
OPERATIONS = [
    (
        "shapeDimensions",
        ["shape"],
        "asShape shape >>= pure . V.List . map V.Index . S.shapeDimensions",
    ),
    ("shapeElements", ["shape"], "asShape shape >>= pure . V.Index . S.shapeElements"),
    (
        "makeShape",
        ["dimensions"],
        "do {ds <- V.asList dimensions >>= mapM V.asIndex;Codec.shape <$> source(S.makeShape ds)}",
    ),
    (
        "ScalarShape",
        ["shape"],
        "do {s <- asShape shape;pure(V.Boolean(case s of S.ScalarShape -> True;_ -> False))}",
    ),
    (
        "VectorShape",
        ["shape"],
        "do {s <- asShape shape;pure(case s of S.VectorShape n -> V.Index n;_ -> V.None)}",
    ),
    (
        "MatrixShape",
        ["shape"],
        "do {s <- asShape shape;pure(case s of S.MatrixShape r c -> V.Tuple[V.Index r,V.Index c];_ -> V.None)}",
    ),
    (
        "staticMatrix",
        ["rows", "columns", "matrix"],
        "do {r <- V.asScalar rows;c <- V.asScalar columns;staticMatrix r c matrix}",
    ),
    ("dynamicMatrix", ["matrix"], "dynamicMatrix matrix"),
    ("staticMultiply", ["left", "right"], "staticMultiply left right"),
    ("staticTranspose", ["matrix"], "staticTranspose matrix"),
    (
        "reflectedShape",
        ["dimensions"],
        "V.asList dimensions >>= mapM V.asScalar >>= reflectedShape",
    ),
    (
        "staticTensor",
        ["dimensions", "tensor"],
        "do {ds <- V.asList dimensions >>= mapM V.asScalar;staticTensor ds tensor}",
    ),
    ("dynamicTensor", ["tensor"], "dynamicTensor tensor"),
    (
        "coordinates",
        ["prototype", "length", "values"],
        "do {n <- V.asScalar count;xs <- V.asList values;coordinatesFrom prototype n xs}",
    ),
    ("coordinateValues", ["coordinates"], "coordinateValues coordinates"),
    ("coordinatesToVector", ["coordinates"], "coordinatesToVector coordinates"),
]
TYPES = ["Shape", "StaticMatrix", "KnownShape", "StaticTensor", "Coordinates"]


def outputs():
    h = [
        """/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_SHAPE_H
#define HMATH_SHAPE_H
#include "hmath_foundation.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Original runtime and nominal type-indexed shapes. Implicit Haskell Nat
 * indices become explicit nonnegative Integer Values; KnownNat/KnownShape
 * dictionaries are reified, never coerced. Source Int overflow and dimension
 * checks remain. Shape patterns are read-only views. Matrix/Tensor results
 * interoperate with their ordinary public APIs. Inputs borrow; outputs own a
 * Value; failure leaves *out untouched. */
"""
    ]
    c = [
        '/* SPDX-License-Identifier: MPL-2.0 */\n#include "hmath_shape.h"\n#include "value_internal.h"\nextern int hm_shape_apply(int,void *const *,size_t,void **);\n'
    ]
    hs = [
        """{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- Generated calls to original shape APIs and typed representation helpers.
module HMath.FFI.ShapeAll where
import Foreign
import Foreign.C
import qualified HMath.API.Shape as S
import qualified HMath.FFI.Value as V
import qualified HMath.FFI.Boundary as Boundary
import HMath.FFI.FoundationCodec(source,foundationBoundary)
import HMath.FFI.ShapeCodec hiding(shape,coordinates)
import qualified HMath.FFI.ShapeCodec as Codec
apply :: Int -> [V.Value] -> IO V.Value
apply operation args=case(operation,args)of
"""
    ]
    py = [
        '''# SPDX-License-Identifier: MPL-2.0
"""Original checked shapes and genuine nominal KnownNat/KnownShape witnesses."""
from ._algebra_base import invoke
from ._foundation_base import FoundationValue,register,_invoke
'''
    ]
    bindings = []
    docs = [
        """# Runtime and type-indexed shapes

These APIs call the original `HMath.API.Shape` operations. Haskell type-level
natural dimensions become explicit Python integers/C Integer Values. The adapter
reifies actual `KnownNat` and recursive `KnownShape` dictionaries; it never
coerces a matrix/tensor to an unrelated shape. `reflected_shape` retains exact
Integer dimensions, even above Int. The original constructors decide Int
overflow and dynamic shape errors. Static multiplication also requires equal
nominal inner dimensions and identical element types.

`scalar_shape`, `vector_shape`, and `matrix_shape` are read-only source pattern
views: Boolean match, optional length, and optional `(rows, columns)`.
`make_shape` performs checked construction. `coordinates(length, values,
dtype=...)` retains the original lazy list element type; numeric, Bool, String
and Exact elements remain lossless. Vector conversion uses the original source
conversion and produces an ordinary interoperable Vector owner. Static wrappers
own independent references. Dynamic conversion retains the original element
type and does not copy or coerce mathematical values. Close each owned result.

"""
    ]
    for name in TYPES:
        if name == "KnownShape":
            py.append(
                '\nclass KnownShape:\n    """Original recursive type-level natural-list witness interface."""\n    @staticmethod\n    def reflected_shape(dimensions):\n        return reflected_shape(dimensions)\n'
            )
        else:
            py.append(
                "\nclass "
                + name
                + '(FoundationValue):\n    """Original HMath.API.Shape.'
                + name
                + ' owner."""\n    _source_type='
                + repr("HMath.API.Shape." + name)
                + "\n"
            )
            if name == "Shape":
                py.append(
                    "    @property\n    def dimensions(self):\n        return shape_dimensions(self)\n    @property\n    def elements(self):\n        return shape_elements(self)\n"
                )
            if name == "Coordinates":
                py.append(
                    "    @property\n    def values(self):\n        return coordinate_values(self)\n"
                )
            py.append(
                "register(" + repr("HMath.API.Shape." + name) + "," + name + ")\n"
            )
        bindings.append(
            {
                "symbol": "HMath.API.Shape." + name,
                "c": ["hmath_value", "hmath_value_release"],
                "python": "hmath.shape." + name,
                "specializations": [
                    "actual original type-level witness and source checks"
                ],
            }
        )
    for index, (name, parameters, body) in enumerate(OPERATIONS):
        arguments = ["count" if a == "length" else a for a in parameters]
        symbol = "hmath_shape_" + snake(name)
        hs.append(
            "    (" + str(index) + ",[" + ",".join(arguments) + "]) -> " + body + "\n"
        )
        prototype = (
            "hmath_status "
            + symbol
            + "("
            + ",".join(
                ["hmath_context *context"]
                + ["const hmath_value *" + a for a in arguments]
                + ["hmath_value **out"]
            )
            + ")"
        )
        h.append("/* HMath.API.Shape." + name + " */\nHMATH_API " + prototype + ";\n")
        c.append(
            prototype
            + " {\n    if(!out"
            + "".join(" || !" + a for a in arguments)
            + ')return hm_error(HMATH_INVALID_ARGUMENT,"NULL shape argument");\n    hmath_value *result;hmath_status status=hm_value_begin(context,&result);if(status)return status;\n    void *args[]={'
            + ",".join("hm_value_stable(" + a + ")" for a in arguments)
            + "};\n    return hm_value_finish(result,hm_shape_apply("
            + str(index)
            + ",args,"
            + str(len(arguments))
            + ",&result->stable),out);\n}\n"
        )
        python = snake(name)
        if name == "coordinates":
            py.append(
                '\ndef coordinates(length,values,*,dtype=None):\n    """Construct an original Coordinates n a with explicit nominal length."""\n    return invoke('
                + repr(symbol)
                + ',[["Integer"],["list",["a"]]],[length,values],"typed",dtype)\n'
            )
        else:
            specs = {
                "rows": ["Integer"],
                "columns": ["Integer"],
                "dimensions": ["list", ["Int"]]
                if name == "makeShape"
                else ["list", ["Integer"]],
            }
            py.append(
                "\ndef "
                + python
                + "("
                + ",".join(parameters)
                + '):\n    """Original HMath.API.Shape.'
                + name
                + '; borrowed inputs, owned result."""\n    return _invoke('
                + repr(symbol)
                + ","
                + repr([specs.get(p, ["Value"]) for p in parameters])
                + ",["
                + ",".join(parameters)
                + "])\n"
            )
        bindings.append(
            {
                "symbol": "HMath.API.Shape." + name,
                "c": [symbol],
                "python": "hmath.shape." + python,
                "specializations": [
                    "actual reified source type indices; numeric/Bool/String/Exact structural elements; no numeric coercion"
                ],
            }
        )
        docs.append(
            "## `shape."
            + python
            + "`\n\nCalls `HMath.API.Shape."
            + name
            + "`. C parameters: `"
            + ", ".join(parameters)
            + "`, each a borrowed Value; the output owns one reference. "
            + (
                "The prototype selects the original element type, including empty coordinates. "
                if name == "coordinates"
                else ""
            )
            + "Failures leave the output pointer untouched.\n\n"
        )
    hs.append("""    _ -> V.invalid "invalid shape operation/arity"
foreign export ccall "hm_shape_apply" ffiApply :: CInt -> Ptr(StablePtr V.Value) -> CSize -> Ptr(StablePtr V.Value) -> IO CInt
ffiApply :: CInt -> Ptr(StablePtr V.Value) -> CSize -> Ptr(StablePtr V.Value) -> IO CInt
ffiApply operation input count out=foundationBoundary $ do
    values <- peekArray(fromIntegral count) input >>= mapM deRefStablePtr
    value <- apply(fromIntegral operation) values
    Boundary.checked(Right())(const(V.publish value out))
""")
    h.append("#ifdef __cplusplus\n}\n#endif\n#endif\n")
    py.append(
        "\n__all__="
        + repr(sorted(TYPES + [snake(name) for name, *_ in OPERATIONS]))
        + "\n"
    )
    result = {
        "src/HMath/FFI/ShapeAll.hs": "".join(hs),
        "include/hmath_shape.h": "".join(h),
        "cbits/shape.c": "".join(c),
        "bindings/python/_hmath_native/shape_values.py": fmt(
            "".join(py), "shape_values.py"
        ),
        "bindings/schema/shape-objects.json": json.dumps(
            {"schema": 1, "bindings": sorted(bindings, key=lambda x: x["symbol"])},
            indent=2,
        )
        + "\n",
        "docs/reference/shapes.md": "".join(docs),
    }
    return {
        name: format_c(data) if name.endswith((".c", ".h")) else data
        for name, data in result.items()
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    for name, data in outputs().items():
        path = ROOT / name
        if args.check:
            if not path.exists() or path.read_text() != data:
                raise SystemExit("Stale: " + name)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(data)
