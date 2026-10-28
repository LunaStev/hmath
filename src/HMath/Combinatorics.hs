-- SPDX-License-Identifier: MPL-2.0

{- | Exact combinatorics. Indices and ranks are zero based; enumerations use
lexicographic order. Counts use unbounded 'Integer'. Enumeration APIs take a
maximum output count and reject the request before constructing that output.
Scalar recurrences accept orders through 4096 (quadratic tables through 512).
-}
module HMath.Combinatorics (
    permutationsCount,
    combinationsCount,
    multinomial,
    permutationsOf,
    combinationsOf,
    rankPermutation,
    unrankPermutation,
    rankCombination,
    unrankCombination,
    derangementCount,
    derangements,
    integerPartitions,
    setPartitions,
    stirlingFirst,
    stirlingSecond,
    bellNumber,
    eulerianNumber,
    lahNumber,
    catalanNumber,
    fibonacci,
    lucas,
    pascalTriangle,
    inclusionExclusion,
    subsets,
    cartesianProduct,
    multisetPermutations,
    multisetCount,
    linearRecurrence,
    generatingCoefficients,
    convolveSeries,
    finiteDifferences,
    finiteSum,
) where

import Data.List (delete, group, sort)
import HMath.Error (MathError (..))

order :: Int -> Either MathError ()
order n
    | n < 0 || n > 4096 = Left (InvalidArgument "combinatorial order must be in [0,4096]")
    | otherwise = Right ()

budget :: Int -> Integer -> Either MathError ()
budget b n
    | b < 0 = Left (InvalidArgument "negative output budget")
    | n > toInteger b = Left (NonConvergence "combinatorial output budget" b)
    | otherwise = Right ()

fact :: Int -> Integer
fact n = product [1 .. toInteger n]

choose :: Int -> Int -> Integer
choose n k
    | k < 0 || k > n = 0
    | otherwise = product [toInteger (n - r + 1) .. toInteger n] `div` fact r
  where
    r = min k (n - k)

permutationsCount :: Int -> Int -> Either MathError Integer
permutationsCount n k = do
    order n
    order k
    pure (if k > n then 0 else fact n `div` fact (n - k))

combinationsCount :: Int -> Int -> Either MathError Integer
combinationsCount n k = do order n; order k; pure (choose n k)

multinomial :: [Int] -> Either MathError Integer
multinomial ks = do
    mapM_ order ks
    let n = sum (map toInteger ks)
    if n > 4096
        then Left (InvalidArgument "multinomial total exceeds 4096")
        else pure (fact (fromInteger n) `div` product (map fact ks))

-- | Distinct positions, including when values compare equal.
permutationsOf :: Int -> Int -> [a] -> Either MathError [[a]]
permutationsOf b k xs = do
    n <- permutationsCount (length xs) k
    budget b n
    pure (perm k xs)
  where
    perm 0 _ = [[]]
    perm j ys = [v : zs | (i, v) <- zip [0 :: Int ..] ys, zs <- perm (j - 1) (take i ys ++ drop (i + 1) ys)]

combinationsOf :: Int -> Int -> [a] -> Either MathError [[a]]
combinationsOf b k xs = do
    n <- combinationsCount (length xs) k; budget b n; pure (comb k xs)
  where
    comb 0 _ = [[]]
    comb _ [] = []
    comb j (v : vs) = map (v :) (comb (j - 1) vs) ++ comb j vs

-- | A permutation of @[0,n)@, in lexicographic Lehmer order.
rankPermutation :: [Int] -> Either MathError Integer
rankPermutation p = do
    order (length p)
    if sort p /= [0 .. length p - 1]
        then Left (InvalidArgument "not a permutation")
        else pure (go p [0 .. length p - 1])
  where
    go [] _ = 0
    go (x : xs) ys = toInteger (length (takeWhile (< x) ys)) * fact (length xs) + go xs (delete x ys)

unrankPermutation :: Int -> Integer -> Either MathError [Int]
unrankPermutation n r = do
    order n
    if r < 0 || r >= fact n
        then Left (InvalidArgument "permutation rank out of bounds")
        else pure (go r [0 .. n - 1])
  where
    go _ [] = []
    go q xs =
        let (i, t) = q `divMod` fact (length xs - 1); v = xs !! fromInteger i
         in v : go t (delete v xs)

