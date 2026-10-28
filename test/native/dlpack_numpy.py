# SPDX-License-Identifier: MPL-2.0
"""Exchange real NumPy DLPack capsules with the C ABI in both directions."""

import ctypes as C
import gc
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "bindings/python"))
import hmath

hmath.initialize()
library = hmath._lib
pointer = C.c_void_p
for name in ("hmath_dlpack_export", "hmath_dlpack_export_versioned"):
    function = getattr(library, name)
    function.argtypes = [pointer, C.POINTER(pointer)]
    function.restype = C.c_int
library.hmath_dlpack_import.argtypes = [pointer, C.c_size_t, C.POINTER(pointer)]
library.hmath_dlpack_import.restype = C.c_int

capsule_pointer = C.pythonapi.PyCapsule_GetPointer
capsule_pointer.argtypes = [C.py_object, C.c_char_p]
capsule_pointer.restype = pointer
capsule_name = C.pythonapi.PyCapsule_SetName
capsule_name.argtypes = [C.py_object, C.c_char_p]
capsule_name.restype = C.c_int
capsule_new = C.pythonapi.PyCapsule_New
capsule_new.argtypes = [pointer, C.c_char_p, pointer]
capsule_new.restype = C.py_object

# Native import retains NumPy's producer owner even after source/capsule GC.
source = np.arange(6, dtype=np.float64).reshape(2, 3)[:, ::2]
capsule = source.__dlpack__()
managed = capsule_pointer(capsule, b"dltensor")
handle = pointer()
hmath._check(library.hmath_dlpack_import(managed, 6, C.byref(handle)))
if capsule_name(capsule, b"used_dltensor"):
    raise AssertionError("capsule rename failed after ownership transfer")
imported = hmath.Tensor._adopt(handle)
del source, capsule
gc.collect()
assert imported.shape == (2, 2)
assert imported.values() == [0, 2, 3, 5]
assert imported.sum() == 10
imported.close()


class Producer:
    def __init__(self, tensor, versioned):
        self.tensor, self.versioned = tensor, versioned

    def __dlpack_device__(self):
        return (1, 0)

    def __dlpack__(self, stream=None, **_kwargs):
        if stream is not None:
            raise BufferError("CPU export has no stream")
        managed = pointer()
        export = (
            library.hmath_dlpack_export_versioned
            if self.versioned
            else library.hmath_dlpack_export
        )
        hmath._check(export(self.tensor._live(), C.byref(managed)))
        name = b"dltensor_versioned" if self.versioned else b"dltensor"
        # This test consumes every capsule immediately with np.from_dlpack.
        # Production capsule wrappers also need an unconsumed-capsule destructor.
        return capsule_new(managed, name, None)


for versioned in (False, True):
    tensor = hmath.Tensor([1, 2, 3, 4], (2, 2))
    array = np.from_dlpack(Producer(tensor, versioned))
    tensor.close()
    del tensor
    gc.collect()
    assert array.shape == (2, 2)
    assert np.array_equal(array, [[1, 2], [3, 4]])
    if versioned:
        assert not array.flags.writeable
    del array
    gc.collect()

print(
    "NumPy DLPack strided import, legacy copy export and readonly versioned export passed"
)
