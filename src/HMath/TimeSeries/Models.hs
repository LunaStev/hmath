-- SPDX-License-Identifier: MPL-2.0

{- | Bounded Double forecasting models. AR fits use checked QR least squares.
ARMA/SARIMA minimize conditional sum of squares, with presample observations
and innovations set to zero, using analytic innovation derivatives and damped
Levenberg--Marquardt. These are local conditional fits, not exact Gaussian
maximum likelihood; stationarity/invertibility and prediction intervals are
not inferred. Differencing is integrated explicitly when forecasting.
-}
module HMath.TimeSeries.Models (
    Smoothing (..),
    smoothForecast,
    Decomposition (..),
    decompose,
    STLConfig (..),
    stl,
    defaultSTLConfig,
    ARModel,
    fitAR,
    arCoefficients,
    forecastAR,
    SARIMAOrder (..),
    ARIMAModel,
    fitARIMA,
    fitMA,
    fitARMA,
    fitSARIMA,
    arimaParameters,
    arimaResiduals,
    arimaInnovationVariance,
    forecastARIMA,
    VARModel,
    fitVAR,
    varCoefficients,
    forecastVAR,
    kalmanSeries,
) where

import Control.Monad (foldM)
import Data.List (sort, transpose)
import HMath.Error
import qualified HMath.Matrix as M
import qualified HMath.Matrix.QR as QR
import qualified HMath.Optimization.Common as O
import qualified HMath.Optimization.Local as O
import qualified HMath.Signal as S
import HMath.TimeSeries.Core

data Smoothing = Simple Double | Holt Double Double | HoltWinters Int Double Double Double
    deriving (Eq, Show)

{- | Fitted one-step means and future means. Simple/Holt initialize from the
first sample/first difference. Additive Holt--Winters initializes the level
and seasonal indices from a complete first cycle, and the trend from the
difference between the first two cycle means. Initial fitted cycle is the
initializer, not an out-of-sample prediction.
-}
smoothForecast :: Smoothing -> Int -> [Double] -> Either MathError ([Double], [Double])
smoothForecast method horizon xs = do
    validate 1 xs
    require (horizon >= 0 && horizon <= 16384) "invalid forecast horizon"
    let rate x = finite x && x >= 0 && x <= 1
    (fitted, future) <- case method of
        Simple alpha -> do
            require (rate alpha) "smoothing rate outside [0,1]"
            let states = scanl (\l x -> alpha * x + (1 - alpha) * l) ((!! 0) xs) ((drop 1) xs)
            Right ((!! 0) xs : init states, replicate horizon (last states))
        Holt alpha beta -> do
            require (length xs >= 2 && all rate [alpha, beta]) "invalid Holt inputs"
            let step (l, b, fs) x =
                    let predicted = l + b
                        next = alpha * x + (1 - alpha) * predicted
                        trend = beta * (next - l) + (1 - beta) * b
                     in (next, trend, fs ++ [predicted])
                (finalLevel, finalTrend, finalFitted) = foldl step ((!! 0) xs, xs !! 1 - (!! 0) xs, [(!! 0) xs]) ((drop 1) xs)
            Right (finalFitted, [finalLevel + fromIntegral k * finalTrend | k <- [1 .. horizon]])
        HoltWinters period alpha beta gamma -> do
            require
                (period >= 2 && period <= 1024 && length xs >= 2 * period && all rate [alpha, beta, gamma])
                "invalid Holt-Winters inputs"
            let level = average (take period xs)
                trend = (average (take period (drop period xs)) - level) / fromIntegral period
                seasons = map (subtract level) (take period xs)
                step (l, b, ss, fs) (t, x) =
                    let j = t `mod` period
                        s = ss !! j
                        prediction = l + b + s
                        next = alpha * (x - s) + (1 - alpha) * (l + b)
                        bt = beta * (next - l) + (1 - beta) * b
                        st = gamma * (x - next) + (1 - gamma) * s
                     in (next, bt, take j ss ++ [st] ++ drop (j + 1) ss, fs ++ [prediction])
                (finalLevel, finalTrend, finalSeasonal, finalFitted) = foldl step (level, trend, seasons, take period xs) (zip [period ..] (drop period xs))
            Right
                ( finalFitted
                , [ finalLevel + fromIntegral k * finalTrend + finalSeasonal !! ((length xs + k - 1) `mod` period)
                  | k <- [1 .. horizon]
                  ]
                )
    _ <- checked (fitted ++ future)
    Right (fitted, future)

