{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE FlexibleInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}
-- SPDX-License-Identifier: MPL-2.0
-- Generated representation adapters; numerical functions are the originals.
module HMath.FFI.SpectralAll where
import Foreign
import Foreign.C
import qualified HMath.FFI.Boundary as B
import HMath.FFI.NumericalCodec
import qualified HMath.FFI.Value as V
import qualified HMath.Signal as S
import qualified HMath.Interpolation as I
import qualified HMath.Fourier as F
import HMath.FFI.NumericalAll ()
import Data.Complex (Complex)
instance From S.Filter where from = unbox 360
instance To S.Filter where
    to value = pure (box 360 value [to (S.filterCoefficients value),to (S.filterState value)])
instance From S.FilterFamily where from = unbox 361
instance To S.FilterFamily where
    to value = pure (box 361 value [])
instance From S.FilterBand where from = unbox 362
instance To S.FilterBand where
    to value = pure (box 362 value [])
instance From S.Window where from = unbox 363
instance To S.Window where
    to value = pure (box 363 value [])
instance From S.Peak where from = unbox 364
instance To S.Peak where
    to value = pure (box 364 value [to (S.peakIndex value),to (S.peakHeight value),to (S.peakProminence value),to (S.peakWidth value)])
instance From S.Wavelet where from = unbox 365
instance To S.Wavelet where
    to value = pure (box 365 value [])
instance From S.WaveletTree where from = unbox 366
instance To S.WaveletTree where
    to value = pure (box 366 value [to (S.waveletApproximation value),to (S.waveletDetails value)])
instance From S.MotherWavelet where from = unbox 367
instance To S.MotherWavelet where
    to value = pure (box 367 value [])
instance From S.WaveletPacket where from = unbox 368
instance To S.WaveletPacket where
    to value = pure (box 368 value [to (S.packetBands value)])
instance From I.Extrapolation where from = unbox 369
instance To I.Extrapolation where
    to value = pure (box 369 value [])
instance From I.InterpolationMethod where from = unbox 370
instance To I.InterpolationMethod where
    to value = pure (box 370 value [])
instance From I.SplineBoundary where from = unbox 371
instance To I.SplineBoundary where
    to value = pure (box 371 value [])
instance From I.PiecewisePolynomial where from = unbox 372
instance To I.PiecewisePolynomial where
    to value = pure (box 372 value [to (I.piecewiseKnots value)])
instance From I.BSpline where from = unbox 373
instance To I.BSpline where
    to value = pure (box 373 value [])
instance From I.RadialKernel where from = unbox 374
instance To I.RadialKernel where
    to value = pure (box 374 value [])
instance From I.RBF where from = unbox 375
instance To I.RBF where
    to value = pure (box 375 value [])
instance From I.Approximation where from = unbox 376
instance To I.Approximation where
    to value = pure (box 376 value [to (I.approximationCoefficients value),to (I.approximationError value),to (I.approximationIterations value)])
instance From F.Direction where from = unbox 377
instance To F.Direction where
    to value = pure (box 377 value [])
instance From F.FFTAlgorithm where from = unbox 378
instance To F.FFTAlgorithm where
    to value = pure (box 378 value [])
instance From F.FFTPlan where from = unbox 379
instance To F.FFTPlan where
    to value = pure (box 379 value [])
instance From F.TransformType where from = unbox 380
instance To F.TransformType where
    to value = pure (box 380 value [])
instance From F.STFT where from = unbox 381
instance To F.STFT where
    to value = pure (box 381 value [to (F.stftFrames value)])
