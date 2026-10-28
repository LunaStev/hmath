-- SPDX-License-Identifier: MPL-2.0

{- | Checked, finite-difference differentiation and numerical quadrature for
Double callbacks. User callbacks must be total and side-effect free. Budgets
bound refinement; error estimates are numerical estimates, not rigorous bounds.
-}
module HMath.Calculus (
    Estimate (..),
    Tolerance (..),
    defaultTolerance,
    Difference (..),
    derivative,
    derivativeN,
    complexDerivative,
    richardson,
    ridders,
    limit,
    partialDerivative,
    gradient,
    jacobian,
    hessian,
    directionalDerivative,
    jvp,
    vjp,
    hvp,
    divergence,
    curl,
    laplacian,
    Quadrature (..),
    integrateComposite,
    romberg,
    gaussLegendre,
    gaussHermite,
    gaussLaguerre,
    gaussChebyshev,
    gaussKronrod,
    adaptiveIntegrate,
    clenshawCurtis,
    tanhSinh,
    integrateInfinite,
    integrateOscillatory,
    integrateND,
    monteCarlo,
    quasiMonteCarlo,
    cumulativeIntegral,
    pathIntegral,
    lineIntegral,
    surfaceIntegral,
    volumeIntegral,
) where

import Data.Complex (Complex ((:+)), imagPart, realPart)
import Data.List (transpose)
import HMath.Error (MathError (..))
import HMath.Matrix (Matrix, fromListChecked)

-- | Estimated value, absolute error estimate and callback evaluation count.
data Estimate a = Estimate {estimateValue :: a, estimateError :: Double, evaluations :: Int}
    deriving (Eq, Show)

-- | Positive absolute tolerance, nonnegative relative tolerance and positive budget.
data Tolerance = Tolerance {absoluteTolerance :: Double, relativeTolerance :: Double, maximumEvaluations :: Int}
    deriving (Eq, Show)

-- | Default adaptive tolerance: 1e-10 absolute, 1e-8 relative, 100000 evaluations.
defaultTolerance :: Tolerance
defaultTolerance = Tolerance 1e-10 1e-8 100000

-- | One-sided or central first differences.
data Difference = Forward | Backward | Central deriving (Eq, Show)

{- | Composite Newton-Cotes formulas. Simpson panels must be a multiple of 2
and ThreeEighths panels a multiple of 3.
-}
data Quadrature = Trapezoidal | Simpson | ThreeEighths deriving (Eq, Show)

finite :: Double -> Bool
finite x = not (isNaN x || isInfinite x)
check :: Double -> Either MathError Double
check x | finite x = Right x | otherwise = Left NonFiniteResult
require :: Bool -> String -> Either MathError ()
require p message = if p then Right () else Left (InvalidArgument message)
validateTolerance :: Tolerance -> Either MathError ()
validateTolerance (Tolerance a r n) =
    require
        (finite a && finite r && a > 0 && r >= 0 && n > 0)
        "invalid numerical tolerance or evaluation budget"
target :: Tolerance -> Double -> Double
target t x = max (absoluteTolerance t) (relativeTolerance t * abs x)
sample :: (Double -> Double) -> Double -> Either MathError Double
sample f x = check x >> check (f x)

-- | First derivative with explicit positive finite step; rounded-away steps fail.
derivative :: Difference -> Double -> (Double -> Double) -> Double -> Either MathError Double
derivative method h f x = do
    require (finite h && h > 0 && finite x) "invalid differentiation step or point"
    let (a, b) = case method of Forward -> (x, x + h); Backward -> (x - h, x); Central -> (x - h, x + h)
    require (a /= b) "unrepresentable differentiation step"
    fa <- sample f a
    fb <- sample f b
    check ((fb - fa) / (b - a))

{- | Arbitrary nonnegative derivative order by recursively centered differences.
Work grows exponentially with the requested order; orders are limited to 12.
-}
derivativeN :: Int -> Double -> (Double -> Double) -> Double -> Either MathError Double
derivativeN order h f x = do
    require
        (order >= 0 && order <= 12 && finite h && h > 0 && finite x)
        "invalid derivative order or step"
    let go 0 p = sample f p
        go n p = do
            require (p + h /= p && p - h /= p) "rounded-away derivative step"
            a <- go (n - 1) (p - h)
            b <- go (n - 1) (p + h)
            check ((b - a) / (2 * h))
    go order x

{- | Complex-step first derivative. The callback must have a holomorphic
extension and be real on the real axis.
-}
complexDerivative ::
    Double -> (Complex Double -> Complex Double) -> Double -> Either MathError Double
complexDerivative h f x = do
    require (finite h && h > 0 && finite x) "invalid complex-step arguments"
    let value = f (x :+ h)
    _ <- check (realPart value)
    check (imagPart value / h)

