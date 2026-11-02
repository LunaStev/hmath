/* SPDX-License-Identifier: MPL-2.0 */
/* Generated; do not edit. */
#include "hmath_numerical.h"
#include "value_internal.h"
extern int hm_numerical_apply(int,void *const *,size_t,void **);
hmath_status hmath_calculus_estimate(hmath_context *context, const hmath_value *value, const hmath_value *error, const hmath_value *evaluations, hmath_value **out) {
    if (!out || !value || !error || !evaluations) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(error), hm_value_stable(evaluations)};
    int code=hm_numerical_apply(0,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_estimate_value(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(1,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_estimate_error(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(2,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_evaluations(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(3,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_tolerance(hmath_context *context, const hmath_value *absolute_tolerance, const hmath_value *relative_tolerance, const hmath_value *maximum_evaluations, hmath_value **out) {
    if (!out || !absolute_tolerance || !relative_tolerance || !maximum_evaluations) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(absolute_tolerance), hm_value_stable(relative_tolerance), hm_value_stable(maximum_evaluations)};
    int code=hm_numerical_apply(4,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_absolute_tolerance(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(5,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_relative_tolerance(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(6,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_maximum_evaluations(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(7,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_default_tolerance(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(8,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_forward(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(9,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_backward(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(10,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_central(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(11,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_trapezoidal(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(12,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_simpson(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(13,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_three_eighths(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(14,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_derivative(hmath_context *context, const hmath_value *method, const hmath_value *h, const hmath_value *f, const hmath_value *x, hmath_value **out) {
    if (!out || !method || !h || !f || !x) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(method), hm_value_stable(h), hm_value_stable(f), hm_value_stable(x)};
    int code=hm_numerical_apply(15,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_derivative_n(hmath_context *context, const hmath_value *order, const hmath_value *h, const hmath_value *f, const hmath_value *x, hmath_value **out) {
    if (!out || !order || !h || !f || !x) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(order), hm_value_stable(h), hm_value_stable(f), hm_value_stable(x)};
    int code=hm_numerical_apply(16,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_complex_derivative(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *x, hmath_value **out) {
    if (!out || !h || !f || !x) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(h), hm_value_stable(f), hm_value_stable(x)};
    int code=hm_numerical_apply(17,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_richardson(hmath_context *context, const hmath_value *tol, const hmath_value *initial, const hmath_value *f, const hmath_value *x, hmath_value **out) {
    if (!out || !tol || !initial || !f || !x) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(tol), hm_value_stable(initial), hm_value_stable(f), hm_value_stable(x)};
    int code=hm_numerical_apply(18,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_ridders(hmath_context *context, const hmath_value *tol, const hmath_value *initial, const hmath_value *f, const hmath_value *x, hmath_value **out) {
    if (!out || !tol || !initial || !f || !x) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(tol), hm_value_stable(initial), hm_value_stable(f), hm_value_stable(x)};
    int code=hm_numerical_apply(19,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_limit(hmath_context *context, const hmath_value *side, const hmath_value *tol, const hmath_value *initial, const hmath_value *f, const hmath_value *x, hmath_value **out) {
    if (!out || !side || !tol || !initial || !f || !x) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(side), hm_value_stable(tol), hm_value_stable(initial), hm_value_stable(f), hm_value_stable(x)};
    int code=hm_numerical_apply(20,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_partial_derivative(hmath_context *context, const hmath_value *i, const hmath_value *h, const hmath_value *f, const hmath_value *xs, hmath_value **out) {
    if (!out || !i || !h || !f || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(i), hm_value_stable(h), hm_value_stable(f), hm_value_stable(xs)};
    int code=hm_numerical_apply(21,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_gradient(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *xs, hmath_value **out) {
    if (!out || !h || !f || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(h), hm_value_stable(f), hm_value_stable(xs)};
    int code=hm_numerical_apply(22,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_jacobian(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *xs, hmath_value **out) {
    if (!out || !h || !f || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(h), hm_value_stable(f), hm_value_stable(xs)};
    int code=hm_numerical_apply(23,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_hessian(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *xs, hmath_value **out) {
    if (!out || !h || !f || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(h), hm_value_stable(f), hm_value_stable(xs)};
    int code=hm_numerical_apply(24,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_directional_derivative(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *x, const hmath_value *v, hmath_value **out) {
    if (!out || !h || !f || !x || !v) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(h), hm_value_stable(f), hm_value_stable(x), hm_value_stable(v)};
    int code=hm_numerical_apply(25,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_jvp(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *x, const hmath_value *v, hmath_value **out) {
    if (!out || !h || !f || !x || !v) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(h), hm_value_stable(f), hm_value_stable(x), hm_value_stable(v)};
    int code=hm_numerical_apply(26,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_vjp(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *x, const hmath_value *v, hmath_value **out) {
    if (!out || !h || !f || !x || !v) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(h), hm_value_stable(f), hm_value_stable(x), hm_value_stable(v)};
    int code=hm_numerical_apply(27,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_hvp(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *x, const hmath_value *v, hmath_value **out) {
    if (!out || !h || !f || !x || !v) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(h), hm_value_stable(f), hm_value_stable(x), hm_value_stable(v)};
    int code=hm_numerical_apply(28,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_divergence(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *x, hmath_value **out) {
    if (!out || !h || !f || !x) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(h), hm_value_stable(f), hm_value_stable(x)};
    int code=hm_numerical_apply(29,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_curl(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *x, hmath_value **out) {
    if (!out || !h || !f || !x) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(h), hm_value_stable(f), hm_value_stable(x)};
    int code=hm_numerical_apply(30,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_laplacian(hmath_context *context, const hmath_value *h, const hmath_value *f, const hmath_value *x, hmath_value **out) {
    if (!out || !h || !f || !x) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(h), hm_value_stable(f), hm_value_stable(x)};
    int code=hm_numerical_apply(31,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_integrate_composite(hmath_context *context, const hmath_value *method, const hmath_value *n, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out) {
    if (!out || !method || !n || !f || !a || !b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(method), hm_value_stable(n), hm_value_stable(f), hm_value_stable(a), hm_value_stable(b)};
    int code=hm_numerical_apply(32,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_romberg(hmath_context *context, const hmath_value *tol, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out) {
    if (!out || !tol || !f || !a || !b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(tol), hm_value_stable(f), hm_value_stable(a), hm_value_stable(b)};
    int code=hm_numerical_apply(33,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_gauss_legendre(hmath_context *context, const hmath_value *n, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out) {
    if (!out || !n || !f || !a || !b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(n), hm_value_stable(f), hm_value_stable(a), hm_value_stable(b)};
    int code=hm_numerical_apply(34,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_gauss_hermite(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_numerical_apply(35,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_gauss_laguerre(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_numerical_apply(36,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_gauss_chebyshev(hmath_context *context, const hmath_value *n, const hmath_value *f, hmath_value **out) {
    if (!out || !n || !f) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(n), hm_value_stable(f)};
    int code=hm_numerical_apply(37,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_gauss_kronrod(hmath_context *context, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out) {
    if (!out || !f || !a || !b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(f), hm_value_stable(a), hm_value_stable(b)};
    int code=hm_numerical_apply(38,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_adaptive_integrate(hmath_context *context, const hmath_value *tol, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out) {
    if (!out || !tol || !f || !a || !b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(tol), hm_value_stable(f), hm_value_stable(a), hm_value_stable(b)};
    int code=hm_numerical_apply(39,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_clenshaw_curtis(hmath_context *context, const hmath_value *n, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out) {
    if (!out || !n || !f || !a || !b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(n), hm_value_stable(f), hm_value_stable(a), hm_value_stable(b)};
    int code=hm_numerical_apply(40,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_tanh_sinh(hmath_context *context, const hmath_value *tol, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out) {
    if (!out || !tol || !f || !a || !b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(tol), hm_value_stable(f), hm_value_stable(a), hm_value_stable(b)};
    int code=hm_numerical_apply(41,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_integrate_infinite(hmath_context *context, const hmath_value *tol, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out) {
    if (!out || !tol || !f || !a || !b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(tol), hm_value_stable(f), hm_value_stable(a), hm_value_stable(b)};
    int code=hm_numerical_apply(42,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_integrate_oscillatory(hmath_context *context, const hmath_value *sine, const hmath_value *omega, const hmath_value *tol, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out) {
    if (!out || !sine || !omega || !tol || !f || !a || !b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(sine), hm_value_stable(omega), hm_value_stable(tol), hm_value_stable(f), hm_value_stable(a), hm_value_stable(b)};
    int code=hm_numerical_apply(43,arguments,6,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_integrate_nd(hmath_context *context, const hmath_value *panels, const hmath_value *budget, const hmath_value *f, const hmath_value *bounds, hmath_value **out) {
    if (!out || !panels || !budget || !f || !bounds) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(panels), hm_value_stable(budget), hm_value_stable(f), hm_value_stable(bounds)};
    int code=hm_numerical_apply(44,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_monte_carlo(hmath_context *context, const hmath_value *seed, const hmath_value *n, const hmath_value *f, const hmath_value *bounds, hmath_value **out) {
    if (!out || !seed || !n || !f || !bounds) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(seed), hm_value_stable(n), hm_value_stable(f), hm_value_stable(bounds)};
    int code=hm_numerical_apply(45,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_quasi_monte_carlo(hmath_context *context, const hmath_value *n, const hmath_value *f, const hmath_value *bounds, hmath_value **out) {
    if (!out || !n || !f || !bounds) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(n), hm_value_stable(f), hm_value_stable(bounds)};
    int code=hm_numerical_apply(46,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_cumulative_integral(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(47,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_path_integral(hmath_context *context, const hmath_value *tol, const hmath_value *curve, const hmath_value *tangent, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out) {
    if (!out || !tol || !curve || !tangent || !f || !a || !b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(tol), hm_value_stable(curve), hm_value_stable(tangent), hm_value_stable(f), hm_value_stable(a), hm_value_stable(b)};
    int code=hm_numerical_apply(48,arguments,6,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_line_integral(hmath_context *context, const hmath_value *tol, const hmath_value *curve, const hmath_value *tangent, const hmath_value *field, const hmath_value *a, const hmath_value *b, hmath_value **out) {
    if (!out || !tol || !curve || !tangent || !field || !a || !b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(tol), hm_value_stable(curve), hm_value_stable(tangent), hm_value_stable(field), hm_value_stable(a), hm_value_stable(b)};
    int code=hm_numerical_apply(49,arguments,6,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_surface_integral(hmath_context *context, const hmath_value *panels, const hmath_value *budget, const hmath_value *surface, const hmath_value *du, const hmath_value *dv, const hmath_value *f, const hmath_value *bounds, hmath_value **out) {
    if (!out || !panels || !budget || !surface || !du || !dv || !f || !bounds) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(panels), hm_value_stable(budget), hm_value_stable(surface), hm_value_stable(du), hm_value_stable(dv), hm_value_stable(f), hm_value_stable(bounds)};
    int code=hm_numerical_apply(50,arguments,7,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_calculus_volume_integral(hmath_context *context, const hmath_value *panels, const hmath_value *budget, const hmath_value *f, const hmath_value *bounds, hmath_value **out) {
    if (!out || !panels || !budget || !f || !bounds) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(panels), hm_value_stable(budget), hm_value_stable(f), hm_value_stable(bounds)};
    int code=hm_numerical_apply(51,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_root_options(hmath_context *context, const hmath_value *root_max_iterations, const hmath_value *root_max_evaluations, const hmath_value *root_tolerance, const hmath_value *root_step_tolerance, hmath_value **out) {
    if (!out || !root_max_iterations || !root_max_evaluations || !root_tolerance || !root_step_tolerance) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(root_max_iterations), hm_value_stable(root_max_evaluations), hm_value_stable(root_tolerance), hm_value_stable(root_step_tolerance)};
    int code=hm_numerical_apply(52,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_root_max_iterations(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(53,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_root_max_evaluations(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(54,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_root_tolerance(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(55,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_root_step_tolerance(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(56,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_default_root_options(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(57,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_root_result(hmath_context *context, const hmath_value *root_value, const hmath_value *root_residual, const hmath_value *root_error_bound, const hmath_value *root_iterations, const hmath_value *root_evaluations, hmath_value **out) {
    if (!out || !root_value || !root_residual || !root_error_bound || !root_iterations || !root_evaluations) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(root_value), hm_value_stable(root_residual), hm_value_stable(root_error_bound), hm_value_stable(root_iterations), hm_value_stable(root_evaluations)};
    int code=hm_numerical_apply(58,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_root_value(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(59,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_root_residual(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(60,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_root_error_bound(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(61,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_root_iterations(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(62,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_root_evaluations(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(63,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_bisection(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(64,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_regula_falsi(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(65,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_illinois(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(66,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_brent(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(67,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_ridder(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(68,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_newton(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(69,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_halley(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(70,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_householder3(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(71,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_picard(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(72,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_aitken(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(73,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_steffensen_fixed(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(74,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_multivariate_newton(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(75,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_newton_trust_region(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(76,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_broyden(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(77,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_system_root_result(hmath_context *context, const hmath_value *system_root, const hmath_value *system_residual, const hmath_value *system_iterations, const hmath_value *system_evaluations, hmath_value **out) {
    if (!out || !system_root || !system_residual || !system_iterations || !system_evaluations) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(system_root), hm_value_stable(system_residual), hm_value_stable(system_iterations), hm_value_stable(system_evaluations)};
    int code=hm_numerical_apply(78,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_system_root(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(79,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_system_residual(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(80,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_system_iterations(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(81,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_system_evaluations(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(82,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_bracket(hmath_context *context, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out) {
    if (!out || !f || !a || !b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(f), hm_value_stable(a), hm_value_stable(b)};
    int code=hm_numerical_apply(83,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_solve_bracket(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, hmath_value **out) {
    if (!out || !value || !value2 || !value3 || !value4) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3), hm_value_stable(value4)};
    int code=hm_numerical_apply(84,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_bracket_scan(hmath_context *context, const hmath_value *o, const hmath_value *f, const hmath_value *a, const hmath_value *b, const hmath_value *cells, hmath_value **out) {
    if (!out || !o || !f || !a || !b || !cells) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(o), hm_value_stable(f), hm_value_stable(a), hm_value_stable(b), hm_value_stable(cells)};
    int code=hm_numerical_apply(85,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_isolate_intervals(hmath_context *context, const hmath_value *o, const hmath_value *f, const hmath_value *a, const hmath_value *b, const hmath_value *cells, hmath_value **out) {
    if (!out || !o || !f || !a || !b || !cells) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(o), hm_value_stable(f), hm_value_stable(a), hm_value_stable(b), hm_value_stable(cells)};
    int code=hm_numerical_apply(86,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_solve_derivative(hmath_context *context, const hmath_value *method, const hmath_value *o, const hmath_value *f, const hmath_value *derivatives, const hmath_value *x0, hmath_value **out) {
    if (!out || !method || !o || !f || !derivatives || !x0) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(method), hm_value_stable(o), hm_value_stable(f), hm_value_stable(derivatives), hm_value_stable(x0)};
    int code=hm_numerical_apply(87,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_secant(hmath_context *context, const hmath_value *o, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out) {
    if (!out || !o || !f || !a || !b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(o), hm_value_stable(f), hm_value_stable(a), hm_value_stable(b)};
    int code=hm_numerical_apply(88,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_steffensen(hmath_context *context, const hmath_value *o, const hmath_value *f, const hmath_value *x0, hmath_value **out) {
    if (!out || !o || !f || !x0) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(o), hm_value_stable(f), hm_value_stable(x0)};
    int code=hm_numerical_apply(89,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_fixed_point(hmath_context *context, const hmath_value *method, const hmath_value *o, const hmath_value *g, const hmath_value *x0, hmath_value **out) {
    if (!out || !method || !o || !g || !x0) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(method), hm_value_stable(o), hm_value_stable(g), hm_value_stable(x0)};
    int code=hm_numerical_apply(90,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_anderson(hmath_context *context, const hmath_value *depth, const hmath_value *regularization, const hmath_value *o, const hmath_value *g, const hmath_value *x0, hmath_value **out) {
    if (!out || !depth || !regularization || !o || !g || !x0) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(depth), hm_value_stable(regularization), hm_value_stable(o), hm_value_stable(g), hm_value_stable(x0)};
    int code=hm_numerical_apply(91,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_solve_system(hmath_context *context, const hmath_value *method, const hmath_value *o, const hmath_value *f, const hmath_value *jac, const hmath_value *x0, hmath_value **out) {
    if (!out || !method || !o || !f || !jac || !x0) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(method), hm_value_stable(o), hm_value_stable(f), hm_value_stable(jac), hm_value_stable(x0)};
    int code=hm_numerical_apply(92,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_polynomial_roots(hmath_context *context, const hmath_value *o, const hmath_value *p, hmath_value **out) {
    if (!out || !o || !p) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(o), hm_value_stable(p)};
    int code=hm_numerical_apply(93,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_root_real_polynomial_roots(hmath_context *context, const hmath_value *budget, const hmath_value *tolerance, const hmath_value *p, hmath_value **out) {
    if (!out || !budget || !tolerance || !p) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(budget), hm_value_stable(tolerance), hm_value_stable(p)};
    int code=hm_numerical_apply(94,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_euler(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(95,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_heun(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(96,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_midpoint(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(97,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_rk2(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(98,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_rk4(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(99,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_rk23(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(100,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_rk45(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(101,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_dormand_prince(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(102,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_dop853(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(103,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_adams_bashforth(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(104,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_adams_moulton(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(105,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_predictor_corrector(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(106,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_backward_euler(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(107,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_bdf(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(108,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_radau(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(109,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_rosenbrock(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(110,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_ode_options(hmath_context *context, const hmath_value *ode_absolute_tolerance, const hmath_value *ode_relative_tolerance, const hmath_value *initial_step, const hmath_value *minimum_step, const hmath_value *maximum_step, const hmath_value *maximum_steps, const hmath_value *newton_iterations, hmath_value **out) {
    if (!out || !ode_absolute_tolerance || !ode_relative_tolerance || !initial_step || !minimum_step || !maximum_step || !maximum_steps || !newton_iterations) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(ode_absolute_tolerance), hm_value_stable(ode_relative_tolerance), hm_value_stable(initial_step), hm_value_stable(minimum_step), hm_value_stable(maximum_step), hm_value_stable(maximum_steps), hm_value_stable(newton_iterations)};
    int code=hm_numerical_apply(111,arguments,7,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_ode_absolute_tolerance(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(112,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_ode_relative_tolerance(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(113,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_initial_step(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(114,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_minimum_step(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(115,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_maximum_step(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(116,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_maximum_steps(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(117,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_newton_iterations(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(118,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_default_ode_options(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(119,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_trajectory(hmath_context *context, const hmath_value *trajectory_times, const hmath_value *trajectory_states, const hmath_value *trajectory_derivatives, hmath_value **out) {
    if (!out || !trajectory_times || !trajectory_states || !trajectory_derivatives) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(trajectory_times), hm_value_stable(trajectory_states), hm_value_stable(trajectory_derivatives)};
    int code=hm_numerical_apply(120,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_trajectory_times(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(121,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_trajectory_states(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(122,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_trajectory_derivatives(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(123,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_solve_ivp(hmath_context *context, const hmath_value *method, const hmath_value *options, const hmath_value *panels, const hmath_value *f, const hmath_value *start, const hmath_value *end, const hmath_value *initial, hmath_value **out) {
    if (!out || !method || !options || !panels || !f || !start || !end || !initial) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(method), hm_value_stable(options), hm_value_stable(panels), hm_value_stable(f), hm_value_stable(start), hm_value_stable(end), hm_value_stable(initial)};
    int code=hm_numerical_apply(124,arguments,7,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_solve_adaptive(hmath_context *context, const hmath_value *method, const hmath_value *options, const hmath_value *f, const hmath_value *start, const hmath_value *end, const hmath_value *initial, hmath_value **out) {
    if (!out || !method || !options || !f || !start || !end || !initial) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(method), hm_value_stable(options), hm_value_stable(f), hm_value_stable(start), hm_value_stable(end), hm_value_stable(initial)};
    int code=hm_numerical_apply(125,arguments,6,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_interpolate_trajectory(hmath_context *context, const hmath_value *trajectory, const hmath_value *t, hmath_value **out) {
    if (!out || !trajectory || !t) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(trajectory), hm_value_stable(t)};
    int code=hm_numerical_apply(126,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_any_direction(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(127,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_rising(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(128,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_falling(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(129,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_event(hmath_context *context, const hmath_value *event_time, const hmath_value *event_state, hmath_value **out) {
    if (!out || !event_time || !event_state) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(event_time), hm_value_stable(event_state)};
    int code=hm_numerical_apply(130,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_event_time(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(131,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_event_state(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(132,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_locate_events(hmath_context *context, const hmath_value *direction, const hmath_value *tolerance, const hmath_value *function, const hmath_value *trajectory, hmath_value **out) {
    if (!out || !direction || !tolerance || !function || !trajectory) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(direction), hm_value_stable(tolerance), hm_value_stable(function), hm_value_stable(trajectory)};
    int code=hm_numerical_apply(133,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_solve_boundary(hmath_context *context, const hmath_value *method, const hmath_value *options, const hmath_value *panels, const hmath_value *f, const hmath_value *boundary, const hmath_value *start, const hmath_value *end, const hmath_value *guess, hmath_value **out) {
    if (!out || !method || !options || !panels || !f || !boundary || !start || !end || !guess) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(method), hm_value_stable(options), hm_value_stable(panels), hm_value_stable(f), hm_value_stable(boundary), hm_value_stable(start), hm_value_stable(end), hm_value_stable(guess)};
    int code=hm_numerical_apply(134,arguments,8,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_solve_dae(hmath_context *context, const hmath_value *options, const hmath_value *panels, const hmath_value *residual, const hmath_value *start, const hmath_value *end, const hmath_value *initial, const hmath_value *initial_derivative, hmath_value **out) {
    if (!out || !options || !panels || !residual || !start || !end || !initial || !initial_derivative) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(options), hm_value_stable(panels), hm_value_stable(residual), hm_value_stable(start), hm_value_stable(end), hm_value_stable(initial), hm_value_stable(initial_derivative)};
    int code=hm_numerical_apply(135,arguments,7,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_symplectic_euler(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(136,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_verlet(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(137,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_leapfrog(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(138,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_solve_hamiltonian(hmath_context *context, const hmath_value *method, const hmath_value *panels, const hmath_value *velocity, const hmath_value *force, const hmath_value *start, const hmath_value *end, const hmath_value *q0, const hmath_value *p0, hmath_value **out) {
    if (!out || !method || !panels || !velocity || !force || !start || !end || !q0 || !p0) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(method), hm_value_stable(panels), hm_value_stable(velocity), hm_value_stable(force), hm_value_stable(start), hm_value_stable(end), hm_value_stable(q0), hm_value_stable(p0)};
    int code=hm_numerical_apply(139,arguments,8,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_solve_nystrom(hmath_context *context, const hmath_value *panels, const hmath_value *acceleration, const hmath_value *start, const hmath_value *end, const hmath_value *q0, const hmath_value *v0, hmath_value **out) {
    if (!out || !panels || !acceleration || !start || !end || !q0 || !v0) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(panels), hm_value_stable(acceleration), hm_value_stable(start), hm_value_stable(end), hm_value_stable(q0), hm_value_stable(v0)};
    int code=hm_numerical_apply(140,arguments,6,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_sensitivities(hmath_context *context, const hmath_value *method, const hmath_value *options, const hmath_value *panels, const hmath_value *h, const hmath_value *family, const hmath_value *parameters, const hmath_value *start, const hmath_value *end, const hmath_value *initial, hmath_value **out) {
    if (!out || !method || !options || !panels || !h || !family || !parameters || !start || !end || !initial) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(method), hm_value_stable(options), hm_value_stable(panels), hm_value_stable(h), hm_value_stable(family), hm_value_stable(parameters), hm_value_stable(start), hm_value_stable(end), hm_value_stable(initial)};
    int code=hm_numerical_apply(141,arguments,9,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_equilibrium(hmath_context *context, const hmath_value *options, const hmath_value *field, const hmath_value *guess, hmath_value **out) {
    if (!out || !options || !field || !guess) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(options), hm_value_stable(field), hm_value_stable(guess)};
    int code=hm_numerical_apply(142,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_phase_trajectories(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, const hmath_value *value6, const hmath_value *value7, hmath_value **out) {
    if (!out || !value || !value2 || !value3 || !value4 || !value5 || !value6 || !value7) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3), hm_value_stable(value4), hm_value_stable(value5), hm_value_stable(value6), hm_value_stable(value7)};
    int code=hm_numerical_apply(143,arguments,7,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_ode_lyapunov_exponents(hmath_context *context, const hmath_value *options, const hmath_value *panels, const hmath_value *difference_step, const hmath_value *f, const hmath_value *start, const hmath_value *end, const hmath_value *initial, hmath_value **out) {
    if (!out || !options || !panels || !difference_step || !f || !start || !end || !initial) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(options), hm_value_stable(panels), hm_value_stable(difference_step), hm_value_stable(f), hm_value_stable(start), hm_value_stable(end), hm_value_stable(initial)};
    int code=hm_numerical_apply(144,arguments,7,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_dirichlet(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(145,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_neumann(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(146,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_robin(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out) {
    if (!out || !value || !value2 || !value3) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3)};
    int code=hm_numerical_apply(147,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_periodic(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(148,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_finite_difference(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(149,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_finite_volume(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(150,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_finite_element(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_numerical_apply(151,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_pde_result(hmath_context *context, const hmath_value *pde_values, const hmath_value *pde_residual, const hmath_value *pde_error_estimate, hmath_value **out) {
    if (!out || !pde_values || !pde_residual || !pde_error_estimate) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(pde_values), hm_value_stable(pde_residual), hm_value_stable(pde_error_estimate)};
    int code=hm_numerical_apply(152,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_pde_values(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(153,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_pde_residual(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(154,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_pde_error_estimate(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(155,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_grid(hmath_context *context, const hmath_value *dims, const hmath_value *bounds, const hmath_value *periodic, hmath_value **out) {
    if (!out || !dims || !bounds || !periodic) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(dims), hm_value_stable(bounds), hm_value_stable(periodic)};
    int code=hm_numerical_apply(156,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_grid_shape(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(157,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_grid_spacing(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(158,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_flatten_index(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_numerical_apply(159,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_unflatten_index(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_numerical_apply(160,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_grid_coordinates(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(161,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_assemble_pde(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, hmath_value **out) {
    if (!out || !value || !value2 || !value3 || !value4 || !value5) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3), hm_value_stable(value4), hm_value_stable(value5)};
    int code=hm_numerical_apply(162,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_pde_stiffness(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(163,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_pde_mass(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(164,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_pde_boundary_load(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_numerical_apply(165,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_solve_elliptic(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_numerical_apply(166,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_poisson(hmath_context *context, const hmath_value *method, const hmath_value *g, const hmath_value *bc, const hmath_value *forcing, hmath_value **out) {
    if (!out || !method || !g || !bc || !forcing) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(method), hm_value_stable(g), hm_value_stable(bc), hm_value_stable(forcing)};
    int code=hm_numerical_apply(167,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_laplace(hmath_context *context, const hmath_value *method, const hmath_value *g, const hmath_value *bc, hmath_value **out) {
    if (!out || !method || !g || !bc) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(method), hm_value_stable(g), hm_value_stable(bc)};
    int code=hm_numerical_apply(168,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_helmholtz(hmath_context *context, const hmath_value *method, const hmath_value *g, const hmath_value *bc, const hmath_value *k, const hmath_value *forcing, hmath_value **out) {
    if (!out || !method || !g || !bc || !k || !forcing) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(method), hm_value_stable(g), hm_value_stable(bc), hm_value_stable(k), hm_value_stable(forcing)};
    int code=hm_numerical_apply(169,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_spatial_gradient(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_numerical_apply(170,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_laplacian_stencil(hmath_context *context, const hmath_value *g, const hmath_value *bc, const hmath_value *values, hmath_value **out) {
    if (!out || !g || !bc || !values) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(g), hm_value_stable(bc), hm_value_stable(values)};
    int code=hm_numerical_apply(171,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_spectral_derivative(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, hmath_value **out) {
    if (!out || !value || !value2 || !value3 || !value4) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3), hm_value_stable(value4)};
    int code=hm_numerical_apply(172,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_spectral_laplacian(hmath_context *context, const hmath_value *g, const hmath_value *values, hmath_value **out) {
    if (!out || !g || !values) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(g), hm_value_stable(values)};
    int code=hm_numerical_apply(173,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_spectral_poisson(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out) {
    if (!out || !value || !value2 || !value3) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3)};
    int code=hm_numerical_apply(174,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_pseudo_spectral_diffusion(hmath_context *context, const hmath_value *g, const hmath_value *kappas, const hmath_value *values, hmath_value **out) {
    if (!out || !g || !kappas || !values) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(g), hm_value_stable(kappas), hm_value_stable(values)};
    int code=hm_numerical_apply(175,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_method_of_lines(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, hmath_value **out) {
    if (!out || !value || !value2 || !value3 || !value4 || !value5) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3), hm_value_stable(value4), hm_value_stable(value5)};
    int code=hm_numerical_apply(176,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_heat(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, hmath_value **out) {
    if (!out || !value || !value2 || !value3 || !value4 || !value5) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3), hm_value_stable(value4), hm_value_stable(value5)};
    int code=hm_numerical_apply(177,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_diffusion(hmath_context *context, const hmath_value *method, const hmath_value *g, const hmath_value *bc, const hmath_value *kappas, const hmath_value *times, const hmath_value *initial, hmath_value **out) {
    if (!out || !method || !g || !bc || !kappas || !times || !initial) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(method), hm_value_stable(g), hm_value_stable(bc), hm_value_stable(kappas), hm_value_stable(times), hm_value_stable(initial)};
    int code=hm_numerical_apply(178,arguments,6,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_wave(hmath_context *context, const hmath_value *g, const hmath_value *speed, const hmath_value *times, const hmath_value *initial, const hmath_value *velocity, hmath_value **out) {
    if (!out || !g || !speed || !times || !initial || !velocity) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(g), hm_value_stable(speed), hm_value_stable(times), hm_value_stable(initial), hm_value_stable(velocity)};
    int code=hm_numerical_apply(179,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_advection(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, hmath_value **out) {
    if (!out || !value || !value2 || !value3 || !value4) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3), hm_value_stable(value4)};
    int code=hm_numerical_apply(180,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_advection_diffusion(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, hmath_value **out) {
    if (!out || !value || !value2 || !value3 || !value4 || !value5) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3), hm_value_stable(value4), hm_value_stable(value5)};
    int code=hm_numerical_apply(181,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_stability_limit(hmath_context *context, const hmath_value *g, const hmath_value *diffusivity, const hmath_value *velocity, hmath_value **out) {
    if (!out || !g || !diffusivity || !velocity) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(g), hm_value_stable(diffusivity), hm_value_stable(velocity)};
    int code=hm_numerical_apply(182,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_cfl_number(hmath_context *context, const hmath_value *g, const hmath_value *diffusivity, const hmath_value *velocity, const hmath_value *dt, hmath_value **out) {
    if (!out || !g || !diffusivity || !velocity || !dt) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(g), hm_value_stable(diffusivity), hm_value_stable(velocity), hm_value_stable(dt)};
    int code=hm_numerical_apply(183,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_pde_manufactured_error(hmath_context *context, const hmath_value *g, const hmath_value *exact, const hmath_value *values, hmath_value **out) {
    if (!out || !g || !exact || !values) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(g), hm_value_stable(exact), hm_value_stable(values)};
    int code=hm_numerical_apply(184,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
