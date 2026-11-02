# SPDX-License-Identifier: MPL-2.0
"""Typed values and callback ownership for original numerical solvers."""

import ctypes as C
import operator
from fractions import Fraction

from . import _value as value
from ._callback_error import fill
from ._linear_base import _callback_states
from ._linear_base import _CallbackState as _NativeCallbackState
from ._math_error import Wire

_CALLBACK = C.CFUNCTYPE(
    C.c_int,
    C.c_void_p,
    C.c_void_p,
    C.POINTER(C.c_void_p),
    C.POINTER(Wire),
)
_FAILURE_MESSAGE = C.create_string_buffer(b"Python numerical callback failed")


class _CallbackState(_NativeCallbackState):
    def __init__(self):
        super().__init__()
        self.failures = self._callback_errors
        self.buffers = self.payload
        self.retained = self.returned_owners


def _prepare(specification, argument, temporary):
    kind = specification[0]
    if kind == "either":
        return _prepare(specification[1], argument, temporary)
    if kind == "function":
        if isinstance(argument, value.Value):
            if argument.info[0] != 101:
                raise TypeError("expected a native callback Value")
            return argument
        callback = _callback(argument, specification[-1])
        temporary.append(callback)
        return callback
    if kind == "list":
        return [_prepare(specification[1], item, temporary) for item in argument]
    if kind == "tuple":
        fields = tuple(argument)
        if len(fields) != len(specification) - 1:
            raise ValueError("tuple arity differs")
        return tuple(
            _prepare(spec, item, temporary)
            for spec, item in zip(specification[1:], fields)
        )
    if kind == "maybe":
        return (
            None
            if argument is None
            else _prepare(specification[1], argument, temporary)
        )
    if kind == "Double":
        return float(argument)
    if kind in ("Int", "Integer"):
        return operator.index(argument)
    if kind == "Word64":
        prepared = value.scalar(argument, "uint64")
        temporary.append(prepared)
        return prepared
    if kind == "ComplexDouble":
        return complex(argument)
    if kind == "Rational":
        if not isinstance(argument, (int, Fraction)):
            raise TypeError("exact Rational requires an integer or Fraction")
        return Fraction(argument)
    if kind == "Bool":
        if not isinstance(argument, bool):
            raise TypeError("expected bool")
        return argument
    if kind == "String":
        if not isinstance(argument, str):
            raise TypeError("expected str")
        return argument
    # Typed native owners and Estimate's arbitrary payload pass to the shared
    # encoder. The Haskell instance validates their actual coefficient/domain.
    return argument


def _callback(function, result_specification):
    import hmath

    if not callable(function):
        raise TypeError("expected a callable original function argument")
    state = _CallbackState()

    @_CALLBACK
    def callback(pointer, _, out, error_wire):
        temporary = []
        try:
            arguments = value.decode(value.borrow(pointer))
            result = function(*arguments)
            encoded = value.encode(_prepare(result_specification, result, temporary))
            state.retained.extend(
                owner for owner in encoded._owners if owner is not state
            )
            out[0] = encoded._ptr
            encoded._ptr, encoded._owners = C.c_void_p(), ()
            return 0
        except BaseException as error:  # noqa: BLE001 - no Python exception may unwind through C
            try:
                handled = fill(error_wire, error, state.buffers)
            except BaseException:  # noqa: BLE001 - malformed error payloads remain contained
                handled = False
            if handled:
                return handled
            state.failures.append(error)
            # Avoid invoking arbitrary exception __str__ inside a C callback.
            error_wire.contents.message = C.cast(_FAILURE_MESSAGE, C.c_void_p)
            error_wire.contents.message_length = len(_FAILURE_MESSAGE.value)
            return 6
        finally:
            for item in temporary:
                item.close()

    owner = value.Value._adopt(owners=(callback, state))
    hmath.initialize()
    hmath._check(
        value.api(
            "hmath_linear_callback",
            C.c_int,
            C.c_void_p,
            _CALLBACK,
            C.c_void_p,
            C.POINTER(C.c_void_p),
        )(None, callback, None, C.byref(owner._ptr))
    )
    return owner


def _invoke(symbol, specifications, arguments, *, boxed=False):
    temporary, inputs = [], []
    snapshots = []
    try:
        for specification, argument in zip(specifications, arguments):
            prepared = _prepare(specification, argument, temporary)
            inputs.append(value.encode(prepared))
        snapshots = [
            (state, len(state._callback_errors)) for state in _callback_states(inputs)
        ]

        def take_failure():
            original = None
            for state, before in snapshots:
                errors = state._callback_errors
                if len(errors) > before:
                    if original is None:
                        original = errors[before]
                    del errors[before:]
            return original

        try:
            result = value.invoke(symbol, *inputs)
        except BaseException:
            original = take_failure()
            if original is not None:
                raise original from None
            raise
        original = take_failure()
        if original is not None:
            result.close()
            raise original from None
        return result if boxed else value.decode(result)
    finally:
        for item in inputs:
            item.close()
        for item in temporary:
            item.close()
