# SPDX-License-Identifier: MPL-2.0
"""Direct persistent data, discrete, combinatorial and convergence adapters."""

import argparse
import json
import keyword
import subprocess
from pathlib import Path

import generate_linear_bindings as G
from generate_stochastic_bindings import fmt

ROOT = Path(__file__).resolve().parent.parent
MODULES = {
    "HMath.DataStructure": ("D", "data_structures", "datastructure"),
    "HMath.Discrete": ("S", "discrete_values", "discrete"),
    "HMath.Algorithms": ("A", "algorithm_values", "algorithms"),
    "HMath.Combinatorics": ("C", "combinatorics_values", "combinatorics"),
    "HMath.API.Convergence": ("V", "convergence_values", "convergence"),
}


def format_c(source):
    return subprocess.run(
        ["clang-format"], input=source, text=True, capture_output=True, check=True
    ).stdout


def normalized(spec):
    return [spec[0].lstrip("!"), *[normalized(s) for s in spec[1:]]]


def specification():
    old, aliases = G.MODULES, G.ALIASES
    G.MODULES = {m: (a, n) for m, (a, n, _public) in MODULES.items()}
    try:
        entries, types, fields, missing = G.signatures()
    finally:
        G.MODULES, G.ALIASES = old, aliases
    missing = [m for m in missing if m != "HMath.API.Convergence.Converged"]
    if missing:
        raise ValueError(missing)
    oldbindings = {
        x["module"] + "." + x["name"]
        for x in json.loads((ROOT / "bindings/schema/numeric.json").read_text())[
            "functions"
        ]
    }
    entries = [e for e in entries if e["module"] + "." + e["name"] not in oldbindings]
    for e in entries:
        e["args"] = [normalized(s) for s in e["args"]]
        e["result"] = normalized(e["result"])
    fields = {name: [(f, normalized(s)) for f, s in fs] for name, fs in fields.items()}
    entries.append(
        {
            "module": "HMath.API.Convergence",
            "name": "Converged",
            "args": [["Convergence", ["a"]]],
            "result": ["Maybe", ["a"]],
            "constraints": "",
            "signature": "Convergence a -> Maybe a (read-only source pattern)",
            "constructor": False,
        }
    )
    return entries, types, fields


def mode(entry):
    if (
        entry["module"] == "HMath.Combinatorics"
        and entry["name"] == "finiteDifferences"
    ):
        return "numeric"
    if "Eq a" in entry["constraints"]:
        return "equality"
    if entry["module"] == "HMath.DataStructure" and entry["name"] in (
        "reservoir",
        "reservoirAdd",
        "reservoirValues",
    ):
        return "equality"
    if entry["module"] == "HMath.API.Convergence" and entry["name"] not in (
        "fromMaybeError",
        "resultMaybe",
    ):
        return "equality"
    if "Ord a" in entry["constraints"] and not any(
        s[0] in ("Heap", "MultiSet") for s in entry["args"] + [entry["result"]]
    ):
        return "ordered"
    return "value"


def hstype(spec, types, element="X.Value"):
    head, *args = spec
    if head == "Heap":
        return "HeapState"
    if head == "MultiSet":
        return "MultiState"
    if head == "a":
        return element
    if head == "e":
        return "X.Value"
    if head == "list":
        return "[" + hstype(args[0], types, element) + "]"
    if head == "tuple":
        return "(" + ",".join(hstype(s, types, element) for s in args) + ")"
    if head == "function":
        return "(" + " -> ".join(hstype(s, types, element) for s in args) + ")"
    if head == "unit":
        return "()"
    name = (
        types[head]["alias"] + "." + head
        if head in types
        else "E.MathError"
        if head == "MathError"
        else head
    )
    return (
        "("
        + name
        + (" " + " ".join(hstype(s, types, element) for s in args) if args else "")
        + ")"
    )


