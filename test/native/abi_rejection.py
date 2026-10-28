# SPDX-License-Identifier: MPL-2.0
"""Verify both Python loaders reject ABI mismatch before resolving new symbols."""

import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--cc", default="cc")
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix="hmath-abi-mismatch-") as temporary:
    library = Path(temporary) / "wrong_abi.so"
    subprocess.run(
        [
            args.cc,
            "-shared",
            "-fPIC",
            str(root / "test/native/wrong_abi.c"),
            "-o",
            str(library),
        ],
        check=True,
    )
    environment = os.environ | {
        "HMATH_LIBRARY": str(library),
        "PYTHONPATH": str(root / "bindings/python"),
    }
    for module in ("hmath", "hmath_cffi"):
        result = subprocess.run(
            [sys.executable, "-c", f"import {module}"],
            env=environment,
            capture_output=True,
            check=False,
            text=True,
            timeout=10,
        )
        if result.returncode == 0 or "requires ABI 1" not in result.stderr:
            raise AssertionError(
                f"{module} did not reject incompatible ABI: {result.stderr}"
            )
print("Python ctypes and cffi reject incompatible ABI before symbol loading")
