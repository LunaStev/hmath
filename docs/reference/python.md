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

**Failure conditions by exception:**

- **`RuntimeError`** — The native ABI is incompatible, or the runtime was permanently shut down.

#### Notes

Initialize the process-wide runtime; repeated calls are
allowed. Constructors and `add()` already do this automatically.

Repeated initialization is allowed. Tensor construction and `add()` already
initialize automatically. This does not create a private runtime or a resource
that each caller should later shut down.

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

**Failure conditions by exception:**

- **`ctypes.ArgumentError`** — ctypes cannot convert an operand to the declared C argument type.

- **`RuntimeError`** — Automatic initialization finds an incompatible or shut-down runtime.

- **`HMathError`** — Non-finite input (status 1), non-finite result (3), runtime failure (5),
  or a contained Haskell exception (6).

#### Notes

This is scalar addition, not broadcasting over a Tensor. A finite result is
not an exact-arithmetic guarantee. Use an application-appropriate tolerance for
non-exact floating-point comparisons.

#### Examples

```python
from hmath import add
assert add(2, 3.5) == 5.5
```

```python
import math
from hmath import HMathError, add

assert add(2, 3.5) == 5.5
assert math.isclose(add(0.1, 0.2), 0.3, rel_tol=1e-12, abs_tol=1e-15)
try:
    add(float("inf"), 1.0)
except HMathError as error:
    assert error.status == 1
else:
    raise AssertionError("non-finite input must be rejected")
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

**Failure conditions by exception:**

- **`HMathError`** — Active work prevents shutdown (status 9). Join the numerical workers and
  retry only after all users have finished.

#### Notes

Only the process owner should call this after joining
all numerical users and releasing their resources. Applications can instead
allow process exit to clean up the runtime.

Only the process owner should call this, after joining numerical users and
releasing their resources. It is not per-Tensor cleanup. A successful shutdown
is irreversible: later `initialize()` calls fail. Applications may instead let
process exit clean up the runtime. This example runs in its own process.

#### Examples

```text
from hmath import shutdown
shutdown()
```

#### See also

[hmath.initialize](#hmathinitialize), [hmath.Tensor.close](#hmathtensorclose).

### `hmath.HMathError(status)`

<a id="hmath.HMathError"></a>

Represent a failed native checked operation.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `status` | `int` | Native status code; available as the exception’s status attribute. |

#### Returns

a `RuntimeError` subclass instance with `.status` and a snapshot
of the calling thread's native diagnostic in `str(error)`. Catch exceptions
raised by operations rather than constructing this manually.

#### Notes

This exception inherits from `RuntimeError`. `str(error)` holds a snapshot of
the calling thread's native diagnostic. Catch exceptions raised by operations;
manually constructing this class does not perform an operation or generate a
new diagnostic. The cffi exception is a different Python class.

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

**Failure conditions by exception:**

- **`ValueError`** — Python rank/dimension validation fails, or more than 1,048,576 values
  are consumed.

- **`TypeError`, `ValueError`, `OverflowError`** — The iterable or an element cannot be converted by the Python/ctypes path.

- **`RuntimeError`** — Automatic initialization cannot use the runtime.

- **`HMathError`** — The shape product exceeds a native budget (3), count differs from the shape
  product (2), an element is non-finite (1), or native allocation fails (4).

#### Notes

`values`: finite numeric iterable in flat row-major order;
`shape`: optional iterable of dimensions, defaulting to `(len(values),)`.
Values are copied, so later changes to the input do not affect the tensor.
At most 1,048,577 entries are consumed before oversized input is rejected.

The constructor consumes at most 1,048,577 values to detect oversized input.
It copies values, so later changes to a source list do not affect the tensor.
The object owns one handle; use a context manager or `close()`.

Shape `()` requires exactly one value; shape `(1,)` describes a vector instead.
For shape `(m, n)`, flat position `i*n + j` corresponds to row `i`, column `j`.
A rank-zero tensor and a one-element vector are not interchangeable operands
for operations requiring equal shapes.

#### Examples

```python
with Tensor([1, 2, 3, 4], (2, 2)) as matrix:
    assert matrix.shape == (2, 2)
    assert matrix.values() == [1., 2., 3., 4.]
```

```python
from hmath import Tensor

