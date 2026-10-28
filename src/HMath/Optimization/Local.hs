-- SPDX-License-Identifier: MPL-2.0

{- | Bounded CPU reference local solvers. Dense quasi-Newton updates implement
their named secant formulas; L-BFGS uses a separate two-loop recursion.
Scalar Brent combines safeguarded parabolic interpolation and golden steps.
Newton-CG uses Hessian products and detects nonpositive curvature.
-}
module HMath.Optimization.Local (
    ScalarMethod (..),
    minimizeScalar,
    QuasiNewton (..),
    minimizeQuasiNewton,
    NewtonMethod (..),
    minimizeNewton,
    nonlinearCG,
    ResidualFunction,
    JacobianFunction,
    LeastSquaresLoss (..),
    leastSquares,
    nelderMead,
    powell,
) where

import Control.Monad (foldM)
import Data.List (sortOn)
import HMath.Error
import HMath.Optimization.Common

data ScalarMethod = GoldenSection | TernarySearch | BrentSearch deriving (Eq, Show)

-- | Minimize on a finite bracket a<b. Result residual is interval width, not an unconstrained derivative.
minimizeScalar ::
    ScalarMethod ->
    OptimizeOptions ->
    (Double -> Either MathError Double) ->
    Double ->
    Double ->
    Either MathError OptimizeResult
minimizeScalar method o f a0 b0 = do
    checkedOptions o
    checkedPoint [a0, b0]
    if a0 >= b0 then Left (InvalidArgument "scalar minimization requires a < b") else Right ()
    case method of
        GoldenSection -> do
            checkBudget o 2
            let c = b0 - ratio * (b0 - a0); d = a0 + ratio * (b0 - a0)
            fc <- eval c
            fd <- eval d
            golden 0 2 a0 b0 c d fc fd
        TernarySearch -> ternary 0 0 a0 b0
        BrentSearch -> do
            let x = a0 + (1 - ratio) * (b0 - a0)
            y <- eval x
            brent 0 1 a0 b0 x x x y y y 0 0
  where
    ratio = (sqrt 5 - 1) / 2
    eval x = do checkedPoint [x]; y <- f x; checkedPoint [y]; Right y
    done k n a b x y = Right (OptimizeResult [x] y (b - a) k n True)
    golden k n a b c d fc fd
        | b - a <= optTolerance o * (1 + abs ((a + b) / 2)) =
            if fc < fd then done k n a b c fc else done k n a b d fd
        | k >= optMaxIterations o = Left (NonConvergence "golden section" k)
        | otherwise = do
            checkBudget o (n + 1)
            if fc < fd
                then do
                    let z = d - ratio * (d - a)
                    fz <- eval z
                    golden (k + 1) (n + 1) a d z c fz fc
                else do
                    let z = c + ratio * (b - c)
                    fz <- eval z
                    golden (k + 1) (n + 1) c b d z fd fz
    ternary k n a b
        | b - a <= optTolerance o * (1 + abs ((a + b) / 2)) = do checkBudget o (n + 1); y <- eval ((a + b) / 2); done k (n + 1) a b ((a + b) / 2) y
        | k >= optMaxIterations o = Left (NonConvergence "ternary search" k)
        | otherwise = do
            checkBudget o (n + 2)
            let c = a + (b - a) / 3; d = b - (b - a) / 3
            fc <- eval c
            fd <- eval d
            if fc < fd then ternary (k + 1) (n + 2) a d else ternary (k + 1) (n + 2) c b
    brent k n a b x w v fx fw fv step old
        | b - a <= optTolerance o * (1 + abs x) = done k n a b x fx
        | k >= optMaxIterations o = Left (NonConvergence "Brent minimum" k)
        | otherwise = do
            checkBudget o (n + 1)
            let mid = (a + b) / 2
                tol = optTolerance o * (1 + abs x) / 4
                r = (x - w) * (fx - fv)
                q0 = (x - v) * (fx - fw)
                p0 = (x - v) * q0 - (x - w) * r
                q1 = 2 * (q0 - r)
                p = if q1 > 0 then -p0 else p0
                q = abs q1
                parabolic = abs old > tol && q /= 0 && abs p < abs (q * old / 2) && p > q * (a - x) && p < q * (b - x)
                movement = if parabolic then p / q else (1 - ratio) * (if x < mid then b - x else a - x)
                newOld = if parabolic then step else if x < mid then b - x else a - x
                d = if abs movement >= tol then movement else if movement >= 0 then tol else -tol
                u = x + d
            fu <- eval u
            let (a', b') = if fu <= fx then if u < x then (a, x) else (x, b) else if u < x then (u, b) else (a, u)
            if fu <= fx
                then brent (k + 1) (n + 1) a' b' u x w fu fx fw d newOld
                else
                    if fu <= fw || w == x
                        then brent (k + 1) (n + 1) a' b' x u v fx fu fv d newOld
                        else
                            if fu <= fv || v == x || v == w
                                then brent (k + 1) (n + 1) a' b' x w u fx fw fu d newOld
                                else brent (k + 1) (n + 1) a' b' x w v fx fw fv d newOld

