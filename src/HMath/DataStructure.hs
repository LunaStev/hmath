-- SPDX-License-Identifier: MPL-2.0

{- | Persistent finite range, queue, heap and streaming structures. Constructors
are opaque. Indices and half-open ranges are checked. Persistent array updates
copy storage; asymptotic logarithmic claims refer to arithmetic/comparisons.
-}
module HMath.DataStructure (
    Fenwick,
    fenwick,
    fenwickAdd,
    fenwickPrefix,
    fenwickRange,
    SegmentTree,
    segmentTree,
    segmentSet,
    segmentRange,
    SparseTable,
    sparseTable,
    sparseMinimum,
    DisjointSparseTable,
    disjointSparseTable,
    disjointRange,
    monotonicMinima,
    nextGreater,
    Heap,
    emptyHeap,
    heapInsert,
    heapPop,
    heapFromList,
    BinaryHeap,
    binaryHeap,
    binaryInsert,
    binaryPop,
    IndexedHeap,
    indexedHeap,
    indexedSet,
    indexedPop,
    UnionFind,
    unionFind,
    findRoot,
    union,
    connected,
    components,
    Bloom,
    bloom,
    bloomInsert,
    bloomMember,
    bloomFalsePositiveBound,
    CountMin,
    countMin,
    countMinAdd,
    countMinEstimate,
    countMinErrorBound,
    HyperLogLog,
    hyperLogLog,
    hllAdd,
    hllEstimate,
    Reservoir,
    reservoir,
    reservoirAdd,
    reservoirValues,
    OnlineQuantiles,
    onlineQuantiles,
    quantileAdd,
    onlineQuantile,
) where

