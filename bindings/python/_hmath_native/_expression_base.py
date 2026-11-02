# SPDX-License-Identifier: MPL-2.0
"""Original positioned expression trees and bounded symbolic transformations."""

import ctypes as C
from dataclasses import dataclass
from enum import IntEnum
from fractions import Fraction

from . import _value as v
from . import (
    polynomial as _polynomial,  # noqa: F401 - register exact polynomial/series owners
)
from ._compat import zip_equal
from ._expression_catalog import CATALOG
from ._expression_error import ErrorKind, ExprError, SourcePos
from ._numeric import _int

_SPEC = {entry["module"] + "." + entry["name"]: entry for entry in CATALOG}


class UnaryOp(IntEnum):
    NEGATE = 0


class BinaryOp(IntEnum):
    ADD = 0
    SUBTRACT = 1
    MULTIPLY = 2
    DIVIDE = 3
    POWER = 4


class NamedConstant(IntEnum):
    PI = 0
    EULER = 1
    TAU = 2


class Precision(IntEnum):
    EXACT_RATIONAL = 0
    FLOAT64 = 1


class Builtin(IntEnum):
    SIN = 0
    COS = 1
    TAN = 2
    EXP = 3
    LOG = 4
    SQRT = 5
    ABS = 6
    SIGNUM = 7
    FLOOR = 8
    CEILING = 9
    MIN = 10
    MAX = 11
    ASIN = 12
    ACOS = 13
    ATAN = 14
    SINH = 15
    COSH = 16
    TANH = 17


class Property(IntEnum):
    REAL = 0
    NON_ZERO = 1
    POSITIVE = 2
    NON_NEGATIVE = 3
    INTEGRAL = 4
    NEGATIVE = 5
    NON_POSITIVE = 6


class Direction(IntEnum):
    FROM_LEFT = 0
    FROM_RIGHT = 1
    TWO_SIDED = 2


class RelationOp(IntEnum):
    EQUAL = 0
    NOT_EQUAL = 1
    LESS = 2
    LESS_EQUAL = 3
    GREATER = 4
    GREATER_EQUAL = 5


@dataclass(frozen=True)
class Limits:
    maximum_steps: int = 100000
    maximum_depth: int = 128
    maximum_nodes: int = 20000
    maximum_input_chars: int = 100000
    maximum_integer_bits: int = 1024
    maximum_cache_entries: int = 64


class Value:
    """Original tagged expression value; ExactValue and FloatValue stay distinct."""


@dataclass(frozen=True)
class ExactValue(Value):
    value: Fraction


@dataclass(frozen=True)
class FloatValue(Value):
    value: float


Bindings = dict[str, Value]


@dataclass(frozen=True)
class SymbolicOptions:
    limits: Limits
    assumptions: object


@dataclass(frozen=True)
class PolynomialFactorization:
    leading: Fraction
    terms: list


@dataclass(frozen=True)
class RewriteRule:
    pattern: object
    replacement: object
    requirements: list


@dataclass(frozen=True)
class Series:
    center: Fraction
    minimum_power: int
    terms: list


@dataclass(frozen=True)
class Relation:
    operator: RelationOp
    left: object
    right: object


@dataclass(frozen=True)
class Guarded:
    value: object
    conditions: list


@dataclass(frozen=True)
class _Sum:
    name: str
    arguments: tuple = ()


class LimitResult(_Sum):
    pass


class RelationResult(_Sum):
    pass


class LinearSolution(_Sum):
    pass


class Expr(v.Value):
    """Immutable original Expr, retaining its source position and full AST."""

    def __init__(self, position, node):
        result = _raw("HMath.Expression.Expr", position, node)
        self._ptr, self._lock, self._owners = result._ptr, result._lock, result._owners
        result._ptr, result._owners = C.c_void_p(), ()

    @property
    def position(self):
        return expression_position(self)

    @property
    def node(self):
        return expression_node(self)

    def __eq__(self, other):
        if not isinstance(other, Expr):
            return NotImplemented
        return _extra("hmath_expression_compare", self, other) == 0

    def __lt__(self, other):
        if not isinstance(other, Expr):
            return NotImplemented
        return _extra("hmath_expression_compare", self, other) < 0

    def __le__(self, other):
        if not isinstance(other, Expr):
            return NotImplemented
        return _extra("hmath_expression_compare", self, other) <= 0

    def __gt__(self, other):
        if not isinstance(other, Expr):
            return NotImplemented
        return _extra("hmath_expression_compare", self, other) > 0

    def __ge__(self, other):
        if not isinstance(other, Expr):
            return NotImplemented
        return _extra("hmath_expression_compare", self, other) >= 0

    __hash__ = None


