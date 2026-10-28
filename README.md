# HMath

HMath is a mathematics and numerical computing library with Python bindings, written in Haskell. It also provides native Haskell, C, and Wave interfaces.

The 1.0.0 release targets Linux x86-64. The Python distribution is named **hmath-python** and is imported as `hmath`.

## Python quick start

Install the Python package on Linux x86-64:

```sh
pip install hmath-python
```

```python
from hmath import Tensor, add

print(add(2, 3))  # 5.0

with Tensor.matrix([1, 2, 3, 4], 2, 2) as matrix:
    with matrix @ matrix as product:
        print(product.values())  # [7.0, 10.0, 15.0, 22.0]
```

Use `with` to release native resources automatically. Invalid operations raise `HMathError`. Optional NumPy and cffi support is described in the [Python binding guide](bindings/python).

## Features

- **Core math:** checked scalar operations, numeric types, constants, units, number theory, and polynomials.
- **Linear algebra:** dense and sparse matrices, decompositions, iterative solvers, and CPU tensors.
- **Scientific computing:** differentiation, integration, ODE/PDE solvers, optimization, interpolation, FFTs, and signal processing.
- **Statistics and learning:** reproducible sampling, probability distributions, inference, automatic differentiation, and machine learning primitives.
- **Discrete and symbolic math:** combinatorics, graphs, numerical data structures, symbolic calculus, and a bounded expression evaluator.
- **Applied math:** complex numbers, rotations, computational geometry, time series, and numerical image processing.
- **Native interface:** checked scalar, vector, matrix, and tensor operations; explicit ownership and errors; Python/NumPy and Wave bindings.
- **Interchange:** typed binary and text arrays, CSV/TSV, Matrix Market, NPY/NPZ, and CPU DLPack.

The Haskell library contains the full numerical API; Python currently exposes scalar addition and binary64 vector, matrix, and tensor construction, arithmetic, and reductions.

## Build from source

Requires GHC, Cabal, a C11 compiler, Meson >= 1.3, Ninja, and Python 3. Zlib enables compressed interchange. BLAS/LAPACKE are optional runtime backends; the full spectral test suite needs LAPACKE.

```sh
git clone https://github.com/wavefnd/hmath.git
cd hmath
meson setup builddir
meson compile -C builddir
meson test -C builddir --print-errorlogs
```

This builds `builddir/libhmath.so` and runs the Haskell, C, and Python tests. Wave tests also run when `wavec` is available.

## Haskell

Save the following as `Main.hs` in the checkout. Run `cabal build lib:hmath`, then `cabal exec -- runghc -package=hmath Main.hs`:

```haskell
import HMath

main :: IO ()
main = do
    print (dotChecked [1, 2, 3 :: Int] [4, 5, 6]) -- Right 32
    print $ do
        matrix <- fromListChecked 2 2 [1, 2, 3, 4 :: Int]
        pure (toList (transposeMatrix matrix))   -- Right [1,3,2,4]
```

Checked operations return `Either MathError` for invalid shapes or lengths. More examples are available in [examples/haskell](examples/haskell).

## C and Wave

The [C header](include/hmath.h) defines errors, ownership, and runtime lifetime. See the [C example](examples/c/main.c) and [Wave bindings](bindings/wave) for usage.

## Contributing

Report bugs or discuss changes through [GitHub issues](https://github.com/wavefnd/hmath/issues). Submit pull requests from a fork against `master`; see [ROADMAP.md](ROADMAP.md) for planned work.

## License

[Mozilla Public License 2.0](LICENSE).
