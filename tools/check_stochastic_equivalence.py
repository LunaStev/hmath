# SPDX-License-Identifier: MPL-2.0
"""Original-source oracle: complete seeded streams, distributions and statistics."""

import argparse
import importlib
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from check_polynomial_equivalence import HASKELL, bits, close
from generate_stochastic_bindings import MODULES, hs_type, python_name, specification

ROOT = Path(__file__).resolve().parent.parent


def normalize(value, modules):
    import hmath
    from _hmath_native._matrix_base import Matrix
    from _hmath_native._stochastic_base import StochasticValue

    if isinstance(value, StochasticValue):
        kind = value.info[0]
        if kind == 240:
            data = modules["HMath.Random"].serialize_rng(value)
        elif kind == 242:
            r = modules["HMath.Random"]
            generator = r.pcg32()
            state = r.seed_rng(generator, 42)
            try:
                data = r.alias_sample(value, state)
            finally:
                generator.close()
                state.close()
        elif kind == 244:
            p = modules["HMath.Probability"]
            data = (p.transition(value, [1, 0]), p.transition(value, [0, 1]))
        elif kind == 245:
            p = modules["HMath.Probability"]
            data = (p.forward(value, [0, 1]), p.backward(value, [0, 1]))
        elif kind == 246:
            try:
                data = modules["HMath.Statistics.Advanced"].streaming_result(
                    False, value
                )
            except hmath.HMathError as error:
                return "O246(E" + str(error.math_error) + ")"
        else:
            data = value.parts
        try:
            return "O" + str(kind) + "(" + normalize(data, modules) + ")"
        finally:
            close(data)
    if isinstance(value, Matrix):
        r, c = value.shape
        return (
            f"M{r}:{c}["
            + ",".join(normalize(x, modules) for x in value.to_list())
            + "]"
        )
    if value is None:
        return "N"
    if isinstance(value, bool):
        return "B1" if value else "B0"
    if isinstance(value, int):
        return "I" + str(value)
    if isinstance(value, float):
        return "F64:" + str(bits(value, 64))
    if isinstance(value, str):
        return "L[" + ",".join("I" + str(ord(c)) for c in value) + "]"
    if isinstance(value, (tuple, list)):
        return (
            ("T[" if isinstance(value, tuple) else "L[")
            + ",".join(normalize(x, modules) for x in value)
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
        r = self.modules["HMath.Random"]
        p = self.modules["HMath.Probability"]
        s = self.modules["HMath.Statistics.Advanced"]
        if name == "Generator":
            return self.own(r.pcg32(), "R.PCG32")
        if name == "RNG":
            g, _ = self.object("Generator")
            return self.own(r.seed_rng(g, 42), "(R.seedRNG R.PCG32 42)")
        if name == "AliasTable":
            return self.own(r.alias_table([1, 2, 3]), "(right(R.aliasTable [1,2,3]))")
        if name == "Distribution":
            return self.own(p.normal(0, 1), "(P.Normal 0 1)")
        if name == "Markov":
            return self.own(
                p.markov([[0.8, 0.2], [0.1, 0.9]]),
                "(right(P.markov [[0.8,0.2],[0.1,0.9]]))",
            )
        if name == "HMM":
            return self.own(
                p.hmm([0.5, 0.5], [[0.8, 0.2], [0.1, 0.9]], [[0.7, 0.3], [0.2, 0.8]]),
                "(right(P.hmm [0.5,0.5] [[0.8,0.2],[0.1,0.9]] [[0.7,0.3],[0.2,0.8]]))",
            )
        if name == "Streaming":
            return self.own(s.empty_streaming(), "S.emptyStreaming")
        if name == "TestResult":
            return self.own(
                s.TestResult(1.5, 0.25, [2.0]), "(S.TestResult 1.5 0.25 [2])"
            )
        raise ValueError(name)

    def argument(self, spec, name, index):
        r = self.modules["HMath.Random"]
        head, *args = spec
        if head in (
            "Generator",
            "RNG",
            "AliasTable",
            "Distribution",
            "Markov",
            "HMM",
            "Streaming",
            "TestResult",
        ):
            return self.object(head)
        if head == "a":
            return 7, "(7::Integer)"
        if head == "Int":
            value = 3 if name not in ("uniformInt", "stationary", "baumWelch") else 2
            return value, str(value)
        if head == "Integer":
            return 10, "10"
        if head == "Word64":
            return 42, "42"
        if head == "Double":
            value = 0.25
            if name in (
                "normal",
                "exponential",
                "gamma",
                "beta",
                "poisson",
                "binomial",
            ):
                value = 1.0 if index < 2 else 0.25
            if name in ("hamiltonianMonteCarlo", "metropolisHastings"):
                value = 0.1
            return value, str(value)
        if head == "Bool":
            return False, "False"
        if head == "String":
            state, hs = self.object("RNG")
            return r.serialize_rng(state), "R.serializeRNG " + hs
        if head == "Matrix":
            from _hmath_native import matrix as m

            return self.own(
                m.from_list_checked(2, 2, [1, 0, 0, 1]),
                "(right(M.fromListChecked 2 2 [1,0,0,1]))",
            )
        if head == "list":
            child = args[0]
            if child == ["Double"]:
                value = [1.0, 2.0, 3.0, 4.0]
                if name in (
                    "forward",
                    "backward",
                    "posteriorStates",
                    "viterbi",
                    "baumWelch",
                ):
                    value = [0.0, 1.0]
                if name in (
                    "sampleMultivariateNormal",
                    "multivariateNormalLogDensity",
                    "gibbs",
                    "hamiltonianMonteCarlo",
                ):
                    value = [0.0, 0.0]
                return value, str(value)
            if child == ["Int"]:
                return [0, 1], "[0,1]"
            if child == ["Bool"]:
                return [True, False, True], "[True,False,True]"
            if child == ["a"]:
                return [10, 20, 30], "([10,20,30]::[Integer])"
            value, expression = self.argument(child, name, index)
            return [value], "[" + expression + "]"
        if head == "tuple":
            values = []
            expressions = []
            for i, s in enumerate(args):
                v, h = self.argument(s, name, i)
                values.append(v)
                expressions.append(h)
            return tuple(values), "(" + ",".join(expressions) + ")"
        if head == "function":
            result = args[-1]
            if name == "sampleN":

                def sample(state):
                    word, next_state = r.next_word64(state)
                    return word, next_state

                return (
                    sample,
                    "(\\state -> let(word,next)=R.nextWord64 state in Right(toInteger word,next))",
                )
            if name == "rejection":
                return (
                    (lambda _x: 1.0, "(const 1)")
                    if result == ["Double"]
                    else (lambda state: r.uniform(state), "(Right . R.uniform)")
                )
            if name == "inverseTransform":
                return lambda x: x, "Right"
            if name == "gibbs":
                return lambda _point, state: r.normal(
                    0.0, 1.0, state
                ), "(\\_ state -> R.normal 0 1 state)"
            if name == "hamiltonianMonteCarlo":
                return (
                    (
                        lambda xs: -sum(x * x for x in xs) / 2.0,
                        "(\\xs -> -sum(map (\\x -> x*x) xs)/2)",
                    )
                    if result == ["Double"]
                    else (lambda xs: [-x for x in xs], "(map negate)")
                )
            if name == "metropolisHastings":
                return lambda x: -x * x / 2.0, "(\\x -> -x*x/2)"
            if name in ("monteCarlo", "expectation"):
                return lambda x: x * x, "(\\x -> x*x)"
            if name == "fitMAPGrid":
                return lambda _distribution: 0.0, "(const 0)"
            if name in ("bootstrap", "jackknife"):
                return (
                    lambda xs: sum(xs) / len(xs),
                    "(\\xs -> Right(sum xs/fromIntegral(length xs)))",
                )
            if name == "permutationTest":
                return (
                    lambda xs, ys: sum(xs) / len(xs) - sum(ys) / len(ys),
                    "(\\xs ys -> Right(sum xs/fromIntegral(length xs)-sum ys/fromIntegral(length ys)))",
                )
        raise ValueError((name, index, spec))


def oracle_instances(entries, types):
    out = [
        'instance E Char where enc c="I"++show(ord c)\ninstance E Word64 where enc x="I"++show x\ninstance E () where enc ()="N"\nright=either(error.show) id\n'
    ]
    from generate_stochastic_bindings import TAGS

    for name, t in types.items():
        prefix = "O" + str(TAGS[name]) + "("
        out.append(
            "instance E("
            + t["alias"]
            + "."
            + name
            + ') where\n    enc value="'
            + prefix
            + '"++('
        )
        if name == "RNG":
            expr = "enc(R.serializeRNG value)"
        elif name == "AliasTable":
            expr = "ok(R.aliasSample value (R.seedRNG R.PCG32 42))"
        elif name == "Markov":
            expr = (
                "enc(right(P.transition value [1,0]),right(P.transition value [0,1]))"
            )
        elif name == "HMM":
            expr = "enc(right(P.forward value [0,1]),right(P.backward value [0,1]))"
        elif name == "Streaming":
            expr = "ok(S.streamingResult False value)"
        else:
            constructors = [
                e for e in entries if e["constructor"] and e["result"][0] == name
            ]
            parts = []
            for e in constructors:
                args = ["p" + str(i) for i in range(len(e["args"]))]
                result = (
                    '"T["++enc("'
                    + e["name"]
                    + '")++",T["++intercalate "," ['
                    + ",".join("enc " + p for p in args)
                    + ']++"]]"'
                )
                parts.append(
                    t["alias"]
                    + "."
                    + e["name"]
                    + " "
                    + " ".join(args)
                    + " -> "
                    + result
                )
            expr = "case value of {" + ";".join(parts) + "}"
        out.append(expr + ')++")"\n')
    return "".join(out)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--library", required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(Path(args.library).resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath

    entries, types, _fields = specification()
    modules = {
        m: importlib.import_module("_hmath_native." + ns)
        for m, (_alias, ns, _public) in MODULES.items()
    }
    fixtures = []
    expressions = []
    owners = []
    for entry in entries:
        if entry["name"] == "entropySeed":
            continue
        factory = Fixtures(modules)
        values = []
        hsargs = []
        for index, spec in enumerate(entry["args"]):
            value, expression = factory.argument(spec, entry["name"], index)
            values.append(value)
            hsargs.append(expression)
        name = python_name(entry, entries, types)
        function = getattr(modules[entry["module"]], name)
        expression = (
            "("
            + MODULES[entry["module"]][0]
            + "."
            + entry["name"]
            + " "
            + " ".join("(" + x + ")" for x in hsargs)
            + " :: "
            + hs_type(entry["result"], types).replace("(X.Value)", "(Integer)")
            + ")"
        )
        expression = (
            "putStrLn ("
            + ("ok" if entry["result"][0] == "Either" else "enc")
            + " "
            + expression
            + ")"
        )
        fixtures.append((function, values, entry["module"] + "." + entry["name"]))
        expressions.append(expression)
        owners.extend(factory.owned)
    random_module = modules["HMath.Random"]
    for entry in entries:
        if (
            entry["module"] != "HMath.Random"
            or not entry["constructor"]
            or entry["result"] != ["Generator"]
        ):
            continue
        generator = getattr(random_module, python_name(entry, entries, types))()
        current = random_module.seed_rng(generator, 2**64 - 1)
        owners.extend([generator, current])
        expression = "(R.seedRNG R." + entry["name"] + " 18446744073709551615)"
        for step in range(3):
            fixtures.append(
                (
                    random_module.next_word64,
                    [current],
                    "RNGcontinuation." + entry["name"] + "." + str(step),
                )
            )
            expressions.append("putStrLn(enc(R.nextWord64 " + expression + "))")
            _word, current = random_module.next_word64(current)
            owners.append(current)
            expression = "(snd(R.nextWord64 " + expression + "))"
    try:
        imports = (
            "import Data.Char(ord)\nimport Data.Word(Word64)\nimport qualified HMath.Error as E\n"
            + "".join(
                "import qualified " + m + " as " + alias + "\n"
                for m, (alias, _ns, _public) in MODULES.items()
            )
        )
        source = (
            HASKELL.replace(
                "import Data.Complex", imports + "import Data.Complex"
            ).split("main=mapM_ putStrLn")[0]
            + oracle_instances(entries, types)
            + "\nmain=sequence_\n    [ "
            + "\n    , ".join(expressions)
            + "\n    ]\n"
        )
        with tempfile.TemporaryDirectory(
            prefix="hmath-stochastic-oracle-"
        ) as directory:
            path = Path(directory) / "Main.hs"
            path.write_text(source)
            shim = Path(directory) / "libhmath_oracle_backend.so"
            subprocess.run(
                [
                    "cc",
                    "-shared",
                    "-fPIC",
                    "-std=c11",
                    "-Iinclude",
                    "cbits/backend.c",
                    "-ldl",
                    "-lm",
                    "-o",
                    str(shim),
                ],
                cwd=ROOT,
                check=True,
                capture_output=True,
            )
            result = subprocess.run(
                [
                    "runghc",
                    "-isrc",
                    "-L" + directory,
                    "-lhmath_oracle_backend",
                    str(path),
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=False,
            )
            if result.returncode:
                Path("/tmp/hmath-stochastic-oracle-failed.hs").write_text(source)
                raise RuntimeError(result.stderr[-8000:])
            expected = result.stdout.splitlines()
        actual = []
        for function, arguments, name in fixtures:
            try:
                value = function(*arguments)
            except hmath.HMathError as error:
                actual.append("E" + str(error.math_error or error))
            else:
                try:
                    actual.append(normalize(value, modules))
                finally:
                    close(value)
        failures = [
            (fixtures[i][-1], expected[i], actual[i])
            for i in range(min(len(expected), len(actual)))
            if expected[i] != actual[i]
        ]
        if failures or len(expected) != len(actual):
            raise AssertionError(f"{len(failures)} mismatches: {failures[:12]}")
        entropy = modules["HMath.Random"].entropy_seed()
        assert isinstance(entropy, int) and 0 <= entropy < 2**64
        print(
            f"Stochastic direct Haskell equivalence: {len(actual)} deterministic operations; entropySeed Word64 IO contract;152source symbols"
        )
    finally:
        for owner in owners:
            owner.close()


if __name__ == "__main__":
    main()
