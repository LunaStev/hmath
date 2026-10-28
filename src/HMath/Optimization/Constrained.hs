-- SPDX-License-Identifier: MPL-2.0

{- | Dense bounded reference constrained optimization. Inequalities use g(x)<=0.
LP uses nonnegative variables and Ax<=b, supports negative right-hand sides
through phase I, and reports infeasibility/unboundedness. Revised simplex has
an explicit feasible-basis contract. Convex QP enumerates active sets up to a
caller budget; it is intended for small problems, not a sparse QP backend.
-}
module HMath.Optimization.Constrained (
    Constraint (..),
    feasibility,
    PenaltyMethod (..),
    constrainedMinimize,
    LPResult (..),
    linearProgramming,
    revisedSimplex,
    quadraticProgramming,
    slsqp,
    cobyla,
    weightedObjective,
    paretoFront,
) where

import qualified Data.Foldable as Foldable (foldl')
import Data.List (nub, sort)
import HMath.Error
import HMath.Optimization.Common
import HMath.Optimization.Local (QuasiNewton (BFGS), minimizeQuasiNewton)

{- | Scalar Equality or LessEqual constraint over the parameter vector; inequality functions
use the solver's \<=0 convention.
-}
data Constraint = Equality Objective Gradient | LessEqual Objective Gradient

{- | Constrained-optimization strategy selecting quadratic penalty,log barrier,augmented
Lagrangian,or interior-point treatment.
-}
data PenaltyMethod = QuadraticPenalty | LogBarrier | InteriorPoint | AugmentedLagrangian
    deriving (Eq, Show)

constraintValues :: [Constraint] -> [Double] -> Either MathError [(Bool, Double, [Double])]
constraintValues cs x = mapM value cs
  where
    value c = case c of
        Equality f g -> do y <- checkedValue f x; gs <- checkedGradient g x; Right (True, y, gs)
        LessEqual f g -> do y <- checkedValue f x; gs <- checkedGradient g x; Right (False, y, gs)

-- | Return maximum absolute equality or positive inequality violation, with checked values and gradients.
feasibility :: [Constraint] -> [Double] -> Either MathError Double
feasibility cs x = do
    values <- constraintValues cs x
    Right (maximum (0 : [if eq then abs y else max 0 y | (eq, y, _) <- values]))

-- | Outer continuation or multiplier updates around the named constrained objective. Every inner callback charges its nested objective/constraint/gradient calls; barriers require strict feasibility.
constrainedMinimize ::
    PenaltyMethod ->
    OptimizeOptions ->
    Objective ->
    Gradient ->
    [Constraint] ->
    [Double] ->
    Either MathError OptimizeResult
constrainedMinimize method o f g constraints x0 = do
    checkedOptions o
    if method == LogBarrier || method == InteriorPoint
        then do
            vals <- constraintValues constraints x0
            if any (\(eq, v, _) -> eq || v >= 0) vals
                then Left (DomainError "log barrier requires strictly feasible inequalities only")
                else Right ()
        else Right ()
    loop 0 0 1 (replicate (length constraints) 0) x0
  where
    loop outerIter cost strength multipliers x
        | outerIter >= min 40 (optMaxIterations o) = Left (NonConvergence (show method) outerIter)
        | otherwise = do
            let evaluate z = do
                    base <- checkedValue f z
                    vals <- constraintValues constraints z
                    terms <-
                        mapM
                            ( \((eq, v, _), lambda) -> case method of
                                LogBarrier -> if v >= 0 then Left (DomainError "outside barrier") else Right (-log (-v) / strength)
                                InteriorPoint -> if v >= 0 then Left (DomainError "outside interior") else Right (-log (-v) / strength)
                                QuadraticPenalty -> Right (strength / 2 * (if eq then v * v else max 0 v ^ (2 :: Int)))
                                AugmentedLagrangian ->
                                    Right
                                        ( if eq
                                            then lambda * v + strength * v * v / 2
                                            else ((max 0 (lambda + strength * v)) ^ (2 :: Int) - lambda * lambda) / (2 * strength)
                                        )
                            )
                            (zip vals multipliers)
                    Right (base + sum terms)
                derivative z = do
                    base <- checkedGradient g z
                    vals <- constraintValues constraints z
                    terms <-
                        mapM
                            ( \((eq, v, gs), lambda) -> do
                                coeff <- case method of
                                    LogBarrier -> if v >= 0 then Left (DomainError "outside barrier") else Right (-1 / (strength * v))
                                    InteriorPoint -> if v >= 0 then Left (DomainError "outside interior") else Right (-1 / (strength * v))
                                    QuadraticPenalty -> Right (strength * (if eq then v else max 0 v))
                                    AugmentedLagrangian -> Right (if eq then lambda + strength * v else max 0 (lambda + strength * v))
                                Right (scale coeff gs)
                            )
                            (zip vals multipliers)
                    Right (Foldable.foldl' add base terms)
                inner =
                    o
                        { optMaxIterations = max 10 (optMaxIterations o `div` 2)
                        , optMaxEvaluations = (optMaxEvaluations o - cost) `div` (1 + 2 * length constraints)
                        , optTolerance = max (optTolerance o / 10) (1 / (strength * strength) * 1e-4)
                        }
            -- A feasible backtracking gradient subsolver avoids evaluating an
            -- unconstrained line search outside the open barrier domain.
            r <-
                if method == LogBarrier || method == InteriorPoint
                    then barrierInner inner evaluate derivative x
                    else minimizeQuasiNewton BFGS inner evaluate derivative x
            let xn = optPoint r; cost' = cost + optEvaluations r * (1 + 2 * length constraints)
            checkBudget o (cost' + 2 + 2 * length constraints)
            vals <- constraintValues constraints xn
            gs <- checkedGradient g xn
            let nextLambda =
                    [ let base = if method == QuadraticPenalty then 0 else l
                       in if eq then base + strength * v else max 0 (base + strength * v)
                    | ((eq, v, _), l) <- zip vals multipliers
                    ]
                lagGradient = Foldable.foldl' add gs [scale l d | ((_, _, d), l) <- zip vals nextLambda]
                violation = maximum (0 : [if eq then abs v else max 0 v | (eq, v, _) <- vals])
                dual =
                    if method == LogBarrier || method == InteriorPoint
                        then fromIntegral (length constraints) / strength
                        else norm lagGradient
            value <- checkedValue f xn
            checkBudget o (cost' + 2 + 2 * length constraints)
            if violation <= optTolerance o && dual <= sqrt (optTolerance o)
                then
                    Right
                        ( OptimizeResult
                            xn
                            value
                            (max violation dual)
                            (outerIter + 1)
                            (cost' + 2 + 2 * length constraints)
                            True
                        )
                else loop (outerIter + 1) (cost' + 2 + 2 * length constraints) (strength * 10) nextLambda xn
    barrierInner opts obj grad start = go 0 0 start
      where
        go k count x = do
            checkBudget opts (count + 2)
            y <- checkedValue obj x
            gs <- checkedGradient grad x
            if norm gs <= optTolerance opts
                then Right (OptimizeResult x y (norm gs) k (count + 2) True)
                else
                    if k >= optMaxIterations opts
                        then Right (OptimizeResult x y (norm gs) k (count + 2) False)
                        else do
                            (next, used) <- backtrack (optMaxEvaluations opts - count - 2) 0 1 y gs x
                            go (k + 1) (count + 2 + used) next
        backtrack remaining k rate y gs x
            | k >= remaining = Left (NonConvergence "barrier evaluation budget" k)
            | k >= 50 = Left (NonConvergence "barrier feasible line search" k)
            | otherwise =
                let next = sub x (scale rate gs)
                 in case checkedValue obj next of
                        Right yn | yn <= y - 1e-4 * rate * dot gs gs -> Right (next, k + 1)
                        Left (DomainError _) -> backtrack remaining (k + 1) (rate / 2) y gs x
                        Left e -> Left e
                        _ -> backtrack remaining (k + 1) (rate / 2) y gs x

{- | Linear-program primal solution,objective value,retained basis indices,and iteration
count.
-}
data LPResult = LPResult
    { lpPoint :: [Double]
    -- ^ Returned primal variable vector of the linear program.
    , lpValue :: Double
    -- ^ Objective value at the returned LP point.
    , lpBasis :: [Int]
    -- ^ Zero-based basis indices retained by the simplex solution.
    , lpIterations :: Int
    -- ^ Number of simplex iterations performed.
    }
    deriving (Eq, Show)

{- | Primal two-phase simplex with Bland entering/leaving rules. Tolerance is
used for feasibility and reduced costs, not to round returned variable data.
-}
linearProgramming ::
    Int -> Double -> [Double] -> [[Double]] -> [Double] -> Either MathError LPResult
linearProgramming budget tolerance c a b = do
    if budget < 1 || tolerance <= 0
        then Left (InvalidArgument "LP tolerance/budget")
        else checkedPoint (tolerance : c ++ concat a ++ b)
    let n = length c
        m = length b
        negative = [i | (i, bi) <- zip [0 :: Int ..] b, bi < 0]
        q = length negative
        total = n + m + q
    if length a /= m || any ((/= n) . length) a
        then Left (InvalidArgument "LP constraint shape")
        else Right ()
    let rows =
            [ let sign = if bi < 0 then -1 else 1
                  slack = [if j == i then sign else 0 | j <- [0 .. m - 1]]
                  artificial = [if Just k == lookup i (zip negative [0 ..]) then 1 else 0 | k <- [0 .. q - 1]]
               in scale sign row ++ slack ++ artificial ++ [abs bi]
            | (i, (row, bi)) <- zip [0 ..] (zip a b)
            ]
        basis = [if bi < 0 then n + m + length (filter (< i) negative) else n + i | (i, bi) <- zip [0 ..] b]
        phaseCost = replicate (n + m) 0 ++ replicate q 1
    (r1, b1, k1) <- simplexTable budget tolerance phaseCost rows basis 0
    let phaseValue = sum [phaseCost !! j * (row !! total) | (row, j) <- zip r1 b1]
    if phaseValue > tolerance then Left (DomainError "infeasible linear program") else Right ()
    (r2, b2, cleanupIterations) <- removeArtificial total (n + m) r1 b1 k1
    let retained = map (\row -> take (n + m) row ++ [row !! total]) r2
    (r3, b3, k3) <- simplexTable budget tolerance (c ++ replicate m 0) retained b2 cleanupIterations
    let point = [sum [row !! (n + m) | (row, j) <- zip r3 b3, j == i] | i <- [0 .. n - 1]]
    checkedPoint point
    Right (LPResult point (dot c point) b3 k3)
  where
    removeArtificial total cutoff rows basics pivots = case [(i, basic) | (i, basic) <- zip [0 :: Int ..] basics, basic >= cutoff] of
        [] -> Right (rows, basics, pivots)
        (index, _) : _ ->
            let row = rows !! index
                available = [j | j <- [0 .. cutoff - 1], abs (row !! j) > tolerance, j `notElem` basics]
             in case available of
                    [] ->
                        if abs (row !! total) <= tolerance
                            then
                                removeArtificial
                                    total
                                    cutoff
                                    [r | (i, r) <- zip [0 ..] rows, i /= index]
                                    [b' | (i, b') <- zip [0 ..] basics, i /= index]
                                    pivots
                            else Left (DomainError "infeasible artificial row")
                    col : _
                        | pivots >= budget -> Left (NonConvergence "simplex artificial cleanup pivot budget" pivots)
                        | otherwise ->
                            let normalized = scale (1 / (row !! col)) row
                                next =
                                    [if i == index then normalized else sub r (scale (r !! col) normalized) | (i, r) <- zip [0 ..] rows]
                                basis' = [if i == index then col else b' | (i, b') <- zip [0 ..] basics]
                             in removeArtificial total cutoff next basis' (pivots + 1)

simplexTable ::
    Int -> Double -> [Double] -> [[Double]] -> [Int] -> Int -> Either MathError ([[Double]], [Int], Int)
simplexTable budget tol costs = go
  where
    n = length costs
    go rows basis k
        | k > budget = Left (NonConvergence "simplex pivots" k)
        | otherwise =
            let reduced = [costs !! j - sum [costs !! bj * (row !! j) | (row, bj) <- zip rows basis] | j <- [0 .. n - 1]]
                entering = [j | (j, v) <- zip [0 ..] reduced, v < -tol, j `notElem` basis]
             in case entering of
                    [] -> Right (rows, basis, k)
                    col : _
                        | k >= budget -> Left (NonConvergence "simplex pivots" k)
                        | otherwise -> case sort
                            [ (max 0 (row !! n) / (row !! col), bj, i)
                            | (i, (row, bj)) <- zip [0 :: Int ..] (zip rows basis)
                            , row !! col > tol
                            ] of
                            [] -> Left (DomainError "unbounded linear program")
                            (_, _, leave) : _ ->
                                let normalized = scale (1 / ((rows !! leave) !! col)) (rows !! leave)
                                    next =
                                        [ if i == leave then normalized else sub row (scale (row !! col) normalized)
                                        | (i, row) <- zip [0 ..] rows
                                        ]
                                    bs = [if i == leave then col else bj | (i, bj) <- zip [0 ..] basis]
                                 in go next bs (k + 1)

{- | Revised primal simplex, A*x=b,x>=0. A basis must have m distinct columns
and B^-1*b >=0. B is solved afresh each pivot; no tableau is materialized.
-}
revisedSimplex ::
    Int -> Double -> [Double] -> [[Double]] -> [Double] -> [Int] -> Either MathError LPResult
revisedSimplex budget tol c a b initial = do
    checkedPoint (tol : c ++ concat a ++ b)
    let n = length c; m = length b
    if budget < 1
        || tol <= 0
        || length a /= m
        || any ((/= n) . length) a
        || length initial /= m
        || length (nub initial) /= m
        || any (\j -> j < 0 || j >= n) initial
        then Left (InvalidArgument "revised simplex shape/basis/budget")
        else go 0 initial
  where
    go k basis
        | k > budget = Left (NonConvergence "revised simplex" k)
        | otherwise = do
            let bm = [[row !! j | j <- basis] | row <- a]
            xb <- solveDense bm b
            if any (< -tol) xb then Left (DomainError "revised simplex basis is infeasible") else Right ()
            prices <- solveDense (transpose bm) [c !! j | j <- basis]
            let reduced = [(j, c !! j - dot prices [row !! j | row <- a]) | j <- [0 .. length c - 1], j `notElem` basis]
            case [j | (j, r) <- reduced, r < -tol] of
                [] ->
                    let x = [sum [max 0 v | (j, v) <- zip basis xb, j == i] | i <- [0 .. length c - 1]]
                     in Right (LPResult x (dot c x) basis k)
                entering : _
                    | k >= budget -> Left (NonConvergence "revised simplex" k)
                    | otherwise -> do
                        direction <- solveDense bm [row !! entering | row <- a]
                        case sort
                            [(max 0 x / d, bj, i) | (i, (x, d, bj)) <- zip [0 :: Int ..] (zip3 xb direction basis), d > tol] of
                            [] -> Left (DomainError "unbounded revised linear program")
                            (_, _, leaving) : _ -> go (k + 1) [if i == leaving then entering else j | (i, j) <- zip [0 ..] basis]

{- | Strictly convex QP: min .5*x'Hx+c'x, A*x<=b. Active-set enumeration
provides a correctness reference and a hard subset budget. H must be SPD.
-}
quadraticProgramming ::
    Int -> Double -> [[Double]] -> [Double] -> [[Double]] -> [Double] -> Either MathError OptimizeResult
quadraticProgramming budget tol h c a b = do
    let n = length c; m = length b
    checkedPoint (tol : c ++ concat h ++ concat a ++ b)
    if budget < 1
        || tol <= 0
        || length h /= n
        || any ((/= n) . length) h
        || length a /= m
        || any ((/= n) . length) a
        then Left (InvalidArgument "QP shapes/budget")
        else Right ()
    if any
        (\(i, j) -> abs ((h !! i) !! j - (h !! j) !! i) > tol)
        [(i, j) | i <- [0 .. n - 1], j <- [0 .. n - 1]]
        then Left (DomainError "QP Hessian must be symmetric")
        else Right ()
    _ <- spd h
    let sets = take (budget + 1) (filter ((<= n) . length) (subsets [0 .. m - 1]))
    if length sets > budget then Left (NonConvergence "QP active-set budget" budget) else Right ()
    candidates <- mapM solveActive sets
    case sort [(y, x, r) | (Just (y, x, r)) <- candidates] of
        [] -> Left (DomainError "infeasible convex quadratic program")
        (y, x, r) : _ -> Right (OptimizeResult x y r (length sets) (length sets) True)
  where
    subsets [] = [[]]
    subsets (x : xs) = let rest = subsets xs in rest ++ map (x :) rest
    spd [] = Right []
    spd rows = case rows of
        (pivot : rs) : others | pivot > 0 -> spd [[v - x * y / pivot | (v, y) <- zip row rs] | (x : row) <- others]
        _ -> Left (DomainError "QP requires positive definite Hessian")
    solveActive active = do
        let n = length c
            ac = [a !! i | i <- active]
            bc = [b !! i | i <- active]
            q = length active
            kkt = [row ++ [ar !! i | ar <- ac] | (i, row) <- zip [0 ..] h] ++ [row ++ replicate q 0 | row <- ac]
            rhs = map negate c ++ bc
        case solveDense kkt rhs of
            Left (SingularMatrix _) -> Right Nothing
            Left (NearSingularMatrix _) -> Right Nothing
            Left err -> Left err
            Right solution -> do
                let x = take n solution
                    multipliers = drop n solution
                    violation = maximum (0 : zipWith (\row bound -> dot row x - bound) a b)
                    dual =
                        sub
                            (map negate c)
                            (add (matVec h x) ([sum [l * (row !! i) | (l, row) <- zip multipliers ac] | i <- [0 .. n - 1]]))
                if violation <= tol && all (>= -tol) multipliers
                    then Right (Just (0.5 * dot x (matVec h x) + dot c x, x, max violation (norm dual)))
                    else Right Nothing

{- | Sequential least-squares QP with an analytic Hessian and exact linearized
equality/active inequality constraints. Merit backtracking globalizes steps.
-}
slsqp ::
    OptimizeOptions ->
    Objective ->
    Gradient ->
    Hessian ->
    [Constraint] ->
    [Double] ->
    Either MathError OptimizeResult
slsqp o f g hess constraints x0 = do checkedOptions o; loop 0 0 x0
  where
    baseCost = 3 + 2 * length constraints
    meritCost = 1 + 2 * length constraints
    loop k cost x = do
        checkBudget o (cost + baseCost)
        y <- checkedValue f x
        gs <- checkedGradient g x
        h <- hess x
        vals <- constraintValues constraints x
        let initial = [(eq, v, d) | (eq, v, d) <- vals, eq || v >= -sqrt (optTolerance o)]
            n = length x
        if length h /= n || any ((/= n) . length) h
            then Left (InvalidArgument "SQP Hessian shape")
            else checkedPoint (concat h)
        (active, solution) <- activeSolve h gs initial
        let a = [d | (_, _, d) <- active]
            p = take n solution
            lambda = drop n solution
            dual = norm (add gs [sum [l * (row !! i) | (l, row) <- zip lambda a] | i <- [0 .. n - 1]])
            violation = maximum (0 : [if eq then abs v else max 0 v | (eq, v, _) <- vals])
            used = cost + baseCost
        if dual <= optTolerance o && violation <= optTolerance o
            then Right (OptimizeResult x y (max dual violation) k used True)
            else
                if k >= optMaxIterations o
                    then Left (NonConvergence "SLSQP" k)
                    else do
                        let rho = 1 + maximum (0 : map abs lambda)
                            merit z = do
                                yz <- checkedValue f z
                                vs <- constraintValues constraints z
                                Right (yz + rho * sum [if eq then abs v else max 0 v | (eq, v, _) <- vs])
                        checkBudget o (used + meritCost)
                        current <- merit x
                        (next, count) <- backtrack (optMaxEvaluations o - used - meritCost) merit current p x 0 1
                        loop (k + 1) (used + meritCost + count) next
    activeSolve h gs active = do
        let n = length gs
            q = length active
            a = [d | (_, _, d) <- active]
            kkt = [row ++ [ar !! i | ar <- a] | (i, row) <- zip [0 ..] h] ++ [row ++ replicate q 0 | row <- a]
        solution <- solveDense kkt (map negate gs ++ [-v | (_, v, _) <- active])
        case [ i
             | (i, ((eq, _, _), lambda)) <- zip [0 :: Int ..] (zip active (drop n solution))
             , not eq
             , lambda < -optTolerance o
             ] of
            [] -> Right (active, solution)
            index : _ -> activeSolve h gs [a' | (i, a') <- zip [0 ..] active, i /= index]
    backtrack remaining merit current p x count rate
        | count + meritCost > remaining = Left (NonConvergence "SQP merit evaluation budget" count)
        | count >= 50 * meritCost = Left (NonConvergence "SQP merit line search" count)
        | otherwise = do
            let next = add x (scale rate p)
            value <- merit next
            if value < current
                then Right (next, count + meritCost)
                else backtrack remaining merit current p x (count + meritCost) (rate / 2)

{- | Derivative-free constrained linear-approximation trust region. This bounded
CPU variant uses an L-infinity trust box and axis interpolation simplex.
It solves each linear model as an LP, rather than relabeling a penalty solver.
-}
cobyla ::
    Double -> OptimizeOptions -> Objective -> [Objective] -> [Double] -> Either MathError OptimizeResult
cobyla initialRadius o f constraints x0 = do
    checkedOptions o
    checkedPoint [initialRadius]
    if initialRadius <= 0 || null x0
        then Left (InvalidArgument "COBYLA trust radius/dimension")
        else loop 0 0 initialRadius x0
  where
    loop k cost radius x = do
        let n = length x; funcs = f : constraints; calls = (n + 2) * length funcs
        checkBudget o (cost + calls + length funcs)
        values <- mapM (`checkedValue` x) funcs
        model <-
            mapM
                ( \fn -> do
                    base <- checkedValue fn x
                    mapM
                        ( \i -> do
                            y <- checkedValue fn (add x [if j == i then radius else 0 | j <- [0 .. n - 1]])
                            Right ((y - base) / radius)
                        )
                        [0 .. n - 1]
                )
                funcs
        let c = model !! 0
            rows = drop 1 model
            rhs = zipWith (\v row -> -v + radius * sum row) (drop 1 values) rows
            bounds = identity n
            aa = rows ++ bounds
            bb = rhs ++ replicate n (2 * radius)
        step <- case linearProgramming (max 100 (optMaxIterations o)) (optTolerance o / 100) c aa bb of
            Right lp -> Right (sub (lpPoint lp) (replicate n radius))
            Left (DomainError _) -> Right (replicate n 0)
            Left e -> Left e
        nextVals <- mapM (\fn -> checkedValue fn (add x step)) funcs
        let merit vs = vs !! 0 + 1000 * sum (map (max 0) (drop 1 vs))
            improve = merit nextVals < merit values
            next = if improve then add x step else x
            violation = maximum (0 : map (max 0) (drop 1 (if improve then nextVals else values)))
        if radius <= optTolerance o && violation <= optTolerance o
            then
                Right
                    ( OptimizeResult
                        next
                        (if improve then nextVals !! 0 else values !! 0)
                        (max radius violation)
                        k
                        (cost + calls + length funcs)
                        True
                    )
            else
                if k >= optMaxIterations o
                    then Left (NonConvergence "COBYLA" k)
                    else
                        loop
                            (k + 1)
                            (cost + calls + length funcs)
                            (if improve && norm step > radius / 2 then radius else radius / 2)
                            next

-- | Compose nonnegative scalarization weights and checked objective values; at least one weight must be positive.
weightedObjective :: [Double] -> [Objective] -> Objective
weightedObjective weights objectives x = do
    checkedPoint weights
    if length weights /= length objectives || null weights || any (< 0) weights || sum weights <= 0
        then Left (InvalidArgument "multiobjective weights")
        else Right ()
    vals <- mapM (`checkedValue` x) objectives
    Right (dot weights vals)

-- | Return original indices of nondominated objective rows under componentwise minimization; duplicates remain nondominated.
paretoFront :: [[Double]] -> Either MathError [Int]
paretoFront points = do
    checkedPoint (concat points)
    case points of
        [] -> Right []
        first : rest ->
            if any ((/= length first) . length) rest
                then Left (InvalidArgument "Pareto objective shape")
                else Right [i | (i, x) <- zip [0 ..] points, not (any (dominates x) points)]
  where
    dominates x y = and (zipWith (<=) y x) && or (zipWith (<) y x)
