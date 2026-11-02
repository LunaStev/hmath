# SPDX-License-Identifier: MPL-2.0
"""Exact quantities, affine-temperature contracts and independent Units owners."""

import sys
from fractions import Fraction
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "bindings/python"))
import hmath
from _hmath_native import units_values as u
from _hmath_native._math_error import MathErrorKind

with u.Dimension([10**5000] + [0] * 8) as dimension:
    assert dimension.exponents == [10**5000] + [0] * 8
with u.length_dimension() as dimension:
    original = u.Unit("unit\0α🙂\ud800", dimension, Fraction(1, 10**5000 + 1), 0)
assert original.name == "unit\0α🙂\ud800"
assert original.scale == Fraction(1, 10**5000 + 1)
quantity = u.Quantity(original, 10**6000 + 3)
original.close()
assert quantity.si_value == Fraction(10**6000 + 3, 10**5000 + 1)
quantity.close()
with u.celsius() as c, u.fahrenheit() as f, u.kelvin() as k:
    assert u.convert(c, f, 100) == 212
    assert u.convert(f, c, 32) == 0
    absolute = u.quantity(c, 20)
    difference = u.temperature_difference(c, 10)
    assert u.in_unit(k, absolute) == Fraction(29315, 100)
    assert u.in_unit(k, difference) == 10
    assert u.in_unit(f, difference) == 18
    shifted = u.add_quantity(absolute, difference)
    assert u.in_unit(c, shifted) == 30
    shifted.close()
    absoluteTen = u.quantity(k, 10)
    assert absoluteTen != difference
    absoluteTen.close()
    try:
        u.add_quantity(absolute, absolute)
    except hmath.HMathError as error:
        assert error.math_error.kind == MathErrorKind.DOMAIN_ERROR
        assert error.math_error.message == "cannot add absolute temperatures"
    else:
        raise AssertionError("absolute-temperature addition changed")
    absolute.close()
    difference.close()
prefixes = u.si_prefixes()
assert (
    len(prefixes) == 24
    and prefixes[0].name == "quetta"
    and prefixes[-1].name == "quecto"
)
assert [p.exponent for p in prefixes] == [
    30,
    27,
    24,
    21,
    18,
    15,
    12,
    9,
    6,
    3,
    2,
    1,
    -1,
    -2,
    -3,
    -6,
    -9,
    -12,
    -15,
    -18,
    -21,
    -24,
    -27,
    -30,
]
for prefix in prefixes:
    prefix.close()
with u.SIPrefix("custom\0name", "µ\ud800", -3) as prefix:
    assert (
        prefix.name == "custom\0name"
        and prefix.symbol == "µ\ud800"
        and prefix.exponent == -3
    )
    with u.metre() as metre:
        derived = u.prefixed(prefix, metre)
assert derived.name == "µ\ud800m" and derived.scale == Fraction(1, 1000)
derived.close()
print(
    "Units exact exponents/scalars, NUL/Unicode/surrogates, affine semantics and owner lifetimes passed"
)
