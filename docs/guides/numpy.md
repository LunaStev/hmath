# Work with NumPy arrays

Install the `numpy` extra as described in [installation](../getting-started/installation.md).

## Choose whether to copy

| Task | Input conversion | Output conversion | Ownership consequence |
| --- | --- | --- | --- |
| Keep working with a mutable source | `Tensor.from_numpy(source)` | `tensor.numpy()` | Both boundaries copy; each side can change independently. |
| Read eligible existing data without an element copy | `Tensor.from_numpy(source, copy=False)` | Either mode | All aliases to the borrowed input must stay immutable. |
| Inspect a result without an element copy | Either mode | `tensor.numpy(copy=False)` | A read-only view retains the result storage after the Tensor closes. |

Borrowing avoids copying the element buffer, not validation or object/metadata
allocation. It is an ownership choice, not a promise of constant-time input
conversion. Start with the copying path when another component may mutate data.

## Copy an array into a tensor

```python
import numpy as np
from hmath import Tensor

source = np.array([[1, 2], [3, 4]], dtype=np.float64)
with Tensor.from_numpy(source) as tensor:
    assert tensor.shape == (2, 2)
    assert np.array_equal(tensor.numpy(), source)
```

Both conversions copy by default. Later changes to the original array do not
change the copied tensor, and the returned NumPy array owns independent data.

## Borrow an array without copying

```python
import numpy as np
from hmath import Tensor

source = np.arange(12, dtype=np.float64).reshape(3, 4)
source.setflags(write=False)
with Tensor.from_numpy(source[:, ::2], copy=False) as tensor:
    view = tensor.numpy(copy=False)
    assert tensor.shape == (3, 2)
    assert tensor.sum() == 30.0
    assert np.shares_memory(view, source)
    assert not view.flags.writeable
```

Zero-copy input requires native-endian, aligned, read-only `float64` storage
and nonnegative strides that are multiples of eight bytes. Negative-stride
views and writable arrays are rejected with `ValueError`.

The caller must keep all aliases immutable until every tensor and derived
view has been released. Setting one array to read-only cannot prevent writes
through another writable alias.

A NumPy view retains a native reference and its borrowed array owner, so it
remains valid after the original tensor is closed. Release the view when it
is no longer needed. Empty arrays can use a separate empty NumPy allocation.


## Handle a conversion that needs copying

A reversed NumPy slice has a negative stride. Copy it explicitly instead of
relying on implicit fallback:

```python
import numpy as np
from hmath import Tensor

source = np.arange(4, dtype=np.float64)
source.setflags(write=False)
reversed_source = source[::-1]
try:
    with Tensor.from_numpy(reversed_source, copy=False):
        pass
except ValueError:
    pass
else:
    raise AssertionError("negative-stride borrowing must be rejected")
with Tensor.from_numpy(reversed_source, copy=True) as tensor:
    assert tensor.values() == [3.0, 2.0, 1.0, 0.0]
```

For other failures, inspect the exception rather than catching every error and
silently copying: non-finite data and oversized layouts can remain invalid even
when copied. `numpy.asarray` normalization can allocate for array-like inputs
before HMath reaches its borrowing checks.


## Keep a result view after closing its handle

```python
import numpy as np
from hmath import Tensor

with Tensor([1, 2, 3, 4], (2, 2)) as tensor:
    view = tensor.numpy(copy=False)
    column = view[:, 1]
    assert np.shares_memory(column, view)
del view
assert column.tolist() == [2.0, 4.0]
assert not column.flags.writeable
del column
```

The view's backing buffer retains native storage and any borrowed array owner.
A derived view keeps that ownership chain alive. Closing a Tensor releases its
handle, not all references to the storage. Release views when no longer needed.
For empty arrays, `numpy(copy=False)` can use a separate empty read-only
allocation; there are no element bytes to share.


## Reshape a borrowed tensor deliberately

Borrowing accepts some layouts that `reshape()` does not. A non-contiguous
Tensor cannot be reshaped by silently copying. When copying is acceptable,
create a contiguous Tensor explicitly:

```python
import numpy as np
from hmath import Tensor

source = np.arange(8, dtype=np.float64)
source.setflags(write=False)
with Tensor.from_numpy(source[::2], copy=True) as contiguous:
    with contiguous.reshape((2, 2)) as matrix:
        assert matrix.numpy().tolist() == [[0.0, 2.0], [4.0, 6.0]]
```

See [Tensor.reshape](../reference/python.md#hmath.Tensor.reshape) for its exact
contiguity and shape rules. Unlike NumPy's reshape, it does not infer `-1` or
fall back to a copy.


## Compare a calculation with NumPy

Use the same operation on each side. HMath `dot()` reduces corresponding
products at every rank; NumPy `dot()` has different higher-rank semantics.
For matrix multiplication, compare `@` with `@`:

```python
import numpy as np
from hmath import Tensor

left = np.array([[0.1, 0.2], [0.3, 0.4]], dtype=np.float64)
right = np.array([[0.5], [0.6]], dtype=np.float64)
with Tensor.from_numpy(left) as a, Tensor.from_numpy(right) as b:
    with a @ b as result:
        actual = result.numpy()
expected = left @ right
assert actual.shape == expected.shape
np.testing.assert_allclose(actual, expected, rtol=1e-12, atol=1e-15)
```

These tolerances belong to this example, not to a library-wide accuracy
guarantee. Choose tolerances for the scale and conditioning of the actual
problem. See [numerical conventions](../explanation/numerical-conventions.md)
and [validate a matrix calculation](matrix-calculation.md).
