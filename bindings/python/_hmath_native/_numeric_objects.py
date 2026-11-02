# SPDX-License-Identifier: MPL-2.0
"""Typed-owner dispatch for original generic numerical functions only."""

from . import _value as V
from ._numerical_base import _invoke

_ORDERED = {
    "hmath_basic_clamp",
    "hmath_scalar_minimum_scalar",
    "hmath_scalar_maximum_scalar",
}


def _owner(argument):
    return isinstance(argument, V.Value) or (
        type(argument).__module__ == "_hmath_native.autodiff"
        and type(argument).__name__ in ("Dual", "Expr")
    )


def _contains_owner(argument):
    return _owner(argument) or (
        isinstance(argument, (list, tuple))
        and any(_contains_owner(item) for item in argument)
    )


def _uses_value(arguments, dtype, *, ordered=False):
    return (
        not isinstance(dtype, str)
        or dtype == "value"
        or any(_contains_owner(argument) for argument in arguments)
        or (
            ordered
            and any(
                isinstance(argument, (bool, str, list, tuple)) for argument in arguments
            )
        )
    )


def _uses_equality_value(arguments, dtype):
    return (
        _uses_value(arguments, dtype)
        or dtype not in {"float32", "float64"}
        or any(
            isinstance(item, bool) or not isinstance(item, (int, float, complex))
            for argument in arguments
            if isinstance(argument, (list, tuple))
            for item in argument
        )
    )


def _leaves(argument):
    if isinstance(argument, (list, tuple)):
        for item in argument:
            yield from _leaves(item)
    else:
        yield argument


def _call_value(symbol, kinds, arguments, dtype):
    temporary = []
    prototype = None
    try:
        if _owner(dtype):
            prototype = V.encode(dtype)
        elif symbol.startswith("hmath_geometry_primitives_"):
            prototype = (
                V.scalar(0, dtype)
                if dtype in V.DTYPES and dtype not in {"float32", "float64"}
                else V.encode(None)
            )
        elif symbol in _ORDERED:
            prototype = V.encode(arguments[0])
        else:
            candidates = [item for argument in arguments for item in _leaves(argument)]
            candidate = next((item for item in candidates if _owner(item)), None)
            if candidate is None:
                if not candidates:
                    raise ValueError(
                        "empty generic inputs require dtype=<typed prototype>"
                    )
                candidate = candidates[0]
            prototype = V.encode(candidate)
        inputs = []
        primitive = prototype.info[0] == 1 and prototype.info[1] in V.DTYPE_NAMES

        def coefficient(argument):
            if primitive and not _owner(argument):
                result = V.scalar(argument, V.DTYPE_NAMES[prototype.info[1]])
                temporary.append(result)
                return result
            return argument

        for kind, argument in zip(kinds, arguments):
            if symbol in _ORDERED:
                prepared = coefficient(argument)
            elif kind == "fs":
                prepared = [coefficient(item) for item in argument]
            else:
                prepared = coefficient(argument)
            inputs.append(prepared)
        return _invoke(
            symbol + "_value", [["Value"]] * (len(inputs) + 1), [prototype, *inputs]
        )
    finally:
        if prototype is not None:
            prototype.close()
        for owner in temporary:
            owner.close()
