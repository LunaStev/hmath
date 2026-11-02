# SPDX-License-Identifier: MPL-2.0
"""Owned typed representation and callbacks; algorithms stay in Haskell."""

import ctypes as C
import importlib
from fractions import Fraction

from . import _value as V
from ._callback_error import fill
from ._math_error import Wire

_REGISTRY = {}


def register(source_type, owner):
    if source_type in _REGISTRY and _REGISTRY[source_type] is not owner:
        raise ValueError("linear source type already registered")
    _REGISTRY[source_type] = owner


class LinearValue(V.Value):
    """Original immutable object. All derived outputs own independent references."""

    _source_type = None

    def __init__(self, *_args, **_kwargs):
        raise TypeError(
            "construct this abstract type through its original public functions"
        )

    def _initialize(self, symbol, generic, specs, args, dtype=None):
        value = _invoke(symbol, generic, specs, args, dtype=dtype)
        self._ptr, self._lock, self._owners = value._ptr, value._lock, value._owners
        value._ptr, value._owners = C.c_void_p(), ()

    @property
    def source_type(self):
        return self._source_type

    @property
    def parts(self):
        """Public constructor name and exact positional fields (abstract types reject)."""
        return V.decode(V.invoke("hmath_linear_object_parts", self))


def _decode(value):
    name = V.decode(V.invoke("hmath_linear_object_type", value))
    if name in ("HMath.Matrix.LU.LU", "HMath.Matrix.QR.QR"):
        import hmath

        from ._matrix_base import LU, QR

        owner = (LU if name.endswith(".LU") else QR)._adopt(
            "float64", "l" if name.endswith(".LU") else "q"
        )
        try:
            with value._lock:
                hmath._check(
                    V.api(
                        "hmath_linear_export_legacy",
                        C.c_int,
                        C.c_void_p,
                        C.c_void_p,
                        C.POINTER(C.c_void_p),
                    )(None, value._ptr, C.byref(owner._ptr))
                )
            return owner
        finally:
            value.close()
    owner = _REGISTRY.get(name)
    if owner is None:
        namespace = {
            "HMath.Vector": "vector",
            "HMath.Matrix.Advanced": "matrix_advanced",
            "HMath.Matrix.Decomposition": "decomposition",
            "HMath.Matrix.Iterative": "iterative",
            "HMath.Matrix.LAPACK": "lapack",
            "HMath.Sparse": "sparse",
            "HMath.Sparse.Spectral": "sparse_spectral",
            "HMath.Backend": "backend",
        }[name.rsplit(".", 1)[0]]
        importlib.import_module("." + namespace, __package__)
        owner = _REGISTRY.get(name)
    if owner is None:
        raise TypeError("unknown original linear object type")
    with value._lock:
        result = owner._adopt(value._ptr, value._owners)
        value._ptr, value._owners = C.c_void_p(), ()
        return result


V.register(100, _decode)


def _infer(arguments):
    from ._matrix_base import Matrix

    for value in arguments:
        if isinstance(value, V.Value):
            kind, dtype, _ = value.info
            if kind == 294 or (kind == 100 and dtype in (16, 17, 18)):
                return value
            if kind in (1, 9, 100) and dtype >= 0:
                if dtype in V.DTYPE_NAMES:
                    return V.DTYPE_NAMES[dtype]
                for owner in value._owners:
                    if isinstance(owner, V.Value) and owner.info[0] == 1:
                        return owner
        elif isinstance(value, Matrix):
            return value.dtype
        elif isinstance(value, (list, tuple)):
            result = _infer(value)
            if result is not None:
                return result
        elif isinstance(value, Fraction):
            return "rational"
        elif isinstance(value, complex):
            return "complex128"
    return None


def _prototype(dtype):
    if isinstance(dtype, str) and dtype in ("bool", "string"):
        return V.encode(False if dtype == "bool" else "")
    return (
        dtype.clone() if isinstance(dtype, V.Value) else V.scalar(0, dtype or "float64")
    )


def _scalar(value, dtype):
    if isinstance(value, V.Value):
        return value.clone()
    if isinstance(dtype, V.Value):
        if dtype.info[0] == 100 and dtype.info[1] in (16, 17):
            return V.encode(value)
        raise TypeError("structured coefficients require typed scalar Values")
    if dtype in ("bool", "string"):
        return V.encode(value)
    return V.scalar(value, dtype)


def _prepare(spec, value, dtype, owners, callbacks):
    head, *args = spec
    if head in ("a", "b", "c", "Double", "Float", "Integer", "Rational", "Complex"):
        target = {
            "Double": "float64",
            "Float": "float32",
            "Integer": "integer",
            "Rational": "rational",
        }.get(head, dtype)
        if head == "Complex":
            target = "complex64" if args[0] == ["Float"] else "complex128"
        result = _scalar(value, target)
        owners.append(result)
        return result
    if head == "list":
        return [_prepare(args[0], item, dtype, owners, callbacks) for item in value]
    if head == "tuple":
        value = tuple(value)
        if len(value) != len(args):
            raise ValueError("tuple arity differs from original signature")
        return tuple(
            _prepare(s, item, dtype, owners, callbacks) for s, item in zip(args, value)
        )
    if head == "Maybe":
        return (
            None
            if value is None
            else _prepare(args[0], value, dtype, owners, callbacks)
        )
    if head == "function":
        if isinstance(value, V.Value):
            callbacks.extend(_callback_states(value))
            return value
        result = _callback(value, args[-1], dtype)
        owners.append(result)
        callbacks.append(result)
        return result
    return value


