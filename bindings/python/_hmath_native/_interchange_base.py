# SPDX-License-Identifier: MPL-2.0
"""Original interchange values, Element witnesses and scoped callback owners."""

import ctypes as C
import operator
import os

from . import _value as value
from ._bytes import Bytes
from ._callback_error import fill
from ._interchange_error import InterchangeError, InterchangeErrorKind
from ._math_error import Wire
from ._numerical_base import _CallbackState
from ._numerical_base import _invoke as _native_invoke

_PREFIX = "hmath_interchange_value_"
_CALLBACK = C.CFUNCTYPE(
    C.c_int, C.c_void_p, C.c_void_p, C.POINTER(C.c_void_p), C.POINTER(Wire)
)
_FAILURE_MESSAGE = C.create_string_buffer(b"Python interchange callback failed")
_DTYPES = (
    "bool",
    "int8",
    "uint8",
    "int16",
    "uint16",
    "int32",
    "uint32",
    "int64",
    "uint64",
    "float32",
    "float64",
    "complex64",
    "complex128",
)


class Array(value.Value):
    @property
    def shape(self):
        return _invoke(_PREFIX + "array_shape", [["Value"]], [self])

    @property
    def strides(self):
        return _invoke(_PREFIX + "array_strides", [["Value"]], [self])

    @property
    def offset(self):
        return _invoke(_PREFIX + "array_offset", [["Value"]], [self])

    @property
    def dtype(self):
        return _invoke(_PREFIX + "array_d_type", [["Value"]], [self])

    @property
    def backing_bytes(self):
        return _invoke(_PREFIX + "array_bytes", [["Value"]], [self])

    def __eq__(self, other):
        if not isinstance(other, Array):
            return NotImplemented
        return _invoke(_PREFIX + "equal_array", [["Value"], ["Value"]], [self, other])

    __hash__ = None


class Limits(value.Value):
    pass


class DType(value.Value):
    pass


class Endian(value.Value):
    pass


class Order(value.Value):
    pass


class Compression(value.Value):
    pass


class RawSpec(value.Value):
    pass


class GetProgram(value.Value):
    def decode(self, data, *, boxed=False):
        return _invoke(
            _PREFIX + "run_decoder",
            [["Value"], ["ByteString"]],
            [self, data],
            boxed=boxed,
        )


class PutProgram(value.Value):
    def to_bytes(self):
        return _invoke(_PREFIX + "put_bytes", [["Value"]], [self])


class MappedArray(value.Value):
    @property
    def shape(self):
        return _invoke(_PREFIX + "mapped_shape", [["Value"]], [self])

    def read_bytes(self, offset, count):
        return _invoke(
            _PREFIX + "mapped_read_bytes",
            [["Value"], ["Int"], ["Int"]],
            [self, offset, count],
        )

    def at(self, indices, *, dtype="float64", boxed=False):
        return _mapped_value(self, indices, dtype, boxed)


class BinaryHandle(value.Value):
    def close(self):
        if not getattr(self, "_ptr", None):
            return
        try:
            _invoke(_PREFIX + "close_handle", [["Value"]], [self])
        finally:
            super().close()

    def seek(self, offset, whence=0):
        return _invoke(
            _PREFIX + "seek_handle",
            [["Value"], ["Int"], ["Integer"]],
            [self, whence, offset],
        )

    def tell(self):
        return _invoke(_PREFIX + "tell_handle", [["Value"]], [self])

    def flush(self):
        return _invoke(_PREFIX + "flush_handle", [["Value"]], [self])


for kind, owner in {
    451: Array,
    452: BinaryHandle,
    457: Limits,
    458: DType,
    459: Endian,
    460: Order,
    461: Compression,
    462: RawSpec,
    463: GetProgram,
    464: PutProgram,
    465: MappedArray,
}.items():
    value.register(kind, owner)


def _decode_error(owner):
    try:
        kind, message = _invoke(_PREFIX + "error_fields", [["Value"]], [owner])
        return InterchangeError(InterchangeErrorKind(kind), message)
    finally:
        owner.close()


def _encode_error(error):
    name = ("invalid_data", "unsupported", "limit_exceeded", "interchange_io_error")[
        InterchangeErrorKind(error.kind)
    ]
    return _invoke(_PREFIX + name, [["String"]], [error.message], boxed=True)


value.register(453, _decode_error)
value.register_encoder(InterchangeError, _encode_error)


def _prepare(specification, argument, temporary):
    kind = specification[0]
    if kind in ("io", "either"):
        return _prepare(specification[1], argument, temporary)
    if kind == "function":
        if isinstance(argument, value.Value):
            return argument
        owner = _callback(argument, specification[-1])
        temporary.append(owner)
        return owner
    if kind == "ByteString":
        if isinstance(argument, Bytes):
            return argument
        if not isinstance(argument, (bytes, bytearray, memoryview)):
            raise TypeError("expected bytes, a byte buffer, or native Bytes")
        owner = Bytes(argument)
        temporary.append(owner)
        return owner
    if kind == "Char":
        if not isinstance(argument, str) or len(argument) != 1:
            raise TypeError("delimiter requires exactly one Unicode codepoint")
        return argument
    if kind == "String":
        argument = (
            os.fspath(argument) if isinstance(argument, os.PathLike) else argument
        )
        if not isinstance(argument, str):
            raise TypeError("expected a Unicode string")
        return argument
    if kind in ("Int", "Integer", "Word32"):
        return operator.index(argument)
    if kind == "Bool":
        if not isinstance(argument, bool):
            raise TypeError("expected bool")
        return argument
    if kind == "maybe":
        return (
            None
            if argument is None
            else _prepare(specification[1], argument, temporary)
        )
    if kind == "list":
        return [_prepare(specification[1], item, temporary) for item in argument]
    if kind == "tuple":
        fields = tuple(argument)
        if len(fields) != len(specification) - 1:
            raise ValueError("tuple arity differs")
        return tuple(
            _prepare(t, v, temporary) for t, v in zip(specification[1:], fields)
        )
    return argument


