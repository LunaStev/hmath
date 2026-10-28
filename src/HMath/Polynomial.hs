-- SPDX-License-Identifier: MPL-2.0

{- | Univariate polynomials with ascending coefficients: @[a0,a1,...]@ means
@a0+a1*x+...@. Trailing exact zeros are removed; zero is @[]@ with degree
'Nothing'. Exact algorithms use Rational. Floating root solvers use Complex
Double with explicit tolerance and iteration budgets, returning failure when
residuals or corrections do not converge.
-}
module HMath.Polynomial (
    Polynomial,
    polynomial,
    coefficients,
    polynomialDegree,
    evaluatePolynomial,
    addPolynomial,
    subtractPolynomial,
    scalePolynomial,
    multiplyPolynomial,
    composePolynomial,
    dividePolynomial,
    monicPolynomial,
    gcdPolynomial,
    differentiatePolynomial,
    integratePolynomial,
    squareFreeFactors,
    rationalRoots,
    factorRationalPolynomial,
    sturmSequence,
    countRealRoots,
    isolateRealRoots,
    durandKerner,
    aberthEhrlich,
    companionMatrix,
    lagrangeInterpolation,
    newtonInterpolation,
    chebyshevPolynomial,
    legendrePolynomial,
    hermitePolynomial,
    laguerrePolynomial,
    bernsteinPolynomial,
    polynomialRegression,
    chebyshevApproximation,
    PowerSeries,
    powerSeries,
    seriesCoefficients,
    addSeries,
    multiplySeries,
    reciprocalSeries,
    divideSeries,
    composeSeries,
    differentiateSeries,
    integrateSeries,
    expSeries,
    logSeries,
    RationalFunction,
    rationalFunction,
    rationalNumerator,
    rationalDenominator,
    evaluateRationalFunction,
    addRationalFunction,
    multiplyRationalFunction,
    partialFractions,
) where

import Control.Monad (foldM)
import Data.Complex (Complex ((:+)), magnitude, mkPolar)
import Data.List (nub, sort)
import Data.Ratio (denominator, numerator, (%))
import HMath.Error (MathError (..))
import qualified HMath.Matrix as M
import HMath.Matrix.QR (leastSquares)
import HMath.NumberTheory (divisors)

-- | Canonical, finite ascending coefficient sequence.
newtype Polynomial a = Polynomial [a] deriving (Eq, Show)

-- | Construct a polynomial, deleting trailing exact zeros (no floating tolerance).
polynomial :: (Eq a, Num a) => [a] -> Polynomial a
polynomial = Polynomial . reverse . dropWhile (== 0) . reverse

-- | Ascending coefficients, with no trailing zero; zero gives an empty list.
coefficients :: Polynomial a -> [a]
coefficients (Polynomial xs) = xs

-- | Degree of a nonzero polynomial; zero has no degree.
polynomialDegree :: Polynomial a -> Maybe Int
polynomialDegree (Polynomial []) = Nothing
polynomialDegree (Polynomial xs) = Just (length xs - 1)

-- | Horner evaluation, with the constant coefficient first in storage.
evaluatePolynomial :: (Num a) => Polynomial a -> a -> a
evaluatePolynomial (Polynomial xs) x = foldr (\a b -> a + x * b) 0 xs

zipPad :: (Num a) => (a -> a -> a) -> [a] -> [a] -> [a]
zipPad f [] ys = map (f 0) ys
zipPad f xs [] = map (`f` 0) xs
zipPad f (x : xs) (y : ys) = f x y : zipPad f xs ys

-- | Coefficientwise addition with canonical exact-zero normalization.
addPolynomial :: (Eq a, Num a) => Polynomial a -> Polynomial a -> Polynomial a
addPolynomial (Polynomial a) (Polynomial b) = polynomial (zipPad (+) a b)

-- | Coefficientwise subtraction.
subtractPolynomial :: (Eq a, Num a) => Polynomial a -> Polynomial a -> Polynomial a
subtractPolynomial (Polynomial a) (Polynomial b) = polynomial (zipPad (-) a b)

-- | Multiply every coefficient by a scalar.
scalePolynomial :: (Eq a, Num a) => a -> Polynomial a -> Polynomial a
scalePolynomial a (Polynomial xs) = polynomial (map (a *) xs)

-- | Exact schoolbook convolution, including zero polynomials.
multiplyPolynomial :: (Eq a, Num a) => Polynomial a -> Polynomial a -> Polynomial a
multiplyPolynomial (Polynomial a) (Polynomial b) = polynomial (go a)
  where
    go [] = []
    go (x : xs) = zipPad (+) (map (x *) b) (0 : go xs)

