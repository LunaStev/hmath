# Python API

`hmath` is the primary interface. Calculations use finite IEEE 754 binary64
values. Tensors are immutable and do not broadcast implicitly. NumPy is needed
only for the conversion methods. Python code blocks run in documentation checks;
the final-shutdown example is displayed separately.

## Function index

| API | Purpose |
| --- | --- |
| [hmath.initialize](#hmathinitialize) | Initialize the shared numerical runtime. |
| [hmath.add](#hmathadda-b) | Add two real scalars. |
| [hmath.shutdown](#hmathshutdown) | Permanently shut down the process-owned runtime. |
| [hmath.HMathError](#hmathhmatherrorstatus) | Represent a failed native checked operation. |
| [hmath.Tensor](#hmathtensorvalues-shapenone) | Copy flat values into a new immutable tensor. |
| [hmath.Tensor.scalar](#hmathtensorscalarvalue) | Construct a rank-zero tensor. |
| [hmath.Tensor.matrix](#hmathtensormatrixvalues-rows-columns) | Construct a rank-two matrix from flat row-major values. |
| [hmath.Tensor.from_numpy](#hmathtensorfrom_numpyarray-copytrue) | Convert an array to a tensor, copying or borrowing its storage. |
| [hmath.Tensor.shape](#hmathtensorshape) | Read the tensor’s dimensions. |
| [hmath.Tensor.values](#hmathtensorvalues) | Copy logical elements to a flat Python list. |
| [hmath.Tensor.numpy](#hmathtensornumpycopytrue) | Return a NumPy copy or a read-only view. |
| [hmath.Tensor.sum](#hmathtensorsum) | Sum all tensor elements to one scalar. |
| [hmath.Tensor.dot](#hmathtensordotother) | Reduce corresponding products of two identically shaped tensors. |
| [hmath.Tensor.__add__](#hmathtensor__add__other-a-b) | Add two tensors element by element. |
| [hmath.Tensor.__matmul__](#hmathtensor__matmul__other-a-b) | Multiply two rank-two matrices. |
| [hmath.Tensor.reshape](#hmathtensorreshapeshape) | Create a new shape over the same contiguous storage. |
| [hmath.Tensor.close](#hmathtensorclose) | Release this tensor handle deterministically. |
| [hmath.Tensor.__enter__](#hmathtensor__enter__) | Enter a context that owns this tensor handle. |
| [hmath.Tensor.__exit__](#hmathtensor__exit__args) | Close the tensor when leaving a context. |
| [hmath.Tensor.__del__](#hmathtensor__del__) | Release the handle as a garbage-collection fallback. |
| [hmath_cffi.add](#hmath_cffiadda-b) | Add two real scalars. |
| [hmath_cffi.HMathError](#hmath_cffihmatherrorstatus) | Represent a failed native checked operation. |
| [hmath_cffi.check](#hmath_cfficheckstatus) | Convert a raw native status into a Python exception. |
| [hmath_cffi.Tensor](#hmath_cffitensorvalues-shapenone) | Copy flat values into a new immutable tensor. |
| [hmath_cffi.Tensor.values](#hmath_cffitensorvalues) | Copy logical elements to a flat Python list. |
| [hmath_cffi.Tensor.sum](#hmath_cffitensorsum) | Sum all tensor elements to one scalar. |
| [hmath_cffi.Tensor.dot](#hmath_cffitensordotother) | Reduce corresponding products of two identically shaped tensors. |
| [hmath_cffi.Tensor.__add__](#hmath_cffitensor__add__other-a-b) | Add two tensors element by element. |
| [hmath_cffi.Tensor.__matmul__](#hmath_cffitensor__matmul__other-a-b) | Multiply two rank-two matrices. |
| [hmath_cffi.Tensor.close](#hmath_cffitensorclose) | Release this tensor handle deterministically. |
| [hmath_cffi.Tensor.__enter__](#hmath_cffitensor__enter__) | Enter a context that owns this tensor handle. |
| [hmath_cffi.Tensor.__exit__](#hmath_cffitensor__exit__args) | Close the tensor when leaving a context. |

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

Initialize the shared numerical runtime.

#### Parameters

None.

#### Returns

`None`.

#### Raises

`RuntimeError` for ABI incompatibility or
an irreversibly shut down runtime.

#### Notes

Initialize the process-wide runtime; repeated calls are
allowed. Constructors and `add()` already do this automatically.

#### Examples

```python
from hmath import initialize
initialize()
initialize()
```

#### See also

[hmath.shutdown](#hmathshutdown), [hmath.add](#hmathadda-b).

### `hmath.add(a, b)`

Add two real scalars.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `a` | `real scalar` | First finite value, convertible to C double. |
| `b` | `real scalar` | Second finite value, convertible to C double. |

#### Returns

their sum as a Python `float`, initializing the runtime if needed.

#### Raises

`HMathError` for non-finite input/result, or runtime/conversion errors.

#### Examples

```python
from hmath import add
assert add(2, 3.5) == 5.5
```

#### See also

[hmath.Tensor.__add__](#hmathtensor__add__other-a-b), [hmath.initialize](#hmathinitialize).

### `hmath.shutdown()`

Permanently shut down the process-owned runtime.

#### Parameters

None.

#### Returns

`None`.

#### Raises

`HMathError` with status 9 while work is active;
join workers and retry. Successful shutdown is **irreversible**.

Example, as the last operation of a dedicated process (not run in shared tests):

#### Notes

Only the process owner should call this after joining
all numerical users and releasing their resources. Applications can instead
allow process exit to clean up the runtime.

#### Examples

```text
from hmath import shutdown
shutdown()
```

#### See also

[hmath.initialize](#hmathinitialize), [hmath.Tensor.close](#hmathtensorclose).

### `hmath.HMathError(status)`

Represent a failed native checked operation.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `status` | `int` | Native status code; available as the exception’s status attribute. |

#### Returns

a `RuntimeError` subclass instance with `.status` and a snapshot
of the calling thread's native diagnostic in `str(error)`. Catch exceptions
raised by operations rather than constructing this manually.

#### Examples

```python
from hmath import HMathError, Tensor
try:
    Tensor([1, 2], (3,))
except HMathError as error:
    assert error.status == 2
```

#### See also

[hmath.add](#hmathadda-b), [hmath.Tensor](#hmathtensorvalues-shapenone).

## Construction

### `hmath.Tensor(values, shape=None)`

Copy flat values into a new immutable tensor.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `values` | `iterable of real scalars` | Finite values in logical row-major order; at most 1,048,576 elements. |
| `shape` | `iterable of int or None; default None` | At most eight bounded nonnegative dimensions. None selects (len(values),). |

#### Returns

a new owned tensor.

#### Raises

`ValueError` for Python shape/size
bounds; `HMathError` for mismatched element count, non-finite input, or allocation
failure; ordinary numeric conversion errors may also occur.

#### Notes

`values`: finite numeric iterable in flat row-major order;
`shape`: optional iterable of dimensions, defaulting to `(len(values),)`.
Values are copied, so later changes to the input do not affect the tensor.
At most 1,048,577 entries are consumed before oversized input is rejected.

#### Examples

```python
with Tensor([1, 2, 3, 4], (2, 2)) as matrix:
    assert matrix.shape == (2, 2)
    assert matrix.values() == [1., 2., 3., 4.]
```

#### See also

[hmath.Tensor.matrix](#hmathtensormatrixvalues-rows-columns), [hmath.Tensor.scalar](#hmathtensorscalarvalue), [hmath.Tensor.from_numpy](#hmathtensorfrom_numpyarray-copytrue).

### `hmath.Tensor.scalar(value)`

Construct a rank-zero tensor.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `value` | `real scalar` | Single finite value; the resulting shape is (). |

#### Returns

a new owned rank-zero tensor
with shape `()`.

#### Raises

the constructor's conversion and native errors.

#### Examples

```python
with Tensor.scalar(7) as scalar:
    assert scalar.shape == ()
    assert scalar.values() == [7.0]
```

#### See also

[hmath.Tensor](#hmathtensorvalues-shapenone), [hmath.Tensor.matrix](#hmathtensormatrixvalues-rows-columns).

### `hmath.Tensor.matrix(values, rows, columns)`

Construct a rank-two matrix from flat row-major values.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `values` | `iterable of real scalars` | Exactly rows * columns finite values. |
| `rows` | `int` | Nonnegative row count, at most 1,048,576; bool is rejected. |
| `columns` | `int` | Nonnegative column count, at most 1,048,576; bool is rejected. |

#### Returns

a new owned rank-two tensor.

#### Raises

constructor errors.

#### Notes

flat row-major values and two nonnegative integer dimensions;
exactly `rows * columns` values are required.

#### Examples

```python
with Tensor.matrix([1, 2, 3, 4, 5, 6], 2, 3) as matrix:
    assert matrix.shape == (2, 3)
```

#### See also

[hmath.Tensor](#hmathtensorvalues-shapenone), [hmath.Tensor.__matmul__](#hmathtensor__matmul__other-a-b).

### `hmath.Tensor.from_numpy(array, copy=True)`

Convert an array to a tensor, copying or borrowing its storage.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `array` | `numpy.ndarray or array-like` | Input whose shape is retained; borrowing requirements are below. |
| `copy` | `bool; default True` | True converts to float64 and copies; False borrows eligible read-only storage. |

#### Returns

an owned tensor preserving shape.

#### Raises

`ImportError` without
NumPy, `ValueError` for borrowing/rank/size violations, or `HMathError` for native
storage validation, non-finite data, or allocation failures.

#### Notes

`array`: NumPy array or array-like input; `copy`: whether to copy.
With `True`, convert to `float64` and copy in row-major order. With `False`,
borrow aligned, native-endian, **read-only** `float64` storage with nonnegative
strides divisible by eight bytes. The tensor keeps the array alive. The caller
must prevent writes through every alias until all borrowed tensors/views die.

#### Examples

```python
import numpy as np
array = np.array([[1., 2.], [3., 4.]])
array.setflags(write=False)
with Tensor.from_numpy(array, copy=False) as tensor:
    assert tensor.sum() == 10.0
```

#### See also

[hmath.Tensor.numpy](#hmathtensornumpycopytrue), [hmath.Tensor](#hmathtensorvalues-shapenone), [hmath.Tensor.close](#hmathtensorclose).

## Inspection and conversion

### `hmath.Tensor.shape`

Read the tensor’s dimensions.

#### Parameters

None.

#### Returns

a tuple of dimensions,
including `()` for scalars.

#### Raises

`RuntimeError` after close or
`HMathError` if native metadata retrieval fails.

#### Examples

```python
with Tensor([], (0, 3)) as empty:
    assert empty.shape == (0, 3)
```

#### See also

[hmath.Tensor.reshape](#hmathtensorreshapeshape), [hmath.Tensor.values](#hmathtensorvalues).

### `hmath.Tensor.values()`

Copy logical elements to a flat Python list.

#### Parameters

None.

#### Returns

an independent flat `list[float]` in logical
row-major order, including for strided input; `[]` for empty tensors.

#### Raises

closed-handle or native copy errors.

#### Examples

```python
with Tensor([2, 4]) as tensor:
    values = tensor.values()
values[0] = 99  # Independent list remains usable after close.
```

#### See also

[hmath.Tensor.numpy](#hmathtensornumpycopytrue), [hmath.Tensor.shape](#hmathtensorshape).

### `hmath.Tensor.numpy(copy=True)`

Return a NumPy copy or a read-only view.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `copy` | `bool; default True` | True returns an independent writable copy; False returns a read-only view. |

#### Returns

`numpy.ndarray` of `float64`.

#### Raises

`ImportError` without NumPy,
closed-handle errors, or native metadata/data errors.

#### Notes

`copy`: `True` for a writable independent copy, `False` for a
read-only native view with the tensor's shape and strides. Views retain storage
and borrowed owners even after this tensor closes. Do not mutate borrowed aliases.

#### Examples

```python
with Tensor([1, 2, 3]) as tensor:
    view = tensor.numpy(copy=False)
assert view.tolist() == [1., 2., 3.]
assert not view.flags.writeable
del view
```

#### See also

[hmath.Tensor.from_numpy](#hmathtensorfrom_numpyarray-copytrue), [hmath.Tensor.values](#hmathtensorvalues), [hmath.Tensor.close](#hmathtensorclose).

## Calculations

### `hmath.Tensor.sum()`

Sum all tensor elements to one scalar.

#### Parameters

None.

#### Returns

a `float`, or `0.0` for an empty tensor.

#### Raises

closed-handle errors or native arithmetic/runtime errors, including
non-finite results.

#### Examples

```python
with Tensor([1, 2, 3]) as tensor:
    assert tensor.sum() == 6.0
```

#### See also

[hmath.Tensor.dot](#hmathtensordotother).

### `hmath.Tensor.dot(other)`

Reduce corresponding products of two identically shaped tensors.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `other` | `Tensor` | Live tensor with exactly the same shape as this tensor. |

#### Returns

a `float`, or `0.0` for matching empty tensors.

#### Raises

`HMathError` for shape/arithmetic/runtime errors; closed operands
raise `RuntimeError`.

#### Notes

a live tensor with exactly the same shape. Sum corresponding
products over the entire tensor; this is a scalar reduction at every rank.

#### Examples

```python
with Tensor([1, 2, 3]) as a, Tensor([4, 5, 6]) as b:
    assert a.dot(b) == 32.0
```

#### See also

[hmath.Tensor.sum](#hmathtensorsum), [hmath.Tensor.__matmul__](#hmathtensor__matmul__other-a-b).

### `hmath.Tensor.__add__(other)` — `a + b`

Add two tensors element by element.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `other` | `Tensor` | Live tensor of the same shape; broadcasting is unsupported. |

#### Returns

a new owned tensor of elementwise sums. Inputs are unchanged.

#### Raises

native shape/allocation/arithmetic/runtime or closed-handle errors.

#### Examples

```python
with Tensor([1, 2]) as a, Tensor([3, 4]) as b:
    with a + b as result:
        assert result.values() == [4., 6.]
```

#### See also

[hmath.Tensor.dot](#hmathtensordotother), [hmath.Tensor.__matmul__](#hmathtensor__matmul__other-a-b).

### `hmath.Tensor.__matmul__(other)` — `a @ b`

Multiply two rank-two matrices.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `other` | `Tensor` | Live (k, n) matrix when this tensor has shape (m, k). |

#### Returns

a new owned matrix.

#### Raises

native rank/inner-dimension,
size/work budget, allocation, arithmetic/runtime, or closed-handle errors.

#### Notes

a live rank-two tensor. Shapes `(m, k)` and `(k, n)` produce
`(m, n)`. Work is bounded by **16,777,216** scalar multiply-add steps (`m*k*n`).
This binding does not expose batched multiplication.

#### Examples

```python
with Tensor.matrix([1, 2, 3, 4], 2, 2) as a:
    with a @ a as squared:
        assert squared.values() == [7., 10., 15., 22.]
```

#### See also

[hmath.Tensor.matrix](#hmathtensormatrixvalues-rows-columns), [hmath.Tensor.dot](#hmathtensordotother).

### `hmath.Tensor.reshape(shape)`

Create a new shape over the same contiguous storage.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `shape` | `iterable of int` | Nonnegative dimensions with unchanged element count; -1 inference is unsupported. |

#### Returns

a new owned handle sharing storage; both handles can close independently.

#### Raises

`ValueError` for invalid dimensions, `HMathError` for incompatible
count or non-contiguous input, or `RuntimeError` after close.

#### Notes

new dimensions with unchanged element count. Storage must be
contiguous. Negative dimensions, including `-1` for inference, are unsupported.

#### Examples

```python
with Tensor([1, 2, 3, 4]) as flat:
    reshaped = flat.reshape((2, 2))
with reshaped:
    assert reshaped.shape == (2, 2)
```

#### See also

[hmath.Tensor.shape](#hmathtensorshape), [hmath.Tensor](#hmathtensorvalues-shapenone).

## Lifetime protocol

### `hmath.Tensor.close()`

Release this tensor handle deterministically.

#### Parameters

None.

#### Returns

`None`; repeated calls are harmless. Other retained handles/views
remain valid. Using this closed handle raises `RuntimeError`.

#### Examples

```python
tensor = Tensor([1])
tensor.close()
tensor.close()
```

#### See also

[hmath.Tensor.__enter__](#hmathtensor__enter__), [hmath.Tensor.__exit__](#hmathtensor__exit__args), [hmath.Tensor.__del__](#hmathtensor__del__).

### `hmath.Tensor.__enter__()`

Enter a context that owns this tensor handle.

#### Parameters

None.

#### Returns

the same live tensor for a `with` block;
this creates no additional reference.

#### Raises

`RuntimeError` after close.
See the context-manager examples above.

#### See also

[hmath.Tensor.close](#hmathtensorclose), [hmath.Tensor.__exit__](#hmathtensor__exit__args).

### `hmath.Tensor.__exit__(*args)`

Close the tensor when leaving a context.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `args` | `exception triple` | Python supplies (exception type, exception value, traceback); exceptions are not suppressed. |

#### Returns

`None`, closing the tensor on normal or exceptional block exit
without suppressing the exception. See the context-manager examples above.

#### See also

[hmath.Tensor.close](#hmathtensorclose), [hmath.Tensor.__enter__](#hmathtensor__enter__).

### `hmath.Tensor.__del__()`

Release the handle as a garbage-collection fallback.

#### Parameters

None.

#### Returns

`None`, calling `close()` as a finalization
fallback. Collection timing is unspecified; use `with` for deterministic cleanup.

#### See also

[hmath.Tensor.close](#hmathtensorclose).

## Optional cffi interface

Install `hmath-python[cffi]` to use `hmath_cffi`. Both wrappers share the native
runtime. Prevent concurrent close/use of a cffi tensor. NumPy conversion,
`reshape`, `scalar`, and `matrix` constructors belong to the primary interface.

### `hmath_cffi.add(a, b)`

Add two real scalars.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `a` | `real scalar` | First finite value, convertible to C double. |
| `b` | `real scalar` | Second finite value, convertible to C double. |

#### Returns

their binary64 sum as a
Python float.

#### Raises

`hmath_cffi.HMathError` for native failures or ordinary
conversion errors. Import initializes the runtime and checks ABI 1.

#### Examples

```python
import hmath_cffi as hc
assert hc.add(2, 3) == 5.0
```

#### See also

[hmath.add](#hmathadda-b), [hmath_cffi.Tensor](#hmath_cffitensorvalues-shapenone), [hmath_cffi.Tensor.close](#hmath_cffitensorclose).

### `hmath_cffi.HMathError(status)`

Represent a failed native checked operation.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `status` | `int` | Native status code; available as the exception’s status attribute. |

#### Returns

an exception with `.status`
and a snapshot of the current native error message. Catch this class for cffi
errors; it is a separate class from `hmath.HMathError`.

#### See also

[hmath.HMathError](#hmathhmatherrorstatus), [hmath_cffi.Tensor](#hmath_cffitensorvalues-shapenone), [hmath_cffi.Tensor.close](#hmath_cffitensorclose).

### `hmath_cffi.check(status)`

Convert a raw native status into a Python exception.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `status` | `int` | Status returned by the immediately preceding checked C call. |

#### Returns

`None` for zero.

#### Raises

`hmath_cffi.HMathError` for nonzero. Call immediately after the raw
call so its thread-local error message has not been replaced.

#### See also

[hmath_cffi.Tensor](#hmath_cffitensorvalues-shapenone), [hmath_cffi.Tensor.close](#hmath_cffitensorclose).

### `hmath_cffi.Tensor(values, shape=None)`

Copy flat values into a new immutable tensor.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `values` | `iterable of real scalars` | Finite values in logical row-major order; at most 1,048,576 elements. |
| `shape` | `iterable of int or None; default None` | At most eight bounded nonnegative dimensions. None selects (len(values),). |

#### Returns

an owned cffi tensor with `.shape`
stored as a tuple.

#### Raises

`ValueError` for Python bounds,
`hmath_cffi.HMathError` for native input/allocation errors, or conversion errors.

#### Examples

```python
with hc.Tensor([1, 2, 3, 4], (2, 2)) as a:
    assert a.shape == (2, 2)
    with a @ a as result:
        assert result.values() == [7., 10., 15., 22.]
```

#### See also

[hmath.Tensor](#hmathtensorvalues-shapenone), [hmath_cffi.Tensor.close](#hmath_cffitensorclose), [hmath_cffi.check](#hmath_cfficheckstatus).

### `hmath_cffi.Tensor.values()`

Copy logical elements to a flat Python list.

#### Parameters

None.

#### Returns

an independent row-major `list[float]`.

#### Raises

`RuntimeError` after close or `hmath_cffi.HMathError` on copy failure.
Use `.values()` inside the context-manager example above.

#### See also

[hmath.Tensor.values](#hmathtensorvalues), [hmath_cffi.Tensor](#hmath_cffitensorvalues-shapenone), [hmath_cffi.Tensor.close](#hmath_cffitensorclose).

### `hmath_cffi.Tensor.sum()`

Sum all tensor elements to one scalar.

#### Parameters

None.

#### Returns

scalar sum, or `0.0` for an empty tensor.

#### Raises

native arithmetic/runtime or closed-handle errors. For example,
`hc.Tensor([1, 2])` sums to `3.0`; close the owner after use.

#### See also

[hmath.Tensor.sum](#hmathtensorsum), [hmath_cffi.Tensor](#hmath_cffitensorvalues-shapenone), [hmath_cffi.Tensor.close](#hmath_cffitensorclose).

### `hmath_cffi.Tensor.dot(other)`

Reduce corresponding products of two identically shaped tensors.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `other` | `Tensor` | Live tensor with exactly the same shape as this tensor. |

#### Returns

scalar sum
of elementwise products.

#### Raises

native shape/arithmetic/runtime or
closed-handle errors. The primary interface's dot example also applies to cffi.

#### See also

[hmath.Tensor.dot](#hmathtensordotother), [hmath_cffi.Tensor](#hmath_cffitensorvalues-shapenone), [hmath_cffi.Tensor.close](#hmath_cffitensorclose).

### `hmath_cffi.Tensor.__add__(other)` — `a + b`

Add two tensors element by element.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `other` | `Tensor` | Live tensor of the same shape; broadcasting is unsupported. |

#### Returns

a new owned
elementwise sum without broadcasting.

#### Raises

native shape/allocation/
arithmetic/runtime or closed-handle errors. Use with `with a + b as result:`.

#### See also

[hmath.Tensor.__add__](#hmathtensor__add__other-a-b), [hmath_cffi.Tensor](#hmath_cffitensorvalues-shapenone), [hmath_cffi.Tensor.close](#hmath_cffitensorclose).

### `hmath_cffi.Tensor.__matmul__(other)` — `a @ b`

Multiply two rank-two matrices.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `other` | `Tensor` | Live (k, n) matrix when this tensor has shape (m, k). |

#### Returns

a new owned matrix.

#### Raises

the same shape/work-bound and
native/lifecycle errors as primary `@`. See the executable cffi example above.

#### See also

[hmath.Tensor.__matmul__](#hmathtensor__matmul__other-a-b), [hmath_cffi.Tensor](#hmath_cffitensorvalues-shapenone), [hmath_cffi.Tensor.close](#hmath_cffitensorclose).

### `hmath_cffi.Tensor.close()`

Release this tensor handle deterministically.

#### Parameters

None.

#### Returns

`None`, releasing its cffi-managed reference.
Repeated calls are harmless. Do not close concurrently with an operation on
this tensor. Other independent owners remain valid.

#### See also

[hmath.Tensor.close](#hmathtensorclose), [hmath_cffi.Tensor](#hmath_cffitensorvalues-shapenone), [hmath_cffi.check](#hmath_cfficheckstatus).

### `hmath_cffi.Tensor.__enter__()`

Enter a context that owns this tensor handle.

#### Parameters

None.

#### Returns

the same live tensor in `with`.

#### Raises

`RuntimeError` after close. No new native owner is created.

#### See also

[hmath.Tensor.__enter__](#hmathtensor__enter__), [hmath_cffi.Tensor](#hmath_cffitensorvalues-shapenone), [hmath_cffi.Tensor.close](#hmath_cffitensorclose).

### `hmath_cffi.Tensor.__exit__(*args)`

Close the tensor when leaving a context.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `args` | `exception triple` | Python supplies (exception type, exception value, traceback); exceptions are not suppressed. |

#### Returns

`None`, closing this
tensor on block exit without suppressing exceptions.

#### See also

[hmath.Tensor.__exit__](#hmathtensor__exit__args), [hmath_cffi.Tensor](#hmath_cffitensorvalues-shapenone), [hmath_cffi.Tensor.close](#hmath_cffitensorclose).

## Low-level cffi attributes

`hmath_cffi.ffi` is the configured `cffi.FFI` object; `hmath_cffi.lib` is the
loaded native handle exposing the declarations used by this wrapper. Raw calls
follow the [C ABI](c.md), including status and ownership rules. `tensor.ptr` is
borrowed: do not release it separately or use it after close. `tensor.shape`
is the construction/result shape tuple and must not be reassigned by callers.

## Native status codes

See the canonical [C status table](c.md#native-status-codes).
