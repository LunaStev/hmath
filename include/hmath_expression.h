/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_EXPRESSION_H
#define HMATH_EXPRESSION_H
#include "hmath_expression_error.h"
#include "hmath_value.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Original positioned ASTs/compiled DAGs/cache/registries/patterns/assumptions
 * and symbolic matrices are immutable native Values (kind80..87). Records and
 * sum payloads use lossless structural tuples; enums are Index values. Exact
 * Rational and Double arithmetic remains selected explicitly by Precision.
 * Every named wrapper has ctx first, original arguments in source order and
 * owned Value** out last. Inputs borrowed; output untouched on failure. */
HMATH_API hmath_status hmath_expression_node_fields(hmath_context *,const hmath_value *,hmath_value **);
HMATH_API hmath_status hmath_symbolic_pattern_fields(hmath_context *,const hmath_value *,hmath_value **);
HMATH_API hmath_status hmath_expression_compare(hmath_context *,const hmath_value *,const hmath_value *,hmath_value **);
HMATH_API hmath_status hmath_expression_node_compare(hmath_context *,const hmath_value *,const hmath_value *,hmath_value **);
HMATH_API hmath_status hmath_symbolic_pattern_equal(hmath_context *,const hmath_value *,const hmath_value *,hmath_value **);
/* BEGIN GENERATED */
/* HMath.Expression.SourcePos -> SourcePos. */
HMATH_API hmath_status hmath_expression_source_pos_create(hmath_context *context, const hmath_value *offset, const hmath_value *line, const hmath_value *column, hmath_value **out);

/* HMath.Expression.unknownPosition -> SourcePos. */
HMATH_API hmath_status hmath_expression_unknown_position(hmath_context *context, hmath_value **out);

/* HMath.Expression.sourceOffset -> Int. */
HMATH_API hmath_status hmath_expression_source_offset(hmath_context *context, const hmath_value *position, hmath_value **out);

/* HMath.Expression.sourceLine -> Int. */
HMATH_API hmath_status hmath_expression_source_line(hmath_context *context, const hmath_value *position, hmath_value **out);

/* HMath.Expression.sourceColumn -> Int. */
HMATH_API hmath_status hmath_expression_source_column(hmath_context *context, const hmath_value *position, hmath_value **out);

/* HMath.Expression.Negate -> UnaryOp. */
HMATH_API hmath_status hmath_expression_negate_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Add -> BinaryOp. */
HMATH_API hmath_status hmath_expression_add_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Subtract -> BinaryOp. */
HMATH_API hmath_status hmath_expression_subtract_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Multiply -> BinaryOp. */
HMATH_API hmath_status hmath_expression_multiply_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Divide -> BinaryOp. */
HMATH_API hmath_status hmath_expression_divide_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Power -> BinaryOp. */
HMATH_API hmath_status hmath_expression_power_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Pi -> NamedConstant. */
HMATH_API hmath_status hmath_expression_pi_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Euler -> NamedConstant. */
HMATH_API hmath_status hmath_expression_euler_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Tau -> NamedConstant. */
HMATH_API hmath_status hmath_expression_tau_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.ExactRational -> Precision. */
HMATH_API hmath_status hmath_expression_exact_rational_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Float64 -> Precision. */
HMATH_API hmath_status hmath_expression_float64_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.SyntaxError -> ErrorKind. */
HMATH_API hmath_status hmath_expression_syntax_error_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.UnknownName -> ErrorKind. */
HMATH_API hmath_status hmath_expression_unknown_name_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.TypeMismatch -> ErrorKind. */
HMATH_API hmath_status hmath_expression_type_mismatch_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.DomainFailure -> ErrorKind. */
HMATH_API hmath_status hmath_expression_domain_failure_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.NonFinite -> ErrorKind. */
HMATH_API hmath_status hmath_expression_non_finite_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.StepLimit -> ErrorKind. */
HMATH_API hmath_status hmath_expression_step_limit_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.DepthLimit -> ErrorKind. */
HMATH_API hmath_status hmath_expression_depth_limit_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.MemoryLimit -> ErrorKind. */
HMATH_API hmath_status hmath_expression_memory_limit_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.InvalidLimits -> ErrorKind. */
HMATH_API hmath_status hmath_expression_invalid_limits_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Unsupported -> ErrorKind. */
HMATH_API hmath_status hmath_expression_unsupported_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Sin -> Builtin. */
HMATH_API hmath_status hmath_expression_sin_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Cos -> Builtin. */
HMATH_API hmath_status hmath_expression_cos_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Tan -> Builtin. */
HMATH_API hmath_status hmath_expression_tan_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Exp -> Builtin. */
HMATH_API hmath_status hmath_expression_exp_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Log -> Builtin. */
HMATH_API hmath_status hmath_expression_log_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Sqrt -> Builtin. */
HMATH_API hmath_status hmath_expression_sqrt_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Abs -> Builtin. */
HMATH_API hmath_status hmath_expression_abs_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Signum -> Builtin. */
HMATH_API hmath_status hmath_expression_signum_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Floor -> Builtin. */
HMATH_API hmath_status hmath_expression_floor_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Ceiling -> Builtin. */
HMATH_API hmath_status hmath_expression_ceiling_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Min -> Builtin. */
HMATH_API hmath_status hmath_expression_min_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Max -> Builtin. */
HMATH_API hmath_status hmath_expression_max_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Asin -> Builtin. */
HMATH_API hmath_status hmath_expression_asin_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Acos -> Builtin. */
HMATH_API hmath_status hmath_expression_acos_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Atan -> Builtin. */
HMATH_API hmath_status hmath_expression_atan_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Sinh -> Builtin. */
HMATH_API hmath_status hmath_expression_sinh_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Cosh -> Builtin. */
HMATH_API hmath_status hmath_expression_cosh_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Tanh -> Builtin. */
HMATH_API hmath_status hmath_expression_tanh_create(hmath_context *context, hmath_value **out);

