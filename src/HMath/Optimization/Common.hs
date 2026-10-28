-- SPDX-License-Identifier: MPL-2.0

{- | Shared checked Double objective contracts. Finite deterministic callbacks
return structured failures. Budgets count objective/gradient/Hessian calls,
including line-search trials, rather than only accepted steps.
-}
module HMath.Optimization.Common (
    Objective,
    Gradient,
    Hessian,
    OptimizeOptions (..),
    defaultOptimizeOptions,
    OptimizeResult (..),
    checkedOptions,
    checkedPoint,
    checkedValue,
    checkedGradient,
    dot,
    norm,
    add,
    sub,
    scale,
    identity,
    matVec,
    transpose,
    matMul,
    outer,
    solveDense,
    result,
    checkBudget,
    LearningRate (..),
    learningRate,
    EarlyStopping (..),
    earlyStopping,
    LineSearch (..),
    lineSearch,
) where

import Data.List (transpose)
import HMath.Error
import qualified HMath.Matrix as M
import qualified HMath.Matrix.LU as LU

-- | Scalar objective function over a parameter vector, supplied by the optimization caller.
type Objective = [Double] -> Either MathError Double

{- | Caller-supplied gradient components in parameter order; dimension/finite checks occur
in the consuming optimizer.
-}
type Gradient = [Double] -> Either MathError [Double]

{- | Caller-supplied second-derivative matrix in parameter order, consumed by checked Newton
methods.
-}
type Hessian = [Double] -> Either MathError [[Double]]

{- | Finite optimization work budgets,tolerance,and method step rate. Start from
defaultOptimizeOptions.
-}
data OptimizeOptions = OptimizeOptions
    { optMaxIterations :: Int
    -- ^ Maximum optimization iterations.
    , optMaxEvaluations :: Int
    -- ^ Maximum objective/evaluation work budget.
    , optTolerance :: Double
    -- ^ Positive finite method-specific stopping tolerance.
    , optLearningRate :: Double
    -- ^ Positive finite step-size/rate where used by the method.
    }
    deriving (Eq, Show)

{- | Default optimization options: 1000 iterations, 20000 evaluations, tolerance 1e-8 and
learning rate 0.01. Customize with record updates; algorithms validate the selected
settings.
-}
defaultOptimizeOptions :: OptimizeOptions
defaultOptimizeOptions = OptimizeOptions 1000 20000 1e-8 0.01

{- | Accepted parameters and diagnostics. optGradientNorm is the Euclidean
gradient norm for smooth methods, the projected/proximal mapping for proximal
methods, and a method-specific geometric stopping residual for derivative-free
methods. Stochastic searches cannot certify global optimality.
-}
data OptimizeResult = OptimizeResult
    { optPoint :: [Double]
    -- ^ Returned parameter vector at the accepted estimate.
    , optValue :: Double
    -- ^ Objective value at optPoint.
    , optGradientNorm :: Double
    -- ^ Gradient,projected/proximal,or geometric stopping residual as defined by the selected method.
    , optIterations :: Int
    -- ^ Completed optimization iterations.
    , optEvaluations :: Int
    -- ^ Recorded objective/evaluation count.
    , optConverged :: Bool
    -- ^ Whether the selected method met its stopping criterion; this does not certify a global optimum.
    }
    deriving (Eq, Show)

-- | Require finite positive tolerance/rate and positive iteration/evaluation budgets.
checkedOptions :: OptimizeOptions -> Either MathError ()
checkedOptions o
    | optMaxIterations o < 1 || optMaxEvaluations o < 1 =
        Left (InvalidArgument "positive optimization budgets required")
    | any (\x -> isNaN x || isInfinite x || x <= 0) [optTolerance o, optLearningRate o] =
        Left InvalidTolerance
    | otherwise = Right ()

-- | Reject NaN/infinity, including finite-input arithmetic overflow caught at solver boundaries.
checkedPoint :: [Double] -> Either MathError ()
checkedPoint xs
    | any (\x -> isNaN x || isInfinite x) xs = Left NonFiniteResult
    | otherwise = Right ()

