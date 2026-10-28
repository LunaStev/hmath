# Haskell modules

Select a module below or in the sidebar to read its public types, function
signatures, input requirements, results, and failure conditions. Search accepts
function names as well as descriptive terms. Module pages are generated from
the same source revision as this site, including function, method, and record
field documentation.

| Area | Representative modules |
| --- | --- |
| Foundations | `HMath`, `HMath.Error`, `HMath.Numeric`, `HMath.Constants`, `HMath.Units` |
| Algebra | `HMath.Algebra`, `HMath.Polynomial`, `HMath.NumberTheory`, `HMath.Combinatorics` |
| Linear algebra | `HMath.Linear`, `HMath.Matrix`, `HMath.Matrix.LU`, `HMath.Matrix.QR`, `HMath.Sparse` |
| Calculus and solvers | `HMath.Calculus`, `HMath.Root`, `HMath.ODE`, `HMath.PDE`, `HMath.Interpolation` |
| Optimization | `HMath.Optimization`, `HMath.Autodiff` |
| Statistics | `HMath.Statistics`, `HMath.Probability`, `HMath.Random`, `HMath.TimeSeries` |
| Learning | `HMath.MachineLearning`, `HMath.DeepLearning` |
| Transforms and signals | `HMath.Fourier`, `HMath.Signal` |
| Geometry and images | `HMath.Geometry`, `HMath.Image`, `HMath.Rotation`, `HMath.Quaternion` |
| Discrete and symbolic | `HMath.Graph`, `HMath.Discrete`, `HMath.Symbolic`, `HMath.Expression` |
| Arrays and interchange | `HMath.Tensor`, `HMath.Interchange`, `HMath.API` |

The `HMath` facade re-exports selected foundational modules. Import additional
modules explicitly for other numerical domains. Checked APIs generally
return `Either MathError`; consult the function signature for the exact
error and result types.

## Read a checked result

The Haskell API covers more numerical domains than the C, Wave, and Python
bindings. Those bindings currently expose the native scalar/tensor interface;
a Haskell-only function is not automatically available in Python.

```haskell
import qualified HMath.Scalar as Scalar
import qualified HMath.Matrix as Matrix
import qualified HMath.Matrix.LU as LU

main :: IO ()
main = do
    print (Scalar.divide (6 :: Double) 2)  -- Right 3.0
    print (Scalar.divide (1 :: Double) 0)  -- Left (DomainError ...)
    let solution = do
            a <- Matrix.fromListChecked 2 2 [2, 0, 0, 4 :: Double]
            LU.solve a [6, 8]
    print solution  -- Right [3.0,2.0]
```

An `Either` result distinguishes input/numerical failure (`Left`) from an
accepted result (`Right`). Solver report fields additionally distinguish a
budget stop from convergence. Pure legacy functions such as `HMath.Basic.factorial`
and `HMath.Statistics.mean` can raise errors on invalid input; their entries
state those preconditions. IEEE/generic arithmetic APIs can retain host-type
overflow or NaN behavior when their contract does not add finite checks.

Build the complete local site with:

```sh
python tools/build_docs.py
```

The [dense linear algebra guide](../linear-algebra.md) describes matrix shapes,
checked operations, and zero-dimensional matrices in more detail.
