-- SPDX-License-Identifier: MPL-2.0

{- | Explicit INT8 quantization and software FP16/BF16 matrix multiplication.
Integer GEMM accumulates exact integers, then applies scales; it rejects
signed-32-bit accumulator overflow. Half inputs round ties to even, with FP32
accumulation and one final conversion to Double. Mixed precision retains
Double master weights; unscale/overflow decisions happen before any update.
-}
module HMath.DeepLearning.Precision (
    Quantization (..),
    QuantizedTensor,
    quantize,
    dequantize,
    quantizedValues,
    quantizationScales,
    quantizationZeroPoints,
    int8Gemm,
    Precision (..),
    reducedGemm,
    LossScaler (..),
    initialLossScaler,
    scaleLoss,
    unscaleGradients,
    updateLossScaler,
    gradientNorm,
    clipGradients,
) where

import Data.Int (Int32, Int8)
import qualified HMath.Autodiff as AD
import HMath.Error
import qualified HMath.Numeric as N
import qualified HMath.Tensor as T

data Quantization = Symmetric | Asymmetric deriving (Eq, Show)
data QuantizedTensor = QuantizedTensor [Int] (Maybe Int) [Double] [Int] [Int8] deriving (Eq, Show)

-- | Return signed INT8 storage in logical row-major order.
quantizedValues :: QuantizedTensor -> [Int8]
quantizedValues (QuantizedTensor _ _ _ _ xs) = xs

-- | Return one positive scale per calibrated channel, or a single per-tensor scale.
quantizationScales :: QuantizedTensor -> [Double]
quantizationScales (QuantizedTensor _ _ xs _ _) = xs

-- | Return integer zero offsets under the selected symmetric/asymmetric calibration.
quantizationZeroPoints :: QuantizedTensor -> [Int]
quantizationZeroPoints (QuantizedTensor _ _ _ xs _) = xs

finite :: [Double] -> Either MathError ()
finite xs = if all (\x -> not (isNaN x || isInfinite x)) xs then Right () else Left NonFiniteResult
indices :: [Int] -> [[Int]]
indices [] = [[]]
indices (d : ds) = [i : is | i <- [0 .. d - 1], is <- indices ds]

-- | Calibrate finite nonempty values per tensor or selected axis. Symmetric uses [-127,127], asymmetric [-128,127], with ties-to-even rounding.
quantize :: Quantization -> Maybe Int -> T.Tensor Double -> Either MathError QuantizedTensor
quantize scheme axis input = do
    let shape = T.tensorShape input; values = T.tensorValues input
    finite values
    if null values || maybe False (\a -> a < 0 || a >= length shape) axis
        then Left (InvalidArgument "quantization empty tensor/axis")
        else Right ()
    let channels = maybe 1 (shape !!) axis
        group ix = maybe 0 (ix !!) axis
        samples c = [v | (ix, v) <- zip (indices shape) values, group ix == c]
        calibrate xs =
            let lo = min 0 (minimum xs); hi = max 0 (maximum xs)
             in case scheme of
                    Symmetric -> (if max (abs lo) (abs hi) == 0 then 1 else max (abs lo) (abs hi) / 127, 0)
                    Asymmetric ->
                        let s = if hi == lo then 1 else (hi - lo) / 255; z = max (-128) (min 127 (round (-128 - lo / s)))
                         in (s, z)
        params = map (calibrate . samples) [0 .. channels - 1]
        quantized =
            [ let (scale, zero) = params !! group ix; low = if scheme == Symmetric then -127 else -128
               in fromIntegral (max low (min 127 (round (v / scale) + zero)))
            | (ix, v) <- zip (indices shape) values
            ]
    finite (map fst params)
    if any ((<= 0) . fst) params
        then Left (DomainError "quantization scale underflow")
        else Right (QuantizedTensor shape axis (map fst params) (map snd params) quantized)

-- | Decode owned INT8 values using scale*(q-zeroPoint), rejecting floating arithmetic overflow.
dequantize :: QuantizedTensor -> Either MathError (T.Tensor Double)
dequantize (QuantizedTensor shape axis scales zeros values) = do
    let decoded =
            [ let channel = maybe 0 (ix !!) axis
               in scales !! channel * fromIntegral (fromIntegral v - (zeros !! channel) :: Int)
            | (ix, v) <- zip (indices shape) values
            ]
    finite decoded
    T.tensor shape decoded

