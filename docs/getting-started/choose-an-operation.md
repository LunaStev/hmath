# Choose an operation

Start with the problem you want to solve, then select an available interface.
The Python wheel provides the native scalar/tensor interface. The Haskell
library additionally supplies the broader numerical algorithms below.

## Python, C, and Wave

| Task | Python | C | Wave |
| --- | --- | --- | --- |
| Add scalars | `add(a, b)` | `hmath_scalar_add` | `scalar_add` |
| Construct a matrix | `Tensor.matrix` | `hmath_matrix_copy` | `matrix_copy` |
| Sum all elements | `tensor.sum()` | `hmath_tensor_sum` | `tensor_sum` |
| Sum corresponding products | `a.dot(b)` | `hmath_tensor_dot` | `tensor_dot` |
| Add corresponding elements | `a + b` | `hmath_tensor_add` | `tensor_add` |
| Multiply two matrices | `a @ b` | `hmath_tensor_matmul` | `tensor_matmul` |
| Exchange NumPy arrays | `Tensor.from_numpy`, `tensor.numpy` | Storage/DLPack ABI | Use the C ABI |
| Reinterpret a contiguous shape | `tensor.reshape` | `hmath_tensor_reshape` | Use the C ABI |

`dot` reduces every corresponding product to a scalar at any rank. Matrix
multiplication requires rank two and matching inner dimensions. Elementwise
addition requires identical shapes. Broadcasting and batched matrix products
are not supported by these wrappers.

Read the [Python](../reference/python.md), [C](../reference/c.md), or
[Wave](../reference/wave.md) reference for complete contracts. The
[matrix calculation guide](../guides/matrix-calculation.md) demonstrates the
three operations on the same inputs.

## Haskell numerical algorithms

| Task | Start with | Guide / reference |
| --- | --- | --- |
| Solve a square linear system | `HMath.Matrix.LU.solve` | [Linear algebra API](../reference/haskell.md) |
| Fit an overdetermined linear model | `HMath.Matrix.QR.leastSquares` | [Least squares](../guides/least-squares.md) |
| Regularize a linear fit | `HMath.Matrix.QR.ridgeSolve` | [QR contracts](../reference/qr.md) |
| Estimate a derivative | `HMath.Calculus.derivative` | [Calculus](../guides/calculus.md) |
| Integrate a smooth finite-interval function | `HMath.Calculus.integrateComposite` | [Calculus](../guides/calculus.md) |
| Request adaptive integration | `HMath.Calculus.adaptiveIntegrate` | [Calculus](../guides/calculus.md) |
| Compute descriptive statistics | `HMath.Statistics` | [Summarize data](../guides/statistics.md) |
| Explore optimization, probability, graphs, or transforms | Select a numerical area | [Haskell module index](../reference/haskell.md) |

These functions require Haskell imports; they are not additional Python
functions. Check [numerical conventions](../explanation/numerical-conventions.md)
before selecting tolerances or interpreting convergence.
