# SPDX-License-Identifier: MPL-2.0
"""Native Haskell AD graphs, dual arithmetic and explicit gradient state.

Builders/rules are pure functions of their inputs. Handles are immutable; close
retained objects explicitly. Callbacks are retained transitively by graph owners.
"""

import ctypes as C
import math
import threading
import weakref
from contextlib import ExitStack, contextmanager
from fractions import Fraction

from ._callback_error import fill as _fill_callback_error
from ._math_error import Wire as _ErrorWire
from ._numeric import _decimal, _int, _integer

P, Z, D, I = C.c_void_p, C.c_size_t, C.c_double, C.c_ssize_t
_callback_errors = threading.local()


def _api(name, *types, result=C.c_int):
    import hmath

    return C.CFUNCTYPE(result, *types)(("hmath_ad_" + name, hmath._lib))


def _check(code):
    import hmath

    if code and getattr(_callback_errors, "error", None) is not None:
        error = _callback_errors.error
        del _callback_errors.error
        raise error
    hmath._check(code)


def _real(value):
    try:
        return float(value)
    except OverflowError:
        return math.inf if value >= 0 else -math.inf


def _owners(*values):
    keepers = {id(keeper): keeper for value in values for keeper in value._keepers}
    return tuple(keepers.values())


@contextmanager
def _locked(*objects):
    with ExitStack() as stack:
        objects = sorted({id(value): value for value in objects}.values(), key=id)
        for value in objects:
            stack.enter_context(value._lock)
            if not value._ptr:
                raise ValueError("AD object is closed")
        # Independent native refs and callback snapshots survive reentrant close.
        snapshots = [(value._ptr, value._keepers) for value in objects]
        for pointer, _ in snapshots:
            _api("retain", P, result=None)(pointer)
        try:
            yield
        finally:
            for pointer, _ in snapshots:
                _api("release", P, result=None)(pointer)


def _new(cls, name, types, args, parents=(), keepers=()):
    import hmath

    hmath.initialize()
    result = cls._adopt(P())
    result._keepers = _owners(*parents) + tuple(keepers)
    with _locked(*parents):
        _check(_api(name, P, *types, C.POINTER(P))(None, *args, C.byref(result._ptr)))
    return result


class _Handle:
    @classmethod
    def _adopt(cls, pointer, keepers=()):
        value = object.__new__(cls)
        value._ptr, value._lock, value._keepers = (
            pointer,
            threading.RLock(),
            tuple(keepers),
        )
        return value

    def close(self):
        with self._lock:
            if self._ptr:
                _api("release", P, result=None)(self._ptr)
                self._ptr = P()
                self._keepers = ()

    def __enter__(self):
        with _locked(self):
            return self

    def __exit__(self, *_):
        self.close()

    def __del__(self):
        if getattr(self, "_ptr", None):
            self.close()

    def _metadata(self):
        count, rank = Z(), Z()
        with _locked(self):
            _check(
                _api("metadata", P, C.POINTER(Z), C.POINTER(Z))(
                    self._ptr, C.byref(count), C.byref(rank)
                )
            )
        return count.value, rank.value


class _Arithmetic(_Handle):
    def _coerce(self, value):
        if isinstance(value, type(self)):
            return value
        if isinstance(value, _Handle):
            raise TypeError("cannot mix AD handle kinds")
        return constant(value) if isinstance(self, Expr) else Dual(value, 0)

    def _binary(self, other, operation, reverse=False):
        other = self._coerce(other)
        left, right = (other, self) if reverse else (self, other)
        return _new(
            type(self),
            "binary",
            [C.c_int, P, P],
            [operation, left._ptr, right._ptr],
            parents=[left, right],
        )

    def _unary(self, operation):
        return _new(
            type(self), "unary", [C.c_int, P], [operation, self._ptr], parents=[self]
        )

    def __add__(self, other):
        return self._binary(other, 0)

    def __radd__(self, other):
        return self._binary(other, 0, True)

    def __sub__(self, other):
        return self._binary(other, 1)

    def __rsub__(self, other):
        return self._binary(other, 1, True)

    def __mul__(self, other):
        return self._binary(other, 2)

    def __rmul__(self, other):
        return self._binary(other, 2, True)

    def __truediv__(self, other):
        return self._binary(other, 3)

    def __rtruediv__(self, other):
        return self._binary(other, 3, True)

    def __pow__(self, other):
        return self._binary(other, 4)

    def __rpow__(self, other):
        return self._binary(other, 4, True)

    def __neg__(self):
        return self._unary(0)

    def __abs__(self):
        return self._unary(1)


