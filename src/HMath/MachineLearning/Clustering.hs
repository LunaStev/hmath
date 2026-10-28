-- SPDX-License-Identifier: MPL-2.0

{- | Dense, finite-budget clustering. Distances are Euclidean, labels zero
based; DBSCAN noise is -1. OPTICS preserves undefined reachability as Nothing.
Affinity propagation uses Frey & Dueck's responsibility/availability updates
(Science 2007, doi:10.1126/science.1136800), with explicit damping.
-}
module HMath.MachineLearning.Clustering (
    ClusterModel,
    clusterCenters,
    predictClusters,
    kMeans,
    kMeansPlusPlus,
    miniBatchKMeans,
    kMedoids,
    GaussianMixture,
    mixtureWeights,
    mixtureMeans,
    mixtureCovariances,
    fitGaussianMixture,
    mixtureResponsibilities,
    dbscan,
    optics,
    extractOPTICS,
    meanShift,
    Linkage (..),
    Merge (..),
    hierarchical,
    cutHierarchy,
    spectralClustering,
    affinityPropagation,
) where

import Control.Monad (foldM)
import Data.List (nub, sortOn, transpose)
import HMath.Error
import HMath.MachineLearning.Internal
import qualified HMath.Random as R

{- | Fitted cluster centroids as cluster-by-feature observations; prediction assigns new
queries to the learned centers.
-}
newtype ClusterModel = Clusters
    { clusterCenters :: Dataset
    -- ^ Cluster centroids as cluster-by-feature rows.
    }
    deriving (Eq, Show)

-- | Assign each row to its closest squared-Euclidean center; ties use the first center.
predictClusters :: ClusterModel -> Dataset -> Either MathError [Int]
predictClusters (Clusters centers) xs = do
    queries (length (firstRow centers)) xs
    let ds = [[dist2 x c | c <- centers] | x <- xs]
    checked (concat ds)
    Right (map argmin ds)

