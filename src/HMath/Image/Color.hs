-- SPDX-License-Identifier: MPL-2.0

{- | Three-channel color conversion. sRGB uses the IEC piecewise transfer;
XYZ is D65 with Y=1 for reference white; Lab uses that same D65 white (no
implicit chromatic adaptation). Hue is in turns [0,1), HSV/HSL saturation
and brightness/lightness in [0,1]. Full-range BT.601 YCbCr uses chroma offset
0.5. Out-of-gamut conversions return finite unclipped values; converting
those results back requires the target color space's input domain.
Matrix and Lab definitions: https://www.w3.org/TR/css-color-4/ .
-}
module HMath.Image.Color (ColorSpace (..), convertColor, grayscale, srgbToLinear, linearToSrgb) where

import HMath.Error
import HMath.Image.Core

{- | Color coordinate convention,including sRGB,linear RGB,HSV,HSL,XYZ,Lab,and YCbCr.
convertColor validates each source convention's ranges.
-}
data ColorSpace = SRGB | LinearRGB | HSV | HSL | XYZ | Lab | YCbCr deriving (Eq, Show)

{- | Transfer functions extend linearly below their positive breakpoints;
finite negative/out-of-gamut channels are retained.
-}
srgbToLinear :: Double -> Either MathError Double
srgbToLinear x = do require (finite x) "nonfinite sRGB channel"; scalar (decode x)

{- | Encode a finite linear-light channel with the sRGB piecewise transfer function (linear
branch through 0.0031308). No automatic clipping is performed. Non-finite input/result
returns Left MathError.
-}
linearToSrgb :: Double -> Either MathError Double
linearToSrgb x = do require (finite x) "nonfinite linear RGB channel"; scalar (encode x)

scalar :: Double -> Either MathError Double
scalar x = do _ <- checked [x]; Right x
decode, encode :: Double -> Double
decode x = if x <= 0.04045 then x / 12.92 else ((x + 0.055) / 1.055) ** 2.4
encode x = if x <= 0.0031308 then 12.92 * x else 1.055 * x ** (1 / 2.4) - 0.055

-- | Explicit source/destination spaces; three interleaved channels required.
convertColor :: ColorSpace -> ColorSpace -> Image -> Either MathError Image
convertColor source destination img = do
    require (imageChannels img == 3) "color conversion needs three channels"
    let triples = chunks (imageValues img)
    mapM_ (validateSource source) triples
    result <-
        mapM
            ( \rgb -> do
                linear <- convertTo source rgb
                if destination == HSV || destination == HSL
                    then do
                        encoded <- checked (map encode linear)
                        _ <- checked [maximum encoded - minimum encoded]
                        Right ()
                    else Right ()
                checked (convertFrom destination linear)
            )
            triples
    image (imageShape img) 3 (concat result)
  where
    chunks [] = []
    chunks (a : b : c : rest) = [a, b, c] : chunks rest
    chunks _ = [] -- constructor guarantees channel divisibility

validateSource :: ColorSpace -> [Double] -> Either MathError ()
validateSource space values = case space of
    HSV -> unit
    HSL -> unit
    _ -> Right ()
  where
    unit = require (all (\x -> x >= 0 && x <= 1) values) "HSV/HSL components outside [0,1]"

convertTo :: ColorSpace -> [Double] -> Either MathError [Double]
convertTo space values = do
    let rgb = case (space, values) of
            (SRGB, _) -> map decode values
            (LinearRGB, _) -> values
            (XYZ, _) -> xyzToRGB values
            (Lab, [l, a, b]) ->
                xyzToRGB
                    [ 0.95047 * labInverse ((l + 16) / 116 + a / 500)
                    , labInverse ((l + 16) / 116)
                    , 1.08883 * labInverse ((l + 16) / 116 - b / 200)
                    ]
            (HSV, [h, s, v]) -> map decode (hueRGB h (v * s) (v - v * s))
            (HSL, [h, s, l]) -> let c = (1 - abs (2 * l - 1)) * s in map decode (hueRGB h c (l - c / 2))
            (YCbCr, [y, cb, cr]) ->
                map
                    decode
                    [ y + 1.402 * (cr - 0.5)
                    , y - 0.34413628620102216 * (cb - 0.5) - 0.7141362862010221 * (cr - 0.5)
                    , y + 1.772 * (cb - 0.5)
                    ]
            _ -> []
    checked rgb