-- | Additive reconstruction is trend+seasonal+remainder at every input index.
data Decomposition = Decomposition
    {trendComponent :: [Double], seasonalComponent :: [Double], remainderComponent :: [Double]}
    deriving (Eq, Show)

{- | Classical additive decomposition with local linear trend smoothing and
centered phase means. Requires at least two complete periods.
-}
decompose :: Int -> [Double] -> Either MathError Decomposition
decompose period xs = do
    validate 1 xs
    require
        (period >= 2 && period <= 1024 && length xs >= 2 * period && length xs <= 2048)
        "invalid decomposition period/sample count"
    let trend = loess (2 * (period `div` 2) + 1) (replicate (length xs) 1) xs
        detrended = zipWith (-) xs trend
        phases =
            [average [v | (i, v) <- zip [0 :: Int ..] detrended, i `mod` period == j] | j <- [0 .. period - 1]]
        seasonal = [phases !! (i `mod` period) - average phases | i <- [0 .. length xs - 1]]
    decomposition xs trend seasonal

data STLConfig = STLConfig
    { stlPeriod :: Int
    , stlSeasonalWindow :: Int
    , stlTrendWindow :: Int
    , stlLowPassWindow :: Int
    , stlInnerIterations :: Int
    , stlRobustIterations :: Int
    }
    deriving (Eq, Show)
defaultSTLConfig :: Int -> STLConfig
defaultSTLConfig period = STLConfig period 7 (oddAbove (2 * period + 1)) (oddAbove period) 2 0
  where
    oddAbove x = if odd x then x else x + 1

