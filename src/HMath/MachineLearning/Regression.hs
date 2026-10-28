-- SPDX-License-Identifier: MPL-2.0

{- | Dense reference estimators. Every design includes an unpenalized intercept;
rows are observations. Fit diagnostics distinguish budget exhaustion from a
coefficient/residual convergence test. Gaussian-process classification uses
the logistic Laplace approximation, rather than exact Bayesian integration.
-}
module HMath.MachineLearning.Regression (
    Penalty (..),
    LinearModel,
    coefficients,
    fitLinear,
    predictLinear,
    polynomialFeatures,
    fitWeighted,
    fitRobust,
    BayesianLinear,
    fitBayesian,
    bayesianMean,
    bayesianCovariance,
    RecursiveLS,
    recursiveLS,
    updateRecursiveLS,
    recursiveCoefficients,
    GLMFamily (..),
    GLM,
    fitGLM,
    predictGLM,
    MultinomialModel,
    fitMultinomial,
    predictMultinomial,
    Kernel (..),
    kernel,
    SVM,
    fitSVM,
    decisionSVM,
    predictSVM,
    GaussianProcess,
    fitGaussianProcess,
    predictGaussianProcess,
    GPClassifier,
    fitGPClassifier,
    predictGPClassifier,
    BayesFamily (..),
    NaiveBayes,
    fitNaiveBayes,
    predictNaiveBayes,
    Discriminant,
    fitDiscriminant,
    predictDiscriminant,
) where

import Control.Monad (foldM)
import Data.List (nub, sort, sortOn, transpose)
import HMath.Error
import HMath.MachineLearning.Internal

-- | Minimize mean squared error divided by two plus L1 and/or squared L2 coefficient penalties.
data Penalty = Ordinary | Ridge Double | Lasso Double | ElasticNet Double Double deriving (Eq, Show)

-- | Affine predictor; coefficient zero is the intercept and remaining coefficients follow feature order.
newtype LinearModel = LinearModel [Double] deriving (Eq, Show)

-- | Intercept followed by slopes in input feature order.
coefficients :: LinearModel -> [Double]
coefficients (LinearModel b) = b

-- | Predict one finite response per query row using the fitted intercept and slopes.
predictLinear :: LinearModel -> Dataset -> Either MathError [Double]
predictLinear (LinearModel b) xs = do
    queries (length b - 1) xs
    let ys = map (dot b . (1 :)) xs
    checked ys
    Right ys

penalties :: Penalty -> Either MathError (Double, Double)
penalties p = do
    let (l1, l2) = case p of Ordinary -> (0, 0); Ridge x -> (0, x); Lasso x -> (x, 0); ElasticNet x y -> (x, y)
    require (all (\x -> finite x && x >= 0) [l1, l2]) "penalty must be finite and nonnegative"
    Right (l1, l2)

-- | Fit affine least squares or coordinate-descent elastic net. Ordinary/ridge use an SVD minimum-norm solve; iterative residual is coefficient displacement.
fitLinear :: MLConfig -> Penalty -> Dataset -> [Double] -> Either MathError (Fit LinearModel)
fitLinear c penalty xs ys = do
    config c
    (n, d) <- responses xs ys
    (l1, l2) <- penalties penalty
    let design = map (1 :) xs; cols = transpose design; nf = fromIntegral n
    if l1 == 0
        then do
            let augmented = design ++ [[if i == j then sqrt (nf * l2) else 0 | j <- [0 .. d]] | i <- [1 .. d], l2 > 0]
            b <- solveLS augmented (ys ++ replicate (if l2 > 0 then d else 0) 0)
            let residual =
                    norm
                        [ sum [design !! i !! j * (dot (design !! i) b - ys !! i) | i <- [0 .. n - 1]] / nf
                            + (if j == 0 then 0 else l2 * b !! j)
                        | j <- [0 .. d]
                        ]
            checked [residual]
            Right (Fit (LinearModel b) 1 residual (residual <= max 1e-8 (mlTolerance c)))
        else do
            let soft t z = signum z * max 0 (abs z - t)
                sweep b =
                    foldM
                        ( \old j -> do
                            let col = cols !! j
                                partial = zipWith (\r y -> y - dot r old + (r !! j) * (old !! j)) design ys
                                rho = dot col partial / nf
                                denominator = dot col col / nf + (if j == 0 then 0 else l2)
                                bnew = if denominator == 0 then 0 else (if j == 0 then rho else soft l1 rho) / denominator
                            checked [bnew]
                            Right (replace j bnew old)
                        )
                        b
                        [0 .. d]
            fit <- iterateFit c sweep (\a b -> norm (sub a b)) (replicate (d + 1) 0)
            Right fit{fitted = LinearModel (fitted fit)}

