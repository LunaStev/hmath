-- SPDX-License-Identifier: MPL-2.0

{- | Checked reference interpolation and approximation. Samples are strictly
increasing, finite, and unique; no silent sorting or duplicate averaging.
Piecewise coefficients are ascending powers of (x-left knot), intervals are
left closed/right open except the final endpoint. Error results are sampled
estimates, not mathematical enclosures. Dense fitting is bounded to 1024
samples, degree 64, and 16 scattered dimensions.
-}
module HMath.Interpolation (
    Extrapolation (..),
    InterpolationMethod (..),
    interpolate,
    hermite,
    cubicHermite,
    SplineBoundary (..),
    PiecewisePolynomial,
    piecewisePolynomial,
    piecewiseKnots,
    evaluatePiecewise,
    differentiatePiecewise,
    integratePiecewise,
    cubicSpline,
    pchip,
    akima,
    smoothingSpline,
    BSpline,
    bSpline,
    evaluateBSpline,
    derivativeBSpline,
    insertKnot,
    bezier,
    rationalBezier,
    cardinalSpline,
    catmullRom,
    kochanekBartels,
    curveIntegral,
    arcLength,
    gridInterpolate,
    RadialKernel (..),
    RBF,
    fitRBF,
    evaluateRBF,
    inverseDistance,
    shepard,
    kriging,
    Approximation (..),
    polynomialFit,
    chebyshevApproximate,
    evaluateChebyshev,
    pade,
    rationalFit,
    remez,
    nonlinearFit,
    interpolationError,
) where

import qualified HMath.Calculus as C
import HMath.Error (MathError (..))
import qualified HMath.Matrix as M
import qualified HMath.Matrix.QR as QR
import HMath.Signal.Internal

-- | Reject out-of-domain queries, clamp to an endpoint, or evaluate the endpoint polynomial beyond its interval.
data Extrapolation = Reject | Clamp | Extrapolate deriving (Eq, Show)

-- | Independent scalar nearest, linear, Lagrange, Newton divided-difference or barycentric formula.
data InterpolationMethod = Nearest | Linear | Lagrange | Newton | Barycentric deriving (Eq, Show)

-- | Natural zero curvature, supplied clamped endpoint slopes, or periodic value/derivative matching.
data SplineBoundary = Natural | Clamped Double Double | Periodic deriving (Eq, Show)

-- | Opaque ascending local polynomial coefficients and strictly increasing breakpoints.
data PiecewisePolynomial = PiecewisePolynomial [Double] [[Double]] deriving (Eq, Show)

-- | Opaque rational B-spline with positive weights and a validated full knot vector.
data BSpline = BSpline Int [Double] [[Double]] [Double] deriving (Eq, Show)

-- | Radial interpolation kernels; the first three accept a positive inverse-length shape parameter.
data RadialKernel
    = Gaussian Double
    | Multiquadric Double
    | InverseMultiquadric Double
    | ThinPlate
    | Cubic
    deriving (Eq, Show)

-- | Opaque fitted radial model with an affine polynomial tail.
data RBF = RBF RadialKernel [[Double]] [Double] [Double] deriving (Eq, Show)

-- | Coefficients or parameters, observed absolute residual, and iteration/evaluation count; error is an estimate.
data Approximation = Approximation
    { approximationCoefficients :: [Double]
    , approximationError :: Double
    , approximationIterations :: Int
    }
    deriving (Eq, Show)

samples :: [(Double, Double)] -> Either MathError ([Double], [Double])
samples points = do
    let (xs, ys) = unzip points
    require
        (not (null xs) && length xs <= 1024 && and (zipWith (<) xs (drop 1 xs)))
        "samples must be strictly increasing, unique and nonempty (maximum 1024)"
    _ <- vector (xs ++ ys)
    Right (xs, ys)
pointPolicy :: Extrapolation -> [Double] -> Double -> Either MathError Double
pointPolicy policy xs x = do
    _ <- checked x
    let lo = xs !! 0; hi = last xs
    require (policy /= Reject || x >= lo && x <= hi) "point outside interpolation domain"
    Right (if policy == Clamp then max lo (min hi x) else x)

-- | Interpolate ordered (x,y) samples using the selected formula and extrapolation policy; nearest ties choose the earlier node.
interpolate ::
    InterpolationMethod -> Extrapolation -> [(Double, Double)] -> Double -> Either MathError Double
