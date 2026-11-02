# SPDX-License-Identifier: MPL-2.0
"""Owned, lossless scalar/container transport for structured HMath APIs.

This module implements representation and lifetime only. Domain arithmetic lives
in the original Haskell modules. Opaque domains register their Python owner or
decoder rather than implementing an alternate numerical algorithm.
"""

import ctypes as C
import numbers
import operator
import sys
import threading
from contextlib import ExitStack
from fractions import Fraction

from ._numeric import _decimal, _integer

DTYPES = {
    "float64": 0,
    "float32": 1,
    "integer": 2,
    "rational": 3,
    "complex128": 4,
    "complex64": 5,
    "int8": 6,
    "int16": 7,
    "int32": 8,
    "int64": 9,
    "uint8": 10,
    "uint16": 11,
    "uint32": 12,
    "uint64": 13,
    "intp": 14,
    "uintp": 15,
}
DTYPE_NAMES = {value: key for key, value in DTYPES.items()}
_REGISTRY = {}
_SCALAR_REGISTRY = {}
_ENCODERS = []


def api(name, result, *types):
    import hmath

    return C.CFUNCTYPE(result, *types)((name, hmath._lib))


def register(kind, owner_or_decoder):
    """Register an opaque Value subclass or a consuming Value decoder."""
    if kind < 6 or kind == 10:
        raise ValueError("kind is reserved for common value transport")
    if kind in _REGISTRY and _REGISTRY[kind] is not owner_or_decoder:
        raise ValueError("opaque value kind already registered")
    _REGISTRY[kind] = owner_or_decoder


def register_scalar(dtype, owner_or_decoder):
    """Register a consuming decoder/owner for a structured scalar dtype."""
    if dtype in DTYPE_NAMES:
        raise ValueError("primitive scalar dtype already has a decoder")
    if dtype in _SCALAR_REGISTRY and _SCALAR_REGISTRY[dtype] is not owner_or_decoder:
        raise ValueError("structured scalar dtype already registered")
    _SCALAR_REGISTRY[dtype] = owner_or_decoder


def register_encoder(type_, encoder):
    """Register a foreign native owner (e.g. Matrix) without import cycles."""
    if any(existing is type_ for existing, _ in _ENCODERS):
        raise ValueError("value encoder already registered")
    _ENCODERS.append((type_, encoder))


class Value:
    @classmethod
    def _adopt(cls, pointer=None, owners=()):
        result = object.__new__(cls)
        result._ptr = (
            C.c_void_p()
            if pointer is None
            else pointer
            if isinstance(pointer, C.c_void_p)
            else C.c_void_p(pointer)
        )
        result._lock = threading.RLock()
        result._owners = tuple(owners)
        return result

    @property
    def info(self):
        import hmath

        kind, dtype, count = C.c_int(), C.c_int(), C.c_size_t()
        with self._lock:
            if not self._ptr:
                raise ValueError("value is closed")
            hmath._check(
                api(
                    "hmath_value_info",
                    C.c_int,
                    C.c_void_p,
                    C.POINTER(C.c_int),
                    C.POINTER(C.c_int),
                    C.POINTER(C.c_size_t),
                )(self._ptr, C.byref(kind), C.byref(dtype), C.byref(count))
            )
        return kind.value, dtype.value, count.value

    @property
    def dtype(self):
        return DTYPE_NAMES.get(self.info[1])

    def clone(self):
        result = Value._adopt()
        with self._lock:
            if not self._ptr:
                raise ValueError("value is closed")
            api("hmath_value_retain", None, C.c_void_p)(self._ptr)
            result._ptr = C.c_void_p(self._ptr.value)
            result._owners = self._owners
        return result

    def close(self):
        with self._lock:
            if self._ptr:
                api("hmath_value_release", None, C.c_void_p)(self._ptr)
                self._ptr = C.c_void_p()
                self._owners = ()

    def __enter__(self):
        with self._lock:
            if not self._ptr:
                raise ValueError("value is closed")
        return self

    def __exit__(self, *_):
        self.close()

    def __del__(self, _sys=sys):
        # Python no longer supports module imports once interpreter teardown
        # clears meta_path; the process reclaims remaining native owners.
        if _sys.meta_path is None:
            return
        if getattr(self, "_ptr", None):
            self.close()

    def decode(self):
        """Consume this reference into a scalar/container/domain owner."""
        return decode(self)

    def item(self, index):
        import hmath

        index = operator.index(index)
        if (
            not -(1 << (C.sizeof(C.c_ssize_t) * 8 - 1))
            <= index
            < (1 << (C.sizeof(C.c_ssize_t) * 8 - 1))
        ):
            raise OverflowError("index does not fit Haskell Int")
        result = Value._adopt()
        with self._lock:
            if not self._ptr:
                raise ValueError("value is closed")
            result._owners = self._owners
            hmath._check(
                api(
                    "hmath_value_item",
                    C.c_int,
                    C.c_void_p,
                    C.c_void_p,
                    C.c_ssize_t,
                    C.POINTER(C.c_void_p),
                )(None, self._ptr, index, C.byref(result._ptr))
            )
        return result


