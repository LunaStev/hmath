# SPDX-License-Identifier: MPL-2.0
"""Persistent owners, exact generic choices and original callback transport."""

import ctypes as C
import importlib

from . import _value as V
from ._linear_base import _callback_scope, _take_callback_failure
from ._stochastic_base import _prepare

_TYPES = {}


def register(source_type, owner):
    if source_type in _TYPES and _TYPES[source_type] is not owner:
        raise ValueError("foundation type already registered")
    _TYPES[source_type] = owner


class FoundationValue(V.Value):
    _source_type = None

    def __init__(self, *_args):
        raise TypeError("use the original public constructors")

    def _initialize(self, symbol, specs, arguments, mode="value", prototype=None):
        result = _invoke(symbol, specs, arguments, mode, prototype=prototype)
        self._ptr, self._lock, self._owners = result._ptr, result._lock, result._owners
        result._ptr, result._owners = C.c_void_p(), ()

    @property
    def source_type(self):
        return self._source_type

    @property
    def parts(self):
        return V.decode(V.invoke("hmath_foundation_object_parts", self))


class Either(FoundationValue):
    """Original generic Either: inspect parts for ('Left',error)/('Right',value)."""

    _source_type = "HMath.Internal.Either"


class Just(FoundationValue):
    """Distinguishes a successful optional None from absent Nothing."""

    _source_type = "HMath.Internal.Just"


class OrderedType(FoundationValue):
    """Owned original Ord dictionary, including explicit nested optional types."""

    _source_type = "HMath.Internal.OrderedType"


_TYPES["HMath.Internal.Either"] = Either
_TYPES["HMath.Internal.Just"] = Just
_TYPES["HMath.Internal.OrderedType"] = OrderedType


def _decode(value):
    name = V.decode(V.invoke("hmath_foundation_object_type", value))
    owner = _TYPES.get(name)
    if owner is None:
        namespace = {
            "HMath.DataStructure": "data_structures",
            "HMath.Discrete": "discrete_values",
            "HMath.Algorithms": "algorithm_values",
            "HMath.Combinatorics": "combinatorics_values",
            "HMath.API.Convergence": "convergence_values",
            "HMath.Algebra": "algebra",
            "HMath.API.Algebra": "algebra_api",
            "HMath.API.Shape": "shape_values",
            "HMath.API.Buffer": "buffer_values",
        }[name.rsplit(".", 1)[0]]
        importlib.import_module("." + namespace, __package__)
        owner = _TYPES.get(name)
    if owner is None:
        raise TypeError("unknown foundation source type")
    with value._lock:
        result = owner._adopt(value._ptr, value._owners)
        value._ptr, value._owners = C.c_void_p(), ()
        return result


V.register(400, _decode)


def left(value):
    return V.decode(V.invoke("hmath_foundation_left", value))


def right(value):
    return V.decode(V.invoke("hmath_foundation_right", value))


def just(value):
    return V.decode(V.invoke("hmath_foundation_just", value))


def ordered_type(prototype):
    return V.decode(V.invoke("hmath_foundation_ordered_type", prototype))


def optional_type(prototype):
    return V.decode(V.invoke("hmath_foundation_optional_type", prototype))


def _invoke(symbol, specs, arguments, mode="value", dtype=None, prototype=None):
    owners = []
    callbacks = []
    order_prototype = prototype
    try:
        if mode == "numeric":
            source_values = list(arguments[0])
            if isinstance(dtype, V.Value):
                prototype = dtype.clone()
            elif dtype is not None:
                prototype = V.scalar(0, dtype)
            elif source_values and isinstance(source_values[0], V.Value):
                prototype = source_values[0].clone()
            else:
                prototype = V.scalar(source_values[0] if source_values else 0)
            owners.append(prototype)
            inferred = prototype.dtype
            values = []
            for value in source_values:
                scalar = (
                    value.clone()
                    if isinstance(value, V.Value)
                    else V.scalar(value, inferred)
                )
                owners.append(scalar)
                values.append(scalar)
            prepared = [prototype, values]
        else:
            adjusted = []

            # Rational parameters in the concrete combinatorial algorithms are
            # exact even when Python callers supply ordinary integer literals.
            def rational(spec, value):
                if spec == ["Rational"]:
                    item = (
                        value.clone()
                        if isinstance(value, V.Value)
                        else V.scalar(value, "rational")
                    )
                    owners.append(item)
                    return item
                if spec[0] == "list":
                    return [rational(spec[1], item) for item in value]
                return value

            for spec, value in zip(specs, arguments):
                adjusted.append(rational(spec, value))
            prepared = [
                _prepare(spec, value, owners, callbacks)
                for spec, value in zip(specs, adjusted)
            ]
        if order_prototype is not None:
            symbol = {
                "hmath_foundation_datastructure_heap_from_list": "hmath_foundation_heap_from_list_typed",
                "hmath_foundation_discrete_multiset": "hmath_foundation_multiset_typed",
            }.get(symbol, symbol + "_typed")
            prepared.insert(0, order_prototype)
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