import Data.Array (Array, array, elems, listArray, (!), (//))
import Data.Bits
import qualified Data.Foldable as Foldable (foldl')
import qualified Data.Map.Strict as M
import Data.Word (Word64)
import HMath.Error (MathError (..))

checkSize :: Int -> Either MathError ()
checkSize n
    | n < 0 || n > 1048576 = Left (InvalidArgument "structure size exceeds 1048576")
    | otherwise = Right ()
checkRange :: Int -> Int -> Int -> Either MathError ()
checkRange n lo hi | lo < 0 || hi < lo || hi > n = Left (InvalidArgument "range out of bounds") | otherwise = Right ()

data Fenwick = Fenwick Int (Array Int Integer) deriving (Eq, Show)
fenwick :: [Integer] -> Either MathError Fenwick
fenwick xs = do
    checkSize (length xs)
    Foldable.foldl'
        (\p (i, x) -> p >>= fenwickAdd i x)
        (Right (Fenwick (length xs) (listArray (1, length xs) (replicate (length xs) 0))))
        (zip [0 ..] xs)
fenwickAdd :: Int -> Integer -> Fenwick -> Either MathError Fenwick
fenwickAdd i delta (Fenwick n a)
    | i < 0 || i >= n = Left (InvalidArgument "Fenwick update index out of bounds")
    | otherwise =
        Right
            ( Fenwick
                n
                (a // [(j, a ! j + delta) | j <- takeWhile (<= n) (iterate (\k -> k + (k .&. (-k))) (i + 1))])
            )
fenwickPrefix :: Int -> Fenwick -> Either MathError Integer
fenwickPrefix end (Fenwick n a) = do
    checkRange n 0 end; pure (sum [a ! j | j <- takeWhile (> 0) (iterate (\k -> k - (k .&. (-k))) end)])
fenwickRange :: Int -> Int -> Fenwick -> Either MathError Integer
fenwickRange lo hi t@(Fenwick n _) = do checkRange n lo hi; (-) <$> fenwickPrefix hi t <*> fenwickPrefix lo t

data SegmentTree = SegmentTree Int Int (Array Int Integer) deriving (Eq, Show)
powerTwo :: Int -> Int
powerTwo n = go 1
  where
    go p | p >= n = p | otherwise = go (p * 2)

segmentTree :: [Integer] -> Either MathError SegmentTree
segmentTree xs = do
    checkSize (length xs)
    let n = length xs
        size = powerTwo (max 1 n)
        a = array (1, 2 * size - 1) [(i, value i) | i <- [1 .. 2 * size - 1]]
        value i
            | i >= size = if i - size < n then xs !! (i - size) else 0
            | otherwise = a ! (2 * i) + a ! (2 * i + 1)
    pure (SegmentTree n size a)
segmentSet :: Int -> Integer -> SegmentTree -> Either MathError SegmentTree
segmentSet i x (SegmentTree n size a)
    | i < 0 || i >= n = Left (InvalidArgument "segment update index out of bounds")
    | otherwise = Right (SegmentTree n size (go (i + size) (a // [(i + size, x)])))
  where
    go j ar
        | j <= 1 = ar
        | otherwise = let p = j `div` 2 in go p (ar // [(p, ar ! (2 * p) + ar ! (2 * p + 1))])
segmentRange :: Int -> Int -> SegmentTree -> Either MathError Integer
segmentRange lo hi (SegmentTree n size a) = do checkRange n lo hi; pure (go (lo + size) (hi + size) 0)
  where
    go l r acc
        | l >= r = acc
        | otherwise =
            go ((l + 1) `div` 2) (r `div` 2) (acc + if odd l then a ! l else 0 + 0)
                `addRight` (if odd r then a ! (r - 1) else 0)
    addRight x y = x + y

data SparseTable = SparseTable Int [Array Int Integer] deriving (Eq, Show)
sparseTable :: [Integer] -> Either MathError SparseTable
sparseTable xs = do
    checkSize (length xs)
    let n = length xs
        firstLevel = listArray (0, n - 1) xs
        build width previous
            | width > n = []
            | otherwise =
                let table =
                        listArray
                            (0, n - width)
                            [min (previous ! i) (previous ! (i + width `div` 2)) | i <- [0 .. n - width]]
                 in table : build (width * 2) table
    pure (SparseTable n (if n == 0 then [] else firstLevel : build 2 firstLevel))

sparseMinimum :: Int -> Int -> SparseTable -> Either MathError Integer
sparseMinimum lo hi (SparseTable n tables) = do
    checkRange n lo hi
    if lo == hi
        then Left (DomainError "empty minimum range")
        else
            let k = integerLog (hi - lo); width = 2 ^ k
             in pure (min ((tables !! k) ! lo) ((tables !! k) ! (hi - width)))
integerLog :: Int -> Int
integerLog n | n <= 1 = 0 | otherwise = 1 + integerLog (n `div` 2)

data DisjointSparseTable = DisjointSparseTable [Integer] [Array Int Integer] deriving (Eq, Show)

{- | Suffix/prefix blocks for associative integer addition, O(n log n) build and
O(1) arithmetic for nonempty queries. Also handles an empty range as zero.
-}
disjointSparseTable :: [Integer] -> Either MathError DisjointSparseTable
disjointSparseTable xs = do
    checkSize (length xs)
    let n = length xs
        level k =
            listArray
                (0, n - 1)
                (concat [block (take (2 ^ (k + 1)) (drop start xs)) (2 ^ k) | start <- [0, 2 ^ (k + 1) .. n - 1]])
        block ys half = let (a, b) = splitAt half ys in scanr1Safe a ++ scanl1 (+) b
        scanr1Safe [] = []; scanr1Safe ys = scanr1 (+) ys
    pure (DisjointSparseTable xs [level k | k <- [0 .. integerLog (max 1 n)]])

disjointRange :: Int -> Int -> DisjointSparseTable -> Either MathError Integer
disjointRange lo hi (DisjointSparseTable xs tables) = do
    checkRange (length xs) lo hi
    if lo == hi
        then pure 0
        else
            if hi == lo + 1
                then pure (xs !! lo)
                else let k = integerLog (lo `xor` (hi - 1)); a = tables !! k in pure (a ! lo + a ! (hi - 1))

{- | Sliding minima using an increasing deque of indices; output windows are
complete only. This list-backed reference deque has O(n*w) worst-case moves.
-}
monotonicMinima :: (Ord a) => Int -> [a] -> Either MathError [a]
monotonicMinima width xs
    | width <= 0 = Left (InvalidArgument "window width must be positive")
    | otherwise = Right (go [] (zip [0 :: Int ..] xs))
  where
    go _ [] = []
    go queue ((i, x) : rest) =
        let q = filter ((> i - width) . fst) queue
            q' = reverse (dropWhile ((>= x) . snd) (reverse q)) ++ [(i, x)]
         in (if i >= width - 1 then [snd (q' !! 0)] else []) ++ go q' rest

nextGreater :: (Ord a) => [a] -> [Maybe Int]
nextGreater xs = map (\i -> M.lookup i result) [0 .. length xs - 1]
  where
    (_, result) = Foldable.foldl' step ([], M.empty) (zip [0 :: Int ..] xs)
    step (stack, out) (i, x) =
        let (popped, keep) = span ((< x) . snd) stack
         in ((i, x) : keep, Foldable.foldl' (\m (j, _) -> M.insert j i m) out popped)

-- | Leftist binary min heap, O(log n) merge/insert/delete-min comparisons.
data Heap a = Empty | Node Int a (Heap a) (Heap a) deriving (Eq, Show)

emptyHeap :: Heap a
emptyHeap = Empty
rank :: Heap a -> Int
rank Empty = 0; rank (Node r _ _ _) = r
mergeHeap :: (Ord a) => Heap a -> Heap a -> Heap a
mergeHeap Empty b = b
mergeHeap a Empty = a
mergeHeap a@(Node _ x l r) b@(Node _ y _ _)
    | x > y = mergeHeap b a
    | rank l >= rank z = Node (rank z + 1) x l z
    | otherwise = Node (rank l + 1) x z l
  where
    z = mergeHeap r b
heapInsert :: (Ord a) => a -> Heap a -> Heap a
heapInsert x = mergeHeap (Node 1 x Empty Empty)
heapPop :: (Ord a) => Heap a -> Maybe (a, Heap a)
heapPop Empty = Nothing
heapPop (Node _ x l r) = Just (x, mergeHeap l r)
heapFromList :: (Ord a) => [a] -> Heap a
heapFromList = Foldable.foldl' (flip heapInsert) Empty

{- | Complete binary min heap in an array. Persistence copies the backing
array; sift operations make O(log n) comparisons.
-}
newtype BinaryHeap = BinaryHeap (Array Int Integer) deriving (Eq, Show)

binaryHeap :: [Integer] -> Either MathError BinaryHeap
binaryHeap xs = do
    checkSize (length xs)
    pure (Foldable.foldl' (flip binaryInsert) (BinaryHeap (listArray (0, -1) [])) xs)
binaryInsert :: Integer -> BinaryHeap -> BinaryHeap
binaryInsert value (BinaryHeap old) = BinaryHeap (bubble (length values) (listArray (0, length values) (values ++ [value])))
  where
    values = elems old
    bubble i a
        | i == 0 = a
        | a ! parent <= a ! i = a
        | otherwise = bubble parent (a // [(parent, a ! i), (i, a ! parent)])
      where
        parent = (i - 1) `div` 2
binaryPop :: BinaryHeap -> Maybe (Integer, BinaryHeap)
binaryPop (BinaryHeap old) = case elems old of
    [] -> Nothing
    [x] -> Just (x, BinaryHeap (listArray (0, -1) []))
    values@(x : _) ->
        let n = length values - 1
            initialArray = listArray (0, n - 1) (last values : take (n - 1) (drop 1 values))
            sift i a
                | left >= n = a
                | a ! i <= a ! child = a
                | otherwise = sift child (a // [(i, a ! child), (child, a ! i)])
              where
                left = 2 * i + 1
                right = left + 1
                child = if right < n && a ! right < a ! left then right else left
         in Just (x, BinaryHeap (sift 0 initialArray))

{- | An indexed priority queue backed by an ordered map and a binary heap.
Updates lazily invalidate old heap entries; pop discards stale entries.
-}
data IndexedHeap = IndexedHeap (M.Map Int Integer) (Heap (Integer, Int)) deriving (Eq, Show)

indexedHeap :: IndexedHeap
indexedHeap = IndexedHeap M.empty Empty
indexedSet :: Int -> Integer -> IndexedHeap -> IndexedHeap
indexedSet key value (IndexedHeap entries h) = IndexedHeap (M.insert key value entries) (heapInsert (value, key) h)
indexedPop :: IndexedHeap -> Maybe ((Int, Integer), IndexedHeap)
indexedPop (IndexedHeap entries h) = case heapPop h of
    Nothing -> Nothing
    Just ((v, k), rest)
        | M.lookup k entries == Just v -> Just ((k, v), IndexedHeap (M.delete k entries) rest)
        | otherwise -> indexedPop (IndexedHeap entries rest)

data UnionFind = UnionFind (Array Int Int) (Array Int Int) deriving (Eq, Show)
unionFind :: Int -> Either MathError UnionFind
unionFind n = do
    checkSize n
    pure (UnionFind (listArray (0, n - 1) [0 .. n - 1]) (listArray (0, n - 1) (replicate n 1)))
findRoot :: Int -> UnionFind -> Either MathError Int
findRoot i (UnionFind parent _)
    | i < 0 || i >= length (elems parent) = Left (InvalidArgument "union-find index out of bounds")
    | otherwise = Right (go i)
  where
    go j | parent ! j == j = j | otherwise = go (parent ! j)
union :: Int -> Int -> UnionFind -> Either MathError UnionFind
union a b uf@(UnionFind parent sizes) = do
    u <- findRoot a uf
    v <- findRoot b uf
    let (small, large) = if sizes ! u <= sizes ! v then (u, v) else (v, u)
    pure
        ( if u == v
            then uf
            else UnionFind (parent // [(small, large)]) (sizes // [(large, sizes ! large + sizes ! small)])
        )
connected :: Int -> Int -> UnionFind -> Either MathError Bool
connected a b uf = (==) <$> findRoot a uf <*> findRoot b uf
components :: UnionFind -> [[Int]]
components uf@(UnionFind parent _) =
    M.elems
        ( M.fromListWith
            (++)
            [(root, [i]) | i <- [0 .. length (elems parent) - 1], Right root <- [findRoot i uf]]
        )

-- SplitMix64 finalizer supplies reproducible noncryptographic hashes. Sketch
-- probability/error formulas assume uniform independent hashes and are not
-- adversarial guarantees for this deterministic hash family.
mix :: Word64 -> Word64
mix x =
    let a = (x `xor` shiftR x 30) * 0xbf58476d1ce4e5b9; b = (a `xor` shiftR a 27) * 0x94d049bb133111eb
     in b `xor` shiftR b 31
hashes :: Int -> Int -> Word64 -> [Int]
hashes k m x =
    [fromIntegral (mix (x + fromIntegral i * 0x9e3779b97f4a7c15) `mod` fromIntegral m) | i <- [1 .. k]]
data Bloom = Bloom Int Int Integer Integer deriving (Eq, Show)
bloom :: Int -> Int -> Either MathError Bloom
bloom m k
    | m <= 0 || m > 1048576 || k <= 0 || k > 64 = Left (InvalidArgument "invalid Bloom dimensions")
    | otherwise = Right (Bloom m k 0 0)
bloomInsert :: Word64 -> Bloom -> Bloom
bloomInsert x (Bloom m k bits count) = Bloom m k (Foldable.foldl' setBit bits (hashes k m x)) (count + 1)
bloomMember :: Word64 -> Bloom -> Bool
bloomMember x (Bloom m k bits _) = all (testBit bits) (hashes k m x)

{- | Conservative union bound @min(1,k*n/m)^k@ under independent uniform
query hashes, since at most k*n bits can be occupied. This is a bound rather
than the common exponential occupancy approximation.
-}
bloomFalsePositiveBound :: Bloom -> Double
bloomFalsePositiveBound (Bloom m k _ count) = min 1 (fromIntegral k * fromInteger count / fromIntegral m) ^ k

data CountMin = CountMin Int Int (M.Map (Int, Int) Integer) Integer deriving (Eq, Show)
countMin :: Int -> Int -> Either MathError CountMin
countMin width depth
    | width <= 0 || depth <= 0 || toInteger width * toInteger depth > 1048576 =
        Left (InvalidArgument "invalid sketch dimensions")
    | otherwise = Right (CountMin width depth M.empty 0)
countMinAdd :: Word64 -> Integer -> CountMin -> Either MathError CountMin
countMinAdd x delta (CountMin w d counts total)
    | delta < 0 = Left (InvalidArgument "count-min requires nonnegative updates")
    | otherwise =
        Right
            ( CountMin
                w
                d
                (Foldable.foldl' (\m key -> M.insertWith (+) key delta m) counts (zip [0 ..] (hashes d w x)))
                (total + delta)
            )
countMinEstimate :: Word64 -> CountMin -> Integer
countMinEstimate x (CountMin w d counts _) = minimum [M.findWithDefault 0 (i, j) counts | (i, j) <- zip [0 ..] (hashes d w x)]

-- | @(additive error, failure probability)@ under the uniform-hash model.
countMinErrorBound :: CountMin -> (Double, Double)
countMinErrorBound (CountMin w d _ total) = (exp 1 * fromInteger total / fromIntegral w, exp (-fromIntegral d))

data HyperLogLog = HyperLogLog Int (M.Map Int Int) deriving (Eq, Show)
hyperLogLog :: Int -> Either MathError HyperLogLog
hyperLogLog precision
    | precision < 4 || precision > 16 = Left (InvalidArgument "HLL precision must be in [4,16]")
    | otherwise = Right (HyperLogLog precision M.empty)
hllAdd :: Word64 -> HyperLogLog -> HyperLogLog
hllAdd x (HyperLogLog p registers) = HyperLogLog p (M.insertWith max bucket rho registers)
  where
    h = mix x
    bucket = fromIntegral (shiftR h (64 - p))
    remainder = shiftL h p
    rho = min (65 - p) (countLeadingZeros remainder + 1)

{- | HyperLogLog with linear-counting small-range correction. Typical relative
standard error is approximately @1.04/sqrt(2^p)@ under uniform hashing.
-}
hllEstimate :: HyperLogLog -> Double
hllEstimate (HyperLogLog p registers)
    | raw <= 2.5 * m && zeros > 0 = m * log (m / fromIntegral zeros)
    | otherwise = raw
  where
    count = 2 ^ p
    m = fromIntegral count
    alpha = case p of 4 -> 0.673; 5 -> 0.697; 6 -> 0.709; _ -> 0.7213 / (1 + 1.079 / m)
    zeros = count - M.size registers
    raw = alpha * m * m / (fromIntegral zeros + sum [2 ** (-fromIntegral r) | r <- M.elems registers])

data Reservoir a = Reservoir Int Integer Word64 [a] deriving (Eq, Show)
reservoir :: Int -> Word64 -> Either MathError (Reservoir a)
reservoir k seed
    | k < 0 || k > 1048576 = Left (InvalidArgument "invalid reservoir size")
    | otherwise = Right (Reservoir k 0 seed [])

{- | Algorithm R with rejection sampling (no modulo bias). The 64-bit stream
index is bounded; uniform sampling assumes the pseudorandom stream model.
-}
reservoirAdd :: a -> Reservoir a -> Either MathError (Reservoir a)
reservoirAdd x (Reservoir k count seed values)
    | count >= 2 ^ (64 :: Int) - 1 = Left (InvalidArgument "reservoir stream exceeds 64-bit counter")
    | length values < k = Right (Reservoir k (count + 1) seed (values ++ [x]))
    | k == 0 = Right (Reservoir k (count + 1) seed values)
    | otherwise =
        let (j, s) = draw (count + 1) seed
         in Right
                ( Reservoir
                    k
                    (count + 1)
                    s
                    ( if j < toInteger k
                        then take (fromInteger j) values ++ [x] ++ drop (fromInteger j + 1) values
                        else values
                    )
                )
  where
    draw bound state =
        let next = state + 0x9e3779b97f4a7c15
            r = toInteger (mix next)
            limit = 2 ^ (64 :: Int) - (2 ^ (64 :: Int) `mod` bound)
         in if r < limit then (r `mod` bound, next) else draw bound next

reservoirValues :: Reservoir a -> [a]
reservoirValues (Reservoir _ _ _ xs) = xs

{- | Exact online order statistics with an explicit memory cap. This deliberately
trades bounded-memory approximate quantiles for exact results; inserts are
O(n), queries O(1) after insertion. Exceeding the cap fails without eviction.
-}
data OnlineQuantiles = OnlineQuantiles Int [Double] deriving (Eq, Show)

onlineQuantiles :: Int -> Either MathError OnlineQuantiles
onlineQuantiles cap = do checkSize cap; pure (OnlineQuantiles cap [])
quantileAdd :: Double -> OnlineQuantiles -> Either MathError OnlineQuantiles
quantileAdd x (OnlineQuantiles cap xs)
    | isNaN x || isInfinite x = Left NonFiniteResult
    | length xs >= cap = Left (NonConvergence "online quantile memory" cap)
    | otherwise = let (a, b) = span (<= x) xs in Right (OnlineQuantiles cap (a ++ [x] ++ b))
onlineQuantile :: Double -> OnlineQuantiles -> Either MathError Double
onlineQuantile q (OnlineQuantiles _ xs)
    | null xs || isNaN q || isInfinite q || q < 0 || q > 1 =
        Left (InvalidArgument "invalid online quantile")
    | otherwise =
        let p = q * fromIntegral (length xs - 1); lo = floor p; hi = ceiling p; t = p - fromIntegral lo
         in Right ((1 - t) * (xs !! lo) + t * (xs !! hi))
