{-# LANGUAGE BangPatterns #-}

-- SPDX-License-Identifier: MPL-2.0

{- | Explicit, immutable random streams. State format @hmath-rng-1@ is decimal
'Show' syntax and is independent of host byte order. A split consumes two
words and hashes each to a new seed; it promises deterministic distinct seeds,
not disjoint mathematical subsequences. Generators are for simulation; even
ChaCha's 64-bit convenience seed is not a cryptographic key interface.

PCG32 XSH-RR: https://www.pcg-random.org/using-pcg-c-basic.html
xoshiro/xoroshiro: https://prng.di.unimi.it/
Counter algorithms: https://www.thesalmons.org/john/random123/
ChaCha20 rounds and counter layout: https://www.rfc-editor.org/rfc/rfc8439
-}
module HMath.Random (
    Generator (..),
    RNG,
    seedRNG,
    nextWord64,
    cloneRNG,
    splitRNG,
    serializeRNG,
    restoreRNG,
    uniform,
    uniformOpen,
    uniformInt,
    sampleN,
    normal,
    boxMuller,
    marsagliaNormal,
    zigguratNormal,
    exponential,
    gamma,
    beta,
    poisson,
    binomial,
    weighted,
    AliasTable,
    aliasTable,
    aliasSample,
    reservoir,
    shuffle,
    withReplacement,
    withoutReplacement,
    stratified,
    importance,
    rejection,
    inverseTransform,
    metropolisHastings,
    gibbs,
    hamiltonianMonteCarlo,
    monteCarlo,
    halton,
    sobol,
    faure,
    latinHypercube,
    randomQuality,
    entropySeed,
) where

import Data.Bits
import Data.Int (Int32)
import Data.List (transpose)
import Data.Word
import HMath.Error
import System.IO (IOMode (ReadMode), hGetChar, withBinaryFile)
import Text.Read (readMaybe)

-- | Algorithm variant. PCG32 concatenates two XSH-RR outputs, MT19937 two 32-bit outputs; counter engines pack adjacent words little endian.
data Generator
    = PCG32
    | Xoshiro256StarStar
    | Xoroshiro128Plus
    | MT19937
    | Philox4x32
    | Threefry2x64
    | ChaCha20
    deriving (Eq, Show, Read, Enum, Bounded)

-- | Opaque immutable generator state, including any buffered block outputs. Equality includes the complete continuation state.
data RNG = RNG !Generator ![Word64] ![Word64] deriving (Eq, Show)

-- Parsing uses a private raw type so Read cannot bypass the opaque invariant.
data RawRNG = RawRNG Generator [Word64] [Word64] deriving (Read, Show)

-- | Copy an immutable state; the copy produces exactly the same future outputs.
cloneRNG :: RNG -> RNG
cloneRNG = id

mix :: Word64 -> Word64
mix x =
    let a = (x `xor` (x `shiftR` 30)) * 0xbf58476d1ce4e5b9
        b = (a `xor` (a `shiftR` 27)) * 0x94d049bb133111eb
     in b `xor` (b `shiftR` 31)

-- | Deterministically encode a 64-bit seed. Shift engines use SplitMix64 expansion; MT uses the low 32 bits and its standard initialization recurrence. PCG uses a fixed odd stream increment and an offset initial state. Counter engines use the seed as key; ChaCha expands it into a 256-bit simulation key.
seedRNG :: Generator -> Word64 -> RNG
seedRNG g s = RNG g state []
  where
    seeds = map (mix . (s +) . (* 0x9e3779b97f4a7c15)) [1 ..]
    state = case g of
        PCG32 -> [s + 0x853c49e6748fea9b, 0xda3e39cb94b95bdb]
        Xoshiro256StarStar -> take 4 seeds
        Xoroshiro128Plus -> take 2 seeds
        MT19937 -> take 624 (map fromIntegral (iterateMT (fromIntegral s))) ++ [624]
        Philox4x32 -> [0, s]
        Threefry2x64 -> [0, s]
        ChaCha20 -> [0] ++ take 4 seeds
    iterateMT :: Word32 -> [Word32]
    iterateMT a = a : go 1 a
    go :: Word32 -> Word32 -> [Word32]
    go i a = let b = 1812433253 * (a `xor` (a `shiftR` 30)) + i in b : go (i + 1) b

-- | Produce one word and its successor state. Fixed-width arithmetic wraps modulo 2^32 or 2^64 as required by the algorithm.
nextWord64 :: RNG -> (Word64, RNG)
nextWord64 (RNG g s (w : ws)) = (w, RNG g s ws)
nextWord64 (RNG g s []) = case (g, s) of
    (PCG32, [x, inc]) ->
        let (a, y) = pcg x inc; (b, z) = pcg y inc
         in (fromIntegral a `shiftL` 32 .|. fromIntegral b, RNG g [z, inc] [])
    (Xoshiro256StarStar, [a, b, c, d]) ->
        let t = b `shiftL` 17
            c1 = c `xor` a
            d1 = d `xor` b
            b1 = b `xor` c1
            a1 = a `xor` d1
            c2 = c1 `xor` t
            d2 = rotateL d1 45
         in (rotateL (b * 5) 7 * 9, RNG g [a1, b1, c2, d2] [])
    (Xoroshiro128Plus, [a, b]) ->
        let t = b `xor` a in (a + b, RNG g [rotateL a 24 `xor` t `xor` (t `shiftL` 16), rotateL t 37] [])
    (MT19937, _) ->
        let (a, s1) = mtNext s; (b, s2) = mtNext s1
         in (fromIntegral a `shiftL` 32 .|. fromIntegral b, RNG g s2 [])
    (Philox4x32, [c, k]) -> let ws = philox c k in nextWord64 (RNG g [c + 1, k] (pack ws))
    (Threefry2x64, [c, k]) -> let (a, b) = threefry c k in (a, RNG g [c + 1, k] [b])
    (ChaCha20, c : ks) -> nextWord64 (RNG g ((c + 1) : ks) (pack (chacha c ks)))
    _ -> nextWord64 (seedRNG g 0) -- unreachable through the opaque, validated interface
  where
    pcg :: Word64 -> Word64 -> (Word32, Word64)
    pcg x inc =
        ( rotateR (fromIntegral (((x `shiftR` 18) `xor` x) `shiftR` 27)) (fromIntegral (x `shiftR` 59))
        , x * 6364136223846793005 + (inc .|. 1)
        )
    pack [] = []
    pack (a : b : xs) = (fromIntegral a .|. fromIntegral b `shiftL` 32) : pack xs
    pack _ = []

mtNext :: [Word64] -> (Word32, [Word64])
mtNext s = (temper (fromIntegral (xs !! i)), take 624 xs ++ [fromIntegral (i + 1)])
  where
    i0 = fromIntegral (last s) :: Int
    old = map fromIntegral (take 624 s) :: [Word32]
    twist = foldl' upd old [0 .. 623]
    upd a j =
        let y = (a !! j .&. 0x80000000) .|. (a !! ((j + 1) `mod` 624) .&. 0x7fffffff)
            v = a !! ((j + 397) `mod` 624) `xor` (y `shiftR` 1) `xor` (if odd y then 0x9908b0df else 0)
         in take j a ++ [v] ++ drop (j + 1) a
    xs = if i0 >= 624 then map fromIntegral twist else take 624 s
    i = if i0 >= 624 then 0 else i0
    temper x =
        let a = x `xor` (x `shiftR` 11)
            b = a `xor` ((a `shiftL` 7) .&. 0x9d2c5680)
            c = b `xor` ((b `shiftL` 15) .&. 0xefc60000)
         in c `xor` (c `shiftR` 18)
philox :: Word64 -> Word64 -> [Word32]
philox c k =
    go
        10
        [fromIntegral c, fromIntegral (c `shiftR` 32), 0, 0]
        (fromIntegral k)
        (fromIntegral (k `shiftR` 32))
  where
    go :: Int -> [Word32] -> Word32 -> Word32 -> [Word32]
    go 0 x _ _ = x
    go n [a, b, d, e] p q =
        let x = fromIntegral a * 0xd2511f53 :: Word64; y = fromIntegral d * 0xcd9e8d57 :: Word64
         in go
                (n - 1)
                [ fromIntegral (y `shiftR` 32) `xor` b `xor` p
                , fromIntegral y
                , fromIntegral (x `shiftR` 32) `xor` e `xor` q
                , fromIntegral x
                ]
                (p + 0x9e3779b9)
                (q + 0xbb67ae85)
    go _ x _ _ = x
threefry :: Word64 -> Word64 -> (Word64, Word64)
threefry c k = go 0 (c + k) 0
  where
    keys = [k, 0, 0x1bd11bdaa9fc1a22 `xor` k]
    rots = [16, 42, 12, 31, 16, 32, 24, 21]
    go :: Int -> Word64 -> Word64 -> (Word64, Word64)
    go 20 a b = (a, b)
    go n a b =
        let x = a + b
            y = rotateL b (rots !! (n `mod` 8)) `xor` x
            t = (n + 1) `div` 4
            (p, q) =
                if (n + 1) `mod` 4 == 0
                    then (x + keys !! (t `mod` 3), y + keys !! ((t + 1) `mod` 3) + fromIntegral t)
                    else (x, y)
         in go (n + 1) p q
chacha :: Word64 -> [Word64] -> [Word32]
chacha c ks = zipWith (+) initial (iterate double initial !! 10)
  where
    initial =
        [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574]
            ++ concatMap (\k -> [fromIntegral k, fromIntegral (k `shiftR` 32)]) ks
            ++ [fromIntegral c, fromIntegral (c `shiftR` 32), 0, 0]
    set j v xs = take j xs ++ [v] ++ drop (j + 1) xs
    quarter xs (a, b, d, e) =
        let a1 = xs !! a + xs !! b
            e1 = rotateL (xs !! e `xor` a1) 16
            d1 = xs !! d + e1
            b1 = rotateL (xs !! b `xor` d1) 12
            a2 = a1 + b1
            e2 = rotateL (e1 `xor` a2) 8
            d2 = d1 + e2
            b2 = rotateL (b1 `xor` d2) 7
         in set e e2 (set d d2 (set b b2 (set a a2 xs)))
    double xs =
        foldl'
            quarter
            xs
            [ (0, 4, 8, 12)
            , (1, 5, 9, 13)
            , (2, 6, 10, 14)
            , (3, 7, 11, 15)
            , (0, 5, 10, 15)
            , (1, 6, 11, 12)
            , (2, 7, 8, 13)
            , (3, 4, 9, 14)
            ]

-- | Create two deterministic child streams by hashing two successive parent words. The original immutable parent is unchanged; see the module-level non-overlap caveat.
splitRNG :: RNG -> (RNG, RNG)
splitRNG r@(RNG g _ _) =
    let (a, r1) = nextWord64 r; (b, _) = nextWord64 r1 in (seedRNG g (mix a), seedRNG g (mix (b + 1)))

-- | Serialize full state, including pending block output, with the versioned hmath-rng-1 prefix.
serializeRNG :: RNG -> String
serializeRNG (RNG g state buffered) = "hmath-rng-1 " ++ show (RawRNG g state buffered)

-- | Parse a versioned full state and validate generator lengths, forbidden zero states, and MT word/index ranges.
restoreRNG :: String -> Either MathError RNG
restoreRNG text = case splitAt 12 text of
    ("hmath-rng-1 ", rest) -> case readMaybe rest of
        Just (RawRNG g s ws) | valid g s && length ws <= 8 -> Right (RNG g s ws)
        _ -> Left (InvalidArgument "invalid RNG state")
    _ -> Left (InvalidArgument "unsupported RNG state version")
  where
    valid PCG32 s = length s == 2 && odd (last s)
    valid Xoshiro256StarStar s = length s == 4 && any (/= 0) s
    valid Xoroshiro128Plus s = length s == 2 && any (/= 0) s
    valid MT19937 s = length s == 625 && last s <= 624 && all (<= 0xffffffff) (take 624 s)
    valid Philox4x32 s = length s == 2
    valid Threefry2x64 s = length s == 2
    valid ChaCha20 s = length s == 5

-- | Uniform 53-bit real on [0,1), using the most significant random bits.
uniform :: RNG -> (Double, RNG)
uniform r = let (w, s) = nextWord64 r in (fromIntegral (w `shiftR` 11) / 9007199254740992, s)

-- | Uniform 52-bit midpoint real on (0,1), safe as input to logarithms.
uniformOpen :: RNG -> (Double, RNG)
uniformOpen r = let (w, s) = nextWord64 r in ((fromIntegral (w `shiftR` 12) + 0.5) / 4503599627370496, s)

-- | Unbiased inclusive integer range using 64-bit rejection. Supports the complete machine Int range; rejects reversed bounds.
uniformInt :: Int -> Int -> RNG -> Either MathError (Int, RNG)
uniformInt lo hi r
    | lo > hi = Left (DomainError "uniformInt: lower > upper")
    | otherwise = go 10000 r
  where
    width = toInteger hi - toInteger lo + 1
    bound = (2 ^ (64 :: Int) :: Integer) - ((2 ^ (64 :: Int)) `mod` width)
    go :: Int -> RNG -> Either MathError (Int, RNG)
    go 0 _ = Left (NonConvergence "uniform integer rejection" 10000)
    go n s =
        let (x, t) = nextWord64 s
         in if toInteger x < bound
                then Right (fromInteger (toInteger lo + toInteger x `mod` width), t)
                else go (n - 1) t

-- | Run a checked sampler sequentially, returning values and final state. Count must lie in [0,10000000].
sampleN :: Int -> (RNG -> Either MathError (a, RNG)) -> RNG -> Either MathError ([a], RNG)
sampleN n f r
    | n < 0 || n > 10000000 = Left (InvalidArgument "sample count outside [0,10000000]")
    | otherwise = go n r []
  where
    go 0 s a = Right (reverse a, s); go k s a = do (x, t) <- f s; go (k - 1) t (x : a)

finite :: Double -> Bool
finite x = not (isNaN x || isInfinite x)
positive :: Double -> Bool
positive x = finite x && x > 0

-- | Standard normal through the polar-coordinate Box--Muller transform, consuming two uniforms.
boxMuller :: RNG -> (Double, RNG)
boxMuller r = let (u, s) = uniformOpen r; (v, t) = uniform s in (sqrt (-2 * log u) * cos (2 * pi * v), t)

-- | Standard normal through Marsaglia polar disk rejection, with 10000-proposal budget.
marsagliaNormal :: RNG -> Either MathError (Double, RNG)

-- | Standard normal through Marsaglia polar disk rejection, with 10000-proposal budget.
marsagliaNormal = go (10000 :: Int)
  where
    go 0 _ = Left (NonConvergence "Marsaglia polar" 10000)
    go n r =
        let (u, s) = uniform r; (v, t) = uniform s; x = 2 * u - 1; y = 2 * v - 1; q = x * x + y * y
         in if q > 0 && q < 1 then Right (x * sqrt (-2 * log q / q), t) else go (n - 1) t

{- | Marsaglia--Tsang 128-layer Ziggurat normal generator. Horizontal
rectangles have equal area; the base includes an exponentially proposed tail.
Published normal cutoff/area constants: https://doi.org/10.18637/jss.v005.i08
Tables are generated by the area recurrence, not embedded implementation data.
-}
zigguratNormal :: RNG -> Either MathError (Double, RNG)
zigguratNormal = draw (100000 :: Int)
  where
    cutoff = 3.442619855899 :: Double
    area = 0.00991256303526217 :: Double
    scale = 2147483648 :: Double
    topDensity = exp (-cutoff * cutoff / 2)
    width0 = area / topDensity
    -- Descending widths x_127,...,x_1; x_0 is the full base width.
    descending = take 127 (iterate (\x -> sqrt (-2 * log (area / x + exp (-x * x / 2)))) cutoff)
    widths = width0 : reverse descending
    heights = 1 : map (\x -> exp (-x * x / 2)) (drop 1 widths)
    thresholds =
        floor (cutoff / width0 * scale)
            : 0
            : [floor (widths !! (i - 1) / widths !! i * scale) | i <- [2 .. 127]] ::
            [Integer]
    draw 0 _ = Left (NonConvergence "Ziggurat normal" 100000)
    draw budget state =
        let (word, next) = nextWord64 state
            signed = fromIntegral (fromIntegral word :: Int32) :: Integer
            layer = fromIntegral (word .&. 127)
            x = fromInteger signed * widths !! layer / scale
         in if abs signed < thresholds !! layer
                then Right (x, next)
                else
                    if layer == 0
                        then tailDraw (budget - 1) (signed < 0) next
                        else
                            let (u, lastState) = uniform next
                                ordinate = heights !! layer + u * (heights !! (layer - 1) - heights !! layer)
                             in if ordinate < exp (-x * x / 2) then Right (x, lastState) else draw (budget - 1) lastState
    tailDraw 0 _ _ = Left (NonConvergence "Ziggurat exponential tail" 100000)
    tailDraw budget negative state =
        let (u, next) = uniformOpen state
            (v, lastState) = uniformOpen next
            x = -log u / cutoff
            y = -log v
         in if 2 * y >= x * x
                then Right ((if negative then -1 else 1) * (cutoff + x), lastState)
                else tailDraw (budget - 1) negative lastState

-- | Normal sample with finite mean and strictly positive standard deviation. Arithmetic overflow returns NonFiniteResult.
normal :: Double -> Double -> RNG -> Either MathError (Double, RNG)
normal mu sd r
    | not (finite mu && positive sd) = Left (DomainError "normal: finite mean and positive sd required")
    | otherwise =
        let (z, s) = boxMuller r; x = mu + sd * z in if finite x then Right (x, s) else Left NonFiniteResult

-- | Exponential sample parameterized by strictly positive rate, via an open-uniform logarithm.
exponential :: Double -> RNG -> Either MathError (Double, RNG)
exponential rate r
    | not (positive rate) = Left (DomainError "exponential: positive rate required")
    | otherwise =
        let (u, s) = uniformOpen r; x = -log u / rate
         in if finite x then Right (x, s) else Left NonFiniteResult

-- | Gamma shape/scale sample using Marsaglia--Tsang rejection and the shape-augmentation identity below shape one; 10000-proposal budget.
gamma :: Double -> Double -> RNG -> Either MathError (Double, RNG)
gamma shape scale r
    | not (positive shape && positive scale) =
        Left (DomainError "gamma: positive shape and scale required")
    | shape < 1 = do
        (x, s) <- gamma (shape + 1) scale r
        let (u, t) = uniformOpen s
        pure (x * u ** (1 / shape), t)
    | otherwise = go (10000 :: Int) r
  where
    d = shape - 1 / 3
    c = 1 / sqrt (9 * d)
    go 0 _ = Left (NonConvergence "Marsaglia-Tsang gamma" 10000)
    go n s =
        let (z, t) = boxMuller s; v = (1 + c * z) ^ (3 :: Int); (u, w) = uniformOpen t
         in if v > 0 && (u < 1 - 0.0331 * z ^ (4 :: Int) || log u < 0.5 * z * z + d * (1 - v + log v))
                then if finite (scale * d * v) then Right (scale * d * v, w) else Left NonFiniteResult
                else go (n - 1) w

-- | Beta(a,b) as the ratio of independent gamma variates. Positive parameters required; unresolved underflow returns an error.
beta :: Double -> Double -> RNG -> Either MathError (Double, RNG)
beta a b r = do
    (x, s) <- gamma a 1 r
    (y, t) <- gamma b 1 s
    let v = if x > y then 1 / (1 + y / x) else let ratio = x / y in ratio / (1 + ratio)
    if finite v then pure (v, t) else Left NonFiniteResult

-- | Poisson count by exponential-arrival inversion. Rate is in [0,100000], work is capped at one million arrivals.
poisson :: Double -> RNG -> Either MathError (Int, RNG)
poisson lambda r
    | not (finite lambda) || lambda < 0 || lambda > 100000 =
        Left (DomainError "Poisson rate must be in [0,100000]")
    | lambda == 0 = Right (0, r)
    | otherwise = go 0 0 r
  where
    go !n !t s
        | n >= 1000000 = Left (NonConvergence "Poisson arrivals" 1000000)
        | otherwise =
            let (u, z) = uniformOpen s; q = t - log u in if q > lambda then Right (n, z) else go (n + 1) q z

-- | Binomial count from n independent Bernoulli trials. n<=10000000 and p in [0,1].
binomial :: Int -> Double -> RNG -> Either MathError (Int, RNG)
binomial n p r
    | n < 0 || n > 10000000 || not (finite p) || p < 0 || p > 1 =
        Left (DomainError "binomial: invalid n or probability")
    | otherwise = do (xs, s) <- sampleN n (Right . uniform) r; pure (length (filter (< p) xs), s)

-- | Draw an index in proportion to finite nonnegative weights; max scaling handles subnormal or overflowing totals and zero weights are never selected.
weighted :: [Double] -> RNG -> Either MathError (Int, RNG)
weighted ws r
    | null ws || any (\x -> not (finite x) || x < 0) ws || largest <= 0 =
        Left (DomainError "weights must be finite, nonnegative with positive maximum")
    | otherwise = let (u, s) = uniform r; target = u * total in Right (select target 0 normalized, s)
  where
    largest = maximum (0 : ws)
    normalized = map (/ largest) ws
    total = sum normalized
    -- The final positive entry is a safe rounding fallback. Zero entries are
    -- skipped even when a subnormal original total could have rounded u*sum up.
    select target i (w : rest)
        | w <= 0 = select target (i + 1) rest
        | target < w = i
        | any (> 0) rest = select (target - w) (i + 1) rest
        | otherwise = i
    select _ i [] = max 0 (i - 1)

-- | Opaque Walker alias table with normalized acceptance thresholds and alternative indices.
data AliasTable = AliasTable [Double] [Int] deriving (Eq, Show)

-- | Build a Walker alias table from finite nonnegative weights with positive maximum; max scaling avoids overflow.
aliasTable :: [Double] -> Either MathError AliasTable
aliasTable ws = do
    _ <- weighted ws (seedRNG PCG32 0)
    let n = length ws
        largest = maximum ws
        scaled = map (/ largest) ws
        total = sum scaled
        ps = map (\x -> (x / total) * fromIntegral n) scaled
        small = [i | (i, p) <- zip [0 ..] ps, p < 1]
        large = [i | (i, p) <- zip [0 ..] ps, p >= 1]
    pure (build ps [0 .. n - 1] small large)
  where
    set i v xs = take i xs ++ [v] ++ drop (i + 1) xs
    build ps as (s : ss) (l : ls) =
        let q = ps !! l + ps !! s - 1; np = set l q ps; na = set s l as
         in if q < 1 then build np na (l : ss) ls else build np na ss (l : ls)
    build ps as ss ls = AliasTable (foldl' (\a i -> set i 1 a) ps (ss ++ ls)) as

-- | Draw an index from an already validated alias table, using one uniform integer and one uniform real.
aliasSample :: AliasTable -> RNG -> Either MathError (Int, RNG)
aliasSample (AliasTable ps as) r = do
    (i, s) <- uniformInt 0 (length ps - 1) r
    let (u, t) = uniform s
    pure (if u < ps !! i then i else as !! i, t)

-- | Fisher--Yates permutation of list positions. This immutable list reference implementation costs quadratic time.
shuffle :: [a] -> RNG -> Either MathError ([a], RNG)
shuffle xs r = go (length xs - 1) xs r
  where
    set i v ys = take i ys ++ [v] ++ drop (i + 1) ys
    go i ys s
        | i <= 0 = Right (ys, s)
        | otherwise = do (j, t) <- uniformInt 0 i s; go (i - 1) (set j (ys !! i) (set i (ys !! j) ys)) t

-- | Draw count values independently from a nonempty finite population, preserving duplicates.
withReplacement :: Int -> [a] -> RNG -> Either MathError ([a], RNG)
withReplacement n xs r
    | null xs && n > 0 = Left (DomainError "empty sampling population")
    | otherwise = sampleN n (\s -> do (i, t) <- uniformInt 0 (length xs - 1) s; pure (xs !! i, t)) r

-- | Uniform subset in shuffled order. Count cannot exceed population length; uniqueness is by position.
withoutReplacement :: Int -> [a] -> RNG -> Either MathError ([a], RNG)
withoutReplacement n xs r
    | n < 0 || n > length xs = Left (DomainError "sample size exceeds population")
    | otherwise = do (ys, s) <- shuffle xs r; pure (take n ys, s)

-- | Algorithm R reservoir over a finite stream, retaining k positions uniformly without replacement.
reservoir :: Int -> [a] -> RNG -> Either MathError ([a], RNG)
reservoir k xs r
    | k < 0 || k > length xs = Left (DomainError "reservoir size outside population")
    | otherwise = go k (take k xs) (drop k xs) r
  where
    go _ a [] s = Right (a, s)
    go i a (y : ys) s = do
        (j, t) <- uniformInt 0 i s; go (i + 1) (if j < k then take j a ++ [y] ++ drop (j + 1) a else a) ys t

-- | One uniform point per equal-width interval of [0,1), in increasing stratum order.
stratified :: Int -> RNG -> Either MathError ([Double], RNG)
stratified n r
    | n <= 0 = Left (DomainError "positive stratum count required")
    | otherwise = do
        (us, s) <- sampleN n (Right . uniform) r
        pure (zipWith (\i u -> (fromIntegral i + u) / fromIntegral n) [0 :: Int ..] us, s)

-- | Self-normalized importance estimate from values and nonnegative finite importance weights. This is a biased finite-sample estimator.
importance :: [Double] -> [Double] -> Either MathError Double
importance values weights
    | null values
        || length values /= length weights
        || any (not . finite) values
        || any (\w -> not (finite w) || w < 0) weights
        || not (positive (sum weights)) =
        Left (DomainError "importance: invalid weights or observations")
    | otherwise = Right (sum (zipWith (*) values weights) / sum weights)

-- | Accept proposals with the supplied target/envelope probability in [0,1]; the first argument is a hard proposal budget.
rejection ::
    Int ->
    (Double -> Double) ->
    (RNG -> Either MathError (Double, RNG)) ->
    RNG ->
    Either MathError (Double, RNG)
rejection budget ratio proposal = go budget
  where
    go n s
        | n <= 0 = Left (NonConvergence "rejection sampling" budget)
        | otherwise = do
            (x, t) <- proposal s
            let (u, z) = uniform t; q = ratio x
            if not (finite q) || q < 0 || q > 1
                then Left (DomainError "rejection ratio outside [0,1]")
                else if u < q then Right (x, z) else go (n - 1) z

-- | Apply a checked inverse CDF to an open uniform; propagates inverse-domain or nonconvergence errors.
inverseTransform :: (Double -> Either MathError Double) -> RNG -> Either MathError (Double, RNG)
inverseTransform inv r = let (u, s) = uniformOpen r in do x <- inv u; pure (x, s)

{- | Symmetric random-walk Metropolis in log density. Returned chain includes
each post-proposal state. Non-finite log densities are rejected.
-}
metropolisHastings ::
    Int -> Double -> (Double -> Double) -> Double -> RNG -> Either MathError ([Double], RNG)
metropolisHastings n step logp initial r
    | n < 0 || not (positive step) || not (finite initial && finite (logp initial)) =
        Left (DomainError "Metropolis: invalid initial state or step")
    | otherwise = go n initial r []
  where
    go 0 _ s a = Right (reverse a, s)
    go k x s a = do
        (y, t) <- normal x step s
        let (u, z) = uniformOpen t; lp = logp y; q = if finite lp && log u < lp - logp x then y else x
        go (k - 1) q z (q : a)

{- | A full Gibbs sweep uses caller-supplied exact conditional samplers in
coordinate order. Shape is checked after each conditional.
-}
gibbs ::
    Int ->
    [([Double] -> RNG -> Either MathError (Double, RNG))] ->
    [Double] ->
    RNG ->
    Either MathError ([[Double]], RNG)
gibbs n fs initial r
    | n < 0 || length fs /= length initial || any (not . finite) initial =
        Left (DomainError "Gibbs: invalid shape")
    | otherwise = go n initial r []
  where
    sweep x s =
        foldl'
            ( \acc (i, f) -> do
                (y, t) <- acc
                (v, z) <- f y t
                if finite v then Right (take i y ++ [v] ++ drop (i + 1) y, z) else Left NonFiniteResult
            )
            (Right (x, s))
            (zip [0 ..] fs)
    go 0 _ s a = Right (reverse a, s)
    go k x s a = do (y, t) <- sweep x s; go (k - 1) y t (y : a)

-- | Identity-mass HMC with Gaussian momentum, leapfrog count and positive step size, log density and its gradient. Returns post-Metropolis states; finite-gradient shapes are checked.
hamiltonianMonteCarlo ::
    Int ->
    Int ->
    Double ->
    ([Double] -> Double) ->
    ([Double] -> [Double]) ->
    [Double] ->
    RNG ->
    Either MathError ([[Double]], RNG)
hamiltonianMonteCarlo n leaps eps logp grad initial r
    | n < 0
        || leaps <= 0
        || not (positive eps)
        || null initial
        || any (not . finite) initial
        || not (finite (logp initial)) =
        Left (DomainError "HMC: invalid configuration")
    | otherwise = go n initial r []
  where
    add a b = zipWith (+) a b
    scale a = map (a *)
    force q =
        let g = grad q
         in if length g /= length q || any (not . finite) g
                then Left (DomainError "HMC gradient shape or value")
                else Right g
    integrate 0 q p = Right (q, p)
    integrate k q p = do
        g <- force q
        let ph = add p (scale (eps / 2) g); qn = add q (scale eps ph)
        gn <- force qn
        integrate (k - 1) qn (add ph (scale (eps / 2) gn))
    go 0 _ s a = Right (reverse a, s)
    go k q s a = do
        (p, t) <- sampleN (length q) (normal 0 1) s
        (qn, pn) <- integrate leaps q p
        let (u, z) = uniformOpen t
            ratio = logp qn - logp q + (sum (map (\x -> x * x) p) - sum (map (\x -> x * x) pn)) / 2
            chosen = if finite ratio && log u < ratio then qn else q
        go (k - 1) chosen z (chosen : a)

-- | Uniform-[0,1] Monte Carlo integral and estimated standard error from at least two draws. This is a stochastic estimate, not a certified bound.
monteCarlo :: (Double -> Double) -> Int -> RNG -> Either MathError ((Double, Double), RNG)
monteCarlo f n r
    | n < 2 = Left (DomainError "Monte Carlo needs at least 2 observations")
    | otherwise = do
        (us, s) <- sampleN n (Right . uniform) r
        let xs = map f us
            m = sum xs / fromIntegral n
            se = sqrt (sum (map (\x -> (x - m) ^ (2 :: Int)) xs) / fromIntegral (n * (n - 1)))
        if all finite xs then Right ((m, se), s) else Left NonFiniteResult

-- | Unshifted Halton point, dimensions 1..16 and zero-based nonnegative point index; index zero is the origin.
halton :: Int -> Int -> Either MathError [Double]
halton dimension index
    | dimension < 1 || dimension > 16 || index < 0 =
        Left (DomainError "Halton: dimension 1..16 and nonnegative index required")
    | otherwise =
        Right
            [ min (1 - 2 ** (-53)) (radical b index)
            | b <- take dimension [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53]
            ]
  where
    radical b = go (1 / fromIntegral b) 0
      where
        go _ a 0 = a; go w a k = go (w / fromIntegral b) (a + w * fromIntegral (k `mod` b)) (k `div` b)

{- | Sobol digital net in dimensions 1..8, 32 direction bits. Joe--Kuo's first
primitive polynomials and initial direction numbers; index zero is the origin.
-}
sobol :: Int -> Int -> Either MathError [Double]
sobol dimension index
    | dimension < 1 || dimension > 8 || index < 0 || toInteger index >= 2 ^ (32 :: Int) =
        Left (DomainError "Sobol: dimension 1..8, 32-bit index required")
    | otherwise = Right [coordinate d | d <- [0 .. dimension - 1]]
  where
    specs :: [(Int, Int, [Int])]
    specs =
        [ (1, 0, [1])
        , (2, 1, [1, 3])
        , (3, 1, [1, 3, 1])
        , (3, 2, [1, 1, 1])
        , (4, 1, [1, 1, 3, 3])
        , (4, 4, [1, 3, 5, 13])
        , (5, 2, [1, 1, 5, 5, 17])
        ]
    dirs :: Int -> [Word32]
    dirs 0 = [bit (31 - j) | j <- [0 .. 31]]
    dirs d =
        let (s, a, ms) = specs !! (d - 1)
            start = zipWith shiftL (map fromIntegral ms) [31, 30 ..]
            go vs j
                | j >= 32 = vs
                | otherwise =
                    let v = vs !! (j - s) `xor` (vs !! (j - s) `shiftR` s)
                        w =
                            foldl' (\x k -> if testBit (a :: Int) (s - 1 - k) then x `xor` vs !! (j - k) else x) v [1 .. s - 1]
                     in go (vs ++ [w]) (j + 1)
         in go start s
    gray = index `xor` (index `shiftR` 1)
    coordinate d = fromIntegral (foldl' xor 0 [v | (j, v) <- zip [0 ..] (dirs d), testBit gray j]) / 4294967296

-- | Faure's Pascal digital transform in the least prime base >= dimension.
faure :: Int -> Int -> Either MathError [Double]
faure d ix
    | d < 1 || d > 16 || ix < 0 =
        Left (DomainError "Faure dimension 1..16 and nonnegative index required")
    | otherwise = Right (take d (map value (iterate transform digits)))
  where
    b = choosePrime (max 2 d)
    choosePrime p =
        if all (\q -> p `mod` q /= 0) [2 .. floor (sqrt (fromIntegral p :: Double))]
            then p
            else choosePrime (p + 1)
    digits = if ix == 0 then [0] else digs ix
    digs 0 = []; digs n = n `mod` b : digs (n `div` b)
    choose n k =
        fromInteger
            ( (product [fromIntegral (n - k + 1) .. fromIntegral n] `div` product [1 .. fromIntegral k])
                `mod` toInteger b
            )
    transform xs = [sum [choose j i * (xs !! j) | j <- [i .. length xs - 1]] `mod` b | i <- [0 .. length xs - 1]]
    value xs =
        min
            (1 - 2 ** (-53))
            (sum [fromIntegral x / fromIntegral b ** fromIntegral (j + 1) | (j, x) <- zip [0 :: Int ..] xs])

-- | Random n-by-d Latin hypercube in [0,1), with a separate Fisher--Yates stratum permutation per axis; n>0 and 1<=d<=1024.
latinHypercube :: Int -> Int -> RNG -> Either MathError ([[Double]], RNG)
latinHypercube n d r
    | n <= 0 || d <= 0 || d > 1024 = Left (DomainError "Latin hypercube: invalid shape")
    | otherwise = do
        (cols, s) <- sampleN d (\t -> do (xs, u) <- stratified n t; shuffle xs u) r
        pure (transpose cols, s)

{- | Mean, population variance, and lag-one correlation; descriptive quality
diagnostics, not a cryptographic certification or a replacement for TestU01.
-}
randomQuality :: Int -> RNG -> Either MathError ((Double, Double, Double), RNG)
randomQuality n r
    | n < 3 = Left (DomainError "quality sample count >=3 required")
    | otherwise = do
        (xs, s) <- sampleN n (Right . uniform) r
        let m = sum xs / fromIntegral n
            v = sum (map (\x -> (x - m) ^ (2 :: Int)) xs) / fromIntegral n
            c = sum (zipWith (\x y -> (x - m) * (y - m)) xs (drop 1 xs)) / fromIntegral (n - 1) / v
        pure ((m, v, c), s)

{- | Read eight bytes from the operating system entropy device, little endian.
IO exceptions are propagated; this deliberately has no time-based fallback.
-}
entropySeed :: IO Word64
entropySeed =
    withBinaryFile
        "/dev/urandom"
        ReadMode
        ( \h -> do
            cs <- mapM (\_ -> hGetChar h) [0 .. 7 :: Int]
            pure (foldl' (\a (i, c) -> a .|. fromIntegral (fromEnum c) `shiftL` (8 * i)) 0 (zip [0 ..] cs))
        )
