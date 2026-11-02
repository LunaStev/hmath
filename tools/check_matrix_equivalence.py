# SPDX-License-Identifier: MPL-2.0
"""Compare all dense Matrix/LU/QR bindings with independent Haskell calls."""

import argparse
import math
import os
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

from generate_matrix_bindings import S, snake

ROOT = Path(__file__).resolve().parent.parent


def fixture(module, name, kinds, bad):
    result = []
    for index, kind in enumerate(kinds):
        if kind in "lq":
            result.append(("object", kind))
        elif kind == "m":
            matrix = "b" if index > 0 else "a"
            if bad and index > 0:
                matrix = "wrong"
            if bad and name in ("luDecompose", "determinant", "inverse"):
                matrix = "singular"
            if bad and name == "qrDecompose":
                matrix = "nonfinite"
            result.append(("object", matrix))
        elif kind == "f":
            result.append(("real", -1.0 if bad else 0.25))
        elif kind == "i":
            value = 2
            if name.startswith("reshape"):
                value = [1, 4][index] if not bad else 3
            elif name.startswith("at"):
                value = [0, 0, 1][index] if not bad else -1
            elif name.startswith("sliceMatrix"):
                value = [0, 1, 2, 1][index] if not bad else -1
            elif bad:
                value = -1
            result.append(("int", value))
        elif kind == "v":
            values = [0.0, 2.0, 1.0, 3.0] if name.startswith("fromList") else [1.0, 2.0]
            if bad and not name.startswith("fromList"):
                values = [1.0]
            result.append(("vector", values))
    return result


def hsarg(item, precision):
    kind, value = item
    if kind == "object":
        return value + str(precision)
    if kind == "real":
        return f"({value} :: {'Float' if precision == 32 else 'Double'})"
    if kind == "int":
        return f"({value})"
    return (
        "("
        + repr(value).replace(" ", "")
        + " :: ["
        + ("Float" if precision == 32 else "Double")
        + "])"
    )


def hsencode(kind, precision):
    return {
        "m": "matrix",
        "l": "lowerUpper",
        "q": "orthogonal",
        "v": "vector",
        "p": "indices",
        "i": "show",
        "f": "fp",
    }[kind] + (str(precision) if kind not in "pi" else "")


def fp(value, precision):
    if math.isnan(value):
        return "NaN"
    return str(
        struct.unpack(
            "!I" if precision == 32 else "!Q",
            struct.pack("!f" if precision == 32 else "!d", value),
        )[0]
    )


