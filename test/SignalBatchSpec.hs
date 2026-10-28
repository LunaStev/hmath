-- SPDX-License-Identifier: MPL-2.0
module SignalBatchSpec (signalBatchTests, signalBatchIOTests) where

import Data.Complex (Complex ((:+)), cis, conjugate, magnitude, realPart)
import Foreign.Marshal.Array (peekArray, withArray)
import Foreign.Ptr (nullPtr)
import qualified HMath.Calculus as C
import qualified HMath.Fourier as F
import qualified HMath.Interpolation as I
import qualified HMath.ODE as O
import qualified HMath.PDE as D
import qualified HMath.Signal as S
import qualified HMath.Sparse as Sparse

near :: Double -> Double -> Bool
near a b = abs (a - b) <= 1e-8 * max 1 (max (abs a) (abs b))
nearTol :: Double -> Double -> Double -> Bool
nearTol t a b = abs (a - b) <= t * max 1 (max (abs a) (abs b))
vec :: [Double] -> [Double] -> Bool
vec a b = length a == length b && and (zipWith near a b)
cvec :: [Complex Double] -> [Complex Double] -> Bool
cvec a b =
    length a == length b
        && and (zipWith (\x y -> magnitude (x - y) <= 1e-8 * max 1 (max (magnitude x) (magnitude y))) a b)
ok :: Either a Bool -> Bool
ok = either (const False) id
left :: Either a b -> Bool
left (Left _) = True
left _ = False
rightNear :: Either a Double -> Double -> Bool
rightNear a b = ok ((`near` b) <$> a)
rightVec :: Either a [Double] -> [Double] -> Bool
rightVec a b = ok ((`vec` b) <$> a)
referenceDFT :: [Complex Double] -> [Complex Double]
referenceDFT xs =
    [ sum
        [ x * cis (-2 * pi * fromIntegral (j * k) / fromIntegral (length xs)) | (j, x) <- zip [0 :: Int ..] xs
        ]
    | k <- [0 .. length xs - 1]
    ]
signal :: Int -> [Double]
signal n = [sin (0.7 * fromIntegral j) + 0.1 * fromIntegral (j `mod` 5) | j <- [0 .. n - 1]]
complexSignal :: Int -> [Complex Double]
complexSignal n = zipWith (:+) (signal n) (reverse (signal n))

signalBatchTests :: [(String, Bool)]
signalBatchTests = fourierTests ++ interpolationTests ++ signalTests ++ pdeTests ++ guardAndConvergenceTests

fourierTests :: [(String, Bool)]
fourierTests =
    [ ( "FFT " ++ show algorithm ++ " length " ++ show n
      , ok
            ( do
                p <- F.planFFT F.Forward algorithm n
                ys <- F.executeFFT p (complexSignal n)
                Right (cvec ys (referenceDFT (complexSignal n)))
            )
      )
    | (algorithm, ns) <-
        [ (F.Automatic, [1, 2, 3, 4, 5, 7, 8, 11, 16, 17, 25, 32])
        , (F.Direct, [1, 2, 5, 11])
        , (F.Radix2, [1, 2, 8, 32])
        , (F.Radix4, [1, 4, 16, 64])
        , (F.MixedRadix, [6, 9, 12, 15, 30])
        , (F.SplitRadix, [1, 2, 4, 8, 32])
        , (F.Bluestein, [1, 2, 3, 7, 17, 25])
        , (F.Rader, [2, 3, 5, 7, 11, 17])
        ]
    , n <- ns
    ]
        ++ [ ( "FFT inverse round trip " ++ show n
             , ok (do ys <- F.fft (complexSignal n); zs <- F.ifft ys; Right (cvec zs (complexSignal n)))
             )
           | n <- [1, 3, 7, 16, 25, 64]
           ]
        ++ [
               ( "FFT Parseval"
               , ok
                    ( do
                        let xs = complexSignal 17; ys0 = sum [magnitude x ^ (2 :: Int) | x <- xs]
                        ys <- F.fft xs
                        Right (near ys0 (sum [magnitude y ^ (2 :: Int) | y <- ys] / 17))
                    )
               )
           , ("FFT plan mismatch", left (F.planFFT F.Forward F.Radix2 8 >>= (`F.executeFFT` [1, 2])))
           , ("FFT nonpower radix rejects", left (F.planFFT F.Forward F.Radix4 8))
           , ("FFT Rader composite rejects", left (F.planFFT F.Forward F.Rader 9))
           , ("FFT empty rejects", left (F.fft []))
           , ("FFT input NaN rejects", left (F.fft [0 / 0]))
           , ("FFT oversized plan rejects", left (F.planFFT F.Forward F.Automatic maxBound))
           ,
               ( "FFT batched"
               , ok
                    ( do
                        p <- F.planFFT F.Forward F.Radix2 4
                        ys <- F.fftBatch p [[1, 0, 0, 0], [1, 1, 1, 1]]
                        Right (cvec (ys !! 0) [1, 1, 1, 1] && cvec (ys !! 1) [4, 0, 0, 0])
                    )
               )
           , ("FFT ND independent 2D", ndFourier [3, 4])
           , ("FFT ND independent 3D", ndFourier [2, 3, 4])
           , ("FFT ND invalid shape", left (F.fftND F.Forward [2, 3] [1, 2]))
           ,
               ( "real FFT round trip"
               , ok (do y <- F.realFFT (signal 17); z <- F.inverseRealFFT 1e-10 y; Right (vec z (signal 17)))
               )
           , ("real FFT Hermitian rejection", left (F.inverseRealFFT 1e-9 [1, 2 :+ 3, 4, 5]))
           , ("FFT frequency even", rightVec (F.frequencies 4 0.25) [0, 1, -2, -1])
           , ("FFT frequency odd", rightVec (F.frequencies 5 0.2) [0, 1, 2, -2, -1])
           , ("FFT shifts odd/even", all (\xs -> F.ifftShift (F.fftShift xs) == xs) [[0 .. 4 :: Int], [0 .. 5]])
           ,
               ( "DCT independent orthonormal II"
               , rightVec (F.dct F.TypeII [1, 2, 3, 4]) [5, -2.230442497387663, 0, -0.158512667781107]
               )
           ,
               ( "Hartley involution"
               , ok (do y <- F.hartley (signal 7); z <- F.hartley y; Right (vec (map (/ 7) z) (signal 7)))
               )
           ,
               ( "STFT Hann reconstruction"
               , ok
                    (do w <- S.window S.Hann 8; t <- F.stft w 2 (signal 17); x <- F.istft t; Right (vec x (signal 17)))
               )
           , ("STFT rejects uncovered samples", left (F.stft [1, 0] 2 [1, 2, 3, 4] >>= F.istft))
           , ("STFT invalid hop", left (F.stft [1, 1] 0 [1]))
           ,
               ( "periodogram scaling"
               , ok
                    ( do
                        p <- F.periodogram 8 (replicate 8 1) [sin (2 * pi * fromIntegral j / 8) | j <- [0 .. 7 :: Int]]
                        Right (vec p [0, 0.25, 0, 0, 0, 0, 0, 0.25])
                    )
               )
           , ("Welch scaling", rightVec (F.welch 1 (replicate 4 1) 2 (replicate 10 1)) [4, 0, 0, 0])
           ,
               ( "cross spectrum conjugate convention"
               , ok
                    ( do
                        let x = signal 8; y = reverse x
                        a <- F.crossSpectrum 4 (replicate 8 1) x y
                        b <- F.crossSpectrum 4 (replicate 8 1) y x
                        Right (cvec a (map conjugate b))
                    )
               )
           ,
               ( "spectrogram shape"
               , ok
                    (do p <- F.spectrogram (replicate 4 1) 2 (signal 9); Right (not (null p) && all ((== 4) . length) p))
               )
           , ("cepstrum unit impulse", rightVec (F.cepstrum 1e-20 [1, 0, 0, 0]) [0, 0, 0, 0])
           ,
               ( "Hilbert analytic sinusoid"
               , ok
                    ( do
                        z <- F.analyticSignal [cos (2 * pi * fromIntegral j / 16) | j <- [0 .. 15 :: Int]]
                        Right (cvec z [cis (2 * pi * fromIntegral j / 16) | j <- [0 .. 15 :: Int]])
                    )
               )
           ,
               ( "chirp Z matches DFT"
               , ok
                    ( do
                        z <- F.chirpZ 7 1 (cis (-2 * pi / 7)) (complexSignal 7)
                        Right (cvec z (referenceDFT (complexSignal 7)))
                    )
               )
           ,
               ( "Goertzel arbitrary frequency"
               , ok
                    ( do
                        let xs = signal 9; w = 0.71
                        value <- F.goertzel w xs
                        Right
                            ( magnitude
                                (value - sum [x * cis (-w * fromIntegral j) | (j, x) <- zip [0 :: Int ..] (map (:+ 0) xs)])
                                < 1e-10
                            )
                    )
               )
           ,
               ( "FFT convolution/correlation"
               , ok
                    ( do
                        a <- F.fftConvolve [1, 2, 3] [4, 5]
                        b <- F.fftCorrelate [1, 2, 3] [4, 5]
                        Right (cvec a [4, 13, 22, 15] && cvec b [5, 14, 23, 12])
                    )
               )
           ]
        ++ [ ( "cosine/sine round trip " ++ show kind ++ show sine
             , ok
                ( do
                    let xs = signal 7
                    y <- (if sine then F.dst else F.dct) kind xs
                    z <- (if sine then F.idst else F.idct) kind y
                    Right (vec z xs)
                )
             )
           | kind <- [F.TypeI, F.TypeII, F.TypeIII, F.TypeIV]
           , sine <- [False, True]
           ]
  where
    ndFourier dims =
        ok
            ( do
                let n = product dims
                    xs = complexSignal n
                    strides = drop 1 (scanr (*) 1 dims)
                    idx i = zipWith (\s d -> i `div` s `mod` d) strides dims
                    ref =
                        [ sum
                            [ x
                                * cis (-2 * pi * sum [fromIntegral (a * b) / fromIntegral d | (a, b, d) <- zip3 (idx j) (idx k) dims])
                            | (j, x) <- zip [0 ..] xs
                            ]
                        | k <- [0 .. n - 1]
                        ]
                ys <- F.fftND F.Forward dims xs
                zs <- F.fftND F.Inverse dims ys
                Right (cvec ys ref && cvec zs xs)
            )

