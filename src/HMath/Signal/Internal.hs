-- SPDX-License-Identifier: MPL-2.0

-- | Private checked reference linear algebra shared by scientific algorithms.
module HMath.Signal.Internal (finite, require, checked, vector, solve, mm, mv, tr, eye, dot, norm, chunks, replace) where

import Data.List (maximumBy, transpose)
import Data.Ord (comparing)
import HMath.Error (MathError (..))

finite :: Double -> Bool
finite x = not (isNaN x || isInfinite x)
require :: Bool -> String -> Either MathError ()
require p s = if p then Right () else Left (InvalidArgument s)
checked :: Double -> Either MathError Double
checked x = if finite x then Right x else Left NonFiniteResult
vector :: [Double] -> Either MathError [Double]
vector = mapM checked
replace :: Int -> a -> [a] -> [a]
replace i x xs = take i xs ++ [x] ++ drop (i + 1) xs
chunks :: Int -> [a] -> [[a]]
chunks n xs | n <= 0 || null xs = [] | otherwise = take n xs : chunks n (drop n xs)
dot :: [Double] -> [Double] -> Double
dot a b = sum (zipWith (*) a b)
norm :: [Double] -> Double
norm xs =
    let s = maximum (0 : map abs xs)
     in if s == 0 then 0 else s * sqrt (sum [(x / s) ^ (2 :: Int) | x <- xs])
tr :: [[a]] -> [[a]]
tr = transpose
mv :: [[Double]] -> [Double] -> [Double]
mv a x = map (`dot` x) a
mm :: [[Double]] -> [[Double]] -> [[Double]]
mm a b = [[dot r c | c <- tr b] | r <- a]
eye :: Int -> [[Double]]
eye n = [[if i == j then 1 else 0 | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]

{- | Partial-pivoted elimination. Explicit square/finite contracts; singular
systems fail rather than yielding an arbitrary least-squares solution.
-}
solve :: [[Double]] -> [Double] -> Either MathError [Double]
solve a b = do
    let n = length a
    require
        (n > 0 && n <= 2048 && length b == n && all ((== n) . length) a)
        "invalid square reference solve (maximum 2048)"
    _ <- vector (concat a ++ b)
    upper <- foldl step (Right (zipWith (\r x -> r ++ [x]) a b)) [0 .. n - 1]
    let back i acc
            | i < 0 = vector acc
            | otherwise =
                let row = upper !! i; x = (last row - sum (zipWith (*) (drop (i + 1) (take n row)) acc)) / (row !! i)
                 in checked x >> back (i - 1) (x : acc)
    back (n - 1) []
  where
    step result k = do
        rows <- result
        let n = length rows
            p = maximumBy (comparing (abs . (!! k) . (rows !!))) [k .. n - 1]
            pivot = rows !! p !! k
        if pivot == 0
            then Left (SingularMatrix k)
            else do
                let swapped = replace p (rows !! k) (replace k (rows !! p) rows)
                    row = swapped !! k
                    next =
                        [if i <= k then r else zipWith (-) r (map (* (r !! k / pivot)) row) | (i, r) <- zip [0 ..] swapped]
                _ <- vector (concat next)
                Right next
