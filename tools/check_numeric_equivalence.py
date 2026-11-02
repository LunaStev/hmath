# SPDX-License-Identifier: MPL-2.0
"""Compare every numeric binding with independent direct Haskell evaluation.

The oracle imports the original public modules, never the generated FFI. Float
and Double results are compared by IEEE bits (NaNs by class). Errors compare
the full MathError constructor/payload. Pure exceptions compare failure kind.
"""

import argparse
import importlib
import json
import math
import os
import struct
import subprocess
import sys
import tempfile
from fractions import Fraction
from pathlib import Path

from generate_numeric_bindings import namespace
from numeric_specializations import BOUNDED, binding_variants

ROOT = Path(__file__).resolve().parent.parent


def variant_fixtures(entry, variant):
    dtype = variant["dtype"]
    if not entry.get("specializations") or dtype in ("float32", "float64"):
        yield from fixtures(entry)
        return
    if dtype in BOUNDED:
        _, _, bits, signed, _ = BOUNDED[dtype]
        bits = bits or struct.calcsize("P") * 8
        low = -(1 << (bits - 1)) if signed else 0
        high = (1 << (bits - 1)) - 1 if signed else (1 << bits) - 1
    else:
        low, high = -(10**100 + 123), 10**100 + 123
    for case in range(4):
        arguments = []
        for index, argument in enumerate(variant["args"]):
            kind = argument["type"]
            if kind == "q":
                value = [
                    Fraction(10**100 + index + 1, 3 + 2 * index),
                    Fraction(-1, 7),
                    Fraction(0),
                    Fraction(1, 3 + 2 * index),
                ][case]
            elif kind == "qs":
                value = [
                    [Fraction(10**100 + 1, 3), Fraction(-1, 7)],
                    [],
                    [Fraction(0)],
                    [Fraction(1, 3), Fraction(1, 7)],
                ][case]
            elif kind == "c":
                value = [
                    complex(0.25 + index, 0.5),
                    complex(-1, 2),
                    complex(-0.0, -0.0),
                    complex(2, -3),
                ][case]
            elif kind == "cs":
                value = [
                    [complex(1, 2), complex(-3, 0.25)],
                    [],
                    [complex(-0.0, -0.0)],
                    [complex(2, -3)],
                ][case]
            elif kind.endswith("s"):
                value = [[high, 1, low], [], [0], [low, low]][case]
            else:
                value = [
                    high if index == 0 else 1,
                    low if index == 0 else (1 if low == 0 else -1),
                    0,
                    low if index == 0 else high,
                ][case]
            arguments.append(value)
        yield arguments


def result_type(result, real):
    if result in BOUNDED:
        return BOUNDED[result][1]
    if result.endswith("d") and result[:-1] in BOUNDED:
        return "[" + BOUNDED[result[:-1]][1] + "]"
    return {
        "f": real,
        "fs": f"[{real}]",
        "fd": f"[{real}]",
        "z": "Integer",
        "i": "Int",
        "b": "Bool",
        "q": "Rational",
        "zd": "[Integer]",
        "id": "[Int]",
        "qd": "[Rational]",
        "cd": f"[Complex {real}]",
        "zz": "(Integer,Integer)",
        "zzz": "(Integer,Integer,Integer)",
        "zzzz": "(Integer,Integer,Integer,Integer)",
        "ff": f"({real},{real})",
        "c": f"(Complex {real})",
    }[result]


