-- SPDX-License-Identifier: MPL-2.0

{- | Image measurements use caller-declared intensity ranges and explicit
local windows. All images must share shape/channel count for comparisons.
-}
module HMath.Image.Measure (
    TemplateMetric (..),
    templateMatch,
    rawMoment,
    centralMoment,
    imageCentroid,
    integralImage,
    rectangleSum,
    meanSquaredError,
    peakSignalToNoise,
    structuralSimilarity,
) where

import Data.Array (Array, array, (!))
import HMath.Error
import HMath.Image.Core
import HMath.Image.Filter (scalar2D)

data TemplateMetric = SquaredDifference | NormalizedCorrelation deriving (Eq, Show)

{- | Valid 2D, one-channel matching. Each output is one template origin.
NCC centers both patches and divides by their energies; constant templates
or candidate patches have undefined correlation and return MathError.
-}
templateMatch :: TemplateMetric -> Image -> Image -> Either MathError Image
templateMatch method needle haystack = do
    (th, tw) <- scalar2D needle
    (height, width) <- scalar2D haystack
    require
        ( th <= height
            && tw <= width
            && toInteger th * toInteger tw * toInteger (height - th + 1) * toInteger (width - tw + 1) <= 20000000
        )
        "template size/work limit"
    let template = imageValues needle
        origins = coordinates [height - th + 1, width - tw + 1]
        evaluate origin =
            let patch = [at haystack [origin !! 0 + i, origin !! 1 + j] 0 | i <- [0 .. th - 1], j <- [0 .. tw - 1]]
             in case method of
                    SquaredDifference -> single (sum (zipWith (\x y -> (x - y) ^ (2 :: Int)) template patch))
                    NormalizedCorrelation -> do
                        let centered values = let mean = sum (map (/ fromIntegral (length values)) values) in map (subtract mean) values
                            a = centered template
                            b = centered patch
                            den = sqrt (sum (map (^ (2 :: Int)) a)) * sqrt (sum (map (^ (2 :: Int)) b))
                        require (finite den && den > 0) "NCC requires positive finite patch variance"
                        single (sum (zipWith (*) a b) / den)
    values <- mapM evaluate origins
    image [height - th + 1, width - tw + 1] 1 values

-- | Raw M_pq=sum(row^p*column^q*intensity), orders 0..8 each.
rawMoment :: Int -> Int -> Image -> Either MathError Double
rawMoment p q img = do
    (height, width) <- scalar2D img
    require (p >= 0 && q >= 0 && p <= 8 && q <= 8) "moment orders outside [0,8]"
    single
        ( sum
            [ fromIntegral i ^ p * fromIntegral j ^ q * at img [i, j] 0
            | i <- [0 .. height - 1]
            , j <- [0 .. width - 1]
            ]
        )

{- | Intensity-weighted (row,column) centroid. Signed intensities are allowed;
a zero total mass is undefined and reported explicitly.
-}
imageCentroid :: Image -> Either MathError (Double, Double)
imageCentroid img = do
    mass <- rawMoment 0 0 img
    require (mass /= 0) "zero image mass"
    row <- rawMoment 1 0 img >>= single . (/ mass)
    col <- rawMoment 0 1 img >>= single . (/ mass)
    Right (row, col)

centralMoment :: Int -> Int -> Image -> Either MathError Double
centralMoment p q img = do
    (height, width) <- scalar2D img
    require (p >= 0 && q >= 0 && p <= 8 && q <= 8) "moment orders outside [0,8]"
    (cy, cx) <- imageCentroid img
    single
        ( sum
            [ (fromIntegral i - cy) ^ p * (fromIntegral j - cx) ^ q * at img [i, j] 0
            | i <- [0 .. height - 1]
            , j <- [0 .. width - 1]
            ]
        )

{- | Padded 2D summed-area image, per channel: output shape (height+1,width+1)
has a leading zero row/column. Rectangle queries use half-open bounds.
-}
integralImage :: Image -> Either MathError Image
integralImage img = do
    require (length (imageShape img) == 2) "2D integral image required"
    let height = imageShape img !! 0; width = imageShape img !! 1; nc = imageChannels img
    require
        (toInteger (height + 1) * toInteger (width + 1) * toInteger nc <= 262144)
        "integral image output storage limit"
    let values :: Array (Int, Int, Int) Double
        values =
            array
                ((0, 0, 0), (height, width, nc - 1))
                [ ( (i, j, c)
                  , if i == 0 || j == 0
                        then 0
                        else
                            at img [i - 1, j - 1] c
                                + values ! (i - 1, j, c)
                                + values ! (i, j - 1, c)
                                - values ! (i - 1, j - 1, c)
                  )
                | i <- [0 .. height]
                , j <- [0 .. width]
                , c <- [0 .. nc - 1]
                ]
    build [height + 1, width + 1] nc (\ix c -> values ! (ix !! 0, ix !! 1, c))

