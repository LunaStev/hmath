# SPDX-License-Identifier: MPL-2.0
"""Ownership/representation for the original finite Quaternion/SO(3)/SE(3) types."""

from . import _value as V


class _RotationValue(V.Value):
    def __eq__(self, other):
        if not isinstance(other, type(self)):
            return NotImplemented
        return V.invoke("hmath_rotations_equal", self, other).decode()

    __hash__ = None


class Quaternion(_RotationValue):
    """Actual finite HMath.Quaternion.Quaternion; construct via quaternion()."""


class SO3(_RotationValue):
    """Actual normalized HMath.Rotation.SO3; construct via so3()/exp_so3()."""


class SE3(_RotationValue):
    """Actual HMath.Rotation.SE3 rigid transform; construct via se3()/exp_se3()."""


class DualQuaternion(_RotationValue):
    """Actual rigid HMath.Rotation.DualQuaternion, distinct from Numeric's type."""


for _kind, _owner in [(72, Quaternion), (73, SO3), (74, SE3), (75, DualQuaternion)]:
    V.register(_kind, _owner)


def _call(symbol, kinds, *arguments):
    owners = []
    try:
        for kind, argument in zip(kinds, arguments):
            if isinstance(argument, V.Value):
                item = argument.clone()
            elif kind == "d":
                item = V.scalar(argument, "float64")
            elif kind == "v":
                item = V.encode([float(x) for x in argument])
            elif kind == "twist":
                if not isinstance(argument, tuple) or len(argument) != 2:
                    raise TypeError("twist is a tuple of two vector lists")
                item = V.encode(
                    tuple([float(x) for x in vector] for vector in argument)
                )
            else:
                item = V.encode(argument)
            owners.append(item)
        return V.invoke(symbol, *owners).decode()
    finally:
        for owner in owners:
            owner.close()
