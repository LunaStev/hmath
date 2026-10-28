-- SPDX-License-Identifier: MPL-2.0

{- | CPU reference Fourier transforms. Forward exponent is negative; inverse
exponent is positive and divided by N. ND data are contiguous row-major with
the last axis fastest. Plans are immutable, reusable and cache N roots; no
global cache or thread-local state is retained. Scalar transforms accept
1..65536 samples (direct quadratic transforms at most 4096).

DCT/DST I--IV use orthonormal matrices, so inverse means transpose. Definitions
follow <https://fftw.org/fftw3_doc/What-FFTW-Really-Computes.html> with explicit
endpoint weights added for orthogonality. Algorithms are reference CPU paths,
not hardware FFTW bindings.
-}
module HMath.Fourier (
    Direction (..),
    FFTAlgorithm (..),
    FFTPlan,
    planFFT,
    executeFFT,
    fft,
    ifft,
    dft,
    fftND,
    fftBatch,
    realFFT,
    inverseRealFFT,
    fftInPlace,
    frequencies,
    fftShift,
    ifftShift,
    TransformType (..),
    dct,
    idct,
    dst,
    idst,
    hartley,
    STFT,
    stft,
    stftFrames,
    istft,
    magnitudeSpectrum,
    phaseSpectrum,
    powerSpectrum,
    periodogram,
    welch,
    crossSpectrum,
    spectrogram,
    cepstrum,
    analyticSignal,
    hilbert,
    chirpZ,
    goertzel,
    fftConvolve,
    fftCorrelate,
) where

import Data.Complex (Complex ((:+)), cis, conjugate, imagPart, magnitude, phase, realPart)
import Foreign.Marshal.Array (peekArray, pokeArray)
import Foreign.Ptr (Ptr, nullPtr)
import HMath.Error (MathError (..))
import HMath.Signal.Internal (finite, require)

-- | Transform exponent convention; Inverse additionally divides by sample count.
data Direction = Forward | Inverse deriving (Eq, Show)

-- | Explicit reference factorization, or Automatic mixed-radix with Bluestein for larger prime factors.
data FFTAlgorithm = Automatic | Direct | Radix2 | Radix4 | MixedRadix | SplitRadix | Bluestein | Rader
    deriving (Eq, Show)

-- | Opaque immutable plan with cached unit-circle roots and a fixed input length.
data FFTPlan = FFTPlan Direction FFTAlgorithm Int [Complex Double] deriving (Eq, Show)

-- | Orthonormal cosine/sine basis type I, II, III or IV.
data TransformType = TypeI | TypeII | TypeIII | TypeIV deriving (Eq, Show)

finiteC :: Complex Double -> Bool
finiteC x = finite (realPart x) && finite (imagPart x)
checkC :: [Complex Double] -> Either MathError [Complex Double]
checkC xs = if all finiteC xs then Right xs else Left NonFiniteResult
powerOf :: Int -> Int -> Bool
powerOf r n | n == 1 = True | n < 1 || n `mod` r /= 0 = False | otherwise = powerOf r (n `div` r)
prime :: Int -> Bool
prime n = n >= 2 && all ((/= 0) . mod n) [2 .. floor (sqrt (fromIntegral n :: Double))]

-- | Create a reusable plan after checking length, prime or radix requirements. No input data or external buffers are retained.
planFFT :: Direction -> FFTAlgorithm -> Int -> Either MathError FFTPlan
planFFT direction method n = do
    require
        (n > 0 && n <= 65536 && (method /= Direct || n <= 4096))
        "FFT length outside reference budget"
    require
        (method /= Radix2 && method /= SplitRadix || powerOf 2 n)
        "radix-2/split-radix length must be a power of two"
    require (method /= Radix4 || powerOf 4 n) "radix-4 length must be a power of four"
    require (method /= Rader || prime n) "Rader length must be prime"
    let sign = if direction == Forward then -1 else 1
    Right
        ( FFTPlan
            direction
            method
            n
            [cis (sign * 2 * pi * fromIntegral k / fromIntegral n) | k <- [0 .. n - 1]]
        )

