-- SPDX-License-Identifier: MPL-2.0

{- | Finite-data checked statistics. Quantiles use Hyndman--Fan type 7; sample
variance divides by n-1; skewness and excess kurtosis use population central
moments. Weights are reliability weights normalized by their positive sum.
NaN/infinity are rejected; 'masked' selects True entries before validation.
Hypothesis tests report a statistic, a two-sided p value (unless intrinsically
upper-tailed), and degrees of freedom. Rank tests use tie-corrected normal/
chi-square asymptotics. KS uses the asymptotic continuous-null law; normality
tests require a fully specified or fitted normal as stated on each function.
-}
module HMath.Statistics.Advanced (
    arithmeticMean,
    weightedMean,
    geometricMean,
    harmonicMean,
    rms,
    trimmedMean,
    winsorizedMean,
    median,
    modes,
    quantile,
    percentile,
    interquartileRange,
    medianAbsoluteDeviation,
    dataRange,
    populationVariance,
    sampleVariance,
    populationSD,
    sampleSD,
    coefficientOfVariation,
    centralMoment,
    skewness,
    kurtosis,
    covariance,
    correlation,
    covarianceMatrix,
    spearman,
    kendall,
    partialCorrelation,
    autocorrelation,
    crossCorrelation,
    movingAverage,
    exponentialMovingAverage,
    movingVariance,
    Streaming,
    emptyStreaming,
    updateStreaming,
    combineStreaming,
    streamingResult,
    histogramND,
    entropy,
    mutualInformation,
    klDivergence,
    jsDivergence,
    zScores,
    standardError,
    confidenceInterval,
    bootstrap,
    jackknife,
    TestResult (..),
    oneSampleT,
    twoSampleT,
    pairedT,
    zTest,
    chiSquareTest,
    varianceFTest,
    anova,
    welchAnova,
    kruskalWallis,
    mannWhitney,
    wilcoxon,
    kolmogorovSmirnov,
    shapiroWilk,
    andersonDarling,
    levene,
    bartlett,
    fisherExact,
    permutationTest,
    bonferroni,
    benjaminiHochberg,
    cohensD,
    etaSquared,
    normalTestPower,
    normalSampleSize,
    tukeyOutliers,
    grubbs,
    masked,
    huberLocation,
) where

