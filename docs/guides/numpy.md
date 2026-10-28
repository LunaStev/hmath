# Work with NumPy arrays

Install the `numpy` extra as described in [installation](../getting-started/installation.md).

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
