-- SPDX-License-Identifier: MPL-2.0

{- | Unit-range, per-channel histograms, equalization, thresholds, and CLAHE.
Values must be in [0,1]; exactly one belongs to the last bin. CLAHE clips
tile counts, redistributes excess without exceeding the feasible clip cap,
and bilinearly interpolates mappings at tile centers.
-}
module HMath.Image.Histogram (histogram, equalizeHistogram, clahe, threshold, otsu, adaptiveThreshold) where

import Data.Array (Array, accumArray, elems, listArray, (!))
import HMath.Error
import HMath.Image.Core
import HMath.Image.Filter (boxBlur, gaussianBlur, validateBoundary)

unit :: Int -> Image -> Either MathError ()
unit bins img = do
    require (bins >= 2 && bins <= 4096) "histogram bin count outside [2,4096]"
    require (all (\x -> x >= 0 && x <= 1) (imageValues img)) "unit-range image required"
bin :: Int -> Double -> Int
bin bins x = min (bins - 1) (floor (x * fromIntegral bins))
counts :: Int -> [Double] -> [Int]
counts bins values = elems (accumArray (+) 0 (0, bins - 1) [(bin bins x, 1) | x <- values] :: Array Int Int)
histogram :: Int -> Image -> Either MathError [[Int]]
histogram bins img = do
    unit bins img
    Right
        [counts bins [at img ix c | ix <- coordinates (imageShape img)] | c <- [0 .. imageChannels img - 1]]

{- | CDF-min equalization with quantized bin mapping. A single occupied bin
is left unchanged, avoiding an arbitrary jump on constant images.
-}
equalizeHistogram :: Int -> Image -> Either MathError Image
equalizeHistogram bins img = do
    hist <- histogram bins img
    let maps = [listArray (0, bins - 1) (mapping h) | h <- hist]
        mapping h =
            let cdf = (drop 1) (scanl (+) 0 h); initial = (!! 0) (dropWhile (== 0) cdf); total = sum h
             in if initial == total
                    then [fromIntegral i / fromIntegral (bins - 1) | i <- [0 .. bins - 1]]
                    else [max 0 (fromIntegral (n - initial) / fromIntegral (total - initial)) | n <- cdf]
        constant c = length (filter (> 0) (hist !! c)) == 1
    build
        (imageShape img)
        (imageChannels img)
        (\ix c -> let x = at img ix c in if constant c then x else maps !! c ! bin bins x)

