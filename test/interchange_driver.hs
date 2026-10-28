{-# LANGUAGE ScopedTypeVariables #-}

-- SPDX-License-Identifier: MPL-2.0

{- | Standalone interchange integration driver; compile with the C mapping/
compression source and the same HMATH_HAVE_ZLIB feature used by Cabal.
-}
module Main (main) where

import Control.Concurrent (forkIO, newEmptyMVar, putMVar, takeMVar)
import Control.Exception (SomeException, evaluate, try)
import Control.Monad (forM_, replicateM, unless)
import Data.Bits (finiteBitSize)
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as C
import Data.Complex (Complex ((:+)))
import Data.IORef
import Data.Int
import Data.Word
import HMath.Interchange
import InterchangeSpec
import System.Directory (createDirectoryIfMissing, removeFile)
import System.Environment (getArgs)
import System.Exit (die)
import System.FilePath ((</>))
import System.IO

lim :: Limits
lim = defaultLimits
right :: (Show e) => Either e a -> IO a
right = either (die . show) pure
assert :: String -> Bool -> IO ()
assert name value = unless value (die ("FAIL " ++ name))
left :: Either a b -> Bool
left (Left _) = True
left _ = False
main :: IO ()
main = do
    args <- getArgs
    case args of
        ["selftest", dir] -> selftest dir
        ["export", dir] -> exportFixtures dir
        ["npy", source, dest] ->
            B.readFile source >>= right . decodeNpy lim >>= \a -> right (encodeNpy lim COrder a) >>= B.writeFile dest
        ["npz", source, dest] -> do
            input <- B.readFile source
            arrays <- decodeNpz lim input >>= right
            createDirectoryIfMissing True dest
            forM_ arrays $ \(name, a) -> right (encodeNpy lim COrder a) >>= B.writeFile (dest </> name ++ ".npy")
        ["mm", source, dest] ->
            B.readFile source >>= right . decodeMatrixMarket lim >>= \a -> right (encodeNpy lim COrder a) >>= B.writeFile dest
        ["inflate", wrapper, source, dest] -> do
            codec <- case wrapper of
                "raw" -> pure RawDeflate
                "zlib" -> pure Zlib
                "gzip" -> pure Gzip
                _ -> die "wrapper"
            input <- B.readFile source
            decompress lim codec (maxBytes lim) input >>= right >>= B.writeFile dest
        _ ->
            die
                "usage: interchange_driver selftest DIR | export DIR | npy IN OUT | npz IN DIR | mm IN OUT | inflate raw|zlib|gzip IN OUT"

selftest :: FilePath -> IO ()
selftest dir = do
    createDirectoryIfMissing True dir
    forM_ interchangeTests $ \(name, value) -> do
        result <- try (evaluate value) :: IO (Either SomeException Bool)
        assert (name ++ either (\e -> ": " ++ show e) (const "") result) (either (const False) id result)
    putStrLn (show (length interchangeTests) ++ " interchange pure test groups passed")
    let rawPath = dir </> "mapping.raw"
        spec = RawSpec I64 BigEndian FOrder [32, 32]
    a <- right (fromValues lim BigEndian [32, 32] [0 .. 1023 :: Int64])
    payload <- right (rawEncode lim BigEndian FOrder a)
    B.writeFile rawPath payload
    result <- withMappedArray lim spec rawPath $ \mapped -> do
        assert "mapped shape" (mappedShape mapped == [32, 32])
        scalar <- mappedValue mapped [7, 13] :: IO (Either InterchangeError Int64)
        assert "mapped endian/layout value" (scalar == Right 237)
        badIndex <- mappedValue mapped [32, 0] :: IO (Either InterchangeError Int64)
        assert "mapped bounds" (left badIndex)
        outputs <- replicateM 32 newEmptyMVar
        forM_ (zip [0 ..] outputs) $ \(i, out) -> do
            _ <- forkIO (mappedValue mapped [i, i] >>= putMVar out)
            pure ()
        values <- mapM takeMVar outputs :: IO [Either InterchangeError Int64]
        assert "concurrent mapping reads" (values == map (Right . fromIntegral . (* 33)) [0 :: Int .. 31])
        pure (mappedValue mapped [0, 0] :: IO (Either InterchangeError Int64))
    escaped <- right result
    afterClose <- escaped
    assert "escaping closure rejects closed mapping" (left afterClose)
    failed <-
        try (withMappedArray lim spec rawPath (\_ -> ioError (userError "callback failure"))) ::
            IO (Either SomeException (Either InterchangeError ()))
    assert "mapping closes on exception" (either (const False) left failed)
    reopened <-
        withMappedArray
            lim
            spec
            rawPath
            (\mapped -> mappedValue mapped [0, 0] :: IO (Either InterchangeError Int64))
    assert "mapping reopen" (reopened == Right (Right 0))
    tooSmall <- withMappedArray (lim{maxBytes = 1}) spec rawPath (\_ -> pure ())
    assert "mapping preallocation budget" (left tooSmall)
    B.writeFile (dir </> "empty.raw") B.empty
    empty <-
        withMappedArray
            lim
            (RawSpec U8 LittleEndian COrder [2, 0])
            (dir </> "empty.raw")
            (\mapped -> mappedReadBytes mapped 0 0)
    assert "empty mmap" (empty == Right (Right B.empty))
    -- A sparse file crosses the 32-bit offset boundary without allocating a
    -- multi-gigabyte Haskell buffer or consuming physical disk space.
    if finiteBitSize (0 :: Int) >= 64
        then do
            let extent = 5 * 1024 * 1024 * 1024 :: Integer
                large = lim{maxBytes = fromInteger extent, maxElements = fromInteger extent}
                path = dir </> "large-sparse.raw"
            withBinaryFile path WriteMode $ \h -> do
                hSetFileSize h extent
                hSeek h AbsoluteSeek (extent - 1)
                B.hPut h (B.singleton 173)
            value <-
                withMappedArray
                    large
                    (RawSpec U8 LittleEndian COrder [fromInteger extent])
                    path
                    (\mapped -> mappedValue mapped [fromInteger extent - 1] :: IO (Either InterchangeError Word8))
            removeFile path
            assert "mapped offset beyond 4 GiB" (value == Right (Right 173))
        else pure ()
    -- Consume with O(chunk) memory and a strict numeric accumulator.
    total <- newIORef (0 :: Integer, 0 :: Int)
    withBinaryFile rawPath ReadMode $ \h -> do
        readRawChunks
            lim
            spec
            73
            h
            ( \chunk -> case toValues chunk :: Either InterchangeError [Int64] of
                Left err -> pure (Left err)
                Right xs -> modifyIORef' total (\(s, n) -> (s + sum (map toInteger xs), n + length xs)) >> pure (Right True)
            )
            >>= right
    accumulated <- readIORef total
    assert "stream read chunk sum" (accumulated == (523776, 1024))
    cursor <- newIORef payload
    withBinaryFile (dir </> "stream.raw") WriteMode $ \h ->
        writeRawChunks
            lim
            spec
            23
            h
            ( \cap -> do
                bytes <- readIORef cursor
                if B.null bytes
                    then pure (Right Nothing)
                    else do
                        let (chunk, rest) = B.splitAt cap bytes
                        writeIORef cursor rest
                        pure (Right (Just chunk))
            )
            >>= right
    written <- B.readFile (dir </> "stream.raw")
    assert "stream write byte equivalence" (written == payload)
    forM_ [("short", B.take (B.length payload - 1) payload), ("tail", payload <> B.singleton 0)] $ \(name, bytes) -> do
        B.writeFile (dir </> name) bytes
        failure <- withBinaryFile (dir </> name) ReadMode $ \h -> readRawChunks lim spec 17 h (const (pure (Right True)))
        assert ("stream " ++ name) (left failure)
    withBinaryFile rawPath ReadMode $ \h -> do
        cancelled <- readRawChunks lim spec 1 h (const (pure (Right False)))
        position <- hTell h
        assert "stream cancellation" (cancelled == Right () && position == 8)
    let small = lim{maxBytes = 100, maxElements = 50}
    missing <- readArrayFile lim (decodeBinary lim) (dir </> "missing.file")
    assert "IO errors typed" (left missing)
    huge <- readArrayFile small (decodeBinary small) rawPath
    assert "file read byte budget" (left huge)
    available <- compressionAvailable
    forM_ [RawDeflate, Zlib, Gzip] $ \wrapper -> do
        encoded <- compress lim wrapper payload
        if available
            then do
                compressed <- right encoded
                decoded <- decompress lim wrapper (B.length payload) compressed
                assert ("compression roundtrip " ++ show wrapper) (decoded == Right payload)
                short <- decompress lim wrapper (B.length payload - 1) compressed
                tailError <- decompress lim wrapper (B.length payload) (compressed <> B.singleton 0)
                assert "decompression budget/trailing" (left short && left tailError)
                emptyCompressed <- compress lim wrapper B.empty >>= right
                emptyDecoded <- decompress lim wrapper 0 emptyCompressed
                assert "empty compression stream" (emptyDecoded == Right B.empty)
            else
                assert
                    "disabled compression reports unsupported"
                    (case encoded of Left (Unsupported _) -> True; _ -> False)
    forM_ (False : [True | available]) $ \compressed -> do
        z <- encodeNpz lim compressed [("tensor", a), ("unicode_λ", a)] >>= right
        arrays <- decodeNpz lim z >>= right
        assert
            "NPZ own roundtrip"
            ( map fst arrays == ["tensor", "unicode_λ"]
                && all (\(_, b) -> rawEncode lim BigEndian COrder b == rawEncode lim BigEndian COrder a) arrays
            )
        forM_ [0 .. B.length z - 1] $ \n -> decodeNpz lim (B.take n z) >>= assert "NPZ truncation rejected" . left
        decodeNpz (lim{maxArchiveEntries = 1}) z >>= assert "NPZ entry budget" . left
        encodeNpz lim compressed [("../escape", a)] >>= assert "NPZ flat safe names" . left
    encodeNpz lim False [(repeat 'x', a)] >>= assert "NPZ infinite key bounded" . left
    encodeNpz (lim{maxBytes = B.length payload + 1024}) False [("first", a), ("second", a)]
        >>= assert "NPZ aggregate encode budget" . left
    encodeNpz lim False [("bad_\xD800", a)] >>= assert "NPZ surrogate key rejected" . left
    encodeNpz lim False [("\xD800", a), ("\xD801", a)]
        >>= assert "NPZ lossy duplicate keys rejected" . left
    putStrLn "interchange streaming, mmap, compression and NPZ IO checks passed"

exportFixtures :: FilePath -> IO ()
exportFixtures dir = do
    createDirectoryIfMissing True dir
    let put name arr = do
            a <- right arr
            right (encodeNpy lim FOrder a) >>= B.writeFile (dir </> name ++ ".npy")
            pure (name, a)
    arrays <-
        sequence
            [ put
                "double_be_fortran"
                (fromValues lim BigEndian [2, 3] [0, 1 / 3, -0, 1e-300, 1e300, -7 :: Double])
            , put
                "int64"
                ( fromValues
                    lim
                    LittleEndian
                    [5]
                    [minBound, -9007199254740993, 0, 9007199254740993, maxBound :: Int64]
                )
            , put "uint64" (fromValues lim BigEndian [3] [0, 9007199254740993, maxBound :: Word64])
            , put "float32" (fromValues lim LittleEndian [4] [0, 1 / 3, -0, 1e-37 :: Float])
            , put
                "complex128"
                (fromValues lim BigEndian [2, 2] [1 :+ 2, 3 :+ (-4), (-0) :+ 0, 1e300 :+ 1e-300 :: Complex Double])
            , put "boolean" (fromValues lim LittleEndian [2, 2] [True, False, False, True])
            , put "empty" (fromValues lim LittleEndian [2, 0, 3] ([] :: [Double]))
            , put "scalar" (fromValues lim LittleEndian [] [42 :: Double])
            ]
    encodeNpz lim False arrays >>= right >>= B.writeFile (dir </> "stored.npz")
    available <- compressionAvailable
    if available
        then encodeNpz lim True arrays >>= right >>= B.writeFile (dir </> "compressed.npz")
        else pure ()
    forM_ arrays $ \(name, a) ->
        if arrayDType a `elem` [F64, I64, C128] && length (arrayShape a) == 2
            then right (encodeMatrixMarket lim a) >>= B.writeFile (dir </> name ++ ".mtx")
            else pure ()
    forM_ (zip [RawDeflate, Zlib, Gzip] ["raw", "zlib", "gzip"]) $ \(wrapper, name) ->
        if available
            then
                compress lim wrapper (C.pack (concat (replicate 1024 "numerical interchange\n")))
                    >>= right
                    >>= B.writeFile (dir </> name ++ ".compressed")
            else pure ()
    putStrLn "interchange export fixtures written"
