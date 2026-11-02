# SPDX-License-Identifier: MPL-2.0
"""Original Bool/String Matrix structure; no invented arithmetic instances."""

import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from check_polynomial_equivalence import HASKELL, close
from generate_matrix_bindings import S, snake

ROOT = Path(__file__).resolve().parent.parent
STRUCTURAL = {
    "fromList",
    "fromListChecked",
    "at",
    "atChecked",
    "sliceMatrix",
    "sliceMatrixChecked",
    "reshape",
    "reshapeChecked",
    "transposeMatrix",
}


def normalize(value):
    from _hmath_native._matrix_base import Matrix

    if isinstance(value, Matrix):
        rows, cols = value.shape
        return (
            f"M{rows}:{cols}[" + ",".join(normalize(x) for x in value.to_list()) + "]"
        )
    if isinstance(value, str):
        return "L[" + ",".join("I" + str(ord(x)) for x in value) + "]"
    if isinstance(value, bool):
        return "B1" if value else "B0"
    if value is None:
        return "N"
    if isinstance(value, int):
        return "I" + str(value)
    if isinstance(value, (list, tuple)):
        return (
            ("T[" if isinstance(value, tuple) else "L[")
            + ",".join(normalize(x) for x in value)
            + "]"
        )
    raise TypeError(type(value))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--library", required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(Path(args.library).resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    from _hmath_native import matrix as m

    fixtures = []
    owners = []
    for dtype, typ, data, hsdata in [
        ("bool", "Bool", [True, False, False, True], "[True,False,False,True]"),
        (
            "string",
            "String",
            ["a\0α", "\ud800", "", "🙂"],
            '["a\\NUL\\945","\\55296","","\\128578"]',
        ),
    ]:
        matrix = m.from_list_checked(2, 2, data, dtype=dtype)
        owners.append(matrix)
        hsm = (
            "(case M.fromListChecked 2 2 "
            + hsdata
            + " :: Either HMath.Error.MathError(M.Matrix "
            + typ
            + ") of Right x->x;Left e->error(show e))"
        )
        for module, name, kinds, _result, mode, expr in S:
            if module != "M" or name not in STRUCTURAL:
                continue
            arguments = []
            hsargs = []
            for index, kind in enumerate(kinds):
                if kind == "m":
                    arguments.append(matrix)
                    hsargs.append(hsm)
                elif kind == "v":
                    arguments.append(data)
                    hsargs.append(hsdata)
                else:
                    value = (
                        [0, 0, 1, 2][index]
                        if name.startswith("slice")
                        else [0, 0, 1][index]
                        if name.startswith("at")
                        else [1, 4][index]
                        if name.startswith("reshape")
                        else 2
                    )
                    arguments.append(value)
                    hsargs.append(str(value))
            code = expr or "M." + name + " " + " ".join(
                "a" + str(i) for i in range(len(arguments))
            )
            for index in reversed(range(len(arguments))):
                code = code.replace("a" + str(index), hsargs[index])
            if "m" not in kinds:
                code += (
                    " :: "
                    + ("Either HMath.Error.MathError" if mode == "either" else "Maybe")
                    + "(M.Matrix "
                    + typ
                    + ")"
                )
            fixtures.append(
                (
                    getattr(m, snake(name)),
                    arguments,
                    {"dtype": dtype} if "m" not in kinds else {},
                    ("ok" if mode == "either" else "enc") + " (" + code + ")",
                )
            )
        fixtures.extend(
            [
                (m.to_list, [matrix], {}, "enc(M.toList " + hsm + ")"),
                (m.shape, [matrix], {}, "enc(M.shape " + hsm + ")"),
                (m.at, [matrix, -1, 0], {}, "enc(M.at " + hsm + " (-1) 0)"),
                (
                    m.at_checked,
                    [matrix, -1, 0],
                    {},
                    "ok(M.atChecked " + hsm + " (-1) 0)",
                ),
            ]
        )
        for name in [
            "zero_matrix",
            "identity",
            "diagonal",
            "add_matrix",
            "multiply_checked",
            "scale_matrix",
        ]:
            arguments = (
                [2, 2]
                if name == "zero_matrix"
                else [2]
                if name == "identity"
                else [data]
                if name == "diagonal"
                else [1, matrix]
                if name == "scale_matrix"
                else [matrix, matrix]
            )
            try:
                getattr(m, name)(
                    *arguments,
                    **(
                        {"dtype": dtype}
                        if name in ["zero_matrix", "identity", "diagonal"]
                        else {}
                    ),
                )
            except hmath.HMathError as error:
                assert error.status == 10
            else:
                raise AssertionError("invented Num instance: " + dtype + "/" + name)
    try:
        source = (
            HASKELL.replace(
                "import Data.Complex", "import Data.Char(ord)\nimport Data.Complex"
            )
            .replace(
                "pR=P.polynomial",
                'instance E Char where enc x="I"++show(ord x)\npR=P.polynomial',
            )
            .replace("EXPRESSIONS", "\n    , ".join(row[3] for row in fixtures))
        )
        with tempfile.TemporaryDirectory(
            prefix="hmath-structural-matrix-oracle-"
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
        for function, arguments, kwargs, _expr in fixtures:
            try:
                value = function(*arguments, **kwargs)
            except hmath.HMathError as error:
                actual.append("E" + str(error.math_error or error))
            else:
                try:
                    actual.append(normalize(value))
                finally:
                    close(value)
        errors = [
            (i, expected[i], actual[i])
            for i in range(len(actual))
            if expected[i] != actual[i]
        ]
        if errors:
            raise AssertionError(errors)
        print(
            f"Structural Matrix original Haskell equivalence:{len(actual)} Bool/String cases; Num-only APIs explicitly reject"
        )
    finally:
        for owner in owners:
            owner.close()


if __name__ == "__main__":
    main()
