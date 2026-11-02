{-# LANGUAGE GADTs #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Actual original algebra dictionaries and lossless foreign representations.
module HMath.FFI.AlgebraCodec where

import Control.Exception (evaluate)
import Data.Typeable (Typeable,cast)
import Data.Proxy (Proxy(..))
import qualified HMath.Algebra as A
import qualified HMath.API.Algebra as P
import qualified HMath.Polynomial as Poly
import qualified HMath.FFI.Polynomial as Polynomial
import qualified HMath.FFI.Value as V
import qualified HMath.Matrix as Matrix
import qualified HMath.Vector as Vector
import qualified HMath.Autodiff as AD
import qualified HMath.Error as E
import qualified HMath.FFI.Autodiff as ADWire
import qualified HMath.FFI.AutodiffValue as ADValue
import qualified HMath.FFI.LinearCodec as Linear
import qualified HMath.FFI.TensorCodec as Tensor
import HMath.FFI.Coefficient
import HMath.FFI.FoundationCodec

data Wire a=Wire (a -> IO V.Value) (V.Value -> IO a) (a -> IO ()) Int
writeWire :: Wire a -> a -> IO V.Value
writeWire(Wire write _ _ _)=write
readWire :: Wire a -> V.Value -> IO a
readWire(Wire _ readValue _ _)=readValue
forceWire :: Wire a -> a -> IO ()
forceWire(Wire _ _ force _)=force
wireCode :: Wire a -> Int
wireCode(Wire _ _ _ code)=code
coefficientWire :: Coefficient a => ScalarType a -> Wire a
coefficientWire w=Wire(pure . V.Scalar w)V.asScalar forceCoefficient(scalarTypeCode w)
polynomialWire :: Coefficient a => ScalarType a -> Wire(Poly.Polynomial a)
polynomialWire w=Wire(pure . Polynomial.poly w)Polynomial.asPolynomial(mapM_ forceCoefficient . Poly.coefficients)(scalarTypeCode w)
exactWire :: Wire P.Exact
exactWire=Wire(pure . exact)(unbox "HMath.API.Algebra.Exact")(forceCoefficient . P.getExact)18
exact :: P.Exact -> V.Value
exact value=opaqueEq "HMath.API.Algebra.Exact" 18 value(forceCoefficient(P.getExact value))(pure(V.Tuple[V.Text "Exact",V.Tuple[V.Scalar SRational(P.getExact value)]]))

data OldWire a where
    OldWire :: (Typeable a,Eq a,A.Ring a) => Wire a -> Maybe(Dict(A.Field a)) -> OldWire a
withOld :: V.Value -> (forall a. (Typeable a,Eq a,A.Ring a) => OldWire a -> IO V.Value) -> IO V.Value
withOld value action=case value of
    V.Scalar SInteger _ -> action(OldWire(coefficientWire SInteger)Nothing)
    V.Scalar SRational _ -> action(OldWire(coefficientWire SRational)(Just Dict))
    V.Opaque 6 _ _ _ _ -> Polynomial.withPolynomial value $ \w _ -> action(OldWire(polynomialWire w)Nothing)
    V.Opaque 400 _ _ _ _ -> do
        name <- objectName value
        if name=="HMath.Algebra.Additive" then do
            AdditiveBox wire _ <- unbox name value
            case wire of OldWire _ _ -> action wire
        else V.unsupported "original HMath.Algebra instances are Integer, Rational and Polynomial; Group uses Additive"
    _ -> V.unsupported "original HMath.Algebra instances are Integer, Rational and Polynomial"
oldWire :: OldWire a -> Wire a
oldWire(OldWire wire _)=wire
oldField :: OldWire a -> (A.Field a => IO V.Value) -> IO V.Value
oldField(OldWire _ (Just Dict)) action=action
oldField _ _=V.unsupported "original HMath.Algebra.Field instance is Rational"
withModule :: V.Value -> (forall a. (Typeable a,Eq a,A.Module a [a]) => Wire a -> IO V.Value) -> IO V.Value
withModule (V.Scalar SInteger _) action=action(coefficientWire SInteger)
withModule (V.Scalar SRational _) action=action(coefficientWire SRational)
withModule _ _=V.unsupported "original Module instances are Integer/Rational lists"
data AdditiveBox where
    AdditiveBox :: (Typeable a,Eq a,A.Ring a) => OldWire a -> A.Additive a -> AdditiveBox
instance Eq AdditiveBox where
    AdditiveBox _ left == AdditiveBox _ right=maybe False(left==)(cast right)
additive :: (Typeable a,Eq a,A.Ring a) => OldWire a -> A.Additive a -> V.Value
additive wire value=opaqueEq "HMath.Algebra.Additive" (wireCode(oldWire wire))(AdditiveBox wire value) force view
  where
    force=forceWire(oldWire wire)(A.getAdditive value)
    view=do x <- writeWire(oldWire wire)(A.getAdditive value);pure(V.Tuple[V.Text "Additive",V.Tuple[x]])
asAdditive :: forall a. Typeable a => V.Value -> IO(A.Additive a)
asAdditive value=do
    AdditiveBox _ payload <- unbox "HMath.Algebra.Additive" value
    maybe(V.invalid "Additive ring types differ")pure(cast payload)
asAdditiveWire :: Typeable a => Wire a -> V.Value -> IO(A.Additive a)
asAdditiveWire _=asAdditive

data APIWire a where
    APIWire :: (Typeable a,Eq a,P.Numeric a,P.Scalar a) => Wire a -> Maybe(Dict(P.Field a)) -> Maybe(Dict(P.FloatingPoint a)) -> APIWire a
withAPI :: V.Value -> (forall a. (Typeable a,Eq a,P.Numeric a,P.Scalar a) => APIWire a -> IO V.Value) -> IO V.Value
withAPI value action=case value of
    V.Scalar SInteger _ -> action(APIWire(coefficientWire SInteger)Nothing Nothing)
    V.Scalar SRational _ -> action(APIWire(coefficientWire SRational)(Just Dict)Nothing)
    V.Scalar SFloat _ -> action(APIWire(coefficientWire SFloat)(Just Dict)(Just Dict))
    V.Scalar SDouble _ -> action(APIWire(coefficientWire SDouble)(Just Dict)(Just Dict))
    V.Scalar SComplexDouble _ -> action(APIWire(coefficientWire SComplexDouble)(Just Dict)(Just Dict))
    V.Opaque 400 _ _ _ _ -> do
        name <- objectName value
        if name=="HMath.API.Algebra.Exact" then action(APIWire exactWire(Just Dict)Nothing)
        else V.unsupported "original API.Algebra instance required"
    _ -> V.unsupported "original API.Algebra instances are Integer/Rational/Float/Double/Complex Double/Exact"
apiWire :: APIWire a -> Wire a
apiWire(APIWire wire _ _)=wire
apiField :: APIWire a -> (P.Field a => IO V.Value) -> IO V.Value
apiField(APIWire _ (Just Dict) _) action=action
apiField _ _=V.unsupported "original API.Algebra.Field does not include Integer"
apiFloating :: APIWire a -> (P.FloatingPoint a => IO V.Value) -> IO V.Value
apiFloating(APIWire _ _ (Just Dict)) action=action
apiFloating _ _=V.unsupported "original FloatingPoint instances are Float,Double,Complex Double"

modular :: A.Modular -> V.Value
modular value=opaqueEq "HMath.Algebra.Modular" (-1)value(evaluate value >> pure())(V.unsupported "original abstract Modular has no public constructor fields")
finiteField :: A.FiniteField -> V.Value
finiteField value=opaqueEq "HMath.Algebra.FiniteField" (-1)value(evaluate value >> pure())(V.unsupported "original abstract FiniteField has no public constructor fields")
fieldElement :: A.FieldElement -> V.Value
fieldElement value=opaqueEq "HMath.Algebra.FieldElement" (-1)value(evaluate value >> pure())(V.unsupported "original abstract FieldElement has no public constructor fields")
asModular :: V.Value -> IO A.Modular
asModular=unbox "HMath.Algebra.Modular"
asFiniteField :: V.Value -> IO A.FiniteField
asFiniteField=unbox "HMath.Algebra.FiniteField"
asFieldElement :: V.Value -> IO A.FieldElement
asFieldElement=unbox "HMath.Algebra.FieldElement"

list :: (a -> IO V.Value) -> [a] -> IO V.Value
list write values=V.List <$> mapM write values
readList :: (V.Value -> IO a) -> V.Value -> IO[a]
readList readValue value=V.asList value >>= mapM readValue
pairs :: [(String,Bool)] -> IO V.Value
pairs values=pure(V.List[V.Tuple[V.Text name,V.Boolean result]|(name,result)<-values])
apiEpsilon :: forall a. P.FloatingPoint a => APIWire a -> Double
apiEpsilon _=P.machineEpsilon(Proxy::Proxy a)

matrix :: Typeable a => Wire a -> Matrix.Matrix a -> V.Value
matrix wire value=V.Dense(V.StructuralMatrix(wireCode wire)(writeWire wire)(readWire wire)(forceWire wire)value)
withMatrix :: V.Value -> (forall a. Typeable a => Wire a -> Matrix.Matrix a -> IO V.Value) -> IO V.Value
withMatrix (V.Dense(V.SomeMatrix w value)) action=action(coefficientWire w)value
withMatrix (V.Dense(V.StructuralMatrix code write readValue force value)) action=action(Wire write readValue force code)value
withMatrix _ _=V.invalid "expected Matrix"
matrixConstruct :: V.Value -> Int -> Int -> [V.Value] -> IO V.Value
matrixConstruct prototype rows columns values=case prototype of
    V.Scalar w _ -> V.Dense . V.SomeMatrix w <$> (mapM V.asScalar values >>= source . P.matrixConstruct rows columns)
    V.Boolean _ -> V.booleanMatrix <$> (mapM V.asBoolean values >>= source . P.matrixConstruct rows columns)
    V.Text _ -> V.stringMatrix <$> (mapM V.asText values >>= source . P.matrixConstruct rows columns)
    _ -> withAPI prototype $ \wire -> matrix(apiWire wire) <$> (mapM(readWire(apiWire wire))values >>= source . P.matrixConstruct rows columns)
tensorConstruct :: V.Value -> [Int] -> [V.Value] -> IO V.Value
tensorConstruct prototype dimensions values=do
    Tensor.SomeElement kind <- algebraElement prototype
    Tensor.fromTensor kind <$> (mapM(Tensor.asElement kind)values >>= source . P.tensorConstruct dimensions)
exactElement :: Tensor.Element P.Exact
exactElement=Tensor.Structural Tensor.StructuralCodec
    { Tensor.structuralCode=18
    , Tensor.structuralEncode=exact
    , Tensor.structuralDecode=unbox "HMath.API.Algebra.Exact"
    , Tensor.structuralForce=forceCoefficient . P.getExact
    , Tensor.structuralOrdering=Just Dict
    , Tensor.structuralRead=Nothing
    , Tensor.structuralStorable=Nothing
    }
algebraElement :: V.Value -> IO Tensor.SomeElement
algebraElement value@(V.Opaque 400 _ _ _ _)=do
    name <- objectName value
    if name=="HMath.API.Algebra.Exact" then pure(Tensor.SomeElement exactElement) else Tensor.element value
algebraElement value=Tensor.element value
tensorDimensions :: V.Value -> IO V.Value
tensorDimensions value=do Tensor.SomeTensor _ tensor <- Tensor.asTensor value;pure(V.List(map V.Index(P.tensorDimensions tensor)))
tensorElements :: V.Value -> IO V.Value
tensorElements value=do Tensor.SomeTensor kind tensor <- Tensor.asTensor value;pure(V.List(map(Tensor.scalar kind)(P.tensorElements tensor)))
differential :: V.Value -> IO V.Value
differential value=do
    ADWire.Tower original <- ADValue.asADTower value
    case ADWire.components original of
        Just(ADWire.Tower(_::a),_) -> case cast original of
            Just dual -> pure(ADValue.fromADTower(ADWire.Tower(P.differential(dual::AD.Dual a))))
            Nothing -> V.invalid "invalid original Dual witness"
        Nothing -> V.unsupported "original Differentiable instance requires Autodiff.Dual"
vectorPlus :: V.Value -> V.Value -> V.Value -> IO V.Value
vectorPlus prototype left right=Linear.withWitness prototype $ \(w::ScalarType a) -> case left of
    V.Dense _ -> do
        a <- V.asMatrix left;b <- V.asMatrix right
        V.Dense . V.SomeMatrix w <$> source(P.vectorPlus a b)
    _ -> do
        a <- Linear.unbox "HMath.Vector.Vector" left
        b <- Linear.unbox "HMath.Vector.Vector" right
        source(P.vectorPlus a b::Either E.MathError(Vector.Vector a)) >>= Linear.encodeVector w
vectorScale :: V.Value -> V.Value -> V.Value -> IO V.Value
vectorScale prototype scalar value=case value of
    V.Dense _ -> Linear.withWitness prototype $ \w -> do
        a <- V.asMatrix value; x <- V.asScalar scalar
        pure(V.Dense(V.SomeMatrix w(P.vectorScale x a)))
    _ -> Linear.withWitness prototype $ \(w::ScalarType a) -> do
        a <- Linear.unbox "HMath.Vector.Vector" value
        x <- V.asScalar scalar
        Linear.encodeVector w(P.vectorScale x (a::Vector.Vector a))
