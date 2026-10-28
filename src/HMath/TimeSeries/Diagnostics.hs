-- SPDX-License-Identifier: MPL-2.0

{- | Explicit-lag stationarity statistics, bounded change-point/warping
reference algorithms, and forecast diagnostics. Statistical critical values
are model-dependent approximations, not guarantees of stationarity.
-}
module HMath.TimeSeries.Diagnostics (
    Deterministic (..),
    Stationarity (..),
    augmentedDickeyFuller,
    kpss,
    changePoints,
    cusum,
    anomalies,
    DTWResult (..),
    dynamicTimeWarping,
    spectrum,
    ForecastMetric (..),
    forecastError,
) where

import Control.Monad (foldM)
import Data.Array (Array, array, (!))
import Data.Complex (Complex ((:+)), magnitude)
import Data.List (minimumBy, transpose)
import Data.Ord (comparing)
import HMath.Error
import qualified HMath.Fourier as F
import qualified HMath.Matrix as M
import qualified HMath.Matrix.LU as LU
import qualified HMath.Matrix.QR as QR
import qualified HMath.Statistics.Advanced as Stats
import HMath.TimeSeries.Core

-- | Stationarity-test deterministic terms: level-only or linear-trend specification.
data Deterministic = Level | LinearTrend deriving (Eq, Show)

{- | Significance level paired with critical value. ADF rejects for smaller
statistics, KPSS for larger ones. No interpolated p value is fabricated.
-}
data Stationarity = Stationarity
    { stationarityStatistic :: Double
    -- ^ Computed ADF/KPSS stationarity test statistic.
    , stationarityCriticalValues :: [(Double, Double)]
    -- ^ Significance-level and critical-value pairs for the selected test/deterministic specification.
    , stationarityObservations :: Int
    -- ^ Number of effective observations used by the test.
    , stationarityNull :: String
    -- ^ Human-readable null hypothesis, which differs between ADF and KPSS.
    }
    deriving (Eq, Show)

{- | OLS of delta x_t on x_(t-1), an intercept, optional trend, and explicitly
supplied lagged differences. Returns the lagged-level t statistic. Critical
values use MacKinnon (2010) finite-sample polynomials for one series:
https://www.statsmodels.org/stable/generated/statsmodels.tsa.stattools.adfuller.html .
There is no automatic lag selection or normal/Student-t p-value shortcut.
-}
augmentedDickeyFuller :: Deterministic -> Int -> [Double] -> Either MathError Stationarity
augmentedDickeyFuller deterministic lags xs = do
    validate 4 xs
    require (lags >= 0 && lags <= 64 && length xs <= 4096) "ADF lag/sample limit"
    let deltas = zipWith (-) ((drop 1) xs) xs
        rows =
            [ xs !! t
                : deterministicRow deterministic (fromIntegral (t + 1))
                ++ [deltas !! (t - j) | j <- [1 .. lags]]
            | t <- [lags .. length deltas - 1]
            ]
        target = drop lags deltas
        n = length target
        width = lags + 2 + if deterministic == LinearTrend then 1 else 0
    require (n > width) "insufficient ADF residual degrees of freedom"
    (b, residual, gramInverse) <- regression rows target
    let variance = sum (map (^ (2 :: Int)) residual) / fromIntegral (n - width)
        se = sqrt (variance * (!! 0) ((!! 0) gramInverse))
    require (finite se && se > 0) "degenerate ADF residual variance"
    stat <- (!! 0) <$> checked [(!! 0) b / se]
    let coefficients =
            if deterministic == Level
                then
                    [ [-3.43035, -6.5393, -16.786, -79.433]
                    , [-2.86154, -2.8903, -4.234, -40.040]
                    , [-2.56677, -1.5384, -2.809, 0]
                    ]
                else
                    [ [-3.95877, -9.0531, -28.428, -134.155]
                    , [-3.41049, -4.3904, -9.036, -45.374]
                    , [-3.12705, -2.5856, -3.925, -22.380]
                    ]
        critical row = sum [v / (fromIntegral n ^ k) | (k, v) <- zip [0 :: Int ..] row]
    Right (Stationarity stat (zip [0.01, 0.05, 0.1] (map critical coefficients)) n "unit root")

