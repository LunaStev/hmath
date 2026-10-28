-- SPDX-License-Identifier: MPL-2.0
{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE ScopedTypeVariables #-}

{- | Private C boundary. Every IO export forces its complete numerical output
inside the exception handler before writing caller memory. The C facade
validates shape, buffer spans and runtime lifetime before entering Haskell.
-}
module HMath.FFI where

import Control.Exception (SomeException, catch, evaluate)
import Control.Monad (forM)
import Foreign
import Foreign.C.Types
import qualified HMath.Basic as Basic
import qualified HMath.Linear as Linear
import qualified HMath.Statistics as Statistics

foreign export ccall "hm_haskell_factorial" hmathFactorial :: CInt -> IO CLLong
hmathFactorial :: CInt -> IO CLLong
hmathFactorial n = catch result (\(_ :: SomeException) -> pure (-1))
  where
    result
        | n < 0 || n > 20 = pure (-1)
        | otherwise = evaluate (fromIntegral (Basic.factorial (fromIntegral n)))

-- | Preserve the prototype's IEEE nonfinite policy only in legacy calls.
foreign export ccall "hm_haskell_legacy"
    hmathLegacy :: CInt -> Ptr CDouble -> Ptr CDouble -> CSize -> Ptr CDouble -> IO CInt

hmathLegacy :: CInt -> Ptr CDouble -> Ptr CDouble -> CSize -> Ptr CDouble -> IO CInt
hmathLegacy op a b n out = boundary $ do
    value <- case op of
        0 -> (+) <$> peek a <*> peek b
        1
            | n == 0 || a == nullPtr -> pure (0 / 0)
            | otherwise -> Statistics.mean <$> peekArray (fromIntegral n) a
        2
            | n == 0 -> pure 0
            | a == nullPtr || b == nullPtr -> pure (0 / 0)
            | otherwise -> Linear.dot <$> peekArray (fromIntegral n) a <*> peekArray (fromIntegral n) b
        _ -> pure (0 / 0)
    evaluate value >>= poke out
    pure 0

boundary :: IO CInt -> IO CInt
boundary action = action `catch` (\(_ :: SomeException) -> pure 6)

{- | op: add scalar, sum, dot, elementwise add, dense matrix product. The
bounded reference matrix loop accumulates each cell in index order. Results
are finite checked; no partial caller output escapes a numerical failure.
-}
foreign export ccall "hm_haskell_kernel"
    hmathKernel ::
        CInt -> Ptr CDouble -> Ptr CDouble -> CSize -> CSize -> CSize -> CSize -> Ptr CDouble -> IO CInt

hmathKernel ::
    CInt -> Ptr CDouble -> Ptr CDouble -> CSize -> CSize -> CSize -> CSize -> Ptr CDouble -> IO CInt
hmathKernel op a b n rows inner columns out = boundary $ do
    xs <- if op == 4 then pure [] else peekArray (fromIntegral n) a
    values <- case op of
        0 -> do y <- peek b; pure [headValue xs + y]
        1 -> pure [sum xs]
        2 -> do ys <- peekArray (fromIntegral n) b; pure [Linear.dot xs ys]
        3 -> do ys <- peekArray (fromIntegral n) b; pure (zipWith (+) xs ys)
        4 -> fmap concat $ forM [0 .. fromIntegral rows - 1] $ \i ->
            forM [0 .. fromIntegral columns - 1] $ \j ->
                go (fromIntegral inner) (fromIntegral columns) i j 0 0
        _ -> error "HMath internal kernel opcode is invalid"
    forced <- mapM evaluate values
    if any (\x -> isNaN x || isInfinite x) forced
        then pure 3
        else pokeArray out forced >> pure 0
  where
    headValue [] = 0
    headValue (x : _) = x
    go k c i j z acc
        | z == k = evaluate acc
        | otherwise = do
            x <- peekElemOff a (i * k + z)
            y <- peekElemOff b (z * c + j)
            next <- evaluate (acc + x * y)
            go k c i j (z + 1) next
