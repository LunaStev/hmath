# Dense matrix, LU and QR bindings

These APIs directly call the original `HMath.Matrix`, `HMath.Matrix.LU` and `HMath.Matrix.QR` functions, specialized to Haskell `Float` (binary32) or `Double` (binary64). Other generic Haskell element types are not yet exposed.

Python: `from hmath import matrix`. C/C++: include `hmath_matrix.h`. Original argument order and mathematical validation are retained. Coordinates and extents are flattened into individual arguments; vectors are a typed pointer plus element count in C.

## Results and errors

Original `Maybe` functions return Python `None` on failure; in C, they return `HMATH_OK` and a NULL object, or `found=0` for scalar `at` (leaving the scalar output untouched). Checked `Either MathError` functions raise `HMathError` in Python and return `HMATH_MATH_ERROR` in C; the original constructor and payload remain in the error message. Pure functions add no finite-value validation. Empty dimensions, shape validation order, LU singularity/tolerance policy, QR rank estimation, permutations and ridge regularization retain their original contracts.

## Ownership and precision

Matrix, LU and QR objects are immutable and independently owned. Close every Python object explicitly or use `with`; in C, call `hmath_dense_release` for each returned object. `hmath_dense_retain` adds a reference and both retain/release accept NULL. Each live object keeps the Haskell runtime alive, so final shutdown returns `HMATH_BUSY` until all such objects are released. A derived factor/matrix remains valid after its parent is closed.

Constructors without an input object accept keyword-only `dtype="float64"` or `dtype="float32"`. Other operations infer dtype from their input objects and reject mixed dtypes. C names end in `_f32` or `_f64` and require the matching object precision; query it with `hmath_dense_precision`. No FP32-to-FP64 intermediate is introduced. The original pure reference algorithms are used, with the original precision-specific default pivot tolerances.

Each caller must hold a live reference for the entire operation. Threads may share immutable inputs but must use independent outputs. Inputs are borrowed for the call; output regions must not overlap inputs or each other. C output pointers/buffers remain untouched on error. Cancellation is checked before the operation, not during the original Haskell algorithm. Haskell dimensions use `ptrdiff_t`, preserving negative-shape errors; checked byte spans and allocation failures are binding-level errors. No legacy tensor element/work cap is added to these dense APIs.

## shape and to_list

`matrix.shape(value)` returns the original `(rows, columns)`, including zero dimensions. `matrix.to_list(value)` returns original row-major storage as a Python list. In C use `hmath_dense_shape`, or `hmath_dense_count` followed by `hmath_dense_values_f32/f64`; capacity is in elements and is checked. Vector solve results use an owned `hmath_dense_vector` with the same count/value-copy helpers. Permutations use `hmath_dense_indices` and `hmath_dense_indices_copy`; they are the original final row/column orders, not swap sequences.

## `from_list`

`matrix.from_list(rows, columns, values, *, dtype="float64")`

