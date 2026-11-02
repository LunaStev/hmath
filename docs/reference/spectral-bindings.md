# Signal, Fourier and interpolation bindings

Python uses `hmath.signal`, `hmath.fourier` and `hmath.interpolation`. C includes `hmath_spectral.h` and uses immutable owned [structured values](values.md). Existing scalar entry points remain available. Every operation calls the original implementation.

Forward Fourier exponents are negative; inverse transforms divide by N. DCT/DST retain the original orthonormal type I–IV definitions. Plans retain the original bounded reference algorithms and are reusable immutable objects. They do not substitute a different transform provider.

Interpolation preserves strictly increasing unique finite samples, exact extrapolation choices and ascending local polynomial coefficients. Error values remain the source's sampled estimates. Signal filters preserve state continuation, window definitions, boundary conventions, Kalman updates and wavelet coefficient ordering. Source work/shape/iteration limits remain in force.

Inputs are borrowed for a synchronous call and successful C outputs own one reference. Output pointers remain untouched on failure. Immutable objects support concurrent readers retaining references and using independent output addresses. Function arguments use kind101 callbacks from `hmath_linear_callback`, with a tuple of flattened positional arguments. Python accepts ordinary callables and retains their owners; exceptions are re-raised after native cleanup. Source MathError returns status11 with a lossless payload. Cancellation is checked before entry.

## `signal.iir`

`signal.iir(numerator, denominator)`

Normalize finite ascending z^-1 coefficients by nonzero a0 and initialize a zero transposed-direct-form-II state.