def decode(spec, value, types, flavor="value"):
    head, *args = spec
    if head == "a":
        return {
            "value": "pure " + value,
            "ordered": "readOrdered witness " + value,
            "equality": "readEquality " + value,
            "numeric": "X.asScalar " + value,
        }[flavor]
    if head == "e":
        return "pure " + value
    if head == "Maybe":
        v = G.fresh("optional")
        return (
            "(asMaybeValue "
            + value
            + " >>= \\"
            + v
            + " -> case "
            + v
            + " of {Nothing -> pure Nothing;Just item -> Just <$> ("
            + decode(args[0], "item", types, flavor)
            + ")})"
        )
    if head == "Either":
        return "asEitherValue " + value
    if head == "function":
        variables = [G.fresh("callbackArg") for _ in args[:-1]]
        vals = [encode(s, v, types, flavor) for s, v in zip(args[:-1], variables)]
        statement = (
            "inputs <- sequence [" + ",".join(vals) + "];let { input=X.Tuple inputs }"
        )
        result = args[-1]
        call = (
            "checkedCallback "
            + value
            + " input (\\reply -> "
            + decode(result[2], "reply", types, flavor)
            + ")"
            if result[0] == "Either" and result[1] == ["MathError"]
            else "LC.callbackValue "
            + value
            + " input >>= \\reply -> "
            + decode(result, "reply", types, flavor)
        )
        return (
            "pure(\\"
            + " ".join(variables)
            + " -> unsafePerformIO $ do {"
            + statement
            + ";"
            + call
            + "})"
        )
    if head == "list":
        item = G.fresh("item")
        return (
            "X.asList "
            + value
            + " >>= mapM(\\"
            + item
            + " -> "
            + decode(args[0], item, types, flavor)
            + ")"
        )
    if head == "tuple":
        variables = [G.fresh("part") for _ in args]
        ls = G.fresh("parts")
        return (
            "(X.asTuple "
            + str(len(args))
            + " "
            + value
            + " >>= \\"
            + ls
            + " -> case "
            + ls
            + " of { ["
            + ",".join(variables)
            + "] -> ("
            + "," * (len(args) - 1)
            + ") <$> "
            + " <*> ".join(
                "(" + decode(s, v, types, flavor) + ")" for s, v in zip(args, variables)
            )
            + ';_ -> X.invalid "tuple arity differs"})'
        )
    if head in types:
        return 'unbox "' + types[head]["module"] + "." + head + '" ' + value
    if head == "Int":
        return "X.asIndex " + value
    if head in ("Integer", "Double", "Word64", "Rational"):
        return "X.asScalar " + value
    if head == "Bool":
        return "X.asBoolean " + value
    if head == "String":
        return "X.asText " + value
    raise ValueError(("decode", spec))


def encode(spec, value, types, flavor="value"):
    head, *args = spec
    if head == "a":
        return {
            "value": "pure " + value,
            "ordered": "writeOrdered " + value,
            "equality": "writeEquality " + value,
            "numeric": "pure(X.Scalar w " + value + ")",
        }[flavor]
    if head == "e":
        return "pure " + value
    if head == "Either":
        if args[0] != ["MathError"]:
            return "eitherValue " + value
        item = G.fresh("_result")
        return (
            "source "
            + value
            + " >>= \\"
            + item
            + " -> "
            + encode(args[1], item, types, flavor)
        )
    if head == "Maybe":
        item = G.fresh("item")
        return (
            "(case "
            + value
            + " of {Nothing -> pure X.None;Just "
            + item
            + " -> "
            + encode(args[0], item, types, flavor)
            + " >>= maybeValue . Just})"
        )
    if head == "list":
        item = G.fresh("item")
        return (
            "X.List <$>mapM(\\"
            + item
            + " -> "
            + encode(args[0], item, types, flavor)
            + ") "
            + value
        )
    if head == "tuple":
        variables = [G.fresh("part") for _ in args]
        return (
            "(\\("
            + ",".join(variables)
            + ") -> X.Tuple <$> sequence ["
            + ",".join(encode(s, v, types, flavor) for s, v in zip(args, variables))
            + "]) "
            + value
        )
    if head in types:
        return "encode" + head + " " + value
    if head == "Int":
        return "pure(X.Index " + value + ")"
    if head in ("Integer", "Double", "Word64", "Rational"):
        return (
            "pure(X.Scalar "
            + {
                "Integer": "SInteger",
                "Double": "SDouble",
                "Word64": "SWord64",
                "Rational": "SRational",
            }[head]
            + " "
            + value
            + ")"
        )
    if head == "Bool":
        return "pure(X.Boolean " + value + ")"
    if head == "String":
        return "pure(X.Text " + value + ")"
    if head == "unit":
        return "pure X.None"
    raise ValueError(("encode", spec))


def sym(entry):
    return (
        "hmath_foundation_"
        + MODULES[entry["module"]][2]
        + "_"
        + ("new_" if entry["constructor"] else "")
        + G.snake(entry["name"])
        + ("_typed" if entry.get("typed_order") else "")
    )


