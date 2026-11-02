/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_error.h"
#include "hmath_expression_error.h"
#include "hmath_interchange_error.h"
#include "hmath_callback.h"
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include <windows.h>
static INIT_ONCE error_once = INIT_ONCE_STATIC_INIT;
static DWORD error_key = FLS_OUT_OF_INDEXES;
#else
#include <pthread.h>
static pthread_once_t error_once = PTHREAD_ONCE_INIT;
static pthread_key_t error_key;
static int key_ready;
#endif
struct error_cell {
    hmath_math_error value;
    hmath_expression_error expression;
    hmath_interchange_error interchange;
    char *owned_message;
    int valid;
};
static void destroy_cell(void *pointer) {
    struct error_cell *cell = pointer;
    if (cell) {
        free(cell->owned_message);
        free(cell);
    }
}
#ifdef _WIN32
static void WINAPI destroy_fiber(void *pointer) { destroy_cell(pointer); }
static BOOL CALLBACK initialize_error_key(PINIT_ONCE once, PVOID parameter, PVOID *context) {
    (void)once;
    (void)parameter;
    (void)context;
    error_key = FlsAlloc(destroy_fiber);
    return TRUE;
}
static struct error_cell *get_cell(int create) {
    if (!InitOnceExecuteOnce(&error_once, initialize_error_key, NULL, NULL) ||
        error_key == FLS_OUT_OF_INDEXES)
        return NULL;
    struct error_cell *cell = FlsGetValue(error_key);
    if (!cell && create) {
        cell = calloc(1, sizeof *cell);
        if (cell && !FlsSetValue(error_key, cell)) {
            free(cell);
            cell = NULL;
        }
    }
    return cell;
}
#else
static void initialize_error_key(void) {
    key_ready = pthread_key_create(&error_key, destroy_cell) == 0;
}
static struct error_cell *get_cell(int create) {
    if (pthread_once(&error_once, initialize_error_key) || !key_ready)
        return NULL;
    struct error_cell *cell = pthread_getspecific(error_key);
    if (!cell && create) {
        cell = calloc(1, sizeof *cell);
        if (cell && pthread_setspecific(error_key, cell)) {
            free(cell);
            cell = NULL;
        }
    }
    return cell;
}
#endif
/* Internal hooks: cleanup is pure C and never calls the Haskell runtime. */
void hm_clear_math_error(void) {
    struct error_cell *cell = get_cell(0);
    if (!cell)
        return;
#ifdef _WIN32
    int detached = FlsSetValue(error_key, NULL) != 0;
#else
    int detached = pthread_setspecific(error_key, NULL) == 0;
#endif
    if (detached) {
        destroy_cell(cell);
    } else {
        /* A failed TLS update must not leave a dangling destructor pointer. */
        free(cell->owned_message);
        cell->owned_message = NULL;
        memset(&cell->value, 0, sizeof cell->value);
        memset(&cell->expression, 0, sizeof cell->expression);
        memset(&cell->interchange, 0, sizeof cell->interchange);
        cell->valid = 0;
    }
}