class Expr(_Arithmetic):
    """Immutable scalar expression using the original Haskell Expr instances."""


class Dual(_Arithmetic):
    """Original nested Dual instances over explicitly typed coefficient leaves."""

    def __init__(self, value, tangent, *, dtype=None):
        import hmath

        self._ptr, self._lock, self._keepers = P(), threading.RLock(), ()
        hmath.initialize()
        template = (
            value
            if isinstance(value, Dual)
            else tangent
            if isinstance(tangent, Dual)
            else None
        )
        owned_prototype = None
        if dtype is None:
            if template is not None:
                dtype = template.dtype
                if dtype.startswith("numeric."):
                    owned_prototype = template.element_type
                    dtype = owned_prototype
            else:
                from ._value import Value

                if isinstance(value, Value):
                    dtype = value
                elif isinstance(tangent, Value):
                    dtype = tangent
                else:
                    dtype = (
                        "complex128"
                        if isinstance(value, complex) or isinstance(tangent, complex)
                        else "float64"
                    )
        try:
            self._initialize_pair(value, tangent, dtype, template)
        finally:
            if owned_prototype is not None:
                owned_prototype.close()

    def _initialize_pair(self, value, tangent, dtype, template):
        from . import _value as v

        if not isinstance(dtype, v.Value) and dtype not in v.DTYPES:
            raise ValueError(
                "Dual dtype must name a supported coefficient or provide a typed coefficient prototype"
            )
        if template is not None:
            value = _dual_number(value, template.depth, dtype)
            tangent = _dual_number(tangent, template.depth, dtype)
            self._keepers = _owners(value, tangent)
            with _locked(value, tangent):
                _check(
                    _api("dual_nested", P, P, P, C.POINTER(P))(
                        None, value._ptr, tangent._ptr, C.byref(self._ptr)
                    )
                )
        elif dtype in ("float64", "float32"):
            real = D if dtype == "float64" else C.c_float
            name = "dual_create" if dtype == "float64" else "dual_create_f32"
            _check(
                _api(name, P, real, real, C.POINTER(P))(
                    None, _real(value), _real(tangent), C.byref(self._ptr)
                )
            )
        elif dtype == "integer":
            _check(
                _api("dual_create_integer", P, C.c_char_p, C.c_char_p, C.POINTER(P))(
                    None, _decimal(value), _decimal(tangent), C.byref(self._ptr)
                )
            )
        elif dtype == "rational":
            value, tangent = Fraction(value), Fraction(tangent)
            _check(
                _api(
                    "dual_create_rational",
                    P,
                    C.c_char_p,
                    C.c_char_p,
                    C.c_char_p,
                    C.c_char_p,
                    C.POINTER(P),
                )(
                    None,
                    _decimal(value.numerator),
                    _decimal(value.denominator),
                    _decimal(tangent.numerator),
                    _decimal(tangent.denominator),
                    C.byref(self._ptr),
                )
            )

        else:
            from ._autodiff_value import export_value

            with (
                _coefficient_leaf(value, dtype) as primal_value,
                _coefficient_leaf(tangent, dtype) as tangent_value,
                export_value(primal_value) as primal_handle,
                export_value(tangent_value) as tangent_handle,
            ):
                self._keepers = _owners(primal_handle, tangent_handle)
                with _locked(primal_handle, tangent_handle):
                    _check(
                        _api("dual_nested", P, P, P, C.POINTER(P))(
                            None,
                            primal_handle._ptr,
                            tangent_handle._ptr,
                            C.byref(self._ptr),
                        )
                    )

    @property
    def depth(self):
        out = Z()
        with _locked(self):
            _check(_api("dual_depth", P, C.POINTER(Z))(self._ptr, C.byref(out)))
        return out.value

    @property
    def dtype(self):
        kind = C.c_int()
        with _locked(self):
            _check(_api("dual_kind", P, C.POINTER(C.c_int))(self._ptr, C.byref(kind)))
        from ._value import DTYPE_NAMES

        return DTYPE_NAMES.get(
            kind.value,
            {20: "numeric.dual", 21: "numeric.quaternion"}.get(
                kind.value, "unsupported"
            ),
        )

    @property
    def element_type(self):
        """Owned exact source coefficient prototype, including numeric towers."""
        from ._autodiff_value import import_value

        current, owned = self, []
        try:
            while current.depth:
                first, second = Dual._adopt(P()), Dual._adopt(P())
                with _locked(current):
                    _check(
                        _api("dual_parts", P, C.POINTER(P), C.POINTER(P))(
                            current._ptr, C.byref(first._ptr), C.byref(second._ptr)
                        )
                    )
                second.close()
                current = first
                owned.append(first)
            return import_value(current)
        finally:
            for value in owned:
                value.close()

    def _coerce(self, value):
        dtype = self.dtype
        if dtype.startswith("numeric."):
            with self.element_type as prototype:
                return _dual_number(value, self.depth, prototype)
        return _dual_number(value, self.depth, dtype)

    def _part(self, index):
        if self.depth == 1 and self.dtype in ("float64", "float32"):
            return _copy_values(self)[index]
        primal_part, tangent_part = Dual._adopt(P()), Dual._adopt(P())
        with _locked(self):
            _check(
                _api("dual_parts", P, C.POINTER(P), C.POINTER(P))(
                    self._ptr, C.byref(primal_part._ptr), C.byref(tangent_part._ptr)
                )
            )
        parts = [primal_part, tangent_part]
        parts[1 - index].close()
        result = parts[index]
        if result.depth == 0:
            try:
                from ._autodiff_value import import_value

                return import_value(result).decode()
            finally:
                result.close()
        return result

    def _relation(self, other, operation):
        other = self._coerce(other)
        out = C.c_int()
        with _locked(self, other):
            _check(
                _api("dual_relation", P, C.c_int, P, P, C.POINTER(C.c_int))(
                    None, operation, self._ptr, other._ptr, C.byref(out)
                )
            )
        return bool(out.value)

    def __eq__(self, other):
        try:
            return self._relation(other, 0)
        except TypeError:
            return NotImplemented

    def __lt__(self, other):
        return self._relation(other, 1)

    def __le__(self, other):
        return self._relation(other, 2)

    def __gt__(self, other):
        return self._relation(other, 3)

    def __ge__(self, other):
        return self._relation(other, 4)

    @property
    def primal(self):
        return self._part(0)

    @property
    def tangent(self):
        return self._part(1)


