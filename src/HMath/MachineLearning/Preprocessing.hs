-- SPDX-License-Identifier: MPL-2.0

{- | Fitted preprocessing and index-based splits. Fit on training rows before
transforming validation/test rows. Unknown categories are rejected unless
explicitly mapped to an all-zero vector. Sample quantiles interpolate between
order statistics; constant features use scale one and transform to zero.
-}
module HMath.MachineLearning.Preprocessing (
    Scaling (..),
    Scaler,
    fitScaler,
    transform,
    inverseTransform,
    QuantileTransformer,
    fitQuantileTransformer,
    quantileTransform,
    inverseQuantileTransform,
    PowerTransform (..),
    powerTransform,
    inversePowerTransform,
    Imputation (..),
    Imputer,
    fitImputer,
    impute,
    Encoder,
    UnknownCategory (..),
    fitEncoder,
    labelEncode,
    labelDecode,
    oneHotEncode,
    Fold (..),
    trainTestSplit,
    kFold,
    stratifiedKFold,
    gridSearch,
    randomSearch,
) where

import Data.List (nub, sort, sortOn, transpose)
import Data.Word (Word64)
import HMath.Error
import HMath.MachineLearning.Internal
import qualified HMath.Random as R
import qualified HMath.Scalar as S

-- | Population z-score, unit-range, or median/IQR feature scaling.
data Scaling = Standardize | MinMax | RobustScale deriving (Eq, Show)

-- | Immutable training-feature centers and nonzero scales; constant columns use scale one.
data Scaler = Scaler [Double] [Double] deriving (Eq, Show)

quantile :: Double -> [Double] -> Double
quantile q xs =
    let s = sort xs; z = q * fromIntegral (length xs - 1); i = floor z; a = z - fromIntegral i
     in (1 - a) * s !! i + a * s !! min (length s - 1) (i + 1)

-- | Estimate one center and scale per training feature. Empty/ragged or nonfinite data fail.
fitScaler :: Scaling -> Dataset -> Either MathError Scaler
fitScaler method xs = do
    _ <- dataset xs
    let fit col = case method of
            Standardize ->
                let m = sum col / fromIntegral (length col)
                 in (m, sqrt (sum [(v - m) ^ (2 :: Int) | v <- col] / fromIntegral (length col)))
            MinMax -> (minimum col, maximum col - minimum col)
            RobustScale -> (quantile 0.5 col, quantile 0.75 col - quantile 0.25 col)
        pairs = map fit (transpose xs)
        origins = map fst pairs
        scales = map (\(_, s) -> if s == 0 then 1 else s) pairs
    checked (origins ++ scales)
    Right (Scaler origins scales)

-- | Apply training centers/scales to rows with the original feature count; no state is updated.
transform :: Scaler -> Dataset -> Either MathError Dataset
transform (Scaler origins scales) xs = do
    queries (length origins) xs
    let ys = map (\r -> zipWith (/) (sub r origins) scales) xs
    checked (concat ys)
    Right ys

-- | Undo a fitted affine scaler, including its constant-feature convention.
inverseTransform :: Scaler -> Dataset -> Either MathError Dataset
inverseTransform (Scaler origins scales) xs = do
    queries (length origins) xs
    let ys = map (\r -> add origins (zipWith (*) r scales)) xs
    checked (concat ys)
    Right ys

-- | Sorted training samples retained separately for each feature.
newtype QuantileTransformer = QT Dataset deriving (Eq, Show)

-- | Fit empirical feature quantiles using training rows only.
fitQuantileTransformer :: Dataset -> Either MathError QuantileTransformer
fitQuantileTransformer xs = dataset xs >> Right (QT (map sort (transpose xs)))

-- | Map values to [0,1]. Ties use their average rank and values outside training extrema clamp.
quantileTransform :: QuantileTransformer -> Dataset -> Either MathError Dataset
quantileTransform (QT cols) xs = do
    queries (length cols) xs
    let rank s v
            | length s == 1 = 0.5
            | v < s !! 0 = 0
            | v > last s = 1
            | not (null equal) =
                sum (map fromIntegral equal) / fromIntegral (length equal) / fromIntegral (length s - 1)
            | otherwise =
                let j = length (takeWhile (< v) s); lo = s !! (j - 1); hi = s !! j
                 in let magnitude = max (abs lo) (abs hi)
                        fraction =
                            if magnitude == 0 then 0 else (v / magnitude - lo / magnitude) / (hi / magnitude - lo / magnitude)
                     in (fromIntegral (j - 1) + fraction) / fromIntegral (length s - 1)
          where
            equal = [i | (i, z) <- zip [0 :: Int ..] s, z == v]
    Right [[rank c v | (c, v) <- zip cols r] | r <- xs]

