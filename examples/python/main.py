# SPDX-License-Identifier: MPL-2.0

import ctypes
import math
import os
from pathlib import Path
import sys

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

hmath.hmath_dot_f64.argtypes = [
    ctypes.POINTER(ctypes.c_double),
    ctypes.POINTER(ctypes.c_double),
    ctypes.c_size_t,
]
hmath.hmath_dot_f64.restype = ctypes.c_double


def check_finite(name, actual, expected):
    if not math.isfinite(actual) or not math.isclose(
        actual, expected, rel_tol=1e-12, abs_tol=1e-12
    ):
        print(f"{name}: expected {expected!r}, got {actual!r}", file=sys.stderr)
        return 1
    return 0


def check_integer(name, actual, expected):
    if actual != expected:
        print(f"{name}: expected {expected}, got {actual}", file=sys.stderr)
        return 1
    return 0


def check_nan(name, actual):
    if not math.isnan(actual):
        print(f"{name}: expected NaN, got {actual!r}", file=sys.stderr)
        return 1
    return 0


def main():
    if hmath.hmath_init() != 0:
        print("Failed to initialize HMath", file=sys.stderr)
        return 1

    try:
        values = (ctypes.c_double * 4)(
            10.25, 20.5, 30.75, 40.0
        )
        a = (ctypes.c_double * 3)(1.5, -2.25, 3.75)
        b = (ctypes.c_double * 3)(2.0, 0.5, -4.0)
        sum_value = hmath.hmath_add_f64(10.25, 20.5)
        average = hmath.hmath_mean_f64(values, 4)
        factorial = hmath.hmath_factorial(10)
        dot = hmath.hmath_dot_f64(a, b, 3)

        print("HMath Python FFI Test")
        print("Add:", sum_value)
        print("Mean:", average)
        print("Factorial:", factorial)
        print("Dot:", dot)

        failures = check_finite("addition", sum_value, 30.75)
        for n, expected in (
            (0, 1),
            (10, 3628800),
            (20, 2432902008176640000),
            (-1, -1),
            (21, -1),
        ):
            actual = factorial if n == 10 else hmath.hmath_factorial(n)
            failures += check_integer(f"factorial({n})", actual, expected)

        failures += check_finite("mean", average, 25.375)
        for name, pointer, count in (
            ("mean(NULL, 4)", None, 4),
            ("mean(values, 0)", values, 0),
            ("mean(NULL, 0)", None, 0),
        ):
            failures += check_nan(name, hmath.hmath_mean_f64(pointer, count))

        failures += check_finite("dot", dot, -13.125)
        for name, left, right in (
            ("dot(a, b, 0)", a, b),
            ("dot(NULL, b, 0)", None, b),
            ("dot(a, NULL, 0)", a, None),
            ("dot(NULL, NULL, 0)", None, None),
        ):
            failures += check_finite(name, hmath.hmath_dot_f64(left, right, 0), 0.0)
        for name, left, right in (
            ("dot(NULL, b, 3)", None, b),
            ("dot(a, NULL, 3)", a, None),
            ("dot(NULL, NULL, 3)", None, None),
        ):
            failures += check_nan(name, hmath.hmath_dot_f64(left, right, 3))

        if failures:
            print(f"{failures} HMath Python FFI check(s) failed", file=sys.stderr)
            return 1
        print("All HMath Python FFI checks passed")
        return 0
    finally:
        hmath.hmath_shutdown()


if __name__ == "__main__":
    sys.exit(main())