def fixtures(entry):
    # Domain-valid nontrivial inputs complement the generic boundary cases.
    # These are test data, never replacement formulas or implementation code.
    name, module = entry["name"], entry["module"]
    valid = None
    if module in ("HMath.Statistics.Advanced", "HMath.Signal", "HMath.Fourier"):
        valid = [
            {"f": 0.1, "i": 1, "b": False, "fs": [0.1, 0.2, 0.3, 0.4]}[a["type"]]
            for a in entry["args"]
        ]
    if module == "HMath.Special":
        valid = [
            {
                "f": 0.5,
                "i": 0,
                "b": True,
                "fs": [0.5],
                "is": [0] * 9,
                "c": complex(0.5, 0.1),
            }[a["type"]]
            for a in entry["args"]
        ]
        overrides = {
            "hypergeometric": [[0.5], [1.5], 0.5],
            "complex1F1": [complex(0.5), complex(1.5), complex(0.5, 0.1)],
            "hankel": [1, 0, 0.5],
            "hurwitzZeta": [2.0, 0.5],
            "debye": [1, 0.5],
            "boseEinstein": [0.5, -0.5],
        }
        valid = overrides.get(name, valid)
    valid = {
        ("HMath.Combinatorics", "inclusionExclusion"): [2, [1, 2, 3]],
        ("HMath.Combinatorics", "rankPermutation"): [[2, 0, 1]],
        ("HMath.NumberTheory", "discreteLog"): [1000, 2, 3, 5],
        ("HMath.NumberTheory", "multiplicativeOrder"): [1000, 2, 5],
        ("HMath.NumberTheory", "pellFundamental"): [1000, 2],
        ("HMath.Probability", "multinomialPMF"): [[0.25, 0.75], [1, 3]],
        ("HMath.Probability", "dirichletDensity"): [[1.0, 2.0], [0.25, 0.75]],
        ("HMath.Probability", "bayes"): [[0.25, 0.75], [0.5, 0.25]],
        ("HMath.Statistics.Advanced", "normalSampleSize"): [0.05, 0.8, 0.5],
        ("HMath.Signal", "savitzkyGolay"): [5, 2, 1, 1.0, [1, 2, 4, 8, 16, 32, 64]],
        ("HMath.Signal", "downsample"): [2, 0, [1, 2, 3, 4]],
    }.get((module, name), valid)
    if valid is not None:
        yield valid
    for case in range(4 if entry["args"] else 1):
        arguments = []
        for index, arg in enumerate(entry["args"]):
            kind = arg["type"]
            value = [0.25 + index * 0.5, -1.0, 0.0, float("nan")][case]
            if kind == "f":
                arguments.append(value)
            elif kind in ("z", "i"):
                arguments.append([5, -1, 0, 2][case])
            elif kind == "b":
                arguments.append([True, False, False, True][case])
            elif kind == "q":
                arguments.append(
                    [Fraction(5, 3), Fraction(-1, 2), Fraction(0), Fraction(2, 7)][case]
                )
            elif kind in ("zs", "is"):
                arguments.append([[1, 3, 2], [], [-1], [0, 2]][case])
            elif kind in ("p", "c"):
                pair = (value, value / 2)
                arguments.append(complex(*pair) if kind == "c" else pair)
            elif kind == "fs":
                arguments.append(
                    [[1.0, 3.0, 2.0], [], [-0.0], [1.0, float("nan")]][case]
                )
        yield arguments


def hsreal(value):
    return "(0/0)" if math.isnan(value) else "(" + repr(value) + ")"


def hsarg(kind, value, real):
    if kind in BOUNDED:
        return f"({value} :: {BOUNDED[kind][1]})"
    if kind.endswith("s") and kind[:-1] in BOUNDED:
        return f"({value!r} :: [{BOUNDED[kind[:-1]][1]}])"
    if kind in ("i", "z"):
        return f"({value})"
    if kind == "f":
        return f"({hsreal(value)} :: {real})"
    if kind == "b":
        return "True" if value else "False"
    if kind == "q":
        return f"({value.numerator} % {value.denominator})"
    if kind == "qs":
        return "([" + ",".join(hsarg("q", v, real) for v in value) + "] :: [Rational])"
    if kind == "cs":
        return (
            "(["
            + ",".join(hsarg("c", v, real) for v in value)
            + f"] :: [Complex {real}])"
        )
    if kind in ("zs", "is"):
        return (
            "(["
            + ",".join(str(v) for v in value)
            + "] :: ["
            + ("Integer" if kind == "zs" else "Int")
            + "])"
        )
    if kind == "p":
        return f"({hsarg('f', value[0], real)}, {hsarg('f', value[1], real)})"
    if kind == "c":
        return f"({hsarg('f', value.real, real)} :+ {hsarg('f', value.imag, real)})"
    if kind == "fs":
        return "([" + ",".join(map(hsreal, value)) + f"] :: [{real}])"
    raise ValueError(kind)