/* HMath.Expression.Expr -> Expr. */
HMATH_API hmath_status hmath_expression_expr_create(hmath_context *context, const hmath_value *position, const hmath_value *node, hmath_value **out);

/* HMath.Expression.expressionPosition -> SourcePos. */
HMATH_API hmath_status hmath_expression_expression_position(hmath_context *context, const hmath_value *expression, hmath_value **out);

/* HMath.Expression.expressionNode -> ExprNode. */
HMATH_API hmath_status hmath_expression_expression_node(hmath_context *context, const hmath_value *expression, hmath_value **out);

/* HMath.Expression.Literal -> ExprNode. */
HMATH_API hmath_status hmath_expression_literal_create(hmath_context *context, const hmath_value *value, hmath_value **out);

/* HMath.Expression.Variable -> ExprNode. */
HMATH_API hmath_status hmath_expression_variable_create(hmath_context *context, const hmath_value *name, hmath_value **out);

/* HMath.Expression.Constant -> ExprNode. */
HMATH_API hmath_status hmath_expression_constant_create(hmath_context *context, const hmath_value *constant, hmath_value **out);

/* HMath.Expression.Unary -> ExprNode. */
HMATH_API hmath_status hmath_expression_unary_create(hmath_context *context, const hmath_value *operator_, const hmath_value *child, hmath_value **out);

/* HMath.Expression.Binary -> ExprNode. */
HMATH_API hmath_status hmath_expression_binary_create(hmath_context *context, const hmath_value *operator_, const hmath_value *left, const hmath_value *right, hmath_value **out);

/* HMath.Expression.Call -> ExprNode. */
HMATH_API hmath_status hmath_expression_call_create(hmath_context *context, const hmath_value *name, const hmath_value *arguments, hmath_value **out);

/* HMath.Expression.Let -> ExprNode. */
HMATH_API hmath_status hmath_expression_let_create(hmath_context *context, const hmath_value *name, const hmath_value *value, const hmath_value *body, hmath_value **out);

/* HMath.Expression.literal -> Expr. */
HMATH_API hmath_status hmath_expression_literal(hmath_context *context, const hmath_value *value, hmath_value **out);

/* HMath.Expression.variable -> Expr. */
HMATH_API hmath_status hmath_expression_variable(hmath_context *context, const hmath_value *name, hmath_value **out);

/* HMath.Expression.constant -> Expr. */
HMATH_API hmath_status hmath_expression_constant(hmath_context *context, const hmath_value *constant, hmath_value **out);

