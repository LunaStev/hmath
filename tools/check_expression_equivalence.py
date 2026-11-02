# SPDX-License-Identifier: MPL-2.0
"""Independent original-Haskell oracle for positioned expressions and symbolic APIs."""

import argparse
import dataclasses
import os
import struct
import subprocess
import sys
import tempfile
from enum import IntEnum
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = r"""{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeSynonymInstances #-}
import qualified HMath.Expression as E
import qualified HMath.Symbolic as S
import qualified HMath.Polynomial as P
import qualified Data.Map.Strict as Map
import Data.List (intercalate,elemIndex)
import Data.Char(ord)
import Data.Ratio
import Data.Complex
import Data.Word
import GHC.Float(castDoubleToWord64)
class Enc a where enc :: a -> String
instance Enc Int where enc x="I"++show x
instance Enc Word64 where enc x="I"++show x
instance Enc Bool where enc x=if x then "B1" else "B0"
instance Enc Rational where enc x="R"++show(numerator x)++"/"++show(denominator x)
instance Enc Double where enc x="F"++show(castDoubleToWord64 x)
instance Enc (Complex Double) where enc (x:+y)="C["++enc x++","++enc y++"]"
instance {-# OVERLAPPING #-} Enc String where enc s="U["++intercalate "," (map(show.ord)s)++"]"
instance {-# OVERLAPPABLE #-} Enc a=>Enc[a] where enc xs="L["++intercalate "," (map enc xs)++"]"
instance (Enc a,Enc b)=>Enc(a,b) where enc(a,b)="T["++enc a++","++enc b++"]"
instance (Enc a,Enc b,Enc c)=>Enc(a,b,c) where enc(a,b,c)="T["++enc a++","++enc b++","++enc c++"]"
instance Enc a=>Enc(Maybe a) where enc Nothing="N";enc(Just x)=enc x
instance Enc () where enc ()="N"
instance Enc a=>Enc(Either E.ExprError a) where enc(Left x)="ERR"++enc x;enc(Right x)=enc x
instance Enc E.SourcePos where enc(E.SourcePos a b c)="Pos"++enc(a,b,c)
instance Enc E.Limits where enc l="Limits"++enc[E.maximumSteps l,E.maximumDepth l,E.maximumNodes l,E.maximumInputChars l,E.maximumIntegerBits l,E.maximumCacheEntries l]
enum name values x=name++"#"++show(case elemIndex x values of Just i->i;Nothing->error "enum")
instance Enc E.UnaryOp where enc=enum "UnaryOp" [E.Negate]
instance Enc E.BinaryOp where enc=enum "BinaryOp" [E.Add,E.Subtract,E.Multiply,E.Divide,E.Power]
instance Enc E.NamedConstant where enc=enum "NamedConstant" [E.Pi,E.Euler,E.Tau]
instance Enc E.Precision where enc=enum "Precision" [E.ExactRational,E.Float64]
instance Enc E.ErrorKind where enc=enum "ErrorKind" [E.SyntaxError,E.UnknownName,E.TypeMismatch,E.DomainFailure,E.NonFinite,E.StepLimit,E.DepthLimit,E.MemoryLimit,E.InvalidLimits,E.Unsupported]
instance Enc S.Property where enc=enum "Property" [S.Real,S.NonZero,S.Positive,S.NonNegative,S.Integral,S.Negative,S.NonPositive]
instance Enc S.Direction where enc=enum "Direction" [S.FromLeft,S.FromRight,S.TwoSided]
instance Enc S.RelationOp where enc=enum "RelationOp" [S.Equal,S.NotEqual,S.Less,S.LessEqual,S.Greater,S.GreaterEqual]
instance Enc E.ExprError where enc(E.ExprError k p m)="Error"++enc(k,p,m)
instance Enc E.Value where enc(E.ExactValue q)="Exact"++enc q;enc(E.FloatValue x)="Float"++enc x
instance Enc E.Expr where enc(E.Expr pos node)="Expr["++enc pos++","++enc node++"]"
node tag fields="Node"++show tag++"["++intercalate "," fields++"]"
instance Enc E.ExprNode where
 enc n=case n of
   E.Literal q->node 0[enc q]
   E.Variable x->node 1[enc x]
   E.Constant x->node 2[enc x]
   E.Unary op x->node 3[enc op,enc x]
   E.Binary op x y->node 4[enc op,enc x,enc y]
   E.Call name xs->node 5[enc name,enc xs]
   E.Let name x y->node 6[enc name,enc x,enc y]
instance Enc E.Registry where enc= ("Registry"++).enc.E.allowedFunctions
instance Enc E.Compiled where enc=("Compiled"++).enc.E.compiledNodeCount
instance Enc E.ExpressionCache where enc=("Cache"++).enc.E.cacheSize
instance Enc S.Pattern where
 enc n=case n of
   S.Any name->"Pattern0["++enc name++"]"
   S.Exactly x->"Pattern1["++enc x++"]"
   S.UnaryPattern op x->"Pattern2["++enc op++","++enc x++"]"
   S.BinaryPattern op x y->"Pattern3["++enc op++","++enc x++","++enc y++"]"
   S.CallPattern name xs->"Pattern4["++enc name++","++enc xs++"]"
instance Enc S.PolynomialFactorization where enc(S.PolynomialFactorization a b)="Factors"++enc(a,b)
instance Enc S.Series where enc(S.Series a b c)="Series"++enc(a,b,c)
instance Enc S.RewriteRule where enc(S.RewriteRule a b c)="Rule"++enc(a,b,c)
instance Enc S.Relation where enc(S.Relation a b c)="Relation"++enc(a,b,c)
instance Enc S.LimitResult where
 enc(S.FiniteLimit x)="FiniteLimit"++enc[x]
 enc S.PositiveInfinity="PositiveInfinityL[]"
 enc S.NegativeInfinity="NegativeInfinityL[]"
 enc S.DoesNotExist="DoesNotExistL[]"
instance Enc S.RelationResult where
 enc(S.Truth x)="Truth"++enc[x]
 enc(S.Unresolved x)="Unresolved"++enc[x]
instance Enc S.LinearSolution where
 enc S.Inconsistent="InconsistentL[]"
 enc(S.ParametricSolution a b)="ParametricSolutionT["++enc a++","++enc b++"]"
instance Enc a=>Enc(S.Guarded a) where enc(S.Guarded a b)="Guarded"++enc(a,b)
instance Enc S.SymbolicMatrix where enc=("Matrix"++).enc.S.matrixExpressions
instance Enc(P.Polynomial Rational) where enc=("Polynomial"++).enc.P.coefficients
instance Enc(P.PowerSeries Rational) where enc=("PowerSeries"++).enc.P.seriesCoefficients
l=E.defaultLimits
o=S.defaultSymbolicOptions
p text=either(error.show)id(E.parseExpression l text)
f=p "x^2+x"
x=E.variable "x"
y=E.variable "y"
zero=E.literal 0
one=E.literal 1
pat=S.BinaryPattern E.Add (S.Any "a") (S.Any "a")
rule=S.RewriteRule pat (E.binary E.Multiply (E.literal 2) (E.variable "a")) []
m=either(error.show)id(S.symbolicMatrix o [[x,one],[zero,y]])
jet=either(error.show)id(S.formalPowerSeries o [1,2,0,0])
main=mapM_ putStrLn [CASES]
"""


