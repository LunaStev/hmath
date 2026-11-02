# SPDX-License-Identifier: MPL-2.0
"""Representation-only preparation for original TimeSeries inputs."""

from ._graph_base import _prepare
from ._value import decode, invoke


def _invoke(symbol, specifications, arguments):
    temporary = []
    prepared = []
    try:
        for specification, argument in zip(specifications, arguments):
            if specification == ["OptimizeOptions"]:
                from ._optimization_all import _typed

                value = _typed(argument, "OptimizeOptions")
                temporary.append(value)
                prepared.append(value)
            else:
                prepared.append(_prepare(specification, argument))
        return decode(invoke(symbol, *prepared))
    finally:
        for value in temporary:
            value.close()