interpolationTests :: [(String, Bool)]
interpolationTests =
    [ ( "interpolation polynomial " ++ show method
      , all
            (\x -> rightNear (I.interpolate method I.Reject [(-1, -1), (0, 0), (1, 1), (2, 8)] x) (x * x * x))
            [-1, -0.5, 0, 0.3, 1, 2]
      )
    | method <- [I.Lagrange, I.Newton, I.Barycentric]
    ]
        ++ [ ("interpolation nearest tie", rightNear (I.interpolate I.Nearest I.Reject [(0, 2), (1, 4)] 0.5) 2)
           ,
               ( "interpolation linear/extrapolation"
               , rightNear (I.interpolate I.Linear I.Extrapolate [(0, 1), (1, 3)] 2) 5
               )
           , ("interpolation clamp", rightNear (I.interpolate I.Linear I.Clamp [(0, 1), (1, 3)] 2) 3)
           , ("interpolation reject extrapolation", left (I.interpolate I.Linear I.Reject [(0, 1), (1, 3)] 2))
           , ("interpolation duplicate reject", left (I.interpolate I.Barycentric I.Reject [(0, 1), (0, 2)] 0))
           ,
               ( "Hermite cubic reproduction"
               , all (\x -> rightNear (I.hermite [(0, 0, 0), (1, 1, 3)] x) (x * x * x)) [0, 0.2, 0.7, 1]
               )
           ,
               ( "piecewise polynomial calculus"
               , ok
                    ( do
                        p <- I.piecewisePolynomial [0, 1, 2] [[0, 0, 1], [1, 2, 1]]
                        d <- I.differentiatePiecewise p
                        v <- I.evaluatePiecewise I.Reject d 1.5
                        i <- I.integratePiecewise p 0 2
                        Right (near v 3 && near i (8 / 3))
                    )
               )
           ,
               ( "clamped cubic reproduction"
               , ok
                    ( do
                        p <- I.cubicSpline (I.Clamped 0 12) [(0, 0), (0.5, 0.125), (1, 1), (2, 8)]
                        ys <- mapM (I.evaluatePiecewise I.Reject p) [0, 0.2, 0.8, 1.5, 2]
                        Right (vec ys [0, 0.008, 0.512, 3.375, 8])
                    )
               )
           ,
               ( "natural spline linear"
               , ok
                    ( do
                        p <- I.cubicSpline I.Natural [(0, 1), (0.3, 1.6), (1, 3), (2, 5)]
                        ys <- mapM (I.evaluatePiecewise I.Reject p) [0, 0.2, 0.8, 1.5, 2]
                        Right (vec ys [1, 1.4, 2.6, 4, 5])
                    )
               )
           ,
               ( "periodic spline derivative/curvature endpoints"
               , ok
                    ( do
                        p <- I.cubicSpline I.Periodic [(0, 0), (1, 1), (2, 0), (3, -1), (4, 0)]
                        d <- I.differentiatePiecewise p
                        dd <- I.differentiatePiecewise d
                        a <- I.evaluatePiecewise I.Reject d 0
                        b <- I.evaluatePiecewise I.Reject d 4
                        c <- I.evaluatePiecewise I.Reject dd 0
                        e <- I.evaluatePiecewise I.Reject dd 4
                        Right (near a b && near c e)
                    )
               )
           ,
               ( "PCHIP monotonicity"
               , ok
                    ( do
                        p <- I.pchip [(0, 0), (0.1, 1), (0.5, 1), (1, 4), (2, 5)]
                        ys <- mapM (I.evaluatePiecewise I.Reject p) [fromIntegral j / 100 | j <- [0 .. 200 :: Int]]
                        Right (and (zipWith (<=) ys (drop 1 ys)))
                    )
               )
           ,
               ( "Akima linear reproduction"
               , ok
                    ( do
                        p <- I.akima [(0, 1), (0.2, 1.4), (0.5, 2), (1, 3), (2, 5)]
                        ys <- mapM (I.evaluatePiecewise I.Reject p) [0.1, 0.4, 0.7, 1.8]
                        Right (vec ys [1.2, 1.8, 2.4, 4.6])
                    )
               )
           ,
               ( "smoothing zero lambda interpolation"
               , ok
                    ( do
                        p <- I.smoothingSpline 0 [(0, 1), (1, 3), (2, 2), (3, 4)]
                        ys <- mapM (I.evaluatePiecewise I.Reject p) [0, 1, 2, 3]
                        Right (vec ys [1, 3, 2, 4])
                    )
               )
           ,
               ( "smoothing curvature decreases"
               , ok
                    ( do
                        a <- I.smoothingSpline 0 [(0, 0), (1, 2), (2, 0), (3, 2), (4, 0)]
                        b <- I.smoothingSpline 100 [(0, 0), (1, 2), (2, 0), (3, 2), (4, 0)]
                        da <- I.differentiatePiecewise a >>= I.differentiatePiecewise
                        db <- I.differentiatePiecewise b >>= I.differentiatePiecewise
                        u <- mapM (I.evaluatePiecewise I.Reject da) [0, 0.1 .. 4]
                        v <- mapM (I.evaluatePiecewise I.Reject db) [0, 0.1 .. 4]
                        Right (sum (map abs v) < sum (map abs u))
                    )
               )
           ,
               ( "Bezier endpoints and middle"
               , rightVec (I.bezier [[0, 0], [1, 2], [2, 0]] 0.5) [1, 1]
                    && rightVec (I.bezier [[0, 0], [1, 2], [2, 0]] 1) [2, 0]
               )
           ,
               ( "NURBS quarter circle"
               , rightVec (I.rationalBezier [[1, 0], [1, 1], [0, 1]] [1, 1 / sqrt 2, 1] 0.5) [1 / sqrt 2, 1 / sqrt 2]
               )
           ,
               ( "B-spline knot insertion preserves curve"
               , ok
                    ( do
                        s <- I.bSpline 2 [0, 0, 0, 1, 1, 1] [[0, 0], [1, 2], [2, 0]] [1, 1, 1]
                        t <- I.insertKnot s 0.4
                        a <- mapM (I.evaluateBSpline s) [0, 0.05 .. 1]
                        b <- mapM (I.evaluateBSpline t) [0, 0.05 .. 1]
                        Right (and (zipWith vec a b))
                    )
               )
           ,
               ( "B-spline analytic derivative"
               , ok
                    ( do
                        s <- I.bSpline 2 [0, 0, 0, 1, 1, 1] [[0, 0], [1, 2], [2, 0]] [1, 1, 1]
                        a <- I.derivativeBSpline s 0
                        b <- I.derivativeBSpline s 1
                        Right (vec a [2, 4] && vec b [2, -4])
                    )
               )
           ,
               ( "B-spline integral and arc length"
               , ok
                    ( do
                        s <- I.bSpline 1 [0, 0, 1, 1] [[0, 0], [3, 4]] [1, 1]
                        i <- I.curveIntegral C.defaultTolerance s 0 1
                        l <- I.arcLength C.defaultTolerance s 0 1
                        Right (vec (map C.estimateValue i) [1.5, 2] && near (C.estimateValue l) 5)
                    )
               )
           ,
               ( "Kochanek-Bartels source interpolation"
               , ok
                    ( do
                        s <- I.kochanekBartels 0.2 0.3 (-0.4) [(0, 0), (1, 2), (2, -1), (3, 0)]
                        ys <- mapM (I.evaluatePiecewise I.Reject s) [0, 1, 2, 3]
                        Right (vec ys [0, 2, -1, 0])
                    )
               )
           ,
               ( "Catmull-Rom cardinal identity"
               , I.catmullRom [(0, 0), (1, 2), (2, 1)] == I.cardinalSpline 0 [(0, 0), (1, 2), (2, 1)]
               )
           ,
               ( "bilinear interpolation"
               , rightNear (I.gridInterpolate I.Linear I.Reject [[0, 1], [0, 2]] [0, 4, 1, 5] [0.2, 0.5]) 1.2
               )
           ,
               ( "trilinear interpolation"
               , rightNear
                    (I.gridInterpolate I.Linear I.Reject (replicate 3 [0, 1]) [0, 3, 2, 5, 1, 4, 3, 6] [0.2, 0.3, 0.4])
                    2
               )
           ,
               ( "ND grid interpolation"
               , rightNear
                    ( I.gridInterpolate
                        I.Linear
                        I.Reject
                        (replicate 4 [0, 1])
                        [fromIntegral (sum bits) | bits <- sequence (replicate 4 [0, 1 :: Int])]
                        [0.2, 0.3, 0.4, 0.5]
                    )
                    1.4
               )
           ,
               ( "grid invalid dimensions reject"
               , left (I.gridInterpolate I.Linear I.Reject [[0, 1]] [1, 2, 3] [0.5])
               )
           , ("Shepard node interpolation", rightNear (I.shepard [[0, 0], [1, 0], [0, 1]] [1, 2, 3] [1, 0]) 2)
           , ("inverse distance symmetry", rightNear (I.inverseDistance 2 [[0], [2]] [1, 3] [1]) 2)
           ,
               ( "kriging exact node and variance"
               , ok (do (m, v) <- I.kriging 1 0 [[0], [1], [2]] [1, 3, 2] [1]; Right (near m 3 && near v 0))
               )
           ,
               ( "polynomial least squares QR"
               , ok
                    ( do
                        p <- I.polynomialFit 2 [(x, 1 + 2 * x + 3 * x * x) | x <- [-2, -1, 0, 1, 2]]
                        Right (vec (I.approximationCoefficients p) [1, 2, 3] && I.approximationError p < 1e-10)
                    )
               )
           ,
               ( "Chebyshev approximation quadratic"
               , ok
                    ( do
                        p <- I.chebyshevApproximate 2 (\x -> x * x) (-1) 1
                        y <- I.evaluateChebyshev (I.approximationCoefficients p) (-1) 1 0.3
                        Right (near y 0.09 && I.approximationError p < 1e-10)
                    )
               )
           ,
               ( "Pade exponential [1/1]"
               , ok (do (p, q) <- I.pade 1 1 [1, 1, 0.5]; Right (vec p [1, 0.5] && vec q [1, -0.5]))
               )
           ,
               ( "rational least squares"
               , ok
                    ( do
                        (p, q, e) <- I.rationalFit 1 1 [(x, (1 + 2 * x) / (1 + 0.3 * x)) | x <- [-1, -0.5, 0, 0.5, 1]]
                        Right (vec p [1, 2] && vec q [1, 0.3] && e < 1e-8)
                    )
               )
           ,
               ( "Remez quadratic minimax constant"
               , ok
                    ( do
                        p <- I.remez 0 257 1e-10 20 (\x -> x * x) (-1) 1
                        Right (near (I.approximationCoefficients p !! 0) 0.5 && near (I.approximationError p) 0.5)
                    )
               )
           ,
               ( "Remez degree one |x|"
               , ok
                    ( do
                        p <- I.remez 1 257 1e-10 20 abs (-1) 1
                        Right (vec (I.approximationCoefficients p) [0.5, 0] && near (I.approximationError p) 0.5)
                    )
               )
           ,
               ( "nonlinear exponential fit"
               , ok
                    ( do
                        p <-
                            I.nonlinearFit
                                100
                                1e-9
                                (\x ps -> ps !! 0 * exp (ps !! 1 * x))
                                [(x, 2 * exp (0.4 * x)) | x <- [0, 0.2 .. 1]]
                                [1, 0.1]
                        Right (and (zipWith (nearTol 1e-6) (I.approximationCoefficients p) [2, 0.4]))
                    )
               )
           ,
               ( "nonlinear fit exhausted budget"
               , left (I.nonlinearFit 1 1e-15 (\x p -> p !! 0 * exp (p !! 1 * x)) [(0, 2), (1, 4), (2, 8)] [1, 0])
               )
           ,
               ( "interpolation sampled error"
               , rightNear (I.interpolationError (\x -> x * x) [(0, 0), (1, 1.1)]) 0.1
               )
           , ("interpolation invalid knots", left (I.piecewisePolynomial [0, 0] [[1]]))
           , ("rational weights must be positive", left (I.rationalBezier [[0], [1]] [1, 0] 0.5))
           ]
        ++ [ ( "RBF " ++ show kernel ++ " affine reproduction"
             , ok
                ( do
                    r <- I.fitRBF kernel 0 [[0, 0], [1, 0], [0, 1], [1, 1]] [1, 3, 4, 6]
                    y <- I.evaluateRBF r [0.3, 0.7]
                    Right (near y 3.7)
                )
             )
           | kernel <- [I.Gaussian 1, I.Multiquadric 1, I.InverseMultiquadric 1, I.ThinPlate, I.Cubic]
           ]

