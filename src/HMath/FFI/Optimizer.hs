{-# LANGUAGE ForeignFunctionInterface #-}

-- SPDX-License-Identifier: MPL-2.0
-- | Preserve the original immutable optimizer state and update semantics.
module HMath.FFI.Optimizer where

import Control.Exception (bracketOnError, evaluate)
import Data.Coerce (coerce)
import Foreign
import Foreign.C
import HMath.FFI.Boundary
import qualified HMath.Optimization.FirstOrder as O

foreign export ccall "hm_optimizer_initialize"
    initialize :: CPtrdiff -> Ptr (StablePtr O.OptimizerState) -> IO CInt

initialize :: CPtrdiff -> Ptr (StablePtr O.OptimizerState) -> IO CInt
initialize dimension out = boundary $
    checked (O.initializeOptimizer (fromIntegral dimension)) $ \state ->
        bracketOnError (newStablePtr state) freeStablePtr (poke out)

foreign export ccall "hm_optimizer_free" release :: StablePtr O.OptimizerState -> IO ()

release :: StablePtr O.OptimizerState -> IO ()
release = freeStablePtr

foreign export ccall "hm_optimizer_step"
    step ::
        CInt -> CDouble -> StablePtr O.OptimizerState ->
        Ptr CDouble -> CSize -> Ptr CDouble -> CSize ->
        Ptr CDouble -> Ptr (StablePtr O.OptimizerState) -> IO CInt

step ::
    CInt -> CDouble -> StablePtr O.OptimizerState ->
    Ptr CDouble -> CSize -> Ptr CDouble -> CSize ->
    Ptr CDouble -> Ptr (StablePtr O.OptimizerState) -> IO CInt
step method rate statePointer xs count gs gradientCount out outState = boundary $ do
    state <- deRefStablePtr statePointer
    parameters <- peekArray (fromIntegral count) (castPtr xs)
    gradient <- peekArray (fromIntegral gradientCount) (castPtr gs)
    checked (O.optimizerStep (toEnum (fromIntegral method)) (coerce rate) state parameters gradient) $
        \(next, nextState) -> do
            values <- mapM evaluate next
            bracketOnError (newStablePtr nextState) freeStablePtr $ \pointer -> do
                pokeArray (castPtr out) values
                poke outState pointer
