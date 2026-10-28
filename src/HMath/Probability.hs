-- SPDX-License-Identifier: MPL-2.0

{- | Checked probability models. Gamma uses shape/scale, geometric and negative
binomial count failures before successes, Gumbel/GEV model maxima, Student-t
is standardized, and triangular parameters are lower/mode/upper. Discrete
densities are zero away from integer support; CDF=P(X\<=x), survival=P(X>x).
Quantiles use inf{x:F(x)>=p}. Log zero is -infinity by contract.
Finite reference summation/integration budgets are explicit in the code.
DiscreteUniform endpoints must be exactly representable integers (|bound|\<=2^53),
and Skellam log-mass order is capped at 1000000; CDF tails outside its finite
numerical summation window saturate to zero/one.
-}
module HMath.Probability (
    Distribution (..),
    validateDistribution,
    density,
    logDensity,
    cdf,
    survival,
    quantile,
    hazard,
    logLikelihood,
    moments,
    entropy,
    sample,
    fitNormal,
    fitExponential,
    fitBernoulli,
    fitMLEGrid,
    fitMAPGrid,
    betaBernoulliUpdate,
    gammaPoissonUpdate,
    normalNormalUpdate,
    conditionalProbability,
    bayes,
    expectation,
    goodnessOfFit,
    gaussianKDE,
    multinomialPMF,
    dirichletDensity,
    multivariateNormalLogDensity,
    sampleMultivariateNormal,
    wishartLogDensity,
    sampleWishart,
    Markov,
    markov,
    transition,
    stationary,
    HMM,
    hmm,
    forward,
    backward,
    posteriorStates,
    viterbi,
    baumWelch,
) where

