-- SPDX-License-Identifier: MPL-2.0

{- | NPY v1/v2/v3 and NPZ (ZIP32 directory, stored or raw-DEFLATE members).
Scalar fixed-width dtypes only: object/pickle, records, strings and ZIP64
directories are rejected. NumPy's small-file ZIP64 local headers are
accepted. Input budgets cover aggregate uncompressed bytes. Nothing is
extracted to disk, so archive names can never become filesystem paths.
Specifications: <https://numpy.org/doc/stable/reference/generated/numpy.lib.format.html>
and <https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT>.
-}
module HMath.Interchange.Numpy (encodeNpy, decodeNpy, encodeNpz, decodeNpz) where

import Control.Monad (foldM, replicateM, unless, when)
import Data.Binary.Get
import Data.Binary.Put
import Data.Bits ((.&.))
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as C
import qualified Data.ByteString.Lazy as L
import Data.Char (isDigit)
import Data.List (intercalate, nub, sortOn)
import qualified Data.Text as T
import qualified Data.Text.Encoding as E
import Data.Word
import HMath.Interchange.Array
import HMath.Interchange.Binary
import HMath.Interchange.Compression
import Text.ParserCombinators.ReadP hiding (count)

descriptor :: DType -> String
descriptor dt = case dt of
    Bool8 -> "b1"
    I8 -> "i1"
    U8 -> "u1"
    I16 -> "i2"
    U16 -> "u2"
    I32 -> "i4"
    U32 -> "u4"
    I64 -> "i8"
    U64 -> "u8"
    F32 -> "f4"
    F64 -> "f8"
    C64 -> "c8"
    C128 -> "c16"

{- | Given limits,physical C/F order,then Array, repack and write a NumPy NPY v1 payload
with explicit dtype/endian/shape. Oversized header/output or unsupported layout
conversion fails.
-}
encodeNpy :: Limits -> Order -> Array -> Either InterchangeError B.ByteString
encodeNpy lim order a = do
    packed <- repack lim (arrayEndian a) order a
    let marker =
            if elementBytes (arrayDType a) == 1 then '|' else if arrayEndian a == LittleEndian then '<' else '>'
        dims = map show (arrayShape a)
        shape = "(" ++ intercalate ", " dims ++ (if length dims == 1 then "," else "") ++ ")"
        header =
            "{'descr': '"
                ++ [marker]
                ++ descriptor (arrayDType a)
                ++ "', 'fortran_order': "
                ++ (if order == FOrder then "True" else "False")
                ++ ", 'shape': "
                ++ shape
                ++ ", }"
        padding = (64 - (10 + length header + 1) `mod` 64) `mod` 64
        h = C.pack (header ++ replicate padding ' ' ++ "\n")
    guardI (B.length h <= 65535 && B.length h <= maxMetadata lim) (LimitExceeded "NPY header")
    guardI
        (toInteger (B.length h) + 10 + toInteger (B.length (arrayBytes packed)) <= toInteger (maxBytes lim))
        (LimitExceeded "NPY output bytes")
    Right
        ( L.toStrict
            ( runPut
                ( putByteString (B.pack [147, 78, 85, 77, 80, 89, 1, 0])
                    >> putWord16le (fromIntegral (B.length h))
                    >> putByteString h
                    >> putByteString (arrayBytes packed)
                )
            )
        )

data HeaderValue = Descr String | Fortran Bool | Shape [Integer] deriving (Show)

