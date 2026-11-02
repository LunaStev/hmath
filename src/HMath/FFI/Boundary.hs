{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- SPDX-License-Identifier: MPL-2.0
-- | Marshaling only: mathematical validation belongs to the original function.
module HMath.FFI.Boundary (boundary, checked, readInteger, writeStrings) where

import Control.Exception (SomeException, bracketOnError, catch, displayException, evaluate)
import Foreign
import Foreign.C
import HMath.Error (MathError)
import HMath.FFI.MathError (callbackBoundary, recordMathError)

foreign import ccall unsafe "hm_error" setError :: CInt -> CString -> IO CInt

report :: CInt -> String -> IO CInt
report code message = withCString message (setError code)

-- The caller reserves the RTS for the entire call. Every result is forced
-- before writing caller memory; Haskell exceptions never cross the C boundary.
boundary :: IO CInt -> IO CInt
boundary action =
    callbackBoundary mathFailure action
        `catch` (\(e :: SomeException) -> report 6 (displayException e))

mathFailure :: MathError -> IO CInt
mathFailure err = do
    status <- report 11 (show err)
    recorded <- recordMathError err
    if recorded == 0
        then pure status
        else report recorded "unable to record structured MathError"

checked :: Either MathError a -> (a -> IO ()) -> IO CInt
checked result write = case result of
    Left err -> mathFailure err
    Right value -> write value >> report 0 ""

-- C validates the decimal grammar before this parser is called. No bounded
-- integer or floating-point intermediate is involved.
readInteger :: CString -> IO Integer
readInteger pointer = peekCString pointer >>= evaluate . read

-- Force and allocate all text outputs before publishing any pointers. A later
-- allocation failure releases earlier allocations and leaves outputs untouched.
writeStrings :: [String] -> ([CString] -> IO ()) -> IO ()
writeStrings values write = do
    mapM_ (evaluate . length) values
    allocate values []
  where
    allocate [] pointers = write (reverse pointers)
    allocate (value : rest) pointers =
        bracketOnError (newCString value) free (\pointer -> allocate rest (pointer : pointers))
