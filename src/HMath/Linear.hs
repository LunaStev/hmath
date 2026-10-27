-- SPDX-License-Identifier: MPL-2.0

module HMath.Linear
    ( dot
    , magnitude
    , normalize
    , add
    , scale
    ) where

dot :: Num a => [a] -> [a] -> a
dot xs ys
    | length xs /= length ys = error "dot: dimension mismatch"
    | otherwise = sum (zipWith (*) xs ys)

magnitude :: Floating a => [a] -> a
magnitude xs = sqrt (dot xs xs)

normalize :: (Eq a, Floating a) => [a] -> [a]
normalize xs
    | m == 0 = xs
    | otherwise = map (/ m) xs
    where
        m = magnitude xs

add :: Num a => [a] -> [a] -> [a]
add xs ys
    | length xs /= length ys = error "add: dimension mismatch"
    | otherwise = zipWith (+) xs ys

scale :: Num a => a -> [a] -> [a]
scale s = map (* s)
