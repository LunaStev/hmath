-- SPDX-License-Identifier: MPL-2.0

{-# LANGUAGE ForeignFunctionInterface #-}

module HMath.FFI where

import Foreign
import Foreign.C.Types

import qualified HMath.Basic as Basic
import qualified HMath.Statistics as Statistics

import qualified HMath.Linear as Linear

foreign export ccall "hmath_add_f64"
    hmathAddF64 :: CDouble -> CDouble -> CDouble

hmathAddF64 :: CDouble -> CDouble -> CDouble
hmathAddF64 a b = a + b

foreign export ccall "hmath_factorial"
    hmathFactorial :: CInt -> CLLong

hmathFactorial :: CInt -> CLLong
hmathFactorial n
    | n < 0 || n > 20 = -1
    | otherwise = fromIntegral (Basic.factorial (fromIntegral n))

foreign export ccall "hmath_mean_f64"
    hmathMeanF64 :: Ptr CDouble -> CSize -> IO CDouble

hmathMeanF64 :: Ptr CDouble -> CSize -> IO CDouble
hmathMeanF64 ptr count
    | count == 0 = return (0 / 0)
    | ptr == nullPtr = return (0 / 0)
    | otherwise = do
        values <- peekArray (fromIntegral count) ptr
        return (Statistics.mean values)

foreign export ccall "hmath_dot_f64"
    hmathDotF64 :: Ptr CDouble -> Ptr CDouble -> CSize -> IO CDouble

hmathDotF64 :: Ptr CDouble -> Ptr CDouble -> CSize -> IO CDouble
hmathDotF64 a b count
    | count == 0 = return 0
    | a == nullPtr || b == nullPtr = return (0 / 0)
    | otherwise = do
        xs <- peekArray (fromIntegral count) a
        ys <- peekArray (fromIntegral count) b

        return (Linear.dot xs ys)
