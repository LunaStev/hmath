# SPDX-License-Identifier: MPL-2.0
"""Original Buffer owners, scoped borrows and exact Storable transport."""

import operator

from . import _value as V
from ._foundation_base import FoundationValue, register
from ._numerical_base import _invoke


def _call(name, arguments, callback=None):
    specs = [["Value"] for _ in arguments]
    if callback is not None:
        specs[callback] = ["function", ["Value"], ["Value"]]
    return _invoke("hmath_buffer_" + name, specs, arguments)


def _typed(value, dtype=None):
    if isinstance(value, V.Value):
        kind, code, count = value.info
        actual = 16 if kind == 3 else 17 if kind == 10 and count == 1 else code
        expected = {"bool": 16, "char": 17}.get(dtype, V.DTYPES.get(dtype, dtype))
        if dtype is not None and actual != expected:
            raise TypeError("explicit storage type differs from the actual scalar")
        return value.clone()
    if dtype == 16 or dtype == "bool":
        if not isinstance(value, bool):
            raise TypeError("Bool storage requires bool")
        return V.encode(value)
    if dtype == 17 or dtype == "char":
        if not isinstance(value, str) or len(value) != 1:
            raise TypeError("Char storage requires one character")
        return V.encode(value)
    if dtype is None:
        if isinstance(value, (bool, str)):
            return V.encode(value)
        if isinstance(value, int):
            dtype = "intp"
    return V.scalar(value, dtype)


def _boxed(name, values, dtype=None):
    if dtype is None:
        return _call(name, [list(values)])
    owners = []
    try:
        owners = [_typed(item, dtype) for item in values]
        return _call(name, [owners])
    finally:
        for owner in owners:
            owner.close()


def _initialize(owner, result):
    owner._ptr, owner._lock, owner._owners = result._ptr, result._lock, result._owners
    import ctypes as C

    result._ptr, result._owners = C.c_void_p(), ()


class Boxed(FoundationValue):
    """Original immutable Boxed a. dtype optionally selects scalar element type."""

    _source_type = "HMath.API.Buffer.Boxed"

    def __init__(self, values, *, strict=False, dtype=None):
        _initialize(
            self, _boxed("strict_boxed" if strict else "lazy_boxed", values, dtype)
        )

    @property
    def values(self):
        return _call("boxed_values", [self])

    def __len__(self):
        return _call("boxed_length", [self])

    def map(self, function):
        return _call("map_strict", [function, self], 0)


class UnboxedDouble(FoundationValue):
    """Actual immutable unboxed Double array, including NaN and infinity."""

    _source_type = "HMath.API.Buffer.UnboxedDouble"

    def __init__(self, values):
        _initialize(self, _call("unboxed_double", [[float(x) for x in values]]))

    @property
    def values(self):
        return _call("unboxed_values", [self])


class STBuffer(FoundationValue):
    """Mutable original ST region: valid only in its run_st_buffer callback."""

    _source_type = "HMath.API.Buffer.STBuffer"

    @property
    def active(self):
        return _call("st_active", [self])

    def read(self, index):
        return _call("read_st_buffer", [self, operator.index(index)])

    def write(self, index, value):
        return _call("write_st_buffer", [self, operator.index(index), value])

    def freeze(self):
        return _call("freeze_st_buffer", [self])

    def thaw(self, boxed):
        return _call("thaw_st_buffer", [self, boxed])


class IOBuffer(FoundationValue):
    """Actual pinned, synchronized Storable IO buffer. Freeze and thaw copy."""

    _source_type = "HMath.API.Buffer.IOBuffer"

    def __init__(self, count, initial, *, dtype=None):
        _initialize(self, _new_io(count, initial, dtype))

    @property
    def dtype(self):
        code = self.info[1]
        return {16: "bool", 17: "char"}.get(code, V.DTYPE_NAMES.get(code))

    def __len__(self):
        return _call("io_buffer_length", [self])

    @property
    def layout(self):
        """Actual (dtype, Storable size, alignment, element count)."""
        return _call("storage_info", [self])

    def read(self, index):
        return _call("read_io_buffer", [self, operator.index(index)])

    def write(self, index, value):
        owner = _typed(value, self.dtype)
        try:
            return _call("write_io_buffer", [self, operator.index(index), owner])
        finally:
            owner.close()

    def freeze(self):
        return _call("freeze_io_buffer", [self])

    def with_pointer(self, callback):
        return _call("with_io_buffer", [self, callback], 1)


class BorrowedPointer(FoundationValue):
    """Checked view of the actual Ptr a, valid only in with_pointer's callback.

    The raw address must never be retained. Do not reenter locking operations on
    the same IOBuffer while borrowed. Reads/writes through this view are checked
    and use the original Storable instance, including Bool/Char ABI layouts.
    """

    _source_type = "HMath.API.Buffer.BorrowedPointer"

    @property
    def dtype(self):
        code = self.info[1]
        return {16: "bool", 17: "char"}.get(code, V.DTYPE_NAMES.get(code))

    @property
    def active(self):
        return _call("pointer_active", [self])

    @property
    def layout(self):
        return _call("pointer_info", [self])

    @property
    def address(self):
        return _call("pointer_address", [self])

    def read(self, index):
        return _call("pointer_read", [self, operator.index(index)])

    def write(self, index, value):
        owner = _typed(value, self.dtype)
        try:
            return _call("pointer_write", [self, operator.index(index), owner])
        finally:
            owner.close()


for _owner in (Boxed, UnboxedDouble, STBuffer, IOBuffer, BorrowedPointer):
    register(_owner._source_type, _owner)


def _new_io(count, initial, dtype=None):
    owner = _typed(initial, dtype)
    try:
        return _call("new_io_buffer", [operator.index(count), owner])
    finally:
        owner.close()


def _thaw_io(boxed, dtype=None, prototype=None):
    if dtype is None:
        return _call("thaw_io_buffer", [prototype, boxed])
    if prototype is not None:
        raise TypeError("supply dtype or prototype, not both")
    values = boxed.values
    owners = []
    typed_box = None
    exemplar = None
    try:
        owners = [_typed(item, dtype) for item in values]
        typed_box = _call("lazy_boxed", [owners])
        exemplar = (
            owners[0]
            if owners
            else _typed(
                "\0"
                if dtype in (17, "char")
                else False
                if dtype in (16, "bool")
                else 0,
                dtype,
            )
        )
        return _call("thaw_io_buffer", [exemplar, typed_box])
    finally:
        if exemplar is not None and not owners:
            exemplar.close()
        if typed_box is not None:
            typed_box.close()
        for owner in owners:
            owner.close()
