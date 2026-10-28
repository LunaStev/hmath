-- SPDX-License-Identifier: MPL-2.0

-- | Core HMath facade, including checked linear algebra operations and their
-- shared 'MathError' results. Extended scalar, algebra, tensor and numerical
-- APIs are available through their independent HMath modules.
module HMath
    ( module HMath.Basic
    , module HMath.Error
    , module HMath.Linear
    , module HMath.Matrix
    , module HMath.Matrix.LU
    , module HMath.Statistics
    ) where

import HMath.Basic
import HMath.Error
import HMath.Linear
import HMath.Matrix
import HMath.Matrix.LU
import HMath.Statistics
