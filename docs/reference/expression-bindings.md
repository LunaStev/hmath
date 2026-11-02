# Expression and symbolic bindings

`hmath.expression` exposes the original positioned expression language from
`HMath.Expression`. `hmath.symbolic` re-exports that language and the original
bounded symbolic operations from `HMath.Symbolic`. C and C++ include
`hmath_expression.h`. These expression trees are distinct from automatic
differentiation's `hmath.autodiff.Expr`.

```python
from fractions import Fraction
from hmath import expression as expr, symbolic

limits = expr.default_limits()
with expr.default_registry() as registry:
    with expr.parse_expression(limits, "let a = x+1 in a*a") as expression:
        result = expr.evaluate_expression(
            limits,
            expr.ExactRational,
            registry,
            {"x": expr.ExactValue(Fraction(2, 3))},
            expression,
        )
        assert result == expr.ExactValue(Fraction(25, 9))

with symbolic.no_assumptions() as assumptions:
    options = symbolic.SymbolicOptions(limits, assumptions)
    with expr.parse_expression(limits, "x^2+x") as expression:
        with symbolic.differentiate(options, "x", expression) as derivative:
            print(expr.pretty_expression(derivative))
```

## Expression trees and positions

`Expr(position, node)` preserves the original `SourcePos` and `ExprNode`.
`SourcePos(offset, line, column)` uses a zero-based character offset and
one-based source line/column; `unknown_position()` is `(0, 0, 0)`.
`expression_position` and `expression_node` are also available as `.position`
and `.node` properties. Parsed nodes retain their actual positions. Original
expression equality and ordering ignore positions and compare tree structure;
Python `Expr` comparisons call those original instances.

Use the raw node constructors `Literal(rational)`, `Variable(name)`,
`Constant(named_constant)`, `Unary(operator, child)`,
`Binary(operator, left, right)`, `Call(name, arguments)`,
`Let(name, value, body)`. The smart expression builders `literal`, `variable`,
`constant`, `unary`, `binary`, `call`, `let_in` use unknown positions. Builders
remain unevaluated and do not add validation that the original builders lack.

An `ExprNode`'s `.fields` property exposes its complete tagged payload. In C,
`hmath_expression_node_fields` returns the same tuple of shared Values:

| Code | Constructor | Remaining fields |
| --- | --- | --- |
| 0 | `Literal` | exact Rational |
| 1 | `Variable` | original name |
| 2 | `Constant` | `NamedConstant` |
| 3 | `Unary` | `UnaryOp`, child `Expr` |
| 4 | `Binary` | `BinaryOp`, left `Expr`, right `Expr` |
| 5 | `Call` | name, list of argument `Expr` |
| 6 | `Let` | name, value `Expr`, body `Expr` |

The operators are `Negate`; `Add`, `Subtract`, `Multiply`, `Divide`, `Power`;
and named constants `Pi`, `Euler`, `Tau`. Their type enums are `UnaryOp`,
`BinaryOp`, `NamedConstant`. Child expressions returned by inspection are
independently owned native handles, retaining their complete positions and
structure. Tree equality is separate from `symbolic.simplify_relation` and
other mathematical transformations.

## Values, registries and resource budgets

`ExactRational` and `Float64` select the original `Precision`. Results retain
original tags: `ExactValue(value)` contains a `fractions.Fraction`, while
`FloatValue(value)` contains a binary64 float. Exact arithmetic never passes
through Double. The expression language has no FP32 evaluation mode. Exact mode
rejects transcendental functions and irrational square roots with the original
errors instead of rounding them. Finite-value and domain checks remain inside
the original evaluator.

`Bindings` accepts a dictionary or a list of `(name, Value)` pairs; later
duplicate names replace earlier ones, matching `Map.fromList`. Lexical `let` is
strict and scoped. Unreferenced external values are not mathematically checked
by the evaluator. `type_check_expression` returns the original precision mode;
it is separate from value-dependent evaluation.

