# SPDX-License-Identifier: MPL-2.0
"""Original Random, Probability and remaining advanced-statistics adapters."""

import argparse
import json
import subprocess
from pathlib import Path

import generate_linear_bindings as G

ROOT = Path(__file__).resolve().parent.parent
MODULES = {
    "HMath.Random": ("R", "random_values", "random"),
    "HMath.Probability": ("P", "probability_values", "probability"),
    "HMath.Statistics.Advanced": ("S", "statistics_values", "statistics_advanced"),
}
TAGS = {
    "RNG": 240,
    "Generator": 241,
    "AliasTable": 242,
    "Distribution": 243,
    "Markov": 244,
    "HMM": 245,
    "Streaming": 246,
    "TestResult": 247,
}


def specification():
    previous_modules, previous_aliases = G.MODULES, G.ALIASES
    G.MODULES = {m: (a, n) for m, (a, n, _public) in MODULES.items()}
    G.ALIASES = {
        **previous_aliases,
        "R.RNG": "RNG",
        "R.Generator": "Generator",
        "P.Distribution": "Distribution",
    }
    try:
        entries, types, fields, missing = G.signatures()
    finally:
        G.MODULES, G.ALIASES = previous_modules, previous_aliases
    numeric = {
        x["module"] + "." + x["name"]
        for x in json.loads((ROOT / "bindings/schema/numeric.json").read_text())[
            "functions"
        ]
    }
    entries = [e for e in entries if e["module"] + "." + e["name"] not in numeric]
    if missing:
        raise ValueError(missing)
    return entries, types, fields


def hs_type(spec, types):
    return G.hs_type(spec, types).replace("(a)", "(X.Value)")


def decode(spec, value, types):
    head, *args = spec
    if head == "a":
        return "pure " + value
    if head == "function":
        variables = [G.fresh("parameter") for _ in args[:-1]]
        encoded = [encode(s, v, types) for s, v in zip(args[:-1], variables)]
        arg = "callbackInput"
        input_statement = (
            "callbackArgs <- sequence ["
            + ",".join(encoded)
            + "]; let { callbackInput=X.Tuple callbackArgs }"
        )
        call = "LC.callbackValue " + value + " " + arg
        result = args[-1]
        if result[0] == "Either":
            result = result[2]
            call = (
                "checkedCallback "
                + value
                + " "
                + arg
                + " (\\reply -> "
                + decode(result, "reply", types)
                + ")"
            )
        else:
            call += " >>= \\reply -> " + decode(result, "reply", types)
        return (
            "pure (\\"
            + " ".join(variables)
            + " -> unsafePerformIO $ do { "
            + input_statement
            + "; "
            + call
            + " })"
        )
    if head == "list":
        variable = G.fresh("item")
        return (
            "X.asList "
            + value
            + " >>= mapM (\\"
            + variable
            + " -> "
            + decode(args[0], variable, types)
            + ")"
        )
    if head == "tuple":
        variables = [G.fresh("part") for _ in args]
        parts = G.fresh("tuple")
        return (
            "(X.asTuple "
            + str(len(args))
            + " "
            + value
            + " >>= \\"
            + parts
            + " -> case "
            + parts
            + " of { ["
            + ",".join(variables)
            + "] -> ("
            + "," * (len(args) - 1)
            + ") <$> "
            + " <*> ".join(
                "(" + decode(s, v, types) + ")" for s, v in zip(args, variables)
            )
            + '; _ -> X.invalid "tuple arity differs" })'
        )
    if head == "Matrix":
        return "LC.asMatrix " + value
    if head in types:
        return ("asRNG" if head == "RNG" else "unbox " + str(TAGS[head])) + " " + value
    if head == "Int":
        return "X.asIndex " + value
    if head == "Bool":
        return "X.asBoolean " + value
    if head == "String":
        return "X.asText " + value
    if head in ("Double", "Integer", "Word64"):
        return "X.asScalar " + value
    raise ValueError("unsupported stochastic decode " + repr(spec))