def native(entries, types, fields):
    entries = [
        *entries,
        *[
            {**entry, "typed_order": True}
            for entry in entries
            if mode(entry) == "ordered"
        ],
    ]
    hs = [
        """{-# LANGUAGE GADTs #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- Generated original-operation adapters. No algorithm implementation here.
module HMath.FFI.Foundation where
import Control.Exception (evaluate)
import Foreign
import Foreign.C
import System.IO.Unsafe (unsafePerformIO)
import qualified HMath.Error as E
import HMath.FFI.Coefficient
import HMath.FFI.FoundationCodec
import HMath.FFI.Ordering
import qualified HMath.FFI.LinearCodec as LC
import qualified HMath.FFI.Value as X
import qualified HMath.FFI.Boundary as Boundary
"""
    ]
    for m, (alias, _ns, _public) in MODULES.items():
        hs.append("import qualified " + m + " as " + alias + "\n")
    for name, t in types.items():
        typ = hstype(
            [name, *[[p] for p in t["params"]]],
            types,
            "EqualityValue" if name in ("Reservoir", "Convergence") else "X.Value",
        )
        hs.append(
            "\nencode"
            + name
            + " :: "
            + typ
            + " -> IO X.Value\nencode"
            + name
            + ' value=pure(opaqueEq "'
            + t["module"]
            + "."
            + name
            + '" (-1) value force view)\n  where\n    force='
        )
        if fields[name]:
            hs.append(
                "forceFields ["
                + ",".join(
                    encode(
                        s,
                        "(" + t["alias"] + "." + f + " value)",
                        types,
                        "equality" if name in ("Reservoir", "Convergence") else "value",
                    )
                    for f, s in fields[name]
                )
                + "]\n"
            )
        elif name == "MultiSet":
            hs.append(
                "multisetEntries value >>= \\xs -> forceFields ["
                + encode(["list", ["tuple", ["a"], ["Integer"]]], "xs", types)
                + "]\n"
            )
        else:
            hs.append("evaluate value >> pure()\n")
        constructors = [
            e for e in entries if e["constructor"] and e["result"][0] == name
        ]
        if constructors:
            hs.append("    view=case value of\n")
            for e in constructors:
                variables = [G.fresh("field") for _ in e["args"]]
                hs.append(
                    "        "
                    + t["alias"]
                    + "."
                    + e["name"]
                    + " "
                    + " ".join(variables)
                    + " -> do\n            values <- sequence ["
                    + ",".join(
                        encode(
                            s,
                            v,
                            types,
                            "equality"
                            if name in ("Reservoir", "Convergence")
                            else "value",
                        )
                        for s, v in zip(e["args"], variables)
                    )
                    + ']\n            pure(X.Tuple[X.Text "'
                    + e["name"]
                    + '",X.Tuple values])\n'
                )
        else:
            hs.append(
                '    view=X.unsupported "original abstract type has no public constructor fields"\n'
            )
    hs.append(
        "\napply :: Int -> [X.Value] -> IO X.Value\napply operation args=case(operation,args) of\n"
    )
    h = [
        """/* SPDX-License-Identifier: MPL-2.0 */
/* Generated by tools/generate_foundation_bindings.py. */
#ifndef HMATH_FOUNDATION_H
#define HMATH_FOUNDATION_H
#include "hmath_linear.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Original persistent data/discrete/combinatorial/convergence operations.
 * Opaque kind400 records own independent references; inputs borrow for the call.
 * Value callback101 transports original argument tuples; checked status11
 * becomes genuine Left, pure callback failures abort. Generic Either results
 * retain explicit Left/Right; optional Just(None) retains its distinction.
 * No arbitrary precision integer, original budget, order, callback or error
 * contract is replaced. Release each owned output with hmath_value_release. */
HMATH_API hmath_status hmath_foundation_object_type(hmath_context *context,const hmath_value *value,hmath_value **out);
HMATH_API hmath_status hmath_foundation_object_parts(hmath_context *context,const hmath_value *value,hmath_value **out);
HMATH_API hmath_status hmath_foundation_left(hmath_context *context,const hmath_value *value,hmath_value **out);
HMATH_API hmath_status hmath_foundation_right(hmath_context *context,const hmath_value *value,hmath_value **out);
HMATH_API hmath_status hmath_foundation_just(hmath_context *context,const hmath_value *value,hmath_value **out);
"""
    ]
    c = [
        '/* SPDX-License-Identifier: MPL-2.0 */\n/* Generated; original operation dispatch only. */\n#include "hmath_foundation.h"\n#include "value_internal.h"\nextern int hm_foundation_apply(int,void *const *,size_t,void **);\n'
    ]
    heap_calls = {
        "emptyHeap": "pure heapEmpty",
        "heapFromList": "heapFromList a0Value",
        "heapInsert": "heapInsert a0Value a1Value",
        "heapPop": "heapPop a0Value",
    }
    multis = {
        "multiset": "multiset a0Value",
        "multiplicity": "multiplicity a0Value a1Value",
        "multisetEntries": "multisetEntries a0Value",
        "multisetInsert": "multisetInsert a0Value a1Value",
        "multisetDelete": "multisetDelete a0Value a1Value",
        "multisetUnion": "multisetBinary S.multisetUnion a0Value a1Value",
        "multisetIntersection": "multisetBinary S.multisetIntersection a0Value a1Value",
        "multisetDifference": "multisetBinary S.multisetDifference a0Value a1Value",
    }
    for opcode, e in enumerate(entries):
        flavor = mode(e)
        variables = ["a" + str(i) for i in range(len(e["args"]))]
        if flavor == "numeric" or e.get("typed_order"):
            variables = ["prototype"] + variables
        hs.append(
            "    ("
            + str(opcode)
            + ",["
            + ",".join(variables)
            + "]) -> "
            + (
                "LC.withWitness prototype $ \\(w::ScalarType a) -> "
                if flavor == "numeric"
                else ""
            )
            + "do\n"
        )
        if flavor == "ordered":
            # Only nonpersistent arrays use this branch; every order operation's
            # polymorphic elements are collected before selecting one real Ord.
            examples = []
            for i, spec in enumerate(e["args"]):
                if spec == ["a"]:
                    examples.append("pure [a" + str(i) + "]")
                elif spec == ["list", ["a"]]:
                    examples.append("X.asList a" + str(i))
            if e.get("typed_order"):
                hs.append(
                    "        witness <- orderedWith [foundationOrdering][prototype]\n"
                )
            else:
                hs.append(
                    "        examples <- concat <$> sequence ["
                    + ",".join(examples)
                    + "]\n        witness <- if null examples then orderedFromPrototype(X.Scalar SInteger 0) else orderedWith [foundationOrdering] examples\n"
                )
        element = {
            "value": "X.Value",
            "ordered": "OrderedValue",
            "equality": "EqualityValue",
            "numeric": "a",
        }[flavor]
        for i, spec in enumerate(e["args"]):
            hs.append(
                "        a"
                + str(i)
                + "Value <- ("
                + decode(spec, "a" + str(i), types, flavor)
                + " :: IO "
                + hstype(spec, types, element)
                + ")\n"
            )
        call = (
            "("
            + MODULES[e["module"]][0]
            + "."
            + e["name"]
            + " "
            + " ".join("a" + str(i) + "Value" for i in range(len(e["args"])))
            + ")"
        )
        extra_io = False
        if e["module"] == "HMath.DataStructure" and e["name"] in heap_calls:
            call = "(" + heap_calls[e["name"]] + ")"
            extra_io = True
        if e["module"] == "HMath.Discrete" and e["name"] in multis:
            call = "(" + multis[e["name"]] + ")"
            extra_io = True
        if e["name"] == "Converged":
            call = "(case a0Value of V.Converged x -> Just x;_ -> Nothing)"
        result = e["result"]
        if extra_io:
            hs.append(
                "        "
                + call
                + " >>= \\result -> "
                + encode(result, "result", types, flavor)
                + "\n"
            )
        else:
            call = "(" + call + " :: " + hstype(result, types, element) + ")"
            hs.append("        " + encode(result, call, types, flavor) + "\n")
        parameters = (
            ["hmath_context *context"]
            + ["const hmath_value *" + v for v in variables]
            + ["hmath_value **out"]
        )
        proto = "hmath_status " + sym(e) + "(" + ", ".join(parameters) + ")"
        h.append(
            "/* " + e["module"] + "." + e["name"] + " */\nHMATH_API " + proto + ";\n"
        )
        c.append(
            proto
            + " {\n    if(!out"
            + "".join(" || !" + v for v in variables)
            + ')return hm_error(HMATH_INVALID_ARGUMENT,"NULL foundation argument");\n    hmath_value *result;hmath_status status=hm_value_begin(context,&result);if(status)return status;\n'
        )
        ptr = "NULL"
        if variables:
            c.append(
                "    void *args[]={"
                + ",".join("hm_value_stable(" + v + ")" for v in variables)
                + "};\n"
            )
            ptr = "args"
        c.append(
            "    return hm_value_finish(result,hm_foundation_apply("
            + str(opcode)
            + ","
            + ptr
            + ","
            + str(len(variables))
            + ",&result->stable),out);\n}\n"
        )
    hs.append("""    (-1,[value]) -> X.Text <$> objectName value
    (-2,[value]) -> objectParts value
    (-3,[value]) -> eitherValue(Left value)
    (-4,[value]) -> eitherValue(Right value)
    (-5,[value]) -> maybeValue(Just value)
    (-6,[value]) -> orderedType value
    (-7,[value]) -> optionalType value
    (-8,[prototype,values]) -> X.asList values >>= heapFromListTyped prototype >>= encodeHeap
    (-9,[prototype,values]) -> X.asList values >>= multisetTyped prototype >>= encodeMultiSet
    _ -> X.invalid "invalid foundation operation/arity"
foreign export ccall "hm_foundation_apply" ffiApply :: CInt -> Ptr(StablePtr X.Value) -> CSize -> Ptr(StablePtr X.Value) -> IO CInt
ffiApply :: CInt -> Ptr(StablePtr X.Value) -> CSize -> Ptr(StablePtr X.Value) -> IO CInt
ffiApply operation input count out=foundationBoundary $ do
    values <- peekArray(fromIntegral count) input >>= mapM deRefStablePtr
    value <- apply(fromIntegral operation) values
    Boundary.checked(Right())(const(X.publish value out))
""")
    for name, opcode in [
        ("object_type", -1),
        ("object_parts", -2),
        ("left", -3),
        ("right", -4),
        ("just", -5),
        ("ordered_type", -6),
        ("optional_type", -7),
    ]:
        if opcode in (-6, -7):
            h.append(
                "HMATH_API hmath_status hmath_foundation_"
                + name
                + "(hmath_context *context,const hmath_value *value,hmath_value **out);\n"
            )
        c.append(
            "hmath_status hmath_foundation_"
            + name
            + '(hmath_context *context,const hmath_value *value,hmath_value **out) {\n    if(!value || !out)return hm_error(HMATH_INVALID_ARGUMENT,"NULL foundation query");\n    hmath_value *result;hmath_status status=hm_value_begin(context,&result);if(status)return status;\n    void *args[]={hm_value_stable(value)};\n    return hm_value_finish(result,hm_foundation_apply('
            + str(opcode)
            + ",args,1,&result->stable),out);\n}\n"
        )
    for name, opcode in [("heap_from_list_typed", -8), ("multiset_typed", -9)]:
        prototype = (
            "hmath_status hmath_foundation_"
            + name
            + "(hmath_context *context,const hmath_value *prototype,const hmath_value *values,hmath_value **out)"
        )
        h.append("HMATH_API " + prototype + ";\n")
        c.append(
            prototype
            + ' {\n    if(!prototype || !values || !out)return hm_error(HMATH_INVALID_ARGUMENT,"NULL typed container argument");\n    hmath_value *result;hmath_status status=hm_value_begin(context,&result);if(status)return status;\n    void *args[]={hm_value_stable(prototype),hm_value_stable(values)};\n    return hm_value_finish(result,hm_foundation_apply('
            + str(opcode)
            + ",args,2,&result->stable),out);\n}\n"
        )
    h.append("#ifdef __cplusplus\n}\n#endif\n#endif\n")
    return {
        "src/HMath/FFI/Foundation.hs": "".join(hs),
        "include/hmath_foundation.h": "".join(h),
        "cbits/foundation.c": "".join(c),
    }