-- | Composition @p(q(x))@ by polynomial Horner evaluation.
composePolynomial :: (Eq a, Num a) => Polynomial a -> Polynomial a -> Polynomial a
composePolynomial (Polynomial xs) q =
    foldr
        ( \a r ->
            addPolynomial
                (polynomial [a])
                (multiplyPolynomial q r)
        )
        (polynomial [])
        xs

{- | Long division over a field. Exact coefficient equality controls termination;
numerical cancellation is truncated at the eliminated leading coefficient.
Zero denominator is rejected.
-}
dividePolynomial ::
    (Eq a, Fractional a) =>
    Polynomial a ->
    Polynomial a ->
    Either MathError (Polynomial a, Polynomial a)
dividePolynomial _ (Polynomial []) = Left (DomainError "zero polynomial divisor")
dividePolynomial (Polynomial xs) (Polynomial ys) = Right (go xs (polynomial []))
  where
    n = length ys
    lead = foldl (\_ x -> x) 0 ys
    go r q
        | length r < n = (q, polynomial r)
        | otherwise =
            let k = length r - n
                a = foldl (\_ x -> x) 0 r / lead
                term = polynomial (replicate k 0 ++ [a])
                eliminated = zipPad (-) r (replicate k 0 ++ map (a *) ys)
                lower = polynomial (take (length r - 1) eliminated)
             in go (coefficients lower) (addPolynomial q term)

-- | Normalize a nonzero polynomial to leading coefficient one; zero remains zero.
monicPolynomial :: (Eq a, Fractional a) => Polynomial a -> Polynomial a
monicPolynomial p@(Polynomial []) = p
monicPolynomial p@(Polynomial xs) = scalePolynomial (recip (foldl (\_ a -> a) 0 xs)) p

-- | Monic Euclidean GCD over an exact field; @gcd(0,0)=0@.
gcdPolynomial :: (Eq a, Fractional a) => Polynomial a -> Polynomial a -> Polynomial a
gcdPolynomial a (Polynomial []) = monicPolynomial a
gcdPolynomial a b = case dividePolynomial a b of
    Right (_, r) -> gcdPolynomial b r
    Left _ -> monicPolynomial a

-- | Formal derivative.
differentiatePolynomial :: (Eq a, Num a) => Polynomial a -> Polynomial a
differentiatePolynomial (Polynomial xs) = polynomial (zipWith (\i a -> fromInteger i * a) [1 ..] (drop 1 xs))

-- | Formal integral with the supplied integration constant.
integratePolynomial :: (Eq a, Fractional a) => a -> Polynomial a -> Polynomial a
integratePolynomial c (Polynomial xs) = polynomial (c : zipWith (\i a -> a / fromInteger i) [1 ..] xs)

{- | Monic square-free factors with positive multiplicities over Rational.
The leading coefficient is omitted; constant polynomials have no factors.
-}
squareFreeFactors :: Polynomial Rational -> [(Polynomial Rational, Int)]
squareFreeFactors p
    | deg p <= 0 = []
    | otherwise = go 1 w c
  where
    f = monicPolynomial p
    c = gcdPolynomial f (differentiatePolynomial f)
    w = quotient f c
    go i a b
        | deg a <= 0 = []
        | otherwise =
            let y = gcdPolynomial a b; z = quotient a y
             in (if deg z > 0 then [(z, i)] else []) ++ go (i + 1) y (quotient b y)

deg :: Polynomial a -> Int
deg p = maybe (-1) id (polynomialDegree p)

quotient :: (Eq a, Fractional a) => Polynomial a -> Polynomial a -> Polynomial a
quotient a b = either (const (polynomial [])) fst (dividePolynomial a b)

{- | Rational roots with exact multiplicities using the rational-root theorem.
Budget applies to integer factorization of numerator and leading coefficient.
-}
rationalRoots :: Int -> Polynomial Rational -> Either MathError [(Rational, Int)]
rationalRoots budget p
    | budget < 0 = Left (InvalidArgument "negative rational-root budget")
    | deg p < 0 = Left (DomainError "zero polynomial has infinitely many roots")
    | deg p == 0 = Right []
    | otherwise = do
        let xs = integerCoefficients p
            zeroCount = length (takeWhile (== 0) xs)
            rest = drop zeroCount xs
            c = case rest of a : _ -> abs a; [] -> 1
            l = abs (foldl (\_ a -> a) 1 rest)
        ns <- divisors budget c
        ds <- divisors budget l
        let candidates = nub [sign * n % d | sign <- [-1, 1], n <- ns, d <- ds]
            multiplicity r q k
                | deg q > 0 && evaluatePolynomial q r == 0 =
                    multiplicity r (quotient q (polynomial [-r, 1])) (k + 1)
                | otherwise = k
        pure
            ( (if zeroCount > 0 then [(0, zeroCount)] else [])
                ++ [(r, k) | r <- sort candidates, let k = multiplicity r p 0, k > 0]
            )