interpolate method policy points x0 = do
    (xs, ys) <- samples points
    x <- pointPolicy policy xs x0
    let n = length xs
        interval = min (n - 2) (max 0 (length (takeWhile (<= x) xs) - 1))
        polynomialValue = case method of
            Nearest -> snd (minimumByDistance x points)
            Linear ->
                if n == 1
                    then ys !! 0
                    else
                        let i = interval; t = (x - xs !! i) / (xs !! (i + 1) - xs !! i)
                         in (1 - t) * ys !! i + t * ys !! (i + 1)
            Lagrange ->
                sum
                    [ ys !! i * product [(x - xs !! j) / (xs !! i - xs !! j) | j <- [0 .. n - 1], j /= i]
                    | i <- [0 .. n - 1]
                    ]
            Newton ->
                let columns =
                        scanl
                            (\v k -> [(v !! (i + 1) - v !! i) / (xs !! (i + k) - xs !! i) | i <- [0 .. length v - 2]])
                            ys
                            [1 .. n - 1]
                    -- Explicit divided-difference table, separate from Lagrange.
                    coeffs = map (!! 0) columns
                 in sum [coeffs !! k * product (take k (map (x -) xs)) | k <- [0 .. n - 1]]
            Barycentric -> case lookup x points of
                Just y -> y
                Nothing ->
                    let weights =
                            [1 / product [xi - xj | (j, xj) <- zip [0 :: Int ..] xs, j /= i] | (i, xi) <- zip [0 :: Int ..] xs]
                        terms = zipWith (\w xi -> w / (x - xi)) weights xs
                     in dot terms ys / sum terms
    checked polynomialValue
  where
    minimumByDistance x = foldl1 (\a b -> if abs (fst a - x) <= abs (fst b - x) then a else b)

{- | Global confluent Hermite polynomial, distinct nodes and supplied first
derivatives. Uses the squared Lagrange cardinal functions.
-}
hermite :: [(Double, Double, Double)] -> Double -> Either MathError Double
hermite triples x = do
    (xs, _) <- samples [(a, b) | (a, b, _) <- triples]
    _ <- vector (x : [d | (_, _, d) <- triples])
    let n = length xs
        term i (_, y, d) =
            let xi = xs !! i
                l = product [(x - xs !! j) / (xi - xs !! j) | j <- [0 .. n - 1], j /= i]
                slope = sum [1 / (xi - xs !! j) | j <- [0 .. n - 1], j /= i]
             in ((1 - 2 * (x - xi) * slope) * y + (x - xi) * d) * l * l
    checked (sum (zipWith term [0 ..] triples))

-- | Validate breakpoints and nonempty coefficient rows. Each row uses ascending powers of displacement from its left knot.
piecewisePolynomial :: [Double] -> [[Double]] -> Either MathError PiecewisePolynomial
piecewisePolynomial knots coefficients = do
    require
        ( length knots >= 2
            && length knots <= 1024
            && length coefficients == length knots - 1
            && and (zipWith (<) knots (drop 1 knots))
            && all (\r -> not (null r) && length r <= 65) coefficients
        )
        "invalid piecewise polynomial knots/coefficients"
    _ <- vector (knots ++ concat coefficients)
    Right (PiecewisePolynomial knots coefficients)

-- | Return the immutable piecewise breakpoints, including both outer endpoints.
piecewiseKnots :: PiecewisePolynomial -> [Double]
piecewiseKnots (PiecewisePolynomial xs _) = xs

-- | Evaluate by Horner rule in the containing interval; use the final interval at the right endpoint.
evaluatePiecewise :: Extrapolation -> PiecewisePolynomial -> Double -> Either MathError Double
evaluatePiecewise policy (PiecewisePolynomial xs coeffs) x0 = do
    x <- pointPolicy policy xs x0
    let i = min (length coeffs - 1) (max 0 (length (takeWhile (<= x) xs) - 1))
    checked (polyEval (coeffs !! i) (x - xs !! i))

polyEval :: [Double] -> Double -> Double
polyEval cs x = foldr (\a b -> a + x * b) 0 cs

-- | Differentiate each local coefficient row without changing the breakpoints.
differentiatePiecewise :: PiecewisePolynomial -> Either MathError PiecewisePolynomial
differentiatePiecewise (PiecewisePolynomial xs cs) = piecewisePolynomial xs [if length r == 1 then [0] else zipWith (*) [1 ..] (drop 1 r) | r <- cs]

-- | Exact polynomial antiderivative across all crossed intervals; both limits must lie inside the domain.
integratePiecewise :: PiecewisePolynomial -> Double -> Double -> Either MathError Double
integratePiecewise pp@(PiecewisePolynomial xs cs) a b = do
    _ <- pointPolicy Reject xs a
    _ <- pointPolicy Reject xs b
    if a > b
        then negate <$> integratePiecewise pp b a
        else
            checked
                ( sum
                    [ primitive i (min b (xs !! (i + 1))) - primitive i (max a (xs !! i))
                    | i <- [0 .. length cs - 1]
                    , max a (xs !! i) < min b (xs !! (i + 1))
                    ]
                )
  where
    primitive i x = polyEval (0 : zipWith (/) (cs !! i) [1 ..]) (x - xs !! i)

{- | Piecewise cubic Hermite interpolation with supplied endpoint derivatives.
Triples are (coordinate,value,slope); first derivatives are continuous at
shared knots, while second derivatives need not agree.
-}
cubicHermite :: [(Double, Double, Double)] -> Either MathError PiecewisePolynomial
cubicHermite triples = do
    (xs, ys) <- samples [(x, y) | (x, y, _) <- triples]
    let derivatives = [d | (_, _, d) <- triples]
    require (length xs >= 2) "cubic Hermite needs two samples"
    _ <- vector derivatives
    hermitePieces xs ys derivatives

