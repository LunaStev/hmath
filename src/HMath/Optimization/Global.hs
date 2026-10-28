-- SPDX-License-Identifier: MPL-2.0

{- | Seeded bounded CPU global search. Bounds are finite inclusive boxes.
Global optimality cannot be certified by these stochastic algorithms: the
result's convergence flag denotes population/step collapse only. Exhausted
generations return the best point with optConverged=False. Random state is
explicit and deterministic; no system entropy or global generator is used.
-}
module HMath.Optimization.Global (GlobalMethod (..), globalMinimize, basinHopping) where

import Control.Monad (foldM)
import Data.Complex (realPart)
import qualified Data.Foldable as Foldable (foldl')
import Data.List (sortOn)
import Data.Word (Word64)
import HMath.Error
import qualified HMath.Matrix as M
import qualified HMath.Matrix.LAPACK as LA
import HMath.Optimization.Common
import HMath.Optimization.Local (nelderMead)
import HMath.Random (Generator (PCG32), RNG, normal, sampleN, seedRNG, uniform)

data GlobalMethod
    = SimulatedAnnealing
    | DifferentialEvolution
    | GeneticAlgorithm
    | ParticleSwarm
    | CMAES
    deriving (Eq, Show)
validateBounds :: [(Double, Double)] -> Either MathError ()
validateBounds bounds = do
    checkedPoint (concatMap (\(lo, hi) -> [lo, hi, hi - lo]) bounds)
    if null bounds || any (uncurry (>=)) bounds
        then Left (InvalidArgument "global search requires finite nonempty lower < upper bounds")
        else Right ()
clip :: [(Double, Double)] -> [Double] -> [Double]
clip bounds = zipWith (\(lo, hi) x -> max lo (min hi x)) bounds
uniformPoint :: [(Double, Double)] -> RNG -> ([Double], RNG)
uniformPoint bounds rng =
    Foldable.foldl'
        (\(xs, s) (lo, hi) -> let (u, t) = uniform s in (xs ++ [lo + (hi - lo) * u], t))
        ([], rng)
        bounds
normals :: Int -> RNG -> Either MathError ([Double], RNG)
normals n = sampleN n (normal 0 1)
population :: Int -> [(Double, Double)] -> RNG -> ([[Double]], RNG)
population n bounds rng =
    Foldable.foldl'
        (\(xs, s) _ -> let (x, t) = uniformPoint bounds s in (xs ++ [x], t))
        ([], rng)
        [1 .. n]
score :: Objective -> [[Double]] -> Either MathError [([Double], Double)]
score f = mapM (\x -> do y <- checkedValue f x; Right (x, y))
bestResult :: Int -> Int -> Bool -> [([Double], Double)] -> OptimizeResult
bestResult k cost converged pop =
    let (x, y) = sortOn snd pop !! 0
        spread = maximum (0 : [maximum (0 : map abs (sub z x)) | (z, _) <- pop])
     in OptimizeResult x y spread k cost converged

-- | Run a reproducible seeded stochastic algorithm in a finite box. size>=4; budget exhaustion returns the best finite incumbent with convergence=False.
globalMinimize ::
    GlobalMethod ->
    Int ->
    Word64 ->
    OptimizeOptions ->
    [(Double, Double)] ->
    Objective ->
    Either MathError OptimizeResult
globalMinimize method size seed o bounds f = do
    checkedOptions o
    validateBounds bounds
    if size < 4
        then Left (InvalidArgument "global population must contain at least 4 points")
        else Right ()
    let rng = seedRNG PCG32 seed
    case method of
        SimulatedAnnealing -> do
            let (x, s) = uniformPoint bounds rng
            checkBudget o 1
            y <- checkedValue f x
            anneal 0 1 s x y (x, y)
        CMAES ->
            let center = map (\(a, b) -> (a + b) / 2) bounds; sigma = minimum (map (\(a, b) -> (b - a) / 4) bounds)
             in cma 0 0 rng center sigma (identity dim) (replicate dim 0) (replicate dim 0) Nothing
        _ -> do
            checkBudget o size
            let (xs, s) = population size bounds rng
            pop <- score f xs
            case method of
                DifferentialEvolution -> de 0 size s pop
                GeneticAlgorithm -> ga 0 size s pop
                ParticleSwarm -> pso 0 size s pop (replicate size (replicate dim 0)) pop
  where
    dim = length bounds
    width = map (uncurry (flip (-))) bounds
    spread pop = let (best, _) = sortOn snd pop !! 0 in maximum (0 : map (norm . (`sub` best) . fst) pop)
    finished k cost pop = k >= optMaxIterations o || cost + size > optMaxEvaluations o || spread pop <= optTolerance o
    anneal k cost rng x y best
        | k >= optMaxIterations o || cost + 1 > optMaxEvaluations o =
            Right
                ( (bestResult k cost False [best])
                    { optGradientNorm = 0.1 * sqrt (max 1e-12 (0.95 ^ k)) * maximum width
                    }
                )
        | otherwise = do
            (zs, s) <- normals dim rng
            let temperature = max 1e-12 (0.95 ^ k)
                trial = clip bounds (add x (zipWith (\w z -> 0.1 * sqrt temperature * w * z) width zs))
                (u, t) = uniform s
            yn <- checkedValue f trial
            let accepted = yn < y || log (max 1e-300 u) < (y - yn) / temperature
                best' = if yn < snd best then (trial, yn) else best
            anneal (k + 1) (cost + 1) t (if accepted then trial else x) (if accepted then yn else y) best'
    de k cost rng pop
        | finished k cost pop = Right (bestResult k cost (spread pop <= optTolerance o) pop)
        | otherwise = do
            (trials, s) <-
                foldM
                    ( \(acc, state) (i, (x, _)) -> do
                        let others = [j | j <- [0 .. size - 1], j /= i]
                            (u1, s1) = uniform state
                            p1 = min (length others - 1) (floor (u1 * fromIntegral (length others)))
                            a = others !! p1
                            rest = filter (/= a) others
                            (u2, s2) = uniform s1
                            b = rest !! min (length rest - 1) (floor (u2 * fromIntegral (length rest)))
                            rest2 = filter (/= b) rest
                            (u3, s3) = uniform s2
                            c = rest2 !! min (length rest2 - 1) (floor (u3 * fromIntegral (length rest2)))
                            mutant = add (fst (pop !! a)) (scale 0.8 (sub (fst (pop !! b)) (fst (pop !! c))))
                            (forcedU, s4) = uniform s3
                            forced = min (dim - 1) (floor (forcedU * fromIntegral dim))
                            (crossed, s5) =
                                Foldable.foldl'
                                    ( \(vs, st) (j, (orig, new)) -> let (u, t) = uniform st in (vs ++ [if j == forced || u < 0.9 then new else orig], t)
                                    )
                                    ([], s4)
                                    (zip [0 ..] (zip x mutant))
                        Right (acc ++ [clip bounds crossed], s5)
                    )
                    ([], rng)
                    (zip [0 ..] pop)
            scored <- score f trials
            de (k + 1) (cost + size) s (zipWith (\old new -> if snd new < snd old then new else old) pop scored)
    ga k cost rng pop
        | finished k cost pop = Right (bestResult k cost (spread pop <= optTolerance o) pop)
        | otherwise = do
            let sorted = sortOn snd pop; elite = sorted !! 0; pool = take (max 2 (size `div` 2)) sorted
            (children, s) <-
                foldM
                    ( \(acc, state) _ -> do
                        let (ua, s1) = uniform state
                            (ub, s2) = uniform s1
                            a = fst (pool !! min (length pool - 1) (floor (ua * fromIntegral (length pool))))
                            b = fst (pool !! min (length pool - 1) (floor (ub * fromIntegral (length pool))))
                            (alpha, s3) = uniform s2
                        (zs, s4) <- normals dim s3
                        let child =
                                clip
                                    bounds
                                    (zipWith3 (\w z base -> base + 0.05 * w * z) width zs (add (scale alpha a) (scale (1 - alpha) b)))
                        Right (acc ++ [child], s4)
                    )
                    ([], rng)
                    [1 .. size - 1]
            ys <- score f children
            ga (k + 1) (cost + size - 1) s (elite : ys)
    pso k cost rng pop velocities personal
        | finished k cost pop = Right (bestResult k cost (spread pop <= optTolerance o) personal)
        | otherwise = do
            let global = fst (sortOn snd personal !! 0)
                (pairs, s) =
                    Foldable.foldl'
                        ( \(acc, state) ((x, _), (vel, (best, _))) ->
                            let (u, s1) = uniform state
                                (v, s2) = uniform s1
                                velocity =
                                    add (scale 0.729 vel) (add (scale (1.49445 * u) (sub best x)) (scale (1.49445 * v) (sub global x)))
                             in (acc ++ [(clip bounds (add x velocity), velocity)], s2)
                        )
                        ([], rng)
                        (zip pop (zip velocities personal))
            ys <- score f (map fst pairs)
            let pb = zipWith (\old new -> if snd new < snd old then new else old) personal ys
            pso (k + 1) (cost + size) s ys (map snd pairs) pb
    -- Rank-mu + rank-one covariance adaptation with cumulative step-size
    -- control and h-sigma gating, following Hansen, arXiv:1604.00772.
    -- Symmetric inverse square roots make the cumulated ps path independent
    -- of the orientation chosen by the eigensolver.
    cma k cost rng mean sigma covariance path pathSigma best
        | k >= optMaxIterations o || cost + size > optMaxEvaluations o = case best of
            Nothing -> Left (NonConvergence "CMA-ES budget" k)
            Just b ->
                Right
                    ( (bestResult k cost False [b])
                        { optGradientNorm = sigma * sqrt (maximum (0 : [row !! i | (i, row) <- zip [0 ..] covariance]))
                        }
                    )
        | sigma * sqrt (maximum (0 : [row !! i | (i, row) <- zip [0 ..] covariance])) <= optTolerance o = case best of
            Nothing -> Left (NonConvergence "CMA-ES initial collapse" k)
            Just b ->
                Right
                    ( (bestResult k cost True [b])
                        { optGradientNorm = sigma * sqrt (maximum (0 : [row !! i | (i, row) <- zip [0 ..] covariance]))
                        }
                    )
        | otherwise = do
            (l, inverseRoot) <- covarianceRoots covariance
            (xs, s) <-
                foldM
                    ( \(acc, state) _ -> do
                        (z, t) <- normals dim state; Right (acc ++ [clip bounds (add mean (scale sigma (matVec l z)))], t)
                    )
                    ([], rng)
                    [1 .. size]
            scored <- score f xs
            let selected = take (size `div` 2) (sortOn snd scored)
                mu = length selected
                rawWeights = [log (fromIntegral mu + 0.5) - log (fromIntegral i) | i <- [1 .. mu]]
                weights = scale (1 / sum rawWeights) rawWeights
                muEff = 1 / dot weights weights
                mean' = Foldable.foldl' add (replicate dim 0) (zipWith (\w (x, _) -> scale w x) weights selected)
                y = scale (1 / sigma) (sub mean' mean)
                dimension = fromIntegral dim
                cc = (4 + muEff / dimension) / (dimension + 4 + 2 * muEff / dimension)
                cs = (muEff + 2) / (dimension + muEff + 5)
                damping = 1 + 2 * max 0 (sqrt ((muEff - 1) / (dimension + 1)) - 1) + cs
                chi = sqrt dimension * (1 - 1 / (4 * dimension) + 1 / (21 * dimension ^ (2 :: Int)))
                pathSigma' = add (scale (1 - cs) pathSigma) (scale (sqrt (cs * (2 - cs) * muEff)) (matVec inverseRoot y))
                hSigma = norm pathSigma' / sqrt (1 - (1 - cs) ^ (2 * (k + 1))) / chi < 1.4 + 2 / (dimension + 1)
                path' = add (scale (1 - cc) path) (scale (if hSigma then sqrt (cc * (2 - cc) * muEff) else 0) y)
                c1 = 2 / ((fromIntegral dim + 1.3) ^ (2 :: Int) + muEff)
                cmu = min (1 - c1) (2 * (muEff - 2 + 1 / muEff) / ((fromIntegral dim + 2) ^ (2 :: Int) + muEff))
                rankMu =
                    Foldable.foldl'
                        (zipWith (zipWith (+)))
                        (replicate dim (replicate dim 0))
                        [ map (scale w) (outer d d)
                        | (w, (x, _)) <- zip weights selected
                        , let d = scale (1 / sigma) (sub x mean)
                        ]
                covariance' =
                    zipWith3
                        ( zipWith3
                            (\a b c -> (1 - c1 - cmu + (if hSigma then 0 else c1 * cc * (2 - cc))) * a + c1 * b + cmu * c)
                        )
                        covariance
                        (outer path' path')
                        rankMu
            let sigma' = sigma * exp (cs / damping * (norm pathSigma' / chi - 1))
                generationBest = sortOn snd scored !! 0
                best' = case best of Just old | snd old < snd generationBest -> old; _ -> generationBest
            checkedPoint (sigma' : concat covariance')
            cma (k + 1) (cost + size) s mean' sigma' covariance' path' pathSigma' (Just best')

