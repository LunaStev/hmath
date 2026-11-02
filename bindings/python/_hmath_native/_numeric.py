# SPDX-License-Identifier: MPL-2.0
"""Marshaling shared by generated bindings; no numerical algorithms live here."""

import ctypes as C
import operator
from fractions import Fraction
from typing import NamedTuple


class SFResult(NamedTuple):
    """Original special-function value and estimated absolute error."""

    sf_value: float
    sf_error: float


_BOUNDED = {
    "int8": C.c_int8,
    "int16": C.c_int16,
    "int32": C.c_int32,
    "int64": C.c_int64,
    "uint8": C.c_uint8,
    "uint16": C.c_uint16,
    "uint32": C.c_uint32,
    "uint64": C.c_uint64,
    "intp": C.c_ssize_t,
    "uintp": C.c_size_t,
}


def _bounded(value, kind):
    value = operator.index(value)
    bits = C.sizeof(_BOUNDED[kind]) * 8
    lower = 0 if kind.startswith("uint") else -(1 << (bits - 1))
    upper = (1 << bits) - 1 if kind.startswith("uint") else (1 << (bits - 1)) - 1
    if not lower <= value <= upper:
        raise OverflowError(f"argument is outside the Haskell {kind} range")
    return value


def _decimal(value):
    """Transport arbitrary Python integers without Python's decimal digit cap."""
    value = operator.index(value)
    negative = value < 0
    value = abs(value)
    chunks = []
    while value:
        value, digit = divmod(value, 10**9)
        chunks.append(digit)
    digits = str(chunks.pop()) if chunks else "0"
    digits += "".join(f"{digit:09d}" for digit in reversed(chunks))
    return ("-" + digits if negative else digits).encode("ascii")


def _integer(data):
    negative = data.startswith(b"-")
    if negative:
        data = data[1:]
    value = 0
    for start in range(0, len(data), 9):
        chunk = data[start : start + 9]
        value = value * 10 ** len(chunk) + int(chunk)
    return -value if negative else value


def _int(value):
    value = operator.index(value)
    bits = C.sizeof(C.c_ssize_t) * 8
    if not -(1 << (bits - 1)) <= value < (1 << (bits - 1)):
        raise OverflowError("argument does not fit the Haskell Int type")
    return value


