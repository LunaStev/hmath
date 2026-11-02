/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_CALLBACK_H
#define HMATH_CALLBACK_H
#include "hmath_error.h"
#ifdef __cplusplus
extern "C" {
#endif
/* ABI-compatible callback error wire. The callback return status determines
 * the domain: 11=MathError, 12=ExprError (offset,line,column in details0..2),
 * 13=InterchangeError. kind is the corresponding domain constructor code;
 * message is length-delimited WTF8 and remains valid until consumed. */
typedef hmath_math_error hmath_callback_error;
/* Query only: capture a matching current structured error after a nested API
 * call. Returns1 on success,0 with out untouched otherwise. Message is borrowed
 * until the next checked operation on this thread. */
HMATH_API int hmath_callback_capture_error(hmath_status status, hmath_callback_error *out);
#ifdef __cplusplus
}
#endif
#endif
