-- SPDX-License-Identifier: MPL-2.0

{- | Timestamped observations, bounded CPU forecasting, decomposition and
diagnostics. See the individual modules for missing-data, fit and error contracts.
-}
module HMath.TimeSeries (
    module HMath.TimeSeries.Core,
    module HMath.TimeSeries.Models,
    module HMath.TimeSeries.Diagnostics,
) where

import HMath.TimeSeries.Core hiding (average, checked, finite, require, validate)
import HMath.TimeSeries.Diagnostics
import HMath.TimeSeries.Models