class ExprNode(v.Value):
    @property
    def fields(self):
        """(constructor code, payload...), preserving child Expr owners.

        Codes:0Literal,1Variable,2Constant,3Unary,4Binary,5Call,6Let.
        """
        fields = _extra("hmath_expression_node_fields", self)
        kind = fields[0]
        if kind == 2:
            return (kind, NamedConstant(fields[1]))
        if kind == 3:
            return (kind, UnaryOp(fields[1]), fields[2])
        if kind == 4:
            return (kind, BinaryOp(fields[1]), *fields[2:])
        return fields

    def __eq__(self, other):
        if not isinstance(other, ExprNode):
            return NotImplemented
        return _extra("hmath_expression_node_compare", self, other) == 0

    def __lt__(self, other):
        if not isinstance(other, ExprNode):
            return NotImplemented
        return _extra("hmath_expression_node_compare", self, other) < 0

    __hash__ = None


class Registry(v.Value):
    pass


class Compiled(v.Value):
    pass


class ExpressionCache(v.Value):
    pass


class Pattern(v.Value):
    @property
    def fields(self):
        """(constructor code, payload...): Any,Exactly,Unary,Binary,Call."""
        fields = _extra("hmath_symbolic_pattern_fields", self)
        if fields[0] == 2:
            return (fields[0], UnaryOp(fields[1]), *fields[2:])
        if fields[0] == 3:
            return (fields[0], BinaryOp(fields[1]), *fields[2:])
        return fields

    def __eq__(self, other):
        if not isinstance(other, Pattern):
            return NotImplemented
        return _extra("hmath_symbolic_pattern_equal", self, other)

    __hash__ = None


class Assumptions(v.Value):
    pass


class SymbolicMatrix(v.Value):
    pass


for _kind, _owner in [
    (80, Expr),
    (81, ExprNode),
    (82, Registry),
    (83, Compiled),
    (84, ExpressionCache),
    (85, Pattern),
    (86, Assumptions),
    (87, SymbolicMatrix),
]:
    v.register(_kind, _owner)

_ENUMS = {
    cls.__name__: cls
    for cls in [
        UnaryOp,
        BinaryOp,
        NamedConstant,
        Precision,
        Builtin,
        ErrorKind,
        Property,
        Direction,
        RelationOp,
    ]
}
_RECORDS = {
    "SourcePos": (SourcePos, ["offset", "line", "column"], ["Int"] * 3),
    "Limits": (
        Limits,
        [
            "maximum_steps",
            "maximum_depth",
            "maximum_nodes",
            "maximum_input_chars",
            "maximum_integer_bits",
            "maximum_cache_entries",
        ],
        ["Int"] * 6,
    ),
    "ExprError": (
        ExprError,
        ["kind", "position", "message"],
        ["ErrorKind", "SourcePos", "String"],
    ),
    "SymbolicOptions": (
        SymbolicOptions,
        ["limits", "assumptions"],
        ["Limits", "Assumptions"],
    ),
    "PolynomialFactorization": (
        PolynomialFactorization,
        ["leading", "terms"],
        ["Rational", "[(Expr,Int)]"],
    ),
    "RewriteRule": (
        RewriteRule,
        ["pattern", "replacement", "requirements"],
        ["Pattern", "Expr", "[(String,Property)]"],
    ),
    "Series": (
        Series,
        ["center", "minimum_power", "terms"],
        ["Rational", "Int", "[Expr]"],
    ),
    "Relation": (
        Relation,
        ["operator", "left", "right"],
        ["RelationOp", "Expr", "Expr"],
    ),
    "Guarded": (Guarded, ["value", "conditions"], ["Generic", "[(Expr,Property)]"]),
}


def _split(hint):
    depth = 0
    start = 0
    parts = []
    for index, char in enumerate(hint):
        if char in "[(":
            depth += 1
        elif char in "])":
            depth -= 1
        elif char == "," and depth == 0:
            parts.append(hint[start:index])
            start = index + 1
    parts.append(hint[start:])
    return parts


