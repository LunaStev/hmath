/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_expression.h"
#include "value_internal.h"
#include <stdlib.h>
extern int hm_expression_apply(const char *,void *const *,size_t,void **);
static hmath_status invoke(hmath_context *context,const char *name,
                           const hmath_value *const *arguments,size_t count,hmath_value **out) {
    if (!out || (count && !arguments))
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL expression argument/output");
    if (count > (size_t)PTRDIFF_MAX/sizeof(void *))
        return hm_error(HMATH_OVERFLOW,"expression argument span overflow");
    for(size_t i=0;i<count;++i)
        if(!arguments[i]) return hm_error(HMATH_INVALID_ARGUMENT,"NULL expression value");
    void **stable=malloc((count?count:1)*sizeof *stable);
    if(!stable) return hm_error(HMATH_ALLOCATION_FAILED,"expression argument allocation failed");
    for(size_t i=0;i<count;++i) stable[i]=hm_value_stable(arguments[i]);
    hmath_value *result;
    hmath_status status=hm_value_begin(context,&result);
    if(status){free(stable);return status;}
    int code=hm_expression_apply(name,stable,count,&result->stable);
    free(stable);
    return hm_value_finish(result,code,out);
}
hmath_status hmath_expression_node_fields(hmath_context *ctx,const hmath_value *value,hmath_value **out){const hmath_value *args[]={value};return invoke(ctx,"__node_fields",args,1,out);}
hmath_status hmath_symbolic_pattern_fields(hmath_context *ctx,const hmath_value *value,hmath_value **out){const hmath_value *args[]={value};return invoke(ctx,"__pattern_fields",args,1,out);}
hmath_status hmath_expression_compare(hmath_context *ctx,const hmath_value *a,const hmath_value *b,hmath_value **out){const hmath_value *args[]={a,b};return invoke(ctx,"__compare_expr",args,2,out);}
hmath_status hmath_expression_node_compare(hmath_context *ctx,const hmath_value *a,const hmath_value *b,hmath_value **out){const hmath_value *args[]={a,b};return invoke(ctx,"__compare_node",args,2,out);}
hmath_status hmath_symbolic_pattern_equal(hmath_context *ctx,const hmath_value *a,const hmath_value *b,hmath_value **out){const hmath_value *args[]={a,b};return invoke(ctx,"__equal_pattern",args,2,out);}
/* BEGIN GENERATED */
hmath_status hmath_expression_source_pos_create(hmath_context *context, const hmath_value *offset, const hmath_value *line, const hmath_value *column, hmath_value **out) {
    const hmath_value *hm_arguments[] = {offset, line, column};
    return invoke(context, "HMath.Expression.SourcePos", hm_arguments, 3, out);
}

hmath_status hmath_expression_unknown_position(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.unknownPosition", NULL, 0, out);
}

hmath_status hmath_expression_source_offset(hmath_context *context, const hmath_value *position, hmath_value **out) {
    const hmath_value *hm_arguments[] = {position};
    return invoke(context, "HMath.Expression.sourceOffset", hm_arguments, 1, out);
}

hmath_status hmath_expression_source_line(hmath_context *context, const hmath_value *position, hmath_value **out) {
    const hmath_value *hm_arguments[] = {position};
    return invoke(context, "HMath.Expression.sourceLine", hm_arguments, 1, out);
}

hmath_status hmath_expression_source_column(hmath_context *context, const hmath_value *position, hmath_value **out) {
    const hmath_value *hm_arguments[] = {position};
    return invoke(context, "HMath.Expression.sourceColumn", hm_arguments, 1, out);
}

hmath_status hmath_expression_negate_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Negate", NULL, 0, out);
}

hmath_status hmath_expression_add_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Add", NULL, 0, out);
}

hmath_status hmath_expression_subtract_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Subtract", NULL, 0, out);
}

hmath_status hmath_expression_multiply_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Multiply", NULL, 0, out);
}

hmath_status hmath_expression_divide_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Divide", NULL, 0, out);
}

hmath_status hmath_expression_power_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Power", NULL, 0, out);
}

hmath_status hmath_expression_pi_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Pi", NULL, 0, out);
}

hmath_status hmath_expression_euler_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Euler", NULL, 0, out);
}

hmath_status hmath_expression_tau_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Tau", NULL, 0, out);
}

hmath_status hmath_expression_exact_rational_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.ExactRational", NULL, 0, out);
}

hmath_status hmath_expression_float64_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Float64", NULL, 0, out);
}

hmath_status hmath_expression_syntax_error_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.SyntaxError", NULL, 0, out);
}

hmath_status hmath_expression_unknown_name_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.UnknownName", NULL, 0, out);
}

hmath_status hmath_expression_type_mismatch_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.TypeMismatch", NULL, 0, out);
}