import qualified Data.Foldable as Foldable (foldl')
import Data.List (group, sort, sortOn, transpose)
import HMath.Error
import HMath.Matrix (fromListChecked, toList)
import HMath.Matrix.LU (inverse)
import qualified HMath.Probability as P
import qualified HMath.Random as R
import qualified HMath.Special as S

finite :: Double -> Bool
finite x = not (isNaN x || isInfinite x)
require :: Bool -> String -> Either MathError ()
require p s = if p then Right () else Left (DomainError s)
checked :: Double -> Either MathError Double
checked x = if finite x then Right x else Left NonFiniteResult
validate :: Int -> [Double] -> Either MathError ()
validate n xs =
    require (length xs >= n && all finite xs) ("requires at least " ++ show n ++ " finite observations")

-- | Mean of finite nonempty data. Dividing each observation before summation avoids preventable same-sign sum overflow.
arithmeticMean :: [Double] -> Either MathError Double
arithmeticMean xs = do validate 1 xs; checked (sum (map (/ fromIntegral (length xs)) xs))

-- | Reliability-weighted mean of observations and nonnegative finite weights; weights must have finite positive total.
weightedMean :: [Double] -> [Double] -> Either MathError Double
weightedMean xs ws = do
    validate 1 xs
    require
        (length xs == length ws && all (\w -> finite w && w >= 0) ws && finite (sum ws) && sum ws > 0)
        "invalid reliability weights"
    checked (sum (zipWith (\x w -> x * (w / sum ws)) xs ws))

-- | exp(mean(log x)) for strictly positive finite observations.
geometricMean :: [Double] -> Either MathError Double
geometricMean xs = do
    validate 1 xs
    require (all (> 0) xs) "geometric mean requires positive data"
    m <- arithmeticMean (map log xs)
    checked (exp m)

-- | Reciprocal of the mean reciprocal, for strictly positive finite observations.
harmonicMean :: [Double] -> Either MathError Double
harmonicMean xs = do
    validate 1 xs
    require (all (> 0) xs) "harmonic mean requires positive data"
    m <- arithmeticMean (map (1 /) xs)
    checked (1 / m)

-- | Root-mean-square with max scaling to avoid squaring overflow.
rms :: [Double] -> Either MathError Double
rms xs = do
    validate 1 xs
    let scale = maximum (map abs xs)
     in if scale == 0
            then pure 0
            else
                checked (scale * sqrt (sum (map (\x -> (x / scale) ^ (2 :: Int)) xs) / fromIntegral (length xs)))

-- | Discard floor(fraction*n) samples from each sorted tail, with fraction in [0,1/2), then average.
trimmedMean :: Double -> [Double] -> Either MathError Double
trimmedMean fraction xs = do
    validate 1 xs
    require (finite fraction && fraction >= 0 && fraction < 0.5) "trim fraction must lie in [0,0.5)"
    let k = floor (fraction * fromIntegral (length xs))
     in arithmeticMean (take (length xs - 2 * k) (drop k (sort xs)))

-- | Replace floor(fraction*n) values at each tail with the nearest retained value, then average.
winsorizedMean :: Double -> [Double] -> Either MathError Double
winsorizedMean fraction xs = do
    validate 1 xs
    require (finite fraction && fraction >= 0 && fraction < 0.5) "winsor fraction must lie in [0,0.5)"
    let ys = sort xs
        k = floor (fraction * fromIntegral (length xs))
        lo = ys !! k
        hi = ys !! (length xs - k - 1)
     in arithmeticMean (map (max lo . min hi) xs)

-- | Hyndman--Fan type-7 quantile with linear interpolation and probability p in [0,1].
quantile :: Double -> [Double] -> Either MathError Double
quantile p xs = do
    validate 1 xs
    require (finite p && p >= 0 && p <= 1) "quantile probability outside [0,1]"
    let ys = sort xs
        t = p * fromIntegral (length xs - 1)
        i = floor t
        j = min (length xs - 1) (i + 1)
        w = t - fromIntegral i
     in checked ((1 - w) * (ys !! i) + w * (ys !! j))

-- | Type-7 50th percentile; averages the central pair for an even sample count.
median :: [Double] -> Either MathError Double
median = quantile 0.5

-- | Type-7 quantile with percentage in [0,100].
percentile :: Double -> [Double] -> Either MathError Double
percentile p = quantile (p / 100)

-- | All values of maximum multiplicity, sorted ascending; exact floating equality defines ties.
modes :: [Double] -> Either MathError [Double]
modes xs = do
    validate 1 xs
    let gs = group (sort xs); m = maximum (map length gs) in pure [ys !! 0 | ys <- gs, length ys == m]

-- | Type-7 75th percentile minus 25th percentile.
interquartileRange :: [Double] -> Either MathError Double
interquartileRange xs = do a <- quantile 0.25 xs; b <- quantile 0.75 xs; checked (b - a)

-- | Median absolute deviation from the median, without the normal consistency multiplier.
medianAbsoluteDeviation :: [Double] -> Either MathError Double
medianAbsoluteDeviation xs = do m <- median xs; median (map (\x -> abs (x - m)) xs)

-- | Maximum minus minimum; arithmetic overflow is an explicit error.
dataRange :: [Double] -> Either MathError Double
dataRange xs = do validate 1 xs; checked (maximum xs - minimum xs)

-- | Population central moment of integer order 0..32; nonfinite intermediate/final arithmetic is rejected.
centralMoment :: Int -> [Double] -> Either MathError Double
centralMoment k xs = do
    require (k >= 0 && k <= 32) "moment order must be 0..32"
    m <- arithmeticMean xs
    arithmeticMean (map (\x -> (x - m) ^ k) xs)

-- | Second population central moment, dividing by n.
populationVariance :: [Double] -> Either MathError Double
populationVariance = centralMoment 2

-- | Unbiased sample variance, dividing by n-1; requires at least two observations.
sampleVariance :: [Double] -> Either MathError Double
sampleVariance xs = do
    validate 2 xs
    v <- populationVariance xs
    checked (v * fromIntegral (length xs) / fromIntegral (length xs - 1))

-- | Square root of population variance.
populationSD :: [Double] -> Either MathError Double
populationSD = fmap sqrt . populationVariance

-- | Square root of unbiased sample variance.
sampleSD :: [Double] -> Either MathError Double
sampleSD = fmap sqrt . sampleVariance

-- | Population standard deviation divided by absolute mean; rejects zero mean.
coefficientOfVariation :: [Double] -> Either MathError Double
coefficientOfVariation xs = do
    m <- arithmeticMean xs
    require (m /= 0) "coefficient of variation undefined at zero mean"
    s <- populationSD xs
    checked (s / abs m)

-- | Uncorrected population third standardized central moment; requires nonconstant observations.
skewness :: [Double] -> Either MathError Double
skewness xs = do
    v <- populationVariance xs
    require (v > 0) "skewness needs nonconstant data"
    m <- centralMoment 3 xs
    checked (m / v ** 1.5)

-- | Uncorrected population excess kurtosis, subtracting three; requires nonconstant observations.
kurtosis :: [Double] -> Either MathError Double
kurtosis xs = do
    v <- populationVariance xs
    require (v > 0) "kurtosis needs nonconstant data"
    m <- centralMoment 4 xs
    checked (m / (v * v) - 3)

-- | Covariance of two matching finite data vectors; True selects the n-1 sample correction.
covariance :: Bool -> [Double] -> [Double] -> Either MathError Double
covariance sampleCorrection xs ys = do
    validate (if sampleCorrection then 2 else 1) xs
    validate 1 ys
    require (length xs == length ys) "covariance length mismatch"
    a <- arithmeticMean xs
    b <- arithmeticMean ys
    checked
        ( sum (zipWith (\x y -> (x - a) * (y - b)) xs ys)
            / fromIntegral (length xs - if sampleCorrection then 1 else 0)
        )

-- | Pearson correlation of matching nonconstant data vectors.
correlation :: [Double] -> [Double] -> Either MathError Double
correlation xs ys = do
    c <- covariance False xs ys
    a <- populationSD xs
    b <- populationSD ys
    require (a > 0 && b > 0) "correlation needs nonconstant data"
    checked (max (-1) (min 1 (c / (a * b))))

-- | Covariance matrix for variables supplied as columns (each list is one variable). Boolean selects sample correction.
covarianceMatrix :: Bool -> [[Double]] -> Either MathError [[Double]]
covarianceMatrix correction columns = do
    require (not (null columns)) "covariance matrix needs columns"
    mapM (\x -> mapM (covariance correction x) columns) columns

ranks :: [Double] -> [Double]
ranks xs = map snd (sortOn fst (concatMap assign (groupByValue (sortOn snd (zip [0 :: Int ..] xs)))))
  where
    groupByValue [] = []
    groupByValue (a : as) = let (g, t) = span ((== snd a) . snd) as in (a : g) : groupByValue t
    assign g =
        let v =
                fromIntegral (sum [1 + length (filter (< x) xs) | (_, x) <- g]) / fromIntegral (length g)
                    + fromIntegral (length g - 1) / 2
         in [(i, v) | (i, _) <- g]

-- | Pearson correlation of average tied ranks; matching nonconstant rank vectors required.
spearman :: [Double] -> [Double] -> Either MathError Double
spearman xs ys = do validate 2 xs; validate 2 ys; correlation (ranks xs) (ranks ys)

-- | Kendall tau-b with tied-pair correction; quadratic reference implementation.
kendall :: [Double] -> [Double] -> Either MathError Double
kendall xs ys = do
    validate 2 xs
    validate 2 ys
    require (length xs == length ys) "Kendall length mismatch"
    let pairs =
            [ (compare (xs !! i) (xs !! j), compare (ys !! i) (ys !! j))
            | i <- [0 .. length xs - 1]
            , j <- [i + 1 .. length xs - 1]
            ]
        score = sum [if a == b then 1 else -1 | (a, b) <- pairs, a /= EQ, b /= EQ]
        n = fromIntegral (length pairs)
        tx = fromIntegral (length (filter ((== EQ) . fst) pairs))
        ty = fromIntegral (length (filter ((== EQ) . snd) pairs))
        den = sqrt ((n - tx) * (n - ty))
    require (den > 0) "Kendall undefined for constant ranks"
    pure (fromIntegral (score :: Int) / den)

-- | Partial correlation of variable indices i,j conditional on every other supplied column, through the inverse sample covariance.
partialCorrelation :: [[Double]] -> Int -> Int -> Either MathError Double
partialCorrelation columns i j = do
    let p = length columns
    require (i >= 0 && j >= 0 && i < p && j < p && i /= j) "partial correlation indices invalid"
    cov <- covarianceMatrix True columns
    mat <- fromListChecked p p (concat cov)
    inv <- inverse mat
    let a = toList inv; den = sqrt (a !! (i * p + i) * a !! (j * p + j))
    require (den > 0) "partial correlation invalid precision matrix"
    checked (-a !! (i * p + j) / den)

-- | Pearson correlation between overlapping lagged segments; zero<=lag<n-1.
autocorrelation :: Int -> [Double] -> Either MathError Double
autocorrelation lag xs = crossCorrelation lag xs xs

-- | Pearson correlation of overlapping x_t and y_(t+lag), using their common finite length.
crossCorrelation :: Int -> [Double] -> [Double] -> Either MathError Double
crossCorrelation lag xs ys = do
    require (lag >= 0 && lag < min (length xs) (length ys) - 1) "lag outside overlap"
    correlation
        (take (min (length xs) (length ys) - lag) xs)
        (drop lag (take (min (length xs) (length ys)) ys))

-- | Valid-window moving means; window must lie in [1,n], with no endpoint padding.
movingAverage :: Int -> [Double] -> Either MathError [Double]
movingAverage window xs = rolling arithmeticMean window xs

-- | Valid-window population variances with no endpoint padding.
movingVariance :: Int -> [Double] -> Either MathError [Double]
movingVariance window xs = rolling populationVariance window xs

rolling :: ([Double] -> Either MathError Double) -> Int -> [Double] -> Either MathError [Double]
rolling f n xs = do
    validate 1 xs
    require (n > 0 && n <= length xs) "rolling window outside data"
    mapM (\i -> f (take n (drop i xs))) [0 .. length xs - n]

-- | EMA with alpha in (0,1], initialized at the first observation.
exponentialMovingAverage :: Double -> [Double] -> Either MathError [Double]
exponentialMovingAverage alpha xs = do
    validate 1 xs
    require (finite alpha && alpha > 0 && alpha <= 1) "EMA alpha in (0,1] required"
    pure (scanl (\a x -> (1 - alpha) * a + alpha * x) (xs !! 0) (drop 1 xs))

-- | Opaque Welford accumulator storing an unbounded Integer count, mean and sum of squared deviations.
data Streaming = Streaming !Integer !Double !Double deriving (Eq, Show)

-- | Zero-count Welford accumulator.
emptyStreaming :: Streaming
emptyStreaming = Streaming 0 0 0

-- | Add one finite observation by Welford recurrence; nonfinite arithmetic is rejected.
updateStreaming :: Streaming -> Double -> Either MathError Streaming
updateStreaming (Streaming n m m2) x = do
    validate 1 [x]
    let count = n + 1; d = x - m; mean = m + d / fromInteger count; second = m2 + d * (x - mean)
     in checked mean >> checked second >> pure (Streaming count mean second)

-- | Chan parallel merge of two Welford accumulators; empty accumulators are identities.
combineStreaming :: Streaming -> Streaming -> Either MathError Streaming
combineStreaming a@(Streaming n m v) b@(Streaming k u w)
    | n == 0 = Right b
    | k == 0 = Right a
    | otherwise =
        let d = u - m
            count = n + k
            mean = m + d * fromInteger k / fromInteger count
            second = v + w + d * d * fromInteger n * fromInteger k / fromInteger count
         in checked mean >> checked second >> pure (Streaming count mean second)

-- | Return count, mean and variance; True uses n-1 correction and requires at least two samples.
streamingResult :: Bool -> Streaming -> Either MathError (Integer, Double, Double)
streamingResult correction (Streaming n m s) = do
    require (n > if correction then 1 else 0) "insufficient streaming count"
    pure (n, m, s / fromInteger (n - if correction then 1 else 0))

{- | Histogram edges must increase strictly; intervals are [a,b), with the last
interval closed on its right. Points outside any axis are excluded. Flattening
is row-major, the last axis varies fastest. Weights need not sum to one.
-}
histogramND :: [[Double]] -> [[Double]] -> [Double] -> Either MathError [Double]
histogramND edges points weights = do
    require
        ( not (null edges)
            && all (\es -> length es >= 2 && all finite es && and (zipWith (<) es (drop 1 es))) edges
        )
        "histogram edges invalid"
    require
        ( length points == length weights
            && all (\p -> length p == length edges && all finite p) points
            && all (\w -> finite w && w >= 0) weights
        )
        "histogram observations/weights invalid"
    let dims = map ((subtract 1) . length) edges; size = product (map toInteger dims)
    require (size <= 1000000) "histogram size budget exceeded"
    let index p =
            sequence
                [ if x < es !! 0 || x > last es
                    then Nothing
                    else Just (min (length es - 2) (length (takeWhile (<= x) es) - 1))
                | (es, x) <- zip edges p
                ]
        pairs =
            [ (Foldable.foldl' (\a (d, i) -> a * d + i) 0 (zip dims ix), w)
            | (p, w) <- zip points weights
            , Just ix <- [index p]
            ]
    mapM checked [sum [w | (j, w) <- pairs, j == i] | i <- [0 .. fromInteger size - 1]]

validateProbabilities :: [Double] -> Either MathError ()
validateProbabilities ps =
    require
        (not (null ps) && all (\p -> finite p && p >= 0) ps && abs (sum ps - 1) < 1e-10)
        "probabilities must be nonnegative and sum to one"

-- | Shannon entropy in nats for normalized nonnegative probabilities, with 0*log(0)=0.
entropy :: [Double] -> Either MathError Double
entropy ps = do validateProbabilities ps; pure (-sum [if p == 0 then 0 else p * log p | p <- ps])

-- | Mutual information in nats from a rectangular normalized joint-probability table.
mutualInformation :: [[Double]] -> Either MathError Double
mutualInformation joint = do
    require
        (not (null joint) && not (null (joint !! 0)) && all ((== length (joint !! 0)) . length) joint)
        "joint probability shape invalid"
    validateProbabilities (concat joint)
    let rows = map sum joint; cols = map sum (transpose joint)
    pure
        ( sum
            [ if p == 0 then 0 else p * log (p / (rows !! i * cols !! j))
            | (i, row) <- zip [0 ..] joint
            , (j, p) <- zip [0 ..] row
            ]
        )

-- | KL(P||Q) in nats, including positive infinity when Q is zero on positive P mass.
klDivergence :: [Double] -> [Double] -> Either MathError Double
klDivergence p q = do
    validateProbabilities p
    validateProbabilities q
    require (length p == length q) "KL length mismatch"
    pure (sum [if a == 0 then 0 else if b == 0 then 1 / 0 else a * log (a / b) | (a, b) <- zip p q])

-- | Equal-mixture Jensen--Shannon divergence in nats, bounded by log 2.
jsDivergence :: [Double] -> [Double] -> Either MathError Double
jsDivergence p q = do
    let m = zipWith (\a b -> (a + b) / 2) p q
    a <- klDivergence p m
    b <- klDivergence q m
    pure ((a + b) / 2)

-- | Standardize with population standard deviation; constant samples are rejected.
zScores :: [Double] -> Either MathError [Double]
zScores xs = do
    m <- arithmeticMean xs
    s <- populationSD xs
    require (s > 0) "z-scores undefined for constant data"
    pure (map (\x -> (x - m) / s) xs)

-- | Unbiased sample standard deviation divided by sqrt n, requiring n>=2.
standardError :: [Double] -> Either MathError Double
standardError xs = (/ sqrt (fromIntegral (length xs))) <$> sampleSD xs

-- | Two-sided Student-t confidence interval for a normal population mean with unknown variance; confidence level in (0,1).
confidenceInterval :: Double -> [Double] -> Either MathError (Double, Double)
confidenceInterval level xs = do
    require (level > 0 && level < 1) "confidence level outside (0,1)"
    m <- arithmeticMean xs
    se <- standardError xs
    q <- P.quantile (P.StudentT (fromIntegral (length xs - 1))) ((1 + level) / 2)
    pure (m - q * se, m + q * se)

-- | Seeded nonparametric resampling with replacement. Returns caller statistic for each replicate and final RNG state.
bootstrap ::
    Int ->
    ([Double] -> Either MathError Double) ->
    [Double] ->
    R.RNG ->
    Either MathError ([Double], R.RNG)
bootstrap count statistic xs rng = do
    validate 1 xs
    R.sampleN
        count
        (\r -> do (ys, s) <- R.withReplacement (length xs) xs r; v <- statistic ys; pure (v, s))
        rng

-- | Leave-one-out bias-corrected statistic and jackknife standard error; requires n>=2.
jackknife :: ([Double] -> Either MathError Double) -> [Double] -> Either MathError (Double, Double)
jackknife statistic xs = do
    validate 2 xs
    theta <- statistic xs
    ts <- mapM (\i -> statistic (take i xs ++ drop (i + 1) xs)) [0 .. length xs - 1]
    m <- arithmeticMean ts
    let n = fromIntegral (length xs)
     in pure (n * theta - (n - 1) * m, sqrt ((n - 1) / n * sum (map (\t -> (t - m) ^ (2 :: Int)) ts)))

-- | Test statistic, p value clamped to [0,1] after numerical checks, and applicable degrees of freedom.
data TestResult = TestResult
    { testStatistic :: Double
    -- ^ Computed statistic for the selected hypothesis test.
    , pValue :: Double
    -- ^ Reported tail probability, clamped to [0,1]; interpret using the test's documented alternative hypothesis.
    , degreesOfFreedom :: [Double]
    -- ^ Distribution degrees-of-freedom parameters in test-specific order (for example numerator then denominator for F tests).
    }
    deriving (Eq, Show)

result :: Double -> Double -> [Double] -> Either MathError TestResult
result stat p df = do
    _ <- checked stat
    require (finite p) "test p-value not finite"
    pure (TestResult stat (max 0 (min 1 p)) df)
tTail :: Double -> Double -> Either MathError Double
tTail df t = (2 *) <$> P.survival (P.StudentT df) (abs t)
chiTail :: Double -> Double -> Either MathError Double
chiTail df x = P.survival (P.ChiSquare df) x

-- | Two-sided one-sample Student t test against a finite null mean; assumes independent normal observations.
oneSampleT :: Double -> [Double] -> Either MathError TestResult
oneSampleT nullMean xs = do
    m <- arithmeticMean xs
    se <- standardError xs
    require (finite nullMean && se > 0) "t-test positive standard error required"
    let t = (m - nullMean) / se; df = fromIntegral (length xs - 1)
     in do p <- tTail df t; result t p [df]

-- | Two-sided pooled t test when True, Welch unequal-variance test when False; each group requires n>=2 and positive combined variation.
twoSampleT :: Bool -> [Double] -> [Double] -> Either MathError TestResult
twoSampleT equalVariance xs ys = do
    a <- arithmeticMean xs
    b <- arithmeticMean ys
    v <- sampleVariance xs
    w <- sampleVariance ys
    let n = fromIntegral (length xs)
        m = fromIntegral (length ys)
        s1 = v / n
        s2 = w / m
        se =
            if equalVariance
                then sqrt (((n - 1) * v + (m - 1) * w) / (n + m - 2) * (1 / n + 1 / m))
                else sqrt (s1 + s2)
        df =
            if equalVariance
                then n + m - 2
                else (s1 + s2) ^ (2 :: Int) / (s1 * s1 / (n - 1) + s2 * s2 / (m - 1))
        t = (a - b) / se
    require (se > 0) "two-sample t requires positive variance"
    p <- tTail df t
    result t p [df]

-- | Two-sided one-sample t test on paired differences; matching group lengths required.
pairedT :: [Double] -> [Double] -> Either MathError TestResult
pairedT xs ys = do require (length xs == length ys) "paired lengths differ"; oneSampleT 0 (zipWith (-) xs ys)

-- | Two-sided one-sample normal z test with known strictly positive population standard deviation.
zTest :: Double -> Double -> [Double] -> Either MathError TestResult
zTest nullMean knownSD xs = do
    m <- arithmeticMean xs
    require (finite nullMean && finite knownSD && knownSD > 0) "z-test needs positive known SD"
    let z = (m - nullMean) * sqrt (fromIntegral (length xs)) / knownSD
     in do p <- (2 *) <$> P.survival (P.Normal 0 1) (abs z); result z p []

-- | Pearson goodness-of-fit chi-square statistic for observed and positive expected counts; first argument is number of fitted nuisance parameters.
chiSquareTest :: Int -> [Double] -> [Double] -> Either MathError TestResult
chiSquareTest fitted xs expected = do
    validate 2 xs
    validate 2 expected
    require
        ( length xs == length expected
            && all (>= 0) xs
            && all (> 0) expected
            && fitted >= 0
            && length xs > fitted + 1
        )
        "chi-square invalid counts/df"
    let stat = sum (zipWith (\a e -> (a - e) ^ (2 :: Int) / e) xs expected)
        df = fromIntegral (length xs - fitted - 1)
     in do p <- chiTail df stat; result stat p [df]

-- | Two-sided normal-population variance-ratio F test, requiring positive sample variances.
varianceFTest :: [Double] -> [Double] -> Either MathError TestResult
varianceFTest xs ys = do
    a <- sampleVariance xs
    b <- sampleVariance ys
    require (a > 0 && b > 0) "variance F needs positive variances"
    let f = a / b; df1 = fromIntegral (length xs - 1); df2 = fromIntegral (length ys - 1)
     in do p <- P.cdf (P.FisherF df1 df2) f; result f (2 * min p (1 - p)) [df1, df2]

validateGroups :: [[Double]] -> Either MathError ()
validateGroups gs = do require (length gs >= 2) "at least two groups required"; mapM_ (validate 2) gs

-- | One-way fixed-effects F test on independent normal groups with common variance; each group requires n>=2.
anova :: [[Double]] -> Either MathError TestResult
anova gs = do
    validateGroups gs
    overall <- arithmeticMean (concat gs)
    means <- mapM arithmeticMean gs
    let k = length gs
        n = sum (map length gs)
        between = sum [fromIntegral (length g) * (m - overall) ^ (2 :: Int) | (g, m) <- zip gs means]
        within = sum [sum (map (\x -> (x - m) ^ (2 :: Int)) g) | (g, m) <- zip gs means]
        df1 = fromIntegral (k - 1)
        df2 = fromIntegral (n - k)
        f = (between / df1) / (within / df2)
    require (within > 0) "ANOVA needs within-group variation"
    p <- P.survival (P.FisherF df1 df2) f
    result f p [df1, df2]

-- | Welch one-way heteroscedastic F test with Satterthwaite denominator degrees of freedom.
welchAnova :: [[Double]] -> Either MathError TestResult
welchAnova gs = do
    validateGroups gs
    ms <- mapM arithmeticMean gs
    vs <- mapM sampleVariance gs
    require (all (> 0) vs) "Welch ANOVA needs positive group variances"
    let ns = map (fromIntegral . length) gs
        k = fromIntegral (length gs)
        ws = zipWith (/) ns vs
        total = sum ws
        m = sum (zipWith (*) ws ms) / total
        s = sum [((1 - w / total) ^ (2 :: Int)) / (n - 1) | (w, n) <- zip ws ns]
        f =
            (sum (zipWith (\w u -> w * (u - m) ^ (2 :: Int)) ws ms) / (k - 1))
                / (1 + 2 * (k - 2) / (k * k - 1) * s)
        df = (k * k - 1) / (3 * s)
    p <- P.survival (P.FisherF (k - 1) df) f
    result f p [k - 1, df]

tieCorrection :: [Double] -> Double
tieCorrection xs =
    let n = fromIntegral (length xs)
     in 1
            - sum [fromIntegral (length g) ^ (3 :: Int) - fromIntegral (length g) | g <- group (sort xs)]
                / (n * n * n - n)

-- | Tie-corrected Kruskal--Wallis H statistic with chi-square asymptotic calibration.
kruskalWallis :: [[Double]] -> Either MathError TestResult
kruskalWallis gs = do
    validateGroups gs
    let xs = concat gs
        rs = ranks xs
        offsets = scanl (+) 0 (map length gs)
        n = fromIntegral (length xs)
        c = tieCorrection xs
        h =
            ( 12
                / (n * (n + 1))
                * sum
                    [ (sum (take (length g) (drop off rs))) ^ (2 :: Int) / fromIntegral (length g)
                    | (g, off) <- zip gs offsets
                    ]
                - 3 * (n + 1)
            )
                / c
        df = fromIntegral (length gs - 1)
    require (c > 0) "Kruskal-Wallis requires nonconstant ranks"
    p <- chiTail df h
    result h p [df]

-- | Mann--Whitney U for the first sample; two-sided tie-corrected normal approximation with continuity correction.
mannWhitney :: [Double] -> [Double] -> Either MathError TestResult
mannWhitney xs ys = do
    validate 1 xs
    validate 1 ys
    let n = fromIntegral (length xs)
        m = fromIntegral (length ys)
        u = sum (take (length xs) (ranks (xs ++ ys))) - n * (n + 1) / 2
        v = n * m * (n + m + 1) / 12 * tieCorrection (xs ++ ys)
        z = (abs (u - n * m / 2) - 0.5) / sqrt v
     in do
            require (v > 0) "Mann-Whitney constant ranks"
            p <- (2 *) <$> P.survival (P.Normal 0 1) (max 0 z)
            result u p []

-- | Wilcoxon signed-rank test for differences, dropping zeros and using average absolute tied ranks and continuity-corrected normal calibration.
wilcoxon :: [Double] -> Either MathError TestResult
wilcoxon differences = do
    validate 1 differences
    let xs = filter (/= 0) differences
        n = fromIntegral (length xs)
        rs = ranks (map abs xs)
        plus = sum [r | (x, r) <- zip xs rs, x > 0]
        mu = n * (n + 1) / 4
        ties =
            sum
                [fromIntegral (length g) ^ (3 :: Int) - fromIntegral (length g) | g <- group (sort (map abs xs))]
        v = n * (n + 1) * (2 * n + 1) / 24 - ties / 48
        z = max 0 (abs (plus - mu) - 0.5) / sqrt v
    require (v > 0) "Wilcoxon needs nonzero differences"
    p <- (2 *) <$> P.survival (P.Normal 0 1) z
    result (min plus (n * (n + 1) / 2 - plus)) p []

-- | Two-sided KS statistic and asymptotic p value against a fully specified continuous distribution. A Jacobi theta transformation handles very small statistics. Fitting parameters from these observations invalidates this null calibration.
kolmogorovSmirnov :: P.Distribution -> [Double] -> Either MathError TestResult
kolmogorovSmirnov d xs = do
    stat <- P.goodnessOfFit d xs
    let root = sqrt (fromIntegral (length xs))
        z = (root + 0.12 + 0.11 / root) * stat
        -- Jacobi's theta transformation converges for small z, where a fixed
        -- alternating survival sum would need thousands or millions of terms.
        probability
            | z == 0 = 1
            | z < 1.18 =
                1
                    - sqrt (2 * pi)
                        / z
                        * sum [exp (-pi * pi * fromIntegral ((2 * k - 1) ^ (2 :: Int)) / (8 * z * z)) | k <- [1 .. 20 :: Int]]
            | otherwise =
                2
                    * sum [(if odd k then 1 else -1) * exp (-2 * fromIntegral (k * k) * z * z) | k <- [1 .. 100 :: Int]]
    result stat probability []

{- | Royston's AS R94 coefficients and normal-tail approximation, n=3..5000,
uncensored samples. Numerical constants are published statistical data.
Reference: https://doi.org/10.2307/2986146
-}
shapiroWilk :: [Double] -> Either MathError TestResult
shapiroWilk xs = do
    validate 3 xs
    require (length xs <= 5000) "Shapiro-Wilk supports n<=5000"
    let n = length xs
        an = fromIntegral n
        half = n `div` 2
        ys = sort xs
        poly cs z = sum [c * z ^ i | (i, c) <- zip [0 :: Int ..] cs]
    v <- populationVariance xs
    require (v > 0) "Shapiro-Wilk needs nonconstant observations"
    coeff <-
        if n == 3
            then pure [sqrt 0.5]
            else do
                zs <- mapM (\i -> S.normalQuantile ((fromIntegral i - 0.375) / (an + 0.25))) [1 .. half]
                let sumsq = 2 * sum (map (\z -> z * z) zs)
                    scale = sqrt sumsq
                    r = 1 / sqrt an
                    a1 = poly [0, 0.221157, -0.147981, -2.071190, 4.434685, -2.706056] r - zs !! 0 / scale
                    a2 = poly [0, 0.042981, -0.293762, -1.752461, 5.682633, -3.582633] r - zs !! 1 / scale
                    start = if n > 5 then 2 else 1
                    adjust =
                        if n > 5
                            then
                                sqrt
                                    ((sumsq - 2 * (zs !! 0) ^ (2 :: Int) - 2 * (zs !! 1) ^ (2 :: Int)) / (1 - 2 * a1 * a1 - 2 * a2 * a2))
                            else sqrt ((sumsq - 2 * (zs !! 0) ^ (2 :: Int)) / (1 - 2 * a1 * a1))
                pure (take start [a1, a2] ++ map (\z -> -z / adjust) (drop start zs))
    let numerator = sum [a * (ys !! (n - i - 1) - ys !! i) | (i, a) <- zip [0 ..] coeff]
        w = max 0 (min 1 (numerator * numerator / (an * v)))
    p <-
        if n == 3
            then pure (1 - 6 / pi * acos (sqrt w))
            else do
                let y = log (max 1e-300 (1 - w))
                    g = -2.273 + 0.459 * an
                    small = n <= 11
                    transformed = if small then -log (g - y) else y
                    mu =
                        if small
                            then poly [0.544, -0.39978, 0.025054, -0.0006714] an
                            else poly [-1.5861, -0.31082, -0.083751, 0.0038915] (log an)
                    sd =
                        exp
                            ( if small
                                then poly [1.3822, -0.77857, 0.062767, -0.0020322] an
                                else poly [-0.4803, -0.082676, 0.0030302] (log an)
                            )
                if small && y >= g then pure 1e-99 else P.survival (P.Normal mu sd) transformed
    result w p []

{- | Anderson--Darling normality test after fitting the sample mean and unbiased
sample standard deviation. The returned statistic is raw A²; Stephens' p-value
approximation uses A²*(1+0.75/n+2.25/n²). For adjusted A²>13, the published
approximation is outside its calibrated range and the extreme tail is
reported as zero instead of extrapolating its quadratic back upward.
-}
andersonDarling :: [Double] -> Either MathError TestResult
andersonDarling xs = do
    validate 5 xs
    mean <- arithmeticMean xs
    sd <- sampleSD xs
    let d = P.Normal mean sd
    ps <- mapM (P.cdf d) (sort xs)
    let n = length xs
        an = fromIntegral n
        a =
            -an
                - sum
                    [ fromIntegral (2 * i + 1) * (log (max 1e-300 probability) + log (max 1e-300 (1 - ps !! (n - i - 1))))
                    | (i, probability) <- zip [0 ..] ps
                    ]
                    / an
        adjust = a * (1 + 0.75 / an + 2.25 / (an * an))
        p
            | adjust < 0.2 = 1 - exp (-13.436 + 101.14 * adjust - 223.73 * adjust * adjust)
            | adjust < 0.34 = 1 - exp (-8.318 + 42.796 * adjust - 59.938 * adjust * adjust)
            | adjust < 0.6 = exp (0.9177 - 4.279 * adjust - 1.38 * adjust * adjust)
            | adjust <= 13 = exp (1.2937 - 5.709 * adjust + 0.0186 * adjust * adjust)
            | otherwise = 0
    result a p []

-- | One-way ANOVA on absolute deviations; True chooses group medians (Brown--Forsythe), False chooses means.
levene :: Bool -> [[Double]] -> Either MathError TestResult
levene useMedian gs = do
    validateGroups gs
    centers <- mapM (if useMedian then median else arithmeticMean) gs
    anova [map (\x -> abs (x - c)) g | (g, c) <- zip gs centers]

-- | Bartlett homogeneity-of-variance test, appropriate for normal samples; positive group variances required.
bartlett :: [[Double]] -> Either MathError TestResult
bartlett gs = do
    validateGroups gs
    vs <- mapM sampleVariance gs
    require (all (> 0) vs) "Bartlett requires positive group variances"
    let ds = map (fromIntegral . subtract 1 . length) gs
        total = sum ds
        k = fromIntegral (length gs)
        pooled = sum (zipWith (*) ds vs) / total
        stat =
            (total * log pooled - sum (zipWith (\d v -> d * log v) ds vs))
                / (1 + (sum (map (1 /) ds) - 1 / total) / (3 * (k - 1)))
     in do p <- chiTail (k - 1) stat; result stat p [k - 1]

-- | Two-sided Fisher exact test on nonnegative 2-by-2 counts (a,b;c,d). Enumerates tables with mass no larger than the observed table.
fisherExact :: Int -> Int -> Int -> Int -> Either MathError TestResult
fisherExact a b c d = do
    require
        (all (>= 0) [a, b, c, d] && a + b + c + d > 0 && a + b + c + d <= 100000)
        "Fisher counts invalid"
    let dist = P.Hypergeometric (a + b + c + d) (a + c) (a + b)
        lo = max 0 (a - d)
        hi = min (a + b) (a + c)
     in do
            p0 <- P.density dist (fromIntegral a)
            ps <- mapM (P.density dist . fromIntegral) [lo .. hi]
            let odds =
                    if b * c == 0
                        then if a * d == 0 then 0 else 1e300
                        else fromIntegral a * fromIntegral d / (fromIntegral b * fromIntegral c)
             in result odds (sum (filter (<= p0 * (1 + 1e-12)) ps)) []

-- | Seeded two-sided random-label permutation p value for a caller statistic, with the (b+1)/(B+1) correction.
permutationTest ::
    Int ->
    ([Double] -> [Double] -> Either MathError Double) ->
    [Double] ->
    [Double] ->
    R.RNG ->
    Either MathError (TestResult, R.RNG)
permutationTest count statistic xs ys rng = do
    validate 1 xs
    validate 1 ys
    require (count > 0 && count <= 1000000) "permutation count outside budget"
    observed <- statistic xs ys
    (values, s) <-
        R.sampleN
            count
            ( \r -> do
                (z, t) <- R.shuffle (xs ++ ys) r
                v <- statistic (take (length xs) z) (drop (length xs) z)
                pure (v, t)
            )
            rng
    res <-
        result
            observed
            (fromIntegral (1 + length (filter (\v -> abs v >= abs observed) values)) / fromIntegral (count + 1))
            []
    pure (res, s)

-- | Bonferroni-adjusted p values in original order, capped at one.
bonferroni :: [Double] -> Either MathError [Double]
bonferroni ps = do
    require (all (\p -> finite p && p >= 0 && p <= 1) ps) "invalid p-values"
    pure (map (min 1 . (* fromIntegral (length ps))) ps)

-- | Monotone Benjamini--Hochberg FDR-adjusted p values in original order.
benjaminiHochberg :: [Double] -> Either MathError [Double]
benjaminiHochberg ps = do
    _ <- bonferroni ps
    let ordered = sortOn snd (zip [0 :: Int ..] ps)
        n = length ps
        adjusted =
            reverse
                ( snd
                    ( Foldable.foldl'
                        ( \(previous, acc) (rank, (i, p)) -> let q = min previous (p * fromIntegral n / fromIntegral rank) in (q, (i, q) : acc)
                        )
                        (1, [])
                        (reverse (zip [1 :: Int ..] ordered))
                    )
                )
    pure (map snd (sortOn fst adjusted))

-- | Difference of sample means divided by pooled unbiased standard deviation.
cohensD :: [Double] -> [Double] -> Either MathError Double
cohensD xs ys = do
    a <- arithmeticMean xs
    b <- arithmeticMean ys
    v <- sampleVariance xs
    w <- sampleVariance ys
    let pooled =
            ( (fromIntegral (length xs - 1) * v + fromIntegral (length ys - 1) * w)
                / fromIntegral (length xs + length ys - 2)
            )
     in require (pooled > 0) "Cohen d needs nonzero pooled variance" >> checked ((a - b) / sqrt pooled)

-- | One-way ANOVA explained sum of squares divided by total sum of squares.
etaSquared :: [[Double]] -> Either MathError Double
etaSquared gs = do
    validateGroups gs
    m <- arithmeticMean (concat gs)
    ms <- mapM arithmeticMean gs
    let between = sum [fromIntegral (length g) * (u - m) ^ (2 :: Int) | (g, u) <- zip gs ms]
        total = sum (map (\x -> (x - m) ^ (2 :: Int)) (concat gs))
     in require (total > 0) "eta squared needs nonconstant data" >> checked (between / total)

-- | Exact power under a known-variance two-sided one-sample normal z-test.
normalTestPower :: Double -> Double -> Int -> Either MathError Double
normalTestPower alpha standardizedEffect n = do
    require
        (alpha > 0 && alpha < 1 && finite standardizedEffect && n > 0)
        "power invalid alpha/effect/n"
    q <- S.normalQuantile (1 - alpha / 2)
    let shift = standardizedEffect * sqrt (fromIntegral n)
     in do a <- S.normalCDF (-q - shift); b <- P.survival (P.Normal 0 1) (q - shift); pure (a + b)

-- | Smallest integer n whose exact known-variance two-sided normal-test power meets the target; hard budget n<=100000000.
normalSampleSize :: Double -> Double -> Double -> Either MathError Int
normalSampleSize alpha power effect = do
    require
        (alpha > 0 && alpha < 1 && power > alpha && power < 1 && finite effect && effect /= 0)
        "sample size invalid alpha/power/effect"
    let go lo hi
            | hi > 100000000 = do
                p <- normalTestPower alpha effect 100000000
                if p >= power then search lo 100000000 else Left (NonConvergence "sample size budget" 100000000)
            | otherwise = do p <- normalTestPower alpha effect hi; if p >= power then search lo hi else go hi (hi * 2)
        search lo hi
            | hi - lo <= 1 = pure hi
            | otherwise =
                let m = lo + (hi - lo) `div` 2
                 in do p <- normalTestPower alpha effect m; if p >= power then search lo m else search m hi
    p1 <- normalTestPower alpha effect 1
    if p1 >= power then pure 1 else go 1 2

-- | Zero-based indices outside [Q1-k*IQR,Q3+k*IQR], with positive multiplier k and type-7 quartiles.
tukeyOutliers :: Double -> [Double] -> Either MathError [Int]
tukeyOutliers multiplier xs = do
    require (finite multiplier && multiplier > 0) "Tukey multiplier must be positive"
    q1 <- quantile 0.25 xs
    q3 <- quantile 0.75 xs
    let iqr = q3 - q1
     in pure [i | (i, x) <- zip [0 ..] xs, x < q1 - multiplier * iqr || x > q3 + multiplier * iqr]

-- | Two-sided single-outlier Grubbs test, returning candidate index, G statistic and rejection decision at alpha; normality assumption required.
grubbs :: Double -> [Double] -> Either MathError (Int, Double, Bool)
grubbs alpha xs = do
    validate 3 xs
    require (alpha > 0 && alpha < 1) "Grubbs alpha outside (0,1)"
    m <- arithmeticMean xs
    s <- sampleSD xs
    require (s > 0) "Grubbs needs nonconstant data"
    let n = fromIntegral (length xs)
        distances = map (\x -> abs (x - m) / s) xs
        g = maximum distances
        i = length (takeWhile (< g) distances)
     in do
            t <- P.quantile (P.StudentT (n - 2)) (1 - alpha / (2 * n))
            let critical = (n - 1) / sqrt n * sqrt (t * t / (n - 2 + t * t)) in pure (i, g, g > critical)

-- | Keep True-mask observations, then validate retained values. Excluded NaN/infinity do not contaminate results.
masked :: [Bool] -> [Double] -> Either MathError [Double]
masked mask xs = do
    require (length mask == length xs) "mask length mismatch"
    let ys = [x | (keep, x) <- zip mask xs, keep] in validate 1 ys >> pure ys

-- | Huber M location by iteratively reweighted means, scaled by 1.4826*MAD; zero MAD returns the median. Positive tuning and finite data required.
huberLocation :: Double -> [Double] -> Either MathError Double
huberLocation tuning xs = do
    require (finite tuning && tuning > 0) "Huber tuning positive required"
    m <- median xs
    mad <- medianAbsoluteDeviation xs
    let scale = 1.4826 * mad
        go :: Int -> Double -> Either MathError Double
        go 0 _ = Left (NonConvergence "Huber location" 1000)
        go n u = do
            let ws = map (\x -> let r = abs ((x - u) / scale) in if r <= tuning then 1 else tuning / r) xs
            v <- weightedMean xs ws
            if abs (v - u) <= 1e-10 * max 1 (abs u) then pure v else go (n - 1) v
    if mad == 0 then pure m else go 1000 m