-- | Build univariate columns x, x^2, ..., x^degree; the regression intercept supplies the constant.
polynomialFeatures :: Int -> [Double] -> Either MathError Dataset
polynomialFeatures degree xs = do
    require (degree >= 1 && degree <= 10000) "polynomial degree must be in [1,10000]"
    checked xs
    let ys = [[x ^ j | j <- [1 .. degree]] | x <- xs]
    checked (concat ys)
    Right ys

-- | Fit affine least squares with nonnegative observation weights. Zero-weight rows contribute no error.
fitWeighted :: Dataset -> [Double] -> [Double] -> Either MathError LinearModel
fitWeighted xs ys weights = do
    (n, _) <- responses xs ys
    require
        (length weights == n && all (\w -> finite w && w >= 0) weights && any (> 0) weights)
        "invalid observation weights"
    b <-
        solveLS
            (zipWith (\w r -> scale (sqrt w) (1 : r)) weights xs)
            (zipWith (\w y -> sqrt w * y) weights ys)
    Right (LinearModel b)

-- | Huber IRLS with fixed positive residual threshold, including intercept.
fitRobust :: MLConfig -> Double -> Dataset -> [Double] -> Either MathError (Fit LinearModel)
fitRobust c delta xs ys = do
    config c
    require (finite delta && delta > 0) "Huber threshold must be positive"
    _ <- responses xs ys
    start <- fitWeighted xs ys (replicate (length ys) 1)
    iterateFit
        c
        ( \model -> do
            p <- predictLinear model xs
            fitWeighted xs ys [if abs r <= delta then 1 else delta / abs r | r <- sub ys p]
        )
        (\a b -> norm (sub (coefficients a) (coefficients b)))
        start

data BayesianLinear = BayesianLinear {bayesianMean :: LinearModel, bayesianCovariance :: Dataset}
    deriving (Eq, Show)

{- | Isotropic zero-mean Gaussian prior, observation precision beta. Unlike
frequentist ridge the prior also regularizes the intercept.
-}
fitBayesian :: Double -> Double -> Dataset -> [Double] -> Either MathError BayesianLinear
fitBayesian alpha beta xs ys = do
    (_, d) <- responses xs ys
    require (all (\x -> finite x && x > 0) [alpha, beta]) "Bayesian precisions must be positive"
    let x = map (1 :) xs
        xt = transpose x
        gram = matmul xt x
        precision = [[beta * gram !! i !! j + (if i == j then alpha else 0) | j <- [0 .. d]] | i <- [0 .. d]]
    covariance <- inverse precision
    let b = map (`dot` scale beta (map (`dot` ys) xt)) covariance
    checked b
    Right (BayesianLinear (LinearModel b) covariance)

-- | Owned online regression coefficients and inverse information, with fixed forgetting factor.
data RecursiveLS = RLS [Double] Dataset Double deriving (Eq, Show)

-- | Current intercept and slopes; updating creates a new state.
recursiveCoefficients :: RecursiveLS -> [Double]
recursiveCoefficients (RLS b _ _) = b

{- | Initial inverse information delta I; forgetting factor in (0,1]. Input
dimension excludes the automatically supplied intercept.
-}
recursiveLS :: Int -> Double -> Double -> Either MathError RecursiveLS
recursiveLS d delta forgetting = do
    require
        ( d > 0
            && d < 100000
            && finite delta
            && delta > 0
            && finite forgetting
            && forgetting > 0
            && forgetting <= 1
        )
        "invalid recursive least-squares configuration"
    Right (RLS (replicate (d + 1) 0) (map (scale delta) (ident (d + 1))) forgetting)

