# SPDX-License-Identifier: MPL-2.0
"""Callbacks, coefficient fidelity and Polynomial/Matrix lifetime integration."""

import math
import sys
from fractions import Fraction
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "bindings/python"))
import hmath
from _hmath_native import matrix as m
from _hmath_native import polynomial as p
from _hmath_native._math_error import MathError, MathErrorKind


def must_fail(function, kind):
    try:
        function()
    except hmath.HMathError as error:
        assert error.math_error.kind == kind, error
        return error
    raise AssertionError("expected original MathError")


for dtype in ("float32", "float64", "integer", "rational", "complex64", "complex128"):
    source = p.polynomial([1, 2, 0, 0], dtype=dtype)
    assert source.degree == 1 and source.coefficients == [1, 2]
    assert source == p.polynomial([1, 2], dtype=dtype)
    zero = p.polynomial([], dtype=dtype)
    assert zero.degree is None and zero.coefficients == []
    series = p.power_series([1, 2, 0, 0], dtype=dtype)
    assert series.coefficients == [1, 2, 0, 0]
    assert series != p.power_series([1, 2], dtype=dtype)
    source.close()
    zero.close()
    series.close()
# Arbitrary precision never enters FP64, including generic Matrix arithmetic.
big = 10**6000 + 7
with p.polynomial([big, 1], dtype="integer") as source:
    assert p.evaluate_polynomial(source, 2) == big + 2
with p.polynomial([Fraction(1, 10**5000 + 1), 0, 1], dtype="rational") as source:
    companion = p.companion_matrix(source)
assert isinstance(companion, m.Matrix) and companion.dtype == "rational"
assert companion.to_list()[1] == -Fraction(1, 10**5000 + 1)
squared = m.multiply_checked(companion, companion)
companion.close()
assert squared.to_list() == [
    -Fraction(1, 10**5000 + 1),
    0,
    0,
    -Fraction(1, 10**5000 + 1),
]
squared.close()
# Float32 stays Float32: construction rounds before Horner arithmetic.
with p.polynomial([16777217, 1], dtype="float32") as source:
    assert p.evaluate_polynomial(source, 1) == 16777216
    companion = p.companion_matrix(source)
assert isinstance(companion, m.Matrix) and companion.dtype == "float32"
assert m.scale_matrix(1, companion).to_list() == companion.to_list()
companion.close()
# Source finite and callback exception policies.
calls = []
with p.chebyshev_approximation(3, lambda x: (calls.append(x), x * x)[1]) as result:
    assert len(calls) == 4 and result.dtype == "float64"
    assert math.isclose(p.evaluate_polynomial(result, 0.4), 0.16, abs_tol=1e-14)
must_fail(
    lambda: p.chebyshev_approximation(
        -1, lambda _x: (_ for _ in ()).throw(AssertionError("must not run"))
    ),
    MathErrorKind.DOMAIN_ERROR,
)
must_fail(
    lambda: p.chebyshev_approximation(2, lambda _x: float("nan")),
    MathErrorKind.NON_FINITE_RESULT,
)
message = "callback\0α🙂\ud800"


def original_error(_x):
    raise MathError(MathErrorKind.NON_CONVERGENCE, (17,), message)


error = must_fail(
    lambda: p.chebyshev_approximation(2, original_error), MathErrorKind.NON_CONVERGENCE
)
assert error.math_error.details == (17,) and error.math_error.message == message
sentinel = KeyboardInterrupt("callback sentinel")


def interrupt(_x):
    raise sentinel


try:
    p.chebyshev_approximation(2, interrupt)
except KeyboardInterrupt as error:
    assert error is sentinel
else:
    raise AssertionError("Python callback exception was swallowed")
# Unsupported original coefficient instances fail without precision-changing fallback.
with p.power_series([1, 2], dtype="complex128") as source:
    try:
        p.log_series(source)
    except hmath.HMathError as error:
        assert error.status == 10
    else:
        raise AssertionError("Complex lacks the original Ord instance")
with m.zero_matrix_checked(0, sys.maxsize, dtype="integer") as source:
    assert source.shape == (0, sys.maxsize)
    target = m.transpose_matrix(source)
    assert target.shape == (sys.maxsize, 0)
    target.close()
print("Polynomial coefficient/callback/Matrix ownership contracts passed")
