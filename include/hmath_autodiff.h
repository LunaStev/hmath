/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_AUTODIFF_H
#define HMATH_AUTODIFF_H
#include "hmath.h"
#include "hmath_value.h"
#include "hmath_callback.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Immutable, independently owned Haskell values. Every returned handle owns a
 * runtime reservation: final shutdown is BUSY until all are released. Callers
 * retain input handles throughout each call; never race final release with use.
 * Output pointers/buffers must be disjoint from inputs and one another. Outputs
 * are untouched on failure. Reverse graphs use the original Double arithmetic;
 * Dual leaves select their original explicit Float/Double/Integer/Rational type.
 * Original MathError constructors/payloads are reported with
 * HMATH_MATH_ERROR; no new domain checks or mathematical defaults are added.
 * Context cancellation is checked before entry. A NULL context disables it.
 * Coordinate/axis/dimension arguments use Haskell Int, represented by ptrdiff_t.
 * Input arrays are borrowed for the call, output arrays belong to the caller.
 * Dual operators invoke the original Haskell Dual Double instances. */
typedef struct hmath_ad_handle hmath_ad_handle;
typedef hmath_ad_handle hmath_ad_expr;
typedef hmath_ad_handle hmath_ad_graph;
typedef hmath_ad_handle hmath_ad_gradient_state;
typedef hmath_ad_handle hmath_ad_tensor;
typedef hmath_ad_handle hmath_ad_dual;
typedef enum hmath_ad_unary_operation {
    HMATH_AD_NEGATE = 0,
    HMATH_AD_ABSOLUTE = 1,
    HMATH_AD_SIGN = 2,
    HMATH_AD_RECIPROCAL = 3,
    HMATH_AD_EXP = 4,
    HMATH_AD_LOG = 5,
    HMATH_AD_SQRT = 6,
    HMATH_AD_SIN = 7,
    HMATH_AD_COS = 8,
    HMATH_AD_TAN = 9,
    HMATH_AD_ASIN = 10,
    HMATH_AD_ACOS = 11,
    HMATH_AD_ATAN = 12,
    HMATH_AD_SINH = 13,
    HMATH_AD_COSH = 14,
    HMATH_AD_TANH = 15,
    HMATH_AD_ASINH = 16,
    HMATH_AD_ACOSH = 17,
    HMATH_AD_ATANH = 18,
    HMATH_AD_DETACH = 19,
    HMATH_AD_STOP_GRADIENT = 20
} hmath_ad_unary_operation;
typedef enum hmath_ad_binary_operation {
    HMATH_AD_ADD = 0,
    HMATH_AD_SUBTRACT = 1,
    HMATH_AD_MULTIPLY = 2,
    HMATH_AD_DIVIDE = 3,
    HMATH_AD_POWER = 4
} hmath_ad_binary_operation;
HMATH_API void hmath_ad_retain(hmath_ad_handle *value);
HMATH_API void hmath_ad_release(hmath_ad_handle *value);
HMATH_API hmath_status hmath_ad_variable(hmath_context *context, ptrdiff_t index,
                                         hmath_ad_expr **out);
HMATH_API hmath_status hmath_ad_constant(hmath_context *context, double value, hmath_ad_expr **out);
HMATH_API hmath_status hmath_ad_dual_create(hmath_context *context, double primal, double tangent,
                                            hmath_ad_dual **out);
HMATH_API hmath_status hmath_ad_unary(hmath_context *context, hmath_ad_unary_operation operation,
                                      const hmath_ad_handle *value, hmath_ad_handle **out);
HMATH_API hmath_status hmath_ad_binary(hmath_context *context, hmath_ad_binary_operation operation,
                                       const hmath_ad_handle *left, const hmath_ad_handle *right,
                                       hmath_ad_handle **out);
HMATH_API hmath_status hmath_ad_compile_graph(hmath_context *context, ptrdiff_t index,
                                              const hmath_ad_expr *expression,
                                              hmath_ad_graph **out);
HMATH_API hmath_status hmath_ad_differentiate(hmath_context *context, ptrdiff_t index,
                                              const hmath_ad_expr *expression, hmath_ad_expr **out);
HMATH_API hmath_status hmath_ad_zero_gradients(hmath_context *context, ptrdiff_t count,
                                               hmath_ad_gradient_state **out);
HMATH_API hmath_status hmath_ad_gradient_state_create(hmath_context *context, const double *values,
                                                      size_t count, hmath_ad_gradient_state **out);
