# Python API

`hmath` is the primary interface. Calculations use finite IEEE 754 binary64
values. Tensors are immutable and do not broadcast implicitly. NumPy is needed
only for the conversion methods. All examples below run in documentation checks.

## Common contracts

- Shapes contain at most **8** nonnegative Python integers (not booleans).
  Each dimension and the total size are bounded by **1,048,576**. Empty
  dimensions are supported. Shape `()` is a scalar with exactly one value.
- Use `with` or `close()` to release each owned tensor. Closing one handle
  preserves independent retained handles and NumPy views.
- Native failures raise `HMathError`. Shape validation raises `ValueError`;
  use after close raises `RuntimeError`. Numeric conversion can also raise
  Python `TypeError`, `ValueError`, or `OverflowError`.
- Primary-interface methods synchronize access to tensor handles. Prevent
  concurrent close/use yourself when using the optional cffi interface.

## Module functions

### `hmath.initialize()`

**Parameters:** none. Initialize the process-wide runtime; repeated calls are
allowed. Constructors and `add()` already do this automatically.
**Returns:** `None`. **Raises:** `RuntimeError` for ABI incompatibility or
an irreversibly shut down runtime.

```python
from hmath import initialize
initialize()
initialize()
```

### `hmath.add(a, b)`

**Parameters:** two finite real scalars convertible to C `double`.
**Returns:** their sum as a Python `float`, initializing the runtime if needed.
**Raises:** `HMathError` for non-finite input/result, or runtime/conversion errors.

```python
from hmath import add
assert add(2, 3.5) == 5.5
```

### `hmath.shutdown()`

**Parameters:** none. Only the process owner should call this after joining
all numerical users and releasing their resources. Applications can instead
allow process exit to clean up the runtime.
**Returns:** `None`. **Raises:** `HMathError` with status 9 while work is active;
join workers and retry. Successful shutdown is **irreversible**.

Example, as the last operation of a dedicated process (not run in shared tests):

```text
from hmath import shutdown
shutdown()
```

### `hmath.HMathError(status)`

**Parameters:** the integer status from a failed checked C call.
**Returns:** a `RuntimeError` subclass instance with `.status` and a snapshot
of the calling thread's native diagnostic in `str(error)`. Catch exceptions
raised by operations rather than constructing this manually.

```python
from hmath import HMathError, Tensor
try:
    Tensor([1, 2], (3,))
except HMathError as error:
    assert error.status == 2
```

## Construction

### `hmath.Tensor(values, shape=None)`

**Parameters:** `values`: finite numeric iterable in flat row-major order;
`shape`: optional iterable of dimensions, defaulting to `(len(values),)`.
Values are copied, so later changes to the input do not affect the tensor.
At most 1,048,577 entries are consumed before oversized input is rejected.
**Returns:** a new owned tensor. **Raises:** `ValueError` for Python shape/size
bounds; `HMathError` for mismatched element count, non-finite input, or allocation
failure; ordinary numeric conversion errors may also occur.

```python
with Tensor([1, 2, 3, 4], (2, 2)) as matrix:
    assert matrix.shape == (2, 2)
    assert matrix.values() == [1., 2., 3., 4.]
```

### `hmath.Tensor.scalar(value)`

**Parameters:** one finite real value. **Returns:** a new owned rank-zero tensor
with shape `()`. **Raises:** the constructor's conversion and native errors.

```python
with Tensor.scalar(7) as scalar:
    assert scalar.shape == ()
    assert scalar.values() == [7.0]
```

### `hmath.Tensor.matrix(values, rows, columns)`

**Parameters:** flat row-major values and two nonnegative integer dimensions;
exactly `rows * columns` values are required.
**Returns:** a new owned rank-two tensor. **Raises:** constructor errors.

```python
with Tensor.matrix([1, 2, 3, 4, 5, 6], 2, 3) as matrix:
    assert matrix.shape == (2, 3)
```

### `hmath.Tensor.from_numpy(array, copy=True)`

**Parameters:** `array`: NumPy array or array-like input; `copy`: whether to copy.
With `True`, convert to `float64` and copy in row-major order. With `False`,
borrow aligned, native-endian, **read-only** `float64` storage with nonnegative
strides divisible by eight bytes. The tensor keeps the array alive. The caller
must prevent writes through every alias until all borrowed tensors/views die.
**Returns:** an owned tensor preserving shape. **Raises:** `ImportError` without
NumPy, `ValueError` for borrowing/rank/size violations, or `HMathError` for native
storage validation, non-finite data, or allocation failures.

