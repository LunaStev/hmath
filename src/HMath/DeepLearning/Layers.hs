-- SPDX-License-Identifier: MPL-2.0

{- | Row-major CPU layers. Convolution/pooling layout is N,C,spatial (1–3
spatial axes), weights are Cout,Cin/groups,kernel, or Cin,Cout/groups,kernel
for transpose convolution. Padding is symmetric and zero-filled. Attention
layout is sequence,feature; True in a mask means allowed. Fully masked rows
produce exact zero outputs and weights. No ambient training state exists.
-}
module HMath.DeepLearning.Layers (
    Training (..),
    dropout,
    spatialDropout,
    BatchNormState (..),
    batchNorm,
    layerNorm,
    instanceNorm,
    groupNorm,
    rmsNorm,
    weightNorm,
    Initializer (..),
    initializeWeights,
    embedding,
    dense,
    denseAD,
    ConvOptions (..),
    convolution,
    transposedConvolution,
    depthwiseConvolution,
    convolutionAD,
    PoolMode (..),
    pooling,
    adaptivePooling,
    globalPooling,
    scaledDotProductAttention,
    multiheadAttention,
    causalMask,
    rotaryEmbedding,
    sinusoidalEncoding,
    alibiBias,
    KVCache,
    emptyCache,
    appendCache,
    cacheValues,
    transformerFeedForward,
    layerNormAD,
    rmsNormAD,
    scaledDotProductAttentionAD,
) where

import Control.Monad (foldM)
import Data.List (nub)
import qualified HMath.Autodiff as AD
import HMath.DeepLearning.Core (Activation, activation, softmax, softmaxExpr)
import HMath.Error
import HMath.Random (RNG, normal, sampleN, uniform)
import qualified HMath.Tensor as T

data Training = Training | Inference deriving (Eq, Show)
finite :: [Double] -> Either MathError ()
finite xs = if all (\x -> not (isNaN x || isInfinite x)) xs then Right () else Left NonFiniteResult
validTensor :: T.Tensor Double -> Either MathError ()
validTensor = finite . T.tensorValues
indices :: [Int] -> [[Int]]
indices [] = [[]]
indices (d : ds) = [i : is | i <- [0 .. d - 1], is <- indices ds]
flat :: [Int] -> [Int] -> Int
flat shape ix = sum (zipWith (*) ix (drop 1 (scanr (*) 1 shape)))
get :: T.Tensor a -> [Int] -> a
get t ix = T.tensorValues t !! flat (T.tensorShape t) ix
checkedMake :: [Int] -> [Double] -> Either MathError (T.Tensor Double)
checkedMake shape values = do finite values; T.tensor shape values

{- | Inverted dropout. Inference consumes no random numbers. Return a separate
multiplicative mask so its exact graph can be replayed by backpropagation.
-}
dropout ::
    Training ->
    Double ->
    RNG ->
    T.Tensor Double ->
    Either MathError (T.Tensor Double, T.Tensor Double, RNG)
dropout mode probability rng input = do
    validTensor input
    finite [probability]
    if probability < 0 || probability >= 1
        then Left (DomainError "dropout probability must be in [0,1)")
        else Right ()
    let draw (xs, s) _ = let (u, t) = uniform s in (xs ++ [if u < probability then 0 else 1 / (1 - probability)], t)
        (mask, state) =
            if mode == Inference
                then (replicate (T.numel input) 1, rng)
                else foldl' draw ([], rng) [1 .. T.numel input]
    m <- T.tensor (T.tensorShape input) mask
    y <- checkedMake (T.tensorShape input) (zipWith (*) (T.tensorValues input) mask)
    Right (y, m, state)

-- | Sample one inverted dropout mask per N,C pair and share it across every spatial position.
spatialDropout ::
    Training ->
    Double ->
    RNG ->
    T.Tensor Double ->
    Either MathError (T.Tensor Double, T.Tensor Double, RNG)
spatialDropout mode probability rng input = case T.tensorShape input of
    n : c : spatial | not (null spatial) -> do
        prototype <- T.tensor [n, c] (replicate (n * c) 1)
        (_, mask, state) <- dropout mode probability rng prototype
        expanded <-
            T.tensor (n : c : replicate (length spatial) 1) (T.tensorValues mask)
                >>= T.broadcastTo (T.tensorShape input)
        output <-
            checkedMake (T.tensorShape input) (zipWith (*) (T.tensorValues input) (T.tensorValues expanded))
        Right (output, expanded, state)
    _ -> Left (InvalidArgument "spatial dropout requires N,C,spatial")

data BatchNormState = BatchNormState {runningMean :: [Double], runningVariance :: [Double], batchesSeen :: Int}
    deriving (Eq, Show)

