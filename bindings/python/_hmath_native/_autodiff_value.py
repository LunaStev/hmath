# SPDX-License-Identifier: MPL-2.0
"""Lossless ownership bridge for the original Autodiff, separate from Numeric.Dual."""

import ctypes as C

from . import _value as v
from . import autodiff as ad


def import_value(value):
    import hmath

    if not isinstance(value, (ad.Expr, ad.ADTensor, ad.Dual)):
        raise TypeError("expected original Autodiff Expr, ADTensor or Dual")
    result = v.Value._adopt()
    hmath.initialize()
    with ad._locked(value):
        result._owners = tuple(value._keepers)
        ad._check(
            v.api(
                "hmath_ad_value_import",
                C.c_int,
                C.c_void_p,
                C.c_void_p,
                C.POINTER(C.c_void_p),
            )(None, value._ptr, C.byref(result._ptr))
        )
    return result


def export_value(value, owner=None):
    import hmath

    if not isinstance(value, v.Value):
        value = v.encode(value)
    else:
        value = value.clone()
    try:
        with value._lock:
            if owner is None:
                kind = value.info[0]
                owner = {287: ad.Expr, 288: ad.ADTensor}.get(kind, ad.Dual)
            result = owner._adopt(C.c_void_p(), keepers=value._owners)
            hmath.initialize()
            ad._check(
                v.api(
                    "hmath_ad_value_export",
                    C.c_int,
                    C.c_void_p,
                    C.c_void_p,
                    C.POINTER(C.c_void_p),
                )(None, value._ptr, C.byref(result._ptr))
            )
            return result
    finally:
        value.close()


def _decode(value, owner):
    try:
        return export_value(value, owner)
    finally:
        value.close()


v.register(287, lambda value: _decode(value, ad.Expr))
v.register(288, lambda value: _decode(value, ad.ADTensor))
v.register(289, lambda value: _decode(value, ad.Dual))
v.register_encoder(ad.Expr, import_value)
v.register_encoder(ad.ADTensor, import_value)
v.register_encoder(ad.Dual, import_value)
