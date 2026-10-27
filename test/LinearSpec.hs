-- SPDX-License-Identifier: MPL-2.0

module LinearSpec (linearTests) where

import Data.Ratio ((%))

import HMath

linearTests :: [(String, Bool)]
linearTests =
    [ ("checked dot", dotChecked [1, 2, 3 :: Int] [4, 5, 6] == Right 32)
    , ("checked empty dot", dotChecked ([] :: [Int]) [] == Right 0)
    , ("checked addition", addChecked [1, 2 :: Int] [3, -4] == Right [4, -2])
    , ("checked subtraction", subtractChecked [1, 2 :: Int] [3, -4] == Right [-2, 6])
    , ("checked empty addition", addChecked ([] :: [Int]) [] == Right [])
    , ("checked empty subtraction", subtractChecked ([] :: [Int]) [] == Right [])
    , ("dot length error", dotChecked [1 :: Int] [2, 3] == Left (VectorLengthMismatch 1 2))
    , ("addition length error", addChecked [1, 2 :: Int] [] == Left (VectorLengthMismatch 2 0))
    , ("subtraction length error", subtractChecked ([] :: [Int]) [1] == Left (VectorLengthMismatch 0 1))
    , ("rational dot is exact", dotChecked [1 % 3, 1 % 2] [3, 2] == Right (2 :: Rational))
    , ("empty magnitude", magnitude ([] :: [Double]) == 0)
    , ("empty normalization", normalize ([] :: [Double]) == [])
    , ("zero normalization is unchanged", normalize [0, 0 :: Double] == [0, 0])
    , ("unit normalization", let actual = normalize [3, 4 :: Double]
        in length actual == 2 && and (zipWith near actual [0.6, 0.8]))
    , ("nonempty magnitude", magnitude [3, 4 :: Double] == 5)
    , ("scalar multiplication values", scale (-2) [1, -3 :: Int] == [-2, 6])
    , ("bounded dot symmetry", all dotSymmetry compatiblePairs)
    , ("bounded addition/subtraction inverse", all additionInverse compatiblePairs)
    , ("bounded distributive dot", all dotDistribution compatibleTriples)
    , ("legacy operations agree with checked API", all legacyAgreement compatiblePairs)
    , ("scaling preserves length", all (\xs -> length (scale 3 xs) == length xs) vectors)
    ]
    where
        near a b = abs (a - b) <= 1e-12

vectors :: [[Int]]
vectors =
    [ take n (cycle patternValues)
    | n <- [0..4]
    , patternValues <- [[0], [1], [-2, 3], [1, 2, -1]]
    ]

compatiblePairs :: [([Int], [Int])]
compatiblePairs = [(xs, ys) | xs <- vectors, ys <- vectors, length xs == length ys]

compatibleTriples :: [([Int], [Int], [Int])]
compatibleTriples =
    [ (xs, ys, zs)
    | (xs, ys) <- compatiblePairs
    , zs <- vectors
    , length xs == length zs
    ]

dotSymmetry :: ([Int], [Int]) -> Bool
dotSymmetry (xs, ys) = dotChecked xs ys == dotChecked ys xs

additionInverse :: ([Int], [Int]) -> Bool
additionInverse (xs, ys) =
    (addChecked xs ys >>= \total -> subtractChecked total ys) == Right xs

dotDistribution :: ([Int], [Int], [Int]) -> Bool
dotDistribution (xs, ys, zs) =
    (addChecked ys zs >>= dotChecked xs) ==
        ((+) <$> dotChecked xs ys <*> dotChecked xs zs)

legacyAgreement :: ([Int], [Int]) -> Bool
legacyAgreement (xs, ys) =
    Right (dot xs ys) == dotChecked xs ys &&
    Right (add xs ys) == addChecked xs ys
