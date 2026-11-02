# SPDX-License-Identifier: MPL-2.0
"""Original Haskell KnownNat/KnownShape oracle, including huge type indices."""

import argparse
import os
import subprocess
import sys
import tempfile
from fractions import Fraction as Q
from pathlib import Path

from check_algebra_equivalence import normalized
from check_polynomial_equivalence import HASKELL, close

ROOT = Path(__file__).resolve().parent.parent


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--library", required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(Path(args.library).resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    from _hmath_native import algebra as a
    from _hmath_native import algebra_api as p
    from _hmath_native import shape_values as s
    from _hmath_native._foundation_base import FoundationValue

    modules = {"HMath.Algebra": a, "HMath.API.Algebra": p}
    owners = []
    tests = []
    expressions = []

    def own(value):
        owners.append(value)
        return value

    matrix = own(p.matrix_construct(2, 2, [1, 2, 3, 4]))
    tensor = own(p.tensor_construct([2], [1, 2]))
    static = own(s.static_matrix(2, 2, matrix))
    stensor = own(s.static_tensor([2], tensor))
    coord = own(s.coordinates(2, [Q(1, 3), Q(2, 5)]))
    shape = own(s.make_shape([2, 3]))
    scalar = own(s.make_shape([]))
    vector = own(s.make_shape([3]))
    exact = own(p.Exact(Q(2, 3)))

    def add(function, values, expression, checked=False, kwargs=None):
        tests.append((function, values, kwargs or {}, function.__name__))
        expressions.append(("ok" if checked else "enc") + "(" + expression + ")")

    add(s.shape_dimensions, [shape], "S.shapeDimensions shape")
    add(s.shape_elements, [shape], "S.shapeElements shape")
    for dims, hs in [
        ([], "[]"),
        ([2, 3], "[2,3]"),
        ([2, 0, 3], "[2,0,3]"),
        ([-1], "[-1]"),
        ([2**62, 4], "[4611686018427387904,4]"),
    ]:
        add(s.make_shape, [dims], "S.makeShape " + hs, True)
    add(s.scalar_shape, [scalar], "case scalar of S.ScalarShape -> True;_ -> False")
    add(s.scalar_shape, [shape], "case shape of S.ScalarShape -> True;_ -> False")
    add(
        s.vector_shape,
        [vector],
        "case vector of S.VectorShape n -> Just n;_ -> Nothing",
    )
    add(s.vector_shape, [shape], "case shape of S.VectorShape n -> Just n;_ -> Nothing")
    add(
        s.matrix_shape,
        [shape],
        "case shape of S.MatrixShape r c -> Just(r,c);_ -> Nothing",
    )
    add(s.static_matrix, [2, 2, matrix], "S.staticMatrix @2 @2 mat", True)
    add(s.static_matrix, [1, 4, matrix], "S.staticMatrix @1 @4 mat", True)
    add(
        s.static_matrix,
        [2**100, 2, matrix],
        "S.staticMatrix @1267650600228229401496703205376 @2 mat",
        True,
    )
    add(s.dynamic_matrix, [static], "S.dynamicMatrix sm")
    add(s.static_multiply, [static, static], "S.staticMultiply sm sm", True)
    add(s.static_transpose, [static], "S.staticTranspose sm")
    add(s.reflected_shape, [[2, 3]], "S.reflectedShape(Proxy::Proxy '[2,3])")
    add(
        s.reflected_shape,
        [[2**100, 0]],
        "S.reflectedShape(Proxy::Proxy '[1267650600228229401496703205376,0])",
    )
    add(s.static_tensor, [[2], tensor], "S.staticTensor @'[2] ten", True)
    add(s.static_tensor, [[1, 2], tensor], "S.staticTensor @'[1,2] ten", True)
    add(s.dynamic_tensor, [stensor], "S.dynamicTensor st")
    add(
        s.coordinates,
        [2, [Q(1, 3), Q(2, 5)]],
        "S.coordinates @2 [1%3,2%5::Rational]",
        True,
    )
    add(
        s.coordinates,
        [3, [Q(1, 3), Q(2, 5)]],
        "S.coordinates @3 [1%3,2%5::Rational]",
        True,
    )
    add(s.coordinate_values, [coord], "S.coordinateValues co")
    add(s.coordinates_to_vector, [coord], "S.coordinatesToVector co", True)
    for values, hs, dtype in [
        ([True, False], "[True,False]", "bool"),
        (["α\0", "🙂"], '["α\\NUL","🙂"]', "string"),
        ([exact, exact], "[P.Exact(2%3),P.Exact(2%3)]", exact),
    ]:
        add(
            s.coordinates, [2, values], "S.coordinates @2 " + hs, True, {"dtype": dtype}
        )
        value = own(s.coordinates(2, values, dtype=dtype))
        add(
            s.coordinates_to_vector,
            [value],
            "S.coordinatesToVector(right(S.coordinates @2 " + hs + "))",
            True,
        )

    def encode(value):
        if isinstance(value, FoundationValue) and value.source_type.startswith(
            "HMath.API.Shape."
        ):
            name = value.source_type.rsplit(".", 1)[-1]
            if name == "Shape":
                data = (value.dimensions, value.elements)
            elif name == "StaticMatrix":
                data = s.dynamic_matrix(value)
            elif name == "StaticTensor":
                data = s.dynamic_tensor(value)
            elif name == "Coordinates":
                data = s.coordinate_values(value)
            else:
                raise TypeError(name)
            try:
                return name + "(" + normalized(data, modules) + ")"
            finally:
                close(data)
        return normalized(value, modules)

    imports = """import qualified HMath.API.Shape as S
import qualified HMath.API.Algebra as P
import qualified HMath.Polynomial as Poly
import qualified HMath.Tensor as T
import qualified HMath.Vector as V
import Data.Proxy(Proxy(..))
import Data.Char(ord)
"""
    source = (
        HASKELL.split("pR=")[0]
        .replace("import qualified HMath.Polynomial as P", imports)
        .replace("P.Polynomial", "Poly.Polynomial")
        .replace("P.coefficients", "Poly.coefficients")
        .replace("P.PowerSeries", "Poly.PowerSeries")
        .replace("P.seriesCoefficients", "Poly.seriesCoefficients")
        .replace("P.RationalFunction", "Poly.RationalFunction")
        .replace("P.rationalNumerator", "Poly.rationalNumerator")
        .replace("P.rationalDenominator", "Poly.rationalDenominator")
    )
    source = (
        "{-# LANGUAGE DataKinds #-}\n{-# LANGUAGE TypeApplications #-}\n{-# LANGUAGE PatternSynonyms #-}\n"
        + source
        + """instance E Char where enc c="I"++show(ord c)
instance E P.Exact where enc x="X("++enc(P.getExact x)++")"
instance E S.Shape where enc x="Shape("++enc(S.shapeDimensions x,S.shapeElements x)++")"
instance E a=>E(S.StaticMatrix m n a)where enc x="StaticMatrix("++enc(S.dynamicMatrix x)++")"
instance E a=>E(S.StaticTensor ds a)where enc x="StaticTensor("++enc(S.dynamicTensor x)++")"
instance E a=>E(S.Coordinates n a)where enc x="Coordinates("++enc(S.coordinateValues x)++")"
instance E a=>E(V.Vector a)where enc x="VECTOR("++enc(V.vectorValues x)++")"
instance E a=>E(T.Tensor a)where enc x="TENSOR("++enc(T.tensorShape x,T.tensorValues x)++")"
right=either(error.show)id
mat=right(P.matrixConstruct 2 2 [1,2,3,4])::M.Matrix Integer
ten=right(P.tensorConstruct [2] [1,2])::T.Tensor Integer
sm=right(S.staticMatrix @2 @2 mat)
st=right(S.staticTensor @'[2] ten)
co=right(S.coordinates @2 [1%3,2%5::Rational])
shape=right(S.makeShape [2,3])
scalar=right(S.makeShape [])
vector=right(S.makeShape [3])
main=mapM_ putStrLn [EXPRESSIONS]
""".replace("EXPRESSIONS", ",\n    ".join(expressions))
    )
    with tempfile.TemporaryDirectory() as directory:
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
            raise SystemExit(result.stderr)
    lines = result.stdout.splitlines()
    if len(lines) != len(tests):
        raise AssertionError((len(lines), len(tests)))
    try:
        for (function, values, kwargs, name), expected in zip(tests, lines):
            try:
                value = function(*values, **kwargs)
                actual = encode(value)
                close(value)
            except hmath.HMathError as error:
                actual = "E" + str(error.math_error)
            if actual != expected:
                raise AssertionError((name, actual, expected))
    finally:
        for owner in owners:
            owner.close()
    print(
        f"Shape direct Haskell equivalence: {len(tests)} cases;21 source symbols;genuine nominal indices/Int overflow/structural interop"
    )


if __name__ == "__main__":
    main()
