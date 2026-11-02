# SPDX-License-Identifier: MPL-2.0
"""Original typed Tensor and pinned mutable APIs, with deferred graph ownership."""

import ctypes as C
import threading
import weakref
from enum import IntEnum

from . import _value as v
from ._callback_error import fill
from ._compat import zip_equal
from ._math_error import Wire
from ._numeric import _int
from ._numeric_types_runtime import number
from ._tensor_catalog import CATALOG
from ._tensor_object import MutableTensor, Tensor, TensorDouble, TensorGraph

_SPEC = {item["name"]: item for item in CATALOG}
_pending = threading.local()


class Layout(IntEnum):
    ROW_MAJOR = 0
    COLUMN_MAJOR = 1
    STRIDED = 2


class Device(IntEnum):
    CPU = 0


RowMajor = Layout.ROW_MAJOR
ColumnMajor = Layout.COLUMN_MAJOR
Strided = Layout.STRIDED
CPU = Device.CPU


def _prototype(dtype="float64"):
    if isinstance(dtype, v.Value):
        return dtype.clone()
    if dtype in ("bool", "boolean"):
        return v.encode(False)
    if dtype in ("str", "string", "text"):
        return v.encode("")
    return v.scalar(0, dtype)


def _prototype_of(value):
    kind = value.info[0]
    symbol = (
        "hmath_tensor_object_graph_prototype"
        if kind == 271
        else "hmath_tensor_object_mutable_prototype"
        if kind == 272
        else "hmath_tensor_object_prototype"
    )
    return v.invoke(symbol, value)


def _coerce(value, prototype):
    if isinstance(value, v.Value):
        return value.clone()
    kind, dtype, _ = prototype.info
    if kind == 3:
        if not isinstance(value, bool):
            raise TypeError("expected Bool element")
        return v.encode(value)
    if kind == 10:
        if not isinstance(value, str):
            raise TypeError("expected String element")
        return v.encode(value)
    if kind == 1 and dtype in v.DTYPE_NAMES:
        return v.scalar(value, v.DTYPE_NAMES[dtype])
    if kind == 1:
        from ._numeric_types_runtime import _literal

        return _literal(value, prototype)
    raise TypeError("prototype is not a supported tensor element")


def _sequence(items, hint, prototype=None, tuple_=False):
    values = []
    try:
        for item in items:
            values.append(_typed(item, hint, prototype))
        return v.encode(tuple(values) if tuple_ else values)
    finally:
        for value in values:
            value.close()


def _typed(value, hint, prototype=None):
    if isinstance(value, v.Value):
        return value.clone()
    if hint == "Int":
        return v._create("hmath_value_index", [C.c_ssize_t], [_int(value)])
    if hint == "Integer":
        return v.scalar(value, "integer")
    if hint == "Bool":
        if not isinstance(value, bool):
            raise TypeError("expected Bool")
        return v.encode(value)
    if hint == "String":
        if not isinstance(value, str):
            raise TypeError("expected String")
        return v.encode(value)
    if hint == "Element":
        return v.encode(value) if prototype is None else _coerce(value, prototype)
    if hint == "Prototype":
        return _prototype(value)
    if hint == "Elements":
        if prototype is None:
            raise TypeError("element list requires an explicit type prototype")
        return _sequence(value, "Element", prototype)
    if hint == "[(Int,Int)]":
        return _sequence(value, "(Int,Int)")
    if hint == "(Int,Int)":
        values = tuple(value)
        if len(values) != 2:
            raise TypeError("expected pair")
        return _sequence(values, "Int", tuple_=True)
    if hint.startswith("["):
        return _sequence(value, hint[1:-1], prototype)
    return v.encode(value)