def outputs():
    G._COUNTER = 0
    entries, types, fields = specification()
    result = native(entries, types, fields)
    result.update(frontend(entries, types, fields))
    result["bindings/schema/foundation-functions.json"] = (
        json.dumps({"functions": entries, "types": types, "fields": fields}, indent=2)
        + "\n"
    )
    return {
        name: format_c(data) if name.endswith((".c", ".h")) else data
        for name, data in result.items()
    }


def pyname(entry, types):
    if entry["constructor"] and entry["name"] in types:
        return entry["name"]
    name = G.snake(entry["name"])
    return {"and": "logical_and", "or": "logical_or", "not": "logical_not"}.get(
        name, name + "_op" if keyword.iskeyword(name) else name
    )


def frontend(entries, types, fields):
    py = {
        m: [
            '# SPDX-License-Identifier: MPL-2.0\n# Generated by tools/generate_foundation_bindings.py.\n"""Original '
            + m
            + ' public functions and immutable values."""\nfrom ._foundation_base import FoundationValue,_invoke,register\n'
        ]
        for m in MODULES
    }
    public = {m: [] for m in MODULES}
    mappings = []
    covered = set()
    docs = [
        "# Foundation, discrete structures and convergence\n\nThese functions call the original Haskell algorithms. Persistent heaps/multisets retain the actual original element ordering dictionary; exact integers, coefficient dtypes, strings, tuples and registered mathematical values are not converted through FP64. Sampling/combinatorial output limits, bit widths, logic depth/input caps, resource defaults and source error conventions remain unchanged. Objects own independent immutable references and support `close()`/context management.\n\nGeneric checked callbacks use plain successful return values and raise a `MathError` to return source Left. Pure callbacks abort on failure. Unexpected Python exceptions are rethrown after native cleanup. Callback owners are retained transitively. Convergence reports retain their estimate even when iteration/stagnation limits stop execution; inspect `stop_reason` or use `require_convergence`. Generic Either results use explicit Left/Right owners; optional Just(None) is preserved as a Just owner.\n\n"
    ]
    docs.append(
        "## Ordered element prototypes\n\nOrd operations infer an actual Haskell dictionary from the supplied values. For all-None or recursively empty inputs, supply an explicit `prototype=`; it selects a type without adding data to the source algorithm. C uses the corresponding `_typed` overload. `ordered_type(example)` retains a representative original Ord dictionary and `optional_type(prototype)` constructs the original `Ord (Maybe a)` dictionary, including nesting. Empty heaps/multisets normally defer their dictionary until the first element arrives.\n\n```python\nfrom hmath import convergence, datastructure\n\nwith convergence.optional_type(0) as optional_integer:\n    with datastructure.heap_from_list([None, None], prototype=optional_integer) as heap:\n        first, remaining = datastructure.heap_pop(heap)\n        assert first is None\n        remaining.close()\n```\n\n`None` represents Nothing; `convergence.just(None)` distinguishes Just Nothing when optional layers nest. Generic Either values retain explicit Left/Right via `left`, `right`, and `.parts`. Prototypes and every returned owner support `close()`/context management. Equality-dependent grouping uses original dictionaries for supported scalar/recursive values, Foundation records, Polynomial/PowerSeries/RationalFunction, numeric/Bool/String/Exact Matrix and Tensor, and original AD.Dual full-field equality. NaNs and tensor views retain their source equality behavior. This finite transport does not invent Eq/Ord for arbitrary custom Haskell types.\n\n"
    )
    constructors = {
        e["name"]: e for e in entries if e["constructor"] and e["name"] in types
    }
    lower = {
        "Fenwick": "fenwick",
        "SegmentTree": "segmentTree",
        "SparseTable": "sparseTable",
        "DisjointSparseTable": "disjointSparseTable",
        "Heap": "heapFromList",
        "BinaryHeap": "binaryHeap",
        "IndexedHeap": "indexedHeap",
        "UnionFind": "unionFind",
        "Bloom": "bloom",
        "CountMin": "countMin",
        "HyperLogLog": "hyperLogLog",
        "Reservoir": "reservoir",
        "OnlineQuantiles": "onlineQuantiles",
        "MultiSet": "multiset",
        "BitSet": "bitSet",
    }
    for name, t in types.items():
        m = t["module"]
        source = m + "." + name
        public[m].append(name)
        py[m].append(
            "\nclass "
            + name
            + '(FoundationValue):\n    """Original '
            + source
            + ' immutable owner."""\n    _source_type='
            + repr(source)
            + "\n"
        )
        constructor = constructors.get(name)
        if name in lower:
            constructor = next(
                e for e in entries if e["module"] == m and e["name"] == lower[name]
            )
        if constructor:
            typed_container = name in ("Heap", "MultiSet")
            specs = constructor["args"]
            params = (
                [G.snake(f) for f, _ in fields[name]]
                if fields[name]
                else ["argument" + str(i + 1) for i in range(len(specs))]
            )
            py[m].append(
                "    def __init__(self"
                + (", " + ", ".join(params) if params else "")
                + (", *, prototype=None" if typed_container else "")
                + "):\n        self._initialize("
                + repr(sym(constructor))
                + ", "
                + repr(specs)
                + ", ["
                + ", ".join(params)
                + "], "
                + repr(mode(constructor))
                + (", prototype=prototype" if typed_container else "")
                + ")\n"
            )
        for field, _spec in fields[name]:
            entry = next(e for e in entries if e["module"] == m and e["name"] == field)
            py[m].append(
                "    @property\n    def "
                + G.snake(field)
                + "(self):\n        return _invoke("
                + repr(sym(entry))
                + ", "
                + repr(entry["args"])
                + ", [self], "
                + repr(mode(entry))
                + ")\n"
            )
        py[m].append("register(" + repr(source) + ", " + name + ")\n")
    for entry in entries:
        m = entry["module"]
        name = pyname(entry, types)
        record = entry["constructor"] and entry["name"] in types
        if not record:
            typed_order = mode(entry) == "ordered" or entry["name"] in (
                "heapFromList",
                "multiset",
            )
            params = ["argument" + str(i + 1) for i in range(len(entry["args"]))]
            public[m].append(name)
            signature = ", ".join(params) + (
                ", *, dtype=None"
                if mode(entry) == "numeric"
                else ", *, prototype=None"
                if typed_order
                else ""
            )
            py[m].append(
                "\ndef "
                + name
                + "("
                + signature
                + "):\n    "
                + repr(G.source_prose(entry))
                + "\n    return _invoke("
                + repr(sym(entry))
                + ", "
                + repr(entry["args"])
                + ", ["
                + ", ".join(params)
                + "], "
                + repr(mode(entry))
                + (", dtype" if mode(entry) == "numeric" else "")
                + (", prototype=prototype" if typed_order else "")
                + ")\n"
            )
        source = m + "." + entry["name"]
        covered.add(source)
        mappings.append(
            {
                "symbol": source,
                "c": [sym(entry)]
                + (
                    [sym(entry) + "_typed"]
                    if mode(entry) == "ordered"
                    else ["hmath_foundation_heap_from_list_typed"]
                    if entry["name"] == "heapFromList"
                    else ["hmath_foundation_multiset_typed"]
                    if entry["name"] == "multiset"
                    else []
                ),
                "python": "hmath." + MODULES[m][2] + "." + name,
                "specializations": [
                    "original algorithms; actual supported Ord/Eq dictionaries; no numeric conversion; complete public variants/fields"
                ],
            }
        )
        docs.append(
            "## `"
            + MODULES[m][2]
            + "."
            + name
            + "`\n\n"
            + G.source_prose(entry)
            + "\n\nOriginal signature: `"
            + entry["signature"]
            + "`. Constraints: `"
            + (entry["constraints"] or "none")
            + "`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.\n\n"
        )
    for name, t in types.items():
        source = t["module"] + "." + name
        if source not in covered:
            mappings.append(
                {
                    "symbol": source,
                    "c": ["hmath_value", "hmath_value_release"],
                    "python": "hmath." + MODULES[t["module"]][2] + "." + name,
                    "specializations": [
                        "original immutable persistent container; kind400 source subtype"
                    ],
                }
            )
    py["HMath.API.Convergence"].append(
        "\nfrom ._foundation_base import Either,Just,OrderedType,left,right,just,ordered_type,optional_type\n"
    )
    public["HMath.API.Convergence"].extend(
        [
            "Either",
            "Just",
            "OrderedType",
            "left",
            "right",
            "just",
            "ordered_type",
            "optional_type",
        ]
    )
    result = {
        "bindings/schema/foundation-objects.json": json.dumps(
            {"schema": 1, "bindings": sorted(mappings, key=lambda x: x["symbol"])},
            indent=2,
        )
        + "\n",
        "docs/reference/foundation.md": "".join(docs),
    }
    for m, parts in py.items():
        parts.append("\n__all__=" + repr(sorted(set(public[m]))) + "\n")
        result["bindings/python/_hmath_native/" + MODULES[m][1] + ".py"] = fmt(
            "".join(parts), MODULES[m][1] + ".py"
        )
    return result


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
