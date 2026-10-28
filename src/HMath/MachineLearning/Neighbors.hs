-- SPDX-License-Identifier: MPL-2.0

{- | Exact branch-and-bound KD/ball trees and budgeted approximate search.
IDs always refer to original training rows. Neighbors sort by distance then
ID. LSH is Euclidean p-stable Gaussian projection hashing (Datar et al. 2004).
Isolation forest follows Liu et al. ICDM 2008, with seeded subsampling and the
harmonic-number correction for unsplit leaves. Larger anomaly scores indicate
more isolated observations. One-class SVM returns positive inlier decisions.
-}
module HMath.MachineLearning.Neighbors (
    IndexKind (..),
    SpatialIndex,
    buildIndex,
    NeighborResult (..),
    nearestNeighbors,
    knnRegress,
    knnClassify,
    LSH,
    buildLSH,
    queryLSH,
    localOutlierFactor,
    IsolationForest,
    fitIsolationForest,
    scoreIsolationForest,
    OneClassSVM,
    fitOneClassSVM,
    decisionOneClassSVM,
) where

import Control.Monad (foldM)
import Data.List (nub, sort, sortOn)
import Data.Word (Word64)
import HMath.Error
import HMath.MachineLearning.Internal
import HMath.MachineLearning.Regression (Kernel, kernel)
import qualified HMath.Random as R

-- | Axis-aligned KD partitions or enclosing Euclidean ball partitions.
data IndexKind = KDTree | BallTree deriving (Eq, Show)

data Tree = Leaf [(Int, [Double])] | KDNode Int Double Tree Tree | BallNode [Double] Double Tree Tree
    deriving (Eq, Show)

-- | Immutable tree retaining original observation IDs and its validated feature dimension.
data SpatialIndex = SpatialIndex Int Int Tree deriving (Eq, Show)