hmath_status hmath_expression_domain_failure_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.DomainFailure", NULL, 0, out);
}

hmath_status hmath_expression_non_finite_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.NonFinite", NULL, 0, out);
}

hmath_status hmath_expression_step_limit_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.StepLimit", NULL, 0, out);
}

hmath_status hmath_expression_depth_limit_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.DepthLimit", NULL, 0, out);
}

hmath_status hmath_expression_memory_limit_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.MemoryLimit", NULL, 0, out);
}

hmath_status hmath_expression_invalid_limits_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.InvalidLimits", NULL, 0, out);
}

hmath_status hmath_expression_unsupported_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Unsupported", NULL, 0, out);
}

hmath_status hmath_expression_sin_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Sin", NULL, 0, out);
}

hmath_status hmath_expression_cos_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Cos", NULL, 0, out);
}

hmath_status hmath_expression_tan_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Tan", NULL, 0, out);
}

hmath_status hmath_expression_exp_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Exp", NULL, 0, out);
}

hmath_status hmath_expression_log_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Log", NULL, 0, out);
}

hmath_status hmath_expression_sqrt_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Sqrt", NULL, 0, out);
}

hmath_status hmath_expression_abs_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Abs", NULL, 0, out);
}

hmath_status hmath_expression_signum_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Signum", NULL, 0, out);
}

hmath_status hmath_expression_floor_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Floor", NULL, 0, out);
}

hmath_status hmath_expression_ceiling_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Ceiling", NULL, 0, out);
}

hmath_status hmath_expression_min_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Min", NULL, 0, out);
}

hmath_status hmath_expression_max_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Max", NULL, 0, out);
}

hmath_status hmath_expression_asin_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Asin", NULL, 0, out);
}

hmath_status hmath_expression_acos_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Acos", NULL, 0, out);
}

hmath_status hmath_expression_atan_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Atan", NULL, 0, out);
}

hmath_status hmath_expression_sinh_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Sinh", NULL, 0, out);
}

hmath_status hmath_expression_cosh_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Cosh", NULL, 0, out);
}

hmath_status hmath_expression_tanh_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.Tanh", NULL, 0, out);
}

hmath_status hmath_expression_expr_create(hmath_context *context, const hmath_value *position, const hmath_value *node, hmath_value **out) {
    const hmath_value *hm_arguments[] = {position, node};
    return invoke(context, "HMath.Expression.Expr", hm_arguments, 2, out);
}

hmath_status hmath_expression_expression_position(hmath_context *context, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {expression};
    return invoke(context, "HMath.Expression.expressionPosition", hm_arguments, 1, out);
}

hmath_status hmath_expression_expression_node(hmath_context *context, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {expression};
    return invoke(context, "HMath.Expression.expressionNode", hm_arguments, 1, out);
}

hmath_status hmath_expression_literal_create(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *hm_arguments[] = {value};
    return invoke(context, "HMath.Expression.Literal", hm_arguments, 1, out);
}

hmath_status hmath_expression_variable_create(hmath_context *context, const hmath_value *name, hmath_value **out) {
    const hmath_value *hm_arguments[] = {name};
    return invoke(context, "HMath.Expression.Variable", hm_arguments, 1, out);
}

hmath_status hmath_expression_constant_create(hmath_context *context, const hmath_value *constant, hmath_value **out) {
    const hmath_value *hm_arguments[] = {constant};
    return invoke(context, "HMath.Expression.Constant", hm_arguments, 1, out);
}

hmath_status hmath_expression_unary_create(hmath_context *context, const hmath_value *operator_, const hmath_value *child, hmath_value **out) {
    const hmath_value *hm_arguments[] = {operator_, child};
    return invoke(context, "HMath.Expression.Unary", hm_arguments, 2, out);
}

hmath_status hmath_expression_binary_create(hmath_context *context, const hmath_value *operator_, const hmath_value *left, const hmath_value *right, hmath_value **out) {
    const hmath_value *hm_arguments[] = {operator_, left, right};
    return invoke(context, "HMath.Expression.Binary", hm_arguments, 3, out);
}

hmath_status hmath_expression_call_create(hmath_context *context, const hmath_value *name, const hmath_value *arguments, hmath_value **out) {
    const hmath_value *hm_arguments[] = {name, arguments};
    return invoke(context, "HMath.Expression.Call", hm_arguments, 2, out);
}

hmath_status hmath_expression_let_create(hmath_context *context, const hmath_value *name, const hmath_value *value, const hmath_value *body, hmath_value **out) {
    const hmath_value *hm_arguments[] = {name, value, body};
    return invoke(context, "HMath.Expression.Let", hm_arguments, 3, out);
}

