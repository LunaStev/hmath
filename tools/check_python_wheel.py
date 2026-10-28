# SPDX-License-Identifier: MPL-2.0
"""Run from a clean installation, without a source checkout or native overrides."""

import ctypes
import importlib.metadata
import os
import runpy
import sys
from pathlib import Path

for variable in ("HMATH_LIBRARY", "LD_LIBRARY_PATH", "PYTHONPATH"):
    if os.environ.get(variable):
        raise SystemExit(f"Wheel validation must not set {variable}")

import hmath
from _hmath_native import library_path

assert "site-packages" in Path(hmath.__file__).parts, hmath.__file__
library = Path(library_path())
assert library.is_file() and "site-packages" in library.parts, library
assert hmath.add(2, 3) == 5.0
with hmath.Tensor.matrix([1, 2, 3, 4], 2, 2) as tensor:
    assert tensor.sum() == 10.0
    with tensor @ tensor as product:
        assert product.values() == [7.0, 10.0, 15.0, 22.0]

if sys.platform == "linux":
    # Every loaded Haskell runtime must come from the installed wheel.
    for line in Path("/proc/self/maps").read_text().splitlines():
        if "libHS" in line or "libhmath" in line:
            assert "site-packages" in line, line
    native = ctypes.CDLL(str(library))
    assert native.hmath_abi_version() == 1
    native.hmath_library_version.restype = ctypes.c_char_p
    assert native.hmath_library_version().decode() == importlib.metadata.version(
        "hmath-python"
    )

if len(sys.argv) > 1:
    runpy.run_path(sys.argv[1], run_name="__main__")
print(f"Installed wheel verified on Python {sys.version.split()[0]}")