def _coefficient_leaf(value, dtype):
    from . import _value as v

    if isinstance(value, v.Value):
        return value.clone()
    if isinstance(dtype, v.Value):
        from ._numeric_types_runtime import _literal

        return _literal(value, dtype)
    return v.scalar(value, dtype)


def _dual_number(value, depth, dtype):
    if isinstance(value, Dual):
        if value.depth != depth or (isinstance(dtype, str) and value.dtype != dtype):
            raise TypeError("mismatched Dual scalar types")
        return value
    if isinstance(value, _Handle):
        raise TypeError("cannot mix AD handle kinds")
    result = value
    for _ in range(depth):
        result = Dual(result, 0, dtype=dtype)
    return result


def _exact_scalar(value):
    numerator, denominator = P(), P()
    try:
        with _locked(value):
            _check(
                _api("scalar_text", P, C.POINTER(P), C.POINTER(P))(
                    value._ptr, C.byref(numerator), C.byref(denominator)
                )
            )
        n, d = _integer(C.string_at(numerator)), _integer(C.string_at(denominator))
        return n if value.dtype == "integer" else Fraction(n, d)
    finally:
        _api("string_free", P, result=None)(numerator)
        _api("string_free", P, result=None)(denominator)


class CompiledGraph(_Handle):
    """Immutable compiled graph; evaluate it repeatedly at new input values."""

    def evaluate(self, values):
        return evaluate_graph(self, values)


class GradientState(_Handle):
    """Explicit original accumulation state; constructor adds no finite check."""

    def __init__(self, values):
        import hmath

        self._ptr, self._lock, self._keepers = P(), threading.RLock(), ()
        values = _doubles(values)
        hmath.initialize()
        _check(
            _api("gradient_state_create", P, C.POINTER(D), Z, C.POINTER(P))(
                None, values, len(values), C.byref(self._ptr)
            )
        )

    @property
    def accumulated_gradient(self):
        return _copy_values(self)


