# SPDX-License-Identifier: MPL-2.0
"""Lossless Matrix coefficient/ownership bridge to the original operations."""

import ctypes as C

from . import _value as V
from ._matrix_base import Matrix


class MatrixValue(V.Value, Matrix):
    """A Matrix with a standard typed element and shared Value owner."""

    @property
    def dtype(self):
        return {16: "bool", 17: "string", 18: "exact"}.get(
            self.info[1], V.DTYPE_NAMES.get(self.info[1])
        )


def _export(matrix):
    import hmath

    result = V.Value._adopt()
    with matrix._lock:
        if not matrix._ptr:
            raise ValueError("dense object is closed")
        hmath._check(
            V.api(
                "hmath_dense_to_value",
                C.c_int,
                C.c_void_p,
                C.c_void_p,
                C.POINTER(C.c_void_p),
            )(None, matrix._ptr, C.byref(result._ptr))
        )
    return result


def _decode(value):
    import hmath

    _, dtype, _ = value.info
    if dtype in (0, 1):
        result = Matrix._adopt("float32" if dtype == 1 else "float64", "m")
        try:
            with value._lock:
                hmath._check(
                    V.api(
                        "hmath_dense_from_value",
                        C.c_int,
                        C.c_void_p,
                        C.c_void_p,
                        C.POINTER(C.c_void_p),
                    )(None, value._ptr, C.byref(result._ptr))
                )
            return result
        finally:
            value.close()
    with value._lock:
        result = MatrixValue._adopt(value._ptr, value._owners)
        value._ptr, value._owners = C.c_void_p(), ()
        return result


V.register(9, _decode)
V.register_encoder(Matrix, _export)


def shape(matrix):
    return V.decode(V.invoke("hmath_matrix_value_shape", matrix))


def to_list(matrix):
    return V.decode(V.invoke("hmath_matrix_value_to_list", matrix))


def _prototype(dtype):
    if isinstance(dtype, V.Value):
        return dtype.clone()
    if dtype == "bool":
        return V.encode(False)
    if dtype == "string":
        return V.encode("")
    return V.scalar(0, dtype)


def invoke(stem, kinds, arguments, dtype):
    objects = [value for kind, value in zip(kinds, arguments) if kind in "mlq"]
    if any(kind in "lq" for kind in kinds) or stem.startswith(
        ("hmath_dense_lu_", "hmath_dense_qr_")
    ):
        raise TypeError("the original LU/QR operations require Float or Double")
    if objects:
        dtype = objects[0].dtype
    if any(not isinstance(value, Matrix) for value in objects):
        raise TypeError("expected Matrix")
    if any(value.dtype != dtype for value in objects):
        raise TypeError("Matrix coefficient types differ")
    converted, owners = [], []
    try:
        if not objects:
            prototype = _prototype(dtype)
            owners.append(prototype)
            converted.append(prototype)
        for kind, value in zip(kinds, arguments):
            if kind == "f":
                scalar = (
                    value.clone()
                    if isinstance(value, V.Value)
                    else V.encode(value)
                    if dtype in ("bool", "string")
                    else V.scalar(value, dtype)
                )
                owners.append(scalar)
                converted.append(scalar)
            elif kind == "v":
                values = []
                for item in value:
                    scalar = (
                        item.clone()
                        if isinstance(item, V.Value)
                        else V.encode(item)
                        if dtype in ("bool", "string")
                        else V.scalar(item, dtype)
                    )
                    owners.append(scalar)
                    values.append(scalar)
                converted.append(values)
            else:
                converted.append(value)
        symbol = "hmath_matrix_value_" + stem.removeprefix("hmath_dense_")
        return V.decode(V.invoke(symbol, *converted))
    finally:
        for owner in owners:
            owner.close()