hmath_status hmath_expression_literal(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *hm_arguments[] = {value};
    return invoke(context, "HMath.Expression.literal", hm_arguments, 1, out);
}

hmath_status hmath_expression_variable(hmath_context *context, const hmath_value *name, hmath_value **out) {
    const hmath_value *hm_arguments[] = {name};
    return invoke(context, "HMath.Expression.variable", hm_arguments, 1, out);
}

hmath_status hmath_expression_constant(hmath_context *context, const hmath_value *constant, hmath_value **out) {
    const hmath_value *hm_arguments[] = {constant};
    return invoke(context, "HMath.Expression.constant", hm_arguments, 1, out);
}

hmath_status hmath_expression_unary(hmath_context *context, const hmath_value *operator_, const hmath_value *child, hmath_value **out) {
    const hmath_value *hm_arguments[] = {operator_, child};
    return invoke(context, "HMath.Expression.unary", hm_arguments, 2, out);
}

hmath_status hmath_expression_binary(hmath_context *context, const hmath_value *operator_, const hmath_value *left, const hmath_value *right, hmath_value **out) {
    const hmath_value *hm_arguments[] = {operator_, left, right};
    return invoke(context, "HMath.Expression.binary", hm_arguments, 3, out);
}

hmath_status hmath_expression_call(hmath_context *context, const hmath_value *name, const hmath_value *arguments, hmath_value **out) {
    const hmath_value *hm_arguments[] = {name, arguments};
    return invoke(context, "HMath.Expression.call", hm_arguments, 2, out);
}

hmath_status hmath_expression_let_in(hmath_context *context, const hmath_value *name, const hmath_value *value, const hmath_value *body, hmath_value **out) {
    const hmath_value *hm_arguments[] = {name, value, body};
    return invoke(context, "HMath.Expression.letIn", hm_arguments, 3, out);
}

hmath_status hmath_expression_limits_create(hmath_context *context, const hmath_value *maximum_steps, const hmath_value *maximum_depth, const hmath_value *maximum_nodes, const hmath_value *maximum_input_chars, const hmath_value *maximum_integer_bits, const hmath_value *maximum_cache_entries, hmath_value **out) {
    const hmath_value *hm_arguments[] = {maximum_steps, maximum_depth, maximum_nodes, maximum_input_chars, maximum_integer_bits, maximum_cache_entries};
    return invoke(context, "HMath.Expression.Limits", hm_arguments, 6, out);
}

hmath_status hmath_expression_default_limits(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.defaultLimits", NULL, 0, out);
}

hmath_status hmath_expression_maximum_steps(hmath_context *context, const hmath_value *limits, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits};
    return invoke(context, "HMath.Expression.maximumSteps", hm_arguments, 1, out);
}

hmath_status hmath_expression_maximum_depth(hmath_context *context, const hmath_value *limits, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits};
    return invoke(context, "HMath.Expression.maximumDepth", hm_arguments, 1, out);
}

hmath_status hmath_expression_maximum_nodes(hmath_context *context, const hmath_value *limits, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits};
    return invoke(context, "HMath.Expression.maximumNodes", hm_arguments, 1, out);
}

hmath_status hmath_expression_maximum_input_chars(hmath_context *context, const hmath_value *limits, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits};
    return invoke(context, "HMath.Expression.maximumInputChars", hm_arguments, 1, out);
}

hmath_status hmath_expression_maximum_integer_bits(hmath_context *context, const hmath_value *limits, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits};
    return invoke(context, "HMath.Expression.maximumIntegerBits", hm_arguments, 1, out);
}

hmath_status hmath_expression_maximum_cache_entries(hmath_context *context, const hmath_value *limits, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits};
    return invoke(context, "HMath.Expression.maximumCacheEntries", hm_arguments, 1, out);
}

hmath_status hmath_expression_expr_error_create(hmath_context *context, const hmath_value *kind, const hmath_value *position, const hmath_value *message, hmath_value **out) {
    const hmath_value *hm_arguments[] = {kind, position, message};
    return invoke(context, "HMath.Expression.ExprError", hm_arguments, 3, out);
}

hmath_status hmath_expression_error_kind_get(hmath_context *context, const hmath_value *error, hmath_value **out) {
    const hmath_value *hm_arguments[] = {error};
    return invoke(context, "HMath.Expression.errorKind", hm_arguments, 1, out);
}

hmath_status hmath_expression_error_position(hmath_context *context, const hmath_value *error, hmath_value **out) {
    const hmath_value *hm_arguments[] = {error};
    return invoke(context, "HMath.Expression.errorPosition", hm_arguments, 1, out);
}

hmath_status hmath_expression_error_message(hmath_context *context, const hmath_value *error, hmath_value **out) {
    const hmath_value *hm_arguments[] = {error};
    return invoke(context, "HMath.Expression.errorMessage", hm_arguments, 1, out);
}

