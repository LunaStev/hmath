{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE FlexibleInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}
-- SPDX-License-Identifier: MPL-2.0
-- Generated representation adapters; all mathematics remains in original modules.
module HMath.FFI.TimeSeries where
import Foreign
import Foreign.C
import HMath.FFI.Boundary
import HMath.FFI.Value
import HMath.FFI.GraphCodec (Wire(..),boxed,unboxed)
import qualified HMath.TimeSeries as T
import qualified HMath.Signal as S
import qualified HMath.Optimization.Common as O
instance Wire O.OptimizeOptions where
    wire = boxed 20
    unwire = unboxed 20
instance Wire T.Series where
    wire = boxed 120
    unwire = unboxed 120
instance Wire T.Alignment where
    wire = boxed 121
    unwire = unboxed 121
instance Wire T.Fill where
    wire = boxed 122
    unwire = unboxed 122
instance Wire T.Resampling where
    wire = boxed 123
    unwire = unboxed 123
instance Wire T.Rolling where
    wire = boxed 124
    unwire = unboxed 124
instance Wire T.DTWResult where
    wire = boxed 125
    unwire = unboxed 125
instance Wire T.Deterministic where
    wire = boxed 126
    unwire = unboxed 126
instance Wire T.ForecastMetric where
    wire = boxed 127
    unwire = unboxed 127
instance Wire T.Stationarity where
    wire = boxed 128
    unwire = unboxed 128
instance Wire T.ARIMAModel where
    wire = boxed 129
    unwire = unboxed 129
instance Wire T.ARModel where
    wire = boxed 130
    unwire = unboxed 130
instance Wire T.Decomposition where
    wire = boxed 131
    unwire = unboxed 131
instance Wire T.SARIMAOrder where
    wire = boxed 132
    unwire = unboxed 132
instance Wire T.STLConfig where
    wire = boxed 133
    unwire = unboxed 133
instance Wire T.Smoothing where
    wire = boxed 134
    unwire = unboxed 134
instance Wire T.VARModel where
    wire = boxed 135
    unwire = unboxed 135
instance Wire S.GaussianState where
    wire = boxed 140
    unwire = unboxed 140
foreign export ccall "hm_timeseries_describe" describe :: StablePtr Value -> Ptr (StablePtr Value) -> IO CInt
describe :: StablePtr Value -> Ptr (StablePtr Value) -> IO CInt
describe input out = boundary $ do
    value <- deRefStablePtr input
    text <- case value of
        Opaque 120 _ _ _ _ -> show <$> (unwire value :: IO T.Series)
        Opaque 121 _ _ _ _ -> show <$> (unwire value :: IO T.Alignment)
        Opaque 122 _ _ _ _ -> show <$> (unwire value :: IO T.Fill)
        Opaque 123 _ _ _ _ -> show <$> (unwire value :: IO T.Resampling)
        Opaque 124 _ _ _ _ -> show <$> (unwire value :: IO T.Rolling)
        Opaque 125 _ _ _ _ -> show <$> (unwire value :: IO T.DTWResult)
        Opaque 126 _ _ _ _ -> show <$> (unwire value :: IO T.Deterministic)
        Opaque 127 _ _ _ _ -> show <$> (unwire value :: IO T.ForecastMetric)
        Opaque 128 _ _ _ _ -> show <$> (unwire value :: IO T.Stationarity)
        Opaque 129 _ _ _ _ -> show <$> (unwire value :: IO T.ARIMAModel)
        Opaque 130 _ _ _ _ -> show <$> (unwire value :: IO T.ARModel)
        Opaque 131 _ _ _ _ -> show <$> (unwire value :: IO T.Decomposition)
        Opaque 132 _ _ _ _ -> show <$> (unwire value :: IO T.SARIMAOrder)
        Opaque 133 _ _ _ _ -> show <$> (unwire value :: IO T.STLConfig)
        Opaque 134 _ _ _ _ -> show <$> (unwire value :: IO T.Smoothing)
        Opaque 135 _ _ _ _ -> show <$> (unwire value :: IO T.VARModel)
        Opaque 140 _ _ _ _ -> show <$> (unwire value :: IO S.GaussianState)
        _ -> invalid "expected a time-series domain object"
    publish (Text text) out
    pure 0
