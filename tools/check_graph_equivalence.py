# SPDX-License-Identifier: MPL-2.0
"""Compare every public Graph adapter with independently executed Haskell."""

import argparse
import json
import os
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

from generate_graph_bindings import snake, split_top

ROOT = Path(__file__).resolve().parent.parent
HASKELL = r"""{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeSynonymInstances #-}
import qualified HMath.Graph as G
import qualified HMath.Error as E
import Data.List (intercalate)
import Data.Char (ord)
import GHC.Float (castDoubleToWord64)
class Encode a where enc :: a -> String
instance Encode Int where enc x="I"++show x
instance Encode Integer where enc x="I"++show x
instance Encode Double where enc x="F"++show(castDoubleToWord64 x)
instance Encode Bool where enc x=if x then "B1" else "B0"
instance Encode () where enc ()="T[]"
instance {-# OVERLAPPING #-} Encode String where enc x="S"++show(map ord x)
instance {-# OVERLAPPABLE #-} Encode a => Encode [a] where enc xs="L["++intercalate "," (map enc xs)++"]"
instance Encode a => Encode (Maybe a) where enc Nothing="N"; enc(Just x)=enc x
instance (Encode a,Encode b) => Encode(a,b) where enc(a,b)="T["++enc a++","++enc b++"]"
instance (Encode a,Encode b,Encode c) => Encode(a,b,c) where enc(a,b,c)="T["++enc a++","++enc b++","++enc c++"]"
instance Encode G.Graph where enc x="G"++enc(G.serializeGraph x)
instance Encode G.Edge where enc x="Edge["++intercalate "," [enc(G.edgeId x),enc(G.edgeFrom x),enc(G.edgeTo x),enc(G.edgeWeight x)]++"]"
instance Encode G.CSR where enc x="CSR["++intercalate "," [enc(G.csrDirected x),enc(G.csrVertices x),enc(G.csrOffsets x),enc(G.csrTargets x),enc(G.csrWeights x),enc(G.csrIds x),enc(G.csrOrientations x)]++"]"
instance Encode G.BipartiteGraph where enc x="B"++enc(G.serializeBipartiteGraph x)
instance Encode G.Hypergraph where enc x="H"++enc(G.serializeHypergraph x)
instance Encode G.Network where enc x="Network"++enc(G.networkEdges x)
instance Encode G.NetworkEdge where enc x="NE["++intercalate "," [enc(G.networkEdgeId x),enc(G.networkFrom x),enc(G.networkTo x),enc(G.networkCapacity x),enc(G.networkCost x)]++"]"
instance Encode G.FlowResult where enc x="Flow"++enc(G.flowValue x,G.edgeFlows x,G.flowCost x)
ok :: Encode a => Either E.MathError a -> String
ok=either (("E"++).show) enc
right (Right x)=x
right (Left e)=error(show e)
g=right(G.graph False 4 [(0,1,1),(1,2,2),(2,3,3),(0,3,10)])
dag=right(G.graph True 4 [(0,1,1),(1,2,2),(2,3,3)])
bip=right(G.bipartiteGraph 2 2 [(0,0,1),(0,1,2),(1,0,3)])
hyper=right(G.hypergraph 4 [[0,1],[1,2,3],[]])
net=right(G.network 4 [(0,1,10^40,2),(1,3,10^40,3),(0,2,7,1),(2,3,7,1)])
edge=G.Edge 9 2 1 (-0.0)
csr=G.toCSR g
ne=G.NetworkEdge 5 1 2 (10^50) (-7)
flow=G.FlowResult (10^50) [3,10^50] (-9)
main=mapM_ putStrLn [EXPRESSIONS]
"""


def close(value):
    if hasattr(value, "close"):
        value.close()
    elif isinstance(value, (list, tuple)):
        for item in value:
            close(item)


