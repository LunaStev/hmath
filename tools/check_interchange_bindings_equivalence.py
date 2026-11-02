# SPDX-License-Identifier: MPL-2.0
"""Independent source oracle for fixed-width array, format and scoped IO APIs."""

import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from check_polynomial_equivalence import HASKELL, bits, close
from generate_graph_bindings import snake

ROOT = Path(__file__).resolve().parent.parent
ELEMENTS = [
    ("bool", "Bool", [True, False, False, True], "[True,False,False,True]"),
    ("int8", "Int8", [-128, -1, 0, 127], "[-128,-1,0,127]"),
    ("uint8", "Word8", [0, 1, 128, 255], "[0,1,128,255]"),
    ("int16", "Int16", [-32768, -1, 0, 32767], "[-32768,-1,0,32767]"),
    ("uint16", "Word16", [0, 1, 32768, 65535], "[0,1,32768,65535]"),
    ("int32", "Int32", [-(2**31), -1, 0, 2**31 - 1], "[-2147483648,-1,0,2147483647]"),
    ("uint32", "Word32", [0, 1, 2**31, 2**32 - 1], "[0,1,2147483648,4294967295]"),
    (
        "int64",
        "Int64",
        [-(2**63), -(2**53) - 1, 2**53 + 1, 2**63 - 1],
        "[-9223372036854775808,-9007199254740993,9007199254740993,9223372036854775807]",
    ),
    (
        "uint64",
        "Word64",
        [0, 1, 2**53 + 1, 2**64 - 1],
        "[0,1,9007199254740993,18446744073709551615]",
    ),
    ("float32", "Float", [0.0, 1 / 3, -0.0, 1.0], "[0,1/3,(-0.0),1]"),
    ("float64", "Double", [0.0, 1 / 3, -0.0, 1.0], "[0,1/3,(-0.0),1]"),
    (
        "complex64",
        "Complex Float",
        [1 + 2j, 3 - 4j, 0j, 1j],
        "[1:+2,3:+(-4),0:+0,0:+1]",
    ),
    (
        "complex128",
        "Complex Double",
        [1 + 2j, 3 - 4j, 0j, 1j],
        "[1:+2,3:+(-4),0:+0,0:+1]",
    ),
]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--library", required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(Path(args.library).resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    from _hmath_native import algebra_api
    from _hmath_native import interchange as i
    from _hmath_native._bytes import Bytes
    from _hmath_native._interchange_error import InterchangeError
    from _hmath_native._matrix_base import Matrix
    from _hmath_native._tensor_object import Tensor

    owners = []
    tests = []
    expressions = []
    covered = set()

    def own(value):
        owners.append(value)
        return value

    limits = own(i.default_limits())
    little = own(i.little_endian())
    big = own(i.big_endian())
    c = own(i.c_order())
    f = own(i.f_order())
    dtype = own(i.f64())
    array = own(
        i.from_values(limits, little, [2, 2], [1.5, -0.0, 3.0, 4.0], dtype="float64")
    )
    binary = own(i.encode_binary(limits, array))
    raw = own(i.raw_encode(limits, little, c, array))
    npy = own(i.encode_npy(limits, c, array))
    text = own(i.encode_text(limits, array))
    csv = own(i.encode_delimited(limits, ",", array))
    market = own(i.encode_matrix_market(limits, array))

    def encode(value, precision=64):
        if isinstance(value, Bytes):
            return "BYTES" + str(list(bytes(value))).replace(" ", "")
        if isinstance(value, i.Array):
            fields = [
                i.array_d_type(value),
                i.array_endian(value),
                i.array_shape(value),
                i.array_strides(value),
                i.array_offset(value),
                i.array_bytes(value),
                i.array_metadata(value),
            ]
            try:
                return "ARR(" + ",".join(encode(x, precision) for x in fields) + ")"
            finally:
                close(fields)
        if isinstance(value, i.DType):
            return "DT" + str(i.dtype_code(value))
        if isinstance(value, i.Endian):
            with (
                i.put_element(value, 4660, dtype="uint16") as program,
                i.put_bytes(program) as data,
            ):
                return "EN" + encode(data)
        if isinstance(value, i.Order):
            return "ORDER" + encode(i.dense_strides(value, 8, [2, 3]))
        if isinstance(value, i.Compression):
            try:
                with i.compress(limits, value, b"hello\0hello") as data:
                    return "COMP" + encode(data)
            except hmath.HMathError as error:
                return "COMP!" + encode(error.interchange_error)
        if isinstance(value, i.Limits):
            return "LIMITS" + encode(
                (
                    i.max_bytes(value),
                    i.max_elements(value),
                    i.max_rank(value),
                    i.max_metadata(value),
                    i.max_archive_entries(value),
                )
            )
        if isinstance(value, i.PutProgram):
            with i.put_bytes(value) as data:
                return encode(data)
        if isinstance(value, InterchangeError):
            return "ERR" + str(int(value.kind)) + "(" + encode(value.message) + ")"
        if isinstance(value, Matrix):
            return (
                "M"
                + str(value.shape[0])
                + ":"
                + str(value.shape[1])
                + "["
                + ",".join(encode(x, precision) for x in value.to_list())
                + "]"
            )
        if isinstance(value, Tensor):
            return (
                "TENSOR("
                + encode(algebra_api.tensor_dimensions(value), precision)
                + ","
                + encode(algebra_api.tensor_elements(value), precision)
                + ")"
            )
        if value is None:
            return "N"
        if isinstance(value, tuple) and not value:
            return "N"
        if isinstance(value, bool):
            return "B1" if value else "B0"
        if isinstance(value, int):
            return "I" + str(value)
        if isinstance(value, float):
            return f"F{precision}:" + str(bits(value, precision))
        if isinstance(value, complex):
            return (
                f"C{precision}:"
                + str(bits(value.real, precision))
                + ":"
                + str(bits(value.imag, precision))
            )
        if isinstance(value, str):
            return "L[" + ",".join("I" + str(ord(x)) for x in value) + "]"
        if isinstance(value, (list, tuple)):
            return (
                ("T[" if isinstance(value, tuple) else "L[")
                + ",".join(encode(x, precision) for x in value)
                + "]"
            )
        raise TypeError(type(value))

    def add(
        name,
        arguments,
        expression,
        checked=False,
        kwargs=None,
        precision=64,
        io=False,
        function=None,
    ):
        covered.add(name)
        tests.append(
            (
                function or getattr(i, snake(name)),
                arguments,
                kwargs or {},
                precision,
                name,
            )
        )
        expressions.append(
            ("fmap " + ("ic" if checked else "enc") + " (" + expression + ")")
            if io
            else "pure(" + ("ic" if checked else "enc") + "(" + expression + "))"
        )

    entries = json.loads(
        (ROOT / "bindings/schema/interchange-functions.json").read_text()
    )["functions"]
    constructors = {
        "Bool8",
        "I8",
        "U8",
        "I16",
        "U16",
        "I32",
        "U32",
        "I64",
        "U64",
        "F32",
        "F64",
        "C64",
        "C128",
        "LittleEndian",
        "BigEndian",
        "COrder",
        "FOrder",
        "RawDeflate",
        "Zlib",
        "Gzip",
    }
    for e in entries:
        if e["name"] in constructors:
            add(e["name"], [], "I." + e["name"])
    for name in ("InvalidData", "Unsupported", "LimitExceeded", "InterchangeIOError"):
        add(name, ["message\0α"], "I." + name + ' "message\\NULα"')
    add("Limits", [1024, 100, 3, 256, 4], "I.Limits 1024 100 3 256 4")
    add("defaultLimits", [], "I.defaultLimits")
    for name in (
        "maxBytes",
        "maxElements",
        "maxRank",
        "maxMetadata",
        "maxArchiveEntries",
    ):
        add(name, [limits], "I." + name + " lim")
    add(
        "array",
        [limits, dtype, little, [2, 2], [16, 8], 0, raw],
        "I.array lim I.F64 I.LittleEndian [2,2] [16,8] 0 raw",
        True,
    )
    add(
        "contiguousArray",
        [limits, dtype, little, c, [2, 2], raw],
        "I.contiguousArray lim I.F64 I.LittleEndian I.COrder [2,2] raw",
        True,
    )
    for name in (
        "arrayBytes",
        "arrayDType",
        "arrayEndian",
        "arrayMetadata",
        "arrayOffset",
        "arrayShape",
        "arrayStrides",
        "elementCount",
        "byteOffsets",
    ):
        add(name, [array], "I." + name + " arr")
    add("denseStrides", [f, 8, [2, 3]], "I.denseStrides I.FOrder 8 [2,3]")
    add("elementBytes", [dtype], "I.elementBytes I.F64")
    add("validateShape", [limits, [2, 3]], "I.validateShape lim [2,3]", True)
    add(
        "withMetadata",
        [limits, [("title", "α\0"), ("unit", "m")], array],
        'I.withMetadata lim [("title","α\\NUL"),("unit","m")] arr',
        True,
    )
    add(
        "rawEncode",
        [limits, big, f, array],
        "I.rawEncode lim I.BigEndian I.FOrder arr",
        True,
    )
    add(
        "rawDecode",
        [limits, dtype, little, c, [2, 2], raw],
        "I.rawDecode lim I.F64 I.LittleEndian I.COrder [2,2] raw",
        True,
    )
    add(
        "repack", [limits, big, f, array], "I.repack lim I.BigEndian I.FOrder arr", True
    )
    add("boundedInt", ["budget", 100, 101], 'I.boundedInt "budget" 100 101', True)
    add("checkLimits", [limits], "I.checkLimits lim", True)
    add(
        "guardI",
        [False, i.invalid_data("failed")],
        'I.guardI False(I.InvalidData "failed")',
        True,
    )
    for name, data, hsdata in [
        ("decodeBinary", binary, "binary"),
        ("decodeNpy", npy, "npy"),
        ("decodeText", text, "text"),
        ("decodeMatrixMarket", market, "market"),
    ]:
        add(name, [limits, data], "I." + name + " lim " + hsdata, True)
    for name in ("encodeBinary", "encodeText", "encodeMatrixMarket"):
        add(name, [limits, array], "I." + name + " lim arr", True)
    add(
        "crc32",
        [b"hello\0world"],
        "I.crc32(B.pack [104,101,108,108,111,0,119,111,114,108,100])",
    )
    add("encodeNpy", [limits, f, array], "I.encodeNpy lim I.FOrder arr", True)
    add("encodeDelimited", [limits, ",", array], "I.encodeDelimited lim ',' arr", True)
    add(
        "decodeDelimited",
        [limits, ",", dtype, csv],
        "I.decodeDelimited lim ',' I.F64 csv",
        True,
    )
    add("compressionAvailable", [], "I.compressionAvailable", io=True)
    for dtype_name, hstype, values, hsvalues in ELEMENTS:
        precision = 32 if dtype_name in ("float32", "complex64") else 64
        for endian, hsendian in [(little, "I.LittleEndian"), (big, "I.BigEndian")]:
            typed_array = own(
                i.from_values(limits, endian, [2, 2], values, dtype=dtype_name)
            )
            source = (
                "right(I.fromValues lim "
                + hsendian
                + " [2,2] ("
                + hsvalues
                + "::["
                + hstype
                + "]))"
            )
            add(
                "elementType",
                [],
                "I.elementType(Proxy::Proxy(" + hstype + "))",
                kwargs={"dtype": dtype_name},
            )
            add(
                "fromValues",
                [limits, endian, [2, 2], values],
                "I.fromValues lim "
                + hsendian
                + " [2,2] ("
                + hsvalues
                + "::["
                + hstype
                + "])",
                True,
                {"dtype": dtype_name},
                precision,
            )
            add(
                "toValues",
                [typed_array],
                "I.toValues("
                + source
                + ")::Either I.InterchangeError ["
                + hstype
                + "]",
                True,
                {"dtype": dtype_name},
                precision,
            )
            add(
                "toMatrix",
                [typed_array],
                "I.toMatrix("
                + source
                + ")::Either I.InterchangeError(M.Matrix("
                + hstype
                + "))",
                True,
                {"dtype": dtype_name},
                precision,
            )
            add(
                "toTensor",
                [typed_array],
                "I.toTensor("
                + source
                + ")::Either I.InterchangeError(T.Tensor("
                + hstype
                + "))",
                True,
                {"dtype": dtype_name},
                precision,
            )
            matrix = own(i.to_matrix(typed_array, dtype=dtype_name))
            tensor = own(i.to_tensor(typed_array, dtype=dtype_name))
            add(
                "fromMatrix",
                [limits, endian, matrix],
                "I.fromMatrix lim "
                + hsendian
                + "(right(M.fromListChecked 2 2 ("
                + hsvalues
                + "::["
                + hstype
                + "])))",
                True,
                precision=precision,
            )
            add(
                "fromTensor",
                [limits, endian, tensor],
                "I.fromTensor lim "
                + hsendian
                + "(right(T.tensor [2,2] ("
                + hsvalues
                + "::["
                + hstype
                + "])))",
                True,
                precision=precision,
            )
            program = own(i.get_element(endian, dtype=dtype_name))
            put = own(i.put_element(endian, values[1], dtype=dtype_name))
            data = own(i.put_bytes(put))
            add(
                "putElement",
                [endian, values[1]],
                "I.putElement "
                + hsendian
                + " (("
                + hsvalues
                + "::["
                + hstype
                + "])!!1)",
                kwargs={"dtype": dtype_name},
                precision=precision,
            )
            add(
                "getElement",
                [endian],
                "I.runDecoder(I.getElement "
                + hsendian
                + "::Get("
                + hstype
                + "))(BL.toStrict(runPut(I.putElement "
                + hsendian
                + " (("
                + hsvalues
                + "::["
                + hstype
                + "])!!1))))",
                True,
                {"dtype": dtype_name},
                precision,
                function=lambda en, dtype=dtype_name, data=data: i.run_decoder(
                    i.get_element(en, dtype=dtype), data
                ),
            )
            add(
                "runDecoder",
                [program, data],
                "I.runDecoder(I.getElement "
                + hsendian
                + "::Get("
                + hstype
                + "))(BL.toStrict(runPut(I.putElement "
                + hsendian
                + " (("
                + hsvalues
                + "::["
                + hstype
                + "])!!1))))",
                True,
                precision=precision,
            )
    compression_available = i.compression_available()
    for method, constructor in [
        ("raw_deflate", "RawDeflate"),
        ("zlib", "Zlib"),
        ("gzip", "Gzip"),
    ]:
        codec = own(getattr(i, method)())
        add(
            "compress",
            [limits, codec, b"hello\0hello"],
            "I.compress lim I." + constructor + " payload",
            True,
            io=True,
        )
        if compression_available:
            compressed = own(i.compress(limits, codec, b"hello\0hello"))
            add(
                "decompress",
                [limits, codec, 11, compressed],
                "I.compress lim I."
                + constructor
                + " payload >>= either(pure.Left)(I.decompress lim I."
                + constructor
                + " 11)",
                True,
                io=True,
            )
    archive = own(i.encode_npz(limits, False, [("alpha", array)]))
    add(
        "encodeNpz",
        [limits, False, [("alpha", array)]],
        'I.encodeNpz lim False [("alpha",arr)]',
        True,
        io=True,
    )
    add(
        "decodeNpz",
        [limits, archive],
        'I.encodeNpz lim False [("alpha",arr)] >>= either(pure.Left)(I.decodeNpz lim)',
        True,
        io=True,
    )
    specification = own(i.raw_spec(dtype, little, c, [2, 2]))

    def scoped_observation(operation, spec=specification, payload=raw):
        with tempfile.TemporaryDirectory(prefix="hmath-bindings-map-") as directory:
            path = Path(directory) / "array.raw"
            path.write_bytes(bytes(payload))

            def callback(mapping):
                if operation == "shape":
                    return i.mapped_shape(mapping)
                if operation == "bytes":
                    return i.mapped_read_bytes(mapping, 8, 16)
                if operation == "value":
                    return i.mapped_value(mapping, [1, 0])
                return (
                    i.mapped_shape(mapping),
                    i.mapped_read_bytes(mapping, 8, 16),
                    i.mapped_value(mapping, [1, 0]),
                )

            return i.with_mapped_array(limits, spec, path, callback)

    for name, operation, expression in [
        ("mappedShape", "shape", "mapShape"),
        ("mappedReadBytes", "bytes", "mapBytes"),
        ("mappedValue", "value", "mapValue"),
        ("withMappedArray", "all", "mapAll"),
        ("RawSpec", "all", "mapAll"),
    ]:
        add(
            name,
            [],
            expression,
            True,
            io=True,
            function=lambda operation=operation: scoped_observation(operation),
        )

    def read_file():
        with tempfile.TemporaryDirectory(prefix="hmath-bindings-read-") as directory:
            path = Path(directory) / "array.hmath"
            path.write_bytes(bytes(binary))
            return i.read_array_file(
                limits, lambda data: i.decode_binary(limits, data), path
            )

    def write_file():
        with tempfile.TemporaryDirectory(prefix="hmath-bindings-write-") as directory:
            path = Path(directory) / "array.hmath"
            i.write_array_file(
                limits,
                lambda budget, value: i.encode_binary(budget, value),
                path,
                array,
            )
            return own(i.Bytes(path.read_bytes()))

    def read_chunks():
        with tempfile.TemporaryDirectory(prefix="hmath-bindings-stream-") as directory:
            path = Path(directory) / "array.raw"
            path.write_bytes(bytes(raw))
            observed = []

            def consume(value):
                observed.append(i.to_values(value))
                return True

            with i.open_handle(path, "rb") as handle:
                i.read_raw_chunks(limits, specification, 2, handle, consume)
            return observed

    def write_chunks():
        with tempfile.TemporaryDirectory(prefix="hmath-bindings-stream-") as directory:
            path = Path(directory) / "array.raw"
            chunks = [bytes(raw)[:16], bytes(raw)[16:]]
            requests = []

            def produce(maximum):
                requests.append(maximum)
                return chunks.pop(0) if chunks else None

            with i.open_handle(path, "wb") as handle:
                i.write_raw_chunks(limits, specification, 2, handle, produce)
            return requests, own(i.Bytes(path.read_bytes()))

    for name, function, expression in [
        ("readArrayFile", read_file, "readFileArray"),
        ("writeArrayFile", write_file, "writeFileArray"),
        ("readRawChunks", read_chunks, "readChunks"),
        ("writeRawChunks", write_chunks, "writeChunks"),
    ]:
        add(name, [], expression, True, io=True, function=function)
    for type_name, hstype, values, hsvalues in ELEMENTS:

        def mapped_typed(type_name=type_name, values=values):
            with (
                i.from_values(limits, big, [2, 2], values, dtype=type_name) as value,
                i.raw_encode(limits, big, f, value) as encoded,
                i.element_type(dtype=type_name) as element,
                i.raw_spec(element, big, f, [2, 2]) as spec,
                tempfile.TemporaryDirectory(prefix="hmath-typed-map-") as directory,
            ):
                path = Path(directory) / "typed.raw"
                path.write_bytes(bytes(encoded))
                return i.with_mapped_array(
                    limits,
                    spec,
                    path,
                    lambda mapping: i.mapped_value(mapping, [1, 0], dtype=type_name),
                )

        add(
            "mappedValue",
            [],
            "mapTyped(Proxy::Proxy("
            + hstype
            + "))("
            + hsvalues
            + "::["
            + hstype
            + "])",
            True,
            precision=32 if type_name in ("float32", "complex64") else 64,
            io=True,
            function=mapped_typed,
        )
    imports = """import qualified HMath.Interchange as I
import qualified HMath.Interchange.Array as IA
import qualified HMath.Interchange.Binary as IB
import qualified HMath.Tensor as T
import Data.Binary.Get(Get)
import Data.Binary.Put(Put,runPut)
import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as BL
import Data.Proxy(Proxy(..))
import Data.Int
import Data.Word
import Data.Char(ord)
import System.IO.Unsafe(unsafePerformIO)
import qualified System.IO as File
import Data.IORef
import Control.Monad(join)
"""
    source = HASKELL.split("pR=")[0].replace(
        "import qualified HMath.Polynomial as P",
        imports + "\nimport qualified HMath.Polynomial as P",
    )
    source = "{-# LANGUAGE RankNTypes #-}\n" + source
    source += (
        """instance E Char where enc x="I"++show(ord x)
instance E Int8 where enc x="I"++show x
instance E Int16 where enc x="I"++show x
instance E Int32 where enc x="I"++show x
instance E Int64 where enc x="I"++show x
instance E Word8 where enc x="I"++show x
instance E Word16 where enc x="I"++show x
instance E Word32 where enc x="I"++show x
instance E Word64 where enc x="I"++show x
instance E () where enc ()="N"
instance E B.ByteString where enc x="BYTES["++intercalate ","(map show(B.unpack x))++"]"
instance E Put where enc=enc . BL.toStrict . runPut
instance(E a,E b,E c,E d,E e)=>E(a,b,c,d,e)where enc(a,b,c,d,e)="T["++intercalate ","[enc a,enc b,enc c,enc d,enc e]++"]"
instance E I.DType where enc x="DT"++show(fromEnum x)
instance E I.Endian where enc x="EN"++enc(I.putElement x (4660::Word16))
instance E I.Order where enc x="ORDER"++enc(I.denseStrides x 8 [2,3])
instance E I.Compression where enc x="COMP"++ic(unsafePerformIO(I.compress I.defaultLimits x payload))
instance E I.Limits where enc x="LIMITS"++enc(I.maxBytes x,I.maxElements x,I.maxRank x,I.maxMetadata x,I.maxArchiveEntries x)
instance E I.InterchangeError where enc errorValue=case errorValue of I.InvalidData x->"ERR0("++enc x++")";I.Unsupported x->"ERR1("++enc x++")";I.LimitExceeded x->"ERR2("++enc x++")";I.InterchangeIOError x->"ERR3("++enc x++")"
instance E I.Array where enc x="ARR("++intercalate ","[enc(I.arrayDType x),enc(I.arrayEndian x),enc(I.arrayShape x),enc(I.arrayStrides x),enc(I.arrayOffset x),enc(I.arrayBytes x),enc(I.arrayMetadata x)]++")"
instance E a=>E(T.Tensor a)where enc x="TENSOR("++enc(T.tensorShape x)++","++enc(T.tensorValues x)++")"
ic :: E a=>Either I.InterchangeError a->String
ic=either (("!"++).enc)enc
right :: Show e=>Either e a->a
right=either(error.show)id
lim=I.defaultLimits
arr=right(I.fromValues lim I.LittleEndian [2,2] [1.5,(-0.0),3,4::Double])
binary=right(I.encodeBinary lim arr)
raw=right(I.rawEncode lim I.LittleEndian I.COrder arr)
npy=right(I.encodeNpy lim I.COrder arr)
text=right(I.encodeText lim arr)
csv=right(I.encodeDelimited lim ',' arr)
market=right(I.encodeMatrixMarket lim arr)
payload=B.pack [104,101,108,108,111,0,104,101,108,108,111]
spec=I.RawSpec I.F64 I.LittleEndian I.COrder [2,2]
rawPath="ORACLE_DIRECTORY/input.raw"
binaryPath="ORACLE_DIRECTORY/input.hmath"
outputPath="ORACLE_DIRECTORY/output.hmath"
streamPath="ORACLE_DIRECTORY/output.raw"
mapped :: (forall s. I.MappedArray s->IO a)->IO(Either I.InterchangeError a)
mapped action=B.writeFile rawPath raw >>I.withMappedArray lim spec rawPath action
mapShape=mapped(pure . I.mappedShape)
mapBytes=fmap join(mapped(\\mapping->I.mappedReadBytes mapping 8 16))
mapValue=fmap join(mapped(\\mapping->I.mappedValue mapping [1,0]::IO(Either I.InterchangeError Double)))
mapAll=mapped(\\mapping->do bytes<-right <$>I.mappedReadBytes mapping 8 16;number<-right <$>I.mappedValue mapping [1,0]::IO Double;pure(I.mappedShape mapping,bytes,number))
readFileArray=B.writeFile binaryPath binary >>I.readArrayFile lim (I.decodeBinary lim) binaryPath
writeFileArray=do result<-I.writeArrayFile lim I.encodeBinary outputPath arr;bytes<-B.readFile outputPath;pure(bytes <$ result)
readChunks=do
    B.writeFile rawPath raw
    ref<-newIORef []
    result<-File.withBinaryFile rawPath File.ReadMode(\\handle->I.readRawChunks lim spec 2 handle(\\value->modifyIORef' ref(++[right(I.toValues value)::[Double]]) >>pure(Right True)))
    observed<-readIORef ref
    pure(observed <$result)
writeChunks=do
    ref<-newIORef[B.take 16 raw,B.drop 16 raw]
    calls<-newIORef []
    let produce amount=do modifyIORef' calls(++[amount]);pieces<-readIORef ref;case pieces of {[]->pure(Right Nothing);piece:rest->writeIORef ref rest >>pure(Right(Just piece))}
    result<-File.withBinaryFile streamPath File.WriteMode(\\handle->I.writeRawChunks lim spec 2 handle produce)
    requests<-readIORef calls;bytes<-B.readFile streamPath
    pure((requests,bytes) <$result)
mapTyped :: I.Element a=>Proxy a->[a]->IO(Either I.InterchangeError a)
mapTyped proxy values=do
    let arrayValue=right(I.fromValues lim I.BigEndian [2,2] values)
        content=right(I.rawEncode lim I.BigEndian I.FOrder arrayValue)
        specification=I.RawSpec(I.elementType proxy)I.BigEndian I.FOrder[2,2]
    B.writeFile rawPath content
    I.withMappedArray lim specification rawPath(\\mapping->right <$>I.mappedValue mapping [1,0])
main=sequence [EXPRESSIONS] >>=mapM_ putStrLn
""".replace("EXPRESSIONS", ",\n    ".join(expressions))
        .replace("I.boundedInt", "IA.boundedInt")
        .replace("I.byteOffsets", "IA.byteOffsets")
        .replace("I.checkLimits", "IA.checkLimits")
        .replace("I.guardI", "IA.guardI")
        .replace("I.runDecoder", "IB.runDecoder")
    )
    with tempfile.TemporaryDirectory(prefix="hmath-interchange-oracle-") as temporary:
        path = Path(temporary) / "Oracle.hs"
        path.write_text(source.replace("ORACLE_DIRECTORY", temporary))
        command = [
            "ghc",
            "--make",
            "-O0",
            "-fmax-errors=3",
            "-isrc",
            "-outputdir",
            str(Path(temporary) / "build"),
            str(path),
            "cbits/interchange_io.c",
            "-o",
            str(Path(temporary) / "oracle"),
        ]
        if compression_available:
            command += ["-optc-DHMATH_HAVE_ZLIB", "-lz"]
        result = subprocess.run(
            command, cwd=ROOT, capture_output=True, text=True, check=False
        )
        if result.returncode:
            raise SystemExit(result.stderr)
        result = subprocess.run(
            [str(Path(temporary) / "oracle")],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode:
            raise SystemExit(result.stderr)
    lines = result.stdout.splitlines()
    if len(lines) != len(tests):
        raise AssertionError((len(lines), len(tests)))
    try:
        for (function, arguments, kwargs, precision, name), expected in zip(
            tests, lines
        ):
            try:
                result = function(*arguments, **kwargs)
                actual = encode(result, precision)
                close(result)
            except hmath.HMathError as error:
                actual = "!" + encode(error.interchange_error)
            if actual != expected:
                raise AssertionError((name, kwargs, actual, expected))
    finally:
        for owner in owners:
            owner.close()
    remaining = {e["name"] for e in entries} - covered
    print(
        f"Interchange direct Haskell equivalence: {len(tests)} cases;{len(covered)} named operations;13 exact Element instances; remaining scoped-IO contracts: {sorted(remaining)}"
    )


if __name__ == "__main__":
    main()