foreign export ccall "hm_spectral_apply" dispatch :: CInt -> Ptr (StablePtr V.Value) -> CSize -> Ptr (StablePtr V.Value) -> IO CInt
dispatch :: CInt -> Ptr (StablePtr V.Value) -> CSize -> Ptr (StablePtr V.Value) -> IO CInt
dispatch operation input arity out = B.boundary $ do
    values <- peekArray (fromIntegral arity) input >>= mapM deRefStablePtr
    result <- case operation of
        0 -> apply S.iir values
        1 -> apply S.fir values
        2 -> apply S.filterCoefficients values
        3 -> apply S.filterState values
        4 -> apply S.resetFilter values
        5 -> apply S.filterSignal values
        6 -> apply S.frequencyResponse values
        7 -> apply S.Butterworth values
        8 -> apply S.ChebyshevI values
        9 -> apply S.ChebyshevII values
        10 -> apply S.Elliptic values
        11 -> apply S.Bessel values
        12 -> apply S.Lowpass values
        13 -> apply S.Highpass values
        14 -> apply S.Bandpass values
        15 -> apply S.Bandstop values
        16 -> apply S.designIIR values
        17 -> apply S.notch values
        18 -> apply S.allPass values
        19 -> apply S.wiener values
        20 -> apply S.Hann values
        21 -> apply S.Hamming values
        22 -> apply S.Blackman values
        23 -> apply S.Bartlett values
        24 -> apply S.Kaiser values
        25 -> apply S.Gaussian values
        26 -> apply S.Tukey values
        27 -> apply S.FlatTop values
        28 -> apply S.DolphChebyshev values
        29 -> apply S.window values
        30 -> apply S.windowedSinc values
        31 -> apply S.Peak values
        32 -> apply S.peakIndex values
        33 -> apply S.peakHeight values
        34 -> apply S.peakProminence values
        35 -> apply S.peakWidth values
        36 -> apply S.peaks values
        37 -> apply S.kalman values
        38 -> apply S.extendedKalman values
        39 -> apply S.unscentedKalman values
        40 -> apply S.Haar values
        41 -> apply S.Daubechies2 values
        42 -> apply S.Daubechies4 values
        43 -> apply S.Biorthogonal53 values
        44 -> apply S.waveletApproximation values
        45 -> apply S.waveletDetails values
        46 -> apply S.dwt values
        47 -> apply S.idwt values
        48 -> apply S.Morlet values
        49 -> apply S.MexicanHat values
        50 -> apply S.GaussianDerivative values
        51 -> apply S.cwt values
        52 -> apply S.waveletPackets values
        53 -> apply S.inverseWaveletPackets values
        54 -> apply S.packetBands values
        55 -> apply S.waveletDenoise values
        56 -> apply I.Reject values
        57 -> apply I.Clamp values
        58 -> apply I.Extrapolate values
        59 -> apply I.Nearest values
        60 -> apply I.Linear values
        61 -> apply I.Lagrange values
        62 -> apply I.Newton values
        63 -> apply I.Barycentric values
        64 -> apply I.Natural values
        65 -> apply I.Clamped values
        66 -> apply I.Periodic values
        67 -> apply I.Gaussian values
        68 -> apply I.Multiquadric values
        69 -> apply I.InverseMultiquadric values
        70 -> apply I.ThinPlate values
        71 -> apply I.Cubic values
        72 -> apply I.Approximation values
        73 -> apply I.approximationCoefficients values
        74 -> apply I.approximationError values
        75 -> apply I.approximationIterations values
        76 -> apply I.interpolate values
        77 -> apply I.hermite values
        78 -> apply I.piecewisePolynomial values
        79 -> apply I.piecewiseKnots values
        80 -> apply I.evaluatePiecewise values
        81 -> apply I.differentiatePiecewise values
        82 -> apply I.integratePiecewise values
        83 -> apply I.cubicHermite values
        84 -> apply I.cubicSpline values
        85 -> apply I.pchip values
        86 -> apply I.akima values
        87 -> apply I.smoothingSpline values
        88 -> apply I.bSpline values
        89 -> apply I.evaluateBSpline values
        90 -> apply I.derivativeBSpline values
        91 -> apply I.insertKnot values
        92 -> apply I.rationalBezier values
        93 -> apply I.bezier values
        94 -> apply I.kochanekBartels values
        95 -> apply I.cardinalSpline values
        96 -> apply I.catmullRom values
        97 -> apply I.curveIntegral values
        98 -> apply I.arcLength values
        99 -> apply I.gridInterpolate values
        100 -> apply I.fitRBF values
        101 -> apply I.evaluateRBF values
        102 -> apply I.inverseDistance values
        103 -> apply I.shepard values
        104 -> apply I.kriging values
        105 -> apply I.polynomialFit values
        106 -> apply I.chebyshevApproximate values
        107 -> apply I.pade values
        108 -> apply I.rationalFit values
        109 -> apply I.remez values
        110 -> apply I.nonlinearFit values
        111 -> apply I.interpolationError values
        112 -> apply F.Forward values
        113 -> apply F.Inverse values
        114 -> apply F.Automatic values
        115 -> apply F.Direct values
        116 -> apply F.Radix2 values
        117 -> apply F.Radix4 values
        118 -> apply F.MixedRadix values
        119 -> apply F.SplitRadix values
        120 -> apply F.Bluestein values
        121 -> apply F.Rader values
        122 -> apply F.TypeI values
        123 -> apply F.TypeII values
        124 -> apply F.TypeIII values
        125 -> apply F.TypeIV values
        126 -> apply F.planFFT values
        127 -> apply F.executeFFT values
        128 -> apply F.fft values
        129 -> apply F.ifft values
        130 -> apply F.dft values
        131 -> apply F.realFFT values
        132 -> apply F.inverseRealFFT values
        133 -> apply F.fftBatch values
        134 -> apply F.fftND values
        135 -> apply F.dct values
        136 -> apply F.idct values
        137 -> apply F.dst values
        138 -> apply F.idst values
        139 -> apply F.stftFrames values
        140 -> apply F.stft values
        141 -> apply F.istft values
        142 -> apply F.magnitudeSpectrum values
        143 -> apply F.phaseSpectrum values
        144 -> apply F.powerSpectrum values
        145 -> apply F.crossSpectrum values
        146 -> apply F.spectrogram values
        147 -> apply F.analyticSignal values
        148 -> apply F.chirpZ values
        149 -> apply F.goertzel values
        150 -> apply F.fftConvolve values
        151 -> apply F.fftCorrelate values
        152 -> apply (F.fftShift :: [V.Value] -> [V.Value]) values
        153 -> apply (F.ifftShift :: [V.Value] -> [V.Value]) values
        _ -> V.invalid "unknown numerical operation"
    V.forceValue result
    B.checked (Right ()) (\_ -> V.publish result out)

