# SPDX-License-Identifier: MPL-2.0
"""Expose both original algebra interfaces without inventing typeclass instances."""

import argparse
import json
import re
from pathlib import Path

import generate_foundation_bindings as F
import generate_linear_bindings as G
from generate_stochastic_bindings import fmt

ROOT = Path(__file__).resolve().parent.parent
MODULES = {"HMath.Algebra": ("A", "algebra"), "HMath.API.Algebra": ("P", "algebra_api")}
CLASSES = {
    "HMath.Algebra": {
        "Semiring": ["zero", "one", "plus", "times"],
        "Ring": ["negateRing"],
        "Field": ["inverseField"],
        "Group": ["groupIdentity", "groupCombine", "groupInverse"],
        "Module": ["moduleScale", "moduleAdd"],
        "VectorSpace": [],
    },
    "HMath.API.Algebra": {
        "Ring": ["zero", "one", "plus", "times", "negative", "integer"],
        "Field": ["invert"],
        "Scalar": ["conjugateScalar"],
        "FloatingPoint": ["machineEpsilon", "finiteScalar"],
        "Numeric": ["rational"],
        "MatrixLike": ["matrixDimensions", "matrixElements", "matrixConstruct"],
        "TensorLike": ["tensorDimensions", "tensorElements", "tensorConstruct"],
        "VectorSpace": ["vectorPlus", "vectorScale"],
        "Differentiable": ["differential"],
        "Differential": [],
    },
}
METHODS = {
    "zero": "a",
    "one": "a",
    "plus": "a -> a -> a",
    "times": "a -> a -> a",
    "negateRing": "a -> a",
    "inverseField": "a -> Either MathError a",
    "groupIdentity": "Additive a",
    "groupCombine": "Additive a -> Additive a -> Additive a",
    "groupInverse": "Additive a -> Additive a",
    "moduleScale": "a -> [a] -> [a]",
    "moduleAdd": "[a] -> [a] -> Either MathError [a]",
    "negative": "a -> a",
    "integer": "Integer -> a",
    "invert": "a -> Either MathError a",
    "conjugateScalar": "a -> a",
    "machineEpsilon": "Double",
    "finiteScalar": "a -> Bool",
    "rational": "Rational -> Either MathError a",
    "matrixDimensions": "Matrix a -> (Int,Int)",
    "matrixElements": "Matrix a -> [a]",
    "matrixConstruct": "Int -> Int -> [a] -> Either MathError (Matrix a)",
    "tensorDimensions": "Tensor a -> [Int]",
    "tensorElements": "Tensor a -> [a]",
    "tensorConstruct": "[Int] -> [a] -> Either MathError (Tensor a)",
    "vectorPlus": "Vector a -> Vector a -> Either MathError (Vector a)",
    "vectorScale": "a -> Vector a -> Vector a",
    "differential": "Dual a -> a",
}


def specification():
    old = G.MODULES
    G.MODULES = MODULES
    try:
        entries, types, _fields, _missing = G.signatures()
    finally:
        G.MODULES = old
    for module, classes in CLASSES.items():
        for cls, names in classes.items():
            for name in names:
                signature = METHODS[name]
                parts = G.split_top(signature, "->")
                raw = (ROOT / "src" / (module.replace(".", "/") + ".hs")).read_text()
                original = re.search(
                    r"^[ \t]+" + re.escape(name) + r"[ \t]*::[ \t]*([^\n]+)",
                    raw,
                    re.MULTILINE,
                )
                entries.append(
                    {
                        "module": module,
                        "name": name,
                        "args": [G.parse_type(s) for s in parts[:-1]],
                        "result": G.parse_type(parts[-1]),
                        "constraints": cls + " (original instances only)",
                        "signature": original[1].strip() if original else signature,
                        "wire_signature": signature,
                        "constructor": False,
                    }
                )
    return entries, types


def mode(e):
    name = e["name"]
    if e["module"] == "HMath.Algebra":
        if name in ("moduleScale", "moduleAdd", "moduleLaws", "linearCombination"):
            return "module"
        if name in (
            "zero",
            "one",
            "plus",
            "times",
            "negateRing",
            "inverseField",
            "semiringLaws",
            "ringLaws",
            "fieldLaws",
            "Additive",
            "getAdditive",
            "groupIdentity",
            "groupCombine",
            "groupInverse",
            "groupLaws",
        ):
            return "old"
    else:
        if name in ("matrixConstruct", "tensorConstruct", "vectorPlus", "vectorScale"):
            return "typed"
        if name in (
            "zero",
            "one",
            "plus",
            "times",
            "negative",
            "integer",
            "invert",
            "conjugateScalar",
            "machineEpsilon",
            "finiteScalar",
            "rational",
            "horner",
            "innerProduct",
        ):
            return "api"
    return "value"


