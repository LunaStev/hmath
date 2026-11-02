# SPDX-License-Identifier: MPL-2.0
"""Concrete standard numeric instances for polymorphic Haskell adapters.

This is a binding/type description, not an implementation of numeric operations.
The source function remains the unit of coverage; its type instances are tracked
individually. Open Haskell classes can have user-defined instances beyond this
finite set, so no entry is labelled universally type-complete.
"""

from copy import deepcopy

BOUNDED = {
    "int8": ("int8_t", "Int8", 8, True, "_i8"),
    "int16": ("int16_t", "Int16", 16, True, "_i16"),
    "int32": ("int32_t", "Int32", 32, True, "_i32"),
    "int64": ("int64_t", "Int64", 64, True, "_i64"),
    "uint8": ("uint8_t", "Word8", 8, False, "_u8"),
    "uint16": ("uint16_t", "Word16", 16, False, "_u16"),
    "uint32": ("uint32_t", "Word32", 32, False, "_u32"),
    "uint64": ("uint64_t", "Word64", 64, False, "_u64"),
    "intp": ("ptrdiff_t", "Int", None, True, "_int"),
    "uintp": ("size_t", "Word", None, False, "_word"),
}
INTEGRAL = ["integer", *BOUNDED]
REAL = ["float32", "float64", "rational", *INTEGRAL]
COMPLEX = ["complex64", "complex128"]
NUM = [*REAL, *COMPLEX]
FRACTIONAL = ["float32", "float64", "rational", *COMPLEX]
FLOATING = ["float32", "float64", *COMPLEX]


def generic_types(module, name):
    """Only instances permitted by the original function's constraints."""
    if module == "HMath.Basic":
        return {"clamp": REAL, "lerp": FRACTIONAL}.get(name)
    if module == "HMath.Scalar":
        if name in {
            "add",
            "subtractScalar",
            "multiply",
            "absolute",
            "sign",
            "cumulativeSum",
            "prefixSum",
            "cumulativeProduct",
        }:
            return NUM
        if name in {"minimumScalar", "maximumScalar"}:
            return REAL
        if name == "positiveModulo":
            return INTEGRAL
        if name in {
            "saturatingAdd",
            "saturatingSubtract",
            "saturatingMultiply",
            "checkedAdd",
            "checkedSubtract",
            "checkedMultiply",
        }:
            return list(BOUNDED)
    if module == "HMath.Linear":
        return FLOATING if name in {"magnitude", "normalize"} else NUM
    if module == "HMath.Statistics":
        return {
            "mean": FRACTIONAL,
            "variance": FRACTIONAL,
            "standardDeviation": FLOATING,
            "median": ["float32", "float64", "rational"],
        }.get(name)
    return None


def dtype_wire(dtype):
    if dtype in ("float32", "float64"):
        return "f", "fs", "f", "fd", int(dtype[-2:]), "_f" + dtype[-2:]
    if dtype == "integer":
        return "z", "zs", "z", "zd", None, "_integer"
    if dtype == "rational":
        return "q", "qs", "q", "qd", None, "_rational"
    if dtype in COMPLEX:
        bits = 32 if dtype == "complex64" else 64
        return "c", "cs", "c", "cd", bits, "_c" + dtype[-2:] if bits == 32 else "_c128"
    if dtype in BOUNDED:
        return dtype, dtype + "s", dtype, dtype + "d", None, BOUNDED[dtype][4]
    raise ValueError(dtype)


def binding_variants(entry):
    """Return explicit wire instances while retaining one source symbol."""
    types = entry.get("specializations")
    if not types:
        # Legacy entries remain byte-for-byte compatible with existing ABI.
        floating = any(
            a["type"] in ("f", "fs", "p", "c") for a in entry["args"]
        ) or entry["result"] in (
            "f",
            "ff",
            "fff",
            "ffff",
            "c",
            "fs",
            "fd",
            "zf",
            "sf",
            "sf2",
            "sf4",
            "fsf",
        )
        return [
            {
                "dtype": f"float{bits}" if bits else None,
                "precision": bits,
                "suffix": f"_f{bits}" if bits else "",
                "args": entry["args"],
                "result": entry["result"],
                "legacy": True,
            }
            for bits in entry.get("precisions", [32, 64] if floating else [None])
        ]
    variants = []
    generic_arguments = entry.get("generic_arguments", [True] * len(entry["args"]))
    for dtype in types:
        scalar_in, list_in, scalar_out, list_out, precision, suffix = dtype_wire(dtype)
        args = deepcopy(entry["args"])
        for generic, argument in zip(generic_arguments, args):
            if generic:
                argument["type"] = (
                    list_in if argument["type"] in ("fs", "zs") else scalar_in
                )
        result = entry["result"]
        if entry.get("generic_result", True):
            result = list_out if result in ("fs", "fd", "zd") else scalar_out
        # Existing Float buffer-output entry points retain their public form.
        if dtype in ("float32", "float64"):
            result = entry["result"]
        variants.append(
            {
                "dtype": dtype,
                "precision": precision,
                "suffix": suffix,
                "args": args,
                "result": result,
                "legacy": False,
            }
        )
    for legacy in entry.get("legacy_variants", []):
        variant = next(v for v in variants if v["dtype"] == legacy["dtype"])
        variants.append(dict(variant, suffix=legacy["suffix"], legacy=True))
    return variants
