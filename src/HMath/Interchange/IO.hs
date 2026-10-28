{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- SPDX-License-Identifier: MPL-2.0

{- | Bounded strict file codecs, fixed-chunk raw streaming, and read-only
mapped arrays. Mappings are bracketed and protected by a lock; even an IO
closure escaping the callback reports a closed mapping rather than touching
freed memory. Callers must keep mapped files immutable (POSIX truncation can
otherwise cause SIGBUS). Windows mappings use the wide-character API.
-}
module HMath.Interchange.IO (
    readArrayFile,
    writeArrayFile,
    RawSpec (..),
    readRawChunks,
    writeRawChunks,
    MappedArray,
    withMappedArray,
    mappedValue,
    mappedShape,
    mappedReadBytes,
) where

import Control.Concurrent.MVar
import Control.Exception (IOException, bracket, catch)
import qualified Data.ByteString as B
import qualified Data.ByteString.Internal as BI
import qualified Data.Text as T
import qualified Data.Text.Encoding as E
import Foreign
import Foreign.C.Types
import HMath.Interchange.Array
import System.IO

{- | File reading checks the declared size before allocating, then caps the
actual read too, handling concurrent growth. Files are closed before return.
-}
readArrayFile ::
    Limits ->
    (B.ByteString -> Either InterchangeError Array) ->
    FilePath ->
    IO (Either InterchangeError Array)
readArrayFile lim decode path = ioErrors $ case checkLimits lim of
    Left err -> pure (Left err)
    Right () -> withBinaryFile path ReadMode $ \h -> do
        size <- hFileSize h
        if size > toInteger (maxBytes lim)
            then pure (Left (LimitExceeded "file bytes"))
            else do
                bytes <- readBounded h (maxBytes lim)
                pure (bytes >>= decode)

{- | Writes to the supplied path after encoding succeeds. Applications needing
transactional replacement can write a sibling temporary and rename it.
-}
writeArrayFile ::
    Limits ->
    (Limits -> Array -> Either InterchangeError B.ByteString) ->
    FilePath ->
    Array ->
    IO (Either InterchangeError ())
writeArrayFile lim encode path a = case encode lim a of
    Left err -> pure (Left err)
    Right bytes -> ioErrors (B.writeFile path bytes >> pure (Right ()))

ioErrors :: IO (Either InterchangeError a) -> IO (Either InterchangeError a)
ioErrors action = action `catch` (\(e :: IOException) -> pure (Left (InterchangeIOError (show e))))
readBounded :: Handle -> Int -> IO (Either InterchangeError B.ByteString)
readBounded h budget = go budget []
  where
    go left chunks = do
        bytes <- B.hGet h (min 65536 (if left == maxBound then left else left + 1))
        if B.length bytes > left
            then pure (Left (LimitExceeded "file grew beyond byte budget"))
            else
                if B.null bytes
                    then pure (Right (B.concat (reverse chunks)))
                    else go (left - B.length bytes) (bytes : chunks)

{- | Raw physical storage: fixed dtype/endian/order and shape, no header. The
stream has exactly the product(shape)*itemsize bytes, including empty arrays.
-}
data RawSpec = RawSpec DType Endian Order [Int] deriving (Eq, Show)

rawSize :: Limits -> RawSpec -> Either InterchangeError Int
rawSize lim (RawSpec dt _ _ sh) = do
    n <- validateShape lim sh
    boundedInt "raw stream bytes" (toInteger (maxBytes lim)) (toInteger n * toInteger (elementBytes dt))

{- | Read physical-order chunks (one-dimensional arrays); the caller retains
the original RawSpec for reconstructing dimensions. Memory is O(chunk),
excluding any data retained by the callback. False cancels successfully
without consuming the rest. Full completion requires EOF, detecting tails.
-}
readRawChunks ::
    Limits ->
    RawSpec ->
    Int ->
    Handle ->
    (Array -> IO (Either InterchangeError Bool)) ->
    IO (Either InterchangeError ())
readRawChunks lim spec@(RawSpec dt en _ _) chunkElements h consume = ioErrors $ case validate of
    Left err -> pure (Left err)
    Right total -> go total
  where
    width = elementBytes dt
    validate = do
        total <- rawSize lim spec
        guardI
            (chunkElements > 0 && toInteger chunkElements * toInteger width <= toInteger (maxBytes lim))
            (InvalidData "invalid stream chunk size")
        Right total
    go 0 = do
        tailByte <- B.hGet h 1
        pure (if B.null tailByte then Right () else Left (InvalidData "raw stream trailing bytes"))
    go left = do
        let amount = min left (chunkElements * width)
        bytes <- B.hGet h amount
        if B.length bytes /= amount
            then pure (Left (InvalidData "truncated raw stream"))
            else case contiguousArray lim dt en COrder [amount `div` width] bytes of
                Left err -> pure (Left err)
                Right a -> do
                    result <- consume a
                    case result of
                        Left err -> pure (Left err)
                        Right False -> pure (Right ())
                        Right True -> go (left - amount)

{- | Write fixed-size raw chunks. The producer receives a maximum byte count,
must return whole elements, and signals EOF with Nothing. Short streams,
overlong streams, noncanonical bools and empty nonfinal chunks fail. Errors
may leave a partial output; the handle remains owned by the caller.
-}
writeRawChunks ::
    Limits ->
    RawSpec ->
    Int ->
    Handle ->
    (Int -> IO (Either InterchangeError (Maybe B.ByteString))) ->
    IO (Either InterchangeError ())
writeRawChunks lim spec@(RawSpec dt en _ _) chunkElements h produce = ioErrors $ case validate of
    Left err -> pure (Left err)
    Right total -> go total
  where
    width = elementBytes dt
    validate = do
        total <- rawSize lim spec
        guardI
            (chunkElements > 0 && toInteger chunkElements * toInteger width <= toInteger (maxBytes lim))
            (InvalidData "invalid stream chunk size")
        Right total
    go left = do
        result <- produce (min left (chunkElements * width))
        case result of
            Left err -> pure (Left err)
            Right Nothing -> pure (if left == 0 then Right () else Left (InvalidData "short raw producer"))
            Right (Just bytes) -> case valid bytes of
                Left err -> pure (Left err)
                Right () -> B.hPut h bytes >> go (left - B.length bytes)
      where
        valid bytes = do
            guardI
                ( not (B.null bytes)
                    && B.length bytes <= min left (chunkElements * width)
                    && B.length bytes `mod` width == 0
                )
                (InvalidData "raw producer chunk size")
            _ <- contiguousArray lim dt en COrder [B.length bytes `div` width] bytes
            Right ()

foreign import ccall safe "hmath_interchange_map"
    c_map :: Ptr CChar -> Word64 -> Ptr CInt -> IO (Ptr ())
foreign import ccall unsafe "hmath_interchange_unmap" c_unmap :: Ptr () -> IO ()
foreign import ccall unsafe "hmath_interchange_map_size" c_size :: Ptr () -> IO Word64
foreign import ccall safe "hmath_interchange_map_read"
    c_read :: Ptr () -> Word64 -> CSize -> Ptr Word8 -> IO CInt

-- | Scope-bound mapping; no pointer or borrowed ByteString is exposed.
data MappedArray s = MappedArray RawSpec Int (MVar (Maybe (Ptr ())))

{- | Return dimensions of a callback-scoped read-only mapped array. The region token
prevents its raw view escaping withMappedArray.
-}
mappedShape :: MappedArray s -> [Int]
mappedShape (MappedArray (RawSpec _ _ _ sh) _ _) = sh

{- | Given limits,RawSpec,path,then rank-2 callback, map read-only raw data for that
callback's lifetime and unmap on exit. Validate exact file size/spec/budgets;
path/IO/format failures return InterchangeError. Do not retain borrowed pointers beyond
the callback.
-}
withMappedArray ::
    Limits -> RawSpec -> FilePath -> (forall s. MappedArray s -> IO a) -> IO (Either InterchangeError a)
withMappedArray lim spec path action = ioErrors $ case rawSize lim spec of
    Left err -> pure (Left err)
    Right expected
        | '\0' `elem` path -> pure (Left (InvalidData "NUL in file path"))
        | otherwise -> B.useAsCString (E.encodeUtf8 (T.pack path)) $ \name -> alloca $ \err -> do
            bracket (c_map name (fromIntegral (maxBytes lim)) err) c_unmap $ \ptr ->
                if ptr == nullPtr
                    then do
                        code <- peek err
                        pure (Left (InterchangeIOError ("mmap failed (" ++ show code ++ ")")))
                    else do
                        size <- c_size ptr
                        if size /= fromIntegral expected
                            then pure (Left (InvalidData "mapped raw file size mismatch"))
                            else do
                                lock <- newMVar (Just ptr)
                                -- Retire the capability before releasing native storage,
                                -- waiting for concurrent read copies already in progress.
                                bracket
                                    (pure (MappedArray spec expected lock))
                                    (\_ -> modifyMVar_ lock (const (pure Nothing)))
                                    (fmap Right . action)

-- | Copy a bounded byte range. Copies may safely survive mapping closure.
mappedReadBytes :: MappedArray s -> Int -> Int -> IO (Either InterchangeError B.ByteString)
mappedReadBytes (MappedArray _ size lock) offset count
    | offset < 0 || count < 0 || offset > size || count > size - offset =
        pure (Left (InvalidData "mapped byte range"))
    | otherwise = withMVar lock $ \current -> case current of
        Nothing -> pure (Left (InvalidData "mapping is closed"))
        Just ptr -> do
            (bytes, result) <- BI.createAndTrim' count $ \dest -> do
                status <- c_read ptr (fromIntegral offset) (fromIntegral count) dest
                pure (0, if status == 0 then count else 0, status)
            pure (if result == 0 then Right bytes else Left (InvalidData "mapped native range"))

{- | Read one typed scalar using checked multidimensional indexing. Physical
endian conversion happens through the same Element decoder as normal arrays.
-}
mappedValue :: (Element a) => MappedArray s -> [Int] -> IO (Either InterchangeError a)
mappedValue mapped@(MappedArray (RawSpec dt en order sh) _ _) ix
    | length (take (length sh + 1) ix) /= length sh || not (and (zipWith (\i d -> i >= 0 && i < d) ix sh)) =
        pure (Left (InvalidData "mapped index out of range"))
    | otherwise = do
        let offset = sum (zipWith (*) ix (denseStrides order (elementBytes dt) sh))
        bytes <- mappedReadBytes mapped offset (elementBytes dt)
        pure $ do
            b <- bytes
            a <- contiguousArray defaultLimits dt en COrder [] b
            xs <- toValues a
            case xs of
                [x] -> Right x
                _ -> Left (InvalidData "mapped scalar")
