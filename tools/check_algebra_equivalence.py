# SPDX-License-Identifier: MPL-2.0
"""Direct source oracle for every algebra operation and actual instance family."""

import argparse
import importlib
import os
import subprocess
import sys
import tempfile
from fractions import Fraction as Q
from pathlib import Path

from check_polynomial_equivalence import HASKELL, bits, close
from generate_algebra_bindings import MODULES, mode, specification
from generate_linear_bindings import snake

ROOT = Path(__file__).resolve().parent.parent


def normalized(value, modules, precision=64):
    from _hmath_native import vector
    from _hmath_native._foundation_base import FoundationValue
    from _hmath_native._linear_base import LinearValue
    from _hmath_native._matrix_base import Matrix
    from _hmath_native._tensor_object import Tensor
    from _hmath_native.polynomial import Polynomial

    if isinstance(value, FoundationValue):
        name = value.source_type.rsplit(".", 1)[-1]
        a = modules["HMath.Algebra"]
        p = modules["HMath.API.Algebra"]
        if name == "Exact":
            return "X(" + normalized(p.get_exact(value), modules, precision) + ")"
        if name == "Additive":
            part = a.get_additive(value)
            try:
                return "A(" + normalized(part, modules, precision) + ")"
            finally:
                close(part)
        if name == "Modular":
            return (
                "Z("
                + normalized(
                    (a.modular_modulus(value), a.modular_value(value)),
                    modules,
                    precision,
                )
                + ")"
            )
        if name == "FiniteField":
            return (
                "F("
                + normalized(
                    (
                        a.field_characteristic(value),
                        a.field_degree(value),
                        a.field_cardinality(value),
                        a.field_modulus(value),
                    ),
                    modules,
                    precision,
                )
                + ")"
            )
        if name == "FieldElement":
            return (
                "E("
                + normalized(a.field_element_coefficients(value), modules, precision)
                + ")"
            )
        raise TypeError(name)
    if isinstance(value, Polynomial):
        return (
            "P["
            + ",".join(normalized(x, modules, precision) for x in value.coefficients)
            + "]"
        )
    if isinstance(value, Matrix):
        r, c = value.shape
        values = value.to_list()
        try:
            return (
                f"M{r}:{c}["
                + ",".join(normalized(x, modules, precision) for x in values)
                + "]"
            )
        finally:
            close(values)
    if isinstance(value, Tensor):
        p = modules["HMath.API.Algebra"]
        values = p.tensor_elements(value)
        try:
            return (
                "TENSOR("
                + normalized((p.tensor_dimensions(value), values), modules, precision)
                + ")"
            )
        finally:
            close(values)
    if isinstance(value, LinearValue):
        return (
            "VECTOR("
            + normalized(vector.vector_values(value), modules, precision)
            + ")"
        )
    if value is None:
        return "N"
    if isinstance(value, bool):
        return "B1" if value else "B0"
    if isinstance(value, int):
        return "I" + str(value)
    if isinstance(value, Q):
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
        return "L[" + ",".join("I" + str(ord(c)) for c in value) + "]"
    if isinstance(value, (list, tuple)):
        return (
            ("T[" if isinstance(value, tuple) else "L[")
            + ",".join(normalized(x, modules, precision) for x in value)
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
    from _hmath_native import algebra as a
    from _hmath_native import algebra_api as p
    from _hmath_native import autodiff as ad
    from _hmath_native import polynomial as poly
    from _hmath_native import vector

    modules = {
        m: importlib.import_module("_hmath_native." + ns)
        for m, (_alias, ns) in MODULES.items()
    }
    owners = []
    tests = []
    expressions = []

    def own(value):
        owners.append(value)
        return value

    field = own(a.finite_field(32, 2, [1, 1, 1]))
    modulus = own(a.modular(7, 3))
    element = own(a.field_element(field, [0, 1]))
    base_poly = own(poly.polynomial([1, 2], dtype="rational"))
    exact = own(p.Exact(Q(2, 3)))
    matrix = own(p.matrix_construct(2, 2, [Q(1), Q(2), Q(3), Q(4)]))
    tensor = own(p.tensor_construct([2], [Q(1), Q(2)]))
    vec = own(vector.vector([Q(1), Q(2)], dtype="rational"))
    dual = own(ad.Dual(Q(2), Q(3), dtype="rational"))
    objects = {
        "Modular": (modulus, "z"),
        "FiniteField": (field, "f"),
        "FieldElement": (element, "e"),
        "Exact": (exact, "P.Exact(2%3)"),
        "Matrix": (matrix, "mat"),
        "Tensor": (tensor, "ten"),
        "Vector": (vec, "vec"),
        "Dual": (dual, "AD.Dual(2%1)(3%1)"),
    }
    entries, _ = specification()

    def typed(type_name):
        if type_name == "Integer":
            return 2, "(2::Integer)", "integer", 64
        if type_name == "Rational":
            return Q(2, 3), "(2%3::Rational)", "rational", 64
        if type_name == "Float":
            return 0.75, "(0.75::Float)", "float32", 32
        if type_name == "Double":
            return 0.75, "(0.75::Double)", "float64", 64
        if type_name == "Complex Double":
            return complex(0.75, 0.25), "(0.75:+0.25::Complex Double)", "complex128", 64
        if type_name == "P.Exact":
            return exact, "(P.Exact(2%3))", exact, 64
        if type_name == "Poly.Polynomial Rational":
            return base_poly, "pol", base_poly, 64
        raise ValueError(type_name)

    def argument(spec, e, index, type_name):
        name = e["name"]
        head, *children = spec
        if head in ("a", "s"):
            return typed(type_name)[:2]
        if head == "v":
            x, h, *_ = typed(type_name)
            return [x, x], "[" + h + "," + h + "]"
        if head == "Additive":
            x, h, dt, _ = typed(type_name)
            return own(a.Additive(x, dtype=dt)), "A.Additive(" + h + ")"
        if head in objects:
            return objects[head]
        if head == "Integer":
            value = 2
            if name == "modular":
                value = 7 if index == 0 else 3
            if name in ("finiteField", "primeField"):
                value = 2
            return value, str(value)
        if head == "Int":
            return (
                (32, "32")
                if name
                in ("finiteField", "primeField", "fieldElements", "finiteFieldLaws")
                else (2, "2")
            )
        if head == "Rational":
            return Q(2, 3), "(2%3)"
        if head == "list":
            if name == "groupLaws":
                x, h, dt, _ = typed(type_name)
                return [own(a.Additive(x, dtype=dt))], "[A.Additive(" + h + ")]"
            if name in ("fieldElement", "finiteField") and children[0] == ["Integer"]:
                return [1, 1, 1], "[1,1,1]"
            if children[0] == ["Integer"]:
                return [1, 2], "[1,2]"
            if children[0] == ["Int"]:
                return [2], "[2]"
            value, h = argument(children[0], e, index, type_name)
            return [value, value], "[" + h + "," + h + "]"
        if head == "tuple":
            values = []
            hs = []
            for i, s in enumerate(children):
                x, h = argument(s, e, i, type_name)
                values.append(x)
                hs.append(h)
            return tuple(values), "(" + ",".join(hs) + ")"
        raise ValueError(spec)

    def hs_type(spec, type_name):
        head, *children = spec
        if head in ("a", "s"):
            return "(" + type_name + ")"
        if head == "v":
            return "[" + type_name + "]"
        if head == "list":
            return "[" + hs_type(children[0], type_name) + "]"
        if head == "tuple":
            return "(" + ",".join(hs_type(s, type_name) for s in children) + ")"
        head = {
            "Additive": "A.Additive",
            "Modular": "A.Modular",
            "FiniteField": "A.FiniteField",
            "FieldElement": "A.FieldElement",
            "Exact": "P.Exact",
            "Matrix": "M.Matrix",
            "Tensor": "T.Tensor",
            "Vector": "V.Vector",
            "Dual": "AD.Dual",
            "MathError": "HMath.Error.MathError",
        }.get(head, head)
        return (
            "("
            + head
            + (
                " " + " ".join(hs_type(s, type_name) for s in children)
                if children
                else ""
            )
            + ")"
        )

    for entry in entries:
        selected = mode(entry)
        name = entry["name"]
        if selected == "old":
            variants = ["Integer", "Rational", "Poly.Polynomial Rational"]
        elif selected == "module":
            variants = ["Integer", "Rational"]
        elif selected == "api":
            variants = [
                "Integer",
                "Rational",
                "Float",
                "Double",
                "Complex Double",
                "P.Exact",
            ]
        else:
            variants = ["Rational"]
        if name in ("inverseField", "fieldLaws"):
            variants = ["Rational"]
        if name == "invert":
            variants = [x for x in variants if x != "Integer"]
        if name in ("machineEpsilon", "finiteScalar"):
            variants = ["Float", "Double", "Complex Double"]
        for type_name in variants:
            values = []
            hsargs = []
            for index, spec in enumerate(entry["args"]):
                value, h = argument(spec, entry, index, type_name)
                values.append(value)
                hsargs.append(h)
            dtype = typed(type_name)[2]
            precision = typed(type_name)[3]
            kwargs = {"dtype": dtype} if selected != "value" else {}
            alias = MODULES[entry["module"]][0]
            expression = (
                "("
                + alias
                + "."
                + name
                + (" " + " ".join("(" + h + ")" for h in hsargs) if hsargs else "")
                + "::"
                + hs_type(entry["result"], type_name)
                + ")"
            )
            # Group instances are Additive; source groupLaws retains its actual
            # polymorphic input and does not pretend Integer itself is a Group.
            if name == "groupLaws":
                expression = "A.groupLaws(" + hsargs[0] + ")"
            if name == "machineEpsilon":
                expression = "P.machineEpsilon(Proxy::Proxy(" + type_name + "))"
            checked = entry["result"][:2] == ["Either", ["MathError"]]
            expressions.append(("ok" if checked else "enc") + "(" + expression + ")")
            function = getattr(
                modules[entry["module"]], name if entry["constructor"] else snake(name)
            )
            tests.append(
                (
                    function,
                    values,
                    kwargs,
                    entry["module"] + "." + name + "[" + type_name + "]",
                    64 if name == "machineEpsilon" else precision,
                )
            )
    # Every structural MatrixLike/TensorLike element family also exercises exact
    # construction and extraction through the ordinary shared object owners.
    for type_name, values, hsvalues, dtype in [
        ("Bool", [True, False], "[True,False]", "bool"),
        ("String", ["a\0α", "β"], '["a\\NULα","β"]', "string"),
        ("P.Exact", [exact, exact], "[P.Exact(2%3),P.Exact(2%3)]", exact),
    ]:
        tests.append(
            (
                p.matrix_construct,
                [1, 2, values],
                {"dtype": dtype},
                "matrixConstruct[" + type_name + "]",
                64,
            )
        )
        expressions.append(
            "ok(P.matrixConstruct 1 2 "
            + hsvalues
            + "::Either HMath.Error.MathError(M.Matrix("
            + type_name
            + ")))"
        )
        tests.append(
            (
                p.tensor_construct,
                [[2], values],
                {"dtype": dtype},
                "tensorConstruct[" + type_name + "]",
                64,
            )
        )
        expressions.append(
            "ok(P.tensorConstruct [2] "
            + hsvalues
            + "::Either HMath.Error.MathError(T.Tensor("
            + type_name
            + ")))"
        )
    imports = """import qualified HMath.Algebra as A
import qualified HMath.API.Algebra as P
import qualified HMath.Polynomial as Poly
import qualified HMath.Tensor as T
import qualified HMath.Vector as V
import qualified HMath.Autodiff as AD
import Data.Proxy(Proxy(..))
import Data.Char(ord)
"""
    source = (
        HASKELL.split("pR=")[0]
        .replace("import qualified HMath.Polynomial as P", imports)
        .replace("(P.Polynomial a)", "(Poly.Polynomial a)")
        .replace("P.coefficients", "Poly.coefficients")
        .replace("(P.PowerSeries a)", "(Poly.PowerSeries a)")
        .replace("P.seriesCoefficients", "Poly.seriesCoefficients")
        .replace("P.RationalFunction", "Poly.RationalFunction")
        .replace("P.rationalNumerator", "Poly.rationalNumerator")
        .replace("P.rationalDenominator", "Poly.rationalDenominator")
    )
    source += """instance E Char where enc c="I"++show(ord c)
instance(E a,E b,E c,E d)=>E(a,b,c,d)where enc(a,b,c,d)="T["++intercalate ","[enc a,enc b,enc c,enc d]++"]"
instance E a=>E(A.Additive a)where enc x="A("++enc(A.getAdditive x)++")"
instance E P.Exact where enc x="X("++enc(P.getExact x)++")"
instance E A.Modular where enc x="Z("++enc(A.modularModulus x,A.modularValue x)++")"
instance E A.FiniteField where enc x="F("++enc(A.fieldCharacteristic x,A.fieldDegree x,A.fieldCardinality x,A.fieldModulus x)++")"
instance E A.FieldElement where enc x="E("++enc(A.fieldElementCoefficients x)++")"
instance E a=>E(V.Vector a)where enc x="VECTOR("++enc(V.vectorValues x)++")"
instance E a=>E(T.Tensor a)where enc x="TENSOR("++enc(T.tensorShape x,T.tensorValues x)++")"
right=either(error.show)id
f=right(A.finiteField 32 2 [1,1,1])
z=right(A.modular 7 3)
e=A.fieldElement f [0,1]
pol=Poly.polynomial [1,2]::Poly.Polynomial Rational
mat=right(P.matrixConstruct 2 2 [1,2,3,4])::M.Matrix Rational
ten=right(P.tensorConstruct [2] [1,2])::T.Tensor Rational
vec=V.vector [1,2]::V.Vector Rational
main=mapM_ putStrLn [EXPRESSIONS]
""".replace("EXPRESSIONS", ",\n    ".join(expressions))
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory) / "Oracle.hs"
        path.write_text(source)
        result = subprocess.run(
            ["runghc", "-isrc", str(path)],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        if result.returncode:
            raise SystemExit(result.stderr)
    expected = result.stdout.splitlines()
    if len(expected) != len(tests):
        raise AssertionError((len(expected), len(tests)))
    try:
        for (function, values, kwargs, name, precision), wanted in zip(tests, expected):
            try:
                value = function(*values, **kwargs)
                actual = normalized(value, modules, precision)
                close(value)
            except hmath.HMathError as error:
                actual = "E" + str(error.math_error)
            if actual != wanted:
                raise AssertionError((name, actual, wanted))
    finally:
        for value in owners:
            value.close()
    print(
        f"Algebra direct Haskell equivalence: {len(tests)} cases;67 operations;85 new source symbols plus existing innerProduct"
    )


if __name__ == "__main__":
    main()
