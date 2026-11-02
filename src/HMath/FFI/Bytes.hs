{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Owned strict bytes with stable, read-only ForeignPtr-backed spans.
module HMath.FFI.Bytes where

import Control.Exception (evaluate)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Internal as BI
import Data.Typeable (cast)
import Foreign hiding (copyBytes)
import Foreign.C
import Foreign.ForeignPtr.Unsafe (unsafeForeignPtrToPtr)
import qualified HMath.FFI.Boundary as B
import qualified HMath.FFI.Value as V

bytes :: BS.ByteString -> V.Value
bytes value = V.Opaque 450 (-1) (BS.length value) (evaluate (BS.length value) >> pure ()) value
asBytes :: V.Value -> IO BS.ByteString
asBytes (V.Opaque 450 _ _ _ value) = maybe (V.invalid "ByteString payload differs") pure (cast value)
asBytes _ = V.invalid "expected an immutable ByteString"

foreign export ccall "hm_bytes_copy" copyBytes :: Ptr Word8 -> CSize -> Ptr (StablePtr V.Value) -> IO CInt
copyBytes :: Ptr Word8 -> CSize -> Ptr (StablePtr V.Value) -> IO CInt
copyBytes pointer count out = B.boundary $ do
    value <- if count == 0 then pure BS.empty else BS.packCStringLen (castPtr pointer,fromIntegral count)
    B.checked (Right ()) (const (V.publish (bytes value) out))

foreign export ccall "hm_bytes_data" byteSpan :: StablePtr V.Value -> Ptr (Ptr Word8) -> Ptr CSize -> IO CInt
byteSpan :: StablePtr V.Value -> Ptr (Ptr Word8) -> Ptr CSize -> IO CInt
byteSpan input out count = B.boundary $ do
    value <- deRefStablePtr input >>= asBytes
    let (owner,offset,size)=BI.toForeignPtr value
        pointer=unsafeForeignPtrToPtr owner `plusPtr` offset
    poke out pointer
    poke count (fromIntegral size)
    touchForeignPtr owner
    pure 0
