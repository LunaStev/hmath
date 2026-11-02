# SPDX-License-Identifier: MPL-2.0
"""Independent original-source oracle for persistent/discrete/convergence APIs."""

import argparse
import importlib
import os
import subprocess
import sys
import tempfile
from fractions import Fraction
from pathlib import Path

from check_polynomial_equivalence import HASKELL, bits, close
from generate_foundation_bindings import MODULES, pyname, specification

ROOT = Path(__file__).resolve().parent.parent


def normalized(value, modules):
    import hmath
    from _hmath_native._foundation_base import FoundationValue

    if isinstance(value, FoundationValue):
        d, s = modules["HMath.DataStructure"], modules["HMath.Discrete"]
        name = value.source_type.rsplit(".", 1)[-1]
        if name == "Fenwick":
            observation = d.fenwick_prefix(2, value)
        elif name == "SegmentTree":
            observation = d.segment_range(0, 2, value)
        elif name == "SparseTable":
            observation = d.sparse_minimum(0, 2, value)
        elif name == "DisjointSparseTable":
            observation = d.disjoint_range(0, 2, value)
        elif name in ("Heap", "BinaryHeap", "IndexedHeap"):
            pop = {
                "Heap": d.heap_pop,
                "BinaryHeap": d.binary_pop,
                "IndexedHeap": d.indexed_pop,
            }[name]
            observation = []
            current = value.clone()
            try:
                while True:
                    result = pop(current)
                    current.close()
                    current = None
                    if result is None:
                        break
                    item, current = result
                    observation.append(item)
            finally:
                close(current)
        elif name == "UnionFind":
            observation = d.components(value)
        elif name == "Bloom":
            observation = (
                [d.bloom_member(x, value) for x in [0, 1, 7, 42]],
                d.bloom_false_positive_bound(value),
            )
        elif name == "CountMin":
            observation = (
                [d.count_min_estimate(x, value) for x in [0, 1, 7, 42]],
                d.count_min_error_bound(value),
            )
        elif name == "HyperLogLog":
            observation = d.hll_estimate(value)
        elif name == "Reservoir":
            observation = d.reservoir_values(value)
        elif name == "OnlineQuantiles":
            try:
                observation = d.online_quantile(0.5, value)
            except hmath.HMathError as error:
                return "O" + name + "(E" + str(error.math_error) + ")"
        elif name == "MultiSet":
            observation = s.multiset_entries(value)
        elif name == "BitSet":
            observation = (s.bit_width(value), s.bit_value(value))
        else:
            observation = value.parts
        try:
            return "O" + name + "(" + normalized(observation, modules) + ")"
        finally:
            close(observation)
    if value is None:
        return "N"
    if isinstance(value, bool):
        return "B1" if value else "B0"
    if isinstance(value, int):
        return "I" + str(value)
    if isinstance(value, Fraction):
        return f"R{value.numerator}/{value.denominator}"
    if isinstance(value, float):
        return "F64:" + str(bits(value, 64))
    if isinstance(value, str):
        return "L[" + ",".join("I" + str(ord(c)) for c in value) + "]"
    if isinstance(value, (list, tuple)):
        return (
            ("T[" if isinstance(value, tuple) else "L[")
            + ",".join(normalized(x, modules) for x in value)
            + "]"
        )
    raise TypeError(type(value))


