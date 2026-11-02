# SPDX-License-Identifier: MPL-2.0
"""Validate all Image bindings against independent original Haskell evaluations."""

import argparse
import math
import os
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

from generate_graph_bindings import split_top
from generate_image_bindings import SPECS, TYPES

ROOT = Path(__file__).resolve().parent.parent


def fp(value):
    return (
        "nan"
        if math.isnan(value)
        else str(struct.unpack("!Q", struct.pack("!d", value))[0])
    )


def hsencode(typ):
    if typ == "Image":
        return "image"
    if typ == "Tensor Double":
        return "tensor"
    if typ == "Double":
        return "fp"
    if typ in ("Int", "Bool"):
        return "show"
    if typ == "()":
        return '(const "unit")'
    if typ in TYPES:
        return '(const "' + typ + '")'
    if typ.startswith("["):
        return "(list " + hsencode(typ[1:-1]) + ")"
    if typ.startswith("("):
        parts = split_top(typ[1:-1], ",")
        variables = ["v" + str(n) for n in range(len(parts))]
        return (
            "(\\("
            + ",".join(variables)
            + ') -> "("++intercalate ";" ['
            + ",".join(hsencode(t) + " " + v for t, v in zip(parts, variables))
            + ']++")")'
        )
    raise AssertionError(typ)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", type=Path, required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(args.library.resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    from _hmath_native import image as i
    from _hmath_native._value import Value

    owners = []

    def own(x):
        owners.append(x)
        return x

    img = own(i.image([3, 3], 1, [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]))
    other = own(i.image([3, 3], 1, [0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1]))
    badimg = own(i.image([2], 1, [0, 1]))
    rgb = own(i.image([3, 3], 3, [0.1, 0.2, 0.3] * 9))
    needle = own(i.image([2, 2], 1, [0.1, 0.2, 0.3, 0.5]))
    binary = own(i.image([3, 3], 1, [0, 1, 0, 1, 1, 0, 0, 0, 1]))
    tensor = own(i.to_tensor(img))
    bad_tensor = own(i.tensor([9], [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]))
    clamp = own(i.clamp())
    bad_boundary = own(i.constant(math.nan))
    sobel = own(i.sobel())
    scharr = own(i.scharr())
    erosion = own(i.erosion())
    closing = own(i.closing())
    squared = own(i.squared_difference())
    correlation = own(i.normalized_correlation())
    bilinear = own(i.bilinear())
    lanczos = own(i.lanczos())
    axis = own(i.axis_connected())
    fully = own(i.fully_connected())
    srgb = own(i.srgb())
    hsv = own(i.hsv())

    def encode(typ, x):
        if typ == "Image":
            return (
                "I"
                + encode("[Int]", i.image_shape(x))
                + ":"
                + str(i.image_channels(x))
                + ":"
                + encode("[Double]", i.image_values(x))
            )
        if typ == "Tensor Double":
            return (
                "T"
                + encode("[Int]", i.tensor_shape(x))
                + ":"
                + encode("[Double]", i.tensor_values(x))
            )
        if typ == "Double":
            return fp(x)
        if typ in ("Int", "Bool"):
            return str(x)
        if typ == "()":
            return "unit"
        if typ in TYPES:
            assert isinstance(x, getattr(i, TYPES[typ][3])), (typ, type(x))
            return typ
        if typ.startswith("["):
            return "[" + ",".join(encode(typ[1:-1], v) for v in x) + "]"
        if typ.startswith("("):
            return (
                "("
                + ";".join(encode(t, v) for t, v in zip(split_top(typ[1:-1], ","), x))
                + ")"
            )
        raise AssertionError(typ)

    def fixture(entry, name, typ, bad):
        function = entry["name"]
        if typ == "Image":
            if bad:
                return badimg, "badimg"
            if function in ("convertColor", "grayscale"):
                return rgb, "rgb"
            if function in ("distanceTransform", "connectedComponents"):
                return binary, "binary"
            if name == "needle":
                return needle, "needle"
            return (other, "other") if name == "b" else (img, "img")
        if typ == "Tensor Double":
            return (bad_tensor, "badTensor") if bad else (tensor, "tensorA")
        if typ == "Boundary":
            return (bad_boundary, "C.Constant (0/0)") if bad else (clamp, "C.Clamp")
        if typ == "GradientOperator":
            return (scharr, "F.Scharr") if bad else (sobel, "F.Sobel")
        if typ == "Morphology":
            return (closing, "F.Closing") if bad else (erosion, "F.Erosion")
        if typ == "TemplateMetric":
            return (
                (correlation, "M.NormalizedCorrelation")
                if bad
                else (squared, "M.SquaredDifference")
            )
        if typ == "Interpolation":
            return (lanczos, "S.Lanczos") if bad else (bilinear, "S.Bilinear")
        if typ == "Connectivity":
            return (fully, "S.FullyConnected") if bad else (axis, "S.AxisConnected")
        if typ == "ColorSpace":
            return (hsv, "K.HSV") if name == "destination" else (srgb, "K.SRGB")
        if typ == "Int":
            value = (
                -1
                if bad
                else {
                    "channels": 1,
                    "index": 0,
                    "bins": 4,
                    "radius": 1,
                    "window": 2,
                }.get(name, 1)
            )
            return value, "(" + str(value) + ")"
        if typ == "Double":
            value = (
                math.inf
                if bad
                else {
                    "low": 0.1,
                    "high": 0.8,
                    "factor": 1.2,
                    "pivot": 0.5,
                    "power": 2,
                    "level": 0.5,
                    "sigma": 0.8,
                    "sigma_space": 0.8,
                    "sigma_range": 0.3,
                    "amount": 0.2,
                    "data_range": 1,
                    "clip_limit": 1,
                    "fill": -0.25,
                    "offset": 0.1,
                }.get(name, 0.25)
            )
            return value, "(1/0)" if bad else "(" + str(value) + ")"
        if typ == "Bool":
            return not bad, "False" if bad else "True"
        if typ == "(Int, Int)":
            value = (-1, 0) if bad else (0, 0) if name == "origin" else (2, 2)
            return value, str(value)
        if typ == "[Image]":
            return ([], "[]") if bad else ([img, other], "[img,other]")
        if typ == "[Int]":
            value = (
                []
                if bad
                else [1, 1]
                if name == "coordinates"
                else [3, 3, 1]
                if entry["module"] == "HMath.Tensor"
                else [3, 3]
            )
            return value, str(value)
        if typ == "[Double]":
            value = (
                []
                if bad
                else [1 / 9] * 9
                if name == "weights"
                else [1, 1]
                if name == "spacing"
                else [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
            )
            haskell = (
                "[]"
                if bad
                else "replicate 9 (1/9)"
                if name == "weights"
                else str(value)
            )
            return value, haskell
        if typ == "[Bool]":
            return ([], "[]") if bad else ([True] * 9, "replicate 9 True")
        if typ == "[[Double]]":
            return (
                ([], "[]")
                if bad
                else ([[1, 0, 0], [0, 1, 0], [0, 0, 1]], "[[1,0,0],[0,1,0],[0,0,1]]")
            )
        if typ == "(Double -> Double)":
            return (
                (lambda _: math.nan, "(\\_ -> 0/0)")
                if bad
                else (lambda x: x * x + 0.1, "(\\x -> x*x+0.1)")
            )
        if typ == "(Double -> Double -> Double)":
            return (
                (lambda _x, _y: math.nan, "(\\_ _ -> 0/0)")
                if bad
                else (lambda x, y: x - y, "(\\x y -> x-y)")
            )
        raise AssertionError((function, name, typ))

    lines = [
        "import qualified HMath.Image.Core as C",
        "import qualified HMath.Image.Filter as F",
        "import qualified HMath.Image.Histogram as H",
        "import qualified HMath.Image.Measure as M",
        "import qualified HMath.Image.Spatial as S",
        "import qualified HMath.Image.Color as K",
        "import qualified HMath.Tensor as T",
        "import HMath.Error (MathError)",
        "import Data.List (intercalate)",
        "import GHC.Float",
        'fp x=if isNaN x then "nan" else show (castDoubleToWord64 x)',
        'list e xs="["++intercalate "," (map e xs)++"]"',
        'image x="I"++list show (C.imageShape x)++":"++show (C.imageChannels x)++":"++list fp (C.imageValues x)',
        'tensor x="T"++list show (T.tensorShape x)++":"++list fp (T.tensorValues x)',
        "right (Right x)=x",
        "right (Left e)=error (show e)",
        "emit :: (a->String)->Either MathError a->IO ()",
        'emit e (Right x)=putStrLn ("OK:"++e x)',
        'emit _ (Left e)=putStrLn ("ERR:"++show e)',
        "img=right (C.image [3,3] 1 [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9])",
        "other=right (C.image [3,3] 1 [0.9,0.8,0.7,0.6,0.5,0.4,0.3,0.2,0.1])",
        "badimg=right (C.image [2] 1 [0,1])",
        "rgb=right (C.image [3,3] 3 (concat (replicate 9 [0.1,0.2,0.3])))",
        "needle=right (C.image [2,2] 1 [0.1,0.2,0.3,0.5])",
        "binary=right (C.image [3,3] 1 [0,1,0,1,1,0,0,0,1])",
        "tensorA=right (C.toTensor img)",
        "badTensor=right (T.tensor [9] [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9::Double])",
        "main=do",
    ]
    qualifiers = {module: qualifier for _, (module, qualifier, _, _) in TYPES.items()}
    qualifiers["HMath.Image.Histogram"] = "H"
    cases = []
    for entry in SPECS:
        for bad in (False, True):
            values = [fixture(entry, name, typ, bad) for name, typ in entry["args"]]
            call = (
                qualifiers[entry["module"]]
                + "."
                + entry["name"]
                + "".join(" (" + hs + ")" for _, hs in values)
            )
            if not entry["checked"]:
                call = "Right (" + call + ")"
            lines.append("  emit " + hsencode(entry["result"]) + " (" + call + ")")
            cases.append((entry, [value for value, _ in values], bad))
    # Every enum branch is consumed by the original numerical operation.
    extras = []
    for name in ["Sobel", "Prewitt", "Scharr"]:
        enum = own(
            getattr(
                i, {"Sobel": "sobel", "Prewitt": "prewitt", "Scharr": "scharr"}[name]
            )()
        )
        extras.append(
            (
                "gradient-" + name,
                "F.gradient F." + name + " C.Reflect img",
                "(Image, Image, Image, Image)",
                lambda enum=enum: i.gradient(enum, i.reflect(), img),
            )
        )
    for name in ["Erosion", "Dilation", "Opening", "Closing"]:
        enum = own(getattr(i, name.lower())())
        extras.append(
            (
                "morphology-" + name,
                "F.morphology F."
                + name
                + " C.Wrap [3,3] [True,False,False,True,True,False,False,False,False] img",
                "Image",
                lambda enum=enum: i.morphology(
                    enum,
                    i.wrap(),
                    [3, 3],
                    [True, False, False, True, True, False, False, False, False],
                    img,
                ),
            )
        )
    for name in ["Clamp", "Reflect", "Wrap"]:
        enum = own(getattr(i, name.lower())())
        extras.append(
            (
                "boundary-" + name,
                "F.gaussianBlur C." + name + " 0.8 2 img",
                "Image",
                lambda enum=enum: i.gaussian_blur(enum, 0.8, 2, img),
            )
        )
    for name, py in [
        ("Nearest", "nearest"),
        ("Bilinear", "bilinear"),
        ("Bicubic", "bicubic"),
        ("Lanczos", "lanczos"),
    ]:
        enum = own(getattr(i, py)())
        extras.append(
            (
                "interpolation-" + name,
                "S.resize S." + name + " C.Reflect (2,4) img",
                "Image",
                lambda enum=enum: i.resize(enum, i.reflect(), (2, 4), img),
            )
        )
    for name, py in [
        ("SRGB", "srgb"),
        ("LinearRGB", "linear_rgb"),
        ("HSV", "hsv"),
        ("HSL", "hsl"),
        ("XYZ", "xyz"),
        ("Lab", "lab"),
        ("YCbCr", "y_cb_cr"),
    ]:
        enum = own(getattr(i, py)())
        extras.append(
            (
                "color-" + name,
                "K.convertColor K.SRGB K." + name + " rgb",
                "Image",
                lambda enum=enum: i.convert_color(srgb, enum, rgb),
            )
        )
    for _, call, typ, _ in extras:
        lines.append("  emit " + hsencode(typ) + " (" + call + ")")
    with tempfile.TemporaryDirectory(prefix="hmath-image-oracle-") as directory:
        path = Path(directory)
        source = path / "Main.hs"
        source.write_text("\n".join(lines) + "\n")
        subprocess.run(
            [
                "ghc",
                "-O0",
                "-isrc",
                "-outputdir",
                directory,
                "-stubdir",
                directory,
                str(source),
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
        if isinstance(value, Value):
            value.close()
        elif isinstance(value, (tuple, list)):
            for child in value:
                close(child)

    for index, (entry, values, bad) in enumerate(cases):
        result = None
        try:
            result = getattr(
                i, __import__("generate_graph_bindings").snake(entry["name"])
            )(*values)
            actual = "OK:" + encode(entry["result"], result)
        except hmath.HMathError as error:
            assert error.math_error is not None, (entry["name"], error)
            actual = "ERR:" + str(error.math_error)
        finally:
            close(result)
        assert actual == expected[index], (entry["name"], bad, actual, expected[index])
    for index, (label, _, typ, function) in enumerate(extras, len(cases)):
        result = function()
        try:
            assert "OK:" + encode(typ, result) == expected[index], (
                label,
                encode(typ, result),
                expected[index],
            )
        finally:
            close(result)
    child = i.to_tensor(img)
    img.close()
    assert i.tensor_shape(child) == [3, 3, 1]
    child.close()

    def fail(_):
        raise LookupError("image callback failed")

    try:
        i.map_image(fail, other)
        raise AssertionError("callback error swallowed")
    except LookupError as error:
        assert str(error) == "image callback failed"
    result = i.map_image(lambda x: x + i.pixel(other, [0, 0])[0], other)
    assert i.image_values(result)[0] == 1.8
    result.close()
    for owner in owners:
        owner.close()
    print(
        f"Image: {len(expected)} direct Haskell cases, all enum branches, exact Tensor interchange and callback ownership passed."
    )


if __name__ == "__main__":
    main()
