# Graph bindings

These adapters call the original Graph functions. Vertex/edge limits, tie order, loops, parallel edges, exact flow capacities and original algorithm budgets are preserved.

C uses `hmath_graph.h` with owned [structured values](values.md). Python uses `from hmath import graph`. Opaque graph objects support `close()` and context managers. Returned lists, tuples, Booleans, strings, integers, optional values and binary64 values use ordinary Python representations.

C output handles are owned and remain untouched on failure. Inputs are borrowed throughout a call; callers retain references. Independent calls may share immutable objects and must use independent output addresses. Source `Left MathError` uses status 11 with a lossless structured error. `Maybe` uses `None`/value kind 0. Checked cancellation occurs before entry; source algorithm budgets are not changed.

## `betweenness_centrality`

`graph.betweenness_centrality(graph)`

 Return unweighted shortest-path betweenness by vertex, accounting for shortest-path multiplicities. Undirected scores are halved; edge weights are not path lengths here. 

Original: [`HMath.Graph.Analysis.betweennessCentrality`](haskell/HMath-Graph-Analysis.md#v:betweennessCentrality). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> [Double]
```

```c
hmath_status hmath_graph_betweenness_centrality(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `bipartite_colors`

`graph.bipartite_colors(graph)`

 Return Just Bool colors for every vertex if the underlying undirected adjacency is bipartite, including disconnected components; conflicting edges/loops yield Nothing. 

Original: [`HMath.Graph.Analysis.bipartiteColors`](haskell/HMath-Graph-Analysis.md#v:bipartiteColors). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Maybe [Bool]
```

```c
hmath_status hmath_graph_bipartite_colors(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `closeness_centrality`

`graph.closeness_centrality(graph)`

 Return unweighted closeness with reachable-component correction: reachable^2/((n-1)*sumDistances). Isolated/singleton vertices yield zero. 

Original: [`HMath.Graph.Analysis.closenessCentrality`](haskell/HMath-Graph-Analysis.md#v:closenessCentrality). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> [Double]
```

```c
hmath_status hmath_graph_closeness_centrality(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `clustering_coefficients`

`graph.clustering_coefficients(graph)`

 Return local undirected clustering coefficients from distinct non-self neighbor sets. Degree below two yields zero. Directed graphs fail. 

Original: [`HMath.Graph.Analysis.clusteringCoefficients`](haskell/HMath-Graph-Analysis.md#v:clusteringCoefficients). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Either MathError [Double]
```

```c
hmath_status hmath_graph_clustering_coefficients(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `degree_centrality`

`graph.degree_centrality(graph)`

 Return outgoing traversal degree divided by n-1 for each vertex; n<=1 yields zeros. Undirected loops contribute twice and parallel edges are retained, so values can exceed one. 

Original: [`HMath.Graph.Analysis.degreeCentrality`](haskell/HMath-Graph-Analysis.md#v:degreeCentrality). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> [Double]
```

```c
hmath_status hmath_graph_degree_centrality(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `density`

`graph.density(graph)`

Simple graph density: parallel edges and loops are ignored.

Original: [`HMath.Graph.Analysis.density`](haskell/HMath-Graph-Analysis.md#v:density). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Double
```

```c
hmath_status hmath_graph_density(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `diameter_radius`

`graph.diameter_radius(graph)`

 Nothing if disconnected (not strongly connected for directed graphs). The empty graph has no diameter/radius; a singleton has (0,0). 

Original: [`HMath.Graph.Analysis.diameterRadius`](haskell/HMath-Graph-Analysis.md#v:diameterRadius). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Maybe (Int, Int)
```

```c
hmath_status hmath_graph_diameter_radius(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `eigenvector_centrality`

`graph.eigenvector_centrality(iterations, tolerance, graph)`

 Shifted power iteration on (I+A), avoiding sign oscillation on bipartite graphs. For reducible graphs the initial all-ones vector selects a Perron combination; convergence and uniqueness are not promised. 

Original: [`HMath.Graph.Analysis.eigenvectorCentrality`](haskell/HMath-Graph-Analysis.md#v:eigenvectorCentrality). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Double -> Graph -> Either MathError [Double]
```

```c
hmath_status hmath_graph_eigenvector_centrality(
    hmath_context *context,
    const hmath_value *iterations,
    const hmath_value *tolerance,
    const hmath_value *graph,
    hmath_value **out);
```

## `eulerian_path`

`graph.eulerian_path(graph)`

 Hierholzer trail, consuming each original edge identity once. A directed trail follows edge directions; disconnected nonisolated components fail. 

Original: [`HMath.Graph.Analysis.eulerianPath`](haskell/HMath-Graph-Analysis.md#v:eulerianPath). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Either MathError (Maybe ([Int], [Int]))
```

```c
hmath_status hmath_graph_eulerian_path(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `exact_coloring`

`graph.exact_coloring(fuel, graph)`

 Given work budget then graph with at most 24 vertices, search for a minimum proper coloring. Invalid budget/size or self-loops fail; exhausted search returns NonConvergence. 

Original: [`HMath.Graph.Analysis.exactColoring`](haskell/HMath-Graph-Analysis.md#v:exactColoring). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Graph -> Either MathError [Int]
```

```c
hmath_status hmath_graph_exact_coloring(
    hmath_context *context,
    const hmath_value *fuel,
    const hmath_value *graph,
    hmath_value **out);
```

## `graph_edit_distance`

`graph.graph_edit_distance(budget, left, right)`

 Exact unlabeled graph edit distance: unit vertex/edge insertion/deletion, edge weights are exact labels; relabeling vertices is free. Substitution is deletion plus insertion. Enumerates padded vertex bijections, at most 9 nodes. 

Original: [`HMath.Graph.Analysis.graphEditDistance`](haskell/HMath-Graph-Analysis.md#v:graphEditDistance). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Graph -> Graph -> Either MathError Int
```

```c
hmath_status hmath_graph_graph_edit_distance(
    hmath_context *context,
    const hmath_value *budget,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out);
```

## `graph_laplacian`

`graph.graph_laplacian(normalized, graph)`

 Given normalized Bool then nonnegative-weight undirected graph, return dense combinatorial or normalized Laplacian rows. Directed/negative-weight graphs or non-finite arithmetic fail. 

Original: [`HMath.Graph.Analysis.graphLaplacian`](haskell/HMath-Graph-Analysis.md#v:graphLaplacian). Argument order and the full contract are defined there; the original type is:

```haskell
Bool -> Graph -> Either MathError [[Double]]
```

```c
hmath_status hmath_graph_graph_laplacian(
    hmath_context *context,
    const hmath_value *normalized,
    const hmath_value *graph,
    hmath_value **out);
```

## `graph_similarity`

`graph.graph_similarity(left, right)`

 Jaccard similarity of labeled weighted edge multisets (vertex labels fixed), counting matching multiplicities. Empty edge multisets have similarity one. 

Original: [`HMath.Graph.Analysis.graphSimilarity`](haskell/HMath-Graph-Analysis.md#v:graphSimilarity). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Graph -> Either MathError Double
```

```c
hmath_status hmath_graph_graph_similarity(
    hmath_context *context,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out);
```

## `greedy_coloring`

`graph.greedy_coloring(graph)`

 Return zero-based greedy colors in vertex order using underlying undirected adjacency. A self-loop makes proper coloring impossible and returns Left DomainError. Minimal color count is not guaranteed. 

Original: [`HMath.Graph.Analysis.greedyColoring`](haskell/HMath-Graph-Analysis.md#v:greedyColoring). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Either MathError [Int]
```

```c
hmath_status hmath_graph_greedy_coloring(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `hamiltonian_path`

`graph.hamiltonian_path(fuel, graph)`

 Given search budget then graph, find a path visiting every vertex once, returning Maybe vertex list. Invalid options/exhausted budget fail; Nothing means exhaustive search found no path. 

Original: [`HMath.Graph.Analysis.hamiltonianPath`](haskell/HMath-Graph-Analysis.md#v:hamiltonianPath). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Graph -> Either MathError (Maybe [Int])
```

```c
hmath_status hmath_graph_hamiltonian_path(
    hmath_context *context,
    const hmath_value *fuel,
    const hmath_value *graph,
    hmath_value **out);
```

## `katz_centrality`

`graph.katz_centrality(iterations, tolerance, alpha, beta, graph)`

 Given iterations,tolerance,alpha,beta,then graph, iterate weighted Katz scores. Require finite alpha>=0 and alpha times maximum absolute incoming weight sum \<1. Invalid input or nonconvergence fails. 

Original: [`HMath.Graph.Analysis.katzCentrality`](haskell/HMath-Graph-Analysis.md#v:katzCentrality). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Double -> Double -> Double -> Graph -> Either MathError [Double]
```

```c
hmath_status hmath_graph_katz_centrality(
    hmath_context *context,
    const hmath_value *iterations,
    const hmath_value *tolerance,
    const hmath_value *alpha,
    const hmath_value *beta,
    const hmath_value *graph,
    hmath_value **out);
```

## `label_propagation`

`graph.label_propagation(iterations, graph)`

 Deterministic asynchronous label propagation. Budget counts full sweeps; equal weighted votes retain the current label when possible. 

Original: [`HMath.Graph.Analysis.labelPropagation`](haskell/HMath-Graph-Analysis.md#v:labelPropagation). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Graph -> Either MathError [Int]
```

```c
hmath_status hmath_graph_label_propagation(
    hmath_context *context,
    const hmath_value *iterations,
    const hmath_value *graph,
    hmath_value **out);
```

## `laplacian_spectrum`

`graph.laplacian_spectrum(iterations, tolerance, normalized, graph)`

 Symmetric Jacobi rotations; eigenvalues sorted ascending. Budget counts rotations, tolerance is relative to the matrix's largest absolute entry. 

Original: [`HMath.Graph.Analysis.laplacianSpectrum`](haskell/HMath-Graph-Analysis.md#v:laplacianSpectrum). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Double -> Bool -> Graph -> Either MathError [Double]
```

```c
hmath_status hmath_graph_laplacian_spectrum(
    hmath_context *context,
    const hmath_value *iterations,
    const hmath_value *tolerance,
    const hmath_value *normalized,
    const hmath_value *graph,
    hmath_value **out);
```

## `louvain`

`graph.louvain(budget, graph)`

 Louvain local modularity moves followed by graph aggregation, repeated until no communities merge. Deterministic local optimum, not a global optimum. Budget counts every modularity candidate evaluation across levels. 

Original: [`HMath.Graph.Analysis.louvain`](haskell/HMath-Graph-Analysis.md#v:louvain). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Graph -> Either MathError [Int]
```

```c
hmath_status hmath_graph_louvain(
    hmath_context *context,
    const hmath_value *budget,
    const hmath_value *graph,
    hmath_value **out);
```

## `modularity`

`graph.modularity(graph, labels)`

 Given undirected nonnegative-weight graph then one community label per vertex, return weighted modularity. Invalid graph/label length or arithmetic fails; loops follow the module degree convention. 

Original: [`HMath.Graph.Analysis.modularity`](haskell/HMath-Graph-Analysis.md#v:modularity). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> [Int] -> Either MathError Double
```

```c
hmath_status hmath_graph_modularity(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *labels,
    hmath_value **out);
```

## `nearest_neighbor_tour`

`graph.nearest_neighbor_tour(graph, start)`

 Nearest-neighbor closed tour heuristic; incomplete graphs may fail. This heuristic promises a valid tour, without an optimality/approximation bound. 

Original: [`HMath.Graph.Analysis.nearestNeighborTour`](haskell/HMath-Graph-Analysis.md#v:nearestNeighborTour). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Int -> Either MathError (Maybe (Double, [Int]))
```

```c
hmath_status hmath_graph_nearest_neighbor_tour(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *start,
    hmath_value **out);
```

## `page_rank`

`graph.page_rank(iterations, tolerance, damping, graph)`

 Given iteration budget,tolerance,damping,then graph, return vertex PageRank scores with dangling-node redistribution. Require nonnegative weights, finite damping in [0,1), valid tolerance/budget; nonconvergence/numeric failure returns Left MathError. 

Original: [`HMath.Graph.Analysis.pageRank`](haskell/HMath-Graph-Analysis.md#v:pageRank). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Double -> Double -> Graph -> Either MathError [Double]
```

```c
hmath_status hmath_graph_page_rank(
    hmath_context *context,
    const hmath_value *iterations,
    const hmath_value *tolerance,
    const hmath_value *damping,
    const hmath_value *graph,
    hmath_value **out);
```

## `random_walk`

`graph.random_walk(count, seed, graph, start)`

 Weighted walk with a reproducible 64-bit SplitMix stream. At a sink it remains in place. Zero-weight edges are never selected. 

Original: [`HMath.Graph.Analysis.randomWalk`](haskell/HMath-Graph-Analysis.md#v:randomWalk). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Word64 -> Graph -> Int -> Either MathError [Int]
```

```c
hmath_status hmath_graph_random_walk(
    hmath_context *context,
    const hmath_value *count,
    const hmath_value *seed,
    const hmath_value *graph,
    const hmath_value *start,
    hmath_value **out);
```

## `two_opt_tour`

`graph.two_opt_tour(iterations, graph, tour)`

 Given improvement-step budget,graph,then closed Hamiltonian tour, improve via pairwise segment reversals. Validate the tour permutation/edges and finite cost. Return (cost,tour); invalid input or missing edges fails. 

Original: [`HMath.Graph.Analysis.twoOptTour`](haskell/HMath-Graph-Analysis.md#v:twoOptTour). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Graph -> [Int] -> Either MathError (Double, [Int])
```

```c
hmath_status hmath_graph_two_opt_tour(
    hmath_context *context,
    const hmath_value *iterations,
    const hmath_value *graph,
    const hmath_value *tour,
    hmath_value **out);
```

## `csr`

`graph.csr(directed, vertex_count, offsets, targets, weights, edge_ids, orientations)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Core.CSR`](haskell/HMath-Graph-Core.md#v:CSR). Argument order and the full contract are defined there; the original type is:

```haskell
Bool -> Int -> [Int] -> [Int] -> [Double] -> [Int] -> [(Int, Int)] -> CSR
```

```c
hmath_status hmath_graph_csr(
    hmath_context *context,
    const hmath_value *directed,
    const hmath_value *vertex_count,
    const hmath_value *offsets,
    const hmath_value *targets,
    const hmath_value *weights,
    const hmath_value *edge_ids,
    const hmath_value *orientations,
    hmath_value **out);
```

## `edge`

`graph.edge(edge_id, source, target, weight)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Core.Edge`](haskell/HMath-Graph-Core.md#v:Edge). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Int -> Int -> Double -> Edge
```

```c
hmath_status hmath_graph_edge(
    hmath_context *context,
    const hmath_value *edge_id,
    const hmath_value *source,
    const hmath_value *target,
    const hmath_value *weight,
    hmath_value **out);
```

## `adjacency_list`

`graph.adjacency_list(graph)`

 Return one sorted neighbors row per zero-based vertex, retaining weight and edge identity for every traversal arc. 

Original: [`HMath.Graph.Core.adjacencyList`](haskell/HMath-Graph-Core.md#v:adjacencyList). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> [[(Int, Double, Int)]]
```

```c
hmath_status hmath_graph_adjacency_list(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `adjacency_matrix`

`graph.adjacency_matrix(graph)`

Cells contain every @(edge ID,weight)@, preserving edge multiplicity.

Original: [`HMath.Graph.Core.adjacencyMatrix`](haskell/HMath-Graph-Core.md#v:adjacencyMatrix). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> [[[(Int, Double)]]]
```

```c
hmath_status hmath_graph_adjacency_matrix(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `arcs`

`graph.arcs(graph)`

 Return directed traversal arcs. An undirected edge yields forward and reverse arcs sharing one original ID; a loop therefore yields two arcs. 

Original: [`HMath.Graph.Core.arcs`](haskell/HMath-Graph-Core.md#v:arcs). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> [Edge]
```

```c
hmath_status hmath_graph_arcs(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `articulation_points`

`graph.articulation_points(graph)`

Removal-based reference algorithms, retaining parallel-edge identity.

Original: [`HMath.Graph.Core.articulationPoints`](haskell/HMath-Graph-Core.md#v:articulationPoints). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Either MathError [Int]
```

```c
hmath_status hmath_graph_articulation_points(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `bfs`

`graph.bfs(graph, start)`

 Given graph then valid start vertex, return breadth-first reachable-vertex order with sorted neighbor tie-breaking. Invalid start fails; disconnected unreachable vertices are omitted. 

Original: [`HMath.Graph.Core.bfs`](haskell/HMath-Graph-Core.md#v:bfs). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Int -> Either MathError [Int]
```

```c
hmath_status hmath_graph_bfs(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *start,
    hmath_value **out);
```

## `bipartite_base`

`graph.bipartite_base(bipartite_graph)`

 Return underlying undirected graph, whose right-part global labels start at the left-part count. 

Original: [`HMath.Graph.Core.bipartiteBase`](haskell/HMath-Graph-Core.md#v:bipartiteBase). Argument order and the full contract are defined there; the original type is:

```haskell
BipartiteGraph -> Graph
```

```c
hmath_status hmath_graph_bipartite_base(
    hmath_context *context,
    const hmath_value *bipartite_graph,
    hmath_value **out);
```

## `bipartite_graph`

`graph.bipartite_graph(left_vertices, right_vertices, edges)`

 Given left count,right count,then (left-local,right-local,weight) triples, construct an undirected bipartite graph. Right vertices are offset by left count internally. Negative/out-of-range endpoints, non-finite weights or graph size bounds fail. 

Original: [`HMath.Graph.Core.bipartiteGraph`](haskell/HMath-Graph-Core.md#v:bipartiteGraph). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Int -> [(Int, Int, Double)] -> Either MathError BipartiteGraph
```

```c
hmath_status hmath_graph_bipartite_graph(
    hmath_context *context,
    const hmath_value *left_vertices,
    const hmath_value *right_vertices,
    const hmath_value *edges,
    hmath_value **out);
```

## `bipartite_parts`

`graph.bipartite_parts(bipartite_graph)`

Return (left vertex count,right vertex count) of a bipartite graph.

Original: [`HMath.Graph.Core.bipartiteParts`](haskell/HMath-Graph-Core.md#v:bipartiteParts). Argument order and the full contract are defined there; the original type is:

```haskell
BipartiteGraph -> (Int, Int)
```

```c
hmath_status hmath_graph_bipartite_parts(
    hmath_context *context,
    const hmath_value *bipartite_graph,
    hmath_value **out);
```

## `boruvka`

`graph.boruvka(graph)`

 Return an undirected minimum spanning forest by repeatedly merging components along cheapest outgoing edges. Preserve original edge identity; directed input fails. 

Original: [`HMath.Graph.Core.boruvka`](haskell/HMath-Graph-Core.md#v:boruvka). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Either MathError [Edge]
```

```c
hmath_status hmath_graph_boruvka(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `bridges`

`graph.bridges(graph)`

 Return original IDs of bridges in an undirected multigraph; parallel edges are treated distinctly. Directed input returns Left InvalidArgument. 

Original: [`HMath.Graph.Core.bridges`](haskell/HMath-Graph-Core.md#v:bridges). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Either MathError [Int]
```

```c
hmath_status hmath_graph_bridges(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `check_vertex`

`graph.check_vertex(graph, vertex)`

 Given graph then vertex index, return Right () only for a label in [0,vertexCount). Invalid labels return Left InvalidArgument. 

Original: [`HMath.Graph.Core.checkVertex`](haskell/HMath-Graph-Core.md#v:checkVertex). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Int -> Either MathError ()
```

```c
hmath_status hmath_graph_check_vertex(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *vertex,
    hmath_value **out);
```

## `connected_components`

`graph.connected_components(graph)`

 Return weak connected components as sorted vertex lists, ignoring edge direction and retaining isolated vertices. 

Original: [`HMath.Graph.Core.connectedComponents`](haskell/HMath-Graph-Core.md#v:connectedComponents). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> [[Int]]
```

```c
hmath_status hmath_graph_connected_components(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `csr_directed`

`graph.csr_directed(csr)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Core.csrDirected`](haskell/HMath-Graph-Core.md#v:csrDirected). Argument order and the full contract are defined there; the original type is:

```haskell
CSR -> Bool
```

```c
hmath_status hmath_graph_csr_directed(
    hmath_context *context,
    const hmath_value *csr,
    hmath_value **out);
```

## `csr_ids`

`graph.csr_ids(csr)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Core.csrIds`](haskell/HMath-Graph-Core.md#v:csrIds). Argument order and the full contract are defined there; the original type is:

```haskell
CSR -> [Int]
```

```c
hmath_status hmath_graph_csr_ids(
    hmath_context *context,
    const hmath_value *csr,
    hmath_value **out);
```

## `csr_offsets`

`graph.csr_offsets(csr)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Core.csrOffsets`](haskell/HMath-Graph-Core.md#v:csrOffsets). Argument order and the full contract are defined there; the original type is:

```haskell
CSR -> [Int]
```

```c
hmath_status hmath_graph_csr_offsets(
    hmath_context *context,
    const hmath_value *csr,
    hmath_value **out);
```

## `csr_orientations`

`graph.csr_orientations(csr)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Core.csrOrientations`](haskell/HMath-Graph-Core.md#v:csrOrientations). Argument order and the full contract are defined there; the original type is:

```haskell
CSR -> [(Int, Int)]
```

```c
hmath_status hmath_graph_csr_orientations(
    hmath_context *context,
    const hmath_value *csr,
    hmath_value **out);
```

## `csr_targets`

`graph.csr_targets(csr)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Core.csrTargets`](haskell/HMath-Graph-Core.md#v:csrTargets). Argument order and the full contract are defined there; the original type is:

```haskell
CSR -> [Int]
```

```c
hmath_status hmath_graph_csr_targets(
    hmath_context *context,
    const hmath_value *csr,
    hmath_value **out);
```

## `csr_vertices`

`graph.csr_vertices(csr)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Core.csrVertices`](haskell/HMath-Graph-Core.md#v:csrVertices). Argument order and the full contract are defined there; the original type is:

```haskell
CSR -> Int
```

```c
hmath_status hmath_graph_csr_vertices(
    hmath_context *context,
    const hmath_value *csr,
    hmath_value **out);
```

## `csr_weights`

`graph.csr_weights(csr)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Core.csrWeights`](haskell/HMath-Graph-Core.md#v:csrWeights). Argument order and the full contract are defined there; the original type is:

```haskell
CSR -> [Double]
```

```c
hmath_status hmath_graph_csr_weights(
    hmath_context *context,
    const hmath_value *csr,
    hmath_value **out);
```

## `deserialize_bipartite_graph`

`graph.deserialize_bipartite_graph(text)`

 Read a versioned bipartite serialization, then validate part counts, endpoints and weights. Reject unknown/malformed encoding or input longer than 16777216 characters. 

Original: [`HMath.Graph.Core.deserializeBipartiteGraph`](haskell/HMath-Graph-Core.md#v:deserializeBipartiteGraph). Argument order and the full contract are defined there; the original type is:

```haskell
String -> Either MathError BipartiteGraph
```

```c
hmath_status hmath_graph_deserialize_bipartite_graph(
    hmath_context *context,
    const hmath_value *text,
    hmath_value **out);
```

## `deserialize_graph`

`graph.deserialize_graph(text)`

 Read complete HMath.Graph/1 encoding and reconstruct via checked graph constructor. Unknown version, malformed text, input over 16777216 characters or invalid graph data fails. 

Original: [`HMath.Graph.Core.deserializeGraph`](haskell/HMath-Graph-Core.md#v:deserializeGraph). Argument order and the full contract are defined there; the original type is:

```haskell
String -> Either MathError Graph
```

```c
hmath_status hmath_graph_deserialize_graph(
    hmath_context *context,
    const hmath_value *text,
    hmath_value **out);
```

## `deserialize_hypergraph`

`graph.deserialize_hypergraph(text)`

 Read versioned hypergraph encoding and validate through hypergraph. Reject unknown/malformed input, more than 16777216 characters or invalid graph bounds. 

Original: [`HMath.Graph.Core.deserializeHypergraph`](haskell/HMath-Graph-Core.md#v:deserializeHypergraph). Argument order and the full contract are defined there; the original type is:

```haskell
String -> Either MathError Hypergraph
```

```c
hmath_status hmath_graph_deserialize_hypergraph(
    hmath_context *context,
    const hmath_value *text,
    hmath_value **out);
```

## `dfs`

`graph.dfs(graph, start)`

 Given graph then valid start vertex, return depth-first reachable-vertex order with deterministic sorted neighbors. Invalid start fails; each reached vertex appears once. 

Original: [`HMath.Graph.Core.dfs`](haskell/HMath-Graph-Core.md#v:dfs). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Int -> Either MathError [Int]
```

```c
hmath_status hmath_graph_dfs(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *start,
    hmath_value **out);
```

## `directed`

`graph.directed(graph)`

 Return whether the graph is directed. Undirected edges are represented once in edges and twice in arcs, including loops. 

Original: [`HMath.Graph.Core.directed`](haskell/HMath-Graph-Core.md#v:directed). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Bool
```

```c
hmath_status hmath_graph_directed(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `edge_from`

`graph.edge_from(edge)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Core.edgeFrom`](haskell/HMath-Graph-Core.md#v:edgeFrom). Argument order and the full contract are defined there; the original type is:

```haskell
Edge -> Int
```

```c
hmath_status hmath_graph_edge_from(
    hmath_context *context,
    const hmath_value *edge,
    hmath_value **out);
```

## `edge_id`

`graph.edge_id(edge)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Core.edgeId`](haskell/HMath-Graph-Core.md#v:edgeId). Argument order and the full contract are defined there; the original type is:

```haskell
Edge -> Int
```

```c
hmath_status hmath_graph_edge_id(
    hmath_context *context,
    const hmath_value *edge,
    hmath_value **out);
```

## `edge_to`

`graph.edge_to(edge)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Core.edgeTo`](haskell/HMath-Graph-Core.md#v:edgeTo). Argument order and the full contract are defined there; the original type is:

```haskell
Edge -> Int
```

```c
hmath_status hmath_graph_edge_to(
    hmath_context *context,
    const hmath_value *edge,
    hmath_value **out);
```

## `edge_weight`

`graph.edge_weight(edge)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Core.edgeWeight`](haskell/HMath-Graph-Core.md#v:edgeWeight). Argument order and the full contract are defined there; the original type is:

```haskell
Edge -> Double
```

```c
hmath_status hmath_graph_edge_weight(
    hmath_context *context,
    const hmath_value *edge,
    hmath_value **out);
```

## `edges`

`graph.edges(graph)`

 Return original labeled edges in input order, preserving loops, multiplicity and stable edge IDs. 

Original: [`HMath.Graph.Core.edges`](haskell/HMath-Graph-Core.md#v:edges). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> [Edge]
```

```c
hmath_status hmath_graph_edges(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `finite`

`graph.finite(x)`

 Test whether a Double is neither NaN nor infinite; used by checked graph weight/arithmetic validation. 

Original: [`HMath.Graph.Core.finite`](haskell/HMath-Graph-Core.md#v:finite). Argument order and the full contract are defined there; the original type is:

```haskell
Double -> Bool
```

```c
hmath_status hmath_graph_finite(
    hmath_context *context,
    const hmath_value *x,
    hmath_value **out);
```

## `from_adjacency_list`

`graph.from_adjacency_list(directed, rows, orientations)`

 Lossless labeled adjacency-list conversion. The final argument records the original direction of each undirected edge, which symmetric arcs alone cannot distinguish. IDs must be contiguous; rows are canonical sorted order. 

Original: [`HMath.Graph.Core.fromAdjacencyList`](haskell/HMath-Graph-Core.md#v:fromAdjacencyList). Argument order and the full contract are defined there; the original type is:

```haskell
Bool -> [[(Int, Double, Int)]] -> [(Int, Int)] -> Either MathError Graph
```

```c
hmath_status hmath_graph_from_adjacency_list(
    hmath_context *context,
    const hmath_value *directed,
    const hmath_value *rows,
    const hmath_value *orientations,
    hmath_value **out);
```

## `from_adjacency_matrix`

`graph.from_adjacency_matrix(directed, cells)`

 Matrix cells are weights; undirected matrices must be exactly symmetric. Diagonal entries denote one loop each, rather than duplicated traversal arcs. 

Original: [`HMath.Graph.Core.fromAdjacencyMatrix`](haskell/HMath-Graph-Core.md#v:fromAdjacencyMatrix). Argument order and the full contract are defined there; the original type is:

```haskell
Bool -> [[[Double]]] -> Either MathError Graph
```

```c
hmath_status hmath_graph_from_adjacency_matrix(
    hmath_context *context,
    const hmath_value *directed,
    const hmath_value *cells,
    hmath_value **out);
```

## `from_csr`

`graph.from_csr(csr)`

 Validate CSR sizes, offsets, endpoint/weight/ID arrays and original orientations, then reconstruct a canonical graph. Malformed or noncanonical data returns Left InvalidArgument. 

Original: [`HMath.Graph.Core.fromCSR`](haskell/HMath-Graph-Core.md#v:fromCSR). Argument order and the full contract are defined there; the original type is:

```haskell
CSR -> Either MathError Graph
```

```c
hmath_status hmath_graph_from_csr(
    hmath_context *context,
    const hmath_value *csr,
    hmath_value **out);
```

## `from_labeled_adjacency_matrix`

`graph.from_labeled_adjacency_matrix(directed, cells, orientations)`

 Given directed flag,square cells of (edge ID,weight) lists,then original edge orientations, reconstruct a lossless graph. Validate square shape, canonical IDs/arcs and graph bounds through fromCSR; malformed input fails. 

Original: [`HMath.Graph.Core.fromLabeledAdjacencyMatrix`](haskell/HMath-Graph-Core.md#v:fromLabeledAdjacencyMatrix). Argument order and the full contract are defined there; the original type is:

```haskell
Bool -> [[[(Int, Double)]]] -> [(Int, Int)] -> Either MathError Graph
```

```c
hmath_status hmath_graph_from_labeled_adjacency_matrix(
    hmath_context *context,
    const hmath_value *directed,
    const hmath_value *cells,
    const hmath_value *orientations,
    hmath_value **out);
```

## `graph`

`graph.graph(directed, vertex_count, edges)`

 Given directed flag,vertex count,then (from,to,weight) triples, construct a multigraph with stable input-order edge IDs. Require 0<=vertices<=512, <=65536 edges, valid endpoints and finite weights; otherwise return Left InvalidArgument. 

Original: [`HMath.Graph.Core.graph`](haskell/HMath-Graph-Core.md#v:graph). Argument order and the full contract are defined there; the original type is:

```haskell
Bool -> Int -> [(Int, Int, Double)] -> Either MathError Graph
```

```c
hmath_status hmath_graph_graph(
    hmath_context *context,
    const hmath_value *directed,
    const hmath_value *vertex_count,
    const hmath_value *edges,
    hmath_value **out);
```

## `has_cycle`

`graph.has_cycle(graph)`

 Test for a directed or undirected cycle, respecting original edge identities. Loops and parallel undirected edges can form cycles. 

Original: [`HMath.Graph.Core.hasCycle`](haskell/HMath-Graph-Core.md#v:hasCycle). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Bool
```

```c
hmath_status hmath_graph_has_cycle(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `hyper_vertices`

`graph.hyper_vertices(hypergraph)`

Return the number of zero-based vertices in a hypergraph.

Original: [`HMath.Graph.Core.hyperVertices`](haskell/HMath-Graph-Core.md#v:hyperVertices). Argument order and the full contract are defined there; the original type is:

```haskell
Hypergraph -> Int
```

```c
hmath_status hmath_graph_hyper_vertices(
    hmath_context *context,
    const hmath_value *hypergraph,
    hmath_value **out);
```

## `hyperedges`

`graph.hyperedges(hypergraph)`

 Return canonical hyperedge lists with sorted distinct member vertices, preserving hyperedge list order. 

Original: [`HMath.Graph.Core.hyperedges`](haskell/HMath-Graph-Core.md#v:hyperedges). Argument order and the full contract are defined there; the original type is:

```haskell
Hypergraph -> [[Int]]
```

```c
hmath_status hmath_graph_hyperedges(
    hmath_context *context,
    const hmath_value *hypergraph,
    hmath_value **out);
```

## `hypergraph`

`graph.hypergraph(vertex_count, hyperedges)`

 Given vertex count then hyperedge vertex lists, validate bounded size/endpoints and construct a hypergraph. Canonicalize vertices within each hyperedge by sorting/deduplicating. Invalid bounds fail. 

Original: [`HMath.Graph.Core.hypergraph`](haskell/HMath-Graph-Core.md#v:hypergraph). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> [[Int]] -> Either MathError Hypergraph
```

```c
hmath_status hmath_graph_hypergraph(
    hmath_context *context,
    const hmath_value *vertex_count,
    const hmath_value *hyperedges,
    hmath_value **out);
```

## `iterative_deepening`

`graph.iterative_deepening(budget, graph, source, target)`

Iterative deepening simple-path DFS. Fuel counts visited search nodes.

Original: [`HMath.Graph.Core.iterativeDeepening`](haskell/HMath-Graph-Core.md#v:iterativeDeepening). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Graph -> Int -> Int -> Either MathError (Maybe [Int])
```

```c
hmath_status hmath_graph_iterative_deepening(
    hmath_context *context,
    const hmath_value *budget,
    const hmath_value *graph,
    const hmath_value *source,
    const hmath_value *target,
    hmath_value **out);
```

## `kosaraju_scc`

`graph.kosaraju_scc(graph)`

 Return sorted strongly connected components via Kosaraju traversal; undirected graphs reduce to ordinary connected components. 

Original: [`HMath.Graph.Core.kosarajuSCC`](haskell/HMath-Graph-Core.md#v:kosarajuSCC). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> [[Int]]
```

```c
hmath_status hmath_graph_kosaraju_scc(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `kruskal`

`graph.kruskal(graph)`

 Return a minimum spanning forest of an undirected weighted graph by Kruskal, breaking ties by stable edge ID. Disconnected graphs return a forest; directed input fails. 

Original: [`HMath.Graph.Core.kruskal`](haskell/HMath-Graph-Core.md#v:kruskal). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Either MathError [Edge]
```

```c
hmath_status hmath_graph_kruskal(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `neighbors`

`graph.neighbors(graph, vertex)`

 Given graph then vertex, return sorted (destination,weight,edge ID) traversal entries leaving that vertex. Parallel edges/loops are preserved. This query does not itself reject invalid vertex labels. 

Original: [`HMath.Graph.Core.neighbors`](haskell/HMath-Graph-Core.md#v:neighbors). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Int -> [(Int, Double, Int)]
```

```c
hmath_status hmath_graph_neighbors(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *vertex,
    hmath_value **out);
```

## `prim`

`graph.prim(graph)`

 All three MST routines return a minimum spanning forest on disconnected inputs. Self-loops are ignored, negative finite weights are supported. 

Original: [`HMath.Graph.Core.prim`](haskell/HMath-Graph-Core.md#v:prim). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Either MathError [Edge]
```

```c
hmath_status hmath_graph_prim(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `require_undirected`

`graph.require_undirected(graph)`

 Return Right () for an undirected graph; directed input returns Left InvalidArgument. No graph conversion occurs. 

Original: [`HMath.Graph.Core.requireUndirected`](haskell/HMath-Graph-Core.md#v:requireUndirected). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Either MathError ()
```

```c
hmath_status hmath_graph_require_undirected(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `serialize_bipartite_graph`

`graph.serialize_bipartite_graph(bipartite)`

 Serialize a bipartite graph with HMath.BipartiteGraph/1 version marker and local part labels. Pair with deserializeBipartiteGraph for checked round-trip. 

Original: [`HMath.Graph.Core.serializeBipartiteGraph`](haskell/HMath-Graph-Core.md#v:serializeBipartiteGraph). Argument order and the full contract are defined there; the original type is:

```haskell
BipartiteGraph -> String
```

```c
hmath_status hmath_graph_serialize_bipartite_graph(
    hmath_context *context,
    const hmath_value *bipartite,
    hmath_value **out);
```

## `serialize_graph`

`graph.serialize_graph(graph)`

 Serialize graph direction, vertex count and input-ordered edges with HMath.Graph/1 marker; stable IDs reconstruct from edge order. 

Original: [`HMath.Graph.Core.serializeGraph`](haskell/HMath-Graph-Core.md#v:serializeGraph). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> String
```

```c
hmath_status hmath_graph_serialize_graph(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `serialize_hypergraph`

`graph.serialize_hypergraph(hypergraph)`

Serialize vertex count and canonical hyperedges with HMath.Hypergraph/1 version marker.

Original: [`HMath.Graph.Core.serializeHypergraph`](haskell/HMath-Graph-Core.md#v:serializeHypergraph). Argument order and the full contract are defined there; the original type is:

```haskell
Hypergraph -> String
```

```c
hmath_status hmath_graph_serialize_hypergraph(
    hmath_context *context,
    const hmath_value *hypergraph,
    hmath_value **out);
```

## `tarjan_scc`

`graph.tarjan_scc(graph)`

Tarjan's single-pass index/low-link stack algorithm.

Original: [`HMath.Graph.Core.tarjanSCC`](haskell/HMath-Graph-Core.md#v:tarjanSCC). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> [[Int]]
```

```c
hmath_status hmath_graph_tarjan_scc(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `to_csr`

`graph.to_csr(graph)`

 Convert a graph to lossless CSR rows with offsets, targets, weights, IDs and original edge orientations. Preserve loops and multiedge identity. 

Original: [`HMath.Graph.Core.toCSR`](haskell/HMath-Graph-Core.md#v:toCSR). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> CSR
```

```c
hmath_status hmath_graph_to_csr(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `topological_sort`

`graph.topological_sort(graph)`

 Return a deterministic topological order of all vertices of a directed acyclic graph. Undirected graphs or directed cycles return Left MathError. 

Original: [`HMath.Graph.Core.topologicalSort`](haskell/HMath-Graph-Core.md#v:topologicalSort). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Either MathError [Int]
```

```c
hmath_status hmath_graph_topological_sort(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `vertex_count`

`graph.vertex_count(graph)`

 Return graph vertex count. Valid vertex labels are zero-based integers below this count. 

Original: [`HMath.Graph.Core.vertexCount`](haskell/HMath-Graph-Core.md#v:vertexCount). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Int
```

```c
hmath_status hmath_graph_vertex_count(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `flow_result`

`graph.flow_result(value, edge_flows, cost)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Flow.FlowResult`](haskell/HMath-Graph-Flow.md#v:FlowResult). Argument order and the full contract are defined there; the original type is:

```haskell
Integer -> [Integer] -> Integer -> FlowResult
```

```c
hmath_status hmath_graph_flow_result(
    hmath_context *context,
    const hmath_value *value,
    const hmath_value *edge_flows,
    const hmath_value *cost,
    hmath_value **out);
```

## `network_edge`

`graph.network_edge(edge_id, source, target, capacity, cost)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Flow.NetworkEdge`](haskell/HMath-Graph-Flow.md#v:NetworkEdge). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Int -> Int -> Integer -> Integer -> NetworkEdge
```

```c
hmath_status hmath_graph_network_edge(
    hmath_context *context,
    const hmath_value *edge_id,
    const hmath_value *source,
    const hmath_value *target,
    const hmath_value *capacity,
    const hmath_value *cost,
    hmath_value **out);
```

## `dinic`

`graph.dinic(budget, network, source, target)`

 Given work budget,network,source,sink, compute maximum flow with level graphs and blocking-flow augmentation. Invalid source/sink/budget or exhausted work returns Left MathError; result includes flows in original edge order. 

Original: [`HMath.Graph.Flow.dinic`](haskell/HMath-Graph-Flow.md#v:dinic). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Network -> Int -> Int -> Either MathError FlowResult
```

```c
hmath_status hmath_graph_dinic(
    hmath_context *context,
    const hmath_value *budget,
    const hmath_value *network,
    const hmath_value *source,
    const hmath_value *target,
    hmath_value **out);
```

## `edge_flows`

`graph.edge_flows(flow_result)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Flow.edgeFlows`](haskell/HMath-Graph-Flow.md#v:edgeFlows). Argument order and the full contract are defined there; the original type is:

```haskell
FlowResult -> [Integer]
```

```c
hmath_status hmath_graph_edge_flows(
    hmath_context *context,
    const hmath_value *flow_result,
    hmath_value **out);
```

## `edmonds_karp`

`graph.edmonds_karp(value, network, value3, value4)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Flow.edmondsKarp`](haskell/HMath-Graph-Flow.md#v:edmondsKarp). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Network -> Int -> Int -> Either MathError FlowResult
```

```c
hmath_status hmath_graph_edmonds_karp(
    hmath_context *context,
    const hmath_value *value,
    const hmath_value *network,
    const hmath_value *value3,
    const hmath_value *value4,
    hmath_value **out);
```

## `flow_cost`

`graph.flow_cost(flow_result)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Flow.flowCost`](haskell/HMath-Graph-Flow.md#v:flowCost). Argument order and the full contract are defined there; the original type is:

```haskell
FlowResult -> Integer
```

```c
hmath_status hmath_graph_flow_cost(
    hmath_context *context,
    const hmath_value *flow_result,
    hmath_value **out);
```

## `flow_value`

`graph.flow_value(flow_result)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Flow.flowValue`](haskell/HMath-Graph-Flow.md#v:flowValue). Argument order and the full contract are defined there; the original type is:

```haskell
FlowResult -> Integer
```

```c
hmath_status hmath_graph_flow_value(
    hmath_context *context,
    const hmath_value *flow_result,
    hmath_value **out);
```

## `ford_fulkerson`

`graph.ford_fulkerson(value, network, value3, value4)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Flow.fordFulkerson`](haskell/HMath-Graph-Flow.md#v:fordFulkerson). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Network -> Int -> Int -> Either MathError FlowResult
```

```c
hmath_status hmath_graph_ford_fulkerson(
    hmath_context *context,
    const hmath_value *value,
    const hmath_value *network,
    const hmath_value *value3,
    const hmath_value *value4,
    hmath_value **out);
```

## `hopcroft_karp`

`graph.hopcroft_karp(bipartite)`

 Hopcroft--Karp layered augmenting paths. Returns @(left,right)@ matching; parallel edges are coalesced and weights are ignored. 

Original: [`HMath.Graph.Flow.hopcroftKarp`](haskell/HMath-Graph-Flow.md#v:hopcroftKarp). Argument order and the full contract are defined there; the original type is:

```haskell
BipartiteGraph -> [(Int, Int)]
```

```c
hmath_status hmath_graph_hopcroft_karp(
    hmath_context *context,
    const hmath_value *bipartite,
    hmath_value **out);
```

## `hungarian`

`graph.hungarian(costs)`

 Rectangular Hungarian primal-dual assignment, rows <= columns <= 256. Every row is assigned to a distinct column; exact integer costs may be negative. 

Original: [`HMath.Graph.Flow.hungarian`](haskell/HMath-Graph-Flow.md#v:hungarian). Argument order and the full contract are defined there; the original type is:

```haskell
[[Integer]] -> Either MathError (Integer, [(Int, Int)])
```

```c
hmath_status hmath_graph_hungarian(
    hmath_context *context,
    const hmath_value *costs,
    hmath_value **out);
```

## `minimum_cost_maximum_flow`

`graph.minimum_cost_maximum_flow(value, network, value3, value4)`

 Maximum flow followed by exact negative-residual-cycle cancellation. This supports negative costs (including disconnected cycles) and finds the minimum cost among all maximum flows. The same budget bounds each phase separately. 

Original: [`HMath.Graph.Flow.minimumCostMaximumFlow`](haskell/HMath-Graph-Flow.md#v:minimumCostMaximumFlow). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Network -> Int -> Int -> Either MathError FlowResult
```

```c
hmath_status hmath_graph_minimum_cost_maximum_flow(
    hmath_context *context,
    const hmath_value *value,
    const hmath_value *network,
    const hmath_value *value3,
    const hmath_value *value4,
    hmath_value **out);
```

## `minimum_cut`

`graph.minimum_cut(value, network, value3, value4)`

Source-side vertices and cut capacity, using Edmonds--Karp residual reach.

Original: [`HMath.Graph.Flow.minimumCut`](haskell/HMath-Graph-Flow.md#v:minimumCut). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Network -> Int -> Int -> Either MathError ([Int], Integer)
```

```c
hmath_status hmath_graph_minimum_cut(
    hmath_context *context,
    const hmath_value *value,
    const hmath_value *network,
    const hmath_value *value3,
    const hmath_value *value4,
    hmath_value **out);
```

## `network`

`graph.network(vertex_count, edges)`

 Given vertex count then (from,to,capacity,cost) edges, construct an exact integral network with stable edge IDs. Require <=512 vertices, <=65536 edges, valid endpoints and nonnegative capacities. Costs may be negative. 

Original: [`HMath.Graph.Flow.network`](haskell/HMath-Graph-Flow.md#v:network). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> [(Int, Int, Integer, Integer)] -> Either MathError Network
```

```c
hmath_status hmath_graph_network(
    hmath_context *context,
    const hmath_value *vertex_count,
    const hmath_value *edges,
    hmath_value **out);
```

## `network_capacity`

`graph.network_capacity(network_edge)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Flow.networkCapacity`](haskell/HMath-Graph-Flow.md#v:networkCapacity). Argument order and the full contract are defined there; the original type is:

```haskell
NetworkEdge -> Integer
```

```c
hmath_status hmath_graph_network_capacity(
    hmath_context *context,
    const hmath_value *network_edge,
    hmath_value **out);
```

## `network_cost`

`graph.network_cost(network_edge)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Flow.networkCost`](haskell/HMath-Graph-Flow.md#v:networkCost). Argument order and the full contract are defined there; the original type is:

```haskell
NetworkEdge -> Integer
```

```c
hmath_status hmath_graph_network_cost(
    hmath_context *context,
    const hmath_value *network_edge,
    hmath_value **out);
```

## `network_edge_id`

`graph.network_edge_id(network_edge)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Flow.networkEdgeId`](haskell/HMath-Graph-Flow.md#v:networkEdgeId). Argument order and the full contract are defined there; the original type is:

```haskell
NetworkEdge -> Int
```

```c
hmath_status hmath_graph_network_edge_id(
    hmath_context *context,
    const hmath_value *network_edge,
    hmath_value **out);
```

## `network_edges`

`graph.network_edges(network)`

Return original network edges in input/ID order, retaining capacities and costs.

Original: [`HMath.Graph.Flow.networkEdges`](haskell/HMath-Graph-Flow.md#v:networkEdges). Argument order and the full contract are defined there; the original type is:

```haskell
Network -> [NetworkEdge]
```

```c
hmath_status hmath_graph_network_edges(
    hmath_context *context,
    const hmath_value *network,
    hmath_value **out);
```

## `network_from`

`graph.network_from(network_edge)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Flow.networkFrom`](haskell/HMath-Graph-Flow.md#v:networkFrom). Argument order and the full contract are defined there; the original type is:

```haskell
NetworkEdge -> Int
```

```c
hmath_status hmath_graph_network_from(
    hmath_context *context,
    const hmath_value *network_edge,
    hmath_value **out);
```

## `network_to`

`graph.network_to(network_edge)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Graph.Flow.networkTo`](haskell/HMath-Graph-Flow.md#v:networkTo). Argument order and the full contract are defined there; the original type is:

```haskell
NetworkEdge -> Int
```

```c
hmath_status hmath_graph_network_to(
    hmath_context *context,
    const hmath_value *network_edge,
    hmath_value **out);
```

## `push_relabel`

`graph.push_relabel(value, network, value3, value4)`

 Given push/relabel work budget,network,source,sink, compute exact maximum flow by preflow and relabel operations. Reject invalid endpoints/budget; work exhaustion returns NonConvergence. 

Original: [`HMath.Graph.Flow.pushRelabel`](haskell/HMath-Graph-Flow.md#v:pushRelabel). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Network -> Int -> Int -> Either MathError FlowResult
```

```c
hmath_status hmath_graph_push_relabel(
    hmath_context *context,
    const hmath_value *value,
    const hmath_value *network,
    const hmath_value *value3,
    const hmath_value *value4,
    hmath_value **out);
```

## `a_star`

`graph.a_star(graph, heuristic, source, target)`

 A* requires a finite consistent heuristic, h(target)=0, checked on all arcs. This guarantees optimality without trusting an arbitrary heuristic. 

Original: [`HMath.Graph.Paths.aStar`](haskell/HMath-Graph-Paths.md#v:aStar). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> (Int -> Double) -> Int -> Int -> Either MathError (Maybe (Double, [Int]))
```

```c
hmath_status hmath_graph_a_star(
    hmath_context *context,
    const hmath_value *graph,
    hmath_graph_heuristic heuristic,
    void *userdata,
    const hmath_value *source,
    const hmath_value *target,
    hmath_value **out);
```

## `bellman_ford`

`graph.bellman_ford(graph, source)`

 Given graph then source, return minimum distances including negative weights. Invalid source, reachable negative cycle or non-finite arithmetic returns Left MathError; unreachable vertices are Nothing. 

Original: [`HMath.Graph.Paths.bellmanFord`](haskell/HMath-Graph-Paths.md#v:bellmanFord). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Int -> Either MathError [Maybe Double]
```

```c
hmath_status hmath_graph_bellman_ford(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *source,
    hmath_value **out);
```

## `bidirectional_dijkstra`

`graph.bidirectional_dijkstra(graph, source, target)`

 Two settled-frontier Dijkstra searches, alternating the frontier with the smaller minimum key. The best meeting bound stops the search safely. 

Original: [`HMath.Graph.Paths.bidirectionalDijkstra`](haskell/HMath-Graph-Paths.md#v:bidirectionalDijkstra). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Int -> Int -> Either MathError (Maybe Double)
```

```c
hmath_status hmath_graph_bidirectional_dijkstra(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *source,
    const hmath_value *target,
    hmath_value **out);
```

## `dijkstra`

`graph.dijkstra(graph, source)`

 Given graph then source, return minimum distances in vertex order, with Nothing for unreachable vertices. Require valid source and nonnegative weights; invalid input or non-finite arithmetic fails. 

Original: [`HMath.Graph.Paths.dijkstra`](haskell/HMath-Graph-Paths.md#v:dijkstra). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Int -> Either MathError [Maybe Double]
```

```c
hmath_status hmath_graph_dijkstra(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *source,
    hmath_value **out);
```

## `floyd_warshall`

`graph.floyd_warshall(graph)`

 Return all-pairs minimum-distance rows, with Nothing for unreachable pairs. Negative edges are allowed; any negative cycle or non-finite arithmetic fails. 

Original: [`HMath.Graph.Paths.floydWarshall`](haskell/HMath-Graph-Paths.md#v:floydWarshall). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Either MathError [[Maybe Double]]
```

```c
hmath_status hmath_graph_floyd_warshall(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `johnson`

`graph.johnson(graph)`

 Johnson reweighting: Bellman--Ford potentials from an implicit zero-cost super-source, followed by independent Dijkstra searches. 

Original: [`HMath.Graph.Paths.johnson`](haskell/HMath-Graph-Paths.md#v:johnson). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Either MathError [[Maybe Double]]
```

```c
hmath_status hmath_graph_johnson(
    hmath_context *context,
    const hmath_value *graph,
    hmath_value **out);
```

## `k_shortest_paths`

`graph.k_shortest_paths(budget, count, graph, source, target)`

 K cheapest simple vertex paths, best-first expansion, for nonnegative weights. Parallel edges generate distinct edge paths; output includes edge IDs to preserve this identity. Fuel counts expanded partial paths. 

Original: [`HMath.Graph.Paths.kShortestPaths`](haskell/HMath-Graph-Paths.md#v:kShortestPaths). Argument order and the full contract are defined there; the original type is:

```haskell
Int -> Int -> Graph -> Int -> Int -> Either MathError [(Double, [Int], [Int])]
```

```c
hmath_status hmath_graph_k_shortest_paths(
    hmath_context *context,
    const hmath_value *budget,
    const hmath_value *count,
    const hmath_value *graph,
    const hmath_value *source,
    const hmath_value *target,
    hmath_value **out);
```

## `longest_dag_paths`

`graph.longest_dag_paths(graph, source)`

 Given directed acyclic graph then source, return maximum path-weight distance to each vertex, Nothing for unreachable vertices. Invalid source, cycles/undirected input or non-finite arithmetic fails. 

Original: [`HMath.Graph.Paths.longestDAGPaths`](haskell/HMath-Graph-Paths.md#v:longestDAGPaths). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> Int -> Either MathError [Maybe Double]
```

```c
hmath_status hmath_graph_longest_dag_paths(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *source,
    hmath_value **out);
```

## `multi_source_dijkstra`

`graph.multi_source_dijkstra(graph, sources)`

 Given graph then source list, return distance to the nearest supplied source, each seeded at zero. Invalid sources, negative weights or non-finite arithmetic fail. Empty sources give all Nothing. 

Original: [`HMath.Graph.Paths.multiSourceDijkstra`](haskell/HMath-Graph-Paths.md#v:multiSourceDijkstra). Argument order and the full contract are defined there; the original type is:

```haskell
Graph -> [Int] -> Either MathError [Maybe Double]
```

```c
hmath_status hmath_graph_multi_source_dijkstra(
    hmath_context *context,
    const hmath_value *graph,
    const hmath_value *sources,
    hmath_value **out);
```

