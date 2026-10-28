-- SPDX-License-Identifier: MPL-2.0

module HMath.Basic (
    factorial,
    fibonacci,
    isPrime,
    clamp,
    lerp,
) where

{- | Return n! using unbounded Integer arithmetic; 0! is 1. Negative n raises a pure error.
For a checked Either result use HMath.Scalar.factorialChecked. Example: factorial 5 ==
120.
-}
factorial :: Integer -> Integer
factorial n
    | n < 0 = error "factorial: negative input"
    | otherwise = product [1 .. n]

{- | Return the zero-based Fibonacci number (F0=0, F1=1). Negative indices raise a pure
error; use HMath.Scalar.fibonacciChecked for checked input. Example: fibonacci 10 ==
55.
-}
fibonacci :: Integer -> Integer
fibonacci n
    | n < 0 = error "fibonacci: negative input"
    | otherwise = go n 0 1
  where
    go 0 a _ = a
    go k a b = go (k - 1) b (a + b)

{- | Test an Integer by trial division through its square root. All n below 2 return False;
2 returns True. Example: isPrime 17 == True. This is a reference primality test for
modest inputs.
-}
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

{- | Given lower bound, upper bound, then value, return max lower (min upper value). Bounds
must be ordered by the caller; reversed bounds are not rejected. Example: clamp 0 1 2
== 1. Use clampChecked for validation.
-}
clamp :: (Ord a) => a -> a -> a -> a
clamp low high value = max low (min high value)

{- | Given endpoints a and b then parameter t, return a+(b-a)*t. Values outside [0,1]
extrapolate; arithmetic follows the chosen Fractional type without validation. Example:
lerp 10 20 0.5 == 15.
-}
lerp :: (Fractional a) => a -> a -> a -> a
lerp a b t = a + (b - a) * t
