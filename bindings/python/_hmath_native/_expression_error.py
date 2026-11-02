# SPDX-License-Identifier: MPL-2.0
"""Lossless original positioned ExprError values and domain-error query."""

import ctypes as C
from dataclasses import dataclass
from enum import IntEnum


class ErrorKind(IntEnum):
    SYNTAX_ERROR = 0
    UNKNOWN_NAME = 1
    TYPE_MISMATCH = 2
    DOMAIN_FAILURE = 3
    NON_FINITE = 4
    STEP_LIMIT = 5
    DEPTH_LIMIT = 6
    MEMORY_LIMIT = 7
    INVALID_LIMITS = 8
    UNSUPPORTED = 9


@dataclass(frozen=True, order=True)
class SourcePos:
    offset: int = 0
    line: int = 0
    column: int = 0


@dataclass(frozen=True)
class ExprError(Exception):
    kind: ErrorKind
    position: SourcePos
    message: str

    def __str__(self):
        return f"{self.kind.name} at {self.position.line}:{self.position.column}: {self.message}"


class Wire(C.Structure):
    _fields_ = [
        ("kind", C.c_uint32),
        ("offset", C.c_ssize_t),
        ("line", C.c_ssize_t),
        ("column", C.c_ssize_t),
        ("message", C.c_void_p),
        ("message_length", C.c_size_t),
    ]


def last_expression_error(library):
    try:
        getter = C.CFUNCTYPE(C.c_int, C.POINTER(Wire))(
            ("hmath_last_expression_error", library)
        )
    except AttributeError:
        return None
    wire = Wire()
    if not getter(C.byref(wire)):
        return None
    message = (
        C.string_at(wire.message, wire.message_length).decode("utf-8", "surrogatepass")
        if wire.message_length
        else ""
    )
    return ExprError(
        ErrorKind(wire.kind), SourcePos(wire.offset, wire.line, wire.column), message
    )