hermitePieces :: [Double] -> [Double] -> [Double] -> Either MathError PiecewisePolynomial
hermitePieces xs ys ds =
    piecewisePolynomial
        xs
        [ let h = xs !! (i + 1) - xs !! i; s = (ys !! (i + 1) - ys !! i) / h
           in [ ys !! i
              , ds !! i
              , (3 * s - 2 * ds !! i - ds !! (i + 1)) / h
              , (ds !! i + ds !! (i + 1) - 2 * s) / (h * h)
              ]
        | i <- [0 .. length xs - 2]
        ]

{- | Cubic C2 interpolation. Periodic requires equal endpoint values and at least
three intervals; endpoint first and second derivatives agree.
-}
cubicSpline :: SplineBoundary -> [(Double, Double)] -> Either MathError PiecewisePolynomial
cubicSpline boundary points = do
    (xs, ys) <- samples points
    let n = length xs; h = zipWith (-) (drop 1 xs) xs; slopes = zipWith (/) (zipWith (-) (drop 1 ys) ys) h
    require (n >= 2) "cubic spline needs two samples"
    second <- case boundary of
        Periodic -> do
            require (n >= 4 && ys !! 0 == last ys) "periodic cubic needs >=4 samples and equal endpoint values"
            let m = n - 1
                row i =
                    [ (if j == i then 2 * (h !! ((i - 1) `mod` m) + h !! i) else 0)
                        + (if j == (i - 1) `mod` m then h !! ((i - 1) `mod` m) else 0)
                        + (if j == (i + 1) `mod` m then h !! i else 0)
                    | j <- [0 .. m - 1]
                    ]
            v <-
                solve
                    [row i | i <- [0 .. m - 1]]
                    [6 * (slopes !! i - slopes !! ((i - 1) `mod` m)) | i <- [0 .. m - 1]]
            Right (v ++ [v !! 0])
        _ -> do
            let first = case boundary of
                    Clamped _ _ -> [2 * h !! 0, h !! 0] ++ replicate (n - 2) 0
                    _ -> 1 : replicate (n - 1) 0
                end = case boundary of
                    Clamped _ _ -> replicate (n - 2) 0 ++ [last h, 2 * last h]
                    _ -> replicate (n - 1) 0 ++ [1]
                middle i =
                    [ if j == i - 1
                        then h !! (i - 1)
                        else if j == i then 2 * (h !! (i - 1) + h !! i) else if j == i + 1 then h !! i else 0
                    | j <- [0 .. n - 1]
                    ]
                left = case boundary of Clamped d _ -> 6 * (slopes !! 0 - d); _ -> 0
                right = case boundary of Clamped _ d -> 6 * (d - last slopes); _ -> 0
            solve
                (first : [middle i | i <- [1 .. n - 2]] ++ [end])
                (left : [6 * (slopes !! i - slopes !! (i - 1)) | i <- [1 .. n - 2]] ++ [right])
    piecewisePolynomial
        xs
        [ [ ys !! i
          , slopes !! i - h !! i * (2 * second !! i + second !! (i + 1)) / 6
          , second !! i / 2
          , (second !! (i + 1) - second !! i) / (6 * h !! i)
          ]
        | i <- [0 .. n - 2]
        ]

{- | Fritsch--Carlson/PCHIP weighted harmonic interior slopes and limited one-
sided endpoints preserve monotonicity on monotone data.
-}
pchip :: [(Double, Double)] -> Either MathError PiecewisePolynomial
pchip points = do
    (xs, ys) <- samples points
    require (length xs >= 2) "PCHIP needs two samples"
    let n = length xs
        h = zipWith (-) (drop 1 xs) xs
        s = zipWith (/) (zipWith (-) (drop 1 ys) ys) h
        endpoint h0 h1 s0 s1 =
            let d = ((2 * h0 + h1) * s0 - h0 * s1) / (h0 + h1)
             in if d * s0 <= 0 then 0 else if s0 * s1 < 0 && abs d > 3 * abs s0 then 3 * s0 else d
        interior i =
            if s !! (i - 1) * s !! i <= 0
                then 0
                else
                    let w1 = 2 * h !! i + h !! (i - 1); w2 = h !! i + 2 * h !! (i - 1)
                     in (w1 + w2) / (w1 / s !! (i - 1) + w2 / s !! i)
        ds =
            if n == 2
                then [s !! 0, s !! 0]
                else
                    endpoint (h !! 0) (h !! 1) (s !! 0) (s !! 1)
                        : [interior i | i <- [1 .. n - 2]]
                        ++ [endpoint (last h) (h !! (n - 3)) (last s) (s !! (n - 3))]
    hermitePieces xs ys ds

-- | Akima cubic interpolation using slope-difference weights and linearly extended endpoint secants; at least three samples.
akima :: [(Double, Double)] -> Either MathError PiecewisePolynomial
akima points = do
    (xs, ys) <- samples points
    require (length xs >= 3) "Akima needs three samples"
    let s = zipWith (/) (zipWith (-) (drop 1 ys) ys) (zipWith (-) (drop 1 xs) xs)
        ext =
            [3 * s !! 0 - 2 * s !! 1, 2 * s !! 0 - s !! 1]
                ++ s
                ++ [2 * last s - s !! (length s - 2), 3 * last s - 2 * s !! (length s - 2)]
        ds =
            [ let a = abs (ext !! (i + 3) - ext !! (i + 2)); b = abs (ext !! (i + 1) - ext !! i)
               in if a + b == 0
                    then (ext !! (i + 1) + ext !! (i + 2)) / 2
                    else (a * ext !! (i + 1) + b * ext !! (i + 2)) / (a + b)
            | i <- [0 .. length xs - 1]
            ]
    hermitePieces xs ys ds

