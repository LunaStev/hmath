# SPDX-License-Identifier: MPL-2.0
"""Lossless value transport and independent native/callback-owner lifetimes."""

import ctypes as C
import math
import sys
import weakref
from fractions import Fraction
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "bindings/python"))
import hmath
from _hmath_native import _value as v

values = [
    None,
    False,
    True,
    0,
    -17,
    10**6000,
    Fraction(10**5000 + 1, 7),
    1.25,
    -0.0,
    float("inf"),
    complex(1, -2),
    "A\0🙂\ud800",
]
for original in values:
    result = v.decode(v.encode(original))
    assert result == original, (type(original), type(result))
assert math.copysign(1, v.decode(v.encode(-0.0))) == -1
assert math.isnan(v.decode(v.encode(float("nan"))))
assert v.decode(v.encode(([1, 2], (None, "x\0y"), Fraction(7, 11)))) == (
    [1, 2],
    (None, "x\0y"),
    Fraction(7, 11),
)
for dtype, number in [
    ("float32", 16777217),
    ("float64", 16777217),
    ("complex64", complex(16777217, 1)),
    ("complex128", complex(16777217, 1)),
    ("int8", -128),
    ("uint8", 255),
    ("uint64", 2**64 - 1),
]:
    value = v.scalar(number, dtype)
    assert value.dtype == dtype
    decoded = v.decode(value)
    if dtype == "float32":
        assert decoded == 16777216
    elif dtype == "complex64":
        assert decoded == complex(16777216, 1)
    else:
        assert decoded == number
for dtype, number in [("int8", 128), ("uint8", -1), ("uint64", 2**64)]:
    try:
        v.scalar(number, dtype)
    except hmath.HMathError as error:
        assert error.status == 3
    else:
        raise AssertionError("bounded scalar silently wrapped")


class Owner:
    pass


owner = Owner()
reference = weakref.ref(owner)
source = v.encode(3)
source._owners = (owner,)
container = v.encode([source])
source.close()
del owner
assert reference() is not None
child = container.item(0)
container.close()
assert reference() is not None
assert v.decode(child) == 3
assert reference() is None
value = v.encode(1)
clone = value.clone()
value.close()
assert v.decode(clone) == 1
with v.encode("A\0🙂\ud800") as text:
    assert text.info == (10, -1, 4)
    buffer = (C.c_uint32 * 5)(99, 99, 99, 99, 99)
    function = v.api(
        "hmath_value_get_text", C.c_int, C.c_void_p, C.POINTER(C.c_uint32), C.c_size_t
    )
    assert function(text._ptr, buffer, 3) == 8 and list(buffer) == [99] * 5
    assert function(text._ptr, buffer, 4) == 0 and list(buffer) == [
        65,
        0,
        0x1F642,
        0xD800,
        99,
    ]
with v.encode([1, 2]) as sequence:
    try:
        sequence.item(-1)
    except hmath.HMathError as error:
        assert error.status == 8
    else:
        raise AssertionError("negative list index accepted")
with v.encode(1.0) as scalar:
    number = C.c_ssize_t(99)
    function = v.api(
        "hmath_value_get_index", C.c_int, C.c_void_p, C.POINTER(C.c_ssize_t)
    )
    assert function(scalar._ptr, C.byref(number)) == 1 and number.value == 99
    assert scalar.info == (1, 0, 0)
    assert (
        hmath._lib.hmath_last_error_code() == 1
    )  # metadata query preserves error state
    try:
        hmath.shutdown()
    except hmath.HMathError as error:
        assert error.status == 9
    else:
        raise AssertionError("runtime shut down with an owned Value")
hmath.shutdown()
print(
    "Value exact integers/rationals, primitive dtype, Unicode/NUL/surrogates, bounded checks, containers, owner snapshots, queries and runtime pinning passed."
)
