# Python API

<!-- hmath:examples independent -->

This reference describes the Python interfaces in HMath **@HMATH_VERSION@**,
using native **ABI 1**. Install `hmath-python` and import `hmath`; the distribution
name and the import name are different. See [installation](../getting-started/installation.md)
for supported wheels and optional dependencies.

`hmath` is the primary interface. `hmath_cffi` is an optional, smaller interface
to the same native runtime. This page documents their public Python operations,
not every function available in the C ABI or the Haskell library. Each Python
example below includes its own imports and runs in a separate process during
documentation checks, including the final-shutdown example.

## Function index

| Area | Primary interface | Optional cffi interface |
| --- | --- | --- |
| Runtime | [initialize](#hmath.initialize), [shutdown](#hmath.shutdown) | Initialized when the module is imported. |
| Scalars | [add](#hmath.add) | [add](#hmath_cffi.add) |
| Exceptions | [HMathError](#hmath.HMathError), [status](#hmath.HMathError.status) | [HMathError](#hmath_cffi.HMathError), [status](#hmath_cffi.HMathError.status), [check](#hmath_cffi.check) |
| Construction | [Tensor](#hmath.Tensor), [scalar](#hmath.Tensor.scalar), [matrix](#hmath.Tensor.matrix), [from_numpy](#hmath.Tensor.from_numpy) | [Tensor](#hmath_cffi.Tensor) |
| Inspection | [shape](#hmath.Tensor.shape), [values](#hmath.Tensor.values), [numpy](#hmath.Tensor.numpy) | [shape](#hmath_cffi.Tensor.shape), [values](#hmath_cffi.Tensor.values) |
| Calculations | [sum](#hmath.Tensor.sum), [dot](#hmath.Tensor.dot), [+](#hmath.Tensor.__add__), [@](#hmath.Tensor.__matmul__) | [sum](#hmath_cffi.Tensor.sum), [dot](#hmath_cffi.Tensor.dot), [+](#hmath_cffi.Tensor.__add__), [@](#hmath_cffi.Tensor.__matmul__) |
| Shape changes | [reshape](#hmath.Tensor.reshape) | Not exposed. |
| Lifetime | [close](#hmath.Tensor.close), [with](#hmath.Tensor.__enter__), [exit](#hmath.Tensor.__exit__), [finalizer](#hmath.Tensor.__del__) | [close](#hmath_cffi.Tensor.close), [with](#hmath_cffi.Tensor.__enter__), [exit](#hmath_cffi.Tensor.__exit__) |

## Common contracts

### Numeric values and shapes

Tensor elements and scalar calculations use finite IEEE 754 binary64 values.
Python integers are converted to this representation; arbitrary-size integer
arithmetic is not provided. Rounding can occur during conversion and arithmetic.
NaN and infinity are rejected as native inputs, and a non-finite computed result
is reported as an error rather than returned as a successful value.

| Shape | Meaning | Required number of values |
| --- | --- | --- |
| `()` | Rank-zero scalar | 1 |
| `(n,)` | Vector | n |
| `(m, n)` | Matrix | m × n |
| `(0, n)` | Empty matrix | 0 |

Shapes contain at most **8** dimensions. Each dimension must be a built-in
Python `int` in `[0, 1_048_576]`; `bool`, integer subclasses, and NumPy integer
scalars are not accepted as dimensions by the Python shape validator. Convert
such dimensions explicitly with `int()` when appropriate. The logical element
count must not exceed **1,048,576**. Borrowed layouts also have bounded strides
and a bounded reachable storage span. A zero dimension makes the logical count
zero, but does not waive the other layout checks. `-1` dimension inference is
not supported.

`values` inputs are flat, in logical row-major (C) order. Nested lists belong
in `Tensor.from_numpy(...)`, not in the flat `Tensor(...)` constructor. Shape
must match exactly for elementwise addition and `dot`; there is no implicit
broadcasting. `@` accepts compatible rank-two matrices only.

### Ownership and concurrency

Every returned Tensor owns a native handle. Use `with` or `close()` to release
that handle. `reshape()` and NumPy views can retain the same storage through
independent references; closing one handle does not close those references.
Tensor operations do not mutate their inputs.

The primary interface locks handle operations, including `close()`. A sequence
of separate calls is not an atomic transaction, and locking cannot protect
against writes through external NumPy aliases. In particular, entering a
`with` block does not reserve a handle against another thread closing it.
The cffi interface has no corresponding per-handle locks: callers must prevent
concurrent close/use. Process-wide shutdown requires application-level
coordination for both interfaces. See [architecture and ownership](../explanation/architecture.md).

### Errors

| Layer | Exception or status | Interpretation |
| --- | --- | --- |
| Python shape/size validation | `ValueError` | A Python-side dimension, rank, size, or borrowing condition is invalid. |
| Input conversion | `TypeError`, `ValueError`, `OverflowError`, or `ctypes.ArgumentError` | Conversion failed before a native checked operation; the exact class depends on the wrapper and conversion path. |
| Closed primary/cffi handle | `RuntimeError` | An operation requires a live handle. |
| Native checked operation | The interface's `HMathError` | Inspect `.status` and `str(error)`. |
| Missing optional dependency | `ImportError` | The requested NumPy or cffi functionality is unavailable. |

Frequently relevant native codes are 1 (invalid/non-finite input), 2 (shape),
3 (overflow, non-finite result, or a work/layout budget), 4 (allocation),
5 (runtime unavailable), 6 (contained Haskell exception), and 9 (shutdown busy).
The [C ABI status table](c.md) is authoritative for names and numeric values;
not every C status is reachable from every Python operation. Exception messages
provide diagnostics, not a stable string-matching API. Allocation of Python
objects can also raise `MemoryError`; iterator and conversion hooks can propagate
their own exceptions. The entries below describe the expected API-specific cases.

Both wrappers require ABI 1. Module import can fail before any function call if
the native library cannot be loaded or the ABI is incompatible. See
[troubleshooting](../guides/troubleshooting.md).

## Module functions

### `hmath.initialize()`

<a id="hmath.initialize"></a>

Initialize the process-wide numerical runtime.

#### Parameters

None.

#### Returns

`None`.

#### Raises

`RuntimeError`
: The native ABI is incompatible, or the runtime was permanently shut down.

#### See Also

[hmath.shutdown](#hmath.shutdown), [hmath.add](#hmath.add).

#### Notes

Repeated initialization is allowed. Tensor construction and `add()` already
initialize automatically. This does not create a private runtime or a resource
that each caller should later shut down.

#### Examples

```python
from hmath import initialize

initialize()
initialize()  # Repeated initialization is allowed.
```

### `hmath.add(a, b)`

<a id="hmath.add"></a>

Add two finite real scalars.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `a` | `real scalar` | First operand, convertible to C `double` by ctypes. |
| `b` | `real scalar` | Second operand, convertible to C `double` by ctypes. |

#### Returns

`float`
: The binary64 sum of the converted operands.

#### Raises

`ctypes.ArgumentError`
: ctypes cannot convert an operand to the declared C argument type.

`RuntimeError`
: Automatic initialization finds an incompatible or shut-down runtime.

`HMathError`
: Non-finite input (status 1), non-finite result (3), runtime failure (5),
  or a contained Haskell exception (6).

#### See Also

[Tensor addition](#hmath.Tensor.__add__), [hmath.initialize](#hmath.initialize).

#### Notes

This is scalar addition, not broadcasting over a Tensor. A finite result is
not an exact-arithmetic guarantee. Use an application-appropriate tolerance for
non-exact floating-point comparisons.

#### Examples

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

### `hmath.shutdown()`

<a id="hmath.shutdown"></a>

Permanently shut down the process-owned numerical runtime.

#### Parameters

None.

#### Returns

`None` on successful shutdown.

#### Raises

`HMathError`
: Active work prevents shutdown (status 9). Join the numerical workers and
  retry only after all users have finished.

#### See Also

[hmath.initialize](#hmath.initialize), [hmath.Tensor.close](#hmath.Tensor.close).

#### Notes

Only the process owner should call this, after joining numerical users and
releasing their resources. It is not per-Tensor cleanup. A successful shutdown
is irreversible: later `initialize()` calls fail. Applications may instead let
process exit clean up the runtime. This example runs in its own process.

#### Examples

```python
from hmath import add, initialize, shutdown

assert add(1, 2) == 3.0
shutdown()
try:
    initialize()
except RuntimeError:
    pass
else:
    raise AssertionError("a shut-down runtime must not restart")
```

### `hmath.HMathError(status)`

<a id="hmath.HMathError"></a>

Represent a failed native checked operation.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `status` | `int` | Native failure code captured by the wrapper. |

#### Attributes

`status` : `int`
: Native failure code; see [HMathError.status](#hmath.HMathError.status).

#### See Also

[hmath.HMathError.status](#hmath.HMathError.status), [hmath_cffi.HMathError](#hmath_cffi.HMathError).

#### Notes

This exception inherits from `RuntimeError`. `str(error)` holds a snapshot of
the calling thread's native diagnostic. Catch exceptions raised by operations;
manually constructing this class does not perform an operation or generate a
new diagnostic. The cffi exception is a different Python class.

#### Examples

```python
from hmath import HMathError, Tensor

try:
    with Tensor([1, 2], (3,)):
        pass
except HMathError as error:
    assert error.status == 2
    assert str(error)
else:
    raise AssertionError("shape mismatch must be rejected")
```

### `hmath.HMathError.status`

<a id="hmath.HMathError.status"></a>

Read the native status captured by an exception.

#### Type

`int`.

#### See Also

[hmath.HMathError](#hmath.HMathError), [native status definitions](c.md).

#### Notes

The value describes the failed native call, not a later operation. Prefer the
status and exception class over exact diagnostic text when classifying failures.

## Construction

### `hmath.Tensor(values, shape=None)`

<a id="hmath.Tensor"></a>

Own an immutable binary64 tensor copied from flat values.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `values` | `iterable of real scalars` | Finite values in logical row-major order. Generators are accepted; nested sequences are not flat values. |
| `shape` | `iterable of int or None; default None` | Dimensions obeying the common shape contract. `None` chooses `(number_of_values,)`. |

#### Raises

`ValueError`
: Python rank/dimension validation fails, or more than 1,048,576 values
  are consumed.

`TypeError`, `ValueError`, `OverflowError`
: The iterable or an element cannot be converted by the Python/ctypes path.

`RuntimeError`
: Automatic initialization cannot use the runtime.

`HMathError`
: The shape product exceeds a native budget (3), count differs from the shape
  product (2), an element is non-finite (1), or native allocation fails (4).

#### Attributes

`shape` : `tuple[int, ...]`
: Read-only dimensions; see [Tensor.shape](#hmath.Tensor.shape).

#### See Also

[hmath.Tensor.scalar](#hmath.Tensor.scalar), [hmath.Tensor.matrix](#hmath.Tensor.matrix), [hmath.Tensor.from_numpy](#hmath.Tensor.from_numpy).

#### Notes

The constructor consumes at most 1,048,577 values to detect oversized input.
It copies values, so later changes to a source list do not affect the tensor.
The object owns one handle; use a context manager or `close()`.

Shape `()` requires exactly one value; shape `(1,)` describes a vector instead.
For shape `(m, n)`, flat position `i*n + j` corresponds to row `i`, column `j`.
A rank-zero tensor and a one-element vector are not interchangeable operands
for operations requiring equal shapes.

#### Examples

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

### `hmath.Tensor.scalar(value)`

<a id="hmath.Tensor.scalar"></a>

Construct a rank-zero tensor from one finite value.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `value` | `real scalar` | Value converted to binary64; integers do not remain integer-typed storage. |

#### Returns

`Tensor`
: New owned tensor with shape `()` and exactly one element.

#### Raises

`TypeError`, `ValueError`, `OverflowError`
: The value cannot be converted by the constructor.

`RuntimeError`
: Automatic initialization fails.

`HMathError`
: The converted value is non-finite (1), or native allocation fails (4).

#### See Also

[hmath.Tensor](#hmath.Tensor), [hmath.Tensor.shape](#hmath.Tensor.shape).

#### Examples

```python
from hmath import Tensor

with Tensor.scalar(7) as scalar, Tensor([7]) as vector:
    assert scalar.shape == ()
    assert vector.shape == (1,)
    assert scalar.values() == vector.values() == [7.0]
```

### `hmath.Tensor.matrix(values, rows, columns)`

<a id="hmath.Tensor.matrix"></a>

Construct a rank-two matrix from flat row-major values.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `values` | `iterable of real scalars` | Exactly `rows * columns` finite values in row-major order. |
| `rows` | `int` | Built-in Python integer in `[0, 1_048_576]`; booleans are rejected. |
| `columns` | `int` | Built-in Python integer in `[0, 1_048_576]`; booleans are rejected. |

#### Returns

`Tensor`
: New owned tensor with shape `(rows, columns)`.

#### Raises

`ValueError`
: Invalid dimensions or an oversized value sequence.

`TypeError`, `OverflowError`
: Values cannot be converted to the constructor's numeric representation.

`RuntimeError`
: Automatic initialization fails.

`HMathError`
: Count mismatch (2), native layout budget (3), non-finite values (1),
  or allocation failure (4). Conversion hooks may also propagate `ValueError`.

#### See Also

[hmath.Tensor](#hmath.Tensor), [matrix multiplication](#hmath.Tensor.__matmul__).

#### Notes

Equivalent to `Tensor(values, (rows, columns))`. Zero rows or zero columns
require an empty value sequence. This constructor does not infer dimensions.

#### Examples

```python
from hmath import Tensor

with Tensor.matrix([1, 2, 3, 4, 5, 6], 2, 3) as matrix:
    assert matrix.shape == (2, 3)
    assert matrix.values() == [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
```

### `hmath.Tensor.from_numpy(array, copy=True)`

<a id="hmath.Tensor.from_numpy"></a>

Create a tensor by copying or borrowing NumPy-compatible data.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `array` | `numpy.ndarray or array-like` | Input normalized with `numpy.asarray`; shape is preserved. |
| `copy` | `bool; default True` | `True` converts to float64 and copies. `False` borrows only eligible read-only storage; there is no copy fallback. |

#### Returns

`Tensor`
: New owned handle with the normalized array's shape. In borrowing mode the
  handle retains the normalized NumPy array as its storage owner.

#### Raises

`ImportError`
: NumPy is not installed.

`ValueError`
: Rank/element or Python dimension bounds fail; borrowing receives a writable,
  misaligned, non-native-endian, or non-float64 array; or strides are negative
  or not whole multiples of eight bytes. NumPy conversion may also raise it.

`TypeError`, `OverflowError`
: NumPy/Python cannot convert the input.

`RuntimeError`
: Automatic initialization fails.

`HMathError`
: Native layout/span budgets (3 or 8), non-finite reachable elements (1),
  or native allocation failure (4).

#### See Also

[hmath.Tensor.numpy](#hmath.Tensor.numpy), [hmath.Tensor.reshape](#hmath.Tensor.reshape), [NumPy guide](../guides/numpy.md).

#### Notes

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

## Inspection and conversion

### `hmath.Tensor.shape`

<a id="hmath.Tensor.shape"></a>

Read the dimensions of a live tensor.

#### Type

`tuple[int, ...]`; this is a read-only property, not a method.

#### Raises

`RuntimeError`
: The handle is closed.

`HMathError`
: Native metadata retrieval fails.

#### See Also

[hmath.Tensor](#hmath.Tensor), [hmath.Tensor.reshape](#hmath.Tensor.reshape).

#### Notes

Shape `()` denotes one scalar, while a shape containing zero denotes an
empty tensor. Reading the property does not copy the element buffer.

#### Examples

```python
from hmath import Tensor

with Tensor.scalar(2) as scalar, Tensor([], (0, 3)) as empty:
    assert scalar.shape == ()
    assert empty.shape == (0, 3)
```

### `hmath.Tensor.values()`

<a id="hmath.Tensor.values"></a>

Copy logical elements to a flat Python list.

#### Parameters

None.

#### Returns

`list[float]`
: Independent values in logical row-major order. Empty tensors produce `[]`;
  scalars produce a one-element list.

#### Raises

`RuntimeError`
: The handle is closed.

`HMathError`
: Native copy validation fails.

#### See Also

[hmath.Tensor.numpy](#hmath.Tensor.numpy), [hmath.Tensor.shape](#hmath.Tensor.shape).

#### Notes

Strided input is gathered in logical order, not raw storage-span order.
The list remains valid after the Tensor closes. Copying N elements takes
O(N) output space; this is not a zero-copy access method.

#### Examples

```python
from hmath import Tensor

with Tensor([2, 4]) as tensor:
    values = tensor.values()
    values[0] = 99.0
    assert tensor.values() == [2.0, 4.0]
assert values == [99.0, 4.0]
```

### `hmath.Tensor.numpy(copy=True)`

<a id="hmath.Tensor.numpy"></a>

Return a NumPy copy or a read-only view of tensor storage.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `copy` | `bool; default True` | `True` returns independent writable storage; `False` returns a read-only view for nonempty storage. |

#### Returns

`numpy.ndarray`
: Float64 array with the tensor's logical shape. A non-copying view preserves
  the tensor's strides and retains storage independently of this handle.

#### Raises

`ImportError`
: NumPy is unavailable.

`RuntimeError`
: The handle is closed.

`HMathError`
: Native data, metadata, or copy retrieval fails.

#### See Also

[hmath.Tensor.from_numpy](#hmath.Tensor.from_numpy), [hmath.Tensor.values](#hmath.Tensor.values), [hmath.Tensor.close](#hmath.Tensor.close).

#### Notes

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

## Calculations

### `hmath.Tensor.sum()`

<a id="hmath.Tensor.sum"></a>

Sum every logical element to one scalar.

#### Parameters

None.

#### Returns

`float`
: The sum of all elements, or `0.0` for an empty tensor.

#### Raises

`RuntimeError`
: A required Tensor handle is closed.

`HMathError`
: Non-finite computed result (3), native scratch/result allocation failure (4),
  unavailable runtime (5), or a contained Haskell exception (6).

#### See Also

[hmath.Tensor.dot](#hmath.Tensor.dot), [numerical conventions](../explanation/numerical-conventions.md).

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
import math
from hmath import Tensor

with Tensor([1, 2, 3, 4], (2, 2)) as matrix:
    assert matrix.sum() == 10.0
with Tensor([], (0, 3)) as empty:
    assert empty.sum() == 0.0
with Tensor([0.1, 0.2]) as samples:
    assert math.isclose(samples.sum(), 0.3, rel_tol=1e-12, abs_tol=1e-15)
```

### `hmath.Tensor.dot(other)`

<a id="hmath.Tensor.dot"></a>

Sum corresponding products of two identically shaped tensors.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `other` | `Tensor` | Live primary-interface Tensor with exactly the same shape, including rank. |

#### Returns

`float`
: Scalar sum of corresponding products at every rank; `0.0` for matching empty tensors.

#### Raises

`RuntimeError`
: A required Tensor handle is closed.

`HMathError`
: Non-finite computed result (3), native scratch/result allocation failure (4),
  unavailable runtime (5), or a contained Haskell exception (6).

`HMathError` with status 2
: The operand shapes differ, even when their total element counts are equal.

#### See Also

[hmath.Tensor.sum](#hmath.Tensor.sum), [matrix multiplication](#hmath.Tensor.__matmul__).

#### Notes

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

#### References

[NumPy dot](https://numpy.org/doc/stable/reference/generated/numpy.dot.html)
documents the different NumPy semantics; it is not a compatibility claim.

#### Examples

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

### `hmath.Tensor.__add__(other)` — `a + b`

<a id="hmath.Tensor.__add__"></a>

Add two tensors element by element.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `other` | `Tensor` | Live primary-interface Tensor with exactly the same shape. |

#### Returns

`Tensor`
: New owned tensor with the same shape and newly allocated result storage.
  Neither input is changed.

#### Raises

`RuntimeError`
: A required Tensor handle is closed.

`HMathError`
: Non-finite computed result (3), native scratch/result allocation failure (4),
  unavailable runtime (5), or a contained Haskell exception (6).

`HMathError` with status 2
: The shapes do not match.

#### See Also

[hmath.add](#hmath.add), [hmath.Tensor.dot](#hmath.Tensor.dot).

#### Notes

For each logical position, `result[i] = a[i] + b[i]`. Scalars represented
as rank-zero tensors can be added to other rank-zero tensors. `tensor + 1`
is not a supported scalar-broadcast operation. Work and result storage are O(N),
with additional O(N) scratch storage in the current native boundary.

#### Examples

```python
from hmath import Tensor

with Tensor([1, 2]) as a, Tensor([3, 4]) as b:
    with a + b as result:
        assert result.values() == [4.0, 6.0]
    assert a.values() == [1.0, 2.0]
```

### `hmath.Tensor.__matmul__(other)` — `a @ b`

<a id="hmath.Tensor.__matmul__"></a>

Multiply two compatible rank-two matrices.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `other` | `Tensor` | Live matrix of shape `(k, n)` when this matrix has shape `(m, k)`. |

#### Returns

`Tensor`
: New owned matrix of shape `(m, n)` with independent result storage.

#### Raises

`RuntimeError`
: A required Tensor handle is closed.

`HMathError`
: Non-finite computed result (3), native scratch/result allocation failure (4),
  unavailable runtime (5), or a contained Haskell exception (6).

`HMathError` with status 2
: An operand is not rank two or the inner dimensions differ.

`HMathError` with status 3
: Output size or the scalar-operation work budget is exceeded.

#### See Also

[hmath.Tensor.matrix](#hmath.Tensor.matrix), [hmath.Tensor.dot](#hmath.Tensor.dot), [matrix calculation guide](../guides/matrix-calculation.md).

#### Notes

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

### `hmath.Tensor.reshape(shape)`

<a id="hmath.Tensor.reshape"></a>

Create an independently owned handle with a new shape over shared storage.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `shape` | `iterable of int` | Built-in nonnegative dimensions with the same total element count; `-1` inference is unsupported. |

#### Returns

`Tensor`
: New handle sharing the contiguous element storage, not a new element copy.
  Original and result handles can be closed independently.

#### Raises

`ValueError`
: The Python shape/rank contract is violated.

`TypeError`
: `shape` is not iterable.

`RuntimeError`
: This handle is closed.

`HMathError`
: Count mismatch or non-contiguous storage (2), native layout budget (3),
  or new-handle allocation failure (4).

#### See Also

[hmath.Tensor.shape](#hmath.Tensor.shape), [hmath.Tensor.from_numpy](#hmath.Tensor.from_numpy).

#### Notes

No element reordering or copy fallback is performed. Contiguity is checked
by the native layout validator: singleton dimensions do not constrain strides,
and empty tensors are considered contiguous. A positive-stride borrowed view
can still be non-contiguous and rejected. The reshaped handle retains any
borrowed owner. Validation and metadata construction depend on rank, not on
copying all elements.

#### Examples

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

## Lifetime protocol

### `hmath.Tensor.close()`

<a id="hmath.Tensor.close"></a>

Release this Tensor handle deterministically.

#### Parameters

None.

#### Returns

`None`; repeated calls are harmless.

#### See Also

[hmath.Tensor.__enter__](#hmath.Tensor.__enter__), [hmath.Tensor.__exit__](#hmath.Tensor.__exit__), [hmath.Tensor.__del__](#hmath.Tensor.__del__).

#### Notes

After closing, handle-dependent operations raise `RuntimeError`. Retained
Tensor handles and NumPy views remain valid. This does not shut down the
process-wide runtime. Closing is synchronized with primary-interface handle
operations, not with arbitrary external writes to borrowed storage.

#### Examples

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

### `hmath.Tensor.__enter__()`

<a id="hmath.Tensor.__enter__"></a>

Enter a context for this live Tensor handle.

#### Parameters

None.

#### Returns

`Tensor`
: The same object, not an additional retained handle.

#### Raises

`RuntimeError`
: The handle is already closed.

#### See Also

[hmath.Tensor.__exit__](#hmath.Tensor.__exit__), [hmath.Tensor.close](#hmath.Tensor.close).

#### Notes

Use `with tensor:` or `with Tensor(...) as tensor:`. Nested contexts over
the same object do not create nested ownership: the inner exit closes that
handle. Create an independent retained result when independent lifetimes are needed.

### `hmath.Tensor.__exit__(*args)`

<a id="hmath.Tensor.__exit__"></a>

Close the handle when leaving a context.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `args` | `exception triple` | Python supplies exception type, exception value, and traceback, or three `None` values on normal exit. |

#### Returns

`None`. The original exception is not suppressed.

#### See Also

[hmath.Tensor.__enter__](#hmath.Tensor.__enter__), [hmath.Tensor.close](#hmath.Tensor.close).

#### Examples

```python
from hmath import Tensor

tensor = Tensor([1])
try:
    with tensor:
        raise ValueError("example failure")
except ValueError:
    pass
try:
    tensor.sum()
except RuntimeError:
    pass
else:
    raise AssertionError("exceptional exit must close the handle")
```

### `hmath.Tensor.__del__()`

<a id="hmath.Tensor.__del__"></a>

Release the handle as a finalization fallback.

#### Parameters

None.

#### Returns

`None`.

#### See Also

[hmath.Tensor.close](#hmath.Tensor.close), [hmath.Tensor.__enter__](#hmath.Tensor.__enter__).

#### Notes

Calls `close()` as a fallback. Do not rely on collection timing or call
this method directly as the usual cleanup API. Use `with` or `close()`.

## Optional cffi interface

Install `hmath-python[cffi]` and import `hmath_cffi`. Import verifies ABI 1 and
initializes the shared runtime. ABI/runtime problems can raise `RuntimeError`
at import; missing cffi raises `ImportError`.

Use only cffi Tensor operands with cffi operations. These objects are not
interchangeable with primary-interface Tensor objects. The mathematical
contracts and native budgets are shared, but Python conversion paths,
exception classes, initialization timing, and handle synchronization differ.
NumPy conversion, `reshape`, `scalar`, and `matrix` are not exposed here.

The common import alias used below is `hc`. Each example defines it independently.

### `hmath_cffi.add(a, b)`

<a id="hmath_cffi.add"></a>

Add two finite scalars through the cffi binding.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `a` | `real scalar` | First operand, convertible to C `double` by cffi. |
| `b` | `real scalar` | Second operand, convertible to C `double` by cffi. |

#### Returns

`float`
: Binary64 sum.

#### Raises

`TypeError`, `OverflowError`
: cffi cannot convert an operand; conversion hooks can propagate other exceptions.

`hmath_cffi.HMathError`
: Non-finite input (1), non-finite result (3), unavailable runtime (5),
  or contained Haskell exception (6).

#### See Also

[hmath.add](#hmath.add), [hmath_cffi.HMathError](#hmath_cffi.HMathError).

#### Notes

Unlike primary `add()`, this function does not itself reinitialize the runtime.
Initialization happens during module import.

#### Examples

```python
import hmath_cffi as hc

assert hc.add(2, 3.5) == 5.5
```

### `hmath_cffi.HMathError(status)`

<a id="hmath_cffi.HMathError"></a>

Represent a failed native operation through the cffi interface.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `status` | `int` | Native failure code captured by this wrapper. |

#### Attributes

`status` : `int`
: Captured code; see [cffi HMathError.status](#hmath_cffi.HMathError.status).

#### See Also

[hmath.HMathError](#hmath.HMathError), [hmath_cffi.check](#hmath_cffi.check).

#### Notes

Inherits from `RuntimeError`, but is not `hmath.HMathError`. Catch the
exception class belonging to the interface being used. The message snapshots
the calling thread's diagnostic; manual construction reads the current native
message rather than performing a new operation.

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

### `hmath_cffi.HMathError.status`

<a id="hmath_cffi.HMathError.status"></a>

Read the native status captured by a cffi exception.

#### Type

`int`.

#### See Also

[hmath_cffi.HMathError](#hmath_cffi.HMathError), [native status definitions](c.md).

#### Notes

The same native numeric code definitions apply to both wrappers, even
though their Python exception classes differ.

### `hmath_cffi.check(status)`

<a id="hmath_cffi.check"></a>

Raise a cffi exception for a nonzero native status.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `status` | `int` | Status from the immediately preceding checked native operation. |

#### Returns

`None` for status zero.

#### Raises

`hmath_cffi.HMathError`
: The supplied status is nonzero; `.status` is the supplied code.

#### See Also

[hmath_cffi.HMathError](#hmath_cffi.HMathError), [hmath_cffi.add](#hmath_cffi.add).

#### Notes

The wrapper uses this helper internally. If using it with a raw checked
call, invoke it immediately on the same thread so another operation cannot
replace the diagnostic. High-level operations already call it; users do not
need to wrap `Tensor.sum()` or `add()` in another `check()`.

#### Examples

```python
import hmath_cffi as hc

assert hc.check(0) is None
```

### `hmath_cffi.Tensor(values, shape=None)`

<a id="hmath_cffi.Tensor"></a>

Own an immutable tensor through the optional cffi binding.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `values` | `iterable of real scalars` | Flat finite row-major values; at most 1,048,576 elements. |
| `shape` | `iterable of int or None; default None` | Built-in Python dimensions under the common shape contract. `None` selects `(number_of_values,)`. |

#### Raises

`ValueError`
: Rank, Python dimension, or input-count validation fails.

`TypeError`, `OverflowError`
: cffi cannot convert values; conversion hooks can propagate other exceptions.

`hmath_cffi.HMathError`
: Count mismatch (2), layout budget (3), non-finite data (1), or native
  allocation failure (4).

#### Attributes

`shape` : `tuple[int, ...]`
: Cached dimensions; see [cffi Tensor.shape](#hmath_cffi.Tensor.shape).

#### See Also

[hmath.Tensor](#hmath.Tensor), [hmath_cffi.Tensor.close](#hmath_cffi.Tensor.close).

#### Notes

Values are copied. The constructor consumes at most 1,048,577 values to
detect oversized input. Use `with` or `close()`; do not close this handle
concurrently with an operation using it. Runtime initialization occurs on
module import. Garbage-collection cleanup is a fallback, not a deterministic
replacement for explicit cleanup.

#### Examples

```python
import hmath_cffi as hc

with hc.Tensor([1, 2, 3, 4], (2, 2)) as matrix:
    assert matrix.shape == (2, 2)
    with matrix @ matrix as squared:
        assert squared.values() == [7.0, 10.0, 15.0, 22.0]
```

### `hmath_cffi.Tensor.shape`

<a id="hmath_cffi.Tensor.shape"></a>

Read the cached shape of a cffi Tensor.

#### Type

`tuple[int, ...]`.

#### See Also

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

### `hmath_cffi.Tensor.values()`

<a id="hmath_cffi.Tensor.values"></a>

Copy a cffi Tensor to a flat Python list.

#### Parameters

None.

#### Returns

`list[float]`
: Independent row-major values; `[]` for an empty tensor.

#### Raises

`RuntimeError`
: The handle is closed.

`hmath_cffi.HMathError`
: Native copy validation fails.

#### See Also

[hmath.Tensor.values](#hmath.Tensor.values), [hmath_cffi.Tensor.close](#hmath_cffi.Tensor.close).

#### Examples

```python
import hmath_cffi as hc

with hc.Tensor([2, 4]) as tensor:
    values = tensor.values()
assert values == [2.0, 4.0]
```

### `hmath_cffi.Tensor.sum()`

<a id="hmath_cffi.Tensor.sum"></a>

Sum every element of a cffi Tensor.

#### Parameters

None.

#### Returns

`float`
: Scalar sum, or `0.0` for an empty tensor.

#### Raises

`RuntimeError`
: A required Tensor handle is closed.

`hmath_cffi.HMathError`
: Non-finite computed result (3), native scratch/result allocation failure (4),
  unavailable runtime (5), or a contained Haskell exception (6).

#### See Also

[hmath.Tensor.sum](#hmath.Tensor.sum), [hmath_cffi.Tensor.dot](#hmath_cffi.Tensor.dot).

#### Notes

The whole-tensor reduction, numerical behavior, and native scratch costs
are the same as primary `Tensor.sum()`. No axis argument is exposed.

#### Examples

```python
import hmath_cffi as hc

with hc.Tensor([1, 2, 3]) as tensor, hc.Tensor([]) as empty:
    assert tensor.sum() == 6.0
    assert empty.sum() == 0.0
```

### `hmath_cffi.Tensor.dot(other)`

<a id="hmath_cffi.Tensor.dot"></a>

Sum corresponding products of identically shaped cffi tensors.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `other` | `hmath_cffi.Tensor` | Live cffi Tensor with exactly the same shape. |

#### Returns

`float`
: Sum of corresponding products; `0.0` for matching empty tensors.

#### Raises

`RuntimeError`
: A required Tensor handle is closed.

`hmath_cffi.HMathError`
: Non-finite computed result (3), native scratch/result allocation failure (4),
  unavailable runtime (5), or a contained Haskell exception (6).

`hmath_cffi.HMathError` with status 2
: Shapes differ.

#### See Also

[hmath.Tensor.dot](#hmath.Tensor.dot), [hmath_cffi.Tensor.__matmul__](#hmath_cffi.Tensor.__matmul__).

#### Notes

This is the same whole-tensor scalar reduction as primary `dot`, not
matrix multiplication. See that entry for the equation and numerical behavior.

#### Examples

```python
import hmath_cffi as hc

with hc.Tensor([1, 2, 3]) as a, hc.Tensor([4, 5, 6]) as b:
    assert a.dot(b) == 32.0
```

### `hmath_cffi.Tensor.__add__(other)` — `a + b`

<a id="hmath_cffi.Tensor.__add__"></a>

Add two cffi tensors element by element.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `other` | `hmath_cffi.Tensor` | Live cffi Tensor with exactly the same shape; no broadcasting. |

#### Returns

`hmath_cffi.Tensor`
: New owned result with independent storage and unchanged input tensors.

#### Raises

`RuntimeError`
: A required Tensor handle is closed.

`hmath_cffi.HMathError`
: Non-finite computed result (3), native scratch/result allocation failure (4),
  unavailable runtime (5), or a contained Haskell exception (6).

`hmath_cffi.HMathError` with status 2
: Shapes differ.

#### See Also

[hmath.Tensor.__add__](#hmath.Tensor.__add__), [hmath_cffi.add](#hmath_cffi.add).

#### Examples

```python
import hmath_cffi as hc

with hc.Tensor([1, 2]) as a, hc.Tensor([3, 4]) as b:
    with a + b as result:
        assert result.values() == [4.0, 6.0]
```

### `hmath_cffi.Tensor.__matmul__(other)` — `a @ b`

<a id="hmath_cffi.Tensor.__matmul__"></a>

Multiply two compatible rank-two cffi matrices.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `other` | `hmath_cffi.Tensor` | Live shape `(k, n)` matrix when this matrix has shape `(m, k)`. |

#### Returns

`hmath_cffi.Tensor`
: New owned matrix with shape `(m, n)` and independent storage.

#### Raises

`RuntimeError`
: A required Tensor handle is closed.

`hmath_cffi.HMathError`
: Non-finite computed result (3), native scratch/result allocation failure (4),
  unavailable runtime (5), or a contained Haskell exception (6).

`hmath_cffi.HMathError`
: Rank/inner-dimension mismatch (2), or output/work budget exceeded (3).

#### See Also

[hmath.Tensor.__matmul__](#hmath.Tensor.__matmul__), [hmath_cffi.Tensor.dot](#hmath_cffi.Tensor.dot).

#### Notes

The primary matrix-product definition and budgets apply: at most
1,048,576 output elements and 16,777,216 scalar multiply-add steps.
There is no batching or vector promotion.

#### Examples

```python
import hmath_cffi as hc

with hc.Tensor([1, 2, 3, 4], (2, 2)) as a:
    with a @ a as result:
        assert result.shape == (2, 2)
        assert result.values() == [7.0, 10.0, 15.0, 22.0]
```

### `hmath_cffi.Tensor.close()`

<a id="hmath_cffi.Tensor.close"></a>

Release this cffi Tensor handle.

#### Parameters

None.

#### Returns

`None`. Repeated calls are harmless.

#### See Also

[hmath_cffi.Tensor.__enter__](#hmath_cffi.Tensor.__enter__), [hmath_cffi.Tensor.shape](#hmath_cffi.Tensor.shape).

#### Notes

Do not call concurrently with an operation using this handle. Numerical
operations and `values()` fail after close; cached `.shape` remains readable.
The shared runtime is not shut down.

#### Examples

```python
import hmath_cffi as hc

tensor = hc.Tensor([1])
tensor.close()
tensor.close()
```

### `hmath_cffi.Tensor.__enter__()`

<a id="hmath_cffi.Tensor.__enter__"></a>

Enter a context for a live cffi Tensor.

#### Parameters

None.

#### Returns

`hmath_cffi.Tensor`
: The same object, without an extra native reference.

#### Raises

`RuntimeError`
: The handle is closed.

#### See Also

[hmath_cffi.Tensor.__exit__](#hmath_cffi.Tensor.__exit__), [hmath_cffi.Tensor.close](#hmath_cffi.Tensor.close).

#### Notes

As with the primary interface, nested contexts on the same object do not
create independent handle lifetimes.

### `hmath_cffi.Tensor.__exit__(*args)`

<a id="hmath_cffi.Tensor.__exit__"></a>

Release a cffi Tensor on normal or exceptional context exit.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `args` | `exception triple` | Exception type, value, and traceback supplied by Python; all are `None` on normal exit. |

#### Returns

`None`. Exceptions are not suppressed.

#### See Also

[hmath_cffi.Tensor.__enter__](#hmath_cffi.Tensor.__enter__), [hmath_cffi.Tensor.close](#hmath_cffi.Tensor.close).