def sym(e):
    return (
        "hmath_algebra_"
        + ("core_" if e["module"] == "HMath.Algebra" else "api_")
        + ("new_" if e["constructor"] else "")
        + G.snake(e["name"])
    )


def decode(spec, value, wire=None):
    head, *args = spec
    if head in ("a", "s"):
        return "readWire " + wire + " " + value
    if head == "v":
        return "readList(readWire " + wire + ") " + value
    if head == "Additive":
        return "asAdditiveWire " + wire + " " + value
    if head == "list":
        return "readList(\\x -> " + decode(args[0], "x", wire) + ") " + value
    if head == "tuple":
        variables = [G.fresh("part") for _ in args]
        return (
            "(V.asTuple "
            + str(len(args))
            + " "
            + value
            + " >>= \\parts -> case parts of {["
            + ",".join(variables)
            + "] -> ("
            + "," * (len(args) - 1)
            + ") <$> "
            + " <*> ".join(
                "(" + decode(s, v, wire) + ")" for s, v in zip(args, variables)
            )
            + ';_ -> V.invalid "tuple arity differs"})'
        )
    if head in ("Modular", "FiniteField", "FieldElement"):
        return "as" + head + " " + value
    if head == "Exact":
        return 'unbox "HMath.API.Algebra.Exact" ' + value
    if head == "Rational":
        return "V.asScalar " + value
    if head == "MathError":
        raise ValueError(spec)
    return F.decode(spec, value, {}).replace("X.", "V.")


def encode(spec, value, wire=None, domain=None):
    head, *args = spec
    if head in ("a", "s"):
        return "writeWire " + wire + " " + value
    if head == "v":
        return "list(writeWire " + wire + ") " + value
    if head == "Additive":
        return "pure(additive " + domain + " " + value + ")"
    if head == "Either":
        return (
            "source "
            + value
            + " >>= \\result -> "
            + encode(args[1], "result", wire, domain)
        )
    if head == "list":
        return "list(\\x -> " + encode(args[0], "x", wire, domain) + ") " + value
    if head == "tuple":
        vs = [G.fresh("field") for _ in args]
        return (
            "(\\("
            + ",".join(vs)
            + ") -> V.Tuple <$> sequence ["
            + ",".join(encode(s, v, wire, domain) for s, v in zip(args, vs))
            + "]) "
            + value
        )
    if head in ("Modular", "FiniteField", "FieldElement", "Exact"):
        return (
            "pure("
            + G.snake(head)
            .replace("finite_field", "finiteField")
            .replace("field_element", "fieldElement")
            + " "
            + value
            + ")"
        )
    return F.encode(spec, value, {}).replace("X.", "V.")


def native_body(e):
    name = e["name"]
    selected = mode(e)
    alias = MODULES[e["module"]][0]
    if selected == "module":
        return "withModule prototype $ \\wire -> do\n" + module_body(e)
    if selected in ("old", "api"):
        domain = "Old" if selected == "old" else "API"
        lines = ["with" + domain + " prototype $ \\domain -> do"]
        if name not in ("groupIdentity", "machineEpsilon"):
            lines.append(
                "    let wire=" + selected.lower() + "Wire domain"
                if selected == "old"
                else "    let wire=apiWire domain"
            )
        specs = e["args"]
        if name == "groupLaws":
            specs = [["list", ["Additive", ["a"]]]]
        for i, s in enumerate(specs):
            lines.append("    x" + str(i) + " <- " + decode(s, "a" + str(i), "wire"))
        result = e["result"]
        call = (
            "("
            + alias
            + "."
            + name
            + (" " + " ".join("x" + str(i) for i in range(len(specs))) if specs else "")
            + ")"
        )
        if name == "machineEpsilon":
            call = "(apiEpsilon domain)"
        out = encode(result, call, "wire", "domain")
        if selected == "old" and name in ("inverseField", "fieldLaws"):
            out = "oldField domain $ " + out
        if selected == "api" and name == "invert":
            out = "apiField domain $ " + out
        if selected == "api" and name in ("machineEpsilon", "finiteScalar"):
            out = "apiFloating domain $ " + out
        # General Group a signatures are represented by the original Additive
        # instance. No other Group instances exist in the source tree.
        if name == "getAdditive":
            out = "writeWire wire (A.getAdditive x0)"
        if name == "groupIdentity":
            out = "pure(additive domain A.groupIdentity)"
        if name == "groupLaws":
            out = "pairs(A.groupLaws x0)"
        lines.append("    " + out)
        return "\n".join(lines)
    specials = {
        "matrixDimensions": "withMatrix a0 $ \\_ matrixValue -> pure(\\(r,c) -> V.Tuple[V.Index r,V.Index c]) <*> pure(P.matrixDimensions matrixValue)",
        "matrixElements": "withMatrix a0 $ \\wire matrixValue -> list(writeWire wire)(P.matrixElements matrixValue)",
        "matrixConstruct": "do {r <- V.asIndex a0;c <- V.asIndex a1;xs <- V.asList a2;matrixConstruct prototype r c xs}",
        "tensorDimensions": "tensorDimensions a0",
        "tensorElements": "tensorElements a0",
        "tensorConstruct": "do {ds <- V.asList a0 >>= mapM V.asIndex;xs <- V.asList a1;tensorConstruct prototype ds xs}",
        "vectorPlus": "vectorPlus prototype a0 a1",
        "vectorScale": "vectorScale prototype a0 a1",
        "differential": "differential a0",
    }
    if e["module"] == "HMath.API.Algebra" and name in specials:
        return specials[name]
    lines = ["do"]
    for i, s in enumerate(e["args"]):
        lines.append("    x" + str(i) + " <- " + decode(s, "a" + str(i)))
    call = (
        "("
        + alias
        + "."
        + name
        + " "
        + " ".join("x" + str(i) for i in range(len(e["args"])))
        + ")"
    )
    lines.append("    " + encode(e["result"], call))
    return "\n".join(lines)


