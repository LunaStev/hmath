-- SPDX-License-Identifier: MPL-2.0

-- | 2D resampling/warps, ND binary topology, and exact bounded distance queries.
module HMath.Image.Spatial (
    Interpolation (..),
    resize,
    warp,
    translate,
    rotate,
    Connectivity (..),
    connectedComponents,
    distanceTransform,
) where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import HMath.Error
import HMath.Image.Core
import HMath.Image.Filter (validateBoundary)
import qualified HMath.Matrix as M
import qualified HMath.Matrix.LU as LU

{- | Image resampling interpolation mode, choosing nearest,bilinear,bicubic,or Lanczos
kernels.
-}
data Interpolation = Nearest | Bilinear | Bicubic | Lanczos deriving (Eq, Show)

{- | 2D resize uses pixel-center mapping (i+0.5)*old/new-0.5, independently
per channel, without antialiasing. Bicubic is Keys a=-0.5; Lanczos has
radius three. Downsampling callers can explicitly prefilter first.
-}
resize :: Interpolation -> Boundary -> (Int, Int) -> Image -> Either MathError Image
resize method boundary (height, width) img = do
    validateBoundary boundary
    require
        ( length (imageShape img) == 2
            && height > 0
            && width > 0
            && toInteger height * toInteger width * toInteger (imageChannels img) <= 262144
        )
        "resize shape/storage limit"
    let oldHeight = imageShape img !! 0; oldWidth = imageShape img !! 1
    build
        [height, width]
        (imageChannels img)
        ( \ix c ->
            interpolate
                method
                boundary
                img
                ((fromIntegral (ix !! 0) + 0.5) * fromIntegral oldHeight / fromIntegral height - 0.5)
                ((fromIntegral (ix !! 1) + 0.5) * fromIntegral oldWidth / fromIntegral width - 0.5)
                c
        )

{- | Forward 3x3 homogeneous transform acts on [x(column),y(row),1]. The
matrix is inverted once for output-to-input sampling. Points at projective
infinity or with magnitude over 1e9 are errors, even with constant padding.
-}
warp :: Interpolation -> Boundary -> (Int, Int) -> [[Double]] -> Image -> Either MathError Image
warp method boundary (height, width) transform img = do
    validateBoundary boundary
    require
        ( length (imageShape img) == 2
            && length transform == 3
            && all ((== 3) . length) transform
            && height > 0
            && width > 0
            && toInteger height * toInteger width * toInteger (imageChannels img) <= 262144
        )
        "warp matrix/output shape"
    _ <- checked (concat transform)
    matrix <- M.fromListChecked 3 3 (concat transform)
    inverse <- M.toList <$> LU.inverse matrix
    points <-
        mapM
            ( \ix -> do
                let x = fromIntegral (ix !! 1)
                    y = fromIntegral (ix !! 0)
                    a = inverse !! 0 * x + inverse !! 1 * y + inverse !! 2
                    b = inverse !! 3 * x + inverse !! 4 * y + inverse !! 5
                    w = inverse !! 6 * x + inverse !! 7 * y + inverse !! 8
                _ <- checked [a, b, w]
                require (w /= 0) "projective point at infinity"
                _ <- checked [a / w, b / w]
                require (abs (a / w) <= 1e9 && abs (b / w) <= 1e9) "warp coordinate limit"
                Right (b / w, a / w)
            )
            (coordinates [height, width])
    image
        [height, width]
        (imageChannels img)
        [interpolate method boundary img y x c | (y, x) <- points, c <- [0 .. imageChannels img - 1]]

-- | Translation in pixel columns/rows; output dimensions equal input.
translate :: Interpolation -> Boundary -> Double -> Double -> Image -> Either MathError Image
translate method boundary dx dy img = do
    require (length (imageShape img) == 2) "2D translation required"
    warp
        method
        boundary
        (imageShape img !! 0, imageShape img !! 1)
        [[1, 0, dx], [0, 1, dy], [0, 0, 1]]
        img

{- | Angle in radians, clockwise on row-down image coordinates; rotate about
the center pixel coordinate while preserving the input canvas dimensions.
-}
rotate :: Interpolation -> Boundary -> Double -> Image -> Either MathError Image
rotate method boundary angle img = do
    require (length (imageShape img) == 2 && finite angle) "invalid 2D rotation"
    let cx = fromIntegral (imageShape img !! 1 - 1) / 2
        cy = fromIntegral (imageShape img !! 0 - 1) / 2
        a = cos angle
        b = sin angle
    warp
        method
        boundary
        (imageShape img !! 0, imageShape img !! 1)
        [[a, -b, cx - a * cx + b * cy], [b, a, cy - b * cx - a * cy], [0, 0, 1]]
        img

