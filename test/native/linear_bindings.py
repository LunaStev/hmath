# SPDX-License-Identifier: MPL-2.0
"""Exact/complex contracts, typed callbacks and direct original Backend policy."""

import sys
from fractions import Fraction
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "bindings/python"))
import hmath
from _hmath_native import backend as b
from _hmath_native import matrix as m
from _hmath_native import matrix_advanced as a
from _hmath_native import sparse as s
from _hmath_native import vector as v
from _hmath_native._math_error import MathError, MathErrorKind

with v.Vector([10**6000 + 1, 2], dtype="integer") as x:
    assert v.vector_dot(x, x) == (10**6000 + 1) ** 2 + 4
with s.sparse(
    2, 2, [(0, 0, Fraction(1, 3)), (0, 0, Fraction(1, 7)), (1, 1, 2)], dtype="rational"
) as sparse:
    assert s.sparse_entries(sparse) == [(0, 0, Fraction(10, 21)), (1, 1, 2)]
    dense = s.sparse_to_dense(sparse)
assert dense.dtype == "rational" and dense.to_list() == [Fraction(10, 21), 0, 0, 2]
dense.close()
with s.sparse(
    2, 2, [(0, 0, complex(1, 2)), (1, 1, complex(3, -1))], dtype="complex64"
) as sparse:
    result = s.spmm(sparse, sparse)
assert s.sparse_entries(result) == [(0, 0, complex(-3, 4)), (1, 1, complex(8, -6))]
result.close()
with v.FixedVector(2, [1, 2], dtype="integer") as fixed:
    assert v.fixed_values(fixed) == [1, 2]
try:
    v.FixedVector(2, [1], dtype="integer")
except hmath.HMathError as error:
    assert error.math_error.kind == MathErrorKind.INVALID_ARGUMENT
else:
    raise AssertionError("KnownNat length mismatch changed")
calls = []
with a.generate_matrix(
    2, 3, lambda row, col: (calls.append((row, col)), row + col)[1], dtype="integer"
) as matrix:
    assert matrix.to_list() == [0, 1, 2, 1, 2, 3]
assert calls == [(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2)]
with (
    m.from_list_checked(1, 1, [16777216], dtype="float32") as left,
    m.from_list_checked(1, 1, [1], dtype="integer") as right,
):
    output = a.zip_matrix_with(lambda x, y: x + y, left, right, dtype="float32")
assert output.dtype == "float32" and output.to_list() == [16777216]
output.close()
message = "linear\0α🙂\ud800"


def original_error(*_):
    raise MathError(MathErrorKind.NON_CONVERGENCE, (7,), message)


try:
    a.generate_matrix(1, 1, original_error)
except hmath.HMathError as error:
    assert error.math_error.kind == MathErrorKind.NON_CONVERGENCE
    assert error.math_error.details == (7,) and error.math_error.message == message
else:
    raise AssertionError("pure callback original error swallowed")


class BrokenMessage(Exception):
    def __str__(self):
        raise ValueError("formatter failed")


sentinel = BrokenMessage()


def unexpected(*_):
    raise sentinel


try:
    a.generate_matrix(1, 1, unexpected)
except BrokenMessage as error:
    assert error is sentinel
else:
    raise AssertionError("callback exception was swallowed")
with (
    b.pure_backend() as backend,
    b.no_transpose() as no_transpose,
    m.from_list_checked(1, 1, [1.0]) as finite,
    m.from_list_checked(1, 1, [float("nan")]) as nonfinite,
):
    try:
        b.gemm(backend, no_transpose, no_transpose, 1.0, finite, finite, 0.0, nonfinite)
    except hmath.HMathError as error:
        assert error.math_error.kind == MathErrorKind.NON_FINITE_VECTOR_ENTRY
    else:
        raise AssertionError("original Backend must validate C even when beta is zero")
    lu = b.backend_lu(backend, finite)
    qr = b.backend_qr(backend, finite)
assert m.determinant_lu(lu) == 1 and m.qr_rank(qr) == 1
lu.close()
qr.close()
# A sparse format's public constructor fields remain accessible and exact.
with s.csr(
    2, 2, [0, 1, 2], [0, 1], [Fraction(1, 3), Fraction(2, 7)], dtype="rational"
) as fmt:
    assert fmt.parts == (
        "CSR",
        (2, 2, [0, 1, 2], [0, 1], [Fraction(1, 3), Fraction(2, 7)]),
    )
    sparse = s.from_format(fmt)
assert s.sparse_entries(sparse) == [(0, 0, Fraction(1, 3)), (1, 1, Fraction(2, 7))]
sparse.close()
print("Linear exact/complex/FixedVector/callback/Backend/LU-QR/format contracts passed")
