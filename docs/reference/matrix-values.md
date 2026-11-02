# Exact and complex matrices

The `hmath.matrix` core supports Float, Double, arbitrary Integer, exact Rational, Complex Float, Complex Double, and the standard bounded integral types. Constructors select the coefficient type with `dtype`; binary operations require matching types. Arithmetic calls the original Haskell `HMath.Matrix` functions with that coefficient instance. Bounded integral arithmetic therefore retains the original Haskell wrapping behavior, while constructing an out-of-range scalar reports a representation error.

```python
from fractions import Fraction
from hmath import matrix
from hmath import polynomial

p = polynomial.polynomial([1, Fraction(1, 3), 2], dtype="rational")
a = polynomial.companion_matrix(p)
p.close()
b = matrix.multiply_checked(a, a)
assert a.dtype == "rational"
assert all(isinstance(x, Fraction) for x in b.to_list())
a.close()
b.close()
```

Companion matrices keep their coefficient type and are ordinary `matrix.Matrix` instances. Exact and complex matrices support the same core constructors, shape/list inspection, indexing, slicing, reshape, addition, subtraction, Hadamard product, scalar multiplication, matrix multiplication, transpose and identity functions described in [Matrix bindings](matrix-bindings.md). `Maybe` functions return `None` on their original failures; `Checked` functions raise the original `MathError`. The original zero-dimension shapes, exact size-overflow checks, arithmetic order and behavior for NaN/Inf remain unchanged. No fixed tensor element or operation cap is added to the pure Matrix API.

LU and QR require the original `RealFloat` coefficient instance. Their supported coefficient types remain Float and Double. Calling those decompositions on an exact or complex Matrix is rejected before entering an unsupported specialization.

## C representation

Include `hmath_matrix_value.h` and `hmath_value.h`. The generic functions use owned immutable `hmath_value` matrices with `kind == 9`; `hmath_value_info` reports the coefficient dtype and element count. Use common scalar/list/tuple constructors for arguments. Constructors take a typed scalar `prototype` first to preserve the type of an empty matrix. Every returned handle must be released with `hmath_value_release`; inputs are borrowed only for the call. A successful output owns an independent reference, including after all input handles are closed. Failure leaves the output pointer untouched.

`hmath_dense_to_value` exports an existing Float/Double `hmath_dense_matrix` without copying its mathematical storage or changing its type. `hmath_dense_from_value` imports a Float/Double Value matrix into an existing typed Matrix owner. Exact and complex matrices stay in the generic representation and use `hmath_matrix_value_*`. These representation bridges retain the original Haskell immutable matrix; they do not serialize/reparse coefficients or convert through FP64.

The C function suffixes correspond directly to the Python functions and source operations:

| Source operation | Generic C entry point | Result Value |
| --- | --- | --- |
| `fromList`, `fromListChecked` | `hmath_matrix_value_from_list[_checked]` | Matrix or None / Matrix or original error |
| `zeroMatrix`, `zeroMatrixChecked` | `hmath_matrix_value_zero_matrix[_checked]` | Matrix or None / Matrix or original error |
| `diagonal`, `diagonalChecked` | `hmath_matrix_value_diagonal[_checked]` | Matrix or None / Matrix or original error |
| `at`, `atChecked` | `hmath_matrix_value_at[_checked]` | coefficient or None / coefficient or original error |
| `sliceMatrix`, `sliceMatrixChecked` | `hmath_matrix_value_slice_matrix[_checked]` | Matrix or None / Matrix or original error |
| `reshape`, `reshapeChecked` | `hmath_matrix_value_reshape[_checked]` | Matrix or None / Matrix or original error |
| `addMatrix`, `addMatrixChecked` | `hmath_matrix_value_add_matrix[_checked]` | Matrix or None / Matrix or original error |
| `subtractMatrix`, `subtractMatrixChecked` | `hmath_matrix_value_subtract_matrix[_checked]` | Matrix or None / Matrix or original error |
| `hadamard`, `hadamardChecked` | `hmath_matrix_value_hadamard[_checked]` | Matrix or None / Matrix or original error |
| `multiply`, `multiplyChecked` | `hmath_matrix_value_multiply[_checked]` | Matrix or None / Matrix or original error |
| `identity`, `identityChecked` | `hmath_matrix_value_identity[_checked]` | Matrix or None / Matrix or original error |
| `scaleMatrix` | `hmath_matrix_value_scale_matrix` | Matrix |
| `transposeMatrix` | `hmath_matrix_value_transpose_matrix` | Matrix |
| `toList` | `hmath_matrix_value_to_list` | scalar list |
| `shape` | `hmath_matrix_value_shape` | (rows, columns) Index tuple |

Every original argument appears in source order after `context`; constructor `prototype` precedes those arguments and an owned `hmath_value **out` follows them. Slice origin and extent pairs are flattened to `start_row, start_column, rows, columns`, matching the existing typed C binding. The header declares each exact signature.

## Bool and String structure

`dtype="bool"` and `dtype="string"` create actual Haskell `Matrix Bool` and `Matrix String` values. `from_list`, `from_list_checked`, `at`, `at_checked`, slicing, reshape, transpose, shape and list inspection keep their original values and error conventions. Strings preserve Unicode codepoints, embedded NUL and surrogate Char values. Bool/String matrices report dtype codes 16/17, matching the typed Tensor element codes.

```python
from hmath import matrix
with matrix.from_list_checked(1, 2, [True, False], dtype="bool") as flags:
    column = matrix.transpose_matrix(flags)
assert column.shape == (2, 1)
assert column.to_list() == [True, False]
column.close()
```

These element types have no original `Num` instance. Zero/identity/diagonal construction and arithmetic therefore return `HMATH_UNSUPPORTED`; the binding does not invent Boolean addition/multiplication or String numeric conversions. C structural constructors use a Boolean/Text prototype with ordinary Boolean/Text element Values. The internal structural codec also lets other non-Num domains retain their original Matrix element type without converting through a numeric dtype.
