# HMath

A general-purpose mathematics and numerical computing library written in Haskell, with a native C ABI.

HMath is in early development. The current prototype provides basic arithmetic helpers, list-based vectors and matrices, descriptive statistics, and a small C interface usable from Python. The public API and ABI are not yet stable.

## Build and test

Requirements: GHC with `base >= 4.16`, Cabal, a C11 compiler, Meson >= 0.63, Ninja, and Python 3. The current native build targets Linux.

```sh
cabal build all
cabal test all

meson setup builddir
meson compile -C builddir
meson test -C builddir --print-errorlogs
```

Meson checks numerical results in C and Python (including Python `-O`), exercises runtime lifecycle sequences in isolated processes, and verifies that the examples reject deliberately incorrect results. Test-only replacement libraries are not installed.

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

## Use from C and Python

For C, include `hmath.h` and check that `hmath_init()` returns `HMATH_INIT_OK` before calling numerical functions. Python callers can load the shared library with `ctypes`; see [the Python example](examples/python/main.py). The shared library requires the matching GHC runtime libraries.

The runtime has one lifetime per process:

- Repeated initialization while running returns `HMATH_INIT_OK` (`0`). It is idempotent and does not count references; one shutdown ends the lifetime.
- Shutdown before the first initialization or after shutdown has no effect.
- After final shutdown, initialization returns `HMATH_INIT_ALREADY_SHUT_DOWN` (`1`) without entering the GHC runtime. [GHC does not support restarting the runtime after shutdown](https://downloads.haskell.org/ghc/9.10.3/docs/users_guide/exts/ffi.html#using-your-own-main).
- Initialization and shutdown calls from different threads are serialized. An initialization racing with final shutdown can succeed before shutdown or be rejected afterward; success does not keep the runtime alive for later numerical calls.
- Before shutdown, the caller must wait for all numerical calls to finish and prevent new calls. Lifecycle serialization does not track or protect active numerical calls. Numerical functions must only be called after successful initialization and before shutdown begins.

HMath must own the process's GHC runtime lifecycle. Calling GHC initialization or shutdown directly, or sharing runtime lifecycle ownership with another Haskell library, is unsupported.

## Roadmap

See [ROADMAP.md](ROADMAP.md) and the [issue tracker](https://github.com/wavefnd/hmath/issues) for the complete development backlog and 1.0.0 planning. The 47 feature areas are development goals; the mandatory 1.0.0 release scope remains to be agreed. Known prototype correctness issues are tracked separately.

## License

HMath is licensed under the [Mozilla Public License 2.0](LICENSE) (`MPL-2.0`).
