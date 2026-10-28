/* SPDX-License-Identifier: MPL-2.0 */
#include "native_internal.h"
#include <HsFFI.h>
#include <limits.h>
#include <math.h>
#include <stdatomic.h>
static atomic_flag lifecycle_lock = ATOMIC_FLAG_INIT;
static enum { UNINITIALIZED, RUNNING, SHUT_DOWN } runtime_state;
static size_t active_calls;
static int argc = 1;
static char program[] = "hmath";
static char *argv[] = {program, NULL};
static char **argv_ptr = argv;
static void lock(void) {
    while (atomic_flag_test_and_set_explicit(&lifecycle_lock, memory_order_acquire)) {
    }
}
static void unlock(void) { atomic_flag_clear_explicit(&lifecycle_lock, memory_order_release); }
int hmath_init(void) {
    lock();
    if (runtime_state == SHUT_DOWN) {
        unlock();
        hm_error(HMATH_RUNTIME_ERROR, "GHC RTS cannot be restarted after final shutdown");
        return HMATH_INIT_ALREADY_SHUT_DOWN;
    }
    if (runtime_state == UNINITIALIZED) {
        hs_init(&argc, &argv_ptr);
        runtime_state = RUNNING;
    }
    unlock();
    hm_error(HMATH_OK, "");
    return HMATH_INIT_OK;
}
hmath_status hm_enter(hmath_context *context) {
    lock();
    if (runtime_state != RUNNING) {
        unlock();
        return hm_error(HMATH_RUNTIME_ERROR, "initialize HMath before numerical calls");
    }
    if (hm_cancelled(context)) {
        unlock();
        return hm_error(HMATH_CANCELLED, "context cancelled");
    }
    ++active_calls;
    unlock();
    return HMATH_OK;
}
void hm_leave(void) {
    lock();
    --active_calls;
    unlock();
}
hmath_status hmath_runtime_shutdown(void) {
    lock();
    if (active_calls) {
        unlock();
        return hm_error(HMATH_BUSY, "numerical calls are active; join workers before shutdown");
    }
    if (runtime_state == RUNNING) {
        hs_exit();
        runtime_state = SHUT_DOWN;
    }
    unlock();
    return hm_error(HMATH_OK, "");
}
void hmath_shutdown(void) { (void)hmath_runtime_shutdown(); }
static double legacy(int op, const double *a, const double *b, size_t n) {
    if (n > (size_t)PTRDIFF_MAX) {
        hm_error(HMATH_OVERFLOW, "legacy count exceeds Haskell Int");
        return NAN;
    }
    if (hm_enter(NULL) != HMATH_OK)
        return NAN;
    double value = NAN;
    int status = hm_haskell_legacy(op, a, b, n, &value);
    hm_leave();
    hm_error((hmath_status)status, status ? "Haskell exception in legacy call" : "");
    return value;
}
double hmath_add_f64(double a, double b) { return legacy(0, &a, &b, 1); }
long long hmath_factorial(int n) {
    if (hm_enter(NULL) != HMATH_OK)
        return -1;
    /* This exact bounded integer operation does not pass through binary64. */
    extern long long hm_haskell_factorial(int);
    long long value = hm_haskell_factorial(n);
    hm_leave();
    hm_error(HMATH_OK, "");
    return value;
}
double hmath_mean_f64(const double *values, size_t count) { return legacy(1, values, NULL, count); }
double hmath_dot_f64(const double *a, const double *b, size_t count) {
    return legacy(2, a, b, count);
}