-- | Assimilate one feature row/response using the matrix inversion lemma. Reject lost definiteness.
updateRecursiveLS :: RecursiveLS -> [Double] -> Double -> Either MathError RecursiveLS
updateRecursiveLS (RLS b p forgetting) row y = do
    queries (length b - 1) [row]
    checked [y]
    let x = 1 : row; px = map (`dot` x) p; denom = forgetting + dot x px
    require (denom > 0 && finite denom) "recursive information matrix lost definiteness"
    let gain = scale (1 / denom) px
        b' = add b (scale (y - dot b x) gain)
        xp = map (dot x) (transpose p)
        p' =
            [ [((p !! i !! j) - (gain !! i) * (xp !! j)) / forgetting | j <- [0 .. length b - 1]]
            | i <- [0 .. length b - 1]
            ]
    checked (b' ++ concat p')
    Right (RLS b' p' forgetting)

-- | Bernoulli mean with logistic link, or nonnegative response mean with log link.
data GLMFamily = BinomialLogit | PoissonLog deriving (Eq, Show)

-- | Fitted generalized linear model with intercept and family-specific inverse link.
data GLM = GLM GLMFamily [Double] deriving (Eq, Show)

sigmoid :: Double -> Double
sigmoid x | x >= 0 = 1 / (1 + exp (-x)) | otherwise = let e = exp x in e / (1 + e)

-- | Damped Newton/IRLS with nonnegative slope ridge. Residual is the penalized likelihood gradient norm.
fitGLM :: MLConfig -> GLMFamily -> Double -> Dataset -> [Double] -> Either MathError (Fit GLM)
fitGLM c family ridge xs ys = do
    config c
    (_, d) <- responses xs ys
    require (finite ridge && ridge >= 0) "invalid GLM ridge"
    require
        (all (\y -> case family of BinomialLogit -> y >= 0 && y <= 1; PoissonLog -> y >= 0) ys)
        "GLM response outside support"
    let x = map (1 :) xs
        n = fromIntegral (length ys)
        evaluate b = do
            let eta = map (`dot` b) x
                means = map (\z -> case family of BinomialLogit -> sigmoid z; PoissonLog -> exp z) eta
                log1exp z = if z > 0 then z + log (1 + exp (-z)) else log (1 + exp z)
                loss =
                    sum
                        ( zipWith
                            (\z y -> case family of BinomialLogit -> log1exp z - y * z; PoissonLog -> exp z - y * z)
                            eta
                            ys
                        )
                        / n
                        + ridge * dot (drop 1 b) (drop 1 b) / 2
                grad =
                    [ sum (zipWith (\r e -> r !! j * e) x (sub means ys)) / n + (if j == 0 then 0 else ridge * b !! j)
                    | j <- [0 .. d]
                    ]
                weights = map (\mu -> max 1e-12 (case family of BinomialLogit -> mu * (1 - mu); PoissonLog -> mu)) means
                h =
                    [ [ sum (zipWith (\r w -> w * r !! i * r !! j) x weights) / n + (if i == j && i > 0 then ridge else 0)
                      | j <- [0 .. d]
                      ]
                    | i <- [0 .. d]
                    ]
            checked (loss : grad ++ concat h)
            Right (loss, grad, h)
        go k b = do
            (loss, g, h) <- evaluate b
            let residual = norm g
            if residual <= mlTolerance c || k >= mlIterations c
                then Right (Fit (GLM family b) k residual (residual <= mlTolerance c))
                else do
                    direction <- solveLS h g
                    let line j step
                            | j >= 40 = Left (NonConvergence "GLM line search" j)
                            | otherwise = do
                                let trial = sub b (scale step direction)
                                (v, _, _) <- evaluate trial
                                if v <= loss - 1e-4 * step * dot g direction then Right trial else line (j + 1) (step / 2)
                    next <- line (0 :: Int) 1
                    go (k + 1) next
    go 0 (replicate (d + 1) 0)

-- | Return conditional means: probabilities for BinomialLogit, positive rates for PoissonLog.
predictGLM :: GLM -> Dataset -> Either MathError [Double]
predictGLM (GLM family b) xs = do
    queries (length b - 1) xs
    let answer =
            map
                (\r -> case family of BinomialLogit -> sigmoid (dot b (1 : r)); PoissonLog -> exp (dot b (1 : r)))
                xs
    checked answer
    Right answer

-- | Softmax class weights and sorted original integer labels.
data MultinomialModel = MultinomialModel [Int] Dataset deriving (Eq, Show)

softmax :: [Double] -> [Double]
softmax xs = let m = maximum xs; ex = map (exp . subtract m) xs; s = sum ex in map (/ s) ex

