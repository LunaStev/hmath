-- SPDX-License-Identifier: MPL-2.0

{- | Explicit optimizer state for deterministic gradients, SGD and minibatches.
Defaults: beta1=.9,beta2=.999,epsilon=1e-8; RMSProp/AdaDelta rho=.9;
AdamW decays weights by .01*learningRate. Bias corrections use one-based steps.
-}
module HMath.Optimization.FirstOrder (
    GradientMethod (..),
    OptimizerState,
    initializeOptimizer,
    optimizerStep,
    minimizeGradient,
    minimizeGradientWithCallback,
    stochasticGradient,
    miniBatchGradient,
    projectedGradient,
    proximalGradient,
    fista,
    coordinateDescent,
) where

import Control.Monad (foldM)
import HMath.Error
import HMath.Optimization.Common

data GradientMethod
    = GradientDescent
    | Momentum
    | Nesterov
    | AdaGrad
    | RMSProp
    | AdaDelta
    | Adam
    | AdamW
    | AMSGrad
    | AdaMax
    | Nadam
    | RAdam
    deriving (Eq, Show, Enum, Bounded)
data OptimizerState = OptimizerState Int [Double] [Double] [Double] deriving (Eq, Show)

-- | Allocate zero momentum/moment buffers for a nonnegative parameter count.
initializeOptimizer :: Int -> Either MathError OptimizerState
initializeOptimizer n
    | n < 0 = Left (InvalidArgument "negative optimizer dimension")
    | otherwise = Right (OptimizerState 0 (replicate n 0) (replicate n 0) (replicate n 0))

-- | Apply one checked stateful update using the supplied gradient and positive rate. Nesterov here applies a corrected momentum direction; minimizeGradient evaluates the actual look-ahead gradient.
optimizerStep ::
    GradientMethod ->
    Double ->
    OptimizerState ->
    [Double] ->
    [Double] ->
    Either MathError ([Double], OptimizerState)