-- | Interpolate training order statistics at probabilities in [0,1].
inverseQuantileTransform :: QuantileTransformer -> Dataset -> Either MathError Dataset
inverseQuantileTransform (QT cols) xs = do
    queries (length cols) xs
    require (all (\x -> x >= 0 && x <= 1) (concat xs)) "quantiles must be in [0,1]"
    Right [[quantile q c | (c, q) <- zip cols r] | r <- xs]

-- | Box-Cox or Yeo-Johnson with a caller-selected finite power lambda; lambda is not estimated.
data PowerTransform = BoxCox Double | YeoJohnson Double deriving (Eq, Show)

-- | Apply the selected power to features. Box-Cox requires positive values; Yeo-Johnson allows signs.
powerTransform :: PowerTransform -> Dataset -> Either MathError Dataset
powerTransform method xs = do
    _ <- dataset xs
    let l = case method of BoxCox z -> z; YeoJohnson z -> z
    checked [l]
    case method of
        BoxCox _ -> require (all (> 0) (concat xs)) "Box-Cox requires positive values"
        _ -> Right ()
    let quotient power logarithm =
            if power == 0
                then Right logarithm
                else
                    if power * logarithm == 0
                        then Right logarithm
                        else (/ power) <$> S.expm1 (power * logarithm)
        one x = case method of
            BoxCox _ -> quotient l (log x)
            YeoJohnson _
                | x >= 0 -> S.log1p x >>= quotient l
                | otherwise -> negate <$> (S.log1p (-x) >>= quotient (2 - l))
    ys <- traverse (traverse one) xs

    checked (concat ys)
    Right ys

-- | Invert the selected power, rejecting values outside the transform range.
inversePowerTransform :: PowerTransform -> Dataset -> Either MathError Dataset
inversePowerTransform method xs = do
    _ <- dataset xs
    let l = case method of BoxCox z -> z; YeoJohnson z -> z
    checked [l]
    let scaledLog power value =
            if power == 0 || power * value == 0
                then Right value
                else (/ power) <$> S.log1p (power * value)
        one x = case method of
            BoxCox _ -> exp <$> scaledLog l x
            YeoJohnson _
                | x >= 0 -> scaledLog l x >>= S.expm1
                | otherwise -> negate <$> (scaledLog (2 - l) (-x) >>= S.expm1)
    ys <- traverse (traverse one) xs
    checked (concat ys)
    Right ys

-- | Training-column mean, median, or a finite constant for NaN-valued observations.
data Imputation = MeanImpute | MedianImpute | ConstantImpute Double deriving (Eq, Show)

-- | Fitted replacement values; an imputer never learns from rows passed to impute.
newtype Imputer = Imputer [Double] deriving (Eq, Show)

-- | Treat NaN as missing and reject infinities. All-missing columns require ConstantImpute.
fitImputer :: Imputation -> Dataset -> Either MathError Imputer
fitImputer method xs = do
    require
        (not (null xs) && not (null (firstRow xs)) && all ((== length (firstRow xs)) . length) xs)
        "imputer requires rectangular data"
    require (not (any isInfinite (concat xs))) "imputer rejects infinities"
    vals <- traverse fit (transpose xs)
    checked vals
    Right (Imputer vals)
  where
    fit col =
        let good = filter (not . isNaN) col
         in case method of
                ConstantImpute c -> checked [c] >> Right c
                _ -> do
                    require (not (null good)) "entirely missing training feature"
                    Right
                        (case method of MeanImpute -> sum (map (/ fromIntegral (length good)) good); _ -> quantile 0.5 good)

-- | Replace NaN with fitted training values while preserving observed entries and row order.
impute :: Imputer -> Dataset -> Either MathError Dataset
impute (Imputer vals) xs = do
    require (all ((== length vals) . length) xs) "imputation feature mismatch"
    require (not (any isInfinite (concat xs))) "imputer rejects infinities"
    Right [zipWith (\x v -> if isNaN x then v else x) r vals | r <- xs]

-- | Sorted distinct training categories with stable zero-based integer codes.
newtype Encoder a = Encoder [a] deriving (Eq, Show)

-- | Whether a previously unseen category fails or produces an all-zero one-hot row.
data UnknownCategory = RejectUnknown | ZeroUnknown deriving (Eq, Show)

-- | Learn sorted category levels from a nonempty training label vector.
fitEncoder :: (Ord a) => [a] -> Either MathError (Encoder a)
fitEncoder xs = do require (not (null xs)) "encoder requires categories"; Right (Encoder (sort (nub xs)))

-- | Map known categories to zero-based codes; unseen categories fail.
labelEncode :: (Eq a) => Encoder a -> [a] -> Either MathError [Int]
labelEncode (Encoder levels) =
    traverse
        ( \x -> case [i | (i, y) <- zip [0 ..] levels, x == y] of
            i : _ -> Right i
            _ -> Left (InvalidArgument "ML: unknown category")
        )