-- | Fit all class logits by full-batch gradient descent with slope ridge. Residual is weight displacement.
fitMultinomial :: MLConfig -> Double -> Dataset -> [Int] -> Either MathError (Fit MultinomialModel)
fitMultinomial c ridge xs labels = do
    config c
    (n, d) <- dataset xs
    require (length labels == n && finite ridge && ridge >= 0) "invalid multinomial responses/ridge"
    let classes = sort (nub labels); k = length classes; design = map (1 :) xs
    require (k >= 2) "multinomial regression needs two classes"
    let step weights = do
            let probs = [softmax (map (`dot` r) weights) | r <- design]
                grad =
                    [ [ sum
                            [ (probs !! i !! j - if labels !! i == classes !! j then 1 else 0) * design !! i !! a
                            | i <- [0 .. n - 1]
                            ]
                            / fromIntegral n
                            + (if a == 0 then 0 else ridge * weights !! j !! a)
                      | a <- [0 .. d]
                      ]
                    | j <- [0 .. k - 1]
                    ]
                new = zipWith (\w g -> sub w (scale (mlRate c) g)) weights grad
            checked (concat new)
            Right new
    fit <-
        iterateFit c step (\a b -> norm (concat (zipWith sub a b))) (replicate k (replicate (d + 1) 0))
    Right fit{fitted = MultinomialModel classes (fitted fit)}

-- | Return sorted (original label, probability) pairs for each observation.
predictMultinomial :: MultinomialModel -> Dataset -> Either MathError [[(Int, Double)]]
predictMultinomial (MultinomialModel classes weights) xs = do
    queries (length (firstRow weights) - 1) xs
    Right [zip classes (softmax (map (`dot` (1 : r)) weights)) | r <- xs]

-- | Positive-semidefinite linear, polynomial, or Gaussian radial basis kernel parameters.
data Kernel = LinearKernel | PolynomialKernel Int Double Double | RBFKernel Double
    deriving (Eq, Show)

-- | Evaluate a checked PSD kernel on equal-length finite feature vectors.
kernel :: Kernel -> [Double] -> [Double] -> Either MathError Double
kernel kind x y = do
    require (length x == length y) "kernel feature mismatch"
    checked (x ++ y)
    case kind of
        RBFKernel gamma -> require (finite gamma && gamma > 0) "RBF gamma must be positive"
        PolynomialKernel degree gamma offset ->
            require
                (degree > 0 && degree <= 1000 && finite gamma && gamma >= 0 && finite offset && offset >= 0)
                "invalid PSD polynomial kernel"
        _ -> Right ()
    let value = case kind of
            LinearKernel -> dot x y
            RBFKernel gamma -> exp (-gamma * dist2 x y)
            PolynomialKernel degree gamma offset -> (gamma * dot x y + offset) ^ degree
    checked [value]
    Right value

-- | Binary kernel decision state, retaining original training observations and signed dual weights.
data SVM = SVM Kernel Dataset [Double] Double deriving (Eq, Show)