{- | Population variance normalizes a training batch; unbiased sample variance
updates runningVariance (a one-element batch uses population variance).
-}
batchNorm ::
    Training ->
    Double ->
    Double ->
    [Double] ->
    [Double] ->
    BatchNormState ->
    T.Tensor Double ->
    Either MathError (T.Tensor Double, BatchNormState)
batchNorm mode momentum eps gamma beta state input = case T.tensorShape input of
    n : c : spatial -> do
        validTensor input
        finite (momentum : eps : gamma ++ beta ++ runningMean state ++ runningVariance state)
        if c <= 0
            || n <= 0
            || product spatial <= 0
            || length gamma /= c
            || length beta /= c
            || length (runningMean state) /= c
            || length (runningVariance state) /= c
            || momentum < 0
            || momentum > 1
            || eps <= 0
            || batchesSeen state < 0
            || any (< 0) (runningVariance state)
            then Left (InvalidArgument "batch normalization shape/state/options")
            else Right ()
        let perChannel = n * product spatial
            groups =
                [ [get input (batch : channel : ix) | batch <- [0 .. n - 1], ix <- indices spatial]
                | channel <- [0 .. c - 1]
                ]
            means = map (\xs -> sum xs / fromIntegral perChannel) groups
            variances = zipWith (\m xs -> sum [(x - m) ^ (2 :: Int) | x <- xs] / fromIntegral perChannel) means groups
            (usedMean, usedVariance) = if mode == Training then (means, variances) else (runningMean state, runningVariance state)
            update old new = (1 - momentum) * old + momentum * new
            unbiased =
                map
                    (* (if perChannel > 1 then fromIntegral perChannel / fromIntegral (perChannel - 1) else 1))
                    variances
            state' =
                if mode == Training
                    then
                        BatchNormState
                            (zipWith update (runningMean state) means)
                            (zipWith update (runningVariance state) unbiased)
                            (batchesSeen state + 1)
                    else state
        output <-
            checkedMake
                (T.tensorShape input)
                [ (gamma !! channel) * (get input ix - usedMean !! channel) / sqrt (usedVariance !! channel + eps)
                    + beta !! channel
                | ix@(_ : channel : _) <- indices (T.tensorShape input)
                ]
        Right (output, state')
    _ -> Left (InvalidArgument "batch normalization requires N,C,...")

normalizeBy ::
    Bool -> Double -> ([Int] -> Int) -> T.Tensor Double -> Either MathError (T.Tensor Double)
normalizeBy rms eps group input = do
    validTensor input
    finite [eps]
    if eps <= 0 || T.numel input == 0
        then Left (InvalidArgument "normalization epsilon/empty input")
        else Right ()
    let allIx = indices (T.tensorShape input)
        ids = map group allIx
        stats =
            [ let xs = [get input ix | ix <- allIx, group ix == g]
                  mean = if rms then 0 else sum xs / fromIntegral (length xs)
                  variance = sum [(x - mean) ^ (2 :: Int) | x <- xs] / fromIntegral (length xs)
               in (g, (mean, variance))
            | g <- nub ids
            ]
        values =
            [ let (mean, variance) = maybe (0, 0) id (lookup (group ix) stats)
               in (get input ix - mean) / sqrt (variance + eps)
            | ix <- allIx
            ]
    checkedMake (T.tensorShape input) values

-- | Normalize the selected number of trailing axes independently for each remaining prefix index.
layerNorm :: Int -> Double -> T.Tensor Double -> Either MathError (T.Tensor Double)
layerNorm axes eps input
    | axes < 1 || axes > length shape = Left (InvalidArgument "layer norm trailing axis count")
    | otherwise =
        normalizeBy False eps (flat (take (length shape - axes) shape) . take (length shape - axes)) input
  where
    shape = T.tensorShape input

-- | Divide trailing-axis groups by sqrt(mean(x*x)+epsilon), without subtracting a mean.
rmsNorm :: Int -> Double -> T.Tensor Double -> Either MathError (T.Tensor Double)
rmsNorm axes eps input
    | axes < 1 || axes > length shape = Left (InvalidArgument "RMS norm trailing axis count")
    | otherwise =
        normalizeBy True eps (flat (take (length shape - axes) shape) . take (length shape - axes)) input
  where
    shape = T.tensorShape input

-- | Normalize spatial axes separately per batch/channel in N,C,spatial layout.
instanceNorm :: Double -> T.Tensor Double -> Either MathError (T.Tensor Double)
instanceNorm eps input = case T.tensorShape input of
    _ : c : spatial | not (null spatial) -> normalizeBy False eps (\ix -> ix !! 0 * c + ix !! 1) input
    _ -> Left (InvalidArgument "instance norm requires N,C,spatial")

-- | Normalize channels/spatial positions per batch and channel group; channel count must be divisible by groups.
groupNorm :: Int -> Double -> T.Tensor Double -> Either MathError (T.Tensor Double)
groupNorm groups eps input = case T.tensorShape input of
    _ : c : _
        | groups > 0 && c > 0 && c `mod` groups == 0 ->
            normalizeBy False eps (\ix -> ix !! 0 * groups + ix !! 1 `div` (c `div` groups)) input
    _ -> Left (InvalidArgument "group norm channel/group shape")

-- | Normalize each selected-axis slice and multiply it by the matching explicit magnitude; zero directions fail.
weightNorm :: Int -> [Double] -> T.Tensor Double -> Either MathError (T.Tensor Double)
weightNorm axis magnitudes input = do
    validTensor input
    finite magnitudes
    let shape = T.tensorShape input
    if axis < 0 || axis >= length shape || length magnitudes /= shape !! axis
        then Left (InvalidArgument "weight norm axis/magnitude shape")
        else Right ()
    let allIx = indices shape
        norms =
            [ sqrt (sum [get input ix ^ (2 :: Int) | ix <- allIx, ix !! axis == i])
            | i <- [0 .. shape !! axis - 1]
            ]
    if any (== 0) norms
        then Left (DomainError "weight normalization zero direction")
        else
            checkedMake
                shape
                [get input ix * (magnitudes !! (ix !! axis)) / (norms !! (ix !! axis)) | ix <- allIx]

data Initializer
    = XavierUniform
    | XavierNormal
    | KaimingUniform
    | KaimingNormal
    | Orthogonal Double
    | TruncatedNormal Double Double Double
    deriving (Eq, Show)

-- | Generate an immutable tensor and advanced RNG. Fans are explicit; orthogonal initialization requires a positive matrix shape.
initializeWeights ::
    Initializer -> Int -> Int -> [Int] -> RNG -> Either MathError (T.Tensor Double, RNG)
initializeWeights kind fanIn fanOut shape rng = do
    count <- T.shapeSize shape
    if fanIn < 1 || fanOut < 1
        then Left (InvalidArgument "positive initialization fan counts")
        else Right ()
    let std = case kind of
            XavierNormal -> sqrt (2 / (fromIntegral fanIn + fromIntegral fanOut))
            _ -> sqrt (2 / fromIntegral fanIn)
        bound = case kind of
            XavierUniform -> sqrt (6 / (fromIntegral fanIn + fromIntegral fanOut))
            _ -> sqrt (6 / fromIntegral fanIn)
        uniformDraw s = let (u, t) = uniform s in Right ((2 * u - 1) * bound, t)
    (values, state) <- case kind of
        XavierUniform -> sampleN count uniformDraw rng
        KaimingUniform -> sampleN count uniformDraw rng
        XavierNormal -> sampleN count (normal 0 std) rng
        KaimingNormal -> sampleN count (normal 0 std) rng
        TruncatedNormal mean sigma limit -> do
            finite [mean, sigma, limit]
            if sigma <= 0 || limit <= 0
                then Left (DomainError "truncated normal sigma/limit")
                else sampleN count (rejection mean sigma limit 0) rng
        Orthogonal gain -> do
            finite [gain]
            case shape of
                [rows, cols] | rows > 0 && cols > 0 -> do
                    (draws, s) <- sampleN count (normal 0 1) rng
                    if rows >= cols
                        then do
                            qs <- orthogonalize [[draws !! (i * cols + j) | i <- [0 .. rows - 1]] | j <- [0 .. cols - 1]]
                            Right ([gain * ((qs !! j) !! i) | i <- [0 .. rows - 1], j <- [0 .. cols - 1]], s)
                        else do
                            qs <- orthogonalize [[draws !! (i * cols + j) | j <- [0 .. cols - 1]] | i <- [0 .. rows - 1]]
                            Right (map (* gain) (concat qs), s)
                _ -> Left (InvalidArgument "orthogonal initialization requires positive matrix shape")
    output <- checkedMake shape values
    Right (output, state)
  where
    rejection mean sigma limit attempts s
        | attempts > 100000 = Left (NonConvergence "truncated normal rejection" attempts)
        | otherwise = do
            (x, t) <- normal mean sigma s
            if abs (x - mean) <= limit * sigma
                then Right (x, t)
                else rejection mean sigma limit (attempts + 1) t
    orthogonalize =
        foldM
            ( \basis v -> do
                let residual = foldl' (\r q -> zipWith (-) r (map (* (sum (zipWith (*) r q))) q)) v basis
                    norm = sqrt (sum (map (\x -> x * x) residual))
                if norm < 1e-14
                    then Left (RankDeficient (length basis))
                    else Right (basis ++ [map (/ norm) residual])
            )
            []

-- | Gather checked row indices from [vocabulary,features] weights in requested order.
embedding :: T.Tensor Double -> [Int] -> Either MathError (T.Tensor Double)
embedding weights ids = do
    validTensor weights
    case T.tensorShape weights of
        [rows, cols]
            | all (\i -> i >= 0 && i < rows) ids ->
                checkedMake [length ids, cols] [get weights [i, j] | i <- ids, j <- [0 .. cols - 1]]
        _ -> Left (InvalidArgument "embedding weights/indices")

denseGeneric :: (Num a) => T.Tensor a -> T.Tensor a -> [a] -> Either MathError (T.Tensor a)
denseGeneric input weights bias = case (T.tensorShape input, T.tensorShape weights) of
    ([n, features], [out, inner])
        | features == inner && length bias == out ->
            T.tensor
                [n, out]
                [ sum [get input [i, k] * get weights [j, k] | k <- [0 .. features - 1]] + bias !! j
                | i <- [0 .. n - 1]
                , j <- [0 .. out - 1]
                ]
    _ -> Left (InvalidArgument "dense expects [batch,in],[out,in],[out]")

-- | Apply x*transpose(weights)+bias to [batch,in] inputs and [out,in] weights.
dense :: T.Tensor Double -> T.Tensor Double -> [Double] -> Either MathError (T.Tensor Double)
dense input weights bias = do
    validTensor input
    validTensor weights
    finite bias
    y <- denseGeneric input weights bias
    validTensor y
    Right y

-- | Symbolic dense layer with gradients through inputs, weights, and explicit bias expressions.
denseAD :: AD.ADTensor -> AD.ADTensor -> [AD.Expr] -> Either MathError AD.ADTensor
denseAD input weights bias = do
    x <- T.tensor (AD.adShape input) (AD.adValues input)
    w <- T.tensor (AD.adShape weights) (AD.adValues weights)
    y <- denseGeneric x w bias
    AD.adTensor (T.tensorShape y) (T.tensorValues y)

data ConvOptions = ConvOptions
    { convolutionStride :: [Int]
    , convolutionPadding :: [Int]
    , convolutionDilation :: [Int]
    , convolutionGroups :: Int
    }
    deriving (Eq, Show)
convGeneric ::
    (Num a) =>
    Bool -> [Int] -> ConvOptions -> T.Tensor a -> T.Tensor a -> [a] -> Either MathError (T.Tensor a)
convGeneric transposed outputPadding options input weights bias = case (T.tensorShape input, T.tensorShape weights) of
    (n : cin : spatial, first : second : kernel) -> do
        let dims = length spatial
            strides = convolutionStride options
            padding = convolutionPadding options
            dilation = convolutionDilation options
            groups = convolutionGroups options
            coutInteger = if transposed then toInteger second * toInteger groups else toInteger first
            cout = fromInteger coutInteger
        if coutInteger > toInteger (maxBound :: Int)
            || coutInteger < 1
            || dims < 1
            || dims > 3
            || length kernel /= dims
            || length strides /= dims
            || length padding /= dims
            || length dilation /= dims
            || groups < 1
            || cin < 1
            || cout < 1
            || cin `mod` groups /= 0
            || cout `mod` groups /= 0
            || length bias /= cout
            || any (<= 0) (kernel ++ strides ++ dilation ++ spatial)
            || any (< 0) padding
            || ( if transposed
                    then
                        first /= cin
                            || length outputPadding /= dims
                            || or (zipWith (\p s -> p < 0 || p >= s) outputPadding strides)
                    else second /= cin `div` groups
               )
            then Left (InvalidArgument "convolution layout, channels, groups, stride, or padding")
            else Right ()
        let integerSpatial = map toInteger spatial
            integerKernel = map toInteger kernel
            integerStride = map toInteger strides
            integerPadding = map toInteger padding
            integerDilation = map toInteger dilation
            outputDimensions =
                if transposed
                    then
                        zipWith5
                            (\s k st p d -> (s - 1) * st - 2 * p + d * (k - 1) + 1)
                            integerSpatial
                            integerKernel
                            integerStride
                            integerPadding
                            integerDilation
                            `zipAdd` map toInteger outputPadding
                    else
                        zipWith5
                            (\s k st p d -> (s + 2 * p - d * (k - 1) - 1) `div` st + 1)
                            integerSpatial
                            integerKernel
                            integerStride
                            integerPadding
                            integerDilation
        outShape <- checkedDimensions outputDimensions
        if any (<= 0) outShape then Left (InvalidArgument "convolution empty output") else Right ()
        _ <- T.shapeSize (n : cout : outShape)
        let values =
                [ let group = oc `div` (cout `div` groups)
                      contributions =
                        [ let (valid, ip) =
                                if transposed
                                    then
                                        let numerator =
                                                zipWith4
                                                    (\o p k d -> o + p - k * d)
                                                    (map toInteger op)
                                                    integerPadding
                                                    (map toInteger kp)
                                                    integerDilation
                                            point = zipWith div numerator integerStride
                                         in ( and (zipWith (\v st -> v `mod` st == 0) numerator integerStride) && inside point integerSpatial
                                            , map fromInteger point
                                            )
                                    else
                                        let point =
                                                zipWith4
                                                    (\o st k d -> o * st + k * d)
                                                    (map toInteger op)
                                                    integerStride
                                                    (map toInteger kp)
                                                    integerDilation
                                                    `zipSubtract` integerPadding
                                         in (inside point integerSpatial, map fromInteger point)
                              channel = group * (cin `div` groups) + ic
                              weightIndex = if transposed then channel : (oc `mod` (cout `div` groups)) : kp else oc : ic : kp
                           in if valid then get input (batch : channel : ip) * get weights weightIndex else 0
                        | ic <- [0 .. cin `div` groups - 1]
                        , kp <- indices kernel
                        ]
                   in sum contributions + bias !! oc
                | batch <- [0 .. n - 1]
                , oc <- [0 .. cout - 1]
                , op <- indices outShape
                ]
        T.tensor (n : cout : outShape) values
    _ -> Left (InvalidArgument "convolution requires N,C,spatial and two channel weight axes")
  where
    inside point shape = and (zipWith (\i d -> i >= 0 && i < d) point shape)
    zipAdd = zipWith (+)
    zipSubtract = zipWith (-)
    zipWith4 f as bs cs ds = [f a b c d | (a, (b, (c, d))) <- zip as (zip bs (zip cs ds))]
    zipWith5 f as bs cs ds es = [f a b c d e | (a, (b, (c, (d, e)))) <- zip as (zip bs (zip cs (zip ds es)))]

-- | Direct checked 1D/2D/3D cross-correlation with grouped channels and explicit stride/padding/dilation.
convolution ::
    ConvOptions -> T.Tensor Double -> T.Tensor Double -> [Double] -> Either MathError (T.Tensor Double)
convolution options input weights bias = do
    validTensor input
    validTensor weights
    finite bias
    output <- convGeneric False [] options input weights bias
    validTensor output
    Right output

-- | Direct adjoint-layout convolution; output padding is per-axis and strictly less than stride.
transposedConvolution ::
    [Int] ->
    ConvOptions ->
    T.Tensor Double ->
    T.Tensor Double ->
    [Double] ->
    Either MathError (T.Tensor Double)
transposedConvolution extra options input weights bias = do
    validTensor input
    validTensor weights
    finite bias
    output <- convGeneric True extra options input weights bias
    validTensor output
    Right output

-- | Set groups to input channels; output channel multipliers remain explicit in the weight shape.
depthwiseConvolution ::
    ConvOptions -> T.Tensor Double -> T.Tensor Double -> [Double] -> Either MathError (T.Tensor Double)
depthwiseConvolution options input weights bias = case T.tensorShape input of
    _ : channels : _ -> convolution (options{convolutionGroups = channels}) input weights bias
    _ -> Left (InvalidArgument "depthwise input channel shape")

-- | Construct the same direct convolution from scalar graph arithmetic, with automatic input/kernel/bias gradients.
convolutionAD ::
    ConvOptions -> AD.ADTensor -> AD.ADTensor -> [AD.Expr] -> Either MathError AD.ADTensor
convolutionAD options input weights bias = do
    x <- T.tensor (AD.adShape input) (AD.adValues input)
    w <- T.tensor (AD.adShape weights) (AD.adValues weights)
    output <- convGeneric False [] options x w bias
    AD.adTensor (T.tensorShape output) (T.tensorValues output)

data PoolMode = MaxPool | AveragePool deriving (Eq, Show)

-- | Windowed max/average pooling. Padded elements are excluded from the average; entirely padded windows fail.
pooling ::
    PoolMode -> [Int] -> [Int] -> [Int] -> T.Tensor Double -> Either MathError (T.Tensor Double)
pooling mode kernel strides padding input = case T.tensorShape input of
    n : c : spatial -> do
        validTensor input
        let dims = length spatial
        if dims < 1
            || dims > 3
            || any ((/= dims) . length) [kernel, strides, padding]
            || any (<= 0) (kernel ++ strides ++ spatial)
            || any (< 0) padding
            then Left (InvalidArgument "pooling shapes/options")
            else Right ()
        let dimensions =
                zipWith3
                    (\s k (st, p) -> (s + 2 * p - k) `div` st + 1)
                    (map toInteger spatial)
                    (map toInteger kernel)
                    (zip (map toInteger strides) (map toInteger padding))
        outShape <- checkedDimensions dimensions
        if any (<= 0) outShape then Left (InvalidArgument "pooling empty output") else Right ()
        _ <- T.shapeSize (n : c : outShape)
        vals <-
            mapM
                ( \(batch, channel, op) -> do
                    let samples =
                            [ get input (batch : channel : map fromInteger ip)
                            | kp <- indices kernel
                            , let ip =
                                    zipWith3
                                        (\o (st, p) k -> o * st - p + k)
                                        (map toInteger op)
                                        (zip (map toInteger strides) (map toInteger padding))
                                        (map toInteger kp)
                            , and (zipWith (\i d -> i >= 0 && i < toInteger d) ip spatial)
                            ]
                    if null samples
                        then Left (DomainError "pool window entirely padding")
                        else
                            Right (if mode == MaxPool then maximum samples else sum samples / fromIntegral (length samples))
                )
                [(batch, channel, op) | batch <- [0 .. n - 1], channel <- [0 .. c - 1], op <- indices outShape]
        checkedMake (n : c : outShape) vals
    _ -> Left (InvalidArgument "pooling requires N,C,spatial")

-- | Partition spatial axes by floor/ceil output-bin boundaries, then reduce each bin.
adaptivePooling :: PoolMode -> [Int] -> T.Tensor Double -> Either MathError (T.Tensor Double)
adaptivePooling mode outShape input = case T.tensorShape input of
    n : c : spatial | not (null spatial) && length outShape == length spatial && all (> 0) (outShape ++ spatial) -> do
        validTensor input
        _ <- T.shapeSize (n : c : outShape)
        let value batch channel op =
                let points =
                        sequence
                            [ let start = toInteger o * toInteger s `div` toInteger d
                                  end = ((toInteger o + 1) * toInteger s + toInteger d - 1) `div` toInteger d
                               in [fromInteger start .. fromInteger end - 1]
                            | (o, (s, d)) <- zip op (zip spatial outShape)
                            ]
                    xs = [get input (batch : channel : ip) | ip <- points]
                 in if mode == MaxPool then maximum xs else sum xs / fromIntegral (length xs)
        checkedMake
            (n : c : outShape)
            [value batch channel op | batch <- [0 .. n - 1], channel <- [0 .. c - 1], op <- indices outShape]
    _ -> Left (InvalidArgument "adaptive pooling spatial shape")

-- | Reduce all spatial positions to one value per N,C pair.
globalPooling :: PoolMode -> T.Tensor Double -> Either MathError (T.Tensor Double)
globalPooling mode input = adaptivePooling mode (replicate (length (T.tensorShape input) - 2) 1) input

-- | Return attended values and normalized weights for Q[N,D],K[M,D],V[M,F]; True masks permit keys.
scaledDotProductAttention ::
    T.Tensor Double ->
    T.Tensor Double ->
    T.Tensor Double ->
    Maybe [[Bool]] ->
    Maybe [[Double]] ->
    Either MathError (T.Tensor Double, T.Tensor Double)
scaledDotProductAttention query key value mask bias = do
    mapM_ validTensor [query, key, value]
    case (T.tensorShape query, T.tensorShape key, T.tensorShape value) of
        ([n, d], [m, k], [v, features]) | d == k && m == v && d > 0 -> do
            let allowed = maybe (replicate n (replicate m True)) id mask
                additive = maybe (replicate n (replicate m 0)) id bias
            if length allowed /= n
                || any ((/= m) . length) allowed
                || length additive /= n
                || any ((/= m) . length) additive
                then Left (InvalidArgument "attention mask/bias shape")
                else finite (concat additive)
            rows <-
                mapM
                    ( \i -> do
                        let active = [j | j <- [0 .. m - 1], (allowed !! i) !! j]
                            scores =
                                [ sum [get query [i, t] * get key [j, t] | t <- [0 .. d - 1]] / sqrt (fromIntegral d)
                                    + (additive !! i) !! j
                                | j <- active
                                ]
                        probabilities <- if null active then Right [] else softmax scores
                        Right [maybe 0 id (lookup j (zip active probabilities)) | j <- [0 .. m - 1]]
                    )
                    [0 .. n - 1]
            output <-
                checkedMake
                    [n, features]
                    [ sum [(rows !! i) !! j * get value [j, t] | j <- [0 .. m - 1]]
                    | i <- [0 .. n - 1]
                    , t <- [0 .. features - 1]
                    ]
            weights <- checkedMake [n, m] (concat rows)
            Right (output, weights)
        _ -> Left (InvalidArgument "attention requires Q[N,D],K[M,D],V[M,F]")

{- | Split feature dimension into equal heads, attend independently, concatenate.
Projection matrices are explicit dense layers composed by the caller.
-}
multiheadAttention ::
    Int ->
    T.Tensor Double ->
    T.Tensor Double ->
    T.Tensor Double ->
    Maybe [[Bool]] ->
    Either MathError (T.Tensor Double)
multiheadAttention heads q k v mask = case (T.tensorShape q, T.tensorShape k, T.tensorShape v) of
    ([n, d], [m, kd], [vm, vd]) | heads > 0 && d == kd && d == vd && m == vm && d `mod` heads == 0 -> do
        let width = d `div` heads
            select input rows headIndex =
                T.tensor
                    [rows, width]
                    [get input [i, headIndex * width + j] | i <- [0 .. rows - 1], j <- [0 .. width - 1]]
        outputs <-
            mapM
                ( \h -> do
                    qh <- select q n h
                    kh <- select k m h
                    vh <- select v m h
                    fst <$> scaledDotProductAttention qh kh vh mask Nothing
                )
                [0 .. heads - 1]
        checkedMake
            [n, d]
            [get (outputs !! h) [i, j] | i <- [0 .. n - 1], h <- [0 .. heads - 1], j <- [0 .. width - 1]]
    _ -> Left (InvalidArgument "multihead attention equal divisible feature dimensions")

-- | Build a query-by-key allowed mask, with an explicit cached-prefix offset.
causalMask :: Int -> Int -> Int -> Either MathError [[Bool]]
causalMask queryLength keyLength offset
    | queryLength < 0 || keyLength < 0 || offset < 0 =
        Left (InvalidArgument "causal mask lengths/offset")
    | otherwise =
        Right
            [ [toInteger j <= toInteger i + toInteger offset | j <- [0 .. keyLength - 1]]
            | i <- [0 .. queryLength - 1]
            ]

-- | Rotate adjacent feature pairs at sequence positions offset+i; feature dimension must be even.
rotaryEmbedding :: Double -> Int -> T.Tensor Double -> Either MathError (T.Tensor Double)
rotaryEmbedding base offset input = do
    validTensor input
    finite [base]
    case T.tensorShape input of
        [n, d]
            | base > 1 && offset >= 0 && d > 0 && even d ->
                checkedMake
                    [n, d]
                    [ let pair = j `div` 2
                          angle = fromInteger (toInteger i + toInteger offset) / base ** (2 * fromIntegral pair / fromIntegral d)
                          a = get input [i, 2 * pair]
                          b = get input [i, 2 * pair + 1]
                       in if even j then a * cos angle - b * sin angle else a * sin angle + b * cos angle
                    | i <- [0 .. n - 1]
                    , j <- [0 .. d - 1]
                    ]
        _ -> Left (InvalidArgument "rotary embedding base/offset/even feature dimension")

-- | Return [position,feature] sine/cosine positional encoding with base 10000.
sinusoidalEncoding :: Int -> Int -> Int -> Either MathError (T.Tensor Double)
sinusoidalEncoding count features offset
    | count < 0 || features < 1 || offset < 0 = Left (InvalidArgument "sinusoidal encoding dimensions")
    | otherwise =
        checkedMake
            [count, features]
            [ let angle =
                    fromInteger (toInteger i + toInteger offset)
                        / 10000 ** (2 * fromIntegral (j `div` 2) / fromIntegral features)
               in if even j then sin angle else cos angle
            | i <- [0 .. count - 1]
            , j <- [0 .. features - 1]
            ]

-- | Return nonpositive slope-scaled absolute position offsets; combine with a causal allowed mask if required.
alibiBias :: Double -> Int -> Int -> Int -> Either MathError [[Double]]
alibiBias slope queryLength keyLength offset = do
    finite [slope]
    if slope < 0 || queryLength < 0 || keyLength < 0 || offset < 0
        then Left (InvalidArgument "ALiBi parameters")
        else Right ()
    let values =
            [ [ -slope * fromInteger (abs (toInteger i + toInteger offset - toInteger j))
              | j <- [0 .. keyLength - 1]
              ]
            | i <- [0 .. queryLength - 1]
            ]
    finite (concat values)
    Right values

data KVCache = KVCache Int Int Int (T.Tensor Double) (T.Tensor Double) deriving (Eq, Show)

-- | Create an owned immutable key/value cache with fixed positive capacity and feature widths.
emptyCache :: Int -> Int -> Int -> Either MathError KVCache
emptyCache capacity keyFeatures valueFeatures
    | capacity < 1 || keyFeatures < 1 || valueFeatures < 1 =
        Left (InvalidArgument "cache capacity/features")
    | otherwise = do
        k <- T.tensor [0, keyFeatures] []
        v <- T.tensor [0, valueFeatures] []
        Right (KVCache capacity keyFeatures valueFeatures k v)

-- | Append equal-length key/value sequences without truncating history; reject capacity or feature mismatches.
appendCache :: KVCache -> T.Tensor Double -> T.Tensor Double -> Either MathError KVCache
appendCache (KVCache capacity kd vd keys values) k v = do
    validTensor k
    validTensor v
    case (T.tensorShape k, T.tensorShape v, T.tensorShape keys) of
        ([n, d], [m, f], [old, _]) | n == m && d == kd && f == vd && n + old <= capacity -> do
            ks <- T.tensor [old + n, kd] (T.tensorValues keys ++ T.tensorValues k)
            vs <- T.tensor [old + n, vd] (T.tensorValues values ++ T.tensorValues v)
            Right (KVCache capacity kd vd ks vs)
        _ -> Left (InvalidArgument "cache append shape or capacity")

-- | Return immutable accumulated key/value tensors, preserving insertion order.
cacheValues :: KVCache -> (T.Tensor Double, T.Tensor Double)
cacheValues (KVCache _ _ _ k v) = (k, v)

-- | Compose dense, checked elementwise activation, and dense layers with explicit parameters.
transformerFeedForward ::
    Activation ->
    T.Tensor Double ->
    T.Tensor Double ->
    [Double] ->
    T.Tensor Double ->
    [Double] ->
    Either MathError (T.Tensor Double)
transformerFeedForward kind input w1 b1 w2 b2 = do
    first <- dense input w1 b1
    values <- mapM (activation kind) (T.tensorValues first)
    middle <- T.tensor (T.tensorShape first) values
    dense middle w2 b2

{- | Symbolic trailing-axis layer normalization. Affine gamma/beta can be
composed with broadcast multiplication/addition in HMath.Autodiff.
-}
layerNormAD :: Int -> Double -> AD.ADTensor -> Either MathError AD.ADTensor
layerNormAD = normalizeAD False

-- | Symbolic RMS normalization; its denominator includes all trailing axes.
rmsNormAD :: Int -> Double -> AD.ADTensor -> Either MathError AD.ADTensor
rmsNormAD = normalizeAD True

normalizeAD :: Bool -> Int -> Double -> AD.ADTensor -> Either MathError AD.ADTensor
normalizeAD rms axes eps input = do
    let shape = AD.adShape input; values = AD.adValues input; prefix = take (length shape - axes) shape
    finite [eps]
    if axes < 1 || axes > length shape || eps <= 0 || null values
        then Left (InvalidArgument "symbolic normalization axes/epsilon/empty input")
        else Right ()
    let group ix = flat prefix (take (length prefix) ix)
        allIx = indices shape
        normalized ix =
            let members = [v | (key, v) <- zip allIx values, group key == group ix]
                size = fromIntegral (length members)
                mean = if rms then 0 else sum members / AD.constant size
                variance = sum [(v - mean) * (v - mean) | v <- members] / AD.constant size
             in (values !! flat shape ix - mean) / sqrt (variance + AD.constant eps)
    AD.adTensor shape (map normalized allIx)

{- | First-order reverse attention graph, including Q/K score and V gradients.
Masks have the same True=allowed semantics as the checked numeric operation;
a fully masked row is a constant zero graph and backpropagates exact zeros.
-}
scaledDotProductAttentionAD ::
    AD.ADTensor -> AD.ADTensor -> AD.ADTensor -> Maybe [[Bool]] -> Either MathError AD.ADTensor
scaledDotProductAttentionAD query key value mask = case (AD.adShape query, AD.adShape key, AD.adShape value) of
    ([n, d], [m, k], [v, features]) | d == k && m == v && d > 0 -> do
        let allowed = maybe (replicate n (replicate m True)) id mask
            q = AD.adValues query
            ks = AD.adValues key
            vs = AD.adValues value
        if length allowed /= n || any ((/= m) . length) allowed
            then Left (InvalidArgument "symbolic attention mask shape")
            else Right ()
        let row i =
                let active = [j | j <- [0 .. m - 1], (allowed !! i) !! j]
                    scores =
                        [ sum [q !! (i * d + t) * ks !! (j * d + t) | t <- [0 .. d - 1]] / AD.constant (sqrt (fromIntegral d))
                        | j <- active
                        ]
                    probabilities = softmaxExpr scores
                 in [sum [p * vs !! (j * features + t) | (j, p) <- zip active probabilities] | t <- [0 .. features - 1]]
        AD.adTensor [n, features] (concatMap row [0 .. n - 1])
    _ -> Left (InvalidArgument "symbolic attention shape")

checkedDimensions :: [Integer] -> Either MathError [Int]
checkedDimensions dimensions
    | any (\d -> d < 0 || d > toInteger (maxBound :: Int)) dimensions =
        Left (InvalidArgument "neural layer output dimension overflow")
    | otherwise = Right (map fromInteger dimensions)