{- | Richardson extrapolation of a central first difference. Each row halves
the step. Evaluation budget is 2 per row; convergence uses consecutive diagonals.
-}
richardson ::
    Tolerance -> Double -> (Double -> Double) -> Double -> Either MathError (Estimate Double)
richardson tol initial f x = do
    validateTolerance tol
    require (finite initial && initial > 0) "invalid Richardson step"
    let go k previous h old = do
            require (2 * (k + 1) <= maximumEvaluations tol) "Richardson budget must permit another row"
            base <- derivative Central h f x
            row <- build 1 [base] previous
            let value = last row
                err = maybe (1 / 0) (abs . (value -)) old
            if err <= target tol value
                then Right (Estimate value err (2 * (k + 1)))
                else
                    if k >= 20 || 2 * (k + 2) > maximumEvaluations tol
                        then Left (NonConvergence "Richardson" (2 * (k + 1)))
                        else go (k + 1) row (h / 2) (Just value)
        build _ acc [] = Right acc
        build j acc (p : ps) = do
            let current = last acc
            value <- check (current + (current - p) / (4 ** fromIntegral j - 1))
            build (j + 1 :: Int) (acc ++ [value]) ps
    go (0 :: Int) [] initial Nothing

-- | Ridders extrapolation with factor 1.4 and a best-error stopping criterion.
ridders :: Tolerance -> Double -> (Double -> Double) -> Double -> Either MathError (Estimate Double)
ridders tol initial f x = do
    validateTolerance tol
    require (finite initial && initial > 0) "invalid Ridders step"
    let go k previous h best = do
            d <- derivative Central h f x
            row <- build 1 [d] previous
            let candidates = zipWith3 (\v a b -> (max (abs (v - a)) (abs (v - b)), v)) (drop 1 row) row previous
                best' = foldl (\p q -> if fst q < fst p then q else p) best candidates
                (err, value) = best'
            if err <= target tol value
                then Right (Estimate value err (2 * (k + 1)))
                else
                    if k >= 20 || 2 * (k + 2) > maximumEvaluations tol
                        then Left (NonConvergence "Ridders" (2 * (k + 1)))
                        else go (k + 1) row (h / 1.4) best'
        build _ acc [] = Right acc
        build j acc (p : ps) = do
            let current = last acc; factor = 1.4 ** fromIntegral (2 * j)
            value <- check ((factor * current - p) / (factor - 1))
            build (j + 1 :: Int) (acc ++ [value]) ps
    require (maximumEvaluations tol >= 4) "Ridders needs at least four evaluations"
    go (0 :: Int) [] initial (1 / 0, 0)

{- | One-sided numerical limit, approaching geometrically from the requested
side. Central compares the average of both sides; it cannot prove continuity.
-}
limit ::
    Difference ->
    Tolerance ->
    Double ->
    (Double -> Double) ->
    Double ->
    Either MathError (Estimate Double)
limit side tol initial f x = do
    validateTolerance tol
    require (finite initial && initial > 0 && finite x) "invalid limit arguments"
    let cost = if side == Central then 2 else 1
        go n h old = do
            require (x + h /= x && x - h /= x) "limit reached floating-point resolution"
            value <- case side of
                Forward -> sample f (x + h)
                Backward -> sample f (x - h)
                Central -> do a <- sample f (x - h); b <- sample f (x + h); check ((a + b) / 2)
            let err = maybe (1 / 0) (abs . (value -)) old
            if err <= target tol value
                then Right (Estimate value err (n + cost))
                else
                    if n + 2 * cost > maximumEvaluations tol
                        then Left (NonConvergence "limit" (n + cost))
                        else go (n + cost) (h / 2) (Just value)
    require (maximumEvaluations tol >= cost) "limit budget is too small for one sample"
    go 0 initial Nothing

replace :: Int -> a -> [a] -> [a]
replace i x = zipWith (\j v -> if j == i then x else v) [0 ..]

-- | Partial derivative at a zero-based coordinate.
partialDerivative :: Int -> Double -> ([Double] -> Double) -> [Double] -> Either MathError Double
partialDerivative i h f xs = do
    require (i >= 0 && i < length xs && all finite xs) "invalid derivative coordinate or point"
    derivative Central h (\x -> f (replace i x xs)) (xs !! i)

-- | Gradient using one central difference per coordinate.
gradient :: Double -> ([Double] -> Double) -> [Double] -> Either MathError [Double]
gradient h f xs = do
    require (finite h && h > 0 && all finite xs) "invalid gradient step or point"
    traverse (\i -> partialDerivative i h f xs) [0 .. length xs - 1]

