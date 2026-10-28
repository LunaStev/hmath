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
    -- ^ Best fitted model retained when fitting stops.
    , fitIterations :: Int
    -- ^ Completed fitting iterations.
    , fitResidual :: Double
    -- ^ Algorithm-specific finite stopping residual at the returned model.
    , fitConverged :: Bool
    -- ^ Whether the selected stopping residual met tolerance; a budget stop may return False.
    }
    deriving (Eq, Show)

-- | Test whether Double is neither NaN nor infinite.
finite :: Double -> Bool
finite x = not (isNaN x || isInfinite x)

-- | Validate a list of finite numerical values, returning Right () or Left NonFiniteResult.
checked :: [Double] -> Either MathError ()
checked xs
    | all finite xs = Right ()
    | otherwise = Left NonFiniteResult

{- | Given condition then diagnostic, return Right () or Left InvalidArgument prefixed with
ML context.
-}
require :: Bool -> String -> Either MathError ()
require True _ = Right ()
require False s = Left (InvalidArgument ("ML: " ++ s))

{- | Validate positive iteration count and positive finite tolerance/learning rate of
MLConfig. Invalid settings return Left InvalidArgument.
-}
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

{- | Validate a nonempty finite rectangular observation-by-feature list with positive
feature count and Int-safe size. Return (observations,features) or Left MathError.
-}
dataset :: Dataset -> Either MathError (Int, Int)
dataset [] = Left (InvalidArgument "ML: nonempty dataset required")
dataset xs@(r : _) = do
    let n = length xs; d = length r
    require (d > 0 && all ((== d) . length) xs) "nonzero, rectangular feature shape required"
    require (toInteger n * toInteger d <= toInteger (maxBound :: Int)) "shape overflow"
    checked (concat xs)
    Right (n, d)

{- | Given dataset then finite response list, validate dataset and equal
observation/response count. Return dataset dimensions; mismatch/non-finite data fails.
-}
responses :: Dataset -> [Double] -> Either MathError (Int, Int)
responses xs ys = do
    dims@(n, _) <- dataset xs
    require (n == length ys) "response count mismatch"
    checked ys
    Right dims

{- | Given expected feature dimension then query rows, validate every row width and finite
values. Empty queries are allowed; mismatch/non-finite values fail.
-}
queries :: Int -> Dataset -> Either MathError ()
queries d xs = do
    require (all ((== d) . length) xs) "query feature count mismatch"
    checked (concat xs)

{- | Unchecked list inner product using zipWith; unequal lengths truncate. Estimator callers
validate feature shapes first.
-}
dot :: [Double] -> [Double] -> Double
dot x y = sum (zipWith (*) x y)

add, sub :: [Double] -> [Double] -> [Double]

{- | Unchecked coordinatewise list addition, truncating to shorter length; checked estimator
callers validate dimensions.
-}
add = zipWith (+)

{- | Unchecked coordinatewise left-minus-right list subtraction, truncating to shorter
length.
-}
sub = zipWith (-)

{- | Given scalar then coordinate list, multiply each coordinate without checked finiteness
validation.
-}
scale :: Double -> [Double] -> [Double]
scale s = map (s *)

{- | Return scaled Euclidean norm of a coordinate list, zero for empty/all-zero input.
Caller validates finite inputs/results when required.
-}
norm :: [Double] -> Double
norm xs | s == 0 = 0 | otherwise = s * sqrt (sum [(x / s) ^ (2 :: Int) | x <- xs])
  where
    s = maximum (0 : map abs xs)

{- | Return squared Euclidean distance using sub and dot. Require matching dimensions
externally; this unchecked helper truncates mismatched lists.
-}
dist2 :: [Double] -> [Double] -> Double
dist2 x y = dot z z where z = sub x y

{- | Return per-feature means for a nonempty equal-width dataset. Empty outer input raises a
pure foldl1 error; use dataset validation before calling.
-}
meanV :: Dataset -> [Double]
meanV xs = foldl1 add (map (scale (1 / fromIntegral (length xs))) xs)

{- | Unchecked dense row-list matrix multiplication via row/column dot products. Caller must
validate rectangular compatible dimensions; zip-based dot otherwise truncates.
-}
matmul :: Dataset -> Dataset -> Dataset
matmul x y = [[dot r c | c <- transpose y] | r <- x]

{- | Return n-by-n Double identity rows for a nonnegative dimension; nonpositive n gives [].
No allocation budget is checked here.
-}
ident :: Int -> Dataset
ident n = [[if i == j then 1 else 0 | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]

{- | Given index,new value,then list, replace by take/drop reconstruction. The checked
caller must ensure an in-range index; this helper does not reject invalid bounds.
-}
replace :: Int -> a -> [a] -> [a]
replace i x xs = take i xs ++ [x] ++ drop (i + 1) xs

{- | Validate dataset then construct row-major Matrix Double with matching dimensions.
Empty/ragged/non-finite input fails.
-}
matrix :: Dataset -> Either MathError (M.Matrix Double)
matrix xs = do (n, d) <- dataset xs; M.fromListChecked n d (concat xs)

-- | Convert Matrix to dense row lists, preserving explicit zero-column row count.
rows :: M.Matrix a -> [[a]]
rows m | d == 0 = replicate n [] | otherwise = [take d (drop (i * d) (M.toList m)) | i <- [0 .. n - 1]]
  where
    (n, d) = M.shape m

{- | Compute a validated dataset pseudoinverse using relative singular-value tolerance 1e-12
and return dense rows. Decomposition/backend failures propagate.
-}
pinv :: Dataset -> Either MathError Dataset
pinv x = matrix x >>= A.pseudoinverse 1e-12 >>= pure . rows

{- | Given dataset then response list, solve least squares through the pseudoinverse.
Validate counts/finite data/result; checked failures propagate.
-}
solveLS :: Dataset -> [Double] -> Either MathError [Double]
solveLS x y = do
    _ <- responses x y
    p <- pinv x
    let answer = map (`dot` y) p
    checked answer
    Right answer

{- | Validate a square dataset, compute pseudoinverse and require inverse reconstruction
residual below 1e-6*n. Reject singular/invalid matrices or decomposition failures.
-}
inverse :: Dataset -> Either MathError Dataset
inverse x = do
    (n, d) <- dataset x
    require (n == d) "square matrix required"
    p <- pinv x
    let residual = norm (concat (zipWith sub (matmul x p) (ident n)))
    require (residual < 1e-6 * fromIntegral n) "singular matrix"
    Right p

{- | Validate finite square approximately symmetric dataset, symmetrize and eigendecompose.
Return descending real eigenvalues and corresponding eigenvector columns as rows;
invalid spectrum/backend failures propagate.
-}
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

{- | Return zero-based first index of a minimum in a nonempty list. Empty list raises a pure
minimum error; callers must validate nonempty input.
-}
argmin xs = snd (minimum (zip xs [0 ..]))

{- | Return zero-based index selected by maximumBy on a nonempty list, with later equal
maxima preferred. Empty list raises a pure error.
-}
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

{- | Monadic left fold: given checked step,initial accumulator,then list, stop at first Left
MathError and otherwise return final accumulator.
-}
foldEither :: (a -> b -> Either MathError a) -> a -> [b] -> Either MathError a
foldEither = foldM

-- | Return the first row of nested lists, or [] for an empty outer list.
firstRow :: [[a]] -> [a]
firstRow [] = []
firstRow (x : _) = x