HMATH_API hmath_status hmath_ad_accumulate_gradients(hmath_context *context,
                                                     const hmath_ad_gradient_state *state,
                                                     const double *values, size_t count,
                                                     hmath_ad_gradient_state **out);
HMATH_API hmath_status hmath_ad_gradient_hook_result(hmath_context *context,
                                                     const hmath_ad_gradient_state *state,
                                                     const double *values, size_t count,
                                                     hmath_ad_gradient_state **out);
HMATH_API hmath_status hmath_ad_reset_gradients(hmath_context *context,
                                                const hmath_ad_gradient_state *state,
                                                hmath_ad_gradient_state **out);
HMATH_API hmath_status hmath_ad_clip_gradient(hmath_context *context, double limit,
                                              const double *values, size_t count,
                                              hmath_ad_gradient_state **out);
HMATH_API hmath_status hmath_ad_tensor_create(hmath_context *context, const ptrdiff_t *shape,
                                              size_t rank, const hmath_ad_expr *const *values,
                                              size_t count, hmath_ad_tensor **out);
HMATH_API hmath_status hmath_ad_broadcast(hmath_context *context, const ptrdiff_t *shape,
                                          size_t rank, const hmath_ad_tensor *tensor,
                                          hmath_ad_tensor **out);
HMATH_API hmath_status hmath_ad_tensor_add(hmath_context *context, const hmath_ad_tensor *left,
                                           const hmath_ad_tensor *right, hmath_ad_tensor **out);
HMATH_API hmath_status hmath_ad_tensor_multiply(hmath_context *context, const hmath_ad_tensor *left,
                                                const hmath_ad_tensor *right,
                                                hmath_ad_tensor **out);
HMATH_API hmath_status hmath_ad_matmul(hmath_context *context, const hmath_ad_tensor *left,
                                       const hmath_ad_tensor *right, hmath_ad_tensor **out);
HMATH_API hmath_status hmath_ad_contract(hmath_context *context, const ptrdiff_t *left_axes,
                                         size_t left_count, const ptrdiff_t *right_axes,
                                         size_t right_count, const hmath_ad_tensor *left,
                                         const hmath_ad_tensor *right, hmath_ad_tensor **out);
HMATH_API hmath_status hmath_ad_sum(hmath_context *context, const hmath_ad_tensor *tensor,
                                    hmath_ad_expr **out);
HMATH_API hmath_status hmath_ad_evaluate_graph(hmath_context *context,
                                               const hmath_ad_graph *expression,
                                               const double *values, size_t n, double *out,
                                               size_t capacity);
HMATH_API hmath_status hmath_ad_value_and_gradient(hmath_context *context,
                                                   const hmath_ad_expr *expression,
                                                   const double *values, size_t n, double *out,
                                                   size_t capacity);
HMATH_API hmath_status hmath_ad_gradient(hmath_context *context, const hmath_ad_expr *expression,
                                         const double *values, size_t n, double *out,
                                         size_t capacity);
HMATH_API hmath_status hmath_ad_hessian(hmath_context *context, const hmath_ad_expr *expression,
                                        const double *values, size_t n, double *out,
                                        size_t capacity);
HMATH_API hmath_status hmath_ad_hvp(hmath_context *context, const hmath_ad_expr *expression,
                                    const double *values, size_t n, const double *direction,
                                    size_t direction_count, double *out, size_t capacity);
HMATH_API hmath_status hmath_ad_gradient_check(hmath_context *context,
                                               const hmath_ad_expr *expression,
                                               const double *values, size_t n, double step,
                                               double *out, size_t capacity);
HMATH_API hmath_status hmath_ad_complex_gradient(hmath_context *context,
                                                 const hmath_ad_expr *expression,
                                                 const double *values, size_t n, double *out,
                                                 size_t capacity);
HMATH_API hmath_status hmath_ad_jacobian(hmath_context *context,
                                         const hmath_ad_expr *const *expressions, size_t count,
                                         const double *values, size_t n, double *out,
                                         size_t capacity);
HMATH_API hmath_status hmath_ad_jvp(hmath_context *context, const hmath_ad_expr *const *expressions,
                                    size_t count, const double *values, size_t n,
                                    const double *direction, size_t direction_count, double *out,
                                    size_t capacity);
HMATH_API hmath_status hmath_ad_vjp(hmath_context *context, const hmath_ad_expr *const *expressions,
                                    size_t count, const double *values, size_t n,
                                    const double *direction, size_t direction_count, double *out,
                                    size_t capacity);