interpolate :: Interpolation -> Boundary -> Image -> Double -> Double -> Int -> Double
interpolate Nearest boundary img y x c = sample boundary img [floor (y + 0.5), floor (x + 0.5)] c
interpolate method boundary img y x c =
    let radius = case method of Bilinear -> 1; Bicubic -> 2; Lanczos -> 3
        weights value = [(i, kernel (value - fromIntegral i)) | i <- [floor value - radius + 1 .. floor value + radius]]
        kernel t =
            let a = abs t
             in case method of
                    Bilinear -> max 0 (1 - a)
                    Bicubic ->
                        if a < 1
                            then 1.5 * a ^ (3 :: Int) - 2.5 * a ^ (2 :: Int) + 1
                            else if a < 2 then (-0.5) * a ^ (3 :: Int) + 2.5 * a ^ (2 :: Int) - 4 * a + 2 else 0
                    Lanczos ->
                        if a == 0 then 1 else if a < 3 then sin (pi * a) / (pi * a) * sin (pi * a / 3) / (pi * a / 3) else 0
        wy = weights y
        wx = weights x
        total = sum (map snd wy) * sum (map snd wx)
     in sum [a * b / total * sample boundary img [i, j] c | (i, a) <- wy, (j, b) <- wx]

-- | Spatial connected-component adjacency: axis neighbors or all surrounding neighbors.
data Connectivity = AxisConnected | FullyConnected deriving (Eq, Show)

{- | Nonzero is foreground. Label zero is background; component labels start
at one in first-pixel row-major order. Returns labels as exact Doubles and
component sizes in that same order. Connectivity has no wraparound.
-}
connectedComponents :: Connectivity -> Image -> Either MathError (Image, [Int])
connectedComponents connectivity img = do
    require (imageChannels img == 1) "components need one channel"
    let dims = imageShape img; rank = length dims
    require (rank <= 4) "component rank limit (four)"
    let offsets = case connectivity of
            AxisConnected ->
                [take k (repeat 0) ++ [sign] ++ replicate (rank - k - 1) 0 | k <- [0 .. rank - 1], sign <- [-1, 1]]
            FullyConnected -> [map (subtract 1) ix | ix <- coordinates (replicate rank 3), any (/= 1) ix]
        foreground = Set.fromList [ix | ix <- coordinates dims, at img ix 0 /= 0]
        flood [] pending found = (pending, found)
        flood (ix : queue) pending found =
            let next = filter (`Set.member` pending) [zipWith (+) ix offset | offset <- offsets]
                remaining = foldr Set.delete pending next
             in flood (next ++ queue) remaining (ix : found)
        components pending labels sizes label
            | Set.null pending = (labels, reverse sizes)
            | otherwise =
                let start = Set.findMin pending
                    (remaining, found) = flood [start] (Set.delete start pending) []
                    next = foldr (\ix -> Map.insert ix (fromIntegral label)) labels found
                 in components remaining next (length found : sizes) (label + 1)
        (finalLabels, finalSizes) = components foreground Map.empty [] (1 :: Int)
    require
        (toInteger (Set.size foreground) * toInteger (length offsets) <= 20000000)
        "component work limit"
    result <- build dims 1 (\ix _ -> Map.findWithDefault 0 ix finalLabels)
    Right (result, finalSizes)

{- | Exact brute-force Euclidean distance to the nearest zero-valued spatial
sample, with strictly positive per-axis spacing. No implicit outside zeros;
an all-foreground image has no finite answer and returns DomainError.
-}
distanceTransform :: [Double] -> Image -> Either MathError Image
distanceTransform spacing img = do
    require
        ( imageChannels img == 1
            && length spacing == length (imageShape img)
            && all (\x -> finite x && x > 0) spacing
            && spatialSize img <= 4096
        )
        "distance transform shape/spacing/size"
    let zeros = [ix | ix <- coordinates (imageShape img), at img ix 0 == 0]
    require (not (null zeros)) "distance transform has no background sample"
    let norm values =
            let scale = maximum (0 : map abs values)
             in if scale == 0 then 0 else scale * sqrt (sum [(x / scale) ^ (2 :: Int) | x <- values])
    build
        (imageShape img)
        1
        ( \ix _ ->
            minimum [norm (zipWith3 (\a b step -> fromIntegral (a - b) * step) ix zero spacing) | zero <- zeros]
        )
