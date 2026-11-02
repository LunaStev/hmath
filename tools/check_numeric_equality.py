# SPDX-License-Identifier: MPL-2.0
"""Direct-source Eq semantics for Geometry distances and opaque numeric records."""

import argparse
import math
import os
import struct
import subprocess
import sys
import tempfile
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def bits(value):
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
    from _hmath_native import _value as v
    from _hmath_native import algebra_api as aa
    from _hmath_native import autodiff as ad
    from _hmath_native import geometry as g
    from _hmath_native import numeric_types as n

    owners, fixtures = [], []

    def own(value):
        owners.append(value)
        return value

    def fixture(label, first, second, hs_first, hs_second):
        fixtures.append((label, first, second, hs_first, hs_second))

    huge = 10**160
    fixture(
        "hugeInteger", huge, huge + 1, f"({huge}::Integer)", f"({huge + 1}::Integer)"
    )
    fixture(
        "closeRational",
        Fraction(1, huge),
        Fraction(1, huge + 1),
        f"1%{huge}",
        f"1%{huge + 1}",
    )
    fixture("Bool", False, True, "False", "True")
    fixture("String/NUL/Unicode", "a\0가", "a\0나", '"a\\0가"', '"a\\0나"')
    fixture(
        "tuple labels",
        (huge, "a"),
        (huge + 1, "a"),
        f'({huge}::Integer,"a")',
        f'({huge + 1}::Integer,"a")',
    )
    fixture(
        "list labels",
        [huge, 2],
        [huge + 1, 2],
        f"[{huge},2::Integer]",
        f"[{huge + 1},2::Integer]",
    )
    fixture("Maybe", None, 3, "Nothing::Maybe Integer", "Just 3")
    for dtype, typ in [
        ("float32", "Float"),
        ("float64", "Double"),
        ("complex64", "Complex Float"),
        ("complex128", "Complex Double"),
        ("int64", "Int64"),
        ("uint64", "Word64"),
    ]:
        complex_type = dtype.startswith("complex")
        first, second = (complex(1, 2), complex(1, 3)) if complex_type else (1, 2)
        fixture(
            dtype,
            own(v.scalar(first, dtype)),
            own(v.scalar(second, dtype)),
            "((1:+2)::" + typ + ")" if complex_type else "(1::" + typ + ")",
            "((1:+3)::" + typ + ")" if complex_type else "(2::" + typ + ")",
        )
    one = own(n.number(1, "integer"))
    two = own(n.number(2, "integer"))
    nd1, nd2 = own(n.dual(one, one)), own(n.dual(one, two))
    fixture(
        "Numeric.Dual exact tangent equality",
        nd1,
        nd2,
        "N.Dual (1::Integer) 1",
        "N.Dual (1::Integer) 2",
    )
    fixture(
        "nested Numeric.Dual",
        own(n.dual(nd1, nd2)),
        own(n.dual(nd2, nd1)),
        "N.Dual (N.Dual (1::Integer) 1)(N.Dual 1 2)",
        "N.Dual (N.Dual (1::Integer) 2)(N.Dual 1 1)",
    )
    for dtype, typ in [("float32", "Float"), ("float64", "Double")]:
        x, y = own(n.number(1.0, dtype)), own(n.number(2.0, dtype))
        q1, q2 = own(n.quaternion(x, x, x, x)), own(n.quaternion(x, x, x, y))
        fixture(
            "Numeric.Quaternion " + dtype,
            q1,
            q2,
            "N.Quaternion(1::" + typ + ") 1 1 1",
            "N.Quaternion(1::" + typ + ") 1 1 2",
        )
        fixture(
            "Numeric.DualQuaternion " + dtype,
            own(n.dual_quaternion(q1, q1)),
            own(n.dual_quaternion(q1, q2)),
            "N.DualQuaternion(N.Quaternion(1::"
            + typ
            + ") 1 1 1)(N.Quaternion 1 1 1 1)",
            "N.DualQuaternion(N.Quaternion(1::"
            + typ
            + ") 1 1 1)(N.Quaternion 1 1 1 2)",
        )
    fixture(
        "AD.Dual uses full Eq rather than primal Ord",
        own(ad.Dual(1.0, 1.0)),
        own(ad.Dual(1.0, 2.0)),
        "A.Dual(1::Double) 1",
        "A.Dual(1::Double) 2",
    )
    fixture(
        "AD.Dual Complex no Ord",
        own(ad.Dual(1 + 2j, 3 + 4j)),
        own(ad.Dual(1 + 2j, 3 + 5j)),
        "A.Dual((1:+2)::Complex Double)(3:+4)",
        "A.Dual((1:+2)::Complex Double)(3:+5)",
    )
    fixture(
        "Exact Ord/Eq",
        own(aa.Exact(Fraction(1, 3))),
        own(aa.Exact(Fraction(2, 3))),
        "AA.Exact(1%3)",
        "AA.Exact(2%3)",
    )
    fixture(
        "Point2 Eq",
        own(g.p2(1.0, 2.0)),
        own(g.p2(1.0, 3.0)),
        "G.P2 1 2",
        "G.P2 1 3",
    )
    fixture(
        "NaN Eq remains nonreflexive",
        math.nan,
        math.nan,
        "(0/0::Double)",
        "(0/0::Double)",
    )
    half1, half2 = own(n.float16_from_bits(0x7E01)), own(n.float16_from_bits(0x7E02))
    fixture(
        "Float16 original bit Eq including NaN",
        half1,
        half2,
        "N.float16FromBits 32257",
        "N.float16FromBits 32258",
    )
    fixture(
        "BFloat16 original bit Eq",
        own(n.bfloat16_from_bits(0x7FC1)),
        own(n.bfloat16_from_bits(0x7FC2)),
        "N.bfloat16FromBits 32705",
        "N.bfloat16FromBits 32706",
    )
    nearest = n.RoundingMode.NEAREST_EVEN
    for label, constructor, source in [
        (
            "BigFloat",
            lambda precision: n.big_float(precision, nearest, Fraction(1, 2)),
            "N.bigFloat",
        ),
        (
            "Fixed",
            lambda precision: n.fixed(precision, nearest, Fraction(1, 2)),
            "N.fixed",
        ),
        (
            "Decimal",
            lambda precision: n.decimal(precision, nearest, Fraction(1, 2)),
            "N.decimal",
        ),
    ]:
        a = own(n.rounded_value(own(constructor(3))))
        b = own(n.rounded_value(own(constructor(4))))
        fixture(
            label + " precision/scale participates in Eq",
            a,
            b,
            "N.roundedValue(right(" + source + " 3 N.NearestEven(1%2)))",
            "N.roundedValue(right(" + source + " 4 N.NearestEven(1%2)))",
        )
    fixture(
        "Interval",
        own(n.interval(-0.0, 2.0)),
        own(n.interval(0.0, 3.0)),
        "right(N.interval (-0.0) 2)",
        "right(N.interval 0 3)",
    )
    fixture(
        "Rounded flags and ordering",
        own(
            n.rounded(
                half1, [n.NumericException.INEXACT, n.NumericException.NUMERIC_OVERFLOW]
            )
        ),
        own(
            n.rounded(
                half1, [n.NumericException.NUMERIC_OVERFLOW, n.NumericException.INEXACT]
            )
        ),
        "N.Rounded(N.float16FromBits 32257)[N.Inexact,N.NumericOverflow]",
        "N.Rounded(N.float16FromBits 32257)[N.NumericOverflow,N.Inexact]",
    )
    fixture(
        "Limits every metadata field",
        own(n.float16_limits()),
        own(
            n.numeric_limits_record(
                2.0**-14,
                2.0**-24,
                65504.0,
                2.0**-10,
                12,
                -13,
                16,
            )
        ),
        "N.float16Limits",
        "N.NumericLimits(2**(-14)::Double)(2**(-24)) 65504 (2**(-10)) 12 (-13) 16",
    )
    fixture(
        "Constant metadata and exact rationals",
        own(
            n.constant(
                "x\0",
                Fraction(1, 3),
                Fraction(1, 10**100),
                Fraction(1, 10**110),
                "m",
                "s",
            )
        ),
        own(
            n.constant(
                "x\0",
                Fraction(1, 3),
                Fraction(1, 10**100),
                Fraction(1, 10**110),
                "m",
                "other",
            )
        ),
        'K.Constant "x\\0"(1%3)(1%10^100)(1%10^110) "m" "s"',
        'K.Constant "x\\0"(1%3)(1%10^100)(1%10^110) "m" "other"',
    )

    tests = []
    for label, a, b, ha, hb in fixtures:
        for name, py, encoder in [
            ("hammingDistance", g.hamming_distance, str),
            ("jaccardDistance", g.jaccard_distance, bits),
        ]:
            for suffix, xs, ys, hxs, hys in [
                ("self", [a], [a], "[" + ha + "]", "[" + ha + "]"),
                ("different", [a], [b], "[" + ha + "]", "[" + hb + "]"),
                (
                    "duplicates",
                    [a, a, b],
                    [b, a, b],
                    "[" + ha + "," + ha + "," + hb + "]",
                    "[" + hb + "," + ha + "," + hb + "]",
                ),
            ]:
                tests.append(
                    (
                        label + " " + name + " " + suffix,
                        "G." + name + "(" + hxs + ")(" + hys + ")",
                        "show" if name == "hammingDistance" else "fp64",
                        lambda py=py, xs=xs, ys=ys, encoder=encoder: encoder(
                            py(xs, ys, dtype="value")
                        ),
                    )
                )
    for name, py, encoder in [
        ("hammingDistance", g.hamming_distance, str),
        ("jaccardDistance", g.jaccard_distance, bits),
    ]:
        tests.append(
            (
                name + " empty",
                "G." + name + "([]::[Integer]) []",
                "show" if name == "hammingDistance" else "fp64",
                lambda py=py, encoder=encoder: encoder(py([], [], dtype="value")),
            )
        )
    tests.append(
        (
            "hamming length error",
            "G.hammingDistance([1]::[Integer]) []",
            "show",
            lambda: str(g.hamming_distance([1], [], dtype="value")),
        )
    )
    lines = [
        "module Main where",
        "import qualified HMath.Geometry as G",
        "import qualified HMath.Numeric as N",
        "import qualified HMath.Autodiff as A",
        "import qualified HMath.Constants as K",
        "import qualified HMath.API.Algebra as AA",
        "import HMath.Error",
        "import Data.Complex",
        "import Data.Ratio",
        "import Data.Int",
        "import Data.Word",
        "import GHC.Float",
        "right(Right x)=x",
        "right(Left e)=error(show e)",
        'fp64 x=if isNaN x then "nan" else show(castDoubleToWord64 x)',
        "emit :: (a->String)->Either MathError a->IO ()",
        'emit e= either(putStrLn . ("ERR:"++) . show)(putStrLn . ("OK:"++) . e)',
        "main=do",
    ]
    lines.extend(
        "  emit " + encoder + " (" + expression + ")"
        for _, expression, encoder, _ in tests
    )
    with tempfile.TemporaryDirectory(prefix="hmath-equality-oracle-") as directory:
        path = Path(directory)
        (path / "Main.hs").write_text("\n".join(lines) + "\n")
        subprocess.run(
            [
                "ghc",
                "-O0",
                "-isrc",
                "-Iinclude",
                "-outputdir",
                directory,
                "-stubdir",
                directory,
                str(path / "Main.hs"),
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
    assert len(expected) == len(tests)
    for (label, _, _, call), wanted in zip(tests, expected):
        try:
            actual = "OK:" + call()
        except hmath.HMathError as error:
            assert error.math_error is not None, (label, error)
            actual = "ERR:" + str(error.math_error)
        assert actual == wanted, (label, actual, wanted)
    for owner in reversed(owners):
        owner.close()
    print(
        f"Geometry Eq: {len(expected)} direct original-Haskell cases, exact/structural labels, distinct Dual semantics, NaN and all opaque NumericTypes Eq records passed."
    )


if __name__ == "__main__":
    main()