-- | Row-major Jacobian; callback output dimensions must remain constant.
jacobian :: Double -> ([Double] -> [Double]) -> [Double] -> Either MathError (Matrix Double)
jacobian h f xs = do
    require (finite h && h > 0 && all finite xs) "invalid Jacobian step or point"
    let ys = f xs; m = length ys; n = length xs
    require (all finite xs && all finite ys) "nonfinite Jacobian point or result"
    columns <- traverse (column m) [0 .. n - 1]
    fromListChecked m n (concat (transpose columns))
  where
    column m i = do
        require
            (finite h && h > 0 && xs !! i + h /= xs !! i && xs !! i - h /= xs !! i)
            "invalid Jacobian step"
        left <- traverse check (replace i (xs !! i - h) xs)
        right <- traverse check (replace i (xs !! i + h) xs)
        let a = f left; b = f right
        require (length a == m && length b == m) "callback changed Jacobian output dimension"
        _ <- traverse check (a ++ b)
        traverse check (zipWith (\u v -> (v - u) / (2 * h)) a b)

-- | Hessian with centered diagonal and mixed differences.
hessian :: Double -> ([Double] -> Double) -> [Double] -> Either MathError (Matrix Double)
hessian h f xs = do
    require
        (finite h && h > 0 && all finite xs && all (\x -> x + h /= x && x - h /= x) xs)
        "invalid Hessian step or point"
    f0 <- check (f xs)
    values <- traverse (entry f0) [(i, j) | i <- [0 .. n - 1], j <- [0 .. n - 1]]
    fromListChecked n n values
  where
    n = length xs
    point i d j e = replace i (xs !! i + d) (replace j (xs !! j + e) xs)
    evaluatePoint p = traverse check p >> check (f p)
    entry f0 (i, j)
        | i == j = do
            a <- evaluatePoint (replace i (xs !! i + h) xs)
            b <- evaluatePoint (replace i (xs !! i - h) xs)
            check ((a - 2 * f0 + b) / (h * h))
        | otherwise = do
            a <- evaluatePoint (point i h j h)
            b <- evaluatePoint (point i h j (-h))
            c <- evaluatePoint (point i (-h) j h)
            d <- evaluatePoint (point i (-h) j (-h))
            check ((a - b - c + d) / (4 * h * h))

-- | Directional derivative; the direction is used as supplied, without normalization.
directionalDerivative ::
    Double -> ([Double] -> Double) -> [Double] -> [Double] -> Either MathError Double
directionalDerivative h f x v = do
    require
        (length x == length v && all finite (x ++ v))
        "direction dimension mismatch or nonfinite direction"
    derivative
        Central
        h
        (\t -> let p = zipWith (\a b -> a + t * b) x v in if all finite p then f p else 0 / 0)
        0

-- | Jacobian-vector product by directional central differences.
jvp :: Double -> ([Double] -> [Double]) -> [Double] -> [Double] -> Either MathError [Double]
jvp h f x v = do
    require (length x == length v && finite h && h > 0 && all finite (x ++ v)) "invalid JVP arguments"
    left <- traverse check (zipWith (\u w -> u - h * w) x v)
    right <- traverse check (zipWith (\u w -> u + h * w) x v)
    let a = f left; b = f right
    require (length a == length b && length a == length (f x)) "callback changed JVP output dimension"
    _ <- traverse check (a ++ b)
    traverse check (zipWith (\u w -> (w - u) / (2 * h)) a b)

-- | Vector-Jacobian product as the gradient of a scalar contraction.
vjp :: Double -> ([Double] -> [Double]) -> [Double] -> [Double] -> Either MathError [Double]
vjp h f x v = do
    require (length (f x) == length v && all finite v) "VJP output dimension mismatch"
    let contracted p = let y = f p in if length y /= length v then 0 / 0 else sum (zipWith (*) v y)
    gradient h contracted x

-- | Hessian-vector product with four directional/coordinate samples per component.
hvp :: Double -> ([Double] -> Double) -> [Double] -> [Double] -> Either MathError [Double]
hvp h f x v = do
    require (length x == length v && finite h && h > 0 && all finite (x ++ v)) "invalid HVP arguments"
    let at sign = zipWith (\a b -> a + sign * h * b) x v
    a <- gradient h f (at 1)
    b <- gradient h f (at (-1))
    traverse check (zipWith (\u w -> (u - w) / (2 * h)) a b)

-- | Divergence of a vector field with equal input and output dimensions.
divergence :: Double -> ([Double] -> [Double]) -> [Double] -> Either MathError Double
divergence h f x = do
    require
        (finite h && h > 0 && all finite x && length (f x) == length x && all finite (f x))
        "divergence requires finite matching dimensions and a positive step"
    values <-
        traverse
            ( \i ->
                partialDerivative
                    i
                    h
                    (\p -> let y = f p in if length y == length x && all finite y then y !! i else 0 / 0)
                    x
            )
            [0 .. length x - 1]
    check (sum values)