-- | Apply a plan to exactly its declared number of finite complex samples; reject nonfinite intermediate results.
executeFFT :: FFTPlan -> [Complex Double] -> Either MathError [Complex Double]
executeFFT (FFTPlan direction method n roots) xs = do
    require (length xs == n) "FFT plan/input length mismatch"
    _ <- checkC xs
    let raw = case method of
            Direct -> direct roots xs
            Radix2 -> radix 2 roots xs
            Radix4 -> radix 4 roots xs
            SplitRadix -> split roots xs
            Bluestein -> blue roots xs
            Rader -> rader roots xs
            _ -> mixed roots xs
        scaled = if direction == Inverse then map (/ (fromIntegral n :+ 0)) raw else raw
    checkC scaled
  where
    direct rs ys =
        [sum [y * (rs !! ((j * k) `mod` length ys)) | (j, y) <- zip [0 ..] ys] | k <- [0 .. length ys - 1]]
    radix r rs ys
        | length ys <= 1 = ys
        | otherwise =
            let m = length ys `div` r
                sub =
                    [ radix r [rs !! (r * j) | j <- [0 .. m - 1]] [ys !! (r * j + q) | j <- [0 .. m - 1]]
                    | q <- [0 .. r - 1]
                    ]
             in [ sum [sub !! q !! (k `mod` m) * (rs !! ((q * k) `mod` length ys)) | q <- [0 .. r - 1]]
                | k <- [0 .. length ys - 1]
                ]
    mixed rs ys
        | length ys <= 1 = ys
        | otherwise = case [p | p <- [2 .. floor (sqrt (fromIntegral (length ys) :: Double))], length ys `mod` p == 0] of
            [] -> if length ys <= 13 then direct rs ys else blue rs ys
            p : _ ->
                let m = length ys `div` p
                    sub =
                        [ mixed [rs !! (p * j) | j <- [0 .. m - 1]] [ys !! (p * j + q) | j <- [0 .. m - 1]]
                        | q <- [0 .. p - 1]
                        ]
                 in [ sum [sub !! q !! (k `mod` m) * (rs !! ((q * k) `mod` length ys)) | q <- [0 .. p - 1]]
                    | k <- [0 .. length ys - 1]
                    ]
    split rs ys
        | length ys <= 2 = direct rs ys
        | otherwise =
            let m = length ys `div` 4
                evenPart = split [rs !! (2 * j) | j <- [0 .. 2 * m - 1]] [ys !! (2 * j) | j <- [0 .. 2 * m - 1]]
                odd1 = split [rs !! (4 * j) | j <- [0 .. m - 1]] [ys !! (4 * j + 1) | j <- [0 .. m - 1]]
                odd3 = split [rs !! (4 * j) | j <- [0 .. m - 1]] [ys !! (4 * j + 3) | j <- [0 .. m - 1]]
             in [ evenPart !! (k `mod` (2 * m))
                    + (rs !! k) * (odd1 !! (k `mod` m))
                    + (rs !! ((3 * k) `mod` (4 * m))) * (odd3 !! (k `mod` m))
                | k <- [0 .. 4 * m - 1]
                ]
    -- Bluestein writes jk=(j²+k²-(j-k)²)/2 and uses padded convolution.
    blue _ [y] = [y]
    blue rs ys =
        let len = length ys
            sign = if imagPart (rs !! 1) <= 0 then -1 else 1
            chirp j = cis (sign * pi * fromIntegral (j * j) / fromIntegral len)
            m = until (>= 2 * len - 1) (* 2) 1
            a = zipWith (*) ys [chirp j | j <- [0 .. len - 1]] ++ replicate (m - len) 0
            b =
                [ if j < len then conjugate (chirp j) else if j > m - len then conjugate (chirp (m - j)) else 0
                | j <- [0 .. m - 1]
                ]
            conv = convolutionRaw a b
         in [conv !! k * chirp k | k <- [0 .. len - 1]]
    convolutionRaw a b =
        let m = length a
            rootsF = [cis (-2 * pi * fromIntegral j / fromIntegral m) | j <- [0 .. m - 1]]
            fa = radix 2 rootsF a
            fb = radix 2 rootsF b
         in map (/ (fromIntegral m :+ 0)) (radix 2 (map conjugate rootsF) (zipWith (*) fa fb))
    -- Primitive-root permutation reduces a prime DFT to cyclic correlation.
    rader rs ys
        | length ys == 2 = direct rs ys
        | otherwise =
            let p = length ys
                m = p - 1
                order generator = take m (iterate (\v -> v * generator `mod` p) 1)
                g = case [v | v <- [2 .. p - 1], all (\q -> powMod v (m `div` q) p /= 1) (primeDivisors m)] of
                    v : _ -> v
                    [] -> 1
                perm = order g
                a = [ys !! (perm !! ((-j) `mod` m)) | j <- [0 .. m - 1]]
                b = [rs !! k | k <- perm]
                rm =
                    [ cis ((if direction == Forward then -1 else 1) * 2 * pi * fromIntegral j / fromIntegral m)
                    | j <- [0 .. m - 1]
                    ]
                fa = mixed rm a
                fb = mixed rm b
                c = map (/ (fromIntegral m :+ 0)) (mixed (map conjugate rm) (zipWith (*) fa fb))
             in sum ys : [ys !! 0 + c !! index k perm | k <- [1 .. p - 1]]
    primeDivisors value = go value 2
      where
        go 1 _ = []
        go z q | q * q > z = [z] | z `mod` q == 0 = q : go (strip z q) (q + 1) | otherwise = go z (q + 1)
        strip z q | z `mod` q == 0 = strip (z `div` q) q | otherwise = z
    index k ps = length (takeWhile (/= k) ps)
    powMod a e m = go a e 1
      where
        go _ 0 z = z; go b k z = go (b * b `mod` m) (k `div` 2) (if odd k then z * b `mod` m else z)

