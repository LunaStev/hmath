-- SPDX-License-Identifier: MPL-2.0

{- | Checked Double activations, losses, and real-coordinate reverse rules.
Probabilities must be in [0,1]; impossible events return a domain failure
instead of silently clipping probabilities. Logit losses avoid exp overflow.
Nondifferentiable hinges use zero at equality; MAE uses signum(0)=0.
-}
module HMath.DeepLearning.Core (
    Activation (..),
    activation,
    activationDerivative,
    activationExpr,
    softmax,
    logSoftmax,
    sparsemax,
    gatedLinearUnit,
    softmaxExpr,
    logSoftmaxExpr,
    sparsemaxExpr,
    ctcLossExpr,
    Reduction (..),
    Loss (..),
    loss,
    lossGradient,
    lossExpr,
    binaryCrossEntropyLogits,
    categoricalCrossEntropyLogits,
    regularization,
    contrastiveLoss,
    tripletLoss,
    focalLoss,
    diceLoss,
    iouLoss,
    ctcLoss,
    ctcLossGradient,
) where

import Data.List (sortBy)
import qualified HMath.Autodiff as AD
import HMath.Error

data Activation
    = Sigmoid
    | Tanh
    | ReLU
    | LeakyReLU Double
    | PReLU Double
    | ELU Double
    | SELU
    | GELU
    | SiLU
    | Mish
    | Softplus
    | Softsign
    | HardSigmoid
    | HardSwish
    deriving (Eq, Show)
finite :: [Double] -> Either MathError ()
finite xs = if all (\x -> not (isNaN x || isInfinite x)) xs then Right () else Left NonFiniteResult
sigmoid :: Double -> Double
sigmoid x = if x >= 0 then 1 / (1 + exp (-x)) else let z = exp x in z / (1 + z)
softplus :: Double -> Double
softplus x = max x 0 + log (1 + exp (-abs x))

-- GELU uses the explicit tanh approximation from Hendrycks/Gimpel (2016).
activation :: Activation -> Double -> Either MathError Double
activation kind x = do
    finite [x]
    case kind of
        LeakyReLU a -> finite [a]
        PReLU a -> finite [a]
        ELU a -> do
            finite [a]
            if a <= 0 then Left (DomainError "positive ELU alpha required") else Right ()
        _ -> Right ()
    let y = case kind of
            Sigmoid -> sigmoid x
            Tanh -> tanh x
            ReLU -> max 0 x
            LeakyReLU a -> if x >= 0 then x else a * x
            PReLU a -> if x >= 0 then x else a * x
            ELU a -> if x >= 0 then x else a * (exp x - 1)
            SELU -> 1.0507009873554805 * (if x >= 0 then x else 1.6732632423543772 * (exp x - 1))
            GELU -> 0.5 * x * (1 + tanh (sqrt (2 / pi) * (x + 0.044715 * x * x * x)))
            SiLU -> x * sigmoid x
            Mish -> x * tanh (softplus x)
            Softplus -> softplus x
            Softsign -> x / (1 + abs x)
            HardSigmoid -> max 0 (min 1 (x / 6 + 0.5))
            HardSwish -> x * max 0 (min 1 (x / 6 + 0.5))
    finite [y]
    Right y

-- | Evaluate the analytic first derivative with documented kink conventions and stable saturated sigmoid/tanh behavior.
activationDerivative :: Activation -> Double -> Either MathError Double
activationDerivative kind x = do
    _ <- activation kind x
    let s = sigmoid x
        t = tanh x
        y = case kind of
            Sigmoid -> s * (1 - s)
            Tanh -> 1 - t * t
            ReLU -> if x > 0 then 1 else 0
            LeakyReLU a -> if x >= 0 then 1 else a
            PReLU a -> if x >= 0 then 1 else a
            ELU a -> if x >= 0 then 1 else a * exp x
            SELU -> 1.0507009873554805 * (if x >= 0 then 1 else 1.6732632423543772 * exp x)
            GELU
                | x > 20 -> 1
                | x < -20 -> 0
                | otherwise ->
                    let c = sqrt (2 / pi); u = c * (x + 0.044715 * x * x * x); z = tanh u
                     in 0.5 * (1 + z) + 0.5 * x * (1 - z * z) * c * (1 + 3 * 0.044715 * x * x)
            SiLU -> s + x * s * (1 - s)
            Mish -> let z = tanh (softplus x) in z + x * (1 - z * z) * s
            Softplus -> s
            Softsign -> 1 / (1 + abs x) ^ (2 :: Int)
            HardSigmoid -> if x > -3 && x < 3 then 1 / 6 else 0
            HardSwish -> if x <= -3 then 0 else if x >= 3 then 1 else x / 3 + 0.5
    finite [y]
    Right y