integerCoefficients :: Polynomial Rational -> [Integer]
integerCoefficients p =
    let xs = coefficients p
        den = foldl lcm 1 (map denominator xs)
        ints = map (\a -> numerator (a * fromInteger den)) xs
        g = foldl gcd 0 ints
     in if g == 0 then [] else map (`div` g) ints

{- | Complete rational factorization by bounded Kronecker interpolation. Returns
the original leading scalar and monic irreducible factors with multiplicity.
Every candidate is divided exactly. Exhausting the candidate budget reports
failure, never an unsupported claim of irreducibility. Intended for small
exact polynomials; coefficient divisor enumeration also uses this budget.
-}
factorRationalPolynomial ::
    Int ->
    Polynomial Rational ->
    Either MathError (Rational, [(Polynomial Rational, Int)])
factorRationalPolynomial budget p
    | budget < 0 = Left (InvalidArgument "negative factorization budget")
    | deg p < 0 = Left (DomainError "zero polynomial cannot be factored")
    | otherwise = do
        let leading = foldl (\_ x -> x) 0 (coefficients p)
        (fs, _) <- factor budget (monicPolynomial p)
        pure (leading, combineFactors fs)
  where
    combineFactors [] = []
    combineFactors (f : fs) = (f, 1 + length (filter (== f) fs)) : combineFactors (filter (/= f) fs)
    factor left f
        | deg f <= 0 = Right ([], left)
        | deg f == 1 = Right ([f], left)
        | otherwise = do
            found <- findFactor left f 1
            case found of
                (Nothing, remain) -> Right ([f], remain)
                (Just g, remain) -> do
                    (a, l) <- factor remain (monicPolynomial g)
                    (b, r) <- factor l (monicPolynomial (quotient f g))
                    pure (a ++ b, r)
    findFactor left f k
        | k > deg f `div` 2 = Right (Nothing, left)
        | otherwise = do
            let ints = polynomial (map fromInteger (integerCoefficients f))
                samplePoints = take (k + 1) [x | x <- 0 : concat [[j, -j] | j <- [1 ..]], evaluatePolynomial ints x /= 0]
            values <- mapM (\x -> divisors budget (abs (numerator (evaluatePolynomial ints x)))) samplePoints
            let choices = map (\ds -> concatMap (\d -> [fromInteger d, fromInteger (-d)]) ds) values
            attempt left (sequence choices)
      where
        points =
            take
                (k + 1)
                [ x
                | x <- 0 : concat [[j, -j] | j <- [1 ..]]
                , evaluatePolynomial (polynomial (map fromInteger (integerCoefficients f))) x /= 0
                ]
        attempt remain [] = findFactor remain f (k + 1)
        attempt 0 _ = Left (NonConvergence "Kronecker factorization" budget)
        attempt remain (ys : rest) = do
            g <- lagrangeInterpolation (zip points ys)
            if deg g > 0 && deg g <= k && all ((== 1) . denominator) (coefficients g)
                then do
                    (_, r) <- dividePolynomial f g
                    if deg r < 0 then Right (Just g, remain - 1) else attempt (remain - 1) rest
                else attempt (remain - 1) rest

{- | Sturm chain over exact rationals, after removing the derivative GCD.
Zero polynomial is invalid. Square-free normalization ensures a repeated root
cannot make every chain member vanish and destroy one-sided variation counts.
-}
sturmSequence :: Polynomial Rational -> Either MathError [Polynomial Rational]
sturmSequence p
    | deg p < 0 = Left (DomainError "Sturm chain of zero polynomial")
    | deg p == 0 = Right [p]
    | otherwise = Right (squareFree : go squareFree (differentiatePolynomial squareFree))
  where
    squareFree = quotient p (gcdPolynomial p (differentiatePolynomial p))
    go a b
        | deg b < 0 = []
        | otherwise =
            b : case dividePolynomial a b of
                Right (_, r) -> go b (scalePolynomial (-1) r)
                Left _ -> []

