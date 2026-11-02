# SPDX-License-Identifier: MPL-2.0
"""Ownership/representation for the original Numeric and Constants operations."""

import ctypes as C
import numbers
import operator
from enum import IntEnum
from fractions import Fraction

from . import _value
from ._numeric import _decimal


class RoundingMode(IntEnum):
    NEAREST_EVEN = 0
    TOWARD_ZERO = 1
    TOWARD_POSITIVE = 2
    TOWARD_NEGATIVE = 3


class NumericException(IntEnum):
    INVALID_OPERATION = 0
    DIVISION_BY_ZERO = 1
    NUMERIC_OVERFLOW = 2
    NUMERIC_UNDERFLOW = 3
    INEXACT = 4


class IEEEClass(IntEnum):
    NOT_A_NUMBER = 0
    POSITIVE_INFINITY = 1
    NEGATIVE_INFINITY = 2
    POSITIVE_ZERO = 3
    NEGATIVE_ZERO = 4
    SUBNORMAL = 5
    NORMAL = 6


def _index(value, bits=None, unsigned=False):
    value = operator.index(value)
    bits = bits or C.sizeof(C.c_ssize_t) * 8
    low = 0 if unsigned else -(1 << (bits - 1))
    high = (1 << bits) - 1 if unsigned else (1 << (bits - 1)) - 1
    if not low <= value <= high:
        raise OverflowError("argument outside its native representation")
    return value


def _transfer(value):
    with value._lock:
        result = NumericValue._adopt(value._ptr, value._owners)
        value._ptr, value._owners = C.c_void_p(), ()
        return result


def number(value, dtype=None):
    """Box an exact standard coefficient; dtype follows common Value transport."""
    if isinstance(value, _value.Value):
        return _transfer(value.clone())
    return _transfer(_value.scalar(value, dtype))


def _box(value):
    return value.clone() if isinstance(value, _value.Value) else _value.encode(value)


def _call_named(name, arguments, raw=False):
    from .numeric_types import _SIGNATURES

    return _invoke(name, _SIGNATURES[name], arguments, raw)


def _literal(value, like):
    if isinstance(value, _value.Value):
        return _transfer(value.clone())
    if isinstance(value, numbers.Integral):
        return _call_named("literal_integer", [like, operator.index(value)], True)
    if isinstance(value, (numbers.Real, Fraction)):
        return _call_named("literal_rational", [like, Fraction(value)], True)
    raise TypeError("use an explicitly typed NumericValue for this operand")


class NumericValue(_value.Value):
    """Immutable Haskell-backed value. Each live reference pins the runtime.

    Operators invoke the original Num/Fractional/Floating instance. Scalar
    children stay boxed in properties, preserving dtype through callbacks.
    Explicit .value decodes standard scalar/container representations.
    """

    @property
    def value(self):
        kind, dtype, _ = self.info
        if kind == 1 and dtype >= 20:
            raise TypeError("use primal/tangent or quaternion components")
        if kind in (1, 2, 3, 4, 5, 10):
            return self.clone().decode()
        raise TypeError("opaque numeric representation: use its original getters")

    @property
    def type_name(self):
        return _call_named("type_name", [self])

    @property
    def primal(self):
        return _call_named("primal", [self], True)

    @property
    def tangent(self):
        return _call_named("tangent", [self], True)

    @property
    def rounded_value(self):
        return _call_named("rounded_value", [self], True)

    @property
    def numerical_exceptions(self):
        return _call_named("numerical_exceptions", [self])

    @property
    def components(self):
        kind, dtype, _ = self.info
        if kind == 53:
            return tuple(
                _call_named("dual_quaternion_component", [self, i], True)
                for i in range(2)
            )
        if (kind == 1 and dtype == 21) or kind == 52:
            return tuple(
                _call_named("quaternion_component", [self, i], True) for i in range(4)
            )
        raise TypeError("components requires Quaternion or DualQuaternion")

    def _binary(self, other, operation):
        operand = _literal(other, self)
        try:
            return _call_named("binary", [operation, self, operand], True)
        finally:
            operand.close()

    def __add__(self, other):
        return self._binary(other, 0)

    def __sub__(self, other):
        return self._binary(other, 1)

    def __mul__(self, other):
        return self._binary(other, 2)

    def __truediv__(self, other):
        return self._binary(other, 3)

    def __pow__(self, other):
        if isinstance(other, numbers.Integral):
            return _call_named("integer_power", [self, operator.index(other)], True)
        return self._binary(other, 4)

    def __radd__(self, other):
        return self.__add__(other)

    def __rmul__(self, other):
        # Multiplication order matters for Quaternion, even with a literal.
        operand = _literal(other, self)
        try:
            return _call_named("binary", [2, operand, self], True)
        finally:
            operand.close()

    def __rsub__(self, other):
        operand = _literal(other, self)
        try:
            return _call_named("binary", [1, operand, self], True)
        finally:
            operand.close()

    def __rtruediv__(self, other):
        operand = _literal(other, self)
        try:
            return _call_named("binary", [3, operand, self], True)
        finally:
            operand.close()

    def __neg__(self):
        return _call_named("unary", [0, self], True)

    def __abs__(self):
        return _call_named("unary", [1, self], True)

    def __eq__(self, other):
        try:
            operand = _literal(other, self)
        except (TypeError, ValueError):
            return False
        try:
            return _call_named("equal", [self, operand])
        finally:
            operand.close()

    __hash__ = None