{- | KPSS level/trend stationarity with an explicit Bartlett/Newey--West lag
bandwidth. Critical values are Table 1 of Kwiatkowski et al. (1992), as
documented at https://www.statsmodels.org/stable/generated/statsmodels.tsa.stattools.kpss.html .
-}
kpss :: Deterministic -> Int -> [Double] -> Either MathError Stationarity
kpss deterministic lags xs = do
    validate 4 xs
    require
        ( lags >= 0
            && lags < length xs
            && length xs <= 4096
            && toInteger lags * toInteger (length xs) <= 4000000
        )
        "KPSS lag/sample limit"
    let n = length xs; nf = fromIntegral n
    residual <- case deterministic of
        Level -> Right (map (subtract (average xs)) xs)
        LinearTrend -> do
            (_, rs, _) <- regression [deterministicRow deterministic (fromIntegral i) | i <- [1 .. n]] xs
            Right rs
    let energy = sum (map (^ (2 :: Int)) residual)
        longRun =
            ( energy
                + 2
                    * sum
                        [ (1 - fromIntegral k / fromIntegral (lags + 1)) * sum (zipWith (*) (drop k residual) residual)
                        | k <- [1 .. lags]
                        ]
            )
                / nf
        partial = (drop 1) (scanl (+) 0 residual)
    require (finite longRun && longRun > 1e-28 * max 1 energy) "degenerate KPSS long-run variance"
    stat <- (!! 0) <$> checked [sum (map (^ (2 :: Int)) partial) / (nf * nf * longRun)]
    let critical = if deterministic == Level then [0.347, 0.463, 0.574, 0.739] else [0.119, 0.146, 0.176, 0.216]
    Right (Stationarity stat (zip [0.1, 0.05, 0.025, 0.01] critical) n "stationarity")

deterministicRow :: Deterministic -> Double -> [Double]
deterministicRow Level _ = [1]
deterministicRow LinearTrend t = [1, t]
regression :: [[Double]] -> [Double] -> Either MathError ([Double], [Double], [[Double]])
regression rows target = do
    let n = length rows; p = length ((!! 0) rows)
    matrix <- M.fromListChecked n p (concat rows)
    b <- QR.leastSquares matrix target
    let residual = zipWith (-) target [sum (zipWith (*) row b) | row <- rows]
        gram = [[sum (zipWith (*) a c) | c <- transpose rows] | a <- transpose rows]
    gm <- M.fromListChecked p p (concat gram)
    inverse <- LU.inverse gm
    let iv = [take p (drop (i * p) (M.toList inverse)) | i <- [0 .. p - 1]]
    _ <- checked (b ++ residual ++ concat iv)
    Right (b, residual, iv)

{- | Exact quadratic dynamic programming for piecewise-constant least squares,
minimizing total within-segment SSE plus penalty per change. Break indices
are zero-based starts of new segments. No pruning/approximation is used.
-}
changePoints :: Double -> Int -> [Double] -> Either MathError [Int]
changePoints penalty minSegment xs = do
    validate 1 xs
    let n = length xs
    require
        (finite penalty && penalty >= 0 && minSegment >= 1 && minSegment <= n && n <= 2048)
        "change-point configuration/sample limit"
    -- Centering before prefix sums avoids severe cancellation for shifted data.
    let centered = map (subtract (average xs)) xs
        sums = prefix centered
        squares = prefix (map (^ (2 :: Int)) centered)
        cost i j =
            let s = sums ! j - sums ! i; q = squares ! j - squares ! i
             in max 0 (q - (s / sqrt (fromIntegral (j - i))) ^ (2 :: Int))
        solution :: Array Int (Double, [Int])
        solution = array (0, n) [(j, entry j) | j <- [0 .. n]]
        entry 0 = (-penalty, [])
        entry j = case [ (base + cost i j + penalty, if i == 0 then [] else breaks ++ [i])
                       | i <- [0 .. j - minSegment]
                       , i == 0 || i >= minSegment
                       , let (base, breaks) = solution ! i
                       , finite base
                       ] of
            [] -> (1 / 0, [])
            candidates -> minimumBy (comparing fst) candidates
    _ <- checked (centered ++ elemsOf sums ++ elemsOf squares)
    let (value, breaks) = solution ! n
    _ <- checked [value]
    Right breaks
  where
    prefix ys = array (0, length ys) (zip [0 ..] (scanl (+) 0 ys))
    elemsOf a = [a ! i | i <- [0 .. length xs]]

{- | Two-sided Page CUSUM with supplied baseline mean/SD. A threshold crossing
emits its index and resets both cumulative scores. drift and threshold are
in standardized observation units.
-}
cusum :: Double -> Double -> Double -> Double -> [Double] -> Either MathError [Int]
cusum mean sd drift threshold xs = do
    validate 0 xs
    require
        (all finite [mean, sd, drift, threshold] && sd > 0 && drift >= 0 && threshold > 0)
        "invalid CUSUM parameters"
    let step (plus, minus, alerts) (i, x) = do
            let z = (x - mean) / sd
            _ <- checked [z]
            -- Exact three-term accumulation avoids overflow before a cancelling
            -- drift. Validate the rounded scores before a threshold can reset them.
            let score old delta = fromRational (max 0 (toRational old + toRational delta - toRational drift))
                p = score plus z
                m = score minus (-z)
            _ <- checked [p, m]
            Right (if max p m > threshold then (0, 0, i : alerts) else (p, m, alerts))
    (_, _, finalAlerts) <- foldM step (0, 0, []) (zip [0 ..] xs)
    Right (reverse finalAlerts)