optimizerStep method rate (OptimizerState t m v u) x g = do
    checkedPoint (rate : x ++ g ++ m ++ v ++ u)
    if rate <= 0 || any ((/= length x) . length) [g, m, v, u]
        then Left (InvalidArgument "optimizer rate or state shape")
        else Right ()
    let t' = t + 1
        b1 = 0.9
        b2 = 0.999
        eps = 1e-8
        m' = zipWith (\a b -> b1 * a + (1 - b1) * b) m g
        v' = zipWith (\a b -> b2 * a + (1 - b2) * b * b) v g
        mh = scale (1 / (1 - b1 ^ t')) m'
        vh = scale (1 / (1 - b2 ^ t')) v'
        plain a b = a / (sqrt b + eps)
        (direction, newM, newV, newU) = case method of
            GradientDescent -> (g, m, v, u)
            Momentum -> let vel = add (scale b1 m) g in (vel, vel, v, u)
            Nesterov -> let vel = add (scale b1 m) g in (add g (scale b1 vel), vel, v, u)
            AdaGrad -> let vs = zipWith (\a b -> a + b * b) v g in (zipWith plain g vs, m, vs, u)
            RMSProp -> let vs = zipWith (\a b -> 0.9 * a + 0.1 * b * b) v g in (zipWith plain g vs, m, vs, u)
            AdaDelta ->
                let vs = zipWith (\a b -> 0.9 * a + 0.1 * b * b) v g
                    ds = zipWith3 (\a b c -> sqrt (a + eps) / sqrt (b + eps) * c) u vs g
                    us = zipWith (\a b -> 0.9 * a + 0.1 * b * b) u ds
                 in (ds, m, vs, us)
            Adam -> (zipWith plain mh vh, m', v', u)
            AdamW -> (add (zipWith plain mh vh) (scale 0.01 x), m', v', u)
            AMSGrad -> let us = zipWith max u v' in (zipWith plain mh (scale (1 / (1 - b2 ^ t')) us), m', v', us)
            AdaMax ->
                let us = zipWith (\a b -> max (b2 * a) (abs b)) u g
                 in (zipWith (\a b -> a / (b + eps)) mh us, m', v', us)
            Nadam ->
                let nm = add (scale b1 mh) (scale ((1 - b1) / (1 - b1 ^ t')) g) in (zipWith plain nm vh, m', v', u)
            RAdam ->
                let rhoInf = 2 / (1 - b2) - 1
                    rho = rhoInf - 2 * fromIntegral t' * b2 ^ t' / (1 - b2 ^ t')
                    rect = sqrt ((rho - 4) * (rho - 2) * rhoInf / ((rhoInf - 4) * (rhoInf - 2) * rho))
                 in (if rho > 4 then scale rect (zipWith plain mh vh) else mh, m', v', u)
        next = sub x (scale rate direction)
    checkedPoint (next ++ direction ++ newM ++ newV ++ newU)
    Right (next, OptimizerState t' newM newV newU)

-- | Minimize with explicit gradient/state and fixed learning rate. Only finite gradient residuals below tolerance certify convergence.
minimizeGradient ::
    GradientMethod ->
    OptimizeOptions ->
    Objective ->
    Gradient ->
    [Double] ->
    Either MathError OptimizeResult
minimizeGradient = minimizeGradientWithCallback (const (Right True))

{- | Observe each finite iterate after its objective/gradient evaluation. False
stops explicitly with convergence=False; callback failures propagate. Callback
observations do not themselves count as objective or derivative evaluations.
-}
minimizeGradientWithCallback ::
    (OptimizeResult -> Either MathError Bool) ->
    GradientMethod ->
    OptimizeOptions ->
    Objective ->
    Gradient ->
    [Double] ->
    Either MathError OptimizeResult
minimizeGradientWithCallback callback method o f g x0 = do
    checkedOptions o
    state <- initializeOptimizer (length x0)
    loop 0 0 state x0
  where
    loop k n state x = do
        checkBudget o (n + 2)
        y <- checkedValue f x
        gs <- checkedGradient g x
        let current = OptimizeResult x y (norm gs) k (n + 2) (norm gs <= optTolerance o)
        continue <- callback current
        if not continue
            then Right current{optConverged = False}
            else
                if norm gs <= optTolerance o
                    then Right current
                    else
                        if k >= optMaxIterations o
                            then Left (NonConvergence (show method) k)
                            else do
                                -- True Nesterov evaluates the gradient at the look-ahead point.
                                actual <- case (method, state) of
                                    (Nesterov, OptimizerState _ velocity _ _) -> do checkBudget o (n + 3); checkedGradient g (sub x (scale (0.9 * optLearningRate o) velocity))
                                    _ -> Right gs
                                (next, state') <-
                                    optimizerStep (if method == Nesterov then Momentum else method) (optLearningRate o) state x actual
                                loop (k + 1) (n + if method == Nesterov then 3 else 2) state' next

{- | One pass over explicit sample/batch gradients; ordering and shuffling are
caller-owned, allowing exact replay. All gradients are checked before update.
-}
stochasticGradient ::
    GradientMethod -> Double -> [Gradient] -> [Double] -> Either MathError ([Double], OptimizerState)
stochasticGradient method rate grads x0 = do
    checkedPoint (rate : x0)
    if rate <= 0 then Left (InvalidArgument "positive stochastic learning rate required") else Right ()
    s <- initializeOptimizer (length x0)
    foldM
        (\(x, state) g -> do gs <- checkedGradient g x; optimizerStep method rate state x gs)
        (x0, s)
        grads

-- | Average a nonempty explicit set of same-length checked sample gradients at the current parameters.
miniBatchGradient :: [Gradient] -> Gradient
miniBatchGradient [] _ = Left (InvalidArgument "empty mini batch")
miniBatchGradient gradients x = do
    checkedPoint x
    gs <- mapM (`checkedGradient` x) gradients
    let average = foldl' add (replicate (length x) 0) (map (scale (1 / fromIntegral (length gs))) gs)
    checkedPoint average
    Right average

-- | Project every update and stop on the projected-gradient mapping, including constrained boundary optima.
projectedGradient ::
    OptimizeOptions ->
    Objective ->
    Gradient ->
    ([Double] -> Either MathError [Double]) ->
    [Double] ->
    Either MathError OptimizeResult
projectedGradient o f g project = proximalGradient o f g (\_ -> project)

-- | Apply prox(rate,point) after each gradient step; residual is the proximal-gradient mapping norm.
proximalGradient ::
    OptimizeOptions ->
    Objective ->
    Gradient ->
    (Double -> [Double] -> Either MathError [Double]) ->
    [Double] ->
    Either MathError OptimizeResult
proximalGradient o f g prox x0 = do checkedOptions o; loop 0 0 x0
  where
    loop k n x = do
        checkBudget o (n + 3)
        gs <- checkedGradient g x
        y <- prox (optLearningRate o) (sub x (scale (optLearningRate o) gs))
        if length y /= length x then Left (InvalidArgument "proximal shape") else checkedPoint y
        val <- checkedValue f y
        let residual = norm (scale (1 / optLearningRate o) (sub x y))
        if residual <= optTolerance o
            then Right (OptimizeResult y val residual k (n + 3) True)
            else
                if k >= optMaxIterations o
                    then Left (NonConvergence "proximal gradient" k)
                    else loop (k + 1) (n + 3) y

-- | Accelerated proximal gradient using the Beck-Teboulle t recurrence and a fresh mapping residual at accepted points.
fista ::
    OptimizeOptions ->
    Objective ->
    Gradient ->
    (Double -> [Double] -> Either MathError [Double]) ->
    [Double] ->
    Either MathError OptimizeResult
fista o f g prox x0 = do checkedOptions o; loop 0 0 1 x0 x0
  where
    loop k n t x y = do
        checkBudget o (n + 3)
        gy <- checkedGradient g y
        z <- prox (optLearningRate o) (sub y (scale (optLearningRate o) gy))
        if length z /= length x then Left (InvalidArgument "FISTA proximal shape") else checkedPoint z
        gz <- checkedGradient g z
        p <- prox (optLearningRate o) (sub z (scale (optLearningRate o) gz))
        if length p /= length z then Left (InvalidArgument "FISTA proximal shape") else checkedPoint p
        val <- checkedValue f z
        let residual = norm (scale (1 / optLearningRate o) (sub z p)); t' = (1 + sqrt (1 + 4 * t * t)) / 2
        if residual <= optTolerance o
            then Right (OptimizeResult z val residual k (n + 3) True)
            else
                if k >= optMaxIterations o
                    then Left (NonConvergence "FISTA" k)
                    else loop (k + 1) (n + 3) t' z (add z (scale ((t - 1) / t') (sub z x)))

-- | Cyclic coordinates or blocks; every coordinate must occur exactly once.
coordinateDescent ::
    [[Int]] -> OptimizeOptions -> Objective -> Gradient -> [Double] -> Either MathError OptimizeResult
coordinateDescent blocks o f g x0 = do
    checkedOptions o
    let ids = concat blocks; n = length x0
    if any null blocks || length ids /= n || any (\i -> length (filter (== i) ids) /= 1) [0 .. n - 1]
        then Left (InvalidArgument "coordinate blocks must partition variables")
        else loop 0 0 x0
  where
    loop k n x = do
        checkBudget o (n + 2 + length blocks)
        gs <- checkedGradient g x
        val <- checkedValue f x
        if norm gs <= optTolerance o
            then Right (OptimizeResult x val (norm gs) k (n + 2) True)
            else
                if k >= optMaxIterations o
                    then Left (NonConvergence "coordinate descent" k)
                    else do
                        y <-
                            foldM
                                ( \z block -> do
                                    dz <- checkedGradient g z
                                    Right [if i `elem` block then a - optLearningRate o * (dz !! i) else a | (i, a) <- zip [0 ..] z]
                                )
                                x
                                blocks
                        loop (k + 1) (n + 2 + length blocks) y