{- | Cleveland-style STL reference backfitting: smooth seasonal subseries by
degree-one tricube LOESS with one-cycle extrapolation; remove a period,
period, three-point moving-average low-pass followed by LOESS, then smooth
the deseasonalized trend. Optional bisquare robust outer iterations use six
times median absolute residual. Every index is evaluated (no jump shortcut).
See https://search.r-project.org/R/refmans/stats/html/stl.html .
-}
stl :: STLConfig -> [Double] -> Either MathError Decomposition
stl config xs = do
    validate 1 xs
    let p = stlPeriod config
        n = length xs
        windows = [stlSeasonalWindow config, stlTrendWindow config, stlLowPassWindow config]
        ni = stlInnerIterations config
        no = stlRobustIterations config
    require
        ( p >= 2
            && p <= 512
            && n >= 2 * p
            && n <= 1024
            && all (\w -> w >= 3 && odd w && w <= 4095) windows
            && ni >= 1
            && ni <= 10
            && no >= 0
            && no <= 10
        )
        "invalid STL configuration/sample count"
    require (toInteger n * toInteger n * toInteger ni * toInteger (no + 1) <= 20000000) "STL work limit"
    let outer k weights trend =
            let (tr, se) = iterate (inner weights) (trend, replicate n 0) !! ni
                residual = zipWith3 (\x t s -> x - t - s) xs tr se
                scale = 6 * median (map abs residual)
                nextWeights =
                    if scale == 0
                        then map (\r -> if r == 0 then 1 else 0) residual
                        else [let u = abs r / scale in if u >= 1 then 0 else (1 - u * u) ^ (2 :: Int) | r <- residual]
             in if k >= no then (tr, se) else outer (k + 1) nextWeights tr
        inner weights (trend, _) =
            let detrended = zipWith (-) xs trend
                sub j =
                    [ (fromIntegral k, v, weights !! i)
                    | (k, i) <- zip [0 :: Int ..] [j, j + p .. n - 1]
                    , let v = detrended !! i
                    ]
                phaseAt i =
                    let j = i `mod` p; t = fromIntegral ((i - j) `div` p)
                     in loessAt (stlSeasonalWindow config) (sub j) t
                extended = [phaseAt i | i <- [-p .. n + p - 1]]
                low0 = moving p extended
                low1 = moving p low0
                low2 = moving 3 low1
                low = loess (stlLowPassWindow config) (replicate n 1) low2
                seasonal = zipWith (-) (take n (drop p extended)) low
                trend' = loess (stlTrendWindow config) weights (zipWith (-) xs seasonal)
             in (trend', seasonal)
        (finalTrend, finalSeasonal) = outer 0 (replicate n 1) (replicate n 0)
    decomposition xs finalTrend finalSeasonal
  where
    moving k ys = [average (take k (drop i ys)) | i <- [0 .. length ys - k]]
    median ys =
        let zs = sort ys; n = length zs
         in if odd n then zs !! (n `div` 2) else (zs !! (n `div` 2 - 1) + zs !! (n `div` 2)) / 2

loess :: Int -> [Double] -> [Double] -> [Double]
loess window weights xs = [loessAt window sample (fromIntegral i) | i <- [0 .. length xs - 1]]
  where
    sample = zipWith3 (\i x w -> (fromIntegral i, x, w)) [0 :: Int ..] xs weights

-- Local linear weighted least squares centered at the query. Select nearest
-- window points with deterministic ties; a widened radius keeps all endpoints
-- from receiving zero weight, including the two-point/extrapolation cases.
loessAt :: Int -> [(Double, Double, Double)] -> Double -> Double
loessAt window sample query =
    let nearest = take window (sortOnDistance sample)
        radius = max 1e-12 (maximum (map (\(t, _, _) -> abs (t - query)) nearest) * 1.000001)
        rows =
            [ (t - query, x, w * (1 - (min 1 (abs (t - query) / radius)) ^ (3 :: Int)) ^ (3 :: Int))
            | (t, x, w) <- nearest
            ]
        sw = sum [w | (_, _, w) <- rows]
        sx = sum [w * t | (t, _, w) <- rows]
        sxx = sum [w * t * t | (t, _, w) <- rows]
        sy = sum [w * x | (_, x, w) <- rows]
        sxy = sum [w * t * x | (t, x, w) <- rows]
        den = sw * sxx - sx * sx
     in if sw == 0
            then average [x | (_, x, _) <- nearest]
            else if abs den <= 1e-14 * max 1 (sw * sxx) then sy / sw else (sxx * sy - sx * sxy) / den
  where
    sortOnDistance = map snd . sort . map (\r@(t, _, _) -> ((abs (t - query), t), r))

decomposition :: [Double] -> [Double] -> [Double] -> Either MathError Decomposition
decomposition xs trend seasonal = do
    let residual = zipWith3 (\x t s -> x - t - s) xs trend seasonal
    _ <- checked (trend ++ seasonal ++ residual)
    Right (Decomposition trend seasonal residual)

-- | Intercept followed by lag coefficients; observations stored chronologically.
data ARModel = ARModel [Double] [Double] deriving (Eq, Show)

arCoefficients :: ARModel -> [Double]
arCoefficients (ARModel b _) = b
fitAR :: Int -> [Double] -> Either MathError ARModel
fitAR order xs = do
    validate 2 xs
    require
        (order >= 0 && order <= 64 && length xs > 2 * order + 1 && length xs <= 4096)
        "invalid AR order/sample count"
    b <-
        ols [[1] ++ [xs !! (t - j) | j <- [1 .. order]] | t <- [order .. length xs - 1]] (drop order xs)
    Right (ARModel b xs)
forecastAR :: Int -> ARModel -> Either MathError [Double]
forecastAR horizon (ARModel b xs) = do
    require (horizon >= 0 && horizon <= 16384) "invalid AR forecast horizon"
    let p = length b - 1
        go 0 _ acc = Right (reverse acc)
        go k past acc = do
            let value = (!! 0) b + sum (zipWith (*) ((drop 1) b) (take p past))
            _ <- checked [value]
            go (k - 1) (value : past) (value : acc)
    go horizon (reverse xs) []

data SARIMAOrder = SARIMAOrder
    { arOrder :: Int
    , differenceOrder :: Int
    , maOrder :: Int
    , seasonalAROrder :: Int
    , seasonalDifferenceOrder :: Int
    , seasonalMAOrder :: Int
    , seasonalPeriod :: Int
    }
    deriving (Eq, Show)
data ARIMAModel = ARIMAModel SARIMAOrder [Double] [Double] [Double] [Double] Double
    deriving (Eq, Show)
arimaParameters :: ARIMAModel -> [Double]
arimaParameters (ARIMAModel _ b _ _ _ _) = b
arimaResiduals :: ARIMAModel -> [Double]
arimaResiduals (ARIMAModel _ _ _ _ es _) = es
arimaInnovationVariance :: ARIMAModel -> Double
arimaInnovationVariance (ARIMAModel _ _ _ _ _ v) = v
fitARIMA :: O.OptimizeOptions -> Int -> Int -> Int -> [Double] -> Either MathError ARIMAModel
fitARIMA options p d q = fitSARIMA options (SARIMAOrder p d q 0 0 0 1)
fitMA :: O.OptimizeOptions -> Int -> [Double] -> Either MathError ARIMAModel
fitMA options q = fitARIMA options 0 0 q
fitARMA :: O.OptimizeOptions -> Int -> Int -> [Double] -> Either MathError ARIMAModel
fitARMA options p q = fitARIMA options p 0 q

{- | Parameters are intercept, ordinary AR, ordinary MA, seasonal AR, seasonal
MA. Multiplicative seasonal polynomials include cross-lag interactions.
Intercept always belongs to the differenced process. Caller supplies fit
budgets; exhausted or ill-conditioned fits return MathError.
-}
fitSARIMA :: O.OptimizeOptions -> SARIMAOrder -> [Double] -> Either MathError ARIMAModel
fitSARIMA options order xs = do
    validate 3 xs
    O.checkedOptions options
    let p = arOrder order
        q = maOrder order
        bigP = seasonalAROrder order
        bigQ = seasonalMAOrder order
        s = seasonalPeriod order
        d = differenceOrder order
        bigD = seasonalDifferenceOrder order
        parameters = 1 + p + q + bigP + bigQ
        burn = max (p + bigP * s) (q + bigQ * s)
    require
        ( all (\k -> k >= 0 && k <= 8) [p, q, bigP, bigQ]
            && d >= 0
            && d <= 2
            && bigD >= 0
            && bigD <= 2
            && s >= 1
            && s <= 128
            && parameters <= 13
            && burn <= 256
            && length xs <= 2048
        )
        "SARIMA order/sample limit"
    zs <- difference d 1 xs >>= difference bigD s
    require (length zs > burn + parameters) "insufficient SARIMA observations"
    require
        ( toInteger (O.optMaxEvaluations options)
            * toInteger (length zs)
            * toInteger parameters
            * toInteger (max 1 burn)
            <= 100000000
        )
        "SARIMA fit work limit"
    let rows b = innovations order b zs
        scale = sqrt (fromIntegral (length zs - burn))
        residual b = do (es, _) <- rows b; checked (map (/ scale) (drop burn es))
        jacobian b = do
            (_, js) <- rows b
            let out = map (map (/ scale)) (drop burn js)
            _ <- checked (concat out)
            Right out
        initial = average zs : replicate (parameters - 1) 0
    b <-
        if parameters == 1
            then Right initial
            else O.optPoint <$> O.leastSquares O.SquaredLoss 0.01 options residual jacobian initial
    (es, _) <- rows b
    let variance = average [e * e | e <- drop burn es]
    _ <- checked [variance]
    Right (ARIMAModel order b xs zs es variance)

polynomialProduct :: [Double] -> [Double] -> [Double]
polynomialProduct a b =
    [ sum [a !! i * b !! (k - i) | i <- [max 0 (k - length b + 1) .. min k (length a - 1)]]
    | k <- [0 .. length a + length b - 2]
    ]
seasonalPolynomial :: Int -> [Double] -> [Double]
seasonalPolynomial s values = [if i `mod` s == 0 then values !! (i `div` s) else 0 | i <- [0 .. s * (length values - 1)]]

modelPolynomials :: SARIMAOrder -> [Double] -> ([Double], [Double])
modelPolynomials order b =
    let p = arOrder order
        q = maOrder order
        bigP = seasonalAROrder order
        bigQ = seasonalMAOrder order
        s = seasonalPeriod order
        phi = take p (drop 1 b)
        theta = take q (drop (1 + p) b)
        bigPhi = take bigP (drop (1 + p + q) b)
        bigTheta = take bigQ (drop (1 + p + q + bigP) b)
     in ( map
            negate
            ((drop 1) (polynomialProduct (1 : map negate phi) (seasonalPolynomial s (1 : map negate bigPhi))))
        , (drop 1) (polynomialProduct (1 : theta) (seasonalPolynomial s (1 : bigTheta)))
        )

innovations :: SARIMAOrder -> [Double] -> [Double] -> Either MathError ([Double], [[Double]])
innovations order b zs = do
    _ <- checked b
    let (ar, ma) = modelPolynomials order b
        derivatives = coefficientPartials order b
        past values k = if k < length values then values !! k else 0
        step (es, js) (t, z) =
            let ypast = reverse (take t zs)
                e = z - (!! 0) b - sum (zipWith (*) ar ypast) - sum (zipWith (*) ma es)
                deriv j (da, dm) =
                    -(if j == 0 then 1 else 0)
                        - sum (zipWith (*) da ypast)
                        - sum (zipWith (*) dm es)
                        - sum [m * past (map (!! j) js) k | (k, m) <- zip [0 ..] ma]
                row = zipWith deriv [0 ..] derivatives
             in (e : es, row : js)
        (er, jr) = foldl step ([], []) (zip [0 ..] zs)
    _ <- checked (er ++ concat jr)
    Right (reverse er, reverse jr)

-- Differentiate polynomial products directly. Subtracting f(b+1)-f(b)
-- would lose a unit perturbation entirely for coefficients above 2^53.
coefficientPartials :: SARIMAOrder -> [Double] -> [([Double], [Double])]
coefficientPartials order b = [partial j | j <- [0 .. length b - 1]]
  where
    p = arOrder order
    q = maOrder order
    bigP = seasonalAROrder order
    bigQ = seasonalMAOrder order
    s = seasonalPeriod order
    ar = 1 : map negate (take p (drop 1 b))
    ma = 1 : take q (drop (1 + p) b)
    seasonalAR = seasonalPolynomial s (1 : map negate (take bigP (drop (1 + p + q) b)))
    seasonalMA = seasonalPolynomial s (1 : take bigQ (drop (1 + p + q + bigP) b))
    basis n index sign = [if k == index then sign else 0 | k <- [0 .. n]]
    partial j
        | j >= 1 && j <= p =
            (map negate (drop 1 (polynomialProduct (basis p j (-1)) seasonalAR)), replicate (q + bigQ * s) 0)
        | j > p && j <= p + q =
            (replicate (p + bigP * s) 0, drop 1 (polynomialProduct (basis q (j - p) 1) seasonalMA))
        | j > p + q && j <= p + q + bigP =
            ( map negate (drop 1 (polynomialProduct ar (seasonalPolynomial s (basis bigP (j - p - q) (-1)))))
            , replicate (q + bigQ * s) 0
            )
        | j > p + q + bigP =
            ( replicate (p + bigP * s) 0
            , drop 1 (polynomialProduct ma (seasonalPolynomial s (basis bigQ (j - p - q - bigP) 1)))
            )
        | otherwise = (replicate (p + bigP * s) 0, replicate (q + bigQ * s) 0)

forecastARIMA :: Int -> ARIMAModel -> Either MathError [Double]
forecastARIMA horizon (ARIMAModel order b xs zs es _) = do
    require (horizon >= 0 && horizon <= 16384) "invalid SARIMA forecast horizon"
    let (ar, ma) = modelPolynomials order b
        diff =
            foldl
                polynomialProduct
                [1]
                ( replicate (differenceOrder order) [1, -1]
                    ++ replicate (seasonalDifferenceOrder order) (seasonalPolynomial (seasonalPeriod order) [1, -1])
                )
        loop 0 _ _ _ acc = Right (reverse acc)
        loop k original transformed errors acc = do
            let z = (!! 0) b + sum (zipWith (*) ar transformed) + sum (zipWith (*) ma errors)
                value = z - sum (zipWith (*) ((drop 1) diff) original)
            _ <- checked [z, value]
            loop (k - 1) (value : original) (z : transformed) (0 : errors) (value : acc)
    loop horizon (reverse xs) (reverse zs) (reverse es) []

data VARModel = VARModel Int [[Double]] [[Double]] deriving (Eq, Show)

-- | Rows are response components, columns are intercept then lag-major predictors.
varCoefficients :: VARModel -> [[Double]]
varCoefficients (VARModel _ b _) = b

fitVAR :: Int -> [[Double]] -> Either MathError VARModel
fitVAR order xs = do
    require (not (null xs) && not (null ((!! 0) xs))) "empty VAR data"
    let d = length ((!! 0) xs); n = length xs; width = 1 + order * d
    require
        ( d <= 16
            && n <= 2048
            && order >= 1
            && order <= 16
            && all ((== d) . length) xs
            && n - order > width
            && toInteger n * toInteger width * toInteger width <= 20000000
        )
        "VAR shape/order/work limit"
    _ <- checked (concat xs)
    let design = [1 : concat [xs !! (t - j) | j <- [1 .. order]] | t <- [order .. n - 1]]
    b <- mapM (ols design) (transpose (drop order xs))
    Right (VARModel order b xs)
forecastVAR :: Int -> VARModel -> Either MathError [[Double]]
forecastVAR horizon (VARModel order b xs) = do
    require
        (horizon >= 0 && horizon <= 16384 && toInteger horizon * toInteger (length b) <= 262144)
        "VAR forecast limit"
    let loop 0 _ acc = Right (reverse acc)
        loop k past acc = do
            let features = 1 : concat (take order past); next = [sum (zipWith (*) row features) | row <- b]
            _ <- checked next
            loop (k - 1) (next : past) (next : acc)
    loop horizon (reverse xs) []

{- | Reuse the checked Joseph-form linear Kalman update for each complete
observation. Returns posterior states, excluding the caller's initial state.
-}
kalmanSeries ::
    [[Double]] ->
    [[Double]] ->
    [[Double]] ->
    [[Double]] ->
    S.GaussianState ->
    [[Double]] ->
    Either MathError [S.GaussianState]
kalmanSeries transition observation q r initial measured = do
    require (length measured <= 16384) "Kalman series limit"
    (_, states) <-
        foldM
            (\(old, acc) y -> do next <- S.kalman transition observation q r y old; Right (next, next : acc))
            (initial, [])
            measured
    Right (reverse states)

ols :: [[Double]] -> [Double] -> Either MathError [Double]
ols rows target = do
    let n = length rows; p = length ((!! 0) rows)
    matrix <- M.fromListChecked n p (concat rows)
    QR.leastSquares matrix target >>= checked