-- | Evaluate a deterministic objective at finite coordinates and reject a nonfinite value.
checkedValue :: Objective -> [Double] -> Either MathError Double
checkedValue f x = do checkedPoint x; y <- f x; checkedPoint [y]; Right y

-- | Evaluate a finite gradient of exactly the input dimension.
checkedGradient :: Gradient -> [Double] -> Either MathError [Double]
checkedGradient g x = do
    checkedPoint x
    ys <- g x
    if length x /= length ys
        then Left (VectorLengthMismatch (length x) (length ys))
        else checkedPoint ys
    Right ys

-- | Reject a proposed evaluation total that exceeds the supplied limit; equality is permitted.
checkBudget :: OptimizeOptions -> Int -> Either MathError ()
checkBudget o n =
    if n > optMaxEvaluations o
        then Left (NonConvergence "optimization evaluation budget" n)
        else Right ()

-- | Internal same-length dot kernel; public algorithms validate shapes and finite arithmetic at their boundaries.
dot :: [Double] -> [Double] -> Double
dot a b = sum (zipWith (*) a b)

-- | Scaled Euclidean norm. A mathematical norm beyond Double range remains positive infinity.
norm :: [Double] -> Double
norm xs =
    let m = maximum (0 : map abs xs)
     in if m == 0 then 0 else m * sqrt (sum (map (\x -> (x / m) ^ (2 :: Int)) xs))

-- | Internal same-length vector kernels; shape validation belongs to the public checked caller.
add, sub :: [Double] -> [Double] -> [Double]
add = zipWith (+)
sub = zipWith (-)

-- | Multiply each vector component by a scalar.
scale :: Double -> [Double] -> [Double]
scale a = map (* a)