HMATH_API hmath_status hmath_ad_forward_jvp_result(hmath_context *context,
                                                   const hmath_ad_dual *const *expressions,
                                                   size_t count, const double *values, size_t n,
                                                   const double *direction, size_t direction_count,
                                                   double *out, size_t capacity);
/* metadata reports logical value count and rank. For Dual count is two;
 * gradient state count is its length; tensors report elements and rank.
 * values_copy supports Dual [primal,tangent] and GradientState; shape_copy
 * supports ADTensor. tensor_values returns owned Expr references; release each.
 * Gradient/JVP/VJP/HVP outputs are flat logical lists; Hessian and Jacobian are
 * row-major. value_and_gradient writes [value, gradient...], complex_gradient
 * writes [real,imag], and forward_jvp_result writes [primals...,tangents...]. */
HMATH_API hmath_status hmath_ad_metadata(const hmath_ad_handle *value, size_t *count, size_t *rank);
HMATH_API hmath_status hmath_ad_values_copy(const hmath_ad_handle *value, double *out,
                                            size_t capacity);
HMATH_API hmath_status hmath_ad_shape_copy(const hmath_ad_tensor *value, ptrdiff_t *out,
                                           size_t capacity);
HMATH_API hmath_status hmath_ad_tensor_values(const hmath_ad_tensor *value, hmath_ad_expr **out,
                                              size_t capacity);
/* Logical expression list is represented as a rank-one ADTensor. */
HMATH_API hmath_status hmath_ad_differentiable_step(hmath_context *context, double rate,
                                                    const hmath_ad_expr *expression,
                                                    const hmath_ad_expr *const *points,
                                                    size_t count, hmath_ad_tensor **out);
/* Custom callbacks are synchronous/reentrant and must not throw across C.
 * Keep function pointers, userdata and borrowed error strings alive until all
 * derived expression/graph/tensor handles are released. HMATH_MATH_ERROR plus
 * an original MathError Show message propagates without changing its payload.
 * Other nonzero callback statuses propagate as binding failures.
 * Rule callbacks write at most partial_capacity values and report actual arity
 * in partial_count. Wrong arity is checked by the original reverse evaluator;
 * value-only graph evaluation retains its original behavior.
 * Builder inputs are borrowed; return one owned expression reference. Retain an
 * input before returning it. Callback-created expressions may themselves hold
 * callbacks, whose userdata must follow the same transitive lifetime rule. */
typedef hmath_status (*hmath_ad_rule_callback)(const double *values, size_t count, void *userdata,
                                               double *value, double *partials,
                                               size_t partial_capacity, size_t *partial_count,
                                               const char **error_message);
typedef hmath_status (*hmath_ad_unary_callback)(double value, void *userdata, double *result,
                                                const char **error_message);
typedef hmath_status (*hmath_ad_builder_callback)(const hmath_ad_expr *const *values, size_t count,
                                                  void *userdata, hmath_ad_expr **result,
                                                  const char **error_message);
HMATH_API hmath_status hmath_ad_custom_operation(hmath_context *context,
                                                 hmath_ad_rule_callback callback, void *userdata,
                                                 const hmath_ad_expr *const *values, size_t count,
                                                 hmath_ad_expr **out);
HMATH_API hmath_status hmath_ad_custom_unary(hmath_context *context,
                                             hmath_ad_unary_callback function,
                                             hmath_ad_unary_callback derivative, void *userdata,
                                             const hmath_ad_expr *value, hmath_ad_expr **out);
HMATH_API hmath_status hmath_ad_checkpoint(hmath_context *context,
                                           hmath_ad_builder_callback callback, void *userdata,
                                           const hmath_ad_expr *const *values, size_t count,
                                           hmath_ad_expr **out);
/* Original Dual instances may nest to arbitrary depth over Double leaves.
 * Components must have equal scalar types/depth. dual_parts returns two owned
 * handles; a scalar leaf has depth zero and values_copy returns one Double.
 * A flat Dual has depth one and values_copy returns [primal,tangent]. Deeper
 * duals require dual_parts; their flat value count is zero. */
HMATH_API hmath_status hmath_ad_dual_nested(hmath_context *context, const hmath_ad_dual *primal,
                                            const hmath_ad_dual *tangent, hmath_ad_dual **out);