rankCombination :: Int -> [Int] -> Either MathError Integer
rankCombination n xs = do
    order n
    if xs /= sort xs || length xs /= length (group xs) || any (\x -> x < 0 || x >= n) xs
        then Left (InvalidArgument "combination must contain increasing indices")
        else pure (go 0 xs)
  where
    go _ [] = 0
    go lo (x : rest) = sum [choose (n - v - 1) (length rest) | v <- [lo .. x - 1]] + go (x + 1) rest

unrankCombination :: Int -> Int -> Integer -> Either MathError [Int]
unrankCombination n k r = do
    order n
    order k
    if r < 0 || r >= choose n k
        then Left (InvalidArgument "combination rank out of bounds")
        else pure (go 0 k r)
  where
    go _ 0 _ = []
    go lo j q = find lo q
      where
        find x t
            | t < count = x : go (x + 1) (j - 1) t
            | otherwise = find (x + 1) (t - count)
          where
            count = choose (n - x - 1) (j - 1)

derangementCount :: Int -> Either MathError Integer
derangementCount n = do
    order n
    pure (fst (foldl (\(a, b) k -> (b, toInteger (k - 1) * (a + b))) (1, 0) [2 .. n + 1]))

{- | Enumeration uses the factorial upper bound, so a request may be rejected
even if its filtered derangement output would fit.
-}
derangements :: Int -> Int -> Either MathError [[Int]]
derangements b n = do
    ps <- permutationsOf b n [0 .. n - 1]
    pure (filter (and . zipWith (/=) [0 ..]) ps)