`empty_registry` and `default_registry` create immutable closed registries.
`register_function(name, builtin, registry)` adds an alias for a permitted
`Builtin`; it never accepts host code. `allowed_functions` returns the original
sorted names. Builtins are `Sin`, `Cos`, `Tan`, `Exp`, `Log`, `Sqrt`, `Abs`,
`Signum`, `Floor`, `Ceiling`, `Min`, `Max`, `Asin`, `Acos`, `Atan`, `Sinh`, `Cosh`,
`Tanh`. The registry is checked again when a compiled expression is evaluated.

`Limits` and `default_limits()` contain the original independent budgets:

| Field | Default | Original accepted range |
| --- | --- | --- |
| `maximum_steps` | 100000 | 1..10000000 |
| `maximum_depth` | 128 | 1..256 |
| `maximum_nodes` | 20000 | 1..100000 |
| `maximum_input_chars` | 100000 | 1..1000000 |
| `maximum_integer_bits` | 1024 | 2..8192 |
| `maximum_cache_entries` | 64 | 0..1024 |

These are expression work/storage limits, rather than byte or wall-clock quotas.
`validate_limits` checks hard bounds; `validate_expression` checks the supplied
AST. Pure builders remain caller controlled. Compilation/CSE and evaluation
have separate fresh budgets. `cached_expression(limits, source, cache)` returns
`(compiled, next_cache)` without changing its input cache; cache hits retain
original validation and aggregate-storage checks. `compiled_node_count` and
`cache_size` expose the original counts.

`serialize_expression` preserves original expression structure using its safe
constructor vocabulary. The source serialization intentionally omits positions;
`deserialize_expression` rebuilds nodes with generated unknown positions.
`expression_hash` is the original 64-bit FNV-1a over serialization Unicode code
points, not UTF-8 bytes. `pretty_expression`, `format_scientific`, `format_radix`,
`to_la_te_x` and `to_math_ml` call original renderers with original limits and
escaping rules.

## Symbolic operations and explicit conditions

`assumptions([(name, properties), ...])` validates and merges original variable
facts, rejecting contradictions. `no_assumptions()` supplies none.
`SymbolicOptions(limits, assumptions)` retains both inputs;
`default_symbolic_options()` returns original defaults. The properties are
`Real`, `NonZero`, `Positive`, `NonNegative`, `Integral`, `Negative`,
`NonPositive`. `proves(assumptions, property, expression)` is conservative:
`False` means unproved, rather than disproved.

Normalization, simplification, expansion, collection, factoring, differentiation,
integration, limits and series call their original algorithms. They preserve
partial-function domains and do not discard unproved cancellation or branch
conditions. Unsupported operations return `ExprError(Unsupported, ...)`; there
is no hidden numerical substitute. The original implementation is a bounded
real reference CAS. For example, series orders remain 0..20, formal Rational
jets at most 64 coefficients, symbolic matrices 1..8 by 1..8, cofactor
determinants at most 6 by 6, and symbolic eigenvalues only order 1 or 2.

`Any`, `Exactly`, `UnaryPattern`, `BinaryPattern`, `CallPattern` construct native
patterns. `.fields` (C `hmath_symbolic_pattern_fields`) returns constructor codes
0..4 in that order and each constructor's full payload. Repeated wildcard names
retain original structural matching. `RewriteRule(pattern, replacement,
requirements)` applies a caller assertion at the root with its original property
requirements. `substitute` preserves capture avoidance and lexical scope.

`to_polynomial` and `from_polynomial` share exact Rational `Polynomial` objects
with [the polynomial API](polynomial.md). Formal series share its exact Rational
`PowerSeries` owners. No coefficient string approximation or FP64 conversion is
introduced. Exact roots include original multiplicities and residual expression;
numerical roots retain original complex binary64 results and failure conditions.

The returned records/sums retain every source field:

