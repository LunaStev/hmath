{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Lossless MathError callback transport, independent of error pretty-printing.
module HMath.FFI.MathError
    ( CallbackFailure (..), callbackBoundary, recordMathError, readMathError, readWireMessage, withMathErrorWire, withEncodedMessage, readCallbackFailure ) where
import Control.Exception (Exception, catch, throwIO)
import Data.Char (chr, ord)
import Foreign
import Foreign.C
import HMath.Error (MathError (..))

data CallbackFailure
    = CallbackFailure CInt String
    | CallbackMathError MathError
    | CallbackDomainError CInt CInt [Int] String
    deriving (Show)
instance Exception CallbackFailure
foreign import ccall unsafe "hm_error" reportCallbackError :: CInt -> CString -> IO CInt
foreign import ccall unsafe "hm_record_math_error" record :: CInt -> Ptr CPtrdiff -> CString -> CSize -> IO CInt
foreign import ccall unsafe "hm_record_expression_error" recordExpression :: CInt -> Ptr CPtrdiff -> CString -> CSize -> IO CInt
foreign import ccall unsafe "hm_record_interchange_error" recordInterchange :: CInt -> CString -> CSize -> IO CInt
foreign import ccall unsafe "hm_math_error_size" wireSize :: IO CSize
foreign import ccall unsafe "hm_math_error_reset" resetWire :: Ptr () -> IO ()
foreign import ccall unsafe "hm_math_error_kind" kindOf :: Ptr () -> IO CInt
foreign import ccall unsafe "hm_math_error_detail" detailOf :: Ptr () -> CInt -> IO CPtrdiff
foreign import ccall unsafe "hm_math_error_message" messageOf :: Ptr () -> IO CString
foreign import ccall unsafe "hm_math_error_message_length" lengthOf :: Ptr () -> IO CSize

-- Install this inside the ordinary SomeException boundary. Source Either
-- callbacks return Left directly; pure callbacks may throw CallbackMathError.
callbackBoundary :: (MathError -> IO CInt) -> IO CInt -> IO CInt
callbackBoundary onMath action = action `catch` relay
  where
    relay (CallbackMathError value) = onMath value
    relay (CallbackFailure code message) = withEncodedMessage message (\pointer _ -> reportCallbackError code pointer)
    relay (CallbackDomainError status kind details message) = do
        _ <- withCString ("Haskell domain error " ++ show status ++ ": " ++ show message) (reportCallbackError status)
        recorded <- withEncodedMessage message $ \pointer count -> case status of
            12 -> withArray (map fromIntegral (take 3 (details ++ repeat 0))) $ \position -> recordExpression kind position pointer count
            13 -> recordInterchange kind pointer count
            _ -> pure 1
        if recorded == 0 then pure status
            else withCString "unable to record callback domain error" (reportCallbackError recorded)

-- The existing callback wire is ABI-compatible across error domains. Return
-- status selects MathError, ExprError(position in details0..2), or interchange.
readCallbackFailure :: CInt -> Ptr () -> IO CallbackFailure
readCallbackFailure status pointer
    | status == 11 = CallbackMathError <$> readMathError pointer
    | status == 12 = do
        kind <- kindOf pointer
        details <- mapM (fmap fromIntegral . detailOf pointer) [0,1,2]
        CallbackDomainError status kind details <$> readWireMessage pointer
    | status == 13 = do
        kind <- kindOf pointer
        CallbackDomainError status kind [] <$> readWireMessage pointer
    | otherwise = CallbackFailure status <$> readWireMessage pointer

-- UTF8 for scalar values, with surrogatepass/WTF8 for the additional Char
-- codepoints permitted by Haskell String. This also preserves embedded NUL.
encodeChar :: Char -> [Word8]
encodeChar character = map fromIntegral $ let n=ord character in
    if n < 0x80 then [n]
    else if n < 0x800 then [0xc0 .|. (n `shiftR` 6),0x80 .|. (n .&. 0x3f)]
    else if n < 0x10000 then [0xe0 .|. (n `shiftR` 12),0x80 .|. ((n `shiftR` 6) .&. 0x3f),0x80 .|. (n .&. 0x3f)]
    else [0xf0 .|. (n `shiftR` 18),0x80 .|. ((n `shiftR` 12) .&. 0x3f),0x80 .|. ((n `shiftR` 6) .&. 0x3f),0x80 .|. (n .&. 0x3f)]
decodeBytes :: [Word8] -> IO String
decodeBytes [] = pure []
decodeBytes (a:rest)
    | a < 0x80 = (chr (fromIntegral a):) <$> decodeBytes rest
    | a >= 0xc2 && a <= 0xdf = more 1 (fromIntegral a .&. 0x1f) rest
    | a >= 0xe0 && a <= 0xef = more 2 (fromIntegral a .&. 0x0f) rest
    | a >= 0xf0 && a <= 0xf4 = more 3 (fromIntegral a .&. 0x07) rest
    | otherwise = invalidText
  where
    more count initial bytes = do
        let (chunk,remaining)=splitAt count bytes
            n=foldl (\value byte -> (value `shiftL` 6) .|. (fromIntegral byte .&. 0x3f)) initial chunk
            minimumValue=case count of {1 -> 0x80; 2 -> 0x800; _ -> 0x10000}
        if length chunk /= count || any (\byte -> byte < 0x80 || byte > 0xbf) chunk || n < minimumValue || n > 0x10ffff
            then invalidText
            else (chr n:) <$> decodeBytes remaining
    invalidText = throwIO (CallbackFailure 1 "invalid MathError UTF8 message")
readWireMessage :: Ptr () -> IO String
readWireMessage pointer = do
    messagePointer <- messageOf pointer
    size <- lengthOf pointer
    if toInteger size > toInteger (maxBound :: Int) || (size /= 0 && messagePointer == nullPtr)
        then throwIO (CallbackFailure 1 "invalid MathError message span")
        else if size == 0 then pure "" else peekArray (fromIntegral size) (castPtr messagePointer) >>= decodeBytes

recordMathError :: MathError -> IO CInt
recordMathError value =
    let (kind,details,message)=fields value
    in withArray (map fromIntegral (take 6 (details ++ repeat 0))) $ \numbers ->
        withEncodedMessage message (record kind numbers)
  where
    fields e = case e of
        NegativeDimensions (a,b) -> (1,[a,b],"")
        ElementCountOverflow (a,b) -> (2,[a,b],"")
        ElementCountMismatch a b -> (3,[a,b],"")
        ShapeMismatch (a,b) (c,d) -> (4,[a,b,c,d],"")
        InnerDimensionMismatch a b -> (5,[a,b],"")
        IndexOutOfBounds (a,b) (c,d) -> (6,[a,b,c,d],"")
        SliceOutOfBounds (a,b) (c,d) (f,g) -> (7,[a,b,c,d,f,g],"")
        VectorLengthMismatch a b -> (8,[a,b],"")
        NonSquareMatrix (a,b) -> (9,[a,b],"")
        InvalidTolerance -> (10,[],"")
        SingularMatrix a -> (11,[a],"")
        NearSingularMatrix a -> (12,[a],"")
        NonFiniteMatrixEntry (a,b) -> (13,[a,b],"")
        NonFiniteVectorEntry a -> (14,[a],"")
        NonFiniteResult -> (15,[],"")
        RightHandSideMismatch a b -> (16,[a,b],"")
        DomainError s -> (17,[],s)
        InvalidArgument s -> (18,[],s)
        NonConvergence s a -> (19,[a],s)
        RankDeficient a -> (20,[a],"")
        NotPositiveDefinite a -> (21,[a],"")

-- Shared domain-error text transport preserves every Haskell Char, including
-- embedded NUL and isolated surrogates, without locale-dependent conversion.
withEncodedMessage :: String -> (CString -> CSize -> IO a) -> IO a
withEncodedMessage message action =
    let bytes = concatMap encodeChar message
    in withArray bytes $ \pointer -> action (castPtr pointer) (fromIntegral (length bytes))

withMathErrorWire :: (Ptr () -> IO a) -> IO a
withMathErrorWire action = do
    size <- wireSize
    allocaBytes (fromIntegral size) $ \pointer -> resetWire pointer >> action pointer

readMathError :: Ptr () -> IO MathError
readMathError pointer = do
    kind <- kindOf pointer
    numbers <- mapM (fmap fromIntegral . detailOf pointer) [0..5]
    message <- if kind `elem` [17,18,19] then readWireMessage pointer else pure ""
    let decoded = do
            let a=numbers!!0; b=numbers!!1; c=numbers!!2; d=numbers!!3; f=numbers!!4; g=numbers!!5
            case kind of
                1 -> pure (NegativeDimensions (a,b))
                2 -> pure (ElementCountOverflow (a,b))
                3 -> pure (ElementCountMismatch a b)
                4 -> pure (ShapeMismatch (a,b) (c,d))
                5 -> pure (InnerDimensionMismatch a b)
                6 -> pure (IndexOutOfBounds (a,b) (c,d))
                7 -> pure (SliceOutOfBounds (a,b) (c,d) (f,g))
                8 -> pure (VectorLengthMismatch a b)
                9 -> pure (NonSquareMatrix (a,b))
                10 -> pure InvalidTolerance
                11 -> pure (SingularMatrix a)
                12 -> pure (NearSingularMatrix a)
                13 -> pure (NonFiniteMatrixEntry (a,b))
                14 -> pure (NonFiniteVectorEntry a)
                15 -> pure NonFiniteResult
                16 -> pure (RightHandSideMismatch a b)
                17 -> pure (DomainError message)
                18 -> pure (InvalidArgument message)
                19 -> pure (NonConvergence message a)
                20 -> pure (RankDeficient a)
                21 -> pure (NotPositiveDefinite a)
                _ -> throwIO (CallbackFailure 1 "invalid MathError constructor kind")
    decoded
