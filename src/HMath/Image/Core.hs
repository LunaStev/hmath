-- SPDX-License-Identifier: MPL-2.0

{- | Finite CPU images with row-major spatial axes and interleaved channels
(last axis). Spatial rank is 1–8, channel count 1–16, and total storage at most
262,144 samples. Dimensions are positive; empty images are explicit errors.
The immutable constructor owns storage. Intensities have no implicit range;
color-space and histogram functions state their stricter range contracts.
-}
module HMath.Image.Core (
    Image,
    image,
    fromTensor,
    toTensor,
    imageShape,
    imageChannels,
    imageValues,
    pixel,
    channel,
    combineChannels,
    mapImage,
    zipImage,
    normalize,
    brightness,
    contrast,
    gamma,
    Boundary (..),
    coordinates,
    sample,
    build,
    at,
    spatialSize,
    finite,
    require,
    checked,
) where

import Data.Array (Array, elems, listArray, (!))
import HMath.Error
import qualified HMath.Tensor as T

{- | Opaque finite CPU image with row-major spatial axes and interleaved channels. Construct
with image; shape/channel/storage limits are checked.
-}
data Image = Image [Int] Int (Array Int Double) deriving (Eq, Show)

-- | Test whether Double is neither NaN nor infinite.
finite :: Double -> Bool
finite x = not (isNaN x || isInfinite x)

{- | Given predicate then diagnostic, return Right () or image-prefixed Left
InvalidArgument.
-}
require :: Bool -> String -> Either MathError ()
require p message = if p then Right () else Left (InvalidArgument ("image: " ++ message))

{- | Return finite Double values unchanged, or Left NonFiniteResult when any sample is
non-finite.
-}
checked :: [Double] -> Either MathError [Double]
checked values = if all finite values then Right values else Left NonFiniteResult

-- | Validate all dimensions before allocating boxed immutable array storage.
image :: [Int] -> Int -> [Double] -> Either MathError Image
image dims channels values = do
    require
        (not (null dims) && length dims <= 8 && all (> 0) dims && channels >= 1 && channels <= 16)
        "invalid spatial/channel shape"
    let count = product (map toInteger dims) * toInteger channels
    require
        (count <= 262144 && count == toInteger (length values))
        "sample count mismatch or storage limit"
    _ <- checked values
    Right (Image dims channels (listArray (0, length values - 1) values))

-- | Tensor shape must be spatial dimensions followed by a channel axis.
fromTensor :: T.Tensor Double -> Either MathError Image
fromTensor tensor = do
    let dims = T.tensorShape tensor
    require (length dims >= 2) "tensor needs spatial and channel axes"
    image (init dims) (last dims) (T.tensorValues tensor)

{- | Copy an image to Tensor Double with shape spatial dimensions followed by channel count.
Values remain row-major with interleaved channels; checked tensor size errors
propagate.
-}
toTensor :: Image -> Either MathError (T.Tensor Double)
toTensor img = T.tensor (imageShape img ++ [imageChannels img]) (imageValues img)

-- | Return spatial dimensions only, excluding the last implicit channel axis.
imageShape :: Image -> [Int]
imageShape (Image dims _ _) = dims

-- | Return channel count, between one and sixteen for validated images.
imageChannels :: Image -> Int
imageChannels (Image _ channels _) = channels

-- | Return flat row-major samples with channels interleaved at each spatial coordinate.
imageValues :: Image -> [Double]
imageValues (Image _ _ values) = elems values

-- | Return number of spatial pixels (shape product), excluding channel multiplicity.
spatialSize :: Image -> Int
spatialSize = product . imageShape

{- | Enumerate zero-based row-major coordinates of a dimension list. [] yields [[]];
zero/negative extents yield no coordinates. This helper performs no image validation.
-}
coordinates :: [Int] -> [[Int]]
coordinates [] = [[]]
coordinates (d : ds) = [i : is | i <- [0 .. d - 1], is <- coordinates ds]

-- Internal indexing kernel: callers must have checked rank/range and channel.

{- | Unchecked image access: given image,complete spatial coordinates,then channel, return
one sample. Checked callers must validate rank/ranges; invalid indices can raise an
array error.
-}
at :: Image -> [Int] -> Int -> Double
at (Image dims channels values) ix c = values ! (foldl (\acc (i, d) -> acc * d + i) 0 (zip ix dims) * channels + c)

{- | Given image then complete spatial coordinates, return all channel values in order.
Invalid coordinate rank/range returns Left InvalidArgument.
-}
pixel :: Image -> [Int] -> Either MathError [Double]
pixel img ix = do
    require
        (length ix == length (imageShape img) && and (zipWith (\i d -> i >= 0 && i < d) ix (imageShape img)))
        "pixel index out of range"
    Right [at img ix c | c <- [0 .. imageChannels img - 1]]

