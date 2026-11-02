# SPDX-License-Identifier: MPL-2.0
"""Generate direct exact adapters for all previously-unmapped Units symbols."""

import argparse
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TYPES = {"Dimension": 68, "Unit": 69, "Quantity": 70, "SIPrefix": 71}
EXISTING = {
    "radiansToDegrees",
    "degreesToRadians",
    "radiansToGradians",
    "gradiansToRadians",
}
# Each entry records source argument order/type, exact result and error convention.
SPECS = {
    "dimension": ([("exponents", "[Integer]")], "Dimension", "either"),
    "dimensionExponents": ([("dimension", "Dimension")], "[Integer]", "pure"),
    "unit": (
        [
            ("name", "String"),
            ("dimension", "Dimension"),
            ("scale", "Rational"),
            ("offset", "Rational"),
        ],
        "Unit",
        "either",
    ),
    "unitName": ([("unit", "Unit")], "String", "pure"),
    "unitDimension": ([("unit", "Unit")], "Dimension", "pure"),
    "unitScale": ([("unit", "Unit")], "Rational", "pure"),
    "unitOffset": ([("unit", "Unit")], "Rational", "pure"),
    "unitProduct": ([("left", "Unit"), ("right", "Unit")], "Unit", "either"),
    "unitQuotient": (
        [("numerator", "Unit"), ("denominator", "Unit")],
        "Unit",
        "either",
    ),
    "unitPower": ([("unit", "Unit"), ("exponent", "Integer")], "Unit", "either"),
    "quantity": ([("unit", "Unit"), ("value", "Rational")], "Quantity", "pure"),
    "temperatureDifference": (
        [("unit", "Unit"), ("value", "Rational")],
        "Quantity",
        "either",
    ),
    "quantityDimension": ([("quantity", "Quantity")], "Dimension", "pure"),
    "siValue": ([("quantity", "Quantity")], "Rational", "pure"),
    "inUnit": ([("unit", "Unit"), ("quantity", "Quantity")], "Rational", "either"),
    "convert": (
        [("source", "Unit"), ("destination", "Unit"), ("value", "Rational")],
        "Rational",
        "either",
    ),
    "addQuantity": (
        [("left", "Quantity"), ("right", "Quantity")],
        "Quantity",
        "either",
    ),
    "subtractQuantity": (
        [("left", "Quantity"), ("right", "Quantity")],
        "Quantity",
        "either",
    ),
    "multiplyQuantity": (
        [("left", "Quantity"), ("right", "Quantity")],
        "Quantity",
        "either",
    ),
    "divideQuantity": (
        [("numerator", "Quantity"), ("denominator", "Quantity")],
        "Quantity",
        "either",
    ),
    "prefixName": ([("prefix", "SIPrefix")], "String", "pure"),
    "prefixSymbol": ([("prefix", "SIPrefix")], "String", "pure"),
    "prefixExponent": ([("prefix", "SIPrefix")], "Int", "pure"),
    "siPrefixes": ([], "[SIPrefix]", "pure"),
    "prefixed": ([("prefix", "SIPrefix"), ("unit", "Unit")], "Unit", "either"),
    "SIPrefix": (
        [("name", "String"), ("symbol", "String"), ("exponent", "Int")],
        "SIPrefix",
        "pure",
    ),
}


def snake(name):
    return re.sub(
        r"([a-z0-9])([A-Z])", r"\1_\2", re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", name)
    ).lower()


def source_exports():
    text = (
        (ROOT / "src/HMath/Units.hs")
        .read_text()
        .split(") where", 1)[0]
        .split("module HMath.Units (", 1)[1]
    )
    return re.findall(r"^    (\w+)", text, re.MULTILINE) + ["prefixName", "prefixSymbol", "prefixExponent"]


def ops():
    result = []
    for name in source_exports():
        if name in EXISTING or (name in TYPES and name != "SIPrefix"):
            continue
        spec = SPECS.get(
            name,
            (
                [],
                "Dimension"
                if name.endswith("Dimension") or name == "dimensionless"
                else "Unit",
                "pure",
            ),
        )
        result.append((name, *spec))
    return result


def source_doc(name):
    source = (ROOT / "src/HMath/Units.hs").read_text()
    match = re.search(r"\n" + re.escape(name) + r"(?:\s+::|\s*=|\s+\w)", source)
    if not match:
        return "Original public HMath.Units constructor or field."
    before = source[: match.start()]
    start = max(before.rfind("\n{- |"), before.rfind("\n-- |"))
    text = before[start:].strip()
    if text.startswith("{- |"):
        text = text[4:].split("-}", 1)[0]
    elif text.startswith("-- |"):
        text = text[4:]
    else:
        return "Original public HMath.Units value."
    return " ".join(text.replace("--", "").replace("@", "`").split())