def _pack(items, hints, tuple_=False):
    values = []
    try:
        for item, hint in zip_equal(items, hints):
            values.append(_typed(item, hint))
        return v.encode(tuple(values) if tuple_ else values)
    finally:
        for value in values:
            value.close()


def _typed(value, hint):
    if isinstance(value, v.Value):
        return value.clone()
    if isinstance(value, _Sum):
        entry = next(
            e
            for e in CATALOG
            if e["name"] == value.name and e["module"] == "HMath.Symbolic"
        )
        return _raw(entry["module"] + "." + entry["name"], *value.arguments)
    if hint == "Int" or hint in _ENUMS:
        if hint in _ENUMS:
            value = _ENUMS[hint](value)
        return v._create("hmath_value_index", [C.c_ssize_t], [_int(value)])
    if hint == "Rational":
        return v.scalar(value, "rational")
    if hint == "Double":
        return v.scalar(value, "float64")
    if hint == "String":
        if not isinstance(value, str):
            raise TypeError("expected String")
        return v.encode(value)
    if hint == "Bool":
        if not isinstance(value, bool):
            raise TypeError("expected Bool")
        return v.encode(value)
    if hint == "ExpressionValue":
        if isinstance(value, ExactValue):
            return _pack([0, value.value], ["Int", "Rational"], True)
        if isinstance(value, FloatValue):
            return _pack([1, value.value], ["Int", "Double"], True)
        raise TypeError("expected ExactValue or FloatValue")
    if hint == "Bindings":
        items = list(value.items()) if isinstance(value, dict) else list(value)
        return _typed(items, "[(String,ExpressionValue)]")
    if hint.startswith("Maybe"):
        return v.encode(None) if value is None else _typed(value, hint[5:])
    if hint.startswith("["):
        items = list(value)
        return _pack(items, [hint[1:-1]] * len(items))
    if hint.startswith("("):
        return _pack(tuple(value), _split(hint[1:-1]), True)
    if hint in _RECORDS:
        cls, names, hints = _RECORDS[hint]
        if not isinstance(value, cls):
            raise TypeError("expected " + hint)
        return _pack([getattr(value, name) for name in names], hints, True)
    if hint == "Generic":
        for record, (cls, _, _) in _RECORDS.items():
            if isinstance(value, cls):
                return _typed(value, record)
        if isinstance(value, Value):
            return _typed(value, "ExpressionValue")
        return v.encode(value)
    return v.encode(value)


def _decode(value, hint):
    if hint in _ENUMS:
        return _ENUMS[hint](value)
    if hint == "ExpressionValue":
        return ExactValue(value[1]) if value[0] == 0 else FloatValue(value[1])
    if hint in _RECORDS:
        cls, _, hints = _RECORDS[hint]
        return cls(*[_decode(item, field) for item, field in zip_equal(value, hints)])
    if hint == "Guarded[Expr]":
        return Guarded(value[0], [(expr, Property(prop)) for expr, prop in value[1]])
    if hint == "LimitResult":
        names = ["FiniteLimit", "PositiveInfinity", "NegativeInfinity", "DoesNotExist"]
        return LimitResult(names[value[0]], tuple(value[1:]))
    if hint == "RelationResult":
        return (
            RelationResult("Truth", (value[1],))
            if value[0] == 0
            else RelationResult("Unresolved", (_decode(value[1], "Relation"),))
        )
    if hint == "LinearSolution":
        return (
            LinearSolution("Inconsistent")
            if value[0] == 0
            else LinearSolution("ParametricSolution", (value[1], value[2]))
        )
    if hint.startswith("Maybe"):
        return None if value is None else _decode(value, hint[5:])
    if hint.startswith("["):
        return [_decode(item, hint[1:-1]) for item in value]
    if hint.startswith("("):
        return tuple(
            _decode(item, field) for item, field in zip_equal(value, _split(hint[1:-1]))
        )
    return value


def _raw(name, *arguments):
    entry = _SPEC[name]
    if len(arguments) != len(entry["arguments"]):
        raise TypeError(name + " argument count differs")
    values = []
    try:
        for value, (_, hint) in zip_equal(arguments, entry["arguments"]):
            values.append(_typed(value, hint))
        return v.invoke(entry["c"], *values)
    finally:
        for value in values:
            value.close()