-- | Curl of a three-dimensional vector field.
curl :: Double -> ([Double] -> [Double]) -> [Double] -> Either MathError [Double]
curl h f x = do
    require (length x == 3 && length (f x) == 3) "curl requires three dimensions"
    let part i j =
            partialDerivative
                j
                h
                (\p -> let y = f p in if length y == 3 && all finite y then y !! i else 0 / 0)
                x
    a <- part 2 1
    b <- part 1 2
    c <- part 0 2
    d <- part 2 0
    e <- part 1 0
    g <- part 0 1
    traverse check [a - b, c - d, e - g]

-- | Laplacian as the sum of centered second coordinate differences.
laplacian :: Double -> ([Double] -> Double) -> [Double] -> Either MathError Double
laplacian h f x = do
    require (finite h && h > 0 && all finite x) "invalid Laplacian arguments"
    values <- traverse (\i -> derivativeN 2 h (\p -> f (replace i p x)) (x !! i)) [0 .. length x - 1]
    check (sum values)

-- | Composite finite-interval integration with exact panel constraints.
integrateComposite ::
    Quadrature -> Int -> (Double -> Double) -> Double -> Double -> Either MathError Double
integrateComposite method n f a b = do
    let divisor = case method of Trapezoidal -> 1; Simpson -> 2; ThreeEighths -> 3
    require
        (n > 0 && n `mod` divisor == 0 && finite a && finite b)
        "invalid integration panels or endpoints"
    if a == b
        then Right 0
        else do
            let h = (b - a) / fromIntegral n
                weight i = case method of
                    Trapezoidal -> if i == 0 || i == n then 0.5 else 1
                    Simpson -> if i == 0 || i == n then 1 else if odd i then 4 else 2
                    ThreeEighths -> if i == 0 || i == n then 1 else if i `mod` 3 == 0 then 2 else 3
                factor = case method of Trapezoidal -> 1; Simpson -> 1 / 3; ThreeEighths -> 3 / 8
            values <- traverse (\i -> (weight i *) <$> sample f (a + fromIntegral i * h)) [0 .. n]
            check (h * factor * sum values)

-- | Romberg integration using trapezoidal refinement and Richardson diagonals.
romberg :: Tolerance -> (Double -> Double) -> Double -> Double -> Either MathError (Estimate Double)
romberg tol f a b = do
    validateTolerance tol
    require (finite a && finite b) "nonfinite integration endpoint"
    if a == b
        then Right (Estimate 0 0 0)
        else do
            require (maximumEvaluations tol >= 3) "Romberg needs at least three evaluations"
            fa <- sample f a
            fb <- sample f b
            let go level previous count = do
                    let n = 2 ^ level; newCount = n `div` 2
                    if count + newCount > maximumEvaluations tol
                        then Left (NonConvergence "Romberg" count)
                        else do
                            values <-
                                traverse (\i -> sample f (a + (2 * fromIntegral i - 1) * (b - a) / fromIntegral n)) [1 .. newCount]
                            let first = 0.5 * (previous !! 0) + (b - a) / fromIntegral n * sum values
                                row =
                                    scanl
                                        (\current (j, p) -> current + (current - p) / (4 ** fromIntegral j - 1))
                                        first
                                        (zip [1 :: Int ..] previous)
                                value = last row
                                err = abs (value - last previous)
                            _ <- check value
                            if err <= target tol value
                                then Right (Estimate value err (count + newCount))
                                else
                                    if level >= 20
                                        then Left (NonConvergence "Romberg" (count + newCount))
                                        else go (level + 1) row (count + newCount)
            go (1 :: Int) [(b - a) * (fa + fb) / 2] 2

-- | n-point Gauss-Legendre quadrature; nodes are refined by Newton iteration.
gaussLegendre :: Int -> (Double -> Double) -> Double -> Double -> Either MathError Double
gaussLegendre n f a b = do
    require (n > 0 && n <= 512 && finite a && finite b) "invalid Gauss-Legendre order or bounds"
    nodes <- traverse root [1 .. n]
    values <- traverse (\(x, w) -> (w *) <$> sample f ((a + b) / 2 + (b - a) / 2 * x)) nodes
    check ((b - a) / 2 * sum values)
  where
    poly x =
        foldl
            (\(p, q) k -> (((2 * fromIntegral k - 1) * x * p - (fromIntegral k - 1) * q) / fromIntegral k, p))
            (1, 0)
            [1 .. n]
    root i = go (0 :: Int) (cos (pi * (fromIntegral i - 0.25) / (fromIntegral n + 0.5)))
    go k x =
        let (p, q) = poly x; d = fromIntegral n * (x * p - q) / (x * x - 1); next = x - p / d
         in if k >= 100
                then Left (NonConvergence "Gauss-Legendre node" k)
                else
                    if abs (next - x) <= 4e-16 then Right (next, 2 / ((1 - next * next) * d * d)) else go (k + 1) next

