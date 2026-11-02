# Quaternions and rigid transforms

`hmath.quaternion` and `hmath.rotation` expose every public function of
`HMath.Quaternion` and `HMath.Rotation`. They use the actual immutable Haskell
objects and original checked algorithms. These finite, normalized rotation APIs
have distinct types from the generic algebraic values in `hmath.numeric_types`.

```python
from hmath import quaternion as q, rotation as r

with q.from_euler(0.1, 0.2, 0.3) as orientation:
    print(q.components(orientation))  # scalar-first [w, x, y, z]
    with r.so3(orientation) as rotation:
        with r.se3(rotation, [1, 2, 3]) as transform:
            print(r.transform_point(transform, [0, 0, 0]))
            with r.to_homogeneous(transform) as matrix:
                print(matrix.shape)  # (4, 4)
                print(matrix.to_list())
```

All real coefficients are the source `Double`. Python vector inputs become
`[Double]`; nested list/tuple results retain their original structure. Matrix
conversions accept or return the same owned `Matrix Double` used by the dense
matrix API, including its shape and row-major logical values. A Float32 Matrix
is a distinct coefficient type and must be converted explicitly.

## Mathematical conventions

Quaternions are Hamilton quaternions in scalar-first `(w,x,y,z)` order. Rotations
are active and right-handed, acting on column vectors. Angles are radians.
`multiply(a,b)` and transform `compose(a,b)` apply `b` first. Euler angles use
intrinsic ZYX, with the Python arguments and returned tuple ordered
`(roll,pitch,yaw)`. The source gimbal-lock convention chooses roll zero.

The `quaternion` constructor checks finite components. Normalization and inverse
reject a zero quaternion. SO(3) construction normalizes a nonzero quaternion.
Quaternion interpolation chooses the original shortest sign-equivalent arc;
`nlerp`, `slerp`, `squad` and dual-quaternion interpolation retain their source
parameter bounds and normalization behavior. SO(3) logarithms use the principal
angle in `[0,pi]`. SE(3) twists are a tuple `(omega,v)` of two three-vectors. The
source left-Jacobian formulas and their series near identity are unchanged.
Rigid dual-quaternion interpolation remains ScLERP through SE(3), including its
pure-translation limit.

`SO3`, `SE3` and `rotation.DualQuaternion` retain the source normalized and rigid
constraints. They do not represent arbitrary scale or shear. `from_matrix` and
`from_homogeneous` keep the original shape, orthogonality, handedness and bottom
row checks. No adapter sanitizes nonfinite data or substitutes a transform.

## Ownership and C interface

Use context managers or `close()` for native objects. Every returned child owns
its value independently of its parent. Equality uses the actual Haskell `Eq`
instance, so a sign-equivalent rotation does not automatically imply object
equality. Independent calls may share immutable objects while holding an owned
reference on each participating thread.

`hmath_rotations.h` declares the C interface. Arguments and outputs use shared
`hmath_value` owners. Scalar arguments must be common Double scalar values;
vector arguments are lists of Double scalar values. A twist is a tuple of two
such lists. Matrix arguments are shared Dense `Matrix Double` values. Opaque
kinds are 72 Quaternion, 73 SO3, 74 SE3 and 75 Rotation.DualQuaternion. These tags
are distinct from the generic Numeric quaternion types.

Each input is borrowed throughout its synchronous call. Success transfers one
owned output reference; failure leaves the output pointer untouched. Release
references with `hmath_value_release`. A live value keeps the Haskell runtime
alive and final shutdown reports `BUSY`. The original `Left MathError` becomes
status `HMATH_MATH_ERROR`, with complete constructor and payload available through
`hmath_last_math_error`. Cancellation is checked before a call enters Haskell.

## Functions

The table below lists every public function, its arguments and result shape.
Names use Python snake case; the original numerical function is unchanged.

