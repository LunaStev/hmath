-- SPDX-License-Identifier: MPL-2.0

{- | Dense decomposition and manifold reference algorithms. PCA signs and
degenerate eigenspaces are not unique. t-SNE implements exact all-pairs
Student-t KL gradients (van der Maaten & Hinton, JMLR 2008); UMAP uses the
fuzzy union and full cross-entropy gradient (McInnes et al., arXiv:1802.03426)
with caller-supplied positive a,b curve parameters. Neither is a Barnes-Hut,
ANN, or stochastic negative-sampling implementation. Budgets are explicit.
-}
module HMath.MachineLearning.Decomposition (
    PCA,
    pcaMean,
    pcaComponents,
    pcaVariances,
    fitPCA,
    transformPCA,
    inversePCA,
    IncrementalPCA,
    incrementalPCA,
    updatePCA,
    mergePCA,
    finishPCA,
    KernelPCA,
    fitKernelPCA,
    transformKernelPCA,
    truncatedSVD,
    ICA,
    fitICA,
    transformICA,
    FactorAnalysis,
    factorLoadings,
    factorNoise,
    fitFactorAnalysis,
    CCA,
    fitCCA,
    transformCCA,
    canonicalCorrelations,
    PLS,
    fitPLS,
    predictPLS,
    randomProjection,
    classicalMDS,
    isomap,
    tsne,
    umap,
) where

import Control.Monad (foldM)
import Data.List (sortOn, transpose)
import HMath.Error
import HMath.MachineLearning.Internal
import HMath.MachineLearning.Regression (Kernel, kernel)
import qualified HMath.Matrix.LAPACK as L
import qualified HMath.Random as R

data PCA = PCA {pcaMean :: [Double], pcaComponents :: Dataset, pcaVariances :: [Double]}
    deriving (Eq, Show)

-- | Fit count principal axes from at least two observations; uses sample covariance (denominator n-1).
fitPCA :: Int -> Dataset -> Either MathError PCA
fitPCA count xs = do
    (n, d) <- dataset xs
    require (n >= 2 && count >= 1 && count <= d) "PCA requires n>=2 and 1<=components<=features"
    let mu = meanV xs
        centered = map (`sub` mu) xs
        cov = map (scale (1 / fromIntegral (n - 1))) (matmul (transpose centered) centered)
    pcaFromCov count mu cov

pcaFromCov :: Int -> [Double] -> Dataset -> Either MathError PCA
pcaFromCov count mu cov = do
    (vals, vs) <- symmetricEigen cov
    let components = take count (transpose vs); variance = take count vals
    require (all (>= -1e-8) variance) "PCA covariance is not positive semidefinite"
    Right (PCA mu components (map (max 0) variance))

-- | Center with the training mean and project onto retained axes; no whitening is applied.
transformPCA :: PCA -> Dataset -> Either MathError Dataset
transformPCA (PCA mu components _) xs = do
    queries (length mu) xs
    let out = [map (`dot` sub r mu) components | r <- xs]
    checked (concat out)
    Right out

-- | Reconstruct original features from retained scores and restore the training mean.
inversePCA :: PCA -> Dataset -> Either MathError Dataset
inversePCA (PCA mu components _) xs = do
    queries (length components) xs
    let out = map (\r -> add mu (map (dot r) (transpose components))) xs
    checked (concat out)
    Right out

{- | Exact sufficient statistics, including between-batch mean correction.
Sample count, running mean, and centered scatter sufficient statistics.
-}
data IncrementalPCA = IPCA Int [Double] Dataset deriving (Eq, Show)

-- | Create empty running covariance state for a positive feature dimension.
incrementalPCA :: Int -> Either MathError IncrementalPCA
incrementalPCA d = do
    require (d > 0 && d < 100000) "invalid incremental PCA dimension"
    Right (IPCA 0 (replicate d 0) (replicate d (replicate d 0)))

-- | Merge observations by Welford updates. Empty batches preserve the previous state.
updatePCA :: IncrementalPCA -> Dataset -> Either MathError IncrementalPCA
updatePCA old@(IPCA _ mu _) xs = do
    queries (length mu) xs
    foldM update old xs
  where
    update (IPCA n m s) x = do
        require (n < maxBound) "incremental PCA sample count overflow"
        let delta = sub x m
            m' = add m (scale (1 / fromIntegral (n + 1)) delta)
            delta' = sub x m'
            s' = [[s !! i !! j + delta !! i * delta' !! j | j <- [0 .. length m - 1]] | i <- [0 .. length m - 1]]
        checked (m' ++ concat s')
        Right (IPCA (n + 1) m' s')

