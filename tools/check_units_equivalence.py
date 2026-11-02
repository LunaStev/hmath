# SPDX-License-Identifier: MPL-2.0
"""Exact original-Haskell oracle for Units catalogs, constructors and operations."""

import argparse
import os
import subprocess
import sys
import tempfile
from fractions import Fraction
from pathlib import Path

from check_polynomial_equivalence import HASKELL, close
from generate_units_bindings import ops, snake

ROOT = Path(__file__).resolve().parent.parent


def encode(value, u):
    import hmath

    if isinstance(value, u.Dimension):
        return "D" + encode(value.exponents, u)
    if isinstance(value, u.Unit):
        dimension = u.unit_dimension(value)
        try:
            return (
                "U["
                + ",".join(
                    encode(x, u)
                    for x in [value.name, dimension, value.scale, value.offset]
                )
                + "]"
            )
        finally:
            dimension.close()
    if isinstance(value, u.Quantity):
        dimension = u.quantity_dimension(value)
        with u.celsius() as c:
            try:
                temperature = u.in_unit(c, value)
            except hmath.HMathError as error:
                temperature = "E" + str(error.math_error)
        try:
            return (
                "Q["
                + ",".join(encode(x, u) for x in [dimension, value.si_value])
                + ","
                + (
                    temperature
                    if isinstance(temperature, str)
                    else encode(temperature, u)
                )
                + "]"
            )
        finally:
            dimension.close()
    if isinstance(value, u.SIPrefix):
        return (
            "SIP["
            + ",".join(encode(x, u) for x in [value.name, value.symbol, value.exponent])
            + "]"
        )
    if isinstance(value, str):
        return "L[" + ",".join("I" + str(ord(x)) for x in value) + "]"
    if isinstance(value, Fraction):
        return f"R{value.numerator}/{value.denominator}"
    if isinstance(value, bool):
        return "B1" if value else "B0"
    if isinstance(value, int):
        return "I" + str(value)
    if isinstance(value, (list, tuple)):
        return (
            ("T[" if isinstance(value, tuple) else "L[")
            + ",".join(encode(x, u) for x in value)
            + "]"
        )
    raise TypeError(type(value))


EXTRA = r"""
instance E Char where enc x="I"++show(ord x)
instance E U.Dimension where enc x="D"++enc(U.dimensionExponents x)
instance E U.Unit where enc x="U["++enc(U.unitName x)++","++enc(U.unitDimension x)++","++enc(U.unitScale x)++","++enc(U.unitOffset x)++"]"
instance E U.Quantity where enc x="Q["++enc(U.quantityDimension x)++","++enc(U.siValue x)++","++ok(U.inUnit U.celsius x)++"]"
instance E U.SIPrefix where enc x="SIP["++enc(U.prefixName x)++","++enc(U.prefixSymbol x)++","++enc(U.prefixExponent x)++"]"
unitM=case U.unit "x\NUL\945" U.lengthDimension (3%7) 0 of Right x->x;Left e->error(show e)
prefix=U.SIPrefix "kilo" "k" 3
leftQ=U.quantity U.metre (3%2)
rightQ=U.quantity U.metre 2
"""