```python
import numpy as np
array = np.array([[1., 2.], [3., 4.]])
array.setflags(write=False)
with Tensor.from_numpy(array, copy=False) as tensor:
    assert tensor.sum() == 10.0
```

## Inspection and conversion

### `hmath.Tensor.shape`

**Parameters:** none; read-only property. **Returns:** a tuple of dimensions,
including `()` for scalars. **Raises:** `RuntimeError` after close or
`HMathError` if native metadata retrieval fails.

```python
with Tensor([], (0, 3)) as empty:
    assert empty.shape == (0, 3)
```

### `hmath.Tensor.values()`

**Parameters:** none. **Returns:** an independent flat `list[float]` in logical
row-major order, including for strided input; `[]` for empty tensors.
**Raises:** closed-handle or native copy errors.

```python
with Tensor([2, 4]) as tensor:
    values = tensor.values()
values[0] = 99  # Independent list remains usable after close.
```

### `hmath.Tensor.numpy(copy=True)`

**Parameters:** `copy`: `True` for a writable independent copy, `False` for a
read-only native view with the tensor's shape and strides. Views retain storage
and borrowed owners even after this tensor closes. Do not mutate borrowed aliases.
**Returns:** `numpy.ndarray` of `float64`. **Raises:** `ImportError` without NumPy,
closed-handle errors, or native metadata/data errors.

```python
with Tensor([1, 2, 3]) as tensor:
    view = tensor.numpy(copy=False)
assert view.tolist() == [1., 2., 3.]
assert not view.flags.writeable
del view
```

## Calculations

### `hmath.Tensor.sum()`

**Parameters:** none. Sum every logical element, regardless of rank.
**Returns:** a `float`, or `0.0` for an empty tensor.
**Raises:** closed-handle errors or native arithmetic/runtime errors, including
non-finite results.

```python
with Tensor([1, 2, 3]) as tensor:
    assert tensor.sum() == 6.0
```

### `hmath.Tensor.dot(other)`

**Parameters:** a live tensor with exactly the same shape. Sum corresponding
products over the entire tensor; this is a scalar reduction at every rank.
**Returns:** a `float`, or `0.0` for matching empty tensors.
**Raises:** `HMathError` for shape/arithmetic/runtime errors; closed operands
raise `RuntimeError`.

```python
with Tensor([1, 2, 3]) as a, Tensor([4, 5, 6]) as b:
    assert a.dot(b) == 32.0
```

### `hmath.Tensor.__add__(other)` — `a + b`

**Parameters:** another live tensor with identical shape; no broadcasting.
**Returns:** a new owned tensor of elementwise sums. Inputs are unchanged.
**Raises:** native shape/allocation/arithmetic/runtime or closed-handle errors.

```python
with Tensor([1, 2]) as a, Tensor([3, 4]) as b:
    with a + b as result:
        assert result.values() == [4., 6.]
```

### `hmath.Tensor.__matmul__(other)` — `a @ b`

**Parameters:** a live rank-two tensor. Shapes `(m, k)` and `(k, n)` produce
`(m, n)`. Work is bounded by **16,777,216** scalar multiply-add steps (`m*k*n`).
This binding does not expose batched multiplication.
**Returns:** a new owned matrix. **Raises:** native rank/inner-dimension,
size/work budget, allocation, arithmetic/runtime, or closed-handle errors.

```python
with Tensor.matrix([1, 2, 3, 4], 2, 2) as a:
    with a @ a as squared:
        assert squared.values() == [7., 10., 15., 22.]
```

### `hmath.Tensor.reshape(shape)`

**Parameters:** new dimensions with unchanged element count. Storage must be
contiguous. Negative dimensions, including `-1` for inference, are unsupported.
**Returns:** a new owned handle sharing storage; both handles can close independently.
**Raises:** `ValueError` for invalid dimensions, `HMathError` for incompatible
count or non-contiguous input, or `RuntimeError` after close.

```python
with Tensor([1, 2, 3, 4]) as flat:
    reshaped = flat.reshape((2, 2))
with reshaped:
    assert reshaped.shape == (2, 2)
```

## Lifetime protocol

### `hmath.Tensor.close()`

**Parameters:** none. Release this handle's native reference and borrowed owner.
**Returns:** `None`; repeated calls are harmless. Other retained handles/views
remain valid. Using this closed handle raises `RuntimeError`.

```python
tensor = Tensor([1])
tensor.close()
tensor.close()
```

### `hmath.Tensor.__enter__()`

**Parameters:** none. **Returns:** the same live tensor for a `with` block;
this creates no additional reference. **Raises:** `RuntimeError` after close.
See the context-manager examples above.

