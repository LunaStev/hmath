{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE FlexibleInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Direct original serialization, typed elements, streaming and mapped scopes.
module HMath.FFI.InterchangeAll where

import Control.Exception (IOException,catch,throwIO)
import Data.Binary.Get (Get)
import Data.Binary.Put (runPut)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as Lazy
import Foreign
import Foreign.C
import qualified System.IO as File
import HMath.FFI.InterchangeCodec
import qualified HMath.FFI.InterchangeElement as E
import qualified HMath.FFI.InterchangeError as Error
import qualified HMath.FFI.Boundary as Boundary
import qualified HMath.FFI.Value as V
import qualified HMath.Interchange.Array as A
import qualified HMath.Interchange.Binary as B
import qualified HMath.Interchange.Compression as C
import qualified HMath.Interchange.IO as I
import qualified HMath.Interchange.Numpy as N
import qualified HMath.Interchange.Text as T

instance From A.Array where from=unbox 451
instance To A.Array where to value=pure(box 451 value [to(A.arrayShape value),to(A.arrayBytes value)])
instance From A.InterchangeError where from=unbox 453
instance To A.InterchangeError where
    to value=pure(box 453 value [to(snd(Error.fields value))])
instance From A.Limits where from=unbox 457
instance To A.Limits where
    to value=pure(box 457 value [to(A.maxBytes value),to(A.maxElements value),to(A.maxRank value),to(A.maxMetadata value),to(A.maxArchiveEntries value)])
instance From A.DType where from=unbox 458
instance To A.DType where to value=pure(box 458 value [])
instance From A.Endian where from=unbox 459
instance To A.Endian where to value=pure(box 459 value [])
instance From A.Order where from=unbox 460
instance To A.Order where to value=pure(box 460 value [])
instance From C.Compression where from=unbox 461
instance To C.Compression where to value=pure(box 461 value [])
instance From I.RawSpec where from=unbox 462
instance To I.RawSpec where to value=pure(box 462 value [])

toValues :: forall a. A.Element a=>E.Element a->A.Array->IO V.Value
toValues witness array=do
    values<-Error.source(A.toValues array :: Either A.InterchangeError[a])
    pure(V.List(map(E.scalar witness) values))
toMatrix :: forall a. A.Element a=>E.Element a->A.Array->IO V.Value
toMatrix witness array=E.matrix witness <$>Error.source(A.toMatrix array)
toTensor :: forall a. A.Element a=>E.Element a->A.Array->IO V.Value
toTensor witness array=E.tensor witness <$>Error.source(A.toTensor array)
mappedValue :: forall a. A.Element a=>E.Element a->Mapping->[Int]->IO V.Value
mappedValue witness(Mapping mapped) index=I.mappedValue mapped index >>=Error.source >>=pure . E.scalar witness

ioErrors :: IO a->IO a
ioErrors action=action `catch` (\(errorValue::IOException)->throwIO(Error.Failure(A.InterchangeIOError(show errorValue))))
openHandle :: String->String->IO File.Handle
openHandle path mode=case mode of
    "rb"->ioErrors(File.openBinaryFile path File.ReadMode)
    "wb"->ioErrors(File.openBinaryFile path File.WriteMode)
    "ab"->ioErrors(File.openBinaryFile path File.AppendMode)
    "r+b"->ioErrors(File.openBinaryFile path File.ReadWriteMode)
    _->V.invalid "binary handle mode must be rb,wb,ab or r+b"
seekHandle :: File.Handle->Int->Integer->IO ()
seekHandle handle whence offset=case whence of
    0->ioErrors(File.hSeek handle File.AbsoluteSeek offset)
    1->ioErrors(File.hSeek handle File.RelativeSeek offset)
    2->ioErrors(File.hSeek handle File.SeekFromEnd offset)
    _->V.invalid "seek origin must be0,1 or2"

foreign export ccall "hm_interchange_apply" dispatch :: CString->Ptr(StablePtr V.Value)->CSize->Ptr(StablePtr V.Value)->IO CInt
dispatch :: CString->Ptr(StablePtr V.Value)->CSize->Ptr(StablePtr V.Value)->IO CInt
dispatch name input count out=Error.boundary $ do
    operation<-peekCString name
    arguments<-peekArray(fromIntegral count) input >>=mapM deRefStablePtr
    result<-case operation of
        "HMath.Interchange.Array.elementType"->do
            [prototype]<-pure arguments
            E.SomeElement witness<-E.element prototype
            to(E.code witness)
        "HMath.Interchange.Array.getElement"->do
            [prototype,endian]<-pure arguments
            E.SomeElement witness<-E.element prototype
            order<-from endian
            to(E.get witness order)
        "HMath.Interchange.Array.putElement"->do
            [prototype,endian,value]<-pure arguments
            E.SomeElement witness<-E.element prototype
            order<-from endian
            E.put witness order value >>=to
        "HMath.Interchange.Array.fromValues"->do
            [prototype,limits,endian,shape,items]<-pure arguments
            E.SomeElement witness<-E.element prototype
            policy<-from limits;order<-from endian;dims<-from shape
            values<-E.values witness items
            to(A.fromValues policy order dims values)
        "HMath.Interchange.Array.toValues"->do
            [prototype,value]<-pure arguments
            E.SomeElement witness<-E.element prototype
            from value >>=toValues witness
        "HMath.Interchange.Array.fromMatrix"->do
            [limits,endian,value]<-pure arguments
            policy<-from limits;order<-from endian
            E.fromMatrix policy order value >>=to
        "HMath.Interchange.Array.fromTensor"->do
            [limits,endian,value]<-pure arguments
            policy<-from limits;order<-from endian
            E.fromTensor policy order value >>=to
        "HMath.Interchange.Array.toMatrix"->do
            [prototype,value]<-pure arguments
            E.SomeElement witness<-E.element prototype
            from value >>=toMatrix witness
        "HMath.Interchange.Array.toTensor"->do
            [prototype,value]<-pure arguments
            E.SomeElement witness<-E.element prototype
            from value >>=toTensor witness
        "HMath.Interchange.Binary.runDecoder"->apply(B.runDecoder :: Get V.Value->BS.ByteString->Either A.InterchangeError V.Value) arguments
        "HMath.Interchange.IO.mappedValue"->do
            [prototype,value,index]<-pure arguments
            E.SomeElement witness<-E.element prototype
            mapping<-from value;coordinates<-from index
            mappedValue witness mapping coordinates
        "HMath.Interchange.IO.mappedShape"->do
            [value]<-pure arguments
            Mapping mapped<-from value
            to(I.mappedShape mapped)
        "HMath.Interchange.IO.mappedReadBytes"->do
            [value,offset,size]<-pure arguments
            Mapping mapped<-from value
            start<-from offset;lengthValue<-from size
            to(I.mappedReadBytes mapped start lengthValue)
        "HMath.Interchange.IO.withMappedArray"->do
            [limits,specification,path,callback]<-pure arguments
            policy<-from limits;layout<-from specification;filename<-from path
            action<-from callback :: IO(Mapping->IO V.Value)
            I.withMappedArray policy layout filename (action . Mapping) >>=to
-- BEGIN GENERATED
        "HMath.Interchange.Array.BigEndian"->apply A.BigEndian arguments
        "HMath.Interchange.Array.Bool8"->apply A.Bool8 arguments
        "HMath.Interchange.Array.C128"->apply A.C128 arguments
        "HMath.Interchange.Array.C64"->apply A.C64 arguments
        "HMath.Interchange.Array.COrder"->apply A.COrder arguments
        "HMath.Interchange.Array.F32"->apply A.F32 arguments
        "HMath.Interchange.Array.F64"->apply A.F64 arguments
        "HMath.Interchange.Array.FOrder"->apply A.FOrder arguments
        "HMath.Interchange.Array.I16"->apply A.I16 arguments
        "HMath.Interchange.Array.I32"->apply A.I32 arguments
        "HMath.Interchange.Array.I64"->apply A.I64 arguments
        "HMath.Interchange.Array.I8"->apply A.I8 arguments
        "HMath.Interchange.Array.InterchangeIOError"->apply A.InterchangeIOError arguments
        "HMath.Interchange.Array.InvalidData"->apply A.InvalidData arguments
        "HMath.Interchange.Array.LimitExceeded"->apply A.LimitExceeded arguments
        "HMath.Interchange.Array.Limits"->apply A.Limits arguments
        "HMath.Interchange.Array.LittleEndian"->apply A.LittleEndian arguments
        "HMath.Interchange.Array.U16"->apply A.U16 arguments
        "HMath.Interchange.Array.U32"->apply A.U32 arguments
        "HMath.Interchange.Array.U64"->apply A.U64 arguments
        "HMath.Interchange.Array.U8"->apply A.U8 arguments
        "HMath.Interchange.Array.Unsupported"->apply A.Unsupported arguments
        "HMath.Interchange.Array.array"->apply A.array arguments
        "HMath.Interchange.Array.arrayBytes"->apply A.arrayBytes arguments
        "HMath.Interchange.Array.arrayDType"->apply A.arrayDType arguments
        "HMath.Interchange.Array.arrayEndian"->apply A.arrayEndian arguments
        "HMath.Interchange.Array.arrayMetadata"->apply A.arrayMetadata arguments
        "HMath.Interchange.Array.arrayOffset"->apply A.arrayOffset arguments
        "HMath.Interchange.Array.arrayShape"->apply A.arrayShape arguments
        "HMath.Interchange.Array.arrayStrides"->apply A.arrayStrides arguments
        "HMath.Interchange.Array.contiguousArray"->apply A.contiguousArray arguments
        "HMath.Interchange.Array.defaultLimits"->apply A.defaultLimits arguments
        "HMath.Interchange.Array.denseStrides"->apply A.denseStrides arguments
        "HMath.Interchange.Array.elementBytes"->apply A.elementBytes arguments
        "HMath.Interchange.Array.elementCount"->apply A.elementCount arguments
        "HMath.Interchange.Array.maxArchiveEntries"->apply A.maxArchiveEntries arguments
        "HMath.Interchange.Array.maxBytes"->apply A.maxBytes arguments
        "HMath.Interchange.Array.maxElements"->apply A.maxElements arguments
        "HMath.Interchange.Array.maxMetadata"->apply A.maxMetadata arguments
        "HMath.Interchange.Array.maxRank"->apply A.maxRank arguments
        "HMath.Interchange.Array.rawDecode"->apply A.rawDecode arguments
        "HMath.Interchange.Array.rawEncode"->apply A.rawEncode arguments
        "HMath.Interchange.Array.repack"->apply A.repack arguments
        "HMath.Interchange.Array.validateShape"->apply A.validateShape arguments
        "HMath.Interchange.Array.withMetadata"->apply A.withMetadata arguments
        "HMath.Interchange.Binary.crc32"->apply B.crc32 arguments
        "HMath.Interchange.Binary.decodeBinary"->apply B.decodeBinary arguments
        "HMath.Interchange.Binary.encodeBinary"->apply B.encodeBinary arguments
        "HMath.Interchange.Compression.Gzip"->apply C.Gzip arguments
        "HMath.Interchange.Compression.RawDeflate"->apply C.RawDeflate arguments
        "HMath.Interchange.Compression.Zlib"->apply C.Zlib arguments
        "HMath.Interchange.Compression.compress"->apply C.compress arguments
        "HMath.Interchange.Compression.compressionAvailable"->apply C.compressionAvailable arguments
        "HMath.Interchange.Compression.decompress"->apply C.decompress arguments
        "HMath.Interchange.IO.RawSpec"->apply I.RawSpec arguments
        "HMath.Interchange.IO.readArrayFile"->apply I.readArrayFile arguments
        "HMath.Interchange.IO.readRawChunks"->apply I.readRawChunks arguments
        "HMath.Interchange.IO.writeArrayFile"->apply I.writeArrayFile arguments
        "HMath.Interchange.IO.writeRawChunks"->apply I.writeRawChunks arguments
        "HMath.Interchange.Numpy.decodeNpy"->apply N.decodeNpy arguments
        "HMath.Interchange.Numpy.decodeNpz"->apply N.decodeNpz arguments
        "HMath.Interchange.Numpy.encodeNpy"->apply N.encodeNpy arguments
        "HMath.Interchange.Numpy.encodeNpz"->apply N.encodeNpz arguments
        "HMath.Interchange.Text.decodeDelimited"->apply T.decodeDelimited arguments
        "HMath.Interchange.Text.decodeMatrixMarket"->apply T.decodeMatrixMarket arguments
        "HMath.Interchange.Text.decodeText"->apply T.decodeText arguments
        "HMath.Interchange.Text.encodeDelimited"->apply T.encodeDelimited arguments
        "HMath.Interchange.Text.encodeMatrixMarket"->apply T.encodeMatrixMarket arguments
        "HMath.Interchange.Text.encodeText"->apply T.encodeText arguments
        "HMath.Interchange.Array.boundedInt"->apply A.boundedInt arguments
        "HMath.Interchange.Array.byteOffsets"->apply A.byteOffsets arguments
        "HMath.Interchange.Array.checkLimits"->apply A.checkLimits arguments
        "HMath.Interchange.Array.guardI"->apply A.guardI arguments
-- END GENERATED
        "__dtype_code"->apply(fromEnum :: A.DType->Int) arguments
        "__error_fields"->apply(\value->let(kind,message)=Error.fields value in(fromIntegral kind::Int,message)) arguments
        "__put_bytes"->apply(Lazy.toStrict . runPut) arguments
        "__open_handle"->apply openHandle arguments
        "__close_handle"->apply(\handle->ioErrors(File.hClose handle)) arguments
        "__seek_handle"->apply seekHandle arguments
        "__tell_handle"->apply(\handle->ioErrors(File.hTell handle)) arguments
        "__flush_handle"->apply(\handle->ioErrors(File.hFlush handle)) arguments
        "__equal_array"->apply((==)::A.Array->A.Array->Bool) arguments
        _->V.invalid "unknown interchange operation"
    V.forceValue result
    Boundary.checked(Right())(const(V.publish result out))
