# SPDX-License-Identifier: MPL-2.0
"""Generate typed opaque adapters for existing Numeric and Constants APIs."""

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SPECS = []


def spec(name, args, expression, checked=False, symbol=None, module="Numeric"):
    SPECS.append(
        {
            "name": name,
            "args": [{"name": n, "type": t} for n, t in args],
            "expression": expression,
            "checked": checked,
            "symbol": symbol,
            "module": module,
        }
    )


def obj(name):
    return (name, "o")


def unary(name, subtype, expression, checked=False, symbol=None):
    spec(name, [("value", subtype)], expression, checked, symbol or name)


def binary(name, subtype, expression, checked=False):
    spec(name, [("a", subtype), ("b", subtype)], expression, checked, name)


spec("type_name", [obj("value")], "pure (Text (objectType value))")
spec("binary", [("operation", "i32"), obj("a"), obj("b")], "binary operation a b")
spec("unary", [("operation", "i32"), obj("value")], "unary operation value")
spec("literal_integer", [obj("like"), ("value", "z")], "literalInteger like value")
spec("literal_rational", [obj("like"), ("value", "q")], "literalRational like value")
spec("integer_power", [obj("value"), ("power", "z")], "integerPower value power")
spec("equal", [obj("a"), obj("b")], "pure (Boolean (a == b))")
spec("sequence_get", [obj("value"), ("index", "i")], "sequenceItem index value")
spec(
    "round_rational",
    [("mode", "mode"), ("value", "q")],
    "pure (ninteger (N.roundRational mode value))",
    symbol="roundRational",
)
unary("classify", "o", "classify value", symbol="classify")
unary("frexp", "o", "frexp value", symbol="frexp")
unary("numeric_limits", "o", "numericLimits value", symbol="numericLimits")
unary("integer_limits", "o", "integerLimits value", symbol="integerLimits")
spec(
    "float16_limits",
    [],
    "pure (limits SDouble N.float16Limits)",
    symbol="float16Limits",
)
spec(
    "bfloat16_limits",
    [],
    "pure (limits SDouble N.bfloat16Limits)",
    symbol="bfloat16Limits",
)
spec(
    "numeric_limits_record",
    [
        obj("normal"),
        obj("subnormal"),
        obj("maximum_value"),
        obj("epsilon"),
        ("digits", "i"),
        ("low", "i"),
        ("high", "i"),
    ],
    "makeLimits normal subnormal maximum_value epsilon digits low high",
    symbol="NumericLimits",
)
for index, name in enumerate(
    [
        "minimumNormal",
        "minimumSubnormal",
        "maximumFinite",
        "machineEpsilon",
        "significandDigits",
        "minimumExponent",
        "maximumExponent",
    ]
):
    snake = re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()
    unary(snake, "o", f"limitsField {index} value", symbol=name)
for name, saturate in [("safeIntegralCast", False), ("saturatingCast", True)]:
    snake = re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()
    spec(
        snake,
        [obj("value"), ("dtype", "i32")],
        f"boundedCast {saturate} dtype value",
        True,
        name,
    )