class ADTensor(_Handle):
    """Original row-major symbolic tensor and checked broadcast operations."""

    def __init__(self, shape, values):
        import hmath

        self._ptr, self._lock, self._keepers = P(), threading.RLock(), ()
        shape = _indices(shape)
        values = [_expression(value) for value in values]
        self._keepers = _owners(*values)
        hmath.initialize()
        with _locked(*values):
            pointers = (P * len(values))(*(value._ptr for value in values))
            _check(
                _api(
                    "tensor_create", P, C.POINTER(I), Z, C.POINTER(P), Z, C.POINTER(P)
                )(None, shape, len(shape), pointers, len(values), C.byref(self._ptr))
            )

    @property
    def shape(self):
        _, rank = self._metadata()
        shape = (I * rank)()
        with _locked(self):
            _check(_api("shape_copy", P, C.POINTER(I), Z)(self._ptr, shape, rank))
        return tuple(shape)

    @property
    def values(self):
        count, _ = self._metadata()
        pointers = (P * count)()
        adopted = []
        with _locked(self):
            _check(
                _api("tensor_values", P, C.POINTER(P), Z)(self._ptr, pointers, count)
            )
            try:
                for pointer in pointers:
                    adopted.append(Expr._adopt(P(pointer), self._keepers))
            except BaseException:
                for pointer in list(pointers)[len(adopted) :]:
                    _api("release", P, result=None)(pointer)
                raise
        return adopted

    def __add__(self, other):
        return ad_add(self, other)

    def __mul__(self, other):
        return ad_multiply(self, other)

    def __matmul__(self, other):
        return ad_matmul(self, other)


def _doubles(values):
    values = tuple(_real(value) for value in values)
    return (D * len(values))(*values)


def _indices(values):
    values = tuple(_int(value) for value in values)
    return (I * len(values))(*values)


def _expression(value):
    if isinstance(value, Expr):
        return value
    if isinstance(value, _Handle):
        raise TypeError("expected an AD expression")
    return constant(value)


def _copy_values(value):
    count, _ = value._metadata()
    out = (D * count)()
    with _locked(value):
        _check(_api("values_copy", P, C.POINTER(D), Z)(value._ptr, out, count))
    return list(out)


def variable(index):
    return _new(Expr, "variable", [I], [_int(index)])


def constant(value):
    return _new(Expr, "constant", [D], [_real(value)])


def compile_graph(input_count, expression):
    expression = _expression(expression)
    return _new(
        CompiledGraph,
        "compile_graph",
        [I, P],
        [_int(input_count), expression._ptr],
        parents=[expression],
    )


def differentiate(index, expression):
    expression = _expression(expression)
    return _new(
        Expr,
        "differentiate",
        [I, P],
        [_int(index), expression._ptr],
        parents=[expression],
    )


def _build(function, n, vector=False):
    value = (
        function([variable(index) for index in range(n)])
        if callable(function)
        else function
    )
    return [_expression(item) for item in value] if vector else [_expression(value)]


def _run(
    name, expressions, values, required, direction=None, scalar=None, vector=False
):
    values = _doubles(values)
    out = (D * required)()
    types, args = [P], [None]
    with _locked(*expressions):
        if vector:
            pointers = (P * len(expressions))(*(value._ptr for value in expressions))
            types.extend([C.POINTER(P), Z])
            args.extend([pointers, len(expressions)])
        else:
            types.append(P)
            args.append(expressions[0]._ptr)
        types.extend([C.POINTER(D), Z])
        args.extend([values, len(values)])
        if direction is not None:
            direction = _doubles(direction)
            types.extend([C.POINTER(D), Z])
            args.extend([direction, len(direction)])
        if scalar is not None:
            types.append(D)
            args.append(_real(scalar))
        types.extend([C.POINTER(D), Z])
        args.extend([out, required])
        _check(_api(name, *types)(*args))
    return list(out)


def evaluate_graph(graph, values):
    if not isinstance(graph, CompiledGraph):
        raise TypeError("expected CompiledGraph")
    return _run("evaluate_graph", [graph], values, 1)[0]


