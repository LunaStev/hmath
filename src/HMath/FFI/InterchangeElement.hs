{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Exactly the fixed-width Element instances defined by Interchange.Array.
module HMath.FFI.InterchangeElement where

import Control.Exception (evaluate)
import Data.Binary.Get (Get)
import Data.Binary.Put (Put)
import Data.Proxy (Proxy(..))
import Data.Typeable (Typeable)
import qualified HMath.Interchange.Array as A
import HMath.FFI.Coefficient
import qualified HMath.FFI.TensorCodec as T
import qualified HMath.FFI.Value as V
import qualified HMath.Matrix as M
import qualified HMath.Tensor as Tensor

data Element a where
    Numeric :: (Coefficient a,A.Element a) => ScalarType a -> Element a
    Logical :: Element Bool
data SomeElement where
    SomeElement :: (A.Element a,Typeable a) => Element a -> SomeElement

dictionary :: Coefficient a => ScalarType a -> Maybe (Dict (A.Element a))
dictionary witness = case witness of
    SDouble -> Just Dict
    SFloat -> Just Dict
    SComplexDouble -> Just Dict
    SComplexFloat -> Just Dict
    SInt8 -> Just Dict
    SInt16 -> Just Dict
    SInt32 -> Just Dict
    SInt64 -> Just Dict
    SWord8 -> Just Dict
    SWord16 -> Just Dict
    SWord32 -> Just Dict
    SWord64 -> Just Dict
    _ -> Nothing
element :: V.Value -> IO SomeElement
element (V.Boolean _) = pure (SomeElement Logical)
element (V.Scalar witness _) = case dictionary witness of
    Just Dict -> pure (SomeElement (Numeric witness))
    Nothing -> V.unsupported "source Element instance does not exist for this coefficient"
element _ = V.invalid "expected a fixed-width Element prototype"

scalar :: Element a -> a -> V.Value
scalar (Numeric witness) = V.Scalar witness
scalar Logical = V.Boolean
readScalar :: Element a -> V.Value -> IO a
readScalar (Numeric _) = V.asScalar
readScalar Logical = V.asBoolean
values :: Element a -> V.Value -> IO [a]
values witness value = V.asList value >>= mapM (readScalar witness)
matrix :: Element a -> M.Matrix a -> V.Value
matrix (Numeric witness) = V.Dense . V.SomeMatrix witness
matrix Logical = V.booleanMatrix
tensor :: Element a -> Tensor.Tensor a -> V.Value
tensor (Numeric witness) = T.fromTensor (T.Numeric witness)
tensor Logical = T.fromTensor T.Logical
code :: forall a. A.Element a => Element a -> A.DType
code _ = A.elementType (Proxy :: Proxy a)

get :: forall a. A.Element a => Element a -> A.Endian -> Get V.Value
get witness endian = scalar witness <$> (A.getElement endian :: Get a)
put :: A.Element a => Element a -> A.Endian -> V.Value -> IO Put
put witness endian value = A.putElement endian <$> readScalar witness value

fromMatrix :: A.Limits -> A.Endian -> V.Value -> IO (Either A.InterchangeError A.Array)
fromMatrix limits endian value = case value of
    V.Dense (V.SomeMatrix witness original) -> case dictionary witness of
        Just Dict -> pure (A.fromMatrix limits endian original)
        Nothing -> V.unsupported "Matrix element has no source Element instance"
    V.Dense (V.StructuralMatrix 16 _ _ _ _) -> do
        original <- V.asMatrix value :: IO (M.Matrix Bool)
        pure (A.fromMatrix limits endian original)
    _ -> V.unsupported "Matrix element has no source Element instance"
fromTensor :: A.Limits -> A.Endian -> V.Value -> IO (Either A.InterchangeError A.Array)
fromTensor limits endian value = do
    T.SomeTensor witness original <- T.asTensor value
    case witness of
        T.Numeric numeric -> case dictionary numeric of
            Just Dict -> pure (A.fromTensor limits endian original)
            Nothing -> V.unsupported "Tensor element has no source Element instance"
        T.Logical -> pure (A.fromTensor limits endian original)
        T.Characters -> V.unsupported "String has no source Element instance"
        T.Structural _ -> V.unsupported "structural Tensor element has no source fixed-width Element instance"

forceProgram :: Put -> IO ()
forceProgram program = evaluate program >> pure ()
