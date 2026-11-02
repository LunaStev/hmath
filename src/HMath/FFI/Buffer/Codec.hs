{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Original containers with foreign scope and storage witnesses. No alternate
-- array implementation is used: every named operation delegates to API.Buffer.
module HMath.FFI.Buffer.Codec where
import Control.Concurrent.MVar
import Control.Exception (bracket_,evaluate,finally,throwIO)
import Control.Monad.ST.Unsafe (unsafeIOToST,unsafeSTToIO)
import Data.IORef
import Data.Typeable (Typeable)
import Foreign.Ptr (Ptr,ptrToWordPtr)
import Foreign.Storable (Storable,sizeOf,alignment,peekElemOff,pokeElemOff)
import System.IO.Unsafe (unsafePerformIO)
import qualified HMath.API.Buffer as B
import qualified HMath.Error as E
import qualified HMath.FFI.Value as V
import qualified HMath.FFI.FoundationCodec as F
import qualified HMath.FFI.LinearCodec as LC
import HMath.FFI.Coefficient
import HMath.FFI.MathError (CallbackFailure(..))

foreign import ccall unsafe "hm_buffer_thread_token" threadToken :: IO (Ptr ())

source :: Either E.MathError a -> IO a
source=F.source
boxed :: B.Boxed V.Value -> V.Value
boxed value=F.opaque "HMath.API.Buffer.Boxed" (-1) value (evaluate value >> pure()) (pure(V.List(B.boxedValues value)))
asBoxed :: V.Value -> IO(B.Boxed V.Value)
asBoxed=F.unbox "HMath.API.Buffer.Boxed"
unboxed :: B.UnboxedDouble -> V.Value
unboxed value=F.opaqueEq "HMath.API.Buffer.UnboxedDouble" 0 value (evaluate value >> pure()) (pure(V.List(map(V.Scalar SDouble)(B.unboxedValues value))))
asUnboxed :: V.Value -> IO B.UnboxedDouble
asUnboxed=F.unbox "HMath.API.Buffer.UnboxedDouble"

-- Scope guards are serialized and tied to the native caller thread. A retained
-- ST or borrowed-pointer owner can be released later, but cannot execute after
-- its callback or from another thread. Invalidation waits for in-flight access.
data Scope=Scope (Ptr ()) (MVar Bool)
newScope :: IO Scope
newScope=Scope <$> threadToken <*> newMVar True
withScope :: Scope -> IO a -> IO a
withScope(Scope owner active) action=withMVar active $ \alive -> do
    if not alive then V.invalid "buffer callback scope has ended" else pure()
    current <- threadToken
    if current/=owner then V.invalid "buffer callback scope belongs to another thread" else action
endScope :: Scope -> IO ()
endScope(Scope _ active)=modifyMVar_ active(const(pure False))
scopeActive :: Scope -> IO Bool
scopeActive(Scope _ active)=readMVar active

data STBox where
    STBox :: Scope -> B.STBuffer s V.Value -> STBox
stBox :: STBox -> V.Value
stBox value=F.opaque "HMath.API.Buffer.STBuffer" (-1) value (evaluate value >> pure()) (V.invalid "ST buffer has no immutable constructor fields")
asSTBox :: V.Value -> IO STBox
asSTBox=F.unbox "HMath.API.Buffer.STBuffer"
runBuffer :: B.Boxed V.Value -> V.Value -> IO V.Value
runBuffer input callback=do
    scope <- newScope
    let result=B.runSTBuffer input $ \buffer -> unsafeIOToST(LC.callbackValue callback(V.Tuple[stBox(STBox scope buffer)]))
    evaluate result `finally` endScope scope
thawST :: STBox -> B.Boxed V.Value -> IO V.Value
thawST(STBox scope _) input=withScope scope $ stBox . STBox scope <$> unsafeSTToIO(B.thawSTBuffer input)
freezeST :: STBox -> IO V.Value
freezeST(STBox scope buffer)=withScope scope $ boxed <$> unsafeSTToIO(B.freezeSTBuffer buffer)
readST :: STBox -> Int -> IO V.Value
readST(STBox scope buffer) index=withScope scope $ unsafeSTToIO(B.readSTBuffer buffer index) >>= source
writeST :: STBox -> Int -> V.Value -> IO V.Value
writeST(STBox scope buffer) index value=withScope scope $ do
    unsafeSTToIO(B.writeSTBuffer buffer index value) >>= source
    pure V.None
mapValue :: V.Value -> V.Value -> V.Value
mapValue callback value=unsafePerformIO(LC.callbackValue callback(V.Tuple[value]))
{-# NOINLINE mapValue #-}
mapStrict :: V.Value -> B.Boxed V.Value -> IO V.Value
mapStrict callback input=boxed <$> evaluate(B.mapStrict(mapValue callback) input)

-- Storable is exposed only for actual existing standard instances. Integer,
-- Rational, Numeric.Dual and Quaternion have no such instance and are rejected.
data Storage a=Storage Int (a -> V.Value) (V.Value -> IO a)
storableDict :: ScalarType a -> Maybe(Dict(Storable a))
storableDict witness=case witness of
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
    _ -> Nothing
withStorage :: V.Value -> (forall a. (Typeable a,Storable a) => Storage a -> IO r) -> IO r
withStorage prototype action=case prototype of
    V.Scalar witness _ -> case storableDict witness of
        Just Dict -> action(Storage(scalarTypeCode witness)(V.Scalar witness)V.asScalar)
        Nothing -> V.unsupported "coefficient has no original Storable instance"
    V.Index _ -> action(Storage 14 V.Index V.asIndex)
    V.Boolean _ -> action(Storage 16 V.Boolean readBool)
    V.Text [_] -> action(Storage 17 (\c -> V.Text[c]) readChar)
    _ -> V.unsupported "IO buffer requires a standard Storable numeric, Bool or Char prototype"
  where
    readBool(V.Boolean x)=pure x
    readBool _=V.invalid "Bool storage requires a Boolean"
    readChar(V.Text[c])=pure c
    readChar _=V.invalid "Char storage requires one Haskell character"

data IOBox where
    IOBox :: (Typeable a,Storable a) => Storage a -> B.IOBuffer a -> IORef(Maybe(Ptr())) -> IOBox
ioBox :: IOBox -> V.Value
ioBox value@(IOBox(Storage code _ _) _ _)=F.opaque "HMath.API.Buffer.IOBuffer" code value (evaluate value >> pure()) (V.invalid "mutable IO storage has no immutable constructor fields")
asIOBox :: V.Value -> IO IOBox
asIOBox=F.unbox "HMath.API.Buffer.IOBuffer"
newIO :: Int -> V.Value -> IO V.Value
newIO count initial=withStorage initial $ \store@(Storage _ _ readValue) -> do
    x <- readValue initial
    buffer <- B.newIOBuffer count x >>= source
    borrowed <- newIORef Nothing
    pure(ioBox(IOBox store buffer borrowed))
thawIO :: V.Value -> B.Boxed V.Value -> IO V.Value
thawIO prototype input=do
    let fields=B.boxedValues input
    selected <- case(prototype,fields)of
        (V.None,first:_) -> pure first
        (V.None,[]) -> V.invalid "empty IO storage needs an explicit element prototype"
        _ -> pure prototype
    withStorage selected $ \store@(Storage _ _ readValue) -> do
        values <- mapM readValue fields
        buffer <- B.thawIOBuffer(B.lazyBoxed values) >>= source
        borrowed <- newIORef Nothing
        pure(ioBox(IOBox store buffer borrowed))
guardReentry :: IORef(Maybe(Ptr())) -> IO a -> IO a
guardReentry borrowed action=do
    owner <- readIORef borrowed
    current <- threadToken
    if owner==Just current then throwIO(CallbackFailure 9 "cannot reenter locking operations on a borrowed IO buffer") else action
freezeIO :: IOBox -> IO V.Value
freezeIO(IOBox(Storage _ write _) buffer borrowed)=guardReentry borrowed $ do
    values <- B.freezeIOBuffer buffer
    pure(boxed(B.lazyBoxed(map write(B.boxedValues values))))
readIO :: IOBox -> Int -> IO V.Value
readIO(IOBox(Storage _ write _) buffer borrowed) index=guardReentry borrowed $ B.readIOBuffer buffer index >>= source >>= pure . write
writeIO :: IOBox -> Int -> V.Value -> IO V.Value
writeIO(IOBox(Storage _ _ readValue) buffer borrowed) index value=guardReentry borrowed $ do
    x <- readValue value
    B.writeIOBuffer buffer index x >>= source
    pure V.None
ioLength :: IOBox -> Int
ioLength(IOBox _ buffer _)=B.ioBufferLength buffer

data Borrowed where
    Borrowed :: (Typeable a,Storable a) => Scope -> Storage a -> Ptr a -> Int -> Borrowed
borrowedValue :: Borrowed -> V.Value
borrowedValue value@(Borrowed _ (Storage code _ _) _ _)=F.opaque "HMath.API.Buffer.BorrowedPointer" code value (evaluate value >> pure()) (V.invalid "borrowed pointer has no persistent fields")
asBorrowed :: V.Value -> IO Borrowed
asBorrowed=F.unbox "HMath.API.Buffer.BorrowedPointer"
withIO :: IOBox -> V.Value -> IO V.Value
withIO(IOBox store buffer borrowed) callback=guardReentry borrowed $ B.withIOBuffer buffer $ \pointer count -> do
    scope <- newScope
    owner <- threadToken
    bracket_(writeIORef borrowed(Just owner))(writeIORef borrowed Nothing) $
        LC.callbackValue callback(V.Tuple[borrowedValue(Borrowed scope store pointer count),V.Index count]) `finally` endScope scope
pointerRead :: Borrowed -> Int -> IO V.Value
pointerRead(Borrowed scope(Storage _ write _) pointer count) index=withScope scope $ do
    pointerIndex count index
    write <$> peekElemOff pointer index
pointerWrite :: Borrowed -> Int -> V.Value -> IO V.Value
pointerWrite(Borrowed scope(Storage _ _ readValue) pointer count) index value=withScope scope $ do
    pointerIndex count index
    x <- readValue value
    pokeElemOff pointer index x
    pure V.None
pointerIndex :: Int -> Int -> IO ()
pointerIndex count index=source(if index<0 || index>=count then Left(E.InvalidArgument "buffer index out of bounds") else Right())
pointerAddress :: Borrowed -> IO V.Value
pointerAddress(Borrowed scope _ pointer _)=withScope scope $ pure(V.Scalar SInteger(toInteger(ptrToWordPtr pointer)))
storageInfo :: IOBox -> V.Value
storageInfo(IOBox(Storage code _ _) (buffer::B.IOBuffer a) _)=V.Tuple[V.Index code,V.Index(sizeOf(undefined::a)),V.Index(alignment(undefined::a)),V.Index(B.ioBufferLength buffer)]
pointerInfo :: Borrowed -> IO V.Value
pointerInfo(Borrowed scope(Storage code _ _) (_::Ptr a) count)=withScope scope $ pure(V.Tuple[V.Index code,V.Index(sizeOf(undefined::a)),V.Index(alignment(undefined::a)),V.Index count])