def borrow(pointer, owners=()):
    """Acquire an owned reference from a C callback's borrowed Value pointer."""
    if not pointer:
        raise ValueError("cannot retain a NULL borrowed value")
    result = Value._adopt(pointer, owners)
    api("hmath_value_retain", None, C.c_void_p)(result._ptr)
    return result


def _create(symbol, types=(), arguments=(), owners=()):
    import hmath

    result = Value._adopt(owners=owners)
    function = api(symbol, C.c_int, C.c_void_p, *types, C.POINTER(C.c_void_p))
    hmath.initialize()
    hmath._check(function(None, *arguments, C.byref(result._ptr)))
    return result


def scalar(value, dtype=None):
    """Encode one explicit standard coefficient without an FP intermediary."""
    if dtype is None:
        native = getattr(getattr(value, "dtype", None), "name", None)
        if native is not None:
            if native not in DTYPES:
                raise TypeError("unsupported native scalar dtype")
            dtype = native
        elif isinstance(value, Fraction):
            dtype = "rational"
        elif isinstance(value, numbers.Integral):
            dtype = "integer"
        elif isinstance(value, numbers.Real):
            dtype = "float64"
        elif isinstance(value, numbers.Complex):
            dtype = "complex128"
        else:
            raise TypeError("unsupported scalar representation")
    if dtype not in DTYPES:
        raise ValueError("unsupported standard coefficient dtype")
    if dtype in ("float32", "float64"):
        real = C.c_float if dtype == "float32" else C.c_double
        return _create(
            "hmath_value_f32" if real is C.c_float else "hmath_value_f64",
            [real],
            [value],
        )
    if dtype in ("complex64", "complex128"):
        value = complex(value)
        real = C.c_float if dtype == "complex64" else C.c_double
        return _create(
            "hmath_value_complex_f32"
            if real is C.c_float
            else "hmath_value_complex_f64",
            [real, real],
            [value.real, value.imag],
        )
    if dtype == "rational":
        value = Fraction(value)
        return _create(
            "hmath_value_rational",
            [C.c_char_p, C.c_char_p],
            [_decimal(value.numerator), _decimal(value.denominator)],
        )
    return _create(
        "hmath_value_integral", [C.c_int, C.c_char_p], [DTYPES[dtype], _decimal(value)]
    )


def encode(value):
    """Encode Python's standard lossless values; typed fields can call scalar()."""
    if isinstance(value, Value):
        return value.clone()
    for type_, encoder in _ENCODERS:
        if isinstance(value, type_):
            return encoder(value)
    if value is None:
        return _create("hmath_value_none")
    if isinstance(value, bool):
        return _create("hmath_value_boolean", [C.c_int], [value])
    if isinstance(value, (numbers.Number, Fraction)):
        return scalar(value)
    if isinstance(value, str):
        points = (C.c_uint32 * len(value))(*(ord(character) for character in value))
        return _create(
            "hmath_value_text",
            [C.POINTER(C.c_uint32), C.c_size_t],
            [points, len(value)],
        )
    if isinstance(value, (list, tuple)):
        items = []
        try:
            for item in value:
                items.append(encode(item))
            pointers = (C.c_void_p * len(items))(*(item._ptr for item in items))
            owners = tuple(owner for item in items for owner in item._owners)
            return _create(
                "hmath_value_tuple" if isinstance(value, tuple) else "hmath_value_list",
                [C.POINTER(C.c_void_p), C.c_size_t],
                [pointers, len(items)],
                owners,
            )
        finally:
            for item in items:
                item.close()
    raise TypeError(f"unsupported value representation: {type(value).__name__}")