def value_and_gradient(function, values):
    values = tuple(values)
    out = _run(
        "value_and_gradient", _build(function, len(values)), values, len(values) + 1
    )
    return out[0], out[1:]


def gradient(function, values):
    values = tuple(values)
    return _run("gradient", _build(function, len(values)), values, len(values))


def hessian(function, values):
    values = tuple(values)
    n = len(values)
    out = _run("hessian", _build(function, n), values, n * n)
    return [out[row * n : (row + 1) * n] for row in range(n)]


def jacobian(function, values):
    values = tuple(values)
    n = len(values)
    expressions = _build(function, n, True)
    out = _run("jacobian", expressions, values, len(expressions) * n, vector=True)
    return [out[row * n : (row + 1) * n] for row in range(len(expressions))]


def jvp(function, values, direction):
    values = tuple(values)
    expressions = _build(function, len(values), True)
    return _run(
        "jvp", expressions, values, len(expressions), direction=direction, vector=True
    )


def vjp(function, values, direction):
    values = tuple(values)
    expressions = _build(function, len(values), True)
    return _run(
        "vjp", expressions, values, len(values), direction=direction, vector=True
    )


def hvp(function, values, direction):
    values = tuple(values)
    return _run(
        "hvp", _build(function, len(values)), values, len(values), direction=direction
    )


def gradient_check(step, function, values):
    values = tuple(values)
    return _run(
        "gradient_check", _build(function, len(values)), values, 1, scalar=step
    )[0]


def complex_gradient(function, value):
    return complex(
        *_run("complex_gradient", _build(function, 2), [value.real, value.imag], 2)
    )


def primal(value):
    return value.primal


def tangent(value):
    return value.tangent


def forward(function, value, *, dtype=None):
    seed = Dual(value, 1, dtype=dtype)
    result = function(seed)
    if not isinstance(result, Dual):
        result = seed._coerce(result)
    return primal(result), tangent(result)


def forward_jvp(function, values, direction):
    values, direction = tuple(values), tuple(direction)
    _run("forward_jvp_result", [], values, 0, direction=direction, vector=True)
    outputs = [
        value if isinstance(value, Dual) else Dual(value, 0)
        for value in function(
            [Dual(value, seed) for value, seed in zip(values, direction)]
        )
    ]
    result = _run(
        "forward_jvp_result",
        outputs,
        values,
        2 * len(outputs),
        direction=direction,
        vector=True,
    )
    return result[: len(outputs)], result[len(outputs) :]


def zero_gradients(count):
    return _new(GradientState, "zero_gradients", [I], [_int(count)])


def accumulate_gradients(state, values):
    values = _doubles(values)
    return _new(
        GradientState,
        "accumulate_gradients",
        [P, C.POINTER(D), Z],
        [state._ptr, values, len(values)],
        parents=[state],
    )


def reset_gradients(state):
    return _new(GradientState, "reset_gradients", [P], [state._ptr], parents=[state])


def gradient_hook(function, state):
    values = _doubles(function(state.accumulated_gradient))
    return _new(
        GradientState,
        "gradient_hook_result",
        [P, C.POINTER(D), Z],
        [state._ptr, values, len(values)],
        parents=[state],
    )


def clip_gradient(limit, values):
    values = _doubles(values)
    with _new(
        GradientState,
        "clip_gradient",
        [D, C.POINTER(D), Z],
        [_real(limit), values, len(values)],
    ) as result:
        return result.accumulated_gradient


def ad_tensor(shape, values):
    return ADTensor(shape, values)


def ad_values(tensor):
    return tensor.values


def ad_shape(tensor):
    return tensor.shape


def ad_broadcast(shape, tensor):
    shape = _indices(shape)
    return _new(
        ADTensor,
        "broadcast",
        [C.POINTER(I), Z, P],
        [shape, len(shape), tensor._ptr],
        parents=[tensor],
    )


def _tensor_binary(name, left, right):
    if not isinstance(left, ADTensor) or not isinstance(right, ADTensor):
        raise TypeError("expected ADTensor operands")
    return _new(ADTensor, name, [P, P], [left._ptr, right._ptr], parents=[left, right])


def ad_add(left, right):
    return _tensor_binary("tensor_add", left, right)