def _callback(function, result_spec):
    import hmath

    if not callable(function):
        raise TypeError("expected a callable original IO/decoder argument")
    state = _CallbackState()

    @_CALLBACK
    def callback(pointer, _, out, wire):
        temporary = []
        try:
            arguments = value.decode(value.borrow(pointer))
            returned = function(*arguments)
            encoded = value.encode(_prepare(result_spec, returned, temporary))
            state.retained.extend(
                owner for owner in encoded._owners if owner is not state
            )
            out[0] = encoded._ptr
            encoded._ptr, encoded._owners = C.c_void_p(), ()
            return 0
        except BaseException as error:  # noqa: BLE001 - nothing may unwind through ctypes
            try:
                status = fill(wire, error, state.buffers)
            except BaseException:
                status = 0  # noqa: BLE001 - malformed errors stay contained
            if status:
                return status
            state.failures.append(error)
            wire.contents.message = C.cast(_FAILURE_MESSAGE, C.c_void_p)
            wire.contents.message_length = len(_FAILURE_MESSAGE.value)
            return 6
        finally:
            for owner in temporary:
                owner.close()

    owner = value.Value._adopt(owners=(callback, state))
    hmath.initialize()
    hmath._check(
        value.api(
            "hmath_linear_callback",
            C.c_int,
            C.c_void_p,
            _CALLBACK,
            C.c_void_p,
            C.POINTER(C.c_void_p),
        )(None, callback, None, C.byref(owner._ptr))
    )
    return owner


def _invoke(symbol, specifications, arguments, *, boxed=False):
    temporary = []
    try:
        prepared = [
            _prepare(t, v, temporary) for t, v in zip(specifications, arguments)
        ]
        return _native_invoke(
            symbol, [["Value"] for _ in prepared], prepared, boxed=boxed
        )
    finally:
        for owner in temporary:
            owner.close()


def _dtype_name(dtype, array=None):
    if dtype is None:
        native = _invoke(_PREFIX + "array_d_type", [["Value"]], [array])
        try:
            return _DTYPES[_invoke(_PREFIX + "dtype_code", [["Value"]], [native])]
        finally:
            native.close()
    if isinstance(dtype, DType):
        return _DTYPES[_invoke(_PREFIX + "dtype_code", [["Value"]], [dtype])]
    name = getattr(dtype, "name", dtype)
    aliases = {
        "bool8": "bool",
        "f32": "float32",
        "f64": "float64",
        "c64": "complex64",
        "c128": "complex128",
        "i8": "int8",
        "u8": "uint8",
        "i16": "int16",
        "u16": "uint16",
        "i32": "int32",
        "u32": "uint32",
        "i64": "int64",
        "u64": "uint64",
    }
    name = aliases.get(str(name).lower(), str(name).lower())
    if name not in _DTYPES:
        raise ValueError("dtype has no original fixed-width Element instance")
    return name


def _scalar(source, dtype):
    if isinstance(source, value.Value):
        return source.clone()
    if dtype == "bool":
        if not isinstance(source, bool):
            raise TypeError("Bool8 values must be bool")
        return value.encode(source)
    return value.scalar(source, dtype)


def _prototype(dtype):
    return _scalar(False if dtype == "bool" else 0, dtype)


def _element_type(dtype):
    with _prototype(_dtype_name(dtype)) as prototype:
        return _invoke(_PREFIX + "element_type", [["Value"]], [prototype])


def _get_element(endian, dtype):
    with _prototype(_dtype_name(dtype)) as prototype:
        return _invoke(
            _PREFIX + "get_element", [["Value"], ["Value"]], [prototype, endian]
        )


def _put_element(endian, source, dtype):
    dtype = _dtype_name(dtype)
    with _prototype(dtype) as prototype, _scalar(source, dtype) as scalar:
        return _invoke(
            _PREFIX + "put_element", [["Value"]] * 3, [prototype, endian, scalar]
        )


def _from_values(limits, endian, shape, values, dtype):
    dtype = _dtype_name(dtype)
    items = []
    try:
        for item in values:
            items.append(_scalar(item, dtype))
        with _prototype(dtype) as prototype, value.encode(items) as encoded:
            return _invoke(
                _PREFIX + "from_values",
                [["Value"], ["Value"], ["Value"], ["list", ["Int"]], ["Value"]],
                [prototype, limits, endian, shape, encoded],
            )
    finally:
        for item in items:
            item.close()


def _to_values(operation, array, dtype, boxed):
    dtype = _dtype_name(dtype, array)
    with _prototype(dtype) as prototype:
        return _invoke(
            _PREFIX + operation, [["Value"], ["Value"]], [prototype, array], boxed=boxed
        )


def _mapped_value(mapping, indices, dtype, boxed):
    with _prototype(_dtype_name(dtype)) as prototype:
        return _invoke(
            _PREFIX + "mapped_value",
            [["Value"], ["Value"], ["list", ["Int"]]],
            [prototype, mapping, indices],
            boxed=boxed,
        )