rectangleSum :: (Int, Int) -> (Int, Int) -> Image -> Either MathError [Double]
rectangleSum (row, col) (height, width) summed = do
    require
        ( length (imageShape summed) == 2
            && row >= 0
            && col >= 0
            && height >= 0
            && width >= 0
            && toInteger row + toInteger height < toInteger (imageShape summed !! 0)
            && toInteger col + toInteger width < toInteger (imageShape summed !! 1)
        )
        "summed-area rectangle out of bounds"
    checked
        [ at summed [row + height, col + width] c
            - at summed [row, col + width] c
            - at summed [row + height, col] c
            + at summed [row, col] c
        | c <- [0 .. imageChannels summed - 1]
        ]

same :: Image -> Image -> Either MathError ()
same a b =
    require
        (imageShape a == imageShape b && imageChannels a == imageChannels b)
        "comparison shape mismatch"
meanSquaredError :: Image -> Image -> Either MathError Double
meanSquaredError a b = do
    same a b
    let n = fromIntegral (length (imageValues a))
    single (sum (zipWith (\x y -> ((x - y) / sqrt n) ^ (2 :: Int)) (imageValues a) (imageValues b)))

{- | PSNR in decibels. Exactly identical images return positive infinity by
definition; this is the sole intentional nonfinite measurement result.
-}
peakSignalToNoise :: Double -> Image -> Image -> Either MathError Double
peakSignalToNoise dataRange a b = do
    require (finite dataRange && dataRange > 0) "positive PSNR range required"
    mse <- meanSquaredError a b
    if mse == 0 then Right (1 / 0) else single (20 * logBase 10 dataRange - 10 * logBase 10 mse)

{- | Mean local SSIM with uniform valid windows and population covariance.
C1=(0.01*range)^2, C2=(0.03*range)^2; all channels are measured separately.
Windows do not include padding and both spatial extents must fit the window.
Wang et al., Image Quality Assessment: From Error Visibility to Structural
Similarity (2004), https://ece.uwaterloo.ca/~z70wang/publications/ssim.html .
-}
structuralSimilarity :: Double -> Int -> Image -> Image -> Either MathError Double
structuralSimilarity dataRange window a b = do
    same a b
    require
        (length (imageShape a) == 2 && finite dataRange && dataRange > 0 && window >= 1 && window <= 63)
        "SSIM range/window/rank"
    let height = imageShape a !! 0; width = imageShape a !! 1; nc = imageChannels a
    require
        ( window <= height
            && window <= width
            && toInteger window
                * toInteger window
                * toInteger (height - window + 1)
                * toInteger (width - window + 1)
                * toInteger nc
                <= 20000000
        )
        "SSIM window/work limit"
    let c1 = (0.01 * dataRange) ^ (2 :: Int)
        c2 = (0.03 * dataRange) ^ (2 :: Int)
        score i j c =
            let patch img = [at img [i + di, j + dj] c | di <- [0 .. window - 1], dj <- [0 .. window - 1]]
                x = patch a
                y = patch b
                n = fromIntegral (length x)
                mx = sum (map (/ n) x)
                my = sum (map (/ n) y)
                vx = sum [((z - mx) / sqrt n) ^ (2 :: Int) | z <- x]
                vy = sum [((z - my) / sqrt n) ^ (2 :: Int) | z <- y]
                covariance = sum (zipWith (\u v -> ((u - mx) / sqrt n) * ((v - my) / sqrt n)) x y)
             in ((2 * mx * my + c1) * (2 * covariance + c2)) / ((mx * mx + my * my + c1) * (vx + vy + c2))
        scores = [score i j c | i <- [0 .. height - window], j <- [0 .. width - window], c <- [0 .. nc - 1]]
    _ <- checked (c1 : c2 : scores)
    single (sum (map (/ fromIntegral (length scores)) scores))

single :: Double -> Either MathError Double
single value = do _ <- checked [value]; Right value
