-- SPDX-License-Identifier: MPL-2.0

{- | Checked graph paths. Unreachable distances are 'Nothing'. A reachable
negative cycle is a domain error; all-pairs methods reject any negative cycle.
Nonfinite arithmetic is rejected. Dijkstra-family methods require nonnegative
weights. Returned vertex paths use lexicographic tie-breaking where applicable.
-}
module HMath.Graph.Paths (
    dijkstra,
    multiSourceDijkstra,
    bellmanFord,
    floydWarshall,
    johnson,
    aStar,
    bidirectionalDijkstra,
    kShortestPaths,
    longestDAGPaths,
) where

import Control.Monad (foldM)
import Data.List (sortOn)
import qualified Data.Map.Strict as M
import qualified Data.Set as S
import HMath.Error (MathError (..))
import HMath.Graph.Core

type Distances = M.Map Int Double

finish :: Graph -> Distances -> Either MathError [Maybe Double]
finish g values
    | any (not . finite) (M.elems values) = Left NonFiniteResult
    | otherwise = Right [M.lookup v values | v <- [0 .. vertexCount g - 1]]
nonnegative :: Graph -> Either MathError ()
nonnegative g
    | any ((< 0) . edgeWeight) (edges g) = Left (DomainError "nonnegative edge weights required")
    | otherwise = Right ()

checkedSum :: Double -> Double -> Either MathError Double
checkedSum a b = let c = a + b in if finite c then Right c else Left NonFiniteResult

multiSourceDijkstra :: Graph -> [Int] -> Either MathError [Maybe Double]
multiSourceDijkstra g sources = do
    mapM_ (checkVertex g) sources
    nonnegative g
    distances <- go S.empty (M.fromList [(v, 0) | v <- sources])
    finish g distances
  where
    go visited dist = case [(d, v) | (v, d) <- M.toList dist, S.notMember v visited] of
        [] -> Right dist
        options -> do
            let (_, v) = minimum options
            next <-
                foldM
                    (\m (u, w, _) -> do candidate <- checkedSum (dist M.! v) w; pure (M.insertWith min u candidate m))
                    dist
                    (neighbors g v)
            go (S.insert v visited) next

dijkstra :: Graph -> Int -> Either MathError [Maybe Double]
dijkstra g source = multiSourceDijkstra g [source]

relax :: [Edge] -> Distances -> Either MathError Distances
relax es initial = foldM step initial es
  where
    step m e = case M.lookup (edgeFrom e) m of
        Nothing -> Right m
        Just d -> do candidate <- checkedSum d (edgeWeight e); pure (M.insertWith min (edgeTo e) candidate m)
repeatRelax :: Int -> [Edge] -> Distances -> Either MathError Distances
repeatRelax count es initial = foldM (\m _ -> relax es m) initial [1 .. count]

bellmanFord :: Graph -> Int -> Either MathError [Maybe Double]
bellmanFord g source = do
    checkVertex g source
    dist <- repeatRelax (max 0 (vertexCount g - 1)) (arcs g) (M.singleton source 0)
    next <- relax (arcs g) dist
    if next /= dist then Left (DomainError "reachable negative cycle") else finish g dist