variations :: [Rational] -> Int
variations xs = length [() | (a, b) <- zip nz (drop 1 nz), signum a /= signum b]
  where
    nz = filter (/= 0) xs

{- | Number of distinct real roots in @(a,b]@. Endpoints that are roots of the
polynomial are rejected to make the interval convention unambiguous.
-}
countRealRoots :: Polynomial Rational -> Rational -> Rational -> Either MathError Int
countRealRoots p a b
    | a >= b = Left (InvalidArgument "root-count interval must increase")
    | evaluatePolynomial p a == 0 || evaluatePolynomial p b == 0 =
        Left (DomainError "root-count endpoint is a root")
    | otherwise = do
        chain <- sturmSequence p
        pure
            ( variations (map (`evaluatePolynomial` a) chain)
                - variations (map (`evaluatePolynomial` b) chain)
            )

{- | Isolate every distinct real root in rational intervals with disjoint interiors and width
at most tolerance. Intervals have the root-count convention (a,b]; shared endpoints
belong to the interval on their left.
Bisection budget bounds visited intervals; all arithmetic is exact.
-}
isolateRealRoots ::
    Int ->
    Rational ->
    Polynomial Rational ->
    Either MathError [(Rational, Rational)]
isolateRealRoots budget tolerance p
    | budget < 0 = Left (InvalidArgument "negative isolation budget")
    | tolerance <= 0 = Left InvalidTolerance
    | deg p < 0 = Left (DomainError "zero polynomial has infinitely many roots")
    | deg p == 0 = Right []
    | otherwise = do
        let f = monicPolynomial p
            bound = 1 + maximum (0 : map abs (take (deg f) (coefficients f)))
        chain <- sturmSequence f
        fst <$> split chain budget (-bound) bound
  where
    var chain x = variations (map (`evaluatePolynomial` x) chain)
    split _ 0 _ _ = Left (NonConvergence "Sturm isolation" budget)
    split chain left a b
        | count == 0 = Right ([], left - 1)
        | count == 1 && b - a <= tolerance = Right ([(a, b)], left - 1)
        | otherwise = do
            let mid = (a + b) / 2
            (lo, l) <- split chain (left - 1) a mid
            (hi, r) <- split chain l mid b
            pure (lo ++ hi, r)
      where
        count = var chain a - var chain b

{- | Durand--Kerner simultaneous complex root iteration. Distinct initial roots
are placed on a Cauchy-bound circle; repeated roots may converge slowly.
-}
durandKerner ::
    Int ->
    Double ->
    Polynomial (Complex Double) ->
    Either MathError [Complex Double]
durandKerner = complexRoots False

{- | Aberth--Ehrlich simultaneous iteration, combining Newton corrections with
mutual-root repulsion. All roots are verified against a scaled residual.
-}
aberthEhrlich ::
    Int ->
    Double ->
    Polynomial (Complex Double) ->
    Either MathError [Complex Double]
aberthEhrlich = complexRoots True

complexRoots ::
    Bool ->
    Int ->
    Double ->
    Polynomial (Complex Double) ->
    Either MathError [Complex Double]
complexRoots useAberth budget tolerance p
    | budget < 0 = Left (InvalidArgument "negative root iteration budget")
    | tolerance <= 0 || isNaN tolerance || isInfinite tolerance = Left InvalidTolerance
    | any (not . finiteComplex) (coefficients p) = Left NonFiniteResult
    | deg p < 0 = Left (DomainError "zero polynomial has infinitely many roots")
    | deg p == 0 = Right []
    | any (not . finiteComplex) (coefficients f) = Left NonFiniteResult
    | otherwise = go budget initial
  where
    f = monicPolynomial p
    n = deg f
    df = differentiatePolynomial f
    radius = 1 + maximum (0 : map magnitude (take n (coefficients f)))
    initial = [mkPolar radius (2 * pi * (fromIntegral k + 0.271828) / fromIntegral n) | k <- [0 .. n - 1]]
    residual z =
        let coefficientScale = maximum (1 : map magnitude (coefficients f))
            scaled = map (/ (coefficientScale :+ 0)) (coefficients f)
            reverseEvaluation = magnitude z > 1
            point = if reverseEvaluation then 1 / z else z
            cs = if reverseEvaluation then reverse scaled else scaled
            value = magnitude (evaluatePolynomial (polynomial cs) point)
            bound = foldr (\a b -> magnitude a + magnitude point * b) 0 cs
         in all (\x -> not (isNaN x || isInfinite x)) [value, bound] && value <= tolerance * bound
    go _ zs | all residual zs = Right zs
    go 0 _ = Left (NonConvergence (if useAberth then "Aberth-Ehrlich" else "Durand-Kerner") budget)
    go left zs = do
        next <- mapM (update zs) (zip [0 ..] zs)
        if all finiteComplex next then go (left - 1) next else Left NonFiniteResult
    update zs (i, z) =
        let others = [w | (j, w) <- zip ([0 ..] :: [Int]) zs, j /= i]
            value = evaluatePolynomial f z
            denom =
                if useAberth
                    then
                        evaluatePolynomial df z
                            - value * sum [1 / (z - w) | w <- others]
                    else product [z - w | w <- others]
         in if denom == 0
                then Left (NonConvergence "colliding polynomial roots" budget)
                else Right (z - value / denom)

