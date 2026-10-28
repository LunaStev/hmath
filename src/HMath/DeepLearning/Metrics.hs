-- SPDX-License-Identifier: MPL-2.0

{- | Classification metrics. Empty samples are rejected, zero-denominator
precision/recall/F1 are defined as zero. Confusion matrix rows are truth,
columns prediction. ROC ties count one half; PR AUC uses grouped-threshold
trapezoids from recall=0,precision=1 (distinct from average precision).
-}
module HMath.DeepLearning.Metrics (
    ClassificationMetrics (..),
    confusionMatrix,
    classificationMetrics,
    topKAccuracy,
    rocAUC,
    prAUC,
    perplexity,
    cosineSimilarityMatrix,
    marginRankingLoss,
) where

import qualified Data.Foldable as Foldable (foldl')
import Data.List (groupBy, sortBy)
import HMath.Error
import qualified HMath.Tensor as T

data ClassificationMetrics = ClassificationMetrics
    { accuracy :: Double
    , precisionByClass :: [Double]
    , recallByClass :: [Double]
    , f1ByClass :: [Double]
    }
    deriving (Eq, Show)
finite :: [Double] -> Either MathError ()
finite xs = if all (\x -> not (isNaN x || isInfinite x)) xs then Right () else Left NonFiniteResult

-- | Count [trueClass,predictedClass] pairs for a positive explicit class count.
confusionMatrix :: Int -> [Int] -> [Int] -> Either MathError [[Int]]
confusionMatrix classes truth prediction
    | classes < 1
        || null truth
        || length truth /= length prediction
        || any (\i -> i < 0 || i >= classes) (truth ++ prediction) =
        Left (InvalidArgument "classification labels/classes/lengths")
    | otherwise =
        Right
            [ [length [() | (t, p) <- zip truth prediction, t == i, p == j] | j <- [0 .. classes - 1]]
            | i <- [0 .. classes - 1]
            ]

-- | Return accuracy and per-class precision, recall, and F1 with zero for undefined class denominators.
classificationMetrics :: Int -> [Int] -> [Int] -> Either MathError ClassificationMetrics
classificationMetrics classes truth prediction = do
    matrix <- confusionMatrix classes truth prediction
    let divide a b = if b == 0 then 0 else fromIntegral a / fromIntegral b
        ps = [divide ((matrix !! i) !! i) (sum [row !! i | row <- matrix]) | i <- [0 .. classes - 1]]
        rs = [divide ((matrix !! i) !! i) (sum (matrix !! i)) | i <- [0 .. classes - 1]]
        fs = zipWith (\p r -> if p + r == 0 then 0 else 2 * p * r / (p + r)) ps rs
        acc = fromIntegral (sum [(matrix !! i) !! i | i <- [0 .. classes - 1]]) / fromIntegral (length truth)
    Right (ClassificationMetrics acc ps rs fs)

-- | Measure whether truth lies among descending top-k scores; equal scores prefer the smaller class index.
topKAccuracy :: Int -> [Int] -> [[Double]] -> Either MathError Double
topKAccuracy k truth scores = do
    finite (concat scores)
    if k < 1
        || null truth
        || length truth /= length scores
        || any (\(t, row) -> null row || k > length row || t < 0 || t >= length row) (zip truth scores)
        then Left (InvalidArgument "top-k labels/scores/k")
        else Right ()
    let correct =
            length
                [ ()
                | (t, row) <- zip truth scores
                , t
                    `elem` map
                        snd
                        ( take
                            k
                            ( sortBy
                                (\(x, i) (y, j) -> case compare y x of EQ -> compare i j; order -> order)
                                (zip row [0 :: Int ..])
                            )
                        )
                ]
    Right (fromIntegral correct / fromIntegral (length truth))

-- | Compute the exact positive/negative rank-pair ROC area; both classes are required and ties count half.
rocAUC :: [Bool] -> [Double] -> Either MathError Double
rocAUC truth scores = do
    finite scores
    if null truth || length truth /= length scores
        then Left (InvalidArgument "ROC sample lengths")
        else Right ()
    let positive = [s | (True, s) <- zip truth scores]; negative = [s | (False, s) <- zip truth scores]
    if null positive || null negative
        then Left (DomainError "ROC AUC requires both classes")
        else
            Right
                ( sum [if p > n then 1 else if p == n then 0.5 else 0 | p <- positive, n <- negative]
                    / fromIntegral (length positive * length negative)
                )

-- | Integrate the precision-recall curve by grouped-score trapezoids, requiring at least one positive example.
prAUC :: [Bool] -> [Double] -> Either MathError Double
prAUC truth scores = do
    finite scores
    if null truth || length truth /= length scores
        then Left (InvalidArgument "PR sample lengths")
        else Right ()
    let positives = length (filter id truth)
    if positives == 0 then Left (DomainError "PR AUC requires positives") else Right ()
    let groups = groupBy (\a b -> snd a == snd b) (sortBy (\a b -> compare (snd b) (snd a)) (zip truth scores))
        update (tp, fp, oldRecall, oldPrecision, area) group =
            let tp' = tp + length [() | (True, _) <- group]
                fp' = fp + length [() | (False, _) <- group]
                recall = fromIntegral tp' / fromIntegral positives
                precision = fromIntegral tp' / fromIntegral (tp' + fp')
             in (tp', fp', recall, precision, area + (recall - oldRecall) * (precision + oldPrecision) / 2)
        (_, _, _, _, auc) = Foldable.foldl' update (0 :: Int, 0 :: Int, 0, 1, 0) groups
    Right auc

-- | Exponentiate the negative mean true-token log probability; empty or positive log probabilities fail.
perplexity :: [Double] -> Either MathError Double
perplexity logs = do
    finite logs
    if null logs || any (> 0) logs
        then Left (DomainError "perplexity requires nonpositive log probabilities")
        else Right ()
    let y = exp (-sum (map (/ fromIntegral (length logs)) logs))
    finite [y]
    Right y

-- | Compare every [M,D] row with every [N,D] row using scale-safe unit vectors; zero vectors fail.
cosineSimilarityMatrix :: T.Tensor Double -> T.Tensor Double -> Either MathError (T.Tensor Double)
cosineSimilarityMatrix a b = do
    finite (T.tensorValues a ++ T.tensorValues b)
    case (T.tensorShape a, T.tensorShape b) of
        ([m, d], [n, e]) | d == e && d > 0 -> do
            let row t i = [T.tensorValues t !! (i * d + j) | j <- [0 .. d - 1]]
                normalize xs =
                    let scale = maximum (map abs xs); unit = map (/ scale) xs; norm = sqrt (sum (map (\x -> x * x) unit))
                     in if scale == 0 then Left (DomainError "cosine similarity zero vector") else Right (map (/ norm) unit)
            ar <- mapM (normalize . row a) [0 .. m - 1]
            br <- mapM (normalize . row b) [0 .. n - 1]
            T.tensor [m, n] [sum (zipWith (*) x y) | x <- ar, y <- br]
        _ -> Left (InvalidArgument "cosine matrix expects [M,D],[N,D]")

-- | Mean hinge on signed (+/-1) pair ordering with a nonnegative finite margin.
marginRankingLoss :: Double -> [Double] -> [Double] -> [Double] -> Either MathError Double
marginRankingLoss margin labels left right = do
    finite (margin : labels ++ left ++ right)
    if margin < 0
        || null labels
        || length labels /= length left
        || length labels /= length right
        || any (\y -> abs y /= 1) labels
        then Left (InvalidArgument "margin ranking labels/shapes/margin")
        else Right ()
    let value =
            sum (zipWith3 (\y a b -> max 0 (margin - y * (a - b))) labels left right)
                / fromIntegral (length labels)
    finite [value]
    Right value
