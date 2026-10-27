-- SPDX-License-Identifier: MPL-2.0

module HMath.Statistics
    ( mean
    , variance
    , standardDeviation
    , median
    ) where

import Data.List (sort)

mean :: Fractional a => [a] -> a
mean [] = error "mean: empty input"
mean xs = sum xs / fromIntegral (length xs)

variance :: Fractional a => [a] -> a
variance [] = error "variance: empty input"
variance xs =
    let m = mean xs
        squared = map (\x -> (x - m) * (x - m)) xs
    in sum squared / fromIntegral (length xs)

standardDeviation :: Floating a => [a] -> a
standardDeviation = sqrt . variance

median :: (Ord a, Fractional a) => [a] -> a
median [] = error "median: empty input"
median xs
    | odd n = sorted !! mid
    | otherwise = (sorted !! (mid - 1) + sorted !! mid) / 2
    where
        sorted = sort xs
        n = length xs
        mid = n `div` 2
