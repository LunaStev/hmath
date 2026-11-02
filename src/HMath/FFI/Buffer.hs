{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Named Buffer calls and checked scope/borrow representation helpers.
module HMath.FFI.Buffer where
import Foreign
import Foreign.C
import qualified HMath.API.Buffer as B
import qualified HMath.FFI.Buffer.Codec as C
import qualified HMath.FFI.FoundationCodec as F
import qualified HMath.FFI.Value as V
import HMath.FFI.Coefficient (ScalarType(SDouble))
foreign export ccall "hm_buffer_apply" apply :: CInt -> Ptr(StablePtr V.Value) -> CSize -> Ptr(StablePtr V.Value) -> IO CInt
apply :: CInt -> Ptr(StablePtr V.Value) -> CSize -> Ptr(StablePtr V.Value) -> IO CInt
apply operation input arity out=F.foundationBoundary $ do
    values <- peekArray(fromIntegral arity) input >>= mapM deRefStablePtr
    result <- case(operation,values)of
        (0,[xs]) -> C.boxed . B.lazyBoxed <$> V.asList xs
        (1,[xs]) -> C.boxed . B.strictBoxed <$> V.asList xs
        (2,[value]) -> V.List . B.boxedValues <$> C.asBoxed value
        (3,[value]) -> V.Index . B.boxedLength <$> C.asBoxed value
        (4,[callback,value]) -> C.asBoxed value >>= C.mapStrict callback
        (5,[xs]) -> V.asList xs >>= mapM V.asScalar >>= pure . C.unboxed . B.unboxedDouble
        (6,[value]) -> V.List . map(V.Scalar SDouble) . B.unboxedValues <$> C.asUnboxed value
        (7,[value,callback]) -> C.asBoxed value >>= \inputBox -> C.runBuffer inputBox callback
        (8,[region,value]) -> do scope <- C.asSTBox region;inputBox <- C.asBoxed value;C.thawST scope inputBox
        (9,[value]) -> C.asSTBox value >>= C.freezeST
        (10,[value,index]) -> do buffer <- C.asSTBox value;i <- V.asIndex index;C.readST buffer i
        (11,[value,index,element]) -> do buffer <- C.asSTBox value;i <- V.asIndex index;C.writeST buffer i element
        (12,[count,value]) -> V.asIndex count >>= \n -> C.newIO n value
        (13,[prototype,value]) -> C.asBoxed value >>= C.thawIO prototype
        (14,[value]) -> C.asIOBox value >>= C.freezeIO
        (15,[value]) -> V.Index . C.ioLength <$> C.asIOBox value
        (16,[value,index]) -> do buffer <- C.asIOBox value;i <- V.asIndex index;C.readIO buffer i
        (17,[value,index,element]) -> do buffer <- C.asIOBox value;i <- V.asIndex index;C.writeIO buffer i element
        (18,[value,callback]) -> C.asIOBox value >>= \buffer -> C.withIO buffer callback
        (19,[value]) -> do raw <- C.asUnboxed value;pure(C.boxed(fmap(V.Scalar SDouble)(B.unboxedToBoxed raw)))
        (20,[value]) -> do raw <- C.asBoxed value;xs <- mapM V.asScalar(B.boxedValues raw);pure(C.unboxed(B.boxedToUnboxed(B.lazyBoxed xs)))
        (21,[value]) -> C.storageInfo <$> C.asIOBox value
        (22,[value]) -> C.asBorrowed value >>= C.pointerInfo
        (23,[value,index]) -> do pointer <- C.asBorrowed value;i <- V.asIndex index;C.pointerRead pointer i
        (24,[value,index,element]) -> do pointer <- C.asBorrowed value;i <- V.asIndex index;C.pointerWrite pointer i element
        (25,[value]) -> C.asBorrowed value >>= C.pointerAddress
        (26,[value]) -> do C.STBox scope _ <- C.asSTBox value;V.Boolean <$> C.scopeActive scope
        (27,[value]) -> do C.Borrowed scope _ _ _ <- C.asBorrowed value;V.Boolean <$> C.scopeActive scope
        _ -> V.invalid "Buffer adapter argument shape differs"
    V.publish result out
    pure 0
