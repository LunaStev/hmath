# SPDX-License-Identifier: MPL-2.0
"""Generate original-operation adapters for the public linear algebra domains."""

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODULES = {
    "HMath.Vector": ("V", "vector"),
    "HMath.Matrix.Advanced": ("A", "matrix_advanced"),
    "HMath.Matrix.Decomposition": ("D", "decomposition"),
    "HMath.Matrix.Iterative": ("I", "iterative"),
    "HMath.Matrix.LAPACK": ("L", "lapack"),
    "HMath.Sparse": ("S", "sparse"),
    "HMath.Sparse.Spectral": ("P", "sparse_spectral"),
    "HMath.Backend": ("B", "backend"),
}
ALIASES = {
    "M.Matrix": "Matrix",
    "LU.LU": "LU",
    "QR.QR": "QR",
    "L.SVD": "SVD",
    "L.Eigen": "Eigen",
    "FilePath": "String",
}


def snake(name):
    return re.sub(
        r"([a-z0-9])([A-Z])", r"\1_\2", re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", name)
    ).lower()


def split_top(text, sep):
    depth = 0
    start = 0
    out = []
    i = 0
    while i < len(text):
        if text[i] in "([":
            depth += 1
        elif text[i] in ")]":
            depth -= 1
        if depth == 0 and text.startswith(sep, i):
            out.append(text[start:i].strip())
            i += len(sep)
            start = i
        else:
            i += 1
    return out + [text[start:].strip()]


def parse_type(text):
    text = " ".join(text.split())
    for old, new in ALIASES.items():
        text = re.sub(r"\b" + re.escape(old) + r"\b", new, text)
    if text.startswith("[") and text.endswith("]"):
        return ["list", parse_type(text[1:-1])]
    if text.startswith("(") and text.endswith(")"):
        inner = text[1:-1]
        if not inner:
            return ["unit"]
        parts = split_top(inner, ",")
        if len(parts) > 1:
            return ["tuple", *[parse_type(x) for x in parts]]
        parts = split_top(inner, "->")
        if len(parts) > 1:
            return ["function", *[parse_type(x) for x in parts]]
        return parse_type(inner)
    parts = [x for x in split_top(text, " ") if x]
    if len(parts) > 1:
        return [parts[0], *[parse_type(x) for x in parts[1:]]]
    if not text:
        raise ValueError("empty type")
    return [text]


def signatures():
    known = {
        x["symbol"]
        for x in json.loads((ROOT / "bindings/schema/public-api.json").read_text())[
            "symbols"
        ]
    }
    entries = []
    types = {}
    fields_by_type = {}
    for module, (alias, namespace) in MODULES.items():
        raw = (ROOT / "src" / (module.replace(".", "/") + ".hs")).read_text()
        source = re.sub(r"\{-.*?-\}", "", raw, flags=re.DOTALL)
        source = re.sub(r"--[^\n]*", "", source)
        # Ordinary and shared signatures stop before a new top-level declaration.
        for match in re.finditer(
            r"^(\w+(?:\s*,\s*\w+)*)\s*::\s*([^\n]*(?:\n[ \t]+[^\n]*)*)",
            source,
            re.MULTILINE,
        ):
            names = re.findall(r"\w+", match[1])
            signature = " ".join(match[2].split())
            if not signature:
                continue
            constraints = ""
            signature = re.sub(r"^forall\s+[^.]+\.\s*", "", signature)
            if "=>" in signature:
                constraints, signature = signature.split("=>", 1)
            parts = split_top(signature.strip(), "->")
            for name in names:
                if module + "." + name not in known:
                    continue
                entries.append(
                    {
                        "module": module,
                        "name": name,
                        "args": [parse_type(p) for p in parts[:-1]],
                        "result": parse_type(parts[-1]),
                        "constraints": constraints.strip(),
                        "signature": signature.strip(),
                        "constructor": False,
                    }
                )
        for match in re.finditer(
            r"^(?:data|newtype)\s+(\w+)([^=\n]*)(?:\n[ \t]+)?=\s*([^\n]*(?:\n[ \t]+[^\n]*)*)",
            source,
            re.MULTILINE,
        ):
            name = match[1]
            if module + "." + name not in known:
                continue
            params = re.findall(r"\b[a-z]\b", match[2])
            if name == "FixedVector":
                params = ["n", "a"]
            types[name] = {
                "module": module,
                "alias": alias,
                "namespace": namespace,
                "name": name,
                "params": params,
            }
            body = re.sub(r"\s+deriving\s*\(.*", "", match[3], flags=re.DOTALL).strip()
            fields = []
            if "{" in body:
                constructor = body.split("{", 1)[0].strip()
                data = body.split("{", 1)[1].rsplit("}", 1)[0]
                for field in split_top(data, ","):
                    fname, ftype = field.split("::", 1)
                    fields.append((fname.strip(), parse_type(ftype)))
                constructors = [(constructor, [typ for _, typ in fields])]
                for fname, ftype in fields:
                    entries.append(
                        {
                            "module": module,
                            "name": fname,
                            "args": [[name, *[[p] for p in params]]],
                            "result": ftype,
                            "constraints": "",
                            "signature": name + " -> field",
                            "constructor": False,
                        }
                    )
            else:
                constructors = []
                for part in split_top(body, "|"):
                    tokens = [x for x in split_top(part, " ") if x]
                    if tokens:
                        constructors.append(
                            (tokens[0], [parse_type(x) for x in tokens[1:]])
                        )
            fields_by_type[name] = fields
            for cname, args in constructors:
                if module + "." + cname not in known:
                    continue
                header = raw.split(") where", 1)[0]
                if not re.search(r"\b" + re.escape(name) + r"\s*\(\.\.\)", header):
                    continue
                entries.append(
                    {
                        "module": module,
                        "name": cname,
                        "args": args,
                        "result": [name, *[[p] for p in params]],
                        "constraints": "",
                        "signature": "constructor",
                        "constructor": True,
                    }
                )
    keys = [x["module"] + "." + x["name"] for x in entries]
    if len(keys) != len(set(keys)):
        raise ValueError(
            "duplicate source function/field/constructor: "
            + str([x for x in set(keys) if keys.count(x) > 1])
        )
    hidden = [
        key
        for key in known
        if key.rsplit(".", 1)[0] in MODULES
        and key not in keys
        and key.rsplit(".", 1)[-1] not in types
    ]
    return entries, types, fields_by_type, sorted(hidden)


# A representation compiler; it never emits arithmetic/algorithm loops.
_COUNTER = 0


def fresh(stem):
    global _COUNTER
    _COUNTER += 1
    return stem + str(_COUNTER)