def encode(value, graph):
    if value is None:
        return "N"
    if isinstance(value, bool):
        return "B1" if value else "B0"
    if isinstance(value, int):
        return "I" + str(value)
    if isinstance(value, float):
        return "F" + str(struct.unpack("!Q", struct.pack("!d", value))[0])
    if isinstance(value, str):
        return "S" + json.dumps(list(map(ord, value)), separators=(",", ":"))
    if isinstance(value, (tuple, list)):
        return (
            ("T[" if isinstance(value, tuple) else "L[")
            + ",".join(encode(v, graph) for v in value)
            + "]"
        )
    if isinstance(value, graph.Graph):
        return "G" + encode(graph.serialize_graph(value), graph)
    if isinstance(value, graph.BipartiteGraph):
        return "B" + encode(graph.serialize_bipartite_graph(value), graph)
    if isinstance(value, graph.Hypergraph):
        return "H" + encode(graph.serialize_hypergraph(value), graph)
    if isinstance(value, graph.Network):
        edges = graph.network_edges(value)
        try:
            return "Network" + encode(edges, graph)
        finally:
            close(edges)
    if isinstance(value, graph.FlowResult):
        return "Flow" + encode(
            (graph.flow_value(value), graph.edge_flows(value), graph.flow_cost(value)),
            graph,
        )
    fields = {
        graph.Edge: ("Edge", ["edge_id", "edge_from", "edge_to", "edge_weight"]),
        graph.CSR: (
            "CSR",
            [
                "csr_directed",
                "csr_vertices",
                "csr_offsets",
                "csr_targets",
                "csr_weights",
                "csr_ids",
                "csr_orientations",
            ],
        ),
        graph.NetworkEdge: (
            "NE",
            [
                "network_edge_id",
                "network_from",
                "network_to",
                "network_capacity",
                "network_cost",
            ],
        ),
    }
    for type_, (label, getters) in fields.items():
        if isinstance(value, type_):
            return (
                label
                + "["
                + ",".join(
                    encode(getattr(graph, name)(value), graph) for name in getters
                )
                + "]"
            )
    raise TypeError(type(value))


