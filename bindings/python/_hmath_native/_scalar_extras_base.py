# SPDX-License-Identifier: MPL-2.0
"""Lossless representations for additional original scalar-domain operations."""

import operator

from . import _value as V
from ._numeric import SFResult


class _Selector(V.Value):
    @property
    def name(self):
        return V.invoke("hmath_scalar_selector_name", self).decode()

    def __eq__(self, other):
        if not isinstance(other, type(self)):
            return NotImplemented
        return V.invoke("hmath_scalar_selector_equal", self, other).decode()

    __hash__ = None


class Elementary(_Selector):
    """Actual HMath.Complex.Elementary selector (Double complex functions)."""


class ComplexFunction(_Selector):
    """Actual HMath.Trigonometry.ComplexFunction selector (Float/Double)."""


V.register(352, Elementary)
V.register(353, ComplexFunction)


def _prepare(kind, argument, dtype):
    if isinstance(argument, V.Value):
        if kind == "TypedComplex" and dtype is not None:
            wanted = {"float32": 5, "complex64": 5, "float64": 4, "complex128": 4}[
                dtype
            ]
            if argument.info[:2] != (1, wanted):
                raise TypeError(
                    "explicit dtype differs from the actual complex coefficient"
                )
        return argument.clone()
    if kind in ("Int", "Integer"):
        return V.encode(operator.index(argument))
    if kind == "Double":
        return V.scalar(float(argument), "float64")
    if kind in ("ComplexDouble", "TypedComplex"):
        target = "complex64" if dtype in ("float32", "complex64") else "complex128"
        if dtype not in (None, "float32", "float64", "complex64", "complex128"):
            raise ValueError("complex dtype must select Float or Double")
        return V.scalar(complex(argument), target)
    if kind == "[ComplexDouble]":
        return V.encode([complex(x) for x in argument])
    if kind == "SFResult":
        value, error = argument
        return V.encode((float(value), float(error)))
    if kind == "[(Integer,Integer)]":
        return V.encode([tuple(operator.index(x) for x in pair) for pair in argument])
    return V.encode(argument)


def _invoke(symbol, kinds, arguments, result, dtype=None):
    owners = []
    try:
        for kind, argument in zip(kinds, arguments):
            owners.append(_prepare(kind, argument, dtype))
        value = V.invoke(symbol, *owners).decode()
        return SFResult(*value) if result == "SFResult" else value
    finally:
        for owner in owners:
            owner.close()