def encode(spec, value, types):
    head, *args = spec
    if head == "a":
        return "pure " + value
    if head == "Either":
        result = G.fresh("_result")
        return (
            "source "
            + value
            + " >>= \\"
            + result
            + " -> "
            + encode(args[1], result, types)
        )
    if head == "IO":
        result = G.fresh("_result")
        return value + " >>= \\" + result + " -> " + encode(args[0], result, types)
    if head == "list":
        variable = G.fresh("item")
        return (
            "X.List <$> mapM (\\"
            + variable
            + " -> "
            + encode(args[0], variable, types)
            + ") "
            + value
        )
    if head == "tuple":
        variables = [G.fresh("part") for _ in args]
        return (
            "(\\("
            + ",".join(variables)
            + ") -> X.Tuple <$> sequence ["
            + ",".join(encode(s, v, types) for s, v in zip(args, variables))
            + "]) "
            + value
        )
    if head == "Matrix":
        return "pure(X.Dense(X.SomeMatrix SDouble " + value + "))"
    if head in types:
        return "encode" + head + " " + value
    if head == "Int":
        return "pure(X.Index " + value + ")"
    if head == "Bool":
        return "pure(X.Boolean " + value + ")"
    if head == "String":
        return "pure(X.Text " + value + ")"
    if head in ("Double", "Integer", "Word64"):
        return (
            "pure(X.Scalar "
            + {"Double": "SDouble", "Integer": "SInteger", "Word64": "SWord64"}[head]
            + " "
            + value
            + ")"
        )
    if head == "unit":
        return "pure X.None"
    raise ValueError("unsupported stochastic encode " + repr(spec))


def symbol(entry):
    return (
        "hmath_stochastic_"
        + MODULES[entry["module"]][2]
        + "_"
        + ("new_" if entry["constructor"] else "")
        + G.snake(entry["name"])
    )


def has_callback(spec):
    return spec[0] == "function" or any(
        has_callback(x) for x in spec[1:] if isinstance(x, list)
    )


