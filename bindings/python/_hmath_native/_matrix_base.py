# SPDX-License-Identifier: MPL-2.0
"""Direct typed bindings for HMath.Matrix, Matrix.LU and Matrix.QR.

Constructors and operations preserve original Maybe (None) / Either (exception)
conventions. Objects are immutable, own independent references, and pin the
Haskell runtime until close(). There are no implicit dtype conversions.
"""

import ctypes as C
import threading
from contextlib import ExitStack

from ._numeric import _int


def _function(name, result, *types):
    import hmath

    return C.CFUNCTYPE(result, *types)((name, hmath._lib))


class _Owned:
    @classmethod
    def _adopt(cls, dtype, kind):
        result = object.__new__(cls)
        result._ptr, result._dtype, result._kind = C.c_void_p(), dtype, kind
        result._lock = threading.RLock()
        return result

    def close(self):
        with self._lock:
            if self._ptr:
                _function("hmath_dense_release", None, C.c_void_p)(self._ptr)
                self._ptr = C.c_void_p()

    def __enter__(self):
        with self._lock:
            if not self._ptr:
                raise ValueError("dense object is closed")
        return self

    def __exit__(self, *_):
        self.close()

    def __del__(self):
        if getattr(self, "_ptr", None):
            self.close()

    @property
    def dtype(self):
        return self._dtype


class Matrix(_Owned):
    """Immutable dense Matrix; create with from_list[_checked] and an explicit dtype."""

    def to_list(self):
        return to_list(self)

    @property
    def shape(self):
        return shape(self)


class LU(_Owned):
    """Original immutable LU factors; create with lu_decompose."""


class QR(_Owned):
    """Original immutable column-pivoted QR factors; create with qr_decompose."""


def _copy_values(obj, indices=False):
    import hmath

    count = C.c_size_t()
    hmath._check(
        _function(
            "hmath_dense_count", C.c_int, C.c_void_p, C.c_void_p, C.POINTER(C.c_size_t)
        )(None, obj._ptr, C.byref(count))
    )
    scalar = (
        C.c_ssize_t if indices else C.c_float if obj._dtype == "float32" else C.c_double
    )
    values = (scalar * count.value)()
    symbol = (
        "hmath_dense_indices_copy"
        if indices
        else "hmath_dense_values_f" + ("32" if obj._dtype == "float32" else "64")
    )
    hmath._check(
        _function(
            symbol, C.c_int, C.c_void_p, C.c_void_p, C.POINTER(scalar), C.c_size_t
        )(None, obj._ptr, values, count.value)
    )
    return list(values)


def to_list(matrix):
    """HMath.Matrix.toList, in logical row-major order."""
    if not isinstance(matrix, Matrix):
        raise TypeError("expected Matrix")
    from . import _matrix_value
    from ._value import Value

    if isinstance(matrix, Value):
        return _matrix_value.to_list(matrix)
    with matrix._lock:
        if not matrix._ptr:
            raise ValueError("dense object is closed")
        return _copy_values(matrix)


def shape(matrix):
    """HMath.Matrix.shape; zero dimensions retain their original shape."""
    import hmath

    if not isinstance(matrix, Matrix):
        raise TypeError("expected Matrix")
    from . import _matrix_value
    from ._value import Value

    if isinstance(matrix, Value):
        return _matrix_value.shape(matrix)
    rows, columns = C.c_ssize_t(), C.c_ssize_t()
    with matrix._lock:
        if not matrix._ptr:
            raise ValueError("dense object is closed")
        hmath._check(
            _function(
                "hmath_dense_shape",
                C.c_int,
                C.c_void_p,
                C.c_void_p,
                C.POINTER(C.c_ssize_t),
                C.POINTER(C.c_ssize_t),
            )(None, matrix._ptr, C.byref(rows), C.byref(columns))
        )
    return rows.value, columns.value


def _invoke(stem, kinds, result_kind, mode, arguments, dtype=None):
    import hmath

    objects = [value for kind, value in zip(kinds, arguments) if kind in "mlq"]
    for obj in objects:
        if not isinstance(obj, _Owned):
            raise TypeError("expected a dense HMath object")
    if objects:
        dtype = objects[0].dtype
    if dtype is None:
        dtype = "float64"
    from . import _matrix_value
    from ._value import Value

    if dtype not in ("float32", "float64") or any(
        isinstance(obj, Value) for obj in objects
    ):
        return _matrix_value.invoke(stem, kinds, arguments, dtype)
    real = C.c_float if dtype == "float32" else C.c_double
    types, values = [C.c_void_p], [None]
    for kind, argument in zip(kinds, arguments):
        if kind in "mlq":
            if not isinstance(argument, {"m": Matrix, "l": LU, "q": QR}[kind]):
                raise TypeError("dense object kind mismatch")
            if argument._dtype != dtype:
                raise TypeError("dense operands must have the same dtype")
            types.append(C.c_void_p)
            values.append(argument._ptr)
        elif kind == "i":
            types.append(C.c_ssize_t)
            values.append(_int(argument))
        elif kind == "f":
            types.append(real)
            values.append(argument)
        elif kind == "v":
            argument = tuple(argument)
            array = (real * len(argument))(*argument)
            types.extend([C.POINTER(real), C.c_size_t])
            values.extend([array, len(argument)])
    owner = None
    if result_kind in "mlqvp":
        owner = {"m": Matrix, "l": LU, "q": QR, "v": _Owned, "p": _Owned}[
            result_kind
        ]._adopt(dtype, result_kind)
        output = owner._ptr
    else:
        output = (C.c_ssize_t if result_kind == "i" else real)()
    types.append(C.POINTER(type(output)))
    values.append(C.byref(output))
    found = C.c_int()
    if mode == "maybe" and result_kind == "f":
        types.append(C.POINTER(C.c_int))
        values.append(C.byref(found))
    function = _function(
        stem + ("_f32" if dtype == "float32" else "_f64"), C.c_int, *types
    )
    hmath.initialize()
    with ExitStack() as locks:
        for obj in sorted({id(obj): obj for obj in objects}.values(), key=id):
            locks.enter_context(obj._lock)
            if not obj._ptr:
                raise ValueError("dense object is closed")
        # Re-read pointers under their locks; close() may have replaced one
        # while Python was constructing the argument buffers.
        cursor = 1
        for kind, argument in zip(kinds, arguments):
            if kind in "mlq":
                values[cursor] = argument._ptr
            cursor += 2 if kind == "v" else 1
        hmath._check(function(*values))
    if owner is not None:
        if not owner._ptr:
            return None
        if result_kind in "vp":
            try:
                return _copy_values(owner, indices=result_kind == "p")
            finally:
                owner.close()
        return owner
    return None if mode == "maybe" and not found.value else output.value


# Register the lossless Dense Value decoder after legacy owner definitions.
from . import _matrix_value as _matrix_value  # noqa: PLC0414
