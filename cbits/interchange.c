/* SPDX-License-Identifier: MPL-2.0 */
/* Generated; do not edit. */
#include "hmath_interchange.h"
#include "value_internal.h"
#include <stdlib.h>
extern int hm_interchange_apply(const char *,void *const *,size_t,void **);
static hmath_status invoke(hmath_context *context,const char *operation,const hmath_value *const *arguments,size_t count,hmath_value **out) {
    if(!out || (count && !arguments))return hm_error(HMATH_INVALID_ARGUMENT,"NULL interchange arguments/output");
    for(size_t i=0;i<count;++i)if(!arguments[i])return hm_error(HMATH_INVALID_ARGUMENT,"NULL interchange value");
    if(count>(size_t)PTRDIFF_MAX/sizeof(void *))return hm_error(HMATH_OVERFLOW,"interchange argument span overflow");
    void **stable=malloc((count?count:1)*sizeof *stable);
    if(!stable)return hm_error(HMATH_ALLOCATION_FAILED,"interchange arguments allocation failed");
    for(size_t i=0;i<count;++i)stable[i]=hm_value_stable(arguments[i]);
    hmath_value *result=NULL;
    hmath_status status=hm_value_begin(context,&result);
    if(status){free(stable);return status;}
    int code=hm_interchange_apply(operation,stable,count,&result->stable);
    free(stable);
    return hm_value_finish(result,code,out);
}
hmath_status hmath_interchange_value_big_endian(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Array.BigEndian",arguments,0,out);
}
hmath_status hmath_interchange_value_bool8(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Array.Bool8",arguments,0,out);
}
hmath_status hmath_interchange_value_c128(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Array.C128",arguments,0,out);
}
hmath_status hmath_interchange_value_c64(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Array.C64",arguments,0,out);
}
hmath_status hmath_interchange_value_c_order(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Array.COrder",arguments,0,out);
}
hmath_status hmath_interchange_value_f32(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Array.F32",arguments,0,out);
}
hmath_status hmath_interchange_value_f64(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Array.F64",arguments,0,out);
}
hmath_status hmath_interchange_value_f_order(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Array.FOrder",arguments,0,out);
}
hmath_status hmath_interchange_value_i16(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Array.I16",arguments,0,out);
}
hmath_status hmath_interchange_value_i32(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Array.I32",arguments,0,out);
}
hmath_status hmath_interchange_value_i64(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Array.I64",arguments,0,out);
}
hmath_status hmath_interchange_value_i8(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Array.I8",arguments,0,out);
}
hmath_status hmath_interchange_value_interchange_io_error(hmath_context *context, const hmath_value *message, hmath_value **out) {
    const hmath_value *arguments[]={message};
    return invoke(context,"HMath.Interchange.Array.InterchangeIOError",arguments,1,out);
}
hmath_status hmath_interchange_value_invalid_data(hmath_context *context, const hmath_value *message, hmath_value **out) {
    const hmath_value *arguments[]={message};
    return invoke(context,"HMath.Interchange.Array.InvalidData",arguments,1,out);
}
hmath_status hmath_interchange_value_limit_exceeded(hmath_context *context, const hmath_value *message, hmath_value **out) {
    const hmath_value *arguments[]={message};
    return invoke(context,"HMath.Interchange.Array.LimitExceeded",arguments,1,out);
}
hmath_status hmath_interchange_value_limits(hmath_context *context, const hmath_value *max_bytes, const hmath_value *max_elements, const hmath_value *max_rank, const hmath_value *max_metadata, const hmath_value *max_archive_entries, hmath_value **out) {
    const hmath_value *arguments[]={max_bytes,max_elements,max_rank,max_metadata,max_archive_entries};
    return invoke(context,"HMath.Interchange.Array.Limits",arguments,5,out);
}
hmath_status hmath_interchange_value_little_endian(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Array.LittleEndian",arguments,0,out);
}
hmath_status hmath_interchange_value_u16(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Array.U16",arguments,0,out);
}
hmath_status hmath_interchange_value_u32(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Array.U32",arguments,0,out);
}
hmath_status hmath_interchange_value_u64(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Array.U64",arguments,0,out);
}
hmath_status hmath_interchange_value_u8(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Array.U8",arguments,0,out);
}
hmath_status hmath_interchange_value_unsupported(hmath_context *context, const hmath_value *message, hmath_value **out) {
    const hmath_value *arguments[]={message};
    return invoke(context,"HMath.Interchange.Array.Unsupported",arguments,1,out);
}
hmath_status hmath_interchange_value_array(hmath_context *context, const hmath_value *lim, const hmath_value *dt, const hmath_value *en, const hmath_value *sh, const hmath_value *st, const hmath_value *off, const hmath_value *bs, hmath_value **out) {
    const hmath_value *arguments[]={lim,dt,en,sh,st,off,bs};
    return invoke(context,"HMath.Interchange.Array.array",arguments,7,out);
}
hmath_status hmath_interchange_value_array_bytes(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *arguments[]={value};
    return invoke(context,"HMath.Interchange.Array.arrayBytes",arguments,1,out);
}
hmath_status hmath_interchange_value_array_d_type(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *arguments[]={value};
    return invoke(context,"HMath.Interchange.Array.arrayDType",arguments,1,out);
}
hmath_status hmath_interchange_value_array_endian(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *arguments[]={value};
    return invoke(context,"HMath.Interchange.Array.arrayEndian",arguments,1,out);
}
hmath_status hmath_interchange_value_array_metadata(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *arguments[]={value};
    return invoke(context,"HMath.Interchange.Array.arrayMetadata",arguments,1,out);
}
hmath_status hmath_interchange_value_array_offset(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *arguments[]={value};
    return invoke(context,"HMath.Interchange.Array.arrayOffset",arguments,1,out);
}
hmath_status hmath_interchange_value_array_shape(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *arguments[]={value};
    return invoke(context,"HMath.Interchange.Array.arrayShape",arguments,1,out);
}
hmath_status hmath_interchange_value_array_strides(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *arguments[]={value};
    return invoke(context,"HMath.Interchange.Array.arrayStrides",arguments,1,out);
}
hmath_status hmath_interchange_value_contiguous_array(hmath_context *context, const hmath_value *lim, const hmath_value *dt, const hmath_value *en, const hmath_value *order, const hmath_value *sh, const hmath_value *bs, hmath_value **out) {
    const hmath_value *arguments[]={lim,dt,en,order,sh,bs};
    return invoke(context,"HMath.Interchange.Array.contiguousArray",arguments,6,out);
}
hmath_status hmath_interchange_value_default_limits(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Array.defaultLimits",arguments,0,out);
}
hmath_status hmath_interchange_value_dense_strides(hmath_context *context, const hmath_value *c_order, const hmath_value *w, const hmath_value *sh, hmath_value **out) {
    const hmath_value *arguments[]={c_order,w,sh};
    return invoke(context,"HMath.Interchange.Array.denseStrides",arguments,3,out);
}
hmath_status hmath_interchange_value_element_bytes(hmath_context *context, const hmath_value *dt, hmath_value **out) {
    const hmath_value *arguments[]={dt};
    return invoke(context,"HMath.Interchange.Array.elementBytes",arguments,1,out);
}
hmath_status hmath_interchange_value_element_count(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *arguments[]={value};
    return invoke(context,"HMath.Interchange.Array.elementCount",arguments,1,out);
}
hmath_status hmath_interchange_value_element_type(hmath_context *context, const hmath_value *prototype, hmath_value **out) {
    const hmath_value *arguments[]={prototype};
    return invoke(context,"HMath.Interchange.Array.elementType",arguments,1,out);
}
hmath_status hmath_interchange_value_from_matrix(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out) {
    const hmath_value *arguments[]={value,value2,value3};
    return invoke(context,"HMath.Interchange.Array.fromMatrix",arguments,3,out);
}
hmath_status hmath_interchange_value_from_tensor(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out) {
    const hmath_value *arguments[]={value,value2,value3};
    return invoke(context,"HMath.Interchange.Array.fromTensor",arguments,3,out);
}
hmath_status hmath_interchange_value_from_values(hmath_context *context, const hmath_value *prototype, const hmath_value *limits, const hmath_value *endian, const hmath_value *shape, const hmath_value *values, hmath_value **out) {
    const hmath_value *arguments[]={prototype,limits,endian,shape,values};
    return invoke(context,"HMath.Interchange.Array.fromValues",arguments,5,out);
}
hmath_status hmath_interchange_value_get_element(hmath_context *context, const hmath_value *prototype, const hmath_value *endian, hmath_value **out) {
    const hmath_value *arguments[]={prototype,endian};
    return invoke(context,"HMath.Interchange.Array.getElement",arguments,2,out);
}
hmath_status hmath_interchange_value_max_archive_entries(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *arguments[]={value};
    return invoke(context,"HMath.Interchange.Array.maxArchiveEntries",arguments,1,out);
}
hmath_status hmath_interchange_value_max_bytes(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *arguments[]={value};
    return invoke(context,"HMath.Interchange.Array.maxBytes",arguments,1,out);
}
hmath_status hmath_interchange_value_max_elements(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *arguments[]={value};
    return invoke(context,"HMath.Interchange.Array.maxElements",arguments,1,out);
}
hmath_status hmath_interchange_value_max_metadata(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *arguments[]={value};
    return invoke(context,"HMath.Interchange.Array.maxMetadata",arguments,1,out);
}
hmath_status hmath_interchange_value_max_rank(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *arguments[]={value};
    return invoke(context,"HMath.Interchange.Array.maxRank",arguments,1,out);
}
hmath_status hmath_interchange_value_put_element(hmath_context *context, const hmath_value *prototype, const hmath_value *endian, const hmath_value *value, hmath_value **out) {
    const hmath_value *arguments[]={prototype,endian,value};
    return invoke(context,"HMath.Interchange.Array.putElement",arguments,3,out);
}
hmath_status hmath_interchange_value_raw_decode(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, const hmath_value *value6, hmath_value **out) {
    const hmath_value *arguments[]={value,value2,value3,value4,value5,value6};
    return invoke(context,"HMath.Interchange.Array.rawDecode",arguments,6,out);
}
hmath_status hmath_interchange_value_raw_encode(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, hmath_value **out) {
    const hmath_value *arguments[]={value,value2,value3,value4};
    return invoke(context,"HMath.Interchange.Array.rawEncode",arguments,4,out);
}
hmath_status hmath_interchange_value_repack(hmath_context *context, const hmath_value *lim, const hmath_value *en, const hmath_value *order, const hmath_value *a, hmath_value **out) {
    const hmath_value *arguments[]={lim,en,order,a};
    return invoke(context,"HMath.Interchange.Array.repack",arguments,4,out);
}
hmath_status hmath_interchange_value_to_matrix(hmath_context *context, const hmath_value *prototype, const hmath_value *array, hmath_value **out) {
    const hmath_value *arguments[]={prototype,array};
    return invoke(context,"HMath.Interchange.Array.toMatrix",arguments,2,out);
}
hmath_status hmath_interchange_value_to_tensor(hmath_context *context, const hmath_value *prototype, const hmath_value *array, hmath_value **out) {
    const hmath_value *arguments[]={prototype,array};
    return invoke(context,"HMath.Interchange.Array.toTensor",arguments,2,out);
}
hmath_status hmath_interchange_value_to_values(hmath_context *context, const hmath_value *prototype, const hmath_value *array, hmath_value **out) {
    const hmath_value *arguments[]={prototype,array};
    return invoke(context,"HMath.Interchange.Array.toValues",arguments,2,out);
}
hmath_status hmath_interchange_value_validate_shape(hmath_context *context, const hmath_value *lim, const hmath_value *sh, hmath_value **out) {
    const hmath_value *arguments[]={lim,sh};
    return invoke(context,"HMath.Interchange.Array.validateShape",arguments,2,out);
}
hmath_status hmath_interchange_value_with_metadata(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, hmath_value **out) {
    const hmath_value *arguments[]={value,value2,value3};
    return invoke(context,"HMath.Interchange.Array.withMetadata",arguments,3,out);
}
hmath_status hmath_interchange_value_crc32(hmath_context *context, const hmath_value *value, hmath_value **out) {
    const hmath_value *arguments[]={value};
    return invoke(context,"HMath.Interchange.Binary.crc32",arguments,1,out);
}
hmath_status hmath_interchange_value_decode_binary(hmath_context *context, const hmath_value *lim, const hmath_value *input, hmath_value **out) {
    const hmath_value *arguments[]={lim,input};
    return invoke(context,"HMath.Interchange.Binary.decodeBinary",arguments,2,out);
}
hmath_status hmath_interchange_value_encode_binary(hmath_context *context, const hmath_value *lim, const hmath_value *a, hmath_value **out) {
    const hmath_value *arguments[]={lim,a};
    return invoke(context,"HMath.Interchange.Binary.encodeBinary",arguments,2,out);
}
hmath_status hmath_interchange_value_gzip(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Compression.Gzip",arguments,0,out);
}
hmath_status hmath_interchange_value_raw_deflate(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Compression.RawDeflate",arguments,0,out);
}
hmath_status hmath_interchange_value_zlib(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Compression.Zlib",arguments,0,out);
}
hmath_status hmath_interchange_value_compress(hmath_context *context, const hmath_value *lim, const hmath_value *wrapper, const hmath_value *input, hmath_value **out) {
    const hmath_value *arguments[]={lim,wrapper,input};
    return invoke(context,"HMath.Interchange.Compression.compress",arguments,3,out);
}
hmath_status hmath_interchange_value_compression_available(hmath_context *context, hmath_value **out) {
    const hmath_value *arguments[]={NULL};
    return invoke(context,"HMath.Interchange.Compression.compressionAvailable",arguments,0,out);
}
hmath_status hmath_interchange_value_decompress(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, hmath_value **out) {
    const hmath_value *arguments[]={value,value2,value3,value4};
    return invoke(context,"HMath.Interchange.Compression.decompress",arguments,4,out);
}
hmath_status hmath_interchange_value_raw_spec(hmath_context *context, const hmath_value *dtype, const hmath_value *endian, const hmath_value *order, const hmath_value *shape, hmath_value **out) {
    const hmath_value *arguments[]={dtype,endian,order,shape};
    return invoke(context,"HMath.Interchange.IO.RawSpec",arguments,4,out);
}
hmath_status hmath_interchange_value_mapped_read_bytes(hmath_context *context, const hmath_value *mapping, const hmath_value *offset, const hmath_value *count, hmath_value **out) {
    const hmath_value *arguments[]={mapping,offset,count};
    return invoke(context,"HMath.Interchange.IO.mappedReadBytes",arguments,3,out);
}
hmath_status hmath_interchange_value_mapped_shape(hmath_context *context, const hmath_value *mapping, hmath_value **out) {
    const hmath_value *arguments[]={mapping};
    return invoke(context,"HMath.Interchange.IO.mappedShape",arguments,1,out);
}
hmath_status hmath_interchange_value_mapped_value(hmath_context *context, const hmath_value *prototype, const hmath_value *mapping, const hmath_value *indices, hmath_value **out) {
    const hmath_value *arguments[]={prototype,mapping,indices};
    return invoke(context,"HMath.Interchange.IO.mappedValue",arguments,3,out);
}
hmath_status hmath_interchange_value_read_array_file(hmath_context *context, const hmath_value *lim, const hmath_value *decode, const hmath_value *path, hmath_value **out) {
    const hmath_value *arguments[]={lim,decode,path};
    return invoke(context,"HMath.Interchange.IO.readArrayFile",arguments,3,out);
}
hmath_status hmath_interchange_value_read_raw_chunks(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, hmath_value **out) {
    const hmath_value *arguments[]={value,value2,value3,value4,value5};
    return invoke(context,"HMath.Interchange.IO.readRawChunks",arguments,5,out);
}
hmath_status hmath_interchange_value_with_mapped_array(hmath_context *context, const hmath_value *limits, const hmath_value *specification, const hmath_value *path, const hmath_value *callback, hmath_value **out) {
    const hmath_value *arguments[]={limits,specification,path,callback};
    return invoke(context,"HMath.Interchange.IO.withMappedArray",arguments,4,out);
}
hmath_status hmath_interchange_value_write_array_file(hmath_context *context, const hmath_value *lim, const hmath_value *encode, const hmath_value *path, const hmath_value *a, hmath_value **out) {
    const hmath_value *arguments[]={lim,encode,path,a};
    return invoke(context,"HMath.Interchange.IO.writeArrayFile",arguments,4,out);
}
hmath_status hmath_interchange_value_write_raw_chunks(hmath_context *context, const hmath_value *value, const hmath_value *value2, const hmath_value *value3, const hmath_value *value4, const hmath_value *value5, hmath_value **out) {
    const hmath_value *arguments[]={value,value2,value3,value4,value5};
    return invoke(context,"HMath.Interchange.IO.writeRawChunks",arguments,5,out);
}
hmath_status hmath_interchange_value_decode_npy(hmath_context *context, const hmath_value *lim, const hmath_value *input, hmath_value **out) {
    const hmath_value *arguments[]={lim,input};
    return invoke(context,"HMath.Interchange.Numpy.decodeNpy",arguments,2,out);
}
hmath_status hmath_interchange_value_decode_npz(hmath_context *context, const hmath_value *lim, const hmath_value *input, hmath_value **out) {
    const hmath_value *arguments[]={lim,input};
    return invoke(context,"HMath.Interchange.Numpy.decodeNpz",arguments,2,out);
}
hmath_status hmath_interchange_value_encode_npy(hmath_context *context, const hmath_value *lim, const hmath_value *order, const hmath_value *a, hmath_value **out) {
    const hmath_value *arguments[]={lim,order,a};
    return invoke(context,"HMath.Interchange.Numpy.encodeNpy",arguments,3,out);
}
hmath_status hmath_interchange_value_encode_npz(hmath_context *context, const hmath_value *lim, const hmath_value *compressed, const hmath_value *arrays, hmath_value **out) {
    const hmath_value *arguments[]={lim,compressed,arrays};
    return invoke(context,"HMath.Interchange.Numpy.encodeNpz",arguments,3,out);
}
hmath_status hmath_interchange_value_decode_delimited(hmath_context *context, const hmath_value *lim, const hmath_value *separator, const hmath_value *dt, const hmath_value *bs, hmath_value **out) {
    const hmath_value *arguments[]={lim,separator,dt,bs};
    return invoke(context,"HMath.Interchange.Text.decodeDelimited",arguments,4,out);
}
hmath_status hmath_interchange_value_decode_matrix_market(hmath_context *context, const hmath_value *lim, const hmath_value *bs, hmath_value **out) {
    const hmath_value *arguments[]={lim,bs};
    return invoke(context,"HMath.Interchange.Text.decodeMatrixMarket",arguments,2,out);
}
hmath_status hmath_interchange_value_decode_text(hmath_context *context, const hmath_value *lim, const hmath_value *bs, hmath_value **out) {
    const hmath_value *arguments[]={lim,bs};
    return invoke(context,"HMath.Interchange.Text.decodeText",arguments,2,out);
}
hmath_status hmath_interchange_value_encode_delimited(hmath_context *context, const hmath_value *lim, const hmath_value *separator, const hmath_value *a, hmath_value **out) {
    const hmath_value *arguments[]={lim,separator,a};
    return invoke(context,"HMath.Interchange.Text.encodeDelimited",arguments,3,out);
}
hmath_status hmath_interchange_value_encode_matrix_market(hmath_context *context, const hmath_value *lim, const hmath_value *a, hmath_value **out) {
    const hmath_value *arguments[]={lim,a};
    return invoke(context,"HMath.Interchange.Text.encodeMatrixMarket",arguments,2,out);
}
hmath_status hmath_interchange_value_encode_text(hmath_context *context, const hmath_value *lim, const hmath_value *a, hmath_value **out) {
    const hmath_value *arguments[]={lim,a};
    return invoke(context,"HMath.Interchange.Text.encodeText",arguments,2,out);
}
hmath_status hmath_interchange_value_bounded_int(hmath_context *context, const hmath_value *name, const hmath_value *upper, const hmath_value *x, hmath_value **out) {
    const hmath_value *arguments[]={name,upper,x};
    return invoke(context,"HMath.Interchange.Array.boundedInt",arguments,3,out);
}
hmath_status hmath_interchange_value_byte_offsets(hmath_context *context, const hmath_value *a, hmath_value **out) {
    const hmath_value *arguments[]={a};
    return invoke(context,"HMath.Interchange.Array.byteOffsets",arguments,1,out);
}
hmath_status hmath_interchange_value_check_limits(hmath_context *context, const hmath_value *lim, hmath_value **out) {
    const hmath_value *arguments[]={lim};
    return invoke(context,"HMath.Interchange.Array.checkLimits",arguments,1,out);
}
hmath_status hmath_interchange_value_guard_i(hmath_context *context, const hmath_value *p, const hmath_value *e, hmath_value **out) {
    const hmath_value *arguments[]={p,e};
    return invoke(context,"HMath.Interchange.Array.guardI",arguments,2,out);
}
hmath_status hmath_interchange_value_run_decoder(hmath_context *context, const hmath_value *parser, const hmath_value *data, hmath_value **out) {
    const hmath_value *arguments[]={parser,data};
    return invoke(context,"HMath.Interchange.Binary.runDecoder",arguments,2,out);
}
hmath_status hmath_interchange_value_dtype_code(hmath_context *context, const hmath_value *dtype, hmath_value **out) {
    const hmath_value *arguments[]={dtype};
    return invoke(context,"__dtype_code",arguments,1,out);
}
hmath_status hmath_interchange_value_error_fields(hmath_context *context, const hmath_value *error, hmath_value **out) {
    const hmath_value *arguments[]={error};
    return invoke(context,"__error_fields",arguments,1,out);
}
hmath_status hmath_interchange_value_put_bytes(hmath_context *context, const hmath_value *program, hmath_value **out) {
    const hmath_value *arguments[]={program};
    return invoke(context,"__put_bytes",arguments,1,out);
}
hmath_status hmath_interchange_value_open_handle(hmath_context *context, const hmath_value *path, const hmath_value *mode, hmath_value **out) {
    const hmath_value *arguments[]={path,mode};
    return invoke(context,"__open_handle",arguments,2,out);
}
hmath_status hmath_interchange_value_close_handle(hmath_context *context, const hmath_value *handle, hmath_value **out) {
    const hmath_value *arguments[]={handle};
    return invoke(context,"__close_handle",arguments,1,out);
}
hmath_status hmath_interchange_value_seek_handle(hmath_context *context, const hmath_value *handle, const hmath_value *whence, const hmath_value *offset, hmath_value **out) {
    const hmath_value *arguments[]={handle,whence,offset};
    return invoke(context,"__seek_handle",arguments,3,out);
}
hmath_status hmath_interchange_value_tell_handle(hmath_context *context, const hmath_value *handle, hmath_value **out) {
    const hmath_value *arguments[]={handle};
    return invoke(context,"__tell_handle",arguments,1,out);
}
hmath_status hmath_interchange_value_flush_handle(hmath_context *context, const hmath_value *handle, hmath_value **out) {
    const hmath_value *arguments[]={handle};
    return invoke(context,"__flush_handle",arguments,1,out);
}
hmath_status hmath_interchange_value_equal_array(hmath_context *context, const hmath_value *left, const hmath_value *right, hmath_value **out) {
    const hmath_value *arguments[]={left,right};
    return invoke(context,"__equal_array",arguments,2,out);
}
