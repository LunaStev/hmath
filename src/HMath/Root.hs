-- SPDX-License-Identifier: MPL-2.0

{- | Checked Double root solvers. Absolute residual and mixed absolute/relative
step tolerances are separate. A small step alone never certifies a root.
All function and derivative calls count against the evaluation budget.
Sign-changing isolation finds simple roots; exact polynomial Sturm isolation
additionally finds even/repeated roots with multiplicity. Callback functions
must be deterministic and total on points visited by the chosen method.
-}
module HMath.Root (
    RootOptions (..),
    defaultRootOptions,
    RootResult (..),
    Bracket,
    bracket,
    BracketMethod (..),
    solveBracket,
    bracketScan,
    isolateIntervals,
    DerivativeMethod (..),
    solveDerivative,
    secant,
    steffensen,
    FixedPointMethod (..),
    fixedPoint,
    anderson,
    SystemMethod (..),
    SystemRootResult (..),
    solveSystem,
    polynomialRoots,
    realPolynomialRoots,
) where

import Control.Monad (foldM)
import Data.Complex (Complex)
import Data.List (sortOn)
import HMath.Error
import qualified HMath.Matrix as M
import qualified HMath.Matrix.LU as LU
import qualified HMath.Polynomial as P

data RootOptions = RootOptions
    { rootMaxIterations :: Int
    , rootMaxEvaluations :: Int
    , rootTolerance :: Double
    , rootStepTolerance :: Double
    }
    deriving (Eq, Show)
defaultRootOptions :: RootOptions
defaultRootOptions = RootOptions 200 4000 1e-10 1e-12
data RootResult = RootResult
    { rootValue :: Double
    , rootResidual :: Double
    , rootErrorBound :: Maybe Double
    , rootIterations :: Int
    , rootEvaluations :: Int
    }
    deriving (Eq, Show)
data Bracket = Bracket Double Double Double Double deriving (Eq, Show)
data BracketMethod = Bisection | RegulaFalsi | Illinois | Brent | Ridder deriving (Eq, Show)
data DerivativeMethod = Newton | Halley | Householder3 deriving (Eq, Show)
data FixedPointMethod = Picard | Aitken | SteffensenFixed deriving (Eq, Show)
data SystemMethod = MultivariateNewton | NewtonTrustRegion Double | Broyden deriving (Eq, Show)
data SystemRootResult = SystemRootResult
    { systemRoot :: [Double]
    , systemResidual :: Double
    , systemIterations :: Int
    , systemEvaluations :: Int
    }
    deriving (Eq, Show)
finite :: Double -> Bool
finite x = not (isNaN x || isInfinite x)
valid :: RootOptions -> Either MathError ()
valid o
    | rootMaxIterations o < 1 || rootMaxEvaluations o < 1 =
        Left (InvalidArgument "root budgets must be positive")
    | not (all finite [rootTolerance o, rootStepTolerance o])
        || rootTolerance o <= 0
        || rootStepTolerance o <= 0 =
        Left InvalidTolerance
    | otherwise = Right ()
call :: RootOptions -> (Double -> Double) -> Int -> Double -> Either MathError (Double, Int)
call o f n x
    | n >= rootMaxEvaluations o = Left (NonConvergence "root evaluation budget" n)
    | not (finite x) = Left NonFiniteResult
    | otherwise = let y = f x in if finite y then Right (y, n + 1) else Left NonFiniteResult

-- | Validate finite a<b and endpoint roots or opposite signs; construction never assumes a discontinuity is a root.
bracket :: (Double -> Double) -> Double -> Double -> Either MathError Bracket
bracket f a b
    | not (all finite [a, b]) || a >= b = Left (InvalidArgument "root bracket requires finite a < b")
    | not (all finite [fa, fb]) = Left NonFiniteResult
    | fa /= 0 && fb /= 0 && signum fa == signum fb =
        Left (DomainError "root endpoints do not bracket a sign change")
    | otherwise = Right (Bracket a b fa fb)
  where
    fa = f a; fb = f b

{- | Brackets are re-evaluated with the supplied function, preventing stale or
mismatched endpoint caches from certifying a different function's root.
-}
solveBracket ::
    BracketMethod -> RootOptions -> (Double -> Double) -> Bracket -> Either MathError RootResult