-- | Build an exact search tree with at most leafSize observations per leaf.
buildIndex :: IndexKind -> Int -> Dataset -> Either MathError SpatialIndex
buildIndex kind leafSize xs = do
    (n, d) <- dataset xs
    require (leafSize > 0) "tree leaf size must be positive"
    let build points
            | length points <= leafSize = Leaf points
            | otherwise = case kind of
                KDTree ->
                    let spans = [maximum col - minimum col | col <- transposeLocal (map snd points)]
                        axis = argmax spans
                        ordered = sortOn (\(_, r) -> r !! axis) points
                        middle = length points `div` 2
                        cutoff = snd (ordered !! middle) !! axis
                     in KDNode axis cutoff (build (take middle ordered)) (build (drop middle ordered))
                BallTree ->
                    let center' = meanV (map snd points)
                        radius = maximum [sqrt (dist2 center' p) | (_, p) <- points]
                        pivot = snd (points !! argmax [dist2 center' p | (_, p) <- points])
                        ordered = sortOn (\(_, p) -> dist2 pivot p) points
                        middle = length points `div` 2
                     in BallNode center' radius (build (take middle ordered)) (build (drop middle ordered))
    let tree = build (zip [0 ..] xs)
        validate (Leaf _) = Right ()
        validate (KDNode _ cutoff left right) = checked [cutoff] >> validate left >> validate right
        validate (BallNode center' radius left right) = checked (radius : center') >> validate left >> validate right
    validate tree
    Right (SpatialIndex d n tree)
  where
    transposeLocal [] = []
    transposeLocal rows' = let d = length (firstRow rows') in [[r !! j | r <- rows'] | j <- [0 .. d - 1]]

{- | Neighbor indices/distances plus visited-leaf and exhaustive-search diagnostics.
Budget-limited candidates are explicitly marked approximate.
-}
data NeighborResult = NeighborResult
    { neighbors :: [(Int, Double)]
    -- ^ Training-row indices paired with returned Euclidean distances, ordered by distance and then index.
    , visitedLeaves :: Int
    -- ^ Number of leaves visited against the explicit query budget.
    , exhaustive :: Bool
    -- ^ True if the neighbor search completed its exact stopping condition; False if unexplored nodes may improve candidates.
    }
    deriving (Eq, Show)

{- | maxLeaves is a query work budget. A False exhaustive flag means unexplored
nodes might improve the result. Even approximate results have exact distances.
-}
nearestNeighbors :: Int -> Int -> SpatialIndex -> [Double] -> Either MathError NeighborResult
nearestNeighbors k maxLeaves (SpatialIndex dimension count tree) point = do
    queries dimension [point]
    require (k > 0 && k <= count && maxLeaves > 0) "invalid neighbor count/leaf budget"
    let trim = take k . sortOn (\(i, d) -> (d, i))
        bound best = if length best < k then 1 / 0 else snd (last best)
        search node best used
            | used >= maxLeaves = (best, used, False)
            | otherwise = case node of
                Leaf pts -> (trim (best ++ [(i, sqrt (dist2 point p)) | (i, p) <- pts]), used + 1, True)
                BallNode center' radius left right
                    | sqrt (dist2 point center') - radius > bound best -> (best, used, True)
                    | otherwise ->
                        let (a, u, e1) = search left best used; (b, v, e2) = search right a u in (b, v, e1 && e2)
                KDNode axis cutoff left right ->
                    let (near, far) = if point !! axis < cutoff then (left, right) else (right, left)
                        (a, u, e1) = search near best used
                     in if abs (point !! axis - cutoff) > bound a
                            then (a, u, e1)
                            else
                                let (b, v, e2) = search far a u in (b, v, e1 && e2)
        (answer, leafCount, complete) = search tree [] 0
    checked (map snd answer)
    Right (NeighborResult answer leafCount complete)

-- | Average the k exact nearest training responses for each query row.
knnRegress :: Int -> SpatialIndex -> [Double] -> Dataset -> Either MathError [Double]
knnRegress k index@(SpatialIndex _ n _) targets xs = do
    require (length targets == n) "KNN response count mismatch"
    checked targets
    traverse
        ( \x -> do
            r <- nearestNeighbors k maxBound index x
            Right (sum [targets !! i | (i, _) <- neighbors r] / fromIntegral k)
        )
        xs

-- | Majority vote among k exact neighbors; targets follow original training row order.
knnClassify :: Int -> SpatialIndex -> [Int] -> Dataset -> Either MathError [Int]
knnClassify k index@(SpatialIndex _ n _) targets xs = do
    require (length targets == n) "KNN label count mismatch"
    traverse
        ( \x -> do
            r <- nearestNeighbors k maxBound index x
            let labels = [targets !! i | (i, _) <- neighbors r]
                classes = sort (nub labels)
                counts = [length (filter (== c) labels) | c <- classes]
            Right (classes !! argmax counts)
        )
        xs

-- | Seeded p-stable Euclidean hash tables retaining Gaussian projections and offset buckets.
data LSH = LSH Dataset Double [[([Double], Double)]] [[([Integer], Int)]] deriving (Eq, Show)

-- | Build tables with projections scalar hashes each and positive bucket width. Storage budget is explicit.
buildLSH :: Word64 -> Int -> Int -> Double -> Dataset -> Either MathError LSH
buildLSH seed tables projections width xs = do
    (_, d) <- dataset xs
    require
        ( tables > 0
            && tables <= 10000
            && projections > 0
            && projections <= 10000
            && finite width
            && width > 0
        )
        "invalid LSH dimensions/width"
    require
        (toInteger tables * toInteger projections * toInteger d <= 10000000)
        "LSH projection budget exceeded"
    let generate r _ = do
            (direction, r') <- R.sampleN d (R.normal 0 1) r
            let (u, r'') = R.uniform r'
            Right (r'', (direction, u * width))
    (_, flat) <-
        foldM
            (\(r, acc) i -> do (next, value) <- generate r i; Right (next, acc ++ [value]))
            (R.seedRNG R.PCG32 seed, [])
            [1 .. tables * projections]
    let planes = [take projections (drop (i * projections) flat) | i <- [0 .. tables - 1]]
    checked [(dot direction row + offset) / width | ps <- planes, (direction, offset) <- ps, row <- xs]
    let signature ps row = [floor ((dot direction row + offset) / width) | (direction, offset) <- ps]
        buckets = [[(signature ps row, i) | (i, row) <- zip [0 ..] xs] | ps <- planes]
    Right (LSH xs width planes buckets)

-- | Rank matching-bucket candidates by exact distance; may return fewer than k results, including none.
queryLSH :: Int -> LSH -> [Double] -> Either MathError [(Int, Double)]
queryLSH k (LSH xs width planes buckets) point = do
    queries (length (firstRow xs)) [point]
    require (k > 0 && k <= length xs) "invalid LSH requested neighbor count"
    checked [(dot direction point + offset) / width | ps <- planes, (direction, offset) <- ps]
    let signature ps = [floor ((dot direction point + offset) / width) | (direction, offset) <- ps]
        candidates = nub [i | (ps, bucket) <- zip planes buckets, (key, i) <- bucket, key == signature ps]
        answer = take k (sortOn (\(i, d) -> (d, i)) [(i, sqrt (dist2 point (xs !! i))) | i <- candidates])
    checked (map snd answer)
    Right answer

{- | Training-set LOF with ties included at the kth neighbor distance. Identical
neighborhoods have LOF 1, including the infinite-density 0/0 limiting case.
-}
localOutlierFactor :: Int -> Dataset -> Either MathError [Double]
localOutlierFactor k xs = do
    (n, _) <- dataset xs
    require (k > 0 && k < n) "LOF k must exclude the point itself"
    let distances = [[sqrt (dist2 x y) | y <- xs] | x <- xs]
        kth = [sort [distances !! i !! j | j <- [0 .. n - 1], i /= j] !! (k - 1) | i <- [0 .. n - 1]]
        near i = [j | j <- [0 .. n - 1], i /= j, distances !! i !! j <= kth !! i]
        reach i = sum [max (kth !! j) (distances !! i !! j) | j <- near i] / fromIntegral (length (near i))
        density = map reach [0 .. n - 1]
        ratio a b | a == 0 && b == 0 = 1 | b == 0 = 1 / 0 | otherwise = a / b
        scores =
            [ sum [ratio (density !! i) (density !! j) | j <- near i] / fromIntegral (length (near i))
            | i <- [0 .. n - 1]
            ]
    checked scores
    Right scores

data IsolationTree = IsolationLeaf Int | IsolationNode Int Double IsolationTree IsolationTree
    deriving (Eq, Show)

-- | Owned random isolation trees with fixed training dimension and subsample size.
data IsolationForest = IsolationForest Int Int [IsolationTree] deriving (Eq, Show)

-- | Seeded independent isolation trees using subsamples of 2..2048 observations.
fitIsolationForest :: Word64 -> Int -> Int -> Dataset -> Either MathError IsolationForest
fitIsolationForest seed treeCount sampleCount xs = do
    (n, d) <- dataset xs
    require
        (treeCount > 0 && treeCount <= 10000 && sampleCount >= 2 && sampleCount <= min 2048 n)
        "invalid isolation forest tree/subsample budget"
    let maxDepth = ceiling (logBase 2 (fromIntegral sampleCount) :: Double)
        grow depth rows' rng
            | length rows' <= 1 || depth >= maxDepth = Right (IsolationLeaf (length rows'), rng)
            | otherwise = do
                let dimensions = [j | j <- [0 .. d - 1], maximum (map (!! j) rows') > minimum (map (!! j) rows')]
                if null dimensions
                    then Right (IsolationLeaf (length rows'), rng)
                    else do
                        (choice, next) <- R.uniformInt 0 (length dimensions - 1) rng
                        let axis = dimensions !! choice
                            lo = minimum (map (!! axis) rows')
                            hi = maximum (map (!! axis) rows')
                            (u, next') = R.uniformOpen next
                            cutoff = lo + (hi - lo) * u
                        require (finite cutoff && cutoff > lo && cutoff < hi) "isolation split not representable"
                        (left, leftR) <- grow (depth + 1) (filter (\r -> r !! axis < cutoff) rows') next'
                        (right, rightR) <- grow (depth + 1) (filter (\r -> r !! axis >= cutoff) rows') leftR
                        Right (IsolationNode axis cutoff left right, rightR)
        one (rng, trees) _ = do
            (shuffled, next) <- R.shuffle xs rng
            (tree, next') <- grow (0 :: Int) (take sampleCount shuffled) next
            Right (next', tree : trees)
    (_, trees) <- foldM one (R.seedRNG R.PCG32 seed, []) [1 .. treeCount]
    Right (IsolationForest d sampleCount trees)

-- | Return 2^(-mean corrected path length / expected random-tree path length); larger means more anomalous.
scoreIsolationForest :: IsolationForest -> Dataset -> Either MathError [Double]
scoreIsolationForest (IsolationForest d sampleCount trees) xs = do
    queries d xs
    let correction n
            | n <= 1 = 0
            | otherwise =
                2 * sum [1 / fromIntegral j | j <- [1 .. n - 1]] - 2 * fromIntegral (n - 1) / fromIntegral n
        path depth (IsolationLeaf size) _ = fromIntegral depth + correction size
        path depth (IsolationNode axis cutoff left right) point = path (depth + 1) (if point !! axis < cutoff then left else right) point
        answer =
            [ 2
                ** ( negate (sum [path (0 :: Int) t x | t <- trees] / fromIntegral (length trees))
                        / correction sampleCount
                   )
            | x <- xs
            ]
    checked answer
    Right answer

-- | Kernel novelty detector with normalized nonnegative dual weights and learned offset.
data OneClassSVM = OneClassSVM Kernel Dataset [Double] Double deriving (Eq, Show)

{- | nu-SVM dual coordinate descent: sum alpha=1, 0<=alpha<=1/(nu*n).
The reported gap is the pairwise box-constrained KKT violation.
-}
fitOneClassSVM :: MLConfig -> Kernel -> Double -> Dataset -> Either MathError (Fit OneClassSVM)
fitOneClassSVM c kind nu xs = do
    config c
    (n, _) <- dataset xs
    require (nu > 0 && nu <= 1 && finite nu) "one-class SVM nu must lie in (0,1]"
    gram <- traverse (\x -> traverse (kernel kind x) xs) xs
    let cap = 1 / (nu * fromIntegral n)
        initial = replicate n (1 / fromIntegral n)
        go iteration alpha = do
            let gradient = map (`dot` alpha) gram
                canIncrease = [i | i <- [0 .. n - 1], alpha !! i < cap - 1e-14]
                canDecrease = [i | i <- [0 .. n - 1], alpha !! i > 1e-14]
                free = [gradient !! i | i <- [0 .. n - 1], alpha !! i > 1e-10 && alpha !! i < cap - 1e-10]
                rho =
                    if not (null free)
                        then sum free / fromIntegral (length free)
                        else
                            let lower = if null canDecrease then minimum gradient else maximum [gradient !! i | i <- canDecrease]
                                upper = if null canIncrease then maximum gradient else minimum [gradient !! i | i <- canIncrease]
                             in (lower + upper) / 2
                result residual conv = Right (Fit (OneClassSVM kind xs alpha rho) iteration residual conv)
            if null canIncrease || null canDecrease
                then result 0 True
                else do
                    let i = canIncrease !! argmin [gradient !! q | q <- canIncrease]
                        j = canDecrease !! argmax [gradient !! q | q <- canDecrease]
                        gap = max 0 (gradient !! j - gradient !! i)
                    if gap <= mlTolerance c || iteration >= mlIterations c
                        then result gap (gap <= mlTolerance c)
                        else do
                            let curvature = gram !! i !! i + gram !! j !! j - 2 * gram !! i !! j
                                room = min (cap - alpha !! i) (alpha !! j)
                                delta = if curvature <= 1e-14 then room else min room (gap / curvature)
                                next = replace i (alpha !! i + delta) (replace j (alpha !! j - delta) alpha)
                            checked next
                            go (iteration + 1) next
    go 0 initial

-- | Return signed novelty margins: positive indicates an inlier under the fitted kernel boundary.
decisionOneClassSVM :: OneClassSVM -> Dataset -> Either MathError [Double]
decisionOneClassSVM (OneClassSVM kind train alpha rho) xs = do
    queries (length (firstRow train)) xs
    traverse
        ( \x -> do
            values <- traverse (kernel kind x) train
            let value = dot alpha values - rho
            checked [value]
            Right value
        )
        xs
