# SPDX-License-Identifier: MPL-2.0
"""Independent original-Haskell oracle for all numerical solver adapters."""

import argparse
import json
import os
import subprocess
import sys
import tempfile
from fractions import Fraction
from pathlib import Path

from check_polynomial_equivalence import HASKELL as POLYNOMIAL_HASKELL
from check_polynomial_equivalence import bits, close
from generate_graph_bindings import snake, split_top
from generate_numerical_bindings import TYPES, normalize, spec

ROOT = Path(__file__).resolve().parent.parent
IMPORTS = """import qualified HMath.Calculus as C
import qualified HMath.Root as R
import qualified HMath.ODE as O
import qualified HMath.PDE as D
import qualified HMath.Sparse as S
"""
BASE = POLYNOMIAL_HASKELL.split("pR=")[0].replace("class E a", IMPORTS + "class E a")
FIXTURES = r"""
right(Right x)=x
right(Left e)=error(show e)
f x=x*x-2
square x=x*x
vector x=map negate x
scalar x=sum(map (\v->v*v) x)
matrix xs=[[-1 * (if i==j then 1 else 0) | j<-[0..length xs-1]] | i<-[0..length xs-1]]
path t=[t,t*t]
tangent t=[1,2*t]
rhs _ y=map negate y
boundary a b=zipWith (+) a b
dae _ y dy=zipWith (+) y dy
event _ y=head y-0.5
sensitivity parameters _ y=map ((-head parameters)*) y
surface xy=[head xy,last xy,0]
du _=[1,0,0]
dv _=[0,1,0]
forcing _=[0,0,0]
options=R.defaultRootOptions
tolerance=C.Tolerance 1e-6 1e-6 2000
odeOptions=O.defaultODEOptions
bracket=right(R.bracket f 0 2)
trajectory=right(O.solveIVP O.RK4 odeOptions 10 rhs 0 1 [1])
grid=right(D.grid [3] [(0,1)] [False])
periodicGrid=right(D.grid [3] [(0,1)] [True])
boundaries=[(D.Dirichlet 0,D.Dirichlet 0)]
operator=right(D.assemblePDE D.FiniteDifference grid boundaries [1,1,1] 0)
complexPoly=P.polynomial [(-2):+0,0:+0,1:+0]
rationalPoly=P.polynomial [-2,0,1] :: P.Polynomial Rational
main=mapM_ putStrLn [EXPRESSIONS]
"""


def enc(value, modules):
    from _hmath_native._linear_base import LinearValue
    from _hmath_native._matrix_base import Matrix
    from _hmath_native._value import Value

    if value is None:
        return "N"
    if isinstance(value, bool):
        return "B1" if value else "B0"
    if isinstance(value, Fraction):
        return f"R{value.numerator}/{value.denominator}"
    if isinstance(value, int):
        return "I" + str(value)
    if isinstance(value, float):
        return "F64:" + str(bits(value, 64))
    if isinstance(value, complex):
        return "C64:" + str(bits(value.real, 64)) + ":" + str(bits(value.imag, 64))
    if isinstance(value, (list, tuple)):
        return (
            ("T[" if isinstance(value, tuple) else "L[")
            + ",".join(enc(x, modules) for x in value)
            + "]"
        )
    if isinstance(value, Matrix):
        r, c = value.shape
        return f"M{r}:{c}[" + ",".join(enc(x, modules) for x in value.to_list()) + "]"
    if isinstance(value, LinearValue) and value.source_type == "HMath.Sparse.Sparse":
        return "Sparse" + enc(
            (
                modules["sparse"].sparse_shape(value),
                modules["sparse"].sparse_entries(value),
            ),
            modules,
        )
    if not isinstance(value, Value):
        raise TypeError(type(value))
    kind = value.info[0]
    if kind == 200:
        c = modules["calculus"]
        return enc(
            (c.estimate_value(value), c.estimate_error(value), c.evaluations(value)),
            modules,
        )
    if kind == 206:
        r = modules["root"]
        with r.bisection() as method, r.default_root_options() as options:
            result = r.solve_bracket(method, options, lambda x: x * x - 2, value)
            try:
                return "Bracket" + enc(result, modules)
            finally:
                close(result)
    if kind == 218:
        p = modules["pde"]
        fields = [p.grid_shape(value), p.grid_spacing(value), p.grid_coordinates(value)]
    elif kind == 221:
        p = modules["pde"]
        fields = [p.pde_stiffness(value), p.pde_mass(value), p.pde_boundary_load(value)]
    else:
        namespace, _typ, _kind, names = next(
            item for item in TYPES.values() if item[2] == kind
        )
        if not names:
            return "K" + str(kind)
        fields = [getattr(modules[namespace], snake(name))(value) for name in names]
    try:
        return (
            "O"
            + str(kind)
            + "["
            + ",".join(enc(field, modules) for field in fields)
            + "]"
        )
    finally:
        close(fields)