def _raw(name, *arguments):
    item = _SPEC[name]
    if len(arguments) != len(item["arguments"]):
        raise TypeError(name + " argument count differs")
    prototype = None
    values = []
    try:
        for argument, (parameter, hint) in zip_equal(arguments, item["arguments"]):
            if hint == "Prototype":
                prototype = (
                    argument.clone()
                    if isinstance(argument, v.Value)
                    else _prototype(argument)
                )
                break
        if prototype is None:
            for argument, (parameter, hint) in zip_equal(arguments, item["arguments"]):
                if (
                    parameter != "mask"
                    and hint in ("Tensor", "TensorGraph", "MutableTensor")
                    and isinstance(argument, v.Value)
                ):
                    prototype = _prototype_of(argument)
                    break
        for argument, (_, hint) in zip_equal(arguments, item["arguments"]):
            values.append(_typed(argument, hint, prototype))
        return v.invoke(item["c"], *values)
    except BaseException:
        if getattr(_pending, "exception", None) is not None:
            error = _pending.exception
            del _pending.exception
            raise error
        raise
    finally:
        for value in values:
            value.close()
        if prototype is not None:
            prototype.close()


def _invoke(name, *arguments, boxed=False):
    result = _raw(name, *arguments)
    if boxed:
        return result
    output = v.decode(result)
    if _SPEC[name]["result"] == "Layout":
        return Layout(output)
    if _SPEC[name]["result"] == "Device":
        return Device(output)
    if _SPEC[name]["result"] == "Unit":
        return None
    return output


class _Owner:
    def __init__(self, function, prototype=None):
        self.function = function
        self.prototype = None if prototype is None else prototype.clone()
        self.callback = None
        self.buffers = {}


_SCALAR = C.CFUNCTYPE(
    C.c_int, C.c_void_p, C.c_void_p, C.POINTER(C.c_void_p), C.POINTER(Wire)
)
_BUFFER = C.CFUNCTYPE(
    C.c_int, C.c_void_p, C.c_void_p, C.c_void_p, C.POINTER(C.c_void_p), C.POINTER(Wire)
)


def _callback_error(owner, error, wire):
    buffers = []
    # Reentrant error properties may invoke this same callback while encoding
    # a payload. Keep both buffer sets alive until their native owner is gone.
    owner.buffers.setdefault(threading.get_ident(), []).append(buffers)
    try:
        status = fill(wire, error, buffers)
        if status:
            return status
        _pending.exception = error
        payload = str(error).encode("utf-8", "surrogatepass")
        buffer = C.create_string_buffer(payload)
        buffers.append(buffer)
        wire.contents.kind = 0
        wire.contents.message = C.cast(buffer, C.c_void_p)
        wire.contents.message_length = len(payload)
        return 6
    except BaseException:  # noqa: BLE001 - contain exception transport failures
        _pending.exception = error
        return 6


def _give(out, value):
    try:
        with value._lock:
            v.api("hmath_value_retain", None, C.c_void_p)(value._ptr)
            out[0] = value._ptr
    finally:
        value.close()


def _scalar_callback(function, prototype):
    if not callable(function):
        raise TypeError("expected scalar callable")
    owner = _Owner(function, prototype)
    reference = weakref.proxy(owner)

    @_SCALAR
    def bridge(pointer, userdata, out, error):
        arguments = []
        try:
            with v.borrow(pointer) as value:
                for index in range(value.info[2]):
                    item = value.item(index)
                    # Numeric operators on these owned scalar inputs call the
                    # original dtype instances, retaining Float arithmetic.
                    if item.info[0] == 1:
                        try:
                            arguments.append(number(item))
                        finally:
                            item.close()
                    else:
                        arguments.append(v.decode(item))
            answer = reference.function(*arguments)
            _give(out, _coerce(answer, reference.prototype))
            return 0
        except BaseException as exception:  # noqa: BLE001 - C callback boundary
            return _callback_error(reference, exception, error)
        finally:
            # Like the C tuple, scalar arguments are borrowed for this call.
            # Clone a typed scalar or copy .value to retain it after return.
            for argument in arguments:
                if isinstance(argument, v.Value):
                    argument.close()

    owner.callback = bridge
    result = v.Value._adopt(owners=(owner,))
    import hmath

    hmath.initialize()
    hmath._check(
        v.api(
            "hmath_tensor_object_callback",
            C.c_int,
            C.c_void_p,
            _SCALAR,
            C.c_void_p,
            C.POINTER(C.c_void_p),
        )(None, bridge, None, C.byref(result._ptr))
    )
    return result