-- ReadP parses a deliberately tiny Python-literal grammar, never eval/Read.
-- Every lexical token is bounded by the already-validated header length.
headerParser :: ReadP [(String, HeaderValue)]
headerParser = lexeme (char '{') *> sepEndBy field (lexeme (char ',')) <* lexeme (char '}') <* eof
  where
    lexeme p = p <* skipSpaces
    quoted = lexeme $ do
        q <- satisfy (\c -> c == '\'' || c == '"')
        s <- munch (\c -> c /= q && c /= '\\')
        _ <- char q
        pure s
    field = do
        key <- quoted
        _ <- lexeme (char ':')
        value <- case key of
            "descr" -> Descr <$> quoted
            "fortran_order" -> Fortran <$> lexeme ((True <$ string "True") <++ (False <$ string "False"))
            "shape" -> Shape <$> (lexeme (char '(') *> sepEndBy integer (lexeme (char ',')) <* lexeme (char ')'))
            _ -> pfail
        pure (key, value)
    integer = lexeme $ do
        digits <- munch1 isDigit
        if length digits <= 20 then pure (read digits) else pfail
    sepEndBy p separator =
        ( do
            x <- p
            xs <- many (separator *> p)
            _ <- option Nothing (Just <$> separator)
            pure (x : xs)
        )
            <++ pure []

