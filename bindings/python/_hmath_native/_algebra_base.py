# SPDX-License-Identifier: MPL-2.0
"""Original algebra instance selection and independent Value ownership."""

import ctypes as C

from . import _value as V
from ._foundation_base import _invoke as plain_invoke


def _snapshot(spec, value):
    if spec[0] == "list":
        return [_snapshot(spec[1], item) for item in value]
    if spec[0] == "tuple":
        value = tuple(value)
        if len(value) != len(spec) - 1:
            raise ValueError("tuple arity differs from original signature")
        return tuple(_snapshot(s, item) for s, item in zip(spec[1:], value))
    return value


def _candidate(spec, value):
    if spec[0] in ("a", "s", "v", "Additive", "Matrix", "Vector", "Tensor"):
        if spec[0] == "v":
            return value[0] if value else None
        return value
    if spec[0] in ("list", "tuple"):
        specs = [spec[1]] * len(value) if spec[0] == "list" else spec[1:]
        for child, item in zip(specs, value):
            result = _candidate(child, item)
            if result is not None:
                return result
    return None


def invoke(symbol, specs, arguments, mode="value", dtype=None):
    if mode == "value":
        return plain_invoke(symbol, specs, arguments)
    arguments = [_snapshot(s, value) for s, value in zip(specs, arguments)]
    prototype = dtype
    if prototype is None:
        for spec, value in zip(specs, arguments):
            prototype = _candidate(spec, value)
            if prototype is not None:
                break
    if isinstance(prototype, V.Value):
        prototype = prototype.clone()
    elif isinstance(prototype, str) and dtype is not None:
        if prototype in ("bool", "string"):
            prototype = V.encode(False if prototype == "bool" else "")
        else:
            prototype = V.scalar(0, prototype)
    elif hasattr(prototype, "dtype"):
        prototype = V.scalar(0, prototype.dtype)
    elif isinstance(prototype, (bool, str)):
        prototype = V.encode(prototype)
    else:
        prototype = V.scalar(prototype if prototype is not None else 0)
    owners = [prototype]
    try:
        target = prototype.dtype

        def prepare(spec, value):
            head, *children = spec
            if head in ("a", "s"):
                if isinstance(value, V.Value):
                    item = value.clone()
                elif prototype.info[0] in (3, 10):
                    item = V.encode(value)
                else:
                    item = V.scalar(value, target)
                owners.append(item)
                return item
            if head == "v":
                return [prepare(["a"], item) for item in value]
            if head == "list":
                return [prepare(children[0], item) for item in value]
            if head == "tuple":
                return tuple(prepare(s, item) for s, item in zip(children, value))
            if head in ("Integer", "Rational"):
                item = (
                    value.clone()
                    if isinstance(value, V.Value)
                    else V.scalar(value, head.lower())
                )
                owners.append(item)
                return item
            return value

        prepared = [prepare(s, value) for s, value in zip(specs, arguments)]
        return V.decode(V.invoke(symbol, prototype, *prepared))
    finally:
        for owner in owners:
            owner.close()


def initialize(owner, symbol, specs, arguments, mode, dtype):
    result = invoke(symbol, specs, arguments, mode, dtype)
    owner._ptr, owner._lock, owner._owners = result._ptr, result._lock, result._owners
    result._ptr, result._owners = C.c_void_p(), ()