def close(value):
    if isinstance(value, (list, tuple)):
        for item in value:
            close(item)
    elif dataclasses.is_dataclass(value):
        for field in dataclasses.fields(value):
            close(getattr(value, field.name))
    elif hasattr(value, "close"):
        value.close()


def encode(value, e, s, poly):
    def enc(x):
        return encode(x, e, s, poly)

    if value is None:
        return "N"
    if isinstance(value, bool):
        return "B1" if value else "B0"
    if isinstance(value, IntEnum):
        return type(value).__name__ + "#" + str(int(value))
    if isinstance(value, int):
        return "I" + str(value)
    if isinstance(value, Fraction):
        return f"R{value.numerator}/{value.denominator}"
    if isinstance(value, float):
        return "F" + str(struct.unpack("=Q", struct.pack("=d", value))[0])
    if isinstance(value, complex):
        return "C[" + enc(value.real) + "," + enc(value.imag) + "]"
    if isinstance(value, str):
        return "U[" + ",".join(str(ord(c)) for c in value) + "]"
    if isinstance(value, e.SourcePos):
        return "Pos" + enc((value.offset, value.line, value.column))
    if isinstance(value, e.Limits):
        return "Limits" + enc(
            [getattr(value, f.name) for f in dataclasses.fields(value)]
        )
    if isinstance(value, e.ExprError):
        return "Error" + enc((value.kind, value.position, value.message))
    if isinstance(value, e.ExactValue):
        return "Exact" + enc(Fraction(value.value))
    if isinstance(value, e.FloatValue):
        return "Float" + enc(float(value.value))
    if isinstance(value, e.Expr):
        with value.node as node:
            return "Expr[" + enc(value.position) + "," + enc(node) + "]"
    if isinstance(value, (e.ExprNode, s.Pattern)):
        fields = value.fields
        try:
            return (
                ("Node" if isinstance(value, e.ExprNode) else "Pattern")
                + str(fields[0])
                + "["
                + ",".join(enc(x) for x in fields[1:])
                + "]"
            )
        finally:
            close(fields)
    if isinstance(value, e.Registry):
        return "Registry" + enc(e.allowed_functions(value))
    if isinstance(value, e.Compiled):
        return "Compiled" + enc(e.compiled_node_count(value))
    if isinstance(value, e.ExpressionCache):
        return "Cache" + enc(e.cache_size(value))
    if isinstance(value, s.PolynomialFactorization):
        return "Factors" + enc((value.leading, value.terms))
    if isinstance(value, s.Series):
        return "Series" + enc((value.center, value.minimum_power, value.terms))
    if isinstance(value, s.RewriteRule):
        return "Rule" + enc((value.pattern, value.replacement, value.requirements))
    if isinstance(value, s.Relation):
        return "Relation" + enc((value.operator, value.left, value.right))
    if isinstance(value, (s.LimitResult, s.RelationResult, s.LinearSolution)):
        values = value.arguments
        return value.name + enc(
            tuple(values) if value.name == "ParametricSolution" else list(values)
        )
    if isinstance(value, s.Guarded):
        return "Guarded" + enc((value.value, value.conditions))
    if isinstance(value, s.SymbolicMatrix):
        rows = s.matrix_expressions(value)
        try:
            return "Matrix" + enc(rows)
        finally:
            close(rows)
    if isinstance(value, poly.Polynomial):
        return "Polynomial" + enc(value.coefficients)
    if isinstance(value, poly.PowerSeries):
        return "PowerSeries" + enc(value.coefficients)
    if isinstance(value, (list, tuple)):
        return (
            ("T[" if isinstance(value, tuple) else "L[")
            + ",".join(enc(x) for x in value)
            + "]"
        )
    raise TypeError(type(value))