def _invoke(name, *arguments):
    return _decode(v.decode(_raw(name, *arguments)), _SPEC[name]["result"])


def _extra(symbol, *args):
    return v.decode(v.invoke(symbol, *args))


# BEGIN GENERATED
def unknown_position():
    """HMath.Expression.unknownPosition: original semantics and checked errors."""
    return _invoke("HMath.Expression.unknownPosition")


def source_offset(position):
    """HMath.Expression.sourceOffset: original semantics and checked errors."""
    return _invoke("HMath.Expression.sourceOffset", position)


def source_line(position):
    """HMath.Expression.sourceLine: original semantics and checked errors."""
    return _invoke("HMath.Expression.sourceLine", position)


def source_column(position):
    """HMath.Expression.sourceColumn: original semantics and checked errors."""
    return _invoke("HMath.Expression.sourceColumn", position)


Negate = UnaryOp.NEGATE

Add = BinaryOp.ADD

Subtract = BinaryOp.SUBTRACT

Multiply = BinaryOp.MULTIPLY

Divide = BinaryOp.DIVIDE

Power = BinaryOp.POWER

Pi = NamedConstant.PI

Euler = NamedConstant.EULER

Tau = NamedConstant.TAU

ExactRational = Precision.EXACT_RATIONAL

Float64 = Precision.FLOAT64

SyntaxError = ErrorKind.SYNTAX_ERROR

UnknownName = ErrorKind.UNKNOWN_NAME

TypeMismatch = ErrorKind.TYPE_MISMATCH

DomainFailure = ErrorKind.DOMAIN_FAILURE

NonFinite = ErrorKind.NON_FINITE

StepLimit = ErrorKind.STEP_LIMIT

DepthLimit = ErrorKind.DEPTH_LIMIT

MemoryLimit = ErrorKind.MEMORY_LIMIT

InvalidLimits = ErrorKind.INVALID_LIMITS

Unsupported = ErrorKind.UNSUPPORTED

Sin = Builtin.SIN

Cos = Builtin.COS

Tan = Builtin.TAN

Exp = Builtin.EXP

Log = Builtin.LOG

Sqrt = Builtin.SQRT

Abs = Builtin.ABS

Signum = Builtin.SIGNUM

Floor = Builtin.FLOOR

Ceiling = Builtin.CEILING

Min = Builtin.MIN

Max = Builtin.MAX

Asin = Builtin.ASIN

Acos = Builtin.ACOS

Atan = Builtin.ATAN

Sinh = Builtin.SINH

Cosh = Builtin.COSH

Tanh = Builtin.TANH


def expression_position(expression):
    """HMath.Expression.expressionPosition: original semantics and checked errors."""
    return _invoke("HMath.Expression.expressionPosition", expression)


def expression_node(expression):
    """HMath.Expression.expressionNode: original semantics and checked errors."""
    return _invoke("HMath.Expression.expressionNode", expression)


def Literal(value):
    """HMath.Expression.Literal: original semantics and checked errors."""
    return _invoke("HMath.Expression.Literal", value)


def Variable(name):
    """HMath.Expression.Variable: original semantics and checked errors."""
    return _invoke("HMath.Expression.Variable", name)


def Constant(constant):
    """HMath.Expression.Constant: original semantics and checked errors."""
    return _invoke("HMath.Expression.Constant", constant)


def Unary(operator, child):
    """HMath.Expression.Unary: original semantics and checked errors."""
    return _invoke("HMath.Expression.Unary", operator, child)


def Binary(operator, left, right):
    """HMath.Expression.Binary: original semantics and checked errors."""
    return _invoke("HMath.Expression.Binary", operator, left, right)


def Call(name, arguments):
    """HMath.Expression.Call: original semantics and checked errors."""
    return _invoke("HMath.Expression.Call", name, arguments)


def Let(name, value, body):
    """HMath.Expression.Let: original semantics and checked errors."""
    return _invoke("HMath.Expression.Let", name, value, body)


def literal(value):
    """HMath.Expression.literal: original semantics and checked errors."""
    return _invoke("HMath.Expression.literal", value)


def variable(name):
    """HMath.Expression.variable: original semantics and checked errors."""
    return _invoke("HMath.Expression.variable", name)


def constant(constant):
    """HMath.Expression.constant: original semantics and checked errors."""
    return _invoke("HMath.Expression.constant", constant)


