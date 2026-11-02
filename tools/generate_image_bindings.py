# SPDX-License-Identifier: MPL-2.0
"""Generate direct Haskell Image bindings and a lossless Tensor Double bridge."""

import argparse
import json
import re
from pathlib import Path

from generate_graph_bindings import snake, source_prose, type_spec

ROOT = Path(__file__).resolve().parent.parent
TYPES = {
    "Image": ("HMath.Image.Core", "C", 160, "Image"),
    "Tensor Double": ("HMath.Tensor", "T", 161, "TensorDouble"),
    "Boundary": ("HMath.Image.Core", "C", 162, "Boundary"),
    "GradientOperator": ("HMath.Image.Filter", "F", 163, "GradientOperator"),
    "Morphology": ("HMath.Image.Filter", "F", 164, "Morphology"),
    "TemplateMetric": ("HMath.Image.Measure", "M", 165, "TemplateMetric"),
    "Interpolation": ("HMath.Image.Spatial", "S", 166, "Interpolation"),
    "Connectivity": ("HMath.Image.Spatial", "S", 167, "Connectivity"),
    "ColorSpace": ("HMath.Image.Color", "K", 168, "ColorSpace"),
}
SPECS = []


def add(module, name, args, result, checked=True):
    SPECS.append(
        {
            "module": module,
            "name": name,
            "args": args,
            "result": result,
            "checked": checked,
            "signature": " -> ".join(
                [typ for _, typ in args]
                + [("Either MathError " if checked else "") + result]
            ),
        }
    )


for name, args, result, checked in [
    (
        "image",
        [("shape", "[Int]"), ("channels", "Int"), ("values", "[Double]")],
        "Image",
        True,
    ),
    ("fromTensor", [("tensor", "Tensor Double")], "Image", True),
    ("toTensor", [("image", "Image")], "Tensor Double", True),
    ("imageShape", [("image", "Image")], "[Int]", False),
    ("imageChannels", [("image", "Image")], "Int", False),
    ("imageValues", [("image", "Image")], "[Double]", False),
    ("pixel", [("image", "Image"), ("coordinates", "[Int]")], "[Double]", True),
    ("channel", [("index", "Int"), ("image", "Image")], "Image", True),
    ("combineChannels", [("images", "[Image]")], "Image", True),
    (
        "mapImage",
        [("function", "(Double -> Double)"), ("image", "Image")],
        "Image",
        True,
    ),
    (
        "zipImage",
        [("function", "(Double -> Double -> Double)"), ("a", "Image"), ("b", "Image")],
        "Image",
        True,
    ),
    (
        "normalize",
        [("low", "Double"), ("high", "Double"), ("image", "Image")],
        "Image",
        True,
    ),
    ("brightness", [("offset", "Double"), ("image", "Image")], "Image", True),
    (
        "contrast",
        [("factor", "Double"), ("pivot", "Double"), ("image", "Image")],
        "Image",
        True,
    ),
    ("gamma", [("power", "Double"), ("image", "Image")], "Image", True),
    ("Constant", [("fill", "Double")], "Boundary", False),
    ("Clamp", [], "Boundary", False),
    ("Reflect", [], "Boundary", False),
    ("Wrap", [], "Boundary", False),
]:
    add("HMath.Image.Core", name, args, result, checked)
