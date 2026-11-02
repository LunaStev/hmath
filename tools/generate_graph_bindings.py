# SPDX-License-Identifier: MPL-2.0
"""Generate named adapters for the concrete public Graph API, without algorithms."""

import argparse
import json
import keyword
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TYPES = {
    "Graph": ("HMath.Graph.Core", 60),
    "Edge": ("HMath.Graph.Core", 61),
    "CSR": ("HMath.Graph.Core", 62),
    "BipartiteGraph": ("HMath.Graph.Core", 63),
    "Hypergraph": ("HMath.Graph.Core", 64),
    "Network": ("HMath.Graph.Flow", 65),
    "NetworkEdge": ("HMath.Graph.Flow", 66),
    "FlowResult": ("HMath.Graph.Flow", 67),
}


def snake(name):
    name = re.sub(r"(.)([A-Z][a-z]+)", r"\1_\2", name)
    return re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", name).lower()


def split_top(text, separator):
    depth, start, result, index = 0, 0, [], 0
    while index < len(text):
        char = text[index]
        if char in "([":
            depth += 1
        elif char in ")]":
            depth -= 1
        if depth == 0 and text.startswith(separator, index):
            result.append(text[start:index].strip())
            start = index + len(separator)
            index += len(separator)
        else:
            index += 1
    return result + [text[start:].strip()]


def type_spec(text, known=None):
    known = TYPES if known is None else known
    text = text.strip()
    if text.startswith("Maybe "):
        return ["maybe", type_spec(text[6:], known)]
    if text.startswith("[") and text.endswith("]"):
        return ["list", type_spec(text[1:-1], known)]
    if text.startswith("(") and text.endswith(")"):
        inner = text[1:-1]
        if not inner:
            return ["unit"]
        fields = split_top(inner, ",")
        if len(fields) > 1:
            return ["tuple", *[type_spec(field, known) for field in fields]]
        arrows = split_top(inner, "->")
        if len(arrows) > 1:
            return ["function", *[type_spec(arrow, known) for arrow in arrows]]
        return type_spec(inner, known)
    if text not in {*known, "Bool", "Int", "Double", "Integer", "String", "Word64"}:
        raise ValueError("unsupported structured type: " + text)
    return [text]


def argument_names(entry, count):
    """Use readable public names without altering the source argument order."""
    overrides = {
        "Edge": "edge_id source target weight",
        "CSR": "directed vertex_count offsets targets weights edge_ids orientations",
        "NetworkEdge": "edge_id source target capacity cost",
        "FlowResult": "value edge_flows cost",
        "graph": "directed vertex_count edges",
        "bipartiteGraph": "left_vertices right_vertices edges",
        "hypergraph": "vertex_count hyperedges",
        "network": "vertex_count edges",
        "fromAdjacencyList": "directed rows orientations",
        "fromLabeledAdjacencyMatrix": "directed cells orientations",
        "fromAdjacencyMatrix": "directed cells",
        "pageRank": "iterations tolerance damping graph",
        "katzCentrality": "iterations tolerance alpha beta graph",
        "eigenvectorCentrality": "iterations tolerance graph",
        "laplacianSpectrum": "iterations tolerance normalized graph",
        "randomWalk": "count seed graph start",
        "kShortestPaths": "budget count graph source target",
        "aStar": "graph heuristic source target",
        "graphEditDistance": "budget left right",
        "graphSimilarity": "left right",
        "hungarian": "costs",
    }
    if entry["name"] in overrides:
        names = overrides[entry["name"]].split()
    else:
        source = (
            ROOT / "src" / (entry["module"].replace(".", "/") + ".hs")
        ).read_text()
        match = re.search(
            r"^" + re.escape(entry["name"]) + r"\s+([^\n=|]+)(?:=|\n\s*\|)",
            source,
            re.MULTILINE,
        )
        parameters = match[1].strip().split() if match else []
        rename = {
            "g": "graph",
            "v": "vertex",
            "b": "budget",
            "net": "network",
            "s": "source",
            "t": "target",
            "steps": "iterations",
            "tol": "tolerance",
            "fs": "flows",
            "n": "vertex_count",
            "es": "edges",
            "bip": "bipartite",
            "h": "hypergraph",
        }
        names = [
            rename.get(p, p) if entry["module"].startswith("HMath.Graph") else snake(p)
            for p in parameters
        ]
        if len(names) != count or any(not name.isidentifier() for name in names):
            types = split_top(entry["signature"], "->")[:-1]
            names = []
            for index, typ in enumerate(types):
                candidate = (
                    snake(typ)
                    if typ in TYPES
                    else ("text" if typ == "String" else "value")
                )
                names.append(
                    candidate if candidate not in names else candidate + str(index + 1)
                )
    if len(names) != count:
        raise ValueError("Graph argument names differ: " + entry["name"])
    used = set()
    for index, name in enumerate(names):
        if keyword.iskeyword(name) or name in {
            "alignas",
            "alignof",
            "auto",
            "bool",
            "break",
            "case",
            "char",
            "class",
            "const",
            "constexpr",
            "continue",
            "default",
            "delete",
            "do",
            "double",
            "else",
            "enum",
            "extern",
            "float",
            "for",
            "friend",
            "goto",
            "inline",
            "int",
            "long",
            "namespace",
            "new",
            "nullptr",
            "operator",
            "private",
            "protected",
            "public",
            "register",
            "return",
            "short",
            "signed",
            "sizeof",
            "static",
            "struct",
            "switch",
            "template",
            "this",
            "throw",
            "typedef",
            "typename",
            "union",
            "unsigned",
            "using",
            "virtual",
            "void",
            "volatile",
            "while",
        }:
            name += "_"
        while name in used:
            name += str(index + 1)
        names[index] = name
        used.add(name)
    return names


