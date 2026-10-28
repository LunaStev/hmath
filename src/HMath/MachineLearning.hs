-- SPDX-License-Identifier: MPL-2.0

{- | Reproducible dense CPU estimators, preprocessing, clustering, and manifold
methods. Features are finite rows; fitted state is immutable and independent
of future transforms/predictions. Fit preprocessing separately within every
training fold. Iterative fits expose residual, iterations, and convergence;
no successful return alone implies an optimizer reached its optimum.
-}
module HMath.MachineLearning (
    Dataset,
    MLConfig (..),
    defaultMLConfig,
    Fit (..),
    module HMath.MachineLearning.Preprocessing,
    module HMath.MachineLearning.Regression,
    module HMath.MachineLearning.Decomposition,
    module HMath.MachineLearning.Clustering,
    module HMath.MachineLearning.Neighbors,
) where

import HMath.MachineLearning.Clustering
import HMath.MachineLearning.Decomposition
import HMath.MachineLearning.Internal (Dataset, Fit (..), MLConfig (..), defaultMLConfig)
import HMath.MachineLearning.Neighbors
import HMath.MachineLearning.Preprocessing
import HMath.MachineLearning.Regression
