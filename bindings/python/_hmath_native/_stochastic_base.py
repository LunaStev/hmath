# SPDX-License-Identifier: MPL-2.0
"""Lossless continuation/record owners and checked callback representations."""

import ctypes as C

from . import _value as V
from ._linear_base import (
    _callback,
    _callback_scope,
    _callback_states,
    _take_callback_failure,
)


class StochasticValue(V.Value):
    """Immutable original state or record; results own independent references."""

    def __init__(self, *_args):
        raise TypeError("use this type's public constructors or source functions")

    def _initialize(self, symbol, specs, arguments):
        result = _invoke(symbol, specs, arguments)
        self._ptr, self._lock, self._owners = result._ptr, result._lock, result._owners
        result._ptr, result._owners = C.c_void_p(), ()

    def __eq__(self, other):
        if not isinstance(other, type(self)):
            return NotImplemented
        return V.decode(V.invoke("hmath_stochastic_equal", self, other))

    __hash__ = None

    @property
    def parts(self):
        """Original public variant constructor and positional fields."""
        return V.decode(V.invoke("hmath_stochastic_object_parts", self))


def _prepare(spec, value, owners, callbacks):
    head, *args = spec
    if head in ("Double", "Integer", "Word64"):
        scalar = (
            value.clone()
            if isinstance(value, V.Value)
            else V.scalar(
                value,
                {"Double": "float64", "Integer": "integer", "Word64": "uint64"}[head],
            )
        )
        owners.append(scalar)
        return scalar
    if head == "a":
        return value
    if head == "list":
        return [_prepare(args[0], item, owners, callbacks) for item in value]
    if head == "tuple":
        value = tuple(value)
        if len(value) != len(args):
            raise ValueError("tuple arity differs from original signature")
        return tuple(
            _prepare(s, item, owners, callbacks) for s, item in zip(args, value)
        )
    if head == "function":
        if isinstance(value, V.Value):
            callbacks.extend(_callback_states(value))
            return value
        if not callable(value):
            raise TypeError("expected a callable source function argument")
        result_spec = args[-1]
        if result_spec[0] == "Either":
            result_spec = result_spec[2]

        def wrapped(*arguments):
            local = []
            try:
                prepared = _prepare(result_spec, value(*arguments), local, [])
                return V.encode(prepared)
            finally:
                for owner in local:
                    owner.close()

        function = _callback(wrapped, ["Value"], None)
        owners.append(function)
        callbacks.append(function)
        return function
    return value


def _invoke(symbol, specs, arguments):
    owners = []
    callbacks = []
    try:
        prepared = [
            _prepare(spec, value, owners, callbacks)
            for spec, value in zip(specs, arguments)
        ]
        scopes = _callback_scope(callbacks)
        try:
            result = V.invoke(symbol, *prepared)
        except BaseException:
            failure = _take_callback_failure(scopes)
            if failure is not None:
                raise failure
            raise
        return V.decode(result)
    finally:
        for owner in owners:
            owner.close()
