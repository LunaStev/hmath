-- SPDX-License-Identifier: MPL-2.0

module DiscreteBatchSpec (discreteBatchTests) where

import Data.Bits (testBit, (.&.))
import Data.List (group, nub, permutations, sort, subsequences)
import qualified Data.Set as S
import qualified HMath.Algorithms as A
import qualified HMath.Combinatorics as C
import qualified HMath.DataStructure as D
import qualified HMath.Discrete as B
import HMath.Error (MathError)
import qualified HMath.Graph as G

ok :: Either MathError a -> (a -> Bool) -> Bool
ok value predicate = either (const False) predicate value
bad :: Either MathError a -> Bool
bad = either (const True) (const False)
near :: Double -> Double -> Bool
near a b = abs (a - b) <= 1e-8 * max 1 (max (abs a) (abs b))
check :: String -> Bool -> (String, Bool)
check name value = ("discrete: " ++ name, value)
smallLists :: [[Integer]]
smallLists = concat [sequence (replicate n [-1, 0, 1]) | n <- [0 .. 5]]

countTests :: [(String, Bool)]
countTests =
    [ check ("permutation ranks " ++ show n) $ ok (C.permutationsOf 100000 n [0 .. n - 1]) $ \ps ->
        and [C.rankPermutation p == Right r && C.unrankPermutation n r == Right p | (r, p) <- zip [0 ..] ps]
    | n <- [0 .. 7]
    ]
        ++ [ check ("combination ranks " ++ show (n, k)) $ ok (C.combinationsOf 100000 k [0 .. n - 1]) $ \cs ->
                and
                    [C.rankCombination n c == Right r && C.unrankCombination n k r == Right c | (r, c) <- zip [0 ..] cs]
           | n <- [0 .. 9]
           , k <- [0 .. n]
           ]
        ++ [ check "exact counting and sequences" $
                and
                    [ C.permutationsCount 5 3 == Right 60
                    , C.combinationsCount 5 3 == Right 10
                    , C.multinomial [2, 2, 1] == Right 30
                    , map C.derangementCount [0 .. 7] == map Right [1, 0, 1, 2, 9, 44, 265, 1854]
                    , map C.catalanNumber [0 .. 6] == map Right [1, 1, 2, 5, 14, 42, 132]
                    , map C.fibonacci [0 .. 9] == map Right [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
                    , map C.lucas [0 .. 6] == map Right [2, 1, 3, 4, 7, 11, 18]
                    , map C.bellNumber [0 .. 6] == map Right [1, 1, 2, 5, 15, 52, 203]
                    , C.stirlingFirst 4 2 == Right 11
                    , C.stirlingFirst 4 3 == Right (-6)
                    , C.stirlingSecond 5 2 == Right 15
                    , map (C.eulerianNumber 4) [0 .. 4] == map Right [1, 11, 11, 1, 0]
                    , C.lahNumber 4 2 == Right 36
                    , C.inclusionExclusion 3 [5, 4, 2, 3, 1, 1, 1] == Right 9
                    , C.multisetCount "aabbc" == Right 30
                    ]
           , check "integer partitions cardinality and invariants" $
                and
                    [ ok (C.integerPartitions 100000 n) $ \ps ->
                        length ps == [1, 1, 2, 3, 5, 7, 11, 15, 22, 30, 42] !! n
                            && all (\p -> sum p == n && all (> 0) p && p == reverse (sort p)) ps
                    | n <- [0 .. 10]
                    ]
           , check "set partitions Bell identities" $
                and
                    [ ok (C.setPartitions 10000 n) $ \ps ->
                        C.bellNumber n == Right (toInteger (length ps))
                            && all (\p -> sort (concat p) == [0 .. n - 1] && all (not . null) p) ps
                    | n <- [0 .. 7]
                    ]
           , check "subset and multiset enumeration" $
                ok (C.subsets 32 "abcde") (\ps -> length ps == 32 && length (nub ps) == 32)
                    && ok (C.multisetPermutations 30 "aabbc") (\ps -> length ps == 30 && ps == sort ps)
                    && C.cartesianProduct 4 [[1, 2 :: Int], [3, 4]] == Right [[1, 3], [1, 4], [2, 3], [2, 4]]
           , check "derangement enumeration" $
                ok (C.derangements 720 6) (\ps -> length ps == 265 && all (and . zipWith (/=) [0 ..]) ps)
           , check "Pascal and finite differences" $
                C.pascalTriangle 4 == Right [[1], [1, 1], [1, 2, 1], [1, 3, 3, 1], [1, 4, 6, 4, 1]]
                    && C.finiteDifferences ([0, 1, 4, 9] :: [Integer]) == [[0, 1, 4, 9], [1, 3, 5], [2, 2], [0]]
                    && C.finiteSum [1 .. 100 :: Integer] == 5050
           , check "recurrences and formal generating functions" $
                C.linearRecurrence 10 [1, 1] [0, 1] == Right [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
                    && C.generatingCoefficients 7 [0, 1] [1, -1, -1] == Right [0, 1, 1, 2, 3, 5, 8]
                    && C.convolveSeries 4 [1, 2, 3] [1, -1] == Right [1, 1, 1, -3]
           , check "counting malformed and budgets" $
                and
                    [ bad (C.combinationsCount (-1) 0)
                    , bad (C.rankPermutation [0, 0])
                    , bad (C.unrankPermutation 3 6)
                    , bad (C.rankCombination 5 [2, 1])
                    , bad (C.unrankCombination 5 3 10)
                    , bad (C.permutationsOf 5 3 [0 .. 3 :: Int])
                    , bad (C.integerPartitions 1 10)
                    , bad (C.setPartitions 2 4)
                    , bad (C.subsets 2 [1 .. 3 :: Int])
                    , bad (C.generatingCoefficients 2 [1] [0])
                    , bad (C.linearRecurrence 2 [] [])
                    ]
           ]

bitTests :: [(String, Bool)]
bitTests =
    [ check ("bit roundtrips " ++ show (w, x)) $ ok (B.bitSet w x) $ \b ->
        B.grayDecode (B.grayEncode b) == b
            && B.reverseBits (B.reverseBits b) == b
            && B.rotateBits (-3) (B.rotateBits 3 b) == b
            && B.populationCount b == length [j | j <- [0 .. w - 1], testBit x j]
            && B.leadingZeros b == length (takeWhile (not . testBit x) (reverse [0 .. w - 1]))
            && B.trailingZeros b == length (takeWhile (not . testBit x) [0 .. w - 1])
    | w <- [0 .. 7]
    , x <- [0 .. 2 ^ w - 1]
    ]
        ++ [ check "bitsets checked mutation and widths" $
                ok
                    (B.bitSet 8 5)
                    ( \b ->
                        B.bitInsert b 1 == B.bitSet 8 7
                            && B.bitDelete b 0 == B.bitSet 8 4
                            && B.bitMember b 2 == Right True
                            && bad (B.bitMember b 8)
                            && B.resizeBitSet 2 b == B.bitSet 2 1
                    )
                    && bad (B.bitSet 1 2)
                    && bad (B.bitSet (-1) 0)
                    && ok
                        (B.bitSet 8 6)
                        ( \a ->
                            ok
                                (B.bitSet 8 3)
                                ( \b ->
                                    B.hammingDistance a b == Right 2
                                        && B.bitUnion a b == B.bitSet 8 7
                                        && B.bitIntersection a b == B.bitSet 8 2
                                        && B.bitDifference a b == B.bitSet 8 4
                                )
                        )
           , check "set operations" $
                B.setUnion [3, 1, 1 :: Int] [2, 3] == [1, 2, 3]
                    && B.setIntersection [1, 2, 3 :: Int] [2, 3, 4] == [2, 3]
                    && B.setDifference [1, 2, 3 :: Int] [2] == [1, 3]
                    && B.symmetricDifference [1, 2 :: Int] [2, 3] == [1, 3]
           , check "relation and Boolean semiring" $
                B.transitiveClosure [[False, True, False], [False, False, True], [False, False, False]]
                    == Right [[False, True, True], [False, False, True], [False, False, False]]
                    && B.equivalenceClosure [[False, True], [False, False]] == Right [[True, True], [True, True]]
                    && B.isEquivalence [[True, False], [False, True]] == Right True
                    && B.booleanMultiply [[False, True], [True, False]] [[False, True], [True, False]]
                        == Right [[True, False], [False, True]]
                    && bad (B.transitiveClosure [[True], []])
           , check "propositions and truth table" $
                B.evaluateProp
                    [True, False]
                    (B.Iff (B.Implies (B.Variable 0) (B.Variable 1)) (B.Or (B.Not (B.Variable 0)) (B.Variable 1)))
                    == Right True
                    && ok
                        (B.truthTable 2 (B.Xor (B.Variable 0) (B.Variable 1)))
                        (\table -> map snd table == [False, True, True, False])
                    && bad (B.evaluateProp [] (B.Variable 0))
           , check "QM essential cover and don't cares" $
                B.quineMcCluskey 10000 3 [0, 1, 2, 3] [] == Right [B.Implicant 0 3]
                    && B.quineMcCluskey 10000 2 [0, 1] [2, 3] == Right [B.Implicant 0 3]
                    && B.quineMcCluskey 10000 2 [] [] == Right []
                    && bad (B.quineMcCluskey 0 3 [1, 2, 3] [])
           ]
        ++ [ check ("QM exhaustive Boolean function " ++ show mask) $
                let on = [x | x <- [0 .. 7], testBit mask (fromInteger x)]
                 in ok (B.quineMcCluskey 100000 3 on []) $ \terms ->
                        all (\x -> any (\p -> B.implicantCovers p x) terms == (x `elem` on)) [0 .. 7]
                            && length terms == minimumCover mask
           | mask <- [0 :: Int .. 255]
           ]

-- Independent dynamic program over truth-set masks, considering every ternary
-- cube (including non-prime cubes), to verify minimum term counts.
minimumCover :: Int -> Int
minimumCover target = table !! target
  where
    cubes =
        [ sum [2 ^ x | x <- [0 :: Int .. 7], (x .&. (7 - mask)) == value]
        | mask <- [0 .. 7]
        , value <- [0 .. 7]
        , value .&. mask == 0
        ]
    useful = [cube | cube <- cubes, cube .&. target == cube, cube > 0]
    table =
        0
            : [ if state .&. target /= state
                    then 100
                    else minimum (100 : [1 + table !! (state .&. (255 - cube)) | cube <- useful, state .&. cube /= 0])
              | state <- [1 .. 255]
              ]

algorithmTests :: [(String, Bool)]
algorithmTests =
    [ check ("sort/select/search reference " ++ show xs) $
        let expected = sort xs; n = length xs
         in all (== expected) [A.mergeSort xs, A.quicksort xs, A.heapsort xs, A.introsort xs, A.radixSort xs]
                && A.countingSort 3 (map fromInteger xs) == Right (map fromInteger expected)
                && and
                    [ A.quickselect k xs == Right (expected !! k) && A.introselect k xs == Right (expected !! k)
                    | k <- [0 .. n - 1]
                    ]
                && and
                    [ A.partialSort k xs == Right (take k expected) && A.topK k xs == Right (take k expected)
                    | k <- [0 .. n]
                    ]
                && and
                    [ A.lowerBound x expected == Right (length (takeWhile (< x) expected))
                        && A.upperBound x expected == Right (length (takeWhile (<= x) expected))
                        && A.binarySearch x expected == A.exponentialSearch x expected
                        && A.binarySearch x expected == A.interpolationSearch x expected
                    | x <- [-2 .. 2]
                    ]
                && map (xs !!) (A.argsort xs) == expected
                && A.deduplicate xs == nub expected
                && A.numericGroups xs == [(g !! 0, length g) | g <- group expected]
                && A.runLengthDecode 10 (A.runLengthEncode xs) == Right xs
    | xs <- smallLists
    ]
        ++ [ check "bucket and quantile selection" $
                A.bucketSort 4 [1, 0, 0.5, 0.25, 0.5] == Right [0, 0.25, 0.5, 0.5, 1]
                    && A.quantileSelect 0.25 [4, 1, 3, 2] == Right 1.75
                    && A.quantileSelect 1 [4, 1, 3, 2] == Right 4
           , check "ternary minimum" $
                ok
                    (A.ternarySearch 100 (\x -> (x - 3) ^ (2 :: Int)) (-10) 10)
                    (\(a, b) -> a <= 3 && b >= 3 && b - a < 1e-10)
           , check "numeric aggregates compression sweep" $
                A.prefixSums [1, 2, 3 :: Integer] == [0, 1, 3, 6]
                    && A.suffixSums [1, 2, 3 :: Integer] == [6, 5, 3, 0]
                    && A.applyDifferences (A.differenceArray [4, 1, 7 :: Integer]) == [4, 1, 7]
                    && A.coordinateCompression [8, 2, 8, 4 :: Int] == ([2, 4, 8], [2, 0, 2, 1])
                    && A.intervalSweep [(0, 3), (2, 5), (5, 7), (10, 10)] == Right (7, 2)
           , check "divide-conquer recurrence and tabulation" $
                A.divideConquerDP (replicate 8 0) (\k j -> fromIntegral ((j - k) ^ (2 :: Int)))
                    == Right (replicate 8 1)
                    && A.tabulateDP 7 (\i -> if i < 2 then [] else [(i - 1, 1), (i - 2, 1)])
                        == Right [1, 1, 2, 3, 5, 8, 13]
                    && A.memoizedDP 20 (\i -> if i < 2 then (1, []) else (0, [(i - 1, 1), (i - 2, 1)])) 8 == Right 34
           , check "binary lifting and integer matrix powers" $
                A.binaryLift [1, 2, 0] 100 0 == Right 1
                    && A.integerMatrixPower [[1, 1], [1, 0]] 10 == Right [[89, 55], [55, 34]]
                    && A.integerMatrixPower [[2]] 0 == Right [[1]]
           , check "rolling polynomial hashes" $
                ok
                    (A.rollingHashes 31 1000000007 3 [1 .. 9])
                    (\hs -> map Right hs == [A.polynomialHash 31 1000000007 (take 3 (drop i [1 .. 9])) | i <- [0 .. 6]])
                    && A.rollingHashes 2 7 0 [1, 2] == Right [0, 0, 0]
           , check "ordering/domain/work failures" $
                and
                    [ bad (A.lowerBound 1 [2, 1 :: Int])
                    , bad (A.quickselect 0 ([] :: [Int]))
                    , bad (A.partialSort 3 [1, 2 :: Int])
                    , bad (A.countingSort 5 [minBound, maxBound])
                    , bad (A.bucketSort 2 [0 / 0])
                    , bad (A.quantileSelect (0 / 0) [1])
                    , bad (A.runLengthDecode 2 [('a', 3)])
                    , bad (A.intervalSweep [(1, 0)])
                    , bad (A.memoizedDP 10 (\i -> (0, [(i, 1)])) 0)
                    , bad (A.binaryLift [2] 0 0)
                    , bad (A.integerMatrixPower [[1, 2]] 2)
                    ]
           ]

structureTests :: [(String, Bool)]
structureTests =
    [ check ("range structures reference " ++ show xs) $
        let n = length xs; ranges = [(lo, hi) | lo <- [0 .. n], hi <- [lo .. n]]
         in ok
                (D.fenwick xs)
                ( \tree ->
                    and [D.fenwickRange lo hi tree == Right (sum (take (hi - lo) (drop lo xs))) | (lo, hi) <- ranges]
                        && and
                            [ok (D.fenwickAdd i 7 tree) (\t -> D.fenwickRange 0 n t == Right (sum xs + 7)) | i <- [0 .. n - 1]]
                )
                && ok
                    (D.segmentTree xs)
                    ( \tree ->
                        and [D.segmentRange lo hi tree == Right (sum (take (hi - lo) (drop lo xs))) | (lo, hi) <- ranges]
                            && and
                                [ ok (D.segmentSet i 9 tree) (\t -> D.segmentRange 0 n t == Right (sum xs - xs !! i + 9))
                                | i <- [0 .. n - 1]
                                ]
                    )
                && ok
                    (D.sparseTable xs)
                    ( \tree ->
                        and
                            [ D.sparseMinimum lo hi tree == Right (minimum (take (hi - lo) (drop lo xs)))
                            | (lo, hi) <- ranges
                            , lo < hi
                            ]
                    )
                && ok
                    (D.disjointSparseTable xs)
                    ( \tree ->
                        and [D.disjointRange lo hi tree == Right (sum (take (hi - lo) (drop lo xs))) | (lo, hi) <- ranges]
                    )
                && and
                    [ D.monotonicMinima w xs == Right [minimum (take w (drop i xs)) | i <- [0 .. n - w]]
                    | w <- [1 .. n + 1]
                    ]
                && D.nextGreater xs
                    == [ case [j | j <- [i + 1 .. n - 1], xs !! j > xs !! i] of [] -> Nothing; j : _ -> Just j
                       | i <- [0 .. n - 1]
                       ]
                && drain (D.heapFromList xs) == sort xs
    | xs <- take 130 smallLists
    ]
        ++ [ check "indexed heap stale updates" $
                let h = D.indexedSet 4 0 (D.indexedSet 2 10 (D.indexedSet 4 7 D.indexedHeap))
                 in case D.indexedPop h of
                        Just ((4, 0), h') -> case D.indexedPop h' of
                            Just ((2, 10), h'') -> D.indexedPop h'' == Nothing
                            _ -> False
                        _ -> False
           , check "union find components" $
                ok
                    (D.unionFind 6 >>= D.union 0 1 >>= D.union 2 3 >>= D.union 1 3)
                    ( \u ->
                        D.connected 0 2 u == Right True
                            && D.connected 0 5 u == Right False
                            && sort (map sort (D.components u)) == [[0, 1, 2, 3], [4], [5]]
                            && bad (D.findRoot 6 u)
                    )
           , check "Bloom no false negatives and occupancy model" $
                ok
                    (D.bloom 4096 5)
                    ( \empty ->
                        let b = foldr D.bloomInsert empty [0 .. 99]
                         in all (`D.bloomMember` b) [0 .. 99]
                                && D.bloomFalsePositiveBound b > 0
                                && D.bloomFalsePositiveBound b < 1e-4
                    )
           , check "count-min nonunderestimation and error model" $
                ok
                    (D.countMin 100 5 >>= D.countMinAdd 10 7 >>= D.countMinAdd 20 11 >>= D.countMinAdd 10 3)
                    ( \s ->
                        D.countMinEstimate 10 s >= 10
                            && D.countMinEstimate 20 s >= 11
                            && let (e, p) = D.countMinErrorBound s in e > 0 && p < 0.01 && bad (D.countMinAdd 0 (-1) s)
                    )
           , check "HyperLogLog reproducible cardinality" $
                ok
                    (D.hyperLogLog 12)
                    ( \h ->
                        let a = foldr D.hllAdd h [1 .. 10000]; b = foldr D.hllAdd a [1 .. 10000]
                         in near (D.hllEstimate a) (D.hllEstimate b) && abs (D.hllEstimate a - 10000) < 800
                    )
           , check "reservoir bounds and determinism" $
                ok
                    (D.reservoir 5 42 >>= \r -> foldl (\p x -> p >>= D.reservoirAdd x) (Right r) [1 .. 100 :: Int])
                    ( \r ->
                        length (D.reservoirValues r) == 5
                            && length (nub (D.reservoirValues r)) == 5
                            && all (\x -> x >= 1 && x <= 100) (D.reservoirValues r)
                    )
           , check "online exact quantiles and cap" $
                ok
                    (D.onlineQuantiles 5 >>= D.quantileAdd 4 >>= D.quantileAdd 1 >>= D.quantileAdd 3 >>= D.quantileAdd 2)
                    ( \q ->
                        D.onlineQuantile 0.5 q == Right 2.5
                            && D.onlineQuantile 0 q == Right 1
                            && D.onlineQuantile 1 q == Right 4
                    )
                    && ok (D.onlineQuantiles 0) (bad . D.quantileAdd 1)
           , check "structure malformed contracts" $
                and
                    [ bad (D.fenwick [1] >>= D.fenwickAdd 1 1)
                    , bad (D.segmentTree [1] >>= D.segmentRange 0 2)
                    , bad (D.sparseTable [] >>= D.sparseMinimum 0 0)
                    , bad (D.disjointSparseTable [1] >>= D.disjointRange (-1) 0)
                    , bad (D.bloom 0 1)
                    , bad (D.countMin 0 2)
                    , bad (D.hyperLogLog 3)
                    ]
           ]
  where
    drain h = case D.heapPop h of Nothing -> []; Just (x, rest) -> x : drain rest

undirectedSmall :: [G.Graph]
undirectedSmall =
    [ g
    | selected <-
        subsequences [(u, v, fromIntegral (1 + (u + v) `mod` 3)) | u <- [0 .. 3], v <- [u + 1 .. 3]]
    , Right g <- [G.graph False 4 selected]
    ]
directedSmall :: [G.Graph]
directedSmall =
    [ g
    | selected <-
        subsequences [(u, v, fromIntegral ((u * 3 + v) `mod` 3)) | u <- [0 .. 2], v <- [0 .. 2], u /= v]
    , Right g <- [G.graph True 3 selected]
    ]

-- Independent exhaustive simple-path distances; nonnegative edges make a
-- shortest simple path sufficient, even with zero-weight cycles.
referenceDistance :: G.Graph -> Int -> Int -> Maybe Double
referenceDistance g source target = case paths [source] 0 of [] -> Nothing; values -> Just (minimum values)
  where
    paths visited cost
        | last visited == target = [cost]
        | otherwise =
            concat
                [paths (visited ++ [u]) (cost + w) | (u, w, _) <- G.neighbors g (last visited), u `notElem` visited]

referenceForest :: G.Graph -> Double
referenceForest g =
    minimum
        [ sum (map G.edgeWeight selected)
        | selected <- subsequences (G.edges g)
        , length selected == G.vertexCount g - length (G.connectedComponents g)
        , Right candidate <-
            [G.graph False (G.vertexCount g) [(G.edgeFrom e, G.edgeTo e, G.edgeWeight e) | e <- selected]]
        , G.connectedComponents candidate == G.connectedComponents g
        ]

referenceCut :: Int -> [(Int, Int, Integer, Integer)] -> Integer
referenceCut n es =
    minimum
        [ sum [c | (u, v, c, _) <- es, u `elem` side, v `notElem` side]
        | inside <- subsequences [1 .. n - 2]
        , let side = 0 : inside
        ]

referenceMatching :: Int -> Int -> [(Int, Int, Double)] -> Int
referenceMatching left right es =
    maximum
        ( 0
            : [ length chosen
              | chosen <- subsequences [(u, v) | (u, v, _) <- es]
              , length (nub (map fst chosen)) == length chosen
              , length (nub (map snd chosen)) == length chosen
              , all (\(u, v) -> u < left && v < right) chosen
              ]
        )

graphTests :: [(String, Bool)]
graphTests =
    [ check ("undirected exhaustive " ++ show i) $
        G.deserializeGraph (G.serializeGraph g) == Right g
            && G.fromCSR (G.toCSR g) == Right g
            && all
                (\solver -> ok (solver g) (\es -> near (sum (map G.edgeWeight es)) (referenceForest g)))
                [G.kruskal, G.prim, G.boruvka]
            && G.tarjanSCC g == G.kosarajuSCC g
            && ok
                (G.bfs g 0)
                (\vs -> S.fromList vs == S.fromList [v | v <- [0 .. 3], referenceDistance g 0 v /= Nothing])
            && ok
                (G.dfs g 0)
                (\vs -> S.fromList vs == S.fromList [v | v <- [0 .. 3], referenceDistance g 0 v /= Nothing])
            && ok
                (G.exactColoring 100000 g)
                (\colors -> all (\e -> colors !! G.edgeFrom e /= colors !! G.edgeTo e) (G.edges g))
            && ok (G.graphLaplacian False g) (all (near 0 . sum))
            && G.graphEditDistance 24 g g == Right 0
    | (i, g) <- zip [0 :: Int ..] undirectedSmall
    ]
        ++ [ check ("directed paths exhaustive " ++ show i) $
                let reference = [[referenceDistance g u v | v <- [0 .. 2]] | u <- [0 .. 2]]
                 in G.floydWarshall g == Right reference
                        && G.johnson g == Right reference
                        && all
                            ( \s ->
                                G.dijkstra g s == Right (reference !! s)
                                    && G.bellmanFord g s == Right (reference !! s)
                                    && all
                                        ( \t ->
                                            G.bidirectionalDijkstra g s t == Right (reference !! s !! t)
                                                && ok (G.aStar g (const 0) s t) (\answer -> fmap fst answer == reference !! s !! t)
                                        )
                                        [0 .. 2]
                            )
                            [0 .. 2]
                        && G.tarjanSCC g == G.kosarajuSCC g
           | (i, g) <- zip [0 :: Int ..] directedSmall
           ]
        ++ [ check ("four maxflows vs all cuts " ++ show i) $
                let es = [(0, 1, a, 0), (0, 2, b, 0), (1, 2, c, 0), (2, 1, d, 0), (1, 3, e, 0), (2, 3, f, 0)]
                 in ok (G.network 4 es) $ \net ->
                        let expected = referenceCut 4 es
                         in all
                                ( \solver ->
                                    ok
                                        (solver 10000 net 0 3)
                                        ( \answer ->
                                            G.flowValue answer == expected
                                                && all (>= 0) (G.edgeFlows answer)
                                                && and (zipWith (<=) (G.edgeFlows answer) [a, b, c, d, e, f])
                                        )
                                )
                                [G.fordFulkerson, G.edmondsKarp, G.dinic, G.pushRelabel]
                                && ok (G.minimumCut 10000 net 0 3) ((== expected) . snd)
           | (i, [a, b, c, d, e, f]) <- zip [0 :: Int ..] (sequence (replicate 6 [0, 1]))
           ]
        ++ [ check ("Hopcroft Karp exhaustive " ++ show i) $
                ok (G.bipartiteGraph 3 3 es) (\g -> length (G.hopcroftKarp g) == referenceMatching 3 3 es)
           | (i, es) <- zip [0 :: Int ..] (subsequences [(u, v, 1) | u <- [0 .. 2], v <- [0 .. 2]])
           ]
        ++ [ check "parallel/self-loop graph identity and CSR" $
                ok
                    (G.graph False 3 [(2, 0, 1), (0, 2, 2), (1, 1, 4), (1, 1, 4)])
                    ( \g ->
                        G.fromCSR (G.toCSR g) == Right g
                            && G.deserializeGraph (G.serializeGraph g) == Right g
                            && G.hasCycle g
                            && G.bridges g == Right []
                            && bad (G.greedyColoring g)
                    )
           , check "hypergraph empty/multiple edges roundtrip" $
                ok
                    (G.hypergraph 4 [[2, 0], [], [0, 2], [1]])
                    ( \g ->
                        G.deserializeHypergraph (G.serializeHypergraph g) == Right g
                            && G.hyperedges g == [[0, 2], [], [0, 2], [1]]
                    )
                    && bad (G.hypergraph 2 [[0, 0]])
           , check "topology DAG and longest path" $
                ok
                    (G.graph True 4 [(0, 1, 2), (0, 2, 1), (1, 3, 3), (2, 3, 6)])
                    ( \g ->
                        G.topologicalSort g == Right [0, 1, 2, 3]
                            && G.longestDAGPaths g 0 == Right [Just 0, Just 2, Just 1, Just 7]
                            && not (G.hasCycle g)
                            && G.multiSourceDijkstra g [1, 2] == Right [Nothing, Just 0, Just 0, Just 3]
                    )
           , check "negative weights Johnson and reachable negative cycles" $
                ok
                    (G.graph True 4 [(0, 1, -2), (1, 2, 3), (0, 2, 4)])
                    ( \g ->
                        G.bellmanFord g 0 == Right [Just 0, Just (-2), Just 1, Nothing]
                            && G.johnson g == G.floydWarshall g
                            && bad (G.dijkstra g 0)
                    )
                    && ok
                        (G.graph True 4 [(0, 1, 1), (2, 3, -1), (3, 2, -1)])
                        ( \g ->
                            G.bellmanFord g 0 == Right [Just 0, Just 1, Nothing, Nothing]
                                && bad (G.bellmanFord g 2)
                                && bad (G.johnson g)
                                && bad (G.floydWarshall g)
                        )
           , check "K simple paths identity and budget" $
                ok
                    (G.graph True 3 [(0, 1, 1), (0, 1, 2), (1, 2, 1), (0, 2, 4)])
                    ( \g ->
                        G.kShortestPaths 100 5 g 0 2
                            == Right [(2, [0, 1, 2], [0, 2]), (3, [0, 1, 2], [1, 2]), (4, [0, 2], [3])]
                            && bad (G.kShortestPaths 0 1 g 0 2)
                            && G.iterativeDeepening 100 g 0 2 == Right (Just [0, 2])
                    )
           , check "articulations bridges and Euler trail" $
                ok
                    (G.graph False 4 [(0, 1, 1), (1, 2, 1), (1, 2, 1), (2, 3, 1)])
                    ( \g ->
                        G.articulationPoints g == Right [1, 2]
                            && G.bridges g == Right [0, 3]
                            && G.eulerianPath g == Right Nothing
                    )
           , check "Euler trail consumes original edge identities" $
                ok
                    (G.graph False 4 [(0, 1, 1), (1, 2, 1), (2, 0, 1), (0, 3, 1)])
                    ( \g ->
                        ok
                            (G.eulerianPath g)
                            (\answer -> case answer of Nothing -> False; Just (vs, es) -> length vs == 5 && sort es == [0 .. 3])
                    )
           , check "Hamiltonian and tour heuristics" $
                ok
                    (G.graph False 4 [(0, 1, 1), (1, 2, 1), (2, 3, 1), (3, 0, 1), (0, 2, 4), (1, 3, 4)])
                    ( \g ->
                        ok (G.hamiltonianPath 1000 g) (maybe False (\p -> sort p == [0 .. 3]))
                            && ok (G.nearestNeighborTour g 0) (maybe False (\(c, p) -> near c 4 && length p == 5))
                            && G.twoOptTour 100 g [0, 2, 1, 3, 0] == Right (4, [0, 1, 2, 3, 0])
                    )
           , check "Hungarian exact rectangular costs" $
                and
                    [ ok
                        (G.hungarian matrix)
                        ( \(value, pairs) ->
                            value
                                == minimum
                                    [ sum [matrix !! r !! (p !! r) | r <- [0 .. length matrix - 1]]
                                    | p <- permutations [0 .. length (matrix !! 0) - 1]
                                    ]
                                && length pairs == length matrix
                        )
                    | matrix <- [[[4, 1, 3], [2, 0, 5], [3, 2, 2]], [[2, -1, 5], [0, 3, -2]], [[7]], [[0, 0], [0, 0]]]
                    ]
                    && G.hungarian [] == Right (0, [])
           , check "minimum-cost negative cycles and antiparallel edges" $
                ok
                    (G.network 4 [(0, 1, 2, 3), (1, 3, 2, 1), (0, 2, 1, 1), (2, 3, 1, 1), (1, 2, 1, -5), (2, 1, 1, 0)])
                    (\net -> ok (G.minimumCostMaximumFlow 10000 net 0 3) (\r -> G.flowValue r == 3 && G.flowCost r == 5))
                    && ok
                        (G.network 4 [(0, 1, 1, 2), (2, 3, 2, -4), (3, 2, 2, 1)])
                        ( \net -> ok (G.minimumCostMaximumFlow 1000 net 0 1) (\r -> G.flowValue r == 1 && G.flowCost r == (-4))
                        )
           , check "PageRank and centrality cycle reference" $
                ok
                    (G.graph False 4 [(0, 1, 1), (1, 2, 1), (2, 3, 1), (3, 0, 1)])
                    ( \g ->
                        ok (G.pageRank 100 1e-12 0.85 g) (all (near 0.25))
                            && G.degreeCentrality g == replicate 4 (2 / 3)
                            && all (near 0.5) (G.betweennessCentrality g)
                            && all (near 0.75) (G.closenessCentrality g)
                            && ok (G.eigenvectorCentrality 100 1e-12 g) (all (near 0.5))
                            && ok (G.katzCentrality 100 1e-12 0.1 1 g) (all (near 1.25))
                            && G.clusteringCoefficients g == Right [0, 0, 0, 0]
                            && near (G.density g) (2 / 3)
                            && G.diameterRadius g == Just (2, 2)
                            && ok (G.laplacianSpectrum 1000 1e-12 False g) (\xs -> and (zipWith near xs [0, 2, 2, 4]))
                    )
           , check "community modularity and Louvain aggregation" $
                ok
                    (G.graph False 6 [(0, 1, 5), (1, 2, 5), (0, 2, 5), (3, 4, 5), (4, 5, 5), (3, 5, 5), (2, 3, 0.01)])
                    ( \g ->
                        ok
                            (G.louvain 10000 g)
                            ( \labels ->
                                length (nub labels) == 2
                                    && labels !! 0 == labels !! 1
                                    && labels !! 3 == labels !! 5
                                    && ok (G.modularity g labels) (> 0.49)
                            )
                            && ok (G.labelPropagation 100 g) (\labels -> length labels == 6)
                            && ok (G.randomWalk 100 42 g 0) (\path -> length path == 101 && all (\v -> v >= 0 && v < 6) path)
                            && G.graphSimilarity g g == Right 1
                    )
           , check "graph malformed/empty/budget/finite contracts" $
                and
                    [ bad (G.graph True 1 [(0, 1, 1)])
                    , bad (G.graph True 1 [(0, 0, 0 / 0)])
                    , bad (G.deserializeGraph "(\"wrong\",True,0,[])")
                    , bad (G.fromCSR (G.CSR True 1 [0, 1] [] [] [] []))
                    , bad (G.network 2 [(0, 1, -1, 0)])
                    , bad (G.network 2 [(0, 1, 1, 0)] >>= \net -> G.dinic 0 net 0 1)
                    , ok
                        (G.graph False 0 [])
                        ( \g ->
                            G.connectedComponents g == []
                                && G.kruskal g == Right []
                                && G.tarjanSCC g == []
                                && G.eulerianPath g == Right (Just ([], []))
                                && G.hamiltonianPath 0 g == Right (Just [])
                                && G.density g == 0
                                && G.diameterRadius g == Nothing
                                && G.fromCSR (G.toCSR g) == Right g
                        )
                    ]
           ]

additionalTests :: [(String, Bool)]
additionalTests =
    [ check "multiset algebra exact multiplicities" $
        let a = B.multiset "aabbc"; b = B.multiset "abbd"
         in B.multisetEntries (B.multisetUnion a b) == [('a', 3), ('b', 4), ('c', 1), ('d', 1)]
                && B.multisetEntries (B.multisetIntersection a b) == [('a', 1), ('b', 2)]
                && B.multisetEntries (B.multisetDifference a b) == [('a', 1), ('c', 1)]
                && B.multiplicity 'a' (B.multisetDelete 'a' a) == 1
                && B.multiplicity 'z' (B.multisetInsert 'z' a) == 1
    , check "complete binary heap exhaustive reference" $
        and [ok (D.binaryHeap xs) (\heap -> drain heap == sort xs) | xs <- smallLists]
    , check "all graph representations preserve IDs and orientation" $
        and
            [ let orientations = [(G.edgeFrom e, G.edgeTo e) | e <- G.edges g]
               in G.fromAdjacencyList (G.directed g) (G.adjacencyList g) orientations == Right g
                    && G.fromLabeledAdjacencyMatrix (G.directed g) (G.adjacencyMatrix g) orientations == Right g
            | g <- undirectedSmall ++ directedSmall
            ]
            && ok
                (G.bipartiteGraph 2 3 [(1, 0, 2), (0, 2, 3), (1, 0, 4)])
                (\g -> G.deserializeBipartiteGraph (G.serializeBipartiteGraph g) == Right g)
    , check "reachable intermediate overflow cannot be masked" $
        ok
            (G.graph True 4 [(0, 1, 1e308), (1, 2, 1e308), (0, 2, 1)])
            ( \g ->
                all (\f -> bad (f g)) [\x -> G.dijkstra x 0, \x -> G.bellmanFord x 0]
                    && bad (G.floydWarshall g)
                    && bad (G.johnson g)
                    && bad (G.aStar g (const 0) 0 3)
                    && bad (G.longestDAGPaths g 0)
            )
            && ok
                (G.graph False 2 [(0, 1, 1e308), (0, 1, 1e308)])
                ( \g -> bad (G.pageRank 100 1e-8 0.85 g) && bad (G.graphLaplacian True g) && bad (G.modularity g [0, 0])
                )
    , check "path errors and domain contracts" $
        ok
            (G.graph True 2 [(0, 1, 1)])
            ( \g ->
                bad (G.aStar g (\v -> if v == 0 then 2 else 0) 0 1)
                    && bad (G.aStar g (const (0 / 0)) 0 1)
                    && bad (G.dijkstra g 2)
                    && bad (G.iterativeDeepening 0 g 0 1)
            )
            && ok (G.graph True 2 [(0, 1, 1), (1, 0, 1)]) (bad . G.topologicalSort)
    , check "edits and similarities distinguish multigraph labels" $
        ok
            (G.graph False 2 [(0, 1, 1), (0, 1, 1)])
            ( \a ->
                ok
                    (G.graph False 2 [(1, 0, 1)])
                    ( \b ->
                        G.graphEditDistance 2 a b == Right 1
                            && G.graphSimilarity a b == Right 0.5
                            && bad (G.graphEditDistance 1 a b)
                    )
            )
    ]
        ++ [ check ("deterministic range update sequence " ++ show seed) $ rangeSequence seed
           | seed <- [1 .. 20]
           ]
        ++ [ check ("min-cost all feasible flows " ++ show seed) $
                let es =
                        [ (0, 1, fromIntegral (seed `mod` 3), fromIntegral (seed `mod` 5 - 2))
                        , (1, 2, 2, 1)
                        , (0, 2, 1, 3)
                        , (1, 0, 1, -1)
                        , (2, 1, 1, fromIntegral (seed `mod` 3 - 1))
                        , (3, 3, 1, -2)
                        ]
                 in ok
                        (G.network 4 es)
                        ( \net ->
                            ok
                                (G.minimumCostMaximumFlow 10000 net 0 2)
                                (\answer -> (G.flowValue answer, G.flowCost answer) == referenceCostFlow 4 0 2 es)
                        )
           | seed <- [0 :: Int .. 39]
           ]
  where
    drain heap = case D.binaryPop heap of Nothing -> []; Just (value, next) -> value : drain next

rangeSequence :: Int -> Bool
rangeSequence seed = ok (D.fenwick initial) (\f -> ok (D.segmentTree initial) (\s -> step f s initial operations))
  where
    initial = map fromIntegral [0 .. 9 :: Int]
    operations = take 40 (iterate (\x -> (x * 73 + 19) `mod` 997) seed)
    step _ _ _ [] = True
    step fenwick segment values (code : rest) =
        let index = code `mod` 10
            delta = toInteger (code `mod` 17 - 8)
            nextValues = take index values ++ [values !! index + delta] ++ drop (index + 1) values
         in ok
                (D.fenwickAdd index delta fenwick)
                ( \f ->
                    ok
                        (D.segmentSet index (nextValues !! index) segment)
                        ( \s ->
                            and
                                [ let expected = Right (sum (take (hi - lo) (drop lo nextValues)))
                                   in D.fenwickRange lo hi f == expected && D.segmentRange lo hi s == expected
                                | lo <- [0 .. 10]
                                , hi <- [lo .. 10]
                                ]
                                && step f s nextValues rest
                        )
                )

referenceCostFlow :: Int -> Int -> Int -> [(Int, Int, Integer, Integer)] -> (Integer, Integer)
referenceCostFlow n source sink es =
    let feasible =
            [ (value, cost)
            | flows <- sequence [[0 .. capacity] | (_, _, capacity, _) <- es]
            , let excess v =
                    sum [f | ((u, _, _, _), f) <- zip es flows, u == v]
                        - sum [f | ((_, v', _, _), f) <- zip es flows, v' == v]
            , all (\v -> v == source || v == sink || excess v == 0) [0 .. n - 1]
            , let value = excess source
            , value >= 0
            , let cost = sum [f * c | ((_, _, _, c), f) <- zip es flows]
            ]
        bestValue = maximum (map fst feasible)
     in (bestValue, minimum [cost | (value, cost) <- feasible, value == bestValue])

discreteBatchTests :: [(String, Bool)]
discreteBatchTests = countTests ++ bitTests ++ algorithmTests ++ structureTests ++ graphTests ++ additionalTests
