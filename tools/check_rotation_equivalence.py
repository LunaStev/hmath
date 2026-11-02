# SPDX-License-Identifier: MPL-2.0
"""Compare every Quaternion/Rotation adapter with independent original Haskell calls."""

import argparse
import math
import os
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

from generate_rotation_bindings import SPECS

ROOT = Path(__file__).resolve().parent.parent


def fp(value):
    return (
        "nan"
        if math.isnan(value)
        else str(struct.unpack("!Q", struct.pack("!d", value))[0])
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", type=Path, required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(args.library.resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    from _hmath_native import matrix as m
    from _hmath_native import quaternion as q
    from _hmath_native import rotation as r

    owners = []

    def own(value):
        owners.append(value)
        return value

    qa = own(q.from_euler(0.1, 0.2, 0.3))
    qb = own(q.from_euler(-0.2, 0.4, -0.1))
    zero = own(q.quaternion(0, 0, 0, 0))
    ra, rb = own(r.so3(qa)), own(r.so3(qb))
    ta, tb = own(r.se3(ra, [1, 2, 3])), own(r.se3(rb, [-2, 0.5, 4]))
    dqa, dqb = own(r.to_dual_quaternion(ta)), own(r.to_dual_quaternion(tb))
    qm, hm = own(q.to_matrix(qa)), own(r.to_homogeneous(ta))
    wrong_matrix = own(m.from_list_checked(2, 3, [1, 0, 0, 0, 1, 0]))

    def encode(kind, value):
        if kind == "q":
            return encode("v", q.components(value))
        if kind == "r":
            with r.rotation_quaternion(value) as child:
                return encode("q", child)
        if kind == "t":
            with r.rotation_part(value) as child:
                return encode("r", child) + ";" + encode("v", r.translation_part(value))
        if kind == "dq":
            children = r.dual_parts(value)
            try:
                return ";".join(encode("q", x) for x in children)
            finally:
                for child in children:
                    child.close()
        if kind == "d":
            return fp(value)
        if kind in ("v", "triple"):
            return ",".join(fp(x) for x in value)
        if kind == "m":
            return (
                str(value.shape[0])
                + ","
                + str(value.shape[1])
                + ":"
                + encode("v", value.to_list())
            )
        if kind == "axis":
            return encode("v", value[0]) + ";" + fp(value[1])
        if kind == "twist":
            return ";".join(encode("v", x) for x in value)
        if kind == "qq":
            return ";".join(encode("q", x) for x in value)
        raise AssertionError(kind)

    def argument(item, name, kind, bad, index):
        if kind == "q":
            return (
                (zero, "zero") if bad else (qa, "qa") if index % 2 == 0 else (qb, "qb")
            )
        if kind == "r":
            return (ra, "ra") if index % 2 == 0 else (rb, "rb")
        if kind == "t":
            return (ta, "ta") if index % 2 == 0 else (tb, "tb")
        if kind == "dq":
            return (dqa, "dqa") if index % 2 == 0 else (dqb, "dqb")
        if kind == "d":
            if bad:
                return math.inf, "(1/0)"
            return 0.25, "(0.25)"
        if kind == "v":
            return ([], "[]") if bad else ([0.1, 0.2, 0.3], "[0.1,0.2,0.3]")
        if kind == "twist":
            return (
                (([], []), "([],[])")
                if bad
                else (([0.1, 0.2, 0.3], [1, 2, 3]), "([0.1,0.2,0.3],[1,2,3])")
            )
        if kind == "m":
            if bad:
                return wrong_matrix, "wrongMatrix"
            return (qm, "qm") if item["module"] == "Quaternion" else (hm, "hm")
        raise AssertionError((name, kind))

    hsenc = {
        "q": "quat",
        "r": "rotation",
        "t": "transform",
        "dq": "dualQuaternion",
        "d": "fp",
        "v": "vector",
        "m": "matrix",
        "axis": "axis",
        "triple": "triple",
        "qq": "quaternionPair",
        "twist": "twist",
    }
    lines = [
        "import qualified HMath.Quaternion as Q",
        "import HMath.Error (MathError)",
        "import qualified HMath.Rotation as R",
        "import qualified HMath.Matrix as M",
        "import Data.List (intercalate)",
        "import GHC.Float",
        'fp x=if isNaN x then "nan" else show (castDoubleToWord64 x)',
        'vector=intercalate "," . map fp',
        "quat=vector . Q.components",
        "rotation=quat . R.rotationQuaternion",
        'transform t=rotation (R.rotationPart t)++";"++vector (R.translationPart t)',
        "dualQuaternion t=quaternionPair (R.dualParts t)",
        'quaternionPair (a,b)=quat a++";"++quat b',
        'axis (a,b)=vector a++";"++fp b',
        "triple (a,b,c)=vector [a,b,c]",
        'twist (a,b)=vector a++";"++vector b',
        'matrix m=let (a,b)=M.shape m in show a++","++show b++":"++vector (M.toList m)',
        "right (Right x)=x",
        "right (Left e)=error (show e)",
        "emit :: (a -> String) -> Either MathError a -> IO ()",
        'emit e (Right x)=putStrLn ("OK:"++e x)',
        'emit _ (Left e)=putStrLn ("ERR:"++show e)',
        "qa=right (Q.fromEuler 0.1 0.2 0.3)",
        "qb=right (Q.fromEuler (-0.2) 0.4 (-0.1))",
        "zero=right (Q.quaternion 0 0 0 0)",
        "ra=right (R.so3 qa)",
        "rb=right (R.so3 qb)",
        "ta=right (R.se3 ra [1,2,3])",
        "tb=right (R.se3 rb [-2,0.5,4])",
        "dqa=right (R.toDualQuaternion ta)",
        "dqb=right (R.toDualQuaternion tb)",
        "qm=right (Q.toMatrix qa)",
        "hm=right (R.toHomogeneous ta)",
        "wrongMatrix=right (M.fromListChecked 2 3 [1,0,0,0,1,0]::Either a (M.Matrix Double))",
        "main=do",
    ]
    # Remove the unconstrained diagnostic type from the concrete Matrix fixture.
    lines[-2] = "wrongMatrix=right (M.fromListChecked 2 3 [1,0,0,0,1,0::Double])"
    cases = []
    for item in SPECS:
        for bad in [False, True]:
            values = [
                argument(item, name, kind, bad, i)
                for i, (name, kind) in enumerate(item["args"])
            ]
            expression = (
                ("Q." if item["module"] == "Quaternion" else "R.")
                + item["name"]
                + "".join(" " + x[1] for x in values)
            )
            if not item["checked"]:
                expression = "Right (" + expression + ")"
            lines.append("  emit " + hsenc[item["result"]] + " (" + expression + ")")
            cases.append((item, [x[0] for x in values], bad))
    # Exercise identity series, pi branch, gimbal lock and sign-equivalent arcs.
    extras = [
        (
            "log-so3-pi",
            "R.logSO3 (right (R.expSO3 [pi,0,0]))",
            "v",
            lambda: r.log_so3(r.exp_so3([math.pi, 0, 0])),
        ),
        (
            "log-so3-zero",
            "R.logSO3 R.identityRotation",
            "v",
            lambda: r.log_so3(r.identity_rotation()),
        ),
        (
            "pure-translation",
            "R.expSE3 ([0,0,0],[1,2,3])",
            "t",
            lambda: r.exp_se3(([0, 0, 0], [1, 2, 3])),
        ),
        (
            "identity-log",
            "R.logSE3 R.identityTransform",
            "twist",
            lambda: r.log_se3(r.identity_transform()),
        ),
        (
            "gimbal-lock",
            "Q.toEuler (right (Q.fromEuler 0.2 (pi/2) 0.3))",
            "triple",
            lambda: q.to_euler(q.from_euler(0.2, math.pi / 2, 0.3)),
        ),
        (
            "negative-quaternion",
            "Q.slerp 0.5 qa (right (Q.scale (-1) qa))",
            "q",
            lambda: q.slerp(0.5, qa, q.scale(-1, qa)),
        ),
    ]
    for _, expression, kind, _ in extras:
        lines.append("  emit " + hsenc[kind] + " (" + expression + ")")
    with tempfile.TemporaryDirectory(prefix="hmath-rotation-oracle-") as directory:
        path = Path(directory)
        source = path / "Main.hs"
        source.write_text("\n".join(lines) + "\n")
        subprocess.run(
            [
                "ghc",
                "-O0",
                "-isrc",
                "-outputdir",
                directory,
                str(source),
                "-o",
                str(path / "oracle"),
            ],
            cwd=ROOT,
            check=True,
            stdout=subprocess.DEVNULL,
        )
        expected = subprocess.check_output(
            [str(path / "oracle")], text=True
        ).splitlines()
    assert len(expected) == len(cases) + len(extras)
    for index, (item, values, bad) in enumerate(cases):
        result = None
        try:
            result = getattr(
                q if item["module"] == "Quaternion" else r, item["python"]
            )(*values)
            actual = "OK:" + encode(item["result"], result)
        except hmath.HMathError as error:
            assert error.math_error is not None
            actual = "ERR:" + str(error.math_error)
        finally:
            if isinstance(result, (list, tuple)):
                for child in result:
                    if hasattr(child, "close"):
                        child.close()
            elif hasattr(result, "close"):
                result.close()
        assert actual == expected[index], (
            item["module"],
            item["name"],
            bad,
            actual,
            expected[index],
        )
    for index, (label, _, kind, function) in enumerate(extras, len(cases)):
        result = function()
        try:
            actual = "OK:" + encode(kind, result)
            assert actual == expected[index], (label, actual, expected[index])
        finally:
            if hasattr(result, "close"):
                result.close()
    assert qa == qa.clone().decode()
    assert qa != qb
    child = r.rotation_part(ta)
    ta.close()
    assert r.rotate(child, [1, 2, 3]) == r.rotate(ra, [1, 2, 3])
    child.close()
    for owner in owners:
        owner.close()
    print(
        f"Quaternion/Rotation: {len(expected)} direct Haskell cases, complete source errors, matrix interop and ownership passed."
    )


if __name__ == "__main__":
    main()