signalTests :: [(String, Bool)]
signalTests =
    [ ("linear convolution", rightVec (S.convolution [1, 2, 3] [4, 5]) [4, 13, 22, 15])
    , ("circular convolution", rightVec (S.circularConvolution [1, 2, 3] [4, 5, 6]) [31, 31, 28])
    , ("correlation lag convention", rightVec (S.correlation [1, 2, 3] [4, 5]) [5, 14, 23, 12])
    , ("autocorrelation symmetry", ok (do y <- S.autocorrelation (signal 9); Right (vec y (reverse y))))
    ,
        ( "overlap-add streaming/full"
        , ok
            ( do
                a <- S.overlapAdd 4 [0.2, 0.3, 0.5] (signal 17)
                b <- S.convolution (signal 17) [0.2, 0.3, 0.5]
                Right (vec a b)
            )
        )
    ,
        ( "overlap-save streaming/full"
        , ok
            ( do
                a <- S.overlapSave 8 [0.2, 0.3, 0.5] (signal 17)
                b <- S.convolution (signal 17) [0.2, 0.3, 0.5]
                Right (vec a b)
            )
        )
    ,
        ( "overlap-save exact block edge"
        , ok
            (do a <- S.overlapSave 3 [1, 2, 3] [1, 2, 3]; b <- S.convolution [1, 2, 3] [1, 2, 3]; Right (vec a b))
        )
    ,
        ( "FIR impulse"
        , ok (do f <- S.fir [1, 2, 3]; (ys, _) <- S.filterSignal f [1, 0, 0, 0]; Right (vec ys [1, 2, 3, 0]))
        )
    ,
        ( "IIR step response"
        , ok
            ( do
                f <- S.iir [0.5] [1, -0.5]
                (ys, _) <- S.filterSignal f (replicate 4 1)
                Right (vec ys [0.5, 0.75, 0.875, 0.9375])
            )
        )
    ,
        ( "IIR streaming state"
        , ok
            ( do
                f <- S.iir [0.5] [1, -0.5]
                (a, g) <- S.filterSignal f (take 7 (signal 17))
                (b, _) <- S.filterSignal g (drop 7 (signal 17))
                (c, _) <- S.filterSignal f (signal 17)
                Right (vec (a ++ b) c)
            )
        )
    ,
        ( "IIR coefficient normalization"
        , ok (do f <- S.iir [1] [2, -1]; Right (S.filterCoefficients f == ([0.5, 0], [1, -0.5])))
        )
    , ("IIR invalid denominator", left (S.iir [1] [0, 1]))
    ,
        ( "notch zero at frequency"
        , ok (do f <- S.notch 0.7 10; h <- S.frequencyResponse f 0.7; Right (magnitude h < 1e-10))
        )
    ,
        ( "all-pass unit magnitude"
        , ok
            ( do
                f <- S.allPass 0.7 2
                hs <- mapM (S.frequencyResponse f) [0, 0.2, 0.7, 1, 2, 3]
                Right (all (near 1 . magnitude) hs)
            )
        )
    , ("median removes impulse", rightVec (S.medianFilter 3 [0, 0, 10, 0, 0]) [0, 0, 0, 0, 0])
    , ("Gaussian constant preservation", rightVec (S.gaussianFilter 5 1 (replicate 7 3)) (replicate 7 3))
    ,
        ( "Savitzky-Golay polynomial derivative"
        , ok
            ( do
                y <- S.savitzkyGolay 5 2 1 1 [fromIntegral (j * j) | j <- [-5 .. 5 :: Int]]
                Right (vec (take 7 (drop 2 y)) [-6, -4, -2, 0, 2, 4, 6])
            )
        )
    , ("Wiener zero-noise identity", rightVec (S.wiener 3 (Just 0) [1, 2, 4, 8]) [1, 2, 4, 8])
    , ("moving average zero-state", rightVec (S.movingAverage 2 [2, 4, 6]) [1, 3, 5])
    ,
        ( "windowed sinc unity DC"
        , ok (do h <- S.windowedSinc S.Hann 31 100 1000; Right (near (sum h) 1 && vec h (reverse h)))
        )
    ,
        ( "Dolph-Chebyshev independent odd reference"
        , rightVec
            (S.window (S.DolphChebyshev 60) 5)
            [0.18761509743652255, 0.686241241097988, 1, 0.686241241097988, 0.18761509743652255]
        )
    ,
        ( "Dolph-Chebyshev independent even reference"
        , rightVec
            (S.window (S.DolphChebyshev 60) 6)
            [0.13265103435564682, 0.5477085429608683, 1, 1, 0.5477085429608683, 0.13265103435564682]
        )
    , ("resampling identity kernel", rightVec (S.resamplePolyphase 1 1 [0, 1, 0] [1, 2, 3]) [1, 2, 3])
    ,
        ( "polyphase reference zero insertion"
        , ok
            ( do
                a <- S.resamplePolyphase 3 2 [0.1, 0.2, 0.4, 0.2, 0.1] [1, 2, 3, 4]
                up <- S.upsample 3 [1, 2, 3, 4]
                full <- S.convolution (map (* 3) up) [0.1, 0.2, 0.4, 0.2, 0.1]
                Right (vec a [takeValue full (k * 2 + 2) | k <- [0 .. 5]])
            )
        )
    ,
        ( "resampling intended frequency"
        , ok
            ( do
                let xs = [sin (2 * pi * 0.03 * fromIntegral j) | j <- [0 .. 255 :: Int]]
                y <- S.resample 2 3 127 xs
                Right (maximum [abs (y !! j - sin (2 * pi * 0.045 * fromIntegral j)) | j <- [20 .. 140]] < 0.01)
            )
        )
    ,
        ( "anti-alias attenuation"
        , ok
            ( do
                let xs = [cos (0.8 * pi * fromIntegral j) | j <- [0 .. 255 :: Int]]
                filtered <- S.antiAlias 2 63 xs
                value <- S.rms (take 200 (drop 28 filtered))
                Right (value < 0.01)
            )
        )
    , ("decimation offset", rightVec (S.downsample 3 1 [0 .. 9]) [1, 4, 7])
    , ("upsample zero insertion", rightVec (S.upsample 2 [1, 2, 3]) [1, 0, 2, 0, 3, 0])
    ,
        ( "peak plateau prominence width"
        , ok
            ( do
                p <- S.peaks 0.1 1 [0, 1, 2, 2, 1, 0]
                Right
                    ( length p == 1
                        && S.peakIndex (p !! 0) == 2
                        && near (S.peakProminence (p !! 0)) 2
                        && near (S.peakWidth (p !! 0)) 3
                    )
            )
        )
    ,
        ( "peak distance selects taller"
        , ok (do p <- S.peaks 0 3 [0, 1, 0, 2, 0]; Right (map S.peakIndex p == [3]))
        )
    , ("zero crossing interpolation/plateau", rightVec (S.zeroCrossings [-1, 1, 0, 0, -1]) [0.5, 2])
    ,
        ( "analytic envelope"
        , rightVec (S.envelope [cos (2 * pi * fromIntegral j / 16) | j <- [0 .. 15 :: Int]]) (replicate 16 1)
        )
    , ("phase unwrap", rightVec (S.unwrapPhase [0, 1, 2, 3, -2, -1]) [0, 1, 2, 3, 2 * pi - 2, 2 * pi - 1])
    , ("linear detrending", rightVec (S.detrend True [2, 5, 8, 11, 14]) (replicate 5 0))
    , ("normalization", rightVec (S.normalize [-2, 0, 1]) [-1, 0, 0.5])
    , ("smoothing constant", rightVec (S.smooth 3 (replicate 7 4)) (replicate 7 4))
    , ("noise estimate constant", rightNear (S.noiseEstimate (replicate 7 3)) 0)
    , ("SNR decibels", rightNear (S.signalToNoise [10, 10] [1, 1]) 20)
    , ("RMS stable scaling", rightNear (S.rms [1e200, -1e200]) 1e200)
    ,
        ( "Kalman independent scalar update"
        , ok
            ( do
                state <- S.gaussianState [0] [[1]]
                next <- S.kalman [[1]] [[1]] [[0.1]] [[0.2]] [1] state
                Right
                    (vec (S.stateMean next) [1.1 / 1.3] && vec (concat (S.stateCovariance next)) [1.1 * 0.2 / 1.3])
            )
        )
    ,
        ( "EKF linear equivalence"
        , ok
            ( do
                state <- S.gaussianState [1, 2] [[1, 0.2], [0.2, 2]]
                a <- S.kalman [[1, 0.1], [0, 1]] [[1, 0]] [[0.1, 0], [0, 0.1]] [[0.2]] [1.5] state
                b <-
                    S.extendedKalman
                        (\x -> [x !! 0 + 0.1 * x !! 1, x !! 1])
                        (\x -> [x !! 0])
                        [[0.1, 0], [0, 0.1]]
                        [[0.2]]
                        [1.5]
                        state
                Right
                    ( vec (S.stateMean a) (S.stateMean b)
                        && vec (concat (S.stateCovariance a)) (concat (S.stateCovariance b))
                    )
            )
        )
    ,
        ( "UKF linear equivalence includes process noise"
        , ok
            ( do
                state <- S.gaussianState [1, 2] [[1, 0.2], [0.2, 2]]
                a <- S.kalman [[1, 0.1], [0, 1]] [[1, 0]] [[0.1, 0], [0, 0.1]] [[0.2]] [1.5] state
                b <-
                    S.unscentedKalman
                        0.7
                        2
                        0
                        (\x -> [x !! 0 + 0.1 * x !! 1, x !! 1])
                        (\x -> [x !! 0])
                        [[0.1, 0], [0, 0.1]]
                        [[0.2]]
                        [1.5]
                        state
                Right
                    ( vec (S.stateMean a) (S.stateMean b)
                        && vec (concat (S.stateCovariance a)) (concat (S.stateCovariance b))
                    )
            )
        )
    , ("Kalman covariance invalid reject", left (S.gaussianState [0, 0] [[1, 2], [2, 1]]))
    ,
        ( "UKF invalid scaling reject"
        , left (S.gaussianState [0] [[1]] >>= S.unscentedKalman 0 2 0 id id [[1]] [[1]] [0])
        )
    ,
        ( "CWT Mexican Hat constant interior zero"
        , ok
            (do ys <- S.cwt S.MexicanHat 0.1 [0.2] (replicate 101 1); Right (magnitude (ys !! 0 !! 50) < 1e-8))
        )
    ,
        ( "CWT Morlet complex frequency"
        , ok
            (do ys <- S.cwt (S.Morlet 6) 0.1 [0.3] (signal 31); Right (length ys == 1 && length (ys !! 0) == 31))
        )
    ,
        ( "CWT Gaussian derivative odd impulse"
        , ok
            ( do
                ys <- S.cwt S.GaussianDerivative 1 [2] [0, 0, 0, 1, 0, 0, 0]
                let row = map realPart (ys !! 0)
                Right (vec row (map negate (reverse row)))
            )
        )
    ,
        ( "wavelet soft threshold zero identity"
        , ok (do y <- S.waveletDenoise S.Daubechies2 3 (Just 0) (signal 32); Right (vec y (signal 32)))
        )
    ,
        ( "wavelet denoising removes alternating noise"
        , ok
            ( do
                let xs = [2 + if even j then 0.1 else -0.1 | j <- [0 .. 31 :: Int]]
                y <- S.waveletDenoise S.Haar 3 (Just 0.2) xs
                Right (vec y (replicate 32 2))
            )
        )
    , ("wavelet invalid divisibility", left (S.dwt S.Haar 3 [1, 2, 3]))
    ]
        ++ [ ( "window symmetry " ++ show kind
             , ok (do w <- S.window kind 15; Right (vec w (reverse w) && length w == 15))
             )
           | kind <-
                [ S.Hann
                , S.Hamming
                , S.Blackman
                , S.Bartlett
                , S.Kaiser 8
                , S.Gaussian 0.5
                , S.Tukey 0.3
                , S.FlatTop
                , S.DolphChebyshev 80
                ]
           ]
        ++ [ ( "wavelet round trip " ++ show family
             , ok (do tree <- S.dwt family 4 (signal 32); y <- S.idwt tree; Right (vec y (signal 32)))
             )
           | family <- [S.Haar, S.Daubechies2, S.Daubechies4, S.Biorthogonal53]
           ]
        ++ [ ( "wavelet packet round trip " ++ show family
             , ok
                ( do
                    packet <- S.waveletPackets family 3 (signal 32)
                    y <- S.inverseWaveletPackets packet
                    Right (vec y (signal 32) && length (S.packetBands packet) == 8)
                )
             )
           | family <- [S.Haar, S.Daubechies2, S.Daubechies4, S.Biorthogonal53]
           ]
        ++ [ ( "IIR independent reference " ++ show family ++ " order " ++ show n
             , ok
                ( do
                    f <- S.designIIR family (S.Lowpass 100) n 1000
                    ys <- mapM (S.frequencyResponse f) [0, 0.1 * pi, 0.2 * pi, 0.5 * pi, 0.9 * pi]
                    Right (and (zipWith (nearTol 2e-6) (map magnitude ys) expected))
                )
             )
           | (family, n, expected) <- filterReferences
           ]
        ++ [ ( "IIR band transformation " ++ show band
             , ok
                ( do
                    f <- S.designIIR S.Butterworth band 3 1000
                    a <- S.frequencyResponse f omega
                    b <- S.frequencyResponse f rejectOmega
                    Right (magnitude a > 0.9 && magnitude b < 0.1)
                )
             )
           | (band, omega, rejectOmega) <-
                [ (S.Highpass 100, 0.8 * pi, 0.02 * pi)
                , (S.Bandpass 100 200, 0.3 * pi, 0.8 * pi)
                , (S.Bandstop 100 200, 0.01 * pi, 0.288 * pi)
                ]
           ]
  where
    takeValue xs i = if i < length xs then xs !! i else 0

