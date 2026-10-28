# Haskell modules

Haskell exposes the full HMath numerical API. The
[generated Haddock reference](https://wavefnd.github.io/hmath/haskell/index.html)
contains public signatures, types, and module documentation, generated from
the same source revision as this site.

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

Build the local API documentation with:

```sh
cabal haddock lib:hmath --haddock-html --haddock-hyperlink-source
```

The [dense linear algebra guide](../linear-algebra.md) describes matrix shapes,
checked operations, and zero-dimensional matrices in more detail.
