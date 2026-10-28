# Build from source

## Native development

The supported native target is Linux x86-64. Install GHC 9.6.7 or 9.10.3,
Cabal, a C11 compiler, Meson 1.3 or newer, Ninja, and Python 3.
Zlib enables compressed interchange; LAPACKE and BLAS providers are optional
for the corresponding Haskell backends.

```sh
git clone https://github.com/wavefnd/hmath.git
cd hmath
meson setup builddir --buildtype=release
meson compile -C builddir
meson test -C builddir --print-errorlogs
```

The build creates `builddir/libhmath.so` and its ABI-versioned copy. It runs
Haskell and C tests, plus optional Python and Wave tests when their
dependencies are installed. Install NumPy and cffi to run the Python binding
suite; install `wavec` to run Wave integration.

## Haskell only

```sh
cabal build lib:hmath
cabal test hmath-tests --test-show-details=direct
```

The [Haskell reference](../reference/haskell.md) links all public modules.

## Reproduce a Python release wheel

Docker is sufficient; the build installs its pinned toolchain inside the
container and checks the GHC and Cabal download checksums.

```sh
docker run --rm -v "$PWD:/io" \
  quay.io/pypa/manylinux_2_28_x86_64@sha256:e0adf18521ad35192df733a6c62d35df7801957d24e0470238aacecfab2188a3 \
  bash /io/tools/build_python_wheel.sh
```

The wheel and source distribution are written to `dist/`. Auditwheel bundles
required non-system shared libraries and replaces build-machine runtime
paths with paths relative to the installed wheel.

An sdist build requires GHC, Cabal, and the system toolchain. Unsupported
platforms are not automatically covered by successful source compilation.
