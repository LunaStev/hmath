# SPDX-License-Identifier: MPL-2.0
"""Compare all generic Matrix core operations against original Haskell calls."""

import argparse
import os
import subprocess
import sys
import tempfile
from fractions import Fraction
from pathlib import Path

from check_polynomial_equivalence import HASKELL, close, encode
from generate_matrix_bindings import S, snake

ROOT = Path(__file__).resolve().parent.parent


def fixtures(matrix):
    result, owners = [], []
    for dtype, hstype, precision in [
        ("integer", "Integer", 64),
        ("rational", "Rational", 64),
        ("complex64", "Complex Float", 32),
        ("complex128", "Complex Double", 64),
        ("int8", "Int8", 64),
    ]:
        a = matrix.from_list_checked(2, 2, [1, 2, 3, 4], dtype=dtype)
        b = matrix.from_list_checked(2, 2, [2, 0, 0, 2], dtype=dtype)
        owners.extend([a, b])
        ah = f"(case M.fromListChecked 2 2 [1,2,3,4] :: Either HMath.Error.MathError (M.Matrix ({hstype})) of Right x->x;Left e->error(show e))"
        bh = f"(case M.fromListChecked 2 2 [2,0,0,2] :: Either HMath.Error.MathError (M.Matrix ({hstype})) of Right x->x;Left e->error(show e))"
        for module, name, kinds, _out, mode, expression in S:
            if module != "M":
                continue
            args, hsargs = [], []
            for index, kind in enumerate(kinds):
                if kind == "m":
                    args.append(b if index and kinds == "mm" else a)
                    hsargs.append(bh if index and kinds == "mm" else ah)
                elif kind == "v":
                    values = [1, 2, 3, 4] if name.startswith("fromList") else [1, 2]
                    args.append(values)
                    hsargs.append(str(values))
                elif kind == "f":
                    args.append(Fraction(3, 2) if dtype == "rational" else 3)
                    hsargs.append("(3%2)" if dtype == "rational" else "3")
                else:
                    value = (
                        [0, 0, 1, 2][index]
                        if name.startswith("sliceMatrix")
                        else [0, 0, 1][index]
                        if name.startswith("at")
                        else [1, 4][index]
                        if name.startswith("reshape")
                        else 2
                    )
                    args.append(value)
                    hsargs.append(str(value))
            code = expression or (
                "M." + name + " " + " ".join("a" + str(i) for i in range(len(args)))
            )
            for index in reversed(range(len(args))):
                code = code.replace("a" + str(index), hsargs[index])
            if "m" not in kinds:
                resulttype = f"M.Matrix ({hstype})"
                code += " :: " + (
                    f"Maybe ({resulttype})"
                    if mode == "maybe"
                    else f"Either HMath.Error.MathError ({resulttype})"
                )
            result.append(
                (
                    snake(name),
                    args,
                    {} if "m" in kinds else {"dtype": dtype},
                    ("ok" if mode == "either" else "enc") + " (" + code + ")",
                    precision,
                )
            )
        result.extend(
            [
                ("shape", [a], {}, "enc (M.shape " + ah + ")", precision),
                ("to_list", [a], {}, "enc (M.toList " + ah + ")", precision),
                ("at", [a, -1, 0], {}, "enc (M.at " + ah + " (-1) 0)", precision),
                (
                    "at_checked",
                    [a, -1, 0],
                    {},
                    "ok (M.atChecked " + ah + " (-1) 0)",
                    precision,
                ),
                (
                    "from_list",
                    [-1, 2, []],
                    {"dtype": dtype},
                    f"enc (M.fromList (-1) 2 [] :: Maybe (M.Matrix ({hstype})))",
                    precision,
                ),
                (
                    "from_list_checked",
                    [2, 2, [1]],
                    {"dtype": dtype},
                    f"ok (M.fromListChecked 2 2 [1] :: Either HMath.Error.MathError (M.Matrix ({hstype})))",
                    precision,
                ),
            ]
        )
    return result, owners


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--library", required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(Path(args.library).resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    from _hmath_native import matrix, polynomial

    cases, owners = fixtures(matrix)
    try:
        source = HASKELL.replace(
            "import Data.Complex", "import Data.Int\nimport Data.Complex"
        ).replace("class E a where", "class E a where")
        source = source.replace(
            "pR=P.polynomial",
            'instance E Int8 where enc x="I"++show x\npR=P.polynomial',
        )
        source = source.replace(
            "EXPRESSIONS", "\n    , ".join(case[3] for case in cases)
        )
        with tempfile.TemporaryDirectory(
            prefix="hmath-matrix-value-oracle-"
        ) as directory:
            path = Path(directory) / "Main.hs"
            path.write_text(source)
            expected = subprocess.run(
                ["runghc", "-isrc", str(path)],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=True,
            ).stdout.splitlines()
        actual = []
        for name, arguments, kwargs, _expression, precision in cases:
            try:
                value = getattr(matrix, name)(*arguments, **kwargs)
            except hmath.HMathError as error:
                actual.append("E" + str(error.math_error or error))
            else:
                try:
                    actual.append(encode(value, polynomial, precision))
                finally:
                    close(value)
        errors = [
            (cases[i][0], expected[i], actual[i])
            for i in range(len(actual))
            if expected[i] != actual[i]
        ]
        if errors:
            raise AssertionError(errors[:10])
        print(
            f"Generic Matrix direct Haskell equivalence: {len(actual)} cases, Integer/Rational/ComplexFloat/ComplexDouble/Int8"
        )
    finally:
        for owner in owners:
            owner.close()


if __name__ == "__main__":
    main()
