# SPDX-License-Identifier: MPL-2.0
"""Binary64 HMath ABI 1, with its native library included in binary wheels.

Tensor owns one native reference. close()/with provide deterministic cleanup;
__del__ is a fallback. Arrays are copied by default. from_numpy(copy=False)
requires readonly, native-endian, aligned float64 storage and nonnegative
strides; the caller must not mutate aliases until all derived views die.
Native storage views retain independent references, so closing a Tensor does
not invalidate an existing NumPy view. The process owner shuts down explicitly.
"""

import ctypes as C
import threading
import weakref
from itertools import islice

from _hmath_native import library_path

_lib = C.CDLL(library_path())
P, Z, D = C.c_void_p, C.c_size_t, C.c_double


def _sig(name, result, *args):
    fn = getattr(_lib, name)
    fn.restype, fn.argtypes = result, list(args)
    return fn


try:
    _sig("hmath_abi_version", C.c_uint32)
    if _lib.hmath_abi_version() != 1:
        raise RuntimeError("HMath binding requires ABI 1")
except AttributeError as error:
    raise RuntimeError(
        "HMath binding requires ABI 1; library has no version query"
    ) from error
_sig("hmath_init", C.c_int)
_sig("hmath_last_error_message", C.c_char_p)
_sig("hmath_runtime_shutdown", C.c_int)
_sig("hmath_tensor_copy", C.c_int, C.POINTER(D), Z, C.POINTER(Z), Z, C.POINTER(P))
_sig(
    "hmath_tensor_borrow",
    C.c_int,
    C.POINTER(D),
    Z,
    C.POINTER(Z),
    C.POINTER(Z),
    Z,
    P,
    P,
    C.POINTER(P),
)
_sig("hmath_tensor_retain", None, P)
_sig("hmath_tensor_release", None, P)
_sig("hmath_tensor_count", Z, P)
_sig("hmath_tensor_rank", Z, P)
_sig("hmath_tensor_metadata", C.c_int, P, C.POINTER(Z), C.POINTER(Z), Z)
_sig("hmath_tensor_copy_to", C.c_int, P, C.POINTER(D), Z)
_sig("hmath_tensor_data", C.c_int, P, C.POINTER(C.POINTER(D)), C.POINTER(Z))
_sig("hmath_scalar_add", C.c_int, P, D, D, C.POINTER(D))
_sig("hmath_tensor_sum", C.c_int, P, P, C.POINTER(D))
_sig("hmath_tensor_dot", C.c_int, P, P, P, C.POINTER(D))
for _name in ("hmath_tensor_add", "hmath_tensor_matmul"):
    _sig(_name, C.c_int, P, P, P, C.POINTER(P))
_sig("hmath_tensor_reshape", C.c_int, P, C.POINTER(Z), Z, C.POINTER(P))


class HMathError(RuntimeError):
    def __init__(self, status):
        self.status = status
        super().__init__(_lib.hmath_last_error_message().decode("utf-8", "replace"))


def _check(status):
    if status:
        raise HMathError(status)


def initialize():
    if _lib.hmath_abi_version() != 1:
        raise RuntimeError("HMath binding requires ABI 1")
    if _lib.hmath_init():
        raise RuntimeError("HMath runtime was permanently shut down")


def shutdown():
    """Process-owner operation; join all numerical users before calling."""
    _check(_lib.hmath_runtime_shutdown())


def add(a, b):
    initialize()
    result = D()
    _check(_lib.hmath_scalar_add(None, a, b, C.byref(result)))
    return result.value


def _shape(shape):
    shape = tuple(shape)
    if len(shape) > 8 or any(type(n) is not int or n < 0 or n > 1048576 for n in shape):
        raise ValueError("shape requires at most eight nonnegative bounded integers")
    return shape, (Z * len(shape))(*shape)