floydWarshall :: Graph -> Either MathError [[Maybe Double]]
floydWarshall g = do
    let n = vertexCount g
        initial =
            M.fromListWith
                min
                ([((v, v), 0) | v <- [0 .. n - 1]] ++ [((edgeFrom e, edgeTo e), edgeWeight e) | e <- arcs g])
        update dist k =
            foldM
                ( \m (i, j) -> case (M.lookup (i, k) dist, M.lookup (k, j) dist) of
                    (Just a, Just b) -> do candidate <- checkedSum a b; pure (M.insertWith min (i, j) candidate m)
                    _ -> Right m
                )
                dist
                [(i, j) | i <- [0 .. n - 1], j <- [0 .. n - 1]]
    out <- foldM update initial [0 .. n - 1]
    if any (\i -> M.findWithDefault 0 (i, i) out < 0) [0 .. n - 1]
        then Left (DomainError "negative cycle")
        else pure [[M.lookup (i, j) out | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]

{- | Johnson reweighting: Bellman--Ford potentials from an implicit zero-cost
super-source, followed by independent Dijkstra searches.
-}
johnson :: Graph -> Either MathError [[Maybe Double]]
johnson g = do
    let n = vertexCount g
    potentials <- repeatRelax n (arcs g) (M.fromList [(v, 0) | v <- [0 .. n - 1]])
    next <- relax (arcs g) potentials
    if next /= potentials
        then Left (DomainError "negative cycle")
        else do
            triples <- mapM (reweight potentials) (arcs g)
            weighted <- graph True n triples
            rows <- mapM (dijkstra weighted) [0 .. n - 1]
            mapM
                ( \i ->
                    mapM
                        ( \j -> case rows !! i !! j of
                            Nothing -> pure Nothing
                            Just distance -> do a <- checkedSum distance (-(potentials M.! i)); Just <$> checkedSum a (potentials M.! j)
                        )
                        [0 .. n - 1]
                )
                [0 .. n - 1]
  where
    reweight potentials e = do
        a <- checkedSum (edgeWeight e) (potentials M.! edgeFrom e)
        x <- checkedSum a (-(potentials M.! edgeTo e))
        let scale = max 1 (maximum (map abs [edgeWeight e, potentials M.! edgeFrom e, potentials M.! edgeTo e]))
        -- Clamp only cancellation within the stated relative rounding scale.
        if x < -1e-12 * scale
            then Left (DomainError "unstable Johnson reweighting")
            else pure (edgeFrom e, edgeTo e, max 0 x)

{- | A* requires a finite consistent heuristic, h(target)=0, checked on all
arcs. This guarantees optimality without trusting an arbitrary heuristic.
-}
aStar :: Graph -> (Int -> Double) -> Int -> Int -> Either MathError (Maybe (Double, [Int]))
aStar g heuristic source target = do
    checkVertex g source
    checkVertex g target
    nonnegative g
    mapM_ (\e -> checkedSum (edgeWeight e) (heuristic (edgeTo e)) >> pure ()) (arcs g)
    let hs = [heuristic v | v <- [0 .. vertexCount g - 1]]
    if any (not . finite) hs
        || heuristic target /= 0
        || any
            ( \e ->
                heuristic (edgeFrom e)
                    > edgeWeight e + heuristic (edgeTo e) + 1e-12 * max 1 (abs (heuristic (edgeFrom e)))
            )
            (arcs g)
        then Left (InvalidArgument "A* heuristic must be finite and consistent")
        else go S.empty (M.singleton source (0, [source]))
  where
    go closed known = do
        candidates <-
            mapM
                (\(v, (d, path)) -> do priority <- checkedSum d (heuristic v); pure (priority, d, path, v))
                [(v, p) | (v, p) <- M.toList known, S.notMember v closed]
        case candidates of
            [] -> Right Nothing
            _ -> do
                let (_, d, path, v) = minimum candidates
                if v == target
                    then Right (Just (d, path))
                    else do
                        next <-
                            foldM
                                (\m (u, w, _) -> do candidate <- checkedSum d w; pure (M.insertWith min u (candidate, path ++ [u]) m))
                                known
                                (neighbors g v)
                        go (S.insert v closed) next

{- | Two settled-frontier Dijkstra searches, alternating the frontier with the
smaller minimum key. The best meeting bound stops the search safely.
-}
bidirectionalDijkstra :: Graph -> Int -> Int -> Either MathError (Maybe Double)
bidirectionalDijkstra g source target = do
    checkVertex g source
    checkVertex g target
    nonnegative g
    go (M.singleton source 0) (M.singleton target 0) S.empty S.empty Nothing
  where
    reverseNeighbors v = [(edgeFrom e, edgeWeight e) | e <- arcs g, edgeTo e == v]
    minimumOpen dist closed = case [(d, v) | (v, d) <- M.toList dist, S.notMember v closed] of
        [] -> Nothing
        xs -> Just (minimum xs)
    go forward backward sf sb best = case (minimumOpen forward sf, minimumOpen backward sb) of
        (Nothing, _) -> Right best
        (_, Nothing) -> Right best
        (Just (a, u), Just (b, v)) -> do
            lowerBound <- checkedSum a b
            if maybe False (<= lowerBound) best
                then Right best
                else
                    if a <= b
                        then expand True u a forward backward sf sb best
                        else expand False v b backward forward sb sf best
    expand front v d own other settled opposite best = do
        let links = if front then [(u, w) | (u, w, _) <- neighbors g v] else reverseNeighbors v
        next <-
            foldM (\m (u, w) -> do candidate <- checkedSum d w; pure (M.insertWith min u candidate m)) own links
        meetings <-
            mapM (uncurry checkedSum) [(x, y) | (u, x) <- M.toList next, Just y <- [M.lookup u other]]
        let updated = foldl' (\old x -> Just (maybe x (min x) old)) best meetings
        if front
            then go next other (S.insert v settled) opposite updated
            else go other next opposite (S.insert v settled) updated

{- | K cheapest simple vertex paths, best-first expansion, for nonnegative
weights. Parallel edges generate distinct edge paths; output includes edge
IDs to preserve this identity. Fuel counts expanded partial paths.
-}
kShortestPaths :: Int -> Int -> Graph -> Int -> Int -> Either MathError [(Double, [Int], [Int])]
kShortestPaths fuel count g source target = do
    checkVertex g source
    checkVertex g target
    nonnegative g
    if fuel < 0 || count < 0
        then Left (InvalidArgument "negative path count/budget")
        else go fuel [(0, [source], [])] []
  where
    go _ _ out | length out >= count = Right out
    go _ [] out = Right out
    go b _ _ | b <= 0 = Left (NonConvergence "K shortest simple paths" fuel)
    go b queue out = case sortOn id queue of
        [] -> Right out
        ((cost, path, ids) : rest) ->
            let v = last path
             in if not (finite cost)
                    then Left NonFiniteResult
                    else
                        if v == target
                            then go (b - 1) rest (out ++ [(cost, path, ids)])
                            else do
                                added <-
                                    mapM
                                        (\(u, w, i) -> do candidate <- checkedSum cost w; pure (candidate, path ++ [u], ids ++ [i]))
                                        [(u, w, i) | (u, w, i) <- neighbors g v, u `notElem` path]
                                go (b - 1) (rest ++ added) out

longestDAGPaths :: Graph -> Int -> Either MathError [Maybe Double]
longestDAGPaths g source = do
    checkVertex g source
    order <- topologicalSort g
    result <-
        foldM
            ( \m v -> case M.lookup v m of
                Nothing -> Right m
                Just d ->
                    foldM
                        (\z (u, w, _) -> do candidate <- checkedSum d w; pure (M.insertWith max u candidate z))
                        m
                        (neighbors g v)
            )
            (M.singleton source 0)
            order
    finish g result