| Python function | Argument types, in order | Result | Original function |
| --- | --- | --- | --- |
| `quaternion.quaternion(w, x, y, z)` | `float`, `float`, `float`, `float` | `Quaternion` | `HMath.Quaternion.quaternion` |
| `quaternion.components(value)` | `Quaternion` | `list[float]` | `HMath.Quaternion.components` |
| `quaternion.norm(value)` | `Quaternion` | `float` | `HMath.Quaternion.norm` |
| `quaternion.normalize(value)` | `Quaternion` | `Quaternion` | `HMath.Quaternion.normalize` |
| `quaternion.inverse(value)` | `Quaternion` | `Quaternion` | `HMath.Quaternion.inverse` |
| `quaternion.conjugate(value)` | `Quaternion` | `Quaternion` | `HMath.Quaternion.conjugate` |
| `quaternion.multiply(a, b)` | `Quaternion`, `Quaternion` | `Quaternion` | `HMath.Quaternion.multiply` |
| `quaternion.add(a, b)` | `Quaternion`, `Quaternion` | `Quaternion` | `HMath.Quaternion.add` |
| `quaternion.scale(factor, value)` | `float`, `Quaternion` | `Quaternion` | `HMath.Quaternion.scale` |
| `quaternion.rotate_vector(value, vector)` | `Quaternion`, `list[float]` | `list[float]` | `HMath.Quaternion.rotateVector` |
| `quaternion.axis_angle(axis, angle)` | `list[float]`, `float` | `Quaternion` | `HMath.Quaternion.axisAngle` |
| `quaternion.to_axis_angle(value)` | `Quaternion` | `(list[float], float)` | `HMath.Quaternion.toAxisAngle` |
| `quaternion.from_euler(roll, pitch, yaw)` | `float`, `float`, `float` | `Quaternion` | `HMath.Quaternion.fromEuler` |
| `quaternion.to_euler(value)` | `Quaternion` | `(float, float, float)` | `HMath.Quaternion.toEuler` |
| `quaternion.to_matrix(value)` | `Quaternion` | `Matrix Double` | `HMath.Quaternion.toMatrix` |
| `quaternion.from_matrix(matrix)` | `Matrix Double` | `Quaternion` | `HMath.Quaternion.fromMatrix` |
| `quaternion.nlerp(fraction, a, b)` | `float`, `Quaternion`, `Quaternion` | `Quaternion` | `HMath.Quaternion.nlerp` |
| `quaternion.slerp(fraction, a, b)` | `float`, `Quaternion`, `Quaternion` | `Quaternion` | `HMath.Quaternion.slerp` |
| `quaternion.squad(fraction, q0, q1, q2, q3)` | `float`, `Quaternion`, `Quaternion`, `Quaternion`, `Quaternion` | `Quaternion` | `HMath.Quaternion.squad` |
| `quaternion.exponential(value)` | `Quaternion` | `Quaternion` | `HMath.Quaternion.exponential` |
| `quaternion.logarithm(value)` | `Quaternion` | `Quaternion` | `HMath.Quaternion.logarithm` |
| `quaternion.swing_twist(axis, value)` | `list[float]`, `Quaternion` | `(Quaternion, Quaternion)` | `HMath.Quaternion.swingTwist` |
| `rotation.so3(value)` | `Quaternion` | `SO3` | `HMath.Rotation.so3` |
| `rotation.rotation_quaternion(value)` | `SO3` | `Quaternion` | `HMath.Rotation.rotationQuaternion` |
| `rotation.identity_rotation()` |  | `SO3` | `HMath.Rotation.identityRotation` |
| `rotation.compose_rotation(a, b)` | `SO3`, `SO3` | `SO3` | `HMath.Rotation.composeRotation` |
| `rotation.inverse_rotation(value)` | `SO3` | `SO3` | `HMath.Rotation.inverseRotation` |
| `rotation.rotate(value, vector)` | `SO3`, `list[float]` | `list[float]` | `HMath.Rotation.rotate` |
| `rotation.exp_so3(omega)` | `list[float]` | `SO3` | `HMath.Rotation.expSO3` |
| `rotation.log_so3(value)` | `SO3` | `list[float]` | `HMath.Rotation.logSO3` |
| `rotation.se3(rotation, translation)` | `SO3`, `list[float]` | `SE3` | `HMath.Rotation.se3` |
| `rotation.rotation_part(value)` | `SE3` | `SO3` | `HMath.Rotation.rotationPart` |
| `rotation.translation_part(value)` | `SE3` | `list[float]` | `HMath.Rotation.translationPart` |
| `rotation.identity_transform()` |  | `SE3` | `HMath.Rotation.identityTransform` |
| `rotation.compose(a, b)` | `SE3`, `SE3` | `SE3` | `HMath.Rotation.compose` |
| `rotation.inverse(value)` | `SE3` | `SE3` | `HMath.Rotation.inverse` |
| `rotation.transform_point(value, point)` | `SE3`, `list[float]` | `list[float]` | `HMath.Rotation.transformPoint` |
| `rotation.exp_se3(twist)` | `(list[float], list[float])` | `SE3` | `HMath.Rotation.expSE3` |
| `rotation.log_se3(value)` | `SE3` | `(list[float], list[float])` | `HMath.Rotation.logSE3` |
| `rotation.to_homogeneous(value)` | `SE3` | `Matrix Double` | `HMath.Rotation.toHomogeneous` |
| `rotation.from_homogeneous(matrix)` | `Matrix Double` | `SE3` | `HMath.Rotation.fromHomogeneous` |
| `rotation.dual_quaternion(real, dual)` | `Quaternion`, `Quaternion` | `DualQuaternion` | `HMath.Rotation.dualQuaternion` |
| `rotation.dual_parts(value)` | `DualQuaternion` | `(Quaternion, Quaternion)` | `HMath.Rotation.dualParts` |
| `rotation.to_dual_quaternion(value)` | `SE3` | `DualQuaternion` | `HMath.Rotation.toDualQuaternion` |
| `rotation.from_dual_quaternion(value)` | `DualQuaternion` | `SE3` | `HMath.Rotation.fromDualQuaternion` |
| `rotation.multiply_dual(a, b)` | `DualQuaternion`, `DualQuaternion` | `DualQuaternion` | `HMath.Rotation.multiplyDual` |
| `rotation.inverse_dual(value)` | `DualQuaternion` | `DualQuaternion` | `HMath.Rotation.inverseDual` |
| `rotation.interpolate_dual(fraction, a, b)` | `float`, `DualQuaternion`, `DualQuaternion` | `DualQuaternion` | `HMath.Rotation.interpolateDual` |