def fixtures(u):
    owned = []

    def own(value):
        owned.append(value)
        return value

    metre = own(u.metre())
    km = own(u.kilometre())
    c = own(u.celsius())
    f = own(u.fahrenheit())
    dim = own(u.length_dimension())
    unit = own(u.unit("x\0α", dim, Fraction(3, 7), 0))
    prefix = own(u.SIPrefix("kilo", "k", 3))
    left = own(u.quantity(metre, Fraction(3, 2)))
    right = own(u.quantity(metre, 2))
    result = []

    def add(name, args, hs, mode="pure"):
        result.append(
            (snake(name), args, ("ok" if mode == "either" else "enc") + " (" + hs + ")")
        )

    for name, args, _return, mode in ops():
        values = []
        hsargs = []
        for parameter, typ in args:
            if typ == "Dimension":
                value, h = dim, "U.lengthDimension"
            elif typ == "[Integer]":
                value, h = [1] + [0] * 8, "[1,0,0,0,0,0,0,0,0]"
            elif typ == "Rational":
                value, h = Fraction(3, 7), "(3%7)"
            elif typ == "Integer":
                value, h = -2, "(-2)"
            elif typ == "Int":
                value, h = 3, "3"
            elif typ == "String":
                value, h = (
                    ("x\0α", '"x\\NUL\\945"') if parameter == "name" else ("k", '"k"')
                )
            elif typ == "SIPrefix":
                value, h = prefix, "prefix"
            elif typ == "Quantity":
                value, h = (
                    (right, "rightQ")
                    if parameter in ("right", "denominator")
                    else (left, "leftQ")
                )
            elif typ == "Unit":
                if name == "temperatureDifference":
                    value, h = c, "U.celsius"
                elif name == "convert":
                    value, h = (
                        (km, "U.kilometre")
                        if parameter == "source"
                        else (metre, "U.metre")
                    )
                elif name in ("unitName", "unitDimension", "unitScale", "unitOffset"):
                    value, h = unit, "unitM"
                else:
                    value, h = metre, "U.metre"
            else:
                raise AssertionError(typ)
            if name == "unit" and parameter == "offset":
                value, h = 0, "0"
            values.append(value)
            hsargs.append(h)
        add(name, values, "U." + name + " " + " ".join(hsargs), mode)
    # Invalid and affine/temperature branches use original source checks.
    add("dimension", [[0] * 8], "U.dimension [0,0,0,0,0,0,0,0]", "either")
    add("unit", ["bad", dim, 0, 0], 'U.unit "bad" U.lengthDimension 0 0', "either")
    add("unit", ["bad", dim, 1, 1], 'U.unit "bad" U.lengthDimension 1 1', "either")
    add("unitProduct", [c, metre], "U.unitProduct U.celsius U.metre", "either")
    add("unitQuotient", [metre, c], "U.unitQuotient U.metre U.celsius", "either")
    add("unitPower", [c, 2], "U.unitPower U.celsius 2", "either")
    add(
        "temperatureDifference",
        [metre, 1],
        "U.temperatureDifference U.metre 1",
        "either",
    )
    add("convert", [metre, c, 1], "U.convert U.metre U.celsius 1", "either")
    absA = own(u.quantity(c, 20))
    absB = own(u.quantity(c, 10))
    delta = own(u.temperature_difference(c, 10))
    for name, arguments, hargs in [
        (
            "addQuantity",
            [absA, absB],
            "(U.quantity U.celsius 20) (U.quantity U.celsius 10)",
        ),
        (
            "addQuantity",
            [absA, delta],
            "(U.quantity U.celsius 20) (case U.temperatureDifference U.celsius 10 of Right x->x;Left e->error(show e))",
        ),
        (
            "subtractQuantity",
            [absA, absB],
            "(U.quantity U.celsius 20) (U.quantity U.celsius 10)",
        ),
        (
            "subtractQuantity",
            [delta, absA],
            "(case U.temperatureDifference U.celsius 10 of Right x->x;Left e->error(show e)) (U.quantity U.celsius 20)",
        ),
        ("multiplyQuantity", [absA, left], "(U.quantity U.celsius 20) leftQ"),
        ("divideQuantity", [left, absA], "leftQ (U.quantity U.celsius 20)"),
    ]:
        add(name, arguments, "U." + name + " " + hargs, "either")
    add(
        "inUnit",
        [f, delta],
        "U.inUnit U.fahrenheit (case U.temperatureDifference U.celsius 10 of Right x->x;Left e->error(show e))",
        "either",
    )
    add(
        "inUnit", [f, absA], "U.inUnit U.fahrenheit (U.quantity U.celsius 20)", "either"
    )
    add("prefixed", [prefix, c], "U.prefixed prefix U.celsius", "either")
    huge = own(u.SIPrefix("huge", "H", 10001))
    add(
        "prefixed",
        [huge, metre],
        'U.prefixed (U.SIPrefix "huge" "H" 10001) U.metre',
        "either",
    )
    return result, owned


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--library", required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(Path(args.library).resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    from _hmath_native import units_values as u

    cases, owners = fixtures(u)
    try:
        source = (
            HASKELL.replace(
                "import Data.Complex",
                "import qualified HMath.Units as U\nimport Data.Char (ord)\nimport Data.Complex",
            )
            .replace("pR=P.polynomial", EXTRA + "\npR=P.polynomial")
            .replace("EXPRESSIONS", "\n    , ".join(case[2] for case in cases))
        )
        with tempfile.TemporaryDirectory(prefix="hmath-units-oracle-") as directory:
            path = Path(directory) / "Main.hs"
            path.write_text(source)
            expected = subprocess.run(
                ["runghc", "-isrc", str(path)],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=True,
            ).stdout.splitlines()
        actual = []
        for name, arguments, _expression in cases:
            try:
                value = getattr(u, name)(*arguments)
            except hmath.HMathError as error:
                actual.append("E" + str(error.math_error or error))
            else:
                try:
                    actual.append(encode(value, u))
                finally:
                    close(value)
        errors = [
            (cases[i][0], expected[i], actual[i])
            for i in range(len(actual))
            if expected[i] != actual[i]
        ]
        if len(expected) != len(actual) or errors:
            raise AssertionError(errors[:10])
        print(
            f"Units direct Haskell equivalence: {len(actual)} cases, all80remaining symbols"
        )
    finally:
        for owner in owners:
            owner.close()


if __name__ == "__main__":
    main()
