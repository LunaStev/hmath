# HMath

HMath is a mathematics and numerical computing library written in Haskell. It provides a native Haskell API and a shared library with a C-compatible interface for use from other languages.

The project is in early development. The native build currently targets Linux, and the public API and ABI are still evolving.

## Features

- **Core math:** factorials, Fibonacci numbers, primality testing, clamping, and linear interpolation.
- **Linear algebra:** list-based vectors and dense matrices, with dimension-checked operations, matrix multiplication, transpose, indexing, slicing, and reshape.
- **Statistics:** mean, variance, standard deviation, and median.
- **Native interface:** C exports for addition, factorial, mean, and dot product, with C and Python examples.

## Build and test

Requires GHC, Cabal, a C11 compiler, Meson >= 0.63, Ninja, Python 3, and the LAPACKE development library.

```sh
git clone https://github.com/wavefnd/hmath.git
cd hmath
meson setup builddir
meson compile -C builddir
meson test -C builddir --print-errorlogs
```

This builds `builddir/libhmath.so` and runs the Haskell, C, and Python tests. For a Haskell-only build, use `cabal build lib:hmath` and `cabal test hmath-tests`.

## Quick start

Save the following as `Main.hs` in the checkout and run `runghc -isrc Main.hs`:

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

## C and Python

The C API is declared in [include/hmath.h](include/hmath.h). C clients initialize with `hmath_init()` before numerical calls and shut down with `hmath_shutdown()` after all calls have finished. See the [C example](examples/c/main.c) and [Python ctypes example](examples/python/main.py).

Run the Python example against the built library:

```sh
HMATH_LIBRARY="$PWD/builddir/libhmath.so" python3 examples/python/main.py
```

## Contributing

Report bugs or discuss changes through [GitHub issues](https://github.com/wavefnd/hmath/issues). Submit pull requests from a fork against `master`; see [ROADMAP.md](ROADMAP.md) for planned work.

## License

[Mozilla Public License 2.0](LICENSE).
