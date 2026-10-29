# Numerical conventions

This page explains how to interpret numerical inputs and results. A function's
reference entry takes precedence when it defines a more specific contract.

## Numeric types and finite values

Python, C, and Wave tensor kernels use IEEE 754 binary64 (`float`, `double`,
and `f64`). Checked native kernels reject non-finite inputs/results. This
does not make floating-point arithmetic exact: rounding and cancellation
still occur for accepted finite values.

Haskell functions have the numeric type shown in their signature. Generic
`Num`, `Fractional`, or `Floating` functions inherit the selected type's
arithmetic. For example, bounded integers can overflow. A generic type
constraint alone does not promise finite-result validation.

## Shapes and storage

Row-major order means consecutive elements in a row are adjacent. For
`[[1, 2], [3, 4]]`, flat values are `[1, 2, 3, 4]`.

| Shape | Meaning | Logical element count |
| --- | --- | --- |
| `()` | Scalar | 1 |
| `(n,)` | Vector | n |
| `(m, n)` | Matrix | m × n |
| `(0, n)` | Empty matrix with n columns | 0 |

The native ABI bounds rank at 8 and logical element count at 1,048,576.
These are native-interface limits, not universal limits for every Haskell
module. Native strides count elements; NumPy strides count bytes. Storage
span and logical element count can differ for a strided view.

## Compare approximate results

Use exact equality for dimensions, counts, and deliberately exact small
examples. For general floating-point results, compare with explicit
absolute and relative tolerances:

$$
|x-y| \leq \max(\mathrm{atol},\ \mathrm{rtol}\,\max(|x|,|y|)).
$$

This is the symmetric rule used by Python's `math.isclose`; a particular
solver may use a different stopping rule. Choose tolerances for the scale
of your data and the required accuracy rather than copying a universal
constant. Absolute tolerance matters when the expected result is near zero.

```python
import math
from hmath import Tensor

with Tensor([0.1, 0.2]) as samples:
    assert math.isclose(samples.sum(), 0.3, rel_tol=1e-12, abs_tol=1e-15)
```

## Python reduction and matrix-product behavior

The Python wrappers call the checked native tensor kernels, not every
algorithm exposed by the Haskell library. The current reference path gathers
logical elements into contiguous native scratch arrays before entering
`HMath.FFI`. Sum uses ordinary Haskell `sum`; dot uses `HMath.Linear.dot`,
which sums corresponding products. Matrix multiplication accumulates each
cell in increasing inner-index order. These descriptions identify the current
implementation, not a cross-release promise of bit-for-bit reduction order.

The mathematical definition of a sum or dot product does not imply exact
accumulation, compensated summation, or a correctly rounded final answer.
Finite inputs can produce a non-finite computed result, which is rejected.
Conversely, a finite accepted result can still have substantial relative error
when cancellation makes the true result small. No universal error tolerance
is implied by accepting a result. The checked path is distinct from legacy
native calls that retain their own non-finite policies.

For `a.dot(b)`, all corresponding elements are reduced to a Python float and
the shapes must match exactly. This is not NumPy's rank-dependent `dot`.
For `a @ b`, `(m, k)` and `(k, n)` produce `(m, n)`; the binding supports rank
two only. The `m*k*n` work limit bounds computation, not numerical error.
A compatible zero inner dimension yields a zero matrix, while a zero outer
dimension yields an empty result. See the
[Python calculations reference](../reference/python.md#calculations) for
individual contracts, budgets, and costs.

Input conversion is another numerical step. Python integers do not remain
arbitrary-precision integers inside a Tensor: they are converted to binary64.
Likewise, copying a NumPy integer array to float64 can round values before
any HMath calculation takes place. For copied versus borrowed data and
lifetime guarantees, see [NumPy interoperability](../guides/numpy.md).

## Residual, conditioning, and rank

For a proposed solution of $A x = b$, the residual is
$r = A x - b$. A small residual checks that the computed vector nearly
satisfies the supplied equation. It does not by itself establish a small
solution error: an ill-conditioned problem can amplify small perturbations
in the data.

QR rank is a numerical decision controlled by a relative pivot tolerance.
`qrRank` is an estimate, not an exact algebraic proof. A rank-deficient
factorization can be inspected, while the QR least-squares solver rejects
it. See [QR contracts](../reference/qr.md) for the exact threshold and shapes.

## Errors and stopping conditions

| Interface | Failure reporting | What to inspect |
| --- | --- | --- |
| Python | `HMathError` or a documented Python exception | Exception type, `.status`, message |
| C | Checked status and thread-local diagnostic | Status immediately, then error message on the same thread |
| Wave | Wrapper/native status | Status; native message can be stale after wrapper-only rejection |
| Haskell checked API | `Either MathError a` | `Left` constructor or accepted `Right` result |
| Haskell legacy pure API | Function-specific precondition or pure error | Reference entry before calling |

An accepted result is not a universal accuracy guarantee. For iterative
methods, inspect the reported stopping reason and residual/error estimate.
An evaluation or iteration budget limits work; it is not a requested error
bound. Calculus `estimateError` values are numerical estimates, not rigorous
bounds on every possible callback.

## Further reading

- [SciPy linear solve](https://docs.scipy.org/doc/scipy/reference/generated/scipy.linalg.solve.html): shape contracts and singular/ill-conditioned systems.
- [GNU Scientific Library linear algebra](https://www.gnu.org/software/gsl/doc/html/linalg.html): decompositions, rank, and numerical tolerances.
- [Python `math.isclose`](https://docs.python.org/3/library/math.html#math.isclose): approximate comparison semantics.
