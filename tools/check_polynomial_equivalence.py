# SPDX-License-Identifier: MPL-2.0
"""Independent original-Haskell oracle for all public Polynomial operations."""

import argparse
import os
import struct
import subprocess
import sys
import tempfile
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
F = Fraction

HASKELL = r"""{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeSynonymInstances #-}
import qualified HMath.Polynomial as P
import qualified HMath.Matrix as M
import Data.Complex
import Data.Ratio
import Data.List (intercalate)
import GHC.Float (castDoubleToWord64,castFloatToWord32)
class E a where enc :: a -> String
instance E Integer where enc x="I"++show x
instance E Int where enc x="I"++show x
instance E Bool where enc x=if x then "B1" else "B0"
instance E Double where enc x="F64:"++show(castDoubleToWord64 x)
instance E Float where enc x="F32:"++show(castFloatToWord32 x)
instance E Rational where enc x="R"++show(numerator x)++"/"++show(denominator x)
instance E (Complex Double) where enc (r:+i)="C64:"++show(castDoubleToWord64 r)++":"++show(castDoubleToWord64 i)
instance E (Complex Float) where enc (r:+i)="C32:"++show(castFloatToWord32 r)++":"++show(castFloatToWord32 i)
instance E a => E [a] where enc xs="L["++intercalate "," (map enc xs)++"]"
instance (E a,E b) => E (a,b) where enc(a,b)="T["++enc a++","++enc b++"]"
instance (E a,E b,E c) => E (a,b,c) where enc(a,b,c)="T["++enc a++","++enc b++","++enc c++"]"
instance E a => E (P.Polynomial a) where enc p="P["++intercalate "," (map enc(P.coefficients p))++"]"
instance E a => E (P.PowerSeries a) where enc p="S["++intercalate "," (map enc(P.seriesCoefficients p))++"]"
instance E P.RationalFunction where enc f="RF["++enc(P.rationalNumerator f)++","++enc(P.rationalDenominator f)++"]"
instance E a => E (M.Matrix a) where enc m=let(r,c)=M.shape m in "M"++show r++":"++show c++"["++intercalate "," (map enc(M.toList m))++"]"
instance E a => E(Maybe a) where enc Nothing="N"; enc(Just x)=enc x
ok :: E a => Either HMath.Error.MathError a -> String
ok=either (("E"++).show) enc
pR=P.polynomial [-1,0,1] :: P.Polynomial Rational
qR=P.polynomial [-1,1] :: P.Polynomial Rational
sR=P.powerSeries [1,2,3,0] :: P.PowerSeries Rational
tR=P.powerSeries [0,1,0,0] :: P.PowerSeries Rational
rf=case P.rationalFunction (P.polynomial [1]) pR of Right x->x; Left e->error(show e)
pointsR=[(0,1),(1,3),(2,7)] :: [(Rational,Rational)]
main=mapM_ putStrLn
    [ EXPRESSIONS
    ]
""".replace("import Data.Complex", "import qualified HMath.Error\nimport Data.Complex")


def bits(value, precision):
    return struct.unpack(
        "!I" if precision == 32 else "!Q",
        struct.pack("!f" if precision == 32 else "!d", value),
    )[0]


def encode(value, p, precision=64):
    from _hmath_native import _matrix_base

    if value is None:
        return "N"
    if isinstance(value, bool):
        return "B1" if value else "B0"
    if isinstance(value, int):
        return "I" + str(value)
    if isinstance(value, F):
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
    if isinstance(value, p.Polynomial):
        return (
            "P[" + ",".join(encode(x, p, precision) for x in value.coefficients) + "]"
        )
    if isinstance(value, p.PowerSeries):
        return (
            "S[" + ",".join(encode(x, p, precision) for x in value.coefficients) + "]"
        )
    if isinstance(value, p.RationalFunction):
        numerator = p.rational_numerator(value)
        denominator = p.rational_denominator(value)
        try:
            return "RF[" + encode(numerator, p) + "," + encode(denominator, p) + "]"
        finally:
            numerator.close()
            denominator.close()
    if isinstance(value, _matrix_base.Matrix):
        r, c = value.shape
        return (
            f"M{r}:{c}["
            + ",".join(encode(x, p, precision) for x in value.to_list())
            + "]"
        )
    if isinstance(value, (list, tuple)):
        return (
            ("T[" if isinstance(value, tuple) else "L[")
            + ",".join(encode(x, p, precision) for x in value)
            + "]"
        )
    raise TypeError(type(value))


def close(value):
    if isinstance(value, (list, tuple)):
        for item in value:
            close(item)
    elif hasattr(value, "close"):
        value.close()