int hm_record_math_error(int kind, const ptrdiff_t *details, const char *message, size_t length) {
    if (kind < 1 || kind > 21 || (length && !message) || length == SIZE_MAX)
        return HMATH_INVALID_ARGUMENT;
    struct error_cell *cell = get_cell(1);
    if (!cell)
        return HMATH_ALLOCATION_FAILED;
    char *copy = malloc(length + 1);
    if (!copy)
        return HMATH_ALLOCATION_FAILED;
    if (length)
        memcpy(copy, message, length);
    copy[length] = '\0';
    free(cell->owned_message);
    cell->owned_message = copy;
    cell->value.kind = (uint32_t)kind;
    memcpy(cell->value.details, details, sizeof cell->value.details);
    cell->value.message = copy;
    cell->value.message_length = length;
    cell->valid = 1;
    return HMATH_OK;
}
int hmath_last_math_error(hmath_math_error *out) {
    struct error_cell *cell = get_cell(0);
    if (!out || !cell || cell->valid != 1)
        return 0;
    *out = cell->value;
    return 1;
}
int hm_record_expression_error(int kind, const ptrdiff_t *position,
                               const char *message, size_t length) {
    if ((unsigned)kind > 9 || !position || (length && !message) || length == SIZE_MAX)
        return HMATH_INVALID_ARGUMENT;
    struct error_cell *cell = get_cell(1);
    if (!cell)
        return HMATH_ALLOCATION_FAILED;
    char *copy = malloc(length + 1);
    if (!copy)
        return HMATH_ALLOCATION_FAILED;
    if (length)
        memcpy(copy, message, length);
    copy[length] = '\0';
    free(cell->owned_message);
    cell->owned_message = copy;
    cell->expression.kind = (uint32_t)kind;
    cell->expression.source_offset = position[0];
    cell->expression.source_line = position[1];
    cell->expression.source_column = position[2];
    cell->expression.message = copy;
    cell->expression.message_length = length;
    cell->valid = 2;
    return HMATH_OK;
}
int hmath_last_expression_error(hmath_expression_error *out) {
    struct error_cell *cell = get_cell(0);
    if (!out || !cell || cell->valid != 2)
        return 0;
    *out = cell->expression;
    return 1;
}
int hm_record_interchange_error(int kind, const char *message, size_t length) {
    if ((unsigned)kind > 3 || (length && !message) || length == SIZE_MAX)
        return HMATH_INVALID_ARGUMENT;
    struct error_cell *cell = get_cell(1);
    if (!cell)
        return HMATH_ALLOCATION_FAILED;
    char *copy = malloc(length + 1);
    if (!copy)
        return HMATH_ALLOCATION_FAILED;
    if (length)
        memcpy(copy, message, length);
    copy[length] = '\0';
    free(cell->owned_message);
    cell->owned_message = copy;
    cell->interchange.kind = (uint32_t)kind;
    cell->interchange.message = copy;
    cell->interchange.message_length = length;
    cell->valid = 3;
    return HMATH_OK;
}
int hmath_last_interchange_error(hmath_interchange_error *out) {
    struct error_cell *cell = get_cell(0);
    if (!out || !cell || cell->valid != 3)
        return 0;
    *out = cell->interchange;
    return 1;
}
int hmath_callback_capture_error(hmath_status status,hmath_callback_error *out) {
    if (!out)
        return 0;
    hmath_callback_error result = {0};
    if (status == HMATH_MATH_ERROR) {
        if (!hmath_last_math_error(&result))
            return 0;
    } else if (status == HMATH_EXPRESSION_ERROR) {
        hmath_expression_error error;
        if (!hmath_last_expression_error(&error))
            return 0;
        result.kind = error.kind;
        result.details[0] = error.source_offset;
        result.details[1] = error.source_line;
        result.details[2] = error.source_column;
        result.message = error.message;
        result.message_length = error.message_length;
    } else if (status == HMATH_INTERCHANGE_ERROR) {
        hmath_interchange_error error;
        if (!hmath_last_interchange_error(&error))
            return 0;
        result.kind = error.kind;
        result.message = error.message;
        result.message_length = error.message_length;
    } else {
        return 0;
    }
    *out = result;
    return 1;
}
size_t hm_math_error_size(void) { return sizeof(hmath_math_error); }
void hm_math_error_reset(hmath_math_error *error) { memset(error, 0, sizeof *error); }
int hm_math_error_kind(const hmath_math_error *error) { return (int)error->kind; }
ptrdiff_t hm_math_error_detail(const hmath_math_error *error, int index) {
    return error->details[index];
}
const char *hm_math_error_message(const hmath_math_error *error) { return error->message; }
size_t hm_math_error_message_length(const hmath_math_error *error) { return error->message_length; }
