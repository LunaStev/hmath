# SPDX-License-Identifier: MPL-2.0
"""Borrowed-array interface to the original Fourier.fftInPlace."""

import ctypes as C

from . import _value as value


def fft_in_place(plan, buffer):
    """Transform one writable contiguous native complex128 NumPy array in place."""
    import hmath
    import numpy as np

    if (
        not isinstance(buffer, np.ndarray)
        or buffer.ndim != 1
        or buffer.dtype != np.dtype("complex128")
        or not buffer.dtype.isnative
        or not buffer.flags.c_contiguous
        or not buffer.flags.aligned
        or not buffer.flags.writeable
    ):
        raise TypeError(
            "expected a writable aligned contiguous native complex128 vector"
        )
    owned = value.encode(plan)
    try:
        hmath._check(
            value.api(
                "hmath_fourier_value_fft_in_place",
                C.c_int,
                C.c_void_p,
                C.c_void_p,
                C.POINTER(C.c_double),
                C.c_ssize_t,
            )(
                None,
                owned._ptr,
                buffer.ctypes.data_as(C.POINTER(C.c_double)),
                buffer.size,
            )
        )
    finally:
        owned.close()
