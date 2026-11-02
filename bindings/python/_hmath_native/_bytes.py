# SPDX-License-Identifier: MPL-2.0
"""Immutable native bytes, with owned copies and read-only borrowed views."""

import ctypes as C

from . import _value as value


class Bytes(value.Value):
    def __new__(cls, source):
        import hmath

        data = bytes(source)
        result = cls._adopt()
        hmath.initialize()
        hmath._check(
            value.api(
                "hmath_bytes_copy",
                C.c_int,
                C.c_void_p,
                C.c_void_p,
                C.c_size_t,
                C.POINTER(C.c_void_p),
            )(None, C.c_char_p(data), len(data), C.byref(result._ptr))
        )
        return result

    def _span(self):
        import hmath

        pointer, count = C.c_void_p(), C.c_size_t()
        if not self._ptr:
            raise ValueError("bytes are closed")
        hmath._check(
            value.api(
                "hmath_bytes_data",
                C.c_int,
                C.c_void_p,
                C.POINTER(C.c_void_p),
                C.POINTER(C.c_size_t),
            )(self._ptr, C.byref(pointer), C.byref(count))
        )
        return pointer.value or 0, count.value

    def __bytes__(self):
        with self._lock:
            pointer, count = self._span()
            return C.string_at(pointer, count)

    def view(self):
        """Return a read-only byte view retaining an independent native owner."""
        with self._lock:
            owner = self.clone()
            try:
                pointer, count = self._span()
                raw = (C.c_ubyte * count).from_address(pointer)
                raw._hmath_owner = owner
                return memoryview(raw).cast("B").toreadonly()
            except BaseException:
                owner.close()
                raise

    def __len__(self):
        return self.info[2]


value.register(450, Bytes)
value.register_encoder(bytes, Bytes)
value.register_encoder(bytearray, Bytes)