def unary(operator, child):
    """HMath.Expression.unary: original semantics and checked errors."""
    return _invoke("HMath.Expression.unary", operator, child)


def binary(operator, left, right):
    """HMath.Expression.binary: original semantics and checked errors."""
    return _invoke("HMath.Expression.binary", operator, left, right)


def call(name, arguments):
    """HMath.Expression.call: original semantics and checked errors."""
    return _invoke("HMath.Expression.call", name, arguments)


def let_in(name, value, body):
    """HMath.Expression.letIn: original semantics and checked errors."""
    return _invoke("HMath.Expression.letIn", name, value, body)


def default_limits():
    """HMath.Expression.defaultLimits: original semantics and checked errors."""
    return _invoke("HMath.Expression.defaultLimits")


def maximum_steps(limits):
    """HMath.Expression.maximumSteps: original semantics and checked errors."""
    return _invoke("HMath.Expression.maximumSteps", limits)


def maximum_depth(limits):
    """HMath.Expression.maximumDepth: original semantics and checked errors."""
    return _invoke("HMath.Expression.maximumDepth", limits)


def maximum_nodes(limits):
    """HMath.Expression.maximumNodes: original semantics and checked errors."""
    return _invoke("HMath.Expression.maximumNodes", limits)


def maximum_input_chars(limits):
    """HMath.Expression.maximumInputChars: original semantics and checked errors."""
    return _invoke("HMath.Expression.maximumInputChars", limits)


def maximum_integer_bits(limits):
    """HMath.Expression.maximumIntegerBits: original semantics and checked errors."""
    return _invoke("HMath.Expression.maximumIntegerBits", limits)


def maximum_cache_entries(limits):
    """HMath.Expression.maximumCacheEntries: original semantics and checked errors."""
    return _invoke("HMath.Expression.maximumCacheEntries", limits)


def error_kind(error):
    """HMath.Expression.errorKind: original semantics and checked errors."""
    return _invoke("HMath.Expression.errorKind", error)


def error_position(error):
    """HMath.Expression.errorPosition: original semantics and checked errors."""
    return _invoke("HMath.Expression.errorPosition", error)


def error_message(error):
    """HMath.Expression.errorMessage: original semantics and checked errors."""
    return _invoke("HMath.Expression.errorMessage", error)


def validate_limits(limits):
    """HMath.Expression.validateLimits: original semantics and checked errors."""
    return _invoke("HMath.Expression.validateLimits", limits)


def validate_expression(limits, expression):
    """HMath.Expression.validateExpression: original semantics and checked errors."""
    return _invoke("HMath.Expression.validateExpression", limits, expression)


def parse_expression(limits, source):
    """HMath.Expression.parseExpression: original semantics and checked errors."""
    return _invoke("HMath.Expression.parseExpression", limits, source)


def pretty_expression(expression):
    """HMath.Expression.prettyExpression: original semantics and checked errors."""
    return _invoke("HMath.Expression.prettyExpression", expression)


def free_variables(expression):
    """HMath.Expression.freeVariables: original semantics and checked errors."""
    return _invoke("HMath.Expression.freeVariables", expression)


def default_registry():
    """HMath.Expression.defaultRegistry: original semantics and checked errors."""
    return _invoke("HMath.Expression.defaultRegistry")


def empty_registry():
    """HMath.Expression.emptyRegistry: original semantics and checked errors."""
    return _invoke("HMath.Expression.emptyRegistry")


def register_function(name, builtin, registry):
    """HMath.Expression.registerFunction: original semantics and checked errors."""
    return _invoke("HMath.Expression.registerFunction", name, builtin, registry)


def allowed_functions(registry):
    """HMath.Expression.allowedFunctions: original semantics and checked errors."""
    return _invoke("HMath.Expression.allowedFunctions", registry)


def type_check_expression(limits, precision, registry, bindings, expression):
    """HMath.Expression.typeCheckExpression: original semantics and checked errors."""
    return _invoke(
        "HMath.Expression.typeCheckExpression",
        limits,
        precision,
        registry,
        bindings,
        expression,
    )


def evaluate_expression(limits, precision, registry, bindings, expression):
    """HMath.Expression.evaluateExpression: original semantics and checked errors."""
    return _invoke(
        "HMath.Expression.evaluateExpression",
        limits,
        precision,
        registry,
        bindings,
        expression,
    )


