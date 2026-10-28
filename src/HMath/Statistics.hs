-- SPDX-License-Identifier: MPL-2.0

module HMath.Statistics (
    mean,
    variance,
    standardDeviation,
    median,
) where

import Data.List (sort)

{- | Arithmetic mean of a finite nonempty list: sum divided by length. Empty input raises a
pure error; no non-finite-value validation is performed. Example: mean [2,4] == 3.
-}
mean :: (Fractional a) => [a] -> a
mean [] = error "mean: empty input"
mean xs = sum xs / fromIntegral (length xs)

{- | Population variance of a finite nonempty list, dividing squared deviations by n (not
n-1). Empty input raises a pure error. Example: variance [1,3] == 1.
-}
variance :: (Fractional a) => [a] -> a
variance [] = error "variance: empty input"
variance xs =
    let m = mean xs
        squared = map (\x -> (x - m) * (x - m)) xs
     in sum squared / fromIntegral (length xs)

{- | Population standard deviation, sqrt of variance. Requires a finite nonempty list; empty
input raises the same error as variance. Example: standardDeviation [1,3] == 1.
-}
standardDeviation :: (Floating a) => [a] -> a
standardDeviation = sqrt . variance

{- | Sort a finite nonempty list and return its middle value, averaging the central pair for
even length. Empty input raises a pure error. Example: median [4,1,3,2] == 2.5.
-}
median :: (Ord a, Fractional a) => [a] -> a
median [] = error "median: empty input"
median xs
    | odd n = sorted !! mid
    | otherwise = (sorted !! (mid - 1) + sorted !! mid) / 2
  where
    sorted = sort xs
    n = length xs
    mid = n `div` 2
