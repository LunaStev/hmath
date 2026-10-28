-- SPDX-License-Identifier: MPL-2.0

module HMath.Basic (
    factorial,
    fibonacci,
    isPrime,
    clamp,
    lerp,
) where

factorial :: Integer -> Integer
factorial n
    | n < 0 = error "factorial: negative input"
    | otherwise = product [1 .. n]

fibonacci :: Integer -> Integer
fibonacci n
    | n < 0 = error "fibonacci: negative input"
    | otherwise = go n 0 1
  where
    go 0 a _ = a
    go k a b = go (k - 1) b (a + b)

isPrime :: Integer -> Bool
isPrime n
    | n < 2 = False
    | n == 2 = True
    | even n = False
    | otherwise = check 3
  where
    check d
        | d > n `div` d = True
        | n `mod` d == 0 = False
        | otherwise = check (d + 2)

clamp :: (Ord a) => a -> a -> a -> a
clamp low high value = max low (min high value)

lerp :: (Fractional a) => a -> a -> a -> a
lerp a b t = a + (b - a) * t