data QuasiNewton = BFGS | LBFGS Int | DFP | SR1 deriving (Eq, Show)

-- | Run the named inverse-Hessian secant update with safeguarded curvature and a strong-Wolfe descent search.
minimizeQuasiNewton ::
    QuasiNewton ->
    OptimizeOptions ->
    Objective ->
    Gradient ->
    [Double] ->
    Either MathError OptimizeResult
minimizeQuasiNewton method o f g x0 = do
    checkedOptions o
    case method of
        LBFGS m | m < 1 -> Left (InvalidArgument "positive L-BFGS memory required")
        _ -> Right ()
    checkBudget o 2
    y <- checkedValue f x0
    gs <- checkedGradient g x0
    loop 0 2 x0 y gs (identity (length x0)) []
  where
    loop k n x y gs h hist
        | norm gs <= optTolerance o = Right (OptimizeResult x y (norm gs) k n True)
        | k >= optMaxIterations o = Left (NonConvergence (show method) k)
        | otherwise = do
            let direction0 = case method of LBFGS _ -> scale (-1) (twoLoop hist gs); _ -> scale (-1) (matVec h gs)
                direction = if dot direction0 gs < 0 then direction0 else scale (-1) gs
            (alpha, yn, gn, cost) <-
                lineSearch StrongWolfe (min 80 (optMaxEvaluations o - n)) f g x direction y gs
            checkBudget o (n + cost)
            let xn = add x (scale alpha direction)
                s = sub xn x
                z = sub gn gs
                sz = dot s z
                hz = matVec h z
                zhz = dot z hz
                r = sub s hz
                update a b = zipWith (zipWith (+)) a b
                minus a b = zipWith (zipWith (-)) a b
                h' = case method of
                    BFGS
                        | sz > 1e-14 * norm s * norm z ->
                            let v = minus (identity (length x)) (map (scale (1 / sz)) (outer s z))
                             in update (matMul (matMul v h) (transpose v)) (map (scale (1 / sz)) (outer s s))
                    DFP
                        | sz > 1e-14 * norm s * norm z && zhz > 0 ->
                            update (minus h (map (scale (1 / zhz)) (outer hz hz))) (map (scale (1 / sz)) (outer s s))
                    SR1 | abs (dot r z) > 1e-8 * norm r * norm z -> update h (map (scale (1 / dot r z)) (outer r r))
                    _ -> h
                hist' = case method of LBFGS m | sz > 1e-14 * norm s * norm z -> take m ((s, z, 1 / sz) : hist); _ -> hist
            loop (k + 1) (n + cost) xn yn gn h' hist'
    twoLoop [] gs = gs
    twoLoop hs@((s0, y0, _) : _) gs =
        let (q, alphas) =
                foldl' (\(v, as) (s, y, rho) -> let a = rho * dot s v in (sub v (scale a y), as ++ [a])) (gs, []) hs
            gamma = dot s0 y0 / dot y0 y0
         in foldl'
                (\v ((s, y, rho), a) -> add v (scale (a - rho * dot y v) s))
                (scale gamma q)
                (reverse (zip hs alphas))

data NewtonMethod = Newton | NewtonCG | TrustRegion Double | Dogleg Double deriving (Eq, Show)

-- | Use an analytic square Hessian with Newton/CG or trust-region acceptance; singular systems and collapsed regions fail.
minimizeNewton ::
    NewtonMethod ->
    OptimizeOptions ->
    Objective ->
    Gradient ->
    Hessian ->
    [Double] ->
    Either MathError OptimizeResult