-- Frozen independent SciPy 1.17.1 frequency-response fixtures; no Python
-- runtime is required. Bessel references explicitly use norm='delay'.
filterReferences :: [(S.FilterFamily, Int, [Double])]
filterReferences =
    [
        ( S.Butterworth
        , 1
        , [1, 0.8988915633764916, 0.7071067811865476, 0.30901699437494745, 0.051394214033586065]
        )
    ,
        ( S.Butterworth
        , 3
        , [1, 0.9933588135581018, 0.7071067811865478, 0.034282521281402155, 0.00013629052186088343]
        )
    ,
        ( S.ChebyshevI 1
        , 4
        ,
            [ 0.891250938133747
            , 0.9748546119130185
            , 0.8912509381337377
            , 0.00305635541710955
            , 1.727540345648957e-6
            ]
        )
    , (S.ChebyshevII 40, 3, [1, 0.27302991949420347, 0.01, 0.008375608497991719, 0.0015384902119782208])
    , (S.ChebyshevII 40, 4, [1, 0.7369632449653044, 0.01, 0.0024459397038173506, 0.009788712728984057])
    ,
        ( S.Elliptic 1 40
        , 1
        , [1, 0.9705881896883672, 0.8912509381337453, 0.538180963866568, 0.10062165471903978]
        )
    ,
        ( S.Elliptic 1 40
        , 3
        , [1, 0.8922048713381072, 0.8912509381337433, 0.004813894287680445, 0.003496587335325386]
        )
    ,
        ( S.Elliptic 1 40
        , 4
        ,
            [ 0.8912509381337482
            , 0.9929394069322406
            , 0.8912509381337373
            , 0.002550784448043673
            , 0.009631871292126429
            ]
        )
    ,
        ( S.Bessel
        , 3
        , [1, 0.9763241012830516, 0.9012626521891648, 0.3321522176503896, 0.0020279871231401684]
        )
    ,
        ( S.Bessel
        , 4
        , [1, 0.9831132127595581, 0.930041530128631, 0.44934020983745376, 0.0007265424465677719]
        )
    ]
        ++ [
               ( S.Butterworth
               , 2
               ,
                   [ 0.9999999999999998
                   , 0.9729114990789712
                   , 0.7071067811865476
                   , 0.10498934469762278
                   , 0.002648351236045209
                   ]
               )
           ,
               ( S.Butterworth
               , 5
               ,
                   [ 0.999999999999996
                   , 0.9996214806165102
                   , 0.7071067811865457
                   , 0.0036214070680761793
                   , 3.609464411826333e-07
                   ]
               )
           ,
               ( S.Butterworth
               , 8
               ,
                   [ 0.9999999999996448
                   , 0.9999949189872123
                   , 0.707106781186294
                   , 0.00012422479964716815
                   , 4.9193579292724224e-11
                   ]
               )
           ,
               ( S.ChebyshevI 1
               , 2
               ,
                   [ 0.8912509381337451
                   , 0.9661479194864628
                   , 0.8912509381337451
                   , 0.1088673859362491
                   , 0.0026057560995742944
                   ]
               )
           ,
               ( S.ChebyshevI 1
               , 5
               ,
                   [ 0.9999999999999489
                   , 0.96157446408255
                   , 0.8912509381336893
                   , 0.0005103838874784432
                   , 4.4481004282949385e-08
                   ]
               )
           ,
               ( S.ChebyshevI 1
               , 8
               ,
                   [ 0.8912509381171345
                   , 0.956908094364851
                   , 0.8912509381600288
                   , 2.3766741157309546e-06
                   , 7.593005944170801e-13
                   ]
               )
           ,
               ( S.ChebyshevII 40
               , 2
               ,
                   [ 0.9999999999999983
                   , 0.07397045027718802
                   , 0.00999999999999999
                   , 0.007888692802825534
                   , 0.009947038044245628
                   ]
               )
           ,
               ( S.ChebyshevII 40
               , 5
               ,
                   [ 1.000000000000019
                   , 0.972676115614597
                   , 0.010000000000000049
                   , 0.009964880229729007
                   , 0.002546029911744882
                   ]
               )
           ,
               ( S.ChebyshevII 40
               , 8
               ,
                   [ 1.0000000000003986
                   , 0.9999911526125133
                   , 0.01000000000000889
                   , 0.008803687315900526
                   , 0.009163772677126859
                   ]
               )
           ,
               ( S.Elliptic 1 40
               , 2
               ,
                   [ 0.8912509381337456
                   , 0.9656960135151118
                   , 0.8912509381337455
                   , 0.0990564755772056
                   , 0.007394582810756181
                   ]
               )
           ,
               ( S.Elliptic 1 40
               , 5
               ,
                   [ 1.0000000000000113
                   , 0.9091316915692761
                   , 0.8912509381338941
                   , 0.00999607752103932
                   , 0.002396400412489709
                   ]
               )
           ,
               ( S.Elliptic 1 40
               , 8
               ,
                   [ 0.8912509381340187
                   , 0.9544540078760935
                   , 0.8912509373468283
                   , 0.0012285719843938758
                   , 0.009756846621689153
                   ]
               )
           ,
               ( S.Bessel
               , 2
               ,
                   [ 1.0000000000000007
                   , 0.9598192123178328
                   , 0.8320502943378443
                   , 0.26606268183005116
                   , 0.007913458453206056
                   ]
               )
           ,
               ( S.Bessel
               , 5
               ,
                   [ 1.0000000000000002
                   , 0.9868611990927887
                   , 0.9455291716487427
                   , 0.5585125191357375
                   , 0.00033414031746759694
                   ]
               )
           ,
               ( S.Bessel
               , 8
               ,
                   [ 0.9999999999999993
                   , 0.9921060039844528
                   , 0.9671327588313834
                   , 0.7231867292385838
                   , 9.461131309015113e-05
                   ]
               )
           ]