def hs_type(spec, types):
    head, *args = spec
    if head == "list":
        return "[" + hs_type(args[0], types) + "]"
    if head == "tuple":
        return "(" + ",".join(hs_type(x, types) for x in args) + ")"
    if head == "unit":
        return "()"
    if head == "function":
        return "(" + " -> ".join(hs_type(x, types) for x in args) + ")"
    prefix = {
        "Matrix": "M.Matrix",
        "LU": "LU.LU",
        "QR": "QR.QR",
        "MathError": "E.MathError",
    }.get(head)
    if head in types:
        prefix = types[head]["alias"] + "." + head
    return (
        "("
        + (prefix or head)
        + (" " + " ".join(hs_type(x, types) for x in args) if args else "")
        + ")"
    )


def witness(spec):
    if spec == ["a"]:
        return "w"
    if spec == ["Complex", ["a"]]:
        return "cw"
    return {
        ("Double",): "SDouble",
        ("Float",): "SFloat",
        ("Rational",): "SRational",
        ("Integer",): "SInteger",
        ("Complex", ("Double",)): "SComplexDouble",
        ("Complex", ("Float",)): "SComplexFloat",
    }.get(tuple(tuple(x) if isinstance(x, list) else x for x in spec))


def decode_expr(spec, value, types):
    head, *args = spec
    if head == "list":
        item = fresh("item")
        return (
            "X.asList "
            + value
            + " >>= mapM (\\"
            + item
            + " -> "
            + decode_expr(args[0], item, types)
            + ")"
        )
    if head == "tuple":
        items = fresh("items")
        names = [fresh("part") for _ in args]
        ctor = "(" + "," * (len(args) - 1) + ")"
        expr = (
            ctor
            + " <$> "
            + (
                " <*> ".join(
                    "(" + decode_expr(s, n, types) + ")" for s, n in zip(args, names)
                )
            )
        )
        return (
            "(X.asTuple "
            + str(len(args))
            + " "
            + value
            + " >>= \\"
            + items
            + " -> case "
            + items
            + " of { ["
            + ",".join(names)
            + "] -> "
            + expr
            + '; _ -> X.invalid "tuple arity differs" })'
        )
    if head == "Maybe":
        return (
            "(case "
            + value
            + " of { X.None -> pure Nothing; _ -> Just <$> ("
            + decode_expr(args[0], value, types)
            + ") })"
        )
    if head == "Matrix":
        return "asMatrix " + value
    if head in types:
        return (
            "unbox "
            + repr(types[head]["module"] + "." + head).replace("'", '"')
            + " "
            + value
        )
    if head == "a" or head in ("Double", "Float", "Integer", "Rational", "Complex"):
        return "X.asScalar " + value
    if head == "Int":
        return "X.asIndex " + value
    if head == "Bool":
        return "X.asBoolean " + value
    if head == "String":
        return "X.asText " + value
    raise ValueError("no decoder " + repr(spec))


def encode_expr(spec, value, types):
    head, *args = spec
    if head == "Either":
        result = fresh("_result")
        return (
            "source "
            + value
            + " >>= \\"
            + result
            + " -> "
            + encode_expr(args[1], result, types)
        )
    if head == "IO":
        result = fresh("_result")
        return value + " >>= \\" + result + " -> " + encode_expr(args[0], result, types)
    if head == "list":
        item = fresh("item")
        return (
            "X.List <$> mapM (\\"
            + item
            + " -> "
            + encode_expr(args[0], item, types)
            + ") "
            + value
        )
    if head == "tuple":
        names = [fresh("part") for _ in args]
        return (
            "(\\("
            + ",".join(names)
            + ") -> X.Tuple <$> sequence ["
            + ",".join(encode_expr(s, n, types) for s, n in zip(args, names))
            + "]) "
            + value
        )
    if head == "Maybe":
        item = fresh("item")
        return (
            "(case "
            + value
            + " of {Nothing -> pure X.None;Just "
            + item
            + " -> "
            + encode_expr(args[0], item, types)
            + "})"
        )
    if head == "Matrix":
        w = witness(args[0])
        if not w:
            raise ValueError("matrix witness " + repr(spec))
        return "pure (X.Dense (X.SomeMatrix " + w + " " + value + "))"
    if head in types:
        t = types[head]
        return "encode" + head + (" w" if "a" in t["params"] else "") + " " + value
    if head in ("LU", "QR"):
        return "encodeLegacy" + head + " " + value
    w = witness(spec)
    if w:
        return "pure (X.Scalar " + w + " " + value + ")"
    if head == "Int":
        return "pure (X.Index " + value + ")"
    if head == "Bool":
        return "pure (X.Boolean " + value + ")"
    if head == "String":
        return "pure (X.Text " + value + ")"
    if head == "unit":
        return "pure X.None"
    raise ValueError("no encoder " + repr(spec))


def source_prose(entry):
    source = (ROOT / "src" / (entry["module"].replace(".", "/") + ".hs")).read_text()
    match = re.search(r"^[ \t]*(?:pattern[ \t]+)?" + re.escape(entry["name"]) + r"\s*::", source, re.MULTILINE)
    if match:
        before = source[: match.start()].rstrip()
        if before.endswith("-}"):
            start = before.rfind("{- |")
            if start >= 0:
                return " ".join(before[start + 4 : -2].replace("@", "`").split())
        lines = []
        for line in reversed(before.splitlines()):
            line = line.lstrip()
            if not line.startswith("--"):
                break
            lines.insert(0, line.removeprefix("--").removeprefix(" | ").strip())
        if lines:
            return " ".join(lines).replace("@", "`")
    if entry["constructor"]:
        return "Construct the original public variant; positional fields retain their exact source types and order."
    return "Read the original immutable public field; no numerical conversion is performed."


def generic_entry(entry):
    def variable(spec):
        return spec in (["a"], ["b"], ["c"]) or any(
            variable(x) for x in spec[1:] if isinstance(x, list)
        )

    return any(variable(x) for x in entry["args"] + [entry["result"]])


def c_symbol(entry):
    namespace = MODULES[entry["module"]][1]
    return (
        "hmath_linear_"
        + namespace
        + "_"
        + ("new_" if entry["constructor"] else "")
        + snake(entry["name"])
    )


