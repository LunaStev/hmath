// SPDX-License-Identifier: MPL-2.0

#include <HsFFI.h>

#include "hmath.h"

static int hmath_initialized = 0;

int hmath_init(void) {
    if (hmath_initialized) {
        return 0;
    }

    int argc = 1;
    char *argv[] = {"hmath", NULL};
    char **argv_ptr = argv;

    hs_init(&argc, &argv_ptr);

    hmath_initialized = 1;

    return 0;
}

void hmath_shutdown(void) {
    if (!hmath_initialized) {
        return;
    }

    hs_exit();

    hmath_initialized = 0;
}