def encode(value, kind, precision, matrix):
    if kind == "m":
        return (
            str(value.shape[0])
            + ","
            + str(value.shape[1])
            + ":"
            + ",".join(fp(x, precision) for x in value.to_list())
        )
    if kind == "l":
        with matrix.lu_lower(value) as lower, matrix.lu_upper(value) as upper:
            return (
                encode(lower, "m", precision, matrix)
                + ";"
                + encode(upper, "m", precision, matrix)
                + ";"
                + encode(matrix.lu_permutation(value), "p", precision, matrix)
            )
    if kind == "q":
        with matrix.qr_q(value) as q, matrix.qr_r(value) as r:
            return (
                encode(q, "m", precision, matrix)
                + ";"
                + encode(r, "m", precision, matrix)
                + ";"
                + encode(matrix.qr_permutation(value), "p", precision, matrix)
                + ";"
                + str(matrix.qr_rank(value))
            )
    if kind == "v":
        return ",".join(fp(x, precision) for x in value)
    if kind == "p":
        return ",".join(str(x) for x in value)
    return str(value) if kind == "i" else fp(value, precision)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", type=Path, required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(args.library.resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    from _hmath_native import matrix

    lines = [
        "{-# LANGUAGE ScopedTypeVariables #-}",
        "import Control.Exception",
        "import Data.List (intercalate)",
        "import GHC.Float",
        "import HMath.Error",
        "import qualified HMath.Matrix as M",
        "import qualified HMath.Matrix.LU as L",
        "import qualified HMath.Matrix.QR as Q",
        "emit :: (a -> String) -> Either MathError a -> IO ()",
        'emit encode result = (do let text = either (("ERR:" ++) . show) (("OK:" ++) . encode) result',
        "                         evaluate (length text)",
        '                         putStrLn text) `catch` (\\(_ :: SomeException) -> putStrLn "EXCEPTION")',
        'emitMaybe encode result = case result of Nothing -> putStrLn "NONE"; Just value -> emit encode (Right value)',
        'indices = intercalate "," . map show',
    ]
    for precision, real in [(32, "Float"), (64, "Double")]:
        p = str(precision)
        for name, rows, columns, values in [
            ("a", 2, 2, "[0,2,1,3]"),
            ("b", 2, 2, "[2,1,0,2]"),
            ("wrong", 1, 4, "[1,2,3,4]"),
            ("singular", 2, 2, "[1,2,2,4]"),
            ("nonfinite", 2, 2, "[0/0,2,1,3]"),
        ]:
            lines.append(f"{name}{p} :: M.Matrix {real}")
            lines.append(
                f"Right {name}{p} = M.fromListChecked {rows} {columns} {values}"
            )
        lines.extend(
            [
                f"Right l{p} = L.luDecompose a{p}",
                f"Right q{p} = Q.qrDecompose a{p}",
                f'fp{p} x = if isNaN x then "NaN" else show (cast{"FloatToWord32" if precision == 32 else "DoubleToWord64"} x)',
                f'vector{p} = intercalate "," . map fp{p}',
                f'matrix{p} value = let (r,c)=M.shape value in show r ++ "," ++ show c ++ ":" ++ vector{p} (M.toList value)',
                f'lowerUpper{p} f = matrix{p} (L.luLower f) ++ ";" ++ matrix{p} (L.luUpper f) ++ ";" ++ indices (L.luPermutation f)',
                f'orthogonal{p} f = matrix{p} (Q.qrQ f) ++ ";" ++ matrix{p} (Q.qrR f) ++ ";" ++ indices (Q.qrPermutation f) ++ ";" ++ show (Q.qrRank f)',
            ]
        )
    lines.append("main = do")
    cases = []
    for precision in [32, 64]:
        for mod, name, kinds, out, mode, expression in S:
            for bad in [False, True]:
                items = fixture(mod, name, kinds, bad)
                arguments = [hsarg(item, precision) for item in items]
                if expression:
                    call = expression
                    for index in reversed(range(len(arguments))):
                        call = call.replace("a" + str(index), arguments[index])
                else:
                    call = mod + "." + name + " " + " ".join(arguments)
                prefix = "emitMaybe" if mode == "maybe" else "emit"
                if mode == "pure":
                    call = "Right (" + call + ")"
                lines.append(
                    "    " + prefix + " " + hsencode(out, precision) + " (" + call + ")"
                )
                cases.append((precision, mod, name, kinds, out, mode, items))
    with tempfile.TemporaryDirectory(prefix="hmath-matrix-oracle-") as directory:
        path = Path(directory)
        (path / "Main.hs").write_text("\n".join(lines) + "\n")
        subprocess.run(
            [
                "ghc",
                "-O2",
                "-i" + str(ROOT / "src"),
                "-outputdir",
                directory,
                str(path / "Main.hs"),
                "-o",
                str(path / "oracle"),
            ],
            check=True,
            stdout=subprocess.DEVNULL,
        )
        expected = subprocess.check_output(
            [str(path / "oracle")], text=True
        ).splitlines()
    assert len(expected) == len(cases)
    fixtures_by_precision = {}
    owned = []
    try:
        for precision in [32, 64]:
            dtype = "float32" if precision == 32 else "float64"
            objects = {}
            for name, rows, columns, values in [
                ("a", 2, 2, [0, 2, 1, 3]),
                ("b", 2, 2, [2, 1, 0, 2]),
                ("wrong", 1, 4, [1, 2, 3, 4]),
                ("singular", 2, 2, [1, 2, 2, 4]),
                ("nonfinite", 2, 2, [float("nan"), 2, 1, 3]),
            ]:
                objects[name] = matrix.from_list_checked(
                    rows, columns, values, dtype=dtype
                )
                owned.append(objects[name])
            objects["l"], objects["q"] = (
                matrix.lu_decompose(objects["a"]),
                matrix.qr_decompose(objects["a"]),
            )
            owned.extend([objects["l"], objects["q"]])
            fixtures_by_precision[precision] = objects
        for case, oracle in zip(cases, expected):
            precision, mod, name, kinds, out, mode, items = case
            arguments = [
                fixtures_by_precision[precision][value] if kind == "object" else value
                for kind, value in items
            ]
            kwargs = (
                {}
                if any(kind in "mlq" for kind in kinds)
                else {"dtype": "float32" if precision == 32 else "float64"}
            )
            value = None
            try:
                value = getattr(matrix, snake(name))(*arguments, **kwargs)
                actual = (
                    "NONE"
                    if value is None
                    else "OK:" + encode(value, out, precision, matrix)
                )
            except hmath.HMathError as error:
                actual = "EXCEPTION" if error.status == 6 else "ERR:" + str(error)
            finally:
                if value is not None and out in "mlq":
                    value.close()
            assert actual == oracle, (precision, mod, name, arguments, actual, oracle)
    finally:
        for value in owned:
            value.close()
    hmath.shutdown()
    print(
        f"{len(cases)} direct Haskell ↔ C/Python Matrix/LU/QR cases passed; 52 source functions covered including shape/toList helpers."
    )


if __name__ == "__main__":
    main()
