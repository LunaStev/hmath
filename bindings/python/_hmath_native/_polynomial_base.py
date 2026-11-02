# SPDX-License-Identifier: MPL-2.0
"""Lifetime, dtype and callback adapters; mathematics stays in Haskell."""

import ctypes as C

from . import _value as V
from ._math_error import Wire, fill
from ._numeric import _int


class Polynomial(V.Value):
    """Immutable ascending polynomial. Source exact-zero normalization applies."""

    def __init__(self, coefficients, *, dtype="float64"):
        result = _construct("hmath_polynomial_polynomial", coefficients, dtype)
        self._ptr, self._lock, self._owners = result._ptr, result._lock, result._owners
        result._ptr, result._owners = C.c_void_p(), ()

    @property
    def coefficients(self):
        return _call("hmath_polynomial_coefficients", self)

    @property
    def degree(self):
        return _call("hmath_polynomial_polynomial_degree", self)

    def __eq__(self, other):
        if not isinstance(other, Polynomial):
            return NotImplemented
        return _call("hmath_polynomial_polynomial_equal", self, other)

    __hash__ = None


class PowerSeries(V.Value):
    """Immutable finite coefficient jet; trailing zeros and source order remain."""

    def __init__(self, coefficients, *, dtype="float64"):
        result = _construct("hmath_polynomial_power_series", coefficients, dtype)
        self._ptr, self._lock, self._owners = result._ptr, result._lock, result._owners
        result._ptr, result._owners = C.c_void_p(), ()

    @property
    def coefficients(self):
        return _call("hmath_polynomial_series_coefficients", self)

    def __eq__(self, other):
        if not isinstance(other, PowerSeries):
            return NotImplemented
        return _call("hmath_polynomial_series_equal", self, other)

    __hash__ = None


class RationalFunction(V.Value):
    """Reduced exact Rational numerator/denominator from the source constructor."""

    def __init__(self, numerator, denominator):
        result = _call("hmath_polynomial_rational_function", numerator, denominator)
        self._ptr, self._lock, self._owners = result._ptr, result._lock, result._owners
        result._ptr, result._owners = C.c_void_p(), ()

    def __eq__(self, other):
        if not isinstance(other, RationalFunction):
            return NotImplemented
        return _call("hmath_polynomial_rational_function_equal", self, other)

    __hash__ = None


V.register(6, Polynomial)
V.register(7, PowerSeries)
V.register(8, RationalFunction)


def _call(symbol, *arguments):
    return V.decode(V.invoke(symbol, *arguments))


def _prototype(dtype):
    return dtype.clone() if isinstance(dtype, V.Value) else V.scalar(0, dtype)


def _typed_one(value, dtype):
    if isinstance(value, V.Value):
        return value.clone()
    if isinstance(dtype, V.Value):
        raise TypeError("structured coefficients require explicit typed scalar Values")
    return V.scalar(value, dtype)


def _construct(symbol, coefficients, dtype):
    values = []
    try:
        for value in coefficients:
            values.append(_typed_one(value, dtype))
        with _prototype(dtype) as prototype:
            return _call(symbol, prototype, values)
    finally:
        for value in values:
            value.close()


def _prototype_call(symbol, dtype, *arguments):
    owners = []
    encoded = []
    try:
        for argument in arguments:
            if isinstance(argument, (list, tuple)):
                rows = []
                for row in argument:
                    pair = []
                    for item in row:
                        value = _typed_one(item, dtype)
                        owners.append(value)
                        pair.append(value)
                    rows.append(tuple(pair))
                encoded.append(rows)
            else:
                encoded.append(argument)
        with _prototype(dtype) as prototype:
            return _call(symbol, prototype, *encoded)
    finally:
        for owner in owners:
            owner.close()


def _typed_call(symbol, owner_index, scalar_indices, *arguments):
    converted = list(arguments)
    owners = []
    try:
        dtype = arguments[owner_index].dtype
        for index in scalar_indices:
            value = _typed_one(arguments[index], dtype)
            owners.append(value)
            converted[index] = value
        return _call(symbol, *converted)
    finally:
        for owner in owners:
            owner.close()


_CALLBACK = C.CFUNCTYPE(
    C.c_int, C.c_double, C.POINTER(C.c_double), C.c_void_p, C.POINTER(Wire)
)


def chebyshev_approximation(degree, function):
    """Original synchronous degree+1-node Chebyshev approximation on [-1,1]."""
    import hmath

    if not callable(function):
        raise TypeError("function must be callable")
    degree = _int(degree)
    errors = []
    payload = []

    @_CALLBACK
    def callback(x, out, _userdata, wire):
        try:
            out[0] = function(x)
            return 0
        except BaseException as error:  # noqa: BLE001 - no exception may escape a ctypes callback
            if fill(wire, error, payload):
                return 11
            errors.append(error)
            try:
                description = str(error)
            except BaseException:  # noqa: BLE001 - exception formatting must not escape ctypes
                description = type(error).__name__
            message = description.encode("utf-8", "surrogatepass")
            buffer = C.create_string_buffer(message)
            payload.append(buffer)
            wire.contents.message = C.cast(buffer, C.c_void_p)
            wire.contents.message_length = len(message)
            return 9

    result = V.Value._adopt()
    call = V.api(
        "hmath_polynomial_chebyshev_approximation",
        C.c_int,
        C.c_void_p,
        C.c_ssize_t,
        _CALLBACK,
        C.c_void_p,
        C.POINTER(C.c_void_p),
    )
    hmath.initialize()
    status = call(None, degree, callback, None, C.byref(result._ptr))
    if errors:
        result.close()
        raise errors[0]
    hmath._check(status)
    return V.decode(result)
