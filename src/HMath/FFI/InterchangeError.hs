{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Lossless original InterchangeError transport, distinct from MathError.
module HMath.FFI.InterchangeError where

import Control.Exception (Exception, catch, throwIO)
import Foreign
import Foreign.C
import qualified HMath.FFI.Boundary as B
import HMath.FFI.MathError (withEncodedMessage, readWireMessage)
import qualified HMath.Interchange.Array as A

newtype Failure = Failure A.InterchangeError deriving (Show)
instance Exception Failure
foreign import ccall unsafe "hm_error" report :: CInt -> CString -> IO CInt
foreign import ccall unsafe "hm_record_interchange_error"
    record :: CInt -> CString -> CSize -> IO CInt
foreign import ccall unsafe "hm_math_error_kind" callbackKind :: Ptr () -> IO CInt

fields :: A.InterchangeError -> (CInt, String)
fields value = case value of
    A.InvalidData message -> (0,message)
    A.Unsupported message -> (1,message)
    A.LimitExceeded message -> (2,message)
    A.InterchangeIOError message -> (3,message)
fromFields :: CInt -> String -> IO A.InterchangeError
fromFields kind message = case kind of
    0 -> pure (A.InvalidData message)
    1 -> pure (A.Unsupported message)
    2 -> pure (A.LimitExceeded message)
    3 -> pure (A.InterchangeIOError message)
    _ -> ioError (userError "unknown InterchangeError constructor")
source :: Either A.InterchangeError a -> IO a
source = either (throwIO . Failure) pure
boundary :: IO CInt -> IO CInt
boundary action = B.boundary (action `catch` failure)
  where
    failure (Failure value) = do
        _ <- withCString (show value) (report 13)
        let (kind,message)=fields value
        status <- withEncodedMessage message (record kind)
        if status == 0 then pure 13
            else withCString "unable to record InterchangeError" (report status)
readCallbackError :: Ptr () -> IO A.InterchangeError
readCallbackError pointer = do
    kind <- callbackKind pointer
    message <- readWireMessage pointer
    fromFields kind message