class Fixtures:
    def __init__(self, modules):
        self.modules = modules
        self.owned = []

    def own(self, value, expression):
        if hasattr(value, "close"):
            self.owned.append(value)
        return value, expression

    def object(self, name):
        d = self.modules["HMath.DataStructure"]
        s = self.modules["HMath.Discrete"]
        v = self.modules["HMath.API.Convergence"]
        if name == "Fenwick":
            return self.own(d.fenwick([1, 2, 3]), "right(D.fenwick [1,2,3])")
        if name == "SegmentTree":
            return self.own(d.segment_tree([1, 2, 3]), "right(D.segmentTree [1,2,3])")
        if name == "SparseTable":
            return self.own(d.sparse_table([1, 2, 3]), "right(D.sparseTable [1,2,3])")
        if name == "DisjointSparseTable":
            return self.own(
                d.disjoint_sparse_table([1, 2, 3]),
                "right(D.disjointSparseTable [1,2,3])",
            )
        if name == "Heap":
            return self.own(
                d.heap_from_list([1, 2, 3]), "(D.heapFromList [1,2,3]::D.Heap Integer)"
            )
        if name == "BinaryHeap":
            return self.own(d.binary_heap([1, 2, 3]), "right(D.binaryHeap [1,2,3])")
        if name == "IndexedHeap":
            heap, _ = self.own(d.indexed_heap(), "D.indexedHeap")
            return self.own(
                d.indexed_set(2, 10, heap), "D.indexedSet 2 10 D.indexedHeap"
            )
        if name == "UnionFind":
            return self.own(d.union_find(3), "right(D.unionFind 3)")
        if name == "Bloom":
            return self.own(d.bloom(32, 3), "right(D.bloom 32 3)")
        if name == "CountMin":
            return self.own(d.count_min(16, 3), "right(D.countMin 16 3)")
        if name == "HyperLogLog":
            return self.own(d.hyper_log_log(4), "right(D.hyperLogLog 4)")
        if name == "Reservoir":
            return self.own(
                d.reservoir(3, 42), "(right(D.reservoir 3 42)::D.Reservoir Integer)"
            )
        if name == "OnlineQuantiles":
            return self.own(d.online_quantiles(8), "right(D.onlineQuantiles 8)")
        if name == "MultiSet":
            return self.own(
                s.multiset([1, 2, 2]), "(S.multiset [1,2,2]::S.MultiSet Integer)"
            )
        if name == "BitSet":
            return self.own(s.bit_set(8, 5), "right(S.bitSet 8 5)")
        if name == "Prop":
            return self.own(s.variable(0), "S.Variable 0")
        if name == "Implicant":
            return self.own(s.Implicant(1, 2), "S.Implicant 1 2")
        if name == "StopReason":
            return self.own(v.residual_satisfied(), "V.ResidualSatisfied")
        if name == "IterationOptions":
            return self.own(v.IterationOptions(5, 0.0, 0.0), "V.IterationOptions 5 0 0")
        if name == "Convergence":
            reason, _hs = self.object("StopReason")
            return self.own(
                v.Convergence(7, 1, 0.0, reason),
                "(V.Convergence 7 1 0 V.ResidualSatisfied::V.Convergence Integer)",
            )
        raise ValueError(name)

    def argument(self, spec, name, index):
        head, *args = spec
        if head in TYPES:
            return self.object(head)
        if head == "a":
            return 2, "(2::Integer)"
        if head == "e":
            return "missing", '"missing"'
        if head == "Int":
            value = 1
            if name in ("permutationsOf", "combinationsOf"):
                value = 100 if index == 0 else 2
            elif name in ("derangements", "integerPartitions", "setPartitions"):
                value = 100 if index == 0 else 3
            elif name in ("subsets", "cartesianProduct", "multisetPermutations"):
                value = 100
            elif name in ("runLengthDecode", "memoizedDP"):
                value = 100 if index == 0 else 3
            elif name in ("truthTable",):
                value = 2
            elif name == "quineMcCluskey":
                value = 20 if index == 0 else 2
            elif name in ("bloom", "countMin"):
                value = 16 if index == 0 else 3
            elif name in ("hyperLogLog",) or name in (
                "onlineQuantiles",
                "unionFind",
                "pascalTriangle",
                "tabulateDP",
                "ternarySearch",
            ):
                value = 4
            elif name in (
                "fenwickRange",
                "segmentRange",
                "sparseMinimum",
                "disjointRange",
            ):
                value = 0 if index == 0 else 2
            elif name in ("union", "connected"):
                value = index
            elif name == "IterationOptions":
                value = 5
            return value, str(value)
        if head == "Integer":
            return (2, "2")
        if head == "Word64":
            return (42, "42")
        if head == "Double":
            value = 0.5
            if name == "ternarySearch":
                value = 0.0 if index == 2 else 2.0
            return value, str(value)
        if head == "Rational":
            return Fraction(1, 2), "(1%2)"
        if head == "Bool":
            return True, "True"
        if head == "String":
            return "operation", '"operation"'
        if head == "Maybe":
            return 2, "Just(2::Integer)"
        if head == "Either":
            c = self.modules["HMath.API.Convergence"]
            return self.own(c.right(2), "(Right 2::Either String Integer)")
        if head == "list":
            if args[0] == ["a"]:
                return [1, 2, 3], "([1,2,3]::[Integer])"
            if args[0] == ["Integer"]:
                return [1, 2, 3], "[1,2,3]"
            if args[0] == ["Double"]:
                return [0.0, 1.0, 2.0], "[0,1,2]"
            if args[0] == ["Bool"]:
                return [True, False], "[True,False]"
            if args[0] == ["Rational"]:
                return [Fraction(1), Fraction(1)], [1, 1].__str__()
            if args[0] == ["list", ["Bool"]]:
                return [[True, False], [False, True]], "[[True,False],[False,True]]"
            item, hs = self.argument(args[0], name, index)
            return [item], "[" + hs + "]"
        if head == "tuple":
            values = []
            expressions = []
            for i, child in enumerate(args):
                value, hs = self.argument(child, name, i)
                values.append(value)
                expressions.append(hs)
            return tuple(values), "(" + ",".join(expressions) + ")"
        if head == "function":
            if name == "ternarySearch":
                return lambda x: (x - 1.0) ** 2, "(\\x -> (x-1)*(x-1))"
            if name == "divideConquerDP":
                return lambda i, j: float(i + j), "(\\i j -> fromIntegral(i+j))"
            if name == "tabulateDP":
                return lambda i: [], "(const [])"
            if name == "memoizedDP":
                return lambda i: (i, []), "(\\i -> (toInteger i,[]))"
            if name == "iterateUntil":
                if index == 1:
                    return lambda x: x + 1, "(Right . (+1))"
                if index == 2:
                    return lambda x: float(
                        max(0, 4 - x)
                    ), "(\\x -> Right(fromInteger(max 0 (4-x))))"
                return lambda a, b: a == b, "(==)"
        raise ValueError((spec, name, index))


