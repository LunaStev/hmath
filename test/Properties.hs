{-# LANGUAGE ScopedTypeVariables #-}

-- SPDX-License-Identifier: MPL-2.0
module Main where

import qualified HMath.Matrix as M
import qualified HMath.Tensor as T
import Test.Hspec
import Test.QuickCheck

main :: IO ()
main = hspec $ do
    describe "Exact container laws" $ do
        it "transposing twice preserves shape and Integer elements" $
            property $
                \(NonNegative r0) (NonNegative c0) (seed :: Integer) ->
                    let r = r0 `mod` 10; c = c0 `mod` 10
                     in case M.fromListChecked r c (take (r * c) [seed ..]) of
                            Left _ -> False
                            Right m ->
                                M.shape (M.transposeMatrix (M.transposeMatrix m)) == (r, c)
                                    && M.toList (M.transposeMatrix (M.transposeMatrix m)) == M.toList m
        it "reshape preserves exact tensor values including empty axes" $
            property $
                \(NonNegative n0) (seed :: Integer) ->
                    let n = n0 `mod` 128; xs = take n [seed ..]
                     in case T.tensor [n] xs >>= T.reshapeTensor [1, n] of
                            Left _ -> False
                            Right t -> T.tensorValues t == xs && T.tensorShape t == [1, n]
        it "checked multiplication agrees with independent coordinates" $
            property $
                \(NonNegative n0) (a :: Integer) (b :: Integer) ->
                    let n = n0 `mod` 8
                        result = do
                            x <- M.fromListChecked 1 n (replicate n a)
                            y <- M.fromListChecked n 1 (replicate n b)
                            M.toList <$> M.multiplyChecked x y
                     in result == Right [toInteger n * a * b]