-- | Combine independent batch statistics with the between-mean scatter correction.
mergePCA :: IncrementalPCA -> IncrementalPCA -> Either MathError IncrementalPCA
mergePCA a@(IPCA n ma sa) b@(IPCA m mb sb) = do
    require (length ma == length mb) "incremental PCA feature mismatch"
    require (toInteger n + toInteger m <= toInteger (maxBound :: Int)) "incremental PCA count overflow"
    if n == 0
        then Right b
        else
            if m == 0
                then Right a
                else do
                    let total = n + m
                        delta = sub mb ma
                        mu = add ma (scale (fromIntegral m / fromIntegral total) delta)
                        s =
                            [ [ sa !! i !! j
                                    + sb !! i !! j
                                    + delta !! i * delta !! j * (fromIntegral n * fromIntegral m / fromIntegral total)
                              | j <- [0 .. length ma - 1]
                              ]
                            | i <- [0 .. length ma - 1]
                            ]
                    checked (mu ++ concat s)
                    Right (IPCA total mu s)

-- | Extract principal axes from accumulated sample covariance; requires at least two observations.
finishPCA :: Int -> IncrementalPCA -> Either MathError PCA
finishPCA count (IPCA n mu scatter) = do
    require
        (n >= 2 && count > 0 && count <= length mu)
        "insufficient incremental PCA samples/components"
    pcaFromCov count mu (map (scale (1 / fromIntegral (n - 1))) scatter)

-- | Centered training kernel state and normalized positive eigenvectors.
data KernelPCA = KPCA Kernel Dataset [Double] Double Dataset deriving (Eq, Show)

