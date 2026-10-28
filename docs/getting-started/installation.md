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
pip install hmath-python
python -c "from hmath import add; print(add(2, 3))"
```

The expected result is `5.0`. The distribution name is `hmath-python`;
the import name is `hmath`.

For a new environment:

```sh
python -m venv .venv
. .venv/bin/activate
pip install hmath-python
```

## Optional integrations

```sh
pip install "hmath-python[numpy,cffi]"
```

NumPy enables array conversion and zero-copy views. The `hmath_cffi` module
provides an alternative cffi wrapper; the default `hmath` module uses ctypes.

## Upgrade from 1.0.0

Version 1.0.0 shipped Python wrappers without the native library. For an existing
installation, run `pip install --upgrade hmath-python` in that environment. Do not copy a random `libhmath.so` into your system library
directory. If `HMATH_LIBRARY` was set as an earlier workaround, remove that
override to let the fixed wheel load its own library.

For macOS, Windows, musl-based Linux, or another CPU architecture, prebuilt
wheels are not currently supplied. See [building from source](../guides/build.md)
and the [support policy](../explanation/releases.md).