source = [1, 2, 3, 4, 5, 6]
with Tensor(source, (2, 3)) as matrix:
    source[0] = 99
    assert matrix.shape == (2, 3)
    assert matrix.values() == [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
with Tensor([], (0, 3)) as empty:
    assert empty.shape == (0, 3)
    assert empty.values() == []
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

**Failure conditions by exception:**

- **`TypeError`, `ValueError`, `OverflowError`** — The value cannot be converted by the constructor.

- **`RuntimeError`** — Automatic initialization fails.

- **`HMathError`** — The converted value is non-finite (1), or native allocation fails (4).

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

**Failure conditions by exception:**

- **`ValueError`** — Invalid dimensions or an oversized value sequence.

- **`TypeError`, `OverflowError`** — Values cannot be converted to the constructor's numeric representation.

- **`RuntimeError`** — Automatic initialization fails.

- **`HMathError`** — Count mismatch (2), native layout budget (3), non-finite values (1),
  or allocation failure (4). Conversion hooks may also propagate `ValueError`.

#### Notes

flat row-major values and two nonnegative integer dimensions;
exactly `rows * columns` values are required.

Equivalent to `Tensor(values, (rows, columns))`. Zero rows or zero columns
require an empty value sequence. This constructor does not infer dimensions.

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

**Failure conditions by exception:**

- **`ImportError`** — NumPy is not installed.

- **`ValueError`** — Rank/element or Python dimension bounds fail; borrowing receives a writable,
  misaligned, non-native-endian, or non-float64 array; or strides are negative
  or not whole multiples of eight bytes. NumPy conversion may also raise it.

- **`TypeError`, `OverflowError`** — NumPy/Python cannot convert the input.

- **`RuntimeError`** — Automatic initialization fails.

- **`HMathError`** — Native layout/span budgets (3 or 8), non-finite reachable elements (1),
  or native allocation failure (4).

#### Notes

`array`: NumPy array or array-like input; `copy`: whether to copy.
With `True`, convert to `float64` and copy in row-major order. With `False`,
borrow aligned, native-endian, **read-only** `float64` storage with nonnegative
strides divisible by eight bytes. The tensor keeps the array alive. The caller
must prevent writes through every alias until all borrowed tensors/views die.

With `copy=True`, NumPy converts to `float64`, the wrapper flattens in C order,
and HMath copies the elements. Input strides need not be contiguous and the
source may be writable. The resulting Tensor has independent contiguous storage.

With `copy=False`, the normalized array must already be aligned, native-endian,
read-only `float64`. Nonnegative strides, including zero strides, must be
multiples of eight bytes; positive-stride non-contiguous views are supported
within the native layout budgets. Native strides count elements, while NumPy
strides count bytes. For a nonempty shape, reachable span in elements is
`1 + sum((dimension - 1) * element_stride)`; logical count and span can differ.
Native validation examines reachable values for finiteness.

Borrowing avoids copying the element buffer, not validation, object allocation,
or metadata allocation. Initial `numpy.asarray` normalization of an array-like
object may itself allocate. Passing an eligible ndarray makes the intended
borrowed-buffer relationship explicit.

Keep every alias to the borrowed storage immutable until all derived tensors
and NumPy views are released. Setting one array read-only does not prevent a
write through a different writable alias. Use `copy=True` when ownership or
immutability cannot be coordinated.

#### Examples

```python
import numpy as np
array = np.array([[1., 2.], [3., 4.]])
array.setflags(write=False)
with Tensor.from_numpy(array, copy=False) as tensor:
    assert tensor.sum() == 10.0
```

```python
import numpy as np
from hmath import Tensor

source = np.arange(12, dtype=np.float64).reshape(3, 4)
source.setflags(write=False)
with Tensor.from_numpy(source[:, ::2], copy=False) as tensor:
    view = tensor.numpy(copy=False)
    assert tensor.shape == (3, 2)
    assert tensor.values() == [0.0, 2.0, 4.0, 6.0, 8.0, 10.0]
    assert np.shares_memory(view, source)
    assert not view.flags.writeable
assert view.sum() == 30.0  # The view survives closing this Tensor handle.
del view
```

```python
import numpy as np
from hmath import Tensor

source = np.arange(4, dtype=np.float64)  # Writable.
try:
    with Tensor.from_numpy(source, copy=False):
        pass
except ValueError:
    pass
else:
    raise AssertionError("writable borrowing must be rejected")
with Tensor.from_numpy(source) as copied:
    source[0] = 99
    assert copied.values()[0] == 0.0
```

#### See also

[hmath.Tensor.numpy](#hmathtensornumpycopytrue), [hmath.Tensor](#hmathtensorvalues-shapenone), [hmath.Tensor.close](#hmathtensorclose).

## Inspection and conversion

### `hmath.Tensor.shape`

<a id="hmath.Tensor.shape"></a>

Read the tensor’s dimensions.

#### Parameters

None.

#### Returns

a tuple of dimensions,
including `()` for scalars.

#### Raises

`RuntimeError` after close or
`HMathError` if native metadata retrieval fails.

**Failure conditions by exception:**

- **`RuntimeError`** — The handle is closed.

- **`HMathError`** — Native metadata retrieval fails.

#### Notes

Shape `()` denotes one scalar, while a shape containing zero denotes an
empty tensor. Reading the property does not copy the element buffer.

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

**Failure conditions by exception:**

- **`RuntimeError`** — The handle is closed.

- **`HMathError`** — Native copy validation fails.

#### Notes

Strided input is gathered in logical order, not raw storage-span order.
The list remains valid after the Tensor closes. Copying N elements takes
O(N) output space; this is not a zero-copy access method.

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

**Failure conditions by exception:**

- **`ImportError`** — NumPy is unavailable.

- **`RuntimeError`** — The handle is closed.

- **`HMathError`** — Native data, metadata, or copy retrieval fails.

#### Notes

`copy`: `True` for a writable independent copy, `False` for a
read-only native view with the tensor's shape and strides. Views retain storage
and borrowed owners even after this tensor closes. Do not mutate borrowed aliases.

A copy is writable and unaffected by closing the tensor. A view is read-only
and retains both native storage and any borrowed NumPy owner. Closing the
original Tensor therefore does not invalidate the view or its derived views.
For empty storage, `copy=False` may return a separate empty read-only NumPy
allocation; there are no elements whose sharing can be demonstrated.

Read-only views do not make other aliases to borrowed storage read-only.
The borrowing immutability contract still applies. View construction allocates
Python/NumPy metadata even when it does not copy elements.

#### Examples

```python
with Tensor([1, 2, 3]) as tensor:
    view = tensor.numpy(copy=False)
assert view.tolist() == [1., 2., 3.]
assert not view.flags.writeable
del view
```

```python
import numpy as np
from hmath import Tensor

with Tensor([1, 2, 3]) as tensor:
    copied = tensor.numpy()
    view = tensor.numpy(copy=False)
    copied[0] = 99
    assert tensor.values() == [1.0, 2.0, 3.0]
    assert not np.shares_memory(copied, view)
assert view.tolist() == [1.0, 2.0, 3.0]
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

**Failure conditions by exception:**

- **`RuntimeError`** — A required Tensor handle is closed.

- **`HMathError`** — Non-finite computed result (3), native scratch/result allocation failure (4),
  unavailable runtime (5), or a contained Haskell exception (6).

#### Notes

For N logical elements, the mathematical operation is

$$
s = \sum_{i=0}^{N-1} x_i.
$$

This method has no `axis`, `dtype`, or `keepdims` argument: even a matrix is
reduced to a Python float. A scalar Tensor contributes its one value.
The native boundary gathers values in logical row-major order and the current
Haskell reference kernel uses ordinary `sum`, not a documented compensated
summation algorithm. Reduction work is O(N); the current boundary also uses
O(N) gathered storage. An empty reduction has constant overhead.

Finite-result checking does not eliminate rounding or cancellation, and no
universal relative-error or correctly-rounded-result guarantee is made.

#### Examples

```python
with Tensor([1, 2, 3]) as tensor:
    assert tensor.sum() == 6.0
```

```python
import math
from hmath import Tensor

with Tensor([1, 2, 3, 4], (2, 2)) as matrix:
    assert matrix.sum() == 10.0
with Tensor([], (0, 3)) as empty:
    assert empty.sum() == 0.0
with Tensor([0.1, 0.2]) as samples:
    assert math.isclose(samples.sum(), 0.3, rel_tol=1e-12, abs_tol=1e-15)
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

**Failure conditions by exception:**

- **`RuntimeError`** — A required Tensor handle is closed.

- **`HMathError`** — Non-finite computed result (3), native scratch/result allocation failure (4),
  unavailable runtime (5), or a contained Haskell exception (6).

- **`HMathError` with status 2** — The operand shapes differ, even when their total element counts are equal.

#### Notes

a live tensor with exactly the same shape. Sum corresponding
products over the entire tensor; this is a scalar reduction at every rank.

For equal shapes and logical flattened elements, the mathematical definition is

$$
d = \sum_{i=0}^{N-1} a_i b_i.
$$

This is not NumPy's dimension-dependent `dot`: two matrices produce a scalar
sum of elementwise products, not a matrix product. Use `a @ b` for matrix
multiplication. There is no broadcasting or mixing of `hmath.Tensor` and
`hmath_cffi.Tensor` operands.

The current native boundary gathers both inputs; the Haskell reference kernel
forms elementwise products and sums them. Arithmetic work and gathered input
storage are O(N), with ordinary binary64 rounding. It does not promise
compensated accumulation or exact products.

#### Examples

```python
with Tensor([1, 2, 3]) as a, Tensor([4, 5, 6]) as b:
    assert a.dot(b) == 32.0
```

```python
from hmath import HMathError, Tensor

with Tensor([1, 2, 3, 4], (2, 2)) as a:
    with Tensor([5, 6, 7, 8], (2, 2)) as b:
        assert a.dot(b) == 70.0
        with a @ b as product:
            assert product.values() == [19.0, 22.0, 43.0, 50.0]
    with Tensor([1, 2, 3, 4], (4,)) as flat:
        try:
            a.dot(flat)
        except HMathError as error:
            assert error.status == 2
        else:
            raise AssertionError("equal counts do not imply equal shapes")
```

#### References

[NumPy dot](https://numpy.org/doc/stable/reference/generated/numpy.dot.html)
documents the different NumPy semantics; it is not a compatibility claim.

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

**Failure conditions by exception:**

- **`RuntimeError`** — A required Tensor handle is closed.

- **`HMathError`** — Non-finite computed result (3), native scratch/result allocation failure (4),
  unavailable runtime (5), or a contained Haskell exception (6).

- **`HMathError` with status 2** — The shapes do not match.

#### Notes

For each logical position, `result[i] = a[i] + b[i]`. Scalars represented
as rank-zero tensors can be added to other rank-zero tensors. `tensor + 1`
is not a supported scalar-broadcast operation. Work and result storage are O(N),
with additional O(N) scratch storage in the current native boundary.

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

**Failure conditions by exception:**

- **`RuntimeError`** — A required Tensor handle is closed.

- **`HMathError`** — Non-finite computed result (3), native scratch/result allocation failure (4),
  unavailable runtime (5), or a contained Haskell exception (6).

- **`HMathError` with status 2** — An operand is not rank two or the inner dimensions differ.

- **`HMathError` with status 3** — Output size or the scalar-operation work budget is exceeded.

#### Notes

a live rank-two tensor. Shapes `(m, k)` and `(k, n)` produce
`(m, n)`. Work is bounded by **16,777,216** scalar multiply-add steps (`m*k*n`).
This binding does not expose batched multiplication.

The mathematical definition is

$$
C_{ij} = \sum_{p=0}^{k-1} A_{ip} B_{pj},
\qquad C \in \mathbb{R}^{m \times n}.
$$

The output must contain at most **1,048,576** elements and `m*k*n` must not
exceed **16,777,216**. This is a work budget, not a precision target or a promise
of hardware fused multiply-add instructions. Vectors, batched products, and
broadcasting are not supported by this binding.

For `k == 0`, compatible `(m, 0)` and `(0, n)` inputs yield an `(m, n)` zero
matrix, subject to the output budget. A zero outer dimension produces an empty
result. The current Haskell reference loop accumulates each cell in increasing
inner-index order. It performs O(m*k*n) arithmetic and produces O(m*n) output;
gathering inputs and preparing output also costs O(m*k + k*n + m*n), including
when an arithmetic dimension is zero. Scratch buffers are used. Do not infer
BLAS acceleration from other Haskell modules.

#### Examples

```python
with Tensor.matrix([1, 2, 3, 4], 2, 2) as a:
    with a @ a as squared:
        assert squared.values() == [7., 10., 15., 22.]
```

```python
from hmath import Tensor

with Tensor.matrix([1, 2, 3, 4, 5, 6], 2, 3) as a:
    with Tensor.matrix([7, 8, 9, 10, 11, 12], 3, 2) as b:
        with a @ b as result:
            assert result.shape == (2, 2)
            assert result.values() == [58.0, 64.0, 139.0, 154.0]
with Tensor([], (2, 0)) as a, Tensor([], (0, 3)) as b:
    with a @ b as result:
        assert result.shape == (2, 3)
        assert result.values() == [0.0] * 6
```

#### See also

[hmath.Tensor.matrix](#hmathtensormatrixvalues-rows-columns), [hmath.Tensor.dot](#hmathtensordotother).

### `hmath.Tensor.reshape(shape)`

<a id="hmath.Tensor.reshape"></a>

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

**Failure conditions by exception:**

- **`ValueError`** — The Python shape/rank contract is violated.

- **`TypeError`** — `shape` is not iterable.

- **`RuntimeError`** — This handle is closed.

- **`HMathError`** — Count mismatch or non-contiguous storage (2), native layout budget (3),
  or new-handle allocation failure (4).

#### Notes

new dimensions with unchanged element count. Storage must be
contiguous. Negative dimensions, including `-1` for inference, are unsupported.

No element reordering or copy fallback is performed. Contiguity is checked
by the native layout validator: singleton dimensions do not constrain strides,
and empty tensors are considered contiguous. A positive-stride borrowed view
can still be non-contiguous and rejected. The reshaped handle retains any
borrowed owner. Validation and metadata construction depend on rank, not on
copying all elements.

#### Examples

```python
with Tensor([1, 2, 3, 4]) as flat:
    reshaped = flat.reshape((2, 2))
with reshaped:
    assert reshaped.shape == (2, 2)
```

```python
from hmath import Tensor

with Tensor([1, 2, 3, 4]) as flat:
    reshaped = flat.reshape((2, 2))
with reshaped:
    assert reshaped.shape == (2, 2)
    assert reshaped.values() == [1.0, 2.0, 3.0, 4.0]
```

```python
import numpy as np
from hmath import HMathError, Tensor

source = np.arange(8, dtype=np.float64)
source.setflags(write=False)
with Tensor.from_numpy(source[::2], copy=False) as strided:
    try:
        with strided.reshape((2, 2)):
            pass
    except HMathError as error:
        assert error.status == 2
    else:
        raise AssertionError("non-contiguous reshape must be rejected")
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

#### Notes

After closing, handle-dependent operations raise `RuntimeError`. Retained
Tensor handles and NumPy views remain valid. This does not shut down the
process-wide runtime. Closing is synchronized with primary-interface handle
operations, not with arbitrary external writes to borrowed storage.

#### Examples

```python
tensor = Tensor([1])
tensor.close()
tensor.close()
```

```python
from hmath import Tensor

tensor = Tensor([1])
tensor.close()
tensor.close()
try:
    tensor.values()
except RuntimeError:
    pass
else:
    raise AssertionError("closed handles must not be used")
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

**Failure conditions by exception:**

- **`RuntimeError`** — The handle is already closed.

#### See also

[hmath.Tensor.close](#hmathtensorclose), [hmath.Tensor.__exit__](#hmathtensor__exit__args).

#### Notes

Use `with tensor:` or `with Tensor(...) as tensor:`. Nested contexts over
the same object do not create nested ownership: the inner exit closes that
handle. Create an independent retained result when independent lifetimes are needed.



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

#### Notes

Calls `close()` as a fallback. Do not rely on collection timing or call
this method directly as the usual cleanup API. Use `with` or `close()`.



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

**Failure conditions by exception:**

- **`TypeError`, `OverflowError`** — cffi cannot convert an operand; conversion hooks can propagate other exceptions.

- **`hmath_cffi.HMathError`** — Non-finite input (1), non-finite result (3), unavailable runtime (5),
  or contained Haskell exception (6).

#### Notes

Unlike primary `add()`, this function does not itself reinitialize the runtime.
Initialization happens during module import.

#### Examples

```python
import hmath_cffi as hc
assert hc.add(2, 3) == 5.0
```

#### See also

[hmath.add](#hmathadda-b), [hmath_cffi.Tensor](#hmath_cffitensorvalues-shapenone), [hmath_cffi.Tensor.close](#hmath_cffitensorclose).

### `hmath_cffi.HMathError(status)`

<a id="hmath_cffi.HMathError"></a>

Represent a failed native checked operation.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `status` | `int` | Native status code; available as the exception’s status attribute. |

#### Returns

an exception with `.status`
and a snapshot of the current native error message. Catch this class for cffi
errors; it is a separate class from `hmath.HMathError`.

#### Examples

```python
import hmath_cffi as hc

try:
    with hc.Tensor([1, 2], (3,)):
        pass
except hc.HMathError as error:
    assert error.status == 2
else:
    raise AssertionError("shape mismatch must be rejected")
```

#### See also

[hmath.HMathError](#hmathhmatherrorstatus), [hmath_cffi.Tensor](#hmath_cffitensorvalues-shapenone), [hmath_cffi.Tensor.close](#hmath_cffitensorclose).

#### Notes

Inherits from `RuntimeError`, but is not `hmath.HMathError`. Catch the
exception class belonging to the interface being used. The message snapshots
the calling thread's diagnostic; manual construction reads the current native
message rather than performing a new operation.



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

**Failure conditions by exception:**

- **`hmath_cffi.HMathError`** — The supplied status is nonzero; `.status` is the supplied code.

#### See also

[hmath_cffi.Tensor](#hmath_cffitensorvalues-shapenone), [hmath_cffi.Tensor.close](#hmath_cffitensorclose).

#### Notes

The wrapper uses this helper internally. If using it with a raw checked
call, invoke it immediately on the same thread so another operation cannot
replace the diagnostic. High-level operations already call it; users do not
need to wrap `Tensor.sum()` or `add()` in another `check()`.



### `hmath_cffi.Tensor(values, shape=None)`

<a id="hmath_cffi.Tensor"></a>

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

**Failure conditions by exception:**

- **`ValueError`** — Rank, Python dimension, or input-count validation fails.

- **`TypeError`, `OverflowError`** — cffi cannot convert values; conversion hooks can propagate other exceptions.

- **`hmath_cffi.HMathError`** — Count mismatch (2), layout budget (3), non-finite data (1), or native
  allocation failure (4).

#### Notes

Values are copied. The constructor consumes at most 1,048,577 values to
detect oversized input. Use `with` or `close()`; do not close this handle
concurrently with an operation using it. Runtime initialization occurs on
module import. Garbage-collection cleanup is a fallback, not a deterministic
replacement for explicit cleanup.

#### Examples

```python
with hc.Tensor([1, 2, 3, 4], (2, 2)) as a:
    assert a.shape == (2, 2)
    with a @ a as result:
        assert result.values() == [7., 10., 15., 22.]
```

```python
import hmath_cffi as hc

with hc.Tensor([1, 2, 3, 4], (2, 2)) as matrix:
    assert matrix.shape == (2, 2)
    with matrix @ matrix as squared:
        assert squared.values() == [7.0, 10.0, 15.0, 22.0]
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

**Failure conditions by exception:**

- **`RuntimeError`** — The handle is closed.

- **`hmath_cffi.HMathError`** — Native copy validation fails.

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

**Failure conditions by exception:**

- **`RuntimeError`** — A required Tensor handle is closed.

- **`hmath_cffi.HMathError`** — Non-finite computed result (3), native scratch/result allocation failure (4),
  unavailable runtime (5), or a contained Haskell exception (6).

#### See also

[hmath.Tensor.sum](#hmathtensorsum), [hmath_cffi.Tensor](#hmath_cffitensorvalues-shapenone), [hmath_cffi.Tensor.close](#hmath_cffitensorclose).

#### Notes

The whole-tensor reduction, numerical behavior, and native scratch costs
are the same as primary `Tensor.sum()`. No axis argument is exposed.



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

**Failure conditions by exception:**

- **`RuntimeError`** — A required Tensor handle is closed.

- **`hmath_cffi.HMathError`** — Non-finite computed result (3), native scratch/result allocation failure (4),
  unavailable runtime (5), or a contained Haskell exception (6).

- **`hmath_cffi.HMathError` with status 2** — Shapes differ.

#### See also

[hmath.Tensor.dot](#hmathtensordotother), [hmath_cffi.Tensor](#hmath_cffitensorvalues-shapenone), [hmath_cffi.Tensor.close](#hmath_cffitensorclose).

#### Notes

This is the same whole-tensor scalar reduction as primary `dot`, not
matrix multiplication. See that entry for the equation and numerical behavior.



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

**Failure conditions by exception:**

- **`RuntimeError`** — A required Tensor handle is closed.

- **`hmath_cffi.HMathError`** — Non-finite computed result (3), native scratch/result allocation failure (4),
  unavailable runtime (5), or a contained Haskell exception (6).

- **`hmath_cffi.HMathError` with status 2** — Shapes differ.

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

**Failure conditions by exception:**

- **`RuntimeError`** — A required Tensor handle is closed.

- **`hmath_cffi.HMathError`** — Non-finite computed result (3), native scratch/result allocation failure (4),
  unavailable runtime (5), or a contained Haskell exception (6).

- **`hmath_cffi.HMathError`** — Rank/inner-dimension mismatch (2), or output/work budget exceeded (3).

#### See also

[hmath.Tensor.__matmul__](#hmathtensor__matmul__other-a-b), [hmath_cffi.Tensor](#hmath_cffitensorvalues-shapenone), [hmath_cffi.Tensor.close](#hmath_cffitensorclose).

#### Notes

The primary matrix-product definition and budgets apply: at most
1,048,576 output elements and 16,777,216 scalar multiply-add steps.
There is no batching or vector promotion.



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

#### Notes

Do not call concurrently with an operation using this handle. Numerical
operations and `values()` fail after close; cached `.shape` remains readable.
The shared runtime is not shut down.



### `hmath_cffi.Tensor.__enter__()`

Enter a context that owns this tensor handle.

#### Parameters

None.

#### Returns

the same live tensor in `with`.

#### Raises

`RuntimeError` after close. No new native owner is created.

**Failure conditions by exception:**

- **`RuntimeError`** — The handle is closed.

#### See also

[hmath.Tensor.__enter__](#hmathtensor__enter__), [hmath_cffi.Tensor](#hmath_cffitensorvalues-shapenone), [hmath_cffi.Tensor.close](#hmath_cffitensorclose).

#### Notes

As with the primary interface, nested contexts on the same object do not
create independent handle lifetimes.



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

## Public exception and cffi attributes

The following public attributes are also available on the Python objects.

### `hmath.HMathError.status`

<a id="hmath.HMathError.status"></a>

Read the native status captured by an exception.

#### Type

`int`.

#### See also

[hmath.HMathError](#hmath.HMathError), [native status definitions](c.md).

#### Notes

The value describes the failed native call, not a later operation. Prefer the
status and exception class over exact diagnostic text when classifying failures.

### `hmath_cffi.HMathError.status`

<a id="hmath_cffi.HMathError.status"></a>

Read the native status captured by a cffi exception.

#### Type

`int`.

#### See also

[hmath_cffi.HMathError](#hmath_cffi.HMathError), [native status definitions](c.md).

#### Notes

The same native numeric code definitions apply to both wrappers, even
though their Python exception classes differ.

### `hmath_cffi.Tensor.shape`

<a id="hmath_cffi.Tensor.shape"></a>

Read the cached shape of a cffi Tensor.

#### Type

`tuple[int, ...]`.

#### See also

[hmath_cffi.Tensor](#hmath_cffi.Tensor), [hmath.Tensor.shape](#hmath.Tensor.shape).

#### Notes

Unlike the primary interface's property, this is a stored Python attribute
and remains readable after `close()`. Treat it as read-only: assigning to it
does not reshape native storage and can make Python metadata inconsistent.

#### Examples

```python
import hmath_cffi as hc

with hc.Tensor([1, 2]) as tensor:
    assert tensor.shape == (2,)
assert tensor.shape == (2,)  # Cached metadata, not evidence of a live handle.
```

## Low-level cffi attributes

`hmath_cffi.ffi` is the configured `cffi.FFI` object; `hmath_cffi.lib` is the
loaded native handle exposing the declarations used by this wrapper. Raw calls
follow the [C ABI](c.md), including status and ownership rules. `tensor.ptr` is
borrowed: do not release it separately or use it after close. `tensor.shape`
is the construction/result shape tuple and must not be reassigned by callers.

## Native status codes

See the canonical [C status table](c.md#native-status-codes).