-- | Embed the checked activation and analytic custom reverse rule in an automatic differentiation graph.
activationExpr :: Activation -> AD.Expr -> AD.Expr
activationExpr a x = AD.customOperation rule [x]
  where
    rule [v] = do y <- activation a v; dy <- activationDerivative a v; Right (y, [dy])
    rule _ = Left (InvalidArgument "activation arity")

-- | Normalize a nonempty finite vector in log space after subtracting its maximum.
logSoftmax :: [Double] -> Either MathError [Double]
logSoftmax [] = Left (InvalidArgument "empty softmax axis")
logSoftmax xs = do
    finite xs
    let m = maximum xs
        normalizer = log (sum [exp (x - m) | x <- xs])
        ys = map (\x -> (x - m) - normalizer) xs
    finite ys
    Right ys

-- | Exponentiate stable log-softmax values; the output sums to one within floating error.
softmax :: [Double] -> Either MathError [Double]
softmax xs = map exp <$> logSoftmax xs

-- | Project a finite vector onto the probability simplex using sorted active-support thresholds.
sparsemax :: [Double] -> Either MathError [Double]
sparsemax [] = Left (InvalidArgument "empty sparsemax axis")
sparsemax xs = do
    finite xs
    let m = maximum xs
        shifted = map (subtract m) xs
        sorted = sortBy (flip compare) shifted
        prefix = tailSafe (scanl (+) 0 sorted)
        active =
            [ (rank, total)
            | (rank, (z, total)) <- zip [1 :: Int ..] (zip sorted prefix)
            , 1 + fromIntegral rank * z > total
            ]
        (k, s) = lastSafe (1, sorted !! 0) active
        threshold = (s - 1) / fromIntegral k
        ys = map (\x -> max 0 (x - threshold)) shifted
    finite ys
    Right ys
  where
    tailSafe [] = []; tailSafe (_ : ys) = ys
    lastSafe z [] = z; lastSafe _ [y] = y; lastSafe z (_ : ys) = lastSafe z ys

-- | Multiply values by sigmoid(gates), requiring equal vector lengths.
gatedLinearUnit :: [Double] -> [Double] -> Either MathError [Double]
gatedLinearUnit values gate = do
    finite (values ++ gate)
    if length values /= length gate
        then Left (VectorLengthMismatch (length values) (length gate))
        else Right (zipWith (\x g -> x * sigmoid g) values gate)

data Reduction = Sum | Mean deriving (Eq, Show)
data Loss
    = MeanSquaredError
    | MeanAbsoluteError
    | Huber Double
    | SmoothL1 Double
    | BinaryCrossEntropy
    | CategoricalCrossEntropy
    | NegativeLogLikelihood
    | KLDivergence
    | CosineLoss
    | Hinge Double
    deriving (Eq, Show)
validatePair :: [Double] -> [Double] -> Either MathError ()
validatePair target prediction = do
    finite (target ++ prediction)
    if null target || length target /= length prediction
        then Left (InvalidArgument "nonempty equal loss vectors required")
        else Right ()
probability :: [Double] -> Either MathError ()
probability xs =
    if any (\x -> x < 0 || x > 1) xs then Left (DomainError "probability outside [0,1]") else finite xs