def native(entries, types, fields):
    hs = [
        """{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- Generated; original algorithms and complete immutable continuation states.
module HMath.FFI.Stochastic where
import Control.Exception (catch,evaluate,throwIO)
import Data.Typeable (Typeable,cast)
import Foreign
import Foreign.C
import System.IO.Unsafe (unsafePerformIO)
import qualified HMath.Error as E
import qualified HMath.Matrix as M
import HMath.FFI.Coefficient
import HMath.FFI.RandomCodec (rng,asRNG)
import qualified HMath.FFI.LinearCodec as LC
import qualified HMath.FFI.Value as X
import qualified HMath.FFI.Boundary as Boundary
import HMath.FFI.MathError
"""
    ]
    for m, (alias, _ns, _public) in MODULES.items():
        hs.append("import qualified " + m + " as " + alias + "\n")
    hs.append("""
unbox :: forall a. Typeable a => Int -> X.Value -> IO a
unbox kind (X.Opaque actual _ _ _ payload) | kind==actual=maybe(X.invalid "stochastic object payload differs") pure(cast payload)
unbox _ _=X.invalid "stochastic object kind differs"
source :: Either E.MathError a -> IO a
source=either (throwIO . CallbackMathError) pure
forceFields :: [IO X.Value] -> IO ()
forceFields fields=sequence fields >>= mapM_ X.forceValue
checkedCallback :: X.Value -> X.Value -> (X.Value -> IO a) -> IO(Either E.MathError a)
checkedCallback function argument decodeResult=(LC.callbackValue function argument >>= decodeResult >>= pure . Right) `catch` relay
  where
    relay(CallbackMathError errorValue)=pure(Left errorValue)
    relay other=throwIO(other::CallbackFailure)
stochasticBoundary :: IO CInt -> IO CInt
stochasticBoundary action=Boundary.boundary $ callbackBoundary (\\e -> Boundary.checked(Left e)(const(pure()))) action
""")
    for name, t in types.items():
        qualified = t["alias"] + "." + name
        hs.append("\nencode" + name + " :: " + qualified + " -> IO X.Value\n")
        if name == "RNG":
            hs.append("encodeRNG=pure . rng\n")
            continue
        hs.append(
            "encode"
            + name
            + " value=pure(X.Opaque "
            + str(TAGS[name])
            + " (-1) 0 force value)\n  where\n    force="
        )
        if fields[name]:
            hs.append(
                "forceFields ["
                + ",".join(
                    encode(s, "(" + t["alias"] + "." + f + " value)", types)
                    for f, s in fields[name]
                )
                + "]\n"
            )
        elif name == "Distribution":
            hs.append("case value of\n")
            for e in entries:
                if e["constructor"] and e["result"][0] == name:
                    variables = [G.fresh("field") for _ in e["args"]]
                    hs.append(
                        "        P."
                        + e["name"]
                        + " "
                        + " ".join(variables)
                        + " -> forceFields ["
                        + ",".join(
                            encode(s, v, types) for s, v in zip(e["args"], variables)
                        )
                        + "]\n"
                    )
        else:
            hs.append("evaluate value >> pure()\n")
    hs.append(
        "\napply :: Int -> [X.Value] -> IO X.Value\napply operation args=case(operation,args) of\n"
    )
    h = [
        """/* SPDX-License-Identifier: MPL-2.0 */
/* Generated by tools/generate_stochastic_bindings.py. */
#ifndef HMATH_STOCHASTIC_H
#define HMATH_STOCHASTIC_H
#include "hmath_linear.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Original immutable RNG240,Generator241,AliasTable242,Distribution243,
 * Markov244,HMM245,Streaming246,TestResult247. Every output owns one Value;
 * retain inputs during the call and release each output. Errors leave out
 * untouched and preserve MathError. Seeds/words are exact Word64 scalars.
 * Polymorphic sample elements transport arbitrary Values without coercion.
 * Callbacks use hmath_linear_callback(kind101). Checked callbacks return true
 * source Left on status11; pure callbacks abort. No generator, distribution,
 * algorithm, default, proposal/evaluation budget or buffered state is replaced. */
HMATH_API hmath_status hmath_stochastic_object_parts(hmath_context *context,const hmath_value *value,hmath_value **out);
HMATH_API hmath_status hmath_stochastic_equal(hmath_context *context,const hmath_value *left,const hmath_value *right,hmath_value **out);
"""
    ]
    c = [
        """/* SPDX-License-Identifier: MPL-2.0 */
/* Generated by tools/generate_stochastic_bindings.py. */
#include "hmath_stochastic.h"
#include "value_internal.h"
extern int hm_stochastic_apply(int opcode,void *const *args,size_t count,void **out);
"""
    ]
    for opcode, e in enumerate(entries):
        variables = ["a" + str(i) for i in range(len(e["args"]))]
        hs.append("    (" + str(opcode) + ",[" + ",".join(variables) + "]) -> do\n")
        for variable, spec in zip(variables, e["args"]):
            hs.append(
                "        "
                + variable
                + "Value <- ("
                + decode(spec, variable, types)
                + " :: IO "
                + hs_type(spec, types)
                + ")\n"
            )
        expression = (
            "("
            + MODULES[e["module"]][0]
            + "."
            + e["name"]
            + " "
            + " ".join(v + "Value" for v in variables)
            + " :: "
            + hs_type(e["result"], types)
            + ")"
        )
        hs.append("        " + encode(e["result"], expression, types) + "\n")
        proto = (
            "hmath_status "
            + symbol(e)
            + "("
            + ", ".join(
                ["hmath_context *context"]
                + ["const hmath_value *" + v for v in variables]
                + ["hmath_value **out"]
            )
            + ")"
        )
        h.append(
            "/* "
            + e["module"]
            + "."
            + e["name"]
            + " :: "
            + e["signature"]
            + " */\nHMATH_API "
            + proto
            + ";\n"
        )
        c.append(
            proto
            + " {\n    if(!out"
            + "".join(" || !" + v for v in variables)
            + ') return hm_error(HMATH_INVALID_ARGUMENT,"NULL stochastic argument");\n    hmath_value *result; hmath_status status=hm_value_begin(context,&result);if(status)return status;\n'
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
            "    return hm_value_finish(result,hm_stochastic_apply("
            + str(opcode)
            + ","
            + ptr
            + ","
            + str(len(variables))
            + ",&result->stable),out);\n}\n"
        )
    hs.append("    (-1,[value]) -> case X.valueInfo value of\n")
    for name, t in types.items():
        constructors = [
            e for e in entries if e["constructor"] and e["result"][0] == name
        ]
        hs.append("        (" + str(TAGS[name]) + ",_,_) -> do\n")
        if not constructors:
            hs.append(
                '            X.unsupported "original abstract type has no public constructor fields"\n'
            )
            continue
        hs.append(
            "            object <- ("
            + (
                "asRNG value"
                if name == "RNG"
                else "unbox " + str(TAGS[name]) + " value"
            )
            + " :: IO "
            + t["alias"]
            + "."
            + name
            + ")\n            case object of\n"
        )
        for e in constructors:
            variables = [G.fresh("field") for _ in e["args"]]
            hs.append(
                "                "
                + t["alias"]
                + "."
                + e["name"]
                + " "
                + " ".join(variables)
                + " -> do\n                    values <- sequence ["
                + ",".join(encode(s, v, types) for s, v in zip(e["args"], variables))
                + ']\n                    pure(X.Tuple[X.Text "'
                + e["name"]
                + '",X.Tuple values])\n'
            )
    hs.append(
        '        _ -> X.invalid "expected stochastic object"\n    (-2,[left,right]) -> case(X.valueInfo left,X.valueInfo right) of\n'
    )
    for name, t in types.items():
        tag = TAGS[name]
        dec = "asRNG" if name == "RNG" else "unbox " + str(tag)
        hs.append(
            "        (("
            + str(tag)
            + ",_,_),("
            + str(tag)
            + ",_,_)) -> do\n            a <- ("
            + dec
            + " left :: IO "
            + t["alias"]
            + "."
            + name
            + "); b <- "
            + dec
            + " right\n            pure(X.Boolean(a==b))\n"
        )
    hs.append("""        _ -> X.invalid "stochastic equality requires matching types"
    _ -> X.invalid "invalid stochastic operation/arity"
foreign export ccall "hm_stochastic_apply" ffiApply :: CInt -> Ptr(StablePtr X.Value) -> CSize -> Ptr(StablePtr X.Value) -> IO CInt
ffiApply :: CInt -> Ptr(StablePtr X.Value) -> CSize -> Ptr(StablePtr X.Value) -> IO CInt
ffiApply operation pointers count out=stochasticBoundary $ do
    values <- peekArray(fromIntegral count) pointers >>= mapM deRefStablePtr
    value <- apply(fromIntegral operation) values
    Boundary.checked(Right())(const(X.publish value out))
""")
    for name, opcode, args in [
        ("object_parts", -1, ["value"]),
        ("equal", -2, ["left", "right"]),
    ]:
        proto = (
            "hmath_status hmath_stochastic_"
            + name
            + "("
            + ", ".join(
                ["hmath_context *context"]
                + ["const hmath_value *" + v for v in args]
                + ["hmath_value **out"]
            )
            + ")"
        )
        c.append(
            proto
            + " {\n    if(!out"
            + "".join(" || !" + v for v in args)
            + ')return hm_error(HMATH_INVALID_ARGUMENT,"NULL stochastic query argument");\n    hmath_value *result;hmath_status status=hm_value_begin(context,&result);if(status)return status;\n    void *args[]={'
            + ",".join("hm_value_stable(" + v + ")" for v in args)
            + "};\n    return hm_value_finish(result,hm_stochastic_apply("
            + str(opcode)
            + ",args,"
            + str(len(args))
            + ",&result->stable),out);\n}\n"
        )
    h.append("#ifdef __cplusplus\n}\n#endif\n#endif\n")
    return {
        "src/HMath/FFI/Stochastic.hs": "".join(hs),
        "include/hmath_stochastic.h": "".join(h),
        "cbits/stochastic.c": "".join(c),
    }


