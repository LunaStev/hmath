# SPDX-License-Identifier: MPL-2.0
"""Optional cffi ABI binding; no compiler needed. Explicit close/with cleanup."""

from itertools import islice

from _hmath_native import library_path
from cffi import FFI

ffi = FFI()
ffi.cdef("""
typedef struct hmath_tensor hmath_tensor;
unsigned int hmath_abi_version(void); int hmath_init(void);
const char *hmath_last_error_message(void);
int hmath_scalar_add(void*,double,double,double*);
int hmath_tensor_copy(const double*,size_t,const size_t*,size_t,hmath_tensor**);
void hmath_tensor_release(hmath_tensor*);
size_t hmath_tensor_count(const hmath_tensor*);
int hmath_tensor_copy_to(const hmath_tensor*,double*,size_t);
int hmath_tensor_sum(void*,const hmath_tensor*,double*);
int hmath_tensor_dot(void*,const hmath_tensor*,const hmath_tensor*,double*);
int hmath_tensor_add(void*,const hmath_tensor*,const hmath_tensor*,hmath_tensor**);
int hmath_tensor_matmul(void*,const hmath_tensor*,const hmath_tensor*,hmath_tensor**);
""")
lib = ffi.dlopen(library_path())
try:
    if lib.hmath_abi_version() != 1:
        raise RuntimeError("HMath binding requires ABI 1")
except AttributeError as error:
    raise RuntimeError(
        "HMath binding requires ABI 1; library has no version query"
    ) from error
if lib.hmath_init():
    raise RuntimeError("HMath runtime was permanently shut down")


class HMathError(RuntimeError):
    def __init__(self, status):
        self.status = status
        super().__init__(ffi.string(lib.hmath_last_error_message()).decode())


def check(status):
    if status:
        raise HMathError(status)


def add(a, b):
    result = ffi.new("double *")
    check(lib.hmath_scalar_add(ffi.NULL, a, b, result))
    return result[0]


class Tensor:
    """Do not close a cffi tensor concurrently with operations on that tensor."""

    def __init__(self, values, shape=None):
        values = list(islice(values, 1048577))
        shape = list(shape if shape is not None else [len(values)])
        if (
            len(shape) > 8
            or len(values) > 1048576
            or any(type(n) is not int or n < 0 or n > 1048576 for n in shape)
        ):
            raise ValueError("invalid bounded shape")
        out = ffi.new("hmath_tensor **")
        check(
            lib.hmath_tensor_copy(
                ffi.new("double[]", values),
                len(values),
                ffi.new("size_t[]", shape),
                len(shape),
                out,
            )
        )
        self.ptr = ffi.gc(out[0], lib.hmath_tensor_release)
        self.shape = tuple(shape)

    def _live(self):
        if self.ptr == ffi.NULL:
            raise RuntimeError("Tensor is closed")
        return self.ptr

    def close(self):
        if self.ptr != ffi.NULL:
            ffi.release(self.ptr)
            self.ptr = ffi.NULL

    def __enter__(self):
        self._live()
        return self

    def __exit__(self, *args):
        self.close()

    def values(self):
        n = lib.hmath_tensor_count(self._live())
        out = ffi.new("double[]", n)
        check(lib.hmath_tensor_copy_to(self.ptr, out, n))
        return list(out)

    def sum(self):
        out = ffi.new("double *")
        check(lib.hmath_tensor_sum(ffi.NULL, self._live(), out))
        return out[0]

    def dot(self, other):
        out = ffi.new("double *")
        check(lib.hmath_tensor_dot(ffi.NULL, self._live(), other._live(), out))
        return out[0]

    def _binary(self, other, operation, shape):
        out = ffi.new("hmath_tensor **")
        check(operation(ffi.NULL, self._live(), other._live(), out))
        result = object.__new__(Tensor)
        result.ptr, result.shape = ffi.gc(out[0], lib.hmath_tensor_release), shape
        return result

    def __add__(self, other):
        return self._binary(other, lib.hmath_tensor_add, self.shape)

    def __matmul__(self, other):
        shape = (
            (self.shape[0], other.shape[1])
            if len(self.shape) == len(other.shape) == 2
            else ()
        )
        return self._binary(other, lib.hmath_tensor_matmul, shape)