pdeTests :: [(String, Bool)]
pdeTests =
    [ ( "PDE manufactured quadratic " ++ show method
      , ok
            ( do
                g <- D.grid [9] [(0, 1)] [False]
                u <- D.poisson method g [(D.Dirichlet 0, D.Dirichlet 0)] (replicate 9 2)
                e <- D.manufacturedError g (\x -> x !! 0 * (1 - x !! 0)) (D.pdeValues u)
                Right (e < 1e-10 && D.pdeResidual u < 1e-10)
            )
      )
    | method <- [D.FiniteDifference, D.FiniteVolume, D.FiniteElement]
    ]
        ++ [ ("PDE manufactured sine " ++ show (method, rank), manufactured method rank)
           | method <- [D.FiniteDifference, D.FiniteVolume, D.FiniteElement]
           , rank <- [2, 3]
           ]
        ++ [ ( "PDE spectral periodic " ++ show rank
             , ok
                ( do
                    let dims = replicate rank 4
                    g <- D.grid dims (replicate rank (0, 1)) (replicate rank True)
                    let exact x = product (map (\v -> sin (2 * pi * v)) x)
                        source = map (\x -> fromIntegral rank * 4 * pi * pi * exact x) (D.gridCoordinates g)
                    result <- D.spectralPoisson g 0 source
                    err <- D.manufacturedError g exact (D.pdeValues result)
                    Right (err < 1e-8 && D.pdeResidual result < 1e-8)
                )
             )
           | rank <- [1, 2, 3]
           ]
        ++ [
               ( "PDE grid indexing"
               , ok
                    ( do
                        g <- D.grid [3, 4, 5] [(0, 1), (0, 2), (0, 3)] [False, False, True]
                        i <- D.flattenIndex g [2, 1, 4]
                        j <- D.unflattenIndex g i
                        Right (i == 49 && j == [2, 1, 4] && D.gridShape g == [3, 4, 5])
                    )
               )
           , ("PDE invalid oversized shape", left (D.grid [maxBound, maxBound] [(0, 1), (0, 1)] [False, False]))
           ,
               ( "PDE mixed Dirichlet Neumann"
               , ok
                    ( do
                        g <- D.grid [9] [(0, 1)] [False]
                        r <- D.poisson D.FiniteVolume g [(D.Dirichlet 0, D.Neumann 1)] (replicate 9 0)
                        Right (vec (D.pdeValues r) [fromIntegral j / 8 | j <- [0 .. 8 :: Int]])
                    )
               )
           ,
               ( "PDE Robin normal derivative"
               , ok
                    ( do
                        g <- D.grid [9] [(0, 1)] [False]
                        r <- D.poisson D.FiniteDifference g [(D.Dirichlet 0, D.Robin 1 1 2)] (replicate 9 0)
                        Right (vec (D.pdeValues r) [fromIntegral j / 8 | j <- [0 .. 8 :: Int]])
                    )
               )
           ,
               ( "PDE FEM natural Neumann"
               , ok
                    ( do
                        g <- D.grid [9] [(0, 1)] [False]
                        r <- D.poisson D.FiniteElement g [(D.Dirichlet 0, D.Neumann 1)] (replicate 9 0)
                        Right (vec (D.pdeValues r) [fromIntegral j / 8 | j <- [0 .. 8 :: Int]])
                    )
               )
           ,
               ( "PDE FEM Robin boundary mass"
               , ok
                    ( do
                        g <- D.grid [9] [(0, 1)] [False]
                        r <- D.poisson D.FiniteElement g [(D.Dirichlet 0, D.Robin 1 1 2)] (replicate 9 0)
                        Right (vec (D.pdeValues r) [fromIntegral j / 8 | j <- [0 .. 8 :: Int]])
                    )
               )
           ,
               ( "PDE FEM variable diffusivity"
               , ok
                    ( do
                        g <- D.grid [9] [(0, 1)] [False]
                        op <-
                            D.assemblePDE
                                D.FiniteElement
                                g
                                [(D.Dirichlet 0, D.Dirichlet 1)]
                                [1 + fromIntegral j / 8 | j <- [0 .. 8 :: Int]]
                                0
                        r <- D.solveElliptic op (replicate 9 (-1))
                        Right (vec (D.pdeValues r) [fromIntegral j / 8 | j <- [0 .. 8 :: Int]])
                    )
               )
           ,
               ( "PDE FV conservative variable diffusivity"
               , ok
                    ( do
                        g <- D.grid [9] [(0, 1)] [False]
                        op <-
                            D.assemblePDE
                                D.FiniteVolume
                                g
                                [(D.Dirichlet 0, D.Dirichlet 1)]
                                [1 + fromIntegral j / 8 | j <- [0 .. 8 :: Int]]
                                0
                        r <- D.solveElliptic op (replicate 9 (-1))
                        Right (vec (D.pdeValues r) [fromIntegral j / 8 | j <- [0 .. 8 :: Int]])
                    )
               )
           ,
               ( "PDE nullspace rejection"
               , left
                    ( do
                        g <- D.grid [7] [(0, 1)] [False]
                        D.poisson D.FiniteVolume g [(D.Neumann 0, D.Neumann 0)] (replicate 7 0)
                    )
               )
           ,
               ( "PDE contradictory corner rejection"
               , left
                    ( do
                        g <- D.grid [3, 3] [(0, 1), (0, 1)] [False, False]
                        D.assemblePDE
                            D.FiniteVolume
                            g
                            [(D.Dirichlet 0, D.Dirichlet 0), (D.Dirichlet 1, D.Dirichlet 1)]
                            (replicate 9 1)
                            0
                    )
               )
           ,
               ( "PDE periodic mean rejection"
               , left (do g <- D.grid [8] [(0, 1)] [True]; D.spectralPoisson g 0 (replicate 8 1))
               )
           ,
               ( "PDE periodic reaction constant"
               , ok
                    ( do
                        g <- D.grid [8] [(0, 1)] [True]
                        r <- D.spectralPoisson g 2 (replicate 8 6)
                        Right (vec (D.pdeValues r) (replicate 8 3))
                    )
               )
           ,
               ( "PDE sparse stencil storage"
               , ok
                    ( do
                        g <- D.grid [8, 8, 8] (replicate 3 (0, 1)) (replicate 3 True)
                        op <- D.assemblePDE D.FiniteVolume g (replicate 3 (D.Periodic, D.Periodic)) (replicate 512 1) 0
                        Right (Sparse.nonzeros (D.pdeStiffness op) == 7 * 512)
                    )
               )
           ,
               ( "PDE spectral derivative"
               , ok
                    ( do
                        g <- D.grid [16] [(0, 1)] [True]
                        let xs = map (!! 0) (D.gridCoordinates g)
                        y <- D.spectralDerivative g 0 1 (map (\x -> sin (2 * pi * x)) xs)
                        Right (vec y (map (\x -> 2 * pi * cos (2 * pi * x)) xs))
                    )
               )
           ,
               ( "PDE pseudospectral variable diffusion"
               , ok
                    ( do
                        g <- D.grid [16] [(0, 1)] [True]
                        let xs = map (!! 0) (D.gridCoordinates g)
                        y <-
                            D.pseudoSpectralDiffusion g (map (\x -> 2 + sin (2 * pi * x)) xs) (map (\x -> cos (2 * pi * x)) xs)
                        let expected x = -4 * pi * pi * (2 * cos (2 * pi * x) + 2 * sin (2 * pi * x) * cos (2 * pi * x))
                        Right (vec y (map expected xs))
                    )
               )
           ,
               ( "PDE heat semidiscrete decay"
               , ok
                    ( do
                        g <- D.grid [9] [(0, 1)] [False]
                        let initial = [sin (pi * fromIntegral j / 8) | j <- [0 .. 8 :: Int]]
                            times = [0, 0.001 .. 0.005]
                            lambda = 4 * sin (pi / 16) ^ (2 :: Int) * 64
                        trajectory <- D.heat g [(D.Dirichlet 0, D.Dirichlet 0)] 1 times initial
                        Right
                            ( and
                                ( zipWith
                                    (nearTol 1e-7)
                                    (last (O.trajectoryStates trajectory))
                                    (map (* (exp (-lambda * 0.005))) initial)
                                )
                            )
                    )
               )
           ,
               ( "PDE heat CFL rejection"
               , left
                    ( do
                        g <- D.grid [9] [(0, 1)] [False]; D.heat g [(D.Dirichlet 0, D.Dirichlet 0)] 1 [0, 1] (replicate 9 0)
                    )
               )
           ,
               ( "PDE periodic wave"
               , ok
                    ( do
                        g <- D.grid [8] [(0, 1)] [True]
                        let initial = [sin (2 * pi * fromIntegral j / 8) | j <- [0 .. 7 :: Int]]
                        ys <- D.wave g 1 [0, 0.001 .. 0.01] initial (replicate 8 0)
                        Right (and (zipWith (nearTol 1e-6) (last ys) (map (* (cos (2 * pi * 0.01))) initial)))
                    )
               )
           ,
               ( "PDE advection conservation"
               , ok
                    ( do
                        g <- D.grid [16] [(0, 1)] [True]
                        ys <- D.advection g [1] [0, 0.01 .. 0.1] (map (+ 2) (signal 16))
                        Right (all (near (sum (map (+ 2) (signal 16))) . sum) ys)
                    )
               )
           ,
               ( "PDE advection diffusion constant"
               , ok
                    ( do
                        g <- D.grid [16] [(0, 1)] [True]
                        ys <- D.advectionDiffusion g [1] 0.1 [0, 0.001 .. 0.01] (replicate 16 3)
                        Right (all (`vec` replicate 16 3) ys)
                    )
               )
           ,
               ( "PDE spatial gradient quadratic"
               , ok
                    ( do
                        g <- D.grid [9] [(0, 1)] [False]
                        ys <- D.spatialGradient g [(fromIntegral j / 8) ^ (2 :: Int) | j <- [0 .. 8 :: Int]]
                        Right (vec (ys !! 0) [fromIntegral j / 4 | j <- [0 .. 8 :: Int]])
                    )
               )
           ,
               ( "PDE CFL combined diagnostic"
               , ok
                    ( do
                        g <- D.grid [16] [(0, 1)] [True]
                        c <- D.cflNumber g 0.1 [1] 0.001
                        Right (near c (0.001 * (16 + 2 * 0.1 * 256)))
                    )
               )
           ,
               ( "PDE Helmholtz manufactured"
               , ok
                    ( do
                        g <- D.grid [9] [(0, 1)] [False]
                        let exact = [sin (pi * fromIntegral j / 8) | j <- [0 .. 8 :: Int]]
                            lambda = 4 * sin (pi / 16) ^ (2 :: Int) * 64
                        r <-
                            D.helmholtz D.FiniteDifference g [(D.Dirichlet 0, D.Dirichlet 0)] 1 (map (* (lambda - 1)) exact)
                        Right (vec (D.pdeValues r) exact)
                    )
               )
           ]
  where
    manufactured method rank =
        ok
            ( do
                let dims = replicate rank 5; bc = replicate rank (D.Dirichlet 0, D.Dirichlet 0)
                g <- D.grid dims (replicate rank (0, 1)) (replicate rank False)
                let exact x = product (map (\t -> sin (pi * t)) x)
                    forcing = map (\x -> fromIntegral rank * pi * pi * exact x) (D.gridCoordinates g)
                result <- D.poisson method g bc forcing
                e <- D.manufacturedError g exact (D.pdeValues result)
                Right (e < 0.16 && D.pdeResidual result < 1e-8)
            )