finiteComplex :: Complex Double -> Bool
finiteComplex (a :+ b) = all (\x -> not (isNaN x || isInfinite x)) [a, b]

{- | Frobenius companion matrix of a nonconstant polynomial, with ones on the
subdiagonal and negated monic coefficients in the last column.
-}
companionMatrix :: (Eq a, Fractional a) => Polynomial a -> Either MathError (M.Matrix a)
companionMatrix p
    | deg p <= 0 = Left (DomainError "companion matrix needs positive degree")
    | otherwise =
        M.fromListChecked
            n
            n
            [entry i j | i <- [0 .. n - 1], j <- [0 .. n - 1]]
  where
    n = deg p
    cs = coefficients (monicPolynomial p)
    entry i j
        | j == n - 1 = -(sum (take 1 (drop i cs)))
        | i == j + 1 = 1
        | otherwise = 0

-- | Exact Lagrange interpolating polynomial. Duplicate nodes are rejected.
lagrangeInterpolation :: (Eq a, Fractional a) => [(a, a)] -> Either MathError (Polynomial a)
lagrangeInterpolation points
    | length (nub (map fst points)) /= length points =
        Left (DomainError "duplicate interpolation nodes")
    | otherwise =
        Right
            ( foldl
                addPolynomial
                (polynomial [])
                [ scalePolynomial
                    (y / product [x - z | (j, (z, _)) <- indexed, j /= i])
                    ( foldl
                        multiplyPolynomial
                        (polynomial [1])
                        [polynomial [-z, 1] | (j, (z, _)) <- indexed, j /= i]
                    )
                | (i, (x, y)) <- indexed
                ]
            )
  where
    indexed = zip ([0 ..] :: [Int]) points

-- | Newton divided differences, returned in the standard power basis.
newtonInterpolation :: (Eq a, Fractional a) => [(a, a)] -> Either MathError (Polynomial a)
newtonInterpolation points
    | length (nub xs) /= length xs = Left (DomainError "duplicate interpolation nodes")
    | otherwise = Right (go 0 (map snd points) (polynomial [1]) (polynomial []))
  where
    xs = map fst points
    go _ [] _ acc = acc
    go k ys basis acc =
        let lead = sum (take 1 ys)
            result = addPolynomial acc (scalePolynomial lead basis)
            next = zipWith3 (\a b (x, z) -> (b - a) / (z - x)) ys (drop 1 ys) (zip xs (drop (k + 1) xs))
            node = sum (take 1 (drop k xs))
         in go (k + 1) next (multiplyPolynomial basis (polynomial [-node, 1])) result

orthogonal ::
    (Fractional a) =>
    Int ->
    (Int -> Polynomial a -> Polynomial a -> Polynomial a) ->
    Polynomial a ->
    Polynomial a ->
    Either MathError (Polynomial a)
orthogonal n step p0 p1
    | n < 0 = Left (DomainError "negative polynomial degree")
    | n == 0 = Right p0
    | otherwise = Right (go 1 p0 p1)
  where
    go k a b
        | k == n = b
        | otherwise = go (k + 1) b (step k a b)

-- | Chebyshev T_n, normalized by T_0=1, T_1=x.
chebyshevPolynomial :: (Eq a, Fractional a) => Int -> Either MathError (Polynomial a)
chebyshevPolynomial n =
    orthogonal
        n
        ( \_ a b ->
            subtractPolynomial
                (multiplyPolynomial (polynomial [0, 2]) b)
                a
        )
        (polynomial [1])
        (polynomial [0, 1])

