# SPDX-License-Identifier: MPL-2.0
"""Explicit row-major buffer GEMM with optional BLAS and no dtype conversion."""

import ctypes as C
import operator
import os
import threading
from enum import IntEnum


class Provider(IntEnum):
    REFERENCE = 0
    OPENBLAS = 1
    BLIS = 2
    MKL = 3
    ACCELERATE = 4


class _Options(C.Structure):
    _fields_ = [
        ("provider", C.c_int),
        ("integer_bits", C.c_uint),
        ("library_path", C.c_char_p),
        ("max_elements", C.c_size_t),
        ("max_multiply_adds", C.c_size_t),
    ]


class _View(C.Structure):
    _fields_ = [
        ("data", C.c_void_p),
        ("storage_count", C.c_size_t),
        ("rows", C.c_size_t),
        ("columns", C.c_size_t),
        ("leading_dimension", C.c_size_t),
    ]


def _api(name, result, *types):
    import hmath

    return C.CFUNCTYPE(result, *types)((name, hmath._lib))


def _size(value):
    value = operator.index(value)
    if value < 0 or value > C.c_size_t(-1).value:
        raise ValueError("resource limit must be a nonnegative size_t")
    return value


def _view(array, writable=False):
    import numpy as np

    if not isinstance(array, np.ndarray) or array.ndim != 2:
        raise TypeError("execution requires two-dimensional NumPy arrays")
    if (
        array.dtype not in (np.dtype("float32"), np.dtype("float64"))
        or not array.dtype.isnative
    ):
        raise TypeError("execution requires native-endian float32 or float64 arrays")
    if not array.flags.aligned or (writable and not array.flags.writeable):
        raise ValueError(
            "execution storage must be aligned and output must be writable"
        )
    rows, columns = array.shape
    item = array.dtype.itemsize
    if any(stride < 0 or stride % item for stride in array.strides):
        raise ValueError("execution requires nonnegative element-aligned strides")
    if columns > 1 and rows and array.strides[1] != item:
        raise ValueError("execution requires consecutive columns")
    leading = array.strides[0] // item
    if rows > 1 and columns and leading < columns:
        raise ValueError("execution rows must not overlap")
    # Row stride is irrelevant for a single row or an empty view. Canonicalize
    # it to the required leading dimension without changing any data address.
    if rows <= 1 or not columns:
        leading = max(columns, leading)
    span = (rows - 1) * leading + columns if rows and columns else 0
    return _View(array.ctypes.data, span, rows, columns, leading)


class Execution:
    """Immutable provider/resource selection; buffers are borrowed per call.

    Provider selection never silently falls back. Limits of zero mean no
    artificial cap; overflow, allocation, shape and alias checks remain active.
    A live Execution owns its provider library but does not pin the GHC runtime.
    """

    def __init__(
        self,
        provider=Provider.REFERENCE,
        *,
        integer_bits=32,
        library_path=None,
        max_elements=0,
        max_multiply_adds=0,
    ):
        import hmath

        self._lock, self._ptr = threading.RLock(), C.c_void_p()
        if isinstance(provider, str):
            provider = Provider[provider.upper()]
        provider = Provider(provider)
        integer_bits = operator.index(integer_bits)
        if integer_bits not in (0, 32, 64):
            raise ValueError("integer_bits must be 32 (LP64) or 64 (ILP64)")
        path = None if library_path is None else os.fsencode(library_path)
        options = _Options(
            provider, integer_bits, path, _size(max_elements), _size(max_multiply_adds)
        )
        hmath._check(
            _api(
                "hmath_execution_create",
                C.c_int,
                C.POINTER(_Options),
                C.POINTER(C.c_void_p),
            )(C.byref(options), C.byref(self._ptr))
        )

    def close(self):
        with self._lock:
            if self._ptr:
                _api("hmath_execution_release", None, C.c_void_p)(self._ptr)
                self._ptr = C.c_void_p()

    def __enter__(self):
        with self._lock:
            if not self._ptr:
                raise ValueError("execution is closed")
        return self

    def __exit__(self, *_):
        self.close()

    def __del__(self):
        if getattr(self, "_ptr", None):
            self.close()

    def gemm(self, a, b, out, *, alpha=1, beta=0):
        """Write alpha*A*B + beta*out into the supplied NumPy output.

        Arrays retain their original float32/float64 storage; padded rows are
        accepted, strided columns/negative strides and overlapping outputs are
        rejected. A/B may share storage. All logical elements (including initial
        output when beta=0) must be finite. Padding is untouched. Validation
        errors leave output unchanged. Once execution starts, cancellation or
        numeric failure may leave output modified. Inputs and their aliases must
        not be mutated concurrently; concurrent calls need separate outputs.
        """
        import hmath

        av, bv, cv = _view(a), _view(b), _view(out, writable=True)
        if a.dtype != b.dtype or a.dtype != out.dtype:
            raise TypeError("GEMM arrays must have exactly the same dtype")
        real = C.c_float if a.dtype.itemsize == 4 else C.c_double
        call = _api(
            "hmath_execution_gemm_f32"
            if real is C.c_float
            else "hmath_execution_gemm_f64",
            C.c_int,
            C.c_void_p,
            C.c_void_p,
            real,
            C.POINTER(_View),
            C.POINTER(_View),
            real,
            C.POINTER(_View),
        )
        retain = _api("hmath_execution_retain", None, C.c_void_p)
        release = _api("hmath_execution_release", None, C.c_void_p)
        hmath.initialize()
        with self._lock:
            if not self._ptr:
                raise ValueError("execution is closed")
            pointer = C.c_void_p(self._ptr.value)
            retain(pointer)
        try:
            hmath._check(
                call(pointer, None, alpha, C.byref(av), C.byref(bv), beta, C.byref(cv))
            )
        finally:
            release(pointer)
        return out

    def matmul(self, a, b):
        """Allocate a zeroed output of the same dtype, then execute GEMM."""
        import numpy as np

        _view(a)
        _view(b)
        if a.dtype != b.dtype:
            raise TypeError("GEMM arrays must have exactly the same dtype")
        out = np.zeros((a.shape[0], b.shape[1]), dtype=a.dtype)
        return self.gemm(a, b, out)