{- | Natural cubic smoothing spline minimizing sum (y_i-s(x_i))² plus lambda
times integral s''². Reinsch Q/R formulation, unit observation weights.
-}
smoothingSpline :: Double -> [(Double, Double)] -> Either MathError PiecewisePolynomial
smoothingSpline lambda points = do
    (xs, ys) <- samples points
    require (finite lambda && lambda >= 0 && length xs >= 3) "invalid smoothing spline"
    let n = length xs
        m = n - 2
        h = zipWith (-) (drop 1 xs) xs
        q =
            [ [ if i == j
                    then 1 / h !! j
                    else
                        if i == j + 1 then -1 / h !! j - 1 / h !! (j + 1) else if i == j + 2 then 1 / h !! (j + 1) else 0
              | j <- [0 .. m - 1]
              ]
            | i <- [0 .. n - 1]
            ]
        r =
            [ [ if i == j then (h !! i + h !! (i + 1)) / 3 else if abs (i - j) == 1 then h !! max i j / 6 else 0
              | j <- [0 .. m - 1]
              ]
            | i <- [0 .. m - 1]
            ]
        system = zipWith (zipWith (+)) r (map (map (lambda *)) (mm (tr q) q))
    gamma <- solve system (mv (tr q) ys)
    fitted <- vector (zipWith (-) ys (map (lambda *) (mv q gamma)))
    cubicSpline Natural (zip xs fitted)

{- | Nondecreasing full knot vector, degree 0..16, positive rational weights,
control points of equal dimension. Evaluation domain [k_p,k_n].
-}
bSpline :: Int -> [Double] -> [[Double]] -> [Double] -> Either MathError BSpline
bSpline degree knots controls weights = do
    let n = length controls; d = if null controls then 0 else length (controls !! 0)
    require
        ( degree >= 0
            && degree <= 16
            && n > degree
            && n <= 1024
            && d > 0
            && d <= 16
            && all ((== d) . length) controls
            && length weights == n
            && all (> 0) weights
            && length knots == n + degree + 1
            && and (zipWith (<=) knots (drop 1 knots))
            && knots !! degree < knots !! n
        )
        "invalid B-spline degree/knots/control points/positive weights"
    _ <- vector (knots ++ concat controls ++ weights)
    Right (BSpline degree knots controls weights)

basis :: Int -> [Double] -> Int -> Double -> Double
basis p knots i x
    | p == 0 = if knots !! i <= x && x < knots !! (i + 1) then 1 else 0
    | otherwise =
        let a = knots !! (i + p) - knots !! i; b = knots !! (i + p + 1) - knots !! (i + 1)
         in (if a == 0 then 0 else (x - knots !! i) / a * basis (p - 1) knots i x)
                + (if b == 0 then 0 else (knots !! (i + p + 1) - x) / b * basis (p - 1) knots (i + 1) x)

splineHomogeneous :: BSpline -> Double -> Either MathError ([Double], Double, [Double], Double)
splineHomogeneous (BSpline p knots controls ws) x0 = do
    let n = length controls; hi = knots !! n
    _ <- pointPolicy Reject [knots !! p, hi] x0
    -- Evaluate the right endpoint using the exact limiting basis.
    let evalBasis degree i =
            if x0 == hi
                then basis degree (map negate (reverse knots)) (length knots - degree - 2 - i) (-x0)
                else basis degree knots i x0
        bs = [evalBasis p i | i <- [0 .. n - 1]]
        db i =
            if p == 0
                then 0
                else
                    let a = knots !! (i + p) - knots !! i; b = knots !! (i + p + 1) - knots !! (i + 1)
                     in (if a == 0 then 0 else fromIntegral p / a * evalBasis (p - 1) i)
                            - (if b == 0 then 0 else fromIntegral p / b * evalBasis (p - 1) (i + 1))
        numerator = mv (tr controls) (zipWith (*) bs ws)
        denominator = dot bs ws
        dnumerator = mv (tr controls) (zipWith (*) [db i | i <- [0 .. n - 1]] ws)
        ddenominator = dot [db i | i <- [0 .. n - 1]] ws
    require (denominator > 0 && finite denominator) "zero/overflow rational spline denominator"
    _ <- vector (numerator ++ dnumerator ++ [ddenominator])
    Right (numerator, denominator, dnumerator, ddenominator)

-- | Evaluate rational Cox--de Boor basis functions and divide homogeneous coordinates by their positive total weight.
evaluateBSpline :: BSpline -> Double -> Either MathError [Double]
evaluateBSpline s x = do (v, w, _, _) <- splineHomogeneous s x; vector (map (/ w) v)

