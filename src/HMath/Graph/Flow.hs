-- SPDX-License-Identifier: MPL-2.0

{- | Exact integral network flow and assignment. Capacities and costs use
'Integer'; residual arcs preserve parallel and antiparallel edge identity.
Each max-flow algorithm has a caller-supplied augmentation/push/relabel budget.
-}
module HMath.Graph.Flow (
    Network,
    NetworkEdge (..),
    network,
    networkEdges,
    FlowResult (..),
    fordFulkerson,
    edmondsKarp,
    dinic,
    pushRelabel,
    minimumCut,
    minimumCostMaximumFlow,
    hopcroftKarp,
    hungarian,
) where

import qualified Data.Foldable as Foldable (foldl')
import Data.List (sort)
import qualified Data.Map.Strict as M
import qualified Data.Set as S
import HMath.Error (MathError (..))
import HMath.Graph.Core

data NetworkEdge = NetworkEdge
    { networkEdgeId :: Int
    , networkFrom :: Int
    , networkTo :: Int
    , networkCapacity :: Integer
    , networkCost :: Integer
    }
    deriving (Eq, Show)
data Network = Network Int [NetworkEdge] deriving (Eq, Show)
network :: Int -> [(Int, Int, Integer, Integer)] -> Either MathError Network
network n es
    | n < 0
        || n > 512
        || length es > 65536
        || any (\(u, v, c, _) -> u < 0 || v < 0 || u >= n || v >= n || c < 0) es =
        Left (InvalidArgument "invalid network size/endpoints/capacity")
    | otherwise = Right (Network n [NetworkEdge i u v c w | (i, (u, v, c, w)) <- zip [0 ..] es])
networkEdges :: Network -> [NetworkEdge]
networkEdges (Network _ es) = es

data FlowResult = FlowResult {flowValue :: Integer, edgeFlows :: [Integer], flowCost :: Integer}
    deriving (Eq, Show)
type Residual = M.Map Int Integer
arcData :: Network -> Int -> (Int, Int, Integer)
arcData (Network _ es) i =
    let e = es !! (i `div` 2)
     in if even i
            then (networkFrom e, networkTo e, networkCost e)
            else (networkTo e, networkFrom e, -networkCost e)
outgoing :: Network -> Residual -> Int -> [Int]
outgoing net@(Network _ es) residual u =
    [ i
    | i <- [0 .. 2 * length es - 1]
    , let (a, b, _) = arcData net i
    , a == u
    , a /= b
    , M.findWithDefault 0 i residual > 0
    ]
initial :: Network -> Residual
initial (Network _ es) =
    M.fromList
        (concat [[(2 * networkEdgeId e, networkCapacity e), (2 * networkEdgeId e + 1, 0)] | e <- es])
augment :: Integer -> [Int] -> Residual -> Residual
augment amount path r = Foldable.foldl' (\m i -> M.adjust (subtract amount) i (M.adjust (+ amount) (xorOne i) m)) r path
  where
    xorOne i = if even i then i + 1 else i - 1
result :: Network -> Int -> Residual -> FlowResult
result (Network _ es) source r = FlowResult value flows cost
  where
    flows = [networkCapacity e - M.findWithDefault 0 (2 * networkEdgeId e) r | e <- es]
    value =
        sum [f | (e, f) <- zip es flows, networkFrom e == source]
            - sum [f | (e, f) <- zip es flows, networkTo e == source]
    cost = sum [f * networkCost e | (e, f) <- zip es flows]
valid :: Int -> Network -> Int -> Int -> Either MathError ()
valid budget (Network n _) s t
    | budget < 0 || s < 0 || t < 0 || s >= n || t >= n || s == t =
        Left (InvalidArgument "invalid flow budget/source/sink")
    | otherwise = Right ()

findPath :: Bool -> Network -> Residual -> Int -> Int -> Maybe [Int]
findPath breadth net r s t = go S.empty [(s, [])]
  where
    go _ [] = Nothing
    go seen ((v, path) : rest)
        | v == t = Just path
        | S.member v seen = go seen rest
        | otherwise =
            let next = [(b, path ++ [i]) | i <- outgoing net r v, let (_, b, _) = arcData net i]
             in go (S.insert v seen) (if breadth then rest ++ next else next ++ rest)
augmenting :: Bool -> Int -> Network -> Int -> Int -> Either MathError FlowResult
augmenting breadth b net s t = do valid b net s t; go b (initial net)
  where
    go fuel r = case findPath breadth net r s t of
        Nothing -> Right (result net s r)
        Just path
            | fuel <= 0 -> Left (NonConvergence "augmenting maximum flow" b)
            | otherwise -> go (fuel - 1) (augment (minimum [r M.! i | i <- path]) path r)
fordFulkerson, edmondsKarp :: Int -> Network -> Int -> Int -> Either MathError FlowResult
fordFulkerson = augmenting False
edmondsKarp = augmenting True

dinic :: Int -> Network -> Int -> Int -> Either MathError FlowResult
dinic b net s t = do valid b net s t; phase b (initial net)
  where
    levels r = go (M.singleton s (0 :: Int)) [s]
      where
        go dist [] = dist
        go dist (v : vs) =
            let fresh = [u | i <- outgoing net r v, let (_, u, _) = arcData net i, M.notMember u dist]
                next = Foldable.foldl' (\m u -> M.insert u (dist M.! v + 1) m) dist fresh
             in go next (vs ++ S.toList (S.fromList fresh))
    layered r dist v
        | v == t = Just []
        | otherwise =
            first
                [ (i :) <$> layered r dist u
                | i <- outgoing net r v
                , let (_, u, _) = arcData net i
                , M.lookup u dist == ((+ 1) <$> M.lookup v dist)
                ]
    first [] = Nothing; first (Just x : _) = Just x; first (Nothing : xs) = first xs
    phase fuel r = let dist = levels r in if M.notMember t dist then pure (result net s r) else block fuel r dist
    block fuel r dist = case layered r dist s of
        Nothing -> phase fuel r
        Just path
            | fuel <= 0 -> Left (NonConvergence "Dinic maximum flow" b)
            | otherwise -> block (fuel - 1) (augment (minimum [r M.! i | i <- path]) path r) dist

pushRelabel :: Int -> Network -> Int -> Int -> Either MathError FlowResult
pushRelabel b net@(Network n _) s t = do
    valid b net s t
    let r0 = initial net
        pre = outgoing net r0 s
        (r, excess) =
            Foldable.foldl'
                ( \(res, ex) i ->
                    let amount = res M.! i; (_, u, _) = arcData net i
                     in (augment amount [i] res, M.insertWith (+) u amount (M.insertWith (+) s (-amount) ex))
                )
                (r0, M.empty)
                pre
    go b r excess (M.insert s n (M.fromList [(v, 0) | v <- [0 .. n - 1]]))
  where
    go fuel r excess heights = case [v | v <- [0 .. n - 1], v /= s, v /= t, M.findWithDefault 0 v excess > 0] of
        [] -> Right (result net s r)
        _ | fuel <= 0 -> Left (NonConvergence "push-relabel maximum flow" b)
        (v : _) -> case [i | i <- outgoing net r v, let (_, u, _) = arcData net i, heights M.! v == heights M.! u + 1] of
            (i : _) ->
                let (_, u, _) = arcData net i; amount = min (excess M.! v) (r M.! i)
                 in go
                        (fuel - 1)
                        (augment amount [i] r)
                        (M.insertWith (+) u amount (M.adjust (subtract amount) v excess))
                        heights
            [] -> case [heights M.! u | i <- outgoing net r v, let (_, u, _) = arcData net i] of
                [] -> Left (DomainError "invalid residual preflow")
                hs -> go (fuel - 1) r excess (M.insert v (minimum hs + 1) heights)

-- | Source-side vertices and cut capacity, using Edmonds--Karp residual reach.
minimumCut :: Int -> Network -> Int -> Int -> Either MathError ([Int], Integer)
minimumCut b net@(Network _ es) s t = do
    answer <- edmondsKarp b net s t
    let r = fromFlows net (edgeFlows answer)
        reach seen [] = seen
        reach seen (v : vs)
            | S.member v seen = reach seen vs
            | otherwise =
                reach (S.insert v seen) ([u | i <- outgoing net r v, let { (_, u, _) = arcData net i }] ++ vs)
        side = reach S.empty [s]
    pure
        ( S.toAscList side
        , sum [networkCapacity e | e <- es, S.member (networkFrom e) side, S.notMember (networkTo e) side]
        )

fromFlows :: Network -> [Integer] -> Residual
fromFlows (Network _ es) fs =
    M.fromList
        ( concat
            [[(2 * networkEdgeId e, networkCapacity e - f), (2 * networkEdgeId e + 1, f)] | (e, f) <- zip es fs]
        )

{- | Maximum flow followed by exact negative-residual-cycle cancellation. This
supports negative costs (including disconnected cycles) and finds the minimum
cost among all maximum flows. The same budget bounds each phase separately.
-}
minimumCostMaximumFlow :: Int -> Network -> Int -> Int -> Either MathError FlowResult
minimumCostMaximumFlow b net@(Network n es) s t = do
    start <- dinic b net s t
    cancel b (fromFlows net (edgeFlows start))
  where
    cancel fuel r = case negativeCycle r of
        Nothing -> Right (result net s r)
        Just path
            | fuel <= 0 -> Left (NonConvergence "minimum-cost cycle cancellation" b)
            | otherwise -> cancel (fuel - 1) (augment (minimum [r M.! i | i <- path]) path r)
    negativeCycle r =
        let active = [i | i <- [0 .. 2 * length es - 1], r M.! i > 0]
            iteration (dist, parent, _) =
                Foldable.foldl'
                    ( \(d, p, lastChanged) i ->
                        let (u, v, c) = arcData net i; candidate = d M.! u + c
                         in if candidate < d M.! v
                                then (M.insert v candidate d, M.insert v i p, Just v)
                                else (d, p, lastChanged)
                    )
                    (dist, parent, Nothing)
                    active
            (_, parents, lastVertex) = iterate iteration (M.fromList [(v, 0 :: Integer) | v <- [0 .. n - 1]], M.empty, Nothing) !! n
            previous v = let i = parents M.! v; (u, _, _) = arcData net i in u
            build start v acc = let i = parents M.! v; u = previous v in if u == start then i : acc else build start u (i : acc)
         in case lastVertex of
                Nothing -> Nothing
                Just v -> let start = iterate previous v !! n in Just (build start start [])

{- | Hopcroft--Karp layered augmenting paths. Returns @(left,right)@ matching;
parallel edges are coalesced and weights are ignored.
-}
hopcroftKarp :: BipartiteGraph -> [(Int, Int)]
hopcroftKarp bip = sort (M.toList (go M.empty M.empty))
  where
    (left, _) = bipartiteParts bip
    g = bipartiteBase bip
    adj u = S.toAscList (S.fromList [v - left | (v, _, _) <- neighbors g u])
    bfsLayer matching reverseMatching =
        walk
            (M.fromList [(u, 0 :: Int) | u <- [0 .. left - 1], M.notMember u matching])
            [u | u <- [0 .. left - 1], M.notMember u matching]
            Nothing
      where
        walk dist [] shortest = (dist, shortest)
        walk dist (u : us) shortest
            | maybe False (<= dist M.! u) shortest = walk dist us shortest
            | otherwise = foldNeighbors dist us shortest (adj u)
          where
            foldNeighbors d queue found [] = walk d queue found
            foldNeighbors d queue found (v : vs) = case M.lookup v reverseMatching of
                Nothing -> foldNeighbors d queue (Just (maybe (d M.! u + 1) (min (d M.! u + 1)) found)) vs
                Just partner
                    | M.notMember partner d ->
                        foldNeighbors (M.insert partner (d M.! u + 1) d) (queue ++ [partner]) found vs
                    | otherwise -> foldNeighbors d queue found vs
    augmentPath dist shortest u matching reverseMatching = try (adj u)
      where
        try [] = Nothing
        try (v : vs) = case M.lookup v reverseMatching of
            Nothing
                | M.lookup u dist == Just (shortest - 1) ->
                    Just (M.insert u v matching, M.insert v u reverseMatching)
                | otherwise -> try vs
            Just partner | M.lookup partner dist == ((+ 1) <$> M.lookup u dist) -> case augmentPath dist shortest partner matching reverseMatching of
                Just (m, r) -> Just (M.insert u v m, M.insert v u r)
                Nothing -> try vs
            _ -> try vs
    go matching reverseMatching = case bfsLayer matching reverseMatching of
        (_, Nothing) -> matching
        (dist, Just shortest) ->
            let (next, rev) =
                    Foldable.foldl'
                        (\(m, r) u -> if M.member u m then (m, r) else maybe (m, r) id (augmentPath dist shortest u m r))
                        (matching, reverseMatching)
                        [0 .. left - 1]
             in if M.size next == M.size matching then matching else go next rev

{- | Rectangular Hungarian primal-dual assignment, rows <= columns <= 256.
Every row is assigned to a distinct column; exact integer costs may be negative.
-}
hungarian :: [[Integer]] -> Either MathError (Integer, [(Int, Int)])
hungarian costs
    | rows > cols || cols > 256 || any ((/= cols) . length) costs =
        Left (InvalidArgument "Hungarian matrix must be rectangular, rows <= columns <= 256")
    | otherwise =
        let (_, _, assignment) = Foldable.foldl' addRow (M.empty, M.empty, M.empty) [1 .. rows]
            pairs = sort [(i - 1, j - 1) | (j, i) <- M.toList assignment, j /= 0]
         in Right (sum [costs !! i !! j | (i, j) <- pairs], pairs)
  where
    rows = length costs
    cols = if null costs then 0 else length (costs !! 0)
    value key = M.findWithDefault 0 key
    addRow (u, v, p) row = search 0 u v (M.insert 0 row p) S.empty M.empty M.empty
    search j0 u v p used slack way =
        let used' = S.insert j0 used
            i0 = p M.! j0
            candidates = [j | j <- [1 .. cols], S.notMember j used']
            (slack', way') =
                Foldable.foldl'
                    ( \(sl, wa) j ->
                        let reduced = costs !! (i0 - 1) !! (j - 1) - value i0 u - value j v
                         in if maybe True (reduced <) (M.lookup j sl)
                                then (M.insert j reduced sl, M.insert j j0 wa)
                                else (sl, wa)
                    )
                    (slack, way)
                    candidates
            (delta, j1) = minimum [(slack' M.! j, j) | j <- candidates]
            u' = Foldable.foldl' (\m j -> M.insertWith (+) (p M.! j) delta m) u (S.toList used')
            v' = Foldable.foldl' (\m j -> M.insertWith (+) j (-delta) m) v (S.toList used')
            sl' = M.mapWithKey (\j d -> if S.member j used' then d else d - delta) slack'
            augmentAssignment j assignment
                | j == 0 = assignment
                | otherwise =
                    let previous = way' M.! j
                     in augmentAssignment previous (M.insert j (assignment M.! previous) assignment)
         in if M.notMember j1 p
                then (u', v', M.delete 0 (augmentAssignment j1 p))
                else search j1 u' v' p used' sl' way'
