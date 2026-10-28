-- SPDX-License-Identifier: MPL-2.0

{- | Checked finite labeled multigraphs. Vertices are @[0,n)@; input edge order
assigns stable edge IDs. Loops and parallel edges are retained. In undirected
graphs every edge yields two traversal arcs (a loop therefore has degree two).
Limits: 512 vertices, 65536 edges. Ties use vertex/edge order.
-}
module HMath.Graph.Core (
    Graph,
    Edge (..),
    directed,
    vertexCount,
    edges,
    graph,
    arcs,
    neighbors,
    fromAdjacencyList,
    fromLabeledAdjacencyMatrix,
    adjacencyList,
    adjacencyMatrix,
    fromAdjacencyMatrix,
    CSR (..),
    toCSR,
    fromCSR,
    BipartiteGraph,
    bipartiteGraph,
    bipartiteParts,
    bipartiteBase,
    Hypergraph,
    hypergraph,
    hyperVertices,
    hyperedges,
    serializeBipartiteGraph,
    deserializeBipartiteGraph,
    serializeGraph,
    deserializeGraph,
    serializeHypergraph,
    deserializeHypergraph,
    bfs,
    dfs,
    iterativeDeepening,
    topologicalSort,
    hasCycle,
    connectedComponents,
    tarjanSCC,
    kosarajuSCC,
    articulationPoints,
    bridges,
    kruskal,
    prim,
    boruvka,
    checkVertex,
    requireUndirected,
    finite,
) where