class Tensor:
    def __init__(self, values, shape=None):
        initialize()
        values = list(islice(values, 1048577))
        self._lock, self._ptr, self._owner = threading.RLock(), P(), None
        shape, dims = _shape((len(values),) if shape is None else shape)
        if len(values) > 1048576:
            raise ValueError("tensor exceeds element budget")
        data = (D * len(values))(*values)
        _check(
            _lib.hmath_tensor_copy(
                data, len(values), dims, len(shape), C.byref(self._ptr)
            )
        )

    @classmethod
    def _adopt(cls, ptr, owner=None):
        result = object.__new__(cls)
        result._lock, result._ptr, result._owner = threading.RLock(), ptr, owner
        return result

    @classmethod
    def scalar(cls, value):
        return cls([value], ())

    @classmethod
    def matrix(cls, values, rows, columns):
        return cls(values, (rows, columns))

    @classmethod
    def from_numpy(cls, array, copy=True):
        import numpy as np

        array = np.asarray(array)
        if array.size > 1048576 or array.ndim > 8:
            raise ValueError("tensor exceeds element or rank budget")
        if copy:
            array = np.asarray(array, dtype=np.float64)
            return cls(array.ravel(order="C"), array.shape)
        initialize()
        if (
            array.dtype != np.dtype("float64")
            or not array.dtype.isnative
            or not array.flags.aligned
            or array.flags.writeable
        ):
            raise ValueError("zero-copy requires readonly aligned native float64")
        shape, dims = _shape(array.shape)
        if any(s < 0 or s % 8 for s in array.strides):
            raise ValueError("zero-copy requires nonnegative whole-element strides")
        strides = (Z * array.ndim)(*(s // 8 for s in array.strides))
        span = (
            0
            if array.size == 0
            else 1 + sum((n - 1) * (s // 8) for n, s in zip(shape, array.strides))
        )
        ptr = P()
        _check(
            _lib.hmath_tensor_borrow(
                array.ctypes.data_as(C.POINTER(D)),
                span,
                dims,
                strides,
                array.ndim,
                None,
                None,
                C.byref(ptr),
            )
        )
        return cls._adopt(ptr, array)

    def _live(self):
        if not self._ptr:
            raise RuntimeError("Tensor is closed")
        return self._ptr

    def close(self):
        lock = getattr(self, "_lock", None)
        if lock is not None:
            with lock:
                if self._ptr:
                    _lib.hmath_tensor_release(self._ptr)
                    self._ptr = P()
                    self._owner = None

    def __del__(self):
        self.close()

    def __enter__(self):
        self._live()
        return self

    def __exit__(self, *args):
        self.close()

    @property
    def shape(self):
        with self._lock:
            rank = _lib.hmath_tensor_rank(self._live())
            dims, steps = (Z * rank)(), (Z * rank)()
            _check(_lib.hmath_tensor_metadata(self._ptr, dims, steps, rank))
            return tuple(dims)

    def values(self):
        with self._lock:
            count = _lib.hmath_tensor_count(self._live())
            result = (D * count)()
            _check(_lib.hmath_tensor_copy_to(self._ptr, result, count))
            return list(result)

    def numpy(self, copy=True):
        import numpy as np

        with self._lock:
            if copy:
                return np.array(self.values()).reshape(self.shape)
            rank = _lib.hmath_tensor_rank(self._live())
            dims, steps = (Z * rank)(), (Z * rank)()
            _check(_lib.hmath_tensor_metadata(self._ptr, dims, steps, rank))
            data, count = C.POINTER(D)(), Z()
            _check(_lib.hmath_tensor_data(self._ptr, C.byref(data), C.byref(count)))
            if count.value == 0:
                result = np.empty(tuple(dims))
                result.setflags(write=False)
                return result
            buffer = (D * count.value).from_address(C.addressof(data.contents))
            result = np.ndarray(
                tuple(dims),
                dtype=np.float64,
                buffer=memoryview(buffer).toreadonly(),
                strides=tuple(s * 8 for s in steps),
            )
            # Keep ownership on the actual buffer shared by every NumPy base
            # chain. A finalizer on only the first ndarray would release too
            # early when another array is created from view.base.
            retained, owner = P(self._ptr.value), self._owner
            _lib.hmath_tensor_retain(retained)
            weakref.finalize(
                buffer, lambda p, keep: _lib.hmath_tensor_release(p), retained, owner
            )
            return result

    def sum(self):
        with self._lock:
            result = D()
            _check(_lib.hmath_tensor_sum(None, self._live(), C.byref(result)))
            return result.value

    def _binary(self, other, operation, scalar=False):
        # Stable lock ordering prevents opposite-operand deadlocks.
        first, second = sorted((self, other), key=id)
        with first._lock, second._lock:
            result = D() if scalar else P()
            _check(operation(None, self._live(), other._live(), C.byref(result)))
            return result.value if scalar else self._adopt(result)

    def dot(self, other):
        return self._binary(other, _lib.hmath_tensor_dot, True)

    def __add__(self, other):
        return self._binary(other, _lib.hmath_tensor_add)

    def __matmul__(self, other):
        return self._binary(other, _lib.hmath_tensor_matmul)

    def reshape(self, shape):
        shape, dims = _shape(shape)
        with self._lock:
            result = P()
            _check(
                _lib.hmath_tensor_reshape(
                    self._live(), dims, len(shape), C.byref(result)
                )
            )
            return self._adopt(result, self._owner)
