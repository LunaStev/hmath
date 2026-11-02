# Structured mathematical errors

Checked Haskell APIs return `Either MathError a`. The C ABI reports those
failures as `HMATH_MATH_ERROR` (status 11); Python raises `hmath.HMathError` with
the complete original value in its `.math_error` attribute. A transport failure
(such as a NULL pointer or allocation failure) has a different status and no
`MathError` payload.

```python
from hmath import HMathError, errors, optimization

try:
    optimization.checked_gradient(lambda point: [], [1.0])
except HMathError as failure:
    error = failure.math_error
    assert error.kind == errors.MathErrorKind.VECTOR_LENGTH_MISMATCH
    assert error.details == (1, 0)
```

`hmath.errors.MathError(kind, details=(), message="")` stores the constructor,
its ordered integer fields and its full string payload. The named constructors
below provide the original argument grouping. Integer fields must fit Haskell
`Int` (`ptrdiff_t` in the supported C ABI); they are never converted through a
floating-point number. Shapes and matrix indices are `(rows, columns)` pairs,
and indices are zero based.

| Python constructor | C `kind` constant | `details` in order | `message` |
| --- | --- | --- | --- |
| `NegativeDimensions(shape)` | `HMATH_MATH_NEGATIVE_DIMENSIONS` | rows, columns | empty |
| `ElementCountOverflow(shape)` | `HMATH_MATH_ELEMENT_COUNT_OVERFLOW` | rows, columns | empty |
| `ElementCountMismatch(expected, actual)` | `HMATH_MATH_ELEMENT_COUNT_MISMATCH` | expected, actual | empty |
| `ShapeMismatch(left, right)` | `HMATH_MATH_SHAPE_MISMATCH` | left rows, left columns, right rows, right columns | empty |
| `InnerDimensionMismatch(left_columns, right_rows)` | `HMATH_MATH_INNER_DIMENSION_MISMATCH` | left columns, right rows | empty |
| `IndexOutOfBounds(shape, index)` | `HMATH_MATH_INDEX_OUT_OF_BOUNDS` | shape rows, shape columns, row, column | empty |
| `SliceOutOfBounds(shape, start, extent)` | `HMATH_MATH_SLICE_OUT_OF_BOUNDS` | shape rows, shape columns, start row, start column, extent rows, extent columns | empty |
| `VectorLengthMismatch(expected, actual)` | `HMATH_MATH_VECTOR_LENGTH_MISMATCH` | expected, actual | empty |
| `NonSquareMatrix(shape)` | `HMATH_MATH_NON_SQUARE_MATRIX` | rows, columns | empty |
| `InvalidTolerance()` | `HMATH_MATH_INVALID_TOLERANCE` | none | empty |
| `SingularMatrix(index)` | `HMATH_MATH_SINGULAR_MATRIX` | pivot index | empty |
| `NearSingularMatrix(index)` | `HMATH_MATH_NEAR_SINGULAR_MATRIX` | pivot index | empty |
| `NonFiniteMatrixEntry(index)` | `HMATH_MATH_NON_FINITE_MATRIX_ENTRY` | row, column | empty |
| `NonFiniteVectorEntry(index)` | `HMATH_MATH_NON_FINITE_VECTOR_ENTRY` | index | empty |
| `NonFiniteResult()` | `HMATH_MATH_NON_FINITE_RESULT` | none | empty |
| `RightHandSideMismatch(expected, actual)` | `HMATH_MATH_RIGHT_HAND_SIDE_MISMATCH` | expected, actual | empty |
| `DomainError(message)` | `HMATH_MATH_DOMAIN_ERROR` | none | original string |
| `InvalidArgument(message)` | `HMATH_MATH_INVALID_ARGUMENT` | none | original string |
| `NonConvergence(algorithm, iterations)` | `HMATH_MATH_NON_CONVERGENCE` | iterations | algorithm string |
| `RankDeficient(rank)` | `HMATH_MATH_RANK_DEFICIENT` | rank | empty |
| `NotPositiveDefinite(index)` | `HMATH_MATH_NOT_POSITIVE_DEFINITE` | index | empty |

The defining Haskell type is [MathError](haskell/HMath-Error.md#t:MathError).
The condition that produces each error remains the condition in the original
function. The adapter does not add finite-value checks or replace a solver's
own recovery decisions.

## Checked callbacks

Return the ordinary successful Python value from a checked callback. Raise one
of the constructors above to return an original Haskell `Left`:

```python
from hmath import errors, optimization


def objective(point):
    if point[0] <= 0:
        raise errors.DomainError("positive point required")
    return point[0] * point[0]


value = optimization.checked_value(objective, [2.0])
```

A solver receives that `Left` and follows its original algorithm. For example,
feasible barrier backtracking can reject a `DomainError` trial and retry a
shorter step. Unexpected Python exceptions abort the call and are re-raised as
the same Python exception after native temporary objects are released. For a
source callback whose type is pure rather than `Either`, a raised `MathError`
becomes a checked failure at the outer ABI boundary.

## C and C++

Include `hmath_error.h`. The transport is a fixed-layout record:

```c
typedef struct hmath_math_error {
    uint32_t kind;
    ptrdiff_t details[6];
    const char *message;
    size_t message_length;
} hmath_math_error;
```

Fill `kind`, the used `details` entries and the optional message when returning
`HMATH_MATH_ERROR` from a checked callback. The message buffer is borrowed until
the callback result is consumed. An explicit length preserves embedded NUL;
use UTF-8, with the surrogatepass/WTF-8 extension if transporting isolated
Haskell surrogate `Char` values. Unused fields are ignored for constructors
that have no corresponding source payload. Invalid constructor tags or invalid
encoded strings produce a transport failure.

`int hmath_last_math_error(hmath_math_error *out)` returns 1 when the current
thread has a complete mathematical failure, otherwise 0. It is a query and
does not clear or consume the last error. Its message is borrowed library memory
until the next checked operation on that thread: copy it before another API
call. The library owns a full dynamic copy, including long strings; the short
human-readable `hmath_last_error()` message is not a substitute for this
structured payload. Successful checked operations and nonmathematical failures
clear the structured error. Thread exit and normal clearing release its storage
in C without calling the Haskell runtime.
