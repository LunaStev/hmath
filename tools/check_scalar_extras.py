# SPDX-License-Identifier: MPL-2.0
"""Compare completed scalar domains with direct source Haskell and IEEE/exact wire values."""

import argparse
import math
import os
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

from generate_graph_bindings import snake
from generate_scalar_extras import COMPLEX_FUNCTION, ELEMENTARY

ROOT = Path(__file__).resolve().parent.parent


def bits(value, width=64):
    return (
        "nan"
        if math.isnan(value)
        else str(
            struct.unpack(
                "!Q" if width == 64 else "!I",
                struct.pack("!d" if width == 64 else "!f", value),
            )[0]
        )
    )


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--library", type=Path, required=True)
    a = p.parse_args()
    os.environ["HMATH_LIBRARY"] = str(a.library.resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    from _hmath_native import (
        complex_extras as c,
    )
    from _hmath_native import (
        numbertheory_extras as n,
    )
    from _hmath_native import (
        special_extras as s,
    )
    from _hmath_native import (
        trigonometry_extras as t,
    )
    from _hmath_native._value import Value

    cases = []
    owners = []

    def case(label, hs, encode, call):
        cases.append((label, hs, encode, call))

    def own(x):
        owners.append(x)
        return x

    def encode(kind, value):
        if kind == "selector":
            return value.name
        if kind in ("c64", "c32"):
            width = 64 if kind == "c64" else 32
            return bits(value.real, width) + "," + bits(value.imag, width)
        if kind == "d":
            return bits(value)
        if kind in ("i", "z"):
            return str(value)
        if kind == "sf":
            return bits(value.sf_value) + "," + bits(value.sf_error)
        if kind == "matrix":
            return (
                str(value.shape[0])
                + ","
                + str(value.shape[1])
                + ":"
                + encode("list:c64", value.to_list())
            )
        if kind.startswith("list:"):
            return "[" + ",".join(encode(kind[5:], x) for x in value) + "]"
        if kind.startswith("pair:"):
            ks = kind[5:].split(":")
            return "(" + ";".join(encode(k, x) for k, x in zip(ks, value)) + ")"
        if kind.startswith("maybe:"):
            return (
                "Nothing" if value is None else "Just(" + encode(kind[6:], value) + ")"
            )
        raise AssertionError(kind)

    def hse(kind):
        if kind == "selector":
            return "show"
        if kind == "c64":
            return "(complex fp64)"
        if kind == "c32":
            return "(complex fp32)"
        if kind == "d":
            return "fp64"
        if kind in ("i", "z"):
            return "show"
        if kind == "sf":
            return "sf"
        if kind == "matrix":
            return "matrix"
        if kind.startswith("list:"):
            return "(list " + hse(kind[5:]) + ")"
        if kind.startswith("pair:"):
            ks = kind[5:].split(":")
            vs = ["v" + str(j) for j in range(len(ks))]
            return (
                "(\\("
                + ",".join(vs)
                + ') -> "("++intercalate ";" ['
                + ",".join(hse(k) + " " + v for k, v in zip(ks, vs))
                + ']++")")'
            )
        if kind.startswith("maybe:"):
            return '(maybe "Nothing" (\\x -> "Just("++' + hse(kind[6:]) + ' x++")"))'
        raise AssertionError(kind)

    input_values = [complex(0.25, 0.5), 0j, complex(-1, -0.0), complex(math.inf, 0.25)]
    hs64 = [
        "(0.25:+0.5)",
        "(0:+0)",
        "((-1):+castWord64ToDouble 9223372036854775808)",
        "((1/0):+0.25)",
    ]
    hs32 = [
        "(0.25:+0.5)",
        "(0:+0)",
        "((-1):+castWord32ToFloat 2147483648)",
        "((1/0):+0.25)",
    ]
    for name in ELEMENTARY:
        selector = own(getattr(c, snake(name))())
        case(
            "Elementary." + name,
            "Right C." + name,
            "selector",
            lambda selector=selector: selector.clone().decode(),
        )
        for j, value in enumerate(input_values):
            case(
                name + str(j),
                "C.elementary C." + name + " (opaque " + hs64[j] + ")",
                "c64",
                lambda selector=selector, value=value: c.elementary(selector, value),
            )
    for name in COMPLEX_FUNCTION:
        selector = own(getattr(t, snake(name))())
        case(
            "ComplexFunction." + name,
            "Right T." + name,
            "selector",
            lambda selector=selector: selector.clone().decode(),
        )
        for width, values in [(32, hs32), (64, hs64)]:
            for j, value in enumerate(input_values):
                case(
                    name + str(width) + str(j),
                    "T.complexFunction T."
                    + name
                    + " (opaque "
                    + values[j]
                    + "::Complex "
                    + ("Float" if width == 32 else "Double")
                    + ")",
                    "c32" if width == 32 else "c64",
                    lambda selector=selector, value=value, width=width: (
                        t.complex_function(selector, value, dtype="float" + str(width))
                    ),
                )
    ma = own(
        c.complex_matrix(
            2, 2, [1 + 2j, complex(-0.5, 0.25), complex(-0.0, -0.0), 3 - 2j]
        )
    )
    mb = own(c.complex_matrix(2, 1, [0.5 + 1j, -2 + 0.25j]))
    case(
        "complexMatrix",
        "C.complexMatrix 2 2 matrixValues",
        "matrix",
        lambda: c.complex_matrix(
            2, 2, [1 + 2j, complex(-0.5, 0.25), complex(-0.0, -0.0), 3 - 2j]
        ),
    )
    case(
        "multiplyMatrices",
        "C.multiplyMatrices ma mb",
        "matrix",
        lambda: c.multiply_matrices(ma, mb),
    )
    case(
        "conjugateTranspose",
        "C.conjugateTranspose ma",
        "matrix",
        lambda: c.conjugate_transpose(ma),
    )
    case(
        "matrixshapeerror",
        "C.complexMatrix (-1) 2 []",
        "matrix",
        lambda: c.complex_matrix(-1, 2, []),
    )
    for name, hs in [("complex_fft", "complexFFT"), ("complex_ifft", "complexIFFT")]:
        for values, expression in [
            ([], "[]"),
            ([1 + 2j, 0.5 - 1j, 3 + 4j], "[1:+2,0.5:+(-1),3:+4]"),
        ]:
            case(
                name + expression,
                "C." + hs + " " + expression,
                "list:c64",
                lambda name=name, values=values: getattr(c, name)(values),
            )
    for pairs in [
        [(2, 3), (3, 5)],
        [(-1, 6), (5, 8)],
        [(1, 2), (0, 2)],
        [(10**100 + 1, 97), (10**110 + 2, 101)],
    ]:
        hs = "[" + ",".join("(" + str(x) + "," + str(y) + ")" for x, y in pairs) + "]"
        case(
            "CRT" + hs,
            "N.chineseRemainder " + hs,
            "pair:z:z",
            lambda pairs=pairs: n.chinese_remainder(pairs),
        )
    for args in [(15, 21, 6), (-15, 21, 6), (0, 0, 0), (15, 21, 7), (10**90 + 1, 3, 1)]:
        case(
            "Diophantine" + str(args),
            "N.linearDiophantine " + " ".join("(" + str(x) + ")" for x in args),
            "pair:z:z:z:z",
            lambda args=args: n.linear_diophantine(*args),
        )
    for value in [0, 1, -1, 2, 4, 8, -8, -16, 10**100, 10**100 + 3]:
        case(
            "power" + str(value),
            "Right (N.perfectPower (" + str(value) + "))",
            "maybe:pair:z:i",
            lambda value=value: n.perfect_power(value),
        )
    for budget, value in [(1000, 360), (0, 97), (0, 1), (0, 360), (-1, 2), (10, 0)]:
        case(
            "factor" + str((budget, value)),
            "N.primeFactorization (" + str(budget) + ") (" + str(value) + ")",
            "list:pair:z:i",
            lambda budget=budget, value=value: n.prime_factorization(budget, value),
        )
    for value in [-1, 0, 1, 5]:
        case(
            "partitions" + str(value),
            "N.partitions (" + str(value) + ")",
            "list:list:i",
            lambda value=value: n.partitions(value),
        )
    for value, error, expression in [
        (1.25, -0.5, "S.SFResult 1.25 (-0.5)"),
        (-0.0, math.nan, "S.SFResult (castWord64ToDouble 9223372036854775808) (0/0)"),
        (math.inf, -0.0, "S.SFResult (1/0) (castWord64ToDouble 9223372036854775808)"),
    ]:
        case(
            "SFResult" + expression,
            "Right (" + expression + ")",
            "sf",
            lambda value=value, error=error: s.sf_result(value, error),
        )
        case(
            "sfValue" + expression,
            "Right (S.sfValue (" + expression + "))",
            "d",
            lambda value=value, error=error: s.sf_value((value, error)),
        )
        case(
            "sfError" + expression,
            "Right (S.sfError (" + expression + "))",
            "d",
            lambda value=value, error=error: s.sf_error((value, error)),
        )
    lines = [
        "import qualified HMath.Complex as C",
        "import qualified HMath.Trigonometry as T",
        "import qualified HMath.NumberTheory as N",
        "import qualified HMath.Special as S",
        "import qualified HMath.Matrix as M",
        "import HMath.Error (MathError)",
        "import Data.Complex",
        "import Data.List (intercalate)",
        "import GHC.Float",
        "{-# NOINLINE opaque #-}",
        "opaque x=x",
        'fp64 x=if isNaN x then "nan" else show (castDoubleToWord64 x)',
        'fp32 x=if isNaN x then "nan" else show (castFloatToWord32 x)',
        'complex e x=e (realPart x)++","++e (imagPart x)',
        'list e xs="["++intercalate "," (map e xs)++"]"',
        'sf x=fp64 (S.sfValue x)++","++fp64 (S.sfError x)',
        'matrix x=let (a,b)=M.shape x in show a++","++show b++":"++list (complex fp64) (M.toList x)',
        "right (Right x)=x",
        "right (Left e)=error (show e)",
        "emit :: (a->String)->Either MathError a->IO ()",
        'emit e (Right x)=putStrLn ("OK:"++e x)',
        'emit _ (Left e)=putStrLn ("ERR:"++show e)',
        "matrixValues=[1:+2,(-0.5):+0.25,castWord64ToDouble 9223372036854775808:+castWord64ToDouble 9223372036854775808,3:+(-2)]",
        "ma=right (C.complexMatrix 2 2 (opaque matrixValues))",
        "mb=right (C.complexMatrix 2 1 [0.5:+1,(-2):+0.25])",
        "main=do",
    ]
    for _, expression, kind, _ in cases:
        lines.append("  emit " + hse(kind) + " (" + expression + ")")
    with tempfile.TemporaryDirectory(prefix="hmath-scalar-extras-oracle-") as directory:
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

    def close(value):
        if isinstance(value, Value) or hasattr(value, "close"):
            value.close()
        elif isinstance(value, (tuple, list)):
            for child in value:
                close(child)

    for (label, _, kind, call), wanted in zip(cases, expected):
        result = None
        try:
            result = call()
            actual = "OK:" + encode(kind, result)
        except hmath.HMathError as error:
            assert error.math_error is not None, (label, error)
            actual = "ERR:" + str(error.math_error)
        finally:
            close(result)
        assert actual == wanted, (label, actual, wanted)
    assert len(cases) == len(expected)
    with c.exp() as a, c.exp() as b, c.log() as other:
        assert a == b and a != other
    for owner in owners:
        owner.close()
    print(
        f"Scalar extras: {len(expected)} direct Haskell cases, both complex precisions, signed-zero branches, exact integers and raw SFResult fields passed."
    )


if __name__ == "__main__":
    main()