def codec_haskell(types, fields, entries):
    out = [
        """{-# LANGUAGE GADTs #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- Generated by tools/generate_linear_bindings.py. Representation/lifetime only.
module HMath.FFI.LinearCodec where
import Control.Exception (bracket,evaluate,throwIO)
import Data.Dynamic (Dynamic,toDyn,fromDynamic)
import Data.Typeable (Typeable,cast)
import Data.Proxy (Proxy(..))
import Data.Complex (Complex)
import Foreign
import Foreign.C
import GHC.TypeLits (KnownNat,SomeNat(..),someNatVal)
import qualified HMath.Error as E
import qualified HMath.Matrix as M
import qualified HMath.Matrix.LU as LU
import qualified HMath.Matrix.QR as QR
import qualified HMath.FFI.Matrix as Legacy
import qualified HMath.FFI.Value as X
import qualified HMath.FFI.Boundary as Boundary
import HMath.FFI.Coefficient
import HMath.FFI.MathError
import qualified HMath.FFI.TensorCodec as TensorCodec
"""
    ]
    for module, (alias, _namespace) in MODULES.items():
        if any(t["module"] == module for t in types.values()):
            out.append("import qualified " + module + " as " + alias + "\n")
    out.append("""
data Envelope=Envelope String Dynamic (IO X.Value)
opaque :: Typeable a => String -> Int -> a -> IO () -> IO X.Value -> X.Value
opaque name dtype payload force view=X.Opaque 100 dtype 0 force (Envelope name (toDyn payload) view)
unbox :: forall a. Typeable a => String -> X.Value -> IO a
unbox expected (X.Opaque 100 _ _ _ payload)=case cast payload of
    Just(Envelope actual value _) | actual==expected -> maybe (X.invalid "linear object coefficient/type differs") pure (fromDynamic value)
    _ -> X.invalid "linear object subtype differs"
unbox _ _=X.invalid "expected linear object"
objectName :: X.Value -> IO String
objectName (X.Opaque 100 _ _ _ payload)=case cast payload of
    Just(Envelope name _ _) -> pure name
    _ -> X.invalid "invalid linear envelope"
objectName _=X.invalid "expected linear object"
objectParts :: X.Value -> IO X.Value
objectParts (X.Opaque 100 _ _ _ payload)=case cast payload of
    Just(Envelope _ _ view) -> view
    _ -> X.invalid "invalid linear envelope"
objectParts _=X.invalid "expected linear object"
asMatrix :: forall a. Coefficient a => X.Value -> IO(M.Matrix a)
asMatrix (X.Dense(X.SomeMatrix _ matrix))=maybe (X.invalid "matrix coefficient types differ") pure (cast matrix)
asMatrix _=X.invalid "expected Matrix"
withWitness :: X.Value -> (forall a. Coefficient a => ScalarType a -> IO X.Value) -> IO X.Value
withWitness (X.Scalar witness _) action=action witness
withWitness _ _=X.invalid "expected scalar coefficient prototype"
source :: Either E.MathError a -> IO a
source=either (throwIO . CallbackMathError) pure
forceFields :: [IO X.Value] -> IO ()
forceFields fields=sequence fields >>= mapM_ X.forceValue
fractional :: forall a. Coefficient a => ScalarType a -> (Fractional a => IO X.Value) -> IO X.Value
fractional _ action=case fractionalDict(Proxy::Proxy a) of
    Just Dict -> action
    Nothing -> X.unsupported "original operation requires Fractional coefficients"
realFloat :: forall a. Coefficient a => ScalarType a -> (RealFloat a => IO X.Value) -> IO X.Value
realFloat _ action=case realFloatDict(Proxy::Proxy a) of
    Just Dict -> action
    Nothing -> X.unsupported "original operation requires RealFloat coefficients"
ordered :: forall a. Coefficient a => ScalarType a -> (Ord a => IO X.Value) -> IO X.Value
ordered _ action=case orderingDict(Proxy::Proxy a) of
    Just Dict -> action
    Nothing -> X.unsupported "original operation requires ordered coefficients"
withComplex :: forall a. Coefficient a => ScalarType a -> (Coefficient(Complex a) => ScalarType(Complex a) -> IO X.Value) -> IO X.Value
withComplex SFloat action=action SComplexFloat
withComplex SDouble action=action SComplexDouble
withComplex _ _=X.unsupported "complex component must retain original Float/Double RealFloat type"
linearBoundary :: IO CInt -> IO CInt
linearBoundary action=Boundary.boundary $ callbackBoundary (\\e -> Boundary.checked(Left e)(const(pure ()))) action

data SomeFixed a where
    SomeFixed :: KnownNat n => V.FixedVector n a -> SomeFixed a
fixedFrom :: forall a. Coefficient a => ScalarType a -> Int -> [a] -> IO X.Value
fixedFrom w count values=case someNatVal(toInteger count) of
    Nothing -> X.invalid "fixed dimension cannot be a negative type-level natural"
    Just(SomeNat(_::Proxy n)) -> do
        result <- source(V.fixedVector values :: Either E.MathError(V.FixedVector n a))
        encodeFixedVector w (SomeFixed result)
""")
    for name, t in types.items():
        generic = "a" in t["params"]
        objtype = (
            "SomeFixed a"
            if name == "FixedVector"
            else t["alias"] + "." + name + (" a" if generic else "")
        )
        out.append(
            "\nencode"
            + name
            + " :: "
            + ("Coefficient a => ScalarType a -> " if generic else "")
            + "("
            + objtype
            + ") -> IO X.Value\n"
        )
        out.append(
            "encode"
            + name
            + (" w" if generic else "")
            + ' value=pure(opaque "'
            + t["module"]
            + "."
            + name
            + '" '
            + ("(scalarTypeCode w)" if generic else "(-1)")
            + " value force view)\n  where\n    force="
        )
        specs = []
        if fields[name]:
            specs = [
                (s, "(" + t["alias"] + "." + f + " value)") for f, s in fields[name]
            ]
        elif name == "Vector":
            specs = [(["list", ["a"]], "(V.vectorValues value)")]
        elif name == "Sparse":
            specs = [
                (
                    ["list", ["tuple", ["Int"], ["Int"], ["a"]]],
                    "(S.sparseEntries value)",
                )
            ]
        elif name == "SparseTensor":
            specs = [
                (
                    ["list", ["tuple", ["list", ["Int"]], ["a"]]],
                    "(S.sparseTensorEntries value)",
                )
            ]
        elif name == "SparseLU":
            specs = [
                (["Sparse", ["a"]], "(S.sparseLULower value)"),
                (["Sparse", ["a"]], "(S.sparseLUUpper value)"),
                (["list", ["Int"]], "(S.sparseLUPermutation value)"),
            ]
        elif name == "SparseQR":
            specs = [(["Sparse", ["a"]], "(S.sparseQRUpper value)")]
        elif name == "Backend":
            specs = [(["BackendInfo"], "(B.backendInfo value)")]
        if specs:
            out.append(
                "forceFields ["
                + ",".join(encode_expr(s, v, types) for s, v in specs)
                + "]\n"
            )
        elif name == "FixedVector":
            out.append(
                "case value of SomeFixed fixed -> forceFields ["
                + encode_expr(["list", ["a"]], "(V.fixedValues fixed)", types)
                + "]\n"
            )
        elif name == "SparseFormat":
            out.append("case value of\n")
            for entry in entries:
                if entry["constructor"] and entry["result"][0] == "SparseFormat":
                    variables = [fresh("field") for _ in entry["args"]]
                    out.append(
                        "        S."
                        + entry["name"]
                        + " "
                        + " ".join(variables)
                        + " -> forceFields ["
                        + ",".join(
                            encode_expr(s, v, types)
                            for s, v in zip(entry["args"], variables)
                        )
                        + "]\n"
                    )
        else:
            out.append("evaluate value >> pure ()\n")
        constructors = [
            e for e in entries if e["constructor"] and e["result"][0] == name
        ]
        if constructors:
            out.append("    view=case value of\n")
            for entry in constructors:
                variables = [fresh("field") for _ in entry["args"]]
                out.append(
                    "        "
                    + t["alias"]
                    + "."
                    + entry["name"]
                    + " "
                    + " ".join(variables)
                    + " -> do\n"
                )
                out.append(
                    "            values <- sequence ["
                    + ",".join(
                        encode_expr(spec, v, types)
                        for spec, v in zip(entry["args"], variables)
                    )
                    + "]\n"
                )
                out.append(
                    '            pure(X.Tuple[X.Text "'
                    + entry["name"]
                    + '",X.Tuple values])\n'
                )
        else:
            out.append(
                '    view=X.unsupported "original abstract type has no public constructor fields"\n'
            )

    out.append("""
encodeLegacyLU :: LU.LU Double -> IO X.Value
encodeLegacyLU value=pure(opaque "HMath.Matrix.LU.LU" 0 value (forceFields [pure(X.Dense(X.SomeMatrix SDouble(LU.luLower value))),pure(X.Dense(X.SomeMatrix SDouble(LU.luUpper value)))]) (X.unsupported "abstract LU constructor"))
encodeLegacyQR :: QR.QR Double -> IO X.Value
encodeLegacyQR value=pure(opaque "HMath.Matrix.QR.QR" 0 value (forceFields [pure(X.Dense(X.SomeMatrix SDouble(QR.qrR value)))]) (X.unsupported "abstract QR constructor"))
foreign export ccall "hm_linear_legacy" legacy :: StablePtr X.Value -> Ptr CInt -> Ptr(StablePtr Legacy.Object) -> IO CInt
legacy :: StablePtr X.Value -> Ptr CInt -> Ptr(StablePtr Legacy.Object) -> IO CInt
legacy pointer kind out=linearBoundary $ do
    value <- deRefStablePtr pointer
    name <- objectName value
    case name of
        "HMath.Matrix.LU.LU" -> do
            result <- unbox name value
            Boundary.checked(Right())(const(Legacy.publish(Legacy.L64 result) out >> poke kind 2))
        "HMath.Matrix.QR.QR" -> do
            result <- unbox name value
            Boundary.checked(Right())(const(Legacy.publish(Legacy.Q64 result) out >> poke kind 3))
        _ -> X.invalid "expected original LU/QR result"
foreign export ccall "hm_linear_clone" clone :: StablePtr X.Value -> Ptr(StablePtr X.Value) -> IO CInt
clone :: StablePtr X.Value -> Ptr(StablePtr X.Value) -> IO CInt
clone pointer out=linearBoundary $ do
    value <- deRefStablePtr pointer
    Boundary.checked(Right())(const(X.publish value out))
""")
    structural = STRUCTURAL_VECTOR_HS
    for index, entry in enumerate(entries):
        if entry["module"] == "HMath.Vector":
            structural = structural.replace("OP_" + entry["name"] + "_", str(index))
    return "".join(out) + CALLBACK_HS + structural