-- | Multiply two INT8 matrices with exact integer accumulation; supports per-row A/per-column B or per-tensor scales.
int8Gemm :: QuantizedTensor -> QuantizedTensor -> Either MathError (T.Tensor Double)
int8Gemm (QuantizedTensor [m, k] aa as az av) (QuantizedTensor [inner, n] ba bs bz bv)
    | k /= inner || maybe False (/= 0) aa || maybe False (/= 1) ba =
        Left (InvalidArgument "INT8 GEMM requires A per-row/B per-column or per-tensor scales")
    | otherwise = do
        vals <-
            mapM
                ( \(i, j) -> do
                    let ai = maybe 0 (const i) aa
                        bj = maybe 0 (const j) ba
                        accum =
                            sum
                                [ (toInteger (av !! (i * k + t)) - toInteger (az !! ai))
                                    * (toInteger (bv !! (t * n + j)) - toInteger (bz !! bj))
                                | t <- [0 .. k - 1]
                                ]
                    if accum < toInteger (minBound :: Int32) || accum > toInteger (maxBound :: Int32)
                        then Left (DomainError "INT8 GEMM accumulator overflow")
                        else Right (fromInteger accum * (as !! ai) * (bs !! bj))
                )
                [(i, j) | i <- [0 .. m - 1], j <- [0 .. n - 1]]
        finite vals
        T.tensor [m, n] vals
int8Gemm _ _ = Left (InvalidArgument "INT8 GEMM expects matrices")

data Precision = FP16 | BF16 deriving (Eq, Show)

-- | Round operands to the chosen 16-bit format, accumulate in Float32, and return checked Double values.
reducedGemm :: Precision -> T.Tensor Double -> T.Tensor Double -> Either MathError (T.Tensor Double)
reducedGemm precision a b = do
    finite (T.tensorValues a ++ T.tensorValues b)
    case (T.tensorShape a, T.tensorShape b) of
        ([m, k], [inner, n]) | k == inner -> do
            let convert x = case precision of
                    FP16 -> let N.Rounded y _ = N.float16 N.NearestEven x in N.fromFloat16 y
                    BF16 -> let N.Rounded y _ = N.bfloat16 N.NearestEven x in N.fromBFloat16 y
                av = map convert (T.tensorValues a)
                bv = map convert (T.tensorValues b)
                fp32 x = realToFrac x :: Float
                vals =
                    [ realToFrac (foldl' (+) 0 [fp32 (av !! (i * k + t)) * fp32 (bv !! (t * n + j)) | t <- [0 .. k - 1]])
                    | i <- [0 .. m - 1]
                    , j <- [0 .. n - 1]
                    ]
            finite (av ++ bv ++ vals)
            T.tensor [m, n] vals
        _ -> Left (InvalidArgument "reduced GEMM expects conformable matrices")

data LossScaler = LossScaler {lossScale :: Double, scaleGrowthInterval :: Int, finiteSteps :: Int}
    deriving (Eq, Show)

-- | Create a positive finite loss scale and positive growth interval; zero accumulated finite steps.
initialLossScaler :: Double -> Int -> Either MathError LossScaler
initialLossScaler scale interval = do
    finite [scale]
    if scale <= 0 || interval < 1
        then Left (InvalidArgument "loss scaler scale/interval")
        else Right (LossScaler scale interval 0)

-- | Multiply a finite loss by the checked current scale; overflow is a structured failure.
scaleLoss :: LossScaler -> Double -> Either MathError Double
scaleLoss state loss = do
    _ <- initialLossScaler (lossScale state) (scaleGrowthInterval state)
    finite [loss, loss * lossScale state]
    Right (loss * lossScale state)

{- | False means overflow: every caller must skip the entire optimizer update.
Gradients are returned only when every scaled gradient is finite.
-}
unscaleGradients :: LossScaler -> [Double] -> Either MathError (Bool, [Double])
unscaleGradients state gradients = do
    _ <- initialLossScaler (lossScale state) (scaleGrowthInterval state)
    if any (\x -> isNaN x || isInfinite x) gradients
        then Right (False, [])
        else do
            let gs = map (/ lossScale state) gradients
            finite gs
            Right (True, gs)

-- | Halve scale after overflow; double after growthInterval finite updates, with a bounded maximum.
updateLossScaler :: Bool -> LossScaler -> Either MathError LossScaler
updateLossScaler successful state = do
    _ <- initialLossScaler (lossScale state) (scaleGrowthInterval state)
    if finiteSteps state < 0 then Left (InvalidArgument "negative finite scaler steps") else Right ()
    let steps = if successful then finiteSteps state + 1 else 0
        grow = steps >= scaleGrowthInterval state
        scale =
            if not successful
                then max 1 (lossScale state / 2)
                else if grow then min (2 ** 120) (lossScale state * 2) else lossScale state
    Right (LossScaler scale (scaleGrowthInterval state) (if grow then 0 else steps))

-- | Compute a checked scaled Euclidean norm; unrepresentable final norms fail explicitly.
gradientNorm :: [Double] -> Either MathError Double
gradientNorm xs = do
    finite xs
    let m = maximum (0 : map abs xs)
        y = if m == 0 then 0 else m * sqrt (sum [(x / m) ^ (2 :: Int) | x <- xs])
    finite [y]
    Right y

-- | Clip norm through the shared overflow-safe automatic-differentiation gradient utility.
clipGradients :: Double -> [Double] -> Either MathError [Double]
clipGradients = AD.clipGradient
