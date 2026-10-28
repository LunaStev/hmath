{-# LANGUAGE DeriveFoldable #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE DeriveTraversable #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ViewPatterns #-}

-- SPDX-License-Identifier: MPL-2.0

{- | Uniform iteration reports retain the best current estimate on an exhausted
budget. Input/domain failures use Either; successful execution need not mean
numerical convergence. Residuals are finite nonnegative absolute measures.
-}
module HMath.API.Convergence (
    StopReason (..),
    Convergence (..),
    IterationOptions (..),
    defaultIterationOptions,
    iterateUntil,
    requireConvergence,
    resultMaybe,
    fromMaybeError,
    pattern Converged,
) where

import HMath.Error

{- | Stagnation is opt-in and uses an exact-equality caller predicate; it does
not reinterpret a small update as proof of a small residual.
-}
data StopReason = ResidualSatisfied | IterationLimit | Stagnation deriving (Eq, Show)

{- | Iteration report retaining the estimate and residual even on a budget/stagnation stop.
Inspect stopReason before assuming convergence.
-}
data Convergence a = Convergence
    { estimate :: a
    -- ^ Best current estimate, retained even when the iteration budget is exhausted.
    , iterationCount :: !Int
    -- ^ Number of completed updates; the initial estimate is iteration zero.
    , finalResidual :: !Double
    -- ^ Finite nonnegative absolute residual at the returned estimate.
    , stopReason :: !StopReason
    -- ^ ResidualSatisfied,IterationLimit,or Stagnation; successful execution does not itself imply convergence.
    }
    deriving (Eq, Show, Functor, Foldable, Traversable)

{- | Caller-controlled iteration count and absolute/relative stopping tolerances, validated
by iterateUntil.
-}
data IterationOptions = IterationOptions
    { maximumIterations :: !Int
    -- ^ Nonnegative maximum number of updates permitted by iterateUntil.
    , absoluteTolerance :: !Double
    -- ^ Finite nonnegative absolute stopping threshold.
    , relativeTolerance :: !Double
    -- ^ Finite nonnegative tolerance scaled by the initial residual.
    }
    deriving (Eq, Show)

{- | Default iteration budget 1000, absolute tolerance 1e-12, relative tolerance 1e-10. Use
record updates to configure a solver; iterateUntil validates nonnegative finite
tolerances.
-}
defaultIterationOptions :: IterationOptions
defaultIterationOptions = IterationOptions 1000 1e-12 1e-10

-- | Read-only successful view. The report still retains its residual and count.
pattern Converged :: a -> Convergence a
pattern Converged x <- Convergence x _ _ ResidualSatisfied

{- | Stop at residual <= atol + rtol * initialResidual. Comparisons are scaled
to avoid overflow in that sum. The initial value is tested at iteration zero.
-}
iterateUntil ::
    IterationOptions ->
    (a -> Either MathError a) ->
    (a -> Either MathError Double) ->
    (a -> a -> Bool) ->
    a ->
    Either MathError (Convergence a)
iterateUntil options step residual stagnant initial = do
    let limit = maximumIterations options
        atol = absoluteTolerance options
        rtol = relativeTolerance options
    if limit < 0 || not (finite atol && finite rtol) || atol < 0 || rtol < 0
        then Left (InvalidArgument "invalid convergence budget/tolerances")
        else Right ()
    initialResidual <- residual initial >>= checkResidual
    loop initialResidual 0 initial initialResidual
  where
    finite x = not (isNaN x || isInfinite x)
    checkResidual x
        | finite x && x >= 0 = Right x
        | otherwise = Left (DomainError "residual must be finite and nonnegative")
    satisfied initialResidual current
        | current <= absoluteTolerance options = True
        | initialResidual == 0 = False
        | otherwise = (current - absoluteTolerance options) / initialResidual <= relativeTolerance options
    loop initialResidual n x r
        | satisfied initialResidual r = Right (Convergence x n r ResidualSatisfied)
        | n >= maximumIterations options = Right (Convergence x n r IterationLimit)
        | otherwise = do
            y <- step x
            ry <- residual y >>= checkResidual
            if not (satisfied initialResidual ry) && stagnant x y
                then Right (Convergence y (n + 1) ry Stagnation)
                else loop initialResidual (n + 1) y ry

{- | Given operation name then convergence report, return its estimate only for
ResidualSatisfied. IterationLimit or Stagnation becomes Left (NonConvergence name
iterationCount), preserving the distinction between execution and convergence.
-}
requireConvergence :: String -> Convergence a -> Either MathError a
requireConvergence name r
    | stopReason r == ResidualSatisfied = Right (estimate r)
    | otherwise = Left (NonConvergence name (iterationCount r))

-- | Explicitly discard error details for callers retaining a Maybe interface.
resultMaybe :: Either e a -> Maybe a
resultMaybe = either (const Nothing) Just

{- | Given error value then Maybe result, convert Nothing to Left error and Just x to Right
x. Example: fromMaybeError "missing" (Just 3) == Right 3.
-}
fromMaybeError :: e -> Maybe a -> Either e a
fromMaybeError e = maybe (Left e) Right