def dispatch_haskell(entries, types):
    out = [
        """{-# LANGUAGE GADTs #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- Generated; every operation calls the original Haskell public function.
module HMath.FFI.LinearAll where
import Foreign
import Foreign.C
import qualified HMath.Matrix as M
import qualified HMath.Matrix.LU as LU
import qualified HMath.Matrix.QR as QR
import Data.Complex (Complex)
import System.IO.Unsafe (unsafePerformIO)
import qualified HMath.Error as E
import HMath.FFI.Coefficient
import HMath.FFI.LinearCodec
import qualified HMath.FFI.Value as X
import qualified HMath.FFI.Boundary as Boundary
"""
    ]
    for module, (alias, _ns) in MODULES.items():
        out.append("import qualified " + module + " as " + alias + "\n")
    special = {"fixedVector", "fixedValues", "generateMatrix", "zipMatrixWith"}
    out.append(
        "\ngeneric :: forall a. Coefficient a => ScalarType a -> Int -> [X.Value] -> IO X.Value\ngeneric w operation args=case(operation,args) of\n"
    )
    for opcode, entry in enumerate(entries):
        if not generic_entry(entry) or entry["name"] in special:
            continue
        out.append(operation_haskell(opcode, entry, types, generic=True))
    out.append(
        '    _ -> X.invalid "unsupported generic linear operation/arity"\n\nconcrete :: Int -> [X.Value] -> IO X.Value\nconcrete operation args=case(operation,args) of\n'
    )
    for opcode, entry in enumerate(entries):
        if generic_entry(entry) or entry["name"] in special:
            continue
        out.append(operation_haskell(opcode, entry, types, generic=False))
    out.append(
        '    (-1,[value]) -> X.Text <$> objectName value\n    (-2,[value]) -> objectParts value\n    _ -> X.invalid "unsupported concrete linear operation/arity"\n'
    )
    return "".join(out) + special_haskell(entries, types)