covarianceRoots :: [[Double]] -> Either MathError ([[Double]], [[Double]])
covarianceRoots covariance = do
    let n = length covariance
    matrix <- M.fromListChecked n n (concat covariance)
    decomposition <- LA.symmetricEigen matrix
    let eigenvalues = map realPart (LA.eigenvalues decomposition)
        vectors = map realPart (M.toList (LA.eigenvectors decomposition))
        basis = [[vectors !! (i * n + j) | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
    if any (<= 0) eigenvalues then Left (NotPositiveDefinite 0) else Right ()
    let square =
            matMul
                [[(basis !! i) !! j * sqrt (eigenvalues !! j) | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
                (transpose basis)
        inverse =
            matMul
                [[(basis !! i) !! j / sqrt (eigenvalues !! j) | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
                (transpose basis)
    checkedPoint (concat square ++ concat inverse)
    Right (square, inverse)

{- | Basin hopping uses genuine local Nelder–Mead descents followed by seeded
Metropolis transitions. Bounds are enforced by rejecting out-of-box trials.
-}
basinHopping ::
    Word64 ->
    Double ->
    Int ->
    OptimizeOptions ->
    [(Double, Double)] ->
    Objective ->
    [Double] ->
    Either MathError OptimizeResult
basinHopping seed temperature hops o bounds f x0 = do
    checkedOptions o
    validateBounds bounds
    checkedPoint (temperature : x0)
    if temperature <= 0 || hops < 1 || length x0 /= length bounds || clip bounds x0 /= x0
        then Left (InvalidArgument "basin hopping parameters")
        else Right ()
    let guarded x = if clip bounds x == x then f x else Right 1e100
    first <- nelderMead o guarded x0
    go guarded 0 (optEvaluations first) (seedRNG PCG32 seed) first first
  where
    go guarded k cost rng current best
        | k >= hops = Right best{optIterations = k, optEvaluations = cost, optConverged = False}
        | otherwise = do
            (z, s) <- normals (length x0) rng
            let trial = clip bounds (add (optPoint current) (scale (optLearningRate o) z)); (u, t) = uniform s
            r <- nelderMead (o{optMaxEvaluations = optMaxEvaluations o - cost}) guarded trial
            let accept =
                    optValue r < optValue current || log (max 1e-300 u) < (optValue current - optValue r) / temperature
                next = if accept then r else current
                best' = if optValue r < optValue best then r else best
            go guarded (k + 1) (cost + optEvaluations r) t next best'
