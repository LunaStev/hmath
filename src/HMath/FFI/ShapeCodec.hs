{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE FlexibleContexts #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Reify real source KnownNat/KnownShape indices; never coerce dimensions.
module HMath.FFI.ShapeCodec where

import Control.Exception(evaluate)
import Data.Proxy(Proxy(..))
import Data.Typeable(Typeable,cast)
import Data.Type.Equality((:~:)(Refl))
import GHC.TypeLits(Nat,KnownNat,SomeNat(..),someNatVal,sameNat)
import qualified HMath.API.Shape as S
import qualified HMath.Matrix as M
import qualified HMath.Error as E
import qualified HMath.FFI.Value as V
import qualified HMath.FFI.LinearCodec as LC
import qualified HMath.FFI.TensorCodec as TC
import HMath.FFI.Coefficient
import HMath.FFI.FoundationCodec
import HMath.FFI.AlgebraCodec(Wire(..),coefficientWire,wireCode,forceWire,writeWire,withMatrix,matrix,algebraElement)

shape :: S.Shape -> V.Value
shape value=opaqueEq "HMath.API.Shape.Shape" (-1)value(evaluate(S.shapeElements value)>>pure())(V.unsupported "original abstract Shape has no public constructor fields")
asShape :: V.Value -> IO S.Shape
asShape=unbox "HMath.API.Shape.Shape"

data SomeStaticMatrix where
    SomeStaticMatrix :: (KnownNat m,KnownNat n,Typeable a) => Wire a -> Maybe(Dict(Num a)) -> (M.Matrix a -> V.Value) -> S.StaticMatrix m n a -> SomeStaticMatrix
static :: SomeStaticMatrix -> V.Value
static payload@(SomeStaticMatrix wire _ _ value)=opaque "HMath.API.Shape.StaticMatrix" (wireCode wire)payload(mapM_(forceWire wire)(M.toList(S.dynamicMatrix value)))(V.unsupported "original abstract StaticMatrix has no public constructor fields")
asStatic :: V.Value -> IO SomeStaticMatrix
asStatic=unbox "HMath.API.Shape.StaticMatrix"
staticFrom :: forall a. Typeable a => Wire a -> Maybe(Dict(Num a)) -> (M.Matrix a -> V.Value) -> Integer -> Integer -> M.Matrix a -> IO V.Value
staticFrom wire numeric publish rows columns input=case(someNatVal rows,someNatVal columns) of
    (Just(SomeNat(_::Proxy m)),Just(SomeNat(_::Proxy n))) -> do
        result <- source(S.staticMatrix input::Either E.MathError(S.StaticMatrix m n a))
        pure(static(SomeStaticMatrix wire numeric publish result))
    _ -> V.invalid "type-level matrix dimensions must be nonnegative naturals"
staticMatrix :: Integer -> Integer -> V.Value -> IO V.Value
staticMatrix rows columns value=case value of
    V.Dense(V.SomeMatrix w input) -> staticFrom(coefficientWire w)(Just Dict)(V.Dense . V.SomeMatrix w)rows columns input
    _ -> withMatrix value $ \wire input -> staticFrom wire Nothing(matrix wire)rows columns input
dynamicMatrix :: V.Value -> IO V.Value
dynamicMatrix input=do SomeStaticMatrix _ _ publish value <- asStatic input;pure(publish(S.dynamicMatrix value))
staticTranspose :: V.Value -> IO V.Value
staticTranspose input=do SomeStaticMatrix wire numeric publish value <- asStatic input;pure(static(SomeStaticMatrix wire numeric publish(S.staticTranspose value)))
staticMultiply :: V.Value -> V.Value -> IO V.Value
staticMultiply leftValue rightValue=do
    SomeStaticMatrix wire numeric publish(left::S.StaticMatrix m k a) <- asStatic leftValue
    SomeStaticMatrix _ _ _(right::S.StaticMatrix l n b) <- asStatic rightValue
    case sameNat(Proxy::Proxy k)(Proxy::Proxy l) of
        Nothing -> V.invalid "staticMultiply requires matching nominal inner dimensions"
        Just Refl -> case cast right of
            Nothing -> V.invalid "staticMultiply element types differ"
            Just other -> case numeric of
                Nothing -> V.unsupported "original staticMultiply requires Num elements"
                Just Dict -> do
                    result <- source(S.staticMultiply left(other::S.StaticMatrix k n a))
                    pure(static(SomeStaticMatrix wire numeric publish result))

data ShapeWitness where
    ShapeWitness :: S.KnownShape(ds::[Nat]) => Proxy ds -> ShapeWitness
shapeWitness :: [Integer] -> IO ShapeWitness
shapeWitness []=pure(ShapeWitness(Proxy::Proxy('[]::[Nat])))
shapeWitness(n:ns)=case someNatVal n of
    Nothing -> V.invalid "type-level tensor dimensions must be nonnegative naturals"
    Just(SomeNat(_::Proxy n)) -> do
        ShapeWitness(_::Proxy ds) <- shapeWitness ns
        pure(ShapeWitness(Proxy::Proxy(n ': ds)))
reflectedShape :: [Integer] -> IO V.Value
reflectedShape dimensions=do ShapeWitness witness <- shapeWitness dimensions;pure(V.List(map(V.Scalar SInteger)(S.reflectedShape witness)))
data SomeStaticTensor where
    SomeStaticTensor :: (S.KnownShape ds,Typeable a,Eq a,Show a) => TC.Element a -> S.StaticTensor ds a -> SomeStaticTensor
staticTensorValue :: SomeStaticTensor -> V.Value
staticTensorValue payload@(SomeStaticTensor kind value)=opaque "HMath.API.Shape.StaticTensor" (TC.elementCode kind)payload(V.forceValue(TC.fromTensor kind(S.dynamicTensor value)))(V.unsupported "original abstract StaticTensor has no public constructor fields")
staticTensor :: [Integer] -> V.Value -> IO V.Value
staticTensor dimensions input=do
    ShapeWitness(_::Proxy ds) <- shapeWitness dimensions
    TC.SomeTensor(kind::TC.Element a) tensor <- TC.asTensor input
    result <- source(S.staticTensor tensor::Either E.MathError(S.StaticTensor ds a))
    pure(staticTensorValue(SomeStaticTensor kind result))
dynamicTensor :: V.Value -> IO V.Value
dynamicTensor input=do SomeStaticTensor kind value <- unbox "HMath.API.Shape.StaticTensor" input;pure(TC.fromTensor kind(S.dynamicTensor value))

data SomeCoordinates where
    SomeCoordinates :: (KnownNat n,Typeable a) => Wire a -> Maybe(ScalarType a) -> S.Coordinates n a -> SomeCoordinates
coordinatesValue :: SomeCoordinates -> V.Value
coordinatesValue payload@(SomeCoordinates wire _ value)=opaque "HMath.API.Shape.Coordinates" (wireCode wire)payload(mapM_(forceWire wire)(S.coordinateValues value))(V.unsupported "original abstract Coordinates has no public constructor fields")
coordinates :: forall a. Typeable a => Wire a -> Maybe(ScalarType a) -> Integer -> [a] -> IO V.Value
coordinates wire numeric count values=case someNatVal count of
    Nothing -> V.invalid "coordinate type-level length must be a nonnegative natural"
    Just(SomeNat(_::Proxy n)) -> do
        result <- source(S.coordinates values::Either E.MathError(S.Coordinates n a))
        pure(coordinatesValue(SomeCoordinates wire numeric result))
coordinatesFrom :: V.Value -> Integer -> [V.Value] -> IO V.Value
coordinatesFrom prototype count values=do
    TC.SomeElement kind <- algebraElement prototype
    let wire=Wire(pure . TC.scalar kind)(TC.asElement kind)(TC.forceElement kind)(TC.elementCode kind)
        numeric=case kind of TC.Numeric witness -> Just witness;_ -> Nothing
    xs <- mapM(TC.asElement kind)values
    coordinates wire numeric count xs
coordinateValues :: V.Value -> IO V.Value
coordinateValues input=do
    SomeCoordinates wire _ value <- unbox "HMath.API.Shape.Coordinates" input
    V.List <$> mapM(writeWire wire)(S.coordinateValues value)
coordinatesToVector :: V.Value -> IO V.Value
coordinatesToVector input=do
    SomeCoordinates wire numeric value <- unbox "HMath.API.Shape.Coordinates" input
    vector <- source(S.coordinatesToVector value)
    case numeric of
        Just w -> withCoefficient w $ LC.encodeVector w vector
        Nothing -> case wire of Wire write readValue force code -> pure(LC.encodeStructuralVector code write readValue force vector)
withCoefficient :: ScalarType a -> (Coefficient a => IO V.Value) -> IO V.Value
withCoefficient w action=case w of
    SDouble -> action;SFloat -> action;SInteger -> action;SRational -> action;SComplexDouble -> action;SComplexFloat -> action
    SInt8 -> action;SInt16 -> action;SInt32 -> action;SInt64 -> action;SWord8 -> action;SWord16 -> action;SWord32 -> action;SWord64 -> action;SInt -> action;SWord -> action
    SDual child -> withCoefficient child action
    SQuaternion _ -> action