-- | Evaluate the selected checked loss. Mean divides elementwise losses by count; CosineLoss is one vector loss.
loss :: Loss -> Reduction -> [Double] -> [Double] -> Either MathError Double
loss kind reduction target prediction = do
    validatePair target prediction
    value <- case kind of
        CosineLoss -> do
            (a, _, _) <- unitVector target
            (b, _, _) <- unitVector prediction
            Right (1 - sum (zipWith (*) a b))
        _ -> do
            vals <- mapM term (zip target prediction)
            Right (sum vals / (if reduction == Mean then fromIntegral (length vals) else 1))
    finite [value]
    Right value
  where
    term (t, p) = case kind of
        MeanSquaredError -> Right ((p - t) ^ (2 :: Int))
        MeanAbsoluteError -> Right (abs (p - t))
        Huber delta
            | delta > 0 ->
                Right (if abs (p - t) <= delta then (p - t) ^ (2 :: Int) / 2 else delta * (abs (p - t) - delta / 2))
            | otherwise -> Left (DomainError "positive Huber delta required")
        SmoothL1 beta
            | beta > 0 ->
                Right (if abs (p - t) < beta then (p - t) ^ (2 :: Int) / (2 * beta) else abs (p - t) - beta / 2)
            | otherwise -> Left (DomainError "positive smooth L1 beta required")
        BinaryCrossEntropy -> do probability [t, p]; logTerm t p >>= \a -> logTerm (1 - t) (1 - p) >>= \b -> Right (a + b)
        CategoricalCrossEntropy -> do probability [t, p]; logTerm t p
        NegativeLogLikelihood -> do
            probability [t]
            if p > 0 then Left (DomainError "NLL expects nonpositive log probabilities") else Right (-t * p)
        KLDivergence -> do
            probability [t, p]
            if t == 0
                then Right 0
                else if p == 0 then Left (DomainError "KL zero denominator") else Right (t * log (t / p))
        Hinge margin
            | margin > 0 && abs t == 1 -> Right (max 0 (margin - t * p))
            | otherwise -> Left (DomainError "hinge margin or +/-1 label")
        CosineLoss -> Left (InvalidArgument "internal cosine loss")
    logTerm 0 _ = Right 0
    logTerm t p
        | p <= 0 = Left (DomainError "positive probability required for nonzero target")
        | otherwise = Right (-t * log p)

-- | Analytic derivatives with respect to predictions under the exact loss/reduction convention.
lossGradient :: Loss -> Reduction -> [Double] -> [Double] -> Either MathError [Double]
lossGradient kind reduction target prediction = do
    _ <- loss kind reduction target prediction
    let n = if reduction == Mean && kind /= CosineLoss then fromIntegral (length target) else 1
        derivatives = case kind of
            CosineLoss -> case (unitVector target, unitVector prediction) of
                (Right (a, _, _), Right (b, m, s)) -> let cosine = sum (zipWith (*) a b) in zipWith (\t p -> ((cosine * p - t) / m) / s) a b
                _ -> replicate (length target) (0 / 0)
            _ -> zipWith derivative target prediction
    finite derivatives
    Right (map (/ n) derivatives)
  where
    derivative t p = case kind of
        MeanSquaredError -> 2 * (p - t)
        MeanAbsoluteError -> signum (p - t)
        Huber d -> max (-d) (min d (p - t))
        SmoothL1 b -> if abs (p - t) < b then (p - t) / b else signum (p - t)
        BinaryCrossEntropy -> (if t == 0 then 0 else -t / p) + (if t == 1 then 0 else (1 - t) / (1 - p))
        CategoricalCrossEntropy -> if t == 0 then 0 else -t / p
        NegativeLogLikelihood -> -t
        KLDivergence -> if t == 0 then 0 else -t / p
        Hinge margin -> if t * p < margin then -t else 0
        CosineLoss -> 0

-- | Use a constant target with symbolic prediction inputs and the matching analytic reverse rule.
lossExpr :: Loss -> Reduction -> [Double] -> [AD.Expr] -> AD.Expr
lossExpr kind reduction target =
    AD.customOperation
        ( \xs -> do y <- loss kind reduction target xs; gs <- lossGradient kind reduction target xs; Right (y, gs)
        )

-- | Stable binary cross entropy from logits and [0,1] targets, including extreme finite logits.
binaryCrossEntropyLogits :: Reduction -> [Double] -> [Double] -> Either MathError Double
binaryCrossEntropyLogits reduction target logits = do
    validatePair target logits
    probability target
    let values = zipWith (\t x -> max x 0 - x * t + log (1 + exp (-abs x))) target logits
        y = sum values / (if reduction == Mean then fromIntegral (length values) else 1)
    finite [y]
    Right y

-- | Cross entropy from one class-logit vector; nonnegative targets must sum to one.
categoricalCrossEntropyLogits :: [Double] -> [Double] -> Either MathError Double
categoricalCrossEntropyLogits target logits = do
    validatePair target logits
    probability target
    if abs (sum target - 1) > 1e-10
        then Left (DomainError "categorical targets must sum to one")
        else Right ()
    logs <- logSoftmax logits
    Right (-sum (zipWith (*) target logs))

-- | Return l1*sum(abs(w)) + l2/2*sum(w*w); both coefficients must be finite and nonnegative.
regularization :: Double -> Double -> [Double] -> Either MathError Double
regularization l1 l2 weights = do
    finite (l1 : l2 : weights)
    if l1 < 0 || l2 < 0 then Left (DomainError "negative regularization") else Right ()
    let value =
            (if l1 == 0 then 0 else l1 * sum (map abs weights))
                + (if l2 == 0 then 0 else l2 / 2 * sum (map (\x -> x * x) weights))
    finite [value]
    Right value