{- | Median/MAD outliers, using the normal-consistency factor 1.4826022185.
If MAD is zero, every value different from the median is an anomaly.
-}
anomalies :: Double -> [Double] -> Either MathError [Int]
anomalies threshold xs = do
    validate 1 xs
    require (finite threshold && threshold > 0) "positive anomaly threshold required"
    median <- Stats.median xs
    mad <- Stats.median (map (abs . subtract median) xs)
    differences <- checked (map (subtract median) xs)
    scores <-
        if mad == 0
            then Right (replicate (length xs) 0)
            else checked [abs delta / mad / 1.4826022185 | delta <- differences]
    Right
        [i | (i, (x, z)) <- zip [0 ..] (zip xs scores), if mad == 0 then x /= median else z > threshold]

{- | Dynamic-time-warping accumulated distance and original-series zero-based alignment
path.
-}
data DTWResult = DTWResult
    { dtwDistance :: Double
    -- ^ Accumulated dynamic-time-warping path cost.
    , dtwPath :: [(Int, Int)]
    -- ^ Optimal alignment as zero-based index pairs from the two input series.
    }
    deriving (Eq, Show)

{- | Absolute local cost; Sakoe--Chiba radius must include both endpoints.
Returns the unnormalized path cost, with diagonal/up/left tie priority.
-}
dynamicTimeWarping :: Int -> [Double] -> [Double] -> Either MathError DTWResult
dynamicTimeWarping radius xs ys = do
    validate 1 xs
    validate 1 ys
    let n = length xs; m = length ys
    require (n <= 512 && m <= 512 && radius >= abs (n - m) && radius <= 16384) "DTW size/radius limit"
    let table :: Array (Int, Int) (Double, (Int, Int))
        table = array ((0, 0), (n, m)) [((i, j), entry i j) | i <- [0 .. n], j <- [0 .. m]]
        entry 0 0 = (0, (0, 0))
        entry i j
            | i == 0 || j == 0 || abs (i - j) > radius = (1 / 0, (0, 0))
            | otherwise =
                let choices = [(fst (table ! (a, b)), (a, b)) | (a, b) <- [(i - 1, j - 1), (i - 1, j), (i, j - 1)]]
                    (cost, predecessor) = minimumBy (comparing fst) choices
                 in (cost + abs (xs !! (i - 1) - ys !! (j - 1)), predecessor)
        trace (0, 0) acc = acc
        trace ij@(i, j) acc = trace (snd (table ! ij)) ((i - 1, j - 1) : acc)
        distance = fst (table ! (n, m))
    _ <- checked [distance]
    Right (DTWResult distance (trace (n, m) []))

{- | One-sided unwindowed periodogram density. Non-DC/Nyquist bins are doubled;
integral of density over frequency equals the sample mean square.
-}
spectrum :: Double -> [Double] -> Either MathError [(Double, Double)]
spectrum sampleRate xs = do
    validate 1 xs
    require (finite sampleRate && sampleRate > 0) "positive sample rate required"
    bins <- F.fft (map (:+ 0) xs)
    let n = length xs
        density =
            [ ( fromIntegral k * sampleRate / fromIntegral n
              , magnitude (bins !! k) ^ (2 :: Int)
                    / (sampleRate * fromIntegral n)
                    * (if k == 0 || even n && k == n `div` 2 then 1 else 2)
              )
            | k <- [0 .. n `div` 2]
            ]
    _ <- checked (concatMap (\(a, b) -> [a, b]) density)
    Right density

{- | Prediction-error metric selector; scale/zero-denominator preconditions are checked by
the metric function.
-}
data ForecastMetric = MAE | MSE | RMSE | MAPE | SMAPE | MASE Int [Double] deriving (Eq, Show)

{- | MAPE and sMAPE are percentages; zero/zero sMAPE contributes zero. MASE
supplies its separate training set and seasonal lag to avoid test leakage.
-}
forecastError :: ForecastMetric -> [Double] -> [Double] -> Either MathError Double
forecastError metric actual predicted = do
    validate 1 actual
    validate 1 predicted
    require (length actual == length predicted) "forecast metric length mismatch"
    let errors = zipWith (-) predicted actual; mse = average (map (^ (2 :: Int)) errors)
    value <- case metric of
        MAE -> Right (average (map abs errors))
        MSE -> Right mse
        RMSE -> Right (sqrt mse)
        MAPE -> do
            require (all (/= 0) actual) "MAPE actual values must be nonzero"
            Right (100 * average (zipWith (\e x -> abs (e / x)) errors actual))
        SMAPE ->
            Right
                ( 100
                    * average
                        [ if x == 0 && y == 0
                            then 0
                            else 2 * abs (x / scale - y / scale) / (abs (x / scale) + abs (y / scale))
                        | (x, y) <- zip actual predicted
                        , let scale = max (abs x) (abs y)
                        ]
                )
        MASE lag training -> do
            deltas <- difference 1 lag training
            let scale = average (map abs deltas)
            require (finite scale && scale > 0) "MASE requires nonzero training scale"
            Right (average (map abs errors) / scale)
    (!! 0) <$> checked [value]