spec(
    "real_to_integral",
    [("mode", "mode"), obj("value"), ("dtype", "i32")],
    "realToIntegral mode dtype value",
    True,
    "realToIntegral",
)
spec(
    "narrow_float",
    [obj("value"), ("dtype", "i32")],
    "narrowFloat dtype value",
    True,
    "narrowFloat",
)
spec(
    "float16",
    [("mode", "mode"), ("value", "f64")],
    "pure (rounded Half (N.float16 mode value))",
    symbol="float16",
)
spec(
    "bfloat16",
    [("mode", "mode"), ("value", "f64")],
    "pure (rounded BHalf (N.bfloat16 mode value))",
    symbol="bfloat16",
)
spec(
    "float16_from_bits",
    [("bits", "u16")],
    "pure (Half (N.float16FromBits bits))",
    symbol="float16FromBits",
)
spec(
    "bfloat16_from_bits",
    [("bits", "u16")],
    "pure (BHalf (N.bfloat16FromBits bits))",
    symbol="bfloat16FromBits",
)
unary(
    "float16_bits",
    "half",
    "pure (scalar SWord16 (N.float16Bits value))",
    symbol="float16Bits",
)
unary(
    "bfloat16_bits",
    "bhalf",
    "pure (scalar SWord16 (N.bfloat16Bits value))",
    symbol="bfloat16Bits",
)
unary(
    "from_float16", "half", "pure (ndouble (N.fromFloat16 value))", symbol="fromFloat16"
)
unary(
    "from_bfloat16",
    "bhalf",
    "pure (ndouble (N.fromBFloat16 value))",
    symbol="fromBFloat16",
)
spec(
    "rounded",
    [obj("value"), ("flags", "flags")],
    "pure (makeRounded value flags)",
    symbol="Rounded",
)
unary("rounded_value", "o", "roundedValue value", symbol="roundedValue")
unary(
    "numerical_exceptions",
    "o",
    "numericalExceptions value",
    symbol="numericalExceptions",
)
spec(
    "big_float",
    [("precision", "i"), ("mode", "mode"), ("value", "q")],
    "pure (rounded Big <$> N.bigFloat (fromIntegral precision) mode value)",
    True,
    "bigFloat",
)
spec("extended", [("value", "q")], "pure (Big <$> N.extended value)", True, "extended")
unary(
    "big_precision", "big", "pure (nint (N.bigPrecision value))", symbol="bigPrecision"
)
unary(
    "big_rational",
    "big",
    "pure (nrational (N.bigRational value))",
    symbol="bigRational",
)
unary(
    "big_to_double", "big", "pure (ndouble (N.bigToDouble value))", symbol="bigToDouble"
)
for name in ["Add", "Subtract", "Multiply", "Divide"]:
    binary("big_" + name.lower(), "big", f"pure (Big <$> N.big{name} a b)", True)
    SPECS[-1]["symbol"] = "big" + name
for name in ["Sqrt", "Exp", "Log"]:
    unary(
        "big_" + name.lower(),
        "big",
        f"pure (Big <$> N.big{name} value)",
        True,
        "big" + name,
    )
for name in ["Add", "Multiply"]:
    spec(
        "mixed_" + name.lower(),
        [("a", "big"), ("b", "f64")],
        f"pure (Big <$> N.mixed{name} a b)",
        True,
        "mixed" + name,
    )
for prefix, wrapper, htype in [
    ("fixed", "Fixed", "fixed"),
    ("decimal", "Decimal", "decimal"),
]:
    spec(
        prefix,
        [("scale", "i"), ("mode", "mode"), ("value", "q")],
        f"pure (rounded {wrapper} <$> N.{prefix} (fromIntegral scale) mode value)",
        True,
        prefix,
    )
    unary(
        prefix + "_rational",
        htype,
        f"pure (nrational (N.{prefix}Rational value))",
        False,
        prefix + "Rational",
    )
    binary(
        prefix + "_add", htype, f"pure (rounded {wrapper} <$> N.{prefix}Add a b)", True
    )
    SPECS[-1]["symbol"] = prefix + "Add"
    for name in ["Multiply", "Divide"]:
        spec(
            prefix + "_" + name.lower(),
            [("mode", "mode"), ("a", htype), ("b", htype)],
            f"pure (rounded {wrapper} <$> N.{prefix}{name} mode a b)",
            True,
            prefix + name,
        )
unary("fixed_scale", "fixed", "pure (nint (N.fixedScale value))", symbol="fixedScale")
unary(
    "fixed_coefficient",
    "fixed",
    "pure (ninteger (N.fixedCoefficient value))",
    symbol="fixedCoefficient",
)
spec(
    "interval",
    [("low", "f64"), ("high", "f64")],
    "pure (Interval <$> N.interval low high)",
    True,
    "interval",
)
unary(
    "interval_bounds",
    "interval",
    'let (a,b)=N.intervalBounds value in pure (Sequence True "" [ndouble a,ndouble b])',
    symbol="intervalBounds",
)
spec(
    "interval_contains",
    [("value", "interval"), ("point", "f64")],
    "pure (Boolean (N.intervalContains value point))",
    symbol="intervalContains",
)
for name in ["Add", "Subtract", "Multiply", "Divide"]:
    binary(
        "interval_" + name.lower(),
        "interval",
        f"pure (Interval <$> N.interval{name} a b)",
        True,
    )
    SPECS[-1]["symbol"] = "interval" + name
