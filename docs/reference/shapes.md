# Runtime and type-indexed shapes

These APIs call the original `HMath.API.Shape` operations. Haskell type-level
natural dimensions become explicit Python integers/C Integer Values. The adapter
reifies actual `KnownNat` and recursive `KnownShape` dictionaries; it never
coerces a matrix/tensor to an unrelated shape. `reflected_shape` retains exact
Integer dimensions, even above Int. The original constructors decide Int
overflow and dynamic shape errors. Static multiplication also requires equal
nominal inner dimensions and identical element types.

`scalar_shape`, `vector_shape`, and `matrix_shape` are read-only source pattern
views: Boolean match, optional length, and optional `(rows, columns)`.
`make_shape` performs checked construction. `coordinates(length, values,
dtype=...)` retains the original lazy list element type; numeric, Bool, String
and Exact elements remain lossless. Vector conversion uses the original source
conversion and produces an ordinary interoperable Vector owner. Static wrappers
own independent references. Dynamic conversion retains the original element
type and does not copy or coerce mathematical values. Close each owned result.

## `shape.shape_dimensions`

Calls `HMath.API.Shape.shapeDimensions`. C parameters: `shape`, each a borrowed Value; the output owns one reference. Failures leave the output pointer untouched.

## `shape.shape_elements`

Calls `HMath.API.Shape.shapeElements`. C parameters: `shape`, each a borrowed Value; the output owns one reference. Failures leave the output pointer untouched.

## `shape.make_shape`

Calls `HMath.API.Shape.makeShape`. C parameters: `dimensions`, each a borrowed Value; the output owns one reference. Failures leave the output pointer untouched.

## `shape.scalar_shape`

Calls `HMath.API.Shape.ScalarShape`. C parameters: `shape`, each a borrowed Value; the output owns one reference. Failures leave the output pointer untouched.

## `shape.vector_shape`

Calls `HMath.API.Shape.VectorShape`. C parameters: `shape`, each a borrowed Value; the output owns one reference. Failures leave the output pointer untouched.

## `shape.matrix_shape`

Calls `HMath.API.Shape.MatrixShape`. C parameters: `shape`, each a borrowed Value; the output owns one reference. Failures leave the output pointer untouched.

## `shape.static_matrix`

Calls `HMath.API.Shape.staticMatrix`. C parameters: `rows, columns, matrix`, each a borrowed Value; the output owns one reference. Failures leave the output pointer untouched.

## `shape.dynamic_matrix`

Calls `HMath.API.Shape.dynamicMatrix`. C parameters: `matrix`, each a borrowed Value; the output owns one reference. Failures leave the output pointer untouched.

## `shape.static_multiply`

Calls `HMath.API.Shape.staticMultiply`. C parameters: `left, right`, each a borrowed Value; the output owns one reference. Failures leave the output pointer untouched.

## `shape.static_transpose`

Calls `HMath.API.Shape.staticTranspose`. C parameters: `matrix`, each a borrowed Value; the output owns one reference. Failures leave the output pointer untouched.

## `shape.reflected_shape`

Calls `HMath.API.Shape.reflectedShape`. C parameters: `dimensions`, each a borrowed Value; the output owns one reference. Failures leave the output pointer untouched.

## `shape.static_tensor`

Calls `HMath.API.Shape.staticTensor`. C parameters: `dimensions, tensor`, each a borrowed Value; the output owns one reference. Failures leave the output pointer untouched.

## `shape.dynamic_tensor`

Calls `HMath.API.Shape.dynamicTensor`. C parameters: `tensor`, each a borrowed Value; the output owns one reference. Failures leave the output pointer untouched.

## `shape.coordinates`

Calls `HMath.API.Shape.coordinates`. C parameters: `prototype, length, values`, each a borrowed Value; the output owns one reference. The prototype selects the original element type, including empty coordinates. Failures leave the output pointer untouched.

## `shape.coordinate_values`

Calls `HMath.API.Shape.coordinateValues`. C parameters: `coordinates`, each a borrowed Value; the output owns one reference. Failures leave the output pointer untouched.

## `shape.coordinates_to_vector`

Calls `HMath.API.Shape.coordinatesToVector`. C parameters: `coordinates`, each a borrowed Value; the output owns one reference. Failures leave the output pointer untouched.