-- | Legendre P_n, normalized by P_n(1)=1.
legendrePolynomial :: (Eq a, Fractional a) => Int -> Either MathError (Polynomial a)
legendrePolynomial n =
    orthogonal
        n
        ( \k a b ->
            scalePolynomial
                (1 / fromIntegral (k + 1))
                ( subtractPolynomial
                    (multiplyPolynomial (polynomial [0, fromIntegral (2 * k + 1)]) b)
                    (scalePolynomial (fromIntegral k) a)
                )
        )
        (polynomial [1])
        (polynomial [0, 1])

-- | Physicists' Hermite H_n: H_0=1, H_1=2x.
hermitePolynomial :: (Eq a, Fractional a) => Int -> Either MathError (Polynomial a)
hermitePolynomial n =
    orthogonal
        n
        ( \k a b ->
            subtractPolynomial
                (multiplyPolynomial (polynomial [0, 2]) b)
                (scalePolynomial (fromIntegral (2 * k)) a)
        )
        (polynomial [1])
        (polynomial [0, 2])

-- | Ordinary Laguerre L_n with alpha=0 and L_n(0)=1.
laguerrePolynomial :: (Eq a, Fractional a) => Int -> Either MathError (Polynomial a)
laguerrePolynomial n =
    orthogonal
        n
        ( \k a b ->
            scalePolynomial
                (1 / fromIntegral (k + 1))
                ( subtractPolynomial
                    (multiplyPolynomial (polynomial [fromIntegral (2 * k + 1), -1]) b)
                    (scalePolynomial (fromIntegral k) a)
                )
        )
        (polynomial [1])
        (polynomial [1, -1])

-- | Bernstein basis @binomial(n,k)*x^k*(1-x)^(n-k)@ for 0<=k<=n.
bernsteinPolynomial :: (Eq a, Fractional a) => Int -> Int -> Either MathError (Polynomial a)
bernsteinPolynomial n k
    | n < 0 || k < 0 || k > n = Left (DomainError "invalid Bernstein indices")
    | otherwise =
        Right
            ( scalePolynomial
                (fromInteger choose)
                ( multiplyPolynomial
                    (polynomial (replicate k 0 ++ [1]))
                    (power (polynomial [1, -1]) (n - k))
                )
            )
  where
    choose = product [toInteger (n - k + 1) .. toInteger n] `div` product [1 .. toInteger k]
    power p j = foldl multiplyPolynomial (polynomial [1]) (replicate j p)

{- | Least-squares power-basis regression using column-pivoted Householder QR.
Degree must be nonnegative; undersampling, nonfinite data and rank deficiency
are reported by the checked design-matrix solver.
-}
polynomialRegression :: (RealFloat a) => Int -> [(a, a)] -> Either MathError (Polynomial a)
polynomialRegression degree points
    | degree < 0 = Left (DomainError "negative regression degree")
    | degree == maxBound = Left (InvalidArgument "regression degree too large")
    | otherwise = do
        matrix <-
            M.fromListChecked
                (length points)
                (degree + 1)
                (concatMap (take (degree + 1) . iterateMultiply . fst) points)
        polynomial <$> leastSquares matrix (map snd points)
  where
    iterateMultiply x = iterate (* x) 1

{- | Truncated Chebyshev interpolation at first-kind nodes on [-1,1], returned
in power basis. Uses degree+1 evaluations; nonfinite values are rejected.
-}
chebyshevApproximation :: Int -> (Double -> Double) -> Either MathError (Polynomial Double)
chebyshevApproximation degree f
    | degree < 0 || degree == maxBound = Left (DomainError "invalid approximation degree")
    | any (\x -> isNaN x || isInfinite x) ys = Left NonFiniteResult
    | otherwise = do
        basis <- mapM chebyshevPolynomial [0 .. degree]
        pure (foldl addPolynomial (polynomial []) (zipWith scalePolynomial weights basis))
  where
    n = degree + 1
    angles = [pi * (fromIntegral j + 0.5) / fromIntegral n | j <- [0 .. degree]]
    ys = map (f . cos) angles
    weights =
        [ (if k == 0 then 1 else 2)
            / fromIntegral n
            * sum (zipWith (\y theta -> y * cos (fromIntegral k * theta)) ys angles)
        | k <- [0 .. degree]
        ]

{- | A finite Taylor jet, coefficients ascending and zeros retained. Its length
is the truncation order; operations preserve the shorter operand's order.
-}
newtype PowerSeries a = PowerSeries [a] deriving (Eq, Show)

-- | Construct a jet with explicit coefficients, including trailing zeros.
powerSeries :: [a] -> PowerSeries a
powerSeries = PowerSeries