_CALLBACK = C.CFUNCTYPE(
    C.c_int, C.c_void_p, C.c_void_p, C.POINTER(C.c_void_p), C.POINTER(Wire)
)


class _CallbackState:
    def __init__(self):
        self._callback_errors = []
        self.payload = []
        self.returned_owners = []


def _callback_states(value):
    """Find retained Python callback errors through native Value owner graphs."""
    result = []
    seen = set()

    def visit(item):
        if id(item) in seen:
            return
        seen.add(id(item))
        if isinstance(item, _CallbackState):
            result.append(item)
            for child in item.returned_owners:
                visit(child)
        elif isinstance(item, V.Value):
            for child in item._owners:
                visit(child)
        elif isinstance(item, (list, tuple)):
            for child in item:
                visit(child)

    visit(value)
    return result


def _callback_scope(callbacks):
    states = []
    seen = set()
    for callback in callbacks:
        candidates = (
            [callback]
            if isinstance(callback, _CallbackState)
            else _callback_states(callback)
        )
        for state in candidates:
            if id(state) not in seen:
                seen.add(id(state))
                states.append((state, len(state._callback_errors)))
    return states


def _take_callback_failure(scopes):
    first = None
    for state, before in scopes:
        if len(state._callback_errors) > before:
            if first is None:
                first = state._callback_errors[before]
            del state._callback_errors[before:]
    return first


def _callback(function, result_spec, dtype):
    import hmath

    if not callable(function):
        raise TypeError("expected a callable original function argument")
    state = _CallbackState()
    pending = state._callback_errors
    payload = state.payload

    @_CALLBACK
    def callback(pointer, _userdata, out, wire):
        argument = None
        owners = []
        try:
            argument = V.decode(V.borrow(pointer))
            result = (
                function(*argument)
                if isinstance(argument, tuple)
                else function(argument)
            )
            prepared = _prepare(result_spec, result, dtype, owners, [])
            encoded = V.encode(prepared)
            # Native StablePtr cloning does not retain newly-created Python
            # callbacks/userdata. Keep every returned dependency transitively.
            state.returned_owners.extend(
                owner
                for owner in encoded._owners
                if owner is not state and owner is not callback
            )
            out[0] = encoded._ptr
            encoded._ptr, encoded._owners = C.c_void_p(), ()
            return 0
        except BaseException as error:  # noqa: BLE001 - ctypes callbacks cannot propagate exceptions
            try:
                handled = fill(wire, error, payload)
            except BaseException:  # noqa: BLE001 - malformed payloads cannot escape ctypes
                handled = 0
            if handled:
                return handled
            pending.append(error)
            try:
                description = str(error)
            except BaseException:  # noqa: BLE001 - exception formatting must not escape ctypes
                description = type(error).__name__
            message = description.encode("utf-8", "surrogatepass")
            buffer = C.create_string_buffer(message)
            payload.append(buffer)
            wire.contents.message = C.cast(buffer, C.c_void_p)
            wire.contents.message_length = len(message)
            return 9
        finally:
            for owner in owners:
                owner.close()

    owner = V.Value._adopt(owners=(callback, state))
    hmath.initialize()
    hmath._check(
        V.api(
            "hmath_linear_callback",
            C.c_int,
            C.c_void_p,
            _CALLBACK,
            C.c_void_p,
            C.POINTER(C.c_void_p),
        )(None, callback, None, C.byref(owner._ptr))
    )
    owner._callback_errors = pending
    return owner


def _invoke(symbol, generic, specs, arguments, dtype=None):
    owners = []
    callbacks = []
    try:
        dtype = dtype if dtype is not None else _infer(arguments) or "float64"
        prepared = [
            _prepare(spec, value, dtype, owners, callbacks)
            for spec, value in zip(specs, arguments)
        ]
        if generic:
            if symbol == "hmath_linear_matrix_advanced_zip_matrix_with":
                left = _prototype(_infer([arguments[1]]) or dtype)
                right = _prototype(_infer([arguments[2]]) or dtype)
                output = _prototype(dtype)
                owners.extend([left, right, output])
                prototype = (left, right, output)
            else:
                if symbol in (
                    "hmath_linear_matrix_advanced_hermitian_matrix",
                    "hmath_linear_matrix_advanced_conjugate_transpose",
                ):
                    dtype = {"complex64": "float32", "complex128": "float64"}.get(
                        dtype, dtype
                    )
                prototype = _prototype(dtype)
                owners.append(prototype)
            prepared.insert(0, prototype)
        snapshots = []
        if generic:
            source = prototype[-1] if isinstance(prototype, tuple) else prototype
            snapshots = [source.clone()]
        scopes = _callback_scope(callbacks)
        try:
            result = V.invoke(symbol, *prepared, owners=snapshots)
        except BaseException:
            failure = _take_callback_failure(scopes)
            if failure is not None:
                raise failure
            raise
        return V.decode(result)
    finally:
        for owner in owners:
            owner.close()