def module_body(e):
    name = e["name"]
    bodies = {
        "moduleScale": "x <- readWire wire a0;xs <- readList(readWire wire)a1;list(writeWire wire)(A.moduleScale x xs)",
        "moduleAdd": "xs <- readList(readWire wire)a0;ys <- readList(readWire wire)a1;source(A.moduleAdd xs ys) >>= list(writeWire wire)",
        "moduleLaws": "xs <- readList(readWire wire)a0;ys <- readList(readList(readWire wire))a1;pairs(A.moduleLaws xs ys)",
        "linearCombination": 'zeroVector <- readList(readWire wire)a0;terms <- readList(\\v -> V.asTuple 2 v >>= \\parts -> case parts of {[s,x] -> (,) <$>readWire wire s <*>readList(readWire wire)x;_ -> V.invalid "module term arity differs"})a1;source(A.linearCombination zeroVector terms) >>= list(writeWire wire)',
    }
    return "    " + bodies[name]


def outputs():
    G._COUNTER = 0
    entries, types = specification()
    numeric_sources = {
        entry["module"] + "." + entry["name"]
        for entry in json.loads((ROOT / "bindings/schema/numeric.json").read_text())[
            "functions"
        ]
    }
    hs = [
        """{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE ScopedTypeVariables #-}
-- SPDX-License-Identifier: MPL-2.0
-- Generated direct calls into the two distinct original algebra interfaces.
module HMath.FFI.AlgebraAll where
import Prelude hiding(readList)
import Foreign
import Foreign.C
import qualified HMath.Algebra as A
import qualified HMath.API.Algebra as P
import qualified HMath.FFI.Value as V
import qualified HMath.FFI.Boundary as Boundary
import HMath.FFI.Coefficient
import HMath.FFI.FoundationCodec
import HMath.FFI.AlgebraCodec
import qualified HMath.FFI.TensorCodec as TensorCodec
apply :: Int -> [V.Value] -> IO V.Value
apply operation args=case(operation,args) of
"""
    ]
    header = [
        """/* SPDX-License-Identifier: MPL-2.0 */
/* Generated original algebra typeclass instances and checked field APIs. */
#ifndef HMATH_ALGEBRA_H
#define HMATH_ALGEBRA_H
#include "hmath_foundation.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Explicit prototype parameters select actual source instances. They are not
 * conversions. Old Algebra: Integer/Rational/Polynomial, Additive groups and
 * Integer/Rational list modules. API.Algebra: Integer/Rational/Float/Double/
 * Complex Double/Exact; unsupported original instances return Unsupported.
 * Exact has no Num instance. Inputs borrow; outputs own an independent Value.
 * Failure leaves *out untouched; release outputs using hmath_value_release. */
"""
    ]
    c = [
        '/* SPDX-License-Identifier: MPL-2.0 */\n#include "hmath_algebra.h"\n#include "value_internal.h"\nextern int hm_algebra_apply(int,void *const *,size_t,void **);\n'
    ]
    py = {
        m: [
            "# SPDX-License-Identifier: MPL-2.0\n# Generated original algebra interface.\nfrom ._algebra_base import invoke,initialize\nfrom ._foundation_base import FoundationValue,register\n"
        ]
        for m in MODULES
    }
    exports = {m: [] for m in MODULES}
    mappings = []
    docs = [
        "# Original algebra interfaces\n\nThe two source modules define different classes and instances. Their functions remain separate. Prototypes select the actual original type, without adding arithmetic instances or converting through Double. `Exact` wraps Rational and deliberately has no Num instance. Old Algebra supports Integer/Rational/Polynomial rings, Rational fields, Additive groups and Integer/Rational list modules. API.Algebra supports Integer/Rational/Float/Double/Complex Double/Exact; Field excludes Integer and FloatingPoint is Float/Double/Complex Double. Source errors, modular ring identity, finite-field proof budgets and checked inversion are unchanged. Values own references and support close/context management.\n\n"
    ]
    for name, t in types.items():
        m = t["module"]
        source = m + "." + name
        exports[m].append(name)
        ctor = next(
            (
                e
                for e in entries
                if e["constructor"] and e["name"] == name and e["module"] == m
            ),
            None,
        )
        py[m].append(
            "\nclass "
            + name
            + '(FoundationValue):\n    """Original '
            + source
            + ' owner."""\n    _source_type='
            + repr(source)
            + "\n"
        )
        if ctor:
            params = ["argument" + str(i + 1) for i in range(len(ctor["args"]))]
            py[m].append(
                "    def __init__(self"
                + (", " + ",".join(params) if params else "")
                + ", *, dtype=None):\n        initialize(self,"
                + repr(sym(ctor))
                + ","
                + repr(ctor["args"])
                + ",["
                + ",".join(params)
                + "],"
                + repr(mode(ctor))
                + ",dtype)\n"
            )
        if name == "Exact":
            py[m].append(
                "    @property\n    def value(self):\n        return get_exact(self)\n"
                "    @property\n    def element_type(self):\n        return exact_element_type()\n"
            )
        if name == "Additive":
            py[m].append(
                "    @property\n    def value(self):\n        return get_additive(self)\n"
            )
        py[m].append("register(" + repr(source) + "," + name + ")\n")
    for opcode, e in enumerate(entries):
        args = ["a" + str(i) for i in range(len(e["args"]))]
        if mode(e) != "value":
            args = ["prototype"] + args
        hs.append(
            "    ("
            + str(opcode)
            + ",["
            + ",".join(args)
            + "]) -> "
            + native_body(e).replace("\n", "\n        ")
            + "\n"
        )
        parameters = (
            ["hmath_context *context"]
            + ["const hmath_value *" + a for a in args]
            + ["hmath_value **out"]
        )
        prototype = "hmath_status " + sym(e) + "(" + ",".join(parameters) + ")"
        header.append(
            "/* "
            + e["module"]
            + "."
            + e["name"]
            + " */\nHMATH_API "
            + prototype
            + ";\n"
        )
        c.append(
            prototype
            + " {\n    if(!out"
            + "".join(" || !" + a for a in args)
            + ')return hm_error(HMATH_INVALID_ARGUMENT,"NULL algebra argument");\n    hmath_value *result;hmath_status status=hm_value_begin(context,&result);if(status)return status;\n'
        )
        if args:
            c.append(
                "    void *args[]={"
                + ",".join("hm_value_stable(" + a + ")" for a in args)
                + "};\n"
            )
        c.append(
            "    return hm_value_finish(result,hm_algebra_apply("
            + str(opcode)
            + ","
            + ("args" if args else "NULL")
            + ","
            + str(len(args))
            + ",&result->stable),out);\n}\n"
        )
        name = e["name"] if e["constructor"] else G.snake(e["name"])
        m = e["module"]
        exports[m].append(name)
        if not e["constructor"]:
            params = ["argument" + str(i + 1) for i in range(len(e["args"]))]
            typed = mode(e) != "value"
            py[m].append(
                "\ndef "
                + name
                + "("
                + ",".join(params)
                + (", " if params and typed else "")
                + ("*, dtype=None" if typed else "")
                + "):\n    "
                + repr(G.source_prose(e))
                + "\n    return invoke("
                + repr(sym(e))
                + ","
                + repr(e["args"])
                + ",["
                + ",".join(params)
                + "],"
                + repr(mode(e))
                + ("," + "dtype" if typed else "")
                + ")\n"
            )
        if e["module"] + "." + e["name"] not in numeric_sources:
            mappings.append(
                {
                    "symbol": e["module"] + "." + e["name"],
                    "c": [sym(e)],
                    "python": "hmath." + MODULES[m][1] + "." + name,
                    "specializations": [
                        "actual original instances; exact domain/dictionary retained; no invented typeclass instances"
                    ],
                }
            )
        docs.append(
            "## `"
            + MODULES[m][1]
            + "."
            + name
            + "`\n\n"
            + G.source_prose(e)
            + "\n\nOriginal signature: `"
            + e["signature"]
            + "`. "
            + (
                "The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. "
                if mode(e) != "value"
                else ""
            )
            + "Borrowed source-order arguments; owned successful output; failure leaves the output untouched.\n\n"
        )
    for m, classes in CLASSES.items():
        for name, methods in classes.items():
            exports[m].append(name)
            py[m].append(
                "\nclass "
                + name
                + ':\n    """Original '
                + m
                + "."
                + name
                + ' interface; methods select supported source instances."""\n'
            )
            if methods:
                for method in methods:
                    py[m].append(
                        "    "
                        + G.snake(method)
                        + "=staticmethod("
                        + G.snake(method)
                        + ")\n"
                    )
            else:
                py[m].append("    pass\n")
            mappings.append(
                {
                    "symbol": m + "." + name,
                    "c": [
                        sym(e)
                        for e in entries
                        if e["module"] == m and e["name"] in methods
                    ]
                    or ["hmath_value", "hmath_value_release"],
                    "python": "hmath." + MODULES[m][1] + "." + name,
                    "specializations": [
                        "original open class/associated type; adapter exposes documented existing concrete instances"
                    ],
                }
            )
    covered = {m["symbol"] for m in mappings}
    for name, t in types.items():
        if t["module"] + "." + name not in covered:
            mappings.append(
                {
                    "symbol": t["module"] + "." + name,
                    "c": ["hmath_value", "hmath_value_release"],
                    "python": "hmath." + MODULES[t["module"]][1] + "." + name,
                    "specializations": ["original opaque owned type"],
                }
            )
    py["HMath.API.Algebra"].append(
        '\ndef exact_element_type():\n    """Typed structural Exact element prototype for ordinary Tensor/Vector APIs."""\n    from ._value import decode,invoke as native_invoke\n    return decode(native_invoke("hmath_algebra_api_exact_element_type"))\n'
    )
    exports["HMath.API.Algebra"].append("exact_element_type")
    header.append(
        "HMATH_API hmath_status hmath_algebra_api_exact_element_type(hmath_context *context,hmath_value **out);\n"
    )
    c.append(
        'hmath_status hmath_algebra_api_exact_element_type(hmath_context *context,hmath_value **out) {\n    if(!out)return hm_error(HMATH_INVALID_ARGUMENT,"NULL element type output");\n    hmath_value *result;hmath_status status=hm_value_begin(context,&result);if(status)return status;\n    return hm_value_finish(result,hm_algebra_apply(-1,NULL,0,&result->stable),out);\n}\n'
    )
    hs.append("""    (-1,[]) -> pure(TensorCodec.prototype exactElement)
    _ -> V.invalid "invalid algebra operation/arity"
foreign export ccall "hm_algebra_apply" ffiApply :: CInt -> Ptr(StablePtr V.Value) -> CSize -> Ptr(StablePtr V.Value) -> IO CInt
ffiApply :: CInt -> Ptr(StablePtr V.Value) -> CSize -> Ptr(StablePtr V.Value) -> IO CInt
ffiApply operation input count out=foundationBoundary $ do
    values <- peekArray(fromIntegral count) input >>= mapM deRefStablePtr
    value <- apply(fromIntegral operation) values
    Boundary.checked(Right())(const(V.publish value out))
""")
    header.append("#ifdef __cplusplus\n}\n#endif\n#endif\n")
    result = {
        "src/HMath/FFI/AlgebraAll.hs": "".join(hs),
        "include/hmath_algebra.h": "".join(header),
        "cbits/algebra.c": "".join(c),
        "bindings/schema/algebra-functions.json": json.dumps(
            {"functions": entries, "types": types}, indent=2
        )
        + "\n",
        "bindings/schema/algebra-objects.json": json.dumps(
            {"schema": 1, "bindings": sorted(mappings, key=lambda x: x["symbol"])},
            indent=2,
        )
        + "\n",
        "docs/reference/algebra-values.md": "".join(docs),
    }
    for m, data in py.items():
        data.append("\n__all__=" + repr(sorted(set(exports[m]))) + "\n")
        result["bindings/python/_hmath_native/" + MODULES[m][1] + ".py"] = fmt(
            "".join(data), MODULES[m][1] + ".py"
        )
    return {
        name: F.format_c(data) if name.endswith((".c", ".h")) else data
        for name, data in result.items()
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