{- | Weighted Gaussian quadrature on the real line for weight exp(-x^2).
Uses the symmetric Jacobi recurrence and a checked implicit QL eigensystem.
-}
gaussHermite :: Int -> (Double -> Double) -> Either MathError Double
gaussHermite n = gaussianRule n (replicate n 0) [sqrt (fromIntegral k / 2) | k <- [1 .. n - 1]] (sqrt pi)

-- | Weighted Gaussian quadrature on [0,infinity) for weight exp(-x).
gaussLaguerre :: Int -> (Double -> Double) -> Either MathError Double
gaussLaguerre n = gaussianRule n [2 * fromIntegral k + 1 | k <- [0 .. n - 1]] (map fromIntegral [1 .. n - 1]) 1

-- | Weighted first-kind Chebyshev rule on [-1,1], weight 1/sqrt(1-x^2).
gaussChebyshev :: Int -> (Double -> Double) -> Either MathError Double
gaussChebyshev n f = do
    require (n > 0 && n <= 100000) "invalid Gauss-Chebyshev order"
    values <- traverse (sample f . cos . (\i -> pi * (fromIntegral i - 0.5) / fromIntegral n)) [1 .. n]
    check (pi / fromIntegral n * sum values)

-- Small symmetric Jacobi eigensolver for quadrature construction; largest
-- off-diagonal rotations preserve eigenvectors and terminate by a scale check.
gaussianRule ::
    Int -> [Double] -> [Double] -> Double -> (Double -> Double) -> Either MathError Double
