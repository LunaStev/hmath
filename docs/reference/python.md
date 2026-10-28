# Python API

Import the primary interface with `import hmath`. Values are finite IEEE 754
binary64 numbers. Tensors are immutable; operations return new owned tensors.

## Functions and exceptions

| API | Result and contract |
| --- | --- |
| `add(a, b) -> float` | Add two finite scalar values; initialize the runtime automatically. |
| `initialize() -> None` | Idempotent initialization; ordinary tensor operations already call it. |
| `shutdown() -> None` | Final process-owner operation; join workers first. Cannot reinitialize afterward. |
| `HMathError(status)` | Native checked-operation failure; `.status` contains the integer C status code and the message describes the failure. |

Python shape validation raises `ValueError`. Native validation and arithmetic
failures raise `HMathError`; use-after-close and final shutdown errors raise
`RuntimeError`. Numeric conversion can raise ordinary Python conversion errors.

## Tensor construction

| Signature | Result and constraints |
| --- | --- |
| `Tensor(values, shape=None)` | Copy an iterable into native storage; default shape is `(len(values),)`. Explicit shape must have exactly the supplied number of elements. |
| `Tensor.scalar(value)` | Scalar with rank zero and shape `()`. |
| `Tensor.matrix(values, rows, columns)` | Rank-two matrix, with values in row-major order. |
| `Tensor.from_numpy(array, copy=True)` | Preserve shape and copy values into binary64 storage. With `copy=False`, borrow suitable read-only NumPy storage. |

Native limits are rank **8** and **1,048,576** elements. Each dimension must
be a nonnegative integer; zero-length dimensions are allowed. A scalar has
one value. Non-finite input is rejected. See the [NumPy guide](../guides/numpy.md)
for borrowing constraints and alias ownership.

## Tensor operations

| API | Return value and behavior |
| --- | --- |
| `tensor.shape` | Tuple of dimensions. |
| `tensor.values()` | Independent Python list of floats in row-major traversal order. |
| `tensor.numpy(copy=True)` | NumPy array of the same shape; an independent copy by default. With `copy=False`, a read-only native view retaining storage ownership. |
| `tensor.sum()` | Scalar sum of elements. |
| `tensor.dot(other)` | Scalar sum of elementwise products; inputs require identical shapes. |
| `tensor + other` | Elementwise addition; inputs require identical shapes. No broadcasting. |
| `tensor @ other` | Rank-two dense matrix multiplication, with matching inner dimensions. Work is limited to 16,777,216 scalar multiply-add steps. |
| `tensor.reshape(shape)` | New handle sharing the same storage; requires contiguous input and unchanged element count. |
| `tensor.close()` | Release this handle. Repeated calls are allowed. Other retained owners remain valid. |

Use context managers for deterministic cleanup:

```python
from hmath import Tensor

with Tensor([1, 2, 3]) as a, Tensor([4, 5, 6]) as b:
    assert a.dot(b) == 32.0
    with a + b as result:
        assert result.values() == [5.0, 7.0, 9.0]
```

## cffi interface

The optional `hmath_cffi` module provides `add`, `HMathError`, and `Tensor`.
Its tensor API includes the iterable constructor, `values`, `sum`, `dot`,
`+`, `@`, `close`, and context-manager cleanup. Its `.shape` is the stored
shape tuple. NumPy conversion, `reshape`, and the convenience `scalar` and
`matrix` constructors belong to the primary ctypes interface.

Do not close a cffi tensor concurrently with an operation on that tensor.
Both wrappers load the same bundled C library and share its runtime.

## Native status codes

| Code | Name | Meaning |
| --- | --- | --- |
| 0 | `HMATH_OK` | Success |
| 1 | `HMATH_INVALID_ARGUMENT` | Invalid argument |
| 2 | `HMATH_SHAPE_ERROR` | Invalid or incompatible dimensions |
| 3 | `HMATH_OVERFLOW` | Arithmetic or size overflow |
| 4 | `HMATH_ALLOCATION_FAILED` | Allocation failed |
| 5 | `HMATH_RUNTIME_ERROR` | Runtime unavailable |
| 6 | `HMATH_HASKELL_EXCEPTION` | Contained Haskell exception |
| 7 | `HMATH_CANCELLED` | Cooperative cancellation |
| 8 | `HMATH_BOUNDS_ERROR` | Buffer or metadata bounds error |
| 9 | `HMATH_BUSY` | Active work prevents shutdown |
| 10 | `HMATH_UNSUPPORTED` | Unsupported operation |
