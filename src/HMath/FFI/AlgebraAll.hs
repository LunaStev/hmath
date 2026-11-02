{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE ScopedTypeVariables #-}
-- SPDX-License-Identifier: MPL-2.0
-- Generated direct calls into the two distinct original algebra interfaces.
module HMath.FFI.AlgebraAll where
import Prelude hiding(readList)
import Foreign
import Foreign.C
import qualified HMath.Algebra as A
import qualified HMath.API.Algebra as P
import qualified HMath.FFI.Value as V
import qualified HMath.FFI.Boundary as Boundary
import HMath.FFI.Coefficient
import HMath.FFI.FoundationCodec
import HMath.FFI.AlgebraCodec
import qualified HMath.FFI.TensorCodec as TensorCodec
apply :: Int -> [V.Value] -> IO V.Value
apply operation args=case(operation,args) of
    (0,[prototype,a0,a1]) -> withModule prototype $ \wire -> do
            zeroVector <- readList(readWire wire)a0;terms <- readList(\v -> V.asTuple 2 v >>= \parts -> case parts of {[s,x] -> (,) <$>readWire wire s <*>readList(readWire wire)x;_ -> V.invalid "module term arity differs"})a1;source(A.linearCombination zeroVector terms) >>= list(writeWire wire)
    (1,[prototype,a0]) -> withOld prototype $ \domain -> do
            let wire=oldWire domain
            x0 <- readList(\x -> readWire wire x) a0
            list(\x -> (\(field1,field2) -> V.Tuple <$> sequence [pure(V.Text field1),pure(V.Boolean field2)]) x) (A.semiringLaws x0)
    (2,[prototype,a0]) -> withOld prototype $ \domain -> do
            let wire=oldWire domain
            x0 <- readList(\x -> readWire wire x) a0
            list(\x -> (\(field3,field4) -> V.Tuple <$> sequence [pure(V.Text field3),pure(V.Boolean field4)]) x) (A.ringLaws x0)
    (3,[prototype,a0]) -> withOld prototype $ \domain -> do
            let wire=oldWire domain
            x0 <- readList(\x -> readWire wire x) a0
            oldField domain $ list(\x -> (\(field5,field6) -> V.Tuple <$> sequence [pure(V.Text field5),pure(V.Boolean field6)]) x) (A.fieldLaws x0)
    (4,[prototype,a0]) -> withOld prototype $ \domain -> do
            let wire=oldWire domain
            x0 <- readList(\x -> asAdditiveWire wire x) a0
            pairs(A.groupLaws x0)
    (5,[prototype,a0,a1]) -> withModule prototype $ \wire -> do
            xs <- readList(readWire wire)a0;ys <- readList(readList(readWire wire))a1;pairs(A.moduleLaws xs ys)
    (6,[a0,a1]) -> do
            x0 <- V.asScalar a0
            x1 <- V.asScalar a1
            source (A.modular x0 x1) >>= \result -> pure(modular result)
    (7,[a0]) -> do
            x0 <- asModular a0
            pure(V.Scalar SInteger (A.modularValue x0))
    (8,[a0]) -> do
            x0 <- asModular a0
            pure(V.Scalar SInteger (A.modularModulus x0))
    (9,[a0,a1]) -> do
            x0 <- asModular a0
            x1 <- asModular a1
            source (A.addModular x0 x1) >>= \result -> pure(modular result)
    (10,[a0,a1]) -> do
            x0 <- asModular a0
            x1 <- asModular a1
            source (A.subtractModular x0 x1) >>= \result -> pure(modular result)
    (11,[a0,a1]) -> do
            x0 <- asModular a0
            x1 <- asModular a1
            source (A.multiplyModular x0 x1) >>= \result -> pure(modular result)
    (12,[a0]) -> do
            x0 <- asModular a0
            source (A.inverseModular x0) >>= \result -> pure(modular result)
    (13,[a0,a1]) -> do
            x0 <- asModular a0
            x1 <- V.asScalar a1
            source (A.powerModular x0 x1) >>= \result -> pure(modular result)
    (14,[a0,a1,a2]) -> do
            x0 <- V.asIndex a0
            x1 <- V.asScalar a1
            x2 <- readList(\x -> V.asScalar x) a2
            source (A.finiteField x0 x1 x2) >>= \result -> pure(finiteField result)
    (15,[a0,a1]) -> do
            x0 <- V.asIndex a0
            x1 <- V.asScalar a1
            source (A.primeField x0 x1) >>= \result -> pure(finiteField result)
    (16,[a0]) -> do
            x0 <- asFiniteField a0
            pure(V.Scalar SInteger (A.fieldCharacteristic x0))
    (17,[a0]) -> do
            x0 <- asFiniteField a0
            pure(V.Index (A.fieldDegree x0))
    (18,[a0]) -> do
            x0 <- asFiniteField a0
            pure(V.Scalar SInteger (A.fieldCardinality x0))
    (19,[a0]) -> do
            x0 <- asFiniteField a0
            list(\x -> pure(V.Scalar SInteger x)) (A.fieldModulus x0)
    (20,[a0,a1]) -> do
            x0 <- asFiniteField a0
            x1 <- readList(\x -> V.asScalar x) a1
            pure(fieldElement (A.fieldElement x0 x1))
    (21,[a0]) -> do
            x0 <- asFieldElement a0
            list(\x -> pure(V.Scalar SInteger x)) (A.fieldElementCoefficients x0)
    (22,[a0,a1]) -> do
            x0 <- V.asIndex a0
            x1 <- asFiniteField a1
            source (A.fieldElements x0 x1) >>= \result -> list(\x -> pure(fieldElement x)) result
    (23,[a0,a1]) -> do
            x0 <- asFieldElement a0
            x1 <- asFieldElement a1
            source (A.addField x0 x1) >>= \result -> pure(fieldElement result)
    (24,[a0]) -> do
            x0 <- asFieldElement a0
            pure(fieldElement (A.negateField x0))
    (25,[a0,a1]) -> do
            x0 <- asFieldElement a0
            x1 <- asFieldElement a1
            source (A.subtractField x0 x1) >>= \result -> pure(fieldElement result)
    (26,[a0,a1]) -> do
            x0 <- asFieldElement a0
            x1 <- asFieldElement a1
            source (A.multiplyField x0 x1) >>= \result -> pure(fieldElement result)
    (27,[a0]) -> do
            x0 <- asFieldElement a0
            source (A.inverseFieldElement x0) >>= \result -> pure(fieldElement result)
    (28,[a0,a1]) -> do
            x0 <- asFieldElement a0
            x1 <- V.asScalar a1
            source (A.powerField x0 x1) >>= \result -> pure(fieldElement result)
    (29,[a0,a1]) -> do
            x0 <- V.asIndex a0
            x1 <- asFiniteField a1
            source (A.finiteFieldLaws x0 x1) >>= \result -> list(\x -> (\(field9,field10) -> V.Tuple <$> sequence [pure(V.Text field9),pure(V.Boolean field10)]) x) result
    (30,[prototype,a0]) -> withOld prototype $ \domain -> do
            let wire=oldWire domain
            x0 <- asAdditiveWire wire a0
            writeWire wire (A.getAdditive x0)
    (31,[prototype,a0]) -> withOld prototype $ \domain -> do
            let wire=oldWire domain
            x0 <- readWire wire a0
            pure(additive domain (A.Additive x0))
    (32,[prototype,a0,a1]) -> withAPI prototype $ \domain -> do
            let wire=apiWire domain
            x0 <- readList(\x -> readWire wire x) a0
            x1 <- readWire wire a1
            writeWire wire (P.horner x0 x1)
    (33,[prototype,a0,a1]) -> withAPI prototype $ \domain -> do
            let wire=apiWire domain
            x0 <- readList(\x -> readWire wire x) a0
            x1 <- readList(\x -> readWire wire x) a1
            source (P.innerProduct x0 x1) >>= \result -> writeWire wire result
    (34,[a0]) -> do
            x0 <- unbox "HMath.API.Algebra.Exact" a0
            pure(V.Scalar SRational (P.getExact x0))
    (35,[a0]) -> do
            x0 <- V.asScalar a0
            pure(exact (P.Exact x0))
    (36,[prototype]) -> withOld prototype $ \domain -> do
            let wire=oldWire domain
            writeWire wire (A.zero)
    (37,[prototype]) -> withOld prototype $ \domain -> do
            let wire=oldWire domain
            writeWire wire (A.one)
    (38,[prototype,a0,a1]) -> withOld prototype $ \domain -> do
            let wire=oldWire domain
            x0 <- readWire wire a0
            x1 <- readWire wire a1
            writeWire wire (A.plus x0 x1)
    (39,[prototype,a0,a1]) -> withOld prototype $ \domain -> do
            let wire=oldWire domain
            x0 <- readWire wire a0
            x1 <- readWire wire a1
            writeWire wire (A.times x0 x1)
    (40,[prototype,a0]) -> withOld prototype $ \domain -> do
            let wire=oldWire domain
            x0 <- readWire wire a0
            writeWire wire (A.negateRing x0)
    (41,[prototype,a0]) -> withOld prototype $ \domain -> do
            let wire=oldWire domain
            x0 <- readWire wire a0
            oldField domain $ source (A.inverseField x0) >>= \result -> writeWire wire result
    (42,[prototype]) -> withOld prototype $ \domain -> do
            pure(additive domain A.groupIdentity)
    (43,[prototype,a0,a1]) -> withOld prototype $ \domain -> do
            let wire=oldWire domain
            x0 <- asAdditiveWire wire a0
            x1 <- asAdditiveWire wire a1
            pure(additive domain (A.groupCombine x0 x1))
    (44,[prototype,a0]) -> withOld prototype $ \domain -> do
            let wire=oldWire domain
            x0 <- asAdditiveWire wire a0
            pure(additive domain (A.groupInverse x0))
    (45,[prototype,a0,a1]) -> withModule prototype $ \wire -> do
            x <- readWire wire a0;xs <- readList(readWire wire)a1;list(writeWire wire)(A.moduleScale x xs)
    (46,[prototype,a0,a1]) -> withModule prototype $ \wire -> do
            xs <- readList(readWire wire)a0;ys <- readList(readWire wire)a1;source(A.moduleAdd xs ys) >>= list(writeWire wire)
    (47,[prototype]) -> withAPI prototype $ \domain -> do
            let wire=apiWire domain
            writeWire wire (P.zero)
    (48,[prototype]) -> withAPI prototype $ \domain -> do
            let wire=apiWire domain
            writeWire wire (P.one)
    (49,[prototype,a0,a1]) -> withAPI prototype $ \domain -> do
            let wire=apiWire domain
            x0 <- readWire wire a0
            x1 <- readWire wire a1
            writeWire wire (P.plus x0 x1)
    (50,[prototype,a0,a1]) -> withAPI prototype $ \domain -> do
            let wire=apiWire domain
            x0 <- readWire wire a0
            x1 <- readWire wire a1
            writeWire wire (P.times x0 x1)
    (51,[prototype,a0]) -> withAPI prototype $ \domain -> do
            let wire=apiWire domain
            x0 <- readWire wire a0
            writeWire wire (P.negative x0)
    (52,[prototype,a0]) -> withAPI prototype $ \domain -> do
            let wire=apiWire domain
            x0 <- V.asScalar a0
            writeWire wire (P.integer x0)
    (53,[prototype,a0]) -> withAPI prototype $ \domain -> do
            let wire=apiWire domain
            x0 <- readWire wire a0
            apiField domain $ source (P.invert x0) >>= \result -> writeWire wire result
    (54,[prototype,a0]) -> withAPI prototype $ \domain -> do
            let wire=apiWire domain
            x0 <- readWire wire a0
            writeWire wire (P.conjugateScalar x0)
    (55,[prototype]) -> withAPI prototype $ \domain -> do
            apiFloating domain $ pure(V.Scalar SDouble (apiEpsilon domain))
    (56,[prototype,a0]) -> withAPI prototype $ \domain -> do
            let wire=apiWire domain
            x0 <- readWire wire a0
            apiFloating domain $ pure(V.Boolean (P.finiteScalar x0))
    (57,[prototype,a0]) -> withAPI prototype $ \domain -> do
            let wire=apiWire domain
            x0 <- V.asScalar a0
            source (P.rational x0) >>= \result -> writeWire wire result
    (58,[a0]) -> withMatrix a0 $ \_ matrixValue -> pure(\(r,c) -> V.Tuple[V.Index r,V.Index c]) <*> pure(P.matrixDimensions matrixValue)
    (59,[a0]) -> withMatrix a0 $ \wire matrixValue -> list(writeWire wire)(P.matrixElements matrixValue)
    (60,[prototype,a0,a1,a2]) -> do {r <- V.asIndex a0;c <- V.asIndex a1;xs <- V.asList a2;matrixConstruct prototype r c xs}
    (61,[a0]) -> tensorDimensions a0
    (62,[a0]) -> tensorElements a0
    (63,[prototype,a0,a1]) -> do {ds <- V.asList a0 >>= mapM V.asIndex;xs <- V.asList a1;tensorConstruct prototype ds xs}
    (64,[prototype,a0,a1]) -> vectorPlus prototype a0 a1
    (65,[prototype,a0,a1]) -> vectorScale prototype a0 a1
    (66,[a0]) -> differential a0
    (-1,[]) -> pure(TensorCodec.prototype exactElement)
    _ -> V.invalid "invalid algebra operation/arity"
foreign export ccall "hm_algebra_apply" ffiApply :: CInt -> Ptr(StablePtr V.Value) -> CSize -> Ptr(StablePtr V.Value) -> IO CInt
ffiApply :: CInt -> Ptr(StablePtr V.Value) -> CSize -> Ptr(StablePtr V.Value) -> IO CInt
ffiApply operation input count out=foundationBoundary $ do
    values <- peekArray(fromIntegral count) input >>= mapM deRefStablePtr
    value <- apply(fromIntegral operation) values
    Boundary.checked(Right())(const(V.publish value out))