foreign export ccall "hm_timeseries_apply" apply :: CInt -> Ptr (StablePtr Value) -> CSize -> Ptr (StablePtr Value) -> IO CInt
apply :: CInt -> Ptr (StablePtr Value) -> CSize -> Ptr (StablePtr Value) -> IO CInt
apply operation input arity out = boundary $ do
    values <- peekArray (fromIntegral arity) input >>= mapM deRefStablePtr
    case (operation,values) of
        (0,[]) -> do
            checked (Right (T.BackwardFill)) (\result_value -> publish (wire result_value) out)
        (1,[]) -> do
            checked (Right (T.BinLast)) (\result_value -> publish (wire result_value) out)
        (2,[]) -> do
            checked (Right (T.BinMean)) (\result_value -> publish (wire result_value) out)
        (3,[]) -> do
            checked (Right (T.ForwardFill)) (\result_value -> publish (wire result_value) out)
        (4,[]) -> do
            checked (Right (T.Inner)) (\result_value -> publish (wire result_value) out)
        (5,[]) -> do
            checked (Right (T.LeftAligned)) (\result_value -> publish (wire result_value) out)
        (6,[]) -> do
            checked (Right (T.LinearFill)) (\result_value -> publish (wire result_value) out)
        (7,[]) -> do
            checked (Right (T.LinearSamples)) (\result_value -> publish (wire result_value) out)
        (8,[]) -> do
            checked (Right (T.MovingMaximum)) (\result_value -> publish (wire result_value) out)
        (9,[]) -> do
            checked (Right (T.MovingMean)) (\result_value -> publish (wire result_value) out)
        (10,[]) -> do
            checked (Right (T.MovingMinimum)) (\result_value -> publish (wire result_value) out)
        (11,[]) -> do
            checked (Right (T.MovingSD)) (\result_value -> publish (wire result_value) out)
        (12,[]) -> do
            checked (Right (T.MovingVariance)) (\result_value -> publish (wire result_value) out)
        (13,[]) -> do
            checked (Right (T.Outer)) (\result_value -> publish (wire result_value) out)
        (14,[vvalue,vvalue2,vvalue3]) -> do
            value <- unwire vvalue
            value2 <- unwire vvalue2
            value3 <- unwire vvalue3
            checked (T.align value value2 value3) (\result_value -> publish (wire result_value) out)
        (15,[vlags,vxs]) -> do
            lags <- unwire vlags
            xs <- unwire vxs
            checked (T.autocorrelation lags xs) (\result_value -> publish (wire result_value) out)
        (16,[vlag,vxs,vys]) -> do
            lag <- unwire vlag
            xs <- unwire vxs
            ys <- unwire vys
            checked (T.crossCorrelation lag xs ys) (\result_value -> publish (wire result_value) out)
        (17,[vxs]) -> do
            xs <- unwire vxs
            checked (T.cumulativeReturns xs) (\result_value -> publish (wire result_value) out)
        (18,[vorder,vlag,vxs]) -> do
            order <- unwire vorder
            lag <- unwire vlag
            xs <- unwire vxs
            checked (T.difference order lag xs) (\result_value -> publish (wire result_value) out)
        (19,[vcovariance]) -> do
            covariance <- unwire vcovariance
            checked (T.durbinLevinson covariance) (\result_value -> publish (wire result_value) out)
        (20,[valpha,vxs]) -> do
            alpha <- unwire valpha
            xs <- unwire vxs
            checked (T.exponentialAverage alpha xs) (\result_value -> publish (wire result_value) out)
        (21,[vvalue,vvalue2]) -> do
            value <- unwire vvalue
            value2 <- unwire vvalue2
            checked (T.fillMissing value value2) (\result_value -> publish (wire result_value) out)
        (22,[vvalue,vvalue2]) -> do
            value <- unwire vvalue
            value2 <- unwire vvalue2
            checked (T.isRegular value value2) (\result_value -> publish (wire result_value) out)
        (23,[vxs]) -> do
            xs <- unwire vxs
            checked (T.logarithmicReturns xs) (\result_value -> publish (wire result_value) out)
        (24,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.observations value)) (\result_value -> publish (wire result_value) out)
        (25,[vorder,vxs]) -> do
            order <- unwire vorder
            xs <- unwire vxs
            checked (T.partialAutocorrelation order xs) (\result_value -> publish (wire result_value) out)
        (26,[vstart,vstep,vxs]) -> do
            start <- unwire vstart
            step <- unwire vstep
            xs <- unwire vxs
            checked (T.regularSeries start step xs) (\result_value -> publish (wire result_value) out)
        (27,[vvalue,vvalue2,vvalue3,vvalue4,vvalue5]) -> do
            value <- unwire vvalue
            value2 <- unwire vvalue2
            value3 <- unwire vvalue3
            value4 <- unwire vvalue4
            value5 <- unwire vvalue5
            checked (T.resample value value2 value3 value4 value5) (\result_value -> publish (wire result_value) out)
        (28,[vmethod,vwidth,vxs]) -> do
            method <- unwire vmethod
            width <- unwire vwidth
            xs <- unwire vxs
            checked (T.rolling method width xs) (\result_value -> publish (wire result_value) out)
        (29,[vxs]) -> do
            xs <- unwire vxs
            checked (T.series xs) (\result_value -> publish (wire result_value) out)
        (30,[vvalue]) -> do
            value <- unwire vvalue
            checked (T.seriesValues value) (\result_value -> publish (wire result_value) out)
        (31,[vws,vxs]) -> do
            ws <- unwire vws
            xs <- unwire vxs
            checked (T.weightedAverage ws xs) (\result_value -> publish (wire result_value) out)
        (32,[vorder,vxs]) -> do
            order <- unwire vorder
            xs <- unwire vxs
            checked (T.yuleWalker order xs) (\result_value -> publish (wire result_value) out)
        (33,[vdistance,vpath]) -> do
            distance <- unwire vdistance
            path <- unwire vpath
            checked (Right (T.DTWResult distance path)) (\result_value -> publish (wire result_value) out)
        (34,[]) -> do
            checked (Right (T.Level)) (\result_value -> publish (wire result_value) out)
        (35,[]) -> do
            checked (Right (T.LinearTrend)) (\result_value -> publish (wire result_value) out)
        (36,[]) -> do
            checked (Right (T.MAE)) (\result_value -> publish (wire result_value) out)
        (37,[]) -> do
            checked (Right (T.MAPE)) (\result_value -> publish (wire result_value) out)
        (38,[vperiod,vtraining]) -> do
            period <- unwire vperiod
            training <- unwire vtraining
            checked (Right (T.MASE period training)) (\result_value -> publish (wire result_value) out)
        (39,[]) -> do
            checked (Right (T.MSE)) (\result_value -> publish (wire result_value) out)
        (40,[]) -> do
            checked (Right (T.RMSE)) (\result_value -> publish (wire result_value) out)
        (41,[]) -> do
            checked (Right (T.SMAPE)) (\result_value -> publish (wire result_value) out)
        (42,[vstatistic,vcritical_values,vobservations,vnull_hypothesis]) -> do
            statistic <- unwire vstatistic
            critical_values <- unwire vcritical_values
            observations <- unwire vobservations
            null_hypothesis <- unwire vnull_hypothesis
            checked (Right (T.Stationarity statistic critical_values observations null_hypothesis)) (\result_value -> publish (wire result_value) out)
        (43,[vthreshold,vxs]) -> do
            threshold <- unwire vthreshold
            xs <- unwire vxs
            checked (T.anomalies threshold xs) (\result_value -> publish (wire result_value) out)
        (44,[vdeterministic,vlags,vxs]) -> do
            deterministic <- unwire vdeterministic
            lags <- unwire vlags
            xs <- unwire vxs
            checked (T.augmentedDickeyFuller deterministic lags xs) (\result_value -> publish (wire result_value) out)
        (45,[vpenalty,vmin_segment,vxs]) -> do
            penalty <- unwire vpenalty
            min_segment <- unwire vmin_segment
            xs <- unwire vxs
            checked (T.changePoints penalty min_segment xs) (\result_value -> publish (wire result_value) out)
        (46,[vmean,vsd,vdrift,vthreshold,vxs]) -> do
            mean <- unwire vmean
            sd <- unwire vsd
            drift <- unwire vdrift
            threshold <- unwire vthreshold
            xs <- unwire vxs
            checked (T.cusum mean sd drift threshold xs) (\result_value -> publish (wire result_value) out)
        (47,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.dtwDistance value)) (\result_value -> publish (wire result_value) out)
        (48,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.dtwPath value)) (\result_value -> publish (wire result_value) out)
        (49,[vradius,vxs,vys]) -> do
            radius <- unwire vradius
            xs <- unwire vxs
            ys <- unwire vys
            checked (T.dynamicTimeWarping radius xs ys) (\result_value -> publish (wire result_value) out)
        (50,[vmetric,vactual,vpredicted]) -> do
            metric <- unwire vmetric
            actual <- unwire vactual
            predicted <- unwire vpredicted
            checked (T.forecastError metric actual predicted) (\result_value -> publish (wire result_value) out)
        (51,[vdeterministic,vlags,vxs]) -> do
            deterministic <- unwire vdeterministic
            lags <- unwire vlags
            xs <- unwire vxs
            checked (T.kpss deterministic lags xs) (\result_value -> publish (wire result_value) out)
        (52,[vsample_rate,vxs]) -> do
            sample_rate <- unwire vsample_rate
            xs <- unwire vxs
            checked (T.spectrum sample_rate xs) (\result_value -> publish (wire result_value) out)
        (53,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.stationarityCriticalValues value)) (\result_value -> publish (wire result_value) out)
        (54,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.stationarityNull value)) (\result_value -> publish (wire result_value) out)
        (55,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.stationarityObservations value)) (\result_value -> publish (wire result_value) out)
        (56,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.stationarityStatistic value)) (\result_value -> publish (wire result_value) out)
        (57,[vtrend,vseasonal,vremainder]) -> do
            trend <- unwire vtrend
            seasonal <- unwire vseasonal
            remainder <- unwire vremainder
            checked (Right (T.Decomposition trend seasonal remainder)) (\result_value -> publish (wire result_value) out)
        (58,[valpha,vbeta]) -> do
            alpha <- unwire valpha
            beta <- unwire vbeta
            checked (Right (T.Holt alpha beta)) (\result_value -> publish (wire result_value) out)
        (59,[vperiod,valpha,vbeta,vgamma]) -> do
            period <- unwire vperiod
            alpha <- unwire valpha
            beta <- unwire vbeta
            gamma <- unwire vgamma
            checked (Right (T.HoltWinters period alpha beta gamma)) (\result_value -> publish (wire result_value) out)
        (60,[var,vdifference,vma,vseasonal_ar,vseasonal_difference,vseasonal_ma,vperiod]) -> do
            ar <- unwire var
            difference <- unwire vdifference
            ma <- unwire vma
            seasonal_ar <- unwire vseasonal_ar
            seasonal_difference <- unwire vseasonal_difference
            seasonal_ma <- unwire vseasonal_ma
            period <- unwire vperiod
            checked (Right (T.SARIMAOrder ar difference ma seasonal_ar seasonal_difference seasonal_ma period)) (\result_value -> publish (wire result_value) out)
        (61,[vperiod,vseasonal_window,vtrend_window,vlow_pass_window,vinner_iterations,vrobust_iterations]) -> do
            period <- unwire vperiod
            seasonal_window <- unwire vseasonal_window
            trend_window <- unwire vtrend_window
            low_pass_window <- unwire vlow_pass_window
            inner_iterations <- unwire vinner_iterations
            robust_iterations <- unwire vrobust_iterations
            checked (Right (T.STLConfig period seasonal_window trend_window low_pass_window inner_iterations robust_iterations)) (\result_value -> publish (wire result_value) out)
        (62,[valpha]) -> do
            alpha <- unwire valpha
            checked (Right (T.Simple alpha)) (\result_value -> publish (wire result_value) out)
        (63,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.arCoefficients value)) (\result_value -> publish (wire result_value) out)
        (64,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.arOrder value)) (\result_value -> publish (wire result_value) out)
        (65,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.arimaInnovationVariance value)) (\result_value -> publish (wire result_value) out)
        (66,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.arimaParameters value)) (\result_value -> publish (wire result_value) out)
        (67,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.arimaResiduals value)) (\result_value -> publish (wire result_value) out)
        (68,[vperiod,vxs]) -> do
            period <- unwire vperiod
            xs <- unwire vxs
            checked (T.decompose period xs) (\result_value -> publish (wire result_value) out)
        (69,[vperiod]) -> do
            period <- unwire vperiod
            checked (Right (T.defaultSTLConfig period)) (\result_value -> publish (wire result_value) out)
        (70,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.differenceOrder value)) (\result_value -> publish (wire result_value) out)
        (71,[vorder,vxs]) -> do
            order <- unwire vorder
            xs <- unwire vxs
            checked (T.fitAR order xs) (\result_value -> publish (wire result_value) out)
        (72,[vvalue,vvalue2,vvalue3,vvalue4,vvalue5]) -> do
            value <- unwire vvalue
            value2 <- unwire vvalue2
            value3 <- unwire vvalue3
            value4 <- unwire vvalue4
            value5 <- unwire vvalue5
            checked (T.fitARIMA value value2 value3 value4 value5) (\result_value -> publish (wire result_value) out)
        (73,[vvalue,vvalue2,vvalue3,vvalue4]) -> do
            value <- unwire vvalue
            value2 <- unwire vvalue2
            value3 <- unwire vvalue3
            value4 <- unwire vvalue4
            checked (T.fitARMA value value2 value3 value4) (\result_value -> publish (wire result_value) out)
        (74,[vvalue,vvalue2,vvalue3]) -> do
            value <- unwire vvalue
            value2 <- unwire vvalue2
            value3 <- unwire vvalue3
            checked (T.fitMA value value2 value3) (\result_value -> publish (wire result_value) out)
        (75,[voptions,vorder,vxs]) -> do
            options <- unwire voptions
            order <- unwire vorder
            xs <- unwire vxs
            checked (T.fitSARIMA options order xs) (\result_value -> publish (wire result_value) out)
        (76,[vorder,vxs]) -> do
            order <- unwire vorder
            xs <- unwire vxs
            checked (T.fitVAR order xs) (\result_value -> publish (wire result_value) out)
        (77,[vvalue,vvalue2]) -> do
            value <- unwire vvalue
            value2 <- unwire vvalue2
            checked (T.forecastAR value value2) (\result_value -> publish (wire result_value) out)
        (78,[vvalue,vvalue2]) -> do
            value <- unwire vvalue
            value2 <- unwire vvalue2
            checked (T.forecastARIMA value value2) (\result_value -> publish (wire result_value) out)
        (79,[vvalue,vvalue2]) -> do
            value <- unwire vvalue
            value2 <- unwire vvalue2
            checked (T.forecastVAR value value2) (\result_value -> publish (wire result_value) out)
        (80,[vtransition,vobservation,vq,vr,vinitial,vmeasured]) -> do
            transition <- unwire vtransition
            observation <- unwire vobservation
            q <- unwire vq
            r <- unwire vr
            initial <- unwire vinitial
            measured <- unwire vmeasured
            checked (T.kalmanSeries transition observation q r initial measured) (\result_value -> publish (wire result_value) out)
        (81,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.maOrder value)) (\result_value -> publish (wire result_value) out)
        (82,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.remainderComponent value)) (\result_value -> publish (wire result_value) out)
        (83,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.seasonalAROrder value)) (\result_value -> publish (wire result_value) out)
        (84,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.seasonalComponent value)) (\result_value -> publish (wire result_value) out)
        (85,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.seasonalDifferenceOrder value)) (\result_value -> publish (wire result_value) out)
        (86,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.seasonalMAOrder value)) (\result_value -> publish (wire result_value) out)
        (87,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.seasonalPeriod value)) (\result_value -> publish (wire result_value) out)
        (88,[vmethod,vhorizon,vxs]) -> do
            method <- unwire vmethod
            horizon <- unwire vhorizon
            xs <- unwire vxs
            checked (T.smoothForecast method horizon xs) (\result_value -> publish (wire result_value) out)
        (89,[vconfig,vxs]) -> do
            config <- unwire vconfig
            xs <- unwire vxs
            checked (T.stl config xs) (\result_value -> publish (wire result_value) out)
        (90,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.stlInnerIterations value)) (\result_value -> publish (wire result_value) out)
        (91,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.stlLowPassWindow value)) (\result_value -> publish (wire result_value) out)
        (92,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.stlPeriod value)) (\result_value -> publish (wire result_value) out)
        (93,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.stlRobustIterations value)) (\result_value -> publish (wire result_value) out)
        (94,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.stlSeasonalWindow value)) (\result_value -> publish (wire result_value) out)
        (95,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.stlTrendWindow value)) (\result_value -> publish (wire result_value) out)
        (96,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.trendComponent value)) (\result_value -> publish (wire result_value) out)
        (97,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (T.varCoefficients value)) (\result_value -> publish (wire result_value) out)
        (98,[vmean,vcovariance]) -> do
            mean <- unwire vmean
            covariance <- unwire vcovariance
            checked (S.gaussianState mean covariance) (\result_value -> publish (wire result_value) out)
        (99,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (S.stateMean value)) (\result_value -> publish (wire result_value) out)
        (100,[vvalue]) -> do
            value <- unwire vvalue
            checked (Right (S.stateCovariance value)) (\result_value -> publish (wire result_value) out)
        _ -> invalid "time-series operation identifier or arity differs"