Original contract: [`HMath.Matrix.fromList`](haskell/HMath-Matrix.md#v:fromList). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `rows` | Haskell Int (C: ptrdiff_t) |
| `columns` | Haskell Int (C: ptrdiff_t) |
| `values` | finite-length sequence of elements (C: typed pointer + count) |
| `dtype` | float32 or float64; default float64 |

Returns an independently owned Matrix. A Nothing result becomes None / NULL (or found=0).

```c
hmath_status hmath_dense_from_list_f32(hmath_context *context, ptrdiff_t a0, ptrdiff_t a1, const float *a2, size_t a2_count, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_from_list_f64(hmath_context *context, ptrdiff_t a0, ptrdiff_t a1, const double *a2, size_t a2_count, hmath_dense_matrix **out);
```

## `zero_matrix`

`matrix.zero_matrix(rows, columns, *, dtype="float64")`

Original contract: [`HMath.Matrix.zeroMatrix`](haskell/HMath-Matrix.md#v:zeroMatrix). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `rows` | Haskell Int (C: ptrdiff_t) |
| `columns` | Haskell Int (C: ptrdiff_t) |
| `dtype` | float32 or float64; default float64 |

Returns an independently owned Matrix. A Nothing result becomes None / NULL (or found=0).

```c
hmath_status hmath_dense_zero_matrix_f32(hmath_context *context, ptrdiff_t a0, ptrdiff_t a1, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_zero_matrix_f64(hmath_context *context, ptrdiff_t a0, ptrdiff_t a1, hmath_dense_matrix **out);
```

## `diagonal`

`matrix.diagonal(values, *, dtype="float64")`

Original contract: [`HMath.Matrix.diagonal`](haskell/HMath-Matrix.md#v:diagonal). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `values` | finite-length sequence of elements (C: typed pointer + count) |
| `dtype` | float32 or float64; default float64 |

Returns an independently owned Matrix. A Nothing result becomes None / NULL (or found=0).

```c
hmath_status hmath_dense_diagonal_f32(hmath_context *context, const float *a0, size_t a0_count, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_diagonal_f64(hmath_context *context, const double *a0, size_t a0_count, hmath_dense_matrix **out);
```

## `at`

`matrix.at(matrix, row, column)`

Original contract: [`HMath.Matrix.at`](haskell/HMath-Matrix.md#v:at). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `matrix` | Matrix of matching dtype |
| `row` | Haskell Int (C: ptrdiff_t) |
| `column` | Haskell Int (C: ptrdiff_t) |

Returns a scalar. A Nothing result becomes None / NULL (or found=0).

```c
hmath_status hmath_dense_at_f32(hmath_context *context, const hmath_dense_matrix *a0, ptrdiff_t a1, ptrdiff_t a2, float *out, int *found);
```

```c
hmath_status hmath_dense_at_f64(hmath_context *context, const hmath_dense_matrix *a0, ptrdiff_t a1, ptrdiff_t a2, double *out, int *found);
```

## `slice_matrix`

`matrix.slice_matrix(start_row, start_column, rows, columns, matrix)`

Original contract: [`HMath.Matrix.sliceMatrix`](haskell/HMath-Matrix.md#v:sliceMatrix). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `start_row` | Haskell Int (C: ptrdiff_t) |
| `start_column` | Haskell Int (C: ptrdiff_t) |
| `rows` | Haskell Int (C: ptrdiff_t) |
| `columns` | Haskell Int (C: ptrdiff_t) |
| `matrix` | Matrix of matching dtype |

Returns an independently owned Matrix. A Nothing result becomes None / NULL (or found=0).

```c
hmath_status hmath_dense_slice_matrix_f32(hmath_context *context, ptrdiff_t a0, ptrdiff_t a1, ptrdiff_t a2, ptrdiff_t a3, const hmath_dense_matrix *a4, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_slice_matrix_f64(hmath_context *context, ptrdiff_t a0, ptrdiff_t a1, ptrdiff_t a2, ptrdiff_t a3, const hmath_dense_matrix *a4, hmath_dense_matrix **out);
```

## `reshape`

`matrix.reshape(rows, columns, matrix)`

Original contract: [`HMath.Matrix.reshape`](haskell/HMath-Matrix.md#v:reshape). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `rows` | Haskell Int (C: ptrdiff_t) |
| `columns` | Haskell Int (C: ptrdiff_t) |
| `matrix` | Matrix of matching dtype |

Returns an independently owned Matrix. A Nothing result becomes None / NULL (or found=0).

```c
hmath_status hmath_dense_reshape_f32(hmath_context *context, ptrdiff_t a0, ptrdiff_t a1, const hmath_dense_matrix *a2, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_reshape_f64(hmath_context *context, ptrdiff_t a0, ptrdiff_t a1, const hmath_dense_matrix *a2, hmath_dense_matrix **out);
```

## `add_matrix`

`matrix.add_matrix(matrix, right)`

Original contract: [`HMath.Matrix.addMatrix`](haskell/HMath-Matrix.md#v:addMatrix). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `matrix` | Matrix of matching dtype |
| `right` | Matrix of matching dtype |

Returns an independently owned Matrix. A Nothing result becomes None / NULL (or found=0).

```c
hmath_status hmath_dense_add_matrix_f32(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_add_matrix_f64(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

## `subtract_matrix`

`matrix.subtract_matrix(matrix, right)`

Original contract: [`HMath.Matrix.subtractMatrix`](haskell/HMath-Matrix.md#v:subtractMatrix). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `matrix` | Matrix of matching dtype |
| `right` | Matrix of matching dtype |

Returns an independently owned Matrix. A Nothing result becomes None / NULL (or found=0).

```c
hmath_status hmath_dense_subtract_matrix_f32(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_subtract_matrix_f64(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

## `hadamard`

`matrix.hadamard(matrix, right)`

Original contract: [`HMath.Matrix.hadamard`](haskell/HMath-Matrix.md#v:hadamard). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `matrix` | Matrix of matching dtype |
| `right` | Matrix of matching dtype |

Returns an independently owned Matrix. A Nothing result becomes None / NULL (or found=0).

```c
hmath_status hmath_dense_hadamard_f32(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_hadamard_f64(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

## `multiply`

`matrix.multiply(matrix, right)`

Original contract: [`HMath.Matrix.multiply`](haskell/HMath-Matrix.md#v:multiply). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `matrix` | Matrix of matching dtype |
| `right` | Matrix of matching dtype |

Returns an independently owned Matrix. A Nothing result becomes None / NULL (or found=0).

```c
hmath_status hmath_dense_multiply_f32(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_multiply_f64(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

## `identity`

`matrix.identity(order, *, dtype="float64")`

Original contract: [`HMath.Matrix.identity`](haskell/HMath-Matrix.md#v:identity). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `order` | Haskell Int (C: ptrdiff_t) |
| `dtype` | float32 or float64; default float64 |

Returns an independently owned Matrix. A Nothing result becomes None / NULL (or found=0).

```c
hmath_status hmath_dense_identity_f32(hmath_context *context, ptrdiff_t a0, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_identity_f64(hmath_context *context, ptrdiff_t a0, hmath_dense_matrix **out);
```

## `from_list_checked`

`matrix.from_list_checked(rows, columns, values, *, dtype="float64")`

Original contract: [`HMath.Matrix.fromListChecked`](haskell/HMath-Matrix.md#v:fromListChecked). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `rows` | Haskell Int (C: ptrdiff_t) |
| `columns` | Haskell Int (C: ptrdiff_t) |
| `values` | finite-length sequence of elements (C: typed pointer + count) |
| `dtype` | float32 or float64; default float64 |

Returns an independently owned Matrix. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_from_list_checked_f32(hmath_context *context, ptrdiff_t a0, ptrdiff_t a1, const float *a2, size_t a2_count, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_from_list_checked_f64(hmath_context *context, ptrdiff_t a0, ptrdiff_t a1, const double *a2, size_t a2_count, hmath_dense_matrix **out);
```

## `zero_matrix_checked`

`matrix.zero_matrix_checked(rows, columns, *, dtype="float64")`

Original contract: [`HMath.Matrix.zeroMatrixChecked`](haskell/HMath-Matrix.md#v:zeroMatrixChecked). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `rows` | Haskell Int (C: ptrdiff_t) |
| `columns` | Haskell Int (C: ptrdiff_t) |
| `dtype` | float32 or float64; default float64 |

Returns an independently owned Matrix. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_zero_matrix_checked_f32(hmath_context *context, ptrdiff_t a0, ptrdiff_t a1, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_zero_matrix_checked_f64(hmath_context *context, ptrdiff_t a0, ptrdiff_t a1, hmath_dense_matrix **out);
```

## `diagonal_checked`

`matrix.diagonal_checked(values, *, dtype="float64")`

Original contract: [`HMath.Matrix.diagonalChecked`](haskell/HMath-Matrix.md#v:diagonalChecked). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `values` | finite-length sequence of elements (C: typed pointer + count) |
| `dtype` | float32 or float64; default float64 |

Returns an independently owned Matrix. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_diagonal_checked_f32(hmath_context *context, const float *a0, size_t a0_count, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_diagonal_checked_f64(hmath_context *context, const double *a0, size_t a0_count, hmath_dense_matrix **out);
```

## `at_checked`

`matrix.at_checked(matrix, row, column)`

Original contract: [`HMath.Matrix.atChecked`](haskell/HMath-Matrix.md#v:atChecked). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `matrix` | Matrix of matching dtype |
| `row` | Haskell Int (C: ptrdiff_t) |
| `column` | Haskell Int (C: ptrdiff_t) |

Returns a scalar. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_at_checked_f32(hmath_context *context, const hmath_dense_matrix *a0, ptrdiff_t a1, ptrdiff_t a2, float *out);
```

```c
hmath_status hmath_dense_at_checked_f64(hmath_context *context, const hmath_dense_matrix *a0, ptrdiff_t a1, ptrdiff_t a2, double *out);
```

## `slice_matrix_checked`

`matrix.slice_matrix_checked(start_row, start_column, rows, columns, matrix)`

Original contract: [`HMath.Matrix.sliceMatrixChecked`](haskell/HMath-Matrix.md#v:sliceMatrixChecked). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `start_row` | Haskell Int (C: ptrdiff_t) |
| `start_column` | Haskell Int (C: ptrdiff_t) |
| `rows` | Haskell Int (C: ptrdiff_t) |
| `columns` | Haskell Int (C: ptrdiff_t) |
| `matrix` | Matrix of matching dtype |

Returns an independently owned Matrix. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_slice_matrix_checked_f32(hmath_context *context, ptrdiff_t a0, ptrdiff_t a1, ptrdiff_t a2, ptrdiff_t a3, const hmath_dense_matrix *a4, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_slice_matrix_checked_f64(hmath_context *context, ptrdiff_t a0, ptrdiff_t a1, ptrdiff_t a2, ptrdiff_t a3, const hmath_dense_matrix *a4, hmath_dense_matrix **out);
```

## `reshape_checked`

`matrix.reshape_checked(rows, columns, matrix)`

Original contract: [`HMath.Matrix.reshapeChecked`](haskell/HMath-Matrix.md#v:reshapeChecked). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `rows` | Haskell Int (C: ptrdiff_t) |
| `columns` | Haskell Int (C: ptrdiff_t) |
| `matrix` | Matrix of matching dtype |

Returns an independently owned Matrix. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_reshape_checked_f32(hmath_context *context, ptrdiff_t a0, ptrdiff_t a1, const hmath_dense_matrix *a2, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_reshape_checked_f64(hmath_context *context, ptrdiff_t a0, ptrdiff_t a1, const hmath_dense_matrix *a2, hmath_dense_matrix **out);
```

## `add_matrix_checked`

`matrix.add_matrix_checked(matrix, right)`

Original contract: [`HMath.Matrix.addMatrixChecked`](haskell/HMath-Matrix.md#v:addMatrixChecked). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `matrix` | Matrix of matching dtype |
| `right` | Matrix of matching dtype |

Returns an independently owned Matrix. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_add_matrix_checked_f32(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_add_matrix_checked_f64(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

## `subtract_matrix_checked`

`matrix.subtract_matrix_checked(matrix, right)`

Original contract: [`HMath.Matrix.subtractMatrixChecked`](haskell/HMath-Matrix.md#v:subtractMatrixChecked). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `matrix` | Matrix of matching dtype |
| `right` | Matrix of matching dtype |

Returns an independently owned Matrix. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_subtract_matrix_checked_f32(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_subtract_matrix_checked_f64(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

## `hadamard_checked`

`matrix.hadamard_checked(matrix, right)`

Original contract: [`HMath.Matrix.hadamardChecked`](haskell/HMath-Matrix.md#v:hadamardChecked). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `matrix` | Matrix of matching dtype |
| `right` | Matrix of matching dtype |

Returns an independently owned Matrix. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_hadamard_checked_f32(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_hadamard_checked_f64(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

## `multiply_checked`

`matrix.multiply_checked(matrix, right)`

Original contract: [`HMath.Matrix.multiplyChecked`](haskell/HMath-Matrix.md#v:multiplyChecked). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `matrix` | Matrix of matching dtype |
| `right` | Matrix of matching dtype |

Returns an independently owned Matrix. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_multiply_checked_f32(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_multiply_checked_f64(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

## `identity_checked`

`matrix.identity_checked(order, *, dtype="float64")`

Original contract: [`HMath.Matrix.identityChecked`](haskell/HMath-Matrix.md#v:identityChecked). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `order` | Haskell Int (C: ptrdiff_t) |
| `dtype` | float32 or float64; default float64 |

Returns an independently owned Matrix. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_identity_checked_f32(hmath_context *context, ptrdiff_t a0, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_identity_checked_f64(hmath_context *context, ptrdiff_t a0, hmath_dense_matrix **out);
```

## `scale_matrix`

`matrix.scale_matrix(scalar, matrix)`

Original contract: [`HMath.Matrix.scaleMatrix`](haskell/HMath-Matrix.md#v:scaleMatrix). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `scalar` | scalar of matching dtype |
| `matrix` | Matrix of matching dtype |

Returns an independently owned Matrix.

```c
hmath_status hmath_dense_scale_matrix_f32(hmath_context *context, float a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_scale_matrix_f64(hmath_context *context, double a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

## `transpose_matrix`

`matrix.transpose_matrix(matrix)`

Original contract: [`HMath.Matrix.transposeMatrix`](haskell/HMath-Matrix.md#v:transposeMatrix). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `matrix` | Matrix of matching dtype |

Returns an independently owned Matrix.

```c
hmath_status hmath_dense_transpose_matrix_f32(hmath_context *context, const hmath_dense_matrix *a0, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_transpose_matrix_f64(hmath_context *context, const hmath_dense_matrix *a0, hmath_dense_matrix **out);
```

## `lu_decompose`

`matrix.lu_decompose(matrix)`

Original contract: [`HMath.Matrix.LU.luDecompose`](haskell/HMath-Matrix-LU.md#v:luDecompose). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `matrix` | Matrix of matching dtype |

Returns independently owned LU factors. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_lu_lu_decompose_f32(hmath_context *context, const hmath_dense_matrix *a0, hmath_dense_lu **out);
```

```c
hmath_status hmath_dense_lu_lu_decompose_f64(hmath_context *context, const hmath_dense_matrix *a0, hmath_dense_lu **out);
```

## `lu_decompose_with_tolerance`

`matrix.lu_decompose_with_tolerance(tolerance, matrix)`

Original contract: [`HMath.Matrix.LU.luDecomposeWithTolerance`](haskell/HMath-Matrix-LU.md#v:luDecomposeWithTolerance). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `tolerance` | scalar of matching dtype |
| `matrix` | Matrix of matching dtype |

Returns independently owned LU factors. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_lu_lu_decompose_with_tolerance_f32(hmath_context *context, float a0, const hmath_dense_matrix *a1, hmath_dense_lu **out);
```

```c
hmath_status hmath_dense_lu_lu_decompose_with_tolerance_f64(hmath_context *context, double a0, const hmath_dense_matrix *a1, hmath_dense_lu **out);
```

## `lu_lower`

`matrix.lu_lower(factors)`

Original contract: [`HMath.Matrix.LU.luLower`](haskell/HMath-Matrix-LU.md#v:luLower). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `factors` | LU factors of matching dtype |

Returns an independently owned Matrix.

```c
hmath_status hmath_dense_lu_lu_lower_f32(hmath_context *context, const hmath_dense_lu *a0, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_lu_lu_lower_f64(hmath_context *context, const hmath_dense_lu *a0, hmath_dense_matrix **out);
```

## `lu_upper`

`matrix.lu_upper(factors)`

Original contract: [`HMath.Matrix.LU.luUpper`](haskell/HMath-Matrix-LU.md#v:luUpper). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `factors` | LU factors of matching dtype |

Returns an independently owned Matrix.

```c
hmath_status hmath_dense_lu_lu_upper_f32(hmath_context *context, const hmath_dense_lu *a0, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_lu_lu_upper_f64(hmath_context *context, const hmath_dense_lu *a0, hmath_dense_matrix **out);
```

## `lu_permutation`

`matrix.lu_permutation(factors)`

Original contract: [`HMath.Matrix.LU.luPermutation`](haskell/HMath-Matrix-LU.md#v:luPermutation). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `factors` | LU factors of matching dtype |

Returns the original list of zero-based permutation indices.

```c
hmath_status hmath_dense_lu_lu_permutation_f32(hmath_context *context, const hmath_dense_lu *a0, hmath_dense_indices **out);
```

```c
hmath_status hmath_dense_lu_lu_permutation_f64(hmath_context *context, const hmath_dense_lu *a0, hmath_dense_indices **out);
```

## `solve_lu`

`matrix.solve_lu(factors, rhs)`

Original contract: [`HMath.Matrix.LU.solveLU`](haskell/HMath-Matrix-LU.md#v:solveLU). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `factors` | LU factors of matching dtype |
| `rhs` | finite-length sequence of elements (C: typed pointer + count) |

Returns the original list of solution elements. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_lu_solve_lu_f32(hmath_context *context, const hmath_dense_lu *a0, const float *a1, size_t a1_count, hmath_dense_vector **out);
```

```c
hmath_status hmath_dense_lu_solve_lu_f64(hmath_context *context, const hmath_dense_lu *a0, const double *a1, size_t a1_count, hmath_dense_vector **out);
```

## `solve_matrix_lu`

`matrix.solve_matrix_lu(factors, rhs)`

Original contract: [`HMath.Matrix.LU.solveMatrixLU`](haskell/HMath-Matrix-LU.md#v:solveMatrixLU). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `factors` | LU factors of matching dtype |
| `rhs` | Matrix of matching dtype |

Returns an independently owned Matrix. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_lu_solve_matrix_lu_f32(hmath_context *context, const hmath_dense_lu *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_lu_solve_matrix_lu_f64(hmath_context *context, const hmath_dense_lu *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

## `solve`

`matrix.solve(matrix, rhs)`

Original contract: [`HMath.Matrix.LU.solve`](haskell/HMath-Matrix-LU.md#v:solve). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `matrix` | Matrix of matching dtype |
| `rhs` | finite-length sequence of elements (C: typed pointer + count) |

Returns the original list of solution elements. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_lu_solve_f32(hmath_context *context, const hmath_dense_matrix *a0, const float *a1, size_t a1_count, hmath_dense_vector **out);
```

```c
hmath_status hmath_dense_lu_solve_f64(hmath_context *context, const hmath_dense_matrix *a0, const double *a1, size_t a1_count, hmath_dense_vector **out);
```

## `solve_matrix`

`matrix.solve_matrix(matrix, rhs)`

Original contract: [`HMath.Matrix.LU.solveMatrix`](haskell/HMath-Matrix-LU.md#v:solveMatrix). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `matrix` | Matrix of matching dtype |
| `rhs` | Matrix of matching dtype |

Returns an independently owned Matrix. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_lu_solve_matrix_f32(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_lu_solve_matrix_f64(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

## `determinant_lu`

`matrix.determinant_lu(factors)`

Original contract: [`HMath.Matrix.LU.determinantLU`](haskell/HMath-Matrix-LU.md#v:determinantLU). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `factors` | LU factors of matching dtype |

Returns a scalar. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_lu_determinant_lu_f32(hmath_context *context, const hmath_dense_lu *a0, float *out);
```

```c
hmath_status hmath_dense_lu_determinant_lu_f64(hmath_context *context, const hmath_dense_lu *a0, double *out);
```

## `determinant`

`matrix.determinant(matrix)`

Original contract: [`HMath.Matrix.LU.determinant`](haskell/HMath-Matrix-LU.md#v:determinant). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `matrix` | Matrix of matching dtype |

Returns a scalar. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_lu_determinant_f32(hmath_context *context, const hmath_dense_matrix *a0, float *out);
```

```c
hmath_status hmath_dense_lu_determinant_f64(hmath_context *context, const hmath_dense_matrix *a0, double *out);
```

## `inverse`

`matrix.inverse(matrix)`

Original contract: [`HMath.Matrix.LU.inverse`](haskell/HMath-Matrix-LU.md#v:inverse). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `matrix` | Matrix of matching dtype |

Returns an independently owned Matrix. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_lu_inverse_f32(hmath_context *context, const hmath_dense_matrix *a0, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_lu_inverse_f64(hmath_context *context, const hmath_dense_matrix *a0, hmath_dense_matrix **out);
```

## `qr_decompose`

`matrix.qr_decompose(matrix)`

Original contract: [`HMath.Matrix.QR.qrDecompose`](haskell/HMath-Matrix-QR.md#v:qrDecompose). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `matrix` | Matrix of matching dtype |

Returns independently owned QR factors. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_qr_qr_decompose_f32(hmath_context *context, const hmath_dense_matrix *a0, hmath_dense_qr **out);
```

```c
hmath_status hmath_dense_qr_qr_decompose_f64(hmath_context *context, const hmath_dense_matrix *a0, hmath_dense_qr **out);
```

## `qr_decompose_with_tolerance`

`matrix.qr_decompose_with_tolerance(tolerance, matrix)`

Original contract: [`HMath.Matrix.QR.qrDecomposeWithTolerance`](haskell/HMath-Matrix-QR.md#v:qrDecomposeWithTolerance). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `tolerance` | scalar of matching dtype |
| `matrix` | Matrix of matching dtype |

Returns independently owned QR factors. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_qr_qr_decompose_with_tolerance_f32(hmath_context *context, float a0, const hmath_dense_matrix *a1, hmath_dense_qr **out);
```

```c
hmath_status hmath_dense_qr_qr_decompose_with_tolerance_f64(hmath_context *context, double a0, const hmath_dense_matrix *a1, hmath_dense_qr **out);
```

## `qr_q`

`matrix.qr_q(factors)`

Original contract: [`HMath.Matrix.QR.qrQ`](haskell/HMath-Matrix-QR.md#v:qrQ). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `factors` | QR factors of matching dtype |

Returns an independently owned Matrix.

```c
hmath_status hmath_dense_qr_qr_q_f32(hmath_context *context, const hmath_dense_qr *a0, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_qr_qr_q_f64(hmath_context *context, const hmath_dense_qr *a0, hmath_dense_matrix **out);
```

## `qr_r`

`matrix.qr_r(factors)`

Original contract: [`HMath.Matrix.QR.qrR`](haskell/HMath-Matrix-QR.md#v:qrR). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `factors` | QR factors of matching dtype |

Returns an independently owned Matrix.

```c
hmath_status hmath_dense_qr_qr_r_f32(hmath_context *context, const hmath_dense_qr *a0, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_qr_qr_r_f64(hmath_context *context, const hmath_dense_qr *a0, hmath_dense_matrix **out);
```

## `qr_permutation`

`matrix.qr_permutation(factors)`

Original contract: [`HMath.Matrix.QR.qrPermutation`](haskell/HMath-Matrix-QR.md#v:qrPermutation). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `factors` | QR factors of matching dtype |

Returns the original list of zero-based permutation indices.

```c
hmath_status hmath_dense_qr_qr_permutation_f32(hmath_context *context, const hmath_dense_qr *a0, hmath_dense_indices **out);
```

```c
hmath_status hmath_dense_qr_qr_permutation_f64(hmath_context *context, const hmath_dense_qr *a0, hmath_dense_indices **out);
```

## `qr_rank`

`matrix.qr_rank(factors)`

Original contract: [`HMath.Matrix.QR.qrRank`](haskell/HMath-Matrix-QR.md#v:qrRank). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `factors` | QR factors of matching dtype |

Returns an integer.

```c
hmath_status hmath_dense_qr_qr_rank_f32(hmath_context *context, const hmath_dense_qr *a0, ptrdiff_t *out);
```

```c
hmath_status hmath_dense_qr_qr_rank_f64(hmath_context *context, const hmath_dense_qr *a0, ptrdiff_t *out);
```

## `apply_q`

`matrix.apply_q(factors, rhs)`

Original contract: [`HMath.Matrix.QR.applyQ`](haskell/HMath-Matrix-QR.md#v:applyQ). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `factors` | QR factors of matching dtype |
| `rhs` | Matrix of matching dtype |

Returns an independently owned Matrix. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_qr_apply_q_f32(hmath_context *context, const hmath_dense_qr *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_qr_apply_q_f64(hmath_context *context, const hmath_dense_qr *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

## `apply_qt`

`matrix.apply_qt(factors, rhs)`

Original contract: [`HMath.Matrix.QR.applyQT`](haskell/HMath-Matrix-QR.md#v:applyQT). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `factors` | QR factors of matching dtype |
| `rhs` | Matrix of matching dtype |

Returns an independently owned Matrix. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_qr_apply_qt_f32(hmath_context *context, const hmath_dense_qr *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_qr_apply_qt_f64(hmath_context *context, const hmath_dense_qr *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

## `solve_matrix_qr`

`matrix.solve_matrix_qr(factors, rhs)`

Original contract: [`HMath.Matrix.QR.solveMatrixQR`](haskell/HMath-Matrix-QR.md#v:solveMatrixQR). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `factors` | QR factors of matching dtype |
| `rhs` | Matrix of matching dtype |

Returns an independently owned Matrix. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_qr_solve_matrix_qr_f32(hmath_context *context, const hmath_dense_qr *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_qr_solve_matrix_qr_f64(hmath_context *context, const hmath_dense_qr *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

## `solve_qr`

`matrix.solve_qr(factors, rhs)`

Original contract: [`HMath.Matrix.QR.solveQR`](haskell/HMath-Matrix-QR.md#v:solveQR). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `factors` | QR factors of matching dtype |
| `rhs` | finite-length sequence of elements (C: typed pointer + count) |

Returns the original list of solution elements. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_qr_solve_qr_f32(hmath_context *context, const hmath_dense_qr *a0, const float *a1, size_t a1_count, hmath_dense_vector **out);
```

```c
hmath_status hmath_dense_qr_solve_qr_f64(hmath_context *context, const hmath_dense_qr *a0, const double *a1, size_t a1_count, hmath_dense_vector **out);
```

## `least_squares`

`matrix.least_squares(matrix, rhs)`

Original contract: [`HMath.Matrix.QR.leastSquares`](haskell/HMath-Matrix-QR.md#v:leastSquares). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `matrix` | Matrix of matching dtype |
| `rhs` | finite-length sequence of elements (C: typed pointer + count) |

Returns the original list of solution elements. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_qr_least_squares_f32(hmath_context *context, const hmath_dense_matrix *a0, const float *a1, size_t a1_count, hmath_dense_vector **out);
```

```c
hmath_status hmath_dense_qr_least_squares_f64(hmath_context *context, const hmath_dense_matrix *a0, const double *a1, size_t a1_count, hmath_dense_vector **out);
```

## `least_squares_matrix`

`matrix.least_squares_matrix(matrix, rhs)`

Original contract: [`HMath.Matrix.QR.leastSquaresMatrix`](haskell/HMath-Matrix-QR.md#v:leastSquaresMatrix). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `matrix` | Matrix of matching dtype |
| `rhs` | Matrix of matching dtype |

Returns an independently owned Matrix. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_qr_least_squares_matrix_f32(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_qr_least_squares_matrix_f64(hmath_context *context, const hmath_dense_matrix *a0, const hmath_dense_matrix *a1, hmath_dense_matrix **out);
```

## `ridge_solve`

`matrix.ridge_solve(lambda_, matrix, rhs)`

Original contract: [`HMath.Matrix.QR.ridgeSolve`](haskell/HMath-Matrix-QR.md#v:ridgeSolve). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `lambda_` | scalar of matching dtype |
| `matrix` | Matrix of matching dtype |
| `rhs` | finite-length sequence of elements (C: typed pointer + count) |

Returns the original list of solution elements. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_qr_ridge_solve_f32(hmath_context *context, float a0, const hmath_dense_matrix *a1, const float *a2, size_t a2_count, hmath_dense_vector **out);
```

```c
hmath_status hmath_dense_qr_ridge_solve_f64(hmath_context *context, double a0, const hmath_dense_matrix *a1, const double *a2, size_t a2_count, hmath_dense_vector **out);
```

## `ridge_solve_matrix`

`matrix.ridge_solve_matrix(lambda_, matrix, rhs)`

Original contract: [`HMath.Matrix.QR.ridgeSolveMatrix`](haskell/HMath-Matrix-QR.md#v:ridgeSolveMatrix). This defines the computation, boundary conditions, failure order and numerical policy.

| Parameter | Type |
| --- | --- |
| `lambda_` | scalar of matching dtype |
| `matrix` | Matrix of matching dtype |
| `rhs` | Matrix of matching dtype |

Returns an independently owned Matrix. A Left MathError raises/returns the original error.

```c
hmath_status hmath_dense_qr_ridge_solve_matrix_f32(hmath_context *context, float a0, const hmath_dense_matrix *a1, const hmath_dense_matrix *a2, hmath_dense_matrix **out);
```

```c
hmath_status hmath_dense_qr_ridge_solve_matrix_f64(hmath_context *context, double a0, const hmath_dense_matrix *a1, const hmath_dense_matrix *a2, hmath_dense_matrix **out);
```

