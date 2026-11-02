{-# LANGUAGE ScopedTypeVariables #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Lossless ownership of the original complete RNG continuation state.
module HMath.FFI.RandomCodec where
import Control.Exception (evaluate)
import Data.Typeable (cast)
import qualified HMath.Random as R
import qualified HMath.FFI.Value as V

rng :: R.RNG -> V.Value
rng value = V.Opaque 240 (-1) 0 (evaluate value >> pure ()) value

asRNG :: V.Value -> IO R.RNG
asRNG (V.Opaque 240 _ _ _ payload) =
    maybe (V.invalid "invalid original RNG payload") pure (cast payload)
asRNG _ = V.invalid "expected original RNG state"