def _floating_method(operation):
    def method(self):
        return _call_named("unary", [operation, self], True)

    return method


for _name, _operation in (
    ("signum", 2),
    ("recip", 3),
    ("exp", 4),
    ("log", 5),
    ("sqrt", 6),
    ("sin", 7),
    ("cos", 8),
    ("tan", 9),
    ("asin", 10),
    ("acos", 11),
    ("atan", 12),
    ("sinh", 13),
    ("cosh", 14),
    ("tanh", 15),
    ("asinh", 16),
    ("acosh", 17),
    ("atanh", 18),
):
    setattr(NumericValue, _name, _floating_method(_operation))


def _decode_enum(value):
    import hmath

    try:
        kind = value.info[0]
        result = C.c_int()
        with value._lock:
            hmath._check(
                _value.api(
                    "hmath_numeric_types_enum_value",
                    C.c_int,
                    C.c_void_p,
                    C.c_void_p,
                    C.POINTER(C.c_int),
                )(None, value._ptr, C.byref(result))
            )
        return (IEEEClass if kind == 49 else NumericException)(result.value)
    finally:
        value.close()


for _kind in (40, 41, 42, 43, 44, 45, 46, 47, 48, 52, 53):
    _value.register(_kind, NumericValue)
for _kind in (49, 50):
    _value.register(_kind, _decode_enum)
for _dtype in (20, 21):
    _value.register_scalar(_dtype, NumericValue)


def _invoke(name, kinds, arguments, raw=False):
    import hmath

    hmath.initialize()
    native_types = [C.c_void_p]
    native_values = [None]
    values = []
    callbacks = []
    errors = []
    result = NumericValue._adopt()
    try:
        for kind, argument in zip(kinds, arguments):
            if kind in ("o", "big", "fixed", "decimal", "interval", "half", "bhalf"):
                value = _box(argument)
                values.append(value)
                native_types.append(C.c_void_p)
                native_values.append(value._ptr)
            elif kind in ("i", "i32", "u16"):
                if kind == "i32" and isinstance(argument, str):
                    argument = _value.DTYPES[argument]
                typ = {"i": C.c_ssize_t, "i32": C.c_int, "u16": C.c_uint16}[kind]
                native_types.append(typ)
                native_values.append(_index(argument, C.sizeof(typ) * 8, kind == "u16"))
            elif kind in ("f32", "f64"):
                native_types.append(C.c_float if kind == "f32" else C.c_double)
                native_values.append(argument)
            elif kind == "mode":
                native_types.append(C.c_int)
                native_values.append(RoundingMode(argument))
            elif kind in ("z", "q"):
                parts = (
                    [operator.index(argument)]
                    if kind == "z"
                    else [Fraction(argument).numerator, Fraction(argument).denominator]
                )
                native_types.extend([C.c_char_p] * len(parts))
                native_values.extend(_decimal(v) for v in parts)
            elif kind in ("text", "flags"):
                if kind == "text":
                    if not isinstance(argument, str):
                        raise TypeError("expected a String")
                    sequence = list(map(ord, argument))
                    typ = C.c_uint32
                else:
                    sequence = [NumericException(v) for v in argument]
                    typ = C.c_int
                data = (typ * len(sequence))(*sequence)
                native_types.extend([C.POINTER(typ), C.c_size_t])
                native_values.extend([data, len(sequence)])
            elif kind == "callback":
                if not callable(argument):
                    raise TypeError("expected a callable")
                callback_type = C.CFUNCTYPE(
                    C.c_int, C.c_void_p, C.c_void_p, C.POINTER(C.c_void_p)
                )

                def adapter(pointer, userdata, out, function=argument):
                    incoming = _transfer(_value.borrow(pointer))
                    converted = None
                    try:
                        outcome = function(incoming)
                        converted = _literal(outcome, incoming)
                        with converted._lock:
                            _value.api("hmath_value_retain", None, C.c_void_p)(
                                converted._ptr
                            )
                            out[0] = converted._ptr
                        return 0
                    except BaseException as error:  # noqa: BLE001 - never unwind a Python exception through C
                        errors.append(error)
                        return 6
                    finally:
                        if converted is not None:
                            converted.close()
                        incoming.close()

                callback = callback_type(adapter)
                callbacks.append(callback)
                native_types.extend([callback_type, C.c_void_p])
                native_values.extend([callback, None])
            else:
                raise RuntimeError("unknown NumericTypes argument kind")
        result._owners = tuple(owner for value in values for owner in value._owners)
        native_types.append(C.POINTER(C.c_void_p))
        native_values.append(C.byref(result._ptr))
        # Every Value input is a separately retained private owner; no original
        # Python lock is held across reentrant Haskell/C/Python callbacks.
        status = _value.api("hmath_numeric_types_" + name, C.c_int, *native_types)(
            *native_values
        )
        if errors:
            raise errors[0]
        hmath._check(status)
        if raw:
            return result
        return result.decode()
    except BaseException:
        result.close()
        raise
    finally:
        for value in values:
            value.close()
