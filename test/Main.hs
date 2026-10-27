-- SPDX-License-Identifier: MPL-2.0

module Main where

import HMath

main :: IO ()
main = do
    check "factorial" (factorial 5 == 120)
    check "fibonacci" (fibonacci 10 == 55)
    check "isPrime" (isPrime 97)
    check "dot" (dot [1, 2, 3] [4, 5, 6] == (32 :: Int))
    check "mean" (mean [10, 20, 30] == (20 :: Double))
    check "variance" (variance [1, 2, 3] == (2 / 3 :: Double))
    check "matrix addition" testMatrixAddition
    check "matrix multiplication" testMatrixMultiplication
    check "matrix transpose" testMatrixTranspose

check :: String -> Bool -> IO ()
check name result =
    if result
        then putStrLn ("PASS: " ++ name)
        else error ("FAIL: " ++ name)

testMatrixAddition :: Bool
testMatrixAddition =
    case (fromList 2 2 [1, 2, 3, 4],
          fromList 2 2 [5, 6, 7, 8]) of
        (Just a, Just b) ->
            fmap toList (addMatrix a b) == Just [6, 8, 10, 12]
        _ -> False

testMatrixMultiplication :: Bool
testMatrixMultiplication =
    case (fromList 2 3 [1, 2, 3, 4, 5, 6],
          fromList 3 2 [7, 8, 9, 10, 11, 12]) of
        (Just a, Just b) ->
            fmap toList (multiply a b) == Just [58, 64, 139, 154]
        _ -> False

testMatrixTranspose :: Bool
testMatrixTranspose =
    case fromList 2 3 [1, 2, 3, 4, 5, 6] of
        Just a ->
            toList (transposeMatrix a) == [1, 4, 2, 5, 3, 6]
        Nothing -> False