def cases(p):
    owned = []

    def poly(xs, dtype="rational"):
        x = p.polynomial(xs, dtype=dtype)
        owned.append(x)
        return x

    def series(xs, dtype="rational"):
        x = p.power_series(xs, dtype=dtype)
        owned.append(x)
        return x

    a = poly([-1, 0, 1])
    b = poly([-1, 1])
    s = series([1, 2, 3, 0])
    t = series([0, 1, 0, 0])
    z = poly([])
    rf = p.rational_function(poly([1]), a)
    owned.append(rf)
    points = [(F(0), F(1)), (F(1), F(3)), (F(2), F(7))]
    result = []

    def add(name, args, expression, checked=False, precision=64, kwargs=None):
        result.append(
            (
                name,
                args,
                kwargs or {},
                ("ok" if checked else "enc") + " (" + expression + ")",
                precision,
            )
        )

    add(
        "polynomial",
        ([1, 0, 0],),
        "P.polynomial [1,0,0] :: P.Polynomial Rational",
        kwargs={"dtype": "rational"},
    )
    add("coefficients", (a,), "P.coefficients pR")
    add("polynomial_degree", (a,), "P.polynomialDegree pR")
    add(
        "polynomial_degree",
        (z,),
        "P.polynomialDegree (P.polynomial [] :: P.Polynomial Rational)",
    )
    add("evaluate_polynomial", (a, F(3, 2)), "P.evaluatePolynomial pR (3%2)")
    for python, haskell in [
        ("add_polynomial", "addPolynomial"),
        ("subtract_polynomial", "subtractPolynomial"),
        ("multiply_polynomial", "multiplyPolynomial"),
        ("compose_polynomial", "composePolynomial"),
        ("divide_polynomial", "dividePolynomial"),
        ("gcd_polynomial", "gcdPolynomial"),
    ]:
        add(python, (a, b), "P." + haskell + " pR qR", haskell == "dividePolynomial")
    add("scale_polynomial", (F(3, 2), a), "P.scalePolynomial (3%2) pR")
    add("monic_polynomial", (a,), "P.monicPolynomial pR")
    add("differentiate_polynomial", (a,), "P.differentiatePolynomial pR")
    add("integrate_polynomial", (F(7, 3), a), "P.integratePolynomial (7%3) pR")
    add("square_free_factors", (a,), "P.squareFreeFactors pR")
    add("rational_roots", (1000, a), "P.rationalRoots 1000 pR", True)
    add(
        "factor_rational_polynomial",
        (1000, a),
        "P.factorRationalPolynomial 1000 pR",
        True,
    )
    add("sturm_sequence", (a,), "P.sturmSequence pR", True)
    add("count_real_roots", (a, F(-2), F(2)), "P.countRealRoots pR (-2) 2", True)
    add(
        "isolate_real_roots",
        (20, F(1, 100), a),
        "P.isolateRealRoots 20 (1%100) pR",
        True,
    )
    c = poly([-1, 0, 1], "complex128")
    for py, hs in [
        ("durand_kerner", "durandKerner"),
        ("aberth_ehrlich", "aberthEhrlich"),
    ]:
        add(
            py,
            (200, 1e-8, c),
            "P."
            + hs
            + " 200 1e-8 (P.polynomial [-1,0,1] :: P.Polynomial (Complex Double))",
            True,
        )
    add("companion_matrix", (a,), "P.companionMatrix pR", True)
    for py, hs in [
        ("lagrange_interpolation", "lagrangeInterpolation"),
        ("newton_interpolation", "newtonInterpolation"),
    ]:
        add(py, (points,), "P." + hs + " pointsR", True, kwargs={"dtype": "rational"})
    for py, hs in [
        ("chebyshev_polynomial", "chebyshevPolynomial"),
        ("legendre_polynomial", "legendrePolynomial"),
        ("hermite_polynomial", "hermitePolynomial"),
        ("laguerre_polynomial", "laguerrePolynomial"),
    ]:
        add(
            py,
            (3,),
            "P." + hs + " 3 :: Either HMath.Error.MathError (P.Polynomial Rational)",
            True,
            kwargs={"dtype": "rational"},
        )
    add(
        "bernstein_polynomial",
        (4, 2),
        "P.bernsteinPolynomial 4 2 :: Either HMath.Error.MathError (P.Polynomial Rational)",
        True,
        kwargs={"dtype": "rational"},
    )
    add(
        "polynomial_regression",
        (2, [(0.0, 1.0), (1.0, 3.0), (2.0, 7.0), (3.0, 13.0)]),
        "P.polynomialRegression 2 [(0,1),(1,3),(2,7),(3,13)] :: Either HMath.Error.MathError (P.Polynomial Double)",
        True,
    )
    add(
        "chebyshev_approximation",
        (4, lambda x: x * x + 2 * x + 1),
        "P.chebyshevApproximation 4 (\\x -> x*x+2*x+1)",
        True,
    )
    add(
        "power_series",
        ([1, 0, 0],),
        "P.powerSeries [1,0,0] :: P.PowerSeries Rational",
        kwargs={"dtype": "rational"},
    )
    add("series_coefficients", (s,), "P.seriesCoefficients sR")
    for py, hs, args, hsargs, checked in [
        ("add_series", "addSeries", (s, t), "sR tR", False),
        ("multiply_series", "multiplySeries", (s, t), "sR tR", False),
        ("reciprocal_series", "reciprocalSeries", (s,), "sR", True),
        ("divide_series", "divideSeries", (t, s), "tR sR", True),
        ("compose_series", "composeSeries", (s, t), "sR tR", True),
        ("differentiate_series", "differentiateSeries", (s,), "sR", False),
        ("integrate_series", "integrateSeries", (F(2, 3), s), "(2%3) sR", False),
    ]:
        add(py, args, "P." + hs + " " + hsargs, checked)
    sd = series([1.0, 2.0, 3.0, 0.0], "float64")
    add(
        "exp_series",
        (sd,),
        "P.expSeries (P.powerSeries [1,2,3,0] :: P.PowerSeries Double)",
    )
    add(
        "log_series",
        (sd,),
        "P.logSeries (P.powerSeries [1,2,3,0] :: P.PowerSeries Double)",
        True,
    )
    add(
        "rational_function",
        (poly([1]), a),
        "P.rationalFunction (P.polynomial [1]) pR",
        True,
    )
    add("rational_numerator", (rf,), "P.rationalNumerator rf")
    add("rational_denominator", (rf,), "P.rationalDenominator rf")
    add(
        "evaluate_rational_function",
        (rf, F(3, 2)),
        "P.evaluateRationalFunction rf (3%2)",
        True,
    )
    add("add_rational_function", (rf, rf), "P.addRationalFunction rf rf", True)
    add(
        "multiply_rational_function", (rf, rf), "P.multiplyRationalFunction rf rf", True
    )
    add("partial_fractions", (1000, rf), "P.partialFractions 1000 rf", True)
    # Original checked failures and both floating coefficient types.
    add("divide_polynomial", (a, z), "P.dividePolynomial pR (P.polynomial [])", True)
    add("rational_roots", (-1, a), "P.rationalRoots (-1) pR", True)
    add("count_real_roots", (a, F(2), F(-2)), "P.countRealRoots pR 2 (-2)", True)
    add("reciprocal_series", (t,), "P.reciprocalSeries tR", True)
    add("compose_series", (s, s), "P.composeSeries sR sR", True)
    add("rational_function", (a, z), "P.rationalFunction pR (P.polynomial [])", True)
    add(
        "chebyshev_approximation",
        (-1, lambda x: x),
        "P.chebyshevApproximation (-1) id",
        True,
    )
    for dtype, hsdtype, precision in [
        ("float32", "Float", 32),
        ("float64", "Double", 64),
        ("integer", "Integer", 64),
        ("complex64", "Complex Float", 32),
        ("complex128", "Complex Double", 64),
    ]:
        fp = poly([0.125, 2, -3] if dtype != "integer" else [10**80, 2, -3], dtype)
        xs = "[0.125,2,-3]" if dtype != "integer" else "[" + str(10**80) + ",2,-3]"
        if dtype.startswith("complex"):
            xs = "[0.125 :+ 0,2 :+ 0,(-3) :+ 0]"
        hp = "(P.polynomial " + xs + " :: P.Polynomial (" + hsdtype + "))"
        add(
            "multiply_polynomial",
            (fp, fp),
            "P.multiplyPolynomial " + hp + " " + hp,
            precision=precision,
        )
        add(
            "differentiate_polynomial",
            (fp,),
            "P.differentiatePolynomial " + hp,
            precision=precision,
        )
        if dtype != "integer":
            add(
                "companion_matrix",
                (fp,),
                "P.companionMatrix " + hp,
                True,
                precision=precision,
            )
    return result, owned


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--library", required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(Path(args.library).resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath

    # Test modules may also be exposed through hmath.polynomial by integration.
    from _hmath_native import _matrix_base
    from _hmath_native import polynomial as p

    del _matrix_base
    fixtures, owners = cases(p)
    try:
        source = HASKELL.replace(
            "EXPRESSIONS", "\n    , ".join(item[3] for item in fixtures)
        )
        with tempfile.TemporaryDirectory(prefix="hmath-poly-oracle-") as directory:
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
        for name, arguments, kwargs, _expression, precision in fixtures:
            try:
                result = getattr(p, name)(*arguments, **kwargs)
            except hmath.HMathError as error:
                actual.append("E" + str(error.math_error or error))
            else:
                try:
                    actual.append(encode(result, p, precision))
                finally:
                    close(result)
        failures = [
            (i, fixtures[i][0], want, got)
            for i, (want, got) in enumerate(zip(expected, actual))
            if want != got
        ]
        if len(expected) != len(actual) or failures:
            raise AssertionError(
                f"{len(failures)} Polynomial oracle mismatches: {failures[:12]}"
            )
        print(
            f"Polynomial direct Haskell equivalence: {len(actual)} cases, all50 public functions"
        )
    finally:
        for owner in owners:
            owner.close()


if __name__ == "__main__":
    main()
