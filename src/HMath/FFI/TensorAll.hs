{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE GADTs #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Direct original Tensor and mutable tensor calls with explicit element witnesses.
module HMath.FFI.TensorAll where

import Control.Exception (bracket,throwIO)
import Data.Typeable (Typeable,cast)
import Data.Proxy (Proxy(..))
import Foreign hiding (shift)
import Foreign.C
import System.IO.Unsafe (unsafePerformIO)
import qualified HMath.Tensor as T
import qualified HMath.Tensor.Mutable as M
import HMath.Error (MathError)
import qualified HMath.FFI.Boundary as B
import HMath.FFI.Coefficient (ScalarType(SDouble,SInt))
import HMath.FFI.GraphCodec (Wire(..))
import HMath.FFI.MathError (CallbackFailure(..),withMathErrorWire,readCallbackFailure)
import HMath.FFI.TensorCodec
import qualified HMath.FFI.Value as V

source :: Either MathError a -> (a -> IO V.Value) -> IO V.Value
source (Left err) _ = throwIO (CallbackMathError err)
source (Right value) encode = encode value
plain :: Wire a => a -> IO V.Value
plain = pure . wire
checked :: Wire a => Either MathError a -> IO V.Value
checked value = source value plain
output :: (Typeable a,Eq a,Show a) => Element a -> Either MathError (T.Tensor a) -> IO V.Value
output witness value = source value (pure . fromTensor witness)
outputs :: (Typeable a,Eq a,Show a) => Element a -> Either MathError [T.Tensor a] -> IO V.Value
outputs witness value = source value (pure . V.List . map (fromTensor witness))
ints :: V.Value -> IO [Int]
ints value = V.asList value >>= mapM V.asIndex
values :: Element a -> V.Value -> IO [a]
values witness value = V.asList value >>= mapM (asElement witness)
structural :: (forall a. T.Tensor a -> Either MathError (T.Tensor a)) -> V.Value -> IO V.Value
structural function input = do SomeTensor witness tensor<-asTensor input; output witness (function tensor)
numericBinary :: (forall a. Num a => T.Tensor a -> T.Tensor a -> Either MathError (T.Tensor a)) -> V.Value -> V.Value -> IO V.Value
numericBinary function left right = do SomeTensor witness a<-asTensor left; b<-asTensorType right; withNum witness (output witness (function a b))
ordinal :: (forall a. Ord a => T.Tensor a -> Either MathError (T.Tensor a)) -> V.Value -> IO V.Value
ordinal function input = do SomeTensor witness tensor<-asTensor input; withOrd witness (output witness (function tensor))
logicalTensor :: V.Value -> IO (T.Tensor Bool)
logicalTensor = asTensorType
intTensor :: T.Tensor Int -> V.Value
intTensor = fromTensor (Numeric SInt)
boolTensor :: T.Tensor Bool -> V.Value
boolTensor = fromTensor Logical

-- Function pointers/userdata are borrowed until all deferred graph owners die.
data Function = Function Int (FunPtr ()) (Ptr ())
asFunction :: Int -> V.Value -> IO Function
asFunction expected (V.Opaque 273 _ _ _ payload) = case cast payload of
    Just result@(Function actual _ _) | actual==expected -> pure result
    _ -> V.invalid "tensor callback role differs"
asFunction _ _ = V.invalid "expected a tensor callback"
foreign import ccall safe "hm_tensor_invoke_callback"
    invokeCallback :: FunPtr () -> Ptr () -> StablePtr V.Value -> Ptr (StablePtr V.Value) -> Ptr () -> IO CInt
foreign import ccall safe "hm_tensor_invoke_buffer"
    invokeBuffer :: FunPtr () -> Ptr () -> Ptr () -> StablePtr V.Value -> Ptr (StablePtr V.Value) -> Ptr () -> IO CInt
{-# NOINLINE callback #-}
callback :: Function -> V.Value -> (V.Value -> IO a) -> a
callback (Function _ callbackPointer userdata) input decode = unsafePerformIO $
    bracket (newStablePtr input) freeStablePtr $ \pointer ->
    alloca $ \out -> withMathErrorWire $ \errorWire -> do
        status<-invokeCallback callbackPointer userdata pointer out errorWire
        if status/=0 then readCallbackFailure status errorWire >>= throwIO
        else do stable<-peek out; bracket (pure stable) freeStablePtr (\result -> deRefStablePtr result >>= decode)
scalar1 :: Element a -> Element b -> Function -> a -> b
scalar1 input outputType cb a = callback cb (V.Tuple [scalar input a]) (asElement outputType)
scalar2 :: Element a -> Element b -> Element c -> Function -> a -> b -> c
scalar2 left right outputType cb a b = callback cb (V.Tuple [scalar left a,scalar right b]) (asElement outputType)
foreign export ccall "hm_tensor_callback" createCallback :: CInt -> FunPtr () -> Ptr () -> Ptr (StablePtr V.Value) -> IO CInt
createCallback :: CInt -> FunPtr () -> Ptr () -> Ptr (StablePtr V.Value) -> IO CInt
createCallback role pointer userdata out = B.boundary $ B.checked (Right ()) $ \_ ->
    V.publish (V.Opaque 273 (-1) (fromIntegral role) (pure ()) (Function (fromIntegral role) pointer userdata)) out
foreign export ccall "hm_tensor_clone" clone :: StablePtr V.Value -> Ptr (StablePtr V.Value) -> IO CInt
clone :: StablePtr V.Value -> Ptr (StablePtr V.Value) -> IO CInt
clone input out = B.boundary $ deRefStablePtr input >>= \value -> B.checked (Right ()) (\_ -> V.publish value out)
foreign export ccall "hm_tensor_apply" apply :: CString -> Ptr (StablePtr V.Value) -> CSize -> Ptr (StablePtr V.Value) -> IO CInt
apply :: CString -> Ptr (StablePtr V.Value) -> CSize -> Ptr (StablePtr V.Value) -> IO CInt
apply namePointer inputs count out = B.boundary $ do
    name<-peekCString namePointer
    arguments<-peekArray (fromIntegral count) inputs >>= mapM deRefStablePtr
    result<-dispatch name arguments
    B.checked (Right ()) (\_ -> V.publish result out)

dispatch :: String -> [V.Value] -> IO V.Value
dispatch name arguments = case (name,arguments) of
    ("RowMajor",[]) -> plain (0::Int)
    ("ColumnMajor",[]) -> plain (1::Int)
    ("Strided",[]) -> plain (2::Int)
    ("CPU",[]) -> plain (0::Int)
    ("tensor",[kind,shape,xs]) -> do SomeElement witness<-element kind; dims<-ints shape; coefficients<-values witness xs; output witness (T.tensor dims coefficients)
    ("tensorColumnMajor",[kind,shape,xs]) -> do SomeElement witness<-element kind; dims<-ints shape; coefficients<-values witness xs; output witness (T.tensorColumnMajor dims coefficients)
    ("tensorFull",[shape,fill]) -> do SomeElement witness<-element fill; dims<-ints shape; value<-asElement witness fill; output witness (T.tensorFull dims value)
    ("tensorZeros",[kind,shape]) -> do SomeElement witness<-element kind; dims<-ints shape; withNum witness (output witness (T.tensorZeros dims))
    ("tensorOnes",[kind,shape]) -> do SomeElement witness<-element kind; dims<-ints shape; withNum witness (output witness (T.tensorOnes dims))
    ("tensorArange",[start,end,step]) -> do SomeElement witness<-element start; a<-asElement witness start; b<-asElement witness end; c<-asElement witness step; withRealFloat witness (output witness (T.tensorArange a b c))
    ("tensorLinspace",[start,end,count]) -> do SomeElement witness<-element start; a<-asElement witness start; b<-asElement witness end; n<-V.asIndex count; withFractional witness (output witness (T.tensorLinspace a b n))
    ("tensorLogspace",[base,start,end,count]) -> do SomeElement witness<-element base; a<-asElement witness base; b<-asElement witness start; c<-asElement witness end; n<-V.asIndex count; withFloating witness (output witness (T.tensorLogspace a b c n))
    ("tensorRandom",[seed,shape]) -> do state<-unwire seed; dims<-ints shape; source (T.tensorRandom state dims) (\(tensor,next) -> pure (V.Tuple [fromTensor (Numeric SDouble) tensor,wire next]))
    ("tensorValues",[input]) -> do SomeTensor witness tensor<-asTensor input; pure (V.List (map (scalar witness) (T.tensorValues tensor)))
    ("tensorShape",[input]) -> do SomeTensor _ tensor<-asTensor input; plain (T.tensorShape tensor)
    ("tensorStrides",[input]) -> do SomeTensor _ tensor<-asTensor input; plain (T.tensorStrides tensor)
    ("tensorOffset",[input]) -> do SomeTensor _ tensor<-asTensor input; plain (T.tensorOffset tensor)
    ("tensorDType",[input]) -> do SomeTensor _ tensor<-asTensor input; plain (T.tensorDType tensor)
    ("tensorDevice",[input]) -> do SomeTensor _ tensor<-asTensor input; case T.tensorDevice tensor of T.CPU -> plain (0::Int)
    ("tensorLayout",[input]) -> do SomeTensor _ tensor<-asTensor input; plain (case T.tensorLayout tensor of {T.RowMajor->0::Int;T.ColumnMajor->1;T.Strided->2})
    ("numel",[input]) -> do SomeTensor _ tensor<-asTensor input; plain (T.numel tensor)
    ("isContiguous",[input]) -> do SomeTensor _ tensor<-asTensor input; plain (T.isContiguous tensor)
    ("shapeSize",[shape]) -> ints shape >>= checked . T.shapeSize
    ("inferBroadcast",[left,right]) -> do a<-ints left;b<-ints right;checked(T.inferBroadcast a b)
    ("contiguous",[input]) -> structural T.contiguous input
    ("indexTensor",[input,index]) -> do SomeTensor witness tensor<-asTensor input; ix<-ints index;source (T.indexTensor tensor ix) (pure . scalar witness)
    ("sliceTensor",[axis,start,count,step,input]) -> do a<-V.asIndex axis;b<-V.asIndex start;c<-V.asIndex count;d<-V.asIndex step;structural (T.sliceTensor a b c d) input
    ("fancyIndex",[axis,indices,input]) -> do a<-V.asIndex axis;ix<-ints indices;structural (T.fancyIndex a ix) input
    ("gather",[axis,indices,input]) -> do a<-V.asIndex axis;ix<-ints indices;structural (T.gather a ix) input
    ("booleanIndex",[mask,input]) -> do booleans<-logicalTensor mask;structural (T.booleanIndex booleans) input
    ("scatter",[axis,indices,updates,target]) -> do a<-V.asIndex axis;ix<-ints indices;SomeTensor witness tensor<-asTensor updates;other<-asTensorType target;output witness(T.scatter a ix tensor other)
    ("scatterAdd",[axis,indices,updates,target]) -> do a<-V.asIndex axis;ix<-ints indices;SomeTensor witness tensor<-asTensor updates;other<-asTensorType target;withNum witness(output witness(T.scatterAdd a ix tensor other))
    ("reshapeTensor",[shape,input]) -> do dims<-ints shape;structural (T.reshapeTensor dims) input
    ("flattenTensor",[input]) -> structural T.flattenTensor input
    ("squeeze",[input]) -> structural T.squeeze input
    ("unsqueeze",[axis,input]) -> V.asIndex axis >>= \a -> structural (T.unsqueeze a) input
    ("expand",[shape,input]) -> ints shape >>= \dims -> structural (T.expand dims) input
    ("permute",[axes,input]) -> ints axes >>= \dims -> structural (T.permute dims) input
    ("transposeTensor",[input]) -> structural T.transposeTensor input
    ("moveAxis",[from,to,input]) -> do a<-V.asIndex from;b<-V.asIndex to;structural(T.moveAxis a b)input
    ("swapAxes",[from,to,input]) -> do a<-V.asIndex from;b<-V.asIndex to;structural(T.swapAxes a b)input
    ("broadcastTo",[shape,input]) -> ints shape >>= \dims -> structural(T.broadcastTo dims)input
    ("repeatTensor",[axis,count,input]) -> do a<-V.asIndex axis;b<-V.asIndex count;structural(T.repeatTensor a b)input
    ("tile",[counts,input]) -> ints counts >>= \dims -> structural(T.tile dims)input
    ("concatenate",[kind,axis,inputs]) -> do SomeElement witness<-element kind;a<-V.asIndex axis;ts<-V.asList inputs >>= mapM asTensorType;output witness(T.concatenate a ts)
    ("stack",[kind,axis,inputs]) -> do SomeElement witness<-element kind;a<-V.asIndex axis;ts<-V.asList inputs >>= mapM asTensorType;output witness(T.stack a ts)
    ("splitTensor",[axis,segments,input]) -> do a<-V.asIndex axis;sizes<-ints segments;SomeTensor witness tensor<-asTensor input;outputs witness(T.splitTensor a sizes tensor)
    ("chunkTensor",[axis,count,input]) -> do a<-V.asIndex axis;n<-V.asIndex count;SomeTensor witness tensor<-asTensor input;outputs witness(T.chunkTensor a n tensor)
    ("padTensor",[padding,fill,input]) -> do pads<-unwire padding;SomeTensor witness tensor<-asTensor input;value<-asElement witness fill;output witness(T.padTensor pads value tensor)
    ("roll",[axis,shift,input]) -> do a<-V.asIndex axis;b<-V.asIndex shift;structural(T.roll a b)input
    ("flipTensor",[axis,input]) -> V.asIndex axis >>= \a -> structural(T.flipTensor a)input
    ("rotate",[first,second,turns,input]) -> do a<-V.asIndex first;b<-V.asIndex second;c<-V.asIndex turns;structural(T.rotate a b c)input
    ("sortTensor",[input]) -> ordinal T.sortTensor input
    ("unique",[input]) -> ordinal T.unique input
    ("argsort",[input]) -> do SomeTensor witness tensor<-asTensor input;withOrd witness(source(T.argsort tensor)(pure.intTensor))
    ("topk",[count,input]) -> do n<-V.asIndex count;SomeTensor witness tensor<-asTensor input;withOrd witness(source(T.topk n tensor)(\(a,b)->pure(V.Tuple[fromTensor witness a,intTensor b])))
    ("nonzero",[input]) -> do SomeTensor witness tensor<-asTensor input;withNum witness(source(T.nonzero tensor)(pure.intTensor))
    ("whereTensor",[mask,left,right]) -> do booleans<-logicalTensor mask;SomeTensor witness a<-asTensor left;b<-asTensorType right;output witness(T.whereTensor booleans a b)
    ("maskedFill",[mask,fill,input]) -> do booleans<-logicalTensor mask;SomeTensor witness tensor<-asTensor input;value<-asElement witness fill;output witness(T.maskedFill booleans value tensor)
    ("maskedSelect",[mask,input]) -> do booleans<-logicalTensor mask;structural(T.maskedSelect booleans)input
    ("mapTensor",[kind,cb,input]) -> do SomeElement outKind<-element kind;handler<-asFunction 0 cb;SomeTensor inKind tensor<-asTensor input;pure(fromTensor outKind(T.mapTensor(scalar1 inKind outKind handler)tensor))
    ("zipTensor",[kind,cb,left,right]) -> do SomeElement outKind<-element kind;handler<-asFunction 0 cb;SomeTensor aKind a<-asTensor left;SomeTensor bKind b<-asTensor right;output outKind(T.zipTensor(scalar2 aKind bKind outKind handler)a b)
    ("tensorAdd",[a,b]) -> numericBinary T.tensorAdd a b
    ("tensorSubtract",[a,b]) -> numericBinary T.tensorSubtract a b
    ("tensorMultiply",[a,b]) -> numericBinary T.tensorMultiply a b
    ("tensorDivide",[a,b]) -> do SomeTensor witness x<-asTensor a;y<-asTensorType b;withFractional witness(output witness(T.tensorDivide x y))
    ("tensorEqual",[a,b]) -> do SomeTensor _ x<-asTensor a;y<-asTensorType b;source(T.tensorEqual x y)(pure.boolTensor)
    ("tensorLess",[a,b]) -> do SomeTensor witness x<-asTensor a;y<-asTensorType b;withOrd witness(source(T.tensorLess x y)(pure.boolTensor))
    ("tensorAnd",[a,b]) -> do x<-logicalTensor a;y<-logicalTensor b;source(T.tensorAnd x y)(pure.boolTensor)
    ("tensorOr",[a,b]) -> do x<-logicalTensor a;y<-logicalTensor b;source(T.tensorOr x y)(pure.boolTensor)
    ("tensorNot",[input]) -> logicalTensor input >>= pure . boolTensor . T.tensorNot
    ("promoteTensor",[kind,input]) -> do SomeElement target<-element kind;SomeTensor origin tensor<-asTensor input;withReal origin(withFractional target(pure(fromTensor target(T.promoteTensor tensor))))
    ("sumAxes",[axes,keep,input]) -> do dims<-ints axes;k<-V.asBoolean keep;SomeTensor witness tensor<-asTensor input;withNum witness(output witness(T.sumAxes dims k tensor))
    ("productAxes",[axes,keep,input]) -> do dims<-ints axes;k<-V.asBoolean keep;SomeTensor witness tensor<-asTensor input;withNum witness(output witness(T.productAxes dims k tensor))
    ("meanAxes",[axes,keep,input]) -> do dims<-ints axes;k<-V.asBoolean keep;SomeTensor witness tensor<-asTensor input;withFractional witness(output witness(T.meanAxes dims k tensor))
    ("varianceAxes",[axes,keep,input]) -> do dims<-ints axes;k<-V.asBoolean keep;SomeTensor witness tensor<-asTensor input;withFractional witness(output witness(T.varianceAxes dims k tensor))
    ("normAxes",[axes,keep,input]) -> do dims<-ints axes;k<-V.asBoolean keep;SomeTensor witness tensor<-asTensor input;withRealFloat witness(output witness(T.normAxes dims k tensor))
    ("minAxes",[axes,keep,input]) -> do dims<-ints axes;k<-V.asBoolean keep;SomeTensor witness tensor<-asTensor input;withOrd witness(output witness(T.minAxes dims k tensor))
    ("maxAxes",[axes,keep,input]) -> do dims<-ints axes;k<-V.asBoolean keep;SomeTensor witness tensor<-asTensor input;withOrd witness(output witness(T.maxAxes dims k tensor))
    ("argmin",[input]) -> do SomeTensor witness tensor<-asTensor input;withOrd witness(checked(T.argmin tensor))
    ("argmax",[input]) -> do SomeTensor witness tensor<-asTensor input;withOrd witness(checked(T.argmax tensor))
    ("cumulativeSum",[axis,input]) -> do a<-V.asIndex axis;SomeTensor witness tensor<-asTensor input;withNum witness(output witness(T.cumulativeSum a tensor))
    ("cumulativeProduct",[axis,input]) -> do a<-V.asIndex axis;SomeTensor witness tensor<-asTensor input;withNum witness(output witness(T.cumulativeProduct a tensor))
    ("tensordot",[leftAxes,rightAxes,left,right]) -> do a<-ints leftAxes;b<-ints rightAxes;SomeTensor witness x<-asTensor left;y<-asTensorType right;withNum witness(output witness(T.tensordot a b x y))
    ("einsum",[kind,labels,outputLabels,inputs]) -> do SomeElement witness<-element kind;names<-unwire labels;out<-V.asText outputLabels;ts<-V.asList inputs >>= mapM asTensorType;withNum witness(output witness(T.einsum names out ts))
    ("batchedMatmul",[a,b]) -> numericBinary T.batchedMatmul a b
    ("tensorKronecker",[a,b]) -> numericBinary T.tensorKronecker a b
    ("serializeTensor",[input]) -> do SomeTensor _ tensor<-asTensor input;plain(T.serializeTensor tensor)
    ("deserializeTensor",[kind,text]) -> do SomeElement witness<-element kind;input<-V.asText text;withRead witness(output witness(T.deserializeTensor input))
    ("inputGraph",[input]) -> do SomeTensor witness tensor<-asTensor input;pure(fromGraph witness(T.inputGraph tensor))
    ("mapGraph",[kind,cb,input]) -> do SomeElement outKind<-element kind;handler<-asFunction 0 cb;SomeGraph inKind graph<-asGraph input;pure(fromGraph outKind(T.mapGraph(scalar1 inKind outKind handler)graph))
    ("zipGraph",[kind,cb,left,right]) -> do SomeElement outKind<-element kind;handler<-asFunction 0 cb;SomeGraph aKind a<-asGraph left;SomeGraph bKind b<-asGraph right;source(T.zipGraph(scalar2 aKind bKind outKind handler)a b)(pure.fromGraph outKind)
    ("evaluateGraph",[input]) -> do SomeGraph witness graph<-asGraph input;output witness(T.evaluateGraph graph)
    ("newMutable",[shape,fill]) -> do SomeElement witness<-element fill;dims<-ints shape;value<-asElement witness fill;withStorable witness(M.newMutable dims value >>= \result -> source result(pure.fromMutable witness))
    ("thawTensor",[input]) -> do SomeTensor witness tensor<-asTensor input;withStorable witness(M.thawTensor tensor >>= \result -> source result(pure.fromMutable witness))
    ("freezeTensor",[input]) -> do SomeMutable witness tensor<-asMutable input;M.freezeTensor tensor >>= output witness
    ("mutableShape",[input]) -> do SomeMutable _ tensor<-asMutable input;plain(M.mutableShape tensor)
    ("readMutable",[input,index]) -> do SomeMutable witness tensor<-asMutable input;ix<-ints index;M.readMutable tensor ix >>= \result -> source result(pure.scalar witness)
    ("writeMutable",[input,index,fill]) -> do SomeMutable witness tensor<-asMutable input;ix<-ints index;value<-asElement witness fill;M.writeMutable tensor ix value >>= checked
    ("modifyMutable",[input,index,cb]) -> do SomeMutable witness tensor<-asMutable input;ix<-ints index;handler<-asFunction 0 cb;M.modifyMutable tensor ix(scalar1 witness witness handler) >>= checked
    ("sliceMutable",[axis,start,count,step,input]) -> do a<-V.asIndex axis;b<-V.asIndex start;c<-V.asIndex count;d<-V.asIndex step;SomeMutable witness tensor<-asMutable input;source(M.sliceMutable a b c d tensor)(pure.fromMutable witness)
    ("transposeMutable",[input]) -> do SomeMutable witness tensor<-asMutable input;pure(fromMutable witness(M.transposeMutable tensor))
    ("mutableAlignment",[kind]) -> do SomeElement (witness::Element a)<-element kind;withStorable witness(plain(M.mutableAlignment(Proxy::Proxy a)))
    ("withMutableBuffer",[input,cb]) -> do
        SomeMutable witness tensor<-asMutable input
        Function _ callbackPointer userdata<-asFunction 1 cb
        M.withMutableBuffer tensor $ \pointer shape strides -> do
            let metadata=V.Tuple[prototype witness,wire shape,wire strides,wire(sizeOfPtr pointer),wire(alignmentPtr pointer)]
            bracket(newStablePtr metadata)freeStablePtr $ \stable -> alloca $ \out -> withMathErrorWire $ \errorWire -> do
                status<-invokeBuffer callbackPointer userdata(castPtr pointer)stable out errorWire
                if status/=0 then readCallbackFailure status errorWire >>= throwIO
                else do result<-peek out;bracket(pure result)freeStablePtr deRefStablePtr
    ("__prototype",[input]) -> do SomeTensor witness _<-asTensor input;pure(prototype witness)
    ("__full_typed",[kind,shape,fill]) -> do SomeElement witness<-element kind;dims<-ints shape;value<-asElement witness fill;output witness(T.tensorFull dims value)
    ("__graph_prototype",[input]) -> do SomeGraph witness _<-asGraph input;pure(prototype witness)
    ("__mutable_prototype",[input]) -> do SomeMutable witness _<-asMutable input;pure(prototype witness)
    ("__equal",[left,right]) -> do SomeTensor _ a<-asTensor left;b<-asTensorType right;plain(a==b)
    _ -> V.invalid "invalid Tensor operation or argument count"

-- The pointer is used only to select the source Storable type, never read.
sizeOfPtr :: forall a. Storable a => Ptr a -> Int
sizeOfPtr _ = sizeOf(undefined::a)
alignmentPtr :: forall a. Storable a => Ptr a -> Int
alignmentPtr _ = alignment(undefined::a)
