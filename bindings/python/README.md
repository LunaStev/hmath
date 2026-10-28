# HMath for Python

Python bindings for [HMath](https://github.com/wavefnd/hmath), a mathematics library written in Haskell. Provides checked binary64 scalar, vector, matrix and tensor operations through C ABI 1.

Install the HMath shared library separately and set `HMATH_LIBRARY` to its absolute path. This package contains Python bindings; the native library and GHC runtime dependencies are separate installations.

```sh
python -m pip install 'hmath-python[numpy,cffi]'
export HMATH_LIBRARY=/absolute/path/to/libhmath.so
```

The standard interface uses `ctypes`. The optional `cffi` interface is available as `hmath_cffi`; NumPy integration is available through `Tensor.from_numpy()` and `Tensor.numpy()`.

```python
from hmath import Tensor, add

print(add(2, 3))
with Tensor.matrix([1, 2, 3, 4], 2, 2) as matrix:
    with matrix @ matrix as product:
        print(product.values())  # [7, 10, 15, 22]
```

Use `with` or `close()` for deterministic cleanup. Shapes are row-major, with at most eight dimensions and 1,048,576 finite elements. Invalid operations raise `HMathError`. NumPy conversions copy by default; explicit zero-copy views retain their storage owner. The process owner may call `hmath.shutdown()` after all workers finish; runtime shutdown is permanent.

Licensed under MPL-2.0. See [LICENSE](LICENSE).