{- | Deterministic two-coordinate SMO for binary labels -1/+1. The reported
residual is the largest box-constrained dual KKT violation.
-}
fitSVM :: MLConfig -> Kernel -> Double -> Dataset -> [Double] -> Either MathError (Fit SVM)
fitSVM c kind cost xs ys = do
    config c
    (n, _) <- responses xs ys
    require
        (n >= 2 && all (`elem` [-1, 1]) ys && (-1) `elem` ys && 1 `elem` ys && finite cost && cost > 0)
        "SVM needs both binary classes and positive C"
    gram <- traverse (\x -> traverse (kernel kind x) xs) xs
    let decision as bias i = sum [as !! j * ys !! j * gram !! i !! j | j <- [0 .. n - 1]] + bias
        dual as =
            sum as
                - 0.5
                    * sum [as !! i * as !! j * ys !! i * ys !! j * gram !! i !! j | i <- [0 .. n - 1], j <- [0 .. n - 1]]
        pair (as, bias) i =
            let ei = decision as bias i - ys !! i
                violates =
                    (ys !! i * ei < -mlTolerance c && as !! i < cost) || (ys !! i * ei > mlTolerance c && as !! i > 0)
                candidates = sortOn (\j -> negate (abs (ei - (decision as bias j - ys !! j)))) [j | j <- [0 .. n - 1], j /= i]
                -- A maximal-error candidate can be blocked by its box bounds.
                -- Continue through the remaining coordinates instead of stalling.
                attempt [] = Right (as, bias)
                attempt (j : rest) = do
                    let ej = decision as bias j - ys !! j
                        ai = as !! i
                        aj = as !! j
                        (lo, hi) =
                            if ys !! i /= ys !! j
                                then (max 0 (aj - ai), min cost (cost + aj - ai))
                                else (max 0 (ai + aj - cost), min cost (ai + aj))
                        eta = 2 * gram !! i !! j - gram !! i !! i - gram !! j !! j
                        withValue value = replace i (ai + ys !! i * ys !! j * (aj - value)) (replace j value as)
                        -- Coincident rows have zero curvature. Their dual is
                        -- linear along this feasible pair, so compare endpoints.
                        endpoint = if dual (withValue lo) > dual (withValue hi) then lo else hi
                        aj' = if eta < -1e-14 then max lo (min hi (aj - ys !! j * (ei - ej) / eta)) else endpoint
                        ai' = ai + ys !! i * ys !! j * (aj - aj')
                    if lo >= hi || abs (aj' - aj) <= 1e-14 * (1 + abs aj)
                        then attempt rest
                        else do
                            let b1 = bias - ei - ys !! i * (ai' - ai) * gram !! i !! i - ys !! j * (aj' - aj) * gram !! i !! j
                                b2 = bias - ej - ys !! i * (ai' - ai) * gram !! i !! j - ys !! j * (aj' - aj) * gram !! j !! j
                                bias' = if ai' > 0 && ai' < cost then b1 else if aj' > 0 && aj' < cost then b2 else (b1 + b2) / 2
                                next = withValue aj'
                            checked (bias' : next)
                            Right (next, bias')
             in if violates then attempt candidates else Right (as, bias)
        recalibrate as oldBias =
            let raw i = decision as 0 i
                free = [ys !! i - raw i | i <- [0 .. n - 1], as !! i > 1e-10, as !! i < cost - 1e-10]
                lower =
                    [ ys !! i - raw i
                    | i <- [0 .. n - 1]
                    , (ys !! i == 1 && as !! i <= 1e-10) || (ys !! i == -1 && as !! i >= cost - 1e-10)
                    ]
                upper =
                    [ ys !! i - raw i
                    | i <- [0 .. n - 1]
                    , (ys !! i == -1 && as !! i <= 1e-10) || (ys !! i == 1 && as !! i >= cost - 1e-10)
                    ]
             in if not (null free)
                    then sum free / fromIntegral (length free)
                    else
                        if null lower || null upper then oldBias else maximum lower / 2 + minimum upper / 2
        residual as bias =
            maximum
                [ let margin = ys !! i * decision as bias i
                   in if as !! i <= 1e-12
                        then max 0 (1 - margin)
                        else if as !! i >= cost - 1e-12 then max 0 (margin - 1) else abs (margin - 1)
                | i <- [0 .. n - 1]
                ]
        go k as bias = do
            let r = residual as bias
            if r <= mlTolerance c || k >= mlIterations c
                then Right (Fit (SVM kind xs (zipWith (*) as ys) bias) k r (r <= mlTolerance c))
                else do
                    (next, b) <- foldM pair (as, bias) [0 .. n - 1]
                    go (k + 1) next (recalibrate next b)
    go 0 (replicate n 0) 0

-- | Return signed kernel margins; zero is the fitted decision boundary.
decisionSVM :: SVM -> Dataset -> Either MathError [Double]
decisionSVM (SVM kind train weights bias) xs = do
    queries (length (firstRow train)) xs
    traverse
        ( \x -> do
            vals <- traverse (kernel kind x) train
            let v = dot weights vals + bias
            checked [v]
            Right v
        )
        xs

-- | Classify margins as -1 or +1, with zero assigned +1.
predictSVM :: SVM -> Dataset -> Either MathError [Double]
predictSVM model xs = map (\x -> if x >= 0 then 1 else -1) <$> decisionSVM model xs

-- | Zero-mean Gaussian-process regression posterior with retained training covariance solve.
data GaussianProcess = GP Kernel Dataset [Double] Dataset deriving (Eq, Show)

-- | Fit a GP with strictly positive observation-noise variance and a checked PSD kernel.
fitGaussianProcess :: Kernel -> Double -> Dataset -> [Double] -> Either MathError GaussianProcess
fitGaussianProcess kind noise xs ys = do
    (n, _) <- responses xs ys
    require (finite noise && noise > 0) "GP observation variance must be positive"
    k <- traverse (\x -> traverse (kernel kind x) xs) xs
    inv <- inverse [[k !! i !! j + if i == j then noise else 0 | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
    let alpha = map (`dot` ys) inv
    checked alpha
    Right (GP kind xs alpha inv)

-- | Return posterior latent-function (mean, variance), excluding observation noise.
predictGaussianProcess :: GaussianProcess -> Dataset -> Either MathError [(Double, Double)]
predictGaussianProcess (GP kind train alpha inv) xs = do
    queries (length (firstRow train)) xs
    traverse
        ( \x -> do
            kv <- traverse (kernel kind x) train
            kxx <- kernel kind x x
            let mu = dot kv alpha; variance = kxx - dot kv (map (`dot` kv) inv)
            checked [mu, variance]
            require (variance >= -1e-7 * max 1 kxx) "GP negative posterior variance"
            Right (mu, max 0 variance)
        )
        xs

-- | Logistic Gaussian-process classifier fitted with a Laplace Gaussian posterior approximation.
data GPClassifier = GPC Kernel Dataset [Double] Dataset deriving (Eq, Show)

-- | Newton mode fitting for 0/1 labels. A 1e-10 diagonal jitter stabilizes the prior covariance.
fitGPClassifier :: MLConfig -> Kernel -> Dataset -> [Double] -> Either MathError (Fit GPClassifier)
fitGPClassifier c kind xs ys = do
    config c
    (n, _) <- responses xs ys
    require (all (`elem` [0, 1]) ys) "GP classification labels must be 0/1"
    gram <- traverse (\x -> traverse (kernel kind x) xs) xs
    ki <-
        inverse [[gram !! i !! j + if i == j then 1e-10 else 0 | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
    let step f = do
            let p = map sigmoid f
                w = map (\z -> max 1e-12 (z * (1 - z))) p
                h = [[ki !! i !! j + if i == j then w !! i else 0 | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
                g = add (map (`dot` f) ki) (sub p ys)
            delta <- solveLS h g
            let new = sub f delta
            checked new
            Right new
    fit <- iterateFit c step (\a b -> norm (sub a b)) (replicate n 0)
    let f = fitted fit; p = map sigmoid f; w = map (\z -> max 1e-12 (z * (1 - z))) p
    correction <-
        inverse
            [[gram !! i !! j + if i == j then 1 / (w !! i) else 0 | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
    Right fit{fitted = GPC kind xs (sub ys p) correction}

-- | Approximate class-one probabilities using the logistic Gaussian variance correction.
predictGPClassifier :: GPClassifier -> Dataset -> Either MathError [Double]
predictGPClassifier (GPC kind xs alpha correction) queries' = do
    predictions <- predictGaussianProcess (GP kind xs alpha correction) queries'
    Right [sigmoid (mu / sqrt (1 + pi * v / 8)) | (mu, v) <- predictions]

-- | Gaussian features, nonnegative multinomial counts, or binary Bernoulli features.
data BayesFamily = GaussianBayes | MultinomialBayes | BernoulliBayes deriving (Eq, Show)

-- | Fitted class priors and family-specific independent feature likelihoods.
data NaiveBayes = NB BayesFamily [Int] [Double] Dataset Dataset deriving (Eq, Show)

-- | Fit class likelihoods. Smoothing is a variance floor for Gaussian and a pseudocount otherwise.
fitNaiveBayes :: BayesFamily -> Double -> Dataset -> [Int] -> Either MathError NaiveBayes
fitNaiveBayes family smoothing xs labels = do
    (n, _) <- dataset xs
    require
        (length labels == n && finite smoothing && smoothing > 0)
        "invalid naive Bayes responses/smoothing"
    case family of
        MultinomialBayes -> require (all (>= 0) (concat xs)) "multinomial features must be nonnegative"
        BernoulliBayes -> require (all (`elem` [0, 1]) (concat xs)) "Bernoulli features must be binary"
        _ -> Right ()
    let classes = sort (nub labels)
        groups = [[x | (x, y) <- zip xs labels, y == c] | c <- classes]
        priors = map (\g -> fromIntegral (length g) / fromIntegral n) groups
        means = map meanV groups
        variances =
            [ map
                ( \col ->
                    max
                        smoothing
                        (sum [(v - sum col / fromIntegral (length col)) ^ (2 :: Int) | v <- col] / fromIntegral (length col))
                )
                (transpose g)
            | g <- groups
            ]
        probs = case family of
            GaussianBayes -> means
            MultinomialBayes ->
                [ let counts = map ((+ smoothing) . sum) (transpose g) in scale (1 / sum counts) counts | g <- groups
                ]
            BernoulliBayes ->
                [ map (\col -> (sum col + smoothing) / (fromIntegral (length col) + 2 * smoothing)) (transpose g)
                | g <- groups
                ]
    checked (priors ++ concat probs ++ concat variances)
    Right (NB family classes priors probs variances)

-- | Select the class with greatest log posterior; preserve the original integer labels.
predictNaiveBayes :: NaiveBayes -> Dataset -> Either MathError [Int]
predictNaiveBayes (NB family classes priors params variances) xs = do
    queries (length (firstRow params)) xs
    case family of
        MultinomialBayes -> require (all (>= 0) (concat xs)) "multinomial query must be nonnegative"
        BernoulliBayes -> require (all (`elem` [0, 1]) (concat xs)) "Bernoulli query must be binary"
        _ -> Right ()
    let scores row =
            [ log (priors !! j)
                + sum
                    [ case family of
                        GaussianBayes ->
                            -0.5
                                * ( log (2 * pi * (variances !! j !! i))
                                        + (row !! i - params !! j !! i) ^ (2 :: Int) / (variances !! j !! i)
                                  )
                        MultinomialBayes -> row !! i * log (params !! j !! i)
                        BernoulliBayes -> row !! i * log (params !! j !! i) + (1 - row !! i) * log (1 - params !! j !! i)
                    | i <- [0 .. length row - 1]
                    ]
            | j <- [0 .. length classes - 1]
            ]
    let allScores = map scores xs
    checked (concat allScores)
    Right [classes !! argmax s | s <- allScores]

-- | Class priors, means, and regularized inverse covariance/log-determinant state.
data Discriminant = Discriminant [Int] [Double] Dataset [Dataset] [Double] deriving (Eq, Show)

{- | False = pooled covariance LDA; True = class covariance QDA. A positive
diagonal ridge makes singular/constant-feature data explicitly regularized.
-}
fitDiscriminant :: Bool -> Double -> Dataset -> [Int] -> Either MathError Discriminant
fitDiscriminant quadratic ridge xs labels = do
    (n, d) <- dataset xs
    require
        (n == length labels && finite ridge && ridge > 0)
        "discriminant needs labels/positive covariance ridge"
    let classes = sort (nub labels)
        groups = [[x | (x, y) <- zip xs labels, y == c] | c <- classes]
        means = map meanV groups
        scatters =
            [ let centered = map (`sub` mu) g in matmul (transpose centered) centered
            | (g, mu) <- zip groups means
            ]
        pooled = [[sum [s !! i !! j | s <- scatters] / fromIntegral n | j <- [0 .. d - 1]] | i <- [0 .. d - 1]]
        covs =
            if quadratic
                then zipWith (\g s -> map (scale (1 / fromIntegral (length g))) s) groups scatters
                else replicate (length groups) pooled
        regularized =
            [ [[cov !! i !! j + if i == j then ridge else 0 | j <- [0 .. d - 1]] | i <- [0 .. d - 1]]
            | cov <- covs
            ]
    inverses <- traverse inverse regularized
    eigs <- traverse symmetricEigen regularized
    let logdets = map (sum . map log . fst) eigs
    checked logdets
    Right
        ( Discriminant
            classes
            (map (\g -> fromIntegral (length g) / fromIntegral n) groups)
            means
            inverses
            logdets
        )

-- | Classify with Gaussian discriminant log likelihoods using training covariance state.
predictDiscriminant :: Discriminant -> Dataset -> Either MathError [Int]
predictDiscriminant (Discriminant classes priors means inverses logdets) xs = do
    queries (length (firstRow means)) xs
    let scores row =
            [ let delta = sub row (means !! j)
               in log (priors !! j) - 0.5 * (logdets !! j + dot delta (map (`dot` delta) (inverses !! j)))
            | j <- [0 .. length classes - 1]
            ]
        allScores = map scores xs
    checked (concat allScores)
    Right [classes !! argmax s | s <- allScores]