def cases(e, s):
    owned = []

    def keep(value):
        owned.append(value)
        return value

    l = e.default_limits()
    o = s.default_symbolic_options()
    owned.append(o)
    reg = keep(e.default_registry())
    empty = keep(e.empty_registry())
    x = keep(e.variable("x"))
    y = keep(e.variable("y"))
    zero = keep(e.literal(0))
    one = keep(e.literal(1))

    def p(text):
        return keep(e.parse_expression(l, text))

    f = p("x^2+x")
    pat = keep(s.BinaryPattern(e.Add, keep(s.Any("a")), keep(s.Any("a"))))
    rule = s.RewriteRule(
        pat, keep(e.binary(e.Multiply, keep(e.literal(2)), keep(e.variable("a")))), []
    )
    matrix = keep(s.symbolic_matrix(o, [[x, one], [zero, y]]))
    jet = keep(s.formal_power_series(o, [1, 2, 0, 0]))
    rows = []

    def add(name, hs, call):
        rows.append((name, hs, call))

    add("limits", "l", lambda: l)
    add("position", "E.SourcePos (-3) 2 9", lambda: e.SourcePos(-3, 2, 9))
    add(
        "raw AST",
        "E.Expr (E.SourcePos 7 2 3) (E.Binary E.Add x (E.literal (2%3)))",
        lambda: e.Expr(
            e.SourcePos(7, 2, 3),
            keep(e.Binary(e.Add, x, keep(e.literal(Fraction(2, 3))))),
        ),
    )
    for text in [
        "-2^2",
        "let a = x+1 in a*a",
        "sin(x)+pi",
        "x +\n 2*y",
        "1.25e-2 + 2//3",
    ]:
        hs = "E.parseExpression l " + repr(text).replace("'", '"').replace("\\n", "\\n")
        add("parse " + text, hs, lambda text=text: e.parse_expression(l, text))
    add("pretty", "E.prettyExpression f", lambda: e.pretty_expression(f))
    add("free", "E.freeVariables f", lambda: e.free_variables(f))
    add("validate", "E.validateExpression l f", lambda: e.validate_expression(l, f))
    add(
        "exact",
        'E.evaluateExpression l E.ExactRational E.defaultRegistry (Map.fromList [("x",E.ExactValue (2%3))]) f',
        lambda: e.evaluate_expression(
            l, e.ExactRational, reg, {"x": e.ExactValue(Fraction(2, 3))}, f
        ),
    )
    add(
        "float",
        'E.evaluateText l E.Float64 E.defaultRegistry Map.empty "sin(pi/2)+sqrt(4)"',
        lambda: e.evaluate_text(l, e.Float64, reg, {}, "sin(pi/2)+sqrt(4)"),
    )
    add(
        "type check",
        'E.typeCheckExpression l E.ExactRational E.defaultRegistry (Map.fromList [("x",E.ExactValue 2)]) f',
        lambda: e.type_check_expression(
            l, e.ExactRational, reg, {"x": e.ExactValue(2)}, f
        ),
    )
    add(
        "registry",
        'E.registerFunction "root" E.Sqrt E.emptyRegistry',
        lambda: e.register_function("root", e.Sqrt, empty),
    )
    add(
        "allowed",
        "E.allowedFunctions E.defaultRegistry",
        lambda: e.allowed_functions(reg),
    )
    add("compiled", "E.compileExpression l f", lambda: e.compile_expression(l, f))
    compiled = keep(e.compile_expression(l, f))
    add(
        "compiled evaluate",
        'E.compileExpression l f >>= E.evaluateCompiled l E.ExactRational E.defaultRegistry (Map.fromList [("x",E.ExactValue (2%3))])',
        lambda: e.evaluate_compiled(
            l, e.ExactRational, reg, {"x": e.ExactValue(Fraction(2, 3))}, compiled
        ),
    )
    add(
        "optimize",
        'E.optimizeExpression l E.ExactRational (p "(2+3)*(x+0)")',
        lambda: e.optimize_expression(l, e.ExactRational, p("(2+3)*(x+0)")),
    )
    cache = keep(e.empty_expression_cache())
    add(
        "cache",
        'E.cachedExpression l "x*x+x*x" E.emptyExpressionCache',
        lambda: e.cached_expression(l, "x*x+x*x", cache),
    )
    add(
        "scientific",
        "E.formatScientific 4 (E.ExactValue (2%3))",
        lambda: e.format_scientific(4, e.ExactValue(Fraction(2, 3))),
    )
    add(
        "radix",
        "E.formatRadix 16 (E.ExactValue (255%16))",
        lambda: e.format_radix(16, e.ExactValue(Fraction(255, 16))),
    )
    add("serialize", "E.serializeExpression l f", lambda: e.serialize_expression(l, f))
    serialized = e.serialize_expression(l, f)
    add(
        "deserialize",
        "E.serializeExpression l f >>= E.deserializeExpression l",
        lambda: e.deserialize_expression(l, serialized),
    )
    add("hash", "E.expressionHash l f", lambda: e.expression_hash(l, f))
    for name in [
        "normalize",
        "simplify",
        "expand",
        "collectTerms",
        "trigonometricSimplify",
        "logarithmicSimplify",
    ]:
        py = {
            "collectTerms": "collect_terms",
            "trigonometricSimplify": "trigonometric_simplify",
            "logarithmicSimplify": "logarithmic_simplify",
        }.get(name, name)
        add(
            name,
            "S." + name + ' o (p "(x+1)*(x-1)")',
            lambda py=py: getattr(s, py)(o, p("(x+1)*(x-1)")),
        )
    add(
        "factor",
        'S.factorPolynomial o "x" (p "x^2-1")',
        lambda: s.factor_polynomial(o, "x", p("x^2-1")),
    )
    add(
        "rational simplify",
        'S.rationalSimplify o "x" (p "(x^2-1)/(x-1)")',
        lambda: s.rational_simplify(o, "x", p("(x^2-1)/(x-1)")),
    )
    add(
        "substitute",
        'S.substitute l [("x",y)] (p "let y = 2 in x+y")',
        lambda: s.substitute(l, [("x", y)], p("let y = 2 in x+y")),
    )
    add(
        "prove",
        "S.proves S.noAssumptions S.Positive (E.literal 2)",
        lambda: s.proves(o.assumptions, s.Positive, keep(e.literal(2))),
    )
    add(
        "match",
        'S.matchPattern l pat (p "x+x")',
        lambda: s.match_pattern(l, pat, p("x+x")),
    )
    add(
        "rewrite",
        'S.applyRewrite o rule (p "x+x")',
        lambda: s.apply_rewrite(o, rule, p("x+x")),
    )
    add("derivative", 'S.differentiate o "x" f', lambda: s.differentiate(o, "x", f))
    add(
        "gradient",
        'S.gradient o ["x","y"] (p "x^2+x*y")',
        lambda: s.gradient(o, ["x", "y"], p("x^2+x*y")),
    )
    add(
        "jacobian",
        'S.jacobian o ["x","y"] [p "x*y",p "x+y"]',
        lambda: s.jacobian(o, ["x", "y"], [p("x*y"), p("x+y")]),
    )
    add(
        "hessian",
        'S.hessian o ["x","y"] (p "x^2+x*y")',
        lambda: s.hessian(o, ["x", "y"], p("x^2+x*y")),
    )
    add(
        "integrate basic",
        'S.integrateBasic o "x" f',
        lambda: s.integrate_basic(o, "x", f),
    )
    add(
        "by parts",
        'S.integrateByParts o "x" x (p "exp(x)")',
        lambda: s.integrate_by_parts(o, "x", x, p("exp(x)")),
    )
    add(
        "substitution integral",
        'S.integrateSubstitution o "x" "t" (p "x^2") (p "exp(t)") (p "2*x*exp(x^2)")',
        lambda: s.integrate_substitution(
            o, "x", "t", p("x^2"), p("exp(t)"), p("2*x*exp(x^2)")
        ),
    )
    add(
        "rational integral",
        'S.integrateRational o "x" one (p "x^2+1")',
        lambda: s.integrate_rational(o, "x", one, p("x^2+1")),
    )
    for name, source in [("Finite", "(x^2-1)/(x-1)"), ("Pole", "1/x")]:
        center = 1 if name == "Finite" else 0
        for hs, direction in [
            ("FromLeft", s.FromLeft),
            ("FromRight", s.FromRight),
            ("TwoSided", s.TwoSided),
        ]:
            add(
                "limit " + name + hs,
                'S.symbolicLimit o "x" '
                + str(center)
                + " S."
                + hs
                + ' (p "'
                + source
                + '")',
                lambda source=source, center=center, direction=direction: (
                    s.symbolic_limit(o, "x", Fraction(center), direction, p(source))
                ),
            )
    for name, py in [
        ("taylorSeries", "taylor_series"),
        ("laurentSeries", "laurent_series"),
    ]:
        text = "1/(1-x)" if name == "taylorSeries" else "1/(x^2*(1-x))"
        add(
            name,
            "S." + name + ' o "x" 0 3 (p "' + text + '")',
            lambda py=py, text=text: getattr(s, py)(o, "x", Fraction(0), 3, p(text)),
        )
    add(
        "maclaurin",
        'S.maclaurinSeries o "x" 3 (p "exp(x)")',
        lambda: s.maclaurin_series(o, "x", 3, p("exp(x)")),
    )
    add(
        "formal series",
        "S.formalPowerSeries o [1,2,0,0]",
        lambda: s.formal_power_series(o, [1, 2, 0, 0]),
    )
    add(
        "formal multiply",
        "S.multiplyFormalSeries o jet jet",
        lambda: s.multiply_formal_series(o, jet, jet),
    )
    add(
        "formal reciprocal",
        "S.reciprocalFormalSeries o jet",
        lambda: s.reciprocal_formal_series(o, jet),
    )
    add("polynomial", 'S.toPolynomial o "x" f', lambda: s.to_polynomial(o, "x", f))
    polynomial = keep(s.to_polynomial(o, "x", f))
    add(
        "from polynomial",
        'S.fromPolynomial "x" (P.polynomial [0,1,1])',
        lambda: s.from_polynomial("x", polynomial),
    )
    add(
        "exact roots",
        'S.exactPolynomialRoots o "x" (p "(x-1)^2*(x+2)")',
        lambda: s.exact_polynomial_roots(o, "x", p("(x-1)^2*(x+2)")),
    )
    add(
        "numeric roots",
        'S.numericalPolynomialRoots o "x" (p "x^2-1")',
        lambda: s.numerical_polynomial_roots(o, "x", p("x^2-1")),
    )
    add(
        "relation",
        "S.simplifyRelation o (S.Relation S.Less one (E.literal 2))",
        lambda: s.simplify_relation(o, s.Relation(s.Less, one, keep(e.literal(2)))),
    )
    add(
        "inequality",
        'S.solveLinearInequality o "x" (S.Relation S.Less (p "-2*x+3") one)',
        lambda: s.solve_linear_inequality(o, "x", s.Relation(s.Less, p("-2*x+3"), one)),
    )
    add(
        "linear system",
        'S.solveLinearEquations o ["x","y"] [(x,E.literal 2)]',
        lambda: s.solve_linear_equations(o, ["x", "y"], [(x, keep(e.literal(2)))]),
    )
    add(
        "matrix",
        "S.symbolicMatrix o [[x,one],[zero,y]]",
        lambda: s.symbolic_matrix(o, [[x, one], [zero, y]]),
    )
    add("matrix rows", "S.matrixExpressions m", lambda: s.matrix_expressions(matrix))
    add("matrix add", "S.matrixAdd o m m", lambda: s.matrix_add(o, matrix, matrix))
    add(
        "matrix multiply",
        "S.matrixMultiply o m m",
        lambda: s.matrix_multiply(o, matrix, matrix),
    )
    add(
        "determinant",
        "S.symbolicDeterminant o m",
        lambda: s.symbolic_determinant(o, matrix),
    )
    add(
        "eigenvalues",
        "S.symbolicEigenvalues o m",
        lambda: s.symbolic_eigenvalues(o, matrix),
    )
    add(
        "numerical substitute",
        'S.numericalSubstitution o E.ExactRational [("x",E.ExactValue (2%3))] f',
        lambda: s.numerical_substitution(
            o, e.ExactRational, [("x", e.ExactValue(Fraction(2, 3)))], f
        ),
    )
    add("latex", "S.toLaTeX l f", lambda: s.to_la_te_x(l, f))
    add("mathml", "S.toMathML l f", lambda: s.to_math_ml(l, f))
    errors = [
        ("syntax", 'E.parseExpression l ")"', lambda: e.parse_expression(l, ")")),
        (
            "unknown",
            'E.evaluateText l E.ExactRational E.defaultRegistry Map.empty "λ"',
            lambda: e.evaluate_text(l, e.ExactRational, reg, {}, "λ"),
        ),
        (
            "type",
            'E.evaluateText l E.ExactRational E.defaultRegistry Map.empty "sin(1)"',
            lambda: e.evaluate_text(l, e.ExactRational, reg, {}, "sin(1)"),
        ),
        (
            "domain",
            'E.evaluateText l E.ExactRational E.defaultRegistry Map.empty "1/0"',
            lambda: e.evaluate_text(l, e.ExactRational, reg, {}, "1/0"),
        ),
        (
            "step",
            'E.parseExpression (l{E.maximumSteps=1}) "1"',
            lambda: e.parse_expression(dataclasses.replace(l, maximum_steps=1), "1"),
        ),
        (
            "depth",
            'E.parseExpression (l{E.maximumDepth=1}) "1"',
            lambda: e.parse_expression(dataclasses.replace(l, maximum_depth=1), "1"),
        ),
        (
            "memory",
            'E.parseExpression (l{E.maximumInputChars=1}) "12"',
            lambda: e.parse_expression(
                dataclasses.replace(l, maximum_input_chars=1), "12"
            ),
        ),
        (
            "invalid",
            "E.validateLimits (l{E.maximumSteps=0})",
            lambda: e.validate_limits(dataclasses.replace(l, maximum_steps=0)),
        ),
        (
            "unsupported",
            'S.integrateBasic o "x" (p "exp(x^2)")',
            lambda: s.integrate_basic(o, "x", p("exp(x^2)")),
        ),
    ]
    for name, hs, call in errors:
        add("error " + name, hs, call)
    return rows, owned


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", required=True, type=Path)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(args.library.resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    from _hmath_native import expression as e
    from _hmath_native import polynomial as poly
    from _hmath_native import symbolic as s

    selected, owned = cases(e, s)
    try:
        with tempfile.TemporaryDirectory(
            prefix="hmath-expression-oracle-"
        ) as temporary:
            path = Path(temporary)
            source = path / "Main.hs"
            source.write_text(
                SOURCE.replace(
                    "CASES", ",".join("enc (" + hs + ")" for _, hs, _ in selected)
                )
            )
            subprocess.run(
                [
                    "ghc",
                    "-XHaskell2010",
                    "-O1",
                    "-i" + str(ROOT / "src"),
                    "-outputdir",
                    temporary,
                    str(source),
                    "-o",
                    str(path / "oracle"),
                ],
                check=True,
                stdout=subprocess.DEVNULL,
            )
            expected = subprocess.check_output(
                [str(path / "oracle")], text=True
            ).splitlines()
        for (name, _, call), reference in zip(selected, expected, strict=True):
            output = None
            try:
                output = call()
                actual = encode(output, e, s, poly)
            except hmath.HMathError as error:
                if error.expression_error is None:
                    raise
                actual = "ERR" + encode(error.expression_error, e, s, poly)
            finally:
                close(output)
            if actual != reference:
                raise AssertionError(f"{name}: binding {actual}, original {reference}")
        print(
            f"Expression/Symbolic equivalence: {len(selected)} independent original Haskell operation sequences match exact ASTs/positions, rational data, binary64 bits, conditions and errors."
        )
    finally:
        close(owned)


if __name__ == "__main__":
    main()