/* HMath.Expression.unary -> Expr. */
HMATH_API hmath_status hmath_expression_unary(hmath_context *context, const hmath_value *operator_, const hmath_value *child, hmath_value **out);

/* HMath.Expression.binary -> Expr. */
HMATH_API hmath_status hmath_expression_binary(hmath_context *context, const hmath_value *operator_, const hmath_value *left, const hmath_value *right, hmath_value **out);

/* HMath.Expression.call -> Expr. */
HMATH_API hmath_status hmath_expression_call(hmath_context *context, const hmath_value *name, const hmath_value *arguments, hmath_value **out);

/* HMath.Expression.letIn -> Expr. */
HMATH_API hmath_status hmath_expression_let_in(hmath_context *context, const hmath_value *name, const hmath_value *value, const hmath_value *body, hmath_value **out);

/* HMath.Expression.Limits -> Limits. */
HMATH_API hmath_status hmath_expression_limits_create(hmath_context *context, const hmath_value *maximum_steps, const hmath_value *maximum_depth, const hmath_value *maximum_nodes, const hmath_value *maximum_input_chars, const hmath_value *maximum_integer_bits, const hmath_value *maximum_cache_entries, hmath_value **out);

/* HMath.Expression.defaultLimits -> Limits. */
HMATH_API hmath_status hmath_expression_default_limits(hmath_context *context, hmath_value **out);

/* HMath.Expression.maximumSteps -> Int. */
HMATH_API hmath_status hmath_expression_maximum_steps(hmath_context *context, const hmath_value *limits, hmath_value **out);

/* HMath.Expression.maximumDepth -> Int. */
HMATH_API hmath_status hmath_expression_maximum_depth(hmath_context *context, const hmath_value *limits, hmath_value **out);

/* HMath.Expression.maximumNodes -> Int. */
HMATH_API hmath_status hmath_expression_maximum_nodes(hmath_context *context, const hmath_value *limits, hmath_value **out);

/* HMath.Expression.maximumInputChars -> Int. */
HMATH_API hmath_status hmath_expression_maximum_input_chars(hmath_context *context, const hmath_value *limits, hmath_value **out);

/* HMath.Expression.maximumIntegerBits -> Int. */
HMATH_API hmath_status hmath_expression_maximum_integer_bits(hmath_context *context, const hmath_value *limits, hmath_value **out);

/* HMath.Expression.maximumCacheEntries -> Int. */
HMATH_API hmath_status hmath_expression_maximum_cache_entries(hmath_context *context, const hmath_value *limits, hmath_value **out);

/* HMath.Expression.ExprError -> ExprError. */
HMATH_API hmath_status hmath_expression_expr_error_create(hmath_context *context, const hmath_value *kind, const hmath_value *position, const hmath_value *message, hmath_value **out);

/* HMath.Expression.errorKind -> ErrorKind. */
HMATH_API hmath_status hmath_expression_error_kind_get(hmath_context *context, const hmath_value *error, hmath_value **out);

/* HMath.Expression.errorPosition -> SourcePos. */
HMATH_API hmath_status hmath_expression_error_position(hmath_context *context, const hmath_value *error, hmath_value **out);

/* HMath.Expression.errorMessage -> String. */
HMATH_API hmath_status hmath_expression_error_message(hmath_context *context, const hmath_value *error, hmath_value **out);

/* HMath.Expression.validateLimits -> Unit. */
HMATH_API hmath_status hmath_expression_validate_limits(hmath_context *context, const hmath_value *limits, hmath_value **out);

/* HMath.Expression.validateExpression -> Unit. */
HMATH_API hmath_status hmath_expression_validate_expression(hmath_context *context, const hmath_value *limits, const hmath_value *expression, hmath_value **out);

/* HMath.Expression.parseExpression -> Expr. */
HMATH_API hmath_status hmath_expression_parse_expression(hmath_context *context, const hmath_value *limits, const hmath_value *source, hmath_value **out);

/* HMath.Expression.prettyExpression -> String. */
HMATH_API hmath_status hmath_expression_pretty_expression(hmath_context *context, const hmath_value *expression, hmath_value **out);

/* HMath.Expression.freeVariables -> [String]. */
HMATH_API hmath_status hmath_expression_free_variables(hmath_context *context, const hmath_value *expression, hmath_value **out);

