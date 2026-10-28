-- SPDX-License-Identifier: MPL-2.0

{- | Direct ND reference filtering and 2D edge detection. Kernel centers are
at floor(size/2); odd extents are required. All boundary policies are
explicit. Work is limited before neighborhood expansion or output allocation.
-}
module HMath.Image.Filter (
    convolve,
    correlate,
    gaussianBlur,
    boxBlur,
    medianBlur,
    bilateralBlur,
    sharpen,
    GradientOperator (..),
    gradient,
    laplacian,
    canny,
    Morphology (..),
    morphology,
    morphologicalGradient,
    validateBoundary,
    scalar2D,
    windowOffsets,
) where

import Control.Monad (foldM)
import Data.List (sort)
import qualified Data.Map.Strict as M
import qualified Data.Set as Set
import HMath.Error
import HMath.Image.Core

validateBoundary :: Boundary -> Either MathError ()
validateBoundary (Constant value) = require (finite value) "nonfinite boundary constant"
validateBoundary _ = Right ()
scalar2D :: Image -> Either MathError (Int, Int)
scalar2D img = do
    require (length (imageShape img) == 2 && imageChannels img == 1) "one-channel 2D image required"
    Right (imageShape img !! 0, imageShape img !! 1)

{- | Correlation uses sample(ix+kernelOffset-center). Convolution reverses all
kernel axes; channels are filtered independently without channel mixing.
-}
correlate :: Boundary -> [Int] -> [Double] -> Image -> Either MathError Image
correlate boundary dims weights img = do
    validateBoundary boundary
    require
        (length dims == length (imageShape img) && all (\d -> d >= 1 && odd d && d <= 65) dims)
        "kernel rank/odd extent invalid"
    let count = product (map toInteger dims)
    require
        ( count <= 4096
            && count == toInteger (length weights)
            && count * toInteger (length (imageValues img)) <= 20000000
        )
        "kernel count/work limit"
    _ <- checked weights
    let offsets = map (\ix -> zipWith (-) ix (map (`div` 2) dims)) (coordinates dims)
        apply ix c = sum [w * sample boundary img (zipWith (+) ix offset) c | (offset, w) <- zip offsets weights]
    build (imageShape img) (imageChannels img) apply

convolve :: Boundary -> [Int] -> [Double] -> Image -> Either MathError Image
convolve boundary dims weights = correlate boundary dims (reverse weights)

-- | Separable Gaussian, truncated at an explicitly supplied integer radius.
gaussianBlur :: Boundary -> Double -> Int -> Image -> Either MathError Image
gaussianBlur boundary sigma radius img = do
    validateBoundary boundary
    require (finite sigma && sigma > 0 && radius >= 0 && radius <= 32) "invalid Gaussian width/radius"
    let raw = [exp (-0.5 * (fromIntegral k / sigma) ^ (2 :: Int)) | k <- [-radius .. radius]]
        weights = map (/ sum raw) raw
        rank = length (imageShape img)
    foldM
        ( \old axis -> correlate boundary [if j == axis then 2 * radius + 1 else 1 | j <- [0 .. rank - 1]] weights old
        )
        img
        [0 .. rank - 1]

windowOffsets :: Int -> Image -> Either MathError [[Int]]
windowOffsets radius img = do
    let rank = length (imageShape img); count = (2 * toInteger radius + 1) ^ rank
    require
        ( radius >= 0
            && radius <= 16
            && count <= 4096
            && count * toInteger (length (imageValues img)) <= 20000000
        )
        "neighborhood/work limit"
    Right (map (map (subtract radius)) (coordinates (replicate rank (2 * radius + 1))))
boxBlur :: Boundary -> Int -> Image -> Either MathError Image
boxBlur boundary radius img = do
    validateBoundary boundary
    offsets <- windowOffsets radius img
    build
        (imageShape img)
        (imageChannels img)
        ( \ix c ->
            sum
                [sample boundary img (zipWith (+) ix offset) c / fromIntegral (length offsets) | offset <- offsets]
        )
medianBlur :: Boundary -> Int -> Image -> Either MathError Image
medianBlur boundary radius img = do
    validateBoundary boundary
    offsets <- windowOffsets radius img
    build
        (imageShape img)
        (imageChannels img)
        ( \ix c ->
            sort [sample boundary img (zipWith (+) ix offset) c | offset <- offsets] !! (length offsets `div` 2)
        )

{- | Per-channel bilateral filtering: spatial and range Gaussian weights are
multiplied, normalized locally, and computed relative to the center sample.
-}
bilateralBlur :: Boundary -> Double -> Double -> Int -> Image -> Either MathError Image
bilateralBlur boundary spatialSigma rangeSigma radius img = do
    validateBoundary boundary
    require
        (all (\x -> finite x && x > 0) [spatialSigma, rangeSigma])
        "positive bilateral scales required"
    offsets <- windowOffsets radius img
    let apply ix c =
            let center = at img ix c
                weighted =
                    [ (weight, value)
                    | offset <- offsets
                    , let value = sample boundary img (zipWith (+) ix offset) c
                    , let weight =
                            exp
                                ( -0.5
                                    * ( sum [(fromIntegral d / spatialSigma) ^ (2 :: Int) | d <- offset]
                                            + ((value - center) / rangeSigma) ^ (2 :: Int)
                                      )
                                )
                    ]
                den = sum (map fst weighted)
             in sum [w / den * v | (w, v) <- weighted]
    build (imageShape img) (imageChannels img) apply