-- | Dense identity matrix for a checked nonnegative dimension.
identity :: Int -> [[Double]]
identity n = [[if i == j then 1 else 0 | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]

-- | Dense row-major matrix-vector kernel for shapes already validated by the caller.
matVec :: [[Double]] -> [Double] -> [Double]
matVec m v = map (`dot` v) m

-- | Dense row-major matrix multiplication for compatible checked inner dimensions.
matMul :: [[Double]] -> [[Double]] -> [[Double]]
matMul a b = [[dot row col | col <- transpose b] | row <- a]

-- | Outer product preserving input coordinate order.
outer :: [Double] -> [Double] -> [[Double]]
outer a b = map (\x -> scale x b) a

-- | Checked square dense LU solve; singular and nonfinite systems return MathError.
solveDense :: [[Double]] -> [Double] -> Either MathError [Double]
solveDense a b
    | length a /= length b || any ((/= length b) . length) a =
        Left (InvalidArgument "square system shape")
    | otherwise = do
        checkedPoint (concat a ++ b); m <- M.fromListChecked (length b) (length b) (concat a); LU.solve m b

-- | Build diagnostics from a final objective and gradient, charging both callbacks.
result :: Int -> Int -> Bool -> Objective -> Gradient -> [Double] -> Either MathError OptimizeResult
result k n converged f g x = do
    y <- checkedValue f x
    gs <- checkedGradient g x
    checkedPoint [norm gs]
    Right (OptimizeResult x y (norm gs) k (n + 2) converged)

{- | Selected constant or scheduled learning-rate policy, with method-specific parameters
validated by the schedule function.
-}
data LearningRate
    = ConstantRate Double
    | StepDecay Double Int Double
    | ExponentialDecay Double Double
    | CosineAnnealing Double Double Int
    | Warmup Int LearningRate
    deriving (Eq, Show)

-- | Evaluate a nonnegative explicit schedule at a zero-based step; warmup scales the initial steps linearly.
learningRate :: LearningRate -> Int -> Either MathError Double
learningRate schedule step
    | step < 0 = Left (InvalidArgument "negative schedule step")
    | otherwise = do
        value <- case schedule of
            ConstantRate r -> Right r
            StepDecay r period decay
                | period > 0 && decay > 0 -> Right (r * decay ^ (step `div` period))
                | otherwise -> Left (InvalidArgument "step schedule parameters")
            ExponentialDecay r decay
                | decay > 0 -> Right (r * decay ^ step)
                | otherwise -> Left (InvalidArgument "exponential schedule decay")
            CosineAnnealing hi lo period
                | period > 0 && hi >= lo && lo >= 0 ->
                    Right (lo + (hi - lo) * (1 + cos (pi * fromIntegral (min step period) / fromIntegral period)) / 2)
                | otherwise -> Left (InvalidArgument "cosine schedule parameters")
            Warmup steps base
                | steps > 0 -> do
                    r <- learningRate base (max 0 (step - steps))
                    Right (r * min 1 (fromIntegral (step + 1) / fromIntegral steps))
                | otherwise -> Left (InvalidArgument "warmup steps")
        checkedPoint [value]
        if value < 0 then Left (InvalidArgument "negative learning rate") else Right value

{- | Explicit monitoring state retaining the best score,nonimproving count,and stop flag; it
does not mutate an optimizer automatically.
-}
data EarlyStopping = EarlyStopping
    { bestScore :: Maybe Double
    -- ^ Best monitored score so far, or Nothing before the first observation.
    , staleSteps :: Int
    -- ^ Consecutive monitoring updates without sufficient improvement.
    , stopped :: Bool
    -- ^ Whether early-stopping patience has been exhausted.
    }
    deriving (Eq, Show)

-- | Track strict improvement beyond minDelta; stop after patience stale observations.
earlyStopping :: Int -> Double -> Double -> EarlyStopping -> Either MathError EarlyStopping
earlyStopping patience minDelta value state = do
    checkedPoint [minDelta, value]
    if patience < 1 || minDelta < 0
        then Left (InvalidArgument "early stopping parameters")
        else Right ()
    let improved = maybe True (\old -> value < old - minDelta) (bestScore state)
        stale = if improved then 0 else staleSteps state + 1
    Right (EarlyStopping (if improved then Just value else bestScore state) stale (stale >= patience))

-- | Step selection policy: Armijo backtracking or strong-Wolfe conditions.
data LineSearch = Armijo | StrongWolfe deriving (Eq, Show)

{- | Backtracking Armijo or bracket-and-zoom strong Wolfe (c1=1e-4,c2=.9).
The return includes all objective/gradient trials; descent is required.
-}
lineSearch ::
    LineSearch ->
    Int ->
    Objective ->
    Gradient ->
    [Double] ->
    [Double] ->
    Double ->
    [Double] ->
    Either MathError (Double, Double, [Double], Int)
lineSearch method budget f g x direction fx gx
    | length x /= length direction || length x /= length gx =
        Left (InvalidArgument "line search vector shape")
    | budget < 2 = Left (NonConvergence "line search budget" 0)
    | dot gx direction >= 0 = Left (DomainError "line search requires descent")
    | otherwise = search 0 0 1 fx
  where
    slope = dot gx direction
    trial a = do
        let point = add x (scale a direction)
        y <- checkedValue f point
        gy <- checkedGradient g point
        Right (y, gy, dot gy direction)
    search k prev a prevY
        | 2 * k + 2 > budget = Left (NonConvergence "line search" k)
        | otherwise = do
            (y, gy, d) <- trial a
            if y > fx + 1e-4 * a * slope || (k > 0 && y >= prevY)
                then zoom (k + 1) prev a prevY
                else
                    if method == Armijo || abs d <= -0.9 * slope
                        then Right (a, y, gy, 2 * k + 2)
                        else
                            if d >= 0
                                then zoom (k + 1) a prev y
                                else search (k + 1) a (2 * a) y
    zoom k lo hi ylo
        | 2 * k + 2 > budget || abs (hi - lo) < 1e-16 = Left (NonConvergence "Wolfe zoom" k)
        | otherwise = do
            let a = (lo + hi) / 2
            (y, gy, d) <- trial a
            if y > fx + 1e-4 * a * slope || y >= ylo
                then zoom (k + 1) lo a ylo
                else
                    if abs d <= -0.9 * slope
                        then Right (a, y, gy, 2 * k + 2)
                        else if d * (hi - lo) >= 0 then zoom (k + 1) a lo y else zoom (k + 1) a hi y
