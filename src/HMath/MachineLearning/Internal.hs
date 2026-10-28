-- SPDX-License-Identifier: MPL-2.0

-- | Shared, deliberately small dense reference kernels for the ML estimators.
module HMath.MachineLearning.Internal where

import Control.Monad (foldM)
import Data.Complex (imagPart, realPart)
import Data.List (maximumBy, sortOn, transpose)
import Data.Ord (comparing)
import Data.Word (Word64)
import HMath.Error
import qualified HMath.Matrix as M
import qualified HMath.Matrix.Advanced as A
import qualified HMath.Matrix.LAPACK as L

-- | Finite observations as rows with a fixed, positive feature count.
type Dataset = [[Double]]

-- | Positive iteration limit/tolerance/rate and an explicit reproducible seed.
data MLConfig = MLConfig
    { mlIterations :: Int
    -- ^ Maximum outer iterations per fitted algorithm.
    , mlTolerance :: Double
    -- ^ Absolute algorithm-specific stopping residual.
    , mlRate :: Double
    -- ^ Positive gradient step size, where used.
    , mlSeed :: Word64
    -- ^ Seed for initialization, projection, or stochastic updates.
    }
    deriving (Eq, Show)

-- | 500 iterations, absolute residual tolerance 1e-8, rate 0.05, PCG seed 42.
defaultMLConfig :: MLConfig
defaultMLConfig = MLConfig 500 1e-8 0.05 42

-- | A finite budget is a valid stopping point, distinct from convergence.
data Fit a = Fit
    { fitted :: a
    , fitIterations :: Int
    , fitResidual :: Double
    , fitConverged :: Bool
    }
    deriving (Eq, Show)

finite :: Double -> Bool
finite x = not (isNaN x || isInfinite x)
checked :: [Double] -> Either MathError ()
checked xs
    | all finite xs = Right ()
    | otherwise = Left NonFiniteResult
require :: Bool -> String -> Either MathError ()
require True _ = Right ()
require False s = Left (InvalidArgument ("ML: " ++ s))
config :: MLConfig -> Either MathError ()
config c =
    require
        ( mlIterations c > 0
            && finite (mlTolerance c)
            && mlTolerance c > 0
            && finite (mlRate c)
            && mlRate c > 0
        )
        "invalid iteration/tolerance/rate configuration"
dataset :: Dataset -> Either MathError (Int, Int)
dataset [] = Left (InvalidArgument "ML: nonempty dataset required")
dataset xs@(r : _) = do
    let n = length xs; d = length r
    require (d > 0 && all ((== d) . length) xs) "nonzero, rectangular feature shape required"
    require (toInteger n * toInteger d <= toInteger (maxBound :: Int)) "shape overflow"
    checked (concat xs)
    Right (n, d)
responses :: Dataset -> [Double] -> Either MathError (Int, Int)
responses xs ys = do
    dims@(n, _) <- dataset xs
    require (n == length ys) "response count mismatch"
    checked ys
    Right dims
queries :: Int -> Dataset -> Either MathError ()
queries d xs = do
    require (all ((== d) . length) xs) "query feature count mismatch"
    checked (concat xs)
dot :: [Double] -> [Double] -> Double
dot x y = sum (zipWith (*) x y)
add, sub :: [Double] -> [Double] -> [Double]
add = zipWith (+)
sub = zipWith (-)
scale :: Double -> [Double] -> [Double]
scale s = map (s *)
norm :: [Double] -> Double
norm xs | s == 0 = 0 | otherwise = s * sqrt (sum [(x / s) ^ (2 :: Int) | x <- xs])
  where
    s = maximum (0 : map abs xs)
dist2 :: [Double] -> [Double] -> Double
dist2 x y = dot z z where z = sub x y
meanV :: Dataset -> [Double]
meanV xs = foldl1 add (map (scale (1 / fromIntegral (length xs))) xs)
matmul :: Dataset -> Dataset -> Dataset
matmul x y = [[dot r c | c <- transpose y] | r <- x]
ident :: Int -> Dataset
ident n = [[if i == j then 1 else 0 | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
replace :: Int -> a -> [a] -> [a]
replace i x xs = take i xs ++ [x] ++ drop (i + 1) xs
matrix :: Dataset -> Either MathError (M.Matrix Double)
matrix xs = do (n, d) <- dataset xs; M.fromListChecked n d (concat xs)
rows :: M.Matrix a -> [[a]]
rows m | d == 0 = replicate n [] | otherwise = [take d (drop (i * d) (M.toList m)) | i <- [0 .. n - 1]]
  where
    (n, d) = M.shape m
pinv :: Dataset -> Either MathError Dataset
pinv x = matrix x >>= A.pseudoinverse 1e-12 >>= pure . rows
solveLS :: Dataset -> [Double] -> Either MathError [Double]
solveLS x y = do
    _ <- responses x y
    p <- pinv x
    let answer = map (`dot` y) p
    checked answer
    Right answer
inverse :: Dataset -> Either MathError Dataset
inverse x = do
    (n, d) <- dataset x
    require (n == d) "square matrix required"
    p <- pinv x
    let residual = norm (concat (zipWith sub (matmul x p) (ident n)))
    require (residual < 1e-6 * fromIntegral n) "singular matrix"
    Right p
symmetricEigen :: Dataset -> Either MathError ([Double], Dataset)
symmetricEigen x = do
    (n, d) <- dataset x
    require (n == d) "eigendecomposition requires square matrix"
    require
        ( and
            [ abs (x !! i !! j - x !! j !! i) <= 1e-10 * max 1 (abs (x !! i !! j))
            | i <- [0 .. n - 1]
            , j <- [0 .. n - 1]
            ]
        )
        "symmetric matrix required"
    m <- matrix [[x !! i !! j / 2 + x !! j !! i / 2 | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
    e <- L.symmetricEigen m
    let vals = L.eigenvalues e; vs = rows (L.eigenvectors e)
    require (all ((< 1e-8) . abs . imagPart) vals) "unexpected complex symmetric eigenvalue"
    let order = map fst (sortOn (negate . snd) (zip [0 ..] (map realPart vals)))
    Right
        ([realPart (vals !! j) | j <- order], [[realPart (vs !! i !! j) | j <- order] | i <- [0 .. n - 1]])
argmin, argmax :: (Ord a) => [a] -> Int
argmin xs = snd (minimum (zip xs [0 ..]))
argmax xs = snd (maximumBy (comparing fst) (zip xs [0 ..]))

-- | Deterministic reference iteration; residual is supplied by each estimator.
iterateFit ::
    MLConfig -> (a -> Either MathError a) -> (a -> a -> Double) -> a -> Either MathError (Fit a)
iterateFit c step difference start = do
    config c
    go 0 start
  where
    go k old = do
        new <- step old
        let r = difference old new
        checked [r]
        if r <= mlTolerance c
            then Right (Fit new (k + 1) r True)
            else
                if k + 1 >= mlIterations c
                    then Right (Fit new (k + 1) r False)
                    else go (k + 1) new

foldEither :: (a -> b -> Either MathError a) -> a -> [b] -> Either MathError a
foldEither = foldM

firstRow :: [[a]] -> [a]
firstRow [] = []
firstRow (x : _) = x
