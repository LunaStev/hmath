-- SPDX-License-Identifier: MPL-2.0

{- | Timestamped finite observations. Times are caller-defined numeric units,
strictly increasing, with explicit missing values. No implicit calendar, time
zone, sorting, duplicate aggregation, or extrapolation occurs. Reference
operations accept at most 16,384 observations; quadratic operations impose
tighter bounds. A regular series is a timestamped series with a positive step.
-}
module HMath.TimeSeries.Core (
    Series,
    series,
    regularSeries,
    observations,
    seriesValues,
    isRegular,
    Alignment (..),
    align,
    Fill (..),
    fillMissing,
    Resampling (..),
    resample,
    Rolling (..),
    rolling,
    exponentialAverage,
    weightedAverage,
    cumulativeReturns,
    logarithmicReturns,
    difference,
    autocorrelation,
    crossCorrelation,
    durbinLevinson,
    yuleWalker,
    partialAutocorrelation,
    finite,
    require,
    checked,
    validate,
    average,
) where

import qualified Data.Map.Strict as M
import Data.Maybe (catMaybes)
import HMath.Error

-- | Opaque, validated timestamps paired with optional observations.
newtype Series = Series [(Double, Maybe Double)] deriving (Eq, Show)

-- | Test whether Double is neither NaN nor infinite.
finite :: Double -> Bool
finite x = not (isNaN x || isInfinite x)

{- | Given predicate then message, return Right () or time-series-prefixed Left
InvalidArgument.
-}
require :: Bool -> String -> Either MathError ()
require p s = if p then Right () else Left (InvalidArgument ("time series: " ++ s))

{- | Return list unchanged when every sample is finite; otherwise return Left
NonFiniteResult.
-}
checked :: [Double] -> Either MathError [Double]
checked xs = if all finite xs then Right xs else Left NonFiniteResult

{- | Given minimum sample count then list, require length between that minimum and 16384 and
all finite values. Invalid input returns Left InvalidArgument.
-}
validate :: Int -> [Double] -> Either MathError ()
validate n xs =
    require
        (length xs >= n && length xs <= 16384 && all finite xs)
        "finite sample count outside supported range"

{- | Unchecked arithmetic average using per-term division by list length; empty list returns
zero by empty sum. Checked statistical callers validate nonempty input first.
-}
average :: [Double] -> Double
average xs = sum (map (/ fromIntegral (length xs)) xs)

-- | Preserve order and missing values; reject duplicate or nonfinite times.
series :: [(Double, Maybe Double)] -> Either MathError Series
series xs = do
    require (length xs <= 16384) "too many observations"
    require (all (finite . fst) xs && all finite (catMaybes (map snd xs))) "nonfinite observation"
    require (and (zipWith (<) (map fst xs) (drop 1 (map fst xs)))) "timestamps must strictly increase"
    Right (Series xs)

-- | Sample times start+i*step. Rounded duplicate times are rejected as well.
regularSeries :: Double -> Double -> [Maybe Double] -> Either MathError Series
regularSeries start step xs = do
    require (finite start && finite step && step > 0) "finite start and positive step required"
    series (zip [start + fromIntegral i * step | i <- [0 :: Int .. length xs - 1]] xs)

{- | Extract time-ordered (timestamp,Maybe value) observations from a validated Series.
Missing values remain Nothing.
-}
observations :: Series -> [(Double, Maybe Double)]
observations (Series xs) = xs

-- | Complete-data conversion never silently drops a missing observation.
seriesValues :: Series -> Either MathError [Double]
seriesValues (Series xs) = mapM (maybe (Left (InvalidArgument "time series: missing observation")) Right . snd) xs

-- | Relative spacing tolerance; fewer than three observations are regular.
isRegular :: Double -> Series -> Either MathError Bool
isRegular tolerance (Series xs) = do
    require (finite tolerance && tolerance >= 0) "invalid spacing tolerance"
    let steps = zipWith (-) (drop 1 (map fst xs)) (map fst xs)
    _ <- checked steps
    Right
        (case steps of [] -> True; d : ds -> all (\x -> abs (x - d) <= tolerance * max (abs d) (abs x)) ds)

{- | Time-series timestamp join policy: Inner intersection or Outer union,with missing
values explicit.
-}
data Alignment = Inner | Outer | LeftAligned deriving (Eq, Show)

-- | Exact timestamp equality. Missing alignment positions are explicit Nothing.
align :: Alignment -> Series -> Series -> Either MathError (Series, Series)
align mode (Series a) (Series b) = do
    let am = M.fromList a
        bm = M.fromList b
        times = case mode of
            Inner -> M.keys (M.intersection am bm)
            Outer -> M.keys (M.union am bm)
            LeftAligned -> M.keys am
    x <- series [(t, M.findWithDefault Nothing t am) | t <- times]
    y <- series [(t, M.findWithDefault Nothing t bm) | t <- times]
    Right (x, y)