for name, args, result, checked in [
    (
        "convolve",
        [
            ("boundary", "Boundary"),
            ("shape", "[Int]"),
            ("weights", "[Double]"),
            ("image", "Image"),
        ],
        "Image",
        True,
    ),
    (
        "correlate",
        [
            ("boundary", "Boundary"),
            ("shape", "[Int]"),
            ("weights", "[Double]"),
            ("image", "Image"),
        ],
        "Image",
        True,
    ),
    (
        "gaussianBlur",
        [
            ("boundary", "Boundary"),
            ("sigma", "Double"),
            ("radius", "Int"),
            ("image", "Image"),
        ],
        "Image",
        True,
    ),
    (
        "boxBlur",
        [("boundary", "Boundary"), ("radius", "Int"), ("image", "Image")],
        "Image",
        True,
    ),
    (
        "medianBlur",
        [("boundary", "Boundary"), ("radius", "Int"), ("image", "Image")],
        "Image",
        True,
    ),
    (
        "bilateralBlur",
        [
            ("boundary", "Boundary"),
            ("sigma_space", "Double"),
            ("sigma_range", "Double"),
            ("radius", "Int"),
            ("image", "Image"),
        ],
        "Image",
        True,
    ),
    (
        "sharpen",
        [
            ("boundary", "Boundary"),
            ("amount", "Double"),
            ("sigma", "Double"),
            ("radius", "Int"),
            ("image", "Image"),
        ],
        "Image",
        True,
    ),
    (
        "gradient",
        [
            ("method", "GradientOperator"),
            ("boundary", "Boundary"),
            ("image", "Image"),
        ],
        "(Image, Image, Image, Image)",
        True,
    ),
    ("laplacian", [("boundary", "Boundary"), ("image", "Image")], "Image", True),
    (
        "canny",
        [
            ("boundary", "Boundary"),
            ("sigma", "Double"),
            ("radius", "Int"),
            ("low", "Double"),
            ("high", "Double"),
            ("image", "Image"),
        ],
        "Image",
        True,
    ),
    (
        "morphology",
        [
            ("operation", "Morphology"),
            ("boundary", "Boundary"),
            ("shape", "[Int]"),
            ("mask", "[Bool]"),
            ("image", "Image"),
        ],
        "Image",
        True,
    ),
    (
        "morphologicalGradient",
        [
            ("boundary", "Boundary"),
            ("shape", "[Int]"),
            ("mask", "[Bool]"),
            ("image", "Image"),
        ],
        "Image",
        True,
    ),
    ("validateBoundary", [("boundary", "Boundary")], "()", True),
    ("scalar2D", [("image", "Image")], "(Int, Int)", True),
    ("windowOffsets", [("radius", "Int"), ("image", "Image")], "[[Int]]", True),
]:
    add("HMath.Image.Filter", name, args, result, checked)
for name in ["Sobel", "Prewitt", "Scharr"]:
    add("HMath.Image.Filter", name, [], "GradientOperator", False)
for name in ["Erosion", "Dilation", "Opening", "Closing"]:
    add("HMath.Image.Filter", name, [], "Morphology", False)
for name, args, result in [
    ("histogram", [("bins", "Int"), ("image", "Image")], "[[Int]]"),
    ("equalizeHistogram", [("bins", "Int"), ("image", "Image")], "Image"),
    (
        "clahe",
        [
            ("bins", "Int"),
            ("tiles", "(Int, Int)"),
            ("clip_limit", "Double"),
            ("image", "Image"),
        ],
        "Image",
    ),
    ("threshold", [("level", "Double"), ("image", "Image")], "Image"),
    ("otsu", [("bins", "Int"), ("image", "Image")], "([Double], Image)"),
    (
        "adaptiveThreshold",
        [
            ("gaussian", "Bool"),
            ("boundary", "Boundary"),
            ("radius", "Int"),
            ("offset", "Double"),
            ("image", "Image"),
        ],
        "Image",
    ),
]:
    add("HMath.Image.Histogram", name, args, result)
for name, args, result in [
    (
        "templateMatch",
        [("metric", "TemplateMetric"), ("needle", "Image"), ("haystack", "Image")],
        "Image",
    ),
    (
        "rawMoment",
        [("row_order", "Int"), ("column_order", "Int"), ("image", "Image")],
        "Double",
    ),
    (
        "centralMoment",
        [("row_order", "Int"), ("column_order", "Int"), ("image", "Image")],
        "Double",
    ),
    ("imageCentroid", [("image", "Image")], "(Double, Double)"),
    ("integralImage", [("image", "Image")], "Image"),
    (
        "rectangleSum",
        [("origin", "(Int, Int)"), ("extent", "(Int, Int)"), ("image", "Image")],
        "[Double]",
    ),
    ("meanSquaredError", [("a", "Image"), ("b", "Image")], "Double"),
    (
        "peakSignalToNoise",
        [("data_range", "Double"), ("a", "Image"), ("b", "Image")],
        "Double",
    ),
    (
        "structuralSimilarity",
        [("data_range", "Double"), ("window", "Int"), ("a", "Image"), ("b", "Image")],
        "Double",
    ),
]:
    add("HMath.Image.Measure", name, args, result)