| Type | Payload |
| --- | --- |
| `PolynomialFactorization` | `leading`: exact Rational; `terms`: `(Expr, multiplicity)` pairs |
| `Series` | exact `center`, integer `minimum_power`, ordered `terms` expressions |
| `LimitResult` | `.name`: `FiniteLimit`, `PositiveInfinity`, `NegativeInfinity`, `DoesNotExist`; `.arguments` contains the Rational only for `FiniteLimit` |
| `Relation` | `operator`, `left`, `right`; operators `Equal`, `NotEqual`, `Less`, `LessEqual`, `Greater`, `GreaterEqual` |
| `RelationResult` | `Truth(bool)` or `Unresolved(Relation)`, retained in `.name`/`.arguments` |
| `LinearSolution` | `Inconsistent` or `ParametricSolution(bindings, free_variables)`; bindings retain original names and Expr values |
| `Guarded` | `value`, `conditions`: complete `(Expr, Property)` premises |

`symbolic_eigenvalues` returns `Guarded` expressions with every required condition
intact. `guarded_value` and `required_conditions` expose original fields. The
polymorphic `Guarded` record constructor/selectors accept the shared Value
transport's representable payloads; the eigenvalue specialization is the
original `[Expr]`. Native constructors, selectors and transformations remain
available even when Python uses immutable dataclasses or tagged records to
represent those source values.

## Positioned expression errors

Expression failures use **`HMATH_EXPRESSION_ERROR` (status 12)**, separate from
`MathError`. Python raises `HMathError` whose `.expression_error` holds the
original `ExprError(kind, position, message)`; `.math_error` is `None`.
The kind is one of `SyntaxError`, `UnknownName`, `TypeMismatch`, `DomainFailure`,
`NonFinite`, `StepLimit`, `DepthLimit`, `MemoryLimit`, `InvalidLimits`,
`Unsupported`. Original zero-based offsets, one-based line/column and full
messages are retained.

C `hmath_last_expression_error(out)` queries a `hmath_expression_error` record:
`kind` is the original 0..9 kind; `source_offset`, `source_line`,
`source_column` are `ptrdiff_t`; `message`/`message_length` are a complete
library-owned UTF-8 payload (surrogatepass/WTF-8 for isolated Haskell surrogates,
with embedded NUL supported by the explicit length). Copy the message before
another checked operation on that thread. Queries do not consume or clear the
error; successful checked operations and other failures clear it. Error storage
is thread local and released in C without runtime callbacks. Source error-record
constructors/selectors also preserve full String payloads through shared Values.

## C representation and ownership

All wrappers use `context` first, original source arguments in order, and
`hmath_value **out` last. Successful outputs own one reference; errors leave
output pointer storage untouched. Include [the shared Value API](values.md)
to create typed scalars, text, lists and tuples and inspect structural results.
Enums use `Index` values. Integer fields fit original Haskell `Int`; Word64
hashes and Rational coefficients never pass through floating-point intermediates.

| Native Value kind | Original object |
| --- | --- |
| 80 | `Expr` |
| 81 | `ExprNode` |
| 82 | `Registry` |
| 83 | `Compiled` |
| 84 | `ExpressionCache` |
| 85 | `Pattern` |
| 86 | `Assumptions` |
| 87 | `SymbolicMatrix` |

Plain records are tuples in original constructor order. `SourcePos` is three
Int indices; `Limits` is six; `ExprError` is `(kind, position, text)`.
`ExactValue` and `FloatValue` are `(tag, scalar)`, with tags 0 and 1 respectively.
`SymbolicOptions`, `PolynomialFactorization`, `RewriteRule`, `Series`, `Relation`,
`Guarded` follow their field order above. `LimitResult` is `(0, Rational)` or a
one-element tuple `(1,)`, `(2,)`, `(3,)` for positive infinity, negative infinity,
does-not-exist. `RelationResult` is `(0, Bool)` or `(1, Relation)`;
`LinearSolution` is `(0,)` or `(1, bindings, free_variables)`. Native constructor
wrappers are provided for every case, so callers need not reproduce these
structural layouts manually. Lists and tuples remain distinct.

