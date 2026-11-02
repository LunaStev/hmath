{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Typed records/labels. Every fitting, encoding and split operation is original.
module HMath.FFI.MachineLearning.Codec where

import Control.Exception (evaluate,throwIO)
import Data.Typeable (Typeable,cast)
import HMath.Error (MathError)
import HMath.FFI.MathError (CallbackFailure(..))
import HMath.FFI.NumericalCodec (From(..),To(..))
import qualified HMath.FFI.NumericalCodec as N
import HMath.FFI.Ordering (SomeOrdered(..),orderedWith)
import HMath.FFI.MachineLearning.Types ()
import qualified HMath.FFI.FoundationCodec as F
import qualified HMath.FFI.Value as V
import qualified HMath.MachineLearning as M


-- Generic record fields stay lossless Value payloads, as with Estimate/Rounded.
-- This transports the original Fit constructor and all diagnostics without
-- converting its model/label payload through a numerical approximation.
instance From a => From (M.Fit a) where
    from value = do
        original <- N.unbox 321 value :: IO (M.Fit V.Value)
        payload <- from (M.fitted original)
        pure (M.Fit payload (M.fitIterations original) (M.fitResidual original) (M.fitConverged original))
instance To a => To (M.Fit a) where
    to original = do
        payload <- to (M.fitted original)
        let value=M.Fit payload (M.fitIterations original) (M.fitResidual original) (M.fitConverged original)
        pure (N.box 321 value [pure payload,to (M.fitIterations original),to (M.fitResidual original),to (M.fitConverged original)])

-- Encoder is abstract in Haskell. Retain its actual homogeneous type and Ord
-- dictionary, rather than converting labels to Double/text or comparing fields.
data EncoderBox where
    EncoderBox :: (Typeable a,Ord a) => (a -> IO V.Value) -> (V.Value -> IO a) -> M.Encoder a -> EncoderBox

encoderValue :: EncoderBox -> V.Value
encoderValue value = V.Opaque 329 (-1) 0 (evaluate value >> pure ()) value
getEncoder :: V.Value -> IO EncoderBox
getEncoder (V.Opaque 329 _ _ _ value) = maybe (V.invalid "Encoder payload differs") pure (cast value)
getEncoder _ = V.invalid "expected MachineLearning.Encoder"
source :: Either MathError a -> IO a
source = either (throwIO . CallbackMathError) pure

categoryOrdering :: [V.Value] -> V.Value -> IO SomeOrdered
categoryOrdering values prototype = do
    result@(SomeOrdered _ readValue) <- orderedWith [F.foundationOrdering] (values ++ case prototype of V.None -> [];_ -> [prototype])
    case prototype of V.None -> pure ();_ -> readValue prototype >> pure ()
    pure result

fitEncoder :: V.Value -> V.Value -> IO V.Value
fitEncoder input prototype = do
    values <- V.asList input
    if null values then do
        _ <- source (M.fitEncoder ([] :: [Integer]))
        V.invalid "an empty Encoder needs a prototype"
    else fit values
  where
    fit values = do
        SomeOrdered write readValue <- categoryOrdering values prototype
        labels <- mapM readValue values
        encoder <- source (M.fitEncoder labels)
        pure (encoderValue (EncoderBox write readValue encoder))

labelEncode :: V.Value -> V.Value -> IO V.Value
labelEncode encoded input = do
    EncoderBox _ readValue encoder <- getEncoder encoded
    values <- V.asList input >>= mapM readValue
    source (M.labelEncode encoder values) >>= to

labelDecode :: V.Value -> V.Value -> IO V.Value
labelDecode encoded input = do
    EncoderBox write _ encoder <- getEncoder encoded
    indices <- from input
    labels <- source (M.labelDecode encoder indices)
    V.List <$> mapM write labels

oneHotEncode :: V.Value -> V.Value -> V.Value -> IO V.Value
oneHotEncode policyValue encoded input = do
    policy <- from policyValue
    EncoderBox _ readValue encoder <- getEncoder encoded
    labels <- V.asList input >>= mapM readValue
    source (M.oneHotEncode policy encoder labels) >>= to

stratifiedKFold :: V.Value -> V.Value -> V.Value -> V.Value -> IO V.Value
stratifiedKFold seedValue countValue input prototype = do
    seed <- from seedValue
    count <- from countValue
    values <- V.asList input
    if null values then source (M.stratifiedKFold seed count ([] :: [Integer])) >>= to else do
        SomeOrdered _ readValue <- categoryOrdering values prototype
        labels <- mapM readValue values
        source (M.stratifiedKFold seed count labels) >>= to