def evaluate_text(limits, precision, registry, bindings, source):
    """HMath.Expression.evaluateText: original semantics and checked errors."""
    return _invoke(
        "HMath.Expression.evaluateText", limits, precision, registry, bindings, source
    )


def evaluate_compiled(limits, precision, registry, bindings, compiled):
    """HMath.Expression.evaluateCompiled: original semantics and checked errors."""
    return _invoke(
        "HMath.Expression.evaluateCompiled",
        limits,
        precision,
        registry,
        bindings,
        compiled,
    )


def compile_expression(limits, expression):
    """HMath.Expression.compileExpression: original semantics and checked errors."""
    return _invoke("HMath.Expression.compileExpression", limits, expression)


def compiled_node_count(compiled):
    """HMath.Expression.compiledNodeCount: original semantics and checked errors."""
    return _invoke("HMath.Expression.compiledNodeCount", compiled)


def optimize_expression(limits, precision, expression):
    """HMath.Expression.optimizeExpression: original semantics and checked errors."""
    return _invoke("HMath.Expression.optimizeExpression", limits, precision, expression)


def empty_expression_cache():
    """HMath.Expression.emptyExpressionCache: original semantics and checked errors."""
    return _invoke("HMath.Expression.emptyExpressionCache")


def cache_size(cache):
    """HMath.Expression.cacheSize: original semantics and checked errors."""
    return _invoke("HMath.Expression.cacheSize", cache)


def cached_expression(limits, source, cache):
    """HMath.Expression.cachedExpression: original semantics and checked errors."""
    return _invoke("HMath.Expression.cachedExpression", limits, source, cache)


def format_scientific(digits, value):
    """HMath.Expression.formatScientific: original semantics and checked errors."""
    return _invoke("HMath.Expression.formatScientific", digits, value)


def format_radix(radix, value):
    """HMath.Expression.formatRadix: original semantics and checked errors."""
    return _invoke("HMath.Expression.formatRadix", radix, value)


def serialize_expression(limits, expression):
    """HMath.Expression.serializeExpression: original semantics and checked errors."""
    return _invoke("HMath.Expression.serializeExpression", limits, expression)


def deserialize_expression(limits, serialized):
    """HMath.Expression.deserializeExpression: original semantics and checked errors."""
    return _invoke("HMath.Expression.deserializeExpression", limits, serialized)


def expression_hash(limits, expression):
    """HMath.Expression.expressionHash: original semantics and checked errors."""
    return _invoke("HMath.Expression.expressionHash", limits, expression)


Real = Property.REAL

NonZero = Property.NON_ZERO

Positive = Property.POSITIVE

NonNegative = Property.NON_NEGATIVE

Integral = Property.INTEGRAL

Negative = Property.NEGATIVE

NonPositive = Property.NON_POSITIVE

FromLeft = Direction.FROM_LEFT

FromRight = Direction.FROM_RIGHT

TwoSided = Direction.TWO_SIDED

Equal = RelationOp.EQUAL

NotEqual = RelationOp.NOT_EQUAL

Less = RelationOp.LESS

LessEqual = RelationOp.LESS_EQUAL

Greater = RelationOp.GREATER

GreaterEqual = RelationOp.GREATER_EQUAL


def assumptions(entries):
    """HMath.Symbolic.assumptions: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.assumptions", entries)


def no_assumptions():
    """HMath.Symbolic.noAssumptions: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.noAssumptions")


def proves(assumptions, property, expression):
    """HMath.Symbolic.proves: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.proves", assumptions, property, expression)


def default_symbolic_options():
    """HMath.Symbolic.defaultSymbolicOptions: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.defaultSymbolicOptions")


def symbolic_limits(options):
    """HMath.Symbolic.symbolicLimits: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.symbolicLimits", options)


def symbolic_assumptions(options):
    """HMath.Symbolic.symbolicAssumptions: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.symbolicAssumptions", options)


def normalize(options, expression):
    """HMath.Symbolic.normalize: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.normalize", options, expression)


def simplify(options, expression):
    """HMath.Symbolic.simplify: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.simplify", options, expression)


def expand(options, expression):
    """HMath.Symbolic.expand: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.expand", options, expression)


def collect_terms(options, expression):
    """HMath.Symbolic.collectTerms: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.collectTerms", options, expression)


