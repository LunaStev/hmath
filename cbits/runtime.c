// SPDX-License-Identifier: MPL-2.0

#include <HsFFI.h>
#include <stdatomic.h>

#include "hmath.h"

enum hmath_runtime_state {
    HMATH_RUNTIME_UNINITIALIZED,
    HMATH_RUNTIME_RUNNING,
    HMATH_RUNTIME_SHUT_DOWN
};

/* All lifecycle state and RTS lifecycle calls are protected by this lock. */
static atomic_flag hmath_lifecycle_lock = ATOMIC_FLAG_INIT;
static enum hmath_runtime_state hmath_runtime = HMATH_RUNTIME_UNINITIALIZED;

/* The RTS may retain program arguments until shutdown. */
static int hmath_argc = 1;
static char hmath_program_name[] = "hmath";
static char *hmath_argv[] = {hmath_program_name, NULL};
static char **hmath_argv_ptr = hmath_argv;

static void lock_lifecycle(void) {
    while (atomic_flag_test_and_set_explicit(
        &hmath_lifecycle_lock, memory_order_acquire
    )) {
        /* Lifecycle operations are infrequent and must finish in sequence. */
    }
}

static void unlock_lifecycle(void) {
    atomic_flag_clear_explicit(&hmath_lifecycle_lock, memory_order_release);
}

int hmath_init(void) {
    int result = HMATH_INIT_OK;

    lock_lifecycle();

    if (hmath_runtime == HMATH_RUNTIME_SHUT_DOWN) {
        result = HMATH_INIT_ALREADY_SHUT_DOWN;
    } else if (hmath_runtime == HMATH_RUNTIME_UNINITIALIZED) {
        hs_init(&hmath_argc, &hmath_argv_ptr);
        hmath_runtime = HMATH_RUNTIME_RUNNING;
    }

    unlock_lifecycle();
    return result;
}

void hmath_shutdown(void) {
    lock_lifecycle();

    if (hmath_runtime == HMATH_RUNTIME_RUNNING) {
        hs_exit();
        hmath_runtime = HMATH_RUNTIME_SHUT_DOWN;
    }

    unlock_lifecycle();
}
