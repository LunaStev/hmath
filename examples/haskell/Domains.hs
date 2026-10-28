-- SPDX-License-Identifier: MPL-2.0

-- Run from the source checkout with: runghc -isrc -llapacke examples/haskell/Domains.hs
module Main where

import qualified HMath.Image as Image
import qualified HMath.TimeSeries as Time

main :: IO ()
main = do
    print (Time.fitAR 1 [1, 1.5, 1.75, 1.875, 1.9375] >>= Time.forecastAR 3)
    print (Time.changePoints 0.5 2 [0, 0, 0, 5, 5, 5])
    print $ do
        image <- Image.image [2, 2] 1 [0, 1, 1, 0]
        enlarged <- Image.resize Image.Bilinear Image.Clamp (3, 3) image
        pure (Image.imageShape enlarged, Image.imageValues enlarged)