-- | Automatic forward/inverse FFT and bounded direct forward DFT, respectively.
fft, ifft, dft :: [Complex Double] -> Either MathError [Complex Double]
fft xs = planFFT Forward Automatic (length xs) >>= (`executeFFT` xs)
ifft xs = planFFT Inverse Automatic (length xs) >>= (`executeFFT` xs)
dft xs = planFFT Forward Direct (length xs) >>= (`executeFFT` xs)

-- | Full complex spectrum; the real-spectrum inverse checks Hermitian symmetry.
realFFT :: [Double] -> Either MathError [Complex Double]
realFFT = fft . map (:+ 0)

-- | Inverse of a full real spectrum; require conjugate symmetry within the supplied absolute tolerance.
inverseRealFFT :: Double -> [Complex Double] -> Either MathError [Double]
inverseRealFFT tolerance xs = do
    require (finite tolerance && tolerance >= 0 && not (null xs)) "invalid real FFT tolerance/length"
    let n = length xs
    require
        (and [magnitude (xs !! k - conjugate (xs !! ((-k) `mod` n))) <= tolerance | k <- [0 .. n - 1]])
        "spectrum is not Hermitian"
    map realPart <$> ifft xs

-- | Apply one immutable plan independently to each batch; any inconsistent row length fails.
fftBatch :: FFTPlan -> [[Complex Double]] -> Either MathError [[Complex Double]]
fftBatch plan = mapM (executeFFT plan)

-- | Transform all axes. Product budget is 65536; last axis varies fastest.
fftND :: Direction -> [Int] -> [Complex Double] -> Either MathError [Complex Double]
fftND direction dims xs = do
    require
        ( not (null dims)
            && all (> 0) dims
            && product (map toInteger dims) <= 65536
            && product dims == length xs
        )
        "invalid ND FFT shape"
    foldl' axis (Right xs) [0 .. length dims - 1]
  where
    axis result a = do
        values <- result
        let n = dims !! a; stride = product (drop (a + 1) dims); outer = product (take a dims)
        p <- planFFT direction Automatic n
        blocks <-
            mapM
                ( \o ->
                    mapM
                        (\s -> executeFFT p [values !! (o * n * stride + j * stride + s) | j <- [0 .. n - 1]])
                        [0 .. stride - 1]
                )
                [0 .. outer - 1]
        Right [blocks !! o !! s !! j | o <- [0 .. outer - 1], j <- [0 .. n - 1], s <- [0 .. stride - 1]]