-- | Recover categories from checked integer codes.
labelDecode :: Encoder a -> [Int] -> Either MathError [a]
labelDecode (Encoder levels) ix = do
    require (all (\i -> i >= 0 && i < length levels) ix) "unknown encoded label"
    Right (map (levels !!) ix)

-- | Emit one column per sorted training category under the explicit unknown-category policy.
oneHotEncode :: (Eq a) => UnknownCategory -> Encoder a -> [a] -> Either MathError Dataset
oneHotEncode policy (Encoder levels) xs = do
    require (policy == ZeroUnknown || all (`elem` levels) xs) "unknown category"
    Right [[if x == c then 1 else 0 | c <- levels] | x <- xs]

-- | Disjoint indices into the original dataset. No estimator is fitted here.
data Fold = Fold
    { trainingIndices :: [Int]
    -- ^ Zero-based original row indices assigned to training in this fold.
    , validationIndices :: [Int]
    -- ^ Zero-based original row indices held out for validation in this fold.
    }
    deriving (Eq, Show)

permutation :: Word64 -> Int -> [Int]
permutation seed n = map snd (sortOn fst (zip (take n (stream (R.seedRNG R.PCG32 seed))) [0 .. n - 1]))
  where
    stream r = let (v, r') = R.nextWord64 r in v : stream r'

-- | Seeded split of n row indices. The fraction denotes test rows, rounded and clamped to [1,n-1].
trainTestSplit :: Word64 -> Double -> Int -> Either MathError Fold
trainTestSplit seed fraction n = do
    require (n >= 2 && finite fraction && fraction > 0 && fraction < 1) "invalid train/test split"
    let p = permutation seed n; count = max 1 (min (n - 1) (round (fraction * fromIntegral n)))
    Right (Fold (drop count p) (take count p))

-- | Partition n shuffled indices into k nonempty validation folds; each row is held out exactly once.
kFold :: Word64 -> Int -> Int -> Either MathError [Fold]
kFold seed k n = do
    require (k >= 2 && k <= n) "fold count must be between two and sample count"
    let p = permutation seed n
    Right
        [ let held = [i | (j, i) <- zip [0 :: Int ..] p, j `mod` k == f]
           in Fold (filter (`notElem` held) p) held
        | f <- [0 .. k - 1]
        ]

-- | Round-robin each shuffled class across k folds. Every class needs at least k observations.
stratifiedKFold :: (Ord a) => Word64 -> Int -> [a] -> Either MathError [Fold]
stratifiedKFold seed k labels = do
    require (k >= 2 && k <= length labels) "invalid stratified fold count"
    let groups = [[i | (i, y) <- zip [0 ..] labels, y == c] | c <- sort (nub labels)]
    require (all ((>= k) . length) groups) "each class needs at least one member per fold"
    let ordered =
            [map (g !!) (permutation (seed + fromIntegral j) (length g)) | (j, g) <- zip [0 :: Int ..] groups]
        held f = concat [[i | (j, i) <- zip [0 :: Int ..] g, j `mod` k == f] | g <- ordered]
    Right [Fold (filter (`notElem` held f) [0 .. length labels - 1]) (held f) | f <- [0 .. k - 1]]

{- | Minimize a user-supplied validation loss, evaluated independently for every
candidate/fold. The callback receives only the split indices, so it can fit
preprocessing/model state inside each fold. Ties preserve candidate order.
-}
gridSearch ::
    [p] -> [Fold] -> (p -> Fold -> Either MathError Double) -> Either MathError (p, Double)
gridSearch candidates folds score = do
    require (not (null candidates) && not (null folds)) "empty parameter search"
    require (all valid folds) "search folds must have disjoint nonempty unique nonnegative indices"
    results <-
        traverse
            ( \p -> do
                costs <- traverse (score p) folds
                checked costs
                let average = sum (map (/ fromIntegral (length costs)) costs)
                checked [average]
                Right (p, average)
            )
            candidates
    Right (results !! argmin (map snd results))
  where
    valid f =
        let tr = trainingIndices f; va = validationIndices f
         in not (null tr)
                && not (null va)
                && all (>= 0) (tr ++ va)
                && length (nub tr) == length tr
                && length (nub va) == length va
                && all (`notElem` va) tr

-- | Sample count distinct candidates from a finite set, then evaluate the supplied folds. Lower loss wins.
randomSearch ::
    Word64 ->
    Int ->
    [p] ->
    [Fold] ->
    (p -> Fold -> Either MathError Double) ->
    Either MathError (p, Double)
randomSearch seed count candidates folds score = do
    require
        (count > 0 && count <= length candidates)
        "random search budget exceeds finite candidate set"
    gridSearch (map (candidates !!) (take count (permutation seed (length candidates)))) folds score