def operation_haskell(opcode, entry, types, generic):
    variables = ["a" + str(i) for i in range(len(entry["args"]))]
    wrappers = []
    if "RealFloat" in entry["constraints"]:
        wrappers.append("realFloat w $ ")
    elif "Fractional" in entry["constraints"]:
        wrappers.append("fractional w $ ")
    if "Ord " in entry["constraints"] or "Ord a" in entry["constraints"]:
        wrappers.append("ordered w $ ")
    if entry["name"] in ("hermitianMatrix", "conjugateTranspose"):
        wrappers.append("withComplex w $ \\cw -> ")
    lines = [
        "    ("
        + str(opcode)
        + ",["
        + ",".join(variables)
        + "]) -> "
        + "".join(wrappers)
        + "do\n"
    ]
    for variable, spec in zip(variables, entry["args"]):
        lines.append(
            "        "
            + variable
            + "Value <- ("
            + decode_expr(spec, variable, types)
            + " :: IO "
            + hs_type(spec, types)
            + ")\n"
        )
    call = (
        "("
        + MODULES[entry["module"]][0]
        + "."
        + entry["name"]
        + " "
        + " ".join(x + "Value" for x in variables)
        + ")"
    )
    # Result annotations fix constructor/result-only generic type variables.
    call = "(" + call + " :: " + hs_type(entry["result"], types) + ")"
    lines.append("        " + encode_expr(entry["result"], call, types) + "\n")
    return "".join(lines)


CALLBACK_HS = """
data Callback=Callback (FunPtr ()) (Ptr ())
foreign import ccall safe "hm_linear_invoke_callback"
    invokeCallback :: FunPtr () -> Ptr () -> StablePtr X.Value -> Ptr(StablePtr X.Value) -> Ptr () -> IO CInt
callbackValue :: X.Value -> X.Value -> IO X.Value
callbackValue (X.Opaque 101 _ _ _ payload) argument=case cast payload of
    Just(Callback function userdata) -> do
        X.forceValue argument
        bracket (newStablePtr argument) freeStablePtr $ \\input -> alloca $ \\out -> withMathErrorWire $ \\wire -> do
            status <- invokeCallback function userdata input out wire
            if status/=0 then readCallbackFailure status wire >>= throwIO
            else peek out >>= \\pointer -> bracket(pure pointer) freeStablePtr deRefStablePtr
    Nothing -> X.invalid "invalid linear callback payload"
callbackValue _ _=X.invalid "expected linear callback"
foreign export ccall "hm_linear_callback" createCallback :: FunPtr () -> Ptr () -> Ptr(StablePtr X.Value) -> IO CInt
createCallback :: FunPtr () -> Ptr () -> Ptr(StablePtr X.Value) -> IO CInt
createCallback pointer userdata out=linearBoundary $ Boundary.checked(Right()) $ const $ X.publish (X.Opaque 101 (-1) 0 (pure()) (Callback pointer userdata)) out
"""


def special_haskell(entries, types):
    opcode = {e["name"]: i for i, e in enumerate(entries)}
    return (
        """
{-# NOINLINE generateCallback #-}
generateCallback :: Coefficient a => X.Value -> Int -> Int -> a
generateCallback callback row column=unsafePerformIO $ callbackValue callback (X.Tuple[X.Index row,X.Index column]) >>= X.asScalar
{-# NOINLINE zipCallback #-}
zipCallback :: (Coefficient a,Coefficient b,Coefficient c) => ScalarType a -> ScalarType b -> X.Value -> a -> b -> c
zipCallback wa wb callback left right=unsafePerformIO $ callbackValue callback (X.Tuple[X.Scalar wa left,X.Scalar wb right]) >>= X.asScalar
special :: Int -> X.Value -> [X.Value] -> IO X.Value
special operation prototype args=case(operation,args) of
    ("""
        + str(opcode["fixedVector"])
        + """,[dimension,values]) -> withWitness prototype $ \\(w::ScalarType a) -> do
        count <- X.asIndex dimension
        xs <- X.asList values >>= mapM X.asScalar
        fixedFrom w count xs
    ("""
        + str(opcode["fixedValues"])
        + """,[value]) -> withWitness prototype $ \\(w::ScalarType a) -> do
        fixed <- (unbox "HMath.Vector.FixedVector" value :: IO(SomeFixed a))
        case fixed of SomeFixed f -> X.List . map (X.Scalar w) <$> pure(V.fixedValues f)
    ("""
        + str(opcode["generateMatrix"])
        + """,[rows,columns,callback]) -> withWitness prototype $ \\(w::ScalarType a) -> do
        r <- X.asIndex rows; c <- X.asIndex columns
        matrix <- source(A.generateMatrix r c (generateCallback callback) :: Either E.MathError(M.Matrix a))
        pure(X.Dense(X.SomeMatrix w matrix))
    ("""
        + str(opcode["zipMatrixWith"])
        + """,[callback,left,right]) -> do
        prototypes <- X.asTuple 3 prototype
        case prototypes of
            [pa,pb,pc] -> withWitness pa $ \\(wa::ScalarType a) -> withWitness pb $ \\(wb::ScalarType b) -> withWitness pc $ \\(wc::ScalarType c) -> do
                a <- (asMatrix left :: IO(M.Matrix a)); b <- (asMatrix right :: IO(M.Matrix b))
                matrix <- source(A.zipMatrixWith (zipCallback wa wb callback) a b :: Either E.MathError(M.Matrix c))
                pure(X.Dense(X.SomeMatrix wc matrix))
            _ -> X.invalid "zipMatrixWith requires three coefficient prototypes"
    _ -> X.invalid "invalid special linear operation/arity"
foreign export ccall "hm_linear_apply" ffiApply :: CInt -> StablePtr X.Value -> Ptr(StablePtr X.Value) -> CSize -> Ptr(StablePtr X.Value) -> IO CInt
ffiApply :: CInt -> StablePtr X.Value -> Ptr(StablePtr X.Value) -> CSize -> Ptr(StablePtr X.Value) -> IO CInt
ffiApply operation prototype pointers count out=linearBoundary $ do
    values <- peekArray(fromIntegral count) pointers >>= mapM deRefStablePtr
    let op=fromIntegral operation
    value <- if op `elem` """
        + repr(
            [
                opcode[n]
                for n in [
                    "fixedVector",
                    "fixedValues",
                    "generateMatrix",
                    "zipMatrixWith",
                ]
            ]
        )
        + """ then do
            p <- deRefStablePtr prototype
            if structuralVectorInput p values then structuralVectors op p values else special op p values
        else if op `elem` """
        + repr([i for i, e in enumerate(entries) if generic_entry(e)])
        + """ then do
            p <- deRefStablePtr prototype
            if structuralVectorInput p values then structuralVectors op p values else withWitness p (\\w -> generic w op values)
        else concrete op values
    Boundary.checked(Right())(const(X.publish value out))
"""
    )