gaussianRule n diagonal off mass f = do
    require (n > 0 && n <= 64) "weighted Gaussian order must lie in [1,64]"
    let a =
            [ [ if i == j then diagonal !! i else if abs (i - j) == 1 then off !! min i j else 0 | j <- [0 .. n - 1]
              ]
            | i <- [0 .. n - 1]
            ]
        unit = [[if i == j then 1 else 0 | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
        go k matrix vectors =
            let candidates = [(abs (matrix !! i !! j), i, j) | i <- [0 .. n - 1], j <- [i + 1 .. n - 1]]
                (largest, p, q) = if null candidates then (0, 0, 0) else maximum candidates
                scale = maximum (1 : map abs diagonal)
             in if largest <= 1e-14 * scale
                    then Right (matrix, vectors)
                    else
                        if k >= 100 * n * n
                            then Left (NonConvergence "Gaussian quadrature eigensystem" k)
                            else
                                let app = matrix !! p !! p
                                    aqq = matrix !! q !! q
                                    apq = matrix !! p !! q
                                    theta = 0.5 * atan2 (2 * apq) (aqq - app)
                                    c = cos theta
                                    s = sin theta
                                    rotate row = replace q (s * (row !! p) + c * (row !! q)) (replace p (c * (row !! p) - s * (row !! q)) row)
                                    columns = map rotate matrix
                                    matrix' = transpose (map rotate (transpose columns))
                                    vectors' = map rotate vectors
                                 in go (k + 1) matrix' vectors'
    (eigen, vectors) <- go (0 :: Int) a unit
    values <-
        traverse
            (\i -> do y <- sample f (eigen !! i !! i); check (mass * (vectors !! 0 !! i) ^ (2 :: Int) * y))
            [0 .. n - 1]
    check (sum values)

{- | Embedded 7-point Gauss / 15-point Kronrod estimate. Nodes and weights are
the standard Gauss-Kronrod pair used by QUADPACK dqk15 (Netlib).
-}
gaussKronrod :: (Double -> Double) -> Double -> Double -> Either MathError (Estimate Double)
gaussKronrod f a b = do
    require (finite a && finite b) "nonfinite quadrature bounds"
    if a == b
        then Right (Estimate 0 0 0)
        else do
            center <- sample f ((a + b) / 2)
            pairs <-
                traverse
                    ( \x -> do
                        u <- sample f ((a + b) / 2 - (b - a) / 2 * x)
                        v <- sample f ((a + b) / 2 + (b - a) / 2 * x)
                        check (u + v)
                    )
                    nodes
            let kronrod = (b - a) / 2 * (wk0 * center + sum (zipWith (*) weights pairs))
                gauss = (b - a) / 2 * (wg0 * center + sum (zipWith (*) gaussWeights pairs))
            value <- check kronrod
            err <- check (abs (kronrod - gauss))
            Right (Estimate value err 15)
  where
    nodes =
        [ 0.9914553711208126
        , 0.9491079123427585
        , 0.8648644233597691
        , 0.7415311855993944
        , 0.5860872354676911
        , 0.4058451513773972
        , 0.2077849550078985
        ]
    weights =
        [ 0.02293532201052922
        , 0.06309209262997855
        , 0.1047900103222502
        , 0.1406532597155259
        , 0.1690047266392679
        , 0.1903505780647854
        , 0.2044329400752989
        ]
    gaussWeights = [0, 0.1294849661688697, 0, 0.2797053914892767, 0, 0.3818300505051189, 0]
    wk0 = 0.2094821410847278
    wg0 = 0.4179591836734694

{- | Adaptive Gauss-Kronrod with global summed error and a strict evaluation
budget. The interval with the largest estimated error is bisected first.
-}
adaptiveIntegrate ::
    Tolerance -> (Double -> Double) -> Double -> Double -> Either MathError (Estimate Double)
adaptiveIntegrate tol f a b = do
    validateTolerance tol
    require (finite a && finite b) "adaptive bounds must be finite"
    if a == b
        then Right (Estimate 0 0 0)
        else do
            require (maximumEvaluations tol >= 15) "Gauss-Kronrod needs fifteen evaluations"
            first <- gaussKronrod f a b
            let go panels count = do
                    let value = sum [estimateValue e | (_, _, e) <- panels]
                        err = sum [estimateError e | (_, _, e) <- panels]
                    _ <- check value
                    if err <= target tol value
                        then Right (Estimate value err count)
                        else
                            if count + 30 > maximumEvaluations tol
                                then Left (NonConvergence "adaptive Gauss-Kronrod" count)
                                else do
                                    let index = snd (maximum [(estimateError e, i) | (i, (_, _, e)) <- zip [0 ..] panels])
                                        (left, right, _) = panels !! index
                                        middle = left + (right - left) / 2
                                    if middle == left || middle == right
                                        then Left (NonConvergence "adaptive interval resolution" count)
                                        else do
                                            l <- gaussKronrod f left middle
                                            r <- gaussKronrod f middle right
                                            go
                                                (take index panels ++ [(left, middle, l), (middle, right, r)] ++ drop (index + 1) panels)
                                                (count + 30)
            go [(a, b, first)] 15

{- | Clenshaw-Curtis quadrature on n cosine-spaced panels using exact moments
of the cosine interpolant. n must be positive and at most 4096.
-}
clenshawCurtis :: Int -> (Double -> Double) -> Double -> Double -> Either MathError Double
clenshawCurtis n f a b = do
    require (n > 0 && n <= 4096 && finite a && finite b) "invalid Clenshaw-Curtis arguments"
    values <-
        traverse
            (\j -> sample f ((a + b) / 2 + (b - a) / 2 * cos (pi * fromIntegral j / fromIntegral n)))
            [0 .. n]
    let coefficients =
            [ 2
                / fromIntegral n
                * sum
                    [ (if j == 0 || j == n then 0.5 else 1)
                        * values !! j
                        * cos (pi * fromIntegral (k * j) / fromIntegral n)
                    | j <- [0 .. n]
                    ]
            | k <- [0 .. n]
            ]
        moment k = if odd k then 0 else 2 / (1 - fromIntegral (k * k))
        integral = sum [(if k == 0 || k == n then 0.5 else 1) * coefficients !! k * moment k | k <- [0 .. n]]
    check ((b - a) / 2 * integral)

{- | Tanh-sinh quadrature with geometric step refinement on a finite interval.
Rounded-to-endpoint nodes are omitted, supporting integrable endpoint poles.
-}
tanhSinh ::
    Tolerance -> (Double -> Double) -> Double -> Double -> Either MathError (Estimate Double)
tanhSinh tol f a b = do
    validateTolerance tol
    require (finite a && finite b) "tanh-sinh bounds must be finite"
    if a == b
        then Right (Estimate 0 0 0)
        else do
            let rule h = do
                    let n = ceiling (3.5 / h) :: Int
                    require (2 * n + 1 <= maximumEvaluations tol) "tanh-sinh initial budget too small"
                    terms <- traverse (node h) [-n .. n]
                    value <- check (h * sum terms)
                    Right (value, 2 * n + 1)
                node h k =
                    let t = fromIntegral k * h
                        u = pi / 2 * sinh t
                        z = tanh u
                        x = (a + b) / 2 + (b - a) / 2 * z
                        weight = (b - a) / 2 * pi / 2 * cosh t / (cosh u * cosh u)
                     in if x == a || x == b then Right 0 else do y <- sample f x; check (weight * y)
                go h old count = do
                    let n = 2 * (ceiling (3.5 / h) :: Int) + 1
                    if count + n > maximumEvaluations tol
                        then Left (NonConvergence "tanh-sinh" count)
                        else do
                            (value, cost) <- rule h
                            let err = maybe (1 / 0) (abs . (value -)) old
                            if err <= target tol value
                                then Right (Estimate value err (count + cost))
                                else go (h / 2) (Just value) (count + cost)
            go 1 Nothing 0

{- | Integrate on finite, half-infinite or doubly-infinite intervals by an open
coordinate transform followed by adaptive Gauss-Kronrod. Reversed bounds
change the sign. Divergent integrals have no guaranteed detection criterion.
-}
integrateInfinite ::
    Tolerance -> (Double -> Double) -> Double -> Double -> Either MathError (Estimate Double)
integrateInfinite tol f a b
    | isNaN a || isNaN b = Left (InvalidArgument "NaN integration bound")
    | a > b = fmap (\e -> e{estimateValue = negate (estimateValue e)}) (integrateInfinite tol f b a)
    | finite a && finite b = adaptiveIntegrate tol f a b
    | a == (-1 / 0) && b == 1 / 0 =
        adaptiveIntegrate tol (\t -> let p = pi * (t - 0.5); c = cos p in f (tan p) * pi / (c * c)) 0 1
    | finite a && b == 1 / 0 =
        adaptiveIntegrate tol (\t -> f (a + t / (1 - t)) / (1 - t) ^ (2 :: Int)) 0 1
    | a == (-1 / 0) && finite b =
        adaptiveIntegrate tol (\t -> f (b - t / (1 - t)) / (1 - t) ^ (2 :: Int)) 0 1
    | otherwise = Left (InvalidArgument "invalid infinite integration bounds")

{- | Integrate f(x)*cos(omega*x) or f(x)*sin(omega*x), splitting at least once
per half-period to avoid accepting an aliased embedded quadrature estimate.
-}
integrateOscillatory ::
    Bool ->
    Double ->
    Tolerance ->
    (Double -> Double) ->
    Double ->
    Double ->
    Either MathError (Estimate Double)
integrateOscillatory sine omega tol f a b = do
    validateTolerance tol
    require (finite omega && finite a && finite b) "invalid oscillatory integration arguments"
    let panelsDouble = max 1 (ceiling (abs (omega * (b - a)) / pi) :: Integer)
    require
        (panelsDouble * 15 <= toInteger (maximumEvaluations tol))
        "oscillatory budget is too small for the frequency"
    let n = fromInteger panelsDouble :: Int
        trig = if sine then sin else cos
        local =
            tol
                { absoluteTolerance = absoluteTolerance tol / fromIntegral n
                , maximumEvaluations = maximumEvaluations tol `div` n
                }
    estimates <-
        traverse
            ( \i ->
                adaptiveIntegrate
                    local
                    (\x -> f x * trig (omega * x))
                    (a + (b - a) * fromIntegral i / fromIntegral n)
                    (a + (b - a) * fromIntegral (i + 1) / fromIntegral n)
            )
            [0 .. n - 1]
    value <- check (sum (map estimateValue estimates))
    Right (Estimate value (sum (map estimateError estimates)) (sum (map evaluations estimates)))

{- | Tensor-product midpoint integration over a box. The product of panel
counts is checked against the explicit budget before callback evaluation.
-}
integrateND :: Int -> Int -> ([Double] -> Double) -> [(Double, Double)] -> Either MathError Double
integrateND panels budget f bounds = do
    require
        (panels > 0 && budget > 0 && all (\(a, b) -> finite a && finite b) bounds)
        "invalid multidimensional integration arguments"
    let count = toInteger panels ^ length bounds
    require (count <= toInteger budget) "multidimensional quadrature exceeds evaluation budget"
    let points =
            sequence
                [ [a + (b - a) * (fromIntegral i + 0.5) / fromIntegral panels | i <- [0 .. panels - 1]]
                | (a, b) <- bounds
                ]
        volume = product [(b - a) / fromIntegral panels | (a, b) <- bounds]
    values <- traverse (\p -> traverse check p >> check (f p)) points
    check (volume * sum values)

{- | Reproducible Monte Carlo box integral with an explicit 64-bit seed.
Error is one estimated standard error from Welford's sample variance.
-}
monteCarlo ::
    Integer -> Int -> ([Double] -> Double) -> [(Double, Double)] -> Either MathError (Estimate Double)
monteCarlo seed n f bounds = do
    require
        (n >= 2 && all (\(a, b) -> finite a && finite b) bounds)
        "Monte Carlo needs two samples and finite bounds"
    let next s = (6364136223846793005 * s + 1442695040888963407) `mod` (2 ^ (64 :: Int))
        point s =
            foldl
                ( \(state, acc) (a, b) ->
                    let t = next state; u = fromInteger (t `div` 2048) / 9007199254740992
                     in (t, acc ++ [a + (b - a) * u])
                )
                (s, [])
                bounds
        go 0 _ _ mean m2 = Right (mean, m2)
        go remaining state count mean m2 = do
            let (state', xs) = point state
            _ <- traverse check xs
            y <- check (f xs)
            let count' = count + 1; delta = y - mean; mean' = mean + delta / fromIntegral count'
            go (remaining - 1) state' count' mean' (m2 + delta * (y - mean'))
    (mean, m2) <- go n seed (0 :: Int) 0 0
    let volume = product [b - a | (a, b) <- bounds]
    value <- check (volume * mean)
    err <- check (abs volume * sqrt (max 0 m2 / fromIntegral (n - 1) / fromIntegral n))
    Right (Estimate value err n)

{- | Deterministic Halton-box quadrature, up to 16 dimensions. No probabilistic
error bound is claimed; estimateError is the difference of the two halves.
-}
quasiMonteCarlo ::
    Int -> ([Double] -> Double) -> [(Double, Double)] -> Either MathError (Estimate Double)
quasiMonteCarlo n f bounds = do
    require
        (n >= 2 && length bounds <= 16 && all (\(a, b) -> finite a && finite b) bounds)
        "invalid Halton quadrature arguments"
    let bases = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53]
        radical base index = go index (1 / fromIntegral base) 0
          where
            go 0 _ acc = acc
            go k factor acc = go (k `div` base) (factor / fromIntegral base) (acc + fromIntegral (k `mod` base) * factor)
        point i = zipWith (\(a, b) base -> a + (b - a) * radical base i) bounds bases
        volume = product [b - a | (a, b) <- bounds]
    values <- traverse (\i -> let p = point i in traverse check p >> check (f p)) [1 .. n]
    let half = n `div` 2
        left = sum (take half values) / fromIntegral half
        right = sum (drop half values) / fromIntegral (n - half)
    value <- check (volume * sum values / fromIntegral n)
    err <- check (abs (volume * (left - right)))
    Right (Estimate value err n)

