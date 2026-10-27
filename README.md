# HMath

A general-purpose mathematics and numerical computing library written in Haskell, with a native C ABI.

HMath is in early development. The current prototype provides basic arithmetic helpers, list-based vectors and matrices, descriptive statistics, and a small C interface usable from Python. The public API and ABI are not yet stable.

## Build and test

Requirements: GHC with `base >= 4.16`, Cabal, a C compiler, Meson >= 0.63, Ninja, and Python 3. The current native build targets Linux.

```sh
cabal build all
cabal test all

meson setup builddir
meson compile -C builddir
meson test -C builddir --print-errorlogs
```

Run the Python example against the Meson output:

```sh
HMATH_LIBRARY="$PWD/builddir/libhmath.so" python3 examples/python/main.py
```

## Use from Haskell

```haskell
import HMath

factorial 5                         -- 120
dot [1, 2, 3] [4, 5, 6]            -- 32
mean [10, 20, 30 :: Double]         -- 20.0
fromList 2 2 [1, 2, 3, 4 :: Double]
```

For C, include `hmath.h`, call `hmath_init()` before numerical functions, and call `hmath_shutdown()` once after all calls have finished. The prototype does not support reinitialization after shutdown or guarantee concurrent runtime lifecycle calls. The shared library currently requires the matching GHC runtime libraries.

## Roadmap

See [ROADMAP.md](ROADMAP.md) and the [issue tracker](https://github.com/wavefnd/hmath/issues) for the complete development backlog and 1.0.0 planning. The 47 feature areas are development goals; the mandatory 1.0.0 release scope remains to be agreed. Known prototype correctness issues are tracked separately.

## License

HMath is licensed under the [Mozilla Public License 2.0](LICENSE) (`MPL-2.0`).