def frontend(entries, types, fields):
    import keyword
    import subprocess

    def fmt(source, name):
        fixed = subprocess.run(
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
            input=fixed,
            text=True,
            capture_output=True,
            check=True,
        ).stdout

    h = [
        """/* SPDX-License-Identifier: MPL-2.0 */
/* Generated by tools/generate_linear_bindings.py. */
#ifndef HMATH_LINEAR_H
#define HMATH_LINEAR_H
#include "hmath_value.h"
#include "hmath_matrix.h"
#include "hmath_error.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Direct original Vector, Matrix advanced/decomposition/iterative/LAPACK,
 * Sparse, Sparse.Spectral and Backend API. Values are immutable owned handles;
 * Matrix uses Dense kind9, linear records use kind100 plus object_type query,
 * and typed callback closures use kind101. Retain inputs for the call and
 * release every owned result with hmath_value_release. Outputs remain untouched
 * on failure. Generic functions take a typed scalar prototype before original
 * arguments, even for empty lists. zip_matrix_with takes a tuple of prototypes
 * (inputA,inputB,output). fixed_vector adds a runtime natural dimension that
 * reifies the original KnownNat witness. Num/Fractional/Ord/RealFloat instance
 * availability, defaults, resource limits, finite checks, ordering and errors
 * remain the original Haskell operations. No mandatory native provider.
 * Callback inputs borrow a Value; output transfers one owned reference. Source
 * pure callbacks abort on nonzero status, preserving status11 MathError wire.
 * Callback/userdata must outlive every function/derived object using them. */
typedef hmath_status (*hmath_linear_callback_fn)(const hmath_value *input,void *userdata,hmath_value **out,hmath_math_error *error);
HMATH_API hmath_status hmath_linear_callback(hmath_context *context,hmath_linear_callback_fn callback,void *userdata,hmath_value **out);
HMATH_API hmath_status hmath_linear_object_type(hmath_context *context,const hmath_value *value,hmath_value **out);
HMATH_API hmath_status hmath_linear_object_parts(hmath_context *context,const hmath_value *value,hmath_value **out);
/* Convert original Backend LU/QR outputs to existing typed dense owners. */
HMATH_API hmath_status hmath_linear_export_legacy(hmath_context *context,const hmath_value *value,void **out);
"""
    ]
    c = [
        """/* SPDX-License-Identifier: MPL-2.0 */
/* Generated by tools/generate_linear_bindings.py. */
#include "hmath_linear.h"
#include "value_internal.h"
#include "matrix_internal.h"
#include <stdlib.h>
extern int hm_linear_apply(int opcode,void *prototype,void *const *args,size_t count,void **out);
extern int hm_linear_callback(hmath_linear_callback_fn callback,void *userdata,void **out);
extern int hm_linear_clone(void *value,void **out);
extern int hm_linear_legacy(void *value,int *kind,void **out);
extern void hm_dense_free(void *value);
"""
    ]
    py = {
        namespace: [
            '# SPDX-License-Identifier: MPL-2.0\n# Generated by tools/generate_linear_bindings.py.\n"""Original '
            + module
            + ' public operations and owned records."""\nfrom ._linear_base import LinearValue,_invoke,register\n'
        ]
        for module, (_alias, namespace) in MODULES.items()
    }
    allnames = {ns: [] for ns in py}
    constructor_by_type = {
        e["name"]: e for e in entries if e["constructor"] and e["name"] in types
    }
    for name, t in types.items():
        ns = t["namespace"]
        typename = t["module"] + "." + name
        allnames[ns].append(name)
        h.append(
            "typedef hmath_value hmath_linear_" + ns + "_" + snake(name) + "_object;\n"
        )
        py[ns].append(
            "\nclass "
            + name
            + '(LinearValue):\n    """Original '
            + typename
            + ' immutable owner."""\n    _source_type='
            + repr(typename)
            + "\n"
        )
        constructor = constructor_by_type.get(name)
        lower = {
            "Vector": "vector",
            "FixedVector": "fixedVector",
            "SparseVector": "sparseVector",
            "Sparse": "sparse",
            "SparseTensor": "sparseTensor",
        }.get(name)
        if lower:
            constructor = next(
                e for e in entries if e["module"] == t["module"] and e["name"] == lower
            )
        if constructor:
            specs = constructor["args"]
            if name == "FixedVector":
                specs = [["Int"], ["list", ["a"]]]
            names = (
                [snake(f[0]) for f in fields[name]]
                if fields[name]
                else ["dimension", "values"]
                if name == "FixedVector"
                else ["values"]
                if name == "Vector"
                else ["dimension", "entries"]
                if name == "SparseVector"
                else ["rows", "columns", "entries"]
                if name == "Sparse"
                else ["shape", "entries"]
                if name == "SparseTensor"
                else ["value" + str(i) for i in range(len(specs))]
            )
            signature = ", ".join(names)
            generic = generic_entry(constructor)
            py[ns].append(
                "    def __init__(self, "
                + signature
                + (", *, dtype=None" if generic else "")
                + "):\n"
            )
            py[ns].append(
                "        self._initialize("
                + repr(c_symbol(constructor))
                + ", "
                + repr(generic)
                + ", "
                + repr(specs)
                + ", ["
                + ", ".join(names)
                + "]"
                + (", dtype" if generic else "")
                + ")\n"
            )
        for field, spec in fields[name]:
            entry = next(
                e for e in entries if e["module"] == t["module"] and e["name"] == field
            )
            py[ns].append(
                "    @property\n    def "
                + snake(field)
                + "(self):\n        return _invoke("
                + repr(c_symbol(entry))
                + ", "
                + repr(generic_entry(entry))
                + ", "
                + repr(entry["args"])
                + ", [self])\n"
            )
        py[ns].append("register(" + repr(typename) + ", " + name + ")\n")
    mappings = []
    docs = [
        "# Linear algebra bindings\n\nAll operations below call the original Haskell functions. Generic coefficients support standard Float/Double/Integer/Rational/Complex and bounded integral instances where the source constraints permit. No automatic dtype promotion occurs. RealFloat-only operations retain Float/Double; optional native LAPACK routines retain their original Double/ComplexDouble types and explicit unavailable-provider failures.\n\n"
    ]
    for opcode, entry in enumerate(entries):
        generic = generic_entry(entry)
        args = entry["args"]
        ns = MODULES[entry["module"]][1]
        if entry["name"] == "fixedVector":
            args = [["Int"], ["list", ["a"]]]
        names = []
        for i, spec in enumerate(args):
            base = {
                "Matrix": "matrix",
                "Int": "index",
                "Integer": "integer",
                "Bool": "flag",
                "String": "text",
                "function": "function",
                "list": "values",
            }.get(
                spec[0], snake(spec[0]) if spec[0] not in ("a", "b", "c") else "scalar"
            )
            if keyword.iskeyword(base):
                base += "_"
            names.append(base + str(i + 1))
        symbol = c_symbol(entry)
        params = (
            ["hmath_context *context"]
            + (["const hmath_value *prototype"] if generic else [])
            + ["const hmath_value *" + n for n in names]
            + ["hmath_value **out"]
        )
        proto = "hmath_status " + symbol + "(" + ", ".join(params) + ")"
        h.append(
            "/* "
            + entry["module"]
            + "."
            + entry["name"]
            + " :: "
            + entry["signature"]
            + " */\nHMATH_API "
            + proto
            + ";\n"
        )
        c.append(
            proto
            + " {\n    if (!out"
            + (" || !prototype" if generic else "")
            + "".join(" || !" + n for n in names)
            + ') return hm_error(HMATH_INVALID_ARGUMENT,"NULL linear argument");\n    hmath_value *result; hmath_status status=hm_value_begin(context,&result); if(status) return status;\n'
        )
        cargs = "NULL"
        if names:
            c.append(
                "    void *args[]={"
                + ",".join("hm_value_stable(" + n + ")" for n in names)
                + "};\n"
            )
            cargs = "args"
        c.append(
            "    return hm_value_finish(result,hm_linear_apply("
            + str(opcode)
            + ","
            + ("hm_value_stable(prototype)" if generic else "NULL")
            + ","
            + cargs
            + ","
            + str(len(names))
            + ",&result->stable),out);\n}\n"
        )
        is_record = entry["constructor"] and entry["name"] in types
        pname = entry["name"] if is_record else snake(entry["name"])
        if not is_record:
            allnames[ns].append(pname)
            signature = ", ".join(names) + (
                ", *, dtype=None"
                if generic and names
                else "*, dtype=None"
                if generic
                else ""
            )
            py[ns].append(
                "\ndef "
                + pname
                + "("
                + signature
                + "):\n    "
                + repr(
                    source_prose(entry)
                    + " Call original "
                    + entry["module"]
                    + "."
                    + entry["name"]
                    + " :: "
                    + entry["signature"]
                )
                + "\n    return _invoke("
                + repr(symbol)
                + ", "
                + repr(generic)
                + ", "
                + repr(args)
                + ", ["
                + ", ".join(names)
                + "]"
                + (", dtype=dtype" if generic else "")
                + ")\n"
            )
        mappings.append(
            {
                "symbol": entry["module"] + "." + entry["name"],
                "c": [symbol],
                "python": "hmath." + ns + "." + pname,
                "specializations": [
                    "original source type/constraints; standard coefficient witnesses; full public fields/constructors"
                ],
            }
        )
        docs.append(
            "## `"
            + ns
            + "."
            + pname
            + "`\n\n"
            + source_prose(entry)
            + "\n\nOriginal signature: `"
            + entry["signature"]
            + "`. Original constraints: `"
            + (entry["constraints"] or "none")
            + "`. "
            + (
                "Construct the original public record/variant without inventing validation."
                if entry["constructor"]
                else "Return the original function result and original Either/Maybe failure convention."
            )
            + "\n\n```c\n"
            + proto
            + ";\n```\n\n"
        )
    covered = {m["symbol"] for m in mappings}
    for name, t in types.items():
        symbol = t["module"] + "." + name
        if symbol not in covered:
            mappings.append(
                {
                    "symbol": symbol,
                    "c": [
                        "hmath_linear_" + t["namespace"] + "_" + snake(name) + "_object"
                    ],
                    "python": "hmath." + t["namespace"] + "." + name,
                    "specializations": [
                        "original owned opaque type with source coefficient type"
                    ],
                }
            )
    for name, opcode in [("object_type", -1), ("object_parts", -2)]:
        c.append(
            "hmath_status hmath_linear_"
            + name
            + '(hmath_context *context,const hmath_value *value,hmath_value **out) {\n    if(!value || !out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL linear object query");\n    hmath_value *result; hmath_status status=hm_value_begin(context,&result); if(status) return status;\n    void *args[]={hm_value_stable(value)};\n    return hm_value_finish(result,hm_linear_apply('
            + str(opcode)
            + ",NULL,args,1,&result->stable),out);\n}\n"
        )
    h.append("#ifdef __cplusplus\n}\n#endif\n#endif\n")
    c.append(CALLBACK_C)
    result = {
        "include/hmath_linear.h": "".join(h),
        "cbits/linear.c": "".join(c),
        "bindings/schema/linear-objects.json": json.dumps(
            {"schema": 1, "bindings": sorted(mappings, key=lambda x: x["symbol"])},
            indent=2,
        )
        + "\n",
        "docs/reference/linear-bindings.md": "".join(docs),
    }
    for ns, parts in py.items():
        parts.append("\n__all__=" + repr(sorted(set(allnames[ns]))) + "\n")
        result["bindings/python/_hmath_native/" + ns + ".py"] = fmt(
            "".join(parts), ns + ".py"
        )
    return result