def source_prose(entry):
    source = (ROOT / "src" / (entry["module"].replace(".", "/") + ".hs")).read_text()
    signature = re.search(
        r"^" + re.escape(entry["name"]) + r"\s*::", source, re.MULTILINE
    )
    if not signature:
        return "Construct or inspect the original immutable record; field order follows the source signature."
    before = source[: signature.start()].rstrip()
    if before.endswith("-}"):
        start = before.rfind("{- |")
        if start >= 0:
            return re.sub(r"\s+", " ", before[start + 4 : -2]).replace("\\<=", "<=")
    lines = []
    for line in reversed(before.splitlines()):
        if not line.startswith("--"):
            break
        lines.insert(0, line.removeprefix("--").removeprefix(" | ").strip())
    return (
        " ".join(lines)
        or "Return the original field or query result without changing its value."
    )


def generate():
    entries = json.loads((ROOT / "bindings/schema/graph-functions.json").read_text())[
        "functions"
    ]
    numeric = {
        e["module"] + "." + e["name"]
        for e in json.loads((ROOT / "bindings/schema/numeric.json").read_text())[
            "functions"
        ]
    }
    header = [
        "/* SPDX-License-Identifier: MPL-2.0 */\n/* Generated by tools/generate_graph_bindings.py. */\n",
        '#ifndef HMATH_GRAPH_H\n#define HMATH_GRAPH_H\n#include "hmath_value.h"\n',
        '#ifdef __cplusplus\nextern "C" {\n#endif\n',
        "/* Original Graph types are owned hmath_value objects (kinds 60..67).\n",
        " * Pass Boolean, Haskell Int, binary64, exact Integer, String, list and\n",
        " * tuple values matching each source signature. No algorithms or source\n",
        " * limits are replaced. Every output owns one reference; release with\n",
        " * hmath_value_release. Error outputs are untouched. MathError payloads\n",
        " * are available through hmath_last_math_error. Cancellation is checked\n",
        " * before entry; original per-algorithm budgets still apply. */\n",
        "typedef hmath_status (*hmath_graph_heuristic)(ptrdiff_t vertex, void *userdata, double *out);\n",
    ]
    c = [
        "/* SPDX-License-Identifier: MPL-2.0 */\n/* Generated; do not edit. */\n",
        '#include "hmath_graph.h"\n#include "value_internal.h"\n',
        "extern int hm_graph_apply(int, void *const *, size_t, hmath_graph_heuristic, void *, void **);\n",
    ]
    hs = [
        "{-# LANGUAGE ForeignFunctionInterface #-}\n-- SPDX-License-Identifier: MPL-2.0\n-- Generated; do not edit.\nmodule HMath.FFI.Graph where\n",
        "import Foreign\nimport Foreign.C\nimport HMath.FFI.Boundary\nimport HMath.FFI.Value\nimport HMath.FFI.GraphCodec\nimport qualified HMath.Graph as G\n",
        'foreign export ccall "hm_graph_apply" apply :: CInt -> Ptr (StablePtr Value) -> CSize -> FunPtr Heuristic -> Ptr () -> Ptr (StablePtr Value) -> IO CInt\n',
        "apply :: CInt -> Ptr (StablePtr Value) -> CSize -> FunPtr Heuristic -> Ptr () -> Ptr (StablePtr Value) -> IO CInt\n",
        "apply operation input arity callback userdata out = boundary $ do\n    values <- peekArray (fromIntegral arity) input >>= mapM deRefStablePtr\n    case (operation, values) of\n",
    ]
    py = [
        "# SPDX-License-Identifier: MPL-2.0\n# Generated by tools/generate_graph_bindings.py.\n",
        "from ._graph_base import _invoke, _astar\nfrom ._value import Value, register\n",
    ]
    docs = [
        "# Graph bindings\n\nThese adapters call the original Graph functions. Vertex/edge limits, tie order, loops, parallel edges, exact flow capacities and original algorithm budgets are preserved.\n\n",
        "C uses `hmath_graph.h` with owned [structured values](values.md). Python uses `from hmath import graph`. Opaque graph objects support `close()` and context managers. Returned lists, tuples, Booleans, strings, integers, optional values and binary64 values use ordinary Python representations.\n\n",
        "C output handles are owned and remain untouched on failure. Inputs are borrowed throughout a call; callers retain references. Independent calls may share immutable objects and must use independent output addresses. Source `Left MathError` uses status 11 with a lossless structured error. `Maybe` uses `None`/value kind 0. Checked cancellation occurs before entry; source algorithm budgets are not changed.\n\n",
    ]
    mappings = []
    names = {e["name"] for e in entries}
    for name, (module, tag) in TYPES.items():
        py.append(
            f'\n\nclass {name}(Value):\n    """Owned immutable original {module}.{name}."""\n\n\nregister({tag}, {name})\n'
        )
        header.append(f"typedef hmath_value hmath_graph_{snake(name)}_object;\n")
        if name not in names:
            mappings.append(
                {
                    "symbol": module + "." + name,
                    "c": [f"hmath_graph_{snake(name)}_object"],
                    "python": "hmath.graph." + name,
                    "specializations": ["original concrete type"],
                }
            )
    for operation, entry in enumerate(entries):
        pieces = split_top(entry["signature"], "->")
        arguments, result = pieces[:-1], pieces[-1]
        checked = result.startswith("Either MathError ")
        result = result.removeprefix("Either MathError ")
        specs = [type_spec(a) for a in arguments]
        type_spec(result)
        name = snake(entry["name"])
        symbol = "hmath_graph_" + name
        source = entry["module"] + "." + entry["name"]
        args = argument_names(entry, len(arguments))
        heuristic = entry["name"] == "aStar"
        declaration = ["hmath_context *context"]
        for i in range(len(args)):
            if heuristic and i == 1:
                declaration += ["hmath_graph_heuristic heuristic", "void *userdata"]
            else:
                declaration.append("const hmath_value *" + args[i])
        declaration.append("hmath_value **out")
        prototype = f"hmath_status {symbol}(\n    " + ",\n    ".join(declaration) + ")"
        header.append(
            f"/* {source} :: {entry['signature']} */\nHMATH_API {prototype};\n"
        )
        vals = [a for i, a in enumerate(args) if not (heuristic and i == 1)]
        c.append(prototype + " {\n")
        c.append(
            "    if (!out"
            + "".join(" || !" + a for a in vals)
            + (" || !heuristic" if heuristic else "")
            + ')\n        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");\n'
        )
        c.append(
            "    hmath_value *temporary = NULL;\n    hmath_status status = hm_value_begin(context, &temporary);\n    if (status)\n        return status;\n"
        )
        c.append(
            "    void *arguments[] = {"
            + ", ".join("hm_value_stable(" + a + ")" for a in vals)
            + "};\n"
        )
        c.append(
            f"    int code = hm_graph_apply({operation}, arguments, {len(vals)}, "
            + ("heuristic, userdata" if heuristic else "NULL, NULL")
            + ", &temporary->stable);\n    return hm_value_finish(temporary, code, out);\n}\n"
        )
        pattern = ", ".join("v" + a for a in vals)
        hs.append(f"        ({operation}, [{pattern}]) -> do\n")
        for i, a in enumerate(args):
            if heuristic and i == 1:
                hs.append(
                    f"            let {a} = heuristicFunction callback userdata\n"
                )
            else:
                hs.append(f"            {a} <- unwire v{a}\n")
        call = f"G.{entry['name']} " + " ".join(args)
        hs.append(
            "            checked ("
            + (call if checked else "Right (" + call + ")")
            + ") (\\result_value -> publish (wire result_value) out)\n"
        )
        py.append(
            f'\n\ndef {name}({", ".join(args)}):\n    """{source} :: {entry["signature"]}."""\n'
        )
        if heuristic:
            py.append("    return _astar(" + ", ".join(args) + ")\n")
        else:
            py.append(
                f"    return _invoke({symbol!r}, {specs!r}, [{', '.join(args)}])\n"
            )
        docs.append(
            f"## `{name}`\n\n`graph.{name}({', '.join(args)})`\n\n{source_prose(entry)}\n\nOriginal: [`{source}`](haskell/{entry['module'].replace('.', '-')}.md#v:{entry['name']}). Argument order and the full contract are defined there; the original type is:\n\n```haskell\n{entry['signature']}\n```\n\n```c\n{prototype};\n```\n\n"
        )
        if source not in numeric:
            mappings.append(
                {
                    "symbol": source,
                    "c": [symbol],
                    "python": "hmath.graph." + name,
                    "specializations": ["original concrete types"],
                }
            )
    hs.append('        _ -> invalid "Graph operation arity or identifier differs"\n')
    header.append("#ifdef __cplusplus\n}\n#endif\n#endif\n")
    return {
        "include/hmath_graph.h": "".join(header),
        "cbits/graph_bindings.c": "".join(c),
        "src/HMath/FFI/Graph.hs": "".join(hs),
        "bindings/python/_hmath_native/graph.py": "".join(py),
        "docs/reference/graph-bindings.md": "".join(docs),
        "bindings/schema/graph-objects.json": json.dumps(
            {"schema": 1, "bindings": mappings}, indent=2
        )
        + "\n",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    for name, text in generate().items():
        path = ROOT / name
        if args.check:
            if not path.exists() or path.read_text() != text:
                parser.exit(1, "Stale Graph binding: " + name + "\n")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)


if __name__ == "__main__":
    main()