signalBatchIOTests :: [(String, IO Bool)]
signalBatchIOTests =
    [
        ( "FFT in-place round trip"
        , withArray
            (complexSignal 16)
            ( \pointer -> do
                case (F.planFFT F.Forward F.Radix2 16, F.planFFT F.Inverse F.Radix2 16) of
                    (Right p, Right q) -> do
                        a <- F.fftInPlace p pointer 16
                        b <- F.fftInPlace q pointer 16
                        ys <- peekArray 16 pointer
                        pure (a == Right () && b == Right () && cvec ys (complexSignal 16))
                    _ -> pure False
            )
        )
    ,
        ( "FFT in-place invalid buffer"
        , case F.planFFT F.Forward F.Radix2 4 of
            Left _ -> pure False
            Right p -> do a <- F.fftInPlace p nullPtr 4; pure (left a)
        )
    ]

-- Adversarial finite inputs exercise the checks before expensive allocation or
-- unsafe arithmetic, and refinement tests measure actual continuum convergence.
guardAndConvergenceTests :: [(String, Bool)]
guardAndConvergenceTests =
    [
        ( "cubic Hermite supplied slopes"
        , ok
            ( do
                p <- I.cubicHermite [(0, 0, 0), (1, 1, 3)]
                v <- I.evaluatePiecewise I.Reject p 0.5
                Right (near v 0.125)
            )
        )
    ,
        ( "Gaussian state clips tiny negative variance"
        , ok (do state <- S.gaussianState [0] [[-1e-13]]; Right (S.stateCovariance state == [[0]]))
        )
    ,
        ( "Gaussian state stores positive semidefinite factor reconstruction"
        , ok
            ( do
                state <- S.gaussianState [0, 0] [[0, 1e-13], [1e-13, 0]]
                Right (S.stateCovariance state == [[0, 0], [0, 0]])
            )
        )
    ,
        ( "Gaussian state clips near semidefinite negative pivot"
        , ok
            ( do
                state <- S.gaussianState [0, 0] [[1, 1], [1, 1 - 1e-13]]
                Right (S.stateCovariance state == [[1, 1], [1, 1]])
            )
        )
    , ("FFT overflowing frequency bins reject", left (F.frequencies 4 5e-324))
    , ("STFT frame storage budget rejects", left (F.stft (replicate 1024 1) 1 (replicate 2048 0)))
    , ("PSD overflowing normalization rejects", left (F.periodogram 1e308 [1e100, 1e100] [1, 1]))
    , ("phase unwrap overflow rejects safely", left (S.unwrapPhase [1e308, -1e308]))
    , ("zero crossing huge scale stable", rightVec (S.zeroCrossings [-1e308, 1e308]) [0.5])
    , ("zero crossing subnormal stable", rightVec (S.zeroCrossings [-5e-324, 5e-324]) [0.5])
    , ("RMS avoids representable result overflow", rightNear (S.rms [1e308, 1e308]) 1e308)
    , ("SNR avoids ratio overflow", rightNear (S.signalToNoise [1e300] [1e-300]) 12000)
    ,
        ( "PDE rounded-away coordinates rejected"
        , left (D.grid [9] [(1e308, 1.0000000000000002e308)] [False])
        )
    ,
        ( "PDE periodic mean-free gauge"
        , ok
            ( do
                g <- D.grid [8] [(0, 1)] [True]
                r <- D.spectralPoisson g 0 (replicate 8 0)
                Right (vec (D.pdeValues r) (replicate 8 0))
            )
        )
    ]
        ++ [ ( "PDE second-order refinement " ++ show (method, rank)
             , ok
                ( do
                    coarse <- errorFor method rank 3
                    fine <- errorFor method rank 5
                    Right (coarse > 0.05 && fine < coarse / 2.5)
                )
             )
           | method <- [D.FiniteDifference, D.FiniteVolume, D.FiniteElement]
           , rank <- [1, 2, 3]
           ]
  where
    errorFor method rank count = do
        g <- D.grid (replicate rank count) (replicate rank (0, 1)) (replicate rank False)
        let exact x = product (map (\t -> sin (pi * t)) x)
            forcing = map (\x -> fromIntegral rank * pi * pi * exact x) (D.gridCoordinates g)
        result <- D.poisson method g (replicate rank (D.Dirichlet 0, D.Dirichlet 0)) forcing
        D.manufacturedError g exact (D.pdeValues result)
