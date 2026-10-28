# Your first calculation

This tutorial constructs a matrix, multiplies it, and reads the result.
Complete [installation](installation.md) first.

## Add two scalars

```python
from hmath import Tensor, add

assert add(2, 3) == 5.0
```

The Python interface calculates with IEEE 754 binary64 values, corresponding
to C `double`. Results are Python floats.

## Construct and multiply a matrix

HMath stores matrix values in row-major order. The list below represents
`[[1, 2], [3, 4]]`.

```python
from hmath import Tensor

with Tensor.matrix([1, 2, 3, 4], 2, 2) as matrix:
    assert matrix.shape == (2, 2)
    assert matrix.sum() == 10.0
    with matrix @ matrix as product:
        assert product.shape == (2, 2)
        assert product.values() == [7.0, 10.0, 15.0, 22.0]
```

The product follows ordinary matrix multiplication:

```text
[1 2] [1 2] = [ 7 10]
[3 4] [3 4]   [15 22]
```

Each `with` block releases its tensor when the block ends. Operators create
new tensors; they do not modify their operands.

## Handle invalid input

The number of values must equal the product of the dimensions:

```python
from hmath import HMathError, Tensor

try:
    Tensor([1.0], shape=(2, 2))
except HMathError as error:
    assert error.status == 2  # HMATH_SHAPE_ERROR
else:
    raise AssertionError("An invalid shape was accepted")
```

Continue with [NumPy interoperability](../guides/numpy.md), or consult
the [complete Python reference](../reference/python.md).