for name in ["SquaredDifference", "NormalizedCorrelation"]:
    add("HMath.Image.Measure", name, [], "TemplateMetric", False)
for name, args, result in [
    (
        "resize",
        [
            ("interpolation", "Interpolation"),
            ("boundary", "Boundary"),
            ("shape", "(Int, Int)"),
            ("image", "Image"),
        ],
        "Image",
    ),
    (
        "warp",
        [
            ("interpolation", "Interpolation"),
            ("boundary", "Boundary"),
            ("shape", "(Int, Int)"),
            ("matrix", "[[Double]]"),
            ("image", "Image"),
        ],
        "Image",
    ),
    (
        "translate",
        [
            ("interpolation", "Interpolation"),
            ("boundary", "Boundary"),
            ("row_shift", "Double"),
            ("column_shift", "Double"),
            ("image", "Image"),
        ],
        "Image",
    ),
    (
        "rotate",
        [
            ("interpolation", "Interpolation"),
            ("boundary", "Boundary"),
            ("angle", "Double"),
            ("image", "Image"),
        ],
        "Image",
    ),
    (
        "connectedComponents",
        [("connectivity", "Connectivity"), ("image", "Image")],
        "(Image, [Int])",
    ),
    ("distanceTransform", [("spacing", "[Double]"), ("image", "Image")], "Image"),
]:
    add("HMath.Image.Spatial", name, args, result)
for name in ["Nearest", "Bilinear", "Bicubic", "Lanczos"]:
    add("HMath.Image.Spatial", name, [], "Interpolation", False)
for name in ["AxisConnected", "FullyConnected"]:
    add("HMath.Image.Spatial", name, [], "Connectivity", False)
for name, args, result in [
    (
        "convertColor",
        [("source", "ColorSpace"), ("destination", "ColorSpace"), ("image", "Image")],
        "Image",
    ),
    ("grayscale", [("source", "ColorSpace"), ("image", "Image")], "Image"),
]:
    add("HMath.Image.Color", name, args, result)
for name in ["SRGB", "LinearRGB", "HSV", "HSL", "XYZ", "Lab", "YCbCr"]:
    add("HMath.Image.Color", name, [], "ColorSpace", False)
add(
    "HMath.Tensor",
    "tensor",
    [("shape", "[Int]"), ("values", "[Double]")],
    "Tensor Double",
)
add("HMath.Tensor", "tensorShape", [("tensor", "Tensor Double")], "[Int]", False)
add("HMath.Tensor", "tensorValues", [("tensor", "Tensor Double")], "[Double]", False)

HS_PREFIX = """{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE FlexibleInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}
-- SPDX-License-Identifier: MPL-2.0
-- Generated by tools/generate_image_bindings.py.
module HMath.FFI.Image where
import Control.Exception (Exception,bracket,catch,evaluate,throwIO)
import Foreign
import Foreign.C
import HMath.FFI.Boundary
import HMath.FFI.GraphCodec (Wire(..),boxed,unboxed)
import HMath.FFI.Value
import qualified HMath.Image.Core as C
import qualified HMath.Image.Filter as F
import qualified HMath.Image.Histogram as H
import qualified HMath.Image.Measure as M
import qualified HMath.Image.Spatial as S
import qualified HMath.Image.Color as K
import qualified HMath.Tensor as T
import System.IO.Unsafe (unsafePerformIO)

instance Wire C.Image where
    wire image = Opaque 160 0 (length (C.imageValues image)) (mapM_ evaluate (C.imageValues image)) image
    unwire = unboxed 160
instance Wire (T.Tensor Double) where
    wire tensor = Opaque 161 0 (length (T.tensorValues tensor)) (mapM_ evaluate (T.tensorValues tensor)) tensor
    unwire = unboxed 161

data CallbackStatus = CallbackStatus CInt deriving Show
instance Exception CallbackStatus
imageBoundary :: IO CInt -> IO CInt
imageBoundary action = boundary (action `catch` (\\(CallbackStatus status) -> pure status))
type ImageCallback = Ptr () -> Ptr () -> Ptr (Ptr ()) -> IO CInt
foreign import ccall safe "hm_image_invoke" invokeCallback :: FunPtr ImageCallback -> Ptr () -> StablePtr Value -> Ptr (StablePtr Value) -> IO CInt
{-# NOINLINE callbackFunction #-}
callbackFunction :: FunPtr ImageCallback -> Ptr () -> [Double] -> Double
callbackFunction callback userdata arguments = unsafePerformIO $ do
    let input=Tuple (map wire arguments)
    forceValue input
    pointer <- newStablePtr input
    alloca $ \\out -> do
        status <- invokeCallback callback userdata pointer out
        if status /= 0 then throwIO (CallbackStatus status) else pure ()
        result <- peek out
        bracket (pure result) freeStablePtr (\\value -> deRefStablePtr value >>= unwire)
foreign export ccall "hm_image_clone" clone :: StablePtr Value -> Ptr (StablePtr Value) -> IO CInt
clone :: StablePtr Value -> Ptr (StablePtr Value) -> IO CInt
clone input out = imageBoundary $ do
    value <- deRefStablePtr input
    checked (Right value) (`publish` out)
"""