-- | Pairwise Euclidean contrastive loss; similar=True penalizes squared distance and dissimilar pairs use the positive margin.
contrastiveLoss :: Double -> Bool -> [Double] -> [Double] -> Either MathError Double
contrastiveLoss margin similar a b = do
    validatePair a b
    finite [margin]
    if margin <= 0 then Left (DomainError "positive contrastive margin") else Right ()
    let d2 = sum (zipWith (\x y -> (x - y) ^ (2 :: Int)) a b)
    let value = if similar then d2 / 2 else max 0 (margin - sqrt d2) ^ (2 :: Int) / 2
    finite [value]
    Right value

-- | Return max(0,positiveDistance-negativeDistance+margin) for equal nonempty vector dimensions.
tripletLoss :: Double -> [Double] -> [Double] -> [Double] -> Either MathError Double
tripletLoss margin anchor positive negative = do
    validatePair anchor positive
    validatePair anchor negative
    finite [margin]
    if margin < 0 then Left (DomainError "negative triplet margin") else Right ()
    let distance a b = sqrt (sum (zipWith (\x y -> (x - y) ^ (2 :: Int)) a b))
    let value = max 0 (distance anchor positive - distance anchor negative + margin)
    finite [distance anchor positive, distance anchor negative, value]
    Right value

-- | Mean binary focal loss with alpha in [0,1], gamma>=0, and exact zero/one targets.
focalLoss :: Double -> Double -> [Double] -> [Double] -> Either MathError Double
focalLoss alpha gamma target prediction = do
    validatePair target prediction
    probability (alpha : target ++ prediction)
    finite [gamma]
    if gamma < 0 || any (\t -> t /= 0 && t /= 1) target
        then Left (DomainError "focal gamma or binary labels")
        else Right ()
    vals <-
        mapM
            ( \(t, p) ->
                let pt = if t == 1 then p else 1 - p; at = if t == 1 then alpha else 1 - alpha
                 in if pt == 0
                        then Left (DomainError "focal impossible event")
                        else Right (-at * (1 - pt) ** gamma * log pt)
            )
            (zip target prediction)
    Right (sum vals / fromIntegral (length vals))

-- | Soft segmentation overlap losses on [0,1] values; positive smoothing defines the empty-mask case.
diceLoss, iouLoss :: Double -> [Double] -> [Double] -> Either MathError Double
diceLoss smooth target prediction = do
    validatePair target prediction
    probability (target ++ prediction)
    finite [smooth]
    if smooth <= 0 then Left (DomainError "positive Dice smoothing") else Right ()
    Right
        (1 - (2 * sum (zipWith (*) target prediction) + smooth) / (sum target + sum prediction + smooth))
iouLoss smooth target prediction = do
    validatePair target prediction
    probability (target ++ prediction)
    finite [smooth]
    if smooth <= 0 then Left (DomainError "positive IoU smoothing") else Right ()
    let intersection = sum (zipWith (*) target prediction)
    Right (1 - (intersection + smooth) / (sum target + sum prediction - intersection + smooth))

{- | Single sequence, time-major log-probabilities [time,class]. Blank index is
explicit; labels exclude blank. The forward/backward dynamic program sums
alignments in log space, including adjacent repeated-label restrictions.
Gradients are with respect to independent log probabilities, before a
log-softmax chain rule. Impossible alignments return DomainError.
-}
ctcLoss :: Int -> [Int] -> [[Double]] -> Either MathError Double
ctcLoss blank labels logs = fst <$> ctcLossGradient blank labels logs

