# Image bindings

`from hmath import image` exposes the original ND CPU image algorithms. Storage is spatial row-major with interleaved channels. Intensities have no implicit range; color/histogram functions retain their source restrictions. Haskell algorithms, limits, normalization and errors are unchanged.

C includes `hmath_image.h` and uses [owned structured values](values.md). Inputs are borrowed, outputs transfer one owner and stay untouched on failure. Immutable values support independent readers with their own references. All real values are Double; Python uses floats, lists and tuples matching each signature. Original MathError constructors/payloads remain available. Callbacks are synchronous and deterministic; Python exceptions rethrow after native cleanup. The Image result is fully evaluated before callbacks are released.

Images retain the source rank1..8, channels1..16 and262144-sample limits. Filtering/interpolation retain per-algorithm budgets. No intensity clipping, dtype promotion, coordinate normalization or substituted boundary policy is added. The TensorDouble bridge retains the actual `HMath.Tensor.Tensor Double`; helpers construct it and expose shape/logical values without claiming the remaining Tensor operations.

## `image`

`image.image(shape, channels, values)`

Validate all dimensions before allocating boxed immutable array storage.

```haskell
[Int] -> Int -> [Double] -> Either MathError Image
```

```c
hmath_status hmath_image_image(hmath_context *context, const hmath_value *shape, const hmath_value *channels, const hmath_value *values, hmath_value **out);
```

## `from_tensor`

`image.from_tensor(tensor)`

Tensor shape must be spatial dimensions followed by a channel axis.

```haskell
Tensor Double -> Either MathError Image
```

```c
hmath_status hmath_image_from_tensor(hmath_context *context, const hmath_value *tensor, hmath_value **out);
```

## `to_tensor`

`image.to_tensor(image)`

 Copy an image to Tensor Double with shape spatial dimensions followed by channel count. Values remain row-major with interleaved channels; checked tensor size errors propagate. 

```haskell
Image -> Either MathError Tensor Double
```

```c
hmath_status hmath_image_to_tensor(hmath_context *context, const hmath_value *image, hmath_value **out);
```

## `image_shape`

`image.image_shape(image)`

Return spatial dimensions only, excluding the last implicit channel axis.

```haskell
Image -> [Int]
```

```c
hmath_status hmath_image_image_shape(hmath_context *context, const hmath_value *image, hmath_value **out);
```

## `image_channels`

`image.image_channels(image)`

Return channel count, between one and sixteen for validated images.

```haskell
Image -> Int
```

```c
hmath_status hmath_image_image_channels(hmath_context *context, const hmath_value *image, hmath_value **out);
```

## `image_values`

`image.image_values(image)`

Return flat row-major samples with channels interleaved at each spatial coordinate.

```haskell
Image -> [Double]
```

```c
hmath_status hmath_image_image_values(hmath_context *context, const hmath_value *image, hmath_value **out);
```

## `pixel`

`image.pixel(image, coordinates)`

 Given image then complete spatial coordinates, return all channel values in order. Invalid coordinate rank/range returns Left InvalidArgument. 

```haskell
Image -> [Int] -> Either MathError [Double]
```

```c
hmath_status hmath_image_pixel(hmath_context *context, const hmath_value *image, const hmath_value *coordinates, hmath_value **out);
```

## `channel`

`image.channel(index, image)`

 Given zero-based channel index then image, return a copied one-channel image of the same spatial shape. Invalid channel index fails. 

```haskell
Int -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_channel(hmath_context *context, const hmath_value *index, const hmath_value *image, hmath_value **out);
```

## `combine_channels`

`image.combine_channels(images)`

 Concatenate channels of a nonempty same-spatial-shape image list in input order. Require total channels<=16; shape/count or checked storage limits fail. 

```haskell
[Image] -> Either MathError Image
```

```c
hmath_status hmath_image_combine_channels(hmath_context *context, const hmath_value *images, hmath_value **out);
```

## `map_image`

`image.map_image(function, image)`

