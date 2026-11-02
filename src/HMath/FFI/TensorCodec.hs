{-# LANGUAGE GADTs #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ConstraintKinds #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Exact element witnesses and ownership of original Tensor/MutableTensor values.
module HMath.FFI.TensorCodec where

import Control.Exception (evaluate)
import Data.Proxy (Proxy(..))
import Data.Typeable (Typeable,cast)
import Foreign.Storable (Storable)
import HMath.FFI.Coefficient
import qualified HMath.FFI.Value as V
import qualified HMath.Tensor as T
import qualified HMath.Tensor.Mutable as M

-- Every witness retains the original Haskell element type. Bool/String are
-- permitted for structural and callback APIs without inventing Num instances.
data Element a where
    Numeric :: Coefficient a => ScalarType a -> Element a
    Logical :: Element Bool
    Characters :: Element String
    Structural :: (Typeable a,Eq a,Show a) => StructuralCodec a -> Element a

-- Providers retain their actual source type, without requiring or inventing a
-- Num instance. Optional dictionaries expose only instances the source has.
data StructuralCodec a = StructuralCodec
    { structuralCode :: Int
    , structuralEncode :: a -> V.Value
    , structuralDecode :: V.Value -> IO a
    , structuralForce :: a -> IO ()
    , structuralOrdering :: Maybe (Dict (Ord a))
    , structuralRead :: Maybe (Dict (Read a))
    , structuralStorable :: Maybe (Dict (Storable a))
    }

data SomeElement where
    SomeElement :: (Typeable a,Eq a,Show a) => Element a -> SomeElement
data SomeTensor where
    SomeTensor :: (Typeable a,Eq a,Show a) => Element a -> T.Tensor a -> SomeTensor
data SomeGraph where
    SomeGraph :: (Typeable a,Eq a,Show a) => Element a -> T.TensorGraph a -> SomeGraph
data SomeMutable where
    SomeMutable :: (Typeable a,Eq a,Show a,Storable a) => Element a -> M.MutableTensor a -> SomeMutable

element :: V.Value -> IO SomeElement
element (V.Scalar witness _) = pure (SomeElement (Numeric witness))
element (V.Boolean _) = pure (SomeElement Logical)
element (V.Text _) = pure (SomeElement Characters)
element (V.Opaque 294 _ _ _ payload) = maybe (V.invalid "invalid structural tensor type token") pure (cast payload)
element _ = V.invalid "expected a typed scalar, Boolean or String prototype"

elementCode :: Element a -> Int
elementCode (Numeric witness) = scalarTypeCode witness
elementCode Logical = 16
elementCode Characters = 17
elementCode (Structural codec) = structuralCode codec
prototype :: Element a -> V.Value
prototype (Numeric witness) = V.Scalar witness 0
prototype Logical = V.Boolean False
prototype Characters = V.Text ""
prototype witness@(Structural codec) = V.Opaque 294 (structuralCode codec) 0 (pure ()) (SomeElement witness)
asElement :: Element a -> V.Value -> IO a
asElement (Numeric _) = V.asScalar
asElement Logical = V.asBoolean
asElement Characters = V.asText
asElement (Structural codec) = structuralDecode codec
scalar :: Element a -> a -> V.Value
scalar (Numeric witness) value = V.Scalar witness value
scalar Logical value = V.Boolean value
scalar Characters value = V.Text value
scalar (Structural codec) value = structuralEncode codec value
forceElement :: Element a -> a -> IO ()
forceElement (Numeric _) value = forceCoefficient value
forceElement Logical value = evaluate value >> pure ()
forceElement Characters value = mapM_ evaluate value
forceElement (Structural codec) value = structuralForce codec value

fromTensor :: (Typeable a,Eq a,Show a) => Element a -> T.Tensor a -> V.Value
fromTensor kind value = case kind of
    Numeric SDouble -> V.Opaque 161 0 (T.numel value) (mapM_ (forceElement kind) (T.tensorValues value)) value
    _ -> V.Opaque 270 (elementCode kind) (T.numel value) (mapM_ (forceElement kind) (T.tensorValues value)) (SomeTensor kind value)
asTensor :: V.Value -> IO SomeTensor
asTensor (V.Opaque 161 _ _ _ payload) = maybe (V.invalid "invalid Tensor Double payload") (pure . SomeTensor (Numeric SDouble)) (cast payload)
asTensor (V.Opaque 270 _ _ _ payload) = maybe (V.invalid "invalid typed Tensor payload") pure (cast payload)
asTensor _ = V.invalid "expected original immutable Tensor"
asTensorType :: forall a. Typeable a => V.Value -> IO (T.Tensor a)
asTensorType value = do
    SomeTensor _ tensor <- asTensor value
    maybe (V.invalid "tensor element types differ") pure (cast tensor)
fromGraph :: (Typeable a,Eq a,Show a) => Element a -> T.TensorGraph a -> V.Value
fromGraph kind value = V.Opaque 271 (elementCode kind) 0 (evaluate value >> pure ()) (SomeGraph kind value)
asGraph :: V.Value -> IO SomeGraph
asGraph (V.Opaque 271 _ _ _ payload) = maybe (V.invalid "invalid TensorGraph payload") pure (cast payload)
asGraph _ = V.invalid "expected original TensorGraph"
asGraphType :: forall a. Typeable a => V.Value -> IO (T.TensorGraph a)
asGraphType value = do
    SomeGraph _ graph <- asGraph value
    maybe (V.invalid "graph element types differ") pure (cast graph)
fromMutable :: (Typeable a,Eq a,Show a,Storable a) => Element a -> M.MutableTensor a -> V.Value
fromMutable kind value = V.Opaque 272 (elementCode kind) (product (M.mutableShape value)) (evaluate value >> pure ()) (SomeMutable kind value)
asMutable :: V.Value -> IO SomeMutable
asMutable (V.Opaque 272 _ _ _ payload) = maybe (V.invalid "invalid MutableTensor payload") pure (cast payload)
asMutable _ = V.invalid "expected original MutableTensor"

withNum :: Element a -> (Num a => IO b) -> IO b
withNum (Numeric _) action = action
withNum _ _ = V.unsupported "element type has no original Num instance"
withFractional :: forall a b. Element a -> (Fractional a => IO b) -> IO b
withFractional (Numeric _) action = case fractionalDict (Proxy::Proxy a) of
    Just Dict -> action
    Nothing -> V.unsupported "element type has no original Fractional instance"
withFractional _ _ = V.unsupported "element type has no original Fractional instance"
withFloating :: forall a b. Element a -> (Floating a => IO b) -> IO b
withFloating (Numeric _) action = case floatingDict (Proxy::Proxy a) of
    Just Dict -> action
    Nothing -> V.unsupported "element type has no original Floating instance"
withFloating _ _ = V.unsupported "element type has no original Floating instance"
withReal :: forall a b. Element a -> (Real a => IO b) -> IO b
withReal (Numeric _) action = case realDict (Proxy::Proxy a) of
    Just Dict -> action
    Nothing -> V.unsupported "element type has no original Real instance"
withReal _ _ = V.unsupported "element type has no original Real instance"
withRealFloat :: forall a b. Element a -> (RealFloat a => IO b) -> IO b
withRealFloat (Numeric _) action = case realFloatDict (Proxy::Proxy a) of
    Just Dict -> action
    Nothing -> V.unsupported "element type has no original RealFloat instance"
withRealFloat _ _ = V.unsupported "element type has no original RealFloat instance"
withOrd :: forall a b. Element a -> (Ord a => IO b) -> IO b
withOrd (Numeric _) action = case orderingDict (Proxy::Proxy a) of
    Just Dict -> action
    Nothing -> V.unsupported "element type has no original Ord instance"
withOrd Logical action = action
withOrd Characters action = action
withOrd (Structural codec) action = maybe (V.unsupported "structural element has no exposed original Ord instance") (\Dict -> action) (structuralOrdering codec)

readDictionary :: Element a -> Maybe (Dict (Read a))
readDictionary (Numeric witness) = case witness of
    SDouble -> Just Dict
    SFloat -> Just Dict
    SInteger -> Just Dict
    SRational -> Just Dict
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
    SInt -> Just Dict
    SWord -> Just Dict
    SDual _ -> Nothing
    SQuaternion _ -> Nothing
readDictionary Logical = Just Dict
readDictionary Characters = Just Dict
readDictionary (Structural codec) = structuralRead codec
storableDictionary :: Element a -> Maybe (Dict (Storable a))
storableDictionary (Numeric witness) = case witness of
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
    SInt -> Just Dict
    SWord -> Just Dict
    SInteger -> Nothing
    SRational -> Nothing
    SDual _ -> Nothing
    SQuaternion _ -> Nothing
storableDictionary Logical = Just Dict
storableDictionary Characters = Nothing
storableDictionary (Structural codec) = structuralStorable codec
withRead :: Element a -> (Read a => IO b) -> IO b
withRead witness action = maybe (V.unsupported "element type has no original Read instance") (\Dict -> action) (readDictionary witness)
withStorable :: Element a -> (Storable a => IO b) -> IO b
withStorable witness action = maybe (V.unsupported "element type has no original Storable instance") (\Dict -> action) (storableDictionary witness)