ctcLossGradient :: Int -> [Int] -> [[Double]] -> Either MathError (Double, [[Double]])
ctcLossGradient blank labels logs = do
    case logs of
        [] -> if null labels then Right (0, []) else Left (DomainError "CTC nonempty labels with empty time")
        first : _ ->
            if null first || any ((/= length first) . length) logs
                then Left (InvalidArgument "CTC rectangular class dimension")
                else calculate (length first)
  where
    calculate classes = do
        finite (concat logs)
        if blank < 0
            || blank >= classes
            || any (\i -> i < 0 || i >= classes || i == blank) labels
            || any (> 0) (concat logs)
            then Left (DomainError "CTC blank, labels, or log probabilities")
            else Right ()
        let states = concatMap (\l -> [blank, l]) labels ++ [blank]
            count = length states
            times = length logs
            neg = -1 / 0
            initial = [if s == 0 || s == 1 then (logs !! 0) !! (states !! s) else neg | s <- [0 .. count - 1]]
            forwardStep previous row =
                [ row !! (states !! s)
                    + logAdd
                        [ previous !! j
                        | j <- [max 0 (s - 2) .. s]
                        , j == s || j == s - 1 || (states !! s /= blank && states !! s /= states !! j)
                        ]
                | s <- [0 .. count - 1]
                ]
            alphas = scanl forwardStep initial (drop 1 logs)
            terminal = [if s >= count - 2 then 0 else neg | s <- [0 .. count - 1]]
            backwardStep (time, next) _ =
                let row = logs !! (time + 1)
                    prev =
                        [ logAdd
                            [ row !! (states !! j) + next !! j
                            | j <- [s .. min (count - 1) (s + 2)]
                            , j == s || j == s + 1 || (states !! j /= blank && states !! j /= states !! s)
                            ]
                        | s <- [0 .. count - 1]
                        ]
                 in (time - 1, prev)
            backwards = map snd (scanl backwardStep (times - 2, terminal) [1 .. times - 1])
            betas = reverse backwards
            total =
                logAdd [lastRow !! s | s <- [max 0 (count - 2) .. count - 1], let lastRow = alphas !! (times - 1)]
        if isInfinite total || isNaN total
            then Left (DomainError "CTC alignment has zero probability")
            else Right ()
        let gradients =
                [ [ -sum [exp ((alphas !! t) !! s + (betas !! t) !! s - total) | s <- [0 .. count - 1], states !! s == c]
                  | c <- [0 .. classes - 1]
                  ]
                | t <- [0 .. times - 1]
                ]
        finite (concat gradients)
        Right (-total, gradients)
    logAdd xs = let m = maximum xs in if isInfinite m && m < 0 then m else m + log (sum [exp (x - m) | x <- xs])

-- | First-order softmax reverse rule, including cross-coordinate coupling.
softmaxExpr :: [AD.Expr] -> [AD.Expr]
softmaxExpr xs = [AD.customOperation (rule i) xs | i <- [0 .. length xs - 1]]
  where
    rule i values = do
        ps <- softmax values
        let p = ps !! i
        Right (p, [p * ((if i == j then 1 else 0) - q) | (j, q) <- zip [0 :: Int ..] ps])

-- | First-order stable log-softmax rule; gradient rows sum to zero.
logSoftmaxExpr :: [AD.Expr] -> [AD.Expr]
logSoftmaxExpr xs = [AD.customOperation (rule i) xs | i <- [0 .. length xs - 1]]
  where
    rule i values = do
        logs <- logSoftmax values
        Right (logs !! i, [(if i == j then 1 else 0) - exp p | (j, p) <- zip [0 :: Int ..] logs])

{- | Sparsemax's piecewise-linear Jacobian. At a support boundary its inactive
coordinate convention chooses zero, giving a defined subgradient.
-}
sparsemaxExpr :: [AD.Expr] -> [AD.Expr]
sparsemaxExpr xs = [AD.customOperation (rule i) xs | i <- [0 .. length xs - 1]]
  where
    rule i values = do
        ps <- sparsemax values
        let count = length (filter (> 0) ps)
            active = ps !! i > 0
        Right
            ( ps !! i
            , [ if active && p > 0 then (if i == j then 1 else 0) - 1 / fromIntegral count else 0
              | (j, p) <- zip [0 :: Int ..] ps
              ]
            )

{- | CTC graph operation on rectangular time-major log probabilities. Its custom
backward uses forward/backward occupancies, rather than numerical differences.
-}
ctcLossExpr :: Int -> [Int] -> [[AD.Expr]] -> Either MathError AD.Expr
ctcLossExpr blank labels logs = case logs of
    [] -> if null labels then Right 0 else Left (DomainError "empty CTC time")
    first : _
        | null first || any ((/= length first) . length) logs ->
            Left (InvalidArgument "CTC symbolic rectangular shape")
        | otherwise ->
            let classes = length first; times = length logs
             in Right
                    ( AD.customOperation
                        ( \values -> do
                            (value, grads) <-
                                ctcLossGradient blank labels [take classes (drop (t * classes) values) | t <- [0 .. times - 1]]
                            Right (value, concat grads)
                        )
                        (concat logs)
                    )

unitVector :: [Double] -> Either MathError ([Double], Double, Double)
unitVector values = do
    let m = maximum (0 : map abs values)
    if m == 0 then Left (DomainError "cosine loss zero vector") else Right ()
    let scaled = map (/ m) values
        s = sqrt (sum (map (\x -> x * x) scaled))
    Right (map (/ s) scaled, m, s)