solveBracket method o f (Bracket a0 b0 _ _) = do
    valid o
    (fa, n1) <- call o f 0 a0
    (fb, n2) <- call o f n1 b0
    _ <- bracket (\x -> if x == a0 then fa else fb) a0 b0
    loop 0 n2 a0 b0 fa fb fa fb Nothing (0 :: Int)
  where
    loop k n a b fa fb wa wb old side
        | abs fa <= rootTolerance o = Right (RootResult a (abs fa) (Just (b - a)) k n)
        | abs fb <= rootTolerance o = Right (RootResult b (abs fb) (Just (b - a)) k n)
        | k >= rootMaxIterations o = Left (NonConvergence (show method) k)
        | otherwise = do
            let mid = a + (b - a) / 2
                interp = if wb == wa then mid else a - wa * (b - a) / (wb - wa)
                guarded z = if finite z && z > a + 0.01 * (b - a) && z < b - 0.01 * (b - a) then z else mid
            (x, fx, n') <- case method of
                Bisection -> do (y, m) <- call o f n mid; Right (mid, y, m)
                RegulaFalsi -> do
                    let z = if interp > a && interp < b then interp else mid
                    (y, m) <- call o f n z
                    Right (z, y, m)
                Illinois -> do
                    let z = if interp > a && interp < b then interp else mid
                    (y, m) <- call o f n z
                    Right (z, y, m)
                Brent -> do
                    -- Inverse quadratic interpolation with the previous trial;
                    -- a central safeguard guarantees interval contraction.
                    let z = case old of
                            Just (c, fc)
                                | fa /= fb && fa /= fc && fb /= fc ->
                                    a * fb * fc / ((fa - fb) * (fa - fc))
                                        + b * fa * fc / ((fb - fa) * (fb - fc))
                                        + c * fa * fb / ((fc - fa) * (fc - fb))
                            _ -> interp
                        trial = guarded z
                    (y, m) <- call o f n trial
                    Right (trial, y, m)
                Ridder -> do
                    (fm, m) <- call o f n mid
                    let scale = maximum [abs fa, abs fb, abs fm]
                        disc = (fm / scale) ^ (2 :: Int) - (fa / scale) * (fb / scale)
                        trial =
                            if scale == 0 || disc <= 0
                                then mid
                                else guarded (mid + (mid - a) * signum (fa - fb) * (fm / scale) / sqrt disc)
                    if trial == mid then Right (mid, fm, m) else do (y, q) <- call o f m trial; Right (trial, y, q)
            if abs fx <= rootTolerance o
                then Right (RootResult x (abs fx) (Just (b - a)) (k + 1) n')
                else
                    if x == a || x == b || b - a <= rootStepTolerance o * (1 + abs x)
                        then
                            Left
                                (NonConvergence "bracket collapsed without residual convergence (possible discontinuity)" (k + 1))
                        else
                            if signum fa /= signum fx
                                then
                                    loop
                                        (k + 1)
                                        n'
                                        a
                                        x
                                        fa
                                        fx
                                        (if method == Illinois && side == 1 then wa / 2 else fa)
                                        fx
                                        (Just (b, fb))
                                        1
                                else
                                    loop
                                        (k + 1)
                                        n'
                                        x
                                        b
                                        fx
                                        fb
                                        fx
                                        (if method == Illinois && side == (-1) then wb / 2 else fb)
                                        (Just (a, fa))
                                        (-1)

-- | Evaluate a uniform finite grid under the evaluation budget and return every endpoint/sign-change bracket.
bracketScan ::
    RootOptions -> (Double -> Double) -> Double -> Double -> Int -> Either MathError [Bracket]
bracketScan o f a b cells = do
    valid o
    if cells < 1
        || toInteger cells + 1 > toInteger (rootMaxEvaluations o)
        || not (all finite [a, b])
        || a >= b
        then Left (InvalidArgument "invalid root scan grid or budget")
        else Right ()
    samples <-
        mapM
            ( \i ->
                let x = a + (b - a) * (fromIntegral i / fromIntegral cells)
                 in do (y, _) <- call o f i x; Right (x, y)
            )
            [0 .. cells]
    Right
        [ Bracket x y fx fy
        | ((x, fx), (y, fy)) <- zip samples (drop 1 samples)
        , fx == 0 || fy == 0 || signum fx /= signum fy
        ]

-- | Refine sign-change scan brackets and deduplicate endpoint roots. Even roots require polynomial isolation.
isolateIntervals ::
    RootOptions -> (Double -> Double) -> Double -> Double -> Int -> Either MathError [RootResult]
isolateIntervals o f a b cells = do
    bs <- bracketScan o f a b cells
    rs <- mapM (solveBracket Brent o f) bs
    Right (dedup (sortOn rootValue rs))
  where
    dedup [] = []
    dedup (x : xs) =
        x
            : dedup
                ( dropWhile
                    (\y -> abs (rootValue y - rootValue x) <= rootStepTolerance o * (1 + abs (rootValue x)))
                    xs
                )

{- | Derivatives [f', f'', f'''] are required through order 1, 2, or 3.
Householder3 is the order-four rational Householder update.
-}
solveDerivative ::
    DerivativeMethod ->
    RootOptions ->
    (Double -> Double) ->
    [Double -> Double] ->
    Double ->
    Either MathError RootResult
solveDerivative method o f derivatives x0 = do
    valid o
    if length derivatives < required
        then Left (InvalidArgument "insufficient analytic derivatives")
        else loop 0 0 x0
  where
    required = case method of Newton -> 1; Halley -> 2; Householder3 -> 3
    loop k n x = do
        (y, n1) <- call o f n x
        if abs y <= rootTolerance o
            then Right (RootResult x (abs y) Nothing k n1)
            else
                if k >= rootMaxIterations o
                    then Left (NonConvergence (show method) k)
                    else do
                        (ds, n2) <-
                            foldM
                                (\(vs, m) d -> do (v, q) <- call o d m x; Right (vs ++ [v], q))
                                ([], n1)
                                (take required derivatives)
                        let d = ds !! 0
                        if d == 0 then Left (DomainError "zero root derivative") else Right ()
                        let u = y / d
                            delta = case method of
                                Newton -> u
                                Halley -> u / (1 - u * (ds !! 1) / (2 * d))
                                Householder3 -> u * (1 - u * (ds !! 1) / (2 * d)) / (1 - u * (ds !! 1) / d + u * u * (ds !! 2) / (6 * d))
                            x' = x - delta
                        if not (finite x')
                            then Left NonFiniteResult
                            else
                                if x' == x
                                    then Left (NonConvergence "derivative iteration stagnated" k)
                                    else loop (k + 1) n2 x'

-- | Unbracketed two-point secant iteration; zero slopes, stagnation, and exhausted budgets fail explicitly.
secant :: RootOptions -> (Double -> Double) -> Double -> Double -> Either MathError RootResult
secant o f a b = do
    valid o
    (fa, n) <- call o f 0 a
    loop 0 n a fa b
  where
    loop k n x fx y = do
        (fy, n') <- call o f n y
        if abs fy <= rootTolerance o
            then Right (RootResult y (abs fy) Nothing k n')
            else
                if k >= rootMaxIterations o
                    then Left (NonConvergence "secant" k)
                    else
                        if fy == fx
                            then Left (DomainError "secant zero slope")
                            else
                                let z = y - fy * (y - x) / (fy - fx)
                                 in if z == y then Left (NonConvergence "secant stagnation" k) else loop (k + 1) n' y fy z

-- | Derivative-free Steffensen root update using f(x+f(x)); termination checks the original residual.
steffensen :: RootOptions -> (Double -> Double) -> Double -> Either MathError RootResult
steffensen o f x0 = do valid o; loop 0 0 x0
  where
    loop k n x = do
        (fx, m) <- call o f n x
        if abs fx <= rootTolerance o
            then Right (RootResult x (abs fx) Nothing k m)
            else
                if k >= rootMaxIterations o
                    then Left (NonConvergence "Steffensen" k)
                    else do
                        (fy, q) <- call o f m (x + fx)
                        let den = fy - fx
                        if den == 0
                            then Left (DomainError "Steffensen zero denominator")
                            else loop (k + 1) q (x - fx * fx / den)

-- | Picard iteration, non-restarted Aitken sequence acceleration, or restarted Steffensen acceleration.
fixedPoint ::
    FixedPointMethod -> RootOptions -> (Double -> Double) -> Double -> Either MathError RootResult
fixedPoint method o g x0 = do
    valid o
    if method == Aitken then aitkenLoop 0 0 x0 else loop 0 0 x0
  where
    loop k n x = do
        (y, m) <- call o g n x
        let r = abs (y - x)
        if r <= rootTolerance o
            then Right (RootResult x r Nothing k m)
            else
                if k >= rootMaxIterations o
                    then Left (NonConvergence (show method) k)
                    else case method of
                        Picard -> loop (k + 1) m y
                        Aitken -> accelerate k m x y
                        SteffensenFixed -> accelerate k m x y
    -- Aitken accelerates the raw sequence without restarting; Steffensen
    -- restarts at each Δ² estimate. Each tests the original fixed-point residual.
    aitkenLoop k n x = do
        (y, m) <- call o g n x
        (z, q) <- call o g m y
        let denominator = z - 2 * y + x
            estimate = if denominator == 0 then y else x - (y - x) * (y - x) / denominator
        (value, count) <- call o g q estimate
        let residual = abs (value - estimate)
        if residual <= rootTolerance o
            then Right (RootResult estimate residual Nothing k count)
            else
                if k >= rootMaxIterations o
                    then Left (NonConvergence "Aitken raw sequence" k)
                    else aitkenLoop (k + 1) count y
    accelerate k n x y = do
        (z, m) <- call o g n y
        let d = z - 2 * y + x; next = if d == 0 then y else x - (y - x) * (y - x) / d
        loop (k + 1) m next

norm :: [Double] -> Double
norm xs = maximum (0 : map abs xs)
vectorCall ::
    RootOptions -> ([Double] -> [Double]) -> Int -> [Double] -> Either MathError ([Double], Int)
vectorCall o f n x
    | n >= rootMaxEvaluations o = Left (NonConvergence "system evaluation budget" n)
    | not (all finite x) = Left NonFiniteResult
    | otherwise =
        let y = f x
         in if length y /= length x
                then Left (VectorLengthMismatch (length x) (length y))
                else if all finite y then Right (y, n + 1) else Left NonFiniteResult
linearSolve :: [[Double]] -> [Double] -> Either MathError [Double]
linearSolve a b = do m <- M.fromListChecked (length a) (length a) (concat a); LU.solve m b

{- | Anderson mixing with depth m and Tikhonov regularization. Residuals are
g(x)-x. Solving the constrained residual Gram system is a bounded reference
implementation; it does not pretend to use a low-storage QR update.
-}
anderson ::
    Int ->
    Double ->
    RootOptions ->
    ([Double] -> [Double]) ->
    [Double] ->
    Either MathError SystemRootResult
anderson depth regularization o g x0 = do
    valid o
    if depth < 1 || regularization <= 0 || not (finite regularization) || null x0
        then Left (InvalidArgument "Anderson depth, regularization, or dimension")
        else loop 0 0 [] x0
  where
    loop k n hist x = do
        (gx, m) <- vectorCall o g n x
        let r = zipWith (-) gx x
        if norm r <= rootTolerance o
            then Right (SystemRootResult x (norm r) k m)
            else
                if k >= rootMaxIterations o
                    then Left (NonConvergence "Anderson" k)
                    else do
                        let hs = take depth ((gx, r) : hist)
                            p = length hs
                            dot a b = sum (zipWith (*) a b)
                            gram =
                                [ [dot a b + if i == j then regularization else 0 | (j, (_, b)) <- zip [0 :: Int ..] hs]
                                | (i, (_, a)) <- zip [0 :: Int ..] hs
                                ]
                            aug = map (++ [1]) gram ++ [replicate p 1 ++ [0]]
                        coeffs <- linearSolve aug (replicate p 0 ++ [1])
                        let next = [sum [c * (a !! j) | (c, (a, _)) <- zip coeffs hs] | j <- [0 .. length x - 1]]
                        loop (k + 1) m hs next

-- | Solve a square analytic-Jacobian system using Newton, trust-radius Newton, or rank-one Broyden updates.
solveSystem ::
    SystemMethod ->
    RootOptions ->
    ([Double] -> [Double]) ->
    ([Double] -> [[Double]]) ->
    [Double] ->
    Either MathError SystemRootResult
solveSystem method o f jac x0 = do
    valid o
    if null x0 then Left (InvalidArgument "empty nonlinear system") else Right ()
    case method of
        NewtonTrustRegion radius | radius <= 0 || not (finite radius) -> Left (InvalidArgument "positive trust radius required")
        _ -> Right ()
    let radius = case method of NewtonTrustRegion r -> r; _ -> 1
    (fx, n) <- vectorCall o f 0 x0
    if norm fx <= rootTolerance o
        then Right (SystemRootResult x0 (norm fx) 0 n)
        else do
            if n >= rootMaxEvaluations o then Left (NonConvergence "Jacobian evaluation budget" n) else Right ()
            j <- checkedJac x0
            loop 0 (n + 1) radius x0 fx j
  where
    checkedJac x =
        let j = jac x; n = length x
         in if length j /= n || any ((/= n) . length) j
                then Left (InvalidArgument "Jacobian shape")
                else if all finite (concat j) then Right j else Left NonFiniteResult
    loop k n radius x fx j
        | norm fx <= rootTolerance o = Right (SystemRootResult x (norm fx) k n)
        | k >= rootMaxIterations o || n >= rootMaxEvaluations o = Left (NonConvergence "nonlinear system" k)
        | otherwise = do
            raw <- linearSolve j (map negate fx)
            let magnitude = maximum (0 : map abs raw)
                unitNorm = if magnitude == 0 then 0 else sqrt (sum [(z / magnitude) ^ (2 :: Int) | z <- raw])
                step = case method of
                    NewtonTrustRegion _
                        | magnitude > 0 && magnitude > radius / unitNorm ->
                            map (\z -> (z / magnitude) * (radius / unitNorm)) raw
                    _ -> raw
                candidate = zipWith (+) x step
            (fy, n1) <- vectorCall o f n candidate
            case method of
                _ | norm fy <= rootTolerance o -> Right (SystemRootResult candidate (norm fy) (k + 1) n1)
                NewtonTrustRegion _ | norm fy >= norm fx -> loop (k + 1) n1 (radius / 2) x fx j
                _ -> do
                    (j', n2) <- case method of
                        Broyden -> do
                            let y = zipWith (-) fy fx
                                js = map (sum . zipWith (*) step) j
                                stepMagnitude = maximum (0 : map abs step)
                                unit = map (/ stepMagnitude) step
                                denominator = sum (map (\z -> z * z) unit)
                            if stepMagnitude == 0
                                then Left (NonConvergence "Broyden zero step" k)
                                else do
                                    let updated =
                                            zipWith
                                                (\row delta -> zipWith (+) row (map (* ((delta / stepMagnitude) / denominator)) unit))
                                                j
                                                (zipWith (-) y js)
                                    if all finite (concat updated) then Right (updated, n1) else Left NonFiniteResult
                        _ ->
                            if norm fy <= rootTolerance o
                                then Right (j, n1)
                                else do
                                    if n1 >= rootMaxEvaluations o
                                        then Left (NonConvergence "Jacobian evaluation budget" n1)
                                        else Right ()
                                    a <- checkedJac candidate
                                    Right (a, n1 + 1)
                    loop (k + 1) n2 (min (radius * 1.5) 1e6) candidate fy j'

-- | Reuse the checked Aberth-Ehrlich simultaneous complex solver for an ascending-coefficient polynomial.
polynomialRoots :: RootOptions -> P.Polynomial (Complex Double) -> Either MathError [Complex Double]
polynomialRoots o p = do valid o; P.aberthEhrlich (rootMaxIterations o) (rootTolerance o) p

-- | Use exact square-free factorization and Sturm isolation; return rational intervals and integer multiplicities.
realPolynomialRoots ::
    Int -> Rational -> P.Polynomial Rational -> Either MathError [(Rational, Rational, Int)]
realPolynomialRoots budget tolerance p = do
    if null (P.coefficients p)
        then Left (DomainError "zero polynomial has infinitely many roots")
        else Right ()
    pieces <-
        mapM
            ( \(factor, multiplicity) -> do
                intervals <- P.isolateRealRoots budget tolerance factor
                Right [(a, b, multiplicity) | (a, b) <- intervals]
            )
            (P.squareFreeFactors p)
    Right (sortOn (\(a, _, _) -> a) (concat pieces))
