/* SPDX-License-Identifier: MPL-2.0 */
/* Generated; original operation dispatch only. */
#include "hmath_foundation.h"
#include "value_internal.h"
extern int hm_foundation_apply(int, void *const *, size_t, void **);
hmath_status hmath_foundation_datastructure_fenwick(hmath_context *context, const hmath_value *a0,
                                                    hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(0, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_fenwick_add(hmath_context *context,
                                                        const hmath_value *a0,
                                                        const hmath_value *a1,
                                                        const hmath_value *a2, hmath_value **out) {
    if (!out || !a0 || !a1 || !a2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2)};
    return hm_value_finish(result, hm_foundation_apply(1, args, 3, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_fenwick_prefix(hmath_context *context,
                                                           const hmath_value *a0,
                                                           const hmath_value *a1,
                                                           hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(2, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_fenwick_range(hmath_context *context,
                                                          const hmath_value *a0,
                                                          const hmath_value *a1,
                                                          const hmath_value *a2,
                                                          hmath_value **out) {
    if (!out || !a0 || !a1 || !a2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2)};
    return hm_value_finish(result, hm_foundation_apply(3, args, 3, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_segment_tree(hmath_context *context,
                                                         const hmath_value *a0, hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(4, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_segment_set(hmath_context *context,
                                                        const hmath_value *a0,
                                                        const hmath_value *a1,
                                                        const hmath_value *a2, hmath_value **out) {
    if (!out || !a0 || !a1 || !a2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2)};
    return hm_value_finish(result, hm_foundation_apply(5, args, 3, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_segment_range(hmath_context *context,
                                                          const hmath_value *a0,
                                                          const hmath_value *a1,
                                                          const hmath_value *a2,
                                                          hmath_value **out) {
    if (!out || !a0 || !a1 || !a2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2)};
    return hm_value_finish(result, hm_foundation_apply(6, args, 3, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_sparse_table(hmath_context *context,
                                                         const hmath_value *a0, hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(7, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_sparse_minimum(hmath_context *context,
                                                           const hmath_value *a0,
                                                           const hmath_value *a1,
                                                           const hmath_value *a2,
                                                           hmath_value **out) {
    if (!out || !a0 || !a1 || !a2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2)};
    return hm_value_finish(result, hm_foundation_apply(8, args, 3, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_disjoint_sparse_table(hmath_context *context,
                                                                  const hmath_value *a0,
                                                                  hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(9, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_disjoint_range(hmath_context *context,
                                                           const hmath_value *a0,
                                                           const hmath_value *a1,
                                                           const hmath_value *a2,
                                                           hmath_value **out) {
    if (!out || !a0 || !a1 || !a2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2)};
    return hm_value_finish(result, hm_foundation_apply(10, args, 3, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_next_greater(hmath_context *context,
                                                         const hmath_value *a0, hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(11, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_empty_heap(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    return hm_value_finish(result, hm_foundation_apply(12, NULL, 0, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_heap_insert(hmath_context *context,
                                                        const hmath_value *a0,
                                                        const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(13, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_heap_pop(hmath_context *context, const hmath_value *a0,
                                                     hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(14, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_heap_from_list(hmath_context *context,
                                                           const hmath_value *a0,
                                                           hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(15, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_binary_heap(hmath_context *context,
                                                        const hmath_value *a0, hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(16, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_binary_insert(hmath_context *context,
                                                          const hmath_value *a0,
                                                          const hmath_value *a1,
                                                          hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(17, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_binary_pop(hmath_context *context,
                                                       const hmath_value *a0, hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(18, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_indexed_heap(hmath_context *context,
                                                         hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    return hm_value_finish(result, hm_foundation_apply(19, NULL, 0, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_indexed_set(hmath_context *context,
                                                        const hmath_value *a0,
                                                        const hmath_value *a1,
                                                        const hmath_value *a2, hmath_value **out) {
    if (!out || !a0 || !a1 || !a2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2)};
    return hm_value_finish(result, hm_foundation_apply(20, args, 3, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_indexed_pop(hmath_context *context,
                                                        const hmath_value *a0, hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(21, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_union_find(hmath_context *context,
                                                       const hmath_value *a0, hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(22, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_find_root(hmath_context *context, const hmath_value *a0,
                                                      const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(23, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_union(hmath_context *context, const hmath_value *a0,
                                                  const hmath_value *a1, const hmath_value *a2,
                                                  hmath_value **out) {
    if (!out || !a0 || !a1 || !a2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2)};
    return hm_value_finish(result, hm_foundation_apply(24, args, 3, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_connected(hmath_context *context, const hmath_value *a0,
                                                      const hmath_value *a1, const hmath_value *a2,
                                                      hmath_value **out) {
    if (!out || !a0 || !a1 || !a2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2)};
    return hm_value_finish(result, hm_foundation_apply(25, args, 3, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_components(hmath_context *context,
                                                       const hmath_value *a0, hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(26, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_bloom(hmath_context *context, const hmath_value *a0,
                                                  const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(27, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_bloom_insert(hmath_context *context,
                                                         const hmath_value *a0,
                                                         const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(28, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_bloom_member(hmath_context *context,
                                                         const hmath_value *a0,
                                                         const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(29, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_bloom_false_positive_bound(hmath_context *context,
                                                                       const hmath_value *a0,
                                                                       hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(30, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_count_min(hmath_context *context, const hmath_value *a0,
                                                      const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(31, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_count_min_add(hmath_context *context,
                                                          const hmath_value *a0,
                                                          const hmath_value *a1,
                                                          const hmath_value *a2,
                                                          hmath_value **out) {
    if (!out || !a0 || !a1 || !a2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2)};
    return hm_value_finish(result, hm_foundation_apply(32, args, 3, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_count_min_estimate(hmath_context *context,
                                                               const hmath_value *a0,
                                                               const hmath_value *a1,
                                                               hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(33, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_count_min_error_bound(hmath_context *context,
                                                                  const hmath_value *a0,
                                                                  hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(34, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_hyper_log_log(hmath_context *context,
                                                          const hmath_value *a0,
                                                          hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(35, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_hll_add(hmath_context *context, const hmath_value *a0,
                                                    const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(36, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_hll_estimate(hmath_context *context,
                                                         const hmath_value *a0, hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(37, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_reservoir(hmath_context *context, const hmath_value *a0,
                                                      const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(38, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_reservoir_add(hmath_context *context,
                                                          const hmath_value *a0,
                                                          const hmath_value *a1,
                                                          hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(39, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_reservoir_values(hmath_context *context,
                                                             const hmath_value *a0,
                                                             hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(40, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_online_quantiles(hmath_context *context,
                                                             const hmath_value *a0,
                                                             hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(41, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_quantile_add(hmath_context *context,
                                                         const hmath_value *a0,
                                                         const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(42, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_online_quantile(hmath_context *context,
                                                            const hmath_value *a0,
                                                            const hmath_value *a1,
                                                            hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(43, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_multiset(hmath_context *context, const hmath_value *a0,
                                                hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(44, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_discrete_multiplicity(hmath_context *context, const hmath_value *a0,
                                                    const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(45, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_multiset_entries(hmath_context *context,
                                                        const hmath_value *a0, hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(46, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_discrete_multiset_insert(hmath_context *context,
                                                       const hmath_value *a0, const hmath_value *a1,
                                                       hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(47, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_multiset_delete(hmath_context *context,
                                                       const hmath_value *a0, const hmath_value *a1,
                                                       hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(48, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_multiset_union(hmath_context *context, const hmath_value *a0,
                                                      const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(49, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_multiset_intersection(hmath_context *context,
                                                             const hmath_value *a0,
                                                             const hmath_value *a1,
                                                             hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(50, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_multiset_difference(hmath_context *context,
                                                           const hmath_value *a0,
                                                           const hmath_value *a1,
                                                           hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(51, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_bit_set(hmath_context *context, const hmath_value *a0,
                                               const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(52, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_bit_width(hmath_context *context, const hmath_value *a0,
                                                 hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(53, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_discrete_bit_value(hmath_context *context, const hmath_value *a0,
                                                 hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(54, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_discrete_bit_member(hmath_context *context, const hmath_value *a0,
                                                  const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(55, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_bit_insert(hmath_context *context, const hmath_value *a0,
                                                  const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(56, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_bit_delete(hmath_context *context, const hmath_value *a0,
                                                  const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(57, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_bit_union(hmath_context *context, const hmath_value *a0,
                                                 const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(58, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_bit_intersection(hmath_context *context,
                                                        const hmath_value *a0,
                                                        const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(59, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_bit_difference(hmath_context *context, const hmath_value *a0,
                                                      const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(60, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_resize_bit_set(hmath_context *context, const hmath_value *a0,
                                                      const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(61, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_population_count(hmath_context *context,
                                                        const hmath_value *a0, hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(62, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_discrete_leading_zeros(hmath_context *context, const hmath_value *a0,
                                                     hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(63, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_discrete_trailing_zeros(hmath_context *context, const hmath_value *a0,
                                                      hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(64, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_discrete_rotate_bits(hmath_context *context, const hmath_value *a0,
                                                   const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(65, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_reverse_bits(hmath_context *context, const hmath_value *a0,
                                                    hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(66, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_discrete_gray_encode(hmath_context *context, const hmath_value *a0,
                                                   hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(67, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_discrete_gray_decode(hmath_context *context, const hmath_value *a0,
                                                   hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(68, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_discrete_hamming_distance(hmath_context *context,
                                                        const hmath_value *a0,
                                                        const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(69, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_transitive_closure(hmath_context *context,
                                                          const hmath_value *a0,
                                                          hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(70, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_discrete_equivalence_closure(hmath_context *context,
                                                           const hmath_value *a0,
                                                           hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(71, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_discrete_is_equivalence(hmath_context *context, const hmath_value *a0,
                                                      hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(72, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_discrete_boolean_multiply(hmath_context *context,
                                                        const hmath_value *a0,
                                                        const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(73, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_evaluate_prop(hmath_context *context, const hmath_value *a0,
                                                     const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(74, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_truth_table(hmath_context *context, const hmath_value *a0,
                                                   const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(75, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_implicant_covers(hmath_context *context,
                                                        const hmath_value *a0,
                                                        const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(76, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_quine_mc_cluskey(hmath_context *context,
                                                        const hmath_value *a0,
                                                        const hmath_value *a1,
                                                        const hmath_value *a2,
                                                        const hmath_value *a3, hmath_value **out) {
    if (!out || !a0 || !a1 || !a2 || !a3)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2),
                    hm_value_stable(a3)};
    return hm_value_finish(result, hm_foundation_apply(77, args, 4, &result->stable), out);
}
hmath_status hmath_foundation_discrete_new_literal(hmath_context *context, const hmath_value *a0,
                                                   hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(78, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_discrete_new_variable(hmath_context *context, const hmath_value *a0,
                                                    hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(79, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_discrete_new_not(hmath_context *context, const hmath_value *a0,
                                               hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(80, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_discrete_new_and(hmath_context *context, const hmath_value *a0,
                                               const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(81, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_new_or(hmath_context *context, const hmath_value *a0,
                                              const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(82, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_new_xor(hmath_context *context, const hmath_value *a0,
                                               const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(83, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_new_implies(hmath_context *context, const hmath_value *a0,
                                                   const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(84, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_new_iff(hmath_context *context, const hmath_value *a0,
                                               const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(85, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_discrete_implicant_value(hmath_context *context,
                                                       const hmath_value *a0, hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(86, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_discrete_implicant_mask(hmath_context *context, const hmath_value *a0,
                                                      hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(87, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_discrete_new_implicant(hmath_context *context, const hmath_value *a0,
                                                     const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(88, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_algorithms_binary_search(hmath_context *context,
                                                       const hmath_value *a0, const hmath_value *a1,
                                                       hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(89, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_algorithms_interpolation_search(hmath_context *context,
                                                              const hmath_value *a0,
                                                              const hmath_value *a1,
                                                              hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(90, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_algorithms_exponential_search(hmath_context *context,
                                                            const hmath_value *a0,
                                                            const hmath_value *a1,
                                                            hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(91, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_algorithms_ternary_search(hmath_context *context,
                                                        const hmath_value *a0,
                                                        const hmath_value *a1,
                                                        const hmath_value *a2,
                                                        const hmath_value *a3, hmath_value **out) {
    if (!out || !a0 || !a1 || !a2 || !a3)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2),
                    hm_value_stable(a3)};
    return hm_value_finish(result, hm_foundation_apply(92, args, 4, &result->stable), out);
}
hmath_status hmath_foundation_algorithms_numeric_groups(hmath_context *context,
                                                        const hmath_value *a0, hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(93, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_algorithms_run_length_encode(hmath_context *context,
                                                           const hmath_value *a0,
                                                           hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(94, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_algorithms_run_length_decode(hmath_context *context,
                                                           const hmath_value *a0,
                                                           const hmath_value *a1,
                                                           hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(95, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_algorithms_coordinate_compression(hmath_context *context,
                                                                const hmath_value *a0,
                                                                hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(96, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_algorithms_interval_sweep(hmath_context *context,
                                                        const hmath_value *a0, hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(97, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_algorithms_divide_conquer_dp(hmath_context *context,
                                                           const hmath_value *a0,
                                                           const hmath_value *a1,
                                                           hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(98, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_algorithms_tabulate_dp(hmath_context *context, const hmath_value *a0,
                                                     const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(99, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_algorithms_memoized_dp(hmath_context *context, const hmath_value *a0,
                                                     const hmath_value *a1, const hmath_value *a2,
                                                     hmath_value **out) {
    if (!out || !a0 || !a1 || !a2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2)};
    return hm_value_finish(result, hm_foundation_apply(100, args, 3, &result->stable), out);
}
hmath_status hmath_foundation_algorithms_integer_matrix_power(hmath_context *context,
                                                              const hmath_value *a0,
                                                              const hmath_value *a1,
                                                              hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(101, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_combinatorics_permutations_of(hmath_context *context,
                                                            const hmath_value *a0,
                                                            const hmath_value *a1,
                                                            const hmath_value *a2,
                                                            hmath_value **out) {
    if (!out || !a0 || !a1 || !a2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2)};
    return hm_value_finish(result, hm_foundation_apply(102, args, 3, &result->stable), out);
}
hmath_status hmath_foundation_combinatorics_combinations_of(hmath_context *context,
                                                            const hmath_value *a0,
                                                            const hmath_value *a1,
                                                            const hmath_value *a2,
                                                            hmath_value **out) {
    if (!out || !a0 || !a1 || !a2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2)};
    return hm_value_finish(result, hm_foundation_apply(103, args, 3, &result->stable), out);
}
hmath_status hmath_foundation_combinatorics_derangements(hmath_context *context,
                                                         const hmath_value *a0,
                                                         const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(104, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_combinatorics_integer_partitions(hmath_context *context,
                                                               const hmath_value *a0,
                                                               const hmath_value *a1,
                                                               hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(105, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_combinatorics_set_partitions(hmath_context *context,
                                                           const hmath_value *a0,
                                                           const hmath_value *a1,
                                                           hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(106, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_combinatorics_pascal_triangle(hmath_context *context,
                                                            const hmath_value *a0,
                                                            hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(107, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_combinatorics_subsets(hmath_context *context, const hmath_value *a0,
                                                    const hmath_value *a1, hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(108, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_combinatorics_cartesian_product(hmath_context *context,
                                                              const hmath_value *a0,
                                                              const hmath_value *a1,
                                                              hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(109, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_combinatorics_multiset_permutations(hmath_context *context,
                                                                  const hmath_value *a0,
                                                                  const hmath_value *a1,
                                                                  hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(110, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_combinatorics_generating_coefficients(hmath_context *context,
                                                                    const hmath_value *a0,
                                                                    const hmath_value *a1,
                                                                    const hmath_value *a2,
                                                                    hmath_value **out) {
    if (!out || !a0 || !a1 || !a2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2)};
    return hm_value_finish(result, hm_foundation_apply(111, args, 3, &result->stable), out);
}
hmath_status hmath_foundation_combinatorics_finite_differences(hmath_context *context,
                                                               const hmath_value *prototype,
                                                               const hmath_value *a0,
                                                               hmath_value **out) {
    if (!out || !prototype || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(112, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_convergence_default_iteration_options(hmath_context *context,
                                                                    hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    return hm_value_finish(result, hm_foundation_apply(113, NULL, 0, &result->stable), out);
}
hmath_status hmath_foundation_convergence_iterate_until(
    hmath_context *context, const hmath_value *a0, const hmath_value *a1, const hmath_value *a2,
    const hmath_value *a3, const hmath_value *a4, hmath_value **out) {
    if (!out || !a0 || !a1 || !a2 || !a3 || !a4)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2),
                    hm_value_stable(a3), hm_value_stable(a4)};
    return hm_value_finish(result, hm_foundation_apply(114, args, 5, &result->stable), out);
}
hmath_status hmath_foundation_convergence_require_convergence(hmath_context *context,
                                                              const hmath_value *a0,
                                                              const hmath_value *a1,
                                                              hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(115, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_convergence_result_maybe(hmath_context *context,
                                                       const hmath_value *a0, hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(116, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_convergence_from_maybe_error(hmath_context *context,
                                                           const hmath_value *a0,
                                                           const hmath_value *a1,
                                                           hmath_value **out) {
    if (!out || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(117, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_convergence_new_residual_satisfied(hmath_context *context,
                                                                 hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    return hm_value_finish(result, hm_foundation_apply(118, NULL, 0, &result->stable), out);
}
hmath_status hmath_foundation_convergence_new_iteration_limit(hmath_context *context,
                                                              hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    return hm_value_finish(result, hm_foundation_apply(119, NULL, 0, &result->stable), out);
}
hmath_status hmath_foundation_convergence_new_stagnation(hmath_context *context,
                                                         hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    return hm_value_finish(result, hm_foundation_apply(120, NULL, 0, &result->stable), out);
}
hmath_status hmath_foundation_convergence_estimate(hmath_context *context, const hmath_value *a0,
                                                   hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(121, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_convergence_iteration_count(hmath_context *context,
                                                          const hmath_value *a0,
                                                          hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(122, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_convergence_final_residual(hmath_context *context,
                                                         const hmath_value *a0, hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(123, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_convergence_stop_reason(hmath_context *context, const hmath_value *a0,
                                                      hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(124, args, 1, &result->stable), out);
}
hmath_status
hmath_foundation_convergence_new_convergence(hmath_context *context, const hmath_value *a0,
                                             const hmath_value *a1, const hmath_value *a2,
                                             const hmath_value *a3, hmath_value **out) {
    if (!out || !a0 || !a1 || !a2 || !a3)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2),
                    hm_value_stable(a3)};
    return hm_value_finish(result, hm_foundation_apply(125, args, 4, &result->stable), out);
}
hmath_status hmath_foundation_convergence_maximum_iterations(hmath_context *context,
                                                             const hmath_value *a0,
                                                             hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(126, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_convergence_absolute_tolerance(hmath_context *context,
                                                             const hmath_value *a0,
                                                             hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(127, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_convergence_relative_tolerance(hmath_context *context,
                                                             const hmath_value *a0,
                                                             hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(128, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_convergence_new_iteration_options(hmath_context *context,
                                                                const hmath_value *a0,
                                                                const hmath_value *a1,
                                                                const hmath_value *a2,
                                                                hmath_value **out) {
    if (!out || !a0 || !a1 || !a2)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0), hm_value_stable(a1), hm_value_stable(a2)};
    return hm_value_finish(result, hm_foundation_apply(129, args, 3, &result->stable), out);
}
hmath_status hmath_foundation_convergence_converged(hmath_context *context, const hmath_value *a0,
                                                    hmath_value **out) {
    if (!out || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(130, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_datastructure_next_greater_typed(hmath_context *context,
                                                               const hmath_value *prototype,
                                                               const hmath_value *a0,
                                                               hmath_value **out) {
    if (!out || !prototype || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(131, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_algorithms_binary_search_typed(hmath_context *context,
                                                             const hmath_value *prototype,
                                                             const hmath_value *a0,
                                                             const hmath_value *a1,
                                                             hmath_value **out) {
    if (!out || !prototype || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(132, args, 3, &result->stable), out);
}
hmath_status hmath_foundation_algorithms_exponential_search_typed(hmath_context *context,
                                                                  const hmath_value *prototype,
                                                                  const hmath_value *a0,
                                                                  const hmath_value *a1,
                                                                  hmath_value **out) {
    if (!out || !prototype || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(133, args, 3, &result->stable), out);
}
hmath_status hmath_foundation_algorithms_numeric_groups_typed(hmath_context *context,
                                                              const hmath_value *prototype,
                                                              const hmath_value *a0,
                                                              hmath_value **out) {
    if (!out || !prototype || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(134, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_algorithms_coordinate_compression_typed(hmath_context *context,
                                                                      const hmath_value *prototype,
                                                                      const hmath_value *a0,
                                                                      hmath_value **out) {
    if (!out || !prototype || !a0)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0)};
    return hm_value_finish(result, hm_foundation_apply(135, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_combinatorics_multiset_permutations_typed(
    hmath_context *context, const hmath_value *prototype, const hmath_value *a0,
    const hmath_value *a1, hmath_value **out) {
    if (!out || !prototype || !a0 || !a1)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(a0), hm_value_stable(a1)};
    return hm_value_finish(result, hm_foundation_apply(136, args, 3, &result->stable), out);
}
hmath_status hmath_foundation_object_type(hmath_context *context, const hmath_value *value,
                                          hmath_value **out) {
    if (!value || !out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation query");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(value)};
    return hm_value_finish(result, hm_foundation_apply(-1, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_object_parts(hmath_context *context, const hmath_value *value,
                                           hmath_value **out) {
    if (!value || !out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation query");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(value)};
    return hm_value_finish(result, hm_foundation_apply(-2, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_left(hmath_context *context, const hmath_value *value,
                                   hmath_value **out) {
    if (!value || !out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation query");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(value)};
    return hm_value_finish(result, hm_foundation_apply(-3, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_right(hmath_context *context, const hmath_value *value,
                                    hmath_value **out) {
    if (!value || !out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation query");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(value)};
    return hm_value_finish(result, hm_foundation_apply(-4, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_just(hmath_context *context, const hmath_value *value,
                                   hmath_value **out) {
    if (!value || !out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation query");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(value)};
    return hm_value_finish(result, hm_foundation_apply(-5, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_ordered_type(hmath_context *context, const hmath_value *value,
                                           hmath_value **out) {
    if (!value || !out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation query");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(value)};
    return hm_value_finish(result, hm_foundation_apply(-6, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_optional_type(hmath_context *context, const hmath_value *value,
                                            hmath_value **out) {
    if (!value || !out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL foundation query");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(value)};
    return hm_value_finish(result, hm_foundation_apply(-7, args, 1, &result->stable), out);
}
hmath_status hmath_foundation_heap_from_list_typed(hmath_context *context,
                                                   const hmath_value *prototype,
                                                   const hmath_value *values, hmath_value **out) {
    if (!prototype || !values || !out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL typed container argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(values)};
    return hm_value_finish(result, hm_foundation_apply(-8, args, 2, &result->stable), out);
}
hmath_status hmath_foundation_multiset_typed(hmath_context *context, const hmath_value *prototype,
                                             const hmath_value *values, hmath_value **out) {
    if (!prototype || !values || !out)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL typed container argument");
    hmath_value *result;
    hmath_status status = hm_value_begin(context, &result);
    if (status)
        return status;
    void *args[] = {hm_value_stable(prototype), hm_value_stable(values)};
    return hm_value_finish(result, hm_foundation_apply(-9, args, 2, &result->stable), out);
}