-- | Fit kernel principal axes; count must be smaller than n and within positive numerical rank.
fitKernelPCA :: Int -> Kernel -> Dataset -> Either MathError KernelPCA
fitKernelPCA count kind xs = do
    (n, _) <- dataset xs
    require (count > 0 && count < n) "kernel PCA needs fewer components than samples"
    gram <- traverse (\x -> traverse (kernel kind x) xs) xs
    let means = map (\r -> sum r / fromIntegral n) gram
        overall = sum means / fromIntegral n
        centered = [[gram !! i !! j - means !! i - means !! j + overall | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
    (vals, vectors) <- symmetricEigen centered
    require (all (> 1e-12) (take count vals)) "kernel PCA requested null component"
    let coefficients' = [[vectors !! i !! j / sqrt (vals !! j) | j <- [0 .. count - 1]] | i <- [0 .. n - 1]]
    Right (KPCA kind xs means overall coefficients')

-- | Center query kernels with training means before projection, without fitting query statistics.
transformKernelPCA :: KernelPCA -> Dataset -> Either MathError Dataset
transformKernelPCA (KPCA kind train means overall weights) xs = do
    queries (length (firstRow train)) xs
    traverse
        ( \x -> do
            k <- traverse (kernel kind x) train
            let average = sum k / fromIntegral (length k)
                centered = zipWith (\v m -> v - average - m + overall) k means
            let result = map (dot centered) (transpose weights)
            checked result
            Right result
        )
        xs

-- | Return reduced (U, singular values, V-transpose) from LAPACK, keeping the largest count values.
truncatedSVD :: Int -> Dataset -> Either MathError (Dataset, [Double], Dataset)
truncatedSVD count xs = do
    (n, d) <- dataset xs
    require (count > 0 && count <= min n d) "invalid truncated SVD count"
    m <- matrix xs
    s <- L.svd m
    Right
        (map (take count) (rows (L.svdU s)), take count (L.singularValues s), take count (rows (L.svdVT s)))

-- | Training center and whitened unmixing directions; component signs/permutations are arbitrary.
data ICA = ICA [Double] Dataset deriving (Eq, Show)

{- | Symmetric FastICA with tanh nonlinearity (Hyvarinen 1999), whitening by
sample covariance. Convergence accounts for independent component signs.
-}
fitICA :: MLConfig -> Int -> Dataset -> Either MathError (Fit ICA)
fitICA c count xs = do
    config c
    p <- fitPCA count xs
    require (all (> 1e-12) (pcaVariances p)) "ICA whitening requires full component rank"
    z0 <- transformPCA p xs
    let scales = map (1 /) . map sqrt $ pcaVariances p
        z = map (zipWith (*) scales) z0
        n = fromIntegral (length xs)
        decorrelate w = do
            (vals, vs) <- symmetricEigen (matmul w (transpose w))
            require (all (> 1e-14) vals) "FastICA unmixing lost rank"
            let invroot = matmul (map (\r -> zipWith (\a v -> a / sqrt v) r vals) vs) (transpose vs)
            Right (matmul invroot w)
        step w = do
            let one row =
                    let projected = map (`dot` row) z
                        g = map tanh projected
                        gp = sum [1 - v * v | v <- g] / n
                     in sub (scale (1 / n) (foldl1 add (zipWith scale g z))) (scale gp row)
            decorrelate (map one w)
    startRaw <- normalMatrix (mlSeed c) count count
    start <- decorrelate startRaw
    fit <- iterateFit c step (\a b -> maximum [abs (abs (dot x y) - 1) | (x, y) <- zip a b]) start
    let whitening = zipWith scale scales (pcaComponents p)
    Right fit{fitted = ICA (pcaMean p) (matmul (fitted fit) whitening)}

-- | Apply the fitted centering and unmixing directions to new observations.
transformICA :: ICA -> Dataset -> Either MathError Dataset
transformICA (ICA mu unmixing) xs = do
    queries (length mu) xs
    let answer = [map (`dot` sub x mu) unmixing | x <- xs]
    checked (concat answer)
    Right answer

normalMatrix :: (Integral s) => s -> Int -> Int -> Either MathError Dataset
normalMatrix seed n d = do
    (values, _) <- R.sampleN (n * d) (R.normal 0 1) (R.seedRNG R.PCG32 (fromIntegral seed))
    Right [take d (drop (i * d) values) | i <- [0 .. n - 1]]

data FactorAnalysis = FA {factorCenter :: [Double], factorLoadings :: Dataset, factorNoise :: [Double]}
    deriving (Eq, Show)

{- | Gaussian factor-analysis EM with diagonal noise floor. Unlike PCA, each
observed feature has its own learned residual variance.
-}
fitFactorAnalysis :: MLConfig -> Int -> Double -> Dataset -> Either MathError (Fit FactorAnalysis)
fitFactorAnalysis c count floorNoise xs = do
    config c
    (n, d) <- dataset xs
    require
        (n >= 2 && count > 0 && count < d && finite floorNoise && floorNoise > 0)
        "invalid factor-analysis rank/noise floor"
    p <- fitPCA count xs
    let mu = pcaMean p
        centered = map (`sub` mu) xs
        covariance = map (scale (1 / fromIntegral n)) (matmul (transpose centered) centered)
        noise = replicate d floorNoise
        loading =
            transpose (zipWith (\v r -> scale (sqrt (max floorNoise v)) r) (pcaVariances p) (pcaComponents p))
        step (FA _ load psi) = do
            let weighted = zipWith (\r v -> scale (1 / v) r) load psi
                information = zipWith add (ident count) (matmul (transpose load) weighted)
            invInfo <- inverse information
            let beta = matmul invInfo (transpose weighted)
                sxz = matmul covariance (transpose beta)
                szz = zipWith add invInfo (matmul beta sxz)
            invZZ <- inverse szz
            let newLoad = matmul sxz invZZ
                newNoise = [max floorNoise (covariance !! j !! j - dot (newLoad !! j) (sxz !! j)) | j <- [0 .. d - 1]]
            checked (concat newLoad ++ newNoise)
            Right (FA mu newLoad newNoise)
    iterateFit
        c
        step
        ( \a b ->
            norm (concat (zipWith sub (factorLoadings a) (factorLoadings b)))
                + norm (sub (factorNoise a) (factorNoise b))
        )
        (FA mu loading noise)

-- | Paired training centers, canonical directions, and regularized canonical correlations.
data CCA = CCA [Double] [Double] Dataset Dataset [Double] deriving (Eq, Show)

-- | Singular values of the whitened cross-covariance, in descending order.
canonicalCorrelations :: CCA -> [Double]
canonicalCorrelations (CCA _ _ _ _ correlations) = correlations

invsqrt :: Dataset -> Either MathError Dataset
invsqrt cov = do
    (vals, vs) <- symmetricEigen cov
    require (all (> 1e-14) vals) "positive covariance required"
    Right (matmul (map (\r -> zipWith (\a v -> a / sqrt v) r vals) vs) (transpose vs))

-- | Fit paired canonical directions with a strictly positive diagonal covariance ridge.
fitCCA :: Int -> Double -> Dataset -> Dataset -> Either MathError CCA
fitCCA count ridge xs ys = do
    (n, dx) <- dataset xs
    (ny, dy) <- dataset ys
    require
        (n == ny && n >= 2 && count > 0 && count <= min dx dy && finite ridge && ridge > 0)
        "invalid CCA shape/rank/ridge"
    let mx = meanV xs
        my = meanV ys
        x = map (`sub` mx) xs
        y = map (`sub` my) ys
        covariance a b = map (scale (1 / fromIntegral (n - 1))) (matmul (transpose a) b)
        regularize z =
            [[z !! i !! j + if i == j then ridge else 0 | j <- [0 .. length z - 1]] | i <- [0 .. length z - 1]]
    wx <- invsqrt (regularize (covariance x x))
    wy <- invsqrt (regularize (covariance y y))
    let whitened = matmul (matmul wx (covariance x y)) wy
    (u, s, vt) <- truncatedSVD count whitened
    Right (CCA mx my (matmul wx u) (matmul wy (transpose vt)) s)

-- | Project paired query rows with fitted training centers and canonical directions.
transformCCA :: CCA -> Dataset -> Dataset -> Either MathError (Dataset, Dataset)
transformCCA (CCA mx my wx wy _) xs ys = do
    queries (length mx) xs
    queries (length my) ys
    require (length xs == length ys) "CCA paired sample mismatch"
    let a = matmul (map (`sub` mx) xs) wx; b = matmul (map (`sub` my) ys) wy
    checked (concat a ++ concat b)
    Right (a, b)

-- | PLS2 regression state with predictor/response centers and a feature-by-response coefficient matrix.
data PLS = PLS [Double] [Double] Dataset deriving (Eq, Show)

{- | PLS2 NIPALS with regression deflation; count cannot exceed the predictor
rank. Inner fixed-point iteration obeys the supplied convergence budget.
-}
fitPLS :: MLConfig -> Int -> Dataset -> Dataset -> Either MathError (Fit PLS)
fitPLS c count xs ys = do
    config c
    (n, dx) <- dataset xs
    (ny, dy) <- dataset ys
    require (n == ny && n >= 2 && count > 0 && count <= min (n - 1) dx) "invalid PLS shape/rank"
    let mx = meanV xs
        my = meanV ys
        centerX = map (`sub` mx) xs
        centerY = map (`sub` my) ys
        component (x, y, ws, ps, qs, total, res, converged) _ = do
            let start = maximumByNorm (transpose y)
                iteration u = do
                    let w0 = map (`dot` u) (transpose x); wn = norm w0
                    require (wn > 1e-14) "PLS predictor rank exhausted"
                    let w = scale (1 / wn) w0; t = map (`dot` w) x; q = map (`dot` t) (transpose y); u' = map (`dot` q) y
                    require (norm u' > 1e-14) "PLS response rank exhausted"
                    Right (scale (1 / norm u') u')
            inner <-
                iterateFit
                    c
                    iteration
                    (\a b -> min (norm (sub a b)) (norm (add a b)))
                    (scale (1 / max 1e-300 (norm start)) start)
            let u = fitted inner
                w0 = map (`dot` u) (transpose x)
                w = scale (1 / norm w0) w0
                t = map (`dot` w) x
                tt = dot t t
                p = scale (1 / tt) (map (`dot` t) (transpose x))
                q = scale (1 / tt) (map (`dot` t) (transpose y))
                x' = zipWith (\r z -> sub r (scale z p)) x t
                y' = zipWith (\r z -> sub r (scale z q)) y t
            checked (concat x' ++ concat y')
            Right
                ( x'
                , y'
                , ws ++ [w]
                , ps ++ [p]
                , qs ++ [q]
                , total + fitIterations inner
                , max res (fitResidual inner)
                , converged && fitConverged inner
                )
    (_, _, ws, ps, qs, it, res, conv) <-
        foldM component (centerX, centerY, [], [], [], 0, 0, True) [1 .. count]
    let w = transpose ws; p = transpose ps; q = transpose qs
    rotationInv <- inverse (matmul (transpose p) w)
    let b = matmul (matmul w rotationInv) (transpose q)
    require (length b == dx && all ((== dy) . length) b) "PLS coefficient shape"
    checked (concat b)
    Right (Fit (PLS mx my b) it res conv)
  where
    maximumByNorm cols = cols !! argmax (map norm cols)

-- | Predict response rows using fitted PLS coefficients and training centers.
predictPLS :: PLS -> Dataset -> Either MathError Dataset
predictPLS (PLS mx my b) xs = do
    queries (length mx) xs
    let answer = map (add my) (matmul (map (`sub` mx) xs) b)
    checked (concat answer)
    Right answer

-- | Seeded Gaussian projection with variance 1/dimension per coefficient. Returns transformed rows.
randomProjection :: MLConfig -> Int -> Dataset -> Either MathError Dataset
randomProjection c dimension xs = do
    config c
    (_, d) <- dataset xs
    require (dimension > 0 && dimension <= 10000) "invalid random-projection dimension"
    projection <- normalMatrix (mlSeed c) d dimension
    let out = matmul xs (map (scale (1 / sqrt (fromIntegral dimension))) projection)
    checked (concat out)
    Right out

{- | Classical metric MDS. Negative eigenvalues are omitted; requesting a
dimension beyond positive rank fails instead of creating imaginary axes.
-}
classicalMDS :: Int -> Dataset -> Either MathError Dataset
classicalMDS dimension distances = do
    (n, d) <- dataset distances
    require
        (n == d && dimension > 0 && dimension < n && all (>= 0) (concat distances))
        "invalid MDS distance matrix"
    require
        ( and
            [ abs (distances !! i !! j - distances !! j !! i) < 1e-10 && abs (distances !! i !! i) < 1e-10
            | i <- [0 .. n - 1]
            , j <- [0 .. n - 1]
            ]
        )
        "MDS distances must be symmetric with zero diagonal"
    let squares = map (map (^ (2 :: Int))) distances
        means = map (\r -> sum r / fromIntegral n) squares
        grand = sum means / fromIntegral n
        gram =
            [ [-0.5 * (squares !! i !! j - means !! i - means !! j + grand) | j <- [0 .. n - 1]]
            | i <- [0 .. n - 1]
            ]
    (vals, vs) <- symmetricEigen gram
    require (all (> 1e-12) (take dimension vals)) "MDS positive rank insufficient"
    Right [[vs !! i !! j * sqrt (vals !! j) | j <- [0 .. dimension - 1]] | i <- [0 .. n - 1]]

-- | Build a symmetric k-neighbor graph, compute geodesics, then metric MDS. Disconnected graphs fail.
isomap :: Int -> Int -> Dataset -> Either MathError Dataset
isomap neighbors dimension xs = do
    (n, _) <- dataset xs
    require (neighbors > 0 && neighbors < n) "Isomap neighbor count invalid"
    let ds = [[sqrt (dist2 x y) | y <- xs] | x <- xs]
        knn i = take neighbors (map snd (sortOn fst [(ds !! i !! j, j) | j <- [0 .. n - 1], j /= i]))
        graph =
            [ [ if i == j then 0 else if j `elem` knn i || i `elem` knn j then ds !! i !! j else 1 / 0
              | j <- [0 .. n - 1]
              ]
            | i <- [0 .. n - 1]
            ]
        shortest =
            foldl
                (\a k -> [[min (a !! i !! j) (a !! i !! k + a !! k !! j) | j <- [0 .. n - 1]] | i <- [0 .. n - 1]])
                graph
                [0 .. n - 1]
    require (all finite (concat shortest)) "Isomap neighborhood graph disconnected"
    classicalMDS dimension shortest

embeddingStart :: MLConfig -> Int -> Int -> Either MathError Dataset
embeddingStart c n dimension = map (map (1e-4 *)) <$> normalMatrix (mlSeed c) n dimension
center :: Dataset -> Dataset
center x = let mu = meanV x in map (`sub` mu) x

-- | Exact all-pairs t-SNE; perplexity must be strictly between one and n.
tsne :: MLConfig -> Int -> Double -> Dataset -> Either MathError (Fit Dataset)
tsne c dimension perplexity xs = do
    config c
    (n, _) <- dataset xs
    require
        ( dimension > 0
            && dimension <= 10
            && perplexity > 1
            && perplexity < fromIntegral n
            && finite perplexity
        )
        "invalid t-SNE dimension/perplexity"
    let squared = [[dist2 x y | y <- xs] | x <- xs]
        conditional i =
            let distances = [squared !! i !! j | j <- [0 .. n - 1], j /= i]
                minimumD = minimum distances
                search k beta lo hi =
                    let ex = map (\d -> exp (-beta * (d - minimumD))) distances
                        total = sum ex
                        probs = map (/ total) ex
                        entropy = negate (sum [prob * log prob | prob <- probs, prob > 0])
                        diff = entropy - log perplexity
                        next =
                            if diff > 0
                                then maybe (beta * 2) (\h -> (beta + h) / 2) hi
                                else maybe (beta / 2) (\l -> (beta + l) / 2) lo
                     in if k > 100 || abs diff < 1e-8
                            then probs
                            else if diff > 0 then search (k + 1) next (Just beta) hi else search (k + 1) next lo (Just beta)
                probabilities = search (0 :: Int) 1 Nothing Nothing
             in take i probabilities ++ [0] ++ drop i probabilities
        conditionals = map conditional [0 .. n - 1]
        p =
            [ [(conditionals !! i !! j + conditionals !! j !! i) / (2 * fromIntegral n) | j <- [0 .. n - 1]]
            | i <- [0 .. n - 1]
            ]
        step ys = do
            let numerator =
                    [ [if i == j then 0 else 1 / (1 + dist2 (ys !! i) (ys !! j)) | j <- [0 .. n - 1]] | i <- [0 .. n - 1]
                    ]
                total = sum (concat numerator)
                grad =
                    [ foldl1
                        add
                        [ scale
                            (4 * (p !! i !! j - numerator !! i !! j / total) * numerator !! i !! j)
                            (sub (ys !! i) (ys !! j))
                        | j <- [0 .. n - 1]
                        ]
                    | i <- [0 .. n - 1]
                    ]
                next = center (zipWith (\y g -> sub y (scale (mlRate c) g)) ys grad)
            checked (concat next)
            Right next
    start <- embeddingStart c n dimension
    iterateFit c step (\a b -> norm (concat (zipWith sub a b))) start

{- | Exact full fuzzy-set cross entropy, caller supplies fitted curve a,b.
Local connectivity rho is the first positive neighbor distance. This dense
reference resolves every repulsive pair instead of sampling negatives.
-}
umap :: MLConfig -> Int -> Int -> Double -> Double -> Dataset -> Either MathError (Fit Dataset)
umap c neighbors dimension a b xs = do
    config c
    (n, _) <- dataset xs
    require
        ( neighbors >= 2
            && neighbors < n
            && dimension > 0
            && dimension <= 10
            && all (\v -> finite v && v > 0) [a, b]
        )
        "invalid UMAP configuration"
    let distances = [[sqrt (dist2 x y) | y <- xs] | x <- xs]
        nearest i = take neighbors (sortOn fst [(distances !! i !! j, j) | j <- [0 .. n - 1], j /= i])
        memberships i =
            let near = nearest i
                positive = filter (> 0) (map fst near)
                rho = if null positive then 0 else minimum positive
                target = logBase 2 (fromIntegral neighbors)
                value bandwidth = sum [exp (-max 0 (d - rho) / bandwidth) | (d, _) <- near]
                search k lo hi =
                    let mid = (lo + hi) / 2
                     in if k > 80 then mid else if value mid > target then search (k + 1) lo mid else search (k + 1) mid hi
                sigma = search (0 :: Int) 1e-12 (max 1 (sum (map fst near) * 100))
             in [ case lookup j [(index, exp (-max 0 (d - rho) / sigma)) | (d, index) <- near] of
                    Just v -> v
                    Nothing -> 0
                | j <- [0 .. n - 1]
                ]
        directed = map memberships [0 .. n - 1]
        p =
            [ [let u = directed !! i !! j; v = directed !! j !! i in u + v - u * v | j <- [0 .. n - 1]]
            | i <- [0 .. n - 1]
            ]
        step ys = do
            let grad =
                    [ foldl1
                        add
                        [ if i == j
                            then replicate dimension 0
                            else
                                let delta = sub (ys !! i) (ys !! j); r2 = max 1e-8 (dot delta delta); q = 1 / (1 + a * r2 ** b)
                                 in map (\v -> max (-4) (min 4 v)) (scale (2 * b * (p !! i !! j - q) / r2) delta)
                        | j <- [0 .. n - 1]
                        ]
                    | i <- [0 .. n - 1]
                    ]
                next = center (zipWith (\y g -> sub y (scale (mlRate c) g)) ys grad)
            checked (concat next)
            Right next
    start <- embeddingStart c n dimension
    iterateFit c step (\u v -> norm (concat (zipWith sub u v))) start
