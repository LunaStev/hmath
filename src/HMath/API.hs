-- SPDX-License-Identifier: MPL-2.0

{- | Stable additive contracts for checked HMath code. Existing modules retain
their signatures; importing this facade is optional. Static constructors and
dynamic conversions validate shapes; generic algebra supports exact/custom
scalars; containers make copying, evaluation and mutation explicit. Legacy
numerical algorithms remain individually importable from their own modules.
-}
module HMath.API (
    module HMath.API.Algebra,
    module HMath.API.Shape,
    module HMath.API.Buffer,
    module HMath.API.Convergence,
) where

import HMath.API.Algebra
import HMath.API.Buffer
import HMath.API.Convergence
import HMath.API.Shape