### `hmath.Tensor.__exit__(*args)`

**Parameters:** Python's context-manager exception triple.
**Returns:** `None`, closing the tensor on normal or exceptional block exit
without suppressing the exception. See the context-manager examples above.

### `hmath.Tensor.__del__()`

**Parameters:** none. **Returns:** `None`, calling `close()` as a finalization
fallback. Collection timing is unspecified; use `with` for deterministic cleanup.

## Optional cffi interface

Install `hmath-python[cffi]` to use `hmath_cffi`. Both wrappers share the native
runtime. Prevent concurrent close/use of a cffi tensor. NumPy conversion,
`reshape`, `scalar`, and `matrix` constructors belong to the primary interface.

### `hmath_cffi.add(a, b)`

**Parameters:** two finite real scalars. **Returns:** their binary64 sum as a
Python float. **Raises:** `hmath_cffi.HMathError` for native failures or ordinary
conversion errors. Import initializes the runtime and checks ABI 1.

```python
import hmath_cffi as hc
assert hc.add(2, 3) == 5.0
```

### `hmath_cffi.HMathError(status)`

**Parameters:** native status integer. **Returns:** an exception with `.status`
and a snapshot of the current native error message. Catch this class for cffi
errors; it is a separate class from `hmath.HMathError`.

### `hmath_cffi.check(status)`

**Parameters:** status from a raw checked C call. **Returns:** `None` for zero.
**Raises:** `hmath_cffi.HMathError` for nonzero. Call immediately after the raw
call so its thread-local error message has not been replaced.

### `hmath_cffi.Tensor(values, shape=None)`

**Parameters:** flat finite numeric iterable and optional dimensions, following
primary constructor limits. **Returns:** an owned cffi tensor with `.shape`
stored as a tuple. **Raises:** `ValueError` for Python bounds,
`hmath_cffi.HMathError` for native input/allocation errors, or conversion errors.

```python
with hc.Tensor([1, 2, 3, 4], (2, 2)) as a:
    assert a.shape == (2, 2)
    with a @ a as result:
        assert result.values() == [7., 10., 15., 22.]
```

### `hmath_cffi.Tensor.values()`

**Parameters:** none. **Returns:** an independent row-major `list[float]`.
**Raises:** `RuntimeError` after close or `hmath_cffi.HMathError` on copy failure.
Use `.values()` inside the context-manager example above.

### `hmath_cffi.Tensor.sum()`

**Parameters:** none. **Returns:** scalar sum, or `0.0` for an empty tensor.
**Raises:** native arithmetic/runtime or closed-handle errors. For example,
`hc.Tensor([1, 2])` sums to `3.0`; close the owner after use.

### `hmath_cffi.Tensor.dot(other)`

**Parameters:** a live cffi tensor with identical shape. **Returns:** scalar sum
of elementwise products. **Raises:** native shape/arithmetic/runtime or
closed-handle errors. The primary interface's dot example also applies to cffi.

### `hmath_cffi.Tensor.__add__(other)` — `a + b`

**Parameters:** a live cffi tensor of identical shape. **Returns:** a new owned
elementwise sum without broadcasting. **Raises:** native shape/allocation/
arithmetic/runtime or closed-handle errors. Use with `with a + b as result:`.

### `hmath_cffi.Tensor.__matmul__(other)` — `a @ b`

**Parameters:** a live cffi tensor with compatible rank-two dimensions.
**Returns:** a new owned matrix. **Raises:** the same shape/work-bound and
native/lifecycle errors as primary `@`. See the executable cffi example above.

### `hmath_cffi.Tensor.close()`

**Parameters:** none. **Returns:** `None`, releasing its cffi-managed reference.
Repeated calls are harmless. Do not close concurrently with an operation on
this tensor. Other independent owners remain valid.

### `hmath_cffi.Tensor.__enter__()`

**Parameters:** none. **Returns:** the same live tensor in `with`.
**Raises:** `RuntimeError` after close. No new native owner is created.

### `hmath_cffi.Tensor.__exit__(*args)`

**Parameters:** Python's exception triple. **Returns:** `None`, closing this
tensor on block exit without suppressing exceptions.

### Low-level cffi attributes

`hmath_cffi.ffi` is the configured `cffi.FFI` object; `hmath_cffi.lib` is the
loaded native handle exposing the declarations used by this wrapper. Raw calls
follow the [C ABI](c.md), including status and ownership rules. `tensor.ptr` is
borrowed: do not release it separately or use it after close. `tensor.shape`
is the construction/result shape tuple and must not be reassigned by callers.

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
