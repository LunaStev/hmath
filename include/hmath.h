// SPDX-License-Identifier: MPL-2.0

#ifndef HMATH_H
#define HMATH_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

enum hmath_init_result {
    HMATH_INIT_OK = 0,
    HMATH_INIT_ALREADY_SHUT_DOWN = 1
};

/*
 * Initialize the Haskell runtime before calling any numerical function.
 * Returns HMATH_INIT_OK on first initialization and repeated calls while the
 * runtime is running. Repeated successful calls do not require extra shutdowns.
 * After final shutdown, returns HMATH_INIT_ALREADY_SHUT_DOWN without restarting
 * the runtime. Lifecycle calls from different threads are serialized.
 *
 * HMath must own the process's GHC runtime lifecycle: initialization or shutdown
 * through another library or directly through the GHC RTS is unsupported.
 */
int hmath_init(void);

/*
 * Shut down the runtime permanently. Calls before first initialization and
 * repeated calls after shutdown have no effect. Before calling, the caller must
 * wait for all numerical calls to finish and prevent any new ones. Lifecycle
 * serialization does not protect numerical calls from concurrent shutdown.
 *
 * An init racing with final shutdown may succeed before shutdown or return
 * HMATH_INIT_ALREADY_SHUT_DOWN afterward; success does not reserve runtime use.
 */
void hmath_shutdown(void);

double hmath_add_f64(double a, double b);

/* Return n! for 0 <= n <= 20, or -1 outside that range. */
long long hmath_factorial(int n);

/*
 * Return the mean, or NaN when count is zero or values is NULL.
 * For nonempty input, values must contain at least count readable doubles.
 * The caller is responsible for valid lengths; buffer sizes are not checked.
 */
double hmath_mean_f64(const double *values, size_t count);

/*
 * Return the dot product, or 0 when count is zero (including NULL pointers).
 * For nonzero count, return NaN if either pointer is NULL; otherwise each array
 * must contain at least count readable doubles. The caller is responsible for
 * valid lengths; buffer sizes are not checked.
 */
double hmath_dot_f64(
    const double *a,
    const double *b,
    size_t count
);

#ifdef __cplusplus
}
#endif

#endif