minimizeNewton method o f g hess x0 = do
    checkedOptions o
    case method of { TrustRegion r -> positive r; Dogleg r -> positive r; _ -> Right () }
    loop 0 0 (case method of TrustRegion r -> r; Dogleg r -> r; _ -> 1) x0
  where
    positive r = do
        checkedPoint [r]
        if r <= 0 then Left (InvalidArgument "positive trust radius required") else Right ()
    loop k n radius x = do
        checkBudget o (n + 3)
        y <- checkedValue f x
        gs <- checkedGradient g x
        if norm gs <= optTolerance o
            then Right (OptimizeResult x y (norm gs) k (n + 2) True)
            else
                if k >= optMaxIterations o
                    then Left (NonConvergence (show method) k)
                    else do
                        h <- hess x
                        let dim = length x
                        if length h /= dim || any ((/= dim) . length) h
                            then Left (InvalidArgument "Hessian shape")
                            else checkedPoint (concat h)
                        let cauchy = let hg = matVec h gs; d = dot gs hg in scale (if d <= 0 then -1 else -dot gs gs / d) gs
                            cg = truncatedCG h gs (max 1e-12 (optTolerance o)) dim
                        raw <- case method of NewtonCG -> Right cg; TrustRegion _ -> Right cg; _ -> solveDense h (scale (-1) gs)
                        let descending = if dot raw gs < 0 then raw else scale (-1) gs
                            p = case method of
                                TrustRegion _ -> cap radius descending
                                Dogleg _ -> dogleg radius cauchy descending
                                _ -> descending
                        case method of
                            TrustRegion _ -> accept k (n + 3) radius x y gs h p
                            Dogleg _ -> accept k (n + 3) radius x y gs h p
                            _ -> do
                                (a, _, _, cost) <- lineSearch Armijo (min 80 (optMaxEvaluations o - n - 3)) f g x p y gs
                                loop (k + 1) (n + 3 + cost) radius (add x (scale a p))
    accept k n radius x y gs h p = do
        checkBudget o (n + 1)
        yn <- checkedValue f (add x p)
        let predicted = -dot gs p - 0.5 * dot p (matVec h p)
            rho = if predicted <= 0 then -1 else (y - yn) / predicted
            radius' =
                if rho < 0.25
                    then radius / 4
                    else if rho > 0.75 && norm p > 0.9 * radius then min 1e6 (2 * radius) else radius
        if radius' < 1e-16
            then Left (NonConvergence "trust region collapsed" k)
            else loop (k + 1) (n + 1) radius' (if rho > 0.1 then add x p else x)
    cap r p = if norm p > r then scale (r / norm p) p else p
    dogleg r pu pb
        | norm pb <= r = pb
        | norm pu >= r = cap r pu
        | otherwise =
            let d = sub pb pu
                a = dot d d
                b = 2 * dot pu d
                c = dot pu pu - r * r
                t = (-b + sqrt (b * b - 4 * a * c)) / (2 * a)
             in add pu (scale t d)