{- | Missing-value strategy selecting forward fill,backward fill,or linear interpolation
under the checked boundary rules.
-}
data Fill = ForwardFill | BackwardFill | LinearFill deriving (Eq, Show)

{- | Directional filling leaves the unavailable leading/trailing end missing.
Linear filling interpolates between finite anchors and never extrapolates.
-}
fillMissing :: Fill -> Series -> Either MathError Series
fillMissing mode (Series xs) =
    series
        ( case mode of
            ForwardFill -> directional xs
            BackwardFill -> reverse (directional (reverse xs))
            LinearFill -> map interpolate xs
        )
  where
    directional = go Nothing
    go _ [] = []
    go old ((t, v) : rest) = let next = maybe old Just v in (t, next) : go next rest
    anchors = M.fromList [(t, v) | (t, Just v) <- xs]
    interpolate pair@(_, Just _) = pair
    interpolate pair@(t, Nothing) = case (M.lookupLT t anchors, M.lookupGT t anchors) of
        (Just (a, x), Just (b, y)) -> (t, Just ((1 - w) * x + w * y)) where w = fraction a b t
        _ -> pair

-- | Series resampling policy selecting bin means,last-bin values,or linear point samples.
data Resampling = LinearSamples | BinMean | BinLast deriving (Eq, Show)

{- | Linear samples require brackets (or an exact timestamp). Bins are
[start+i*step,start+(i+1)*step); the final right endpoint is excluded.
-}
resample :: Resampling -> Double -> Double -> Int -> Series -> Either MathError Series
resample method start step count input@(Series xs) = do
    require
        (count >= 0 && count <= 16384 && finite start && finite step && step > 0)
        "invalid resampling grid"
    let targets = [start + fromIntegral i * step | i <- [0 .. count - 1]]
    _ <- checked (targets ++ [start + fromIntegral count * step | method /= LinearSamples])
    case method of
        LinearSamples -> do
            let anchors = M.fromList xs
                lookupValue t = case M.lookup t anchors of
                    Just v -> v
                    Nothing -> case (M.lookupLT t anchors, M.lookupGT t anchors) of
                        (Just (a, Just x), Just (b, Just y)) -> Just ((1 - w) * x + w * y) where w = fraction a b t
                        _ -> Nothing
            series [(t, lookupValue t) | t <- targets]
        _ -> do
            require
                (toInteger count * toInteger (length (observations input)) <= 4000000)
                "resampling work limit"
            series [(t, aggregate (catMaybes [v | (s, v) <- xs, s >= t, s < t + step])) | t <- targets]
  where
    aggregate [] = Nothing
    aggregate vs = Just (if method == BinLast then last vs else average vs)

{- | Rolling-window statistic selector for mean,variance,standard deviation,minimum,or
maximum.
-}
data Rolling = MovingMean | MovingVariance | MovingSD | MovingMinimum | MovingMaximum
    deriving (Eq, Show)

-- | Full trailing windows only; variance is population variance (ddof=0).
rolling :: Rolling -> Int -> [Double] -> Either MathError [Double]
rolling method width xs = do
    validate 1 xs
    require
        (width > 0 && width <= length xs && toInteger width * toInteger (length xs) <= 4000000)
        "invalid rolling window/work limit"
    checked [apply (take width (drop i xs)) | i <- [0 .. length xs - width]]
  where
    apply ys = case method of
        MovingMean -> average ys
        MovingVariance -> var ys
        MovingSD -> sqrt (var ys)
        MovingMinimum -> minimum ys
        MovingMaximum -> maximum ys
    var ys = let m = average ys in average [(x - m) ^ (2 :: Int) | x <- ys]

-- | Recursive EMA, initialized at the first observation; 0<alpha<=1.
exponentialAverage :: Double -> [Double] -> Either MathError [Double]
exponentialAverage alpha xs = do
    validate 1 xs
    require (finite alpha && alpha > 0 && alpha <= 1) "EMA alpha outside (0,1]"
    checked (scanl (\a x -> (1 - alpha) * a + alpha * x) ((!! 0) xs) ((drop 1) xs))

-- | Nonnegative chronological weights: first weight multiplies oldest sample.
weightedAverage :: [Double] -> [Double] -> Either MathError [Double]
weightedAverage ws xs = do
    validate 1 xs
    validate 1 ws
    require
        (all (>= 0) ws && finite (sum ws) && sum ws > 0 && length ws <= length xs)
        "invalid moving weights"
    require (toInteger (length ws) * toInteger (length xs) <= 4000000) "weighted average work limit"
    checked
        [sum (zipWith (\w x -> (w / sum ws) * x) ws (drop i xs)) | i <- [0 .. length xs - length ws]]