import qualified Data.Foldable as Foldable (foldl')
import Data.List (nub, sort, sortOn)
import qualified Data.Map.Strict as M
import qualified Data.Set as S
import qualified HMath.DataStructure as U
import HMath.Error (MathError (..))
import Text.Read (readMaybe)

data Edge = Edge {edgeId :: Int, edgeFrom :: Int, edgeTo :: Int, edgeWeight :: Double}
    deriving (Eq, Ord, Show, Read)
data Graph = Graph Bool Int [Edge] deriving (Eq, Show)
directed :: Graph -> Bool
directed (Graph d _ _) = d
vertexCount :: Graph -> Int
vertexCount (Graph _ n _) = n
edges :: Graph -> [Edge]
edges (Graph _ _ es) = es
finite :: Double -> Bool
finite x = not (isNaN x || isInfinite x)
graph :: Bool -> Int -> [(Int, Int, Double)] -> Either MathError Graph
graph d n es
    | n < 0 || n > 512 || length es > 65536 = Left (InvalidArgument "graph size limit exceeded")
    | any (\(u, v, w) -> u < 0 || v < 0 || u >= n || v >= n || not (finite w)) es =
        Left (InvalidArgument "invalid graph endpoint/weight")
    | otherwise = Right (Graph d n [Edge i u v w | (i, (u, v, w)) <- zip [0 ..] es])
checkVertex :: Graph -> Int -> Either MathError ()
checkVertex g v
    | v < 0 || v >= vertexCount g = Left (InvalidArgument "graph vertex out of bounds")
    | otherwise = Right ()
requireUndirected :: Graph -> Either MathError ()
requireUndirected g | directed g = Left (InvalidArgument "undirected graph required") | otherwise = Right ()
arcs :: Graph -> [Edge]
arcs g
    | directed g = edges g
    | otherwise = concat [[e, e{edgeFrom = edgeTo e, edgeTo = edgeFrom e}] | e <- edges g]
neighbors :: Graph -> Int -> [(Int, Double, Int)]
neighbors g v = sort [(edgeTo e, edgeWeight e, edgeId e) | e <- arcs g, edgeFrom e == v]
adjacencyList :: Graph -> [[(Int, Double, Int)]]
adjacencyList g = [neighbors g v | v <- [0 .. vertexCount g - 1]]

-- | Cells contain every @(edge ID,weight)@, preserving edge multiplicity.
adjacencyMatrix :: Graph -> [[[(Int, Double)]]]
adjacencyMatrix g =
    [ [[(edgeId e, edgeWeight e) | e <- arcs g, edgeFrom e == u, edgeTo e == v] | v <- [0 .. n - 1]]
    | u <- [0 .. n - 1]
    ]
  where
    n = vertexCount g

{- | Lossless labeled adjacency-list conversion. The final argument records
the original direction of each undirected edge, which symmetric arcs alone
cannot distinguish. IDs must be contiguous; rows are canonical sorted order.
-}
fromAdjacencyList :: Bool -> [[(Int, Double, Int)]] -> [(Int, Int)] -> Either MathError Graph
fromAdjacencyList d rows orientations =
    let entries = concat rows
     in fromCSR
            ( CSR
                d
                (length rows)
                (scanl (+) 0 (map length rows))
                [v | (v, _, _) <- entries]
                [w | (_, w, _) <- entries]
                [i | (_, _, i) <- entries]
                orientations
            )

fromLabeledAdjacencyMatrix :: Bool -> [[[(Int, Double)]]] -> [(Int, Int)] -> Either MathError Graph
fromLabeledAdjacencyMatrix d cells orientations
    | any ((/= length cells) . length) cells = Left (InvalidArgument "adjacency matrix must be square")
    | otherwise =
        fromAdjacencyList
            d
            [sort [(v, w, i) | (v, entries) <- zip [0 ..] row, (i, w) <- entries] | row <- cells]
            orientations

{- | Matrix cells are weights; undirected matrices must be exactly symmetric.
Diagonal entries denote one loop each, rather than duplicated traversal arcs.
-}
fromAdjacencyMatrix :: Bool -> [[[Double]]] -> Either MathError Graph
fromAdjacencyMatrix d matrix
    | any ((/= n) . length) matrix
        || (not d && or [matrix !! i !! j /= matrix !! j !! i | i <- [0 .. n - 1], j <- [0 .. n - 1]]) =
        Left (InvalidArgument "invalid/symmetric adjacency matrix required")
    | otherwise =
        graph d n [(i, j, w) | i <- [0 .. n - 1], j <- [0 .. n - 1], d || i <= j, w <- matrix !! i !! j]
  where
    n = length matrix

data CSR = CSR
    { csrDirected :: Bool
    , csrVertices :: Int
    , csrOffsets :: [Int]
    , csrTargets :: [Int]
    , csrWeights :: [Double]
    , csrIds :: [Int]
    , csrOrientations :: [(Int, Int)]
    }
    deriving (Eq, Show, Read)
toCSR :: Graph -> CSR
toCSR g =
    let rows = adjacencyList g; entries = concat rows
     in CSR
            (directed g)
            (vertexCount g)
            (scanl (+) 0 (map length rows))
            [v | (v, _, _) <- entries]
            [w | (_, w, _) <- entries]
            [i | (_, _, i) <- entries]
            [(edgeFrom e, edgeTo e) | e <- edges g]
fromCSR :: CSR -> Either MathError Graph
fromCSR input@(CSR d n offsets targets weights ids orientations)
    | n < 0
        || n > 512
        || length offsets /= n + 1
        || null offsets
        || offsets !! 0 /= 0
        || last offsets /= length targets
        || not (and (zipWith (<=) offsets (drop 1 offsets)))
        || length targets /= length weights
        || length ids /= length weights =
        Left (InvalidArgument "malformed CSR")
    | otherwise = do
        let rows =
                [ (u, targets !! j, weights !! j, ids !! j)
                | u <- [0 .. n - 1]
                , j <- [offsets !! u .. offsets !! (u + 1) - 1]
                ]
            groups = M.toAscList (M.fromListWith (++) [(i, [(u, v, w)]) | (u, v, w, i) <- rows])
        if map fst groups /= [0 .. length groups - 1]
            then Left (InvalidArgument "CSR edge IDs must be contiguous")
            else do
                triples <- mapM recover groups
                candidate <- graph d n triples
                if toCSR candidate == input
                    then pure candidate
                    else Left (InvalidArgument "CSR orientation metadata mismatch")
  where
    recover (i, entries)
        | i < 0 || i >= length orientations = Left (InvalidArgument "CSR missing edge orientation")
        | otherwise =
            let (u, v) = orientations !! i
                expected = if d then [(u, v)] else [(u, v), (v, u)]
                weightsForEdge = [w | (_, _, w) <- entries]
             in case weightsForEdge of
                    [] -> Left (InvalidArgument "CSR missing edge")
                    (w : _)
                        | sort [(a, b) | (a, b, _) <- entries] == sort expected && all (== w) weightsForEdge ->
                            Right (u, v, w)
                        | otherwise -> Left (InvalidArgument "CSR edge identity/orientation mismatch")

data BipartiteGraph = BipartiteGraph Int Graph deriving (Eq, Show)
bipartiteGraph :: Int -> Int -> [(Int, Int, Double)] -> Either MathError BipartiteGraph
bipartiteGraph left right es
    | left < 0 || right < 0 || any (\(u, v, _) -> u < 0 || u >= left || v < 0 || v >= right) es =
        Left (InvalidArgument "bipartite endpoints out of bounds")
    | otherwise =
        BipartiteGraph left <$> graph False (left + right) [(u, left + v, w) | (u, v, w) <- es]
bipartiteParts :: BipartiteGraph -> (Int, Int)
bipartiteParts (BipartiteGraph l g) = (l, vertexCount g - l)
bipartiteBase :: BipartiteGraph -> Graph
bipartiteBase (BipartiteGraph _ g) = g

data Hypergraph = Hypergraph Int [[Int]] deriving (Eq, Show)
hypergraph :: Int -> [[Int]] -> Either MathError Hypergraph
hypergraph n es
    | n < 0
        || n > 512
        || length es > 65536
        || any (any (\v -> v < 0 || v >= n)) es
        || any (\e -> length (nub e) /= length e) es =
        Left (InvalidArgument "invalid hypergraph")
    | otherwise = Right (Hypergraph n (map sort es))
hyperVertices :: Hypergraph -> Int
hyperVertices (Hypergraph n _) = n
hyperedges :: Hypergraph -> [[Int]]
hyperedges (Hypergraph _ es) = es

{- | Versioned Haskell tuple grammar. Deserialization validates all invariants,
requires full-input parsing and limits input text to 16 MiB.
-}
serializeBipartiteGraph :: BipartiteGraph -> String
serializeBipartiteGraph bip =
    let (left, right) = bipartiteParts bip
     in show
            ( "HMath.BipartiteGraph/1"
            , left
            , right
            , [(edgeFrom e, edgeTo e - left, edgeWeight e) | e <- edges (bipartiteBase bip)]
            )

deserializeBipartiteGraph :: String -> Either MathError BipartiteGraph
deserializeBipartiteGraph text
    | length text > 16777216 = Left (InvalidArgument "serialized bipartite graph too large")
    | otherwise = case readMaybe text of
        Just (version, left, right, es) | version == ("HMath.BipartiteGraph/1" :: String) -> bipartiteGraph left right es
        _ -> Left (InvalidArgument "invalid bipartite serialization/version")

serializeGraph :: Graph -> String
serializeGraph g =
    show
        ("HMath.Graph/1", directed g, vertexCount g, [(edgeFrom e, edgeTo e, edgeWeight e) | e <- edges g])

deserializeGraph :: String -> Either MathError Graph
deserializeGraph text
    | length text > 16777216 = Left (InvalidArgument "serialized graph too large")
    | otherwise = case readMaybe text of
        Just (version, d, n, es) | version == ("HMath.Graph/1" :: String) -> graph d n es
        _ -> Left (InvalidArgument "invalid graph serialization/version")
serializeHypergraph :: Hypergraph -> String
serializeHypergraph h = show ("HMath.Hypergraph/1", hyperVertices h, hyperedges h)
deserializeHypergraph :: String -> Either MathError Hypergraph
deserializeHypergraph text
    | length text > 16777216 = Left (InvalidArgument "serialized hypergraph too large")
    | otherwise = case readMaybe text of
        Just (version, n, es) | version == ("HMath.Hypergraph/1" :: String) -> hypergraph n es
        _ -> Left (InvalidArgument "invalid hypergraph serialization/version")

bfs :: Graph -> Int -> Either MathError [Int]
bfs g start = do checkVertex g start; pure (go S.empty [start])
  where
    go _ [] = []
    go seen (v : rest)
        | S.member v seen = go seen rest
        | otherwise = v : go (S.insert v seen) (rest ++ [u | (u, _, _) <- neighbors g v])
dfs :: Graph -> Int -> Either MathError [Int]
dfs g start = do checkVertex g start; pure (go S.empty [start])
  where
    go _ [] = []
    go seen (v : rest)
        | S.member v seen = go seen rest
        | otherwise = v : go (S.insert v seen) ([u | (u, _, _) <- neighbors g v] ++ rest)

-- | Iterative deepening simple-path DFS. Fuel counts visited search nodes.
iterativeDeepening :: Int -> Graph -> Int -> Int -> Either MathError (Maybe [Int])
iterativeDeepening b g source target = do
    checkVertex g source
    checkVertex g target
    if b < 0 then Left (InvalidArgument "negative DFS budget") else search b 0
  where
    search fuel depth
        | depth >= vertexCount g = Right Nothing
        | otherwise = do
            (answer, left) <- limited fuel depth [source]; maybe (search left (depth + 1)) (pure . Just) answer
    limited fuel depth path
        | fuel <= 0 = Left (NonConvergence "iterative deepening DFS" b)
        | last path == target = Right (Just path, fuel - 1)
        | depth == 0 = Right (Nothing, fuel - 1)
        | otherwise =
            Foldable.foldl'
                ( \previous v -> do
                    (answer, left) <- previous
                    case answer of { Just _ -> pure (answer, left); Nothing -> limited left (depth - 1) (path ++ [v]) }
                )
                (Right (Nothing, fuel - 1))
                [v | (v, _, _) <- neighbors g (last path), v `notElem` path]

topologicalSort :: Graph -> Either MathError [Int]
topologicalSort g
    | not (directed g) = Left (InvalidArgument "topological sort requires directed graph")
    | otherwise = go [] [0 .. vertexCount g - 1]
  where
    go out [] = Right out
    go out remaining = case [v | v <- remaining, not (any (\e -> edgeTo e == v && edgeFrom e `elem` remaining) (edges g))] of
        [] -> Left (DomainError "directed cycle")
        (v : _) -> go (out ++ [v]) (filter (/= v) remaining)
hasCycle :: Graph -> Bool
hasCycle g
    | directed g = either (const True) (const False) (topologicalSort g)
    | otherwise = either (const False) id $ do
        uf <- U.unionFind (vertexCount g)
        fst <$> Foldable.foldl' step (Right (False, uf)) (edges g)
  where
    step p e = do
        (found, uf) <- p
        same <- U.connected (edgeFrom e) (edgeTo e) uf
        next <- U.union (edgeFrom e) (edgeTo e) uf
        pure (found || same, next)
connectedComponents :: Graph -> [[Int]]
connectedComponents g = go S.empty [0 .. vertexCount g - 1]
  where
    links v = nub ([edgeTo e | e <- edges g, edgeFrom e == v] ++ [edgeFrom e | e <- edges g, edgeTo e == v])
    reach seen [] = seen
    reach seen (v : vs) | S.member v seen = reach seen vs | otherwise = reach (S.insert v seen) (links v ++ vs)
    go _ [] = []
    go seen (v : vs)
        | S.member v seen = go seen vs
        | otherwise = let c = reach S.empty [v] in S.toAscList c : go (S.union c seen) vs

-- | Tarjan's single-pass index/low-link stack algorithm.
tarjanSCC :: Graph -> [[Int]]
tarjanSCC g = sort (map sort output)
  where
    (_, _, _, _, _, output) =
        Foldable.foldl'
            (\state v -> if M.member v (second state) then state else visit v state)
            (0 :: Int, M.empty, M.empty, [], S.empty, [])
            [0 .. vertexCount g - 1]
    second (_, a, _, _, _, _) = a
    visit v (counter, index, low, stack, on, comps) =
        let initial = (counter + 1, M.insert v counter index, M.insert v counter low, v : stack, S.insert v on, comps)
            stepped = Foldable.foldl' (edge v) initial [u | (u, _, _) <- neighbors g v]
            (c, idx, lows, stk, active, cs) = stepped
         in if lows M.! v /= idx M.! v
                then stepped
                else
                    let (above, rest) = break (== v) stk; component = above ++ [v]
                     in (c, idx, lows, drop 1 rest, foldr S.delete active component, component : cs)
    edge v state@(_, idx, _, _, on, _) u
        | M.notMember u idx =
            let (c, i, l, s, o, cs) = visit u state in (c, i, M.insert v (min (l M.! v) (l M.! u)) l, s, o, cs)
        | S.member u on =
            let (c, i, l, s, o, cs) = state in (c, i, M.insert v (min (l M.! v) (idx M.! u)) l, s, o, cs)
        | otherwise = state

kosarajuSCC :: Graph -> [[Int]]
kosarajuSCC g = sort (map sort (snd (Foldable.foldl' second (S.empty, []) order)))
  where
    adj v = [u | (u, _, _) <- neighbors g v]
    rev v = [edgeFrom e | e <- arcs g, edgeTo e == v]
    finish (seen, out) v
        | S.member v seen = (seen, out)
        | otherwise = let (s, o) = Foldable.foldl' finish (S.insert v seen, out) (adj v) in (s, v : o)
    (_, order) = Foldable.foldl' finish (S.empty, []) [0 .. vertexCount g - 1]
    flood seen [] = seen
    flood seen (v : vs) | S.member v seen = flood seen vs | otherwise = flood (S.insert v seen) (rev v ++ vs)
    second (seen, cs) v
        | S.member v seen = (seen, cs)
        | otherwise =
            let reached = flood seen [v]; c = S.difference reached seen in (reached, S.toList c : cs)

-- | Removal-based reference algorithms, retaining parallel-edge identity.
articulationPoints :: Graph -> Either MathError [Int]
articulationPoints g = do
    requireUndirected g
    pure [v | v <- [0 .. vertexCount g - 1], componentCount (Just v) Nothing > baseline]
  where
    baseline = componentCount Nothing Nothing
    componentCount removed edgeRemoved = length (groups S.empty [v | v <- [0 .. vertexCount g - 1], Just v /= removed])
      where
        groups _ [] = []
        groups seen (v : vs)
            | S.member v seen = groups seen vs
            | otherwise = let c = reach S.empty [v] in c : groups (S.union c seen) vs
        reach seen [] = seen
        reach seen (v : vs)
            | S.member v seen = reach seen vs
            | otherwise =
                reach
                    (S.insert v seen)
                    ([u | (u, _, i) <- neighbors g v, Just u /= removed, Just i /= edgeRemoved] ++ vs)

bridges :: Graph -> Either MathError [Int]
bridges g = do
    requireUndirected g
    pure
        [ edgeId e
        | e <- edges g
        , length
            (connectedComponents (Graph False (vertexCount g) (filter ((/= edgeId e) . edgeId) (edges g))))
            > length (connectedComponents g)
        ]

kruskal :: Graph -> Either MathError [Edge]
kruskal g = do
    requireUndirected g
    uf <- U.unionFind (vertexCount g)
    fst <$> Foldable.foldl' step (Right ([], uf)) (sortOn (\e -> (edgeWeight e, edgeId e)) (edges g))
  where
    step p e = do
        (out, uf) <- p
        same <- U.connected (edgeFrom e) (edgeTo e) uf
        if same
            then pure (out, uf)
            else do
                next <- U.union (edgeFrom e) (edgeTo e) uf
                pure (out ++ [e], next)

{- | All three MST routines return a minimum spanning forest on disconnected
inputs. Self-loops are ignored, negative finite weights are supported.
-}
prim :: Graph -> Either MathError [Edge]
prim g = do requireUndirected g; pure (go S.empty [])
  where
    go seen out
        | S.size seen == vertexCount g = out
        | otherwise = case sortOn
            (\e -> (edgeWeight e, edgeId e))
            [e | e <- edges g, S.member (edgeFrom e) seen /= S.member (edgeTo e) seen] of
            (e : _) -> go (S.insert (edgeFrom e) (S.insert (edgeTo e) seen)) (out ++ [e])
            [] -> go (S.insert (([v | v <- [0 .. vertexCount g - 1], S.notMember v seen] !! 0)) seen) out

boruvka :: Graph -> Either MathError [Edge]
boruvka g = do
    requireUndirected g
    uf <- U.unionFind (vertexCount g)
    go uf []
  where
    go uf out = do
        candidates <- Foldable.foldl' (consider uf) (Right M.empty) (edges g)
        (added, next) <- Foldable.foldl' add (Right ([], uf)) (nub (M.elems candidates))
        if null added then pure out else go next (out ++ added)
    consider uf previous e = do
        m <- previous
        u <- U.findRoot (edgeFrom e) uf
        v <- U.findRoot (edgeTo e) uf
        let better a b = if (edgeWeight a, edgeId a) < (edgeWeight b, edgeId b) then a else b
        pure (if u == v then m else M.insertWith better u e (M.insertWith better v e m))
    add previous e = do
        (xs, current) <- previous
        same <- U.connected (edgeFrom e) (edgeTo e) current
        if same
            then pure (xs, current)
            else do
                z <- U.union (edgeFrom e) (edgeTo e) current
                pure (e : xs, z)
