# SPDX-License-Identifier: MPL-2.0
"""Status-selected structured error payloads for the shared callback wire."""

import ctypes as C

from ._expression_error import ErrorKind, ExprError
from ._interchange_error import fill as fill_interchange
from ._math_error import fill as fill_math
from ._numeric import _int


def fill(pointer, error, owners):
    """Return11/12/13 for a domain error, or0 for an ordinary Python exception."""
    if fill_math(pointer, error, owners):
        return 11
    expression = (
        error
        if isinstance(error, ExprError)
        else getattr(error, "expression_error", None)
    )
    if isinstance(expression, ExprError):
        pointer.contents.kind = ErrorKind(expression.kind)
        fields = (
            expression.position.offset,
            expression.position.line,
            expression.position.column,
        )
        for index in range(6):
            pointer.contents.details[index] = _int(fields[index]) if index < 3 else 0
        data = expression.message.encode("utf-8", "surrogatepass")
        buffer = C.create_string_buffer(data)
        owners.append(buffer)
        pointer.contents.message = C.cast(buffer, C.c_void_p)
        pointer.contents.message_length = len(data)
        return 12
    if fill_interchange(pointer, error, owners):
        return 13
    return 0