def trigonometric_simplify(options, expression):
    """HMath.Symbolic.trigonometricSimplify: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.trigonometricSimplify", options, expression)


def logarithmic_simplify(options, expression):
    """HMath.Symbolic.logarithmicSimplify: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.logarithmicSimplify", options, expression)


def factor_polynomial(options, variable, expression):
    """HMath.Symbolic.factorPolynomial: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.factorPolynomial", options, variable, expression)


def rational_simplify(options, variable, expression):
    """HMath.Symbolic.rationalSimplify: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.rationalSimplify", options, variable, expression)


def differentiate(options, variable, expression):
    """HMath.Symbolic.differentiate: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.differentiate", options, variable, expression)


def integrate_basic(options, variable, expression):
    """HMath.Symbolic.integrateBasic: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.integrateBasic", options, variable, expression)


def to_polynomial(options, variable, expression):
    """HMath.Symbolic.toPolynomial: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.toPolynomial", options, variable, expression)


def exact_polynomial_roots(options, variable, expression):
    """HMath.Symbolic.exactPolynomialRoots: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.exactPolynomialRoots", options, variable, expression)


def numerical_polynomial_roots(options, variable, expression):
    """HMath.Symbolic.numericalPolynomialRoots: original semantics and checked errors."""
    return _invoke(
        "HMath.Symbolic.numericalPolynomialRoots", options, variable, expression
    )


def factor_leading(factorization):
    """HMath.Symbolic.factorLeading: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.factorLeading", factorization)


def factor_terms(factorization):
    """HMath.Symbolic.factorTerms: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.factorTerms", factorization)


def substitute(limits, bindings, expression):
    """HMath.Symbolic.substitute: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.substitute", limits, bindings, expression)


def Any(name):
    """HMath.Symbolic.Any: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.Any", name)


def Exactly(expression):
    """HMath.Symbolic.Exactly: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.Exactly", expression)


def UnaryPattern(operator, child):
    """HMath.Symbolic.UnaryPattern: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.UnaryPattern", operator, child)


def BinaryPattern(operator, left, right):
    """HMath.Symbolic.BinaryPattern: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.BinaryPattern", operator, left, right)


def CallPattern(name, arguments):
    """HMath.Symbolic.CallPattern: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.CallPattern", name, arguments)


def match_pattern(limits, pattern, expression):
    """HMath.Symbolic.matchPattern: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.matchPattern", limits, pattern, expression)


def rewrite_pattern(rule):
    """HMath.Symbolic.rewritePattern: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.rewritePattern", rule)


def rewrite_replacement(rule):
    """HMath.Symbolic.rewriteReplacement: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.rewriteReplacement", rule)


def rewrite_requirements(rule):
    """HMath.Symbolic.rewriteRequirements: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.rewriteRequirements", rule)


def apply_rewrite(options, rule, expression):
    """HMath.Symbolic.applyRewrite: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.applyRewrite", options, rule, expression)


def gradient(options, variables, expression):
    """HMath.Symbolic.gradient: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.gradient", options, variables, expression)


def hessian(options, variables, expression):
    """HMath.Symbolic.hessian: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.hessian", options, variables, expression)


def jacobian(options, variables, expressions):
    """HMath.Symbolic.jacobian: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.jacobian", options, variables, expressions)


def integrate_by_parts(options, variable, u, dv):
    """HMath.Symbolic.integrateByParts: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.integrateByParts", options, variable, u, dv)


def integrate_substitution(options, variable, temporary, inner, outer, integrand):
    """HMath.Symbolic.integrateSubstitution: original semantics and checked errors."""
    return _invoke(
        "HMath.Symbolic.integrateSubstitution",
        options,
        variable,
        temporary,
        inner,
        outer,
        integrand,
    )


def integrate_rational(options, variable, numerator, denominator):
    """HMath.Symbolic.integrateRational: original semantics and checked errors."""
    return _invoke(
        "HMath.Symbolic.integrateRational", options, variable, numerator, denominator
    )


def FiniteLimit(value):
    """HMath.Symbolic.FiniteLimit: original semantics and checked errors."""
    return LimitResult("FiniteLimit", (value,))


PositiveInfinity = LimitResult("PositiveInfinity")

NegativeInfinity = LimitResult("NegativeInfinity")

DoesNotExist = LimitResult("DoesNotExist")


def symbolic_limit(options, variable, center, direction, expression):
    """HMath.Symbolic.symbolicLimit: original semantics and checked errors."""
    return _invoke(
        "HMath.Symbolic.symbolicLimit", options, variable, center, direction, expression
    )


def series_center(series):
    """HMath.Symbolic.seriesCenter: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.seriesCenter", series)


