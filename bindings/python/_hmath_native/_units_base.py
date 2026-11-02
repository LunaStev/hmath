# SPDX-License-Identifier: MPL-2.0
"""Lifetime and exact scalar representations for the original Units API."""

import ctypes as C

from . import _value as V


class _UnitsValue(V.Value):
    def __eq__(self, other):
        if not isinstance(other, type(self)):
            return NotImplemented
        return V.decode(V.invoke("hmath_units_value_equal", self, other))

    __hash__ = None

    def _initialize(self, symbol, types, *args):
        result = _call(symbol, types, *args)
        self._ptr, self._lock, self._owners = result._ptr, result._lock, result._owners
        result._ptr, result._owners = C.c_void_p(), ()


class Dimension(_UnitsValue):
    """Nine exact dimensional exponents; source constructor validation applies."""

    def __init__(self, exponents):
        self._initialize("hmath_units_value_dimension", ["[Integer]"], exponents)

    @property
    def exponents(self):
        return _call("hmath_units_value_dimension_exponents", ["Dimension"], self)


class Unit(_UnitsValue):
    """Exact affine conversion SI=value*scale+offset."""

    def __init__(self, name, dimension, scale, offset):
        self._initialize(
            "hmath_units_value_unit",
            ["String", "Dimension", "Rational", "Rational"],
            name,
            dimension,
            scale,
            offset,
        )

    @property
    def name(self):
        return _call("hmath_units_value_unit_name", ["Unit"], self)

    @property
    def dimension(self):
        return _call("hmath_units_value_unit_dimension", ["Unit"], self)

    @property
    def scale(self):
        return _call("hmath_units_value_unit_scale", ["Unit"], self)

    @property
    def offset(self):
        return _call("hmath_units_value_unit_offset", ["Unit"], self)


class Quantity(_UnitsValue):
    """Exact SI value and dimensional/absolute-temperature semantics."""

    def __init__(self, unit, value):
        self._initialize(
            "hmath_units_value_quantity", ["Unit", "Rational"], unit, value
        )

    @property
    def dimension(self):
        return _call("hmath_units_value_quantity_dimension", ["Quantity"], self)

    @property
    def si_value(self):
        return _call("hmath_units_value_si_value", ["Quantity"], self)


class SIPrefix(_UnitsValue):
    """Original SI-prefix record, including unrestricted constructor text."""

    def __init__(self, name, symbol, exponent):
        self._initialize(
            "hmath_units_value_si_prefix",
            ["String", "String", "Int"],
            name,
            symbol,
            exponent,
        )

    @property
    def name(self):
        return _call("hmath_units_value_prefix_name", ["SIPrefix"], self)

    @property
    def symbol(self):
        return _call("hmath_units_value_prefix_symbol", ["SIPrefix"], self)

    @property
    def exponent(self):
        return _call("hmath_units_value_prefix_exponent", ["SIPrefix"], self)


for _kind, _owner in [(68, Dimension), (69, Unit), (70, Quantity), (71, SIPrefix)]:
    V.register(_kind, _owner)


def _call(symbol, types, *arguments):
    converted = []
    owners = []
    try:
        for typ, value in zip(types, arguments):
            if typ in ("Rational", "Integer"):
                item = (
                    value.clone()
                    if isinstance(value, V.Value)
                    else V.scalar(value, "rational" if typ == "Rational" else "integer")
                )
                converted.append(item)
                owners.append(item)
            elif typ == "[Integer]":
                items = []
                for number in value:
                    item = (
                        number.clone()
                        if isinstance(number, V.Value)
                        else V.scalar(number, "integer")
                    )
                    items.append(item)
                    owners.append(item)
                converted.append(items)
            else:
                converted.append(value)
        return V.decode(V.invoke(symbol, *converted))
    finally:
        for owner in owners:
            owner.close()