truncatedCG :: [[Double]] -> [Double] -> Double -> Int -> [Double]
truncatedCG h g tol limit = go 0 (replicate (length g) 0) (scale (-1) g) (scale (-1) g)
  where
    go k x r p
        | k >= limit || norm r <= tol = x
        | curvature <= 0 = if k == 0 then scale (-1) g else x
        | otherwise =
            let alpha = dot r r / curvature
                x' = add x (scale alpha p)
                r' = sub r (scale alpha hp)
                beta = dot r' r' / dot r r
             in go (k + 1) x' r' (add r' (scale beta p))
      where
        hp = matVec h p; curvature = dot p hp

-- | Polak–Ribiere+ nonlinear CG with descent restart and strong Wolfe search.
nonlinearCG ::
    OptimizeOptions -> Objective -> Gradient -> [Double] -> Either MathError OptimizeResult
nonlinearCG o f g x0 = do
    checkedOptions o
    checkBudget o 2
    y <- checkedValue f x0
    gs <- checkedGradient g x0
    loop 0 2 x0 y gs (scale (-1) gs)
  where
    loop k n x y gs p
        | norm gs <= optTolerance o = Right (OptimizeResult x y (norm gs) k n True)
        | k >= optMaxIterations o = Left (NonConvergence "nonlinear CG" k)
        | otherwise = do
            let d = if dot p gs < 0 then p else scale (-1) gs
            (a, yn, gn, cost) <- lineSearch StrongWolfe (min 80 (optMaxEvaluations o - n)) f g x d y gs
            let beta = max 0 (dot gn (sub gn gs) / dot gs gs)
            loop (k + 1) (n + cost) (add x (scale a d)) yn gn (add (scale (-1) gn) (scale beta d))

type ResidualFunction = [Double] -> Either MathError [Double]
type JacobianFunction = [Double] -> Either MathError [[Double]]
data LeastSquaresLoss = SquaredLoss | HuberLoss Double | CauchyLoss Double | SoftL1 Double
    deriving (Eq, Show)

{- | lambda=0 selects Gauss–Newton, positive lambda selects LM. Robust losses
use iteratively reweighted least squares with the actual robust objective.
-}
leastSquares ::
    LeastSquaresLoss ->
    Double ->
    OptimizeOptions ->
    ResidualFunction ->
    JacobianFunction ->
    [Double] ->
    Either MathError OptimizeResult
leastSquares loss lambda0 o residual jac x0 = do
    checkedOptions o
    checkedPoint [lambda0]
    if lambda0 < 0 then Left (InvalidArgument "negative LM damping") else Right ()
    case loss of
        SquaredLoss -> Right ()
        HuberLoss c -> positive c
        CauchyLoss c -> positive c
        SoftL1 c -> positive c
    loop 0 0 lambda0 x0
  where
    positive c = do checkedPoint [c]; if c <= 0 then Left (InvalidArgument "robust loss scale") else Right ()
    rho r = case loss of
        SquaredLoss -> r * r / 2
        HuberLoss c -> if abs r <= c then r * r / 2 else c * (abs r - c / 2)
        CauchyLoss c -> c * c / 2 * log (1 + (r / c) ^ (2 :: Int))
        SoftL1 c -> c * c * (sqrt (1 + (r / c) ^ (2 :: Int)) - 1)
    weight r = case loss of
        SquaredLoss -> 1
        HuberLoss c -> if abs r <= c then 1 else c / abs r
        CauchyLoss c -> 1 / (1 + (r / c) ^ (2 :: Int))
        SoftL1 c -> 1 / sqrt (1 + (r / c) ^ (2 :: Int))
    loop k n lambda x = do
        checkedPoint x
        checkBudget o (n + 2)
        rs <- residual x
        checkedPoint rs
        j <- jac x
        if length j /= length rs || any ((/= length x) . length) j
            then Left (InvalidArgument "least squares Jacobian shape")
            else checkedPoint (concat j)
        let ws = map weight rs
            wj = zipWith scale ws j
            jt = transpose j
            grad = matVec jt (zipWith (*) ws rs)
            normal = matMul jt wj
            damped = zipWith (zipWith (+)) normal (map (scale lambda) (identity (length x)))
            y = sum (map rho rs)
        checkedPoint (y : norm grad : ws ++ grad ++ concat normal ++ concat damped)
        if norm grad <= optTolerance o
            then Right (OptimizeResult x y (norm grad) k (n + 2) True)
            else
                if k >= optMaxIterations o
                    then Left (NonConvergence "least squares" k)
                    else do
                        step <- solveDense damped (scale (-1) grad)
                        checkBudget o (n + 3)
                        checkedPoint (add x step)
                        rn <- residual (add x step)
                        checkedPoint rn
                        if length rn /= length rs then Left (InvalidArgument "residual length changed") else Right ()
                        let yn = sum (map rho rn)
                        checkedPoint [yn]
                        if yn < y
                            then loop (k + 1) (n + 3) (if lambda0 == 0 then 0 else max 1e-15 (lambda / 3)) (add x step)
                            else
                                if lambda0 == 0
                                    then Left (NonConvergence "Gauss Newton step failed to decrease objective" k)
                                    else loop (k + 1) (n + 3) (min 1e20 (lambda * 10)) x

-- | Optimize an axis-initialized simplex with reflection, expansion, contraction, and shrink steps; report simplex spread.
nelderMead :: OptimizeOptions -> Objective -> [Double] -> Either MathError OptimizeResult
nelderMead o f x0 = do
    checkedOptions o
    if null x0 then Left (InvalidArgument "empty simplex") else Right ()
    let points =
            x0
                : [ add x0 [if i == j then optLearningRate o else 0 | j <- [0 .. length x0 - 1]]
                  | i <- [0 .. length x0 - 1]
                  ]
    checkBudget o (length points)
    simplex <- mapM (\x -> do y <- checkedValue f x; Right (x, y)) points
    loop 0 (length simplex) simplex
  where
    loop k n simplex = do
        let sorted = sortOn snd simplex
            (best, fb) = sorted !! 0
            (worst, fw) = sorted !! length x0
            second = snd (sorted !! (length x0 - 1))
            rest = take (length x0) sorted
            centroid = scale (1 / fromIntegral (length x0)) (foldl' add (replicate (length x0) 0) (map fst rest))
            spread = maximum (map (\(x, y) -> max (norm (sub x best)) (abs (y - fb))) sorted)
        if spread <= optTolerance o
            then Right (OptimizeResult best fb spread k n True)
            else
                if k >= optMaxIterations o
                    then Left (NonConvergence "Nelder Mead" k)
                    else do
                        checkBudget o (n + 2 + length x0)
                        let reflected = add centroid (sub centroid worst)
                        fr <- checkedValue f reflected
                        if fr < fb
                            then do
                                let expanded = add centroid (scale 2 (sub reflected centroid))
                                fe <- checkedValue f expanded
                                loop (k + 1) (n + 2) (rest ++ [if fe < fr then (expanded, fe) else (reflected, fr)])
                            else
                                if fr < second
                                    then loop (k + 1) (n + 1) (rest ++ [(reflected, fr)])
                                    else do
                                        let contracted =
                                                if fr < fw
                                                    then add centroid (scale 0.5 (sub reflected centroid))
                                                    else add centroid (scale 0.5 (sub worst centroid))
                                        fc <- checkedValue f contracted
                                        if fc < min fr fw
                                            then loop (k + 1) (n + 2) (rest ++ [(contracted, fc)])
                                            else do
                                                shrunk <-
                                                    mapM
                                                        (\(x, _) -> let y = add best (scale 0.5 (sub x best)) in do fy <- checkedValue f y; Right (y, fy))
                                                        (drop 1 sorted)
                                                loop (k + 1) (n + 2 + length shrunk) ((best, fb) : shrunk)

{- | Powell direction-set method with bounded line minimization on [-radius,radius].
Each outer iteration replaces the direction with greatest decrease by its
net displacement, provided that displacement improves the objective.
-}
powell :: Double -> OptimizeOptions -> Objective -> [Double] -> Either MathError OptimizeResult
powell radius o f x0 = do
    checkedOptions o
    checkedPoint [radius]
    if radius <= 0 || null x0
        then Left (InvalidArgument "Powell radius or dimension")
        else loop 0 0 x0 (identity (length x0))
  where
    loop k n x directions = do
        checkBudget o (n + 1)
        y <- checkedValue f x
        (xn, yn, cost, changes) <-
            foldM
                ( \(z, old, count, cs) d -> do
                    let local = o{optMaxEvaluations = optMaxEvaluations o - count}
                    r <- minimizeScalar BrentSearch local (\a -> checkedValue f (add z (scale a d))) (-radius) radius
                    Right
                        (add z (scale (optPoint r !! 0) d), optValue r, count + optEvaluations r, cs ++ [old - optValue r])
                )
                (x, y, n + 1, [])
                directions
        let displacement = sub xn x
        if norm displacement <= optTolerance o * (1 + norm x) && abs (y - yn) <= optTolerance o
            then Right (OptimizeResult xn yn (norm displacement) k cost True)
            else
                if k >= optMaxIterations o
                    then Left (NonConvergence "Powell" k)
                    else do
                        let index = fst (maximum [(c, i) | (i, c) <- zip [0 :: Int ..] changes])
                            -- Index is selected below from (decrease,index) to avoid a
                            -- numeric conversion between objective and coordinate types.
                            chosen = snd (maximum [(c, i) | (i, c) <- zip [0 :: Int ..] changes])
                            dirs =
                                if index > 0 && norm displacement > 0
                                    then
                                        [ if i == chosen then scale (1 / norm displacement) displacement else d
                                        | (i, d) <- zip [0 ..] directions
                                        ]
                                    else directions
                        loop (k + 1) cost xn dirs