hmath_status hmath_expression_validate_limits(hmath_context *context, const hmath_value *limits, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits};
    return invoke(context, "HMath.Expression.validateLimits", hm_arguments, 1, out);
}

hmath_status hmath_expression_validate_expression(hmath_context *context, const hmath_value *limits, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits, expression};
    return invoke(context, "HMath.Expression.validateExpression", hm_arguments, 2, out);
}

hmath_status hmath_expression_parse_expression(hmath_context *context, const hmath_value *limits, const hmath_value *source, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits, source};
    return invoke(context, "HMath.Expression.parseExpression", hm_arguments, 2, out);
}

hmath_status hmath_expression_pretty_expression(hmath_context *context, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {expression};
    return invoke(context, "HMath.Expression.prettyExpression", hm_arguments, 1, out);
}

hmath_status hmath_expression_free_variables(hmath_context *context, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {expression};
    return invoke(context, "HMath.Expression.freeVariables", hm_arguments, 1, out);
}

hmath_status hmath_expression_exact_value_create(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *hm_arguments[] = {value};
    return invoke(context, "HMath.Expression.ExactValue", hm_arguments, 1, out);
}

hmath_status hmath_expression_float_value_create(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *hm_arguments[] = {value};
    return invoke(context, "HMath.Expression.FloatValue", hm_arguments, 1, out);
}

hmath_status hmath_expression_default_registry(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.defaultRegistry", NULL, 0, out);
}

hmath_status hmath_expression_empty_registry(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.emptyRegistry", NULL, 0, out);
}

hmath_status hmath_expression_register_function(hmath_context *context, const hmath_value *name, const hmath_value *builtin, const hmath_value *registry, hmath_value **out) {
    const hmath_value *hm_arguments[] = {name, builtin, registry};
    return invoke(context, "HMath.Expression.registerFunction", hm_arguments, 3, out);
}

hmath_status hmath_expression_allowed_functions(hmath_context *context, const hmath_value *registry, hmath_value **out) {
    const hmath_value *hm_arguments[] = {registry};
    return invoke(context, "HMath.Expression.allowedFunctions", hm_arguments, 1, out);
}

hmath_status hmath_expression_type_check_expression(hmath_context *context, const hmath_value *limits, const hmath_value *precision, const hmath_value *registry, const hmath_value *bindings, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits, precision, registry, bindings, expression};
    return invoke(context, "HMath.Expression.typeCheckExpression", hm_arguments, 5, out);
}

hmath_status hmath_expression_evaluate_expression(hmath_context *context, const hmath_value *limits, const hmath_value *precision, const hmath_value *registry, const hmath_value *bindings, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits, precision, registry, bindings, expression};
    return invoke(context, "HMath.Expression.evaluateExpression", hm_arguments, 5, out);
}

hmath_status hmath_expression_evaluate_text(hmath_context *context, const hmath_value *limits, const hmath_value *precision, const hmath_value *registry, const hmath_value *bindings, const hmath_value *source, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits, precision, registry, bindings, source};
    return invoke(context, "HMath.Expression.evaluateText", hm_arguments, 5, out);
}

hmath_status hmath_expression_evaluate_compiled(hmath_context *context, const hmath_value *limits, const hmath_value *precision, const hmath_value *registry, const hmath_value *bindings, const hmath_value *compiled, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits, precision, registry, bindings, compiled};
    return invoke(context, "HMath.Expression.evaluateCompiled", hm_arguments, 5, out);
}

hmath_status hmath_expression_compile_expression(hmath_context *context, const hmath_value *limits, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits, expression};
    return invoke(context, "HMath.Expression.compileExpression", hm_arguments, 2, out);
}

hmath_status hmath_expression_compiled_node_count(hmath_context *context, const hmath_value *compiled, hmath_value **out) {
    const hmath_value *hm_arguments[] = {compiled};
    return invoke(context, "HMath.Expression.compiledNodeCount", hm_arguments, 1, out);
}

hmath_status hmath_expression_optimize_expression(hmath_context *context, const hmath_value *limits, const hmath_value *precision, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits, precision, expression};
    return invoke(context, "HMath.Expression.optimizeExpression", hm_arguments, 3, out);
}

hmath_status hmath_expression_empty_expression_cache(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Expression.emptyExpressionCache", NULL, 0, out);
}

hmath_status hmath_expression_cache_size(hmath_context *context, const hmath_value *cache, hmath_value **out) {
    const hmath_value *hm_arguments[] = {cache};
    return invoke(context, "HMath.Expression.cacheSize", hm_arguments, 1, out);
}

