{-# LANGUAGE ForeignFunctionInterface #-}

-- SPDX-License-Identifier: MPL-2.0

{- | Real special functions with checked domains. 'SFResult' reports an
/estimated/ absolute truncation/rounding error, never an interval certificate.
Series and quadrature have finite work budgets and reject nonconvergence.
Complex hypergeometric functions use principal powers and their power-series
disk; no unspecified continuation across a branch cut is performed.
Equations and normalization: https://dlmf.nist.gov/ (chapters 5--33).
The C99 libm gamma/error/Bessel entry points are used as platform elementary
kernels. They do not change the process error handler or floating-point mode.
-}
module HMath.Special (
    SFResult (..),
    gamma,
    logGamma,
    gammaP,
    gammaQ,
    incompleteGamma,
    beta,
    logBeta,
    betaI,
    incompleteBeta,
    digamma,
    trigamma,
    polygamma,
    erf,
    erfc,
    inverseErf,
    erfcx,
    normalCDF,
    normalQuantile,
    dawson,
    exponentialIntegral,
    logarithmicIntegral,
    sineIntegral,
    cosineIntegral,
    fresnel,
    ellipticF,
    ellipticE,
    ellipticPi,
    jacobiElliptic,
    besselJ,
    besselY,
    besselI,
    besselK,
    sphericalBesselJ,
    sphericalBesselY,
    hankel,
    airy,
    struve,
    hypergeometric,
    hypergeometric1F1,
    hypergeometric2F1,
    complex1F1,
    legendre,
    associatedLegendre,
    sphericalHarmonic,
    riemannZeta,
    hurwitzZeta,
    polylogarithm,
    dilogarithm,
    lambertW,
    debye,
    clausen,
    fermiDirac,
    boseEinstein,
    coulombWave,
    gegenbauer,
    parabolicCylinder,
    mathieu,
    bernoulliPolynomial,
    eulerPolynomial,
    wigner3j,
    wigner6j,
    wigner9j,
    clebschGordan,
    scaledBesselI,
    scaledBesselK,
) where

import Data.Complex hiding (phase)
import qualified Data.Foldable as Foldable (foldl')
import Foreign.C.Types
import HMath.Error
import HMath.Matrix (fromListChecked, toList)
import HMath.Matrix.LAPACK (eigenvalues, eigenvectors, symmetricEigen)

foreign import ccall unsafe "tgamma" cGamma :: CDouble -> CDouble
foreign import ccall unsafe "lgamma" cLogGamma :: CDouble -> CDouble
foreign import ccall unsafe "erf" cErf :: CDouble -> CDouble
foreign import ccall unsafe "erfc" cErfc :: CDouble -> CDouble
foreign import ccall unsafe "jn" cJn :: CInt -> CDouble -> CDouble
foreign import ccall unsafe "yn" cYn :: CInt -> CDouble -> CDouble

-- | Finite value and estimated absolute numerical error. The estimate includes truncation/discretization and a small rounding allowance; it is not a certified enclosure.
data SFResult = SFResult {sfValue :: Double, sfError :: Double} deriving (Eq, Show)

finite :: Double -> Bool
finite x = not (isNaN x || isInfinite x)
checked :: Double -> Either MathError Double
checked x = if finite x then Right x else Left NonFiniteResult
estimate :: Double -> Double -> Either MathError SFResult
estimate x e = if finite x && finite e then Right (SFResult x (abs e + 8e-16 * abs x)) else Left NonFiniteResult
require :: Bool -> String -> Either MathError ()
require p msg = if p then Right () else Left (DomainError msg)

-- | Real gamma using C99 libm; rejects nonfinite arguments and nonpositive integer poles. Overflow is reported as NonFiniteResult.
gamma :: Double -> Either MathError Double
gamma x = do
    require (finite x && (x > 0 || x /= fromInteger (round x))) "gamma pole or non-finite argument"
    checked (realToFrac (cGamma (realToFrac x)))

-- | Natural logarithm of gamma for strictly positive finite arguments; avoids overflow of gamma itself.
logGamma :: Double -> Either MathError Double
logGamma x = do
    require (finite x && x > 0) "logGamma requires x>0"; checked (realToFrac (cLogGamma (realToFrac x)))

-- | Log beta for strictly positive finite parameters.
logBeta :: Double -> Double -> Either MathError Double
logBeta a b = do
    require (a > 0 && b > 0 && finite (a + b)) "beta positive parameters required"
    x <- logGamma a
    y <- logGamma b
    z <- logGamma (a + b)
    checked (x + y - z)

-- | Beta function for strictly positive parameters, evaluated through log gamma.
beta :: Double -> Double -> Either MathError Double
beta a b = exp <$> logBeta a b

{- | Regularized lower incomplete gamma. Series below a+1, Lentz continued
fraction above; upper tail is evaluated directly instead of subtracting 1.
-}
gammaP :: Double -> Double -> Either MathError Double
gammaP a x = do (p, _) <- gammaPQ a x; pure p

-- | Regularized upper gamma Q(a,x); the upper-tail continued fraction is evaluated directly when x>=a+1.
gammaQ :: Double -> Double -> Either MathError Double
gammaQ a x = do (_, q) <- gammaPQ a x; pure q

gammaPQ :: Double -> Double -> Either MathError (Double, Double)
gammaPQ a x = do
    require (finite a && finite x && a > 0 && x >= 0) "incomplete gamma needs a>0, x>=0"
    lg <- logGamma a
    if x == 0
        then Right (0, 1)
        else
            if x < a + 1
                then do
                    s <- series 10000 (1 / a) (\n t -> t * x / (a + fromIntegral n))
                    p <- checked (exp (a * log x - x - lg) * sfValue s)
                    pure (max 0 (min 1 p), max 0 (1 - p))
                else do
                    let b = x + 1 - a
                        d = 1 / b
                        go :: Int -> Double -> Double -> Double -> Double -> Either MathError Double
                        go n bb cc dd h
                            | n > 10000 = Left (NonConvergence "incomplete gamma fraction" 10000)
                            | otherwise =
                                let an = negate (fromIntegral n * (fromIntegral n - a))
                                    bn = bb + 2
                                    dn = nonzero (an * dd + bn)
                                    cn = nonzero (bn + an / cc)
                                    di = 1 / dn
                                    change = di * cn
                                    hn = h * change
                                 in if abs (change - 1) < 2e-15 then checked hn else go (n + 1) bn cn di hn
                    h <- go 1 b 1e300 d d
                    q <- checked (exp (a * log x - x - lg) * h)
                    pure (max 0 (1 - q), max 0 (min 1 q))
  where
    nonzero z = if abs z < 1e-300 then 1e-300 else z

-- | Unregularized lower gamma gamma(a,x)=Gamma(a)*P(a,x). Overflow is an error.
incompleteGamma :: Double -> Double -> Either MathError Double
incompleteGamma a x = do p <- gammaP a x; g <- gamma a; checked (p * g)

-- | Regularized lower incomplete beta I_x(a,b), positive parameters and x in [0,1], via reflected Lentz continued fraction.
betaI :: Double -> Double -> Double -> Either MathError Double
betaI a b x = do
    require
        (finite (a + b + x) && a > 0 && b > 0 && x >= 0 && x <= 1)
        "regularized beta requires positive parameters and x in [0,1]"
    if x == 0 || x == 1
        then Right x
        else
            if x > (a + 1) / (a + b + 2)
                then (1 -) <$> betaI b a (1 - x)
                else do
                    lb <- logBeta a b
                    let qab = a + b
                        qap = a + 1
                        qam = a - 1
                        nz v = if abs v < 1e-300 then 1e-300 else v
                        go :: Int -> Double -> Double -> Double -> Either MathError Double
                        go m c d h
                            | m > 10000 = Left (NonConvergence "beta continued fraction" 10000)
                            | otherwise =
                                let fm = fromIntegral m
                                    m2 = 2 * fm
                                    aa = fm * (b - fm) * x / ((qam + m2) * (a + m2))
                                    d1 = 1 / nz (1 + aa * d)
                                    c1 = nz (1 + aa / c)
                                    h1 = h * d1 * c1
                                    ab = -(a + fm) * (qab + fm) * x / ((a + m2) * (qap + m2))
                                    d2 = 1 / nz (1 + ab * d1)
                                    c2 = nz (1 + ab / c1)
                                    change = d2 * c2
                                    h2 = h1 * change
                                 in if abs (change - 1) < 2e-15 then checked h2 else go (m + 1) c2 d2 h2
                    cf <- go 1 1 (1 / (1 - qab * x / qap)) (1 / (1 - qab * x / qap))
                    checked (max 0 (min 1 (exp (a * log x + b * log (1 - x) - lb) * cf / a)))

-- | Unregularized lower incomplete beta B_x(a,b).
incompleteBeta :: Double -> Double -> Double -> Either MathError Double
incompleteBeta a b x = do p <- betaI a b x; v <- beta a b; checked (p * v)

series :: Int -> Double -> (Int -> Double -> Double) -> Either MathError SFResult
series budget first step = go 1 first first (abs first)
  where
    go n t s absoluteSum
        | n > budget = Left (NonConvergence "special-function series" budget)
        | otherwise =
            let u = step n t
                q = s + u
                absoluteNext = absoluteSum + abs u
                ratio = if t == 0 then 0 else abs (u / t)
                tailEstimate = if ratio < 1 then abs u / max 1e-16 (1 - ratio) else abs u
             in if not (finite q && finite absoluteNext)
                    then Left NonFiniteResult
                    else
                        if u == 0 || abs u < 2e-15 * abs q
                            then estimate q (tailEstimate + 8e-16 * absoluteNext)
                            else go (n + 1) u q absoluteNext

-- Adaptive Simpson with endpoint-finite integrands. Error is Richardson's
-- difference, not a bound. Budget counts binary subdivision depth (20).
integrate :: (Double -> Double) -> Double -> Double -> Either MathError SFResult
integrate f a b
    | a == b = Right (SFResult 0 0)
    | otherwise = go 20 a b (f a) (f ((a + b) / 2)) (f b)
  where
    sim x y u v w = (y - x) * (u + 4 * v + w) / 6
    go :: Int -> Double -> Double -> Double -> Double -> Double -> Either MathError SFResult
    go depth x y u v w
        | any (not . finite) [u, v, w] = Left NonFiniteResult
        | otherwise =
            let m = (x + y) / 2
                l = f ((x + m) / 2)
                r = f ((m + y) / 2)
                old = sim x y u v w
                new = sim x m u l v + sim m y v r w
                e = abs (new - old) / 15
             in if not (finite new)
                    then Left NonFiniteResult
                    else
                        if e < 1e-11 * max 1 (abs new)
                            then estimate (new + (new - old) / 15) e
                            else
                                if depth <= 0
                                    then Left (NonConvergence "special quadrature" 20)
                                    else do
                                        p <- go (depth - 1) x m u l v
                                        q <- go (depth - 1) m y v r w
                                        estimate (sfValue p + sfValue q) (sfError p + sfError q)

-- | Log-gamma derivative for x>0, using recurrence to x>=12 and an inverse-power asymptotic expansion.
digamma :: Double -> Either MathError Double
digamma x = do
    require (finite x && x > 0) "digamma x>0 required"
    let (y, s) = shift x 0
        z = 1 / (y * y)
        v = log y - 1 / (2 * y) - z * (1 / 12 - z * (1 / 120 - z * (1 / 252 - z / 240))) + s
     in checked v
  where
    shift y s | y < 12 = shift (y + 1) (s - 1 / y) | otherwise = (y, s)

-- | First polygamma derivative for x>0, using the Hurwitz-zeta identity.
trigamma :: Double -> Either MathError Double
trigamma = polygamma 1

-- | Derivative order 0..32 of digamma for x>0; higher orders use signed factorial times Hurwitz zeta.
polygamma :: Int -> Double -> Either MathError Double
polygamma n x
    | n == 0 = digamma x
    | otherwise = do
        require (n >= 1 && n <= 32 && finite x && x > 0) "polygamma order 0..32 and x>0 required"
        z <- hurwitzZeta (fromIntegral n + 1) x
        checked ((if odd n then 1 else -1) * fact n * sfValue z)

-- | Real error function from C99 libm; finite arguments required.
erf :: Double -> Either MathError Double
erf x = do require (finite x) "erf finite input required"; checked (realToFrac (cErf (realToFrac x)))

-- | Real complementary error function from C99 libm; upper tails avoid subtracting erf from one.
erfc :: Double -> Either MathError Double
erfc x = do require (finite x) "erfc finite input required"; checked (realToFrac (cErfc (realToFrac x)))

-- | exp(x^2)*erfc(x), with a large-positive-x inverse-power asymptotic expansion to avoid overflow.
erfcx :: Double -> Either MathError SFResult
erfcx x
    | not (finite x) = Left (DomainError "erfcx finite input required")
    | x > 26 = do
        s <- series 100 1 (\n t -> t * negate (fromIntegral (2 * n - 1)) / (2 * x * x))
        estimate (sfValue s / (sqrt pi * x)) (sfError s / (sqrt pi * x))
    | otherwise = do y <- erfc x; estimate (exp (x * x) * y) (abs y * 2e-15)

-- | Standard-normal CDF through erfc, with stable small lower tails.
normalCDF :: Double -> Either MathError Double
normalCDF x = (/ 2) <$> erfc (-x / sqrt 2)

-- | Standard-normal inverse CDF for 0\<p\<1. Symmetry preserves tiny upper-tail probabilities before bounded bisection.
normalQuantile :: Double -> Either MathError Double
normalQuantile p = do
    require (finite p && p > 0 && p < 1) "normal quantile requires 0<p<1"
    if p > 0.5 then negate <$> normalQuantile (1 - p) else bisect 100 (-40) 0 p normalCDF

-- | Real inverse error function for -1\<x\<1, using the normal inverse identity.
inverseErf :: Double -> Either MathError Double
inverseErf x = do
    require (finite x && abs x < 1) "inverseErf requires -1<x<1"
    (/ sqrt 2) <$> normalQuantile ((x + 1) / 2)

bisect ::
    Int -> Double -> Double -> Double -> (Double -> Either MathError Double) -> Either MathError Double
bisect n lo hi target f
    | n <= 0 = Right ((lo + hi) / 2)
    | otherwise = do
        let m = (lo + hi) / 2
        v <- f m
        if v < target then bisect (n - 1) m hi target f else bisect (n - 1) lo m target f
fact :: Int -> Double
fact n = product [1 .. fromIntegral n]

-- | Dawson integral for |x|\<=100; scaled quadrature below |x|=10, inverse-power asymptotics above.
dawson :: Double -> Either MathError SFResult
dawson x = do
    require (finite x && abs x <= 100) "Dawson supports |x|<=100"
    if abs x > 10
        then series 100 (1 / (2 * x)) (\n t -> t * fromIntegral (2 * n - 1) / (2 * x * x))
        else integrate (\t -> exp (t * t - x * x)) 0 x

-- | E_n(x), integer n=0..100000,x>0. Uses a continued fraction for x>=1, the logarithmic E1 series and stable upward recurrence below one.
exponentialIntegral :: Int -> Double -> Either MathError SFResult
exponentialIntegral n x = do
    require (n >= 0 && n <= 100000 && finite x && x > 0) "E_n needs integer n in0..100000 and x>0"
    if n == 0
        then estimate (exp (-x) / x) 0
        else
            if x >= 1
                then do
                    let nonzero y = if abs y < 1e-300 then 1e-300 else y
                        go :: Int -> Double -> Double -> Double -> Double -> Either MathError SFResult
                        go k b c d h
                            | k > 10000 = Left (NonConvergence "exponential integral fraction" 10000)
                            | otherwise =
                                let an = -fromIntegral k * (fromIntegral k + fromIntegral n - 1)
                                    bn = b + 2
                                    dn = 1 / nonzero (bn + an * d)
                                    cn = nonzero (bn + an / c)
                                    change = dn * cn
                                    hn = h * change
                                 in if abs (change - 1) < 2e-15
                                        then estimate (exp (-x) * hn) (abs (exp (-x) * hn * (change - 1)))
                                        else go (k + 1) bn cn dn hn
                    go 1 (x + fromIntegral n) 1e300 (1 / (x + fromIntegral n)) (1 / (x + fromIntegral n))
                else do
                    value <- series 10000 (-x) (\k t -> -t * x * fromIntegral k / fromIntegral ((k + 1) * (k + 1)))
                    let first = -0.5772156649015329 - log x - sfValue value
                        advance (v, e) k =
                            let fk = fromIntegral k; term = exp (-x) - x * v
                             in (term / fk, (x * e + 4e-16 * (abs (exp (-x)) + abs (x * v))) / fk)
                        (answer, errorEstimate) = Foldable.foldl' advance (first, sfError value) [1 .. n - 1]
                    estimate answer errorEstimate

{- | Real principal-value Ei for x>0; logarithmic integral li(x)=Ei(log x),
with the real PV continuation on 0\<x\<1.
-}
logarithmicIntegral :: Double -> Either MathError SFResult
logarithmicIntegral x = do
    require (finite x && x > 0 && x /= 1 && abs (log x) < 500) "li requires x>0, x/=1, |log x|<500"
    let y = log x
    if y < 0
        then do
            value <- exponentialIntegral 1 (-y)
            estimate (-sfValue value) (sfError value)
        else do
            value <- series 10000 y (\n t -> t * y * fromIntegral n / fromIntegral ((n + 1) * (n + 1)))
            estimate (0.5772156649015329 + log y + sfValue value) (sfError value)

-- | Real Si(x) on |x|\<=1000, with its removable singularity explicitly filled at zero.
sineIntegral :: Double -> Either MathError SFResult
sineIntegral x = do
    require (finite x && abs x <= 1000) "Si supports |x|<=1000"
    if abs x > 50
        then do
            (f, g) <- oscillatoryFG (abs x)
            let t = abs x; value = pi / 2 - cos t / t * sfValue f - sin t / (t * t) * sfValue g
            estimate ((if x < 0 then -1 else 1) * value) (sfError f / t + sfError g / (t * t))
        else
            integrateSegments
                (\t -> if t == 0 then 1 else sin t / t)
                (linearSegments 0 x (max 1 (ceiling (abs x))))

{- | Real Ci(x) on 0\<x\<=1000, using phase-resolved quadrature near zero and
inverse-power oscillatory asymptotics above x=50.
-}
cosineIntegral :: Double -> Either MathError SFResult
cosineIntegral x = do
    require (finite x && x > 0 && x <= 1000) "Ci supports 0<x<=1000"
    if x > 50
        then do
            (f, g) <- oscillatoryFG x
            estimate (sin x / x * sfValue f - cos x / (x * x) * sfValue g) (sfError f / x + sfError g / (x * x))
        else do
            value <-
                integrateSegments
                    (\t -> if t == 0 then 0 else (cos t - 1) / t)
                    (linearSegments 0 x (max 1 (ceiling x)))
            estimate (0.5772156649015329 + log x + sfValue value) (sfError value + 1e-14 * abs (log x))

oscillatoryFG :: Double -> Either MathError (SFResult, SFResult)
oscillatoryFG x = do
    f <- series 100 1 (\k t -> -t * fromIntegral ((2 * k) * (2 * k - 1)) / (x * x))
    g <- series 100 1 (\k t -> -t * fromIntegral ((2 * k + 1) * (2 * k)) / (x * x))
    pure (f, g)
linearSegments :: Double -> Double -> Int -> [Double]
linearSegments a b n = [a + (b - a) * fromIntegral i / fromIntegral n | i <- [0 .. n]]
integrateSegments :: (Double -> Double) -> [Double] -> Either MathError SFResult
integrateSegments f knots = do
    parts <- mapM (uncurry (integrate f)) (zip knots (drop 1 knots))
    estimate (sum (map sfValue parts)) (sum (map sfError parts))

{- | Fresnel (C,S), phase pi*t^2/2, |x|\<=100. Phase-sized subintervals prevent
oscillatory quadrature aliasing; above |x|=8 inverse-power asymptotics avoid it.
-}
fresnel :: Double -> Either MathError (SFResult, SFResult)
fresnel x = do
    require (finite x && abs x <= 100) "Fresnel supports |x|<=100"
    let t = abs x; sign = if x < 0 then -1 else 1
    if t >= 8
        then do
            let scale = pi * pi * t * t * t * t; theta = pi * t * t / 2
            f <- series 100 1 (\k v -> -v * fromIntegral ((4 * k - 1) * (4 * k - 3)) / scale)
            g <- series 100 1 (\k v -> -v * fromIntegral ((4 * k + 1) * (4 * k - 1)) / scale)
            let fv = sfValue f / (pi * t)
                gv = sfValue g / (pi * pi * t * t * t)
                err = sfError f / (pi * t) + sfError g / (pi * pi * t * t * t) + 1e-14
            c <- estimate (sign * (0.5 + fv * sin theta - gv * cos theta)) err
            ss <- estimate (sign * (0.5 - fv * cos theta - gv * sin theta)) err
            pure (c, ss)
        else do
            let n = max 1 (ceiling (t * t)) :: Int
                knots = [sign * sqrt (t * t * fromIntegral i / fromIntegral n) | i <- [0 .. n]]
            c <- integrateSegments (\u -> cos (pi * u * u / 2)) knots
            ss <- integrateSegments (\u -> sin (pi * u * u / 2)) knots
            pure (c, ss)

{- | Legendre incomplete elliptic integrals, parameter m (not modulus k),
real branch |phi|\<=pi/2, m\<1; Pi additionally n\<1.
-}
ellipticF :: Double -> Double -> Either MathError SFResult
ellipticF phi m = elliptic phi m 0 0

-- | Legendre incomplete second-kind elliptic integral with the same amplitude/parameter convention.
ellipticE :: Double -> Double -> Either MathError SFResult
ellipticE phi m = elliptic phi m 0 1

-- | Legendre third-kind integral with arguments characteristic n, amplitude phi, parameter m; n\<1, m\<1, |phi|\<=pi/2.
ellipticPi :: Double -> Double -> Double -> Either MathError SFResult
ellipticPi n phi m = elliptic phi m n 2

elliptic :: Double -> Double -> Double -> Int -> Either MathError SFResult
elliptic phi m n kind = do
    require
        (all finite [phi, m, n] && abs phi <= pi / 2 && m < 1 && n < 1)
        "real elliptic branch requires |phi|<=pi/2,m<1,n<1"
    integrate
        ( \t ->
            let q = sqrt (1 - m * sin t ^ (2 :: Int))
             in if kind == 1 then q else if kind == 2 then 1 / ((1 - n * sin t ^ (2 :: Int)) * q) else 1 / q
        )
        0
        phi

{- | Real (sn,cn,dn), |u|\<=10^6 and 0\<=m\<1, using periodic amplitude
inversion. The complete period uses AGM; the argument cap prevents accumulated
period uncertainty from being presented as a resolved large-argument phase.
-}
jacobiElliptic :: Double -> Double -> Either MathError (Double, Double, Double)
jacobiElliptic u m = do
    require
        (finite u && abs u <= 1e6 && finite m && m >= 0 && m < 1)
        "Jacobi requires |u|<=1e6 and 0<=m<1"
    let agm :: Int -> Double -> Double -> Either MathError Double
        agm 0 _ _ = Left (NonConvergence "Jacobi complete elliptic AGM" 100)
        agm count a b =
            let arithmetic = (a + b) / 2
                geometric = sqrt (a * b)
                -- Rounded AGM iterates can settle one ulp apart. Requiring a
                -- smaller difference would exhaust the budget at a fixed point.
                stagnant = arithmetic == a && geometric == b
             in if abs (a - b) <= 2e-16 * a || stagnant
                    then checked (pi / (a + b))
                    else agm (count - 1) arithmetic geometric
    k <- agm 100 1 (sqrt (1 - m))
    let period = 4 * k
        v = u - period * fromIntegral (floor ((u + 2 * k) / period) :: Integer)
        sgn = if v < 0 then -1 else 1
        w = abs v
        reflected = w > k
        target = if reflected then 2 * k - w else w
    phi <- bisect 60 0 (pi / 2) target (\t -> sfValue <$> ellipticF t m)
    let sn = sgn * sin phi; cn = (if reflected then -1 else 1) * cos phi
    pure (sn, cn, sqrt (1 - m * sn * sn))

-- | Integer-order J_n(x) from libm, |n|\<=100000 and finite real x.
besselJ :: Int -> Double -> Either MathError Double
besselJ n x = do
    require (abs (toInteger n) <= 100000 && finite x) "Bessel J integer order budget exceeded"
    checked (realToFrac (cJn (fromIntegral n) (realToFrac x)))

-- | Integer-order Y_n(x) from libm, |n|\<=100000 and x>0.
besselY :: Int -> Double -> Either MathError Double
besselY n x = do
    require (abs (toInteger n) <= 100000 && finite x && x > 0) "Bessel Y integer order, x>0 required"
    checked (realToFrac (cYn (fromIntegral n) (realToFrac x)))

-- | Modified Bessel I_n(x) via its convergent series, integer order 0..100 and |x|\<=700. Overflow is an error.
besselI :: Int -> Double -> Either MathError SFResult
besselI n x = do
    require (n >= 0 && n <= 100 && finite x && abs x <= 700) "Bessel I order 0..100, |x|<=700"
    g <- gamma (fromIntegral n + 1)
    series
        10000
        ((x / 2) ^ n / g)
        (\k t -> t * x * x / (4 * fromIntegral k * (fromIntegral k + fromIntegral n)))

-- | exp(-|x|)*I_n(x). Uses the power series for |x|\<=50 and asymptotics when n\<=20 and |x|>n^2.
scaledBesselI :: Int -> Double -> Either MathError SFResult
scaledBesselI n x
    | abs x <= 50 = do s <- besselI n x; estimate (exp (-abs x) * sfValue s) (exp (-abs x) * sfError s)
    | otherwise = do
        require
            (n >= 0 && n <= 20 && finite x && abs x > fromIntegral (n * n))
            "scaled I asymptotic requires |x|>n^2, n<=20"
        s <-
            series
                100
                1
                ( \k t -> t * negate (fromIntegral (4 * n * n - (2 * k - 1) ^ (2 :: Int))) / (8 * abs x * fromIntegral k)
                )
        let sign = if x < 0 && odd n then -1 else 1
         in estimate
                (sign * sfValue s / (sqrt (2 * pi) * sqrt (abs x)))
                (sfError s / (sqrt (2 * pi) * sqrt (abs x)))

-- | Modified Bessel K_n(x)=exp(-x)*scaledBesselK(n,x), integer order 0..100,x>0.
besselK :: Int -> Double -> Either MathError SFResult
besselK n x = do s <- scaledBesselK n x; estimate (exp (-x) * sfValue s) (exp (-x) * sfError s)

-- | exp(x)*K_n(x) from its cosh integral, integer order 0..100,x>0; scaling is inside the integrand.
scaledBesselK :: Int -> Double -> Either MathError SFResult
scaledBesselK n x = do
    require (n >= 0 && n <= 100 && finite x && x > 0) "Bessel K needs order 0..100,x>0"
    if x > max 50 (fromIntegral (n * n))
        then do
            value <-
                series
                    100
                    1
                    (\k t -> t * fromIntegral (4 * n * n - (2 * k - 1) ^ (2 :: Int)) / (8 * x * fromIntegral k))
            let scale = sqrt (pi / 2) / sqrt x
            estimate (scale * sfValue value) (scale * sfError value)
        else
            if x < 1e-4
                then do
                    -- The logarithmic small-x expansion avoids a truncated cosh integral whose
                    -- plateau extends beyond any practical finite integration limit.
                    let z = x * x / 4
                        terms = take 12 (scanl (\t k -> t * z / fromIntegral (k * k)) 1 [1 :: Int ..])
                        hs = scanl (+) 0 [1 / fromIntegral k | k <- [1 :: Int ..]]
                        i0 = sum terms
                        logTerm = log x - log 2 + 0.5772156649015329
                        i1 = x / 2 * sum (take 12 (scanl (\t k -> t * z / fromIntegral (k * (k + 1))) 1 [1 :: Int ..]))
                        k0 = -logTerm * i0 + sum (zipWith (*) terms hs)
                        k1 =
                            i0 / x
                                + logTerm * i1
                                - sum [2 * fromIntegral k / x * h * t | (k, (h, t)) <- zip [1 :: Int ..] (drop 1 (zip hs terms))]
                        go j a b | j == n = a | otherwise = go (j + 1) b (a + 2 * fromIntegral (j + 1) / x * b)
                        answer = if n == 0 then k0 else go 0 k0 k1
                    estimate (exp x * answer) (1e-13 * abs answer)
                else
                    integrate
                        ( \t ->
                            let y = abs (fromIntegral n * t); logCosh = y + log (1 + exp (-2 * y)) - log 2
                             in exp (-x * (cosh t - 1) + logCosh)
                        )
                        0
                        (min 40 (acosh (1 + max 50 (fromIntegral (n * n) + 50) / x)))

-- | Spherical j_n(x), order 0..100; uses a series for small x relative to order and upward recurrence otherwise.
sphericalBesselJ :: Int -> Double -> Either MathError Double
sphericalBesselJ n x = do
    require (n >= 0 && n <= 100 && finite x) "spherical Bessel J order 0..100"
    if x == 0
        then Right (if n == 0 then 1 else 0)
        else
            if abs x < fromIntegral n + 1
                then do
                    s <-
                        series
                            10000
                            (x ^ n / product [1, 3 .. fromIntegral (2 * n + 1)])
                            (\k t -> -t * x * x / (2 * fromIntegral k * fromIntegral (2 * n + 2 * k + 1)))
                    pure (sfValue s)
                else pure (recur n (sin x / x) (sin x / (x * x) - cos x / x))
  where
    recur 0 a _ = a
    recur 1 _ b = b
    recur k a b = go 1 a b
      where
        go j p q | j >= k = q | otherwise = go (j + 1) q (fromIntegral (2 * j + 1) / x * q - p)

-- | Spherical y_n(x), integer order 0..100,x>0, by upward recurrence.
sphericalBesselY :: Int -> Double -> Either MathError Double
sphericalBesselY n x = do
    require (n >= 0 && n <= 100 && finite x && x > 0) "spherical Y order 0..100,x>0"
    checked (go 0 (-cos x / x) (-cos x / (x * x) - sin x / x))
  where
    go j a b | j == n = a | otherwise = go (j + 1) b (fromIntegral (2 * j + 3) / x * b - a)

-- | Complex H_n^(kind)(x)=J_n(x)+/-iY_n(x), kind 1 or 2, integer order and x>0.
hankel :: Int -> Int -> Double -> Either MathError (Complex Double)
hankel kind n x = do
    require (kind == 1 || kind == 2) "Hankel kind 1 or 2"
    j <- besselJ n x
    y <- besselY n x
    pure (j :+ (if kind == 1 then y else -y))

{- | Airy Ai,Bi and derivatives solve y''=x y by convergent Maclaurin series.
The bounded real reference domain |x|\<=8 avoids severe recessive cancellation.
-}
airy :: Double -> Either MathError (SFResult, SFResult, SFResult, SFResult)
airy x = do
    require (finite x && abs x <= 8) "Airy reference domain |x|<=8"
    g1 <- gamma (1 / 3)
    g2 <- gamma (2 / 3)
    let a0 = 1 / (3 ** (2 / 3) * g2)
        a1 = -1 / (3 ** (1 / 3) * g1)
        eval y0 y1 =
            let cs = take 150 (y0 : y1 : 0 : zipWith (\c n -> c / fromIntegral (n * (n - 1))) cs [3 :: Int ..])
                v = sum (zipWith (*) cs (iterate (* x) 1))
                d = sum (zipWith (\n c -> fromIntegral n * c * x ^ (n - 1)) [1 :: Int ..] (drop 1 cs))
                e = 1e-14 * sum (map abs (zipWith (*) cs (iterate (* x) 1)))
             in (SFResult v e, SFResult d (e * 150))
        (a, ad) = eval a0 a1
        (b, bd) = eval (sqrt 3 * a0) (-sqrt 3 * a1)
    pure (a, ad, b, bd)

-- | Real Struve H_nu(x) by a convergent series; nu>-3/2 and 0\<=x\<=30.
struve :: Double -> Double -> Either MathError SFResult
struve nu x = do
    require (finite (nu + x) && nu > -1.5 && x >= 0 && x <= 30) "Struve H requires nu>-1.5,0<=x<=30"
    g <- gamma (nu + 1.5)
    series
        10000
        ((x / 2) ** (nu + 1) / (sqrt pi / 2 * g))
        (\k t -> -t * x * x / (4 * (fromIntegral k + 0.5) * (fromIntegral k + nu + 0.5)))

-- | Generalized pFq power series. Requires p\<=q or p=q+1 with |z|\<1 and no nonpositive-integer denominator parameters; finite budget 10000 terms.
hypergeometric :: [Double] -> [Double] -> Double -> Either MathError SFResult
hypergeometric as bs z = do
    require
        ( all finite (z : as ++ bs)
            && all (\b -> b > 0 || b /= fromInteger (round b)) bs
            && length as <= length bs + 1
            && (length as <= length bs || abs z < 1)
        )
        "hypergeometric power-series domain or denominator pole"
    series
        10000
        1
        ( \k t ->
            t
                * z
                / fromIntegral k
                * product [a + fromIntegral (k - 1) | a <- as]
                / product [b + fromIntegral (k - 1) | b <- bs]
        )

-- | Kummer confluent hypergeometric 1F1(a;b;z), real power-series evaluation with denominator-pole rejection.
hypergeometric1F1 :: Double -> Double -> Double -> Either MathError SFResult
hypergeometric1F1 a b z
    | z < 0 = do
        -- Kummer reflection turns a catastrophically alternating negative-axis
        -- series into positive-axis evaluation, with scaling applied afterwards.
        value <- hypergeometric [b - a] [b] (-z)
        estimate (exp z * sfValue value) (exp z * sfError value)
    | otherwise = hypergeometric [a] [b] z

-- | Gauss 2F1(a,b;c;z) in the real power-series disk |z|\<1.
hypergeometric2F1 :: Double -> Double -> Double -> Double -> Either MathError SFResult
hypergeometric2F1 a b c z = hypergeometric [a, b] [c] z

-- | Complex Kummer 1F1 in its entire z plane, rejecting denominator poles and nonfinite arithmetic; cancellation can limit accuracy for large imaginary z.
complex1F1 ::
    Complex Double -> Complex Double -> Complex Double -> Either MathError (Complex Double)
complex1F1 a b z = go 1 1 1
  where
    go :: Int -> Complex Double -> Complex Double -> Either MathError (Complex Double)
    go k t s
        | k > 10000 = Left (NonConvergence "complex 1F1" 10000)
        | magnitude (b + fromIntegral (k - 1)) == 0 = Left (DomainError "complex 1F1 pole")
        | otherwise =
            let u = t * (a + fromIntegral (k - 1)) / (b + fromIntegral (k - 1)) * z / fromIntegral k; q = s + u
             in if not (finite (magnitude q))
                    then Left NonFiniteResult
                    else if magnitude u < 1e-14 * max 1 (magnitude q) then Right q else go (k + 1) u q

-- | Legendre P_n(x), n=0..1000 and |x|\<=1.
legendre :: Int -> Double -> Either MathError Double
legendre n x = associatedLegendre n 0 x

-- | Associated P_l^m(x) with Condon--Shortley phase, 0\<=m\<=l\<=1000 and |x|\<=1.
associatedLegendre :: Int -> Int -> Double -> Either MathError Double
associatedLegendre l m x = do
    require
        (l >= 0 && l <= 1000 && m >= 0 && m <= l && finite x && abs x <= 1)
        "associated Legendre needs 0<=m<=l<=1000, |x|<=1"
    let p0 = product [1, 3 .. fromIntegral (2 * m - 1)] * (-sqrt (1 - x * x)) ^ m
        p1 = x * fromIntegral (2 * m + 1) * p0
        go j a b
            | j == l = a
            | otherwise =
                go
                    (j + 1)
                    b
                    ((fromIntegral (2 * j + 3) * x * b - fromIntegral (j + m + 1) * a) / fromIntegral (j - m + 2))
     in checked (if l == m then p0 else go m p0 p1)

-- | Orthonormal complex spherical harmonic Y_l^m(theta,phi), theta in [0,pi], including negative-m conjugation symmetry.
sphericalHarmonic :: Int -> Int -> Double -> Double -> Either MathError (Complex Double)
sphericalHarmonic l m theta phi = do
    require
        (l >= 0 && abs m <= l && finite (theta + phi) && theta >= 0 && theta <= pi)
        "spherical harmonic invalid degree/angle"
    p <- associatedLegendre l (abs m) (cos theta)
    a <- logGamma (fromIntegral (l - abs m + 1))
    b <- logGamma (fromIntegral (l + abs m + 1))
    let y =
            (sqrt (fromIntegral (2 * l + 1) / (4 * pi) * exp (a - b)) * p :+ 0)
                * cis (fromIntegral (abs m) * phi)
    pure (if m < 0 then (if odd m then -1 else 1) * conjugate y else y)

-- | Hurwitz zeta for s>1,q>0 using 64 explicit terms plus seven Euler--Maclaurin corrections.
hurwitzZeta :: Double -> Double -> Either MathError SFResult
hurwitzZeta s q = do
    require (finite (s + q) && s > 1 && q > 0) "Hurwitz zeta requires s>1,q>0"
    let n = 64 :: Int
        a = q + fromIntegral n
        terms = [(q + fromIntegral k) ** (-s) | k <- [0 .. n - 1]]
        coeff = [1 / 12, -1 / 720, 1 / 30240, -1 / 1209600, 1 / 47900160, -691 / 1307674368000, 7 / 523069747200]
        correction =
            [ b * product [s + fromIntegral j | j <- [0 .. 2 * k - 2]] * a ** (-s - fromIntegral (2 * k - 1))
            | (k, b) <- zip [1 :: Int ..] coeff
            ]
    estimate
        (sum terms + a ** (1 - s) / (s - 1) + 0.5 * a ** (-s) + sum correction)
        (abs (last correction))

-- | Real zeta: Euler--Maclaurin for s>1, Euler-transformed eta for 0\<s\<1 and reflection for -170\<s\<0. The pole s=1 is rejected.
riemannZeta :: Double -> Either MathError SFResult
riemannZeta s
    | s > 1 = hurwitzZeta s 1
    | s == 0 = Right (SFResult (-0.5) 0)
    | s < 0 = do
        require (finite s && s > -170) "zeta reflection domain -170<s<0"
        if s == fromInteger (round s) && even (round s :: Integer)
            then Right (SFResult 0 0)
            else do
                z <- hurwitzZeta (1 - s) 1
                g <- gamma (1 - s)
                estimate
                    (2 ** s * pi ** (s - 1) * sin (pi * s / 2) * g * sfValue z)
                    (abs (2 ** s * pi ** (s - 1) * sin (pi * s / 2) * g) * sfError z)
    | otherwise = do
        require (finite s && s /= 1) "zeta pole at 1"
        let rows =
                take
                    64
                    (iterate (\xs -> zipWith (-) xs (drop 1 xs)) [fromIntegral (k + 1) ** (-s) | k <- [0 .. 64 :: Int]])
            terms = [(row !! 0) / 2 ** fromIntegral (k + 1) | (k, row) <- zip [0 :: Int ..] rows]
            den = 1 - 2 ** (1 - s)
        estimate (sum terms / den) (abs (last terms / den) + 1e-14 / abs den)

-- | Real polylog Li_s(z) in the convergent power-series disk |z|\<1; no cross-cut continuation is implied.
polylogarithm :: Double -> Double -> Either MathError SFResult
polylogarithm s z = do
    require (finite (s + z) && abs z < 1) "real polylog power series needs |z|<1"
    series 100000 z (\k t -> t * z * (fromIntegral k / fromIntegral (k + 1)) ** s)

-- | Real Li_2(x) for x\<=1, with reflection and negative-axis transformations for convergent evaluation.
dilogarithm :: Double -> Either MathError SFResult
dilogarithm x
    | x == 1 = Right (SFResult (pi * pi / 6) 1e-15)
    | x == -1 = Right (SFResult (-pi * pi / 12) 1e-15)
    | x < -0.5 = do
        require (finite x) "dilog finite real x<=1"
        s <- dilogarithm (x / (x - 1))
        estimate (-sfValue s - log (1 - x) ^ (2 :: Int) / 2) (sfError s)
    | x > 0.5 && x < 1 = do s <- dilogarithm (1 - x); estimate (pi * pi / 6 - log x * log (1 - x) - sfValue s) (sfError s)
    | otherwise = polylogarithm 2 x

-- | Real Lambert W branch 0 or -1, x>=-1/e and x\<0 on branch -1, using bounded Halley iteration.
lambertW :: Int -> Double -> Either MathError SFResult
lambertW branch x = do
    require
        (finite x && (branch == 0 || branch == -1) && x >= -1 / exp 1 && (branch == 0 || x < 0))
        "real Lambert W branches 0 and -1 require x>=-1/e; -1 needs x<0"
    if x == -1 / exp 1
        then Right (SFResult (-1) 1e-8)
        else if x == 0 then Right (SFResult 0 0) else go 100 initial
  where
    initial | branch == -1 = log (-x) - log (-log (-x)) | x < 1 = x | otherwise = log x - log (max 1 (log x))
    go :: Int -> Double -> Either MathError SFResult
    go 0 _ = Left (NonConvergence "Lambert W Halley" 100)
    go n w =
        let e = exp w; f = w * e - x; d = e * (w + 1) - (w + 2) * f / (2 * w + 2); v = w - f / d
         in if abs (v - w) < 1e-13 * max 1 (abs v) then estimate v (abs (v - w)) else go (n - 1) v

{- | Normalized Debye D_n(x), integer n=1..16,x>=0, with D_n(0)=1.
At large x the complete Bose integral supplies the asymptote and an
exponentially small omitted-tail estimate; logarithmic scaling avoids x^n overflow.
-}
debye :: Int -> Double -> Either MathError SFResult
debye n x = do
    require (n >= 1 && n <= 16 && finite x && x >= 0) "Debye order 1..16,x>=0"
    if x == 0
        then Right (SFResult 1 0)
        else
            if x > 100 + 2 * fromIntegral n
                then do
                    z <- hurwitzZeta (fromIntegral n + 1) 1
                    lg <- logGamma (fromIntegral n + 1)
                    let value = exp (log (fromIntegral n) + lg + log (sfValue z) - fromIntegral n * log x)
                        tailBound = fromIntegral n * exp (-x) / ((1 - exp (-x)) * (1 - fromIntegral n / x))
                    estimate value (tailBound + abs value * sfError z / sfValue z)
                else do
                    s <- integrate (\t -> if t == 0 then if n == 1 then 1 else 0 else t ^ n / (exp t - 1)) 0 x
                    estimate (fromIntegral n * sfValue s / x ^ n) (fromIntegral n * sfError s / x ^ n)

-- | Periodic Clausen Cl_2(theta) from an integral with a squared-variable substitution at its logarithmic endpoint.
clausen :: Double -> Either MathError SFResult
clausen theta = do
    require (finite theta) "Clausen finite angle"
    -- libm trigonometric reduction retains phase where theta-2*pi*k would
    -- round away the entire remainder for a huge finite angle.
    let x = atan2 (sin theta) (cos theta)
     in if x == 0
            then Right (SFResult 0 0)
            else integrate (\u -> if u == 0 then 0 else -2 * x * u * log (abs (2 * sin (x * u * u / 2)))) 0 1

-- | Complete normalized Fermi--Dirac integral F_order(eta), 0\<=order\<=20, |eta|\<=100.
fermiDirac :: Double -> Double -> Either MathError SFResult
fermiDirac order eta = quantumIntegral False order eta

-- | Complete normalized Bose--Einstein integral, same order range, -100\<=eta\<=0 and positive order at eta=0.
boseEinstein :: Double -> Double -> Either MathError SFResult
boseEinstein order eta = quantumIntegral True order eta

quantumIntegral :: Bool -> Double -> Double -> Either MathError SFResult
quantumIntegral bose order eta = do
    require
        ( finite (order + eta)
            && order >= 0
            && order <= 20
            && eta <= 100
            && eta >= -100
            && (not bose || (eta <= 0 && (eta < 0 || order > 0)))
        )
        "quantum integral: 0<=order<=20,|eta|<=100; Bose eta<=0 and order>0 at eta=0"
    g <- gamma (order + 1)
    let top = max 50 (eta + 50); sgn = if bose then -1 else 1
    s <-
        integrate
            (\u -> if u == 0 then 0 else let t = top * u * u in 2 * top * u * t ** order / (exp (t - eta) + sgn))
            0
            1
    estimate (sfValue s / g) (sfError s / g + exp (eta - top) * top ** order / g)

{- | Regular and irregular Coulomb waves F_l,G_l. The regular function follows
the convergent hypergeometric representation. G is integrated backwards from
a first-order asymptotic boundary at R>=300 using RK4; its error estimate
includes the omitted O((l(l+1)+eta^2)/R) term. Real reference domain l\<=8,
|eta|\<=3, 0.5\<=rho\<=30. This is deliberately not a high-accuracy scattering solver.
-}
coulombWave :: Int -> Double -> Double -> Either MathError (SFResult, SFResult)
coulombWave l eta rho = do
    require
        (l >= 0 && l <= 8 && finite (eta + rho) && abs eta <= 3 && rho >= 0.5 && rho <= 30)
        "Coulomb reference domain l<=8,|eta|<=3,0.5<=rho<=30"
    let z = complexLogGamma (fromIntegral (l + 1) :+ eta)
        sigma = imagPart z
        lc = fromIntegral l * log 2 - pi * eta / 2 + realPart z - log (fact (2 * l + 1))
        start = 0.5
        aa = fromIntegral (l + 1) :+ (-eta)
        bb = fromIntegral (2 * l + 2) :+ 0
    h <- complex1F1 aa bb (0 :+ (2 * start))
    hd <- complex1F1 (aa + 1) (bb + 1) (0 :+ (2 * start))
    let pref = exp lc
        f0 = pref * start ^ (l + 1) * realPart (cis (-start) * h)
        df0 =
            pref
                * realPart
                    ( cis (-start)
                        * ( ((fromIntegral (l + 1) * start ^ l) :+ (-start ^ (l + 1))) * h
                                + (start ^ (l + 1) :+ 0) * (0 :+ 2) * aa / bb * hd
                          )
                    )
        accel t y = (fromIntegral (l * (l + 1)) / (t * t) + 2 * eta / t - 1) * y
        advance dt (t, y, v) =
            let a = accel t y
                b = accel (t + dt / 2) (y + dt * v / 2)
                c = accel (t + dt / 2) (y + dt * v / 2 + dt * dt * a / 4)
                d = accel (t + dt) (y + dt * v + dt * dt * b / 2)
             in (t + dt, y + dt * v + dt * dt * (a + b + c) / 6, v + dt * (a + 2 * b + 2 * c + d) / 6)
        propagate maxStep lo hi y v =
            let direction = if hi >= lo then 1 else -1
                go state@(t, _, _) steps
                    | direction * (hi - t) <= 1e-12 = let (_, answer, _) = state in answer
                    | steps >= 1000000 = 0 / 0
                    | otherwise =
                        let dt = direction * min (abs (hi - t)) (min maxStep (0.01 * t))
                         in go (advance dt state) (steps + 1)
             in go (lo, y, v) (0 :: Int)
        -- Integrate from a small regular series value to avoid catastrophic
        -- cancellation of the oscillatory 1F1 representation at large rho.
        f = propagate 0.0025 start rho f0 df0
        fCoarse = propagate 0.005 start rho f0 df0
        r = 300 + fromIntegral (l * l) + eta * eta
        theta = r - eta * log (2 * r) - fromIntegral l * pi / 2 + sigma
        gv = propagate 0.01 r rho (cos theta) (-sin theta * (1 - eta / r))
    a <- estimate f (abs (f - fCoarse) / 15 + 1e-8 * abs f)
    b <- estimate gv ((1 + abs gv) * (1 + fromIntegral (l * (l + 1)) + eta * eta) / r)
    pure (a, b)

complexLogGamma :: Complex Double -> Complex Double
complexLogGamma z
    | realPart z < 0.5 = (log (pi :+ 0) - log (sin (pi * z))) - complexLogGamma (1 - z)
    | otherwise =
        let cs =
                [ 0.99999999999980993
                , 676.5203681218851
                , -1259.1392167224028
                , 771.32342877765313
                , -176.61502916214059
                , 12.507343278686905
                , -0.13857109526572012
                , 9.9843695780195716e-6
                , 1.5056327351493116e-7
                ]
            w = z - 1
            t = w + 7.5
            a = (cs !! 0 :+ 0) + sum [(c :+ 0) / (w + fromIntegral k) | (k, c) <- zip [1 :: Int ..] (drop 1 cs)]
         in 0.5 * log (2 * pi) + (w + 0.5) * log t - t + log a

-- | Gegenbauer C_n^alpha(x), degree 0..10000 and alpha>-1/2, alpha/=0, by three-term recurrence.
gegenbauer :: Int -> Double -> Double -> Either MathError Double
gegenbauer n a x = do
    require (n >= 0 && n <= 10000 && finite (a + x) && a > -0.5 && a /= 0) "Gegenbauer n>=0,a>-1/2,a/=0"
    checked (go 0 1 (2 * a * x))
  where
    go k p q
        | k == n = p
        | otherwise =
            let j = fromIntegral (k + 1) in go (k + 1) q ((2 * (j + a) * x * q - (j + 2 * a - 1) * p) / (j + 1))

-- | Real D_nu(x) via Kummer's representation; reference |x|\<=6, |nu|\<=10.
parabolicCylinder :: Double -> Double -> Either MathError SFResult
parabolicCylinder nu x = do
    require
        (finite (nu + x) && abs nu <= 10 && abs x <= 6)
        "parabolic cylinder reference |nu|<=10,|x|<=6"
    let recipGamma y = if y <= 0 && y == fromInteger (round y) then Right 0 else (1 /) <$> gamma y
    a <- recipGamma ((1 - nu) / 2)
    b <- recipGamma (-nu / 2)
    u <- hypergeometric1F1 (-nu / 2) 0.5 (x * x / 2)
    v <- hypergeometric1F1 ((1 - nu) / 2) 1.5 (x * x / 2)
    let fac = 2 ** (nu / 2) * exp (-x * x / 4) * sqrt pi
    estimate
        (fac * (a * sfValue u - sqrt 2 * x * b * sfValue v))
        (abs fac * (abs a * sfError u + sqrt 2 * abs (x * b) * sfError v))

{- | Mathieu ce_n (even=True) or se_n, from a 32-term Fourier Galerkin
eigenproblem. ce(0)=1 or se'(0)=1. Error estimates the last coefficient;
reference 0\<=n\<=12, |q|\<=10, any real x. Characteristic value is returned.
-}
mathieu :: Bool -> Int -> Double -> Double -> Either MathError (Double, SFResult)
mathieu evenMode n q x = do
    require
        (n >= 0 && n <= 12 && (evenMode || n > 0) && finite (q + x) && abs q <= 10)
        "Mathieu reference degree 0..12,|q|<=10"
    let parity = n `mod` 2
        freqs =
            take
                32
                [ if parity == 0 && not evenMode then 2 else parity
                , if parity == 0 && not evenMode then 4 else parity + 2
                ..
                ]
        norm j = if freqs !! j == 0 then sqrt 2 else 1
        entry i j
            | i == j =
                fromIntegral ((freqs !! i) ^ (2 :: Int))
                    + (if freqs !! i == 1 then if evenMode then q else -q else 0)
            | abs (i - j) == 1 = q * (if freqs !! min i j == 0 then sqrt 2 else 1)
            | otherwise = 0
    mat <- fromListChecked 32 32 [entry i j | i <- [0 .. 31], j <- [0 .. 31]]
    eig <- symmetricEigen mat
    let which = if evenMode then n `div` 2 else (n - 1) `div` 2
        coeff = [realPart (toList (eigenvectors eig) !! (32 * j + which)) | j <- [0 .. 31]]
        basis j =
            if evenMode
                then cos (fromIntegral (freqs !! j) * x) / norm j
                else sin (fromIntegral (freqs !! j) * x)
        denom =
            if evenMode
                then sum [coeff !! j / norm j | j <- [0 .. 31]]
                else sum [coeff !! j * fromIntegral (freqs !! j) | j <- [0 .. 31]]
        v = sum [coeff !! j * basis j | j <- [0 .. 31]] / denom
    value <- estimate v (abs (last coeff / denom))
    pure (realPart (eigenvalues eig !! which), value)

{- | Exact rational Bernoulli/Euler coefficients evaluated as Double. Bernoulli
B1=-1/2; Euler E_n(x) defined by 2 exp(xt)/(exp t+1).
-}
bernoulliPolynomial :: Int -> Double -> Either MathError Double
bernoulliPolynomial n x = do
    require (n >= 0 && n <= 100 && finite x) "Bernoulli polynomial degree 0..100"
    checked (sum [fromIntegral (choose n k) * fromRational (bs !! k) * x ^ (n - k) | k <- [0 .. n]])
  where
    bs =
        1
            : [ -sum [fromIntegral (choose (m + 1) k) * (bs !! k) | k <- [0 .. m - 1]] / fromIntegral (m + 1)
              | m <- [1 ..]
              ] ::
            [Rational]

-- | Euler E_n(x), n=0..100, from the Bernoulli duplication identity.
eulerPolynomial :: Int -> Double -> Either MathError Double
eulerPolynomial n x = do
    require (n >= 0 && n <= 100 && finite x) "Euler polynomial degree 0..100"
    a <- bernoulliPolynomial (n + 1) x
    b <- bernoulliPolynomial (n + 1) (x / 2)
    checked (2 / fromIntegral (n + 1) * (a - 2 ** fromIntegral (n + 1) * b))

choose :: Int -> Int -> Integer
choose n k
    | k < 0 || k > n = 0
    | otherwise =
        product [fromIntegral (n - k + 1) .. fromIntegral n] `div` product [1 .. fromIntegral k]

{- | Angular momenta and projections are encoded as doubled integers, allowing
half-integers exactly. Factorial Racah sums have j\<=30 and return selection
rule zeros rather than factorials of negative arguments.
-}
wigner3j :: Int -> Int -> Int -> Int -> Int -> Int -> Either MathError Double
wigner3j j1 j2 j3 m1 m2 m3 = do
    require (all (\j -> j >= 0 && j <= 60) [j1, j2, j3]) "Wigner doubled j must lie in 0..60"
    if not (triangle j1 j2 j3)
        || m1 + m2 + m3 /= 0
        || or [abs m > j || odd (j + m) | (j, m) <- zip [j1, j2, j3] [m1, m2, m3]]
        then Right 0
        else do
            let a = (j1 + j2 - j3) `div` 2
                b = (j1 - m1) `div` 2
                c = (j2 + m2) `div` 2
                d = (j3 - j2 + m1) `div` 2
                e = (j3 - j1 - m2) `div` 2
                lo = maximum [0, -d, -e]
                hi = minimum [a, b, c]
                sumv =
                    sum
                        [ (if even z then 1 else -1)
                            / fromInteger
                                ( integerFact z
                                    * integerFact (a - z)
                                    * integerFact (b - z)
                                    * integerFact (c - z)
                                    * integerFact (d + z)
                                    * integerFact (e + z)
                                )
                        | z <- [lo .. hi]
                        ] ::
                        Rational
                pref2 =
                    deltaR j1 j2 j3
                        * fromInteger
                            ( product
                                [ integerFact ((j + m) `div` 2) * integerFact ((j - m) `div` 2)
                                | (j, m) <- zip [j1, j2, j3] [m1, m2, m3]
                                ]
                            )
                value =
                    phase ((j1 - j2 - m3) `div` 2)
                        * (if sumv < 0 then -1 else 1)
                        * sqrt (fromRational (pref2 * sumv * sumv))
            checked value

phase :: Int -> Double
phase n = if even n then 1 else -1
triangle :: Int -> Int -> Int -> Bool
triangle a b c = a + b >= c && a + c >= b && b + c >= a && even (a + b + c)
integerFact :: Int -> Integer
integerFact n = product [1 .. toInteger n]
deltaR :: Int -> Int -> Int -> Rational
deltaR a b c =
    fromInteger
        ( integerFact ((a + b - c) `div` 2)
            * integerFact ((a - b + c) `div` 2)
            * integerFact ((-a + b + c) `div` 2)
        )
        / fromInteger (integerFact ((a + b + c) `div` 2 + 1))

-- | Racah factorial sum for a Wigner 6j symbol; each angular momentum is a doubled integer in 0..60.
wigner6j :: Int -> Int -> Int -> Int -> Int -> Int -> Either MathError Double
wigner6j a b c d e f = do
    require (all (\j -> j >= 0 && j <= 60) [a, b, c, d, e, f]) "Wigner doubled j 0..60"
    if not (and [triangle a b c, triangle a e f, triangle d b f, triangle d e c])
        then Right 0
        else do
            let low = map (`div` 2) [a + b + c, a + e + f, d + b + f, d + e + c]
                high = map (`div` 2) [a + b + d + e, a + c + d + f, b + c + e + f]
                s =
                    sum
                        [ (if even z then 1 else -1)
                            * fromInteger (integerFact (z + 1))
                            / fromInteger (product [integerFact (z - t) | t <- low] * product [integerFact (t - z) | t <- high])
                        | z <- [maximum low .. minimum high]
                        ] ::
                        Rational
                squared = deltaR a b c * deltaR a e f * deltaR d b f * deltaR d e c * s * s
            checked ((if s < 0 then -1 else 1) * sqrt (fromRational squared))

-- | Wigner 9j as a finite sum of three 6j symbols; accepts nine row-major doubled angular momenta in 0..30.
wigner9j :: [Int] -> Either MathError Double
wigner9j js = do
    require
        (length js == 9 && all (\j -> j >= 0 && j <= 30) js)
        "9j needs nine doubled angular momenta 0..30"
    let a = js !! 0
        b = js !! 1
        c = js !! 2
        d = js !! 3
        e = js !! 4
        f = js !! 5
        g = js !! 6
        h = js !! 7
        i = js !! 8
    terms <-
        mapM
            ( \x -> do
                u <- wigner6j a d g h i x
                v <- wigner6j b e h d x f
                w <- wigner6j c f i x a b
                pure (phase x * fromIntegral (x + 1) * u * v * w)
            )
            [0 .. 60]
    checked (sum terms)

-- | Clebsch--Gordan coefficient \<j1 m1,j2 m2|j m> through the Condon--Shortley 3j convention; all arguments doubled integers.
clebschGordan :: Int -> Int -> Int -> Int -> Int -> Int -> Either MathError Double
clebschGordan j1 m1 j2 m2 j m = do
    v <- wigner3j j1 j2 j m1 m2 (-m)
    checked (phase ((j1 - j2 + m) `div` 2) * sqrt (fromIntegral (j + 1)) * v)