{- | Given limits then NPY bytes, decode supported v1/v2/v3 fixed-width scalar dtype arrays.
Reject pickle/object/record/string dtypes, malformed headers, unknown endian/layout,
trailing bytes or exceeded budgets.
-}
decodeNpy :: Limits -> B.ByteString -> Either InterchangeError Array
decodeNpy lim input = do
    checkLimits lim
    guardI (B.length input <= maxBytes lim) (LimitExceeded "NPY input bytes")
    (header, payload) <- runDecoder parser input
    headerString <-
        either (const (Left (InvalidData "invalid NPY UTF-8"))) (Right . T.unpack) (E.decodeUtf8' header)
    fields <- case readP_to_S (skipSpaces *> headerParser) headerString of
        [(x, "")] -> Right x
        _ -> Left (InvalidData "invalid NPY literal header")
    guardI (length fields == 3 && length (nub (map fst fields)) == 3) (InvalidData "NPY header keys")
    (desc, order, sh) <- case (lookup "descr" fields, lookup "fortran_order" fields, lookup "shape" fields) of
        (Just (Descr d), Just (Fortran f), Just (Shape dims)) -> do
            shape <- mapM (boundedInt "NPY dimension" (toInteger (maxBound :: Int))) dims
            Right (d, if f then FOrder else COrder, shape)
        _ -> Left (InvalidData "NPY required header fields")
    (dt, en) <- case desc of
        marker : dtype -> do
            dt <-
                maybe
                    (Left (Unsupported "NPY scalar dtype"))
                    Right
                    (lookup dtype [(descriptor t, t) | t <- [minBound .. maxBound]])
            en <- case marker of
                '<' -> Right LittleEndian
                '>' -> Right BigEndian
                '|' | elementBytes dt == 1 -> Right LittleEndian
                _ -> Left (Unsupported "NPY requires explicit endian")
            Right (dt, en)
        _ -> Left (InvalidData "empty NPY descriptor")
    contiguousArray lim dt en order sh payload
  where
    parser = do
        magic <- getByteString 6
        unless (magic == B.pack [147, 78, 85, 77, 80, 89]) (fail "NPY magic")
        major <- getWord8
        minor <- getWord8
        unless (minor == 0 && major `elem` [1, 2, 3]) (fail "unsupported NPY version")
        len <- if major == 1 then fromIntegral <$> getWord16le else getWord32le
        when (toInteger len > toInteger (maxMetadata lim)) (fail "NPY header budget")
        h <- getByteString (fromIntegral len)
        unless (not (B.null h) && B.last h == 10) (fail "NPY header newline")
        -- Older NPY writers align to 16 rather than modern NumPy's 64 bytes.
        unless
            ((fromIntegral len + (if major == 1 then 10 else 12) :: Integer) `mod` 16 == 0)
            (fail "NPY alignment")
        unless (major == 3 || B.all (< 128) h) (fail "non-ASCII NPY v1/v2 header")
        p <- L.toStrict <$> getRemainingLazyByteString
        pure (h, p)

-- ZIP central-directory metadata, validated before touching a member.
data Entry = Entry B.ByteString Word16 Word16 Word32 Int Int Int deriving (Show)
entryName :: Entry -> B.ByteString
entryName (Entry n _ _ _ _ _ _) = n
entrySize :: Entry -> Int
entrySize (Entry _ _ _ _ _ n _) = n
entryOffset :: Entry -> Int
entryOffset (Entry _ _ _ _ _ _ n) = n

{- | Deterministic archives, DOS epoch timestamps and no ZIP comments. True
selects raw DEFLATE and requires the optional zlib build feature.
-}
encodeNpz :: Limits -> Bool -> [(String, Array)] -> IO (Either InterchangeError B.ByteString)
encodeNpz lim compressed arrays = case validate of
    Left err -> pure (Left err)
    Right encoded -> do
        results <- mapM pack encoded
        pure $ do
            members <- sequence results
            -- Check lengths before constructing any ZIP record buffers.
            let recordSizes = [30 + toInteger (B.length name) + toInteger (B.length payload) | (name, _, payload) <- members]
                directorySize = sum [46 + toInteger (B.length name) | (name, _, _) <- members]
                total = sum recordSizes + directorySize + 22
            guardI
                (total <= toInteger (maxBytes lim) && total < 4294967295)
                (LimitExceeded "NPZ archive output")
            let localRecords = map local members
                positions = scanl (+) (0 :: Int) (map fromInteger recordSizes)
                directory = B.concat (zipWith central members positions)
                start = fromInteger (sum recordSizes) :: Int
            Right
                ( B.concat localRecords
                    <> directory
                    <> L.toStrict
                        ( runPut $ do
                            putWord32le 0x06054b50
                            putWord16le 0
                            putWord16le 0
                            putWord16le (fromIntegral (length members))
                            putWord16le (fromIntegral (length members))
                            putWord32le (fromIntegral (B.length directory))
                            putWord32le (fromIntegral start)
                            putWord16le 0
                        )
                )
  where
    validate = do
        checkLimits lim
        guardI
            (length (take (maxArchiveEntries lim + 1) arrays) <= maxArchiveEntries lim && length arrays < 65535)
            (LimitExceeded "archive member count")
        -- Validate bounded Unicode names before comparing them, then consume
        -- a shared budget incrementally. Encoding all members first could
        -- allocate maxArchiveEntries * maxBytes before rejecting an archive.
        names <- mapM (archiveName . fst) arrays
        guardI (length (nub names) == length names) (InvalidData "duplicate NPZ name")
        let overhead = 22 + sum [76 + 2 * toInteger (B.length name) | name <- names]
        guardI (overhead <= toInteger (maxBytes lim)) (LimitExceeded "NPZ metadata bytes")
        (_, encoded) <-
            foldM encodeMember (maxBytes lim - fromInteger overhead, []) (zip names (map snd arrays))
        Right (reverse encoded)
    encodeMember (budget, encoded) (name, a) = do
        bytes <- encodeNpy (lim{maxBytes = budget}) COrder a
        Right (budget - B.length bytes, (name, bytes) : encoded)
    pack (name, bytes) = do
        content <- if compressed then compress lim RawDeflate bytes else pure (Right bytes)
        pure ((\p -> (name, bytes, p)) <$> content)
    method = if compressed then 8 else 0
    local (name, bytes, payload) =
        L.toStrict
            ( runPut $ do
                putWord32le 0x04034b50
                putWord16le 20
                putWord16le 0x800
                putWord16le method
                putWord16le 0
                putWord16le 33
                putWord32le (crc32 bytes)
                putWord32le (fromIntegral (B.length payload))
                putWord32le (fromIntegral (B.length bytes))
                putWord16le (fromIntegral (B.length name))
                putWord16le 0
                putByteString name
                putByteString payload
            )
    central (name, bytes, payload) offset =
        L.toStrict
            ( runPut $ do
                putWord32le 0x02014b50
                putWord16le 20
                putWord16le 20
                putWord16le 0x800
                putWord16le method
                putWord16le 0
                putWord16le 33
                putWord32le (crc32 bytes)
                putWord32le (fromIntegral (B.length payload))
                putWord32le (fromIntegral (B.length bytes))
                putWord16le (fromIntegral (B.length name))
                putWord16le 0
                putWord16le 0
                putWord16le 0
                putWord16le 0
                putWord32le 0
                putWord32le (fromIntegral offset)
                putByteString name
            )

archiveName :: String -> Either InterchangeError B.ByteString
archiveName name = do
    guardI
        ( not (null name)
            && length (take 1025 name) <= 1024
            && all (\c -> c /= '\0' && c /= '/' && c /= '\\' && (c < '\xD800' || c > '\xDFFF')) name
            && name /= "."
            && name /= ".."
        )
        (InvalidData "NPZ key must be a nonempty flat name")
    let encoded = E.encodeUtf8 (T.pack (name ++ ".npy"))
    guardI (B.length encoded < 65535) (LimitExceeded "NPZ member name")
    Right encoded

{- | Checks directory/local consistency, CRC, exact deflate length, duplicate
names, overlapping member ranges and aggregate expanded bytes. Data
descriptors/encryption/multi-disk/ZIP64 directories are explicitly rejected.
-}
decodeNpz :: Limits -> B.ByteString -> IO (Either InterchangeError [(String, Array)])
decodeNpz lim input = case directory of
    Left err -> pure (Left err)
    Right members -> fmap sequence (mapM unpack members)
  where
    directory = do
        checkLimits lim
        guardI (B.length input <= maxBytes lim && B.length input >= 22) (LimitExceeded "NPZ input size")
        end <- case [ i
                    | i <- [B.length input - 22, B.length input - 23 .. max 0 (B.length input - 65557)]
                    , B.take 4 (B.drop i input) == B.pack [80, 75, 5, 6]
                    , let tailBytes = B.drop i input
                    , B.length tailBytes >= 22
                    , fromIntegral (B.index tailBytes 20) + 256 * fromIntegral (B.index tailBytes 21)
                        == B.length tailBytes - 22
                    ] of
            i : _ -> Right i
            _ -> Left (InvalidData "ZIP end directory missing")
        (count, start, size) <- runDecoder endParser (B.drop end input)
        guardI (toInteger start + toInteger size == toInteger end) (InvalidData "central directory extent")
        entries <- runDecoder (replicateM count entryParser) (B.take size (B.drop start input))
        guardI
            (length (nub (map entryName entries)) == length entries)
            (InvalidData "duplicate archive member name")
        guardI
            (sum (map (toInteger . entrySize) entries) <= toInteger (maxBytes lim))
            (LimitExceeded "aggregate expanded bytes")
        members <- mapM (member start) entries
        let intervals = sortOn fst [(entryOffset e, z) | (e, _, _, z) <- members]
        guardI
            (and (zipWith (\(_, endOffset) (next, _) -> endOffset <= next) intervals (drop 1 intervals)))
            (InvalidData "overlapping ZIP members")
        Right members
    endParser = do
        signature 0x06054b50
        disk <- getWord16le
        directoryDisk <- getWord16le
        countDisk <- getWord16le
        count <- getWord16le
        unless
            (disk == 0 && directoryDisk == 0 && countDisk == count && count /= 65535)
            (fail "multi-disk/ZIP64 not supported")
        when (fromIntegral count > maxArchiveEntries lim) (fail "archive entry budget")
        size <- size32
        start <- size32
        comment <- getWord16le
        _ <- getByteString (fromIntegral comment)
        pure (fromIntegral count, start, size)
    signature expected = do
        actual <- getWord32le
        unless (actual == expected) (fail "ZIP signature")
    size32 = do
        x <- getWord32le
        when (toInteger x > toInteger (maxBytes lim)) (fail "ZIP size budget")
        pure (fromIntegral x)
    entryParser = do
        signature 0x02014b50
        _ <- getWord16le
        version <- getWord16le
        flags <- getWord16le
        method <- getWord16le
        unless
            (version <= 45 && flags .&. 0xf7ff == 0 && method `elem` [0, 8])
            (fail "unsupported ZIP flags/method/version")
        _ <- getWord16le
        _ <- getWord16le
        checksum <- getWord32le
        compressed <- size32
        expanded <- size32
        nl <- getWord16le
        el <- getWord16le
        cl <- getWord16le
        disk <- getWord16le
        _ <- getWord16le
        _ <- getWord32le
        offset <- size32
        unless (disk == 0) (fail "multi-disk member")
        name <- getByteString (fromIntegral nl)
        extra <- getByteString (fromIntegral el)
        _ <- getByteString (fromIntegral cl)
        _ <- either (fail . show) pure (runDecoder extras extra)
        pure (Entry name flags method checksum compressed expanded offset)
    extras = do
        empty <- isEmpty
        if empty
            then pure []
            else do
                ident <- getWord16le
                len <- getWord16le
                bytes <- getByteString (fromIntegral len)
                ((ident, bytes) :) <$> extras
    member directoryStart entry@(Entry name flags method checksum compressed expanded offset) = do
        guardI (offset >= 0 && offset < directoryStart) (InvalidData "local header offset")
        (payloadStart, len) <-
            runDecoder
                ( do
                    signature 0x04034b50
                    _ <- getWord16le
                    f <- getWord16le
                    m <- getWord16le
                    unless (f == flags && m == method) (fail "local/directory flags mismatch")
                    _ <- getWord16le
                    _ <- getWord16le
                    c <- getWord32le
                    cs <- getWord32le
                    us <- getWord32le
                    nl <- getWord16le
                    el <- getWord16le
                    n <- getByteString (fromIntegral nl)
                    e <- getByteString (fromIntegral el)
                    unless (n == name && c == checksum) (fail "local/directory name or CRC mismatch")
                    extra <- either (fail . show) pure (runDecoder extras e)
                    (actualU, actualC) <-
                        if us == 0xffffffff || cs == 0xffffffff
                            then case lookup 1 extra of
                                Nothing -> fail "missing ZIP64 local sizes"
                                Just bytes ->
                                    either
                                        (fail . show)
                                        pure
                                        ( runDecoder
                                            ( (,)
                                                <$> (if us == 0xffffffff then getWord64le else pure (fromIntegral us))
                                                <*> (if cs == 0xffffffff then getWord64le else pure (fromIntegral cs))
                                            )
                                            bytes
                                        )
                            else pure (fromIntegral us, fromIntegral cs)
                    unless
                        (actualU == fromIntegral expanded && actualC == fromIntegral compressed)
                        (fail "local/directory size mismatch")
                    consumed <- bytesRead
                    _ <- getRemainingLazyByteString
                    pure (offset + fromIntegral consumed, compressed)
                )
                (B.take (directoryStart - offset) (B.drop offset input))
        guardI
            (toInteger payloadStart + toInteger len <= toInteger directoryStart)
            (InvalidData "ZIP payload overlaps directory")
        str <-
            either
                (const (Left (InvalidData "invalid UTF-8 archive key")))
                (Right . T.unpack)
                (E.decodeUtf8' name)
        guardI
            (length str >= 4 && drop (length str - 4) str == ".npy")
            (Unsupported "NPZ member must end .npy")
        let key = take (length str - 4) str
        canonical <- archiveName key
        guardI (canonical == name) (InvalidData "noncanonical NPZ member name")
        Right (entry, key, B.take len (B.drop payloadStart input), payloadStart + len)
    unpack (Entry _ _ method checksum _ expanded _, key, bytes, _) = do
        decoded <- if method == 0 then pure (Right bytes) else decompress lim RawDeflate expanded bytes
        pure $ do
            payload <- decoded
            guardI
                (B.length payload == expanded && crc32 payload == checksum)
                (InvalidData "ZIP uncompressed size/CRC mismatch")
            a <- decodeNpy lim payload
            Right (key, a)
