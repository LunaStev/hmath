# Time-series bindings

C includes `hmath_timeseries.h`; Python uses `from hmath import timeseries`. These functions call the original Haskell time-series implementation. Timestamps retain caller-defined units, ordering and explicit missing values; no calendar interpretation or automatic data cleaning is added. The source observation, work and fitting limits remain in force.

All inputs are borrowed during a synchronous call; every successful C output owns one [structured value](values.md) reference. Outputs are unchanged on error. Checked `Left MathError` returns status11 with the original structured error. Immutable objects support concurrent readers with independent references and output addresses. Python owners have `close()` and context managers. `Maybe Double` observations use `None` for missingness. Forecast models and configuration constructors retain the original argument order and defaults. `OptimizeOptions` comes from `hmath.optimization`.

ARMA/SARIMA use the original local conditional sum-of-squares fit, not a substituted exact likelihood model. Stationarity and interval estimates are not inferred by forecasting calls. Refer to the linked source contract for each model and diagnostic.

## `describe`

`timeseries.describe(value)` returns the original Haskell `Show` representation of one time-series object or Gaussian state. It preserves the original constructor and fields as text, including Unicode and embedded NUL. C receives an owned String value through `hmath_timeseries_describe(context, value, out)`. Mathematical operations use the typed object directly.

## `backward_fill`