instance From S.GaussianState where from = unbox 140
instance To S.GaussianState where
    to value = pure (box 140 value [to (S.stateMean value),to (S.stateCovariance value)])

foreign export ccall "hm_spectral_fft_in_place" rawFFT :: StablePtr V.Value -> Ptr (Complex Double) -> CPtrdiff -> IO CInt
rawFFT :: StablePtr V.Value -> Ptr (Complex Double) -> CPtrdiff -> IO CInt
rawFFT input pointer count = B.boundary $ do
    plan <- deRefStablePtr input >>= from
    outcome <- F.fftInPlace plan pointer (fromIntegral count)
    B.checked outcome (const (pure ()))

foreign export ccall "hm_spectral_describe" describe :: StablePtr V.Value -> Ptr (StablePtr V.Value) -> IO CInt
describe :: StablePtr V.Value -> Ptr (StablePtr V.Value) -> IO CInt
describe input out = B.boundary $ do
    value <- deRefStablePtr input
    rendered <- case value of
        V.Opaque 360 _ _ _ _ -> show <$> (from value :: IO S.Filter)
        V.Opaque 361 _ _ _ _ -> show <$> (from value :: IO S.FilterFamily)
        V.Opaque 362 _ _ _ _ -> show <$> (from value :: IO S.FilterBand)
        V.Opaque 363 _ _ _ _ -> show <$> (from value :: IO S.Window)
        V.Opaque 364 _ _ _ _ -> show <$> (from value :: IO S.Peak)
        V.Opaque 365 _ _ _ _ -> show <$> (from value :: IO S.Wavelet)
        V.Opaque 366 _ _ _ _ -> show <$> (from value :: IO S.WaveletTree)
        V.Opaque 367 _ _ _ _ -> show <$> (from value :: IO S.MotherWavelet)
        V.Opaque 368 _ _ _ _ -> show <$> (from value :: IO S.WaveletPacket)
        V.Opaque 369 _ _ _ _ -> show <$> (from value :: IO I.Extrapolation)
        V.Opaque 370 _ _ _ _ -> show <$> (from value :: IO I.InterpolationMethod)
        V.Opaque 371 _ _ _ _ -> show <$> (from value :: IO I.SplineBoundary)
        V.Opaque 372 _ _ _ _ -> show <$> (from value :: IO I.PiecewisePolynomial)
        V.Opaque 373 _ _ _ _ -> show <$> (from value :: IO I.BSpline)
        V.Opaque 374 _ _ _ _ -> show <$> (from value :: IO I.RadialKernel)
        V.Opaque 375 _ _ _ _ -> show <$> (from value :: IO I.RBF)
        V.Opaque 376 _ _ _ _ -> show <$> (from value :: IO I.Approximation)
        V.Opaque 377 _ _ _ _ -> show <$> (from value :: IO F.Direction)
        V.Opaque 378 _ _ _ _ -> show <$> (from value :: IO F.FFTAlgorithm)
        V.Opaque 379 _ _ _ _ -> show <$> (from value :: IO F.FFTPlan)
        V.Opaque 380 _ _ _ _ -> show <$> (from value :: IO F.TransformType)
        V.Opaque 381 _ _ _ _ -> show <$> (from value :: IO F.STFT)
        V.Opaque 140 _ _ _ _ -> show <$> (from value :: IO S.GaussianState)
        _ -> V.invalid "expected a spectral-domain object"
    B.checked (Right ()) (const (V.publish (V.Text rendered) out))
