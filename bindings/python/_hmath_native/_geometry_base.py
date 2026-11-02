# SPDX-License-Identifier: MPL-2.0
"""Typed Geometry representation; algorithms remain in the original modules."""

from enum import IntEnum

from . import _value as V
from ._image_base import _prepare_argument


class Ordering(IntEnum):
    LT = -1
    EQ = 0
    GT = 1


class GeometryValue(V.Value):
    @property
    def parts(self):
        return _invoke("hmath_geometry_parts", [["GeometryObject"]], [self])

    @property
    def coordinates(self):
        name, fields = self.parts
        if name in ("P2", "P3"):
            return list(fields)
        if name == "PointND":
            return fields[0]
        raise TypeError("coordinates requires Point2, Point3 or PointND")

    def __eq__(self, other):
        if not isinstance(other, GeometryValue):
            return NotImplemented
        return _invoke("hmath_geometry_equal", [["GeometryObject"]] * 2, [self, other])

    __hash__ = None


def _invoke(symbol, specifications, arguments):
    owners = []
    try:
        for specification, argument in zip(specifications, arguments):
            value = (
                argument
                if specification == ["Matrix Double"]
                else _prepare_argument(specification, argument)
            )
            owners.append(V.encode(value))
        return V.invoke(symbol, *owners).decode()
    finally:
        for owner in owners:
            owner.close()