def hs_type(spec):
    head, *args = spec
    if head == "a":
        return "Integer"
    if head == "e":
        return "String"
    if head == "MathError":
        return "HMath.Error.MathError"
    if head == "list":
        return "[" + hs_type(args[0]) + "]"
    if head == "tuple":
        return "(" + ",".join(hs_type(s) for s in args) + ")"
    if head in TYPES:
        head = TYPES[head]["alias"] + "." + head
    return "(" + head + (" " + " ".join(hs_type(s) for s in args) if args else "") + ")"


def instances(entries, types):
    out = [
        'instance E Char where enc c="I"++show(ord c)\ninstance E Word64 where enc x="I"++show x\ninstance E () where enc ()="N"\ninstance(E a,E b,E c,E d)=>E(a,b,c,d)where enc(a,b,c,d)="T["++intercalate ","[enc a,enc b,enc c,enc d]++"]"\ninstance(E a,E b)=>E(Either a b)where enc(Left e)="OEither("++enc("Left",e)++")";enc(Right x)="OEither("++enc("Right",x)++")"\nright=either(error.show)id\ndrain pop value=case pop value of Nothing->[];Just(x,next)->x:drain pop next\n'
    ]
    observations = {
        "Fenwick": "enc(right(D.fenwickPrefix 2 value))",
        "SegmentTree": "enc(right(D.segmentRange 0 2 value))",
        "SparseTable": "enc(right(D.sparseMinimum 0 2 value))",
        "DisjointSparseTable": "enc(right(D.disjointRange 0 2 value))",
        "Heap": "enc(drain D.heapPop value)",
        "BinaryHeap": "enc(drain D.binaryPop value)",
        "IndexedHeap": "enc(drain D.indexedPop value)",
        "UnionFind": "enc(D.components value)",
        "Bloom": "enc(map(\\x -> D.bloomMember x value)[0,1,7,42],D.bloomFalsePositiveBound value)",
        "CountMin": "enc(map(\\x -> D.countMinEstimate x value)[0,1,7,42],D.countMinErrorBound value)",
        "HyperLogLog": "enc(D.hllEstimate value)",
        "Reservoir": "enc(D.reservoirValues value)",
        "OnlineQuantiles": "ok(D.onlineQuantile 0.5 value)",
        "MultiSet": "enc(S.multisetEntries value)",
        "BitSet": "enc(S.bitWidth value,S.bitValue value)",
    }
    for name, t in types.items():
        params = t["params"]
        constraints = ""
        if params:
            constraints = (
                "("
                + ",".join(
                    ("Ord " + p if name in ("Heap", "MultiSet") else "E " + p)
                    for p in params
                )
                + ",E "
                + params[0]
                + ") => "
            )
        out.append(
            "instance "
            + constraints
            + "E("
            + t["alias"]
            + "."
            + name
            + (" " + " ".join(params) if params else "")
            + ')where\n    enc value="O'
            + name
            + '("++('
        )
        if name in observations:
            expr = observations[name]
        else:
            variants = []
            for e in entries:
                if not e["constructor"] or e["result"][0] != name:
                    continue
                vs = ["p" + str(i) for i in range(len(e["args"]))]
                variants.append(
                    t["alias"]
                    + "."
                    + e["name"]
                    + " "
                    + " ".join(vs)
                    + ' -> "T["++enc("'
                    + e["name"]
                    + '")++",T["++intercalate ","['
                    + ",".join("enc " + v for v in vs)
                    + ']++"]]"'
                )
            expr = "case value of {" + ";".join(variants) + "}"
        out.append(expr + ')++")"\n')
    return "".join(out)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--library", required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(Path(args.library).resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    from _hmath_native import algebra_api, autodiff, polynomial, tensor

    entries, types, _ = specification()
    global TYPES
    TYPES = types
    modules = {
        m: importlib.import_module("_hmath_native." + ns)
        for m, (_alias, ns, _public) in MODULES.items()
    }
    tests = []
    expressions = []
    owners = []
    for e in entries:
        fixture = Fixtures(modules)
        values = []
        hsargs = []
        for index, spec in enumerate(e["args"]):
            value, hs = fixture.argument(spec, e["name"], index)
            values.append(value)
            hsargs.append(hs)
        operation = MODULES[e["module"]][0] + "." + e["name"]
        expression = (
            "("
            + operation
            + " "
            + " ".join("(" + h + ")" for h in hsargs)
            + "::"
            + hs_type(e["result"])
            + ")"
        )
        if e["name"] == "Converged":
            expression = (
                "(case " + hsargs[0] + " of V.Converged x -> Just x;_ -> Nothing)"
            )
        checked = e["result"][:2] == ["Either", ["MathError"]]
        expressions.append(
            "putStrLn(" + ("ok" if checked else "enc") + " " + expression + ")"
        )
        tests.append(
            (
                getattr(modules[e["module"]], pyname(e, types)),
                values,
                e["module"] + "." + e["name"],
            )
        )
        owners += fixture.owned

    def owned(value):
        owners.append(value)
        return value

    def counts(values):
        result = modules["HMath.Algorithms"].run_length_encode(values)
        try:
            return [count for _, count in result]
        finally:
            close(result)

    p = owned(polynomial.polynomial([1, 0], dtype="rational"))
    q = owned(polynomial.polynomial([2], dtype="rational"))
    series = owned(polynomial.power_series([1, 0], dtype="rational"))
    short_series = owned(polynomial.power_series([1], dtype="rational"))
    numerator = owned(polynomial.polynomial([1], dtype="rational"))
    denominator = owned(polynomial.polynomial([1, 1], dtype="rational"))
    rf = owned(polynomial.rational_function(numerator, denominator))
    exact = owned(algebra_api.Exact(Fraction(1, 3)))
    equality_cases = [
        (
            "Polynomial",
            [p, p, q],
            "[P.polynomial [1,0],P.polynomial [1,0],P.polynomial [2]]::[P.Polynomial Rational]",
        ),
        (
            "PowerSeries",
            [series, series, short_series],
            "[P.powerSeries [1,0],P.powerSeries [1,0],P.powerSeries [1]]::[P.PowerSeries Rational]",
        ),
        (
            "RationalFunction",
            [rf, rf],
            "[right(P.rationalFunction(P.polynomial[1])(P.polynomial[1,1])),right(P.rationalFunction(P.polynomial[1])(P.polynomial[1,1]))]",
        ),
    ]
    for dtype, values, hs_values, hstype in [
        ("integer", [1, 2], "[1,2]", "Integer"),
        ("bool", [True, False], "[True,False]", "Bool"),
        ("string", ["α\0", "β"], '["α\\NUL","β"]', "String"),
        (exact, [exact, exact], "[API.Exact(1%3),API.Exact(1%3)]", "API.Exact"),
    ]:
        matrix = owned(algebra_api.matrix_construct(1, 2, values, dtype=dtype))
        equality_cases.append(
            (
                "Matrix-" + hstype,
                [matrix, matrix],
                "let x=right(M.fromListChecked 1 2 ("
                + hs_values
                + "::["
                + hstype
                + "])) in [x,x]",
            )
        )
        value = owned(algebra_api.tensor_construct([2], values, dtype=dtype))
        equality_cases.append(
            (
                "Tensor-" + hstype,
                [value, value],
                "let x=right(T.tensor[2]("
                + hs_values
                + "::["
                + hstype
                + "])) in [x,x]",
            )
        )
    nan = owned(tensor.tensor([1], [float("nan")]))
    equality_cases.append(
        ("Tensor-NaN", [nan, nan], "let x=right(T.tensor[1][0/0::Double]) in [x,x]")
    )
    value = owned(tensor.tensor([2, 2], [1.0, 1.0, 1.0, 1.0]))
    view = owned(tensor.transpose_tensor(value))
    equality_cases.append(
        (
            "Tensor-logical-view",
            [value, view],
            "let x=right(T.tensor[2,2][1,1,1,1::Double]);y=right(T.transposeTensor x) in [x,y]",
        )
    )
    dual = owned(autodiff.Dual(1 + 2j, 3 + 4j, dtype="complex128"))
    different = owned(autodiff.Dual(1 + 2j, 5 + 6j, dtype="complex128"))
    equality_cases.append(
        (
            "AD-Dual-Complex-full-Eq",
            [dual, dual, different],
            "[AD.Dual(1:+2)(3:+4),AD.Dual(1:+2)(3:+4),AD.Dual(1:+2)(5:+6)]::[AD.Dual(Complex Double)]",
        )
    )
    for name, values, expression in equality_cases:
        tests.append((counts, [values], "original Eq " + name))
        expressions.append(
            "putStrLn(enc(map snd(A.runLengthEncode(" + expression + "))))"
        )
    imports = (
        "\n".join(
            "import qualified " + m + " as " + a for m, (a, *_) in MODULES.items()
        )
        + "\nimport Data.Char(ord)\nimport Data.Word(Word64)\nimport qualified HMath.Tensor as T\nimport qualified HMath.API.Algebra as API\nimport qualified HMath.Autodiff as AD\n"
    )
    source = HASKELL.split("pR=")[0].replace(
        "import qualified HMath.Polynomial as P",
        imports + "\nimport qualified HMath.Polynomial as P",
    )
    source = (
        "{-# LANGUAGE PatternSynonyms #-}\n"
        + source
        + instances(entries, types)
        + "main=do\n    "
        + "\n    ".join(expressions)
        + "\n"
    )
    with tempfile.TemporaryDirectory() as directory:
        oracle = Path(directory) / "Oracle.hs"
        oracle.write_text(source)
        result = subprocess.run(
            ["runghc", "-isrc", str(oracle)],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode:
            raise SystemExit(result.stderr)
    lines = result.stdout.splitlines()
    if len(lines) != len(tests):
        raise AssertionError((len(lines), len(tests)))
    try:
        for (function, values, name), expected in zip(tests, lines):
            try:
                value = function(*values)
                actual = normalized(value, modules)
                close(value)
            except hmath.HMathError as error:
                actual = "E" + str(error.math_error)
            if actual != expected:
                raise AssertionError((name, actual, expected))
    finally:
        for owner in owners:
            owner.close()
    print(
        f"Foundation direct Haskell equivalence: {len(tests)} operations/constructors;148 source symbols"
    )


if __name__ == "__main__":
    main()
