-- SPDX-License-Identifier: MPL-2.0
module HMath.Matrix.Internal (
    entries,
    build,
    get,
    mapEntries,
    finiteMatrix,
    finiteValues,
    stableNorm,
    dotV,
    replace,
    swap,
    epsilon,
    defaultTolerance,
) where

import HMath.Error
import HMath.Matrix

entries :: Matrix a -> [[a]]
entries a = let (r, c) = shape a in [take c (drop (i * c) (toList a)) | i <- [0 .. r - 1]]

build :: Int -> Int -> (Int -> Int -> a) -> Either MathError (Matrix a)
build r c f =
    fromListChecked
        r
        c
        (if r == 0 || c == 0 then [] else [f i j | i <- [0 .. r - 1], j <- [0 .. c - 1]])

get :: Matrix a -> Int -> Int -> a
get a i j = toList a !! (i * snd (shape a) + j)

mapEntries :: (a -> b) -> Matrix a -> Matrix b
mapEntries f a = case fromListChecked r c (map f (toList a)) of
    Right b -> b
    Left _ -> error "mapEntries: internal shape invariant"
  where
    (r, c) = shape a

finiteMatrix :: (RealFloat a) => Matrix a -> Either MathError ()
finiteMatrix a = case [k | (k, x) <- zip [0 ..] (toList a), isNaN x || isInfinite x] of
    k : _ -> Left (NonFiniteMatrixEntry (k `div` snd (shape a), k `mod` snd (shape a)))
    [] -> Right ()

finiteValues :: (RealFloat a) => [a] -> Either MathError ()
finiteValues xs = case [i | (i, x) <- zip [0 ..] xs, isNaN x || isInfinite x] of
    i : _ -> Left (NonFiniteVectorEntry i)
    [] -> Right ()

stableNorm :: (RealFloat a) => [a] -> a
stableNorm xs
    | any isNaN xs = 0 / 0
    | any isInfinite xs = 1 / 0
    | s == 0 = 0
    | otherwise = s * sqrt (sum [(x / s) ^ (2 :: Int) | x <- xs])
  where
    s = maximum (0 : map abs xs)

dotV :: (Num a) => [a] -> [a] -> a
dotV a b = sum (zipWith (*) a b)

replace :: Int -> a -> [a] -> [a]
replace i x xs = take i xs ++ x : drop (i + 1) xs

swap :: Int -> Int -> [a] -> [a]
swap i j xs = replace i (xs !! j) (replace j (xs !! i) xs)

epsilon :: (RealFloat a) => a -> a
epsilon x = encodeFloat 1 (1 - floatDigits x)

defaultTolerance :: (RealFloat a) => Matrix a -> a
defaultTolerance a = fromIntegral (max r c) * epsilon prototype
  where
    (r, c) = shape a
    prototype = case toList a of x : _ -> x; [] -> 0
