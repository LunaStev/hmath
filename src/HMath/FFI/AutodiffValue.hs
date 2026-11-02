{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE ScopedTypeVariables #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Lossless interoperability with the existing Autodiff handles and sum type.
module HMath.FFI.AutodiffValue where

import Control.Exception (bracketOnError,evaluate)
import Data.Typeable (Typeable,cast)
import Foreign
import Foreign.C
import qualified HMath.Autodiff as A
import qualified HMath.FFI.Autodiff as D
import qualified HMath.FFI.Boundary as B
import HMath.FFI.Coefficient (SomeCoefficient(..))
import qualified HMath.FFI.Value as V

fromADExpr :: A.Expr -> V.Value
fromADExpr value = V.Opaque 287 0 0 (evaluate value >> pure ()) value
asADExpr :: V.Value -> IO A.Expr
asADExpr (V.Opaque 287 _ _ _ payload) = maybe (V.invalid "invalid original AD Expr payload") pure (cast payload)
asADExpr _ = V.invalid "expected original AD Expr"
fromADTensor :: A.ADTensor -> V.Value
fromADTensor value = V.Opaque 288 0 (length(A.adValues value)) (evaluate value >> pure ()) value
asADTensor :: V.Value -> IO A.ADTensor
asADTensor (V.Opaque 288 _ _ _ payload) = maybe (V.invalid "invalid original ADTensor payload") pure (cast payload)
asADTensor _ = V.invalid "expected original ADTensor"

-- Coefficient leaves remain ordinary exact typed scalars; each actual A.Dual
-- tower remains separate from HMath.Numeric.Dual's Coefficient representation.
fromADTower :: D.Tower -> V.Value
fromADTower tower@(D.Tower value) = case D.coefficientLeaf value of
    Just (SomeCoefficient witness number) -> V.Scalar witness number
    Nothing -> V.Opaque 289 (-1) (D.depth value) (evaluate value >> pure ()) tower
asADTower :: V.Value -> IO D.Tower
asADTower (V.Opaque 289 _ _ _ payload) = maybe (V.invalid "invalid original Autodiff Dual tower") pure (cast payload)
asADTower (V.Scalar _ value) = pure(D.Tower value)
asADTower _ = V.invalid "expected original Autodiff Dual or coefficient scalar leaf"
adDual :: D.TowerValue a => A.Dual a -> V.Value
adDual = fromADTower . D.Tower
asADDual :: forall a. Typeable a => V.Value -> IO(A.Dual a)
asADDual input = do
    D.Tower value <- asADTower input
    maybe (V.invalid "original Autodiff Dual component types differ") pure (cast value)

foreign export ccall "hm_ad_value_import" importValue :: StablePtr D.Value -> Ptr(StablePtr V.Value) -> IO CInt
importValue :: StablePtr D.Value -> Ptr(StablePtr V.Value) -> IO CInt
importValue input out = B.boundary $ do
    value<-deRefStablePtr input
    result<-case value of
        D.Expression expression -> pure(fromADExpr expression)
        D.Tensor tensor -> pure(fromADTensor tensor)
        D.Dual tower -> pure(fromADTower tower)
        _ -> V.invalid "AD Value interchange supports expressions, symbolic tensors and original Duals"
    B.checked(Right())(\_ -> V.publish result out)
foreign export ccall "hm_ad_value_export" exportValue :: StablePtr V.Value -> Ptr(StablePtr D.Value) -> Ptr CInt -> IO CInt
exportValue :: StablePtr V.Value -> Ptr(StablePtr D.Value) -> Ptr CInt -> IO CInt
exportValue input out kindOut = B.boundary $ do
    value<-deRefStablePtr input
    (kind,result)<-case value of
        V.Opaque 287 _ _ _ _ -> do expression<-asADExpr value;pure(0,D.Expression expression)
        V.Opaque 288 _ _ _ _ -> do tensor<-asADTensor value;pure(3,D.Tensor tensor)
        _ -> do tower<-asADTower value;pure(4,D.Dual tower)
    B.checked(Right()) $ \_ -> bracketOnError(newStablePtr result)freeStablePtr(\pointer -> poke kindOut kind >> poke out pointer)