def ad_multiply(left, right):
    return _tensor_binary("tensor_multiply", left, right)


def ad_matmul(left, right):
    return _tensor_binary("matmul", left, right)


def ad_contract(left_axes, right_axes, left, right):
    left_axes, right_axes = _indices(left_axes), _indices(right_axes)
    return _new(
        ADTensor,
        "contract",
        [C.POINTER(I), Z, C.POINTER(I), Z, P, P],
        [left_axes, len(left_axes), right_axes, len(right_axes), left._ptr, right._ptr],
        parents=[left, right],
    )


def ad_sum(tensor):
    return _new(Expr, "sum", [P], [tensor._ptr], parents=[tensor])


def differentiable_step(rate, function, expressions):
    points = [_expression(value) for value in expressions]
    objective = _build(function, len(points))[0]
    with _locked(objective, *points):
        pointers = (P * len(points))(*(value._ptr for value in points))
        with _new(
            ADTensor,
            "differentiable_step",
            [D, P, C.POINTER(P), Z],
            [_real(rate), objective._ptr, pointers, len(points)],
            parents=[objective, *points],
        ) as result:
            return result.values


class _CallbackOwner:
    def __init__(self):
        self.callbacks = []
        self.buffers = []
        self.derived = {}
        self.results = []


def _callback_error(owner, error, message):
    _callback_errors.error = error
    try:
        encoded = str(error).encode("utf-8", "backslashreplace")
    except BaseException:  # noqa: BLE001 - even exception formatting stays inside C
        encoded = b"AD callback failed"
    owner.buffers.append(encoded)
    message[0] = encoded
    try:
        status = getattr(error, "status", 6)
        return status if isinstance(status, int) and 1 <= status <= 11 else 6
    except BaseException:  # noqa: BLE001 - contain arbitrary exception properties
        return 6


_RULE = C.CFUNCTYPE(
    C.c_int,
    C.POINTER(D),
    Z,
    P,
    C.POINTER(D),
    C.POINTER(D),
    Z,
    C.POINTER(Z),
    C.POINTER(C.c_char_p),
)
_UNARY = C.CFUNCTYPE(C.c_int, D, P, C.POINTER(D), C.POINTER(C.c_char_p))
_BUILDER = C.CFUNCTYPE(C.c_int, C.POINTER(P), Z, P, C.POINTER(P), C.POINTER(C.c_char_p))
_RULE_CHECKED = C.CFUNCTYPE(
    C.c_int,
    C.POINTER(D),
    Z,
    P,
    C.POINTER(D),
    C.POINTER(D),
    Z,
    C.POINTER(Z),
    C.POINTER(_ErrorWire),
)
_UNARY_CHECKED = C.CFUNCTYPE(C.c_int, D, P, C.POINTER(D), C.POINTER(_ErrorWire))
_BUILDER_CHECKED = C.CFUNCTYPE(
    C.c_int, C.POINTER(P), Z, P, C.POINTER(P), C.POINTER(_ErrorWire)
)


def _has_checked_callback(name):
    import hmath

    return hasattr(hmath._lib, "hmath_ad_" + name + "_checked")


def _checked_callback_error(owner, exception, error):
    buffers = []
    owner.buffers.append(buffers)
    try:
        status = _fill_callback_error(error, exception, buffers)
    except BaseException as invalid_payload:  # noqa: BLE001 - contain malformed payloads
        _callback_errors.error = invalid_payload
        return 6
    if status:
        return status
    _callback_errors.error = exception
    try:
        message = str(exception).encode("utf-8", "surrogatepass")
        buffer = C.create_string_buffer(message)
        buffers.append(buffer)
        error.contents.kind = 0
        error.contents.message = C.cast(buffer, P)
        error.contents.message_length = len(message)
    except BaseException:  # noqa: BLE001 - even formatting/allocation stays inside C
        error.contents.kind = 0
        error.contents.message = None
        error.contents.message_length = 0
    return 6