Original: [`HMath.Signal.iir`](haskell/HMath-Signal.md#v:iir).

```haskell
[Double] -> [Double] -> Either MathError Filter
```

```c
hmath_status hmath_signal_value_iir(hmath_context *context, const hmath_value *numerator, const hmath_value *denominator, hmath_value **out);
```

## `signal.fir`

`signal.fir(b)`

Construct a causal zero-state finite-impulse-response filter; maximum 257 taps.

Original: [`HMath.Signal.fir`](haskell/HMath-Signal.md#v:fir).

```haskell
[Double] -> Either MathError Filter
```

```c
hmath_status hmath_signal_value_fir(hmath_context *context, const hmath_value *b, hmath_value **out);
```

## `signal.filter_coefficients`

`signal.filter_coefficients(value)`

Read normalized padded (numerator,denominator) coefficients in increasing delay order.

Original: [`HMath.Signal.filterCoefficients`](haskell/HMath-Signal.md#v:filterCoefficients).

```haskell
Filter -> ([Double], [Double])
```

```c
hmath_status hmath_signal_value_filter_coefficients(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.filter_state`

`signal.filter_state(value)`

Read explicit delay state after a block; the list is immutable and independently reusable.

Original: [`HMath.Signal.filterState`](haskell/HMath-Signal.md#v:filterState).

```haskell
Filter -> [Double]
```

```c
hmath_status hmath_signal_value_filter_state(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.reset_filter`

`signal.reset_filter(value)`

Preserve coefficients while replacing every delay with zero.

Original: [`HMath.Signal.resetFilter`](haskell/HMath-Signal.md#v:resetFilter).

```haskell
Filter -> Filter
```

```c
hmath_status hmath_signal_value_reset_filter(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.filter_signal`

`signal.filter_signal(value, value2)`

Process a finite input block, returning both its output and the filter state for the next block.

Original: [`HMath.Signal.filterSignal`](haskell/HMath-Signal.md#v:filterSignal).

```haskell
Filter -> [Double] -> Either MathError ([Double], Filter)
```

```c
hmath_status hmath_signal_value_filter_signal(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `signal.frequency_response`

`signal.frequency_response(value, value2)`

Complex unit-circle response at omega radians/sample; reject poles and nonfinite arithmetic.

Original: [`HMath.Signal.frequencyResponse`](haskell/HMath-Signal.md#v:frequencyResponse).

```haskell
Filter -> Double -> Either MathError (Complex Double)
```

```c
hmath_status hmath_signal_value_frequency_response(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `signal.butterworth`

`signal.butterworth()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Butterworth`](haskell/HMath-Signal.md#v:Butterworth).

```haskell
FilterFamily
```

```c
hmath_status hmath_signal_value_butterworth(hmath_context *context, hmath_value **out);
```

## `signal.chebyshev_i`

`signal.chebyshev_i(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.ChebyshevI`](haskell/HMath-Signal.md#v:ChebyshevI).

```haskell
Double -> FilterFamily
```

```c
hmath_status hmath_signal_value_chebyshev_i(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.chebyshev_ii`

`signal.chebyshev_ii(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.ChebyshevII`](haskell/HMath-Signal.md#v:ChebyshevII).

```haskell
Double -> FilterFamily
```

```c
hmath_status hmath_signal_value_chebyshev_ii(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.elliptic`

`signal.elliptic(value, value2)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Elliptic`](haskell/HMath-Signal.md#v:Elliptic).

```haskell
Double -> Double -> FilterFamily
```

```c
hmath_status hmath_signal_value_elliptic(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `signal.bessel`

`signal.bessel()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Bessel`](haskell/HMath-Signal.md#v:Bessel).

```haskell
FilterFamily
```

```c
hmath_status hmath_signal_value_bessel(hmath_context *context, hmath_value **out);
```

## `signal.lowpass`

`signal.lowpass(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Lowpass`](haskell/HMath-Signal.md#v:Lowpass).

```haskell
Double -> FilterBand
```

```c
hmath_status hmath_signal_value_lowpass(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.highpass`

`signal.highpass(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Highpass`](haskell/HMath-Signal.md#v:Highpass).

```haskell
Double -> FilterBand
```

```c
hmath_status hmath_signal_value_highpass(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.bandpass`

`signal.bandpass(value, value2)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Bandpass`](haskell/HMath-Signal.md#v:Bandpass).

```haskell
Double -> Double -> FilterBand
```

```c
hmath_status hmath_signal_value_bandpass(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `signal.bandstop`

`signal.bandstop(value, value2)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Bandstop`](haskell/HMath-Signal.md#v:Bandstop).

```haskell
Double -> Double -> FilterBand
```

```c
hmath_status hmath_signal_value_bandstop(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `signal.design_iir`

`signal.design_iir(family, band, order, rate)`

 Orders 1..8; ripple/attenuation in dB; all edges strictly inside (0, fs/2). Expanded coefficients are a bounded reference representation; high orders should use cascaded sections in production applications. 

Original: [`HMath.Signal.designIIR`](haskell/HMath-Signal.md#v:designIIR).

```haskell
FilterFamily -> FilterBand -> Int -> Double -> Either MathError Filter
```

```c
hmath_status hmath_signal_value_design_iir(hmath_context *context, const hmath_value *family, const hmath_value *band, const hmath_value *order, const hmath_value *rate, hmath_value **out);
```

## `signal.notch`

`signal.notch(omega, quality)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.notch`](haskell/HMath-Signal.md#v:notch).

```haskell
Double -> Double -> Either MathError Filter
```

```c
hmath_status hmath_signal_value_notch(hmath_context *context, const hmath_value *omega, const hmath_value *quality, hmath_value **out);
```

## `signal.all_pass`

`signal.all_pass(omega, quality)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.allPass`](haskell/HMath-Signal.md#v:allPass).

```haskell
Double -> Double -> Either MathError Filter
```

```c
hmath_status hmath_signal_value_all_pass(hmath_context *context, const hmath_value *omega, const hmath_value *quality, hmath_value **out);
```

## `signal.wiener`

`signal.wiener(width, noise, xs)`

Local mean/variance Wiener shrinkage; optional noise variance, otherwise average local variance is estimated.

Original: [`HMath.Signal.wiener`](haskell/HMath-Signal.md#v:wiener).

```haskell
Int -> Maybe Double -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_signal_value_wiener(hmath_context *context, const hmath_value *width, const hmath_value *noise, const hmath_value *xs, hmath_value **out);
```

## `signal.hann`

`signal.hann()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Hann`](haskell/HMath-Signal.md#v:Hann).

```haskell
Window
```

```c
hmath_status hmath_signal_value_hann(hmath_context *context, hmath_value **out);
```

## `signal.hamming`

`signal.hamming()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Hamming`](haskell/HMath-Signal.md#v:Hamming).

```haskell
Window
```

```c
hmath_status hmath_signal_value_hamming(hmath_context *context, hmath_value **out);
```

## `signal.blackman`

`signal.blackman()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Blackman`](haskell/HMath-Signal.md#v:Blackman).

```haskell
Window
```

```c
hmath_status hmath_signal_value_blackman(hmath_context *context, hmath_value **out);
```

## `signal.bartlett`

`signal.bartlett()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Bartlett`](haskell/HMath-Signal.md#v:Bartlett).

```haskell
Window
```

```c
hmath_status hmath_signal_value_bartlett(hmath_context *context, hmath_value **out);
```

## `signal.kaiser`

`signal.kaiser(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Kaiser`](haskell/HMath-Signal.md#v:Kaiser).

```haskell
Double -> Window
```

```c
hmath_status hmath_signal_value_kaiser(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.gaussian`

`signal.gaussian(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Gaussian`](haskell/HMath-Signal.md#v:Gaussian).

```haskell
Double -> Window
```

```c
hmath_status hmath_signal_value_gaussian(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.tukey`

`signal.tukey(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Tukey`](haskell/HMath-Signal.md#v:Tukey).

```haskell
Double -> Window
```

```c
hmath_status hmath_signal_value_tukey(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.flat_top`

`signal.flat_top()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.FlatTop`](haskell/HMath-Signal.md#v:FlatTop).

```haskell
Window
```

```c
hmath_status hmath_signal_value_flat_top(hmath_context *context, hmath_value **out);
```

## `signal.dolph_chebyshev`

`signal.dolph_chebyshev(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.DolphChebyshev`](haskell/HMath-Signal.md#v:DolphChebyshev).

```haskell
Double -> Window
```

```c
hmath_status hmath_signal_value_dolph_chebyshev(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.window`

`signal.window(kind, n)`

Generate a finite symmetric window. Gaussian sigma is relative to half length; Dolph attenuation is in dB.

Original: [`HMath.Signal.window`](haskell/HMath-Signal.md#v:window).

```haskell
Window -> Int -> Either MathError [Double]
```

```c
hmath_status hmath_signal_value_window(hmath_context *context, const hmath_value *kind, const hmath_value *n, hmath_value **out);
```

## `signal.windowed_sinc`

`signal.windowed_sinc(kind, taps, cutoff, rate)`

 Given window kind, odd tap count in [1,257], cutoff frequency and positive sample rate, return normalized low-pass FIR coefficients. Require 0\<cutoff\<rate/2 and finite parameters; invalid values or normalization failure returns Left MathError. 

Original: [`HMath.Signal.windowedSinc`](haskell/HMath-Signal.md#v:windowedSinc).

```haskell
Window -> Int -> Double -> Double -> Either MathError [Double]
```

```c
hmath_status hmath_signal_value_windowed_sinc(hmath_context *context, const hmath_value *kind, const hmath_value *taps, const hmath_value *cutoff, const hmath_value *rate, hmath_value **out);
```

## `signal.peak`

`signal.peak(peak_index, peak_height, peak_prominence, peak_width)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Peak`](haskell/HMath-Signal.md#v:Peak).

```haskell
Int -> Double -> Double -> Double -> Peak
```

```c
hmath_status hmath_signal_value_peak(hmath_context *context, const hmath_value *peak_index, const hmath_value *peak_height, const hmath_value *peak_prominence, const hmath_value *peak_width, hmath_value **out);
```

## `signal.peak_index`

`signal.peak_index(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.peakIndex`](haskell/HMath-Signal.md#v:peakIndex).

```haskell
Peak -> Int
```

```c
hmath_status hmath_signal_value_peak_index(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.peak_height`

`signal.peak_height(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.peakHeight`](haskell/HMath-Signal.md#v:peakHeight).

```haskell
Peak -> Double
```

```c
hmath_status hmath_signal_value_peak_height(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.peak_prominence`

`signal.peak_prominence(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.peakProminence`](haskell/HMath-Signal.md#v:peakProminence).

```haskell
Peak -> Double
```

```c
hmath_status hmath_signal_value_peak_prominence(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.peak_width`

`signal.peak_width(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.peakWidth`](haskell/HMath-Signal.md#v:peakWidth).

```haskell
Peak -> Double
```

```c
hmath_status hmath_signal_value_peak_width(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.peaks`

`signal.peaks(minimum_prominence, minimum_distance, xs)`

 Interior local maxima; flat plateaus select the lower middle index. Width is linearly interpolated at half prominence; endpoints are not peaks. 

Original: [`HMath.Signal.peaks`](haskell/HMath-Signal.md#v:peaks).

```haskell
Double -> Int -> [Double] -> Either MathError [Peak]
```

```c
hmath_status hmath_signal_value_peaks(hmath_context *context, const hmath_value *minimum_prominence, const hmath_value *minimum_distance, const hmath_value *xs, hmath_value **out);
```

## `signal.kalman`

`signal.kalman(value, value2, value3, value4, value5, value6)`

 One linear Gaussian prediction+measurement update. Uses Joseph covariance update to preserve positive semidefiniteness under roundoff. 

Original: [`HMath.Signal.kalman`](haskell/HMath-Signal.md#v:kalman).

```haskell
[[Double]] -> [[Double]] -> [[Double]] -> [[Double]] -> [Double] -> GaussianState -> Either MathError GaussianState
```

```c
hmath_status hmath_signal_value_kalman(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, const hmath_value *value6, hmath_value **out);
```

## `signal.extended_kalman`

`signal.extended_kalman(value, value2, value3, value4, value5, value6)`

EKF with checked central-difference Jacobians (step 1e-5*max(1,abs x)).

Original: [`HMath.Signal.extendedKalman`](haskell/HMath-Signal.md#v:extendedKalman).

```haskell
([Double] -> [Double]) -> ([Double] -> [Double]) -> [[Double]] -> [[Double]] -> [Double] -> GaussianState -> Either MathError GaussianState
```

```c
hmath_status hmath_signal_value_extended_kalman(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, const hmath_value *value6, hmath_value **out);
```

## `signal.unscented_kalman`

`signal.unscented_kalman(alpha, beta, kappa, transition, measurement, q, r, measured, state)`

 Scaled UKF. alpha>0, beta>=0, n+kappa>0, lambda+n>0. Process noise is incorporated before regenerating measurement sigma points. 

Original: [`HMath.Signal.unscentedKalman`](haskell/HMath-Signal.md#v:unscentedKalman).

```haskell
Double -> Double -> Double -> ([Double] -> [Double]) -> ([Double] -> [Double]) -> [[Double]] -> [[Double]] -> [Double] -> GaussianState -> Either MathError GaussianState
```

```c
hmath_status hmath_signal_value_unscented_kalman(hmath_context *context, const hmath_value *alpha, const hmath_value *beta, const hmath_value *kappa, const hmath_value *transition, const hmath_value *measurement, const hmath_value *q, const hmath_value *r, const hmath_value *measured, const hmath_value *state, hmath_value **out);
```

## `signal.haar`

`signal.haar()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Haar`](haskell/HMath-Signal.md#v:Haar).

```haskell
Wavelet
```

```c
hmath_status hmath_signal_value_haar(hmath_context *context, hmath_value **out);
```

## `signal.daubechies2`

`signal.daubechies2()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Daubechies2`](haskell/HMath-Signal.md#v:Daubechies2).

```haskell
Wavelet
```

```c
hmath_status hmath_signal_value_daubechies2(hmath_context *context, hmath_value **out);
```

## `signal.daubechies4`

`signal.daubechies4()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Daubechies4`](haskell/HMath-Signal.md#v:Daubechies4).

```haskell
Wavelet
```

```c
hmath_status hmath_signal_value_daubechies4(hmath_context *context, hmath_value **out);
```

## `signal.biorthogonal53`

`signal.biorthogonal53()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Biorthogonal53`](haskell/HMath-Signal.md#v:Biorthogonal53).

```haskell
Wavelet
```

```c
hmath_status hmath_signal_value_biorthogonal53(hmath_context *context, hmath_value **out);
```

## `signal.wavelet_approximation`

`signal.wavelet_approximation(value)`

Coarsest approximation coefficients after all requested levels.

Original: [`HMath.Signal.waveletApproximation`](haskell/HMath-Signal.md#v:waveletApproximation).

```haskell
WaveletTree -> [Double]
```

```c
hmath_status hmath_signal_value_wavelet_approximation(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.wavelet_details`

`signal.wavelet_details(value)`

Detail bands ordered from finest first to coarsest last.

Original: [`HMath.Signal.waveletDetails`](haskell/HMath-Signal.md#v:waveletDetails).

```haskell
WaveletTree -> [[Double]]
```

```c
hmath_status hmath_signal_value_wavelet_details(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.dwt`

`signal.dwt(family, levels, xs)`

Periodic multilevel analysis; length must be divisible by 2^levels, with levels 0..20 and length <=1048576.

Original: [`HMath.Signal.dwt`](haskell/HMath-Signal.md#v:dwt).

```haskell
Wavelet -> Int -> [Double] -> Either MathError WaveletTree
```

```c
hmath_status hmath_signal_value_dwt(hmath_context *context, const hmath_value *family, const hmath_value *levels, const hmath_value *xs, hmath_value **out);
```

## `signal.idwt`

`signal.idwt(value)`

Invert multilevel analysis using orthogonal synthesis or inverse CDF 5/3 lifting.

Original: [`HMath.Signal.idwt`](haskell/HMath-Signal.md#v:idwt).

```haskell
WaveletTree -> Either MathError [Double]
```

```c
hmath_status hmath_signal_value_idwt(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.morlet`

`signal.morlet(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.Morlet`](haskell/HMath-Signal.md#v:Morlet).

```haskell
Double -> MotherWavelet
```

```c
hmath_status hmath_signal_value_morlet(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.mexican_hat`

`signal.mexican_hat()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.MexicanHat`](haskell/HMath-Signal.md#v:MexicanHat).

```haskell
MotherWavelet
```

```c
hmath_status hmath_signal_value_mexican_hat(hmath_context *context, hmath_value **out);
```

## `signal.gaussian_derivative`

`signal.gaussian_derivative()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Signal.GaussianDerivative`](haskell/HMath-Signal.md#v:GaussianDerivative).

```haskell
MotherWavelet
```

```c
hmath_status hmath_signal_value_gaussian_derivative(hmath_context *context, hmath_value **out);
```

## `signal.cwt`

`signal.cwt(mother, spacing, scales, xs)`

 Direct zero-extended CWT. Scales are in seconds; coefficients use dt/sqrt(s) quadrature. Morlet subtracts its nonzero-mean correction exp(-omega²/2). 

Original: [`HMath.Signal.cwt`](haskell/HMath-Signal.md#v:cwt).

```haskell
MotherWavelet -> Double -> [Double] -> [Double] -> Either MathError [[Complex Double]]
```

```c
hmath_status hmath_signal_value_cwt(hmath_context *context, const hmath_value *mother, const hmath_value *spacing, const hmath_value *scales, const hmath_value *xs, hmath_value **out);
```

## `signal.wavelet_packets`

`signal.wavelet_packets(family, levels, xs)`

Recursively analyze both approximation and detail branches to the supplied depth.

Original: [`HMath.Signal.waveletPackets`](haskell/HMath-Signal.md#v:waveletPackets).

```haskell
Wavelet -> Int -> [Double] -> Either MathError WaveletPacket
```

```c
hmath_status hmath_signal_value_wavelet_packets(hmath_context *context, const hmath_value *family, const hmath_value *levels, const hmath_value *xs, hmath_value **out);
```

## `signal.inverse_wavelet_packets`

`signal.inverse_wavelet_packets(value)`

Reconstruct a complete packet tree exactly up to floating roundoff.

Original: [`HMath.Signal.inverseWaveletPackets`](haskell/HMath-Signal.md#v:inverseWaveletPackets).

```haskell
WaveletPacket -> Either MathError [Double]
```

```c
hmath_status hmath_signal_value_inverse_wavelet_packets(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.packet_bands`

`signal.packet_bands(value)`

Leaf coefficient bands in natural binary low/high tree order.

Original: [`HMath.Signal.packetBands`](haskell/HMath-Signal.md#v:packetBands).

```haskell
WaveletPacket -> [[Double]]
```

```c
hmath_status hmath_signal_value_packet_bands(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `signal.wavelet_denoise`

`signal.wavelet_denoise(family, levels, threshold, xs)`

Soft-threshold detail coefficients; optional explicit threshold, otherwise finest-band MAD universal threshold.

Original: [`HMath.Signal.waveletDenoise`](haskell/HMath-Signal.md#v:waveletDenoise).

```haskell
Wavelet -> Int -> Maybe Double -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_signal_value_wavelet_denoise(hmath_context *context, const hmath_value *family, const hmath_value *levels, const hmath_value *threshold, const hmath_value *xs, hmath_value **out);
```

## `interpolation.reject`

`interpolation.reject()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.Reject`](haskell/HMath-Interpolation.md#v:Reject).

```haskell
Extrapolation
```

```c
hmath_status hmath_interpolation_value_reject(hmath_context *context, hmath_value **out);
```

## `interpolation.clamp`

`interpolation.clamp()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.Clamp`](haskell/HMath-Interpolation.md#v:Clamp).

```haskell
Extrapolation
```

```c
hmath_status hmath_interpolation_value_clamp(hmath_context *context, hmath_value **out);
```

## `interpolation.extrapolate`

`interpolation.extrapolate()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.Extrapolate`](haskell/HMath-Interpolation.md#v:Extrapolate).

```haskell
Extrapolation
```

```c
hmath_status hmath_interpolation_value_extrapolate(hmath_context *context, hmath_value **out);
```

## `interpolation.nearest`

`interpolation.nearest()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.Nearest`](haskell/HMath-Interpolation.md#v:Nearest).

```haskell
InterpolationMethod
```

```c
hmath_status hmath_interpolation_value_nearest(hmath_context *context, hmath_value **out);
```

## `interpolation.linear`

`interpolation.linear()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.Linear`](haskell/HMath-Interpolation.md#v:Linear).

```haskell
InterpolationMethod
```

```c
hmath_status hmath_interpolation_value_linear(hmath_context *context, hmath_value **out);
```

## `interpolation.lagrange`

`interpolation.lagrange()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.Lagrange`](haskell/HMath-Interpolation.md#v:Lagrange).

```haskell
InterpolationMethod
```

```c
hmath_status hmath_interpolation_value_lagrange(hmath_context *context, hmath_value **out);
```

## `interpolation.newton`

`interpolation.newton()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.Newton`](haskell/HMath-Interpolation.md#v:Newton).

```haskell
InterpolationMethod
```

```c
hmath_status hmath_interpolation_value_newton(hmath_context *context, hmath_value **out);
```

## `interpolation.barycentric`

`interpolation.barycentric()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.Barycentric`](haskell/HMath-Interpolation.md#v:Barycentric).

```haskell
InterpolationMethod
```

```c
hmath_status hmath_interpolation_value_barycentric(hmath_context *context, hmath_value **out);
```

## `interpolation.natural`

`interpolation.natural()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.Natural`](haskell/HMath-Interpolation.md#v:Natural).

```haskell
SplineBoundary
```

```c
hmath_status hmath_interpolation_value_natural(hmath_context *context, hmath_value **out);
```

## `interpolation.clamped`

`interpolation.clamped(value, value2)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.Clamped`](haskell/HMath-Interpolation.md#v:Clamped).

```haskell
Double -> Double -> SplineBoundary
```

```c
hmath_status hmath_interpolation_value_clamped(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `interpolation.periodic`

`interpolation.periodic()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.Periodic`](haskell/HMath-Interpolation.md#v:Periodic).

```haskell
SplineBoundary
```

```c
hmath_status hmath_interpolation_value_periodic(hmath_context *context, hmath_value **out);
```

## `interpolation.gaussian`

`interpolation.gaussian(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.Gaussian`](haskell/HMath-Interpolation.md#v:Gaussian).

```haskell
Double -> RadialKernel
```

```c
hmath_status hmath_interpolation_value_gaussian(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `interpolation.multiquadric`

`interpolation.multiquadric(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.Multiquadric`](haskell/HMath-Interpolation.md#v:Multiquadric).

```haskell
Double -> RadialKernel
```

```c
hmath_status hmath_interpolation_value_multiquadric(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `interpolation.inverse_multiquadric`

`interpolation.inverse_multiquadric(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.InverseMultiquadric`](haskell/HMath-Interpolation.md#v:InverseMultiquadric).

```haskell
Double -> RadialKernel
```

```c
hmath_status hmath_interpolation_value_inverse_multiquadric(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `interpolation.thin_plate`

`interpolation.thin_plate()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.ThinPlate`](haskell/HMath-Interpolation.md#v:ThinPlate).

```haskell
RadialKernel
```

```c
hmath_status hmath_interpolation_value_thin_plate(hmath_context *context, hmath_value **out);
```

## `interpolation.cubic`

`interpolation.cubic()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.Cubic`](haskell/HMath-Interpolation.md#v:Cubic).

```haskell
RadialKernel
```

```c
hmath_status hmath_interpolation_value_cubic(hmath_context *context, hmath_value **out);
```

## `interpolation.approximation`

`interpolation.approximation(approximation_coefficients, approximation_error, approximation_iterations)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.Approximation`](haskell/HMath-Interpolation.md#v:Approximation).

```haskell
[Double] -> Double -> Int -> Approximation
```

```c
hmath_status hmath_interpolation_value_approximation(hmath_context *context, const hmath_value *approximation_coefficients, const hmath_value *approximation_error, const hmath_value *approximation_iterations, hmath_value **out);
```

## `interpolation.approximation_coefficients`

`interpolation.approximation_coefficients(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.approximationCoefficients`](haskell/HMath-Interpolation.md#v:approximationCoefficients).

```haskell
Approximation -> [Double]
```

```c
hmath_status hmath_interpolation_value_approximation_coefficients(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `interpolation.approximation_error`

`interpolation.approximation_error(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.approximationError`](haskell/HMath-Interpolation.md#v:approximationError).

```haskell
Approximation -> Double
```

```c
hmath_status hmath_interpolation_value_approximation_error(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `interpolation.approximation_iterations`

`interpolation.approximation_iterations(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Interpolation.approximationIterations`](haskell/HMath-Interpolation.md#v:approximationIterations).

```haskell
Approximation -> Int
```

```c
hmath_status hmath_interpolation_value_approximation_iterations(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `interpolation.interpolate`

`interpolation.interpolate(method, policy, points, x0)`

Interpolate ordered (x,y) samples using the selected formula and extrapolation policy; nearest ties choose the earlier node.

Original: [`HMath.Interpolation.interpolate`](haskell/HMath-Interpolation.md#v:interpolate).

```haskell
InterpolationMethod -> Extrapolation -> [(Double, Double)] -> Double -> Either MathError Double
```

```c
hmath_status hmath_interpolation_value_interpolate(hmath_context *context, const hmath_value *method, const hmath_value *policy, const hmath_value *points, const hmath_value *x0, hmath_value **out);
```

## `interpolation.hermite`

`interpolation.hermite(triples, x)`

 Global confluent Hermite polynomial, distinct nodes and supplied first derivatives. Uses the squared Lagrange cardinal functions. 

Original: [`HMath.Interpolation.hermite`](haskell/HMath-Interpolation.md#v:hermite).

```haskell
[(Double, Double, Double)] -> Double -> Either MathError Double
```

```c
hmath_status hmath_interpolation_value_hermite(hmath_context *context, const hmath_value *triples, const hmath_value *x, hmath_value **out);
```

## `interpolation.piecewise_polynomial`

`interpolation.piecewise_polynomial(knots, coefficients)`

Validate breakpoints and nonempty coefficient rows. Each row uses ascending powers of displacement from its left knot.

Original: [`HMath.Interpolation.piecewisePolynomial`](haskell/HMath-Interpolation.md#v:piecewisePolynomial).

```haskell
[Double] -> [[Double]] -> Either MathError PiecewisePolynomial
```

```c
hmath_status hmath_interpolation_value_piecewise_polynomial(hmath_context *context, const hmath_value *knots, const hmath_value *coefficients, hmath_value **out);
```

## `interpolation.piecewise_knots`

`interpolation.piecewise_knots(value)`

Return the immutable piecewise breakpoints, including both outer endpoints.

Original: [`HMath.Interpolation.piecewiseKnots`](haskell/HMath-Interpolation.md#v:piecewiseKnots).

```haskell
PiecewisePolynomial -> [Double]
```

```c
hmath_status hmath_interpolation_value_piecewise_knots(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `interpolation.evaluate_piecewise`

`interpolation.evaluate_piecewise(value, value2, value3)`

Evaluate by Horner rule in the containing interval; use the final interval at the right endpoint.

Original: [`HMath.Interpolation.evaluatePiecewise`](haskell/HMath-Interpolation.md#v:evaluatePiecewise).

```haskell
Extrapolation -> PiecewisePolynomial -> Double -> Either MathError Double
```

```c
hmath_status hmath_interpolation_value_evaluate_piecewise(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out);
```

## `interpolation.differentiate_piecewise`

`interpolation.differentiate_piecewise(value)`

Differentiate each local coefficient row without changing the breakpoints.

Original: [`HMath.Interpolation.differentiatePiecewise`](haskell/HMath-Interpolation.md#v:differentiatePiecewise).

```haskell
PiecewisePolynomial -> Either MathError PiecewisePolynomial
```

```c
hmath_status hmath_interpolation_value_differentiate_piecewise(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `interpolation.integrate_piecewise`

`interpolation.integrate_piecewise(value, value2, value3)`

Exact polynomial antiderivative across all crossed intervals; both limits must lie inside the domain.

Original: [`HMath.Interpolation.integratePiecewise`](haskell/HMath-Interpolation.md#v:integratePiecewise).

```haskell
PiecewisePolynomial -> Double -> Double -> Either MathError Double
```

```c
hmath_status hmath_interpolation_value_integrate_piecewise(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out);
```

## `interpolation.cubic_hermite`

`interpolation.cubic_hermite(triples)`

 Piecewise cubic Hermite interpolation with supplied endpoint derivatives. Triples are (coordinate,value,slope); first derivatives are continuous at shared knots, while second derivatives need not agree. 

Original: [`HMath.Interpolation.cubicHermite`](haskell/HMath-Interpolation.md#v:cubicHermite).

```haskell
[(Double, Double, Double)] -> Either MathError PiecewisePolynomial
```

```c
hmath_status hmath_interpolation_value_cubic_hermite(hmath_context *context, const hmath_value *triples, hmath_value **out);
```

## `interpolation.cubic_spline`

`interpolation.cubic_spline(boundary, points)`

 Cubic C2 interpolation. Periodic requires equal endpoint values and at least three intervals; endpoint first and second derivatives agree. 

Original: [`HMath.Interpolation.cubicSpline`](haskell/HMath-Interpolation.md#v:cubicSpline).

```haskell
SplineBoundary -> [(Double, Double)] -> Either MathError PiecewisePolynomial
```

```c
hmath_status hmath_interpolation_value_cubic_spline(hmath_context *context, const hmath_value *boundary, const hmath_value *points, hmath_value **out);
```

## `interpolation.pchip`

`interpolation.pchip(points)`

 Fritsch--Carlson/PCHIP weighted harmonic interior slopes and limited one- sided endpoints preserve monotonicity on monotone data. 

Original: [`HMath.Interpolation.pchip`](haskell/HMath-Interpolation.md#v:pchip).

```haskell
[(Double, Double)] -> Either MathError PiecewisePolynomial
```

```c
hmath_status hmath_interpolation_value_pchip(hmath_context *context, const hmath_value *points, hmath_value **out);
```

## `interpolation.akima`

`interpolation.akima(points)`

Akima cubic interpolation using slope-difference weights and linearly extended endpoint secants; at least three samples.

Original: [`HMath.Interpolation.akima`](haskell/HMath-Interpolation.md#v:akima).

```haskell
[(Double, Double)] -> Either MathError PiecewisePolynomial
```

```c
hmath_status hmath_interpolation_value_akima(hmath_context *context, const hmath_value *points, hmath_value **out);
```

## `interpolation.smoothing_spline`

`interpolation.smoothing_spline(lambda_, points)`

 Natural cubic smoothing spline minimizing sum (y_i-s(x_i))² plus lambda times integral s''². Reinsch Q/R formulation, unit observation weights. 

Original: [`HMath.Interpolation.smoothingSpline`](haskell/HMath-Interpolation.md#v:smoothingSpline).

```haskell
Double -> [(Double, Double)] -> Either MathError PiecewisePolynomial
```

```c
hmath_status hmath_interpolation_value_smoothing_spline(hmath_context *context, const hmath_value *lambda_, const hmath_value *points, hmath_value **out);
```

## `interpolation.b_spline`

`interpolation.b_spline(degree, knots, controls, weights)`

 Nondecreasing full knot vector, degree 0..16, positive rational weights, control points of equal dimension. Evaluation domain [k_p,k_n]. 

Original: [`HMath.Interpolation.bSpline`](haskell/HMath-Interpolation.md#v:bSpline).

```haskell
Int -> [Double] -> [[Double]] -> [Double] -> Either MathError BSpline
```

```c
hmath_status hmath_interpolation_value_b_spline(hmath_context *context, const hmath_value *degree, const hmath_value *knots, const hmath_value *controls, const hmath_value *weights, hmath_value **out);
```

## `interpolation.evaluate_b_spline`

`interpolation.evaluate_b_spline(s, x)`

Evaluate rational Cox--de Boor basis functions and divide homogeneous coordinates by their positive total weight.

Original: [`HMath.Interpolation.evaluateBSpline`](haskell/HMath-Interpolation.md#v:evaluateBSpline).

```haskell
BSpline -> Double -> Either MathError [Double]
```

```c
hmath_status hmath_interpolation_value_evaluate_b_spline(hmath_context *context, const hmath_value *s, const hmath_value *x, hmath_value **out);
```

## `interpolation.derivative_b_spline`

`interpolation.derivative_b_spline(s, x)`

Analytic first derivative of a rational B-spline using basis derivatives and the homogeneous quotient rule.

Original: [`HMath.Interpolation.derivativeBSpline`](haskell/HMath-Interpolation.md#v:derivativeBSpline).

```haskell
BSpline -> Double -> Either MathError [Double]
```

```c
hmath_status hmath_interpolation_value_derivative_b_spline(hmath_context *context, const hmath_value *s, const hmath_value *x, hmath_value **out);
```

## `interpolation.insert_knot`

`interpolation.insert_knot(value, value2)`

One Boehm knot insertion in homogeneous coordinates; shape is preserved.

Original: [`HMath.Interpolation.insertKnot`](haskell/HMath-Interpolation.md#v:insertKnot).

```haskell
BSpline -> Double -> Either MathError BSpline
```

```c
hmath_status hmath_interpolation_value_insert_knot(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `interpolation.rational_bezier`

`interpolation.rational_bezier(controls, ws, t)`

Positive-weight rational Bezier curve on [0,1], represented exactly as an open clamped B-spline (degree <=16).

Original: [`HMath.Interpolation.rationalBezier`](haskell/HMath-Interpolation.md#v:rationalBezier).

```haskell
[[Double]] -> [Double] -> Double -> Either MathError [Double]
```

```c
hmath_status hmath_interpolation_value_rational_bezier(hmath_context *context, const hmath_value *controls, const hmath_value *ws, const hmath_value *t, hmath_value **out);
```

## `interpolation.bezier`

`interpolation.bezier(value, value2)`

Polynomial Bezier curve with unit weights; controls are vectors with 1..16 coordinates.

Original: [`HMath.Interpolation.bezier`](haskell/HMath-Interpolation.md#v:bezier).

```haskell
[[Double]] -> Double -> Either MathError [Double]
```

```c
hmath_status hmath_interpolation_value_bezier(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `interpolation.kochanek_bartels`

`interpolation.kochanek_bartels(tension, continuity, bias, points)`

 Interpolating cubic Hermite segment sequence with Kochanek--Bartels tension, continuity and bias in [-1,1]; endpoint secants are repeated. 

Original: [`HMath.Interpolation.kochanekBartels`](haskell/HMath-Interpolation.md#v:kochanekBartels).

```haskell
Double -> Double -> Double -> [(Double, Double)] -> Either MathError PiecewisePolynomial
```

```c
hmath_status hmath_interpolation_value_kochanek_bartels(hmath_context *context, const hmath_value *tension, const hmath_value *continuity, const hmath_value *bias, const hmath_value *points, hmath_value **out);
```

## `interpolation.cardinal_spline`

`interpolation.cardinal_spline(value, value2)`

Kochanek--Bartels interpolation with zero continuity/bias and supplied tension in [-1,1].

Original: [`HMath.Interpolation.cardinalSpline`](haskell/HMath-Interpolation.md#v:cardinalSpline).

```haskell
Double -> [(Double, Double)] -> Either MathError PiecewisePolynomial
```

```c
hmath_status hmath_interpolation_value_cardinal_spline(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `interpolation.catmull_rom`

`interpolation.catmull_rom(value)`

Cardinal cubic interpolation with zero tension and repeated endpoint secants.

Original: [`HMath.Interpolation.catmullRom`](haskell/HMath-Interpolation.md#v:catmullRom).

```haskell
[(Double, Double)] -> Either MathError PiecewisePolynomial
```

```c
hmath_status hmath_interpolation_value_catmull_rom(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `interpolation.curve_integral`

`interpolation.curve_integral(value, value2, value3, value4)`

Componentwise adaptive integral of a B-spline between in-domain limits, with estimated quadrature errors.

Original: [`HMath.Interpolation.curveIntegral`](haskell/HMath-Interpolation.md#v:curveIntegral).

```haskell
C.Tolerance -> BSpline -> Double -> Double -> Either MathError [C.Estimate Double]
```

```c
hmath_status hmath_interpolation_value_curve_integral(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, hmath_value **out);
```

## `interpolation.arc_length`

`interpolation.arc_length(tolerance, spline, a, b)`

Adaptive integral of the Euclidean analytic derivative norm; limits must increase and remain in the spline domain.

Original: [`HMath.Interpolation.arcLength`](haskell/HMath-Interpolation.md#v:arcLength).

```haskell
C.Tolerance -> BSpline -> Double -> Double -> Either MathError (C.Estimate Double)
```

```c
hmath_status hmath_interpolation_value_arc_length(hmath_context *context, const hmath_value *tolerance, const hmath_value *spline, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `interpolation.grid_interpolate`

`interpolation.grid_interpolate(method, policy, axes, values, point)`

 Rectilinear multilinear interpolation; values are row-major/last axis fast. Nearest uses Euclidean distance to grid nodes; extrapolation policy per axis. 

Original: [`HMath.Interpolation.gridInterpolate`](haskell/HMath-Interpolation.md#v:gridInterpolate).

```haskell
InterpolationMethod -> Extrapolation -> [[Double]] -> [Double] -> [Double] -> Either MathError Double
```

```c
hmath_status hmath_interpolation_value_grid_interpolate(hmath_context *context, const hmath_value *method, const hmath_value *policy, const hmath_value *axes, const hmath_value *values, const hmath_value *point, hmath_value **out);
```

## `interpolation.fit_rbf`

`interpolation.fit_rbf(method, smoothing, nodes, ys)`

Solve the augmented radial/affine system with nonnegative diagonal smoothing; singular or affinely degenerate systems fail.

Original: [`HMath.Interpolation.fitRBF`](haskell/HMath-Interpolation.md#v:fitRBF).

```haskell
RadialKernel -> Double -> [[Double]] -> [Double] -> Either MathError RBF
```

```c
hmath_status hmath_interpolation_value_fit_rbf(hmath_context *context, const hmath_value *method, const hmath_value *smoothing, const hmath_value *nodes, const hmath_value *ys, hmath_value **out);
```

## `interpolation.evaluate_rbf`

`interpolation.evaluate_rbf(value, value2)`

Evaluate a fitted scattered model at one finite point with the original coordinate dimension.

Original: [`HMath.Interpolation.evaluateRBF`](haskell/HMath-Interpolation.md#v:evaluateRBF).

```haskell
RBF -> [Double] -> Either MathError Double
```

```c
hmath_status hmath_interpolation_value_evaluate_rbf(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `interpolation.inverse_distance`

`interpolation.inverse_distance(power, nodes, ys, point)`

Normalized inverse-distance interpolation with positive power; coincident queries return the exact observation.

Original: [`HMath.Interpolation.inverseDistance`](haskell/HMath-Interpolation.md#v:inverseDistance).

```haskell
Double -> [[Double]] -> [Double] -> [Double] -> Either MathError Double
```

```c
hmath_status hmath_interpolation_value_inverse_distance(hmath_context *context, const hmath_value *power, const hmath_value *nodes, const hmath_value *ys, const hmath_value *point, hmath_value **out);
```

## `interpolation.shepard`

`interpolation.shepard(value, value2, value3)`

Classical inverse-square Shepard interpolation in the supplied Euclidean coordinates.

Original: [`HMath.Interpolation.shepard`](haskell/HMath-Interpolation.md#v:shepard).

```haskell
[[Double]] -> [Double] -> [Double] -> Either MathError Double
```

```c
hmath_status hmath_interpolation_value_shepard(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out);
```

## `interpolation.kriging`

`interpolation.kriging(range, nugget, nodes, ys, point)`

 Ordinary kriging with stationary exponential covariance exp(-distance/range), optional independent nugget, unbiased constant mean. Returns mean and variance. 

Original: [`HMath.Interpolation.kriging`](haskell/HMath-Interpolation.md#v:kriging).

```haskell
Double -> Double -> [[Double]] -> [Double] -> [Double] -> Either MathError (Double, Double)
```

```c
hmath_status hmath_interpolation_value_kriging(hmath_context *context, const hmath_value *range, const hmath_value *nugget, const hmath_value *nodes, const hmath_value *ys, const hmath_value *point, hmath_value **out);
```

## `interpolation.polynomial_fit`

`interpolation.polynomial_fit(degree, points)`

Full-column-rank polynomial least squares via pivoted QR, returning ascending coefficients and maximum observation error.

Original: [`HMath.Interpolation.polynomialFit`](haskell/HMath-Interpolation.md#v:polynomialFit).

```haskell
Int -> [(Double, Double)] -> Either MathError Approximation
```

```c
hmath_status hmath_interpolation_value_polynomial_fit(hmath_context *context, const hmath_value *degree, const hmath_value *points, hmath_value **out);
```

## `interpolation.chebyshev_approximate`

`interpolation.chebyshev_approximate(degree, f, a, b)`

Chebyshev-root interpolation on a finite interval; report maximum error on a separate 513-point uniform validation grid.

Original: [`HMath.Interpolation.chebyshevApproximate`](haskell/HMath-Interpolation.md#v:chebyshevApproximate).

```haskell
Int -> (Double -> Double) -> Double -> Double -> Either MathError Approximation
```

```c
hmath_status hmath_interpolation_value_chebyshev_approximate(hmath_context *context, const hmath_value *degree, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `interpolation.pade`

`interpolation.pade(m, n, series)`

Padé [m/n] from ascending Taylor coefficients, q_0=1.

Original: [`HMath.Interpolation.pade`](haskell/HMath-Interpolation.md#v:pade).

```haskell
Int -> Int -> [Double] -> Either MathError ([Double], [Double])
```

```c
hmath_status hmath_interpolation_value_pade(hmath_context *context, const hmath_value *m, const hmath_value *n, const hmath_value *series, hmath_value **out);
```

## `interpolation.rational_fit`

`interpolation.rational_fit(m, n, points)`

 Linearized rational least squares y*q(x)-p(x)=0 with q_0=1; poles at observations are rejected. Error is the actual rational residual. 

Original: [`HMath.Interpolation.rationalFit`](haskell/HMath-Interpolation.md#v:rationalFit).

```haskell
Int -> Int -> [(Double, Double)] -> Either MathError ([Double], [Double], Double)
```

```c
hmath_status hmath_interpolation_value_rational_fit(hmath_context *context, const hmath_value *m, const hmath_value *n, const hmath_value *points, hmath_value **out);
```

## `interpolation.remez`

`interpolation.remez(degree, grid_count, tolerance, budget, f, a, b)`

 Discrete Remez exchange on an explicit dense grid, 1..64 degree. Success requires alternating extrema and stable equioscillation; returned error is the maximum on this grid only, not a certified continuous minimax bound. 

Original: [`HMath.Interpolation.remez`](haskell/HMath-Interpolation.md#v:remez).

```haskell
Int -> Int -> Double -> Int -> (Double -> Double) -> Double -> Double -> Either MathError Approximation
```

```c
hmath_status hmath_interpolation_value_remez(hmath_context *context, const hmath_value *degree, const hmath_value *grid_count, const hmath_value *tolerance, const hmath_value *budget, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `interpolation.nonlinear_fit`

`interpolation.nonlinear_fit(budget, tolerance, model, points, initial)`

 Damped Gauss--Newton least squares with central-difference Jacobian, strict residual/step convergence and finite total callbacks; returns fitted parameters. 

Original: [`HMath.Interpolation.nonlinearFit`](haskell/HMath-Interpolation.md#v:nonlinearFit).

```haskell
Int -> Double -> (Double -> [Double] -> Double) -> [(Double, Double)] -> [Double] -> Either MathError Approximation
```

```c
hmath_status hmath_interpolation_value_nonlinear_fit(hmath_context *context, const hmath_value *budget, const hmath_value *tolerance, const hmath_value *model, const hmath_value *points, const hmath_value *initial, hmath_value **out);
```

## `interpolation.interpolation_error`

`interpolation.interpolation_error(f, points)`

Maximum absolute discrepancy at the supplied nonempty observations; nonfinite callback results fail.

Original: [`HMath.Interpolation.interpolationError`](haskell/HMath-Interpolation.md#v:interpolationError).

```haskell
(Double -> Double) -> [(Double, Double)] -> Either MathError Double
```

```c
hmath_status hmath_interpolation_value_interpolation_error(hmath_context *context, const hmath_value *f, const hmath_value *points, hmath_value **out);
```

## `fourier.forward`

`fourier.forward()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.Forward`](haskell/HMath-Fourier.md#v:Forward).

```haskell
Direction
```

```c
hmath_status hmath_fourier_value_forward(hmath_context *context, hmath_value **out);
```

## `fourier.inverse`

`fourier.inverse()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.Inverse`](haskell/HMath-Fourier.md#v:Inverse).

```haskell
Direction
```

```c
hmath_status hmath_fourier_value_inverse(hmath_context *context, hmath_value **out);
```

## `fourier.automatic`

`fourier.automatic()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.Automatic`](haskell/HMath-Fourier.md#v:Automatic).

```haskell
FFTAlgorithm
```

```c
hmath_status hmath_fourier_value_automatic(hmath_context *context, hmath_value **out);
```

## `fourier.direct`

`fourier.direct()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.Direct`](haskell/HMath-Fourier.md#v:Direct).

```haskell
FFTAlgorithm
```

```c
hmath_status hmath_fourier_value_direct(hmath_context *context, hmath_value **out);
```

## `fourier.radix2`

`fourier.radix2()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.Radix2`](haskell/HMath-Fourier.md#v:Radix2).

```haskell
FFTAlgorithm
```

```c
hmath_status hmath_fourier_value_radix2(hmath_context *context, hmath_value **out);
```

## `fourier.radix4`

`fourier.radix4()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.Radix4`](haskell/HMath-Fourier.md#v:Radix4).

```haskell
FFTAlgorithm
```

```c
hmath_status hmath_fourier_value_radix4(hmath_context *context, hmath_value **out);
```

## `fourier.mixed_radix`

`fourier.mixed_radix()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.MixedRadix`](haskell/HMath-Fourier.md#v:MixedRadix).

```haskell
FFTAlgorithm
```

```c
hmath_status hmath_fourier_value_mixed_radix(hmath_context *context, hmath_value **out);
```

## `fourier.split_radix`

`fourier.split_radix()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.SplitRadix`](haskell/HMath-Fourier.md#v:SplitRadix).

```haskell
FFTAlgorithm
```

```c
hmath_status hmath_fourier_value_split_radix(hmath_context *context, hmath_value **out);
```

## `fourier.bluestein`

`fourier.bluestein()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.Bluestein`](haskell/HMath-Fourier.md#v:Bluestein).

```haskell
FFTAlgorithm
```

```c
hmath_status hmath_fourier_value_bluestein(hmath_context *context, hmath_value **out);
```

## `fourier.rader`

`fourier.rader()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.Rader`](haskell/HMath-Fourier.md#v:Rader).

```haskell
FFTAlgorithm
```

```c
hmath_status hmath_fourier_value_rader(hmath_context *context, hmath_value **out);
```

## `fourier.type_i`

`fourier.type_i()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.TypeI`](haskell/HMath-Fourier.md#v:TypeI).

```haskell
TransformType
```

```c
hmath_status hmath_fourier_value_type_i(hmath_context *context, hmath_value **out);
```

## `fourier.type_ii`

`fourier.type_ii()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.TypeII`](haskell/HMath-Fourier.md#v:TypeII).

```haskell
TransformType
```

```c
hmath_status hmath_fourier_value_type_ii(hmath_context *context, hmath_value **out);
```

## `fourier.type_iii`

`fourier.type_iii()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.TypeIII`](haskell/HMath-Fourier.md#v:TypeIII).

```haskell
TransformType
```

```c
hmath_status hmath_fourier_value_type_iii(hmath_context *context, hmath_value **out);
```

## `fourier.type_iv`

`fourier.type_iv()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.TypeIV`](haskell/HMath-Fourier.md#v:TypeIV).

```haskell
TransformType
```

```c
hmath_status hmath_fourier_value_type_iv(hmath_context *context, hmath_value **out);
```

## `fourier.plan_fft`

`fourier.plan_fft(direction, method, n)`

Create a reusable plan after checking length, prime or radix requirements. No input data or external buffers are retained.

Original: [`HMath.Fourier.planFFT`](haskell/HMath-Fourier.md#v:planFFT).

```haskell
Direction -> FFTAlgorithm -> Int -> Either MathError FFTPlan
```

```c
hmath_status hmath_fourier_value_plan_fft(hmath_context *context, const hmath_value *direction, const hmath_value *method, const hmath_value *n, hmath_value **out);
```

## `fourier.execute_fft`

`fourier.execute_fft(value, value2)`

Apply a plan to exactly its declared number of finite complex samples; reject nonfinite intermediate results.

Original: [`HMath.Fourier.executeFFT`](haskell/HMath-Fourier.md#v:executeFFT).

```haskell
FFTPlan -> [Complex Double] -> Either MathError [Complex Double]
```

```c
hmath_status hmath_fourier_value_execute_fft(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `fourier.fft`

`fourier.fft(xs)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.fft`](haskell/HMath-Fourier.md#v:fft).

```haskell
[Complex Double] -> Either MathError [Complex Double]
```

```c
hmath_status hmath_fourier_value_fft(hmath_context *context, const hmath_value *xs, hmath_value **out);
```

## `fourier.ifft`

`fourier.ifft(xs)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.ifft`](haskell/HMath-Fourier.md#v:ifft).

```haskell
[Complex Double] -> Either MathError [Complex Double]
```

```c
hmath_status hmath_fourier_value_ifft(hmath_context *context, const hmath_value *xs, hmath_value **out);
```

## `fourier.dft`

`fourier.dft(xs)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.dft`](haskell/HMath-Fourier.md#v:dft).

```haskell
[Complex Double] -> Either MathError [Complex Double]
```

```c
hmath_status hmath_fourier_value_dft(hmath_context *context, const hmath_value *xs, hmath_value **out);
```

## `fourier.real_fft`

`fourier.real_fft(value)`

Full complex spectrum; the real-spectrum inverse checks Hermitian symmetry.

Original: [`HMath.Fourier.realFFT`](haskell/HMath-Fourier.md#v:realFFT).

```haskell
[Double] -> Either MathError [Complex Double]
```

```c
hmath_status hmath_fourier_value_real_fft(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `fourier.inverse_real_fft`

`fourier.inverse_real_fft(tolerance, xs)`

Inverse of a full real spectrum; require conjugate symmetry within the supplied absolute tolerance.

Original: [`HMath.Fourier.inverseRealFFT`](haskell/HMath-Fourier.md#v:inverseRealFFT).

```haskell
Double -> [Complex Double] -> Either MathError [Double]
```

```c
hmath_status hmath_fourier_value_inverse_real_fft(hmath_context *context, const hmath_value *tolerance, const hmath_value *xs, hmath_value **out);
```

## `fourier.fft_batch`

`fourier.fft_batch(value, value2)`

Apply one immutable plan independently to each batch; any inconsistent row length fails.

Original: [`HMath.Fourier.fftBatch`](haskell/HMath-Fourier.md#v:fftBatch).

```haskell
FFTPlan -> [[Complex Double]] -> Either MathError [[Complex Double]]
```

```c
hmath_status hmath_fourier_value_fft_batch(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `fourier.fft_nd`

`fourier.fft_nd(direction, dims, xs)`

Transform all axes. Product budget is 65536; last axis varies fastest.

Original: [`HMath.Fourier.fftND`](haskell/HMath-Fourier.md#v:fftND).

```haskell
Direction -> [Int] -> [Complex Double] -> Either MathError [Complex Double]
```

```c
hmath_status hmath_fourier_value_fft_nd(hmath_context *context, const hmath_value *direction, const hmath_value *dims, const hmath_value *xs, hmath_value **out);
```

## `fourier.dct`

`fourier.dct(value, value2)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.dct`](haskell/HMath-Fourier.md#v:dct).

```haskell
TransformType -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_fourier_value_dct(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `fourier.idct`

`fourier.idct(value, value2)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.idct`](haskell/HMath-Fourier.md#v:idct).

```haskell
TransformType -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_fourier_value_idct(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `fourier.dst`

`fourier.dst(value, value2)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.dst`](haskell/HMath-Fourier.md#v:dst).

```haskell
TransformType -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_fourier_value_dst(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `fourier.idst`

`fourier.idst(value, value2)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.idst`](haskell/HMath-Fourier.md#v:idst).

```haskell
TransformType -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_fourier_value_idst(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `fourier.stft_frames`

`fourier.stft_frames(value)`

Read the full complex spectra in increasing frame-start order.

Original: [`HMath.Fourier.stftFrames`](haskell/HMath-Fourier.md#v:stftFrames).

```haskell
STFT -> [[Complex Double]]
```

```c
hmath_status hmath_fourier_value_stft_frames(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `fourier.stft`

`fourier.stft(window, hop, xs)`

Windowed analysis with an explicit hop in samples, padded endpoint frames, and a 1048576-coefficient storage budget.

Original: [`HMath.Fourier.stft`](haskell/HMath-Fourier.md#v:stft).

```haskell
[Double] -> Int -> [Double] -> Either MathError STFT
```

```c
hmath_status hmath_fourier_value_stft(hmath_context *context, const hmath_value *window, const hmath_value *hop, const hmath_value *xs, hmath_value **out);
```

## `fourier.istft`

`fourier.istft(value)`

Overlap-add inverse with squared-window normalization; reject every uncovered original sample.

Original: [`HMath.Fourier.istft`](haskell/HMath-Fourier.md#v:istft).

```haskell
STFT -> Either MathError [Double]
```

```c
hmath_status hmath_fourier_value_istft(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `fourier.magnitude_spectrum`

`fourier.magnitude_spectrum(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.magnitudeSpectrum`](haskell/HMath-Fourier.md#v:magnitudeSpectrum).

```haskell
[Complex Double] -> [Double]
```

```c
hmath_status hmath_fourier_value_magnitude_spectrum(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `fourier.phase_spectrum`

`fourier.phase_spectrum(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.phaseSpectrum`](haskell/HMath-Fourier.md#v:phaseSpectrum).

```haskell
[Complex Double] -> [Double]
```

```c
hmath_status hmath_fourier_value_phase_spectrum(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `fourier.power_spectrum`

`fourier.power_spectrum(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.powerSpectrum`](haskell/HMath-Fourier.md#v:powerSpectrum).

```haskell
[Complex Double] -> [Double]
```

```c
hmath_status hmath_fourier_value_power_spectrum(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `fourier.cross_spectrum`

`fourier.cross_spectrum(rate, window, x, y)`

Two-sided conjugate(X)*Y cross PSD using the same sample-rate/window-energy normalization as periodogram.

Original: [`HMath.Fourier.crossSpectrum`](haskell/HMath-Fourier.md#v:crossSpectrum).

```haskell
Double -> [Double] -> [Double] -> [Double] -> Either MathError [Complex Double]
```

```c
hmath_status hmath_fourier_value_cross_spectrum(hmath_context *context, const hmath_value *rate, const hmath_value *window, const hmath_value *x, const hmath_value *y, hmath_value **out);
```

## `fourier.spectrogram`

`fourier.spectrogram(w, h, xs)`

Squared-magnitude STFT frames, retaining the explicit padding/frame order of stft.

Original: [`HMath.Fourier.spectrogram`](haskell/HMath-Fourier.md#v:spectrogram).

```haskell
[Double] -> Int -> [Double] -> Either MathError [[Double]]
```

```c
hmath_status hmath_fourier_value_spectrogram(hmath_context *context, const hmath_value *w, const hmath_value *h, const hmath_value *xs, hmath_value **out);
```

## `fourier.analytic_signal`

`fourier.analytic_signal(xs)`

Real signal plus imaginary Hilbert transform, formed by doubling positive-frequency bins and retaining DC/Nyquist.

Original: [`HMath.Fourier.analyticSignal`](haskell/HMath-Fourier.md#v:analyticSignal).

```haskell
[Double] -> Either MathError [Complex Double]
```

```c
hmath_status hmath_fourier_value_analytic_signal(hmath_context *context, const hmath_value *xs, hmath_value **out);
```

## `fourier.chirp_z`

`fourier.chirp_z(count, a, w, xs)`

Direct bounded Z-transform along z_k=a*w^(-k); nonzero a,w required.

Original: [`HMath.Fourier.chirpZ`](haskell/HMath-Fourier.md#v:chirpZ).

```haskell
Int -> Complex Double -> Complex Double -> [Complex Double] -> Either MathError [Complex Double]
```

```c
hmath_status hmath_fourier_value_chirp_z(hmath_context *context, const hmath_value *count, const hmath_value *a, const hmath_value *w, const hmath_value *xs, hmath_value **out);
```

## `fourier.goertzel`

`fourier.goertzel(omega, xs)`

One arbitrary-frequency DFT value from a second-order real resonator; omega is radians/sample.

Original: [`HMath.Fourier.goertzel`](haskell/HMath-Fourier.md#v:goertzel).

```haskell
Double -> [Double] -> Either MathError (Complex Double)
```

```c
hmath_status hmath_fourier_value_goertzel(hmath_context *context, const hmath_value *omega, const hmath_value *xs, hmath_value **out);
```

## `fourier.fft_convolve`

`fourier.fft_convolve(a, b)`

Full zero-padded complex linear convolution; padded transform length is limited to 65536.

Original: [`HMath.Fourier.fftConvolve`](haskell/HMath-Fourier.md#v:fftConvolve).

```haskell
[Complex Double] -> [Complex Double] -> Either MathError [Complex Double]
```

```c
hmath_status hmath_fourier_value_fft_convolve(hmath_context *context, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `fourier.fft_correlate`

`fourier.fft_correlate(a, b)`

Correlation lags -(length b-1)..length a-1, conjugating b.

Original: [`HMath.Fourier.fftCorrelate`](haskell/HMath-Fourier.md#v:fftCorrelate).

```haskell
[Complex Double] -> [Complex Double] -> Either MathError [Complex Double]
```

```c
hmath_status hmath_fourier_value_fft_correlate(hmath_context *context, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `fourier.fft_shift`

`fourier.fft_shift(xs)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.fftShift`](haskell/HMath-Fourier.md#v:fftShift).

```haskell
[a] -> [a]
```

```c
hmath_status hmath_fourier_value_fft_shift(hmath_context *context, const hmath_value *xs, hmath_value **out);
```

## `fourier.ifft_shift`

`fourier.ifft_shift(xs)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.Fourier.ifftShift`](haskell/HMath-Fourier.md#v:ifftShift).

```haskell
[a] -> [a]
```

```c
hmath_status hmath_fourier_value_ifft_shift(hmath_context *context, const hmath_value *xs, hmath_value **out);
```

## `fourier.fft_in_place`

`fourier.fft_in_place(plan, buffer)` mutates a writable, one-dimensional, native-endian, C-contiguous NumPy `complex128` array using the original `fftInPlace`. The wrapper borrows its storage; the original routine stages and validates input before writing the result. Keep the buffer alive and exclude concurrent access during the call. Invalid lengths and nonfinite input follow the original MathError contract; storage is unchanged on failure. C takes a borrowed `double *` with interleaved real/imaginary components and a signed `ptrdiff_t` complex-element count.

```c
hmath_status hmath_fourier_value_fft_in_place(hmath_context *context, const hmath_value *plan, double *interleaved, ptrdiff_t count);
```

## `describe`

`signal.describe(value)`, `fourier.describe(value)` and `interpolation.describe(value)` return the original Haskell Show representation of a domain object. C uses `hmath_spectral_describe(context, value, out)` and receives an owned String value.