-- | Cumulative trapezoidal integrals at strictly increasing sample coordinates.
cumulativeIntegral :: [(Double, Double)] -> Either MathError [Double]
cumulativeIntegral [] = Right []
cumulativeIntegral values = do
    require
        ( all (\(x, y) -> finite x && finite y) values
            && and (zipWith (<) (map fst values) (drop 1 (map fst values)))
        )
        "samples must be finite with strictly increasing coordinates"
    increments <-
        traverse (\((x, y), (u, v)) -> check ((u - x) * (y + v) / 2)) (zip values (drop 1 values))
    traverse check (scanl (+) 0 increments)

-- | Scalar line integral f(r(t))*|r'(t)| along an explicitly parameterized path.
pathIntegral ::
    Tolerance ->
    (Double -> [Double]) ->
    (Double -> [Double]) ->
    ([Double] -> Double) ->
    Double ->
    Double ->
    Either MathError (Estimate Double)
pathIntegral tol curve tangent f a b = adaptiveIntegrate tol integrand a b
  where
    integrand t =
        let p = curve t; v = tangent t
         in if length p /= length v || not (all finite (p ++ v))
                then 0 / 0
                else f p * sqrt (sum (map (^ (2 :: Int)) v))

-- | Oriented vector-field line integral along a parameterized path.
lineIntegral ::
    Tolerance ->
    (Double -> [Double]) ->
    (Double -> [Double]) ->
    ([Double] -> [Double]) ->
    Double ->
    Double ->
    Either MathError (Estimate Double)