import Control.Monad (foldM)
import qualified Data.Foldable as Foldable (foldl')
import Data.List (maximumBy, sort)
import Data.Ord (comparing)
import HMath.Error
import HMath.Matrix (Matrix, fromListChecked, multiplyChecked, shape, toList, transposeMatrix)
import HMath.Matrix.Decomposition (cholesky)
import HMath.Matrix.LU (determinant, inverse, solve)
import qualified HMath.Random as R
import qualified HMath.Special as S

data Distribution
    = Bernoulli Double
    | Binomial Int Double
    | NegativeBinomial Double Double
    | Geometric Double
    | Hypergeometric Int Int Int
    | Poisson Double
    | Categorical [Double]
    | DiscreteUniform Int Int
    | Uniform Double Double
    | Normal Double Double
    | LogNormal Double Double
    | Exponential Double
    | Gamma Double Double
    | Beta Double Double
    | ChiSquare Double
    | StudentT Double
    | FisherF Double Double
    | Cauchy Double Double
    | Laplace Double Double
    | Logistic Double Double
    | Weibull Double Double
    | Pareto Double Double
    | Rayleigh Double
    | Maxwell Double
    | Gumbel Double Double
    | GeneralizedExtremeValue Double Double Double
    | BetaBinomial Int Double Double
    | Skellam Double Double
    | VonMises Double Double
    | Triangular Double Double Double
    | TruncatedNormal Double Double Double Double
    | Mixture [(Double, Distribution)]
    | Empirical [Double]
    | GaussianKDE Double [Double]
    deriving (Eq, Show)
finite :: Double -> Bool
finite x = not (isNaN x || isInfinite x)
positive :: Double -> Bool
positive x = finite x && x > 0
require :: Bool -> String -> Either MathError ()
require p msg = if p then Right () else Left (DomainError msg)
checked :: Double -> Either MathError Double
checked x = if isNaN x || isInfinite x then Left NonFiniteResult else Right x
prob :: Double -> Bool
prob x = finite x && x >= 0 && x <= 1

-- | Check finite parameters, support ordering, probability normalization, and declared per-family reference budgets.
validateDistribution :: Distribution -> Either MathError ()
validateDistribution d = case d of
    Bernoulli p -> ok (prob p)
    Binomial n p -> ok (n >= 0 && n <= 100000 && prob p)
    NegativeBinomial r p -> ok (positive r && positive p && p <= 1)
    Geometric p -> ok (positive p && p <= 1)
    Hypergeometric n k draws -> ok (n > 0 && n <= 100000 && k >= 0 && k <= n && draws >= 0 && draws <= n)
    Poisson r -> ok (finite r && r >= 0 && r <= 100000)
    Categorical ps -> ok (not (null ps) && all prob ps && abs (sum ps - 1) < 1e-12)
    DiscreteUniform lo hi ->
        ok
            ( lo <= hi
                && toInteger hi - toInteger lo < 1000000
                && abs (toInteger lo) <= 2 ^ (53 :: Int)
                && abs (toInteger hi) <= 2 ^ (53 :: Int)
            )
    Uniform lo hi -> ok (finite lo && finite hi && positive (hi - lo))
    Normal mu sd -> loc mu sd
    LogNormal mu sd -> loc mu sd
    Exponential rate -> ok (positive rate)
    Gamma a b -> pair a b
    Beta a b -> pair a b
    ChiSquare a -> ok (positive a)
    StudentT a -> ok (positive a)
    FisherF a b -> pair a b
    Cauchy mu scale -> loc mu scale
    Laplace mu scale -> loc mu scale
    Logistic mu scale -> loc mu scale
    Weibull a b -> pair a b
    Pareto a b -> pair a b
    Rayleigh s -> ok (positive s)
    Maxwell s -> ok (positive s)
    Gumbel a b -> loc a b
    GeneralizedExtremeValue mu sc xi -> ok (finite (mu + xi) && positive sc)
    BetaBinomial n a b -> ok (n >= 0 && n <= 100000 && positive a && positive b)
    Skellam a b -> ok (positive a && positive b && a + b <= 500)
    VonMises mu k -> ok (finite mu && finite k && k >= 0 && k <= 500)
    Triangular a b c -> ok (all finite [a, b, c] && a <= b && b <= c && a < c)
    TruncatedNormal mu sd a b -> ok (finite (mu + a + b) && positive sd && a < b)
    Mixture pairs -> do
        ok
            ( not (null pairs)
                && all (\(p, _) -> finite p && p >= 0) pairs
                && abs (sum (map fst pairs) - 1) < 1e-12
            )
        mapM_ (validateDistribution . snd) pairs
        ok (all ((== isDiscrete (snd (pairs !! 0))) . isDiscrete . snd) pairs)
    Empirical xs -> ok (not (null xs) && all finite xs)
    GaussianKDE h xs -> ok (positive h && not (null xs) && all finite xs)
  where
    ok p = require p ("invalid distribution parameters: " ++ show d)
    loc a b = ok (finite a && positive b)
    pair a b = ok (positive a && positive b)

isDiscrete :: Distribution -> Bool
isDiscrete d = case d of
    Bernoulli _ -> True
    Binomial _ _ -> True
    NegativeBinomial _ _ -> True
    Geometric _ -> True
    Hypergeometric _ _ _ -> True
    Poisson _ -> True
    Categorical _ -> True
    DiscreteUniform _ _ -> True
    BetaBinomial _ _ _ -> True
    Skellam _ _ -> True
    Empirical _ -> True
    Mixture ps -> all (isDiscrete . snd) ps
    _ -> False
logChoose :: Int -> Int -> Either MathError Double
logChoose n k
    | k < 0 || k > n = Right (-1 / 0)
    | otherwise = do
        a <- S.logGamma (fromIntegral n + 1)
        b <- S.logGamma (fromIntegral k + 1)
        c <- S.logGamma (fromIntegral (n - k) + 1)
        pure (a - b - c)
xlog :: Double -> Double -> Double
xlog a b = if a == 0 then 0 else a * log b

-- | Log density or mass; zero probability is negative infinity, while an integrable endpoint singularity is positive infinity. Observations must be finite.
logDensity :: Distribution -> Double -> Either MathError Double
logDensity d x = do
    validateDistribution d
    require (finite x) "density requires finite observation"
    value <-
        if isDiscrete d && not (empirical d) && x /= fromInteger (round x) then Right (-1 / 0) else raw d x
    if isNaN value then Left NonFiniteResult else Right value
  where
    empirical (Empirical _) = True
    empirical (Mixture ps) = any (empirical . snd) ps
    empirical _ = False
    raw dist y = case dist of
        Bernoulli p -> pure (if y == 0 then log (1 - p) else if y == 1 then log p else -1 / 0)
        Binomial n p ->
            if y < 0 || y > fromIntegral n
                then zero
                else do c <- logChoose n (round y); pure (c + xlog y p + xlog (fromIntegral n - y) (1 - p))
        NegativeBinomial r p ->
            if y < 0
                then zero
                else do
                    a <- S.logGamma (y + r)
                    b <- S.logGamma r
                    c <- S.logGamma (y + 1)
                    pure (a - b - c + r * log p + xlog y (1 - p))
        Geometric p -> pure (if y < 0 then -1 / 0 else log p + xlog y (1 - p))
        Hypergeometric n k draws ->
            if y < fromIntegral (max 0 (draws - (n - k))) || y > fromIntegral (min draws k)
                then zero
                else do
                    a <- logChoose k (round y)
                    b <- logChoose (n - k) (draws - round y)
                    c <- logChoose n draws
                    pure (a + b - c)
        Poisson rate ->
            if y < 0
                then zero
                else
                    if rate == 0
                        then pure (if y == 0 then 0 else -1 / 0)
                        else do g <- S.logGamma (y + 1); pure (y * log rate - rate - g)
        Categorical ps -> pure (if y < 0 || y >= fromIntegral (length ps) then -1 / 0 else log (ps !! round y))
        DiscreteUniform lo hi ->
            pure
                ( if y < fromIntegral lo || y > fromIntegral hi
                    then -1 / 0
                    else -log (fromIntegral (toInteger hi - toInteger lo + 1))
                )
        Uniform lo hi -> pure (if y < lo || y > hi then -1 / 0 else -log (hi - lo))
        Normal mu sd -> pure (-0.5 * log (2 * pi) - log sd - 0.5 * ((y - mu) / sd) ^ (2 :: Int))
        LogNormal mu sd -> if y <= 0 then zero else (subtract (log y)) <$> raw (Normal mu sd) (log y)
        Exponential rate -> pure (if y < 0 then -1 / 0 else log rate - rate * y)
        Gamma a sc ->
            if y < 0
                then zero
                else
                    if y == 0
                        then pure (if a == 1 then -log sc else if a > 1 then -1 / 0 else 1 / 0)
                        else do g <- S.logGamma a; pure ((a - 1) * log y - y / sc - g - a * log sc)
        Beta a b ->
            if y < 0 || y > 1
                then zero
                else do lb <- S.logBeta a b; pure (xlog (a - 1) y + xlog (b - 1) (1 - y) - lb)
        ChiSquare k -> raw (Gamma (k / 2) 2) y
        StudentT nu -> do
            a <- S.logGamma ((nu + 1) / 2)
            b <- S.logGamma (nu / 2)
            pure (a - b - 0.5 * log (nu * pi) - (nu + 1) / 2 * log (1 + y * y / nu))
        FisherF a b ->
            if y <= 0
                then zero
                else do
                    lb <- S.logBeta (a / 2) (b / 2)
                    pure (a / 2 * log (a / b) + (a / 2 - 1) * log y - (a + b) / 2 * log (1 + a * y / b) - lb)
        Cauchy mu sc -> pure (-log (pi * sc) - log (1 + ((y - mu) / sc) ^ (2 :: Int)))
        Laplace mu sc -> pure (-log (2 * sc) - abs (y - mu) / sc)
        Logistic mu sc -> let z = abs ((y - mu) / sc) in pure (-z - 2 * log (1 + exp (-z)) - log sc)
        Weibull k sc -> if y < 0 then zero else pure (log (k / sc) + xlog (k - 1) (y / sc) - (y / sc) ** k)
        Pareto xm a -> pure (if y < xm then -1 / 0 else log a + a * log xm - (a + 1) * log y)
        Rayleigh sc -> pure (if y <= 0 then -1 / 0 else log y - 2 * log sc - y * y / (2 * sc * sc))
        Maxwell sc ->
            pure
                (if y <= 0 then -1 / 0 else 0.5 * log (2 / pi) + 2 * log y - 3 * log sc - y * y / (2 * sc * sc))
        Gumbel mu sc -> let z = (y - mu) / sc in pure (if isInfinite z then -1 / 0 else -log sc - z - exp (-z))
        GeneralizedExtremeValue mu sc xi ->
            if abs xi < 1e-12
                then raw (Gumbel mu sc) y
                else
                    let t = 1 + xi * (y - mu) / sc
                     in pure (if t <= 0 then -1 / 0 else -log sc - (1 + 1 / xi) * log t - t ** (-1 / xi))
        BetaBinomial n a b ->
            if y < 0 || y > fromIntegral n
                then zero
                else do
                    c <- logChoose n (round y)
                    u <- S.logBeta (y + a) (fromIntegral n - y + b)
                    v <- S.logBeta a b
                    pure (c + u - v)
        Skellam a b -> do
            let order = abs (round y) :: Integer
            require (order <= 1000000) "Skellam absolute integer order exceeds 1000000 reference budget"
            let n = fromInteger order :: Int; t = sqrt (a * b)
            lg <- S.logGamma (fromIntegral n + 1)
            let go k term accum
                    | k > 10000 = Left (NonConvergence "Skellam Bessel series" 10000)
                    | otherwise =
                        let u = term * t * t / (fromIntegral k * (fromIntegral k + fromIntegral n)); v = accum + u
                         in if u < 1e-14 * v then Right v else go (k + 1) u v
            v <- go (1 :: Int) 1 1
            pure (-(a + b) + y / 2 * log (a / b) + fromIntegral n * log t - lg + log v)
        VonMises mu k -> do v <- S.scaledBesselI 0 k; pure (k * (cos (y - mu) - 1) - log (2 * pi * S.sfValue v))
        Triangular a b c ->
            pure
                ( if y < a || y > c
                    then -1 / 0
                    else
                        if y <= b
                            then
                                if a == b then log (2 * (c - y) / ((c - a) * (c - b))) else log (2 * (y - a) / ((c - a) * (b - a)))
                            else
                                if b == c then log (2 * (y - a) / ((c - a) * (b - a))) else log (2 * (c - y) / ((c - a) * (c - b)))
                )
        TruncatedNormal mu sd a b ->
            if y < a || y > b
                then zero
                else do
                    u <- S.normalCDF ((a - mu) / sd)
                    v <- S.normalCDF ((b - mu) / sd)
                    require (v > u) "truncated normal has unresolved mass"
                    p <- raw (Normal mu sd) y
                    pure (p - log (v - u))
        Mixture ps -> do ls <- mapM (\(p, m) -> (log p +) <$> logDensity m y) ps; pure (logSumExp ls)
        Empirical xs -> pure (log (fromIntegral (length (filter (== y) xs)) / fromIntegral (length xs)))
        GaussianKDE h xs -> do ls <- mapM (\mu -> raw (Normal mu h) y) xs; pure (logSumExp ls - log (fromIntegral (length xs)))
    zero = Right (-1 / 0)

log1pexp :: Double -> Double
log1pexp x = if x > 0 then x + log (1 + exp (-x)) else log (1 + exp x)
logSumExp :: [Double] -> Double
logSumExp xs = let m = maximum xs in if isInfinite m then m else m + log (sum (map (\x -> exp (x - m)) xs))

-- | Probability mass for discrete families or density for continuous families. At integrable density singularities the result can be positive infinity; outside support it is zero.
density :: Distribution -> Double -> Either MathError Double
density d x = exp <$> logDensity d x

-- | P(X\<=x). Gamma/beta and classical transformed families use analytic special-function identities. Remaining finite-support continuous cases use 2048-panel Simpson integration; Skellam drops a tail beyond 14 standard deviations plus 20 counts.
cdf :: Distribution -> Double -> Either MathError Double
cdf d x = do
    validateDistribution d
    require (finite x) "CDF requires finite argument"
    p <- case d of
        Poisson rate -> if x < 0 then pure 0 else S.gammaQ (fromIntegral (floor x :: Integer) + 1) rate
        Binomial n p ->
            if x < 0
                then pure 0
                else
                    if x >= fromIntegral n
                        then pure 1
                        else
                            if p == 0
                                then pure 1
                                else
                                    if p == 1
                                        then pure 0
                                        else
                                            S.betaI
                                                (fromIntegral n - fromIntegral (floor x :: Integer))
                                                (fromIntegral (floor x :: Integer) + 1)
                                                (1 - p)
        NegativeBinomial r p ->
            if x < 0
                then pure 0
                else if p == 1 then pure 1 else S.betaI r (fromIntegral (floor x :: Integer) + 1) p
        Geometric p -> pure (if x < 0 then 0 else 1 - (1 - p) ** (fromIntegral (floor x :: Integer) + 1))
        Normal mu sd -> S.normalCDF ((x - mu) / sd)
        LogNormal mu sd -> if x <= 0 then pure 0 else S.normalCDF ((log x - mu) / sd)
        Uniform a b -> pure ((x - a) / (b - a))
        Exponential rate -> pure (if x <= 0 then 0 else 1 - exp (-rate * x))
        Gamma a sc -> if x <= 0 then pure 0 else S.gammaP a (x / sc)
        Beta a b -> if x <= 0 then pure 0 else if x >= 1 then pure 1 else S.betaI a b x
        ChiSquare k -> cdf (Gamma (k / 2) 2) x
        StudentT nu -> do b <- S.betaI (nu / 2) 0.5 (nu / (nu + x * x)); pure (if x >= 0 then 1 - b / 2 else b / 2)
        FisherF a b -> if x <= 0 then pure 0 else S.betaI (a / 2) (b / 2) (a * x / (a * x + b))
        Cauchy mu sc -> pure (0.5 + atan ((x - mu) / sc) / pi)
        Laplace mu sc -> pure (if x < mu then 0.5 * exp ((x - mu) / sc) else 1 - 0.5 * exp (-(x - mu) / sc))
        Logistic mu sc -> pure (exp (-log1pexp (-(x - mu) / sc)))
        Weibull k sc -> pure (if x <= 0 then 0 else 1 - exp (-(x / sc) ** k))
        Pareto xm a -> pure (if x < xm then 0 else 1 - (xm / x) ** a)
        Rayleigh sc -> pure (if x <= 0 then 0 else 1 - exp (-x * x / (2 * sc * sc)))
        Maxwell sc ->
            if x <= 0
                then pure 0
                else do e <- S.erf (x / (sqrt 2 * sc)); pure (e - sqrt (2 / pi) * x / sc * exp (-x * x / (2 * sc * sc)))
        Gumbel mu sc -> pure (exp (-exp (-(x - mu) / sc)))
        GeneralizedExtremeValue mu sc xi ->
            if abs xi < 1e-12
                then cdf (Gumbel mu sc) x
                else
                    let t = 1 + xi * (x - mu) / sc
                     in pure (if t <= 0 then if xi > 0 then 0 else 1 else exp (-t ** (-1 / xi)))
        Triangular a b c ->
            pure
                ( if x <= a
                    then 0
                    else
                        if x >= c
                            then 1
                            else
                                if x <= b
                                    then (x - a) ^ (2 :: Int) / ((b - a) * (c - a))
                                    else 1 - (c - x) ^ (2 :: Int) / ((c - a) * (c - b))
                )
        TruncatedNormal mu sd a b ->
            if x <= a
                then pure 0
                else
                    if x >= b
                        then pure 1
                        else do
                            l <- cdf (Normal mu sd) a
                            u <- cdf (Normal mu sd) b
                            v <- cdf (Normal mu sd) x
                            require (u > l) "unresolved truncation probability"
                            pure ((v - l) / (u - l))
        Empirical xs -> pure (fromIntegral (length (filter (<= x) xs)) / fromIntegral (length xs))
        Mixture ps -> sum <$> mapM (\(w, m) -> (w *) <$> cdf m x) ps
        GaussianKDE h xs -> do ps <- mapM (\mu -> cdf (Normal mu h) x) xs; pure (sum ps / fromIntegral (length xs))
        Skellam a b -> do
            let low = a - b - 14 * sqrt (a + b) - 20; high = a - b + 14 * sqrt (a + b) + 20
            if x < low
                then pure 0
                else
                    if x >= high
                        then pure 1
                        else do
                            let start = floor low :: Integer; end = floor x
                            sum <$> mapM (density d . fromInteger) [start .. end]
        VonMises mu _ -> if x <= mu - pi then pure 0 else if x >= mu + pi then pure 1 else integrateDensity d (mu - pi) x
        _
            | isDiscrete d -> do
                let (lo, hi) = support d
                if x < lo
                    then pure 0
                    else
                        if x >= hi
                            then pure 1
                            else do
                                let start = ceiling lo :: Integer; end = floor x; count = end - start + 1
                                require (count <= 1000000) "discrete CDF summation budget exceeded"
                                sum <$> mapM (density d . fromInteger) [start .. end]
            | otherwise -> let (lo, _) = support d in if x <= lo then pure 0 else integrateDensity d lo x
    _ <- checked p
    pure (max 0 (min 1 p))

-- | P(X>x), using direct upper tails for normal, gamma, beta, t, F, binomial and Poisson to avoid cancellation. Other families use the CDF complement.
survival :: Distribution -> Double -> Either MathError Double
survival d x = do
    validateDistribution d
    require (finite x) "survival finite argument required"
    case d of
        Normal mu sd -> (/ 2) <$> S.erfc ((x - mu) / (sd * sqrt 2))
        LogNormal mu sd -> if x <= 0 then pure 1 else survival (Normal mu sd) (log x)
        Beta a b -> if x <= 0 then pure 1 else if x >= 1 then pure 0 else S.betaI b a (1 - x)
        StudentT nu -> do p <- S.betaI (nu / 2) 0.5 (nu / (nu + x * x)); pure (if x >= 0 then p / 2 else 1 - p / 2)
        FisherF a b -> if x <= 0 then pure 1 else S.betaI (b / 2) (a / 2) (b / (b + a * x))
        Gamma a sc -> if x <= 0 then pure 1 else S.gammaQ a (x / sc)
        ChiSquare k -> survival (Gamma (k / 2) 2) x
        Exponential r -> pure (if x <= 0 then 1 else exp (-r * x))
        Poisson r -> if x < 0 then pure 1 else S.gammaP (fromIntegral (floor x :: Integer) + 1) r
        Binomial n p ->
            if x < 0
                then pure 1
                else
                    if x >= fromIntegral n
                        then pure 0
                        else
                            if p == 0
                                then pure 0
                                else
                                    if p == 1
                                        then pure 1
                                        else
                                            S.betaI
                                                (fromIntegral (floor x :: Integer) + 1)
                                                (fromIntegral n - fromIntegral (floor x :: Integer))
                                                p
        _ -> (1 -) <$> cdf d x

support :: Distribution -> (Double, Double)
support d = case d of
    Bernoulli _ -> (0, 1)
    Binomial n _ -> (0, fromIntegral n)
    NegativeBinomial _ _ -> (0, 1 / 0)
    Geometric _ -> (0, 1 / 0)
    Hypergeometric n k draws -> (fromIntegral (max 0 (draws - (n - k))), fromIntegral (min draws k))
    Poisson _ -> (0, 1 / 0)
    Categorical ps -> (0, fromIntegral (length ps - 1))
    DiscreteUniform a b -> (fromIntegral a, fromIntegral b)
    Uniform a b -> (a, b)
    Beta _ _ -> (0, 1)
    Pareto xm _ -> (xm, 1 / 0)
    BetaBinomial n _ _ -> (0, fromIntegral n)
    Triangular a _ b -> (a, b)
    TruncatedNormal _ _ a b -> (a, b)
    VonMises mu _ -> (mu - pi, mu + pi)
    Empirical xs -> (minimum xs, maximum xs)
    Skellam _ _ -> (-1 / 0, 1 / 0)
    Normal _ _ -> (-1 / 0, 1 / 0)
    StudentT _ -> (-1 / 0, 1 / 0)
    Cauchy _ _ -> (-1 / 0, 1 / 0)
    Laplace _ _ -> (-1 / 0, 1 / 0)
    Logistic _ _ -> (-1 / 0, 1 / 0)
    Gumbel _ _ -> (-1 / 0, 1 / 0)
    GeneralizedExtremeValue mu sc xi ->
        if xi > 0 then (mu - sc / xi, 1 / 0) else if xi < 0 then (-1 / 0, mu - sc / xi) else (-1 / 0, 1 / 0)
    GaussianKDE _ _ -> (-1 / 0, 1 / 0)
    Mixture ps -> (minimum (map (fst . support . snd) ps), maximum (map (snd . support . snd) ps))
    _ -> (0, 1 / 0)
integrateDensity :: Distribution -> Double -> Double -> Either MathError Double
integrateDensity d a b = do
    let n = 2048 :: Int; h = (b - a) / fromIntegral n
    require (finite h && h >= 0) "integration requires finite ordered bounds"
    ys <- mapM (density d . (a +) . (h *) . fromIntegral) [0 .. n]
    checked
        ( h
            / 3
            * sum [if i == 0 || i == n then y else if odd i then 4 * y else 2 * y | (i, y) <- zip [0 ..] ys]
        )

-- | Generalized inverse CDF, p in [0,1]; endpoints return mathematical support bounds, including infinities. Interior values use analytic transforms or bounded bracketing/bisection.
quantile :: Distribution -> Double -> Either MathError Double
quantile d p = do
    validateDistribution d
    require (prob p) "quantile p outside [0,1]"
    let (a, b) = support d
    if p == 0
        then Right a
        else
            if p == 1
                then Right b
                else case d of
                    Normal mu sd -> (\z -> mu + sd * z) <$> S.normalQuantile p
                    LogNormal mu sd -> exp <$> quantile (Normal mu sd) p
                    Uniform lo hi -> pure (lo + p * (hi - lo))
                    Exponential r -> pure (-log (1 - p) / r)
                    Empirical xs -> pure (sort xs !! max 0 (ceiling (p * fromIntegral (length xs)) - 1))
                    _ -> do
                        lo <- if finite a then pure a else bracket (-1) (\v -> (< p) <$> cdf d v)
                        hi <- if finite b && b < 1000000 then pure b else bracket 1 (\v -> (>= p) <$> cdf d v)
                        if isDiscrete d then discreteSearch (ceiling lo) (ceiling hi) else continuousSearch 80 lo hi
  where
    bracket v predicate = go (64 :: Int) v
      where
        go 0 _ = Left (NonConvergence "quantile bracket" 64)
        go k x = do ok <- predicate x; if ok then pure x else go (k - 1) (2 * x)
    discreteSearch :: Integer -> Integer -> Either MathError Double
    discreteSearch lo hi
        | lo >= hi = pure (fromInteger lo)
        | otherwise = do
            let mid = lo + (hi - lo) `div` 2
            v <- cdf d (fromInteger mid)
            if v >= p then discreteSearch lo mid else discreteSearch (mid + 1) hi
    continuousSearch :: Int -> Double -> Double -> Either MathError Double
    continuousSearch 0 lo hi = pure ((lo + hi) / 2)
    continuousSearch n lo hi = do
        let m = (lo + hi) / 2
        v <- cdf d m
        if v >= p then continuousSearch (n - 1) lo m else continuousSearch (n - 1) m hi

-- | Density divided by survival. For zero survival returns positive infinity by convention.
hazard :: Distribution -> Double -> Either MathError Double
hazard d x = do f <- density d x; s <- survival d x; pure (if s == 0 then 1 / 0 else f / s)

-- | Sum of independent observation log probabilities. Impossible data produce negative infinity.
logLikelihood :: Distribution -> [Double] -> Either MathError Double
logLikelihood d xs = sum <$> mapM (logDensity d) xs

{- | Mean and population variance. Infinite/nonexistent moments return a domain
error rather than a numeric value that could be mistaken for a finite moment.
-}
moments :: Distribution -> Either MathError (Double, Double)
moments d = do
    validateDistribution d
    pair <- case d of
        Bernoulli p -> pure (p, p * (1 - p))
        Binomial n p -> pure (fromIntegral n * p, fromIntegral n * p * (1 - p))
        NegativeBinomial r p -> pure (r * (1 - p) / p, r * (1 - p) / (p * p))
        Geometric p -> pure ((1 - p) / p, (1 - p) / (p * p))
        Hypergeometric n k draws ->
            let p = fromIntegral k / fromIntegral n; m = fromIntegral draws * p
             in pure (m, if n == 1 then 0 else m * (1 - p) * fromIntegral (n - draws) / fromIntegral (n - 1))
        Poisson r -> pure (r, r)
        Categorical ps ->
            let m = sum (zipWith (*) [0 ..] ps)
             in pure (m, sum (zipWith (\i p -> p * (i - m) ^ (2 :: Int)) [0 ..] ps))
        DiscreteUniform a b ->
            pure
                ( (fromIntegral a + fromIntegral b) / 2
                , ((fromIntegral b - fromIntegral a + 1) ^ (2 :: Int) - 1) / 12
                )
        Uniform a b -> pure ((a + b) / 2, (b - a) ^ (2 :: Int) / 12)
        Normal mu sd -> pure (mu, sd * sd)
        LogNormal mu sd -> let m = exp (mu + sd * sd / 2) in checkedPair (m, m * m * (exp (sd * sd) - 1))
        Exponential r -> pure (1 / r, 1 / (r * r))
        Gamma a sc -> pure (a * sc, a * sc * sc)
        Beta a b -> pure (a / (a + b), a * b / ((a + b) ^ (2 :: Int) * (a + b + 1)))
        ChiSquare k -> pure (k, 2 * k)
        StudentT nu -> do require (nu > 2) "Student-t variance needs nu>2"; pure (0, nu / (nu - 2))
        FisherF a b -> do
            require (b > 4) "F variance needs d2>4"
            pure (b / (b - 2), 2 * b * b * (a + b - 2) / (a * (b - 2) ^ (2 :: Int) * (b - 4)))
        Cauchy _ _ -> Left (DomainError "Cauchy moments do not exist")
        Laplace mu sc -> pure (mu, 2 * sc * sc)
        Logistic mu sc -> pure (mu, pi * pi * sc * sc / 3)
        Weibull k sc -> do a <- S.gamma (1 + 1 / k); b <- S.gamma (1 + 2 / k); pure (sc * a, sc * sc * (b - a * a))
        Pareto xm a -> do
            require (a > 2) "Pareto variance needs shape>2"
            pure (a * xm / (a - 1), a * xm * xm / ((a - 1) ^ (2 :: Int) * (a - 2)))
        Rayleigh sc -> pure (sc * sqrt (pi / 2), (2 - pi / 2) * sc * sc)
        Maxwell sc -> pure (2 * sc * sqrt (2 / pi), (3 - 8 / pi) * sc * sc)
        Gumbel mu sc -> pure (mu + 0.5772156649015329 * sc, pi * pi * sc * sc / 6)
        GeneralizedExtremeValue mu sc xi ->
            if abs xi < 1e-10
                then moments (Gumbel mu sc)
                else do
                    require (xi < 0.5) "GEV variance needs xi<1/2"
                    g1 <- S.gamma (1 - xi)
                    g2 <- S.gamma (1 - 2 * xi)
                    pure (mu + sc * (g1 - 1) / xi, sc * sc / (xi * xi) * (g2 - g1 * g1))
        BetaBinomial n a b ->
            pure
                ( fromIntegral n * a / (a + b)
                , fromIntegral n * a * b * (a + b + fromIntegral n) / ((a + b) ^ (2 :: Int) * (a + b + 1))
                )
        Skellam a b -> pure (a - b, a + b)
        Triangular a b c -> pure ((a + b + c) / 3, (a * a + b * b + c * c - a * b - a * c - b * c) / 18)
        Empirical xs ->
            let m = sum xs / fromIntegral (length xs)
             in pure (m, sum (map (\x -> (x - m) ^ (2 :: Int)) xs) / fromIntegral (length xs))
        GaussianKDE h xs -> do (m, v) <- moments (Empirical xs); pure (m, v + h * h)
        Mixture ps -> do
            ms <- mapM (\(w, m) -> do (u, v) <- moments m; pure (w, u, v)) ps
            let mean = sum [w * u | (w, u, _) <- ms]
             in pure (mean, sum [w * (v + (u - mean) ^ (2 :: Int)) | (w, u, v) <- ms])
        _ -> do m <- expectation d id; second <- expectation d (\x -> x * x); pure (m, max 0 (second - m * m))
    checkedPair pair
  where
    checkedPair (a, b) = do _ <- checked a; _ <- checked b; pure (a, b)

-- | Shannon or differential entropy in nats. Closed forms are used when available; other families use the documented expectation quadrature.
entropy :: Distribution -> Either MathError Double
entropy d = do
    validateDistribution d
    case d of
        Normal _ sd -> checked (0.5 * log (2 * pi * exp 1) + log sd)
        Uniform a b -> pure (log (b - a))
        Exponential r -> pure (1 - log r)
        Bernoulli p -> pure (-xlog p p - xlog (1 - p) (1 - p))
        Categorical ps -> pure (-sum (map (\p -> xlog p p) ps))
        _ ->
            expectation
                d
                (\x -> case logDensity d x of Right lp -> if isInfinite lp then 0 else -lp; Left _ -> 0 / 0)

-- | Reference expectation under a distribution. Empirical/mixture cases are exact weighted sums; count families truncate at 1e-10 tail quantiles, continuous families use 4096 midpoint probability-space nodes. No certified quadrature error is claimed.
expectation :: Distribution -> (Double -> Double) -> Either MathError Double
expectation d f = do
    validateDistribution d
    case d of
        Empirical xs -> checked (sum (map f xs) / fromIntegral (length xs))
        Mixture pairs -> do values <- mapM (\(w, m) -> (w *) <$> expectation m f) pairs; checked (sum values)
        _ -> numeric
  where
    numeric =
        if isDiscrete d
            then do
                lo <- quantile d 1e-10
                hi <- quantile d (1 - 1e-10)
                let a = ceiling lo :: Integer; b = floor hi
                require (b - a <= 1000000) "expectation summation budget"
                terms <- mapM (\k -> do p <- density d (fromInteger k); pure (p * f (fromInteger k))) [a .. b]
                checked (sum terms)
            else do
                -- Midpoint integration over probability space handles unbounded supports.
                xs <- mapM (\i -> quantile d ((fromIntegral i + 0.5) / 4096)) [0 .. 4095 :: Int]
                checked (sum (map f xs) / 4096)

-- | Draw a model sample and updated immutable RNG; specialized gamma/normal/count samplers are reused, with inverse-CDF sampling for remaining families.
sample :: Distribution -> R.RNG -> Either MathError (Double, R.RNG)
sample d r = do
    validateDistribution d
    case d of
        Normal mu sd -> R.normal mu sd r
        Gamma a sc -> R.gamma a sc r
        Beta a b -> R.beta a b r
        Exponential rate -> R.exponential rate r
        Poisson rate -> do (x, s) <- R.poisson rate r; pure (fromIntegral x, s)
        Binomial n p -> do (x, s) <- R.binomial n p r; pure (fromIntegral x, s)
        Categorical ps -> do (x, s) <- R.weighted ps r; pure (fromIntegral x, s)
        Mixture ps -> do (i, s) <- R.weighted (map fst ps) r; sample (snd (ps !! i)) s
        GaussianKDE h xs -> do (i, s) <- R.uniformInt 0 (length xs - 1) r; R.normal (xs !! i) h s
        Empirical xs -> do (i, s) <- R.uniformInt 0 (length xs - 1) r; pure (xs !! i, s)
        _ -> let (u, s) = R.uniformOpen r in do x <- quantile d u; pure (x, s)

-- | Normal maximum-likelihood fit; variance divides by n. Constant data are rejected because this continuous family requires positive standard deviation.
fitNormal :: [Double] -> Either MathError Distribution
fitNormal xs = do
    require (not (null xs) && all finite xs) "normal fit needs finite nonempty data"
    let m = sum xs / fromIntegral (length xs)
        v = sum (map (\x -> (x - m) ^ (2 :: Int)) xs) / fromIntegral (length xs)
        d = Normal m (sqrt v)
     in validateDistribution d >> pure d

-- | Maximum-likelihood rate for nonnegative observations with strictly positive total.
fitExponential :: [Double] -> Either MathError Distribution
fitExponential xs = do
    require
        (not (null xs) && all (\x -> finite x && x >= 0) xs && sum xs > 0)
        "exponential fit nonnegative data with positive sum required"
    pure (Exponential (fromIntegral (length xs) / sum xs))

-- | Maximum-likelihood probability for nonempty binary observations.
fitBernoulli :: [Double] -> Either MathError Distribution
fitBernoulli xs = do
    require (not (null xs) && all (\x -> x == 0 || x == 1) xs) "Bernoulli fit requires binary data"
    pure (Bernoulli (sum xs / fromIntegral (length xs)))

-- | Select the maximum-likelihood model from an explicit finite candidate grid; this is grid search, not continuous parameter optimization.
fitMLEGrid :: [Distribution] -> [Double] -> Either MathError Distribution
fitMLEGrid ds xs = fitMAPGrid ds xs (const 0)

-- | Select the maximum log-likelihood plus caller-supplied log prior over a finite model grid. Log priors must be finite.
fitMAPGrid ::
    [Distribution] -> [Double] -> (Distribution -> Double) -> Either MathError Distribution
fitMAPGrid ds xs prior = do
    require (not (null ds) && not (null xs)) "grid fit requires models and observations"
    scores <-
        mapM
            ( \d -> do
                l <- logLikelihood d xs
                let p = prior d in require (finite p) "nonfinite log prior" >> pure (d, l + p)
            )
            ds
    pure (fst (maximumBy (comparing snd) scores))

-- | Conjugate Beta prior update from success/failure observations, returning posterior concentrations (alpha,beta).
betaBernoulliUpdate :: Double -> Double -> [Bool] -> Either MathError (Double, Double)
betaBernoulliUpdate a b xs = do
    require (positive a && positive b) "positive beta prior required"
    pure (a + fromIntegral (length (filter id xs)), b + fromIntegral (length (filter not xs)))

-- | Conjugate Poisson-rate update; arguments and result use Gamma shape/rate, deliberately distinct from the Gamma distribution constructor shape/scale.
gammaPoissonUpdate :: Double -> Double -> [Int] -> Either MathError (Double, Double)
gammaPoissonUpdate shapePrior ratePrior xs = do
    require
        (positive shapePrior && positive ratePrior && all (>= 0) xs)
        "positive Gamma shape/rate prior and counts required"
    pure (shapePrior + sum (map fromIntegral xs), ratePrior + fromIntegral (length xs))

-- | Known-variance conjugate normal mean update. Arguments are prior mean, prior variance, observation variance and observations; returns posterior mean/variance.
normalNormalUpdate :: Double -> Double -> Double -> [Double] -> Either MathError (Double, Double)
normalNormalUpdate mu priorVariance observationVariance xs = do
    require
        (finite mu && positive priorVariance && positive observationVariance && all finite xs)
        "normal update requires finite mean and positive variances"
    let precision = 1 / priorVariance + fromIntegral (length xs) / observationVariance
     in pure ((mu / priorVariance + sum xs / observationVariance) / precision, 1 / precision)

-- | Compute P(A|B) from joint P(A intersection B) and strictly positive P(B).
conditionalProbability :: Double -> Double -> Either MathError Double
conditionalProbability joint given = do
    require
        (prob joint && positive given && given <= 1 && joint <= given)
        "conditional probability invalid joint/marginal"
    pure (joint / given)

-- | Normalize prior probabilities times observation likelihoods. A zero-evidence observation is rejected.
bayes :: [Double] -> [Double] -> Either MathError [Double]
bayes priors likelihoods = do
    require
        ( length priors == length likelihoods
            && not (null priors)
            && all prob priors
            && all prob likelihoods
            && abs (sum priors - 1) < 1e-12
        )
        "Bayes invalid probabilities"
    let ws = zipWith (*) priors likelihoods
     in require (sum ws > 0) "zero evidence" >> pure (map (/ sum ws) ws)

-- | Two-sided one-sample Kolmogorov distance against a specified CDF. Returns the distance only; no discrete-null p-value is implied.
goodnessOfFit :: Distribution -> [Double] -> Either MathError Double
goodnessOfFit d xs = do
    require (not (null xs) && all finite xs) "KS goodness needs finite observations"
    ps <- mapM (cdf d) (sort xs)
    let n = fromIntegral (length xs)
     in pure
            ( maximum
                [maximum [p - fromIntegral i / n, fromIntegral (i + 1) / n - p] | (i, p) <- zip [0 :: Int ..] ps]
            )

-- | Construct an equal-weight Gaussian kernel density with strictly positive bandwidth and finite nonempty observations.
gaussianKDE :: Double -> [Double] -> Either MathError Distribution
gaussianKDE h xs = let d = GaussianKDE h xs in validateDistribution d >> pure d

-- | Multinomial mass for probabilities summing to one and nonnegative count vector; log-gamma arithmetic avoids factorial overflow.
multinomialPMF :: [Double] -> [Int] -> Either MathError Double
multinomialPMF ps counts = do
    require
        (length ps == length counts && all prob ps && abs (sum ps - 1) < 1e-12 && all (>= 0) counts)
        "multinomial invalid probabilities/counts"
    a <- S.logGamma (fromIntegral (sum counts) + 1)
    bs <- mapM (\c -> S.logGamma (fromIntegral c + 1)) counts
    pure (exp (a - sum bs + sum (zipWith (\c p -> xlog (fromIntegral c) p) counts ps)))

-- | Dirichlet density on the strictly positive simplex interior. Concentration and coordinate vectors must have matching nonzero length.
dirichletDensity :: [Double] -> [Double] -> Either MathError Double
dirichletDensity as xs = do
    require
        ( not (null as)
            && length as == length xs
            && all positive as
            && all positive xs
            && abs (sum xs - 1) < 1e-10
        )
        "Dirichlet requires positive simplex interior and concentrations"
    a <- S.logGamma (sum as)
    bs <- mapM S.logGamma as
    checked (exp (a - sum bs + sum (zipWith (\p x -> (p - 1) * log x) as xs)))

-- | Log density for a finite mean/point and symmetric positive-definite covariance, validated by Cholesky.
multivariateNormalLogDensity :: [Double] -> Matrix Double -> [Double] -> Either MathError Double
multivariateNormalLogDensity mu covariance x = do
    require
        ( not (null mu)
            && length mu == length x
            && shape covariance == (length mu, length mu)
            && all finite (mu ++ x)
        )
        "multivariate normal shape or input"
    _ <- cholesky covariance
    det <- determinant covariance
    z <- solve covariance (zipWith (-) x mu)
    checked
        (-0.5 * (fromIntegral (length mu) * log (2 * pi) + log det + sum (zipWith (*) z (zipWith (-) x mu))))

-- | Cholesky-transform independent standard normals; returns a vector and updated state.
sampleMultivariateNormal :: [Double] -> Matrix Double -> R.RNG -> Either MathError ([Double], R.RNG)
sampleMultivariateNormal mu covariance r = do
    require
        (not (null mu) && shape covariance == (length mu, length mu) && all finite mu)
        "multivariate normal sampling shape"
    l <- cholesky covariance
    (zs, s) <- R.sampleN (length mu) (R.normal 0 1) r
    let n = length mu
        ys = [mu !! i + sum [toList l !! (i * n + j) * zs !! j | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
    pure (ys, s)

-- | Wishart log density for real degrees of freedom nu>p-1 and positive-definite p-by-p scale and observation matrices.
wishartLogDensity :: Double -> Matrix Double -> Matrix Double -> Either MathError Double
wishartLogDensity nu scale x = do
    let p = fst (shape scale)
    require
        (p > 0 && shape scale == (p, p) && shape x == (p, p) && finite nu && nu > fromIntegral (p - 1))
        "Wishart degrees of freedom must exceed p-1"
    _ <- cholesky scale
    _ <- cholesky x
    ds <- determinant scale
    dx <- determinant x
    inv <- inverse scale
    prod <- multiplyChecked inv x
    gs <- mapM (\j -> S.logGamma ((nu + 1 - fromIntegral j) / 2)) [1 .. p]
    let tr = sum [toList prod !! (j * p + j) | j <- [0 .. p - 1]]
        lg = fromIntegral (p * (p - 1)) / 4 * log pi + sum gs
    checked
        ( (nu - fromIntegral p - 1) / 2 * log dx
            - tr / 2
            - nu * fromIntegral p / 2 * log 2
            - nu / 2 * log ds
            - lg
        )

-- | Reference Wishart draw as the sum of nu Gaussian outer products; requires integer nu>=p and nu\<=100000.
sampleWishart :: Int -> Matrix Double -> R.RNG -> Either MathError (Matrix Double, R.RNG)
sampleWishart nu scale r = do
    let p = fst (shape scale)
    require
        (p > 0 && shape scale == (p, p) && nu >= p && nu <= 100000)
        "Wishart reference sampler uses integer nu>=p"
    (ys, s) <- R.sampleN nu (sampleMultivariateNormal (replicate p 0) scale) r
    mat <- fromListChecked nu p (concat ys)
    x <- multiplyChecked (transposeMatrix mat) mat
    pure (x, s)

-- | Opaque finite row-stochastic transition matrix.
newtype Markov = Markov [[Double]] deriving (Eq, Show)

-- | Validate and construct a row-stochastic matrix with 1..1024 states; row sums tolerate absolute error 1e-12.
markov :: [[Double]] -> Either MathError Markov
markov rows = do
    let n = length rows
    require
        (n > 0 && n <= 1024 && all (\r -> length r == n && all prob r && abs (sum r - 1) < 1e-12) rows)
        "Markov transition matrix rows must be probabilities"
    pure (Markov rows)

-- | Advance a normalized state-probability row vector by one Markov step.
transition :: Markov -> [Double] -> Either MathError [Double]
transition (Markov rows) ps = do
    require
        (length ps == length rows && all prob ps && abs (sum ps - 1) < 1e-10)
        "invalid state probabilities"
    pure [sum [ps !! i * rows !! i !! j | i <- [0 .. length ps - 1]] | j <- [0 .. length ps - 1]]

-- | Stationary probabilities by damped power iteration, with caller iteration budget and positive residual tolerance. Reducible chains can have multiple stationary laws.
stationary :: Int -> Double -> Markov -> Either MathError [Double]
stationary budget tol m@(Markov rows) = do
    require (budget > 0 && positive tol) "stationary requires positive budget and tolerance"
    -- Cesaro damping preserves stationary states and converges for periodic chains.
    let go 0 _ = Left (NonConvergence "stationary distribution" budget)
        go n p = do
            q <- transition m p
            let z = zipWith (\a b -> (a + b) / 2) p q
             in if maximum (zipWith (\a b -> abs (a - b)) p q) < tol then pure q else go (n - 1) z
    go budget (replicate (length rows) (1 / fromIntegral (length rows)))

-- | Opaque finite-state categorical-emission hidden Markov model.
data HMM = HMM [Double] [[Double]] [[Double]] deriving (Eq, Show)

-- | Validate initial probabilities, square transition matrix and equally sized categorical-emission rows.
hmm :: [Double] -> [[Double]] -> [[Double]] -> Either MathError HMM
hmm initial trans emissions = do
    _ <- markov trans
    let n = length trans; k = case emissions of [] -> 0; r : _ -> length r
    require
        ( length initial == n
            && all prob initial
            && abs (sum initial - 1) < 1e-12
            && length emissions == n
            && k > 0
            && all (\r -> length r == k && all prob r && abs (sum r - 1) < 1e-12) emissions
        )
        "HMM invalid initial/emission probabilities"
    pure (HMM initial trans emissions)

-- | Check a nonempty HMM observation sequence of zero-based emission-symbol indices.
validateObservations :: HMM -> [Int] -> Either MathError ()
validateObservations (HMM _ _ es) obs =
    require
        (not (null obs) && all (\x -> x >= 0 && x < length (es !! 0)) obs)
        "HMM requires valid nonempty observation sequence"

{- | Scaled forward returns log likelihood, normalized alpha rows and per-time
scaling constants. This avoids the product underflow of raw probability DP.
-}
forward :: HMM -> [Int] -> Either MathError (Double, [[Double]], [Double])
forward model@(HMM initial trans es) obs = do
    validateObservations model obs
    let norm xs =
            let c = sum xs in require (positive c) "HMM zero observation likelihood" >> pure (map (/ c) xs, c)
    (a, c) <- norm (zipWith (*) initial [es !! i !! (obs !! 0) | i <- [0 .. length initial - 1]])
    let step (as, cs) o = do
            let prev = last as
                next =
                    [ es !! j !! o * sum [prev !! i * trans !! i !! j | i <- [0 .. length initial - 1]]
                    | j <- [0 .. length initial - 1]
                    ]
            (v, s) <- norm next
            pure (as ++ [v], cs ++ [s])
    (as, cs) <- foldM step ([a], [c]) (drop 1 obs)
    pure (sum (map log cs), as, cs)

-- | Scaled backward messages using the same per-time normalizers as forward; terminal message is the all-ones vector.
backward :: HMM -> [Int] -> Either MathError [[Double]]
backward model@(HMM initial trans es) obs = do
    (_, _, cs) <- forward model obs
    let n = length initial
        t = length obs
        go k rows
            | k < 0 = rows
            | otherwise =
                let next = (case rows of a : _ -> a; [] -> replicate n 1)
                    b =
                        [ sum [trans !! i !! j * es !! j !! (obs !! (k + 1)) * next !! j | j <- [0 .. n - 1]]
                            / (cs !! (k + 1))
                        | i <- [0 .. n - 1]
                        ]
                 in go (k - 1) (b : rows)
    pure (go (t - 2) [replicate n 1])

-- | Posterior state probabilities at each observation time from normalized alpha-beta products.
posteriorStates :: HMM -> [Int] -> Either MathError [[Double]]
posteriorStates model obs = do
    (_, as, _) <- forward model obs
    bs <- backward model obs
    pure [let ps = zipWith (*) a b in map (/ sum ps) ps | (a, b) <- zip as bs]

-- | Most likely state path and its joint log probability, via max-product dynamic programming in log space.
viterbi :: HMM -> [Int] -> Either MathError ([Int], Double)
viterbi model@(HMM initial trans es) obs = do
    validateObservations model obs
    let start = [(log p + log (es !! i !! (obs !! 0)), [i]) | (i, p) <- zip [0 ..] initial]
        step states o =
            [ maximumBy
                (comparing fst)
                [ (l + log (trans !! i !! j) + log (es !! j !! o), previousPath ++ [j])
                | (i, (l, previousPath)) <- zip [0 ..] states
                ]
            | j <- [0 .. length initial - 1]
            ]
        (score, path) = maximumBy (comparing fst) (Foldable.foldl' step start (drop 1 obs))
    require (finite score) "HMM no possible state path"
    pure (path, score)

{- | Baum--Welch EM for one observation sequence, pseudocount>=0. Transition
rows with zero expected occupancy retain their old row. Fixed iteration budget.
-}
baumWelch :: Int -> Double -> HMM -> [Int] -> Either MathError HMM
baumWelch count pseudo initialModel obs = do
    require
        (count >= 0 && count <= 10000 && finite pseudo && pseudo >= 0)
        "Baum-Welch invalid iteration count/pseudocount"
    foldM (\model _ -> step model) initialModel [1 .. count]
  where
    step model@(HMM _ trans es) = do
        (_, as, cs) <- forward model obs
        bs <- backward model obs
        gs <- posteriorStates model obs
        let n = length trans
            k = length (es !! 0)
            t = length obs
            norm old xs = if sum xs == 0 then old else map (/ sum xs) xs
            xis i j =
                sum
                    [ (as !! u !! i)
                        * trans !! i !! j
                        * es !! j !! (obs !! (u + 1))
                        * (bs !! (u + 1) !! j)
                        / (cs !! (u + 1))
                    | u <- [0 .. t - 2]
                    ]
            tr = [norm (trans !! i) [pseudo + xis i j | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
            em =
                [ norm
                    (es !! i)
                    [pseudo + sum [gs !! u !! i | u <- [0 .. t - 1], obs !! u == symbol] | symbol <- [0 .. k - 1]]
                | i <- [0 .. n - 1]
                ]
        hmm (gs !! 0) tr em
