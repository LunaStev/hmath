/* SPDX-License-Identifier: MPL-2.0 */
/* Compile and run in both C99 and C++17. */
#include "hmath_error.h"
#include "hmath_expression.h"
#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
static hmath_value *text(const char *ascii) {
    size_t count = strlen(ascii);
    uint32_t *points = (uint32_t *)malloc((count ? count : 1) * sizeof *points);
    assert(points);
    for (size_t i = 0; i < count; ++i)
        points[i] = (unsigned char)ascii[i];
    hmath_value *value = NULL;
    assert(hmath_value_text(NULL, points, count, &value) == HMATH_OK);
    free(points);
    return value;
}
static hmath_value *index(ptrdiff_t n) {
    hmath_value *value = NULL;
    assert(hmath_value_index(NULL, n, &value) == HMATH_OK);
    return value;
}
int main(void) {
    assert(hmath_init() == HMATH_INIT_OK);
    hmath_value *limits = NULL, *registry = NULL, *precision = NULL, *bindings = NULL;
    assert(hmath_expression_default_limits(NULL, &limits) == HMATH_OK);
    assert(hmath_expression_default_registry(NULL, &registry) == HMATH_OK);
    assert(hmath_expression_exact_rational_create(NULL, &precision) == HMATH_OK);
    assert(hmath_value_list(NULL, NULL, 0, &bindings) == HMATH_OK);
    hmath_value *source = text("1//3 + 2//3"), *expr = NULL, *result = NULL, *item = NULL;
    assert(hmath_expression_parse_expression(NULL, limits, source, &expr) == HMATH_OK);
    assert(hmath_expression_evaluate_expression(NULL, limits, precision, registry, bindings, expr,
                                                &result) == HMATH_OK);
    assert(hmath_value_item(NULL, result, 1, &item) == HMATH_OK);
    char *n = NULL, *d = NULL;
    assert(hmath_value_get_exact(item, &n, &d) == HMATH_OK);
    assert(strcmp(n, "1") == 0 && strcmp(d, "1") == 0);
    hmath_value_string_free(n);
    hmath_value_string_free(d);
    hmath_value_release(item);
    hmath_value_release(result);

    hmath_value *cache = NULL, *cached = NULL;
    assert(hmath_expression_empty_expression_cache(NULL, &cache) == HMATH_OK);
    assert(hmath_expression_cached_expression(NULL, limits, source, cache, &cached) == HMATH_OK);
    assert(hmath_runtime_shutdown() == HMATH_BUSY);
    hmath_value_release(cached);
    hmath_value_release(cache);
    hmath_value *bad = text(")");
    result = (hmath_value *)(uintptr_t)0x1234;
    assert(hmath_expression_parse_expression(NULL, limits, bad, &result) == HMATH_EXPRESSION_ERROR);
    assert(result == (hmath_value *)(uintptr_t)0x1234);
    hmath_expression_error error;
    hmath_math_error math_error;
    assert(hmath_last_expression_error(&error) == 1);
    assert(error.kind == HMATH_EXPRESSION_SYNTAX_ERROR);
    assert(error.source_offset == 0 && error.source_line == 1 && error.source_column == 1);
    assert(hmath_last_math_error(&math_error) == 0);
    int kind, dtype;
    size_t count;
    assert(hmath_value_info(limits, &kind, &dtype, &count) == HMATH_OK);
    assert(hmath_last_expression_error(&error) == 1); /* query did not clear */
    assert(hmath_expression_validate_limits(NULL, limits, &result) == HMATH_OK);
    hmath_value_release(result);
    assert(hmath_last_expression_error(&error) == 0);

    /* A pure source ExprError value also retains all characters and positions. */
    const uint32_t points[] = {'a', 0, 0xd800, 0x1d11e};
    hmath_value *message = NULL, *offset = index(-3), *line = index(2), *column = index(9),
                *position = NULL, *error_kind = NULL, *record = NULL;
    assert(hmath_value_text(NULL, points, 4, &message) == HMATH_OK);
    assert(hmath_expression_source_pos_create(NULL, offset, line, column, &position) == HMATH_OK);
    assert(hmath_expression_unsupported_create(NULL, &error_kind) == HMATH_OK);
    assert(hmath_expression_expr_error_create(NULL, error_kind, position, message, &record) ==
           HMATH_OK);
    assert(hmath_expression_error_message(NULL, record, &result) == HMATH_OK);
    uint32_t copied[4];
    assert(hmath_value_info(result, &kind, &dtype, &count) == HMATH_OK && count == 4);
    assert(hmath_value_get_text(result, copied, 4) == HMATH_OK);
    assert(memcmp(copied, points, sizeof points) == 0);
    hmath_value_release(result);
    hmath_value_release(record);
    hmath_value_release(error_kind);
    hmath_value_release(position);
    hmath_value_release(column);
    hmath_value_release(line);
    hmath_value_release(offset);
    hmath_value_release(message);

    hmath_value *options = NULL, *variable = text("x"), *quadratic = text("x^2+x"),
                *function = NULL, *derivative = NULL;
    assert(hmath_symbolic_default_symbolic_options(NULL, &options) == HMATH_OK);
    assert(hmath_expression_parse_expression(NULL, limits, quadratic, &function) == HMATH_OK);
    assert(hmath_symbolic_differentiate(NULL, options, variable, function, &derivative) ==
           HMATH_OK);
    assert(hmath_expression_expression_node(NULL, derivative, &item) == HMATH_OK);
    assert(hmath_value_info(item, &kind, &dtype, &count) == HMATH_OK && kind == 81);
    hmath_value_release(item);
    hmath_value_release(derivative);
    hmath_value_release(function);
    hmath_value_release(quadratic);
    hmath_value_release(variable);
    hmath_value_release(options);
    hmath_value_release(bad);
    hmath_value_release(expr);
    hmath_value_release(source);
    hmath_value_release(bindings);
    hmath_value_release(precision);
    hmath_value_release(registry);
    hmath_value_release(limits);
    assert(hmath_runtime_shutdown() == HMATH_OK);
    return 0;
}
