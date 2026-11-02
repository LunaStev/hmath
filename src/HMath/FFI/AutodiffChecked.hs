{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Additive structured callbacks; original AD formulas and laziness stay in Autodiff.
module HMath.FFI.AutodiffChecked where

import Control.Exception (bracket,bracketOnError,throwIO)
import Data.Coerce (coerce)
import Foreign
import Foreign.C
import System.IO.Unsafe (unsafePerformIO)
import qualified HMath.Autodiff as A
import qualified HMath.FFI.Autodiff as D
import HMath.Error (MathError)
import qualified HMath.FFI.Boundary as B
import HMath.FFI.MathError (CallbackFailure(..),withMathErrorWire,readCallbackFailure)

type Rule = Ptr CDouble -> CSize -> Ptr () -> Ptr CDouble -> Ptr CDouble -> CSize -> Ptr CSize -> Ptr () -> IO CInt
type Unary = CDouble -> Ptr () -> Ptr CDouble -> Ptr () -> IO CInt
foreign import ccall safe "dynamic" callRule :: FunPtr Rule -> Rule
foreign import ccall safe "dynamic" callUnary :: FunPtr Unary -> Unary
foreign import ccall safe "hm_ad_invoke_builder_checked"
    callBuilder :: FunPtr () -> Ptr () -> Ptr(StablePtr D.Value) -> CSize -> Ptr(StablePtr D.Value) -> Ptr () -> IO CInt

{-# NOINLINE rule #-}
rule :: FunPtr Rule -> Ptr () -> [Double] -> Either MathError(Double,[Double])
rule callback userdata values = unsafePerformIO $
    withArray(map coerce values::[CDouble]) $ \inputs ->
    alloca $ \value -> allocaArray(max 1(length values)) $ \partials ->
    alloca $ \written -> withMathErrorWire $ \errorWire -> do
        poke value (0/0)
        poke written (fromIntegral(length values))
        status<-callRule callback inputs (fromIntegral(length values)) userdata value partials (fromIntegral(length values)) written errorWire
        if status/=0 then do
            failure<-readCallbackFailure status errorWire
            case failure of
                CallbackMathError err -> pure(Left err)
                _ -> throwIO failure
        else do
            count<-peek written
            if toInteger count>toInteger(maxBound::Int)
                then throwIO(CallbackFailure 3 "custom derivative count exceeds Haskell Int")
                else do
                    result<-coerce <$> peek value
                    derivatives<-if fromIntegral count==length values
                        then map coerce <$> peekArray(fromIntegral count)partials
                        else pure(replicate(fromIntegral count)0)
                    pure(Right(result,derivatives))

{-# NOINLINE unary #-}
unary :: FunPtr Unary -> Ptr () -> Double -> Double
unary callback userdata input = unsafePerformIO $ alloca $ \out -> withMathErrorWire $ \errorWire -> do
    poke out (0/0)
    status<-callUnary callback (coerce input) userdata out errorWire
    if status/=0 then readCallbackFailure status errorWire >>= throwIO else coerce <$> peek out

{-# NOINLINE builder #-}
builder :: FunPtr () -> Ptr () -> [A.Expr] -> A.Expr
builder callback userdata values = unsafePerformIO $ temporary values []
  where
    temporary [] pointers = withArray(reverse pointers) $ \inputs -> alloca $ \out -> withMathErrorWire $ \errorWire -> do
        status<-callBuilder callback userdata inputs (fromIntegral(length values)) out errorWire
        if status/=0 then readCallbackFailure status errorWire >>= throwIO else do
            pointer<-peek out
            bracket(pure pointer)freeStablePtr $ \stable -> do
                value<-deRefStablePtr stable
                case D.expression value of
                    Left err -> throwIO(CallbackMathError err)
                    Right expression -> pure expression
    temporary (value:rest) pointers = bracket(newStablePtr(D.Expression value))freeStablePtr $ \pointer -> temporary rest(pointer:pointers)

foreign export ccall "hm_ad_custom_checked" create :: CInt -> FunPtr () -> FunPtr () -> Ptr () -> Ptr(StablePtr D.Value) -> CSize -> Ptr(StablePtr D.Value) -> IO CInt
create :: CInt -> FunPtr () -> FunPtr () -> Ptr () -> Ptr(StablePtr D.Value) -> CSize -> Ptr(StablePtr D.Value) -> IO CInt
create operation callback derivative userdata inputs count out = B.boundary $ do
    arguments<-peekArray(fromIntegral count)inputs >>= mapM deRefStablePtr
    B.checked(mapM D.expression arguments) $ \expressions -> do
        result<-case (operation,expressions) of
            (0,_) -> pure(A.customOperation(rule(castFunPtr callback)userdata)expressions)
            (1,[expression]) -> pure(A.customUnary(unary(castFunPtr callback)userdata)(unary(castFunPtr derivative)userdata)expression)
            (2,_) -> pure(A.checkpoint(builder callback userdata)expressions)
            _ -> throwIO(CallbackFailure 1 "invalid checked AD callback operation")
        bracketOnError(newStablePtr(D.Expression result))freeStablePtr(poke out)