/* HMath.Expression.ExactValue -> ExpressionValue. */
HMATH_API hmath_status hmath_expression_exact_value_create(hmath_context *context, const hmath_value *value, hmath_value **out);

/* HMath.Expression.FloatValue -> ExpressionValue. */
HMATH_API hmath_status hmath_expression_float_value_create(hmath_context *context, const hmath_value *value, hmath_value **out);

/* HMath.Expression.defaultRegistry -> Registry. */
HMATH_API hmath_status hmath_expression_default_registry(hmath_context *context, hmath_value **out);

/* HMath.Expression.emptyRegistry -> Registry. */
HMATH_API hmath_status hmath_expression_empty_registry(hmath_context *context, hmath_value **out);

/* HMath.Expression.registerFunction -> Registry. */
HMATH_API hmath_status hmath_expression_register_function(hmath_context *context, const hmath_value *name, const hmath_value *builtin, const hmath_value *registry, hmath_value **out);

/* HMath.Expression.allowedFunctions -> [String]. */
HMATH_API hmath_status hmath_expression_allowed_functions(hmath_context *context, const hmath_value *registry, hmath_value **out);

/* HMath.Expression.typeCheckExpression -> Precision. */
HMATH_API hmath_status hmath_expression_type_check_expression(hmath_context *context, const hmath_value *limits, const hmath_value *precision, const hmath_value *registry, const hmath_value *bindings, const hmath_value *expression, hmath_value **out);

/* HMath.Expression.evaluateExpression -> ExpressionValue. */
HMATH_API hmath_status hmath_expression_evaluate_expression(hmath_context *context, const hmath_value *limits, const hmath_value *precision, const hmath_value *registry, const hmath_value *bindings, const hmath_value *expression, hmath_value **out);

/* HMath.Expression.evaluateText -> ExpressionValue. */
HMATH_API hmath_status hmath_expression_evaluate_text(hmath_context *context, const hmath_value *limits, const hmath_value *precision, const hmath_value *registry, const hmath_value *bindings, const hmath_value *source, hmath_value **out);

/* HMath.Expression.evaluateCompiled -> ExpressionValue. */
HMATH_API hmath_status hmath_expression_evaluate_compiled(hmath_context *context, const hmath_value *limits, const hmath_value *precision, const hmath_value *registry, const hmath_value *bindings, const hmath_value *compiled, hmath_value **out);

/* HMath.Expression.compileExpression -> Compiled. */
HMATH_API hmath_status hmath_expression_compile_expression(hmath_context *context, const hmath_value *limits, const hmath_value *expression, hmath_value **out);

/* HMath.Expression.compiledNodeCount -> Int. */
HMATH_API hmath_status hmath_expression_compiled_node_count(hmath_context *context, const hmath_value *compiled, hmath_value **out);

/* HMath.Expression.optimizeExpression -> Expr. */
HMATH_API hmath_status hmath_expression_optimize_expression(hmath_context *context, const hmath_value *limits, const hmath_value *precision, const hmath_value *expression, hmath_value **out);

/* HMath.Expression.emptyExpressionCache -> ExpressionCache. */
HMATH_API hmath_status hmath_expression_empty_expression_cache(hmath_context *context, hmath_value **out);

/* HMath.Expression.cacheSize -> Int. */
HMATH_API hmath_status hmath_expression_cache_size(hmath_context *context, const hmath_value *cache, hmath_value **out);

/* HMath.Expression.cachedExpression -> (Compiled,ExpressionCache). */
HMATH_API hmath_status hmath_expression_cached_expression(hmath_context *context, const hmath_value *limits, const hmath_value *source, const hmath_value *cache, hmath_value **out);

/* HMath.Expression.formatScientific -> String. */
HMATH_API hmath_status hmath_expression_format_scientific(hmath_context *context, const hmath_value *digits, const hmath_value *value, hmath_value **out);

/* HMath.Expression.formatRadix -> String. */
HMATH_API hmath_status hmath_expression_format_radix(hmath_context *context, const hmath_value *radix, const hmath_value *value, hmath_value **out);

/* HMath.Expression.serializeExpression -> String. */
HMATH_API hmath_status hmath_expression_serialize_expression(hmath_context *context, const hmath_value *limits, const hmath_value *expression, hmath_value **out);

