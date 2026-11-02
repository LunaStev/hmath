# SPDX-License-Identifier: MPL-2.0
"""Shared owners for the original boxed Tensor, its graphs and pinned views."""

import ctypes as C

from ._value import Value, register


def _call(name, *arguments, **keywords):
    from . import _tensor_core

    return getattr(_tensor_core, name)(*arguments, **keywords)


class Tensor(Value):
    """Original immutable Haskell tensor, preserving dtype and strided views."""

    def __init__(self, shape, values, dtype="float64", *, column_major=False):
        result = _call(
            "tensor_column_major" if column_major else "tensor",
            shape,
            values,
            dtype=dtype,
        )
        self._ptr, self._lock, self._owners = result._ptr, result._lock, result._owners
        result._ptr, result._owners = C.c_void_p(), ()

    @property
    def shape(self):
        return _call("tensor_shape", self)

    @property
    def strides(self):
        return _call("tensor_strides", self)

    @property
    def offset(self):
        return _call("tensor_offset", self)

    @property
    def values(self):
        return _call("tensor_values", self)

    @property
    def type_name(self):
        return _call("tensor_dtype", self)

    @property
    def dtype_code(self):
        return self.info[1]

    @property
    def element_type(self):
        return _call("element_type", self)

    @property
    def layout(self):
        return _call("tensor_layout", self)

    @property
    def device(self):
        return _call("tensor_device", self)

    @property
    def numel(self):
        return _call("numel", self)

    @property
    def is_contiguous(self):
        return _call("is_contiguous", self)

    def to_list(self):
        return self.values

    def __eq__(self, other):
        if not isinstance(other, Tensor):
            return NotImplemented
        return _call("_equal_tensor", self, other)

    __hash__ = None


class TensorDouble(Tensor):
    """Original Tensor Double; shared directly with the Image API's kind161."""


class TensorGraph(Value):
    """Lazy original TensorGraph. Owns deferred callback references transitively."""

    def evaluate(self):
        return _call("evaluate_graph", self)


class MutableTensor(Value):
    """Original pinned mutable view; synchronize concurrent writes externally."""

    @property
    def shape(self):
        return _call("mutable_shape", self)

    def read(self, coordinates):
        return _call("read_mutable", self, coordinates)

    def write(self, coordinates, value):
        return _call("write_mutable", self, coordinates, value)

    def freeze(self):
        return _call("freeze_tensor", self)


register(161, TensorDouble)
register(270, Tensor)
register(271, TensorGraph)
register(272, MutableTensor)