Output is validated, including arithmetic overflow inside the callback.

```haskell
(Double -> Double) -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_map_image(hmath_context *context, hmath_image_callback function, void *userdata, const hmath_value *image, hmath_value **out);
```

## `zip_image`

`image.zip_image(function, a, b)`

 Given binary sample function then equally shaped/channel-count images, return a new validated image. Mismatched shape/channels or non-finite output returns Left MathError. 

```haskell
(Double -> Double -> Double) -> Image -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_zip_image(hmath_context *context, hmath_image_callback function, void *userdata, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `normalize`

`image.normalize(low, high, image)`

Global min/max scaling; a constant image maps to the requested lower bound.

```haskell
Double -> Double -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_normalize(hmath_context *context, const hmath_value *low, const hmath_value *high, const hmath_value *image, hmath_value **out);
```

## `brightness`

`image.brightness(offset, image)`

Add a finite offset without implicit clipping.

```haskell
Double -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_brightness(hmath_context *context, const hmath_value *offset, const hmath_value *image, hmath_value **out);
```

## `contrast`

`image.contrast(factor, pivot, image)`

Scale about a caller-defined pivot, without clipping.

```haskell
Double -> Double -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_contrast(hmath_context *context, const hmath_value *factor, const hmath_value *pivot, const hmath_value *image, hmath_value **out);
```

## `gamma`

`image.gamma(power, image)`

Positive gamma, nonnegative inputs; computes x^gamma without clipping.

```haskell
Double -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_gamma(hmath_context *context, const hmath_value *power, const hmath_value *image, hmath_value **out);
```

## `constant`

`image.constant(fill)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Double -> Boundary
```

```c
hmath_status hmath_image_constant(hmath_context *context, const hmath_value *fill, hmath_value **out);
```

## `clamp`

`image.clamp()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Boundary
```

```c
hmath_status hmath_image_clamp(hmath_context *context, hmath_value **out);
```

## `reflect`

`image.reflect()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Boundary
```

```c
hmath_status hmath_image_reflect(hmath_context *context, hmath_value **out);
```

## `wrap`

`image.wrap()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Boundary
```

```c
hmath_status hmath_image_wrap(hmath_context *context, hmath_value **out);
```

## `convolve`

`image.convolve(boundary, shape, weights, image)`

 Given boundary,kernel dimensions,flat weights,then image, reverse all kernel axes and correlate. Channels are filtered independently; require odd extents<=65, matching rank/count, <=4096 weights and <=20000000 sample operations. Invalid/non-finite input/result fails. 

```haskell
Boundary -> [Int] -> [Double] -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_convolve(hmath_context *context, const hmath_value *boundary, const hmath_value *shape, const hmath_value *weights, const hmath_value *image, hmath_value **out);
```

## `correlate`

`image.correlate(boundary, shape, weights, image)`

 Correlation uses sample(ix+kernelOffset-center). Convolution reverses all kernel axes; channels are filtered independently without channel mixing. 

```haskell
Boundary -> [Int] -> [Double] -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_correlate(hmath_context *context, const hmath_value *boundary, const hmath_value *shape, const hmath_value *weights, const hmath_value *image, hmath_value **out);
```

## `gaussian_blur`

`image.gaussian_blur(boundary, sigma, radius, image)`

Separable Gaussian, truncated at an explicitly supplied integer radius.

```haskell
Boundary -> Double -> Int -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_gaussian_blur(hmath_context *context, const hmath_value *boundary, const hmath_value *sigma, const hmath_value *radius, const hmath_value *image, hmath_value **out);
```

## `box_blur`

`image.box_blur(boundary, radius, image)`

 Given boundary,radius,then image, average a centered full-dimensional box neighborhood independently per channel. Neighborhood/work bounds and boundary finiteness are checked; invalid/non-finite output fails. 

```haskell
Boundary -> Int -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_box_blur(hmath_context *context, const hmath_value *boundary, const hmath_value *radius, const hmath_value *image, hmath_value **out);
```

## `median_blur`

`image.median_blur(boundary, radius, image)`

 Given boundary,radius,then image, choose the median of each centered odd-sized neighborhood independently per channel. Invalid boundary/neighborhood/work bounds fail. 

```haskell
Boundary -> Int -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_median_blur(hmath_context *context, const hmath_value *boundary, const hmath_value *radius, const hmath_value *image, hmath_value **out);
```

## `bilateral_blur`

`image.bilateral_blur(boundary, sigma_space, sigma_range, radius, image)`

 Per-channel bilateral filtering: spatial and range Gaussian weights are multiplied, normalized locally, and computed relative to the center sample. 

```haskell
Boundary -> Double -> Double -> Int -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_bilateral_blur(hmath_context *context, const hmath_value *boundary, const hmath_value *sigma_space, const hmath_value *sigma_range, const hmath_value *radius, const hmath_value *image, hmath_value **out);
```

## `sharpen`

`image.sharpen(boundary, amount, sigma, radius, image)`

Unsharp mask x+amount*(x-Gaussian(x)); no implicit range clipping.

```haskell
Boundary -> Double -> Double -> Int -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_sharpen(hmath_context *context, const hmath_value *boundary, const hmath_value *amount, const hmath_value *sigma, const hmath_value *radius, const hmath_value *image, hmath_value **out);
```

## `gradient`

`image.gradient(method, boundary, image)`

 Returns row derivative, column derivative, magnitude, and atan2(row,col) direction in radians. Smoothing/derivative kernels are normalized so an interior unit ramp has derivative one. 

```haskell
GradientOperator -> Boundary -> Image -> Either MathError (Image, Image, Image, Image)
```

```c
hmath_status hmath_image_gradient(hmath_context *context, const hmath_value *method, const hmath_value *boundary, const hmath_value *image, hmath_value **out);
```

## `laplacian`

`image.laplacian(boundary, image)`

 Given boundary then one-channel 2D image, apply the four-neighbor 3-by-3 Laplacian [0,1,0;1,-4,1;0,1,0]. Invalid image/boundary or non-finite output fails. 

```haskell
Boundary -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_laplacian(hmath_context *context, const hmath_value *boundary, const hmath_value *image, hmath_value **out);
```

## `canny`

`image.canny(boundary, sigma, radius, low, high, image)`

 Canny: Gaussian smoothing, Sobel gradient, four-direction nonmaximum suppression, and 8-connected hysteresis. low/high are absolute normalized gradient magnitudes, not quantiles. Output is exactly zero or one. 

```haskell
Boundary -> Double -> Int -> Double -> Double -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_canny(hmath_context *context, const hmath_value *boundary, const hmath_value *sigma, const hmath_value *radius, const hmath_value *low, const hmath_value *high, const hmath_value *image, hmath_value **out);
```

## `morphology`

`image.morphology(operation, boundary, shape, mask, image)`

 Flat grayscale morphology with an explicit odd-rank Boolean footprint. Erosion samples x+offset; dilation samples x-offset (reflected footprint), so asymmetric footprints obey the usual adjunction. Opening/closing compose these operators under the same caller-selected boundary extension. 

```haskell
Morphology -> Boundary -> [Int] -> [Bool] -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_morphology(hmath_context *context, const hmath_value *operation, const hmath_value *boundary, const hmath_value *shape, const hmath_value *mask, const hmath_value *image, hmath_value **out);
```

## `morphological_gradient`

`image.morphological_gradient(boundary, shape, mask, image)`

 Given boundary,footprint dimensions,Bool footprint,then image, return dilation minus erosion. Shape/footprint/work/boundary validation and finite output checks propagate from morphology. 

```haskell
Boundary -> [Int] -> [Bool] -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_morphological_gradient(hmath_context *context, const hmath_value *boundary, const hmath_value *shape, const hmath_value *mask, const hmath_value *image, hmath_value **out);
```

## `validate_boundary`

`image.validate_boundary(boundary)`

 Validate Constant boundary value as finite; Clamp,Reflect,Wrap are always valid. Non-finite constant returns Left InvalidArgument. 

```haskell
Boundary -> Either MathError ()
```

```c
hmath_status hmath_image_validate_boundary(hmath_context *context, const hmath_value *boundary, hmath_value **out);
```

## `scalar2_d`

`image.scalar2_d(image)`

 Require a two-dimensional one-channel image and return (height,width). Other spatial/channel layouts return Left InvalidArgument. 

```haskell
Image -> Either MathError (Int, Int)
```

```c
hmath_status hmath_image_scalar2_d(hmath_context *context, const hmath_value *image, hmath_value **out);
```

## `window_offsets`

`image.window_offsets(radius, image)`

 Given radius then image, enumerate centered neighborhood offsets. Require radius in [0,16], <=4096 neighbors and <=20000000 sample operations; otherwise fail. 

```haskell
Int -> Image -> Either MathError [[Int]]
```

```c
hmath_status hmath_image_window_offsets(hmath_context *context, const hmath_value *radius, const hmath_value *image, hmath_value **out);
```

## `sobel`

`image.sobel()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
GradientOperator
```

```c
hmath_status hmath_image_sobel(hmath_context *context, hmath_value **out);
```

## `prewitt`

`image.prewitt()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
GradientOperator
```

```c
hmath_status hmath_image_prewitt(hmath_context *context, hmath_value **out);
```

## `scharr`

`image.scharr()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
GradientOperator
```

```c
hmath_status hmath_image_scharr(hmath_context *context, hmath_value **out);
```

## `erosion`

`image.erosion()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Morphology
```

```c
hmath_status hmath_image_erosion(hmath_context *context, hmath_value **out);
```

## `dilation`

`image.dilation()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Morphology
```

```c
hmath_status hmath_image_dilation(hmath_context *context, hmath_value **out);
```

## `opening`

`image.opening()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Morphology
```

```c
hmath_status hmath_image_opening(hmath_context *context, hmath_value **out);
```

## `closing`

`image.closing()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Morphology
```

```c
hmath_status hmath_image_closing(hmath_context *context, hmath_value **out);
```

## `histogram`

`image.histogram(bins, image)`

 Given bin count in [2,4096] then image with every sample in [0,1], return one Int count list per channel. Values at 1 enter the final bin. Invalid count/range fails. 

```haskell
Int -> Image -> Either MathError [[Int]]
```

```c
hmath_status hmath_image_histogram(hmath_context *context, const hmath_value *bins, const hmath_value *image, hmath_value **out);
```

## `equalize_histogram`

`image.equalize_histogram(bins, image)`

 CDF-min equalization with quantized bin mapping. A single occupied bin is left unchanged, avoiding an arbitrary jump on constant images. 

```haskell
Int -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_equalize_histogram(hmath_context *context, const hmath_value *bins, const hmath_value *image, hmath_value **out);
```

## `clahe`

`image.clahe(bins, tiles, clip_limit, image)`

 2D adaptive equalization. clipFactor>=1 is relative to uniform tile occupancy; the cap is max(ceil(tileSamples/bins),floor(factor*tileSamples/bins)). Tiles at image ends may be smaller. Intensities are quantized without channel coupling. At most 4,096 tiles and 1,048,576 stored histogram bins. 

```haskell
Int -> (Int, Int) -> Double -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_clahe(hmath_context *context, const hmath_value *bins, const hmath_value *tiles, const hmath_value *clip_limit, const hmath_value *image, hmath_value **out);
```

## `threshold`

`image.threshold(level, image)`

Strict comparison x>level; each channel is thresholded independently.

```haskell
Double -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_threshold(hmath_context *context, const hmath_value *level, const hmath_value *image, hmath_value **out);
```

## `otsu`

`image.otsu(bins, image)`

 Otsu between-class variance maximum. Lowest threshold wins ties. Returns one bin-edge threshold per channel; a constant channel returns its value. 

```haskell
Int -> Image -> Either MathError ([Double], Image)
```

```c
hmath_status hmath_image_otsu(hmath_context *context, const hmath_value *bins, const hmath_value *image, hmath_value **out);
```

## `adaptive_threshold`

`image.adaptive_threshold(gaussian, boundary, radius, offset, image)`

 Local mean or Gaussian threshold: x > localMean-offset. Gaussian uses sigma=max(0.5,radius/2); boundary extension is explicit. 

```haskell
Bool -> Boundary -> Int -> Double -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_adaptive_threshold(hmath_context *context, const hmath_value *gaussian, const hmath_value *boundary, const hmath_value *radius, const hmath_value *offset, const hmath_value *image, hmath_value **out);
```

## `template_match`

`image.template_match(metric, needle, haystack)`

 Valid 2D, one-channel matching. Each output is one template origin. NCC centers both patches and divides by their energies; constant templates or candidate patches have undefined correlation and return MathError. 

```haskell
TemplateMetric -> Image -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_template_match(hmath_context *context, const hmath_value *metric, const hmath_value *needle, const hmath_value *haystack, hmath_value **out);
```

## `raw_moment`

`image.raw_moment(row_order, column_order, image)`

Raw M_pq=sum(row^p*column^q*intensity), orders 0..8 each.

```haskell
Int -> Int -> Image -> Either MathError Double
```

```c
hmath_status hmath_image_raw_moment(hmath_context *context, const hmath_value *row_order, const hmath_value *column_order, const hmath_value *image, hmath_value **out);
```

## `central_moment`

`image.central_moment(row_order, column_order, image)`

 Given row exponent p,column exponent q,then scalar 2D image, compute the unnormalized intensity-weighted central moment around its centroid. Require orders in [0,8]; invalid image/zero mass or non-finite result fails. 

```haskell
Int -> Int -> Image -> Either MathError Double
```

```c
hmath_status hmath_image_central_moment(hmath_context *context, const hmath_value *row_order, const hmath_value *column_order, const hmath_value *image, hmath_value **out);
```

## `image_centroid`

`image.image_centroid(image)`

 Intensity-weighted (row,column) centroid. Signed intensities are allowed; a zero total mass is undefined and reported explicitly. 

```haskell
Image -> Either MathError (Double, Double)
```

```c
hmath_status hmath_image_image_centroid(hmath_context *context, const hmath_value *image, hmath_value **out);
```

## `integral_image`

`image.integral_image(image)`

 Padded 2D summed-area image, per channel: output shape (height+1,width+1) has a leading zero row/column. Rectangle queries use half-open bounds. 

```haskell
Image -> Either MathError Image
```

```c
hmath_status hmath_image_integral_image(hmath_context *context, const hmath_value *image, hmath_value **out);
```

## `rectangle_sum`

`image.rectangle_sum(origin, extent, image)`

 Given (row,column) origin,(height,width) extent,then padded integralImage output, return per-channel sum of the half-open rectangle. Reject invalid/out-of-range bounds; zero extents are allowed. 

```haskell
(Int, Int) -> (Int, Int) -> Image -> Either MathError [Double]
```

```c
hmath_status hmath_image_rectangle_sum(hmath_context *context, const hmath_value *origin, const hmath_value *extent, const hmath_value *image, hmath_value **out);
```

## `mean_squared_error`

`image.mean_squared_error(a, b)`

 Given two images of equal spatial shape and channels, return average squared sample difference. Shape mismatch or non-finite arithmetic returns Left MathError. 

```haskell
Image -> Image -> Either MathError Double
```

```c
hmath_status hmath_image_mean_squared_error(hmath_context *context, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `peak_signal_to_noise`

`image.peak_signal_to_noise(data_range, a, b)`

 PSNR in decibels. Exactly identical images return positive infinity by definition; this is the sole intentional nonfinite measurement result. 

```haskell
Double -> Image -> Image -> Either MathError Double
```

```c
hmath_status hmath_image_peak_signal_to_noise(hmath_context *context, const hmath_value *data_range, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `structural_similarity`

`image.structural_similarity(data_range, window, a, b)`

 Mean local SSIM with uniform valid windows and population covariance. C1=(0.01*range)^2, C2=(0.03*range)^2; all channels are measured separately. Windows do not include padding and both spatial extents must fit the window. Wang et al., Image Quality Assessment: From Error Visibility to Structural Similarity (2004), https://ece.uwaterloo.ca/~z70wang/publications/ssim.html . 

```haskell
Double -> Int -> Image -> Image -> Either MathError Double
```

```c
hmath_status hmath_image_structural_similarity(hmath_context *context, const hmath_value *data_range, const hmath_value *window, const hmath_value *a, const hmath_value *b, hmath_value **out);
```

## `squared_difference`

`image.squared_difference()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
TemplateMetric
```

```c
hmath_status hmath_image_squared_difference(hmath_context *context, hmath_value **out);
```

## `normalized_correlation`

`image.normalized_correlation()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
TemplateMetric
```

```c
hmath_status hmath_image_normalized_correlation(hmath_context *context, hmath_value **out);
```

## `resize`

`image.resize(interpolation, boundary, shape, image)`

 2D resize uses pixel-center mapping (i+0.5)*old/new-0.5, independently per channel, without antialiasing. Bicubic is Keys a=-0.5; Lanczos has radius three. Downsampling callers can explicitly prefilter first. 

```haskell
Interpolation -> Boundary -> (Int, Int) -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_resize(hmath_context *context, const hmath_value *interpolation, const hmath_value *boundary, const hmath_value *shape, const hmath_value *image, hmath_value **out);
```

## `warp`

`image.warp(interpolation, boundary, shape, matrix, image)`

 Forward 3x3 homogeneous transform acts on [x(column),y(row),1]. The matrix is inverted once for output-to-input sampling. Points at projective infinity or with magnitude over 1e9 are errors, even with constant padding. 

```haskell
Interpolation -> Boundary -> (Int, Int) -> [[Double]] -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_warp(hmath_context *context, const hmath_value *interpolation, const hmath_value *boundary, const hmath_value *shape, const hmath_value *matrix, const hmath_value *image, hmath_value **out);
```

## `translate`

`image.translate(interpolation, boundary, row_shift, column_shift, image)`

Translation in pixel columns/rows; output dimensions equal input.

```haskell
Interpolation -> Boundary -> Double -> Double -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_translate(hmath_context *context, const hmath_value *interpolation, const hmath_value *boundary, const hmath_value *row_shift, const hmath_value *column_shift, const hmath_value *image, hmath_value **out);
```

## `rotate`

`image.rotate(interpolation, boundary, angle, image)`

 Angle in radians, clockwise on row-down image coordinates; rotate about the center pixel coordinate while preserving the input canvas dimensions. 

```haskell
Interpolation -> Boundary -> Double -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_rotate(hmath_context *context, const hmath_value *interpolation, const hmath_value *boundary, const hmath_value *angle, const hmath_value *image, hmath_value **out);
```

## `connected_components`

`image.connected_components(connectivity, image)`

 Nonzero is foreground. Label zero is background; component labels start at one in first-pixel row-major order. Returns labels as exact Doubles and component sizes in that same order. Connectivity has no wraparound. 

```haskell
Connectivity -> Image -> Either MathError (Image, [Int])
```

```c
hmath_status hmath_image_connected_components(hmath_context *context, const hmath_value *connectivity, const hmath_value *image, hmath_value **out);
```

## `distance_transform`

`image.distance_transform(spacing, image)`

 Exact brute-force Euclidean distance to the nearest zero-valued spatial sample, with strictly positive per-axis spacing. No implicit outside zeros; an all-foreground image has no finite answer and returns DomainError. 

```haskell
[Double] -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_distance_transform(hmath_context *context, const hmath_value *spacing, const hmath_value *image, hmath_value **out);
```

## `nearest`

`image.nearest()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Interpolation
```

```c
hmath_status hmath_image_nearest(hmath_context *context, hmath_value **out);
```

## `bilinear`

`image.bilinear()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Interpolation
```

```c
hmath_status hmath_image_bilinear(hmath_context *context, hmath_value **out);
```

## `bicubic`

`image.bicubic()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Interpolation
```

```c
hmath_status hmath_image_bicubic(hmath_context *context, hmath_value **out);
```

## `lanczos`

`image.lanczos()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Interpolation
```

```c
hmath_status hmath_image_lanczos(hmath_context *context, hmath_value **out);
```

## `axis_connected`

`image.axis_connected()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Connectivity
```

```c
hmath_status hmath_image_axis_connected(hmath_context *context, hmath_value **out);
```

## `fully_connected`

`image.fully_connected()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Connectivity
```

```c
hmath_status hmath_image_fully_connected(hmath_context *context, hmath_value **out);
```

## `convert_color`

`image.convert_color(source, destination, image)`

Explicit source/destination spaces; three interleaved channels required.

```haskell
ColorSpace -> ColorSpace -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_convert_color(hmath_context *context, const hmath_value *source, const hmath_value *destination, const hmath_value *image, hmath_value **out);
```

## `grayscale`

`image.grayscale(source, image)`

Rec.709 luminance, explicitly converting the stated source to linear RGB.

```haskell
ColorSpace -> Image -> Either MathError Image
```

```c
hmath_status hmath_image_grayscale(hmath_context *context, const hmath_value *source, const hmath_value *image, hmath_value **out);
```

## `srgb`

`image.srgb()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ColorSpace
```

```c
hmath_status hmath_image_srgb(hmath_context *context, hmath_value **out);
```

## `linear_rgb`

`image.linear_rgb()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ColorSpace
```

```c
hmath_status hmath_image_linear_rgb(hmath_context *context, hmath_value **out);
```

## `hsv`

`image.hsv()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ColorSpace
```

```c
hmath_status hmath_image_hsv(hmath_context *context, hmath_value **out);
```

## `hsl`

`image.hsl()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ColorSpace
```

```c
hmath_status hmath_image_hsl(hmath_context *context, hmath_value **out);
```

## `xyz`

`image.xyz()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ColorSpace
```

```c
hmath_status hmath_image_xyz(hmath_context *context, hmath_value **out);
```

## `lab`

`image.lab()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ColorSpace
```

```c
hmath_status hmath_image_lab(hmath_context *context, hmath_value **out);
```

## `y_cb_cr`

`image.y_cb_cr()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ColorSpace
```

```c
hmath_status hmath_image_y_cb_cr(hmath_context *context, hmath_value **out);
```

## `tensor`

`image.tensor(shape, values)`

 Given shape then flat row-major values, construct an immutable CPU tensor. Require exactly the shape product values; invalid dimensions/count return Left MathError. Generic values are not validated for finiteness. 

```haskell
[Int] -> [Double] -> Either MathError Tensor Double
```

```c
hmath_status hmath_image_tensor(hmath_context *context, const hmath_value *shape, const hmath_value *values, hmath_value **out);
```

## `tensor_shape`

`image.tensor_shape(tensor)`

Return dimensions in axis order. Scalar shape is []; empty axes are retained.

```haskell
Tensor Double -> [Int]
```

```c
hmath_status hmath_image_tensor_shape(hmath_context *context, const hmath_value *tensor, hmath_value **out);
```

## `tensor_values`

`image.tensor_values(tensor)`

 Return logical values in row-major coordinate order, honoring strides/offsets rather than exposing raw backing storage. 

```haskell
Tensor Double -> [Double]
```

```c
hmath_status hmath_image_tensor_values(hmath_context *context, const hmath_value *tensor, hmath_value **out);
```