Handles are immutable and can be shared while each user owns a live reference.
C releases them with `hmath_value_release`; Python uses `.close()`/context
managers. Records may contain handles: release every returned child expression,
pattern, assumptions or matrix reference, including those in lists or guarded
results. Python destructors are a fallback. A live handle reserves the Haskell
runtime, so final shutdown returns `HMATH_BUSY` until every reference is released. Releasing
the final reference must not race a call using that reference. There are no
asynchronous callbacks or dynamically registered host functions in this domain.

## Named API mapping

The tables give exact argument order, result representation and C wrapper.
The original [Expression reference](haskell/HMath-Expression.md) and
[Symbolic reference](haskell/HMath-Symbolic.md) document formulas and original
validation conditions for each function.

### Expression

| Python callable or constructor | Result | C wrapper |
| --- | --- | --- |
| `SourcePos(offset, line, column)` | `SourcePos` | `hmath_expression_source_pos_create` |
| `unknown_position()` | `SourcePos` | `hmath_expression_unknown_position` |
| `source_offset(position)` | `Int` | `hmath_expression_source_offset` |
| `source_line(position)` | `Int` | `hmath_expression_source_line` |
| `source_column(position)` | `Int` | `hmath_expression_source_column` |
| `Negate` | `UnaryOp` | `hmath_expression_negate_create` |
| `Add` | `BinaryOp` | `hmath_expression_add_create` |
| `Subtract` | `BinaryOp` | `hmath_expression_subtract_create` |
| `Multiply` | `BinaryOp` | `hmath_expression_multiply_create` |
| `Divide` | `BinaryOp` | `hmath_expression_divide_create` |
| `Power` | `BinaryOp` | `hmath_expression_power_create` |
| `Pi` | `NamedConstant` | `hmath_expression_pi_create` |
| `Euler` | `NamedConstant` | `hmath_expression_euler_create` |
| `Tau` | `NamedConstant` | `hmath_expression_tau_create` |
| `ExactRational` | `Precision` | `hmath_expression_exact_rational_create` |
| `Float64` | `Precision` | `hmath_expression_float64_create` |
| `SyntaxError` | `ErrorKind` | `hmath_expression_syntax_error_create` |
| `UnknownName` | `ErrorKind` | `hmath_expression_unknown_name_create` |
| `TypeMismatch` | `ErrorKind` | `hmath_expression_type_mismatch_create` |
| `DomainFailure` | `ErrorKind` | `hmath_expression_domain_failure_create` |
| `NonFinite` | `ErrorKind` | `hmath_expression_non_finite_create` |
| `StepLimit` | `ErrorKind` | `hmath_expression_step_limit_create` |
| `DepthLimit` | `ErrorKind` | `hmath_expression_depth_limit_create` |
| `MemoryLimit` | `ErrorKind` | `hmath_expression_memory_limit_create` |
| `InvalidLimits` | `ErrorKind` | `hmath_expression_invalid_limits_create` |
| `Unsupported` | `ErrorKind` | `hmath_expression_unsupported_create` |
| `Sin` | `Builtin` | `hmath_expression_sin_create` |
| `Cos` | `Builtin` | `hmath_expression_cos_create` |
| `Tan` | `Builtin` | `hmath_expression_tan_create` |
| `Exp` | `Builtin` | `hmath_expression_exp_create` |
| `Log` | `Builtin` | `hmath_expression_log_create` |
| `Sqrt` | `Builtin` | `hmath_expression_sqrt_create` |
| `Abs` | `Builtin` | `hmath_expression_abs_create` |
| `Signum` | `Builtin` | `hmath_expression_signum_create` |
| `Floor` | `Builtin` | `hmath_expression_floor_create` |
| `Ceiling` | `Builtin` | `hmath_expression_ceiling_create` |
| `Min` | `Builtin` | `hmath_expression_min_create` |
| `Max` | `Builtin` | `hmath_expression_max_create` |
| `Asin` | `Builtin` | `hmath_expression_asin_create` |
| `Acos` | `Builtin` | `hmath_expression_acos_create` |
| `Atan` | `Builtin` | `hmath_expression_atan_create` |
| `Sinh` | `Builtin` | `hmath_expression_sinh_create` |
| `Cosh` | `Builtin` | `hmath_expression_cosh_create` |
| `Tanh` | `Builtin` | `hmath_expression_tanh_create` |
| `Expr(position, node)` | `Expr` | `hmath_expression_expr_create` |
| `expression_position(expression)` | `SourcePos` | `hmath_expression_expression_position` |
| `expression_node(expression)` | `ExprNode` | `hmath_expression_expression_node` |
| `Literal(value)` | `ExprNode` | `hmath_expression_literal_create` |
| `Variable(name)` | `ExprNode` | `hmath_expression_variable_create` |
| `Constant(constant)` | `ExprNode` | `hmath_expression_constant_create` |
| `Unary(operator, child)` | `ExprNode` | `hmath_expression_unary_create` |
| `Binary(operator, left, right)` | `ExprNode` | `hmath_expression_binary_create` |
| `Call(name, arguments)` | `ExprNode` | `hmath_expression_call_create` |
| `Let(name, value, body)` | `ExprNode` | `hmath_expression_let_create` |
| `literal(value)` | `Expr` | `hmath_expression_literal` |
| `variable(name)` | `Expr` | `hmath_expression_variable` |
| `constant(constant)` | `Expr` | `hmath_expression_constant` |
| `unary(operator, child)` | `Expr` | `hmath_expression_unary` |
| `binary(operator, left, right)` | `Expr` | `hmath_expression_binary` |
| `call(name, arguments)` | `Expr` | `hmath_expression_call` |
| `let_in(name, value, body)` | `Expr` | `hmath_expression_let_in` |
| `Limits(maximum_steps, maximum_depth, maximum_nodes, maximum_input_chars, maximum_integer_bits, maximum_cache_entries)` | `Limits` | `hmath_expression_limits_create` |
| `default_limits()` | `Limits` | `hmath_expression_default_limits` |
| `maximum_steps(limits)` | `Int` | `hmath_expression_maximum_steps` |
| `maximum_depth(limits)` | `Int` | `hmath_expression_maximum_depth` |
| `maximum_nodes(limits)` | `Int` | `hmath_expression_maximum_nodes` |
| `maximum_input_chars(limits)` | `Int` | `hmath_expression_maximum_input_chars` |
| `maximum_integer_bits(limits)` | `Int` | `hmath_expression_maximum_integer_bits` |
| `maximum_cache_entries(limits)` | `Int` | `hmath_expression_maximum_cache_entries` |
| `ExprError(kind, position, message)` | `ExprError` | `hmath_expression_expr_error_create` |
| `error_kind(error)` | `ErrorKind` | `hmath_expression_error_kind_get` |
| `error_position(error)` | `SourcePos` | `hmath_expression_error_position` |
| `error_message(error)` | `String` | `hmath_expression_error_message` |
| `validate_limits(limits)` | `Unit` | `hmath_expression_validate_limits` |
| `validate_expression(limits, expression)` | `Unit` | `hmath_expression_validate_expression` |
| `parse_expression(limits, source)` | `Expr` | `hmath_expression_parse_expression` |
| `pretty_expression(expression)` | `String` | `hmath_expression_pretty_expression` |
| `free_variables(expression)` | `[String]` | `hmath_expression_free_variables` |
| `ExactValue(value)` | `ExpressionValue` | `hmath_expression_exact_value_create` |
| `FloatValue(value)` | `ExpressionValue` | `hmath_expression_float_value_create` |
| `default_registry()` | `Registry` | `hmath_expression_default_registry` |
| `empty_registry()` | `Registry` | `hmath_expression_empty_registry` |
| `register_function(name, builtin, registry)` | `Registry` | `hmath_expression_register_function` |
| `allowed_functions(registry)` | `[String]` | `hmath_expression_allowed_functions` |
| `type_check_expression(limits, precision, registry, bindings, expression)` | `Precision` | `hmath_expression_type_check_expression` |
| `evaluate_expression(limits, precision, registry, bindings, expression)` | `ExpressionValue` | `hmath_expression_evaluate_expression` |
| `evaluate_text(limits, precision, registry, bindings, source)` | `ExpressionValue` | `hmath_expression_evaluate_text` |
| `evaluate_compiled(limits, precision, registry, bindings, compiled)` | `ExpressionValue` | `hmath_expression_evaluate_compiled` |
| `compile_expression(limits, expression)` | `Compiled` | `hmath_expression_compile_expression` |
| `compiled_node_count(compiled)` | `Int` | `hmath_expression_compiled_node_count` |
| `optimize_expression(limits, precision, expression)` | `Expr` | `hmath_expression_optimize_expression` |
| `empty_expression_cache()` | `ExpressionCache` | `hmath_expression_empty_expression_cache` |
| `cache_size(cache)` | `Int` | `hmath_expression_cache_size` |
| `cached_expression(limits, source, cache)` | `(Compiled,ExpressionCache)` | `hmath_expression_cached_expression` |
| `format_scientific(digits, value)` | `String` | `hmath_expression_format_scientific` |
| `format_radix(radix, value)` | `String` | `hmath_expression_format_radix` |
| `serialize_expression(limits, expression)` | `String` | `hmath_expression_serialize_expression` |
| `deserialize_expression(limits, serialized)` | `Expr` | `hmath_expression_deserialize_expression` |
| `expression_hash(limits, expression)` | `Word64` | `hmath_expression_expression_hash` |

