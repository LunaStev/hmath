{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE UndecidableInstances #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Typed transport for the original interchange APIs and scoped IO callbacks.
module HMath.FFI.InterchangeCodec where

import Control.Exception (bracket,catch,evaluate,throwIO)
import Data.Binary.Get (Get)
import Data.Binary.Put (Put)
import qualified Data.ByteString as BS
import Data.Typeable (Typeable,cast)
import Foreign
import Foreign.C
import System.IO (Handle)
import System.IO.Unsafe (unsafePerformIO)
import HMath.FFI.Coefficient (ScalarType(SWord32))
import HMath.FFI.MathError (withMathErrorWire,readCallbackFailure)
import qualified HMath.FFI.Bytes as Bytes
import qualified HMath.FFI.InterchangeError as Error
import qualified HMath.FFI.LinearCodec as L
import qualified HMath.FFI.NumericalCodec as N
import qualified HMath.FFI.Value as V
import qualified HMath.Interchange.Array as A
import qualified HMath.Interchange.IO as I

class From a where from :: V.Value -> IO a
class To a where to :: a -> IO V.Value
instance {-# OVERLAPPABLE #-} N.From a => From a where from=N.from
instance {-# OVERLAPPABLE #-} N.To a => To a where to=N.to
instance {-# OVERLAPPING #-} From String where from=V.asText
instance {-# OVERLAPPING #-} To String where to=pure . V.Text
instance {-# OVERLAPPING #-} From Char where
    from value=do
        text<-V.asText value
        case text of
            [character]->pure character
            _->V.invalid "delimiter must be exactly one Haskell Char"
instance {-# OVERLAPPING #-} To Char where to=pure . V.Text . (:[])
instance {-# OVERLAPPING #-} From Word32 where from=V.asScalar
instance {-# OVERLAPPING #-} To Word32 where to=pure . V.Scalar SWord32
instance {-# OVERLAPPING #-} From BS.ByteString where from=Bytes.asBytes
instance {-# OVERLAPPING #-} To BS.ByteString where to=pure . Bytes.bytes
instance {-# OVERLAPPING #-} From a=>From [a] where from value=V.asList value >>=mapM from
instance {-# OVERLAPPING #-} To a=>To [a] where to values=V.List <$>mapM to values
instance {-# OVERLAPPING #-} From a=>From(Maybe a) where
    from V.None=pure Nothing
    from value=Just <$>from value
instance {-# OVERLAPPING #-} To a=>To(Maybe a) where to=maybe(pure V.None) to
instance {-# OVERLAPPING #-} (From a,From b)=>From(a,b) where
    from value=do
        fields<-V.asTuple 2 value
        case fields of
            [a,b]->(,) <$>from a <*>from b
            _->V.invalid "interchange pair arity differs"
instance {-# OVERLAPPING #-} (To a,To b)=>To(a,b) where to(a,b)=V.Tuple <$>sequence[to a,to b]
instance {-# OVERLAPPING #-} To a=>To(Either A.InterchangeError a) where to result=Error.source result >>=to
instance {-# OVERLAPPING #-} To a=>To(IO a) where to action=action >>=to
instance {-# OVERLAPPING #-} From (Get V.Value) where from=unbox 463
instance {-# OVERLAPPING #-} To (Get V.Value) where to value=pure(box 463 value [])
instance {-# OVERLAPPING #-} From Put where from=unbox 464
instance {-# OVERLAPPING #-} To Put where to value=pure(box 464 value [])
instance {-# OVERLAPPING #-} From Handle where from=unbox 452
instance {-# OVERLAPPING #-} To Handle where to value=pure(box 452 value [])

data Mapping where Mapping :: I.MappedArray s -> Mapping
instance {-# OVERLAPPING #-} From Mapping where from=unbox 465
instance {-# OVERLAPPING #-} To Mapping where
    to value@(Mapping mapped)=pure(box 465 value [to(I.mappedShape mapped)])

box :: Typeable a=>Int->a->[IO V.Value]->V.Value
box kind value fields=V.Opaque kind (-1) 0 (evaluate value >>sequence fields >>=mapM_ V.forceValue) value
unbox :: Typeable a=>Int->V.Value->IO a
unbox kind(V.Opaque actual _ _ _ value)
    |kind==actual=maybe(V.invalid "interchange payload type differs") pure(cast value)
unbox _ _=V.invalid "interchange object kind differs"

class Apply a where apply :: a->[V.Value]->IO V.Value
instance {-# OVERLAPPABLE #-} To a=>Apply a where
    apply value []=to value
    apply _ _=V.invalid "too many interchange arguments"
instance {-# OVERLAPPING #-} (From a,Apply b)=>Apply(a->b) where
    apply operation(value:rest)=from value >>= \argument->apply(operation argument) rest
    apply _ []=V.invalid "missing interchange argument"

foreign import ccall safe "hm_linear_invoke_callback"
    invokeCallback :: FunPtr ()->Ptr ()->StablePtr V.Value->Ptr(StablePtr V.Value)->Ptr ()->IO CInt
callbackResult :: V.Value->[IO V.Value]->IO V.Value
callbackResult (V.Opaque 101 _ _ _ payload) arguments=case cast payload of
    Just(L.Callback pointer userdata)->do
        encoded<-V.Tuple <$>sequence arguments
        V.forceValue encoded
        bracket(newStablePtr encoded) freeStablePtr $ \input->
            alloca $ \out->withMathErrorWire $ \errorWire->do
                status<-invokeCallback pointer userdata input out errorWire
                if status==13 then Error.readCallbackError errorWire >>=throwIO . Error.Failure
                else if status/=0 then readCallbackFailure status errorWire >>=throwIO
                else do
                    result<-peek out
                    bracket(pure result) freeStablePtr deRefStablePtr
    Nothing->V.invalid "interchange callback payload differs"
callbackResult _ _=V.invalid "expected a callback Value"

class Function a where function :: V.Value->[IO V.Value]->a
instance {-# OVERLAPPABLE #-} From a=>Function a where function=pureResult
instance {-# OVERLAPPING #-} (To a,Function b)=>Function(a->b) where
    function callback arguments argument=function callback(arguments++[to argument])
instance {-# OVERLAPPING #-} From a=>Function(IO a) where
    function callback arguments=callbackResult callback arguments >>=from
instance {-# OVERLAPPING #-} From a=>Function(Either A.InterchangeError a) where
    function callback arguments=unsafePerformIO(checkedResult callback arguments)
instance {-# OVERLAPPING #-} From a=>Function(IO(Either A.InterchangeError a)) where
    function=checkedResult
instance {-# OVERLAPPING #-} (To a,Function b)=>From(a->b) where from callback=pure(function callback [])

{-# NOINLINE pureResult #-}
pureResult :: From a=>V.Value->[IO V.Value]->a
pureResult callback arguments=unsafePerformIO(callbackResult callback arguments >>=from)
checkedResult :: From a=>V.Value->[IO V.Value]->IO(Either A.InterchangeError a)
checkedResult callback arguments=(Right <$> (callbackResult callback arguments >>=from)) `catch` recover
  where recover(Error.Failure errorValue)=pure(Left errorValue)