HMATH_API hmath_status hmath_ad_dual_depth(const hmath_ad_dual *value, size_t *out);
HMATH_API hmath_status hmath_ad_dual_parts(const hmath_ad_dual *value, hmath_ad_dual **out_primal,
                                           hmath_ad_dual **out_tangent);
/* Forward-mode leaf types use original Haskell instances without widening.
 * kind follows hmath_coefficient_type (0..15), plus20=Numeric.Dual and
 *21=Numeric.Quaternion. Every supported coefficient can be exported from a
 * shared Value into a depth-zero handle, then nested with dual_nested. The
 * original class dictionaries apply; unavailable Ord/Fractional/Floating
 * instances are rejected without conversion. Integer/Rational use signed
 * decimal strings, and scalar_text returns owned numerator/denominator strings
 * for exact scalar leaf handles (depth zero). Release both with string_free.
 * Exact values never pass through floating-point intermediates. Unsupported
 * class operations (Integer division, Rational exp, etc.) report InvalidArgument.
 * These leaf types can all nest through dual_nested. */
HMATH_API hmath_status hmath_ad_dual_create_f32(hmath_context *context, float primal, float tangent,
                                                hmath_ad_dual **out);
HMATH_API hmath_status hmath_ad_dual_create_integer(hmath_context *context, const char *primal,
                                                    const char *tangent, hmath_ad_dual **out);
HMATH_API hmath_status hmath_ad_dual_create_rational(
    hmath_context *context, const char *primal_numerator, const char *primal_denominator,
    const char *tangent_numerator, const char *tangent_denominator, hmath_ad_dual **out);
HMATH_API hmath_status hmath_ad_dual_kind(const hmath_ad_dual *value, int *out);
HMATH_API hmath_status hmath_ad_scalar_text(const hmath_ad_dual *value, char **numerator,
                                            char **denominator);
HMATH_API void hmath_ad_string_free(char *value);
/* Relations use original instances: Eq includes both fields; Ord compares
 * primal fields only, recursively. operation: 0=Eq,1=LT,2=LE,3=GT,4=GE. */
HMATH_API hmath_status hmath_ad_dual_relation(hmath_context *context, int operation,
                                              const hmath_ad_dual *left, const hmath_ad_dual *right,
                                              int *out);
/* Additive shared-Value interchange for original AD Expr/ADTensor/Dual values.
 * Each conversion returns independent ownership and preserves the original
 * object/type. Scalar Dual component leaves use ordinary exact typed Values.
 * Keep callback pointers/userdata alive transitively through derived handles. */
HMATH_API hmath_status hmath_ad_value_import(hmath_context *context,
                                             const hmath_ad_handle *input,
                                             hmath_value **out);
HMATH_API hmath_status hmath_ad_value_export(hmath_context *context,
                                             const hmath_value *input,
                                             hmath_ad_handle **out);
/* Checked additive callbacks preserve full status11/12/13 structured errors.
 * Returning11 from a custom rule supplies a genuine original Left MathError;
 * other failures abort after cleanup. Pure unary/checkpoint callback failures
 * relay at the outer boundary. Function/userdata and error buffers stay valid
 * until consumed; derived expressions retain the same borrowed-callback lifetime
 * contract as the legacy constructors. written is the logical derivative count;
 * never write more than capacity partials (wrong counts retain source errors). */
typedef hmath_status (*hmath_ad_rule_checked_callback)(
    const double *values, size_t count, void *userdata, double *value,
    double *partials, size_t capacity, size_t *written, hmath_callback_error *error);
typedef hmath_status (*hmath_ad_unary_checked_callback)(
    double value, void *userdata, double *out, hmath_callback_error *error);
typedef hmath_status (*hmath_ad_builder_checked_callback)(
    const hmath_ad_expr *const *inputs, size_t count, void *userdata,
    hmath_ad_expr **out, hmath_callback_error *error);
HMATH_API hmath_status hmath_ad_custom_operation_checked(
    hmath_context *, hmath_ad_rule_checked_callback, void *,
    const hmath_ad_expr *const *, size_t, hmath_ad_expr **);
HMATH_API hmath_status hmath_ad_custom_unary_checked(
    hmath_context *, hmath_ad_unary_checked_callback,
    hmath_ad_unary_checked_callback, void *, const hmath_ad_expr *, hmath_ad_expr **);
HMATH_API hmath_status hmath_ad_checkpoint_checked(
    hmath_context *, hmath_ad_builder_checked_callback, void *,
    const hmath_ad_expr *const *, size_t, hmath_ad_expr **);
#ifdef __cplusplus
}
#endif
#endif