### Symbolic

| Python callable or constructor | Result | C wrapper |
| --- | --- | --- |
| `Real` | `Property` | `hmath_symbolic_real_create` |
| `NonZero` | `Property` | `hmath_symbolic_non_zero_create` |
| `Positive` | `Property` | `hmath_symbolic_positive_create` |
| `NonNegative` | `Property` | `hmath_symbolic_non_negative_create` |
| `Integral` | `Property` | `hmath_symbolic_integral_create` |
| `Negative` | `Property` | `hmath_symbolic_negative_create` |
| `NonPositive` | `Property` | `hmath_symbolic_non_positive_create` |
| `FromLeft` | `Direction` | `hmath_symbolic_from_left_create` |
| `FromRight` | `Direction` | `hmath_symbolic_from_right_create` |
| `TwoSided` | `Direction` | `hmath_symbolic_two_sided_create` |
| `Equal` | `RelationOp` | `hmath_symbolic_equal_create` |
| `NotEqual` | `RelationOp` | `hmath_symbolic_not_equal_create` |
| `Less` | `RelationOp` | `hmath_symbolic_less_create` |
| `LessEqual` | `RelationOp` | `hmath_symbolic_less_equal_create` |
| `Greater` | `RelationOp` | `hmath_symbolic_greater_create` |
| `GreaterEqual` | `RelationOp` | `hmath_symbolic_greater_equal_create` |
| `assumptions(entries)` | `Assumptions` | `hmath_symbolic_assumptions` |
| `no_assumptions()` | `Assumptions` | `hmath_symbolic_no_assumptions` |
| `proves(assumptions, property, expression)` | `Bool` | `hmath_symbolic_proves` |
| `SymbolicOptions(limits, assumptions)` | `SymbolicOptions` | `hmath_symbolic_symbolic_options_create` |
| `default_symbolic_options()` | `SymbolicOptions` | `hmath_symbolic_default_symbolic_options` |
| `symbolic_limits(options)` | `Limits` | `hmath_symbolic_symbolic_limits` |
| `symbolic_assumptions(options)` | `Assumptions` | `hmath_symbolic_symbolic_assumptions` |
| `normalize(options, expression)` | `Expr` | `hmath_symbolic_normalize` |
| `simplify(options, expression)` | `Expr` | `hmath_symbolic_simplify` |
| `expand(options, expression)` | `Expr` | `hmath_symbolic_expand` |
| `collect_terms(options, expression)` | `Expr` | `hmath_symbolic_collect_terms` |
| `trigonometric_simplify(options, expression)` | `Expr` | `hmath_symbolic_trigonometric_simplify` |
| `logarithmic_simplify(options, expression)` | `Expr` | `hmath_symbolic_logarithmic_simplify` |
| `factor_polynomial(options, variable, expression)` | `PolynomialFactorization` | `hmath_symbolic_factor_polynomial` |
| `rational_simplify(options, variable, expression)` | `Expr` | `hmath_symbolic_rational_simplify` |
| `differentiate(options, variable, expression)` | `Expr` | `hmath_symbolic_differentiate` |
| `integrate_basic(options, variable, expression)` | `Expr` | `hmath_symbolic_integrate_basic` |
| `to_polynomial(options, variable, expression)` | `Polynomial` | `hmath_symbolic_to_polynomial` |
| `exact_polynomial_roots(options, variable, expression)` | `([(Rational,Int)],Expr)` | `hmath_symbolic_exact_polynomial_roots` |
| `numerical_polynomial_roots(options, variable, expression)` | `[Complex]` | `hmath_symbolic_numerical_polynomial_roots` |
| `PolynomialFactorization(leading, terms)` | `PolynomialFactorization` | `hmath_symbolic_polynomial_factorization_create` |
| `factor_leading(factorization)` | `Rational` | `hmath_symbolic_factor_leading` |
| `factor_terms(factorization)` | `[(Expr,Int)]` | `hmath_symbolic_factor_terms` |
| `substitute(limits, bindings, expression)` | `Expr` | `hmath_symbolic_substitute` |
| `Any(name)` | `Pattern` | `hmath_symbolic_any_create` |
| `Exactly(expression)` | `Pattern` | `hmath_symbolic_exactly_create` |
| `UnaryPattern(operator, child)` | `Pattern` | `hmath_symbolic_unary_pattern_create` |
| `BinaryPattern(operator, left, right)` | `Pattern` | `hmath_symbolic_binary_pattern_create` |
| `CallPattern(name, arguments)` | `Pattern` | `hmath_symbolic_call_pattern_create` |
| `match_pattern(limits, pattern, expression)` | `Maybe[(String,Expr)]` | `hmath_symbolic_match_pattern` |
| `RewriteRule(pattern, replacement, requirements)` | `RewriteRule` | `hmath_symbolic_rewrite_rule_create` |
| `rewrite_pattern(rule)` | `Pattern` | `hmath_symbolic_rewrite_pattern` |
| `rewrite_replacement(rule)` | `Expr` | `hmath_symbolic_rewrite_replacement` |
| `rewrite_requirements(rule)` | `[(String,Property)]` | `hmath_symbolic_rewrite_requirements` |
| `apply_rewrite(options, rule, expression)` | `Expr` | `hmath_symbolic_apply_rewrite` |
| `gradient(options, variables, expression)` | `[Expr]` | `hmath_symbolic_gradient` |
| `hessian(options, variables, expression)` | `[[Expr]]` | `hmath_symbolic_hessian` |
| `jacobian(options, variables, expressions)` | `[[Expr]]` | `hmath_symbolic_jacobian` |
| `integrate_by_parts(options, variable, u, dv)` | `Expr` | `hmath_symbolic_integrate_by_parts` |
| `integrate_substitution(options, variable, temporary, inner, outer, integrand)` | `Expr` | `hmath_symbolic_integrate_substitution` |
| `integrate_rational(options, variable, numerator, denominator)` | `Expr` | `hmath_symbolic_integrate_rational` |
| `FiniteLimit(value)` | `LimitResult` | `hmath_symbolic_finite_limit_create` |
| `PositiveInfinity` | `LimitResult` | `hmath_symbolic_positive_infinity_create` |
| `NegativeInfinity` | `LimitResult` | `hmath_symbolic_negative_infinity_create` |
| `DoesNotExist` | `LimitResult` | `hmath_symbolic_does_not_exist_create` |
| `symbolic_limit(options, variable, center, direction, expression)` | `LimitResult` | `hmath_symbolic_symbolic_limit` |
| `Series(center, minimum_power, terms)` | `Series` | `hmath_symbolic_series_create` |
| `series_center(series)` | `Rational` | `hmath_symbolic_series_center` |
| `series_minimum_power(series)` | `Int` | `hmath_symbolic_series_minimum_power` |
| `series_terms(series)` | `[Expr]` | `hmath_symbolic_series_terms` |
| `taylor_series(options, variable, center, order, expression)` | `Series` | `hmath_symbolic_taylor_series` |
| `laurent_series(options, variable, center, order, expression)` | `Series` | `hmath_symbolic_laurent_series` |
| `maclaurin_series(options, variable, order, expression)` | `Series` | `hmath_symbolic_maclaurin_series` |
| `formal_power_series(options, coefficients)` | `PowerSeries` | `hmath_symbolic_formal_power_series` |
| `multiply_formal_series(options, left, right)` | `PowerSeries` | `hmath_symbolic_multiply_formal_series` |
| `reciprocal_formal_series(options, series)` | `PowerSeries` | `hmath_symbolic_reciprocal_formal_series` |
| `from_polynomial(variable, polynomial)` | `Expr` | `hmath_symbolic_from_polynomial` |
| `Relation(operator, left, right)` | `Relation` | `hmath_symbolic_relation_create` |
| `Truth(value)` | `RelationResult` | `hmath_symbolic_truth_create` |
| `Unresolved(relation)` | `RelationResult` | `hmath_symbolic_unresolved_create` |
| `simplify_relation(options, relation)` | `RelationResult` | `hmath_symbolic_simplify_relation` |
| `solve_linear_inequality(options, variable, relation)` | `RelationResult` | `hmath_symbolic_solve_linear_inequality` |
| `Inconsistent` | `LinearSolution` | `hmath_symbolic_inconsistent_create` |
| `ParametricSolution(bindings, free_variables)` | `LinearSolution` | `hmath_symbolic_parametric_solution_create` |
| `solve_linear_equations(options, variables, equations)` | `LinearSolution` | `hmath_symbolic_solve_linear_equations` |
| `symbolic_matrix(options, rows)` | `SymbolicMatrix` | `hmath_symbolic_symbolic_matrix` |
| `matrix_expressions(matrix)` | `[[Expr]]` | `hmath_symbolic_matrix_expressions` |
| `matrix_add(options, left, right)` | `SymbolicMatrix` | `hmath_symbolic_matrix_add` |
| `matrix_multiply(options, left, right)` | `SymbolicMatrix` | `hmath_symbolic_matrix_multiply` |
| `symbolic_determinant(options, matrix)` | `Expr` | `hmath_symbolic_symbolic_determinant` |
| `Guarded(value, conditions)` | `Guarded` | `hmath_symbolic_guarded_create` |
| `guarded_value(guarded)` | `Generic` | `hmath_symbolic_guarded_value` |
| `required_conditions(guarded)` | `[(Expr,Property)]` | `hmath_symbolic_required_conditions` |
| `symbolic_eigenvalues(options, matrix)` | `Guarded[Expr]` | `hmath_symbolic_symbolic_eigenvalues` |
| `numerical_substitution(options, precision, bindings, expression)` | `ExpressionValue` | `hmath_symbolic_numerical_substitution` |
| `to_la_te_x(limits, expression)` | `String` | `hmath_symbolic_to_la_te_x` |
| `to_math_ml(limits, expression)` | `String` | `hmath_symbolic_to_math_ml` |
