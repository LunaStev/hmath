#define _POSIX_C_SOURCE 200809L
/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_error.h"
#include "hmath_expression_error.h"
#include "hmath_interchange.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define CHECK(condition)                                                                           \
    do {                                                                                           \
        if (!(condition)) {                                                                        \
            fprintf(stderr, "%s:%d: %s (%s)\n", __FILE__, __LINE__, #condition,                    \
                    hmath_last_error_message());                                                   \
            exit(1);                                                                               \
        }                                                                                          \
    } while (0)
static hmath_value *index_value(ptrdiff_t number) {
    hmath_value *out = NULL;
    CHECK(hmath_value_index(NULL, number, &out) == HMATH_OK);
    return out;
}
static void exact_is(const hmath_value *value, const char *expected) {
    char *n = NULL, *d = NULL;
    CHECK(hmath_value_get_exact(value, &n, &d) == HMATH_OK && strcmp(n, expected) == 0 &&
          strcmp(d, "1") == 0);
    hmath_value_string_free(n);
    hmath_value_string_free(d);
}
static void big_bytes(unsigned char *out, uint64_t bits, size_t width) {
    for (size_t i = 0; i < width; ++i)
        out[width - 1 - i] = (unsigned char)(bits >> (8 * i));
}
static hmath_value *text_value(const char *text) {
    size_t length = strlen(text);
    uint32_t *chars = (uint32_t *)malloc((length ? length : 1) * sizeof *chars);
    CHECK(chars != NULL);
    for (size_t n = 0; n < length; ++n)
        chars[n] = (unsigned char)text[n];
    hmath_value *value = NULL;
    CHECK(hmath_value_text(NULL, chars, length, &value) == HMATH_OK);
    free(chars);
    return value;
}
struct mapped_state {
    hmath_value *prototype, *indices, *zero, *size, *escaped;
    int failure;
};
static hmath_status mapping_callback(const hmath_value *arguments, void *userdata,
                                     hmath_value **out, hmath_math_error *error) {
    struct mapped_state *state = (struct mapped_state *)userdata;
    hmath_value *mapping = NULL, *scalar = NULL, *bytes = NULL;
    CHECK(hmath_value_item(NULL, arguments, 0, &mapping) == HMATH_OK);
    hmath_value_release(state->escaped);
    state->escaped = mapping;
    if (state->failure) {
        static const char message[] = "callback\0\xce\xb1";
        memset(error, 0, sizeof *error);
        error->message = message;
        error->message_length = sizeof message - 1;
        if (state->failure == HMATH_MATH_ERROR) {
            error->kind = HMATH_MATH_NON_CONVERGENCE;
            error->details[0] = 17;
        } else if (state->failure == HMATH_EXPRESSION_ERROR) {
            error->kind = HMATH_EXPRESSION_TYPE_MISMATCH;
            error->details[0] = 19;
            error->details[1] = 3;
            error->details[2] = 5;
        } else
            error->kind = HMATH_INTERCHANGE_INVALID_DATA;
        return (hmath_status)state->failure;
    }
    CHECK(hmath_interchange_value_mapped_value(NULL, state->prototype, mapping, state->indices,
                                               &scalar) == HMATH_OK);
    CHECK(hmath_interchange_value_mapped_read_bytes(NULL, mapping, state->zero, state->size,
                                                    &bytes) == HMATH_OK);
    const hmath_value *fields[] = {scalar, bytes};
    hmath_status status = hmath_value_tuple(NULL, fields, 2, out);
    hmath_value_release(scalar);
    hmath_value_release(bytes);
    return status;
}
int main(void) {
    CHECK(hmath_init() == HMATH_OK);
    hmath_value *limits = NULL, *big = NULL, *little = NULL, *order = NULL, *one = index_value(1),
                *two = index_value(2), *shape = NULL;
    CHECK(hmath_interchange_value_default_limits(NULL, &limits) == HMATH_OK);
    CHECK(hmath_interchange_value_big_endian(NULL, &big) == HMATH_OK);
    CHECK(hmath_interchange_value_little_endian(NULL, &little) == HMATH_OK);
    CHECK(hmath_interchange_value_c_order(NULL, &order) == HMATH_OK);
    const hmath_value *dimensions[] = {one, two};
    CHECK(hmath_value_list(NULL, dimensions, 2, &shape) == HMATH_OK);
    struct scalar_case {
        int dtype;
        const char *decimal;
        uint64_t bits;
        size_t width;
    };
    const struct scalar_case cases[] = {
        {16, NULL, 1, 1},
        {HMATH_COEFFICIENT_INT8, "-2", 254, 1},
        {HMATH_COEFFICIENT_UINT8, "254", 254, 1},
        {HMATH_COEFFICIENT_INT16, "-4660", 60876, 2},
        {HMATH_COEFFICIENT_UINT16, "43981", 43981, 2},
        {HMATH_COEFFICIENT_INT32, "-19088743", UINT32_C(0xfedcba99), 4},
        {HMATH_COEFFICIENT_UINT32, "2309737967", UINT32_C(0x89abcdef), 4},
        {HMATH_COEFFICIENT_INT64, "-9007199254740993", UINT64_C(0xffdfffffffffffff), 8},
        {HMATH_COEFFICIENT_UINT64, "18446744073709551615", UINT64_MAX, 8},
        {HMATH_COEFFICIENT_FLOAT32, NULL, UINT32_C(0x80000000), 4},
        {HMATH_COEFFICIENT_FLOAT64, NULL, UINT64_C(0x7ff8000000000001), 8},
        {HMATH_COEFFICIENT_COMPLEX64, NULL, 0, 8},
        {HMATH_COEFFICIENT_COMPLEX128, NULL, 0, 16}};
    for (size_t which = 0; which < sizeof cases / sizeof *cases; ++which) {
        const struct scalar_case *entry = &cases[which];
        hmath_value *scalar = NULL, *program = NULL, *data = NULL, *parser = NULL, *decoded = NULL,
                    *values = NULL, *array = NULL, *matrix = NULL, *raw = NULL;
        unsigned char expected[16] = {0};
        if (entry->decimal)
            CHECK(hmath_value_integral(NULL, (hmath_coefficient_type)entry->dtype, entry->decimal,
                                       &scalar) == HMATH_OK);
        else if (entry->dtype == 16)
            CHECK(hmath_value_boolean(NULL, 1, &scalar) == HMATH_OK);
        else if (entry->dtype == HMATH_COEFFICIENT_FLOAT32) {
            uint32_t bits = (uint32_t)entry->bits;
            float value;
            memcpy(&value, &bits, 4);
            CHECK(hmath_value_f32(NULL, value, &scalar) == HMATH_OK);
        } else if (entry->dtype == HMATH_COEFFICIENT_FLOAT64) {
            double value;
            memcpy(&value, &entry->bits, 8);
            CHECK(hmath_value_f64(NULL, value, &scalar) == HMATH_OK);
        } else if (entry->dtype == HMATH_COEFFICIENT_COMPLEX64)
            CHECK(hmath_value_complex_f32(NULL, 1.5f, -2.25f, &scalar) == HMATH_OK);
        else
            CHECK(hmath_value_complex_f64(NULL, 1.5, -2.25, &scalar) == HMATH_OK);
        if (entry->dtype == HMATH_COEFFICIENT_COMPLEX64) {
            big_bytes(expected, UINT32_C(0x3fc00000), 4);
            big_bytes(expected + 4, UINT32_C(0xc0100000), 4);
        } else if (entry->dtype == HMATH_COEFFICIENT_COMPLEX128) {
            big_bytes(expected, UINT64_C(0x3ff8000000000000), 8);
            big_bytes(expected + 8, UINT64_C(0xc002000000000000), 8);
        } else
            big_bytes(expected, entry->bits, entry->width);
        CHECK(hmath_interchange_value_put_element(NULL, scalar, big, scalar, &program) == HMATH_OK);
        CHECK(hmath_interchange_value_put_bytes(NULL, program, &data) == HMATH_OK);
        const unsigned char *bytes = NULL;
        size_t count = 0;
        CHECK(hmath_bytes_data(data, &bytes, &count) == HMATH_OK && count == entry->width &&
              memcmp(bytes, expected, count) == 0);
        CHECK(hmath_interchange_value_get_element(NULL, scalar, big, &parser) == HMATH_OK);
        CHECK(hmath_interchange_value_run_decoder(NULL, parser, data, &decoded) == HMATH_OK);
        int kind = -1, dtype = -1;
        size_t length = 0;
        CHECK(hmath_value_info(decoded, &kind, &dtype, &length) == HMATH_OK &&
              (entry->dtype == 16 ? kind == 3 : (kind == 1 && dtype == entry->dtype)));
        if (entry->decimal)
            exact_is(decoded, entry->decimal);
        const hmath_value *items[] = {scalar, scalar};
        CHECK(hmath_value_list(NULL, items, 2, &values) == HMATH_OK);
        CHECK(hmath_interchange_value_from_values(NULL, scalar, limits, big, shape, values,
                                                  &array) == HMATH_OK);
        CHECK(hmath_interchange_value_raw_encode(NULL, limits, big, order, array, &raw) ==
              HMATH_OK);
        CHECK(hmath_bytes_data(raw, &bytes, &count) == HMATH_OK && count == 2 * entry->width &&
              memcmp(bytes, expected, entry->width) == 0 &&
              memcmp(bytes + entry->width, expected, entry->width) == 0);
        CHECK(hmath_interchange_value_to_matrix(NULL, scalar, array, &matrix) == HMATH_OK);
        CHECK(hmath_value_info(matrix, &kind, &dtype, &length) == HMATH_OK && kind == 9 &&
              dtype == entry->dtype && length == 2);
        unsigned char extra[17];
        memcpy(extra, expected, entry->width);
        extra[entry->width] = 0;
        hmath_value *tail = NULL, *sentinel = scalar;
        CHECK(hmath_bytes_copy(NULL, extra, entry->width + 1, &tail) == HMATH_OK);
        CHECK(hmath_interchange_value_run_decoder(NULL, parser, tail, &sentinel) ==
                  HMATH_INTERCHANGE_ERROR &&
              sentinel == scalar);
        hmath_interchange_error failure;
        CHECK(hmath_last_interchange_error(&failure) == 1 &&
              failure.kind == HMATH_INTERCHANGE_INVALID_DATA);
        hmath_value_release(tail);
        hmath_value_release(matrix);
        hmath_value_release(raw);
        hmath_value_release(array);
        hmath_value_release(values);
        hmath_value_release(decoded);
        hmath_value_release(parser);
        hmath_value_release(data);
        hmath_value_release(program);
        hmath_value_release(scalar);
    }
    char path[] = "/tmp/hmath-interchange-c-XXXXXX";
    int descriptor = mkstemp(path);
    CHECK(descriptor >= 0);
    const unsigned char raw_words[] = {255, 255, 255, 255, 255, 255, 255, 255,
                                       1,   0,   0,   0,   0,   0,   32,  0};
    CHECK(write(descriptor, raw_words, sizeof raw_words) == (ssize_t)sizeof raw_words);
    CHECK(close(descriptor) == 0);
    hmath_value *prototype = NULL, *native_path = text_value(path), *specification = NULL,
                *data_type = NULL, *flat_shape = NULL, *indices = NULL, *callback = NULL,
                *result = NULL;
    CHECK(hmath_value_integral(NULL, HMATH_COEFFICIENT_UINT64, "0", &prototype) == HMATH_OK);
    CHECK(hmath_interchange_value_element_type(NULL, prototype, &data_type) == HMATH_OK);
    const hmath_value *flat_dimensions[] = {two}, *index_items[] = {one};
    CHECK(hmath_value_list(NULL, flat_dimensions, 1, &flat_shape) == HMATH_OK);
    CHECK(hmath_value_list(NULL, index_items, 1, &indices) == HMATH_OK);
    CHECK(hmath_interchange_value_raw_spec(NULL, data_type, little, order, flat_shape,
                                           &specification) == HMATH_OK);
    struct mapped_state state = {prototype, indices, index_value(0), index_value(16), NULL, 0};
    CHECK(hmath_linear_callback(NULL, mapping_callback, &state, &callback) == HMATH_OK);
    CHECK(hmath_interchange_value_with_mapped_array(NULL, limits, specification, native_path,
                                                    callback, &result) == HMATH_OK);
    hmath_value *number = NULL, *copied = NULL;
    CHECK(hmath_value_item(NULL, result, 0, &number) == HMATH_OK);
    exact_is(number, "9007199254740993");
    CHECK(hmath_value_item(NULL, result, 1, &copied) == HMATH_OK);
    const unsigned char *bytes = NULL;
    size_t size = 0;
    CHECK(hmath_bytes_data(copied, &bytes, &size) == HMATH_OK && size == 16 &&
          memcmp(bytes, raw_words, 16) == 0);
    hmath_value *sentinel = one;
    CHECK(hmath_interchange_value_mapped_read_bytes(NULL, state.escaped, state.zero, state.size,
                                                    &sentinel) == HMATH_INTERCHANGE_ERROR &&
          sentinel == one);
    hmath_interchange_error interchange;
    CHECK(hmath_last_interchange_error(&interchange) == 1 &&
          interchange.kind == HMATH_INTERCHANGE_INVALID_DATA && interchange.message_length == 17 &&
          memcmp(interchange.message, "mapping is closed", 17) == 0);
    hmath_value_release(number);
    hmath_value_release(copied);
    hmath_value_release(result);
    for (int status = HMATH_MATH_ERROR; status <= HMATH_INTERCHANGE_ERROR; ++status) {
        state.failure = status;
        sentinel = one;
        CHECK(hmath_interchange_value_with_mapped_array(NULL, limits, specification, native_path,
                                                        callback,
                                                        &sentinel) == (hmath_status)status &&
              sentinel == one);
        if (status == HMATH_MATH_ERROR) {
            hmath_math_error failure;
            CHECK(hmath_last_math_error(&failure) == 1 &&
                  failure.kind == HMATH_MATH_NON_CONVERGENCE && failure.details[0] == 17 &&
                  failure.message_length == 11);
        } else if (status == HMATH_EXPRESSION_ERROR) {
            hmath_expression_error failure;
            CHECK(hmath_last_expression_error(&failure) == 1 &&
                  failure.kind == HMATH_EXPRESSION_TYPE_MISMATCH && failure.source_offset == 19 &&
                  failure.source_line == 3 && failure.source_column == 5 &&
                  failure.message_length == 11);
        } else
            CHECK(hmath_last_interchange_error(&interchange) == 1 &&
                  interchange.kind == HMATH_INTERCHANGE_INVALID_DATA &&
                  interchange.message_length == 11);
        hmath_value *expired = one;
        CHECK(hmath_interchange_value_mapped_read_bytes(NULL, state.escaped, state.zero, state.size,
                                                        &expired) == HMATH_INTERCHANGE_ERROR &&
              expired == one);
    }
    CHECK(unlink(path) == 0);
    hmath_value_release(state.escaped);
    hmath_value_release(state.zero);
    hmath_value_release(state.size);
    hmath_value_release(callback);
    hmath_value_release(indices);
    hmath_value_release(specification);
    hmath_value_release(flat_shape);
    hmath_value_release(data_type);
    hmath_value_release(prototype);
    hmath_value_release(native_path);
    hmath_value_release(limits);
    hmath_value_release(big);
    hmath_value_release(little);
    hmath_value_release(order);
    hmath_value_release(one);
    CHECK(hmath_runtime_shutdown() == HMATH_BUSY);
    hmath_value_release(shape);
    hmath_value_release(two);
    CHECK(hmath_runtime_shutdown() == HMATH_OK);
    return 0;
}