{- | 2D adaptive equalization. clipFactor>=1 is relative to uniform tile
occupancy; the cap is max(ceil(tileSamples/bins),floor(factor*tileSamples/bins)).
Tiles at image ends may be smaller. Intensities are quantized without
channel coupling. At most 4,096 tiles and 1,048,576 stored histogram bins.
-}
clahe :: Int -> (Int, Int) -> Double -> Image -> Either MathError Image
clahe bins (tileHeight, tileWidth) clipFactor img = do
    unit bins img
    require
        ( length (imageShape img) == 2
            && tileHeight > 0
            && tileWidth > 0
            && finite clipFactor
            && clipFactor >= 1
            && clipFactor <= 1e6
        )
        "invalid CLAHE parameters"
    let height = imageShape img !! 0
        width = imageShape img !! 1
        nh = 1 + (height - 1) `div` tileHeight
        nw = 1 + (width - 1) `div` tileWidth
    require
        ( toInteger nh * toInteger nw <= 4096
            && toInteger nh * toInteger nw * toInteger bins * toInteger (imageChannels img) <= 1048576
        )
        "CLAHE histogram storage limit"
    let tile i j c =
            let values =
                    [ at img [y, x] c
                    | y <- [i * tileHeight .. min height ((i + 1) * tileHeight) - 1]
                    , x <- [j * tileWidth .. min width ((j + 1) * tileWidth) - 1]
                    ]
                n = length values
                cap = max ((n + bins - 1) `div` bins) (min n (floor (clipFactor * fromIntegral n / fromIntegral bins)))
                clipped = map (min cap) (counts bins values)
                redistributed = redistribute cap (n - sum clipped) clipped
             in listArray
                    (0, bins - 1)
                    (map ((/ fromIntegral n) . fromIntegral) ((drop 1) (scanl (+) 0 redistributed)))
        mappings = array3 nh nw (imageChannels img) tile
        yCenters = [fromIntegral (i * tileHeight + min height ((i + 1) * tileHeight) - 1) / 2 | i <- [0 .. nh - 1]]
        xCenters = [fromIntegral (j * tileWidth + min width ((j + 1) * tileWidth) - 1) / 2 | j <- [0 .. nw - 1]]
        apply [y, x] c =
            let (a, b, v) = bracket yCenters (fromIntegral y)
                (d, e, u) = bracket xCenters (fromIntegral x)
                k = bin bins (at img [y, x] c)
                get i j = mappings ! ((i * nw + j) * imageChannels img + c) ! k
             in (1 - v) * ((1 - u) * get a d + u * get a e) + v * ((1 - u) * get b d + u * get b e)
        apply _ _ = 0
    build [height, width] (imageChannels img) apply
  where
    array3 nh nw nc f =
        listArray
            (0, nh * nw * nc - 1)
            [f i j c | i <- [0 .. nh - 1], j <- [0 .. nw - 1], c <- [0 .. nc - 1]]
    redistribute _ 0 hs = hs
    redistribute cap remaining hs =
        let available = length (filter (< cap) hs)
            share = max 1 (remaining `div` available)
            step left [] = (left, [])
            step left (h : rest) =
                let delta = min left (min share (cap - h)); (final, tailValues) = step (left - delta) rest
                 in (final, (h + delta) : tailValues)
            (unassigned, next) = step remaining hs
         in redistribute cap unassigned next
    bracket centers value
        | value <= (!! 0) centers = (0, 0, 0)
        | value >= last centers = (length centers - 1, length centers - 1, 0)
        | otherwise =
            let b = length (takeWhile (< value) centers); a = b - 1
             in (a, b, (value - centers !! a) / (centers !! b - centers !! a))

-- | Strict comparison x>level; each channel is thresholded independently.
threshold :: Double -> Image -> Either MathError Image
threshold level img = do require (finite level) "nonfinite threshold"; mapImage (\x -> if x > level then 1 else 0) img

{- | Otsu between-class variance maximum. Lowest threshold wins ties. Returns
one bin-edge threshold per channel; a constant channel returns its value.
-}
otsu :: Int -> Image -> Either MathError ([Double], Image)
otsu bins img = do
    hist <- histogram bins img
    let choose c h =
            let values = [at img ix c | ix <- coordinates (imageShape img)]
                n = fromIntegral (sum h) :: Double
                total = sum [fromIntegral i * fromIntegral count | (i, count) <- zip [0 :: Int ..] h]
                choices =
                    [ (score, k)
                    | k <- [0 .. bins - 2]
                    , let w0 = fromIntegral (sum (take (k + 1) h))
                    , let s0 = sum [fromIntegral i * fromIntegral count | (i, count) <- zip [0 :: Int .. k] (take (k + 1) h)]
                    , let score =
                            if w0 == 0 || w0 == n then -1 else w0 * (n - w0) * (s0 / w0 - (total - s0) / (n - w0)) ^ (2 :: Int)
                    ]
                best = foldl (\a b -> if fst b > fst a then b else a) ((!! 0) choices) ((drop 1) choices)
             in if minimum values == maximum values
                    then (!! 0) values
                    else fromIntegral (snd best + 1) / fromIntegral bins
        levels = zipWith choose [0 ..] hist
    result <-
        build (imageShape img) (imageChannels img) (\ix c -> if at img ix c > levels !! c then 1 else 0)
    Right (levels, result)

{- | Local mean or Gaussian threshold: x > localMean-offset. Gaussian uses
sigma=max(0.5,radius/2); boundary extension is explicit.
-}
adaptiveThreshold :: Bool -> Boundary -> Int -> Double -> Image -> Either MathError Image
adaptiveThreshold gaussian boundary radius offset img = do
    validateBoundary boundary
    require (finite offset) "nonfinite adaptive offset"
    smoothed <-
        if gaussian
            then gaussianBlur boundary (max 0.5 (fromIntegral radius / 2)) radius img
            else boxBlur boundary radius img
    zipImage (\x mean -> if x > mean - offset then 1 else 0) img smoothed