-- | Stored Taylor coefficients; coefficient n multiplies x^n, not x^n/n!.
seriesCoefficients :: PowerSeries a -> [a]
seriesCoefficients (PowerSeries xs) = xs

-- | Add jets to their common truncation order.
addSeries :: (Num a) => PowerSeries a -> PowerSeries a -> PowerSeries a
addSeries (PowerSeries a) (PowerSeries b) = PowerSeries (zipWith (+) a b)

-- | Multiply jets by truncated convolution.
multiplySeries :: (Num a) => PowerSeries a -> PowerSeries a -> PowerSeries a
multiplySeries (PowerSeries a) (PowerSeries b) =
    PowerSeries
        [ sum (zipWith (*) (take (k + 1) a) (reverse (take (k + 1) b)))
        | k <- [0 .. min (length a) (length b) - 1]
        ]

-- | Reciprocal jet from coefficient recurrence; constant term must be nonzero.
reciprocalSeries :: (Eq a, Fractional a) => PowerSeries a -> Either MathError (PowerSeries a)
reciprocalSeries (PowerSeries []) = Left (DomainError "empty reciprocal series")
reciprocalSeries (PowerSeries (a : as))
    | a == 0 = Left (DomainError "zero constant reciprocal series")
    | otherwise = Right (PowerSeries result)
  where
    result = 1 / a : [-sum (zipWith (*) (take k as) (reverse (take k result))) / a | k <- [1 .. length as]]

-- | Divide jets to their common order; denominator constant must be nonzero.
divideSeries ::
    (Eq a, Fractional a) => PowerSeries a -> PowerSeries a -> Either MathError (PowerSeries a)
divideSeries a b = multiplySeries a <$> reciprocalSeries b

{- | Formal composition to the inner jet's order. Inner constant must be zero,
so unknown higher outer coefficients cannot affect the returned jet.
-}
composeSeries :: (Eq a, Num a) => PowerSeries a -> PowerSeries a -> Either MathError (PowerSeries a)
composeSeries (PowerSeries outer) inner@(PowerSeries xs)
    | any (/= 0) (take 1 xs) = Left (DomainError "formal composition needs zero inner constant")
    | length outer < length xs = Left (InvalidArgument "outer jet order is too short")
    | otherwise = Right (foldr step (PowerSeries (replicate (length xs) 0)) (take (length xs) outer))
  where
    step a acc = addSeries (PowerSeries (a : replicate (max 0 (length xs - 1)) 0)) (multiplySeries inner acc)

-- | Derivative jet has one fewer coefficient.
differentiateSeries :: (Num a) => PowerSeries a -> PowerSeries a
differentiateSeries (PowerSeries xs) = PowerSeries (zipWith (\k a -> fromInteger k * a) [1 ..] (drop 1 xs))

-- | Integral jet with supplied constant, one coefficient longer.
integrateSeries :: (Fractional a) => a -> PowerSeries a -> PowerSeries a
integrateSeries c (PowerSeries xs) = PowerSeries (c : zipWith (\k a -> a / fromInteger k) [1 ..] xs)

{- | Exponential of a finite jet from b'=a'b; constant uses the coefficient
type's exp. The output has the same truncation order.
-}
expSeries :: (Floating a) => PowerSeries a -> PowerSeries a
expSeries (PowerSeries []) = PowerSeries []
expSeries (PowerSeries (a : as)) = PowerSeries bs
  where
    bs =
        exp a
            : [ sum
                    [ fromIntegral k * ak * bj
                    | (k, ak) <- zip [1 .. n] (take n as)
                    , let bj = sum (take 1 (drop (n - k) bs))
                    ]
                    / fromIntegral n
              | n <- [1 .. length as]
              ]

{- | Formal log through derivative/division/integration. Requires positive real
constant term, with exact truncation matching the input jet.
-}
logSeries :: (Ord a, Floating a) => PowerSeries a -> Either MathError (PowerSeries a)
logSeries (PowerSeries []) = Left (DomainError "empty logarithm series")
logSeries a@(PowerSeries (c : _))
    | c <= 0 = Left (DomainError "log series needs positive constant")
    | otherwise = do
        inv <- reciprocalSeries a
        let deriv = differentiateSeries a
            ratio = multiplySeries deriv inv
        pure (integrateSeries (log c) ratio)

-- | Reduced exact rational function with monic denominator.
data RationalFunction = RationalFunction (Polynomial Rational) (Polynomial Rational)
    deriving (Eq, Show)