class _ComplexFloat(C.Structure):
    _fields_ = [("real", C.c_float), ("imag", C.c_float)]


class _ComplexDouble(C.Structure):
    _fields_ = [("real", C.c_double), ("imag", C.c_double)]


_CTYPES = {
    0: C.c_double,
    1: C.c_float,
    4: _ComplexDouble,
    5: _ComplexFloat,
    6: C.c_int8,
    7: C.c_int16,
    8: C.c_int32,
    9: C.c_int64,
    10: C.c_uint8,
    11: C.c_uint16,
    12: C.c_uint32,
    13: C.c_uint64,
    14: C.c_ssize_t,
    15: C.c_size_t,
}


class BorrowedBuffer:
    """Pointer access is valid only during with_mutable_buffer's callback."""

    def __init__(self, address, prototype, shape, strides, itemsize, alignment):
        self._address = address
        self._prototype = prototype
        self.shape, self.strides, self.itemsize, self.alignment = (
            shape,
            strides,
            itemsize,
            alignment,
        )
        self._active = True

    @property
    def pointer(self):
        if not self._active:
            raise ValueError("borrowed mutable buffer is outside its callback scope")
        kind, dtype, _ = self._prototype.info
        type_ = C.c_int if kind == 3 else _CTYPES.get(dtype)
        if type_ is None or C.sizeof(type_) != self.itemsize:
            raise TypeError("no matching ctypes Storable representation")
        return C.cast(self._address, C.POINTER(type_))

    def _invalidate(self):
        self._active = False
        self._prototype.close()


def _buffer_callback(function):
    if not callable(function):
        raise TypeError("expected buffer callable")
    owner = _Owner(function)
    reference = weakref.proxy(owner)

    @_BUFFER
    def bridge(address, pointer, userdata, out, error):
        buffer = None
        try:
            with v.borrow(pointer) as metadata:
                prototype = metadata.item(0)
                fields = [v.decode(metadata.item(index)) for index in range(1, 5)]
            buffer = BorrowedBuffer(address, prototype, *fields)
            answer = reference.function(buffer)
            _give(out, v.encode(answer))
            return 0
        except BaseException as exception:  # noqa: BLE001 - C callback boundary
            return _callback_error(reference, exception, error)
        finally:
            if buffer is not None:
                buffer._invalidate()

    owner.callback = bridge
    result = v.Value._adopt(owners=(owner,))
    import hmath

    hmath.initialize()
    hmath._check(
        v.api(
            "hmath_tensor_object_buffer_callback",
            C.c_int,
            C.c_void_p,
            _BUFFER,
            C.c_void_p,
            C.POINTER(C.c_void_p),
        )(None, bridge, None, C.byref(result._ptr))
    )
    return result


def tensor(shape, values, *, dtype="float64"):
    with _prototype(dtype) as prototype:
        return _invoke("tensor", prototype, shape, values)


def tensor_column_major(shape, values, *, dtype="float64"):
    with _prototype(dtype) as prototype:
        return _invoke("tensorColumnMajor", prototype, shape, values)


def tensor_zeros(shape, *, dtype="float64"):
    with _prototype(dtype) as prototype:
        return _invoke("tensorZeros", prototype, shape)


def tensor_ones(shape, *, dtype="float64"):
    with _prototype(dtype) as prototype:
        return _invoke("tensorOnes", prototype, shape)