-- | Analytic first derivative of a rational B-spline using basis derivatives and the homogeneous quotient rule.
derivativeBSpline :: BSpline -> Double -> Either MathError [Double]
derivativeBSpline s x = do (v, w, dv, dw) <- splineHomogeneous s x; vector (zipWith (\a b -> (a - b * (dw / w)) / w) dv v)

-- | One Boehm knot insertion in homogeneous coordinates; shape is preserved.
insertKnot :: BSpline -> Double -> Either MathError BSpline
insertKnot (BSpline p knots controls ws) u = do
    let n = length controls
        k = min (n - 1) (length (takeWhile (<= u) knots) - 1)
        s = length (filter (== u) knots)
    require
        (finite u && u > knots !! p && u < knots !! n && s < p)
        "knot insertion needs interior knot with multiplicity less than degree"
    let hc = zipWith (\v w -> map (w *) v ++ [w]) controls ws
        at i
            | i <= k - p = hc !! i
            | i >= k - s + 1 = hc !! (i - 1)
            | otherwise =
                let a = (u - knots !! i) / (knots !! (i + p) - knots !! i)
                 in zipWith (\x y -> a * x + (1 - a) * y) (hc !! i) (hc !! (i - 1))
        next = map at [0 .. n]
        ww = map last next
        cc = zipWith (\v w -> map (/ w) (init v)) next ww
    bSpline p (take (k + 1) knots ++ [u] ++ drop (k + 1) knots) cc ww

-- | Positive-weight rational Bezier curve on [0,1], represented exactly as an open clamped B-spline (degree <=16).
rationalBezier :: [[Double]] -> [Double] -> Double -> Either MathError [Double]
rationalBezier controls ws t = do
    require
        (length controls >= 1 && length controls <= 17 && finite t && t >= 0 && t <= 1)
        "invalid Bezier degree/parameter"
    spline <-
        bSpline
            (length controls - 1)
            (replicate (length controls) 0 ++ replicate (length controls) 1)
            controls
            ws
    evaluateBSpline spline t

-- | Polynomial Bezier curve with unit weights; controls are vectors with 1..16 coordinates.
bezier :: [[Double]] -> Double -> Either MathError [Double]
bezier controls = rationalBezier controls (replicate (length controls) 1)

{- | Interpolating cubic Hermite segment sequence with Kochanek--Bartels
tension, continuity and bias in [-1,1]; endpoint secants are repeated.
-}
kochanekBartels ::
    Double -> Double -> Double -> [(Double, Double)] -> Either MathError PiecewisePolynomial
kochanekBartels tension continuity bias points = do
    (xs, ys) <- samples points
    require
        (length xs >= 2 && all (\x -> finite x && abs x <= 1) [tension, continuity, bias])
        "invalid Kochanek-Bartels parameters"
    let n = length xs
        s = zipWith (/) (zipWith (-) (drop 1 ys) ys) (zipWith (-) (drop 1 xs) xs)
        before i = s !! max 0 (i - 1)
        after i = s !! min (n - 2) i
        out i =
            (1 - tension)
                * ((1 + continuity) * (1 + bias) * before i + (1 - continuity) * (1 - bias) * after i)
                / 2
        incoming i =
            (1 - tension)
                * ((1 - continuity) * (1 + bias) * before i + (1 + continuity) * (1 - bias) * after i)
                / 2
    piecewisePolynomial
        xs
        [ let h = xs !! (i + 1) - xs !! i; sec = s !! i; a = out i; b = incoming (i + 1)
           in [ys !! i, a, (3 * sec - 2 * a - b) / h, (a + b - 2 * sec) / (h * h)]
        | i <- [0 .. n - 2]
        ]

-- | Kochanek--Bartels interpolation with zero continuity/bias and supplied tension in [-1,1].
cardinalSpline :: Double -> [(Double, Double)] -> Either MathError PiecewisePolynomial
cardinalSpline t = kochanekBartels t 0 0

-- | Cardinal cubic interpolation with zero tension and repeated endpoint secants.
catmullRom :: [(Double, Double)] -> Either MathError PiecewisePolynomial
catmullRom = cardinalSpline 0

-- | Componentwise adaptive integral of a B-spline between in-domain limits, with estimated quadrature errors.
curveIntegral :: C.Tolerance -> BSpline -> Double -> Double -> Either MathError [C.Estimate Double]
curveIntegral tolerance s@(BSpline _ _ controls _) a b = do
    _ <- evaluateBSpline s a
    _ <- evaluateBSpline s b
    mapM
        (\i -> C.adaptiveIntegrate tolerance (\t -> either (const (0 / 0)) (!! i) (evaluateBSpline s t)) a b)
        [0 .. length (controls !! 0) - 1]

-- | Adaptive integral of the Euclidean analytic derivative norm; limits must increase and remain in the spline domain.
arcLength :: C.Tolerance -> BSpline -> Double -> Double -> Either MathError (C.Estimate Double)
arcLength tolerance spline a b = do
    require (a <= b) "arc length limits must be ordered"
    _ <- evaluateBSpline spline a
    _ <- evaluateBSpline spline b
    C.adaptiveIntegrate tolerance (\t -> either (const (0 / 0)) norm (derivativeBSpline spline t)) a b