def python_format(source):
    checked = subprocess.run(
        [
            "ruff",
            "check",
            "--select",
            "I,RUF022",
            "--fix",
            "--stdin-filename",
            "units_values.py",
            "-",
        ],
        input=source,
        text=True,
        capture_output=True,
        check=True,
    ).stdout
    return subprocess.run(
        ["ruff", "format", "--stdin-filename", "units_values.py", "-"],
        input=checked,
        text=True,
        capture_output=True,
        check=True,
    ).stdout


def outputs():
    entries = ops()
    h = [
        """/* SPDX-License-Identifier: MPL-2.0 */
/* Generated by tools/generate_units_bindings.py. */
#ifndef HMATH_UNITS_H
#define HMATH_UNITS_H
#include "hmath_value.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Exact original Units API. Unit/Quantity scalar inputs must be Rational
 * Values; dimension and power exponents use arbitrary Integer Values.
 * Prefix exponents use Haskell Int. Objects are immutable and independently
 * owned; release every result with hmath_value_release. Inputs are borrowed
 * for this call only. All errors preserve the original MathError; output
 * pointers remain untouched on failure. Catalog getters return owned handles. */
"""
    ]
    c = [
        """/* SPDX-License-Identifier: MPL-2.0 */
/* Generated by tools/generate_units_bindings.py. */
#include "hmath_units.h"
#include "value_internal.h"
extern int hm_units_apply(int opcode,void *const *args,size_t count,void **out);
"""
    ]
    hs = [
        """{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- Generated by tools/generate_units_bindings.py. No numerical reimplementation.
module HMath.FFI.Units where
import Control.Exception (evaluate,throwIO)
import Data.Typeable (Typeable,cast)
import Foreign
import Foreign.C
import qualified HMath.Units as U
import HMath.Error (MathError)
import HMath.FFI.Coefficient
import qualified HMath.FFI.Value as V
import qualified HMath.FFI.Boundary as B
import HMath.FFI.MathError

dimension :: U.Dimension -> V.Value
dimension x=V.Opaque 68 (-1) 9 (mapM_ forceCoefficient (U.dimensionExponents x)) x
unit :: U.Unit -> V.Value
unit x=V.Opaque 69 (-1) 0 (V.forceValue(V.Text(U.unitName x)) >> V.forceValue(dimension(U.unitDimension x)) >> forceCoefficient(U.unitScale x) >> forceCoefficient(U.unitOffset x)) x
quantity :: U.Quantity -> V.Value
quantity x=V.Opaque 70 (-1) 0 (V.forceValue(dimension(U.quantityDimension x)) >> forceCoefficient(U.siValue x) >> evaluate x >> pure ()) x
siPrefix :: U.SIPrefix -> V.Value
siPrefix x=V.Opaque 71 (-1) 0 (V.forceValue(V.Text(U.prefixName x)) >> V.forceValue(V.Text(U.prefixSymbol x)) >> evaluate(U.prefixExponent x) >> pure ()) x
asObject :: Typeable a => Int -> V.Value -> IO a
asObject kind (V.Opaque actual _ _ _ payload) | kind==actual=maybe (V.invalid "Units object payload/type mismatch") pure (cast payload)
asObject _ _=V.invalid "Units object kind mismatch"
source :: Either MathError a -> IO a
source=either (throwIO . CallbackMathError) pure
unitsBoundary :: IO CInt -> IO CInt
unitsBoundary action=B.boundary $ callbackBoundary (\\e -> B.checked (Left e) (const(pure ()))) action
apply :: Int -> [V.Value] -> IO V.Value
apply opcode args=case (opcode,args) of
"""
    ]
    py = [
        '# SPDX-License-Identifier: MPL-2.0\n# Generated by tools/generate_units_bindings.py.\n"""Exact original HMath.Units operations and owned catalog values."""\nfrom ._units_base import Dimension,Unit,Quantity,SIPrefix,_call\n'
    ]
    py.append(
        "__all__="
        + repr(list(TYPES) + [snake(x[0]) for x in entries])
        + "\n"
    )
    docs = [
        """# Exact units and quantities

Unit conversion and quantity arithmetic call the original `HMath.Units` implementation. Values are exact `fractions.Fraction` objects, including affine offsets; exponents are arbitrary integers. Nine dimensions distinguish seven SI base dimensions, data, and plane angle. Invalid conversions preserve original `MathError` constructors and messages.

```python
from fractions import Fraction
from hmath import units as u

with u.kilometre() as km, u.metre() as metre:
    assert u.convert(km, metre, Fraction(3, 2)) == 1500
with u.celsius() as c, u.fahrenheit() as f:
    assert u.convert(c, f, 100) == 212
```

Catalog names are zero-argument functions returning independently owned immutable Unit/Dimension handles. Use `close()` or a context manager; releasing an input cannot invalidate a returned quantity or derived unit. Constants are not initialized at import time. `Dimension`, `Unit`, `Quantity`, and `SIPrefix` constructors follow their original source constructors; named functions provide equivalent access. Their equality uses original derived Haskell `Eq`.

Absolute temperatures and differences retain their original hidden distinction: absolute plus absolute fails, absolute minus absolute yields a difference, difference minus absolute fails, and multiplying/dividing an absolute temperature fails. `temperature_difference` ignores the unit's affine offset. `in_unit` subtracts an affine offset only for absolute quantities. Zero divisor, incompatible dimensions, invalid scale, affine unit products/prefixes, and prefix resource limits retain original errors. The SI prefix catalog includes exactly the source ordering and spellings.

Python integer inputs to Rational fields are converted exactly, and `Fraction` values never pass through FP64. A Python float is converted to the exact fraction representing that already-rounded float; use `Fraction("0.1")` when decimal 0.1 is intended. Prefix exponents must fit Haskell `Int`; unit powers and dimension exponents use unbounded `Integer`. The existing four angle-conversion numeric functions retain their Float/Double interfaces.

Include `hmath_units.h` plus `hmath_value.h` in C. Unit/quantity scalar inputs use Rational Values, dimensional/power exponents use Integer Values, and prefix exponents use Index or an exact Int-range integral Value. Text uses length-delimited codepoints, preserving Unicode, embedded NUL and Haskell Char surrogates. Every result is owned and must be released once. Errors leave `out` untouched. Inputs are immutable and borrowed for the call only; independent calls may share them.

"""
    ]
    mapping = []
    decoder = {
        "String": "V.asText",
        "Rational": "V.asScalar",
        "Integer": "V.asScalar",
        "Int": "V.asIndex",
        "[Integer]": "(\\v -> V.asList v >>= mapM V.asScalar)",
    }
    encoder = {
        "String": "V.Text",
        "Rational": "V.Scalar SRational",
        "Integer": "V.Scalar SInteger",
        "Int": "V.Index",
        "[Integer]": "V.List . map (V.Scalar SInteger)",
        "[SIPrefix]": "V.List . map siPrefix",
    }
    for typ, tag in TYPES.items():
        decoder[typ] = "asObject " + str(tag)
        encoder[typ] = "siPrefix" if typ == "SIPrefix" else typ[0].lower() + typ[1:]
    for opcode, (name, args, result, mode) in enumerate(entries):
        variables = ["a" + str(i) for i in range(len(args))]
        hs.append("    (" + str(opcode) + ",[" + ",".join(variables) + "]) -> do\n")
        for variable, (_parameter, typ) in zip(variables, args):
            hs.append(
                "        "
                + variable
                + "Value <- "
                + decoder[typ]
                + " "
                + variable
                + "\n"
            )
        expression = "U." + name + " " + " ".join(v + "Value" for v in variables)
        if mode == "either":
            hs.append(
                "        (" + encoder[result] + ") <$> source (" + expression + ")\n"
            )
        else:
            hs.append("        pure ((" + encoder[result] + ") (" + expression + "))\n")
        symbol = "hmath_units_value_" + snake(name)
        params = (
            ["hmath_context *context"]
            + ["const hmath_value *" + a for a, _ in args]
            + ["hmath_value **out"]
        )
        proto = "hmath_status " + symbol + "(" + ", ".join(params) + ")"
        h.append("HMATH_API " + proto + ";\n")
        checks = ["!out"] + ["!" + a for a, _ in args]
        c.append(
            proto
            + " {\n    if ("
            + " || ".join(checks)
            + ')\n        return hm_error(HMATH_INVALID_ARGUMENT,"NULL Units argument");\n    hmath_value *result;\n    hmath_status status=hm_value_begin(context,&result);\n    if(status) return status;\n'
        )
        cargs = "NULL"
        if args:
            c.append(
                "    void *args[]={"
                + ",".join("hm_value_stable(" + a + ")" for a, _ in args)
                + "};\n"
            )
            cargs = "args"
        c.append(
            "    return hm_value_finish(result,hm_units_apply("
            + str(opcode)
            + ","
            + cargs
            + ","
            + str(len(args))
            + ",&result->stable),out);\n}\n"
        )
        pname = "si_prefix" if name == "SIPrefix" else snake(name)
        signature = ", ".join(a for a, _ in args)
        doc = source_doc(name)
        py.append(
            "\ndef "
            + pname
            + "("
            + signature
            + "):\n    "
            + repr("HMath.Units." + name + ": " + doc)
            + "\n    return _call("
            + repr(symbol)
            + ", "
            + repr([typ for _, typ in args])
            + (", " + signature if args else "")
            + ")\n"
        )
        docs.append(
            "## `"
            + pname
            + "`\n\n"
            + doc
            + "\n\n`"
            + pname
            + "("
            + signature
            + ")` returns `"
            + result
            + "`"
            + (" or raises the original checked error." if mode == "either" else ".")
            + " Parameters: "
            + (
                ", ".join("`" + a + "`: `" + typ + "`" for a, typ in args)
                if args
                else "none; returns a new owned reference to the source catalog value."
            )
            + "\n\n```c\n"
            + proto
            + ";\n```\n\n"
        )
        if name not in TYPES:
            mapping.append(
                {
                    "symbol": "HMath.Units." + name,
                    "c": [symbol],
                    "python": "hmath.units." + pname,
                    "specializations": [
                        "original concrete Integer/Rational/Int/String/record types; exact conversion"
                    ],
                }
            )
    for typ, tag in TYPES.items():
        mapping.append(
            {
                "symbol": "HMath.Units." + typ,
                "c": [
                    "hmath_value",
                    "hmath_units_value_"
                    + snake(typ if typ == "SIPrefix" else typ[0].lower() + typ[1:]),
                ],
                "python": "hmath.units." + typ,
                "specializations": ["immutable exact Units Value kind" + str(tag)],
            }
        )
    # Private dispatch opcode100 compares original Eq of matching owner families.
    hs.append("""    (100,[a,b]) -> case (V.valueInfo a,V.valueInfo b) of
        ((68,_,_),(68,_,_)) -> do x <- asObject 68 a; y <- asObject 68 b; pure(V.Boolean((x::U.Dimension)==y))
        ((69,_,_),(69,_,_)) -> do x <- asObject 69 a; y <- asObject 69 b; pure(V.Boolean((x::U.Unit)==y))
        ((70,_,_),(70,_,_)) -> do x <- asObject 70 a; y <- asObject 70 b; pure(V.Boolean((x::U.Quantity)==y))
        ((71,_,_),(71,_,_)) -> do x <- asObject 71 a; y <- asObject 71 b; pure(V.Boolean((x::U.SIPrefix)==y))
        _ -> V.invalid "Units equality requires matching types"
    _ -> V.invalid "invalid Units operation/arity"
foreign export ccall "hm_units_apply" ffiApply :: CInt -> Ptr (StablePtr V.Value) -> CSize -> Ptr (StablePtr V.Value) -> IO CInt
ffiApply :: CInt -> Ptr (StablePtr V.Value) -> CSize -> Ptr (StablePtr V.Value) -> IO CInt
ffiApply opcode pointers count out=unitsBoundary $ do
    args <- peekArray (fromIntegral count) pointers >>= mapM deRefStablePtr
    value <- apply (fromIntegral opcode) args
    B.checked (Right ()) (const (V.publish value out))
""")
    h.append(
        "HMATH_API hmath_status hmath_units_value_equal(hmath_context *context,const hmath_value *left,const hmath_value *right,hmath_value **out);\n#ifdef __cplusplus\n}\n#endif\n#endif\n"
    )
    c.append("""hmath_status hmath_units_value_equal(hmath_context *context,const hmath_value *left,const hmath_value *right,hmath_value **out) {
    if(!left || !right || !out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL Units equality argument");
    hmath_value *result; hmath_status status=hm_value_begin(context,&result); if(status) return status;
    void *args[]={hm_value_stable(left),hm_value_stable(right)};
    return hm_value_finish(result,hm_units_apply(100,args,2,&result->stable),out);
}
""")
    return {
        "src/HMath/FFI/Units.hs": "".join(hs),
        "include/hmath_units.h": "".join(h),
        "cbits/units.c": "".join(c),
        "bindings/python/_hmath_native/units_values.py": python_format("".join(py)),
        "bindings/schema/units-values-objects.json": json.dumps(
            {"schema": 1, "bindings": sorted(mapping, key=lambda x: x["symbol"])},
            indent=2,
        )
        + "\n",
        "docs/reference/units-values.md": "".join(docs),
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    for name, data in outputs().items():
        path = ROOT / name
        if args.check:
            if not path.exists() or path.read_text() != data:
                raise SystemExit("Stale: " + name)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(data)