def tensor_full(shape, value, *, dtype=None):
    if dtype is None:
        return _invoke("tensorFull", shape, value)
    with _prototype(dtype) as prototype, _coerce(value, prototype) as fill_value:
        if prototype.info[0] == 294:
            with _typed(shape, "[Int]") as dimensions:
                return v.decode(
                    v.invoke(
                        "hmath_tensor_object_full_typed",
                        prototype,
                        dimensions,
                        fill_value,
                    )
                )
        return _invoke("tensorFull", shape, fill_value)


def tensor_arange(start, end, step, *, dtype="float64"):
    with _prototype(dtype) as prototype:
        values = []
        try:
            values = [_coerce(value, prototype) for value in [start, end, step]]
            return _invoke("tensorArange", *values)
        finally:
            for value in values:
                value.close()


def tensor_linspace(start, end, count, *, dtype="float64"):
    with (
        _prototype(dtype) as prototype,
        _coerce(start, prototype) as first,
        _coerce(end, prototype) as last,
    ):
        return _invoke("tensorLinspace", first, last, count)


def tensor_logspace(base, start, end, count, *, dtype="float64"):
    with (
        _prototype(dtype) as prototype,
        _coerce(base, prototype) as scale,
        _coerce(start, prototype) as first,
        _coerce(end, prototype) as last,
    ):
        return _invoke("tensorLogspace", scale, first, last, count)


def _list_operation(name, arguments, tensors, dtype):
    tensors = list(tensors)
    with (
        _prototype_of(tensors[0])
        if dtype is None and tensors
        else _prototype("float64" if dtype is None else dtype)
    ) as prototype:
        return _invoke(name, prototype, *arguments, tensors)


def concatenate(axis, tensors, *, dtype=None):
    return _list_operation("concatenate", [axis], tensors, dtype)


def stack(axis, tensors, *, dtype=None):
    return _list_operation("stack", [axis], tensors, dtype)


def einsum(labels, output, tensors, *, dtype=None):
    return _list_operation("einsum", [labels, output], tensors, dtype)


def promote_tensor(dtype, tensor):
    with _prototype(dtype) as prototype:
        return _invoke("promoteTensor", prototype, tensor)


def deserialize_tensor(source, *, dtype="float64"):
    with _prototype(dtype) as prototype:
        return _invoke("deserializeTensor", prototype, source)


def _mapped(name, function, inputs, dtype):
    with (
        _prototype_of(inputs[0]) if dtype is None else _prototype(dtype) as prototype,
        _scalar_callback(function, prototype) as callback,
    ):
        return _invoke(name, prototype, callback, *inputs)


def map_tensor(function, tensor, *, dtype=None):
    return _mapped("mapTensor", function, [tensor], dtype)


def zip_tensor(function, left, right, *, dtype=None):
    return _mapped("zipTensor", function, [left, right], dtype)


def map_graph(function, graph, *, dtype=None):
    return _mapped("mapGraph", function, [graph], dtype)


def zip_graph(function, left, right, *, dtype=None):
    return _mapped("zipGraph", function, [left, right], dtype)


def new_mutable(shape, value, *, dtype="float64"):
    with _prototype(dtype) as prototype, _coerce(value, prototype) as fill_value:
        return _invoke("newMutable", shape, fill_value)


def modify_mutable(tensor, coordinates, function):
    with (
        _prototype_of(tensor) as prototype,
        _scalar_callback(function, prototype) as callback,
    ):
        return _invoke("modifyMutable", tensor, coordinates, callback)


def mutable_alignment(dtype):
    with _prototype(dtype) as prototype:
        return _invoke("mutableAlignment", prototype)


def with_mutable_buffer(tensor, function):
    with _buffer_callback(function) as callback:
        return _invoke("withMutableBuffer", tensor, callback)


def _equal_tensor(left, right):
    return v.decode(v.invoke("hmath_tensor_object_equal_instance", left, right))


def element_type(tensor):
    """Return an owned dtype prototype, including exact structural type tokens."""
    return _prototype_of(tensor)


# BEGIN GENERATED
def tensor_random(seed, shape):
    """HMath.Tensor.tensorRandom: original dtype and failure conditions."""
    return _invoke("tensorRandom", seed, shape)