{- | Rectilinear multilinear interpolation; values are row-major/last axis fast.
Nearest uses Euclidean distance to grid nodes; extrapolation policy per axis.
-}
gridInterpolate ::
    InterpolationMethod ->
    Extrapolation ->
    [[Double]] ->
    [Double] ->
    [Double] ->
    Either MathError Double
gridInterpolate method policy axes values point = do
    let dims = map length axes; d = length axes
    require
        ( d > 0
            && d <= 16
            && length point == d
            && all (>= 2) dims
            && product (map toInteger dims) <= 1048576
            && product dims == length values
            && (method == Linear || method == Nearest)
        )
        "invalid grid interpolation shape/method"
    mapM_ (\a -> samples (zip a (repeat 0))) axes
    _ <- vector values
    p <- sequence (zipWith (pointPolicy policy) axes point)
    let intervals = [min (length a - 2) (max 0 (length (takeWhile (<= x) a) - 1)) | (a, x) <- zip axes p]
        ts = [(x - a !! i) / (a !! (i + 1) - a !! i) | (a, x, i) <- zip3 axes p intervals]
        strides = drop 1 (scanr (*) 1 dims)
        corner bits =
            let indices = zipWith (+) intervals bits
                weight = product (zipWith (\t bit -> if bit == 0 then 1 - t else t) ts bits)
             in weight * (values !! sum (zipWith (*) indices strides))
    if method == Nearest
        then
            checked
                (values !! sum (zipWith (*) (zipWith (\i t -> i + if t <= 0.5 then 0 else 1) intervals ts) strides))
        else checked (sum (map corner (sequence (replicate d [0, 1]))))

scattered :: [[Double]] -> [Double] -> Either MathError Int
scattered nodes ys = do
    let n = length nodes; d = if null nodes then 0 else length (nodes !! 0)
    require
        (n > 0 && n <= 1024 && length ys == n && d > 0 && d <= 16 && all ((== d) . length) nodes)
        "invalid scattered-data shape"
    _ <- vector (concat nodes ++ ys)
    require
        (and [nodes !! i /= nodes !! j | i <- [0 .. n - 1], j <- [0 .. i - 1]])
        "duplicate scattered nodes"
    Right d
distance :: [Double] -> [Double] -> Double
distance x y = norm (zipWith (-) x y)
kernel :: RadialKernel -> Double -> Double
kernel method r = case method of
    Gaussian e -> exp (-(e * r) ^ (2 :: Int))
    Multiquadric e -> sqrt (1 + (e * r) ^ (2 :: Int))
    InverseMultiquadric e -> 1 / sqrt (1 + (e * r) ^ (2 :: Int))
    ThinPlate -> if r == 0 then 0 else r * r * log r
    Cubic -> r * r * r

-- | Solve the augmented radial/affine system with nonnegative diagonal smoothing; singular or affinely degenerate systems fail.
fitRBF :: RadialKernel -> Double -> [[Double]] -> [Double] -> Either MathError RBF
fitRBF method smoothing nodes ys = do
    d <- scattered nodes ys
    require (finite smoothing && smoothing >= 0) "invalid RBF smoothing"
    case method of
        Gaussian e -> validScale e
        Multiquadric e -> validScale e
        InverseMultiquadric e -> validScale e
        _ -> Right ()
    let n = length nodes
        p = map (1 :) nodes
        a =
            [ [ kernel method (distance x y) + (if i == j then smoothing else 0) | (j, y) <- zip [0 :: Int ..] nodes
              ]
                ++ p !! i
            | (i, x) <- zip [0 :: Int ..] nodes
            ]
                ++ [row ++ replicate (d + 1) 0 | row <- tr p]
    coeffs <- solve a (ys ++ replicate (d + 1) 0)
    Right (RBF method nodes (take n coeffs) (drop n coeffs))
  where
    validScale e = require (finite e && e > 0) "RBF shape must be positive"

-- | Evaluate a fitted scattered model at one finite point with the original coordinate dimension.
evaluateRBF :: RBF -> [Double] -> Either MathError Double
evaluateRBF (RBF method nodes weights affine) x = do
    require (length x == length (nodes !! 0) && all finite x) "RBF query shape/nonfinite"
    checked
        (sum (zipWith (\w c -> w * kernel method (distance x c)) weights nodes) + dot affine (1 : x))

-- | Normalized inverse-distance interpolation with positive power; coincident queries return the exact observation.
inverseDistance :: Double -> [[Double]] -> [Double] -> [Double] -> Either MathError Double
inverseDistance power nodes ys point = do
    d <- scattered nodes ys
    require
        (finite power && power > 0 && length point == d && all finite point)
        "invalid inverse distance query/power"
    case lookup point (zip nodes ys) of
        Just y -> Right y
        Nothing ->
            let distances = map (distance point) nodes
                nearest = minimum distances
                weights = map (\r -> (nearest / r) ** power) distances
             in checked (dot weights ys / sum weights)

-- | Classical inverse-square Shepard interpolation in the supplied Euclidean coordinates.
shepard :: [[Double]] -> [Double] -> [Double] -> Either MathError Double
shepard = inverseDistance 2