-- | Unsharp mask x+amount*(x-Gaussian(x)); no implicit range clipping.
sharpen :: Boundary -> Double -> Double -> Int -> Image -> Either MathError Image
sharpen boundary amount sigma radius img = do
    require (finite amount && amount >= 0) "invalid sharpening amount"
    blurred <- gaussianBlur boundary sigma radius img
    zipImage (\x y -> x + amount * (x - y)) img blurred

data GradientOperator = Sobel | Prewitt | Scharr deriving (Eq, Show)

{- | Returns row derivative, column derivative, magnitude, and atan2(row,col)
direction in radians. Smoothing/derivative kernels are normalized so an
interior unit ramp has derivative one.
-}
gradient :: GradientOperator -> Boundary -> Image -> Either MathError (Image, Image, Image, Image)
gradient operator boundary img = do
    _ <- scalar2D img
    let smooth = case operator of Sobel -> [1, 2, 1]; Prewitt -> [1, 1, 1]; Scharr -> [3, 10, 3]
        scale = 2 * sum smooth
        rowKernel = [d * s / scale | d <- [-1, 0, 1], s <- smooth]
        colKernel = [s * d / scale | s <- smooth, d <- [-1, 0, 1]]
    dr <- correlate boundary [3, 3] rowKernel img
    dc <- correlate boundary [3, 3] colKernel img
    mag <-
        zipImage
            ( \a b ->
                let m = max (abs a) (abs b)
                 in if m == 0 then 0 else m * sqrt ((a / m) ^ (2 :: Int) + (b / m) ^ (2 :: Int))
            )
            dr
            dc
    angle <- zipImage atan2 dr dc
    Right (dr, dc, mag, angle)

laplacian :: Boundary -> Image -> Either MathError Image
laplacian boundary img = do _ <- scalar2D img; correlate boundary [3, 3] [0, 1, 0, 1, -4, 1, 0, 1, 0] img

{- | Canny: Gaussian smoothing, Sobel gradient, four-direction nonmaximum
suppression, and 8-connected hysteresis. low/high are absolute normalized
gradient magnitudes, not quantiles. Output is exactly zero or one.
-}
canny :: Boundary -> Double -> Int -> Double -> Double -> Image -> Either MathError Image
canny boundary sigma radius low high img = do
    (height, width) <- scalar2D img
    require (all finite [low, high] && low >= 0 && high >= low) "invalid Canny thresholds"
    smoothed <- gaussianBlur boundary sigma radius img
    (_, _, mag, angle) <- gradient Sobel boundary smoothed
    let suppressed i j =
            let a = at angle [i, j] 0
                direction = (round (a / (pi / 4)) :: Int) `mod` 4
                (di, dj) = case direction of 0 -> (0, 1); 1 -> (1, 1); 2 -> (1, 0); _ -> (1, -1)
                v = at mag [i, j] 0
             in if v >= sample (Constant 0) mag [i + di, j + dj] 0 && v >= sample (Constant 0) mag [i - di, j - dj] 0
                    then v
                    else 0
        values = M.fromList [((i, j), suppressed i j) | i <- [0 .. height - 1], j <- [0 .. width - 1]]
        weak = Set.fromList [ij | (ij, v) <- M.toList values, v > 0 && v >= low]
        strong = Set.fromList [ij | (ij, v) <- M.toList values, v > 0 && v >= high]
        flood [] visited = visited
        flood ((i, j) : queue) visited =
            let next =
                    [ (i + di, j + dj)
                    | di <- [-1 .. 1]
                    , dj <- [-1 .. 1]
                    , (di, dj) /= (0, 0)
                    , Set.member (i + di, j + dj) weak
                    , Set.notMember (i + di, j + dj) visited
                    ]
             in flood (next ++ queue) (foldr Set.insert visited next)
        edges = flood (Set.toList strong) strong
    build [height, width] 1 (\ix _ -> if Set.member (ix !! 0, ix !! 1) edges then 1 else 0)

data Morphology = Erosion | Dilation | Opening | Closing deriving (Eq, Show)

{- | Flat grayscale morphology with an explicit odd-rank Boolean footprint.
Erosion samples x+offset; dilation samples x-offset (reflected footprint),
so asymmetric footprints obey the usual adjunction. Opening/closing compose
these operators under the same caller-selected boundary extension.
-}
morphology :: Morphology -> Boundary -> [Int] -> [Bool] -> Image -> Either MathError Image
morphology operation boundary dims footprint img = do
    validateBoundary boundary
    require
        ( length dims == length (imageShape img)
            && all (\d -> d >= 1 && odd d && d <= 33) dims
            && product (map toInteger dims) == toInteger (length footprint)
            && any id footprint
            && length footprint <= 4096
        )
        "invalid morphology footprint"
    require
        (toInteger (length footprint) * toInteger (length (imageValues img)) <= 20000000)
        "morphology work limit"
    let center = map (`div` 2) dims
        offsets = [zipWith (-) ix center | (ix, True) <- zip (coordinates dims) footprint]
        erode old =
            build
                (imageShape old)
                (imageChannels old)
                (\ix c -> minimum [sample boundary old (zipWith (+) ix o) c | o <- offsets])
        dilate old =
            build
                (imageShape old)
                (imageChannels old)
                (\ix c -> maximum [sample boundary old (zipWith (-) ix o) c | o <- offsets])
    case operation of
        Erosion -> erode img
        Dilation -> dilate img
        Opening -> erode img >>= dilate
        Closing -> dilate img >>= erode

morphologicalGradient :: Boundary -> [Int] -> [Bool] -> Image -> Either MathError Image
morphologicalGradient boundary dims footprint img = do
    dilated <- morphology Dilation boundary dims footprint img
    eroded <- morphology Erosion boundary dims footprint img
    zipImage (-) dilated eroded