lineIntegral tol curve tangent field a b = adaptiveIntegrate tol integrand a b
  where
    integrand t =
        let p = curve t; v = tangent t
         in if length p /= length v || not (all finite (p ++ v))
                then 0 / 0
                else
                    let w = field p
                     in if length v /= length w || not (all finite w) then 0 / 0 else sum (zipWith (*) v w)

-- | Scalar surface integral over a rectangular parameter domain in R3.
surfaceIntegral ::
    Int ->
    Int ->
    ([Double] -> [Double]) ->
    ([Double] -> [Double]) ->
    ([Double] -> [Double]) ->
    ([Double] -> Double) ->
    [(Double, Double)] ->
    Either MathError Double
surfaceIntegral panels budget surface du dv f bounds = do
    require (length bounds == 2) "surface parameter domain must have two dimensions"
    let integrand uv = case (surface uv, du uv, dv uv) of
            (p, [a, b, c], [x, y, z])
                | length p == 3 && all finite (p ++ [a, b, c, x, y, z]) ->
                    f p
                        * sqrt ((b * z - c * y) ^ (2 :: Int) + (c * x - a * z) ^ (2 :: Int) + (a * y - b * x) ^ (2 :: Int))
            _ -> 0 / 0
    integrateND panels budget integrand bounds

-- | Volume integral over a three-dimensional rectangular box.
volumeIntegral ::
    Int -> Int -> ([Double] -> Double) -> [(Double, Double)] -> Either MathError Double
volumeIntegral panels budget f bounds =
    require (length bounds == 3) "volume domain must have three dimensions"
        >> integrateND panels budget f bounds