-- | Normalize by polynomial GCD and reject a zero denominator.
rationalFunction :: Polynomial Rational -> Polynomial Rational -> Either MathError RationalFunction
rationalFunction p q
    | deg q < 0 = Left (DomainError "zero rational-function denominator")
    | otherwise =
        let g = gcdPolynomial p q
            a = quotient p g
            b = quotient q g
            lead = foldl (\_ x -> x) 1 (coefficients b)
         in Right (RationalFunction (scalePolynomial (1 / lead) a) (monicPolynomial b))

-- | Reduced numerator.
rationalNumerator :: RationalFunction -> Polynomial Rational
rationalNumerator (RationalFunction p _) = p

-- | Monic reduced denominator.
rationalDenominator :: RationalFunction -> Polynomial Rational
rationalDenominator (RationalFunction _ q) = q

-- | Exact evaluation, rejecting poles.
evaluateRationalFunction :: RationalFunction -> Rational -> Either MathError Rational
evaluateRationalFunction (RationalFunction p q) x
    | den == 0 = Left (DomainError "rational-function pole")
    | otherwise = Right (evaluatePolynomial p x / den)
  where
    den = evaluatePolynomial q x

-- | Exact rational-function addition with cancellation.
addRationalFunction :: RationalFunction -> RationalFunction -> Either MathError RationalFunction
addRationalFunction (RationalFunction a b) (RationalFunction c d) =
    rationalFunction
        (addPolynomial (multiplyPolynomial a d) (multiplyPolynomial c b))
        (multiplyPolynomial b d)

-- | Exact rational-function multiplication with cancellation.
multiplyRationalFunction ::
    RationalFunction -> RationalFunction -> Either MathError RationalFunction
multiplyRationalFunction (RationalFunction a b) (RationalFunction c d) =
    rationalFunction (multiplyPolynomial a c) (multiplyPolynomial b d)

{- | Exact partial fractions over Q. Each term is @(numerator,monic irreducible
denominator,power)@ and numerator degree is smaller than denominator degree.
Supports repeated and nonlinear factors. Kronecker factorization and linear
elimination are bounded by the supplied candidate budget.
-}
partialFractions ::
    Int ->
    RationalFunction ->
    Either MathError (Polynomial Rational, [(Polynomial Rational, Polynomial Rational, Int)])
partialFractions budget (RationalFunction p q) = do
    (whole, remainder) <- dividePolynomial p q
    (_, factors) <- factorRationalPolynomial budget q
    let basis = [(f, k, j, quotient q (power f k)) | (f, m) <- factors, k <- [1 .. m], j <- [0 .. deg f - 1]]
        columns = [coefficients (multiplyPolynomial (polynomial (replicate j 0 ++ [1])) b) | (_, _, j, b) <- basis]
        n = deg q
        rows =
            [ [sum (take 1 (drop i col)) | col <- columns] ++ [sum (take 1 (drop i (coefficients remainder)))]
            | i <- [0 .. n - 1]
            ]
    values <- gaussian rows
    let result = [(polynomial [valueFor f k j | j <- [0 .. deg f - 1]], f, k) | (f, m) <- factors, k <- [1 .. m]]
        valueFor f k j = sum [v | ((g, l, h, _), v) <- zip basis values, g == f, l == k, h == j]
    pure (whole, filter (\(a, _, _) -> deg a >= 0) result)
  where
    power f k = foldl multiplyPolynomial (polynomial [1]) (replicate k f)

gaussian :: [[Rational]] -> Either MathError [Rational]
gaussian [] = Right []
gaussian rows = do
    reduced <- foldM eliminate rows [0 .. length rows - 1]
    pure [sum (take 1 (drop (length rows) row)) | row <- reduced]
  where
    eliminate rs k = case [(i, row) | (i, row) <- zip [0 ..] rs, i >= k, sum (take 1 (drop k row)) /= 0] of
        [] -> Left (SingularMatrix k)
        (i, pivot) : _ ->
            let chosen = [if j == k then pivot else if j == i then atRow k rs else row | (j, row) <- zip [0 ..] rs]
                val = sum (take 1 (drop k pivot))
                normalized = map (/ val) pivot
             in Right
                    [ if j == k
                        then normalized
                        else
                            zipWith
                                (-)
                                row
                                (map (* (sum (take 1 (drop k row)))) normalized)
                    | (j, row) <- zip [0 ..] chosen
                    ]
    atRow k rs = concat (take 1 (drop k rs))
