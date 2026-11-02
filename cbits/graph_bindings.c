/* SPDX-License-Identifier: MPL-2.0 */
/* Generated; do not edit. */
#include "hmath_graph.h"
#include "value_internal.h"
extern int hm_graph_apply(int, void *const *, size_t, hmath_graph_heuristic, void *, void **);
hmath_status hmath_graph_betweenness_centrality(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(0, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_bipartite_colors(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(1, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_closeness_centrality(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(2, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_clustering_coefficients(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(3, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_degree_centrality(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(4, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_density(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(5, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_diameter_radius(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(6, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_eigenvector_centrality(
    hmath_context *context,
    const hmath_value *iterations,
    const hmath_value *tolerance,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !iterations || !tolerance || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(iterations), hm_value_stable(tolerance), hm_value_stable(graph)};
    int code = hm_graph_apply(7, arguments, 3, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_eulerian_path(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(8, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_exact_coloring(
    hmath_context *context,
    const hmath_value *fuel,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !fuel || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(fuel), hm_value_stable(graph)};
    int code = hm_graph_apply(9, arguments, 2, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_graph_edit_distance(
    hmath_context *context,
    const hmath_value *budget,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out) {
    if (!out || !budget || !left || !right)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(budget), hm_value_stable(left), hm_value_stable(right)};
    int code = hm_graph_apply(10, arguments, 3, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_graph_laplacian(
    hmath_context *context,
    const hmath_value *normalized,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !normalized || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(normalized), hm_value_stable(graph)};
    int code = hm_graph_apply(11, arguments, 2, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_graph_similarity(
    hmath_context *context,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out) {
    if (!out || !left || !right)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(left), hm_value_stable(right)};
    int code = hm_graph_apply(12, arguments, 2, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_greedy_coloring(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(13, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_hamiltonian_path(
    hmath_context *context,
    const hmath_value *fuel,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !fuel || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(fuel), hm_value_stable(graph)};
    int code = hm_graph_apply(14, arguments, 2, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_katz_centrality(
    hmath_context *context,
    const hmath_value *iterations,
    const hmath_value *tolerance,
    const hmath_value *alpha,
    const hmath_value *beta,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !iterations || !tolerance || !alpha || !beta || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(iterations), hm_value_stable(tolerance), hm_value_stable(alpha), hm_value_stable(beta), hm_value_stable(graph)};
    int code = hm_graph_apply(15, arguments, 5, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_label_propagation(
    hmath_context *context,
    const hmath_value *iterations,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !iterations || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(iterations), hm_value_stable(graph)};
    int code = hm_graph_apply(16, arguments, 2, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_laplacian_spectrum(
    hmath_context *context,
    const hmath_value *iterations,
    const hmath_value *tolerance,
    const hmath_value *normalized,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !iterations || !tolerance || !normalized || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(iterations), hm_value_stable(tolerance), hm_value_stable(normalized), hm_value_stable(graph)};
    int code = hm_graph_apply(17, arguments, 4, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_louvain(
    hmath_context *context,
    const hmath_value *budget,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !budget || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(budget), hm_value_stable(graph)};
    int code = hm_graph_apply(18, arguments, 2, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_modularity(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *labels,
    hmath_value **out) {
    if (!out || !graph || !labels)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph), hm_value_stable(labels)};
    int code = hm_graph_apply(19, arguments, 2, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_nearest_neighbor_tour(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *start,
    hmath_value **out) {
    if (!out || !graph || !start)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph), hm_value_stable(start)};
    int code = hm_graph_apply(20, arguments, 2, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_page_rank(
    hmath_context *context,
    const hmath_value *iterations,
    const hmath_value *tolerance,
    const hmath_value *damping,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !iterations || !tolerance || !damping || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(iterations), hm_value_stable(tolerance), hm_value_stable(damping), hm_value_stable(graph)};
    int code = hm_graph_apply(21, arguments, 4, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_random_walk(
    hmath_context *context,
    const hmath_value *count,
    const hmath_value *seed,
    const hmath_value *graph,
    const hmath_value *start,
    hmath_value **out) {
    if (!out || !count || !seed || !graph || !start)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(count), hm_value_stable(seed), hm_value_stable(graph), hm_value_stable(start)};
    int code = hm_graph_apply(22, arguments, 4, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_two_opt_tour(
    hmath_context *context,
    const hmath_value *iterations,
    const hmath_value *graph,
    const hmath_value *tour,
    hmath_value **out) {
    if (!out || !iterations || !graph || !tour)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(iterations), hm_value_stable(graph), hm_value_stable(tour)};
    int code = hm_graph_apply(23, arguments, 3, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_csr(
    hmath_context *context,
    const hmath_value *directed,
    const hmath_value *vertex_count,
    const hmath_value *offsets,
    const hmath_value *targets,
    const hmath_value *weights,
    const hmath_value *edge_ids,
    const hmath_value *orientations,
    hmath_value **out) {
    if (!out || !directed || !vertex_count || !offsets || !targets || !weights || !edge_ids || !orientations)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(directed), hm_value_stable(vertex_count), hm_value_stable(offsets), hm_value_stable(targets), hm_value_stable(weights), hm_value_stable(edge_ids), hm_value_stable(orientations)};
    int code = hm_graph_apply(24, arguments, 7, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_edge(
    hmath_context *context,
    const hmath_value *edge_id,
    const hmath_value *source,
    const hmath_value *target,
    const hmath_value *weight,
    hmath_value **out) {
    if (!out || !edge_id || !source || !target || !weight)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(edge_id), hm_value_stable(source), hm_value_stable(target), hm_value_stable(weight)};
    int code = hm_graph_apply(25, arguments, 4, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_adjacency_list(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(26, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_adjacency_matrix(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(27, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_arcs(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(28, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_articulation_points(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(29, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_bfs(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *start,
    hmath_value **out) {
    if (!out || !graph || !start)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph), hm_value_stable(start)};
    int code = hm_graph_apply(30, arguments, 2, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_bipartite_base(
    hmath_context *context,
    const hmath_value *bipartite_graph,
    hmath_value **out) {
    if (!out || !bipartite_graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(bipartite_graph)};
    int code = hm_graph_apply(31, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_bipartite_graph(
    hmath_context *context,
    const hmath_value *left_vertices,
    const hmath_value *right_vertices,
    const hmath_value *edges,
    hmath_value **out) {
    if (!out || !left_vertices || !right_vertices || !edges)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(left_vertices), hm_value_stable(right_vertices), hm_value_stable(edges)};
    int code = hm_graph_apply(32, arguments, 3, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_bipartite_parts(
    hmath_context *context,
    const hmath_value *bipartite_graph,
    hmath_value **out) {
    if (!out || !bipartite_graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(bipartite_graph)};
    int code = hm_graph_apply(33, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_boruvka(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(34, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_bridges(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(35, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_check_vertex(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *vertex,
    hmath_value **out) {
    if (!out || !graph || !vertex)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph), hm_value_stable(vertex)};
    int code = hm_graph_apply(36, arguments, 2, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_connected_components(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(37, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_csr_directed(
    hmath_context *context,
    const hmath_value *csr,
    hmath_value **out) {
    if (!out || !csr)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(csr)};
    int code = hm_graph_apply(38, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_csr_ids(
    hmath_context *context,
    const hmath_value *csr,
    hmath_value **out) {
    if (!out || !csr)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(csr)};
    int code = hm_graph_apply(39, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_csr_offsets(
    hmath_context *context,
    const hmath_value *csr,
    hmath_value **out) {
    if (!out || !csr)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(csr)};
    int code = hm_graph_apply(40, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_csr_orientations(
    hmath_context *context,
    const hmath_value *csr,
    hmath_value **out) {
    if (!out || !csr)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(csr)};
    int code = hm_graph_apply(41, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_csr_targets(
    hmath_context *context,
    const hmath_value *csr,
    hmath_value **out) {
    if (!out || !csr)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(csr)};
    int code = hm_graph_apply(42, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_csr_vertices(
    hmath_context *context,
    const hmath_value *csr,
    hmath_value **out) {
    if (!out || !csr)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(csr)};
    int code = hm_graph_apply(43, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_csr_weights(
    hmath_context *context,
    const hmath_value *csr,
    hmath_value **out) {
    if (!out || !csr)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(csr)};
    int code = hm_graph_apply(44, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_deserialize_bipartite_graph(
    hmath_context *context,
    const hmath_value *text,
    hmath_value **out) {
    if (!out || !text)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(text)};
    int code = hm_graph_apply(45, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_deserialize_graph(
    hmath_context *context,
    const hmath_value *text,
    hmath_value **out) {
    if (!out || !text)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(text)};
    int code = hm_graph_apply(46, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_deserialize_hypergraph(
    hmath_context *context,
    const hmath_value *text,
    hmath_value **out) {
    if (!out || !text)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(text)};
    int code = hm_graph_apply(47, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_dfs(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *start,
    hmath_value **out) {
    if (!out || !graph || !start)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph), hm_value_stable(start)};
    int code = hm_graph_apply(48, arguments, 2, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_directed(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(49, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_edge_from(
    hmath_context *context,
    const hmath_value *edge,
    hmath_value **out) {
    if (!out || !edge)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(edge)};
    int code = hm_graph_apply(50, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_edge_id(
    hmath_context *context,
    const hmath_value *edge,
    hmath_value **out) {
    if (!out || !edge)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(edge)};
    int code = hm_graph_apply(51, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_edge_to(
    hmath_context *context,
    const hmath_value *edge,
    hmath_value **out) {
    if (!out || !edge)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(edge)};
    int code = hm_graph_apply(52, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_edge_weight(
    hmath_context *context,
    const hmath_value *edge,
    hmath_value **out) {
    if (!out || !edge)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(edge)};
    int code = hm_graph_apply(53, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_edges(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(54, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_finite(
    hmath_context *context,
    const hmath_value *x,
    hmath_value **out) {
    if (!out || !x)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(x)};
    int code = hm_graph_apply(55, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_from_adjacency_list(
    hmath_context *context,
    const hmath_value *directed,
    const hmath_value *rows,
    const hmath_value *orientations,
    hmath_value **out) {
    if (!out || !directed || !rows || !orientations)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(directed), hm_value_stable(rows), hm_value_stable(orientations)};
    int code = hm_graph_apply(56, arguments, 3, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_from_adjacency_matrix(
    hmath_context *context,
    const hmath_value *directed,
    const hmath_value *cells,
    hmath_value **out) {
    if (!out || !directed || !cells)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(directed), hm_value_stable(cells)};
    int code = hm_graph_apply(57, arguments, 2, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_from_csr(
    hmath_context *context,
    const hmath_value *csr,
    hmath_value **out) {
    if (!out || !csr)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(csr)};
    int code = hm_graph_apply(58, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_from_labeled_adjacency_matrix(
    hmath_context *context,
    const hmath_value *directed,
    const hmath_value *cells,
    const hmath_value *orientations,
    hmath_value **out) {
    if (!out || !directed || !cells || !orientations)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(directed), hm_value_stable(cells), hm_value_stable(orientations)};
    int code = hm_graph_apply(59, arguments, 3, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_graph(
    hmath_context *context,
    const hmath_value *directed,
    const hmath_value *vertex_count,
    const hmath_value *edges,
    hmath_value **out) {
    if (!out || !directed || !vertex_count || !edges)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(directed), hm_value_stable(vertex_count), hm_value_stable(edges)};
    int code = hm_graph_apply(60, arguments, 3, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_has_cycle(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(61, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_hyper_vertices(
    hmath_context *context,
    const hmath_value *hypergraph,
    hmath_value **out) {
    if (!out || !hypergraph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(hypergraph)};
    int code = hm_graph_apply(62, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_hyperedges(
    hmath_context *context,
    const hmath_value *hypergraph,
    hmath_value **out) {
    if (!out || !hypergraph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(hypergraph)};
    int code = hm_graph_apply(63, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_hypergraph(
    hmath_context *context,
    const hmath_value *vertex_count,
    const hmath_value *hyperedges,
    hmath_value **out) {
    if (!out || !vertex_count || !hyperedges)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(vertex_count), hm_value_stable(hyperedges)};
    int code = hm_graph_apply(64, arguments, 2, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_iterative_deepening(
    hmath_context *context,
    const hmath_value *budget,
    const hmath_value *graph,
    const hmath_value *source,
    const hmath_value *target,
    hmath_value **out) {
    if (!out || !budget || !graph || !source || !target)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(budget), hm_value_stable(graph), hm_value_stable(source), hm_value_stable(target)};
    int code = hm_graph_apply(65, arguments, 4, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_kosaraju_scc(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(66, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_kruskal(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(67, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_neighbors(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *vertex,
    hmath_value **out) {
    if (!out || !graph || !vertex)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph), hm_value_stable(vertex)};
    int code = hm_graph_apply(68, arguments, 2, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_prim(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(69, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_require_undirected(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(70, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_serialize_bipartite_graph(
    hmath_context *context,
    const hmath_value *bipartite,
    hmath_value **out) {
    if (!out || !bipartite)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(bipartite)};
    int code = hm_graph_apply(71, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_serialize_graph(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(72, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_serialize_hypergraph(
    hmath_context *context,
    const hmath_value *hypergraph,
    hmath_value **out) {
    if (!out || !hypergraph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(hypergraph)};
    int code = hm_graph_apply(73, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_tarjan_scc(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(74, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_to_csr(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(75, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_topological_sort(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(76, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_vertex_count(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(77, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_flow_result(
    hmath_context *context,
    const hmath_value *value,
    const hmath_value *edge_flows,
    const hmath_value *cost,
    hmath_value **out) {
    if (!out || !value || !edge_flows || !cost)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(value), hm_value_stable(edge_flows), hm_value_stable(cost)};
    int code = hm_graph_apply(78, arguments, 3, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_network_edge(
    hmath_context *context,
    const hmath_value *edge_id,
    const hmath_value *source,
    const hmath_value *target,
    const hmath_value *capacity,
    const hmath_value *cost,
    hmath_value **out) {
    if (!out || !edge_id || !source || !target || !capacity || !cost)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(edge_id), hm_value_stable(source), hm_value_stable(target), hm_value_stable(capacity), hm_value_stable(cost)};
    int code = hm_graph_apply(79, arguments, 5, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_dinic(
    hmath_context *context,
    const hmath_value *budget,
    const hmath_value *network,
    const hmath_value *source,
    const hmath_value *target,
    hmath_value **out) {
    if (!out || !budget || !network || !source || !target)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(budget), hm_value_stable(network), hm_value_stable(source), hm_value_stable(target)};
    int code = hm_graph_apply(80, arguments, 4, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_edge_flows(
    hmath_context *context,
    const hmath_value *flow_result,
    hmath_value **out) {
    if (!out || !flow_result)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(flow_result)};
    int code = hm_graph_apply(81, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_edmonds_karp(
    hmath_context *context,
    const hmath_value *value,
    const hmath_value *network,
    const hmath_value *value3,
    const hmath_value *value4,
    hmath_value **out) {
    if (!out || !value || !network || !value3 || !value4)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(value), hm_value_stable(network), hm_value_stable(value3), hm_value_stable(value4)};
    int code = hm_graph_apply(82, arguments, 4, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_flow_cost(
    hmath_context *context,
    const hmath_value *flow_result,
    hmath_value **out) {
    if (!out || !flow_result)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(flow_result)};
    int code = hm_graph_apply(83, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_flow_value(
    hmath_context *context,
    const hmath_value *flow_result,
    hmath_value **out) {
    if (!out || !flow_result)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(flow_result)};
    int code = hm_graph_apply(84, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_ford_fulkerson(
    hmath_context *context,
    const hmath_value *value,
    const hmath_value *network,
    const hmath_value *value3,
    const hmath_value *value4,
    hmath_value **out) {
    if (!out || !value || !network || !value3 || !value4)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(value), hm_value_stable(network), hm_value_stable(value3), hm_value_stable(value4)};
    int code = hm_graph_apply(85, arguments, 4, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_hopcroft_karp(
    hmath_context *context,
    const hmath_value *bipartite,
    hmath_value **out) {
    if (!out || !bipartite)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(bipartite)};
    int code = hm_graph_apply(86, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_hungarian(
    hmath_context *context,
    const hmath_value *costs,
    hmath_value **out) {
    if (!out || !costs)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(costs)};
    int code = hm_graph_apply(87, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_minimum_cost_maximum_flow(
    hmath_context *context,
    const hmath_value *value,
    const hmath_value *network,
    const hmath_value *value3,
    const hmath_value *value4,
    hmath_value **out) {
    if (!out || !value || !network || !value3 || !value4)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(value), hm_value_stable(network), hm_value_stable(value3), hm_value_stable(value4)};
    int code = hm_graph_apply(88, arguments, 4, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_minimum_cut(
    hmath_context *context,
    const hmath_value *value,
    const hmath_value *network,
    const hmath_value *value3,
    const hmath_value *value4,
    hmath_value **out) {
    if (!out || !value || !network || !value3 || !value4)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(value), hm_value_stable(network), hm_value_stable(value3), hm_value_stable(value4)};
    int code = hm_graph_apply(89, arguments, 4, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_network(
    hmath_context *context,
    const hmath_value *vertex_count,
    const hmath_value *edges,
    hmath_value **out) {
    if (!out || !vertex_count || !edges)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(vertex_count), hm_value_stable(edges)};
    int code = hm_graph_apply(90, arguments, 2, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_network_capacity(
    hmath_context *context,
    const hmath_value *network_edge,
    hmath_value **out) {
    if (!out || !network_edge)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(network_edge)};
    int code = hm_graph_apply(91, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_network_cost(
    hmath_context *context,
    const hmath_value *network_edge,
    hmath_value **out) {
    if (!out || !network_edge)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(network_edge)};
    int code = hm_graph_apply(92, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_network_edge_id(
    hmath_context *context,
    const hmath_value *network_edge,
    hmath_value **out) {
    if (!out || !network_edge)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(network_edge)};
    int code = hm_graph_apply(93, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_network_edges(
    hmath_context *context,
    const hmath_value *network,
    hmath_value **out) {
    if (!out || !network)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(network)};
    int code = hm_graph_apply(94, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_network_from(
    hmath_context *context,
    const hmath_value *network_edge,
    hmath_value **out) {
    if (!out || !network_edge)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(network_edge)};
    int code = hm_graph_apply(95, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_network_to(
    hmath_context *context,
    const hmath_value *network_edge,
    hmath_value **out) {
    if (!out || !network_edge)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(network_edge)};
    int code = hm_graph_apply(96, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_push_relabel(
    hmath_context *context,
    const hmath_value *value,
    const hmath_value *network,
    const hmath_value *value3,
    const hmath_value *value4,
    hmath_value **out) {
    if (!out || !value || !network || !value3 || !value4)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(value), hm_value_stable(network), hm_value_stable(value3), hm_value_stable(value4)};
    int code = hm_graph_apply(97, arguments, 4, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_a_star(
    hmath_context *context,
    const hmath_value *graph,
    hmath_graph_heuristic heuristic,
    void *userdata,
    const hmath_value *source,
    const hmath_value *target,
    hmath_value **out) {
    if (!out || !graph || !source || !target || !heuristic)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph), hm_value_stable(source), hm_value_stable(target)};
    int code = hm_graph_apply(98, arguments, 3, heuristic, userdata, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_bellman_ford(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *source,
    hmath_value **out) {
    if (!out || !graph || !source)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph), hm_value_stable(source)};
    int code = hm_graph_apply(99, arguments, 2, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_bidirectional_dijkstra(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *source,
    const hmath_value *target,
    hmath_value **out) {
    if (!out || !graph || !source || !target)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph), hm_value_stable(source), hm_value_stable(target)};
    int code = hm_graph_apply(100, arguments, 3, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_dijkstra(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *source,
    hmath_value **out) {
    if (!out || !graph || !source)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph), hm_value_stable(source)};
    int code = hm_graph_apply(101, arguments, 2, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_floyd_warshall(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(102, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_johnson(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out) {
    if (!out || !graph)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph)};
    int code = hm_graph_apply(103, arguments, 1, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_k_shortest_paths(
    hmath_context *context,
    const hmath_value *budget,
    const hmath_value *count,
    const hmath_value *graph,
    const hmath_value *source,
    const hmath_value *target,
    hmath_value **out) {
    if (!out || !budget || !count || !graph || !source || !target)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(budget), hm_value_stable(count), hm_value_stable(graph), hm_value_stable(source), hm_value_stable(target)};
    int code = hm_graph_apply(104, arguments, 5, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_longest_dag_paths(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *source,
    hmath_value **out) {
    if (!out || !graph || !source)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph), hm_value_stable(source)};
    int code = hm_graph_apply(105, arguments, 2, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
hmath_status hmath_graph_multi_source_dijkstra(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *sources,
    hmath_value **out) {
    if (!out || !graph || !sources)
        return hm_error(HMATH_INVALID_ARGUMENT, "NULL Graph argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context, &temporary);
    if (status)
        return status;
    void *arguments[] = {hm_value_stable(graph), hm_value_stable(sources)};
    int code = hm_graph_apply(106, arguments, 2, NULL, NULL, &temporary->stable);
    return hm_value_finish(temporary, code, out);
}
