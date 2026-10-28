-- SPDX-License-Identifier: MPL-2.0

{- | List-based vector operations. Inputs must be finite lists. Checked binary
operations return a 'MathError' for unequal lengths; legacy 'dot' and 'add'
retain their original exception behavior for that case.
-}
module HMath.Linear (
    dot,
    dotChecked,
    magnitude,
    normalize,
    add,
    addChecked,
    subtractChecked,
    scale,
) where

import HMath.Error (MathError (..))

{- | Inner product. Empty vectors have inner product zero.
Unequal lengths raise an exception; use 'dotChecked' to handle that input.
-}
dot :: (Num a) => [a] -> [a] -> a
dot xs ys = either (const (error "dot: dimension mismatch")) id (dotChecked xs ys)

-- | Inner product, or 'VectorLengthMismatch' with the left and right lengths.
dotChecked :: (Num a) => [a] -> [a] -> Either MathError a
dotChecked xs ys = sum <$> zipWithChecked (*) xs ys

-- | Euclidean magnitude. The empty vector has magnitude zero.
magnitude :: (Floating a) => [a] -> a
magnitude xs = sqrt (dot xs xs)

{- | Normalize by Euclidean magnitude. A vector whose computed magnitude is
zero is returned unchanged, including the empty vector. Floating-point
overflow and non-finite values retain the underlying type's behavior.
-}
normalize :: (Eq a, Floating a) => [a] -> [a]
normalize xs
    | m == 0 = xs
    | otherwise = map (/ m) xs
  where
    m = magnitude xs

{- | Elementwise addition. Unequal lengths raise an exception; use 'addChecked'
to handle that input.
-}
add :: (Num a) => [a] -> [a] -> [a]
add xs ys = either (const (error "add: dimension mismatch")) id (addChecked xs ys)

-- | Elementwise addition, requiring equal lengths. Two empty lists succeed.
addChecked :: (Num a) => [a] -> [a] -> Either MathError [a]
addChecked = zipWithChecked (+)

-- | Elementwise left-minus-right subtraction, requiring equal lengths.
subtractChecked :: (Num a) => [a] -> [a] -> Either MathError [a]
subtractChecked = zipWithChecked (-)

-- | Multiply every component by a scalar, preserving length.
scale :: (Num a) => a -> [a] -> [a]
scale s = map (* s)

zipWithChecked :: (a -> b -> c) -> [a] -> [b] -> Either MathError [c]
zipWithChecked operation xs ys
    | leftLength /= rightLength = Left (VectorLengthMismatch leftLength rightLength)
    | otherwise = Right (zipWith operation xs ys)
  where
    leftLength = length xs
    rightLength = length ys