def _call(
    symbol, kinds, result, arguments, dtype, result_extra=0, *, symbol_suffix=None
):
    # Lazy import avoids a cycle with the existing hmath module.
    import hmath

    if dtype not in ("float32", "float64", None):
        raise ValueError("dtype must be 'float32' or 'float64'")
    real = C.c_float if dtype == "float32" else C.c_double
    suffix = "_f32" if dtype == "float32" else "_f64" if dtype else ""
    if symbol_suffix is not None:
        suffix = symbol_suffix
    hmath.initialize()
    types, values = [C.c_void_p], [None]
    count = 0
    for kind, argument in zip(kinds, arguments):
        if kind in _BOUNDED:
            types.append(_BOUNDED[kind])
            values.append(_bounded(argument, kind))
        elif kind.endswith("s") and kind[:-1] in _BOUNDED:
            sequence = tuple(argument)
            element = _BOUNDED[kind[:-1]]
            types.extend([C.POINTER(element), C.c_size_t])
            values.extend(
                [
                    (element * len(sequence))(
                        *(_bounded(v, kind[:-1]) for v in sequence)
                    ),
                    len(sequence),
                ]
            )
        elif kind in ("qs", "cs"):
            if kind == "qs":
                sequence = tuple(Fraction(v) for v in argument)
                flattened = [
                    component
                    for v in sequence
                    for component in (_decimal(v.numerator), _decimal(v.denominator))
                ]
                element = C.c_char_p
            else:
                sequence = tuple(complex(v) for v in argument)
                flattened = [
                    component for v in sequence for component in (v.real, v.imag)
                ]
                element = real
            types.extend([C.POINTER(element), C.c_size_t])
            values.extend([(element * len(flattened))(*flattened), len(sequence)])
        elif kind == "f":
            types.append(real)
            values.append(argument)
        elif kind == "z":
            types.append(C.c_char_p)
            values.append(_decimal(argument))
        elif kind == "i":
            types.append(C.c_ssize_t)
            values.append(_int(argument))
        elif kind == "b":
            if not isinstance(argument, bool):
                raise TypeError("expected a Boolean")
            types.append(C.c_int)
            values.append(argument)
        elif kind == "q":
            rational = Fraction(argument)
            types.extend([C.c_char_p, C.c_char_p])
            values.extend(
                [_decimal(rational.numerator), _decimal(rational.denominator)]
            )
        elif kind in ("p", "c"):
            pair = (argument.real, argument.imag) if kind == "c" else tuple(argument)
            if len(pair) != 2:
                raise ValueError("expected a pair")
            types.extend([real, real])
            values.extend(pair)
        elif kind == "fs":
            sequence = tuple(argument)
            count = len(sequence)
            types.extend([C.POINTER(real), C.c_size_t])
            values.extend([(real * count)(*sequence), count])
        elif kind in ("zs", "is"):
            sequence = tuple(argument)
            element = C.c_char_p if kind == "zs" else C.c_ssize_t
            conversion = _decimal if kind == "zs" else _int
            types.extend([C.POINTER(element), C.c_size_t])
            values.extend(
                [
                    (element * len(sequence))(*(conversion(v) for v in sequence)),
                    len(sequence),
                ]
            )
        else:
            raise RuntimeError(f"unknown argument kind: {kind}")
    if result in ("fd", "zd", "id", "qd", "cd") or (
        result.endswith("d") and result[:-1] in _BOUNDED
    ):
        element = {
            "fd": real,
            "cd": real,
            "zd": C.c_void_p,
            "id": C.c_ssize_t,
            "qd": C.c_void_p,
            **{name + "d": typ for name, typ in _BOUNDED.items()},
        }[result]
        pointer, length = C.POINTER(element)(), C.c_size_t()
        types.extend([C.POINTER(C.POINTER(element)), C.POINTER(C.c_size_t)])
        values.extend([C.byref(pointer), C.byref(length)])
        function = C.CFUNCTYPE(C.c_int, *types)((symbol + suffix, hmath._lib))
        free = C.CFUNCTYPE(None, C.c_void_p)(("hmath_numeric_buffer_free", hmath._lib))
        try:
            hmath._check(function(*values))
            if result in ("zd", "qd"):
                decoded = [
                    _integer(C.string_at(pointer[i]))
                    for i in range(length.value * (2 if result == "qd" else 1))
                ]
                return (
                    [
                        Fraction(decoded[i], decoded[i + 1])
                        for i in range(0, len(decoded), 2)
                    ]
                    if result == "qd"
                    else decoded
                )
            if result == "cd":
                return [
                    complex(pointer[i], pointer[i + 1])
                    for i in range(0, 2 * length.value, 2)
                ]
            return list(pointer[: length.value])
        finally:
            if pointer:
                if result in ("zd", "qd"):
                    for i in range(length.value * (2 if result == "qd" else 1)):
                        free(pointer[i])
                free(pointer)
    result_kinds = (
        [result]
        if result in _BOUNDED
        else {
            "f": "f",
            "ff": "ff",
            "fff": "fff",
            "ffff": "ffff",
            "sf": "ff",
            "sf2": "ffff",
            "sf4": "ffffffff",
            "fsf": "fff",
            "c": "ff",
            "b": "b",
            "z": "z",
            "zz": "zz",
            "zzz": "zzz",
            "zzzz": "zzzz",
            "i": "i",
            "q": "zz",
            "zf": "zf",
            "fs": "s",
        }[result]
    )
    outputs = []
    count += result_extra
    for kind in result_kinds:
        output = {
            "f": real,
            "b": C.c_int,
            "i": C.c_ssize_t,
            "z": C.c_void_p,
            "s": real * count,
            **_BOUNDED,
        }[kind]()
        outputs.append((kind, output))
        types.append(C.POINTER(real) if kind == "s" else C.POINTER(type(output)))
        values.append(output if kind == "s" else C.byref(output))
        if kind == "s":
            types.append(C.c_size_t)
            values.append(count)
    # Construct a private function object: concurrent callers do not mutate a
    # shared ctypes function's argtypes. CDLL/CFUNCTYPE release the GIL in C.
    function = C.CFUNCTYPE(C.c_int, *types)((symbol + suffix, hmath._lib))
    free = C.CFUNCTYPE(None, C.c_void_p)(("hmath_numeric_string_free", hmath._lib))
    try:
        hmath._check(function(*values))
        decoded = []
        for kind, output in outputs:
            if kind == "z":
                decoded.append(_integer(C.string_at(output)))
            elif kind == "s":
                decoded.append(list(output))
            else:
                decoded.append(bool(output.value) if kind == "b" else output.value)
    finally:
        for kind, output in outputs:
            if kind == "z":
                free(output)
    if result == "q":
        return Fraction(*decoded)
    if result == "c":
        return complex(*decoded)
    if result == "sf":
        return SFResult(*decoded)
    if result in ("sf2", "sf4"):
        return tuple(SFResult(*decoded[i : i + 2]) for i in range(0, len(decoded), 2))
    if result == "fsf":
        return decoded[0], SFResult(*decoded[1:])
    return decoded[0] if len(decoded) == 1 else tuple(decoded)