{- | Ordinary kriging with stationary exponential covariance exp(-distance/range),
optional independent nugget, unbiased constant mean. Returns mean and variance.
-}
kriging ::
    Double -> Double -> [[Double]] -> [Double] -> [Double] -> Either MathError (Double, Double)
kriging range nugget nodes ys point = do
    d <- scattered nodes ys
    require
        (finite range && range > 0 && finite nugget && nugget >= 0 && length point == d && all finite point)
        "invalid kriging parameters/query"
    let n = length nodes
        c = map (\x -> exp (-distance x point / range)) nodes
        a =
            [ [exp (-distance x y / range) + (if i == j then nugget else 0) | (j, y) <- zip [0 :: Int ..] nodes]
                ++ [1]
            | (i, x) <- zip [0 :: Int ..] nodes
            ]
                ++ [replicate n 1 ++ [0]]
    w <- solve a (c ++ [1])
    mean <- checked (dot (take n w) ys)
    variance <- checked (1 - dot (take n w) c - last w)
    require (variance >= -1e-10) "kriging covariance produced negative variance"
    Right (mean, max 0 variance)

-- | Full-column-rank polynomial least squares via pivoted QR, returning ascending coefficients and maximum observation error.
polynomialFit :: Int -> [(Double, Double)] -> Either MathError Approximation
polynomialFit degree points = do
    (xs, ys) <- samples points
    require (degree >= 0 && degree <= 64 && degree < length xs) "invalid polynomial fit degree"
    design <-
        M.fromListChecked (length xs) (degree + 1) (concat [[x ^ j | j <- [0 .. degree]] | x <- xs])
    cs <- QR.leastSquares design ys
    err <- interpolationError (polyEval cs) points
    Right (Approximation cs err 1)

-- | Chebyshev-root interpolation on a finite interval; report maximum error on a separate 513-point uniform validation grid.
chebyshevApproximate ::
    Int -> (Double -> Double) -> Double -> Double -> Either MathError Approximation
chebyshevApproximate degree f a b = do
    require
        (degree >= 0 && degree <= 64 && finite a && finite b && a < b && finite (b - a))
        "invalid Chebyshev interval/degree"
    let n = degree + 1
        theta j = pi * (fromIntegral j + 0.5) / fromIntegral n
        xs = [a + (b - a) * (1 + cos (theta j)) / 2 | j <- [0 .. n - 1]]
    ys <- vector (map f xs)
    let cs =
            [ (if k == 0 then 1 else 2)
                / fromIntegral n
                * sum [ys !! j * cos (fromIntegral k * theta j) | j <- [0 .. n - 1]]
            | k <- [0 .. degree]
            ]
        grid = [a + (b - a) * fromIntegral j / 512 | j <- [0 .. 512 :: Int]]
    fitted <- mapM (evaluateChebyshev cs a b) grid
    _ <- vector grid
    truth <- vector (map f grid)
    Right (Approximation cs (maximum (map abs (zipWith (-) truth fitted))) n)

-- | Evaluate ascending Chebyshev coefficients after mapping the original interval to [-1,1].
evaluateChebyshev :: [Double] -> Double -> Double -> Double -> Either MathError Double
evaluateChebyshev cs a b x = do
    require (finite a && finite b && a < b && finite x && all finite cs) "invalid Chebyshev evaluation"
    let z = 2 * ((x - a) / (b - a)) - 1; ts = 1 : z : zipWith (\u v -> 2 * z * v - u) ts (drop 1 ts)
    checked (dot cs (take (length cs) ts))

-- | Padé [m/n] from ascending Taylor coefficients, q_0=1.
pade :: Int -> Int -> [Double] -> Either MathError ([Double], [Double])
pade m n series = do
    require
        (m >= 0 && n >= 0 && m + n <= 64 && length series >= m + n + 1 && all finite series)
        "invalid Pade orders/series"
    let a k = if k < 0 then 0 else series !! k
    qs <-
        if n == 0
            then Right []
            else solve [[a (m + i - j) | j <- [1 .. n]] | i <- [1 .. n]] [-a (m + i) | i <- [1 .. n]]
    let q = 1 : qs; p = [sum [q !! j * a (k - j) | j <- [0 .. min k n]] | k <- [0 .. m]]
    _ <- vector (p ++ q)
    Right (p, q)

{- | Linearized rational least squares y*q(x)-p(x)=0 with q_0=1;
poles at observations are rejected. Error is the actual rational residual.
-}
rationalFit :: Int -> Int -> [(Double, Double)] -> Either MathError ([Double], [Double], Double)
rationalFit m n points = do
    (xs, ys) <- samples points
    require (m >= 0 && n >= 0 && m + n <= 64 && length xs >= m + n + 1) "invalid rational fit degrees"
    a <-
        M.fromListChecked
            (length xs)
            (m + n + 1)
            (concat [[x ^ j | j <- [0 .. m]] ++ [-y * x ^ j | j <- [1 .. n]] | (x, y) <- points])
    cs <- QR.leastSquares a ys
    let p = take (m + 1) cs; q = 1 : drop (m + 1) cs
    require (all ((/= 0) . polyEval q) xs) "rational fit has an observation pole"
    err <- interpolationError (\x -> polyEval p x / polyEval q x) points
    Right (p, q, err)

