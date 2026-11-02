# SPDX-License-Identifier: MPL-2.0
"""Actual Haskell instances for generic numerical owner specializations."""

import argparse
import importlib
import json
import os
import subprocess
import sys
import tempfile
from fractions import Fraction
from pathlib import Path

from check_polynomial_equivalence import HASKELL, bits, close

ROOT = Path(__file__).resolve().parent.parent
REQUIRES = {
    "clamp": {"Ord"},
    "minimumScalar": {"Ord"},
    "maximumScalar": {"Ord"},
    "lerp": {"Fractional"},
    "mean": {"Fractional"},
    "variance": {"Fractional"},
    "standardDeviation": {"Floating"},
    "magnitude": {"Floating"},
    "normalize": {"Floating", "Eq"},
    "median": {"Fractional", "Ord"},
    "positiveModulo": {"Integral"},
    **{
        name: {"Integral", "Bounded"}
        for name in [
            "saturatingAdd",
            "saturatingSubtract",
            "saturatingMultiply",
            "checkedAdd",
            "checkedSubtract",
            "checkedMultiply",
        ]
    },
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--library", required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(Path(args.library).resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    from _hmath_native import _value as v
    from _hmath_native import algebra_api, geometry
    from _hmath_native import autodiff as ad
    from _hmath_native import numeric_types as n

    entries = [
        entry
        for entry in json.loads((ROOT / "bindings/schema/numeric.json").read_text())[
            "functions"
        ]
        if entry.get("specializations")
    ]
    assert len(entries) == 31
    modules = {
        name: importlib.import_module("_hmath_native." + name.lower())
        for name in ["Basic", "Scalar", "Linear", "Statistics"]
    }
    owners = []
    domains = []
    tests = []
    expressions = []
    denied = []
    covered = set()

    def own(value):
        owners.append(value)
        return value

    def primitive(
        dtype,
        hstype,
        kind,
        fractional=False,
        floating=False,
        ordered=True,
        integral=False,
        bounded=False,
    ):
        capabilities = (
            {"Num", "Eq"}
            | ({"Fractional"} if fractional else set())
            | ({"Floating"} if floating else set())
            | ({"Ord"} if ordered else set())
            | ({"Integral"} if integral else set())
            | ({"Bounded"} if bounded else set())
        )

        def factory(index):
            raw = (
                Fraction(index + 2, 3)
                if dtype == "rational"
                else complex(index + 2, index / 4)
                if kind == "complex"
                else float(index + 2)
                if kind == "float"
                else index + 2
            )
            text = (
                f"(({index + 2}%3)::Rational)"
                if dtype == "rational"
                else f"({index + 2}:+({index}/4)::{hstype})"
                if kind == "complex"
                else f"({index + 2}::{hstype})"
            )
            return own(n.number(raw, dtype)), text

        domain = {
            "name": dtype,
            "type": hstype,
            "factory": factory,
            "caps": capabilities,
            "precision": 32 if dtype in ("float32", "complex64") else 64,
        }
        domains.append(domain)
        return domain

    bases = {}
    for arguments in [
        ("integer", "Integer", "int", False, False, True, True, False),
        ("rational", "Rational", "rational", True, False, True, False, False),
        ("float32", "Float", "float", True, True, True, False, False),
        ("float64", "Double", "float", True, True, True, False, False),
        ("complex64", "Complex Float", "complex", True, True, False, False, False),
        ("complex128", "Complex Double", "complex", True, True, False, False, False),
        ("int8", "Int8", "int", False, False, True, True, True),
        ("uint64", "Word64", "int", False, False, True, True, True),
    ]:
        bases[arguments[0]] = primitive(*arguments)

    def dual_domain(base, family):
        constructor = "N.Dual" if family == "numeric" else "AD.Dual"

        def factory(index):
            a, hs_a = base["factory"](index)
            b, hs_b = base["factory"](0)
            value = (
                n.dual(a, b)
                if family == "numeric"
                else ad.Dual(a, b)
                if isinstance(a, ad.Dual)
                else ad.Dual(a, b, dtype=a)
            )
            return own(value), "(" + constructor + "(" + hs_a + ")(" + hs_b + "))"

        caps = (base["caps"] & {"Fractional", "Floating", "Eq"}) | {"Num"}
        if family == "ad" and "Ord" in base["caps"]:
            caps.add("Ord")
        domain = {
            "name": family + ".Dual(" + base["name"] + ")",
            "type": constructor + "(" + base["type"] + ")",
            "factory": factory,
            "caps": caps,
            "precision": base["precision"],
        }
        domains.append(domain)
        return domain

    numeric_duals = {
        name: dual_domain(bases[name], "numeric")
        for name in ["integer", "rational", "float32", "float64"]
    }
    dual_domain(numeric_duals["float64"], "numeric")
    quaternions = {}
    for name in ["float32", "float64"]:
        base = bases[name]

        def factory(index, base=base):
            values = [base["factory"](index + j) for j in range(4)]
            return own(
                n.quaternion(*(x for x, _ in values))
            ), "(N.Quaternion " + " ".join("(" + h + ")" for _, h in values) + ")"

        domain = {
            "name": "Quaternion(" + name + ")",
            "type": "N.Quaternion(" + base["type"] + ")",
            "factory": factory,
            "caps": {"Num", "Eq"},
            "precision": base["precision"],
        }
        domains.append(domain)
        quaternions[name] = domain
    dual_domain(quaternions["float64"], "numeric")
    ad_duals = {
        name: dual_domain(bases[name], "ad")
        for name in ["integer", "rational", "float32", "float64"]
    }
    dual_domain(ad_duals["float64"], "ad")
    dual_domain(numeric_duals["float64"], "ad")
    dual_domain(quaternions["float64"], "ad")
    dual_domain(bases["complex128"], "ad")

    def expression(index):
        x = own(ad.variable(index % 2))
        constant = own(ad.constant(index + 2.0))
        return own(x + constant), "(AD.variable " + str(
            index % 2
        ) + "+AD.constant " + str(index + 2) + ")"

    domains.append(
        {
            "name": "AD.Expr",
            "type": "AD.Expr",
            "factory": expression,
            "caps": {"Num", "Fractional", "Floating"},
            "precision": 64,
        }
    )

    def encode(value, precision=64):
        if isinstance(value, ad.Expr):
            observed = []
            for point in [[1.25, 2.5], [-1.0, 3.0]]:
                try:
                    observed.append(encode(ad.value_and_gradient(value, point), 64))
                except hmath.HMathError as error:
                    if error.math_error is None:
                        raise
                    observed.append("E" + str(error.math_error))
            return "EXPR(L[" + ",".join(observed) + "])"
        if isinstance(value, ad.Dual):
            parts = [value.primal, value.tangent]
            try:
                return "AD(" + ",".join(encode(part, precision) for part in parts) + ")"
            finally:
                close(parts)
        if isinstance(value, v.Value):
            kind, dtype, _ = value.info
            if kind == 1 and dtype == 20:
                parts = [n.primal(value, boxed=True), n.tangent(value, boxed=True)]
                try:
                    return (
                        "ND("
                        + ",".join(encode(part, precision) for part in parts)
                        + ")"
                    )
                finally:
                    close(parts)
            if kind == 1 and dtype == 21:
                parts = [
                    n.quaternion_component(value, index, boxed=True)
                    for index in range(4)
                ]
                try:
                    return (
                        "Q(" + ",".join(encode(part, precision) for part in parts) + ")"
                    )
                finally:
                    close(parts)
            if kind == 1:
                precision = 32 if dtype in (1, 5) else 64
                raw = v.decode(value.clone())
                return encode(raw, precision)
            if kind == 400:
                return "EXACT(" + encode(algebra_api.get_exact(value), precision) + ")"
            if kind == 169:
                return "POINT(" + encode(value.coordinates, 64) + ")"
        if value is None:
            return "N"
        if isinstance(value, bool):
            return "B1" if value else "B0"
        if isinstance(value, int):
            return "I" + str(value)
        if isinstance(value, Fraction):
            return f"R{value.numerator}/{value.denominator}"
        if isinstance(value, float):
            return f"F{precision}:" + str(bits(value, precision))
        if isinstance(value, complex):
            return (
                f"C{precision}:"
                + str(bits(value.real, precision))
                + ":"
                + str(bits(value.imag, precision))
            )
        if isinstance(value, str):
            return "L[" + ",".join("I" + str(ord(x)) for x in value) + "]"
        if isinstance(value, (list, tuple)):
            return (
                ("T[" if isinstance(value, tuple) else "L[")
                + ",".join(encode(x, precision) for x in value)
                + "]"
            )
        raise TypeError(type(value))

    def add(entry, domain, values, hsargs, kwargs=None, name=None):
        function = getattr(modules[entry["module"].split(".")[-1]], entry["python"])
        checked = entry.get("checked", False)
        expression = (
            entry["module"].split(".")[-1]
            + "."
            + entry["name"]
            + " "
            + " ".join("(" + h + ")" for h in hsargs)
        )
        expressions.append(("ok" if checked else "enc") + "(" + expression + ")")
        tests.append(
            (
                function,
                values,
                kwargs or {},
                domain["precision"],
                name or domain["name"] + ":" + entry["name"],
            )
        )
        covered.add(entry["module"] + "." + entry["name"])

    for domain in domains:
        samples = [domain["factory"](index) for index in range(3)]
        for entry in entries:
            required = REQUIRES.get(entry["name"], {"Num"})
            if not required <= domain["caps"]:
                denied.append((entry, domain, samples))
                continue
            values = []
            hsargs = []
            for index, argument in enumerate(entry["args"]):
                if argument["type"] == "fs":
                    values.append([x for x, _ in samples])
                    hsargs.append("[" + ",".join(h for _, h in samples) + "]")
                else:
                    x, h = samples[index % 3]
                    values.append(x)
                    hsargs.append(h)
            add(entry, domain, values, hsargs)
        # Explicit prototypes on empties preserve the actual additive identity,
        # nested zero tower and source empty-list exceptions.
        for entry in entries:
            name = entry["name"]
            if name not in [
                "dot",
                "dotChecked",
                "add",
                "addChecked",
                "subtractChecked",
                "magnitude",
                "normalize",
                "cumulativeSum",
                "prefixSum",
                "cumulativeProduct",
                "mean",
                "variance",
                "standardDeviation",
                "median",
            ]:
                continue
            if not all(arg["type"] == "fs" for arg in entry["args"]):
                continue
            if not REQUIRES.get(name, {"Num"}) <= domain["caps"]:
                continue
            if entry["module"] == "HMath.Scalar" and name == "add":
                continue
            add(
                entry,
                domain,
                [[] for _ in entry["args"]],
                ["([]::[" + domain["type"] + "])" for _ in entry["args"]],
                {"dtype": samples[0][0]},
                domain["name"] + ":empty:" + name,
            )
    for name, low, high, value, hs_low, hs_high, hs_value in [
        ("Bool", False, True, True, "False", "True", "True"),
        ("String", "α", "ω", "β", '"α"', '"ω"', '"β"'),
        (
            "Tuple",
            (1, "a"),
            (4, "z"),
            (2, "b"),
            '(1::Integer,"a")',
            '(4::Integer,"z")',
            '(2::Integer,"b")',
        ),
        (
            "NestedList",
            [[1]],
            [[4]],
            [[], [3]],
            "[[1::Integer]]",
            "[[4::Integer]]",
            "[[],[3::Integer]]",
        ),
        (
            "Exact",
            own(algebra_api.Exact(Fraction(1, 3))),
            own(algebra_api.Exact(Fraction(4, 3))),
            own(algebra_api.Exact(Fraction(2, 3))),
            "API.Exact(1%3)",
            "API.Exact(4%3)",
            "API.Exact(2%3)",
        ),
        (
            "Point2",
            own(geometry.point2(1.0, 2.0)),
            own(geometry.point2(4.0, 5.0)),
            own(geometry.point2(2.0, 3.0)),
            "G.P2 1 2",
            "G.P2 4 5",
            "G.P2 2 3",
        ),
    ]:
        for entry in entries:
            if entry["name"] == "clamp":
                add(
                    entry,
                    {"name": name, "precision": 64},
                    [low, high, value],
                    [hs_low, hs_high, hs_value],
                    {"dtype": "value"},
                )
            elif entry["name"] in ("minimumScalar", "maximumScalar"):
                add(
                    entry,
                    {"name": name, "precision": 64},
                    [low, high],
                    [hs_low, hs_high],
                    {"dtype": "value"},
                )
    # Mixed raw literals are converted only when an explicit actual primitive
    # prototype is selected; the original Float32 rounding remains observable.
    entry = next(
        e for e in entries if e["module"] == "HMath.Scalar" and e["name"] == "add"
    )
    prototype = own(n.number(16777216.0, "float32"))
    add(
        entry,
        {"name": "mixed-Float32", "precision": 32},
        [prototype, 1.0],
        ["(16777216::Float)", "(1::Float)"],
    )
    imports = """import qualified HMath.Basic as Basic
import qualified HMath.Scalar as Scalar
import qualified HMath.Linear as Linear
import qualified HMath.Statistics as Statistics
import qualified HMath.Numeric as N
import qualified HMath.Autodiff as AD
import qualified HMath.API.Algebra as API
import qualified HMath.Geometry.Internal as G
import Data.Int
import Data.Word
import Data.Char(ord)
import Control.Exception(SomeException,catch,evaluate,displayException)
"""
    source = HASKELL.split("pR=")[0].replace(
        "import qualified HMath.Polynomial as P",
        imports + "\nimport qualified HMath.Polynomial as P",
    )
    source += """instance E Char where enc c="I"++show(ord c)
instance E Int8 where enc x="I"++show x
instance E Word64 where enc x="I"++show x
instance E a=>E(N.Dual a)where enc(N.Dual a b)="ND("++enc a++","++enc b++")"
instance E a=>E(N.Quaternion a)where enc(N.Quaternion a b c d)="Q("++intercalate ","[enc a,enc b,enc c,enc d]++")"
instance E a=>E(AD.Dual a)where enc(AD.Dual a b)="AD("++enc a++","++enc b++")"
instance E API.Exact where enc x="EXACT("++enc(API.getExact x)++")"
instance E G.Point2 where enc(G.P2 x y)="POINT("++enc[x,y]++")"
instance E AD.Expr where enc expression="EXPR("++enc[observe [1.25,2.5],observe[-1,3]]++")" where observe point=either(("E"++).show)(\\(x,y)->enc(x,y))(AD.valueAndGradient(const expression)point)
emit :: String->IO()
emit text=(evaluate(length text)>>putStrLn text) `catch` (\\errorValue->putStrLn("EXCEPTION:"++takeWhile(/='\\n')(displayException(errorValue::SomeException))))
main=mapM_ emit [EXPRESSIONS]
""".replace("EXPRESSIONS", ",\n    ".join(expressions))
    # Expr observation above returns canonical sub-observations, not quoted
    # strings: retain the same actual values+gradients tuple structure.
    source = source.replace(
        "enc[observe [1.25,2.5],observe[-1,3]]",
        '"L["++intercalate ","[observe [1.25,2.5],observe[-1,3]]++"]"',
    )
    with tempfile.TemporaryDirectory(
        prefix="hmath-numeric-object-oracle-"
    ) as directory:
        path = Path(directory) / "Oracle.hs"
        path.write_text(source)
        result = subprocess.run(
            ["runghc", "-isrc", str(path)],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode:
            raise SystemExit(result.stderr[:12000])
    lines = result.stdout.splitlines()
    if len(lines) != len(tests):
        raise AssertionError((len(lines), len(tests)))
    try:
        for (function, arguments, kwargs, precision, name), expected in zip(
            tests, lines
        ):
            try:
                result = function(*arguments, **kwargs)
                actual = encode(result, precision)
                close(result)
            except hmath.HMathError as error:
                actual = (
                    "E" + str(error.math_error)
                    if error.math_error is not None
                    else "EXCEPTION:" + str(error).splitlines()[0]
                )
            if actual != expected:
                raise AssertionError((name, actual, expected))
        for entry, domain, samples in denied:
            arguments = [
                [x for x, _ in samples]
                if argument["type"] == "fs"
                else samples[index % 3][0]
                for index, argument in enumerate(entry["args"])
            ]
            function = getattr(modules[entry["module"].split(".")[-1]], entry["python"])
            try:
                result = function(*arguments)
                close(result)
            except hmath.HMathError as error:
                if error.status != 10:
                    raise AssertionError(
                        (
                            domain["name"],
                            entry["name"],
                            "expected Unsupported",
                            error.status,
                            str(error),
                        )
                    ) from error
            else:
                raise AssertionError(
                    (domain["name"], entry["name"], "invented instance")
                )
    finally:
        for owner in owners:
            owner.close()
    assert len(covered) == 31
    print(
        f"Generic numeric owners: {len(tests)} direct-source cases across31 operations/{len(domains)} actual domains;{len(denied)} absent-instance rejections"
    )


if __name__ == "__main__":
    main()
