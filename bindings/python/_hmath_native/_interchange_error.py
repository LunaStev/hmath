# SPDX-License-Identifier: MPL-2.0
"""The four original interchange errors, with lossless message payloads."""

import ctypes as C
from dataclasses import dataclass
from enum import IntEnum


class InterchangeErrorKind(IntEnum):
    INVALID_DATA = 0
    UNSUPPORTED = 1
    LIMIT_EXCEEDED = 2
    IO_ERROR = 3


@dataclass(frozen=True)
class InterchangeError(Exception):
    kind: InterchangeErrorKind
    message: str

    def __str__(self):
        return self.kind.name + ": " + self.message


class Wire(C.Structure):
    _fields_ = [
        ("kind", C.c_uint32),
        ("message", C.c_void_p),
        ("message_length", C.c_size_t),
    ]


def last_interchange_error(library):
    try:
        getter = C.CFUNCTYPE(C.c_int, C.POINTER(Wire))(
            ("hmath_last_interchange_error", library)
        )
    except AttributeError:
        return None
    wire = Wire()
    if not getter(C.byref(wire)):
        return None
    message = C.string_at(wire.message, wire.message_length).decode(
        "utf-8", "surrogatepass"
    )
    return InterchangeError(InterchangeErrorKind(wire.kind), message)


def fill(pointer, error, owners):
    if not isinstance(error, InterchangeError):
        error = getattr(error, "interchange_error", None)
    if not isinstance(error, InterchangeError):
        return False
    pointer.contents.kind = error.kind
    encoded = error.message.encode("utf-8", "surrogatepass")
    buffer = C.create_string_buffer(encoded)
    owners.append(buffer)
    pointer.contents.message = C.cast(buffer, C.c_void_p)
    pointer.contents.message_length = len(encoded)
    return True
