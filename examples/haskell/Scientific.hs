-- SPDX-License-Identifier: MPL-2.0
-- Run in the checkout with: cabal exec -- runghc -isrc -llapacke examples/haskell/Scientific.hs
module Main where

import Data.Complex (Complex ((:+)))
import qualified HMath.Autodiff as AD
import qualified HMath.Fourier as FFT
import qualified HMath.MachineLearning as ML
import qualified HMath.Random as R

main :: IO ()
main = do
    -- Pure generator state makes repeated experiments reproducible.
    print (fmap fst (R.sampleN 4 (R.normal 0 1) (R.seedRNG R.PCG32 42)))
    -- Reverse differentiation of x^2 + sin y.
    print (AD.valueAndGradient (\xs -> xs !! 0 * xs !! 0 + sin (xs !! 1)) [3, 0])
    -- A fitted model owns its coefficients; prediction preserves input rows.
    print $ do
        fit <- ML.fitLinear ML.defaultMLConfig ML.Ordinary [[0], [1], [2]] [1, 3, 5]
        ML.predictLinear (ML.fitted fit) [[3]]
    print (FFT.fft [1 :+ 0, 0 :+ 0, 0 :+ 0, 0 :+ 0])
