# Installation

## Requirements

- Linux on an x86-64 CPU, with glibc 2.28 or newer.
- Python 3.9 or newer; standard CPython 3.9–3.14 is tested in CI.
- A recent pip capable of selecting manylinux wheels.

The binary wheel includes HMath and the required Haskell runtime libraries.
GHC, Cabal, a C compiler, and an environment variable pointing to a shared
library are not needed for normal Python use.

## Install into your project

Use the interpreter belonging to your project or IDE environment:

```sh
python -m pip install --upgrade pip
python -m pip install --upgrade --only-binary=:all: "hmath-python>=1.0.1"
python -c "from hmath import add; print(add(2, 3))"
```

The expected result is `5.0`. The distribution name is `hmath-python`;
the import name is `hmath`.

`--only-binary=:all:` makes unsupported platforms fail with a package-selection
error instead of unexpectedly attempting a source build.

For a new environment:

```sh
python -m venv .venv
. .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install --only-binary=:all: "hmath-python>=1.0.1"
```

## Optional integrations

```sh
python -m pip install --upgrade --only-binary=:all: "hmath-python[numpy,cffi]>=1.0.1"
```

NumPy enables array conversion and zero-copy views. The `hmath_cffi` module
provides an alternative cffi wrapper; the default `hmath` module uses ctypes.

## Upgrade from 1.0.0

Version 1.0.0 shipped Python wrappers without the native library. Upgrade using
the command above. Do not copy a random `libhmath.so` into your system library
directory. If `HMATH_LIBRARY` was set as an earlier workaround, remove that
override to let the fixed wheel load its own library.

For macOS, Windows, musl-based Linux, or another CPU architecture, prebuilt
wheels are not currently supplied. See [building from source](../guides/build.md)
and the [support policy](../explanation/releases.md).
