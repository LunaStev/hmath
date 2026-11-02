/* SPDX-License-Identifier: MPL-2.0 */
/* Generated; do not edit. */
#include "hmath_timeseries.h"
#include "value_internal.h"
extern int hm_timeseries_apply(int, void *const *, size_t, void **);
extern int hm_timeseries_describe(void *,void **);
hmath_status hmath_timeseries_describe(hmath_context *context,const hmath_value *value,hmath_value **out) {
    if (!value || !out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series description argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    int code = hm_timeseries_describe(hm_value_stable(value),&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_backward_fill(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(0,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_bin_last(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(1,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_bin_mean(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(2,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_forward_fill(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(3,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_inner(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(4,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_left_aligned(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(5,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_linear_fill(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(6,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_linear_samples(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(7,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_moving_maximum(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(8,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_moving_mean(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(9,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_moving_minimum(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(10,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_moving_sd(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(11,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_moving_variance(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(12,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_outer(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(13,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_align(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out) {
    if (!out || !value || !value2 || !value3)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3)};
    int code = hm_timeseries_apply(14,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_autocorrelation(hmath_context *context, const hmath_value *lags, const hmath_value *xs, hmath_value **out) {
    if (!out || !lags || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(lags), hm_value_stable(xs)};
    int code = hm_timeseries_apply(15,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_cross_correlation(hmath_context *context, const hmath_value *lag, const hmath_value *xs, const hmath_value *ys, hmath_value **out) {
    if (!out || !lag || !xs || !ys)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(lag), hm_value_stable(xs), hm_value_stable(ys)};
    int code = hm_timeseries_apply(16,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_cumulative_returns(hmath_context *context, const hmath_value *xs, hmath_value **out) {
    if (!out || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(xs)};
    int code = hm_timeseries_apply(17,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_difference(hmath_context *context, const hmath_value *order, const hmath_value *lag, const hmath_value *xs, hmath_value **out) {
    if (!out || !order || !lag || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(order), hm_value_stable(lag), hm_value_stable(xs)};
    int code = hm_timeseries_apply(18,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_durbin_levinson(hmath_context *context, const hmath_value *covariance, hmath_value **out) {
    if (!out || !covariance)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(covariance)};
    int code = hm_timeseries_apply(19,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_exponential_average(hmath_context *context, const hmath_value *alpha, const hmath_value *xs, hmath_value **out) {
    if (!out || !alpha || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(alpha), hm_value_stable(xs)};
    int code = hm_timeseries_apply(20,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_fill_missing(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value), hm_value_stable(value2)};
    int code = hm_timeseries_apply(21,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_is_regular(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value), hm_value_stable(value2)};
    int code = hm_timeseries_apply(22,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_logarithmic_returns(hmath_context *context, const hmath_value *xs, hmath_value **out) {
    if (!out || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(xs)};
    int code = hm_timeseries_apply(23,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_observations(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(24,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_partial_autocorrelation(hmath_context *context, const hmath_value *order, const hmath_value *xs, hmath_value **out) {
    if (!out || !order || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(order), hm_value_stable(xs)};
    int code = hm_timeseries_apply(25,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_regular_series(hmath_context *context, const hmath_value *start, const hmath_value *step, const hmath_value *xs, hmath_value **out) {
    if (!out || !start || !step || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(start), hm_value_stable(step), hm_value_stable(xs)};
    int code = hm_timeseries_apply(26,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_resample(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, hmath_value **out) {
    if (!out || !value || !value2 || !value3 || !value4 || !value5)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3), hm_value_stable(value4), hm_value_stable(value5)};
    int code = hm_timeseries_apply(27,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_rolling(hmath_context *context, const hmath_value *method, const hmath_value *width, const hmath_value *xs, hmath_value **out) {
    if (!out || !method || !width || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(method), hm_value_stable(width), hm_value_stable(xs)};
    int code = hm_timeseries_apply(28,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_series(hmath_context *context, const hmath_value *xs, hmath_value **out) {
    if (!out || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(xs)};
    int code = hm_timeseries_apply(29,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_series_values(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(30,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_weighted_average(hmath_context *context, const hmath_value *ws, const hmath_value *xs, hmath_value **out) {
    if (!out || !ws || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(ws), hm_value_stable(xs)};
    int code = hm_timeseries_apply(31,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_yule_walker(hmath_context *context, const hmath_value *order, const hmath_value *xs, hmath_value **out) {
    if (!out || !order || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(order), hm_value_stable(xs)};
    int code = hm_timeseries_apply(32,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_dtw_result(hmath_context *context, const hmath_value *distance, const hmath_value *path, hmath_value **out) {
    if (!out || !distance || !path)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(distance), hm_value_stable(path)};
    int code = hm_timeseries_apply(33,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_level(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(34,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_linear_trend(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(35,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_mae(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(36,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_mape(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(37,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_mase(hmath_context *context, const hmath_value *period, const hmath_value *training, hmath_value **out) {
    if (!out || !period || !training)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(period), hm_value_stable(training)};
    int code = hm_timeseries_apply(38,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_mse(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(39,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_rmse(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(40,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_smape(hmath_context *context, hmath_value **out) {
    if (!out)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {NULL};
    int code = hm_timeseries_apply(41,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_stationarity(hmath_context *context, const hmath_value *statistic, const hmath_value *critical_values, const hmath_value *observations, const hmath_value *null_hypothesis, hmath_value **out) {
    if (!out || !statistic || !critical_values || !observations || !null_hypothesis)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(statistic), hm_value_stable(critical_values), hm_value_stable(observations), hm_value_stable(null_hypothesis)};
    int code = hm_timeseries_apply(42,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_anomalies(hmath_context *context, const hmath_value *threshold, const hmath_value *xs, hmath_value **out) {
    if (!out || !threshold || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(threshold), hm_value_stable(xs)};
    int code = hm_timeseries_apply(43,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_augmented_dickey_fuller(hmath_context *context, const hmath_value *deterministic, const hmath_value *lags, const hmath_value *xs, hmath_value **out) {
    if (!out || !deterministic || !lags || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(deterministic), hm_value_stable(lags), hm_value_stable(xs)};
    int code = hm_timeseries_apply(44,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_change_points(hmath_context *context, const hmath_value *penalty, const hmath_value *min_segment, const hmath_value *xs, hmath_value **out) {
    if (!out || !penalty || !min_segment || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(penalty), hm_value_stable(min_segment), hm_value_stable(xs)};
    int code = hm_timeseries_apply(45,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_cusum(hmath_context *context, const hmath_value *mean, const hmath_value *sd, const hmath_value *drift, const hmath_value *threshold, const hmath_value *xs, hmath_value **out) {
    if (!out || !mean || !sd || !drift || !threshold || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(mean), hm_value_stable(sd), hm_value_stable(drift), hm_value_stable(threshold), hm_value_stable(xs)};
    int code = hm_timeseries_apply(46,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_dtw_distance(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(47,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_dtw_path(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(48,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_dynamic_time_warping(hmath_context *context, const hmath_value *radius, const hmath_value *xs, const hmath_value *ys, hmath_value **out) {
    if (!out || !radius || !xs || !ys)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(radius), hm_value_stable(xs), hm_value_stable(ys)};
    int code = hm_timeseries_apply(49,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_forecast_error(hmath_context *context, const hmath_value *metric, const hmath_value *actual, const hmath_value *predicted, hmath_value **out) {
    if (!out || !metric || !actual || !predicted)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(metric), hm_value_stable(actual), hm_value_stable(predicted)};
    int code = hm_timeseries_apply(50,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_kpss(hmath_context *context, const hmath_value *deterministic, const hmath_value *lags, const hmath_value *xs, hmath_value **out) {
    if (!out || !deterministic || !lags || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(deterministic), hm_value_stable(lags), hm_value_stable(xs)};
    int code = hm_timeseries_apply(51,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_spectrum(hmath_context *context, const hmath_value *sample_rate, const hmath_value *xs, hmath_value **out) {
    if (!out || !sample_rate || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(sample_rate), hm_value_stable(xs)};
    int code = hm_timeseries_apply(52,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_stationarity_critical_values(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(53,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_stationarity_null(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(54,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_stationarity_observations(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(55,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_stationarity_statistic(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(56,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_decomposition(hmath_context *context, const hmath_value *trend, const hmath_value *seasonal, const hmath_value *remainder, hmath_value **out) {
    if (!out || !trend || !seasonal || !remainder)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(trend), hm_value_stable(seasonal), hm_value_stable(remainder)};
    int code = hm_timeseries_apply(57,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_holt(hmath_context *context, const hmath_value *alpha, const hmath_value *beta, hmath_value **out) {
    if (!out || !alpha || !beta)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(alpha), hm_value_stable(beta)};
    int code = hm_timeseries_apply(58,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_holt_winters(hmath_context *context, const hmath_value *period, const hmath_value *alpha, const hmath_value *beta, const hmath_value *gamma, hmath_value **out) {
    if (!out || !period || !alpha || !beta || !gamma)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(period), hm_value_stable(alpha), hm_value_stable(beta), hm_value_stable(gamma)};
    int code = hm_timeseries_apply(59,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_sarima_order(hmath_context *context, const hmath_value *ar, const hmath_value *difference, const hmath_value *ma, const hmath_value *seasonal_ar, const hmath_value *seasonal_difference, const hmath_value *seasonal_ma, const hmath_value *period, hmath_value **out) {
    if (!out || !ar || !difference || !ma || !seasonal_ar || !seasonal_difference || !seasonal_ma || !period)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(ar), hm_value_stable(difference), hm_value_stable(ma), hm_value_stable(seasonal_ar), hm_value_stable(seasonal_difference), hm_value_stable(seasonal_ma), hm_value_stable(period)};
    int code = hm_timeseries_apply(60,arguments,7,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_stl_config(hmath_context *context, const hmath_value *period, const hmath_value *seasonal_window, const hmath_value *trend_window, const hmath_value *low_pass_window, const hmath_value *inner_iterations, const hmath_value *robust_iterations, hmath_value **out) {
    if (!out || !period || !seasonal_window || !trend_window || !low_pass_window || !inner_iterations || !robust_iterations)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(period), hm_value_stable(seasonal_window), hm_value_stable(trend_window), hm_value_stable(low_pass_window), hm_value_stable(inner_iterations), hm_value_stable(robust_iterations)};
    int code = hm_timeseries_apply(61,arguments,6,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_simple(hmath_context *context, const hmath_value *alpha, hmath_value **out) {
    if (!out || !alpha)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(alpha)};
    int code = hm_timeseries_apply(62,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_ar_coefficients(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(63,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_ar_order(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(64,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_arima_innovation_variance(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(65,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_arima_parameters(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(66,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_arima_residuals(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(67,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_decompose(hmath_context *context, const hmath_value *period, const hmath_value *xs, hmath_value **out) {
    if (!out || !period || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(period), hm_value_stable(xs)};
    int code = hm_timeseries_apply(68,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_default_stl_config(hmath_context *context, const hmath_value *period, hmath_value **out) {
    if (!out || !period)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(period)};
    int code = hm_timeseries_apply(69,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_difference_order(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(70,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_fit_ar(hmath_context *context, const hmath_value *order, const hmath_value *xs, hmath_value **out) {
    if (!out || !order || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(order), hm_value_stable(xs)};
    int code = hm_timeseries_apply(71,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_fit_arima(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, hmath_value **out) {
    if (!out || !value || !value2 || !value3 || !value4 || !value5)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3), hm_value_stable(value4), hm_value_stable(value5)};
    int code = hm_timeseries_apply(72,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_fit_arma(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, hmath_value **out) {
    if (!out || !value || !value2 || !value3 || !value4)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3), hm_value_stable(value4)};
    int code = hm_timeseries_apply(73,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_fit_ma(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out) {
    if (!out || !value || !value2 || !value3)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3)};
    int code = hm_timeseries_apply(74,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_fit_sarima(hmath_context *context, const hmath_value *options, const hmath_value *order, const hmath_value *xs, hmath_value **out) {
    if (!out || !options || !order || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(options), hm_value_stable(order), hm_value_stable(xs)};
    int code = hm_timeseries_apply(75,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_fit_var(hmath_context *context, const hmath_value *order, const hmath_value *xs, hmath_value **out) {
    if (!out || !order || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(order), hm_value_stable(xs)};
    int code = hm_timeseries_apply(76,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_forecast_ar(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value), hm_value_stable(value2)};
    int code = hm_timeseries_apply(77,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_forecast_arima(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value), hm_value_stable(value2)};
    int code = hm_timeseries_apply(78,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_forecast_var(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value), hm_value_stable(value2)};
    int code = hm_timeseries_apply(79,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_kalman_series(hmath_context *context, const hmath_value *transition, const hmath_value *observation, const hmath_value *q, const hmath_value *r, const hmath_value *initial, const hmath_value *measured, hmath_value **out) {
    if (!out || !transition || !observation || !q || !r || !initial || !measured)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(transition), hm_value_stable(observation), hm_value_stable(q), hm_value_stable(r), hm_value_stable(initial), hm_value_stable(measured)};
    int code = hm_timeseries_apply(80,arguments,6,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_ma_order(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(81,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_remainder_component(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(82,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_seasonal_ar_order(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(83,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_seasonal_component(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(84,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_seasonal_difference_order(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(85,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_seasonal_ma_order(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(86,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_seasonal_period(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(87,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_smooth_forecast(hmath_context *context, const hmath_value *method, const hmath_value *horizon, const hmath_value *xs, hmath_value **out) {
    if (!out || !method || !horizon || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(method), hm_value_stable(horizon), hm_value_stable(xs)};
    int code = hm_timeseries_apply(88,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_stl(hmath_context *context, const hmath_value *config, const hmath_value *xs, hmath_value **out) {
    if (!out || !config || !xs)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(config), hm_value_stable(xs)};
    int code = hm_timeseries_apply(89,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_stl_inner_iterations(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(90,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_stl_low_pass_window(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(91,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_stl_period(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(92,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_stl_robust_iterations(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(93,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_stl_seasonal_window(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(94,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_stl_trend_window(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(95,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_trend_component(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(96,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_var_coefficients(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(97,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_gaussian_state(hmath_context *context, const hmath_value *mean, const hmath_value *covariance, hmath_value **out) {
    if (!out || !mean || !covariance)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(mean), hm_value_stable(covariance)};
    int code = hm_timeseries_apply(98,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_state_mean(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(99,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_timeseries_state_covariance(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value)
        return hm_error(HMATH_INVALID_ARGUMENT,"NULL time-series argument");
    hmath_value *temporary = NULL;
    hmath_status status = hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[] = {hm_value_stable(value)};
    int code = hm_timeseries_apply(100,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
