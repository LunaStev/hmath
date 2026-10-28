-- SPDX-License-Identifier: MPL-2.0

{- | Finite graph analysis. Centralities use unweighted distances unless their
name explicitly mentions weights. Undirected community algorithms use
nonnegative weights; loops contribute twice to degree. Exponential exact
coloring, Hamiltonian and edit searches require explicit work budgets.
-}
module HMath.Graph.Analysis (
    bipartiteColors,
    greedyColoring,
    exactColoring,
    eulerianPath,
    hamiltonianPath,
    nearestNeighborTour,
    twoOptTour,
    pageRank,
    degreeCentrality,
    betweennessCentrality,
    closenessCentrality,
    eigenvectorCentrality,
    katzCentrality,
    clusteringCoefficients,
    density,
    diameterRadius,
    graphLaplacian,
    laplacianSpectrum,
    randomWalk,
    labelPropagation,
    louvain,
    modularity,
    graphSimilarity,
    graphEditDistance,
) where

import Data.Bits (shiftR, xor)
import qualified Data.Foldable as Foldable (foldl')
import Data.List (nub, permutations, sort)
import qualified Data.Map.Strict as M
import qualified Data.Set as S
import Data.Word (Word64)
import HMath.Error (MathError (..))
import HMath.Graph.Core

allVertices :: Graph -> [Int]
allVertices g = [0 .. vertexCount g - 1]
weakNeighbors :: Graph -> Int -> [Int]
weakNeighbors g v =
    S.toAscList
        ( S.fromList
            ([edgeTo e | e <- edges g, edgeFrom e == v] ++ [edgeFrom e | e <- edges g, edgeTo e == v])
        )

{- | Return Just Bool colors for every vertex if the underlying undirected adjacency is
bipartite, including disconnected components; conflicting edges/loops yield Nothing.
-}
bipartiteColors :: Graph -> Maybe [Bool]
bipartiteColors g = mapM (`M.lookup` final) (allVertices g)
  where
    color known [] = Just known
    color known (v : vs) = do
        next <- Foldable.foldl' (assign v) (Just known) (weakNeighbors g v)
        color next (vs ++ [u | u <- weakNeighbors g v, M.notMember u known])
    assign v previous u = do
        m <- previous
        case M.lookup u m of
            Just c
                | c == m M.! v -> Nothing
                | otherwise -> Just m
            Nothing -> Just (M.insert u (not (m M.! v)) m)
    result =
        Foldable.foldl'
            (\p v -> do m <- p; if M.member v m then Just m else color (M.insert v False m) [v])
            (Just M.empty)
            (allVertices g)
    final = maybe M.empty id result

{- | Return zero-based greedy colors in vertex order using underlying undirected adjacency.
A self-loop makes proper coloring impossible and returns Left DomainError. Minimal
color count is not guaranteed.
-}
greedyColoring :: Graph -> Either MathError [Int]
greedyColoring g
    | any (\e -> edgeFrom e == edgeTo e) (edges g) =
        Left (DomainError "self-loop graph has no proper coloring")
    | otherwise = Right (map (colors M.!) (allVertices g))
  where
    colors =
        Foldable.foldl'
            ( \m v ->
                let forbidden = [color | u <- weakNeighbors g v, Just color <- [M.lookup u m]]
                    c = length (takeWhile (`elem` forbidden) [0 ..])
                 in M.insert v c m
            )
            M.empty
            (allVertices g)

{- | Given work budget then graph with at most 24 vertices, search for a minimum proper
coloring. Invalid budget/size or self-loops fail; exhausted search returns
NonConvergence.
-}
exactColoring :: Int -> Graph -> Either MathError [Int]
exactColoring fuel g = do
    initial <- greedyColoring g
    if fuel < 0 || vertexCount g > 24
        then Left (InvalidArgument "exact coloring supports at most 24 vertices")
        else fst <$> try fuel 0 initial
  where
    try left k initial
        | k > maximum (-1 : initial) + 1 = Right (initial, left)
        | otherwise = do
            (answer, remaining) <- assign left k []
            maybe (try remaining (k + 1) initial) (\a -> pure (a, remaining)) answer
    assign left k assigned
        | left <= 0 = Left (NonConvergence "exact coloring" fuel)
        | length assigned == vertexCount g = Right (Just assigned, left - 1)
        | otherwise =
            Foldable.foldl'
                ( \p c -> do
                    (answer, r) <- p
                    case answer of { Just _ -> pure (answer, r); Nothing -> assign r k (assigned ++ [c]) }
                )
                (Right (Nothing, left - 1))
                [ c
                | c <- [0 .. k - 1]
                , and [u >= length assigned || assigned !! u /= c | u <- weakNeighbors g (length assigned)]
                ]

{- | Hierholzer trail, consuming each original edge identity once. A directed
trail follows edge directions; disconnected nonisolated components fail.
-}
eulerianPath :: Graph -> Either MathError (Maybe ([Int], [Int]))
eulerianPath g
    | null (edges g) = Right (Just (if vertexCount g == 0 then [] else [0], []))
    | otherwise = case starts of
        [] -> Right Nothing
        (start : _) ->
            let (vertices, ids) = walk [(start, Nothing)] S.empty [] []
             in Right (if length ids == length (edges g) then Just (vertices, ids) else Nothing)
  where
    indeg v = length [e | e <- arcs g, edgeTo e == v]
    outdeg v = length (neighbors g v)
    active = [v | v <- allVertices g, outdeg v + indeg v > 0]
    oddVertices = [v | v <- active, odd (outdeg v)]
    plus = [v | v <- active, outdeg v - indeg v == 1]
    minus = [v | v <- active, indeg v - outdeg v == 1]
    starts
        | directed g && all (\v -> outdeg v == indeg v) active = take 1 active
        | directed g
            && length plus == 1
            && length minus == 1
            && all (\v -> abs (outdeg v - indeg v) <= 1) active =
            plus
        | directed g = []
        | null oddVertices = take 1 active
        | length oddVertices == 2 = take 1 oddVertices
        | otherwise = []
    walk [] _ vertices ids = (vertices, ids)
    walk stack@((v, incoming) : rest) used vertices ids = case [(u, i) | (u, _, i) <- neighbors g v, S.notMember i used] of
        ((u, i) : _) -> walk ((u, Just i) : stack) (S.insert i used) vertices ids
        [] -> walk rest used (v : vertices) (maybe ids (: ids) incoming)

{- | Given search budget then graph, find a path visiting every vertex once, returning Maybe
vertex list. Invalid options/exhausted budget fail; Nothing means exhaustive search
found no path.
-}
hamiltonianPath :: Int -> Graph -> Either MathError (Maybe [Int])
hamiltonianPath fuel g
    | fuel < 0 || vertexCount g > 24 =
        Left (InvalidArgument "Hamiltonian search supports at most 24 vertices")
    | vertexCount g == 0 = Right (Just [])
    | otherwise = fst <$> starts fuel (allVertices g)
  where
    starts left [] = Right (Nothing, left)
    starts left (v : vs) = do (answer, r) <- visit left [v]; maybe (starts r vs) (\a -> pure (Just a, r)) answer
    visit left path
        | left <= 0 = Left (NonConvergence "Hamiltonian path" fuel)
        | length path == vertexCount g = Right (Just path, left - 1)
        | otherwise =
            Foldable.foldl'
                (\p v -> do (answer, r) <- p; maybe (visit r (path ++ [v])) (\a -> pure (Just a, r)) answer)
                (Right (Nothing, left - 1))
                [v | v <- nub [u | (u, _, _) <- neighbors g (last path)], v `notElem` path]

edgeCost :: Graph -> Int -> Int -> Maybe Double
edgeCost g u v = case [w | (target, w, _) <- neighbors g u, target == v] of [] -> Nothing; ws -> Just (minimum ws)
pathCost :: Graph -> [Int] -> Maybe Double
pathCost g path = sum <$> sequence [edgeCost g u v | (u, v) <- zip path (drop 1 path)]

{- | Nearest-neighbor closed tour heuristic; incomplete graphs may fail. This
heuristic promises a valid tour, without an optimality/approximation bound.
-}
nearestNeighborTour :: Graph -> Int -> Either MathError (Maybe (Double, [Int]))
nearestNeighborTour g start = do
    checkVertex g start
    let go path
            | length path == vertexCount g = let tour = path ++ [start] in (\c -> (c, tour)) <$> pathCost g tour
            | otherwise = case sort [(w, v) | (v, w, _) <- neighbors g (last path), v `notElem` path] of
                [] -> Nothing
                (_, v) : _ -> go (path ++ [v])
        answer = if vertexCount g == 1 then Just (0, [start, start]) else go [start]
    if maybe False (not . finite . fst) answer then Left NonFiniteResult else pure answer

{- | Given improvement-step budget,graph,then closed Hamiltonian tour, improve via pairwise
segment reversals. Validate the tour permutation/edges and finite cost. Return
(cost,tour); invalid input or missing edges fails.
-}
twoOptTour :: Int -> Graph -> [Int] -> Either MathError (Double, [Int])
twoOptTour steps g tour
    | steps < 0
        || length tour /= vertexCount g + 1
        || null tour
        || tour !! 0 /= last tour
        || sort (init tour) /= allVertices g =
        Left (InvalidArgument "invalid closed tour/step limit")
    | otherwise = case pathCost g tour of
        Nothing -> Left (DomainError "tour contains absent edge")
        Just c -> go steps c tour
  where
    go remaining cost path
        | not (finite cost) = Left NonFiniteResult
        | otherwise = case sort
            [ (c, p)
            | i <- [1 .. length path - 3]
            , j <- [i + 1 .. length path - 2]
            , let p = take i path ++ reverse (take (j - i + 1) (drop i path)) ++ drop (j + 1) path
            , Just c <- [pathCost g p]
            , c < cost - 1e-12 * max 1 (abs cost)
            ] of
            [] -> Right (cost, path)
            _ | remaining <= 0 -> Left (NonConvergence "2-opt tour" steps)
            ((c, p) : _) -> go (remaining - 1) c p

validateIteration :: Int -> Double -> Either MathError ()
validateIteration steps tol
    | steps <= 0 || not (finite tol) || tol <= 0 =
        Left (InvalidArgument "positive iteration budget/tolerance required")
    | otherwise = Right ()
iterateVector ::
    String -> Int -> Double -> ([Double] -> [Double]) -> [Double] -> Either MathError [Double]
iterateVector name steps tol update = go steps
  where
    go remaining x =
        let y = update x
         in if any (not . finite) y
                then Left NonFiniteResult
                else
                    if maximum (0 : zipWith (\a b -> abs (a - b)) x y) <= tol
                        then Right y
                        else if remaining <= 1 then Left (NonConvergence name steps) else go (remaining - 1) y

{- | Given iteration budget,tolerance,damping,then graph, return vertex PageRank scores with
dangling-node redistribution. Require nonnegative weights, finite damping in [0,1),
valid tolerance/budget; nonconvergence/numeric failure returns Left MathError.
-}
pageRank :: Int -> Double -> Double -> Graph -> Either MathError [Double]
pageRank steps tol damping g = do
    validateIteration steps tol
    if not (finite damping) || damping < 0 || damping >= 1 || any ((< 0) . edgeWeight) (edges g)
        then Left (InvalidArgument "invalid PageRank damping/weights")
        else
            if any (not . finite . weights) (allVertices g)
                then Left NonFiniteResult
                else
                    if n == 0
                        then pure []
                        else iterateVector "PageRank" steps tol update (replicate n (1 / fromIntegral n))
  where
    n = vertexCount g
    weights u = sum [w | (_, w, _) <- neighbors g u]
    update x =
        [ (1 - damping) / fromIntegral n
            + damping
                * ( sum
                        [ x !! u * w / weights u
                        | e <- arcs g
                        , let u = edgeFrom e
                        , edgeTo e == v
                        , let w = edgeWeight e
                        , weights u > 0
                        ]
                        + sum [x !! u / fromIntegral n | u <- allVertices g, weights u == 0]
                  )
        | v <- allVertices g
        ]

{- | Return outgoing traversal degree divided by n-1 for each vertex; n\<=1 yields zeros.
Undirected loops contribute twice and parallel edges are retained, so values can exceed
one.
-}
degreeCentrality :: Graph -> [Double]
degreeCentrality g =
    [ if n <= 1 then 0 else fromIntegral (length (neighbors g v)) / fromIntegral (n - 1)
    | v <- allVertices g
    ]
  where
    n = vertexCount g

-- Brandes' unweighted accumulation; parallel arcs count as distinct shortest
-- edge paths, consistent with the graph's multigraph interpretation.

{- | Return unweighted shortest-path betweenness by vertex, accounting for shortest-path
multiplicities. Undirected scores are halved; edge weights are not path lengths here.
-}
betweennessCentrality :: Graph -> [Double]
betweennessCentrality g = map (/ if directed g then 1 else 2) (Foldable.foldl' source (replicate n 0) (allVertices g))
  where
    n = vertexCount g
    source central start =
        let walk [] dist sigma predecessors order = (dist, sigma, predecessors, order)
            walk (v : queue) dist sigma predecessors order =
                let visit (pending, known, counts, parentMap) (u, _, _) =
                        let unseen = M.notMember u known
                            updated = if unseen then M.insert u (known M.! v + 1) known else known
                         in if updated M.! u == known M.! v + 1
                                then
                                    ( if unseen then pending ++ [u] else pending
                                    , updated
                                    , M.insertWith (+) u (sigma M.! v) counts
                                    , M.insertWith (++) u [v] parentMap
                                    )
                                else (pending, updated, counts, parentMap)
                    (nextQueue, nextDistances, nextCounts, nextParents) = Foldable.foldl' visit (queue, dist, sigma, predecessors) (neighbors g v)
                 in walk nextQueue nextDistances nextCounts nextParents (v : order)
            (_, pathCounts, parents, stack) = walk [start] (M.singleton start (0 :: Int)) (M.singleton start (1 :: Double)) M.empty []
            delta =
                Foldable.foldl'
                    ( \d w ->
                        Foldable.foldl'
                            ( \acc v -> M.insertWith (+) v ((pathCounts M.! v) / (pathCounts M.! w) * (1 + M.findWithDefault 0 w d)) acc
                            )
                            d
                            (M.findWithDefault [] w parents)
                    )
                    M.empty
                    stack
         in zipWith (+) central [if v == start then 0 else M.findWithDefault 0 v delta | v <- allVertices g]

unweightedDistances :: Graph -> Int -> M.Map Int Int
unweightedDistances g start = go (M.singleton start 0) [start]
  where
    go dist [] = dist
    go dist (v : vs) =
        let fresh = S.toAscList (S.fromList [u | (u, _, _) <- neighbors g v, M.notMember u dist])
            next = Foldable.foldl' (\m u -> M.insert u (dist M.! v + 1) m) dist fresh
         in go next (vs ++ fresh)

{- | Return unweighted closeness with reachable-component correction:
reachable^2/((n-1)*sumDistances). Isolated/singleton vertices yield zero.
-}
closenessCentrality :: Graph -> [Double]
closenessCentrality g =
    [ let ds = M.elems (unweightedDistances g v); reachable = length ds - 1; total = sum ds
       in if total == 0 || n <= 1
            then 0
            else fromIntegral (reachable * reachable) / (fromIntegral (n - 1) * fromIntegral total)
    | v <- allVertices g
    ]
  where
    n = vertexCount g

weightedMultiply :: Graph -> [Double] -> [Double]
weightedMultiply g x = [sum [edgeWeight e * x !! edgeFrom e | e <- arcs g, edgeTo e == v] | v <- allVertices g]

{- | Shifted power iteration on (I+A), avoiding sign oscillation on bipartite
graphs. For reducible graphs the initial all-ones vector selects a Perron
combination; convergence and uniqueness are not promised.
-}
eigenvectorCentrality :: Int -> Double -> Graph -> Either MathError [Double]
eigenvectorCentrality steps tol g = do
    validateIteration steps tol
    if any ((< 0) . edgeWeight) (edges g)
        then Left (DomainError "eigenvector centrality requires nonnegative weights")
        else
            if vertexCount g == 0
                then pure []
                else
                    iterateVector
                        "eigenvector centrality"
                        steps
                        tol
                        update
                        (replicate (vertexCount g) (1 / sqrt (fromIntegral (vertexCount g))))
  where
    update x =
        let y = zipWith (+) x (weightedMultiply g x); norm = sqrt (sum (map (\v -> v * v) y))
         in map (/ norm) y

{- | Given iterations,tolerance,alpha,beta,then graph, iterate weighted Katz scores. Require
finite alpha>=0 and alpha times maximum absolute incoming weight sum \<1. Invalid input
or nonconvergence fails.
-}
katzCentrality :: Int -> Double -> Double -> Double -> Graph -> Either MathError [Double]
katzCentrality steps tol alpha beta g = do
    validateIteration steps tol
    let bound = maximum (0 : [sum [abs (edgeWeight e) | e <- arcs g, edgeTo e == v] | v <- allVertices g])
    if not (all finite [alpha, beta, bound]) || alpha < 0 || alpha * bound >= 1
        then Left (InvalidArgument "Katz requires alpha times maximum absolute incoming row sum < 1")
        else
            iterateVector
                "Katz centrality"
                steps
                tol
                (map (\v -> beta + alpha * v) . weightedMultiply g)
                (replicate (vertexCount g) beta)

{- | Return local undirected clustering coefficients from distinct non-self neighbor sets.
Degree below two yields zero. Directed graphs fail.
-}
clusteringCoefficients :: Graph -> Either MathError [Double]
clusteringCoefficients g = do
    requireUndirected g
    pure
        [ let ns = filter (/= v) (weakNeighbors g v)
              k = length ns
              links = length [(a, b) | a <- ns, b <- ns, a < b, b `elem` weakNeighbors g a]
           in if k < 2 then 0 else 2 * fromIntegral links / fromIntegral (k * (k - 1))
        | v <- allVertices g
        ]

-- | Simple graph density: parallel edges and loops are ignored.
density :: Graph -> Double
density g
    | n < 2 = 0
    | otherwise =
        fromIntegral (S.size pairs) / fromIntegral (if directed g then n * (n - 1) else n * (n - 1) `div` 2)
  where
    n = vertexCount g
    pairs =
        S.fromList
            [ ( if directed g
                    then (edgeFrom e, edgeTo e)
                    else (min (edgeFrom e) (edgeTo e), max (edgeFrom e) (edgeTo e))
              )
            | e <- edges g
            , edgeFrom e /= edgeTo e
            ]

{- | Nothing if disconnected (not strongly connected for directed graphs).
The empty graph has no diameter/radius; a singleton has (0,0).
-}
diameterRadius :: Graph -> Maybe (Int, Int)
diameterRadius g
    | vertexCount g == 0 || any ((/= vertexCount g) . M.size) distances = Nothing
    | otherwise = let ecc = map (maximum . M.elems) distances in Just (maximum ecc, minimum ecc)
  where
    distances = map (unweightedDistances g) (allVertices g)

{- | Given normalized Bool then nonnegative-weight undirected graph, return dense
combinatorial or normalized Laplacian rows. Directed/negative-weight graphs or
non-finite arithmetic fail.
-}
graphLaplacian :: Bool -> Graph -> Either MathError [[Double]]
graphLaplacian normalized g = do
    requireUndirected g
    if any ((< 0) . edgeWeight) (edges g)
        then Left (DomainError "Laplacian requires nonnegative weights")
        else do
            let n = vertexCount g
                a i j = sum [edgeWeight e | e <- arcs g, edgeFrom e == i, edgeTo e == j]
                degree i = sum [a i j | j <- [0 .. n - 1]]
                entry i j
                    | normalized && (degree i == 0 || degree j == 0) = 0
                    | normalized = (if i == j then 1 else 0) - (a i j / sqrt (degree i)) / sqrt (degree j)
                    | otherwise = (if i == j then degree i else 0) - a i j
                matrix = [[entry i j | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
            if any (not . finite . degree) [0 .. n - 1] || any (any (not . finite)) matrix
                then Left NonFiniteResult
                else pure matrix

{- | Symmetric Jacobi rotations; eigenvalues sorted ascending. Budget counts
rotations, tolerance is relative to the matrix's largest absolute entry.
-}
laplacianSpectrum :: Int -> Double -> Bool -> Graph -> Either MathError [Double]
laplacianSpectrum steps tol normalized g = do
    validateIteration steps tol
    if vertexCount g > 128
        then Left (InvalidArgument "Jacobi spectrum supports at most 128 vertices")
        else graphLaplacian normalized g >>= go steps
  where
    n = vertexCount g
    go remaining a
        | n < 2 = Right (if n == 0 then [] else [a !! 0 !! 0])
        | otherwise =
            let (off, p, q) = maximum [(abs (a !! i !! j), i, j) | i <- [0 .. n - 1], j <- [i + 1 .. n - 1]]
                scale = maximum (1 : map abs (concat a))
             in if off <= tol * scale
                    then Right (sort [a !! i !! i | i <- [0 .. n - 1]])
                    else
                        if remaining <= 0
                            then Left (NonConvergence "Jacobi Laplacian spectrum" steps)
                            else
                                let angle = 0.5 * atan2 (2 * a !! p !! q) (a !! q !! q - a !! p !! p)
                                    c = cos angle
                                    s = sin angle
                                    -- A'=J^T A J, with columns (c,-s),(s,c).
                                    value i j
                                        | i == p && j == p = c * c * a !! p !! p - 2 * c * s * a !! p !! q + s * s * a !! q !! q
                                        | i == q && j == q = s * s * a !! p !! p + 2 * c * s * a !! p !! q + c * c * a !! q !! q
                                        | (i == p && j == q) || (i == q && j == p) = 0
                                        | i == p = c * a !! p !! j - s * a !! q !! j
                                        | j == p = c * a !! i !! p - s * a !! i !! q
                                        | i == q = s * a !! p !! j + c * a !! q !! j
                                        | j == q = s * a !! i !! p + c * a !! i !! q
                                        | otherwise = a !! i !! j
                                    next = [[value i j | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
                                 in if any (any (not . finite)) next then Left NonFiniteResult else go (remaining - 1) next

{- | Weighted walk with a reproducible 64-bit SplitMix stream. At a sink it
remains in place. Zero-weight edges are never selected.
-}
randomWalk :: Int -> Word64 -> Graph -> Int -> Either MathError [Int]
randomWalk count seed g start = do
    checkVertex g start
    if count < 0 || count > 1048576 || any ((< 0) . edgeWeight) (edges g)
        then Left (InvalidArgument "invalid random walk length/weights")
        else go count seed start
  where
    mix x =
        let a = (x `xor` shiftR x 30) * 0xbf58476d1ce4e5b9; b = (a `xor` shiftR a 27) * 0x94d049bb133111eb
         in b `xor` shiftR b 31
    go 0 _ v = Right [v]
    go k state v =
        let links = [(u, w) | (u, w, _) <- neighbors g v, w > 0]
            total = sum (map snd links)
            next = state + 0x9e3779b97f4a7c15
            draw = fromIntegral (shiftR (mix next) 11) / 9007199254740992 * total
            choose _ [] = v
            choose r ((u, w) : rest) = if r < w then u else choose (r - w) rest
         in if not (finite total) then Left NonFiniteResult else (v :) <$> go (k - 1) next (choose draw links)

communityInput :: Graph -> Either MathError ()
communityInput g = do
    requireUndirected g
    if any ((< 0) . edgeWeight) (edges g)
        then Left (DomainError "nonnegative community weights required")
        else Right ()

{- | Given undirected nonnegative-weight graph then one community label per vertex, return
weighted modularity. Invalid graph/label length or arithmetic fails; loops follow the
module degree convention.
-}
modularity :: Graph -> [Int] -> Either MathError Double
modularity g labels = do
    communityInput g
    if length labels /= vertexCount g
        then Left (InvalidArgument "community labels length mismatch")
        else do
            let es = arcs g
                total = sum (map edgeWeight es)
                degrees = M.fromListWith (+) [(edgeFrom e, edgeWeight e) | e <- es]
                inside = sum [edgeWeight e | e <- es, labels !! edgeFrom e == labels !! edgeTo e]
                totals = M.fromListWith (+) [(labels !! v, M.findWithDefault 0 v degrees) | v <- allVertices g]
                q = if total == 0 then 0 else inside / total - sum [(d / total) ^ (2 :: Int) | d <- M.elems totals]
            if not (finite total)
                || any (not . finite) (M.elems degrees)
                || any (not . finite) (M.elems totals)
                || not (finite q)
                then Left NonFiniteResult
                else pure q

{- | Deterministic asynchronous label propagation. Budget counts full sweeps;
equal weighted votes retain the current label when possible.
-}
labelPropagation :: Int -> Graph -> Either MathError [Int]
labelPropagation steps g = do
    communityInput g
    if steps < 0
        then Left (InvalidArgument "negative community sweep budget")
        else go steps (allVertices g)
  where
    go remaining labels =
        let update current v =
                let votes = M.fromListWith (+) [(current !! u, w) | (u, w, _) <- neighbors g v, u /= v]
                    old = current !! v
                    best =
                        if M.null votes
                            then old
                            else
                                let top = maximum (M.elems votes)
                                    winners = [l | (l, w) <- M.toAscList votes, w == top]
                                 in if old `elem` winners then old else winners !! 0
                 in take v current ++ [best] ++ drop (v + 1) current
            next = Foldable.foldl' update labels (allVertices g)
         in if next == labels
                then Right labels
                else
                    if remaining <= 0 then Left (NonConvergence "label propagation" steps) else go (remaining - 1) next

{- | Louvain local modularity moves followed by graph aggregation, repeated
until no communities merge. Deterministic local optimum, not a global optimum.
Budget counts every modularity candidate evaluation across levels.
-}
louvain :: Int -> Graph -> Either MathError [Int]
louvain budget g = do
    communityInput g
    if budget < 0
        then Left (InvalidArgument "negative Louvain budget")
        else fst <$> level budget g (allVertices g)
  where
    level fuel current originalMap = do
        (labels, left) <- local fuel current (allVertices current)
        let keys = sort (nub labels)
            compression = M.fromList (zip keys [0 ..])
            compact = map (compression M.!) labels
            mapped = map (compact !!) originalMap
        if length keys == vertexCount current
            then pure (mapped, left)
            else do
                coarse <-
                    graph
                        False
                        (length keys)
                        [(compact !! edgeFrom e, compact !! edgeTo e, edgeWeight e) | e <- edges current]
                level left coarse mapped
    local fuel current labels = do
        (next, left) <-
            Foldable.foldl'
                ( \p v -> do
                    (assignment, r) <- p
                    baseline <- modularity current assignment
                    let choices = nub (assignment !! v : [assignment !! u | (u, _, _) <- neighbors current v])
                    if length choices > r
                        then Left (NonConvergence "Louvain modularity evaluations" budget)
                        else do
                            options <-
                                mapM
                                    ( \c ->
                                        let candidate = take v assignment ++ [c] ++ drop (v + 1) assignment
                                         in do q <- modularity current candidate; pure (q, c, candidate)
                                    )
                                    choices
                            let best = maximum options
                            pure (if first best > baseline + 1e-12 then third best else assignment, r - length choices)
                )
                (Right (labels, fuel))
                (allVertices current)
        if next == labels then pure (labels, left) else local left current next
    first (a, _, _) = a
    third (_, _, c) = c

{- | Jaccard similarity of labeled weighted edge multisets (vertex labels fixed),
counting matching multiplicities. Empty edge multisets have similarity one.
-}
graphSimilarity :: Graph -> Graph -> Either MathError Double
graphSimilarity a b
    | directed a /= directed b = Left (InvalidArgument "graph orientations differ")
    | otherwise =
        let x = bag a
            y = bag b
            keys = S.toList (M.keysSet x `S.union` M.keysSet y)
            common = sum [min (M.findWithDefault 0 k x) (M.findWithDefault 0 k y) | k <- keys]
            total = sum [max (M.findWithDefault 0 k x) (M.findWithDefault 0 k y) | k <- keys]
         in Right (if total == 0 then 1 else fromIntegral common / fromIntegral (total :: Int))
  where
    bag graphValue = M.fromListWith (+) [(key graphValue e, 1) | e <- edges graphValue]
    key graphValue e =
        if directed graphValue
            then (edgeFrom e, edgeTo e, edgeWeight e)
            else (min (edgeFrom e) (edgeTo e), max (edgeFrom e) (edgeTo e), edgeWeight e)

{- | Exact unlabeled graph edit distance: unit vertex/edge insertion/deletion,
edge weights are exact labels; relabeling vertices is free. Substitution is
deletion plus insertion. Enumerates padded vertex bijections, at most 9 nodes.
-}
graphEditDistance :: Int -> Graph -> Graph -> Either MathError Int
graphEditDistance budget a b
    | directed a /= directed b || n > 9 || budget < 0 =
        Left (InvalidArgument "edit distance requires same orientation and at most 9 vertices")
    | product [1 .. toInteger n] > toInteger budget =
        Left (NonConvergence "graph edit bijections" budget)
    | otherwise =
        Right (abs (vertexCount a - vertexCount b) + minimum (map distance (permutations [0 .. n - 1])))
  where
    n = max (vertexCount a) (vertexCount b)
    key u v w = if directed a then (u, v, w) else (min u v, max u v, w)
    bag = M.fromListWith (+) [(key (edgeFrom e) (edgeTo e) (edgeWeight e), 1 :: Int) | e <- edges b]
    distance permutation =
        let mapped =
                M.fromListWith
                    (+)
                    [ (key (permutation !! edgeFrom e) (permutation !! edgeTo e) (edgeWeight e), 1 :: Int) | e <- edges a
                    ]
            keys = S.toList (M.keysSet mapped `S.union` M.keysSet bag)
         in sum [abs (M.findWithDefault 0 k mapped - M.findWithDefault 0 k bag) | k <- keys]