{- | The caller exclusively owns a valid, aligned, writable buffer of exactly
N Complex Double elements for the duration of this call. No pointers escape;
the entire input is copied and checked before a successful write-back.
-}
fftInPlace :: FFTPlan -> Ptr (Complex Double) -> Int -> IO (Either MathError ())
fftInPlace plan@(FFTPlan _ _ n _) pointer count
    | pointer == nullPtr || count /= n =
        pure (Left (InvalidArgument "invalid in-place FFT buffer/length"))
    | otherwise = do
        xs <- peekArray count pointer
        case executeFFT plan xs of
            Left e -> pure (Left e)
            Right ys -> pokeArray pointer ys >> pure (Right ())

-- | Signed DFT frequency bins in cycles per coordinate unit, given sample count and positive sample spacing.
frequencies :: Int -> Double -> Either MathError [Double]
frequencies n spacing = do
    require (n > 0 && n <= 65536 && finite spacing && spacing > 0) "invalid sampling spacing"
    let period = fromIntegral n * spacing
    require (finite period) "sampling period overflow"
    let result = [fromIntegral (if k < (n + 1) `div` 2 then k else k - n) / period | k <- [0 .. n - 1]]
    require (all finite result) "frequency bins overflow"
    Right result

-- | Rotate zero frequency to/from the center; these operations are exact inverses for odd and even lengths.
fftShift, ifftShift :: [a] -> [a]
fftShift xs = let k = (length xs + 1) `div` 2 in drop k xs ++ take k xs
ifftShift xs = let k = length xs `div` 2 in drop k xs ++ take k xs

realTransform :: Bool -> Bool -> TransformType -> [Double] -> Either MathError [Double]
realTransform sine inverse kind xs = do
    let n = length xs
        nd = fromIntegral n
        endpoint j = if j == 0 || j == n - 1 then 1 / sqrt 2 else 1
        base j k =
            if sine
                then case kind of
                    TypeI -> sqrt (2 / (nd + 1)) * sin (pi * fromIntegral ((j + 1) * (k + 1)) / (nd + 1))
                    TypeII ->
                        sqrt (2 / nd)
                            * (if k == n - 1 then 1 / sqrt 2 else 1)
                            * sin (pi * (fromIntegral j + 0.5) * fromIntegral (k + 1) / nd)
                    TypeIII ->
                        sqrt (2 / nd)
                            * (if j == n - 1 then 1 / sqrt 2 else 1)
                            * sin (pi * fromIntegral (j + 1) * (fromIntegral k + 0.5) / nd)
                    TypeIV -> sqrt (2 / nd) * sin (pi * (fromIntegral j + 0.5) * (fromIntegral k + 0.5) / nd)
                else case kind of
                    TypeI -> sqrt (2 / (nd - 1)) * endpoint j * endpoint k * cos (pi * fromIntegral (j * k) / (nd - 1))
                    TypeII ->
                        sqrt (2 / nd)
                            * (if k == 0 then 1 / sqrt 2 else 1)
                            * cos (pi * (fromIntegral j + 0.5) * fromIntegral k / nd)
                    TypeIII ->
                        sqrt (2 / nd)
                            * (if j == 0 then 1 / sqrt 2 else 1)
                            * cos (pi * fromIntegral j * (fromIntegral k + 0.5) / nd)
                    TypeIV -> sqrt (2 / nd) * cos (pi * (fromIntegral j + 0.5) * (fromIntegral k + 0.5) / nd)
    require
        (n > 0 && n <= 4096 && (sine || kind /= TypeI || n > 1) && all finite xs)
        "invalid cosine/sine transform input"
    let ys =
            [sum [x * (if inverse then base k j else base j k) | (j, x) <- zip [0 ..] xs] | k <- [0 .. n - 1]]
    require (all finite ys) "cosine/sine transform overflow"
    Right ys

-- | Apply an orthonormal cosine/sine basis or its transpose; type-I cosine needs at least two samples.
dct, idct, dst, idst :: TransformType -> [Double] -> Either MathError [Double]
dct = realTransform False False
idct = realTransform False True
dst = realTransform True False
idst = realTransform True True

-- | Unnormalized real Hartley transform, Re(DFT)-Im(DFT); applying twice multiplies by N.
hartley :: [Double] -> Either MathError [Double]
hartley xs = map (\z -> realPart z - imagPart z) <$> realFFT xs

