-- SPDX-License-Identifier: MPL-2.0

{- | CPU reference DSP. Sample rates/frequencies are in Hz, times in seconds,
angular frequencies in radians/sample. Filtering uses causal zero-state
initial conditions and transposed direct form II; state is explicit and may
be carried across blocks. Convolution is full linear convolution; correlation
lags run -(length y-1)..length x-1 and real-valued y is reversed.

Filter prototypes use the classical bilinear transform and prewarped edges;
elliptic prototypes use Jacobi elliptic identities and the nome degree
equation (see <https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.ellipap.html>
and <https://dlmf.nist.gov/22.6>). Bessel is delay-normalized, so its supplied
edge is a prototype scale, not the Butterworth half-power frequency.
Wavelets use periodic extension; lengths must be divisible by 2^levels.
-}
module HMath.Signal (
    convolution,
    circularConvolution,
    correlation,
    autocorrelation,
    overlapAdd,
    overlapSave,
    Filter,
    iir,
    fir,
    filterCoefficients,
    filterState,
    resetFilter,
    filterSignal,
    FilterFamily (..),
    FilterBand (..),
    designIIR,
    frequencyResponse,
    notch,
    allPass,
    movingAverage,
    medianFilter,
    gaussianFilter,
    savitzkyGolay,
    wiener,
    Window (..),
    window,
    windowedSinc,
    downsample,
    upsample,
    resamplePolyphase,
    resample,
    antiAlias,
    Peak (..),
    peaks,
    zeroCrossings,
    envelope,
    unwrapPhase,
    detrend,
    normalize,
    smooth,
    noiseEstimate,
    signalToNoise,
    rms,
    GaussianState,
    gaussianState,
    stateMean,
    stateCovariance,
    kalman,
    extendedKalman,
    unscentedKalman,
    Wavelet (..),
    WaveletTree,
    dwt,
    idwt,
    waveletApproximation,
    waveletDetails,
    MotherWavelet (..),
    cwt,
    WaveletPacket,
    waveletPackets,
    inverseWaveletPackets,
    packetBands,
    waveletDenoise,
) where

import Control.Monad (foldM)
import Data.Complex (Complex ((:+)), cis, conjugate, imagPart, magnitude, realPart)
import Data.List (sort)
import HMath.Error (MathError (..))
import qualified HMath.Fourier as F
import qualified HMath.Interpolation as I
import qualified HMath.Polynomial as P
import HMath.Signal.Internal
import qualified HMath.Special as SF

-- | Direct full real linear convolution, with explicit quadratic work budget; an empty operand yields an empty result.
convolution :: [Double] -> [Double] -> Either MathError [Double]
convolution xs ys = do
    require
        (toInteger (length xs) * toInteger (length ys) <= 10000000)
        "direct convolution work budget exceeded"
    _ <- vector (xs ++ ys)
    if null xs || null ys
        then Right []
        else
            vector
                [ sum [xs !! j * ys !! (k - j) | j <- [max 0 (k - length ys + 1) .. min k (length xs - 1)]]
                | k <- [0 .. length xs + length ys - 2]
                ]

-- | Length-N periodic convolution of two equally sized nonempty real signals (N<=4096).
circularConvolution :: [Double] -> [Double] -> Either MathError [Double]
circularConvolution x y = do
    require
        (not (null x) && length x == length y && length x <= 4096)
        "circular convolution needs equal nonempty lengths <=4096"
    _ <- vector (x ++ y)
    let n = length x
    vector [sum [x !! j * y !! ((k - j) `mod` n) | j <- [0 .. n - 1]] | k <- [0 .. n - 1]]

-- | Full real cross-correlation, equivalent to convolution with the reversed second signal.
correlation :: [Double] -> [Double] -> Either MathError [Double]
correlation x y = convolution x (reverse y)

-- | Unnormalized full autocorrelation with zero lag in the middle.
autocorrelation :: [Double] -> Either MathError [Double]
autocorrelation x = correlation x x

-- | Block FFT linear convolution; block is the number of new input samples, not the padded transform length.
overlapAdd :: Int -> [Double] -> [Double] -> Either MathError [Double]
overlapAdd block kernel xs = do
    require
        ( block > 0
            && not (null kernel)
            && not (null xs)
            && toInteger block + toInteger (length kernel) <= 65537
        )
        "invalid overlap-add block/kernel/data"
    _ <- vector (kernel ++ xs)
    pieces <-
        mapM
            (\segment -> map realPart <$> F.fftConvolve (map (:+ 0) segment) (map (:+ 0) kernel))
            (chunks block xs)
    let n = length xs + length kernel - 1
    vector
        [ sum
            [row !! (k - start) | (start, row) <- zip [0, block ..] pieces, k >= start, k - start < length row]
        | k <- [0 .. n - 1]
        ]

-- | Streaming FFT convolution with explicit transform length >= kernel length; retained block size is N-M+1.
overlapSave :: Int -> [Double] -> [Double] -> Either MathError [Double]
overlapSave fftLength kernel xs = do
    let m = length kernel; l = fftLength - m + 1
    require
        (m > 0 && not (null xs) && fftLength >= m && fftLength <= 65536)
        "invalid overlap-save transform length/kernel/data"
    _ <- vector (kernel ++ xs)
    let padded = replicate (m - 1) 0 ++ xs ++ replicate (m - 1) 0
        count = length xs + m - 1
        starts = takeWhile (< count) [0, l ..]
    h <- F.fft (map (:+ 0) (kernel ++ replicate (fftLength - m) 0))
    blocks <-
        mapM
            ( \start -> do
                let segment = take fftLength (drop start padded ++ repeat 0)
                a <- F.fft (map (:+ 0) segment)
                row <- F.ifft (zipWith (*) a h)
                Right (take l (drop (m - 1) (map realPart row)))
            )
            starts
    vector (take count (concat blocks))

-- | Opaque normalized numerator/denominator and caller-visible persistent delay state.
data Filter = Filter [Double] [Double] [Double] deriving (Eq, Show)

-- | Normalize finite ascending z^-1 coefficients by nonzero a0 and initialize a zero transposed-direct-form-II state.
iir :: [Double] -> [Double] -> Either MathError Filter
iir numerator denominator = do
    require
        ( not (null numerator)
            && not (null denominator)
            && length numerator <= 257
            && length denominator <= 257
            && denominator !! 0 /= 0
        )
        "invalid IIR coefficients (1..257, nonzero a0)"
    _ <- vector (numerator ++ denominator)
    let a0 = denominator !! 0; order = max (length numerator) (length denominator) - 1
    b <- vector (map (/ a0) numerator ++ replicate (order + 1 - length numerator) 0)
    a <- vector (map (/ a0) denominator ++ replicate (order + 1 - length denominator) 0)
    Right (Filter b a (replicate order 0))

-- | Construct a causal zero-state finite-impulse-response filter; maximum 257 taps.
fir :: [Double] -> Either MathError Filter
fir b = iir b [1]

-- | Read normalized padded (numerator,denominator) coefficients in increasing delay order.
filterCoefficients :: Filter -> ([Double], [Double])
filterCoefficients (Filter b a _) = (b, a)

-- | Read explicit delay state after a block; the list is immutable and independently reusable.
filterState :: Filter -> [Double]
filterState (Filter _ _ s) = s

-- | Preserve coefficients while replacing every delay with zero.
resetFilter :: Filter -> Filter
resetFilter (Filter b a s) = Filter b a (replicate (length s) 0)

-- | Process a finite input block, returning both its output and the filter state for the next block.
filterSignal :: Filter -> [Double] -> Either MathError ([Double], Filter)
filterSignal (Filter b a state) xs = do
    _ <- vector xs
    let step (acc, s) x = do
            let y = b !! 0 * x + if null s then 0 else s !! 0
                next =
                    [ (if i + 1 < length s then s !! (i + 1) else 0) + b !! (i + 1) * x - a !! (i + 1) * y
                    | i <- [0 .. length s - 1]
                    ]
            _ <- vector (y : next)
            Right (y : acc, next)
    (ys, next) <- foldM step ([], state) xs
    Right (reverse ys, Filter b a next)

-- | Complex unit-circle response at omega radians/sample; reject poles and nonfinite arithmetic.
frequencyResponse :: Filter -> Double -> Either MathError (Complex Double)
frequencyResponse (Filter b a _) omega = do
    require (finite omega) "invalid angular frequency"
    let z = cis (-omega)
        den = sum [coefficient * z ^ j | (j, coefficient) <- zip [0 :: Int ..] (map (:+ 0) a)]
        numerator = sum [coefficient * z ^ j | (j, coefficient) <- zip [0 :: Int ..] (map (:+ 0) b)]
    require (magnitude den > 0) "filter pole at requested frequency"
    let value = numerator / den
    _ <- vector [realPart value, imagPart value]
    Right value

-- | Classical analog prototypes with ripple/attenuation parameters in decibels.
data FilterFamily
    = Butterworth
    | ChebyshevI Double
    | ChebyshevII Double
    | Elliptic Double Double
    | Bessel
    deriving (Eq, Show)

-- | Prewarped low/high edge or ordered band edges, all in Hz.
data FilterBand = Lowpass Double | Highpass Double | Bandpass Double Double | Bandstop Double Double
    deriving (Eq, Show)

{- | Orders 1..8; ripple/attenuation in dB; all edges strictly inside (0, fs/2).
Expanded coefficients are a bounded reference representation; high orders
should use cascaded sections in production applications.
-}
designIIR :: FilterFamily -> FilterBand -> Int -> Double -> Either MathError Filter
designIIR family band order rate = do
    require (order >= 1 && order <= 8 && finite rate && rate > 0) "invalid IIR order/sample rate"
    let edges = case band of Lowpass f -> [f]; Highpass f -> [f]; Bandpass a b -> [a, b]; Bandstop a b -> [a, b]
    require
        (all (\f -> finite f && f > 0 && f < rate / 2) edges && and (zipWith (<) edges (drop 1 edges)))
        "filter edges must increase inside Nyquist"
    (zeros, poles, gain) <- prototype family order
    let warp f = 2 * rate * tan (pi * f / rate)
        degree = length poles - length zeros
        ratio = realPart (product (map negate zeros) / product (map negate poles))
        quadratic term center =
            let discriminant = sqrt (term * term - (4 * center * center :+ 0))
             in [(term + discriminant) / 2, (term - discriminant) / 2]
        (az, ap, ak) = case band of
            Lowpass f -> let w = warp f in (map (* (w :+ 0)) zeros, map (* (w :+ 0)) poles, gain * w ^ degree)
            Highpass f ->
                let w = warp f
                 in (map ((w :+ 0) /) zeros ++ replicate degree 0, map ((w :+ 0) /) poles, gain * ratio)
            Bandpass lo hi ->
                let w1 = warp lo; w2 = warp hi; width = w2 - w1; center = sqrt (w1 * w2)
                 in ( concatMap (\z -> quadratic (z * (width :+ 0)) center) zeros ++ replicate degree 0
                    , concatMap (\p -> quadratic (p * (width :+ 0)) center) poles
                    , gain * width ^ degree
                    )
            Bandstop lo hi ->
                let w1 = warp lo; w2 = warp hi; width = w2 - w1; center = sqrt (w1 * w2)
                 in ( concatMap (\z -> quadratic ((width :+ 0) / z) center) zeros
                        ++ concat (replicate degree [0 :+ center, 0 :+ (-center)])
                    , concatMap (\p -> quadratic ((width :+ 0) / p) center) poles
                    , gain * ratio
                    )
        c = 2 * rate :+ 0
        dz = map (\z -> (c + z) / (c - z)) az ++ replicate (length ap - length az) (-1)
        dp = map (\p -> (c + p) / (c - p)) ap
        dk = ak * realPart (product (map (c -) az) / product (map (c -) ap))
        coeffs = foldl (\cs z -> zipPad cs (0 : map (negate z *) cs)) [1]
        zipPad [] ys = ys; zipPad xs [] = xs; zipPad (x : xs) (y : ys) = (x + y) : zipPad xs ys
        numerator = map (* (dk :+ 0)) (coeffs dz)
        denominator = coeffs dp
    require (all (\p -> magnitude p < 1) dp) "designed digital filter is unstable"
    require
        (all (\z -> abs (imagPart z) <= 1e-8 * max 1 (abs (realPart z))) (numerator ++ denominator))
        "filter coefficients lost conjugate symmetry"
    iir (map realPart numerator) (map realPart denominator)

prototype :: FilterFamily -> Int -> Either MathError ([Complex Double], [Complex Double], Double)
prototype family n = case family of
    Butterworth ->
        let poles = [cis (pi * (2 * fromIntegral k + fromIntegral n + 1) / (2 * fromIntegral n)) | k <- [0 .. n - 1]]
         in Right ([], poles, realPart (product (map negate poles)))
    ChebyshevI ripple -> do
        require
            (finite ripple && ripple > 0 && ripple <= 100)
            "Chebyshev I ripple must be positive <=100 dB"
        let eps = sqrt (10 ** (ripple / 10) - 1)
            mu = asinh (1 / eps) / fromIntegral n
            poles =
                [ let theta = pi * fromIntegral (2 * k + 1) / (2 * fromIntegral n)
                   in (-sinh mu * sin theta) :+ (cosh mu * cos theta)
                | k <- [0 .. n - 1]
                ]
            gain = realPart (product (map negate poles)) / (if even n then sqrt (1 + eps * eps) else 1)
        Right ([], poles, gain)
    ChebyshevII attenuation -> do
        require
            (finite attenuation && attenuation > 0 && attenuation <= 300)
            "Chebyshev II attenuation must be positive <=300 dB"
        let mu = asinh (sqrt (10 ** (attenuation / 10) - 1)) / fromIntegral n
            poles =
                [ recip ((-sinh mu * sin theta) :+ (cosh mu * cos theta))
                | k <- [0 .. n - 1]
                , let theta = pi * fromIntegral (2 * k + 1) / (2 * fromIntegral n)
                ]
            zeros =
                [ 0 :+ (1 / cos theta)
                | k <- [0 .. n - 1]
                , 2 * k + 1 /= n
                , let theta = pi * fromIntegral (2 * k + 1) / (2 * fromIntegral n)
                ]
        Right (zeros, poles, realPart (product (map negate poles) / product (map negate zeros)))
    Elliptic ripple attenuation -> do
        require
            (finite ripple && finite attenuation && ripple > 0 && attenuation > ripple && attenuation <= 150)
            "elliptic requires 0<ripple<attenuation<=150 dB"
        let eps = sqrt (10 ** (ripple / 10) - 1); m1 = eps * eps / (10 ** (attenuation / 10) - 1)
        require (m1 > 1e-14 && m1 < 1) "elliptic selectivity outside reference precision"
        k1 <- completeK m1
        k1p <- completeK (1 - m1)
        let q = exp (-pi * k1p / k1 / fromIntegral n)
            theta2 = 2 * q ** 0.25 * sum [q ** fromIntegral (j * (j + 1)) | j <- [0 .. 100 :: Int]]
            theta3 = 1 + 2 * sum [q ** fromIntegral (j * j) | j <- [1 .. 100 :: Int]]
            m = (theta2 / theta3) ^ (4 :: Int)
        require (m > 0 && m < 1 - 1e-12) "elliptic degree equation ill-conditioned"
        kk <- completeK m
        inverseSC <- SF.sfValue <$> SF.ellipticF (atan (1 / eps)) (1 - m1)
        let v0 = kk * inverseSC / (fromIntegral n * k1)
        (sv, cv, dv) <- SF.jacobiElliptic v0 (1 - m)
        triples <-
            mapM
                (\j -> SF.jacobiElliptic (fromIntegral j * kk / fromIntegral n) m)
                [1 - n `mod` 2, 3 - n `mod` 2 .. n - 1]
        let positiveZeros = [0 :+ (1 / (sqrt m * s)) | (s, _, _) <- triples, abs s > 1e-14]
            zeros = positiveZeros ++ map conjugate positiveZeros
            halfPoles =
                [negate ((c * d * sv * cv) :+ (s * dv)) / ((1 - (d * sv) ^ (2 :: Int)) :+ 0) | (s, c, d) <- triples]
            poles = halfPoles ++ map conjugate [p | p <- halfPoles, abs (imagPart p) > 1e-12]
            gain =
                realPart (product (map negate poles) / product (map negate zeros))
                    / (if even n then sqrt (1 + eps * eps) else 1)
        require (length poles == n) "elliptic pole count mismatch"
        Right (zeros, poles, gain)
    Bessel -> do
        let factorial k = product [1 .. fromIntegral k] :: Double
            cs =
                [ factorial (2 * n - k) / (2 ** fromIntegral (n - k) * factorial k * factorial (n - k)) :+ 0
                | k <- [0 .. n]
                ]
        poles <- P.aberthEhrlich 2000 1e-11 (P.polynomial cs)
        require (all ((< 0) . realPart) poles) "Bessel root solver returned nonstable pole"
        Right ([], poles, realPart (product (map negate poles)))
  where
    completeK m = do
        require (finite m && m >= 0 && m < 1) "elliptic K parameter"
        let loop 0 _ _ = Left (NonConvergence "elliptic AGM" 100)
            loop k a b =
                if abs (a - b) <= 1e-15 * a then Right (pi / (2 * a)) else loop (k - 1) ((a + b) / 2) (sqrt (a * b))
        loop (100 :: Int) 1 (sqrt (1 - m))

-- | Second-order notch or unity-magnitude all-pass with center omega in (0,pi) and positive quality factor Q.
notch, allPass :: Double -> Double -> Either MathError Filter
notch omega quality = do
    require
        (finite omega && omega > 0 && omega < pi && finite quality && quality > 0)
        "invalid notch frequency/Q"
    let alpha = sin omega / (2 * quality); c = cos omega
    iir [1, -2 * c, 1] [1 + alpha, -2 * c, 1 - alpha]
allPass omega quality = do
    require
        (finite omega && omega > 0 && omega < pi && finite quality && quality > 0)
        "invalid all-pass frequency/Q"
    let alpha = sin omega / (2 * quality); c = cos omega
    iir [1 - alpha, -2 * c, 1 + alpha] [1 + alpha, -2 * c, 1 - alpha]

-- | Causal zero-state box FIR with supplied width; initial outputs include implicit leading zeros.
movingAverage :: Int -> [Double] -> Either MathError [Double]
movingAverage count xs = do
    require (count > 0 && count <= 257) "moving average width must be 1..257"
    f <- fir (replicate count (1 / fromIntegral count))
    fst <$> filterSignal f xs

{- | Centered finite filters clamp sample indices at endpoints (replicate
padding), preserve output length, and require odd positive support widths.
-}
localFilter :: Int -> ([Double] -> Either MathError Double) -> [Double] -> Either MathError [Double]
localFilter width f xs = do
    require
        (width > 0 && odd width && width <= 1025 && not (null xs))
        "invalid centered filter width/data"
    _ <- vector xs
    let radius = width `div` 2
    mapM
        (\i -> f [xs !! max 0 (min (length xs - 1) (i + j)) | j <- [-radius .. radius]])
        [0 .. length xs - 1]

-- | Centered odd-width running median using replicate endpoint padding.
medianFilter :: Int -> [Double] -> Either MathError [Double]
medianFilter width = localFilter width (\ys -> Right (sort ys !! (length ys `div` 2)))

-- | Centered normalized Gaussian convolution with supplied sigma in samples and odd support width.
gaussianFilter :: Int -> Double -> [Double] -> Either MathError [Double]
gaussianFilter width sigma xs = do
    require (finite sigma && sigma > 0) "Gaussian sigma must be positive"
    let r = width `div` 2; weights = [exp (-0.5 * (fromIntegral j / sigma) ^ (2 :: Int)) | j <- [-r .. r]]
    localFilter width (checked . (/ sum weights) . dot weights) xs

-- | Centered local QR polynomial fit; choose width, degree, derivative order and positive sample spacing.
savitzkyGolay :: Int -> Int -> Int -> Double -> [Double] -> Either MathError [Double]
savitzkyGolay width degree derivative spacing xs = do
    require
        ( degree >= 0
            && degree < width
            && degree <= 16
            && derivative >= 0
            && derivative <= degree
            && finite spacing
            && spacing > 0
        )
        "invalid Savitzky-Golay polynomial/derivative/spacing"
    let r = width `div` 2
        coordinates = [fromIntegral j * spacing | j <- [-r .. r]]
        factorial = product [1 .. fromIntegral derivative]
    localFilter
        width
        ( \ys -> do
            fit <- I.polynomialFit degree (zip coordinates ys)
            checked (factorial * (I.approximationCoefficients fit !! derivative))
        )
        xs

-- | Local mean/variance Wiener shrinkage; optional noise variance, otherwise average local variance is estimated.
wiener :: Int -> Maybe Double -> [Double] -> Either MathError [Double]
wiener width noise xs = do
    means <- localFilter width (\ys -> checked (sum ys / fromIntegral (length ys))) xs
    variances <-
        localFilter
            width
            ( \ys ->
                let m = sum ys / fromIntegral (length ys)
                 in checked (sum [(y - m) ^ (2 :: Int) | y <- ys] / fromIntegral (length ys))
            )
            xs
    let nv = maybe (sum variances / fromIntegral (length variances)) id noise
    require (finite nv && nv >= 0) "Wiener noise variance must be nonnegative"
    vector (zipWith3 (\x m v -> m + (x - m) * (if v <= nv then 0 else 1 - nv / v)) xs means variances)

-- | Symmetric endpoint-inclusive windows, with shape parameters beta/sigma/alpha/attenuation as appropriate.
data Window
    = Hann
    | Hamming
    | Blackman
    | Bartlett
    | Kaiser Double
    | Gaussian Double
    | Tukey Double
    | FlatTop
    | DolphChebyshev Double
    deriving (Eq, Show)

-- | Generate a finite symmetric window. Gaussian sigma is relative to half length; Dolph attenuation is in dB.
window :: Window -> Int -> Either MathError [Double]
window kind n = do
    require (n > 0 && n <= 65536) "window length must be 1..65536"
    case kind of
        Kaiser b -> require (finite b && b >= 0 && b <= 100) "Kaiser beta 0..100"
        Gaussian s -> require (finite s && s > 0) "Gaussian window sigma positive"
        Tukey a -> require (finite a && a >= 0 && a <= 1) "Tukey alpha 0..1"
        DolphChebyshev db -> require (finite db && db > 0 && db <= 300 && n <= 4096) "Dolph-Chebyshev attenuation/length"
        _ -> Right ()
    if n == 1
        then Right [1]
        else do
            let m = fromIntegral (n - 1)
                theta j = 2 * pi * fromIntegral j / m
                i0 z = sum (take 100 (scanl (\t k -> t * z * z / (4 * fromIntegral (k * k))) 1 [1 .. 99 :: Int]))
                cheb degree x
                    | abs x <= 1 = cos (fromIntegral degree * acos x)
                    | x > 1 = cosh (fromIntegral degree * acosh x)
                    | otherwise = (if even degree then 1 else -1) * cosh (fromIntegral degree * acosh (-x))
                coefficient j =
                    let x = theta j; t = fromIntegral j / m; center = (2 * fromIntegral j - m) / m
                     in case kind of
                            Hann -> 0.5 - 0.5 * cos x
                            Hamming -> 0.54 - 0.46 * cos x
                            Blackman -> 0.42 - 0.5 * cos x + 0.08 * cos (2 * x)
                            Bartlett -> 1 - abs center
                            Kaiser b -> i0 (b * sqrt (max 0 (1 - center * center))) / i0 b
                            Gaussian sigma -> exp (-0.5 * (center / sigma) ^ (2 :: Int))
                            Tukey alpha
                                | alpha == 0 -> 1
                                | t < alpha / 2 -> 0.5 * (1 + cos (pi * (2 * t / alpha - 1)))
                                | t > 1 - alpha / 2 -> 0.5 * (1 + cos (pi * (2 * t / alpha - 2 / alpha + 1)))
                                | otherwise -> 1
                            FlatTop ->
                                0.21557895
                                    - 0.41663158 * cos x
                                    + 0.277263158 * cos (2 * x)
                                    - 0.083578947 * cos (3 * x)
                                    + 0.006947368 * cos (4 * x)
                            DolphChebyshev db ->
                                let beta = cosh (acosh (10 ** (db / 20)) / m)
                                 in sum
                                        [ cheb (n - 1) (beta * cos (pi * fromIntegral k / fromIntegral n))
                                            * cos (2 * pi * fromIntegral k * (fromIntegral j - m / 2) / fromIntegral n)
                                        | k <- [0 .. n - 1]
                                        ]
                                        / fromIntegral n
                raw = map coefficient [0 .. n - 1]
                result = case kind of DolphChebyshev _ -> let scale = maximum (map abs raw) in map (/ scale) raw; _ -> raw
            vector result

windowedSinc :: Window -> Int -> Double -> Double -> Either MathError [Double]
windowedSinc kind taps cutoff rate = do
    require
        ( taps > 0
            && odd taps
            && taps <= 257
            && finite rate
            && rate > 0
            && finite cutoff
            && cutoff > 0
            && cutoff < rate / 2
        )
        "invalid windowed-sinc taps/cutoff/rate"
    weights <- window kind taps
    let center = taps `div` 2
        fc = cutoff / rate
        raw =
            zipWith
                (\w j -> w * (if j == 0 then 2 * fc else sin (2 * pi * fc * fromIntegral j) / (pi * fromIntegral j)))
                weights
                [-center .. center]
        scale = sum raw
    require (scale /= 0 && finite scale) "windowed sinc has zero/overflow DC gain"
    vector (map (/ scale) raw)

-- | Select indices congruent to offset modulo factor; this primitive performs no implicit anti-alias filtering.
downsample :: Int -> Int -> [Double] -> Either MathError [Double]
downsample factor offset xs = do
    require
        (factor > 0 && offset >= 0 && offset < factor && all finite xs)
        "invalid decimation factor/offset/data"
    Right [x | (i, x) <- zip [0 :: Int ..] xs, i `mod` factor == offset]

-- | Insert factor-1 zeros after each sample, with a checked 1048576-element output budget.
upsample :: Int -> [Double] -> Either MathError [Double]
upsample factor xs = do
    require
        (factor > 0 && toInteger factor * toInteger (length xs) <= 1048576 && all finite xs)
        "invalid upsampling factor/output budget"
    Right (concatMap (\x -> x : replicate (factor - 1) 0) xs)

{- | Zero-extended centered polyphase FIR resampling. Only nonzero upsampled
phases are evaluated. Output has ceiling(N*up/down) samples, no group delay.
Kernel has odd length and is centered at index length/2; gain includes up.
-}
resamplePolyphase :: Int -> Int -> [Double] -> [Double] -> Either MathError [Double]
resamplePolyphase up down kernel xs = do
    require
        ( up > 0
            && down > 0
            && not (null kernel)
            && odd (length kernel)
            && toInteger (length xs) * toInteger up <= 1048576
        )
        "invalid polyphase resampling factors/kernel/budget"
    _ <- vector (kernel ++ xs)
    let output = (toInteger (length xs) * toInteger up + toInteger down - 1) `div` toInteger down
        center = length kernel `div` 2
        at k =
            sum
                [ fromIntegral up * x * (kernel !! j)
                | (i, x) <- zip [0 ..] xs
                , let j = k * down - i * up + center
                , j >= 0
                , j < length kernel
                ]
    vector (map at [0 .. fromInteger output - 1])

-- | Construct a Kaiser-windowed anti-alias/interpolation FIR, then evaluate only the necessary rational polyphase taps.
resample :: Int -> Int -> Int -> [Double] -> Either MathError [Double]
resample up down taps xs = do
    require (up > 0 && down > 0 && up <= 1024 && down <= 1024) "invalid resampling factors"
    let cutoff = 0.45 / fromIntegral (max up down)
    kernel <- windowedSinc (Kaiser 8) taps cutoff 1
    resamplePolyphase up down kernel xs

-- | Centered replicate-padded low-pass before decimation by factor; cutoff is 0.45/factor cycles/sample.
antiAlias :: Int -> Int -> [Double] -> Either MathError [Double]
antiAlias factor taps xs = do
    require (factor > 1) "anti-alias factor must exceed one"
    kernel <- windowedSinc (Kaiser 8) taps (0.45 / fromIntegral factor) 1
    -- Centered replicate-padded convolution, followed by explicit decimation.
    localFilter taps (checked . dot kernel) xs

-- | Interior peak index, height, topographic prominence and half-prominence width in samples.
data Peak = Peak {peakIndex :: Int, peakHeight :: Double, peakProminence :: Double, peakWidth :: Double}
    deriving (Eq, Show)

{- | Interior local maxima; flat plateaus select the lower middle index. Width
is linearly interpolated at half prominence; endpoints are not peaks.
-}
peaks :: Double -> Int -> [Double] -> Either MathError [Peak]
peaks minimumProminence minimumDistance xs = do
    require
        (finite minimumProminence && minimumProminence >= 0 && minimumDistance >= 1 && all finite xs)
        "invalid peak criteria/data"
    let n = length xs
        candidates =
            [ (i, j)
            | i <- [1 .. n - 2]
            , xs !! i > xs !! (i - 1)
            , let j = i + length (takeWhile (== xs !! i) (drop (i + 1) xs))
            , j < n - 1
            , xs !! j > xs !! (j + 1)
            ]
        make (start, end) =
            let i = (start + end) `div` 2
                h = xs !! i
                left = reverse (take start xs)
                right = drop (end + 1) xs
                leftB = minimum (h : takeWhile (<= h) left)
                rightB = minimum (h : takeWhile (<= h) right)
                prominence = h - max leftB rightB
                level = h - prominence / 2
                l = last (0 : [j | j <- [0 .. start - 1], xs !! j <= level])
                r = case [j | j <- [end + 1 .. n - 1], xs !! j <= level] of j : _ -> j; [] -> n - 1
                interpolateCross a b =
                    if xs !! a == xs !! b
                        then fromIntegral a
                        else fromIntegral a + (level - xs !! a) / (xs !! b - xs !! a) * fromIntegral (b - a)
                width = interpolateCross (r - 1) r - interpolateCross l (l + 1)
             in Peak i h prominence (max 0 width)
        ranked = sortByHeight (filter ((>= minimumProminence) . peakProminence) (map make candidates))
        accepted =
            foldl
                ( \acc p -> if all (\q -> abs (peakIndex p - peakIndex q) >= minimumDistance) acc then p : acc else acc
                )
                []
                ranked
    _ <- vector (concat [[peakHeight p, peakProminence p, peakWidth p] | p <- accepted])
    Right (sortByIndex accepted)
  where
    sortByHeight = reverse . sortOnHeight
    sortOnHeight =
        sortByLocal
            (\a b -> compare (peakHeight a, negate (peakIndex a)) (peakHeight b, negate (peakIndex b)))
    sortByIndex = sortByLocal (\a b -> compare (peakIndex a) (peakIndex b))
    sortByLocal _ [] = []
    sortByLocal compareValues (p : ps) =
        sortByLocal compareValues [x | x <- ps, compareValues x p == LT]
            ++ [p]
            ++ sortByLocal compareValues [x | x <- ps, compareValues x p /= LT]

-- | Interpolated opposite-sign transitions; zero plateaus count once, leading/trailing zeros are ignored.
zeroCrossings :: [Double] -> Either MathError [Double]
zeroCrossings xs = do
    _ <- vector xs
    -- Exact zero plateaus count once, located at their first zero if a sign
    -- change occurs across the plateau; leading/trailing zeros are ignored.
    let nonzero = [(i, x) | (i, x) <- zip [0 :: Int ..] xs, x /= 0]
    let crossing a b = let scale = max (abs a) (abs b); aa = abs a / scale; bb = abs b / scale in aa / (aa + bb)
    vector
        [ if j == i + 1 then fromIntegral i + crossing a b else fromIntegral (i + 1)
        | ((i, a), (j, b)) <- zip nonzero (drop 1 nonzero)
        , (a < 0 && b > 0) || (a > 0 && b < 0)
        ]

-- | Magnitude of the periodic analytic-signal representation.
envelope :: [Double] -> Either MathError [Double]
envelope xs = map magnitude <$> F.analyticSignal xs

-- | Remove nearest multiples of 2*pi from adjacent phase jumps; reject overflowing finite differences before integer conversion.
unwrapPhase :: [Double] -> Either MathError [Double]
unwrapPhase xs = do
    _ <- vector xs
    case xs of
        [] -> Right []
        x : rest -> do
            let step (acc, previous, offset) v = do
                    delta <- checked (v - previous)
                    let wrapped = delta - 2 * pi * fromIntegral (floor ((delta + pi) / (2 * pi)) :: Integer)
                        shift = if wrapped == (-pi) && delta > 0 then pi - delta else wrapped - delta
                    next <- checked (offset + shift)
                    value <- checked (v + next)
                    Right (value : acc, v, next)
            (ys, _, _) <- foldM step ([x], x, 0) rest
            vector (reverse ys)

-- | Subtract a constant mean or a fitted linear trend in sample index.
detrend :: Bool -> [Double] -> Either MathError [Double]
detrend linear xs = do
    require (not (null xs)) "detrend needs samples"
    _ <- vector xs
    let n = fromIntegral (length xs); mean = sum (map (/ n) xs)
    if not linear || length xs == 1
        then vector (map (subtract mean) xs)
        else do
            fit <- I.polynomialFit 1 (zip [0 ..] xs)
            let cs = I.approximationCoefficients fit
            vector [x - cs !! 0 - cs !! 1 * fromIntegral j | (j, x) <- zip [0 :: Int ..] xs]

-- | Divide by maximum absolute amplitude; reject an empty or identically zero signal.
normalize :: [Double] -> Either MathError [Double]
normalize xs = do
    require (not (null xs)) "normalization needs samples"
    _ <- vector xs
    let scale = maximum (map abs xs)
    require (scale > 0) "cannot normalize zero signal"
    vector (map (/ scale) xs)

-- | Centered odd-width arithmetic mean with replicate endpoint padding.
smooth :: Int -> [Double] -> Either MathError [Double]
smooth width = localFilter width (\ys -> checked (sum ys / fromIntegral (length ys)))

-- | Robust Gaussian noise sigma from median absolute adjacent differences divided by sqrt(2)*Phi^-1(0.75).
noiseEstimate :: [Double] -> Either MathError Double
noiseEstimate xs = do
    require (length xs >= 2) "noise estimate needs two samples"
    _ <- vector xs
    let differences = zipWith (\a b -> abs (b - a)) xs (drop 1 xs)
    _ <- vector differences
    checked (sort differences !! (length differences `div` 2) / (0.6744897501960817 * sqrt 2))

-- | 20*(log10(signal RMS)-log10(noise RMS)) in dB; both energies must be positive.
signalToNoise :: [Double] -> [Double] -> Either MathError Double
signalToNoise signal noise = do
    require (length signal == length noise && not (null signal)) "SNR length mismatch/empty"
    s <- rms signal
    n <- rms noise
    require (s > 0 && n > 0) "SNR requires positive signal and noise energies"
    checked (20 * (logBase 10 s - logBase 10 n))

-- | Scaled root-mean-square calculation that avoids overflow when the RMS itself is representable.
rms :: [Double] -> Either MathError Double
rms xs = do
    require (not (null xs)) "RMS requires samples"
    _ <- vector xs
    let scale = maximum (map abs xs)
    checked
        ( if scale == 0
            then 0
            else scale * sqrt (sum [(x / scale) ^ (2 :: Int) | x <- xs] / fromIntegral (length xs))
        )

{- | Mean and symmetric positive semidefinite covariance, dimension 1..64.
User-supplied transition/measurement callbacks must be finite, pure and total.
-}
data GaussianState = GaussianState [Double] [[Double]] deriving (Eq, Show)

{- | Validate a mean and symmetric positive semidefinite covariance; Cholesky
roundoff tolerance is 1e-12*max(1,diagonal). Accepted tiny negative pivots
are clipped, and the stored covariance is reconstructed from that factor.
Thus a tolerated negative input variance never escapes through stateCovariance.
-}
gaussianState :: [Double] -> [[Double]] -> Either MathError GaussianState
gaussianState mean covariance = do
    require (not (null mean) && length mean <= 64) "Gaussian state dimension must be 1..64"
    _ <- vector mean
    factor <- covarianceCheck (length mean) covariance
    let accepted = mm factor (tr factor)
    _ <- vector (concat accepted)
    Right (GaussianState mean accepted)

-- | Read the posterior mean vector.
stateMean :: GaussianState -> [Double]
stateMean (GaussianState mean _) = mean

-- | Read the symmetric posterior covariance matrix.
stateCovariance :: GaussianState -> [[Double]]
stateCovariance (GaussianState _ covariance) = covariance

symmetrize :: [[Double]] -> [[Double]]
symmetrize a = zipWith (zipWith (\x y -> x / 2 + y / 2)) a (tr a)
matrixCheck :: Int -> Int -> [[Double]] -> Either MathError ()
matrixCheck rows cols a = do
    require
        (rows > 0 && cols > 0 && rows <= 64 && cols <= 64 && length a == rows && all ((== cols) . length) a)
        "invalid Kalman matrix dimensions (1..64)"
    _ <- vector (concat a)
    Right ()
covarianceCheck :: Int -> [[Double]] -> Either MathError [[Double]]
covarianceCheck n a = do
    matrixCheck n n a
    require
        ( and
            [ abs (a !! i !! j - a !! j !! i) <= 1e-10 * max 1 (max (abs (a !! i !! j)) (abs (a !! j !! i)))
            | i <- [0 .. n - 1]
            , j <- [0 .. i - 1]
            ]
        )
        "covariance must be symmetric"
    cholesky a
cholesky :: [[Double]] -> Either MathError [[Double]]
cholesky a = foldM row [] [0 .. length a - 1]
  where
    row previous i = do
        values <- foldM (entry previous i) [] [0 .. i]
        Right (previous ++ [values ++ replicate (length a - i - 1) 0])
    entry previous i current j = do
        let residual =
                a !! i !! j
                    - sum [current !! k * (if j == i then current !! k else previous !! j !! k) | k <- [0 .. j - 1]]
            scale = 1e-12 * max 1 (abs (a !! i !! i))
        value <-
            if i == j
                then if residual < (-scale) then Left (NotPositiveDefinite i) else checked (sqrt (max 0 residual))
                else
                    let pivot = previous !! j !! j
                     in if pivot == 0
                            then require (abs residual <= scale) "singular inconsistent covariance" >> Right 0
                            else checked (residual / pivot)
        Right (current ++ [value])
addM, subM :: [[Double]] -> [[Double]] -> [[Double]]
addM = zipWith (zipWith (+))
subM = zipWith (zipWith (-))
outer :: [Double] -> [Double] -> [[Double]]
outer x y = [map (a *) y | a <- x]
solveRight :: [[Double]] -> [[Double]] -> Either MathError [[Double]]
solveRight numerator denominator = mapM (solve (tr denominator)) numerator

{- | One linear Gaussian prediction+measurement update. Uses Joseph covariance
update to preserve positive semidefiniteness under roundoff.
-}
kalman ::
    [[Double]] ->
    [[Double]] ->
    [[Double]] ->
    [[Double]] ->
    [Double] ->
    GaussianState ->
    Either MathError GaussianState
kalman transition observation processNoise measurementNoise measured (GaussianState mean covariance) = do
    let n = length mean; m = length measured
    matrixCheck n n transition
    matrixCheck m n observation
    _ <- covarianceCheck n processNoise
    _ <- covarianceCheck m measurementNoise
    _ <- vector measured
    let predicted = mv transition mean
        pp = addM (mm (mm transition covariance) (tr transition)) processNoise
    linearUpdate observation measurementNoise measured predicted pp

linearUpdate ::
    [[Double]] -> [[Double]] -> [Double] -> [Double] -> [[Double]] -> Either MathError GaussianState
linearUpdate h r measured predicted pp = do
    let innovation = zipWith (-) measured (mv h predicted)
        pht = mm pp (tr h)
        s = addM (mm h pht) r
    gain <- solveRight pht s
    let next = zipWith (+) predicted (mv gain innovation)
        factor = subM (eye (length predicted)) (mm gain h)
        covariance = addM (mm (mm factor pp) (tr factor)) (mm (mm gain r) (tr gain))
    gaussianState next covariance

jacobianFinite :: ([Double] -> [Double]) -> [Double] -> Int -> Either MathError [[Double]]
jacobianFinite f point output = do
    columns <-
        mapM
            ( \j -> do
                let h = 1e-5 * max 1 (abs (point !! j))
                    plus = f (replace j (point !! j + h) point)
                    minus = f (replace j (point !! j - h) point)
                require (length plus == output && length minus == output) "Kalman callback changed dimension"
                vector (zipWith (\a b -> (a - b) / (2 * h)) plus minus)
            )
            [0 .. length point - 1]
    Right (tr columns)

-- | EKF with checked central-difference Jacobians (step 1e-5*max(1,abs x)).
extendedKalman ::
    ([Double] -> [Double]) ->
    ([Double] -> [Double]) ->
    [[Double]] ->
    [[Double]] ->
    [Double] ->
    GaussianState ->
    Either MathError GaussianState
extendedKalman transition measurement q r measured (GaussianState mean covariance) = do
    let n = length mean; m = length measured; predicted = transition mean
    require (length predicted == n && m > 0) "EKF callback/output dimension mismatch"
    _ <- vector (predicted ++ measured)
    _ <- covarianceCheck n q
    _ <- covarianceCheck m r
    f <- jacobianFinite transition mean n
    h <- jacobianFinite measurement predicted m
    let expected = measurement predicted
    require (length expected == m) "EKF observation dimension mismatch"
    _ <- vector expected
    let pp = addM (mm (mm f covariance) (tr f)) q
        -- linearUpdate subtracts H*x, so shift observed data by H*x-h(x).
        adjusted = zipWith3 (\z linear nonlinear -> z + linear - nonlinear) measured (mv h predicted) expected
    linearUpdate h r adjusted predicted pp

{- | Scaled UKF. alpha>0, beta>=0, n+kappa>0, lambda+n>0. Process
noise is incorporated before regenerating measurement sigma points.
-}
unscentedKalman ::
    Double ->
    Double ->
    Double ->
    ([Double] -> [Double]) ->
    ([Double] -> [Double]) ->
    [[Double]] ->
    [[Double]] ->
    [Double] ->
    GaussianState ->
    Either MathError GaussianState
unscentedKalman alpha beta kappa transition measurement q r measured state = do
    let n = length (stateMean state)
        m = length measured
        lambda = alpha * alpha * (fromIntegral n + kappa) - fromIntegral n
        c = fromIntegral n + lambda
    require
        (all finite [alpha, beta, kappa, c] && alpha > 0 && beta >= 0 && c > 1e-12 && m > 0)
        "invalid UKF scaling/output dimension"
    _ <- covarianceCheck n q
    _ <- covarianceCheck m r
    _ <- vector measured
    let weightsMean = lambda / c : replicate (2 * n) (1 / (2 * c))
        weightsCov = (lambda / c + 1 - alpha * alpha + beta) : replicate (2 * n) (1 / (2 * c))
        sigma (GaussianState mu p) = do
            l <- covarianceCheck n p
            let columns = map (map (sqrt c *)) (tr l)
            Right (mu : [zipWith (+) mu col | col <- columns] ++ [zipWith (-) mu col | col <- columns])
        transform output f points = do
            let values = map f points
            require (all ((== output) . length) values) "UKF callback changed dimension"
            _ <- vector (concat values)
            let mu = mv (tr values) weightsMean
                covariance =
                    foldl
                        addM
                        (replicate output (replicate output 0))
                        [map (map (w *)) (outer (zipWith (-) v mu) (zipWith (-) v mu)) | (w, v) <- zip weightsCov values]
            _ <- vector (mu ++ concat covariance)
            Right (mu, covariance, values)
    points <- sigma state
    (pm, p0, _) <- transform n transition points
    predicted <- gaussianState pm (addM p0 q)
    observedPoints <- sigma predicted
    (zm, s0, zvalues) <- transform m measurement observedPoints
    let innovationCov = addM s0 r
        cross =
            foldl
                addM
                (replicate n (replicate m 0))
                [ map (map (w *)) (outer (zipWith (-) x pm) (zipWith (-) z zm))
                | (w, (x, z)) <- zip weightsCov (zip observedPoints zvalues)
                ]
    gain <- solveRight cross innovationCov
    let mean = zipWith (+) pm (mv gain (zipWith (-) measured zm))
        covariance = subM (stateCovariance predicted) (mm (mm gain innovationCov) (tr gain))
    gaussianState mean (symmetrize covariance)

{- | Orthogonal Haar, 4-tap db2, 8-tap db4, and reversible CDF 5/3 lifting.
CDF coefficients use the unnormalized lifting convention (constant detail=0).
-}
data Wavelet = Haar | Daubechies2 | Daubechies4 | Biorthogonal53 deriving (Eq, Show)

-- | Opaque multilevel approximation and detail coefficients, retaining family and original length.
data WaveletTree = WaveletTree Wavelet Int [Double] [[Double]] deriving (Eq, Show)

-- | Coarsest approximation coefficients after all requested levels.
waveletApproximation :: WaveletTree -> [Double]
waveletApproximation (WaveletTree _ _ a _) = a

-- | Detail bands ordered from finest first to coarsest last.
waveletDetails :: WaveletTree -> [[Double]]
waveletDetails (WaveletTree _ _ _ d) = d

waveletLow :: Wavelet -> [Double]
waveletLow Haar = [1 / sqrt 2, 1 / sqrt 2]
waveletLow Daubechies2 =
    [ (1 + sqrt 3) / (4 * sqrt 2)
    , (3 + sqrt 3) / (4 * sqrt 2)
    , (3 - sqrt 3) / (4 * sqrt 2)
    , (1 - sqrt 3) / (4 * sqrt 2)
    ]
waveletLow Daubechies4 =
    [ 0.2303778133088965
    , 0.7148465705529154
    , 0.6308807679298587
    , -0.02798376941685985
    , -0.1870348117190931
    , 0.03084138183556076
    , 0.0328830116668852
    , -0.01059740178506903
    ]
waveletLow Biorthogonal53 = []
waveletStep :: Wavelet -> [Double] -> ([Double], [Double])
waveletStep Biorthogonal53 xs =
    let n = length xs `div` 2
        e = [xs !! (2 * i) | i <- [0 .. n - 1]]
        o = [xs !! (2 * i + 1) | i <- [0 .. n - 1]]
        d = [o !! i - (e !! i + e !! ((i + 1) `mod` n)) / 2 | i <- [0 .. n - 1]]
        a = [e !! i + (d !! ((i - 1) `mod` n) + d !! i) / 4 | i <- [0 .. n - 1]]
     in (a, d)
waveletStep family xs =
    let n = length xs
        lo = waveletLow family
        hi = zipWith (\j h -> if even j then h else -h) [0 :: Int ..] (reverse lo)
        apply kernel = [sum [h * xs !! ((2 * i + j) `mod` n) | (j, h) <- zip [0 ..] kernel] | i <- [0 .. n `div` 2 - 1]]
     in (apply lo, apply hi)
inverseStep :: Wavelet -> [Double] -> [Double] -> [Double]
inverseStep Biorthogonal53 a d =
    let n = length a
        e = [a !! i - (d !! ((i - 1) `mod` n) + d !! i) / 4 | i <- [0 .. n - 1]]
        o = [d !! i + (e !! i + e !! ((i + 1) `mod` n)) / 2 | i <- [0 .. n - 1]]
     in concat (zipWith (\x y -> [x, y]) e o)
inverseStep family a d =
    let n = 2 * length a
        lo = waveletLow family
        hi = zipWith (\j h -> if even j then h else -h) [0 :: Int ..] (reverse lo)
     in [ sum
            [ a !! i * l + d !! i * h
            | (j, (l, h)) <- zip [0 ..] (zip lo hi)
            , let residue = (k - j) `mod` n
            , even residue
            , let i = residue `div` 2
            ]
        | k <- [0 .. n - 1]
        ]

-- | Periodic multilevel analysis; length must be divisible by 2^levels, with levels 0..20 and length <=1048576.
dwt :: Wavelet -> Int -> [Double] -> Either MathError WaveletTree
dwt family levels xs = do
    require
        ( levels >= 0
            && levels <= 20
            && not (null xs)
            && length xs <= 1048576
            && toInteger (length xs) `mod` (2 ^ levels :: Integer) == 0
        )
        "DWT length must be positive and divisible by 2^levels"
    _ <- vector xs
    let go 0 a details = Right (WaveletTree family (length xs) a (reverse details))
        go k a details = let (next, d) = waveletStep family a in vector (next ++ d) >> go (k - 1) next (d : details)
    go levels xs []

-- | Invert multilevel analysis using orthogonal synthesis or inverse CDF 5/3 lifting.
idwt :: WaveletTree -> Either MathError [Double]
idwt (WaveletTree family _ approximation details) = foldM (\a d -> vector (inverseStep family a d)) approximation (reverse details)

-- | Admissible corrected complex Morlet, real Mexican hat, or real first Gaussian derivative.
data MotherWavelet = Morlet Double | MexicanHat | GaussianDerivative deriving (Eq, Show)

{- | Direct zero-extended CWT. Scales are in seconds; coefficients use dt/sqrt(s)
quadrature. Morlet subtracts its nonzero-mean correction exp(-omega²/2).
-}
cwt :: MotherWavelet -> Double -> [Double] -> [Double] -> Either MathError [[Complex Double]]
cwt mother spacing scales xs = do
    require
        ( finite spacing
            && spacing > 0
            && not (null scales)
            && all (\s -> finite s && s > 0) scales
            && toInteger (length scales) * toInteger (length xs) ^ (2 :: Int) <= 20000000
        )
        "invalid CWT spacing/scales/work budget"
    _ <- vector xs
    case mother of
        Morlet omega -> require (finite omega && omega > 0 && omega <= 50) "Morlet omega must be 0..50"
        _ -> Right ()
    let psi t = case mother of
            Morlet omega -> ((exp (-t * t / 2) * pi ** (-0.25)) :+ 0) * (cis (omega * t) - (exp (-omega * omega / 2) :+ 0))
            MexicanHat -> (2 / (sqrt 3 * pi ** 0.25) * (1 - t * t) * exp (-t * t / 2)) :+ 0
            GaussianDerivative -> (-sqrt 2 * pi ** (-0.25) * t * exp (-t * t / 2)) :+ 0
        rows =
            [ [ sum
                    [ (x * spacing / sqrt scale :+ 0) * conjugate (psi (fromIntegral (j - b) * spacing / scale))
                    | (j, x) <- zip [0 ..] xs
                    ]
              | b <- [0 .. length xs - 1]
              ]
            | scale <- scales
            ]
    _ <- vector (concatMap (\row -> concatMap (\z -> [realPart z, imagPart z]) row) rows)
    Right rows

-- | Opaque complete binary low/high analysis tree in natural binary order, rather than frequency-sorted Gray order.
data WaveletPacket = PacketLeaf [Double] | PacketNode Wavelet WaveletPacket WaveletPacket
    deriving (Eq, Show)

-- | Recursively analyze both approximation and detail branches to the supplied depth.
waveletPackets :: Wavelet -> Int -> [Double] -> Either MathError WaveletPacket
waveletPackets family levels xs = do
    _ <- dwt family levels xs
    let go 0 values = PacketLeaf values
        go k values = let (a, d) = waveletStep family values in PacketNode family (go (k - 1) a) (go (k - 1) d)
    Right (go levels xs)

-- | Reconstruct a complete packet tree exactly up to floating roundoff.
inverseWaveletPackets :: WaveletPacket -> Either MathError [Double]
inverseWaveletPackets (PacketLeaf xs) = vector xs
inverseWaveletPackets (PacketNode family a d) = do aa <- inverseWaveletPackets a; dd <- inverseWaveletPackets d; vector (inverseStep family aa dd)

-- | Leaf coefficient bands in natural binary low/high tree order.
packetBands :: WaveletPacket -> [[Double]]
packetBands (PacketLeaf xs) = [xs]
packetBands (PacketNode _ a d) = packetBands a ++ packetBands d

-- | Soft-threshold detail coefficients; optional explicit threshold, otherwise finest-band MAD universal threshold.
waveletDenoise :: Wavelet -> Int -> Maybe Double -> [Double] -> Either MathError [Double]
waveletDenoise family levels threshold xs = do
    tree@(WaveletTree _ n a details) <- dwt family levels xs
    let sigma =
            if null details
                then 0
                else
                    let finest = map abs (details !! 0) in sort finest !! (length finest `div` 2) / 0.6744897501960817
        t = maybe (sigma * sqrt (2 * log (fromIntegral n))) id threshold
    require (finite t && t >= 0) "invalid wavelet threshold"
    if null details
        then idwt tree
        else idwt (WaveletTree family n a [[signum x * max 0 (abs x - t) | x <- d] | d <- details])