spec(
    "dual",
    [obj("primal_value"), obj("tangent_value")],
    "makeDual primal_value tangent_value",
    symbol="Dual",
)
unary("primal", "o", "primal value", symbol="primal")
unary("tangent", "o", "tangent value", symbol="tangent")
spec(
    "derivative",
    [("function", "callback"), obj("value")],
    "derivative function functionUserdata value",
    symbol="derivative",
)
spec(
    "quaternion",
    [obj("real"), obj("i"), obj("j"), obj("k")],
    "makeQuaternion real i j k",
    symbol="Quaternion",
)
unary(
    "quaternion_conjugate",
    "o",
    "quaternionConjugate value",
    symbol="quaternionConjugate",
)
unary("quaternion_norm", "o", "quaternionNorm value", symbol="quaternionNorm")
unary("quaternion_inverse", "o", "quaternionInverse value", True, "quaternionInverse")
spec(
    "quaternion_component",
    [obj("value"), ("index", "i")],
    "quaternionComponent index value",
)
spec(
    "dual_quaternion",
    [obj("real"), obj("dual")],
    "makeDualQuaternion real dual",
    symbol="DualQuaternion",
)
spec(
    "dual_quaternion_component",
    [obj("value"), ("index", "i")],
    "dualQuaternionComponent index value",
)
spec(
    "dual_quaternion_multiply",
    [obj("a"), obj("b")],
    "dualQuaternionMultiply a b",
    symbol="dualQuaternionMultiply",
)
unary(
    "dual_quaternion_inverse",
    "o",
    "dualQuaternionInverse value",
    True,
    "dualQuaternionInverse",
)
for snake, hs in [
    ("rotate_vector", "rotateVector"),
    ("rigid_transform", "rigidTransform"),
    ("transform_point", "transformPoint"),
]:
    spec(
        snake,
        [obj("value"), obj("x"), obj("y"), obj("z")],
        f"{hs} value x y z",
        True,
        hs,
    )
spec(
    "constant",
    [
        ("name", "text"),
        ("value", "q"),
        ("uncertainty", "q"),
        ("approximation", "q"),
        ("unit", "text"),
        ("source", "text"),
    ],
    "pure (Constant (K.Constant name value uncertainty approximation unit source))",
    symbol="Constant",
    module="Constants",
)
for index, name in enumerate(
    [
        "constantName",
        "constantValue",
        "standardUncertainty",
        "approximationBound",
        "constantUnit",
        "constantSource",
    ]
):
    unary(
        re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower(),
        "o",
        f"constantField {index} value",
        symbol=name,
    )
    SPECS[-1]["module"] = "Constants"
spec(
    "constant_as",
    [obj("value"), ("dtype", "i32")],
    "constantAs dtype value",
    symbol="constantAs",
    module="Constants",
)
spec(
    "constant_as_like",
    [obj("value"), obj("prototype")],
    "constantAsLike prototype value",
)
for name in ["mathematicalConstants", "physicalConstants"]:
    spec(
        re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower(),
        [],
        f'pure (Sequence False "Constant" (map Constant K.{name}))',
        symbol=name,
        module="Constants",
    )
for name in [
    "speedOfLight",
    "planckConstant",
    "elementaryCharge",
    "boltzmannConstant",
    "avogadroConstant",
    "gravitationalConstant",
    "electronMass",
    "astronomicalUnit",
]:
    spec(
        re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower(),
        [],
        f"pure (Constant K.{name})",
        symbol=name,
        module="Constants",
    )

OBJECT_TYPES = {
    "o": None,
    "big": "getBig",
    "fixed": "getFixed",
    "decimal": "getDecimal",
    "interval": "getInterval",
    "half": "getHalf",
    "bhalf": "getBHalf",
}


