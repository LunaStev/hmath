-- SPDX-License-Identifier: MPL-2.0
-- Fixed independent SVC/LOF/CCA numeric fixtures use scikit-learn/SciPy;
-- only numeric values, not their implementation code, are reproduced.
module MachineLearningBatchSpec (machineLearningBatchTests) where

import Data.List (nub, sort)
import HMath.MachineLearning

machineLearningBatchTests :: [(String, Bool)]
machineLearningBatchTests =
    [ test "OLS exact affine coefficients" $ do
        f <- fitLinear opts Ordinary x y
        pure (vectorClose 1e-10 [2, 3] (coefficients (fitted f)) && fitConverged f)
    , test "polynomial regression recovers quadratic" $ do
        design <- polynomialFeatures 2 [-2, -1, 0, 1, 2]
        f <- fitLinear opts Ordinary design [9, 2, 1, 6, 17]
        pure (vectorClose 1e-10 [1, 2, 3] (coefficients (fitted f)))
    , test "ridge shrinks slope and keeps intercept unpenalized" $ do
        f <- fitLinear opts (Ridge 2) x y
        pure (vectorClose 1e-9 [2, 1.5] (coefficients (fitted f)))
    , test "lasso soft threshold has analytic orthogonal solution" $ do
        f <- fitLinear opts (Lasso 2) x y
        pure (vectorClose 1e-8 [2, 2] (coefficients (fitted f)) && fitConverged f)
    , test "elastic net combines L1 and L2" $ do
        f <- fitLinear opts (ElasticNet 2 2) x y
        pure (vectorClose 1e-8 [2, 1] (coefficients (fitted f)))
    , test "weighted LS ignores zero-weight outlier" $ do
        model <- fitWeighted [[0], [1], [2], [3]] [1, 3, 5, 100] [1, 1, 1, 0]
        pure (vectorClose 1e-9 [1, 2] (coefficients model))
    , test "Huber IRLS resists a response outlier" $ do
        f <- fitRobust opts 0.1 (map (: []) [0 .. 9]) ([1, 3 .. 17] ++ [1000])
        pure (abs (coefficients (fitted f) !! 1 - 2) < 0.03)
    , test "Bayesian linear posterior analytic one observation" $ do
        model <- fitBayesian 1 1 [[0]] [2]
        pure
            ( vectorClose 1e-10 [1, 0] (coefficients (bayesianMean model))
                && matrixClose 1e-10 [[0.5, 0], [0, 1]] (bayesianCovariance model)
            )
    , test "recursive LS agrees with vanishing prior batch limit" $ do
        start <- recursiveLS 1 1e9 1
        final <- foldE (\s (r, v) -> updateRecursiveLS s r v) start (zip x y)
        pure (vectorClose 1e-7 [2, 3] (recursiveCoefficients final))
    , test "logistic GLM reduces training classification error" $ do
        f <- fitGLM opts BinomialLogit 0.01 [[-2], [-1], [1], [2]] [0, 0, 1, 1]
        p <- predictGLM (fitted f) [[-2], [2]]
        pure (p !! 0 < 0.1 && p !! 1 > 0.9 && fitConverged f)
    , test "Poisson GLM recovers log-linear means" $ do
        f <- fitGLM opts PoissonLog 0 x (map (\r -> exp (0.2 + 0.3 * r !! 0)) x)
        p <- predictGLM (fitted f) [[0], [1]]
        pure (vectorClose 1e-7 [exp 0.2, exp 0.5] p)
    , test "multinomial regression predicts three separated classes" $ do
        f <-
            fitMultinomial
                opts{mlIterations = 1000, mlRate = 0.1}
                0.001
                [[-2, 0], [-1, 0], [1, 0], [2, 0], [0, 2], [0, 3]]
                [0, 0, 1, 1, 2, 2]
        p <- predictMultinomial (fitted f) [[-2, 0], [2, 0], [0, 3]]
        pure
            (map (fst . maximumByProbability) p == [0, 1, 2] && all (\r -> close 1e-12 1 (sum (map snd r))) p)
    , test "linear SMO SVM separates signed classes" $ do
        f <- fitSVM opts LinearKernel 10 [[-2], [-1], [1], [2]] [-1, -1, 1, 1]
        predicted <- predictSVM (fitted f) [[-3], [3]]
        pure (predicted == [-1, 1] && fitConverged f)
    , test "RBF SMO SVM learns XOR" $ do
        f <-
            fitSVM opts{mlIterations = 2000} (RBFKernel 1) 10 [[0, 0], [0, 1], [1, 0], [1, 1]] [-1, 1, 1, -1]
        p <- predictSVM (fitted f) [[0, 0], [0, 1], [1, 0], [1, 1]]
        pure (p == [-1, 1, 1, -1])
    , test "kernel Gram scalar references" $ do
        a <- kernel LinearKernel [1, 2] [3, 4]
        b <- kernel (PolynomialKernel 2 1 1) [1, 2] [3, 4]
        c <- kernel (RBFKernel 0.5) [0, 0] [1, 1]
        pure (a == 11 && b == 144 && close 1e-14 (exp (-1)) c)
    , test "GP posterior single-point mean and variance" $ do
        model <- fitGaussianProcess (RBFKernel 1) 1 [[0]] [2]
        p <- predictGaussianProcess model [[0]]
        pure (pairClose 1e-10 (1, 0.5) (p !! 0))
    , test "GP classifier Laplace probabilities distinguish clusters" $ do
        f <- fitGPClassifier opts (RBFKernel 0.5) [[-2], [-1], [1], [2]] [0, 0, 1, 1]
        p <- predictGPClassifier (fitted f) [[-2], [2]]
        pure (p !! 0 < 0.5 && p !! 1 > 0.5 && all (\v -> v > 0 && v < 1) p)
    , test "Gaussian naive Bayes regularizes constant features" $ do
        model <- fitNaiveBayes GaussianBayes 1e-6 [[0, 1], [0.1, 1], [10, 1], [10.1, 1]] [4, 4, 9, 9]
        p <- predictNaiveBayes model [[0.05, 1], [10.05, 1]]
        pure (p == [4, 9])
    , test "multinomial and Bernoulli Bayes classes" $ do
        a <- fitNaiveBayes MultinomialBayes 1 [[4, 0], [3, 1], [0, 4], [1, 3]] [0, 0, 1, 1]
        b <- fitNaiveBayes BernoulliBayes 1 [[1, 0], [1, 0], [0, 1], [0, 1]] [0, 0, 1, 1]
        pa <- predictNaiveBayes a [[5, 0], [0, 5]]
        pb <- predictNaiveBayes b [[1, 0], [0, 1]]
        pure (pa == [0, 1] && pb == [0, 1])
    , test "LDA and QDA discriminate class means" $ do
        models <-
            traverse
                (\q -> fitDiscriminant q 0.01 [[0, 0], [0.1, 0.1], [5, 5], [5.1, 5.2]] [2, 2, 7, 7])
                [False, True]
        p <- traverse (\m -> predictDiscriminant m [[0, 0], [5, 5]]) models
        pure (all (== [2, 7]) p)
    , test "PCA variance and reconstruction are analytic" $ do
        model <- fitPCA 1 line
        z <- transformPCA model line
        reconstructed <- inversePCA model z
        pure (vectorClose 1e-10 [10 / 3] (pcaVariances model) && matrixClose 1e-10 line reconstructed)
    , test "incremental PCA merge matches batch covariance" $ do
        start <- incrementalPCA 2
        a <- updatePCA start (take 2 line)
        b <- updatePCA start (drop 2 line)
        combined <- mergePCA a b
        model <- finishPCA 1 combined
        pure (vectorClose 1e-10 [0, 0] (pcaMean model) && vectorClose 1e-10 [10 / 3] (pcaVariances model))
    , test "linear kernel PCA preserves centered distances" $ do
        model <- fitKernelPCA 1 LinearKernel line
        z <- transformKernelPCA model line
        pure (close 1e-9 4 (abs (z !! 0 !! 0 - z !! 3 !! 0)))
    , test "truncated SVD reconstructs rank-one observations" $ do
        (u, s, vt) <- truncatedSVD 1 [[1, 2], [2, 4], [3, 6]]
        pure (matrixClose 1e-10 [[1, 2], [2, 4], [3, 6]] (refMatmul (map (refScale (s !! 0)) u) vt))
    , test "FastICA whitens separated non-Gaussian components" $ do
        let mixed = [[a + 2 * b, 2 * a - b] | a <- [-2, -1, 0, 1, 2], b <- [-1, 1]]
        f <- fitICA opts{mlIterations = 1000} 2 mixed
        z <- transformICA (fitted f) mixed
        let mu = refMeanV z; c = refMatmul (transpose' (map (`refSub` mu) z)) (map (`refSub` mu) z)
        pure (abs (c !! 0 !! 1) < 1e-6 && close 1e-6 9 (c !! 0 !! 0) && close 1e-6 9 (c !! 1 !! 1))
    , test "factor-analysis EM returns positive feature noise" $ do
        f <-
            fitFactorAnalysis
                opts{mlIterations = 30}
                1
                1e-4
                [[a, a + 0.01 * b, 2 * a - 0.01 * b] | a <- [-2, -1, 0, 1, 2], b <- [-1, 1]]
        pure (all (>= 1e-4) (factorNoise (fitted f)) && length (factorLoadings (fitted f)) == 3)
    , test "CCA identifies perfect canonical correlation" $ do
        model <- fitCCA 1 1e-9 x (map (\r -> [2 * r !! 0]) x)
        (a, b) <- transformCCA model x (map (\r -> [2 * r !! 0]) x)
        pure
            ( close 1e-8 1 (canonicalCorrelations model !! 0)
                && all (\(u, v) -> abs (u !! 0 - v !! 0) < 1e-7) (zip a b)
            )
    , test "PLS2 predicts two linear response columns" $ do
        f <- fitPLS opts 1 x (map (\r -> [1 + 2 * r !! 0, 3 - r !! 0]) x)
        predicted <- predictPLS (fitted f) [[3]]
        pure (matrixClose 1e-8 [[7, 0]] predicted)
    , test "random projection reproducibility and dimension" $ do
        a <- randomProjection opts 3 line
        b <- randomProjection opts 3 line
        pure (a == b && all ((== 3) . length) a)
    , test "classical MDS recovers line distances" $ do
        embedded <- classicalMDS 1 [[abs (a - b) | b <- [0, 1, 3]] | a <- [0, 1, 3]]
        pure (close 1e-9 3 (sqrt (refDist2 (embedded !! 0) (embedded !! 2))))
    , test "Isomap geodesic path agrees with line distance" $ do
        embedded <- isomap 2 1 [[0], [1], [2], [3]]
        pure (close 1e-9 3 (sqrt (refDist2 (embedded !! 0) (embedded !! 3))))
    , test "t-SNE finite exact gradient iteration and seed" $ do
        a <- tsne opts{mlIterations = 20, mlRate = 10} 2 2 clusters
        b <- tsne opts{mlIterations = 20, mlRate = 10} 2 2 clusters
        pure
            ( a == b
                && length (fitted a) == 6
                && all ((== 2) . length) (fitted a)
                && refNorm (concat (fitted a)) > 1e-4
            )
    , test "UMAP fuzzy full-gradient iteration is reproducible" $ do
        a <- umap opts{mlIterations = 20} 3 2 1.576943 0.895061 clusters
        b <- umap opts{mlIterations = 20} 3 2 1.576943 0.895061 clusters
        pure (a == b && all ((== 2) . length) (fitted a) && all refFinite (concat (fitted a)))
    , test "Lloyd and k-means++ find separate clusters" $ do
        fs <- traverse (\method -> method opts 2 clusters) [kMeans, kMeansPlusPlus]
        labels <- traverse (\f -> predictClusters (fitted f) clusters) fs
        pure (all (twoClusters 3) labels)
    , test "minibatch k-means online update remains reproducible" $ do
        a <- miniBatchKMeans opts{mlIterations = 100} 2 3 clusters
        b <- miniBatchKMeans opts{mlIterations = 100} 2 3 clusters
        pure (a == b && length (clusterCenters (fitted a)) == 2)
    , test "PAM medoids cover both separated groups" $ do
        f <- kMedoids opts 2 clusters
        pure (any (< 3) (fitted f) && any (>= 3) (fitted f) && length (nub (fitted f)) == 2)
    , test "full-covariance GMM EM separates and normalizes" $ do
        f <- fitGaussianMixture opts 2 0.001 clusters
        r <- mixtureResponsibilities (fitted f) clusters
        pure
            ( all (\v -> close 1e-10 1 (sum v)) r
                && twoClusters 3 (map refArgmax r)
                && close 1e-10 1 (sum (mixtureWeights (fitted f)))
            )
    , test "DBSCAN identifies density groups and distant noise" $ do
        p <- dbscan 0.3 2 (clusters ++ [[99]])
        pure (twoClusters 3 (take 6 p) && last p == -1)
    , test "OPTICS expansion and extraction agree with density clusters" $ do
        order <- optics 20 2 (clusters ++ [[99]])
        p <- extractOPTICS 0.3 order
        pure (sort (map (\(i, _, _) -> i) order) == [0 .. 6] && twoClusters 3 (take 6 p) && last p == -1)
    , test "Gaussian mean shift modes separate clusters" $ do
        f <- meanShift opts 0.5 clusters
        pure (length (clusterCenters (fitted f)) == 2)
    , test "all hierarchy linkage variants have valid cuts" $ do
        hierarchies <- traverse (\kind -> hierarchical kind clusters) [Single, Complete, Average, Ward]
        cuts <- traverse (cutHierarchy 6 2) hierarchies
        pure (all (twoClusters 3) cuts && all ((== 5) . length) hierarchies)
    , test "spectral clustering labels disconnected scales consistently" $ do
        f <- spectralClustering opts 2 0.1 clusters
        pure (twoClusters 3 (fitted f))
    , test "affinity propagation selects representative clusters" $ do
        f <- affinityPropagation opts (-1) 0.7 clusters
        pure (twoClusters 3 (fitted f) && fitConverged f)
    , test "KD and ball trees match brute-force nearest distances" $ do
        indexes <- traverse (\kind -> buildIndex kind 1 clusters) [KDTree, BallTree]
        results <- traverse (\idx -> nearestNeighbors 2 maxBound idx [0.12]) indexes
        pure
            ( all
                ( \r ->
                    map fst (neighbors r) == [1, 2]
                        && vectorClose 1e-10 [0.02, 0.08] (map snd (neighbors r))
                        && exhaustive r
                )
                results
            )
    , test "approximate tree search exposes exhausted work budget" $ do
        index <- buildIndex KDTree 1 clusters
        r <- nearestNeighbors 6 1 index [0]
        pure (not (exhaustive r) && visitedLeaves r == 1 && length (neighbors r) == 1)
    , test "KNN regression and majority classification" $ do
        idx <- buildIndex BallTree 2 clusters
        a <- knnRegress 3 idx [1, 2, 3, 7, 8, 9] [[0.1], [10.1]]
        b <- knnClassify 3 idx [0, 0, 0, 1, 1, 1] [[0.1], [10.1]]
        pure (vectorClose 1e-10 [2, 8] a && b == [0, 1])
    , test "LSH returns original row for exact self query reproducibly" $ do
        a <- buildLSH 42 4 3 1 clusters
        b <- buildLSH 42 4 3 1 clusters
        qa <- queryLSH 1 a [0.1]
        qb <- queryLSH 1 b [0.1]
        pure (qa == qb && qa == [(1, 0)])
    , test "LOF detects remote observation and handles identical rows" $ do
        a <- localOutlierFactor 2 (clusters ++ [[99]])
        b <- localOutlierFactor 2 (replicate 4 [1])
        pure (last a > 10 && b == replicate 4 1)
    , test "isolation forest ranks extreme outlier higher" $ do
        model <- fitIsolationForest 42 100 21 (map (: []) [0 .. 19] ++ [[1000]])
        scores <- scoreIsolationForest model [[10], [1000]]
        pure (scores !! 1 > scores !! 0 && all (\v -> v > 0 && v <= 1) scores)
    , test "one-class SVM separates far novelty" $ do
        f <- fitOneClassSVM opts{mlIterations = 2000} (RBFKernel 1) 0.5 [[-0.2], [-0.1], [0], [0.1], [0.2]]
        scores <- decisionOneClassSVM (fitted f) [[0], [99]]
        pure (scores !! 0 > scores !! 1 && scores !! 1 < 0 && fitResidual f < 1e-6)
    , test "all scalers inverse-transform including constant columns" $ do
        scalers <-
            traverse (\kind -> fitScaler kind [[0, 7], [1, 7], [2, 7]]) [Standardize, MinMax, RobustScale]
        results <- traverse (\s -> transform s [[0, 7], [2, 7]] >>= inverseTransform s) scalers
        pure (all (matrixClose 1e-12 [[0, 7], [2, 7]]) results)
    , test "training-only scaler does not absorb test statistics" $ do
        s <- fitScaler Standardize [[0], [2]]
        z <- transform s [[100]]
        pure (z == [[99]])
    , test "quantile transformer ties, extrapolation and inverse" $ do
        model <- fitQuantileTransformer [[0], [1], [1], [3]]
        z <- quantileTransform model [[-1], [1], [4]]
        inv <- inverseQuantileTransform model [[0], [1]]
        pure (matrixClose 1e-12 [[0], [0.5], [1]] z && inv == [[0], [3]])
    , test "Box-Cox and Yeo-Johnson inverse round trips" $ do
        let methods = [BoxCox 0, BoxCox 0.5, YeoJohnson 0, YeoJohnson 1, YeoJohnson 2]
        results <-
            traverse
                ( \method ->
                    let values = case method of BoxCox _ -> [[0.1], [1], [4]]; _ -> [[-3], [-1], [0], [2]]
                     in do
                            z <- powerTransform method values
                            v <- inversePowerTransform method z
                            pure (matrixClose 1e-10 values v)
                )
                methods
        pure (and results)
    , test "imputation learns training means/medians with NaN masks" $ do
        a <- fitImputer MeanImpute [[1, 0 / 0], [3, 4]]
        b <- fitImputer MedianImpute [[1], [4], [100]]
        ra <- impute a [[0 / 0, 0 / 0]]
        rb <- impute b [[0 / 0]]
        pure (ra == [[2, 4]] && rb == [[4]])
    , test "categorical encoding stable order and unknown policy" $ do
        encoder <- fitEncoder ["b", "a", "b"]
        labels <- labelEncode encoder ["b", "a"]
        categories <- labelDecode encoder labels
        hot <- oneHotEncode ZeroUnknown encoder ["b", "z"]
        pure
            ( labels == [1, 0]
                && categories == ["b", "a"]
                && hot == [[0, 1], [0, 0]]
                && failure (oneHotEncode RejectUnknown encoder ["z"])
            )
    , test "train/test partition and seed reproducibility" $ do
        a <- trainTestSplit 42 0.2 20
        b <- trainTestSplit 42 0.2 20
        pure
            ( a == b
                && disjoint a
                && sort (trainingIndices a ++ validationIndices a) == [0 .. 19]
                && length (validationIndices a) == 4
            )
    , test "K-fold partitions validation exactly once" $ do
        folds <- kFold 42 3 10
        pure (all disjoint folds && sort (concatMap validationIndices folds) == [0 .. 9])
    , test "stratified fold preserves class proportions" $ do
        folds <- stratifiedKFold 42 2 [0 :: Int, 0, 0, 0, 1, 1, 1, 1]
        pure (all (\f -> length (filter (< 4) (validationIndices f)) == 2 && disjoint f) folds)
    , test "grid/random search use only supplied folds" $ do
        folds <- kFold 42 2 6
        let loss p f = Right ((p - 2) ^ (2 :: Int) + fromIntegral (length (validationIndices f)) * 0)
        a <- gridSearch [0, 1, 2, 3 :: Double] folds loss
        b <- randomSearch 42 4 [0, 1, 2, 3 :: Double] folds loss
        pure (a == (2, 0) && b == (2, 0))
    ,
        ( "ML rejects nonfinite/ragged and response shapes"
        , failure (fitLinear opts Ordinary [[0 / 0]] [1])
            && failure (fitLinear opts Ordinary [[1], [1, 2]] [1, 2])
            && failure (fitLinear opts Ordinary [[1]] [1, 2])
        )
    ,
        ( "ML rejects invalid budgets and penalties"
        , failure (fitLinear opts{mlIterations = 0} Ordinary x y)
            && failure (fitLinear opts (Lasso (-1)) x y)
            && failure (fitGLM opts BinomialLogit 0 x y)
        )
    ,
        ( "ML query dimensions are checked"
        , failure (fitScaler Standardize [[1], [2]] >>= \s -> transform s [[1, 2]])
            && failure (buildIndex KDTree 1 clusters >>= \i -> nearestNeighbors 2 10 i [1, 2])
        )
    ,
        ( "ML PCA ranks/disconnected Isomap checked"
        , failure (fitPCA 3 line)
            && failure (fitKernelPCA 2 LinearKernel line)
            && failure (isomap 1 1 [[0], [1], [10], [11]])
        )
    ,
        ( "ML density/tree configuration checked"
        , failure (dbscan 0 2 clusters)
            && failure (optics 1 0 clusters)
            && failure (buildIndex KDTree 0 clusters)
            && failure (localOutlierFactor 6 clusters)
        )
    ,
        ( "ML missing/category/power failures checked"
        , failure (fitImputer MeanImpute [[0 / 0]])
            && failure (powerTransform (BoxCox 0) [[0]])
            && failure (inversePowerTransform (BoxCox 1) [[-2]])
        )
    ,
        ( "ML invalid search folds and kernel contracts checked"
        , failure (kFold 1 7 6)
            && failure (stratifiedKFold 1 2 [0 :: Int, 0, 1])
            && failure (kernel (RBFKernel (-1)) [0] [1])
        )
    , test "ML iteration exhaustion remains explicit in fit result" $ do
        f <- fitLinear opts{mlIterations = 1} (ElasticNet 0.1 0.1) [[0, 1], [1, 2], [2, 4]] [0, 1, 2]
        pure (fitIterations f == 1 && not (fitConverged f))
    , test "near-zero Box-Cox power avoids cancellation" $ do
        value <- powerTransform (BoxCox 1e-10) [[1.00000001]]
        restored <- inversePowerTransform (YeoJohnson 1e-10) [[1e-12]]
        pure (close 1e-20 (log 1.00000001) (value !! 0 !! 0) && close 1e-24 1e-12 (restored !! 0 !! 0))
    , test "empirical quantile interpolates huge opposite-sign endpoints" $ do
        model <- fitQuantileTransformer [[-1e308], [1e308]]
        q <- quantileTransform model [[0]]
        pure (q == [[0.5]])
    , test "imputation retains finite large-value means" $ do
        model <- fitImputer MeanImpute [[1e308], [1e308]]
        values <- impute model [[0 / 0]]
        pure (values == [[1e308]])
    ,
        ( "ML LSH rejects overflowing projections before integer conversion"
        , failure (buildLSH 42 10 10 1e-308 [[1e308]])
        )
    ,
        ( "ML CV rejects caller-supplied overlapping folds"
        , failure (gridSearch [1 :: Int] [Fold [0, 1] [1]] (\_ _ -> Right 0))
        )
    , ("ML density rejects unrepresentable pair distances", failure (dbscan 1e308 2 [[-1e308], [1e308]]))
    , test "PCA repeated eigenspaces remain orthonormal" $ do
        let a = sqrt 3.5
            samples = [[a, 0, 0], [-a, 0, 0], [0, a, 0], [0, -a, 0], [0, 0, a], [0, 0, -a], [a, a, a], [-a, -a, -a]]
        model <- fitPCA 3 samples
        scores <- transformPCA model samples
        restored <- inversePCA model scores
        let axes = pcaComponents model
        pure
            ( vectorClose 1e-10 [4, 1, 1] (pcaVariances model)
                && matrixClose 1e-10 [[1, 0, 0], [0, 1, 0], [0, 0, 1]] (refMatmul axes (transpose' axes))
                && matrixClose 1e-10 samples restored
            )
    , test "SMO zero-curvature duplicate pair reaches box optimum" $ do
        fit <- fitSVM opts LinearKernel 2 [[0], [0]] [-1, 1]
        margins <- decisionSVM (fitted fit) [[0]]
        pure (fitConverged fit && fitResidual fit < 1e-8 && vectorClose 1e-8 [0] margins)
    , test "SMO fallback pairs agree with independent nonlinear SVC fixture" $ do
        let points = [[-2, -1], [-1, 0], [-1, 2], [0, 0], [1, 1], [2, -1], [3, 1], [2, 3]]
        fit <-
            fitSVM
                opts{mlIterations = 2000, mlTolerance = 1e-9}
                (RBFKernel 0.4)
                2
                points
                [-1, -1, 1, -1, 1, -1, 1, 1]
        margins <- decisionSVM (fitted fit) points
        pure (fitConverged fit && vectorClose 1e-7 [-1, -1.021379029622831, 1, -1, 1, -1, 1, 1] margins)
    , test "LOF agrees with independent multivariate density fixture" $ do
        values <- localOutlierFactor 2 [[0, 0], [0.1, 0.2], [0.2, 0], [3, 3], [3.1, 3.2], [20, 10]]
        pure (vectorClose 1e-8 [1, 1, 1, 9.750355580669273, 9.750355580669273, 4.423803028671718] values)
    , test "CCA multivariate singular values match independent SciPy fixture" $ do
        model <-
            fitCCA
                2
                0.01
                [[-2, 1], [-1, -2], [0, 1], [1, 2], [2, 0], [3, -1]]
                [[1, 3], [2, 1], [0, 1], [-1, 2], [0, -2], [-2, 0]]
        pure (vectorClose 1e-10 [0.986048914141918, 0.5686258314218263] (canonicalCorrelations model))
    ,
        ( "ML CCA rejects unrepresentable query projection"
        , failure
            (fitCCA 1 1e-8 [[1e-4], [-1e-4]] [[1e-4], [-1e-4]] >>= \m -> transformCCA m [[1e308]] [[1e308]])
        )
    ,
        ( "ML kernel PCA rejects unrepresentable query projection"
        , failure
            ( fitKernelPCA 1 LinearKernel [[1e-4, 1e-4, 1e-4, 1e-4], [-1e-4, -1e-4, -1e-4, -1e-4]] >>= \m -> transformKernelPCA m [[1e308, 1e308, 1e308, 1e308]]
            )
        )
    ,
        ( "ML GP rejects overflowed posterior state"
        , failure (fitGaussianProcess LinearKernel 1e-8 [[0]] [1e308])
        )
    ]
  where
    opts = defaultMLConfig{mlTolerance = 1e-7}
    x = map (: []) [-2, -1, 0, 1, 2]
    y = [-4, -1, 2, 5, 8]
    line = [[-2, 0], [-1, 0], [1, 0], [2, 0]]
    clusters = map (: []) [0, 0.1, 0.2, 10, 10.1, 10.2]

test :: String -> Either e Bool -> (String, Bool)
test name value = ("ML " ++ name, either (const False) id value)
close :: Double -> Double -> Double -> Bool
close tolerance a b = refFinite b && abs (a - b) <= tolerance * max 1 (abs a)
vectorClose :: Double -> [Double] -> [Double] -> Bool
vectorClose t a b = length a == length b && and (zipWith (close t) a b)
matrixClose :: Double -> [[Double]] -> [[Double]] -> Bool
matrixClose t a b = length a == length b && and (zipWith (vectorClose t) a b)
pairClose :: Double -> (Double, Double) -> (Double, Double) -> Bool
pairClose t (a, b) (x, y) = close t a x && close t b y
failure :: Either e a -> Bool
failure = either (const True) (const False)
foldE :: (a -> b -> Either e a) -> a -> [b] -> Either e a
foldE _ z [] = Right z
foldE f z (a : as) = f z a >>= \next -> foldE f next as
transpose' :: [[a]] -> [[a]]
transpose' [] = []
transpose' xs = [[r !! j | r <- xs] | j <- [0 .. length (xs !! 0) - 1]]
twoClusters :: Int -> [Int] -> Bool
twoClusters n labels =
    length labels == 2 * n
        && length (nub (take n labels)) == 1
        && length (nub (drop n labels)) == 1
        && labels !! 0 /= labels !! n
maximumByProbability :: [(Int, Double)] -> (Int, Double)
maximumByProbability xs = foldl1 (\a b -> if snd a >= snd b then a else b) xs
disjoint :: Fold -> Bool
disjoint f = null [i | i <- trainingIndices f, i `elem` validationIndices f]

-- Small independent reference arithmetic for analytic fixtures; deliberately
-- does not import the package's hidden estimator kernels.
refFinite :: Double -> Bool
refFinite x = not (isNaN x || isInfinite x)
refScale :: Double -> [Double] -> [Double]
refScale x = map (x *)
refSub :: [Double] -> [Double] -> [Double]
refSub = zipWith (-)
refNorm :: [Double] -> Double
refNorm x = sqrt (sum (map (^ (2 :: Int)) x))
refMeanV :: [[Double]] -> [Double]
refMeanV x = map (\column -> sum column / fromIntegral (length column)) (transpose' x)
refMatmul :: [[Double]] -> [[Double]] -> [[Double]]
refMatmul a b = [[sum (zipWith (*) r c) | c <- transpose' b] | r <- a]
refDist2 :: [Double] -> [Double] -> Double
refDist2 a b = sum (zipWith (\x y -> (x - y) ^ (2 :: Int)) a b)
refArgmax :: [Double] -> Int
refArgmax x = snd (maximum (zip x [0 ..]))
