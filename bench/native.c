/* SPDX-License-Identifier: MPL-2.0 */
#define _POSIX_C_SOURCE 200809L
#include "hmath.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#ifdef _WIN32
#include <windows.h>
#endif

static double now(void) {
#ifdef _WIN32
    LARGE_INTEGER count, frequency;
    QueryPerformanceCounter(&count);
    QueryPerformanceFrequency(&frequency);
    return (double)count.QuadPart / (double)frequency.QuadPart;
#else
    struct timespec t;
    if (clock_gettime(CLOCK_MONOTONIC, &t))
        abort();
    return (double)t.tv_sec + 1e-9 * (double)t.tv_nsec;
#endif
}
static void require(int ok) {
    if (!ok) {
        fprintf(stderr, "benchmark validation: %s\n", hmath_last_error_message());
        exit(1);
    }
}
int main(int argc, char **argv) {
    char *end = NULL;
    unsigned long count = argc == 2 ? strtoul(argv[1], &end, 10) : 1000;
    require(argc <= 2 && (argc != 2 || (end != argv[1] && *end == '\0')) && count > 0 &&
            count <= 10000000);
    require(hmath_init() == HMATH_INIT_OK);
    double values[1024];
    for (size_t i = 0; i < 1024; ++i)
        values[i] = 1;
    hmath_tensor *vector = NULL;
    require(hmath_vector_copy(values, 1024, &vector) == HMATH_OK);
    double result = 0;
    require(hmath_tensor_dot(NULL, vector, vector, &result) == HMATH_OK && result == 1024);
    const char *names[] = {"legacy-scalar-call", "legacy-dot-1024", "checked-dot-1024",
                           "tensor-allocation-1024"};
    printf("{\"schema\":1,\"iterations\":%lu,\"cases\":[", count);
    for (int kind = 0; kind < 4; ++kind) {
        double samples[7];
        for (int sample = -1; sample < 7; ++sample) {
            double start = now();
            for (unsigned long iteration = 0; iteration < count; ++iteration) {
                if (kind == 0) {
                    result = hmath_add_f64(1, 2);
                } else if (kind == 1) {
                    result = hmath_dot_f64(values, values, 1024);
                } else if (kind == 2) {
                    require(hmath_tensor_dot(NULL, vector, vector, &result) == HMATH_OK);
                } else {
                    hmath_tensor *copy = NULL;
                    require(hmath_vector_copy(values, 1024, &copy) == HMATH_OK);
                    result = (double)hmath_tensor_count(copy);
                    hmath_tensor_release(copy);
                }
            }
            double elapsed = (now() - start) / (double)count;
            require(result == (kind == 0 ? 3 : 1024) && isfinite(elapsed) && elapsed > 0);
            if (sample >= 0)
                samples[sample] = elapsed;
        }
        printf("%s{\"name\":\"%s\",\"seconds\":[", kind ? "," : "", names[kind]);
        for (int i = 0; i < 7; ++i)
            printf("%s%.17g", i ? "," : "", samples[i]);
        printf("]}");
    }
    puts("]}");
    hmath_tensor_release(vector);
    require(hmath_runtime_shutdown() == HMATH_OK);
    return 0;
}