{- | Discrete Remez exchange on an explicit dense grid, 1..64 degree. Success
requires alternating extrema and stable equioscillation; returned error is
the maximum on this grid only, not a certified continuous minimax bound.
-}
remez ::
    Int ->
    Int ->
    Double ->
    Int ->
    (Double -> Double) ->
    Double ->
    Double ->
    Either MathError Approximation
remez degree gridCount tolerance budget f a b = do
    require
        ( degree >= 0
            && degree <= 32
            && gridCount >= 8 * (degree + 2)
            && gridCount <= 65536
            && finite tolerance
            && tolerance > 0
            && budget > 0
            && finite a
            && finite b
            && a < b
            && finite (b - a)
        )
        "invalid Remez configuration"
    let grid = [a + (b - a) * fromIntegral j / fromIntegral (gridCount - 1) | j <- [0 .. gridCount - 1]]
    _ <- vector grid
    truth <- vector (map f grid)
    let initial =
            [ round
                ( (fromIntegral (gridCount - 1) :: Double)
                    * (1 - cos (pi * fromIntegral j / fromIntegral (degree + 1)))
                    / 2
                )
            | j <- [0 .. degree + 1]
            ]
        go iteration indices = do
            let rows =
                    [ [(grid !! i) ^ k | k <- [0 .. degree]] ++ [if even j then 1 else -1]
                    | (j, i) <- zip [0 :: Int ..] indices
                    ]
            cs <- solve rows [truth !! i | i <- indices]
            let p = take (degree + 1) cs
                err = [truth !! i - polyEval p (grid !! i) | i <- [0 .. gridCount - 1]]
                local =
                    0
                        : [ i
                          | i <- [1 .. gridCount - 2]
                          , abs (err !! i) >= abs (err !! (i - 1))
                          , abs (err !! i) >= abs (err !! (i + 1))
                          ]
                        ++ [gridCount - 1]
                alternate =
                    foldl
                        ( \acc i -> case reverse acc of
                            [] -> [i]
                            j : _ ->
                                if err !! i * err !! j > 0
                                    then if abs (err !! i) > abs (err !! j) then init acc ++ [i] else acc
                                    else acc ++ [i]
                        )
                        []
                        local
                trim is
                    | length is <= degree + 2 = is
                    | abs (err !! (is !! 0)) < abs (err !! last is) = trim (drop 1 is)
                    | otherwise = trim (init is)
                next = trim alternate
                maximumError = maximum (map abs err)
                ripple = abs (last cs)
            _ <- vector (p ++ err)
            if maximumError <= ripple + tolerance || maximumError <= tolerance
                then Right (Approximation p maximumError iteration)
                else
                    if iteration >= budget || length next < degree + 2
                        then Left (NonConvergence "Remez exchange" iteration)
                        else go (iteration + 1) next
    go 1 initial

{- | Damped Gauss--Newton least squares with central-difference Jacobian, strict
residual/step convergence and finite total callbacks; returns fitted parameters.
-}
nonlinearFit ::
    Int ->
    Double ->
    (Double -> [Double] -> Double) ->
    [(Double, Double)] ->
    [Double] ->
    Either MathError Approximation
nonlinearFit budget tolerance model points initial = do
    _ <- samples points
    require
        ( budget > 0
            && finite tolerance
            && tolerance > 0
            && not (null initial)
            && length initial <= 32
            && length points >= length initial
        )
        "invalid nonlinear fit"
    _ <- vector initial
    let residual ps = vector [y - model x ps | (x, y) <- points]
        go iteration damping ps = do
            r <- residual ps
            columns <-
                mapM
                    ( \j -> do
                        let h = 1e-5 * max 1 (abs (ps !! j))
                            plus = replace j (ps !! j + h) ps
                            minus = replace j (ps !! j - h) ps
                        _ <- vector (plus ++ minus)
                        vector [(model x plus - model x minus) / (2 * h) | (x, _) <- points]
                    )
                    [0 .. length ps - 1]
            let jac = tr columns
                jtj = mm columns jac
                a = zipWith (zipWith (+)) jtj (map (map (damping *)) (eye (length ps)))
            step <- solve a (mv columns r)
            next <- vector (zipWith (+) ps step)
            rr <- residual next
            let old = norm r; new = norm rr
            if old <= tolerance || new <= old && norm step <= tolerance * (1 + norm ps)
                then Right (Approximation (if old <= tolerance then ps else next) (min old new) iteration)
                else
                    if iteration >= budget
                        then Left (NonConvergence "nonlinear fit" iteration)
                        else
                            if new < old
                                then go (iteration + 1) (max 1e-15 (damping / 3)) next
                                else go (iteration + 1) (damping * 10) ps
    go 1 1e-3 initial

-- | Maximum absolute discrepancy at the supplied nonempty observations; nonfinite callback results fail.
interpolationError :: (Double -> Double) -> [(Double, Double)] -> Either MathError Double
interpolationError f points = do
    require (not (null points)) "error estimate needs observations"
    errors <- vector [abs (f x - y) | (x, y) <- points]
    Right (maximum errors)