def tensor_values(tensor):
    """HMath.Tensor.tensorValues: original dtype and failure conditions."""
    return _invoke("tensorValues", tensor)


def tensor_shape(tensor):
    """HMath.Tensor.tensorShape: original dtype and failure conditions."""
    return _invoke("tensorShape", tensor)


def tensor_strides(tensor):
    """HMath.Tensor.tensorStrides: original dtype and failure conditions."""
    return _invoke("tensorStrides", tensor)


def tensor_offset(tensor):
    """HMath.Tensor.tensorOffset: original dtype and failure conditions."""
    return _invoke("tensorOffset", tensor)


def tensor_dtype(tensor):
    """HMath.Tensor.tensorDType: original dtype and failure conditions."""
    return _invoke("tensorDType", tensor)


def tensor_device(tensor):
    """HMath.Tensor.tensorDevice: original dtype and failure conditions."""
    return _invoke("tensorDevice", tensor)


def tensor_layout(tensor):
    """HMath.Tensor.tensorLayout: original dtype and failure conditions."""
    return _invoke("tensorLayout", tensor)


def numel(tensor):
    """HMath.Tensor.numel: original dtype and failure conditions."""
    return _invoke("numel", tensor)


def is_contiguous(tensor):
    """HMath.Tensor.isContiguous: original dtype and failure conditions."""
    return _invoke("isContiguous", tensor)


def shape_size(shape):
    """HMath.Tensor.shapeSize: original dtype and failure conditions."""
    return _invoke("shapeSize", shape)


def infer_broadcast(left, right):
    """HMath.Tensor.inferBroadcast: original dtype and failure conditions."""
    return _invoke("inferBroadcast", left, right)


def contiguous(tensor):
    """HMath.Tensor.contiguous: original dtype and failure conditions."""
    return _invoke("contiguous", tensor)


def index_tensor(tensor, coordinates):
    """HMath.Tensor.indexTensor: original dtype and failure conditions."""
    return _invoke("indexTensor", tensor, coordinates)


def slice_tensor(axis, start, count, step, tensor):
    """HMath.Tensor.sliceTensor: original dtype and failure conditions."""
    return _invoke("sliceTensor", axis, start, count, step, tensor)


def fancy_index(axis, indices, tensor):
    """HMath.Tensor.fancyIndex: original dtype and failure conditions."""
    return _invoke("fancyIndex", axis, indices, tensor)


def gather(axis, indices, tensor):
    """HMath.Tensor.gather: original dtype and failure conditions."""
    return _invoke("gather", axis, indices, tensor)


def boolean_index(mask, tensor):
    """HMath.Tensor.booleanIndex: original dtype and failure conditions."""
    return _invoke("booleanIndex", mask, tensor)


def scatter(axis, indices, updates, target):
    """HMath.Tensor.scatter: original dtype and failure conditions."""
    return _invoke("scatter", axis, indices, updates, target)


def scatter_add(axis, indices, updates, target):
    """HMath.Tensor.scatterAdd: original dtype and failure conditions."""
    return _invoke("scatterAdd", axis, indices, updates, target)


def reshape_tensor(shape, tensor):
    """HMath.Tensor.reshapeTensor: original dtype and failure conditions."""
    return _invoke("reshapeTensor", shape, tensor)


def flatten_tensor(tensor):
    """HMath.Tensor.flattenTensor: original dtype and failure conditions."""
    return _invoke("flattenTensor", tensor)


def squeeze(tensor):
    """HMath.Tensor.squeeze: original dtype and failure conditions."""
    return _invoke("squeeze", tensor)


def unsqueeze(axis, tensor):
    """HMath.Tensor.unsqueeze: original dtype and failure conditions."""
    return _invoke("unsqueeze", axis, tensor)


def expand(shape, tensor):
    """HMath.Tensor.expand: original dtype and failure conditions."""
    return _invoke("expand", shape, tensor)