`timeseries.backward_fill()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Core.BackwardFill`](haskell/HMath-TimeSeries-Core.md#v:BackwardFill).

```haskell
Fill
```

```c
hmath_status hmath_timeseries_backward_fill(hmath_context *context, hmath_value **out);
```

## `bin_last`

`timeseries.bin_last()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Core.BinLast`](haskell/HMath-TimeSeries-Core.md#v:BinLast).

```haskell
Resampling
```

```c
hmath_status hmath_timeseries_bin_last(hmath_context *context, hmath_value **out);
```

## `bin_mean`

`timeseries.bin_mean()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Core.BinMean`](haskell/HMath-TimeSeries-Core.md#v:BinMean).

```haskell
Resampling
```

```c
hmath_status hmath_timeseries_bin_mean(hmath_context *context, hmath_value **out);
```

## `forward_fill`

`timeseries.forward_fill()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Core.ForwardFill`](haskell/HMath-TimeSeries-Core.md#v:ForwardFill).

```haskell
Fill
```

```c
hmath_status hmath_timeseries_forward_fill(hmath_context *context, hmath_value **out);
```

## `inner`

`timeseries.inner()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Core.Inner`](haskell/HMath-TimeSeries-Core.md#v:Inner).

```haskell
Alignment
```

```c
hmath_status hmath_timeseries_inner(hmath_context *context, hmath_value **out);
```

## `left_aligned`

`timeseries.left_aligned()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Core.LeftAligned`](haskell/HMath-TimeSeries-Core.md#v:LeftAligned).

```haskell
Alignment
```

```c
hmath_status hmath_timeseries_left_aligned(hmath_context *context, hmath_value **out);
```

## `linear_fill`

`timeseries.linear_fill()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Core.LinearFill`](haskell/HMath-TimeSeries-Core.md#v:LinearFill).

```haskell
Fill
```

```c
hmath_status hmath_timeseries_linear_fill(hmath_context *context, hmath_value **out);
```

## `linear_samples`

`timeseries.linear_samples()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Core.LinearSamples`](haskell/HMath-TimeSeries-Core.md#v:LinearSamples).

```haskell
Resampling
```

```c
hmath_status hmath_timeseries_linear_samples(hmath_context *context, hmath_value **out);
```

## `moving_maximum`

`timeseries.moving_maximum()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Core.MovingMaximum`](haskell/HMath-TimeSeries-Core.md#v:MovingMaximum).

```haskell
Rolling
```

```c
hmath_status hmath_timeseries_moving_maximum(hmath_context *context, hmath_value **out);
```

## `moving_mean`

`timeseries.moving_mean()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Core.MovingMean`](haskell/HMath-TimeSeries-Core.md#v:MovingMean).

```haskell
Rolling
```

```c
hmath_status hmath_timeseries_moving_mean(hmath_context *context, hmath_value **out);
```

## `moving_minimum`

`timeseries.moving_minimum()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Core.MovingMinimum`](haskell/HMath-TimeSeries-Core.md#v:MovingMinimum).

```haskell
Rolling
```

```c
hmath_status hmath_timeseries_moving_minimum(hmath_context *context, hmath_value **out);
```

## `moving_sd`

`timeseries.moving_sd()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Core.MovingSD`](haskell/HMath-TimeSeries-Core.md#v:MovingSD).

```haskell
Rolling
```

```c
hmath_status hmath_timeseries_moving_sd(hmath_context *context, hmath_value **out);
```

## `moving_variance`

`timeseries.moving_variance()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Core.MovingVariance`](haskell/HMath-TimeSeries-Core.md#v:MovingVariance).

```haskell
Rolling
```

```c
hmath_status hmath_timeseries_moving_variance(hmath_context *context, hmath_value **out);
```

## `outer`

`timeseries.outer()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Core.Outer`](haskell/HMath-TimeSeries-Core.md#v:Outer).

```haskell
Alignment
```

```c
hmath_status hmath_timeseries_outer(hmath_context *context, hmath_value **out);
```

## `align`

`timeseries.align(value, value2, value3)`

Exact timestamp equality. Missing alignment positions are explicit Nothing.

Original: [`HMath.TimeSeries.Core.align`](haskell/HMath-TimeSeries-Core.md#v:align).

```haskell
Alignment -> Series -> Series -> Either MathError (Series, Series)
```

```c
hmath_status hmath_timeseries_align(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out);
```

## `autocorrelation`

`timeseries.autocorrelation(lags, xs)`

Biased covariance divided by lag-zero covariance, global sample mean.

Original: [`HMath.TimeSeries.Core.autocorrelation`](haskell/HMath-TimeSeries-Core.md#v:autocorrelation).

```haskell
Int -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_timeseries_autocorrelation(hmath_context *context, const hmath_value *lags, const hmath_value *xs, hmath_value **out);
```

## `cross_correlation`

`timeseries.cross_correlation(lag, xs, ys)`

Corr(x_t,y_(t+lag)), global means and full lag-zero energy normalization.

Original: [`HMath.TimeSeries.Core.crossCorrelation`](haskell/HMath-TimeSeries-Core.md#v:crossCorrelation).

```haskell
Int -> [Double] -> [Double] -> Either MathError Double
```

```c
hmath_status hmath_timeseries_cross_correlation(hmath_context *context, const hmath_value *lag, const hmath_value *xs, const hmath_value *ys, hmath_value **out);
```

## `cumulative_returns`

`timeseries.cumulative_returns(xs)`

Cumulative simple return relative to the first strictly positive price.

Original: [`HMath.TimeSeries.Core.cumulativeReturns`](haskell/HMath-TimeSeries-Core.md#v:cumulativeReturns).

```haskell
[Double] -> Either MathError [Double]
```

```c
hmath_status hmath_timeseries_cumulative_returns(hmath_context *context, const hmath_value *xs, hmath_value **out);
```

## `difference`

`timeseries.difference(order, lag, xs)`

Apply (1-B^lag)^order. Zero order preserves data; at least one output is required.

Original: [`HMath.TimeSeries.Core.difference`](haskell/HMath-TimeSeries-Core.md#v:difference).

```haskell
Int -> Int -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_timeseries_difference(hmath_context *context, const hmath_value *order, const hmath_value *lag, const hmath_value *xs, hmath_value **out);
```

## `durbin_levinson`

`timeseries.durbin_levinson(covariance)`

 Levinson recursion for a positive definite Toeplitz covariance. Returns AR coefficients, innovation variance, and PACF (without the lag-zero one). 

Original: [`HMath.TimeSeries.Core.durbinLevinson`](haskell/HMath-TimeSeries-Core.md#v:durbinLevinson).

```haskell
[Double] -> Either MathError ([Double], Double, [Double])
```

```c
hmath_status hmath_timeseries_durbin_levinson(hmath_context *context, const hmath_value *covariance, hmath_value **out);
```

## `exponential_average`

`timeseries.exponential_average(alpha, xs)`

Recursive EMA, initialized at the first observation; 0<alpha<=1.

Original: [`HMath.TimeSeries.Core.exponentialAverage`](haskell/HMath-TimeSeries-Core.md#v:exponentialAverage).

```haskell
Double -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_timeseries_exponential_average(hmath_context *context, const hmath_value *alpha, const hmath_value *xs, hmath_value **out);
```

## `fill_missing`

`timeseries.fill_missing(value, value2)`

 Directional filling leaves the unavailable leading/trailing end missing. Linear filling interpolates between finite anchors and never extrapolates. 

Original: [`HMath.TimeSeries.Core.fillMissing`](haskell/HMath-TimeSeries-Core.md#v:fillMissing).

```haskell
Fill -> Series -> Either MathError Series
```

```c
hmath_status hmath_timeseries_fill_missing(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `is_regular`

`timeseries.is_regular(value, value2)`

Relative spacing tolerance; fewer than three observations are regular.

Original: [`HMath.TimeSeries.Core.isRegular`](haskell/HMath-TimeSeries-Core.md#v:isRegular).

```haskell
Double -> Series -> Either MathError Bool
```

```c
hmath_status hmath_timeseries_is_regular(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `logarithmic_returns`

`timeseries.logarithmic_returns(xs)`

Consecutive log returns, using log prices to avoid ratio overflow.

Original: [`HMath.TimeSeries.Core.logarithmicReturns`](haskell/HMath-TimeSeries-Core.md#v:logarithmicReturns).

```haskell
[Double] -> Either MathError [Double]
```

```c
hmath_status hmath_timeseries_logarithmic_returns(hmath_context *context, const hmath_value *xs, hmath_value **out);
```

## `observations`

`timeseries.observations(value)`

 Extract time-ordered (timestamp,Maybe value) observations from a validated Series. Missing values remain Nothing. 

Original: [`HMath.TimeSeries.Core.observations`](haskell/HMath-TimeSeries-Core.md#v:observations).

```haskell
Series -> [(Double, Maybe Double)]
```

```c
hmath_status hmath_timeseries_observations(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `partial_autocorrelation`

`timeseries.partial_autocorrelation(order, xs)`

 Given maximum lag then samples, compute ACF and Durbin-Levinson partial correlations, returning lag zero (1) followed by requested PACF lags. Invalid lag/data or singular covariance recurrence returns Left MathError. 

Original: [`HMath.TimeSeries.Core.partialAutocorrelation`](haskell/HMath-TimeSeries-Core.md#v:partialAutocorrelation).

```haskell
Int -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_timeseries_partial_autocorrelation(hmath_context *context, const hmath_value *order, const hmath_value *xs, hmath_value **out);
```

## `regular_series`

`timeseries.regular_series(start, step, xs)`

Sample times start+i*step. Rounded duplicate times are rejected as well.

Original: [`HMath.TimeSeries.Core.regularSeries`](haskell/HMath-TimeSeries-Core.md#v:regularSeries).

```haskell
Double -> Double -> [Maybe Double] -> Either MathError Series
```

```c
hmath_status hmath_timeseries_regular_series(hmath_context *context, const hmath_value *start, const hmath_value *step, const hmath_value *xs, hmath_value **out);
```

## `resample`

`timeseries.resample(value, value2, value3, value4, value5)`

 Linear samples require brackets (or an exact timestamp). Bins are [start+i*step,start+(i+1)*step); the final right endpoint is excluded. 

Original: [`HMath.TimeSeries.Core.resample`](haskell/HMath-TimeSeries-Core.md#v:resample).

```haskell
Resampling -> Double -> Double -> Int -> Series -> Either MathError Series
```

```c
hmath_status hmath_timeseries_resample(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, hmath_value **out);
```

## `rolling`

`timeseries.rolling(method, width, xs)`

Full trailing windows only; variance is population variance (ddof=0).

Original: [`HMath.TimeSeries.Core.rolling`](haskell/HMath-TimeSeries-Core.md#v:rolling).

```haskell
Rolling -> Int -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_timeseries_rolling(hmath_context *context, const hmath_value *method, const hmath_value *width, const hmath_value *xs, hmath_value **out);
```

## `series`

`timeseries.series(xs)`

Preserve order and missing values; reject duplicate or nonfinite times.

Original: [`HMath.TimeSeries.Core.series`](haskell/HMath-TimeSeries-Core.md#v:series).

```haskell
[(Double, Maybe Double)] -> Either MathError Series
```

```c
hmath_status hmath_timeseries_series(hmath_context *context, const hmath_value *xs, hmath_value **out);
```

## `series_values`

`timeseries.series_values(value)`

Complete-data conversion never silently drops a missing observation.

Original: [`HMath.TimeSeries.Core.seriesValues`](haskell/HMath-TimeSeries-Core.md#v:seriesValues).

```haskell
Series -> Either MathError [Double]
```

```c
hmath_status hmath_timeseries_series_values(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `weighted_average`

`timeseries.weighted_average(ws, xs)`

Nonnegative chronological weights: first weight multiplies oldest sample.

Original: [`HMath.TimeSeries.Core.weightedAverage`](haskell/HMath-TimeSeries-Core.md#v:weightedAverage).

```haskell
[Double] -> [Double] -> Either MathError [Double]
```

```c
hmath_status hmath_timeseries_weighted_average(hmath_context *context, const hmath_value *ws, const hmath_value *xs, hmath_value **out);
```

## `yule_walker`

`timeseries.yule_walker(order, xs)`

Biased sample autocovariances with centered data; returns mean separately.

Original: [`HMath.TimeSeries.Core.yuleWalker`](haskell/HMath-TimeSeries-Core.md#v:yuleWalker).

```haskell
Int -> [Double] -> Either MathError ([Double], Double, Double)
```

```c
hmath_status hmath_timeseries_yule_walker(hmath_context *context, const hmath_value *order, const hmath_value *xs, hmath_value **out);
```

## `dtw_result`

`timeseries.dtw_result(distance, path)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Diagnostics.DTWResult`](haskell/HMath-TimeSeries-Diagnostics.md#v:DTWResult).

```haskell
Double -> [(Int, Int)] -> DTWResult
```

```c
hmath_status hmath_timeseries_dtw_result(hmath_context *context, const hmath_value *distance, const hmath_value *path, hmath_value **out);
```

## `level`

`timeseries.level()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Diagnostics.Level`](haskell/HMath-TimeSeries-Diagnostics.md#v:Level).

```haskell
Deterministic
```

```c
hmath_status hmath_timeseries_level(hmath_context *context, hmath_value **out);
```

## `linear_trend`

`timeseries.linear_trend()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Diagnostics.LinearTrend`](haskell/HMath-TimeSeries-Diagnostics.md#v:LinearTrend).

```haskell
Deterministic
```

```c
hmath_status hmath_timeseries_linear_trend(hmath_context *context, hmath_value **out);
```

## `mae`

`timeseries.mae()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Diagnostics.MAE`](haskell/HMath-TimeSeries-Diagnostics.md#v:MAE).

```haskell
ForecastMetric
```

```c
hmath_status hmath_timeseries_mae(hmath_context *context, hmath_value **out);
```

## `mape`

`timeseries.mape()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Diagnostics.MAPE`](haskell/HMath-TimeSeries-Diagnostics.md#v:MAPE).

```haskell
ForecastMetric
```

```c
hmath_status hmath_timeseries_mape(hmath_context *context, hmath_value **out);
```

## `mase`

`timeseries.mase(period, training)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Diagnostics.MASE`](haskell/HMath-TimeSeries-Diagnostics.md#v:MASE).

```haskell
Int -> [Double] -> ForecastMetric
```

```c
hmath_status hmath_timeseries_mase(hmath_context *context, const hmath_value *period, const hmath_value *training, hmath_value **out);
```

## `mse`

`timeseries.mse()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Diagnostics.MSE`](haskell/HMath-TimeSeries-Diagnostics.md#v:MSE).

```haskell
ForecastMetric
```

```c
hmath_status hmath_timeseries_mse(hmath_context *context, hmath_value **out);
```

## `rmse`

`timeseries.rmse()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Diagnostics.RMSE`](haskell/HMath-TimeSeries-Diagnostics.md#v:RMSE).

```haskell
ForecastMetric
```

```c
hmath_status hmath_timeseries_rmse(hmath_context *context, hmath_value **out);
```

## `smape`

`timeseries.smape()`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Diagnostics.SMAPE`](haskell/HMath-TimeSeries-Diagnostics.md#v:SMAPE).

```haskell
ForecastMetric
```

```c
hmath_status hmath_timeseries_smape(hmath_context *context, hmath_value **out);
```

## `stationarity`

`timeseries.stationarity(statistic, critical_values, observations, null_hypothesis)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Diagnostics.Stationarity`](haskell/HMath-TimeSeries-Diagnostics.md#v:Stationarity).

```haskell
Double -> [(Double, Double)] -> Int -> String -> Stationarity
```

```c
hmath_status hmath_timeseries_stationarity(hmath_context *context, const hmath_value *statistic, const hmath_value *critical_values, const hmath_value *observations, const hmath_value *null_hypothesis, hmath_value **out);
```

## `anomalies`

`timeseries.anomalies(threshold, xs)`

 Median/MAD outliers, using the normal-consistency factor 1.4826022185. If MAD is zero, every value different from the median is an anomaly. 

Original: [`HMath.TimeSeries.Diagnostics.anomalies`](haskell/HMath-TimeSeries-Diagnostics.md#v:anomalies).

```haskell
Double -> [Double] -> Either MathError [Int]
```

```c
hmath_status hmath_timeseries_anomalies(hmath_context *context, const hmath_value *threshold, const hmath_value *xs, hmath_value **out);
```

## `augmented_dickey_fuller`

`timeseries.augmented_dickey_fuller(deterministic, lags, xs)`

 OLS of delta x_t on x_(t-1), an intercept, optional trend, and explicitly supplied lagged differences. Returns the lagged-level t statistic. Critical values use MacKinnon (2010) finite-sample polynomials for one series: https://www.statsmodels.org/stable/generated/statsmodels.tsa.stattools.adfuller.html . There is no automatic lag selection or normal/Student-t p-value shortcut. 

Original: [`HMath.TimeSeries.Diagnostics.augmentedDickeyFuller`](haskell/HMath-TimeSeries-Diagnostics.md#v:augmentedDickeyFuller).

```haskell
Deterministic -> Int -> [Double] -> Either MathError Stationarity
```

```c
hmath_status hmath_timeseries_augmented_dickey_fuller(hmath_context *context, const hmath_value *deterministic, const hmath_value *lags, const hmath_value *xs, hmath_value **out);
```

## `change_points`

`timeseries.change_points(penalty, min_segment, xs)`

 Exact quadratic dynamic programming for piecewise-constant least squares, minimizing total within-segment SSE plus penalty per change. Break indices are zero-based starts of new segments. No pruning/approximation is used. 

Original: [`HMath.TimeSeries.Diagnostics.changePoints`](haskell/HMath-TimeSeries-Diagnostics.md#v:changePoints).

```haskell
Double -> Int -> [Double] -> Either MathError [Int]
```

```c
hmath_status hmath_timeseries_change_points(hmath_context *context, const hmath_value *penalty, const hmath_value *min_segment, const hmath_value *xs, hmath_value **out);
```

## `cusum`

`timeseries.cusum(mean, sd, drift, threshold, xs)`

 Two-sided Page CUSUM with supplied baseline mean/SD. A threshold crossing emits its index and resets both cumulative scores. drift and threshold are in standardized observation units. 

Original: [`HMath.TimeSeries.Diagnostics.cusum`](haskell/HMath-TimeSeries-Diagnostics.md#v:cusum).

```haskell
Double -> Double -> Double -> Double -> [Double] -> Either MathError [Int]
```

```c
hmath_status hmath_timeseries_cusum(hmath_context *context, const hmath_value *mean, const hmath_value *sd, const hmath_value *drift, const hmath_value *threshold, const hmath_value *xs, hmath_value **out);
```

## `dtw_distance`

`timeseries.dtw_distance(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Diagnostics.dtwDistance`](haskell/HMath-TimeSeries-Diagnostics.md#v:dtwDistance).

```haskell
DTWResult -> Double
```

```c
hmath_status hmath_timeseries_dtw_distance(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `dtw_path`

`timeseries.dtw_path(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Diagnostics.dtwPath`](haskell/HMath-TimeSeries-Diagnostics.md#v:dtwPath).

```haskell
DTWResult -> [(Int, Int)]
```

```c
hmath_status hmath_timeseries_dtw_path(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `dynamic_time_warping`

`timeseries.dynamic_time_warping(radius, xs, ys)`

 Absolute local cost; Sakoe--Chiba radius must include both endpoints. Returns the unnormalized path cost, with diagonal/up/left tie priority. 

Original: [`HMath.TimeSeries.Diagnostics.dynamicTimeWarping`](haskell/HMath-TimeSeries-Diagnostics.md#v:dynamicTimeWarping).

```haskell
Int -> [Double] -> [Double] -> Either MathError DTWResult
```

```c
hmath_status hmath_timeseries_dynamic_time_warping(hmath_context *context, const hmath_value *radius, const hmath_value *xs, const hmath_value *ys, hmath_value **out);
```

## `forecast_error`

`timeseries.forecast_error(metric, actual, predicted)`

 MAPE and sMAPE are percentages; zero/zero sMAPE contributes zero. MASE supplies its separate training set and seasonal lag to avoid test leakage. 

Original: [`HMath.TimeSeries.Diagnostics.forecastError`](haskell/HMath-TimeSeries-Diagnostics.md#v:forecastError).

```haskell
ForecastMetric -> [Double] -> [Double] -> Either MathError Double
```

```c
hmath_status hmath_timeseries_forecast_error(hmath_context *context, const hmath_value *metric, const hmath_value *actual, const hmath_value *predicted, hmath_value **out);
```

## `kpss`

`timeseries.kpss(deterministic, lags, xs)`

 KPSS level/trend stationarity with an explicit Bartlett/Newey--West lag bandwidth. Critical values are Table 1 of Kwiatkowski et al. (1992), as documented at https://www.statsmodels.org/stable/generated/statsmodels.tsa.stattools.kpss.html . 

Original: [`HMath.TimeSeries.Diagnostics.kpss`](haskell/HMath-TimeSeries-Diagnostics.md#v:kpss).

```haskell
Deterministic -> Int -> [Double] -> Either MathError Stationarity
```

```c
hmath_status hmath_timeseries_kpss(hmath_context *context, const hmath_value *deterministic, const hmath_value *lags, const hmath_value *xs, hmath_value **out);
```

## `spectrum`

`timeseries.spectrum(sample_rate, xs)`

 One-sided unwindowed periodogram density. Non-DC/Nyquist bins are doubled; integral of density over frequency equals the sample mean square. 

Original: [`HMath.TimeSeries.Diagnostics.spectrum`](haskell/HMath-TimeSeries-Diagnostics.md#v:spectrum).

```haskell
Double -> [Double] -> Either MathError [(Double, Double)]
```

```c
hmath_status hmath_timeseries_spectrum(hmath_context *context, const hmath_value *sample_rate, const hmath_value *xs, hmath_value **out);
```

## `stationarity_critical_values`

`timeseries.stationarity_critical_values(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Diagnostics.stationarityCriticalValues`](haskell/HMath-TimeSeries-Diagnostics.md#v:stationarityCriticalValues).

```haskell
Stationarity -> [(Double, Double)]
```

```c
hmath_status hmath_timeseries_stationarity_critical_values(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `stationarity_null`

`timeseries.stationarity_null(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Diagnostics.stationarityNull`](haskell/HMath-TimeSeries-Diagnostics.md#v:stationarityNull).

```haskell
Stationarity -> String
```

```c
hmath_status hmath_timeseries_stationarity_null(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `stationarity_observations`

`timeseries.stationarity_observations(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Diagnostics.stationarityObservations`](haskell/HMath-TimeSeries-Diagnostics.md#v:stationarityObservations).

```haskell
Stationarity -> Int
```

```c
hmath_status hmath_timeseries_stationarity_observations(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `stationarity_statistic`

`timeseries.stationarity_statistic(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Diagnostics.stationarityStatistic`](haskell/HMath-TimeSeries-Diagnostics.md#v:stationarityStatistic).

```haskell
Stationarity -> Double
```

```c
hmath_status hmath_timeseries_stationarity_statistic(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `decomposition`

`timeseries.decomposition(trend, seasonal, remainder)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.Decomposition`](haskell/HMath-TimeSeries-Models.md#v:Decomposition).

```haskell
[Double] -> [Double] -> [Double] -> Decomposition
```

```c
hmath_status hmath_timeseries_decomposition(hmath_context *context, const hmath_value *trend, const hmath_value *seasonal, const hmath_value *remainder, hmath_value **out);
```

## `holt`

`timeseries.holt(alpha, beta)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.Holt`](haskell/HMath-TimeSeries-Models.md#v:Holt).

```haskell
Double -> Double -> Smoothing
```

```c
hmath_status hmath_timeseries_holt(hmath_context *context, const hmath_value *alpha, const hmath_value *beta, hmath_value **out);
```

## `holt_winters`

`timeseries.holt_winters(period, alpha, beta, gamma)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.HoltWinters`](haskell/HMath-TimeSeries-Models.md#v:HoltWinters).

```haskell
Int -> Double -> Double -> Double -> Smoothing
```

```c
hmath_status hmath_timeseries_holt_winters(hmath_context *context, const hmath_value *period, const hmath_value *alpha, const hmath_value *beta, const hmath_value *gamma, hmath_value **out);
```

## `sarima_order`

`timeseries.sarima_order(ar, difference, ma, seasonal_ar, seasonal_difference, seasonal_ma, period)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.SARIMAOrder`](haskell/HMath-TimeSeries-Models.md#v:SARIMAOrder).

```haskell
Int -> Int -> Int -> Int -> Int -> Int -> Int -> SARIMAOrder
```

```c
hmath_status hmath_timeseries_sarima_order(hmath_context *context, const hmath_value *ar, const hmath_value *difference, const hmath_value *ma, const hmath_value *seasonal_ar, const hmath_value *seasonal_difference, const hmath_value *seasonal_ma, const hmath_value *period, hmath_value **out);
```

## `stl_config`

`timeseries.stl_config(period, seasonal_window, trend_window, low_pass_window, inner_iterations, robust_iterations)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.STLConfig`](haskell/HMath-TimeSeries-Models.md#v:STLConfig).

```haskell
Int -> Int -> Int -> Int -> Int -> Int -> STLConfig
```

```c
hmath_status hmath_timeseries_stl_config(hmath_context *context, const hmath_value *period, const hmath_value *seasonal_window, const hmath_value *trend_window, const hmath_value *low_pass_window, const hmath_value *inner_iterations, const hmath_value *robust_iterations, hmath_value **out);
```

## `simple`

`timeseries.simple(alpha)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.Simple`](haskell/HMath-TimeSeries-Models.md#v:Simple).

```haskell
Double -> Smoothing
```

```c
hmath_status hmath_timeseries_simple(hmath_context *context, const hmath_value *alpha, hmath_value **out);
```

## `ar_coefficients`

`timeseries.ar_coefficients(value)`

 Return AR intercept followed by lag-1 through lag-p coefficients. The model retains observations chronologically for forecastAR. 

Original: [`HMath.TimeSeries.Models.arCoefficients`](haskell/HMath-TimeSeries-Models.md#v:arCoefficients).

```haskell
ARModel -> [Double]
```

```c
hmath_status hmath_timeseries_ar_coefficients(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `ar_order`

`timeseries.ar_order(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.arOrder`](haskell/HMath-TimeSeries-Models.md#v:arOrder).

```haskell
SARIMAOrder -> Int
```

```c
hmath_status hmath_timeseries_ar_order(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `arima_innovation_variance`

`timeseries.arima_innovation_variance(value)`

Return fitted innovation-variance estimate stored in an ARIMA/SARIMA model.

Original: [`HMath.TimeSeries.Models.arimaInnovationVariance`](haskell/HMath-TimeSeries-Models.md#v:arimaInnovationVariance).

```haskell
ARIMAModel -> Double
```

```c
hmath_status hmath_timeseries_arima_innovation_variance(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `arima_parameters`

`timeseries.arima_parameters(value)`

 Return fitted intercept,ordinary AR,ordinary MA,seasonal AR,seasonal MA parameters in that order. Intercept belongs to the differenced process. 

Original: [`HMath.TimeSeries.Models.arimaParameters`](haskell/HMath-TimeSeries-Models.md#v:arimaParameters).

```haskell
ARIMAModel -> [Double]
```

```c
hmath_status hmath_timeseries_arima_parameters(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `arima_residuals`

`timeseries.arima_residuals(value)`

 Return fitted innovation residuals in chronological order, on the model's differenced process. 

Original: [`HMath.TimeSeries.Models.arimaResiduals`](haskell/HMath-TimeSeries-Models.md#v:arimaResiduals).

```haskell
ARIMAModel -> [Double]
```

```c
hmath_status hmath_timeseries_arima_residuals(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `decompose`

`timeseries.decompose(period, xs)`

 Classical additive decomposition with local linear trend smoothing and centered phase means. Requires at least two complete periods. 

Original: [`HMath.TimeSeries.Models.decompose`](haskell/HMath-TimeSeries-Models.md#v:decompose).

```haskell
Int -> [Double] -> Either MathError Decomposition
```

```c
hmath_status hmath_timeseries_decompose(hmath_context *context, const hmath_value *period, const hmath_value *xs, hmath_value **out);
```

## `default_stl_config`

`timeseries.default_stl_config(period)`

 Given seasonal period, construct STL options with seasonal window 7, odd trend window above 2*period, odd low-pass window at/above period, two inner iterations and no robust outer iterations. stl validates the resulting configuration. 

Original: [`HMath.TimeSeries.Models.defaultSTLConfig`](haskell/HMath-TimeSeries-Models.md#v:defaultSTLConfig).

```haskell
Int -> STLConfig
```

```c
hmath_status hmath_timeseries_default_stl_config(hmath_context *context, const hmath_value *period, hmath_value **out);
```

## `difference_order`

`timeseries.difference_order(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.differenceOrder`](haskell/HMath-TimeSeries-Models.md#v:differenceOrder).

```haskell
SARIMAOrder -> Int
```

```c
hmath_status hmath_timeseries_difference_order(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `fit_ar`

`timeseries.fit_ar(order, xs)`

 Given AR order then finite chronological samples, fit intercept and lag coefficients by checked OLS. Require order in [0,64], <=4096 samples and more than 2*order+1 observations; invalid/ill-conditioned fits fail. 

Original: [`HMath.TimeSeries.Models.fitAR`](haskell/HMath-TimeSeries-Models.md#v:fitAR).

```haskell
Int -> [Double] -> Either MathError ARModel
```

```c
hmath_status hmath_timeseries_fit_ar(hmath_context *context, const hmath_value *order, const hmath_value *xs, hmath_value **out);
```

## `fit_arima`

`timeseries.fit_arima(value, value2, value3, value4, value5)`

 Given optimization options,p,d,q,then finite chronological series, fit nonseasonal ARIMA through fitSARIMA with seasonal orders zero. Invalid order/sample bounds, unstable or nonconvergent/ill-conditioned fit returns Left MathError. 

Original: [`HMath.TimeSeries.Models.fitARIMA`](haskell/HMath-TimeSeries-Models.md#v:fitARIMA).

```haskell
OptimizeOptions -> Int -> Int -> Int -> [Double] -> Either MathError ARIMAModel
```

```c
hmath_status hmath_timeseries_fit_arima(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, hmath_value **out);
```

## `fit_arma`

`timeseries.fit_arma(value, value2, value3, value4)`

 Given optimization options,AR order p,MA order q,then samples, fit ARIMA(p,0,q). Invalid or nonconvergent fits return Left MathError. 

Original: [`HMath.TimeSeries.Models.fitARMA`](haskell/HMath-TimeSeries-Models.md#v:fitARMA).

```haskell
OptimizeOptions -> Int -> Int -> [Double] -> Either MathError ARIMAModel
```

```c
hmath_status hmath_timeseries_fit_arma(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, hmath_value **out);
```

## `fit_ma`

`timeseries.fit_ma(value, value2, value3)`

 Given optimization options,MA order q,then samples, fit ARIMA(0,0,q). Order/sample/optimization errors propagate from fitARIMA. 

Original: [`HMath.TimeSeries.Models.fitMA`](haskell/HMath-TimeSeries-Models.md#v:fitMA).

```haskell
OptimizeOptions -> Int -> [Double] -> Either MathError ARIMAModel
```

```c
hmath_status hmath_timeseries_fit_ma(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out);
```

## `fit_sarima`

`timeseries.fit_sarima(options, order, xs)`

 Parameters are intercept, ordinary AR, ordinary MA, seasonal AR, seasonal MA. Multiplicative seasonal polynomials include cross-lag interactions. Intercept always belongs to the differenced process. Caller supplies fit budgets; exhausted or ill-conditioned fits return MathError. 

Original: [`HMath.TimeSeries.Models.fitSARIMA`](haskell/HMath-TimeSeries-Models.md#v:fitSARIMA).

```haskell
OptimizeOptions -> SARIMAOrder -> [Double] -> Either MathError ARIMAModel
```

```c
hmath_status hmath_timeseries_fit_sarima(hmath_context *context, const hmath_value *options, const hmath_value *order, const hmath_value *xs, hmath_value **out);
```

## `fit_var`

`timeseries.fit_var(order, xs)`

 Given lag order then chronological multivariate rows, fit response-wise OLS with intercept and lag-major features. Require finite rectangular data, dimensions<=16, rows<=2048, order in [1,16], sufficient samples and <=20000000 fitting work. Invalid/ill-conditioned fits fail. 

Original: [`HMath.TimeSeries.Models.fitVAR`](haskell/HMath-TimeSeries-Models.md#v:fitVAR).

```haskell
Int -> [[Double]] -> Either MathError VARModel
```

```c
hmath_status hmath_timeseries_fit_var(hmath_context *context, const hmath_value *order, const hmath_value *xs, hmath_value **out);
```

## `forecast_ar`

`timeseries.forecast_ar(value, value2)`

 Given horizon in [0,16384] then fitted AR model, recursively forecast future samples from latest observations. Zero horizon returns []; invalid horizon or non-finite predictions fail. 

Original: [`HMath.TimeSeries.Models.forecastAR`](haskell/HMath-TimeSeries-Models.md#v:forecastAR).

```haskell
Int -> ARModel -> Either MathError [Double]
```

```c
hmath_status hmath_timeseries_forecast_ar(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `forecast_arima`

`timeseries.forecast_arima(value, value2)`

 Given horizon in [0,16384] then fitted ARIMA/SARIMA model, forecast recursively with future innovations set to zero and undo ordinary/seasonal differencing. Invalid horizon or non-finite predictions fail. 

Original: [`HMath.TimeSeries.Models.forecastARIMA`](haskell/HMath-TimeSeries-Models.md#v:forecastARIMA).

```haskell
Int -> ARIMAModel -> Either MathError [Double]
```

```c
hmath_status hmath_timeseries_forecast_arima(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `forecast_var`

`timeseries.forecast_var(value, value2)`

 Given horizon then VAR model, recursively return future multivariate observation rows. Require horizon in [0,16384] and horizon*components<=262144; invalid bounds or non-finite predictions fail. 

Original: [`HMath.TimeSeries.Models.forecastVAR`](haskell/HMath-TimeSeries-Models.md#v:forecastVAR).

```haskell
Int -> VARModel -> Either MathError [[Double]]
```

```c
hmath_status hmath_timeseries_forecast_var(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out);
```

## `kalman_series`

`timeseries.kalman_series(transition, observation, q, r, initial, measured)`

 Reuse the checked Joseph-form linear Kalman update for each complete observation. Returns posterior states, excluding the caller's initial state. 

Original: [`HMath.TimeSeries.Models.kalmanSeries`](haskell/HMath-TimeSeries-Models.md#v:kalmanSeries).

```haskell
[[Double]] -> [[Double]] -> [[Double]] -> [[Double]] -> GaussianState -> [[Double]] -> Either MathError [GaussianState]
```

```c
hmath_status hmath_timeseries_kalman_series(hmath_context *context, const hmath_value *transition, const hmath_value *observation, const hmath_value *q, const hmath_value *r, const hmath_value *initial, const hmath_value *measured, hmath_value **out);
```

## `ma_order`

`timeseries.ma_order(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.maOrder`](haskell/HMath-TimeSeries-Models.md#v:maOrder).

```haskell
SARIMAOrder -> Int
```

```c
hmath_status hmath_timeseries_ma_order(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `remainder_component`

`timeseries.remainder_component(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.remainderComponent`](haskell/HMath-TimeSeries-Models.md#v:remainderComponent).

```haskell
Decomposition -> [Double]
```

```c
hmath_status hmath_timeseries_remainder_component(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `seasonal_ar_order`

`timeseries.seasonal_ar_order(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.seasonalAROrder`](haskell/HMath-TimeSeries-Models.md#v:seasonalAROrder).

```haskell
SARIMAOrder -> Int
```

```c
hmath_status hmath_timeseries_seasonal_ar_order(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `seasonal_component`

`timeseries.seasonal_component(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.seasonalComponent`](haskell/HMath-TimeSeries-Models.md#v:seasonalComponent).

```haskell
Decomposition -> [Double]
```

```c
hmath_status hmath_timeseries_seasonal_component(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `seasonal_difference_order`

`timeseries.seasonal_difference_order(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.seasonalDifferenceOrder`](haskell/HMath-TimeSeries-Models.md#v:seasonalDifferenceOrder).

```haskell
SARIMAOrder -> Int
```

```c
hmath_status hmath_timeseries_seasonal_difference_order(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `seasonal_ma_order`

`timeseries.seasonal_ma_order(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.seasonalMAOrder`](haskell/HMath-TimeSeries-Models.md#v:seasonalMAOrder).

```haskell
SARIMAOrder -> Int
```

```c
hmath_status hmath_timeseries_seasonal_ma_order(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `seasonal_period`

`timeseries.seasonal_period(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.seasonalPeriod`](haskell/HMath-TimeSeries-Models.md#v:seasonalPeriod).

```haskell
SARIMAOrder -> Int
```

```c
hmath_status hmath_timeseries_seasonal_period(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `smooth_forecast`

`timeseries.smooth_forecast(method, horizon, xs)`

 Fitted one-step means and future means. Simple/Holt initialize from the first sample/first difference. Additive Holt--Winters initializes the level and seasonal indices from a complete first cycle, and the trend from the difference between the first two cycle means. Initial fitted cycle is the initializer, not an out-of-sample prediction. 

Original: [`HMath.TimeSeries.Models.smoothForecast`](haskell/HMath-TimeSeries-Models.md#v:smoothForecast).

```haskell
Smoothing -> Int -> [Double] -> Either MathError ([Double], [Double])
```

```c
hmath_status hmath_timeseries_smooth_forecast(hmath_context *context, const hmath_value *method, const hmath_value *horizon, const hmath_value *xs, hmath_value **out);
```

## `stl`

`timeseries.stl(config, xs)`

 Cleveland-style STL reference backfitting: smooth seasonal subseries by degree-one tricube LOESS with one-cycle extrapolation; remove a period, period, three-point moving-average low-pass followed by LOESS, then smooth the deseasonalized trend. Optional bisquare robust outer iterations use six times median absolute residual. Every index is evaluated (no jump shortcut). See https://search.r-project.org/R/refmans/stats/html/stl.html . 

Original: [`HMath.TimeSeries.Models.stl`](haskell/HMath-TimeSeries-Models.md#v:stl).

```haskell
STLConfig -> [Double] -> Either MathError Decomposition
```

```c
hmath_status hmath_timeseries_stl(hmath_context *context, const hmath_value *config, const hmath_value *xs, hmath_value **out);
```

## `stl_inner_iterations`

`timeseries.stl_inner_iterations(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.stlInnerIterations`](haskell/HMath-TimeSeries-Models.md#v:stlInnerIterations).

```haskell
STLConfig -> Int
```

```c
hmath_status hmath_timeseries_stl_inner_iterations(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `stl_low_pass_window`

`timeseries.stl_low_pass_window(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.stlLowPassWindow`](haskell/HMath-TimeSeries-Models.md#v:stlLowPassWindow).

```haskell
STLConfig -> Int
```

```c
hmath_status hmath_timeseries_stl_low_pass_window(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `stl_period`

`timeseries.stl_period(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.stlPeriod`](haskell/HMath-TimeSeries-Models.md#v:stlPeriod).

```haskell
STLConfig -> Int
```

```c
hmath_status hmath_timeseries_stl_period(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `stl_robust_iterations`

`timeseries.stl_robust_iterations(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.stlRobustIterations`](haskell/HMath-TimeSeries-Models.md#v:stlRobustIterations).

```haskell
STLConfig -> Int
```

```c
hmath_status hmath_timeseries_stl_robust_iterations(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `stl_seasonal_window`

`timeseries.stl_seasonal_window(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.stlSeasonalWindow`](haskell/HMath-TimeSeries-Models.md#v:stlSeasonalWindow).

```haskell
STLConfig -> Int
```

```c
hmath_status hmath_timeseries_stl_seasonal_window(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `stl_trend_window`

`timeseries.stl_trend_window(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.stlTrendWindow`](haskell/HMath-TimeSeries-Models.md#v:stlTrendWindow).

```haskell
STLConfig -> Int
```

```c
hmath_status hmath_timeseries_stl_trend_window(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `trend_component`

`timeseries.trend_component(value)`

Construct or inspect the original immutable record; field order follows the source signature.

Original: [`HMath.TimeSeries.Models.trendComponent`](haskell/HMath-TimeSeries-Models.md#v:trendComponent).

```haskell
Decomposition -> [Double]
```

```c
hmath_status hmath_timeseries_trend_component(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `var_coefficients`

`timeseries.var_coefficients(value)`

Rows are response components, columns are intercept then lag-major predictors.

Original: [`HMath.TimeSeries.Models.varCoefficients`](haskell/HMath-TimeSeries-Models.md#v:varCoefficients).

```haskell
VARModel -> [[Double]]
```

```c
hmath_status hmath_timeseries_var_coefficients(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `gaussian_state`

`timeseries.gaussian_state(mean, covariance)`

 Validate a mean and symmetric positive semidefinite covariance; Cholesky roundoff tolerance is 1e-12*max(1,diagonal). Accepted tiny negative pivots are clipped, and the stored covariance is reconstructed from that factor. Thus a tolerated negative input variance never escapes through stateCovariance. 

Original: [`HMath.Signal.gaussianState`](haskell/HMath-Signal.md#v:gaussianState).

```haskell
[Double] -> [[Double]] -> Either MathError GaussianState
```

```c
hmath_status hmath_timeseries_gaussian_state(hmath_context *context, const hmath_value *mean, const hmath_value *covariance, hmath_value **out);
```

## `state_mean`

`timeseries.state_mean(value)`

Read the posterior mean vector.

Original: [`HMath.Signal.stateMean`](haskell/HMath-Signal.md#v:stateMean).

```haskell
GaussianState -> [Double]
```

```c
hmath_status hmath_timeseries_state_mean(hmath_context *context, const hmath_value *value, hmath_value **out);
```

## `state_covariance`

`timeseries.state_covariance(value)`

Read the symmetric posterior covariance matrix.

Original: [`HMath.Signal.stateCovariance`](haskell/HMath-Signal.md#v:stateCovariance).

```haskell
GaussianState -> [[Double]]
```

```c
hmath_status hmath_timeseries_state_covariance(hmath_context *context, const hmath_value *value, hmath_value **out);
```