def fmt(source, name):
    source = subprocess.run(
        [
            "ruff",
            "check",
            "--select",
            "I,RUF022,F401",
            "--fix",
            "--stdin-filename",
            name,
            "-",
        ],
        input=source,
        text=True,
        capture_output=True,
        check=True,
    ).stdout
    return subprocess.run(
        ["ruff", "format", "--stdin-filename", name, "-"],
        input=source,
        text=True,
        capture_output=True,
        check=True,
    ).stdout


def python_name(entry, entries, types):
    if entry["constructor"] and entry["name"] in types:
        return entry["name"]
    base = G.snake(entry["name"])
    if entry["constructor"] and any(
        not e["constructor"]
        and e["module"] == entry["module"]
        and G.snake(e["name"]) == base
        for e in entries
    ):
        return "new_" + base
    return base


def frontend(entries, types, fields):
    py = {
        m: [
            '# SPDX-License-Identifier: MPL-2.0\n# Generated by tools/generate_stochastic_bindings.py.\n"""Original '
            + m
            + ' remaining public functions and owned immutable records."""\nfrom ._stochastic_base import StochasticValue,_invoke\nfrom ._value import register\n'
        ]
        for m in MODULES
    }
    names = {m: [] for m in MODULES}
    mapping = []
    docs = [
        "# Random streams, distributions and statistics\n\nEvery function calls the original Haskell implementation. RNG owners retain the complete immutable algorithm state, including buffered outputs. Seeds and generated words use exact Word64 transport. All seven generators, continuation/clone/split/serialization behavior, original distributions, model validation, sample ordering, diagnostics, resource budgets and error recovery are preserved. Values are owned and support `close()`/context management; results survive closing inputs. Generic sample elements preserve arbitrary typed Values rather than coercing through a numeric dtype.\n\nCallbacks use the original argument order. Raising a `MathError` from a checked callback becomes the original source `Left`; the algorithm retains its original recovery behavior. Unexpected Python exceptions rethrow after native cleanup. Pure callbacks abort on failure. Keep C callbacks/userdata alive as long as any owner/derived closure can invoke them. No package import initializes global RNG state or consumes entropy.\n\n"
    ]
    for name, t in types.items():
        m = t["module"]
        names[m].append(name)
        py[m].append(
            "\nclass "
            + name
            + '(StochasticValue):\n    """Original '
            + m
            + "."
            + name
            + ' immutable owner."""\n'
        )
        constructor = next(
            (e for e in entries if e["constructor"] and e["name"] == name), None
        )
        if name == "RNG":
            constructor = next(
                e
                for e in entries
                if e["module"] == "HMath.Random" and e["name"] == "seedRNG"
            )
        if constructor:
            params = (
                [G.snake(f) for f, _ in fields[name]]
                if fields[name]
                else ["generator", "seed"]
                if name == "RNG"
                else ["value" + str(i) for i in range(len(constructor["args"]))]
            )
            py[m].append(
                "    def __init__(self, "
                + ", ".join(params)
                + "):\n        self._initialize("
                + repr(symbol(constructor))
                + ", "
                + repr(constructor["args"])
                + ", ["
                + ", ".join(params)
                + "])\n"
            )
        for field, typ in fields[name]:
            e = next(e for e in entries if e["module"] == m and e["name"] == field)
            py[m].append(
                "    @property\n    def "
                + G.snake(field)
                + "(self):\n        return _invoke("
                + repr(symbol(e))
                + ", "
                + repr(e["args"])
                + ", [self])\n"
            )
        if name == "RNG":
            py[m].append(
                '    def serialize(self):\n        return _invoke("hmath_stochastic_random_serialize_rng", [["RNG"]], [self])\n'
            )
        py[m].append("register(" + str(TAGS[name]) + ", " + name + ")\n")
    covered = set()
    for e in entries:
        m = e["module"]
        public = MODULES[m][2]
        record = e["constructor"] and e["name"] in types
        pname = python_name(e, entries, types)
        if not record:
            params = ["argument" + str(i + 1) for i in range(len(e["args"]))]
            names[m].append(pname)
            py[m].append(
                "\ndef "
                + pname
                + "("
                + ", ".join(params)
                + "):\n    "
                + repr(G.source_prose(e))
                + "\n    return _invoke("
                + repr(symbol(e))
                + ", "
                + repr(e["args"])
                + ", ["
                + ", ".join(params)
                + "])\n"
            )
        src = m + "." + e["name"]
        covered.add(src)
        mapping.append(
            {
                "symbol": src,
                "c": [symbol(e)],
                "python": "hmath." + public + "." + pname,
                "specializations": [
                    "original concrete types; arbitrary Value element containers without coercion; original checked/pure callbacks"
                ],
            }
        )
        docs.append(
            "## `"
            + public
            + "."
            + pname
            + "`\n\n"
            + G.source_prose(e)
            + "\n\nOriginal signature: `"
            + e["signature"]
            + "`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.\n\n"
        )
    for name, t in types.items():
        src = t["module"] + "." + name
        if src not in covered:
            mapping.append(
                {
                    "symbol": src,
                    "c": ["hmath_value", "hmath_value_release"],
                    "python": "hmath." + MODULES[t["module"]][2] + "." + name,
                    "specializations": [
                        "original raw immutable type, Value kind" + str(TAGS[name])
                    ],
                }
            )
    result = {
        "bindings/schema/stochastic-objects.json": json.dumps(
            {"schema": 1, "bindings": sorted(mapping, key=lambda x: x["symbol"])},
            indent=2,
        )
        + "\n",
        "bindings/schema/stochastic-functions.json": json.dumps(
            {"functions": entries, "types": types, "fields": fields}, indent=2
        )
        + "\n",
        "docs/reference/stochastic.md": "".join(docs),
    }
    for m, parts in py.items():
        parts.append("\n__all__=" + repr(sorted(set(names[m]))) + "\n")
        result["bindings/python/_hmath_native/" + MODULES[m][1] + ".py"] = fmt(
            "".join(parts), MODULES[m][1] + ".py"
        )
    return result


def outputs():
    G._COUNTER = 0
    entries, types, fields = specification()
    result = native(entries, types, fields)
    result.update(frontend(entries, types, fields))
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