def custom_operation(function, expressions):
    expressions = [_expression(value) for value in expressions]
    owner = _CallbackOwner()
    reference = weakref.proxy(owner)
    checked = _has_checked_callback("custom_operation")
    callback_type = _RULE_CHECKED if checked else _RULE

    @callback_type
    def callback(values, count, userdata, out, partials, capacity, written, error):
        try:
            value, derivatives = function([values[index] for index in range(count)])
            derivatives = tuple(derivatives)
            out[0] = _real(value)
            written[0] = len(derivatives)
            for index in range(min(capacity, len(derivatives))):
                partials[index] = _real(derivatives[index])
            return 0
        except BaseException as exception:  # noqa: BLE001 - C callback exception boundary
            return (_checked_callback_error if checked else _callback_error)(
                reference, exception, error
            )

    owner.callbacks.append(callback)
    with _locked(*expressions):
        pointers = (P * len(expressions))(*(value._ptr for value in expressions))
        return _new(
            Expr,
            "custom_operation_checked" if checked else "custom_operation",
            [callback_type, P, C.POINTER(P), Z],
            [callback, None, pointers, len(expressions)],
            parents=expressions,
            keepers=[owner],
        )


def custom_unary(function, derivative, expression):
    expression = _expression(expression)
    owner = _CallbackOwner()
    reference = weakref.proxy(owner)
    checked = _has_checked_callback("custom_unary")
    callback_type = _UNARY_CHECKED if checked else _UNARY

    def wrap(function):
        @callback_type
        def callback(value, userdata, out, error):
            try:
                out[0] = _real(function(value))
                return 0
            except BaseException as exception:  # noqa: BLE001 - C callback exception boundary
                return (_checked_callback_error if checked else _callback_error)(
                    reference, exception, error
                )

        owner.callbacks.append(callback)
        return callback

    value_callback, derivative_callback = wrap(function), wrap(derivative)
    return _new(
        Expr,
        "custom_unary_checked" if checked else "custom_unary",
        [callback_type, callback_type, P, P],
        [value_callback, derivative_callback, None, expression._ptr],
        parents=[expression],
        keepers=[owner],
    )


def checkpoint(function, expressions):
    expressions = [_expression(value) for value in expressions]
    owner = _CallbackOwner()
    reference = weakref.proxy(owner)
    input_keepers = _owners(*expressions)
    checked = _has_checked_callback("checkpoint")
    callback_type = _BUILDER_CHECKED if checked else _BUILDER

    @callback_type
    def callback(pointers, count, userdata, out, error):
        inputs = []
        try:
            for index in range(count):
                pointer = P(pointers[index])
                _api("retain", P, result=None)(pointer)
                inputs.append(Expr._adopt(pointer, input_keepers))
            result = _expression(function(inputs))
            reference.results.append(result)
            for keeper in result._keepers:
                reference.derived[id(keeper)] = keeper
            with _locked(result):
                _api("retain", P, result=None)(result._ptr)
                out[0] = result._ptr
            return 0
        except BaseException as exception:  # noqa: BLE001 - C callback exception boundary
            for value in inputs:
                value.close()
            return (_checked_callback_error if checked else _callback_error)(
                reference, exception, error
            )

    owner.callbacks.append(callback)
    with _locked(*expressions):
        pointers = (P * len(expressions))(*(value._ptr for value in expressions))
        return _new(
            Expr,
            "checkpoint_checked" if checked else "checkpoint",
            [callback_type, P, C.POINTER(P), Z],
            [callback, None, pointers, len(expressions)],
            parents=expressions,
            keepers=[owner],
        )


def negate(value):
    return value._unary(0)


def absolute(value):
    return value._unary(1)


def sign(value):
    return value._unary(2)


def reciprocal(value):
    return value._unary(3)


def exp(value):
    return value._unary(4)


def log(value):
    return value._unary(5)


def sqrt(value):
    return value._unary(6)


def sin(value):
    return value._unary(7)


def cos(value):
    return value._unary(8)


def tan(value):
    return value._unary(9)


def asin(value):
    return value._unary(10)


def acos(value):
    return value._unary(11)


def atan(value):
    return value._unary(12)


def sinh(value):
    return value._unary(13)


def cosh(value):
    return value._unary(14)


def tanh(value):
    return value._unary(15)


def asinh(value):
    return value._unary(16)


def acosh(value):
    return value._unary(17)


def atanh(value):
    return value._unary(18)


def detach(value):
    return value._unary(19)


def stop_gradient(value):
    return value._unary(20)


# Register exact shared-Value interoperability after all legacy owner classes.
from . import _autodiff_value as _value_interop  # noqa: F401