def hsencode(result, precision):
    encode = "fp32" if precision == "float32" else "fp64"
    if result in BOUNDED:
        return "show"
    if result.endswith("d") and result[:-1] in BOUNDED:
        return '(intercalate "," . map show)'
    if result == "cd":
        return f'(intercalate ";" . map (\\x -> {encode} (realPart x) ++ "," ++ {encode} (imagPart x)))'
    if result == "f":
        return encode
    if result in ("z", "i", "b"):
        return "show"
    if result in ("fs", "fd"):
        return f'(intercalate "," . map {encode})'
    if result in ("zd", "id"):
        return '(intercalate "," . map show)'
    if result == "qd":
        return '(intercalate "," . map (\\x -> show (numerator x) ++ "/" ++ show (denominator x)))'
    sf = f'(\\x -> {encode} (HMath.Special.sfValue x) ++ "," ++ {encode} (HMath.Special.sfError x))'
    if result == "sf":
        return sf
    if result in ("sf2", "sf4"):
        vs = ["a", "b"] if result == "sf2" else ["a", "b", "c", "d"]
        return (
            "(\\("
            + ",".join(vs)
            + ') -> intercalate "," ['
            + ",".join(sf + " " + v for v in vs)
            + "])"
        )
    if result == "fsf":
        return f'(\\(a,b) -> {encode} a ++ "," ++ {sf} b)'
    if result == "q":
        return '(\\x -> show (numerator x) ++ "," ++ show (denominator x))'
    if result == "c":
        return f'(\\x -> {encode} (realPart x) ++ "," ++ {encode} (imagPart x))'
    encoders = ["show" if t == "z" else encode for t in result]
    variables = ["a", "b", "c", "d"][: len(encoders)]
    return (
        "(\\("
        + ",".join(variables)
        + ') -> intercalate "," ['
        + ",".join(f"{enc} {var}" for enc, var in zip(encoders, variables))
        + "])"
    )