def permute(axes, tensor):
    """HMath.Tensor.permute: original dtype and failure conditions."""
    return _invoke("permute", axes, tensor)


def transpose_tensor(tensor):
    """HMath.Tensor.transposeTensor: original dtype and failure conditions."""
    return _invoke("transposeTensor", tensor)


def move_axis(from_axis, to_axis, tensor):
    """HMath.Tensor.moveAxis: original dtype and failure conditions."""
    return _invoke("moveAxis", from_axis, to_axis, tensor)


def swap_axes(from_axis, to_axis, tensor):
    """HMath.Tensor.swapAxes: original dtype and failure conditions."""
    return _invoke("swapAxes", from_axis, to_axis, tensor)


def broadcast_to(shape, tensor):
    """HMath.Tensor.broadcastTo: original dtype and failure conditions."""
    return _invoke("broadcastTo", shape, tensor)


def repeat_tensor(axis, count, tensor):
    """HMath.Tensor.repeatTensor: original dtype and failure conditions."""
    return _invoke("repeatTensor", axis, count, tensor)


def tile(counts, tensor):
    """HMath.Tensor.tile: original dtype and failure conditions."""
    return _invoke("tile", counts, tensor)


def split_tensor(axis, segments, tensor):
    """HMath.Tensor.splitTensor: original dtype and failure conditions."""
    return _invoke("splitTensor", axis, segments, tensor)


def chunk_tensor(axis, count, tensor):
    """HMath.Tensor.chunkTensor: original dtype and failure conditions."""
    return _invoke("chunkTensor", axis, count, tensor)


def pad_tensor(padding, value, tensor):
    """HMath.Tensor.padTensor: original dtype and failure conditions."""
    return _invoke("padTensor", padding, value, tensor)


def roll(axis, shift, tensor):
    """HMath.Tensor.roll: original dtype and failure conditions."""
    return _invoke("roll", axis, shift, tensor)


def flip_tensor(axis, tensor):
    """HMath.Tensor.flipTensor: original dtype and failure conditions."""
    return _invoke("flipTensor", axis, tensor)


def rotate(first, second, turns, tensor):
    """HMath.Tensor.rotate: original dtype and failure conditions."""
    return _invoke("rotate", first, second, turns, tensor)


def sort_tensor(tensor):
    """HMath.Tensor.sortTensor: original dtype and failure conditions."""
    return _invoke("sortTensor", tensor)


def unique(tensor):
    """HMath.Tensor.unique: original dtype and failure conditions."""
    return _invoke("unique", tensor)


def argsort(tensor):
    """HMath.Tensor.argsort: original dtype and failure conditions."""
    return _invoke("argsort", tensor)


def topk(count, tensor):
    """HMath.Tensor.topk: original dtype and failure conditions."""
    return _invoke("topk", count, tensor)


def nonzero(tensor):
    """HMath.Tensor.nonzero: original dtype and failure conditions."""
    return _invoke("nonzero", tensor)


def where_tensor(mask, left, right):
    """HMath.Tensor.whereTensor: original dtype and failure conditions."""
    return _invoke("whereTensor", mask, left, right)


def masked_fill(mask, value, tensor):
    """HMath.Tensor.maskedFill: original dtype and failure conditions."""
    return _invoke("maskedFill", mask, value, tensor)


def masked_select(mask, tensor):
    """HMath.Tensor.maskedSelect: original dtype and failure conditions."""
    return _invoke("maskedSelect", mask, tensor)


def tensor_add(a, b):
    """HMath.Tensor.tensorAdd: original dtype and failure conditions."""
    return _invoke("tensorAdd", a, b)


def tensor_subtract(a, b):
    """HMath.Tensor.tensorSubtract: original dtype and failure conditions."""
    return _invoke("tensorSubtract", a, b)


def tensor_multiply(a, b):
    """HMath.Tensor.tensorMultiply: original dtype and failure conditions."""
    return _invoke("tensorMultiply", a, b)