{- | Frames include zero padding on both sides by one full window, so windows
with zero endpoints reconstruct boundary samples. Inverse divides by summed
window squares and rejects uncovered samples. No implicit amplitude scaling.
-}
data STFT = STFT Int Int [Double] [[Complex Double]] deriving (Eq, Show)

-- | Read the full complex spectra in increasing frame-start order.
stftFrames :: STFT -> [[Complex Double]]
stftFrames (STFT _ _ _ frames) = frames

-- | Windowed analysis with an explicit hop in samples, padded endpoint frames, and a 1048576-coefficient storage budget.
stft :: [Double] -> Int -> [Double] -> Either MathError STFT
stft window hop xs = do
    let n = length window
        padded = replicate n 0 ++ xs ++ replicate n 0
        starts = takeWhile (\k -> k + n <= length padded) [0, hop ..]
    require
        (n > 0 && n <= 65536 && hop > 0 && hop <= n && all finite (window ++ xs) && length xs <= 65536)
        "invalid STFT/window/hop"
    require
        (toInteger n * ((toInteger n + toInteger (length xs)) `div` toInteger hop + 1) <= 1048576)
        "STFT frame storage budget exceeded"
    frames <- mapM (realFFT . zipWith (*) window . (\k -> take n (drop k padded))) starts
    Right (STFT (length xs) hop window frames)

-- | Overlap-add inverse with squared-window normalization; reject every uncovered original sample.
istft :: STFT -> Either MathError [Double]
istft (STFT count hop window frames) = do
    time <- mapM ifft frames
    let n = length window
        at k =
            sum
                [ realPart (row !! j) * (window !! j) | (s, row) <- zip [0, hop ..] time, let j = k - s, j >= 0, j < n
                ]
        weight k =
            sum
                [(window !! j) ^ (2 :: Int) | s <- take (length frames) [0, hop ..], let j = k - s, j >= 0, j < n]
        ws = map weight [n .. n + count - 1]
    require (all (> 1e-300) ws) "STFT overlap leaves uncovered samples"
    let ys = zipWith (/) (map at [n .. n + count - 1]) ws
    require (all finite ys) "STFT reconstruction overflow"
    Right ys

-- | Elementwise complex magnitude, principal phase in radians, and squared magnitude; no PSD normalization.
magnitudeSpectrum, phaseSpectrum, powerSpectrum :: [Complex Double] -> [Double]
magnitudeSpectrum = map magnitude
phaseSpectrum = map phase
powerSpectrum = map (\z -> magnitude z ^ (2 :: Int))

-- | Two-sided PSD in amplitude-squared/Hz: squared FFT magnitude divided by sample rate and window squared energy.
periodogram :: Double -> [Double] -> [Double] -> Either MathError [Double]
periodogram rate window xs = do
    require
        (finite rate && rate > 0 && length window == length xs && not (null xs) && all finite window)
        "invalid periodogram input"
    let energy = sum (map (^ (2 :: Int)) window)
    require
        (energy > 0 && finite energy && finite (rate * energy) && rate * energy > 0)
        "zero/overflow window energy or PSD scale"
    spectrum <- realFFT (zipWith (*) window xs)
    let ys = map (/ (rate * energy)) (powerSpectrum spectrum)
    require (all finite ys) "PSD overflow"
    Right ys

-- | Average full-window two-sided periodograms at the supplied hop; discard the incomplete final frame.
welch :: Double -> [Double] -> Int -> [Double] -> Either MathError [Double]
welch rate window hop xs = do
    require
        ( hop > 0
            && not (null window)
            && length xs >= length window
            && length xs <= 1048576
            && toInteger (length window) * (toInteger (length xs) `div` toInteger hop + 1) <= 1048576
        )
        "invalid Welch frames"
    let frames =
            takeWhile
                ((== length window) . length)
                [take (length window) (drop k xs) | k <- [0, hop .. length xs - 1]]
    spectra <- mapM (periodogram rate window) frames
    Right (map (/ fromIntegral (length spectra)) (foldl1 (zipWith (+)) spectra))