CALLBACK_C = """
hmath_status hmath_linear_callback(hmath_context *context,hmath_linear_callback_fn callback,void *userdata,hmath_value **out) {
    if(!callback || !out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL linear callback/output");
    hmath_value *result; hmath_status status=hm_value_begin(context,&result); if(status) return status;
    return hm_value_finish(result,hm_linear_callback(callback,userdata,&result->stable),out);
}
int hm_linear_invoke_callback(hmath_linear_callback_fn callback,void *userdata,void *argument,void **out,hmath_math_error *error) {
    hmath_value *input=NULL,*borrowed=NULL,*result=NULL;
    hmath_status status=hm_value_begin(NULL,&input);
    if(status) return status;
    status=hm_value_finish(input,hm_linear_clone(argument,&input->stable),&borrowed);
    if(status) return status;
    status=callback(borrowed,userdata,&result,error);
    if(!status) {
        if(!result) { error->message="linear callback returned NULL";error->message_length=29;status=HMATH_INVALID_ARGUMENT; }
        else status=(hmath_status)hm_linear_clone(hm_value_stable(result),out);
    }
    hmath_value_release(result);hmath_value_release(borrowed);
    return status;
}
hmath_status hmath_linear_export_legacy(hmath_context *context,const hmath_value *value,void **out) {
    if(!value || !out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL legacy linear export");
    struct hmath_dense_object *result=calloc(1,sizeof *result);
    if(!result) return hm_error(HMATH_ALLOCATION_FAILED,"legacy linear handle allocation failed");
    hmath_status status=hm_enter(context);if(status) {free(result);return status;}
    int kind=0;status=(hmath_status)hm_linear_legacy(hm_value_stable(value),&kind,&result->stable);
    if(status) {if(result->stable)hm_dense_free(result->stable);free(result);hm_leave();return status;}
    atomic_init(&result->refs,1);result->kind=(unsigned)kind;result->precision=64;*out=result;
    return HMATH_OK;
}
"""