hmath_status hmath_expression_cached_expression(hmath_context *context, const hmath_value *limits, const hmath_value *source, const hmath_value *cache, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits, source, cache};
    return invoke(context, "HMath.Expression.cachedExpression", hm_arguments, 3, out);
}

hmath_status hmath_expression_format_scientific(hmath_context *context, const hmath_value *digits, const hmath_value *value, hmath_value **out) {
    const hmath_value *hm_arguments[] = {digits, value};
    return invoke(context, "HMath.Expression.formatScientific", hm_arguments, 2, out);
}

hmath_status hmath_expression_format_radix(hmath_context *context, const hmath_value *radix, const hmath_value *value, hmath_value **out) {
    const hmath_value *hm_arguments[] = {radix, value};
    return invoke(context, "HMath.Expression.formatRadix", hm_arguments, 2, out);
}

hmath_status hmath_expression_serialize_expression(hmath_context *context, const hmath_value *limits, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits, expression};
    return invoke(context, "HMath.Expression.serializeExpression", hm_arguments, 2, out);
}

hmath_status hmath_expression_deserialize_expression(hmath_context *context, const hmath_value *limits, const hmath_value *serialized, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits, serialized};
    return invoke(context, "HMath.Expression.deserializeExpression", hm_arguments, 2, out);
}

hmath_status hmath_expression_expression_hash(hmath_context *context, const hmath_value *limits, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits, expression};
    return invoke(context, "HMath.Expression.expressionHash", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_real_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.Real", NULL, 0, out);
}

hmath_status hmath_symbolic_non_zero_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.NonZero", NULL, 0, out);
}

hmath_status hmath_symbolic_positive_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.Positive", NULL, 0, out);
}

hmath_status hmath_symbolic_non_negative_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.NonNegative", NULL, 0, out);
}

hmath_status hmath_symbolic_integral_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.Integral", NULL, 0, out);
}

hmath_status hmath_symbolic_negative_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.Negative", NULL, 0, out);
}

hmath_status hmath_symbolic_non_positive_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.NonPositive", NULL, 0, out);
}

hmath_status hmath_symbolic_from_left_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.FromLeft", NULL, 0, out);
}

hmath_status hmath_symbolic_from_right_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.FromRight", NULL, 0, out);
}

hmath_status hmath_symbolic_two_sided_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.TwoSided", NULL, 0, out);
}

hmath_status hmath_symbolic_equal_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.Equal", NULL, 0, out);
}

hmath_status hmath_symbolic_not_equal_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.NotEqual", NULL, 0, out);
}

hmath_status hmath_symbolic_less_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.Less", NULL, 0, out);
}

hmath_status hmath_symbolic_less_equal_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.LessEqual", NULL, 0, out);
}

hmath_status hmath_symbolic_greater_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.Greater", NULL, 0, out);
}

hmath_status hmath_symbolic_greater_equal_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.GreaterEqual", NULL, 0, out);
}

hmath_status hmath_symbolic_assumptions(hmath_context *context, const hmath_value *entries, hmath_value **out) {
    const hmath_value *hm_arguments[] = {entries};
    return invoke(context, "HMath.Symbolic.assumptions", hm_arguments, 1, out);
}

hmath_status hmath_symbolic_no_assumptions(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.noAssumptions", NULL, 0, out);
}

