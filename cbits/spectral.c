/* SPDX-License-Identifier: MPL-2.0 */
/* Generated; do not edit. */
#include "hmath_spectral.h"
#include "value_internal.h"
extern int hm_spectral_apply(int,void *const *,size_t,void **);
hmath_status hmath_signal_value_iir(hmath_context *context, const hmath_value *numerator, const hmath_value *denominator, hmath_value **out) {
    if (!out || !numerator || !denominator) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(numerator), hm_value_stable(denominator)};
    int code=hm_spectral_apply(0,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_fir(hmath_context *context, const hmath_value *b, hmath_value **out) {
    if (!out || !b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(b)};
    int code=hm_spectral_apply(1,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_filter_coefficients(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(2,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_filter_state(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(3,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_reset_filter(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(4,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_filter_signal(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_spectral_apply(5,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_frequency_response(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_spectral_apply(6,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_butterworth(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(7,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_chebyshev_i(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(8,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_chebyshev_ii(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(9,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_elliptic(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_spectral_apply(10,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_bessel(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(11,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_lowpass(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(12,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_highpass(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(13,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_bandpass(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_spectral_apply(14,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_bandstop(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_spectral_apply(15,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_design_iir(hmath_context *context, const hmath_value *family, const hmath_value *band, const hmath_value *order, const hmath_value *rate, hmath_value **out) {
    if (!out || !family || !band || !order || !rate) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(family), hm_value_stable(band), hm_value_stable(order), hm_value_stable(rate)};
    int code=hm_spectral_apply(16,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_notch(hmath_context *context, const hmath_value *omega, const hmath_value *quality, hmath_value **out) {
    if (!out || !omega || !quality) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(omega), hm_value_stable(quality)};
    int code=hm_spectral_apply(17,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_all_pass(hmath_context *context, const hmath_value *omega, const hmath_value *quality, hmath_value **out) {
    if (!out || !omega || !quality) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(omega), hm_value_stable(quality)};
    int code=hm_spectral_apply(18,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_wiener(hmath_context *context, const hmath_value *width, const hmath_value *noise, const hmath_value *xs, hmath_value **out) {
    if (!out || !width || !noise || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(width), hm_value_stable(noise), hm_value_stable(xs)};
    int code=hm_spectral_apply(19,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_hann(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(20,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_hamming(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(21,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_blackman(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(22,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_bartlett(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(23,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_kaiser(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(24,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_gaussian(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(25,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_tukey(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(26,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_flat_top(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(27,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_dolph_chebyshev(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(28,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_window(hmath_context *context, const hmath_value *kind, const hmath_value *n, hmath_value **out) {
    if (!out || !kind || !n) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(kind), hm_value_stable(n)};
    int code=hm_spectral_apply(29,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_windowed_sinc(hmath_context *context, const hmath_value *kind, const hmath_value *taps, const hmath_value *cutoff, const hmath_value *rate, hmath_value **out) {
    if (!out || !kind || !taps || !cutoff || !rate) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(kind), hm_value_stable(taps), hm_value_stable(cutoff), hm_value_stable(rate)};
    int code=hm_spectral_apply(30,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_peak(hmath_context *context, const hmath_value *peak_index, const hmath_value *peak_height, const hmath_value *peak_prominence, const hmath_value *peak_width, hmath_value **out) {
    if (!out || !peak_index || !peak_height || !peak_prominence || !peak_width) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(peak_index), hm_value_stable(peak_height), hm_value_stable(peak_prominence), hm_value_stable(peak_width)};
    int code=hm_spectral_apply(31,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_peak_index(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(32,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_peak_height(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(33,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_peak_prominence(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(34,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_peak_width(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(35,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_peaks(hmath_context *context, const hmath_value *minimum_prominence, const hmath_value *minimum_distance, const hmath_value *xs, hmath_value **out) {
    if (!out || !minimum_prominence || !minimum_distance || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(minimum_prominence), hm_value_stable(minimum_distance), hm_value_stable(xs)};
    int code=hm_spectral_apply(36,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_kalman(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, const hmath_value *value6, hmath_value **out) {
    if (!out || !value || !value2 || !value3 || !value4 || !value5 || !value6) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3), hm_value_stable(value4), hm_value_stable(value5), hm_value_stable(value6)};
    int code=hm_spectral_apply(37,arguments,6,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_extended_kalman(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, const hmath_value *value6, hmath_value **out) {
    if (!out || !value || !value2 || !value3 || !value4 || !value5 || !value6) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3), hm_value_stable(value4), hm_value_stable(value5), hm_value_stable(value6)};
    int code=hm_spectral_apply(38,arguments,6,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_unscented_kalman(hmath_context *context, const hmath_value *alpha, const hmath_value *beta, const hmath_value *kappa, const hmath_value *transition, const hmath_value *measurement, const hmath_value *q, const hmath_value *r, const hmath_value *measured, const hmath_value *state, hmath_value **out) {
    if (!out || !alpha || !beta || !kappa || !transition || !measurement || !q || !r || !measured || !state) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(alpha), hm_value_stable(beta), hm_value_stable(kappa), hm_value_stable(transition), hm_value_stable(measurement), hm_value_stable(q), hm_value_stable(r), hm_value_stable(measured), hm_value_stable(state)};
    int code=hm_spectral_apply(39,arguments,9,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_haar(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(40,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_daubechies2(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(41,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_daubechies4(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(42,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_biorthogonal53(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(43,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_wavelet_approximation(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(44,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_wavelet_details(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(45,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_dwt(hmath_context *context, const hmath_value *family, const hmath_value *levels, const hmath_value *xs, hmath_value **out) {
    if (!out || !family || !levels || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(family), hm_value_stable(levels), hm_value_stable(xs)};
    int code=hm_spectral_apply(46,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_idwt(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(47,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_morlet(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(48,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_mexican_hat(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(49,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_gaussian_derivative(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(50,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_cwt(hmath_context *context, const hmath_value *mother, const hmath_value *spacing, const hmath_value *scales, const hmath_value *xs, hmath_value **out) {
    if (!out || !mother || !spacing || !scales || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(mother), hm_value_stable(spacing), hm_value_stable(scales), hm_value_stable(xs)};
    int code=hm_spectral_apply(51,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_wavelet_packets(hmath_context *context, const hmath_value *family, const hmath_value *levels, const hmath_value *xs, hmath_value **out) {
    if (!out || !family || !levels || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(family), hm_value_stable(levels), hm_value_stable(xs)};
    int code=hm_spectral_apply(52,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_inverse_wavelet_packets(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(53,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_packet_bands(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(54,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_signal_value_wavelet_denoise(hmath_context *context, const hmath_value *family, const hmath_value *levels, const hmath_value *threshold, const hmath_value *xs, hmath_value **out) {
    if (!out || !family || !levels || !threshold || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(family), hm_value_stable(levels), hm_value_stable(threshold), hm_value_stable(xs)};
    int code=hm_spectral_apply(55,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_reject(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(56,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_clamp(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(57,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_extrapolate(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(58,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_nearest(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(59,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_linear(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(60,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_lagrange(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(61,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_newton(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(62,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_barycentric(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(63,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_natural(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(64,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_clamped(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_spectral_apply(65,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_periodic(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(66,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_gaussian(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(67,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_multiquadric(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(68,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_inverse_multiquadric(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(69,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_thin_plate(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(70,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_cubic(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(71,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_approximation(hmath_context *context, const hmath_value *approximation_coefficients, const hmath_value *approximation_error, const hmath_value *approximation_iterations, hmath_value **out) {
    if (!out || !approximation_coefficients || !approximation_error || !approximation_iterations) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(approximation_coefficients), hm_value_stable(approximation_error), hm_value_stable(approximation_iterations)};
    int code=hm_spectral_apply(72,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_approximation_coefficients(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(73,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_approximation_error(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(74,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_approximation_iterations(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(75,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_interpolate(hmath_context *context, const hmath_value *method, const hmath_value *policy, const hmath_value *points, const hmath_value *x0, hmath_value **out) {
    if (!out || !method || !policy || !points || !x0) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(method), hm_value_stable(policy), hm_value_stable(points), hm_value_stable(x0)};
    int code=hm_spectral_apply(76,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_hermite(hmath_context *context, const hmath_value *triples, const hmath_value *x, hmath_value **out) {
    if (!out || !triples || !x) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(triples), hm_value_stable(x)};
    int code=hm_spectral_apply(77,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_piecewise_polynomial(hmath_context *context, const hmath_value *knots, const hmath_value *coefficients, hmath_value **out) {
    if (!out || !knots || !coefficients) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(knots), hm_value_stable(coefficients)};
    int code=hm_spectral_apply(78,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_piecewise_knots(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(79,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_evaluate_piecewise(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out) {
    if (!out || !value || !value2 || !value3) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3)};
    int code=hm_spectral_apply(80,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_differentiate_piecewise(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(81,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_integrate_piecewise(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out) {
    if (!out || !value || !value2 || !value3) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3)};
    int code=hm_spectral_apply(82,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_cubic_hermite(hmath_context *context, const hmath_value *triples, hmath_value **out) {
    if (!out || !triples) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(triples)};
    int code=hm_spectral_apply(83,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_cubic_spline(hmath_context *context, const hmath_value *boundary, const hmath_value *points, hmath_value **out) {
    if (!out || !boundary || !points) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(boundary), hm_value_stable(points)};
    int code=hm_spectral_apply(84,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_pchip(hmath_context *context, const hmath_value *points, hmath_value **out) {
    if (!out || !points) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(points)};
    int code=hm_spectral_apply(85,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_akima(hmath_context *context, const hmath_value *points, hmath_value **out) {
    if (!out || !points) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(points)};
    int code=hm_spectral_apply(86,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_smoothing_spline(hmath_context *context, const hmath_value *lambda_, const hmath_value *points, hmath_value **out) {
    if (!out || !lambda_ || !points) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(lambda_), hm_value_stable(points)};
    int code=hm_spectral_apply(87,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_b_spline(hmath_context *context, const hmath_value *degree, const hmath_value *knots, const hmath_value *controls, const hmath_value *weights, hmath_value **out) {
    if (!out || !degree || !knots || !controls || !weights) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(degree), hm_value_stable(knots), hm_value_stable(controls), hm_value_stable(weights)};
    int code=hm_spectral_apply(88,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_evaluate_b_spline(hmath_context *context, const hmath_value *s, const hmath_value *x, hmath_value **out) {
    if (!out || !s || !x) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(s), hm_value_stable(x)};
    int code=hm_spectral_apply(89,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_derivative_b_spline(hmath_context *context, const hmath_value *s, const hmath_value *x, hmath_value **out) {
    if (!out || !s || !x) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(s), hm_value_stable(x)};
    int code=hm_spectral_apply(90,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_insert_knot(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_spectral_apply(91,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_rational_bezier(hmath_context *context, const hmath_value *controls, const hmath_value *ws, const hmath_value *t, hmath_value **out) {
    if (!out || !controls || !ws || !t) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(controls), hm_value_stable(ws), hm_value_stable(t)};
    int code=hm_spectral_apply(92,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_bezier(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_spectral_apply(93,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_kochanek_bartels(hmath_context *context, const hmath_value *tension, const hmath_value *continuity, const hmath_value *bias, const hmath_value *points, hmath_value **out) {
    if (!out || !tension || !continuity || !bias || !points) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(tension), hm_value_stable(continuity), hm_value_stable(bias), hm_value_stable(points)};
    int code=hm_spectral_apply(94,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_cardinal_spline(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_spectral_apply(95,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_catmull_rom(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(96,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_curve_integral(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, hmath_value **out) {
    if (!out || !value || !value2 || !value3 || !value4) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3), hm_value_stable(value4)};
    int code=hm_spectral_apply(97,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_arc_length(hmath_context *context, const hmath_value *tolerance, const hmath_value *spline, const hmath_value *a, const hmath_value *b, hmath_value **out) {
    if (!out || !tolerance || !spline || !a || !b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(tolerance), hm_value_stable(spline), hm_value_stable(a), hm_value_stable(b)};
    int code=hm_spectral_apply(98,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_grid_interpolate(hmath_context *context, const hmath_value *method, const hmath_value *policy, const hmath_value *axes, const hmath_value *values, const hmath_value *point, hmath_value **out) {
    if (!out || !method || !policy || !axes || !values || !point) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(method), hm_value_stable(policy), hm_value_stable(axes), hm_value_stable(values), hm_value_stable(point)};
    int code=hm_spectral_apply(99,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_fit_rbf(hmath_context *context, const hmath_value *method, const hmath_value *smoothing, const hmath_value *nodes, const hmath_value *ys, hmath_value **out) {
    if (!out || !method || !smoothing || !nodes || !ys) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(method), hm_value_stable(smoothing), hm_value_stable(nodes), hm_value_stable(ys)};
    int code=hm_spectral_apply(100,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_evaluate_rbf(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_spectral_apply(101,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_inverse_distance(hmath_context *context, const hmath_value *power, const hmath_value *nodes, const hmath_value *ys, const hmath_value *point, hmath_value **out) {
    if (!out || !power || !nodes || !ys || !point) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(power), hm_value_stable(nodes), hm_value_stable(ys), hm_value_stable(point)};
    int code=hm_spectral_apply(102,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_shepard(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out) {
    if (!out || !value || !value2 || !value3) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2), hm_value_stable(value3)};
    int code=hm_spectral_apply(103,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_kriging(hmath_context *context, const hmath_value *range, const hmath_value *nugget, const hmath_value *nodes, const hmath_value *ys, const hmath_value *point, hmath_value **out) {
    if (!out || !range || !nugget || !nodes || !ys || !point) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(range), hm_value_stable(nugget), hm_value_stable(nodes), hm_value_stable(ys), hm_value_stable(point)};
    int code=hm_spectral_apply(104,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_polynomial_fit(hmath_context *context, const hmath_value *degree, const hmath_value *points, hmath_value **out) {
    if (!out || !degree || !points) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(degree), hm_value_stable(points)};
    int code=hm_spectral_apply(105,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_chebyshev_approximate(hmath_context *context, const hmath_value *degree, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out) {
    if (!out || !degree || !f || !a || !b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(degree), hm_value_stable(f), hm_value_stable(a), hm_value_stable(b)};
    int code=hm_spectral_apply(106,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_pade(hmath_context *context, const hmath_value *m, const hmath_value *n, const hmath_value *series, hmath_value **out) {
    if (!out || !m || !n || !series) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(m), hm_value_stable(n), hm_value_stable(series)};
    int code=hm_spectral_apply(107,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_rational_fit(hmath_context *context, const hmath_value *m, const hmath_value *n, const hmath_value *points, hmath_value **out) {
    if (!out || !m || !n || !points) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(m), hm_value_stable(n), hm_value_stable(points)};
    int code=hm_spectral_apply(108,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_remez(hmath_context *context, const hmath_value *degree, const hmath_value *grid_count, const hmath_value *tolerance, const hmath_value *budget, const hmath_value *f, const hmath_value *a, const hmath_value *b, hmath_value **out) {
    if (!out || !degree || !grid_count || !tolerance || !budget || !f || !a || !b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(degree), hm_value_stable(grid_count), hm_value_stable(tolerance), hm_value_stable(budget), hm_value_stable(f), hm_value_stable(a), hm_value_stable(b)};
    int code=hm_spectral_apply(109,arguments,7,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_nonlinear_fit(hmath_context *context, const hmath_value *budget, const hmath_value *tolerance, const hmath_value *model, const hmath_value *points, const hmath_value *initial, hmath_value **out) {
    if (!out || !budget || !tolerance || !model || !points || !initial) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(budget), hm_value_stable(tolerance), hm_value_stable(model), hm_value_stable(points), hm_value_stable(initial)};
    int code=hm_spectral_apply(110,arguments,5,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_interpolation_value_interpolation_error(hmath_context *context, const hmath_value *f, const hmath_value *points, hmath_value **out) {
    if (!out || !f || !points) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(f), hm_value_stable(points)};
    int code=hm_spectral_apply(111,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_forward(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(112,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_inverse(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(113,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_automatic(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(114,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_direct(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(115,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_radix2(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(116,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_radix4(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(117,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_mixed_radix(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(118,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_split_radix(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(119,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_bluestein(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(120,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_rader(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(121,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_type_i(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(122,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_type_ii(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(123,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_type_iii(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(124,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_type_iv(hmath_context *context, hmath_value **out) {
    if (!out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={NULL};
    int code=hm_spectral_apply(125,arguments,0,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_plan_fft(hmath_context *context, const hmath_value *direction, const hmath_value *method, const hmath_value *n, hmath_value **out) {
    if (!out || !direction || !method || !n) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(direction), hm_value_stable(method), hm_value_stable(n)};
    int code=hm_spectral_apply(126,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_execute_fft(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_spectral_apply(127,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_fft(hmath_context *context, const hmath_value *xs, hmath_value **out) {
    if (!out || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(xs)};
    int code=hm_spectral_apply(128,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_ifft(hmath_context *context, const hmath_value *xs, hmath_value **out) {
    if (!out || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(xs)};
    int code=hm_spectral_apply(129,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_dft(hmath_context *context, const hmath_value *xs, hmath_value **out) {
    if (!out || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(xs)};
    int code=hm_spectral_apply(130,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_real_fft(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(131,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_inverse_real_fft(hmath_context *context, const hmath_value *tolerance, const hmath_value *xs, hmath_value **out) {
    if (!out || !tolerance || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(tolerance), hm_value_stable(xs)};
    int code=hm_spectral_apply(132,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_fft_batch(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_spectral_apply(133,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_fft_nd(hmath_context *context, const hmath_value *direction, const hmath_value *dims, const hmath_value *xs, hmath_value **out) {
    if (!out || !direction || !dims || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(direction), hm_value_stable(dims), hm_value_stable(xs)};
    int code=hm_spectral_apply(134,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_dct(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_spectral_apply(135,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_idct(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_spectral_apply(136,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_dst(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_spectral_apply(137,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_idst(hmath_context *context, const hmath_value *value, const hmath_value *value2, hmath_value **out) {
    if (!out || !value || !value2) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value), hm_value_stable(value2)};
    int code=hm_spectral_apply(138,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_stft_frames(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(139,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_stft(hmath_context *context, const hmath_value *window, const hmath_value *hop, const hmath_value *xs, hmath_value **out) {
    if (!out || !window || !hop || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(window), hm_value_stable(hop), hm_value_stable(xs)};
    int code=hm_spectral_apply(140,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_istft(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(141,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_magnitude_spectrum(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(142,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_phase_spectrum(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(143,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_power_spectrum(hmath_context *context, const hmath_value *value, hmath_value **out) {
    if (!out || !value) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(value)};
    int code=hm_spectral_apply(144,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_cross_spectrum(hmath_context *context, const hmath_value *rate, const hmath_value *window, const hmath_value *x, const hmath_value *y, hmath_value **out) {
    if (!out || !rate || !window || !x || !y) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(rate), hm_value_stable(window), hm_value_stable(x), hm_value_stable(y)};
    int code=hm_spectral_apply(145,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_spectrogram(hmath_context *context, const hmath_value *w, const hmath_value *h, const hmath_value *xs, hmath_value **out) {
    if (!out || !w || !h || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(w), hm_value_stable(h), hm_value_stable(xs)};
    int code=hm_spectral_apply(146,arguments,3,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_analytic_signal(hmath_context *context, const hmath_value *xs, hmath_value **out) {
    if (!out || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(xs)};
    int code=hm_spectral_apply(147,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_chirp_z(hmath_context *context, const hmath_value *count, const hmath_value *a, const hmath_value *w, const hmath_value *xs, hmath_value **out) {
    if (!out || !count || !a || !w || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(count), hm_value_stable(a), hm_value_stable(w), hm_value_stable(xs)};
    int code=hm_spectral_apply(148,arguments,4,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_goertzel(hmath_context *context, const hmath_value *omega, const hmath_value *xs, hmath_value **out) {
    if (!out || !omega || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(omega), hm_value_stable(xs)};
    int code=hm_spectral_apply(149,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_fft_convolve(hmath_context *context, const hmath_value *a, const hmath_value *b, hmath_value **out) {
    if (!out || !a || !b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(a), hm_value_stable(b)};
    int code=hm_spectral_apply(150,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_fft_correlate(hmath_context *context, const hmath_value *a, const hmath_value *b, hmath_value **out) {
    if (!out || !a || !b) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(a), hm_value_stable(b)};
    int code=hm_spectral_apply(151,arguments,2,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_fft_shift(hmath_context *context, const hmath_value *xs, hmath_value **out) {
    if (!out || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(xs)};
    int code=hm_spectral_apply(152,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}
hmath_status hmath_fourier_value_ifft_shift(hmath_context *context, const hmath_value *xs, hmath_value **out) {
    if (!out || !xs) return hm_error(HMATH_INVALID_ARGUMENT,"NULL numerical argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if (status) return status;
    void *arguments[]={hm_value_stable(xs)};
    int code=hm_spectral_apply(153,arguments,1,&temporary->stable);
    return hm_value_finish(temporary,code,out);
}

extern int hm_spectral_fft_in_place(void *,void *,ptrdiff_t);
hmath_status hmath_fourier_value_fft_in_place(hmath_context *context,const hmath_value *plan,double *interleaved,ptrdiff_t count) {
    if (!plan) return hm_error(HMATH_INVALID_ARGUMENT,"NULL FFT plan");
    hmath_status status=hm_enter(context);
    if(status)return status;
    int code=hm_spectral_fft_in_place(hm_value_stable(plan),interleaved,count);
    hm_leave();
    return (hmath_status)code;
}

extern int hm_spectral_describe(void *,void **);
hmath_status hmath_spectral_describe(hmath_context *context,const hmath_value *value,hmath_value **out) {
    if (!value || !out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL spectral description argument");
    hmath_value *temporary=NULL;
    hmath_status status=hm_value_begin(context,&temporary);
    if(status)return status;
    return hm_value_finish(temporary,hm_spectral_describe(hm_value_stable(value),&temporary->stable),out);
}
