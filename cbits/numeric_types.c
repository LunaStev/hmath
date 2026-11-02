/* SPDX-License-Identifier: MPL-2.0 */
/* Generated; do not edit. */
#include "hmath_numeric_types.h"
#include "numeric_internal.h"
#include "value_internal.h"
#include <stdlib.h>
extern int hm_numeric_types_clone(void *stable,void **out);
void hmath_numeric_types_retain(hmath_numeric_value *value) { hmath_value_retain(value); }
void hmath_numeric_types_release(hmath_numeric_value *value) { hmath_value_release(value); }
void hmath_numeric_types_buffer_free(void *value) { free(value); }
int hmath_numeric_types_kind(const hmath_numeric_value *value) { return value ? value->kind : 0; }
int hm_numeric_types_invoke(hmath_numeric_callback callback,void *userdata,void *input_stable,void **out) {
 hmath_numeric_value *temporary=NULL,*input=NULL,*output=NULL;
 hmath_status status=hm_value_begin(NULL,&temporary);
 if(status) { extern void hm_value_free(void *);hm_value_free(input_stable);return status; }
 temporary->stable=input_stable;
 status=hm_value_finish(temporary,0,&input);
 if(status) return status;
 status=callback(input,userdata,&output);
 if(!status && !output) status=hm_error(HMATH_INVALID_ARGUMENT,"callback returned NULL value");
 if(!status) status=(hmath_status)hm_numeric_types_clone(output->stable,out);
 if(output) hmath_value_release(output);
 hmath_value_release(input);
 return status;
}
extern int hm_numeric_types_type_name(void *value, void **out);
hmath_status hmath_numeric_types_type_name(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_type_name(value->stable, &result->stable), out);
}
extern int hm_numeric_types_binary(int operation, void *a, void *b, void **out);
hmath_status hmath_numeric_types_binary(hmath_context *context, int operation, const hmath_numeric_value *a, const hmath_numeric_value *b, hmath_numeric_value **out) {
 if(!a) return hm_error(HMATH_INVALID_ARGUMENT,"NULL a");
 if(!b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL b");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_binary(operation, a->stable, b->stable, &result->stable), out);
}
extern int hm_numeric_types_unary(int operation, void *value, void **out);
hmath_status hmath_numeric_types_unary(hmath_context *context, int operation, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_unary(operation, value->stable, &result->stable), out);
}
extern int hm_numeric_types_literal_integer(void *like, const char *value, void **out);
hmath_status hmath_numeric_types_literal_integer(hmath_context *context, const hmath_numeric_value *like, const char *value, hmath_numeric_value **out) {
 if(!like) return hm_error(HMATH_INVALID_ARGUMENT,"NULL like");
 if(!hm_decimal(value)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_literal_integer(like->stable, value, &result->stable), out);
}
extern int hm_numeric_types_literal_rational(void *like, const char *value_numerator, const char *value_denominator, void **out);
hmath_status hmath_numeric_types_literal_rational(hmath_context *context, const hmath_numeric_value *like, const char *value_numerator, const char *value_denominator, hmath_numeric_value **out) {
 if(!like) return hm_error(HMATH_INVALID_ARGUMENT,"NULL like");
 if(!hm_decimal(value_numerator)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 if(!hm_decimal(value_denominator)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 const char *valueDigit=value_denominator; if(*valueDigit=='-') ++valueDigit; while(*valueDigit=='0') ++valueDigit; if(!*valueDigit) return hm_error(HMATH_INVALID_ARGUMENT,"zero Rational denominator");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_literal_rational(like->stable, value_numerator, value_denominator, &result->stable), out);
}
extern int hm_numeric_types_integer_power(void *value, const char *power, void **out);
hmath_status hmath_numeric_types_integer_power(hmath_context *context, const hmath_numeric_value *value, const char *power, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!hm_decimal(power)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_integer_power(value->stable, power, &result->stable), out);
}
extern int hm_numeric_types_equal(void *a, void *b, void **out);
hmath_status hmath_numeric_types_equal(hmath_context *context, const hmath_numeric_value *a, const hmath_numeric_value *b, hmath_numeric_value **out) {
 if(!a) return hm_error(HMATH_INVALID_ARGUMENT,"NULL a");
 if(!b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL b");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_equal(a->stable, b->stable, &result->stable), out);
}
extern int hm_numeric_types_sequence_get(void *value, ptrdiff_t index, void **out);
hmath_status hmath_numeric_types_sequence_get(hmath_context *context, const hmath_numeric_value *value, ptrdiff_t index, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_sequence_get(value->stable, index, &result->stable), out);
}
extern int hm_numeric_types_round_rational(int mode, const char *value_numerator, const char *value_denominator, void **out);
hmath_status hmath_numeric_types_round_rational(hmath_context *context, int mode, const char *value_numerator, const char *value_denominator, hmath_numeric_value **out) {
 if(!hm_decimal(value_numerator)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 if(!hm_decimal(value_denominator)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 const char *valueDigit=value_denominator; if(*valueDigit=='-') ++valueDigit; while(*valueDigit=='0') ++valueDigit; if(!*valueDigit) return hm_error(HMATH_INVALID_ARGUMENT,"zero Rational denominator");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_round_rational(mode, value_numerator, value_denominator, &result->stable), out);
}
extern int hm_numeric_types_classify(void *value, void **out);
hmath_status hmath_numeric_types_classify(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_classify(value->stable, &result->stable), out);
}
extern int hm_numeric_types_frexp(void *value, void **out);
hmath_status hmath_numeric_types_frexp(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_frexp(value->stable, &result->stable), out);
}
extern int hm_numeric_types_numeric_limits(void *value, void **out);
hmath_status hmath_numeric_types_numeric_limits(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_numeric_limits(value->stable, &result->stable), out);
}
extern int hm_numeric_types_integer_limits(void *value, void **out);
hmath_status hmath_numeric_types_integer_limits(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_integer_limits(value->stable, &result->stable), out);
}
extern int hm_numeric_types_float16_limits(void **out);
hmath_status hmath_numeric_types_float16_limits(hmath_context *context, hmath_numeric_value **out) {
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_float16_limits(&result->stable), out);
}
extern int hm_numeric_types_bfloat16_limits(void **out);
hmath_status hmath_numeric_types_bfloat16_limits(hmath_context *context, hmath_numeric_value **out) {
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_bfloat16_limits(&result->stable), out);
}
extern int hm_numeric_types_numeric_limits_record(void *normal, void *subnormal, void *maximum_value, void *epsilon, ptrdiff_t digits, ptrdiff_t low, ptrdiff_t high, void **out);
hmath_status hmath_numeric_types_numeric_limits_record(hmath_context *context, const hmath_numeric_value *normal, const hmath_numeric_value *subnormal, const hmath_numeric_value *maximum_value, const hmath_numeric_value *epsilon, ptrdiff_t digits, ptrdiff_t low, ptrdiff_t high, hmath_numeric_value **out) {
 if(!normal) return hm_error(HMATH_INVALID_ARGUMENT,"NULL normal");
 if(!subnormal) return hm_error(HMATH_INVALID_ARGUMENT,"NULL subnormal");
 if(!maximum_value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL maximum_value");
 if(!epsilon) return hm_error(HMATH_INVALID_ARGUMENT,"NULL epsilon");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_numeric_limits_record(normal->stable, subnormal->stable, maximum_value->stable, epsilon->stable, digits, low, high, &result->stable), out);
}
extern int hm_numeric_types_minimum_normal(void *value, void **out);
hmath_status hmath_numeric_types_minimum_normal(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_minimum_normal(value->stable, &result->stable), out);
}
extern int hm_numeric_types_minimum_subnormal(void *value, void **out);
hmath_status hmath_numeric_types_minimum_subnormal(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_minimum_subnormal(value->stable, &result->stable), out);
}
extern int hm_numeric_types_maximum_finite(void *value, void **out);
hmath_status hmath_numeric_types_maximum_finite(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_maximum_finite(value->stable, &result->stable), out);
}
extern int hm_numeric_types_machine_epsilon(void *value, void **out);
hmath_status hmath_numeric_types_machine_epsilon(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_machine_epsilon(value->stable, &result->stable), out);
}
extern int hm_numeric_types_significand_digits(void *value, void **out);
hmath_status hmath_numeric_types_significand_digits(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_significand_digits(value->stable, &result->stable), out);
}
extern int hm_numeric_types_minimum_exponent(void *value, void **out);
hmath_status hmath_numeric_types_minimum_exponent(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_minimum_exponent(value->stable, &result->stable), out);
}
extern int hm_numeric_types_maximum_exponent(void *value, void **out);
hmath_status hmath_numeric_types_maximum_exponent(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_maximum_exponent(value->stable, &result->stable), out);
}
extern int hm_numeric_types_safe_integral_cast(void *value, int dtype, void **out);
hmath_status hmath_numeric_types_safe_integral_cast(hmath_context *context, const hmath_numeric_value *value, int dtype, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_safe_integral_cast(value->stable, dtype, &result->stable), out);
}
extern int hm_numeric_types_saturating_cast(void *value, int dtype, void **out);
hmath_status hmath_numeric_types_saturating_cast(hmath_context *context, const hmath_numeric_value *value, int dtype, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_saturating_cast(value->stable, dtype, &result->stable), out);
}
extern int hm_numeric_types_real_to_integral(int mode, void *value, int dtype, void **out);
hmath_status hmath_numeric_types_real_to_integral(hmath_context *context, int mode, const hmath_numeric_value *value, int dtype, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_real_to_integral(mode, value->stable, dtype, &result->stable), out);
}
extern int hm_numeric_types_narrow_float(void *value, int dtype, void **out);
hmath_status hmath_numeric_types_narrow_float(hmath_context *context, const hmath_numeric_value *value, int dtype, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_narrow_float(value->stable, dtype, &result->stable), out);
}
extern int hm_numeric_types_float16(int mode, double value, void **out);
hmath_status hmath_numeric_types_float16(hmath_context *context, int mode, double value, hmath_numeric_value **out) {
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_float16(mode, value, &result->stable), out);
}
extern int hm_numeric_types_bfloat16(int mode, double value, void **out);
hmath_status hmath_numeric_types_bfloat16(hmath_context *context, int mode, double value, hmath_numeric_value **out) {
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_bfloat16(mode, value, &result->stable), out);
}
extern int hm_numeric_types_float16_from_bits(uint16_t bits, void **out);
hmath_status hmath_numeric_types_float16_from_bits(hmath_context *context, uint16_t bits, hmath_numeric_value **out) {
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_float16_from_bits(bits, &result->stable), out);
}
extern int hm_numeric_types_bfloat16_from_bits(uint16_t bits, void **out);
hmath_status hmath_numeric_types_bfloat16_from_bits(hmath_context *context, uint16_t bits, hmath_numeric_value **out) {
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_bfloat16_from_bits(bits, &result->stable), out);
}
extern int hm_numeric_types_float16_bits(void *value, void **out);
hmath_status hmath_numeric_types_float16_bits(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_float16_bits(value->stable, &result->stable), out);
}
extern int hm_numeric_types_bfloat16_bits(void *value, void **out);
hmath_status hmath_numeric_types_bfloat16_bits(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_bfloat16_bits(value->stable, &result->stable), out);
}
extern int hm_numeric_types_from_float16(void *value, void **out);
hmath_status hmath_numeric_types_from_float16(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_from_float16(value->stable, &result->stable), out);
}
extern int hm_numeric_types_from_bfloat16(void *value, void **out);
hmath_status hmath_numeric_types_from_bfloat16(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_from_bfloat16(value->stable, &result->stable), out);
}
extern int hm_numeric_types_rounded(void *value, const int *flags, size_t flags_count, void **out);
hmath_status hmath_numeric_types_rounded(hmath_context *context, const hmath_numeric_value *value, const int *flags, size_t flags_count, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(flags_count>(size_t)PTRDIFF_MAX/sizeof(int) || (flags_count && !flags)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid array span");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_rounded(value->stable, flags, flags_count, &result->stable), out);
}
extern int hm_numeric_types_rounded_value(void *value, void **out);
hmath_status hmath_numeric_types_rounded_value(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_rounded_value(value->stable, &result->stable), out);
}
extern int hm_numeric_types_numerical_exceptions(void *value, void **out);
hmath_status hmath_numeric_types_numerical_exceptions(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_numerical_exceptions(value->stable, &result->stable), out);
}
extern int hm_numeric_types_big_float(ptrdiff_t precision, int mode, const char *value_numerator, const char *value_denominator, void **out);
hmath_status hmath_numeric_types_big_float(hmath_context *context, ptrdiff_t precision, int mode, const char *value_numerator, const char *value_denominator, hmath_numeric_value **out) {
 if(!hm_decimal(value_numerator)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 if(!hm_decimal(value_denominator)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 const char *valueDigit=value_denominator; if(*valueDigit=='-') ++valueDigit; while(*valueDigit=='0') ++valueDigit; if(!*valueDigit) return hm_error(HMATH_INVALID_ARGUMENT,"zero Rational denominator");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_big_float(precision, mode, value_numerator, value_denominator, &result->stable), out);
}
extern int hm_numeric_types_extended(const char *value_numerator, const char *value_denominator, void **out);
hmath_status hmath_numeric_types_extended(hmath_context *context, const char *value_numerator, const char *value_denominator, hmath_numeric_value **out) {
 if(!hm_decimal(value_numerator)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 if(!hm_decimal(value_denominator)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 const char *valueDigit=value_denominator; if(*valueDigit=='-') ++valueDigit; while(*valueDigit=='0') ++valueDigit; if(!*valueDigit) return hm_error(HMATH_INVALID_ARGUMENT,"zero Rational denominator");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_extended(value_numerator, value_denominator, &result->stable), out);
}
extern int hm_numeric_types_big_precision(void *value, void **out);
hmath_status hmath_numeric_types_big_precision(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_big_precision(value->stable, &result->stable), out);
}
extern int hm_numeric_types_big_rational(void *value, void **out);
hmath_status hmath_numeric_types_big_rational(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_big_rational(value->stable, &result->stable), out);
}
extern int hm_numeric_types_big_to_double(void *value, void **out);
hmath_status hmath_numeric_types_big_to_double(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_big_to_double(value->stable, &result->stable), out);
}
extern int hm_numeric_types_big_add(void *a, void *b, void **out);
hmath_status hmath_numeric_types_big_add(hmath_context *context, const hmath_numeric_value *a, const hmath_numeric_value *b, hmath_numeric_value **out) {
 if(!a) return hm_error(HMATH_INVALID_ARGUMENT,"NULL a");
 if(!b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL b");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_big_add(a->stable, b->stable, &result->stable), out);
}
extern int hm_numeric_types_big_subtract(void *a, void *b, void **out);
hmath_status hmath_numeric_types_big_subtract(hmath_context *context, const hmath_numeric_value *a, const hmath_numeric_value *b, hmath_numeric_value **out) {
 if(!a) return hm_error(HMATH_INVALID_ARGUMENT,"NULL a");
 if(!b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL b");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_big_subtract(a->stable, b->stable, &result->stable), out);
}
extern int hm_numeric_types_big_multiply(void *a, void *b, void **out);
hmath_status hmath_numeric_types_big_multiply(hmath_context *context, const hmath_numeric_value *a, const hmath_numeric_value *b, hmath_numeric_value **out) {
 if(!a) return hm_error(HMATH_INVALID_ARGUMENT,"NULL a");
 if(!b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL b");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_big_multiply(a->stable, b->stable, &result->stable), out);
}
extern int hm_numeric_types_big_divide(void *a, void *b, void **out);
hmath_status hmath_numeric_types_big_divide(hmath_context *context, const hmath_numeric_value *a, const hmath_numeric_value *b, hmath_numeric_value **out) {
 if(!a) return hm_error(HMATH_INVALID_ARGUMENT,"NULL a");
 if(!b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL b");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_big_divide(a->stable, b->stable, &result->stable), out);
}
extern int hm_numeric_types_big_sqrt(void *value, void **out);
hmath_status hmath_numeric_types_big_sqrt(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_big_sqrt(value->stable, &result->stable), out);
}
extern int hm_numeric_types_big_exp(void *value, void **out);
hmath_status hmath_numeric_types_big_exp(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_big_exp(value->stable, &result->stable), out);
}
extern int hm_numeric_types_big_log(void *value, void **out);
hmath_status hmath_numeric_types_big_log(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_big_log(value->stable, &result->stable), out);
}
extern int hm_numeric_types_mixed_add(void *a, double b, void **out);
hmath_status hmath_numeric_types_mixed_add(hmath_context *context, const hmath_numeric_value *a, double b, hmath_numeric_value **out) {
 if(!a) return hm_error(HMATH_INVALID_ARGUMENT,"NULL a");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_mixed_add(a->stable, b, &result->stable), out);
}
extern int hm_numeric_types_mixed_multiply(void *a, double b, void **out);
hmath_status hmath_numeric_types_mixed_multiply(hmath_context *context, const hmath_numeric_value *a, double b, hmath_numeric_value **out) {
 if(!a) return hm_error(HMATH_INVALID_ARGUMENT,"NULL a");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_mixed_multiply(a->stable, b, &result->stable), out);
}
extern int hm_numeric_types_fixed(ptrdiff_t scale, int mode, const char *value_numerator, const char *value_denominator, void **out);
hmath_status hmath_numeric_types_fixed(hmath_context *context, ptrdiff_t scale, int mode, const char *value_numerator, const char *value_denominator, hmath_numeric_value **out) {
 if(!hm_decimal(value_numerator)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 if(!hm_decimal(value_denominator)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 const char *valueDigit=value_denominator; if(*valueDigit=='-') ++valueDigit; while(*valueDigit=='0') ++valueDigit; if(!*valueDigit) return hm_error(HMATH_INVALID_ARGUMENT,"zero Rational denominator");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_fixed(scale, mode, value_numerator, value_denominator, &result->stable), out);
}
extern int hm_numeric_types_fixed_rational(void *value, void **out);
hmath_status hmath_numeric_types_fixed_rational(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_fixed_rational(value->stable, &result->stable), out);
}
extern int hm_numeric_types_fixed_add(void *a, void *b, void **out);
hmath_status hmath_numeric_types_fixed_add(hmath_context *context, const hmath_numeric_value *a, const hmath_numeric_value *b, hmath_numeric_value **out) {
 if(!a) return hm_error(HMATH_INVALID_ARGUMENT,"NULL a");
 if(!b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL b");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_fixed_add(a->stable, b->stable, &result->stable), out);
}
extern int hm_numeric_types_fixed_multiply(int mode, void *a, void *b, void **out);
hmath_status hmath_numeric_types_fixed_multiply(hmath_context *context, int mode, const hmath_numeric_value *a, const hmath_numeric_value *b, hmath_numeric_value **out) {
 if(!a) return hm_error(HMATH_INVALID_ARGUMENT,"NULL a");
 if(!b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL b");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_fixed_multiply(mode, a->stable, b->stable, &result->stable), out);
}
extern int hm_numeric_types_fixed_divide(int mode, void *a, void *b, void **out);
hmath_status hmath_numeric_types_fixed_divide(hmath_context *context, int mode, const hmath_numeric_value *a, const hmath_numeric_value *b, hmath_numeric_value **out) {
 if(!a) return hm_error(HMATH_INVALID_ARGUMENT,"NULL a");
 if(!b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL b");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_fixed_divide(mode, a->stable, b->stable, &result->stable), out);
}
extern int hm_numeric_types_decimal(ptrdiff_t scale, int mode, const char *value_numerator, const char *value_denominator, void **out);
hmath_status hmath_numeric_types_decimal(hmath_context *context, ptrdiff_t scale, int mode, const char *value_numerator, const char *value_denominator, hmath_numeric_value **out) {
 if(!hm_decimal(value_numerator)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 if(!hm_decimal(value_denominator)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 const char *valueDigit=value_denominator; if(*valueDigit=='-') ++valueDigit; while(*valueDigit=='0') ++valueDigit; if(!*valueDigit) return hm_error(HMATH_INVALID_ARGUMENT,"zero Rational denominator");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_decimal(scale, mode, value_numerator, value_denominator, &result->stable), out);
}
extern int hm_numeric_types_decimal_rational(void *value, void **out);
hmath_status hmath_numeric_types_decimal_rational(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_decimal_rational(value->stable, &result->stable), out);
}
extern int hm_numeric_types_decimal_add(void *a, void *b, void **out);
hmath_status hmath_numeric_types_decimal_add(hmath_context *context, const hmath_numeric_value *a, const hmath_numeric_value *b, hmath_numeric_value **out) {
 if(!a) return hm_error(HMATH_INVALID_ARGUMENT,"NULL a");
 if(!b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL b");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_decimal_add(a->stable, b->stable, &result->stable), out);
}
extern int hm_numeric_types_decimal_multiply(int mode, void *a, void *b, void **out);
hmath_status hmath_numeric_types_decimal_multiply(hmath_context *context, int mode, const hmath_numeric_value *a, const hmath_numeric_value *b, hmath_numeric_value **out) {
 if(!a) return hm_error(HMATH_INVALID_ARGUMENT,"NULL a");
 if(!b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL b");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_decimal_multiply(mode, a->stable, b->stable, &result->stable), out);
}
extern int hm_numeric_types_decimal_divide(int mode, void *a, void *b, void **out);
hmath_status hmath_numeric_types_decimal_divide(hmath_context *context, int mode, const hmath_numeric_value *a, const hmath_numeric_value *b, hmath_numeric_value **out) {
 if(!a) return hm_error(HMATH_INVALID_ARGUMENT,"NULL a");
 if(!b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL b");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_decimal_divide(mode, a->stable, b->stable, &result->stable), out);
}
extern int hm_numeric_types_fixed_scale(void *value, void **out);
hmath_status hmath_numeric_types_fixed_scale(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_fixed_scale(value->stable, &result->stable), out);
}
extern int hm_numeric_types_fixed_coefficient(void *value, void **out);
hmath_status hmath_numeric_types_fixed_coefficient(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_fixed_coefficient(value->stable, &result->stable), out);
}
extern int hm_numeric_types_interval(double low, double high, void **out);
hmath_status hmath_numeric_types_interval(hmath_context *context, double low, double high, hmath_numeric_value **out) {
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_interval(low, high, &result->stable), out);
}
extern int hm_numeric_types_interval_bounds(void *value, void **out);
hmath_status hmath_numeric_types_interval_bounds(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_interval_bounds(value->stable, &result->stable), out);
}
extern int hm_numeric_types_interval_contains(void *value, double point, void **out);
hmath_status hmath_numeric_types_interval_contains(hmath_context *context, const hmath_numeric_value *value, double point, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_interval_contains(value->stable, point, &result->stable), out);
}
extern int hm_numeric_types_interval_add(void *a, void *b, void **out);
hmath_status hmath_numeric_types_interval_add(hmath_context *context, const hmath_numeric_value *a, const hmath_numeric_value *b, hmath_numeric_value **out) {
 if(!a) return hm_error(HMATH_INVALID_ARGUMENT,"NULL a");
 if(!b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL b");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_interval_add(a->stable, b->stable, &result->stable), out);
}
extern int hm_numeric_types_interval_subtract(void *a, void *b, void **out);
hmath_status hmath_numeric_types_interval_subtract(hmath_context *context, const hmath_numeric_value *a, const hmath_numeric_value *b, hmath_numeric_value **out) {
 if(!a) return hm_error(HMATH_INVALID_ARGUMENT,"NULL a");
 if(!b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL b");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_interval_subtract(a->stable, b->stable, &result->stable), out);
}
extern int hm_numeric_types_interval_multiply(void *a, void *b, void **out);
hmath_status hmath_numeric_types_interval_multiply(hmath_context *context, const hmath_numeric_value *a, const hmath_numeric_value *b, hmath_numeric_value **out) {
 if(!a) return hm_error(HMATH_INVALID_ARGUMENT,"NULL a");
 if(!b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL b");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_interval_multiply(a->stable, b->stable, &result->stable), out);
}
extern int hm_numeric_types_interval_divide(void *a, void *b, void **out);
hmath_status hmath_numeric_types_interval_divide(hmath_context *context, const hmath_numeric_value *a, const hmath_numeric_value *b, hmath_numeric_value **out) {
 if(!a) return hm_error(HMATH_INVALID_ARGUMENT,"NULL a");
 if(!b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL b");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_interval_divide(a->stable, b->stable, &result->stable), out);
}
extern int hm_numeric_types_dual(void *primal_value, void *tangent_value, void **out);
hmath_status hmath_numeric_types_dual(hmath_context *context, const hmath_numeric_value *primal_value, const hmath_numeric_value *tangent_value, hmath_numeric_value **out) {
 if(!primal_value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL primal_value");
 if(!tangent_value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL tangent_value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_dual(primal_value->stable, tangent_value->stable, &result->stable), out);
}
extern int hm_numeric_types_primal(void *value, void **out);
hmath_status hmath_numeric_types_primal(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_primal(value->stable, &result->stable), out);
}
extern int hm_numeric_types_tangent(void *value, void **out);
hmath_status hmath_numeric_types_tangent(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_tangent(value->stable, &result->stable), out);
}
extern int hm_numeric_types_derivative(hmath_numeric_callback function, void *function_userdata, void *value, void **out);
hmath_status hmath_numeric_types_derivative(hmath_context *context, hmath_numeric_callback function, void *function_userdata, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!function) return hm_error(HMATH_INVALID_ARGUMENT,"NULL callback");
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_derivative(function, function_userdata, value->stable, &result->stable), out);
}
extern int hm_numeric_types_quaternion(void *real, void *i, void *j, void *k, void **out);
hmath_status hmath_numeric_types_quaternion(hmath_context *context, const hmath_numeric_value *real, const hmath_numeric_value *i, const hmath_numeric_value *j, const hmath_numeric_value *k, hmath_numeric_value **out) {
 if(!real) return hm_error(HMATH_INVALID_ARGUMENT,"NULL real");
 if(!i) return hm_error(HMATH_INVALID_ARGUMENT,"NULL i");
 if(!j) return hm_error(HMATH_INVALID_ARGUMENT,"NULL j");
 if(!k) return hm_error(HMATH_INVALID_ARGUMENT,"NULL k");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_quaternion(real->stable, i->stable, j->stable, k->stable, &result->stable), out);
}
extern int hm_numeric_types_quaternion_conjugate(void *value, void **out);
hmath_status hmath_numeric_types_quaternion_conjugate(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_quaternion_conjugate(value->stable, &result->stable), out);
}
extern int hm_numeric_types_quaternion_norm(void *value, void **out);
hmath_status hmath_numeric_types_quaternion_norm(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_quaternion_norm(value->stable, &result->stable), out);
}
extern int hm_numeric_types_quaternion_inverse(void *value, void **out);
hmath_status hmath_numeric_types_quaternion_inverse(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_quaternion_inverse(value->stable, &result->stable), out);
}
extern int hm_numeric_types_quaternion_component(void *value, ptrdiff_t index, void **out);
hmath_status hmath_numeric_types_quaternion_component(hmath_context *context, const hmath_numeric_value *value, ptrdiff_t index, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_quaternion_component(value->stable, index, &result->stable), out);
}
extern int hm_numeric_types_dual_quaternion(void *real, void *dual, void **out);
hmath_status hmath_numeric_types_dual_quaternion(hmath_context *context, const hmath_numeric_value *real, const hmath_numeric_value *dual, hmath_numeric_value **out) {
 if(!real) return hm_error(HMATH_INVALID_ARGUMENT,"NULL real");
 if(!dual) return hm_error(HMATH_INVALID_ARGUMENT,"NULL dual");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_dual_quaternion(real->stable, dual->stable, &result->stable), out);
}
extern int hm_numeric_types_dual_quaternion_component(void *value, ptrdiff_t index, void **out);
hmath_status hmath_numeric_types_dual_quaternion_component(hmath_context *context, const hmath_numeric_value *value, ptrdiff_t index, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_dual_quaternion_component(value->stable, index, &result->stable), out);
}
extern int hm_numeric_types_dual_quaternion_multiply(void *a, void *b, void **out);
hmath_status hmath_numeric_types_dual_quaternion_multiply(hmath_context *context, const hmath_numeric_value *a, const hmath_numeric_value *b, hmath_numeric_value **out) {
 if(!a) return hm_error(HMATH_INVALID_ARGUMENT,"NULL a");
 if(!b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL b");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_dual_quaternion_multiply(a->stable, b->stable, &result->stable), out);
}
extern int hm_numeric_types_dual_quaternion_inverse(void *value, void **out);
hmath_status hmath_numeric_types_dual_quaternion_inverse(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_dual_quaternion_inverse(value->stable, &result->stable), out);
}
extern int hm_numeric_types_rotate_vector(void *value, void *x, void *y, void *z, void **out);
hmath_status hmath_numeric_types_rotate_vector(hmath_context *context, const hmath_numeric_value *value, const hmath_numeric_value *x, const hmath_numeric_value *y, const hmath_numeric_value *z, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!x) return hm_error(HMATH_INVALID_ARGUMENT,"NULL x");
 if(!y) return hm_error(HMATH_INVALID_ARGUMENT,"NULL y");
 if(!z) return hm_error(HMATH_INVALID_ARGUMENT,"NULL z");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_rotate_vector(value->stable, x->stable, y->stable, z->stable, &result->stable), out);
}
extern int hm_numeric_types_rigid_transform(void *value, void *x, void *y, void *z, void **out);
hmath_status hmath_numeric_types_rigid_transform(hmath_context *context, const hmath_numeric_value *value, const hmath_numeric_value *x, const hmath_numeric_value *y, const hmath_numeric_value *z, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!x) return hm_error(HMATH_INVALID_ARGUMENT,"NULL x");
 if(!y) return hm_error(HMATH_INVALID_ARGUMENT,"NULL y");
 if(!z) return hm_error(HMATH_INVALID_ARGUMENT,"NULL z");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_rigid_transform(value->stable, x->stable, y->stable, z->stable, &result->stable), out);
}
extern int hm_numeric_types_transform_point(void *value, void *x, void *y, void *z, void **out);
hmath_status hmath_numeric_types_transform_point(hmath_context *context, const hmath_numeric_value *value, const hmath_numeric_value *x, const hmath_numeric_value *y, const hmath_numeric_value *z, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!x) return hm_error(HMATH_INVALID_ARGUMENT,"NULL x");
 if(!y) return hm_error(HMATH_INVALID_ARGUMENT,"NULL y");
 if(!z) return hm_error(HMATH_INVALID_ARGUMENT,"NULL z");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_transform_point(value->stable, x->stable, y->stable, z->stable, &result->stable), out);
}
extern int hm_numeric_types_constant(const uint32_t *name, size_t name_count, const char *value_numerator, const char *value_denominator, const char *uncertainty_numerator, const char *uncertainty_denominator, const char *approximation_numerator, const char *approximation_denominator, const uint32_t *unit, size_t unit_count, const uint32_t *source, size_t source_count, void **out);
hmath_status hmath_numeric_types_constant(hmath_context *context, const uint32_t *name, size_t name_count, const char *value_numerator, const char *value_denominator, const char *uncertainty_numerator, const char *uncertainty_denominator, const char *approximation_numerator, const char *approximation_denominator, const uint32_t *unit, size_t unit_count, const uint32_t *source, size_t source_count, hmath_numeric_value **out) {
 if(name_count>(size_t)PTRDIFF_MAX/sizeof(uint32_t) || (name_count && !name)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid array span");
 for(size_t i=0;i<name_count;++i) if(name[i]>0x10ffffu) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Char code point");
 if(!hm_decimal(value_numerator)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 if(!hm_decimal(value_denominator)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 const char *valueDigit=value_denominator; if(*valueDigit=='-') ++valueDigit; while(*valueDigit=='0') ++valueDigit; if(!*valueDigit) return hm_error(HMATH_INVALID_ARGUMENT,"zero Rational denominator");
 if(!hm_decimal(uncertainty_numerator)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 if(!hm_decimal(uncertainty_denominator)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 const char *uncertaintyDigit=uncertainty_denominator; if(*uncertaintyDigit=='-') ++uncertaintyDigit; while(*uncertaintyDigit=='0') ++uncertaintyDigit; if(!*uncertaintyDigit) return hm_error(HMATH_INVALID_ARGUMENT,"zero Rational denominator");
 if(!hm_decimal(approximation_numerator)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 if(!hm_decimal(approximation_denominator)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Integer decimal");
 const char *approximationDigit=approximation_denominator; if(*approximationDigit=='-') ++approximationDigit; while(*approximationDigit=='0') ++approximationDigit; if(!*approximationDigit) return hm_error(HMATH_INVALID_ARGUMENT,"zero Rational denominator");
 if(unit_count>(size_t)PTRDIFF_MAX/sizeof(uint32_t) || (unit_count && !unit)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid array span");
 for(size_t i=0;i<unit_count;++i) if(unit[i]>0x10ffffu) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Char code point");
 if(source_count>(size_t)PTRDIFF_MAX/sizeof(uint32_t) || (source_count && !source)) return hm_error(HMATH_INVALID_ARGUMENT,"invalid array span");
 for(size_t i=0;i<source_count;++i) if(source[i]>0x10ffffu) return hm_error(HMATH_INVALID_ARGUMENT,"invalid Char code point");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_constant(name, name_count, value_numerator, value_denominator, uncertainty_numerator, uncertainty_denominator, approximation_numerator, approximation_denominator, unit, unit_count, source, source_count, &result->stable), out);
}
extern int hm_numeric_types_constant_name(void *value, void **out);
hmath_status hmath_numeric_types_constant_name(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_constant_name(value->stable, &result->stable), out);
}
extern int hm_numeric_types_constant_value(void *value, void **out);
hmath_status hmath_numeric_types_constant_value(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_constant_value(value->stable, &result->stable), out);
}
extern int hm_numeric_types_standard_uncertainty(void *value, void **out);
hmath_status hmath_numeric_types_standard_uncertainty(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_standard_uncertainty(value->stable, &result->stable), out);
}
extern int hm_numeric_types_approximation_bound(void *value, void **out);
hmath_status hmath_numeric_types_approximation_bound(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_approximation_bound(value->stable, &result->stable), out);
}
extern int hm_numeric_types_constant_unit(void *value, void **out);
hmath_status hmath_numeric_types_constant_unit(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_constant_unit(value->stable, &result->stable), out);
}
extern int hm_numeric_types_constant_source(void *value, void **out);
hmath_status hmath_numeric_types_constant_source(hmath_context *context, const hmath_numeric_value *value, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_constant_source(value->stable, &result->stable), out);
}
extern int hm_numeric_types_constant_as(void *value, int dtype, void **out);
hmath_status hmath_numeric_types_constant_as(hmath_context *context, const hmath_numeric_value *value, int dtype, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_constant_as(value->stable, dtype, &result->stable), out);
}
extern int hm_numeric_types_constant_as_like(void *value, void *prototype, void **out);
hmath_status hmath_numeric_types_constant_as_like(hmath_context *context, const hmath_numeric_value *value, const hmath_numeric_value *prototype, hmath_numeric_value **out) {
 if(!value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value");
 if(!prototype) return hm_error(HMATH_INVALID_ARGUMENT,"NULL prototype");
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_constant_as_like(value->stable, prototype->stable, &result->stable), out);
}
extern int hm_numeric_types_mathematical_constants(void **out);
hmath_status hmath_numeric_types_mathematical_constants(hmath_context *context, hmath_numeric_value **out) {
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_mathematical_constants(&result->stable), out);
}
extern int hm_numeric_types_physical_constants(void **out);
hmath_status hmath_numeric_types_physical_constants(hmath_context *context, hmath_numeric_value **out) {
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_physical_constants(&result->stable), out);
}
extern int hm_numeric_types_speed_of_light(void **out);
hmath_status hmath_numeric_types_speed_of_light(hmath_context *context, hmath_numeric_value **out) {
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_speed_of_light(&result->stable), out);
}
extern int hm_numeric_types_planck_constant(void **out);
hmath_status hmath_numeric_types_planck_constant(hmath_context *context, hmath_numeric_value **out) {
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_planck_constant(&result->stable), out);
}
extern int hm_numeric_types_elementary_charge(void **out);
hmath_status hmath_numeric_types_elementary_charge(hmath_context *context, hmath_numeric_value **out) {
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_elementary_charge(&result->stable), out);
}
extern int hm_numeric_types_boltzmann_constant(void **out);
hmath_status hmath_numeric_types_boltzmann_constant(hmath_context *context, hmath_numeric_value **out) {
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_boltzmann_constant(&result->stable), out);
}
extern int hm_numeric_types_avogadro_constant(void **out);
hmath_status hmath_numeric_types_avogadro_constant(hmath_context *context, hmath_numeric_value **out) {
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_avogadro_constant(&result->stable), out);
}
extern int hm_numeric_types_gravitational_constant(void **out);
hmath_status hmath_numeric_types_gravitational_constant(hmath_context *context, hmath_numeric_value **out) {
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_gravitational_constant(&result->stable), out);
}
extern int hm_numeric_types_electron_mass(void **out);
hmath_status hmath_numeric_types_electron_mass(hmath_context *context, hmath_numeric_value **out) {
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_electron_mass(&result->stable), out);
}
extern int hm_numeric_types_astronomical_unit(void **out);
hmath_status hmath_numeric_types_astronomical_unit(hmath_context *context, hmath_numeric_value **out) {
 if(!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL value output");
 hmath_numeric_value *result=NULL;
 hmath_status status=hm_value_begin(context,&result);
 if(status) return status;
 return hm_value_finish(result, hm_numeric_types_astronomical_unit(&result->stable), out);
}
extern int hm_numeric_types_enum_value(void *stable,int *out);
hmath_status hmath_numeric_types_enum_value(hmath_context *context,const hmath_numeric_value *value,int *out) { if(!value||!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL enum argument"); hmath_status status=hm_enter(context);if(status)return status;status=(hmath_status)hm_numeric_types_enum_value(value->stable,out);hm_leave();return status;}
