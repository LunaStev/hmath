-- SPDX-License-Identifier: MPL-2.0

{- | Reference numerical search and ordering algorithms. Search routines validate
ascending input (O(n)); their subsequent search is logarithmic except ternary
optimization. Pure comparison sorts accept any lawful total 'Ord'.
-}
module HMath.Algorithms (
    lowerBound,
    upperBound,
    binarySearch,
    interpolationSearch,
    exponentialSearch,
    ternarySearch,
    quickselect,
    introselect,
    partialSort,
    mergeSort,
    quicksort,
    heapsort,
    introsort,
    countingSort,
    radixSort,
    bucketSort,
    argsort,
    topK,
    quantileSelect,
    deduplicate,
    numericGroups,
    runLengthEncode,
    runLengthDecode,
    prefixSums,
    suffixSums,
    differenceArray,
    applyDifferences,
    coordinateCompression,
    intervalSweep,
    divideConquerDP,
    tabulateDP,
    memoizedDP,
    binaryLift,
    integerMatrixPower,
    polynomialHash,
    rollingHashes,
) where

import Data.Array (elems, listArray, (!), (//))
import qualified Data.Foldable as Foldable (foldl')
import Data.List (group, sort, sortOn)
import qualified Data.Map.Strict as M
import HMath.Error (MathError (..))

ordered :: (Ord a) => [a] -> Either MathError ()
ordered xs
    | and (zipWith (<=) xs (drop 1 xs)) = Right ()
    | otherwise = Left (InvalidArgument "search input must be ascending")

bound :: (Ord a) => (a -> a -> Bool) -> a -> [a] -> Int
bound cmp x xs = go 0 (length xs)
  where
    a = listArray (0, length xs - 1) xs
    go lo hi
        | lo >= hi = lo
        | cmp (a ! mid) x = go (mid + 1) hi
        | otherwise = go lo mid
      where
        mid = lo + (hi - lo) `div` 2
lowerBound, upperBound :: (Ord a) => a -> [a] -> Either MathError Int
lowerBound x xs = ordered xs >> pure (bound (<) x xs)
upperBound x xs = ordered xs >> pure (bound (<=) x xs)
binarySearch :: (Ord a) => a -> [a] -> Either MathError (Maybe Int)
binarySearch x xs = do i <- lowerBound x xs; pure (if i < length xs && xs !! i == x then Just i else Nothing)

interpolationSearch :: Integer -> [Integer] -> Either MathError (Maybe Int)
interpolationSearch x xs = do ordered xs; pure (go 0 (length xs - 1))
  where
    a = listArray (0, length xs - 1) xs
    go lo hi
        | lo > hi || x < a ! lo || x > a ! hi = Nothing
        | a ! lo == a ! hi = if x == a ! lo then Just lo else Nothing
        | a ! p == x = Just (bound (<) x xs)
        | a ! p < x = go (p + 1) hi
        | otherwise = go lo (p - 1)
      where
        p = lo + fromInteger ((x - a ! lo) * toInteger (hi - lo) `div` (a ! hi - a ! lo))
exponentialSearch :: (Ord a) => a -> [a] -> Either MathError (Maybe Int)
exponentialSearch x xs = do
    ordered xs
    let n = length xs
        hi = grow 1 n
        lo = hi `div` 2
        i = lo + bound (<) x (take (hi - lo + 1) (drop lo xs))
    pure (if i < n && xs !! i == x then Just i else Nothing)
  where
    grow k n | k >= n || xs !! k >= x = min k (max 0 (n - 1)) | otherwise = grow (2 * k) n

{- | Fixed-iteration minimization of a unimodal finite function on [lo,hi].
Returns the final bracket; unimodality is a caller precondition.
-}
ternarySearch :: Int -> (Double -> Double) -> Double -> Double -> Either MathError (Double, Double)
ternarySearch steps f lo hi
    | steps < 0 || steps > 100000 || not (all finite [lo, hi]) || lo > hi =
        Left (InvalidArgument "invalid ternary search interval/steps")
    | otherwise = go steps lo hi
  where
    finite x = not (isNaN x || isInfinite x)
    go 0 a b = Right (a, b)
    go k a b =
        let c = a + (b - a) / 3; d = b - (b - a) / 3; u = f c; v = f d
         in if not (all finite [c, d, u, v])
                then Left NonFiniteResult
                else if u < v then go (k - 1) a d else go (k - 1) c b

select :: (Ord a) => Int -> Int -> [a] -> a
select depth k xs
    | length xs <= 1 = xs !! 0
    | depth == 0 = heapsort xs !! k
    | k < length lo = select (depth - 1) k lo
    | k < length lo + length eq = p
    | otherwise = select (depth - 1) (k - length lo - length eq) hi
  where
    p = xs !! (length xs `div` 2); lo = filter (< p) xs; eq = filter (== p) xs; hi = filter (> p) xs
quickselect, introselect :: (Ord a) => Int -> [a] -> Either MathError a
quickselect k xs
    | k < 0 || k >= length xs = Left (InvalidArgument "selection index out of bounds")
    | otherwise = Right (select (length xs) k xs)
introselect k xs
    | k < 0 || k >= length xs = Left (InvalidArgument "selection index out of bounds")
    | otherwise = Right (select (2 * log2 (length xs)) k xs)
log2 :: Int -> Int
log2 n | n <= 1 = 0 | otherwise = 1 + log2 (n `div` 2)
partialSort :: (Ord a) => Int -> [a] -> Either MathError [a]
partialSort k xs
    | k < 0 || k > length xs = Left (InvalidArgument "partial-sort size out of bounds")
    | k == 0 = Right []
    | otherwise = do
        p <- introselect (k - 1) xs
        let lo = filter (< p) xs
        pure (mergeSort lo ++ take (k - length lo) (filter (== p) xs))
mergeSort :: (Ord a) => [a] -> [a]
mergeSort [] = []
mergeSort [x] = [x]
mergeSort xs = merge (mergeSort a) (mergeSort b)
  where
    (a, b) = splitAt (length xs `div` 2) xs
    merge [] ys = ys
    merge ys [] = ys
    merge aa@(u : us) bb@(v : vs) | u <= v = u : merge us bb | otherwise = v : merge aa vs
quicksort :: (Ord a) => [a] -> [a]
quicksort [] = []
quicksort (p : xs) = quicksort (filter (< p) xs) ++ (p : filter (== p) xs) ++ quicksort (filter (> p) xs)

{- | In-place-style array max heap with persistent updates. Correct heap sort;
persistence adds allocation to the usual O(n log n) comparisons.
-}
heapsort :: (Ord a) => [a] -> [a]
heapsort xs = elems (extract (n - 1) built)
  where
    n = length xs
    a = listArray (0, n - 1) xs
    swap ar i j = ar // [(i, ar ! j), (j, ar ! i)]
    sift ar size i
        | left >= size = ar
        | ar ! i >= ar ! child = ar
        | otherwise = sift (swap ar i child) size child
      where
        left = 2 * i + 1
        right = left + 1
        child = if right < size && ar ! right > ar ! left then right else left
    built = Foldable.foldl' (\ar i -> sift ar n i) a [n `div` 2 - 1, n `div` 2 - 2 .. 0]
    extract i ar | i <= 0 = ar | otherwise = extract (i - 1) (sift (swap ar 0 i) i 0)

introsort :: (Ord a) => [a] -> [a]
introsort xs = go (2 * log2 (length xs)) xs
  where
    go _ [] = []
    go 0 ys = heapsort ys
    go d ys =
        let p = ys !! (length ys `div` 2)
         in go (d - 1) (filter (< p) ys) ++ filter (== p) ys ++ go (d - 1) (filter (> p) ys)
countingSort :: Int -> [Int] -> Either MathError [Int]
countingSort budget xs
    | budget < 0 = Left (InvalidArgument "negative counting-sort range budget")
    | null xs = Right []
    | toInteger hi - toInteger lo + 1 > toInteger budget =
        Left (NonConvergence "counting sort range" budget)
    | otherwise = Right (concat [replicate (M.findWithDefault 0 x counts) x | x <- [lo .. hi]])
  where
    lo = minimum xs; hi = maximum xs; counts = M.fromListWith (+) [(x, 1) | x <- xs]
radixSort :: [Integer] -> [Integer]
radixSort [] = []
radixSort xs = map (+ lo) (go 1 shifted)
  where
    lo = minimum xs
    shifted = map (subtract lo) xs
    hi = maximum shifted
    go p ys
        | p > hi = ys
        | otherwise = go (p * 256) (concat [[x | x <- ys, (x `div` p) `mod` 256 == d] | d <- [0 .. 255]])
bucketSort :: Int -> [Double] -> Either MathError [Double]
bucketSort buckets xs
    | buckets <= 0 || buckets > 65536 = Left (InvalidArgument "bucket count must be in [1,65536]")
    | any (\x -> isNaN x || isInfinite x || x < 0 || x > 1) xs =
        Left (DomainError "bucket sort values must be in [0,1]")
    | otherwise = Right (concat [mergeSort [x | x <- xs, index x == i] | i <- [0 .. buckets - 1]])
  where
    index x = min (buckets - 1) (floor (x * fromIntegral buckets))
argsort :: (Ord a) => [a] -> [Int]
argsort = map snd . mergeSort . flip zip [0 ..]
topK :: (Ord a) => Int -> [a] -> Either MathError [a]
topK = partialSort
quantileSelect :: Double -> [Double] -> Either MathError Double
quantileSelect q xs
    | null xs || q < 0 || q > 1 || any (\x -> isNaN x || isInfinite x) (q : xs) =
        Left (InvalidArgument "invalid quantile input")
    | otherwise = do a <- introselect lo xs; b <- introselect hi xs; pure ((1 - t) * a + t * b)
  where
    p = q * fromIntegral (length xs - 1); lo = floor p; hi = ceiling p; t = p - fromIntegral lo
deduplicate :: (Ord a) => [a] -> [a]
deduplicate xs = [x | x : _ <- group (mergeSort xs)]
numericGroups :: (Ord a) => [a] -> [(a, Int)]
numericGroups xs = [(x, length g) | g@(x : _) <- group (mergeSort xs)]
runLengthEncode :: (Eq a) => [a] -> [(a, Int)]
runLengthEncode xs = [(x, length g) | g@(x : _) <- group xs]
runLengthDecode :: Int -> [(a, Int)] -> Either MathError [a]
runLengthDecode b runs
    | b < 0 || any ((< 0) . snd) runs = Left (InvalidArgument "negative RLE size")
    | sum (map (toInteger . snd) runs) > toInteger b = Left (NonConvergence "RLE output" b)
    | otherwise = Right (concatMap (uncurry (flip replicate)) runs)
prefixSums, suffixSums, differenceArray, applyDifferences :: (Num a) => [a] -> [a]
prefixSums = scanl (+) 0
suffixSums = scanr (+) 0
differenceArray [] = []
differenceArray xs = zipWith (-) xs (0 : xs)
applyDifferences = drop 1 . prefixSums
coordinateCompression :: (Ord a) => [a] -> ([a], [Int])
coordinateCompression xs = (keys, map (\x -> table M.! x) xs)
  where
    keys = deduplicate xs; table = M.fromList (zip keys [0 ..])

{- | Half-open interval union length and peak overlap; zero-length intervals
contribute neither. End events precede starts at the same coordinate.
-}
intervalSweep :: [(Integer, Integer)] -> Either MathError (Integer, Int)
intervalSweep intervals
    | any (uncurry (>)) intervals = Left (InvalidArgument "reversed interval")
    | otherwise = Right (go events 0 0 0 0)
  where
    events = sort (concat [[(a, 1 :: Int), (b, -1)] | (a, b) <- intervals, a < b])
    go [] _ _ total peak = (total, peak)
    go ((x, d) : rest) old active total peak = go rest x (active + d) (total + if active > 0 then x - old else 0) (max peak (active + d))

{- | One DP layer @next[j] = min_{0<=k<j} previous[k]+cost k j@.
Monotone argmins are checked against all candidates before returning;
invalid optimization assumptions fail explicitly. O(n^2) validation.
-}
divideConquerDP :: [Double] -> (Int -> Int -> Double) -> Either MathError [Double]
divideConquerDP prev cost
    | null prev || length prev > 4096 || any bad prev = Left (InvalidArgument "invalid DP layer")
    | otherwise = do
        let n = length prev
            solve l r a b
                | l > r = []
                | otherwise =
                    let m = (l + r) `div` 2
                        candidates = [(prev !! j + cost j m, j) | j <- [a .. min b (m - 1)]]
                        (v, k) = minimum candidates
                     in solve l (m - 1) a k ++ [(m, v, k)] ++ solve (m + 1) r k b
            out = sortOn (\(i, _, _) -> i) (solve 1 n 0 (n - 1))
        if any (\(j, v, _) -> bad v || v /= minimum [prev !! k + cost k j | k <- [0 .. j - 1]]) out
            then Left (InvalidArgument "nonfinite costs or nonmonotone DP argmins")
            else pure [v | (_, v, _) <- out]
  where
    bad x = isNaN x || isInfinite x

-- | Bottom-up bounded DAG recurrence; dependencies must have lower indices.
tabulateDP :: Int -> (Int -> [(Int, Integer)]) -> Either MathError [Integer]
tabulateDP n recurrence
    | n < 0 || n > 100000 = Left (InvalidArgument "DP size exceeds 100000")
    | otherwise = go 0 []
  where
    go i values
        | i == n = Right values
        | otherwise =
            let terms = recurrence i
             in if any (\(j, _) -> j < 0 || j >= i) terms
                    then Left (InvalidArgument "DP dependency is not earlier")
                    else go (i + 1) (values ++ [if null terms then 1 else sum [c * values !! j | (j, c) <- terms]])

{- | Top-down memoization with a node budget. Recurrence supplies an additive
constant and weighted dependencies; cycles are rejected.
-}
memoizedDP :: Int -> (Int -> (Integer, [(Int, Integer)])) -> Int -> Either MathError Integer
memoizedDP b recurrence target
    | b < 0 = Left (InvalidArgument "negative memoization budget")
    | otherwise = do (v, _, _) <- go b [] M.empty target; pure v
  where
    go fuel stack cache x = case M.lookup x cache of
        Just v -> Right (v, fuel, cache)
        Nothing
            | x `elem` stack -> Left (InvalidArgument "cyclic recurrence")
            | fuel <= 0 -> Left (NonConvergence "memoized DP" b)
            | otherwise -> do
                let (base, terms) = recurrence x
                (v, f, c) <-
                    Foldable.foldl'
                        ( \result (j, w) -> do (v, f, c) <- result; (u, f', c') <- go f (x : stack) c j; pure (v + w * u, f', c')
                        )
                        (Right (base, fuel - 1, cache))
                        terms
                pure (v, f, M.insert x v c)

-- | K-fold application of a total finite successor map, by repeated squaring.
binaryLift :: [Int] -> Integer -> Int -> Either MathError Int
binaryLift next steps start
    | steps < 0 || start < 0 || start >= length next || any (\i -> i < 0 || i >= length next) next =
        Left (InvalidArgument "invalid lifting map/index")
    | otherwise = Right (go next steps start)
  where
    go _ 0 x = x; go table k x = go (map (table !!) table) (k `div` 2) (if odd k then table !! x else x)

integerMatrixPower :: [[Integer]] -> Integer -> Either MathError [[Integer]]
integerMatrixPower a powerIndex
    | powerIndex < 0 || length a > 128 || any ((/= n) . length) a =
        Left (InvalidArgument "invalid square integer matrix/exponent")
    | otherwise = Right (go a powerIndex identity)
  where
    n = length a
    identity = [[if i == j then 1 else 0 | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
    mul x y = [[sum [x !! i !! k * y !! k !! j | k <- [0 .. n - 1]] | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
    go _ 0 r = r
    go x k r = go (mul x x) (k `div` 2) (if odd k then mul r x else r)
polynomialHash :: Integer -> Integer -> [Integer] -> Either MathError Integer
polynomialHash base modulus xs
    | modulus <= 1 = Left (InvalidArgument "hash modulus must exceed one")
    | otherwise = Right (Foldable.foldl' (\h x -> (h * base + x) `mod` modulus) 0 xs)

-- | Noncryptographic polynomial rolling hash; equal hashes can collide.
rollingHashes :: Integer -> Integer -> Int -> [Integer] -> Either MathError [Integer]
rollingHashes base modulus width xs
    | modulus <= 1 || width < 0 || width > length xs =
        Left (InvalidArgument "invalid rolling hash window/modulus")
    | width == 0 = Right (replicate (length xs + 1) 0)
    | otherwise = do
        h <- polynomialHash base modulus (take width xs)
        let power = pow base (width - 1) 1
            go _ [] _ = []
            go _ _ [] = []
            go old (a : as) (b : bs) = let v = ((old - a * power) * base + b) `mod` modulus in v : go v as bs
        pure (h : go h xs (drop width xs))
  where
    pow _ 0 r = r
    pow x k r = pow (x * x `mod` modulus) (k `div` 2) (if odd k then r * x `mod` modulus else r)
