-- SPDX-License-Identifier: MPL-2.0

module Main where

import HMath
import System.Exit (die)

main :: IO ()
main = case examples of
    Left err -> die ("HMath example failed: " ++ show err)
    Right linesToPrint -> mapM_ putStrLn linesToPrint

examples :: Either MathError [String]
examples = do
    matrix <- fromListChecked 2 3 [1, 2, 3, 4, 5, 6 :: Integer]
    section <- sliceMatrixChecked (0, 1) (2, 2) matrix
    reshaped <- reshapeChecked 3 2 matrix
    left <- zeroMatrixChecked 2 0
    right <- zeroMatrixChecked 0 3
    productMatrix <- multiplyChecked left right
    inner <- dotChecked [1, 2, 3 :: Integer] [4, 5, 6]
    pure
        [ "Slice: " ++ show (toList section)
        , "Reshape: " ++ show (shape reshaped, toList reshaped)
        , "Empty-inner product: " ++ show (shape productMatrix, toList productMatrix :: [Integer])
        , "Dot: " ++ show inner
        , "Length error: " ++ show (addChecked [1 :: Integer] [2, 3])
        ]