{- | Given zero-based channel index then image, return a copied one-channel image of the
same spatial shape. Invalid channel index fails.
-}
channel :: Int -> Image -> Either MathError Image
channel c img = do
    require (c >= 0 && c < imageChannels img) "channel index out of range"
    image (imageShape img) 1 [at img ix c | ix <- coordinates (imageShape img)]

{- | Concatenate channels of a nonempty same-spatial-shape image list in input order.
Require total channels\<=16; shape/count or checked storage limits fail.
-}
combineChannels :: [Image] -> Either MathError Image
combineChannels images = do
    require (not (null images)) "no channels to combine"
    let dims = imageShape ((!! 0) images); count = sum (map imageChannels images)
    require (all ((== dims) . imageShape) images && count <= 16) "channel shapes/count mismatch"
    image
        dims
        count
        [at img ix c | ix <- coordinates dims, img <- images, c <- [0 .. imageChannels img - 1]]

-- | Output is validated, including arithmetic overflow inside the callback.
mapImage :: (Double -> Double) -> Image -> Either MathError Image
mapImage f img = image (imageShape img) (imageChannels img) (map f (imageValues img))

{- | Given binary sample function then equally shaped/channel-count images, return a new
validated image. Mismatched shape/channels or non-finite output returns Left MathError.
-}
zipImage :: (Double -> Double -> Double) -> Image -> Image -> Either MathError Image
zipImage f a b = do
    require (imageShape a == imageShape b && imageChannels a == imageChannels b) "image shape mismatch"
    image (imageShape a) (imageChannels a) (zipWith f (imageValues a) (imageValues b))

-- | Global min/max scaling; a constant image maps to the requested lower bound.
normalize :: Double -> Double -> Image -> Either MathError Image
normalize lo hi img = do
    require (finite lo && finite hi && lo <= hi) "invalid normalization range"
    let values = imageValues img
        a = minimum values
        b = maximum values
        ratio x = if finite (b - a) then (x - a) / (b - a) else (x / 2 - a / 2) / (b / 2 - a / 2)
    mapImage (\x -> if a == b then lo else (1 - ratio x) * lo + ratio x * hi) img

-- | Add a finite offset without implicit clipping.
brightness :: Double -> Image -> Either MathError Image
brightness offset img = do require (finite offset) "nonfinite brightness"; mapImage (+ offset) img

-- | Scale about a caller-defined pivot, without clipping.
contrast :: Double -> Double -> Image -> Either MathError Image
contrast factor pivot img = do
    require (all finite [factor, pivot] && factor >= 0) "invalid contrast"
    mapImage (\x -> pivot + factor * (x - pivot)) img

-- | Positive gamma, nonnegative inputs; computes x^gamma without clipping.
gamma :: Double -> Image -> Either MathError Image
gamma power img = do
    require
        (finite power && power > 0 && all (>= 0) (imageValues img))
        "gamma needs positive exponent/nonnegative data"
    mapImage (** power) img

{- | Image sampling policy: Constant fill,edge Clamp,half-sample symmetric Reflect,or
periodic Wrap.
-}
data Boundary = Constant Double | Clamp | Reflect | Wrap deriving (Eq, Show)

{- | Reflect is half-sample symmetric (... b a | a b c | c b ...).
Boundary rank/channel validation belongs to the checked filter/warp caller.
-}
sample :: Boundary -> Image -> [Int] -> Int -> Double
sample boundary img ix c
    | all inside (zip ix dims) = at img ix c
    | otherwise = case boundary of
        Constant value -> value
        _ -> at img (zipWith convert ix dims) c
  where
    dims = imageShape img
    inside (i, d) = i >= 0 && i < d
    convert i d = case boundary of
        Clamp -> max 0 (min (d - 1) i)
        Wrap -> i `mod` d
        Reflect -> let j = i `mod` (2 * d) in if j < d then j else 2 * d - 1 - j
        Constant _ -> i

-- | Checked output allocation for internal coordinate-wise reference kernels.
build :: [Int] -> Int -> ([Int] -> Int -> Double) -> Either MathError Image
build dims channels f = do
    require
        ( not (null dims)
            && length dims <= 8
            && all (> 0) dims
            && channels >= 1
            && channels <= 16
            && product (map toInteger dims) * toInteger channels <= 262144
        )
        "output shape/storage limit"
    image dims channels [f ix c | ix <- coordinates dims, c <- [0 .. channels - 1]]