def invoke(symbol, *arguments, owners=()):
    """Call a named ctx-first, fixed Value*-arguments, Value**-out adapter.

    All temporary inputs are closed. Callback-owner snapshots propagate to the
    result so explicitly closing an input owner cannot invalidate a derived
    object's borrowed callback/userdata references.
    """
    import hmath

    values = []
    try:
        for argument in arguments:
            values.append(encode(argument))
        result = Value._adopt(
            owners=tuple(owners)
            + tuple(owner for value in values for owner in value._owners)
        )
        function = api(
            symbol,
            C.c_int,
            C.c_void_p,
            *([C.c_void_p] * len(values)),
            C.POINTER(C.c_void_p),
        )
        hmath.initialize()
        with ExitStack() as locks:
            for value in sorted(values, key=id):
                locks.enter_context(value._lock)
                if not value._ptr:
                    raise ValueError("value is closed")
            hmath._check(
                function(None, *(value._ptr for value in values), C.byref(result._ptr))
            )
        return result
    finally:
        for value in values:
            value.close()


def decode(value):
    """Consume an owned Value, preserving opaque owners and exact scalar data."""
    import hmath

    if not isinstance(value, Value):
        raise TypeError("decode requires an owned Value")
    kind, dtype, count = value.info
    if (kind >= 6 and kind != 10) or (kind == 1 and dtype in _SCALAR_REGISTRY):
        registered = _SCALAR_REGISTRY.get(dtype) if kind == 1 else _REGISTRY.get(kind)
        if registered is None:
            return value
        if isinstance(registered, type) and issubclass(registered, Value):
            with value._lock:
                result = registered._adopt(value._ptr, value._owners)
                value._ptr, value._owners = C.c_void_p(), ()
                return result
        return registered(value)
    try:
        with value._lock:
            if not value._ptr:
                raise ValueError("value is closed")
            if kind == 0:
                return None
            if kind == 1:
                if dtype in (0, 1, 4, 5):
                    real = C.c_float if dtype in (1, 5) else C.c_double
                    first, second = real(), real()
                    hmath._check(
                        api(
                            "hmath_value_get_f32"
                            if real is C.c_float
                            else "hmath_value_get_f64",
                            C.c_int,
                            C.c_void_p,
                            C.POINTER(real),
                            C.POINTER(real),
                        )(value._ptr, C.byref(first), C.byref(second))
                    )
                    return (
                        complex(first.value, second.value)
                        if dtype in (4, 5)
                        else first.value
                    )
                if dtype in (2, 3) or 6 <= dtype <= 15:
                    first, second = C.c_void_p(), C.c_void_p()
                    free = api("hmath_value_string_free", None, C.c_void_p)
                    try:
                        hmath._check(
                            api(
                                "hmath_value_get_exact",
                                C.c_int,
                                C.c_void_p,
                                C.POINTER(C.c_void_p),
                                C.POINTER(C.c_void_p),
                            )(value._ptr, C.byref(first), C.byref(second))
                        )
                        numerator, denominator = (
                            _integer(C.string_at(first)),
                            _integer(C.string_at(second)),
                        )
                        return (
                            Fraction(numerator, denominator)
                            if dtype == 3
                            else numerator
                        )
                    finally:
                        free(first)
                        free(second)
                raise TypeError("coefficient representation has no Python decoder")
            if kind in (2, 3):
                result = C.c_ssize_t() if kind == 2 else C.c_int()
                hmath._check(
                    api(
                        "hmath_value_get_index"
                        if kind == 2
                        else "hmath_value_get_boolean",
                        C.c_int,
                        C.c_void_p,
                        C.POINTER(type(result)),
                    )(value._ptr, C.byref(result))
                )
                return bool(result.value) if kind == 3 else result.value
            if kind in (4, 5):
                result = [decode(value.item(index)) for index in range(count)]
                return tuple(result) if kind == 5 else result
            if kind == 10:
                points = (C.c_uint32 * count)()
                hmath._check(
                    api(
                        "hmath_value_get_text",
                        C.c_int,
                        C.c_void_p,
                        C.POINTER(C.c_uint32),
                        C.c_size_t,
                    )(value._ptr, points, count)
                )
                return "".join(chr(point) for point in points)
            raise TypeError("unknown value kind")
    finally:
        value.close()