convertFrom :: ColorSpace -> [Double] -> [Double]
convertFrom space linear = case (space, linear) of
    (LinearRGB, _) -> linear
    (XYZ, _) -> rgbToXYZ linear
    (Lab, _) -> case rgbToXYZ linear of
        [x, y, z] ->
            let fx = labFunction (x / 0.95047); fy = labFunction y; fz = labFunction (z / 1.08883)
             in [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)]
        _ -> []
    _ ->
        let rgb = map encode linear
         in case (space, rgb) of
                (SRGB, _) -> rgb
                (HSV, [r, g, b]) ->
                    let hi = maximum rgb; lo = minimum rgb; c = hi - lo
                     in [hue r g b hi c, if hi == 0 then 0 else c / hi, hi]
                (HSL, [r, g, b]) ->
                    let hi = maximum rgb; lo = minimum rgb; c = hi - lo; l = (hi + lo) / 2
                     in [hue r g b hi c, if c == 0 then 0 else c / (1 - abs (2 * l - 1)), l]
                (YCbCr, [r, g, b]) -> let y = 0.299 * r + 0.587 * g + 0.114 * b in [y, 0.5 + (b - y) / 1.772, 0.5 + (r - y) / 1.402]
                _ -> []

hue :: Double -> Double -> Double -> Double -> Double -> Double
hue r g b hi chroma
    | chroma == 0 = 0
    | otherwise =
        let sector =
                if hi == r then (g - b) / chroma else if hi == g then (b - r) / chroma + 2 else (r - g) / chroma + 4
            value = sector / 6
         in value - fromIntegral (floor value :: Int)
hueRGB :: Double -> Double -> Double -> [Double]
hueRGB h chroma minimumValue =
    map
        (+ minimumValue)
        ( case sector of
            0 -> [chroma, x, 0]
            1 -> [x, chroma, 0]
            2 -> [0, chroma, x]
            3 -> [0, x, chroma]
            4 -> [x, 0, chroma]
            _ -> [chroma, 0, x]
        )
  where
    turn = (h - fromIntegral (floor h :: Int)) * 6
    sector = floor turn :: Int
    x = chroma * (1 - abs (turn - 2 * fromIntegral (floor (turn / 2) :: Int) - 1))
rgbToXYZ, xyzToRGB :: [Double] -> [Double]
rgbToXYZ [r, g, b] =
    [ 0.4124564 * r + 0.3575761 * g + 0.1804375 * b
    , 0.2126729 * r + 0.7151522 * g + 0.0721750 * b
    , 0.0193339 * r + 0.1191920 * g + 0.9503041 * b
    ]
rgbToXYZ _ = []
xyzToRGB [x, y, z] =
    [ 3.2404542 * x - 1.5371385 * y - 0.4985314 * z
    , (-0.9692660) * x + 1.8760108 * y + 0.0415560 * z
    , 0.0556434 * x - 0.2040259 * y + 1.0572252 * z
    ]
xyzToRGB _ = []
labFunction, labInverse :: Double -> Double
labFunction x = if x > (6 / 29) ^ (3 :: Int) then x ** (1 / 3) else x / (3 * (6 / 29) ^ (2 :: Int)) + 4 / 29
labInverse x = if x > 6 / 29 then x ^ (3 :: Int) else 3 * (6 / 29) ^ (2 :: Int) * (x - 4 / 29)

-- | Rec.709 luminance, explicitly converting the stated source to linear RGB.
grayscale :: ColorSpace -> Image -> Either MathError Image
grayscale source img = do
    linear <- convertColor source LinearRGB img
    build
        (imageShape img)
        1
        (\ix _ -> 0.2126 * at linear ix 0 + 0.7152 * at linear ix 1 + 0.0722 * at linear ix 2)
