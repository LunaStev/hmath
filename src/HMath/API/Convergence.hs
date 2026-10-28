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

data Convergence a = Convergence
    {estimate :: a, iterationCount :: !Int, finalResidual :: !Double, stopReason :: !StopReason}
    deriving (Eq, Show, Functor, Foldable, Traversable)
data IterationOptions = IterationOptions
    {maximumIterations :: !Int, absoluteTolerance :: !Double, relativeTolerance :: !Double}
    deriving (Eq, Show)
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

requireConvergence :: String -> Convergence a -> Either MathError a
requireConvergence name r
    | stopReason r == ResidualSatisfied = Right (estimate r)
    | otherwise = Left (NonConvergence name (iterationCount r))

-- | Explicitly discard error details for callers retaining a Maybe interface.
resultMaybe :: Either e a -> Maybe a
resultMaybe = either (const Nothing) Just

fromMaybeError :: e -> Maybe a -> Either e a
fromMaybeError e = maybe (Left e) Right
