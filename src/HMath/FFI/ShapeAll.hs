{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- Generated calls to original shape APIs and typed representation helpers.
module HMath.FFI.ShapeAll where
import Foreign
import Foreign.C
import qualified HMath.API.Shape as S
import qualified HMath.FFI.Value as V
import qualified HMath.FFI.Boundary as Boundary
import HMath.FFI.FoundationCodec(source,foundationBoundary)
import HMath.FFI.ShapeCodec hiding(shape,coordinates)
import qualified HMath.FFI.ShapeCodec as Codec
apply :: Int -> [V.Value] -> IO V.Value
apply operation args=case(operation,args)of
    (0,[shape]) -> asShape shape >>= pure . V.List . map V.Index . S.shapeDimensions
    (1,[shape]) -> asShape shape >>= pure . V.Index . S.shapeElements
    (2,[dimensions]) -> do {ds <- V.asList dimensions >>= mapM V.asIndex;Codec.shape <$> source(S.makeShape ds)}
    (3,[shape]) -> do {s <- asShape shape;pure(V.Boolean(case s of S.ScalarShape -> True;_ -> False))}
    (4,[shape]) -> do {s <- asShape shape;pure(case s of S.VectorShape n -> V.Index n;_ -> V.None)}
    (5,[shape]) -> do {s <- asShape shape;pure(case s of S.MatrixShape r c -> V.Tuple[V.Index r,V.Index c];_ -> V.None)}
    (6,[rows,columns,matrix]) -> do {r <- V.asScalar rows;c <- V.asScalar columns;staticMatrix r c matrix}
    (7,[matrix]) -> dynamicMatrix matrix
    (8,[left,right]) -> staticMultiply left right
    (9,[matrix]) -> staticTranspose matrix
    (10,[dimensions]) -> V.asList dimensions >>= mapM V.asScalar >>= reflectedShape
    (11,[dimensions,tensor]) -> do {ds <- V.asList dimensions >>= mapM V.asScalar;staticTensor ds tensor}
    (12,[tensor]) -> dynamicTensor tensor
    (13,[prototype,count,values]) -> do {n <- V.asScalar count;xs <- V.asList values;coordinatesFrom prototype n xs}
    (14,[coordinates]) -> coordinateValues coordinates
    (15,[coordinates]) -> coordinatesToVector coordinates
    _ -> V.invalid "invalid shape operation/arity"
foreign export ccall "hm_shape_apply" ffiApply :: CInt -> Ptr(StablePtr V.Value) -> CSize -> Ptr(StablePtr V.Value) -> IO CInt
ffiApply :: CInt -> Ptr(StablePtr V.Value) -> CSize -> Ptr(StablePtr V.Value) -> IO CInt
ffiApply operation input count out=foundationBoundary $ do
    values <- peekArray(fromIntegral count) input >>= mapM deRefStablePtr
    value <- apply(fromIntegral operation) values
    Boundary.checked(Right())(const(V.publish value out))