-- | Two-sided conjugate(X)*Y cross PSD using the same sample-rate/window-energy normalization as periodogram.
crossSpectrum :: Double -> [Double] -> [Double] -> [Double] -> Either MathError [Complex Double]
crossSpectrum rate window x y = do
    require
        (finite rate && rate > 0 && length x == length y && length window == length x && all finite window)
        "invalid cross spectrum"
    let energy = sum (map (^ (2 :: Int)) window)
    require
        (energy > 0 && finite energy && finite (rate * energy) && rate * energy > 0)
        "invalid cross-spectrum scale"
    a <- realFFT (zipWith (*) window x)
    b <- realFFT (zipWith (*) window y)
    checkC (zipWith (\u v -> conjugate u * v / (rate * energy :+ 0)) a b)

-- | Squared-magnitude STFT frames, retaining the explicit padding/frame order of stft.
spectrogram :: [Double] -> Int -> [Double] -> Either MathError [[Double]]
spectrogram w h xs = map powerSpectrum . stftFrames <$> stft w h xs

-- | Real cepstrum from inverse FFT of log(max(floor,abs(FFT(x)))); floor must be positive.
cepstrum :: Double -> [Double] -> Either MathError [Double]
cepstrum floorValue xs = do
    require (finite floorValue && floorValue > 0) "invalid cepstral log floor"
    a <- realFFT xs
    map realPart <$> ifft [log (max floorValue (magnitude z)) :+ 0 | z <- a]

-- | Real signal plus imaginary Hilbert transform, formed by doubling positive-frequency bins and retaining DC/Nyquist.
analyticSignal :: [Double] -> Either MathError [Complex Double]
analyticSignal xs = do
    spectrum <- realFFT xs
    let n = length xs
        factor k | k == 0 || even n && k == n `div` 2 = 1 | k <= (n - 1) `div` 2 = 2 | otherwise = 0
    ifft [z * (factor k :+ 0) | (k, z) <- zip [0 ..] spectrum]

-- | Imaginary part of the analytic signal; periodic finite-record boundary convention.
hilbert :: [Double] -> Either MathError [Double]
hilbert xs = map imagPart <$> analyticSignal xs

-- | Direct bounded Z-transform along z_k=a*w^(-k); nonzero a,w required.
chirpZ ::
    Int -> Complex Double -> Complex Double -> [Complex Double] -> Either MathError [Complex Double]
chirpZ count a w xs = do
    require
        (count > 0 && count <= 4096 && length xs <= 4096 && a /= 0 && w /= 0 && finiteC a && finiteC w)
        "invalid chirp-Z arguments"
    _ <- checkC xs
    checkC [sum [x * a ^^ (-j) * w ^^ (j * k) | (j, x) <- zip [0 ..] xs] | k <- [0 .. count - 1]]

-- | One arbitrary-frequency DFT value from a second-order real resonator; omega is radians/sample.
goertzel :: Double -> [Double] -> Either MathError (Complex Double)
goertzel omega xs = do
    require (finite omega && all finite xs && not (null xs)) "invalid Goertzel input"
    let c = 2 * cos omega
        (s1, s2) = foldl' (\(a, b) x -> (x + c * a - b, a)) (0, 0) xs
        -- Final phase rotates the usual resonator to arbitrary-frequency DFT.
        value = ((s1 :+ 0) - cis (-omega) * (s2 :+ 0)) * cis (-omega * fromIntegral (length xs - 1))
    _ <- checkC [value]
    Right value

-- | Full zero-padded complex linear convolution; padded transform length is limited to 65536.
fftConvolve :: [Complex Double] -> [Complex Double] -> Either MathError [Complex Double]
fftConvolve a b = do
    require
        (not (null a) && not (null b) && toInteger (length a) + toInteger (length b) <= 65537)
        "invalid FFT convolution lengths"
    let count = length a + length b - 1; n = until (>= count) (* 2) 1
    require (n <= 65536) "FFT convolution exceeds padded budget"
    fa <- fft (a ++ replicate (n - length a) 0)
    fb <- fft (b ++ replicate (n - length b) 0)
    take count <$> ifft (zipWith (*) fa fb)

-- | Correlation lags -(length b-1)..length a-1, conjugating b.
fftCorrelate :: [Complex Double] -> [Complex Double] -> Either MathError [Complex Double]
fftCorrelate a b = fftConvolve a (reverse (map conjugate b))