def tensor_divide(a, b):
    """HMath.Tensor.tensorDivide: original dtype and failure conditions."""
    return _invoke("tensorDivide", a, b)


def tensor_equal(a, b):
    """HMath.Tensor.tensorEqual: original dtype and failure conditions."""
    return _invoke("tensorEqual", a, b)


def tensor_less(a, b):
    """HMath.Tensor.tensorLess: original dtype and failure conditions."""
    return _invoke("tensorLess", a, b)


def tensor_and(a, b):
    """HMath.Tensor.tensorAnd: original dtype and failure conditions."""
    return _invoke("tensorAnd", a, b)


def tensor_or(a, b):
    """HMath.Tensor.tensorOr: original dtype and failure conditions."""
    return _invoke("tensorOr", a, b)


def tensor_not(tensor):
    """HMath.Tensor.tensorNot: original dtype and failure conditions."""
    return _invoke("tensorNot", tensor)


def sum_axes(axes, keep_dimensions, tensor):
    """HMath.Tensor.sumAxes: original dtype and failure conditions."""
    return _invoke("sumAxes", axes, keep_dimensions, tensor)


def product_axes(axes, keep_dimensions, tensor):
    """HMath.Tensor.productAxes: original dtype and failure conditions."""
    return _invoke("productAxes", axes, keep_dimensions, tensor)


def mean_axes(axes, keep_dimensions, tensor):
    """HMath.Tensor.meanAxes: original dtype and failure conditions."""
    return _invoke("meanAxes", axes, keep_dimensions, tensor)


def variance_axes(axes, keep_dimensions, tensor):
    """HMath.Tensor.varianceAxes: original dtype and failure conditions."""
    return _invoke("varianceAxes", axes, keep_dimensions, tensor)


def norm_axes(axes, keep_dimensions, tensor):
    """HMath.Tensor.normAxes: original dtype and failure conditions."""
    return _invoke("normAxes", axes, keep_dimensions, tensor)


def min_axes(axes, keep_dimensions, tensor):
    """HMath.Tensor.minAxes: original dtype and failure conditions."""
    return _invoke("minAxes", axes, keep_dimensions, tensor)


def max_axes(axes, keep_dimensions, tensor):
    """HMath.Tensor.maxAxes: original dtype and failure conditions."""
    return _invoke("maxAxes", axes, keep_dimensions, tensor)


def argmin(tensor):
    """HMath.Tensor.argmin: original dtype and failure conditions."""
    return _invoke("argmin", tensor)


def argmax(tensor):
    """HMath.Tensor.argmax: original dtype and failure conditions."""
    return _invoke("argmax", tensor)


def cumulative_sum(axis, tensor):
    """HMath.Tensor.cumulativeSum: original dtype and failure conditions."""
    return _invoke("cumulativeSum", axis, tensor)


def cumulative_product(axis, tensor):
    """HMath.Tensor.cumulativeProduct: original dtype and failure conditions."""
    return _invoke("cumulativeProduct", axis, tensor)


def tensordot(left_axes, right_axes, left, right):
    """HMath.Tensor.tensordot: original dtype and failure conditions."""
    return _invoke("tensordot", left_axes, right_axes, left, right)


def batched_matmul(a, b):
    """HMath.Tensor.batchedMatmul: original dtype and failure conditions."""
    return _invoke("batchedMatmul", a, b)


def tensor_kronecker(a, b):
    """HMath.Tensor.tensorKronecker: original dtype and failure conditions."""
    return _invoke("tensorKronecker", a, b)


def serialize_tensor(tensor):
    """HMath.Tensor.serializeTensor: original dtype and failure conditions."""
    return _invoke("serializeTensor", tensor)


def input_graph(tensor):
    """HMath.Tensor.inputGraph: original dtype and failure conditions."""
    return _invoke("inputGraph", tensor)


