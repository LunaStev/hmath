# SPDX-License-Identifier: MPL-2.0
"""Lossless original MathError values and C callback transport."""

import ctypes as C
import json
from enum import IntEnum

from ._numeric import _int


class MathErrorKind(IntEnum):
    NEGATIVE_DIMENSIONS = 1
    ELEMENT_COUNT_OVERFLOW = 2
    ELEMENT_COUNT_MISMATCH = 3
    SHAPE_MISMATCH = 4
    INNER_DIMENSION_MISMATCH = 5
    INDEX_OUT_OF_BOUNDS = 6
    SLICE_OUT_OF_BOUNDS = 7
    VECTOR_LENGTH_MISMATCH = 8
    NON_SQUARE_MATRIX = 9
    INVALID_TOLERANCE = 10
    SINGULAR_MATRIX = 11
    NEAR_SINGULAR_MATRIX = 12
    NON_FINITE_MATRIX_ENTRY = 13
    NON_FINITE_VECTOR_ENTRY = 14
    NON_FINITE_RESULT = 15
    RIGHT_HAND_SIDE_MISMATCH = 16
    DOMAIN_ERROR = 17
    INVALID_ARGUMENT = 18
    NON_CONVERGENCE = 19
    RANK_DEFICIENT = 20
    NOT_POSITIVE_DEFINITE = 21


_ARITY = (0, 2, 2, 2, 4, 2, 4, 6, 2, 2, 0, 1, 1, 2, 1, 0, 2, 0, 0, 1, 1, 1)
_NAMES = (
    "",
    "NegativeDimensions",
    "ElementCountOverflow",
    "ElementCountMismatch",
    "ShapeMismatch",
    "InnerDimensionMismatch",
    "IndexOutOfBounds",
    "SliceOutOfBounds",
    "VectorLengthMismatch",
    "NonSquareMatrix",
    "InvalidTolerance",
    "SingularMatrix",
    "NearSingularMatrix",
    "NonFiniteMatrixEntry",
    "NonFiniteVectorEntry",
    "NonFiniteResult",
    "RightHandSideMismatch",
    "DomainError",
    "InvalidArgument",
    "NonConvergence",
    "RankDeficient",
    "NotPositiveDefinite",
)


class MathError(Exception):
    """A source MathError constructor, integer fields and full string payload.

    Raise this from checked Python callbacks to return a Haskell Left value.
    The solver may recover from that Left according to its original algorithm.
    Unexpected Python exceptions instead abort and rethrow after native cleanup.
    """

    status = 11

    def __init__(self, kind, details=(), message=""):
        self.kind = MathErrorKind(kind)
        self.details = tuple(_int(value) for value in details)
        self.message = str(message)
        if len(self.details) != _ARITY[self.kind]:
            raise ValueError(
                f"{self.kind.name} needs {_ARITY[self.kind]} integer fields"
            )
        super().__init__(self.kind, self.details, self.message)

    def __str__(self):
        name = _NAMES[self.kind]
        if self.kind in (1, 2, 9, 13):
            return f"{name} ({self.details[0]},{self.details[1]})"
        if self.kind in (4, 6, 7):
            pairs = " ".join(
                f"({self.details[i]},{self.details[i + 1]})"
                for i in range(0, len(self.details), 2)
            )
            return name + " " + pairs
        if self.kind in (17, 18, 19):
            payload = json.dumps(self.message, ensure_ascii=False)
            return (
                name
                + " "
                + payload
                + (f" {self.details[0]}" if self.kind == 19 else "")
            )
        return name + ((" " + " ".join(map(str, self.details))) if self.details else "")


class Wire(C.Structure):
    _fields_ = [
        ("kind", C.c_uint32),
        ("details", C.c_ssize_t * 6),
        ("message", C.c_void_p),
        ("message_length", C.c_size_t),
    ]


def decode(wire):
    kind = MathErrorKind(wire.kind)
    payload = (
        C.string_at(wire.message, wire.message_length).decode("utf-8", "surrogatepass")
        if wire.message_length
        else ""
    )
    return MathError(kind, wire.details[: _ARITY[kind]], payload)


def fill(pointer, error, owners):
    """Copy payload into a caller-owned callback buffer set, including NUL."""
    if not isinstance(error, MathError):
        error = getattr(error, "math_error", None)
    if not isinstance(error, MathError):
        return False
    # Public exceptions can be subclassed or have attributes replaced after
    # construction. Validate again before ctypes can narrow integer fields.
    kind = MathErrorKind(error.kind)
    details = tuple(_int(value) for value in error.details)
    if len(details) != _ARITY[kind]:
        raise ValueError(f"{kind.name} needs {_ARITY[kind]} integer fields")
    pointer.contents.kind = kind
    for index in range(6):
        pointer.contents.details[index] = details[index] if index < len(details) else 0
    payload = error.message.encode("utf-8", "surrogatepass")
    buffer = C.create_string_buffer(payload)
    owners.append(buffer)
    pointer.contents.message = C.cast(buffer, C.c_void_p)
    pointer.contents.message_length = len(payload)
    return True


def last_math_error(library):
    """Query without changing native status; older ABI1 libraries return None."""
    try:
        getter = C.CFUNCTYPE(C.c_int, C.POINTER(Wire))(
            ("hmath_last_math_error", library)
        )
    except AttributeError:
        return None
    wire = Wire()
    return decode(wire) if getter(C.byref(wire)) else None