def pyencode(result, value, precision):
    def fp(number):
        if math.isnan(number):
            return "NaN"
        return str(
            struct.unpack(
                "!I" if precision == "float32" else "!Q",
                struct.pack("!f" if precision == "float32" else "!d", number),
            )[0]
        )

    if result in BOUNDED:
        return str(value)
    if result.endswith("d") and result[:-1] in BOUNDED:
        return ",".join(map(str, value))
    if result == "cd":
        return ";".join(fp(v.real) + "," + fp(v.imag) for v in value)
    if result == "f":
        return fp(value)
    if result in ("z", "i", "b"):
        return str(value)
    if result in ("fs", "fd", "sf"):
        return ",".join(map(fp, value))
    if result in ("zd", "id"):
        return ",".join(map(str, value))
    if result == "qd":
        return ",".join(f"{v.numerator}/{v.denominator}" for v in value)
    if result in ("sf2", "sf4"):
        return ",".join(fp(component) for sf in value for component in sf)
    if result == "fsf":
        return fp(value[0]) + "," + ",".join(map(fp, value[1]))
    if result == "q":
        return f"{value.numerator},{value.denominator}"
    if result == "c":
        return f"{fp(value.real)},{fp(value.imag)}"
    return ",".join(
        str(item) if kind == "z" else fp(item) for kind, item in zip(result, value)
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", type=Path, required=True)
    parser.add_argument(
        "--oracle-builddir",
        type=Path,
        help="Optional GHC object cache for repeated local checks",
    )
    parser.add_argument(
        "--optimization",
        choices=("0", "1", "2"),
        default="2",
        help="Match the source algorithms to the native library's GHC optimization level",
    )
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(args.library.resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath

    entries = json.loads((ROOT / "bindings/schema/numeric.json").read_text())[
        "functions"
    ]
    lines = [
        # The oracle's source algorithms use the library optimization level;
        # its large fixture driver does not need optimization.
        "{-# OPTIONS_GHC -O0 #-}",
        "{-# LANGUAGE ScopedTypeVariables #-}",
        "import Control.Exception",
        "import Data.List (intercalate)",
        "import Data.Complex",
        "import Data.Ratio",
        "import Data.Int",
        "import Data.Word",
        "import GHC.Float",
        "import HMath.Error",
        "import qualified HMath.Optimization.FirstOrder as O",
    ]
    lines += [f"import qualified {m}" for m in sorted({e["module"] for e in entries})]
    lines += [
        'fp32 x = if isNaN x then "NaN" else show (castFloatToWord32 x)',
        'fp64 x = if isNaN x then "NaN" else show (castDoubleToWord64 x)',
        "{-# NOINLINE opaque #-}",
        "opaque :: a -> a",
        "opaque x = x",
        'emit encode value = (do let text = either (("ERR:" ++) . show) (("OK:" ++) . encode) value',
        "                        evaluate (length text)",
        '                        putStrLn text) `catch` (\\(_ :: SomeException) -> putStrLn "EXCEPTION")',
        "steps method k state point | k > 20 = Right []",
        "steps method k state point = do",
        "    (next, nextState) <- O.optimizerStep method 0.01 state point [fromIntegral (k `mod` 3) - 1, fromIntegral k * 0.25, -0.5]",
        "    rest <- steps method (k+1) nextState next",
        "    Right (next ++ rest)",
        "main = do",
        '    if castFloatToWord32 (opaque ((-0.0) :: Float)) /= 2147483648 then error "oracle lost Float input sign bit" else pure ()',
        '    if castDoubleToWord64 (opaque ((-0.0) :: Double)) /= 9223372036854775808 then error "oracle lost Double input sign bit" else pure ()',
    ]
    cases = []
    for entry in entries:
        for variant in binding_variants(entry):
            bits = variant["precision"]
            precision = f"float{bits}" if bits else None
            for arguments in variant_fixtures(entry, variant):
                real = "Float" if precision == "float32" else "Double"
                call = (
                    entry["module"]
                    + "."
                    + entry["name"]
                    + " "
                    + " ".join(
                        "(opaque " + hsarg(arg["type"], value, real) + ")"
                        for arg, value in zip(variant["args"], arguments)
                    )
                )
                if not entry["args"]:
                    call = f"({call} :: {real})"
                if not entry["checked"]:
                    call = (
                        f"(Right ({call}) :: Either MathError "
                        + result_type(variant["result"], real)
                        + ")"
                    )
                lines.append(
                    f"    emit {hsencode(variant['result'], precision)} ({call})"
                )
                cases.append((entry, variant, arguments))
    lines.append(
        '    mapM_ (\\method -> emit (intercalate "," . map fp64) (O.initializeOptimizer 3 >>= \\state -> steps method (1 :: Int) state [1,-2,3])) [minBound..maxBound]'
    )
    with tempfile.TemporaryDirectory(prefix="hmath-numeric-oracle-") as directory:
        path = Path(directory)
        object_path = args.oracle_builddir or path
        object_path.mkdir(parents=True, exist_ok=True)
        (path / "Main.hs").write_text("\n".join(lines) + "\n")
        subprocess.run(
            [
                "ghc",
                "-O" + args.optimization,
                "-i" + str(ROOT / "src"),
                "-outputdir",
                str(object_path),
                str(path / "Main.hs"),
                str(ROOT / "cbits/backend.c"),
                "-I" + str(ROOT / "include"),
                "-optc-std=c11",
                *(["-ldl"] if sys.platform.startswith("linux") else []),
                "-o",
                str(path / "oracle"),
            ],
            check=True,
            stdout=subprocess.DEVNULL,
        )
        expected = subprocess.check_output(
            [str(path / "oracle")], text=True
        ).splitlines()
    assert len(expected) == len(cases) + 12, (len(expected), len(cases))
    for (entry, variant, arguments), oracle in zip(cases, expected):
        precision = f"float{variant['precision']}" if variant["precision"] else None
        function = getattr(
            importlib.import_module("_hmath_native." + namespace(entry)),
            entry["python"],
        )
        try:
            if entry.get("specializations") and variant["legacy"]:
                from _hmath_native._numeric import _call
                from generate_numeric_bindings import prefix

                value = _call(
                    prefix(entry),
                    [a["type"] for a in variant["args"]],
                    variant["result"],
                    arguments,
                    precision,
                    entry.get("result_extra", 0),
                    symbol_suffix=variant["suffix"],
                )
            else:
                dtype = variant["dtype"]
                value = function(*arguments, **({"dtype": dtype} if dtype else {}))
            actual = "OK:" + pyencode(variant["result"], value, precision)
        except hmath.HMathError as error:
            actual = "EXCEPTION" if error.status == 6 else "ERR:" + str(error)
        assert actual == oracle, (
            entry["module"],
            entry["name"],
            variant["dtype"],
            arguments,
            actual,
            oracle,
        )
    from _hmath_native import algorithms
    from hmath import optimization

    for precision in ("float32", "float64"):
        # partialSort is an identity for a single element: this verifies that
        # the common Python→C→Haskell→C→Python array transport retains -0 bits.
        value = algorithms.partial_sort(1, [-0.0], dtype=precision)
        expected_zero = (
            "2147483648" if precision == "float32" else "9223372036854775808"
        )
        assert pyencode("fs", value, precision) == expected_zero

    for method, oracle in zip(optimization.GradientMethod, expected[len(cases) :]):
        state = optimization.initialize_optimizer(3)
        point, values = [1, -2, 3], []
        try:
            for step in range(1, 21):
                point, next_state = optimization.optimizer_step(
                    method, 0.01, state, point, [step % 3 - 1, step * 0.25, -0.5]
                )
                state.close()
                state = next_state
                values.extend(point)
        finally:
            state.close()
        actual = "OK:" + pyencode("fs", values, "float64")
        assert actual == oracle, (method, actual, oracle)
    print(
        f"{len(cases)} direct Haskell ↔ C/Python equivalence cases passed ({len(entries)} functions), plus 20 steps of all 12 optimizers."
    )


if __name__ == "__main__":
    main()
