{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeSynonymInstances #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Concrete standard numeric witnesses. Dictionaries expose only instances
-- already implemented by the original Haskell types; no arithmetic lives here.
module HMath.FFI.Coefficient where

import Control.Exception (evaluate)
import Data.Complex (Complex, imagPart, realPart)
import Data.Int
import Data.Kind (Constraint)
import Data.Proxy (Proxy (..))
import Data.Ratio (denominator, numerator)
import Data.Typeable (Typeable)
import Data.Word
import qualified HMath.Numeric as N

data Dict (constraint :: Constraint) where
    Dict :: constraint => Dict constraint

data ScalarType a where
    SDouble :: ScalarType Double
    SFloat :: ScalarType Float
    SInteger :: ScalarType Integer
    SRational :: ScalarType Rational
    SComplexDouble :: ScalarType (Complex Double)
    SComplexFloat :: ScalarType (Complex Float)
    SInt8 :: ScalarType Int8
    SInt16 :: ScalarType Int16
    SInt32 :: ScalarType Int32
    SInt64 :: ScalarType Int64
    SWord8 :: ScalarType Word8
    SWord16 :: ScalarType Word16
    SWord32 :: ScalarType Word32
    SWord64 :: ScalarType Word64
    SInt :: ScalarType Int
    SWord :: ScalarType Word
    SDual :: ScalarType a -> ScalarType (N.Dual a)
    SQuaternion :: (Coefficient a, RealFloat a) => ScalarType a -> ScalarType (N.Quaternion a)

class (Typeable a, Eq a, Show a, Num a) => Coefficient a where
    scalarType :: ScalarType a
    fractionalDict :: proxy a -> Maybe (Dict (Fractional a))
    fractionalDict _ = Nothing
    floatingDict :: proxy a -> Maybe (Dict (Floating a))
    floatingDict _ = Nothing
    orderingDict :: proxy a -> Maybe (Dict (Ord a))
    orderingDict _ = Nothing
    realFloatDict :: proxy a -> Maybe (Dict (RealFloat a))
    realFloatDict _ = Nothing
    realFracDict :: proxy a -> Maybe (Dict (RealFrac a))
    realFracDict _ = Nothing
    realDict :: proxy a -> Maybe (Dict (Real a))
    realDict _ = Nothing
    integralDict :: proxy a -> Maybe (Dict (Integral a))
    integralDict _ = Nothing
    boundedDict :: proxy a -> Maybe (Dict (Bounded a))
    boundedDict _ = Nothing
    forceCoefficient :: a -> IO ()
    forceCoefficient value = evaluate value >> pure ()

instance Coefficient Double where
    scalarType = SDouble
    fractionalDict _ = Just Dict
    floatingDict _ = Just Dict
    orderingDict _ = Just Dict
    realFloatDict _ = Just Dict
    realFracDict _ = Just Dict
    realDict _ = Just Dict
instance Coefficient Float where
    scalarType = SFloat
    fractionalDict _ = Just Dict
    floatingDict _ = Just Dict
    orderingDict _ = Just Dict
    realFloatDict _ = Just Dict
    realFracDict _ = Just Dict
    realDict _ = Just Dict
instance Coefficient Integer where
    scalarType = SInteger
    orderingDict _ = Just Dict
    realDict _ = Just Dict
    integralDict _ = Just Dict
instance Coefficient Rational where
    scalarType = SRational
    fractionalDict _ = Just Dict
    orderingDict _ = Just Dict
    realFracDict _ = Just Dict
    realDict _ = Just Dict
    forceCoefficient value = evaluate (numerator value) >> evaluate (denominator value) >> pure ()
instance Coefficient (Complex Double) where
    scalarType = SComplexDouble
    fractionalDict _ = Just Dict
    floatingDict _ = Just Dict
    forceCoefficient value = evaluate (realPart value) >> evaluate (imagPart value) >> pure ()
instance Coefficient (Complex Float) where
    scalarType = SComplexFloat
    fractionalDict _ = Just Dict
    floatingDict _ = Just Dict
    forceCoefficient value = evaluate (realPart value) >> evaluate (imagPart value) >> pure ()

instance Coefficient Int8 where
    scalarType = SInt8
    orderingDict _ = Just Dict
    realDict _ = Just Dict
    integralDict _ = Just Dict
    boundedDict _ = Just Dict

instance Coefficient Int16 where
    scalarType = SInt16
    orderingDict _ = Just Dict
    realDict _ = Just Dict
    integralDict _ = Just Dict
    boundedDict _ = Just Dict

instance Coefficient Int32 where
    scalarType = SInt32
    orderingDict _ = Just Dict
    realDict _ = Just Dict
    integralDict _ = Just Dict
    boundedDict _ = Just Dict

instance Coefficient Int64 where
    scalarType = SInt64
    orderingDict _ = Just Dict
    realDict _ = Just Dict
    integralDict _ = Just Dict
    boundedDict _ = Just Dict

instance Coefficient Word8 where
    scalarType = SWord8
    orderingDict _ = Just Dict
    realDict _ = Just Dict
    integralDict _ = Just Dict
    boundedDict _ = Just Dict

instance Coefficient Word16 where
    scalarType = SWord16
    orderingDict _ = Just Dict
    realDict _ = Just Dict
    integralDict _ = Just Dict
    boundedDict _ = Just Dict

instance Coefficient Word32 where
    scalarType = SWord32
    orderingDict _ = Just Dict
    realDict _ = Just Dict
    integralDict _ = Just Dict
    boundedDict _ = Just Dict

instance Coefficient Word64 where
    scalarType = SWord64
    orderingDict _ = Just Dict
    realDict _ = Just Dict
    integralDict _ = Just Dict
    boundedDict _ = Just Dict

instance Coefficient Int where
    scalarType = SInt
    orderingDict _ = Just Dict
    realDict _ = Just Dict
    integralDict _ = Just Dict
    boundedDict _ = Just Dict

instance Coefficient Word where
    scalarType = SWord
    orderingDict _ = Just Dict
    realDict _ = Just Dict
    integralDict _ = Just Dict
    boundedDict _ = Just Dict

instance forall a. Coefficient a => Coefficient (N.Dual a) where
    scalarType = SDual (scalarType :: ScalarType a)
    fractionalDict _ = case fractionalDict (Proxy :: Proxy a) of
        Just Dict -> Just Dict
        Nothing -> Nothing
    floatingDict _ = case floatingDict (Proxy :: Proxy a) of
        Just Dict -> Just Dict
        Nothing -> Nothing
    forceCoefficient value = forceCoefficient (N.primal value) >> forceCoefficient (N.tangent value)

instance forall a. (Coefficient a, RealFloat a) => Coefficient (N.Quaternion a) where
    scalarType = SQuaternion (scalarType :: ScalarType a)
    forceCoefficient (N.Quaternion a b c d) =
        forceCoefficient a >> forceCoefficient b >> forceCoefficient c >> forceCoefficient d

data SomeCoefficient where
    SomeCoefficient :: Coefficient a => ScalarType a -> a -> SomeCoefficient

coefficientDict :: ScalarType a -> Dict (Coefficient a)
coefficientDict witness = case witness of
    SDouble -> Dict
    SFloat -> Dict
    SInteger -> Dict
    SRational -> Dict
    SComplexDouble -> Dict
    SComplexFloat -> Dict
    SInt8 -> Dict
    SInt16 -> Dict
    SInt32 -> Dict
    SInt64 -> Dict
    SWord8 -> Dict
    SWord16 -> Dict
    SWord32 -> Dict
    SWord64 -> Dict
    SInt -> Dict
    SWord -> Dict
    SDual child -> case coefficientDict child of Dict -> Dict
    SQuaternion _ -> Dict

scalarTypeCode :: ScalarType a -> Int
scalarTypeCode witness = case witness of
    SDouble -> 0
    SFloat -> 1
    SInteger -> 2
    SRational -> 3
    SComplexDouble -> 4
    SComplexFloat -> 5
    SInt8 -> 6
    SInt16 -> 7
    SInt32 -> 8
    SInt64 -> 9
    SWord8 -> 10
    SWord16 -> 11
    SWord32 -> 12
    SWord64 -> 13
    SInt -> 14
    SWord -> 15
    SDual _ -> 20
    SQuaternion _ -> 21
