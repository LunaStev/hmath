# SPDX-License-Identifier: MPL-2.0
"""Image representation and synchronous callback ownership, without algorithms."""

import ctypes as C

from . import _value as V
from ._graph_base import _prepare


def _prepare_argument(specification, argument):
    if isinstance(argument, V.Value):
        return argument
    if specification[0] == "list":
        return [_prepare_argument(specification[1], item) for item in argument]
    if specification[0] == "tuple":
        if not isinstance(argument, tuple) or len(argument) != len(specification) - 1:
            raise TypeError("tuple arity differs from its original signature")
        return tuple(
            _prepare_argument(typ, item)
            for typ, item in zip(specification[1:], argument)
        )
    return _prepare(specification, argument)


def _invoke(symbol, specifications, arguments):
    import hmath

    inputs = []
    callbacks = []
    failures = []
    types = [C.c_void_p]
    native = [None]
    result = V.Value._adopt()
    hmath.initialize()
    try:
        for specification, argument in zip(specifications, arguments):
            if specification[0] == "function":
                if not callable(argument):
                    raise TypeError("expected a deterministic callable")
                callback_type = C.CFUNCTYPE(
                    C.c_int, C.c_void_p, C.c_void_p, C.POINTER(C.c_void_p)
                )

                def callback(pointer, _, out, function=argument):
                    try:
                        values = V.borrow(pointer).decode()
                        answer = function(*values)
                        owner = (
                            answer.clone()
                            if isinstance(answer, V.Value)
                            else V.scalar(float(answer), "float64")
                        )
                        try:
                            V.api("hmath_value_retain", None, C.c_void_p)(owner._ptr)
                            out[0] = owner._ptr
                        finally:
                            owner.close()
                        return 0
                    except BaseException as error:  # noqa: BLE001 - never unwind through C
                        failures.append(error)
                        return 6

                adapter = callback_type(callback)
                callbacks.append(adapter)
                types.extend([callback_type, C.c_void_p])
                native.extend([adapter, None])
            else:
                owner = V.encode(_prepare_argument(specification, argument))
                inputs.append(owner)
                types.append(C.c_void_p)
                native.append(owner._ptr)
        types.append(C.POINTER(C.c_void_p))
        native.append(C.byref(result._ptr))
        status = V.api(symbol, C.c_int, *types)(*native)
        if failures:
            raise failures[0]
        hmath._check(status)
        return result.decode()
    finally:
        result.close()
        for owner in inputs:
            owner.close()
