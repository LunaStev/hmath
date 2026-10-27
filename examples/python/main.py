# SPDX-License-Identifier: MPL-2.0

import ctypes
from pathlib import Path

import os

root = Path(__file__).resolve().parents[2]

library_path = Path(
    os.environ.get(
        "HMATH_LIBRARY",
        str(root / "build" / "libhmath.so")
    )
)

hmath = ctypes.CDLL(str(library_path))

hmath.hmath_init.argtypes = []
hmath.hmath_init.restype = ctypes.c_int

hmath.hmath_shutdown.argtypes = []
hmath.hmath_shutdown.restype = None

hmath.hmath_add_f64.argtypes = [
    ctypes.c_double,
    ctypes.c_double,
]
hmath.hmath_add_f64.restype = ctypes.c_double

hmath.hmath_factorial.argtypes = [ctypes.c_int]
hmath.hmath_factorial.restype = ctypes.c_longlong

hmath.hmath_mean_f64.argtypes = [
    ctypes.POINTER(ctypes.c_double),
    ctypes.c_size_t,
]
hmath.hmath_mean_f64.restype = ctypes.c_double


def main():
    if hmath.hmath_init() != 0:
        raise RuntimeError("Failed to initialize HMath")

    try:
        values = (ctypes.c_double * 4)(
            10.0, 20.0, 30.0, 40.0
        )

        print("HMath Python FFI Test")
        print("Add:", hmath.hmath_add_f64(10.0, 20.0))
        print("Mean:", hmath.hmath_mean_f64(values, 4))
        print("Factorial:", hmath.hmath_factorial(10))
    finally:
        hmath.hmath_shutdown()


if __name__ == "__main__":
    main()