def series_minimum_power(series):
    """HMath.Symbolic.seriesMinimumPower: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.seriesMinimumPower", series)


def series_terms(series):
    """HMath.Symbolic.seriesTerms: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.seriesTerms", series)


def taylor_series(options, variable, center, order, expression):
    """HMath.Symbolic.taylorSeries: original semantics and checked errors."""
    return _invoke(
        "HMath.Symbolic.taylorSeries", options, variable, center, order, expression
    )


def laurent_series(options, variable, center, order, expression):
    """HMath.Symbolic.laurentSeries: original semantics and checked errors."""
    return _invoke(
        "HMath.Symbolic.laurentSeries", options, variable, center, order, expression
    )


def maclaurin_series(options, variable, order, expression):
    """HMath.Symbolic.maclaurinSeries: original semantics and checked errors."""
    return _invoke(
        "HMath.Symbolic.maclaurinSeries", options, variable, order, expression
    )


def formal_power_series(options, coefficients):
    """HMath.Symbolic.formalPowerSeries: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.formalPowerSeries", options, coefficients)


def multiply_formal_series(options, left, right):
    """HMath.Symbolic.multiplyFormalSeries: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.multiplyFormalSeries", options, left, right)


def reciprocal_formal_series(options, series):
    """HMath.Symbolic.reciprocalFormalSeries: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.reciprocalFormalSeries", options, series)


def from_polynomial(variable, polynomial):
    """HMath.Symbolic.fromPolynomial: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.fromPolynomial", variable, polynomial)


def Truth(value):
    """HMath.Symbolic.Truth: original semantics and checked errors."""
    return RelationResult("Truth", (value,))


def Unresolved(relation):
    """HMath.Symbolic.Unresolved: original semantics and checked errors."""
    return RelationResult("Unresolved", (relation,))


def simplify_relation(options, relation):
    """HMath.Symbolic.simplifyRelation: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.simplifyRelation", options, relation)


def solve_linear_inequality(options, variable, relation):
    """HMath.Symbolic.solveLinearInequality: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.solveLinearInequality", options, variable, relation)


Inconsistent = LinearSolution("Inconsistent")


def ParametricSolution(bindings, free_variables):
    """HMath.Symbolic.ParametricSolution: original semantics and checked errors."""
    return LinearSolution("ParametricSolution", (bindings, free_variables))


def solve_linear_equations(options, variables, equations):
    """HMath.Symbolic.solveLinearEquations: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.solveLinearEquations", options, variables, equations)


def symbolic_matrix(options, rows):
    """HMath.Symbolic.symbolicMatrix: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.symbolicMatrix", options, rows)


def matrix_expressions(matrix):
    """HMath.Symbolic.matrixExpressions: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.matrixExpressions", matrix)


def matrix_add(options, left, right):
    """HMath.Symbolic.matrixAdd: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.matrixAdd", options, left, right)


def matrix_multiply(options, left, right):
    """HMath.Symbolic.matrixMultiply: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.matrixMultiply", options, left, right)


def symbolic_determinant(options, matrix):
    """HMath.Symbolic.symbolicDeterminant: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.symbolicDeterminant", options, matrix)


def guarded_value(guarded):
    """HMath.Symbolic.guardedValue: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.guardedValue", guarded)


def required_conditions(guarded):
    """HMath.Symbolic.requiredConditions: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.requiredConditions", guarded)


def symbolic_eigenvalues(options, matrix):
    """HMath.Symbolic.symbolicEigenvalues: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.symbolicEigenvalues", options, matrix)


def numerical_substitution(options, precision, bindings, expression):
    """HMath.Symbolic.numericalSubstitution: original semantics and checked errors."""
    return _invoke(
        "HMath.Symbolic.numericalSubstitution", options, precision, bindings, expression
    )


def to_la_te_x(limits, expression):
    """HMath.Symbolic.toLaTeX: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.toLaTeX", limits, expression)


def to_math_ml(limits, expression):
    """HMath.Symbolic.toMathML: original semantics and checked errors."""
    return _invoke("HMath.Symbolic.toMathML", limits, expression)


# END GENERATED
