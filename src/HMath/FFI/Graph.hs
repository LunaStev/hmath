{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- Generated; do not edit.
module HMath.FFI.Graph where
import Foreign
import Foreign.C
import HMath.FFI.Boundary
import HMath.FFI.Value
import HMath.FFI.GraphCodec
import qualified HMath.Graph as G
foreign export ccall "hm_graph_apply" apply :: CInt -> Ptr (StablePtr Value) -> CSize -> FunPtr Heuristic -> Ptr () -> Ptr (StablePtr Value) -> IO CInt
apply :: CInt -> Ptr (StablePtr Value) -> CSize -> FunPtr Heuristic -> Ptr () -> Ptr (StablePtr Value) -> IO CInt
apply operation input arity callback userdata out = boundary $ do
    values <- peekArray (fromIntegral arity) input >>= mapM deRefStablePtr
    case (operation, values) of
        (0, [vgraph]) -> do
            graph <- unwire vgraph
            checked (Right (G.betweennessCentrality graph)) (\result_value -> publish (wire result_value) out)
        (1, [vgraph]) -> do
            graph <- unwire vgraph
            checked (Right (G.bipartiteColors graph)) (\result_value -> publish (wire result_value) out)
        (2, [vgraph]) -> do
            graph <- unwire vgraph
            checked (Right (G.closenessCentrality graph)) (\result_value -> publish (wire result_value) out)
        (3, [vgraph]) -> do
            graph <- unwire vgraph
            checked (G.clusteringCoefficients graph) (\result_value -> publish (wire result_value) out)
        (4, [vgraph]) -> do
            graph <- unwire vgraph
            checked (Right (G.degreeCentrality graph)) (\result_value -> publish (wire result_value) out)
        (5, [vgraph]) -> do
            graph <- unwire vgraph
            checked (Right (G.density graph)) (\result_value -> publish (wire result_value) out)
        (6, [vgraph]) -> do
            graph <- unwire vgraph
            checked (Right (G.diameterRadius graph)) (\result_value -> publish (wire result_value) out)
        (7, [viterations, vtolerance, vgraph]) -> do
            iterations <- unwire viterations
            tolerance <- unwire vtolerance
            graph <- unwire vgraph
            checked (G.eigenvectorCentrality iterations tolerance graph) (\result_value -> publish (wire result_value) out)
        (8, [vgraph]) -> do
            graph <- unwire vgraph
            checked (G.eulerianPath graph) (\result_value -> publish (wire result_value) out)
        (9, [vfuel, vgraph]) -> do
            fuel <- unwire vfuel
            graph <- unwire vgraph
            checked (G.exactColoring fuel graph) (\result_value -> publish (wire result_value) out)
        (10, [vbudget, vleft, vright]) -> do
            budget <- unwire vbudget
            left <- unwire vleft
            right <- unwire vright
            checked (G.graphEditDistance budget left right) (\result_value -> publish (wire result_value) out)
        (11, [vnormalized, vgraph]) -> do
            normalized <- unwire vnormalized
            graph <- unwire vgraph
            checked (G.graphLaplacian normalized graph) (\result_value -> publish (wire result_value) out)
        (12, [vleft, vright]) -> do
            left <- unwire vleft
            right <- unwire vright
            checked (G.graphSimilarity left right) (\result_value -> publish (wire result_value) out)
        (13, [vgraph]) -> do
            graph <- unwire vgraph
            checked (G.greedyColoring graph) (\result_value -> publish (wire result_value) out)
        (14, [vfuel, vgraph]) -> do
            fuel <- unwire vfuel
            graph <- unwire vgraph
            checked (G.hamiltonianPath fuel graph) (\result_value -> publish (wire result_value) out)
        (15, [viterations, vtolerance, valpha, vbeta, vgraph]) -> do
            iterations <- unwire viterations
            tolerance <- unwire vtolerance
            alpha <- unwire valpha
            beta <- unwire vbeta
            graph <- unwire vgraph
            checked (G.katzCentrality iterations tolerance alpha beta graph) (\result_value -> publish (wire result_value) out)
        (16, [viterations, vgraph]) -> do
            iterations <- unwire viterations
            graph <- unwire vgraph
            checked (G.labelPropagation iterations graph) (\result_value -> publish (wire result_value) out)
        (17, [viterations, vtolerance, vnormalized, vgraph]) -> do
            iterations <- unwire viterations
            tolerance <- unwire vtolerance
            normalized <- unwire vnormalized
            graph <- unwire vgraph
            checked (G.laplacianSpectrum iterations tolerance normalized graph) (\result_value -> publish (wire result_value) out)
        (18, [vbudget, vgraph]) -> do
            budget <- unwire vbudget
            graph <- unwire vgraph
            checked (G.louvain budget graph) (\result_value -> publish (wire result_value) out)
        (19, [vgraph, vlabels]) -> do
            graph <- unwire vgraph
            labels <- unwire vlabels
            checked (G.modularity graph labels) (\result_value -> publish (wire result_value) out)
        (20, [vgraph, vstart]) -> do
            graph <- unwire vgraph
            start <- unwire vstart
            checked (G.nearestNeighborTour graph start) (\result_value -> publish (wire result_value) out)
        (21, [viterations, vtolerance, vdamping, vgraph]) -> do
            iterations <- unwire viterations
            tolerance <- unwire vtolerance
            damping <- unwire vdamping
            graph <- unwire vgraph
            checked (G.pageRank iterations tolerance damping graph) (\result_value -> publish (wire result_value) out)
        (22, [vcount, vseed, vgraph, vstart]) -> do
            count <- unwire vcount
            seed <- unwire vseed
            graph <- unwire vgraph
            start <- unwire vstart
            checked (G.randomWalk count seed graph start) (\result_value -> publish (wire result_value) out)
        (23, [viterations, vgraph, vtour]) -> do
            iterations <- unwire viterations
            graph <- unwire vgraph
            tour <- unwire vtour
            checked (G.twoOptTour iterations graph tour) (\result_value -> publish (wire result_value) out)
        (24, [vdirected, vvertex_count, voffsets, vtargets, vweights, vedge_ids, vorientations]) -> do
            directed <- unwire vdirected
            vertex_count <- unwire vvertex_count
            offsets <- unwire voffsets
            targets <- unwire vtargets
            weights <- unwire vweights
            edge_ids <- unwire vedge_ids
            orientations <- unwire vorientations
            checked (Right (G.CSR directed vertex_count offsets targets weights edge_ids orientations)) (\result_value -> publish (wire result_value) out)
        (25, [vedge_id, vsource, vtarget, vweight]) -> do
            edge_id <- unwire vedge_id
            source <- unwire vsource
            target <- unwire vtarget
            weight <- unwire vweight
            checked (Right (G.Edge edge_id source target weight)) (\result_value -> publish (wire result_value) out)
        (26, [vgraph]) -> do
            graph <- unwire vgraph
            checked (Right (G.adjacencyList graph)) (\result_value -> publish (wire result_value) out)
        (27, [vgraph]) -> do
            graph <- unwire vgraph
            checked (Right (G.adjacencyMatrix graph)) (\result_value -> publish (wire result_value) out)
        (28, [vgraph]) -> do
            graph <- unwire vgraph
            checked (Right (G.arcs graph)) (\result_value -> publish (wire result_value) out)
        (29, [vgraph]) -> do
            graph <- unwire vgraph
            checked (G.articulationPoints graph) (\result_value -> publish (wire result_value) out)
        (30, [vgraph, vstart]) -> do
            graph <- unwire vgraph
            start <- unwire vstart
            checked (G.bfs graph start) (\result_value -> publish (wire result_value) out)
        (31, [vbipartite_graph]) -> do
            bipartite_graph <- unwire vbipartite_graph
            checked (Right (G.bipartiteBase bipartite_graph)) (\result_value -> publish (wire result_value) out)
        (32, [vleft_vertices, vright_vertices, vedges]) -> do
            left_vertices <- unwire vleft_vertices
            right_vertices <- unwire vright_vertices
            edges <- unwire vedges
            checked (G.bipartiteGraph left_vertices right_vertices edges) (\result_value -> publish (wire result_value) out)
        (33, [vbipartite_graph]) -> do
            bipartite_graph <- unwire vbipartite_graph
            checked (Right (G.bipartiteParts bipartite_graph)) (\result_value -> publish (wire result_value) out)
        (34, [vgraph]) -> do
            graph <- unwire vgraph
            checked (G.boruvka graph) (\result_value -> publish (wire result_value) out)
        (35, [vgraph]) -> do
            graph <- unwire vgraph
            checked (G.bridges graph) (\result_value -> publish (wire result_value) out)
        (36, [vgraph, vvertex]) -> do
            graph <- unwire vgraph
            vertex <- unwire vvertex
            checked (G.checkVertex graph vertex) (\result_value -> publish (wire result_value) out)
        (37, [vgraph]) -> do
            graph <- unwire vgraph
            checked (Right (G.connectedComponents graph)) (\result_value -> publish (wire result_value) out)
        (38, [vcsr]) -> do
            csr <- unwire vcsr
            checked (Right (G.csrDirected csr)) (\result_value -> publish (wire result_value) out)
        (39, [vcsr]) -> do
            csr <- unwire vcsr
            checked (Right (G.csrIds csr)) (\result_value -> publish (wire result_value) out)
        (40, [vcsr]) -> do
            csr <- unwire vcsr
            checked (Right (G.csrOffsets csr)) (\result_value -> publish (wire result_value) out)
        (41, [vcsr]) -> do
            csr <- unwire vcsr
            checked (Right (G.csrOrientations csr)) (\result_value -> publish (wire result_value) out)
        (42, [vcsr]) -> do
            csr <- unwire vcsr
            checked (Right (G.csrTargets csr)) (\result_value -> publish (wire result_value) out)
        (43, [vcsr]) -> do
            csr <- unwire vcsr
            checked (Right (G.csrVertices csr)) (\result_value -> publish (wire result_value) out)
        (44, [vcsr]) -> do
            csr <- unwire vcsr
            checked (Right (G.csrWeights csr)) (\result_value -> publish (wire result_value) out)
        (45, [vtext]) -> do
            text <- unwire vtext
            checked (G.deserializeBipartiteGraph text) (\result_value -> publish (wire result_value) out)
        (46, [vtext]) -> do
            text <- unwire vtext
            checked (G.deserializeGraph text) (\result_value -> publish (wire result_value) out)
        (47, [vtext]) -> do
            text <- unwire vtext
            checked (G.deserializeHypergraph text) (\result_value -> publish (wire result_value) out)
        (48, [vgraph, vstart]) -> do
            graph <- unwire vgraph
            start <- unwire vstart
            checked (G.dfs graph start) (\result_value -> publish (wire result_value) out)
        (49, [vgraph]) -> do
            graph <- unwire vgraph
            checked (Right (G.directed graph)) (\result_value -> publish (wire result_value) out)
        (50, [vedge]) -> do
            edge <- unwire vedge
            checked (Right (G.edgeFrom edge)) (\result_value -> publish (wire result_value) out)
        (51, [vedge]) -> do
            edge <- unwire vedge
            checked (Right (G.edgeId edge)) (\result_value -> publish (wire result_value) out)
        (52, [vedge]) -> do
            edge <- unwire vedge
            checked (Right (G.edgeTo edge)) (\result_value -> publish (wire result_value) out)
        (53, [vedge]) -> do
            edge <- unwire vedge
            checked (Right (G.edgeWeight edge)) (\result_value -> publish (wire result_value) out)
        (54, [vgraph]) -> do
            graph <- unwire vgraph
            checked (Right (G.edges graph)) (\result_value -> publish (wire result_value) out)
        (55, [vx]) -> do
            x <- unwire vx
            checked (Right (G.finite x)) (\result_value -> publish (wire result_value) out)
        (56, [vdirected, vrows, vorientations]) -> do
            directed <- unwire vdirected
            rows <- unwire vrows
            orientations <- unwire vorientations
            checked (G.fromAdjacencyList directed rows orientations) (\result_value -> publish (wire result_value) out)
        (57, [vdirected, vcells]) -> do
            directed <- unwire vdirected
            cells <- unwire vcells
            checked (G.fromAdjacencyMatrix directed cells) (\result_value -> publish (wire result_value) out)
        (58, [vcsr]) -> do
            csr <- unwire vcsr
            checked (G.fromCSR csr) (\result_value -> publish (wire result_value) out)
        (59, [vdirected, vcells, vorientations]) -> do
            directed <- unwire vdirected
            cells <- unwire vcells
            orientations <- unwire vorientations
            checked (G.fromLabeledAdjacencyMatrix directed cells orientations) (\result_value -> publish (wire result_value) out)
        (60, [vdirected, vvertex_count, vedges]) -> do
            directed <- unwire vdirected
            vertex_count <- unwire vvertex_count
            edges <- unwire vedges
            checked (G.graph directed vertex_count edges) (\result_value -> publish (wire result_value) out)
        (61, [vgraph]) -> do
            graph <- unwire vgraph
            checked (Right (G.hasCycle graph)) (\result_value -> publish (wire result_value) out)
        (62, [vhypergraph]) -> do
            hypergraph <- unwire vhypergraph
            checked (Right (G.hyperVertices hypergraph)) (\result_value -> publish (wire result_value) out)
        (63, [vhypergraph]) -> do
            hypergraph <- unwire vhypergraph
            checked (Right (G.hyperedges hypergraph)) (\result_value -> publish (wire result_value) out)
        (64, [vvertex_count, vhyperedges]) -> do
            vertex_count <- unwire vvertex_count
            hyperedges <- unwire vhyperedges
            checked (G.hypergraph vertex_count hyperedges) (\result_value -> publish (wire result_value) out)
        (65, [vbudget, vgraph, vsource, vtarget]) -> do
            budget <- unwire vbudget
            graph <- unwire vgraph
            source <- unwire vsource
            target <- unwire vtarget
            checked (G.iterativeDeepening budget graph source target) (\result_value -> publish (wire result_value) out)
        (66, [vgraph]) -> do
            graph <- unwire vgraph
            checked (Right (G.kosarajuSCC graph)) (\result_value -> publish (wire result_value) out)
        (67, [vgraph]) -> do
            graph <- unwire vgraph
            checked (G.kruskal graph) (\result_value -> publish (wire result_value) out)
        (68, [vgraph, vvertex]) -> do
            graph <- unwire vgraph
            vertex <- unwire vvertex
            checked (Right (G.neighbors graph vertex)) (\result_value -> publish (wire result_value) out)
        (69, [vgraph]) -> do
            graph <- unwire vgraph
            checked (G.prim graph) (\result_value -> publish (wire result_value) out)
        (70, [vgraph]) -> do
            graph <- unwire vgraph
            checked (G.requireUndirected graph) (\result_value -> publish (wire result_value) out)
        (71, [vbipartite]) -> do
            bipartite <- unwire vbipartite
            checked (Right (G.serializeBipartiteGraph bipartite)) (\result_value -> publish (wire result_value) out)
        (72, [vgraph]) -> do
            graph <- unwire vgraph
            checked (Right (G.serializeGraph graph)) (\result_value -> publish (wire result_value) out)
        (73, [vhypergraph]) -> do
            hypergraph <- unwire vhypergraph
            checked (Right (G.serializeHypergraph hypergraph)) (\result_value -> publish (wire result_value) out)
        (74, [vgraph]) -> do
            graph <- unwire vgraph
            checked (Right (G.tarjanSCC graph)) (\result_value -> publish (wire result_value) out)
        (75, [vgraph]) -> do
            graph <- unwire vgraph
            checked (Right (G.toCSR graph)) (\result_value -> publish (wire result_value) out)
        (76, [vgraph]) -> do
            graph <- unwire vgraph
            checked (G.topologicalSort graph) (\result_value -> publish (wire result_value) out)
        (77, [vgraph]) -> do
            graph <- unwire vgraph
            checked (Right (G.vertexCount graph)) (\result_value -> publish (wire result_value) out)
        (78, [vvalue, vedge_flows, vcost]) -> do
            value <- unwire vvalue
            edge_flows <- unwire vedge_flows
            cost <- unwire vcost
            checked (Right (G.FlowResult value edge_flows cost)) (\result_value -> publish (wire result_value) out)
        (79, [vedge_id, vsource, vtarget, vcapacity, vcost]) -> do
            edge_id <- unwire vedge_id
            source <- unwire vsource
            target <- unwire vtarget
            capacity <- unwire vcapacity
            cost <- unwire vcost
            checked (Right (G.NetworkEdge edge_id source target capacity cost)) (\result_value -> publish (wire result_value) out)
        (80, [vbudget, vnetwork, vsource, vtarget]) -> do
            budget <- unwire vbudget
            network <- unwire vnetwork
            source <- unwire vsource
            target <- unwire vtarget
            checked (G.dinic budget network source target) (\result_value -> publish (wire result_value) out)
        (81, [vflow_result]) -> do
            flow_result <- unwire vflow_result
            checked (Right (G.edgeFlows flow_result)) (\result_value -> publish (wire result_value) out)
        (82, [vvalue, vnetwork, vvalue3, vvalue4]) -> do
            value <- unwire vvalue
            network <- unwire vnetwork
            value3 <- unwire vvalue3
            value4 <- unwire vvalue4
            checked (G.edmondsKarp value network value3 value4) (\result_value -> publish (wire result_value) out)
        (83, [vflow_result]) -> do
            flow_result <- unwire vflow_result
            checked (Right (G.flowCost flow_result)) (\result_value -> publish (wire result_value) out)
        (84, [vflow_result]) -> do
            flow_result <- unwire vflow_result
            checked (Right (G.flowValue flow_result)) (\result_value -> publish (wire result_value) out)
        (85, [vvalue, vnetwork, vvalue3, vvalue4]) -> do
            value <- unwire vvalue
            network <- unwire vnetwork
            value3 <- unwire vvalue3
            value4 <- unwire vvalue4
            checked (G.fordFulkerson value network value3 value4) (\result_value -> publish (wire result_value) out)
        (86, [vbipartite]) -> do
            bipartite <- unwire vbipartite
            checked (Right (G.hopcroftKarp bipartite)) (\result_value -> publish (wire result_value) out)
        (87, [vcosts]) -> do
            costs <- unwire vcosts
            checked (G.hungarian costs) (\result_value -> publish (wire result_value) out)
        (88, [vvalue, vnetwork, vvalue3, vvalue4]) -> do
            value <- unwire vvalue
            network <- unwire vnetwork
            value3 <- unwire vvalue3
            value4 <- unwire vvalue4
            checked (G.minimumCostMaximumFlow value network value3 value4) (\result_value -> publish (wire result_value) out)
        (89, [vvalue, vnetwork, vvalue3, vvalue4]) -> do
            value <- unwire vvalue
            network <- unwire vnetwork
            value3 <- unwire vvalue3
            value4 <- unwire vvalue4
            checked (G.minimumCut value network value3 value4) (\result_value -> publish (wire result_value) out)
        (90, [vvertex_count, vedges]) -> do
            vertex_count <- unwire vvertex_count
            edges <- unwire vedges
            checked (G.network vertex_count edges) (\result_value -> publish (wire result_value) out)
        (91, [vnetwork_edge]) -> do
            network_edge <- unwire vnetwork_edge
            checked (Right (G.networkCapacity network_edge)) (\result_value -> publish (wire result_value) out)
        (92, [vnetwork_edge]) -> do
            network_edge <- unwire vnetwork_edge
            checked (Right (G.networkCost network_edge)) (\result_value -> publish (wire result_value) out)
        (93, [vnetwork_edge]) -> do
            network_edge <- unwire vnetwork_edge
            checked (Right (G.networkEdgeId network_edge)) (\result_value -> publish (wire result_value) out)
        (94, [vnetwork]) -> do
            network <- unwire vnetwork
            checked (Right (G.networkEdges network)) (\result_value -> publish (wire result_value) out)
        (95, [vnetwork_edge]) -> do
            network_edge <- unwire vnetwork_edge
            checked (Right (G.networkFrom network_edge)) (\result_value -> publish (wire result_value) out)
        (96, [vnetwork_edge]) -> do
            network_edge <- unwire vnetwork_edge
            checked (Right (G.networkTo network_edge)) (\result_value -> publish (wire result_value) out)
        (97, [vvalue, vnetwork, vvalue3, vvalue4]) -> do
            value <- unwire vvalue
            network <- unwire vnetwork
            value3 <- unwire vvalue3
            value4 <- unwire vvalue4
            checked (G.pushRelabel value network value3 value4) (\result_value -> publish (wire result_value) out)
        (98, [vgraph, vsource, vtarget]) -> do
            graph <- unwire vgraph
            let heuristic = heuristicFunction callback userdata
            source <- unwire vsource
            target <- unwire vtarget
            checked (G.aStar graph heuristic source target) (\result_value -> publish (wire result_value) out)
        (99, [vgraph, vsource]) -> do
            graph <- unwire vgraph
            source <- unwire vsource
            checked (G.bellmanFord graph source) (\result_value -> publish (wire result_value) out)
        (100, [vgraph, vsource, vtarget]) -> do
            graph <- unwire vgraph
            source <- unwire vsource
            target <- unwire vtarget
            checked (G.bidirectionalDijkstra graph source target) (\result_value -> publish (wire result_value) out)
        (101, [vgraph, vsource]) -> do
            graph <- unwire vgraph
            source <- unwire vsource
            checked (G.dijkstra graph source) (\result_value -> publish (wire result_value) out)
        (102, [vgraph]) -> do
            graph <- unwire vgraph
            checked (G.floydWarshall graph) (\result_value -> publish (wire result_value) out)
        (103, [vgraph]) -> do
            graph <- unwire vgraph
            checked (G.johnson graph) (\result_value -> publish (wire result_value) out)
        (104, [vbudget, vcount, vgraph, vsource, vtarget]) -> do
            budget <- unwire vbudget
            count <- unwire vcount
            graph <- unwire vgraph
            source <- unwire vsource
            target <- unwire vtarget
            checked (G.kShortestPaths budget count graph source target) (\result_value -> publish (wire result_value) out)
        (105, [vgraph, vsource]) -> do
            graph <- unwire vgraph
            source <- unwire vsource
            checked (G.longestDAGPaths graph source) (\result_value -> publish (wire result_value) out)
        (106, [vgraph, vsources]) -> do
            graph <- unwire vgraph
            sources <- unwire vsources
            checked (G.multiSourceDijkstra graph sources) (\result_value -> publish (wire result_value) out)
        _ -> invalid "Graph operation arity or identifier differs"