initialCenters :: Bool -> MLConfig -> Int -> Dataset -> Either MathError Dataset
initialCenters plus c k xs = do
    (n, _) <- dataset xs
    require (k > 0 && k <= n) "cluster count must be between one and sample count"
    let rng = R.seedRNG R.PCG32 (mlSeed c)
    if not plus
        then do
            (shuffled, _) <- R.shuffle xs rng
            Right (take k shuffled)
        else do
            (first, rng') <- R.uniformInt 0 (n - 1) rng
            let go chosen r
                    | length chosen == k = Right (map (xs !!) chosen)
                    | otherwise = do
                        let weights =
                                [if i `elem` chosen then 0 else minimum [dist2 x (xs !! j) | j <- chosen] | (i, x) <- zip [0 ..] xs]
                            total = sum weights
                        checked weights
                        let (u, r') = R.uniform r
                            remaining = [i | i <- [0 .. n - 1], i `notElem` chosen]
                            index =
                                if total <= 0
                                    then remaining !! 0
                                    else min (n - 1) (length (takeWhile (<= u * total) (drop 1 (scanl (+) 0 weights))))
                        go (chosen ++ [index]) r'
            go [first] rng'

-- | Seeded random-center Lloyd iteration; residual is total center displacement.
kMeans :: MLConfig -> Int -> Dataset -> Either MathError (Fit ClusterModel)
kMeans = lloyd False

-- | D-squared k-means++ initialization followed by Lloyd center updates.
kMeansPlusPlus :: MLConfig -> Int -> Dataset -> Either MathError (Fit ClusterModel)
kMeansPlusPlus = lloyd True

lloyd :: Bool -> MLConfig -> Int -> Dataset -> Either MathError (Fit ClusterModel)
lloyd plus c k xs = do
    config c
    start <- initialCenters plus c k xs
    let step centers = do
            labels <- predictClusters (Clusters centers) xs
            let assigned j = [x | (x, l) <- zip xs labels, l == j]
                -- Keep an empty center at its prior location. This is stable on
                -- duplicate points and preserves the caller's requested k.
                next = [if null (assigned j) then centers !! j else meanV (assigned j) | j <- [0 .. k - 1]]
            checked (concat next)
            Right next
    fit <- iterateFit c step (\a b -> norm (concat (zipWith sub a b))) start
    Right fit{fitted = Clusters (fitted fit)}

{- | Online center updates with per-cluster counts and seeded shuffled batches.
One outer iteration consumes batchSize observations, cycling shuffled data.
-}
miniBatchKMeans :: MLConfig -> Int -> Int -> Dataset -> Either MathError (Fit ClusterModel)
miniBatchKMeans c k batchSize xs = do
    config c
    require (batchSize > 0 && batchSize <= length xs) "invalid minibatch size"
    start <- initialCenters True c k xs
    let step (centers, counts, rng) = do
            (batch, rng') <- R.shuffle xs rng
            (next, newCounts) <-
                foldM
                    ( \(cs, ns) x -> do
                        let j = argmin (map (dist2 x) cs)
                            count = ns !! j + 1
                            value = add (cs !! j) (scale (1 / fromIntegral count) (sub x (cs !! j)))
                        checked value
                        Right (replace j value cs, replace j count ns)
                    )
                    (centers, counts)
                    (take batchSize batch)
            Right (next, newCounts, rng')
    fit <-
        iterateFit
            c
            step
            (\(a, _, _) (b, _, _) -> norm (concat (zipWith sub a b)))
            (start, replicate k (0 :: Int), R.seedRNG R.PCG32 (mlSeed c))
    let (centers, _, _) = fitted fit
    Right fit{fitted = Clusters centers}

-- | PAM exhaustive medoid swaps. Return original row indices; residual is the objective decrease.
kMedoids :: MLConfig -> Int -> Dataset -> Either MathError (Fit [Int])
kMedoids c k xs = do
    config c
    (n, _) <- dataset xs
    require (k > 0 && k <= n) "invalid medoid count"
    let distances = [[sqrt (dist2 x y) | y <- xs] | x <- xs]
        cost ids = sum [minimum [distances !! i !! j | j <- ids] | i <- [0 .. n - 1]]
        step ids = do
            let candidates = ids : [replace p j ids | p <- [0 .. k - 1], j <- [0 .. n - 1], j `notElem` ids]
                costs = map cost candidates
            checked costs
            Right (candidates !! argmin costs)
    iterateFit c step (\a b -> abs (cost a - cost b)) [0 .. k - 1]

{- | Fitted component probabilities,mean vectors,and covariance matrices in shared component
order.
-}
data GaussianMixture = GMM
    { mixtureWeights :: [Double]
    -- ^ Gaussian-mixture component probabilities in component order.
    , mixtureMeans :: Dataset
    -- ^ Component mean vectors, matching mixtureWeights order.
    , mixtureCovariances :: [Dataset]
    -- ^ One feature-by-feature covariance matrix per Gaussian component.
    }
    deriving (Eq, Show)

logsumexp :: [Double] -> Double
logsumexp xs = let m = maximum xs in m + log (sum (map (exp . subtract m) xs))

-- | Compute normalized posterior component probabilities with log-sum-exp stabilization.
mixtureResponsibilities :: GaussianMixture -> Dataset -> Either MathError Dataset
mixtureResponsibilities (GMM weights means covariances) xs = do
    let d = length (firstRow means)
    queries d xs
    inverses <- traverse inverse covariances
    eigenvalues <- traverse symmetricEigen covariances
    require (all (> 0) (concatMap fst eigenvalues)) "mixture covariance must be positive definite"
    let logdet = map (sum . map log . fst) eigenvalues
        logDensity row j =
            let delta = sub row (means !! j)
             in log (weights !! j)
                    - 0.5 * (fromIntegral d * log (2 * pi) + logdet !! j + dot delta (map (`dot` delta) (inverses !! j)))
        answer =
            [ let logs = [logDensity row j | j <- [0 .. length weights - 1]]; z = logsumexp logs
               in map (\v -> exp (v - z)) logs
            | row <- xs
            ]
    checked (concat answer)
    Right answer

-- | Full-covariance EM initialized by k-means++; positive ridge is added at each covariance update. Collapsed component mass fails.
fitGaussianMixture :: MLConfig -> Int -> Double -> Dataset -> Either MathError (Fit GaussianMixture)
fitGaussianMixture c k ridge xs = do
    config c
    (n, d) <- dataset xs
    require (finite ridge && ridge > 0) "mixture covariance ridge must be positive"
    initial <- kMeansPlusPlus c k xs
    let centers = clusterCenters (fitted initial)
        n' = fromIntegral n
        initialCov = map (scale (1 / n')) (matmul (transpose (map (`sub` meanV xs) xs)) (map (`sub` meanV xs) xs))
        regularize cov = [[cov !! i !! j + if i == j then ridge else 0 | j <- [0 .. d - 1]] | i <- [0 .. d - 1]]
        step model = do
            responsibilities <- mixtureResponsibilities model xs
            let totals = map sum (transpose responsibilities)
            require (all (> 1e-12) totals) "Gaussian mixture component collapsed"
            let means =
                    [ scale (1 / total) (foldl1 add (zipWith scale weights xs))
                    | (weights, total) <- zip (transpose responsibilities) totals
                    ]
                covariances =
                    [ regularize
                        [ [ sum
                                [ (responsibilities !! i !! j) * (xs !! i !! a - means !! j !! a) * (xs !! i !! b - means !! j !! b)
                                | i <- [0 .. n - 1]
                                ]
                                / (totals !! j)
                          | b <- [0 .. d - 1]
                          ]
                        | a <- [0 .. d - 1]
                        ]
                    | j <- [0 .. k - 1]
                    ]
            checked (concat means ++ concatMap concat covariances)
            Right (GMM (map (/ n') totals) means covariances)
        difference a b =
            norm (sub (mixtureWeights a) (mixtureWeights b))
                + norm (concat (zipWith sub (mixtureMeans a) (mixtureMeans b)))
                + norm (concatMap concat (zipWith (zipWith sub) (mixtureCovariances a) (mixtureCovariances b)))
    iterateFit
        c
        step
        difference
        (GMM (replicate k (1 / fromIntegral k)) centers (replicate k (regularize initialCov)))

-- | Density expansion using a positive Euclidean radius; minimumPoints includes the observation itself.
dbscan :: Double -> Int -> Dataset -> Either MathError [Int]
dbscan epsilon minimumPoints xs = do
    (n, _) <- dataset xs
    require
        (finite epsilon && epsilon > 0 && minimumPoints > 0 && minimumPoints <= n)
        "invalid DBSCAN parameters"
    let distances = [[norm (sub x y) | y <- xs] | x <- xs]
    checked (concat distances)
    let neighbors i = [j | j <- [0 .. n - 1], distances !! i !! j <= epsilon]
        expand _ [] visited labels = (visited, labels)
        expand label (j : todo) visited labels =
            let unseen = j `notElem` visited
                visited' = if unseen then j : visited else visited
                todo' = if unseen && length (neighbors j) >= minimumPoints then nub (todo ++ neighbors j) else todo
                labels' = if labels !! j < 0 then replace j label labels else labels
             in expand label todo' visited' labels'
        go i label visited labels
            | i == n = labels
            | i `elem` visited = go (i + 1) label visited labels
            | length (neighbors i) < minimumPoints = go (i + 1) label (i : visited) labels
            | otherwise =
                let (v, l) = expand label (neighbors i) (i : visited) (replace i label labels)
                 in go (i + 1) (label + 1) v l
    Right (go 0 0 [] (replicate n (-1)))

{- | OPTICS (Ankerst et al., SIGMOD 1999): ordered point index, core distance,
reachability distance. Undefined reachability starts each connected expansion.
-}
optics :: Double -> Int -> Dataset -> Either MathError [(Int, Maybe Double, Maybe Double)]
optics epsilon minimumPoints xs = do
    (n, _) <- dataset xs
    require
        (finite epsilon && epsilon > 0 && minimumPoints > 0 && minimumPoints <= n)
        "invalid OPTICS parameters"
    let distances = [[norm (sub x y) | y <- xs] | x <- xs]
    checked (concat distances)
    let near i = sortOn fst [(distances !! i !! j, j) | j <- [0 .. n - 1], distances !! i !! j <= epsilon]
        core i = if length (near i) >= minimumPoints then Just (fst (near i !! (minimumPoints - 1))) else Nothing
        visit i reached processed queue result =
            let processed' = i : processed
                update cd q (distance, j)
                    | j `elem` processed' = q
                    | otherwise =
                        let r = max cd distance
                         in case lookup j q of
                                Nothing -> (j, r) : q
                                Just old -> (j, min old r) : filter ((/= j) . fst) q
                queue' = case core i of
                    Nothing -> queue
                    Just cd -> foldl (update cd) queue (near i)
                result' = result ++ [(i, core i, reached)]
             in case sortOn snd queue' of
                    [] -> (processed', result')
                    (j, r) : rest -> visit j (Just r) processed' rest result'
        go i processed result
            | i >= n = result
            | i `elem` processed = go (i + 1) processed result
            | otherwise = let (p, r) = visit i Nothing processed [] result in go (i + 1) p r
    Right (go 0 [] [])

-- | Extract DBSCAN-style labels at epsilon from a checked OPTICS ordering; noise is -1.
extractOPTICS :: Double -> [(Int, Maybe Double, Maybe Double)] -> Either MathError [Int]
extractOPTICS epsilon ordered = do
    let n = length ordered
    require
        (finite epsilon && epsilon > 0 && sortOn id (map (\(i, _, _) -> i) ordered) == [0 .. n - 1])
        "invalid OPTICS ordering/threshold"
    require
        (all (\(_, c, r) -> all (\v -> finite v && v >= 0) (maybe [] (: []) c ++ maybe [] (: []) r)) ordered)
        "invalid OPTICS distances"
    let (_, assignments) =
            foldl
                ( \(cluster, labels) (i, cd, rd) ->
                    if maybe True (> epsilon) rd
                        then
                            if maybe False (<= epsilon) cd
                                then (cluster + 1, (i, cluster + 1) : labels)
                                else (cluster, (i, -1) : labels)
                        else (cluster, (i, cluster) : labels)
                )
                (-1, [])
                ordered
    Right [maybe (-1) id (lookup i assignments) | i <- [0 .. n - 1]]

-- | Gaussian-kernel mean shift from every training point; modes within bandwidth/2 are merged.
meanShift :: MLConfig -> Double -> Dataset -> Either MathError (Fit ClusterModel)
meanShift c bandwidth xs = do
    config c
    _ <- dataset xs
    require (finite bandwidth && bandwidth > 0) "mean-shift bandwidth must be positive"
    let step centers =
            traverse
                ( \mu -> do
                    let weights = map (\x -> exp (-dist2 x mu / (2 * bandwidth * bandwidth))) xs; total = sum weights
                    require (total > 0 && finite total) "mean-shift kernel mass vanished"
                    Right (scale (1 / total) (foldl1 add (zipWith scale weights xs)))
                )
                centers
    fit <- iterateFit c step (\a b -> norm (concat (zipWith sub a b))) xs
    let uniqueModes =
            foldl
                (\m x -> if any (\y -> dist2 x y <= bandwidth * bandwidth / 4) m then m else m ++ [x])
                []
                (fitted fit)
    Right fit{fitted = Clusters uniqueModes}

-- | Single, complete, average Euclidean distance or Ward variance-increase linkage.
data Linkage = Single | Complete | Average | Ward deriving (Eq, Show)

{- | One hierarchical-clustering merge, retaining child IDs,linkage distance,and merged
observation count.
-}
data Merge = Merge
    { leftCluster :: Int
    -- ^ Left child cluster ID in a hierarchical merge.
    , rightCluster :: Int
    -- ^ Right child cluster ID in a hierarchical merge.
    , mergeDistance :: Double
    -- ^ Linkage distance at which the two child clusters merge.
    , mergedSize :: Int
    -- ^ Number of original observations in the merged cluster.
    }
    deriving (Eq, Show)

-- | Agglomerate the closest active clusters to produce all n-1 linkage rows.
hierarchical :: Linkage -> Dataset -> Either MathError [Merge]
hierarchical method xs = do
    (n, _) <- dataset xs
    let distance as bs = case method of
            Single -> minimum ds
            Complete -> maximum ds
            Average -> sum ds / fromIntegral (length ds)
            Ward ->
                sqrt
                    ( 2
                        * fromIntegral (length as * length bs)
                        / fromIntegral (length as + length bs)
                        * dist2 (meanV (map (xs !!) as)) (meanV (map (xs !!) bs))
                    )
          where
            ds = [sqrt (dist2 (xs !! i) (xs !! j)) | i <- as, j <- bs]
        go _ [_] result = Right result
        go next clusters result = do
            let pairs = [(distance as bs, ca, cb, as ++ bs) | (ca, as) <- clusters, (cb, bs) <- clusters, ca < cb]
                (height, a, b, members) = sortOn (\(v, _, _, _) -> v) pairs !! 0
            checked [height]
            go
                (next + 1)
                ((next, members) : filter (\(j, _) -> j /= a && j /= b) clusters)
                (result ++ [Merge a b height (length members)])
    go n [(i, [i]) | i <- [0 .. n - 1]] []

-- | Validate the entire hierarchy and return k cluster labels in original observation order.
cutHierarchy :: Int -> Int -> [Merge] -> Either MathError [Int]
cutHierarchy n k merges = do
    require (n > 0 && k > 0 && k <= n && length merges == n - 1) "invalid hierarchy cut"
    let step clusters (j, Merge a b height size) = do
            require (a /= b && finite height && height >= 0) "invalid hierarchy merge"
            as <- maybe (Left (InvalidArgument "ML: unknown hierarchy cluster")) Right (lookup a clusters)
            bs <- maybe (Left (InvalidArgument "ML: unknown hierarchy cluster")) Right (lookup b clusters)
            require (size == length as + length bs) "invalid hierarchy size"
            Right ((n + j, as ++ bs) : filter (\(i, _) -> i /= a && i /= b) clusters)
    -- Validate the complete hierarchy, including merges after the requested cut.
    _ <- foldM step [(i, [i]) | i <- [0 .. n - 1]] (zip [0 ..] merges)
    clusters <- foldM step [(i, [i]) | i <- [0 .. n - 1]] (take (n - k) (zip [0 ..] merges))
    Right
        [ maybe
            (-1)
            id
            ( lookup
                i
                [(point, label) | (label, (_, members)) <- zip [0 ..] (sortOn fst clusters), point <- members]
            )
        | i <- [0 .. n - 1]
        ]

-- | Cluster row-normalized leading eigenvectors of the normalized Gaussian affinity matrix.
spectralClustering :: MLConfig -> Int -> Double -> Dataset -> Either MathError (Fit [Int])
spectralClustering c k gamma xs = do
    config c
    (n, _) <- dataset xs
    require (k > 0 && k < n && finite gamma && gamma > 0) "invalid spectral clustering parameters"
    let affinity =
            [ [if i == j then 0 else exp (-gamma * dist2 (xs !! i) (xs !! j)) | j <- [0 .. n - 1]]
            | i <- [0 .. n - 1]
            ]
        degrees = map sum affinity
    require (all (> 0) degrees) "spectral affinity graph has isolated vertices"
    (_, vectors) <-
        symmetricEigen
            [[affinity !! i !! j / sqrt (degrees !! i * degrees !! j) | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
    let embedding = [let r = take k v; s = norm r in if s == 0 then r else scale (1 / s) r | v <- vectors]
    fit <- kMeansPlusPlus c k embedding
    labels <- predictClusters (fitted fit) embedding
    Right fit{fitted = labels}

{- | The preference is the common diagonal similarity; damping is in [0.5,1).
Stops only after exemplar identities remain unchanged for ten iterations.
-}
affinityPropagation :: MLConfig -> Double -> Double -> Dataset -> Either MathError (Fit [Int])
affinityPropagation c preference damping xs = do
    config c
    (n, _) <- dataset xs
    require
        (n >= 2 && finite preference && finite damping && damping >= 0.5 && damping < 1)
        "invalid affinity propagation parameters"
    let similarity =
            [ [if i == j then preference else negate (dist2 (xs !! i) (xs !! j)) | j <- [0 .. n - 1]]
            | i <- [0 .. n - 1]
            ]
        mix old new = damping * old + (1 - damping) * new
        go iteration responsibilities availabilities previous stable = do
            let rs =
                    [ [ mix
                            (responsibilities !! i !! k)
                            ( similarity !! i !! k
                                - maximum [availabilities !! i !! j + similarity !! i !! j | j <- [0 .. n - 1], j /= k]
                            )
                      | k <- [0 .. n - 1]
                      ]
                    | i <- [0 .. n - 1]
                    ]
                av =
                    [ [ mix
                            (availabilities !! i !! k)
                            ( if i == k
                                then sum [max 0 (rs !! j !! k) | j <- [0 .. n - 1], j /= k]
                                else min 0 (rs !! k !! k + sum [max 0 (rs !! j !! k) | j <- [0 .. n - 1], j /= i, j /= k])
                            )
                      | k <- [0 .. n - 1]
                      ]
                    | i <- [0 .. n - 1]
                    ]
                exemplars = [k | k <- [0 .. n - 1], rs !! k !! k + av !! k !! k > 0]
                stable' = if exemplars == previous && not (null exemplars) then stable + 1 else 0
            checked (concat rs ++ concat av)
            if stable' >= 10 || iteration >= mlIterations c
                then do
                    require (not (null exemplars)) "affinity propagation found no exemplar within budget"
                    let labels = [argmax [similarity !! i !! j | j <- exemplars] | i <- [0 .. n - 1]]
                    Right (Fit labels iteration (fromIntegral (max 0 (10 - stable'))) (stable' >= 10))
                else go (iteration + 1) rs av exemplars stable'
    go 1 (replicate n (replicate n 0)) (replicate n (replicate n 0)) [] (0 :: Int)