def cases(graph):
    owners = {}

    def owner(name, value):
        owners[name] = value
        return value

    g = owner("g", graph.graph(False, 4, [(0, 1, 1), (1, 2, 2), (2, 3, 3), (0, 3, 10)]))
    owner("dag", graph.graph(True, 4, [(0, 1, 1), (1, 2, 2), (2, 3, 3)]))
    owner("bip", graph.bipartite_graph(2, 2, [(0, 0, 1), (0, 1, 2), (1, 0, 3)]))
    owner("hyper", graph.hypergraph(4, [[0, 1], [1, 2, 3], []]))
    owner(
        "net",
        graph.network(
            4, [(0, 1, 10**40, 2), (1, 3, 10**40, 3), (0, 2, 7, 1), (2, 3, 7, 1)]
        ),
    )
    owner("edge", graph.edge(9, 2, 1, -0.0))
    owner("csr", graph.to_csr(g))
    owner("ne", graph.network_edge(5, 1, 2, 10**50, -7))
    owner("flow", graph.flow_result(10**50, [3, 10**50], -9))
    defaults = {
        "Graph": "g",
        "Edge": "edge",
        "CSR": "csr",
        "BipartiteGraph": "bip",
        "Hypergraph": "hyper",
        "Network": "net",
        "NetworkEdge": "ne",
        "FlowResult": "flow",
    }
    overrides = {
        "Edge": ([9, 2, 1, -0.0], ["9", "2", "1", "(-0.0)"]),
        "CSR": (
            [False, 1, [0, 0], [], [], [], []],
            ["False", "1", "[0,0]", "[]", "[]", "[]", "[]"],
        ),
        "NetworkEdge": ([5, 1, 2, 10**50, -7], ["5", "1", "2", "(10^50)", "(-7)"]),
        "FlowResult": ([10**50, [3, 10**50], -9], ["(10^50)", "[3,10^50]", "(-9)"]),
        "graph": (
            [False, 3, [(0, 0, 1), (0, 1, 2), (0, 1, 3)]],
            ["False", "3", "[(0,0,1),(0,1,2),(0,1,3)]"],
        ),
        "bipartiteGraph": ([2, 2, [(0, 1, 3)]], ["2", "2", "[(0,1,3)]"]),
        "hypergraph": ([4, [[0, 1], [2, 3]]], ["4", "[[0,1],[2,3]]"]),
        "network": ([2, [(0, 1, 10**50, -3)]], ["2", "[(0,1,10^50,-3)]"]),
        "aStar": ([g, lambda _: 0.0, 0, 3], ["g", "(const 0)", "0", "3"]),
        "kShortestPaths": ([1000, 3, g, 0, 3], ["1000", "3", "g", "0", "3"]),
        "randomWalk": ([8, 2**64 - 1, g, 0], ["8", "maxBound", "g", "0"]),
        "twoOptTour": ([1000, g, [0, 1, 2, 3, 0]], ["1000", "g", "[0,1,2,3,0]"]),
        "modularity": ([g, [0, 0, 1, 1]], ["g", "[0,0,1,1]"]),
        "pageRank": ([1000, 1e-8, 0.85, g], ["1000", "1e-8", "0.85", "g"]),
        "katzCentrality": (
            [1000, 1e-8, 0.01, 1.0, g],
            ["1000", "1e-8", "0.01", "1", "g"],
        ),
        "hungarian": ([[[10**50, 3], [2, 10**50]]], ["[[10^50,3],[2,10^50]]"]),
    }
    for name in (
        "fordFulkerson",
        "edmondsKarp",
        "dinic",
        "pushRelabel",
        "minimumCostMaximumFlow",
        "minimumCut",
    ):
        overrides[name] = ([10000, owners["net"], 0, 3], ["10000", "net", "0", "3"])
    for name, string in [
        ("deserializeGraph", graph.serialize_graph(g)),
        ("deserializeBipartiteGraph", graph.serialize_bipartite_graph(owners["bip"])),
        ("deserializeHypergraph", graph.serialize_hypergraph(owners["hyper"])),
    ]:
        corresponding = {
            "deserializeGraph": "G.serializeGraph g",
            "deserializeBipartiteGraph": "G.serializeBipartiteGraph bip",
            "deserializeHypergraph": "G.serializeHypergraph hyper",
        }[name]
        overrides[name] = ([string], ["(" + corresponding + ")"])
    orientations = [(0, 1), (1, 2), (2, 3), (0, 3)]
    overrides["fromAdjacencyList"] = (
        [False, graph.adjacency_list(g), orientations],
        ["False", "(G.adjacencyList g)", "[(0,1),(1,2),(2,3),(0,3)]"],
    )
    overrides["fromLabeledAdjacencyMatrix"] = (
        [False, graph.adjacency_matrix(g), orientations],
        ["False", "(G.adjacencyMatrix g)", "[(0,1),(1,2),(2,3),(0,3)]"],
    )
    overrides["fromAdjacencyMatrix"] = (
        [True, [[[], [2.0]], [[], []]]],
        ["True", "[[[],[2]],[[],[]]]"],
    )
    entries = json.loads((ROOT / "bindings/schema/graph-functions.json").read_text())[
        "functions"
    ]
    result = []
    for entry in entries:
        name = entry["name"]
        if name in overrides:
            arguments, expressions = overrides[name]
        else:
            arguments, expressions = [], []
            for typ in split_top(entry["signature"], "->")[:-1]:
                if typ in defaults:
                    key = defaults[typ]
                    arguments.append(owners[key])
                    expressions.append(key)
                elif typ == "Int":
                    arguments.append(1000 if not arguments else 0)
                    expressions.append(str(arguments[-1]))
                elif typ == "Double":
                    arguments.append(1e-8)
                    expressions.append("1e-8")
                elif typ == "Bool":
                    arguments.append(False)
                    expressions.append("False")
                elif typ == "[Int]":
                    arguments.append([0, 2])
                    expressions.append("[0,2]")
                else:
                    raise ValueError((name, typ))
        call = "G." + name + " " + " ".join(expressions)
        checked = split_top(entry["signature"], "->")[-1].startswith("Either MathError")
        result.append(
            (snake(name), arguments, ("ok (" if checked else "enc (") + call + ")")
        )
    # Invalid source inputs and exhausted budgets must retain the original Left.
    result += [
        ("graph", [False, 513, []], "ok(G.graph False 513 [])"),
        (
            "graph",
            [False, 2, [(0, 1, float("inf"))]],
            "ok(G.graph False 2 [(0,1,1/0)])",
        ),
        ("check_vertex", [g, -1], "ok(G.checkVertex g (-1))"),
        ("require_undirected", [owners["dag"]], "ok(G.requireUndirected dag)"),
        ("exact_coloring", [0, g], "ok(G.exactColoring 0 g)"),
        ("dinic", [0, owners["net"], 0, 3], "ok(G.dinic 0 net 0 3)"),
        ("deserialize_graph", ["bad\0input"], 'ok(G.deserializeGraph "bad\\0input")'),
        ("longest_dag_paths", [owners["dag"], 0], "ok(G.longestDAGPaths dag 0)"),
    ]
    return result, owners


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(Path(args.library).resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath

    graph = hmath.graph
    fixtures, owners = cases(graph)
    try:
        with tempfile.TemporaryDirectory(prefix="hmath-graph-oracle-") as directory:
            path = Path(directory) / "Main.hs"
            path.write_text(
                HASKELL.replace(
                    "EXPRESSIONS", ",\n    ".join(case[2] for case in fixtures)
                )
            )
            process = subprocess.run(
                ["runghc", "-isrc", str(path)],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=False,
            )
            if process.returncode:
                raise RuntimeError(process.stderr)
            expected = process.stdout.splitlines()
        actual = []
        for name, arguments, _ in fixtures:
            try:
                result = getattr(graph, name)(*arguments)
            except hmath.HMathError as error:
                actual.append("E" + str(error.math_error or error))
            else:
                try:
                    actual.append(encode(result, graph))
                finally:
                    close(result)
        failures = [
            (i, fixtures[i][0], want, got)
            for i, (want, got) in enumerate(zip(expected, actual))
            if want != got
        ]
        if len(expected) != len(actual) or failures:
            raise AssertionError(f"Graph oracle mismatches: {failures[:12]}")
        print(
            f"Graph direct Haskell equivalence: {len(actual)} cases, all107 public functions/constructors"
        )
    finally:
        for owner in owners.values():
            owner.close()


if __name__ == "__main__":
    main()