def evaluate_graph(tensor):
    """HMath.Tensor.evaluateGraph: original dtype and failure conditions."""
    return _invoke("evaluateGraph", tensor)


def thaw_tensor(tensor):
    """HMath.Tensor.Mutable.thawTensor: original dtype and failure conditions."""
    return _invoke("thawTensor", tensor)


def freeze_tensor(tensor):
    """HMath.Tensor.Mutable.freezeTensor: original dtype and failure conditions."""
    return _invoke("freezeTensor", tensor)


def mutable_shape(tensor):
    """HMath.Tensor.Mutable.mutableShape: original dtype and failure conditions."""
    return _invoke("mutableShape", tensor)


def read_mutable(tensor, coordinates):
    """HMath.Tensor.Mutable.readMutable: original dtype and failure conditions."""
    return _invoke("readMutable", tensor, coordinates)


def write_mutable(tensor, coordinates, value):
    """HMath.Tensor.Mutable.writeMutable: original dtype and failure conditions."""
    return _invoke("writeMutable", tensor, coordinates, value)


def slice_mutable(axis, start, count, step, tensor):
    """HMath.Tensor.Mutable.sliceMutable: original dtype and failure conditions."""
    return _invoke("sliceMutable", axis, start, count, step, tensor)


def transpose_mutable(tensor):
    """HMath.Tensor.Mutable.transposeMutable: original dtype and failure conditions."""
    return _invoke("transposeMutable", tensor)


__all__ = [
    "CPU",
    "BorrowedBuffer",
    "ColumnMajor",
    "Device",
    "Layout",
    "MutableTensor",
    "RowMajor",
    "Strided",
    "Tensor",
    "TensorDouble",
    "TensorGraph",
    "argmax",
    "argmin",
    "argsort",
    "batched_matmul",
    "boolean_index",
    "broadcast_to",
    "chunk_tensor",
    "concatenate",
    "contiguous",
    "cumulative_product",
    "cumulative_sum",
    "deserialize_tensor",
    "einsum",
    "element_type",
    "evaluate_graph",
    "expand",
    "fancy_index",
    "flatten_tensor",
    "flip_tensor",
    "freeze_tensor",
    "gather",
    "index_tensor",
    "input_graph",
    "is_contiguous",
    "map_graph",
    "map_tensor",
    "masked_fill",
    "masked_select",
    "max_axes",
    "mean_axes",
    "min_axes",
    "modify_mutable",
    "move_axis",
    "mutable_alignment",
    "mutable_shape",
    "new_mutable",
    "nonzero",
    "norm_axes",
    "numel",
    "pad_tensor",
    "permute",
    "product_axes",
    "promote_tensor",
    "read_mutable",
    "repeat_tensor",
    "reshape_tensor",
    "roll",
    "rotate",
    "scatter",
    "scatter_add",
    "serialize_tensor",
    "slice_mutable",
    "slice_tensor",
    "sort_tensor",
    "split_tensor",
    "squeeze",
    "stack",
    "sum_axes",
    "swap_axes",
    "tensor",
    "tensor_add",
    "tensor_and",
    "tensor_arange",
    "tensor_column_major",
    "tensor_device",
    "tensor_divide",
    "tensor_dtype",
    "tensor_equal",
    "tensor_full",
    "tensor_kronecker",
    "tensor_layout",
    "tensor_less",
    "tensor_linspace",
    "tensor_logspace",
    "tensor_multiply",
    "tensor_not",
    "tensor_offset",
    "tensor_ones",
    "tensor_or",
    "tensor_random",
    "tensor_shape",
    "tensor_strides",
    "tensor_subtract",
    "tensor_values",
    "tensor_zeros",
    "tensordot",
    "thaw_tensor",
    "tile",
    "topk",
    "transpose_mutable",
    "transpose_tensor",
    "unique",
    "unsqueeze",
    "variance_axes",
    "where_tensor",
    "with_mutable_buffer",
    "write_mutable",
    "zip_graph",
    "zip_tensor",
]
# END GENERATED