{- | Nonincreasing positive parts. The budget counts search nodes as well as
outputs, preventing long searches with a tiny output limit.
-}
integerPartitions :: Int -> Int -> Either MathError [[Int]]
integerPartitions b n = do
    order n
    if b < 0
        then Left (InvalidArgument "negative partition budget")
        else fst <$> go b n n
  where
    go fuel k hi
        | fuel <= 0 = Left (NonConvergence "integer partitions" b)
        | k == 0 = Right ([[]], fuel - 1)
        | otherwise = foldl step (Right ([], fuel - 1)) [min k hi, min k hi - 1 .. 1]
      where
        step prev x = do
            (out, f) <- prev
            (ys, f') <- go f (k - x) x
            pure (out ++ map (x :) ys, f')

-- | Set partitions of @[0,n)@, using restricted-growth order of block labels.
setPartitions :: Int -> Int -> Either MathError [[[Int]]]
setPartitions b n = do
    order n
    count <- bellNumber n
    budget b count
    pure
        [ [[i | (i, v) <- zip [0 ..] labels, v == j] | j <- [0 .. maximum (-1 : labels)]]
        | labels <- grow n [] (-1 :: Int)
        ]
  where
    grow 0 acc _ = [acc]
    grow k acc hi = concat [grow (k - 1) (acc ++ [j]) (max hi j) | j <- [0 .. hi + 1]]

triangle :: (Int -> Int -> Integer -> Integer -> Integer) -> Int -> Int -> Either MathError Integer
triangle f n k = do
    order n
    order k
    if n > 512
        then Left (InvalidArgument "triangular recurrence order exceeds 512")
        else pure ((iterate next [1] !! n) !! min k n * if k > n then 0 else 1)
  where
    next row = let i = length row in [f i j (at row (j - 1)) (at row j) | j <- [0 .. i]]
    at xs i | i < 0 || i >= length xs = 0 | otherwise = xs !! i

-- | Signed first-kind Stirling numbers, coefficients of the falling factorial.
stirlingFirst :: Int -> Int -> Either MathError Integer
stirlingFirst = triangle (\n _ a b -> a - toInteger (n - 1) * b)

stirlingSecond :: Int -> Int -> Either MathError Integer
stirlingSecond = triangle (\_ k a b -> a + toInteger k * b)

bellNumber :: Int -> Either MathError Integer
bellNumber n = sum <$> mapM (stirlingSecond n) [0 .. n]

eulerianNumber :: Int -> Int -> Either MathError Integer
eulerianNumber = triangle (\n k a b -> toInteger (n - k) * a + toInteger (k + 1) * b)

lahNumber :: Int -> Int -> Either MathError Integer
lahNumber n k = do
    order n
    order k
    pure
        ( if n == 0 && k == 0
            then 1
            else if k == 0 || k > n then 0 else choose (n - 1) (k - 1) * fact n `div` fact k
        )

catalanNumber :: Int -> Either MathError Integer
catalanNumber n = do order n; pure (choose (2 * n) n `div` toInteger (n + 1))

fibonacci :: Int -> Either MathError Integer
fibonacci n = do order n; pure (fst (pair n))
  where
    pair 0 = (0, 1)
    pair k =
        let (a, b) = pair (k `div` 2); c = a * (2 * b - a); d = a * a + b * b
         in if even k then (c, d) else (d, c + d)

lucas :: Int -> Either MathError Integer
lucas n = do a <- fibonacci n; b <- fibonacci (n + 1); pure (2 * b - a)

pascalTriangle :: Int -> Either MathError [[Integer]]
pascalTriangle n = do
    order n
    if n > 512
        then Left (InvalidArgument "Pascal order exceeds 512")
        else pure (take (n + 1) (iterate (\r -> zipWith (+) (0 : r) (r ++ [0])) [1]))

{- | Union cardinality from all nonempty intersection sizes, indexed by subset
bit mask 1 through 2^n-1. The caller supplies consistent intersection counts.
-}
inclusionExclusion :: Int -> [Integer] -> Either MathError Integer
inclusionExclusion n sizes
    | n < 0 || n > 20 || length sizes /= 2 ^ n - 1 || any (< 0) sizes =
        Left (InvalidArgument "invalid intersection table")
    | otherwise = Right (sum [if odd (ones i) then x else -x | (i, x) <- zip [1 :: Int ..] sizes])
  where
    ones 0 = 0 :: Int; ones k = k `mod` 2 + ones (k `div` 2)

subsets :: Int -> [a] -> Either MathError [[a]]
subsets b xs = do
    order (length xs)
    budget b (2 ^ length xs)
    pure (foldr (\x ps -> ps ++ map (x :) ps) [[]] xs)

cartesianProduct :: Int -> [[a]] -> Either MathError [[a]]
cartesianProduct b xs = do
    budget b (product (map (toInteger . length) xs)); pure (sequence xs)

multisetCount :: (Ord a) => [a] -> Either MathError Integer
multisetCount xs = multinomial (map length (group (sort xs)))

multisetPermutations :: (Ord a) => Int -> [a] -> Either MathError [[a]]
multisetPermutations b xs = do
    count <- multisetCount xs; budget b count; pure (go (sort xs))
  where
    go [] = [[]]
    go ys = [v : zs | v <- [v | v : _ <- group ys], zs <- go (delete v ys)]

{- | @a[n] = sum c[i]*a[n-i-1]@; initial values have the same length as
coefficients. A finite exact prefix of at most 4096 coefficients is returned.
-}
linearRecurrence :: Int -> [Integer] -> [Integer] -> Either MathError [Integer]
linearRecurrence n cs initial = do
    order n
    if null cs || length cs /= length initial
        then Left (InvalidArgument "recurrence initial state mismatch")
        else pure (take n (go initial))
  where
    k = length cs
    go ys = ys ++ extend ys
    extend ys = let z = sum (zipWith (*) cs (reverse (drop (length ys - k) ys))) in z : extend (drop 1 ys ++ [z])

{- | Formal power-series division @P(x)/Q(x)@ around zero, exact rationals.
The denominator constant must be nonzero; no analytic convergence is claimed.
-}
generatingCoefficients :: Int -> [Rational] -> [Rational] -> Either MathError [Rational]
generatingCoefficients n ps qs = do
    order n
    if null qs || get qs 0 == 0
        then Left (DomainError "series denominator has zero constant")
        else pure (go [] 0)
  where
    get xs i = if i < length xs then xs !! i else 0
    go acc i
        | i >= n = acc
        | otherwise =
            let v = (get ps i - sum [get qs j * (acc !! (i - j)) | j <- [1 .. min i (length qs - 1)]]) / get qs 0
             in go (acc ++ [v]) (i + 1)

convolveSeries :: Int -> [Integer] -> [Integer] -> Either MathError [Integer]
convolveSeries n a b = do
    order n
    pure
        [sum [a !! j * b !! (i - j) | j <- [0 .. i], j < length a, i - j < length b] | i <- [0 .. n - 1]]

finiteDifferences :: (Num a) => [a] -> [[a]]
finiteDifferences [] = []
finiteDifferences xs = xs : finiteDifferences (zipWith (-) (drop 1 xs) xs)

finiteSum :: (Num a) => [a] -> a
finiteSum = sum