/* HMath.Expression.deserializeExpression -> Expr. */
HMATH_API hmath_status hmath_expression_deserialize_expression(hmath_context *context, const hmath_value *limits, const hmath_value *serialized, hmath_value **out);

/* HMath.Expression.expressionHash -> Word64. */
HMATH_API hmath_status hmath_expression_expression_hash(hmath_context *context, const hmath_value *limits, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.Real -> Property. */
HMATH_API hmath_status hmath_symbolic_real_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.NonZero -> Property. */
HMATH_API hmath_status hmath_symbolic_non_zero_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.Positive -> Property. */
HMATH_API hmath_status hmath_symbolic_positive_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.NonNegative -> Property. */
HMATH_API hmath_status hmath_symbolic_non_negative_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.Integral -> Property. */
HMATH_API hmath_status hmath_symbolic_integral_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.Negative -> Property. */
HMATH_API hmath_status hmath_symbolic_negative_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.NonPositive -> Property. */
HMATH_API hmath_status hmath_symbolic_non_positive_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.FromLeft -> Direction. */
HMATH_API hmath_status hmath_symbolic_from_left_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.FromRight -> Direction. */
HMATH_API hmath_status hmath_symbolic_from_right_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.TwoSided -> Direction. */
HMATH_API hmath_status hmath_symbolic_two_sided_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.Equal -> RelationOp. */
HMATH_API hmath_status hmath_symbolic_equal_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.NotEqual -> RelationOp. */
HMATH_API hmath_status hmath_symbolic_not_equal_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.Less -> RelationOp. */
HMATH_API hmath_status hmath_symbolic_less_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.LessEqual -> RelationOp. */
HMATH_API hmath_status hmath_symbolic_less_equal_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.Greater -> RelationOp. */
HMATH_API hmath_status hmath_symbolic_greater_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.GreaterEqual -> RelationOp. */
HMATH_API hmath_status hmath_symbolic_greater_equal_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.assumptions -> Assumptions. */
HMATH_API hmath_status hmath_symbolic_assumptions(hmath_context *context, const hmath_value *entries, hmath_value **out);

/* HMath.Symbolic.noAssumptions -> Assumptions. */
HMATH_API hmath_status hmath_symbolic_no_assumptions(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.proves -> Bool. */
HMATH_API hmath_status hmath_symbolic_proves(hmath_context *context, const hmath_value *assumptions, const hmath_value *property, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.SymbolicOptions -> SymbolicOptions. */
HMATH_API hmath_status hmath_symbolic_symbolic_options_create(hmath_context *context, const hmath_value *limits, const hmath_value *assumptions, hmath_value **out);

/* HMath.Symbolic.defaultSymbolicOptions -> SymbolicOptions. */
HMATH_API hmath_status hmath_symbolic_default_symbolic_options(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.symbolicLimits -> Limits. */
HMATH_API hmath_status hmath_symbolic_symbolic_limits(hmath_context *context, const hmath_value *options, hmath_value **out);

/* HMath.Symbolic.symbolicAssumptions -> Assumptions. */
HMATH_API hmath_status hmath_symbolic_symbolic_assumptions(hmath_context *context, const hmath_value *options, hmath_value **out);

/* HMath.Symbolic.normalize -> Expr. */
HMATH_API hmath_status hmath_symbolic_normalize(hmath_context *context, const hmath_value *options, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.simplify -> Expr. */
HMATH_API hmath_status hmath_symbolic_simplify(hmath_context *context, const hmath_value *options, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.expand -> Expr. */
HMATH_API hmath_status hmath_symbolic_expand(hmath_context *context, const hmath_value *options, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.collectTerms -> Expr. */
HMATH_API hmath_status hmath_symbolic_collect_terms(hmath_context *context, const hmath_value *options, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.trigonometricSimplify -> Expr. */
HMATH_API hmath_status hmath_symbolic_trigonometric_simplify(hmath_context *context, const hmath_value *options, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.logarithmicSimplify -> Expr. */
HMATH_API hmath_status hmath_symbolic_logarithmic_simplify(hmath_context *context, const hmath_value *options, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.factorPolynomial -> PolynomialFactorization. */
HMATH_API hmath_status hmath_symbolic_factor_polynomial(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.rationalSimplify -> Expr. */
HMATH_API hmath_status hmath_symbolic_rational_simplify(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.differentiate -> Expr. */
HMATH_API hmath_status hmath_symbolic_differentiate(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.integrateBasic -> Expr. */
HMATH_API hmath_status hmath_symbolic_integrate_basic(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.toPolynomial -> Polynomial. */
HMATH_API hmath_status hmath_symbolic_to_polynomial(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.exactPolynomialRoots -> ([(Rational,Int)],Expr). */
HMATH_API hmath_status hmath_symbolic_exact_polynomial_roots(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.numericalPolynomialRoots -> [Complex]. */
HMATH_API hmath_status hmath_symbolic_numerical_polynomial_roots(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.PolynomialFactorization -> PolynomialFactorization. */
HMATH_API hmath_status hmath_symbolic_polynomial_factorization_create(hmath_context *context, const hmath_value *leading, const hmath_value *terms, hmath_value **out);

/* HMath.Symbolic.factorLeading -> Rational. */
HMATH_API hmath_status hmath_symbolic_factor_leading(hmath_context *context, const hmath_value *factorization, hmath_value **out);

/* HMath.Symbolic.factorTerms -> [(Expr,Int)]. */
HMATH_API hmath_status hmath_symbolic_factor_terms(hmath_context *context, const hmath_value *factorization, hmath_value **out);

/* HMath.Symbolic.substitute -> Expr. */
HMATH_API hmath_status hmath_symbolic_substitute(hmath_context *context, const hmath_value *limits, const hmath_value *bindings, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.Any -> Pattern. */
HMATH_API hmath_status hmath_symbolic_any_create(hmath_context *context, const hmath_value *name, hmath_value **out);

/* HMath.Symbolic.Exactly -> Pattern. */
HMATH_API hmath_status hmath_symbolic_exactly_create(hmath_context *context, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.UnaryPattern -> Pattern. */
HMATH_API hmath_status hmath_symbolic_unary_pattern_create(hmath_context *context, const hmath_value *operator_, const hmath_value *child, hmath_value **out);

/* HMath.Symbolic.BinaryPattern -> Pattern. */
HMATH_API hmath_status hmath_symbolic_binary_pattern_create(hmath_context *context, const hmath_value *operator_, const hmath_value *left, const hmath_value *right, hmath_value **out);

/* HMath.Symbolic.CallPattern -> Pattern. */
HMATH_API hmath_status hmath_symbolic_call_pattern_create(hmath_context *context, const hmath_value *name, const hmath_value *arguments, hmath_value **out);

/* HMath.Symbolic.matchPattern -> Maybe[(String,Expr)]. */
HMATH_API hmath_status hmath_symbolic_match_pattern(hmath_context *context, const hmath_value *limits, const hmath_value *pattern, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.RewriteRule -> RewriteRule. */
HMATH_API hmath_status hmath_symbolic_rewrite_rule_create(hmath_context *context, const hmath_value *pattern, const hmath_value *replacement, const hmath_value *requirements, hmath_value **out);

/* HMath.Symbolic.rewritePattern -> Pattern. */
HMATH_API hmath_status hmath_symbolic_rewrite_pattern(hmath_context *context, const hmath_value *rule, hmath_value **out);

/* HMath.Symbolic.rewriteReplacement -> Expr. */
HMATH_API hmath_status hmath_symbolic_rewrite_replacement(hmath_context *context, const hmath_value *rule, hmath_value **out);

/* HMath.Symbolic.rewriteRequirements -> [(String,Property)]. */
HMATH_API hmath_status hmath_symbolic_rewrite_requirements(hmath_context *context, const hmath_value *rule, hmath_value **out);

/* HMath.Symbolic.applyRewrite -> Expr. */
HMATH_API hmath_status hmath_symbolic_apply_rewrite(hmath_context *context, const hmath_value *options, const hmath_value *rule, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.gradient -> [Expr]. */
HMATH_API hmath_status hmath_symbolic_gradient(hmath_context *context, const hmath_value *options, const hmath_value *variables, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.hessian -> [[Expr]]. */
HMATH_API hmath_status hmath_symbolic_hessian(hmath_context *context, const hmath_value *options, const hmath_value *variables, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.jacobian -> [[Expr]]. */
HMATH_API hmath_status hmath_symbolic_jacobian(hmath_context *context, const hmath_value *options, const hmath_value *variables, const hmath_value *expressions, hmath_value **out);

/* HMath.Symbolic.integrateByParts -> Expr. */
HMATH_API hmath_status hmath_symbolic_integrate_by_parts(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *u, const hmath_value *dv, hmath_value **out);

/* HMath.Symbolic.integrateSubstitution -> Expr. */
HMATH_API hmath_status hmath_symbolic_integrate_substitution(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *temporary, const hmath_value *inner, const hmath_value *outer, const hmath_value *integrand, hmath_value **out);

/* HMath.Symbolic.integrateRational -> Expr. */
HMATH_API hmath_status hmath_symbolic_integrate_rational(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *numerator, const hmath_value *denominator, hmath_value **out);

/* HMath.Symbolic.FiniteLimit -> LimitResult. */
HMATH_API hmath_status hmath_symbolic_finite_limit_create(hmath_context *context, const hmath_value *value, hmath_value **out);

/* HMath.Symbolic.PositiveInfinity -> LimitResult. */
HMATH_API hmath_status hmath_symbolic_positive_infinity_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.NegativeInfinity -> LimitResult. */
HMATH_API hmath_status hmath_symbolic_negative_infinity_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.DoesNotExist -> LimitResult. */
HMATH_API hmath_status hmath_symbolic_does_not_exist_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.symbolicLimit -> LimitResult. */
HMATH_API hmath_status hmath_symbolic_symbolic_limit(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *center, const hmath_value *direction, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.Series -> Series. */
HMATH_API hmath_status hmath_symbolic_series_create(hmath_context *context, const hmath_value *center, const hmath_value *minimum_power, const hmath_value *terms, hmath_value **out);

/* HMath.Symbolic.seriesCenter -> Rational. */
HMATH_API hmath_status hmath_symbolic_series_center(hmath_context *context, const hmath_value *series, hmath_value **out);

/* HMath.Symbolic.seriesMinimumPower -> Int. */
HMATH_API hmath_status hmath_symbolic_series_minimum_power(hmath_context *context, const hmath_value *series, hmath_value **out);

/* HMath.Symbolic.seriesTerms -> [Expr]. */
HMATH_API hmath_status hmath_symbolic_series_terms(hmath_context *context, const hmath_value *series, hmath_value **out);

/* HMath.Symbolic.taylorSeries -> Series. */
HMATH_API hmath_status hmath_symbolic_taylor_series(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *center, const hmath_value *order, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.laurentSeries -> Series. */
HMATH_API hmath_status hmath_symbolic_laurent_series(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *center, const hmath_value *order, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.maclaurinSeries -> Series. */
HMATH_API hmath_status hmath_symbolic_maclaurin_series(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *order, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.formalPowerSeries -> PowerSeries. */
HMATH_API hmath_status hmath_symbolic_formal_power_series(hmath_context *context, const hmath_value *options, const hmath_value *coefficients, hmath_value **out);

/* HMath.Symbolic.multiplyFormalSeries -> PowerSeries. */
HMATH_API hmath_status hmath_symbolic_multiply_formal_series(hmath_context *context, const hmath_value *options, const hmath_value *left, const hmath_value *right, hmath_value **out);

/* HMath.Symbolic.reciprocalFormalSeries -> PowerSeries. */
HMATH_API hmath_status hmath_symbolic_reciprocal_formal_series(hmath_context *context, const hmath_value *options, const hmath_value *series, hmath_value **out);

/* HMath.Symbolic.fromPolynomial -> Expr. */
HMATH_API hmath_status hmath_symbolic_from_polynomial(hmath_context *context, const hmath_value *variable, const hmath_value *polynomial, hmath_value **out);

/* HMath.Symbolic.Relation -> Relation. */
HMATH_API hmath_status hmath_symbolic_relation_create(hmath_context *context, const hmath_value *operator_, const hmath_value *left, const hmath_value *right, hmath_value **out);

/* HMath.Symbolic.Truth -> RelationResult. */
HMATH_API hmath_status hmath_symbolic_truth_create(hmath_context *context, const hmath_value *value, hmath_value **out);

/* HMath.Symbolic.Unresolved -> RelationResult. */
HMATH_API hmath_status hmath_symbolic_unresolved_create(hmath_context *context, const hmath_value *relation, hmath_value **out);

/* HMath.Symbolic.simplifyRelation -> RelationResult. */
HMATH_API hmath_status hmath_symbolic_simplify_relation(hmath_context *context, const hmath_value *options, const hmath_value *relation, hmath_value **out);

/* HMath.Symbolic.solveLinearInequality -> RelationResult. */
HMATH_API hmath_status hmath_symbolic_solve_linear_inequality(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *relation, hmath_value **out);

/* HMath.Symbolic.Inconsistent -> LinearSolution. */
HMATH_API hmath_status hmath_symbolic_inconsistent_create(hmath_context *context, hmath_value **out);

/* HMath.Symbolic.ParametricSolution -> LinearSolution. */
HMATH_API hmath_status hmath_symbolic_parametric_solution_create(hmath_context *context, const hmath_value *bindings, const hmath_value *free_variables, hmath_value **out);

/* HMath.Symbolic.solveLinearEquations -> LinearSolution. */
HMATH_API hmath_status hmath_symbolic_solve_linear_equations(hmath_context *context, const hmath_value *options, const hmath_value *variables, const hmath_value *equations, hmath_value **out);

/* HMath.Symbolic.symbolicMatrix -> SymbolicMatrix. */
HMATH_API hmath_status hmath_symbolic_symbolic_matrix(hmath_context *context, const hmath_value *options, const hmath_value *rows, hmath_value **out);

/* HMath.Symbolic.matrixExpressions -> [[Expr]]. */
HMATH_API hmath_status hmath_symbolic_matrix_expressions(hmath_context *context, const hmath_value *matrix, hmath_value **out);

/* HMath.Symbolic.matrixAdd -> SymbolicMatrix. */
HMATH_API hmath_status hmath_symbolic_matrix_add(hmath_context *context, const hmath_value *options, const hmath_value *left, const hmath_value *right, hmath_value **out);

/* HMath.Symbolic.matrixMultiply -> SymbolicMatrix. */
HMATH_API hmath_status hmath_symbolic_matrix_multiply(hmath_context *context, const hmath_value *options, const hmath_value *left, const hmath_value *right, hmath_value **out);

/* HMath.Symbolic.symbolicDeterminant -> Expr. */
HMATH_API hmath_status hmath_symbolic_symbolic_determinant(hmath_context *context, const hmath_value *options, const hmath_value *matrix, hmath_value **out);

/* HMath.Symbolic.Guarded -> Guarded. */
HMATH_API hmath_status hmath_symbolic_guarded_create(hmath_context *context, const hmath_value *value, const hmath_value *conditions, hmath_value **out);

/* HMath.Symbolic.guardedValue -> Generic. */
HMATH_API hmath_status hmath_symbolic_guarded_value(hmath_context *context, const hmath_value *guarded, hmath_value **out);

/* HMath.Symbolic.requiredConditions -> [(Expr,Property)]. */
HMATH_API hmath_status hmath_symbolic_required_conditions(hmath_context *context, const hmath_value *guarded, hmath_value **out);

/* HMath.Symbolic.symbolicEigenvalues -> Guarded[Expr]. */
HMATH_API hmath_status hmath_symbolic_symbolic_eigenvalues(hmath_context *context, const hmath_value *options, const hmath_value *matrix, hmath_value **out);

/* HMath.Symbolic.numericalSubstitution -> ExpressionValue. */
HMATH_API hmath_status hmath_symbolic_numerical_substitution(hmath_context *context, const hmath_value *options, const hmath_value *precision, const hmath_value *bindings, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.toLaTeX -> String. */
HMATH_API hmath_status hmath_symbolic_to_la_te_x(hmath_context *context, const hmath_value *limits, const hmath_value *expression, hmath_value **out);

/* HMath.Symbolic.toMathML -> String. */
HMATH_API hmath_status hmath_symbolic_to_math_ml(hmath_context *context, const hmath_value *limits, const hmath_value *expression, hmath_value **out);
/* END GENERATED */
#ifdef __cplusplus
}
#endif
#endif
