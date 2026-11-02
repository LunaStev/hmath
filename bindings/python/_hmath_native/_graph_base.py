# SPDX-License-Identifier: MPL-2.0
"""Type marshaling and callback lifetime for the original Graph algorithms."""

import ctypes as C
import operator

from ._value import Value, api, decode, encode, invoke


def _prepare(spec, argument):
    kind = spec[0]
    if kind == "Double":
        return float(argument)
    if kind in ("Int", "Integer"):
        return operator.index(argument)
    if kind == "Word64":
        number = operator.index(argument)
        if not 0 <= number <= (1 << 64) - 1:
            raise OverflowError("seed must fit Word64")
        return number
    if kind == "Bool":
        if not isinstance(argument, bool):
            raise TypeError("expected bool")
        return argument
    if kind == "String":
        if not isinstance(argument, str):
            raise TypeError("expected str")
        return argument
    if kind == "list":
        return [_prepare(spec[1], item) for item in argument]
    if kind == "tuple":
        arguments = tuple(argument)
        if len(arguments) != len(spec) - 1:
            raise ValueError("tuple arity differs")
        return tuple(_prepare(t, v) for t, v in zip(spec[1:], arguments))
    if kind == "maybe":
        return None if argument is None else _prepare(spec[1], argument)
    if kind == "unit":
        if argument != ():
            raise TypeError("expected unit ()")
        return ()
    if not isinstance(argument, Value):
        raise TypeError("expected an owned Graph-domain object")
    return argument


def _invoke(symbol, specifications, arguments):
    return decode(
        invoke(symbol, *[_prepare(t, a) for t, a in zip(specifications, arguments)])
    )


def _astar(graph, heuristic, start, end):
    import hmath

    hmath.initialize()
    if not callable(heuristic):
        raise TypeError("heuristic must be callable")
    failures = []
    callback_type = C.CFUNCTYPE(C.c_int, C.c_ssize_t, C.c_void_p, C.POINTER(C.c_double))

    @callback_type
    def callback(vertex, _, out):
        try:
            out[0] = float(heuristic(vertex))
            return 0
        except BaseException as error:  # noqa: BLE001 - exceptions must not cross a C callback
            failures.append(error)
            return 6

    inputs = [encode(graph), encode(operator.index(start)), encode(operator.index(end))]
    result = Value._adopt(owners=(callback,))
    try:
        status = api(
            "hmath_graph_a_star",
            C.c_int,
            C.c_void_p,
            C.c_void_p,
            callback_type,
            C.c_void_p,
            C.c_void_p,
            C.c_void_p,
            C.POINTER(C.c_void_p),
        )(
            None,
            inputs[0]._ptr,
            callback,
            None,
            inputs[1]._ptr,
            inputs[2]._ptr,
            C.byref(result._ptr),
        )
        if failures:
            raise failures[0]
        hmath._check(status)
        return decode(result)
    finally:
        result.close()
        for value in inputs:
            value.close()