def generate():
    header = [
        '/* SPDX-License-Identifier: MPL-2.0 */\n/* Generated by tools/generate_numeric_types.py. */\n#ifndef HMATH_NUMERIC_TYPES_H\n#define HMATH_NUMERIC_TYPES_H\n#include "hmath_value.h"\n#ifdef __cplusplus\nextern "C" {\n#endif\n',
        """typedef hmath_value hmath_numeric_value;
typedef hmath_status (*hmath_numeric_callback)(const hmath_numeric_value *input, void *userdata, hmath_numeric_value **out);
typedef enum hmath_rounding_mode {
 HMATH_NEAREST_EVEN=0, HMATH_TOWARD_ZERO=1, HMATH_TOWARD_POSITIVE=2, HMATH_TOWARD_NEGATIVE=3
} hmath_rounding_mode;
typedef enum hmath_numeric_exception {
 HMATH_INVALID_OPERATION=0, HMATH_DIVISION_BY_ZERO=1, HMATH_NUMERIC_OVERFLOW=2,
 HMATH_NUMERIC_UNDERFLOW=3, HMATH_INEXACT=4
} hmath_numeric_exception;
typedef enum hmath_ieee_class {
 HMATH_NOT_A_NUMBER=0, HMATH_POSITIVE_INFINITY=1, HMATH_NEGATIVE_INFINITY=2,
 HMATH_POSITIVE_ZERO=3, HMATH_NEGATIVE_ZERO=4, HMATH_SUBNORMAL=5, HMATH_NORMAL=6
} hmath_ieee_class;
/* Handles are immutable and own an RTS reservation. Hold a reference throughout
 * every call; final shutdown is BUSY while any handle is live. Release is a NULL
 * no-op. Outputs are untouched on failure. Original MathError uses status11.
 * Strings use length-delimited Unicode code points (including embedded NUL and
 * surrogates), exactly matching Haskell Char. All code points must be <=0x10ffff.
 * Synchronous derivative callbacks borrow input; out transfers one reference.
 * Retain input first if returning it. Callbacks may reenter checked APIs, must
 * not unwind through C, and must be deterministic. Cancellation is before entry.
 * Independent calls may share immutable values; own a reference on each thread.
 * Primitive dtypes follow shared Coefficient codes: Double0,Float1,Integer2,
 * Rational3,ComplexDouble4,ComplexFloat5,Int8..Int64=6..9,Word8..Word64=10..13,
 * native Int14,Word15; Numeric.Dual20,Quaternion21.
 */
HMATH_API void hmath_numeric_types_retain(hmath_numeric_value *value);
HMATH_API void hmath_numeric_types_release(hmath_numeric_value *value);
HMATH_API void hmath_numeric_types_buffer_free(void *value);
HMATH_API int hmath_numeric_types_kind(const hmath_numeric_value *value);
""",
    ]
    c = [
        '/* SPDX-License-Identifier: MPL-2.0 */\n/* Generated; do not edit. */\n#include "hmath_numeric_types.h"\n#include "numeric_internal.h"\n#include "value_internal.h"\n#include <stdlib.h>\n',
        """extern int hm_numeric_types_clone(void *stable,void **out);
void hmath_numeric_types_retain(hmath_numeric_value *value) { hmath_value_retain(value); }
void hmath_numeric_types_release(hmath_numeric_value *value) { hmath_value_release(value); }
void hmath_numeric_types_buffer_free(void *value) { free(value); }
int hmath_numeric_types_kind(const hmath_numeric_value *value) { return value ? value->kind : 0; }
int hm_numeric_types_invoke(hmath_numeric_callback callback,void *userdata,void *input_stable,void **out) {
 hmath_numeric_value *temporary=NULL,*input=NULL,*output=NULL;
 hmath_status status=hm_value_begin(NULL,&temporary);
 if(status) { extern void hm_value_free(void *);hm_value_free(input_stable);return status; }
 temporary->stable=input_stable;
 status=hm_value_finish(temporary,0,&input);
 if(status) return status;
 status=callback(input,userdata,&output);
 if(!status && !output) status=hm_error(HMATH_INVALID_ARGUMENT,"callback returned NULL value");
 if(!status) status=(hmath_status)hm_numeric_types_clone(output->stable,out);
 if(output) hmath_value_release(output);
 hmath_value_release(input);
 return status;
}
""",
    ]
    hs = [
        "{-# LANGUAGE ForeignFunctionInterface #-}\n-- SPDX-License-Identifier: MPL-2.0\n-- Generated by tools/generate_numeric_types.py.\nmodule HMath.FFI.NumericTypes where\nimport HMath.FFI.NumericTypes.Core\nimport HMath.FFI.Boundary (checked, readInteger)\nimport HMath.FFI.Coefficient\nimport qualified HMath.Numeric as N\nimport qualified HMath.Constants as K\nimport Data.Coerce (coerce)\nimport Data.Ratio ((%))\nimport Foreign\nimport Foreign.C\n"
    ]
    symbols = [
        "hmath_numeric_types_" + name
        for name in ["retain", "release", "buffer_free", "kind"]
    ]
    mapping = []
    for item in SPECS:
        name = item["name"]
        public = "hmath_numeric_types_" + name
        internal = "hm_numeric_types_" + name
        hsname = "ffi" + "".join(x.title() for x in name.split("_"))
        ca = []
        ha = []
        hargs = []
        decode = []
        validation = []
        nativeargs = []
        for arg in item["args"]:
            n, k = arg["name"], arg["type"]
            h = "raw" + n[0].upper() + n[1:]
            if k in OBJECT_TYPES:
                ca.append(f"const hmath_numeric_value *{n}")
                ha.append("Handle")
                hargs.append(h)
                decode.append(f"    {n}Object <- dereference {h}\n")
                decode.append(
                    f"    {n} <- {OBJECT_TYPES[k]} {n}Object\n"
                    if OBJECT_TYPES[k]
                    else f"    let {n} = {n}Object\n"
                )
                validation.append(
                    f' if(!{n}) return hm_error(HMATH_INVALID_ARGUMENT,"NULL {n}");\n'
                )
                nativeargs.append(n + "->stable")
            elif k in ("i", "i32", "u16", "f32", "f64"):
                ct, ht = {
                    "i": ("ptrdiff_t", "CPtrdiff"),
                    "i32": ("int", "CInt"),
                    "u16": ("uint16_t", "Word16"),
                    "f32": ("float", "CFloat"),
                    "f64": ("double", "CDouble"),
                }[k]
                ca.append(f"{ct} {n}")
                ha.append(ht)
                hargs.append(h)
                nativeargs.append(n)
                decode.append(
                    f"    let {n} = coerce {h}\n"
                    if k in ("f32", "f64")
                    else f"    let {n} = {h}\n"
                )
            elif k == "mode":
                ca.append(f"int {n}")
                ha.append("CInt")
                hargs.append(h)
                nativeargs.append(n)
                decode.append(f"    {n} <- roundingMode {h}\n")
            elif k in ("z", "q"):
                labels = [n] if k == "z" else [n + "_numerator", n + "_denominator"]
                parsed = []
                for label in labels:
                    hh = "raw" + label.replace("_", "X")
                    vv = label.replace("_", "X") + "Value"
                    ca.append(f"const char *{label}")
                    ha.append("CString")
                    hargs.append(hh)
                    nativeargs.append(label)
                    validation.append(
                        f' if(!hm_decimal({label})) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");\n'
                    )
                    decode.append(f"    {vv} <- readInteger {hh}\n")
                    parsed.append(vv)
                if k == "q":
                    validation.append(
                        f" const char *{n}Digit={n}_denominator; if(*{n}Digit=='-') ++{n}Digit; while(*{n}Digit=='0') ++{n}Digit; if(!*{n}Digit) return hm_error(HMATH_INVALID_ARGUMENT,\"zero Rational denominator\");\n"
                    )
                decode.append(
                    f"    let {n} = "
                    + (parsed[0] if k == "z" else parsed[0] + " % " + parsed[1])
                    + "\n"
                )
            elif k in ("text", "flags"):
                ct, ht = ("uint32_t", "Word32") if k == "text" else ("int", "CInt")
                ca.extend([f"const {ct} *{n}", f"size_t {n}_count"])
                ha.extend([f"Ptr {ht}", "CSize"])
                hargs.extend([h, h + "Count"])
                nativeargs.extend([n, n + "_count"])
                validation.append(
                    f' if({n}_count>(size_t)PTRDIFF_MAX/sizeof({ct}) || ({n}_count && !{n})) return hm_error(HMATH_INVALID_ARGUMENT,"invalid array span");\n'
                )
                if k == "text":
                    validation.append(
                        f' for(size_t i=0;i<{n}_count;++i) if({n}[i]>0x10ffffu) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Char code point");\n'
                    )
                    decode.append(
                        f"    {n}Object <- readText {h} {h}Count\n    {n} <- getText {n}Object\n"
                    )
                else:
                    decode.append(
                        f"    {n} <- peekArray (fromIntegral {h}Count) {h} >>= mapM exception\n"
                    )
            elif k == "callback":
                ca.extend([f"hmath_numeric_callback {n}", f"void *{n}_userdata"])
                ha.extend(["FunPtr NumericCallback", "Ptr ()"])
                hargs.extend([n, n + "Userdata"])
                nativeargs.extend([n, n + "_userdata"])
                validation.append(
                    f' if(!{n}) return hm_error(HMATH_INVALID_ARGUMENT,"NULL callback");\n'
                )
            else:
                raise ValueError(k)
        signature = (
            f"hmath_status {public}(hmath_context *context"
            + (", " + ", ".join(ca) if ca else "")
            + ", hmath_numeric_value **out)"
        )
        header.append("HMATH_API " + signature + ";\n")
        ffi_args = []
        for original, arg in zip(ca, nativeargs):
            ffi_args.append(
                "void *" + arg.split("->")[0] if "->stable" in arg else original
            )
        # Native stable pointers replace typed wrapper pointers at this boundary.
        ffi_decl = [
            re.sub(r"const hmath_numeric_value \*", "void *", arg) for arg in ca
        ]
        c.append(
            f"extern int {internal}("
            + ", ".join(ffi_decl + ["void **out"])
            + ");\n"
            + signature
            + " {\n"
        )
        c.extend(validation)
        c.append(
            ' if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");\n hmath_numeric_value *result=NULL;\n hmath_status status=hm_value_begin(context,&result);\n if(status) return status;\n'
        )
        c.append(
            " return hm_value_finish(result, "
            + internal
            + "("
            + ", ".join(nativeargs + ["&result->stable"])
            + "), out);\n}\n"
        )
        hsig = " -> ".join(ha + ["Ptr Handle", "IO CInt"])
        hs.append(
            f'\nforeign export ccall "{internal}" {hsname} :: {hsig}\n{hsname} :: {hsig}\n{hsname} '
            + " ".join(hargs + ["out"])
            + " = numericBoundary $ do\n"
        )
        hs.extend(decode)
        hs.append(f"    result <- {item['expression']}\n")
        hs.append(
            "    checked "
            + ("(result)" if item["checked"] else "(Right result)")
            + " (`publish` out)\n"
        )
        symbols.append(public)
        if item["symbol"]:
            mapping.append(
                {
                    "symbol": "HMath." + item["module"] + "." + item["symbol"],
                    "c": [public],
                    "python": "hmath.numeric_types." + name,
                    "specializations": ["typed opaque representation"],
                }
            )
    header.append(
        "HMATH_API hmath_status hmath_numeric_types_enum_value(hmath_context *context,const hmath_numeric_value *value,int *out);\n"
    )
    c.append(
        'extern int hm_numeric_types_enum_value(void *stable,int *out);\nhmath_status hmath_numeric_types_enum_value(hmath_context *context,const hmath_numeric_value *value,int *out) { if(!value||!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL enum argument"); hmath_status status=hm_enter(context);if(status)return status;status=(hmath_status)hm_numeric_types_enum_value(value->stable,out);hm_leave();return status;}\n'
    )
    symbols.append("hmath_numeric_types_enum_value")
    header.append("#ifdef __cplusplus\n}\n#endif\n#endif\n")
    py = [
        "# SPDX-License-Identifier: MPL-2.0\n# Generated by tools/generate_numeric_types.py; do not edit.\n",
        '"""Original HMath.Numeric types and Constants records.\n\n',
        "Factories return immutable owned NumericValue objects for structured types.\n",
        "Standard scalar results decode to Python numbers; use boxed properties\n",
        "on NumericValue when preserving a scalar dtype through callbacks.\n",
        '"""\n',
        "from ._numeric_types_runtime import (\n    IEEEClass,\n    NumericException,\n    NumericValue,\n    RoundingMode,\n    _call_named,\n    number,\n)\n\n",
    ]
    signatures = {item["name"]: [a["type"] for a in item["args"]] for item in SPECS}
    py.append("_SIGNATURES = " + json.dumps(signatures, indent=4) + "\n\n")
    for item in SPECS:
        name = item["name"]
        names = [a["name"] for a in item["args"]]
        parameters = ", ".join(names + ["*", "boxed=False"])
        py.append("def " + name + "(" + parameters + "):\n")
        symbol = item["symbol"]
        py.append(
            '    """'
            + (
                "HMath."
                + item["module"]
                + "."
                + symbol
                + "; retains the original type/rounding/error contract."
                if symbol
                else "Typed representation helper; no alternate numerical algorithm."
            )
            + '"""\n'
        )
        py.append(
            "    return _call_named(" + repr(name) + ", [" + ", ".join(names) + "], raw=boxed)\n\n"
        )
    py.append(
        "__all__ = "
        + json.dumps(
            sorted(
                [
                    "NumericValue",
                    "RoundingMode",
                    "NumericException",
                    "IEEEClass",
                    "number",
                ]
                + [item["name"] for item in SPECS]
            ),
            indent=4,
        )
        + "\n"
    )
    type_factories = {
        "Float16": "float16_from_bits",
        "BFloat16": "bfloat16_from_bits",
        "BigFloat": "big_float",
        "Fixed": "fixed",
        "Decimal": "decimal",
        "Interval": "interval",
    }
    for symbol, factory in type_factories.items():
        mapping.append(
            {
                "symbol": "HMath.Numeric." + symbol,
                "c": ["hmath_numeric_types_" + factory],
                "python": "hmath.numeric_types." + factory,
                "specializations": ["original opaque Haskell type"],
            }
        )
    for group, constructors in [
        (
            "RoundingMode",
            ["NearestEven", "TowardZero", "TowardPositive", "TowardNegative"],
        ),
        (
            "NumericException",
            [
                "InvalidOperation",
                "DivisionByZero",
                "NumericOverflow",
                "NumericUnderflow",
                "Inexact",
            ],
        ),
        (
            "IEEEClass",
            [
                "NotANumber",
                "PositiveInfinity",
                "NegativeInfinity",
                "PositiveZero",
                "NegativeZero",
                "Subnormal",
                "Normal",
            ],
        ),
    ]:
        for symbol in [group] + constructors:
            mapping.append(
                {
                    "symbol": "HMath.Numeric." + symbol,
                    "c": [
                        "hmath_numeric_types_classify"
                        if group == "IEEEClass"
                        else "hmath_numeric_types_rounded"
                        if group == "NumericException"
                        else "hmath_numeric_types_round_rational"
                    ],
                    "python": "hmath.numeric_types."
                    + group
                    + (
                        ""
                        if symbol == group
                        else "." + re.sub(r"(?<!^)(?=[A-Z])", "_", symbol).upper()
                    ),
                    "specializations": ["lossless enum representation"],
                }
            )
    for alias, dtype in [("Float32", "float32"), ("Float64", "float64")]:
        mapping.append(
            {
                "symbol": "HMath.Numeric." + alias,
                "c": ["hmath_value_f32" if dtype == "float32" else "hmath_value_f64"],
                "python": "hmath.numeric_types.number",
                "specializations": [dtype],
            }
        )
    return {
        "include/hmath_numeric_types.h": "".join(header),
        "cbits/numeric_types.c": "".join(c),
        "src/HMath/FFI/NumericTypes.hs": "".join(hs),
        "bindings/python/_hmath_native/numeric_types.py": "".join(py),
        "bindings/schema/numeric-types-objects.json": json.dumps(
            {"schema": 1, "bindings": mapping}, indent=2
        )
        + "\n",
        "bindings/schema/numeric-types-symbols.txt": "\n".join(symbols) + "\n",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    bad = []
    for name, text in generate().items():
        path = ROOT / name
        if args.check:
            if not path.exists() or path.read_text() != text:
                bad.append(name)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)
    if bad:
        parser.exit(1, "Stale numeric type adapters: " + ", ".join(bad) + "\n")


if __name__ == "__main__":
    main()
