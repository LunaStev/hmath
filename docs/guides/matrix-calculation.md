# Validate a matrix calculation

Use this guide when you have two matrices and need to choose between
elementwise addition, a scalar dot reduction, and matrix multiplication.
It uses the installed Python package and requires no optional dependencies.

## Choose the calculation

For two 2-by-2 matrices, all three operations are valid but produce different
results:

```python
from hmath import Tensor

with Tensor.matrix([1, 2, 3, 4], 2, 2) as a:
    with Tensor.matrix([5, 6, 7, 8], 2, 2) as b:
        with a + b as elementwise:
            assert elementwise.values() == [6.0, 8.0, 10.0, 12.0]
        assert a.dot(b) == 70.0
        with a @ b as product:
            assert product.shape == (2, 2)
            assert product.values() == [19.0, 22.0, 43.0, 50.0]
```

Matrix multiplication computes

$$
C_{ij} = \sum_{k=0}^{p-1} A_{ik} B_{kj},
\qquad A\in\mathbb{R}^{m\times p},\ B\in\mathbb{R}^{p\times n}.
$$

For a dot reduction, matching element positions are multiplied and all
products are added to one scalar. Neither operation broadcasts inputs.

## Handle incompatible dimensions

```python
from hmath import HMathError, Tensor

with Tensor.matrix([1, 2, 3, 4, 5, 6], 2, 3) as a:
    with Tensor.matrix([1, 2, 3, 4], 2, 2) as b:
        try:
            invalid = a @ b
        except HMathError as error:
            assert error.status == 2  # HMATH_SHAPE_ERROR
        else:
            invalid.close()
            raise AssertionError("Inner dimensions must agree")
```

All owned results have their own lifetime. A `with` block closes its result
even if a later assertion or operation fails. Inputs remain unchanged.

For general floating-point data, use a scale-appropriate approximate
comparison instead of the exact small-integer assertions in this example.
See [numerical conventions](../explanation/numerical-conventions.md),
[Python API](../reference/python.md), and [NumPy interoperability](numpy.md).