-- | Cumulative simple return relative to the first strictly positive price.
cumulativeReturns :: [Double] -> Either MathError [Double]
cumulativeReturns xs = do
    validate 1 xs
    require (all (> 0) xs) "positive prices required"
    checked [x / (!! 0) xs - 1 | x <- xs]

-- | Consecutive log returns, using log prices to avoid ratio overflow.
logarithmicReturns :: [Double] -> Either MathError [Double]
logarithmicReturns xs = do
    validate 1 xs
    require (all (> 0) xs) "positive prices required"
    checked (zipWith (-) (map log ((drop 1) xs)) (map log xs))

-- | Apply (1-B^lag)^order. Zero order preserves data; at least one output is required.
difference :: Int -> Int -> [Double] -> Either MathError [Double]
difference order lag xs = do
    validate 1 xs
    require
        (order >= 0 && order <= 8 && lag > 0 && toInteger order * toInteger lag < toInteger (length xs))
        "invalid differencing order/lag"
    checked (iterate (\ys -> zipWith (-) (drop lag ys) ys) xs !! order)

-- | Biased covariance divided by lag-zero covariance, global sample mean.
autocorrelation :: Int -> [Double] -> Either MathError [Double]
autocorrelation lags xs = do
    validate 2 xs
    require
        (lags >= 0 && lags < length xs && toInteger lags * toInteger (length xs) <= 4000000)
        "invalid ACF lags/work limit"
    let m = average xs; zs = map (subtract m) xs; den = sum (map (^ (2 :: Int)) zs)
    require (den > 0 && finite den) "ACF requires positive finite variance"
    checked [sum (zipWith (*) (drop k zs) zs) / den | k <- [0 .. lags]]

-- | Corr(x_t,y_(t+lag)), global means and full lag-zero energy normalization.
crossCorrelation :: Int -> [Double] -> [Double] -> Either MathError Double
crossCorrelation lag xs ys = do
    validate 2 xs
    validate 2 ys
    require
        (length xs == length ys && abs (toInteger lag) < toInteger (length xs))
        "cross-correlation shape/lag"
    let a = map (subtract (average xs)) xs
        b = map (subtract (average ys)) ys
        energy values = sqrt (sum (map (^ (2 :: Int)) values))
        den = energy a * energy b
        (u, v) = if lag >= 0 then (a, drop lag b) else (drop (-lag) a, b)
    require (finite den && den > 0) "cross-correlation requires finite positive variances"
    (!! 0) <$> checked [sum (zipWith (*) u v) / den]

{- | Levinson recursion for a positive definite Toeplitz covariance. Returns
AR coefficients, innovation variance, and PACF (without the lag-zero one).
-}
durbinLevinson :: [Double] -> Either MathError ([Double], Double, [Double])
durbinLevinson covariance = do
    validate 1 covariance
    require (length covariance <= 257 && (!! 0) covariance > 0) "invalid covariance/order"
    go 1 [] ((!! 0) covariance) []
  where
    go k phi variance pacf
        | k >= length covariance = Right (phi, variance, pacf)
        | otherwise = do
            let reflection = (covariance !! k - sum [phi !! (j - 1) * covariance !! (k - j) | j <- [1 .. k - 1]]) / variance
                next = zipWith (\a b -> a - reflection * b) phi (reverse phi) ++ [reflection]
                v = variance * (1 - reflection * reflection)
            _ <- checked (reflection : v : next)
            require (abs reflection < 1 && v > 0) "Toeplitz covariance is not positive definite"
            go (k + 1) next v (pacf ++ [reflection])

-- | Biased sample autocovariances with centered data; returns mean separately.
yuleWalker :: Int -> [Double] -> Either MathError ([Double], Double, Double)
yuleWalker order xs = do
    acf <- autocorrelation order xs
    let m = average xs; variance = average [(x - m) ^ (2 :: Int) | x <- xs]
    (phi, v, _) <- durbinLevinson (map (* variance) acf)
    Right (phi, v, m)

{- | Given maximum lag then samples, compute ACF and Durbin-Levinson partial correlations,
returning lag zero (1) followed by requested PACF lags. Invalid lag/data or singular
covariance recurrence returns Left MathError.
-}
partialAutocorrelation :: Int -> [Double] -> Either MathError [Double]
partialAutocorrelation order xs = do
    acf <- autocorrelation order xs
    (_, _, pacf) <- durbinLevinson acf
    Right (1 : pacf)

-- Relative position between finite ordered anchors, avoiding opposite-sign
-- endpoint subtraction overflow.
fraction :: Double -> Double -> Double -> Double
fraction a b t = if finite (b - a) then (t - a) / (b - a) else (t / 2 - a / 2) / (b / 2 - a / 2)