hmath_status hmath_symbolic_proves(hmath_context *context, const hmath_value *assumptions, const hmath_value *property, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {assumptions, property, expression};
    return invoke(context, "HMath.Symbolic.proves", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_symbolic_options_create(hmath_context *context, const hmath_value *limits, const hmath_value *assumptions, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits, assumptions};
    return invoke(context, "HMath.Symbolic.SymbolicOptions", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_default_symbolic_options(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.defaultSymbolicOptions", NULL, 0, out);
}

hmath_status hmath_symbolic_symbolic_limits(hmath_context *context, const hmath_value *options, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options};
    return invoke(context, "HMath.Symbolic.symbolicLimits", hm_arguments, 1, out);
}

hmath_status hmath_symbolic_symbolic_assumptions(hmath_context *context, const hmath_value *options, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options};
    return invoke(context, "HMath.Symbolic.symbolicAssumptions", hm_arguments, 1, out);
}

hmath_status hmath_symbolic_normalize(hmath_context *context, const hmath_value *options, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, expression};
    return invoke(context, "HMath.Symbolic.normalize", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_simplify(hmath_context *context, const hmath_value *options, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, expression};
    return invoke(context, "HMath.Symbolic.simplify", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_expand(hmath_context *context, const hmath_value *options, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, expression};
    return invoke(context, "HMath.Symbolic.expand", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_collect_terms(hmath_context *context, const hmath_value *options, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, expression};
    return invoke(context, "HMath.Symbolic.collectTerms", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_trigonometric_simplify(hmath_context *context, const hmath_value *options, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, expression};
    return invoke(context, "HMath.Symbolic.trigonometricSimplify", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_logarithmic_simplify(hmath_context *context, const hmath_value *options, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, expression};
    return invoke(context, "HMath.Symbolic.logarithmicSimplify", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_factor_polynomial(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, variable, expression};
    return invoke(context, "HMath.Symbolic.factorPolynomial", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_rational_simplify(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, variable, expression};
    return invoke(context, "HMath.Symbolic.rationalSimplify", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_differentiate(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, variable, expression};
    return invoke(context, "HMath.Symbolic.differentiate", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_integrate_basic(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, variable, expression};
    return invoke(context, "HMath.Symbolic.integrateBasic", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_to_polynomial(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, variable, expression};
    return invoke(context, "HMath.Symbolic.toPolynomial", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_exact_polynomial_roots(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, variable, expression};
    return invoke(context, "HMath.Symbolic.exactPolynomialRoots", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_numerical_polynomial_roots(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, variable, expression};
    return invoke(context, "HMath.Symbolic.numericalPolynomialRoots", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_polynomial_factorization_create(hmath_context *context, const hmath_value *leading, const hmath_value *terms, hmath_value **out) {
    const hmath_value *hm_arguments[] = {leading, terms};
    return invoke(context, "HMath.Symbolic.PolynomialFactorization", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_factor_leading(hmath_context *context, const hmath_value *factorization, hmath_value **out) {
    const hmath_value *hm_arguments[] = {factorization};
    return invoke(context, "HMath.Symbolic.factorLeading", hm_arguments, 1, out);
}

hmath_status hmath_symbolic_factor_terms(hmath_context *context, const hmath_value *factorization, hmath_value **out) {
    const hmath_value *hm_arguments[] = {factorization};
    return invoke(context, "HMath.Symbolic.factorTerms", hm_arguments, 1, out);
}

hmath_status hmath_symbolic_substitute(hmath_context *context, const hmath_value *limits, const hmath_value *bindings, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits, bindings, expression};
    return invoke(context, "HMath.Symbolic.substitute", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_any_create(hmath_context *context, const hmath_value *name, hmath_value **out) {
    const hmath_value *hm_arguments[] = {name};
    return invoke(context, "HMath.Symbolic.Any", hm_arguments, 1, out);
}

hmath_status hmath_symbolic_exactly_create(hmath_context *context, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {expression};
    return invoke(context, "HMath.Symbolic.Exactly", hm_arguments, 1, out);
}

hmath_status hmath_symbolic_unary_pattern_create(hmath_context *context, const hmath_value *operator_, const hmath_value *child, hmath_value **out) {
    const hmath_value *hm_arguments[] = {operator_, child};
    return invoke(context, "HMath.Symbolic.UnaryPattern", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_binary_pattern_create(hmath_context *context, const hmath_value *operator_, const hmath_value *left, const hmath_value *right, hmath_value **out) {
    const hmath_value *hm_arguments[] = {operator_, left, right};
    return invoke(context, "HMath.Symbolic.BinaryPattern", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_call_pattern_create(hmath_context *context, const hmath_value *name, const hmath_value *arguments, hmath_value **out) {
    const hmath_value *hm_arguments[] = {name, arguments};
    return invoke(context, "HMath.Symbolic.CallPattern", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_match_pattern(hmath_context *context, const hmath_value *limits, const hmath_value *pattern, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits, pattern, expression};
    return invoke(context, "HMath.Symbolic.matchPattern", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_rewrite_rule_create(hmath_context *context, const hmath_value *pattern, const hmath_value *replacement, const hmath_value *requirements, hmath_value **out) {
    const hmath_value *hm_arguments[] = {pattern, replacement, requirements};
    return invoke(context, "HMath.Symbolic.RewriteRule", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_rewrite_pattern(hmath_context *context, const hmath_value *rule, hmath_value **out) {
    const hmath_value *hm_arguments[] = {rule};
    return invoke(context, "HMath.Symbolic.rewritePattern", hm_arguments, 1, out);
}

hmath_status hmath_symbolic_rewrite_replacement(hmath_context *context, const hmath_value *rule, hmath_value **out) {
    const hmath_value *hm_arguments[] = {rule};
    return invoke(context, "HMath.Symbolic.rewriteReplacement", hm_arguments, 1, out);
}

hmath_status hmath_symbolic_rewrite_requirements(hmath_context *context, const hmath_value *rule, hmath_value **out) {
    const hmath_value *hm_arguments[] = {rule};
    return invoke(context, "HMath.Symbolic.rewriteRequirements", hm_arguments, 1, out);
}

hmath_status hmath_symbolic_apply_rewrite(hmath_context *context, const hmath_value *options, const hmath_value *rule, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, rule, expression};
    return invoke(context, "HMath.Symbolic.applyRewrite", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_gradient(hmath_context *context, const hmath_value *options, const hmath_value *variables, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, variables, expression};
    return invoke(context, "HMath.Symbolic.gradient", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_hessian(hmath_context *context, const hmath_value *options, const hmath_value *variables, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, variables, expression};
    return invoke(context, "HMath.Symbolic.hessian", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_jacobian(hmath_context *context, const hmath_value *options, const hmath_value *variables, const hmath_value *expressions, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, variables, expressions};
    return invoke(context, "HMath.Symbolic.jacobian", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_integrate_by_parts(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *u, const hmath_value *dv, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, variable, u, dv};
    return invoke(context, "HMath.Symbolic.integrateByParts", hm_arguments, 4, out);
}

hmath_status hmath_symbolic_integrate_substitution(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *temporary, const hmath_value *inner, const hmath_value *outer, const hmath_value *integrand, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, variable, temporary, inner, outer, integrand};
    return invoke(context, "HMath.Symbolic.integrateSubstitution", hm_arguments, 6, out);
}

hmath_status hmath_symbolic_integrate_rational(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *numerator, const hmath_value *denominator, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, variable, numerator, denominator};
    return invoke(context, "HMath.Symbolic.integrateRational", hm_arguments, 4, out);
}

hmath_status hmath_symbolic_finite_limit_create(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *hm_arguments[] = {value};
    return invoke(context, "HMath.Symbolic.FiniteLimit", hm_arguments, 1, out);
}

hmath_status hmath_symbolic_positive_infinity_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.PositiveInfinity", NULL, 0, out);
}

hmath_status hmath_symbolic_negative_infinity_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.NegativeInfinity", NULL, 0, out);
}

hmath_status hmath_symbolic_does_not_exist_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.DoesNotExist", NULL, 0, out);
}

hmath_status hmath_symbolic_symbolic_limit(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *center, const hmath_value *direction, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, variable, center, direction, expression};
    return invoke(context, "HMath.Symbolic.symbolicLimit", hm_arguments, 5, out);
}

hmath_status hmath_symbolic_series_create(hmath_context *context, const hmath_value *center, const hmath_value *minimum_power, const hmath_value *terms, hmath_value **out) {
    const hmath_value *hm_arguments[] = {center, minimum_power, terms};
    return invoke(context, "HMath.Symbolic.Series", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_series_center(hmath_context *context, const hmath_value *series, hmath_value **out) {
    const hmath_value *hm_arguments[] = {series};
    return invoke(context, "HMath.Symbolic.seriesCenter", hm_arguments, 1, out);
}

hmath_status hmath_symbolic_series_minimum_power(hmath_context *context, const hmath_value *series, hmath_value **out) {
    const hmath_value *hm_arguments[] = {series};
    return invoke(context, "HMath.Symbolic.seriesMinimumPower", hm_arguments, 1, out);
}

hmath_status hmath_symbolic_series_terms(hmath_context *context, const hmath_value *series, hmath_value **out) {
    const hmath_value *hm_arguments[] = {series};
    return invoke(context, "HMath.Symbolic.seriesTerms", hm_arguments, 1, out);
}

hmath_status hmath_symbolic_taylor_series(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *center, const hmath_value *order, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, variable, center, order, expression};
    return invoke(context, "HMath.Symbolic.taylorSeries", hm_arguments, 5, out);
}

hmath_status hmath_symbolic_laurent_series(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *center, const hmath_value *order, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, variable, center, order, expression};
    return invoke(context, "HMath.Symbolic.laurentSeries", hm_arguments, 5, out);
}

hmath_status hmath_symbolic_maclaurin_series(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *order, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, variable, order, expression};
    return invoke(context, "HMath.Symbolic.maclaurinSeries", hm_arguments, 4, out);
}

hmath_status hmath_symbolic_formal_power_series(hmath_context *context, const hmath_value *options, const hmath_value *coefficients, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, coefficients};
    return invoke(context, "HMath.Symbolic.formalPowerSeries", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_multiply_formal_series(hmath_context *context, const hmath_value *options, const hmath_value *left, const hmath_value *right, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, left, right};
    return invoke(context, "HMath.Symbolic.multiplyFormalSeries", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_reciprocal_formal_series(hmath_context *context, const hmath_value *options, const hmath_value *series, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, series};
    return invoke(context, "HMath.Symbolic.reciprocalFormalSeries", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_from_polynomial(hmath_context *context, const hmath_value *variable, const hmath_value *polynomial, hmath_value **out) {
    const hmath_value *hm_arguments[] = {variable, polynomial};
    return invoke(context, "HMath.Symbolic.fromPolynomial", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_relation_create(hmath_context *context, const hmath_value *operator_, const hmath_value *left, const hmath_value *right, hmath_value **out) {
    const hmath_value *hm_arguments[] = {operator_, left, right};
    return invoke(context, "HMath.Symbolic.Relation", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_truth_create(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *hm_arguments[] = {value};
    return invoke(context, "HMath.Symbolic.Truth", hm_arguments, 1, out);
}

hmath_status hmath_symbolic_unresolved_create(hmath_context *context, const hmath_value *relation, hmath_value **out) {
    const hmath_value *hm_arguments[] = {relation};
    return invoke(context, "HMath.Symbolic.Unresolved", hm_arguments, 1, out);
}

hmath_status hmath_symbolic_simplify_relation(hmath_context *context, const hmath_value *options, const hmath_value *relation, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, relation};
    return invoke(context, "HMath.Symbolic.simplifyRelation", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_solve_linear_inequality(hmath_context *context, const hmath_value *options, const hmath_value *variable, const hmath_value *relation, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, variable, relation};
    return invoke(context, "HMath.Symbolic.solveLinearInequality", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_inconsistent_create(hmath_context *context, hmath_value **out) {
    return invoke(context, "HMath.Symbolic.Inconsistent", NULL, 0, out);
}

hmath_status hmath_symbolic_parametric_solution_create(hmath_context *context, const hmath_value *bindings, const hmath_value *free_variables, hmath_value **out) {
    const hmath_value *hm_arguments[] = {bindings, free_variables};
    return invoke(context, "HMath.Symbolic.ParametricSolution", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_solve_linear_equations(hmath_context *context, const hmath_value *options, const hmath_value *variables, const hmath_value *equations, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, variables, equations};
    return invoke(context, "HMath.Symbolic.solveLinearEquations", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_symbolic_matrix(hmath_context *context, const hmath_value *options, const hmath_value *rows, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, rows};
    return invoke(context, "HMath.Symbolic.symbolicMatrix", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_matrix_expressions(hmath_context *context, const hmath_value *matrix, hmath_value **out) {
    const hmath_value *hm_arguments[] = {matrix};
    return invoke(context, "HMath.Symbolic.matrixExpressions", hm_arguments, 1, out);
}

hmath_status hmath_symbolic_matrix_add(hmath_context *context, const hmath_value *options, const hmath_value *left, const hmath_value *right, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, left, right};
    return invoke(context, "HMath.Symbolic.matrixAdd", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_matrix_multiply(hmath_context *context, const hmath_value *options, const hmath_value *left, const hmath_value *right, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, left, right};
    return invoke(context, "HMath.Symbolic.matrixMultiply", hm_arguments, 3, out);
}

hmath_status hmath_symbolic_symbolic_determinant(hmath_context *context, const hmath_value *options, const hmath_value *matrix, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, matrix};
    return invoke(context, "HMath.Symbolic.symbolicDeterminant", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_guarded_create(hmath_context *context, const hmath_value *value, const hmath_value *conditions, hmath_value **out) {
    const hmath_value *hm_arguments[] = {value, conditions};
    return invoke(context, "HMath.Symbolic.Guarded", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_guarded_value(hmath_context *context, const hmath_value *guarded, hmath_value **out) {
    const hmath_value *hm_arguments[] = {guarded};
    return invoke(context, "HMath.Symbolic.guardedValue", hm_arguments, 1, out);
}

hmath_status hmath_symbolic_required_conditions(hmath_context *context, const hmath_value *guarded, hmath_value **out) {
    const hmath_value *hm_arguments[] = {guarded};
    return invoke(context, "HMath.Symbolic.requiredConditions", hm_arguments, 1, out);
}

hmath_status hmath_symbolic_symbolic_eigenvalues(hmath_context *context, const hmath_value *options, const hmath_value *matrix, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, matrix};
    return invoke(context, "HMath.Symbolic.symbolicEigenvalues", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_numerical_substitution(hmath_context *context, const hmath_value *options, const hmath_value *precision, const hmath_value *bindings, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {options, precision, bindings, expression};
    return invoke(context, "HMath.Symbolic.numericalSubstitution", hm_arguments, 4, out);
}

hmath_status hmath_symbolic_to_la_te_x(hmath_context *context, const hmath_value *limits, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits, expression};
    return invoke(context, "HMath.Symbolic.toLaTeX", hm_arguments, 2, out);
}

hmath_status hmath_symbolic_to_math_ml(hmath_context *context, const hmath_value *limits, const hmath_value *expression, hmath_value **out) {
    const hmath_value *hm_arguments[] = {limits, expression};
    return invoke(context, "HMath.Symbolic.toMathML", hm_arguments, 2, out);
}
/* END GENERATED */
