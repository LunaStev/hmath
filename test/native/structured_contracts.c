/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_error.h"
#include "hmath_graph.h"
#include "hmath_timeseries.h"
#include <assert.h>
#include <stdint.h>

static hmath_status failed_heuristic(ptrdiff_t vertex, void *userdata, double *out) {
    int *calls = (int *)userdata;
    (void)vertex;
    (void)out;
    ++*calls;
    return HMATH_HASKELL_EXCEPTION;
}

int main(void) {
    hmath_value *flag = NULL, *count = NULL, *empty = NULL, *graph = NULL;
    hmath_value *zero = NULL, *one = NULL, *unit = NULL, *result = NULL;
    hmath_value *start = NULL, *step = NULL, *missing = NULL, *samples = NULL;
    hmath_value *series = NULL;
    hmath_value *sentinel = (hmath_value *)(uintptr_t)1;
    hmath_context *context = NULL;
    hmath_math_error error;
    int kind = -1, dtype = -1, calls = 0;
    size_t size = 99;
    assert(hmath_init() == HMATH_OK);
    assert(hmath_value_boolean(NULL, 0, &flag) == HMATH_OK);
    assert(hmath_value_index(NULL, 3, &count) == HMATH_OK);
    assert(hmath_value_index(NULL, 0, &zero) == HMATH_OK);
    assert(hmath_value_index(NULL, 1, &one) == HMATH_OK);
    assert(hmath_value_list(NULL, NULL, 0, &empty) == HMATH_OK);
    assert(hmath_graph_graph(NULL, flag, count, empty, &graph) == HMATH_OK);
    assert(hmath_graph_check_vertex(NULL, graph, zero, &unit) == HMATH_OK);
    assert(hmath_value_info(unit, &kind, &dtype, &size) == HMATH_OK);
    assert(kind == 5 && size == 0); /* () retains tuple identity. */
    hmath_value_release(unit);
    assert(hmath_graph_a_star(NULL, graph, failed_heuristic, &calls, zero, one, &sentinel) ==
           HMATH_HASKELL_EXCEPTION);
    assert(calls > 0 && sentinel == (hmath_value *)(uintptr_t)1);
    assert(hmath_context_create(&context) == HMATH_OK);
    hmath_context_cancel(context);
    assert(hmath_graph_vertex_count(context, graph, &sentinel) == HMATH_CANCELLED);
    assert(sentinel == (hmath_value *)(uintptr_t)1);
    hmath_context_release(context);
    hmath_value_release(graph);
    hmath_value_release(flag);
    hmath_value_release(count);
    hmath_value_release(zero);
    hmath_value_release(one);

    assert(hmath_value_f64(NULL, 0, &start) == HMATH_OK);
    assert(hmath_value_f64(NULL, 1, &step) == HMATH_OK);
    assert(hmath_value_none(NULL, &missing) == HMATH_OK);
    {
        const hmath_value *items[] = {missing, step};
        assert(hmath_value_list(NULL, items, 2, &samples) == HMATH_OK);
    }
    assert(hmath_timeseries_regular_series(NULL, start, step, samples, &series) == HMATH_OK);
    hmath_value_release(samples);
    hmath_value_release(missing);
    hmath_value_release(start);
    hmath_value_release(step);
    assert(hmath_timeseries_series_values(NULL, series, &sentinel) == HMATH_MATH_ERROR);
    assert(sentinel == (hmath_value *)(uintptr_t)1);
    assert(hmath_last_math_error(&error) && error.kind == HMATH_MATH_INVALID_ARGUMENT);
    assert(hmath_timeseries_observations(NULL, series, &result) == HMATH_OK);
    hmath_value_release(series);
    assert(hmath_runtime_shutdown() == HMATH_BUSY);
    assert(hmath_value_info(result, &kind, &dtype, &size) == HMATH_OK);
    assert(kind == 4 && size == 2);
    hmath_value_release(result);
    hmath_value_release(empty);
    assert(hmath_runtime_shutdown() == HMATH_OK);
    return 0;
}