def generate():
    known = {
        e["symbol"]
        for e in json.loads((ROOT / "bindings/schema/public-api.json").read_text())[
            "symbols"
        ]
    }
    for item in SPECS:
        assert item["module"] + "." + item["name"] in known, item
    qualifiers = {module: qualifier for _, (module, qualifier, _, _) in TYPES.items()}
    qualifiers["HMath.Image.Histogram"] = "H"
    header = [
        '/* SPDX-License-Identifier: MPL-2.0 */\n/* Generated by tools/generate_image_bindings.py. */\n#ifndef HMATH_IMAGE_H\n#define HMATH_IMAGE_H\n#include "hmath_value.h"\n#ifdef __cplusplus\nextern "C" {\n#endif\n',
        "/* Original finite interleaved ND Image algorithms; all coefficients are Double.\n * Inputs are borrowed; successful outputs transfer one immutable Value owner.\n * Outputs stay untouched on failure. Release with hmath_value_release. Live\n * owners pin the runtime. Source MathError/status11 retains its full payload.\n * Source shape/sample/work budgets, boundary policies, color ranges, tie order\n * and unchecked-helper errors remain unchanged. Callbacks are synchronous and\n * deterministic: input is a borrowed tuple of Double values; output transfers\n * one owned Double scalar. Retain input children if keeping them after return.\n * Callbacks may reenter checked APIs and must not unwind through C. */\n",
        "typedef hmath_status (*hmath_image_callback)(const hmath_value *arguments,void *userdata,hmath_value **out);\n",
    ]
    c = [
        '/* SPDX-License-Identifier: MPL-2.0 */\n/* Generated by tools/generate_image_bindings.py. */\n#include "hmath_image.h"\n#include "value_internal.h"\nextern int hm_image_apply(int,void *const *,size_t,hmath_image_callback,void *,void **);\n',
        """extern int hm_image_clone(void *,void **);
int hm_image_invoke(hmath_image_callback callback,void *userdata,void *stable,void **out) {
    hmath_value *temporary=NULL,*input=NULL,*output=NULL;
    hmath_status status=hm_value_begin(NULL,&temporary);
    if(status) { extern void hm_value_free(void *);hm_value_free(stable);return status; }
    temporary->stable=stable;
    status=hm_value_finish(temporary,0,&input);
    if(status)return status;
    status=callback(input,userdata,&output);
    if(!status && !output)status=hm_error(HMATH_INVALID_ARGUMENT,"NULL Image callback output");
    if(!status)status=(hmath_status)hm_image_clone(output->stable,out);
    if(output)hmath_value_release(output);
    hmath_value_release(input);
    return status;
}
""",
    ]
    hs = [HS_PREFIX]
    py = [
        '# SPDX-License-Identifier: MPL-2.0\n# Generated by tools/generate_image_bindings.py; do not edit.\n"""Original Image operations and typed Tensor Double interchange."""\nfrom ._image_base import _invoke\nfrom ._tensor_object import TensorDouble\nfrom ._value import Value, register\nfrom .image_color import linear_to_srgb, srgb_to_linear\n'
    ]
    docs = [
        "# Image bindings\n\n`from hmath import image` exposes the original ND CPU image algorithms. Storage is spatial row-major with interleaved channels. Intensities have no implicit range; color/histogram functions retain their source restrictions. Haskell algorithms, limits, normalization and errors are unchanged.\n\nC includes `hmath_image.h` and uses [owned structured values](values.md). Inputs are borrowed, outputs transfer one owner and stay untouched on failure. Immutable values support independent readers with their own references. All real values are Double; Python uses floats, lists and tuples matching each signature. Original MathError constructors/payloads remain available. Callbacks are synchronous and deterministic; Python exceptions rethrow after native cleanup. The Image result is fully evaluated before callbacks are released.\n\nImages retain the source rank1..8, channels1..16 and262144-sample limits. Filtering/interpolation retain per-algorithm budgets. No intensity clipping, dtype promotion, coordinate normalization or substituted boundary policy is added. The TensorDouble bridge retains the actual `HMath.Tensor.Tensor Double`; helpers construct it and expose shape/logical values without claiming the remaining Tensor operations.\n\n"
    ]
    mappings = []
    symbols = []
    exports = ["linear_to_srgb", "srgb_to_linear"]
    for typ, (module, qualifier, tag, python) in TYPES.items():
        qualified = (
            qualifier + "." + ("Tensor Double" if typ == "Tensor Double" else typ)
        )
        if typ not in ("Image", "Tensor Double"):
            hs.append(
                "instance Wire "
                + qualified
                + " where\n    wire = boxed "
                + str(tag)
                + "\n    unwire = unboxed "
                + str(tag)
                + "\n"
            )
        header.append(
            "typedef hmath_value hmath_image_"
            + snake(python)
            + "_object; /* kind"
            + str(tag)
            + " */\n"
        )
        if typ != "Tensor Double":
            py.append(
                "\n\nclass "
                + python
                + '(Value):\n    """Actual immutable '
                + module
                + "."
                + typ
                + ' native owner."""\n\n\nregister('
                + str(tag)
                + ", "
                + python
                + ")\n"
            )
        exports.append(python)
        source = module + "." + ("Tensor" if typ == "Tensor Double" else typ)
        mappings.append(
            {
                "symbol": source,
                "c": ["hmath_image_" + snake(python) + "_object"],
                "python": "hmath.image." + python,
                "specializations": [
                    "Double only"
                    if typ == "Tensor Double"
                    else "original concrete type"
                ],
            }
        )
    hs.append(
        'foreign export ccall "hm_image_apply" apply :: CInt -> Ptr (StablePtr Value) -> CSize -> FunPtr ImageCallback -> Ptr () -> Ptr (StablePtr Value) -> IO CInt\napply :: CInt -> Ptr (StablePtr Value) -> CSize -> FunPtr ImageCallback -> Ptr () -> Ptr (StablePtr Value) -> IO CInt\napply operation inputs arity callback userdata out = imageBoundary $ do\n    values <- peekArray (fromIntegral arity) inputs >>= mapM deRefStablePtr\n    case (operation,values) of\n'
    )
    for op, item in enumerate(SPECS):
        args = item["args"]
        plain = [(name, typ) for name, typ in args if "->" not in typ]
        callback = any("->" in typ for _, typ in args)
        name = snake(item["name"])
        symbol = "hmath_image_" + name
        decl = ["hmath_context *context"]
        for arg, typ in args:
            decl += (
                ["hmath_image_callback " + arg, "void *userdata"]
                if "->" in typ
                else ["const hmath_value *" + arg]
            )
        prototype = (
            "hmath_status "
            + symbol
            + "("
            + ", ".join(decl + ["hmath_value **out"])
            + ")"
        )
        header.append(
            "/* "
            + item["module"]
            + "."
            + item["name"]
            + " :: "
            + item["signature"]
            + " */\nHMATH_API "
            + prototype
            + ";\n"
        )
        c.append(
            prototype
            + " {\n    if(!out"
            + "".join(" || !" + arg for arg, _ in args)
            + ')return hm_error(HMATH_INVALID_ARGUMENT,"NULL Image argument");\n    hmath_value *temporary=NULL;\n    hmath_status status=hm_value_begin(context,&temporary);\n    if(status)return status;\n    void *arguments[]={'
            + (", ".join("hm_value_stable(" + arg + ")" for arg, _ in plain) or "NULL")
            + "};\n    return hm_value_finish(temporary,hm_image_apply("
            + str(op)
            + ",arguments,"
            + str(len(plain))
            + ","
            + ("function,userdata" if callback else "NULL,NULL")
            + ",&temporary->stable),out);\n}\n"
        )
        hs.append(
            "        ("
            + str(op)
            + ",["
            + ",".join("v" + arg for arg, _ in plain)
            + "]) -> do\n"
        )
        for arg, typ in plain:
            native_type = typ
            for token, (_, qualifier, _, _) in sorted(
                TYPES.items(), key=lambda item: -len(item[0])
            ):
                native_type = re.sub(
                    r"(?<![\w.])" + re.escape(token) + r"(?!\w)",
                    qualifier + "." + token,
                    native_type,
                )
            hs.append(
                "            arg"
                + arg[0].upper()
                + arg[1:]
                + " <- (unwire v"
                + arg
                + " :: IO ("
                + native_type
                + "))\n"
            )
        if callback:
            hs.append(
                "            let argFunction "
                + (
                    "x y = callbackFunction callback userdata [x,y]\n"
                    if item["name"] == "zipImage"
                    else "x = callbackFunction callback userdata [x]\n"
                )
            )
        call = (
            qualifiers[item["module"]]
            + "."
            + item["name"]
            + "".join(" arg" + arg[0].upper() + arg[1:] for arg, _ in args)
        )
        hs.append(
            "            checked ("
            + (call if item["checked"] else "Right (" + call + ")")
            + ") (\\result -> publish (wire result) out)\n"
        )
        specs = [type_spec(t, TYPES) for _, t in args]
        py.append(
            "\n\ndef "
            + name
            + "("
            + ", ".join(arg for arg, _ in args)
            + '):\n    """'
            + item["module"]
            + "."
            + item["name"]
            + " :: "
            + item["signature"]
            + '."""\n    return _invoke('
            + repr(symbol)
            + ", "
            + repr(specs)
            + ", ["
            + ", ".join(arg for arg, _ in args)
            + "])\n"
        )
        docs.append(
            "## `"
            + name
            + "`\n\n`image."
            + name
            + "("
            + ", ".join(arg for arg, _ in args)
            + ")`\n\n"
            + source_prose(item)
            + "\n\n```haskell\n"
            + item["signature"]
            + "\n```\n\n```c\n"
            + prototype
            + ";\n```\n\n"
        )
        mappings.append(
            {
                "symbol": item["module"] + "." + item["name"],
                "c": [symbol],
                "python": "hmath.image." + name,
                "specializations": [
                    "Double only"
                    if item["module"] == "HMath.Tensor"
                    else "original concrete types"
                ],
            }
        )
        symbols.append(symbol)
        exports.append(name)
    hs.append('        _ -> invalid "Image operation identifier or arity differs"\n')
    header.append("#ifdef __cplusplus\n}\n#endif\n#endif\n")
    py.append("\n\n__all__ = " + json.dumps(sorted(exports), indent=4) + "\n")
    return {
        "include/hmath_image.h": "".join(header),
        "cbits/image.c": "".join(c),
        "src/HMath/FFI/Image.hs": "".join(hs),
        "bindings/python/_hmath_native/image.py": "".join(py),
        "bindings/schema/image-objects.json": json.dumps(
            {"schema": 1, "bindings": mappings}, indent=2
        )
        + "\n",
        "bindings/schema/image-symbols.txt": "\n".join(symbols) + "\n",
        "docs/reference/image-bindings.md": "".join(docs),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    for name, content in generate().items():
        path = ROOT / name
        if args.check:
            if not path.exists() or path.read_text() != content:
                parser.exit(1, "Stale Image binding: " + name + "\n")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)


if __name__ == "__main__":
    main()