def source_instances():
    result = [
        "instance E a => E(C.Estimate a) where enc x=enc(C.estimateValue x,C.estimateError x,C.evaluations x)"
    ]
    result.append(
        'instance E(S.Sparse Double) where enc x="Sparse"++enc(S.sparseShape x,S.sparseEntries x)'
    )
    for name, (namespace, typ, tag, fields) in TYPES.items():
        if name == "EstimateValue":
            continue
        typ = typ.replace("P.", "D.")
        q = {"calculus": "C", "root": "R", "ode": "O", "pde": "D"}[namespace]
        if tag == 206:
            body = '"Bracket"++ok(R.solveBracket R.Bisection R.defaultRootOptions f x)'
        elif tag == 218:
            fields = ["gridShape", "gridSpacing", "gridCoordinates"]
            body = None
        else:
            body = None
        if body is None:
            body = (
                '"K' + str(tag) + '"'
                if not fields
                else '"O'
                + str(tag)
                + '["++intercalate "," ['
                + ",".join("enc(" + q + "." + field + " x)" for field in fields)
                + ']++"]"'
            )
        result.append("instance E(" + typ + ") where enc x=" + body)
    return "\n".join(result)


def cases(modules):
    c, r, o, p = (modules[n] for n in ("calculus", "root", "ode", "pde"))
    owners = []

    def keep(value):
        owners.append(value)
        return value

    constructors = {
        "Tolerance": (keep(c.tolerance(1e-6, 1e-6, 2000)), "tolerance"),
        "Difference": (keep(c.central()), "C.Central"),
        "Quadrature": (keep(c.simpson()), "C.Simpson"),
        "RootOptions": (keep(r.default_root_options()), "options"),
        "RootResult": (
            keep(r.root_result(1, 0, None, 2, 3)),
            "R.RootResult 1 0 Nothing 2 3",
        ),
        "Bracket": (keep(r.bracket(lambda x: x * x - 2, 0, 2)), "bracket"),
        "BracketMethod": (keep(r.brent()), "R.Brent"),
        "DerivativeMethod": (keep(r.newton()), "R.Newton"),
        "FixedPointMethod": (keep(r.picard()), "R.Picard"),
        "SystemMethod": (keep(r.multivariate_newton()), "R.MultivariateNewton"),
        "SystemRootResult": (
            keep(r.system_root_result([1], 0, 2, 3)),
            "R.SystemRootResult [1] 0 2 3",
        ),
        "ODEMethod": (keep(o.rk4()), "O.RK4"),
        "ODEOptions": (keep(o.default_ode_options()), "odeOptions"),
        "EventDirection": (keep(o.any_direction()), "O.AnyDirection"),
        "Event": (keep(o.event(0.5, [0.5])), "O.Event 0.5 [0.5]"),
        "HamiltonianMethod": (keep(o.verlet()), "O.Verlet"),
        "Grid": (keep(p.grid([3], [(0, 1)], [False])), "grid"),
        "Boundary": (keep(p.dirichlet(0)), "D.Dirichlet 0"),
        "Discretization": (keep(p.finite_difference()), "D.FiniteDifference"),
        "PDEResult": (keep(p.pde_result([0, 0, 0], 0, 0)), "D.PDEResult [0,0,0] 0 0"),
        "EstimateValue": (
            keep(c.estimate(2.0, 0.1, 4)),
            "C.Estimate (2::Double) 0.1 4",
        ),
    }
    options, ode_options = constructors["RootOptions"][0], constructors["ODEOptions"][0]
    grid, boundary = constructors["Grid"][0], constructors["Boundary"][0]
    boundaries = [(boundary, boundary)]
    trajectory = keep(
        o.solve_ivp(
            constructors["ODEMethod"][0],
            ode_options,
            10,
            lambda t, y: [-v for v in y],
            0,
            1,
            [1],
        )
    )
    constructors["Trajectory"] = (trajectory, "trajectory")
    constructors["PDEOperator"] = (
        keep(
            p.assemble_pde(
                constructors["Discretization"][0], grid, boundaries, [1, 1, 1], 0
            )
        ),
        "operator",
    )
    complex_poly = keep(
        modules["polynomial"].polynomial([-2 + 0j, 0j, 1 + 0j], dtype="complex128")
    )
    rational_poly = keep(modules["polynomial"].polynomial([-2, 0, 1], dtype="rational"))
    functions = {
        ("Double", "Double"): (lambda x: x * x, "square"),
        ("ComplexDouble", "ComplexDouble"): (lambda z: z * z, "(\\z->z*z)"),
        ("list:Double", "Double"): (lambda xs: sum(x * x for x in xs), "scalar"),
        ("list:Double", "list:Double"): (lambda xs: [-x for x in xs], "vector"),
        ("list:Double", "list:list:Double"): (
            lambda xs: [
                [-1.0 if i == j else 0.0 for j in range(len(xs))]
                for i in range(len(xs))
            ],
            "matrix",
        ),
        ("Double", "list:Double"): (lambda t: [t, t * t], "path"),
        ("Double", "list:Double", "list:Double"): (
            lambda t, ys: [-y for y in ys],
            "rhs",
        ),
        ("Double", "list:Double", "Double"): (lambda t, y: y[0] - 0.5, "event"),
        ("list:Double", "list:Double", "list:Double"): (
            lambda a, b: [x + y for x, y in zip(a, b)],
            "boundary",
        ),
        ("Double", "list:Double", "list:Double", "list:Double"): (
            lambda t, y, dy: [a + b for a, b in zip(y, dy)],
            "dae",
        ),
        ("list:Double", "Double", "list:Double", "list:Double"): (
            lambda parameters, t, y: [-parameters[0] * v for v in y],
            "sensitivity",
        ),
    }

    def key(type_):
        return type_[0] + (":" + key(type_[1]) if type_[0] == "list" else "")

    def argument(type_, namespace):
        kind = type_[0]
        if kind == "function":
            return functions[tuple(key(t) for t in type_[1:])]
        if kind in constructors:
            value, expression = constructors[kind]
            return value, "(" + expression + ")"
        defaults = {
            "Double": (0.1, "0.1"),
            "Int": (4, "4"),
            "Integer": (13, "13"),
            "Bool": (False, "False"),
            "Rational": (Fraction(1, 100), "(1/100)"),
            "Value": (2.0, "(2::Double)"),
            "ComplexPolynomial": (complex_poly, "complexPoly"),
            "RationalPolynomial": (rational_poly, "rationalPoly"),
            "list:Double": ([1.0, 2.0], "[1,2]"),
            "list:list:Double": ([[1.0]], "[[1]]"),
            "list:Int": ([0], "[0]"),
            "list:Bool": ([False], "[False]"),
        }
        if key(type_) in defaults:
            return defaults[key(type_)]
        if kind == "maybe":
            return None, "Nothing"
        if kind == "tuple":
            items = [argument(item, namespace) for item in type_[1:]]
            return tuple(v for v, _ in items), "(" + ",".join(e for _, e in items) + ")"
        if kind == "list":
            item, expression = argument(type_[1], namespace)
            return [item], "[" + expression + "]"
        raise ValueError(type_)

    overrides = {}

    def override(namespace, name, values, expressions):
        overrides[(namespace, name)] = (values, expressions)

    # Common quadrature bounds and callback dimensions are explicit.
    tol = constructors["Tolerance"][0]
    for name in ("romberg", "adaptiveIntegrate", "tanhSinh"):
        override(
            "calculus",
            name,
            [tol, lambda x: x * x, 0, 1],
            ["tolerance", "square", "0", "1"],
        )
    for name in ("gaussLegendre", "clenshawCurtis"):
        override(
            "calculus", name, [4, lambda x: x * x, 0, 1], ["4", "square", "0", "1"]
        )
    override(
        "calculus",
        "integrateComposite",
        [constructors["Quadrature"][0], 4, lambda x: x * x, 0, 1],
        ["C.Simpson", "4", "square", "0", "1"],
    )
    override("calculus", "gaussKronrod", [lambda x: x * x, 0, 1], ["square", "0", "1"])
    override(
        "calculus",
        "integrateOscillatory",
        [True, 2, tol, lambda x: x * x, 0, 1],
        ["True", "2", "tolerance", "square", "0", "1"],
    )
    for name in ("integrateND", "volumeIntegral"):
        override(
            "calculus",
            name,
            [2, 4, lambda xs: sum(x * x for x in xs), [(0, 1), (0, 1)]],
            ["2", "4", "scalar", "[(0,1),(0,1)]"],
        )
    override(
        "calculus",
        "monteCarlo",
        [13, 10, lambda xs: sum(x * x for x in xs), [(0, 1), (0, 1)]],
        ["13", "10", "scalar", "[(0,1),(0,1)]"],
    )
    override(
        "calculus",
        "quasiMonteCarlo",
        [10, lambda xs: sum(x * x for x in xs), [(0, 1), (0, 1)]],
        ["10", "scalar", "[(0,1),(0,1)]"],
    )
    override(
        "calculus",
        "pathIntegral",
        [
            tol,
            lambda t: [t, t * t],
            lambda t: [1, 2 * t],
            lambda xs: sum(x * x for x in xs),
            0,
            1,
        ],
        ["tolerance", "path", "tangent", "scalar", "0", "1"],
    )
    override(
        "calculus",
        "lineIntegral",
        [tol, lambda t: [t, t * t], lambda t: [1, 2 * t], lambda xs: xs, 0, 1],
        ["tolerance", "path", "tangent", "id", "0", "1"],
    )
    override(
        "calculus",
        "surfaceIntegral",
        [
            2,
            4,
            lambda xy: [xy[0], xy[1], 0],
            lambda _: [1, 0, 0],
            lambda _: [0, 1, 0],
            lambda xs: sum(x * x for x in xs),
            [(0, 1), (0, 1)],
        ],
        ["2", "4", "surface", "du", "dv", "scalar", "[(0,1),(0,1)]"],
    )
    override(
        "calculus",
        "curl",
        [0.001, lambda xs: [-x for x in xs], [1, 2, 3]],
        ["0.001", "vector", "[1,2,3]"],
    )
    # Use the same scalar residual for each bracketing/derivative solver.
    scalar_root = lambda x: x * x - 2
    for name in ("bracketScan", "isolateIntervals"):
        override(
            "root",
            name,
            [options, scalar_root, 0, 2, 8],
            ["options", "f", "0", "2", "8"],
        )
    override("root", "bracket", [scalar_root, 0, 2], ["f", "0", "2"])
    override(
        "root",
        "solveBracket",
        [
            constructors["BracketMethod"][0],
            options,
            scalar_root,
            constructors["Bracket"][0],
        ],
        ["R.Brent", "options", "f", "bracket"],
    )
    override(
        "root",
        "solveDerivative",
        [
            constructors["DerivativeMethod"][0],
            options,
            scalar_root,
            [lambda x: 2 * x, lambda _: 2, lambda _: 0],
            1,
        ],
        ["R.Newton", "options", "f", "[(\\x->2*x),(const 2),(const 0)]", "1"],
    )
    override("root", "secant", [options, scalar_root, 0, 2], ["options", "f", "0", "2"])
    override("root", "steffensen", [options, scalar_root, 1], ["options", "f", "1"])
    override(
        "root",
        "fixedPoint",
        [constructors["FixedPointMethod"][0], options, lambda x: x / 2, 1],
        ["R.Picard", "options", "(/2)", "1"],
    )
    # ODE time intervals and dimensions remain valid for all methods.
    rhs = lambda _, ys: [-y for y in ys]
    override(
        "ode",
        "solveIVP",
        [constructors["ODEMethod"][0], ode_options, 4, rhs, 0, 1, [1]],
        ["O.RK4", "odeOptions", "4", "rhs", "0", "1", "[1]"],
    )
    override(
        "ode",
        "solveAdaptive",
        [constructors["ODEMethod"][0], ode_options, rhs, 0, 1, [1]],
        ["O.RK4", "odeOptions", "rhs", "0", "1", "[1]"],
    )
    override(
        "ode",
        "solveBoundary",
        [
            constructors["ODEMethod"][0],
            ode_options,
            4,
            rhs,
            lambda a, b: [a[0] + b[0]],
            0,
            1,
            [1],
        ],
        ["O.RK4", "odeOptions", "4", "rhs", "boundary", "0", "1", "[1]"],
    )
    override(
        "ode",
        "solveDAE",
        [ode_options, 4, lambda t, y, dy: [y[0] + dy[0]], 0, 1, [1], [-1]],
        ["odeOptions", "4", "dae", "0", "1", "[1]", "[-1]"],
    )
    override(
        "ode",
        "sensitivities",
        [
            constructors["ODEMethod"][0],
            ode_options,
            4,
            0.001,
            lambda params, t, y: [-params[0] * x for x in y],
            [1],
            0,
            1,
            [1],
        ],
        ["O.RK4", "odeOptions", "4", "0.001", "sensitivity", "[1]", "0", "1", "[1]"],
    )
    override(
        "ode",
        "solveNystrom",
        [4, lambda t, y: [-x for x in y], 0, 1, [1], [0]],
        ["4", "rhs", "0", "1", "[1]", "[0]"],
    )
    override(
        "ode",
        "solveHamiltonian",
        [
            constructors["HamiltonianMethod"][0],
            4,
            lambda x: x,
            lambda x: x,
            0,
            1,
            [1],
            [0],
        ],
        ["O.Verlet", "4", "id", "id", "0", "1", "[1]", "[0]"],
    )
    override(
        "ode",
        "phaseTrajectories",
        [
            constructors["ODEMethod"][0],
            ode_options,
            4,
            lambda x: [-v for v in x],
            0,
            1,
            [[1], [2]],
        ],
        ["O.RK4", "odeOptions", "4", "vector", "0", "1", "[[1],[2]]"],
    )
    override(
        "ode",
        "lyapunovExponents",
        [ode_options, 4, 0.001, rhs, 0, 1, [1]],
        ["odeOptions", "4", "0.001", "rhs", "0", "1", "[1]"],
    )
    override("pde", "grid", [[3], [(0, 1)], [False]], ["[3]", "[(0,1)]", "[False]"])
    entries = json.loads(
        (ROOT / "bindings/schema/numerical-functions.json").read_text()
    )["functions"]
    fixtures = []
    for entry in entries:
        namespace = entry["module"].removeprefix("HMath.").lower()
        names = split_top(normalize(entry["signature"], namespace), "->")
        prepared = [argument(spec(text), namespace) for text in names[:-1]]
        arguments = [value for value, _ in prepared]
        expressions = [expression for _, expression in prepared]
        if (namespace, entry["name"]) in overrides:
            arguments, expressions = overrides[(namespace, entry["name"])]
        # PDE shape-sensitive lists: count3 values and one pair of faces.
        if namespace == "pde" and entry["name"] != "grid":
            for i, text in enumerate(names[:-1]):
                if text == "[Double]":
                    arguments[i] = [1, 1, 1]
                    expressions[i] = "[1,1,1]"
                elif text == "[(Boundary, Boundary)]":
                    arguments[i] = boundaries
                    expressions[i] = "boundaries"
                elif text == "(Double -> [Double])":
                    arguments[i] = lambda _: [0, 0, 0]
                    expressions[i] = "forcing"
        q = {"calculus": "C", "root": "R", "ode": "O", "pde": "D"}[namespace]
        call = q + "." + entry["name"] + " " + " ".join(expressions)
        checked = names[-1].startswith("Either MathError")
        fixtures.append(
            (
                namespace,
                snake(entry["name"]),
                arguments,
                ("ok(" if checked else "enc(") + call + ")",
            )
        )
    # Constructor results are also exercised in the mathematical algorithms.
    for constructor in ("forward", "backward", "central"):
        method = keep(getattr(c, constructor)())
        fixtures.append(
            (
                "calculus",
                "derivative",
                [method, 0.001, lambda x: x * x, 2],
                "ok(C.derivative C." + constructor.capitalize() + " 0.001 square 2)",
            )
        )
    # Feed every public method constructor back into the original algorithm;
    # merely comparing its opaque kind would not distinguish wrong variants.
    for entry in entries:
        if not entry["name"][0].isupper():
            continue
        namespace = entry["module"].removeprefix("HMath.").lower()
        normalized = split_top(normalize(entry["signature"], namespace), "->")
        result_type = normalized[-1]
        targets = {
            "Quadrature",
            "BracketMethod",
            "DerivativeMethod",
            "FixedPointMethod",
            "SystemMethod",
            "ODEMethod",
            "HamiltonianMethod",
            "Discretization",
        }
        if result_type not in targets:
            continue
        prepared = [argument(spec(text), namespace) for text in normalized[:-1]]
        method = keep(
            getattr(modules[namespace], snake(entry["name"]))(*[v for v, _ in prepared])
        )
        qualifier = {"calculus": "C", "root": "R", "ode": "O", "pde": "D"}[namespace]
        expression = (
            "("
            + qualifier
            + "."
            + entry["name"]
            + " "
            + " ".join(e for _, e in prepared)
            + ")"
        )
        if result_type == "Quadrature":
            call = (
                "calculus",
                "integrate_composite",
                [method, 6, lambda x: x * x, 0, 1],
                "ok(C.integrateComposite " + expression + " 6 square 0 1)",
            )
        elif result_type == "BracketMethod":
            call = (
                "root",
                "solve_bracket",
                [method, options, scalar_root, constructors["Bracket"][0]],
                "ok(R.solveBracket " + expression + " options f bracket)",
            )
        elif result_type == "DerivativeMethod":
            call = (
                "root",
                "solve_derivative",
                [
                    method,
                    options,
                    scalar_root,
                    [lambda x: 2 * x, lambda _: 2, lambda _: 0],
                    1,
                ],
                "ok(R.solveDerivative "
                + expression
                + " options f [(\\x->2*x),(const 2),(const 0)] 1)",
            )
        elif result_type == "FixedPointMethod":
            call = (
                "root",
                "fixed_point",
                [method, options, lambda x: x / 2, 1],
                "ok(R.fixedPoint " + expression + " options (/2) 1)",
            )
        elif result_type == "SystemMethod":
            call = (
                "root",
                "solve_system",
                [
                    method,
                    options,
                    lambda xs: [-x for x in xs],
                    lambda xs: [
                        [-1.0 if i == j else 0.0 for j in range(len(xs))]
                        for i in range(len(xs))
                    ],
                    [1, 2],
                ],
                "ok(R.solveSystem " + expression + " options vector matrix [1,2])",
            )
        elif result_type == "ODEMethod":
            call = (
                "ode",
                "solve_ivp",
                [method, ode_options, 4, rhs, 0, 1, [1]],
                "ok(O.solveIVP " + expression + " odeOptions 4 rhs 0 1 [1])",
            )
        elif result_type == "HamiltonianMethod":
            call = (
                "ode",
                "solve_hamiltonian",
                [method, 4, lambda x: x, lambda x: x, 0, 1, [1], [0]],
                "ok(O.solveHamiltonian " + expression + " 4 id id 0 1 [1] [0])",
            )
        else:
            call = (
                "pde",
                "poisson",
                [method, grid, boundaries, [1, 1, 1]],
                "ok(D.poisson " + expression + " grid boundaries [1,1,1])",
            )
        fixtures.append(call)
    return fixtures, owners


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(Path(args.library).resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath

    modules = {
        name: getattr(hmath, name)
        for name in ("calculus", "root", "ode", "pde", "sparse", "polynomial")
    }
    fixtures, owners = cases(modules)
    try:
        source = (
            BASE
            + source_instances()
            + FIXTURES.replace(
                "EXPRESSIONS", ",\n    ".join(case[3] for case in fixtures)
            )
        )
        with tempfile.TemporaryDirectory(prefix="hmath-numerical-oracle-") as directory:
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
                Path("/tmp/hmath-numerical-oracle-failed.hs").write_text(source)
                raise RuntimeError(result.stderr[-12000:])
            expected = result.stdout.splitlines()
        actual = []
        for namespace, name, arguments, _ in fixtures:
            try:
                value = getattr(modules[namespace], name)(*arguments)
            except hmath.HMathError as error:
                actual.append("E" + str(error.math_error or error))
            else:
                try:
                    actual.append(enc(value, modules))
                finally:
                    close(value)
        failures = [
            (fixtures[i][:2], want, got)
            for i, (want, got) in enumerate(zip(expected, actual))
            if want != got
        ]
        if failures or len(expected) != len(actual):
            raise AssertionError(f"Numerical oracle mismatches: {failures[:10]}")
        print(
            f"Numerical solvers: {len(actual)} direct Haskell cases; all185 public operations/constructors"
        )
    finally:
        for owner in owners:
            close(owner)


if __name__ == "__main__":
    main()