STRUCTURAL_VECTOR_HS = r'''
-- Non-Num vectors retain actual original structural values and their codec.
data StructuralVector where
    StructuralVector :: Typeable a => Int -> (a -> IO X.Value) -> (X.Value -> IO a) -> (a -> IO ()) -> V.Vector a -> StructuralVector
data StructuralFixed where
    StructuralFixed :: Typeable a => Int -> (a -> IO X.Value) -> (X.Value -> IO a) -> (a -> IO ()) -> SomeFixed a -> StructuralFixed
encodeStructuralVector :: Typeable a => Int -> (a -> IO X.Value) -> (X.Value -> IO a) -> (a -> IO ()) -> V.Vector a -> X.Value
encodeStructuralVector code write readValue force value=opaque "HMath.Vector.Vector" code (StructuralVector code write readValue force value)(mapM_ force(V.vectorValues value))(X.unsupported "original Vector is abstract")
encodeStructuralFixed :: Typeable a => Int -> (a -> IO X.Value) -> (X.Value -> IO a) -> (a -> IO ()) -> SomeFixed a -> X.Value
encodeStructuralFixed code write readValue force value=opaque "HMath.Vector.FixedVector" code (StructuralFixed code write readValue force value)(case value of SomeFixed fixed -> mapM_ force(V.fixedValues fixed))(X.unsupported "original FixedVector is abstract")
asStructuralVector :: X.Value -> IO StructuralVector
asStructuralVector=unbox "HMath.Vector.Vector"
asStructuralFixed :: X.Value -> IO StructuralFixed
asStructuralFixed=unbox "HMath.Vector.FixedVector"
structuralVectorValue :: X.Value -> Bool
structuralVectorValue(X.Opaque 100 _ _ _ payload)=case cast payload of
    Just(Envelope _ dynamic _) -> case(fromDynamic dynamic::Maybe StructuralVector,fromDynamic dynamic::Maybe StructuralFixed)of
        (Just _,_) -> True
        (_,Just _) -> True
        _ -> False
    _ -> False
structuralVectorValue(X.List values)=any structuralVectorValue values
structuralVectorValue _=False
structuralVectorInput :: X.Value -> [X.Value] -> Bool
structuralVectorInput prototype args=structuralVectorValue prototype || any structuralVectorValue args || case prototype of
    X.Boolean _ -> True
    X.Text _ -> True
    X.Opaque 294 _ _ _ _ -> True
    _ -> False
withStructuralVector :: X.Value -> [X.Value] -> (forall a. Typeable a => Int -> (a -> IO X.Value) -> (X.Value -> IO a) -> (a -> IO ()) -> IO X.Value) -> IO X.Value
withStructuralVector prototype args action=case filter structuralVectorValue(prototype:concatMap flatten args) of
    first:_ -> do
        name <- objectName first
        if name=="HMath.Vector.Vector" then do
            StructuralVector code write readValue force _ <- asStructuralVector first
            action code write readValue force
        else do
            StructuralFixed code write readValue force _ <- asStructuralFixed first
            action code write readValue force
    [] -> do
        TensorCodec.SomeElement kind <- TensorCodec.element prototype
        action(TensorCodec.elementCode kind)(pure . TensorCodec.scalar kind)(TensorCodec.asElement kind)(TensorCodec.forceElement kind)
  where
    flatten(X.List xs)=concatMap flatten xs
    flatten value=[value]
structuralVectors :: Int -> X.Value -> [X.Value] -> IO X.Value
structuralVectors operation prototype args=withStructuralVector prototype args $ \code write readValue force -> case(operation,args)of
    (OP_vector_,[values]) -> X.asList values >>= mapM readValue >>= pure . encodeStructuralVector code write readValue force . V.vector
    (OP_vectorValues_,[value]) -> do
        StructuralVector _ _ _ _ raw <- asStructuralVector value
        case cast raw of
            Just vector -> X.List <$> mapM write(V.vectorValues vector)
            Nothing -> X.invalid "structural Vector element types differ"
    (OP_vectorDimension_,[value]) -> do StructuralVector _ _ _ _ raw <- asStructuralVector value;pure(X.Index(V.vectorDimension raw))
    (OP_vectorSlice_,[start,count,value]) -> do
        s <- X.asIndex start;n <- X.asIndex count
        StructuralVector _ _ _ _ raw <- asStructuralVector value
        case cast raw of
            Just vector -> encodeStructuralVector code write readValue force <$> source(V.vectorSlice s n vector)
            Nothing -> X.invalid "structural Vector element types differ"
    (OP_vectorConcat_,[values]) -> do
        xs <- X.asList values >>= mapM(\value -> do StructuralVector _ _ _ _ raw <- asStructuralVector value;maybe(X.invalid "structural Vector element types differ")pure(cast raw))
        encodeStructuralVector code write readValue force <$> source(V.vectorConcat xs)
    (OP_fixedVector_,[count,values]) -> do
        n <- X.asIndex count;xs <- X.asList values >>= mapM readValue
        structuralFixedFrom code write readValue force n xs
    (OP_fixedValues_,[value]) -> do
        StructuralFixed _ _ _ _ raw <- asStructuralFixed value
        case cast raw of
            Just(SomeFixed fixed) -> X.List <$>mapM write(V.fixedValues fixed)
            Nothing -> X.invalid "structural FixedVector element types differ"
    _ -> X.unsupported "original vector operation requires a numeric instance"
structuralFixedFrom :: forall a. Typeable a => Int -> (a -> IO X.Value) -> (X.Value -> IO a) -> (a -> IO ()) -> Int -> [a] -> IO X.Value
structuralFixedFrom code write readValue force n xs=case someNatVal(toInteger n)of
    Nothing -> X.invalid "fixed dimension must be nonnegative"
    Just(SomeNat(_::Proxy k)) -> do
        result <- source(V.fixedVector xs::Either E.MathError(V.FixedVector k a))
        pure(encodeStructuralFixed code write readValue force(SomeFixed result))
'''


def outputs():
    global _COUNTER
    _COUNTER = 0
    entries, types, fields, missing = signatures()
    if missing:
        raise ValueError("missing linear source symbols: " + repr(missing))
    result = {
        "src/HMath/FFI/LinearCodec.hs": codec_haskell(types, fields, entries),
        "src/HMath/FFI/LinearAll.hs": dispatch_haskell(entries, types),
        "bindings/schema/linear-functions.json": json.dumps(
            {"functions": entries, "types": types, "fields": fields}, indent=2
        )
        + "\n",
    }
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
