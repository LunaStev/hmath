/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_tensor_bindings.h"
#include "value_internal.h"
#include <stdlib.h>
#include <string.h>
extern int hm_tensor_apply(const char *,void *const *,size_t,void **);
extern int hm_tensor_callback(int,void (*)(void),void *,void **);
extern int hm_tensor_clone(void *,void **);
static hmath_status invoke(hmath_context *context,const char *name,const hmath_value *const *arguments,size_t count,hmath_value **out) {
    if(!out || (count && !arguments))return hm_error(HMATH_INVALID_ARGUMENT,"NULL Tensor argument/output");
    if(count>(size_t)PTRDIFF_MAX/sizeof(void *))return hm_error(HMATH_OVERFLOW,"Tensor argument span overflow");
    for(size_t i=0;i<count;++i)if(!arguments[i])return hm_error(HMATH_INVALID_ARGUMENT,"NULL Tensor Value");
    void **stable=malloc((count?count:1)*sizeof *stable);
    if(!stable)return hm_error(HMATH_ALLOCATION_FAILED,"Tensor argument allocation failed");
    for(size_t i=0;i<count;++i)stable[i]=hm_value_stable(arguments[i]);
    hmath_value *result;
    hmath_status status=hm_value_begin(context,&result);
    if(status){free(stable);return status;}
    int code=hm_tensor_apply(name,stable,count,&result->stable);
    free(stable);
    return hm_value_finish(result,code,out);
}
static hmath_status make_callback(hmath_context *context,int role,void (*function)(void),void *userdata,hmath_value **out) {
    if(!function || !out)return hm_error(HMATH_INVALID_ARGUMENT,"NULL Tensor callback/output");
    hmath_value *result;
    hmath_status status=hm_value_begin(context,&result);
    if(status)return status;
    return hm_value_finish(result,hm_tensor_callback(role,function,userdata,&result->stable),out);
}
hmath_status hmath_tensor_object_callback(hmath_context *context,hmath_tensor_scalar_callback_fn function,void *userdata,hmath_value **out) {
    return make_callback(context,0,(void (*)(void))function,userdata,out);
}
hmath_status hmath_tensor_object_buffer_callback(hmath_context *context,hmath_tensor_buffer_callback_fn function,void *userdata,hmath_value **out) {
    return make_callback(context,1,(void (*)(void))function,userdata,out);
}
static int callback_input(void *stable,hmath_value **out,hmath_math_error *error) {
    hmath_value *input;
    hmath_status status=hm_value_begin(NULL,&input);
    if(!status)status=hm_value_finish(input,hm_tensor_clone(stable,&input->stable),out);
    if(status){error->message="Tensor callback input allocation failed";error->message_length=strlen(error->message);}
    return status;
}
static int callback_result(int status,hmath_value *result,void **out,hmath_math_error *error) {
    if(!status){
        if(!result){status=HMATH_INVALID_ARGUMENT;error->message="Tensor callback returned NULL";error->message_length=strlen(error->message);}
        else status=hm_tensor_clone(hm_value_stable(result),out);
    }
    hmath_value_release(result);
    return status;
}
int hm_tensor_invoke_callback(hmath_tensor_scalar_callback_fn function,void *userdata,void *argument,void **out,hmath_math_error *error) {
    hmath_value *input=NULL,*result=NULL;
    int status=callback_input(argument,&input,error);
    if(!status){
        status=function(input,userdata,&result,error);
        status=callback_result(status,result,out,error);
    }
    hmath_value_release(input);
    return status;
}
int hm_tensor_invoke_buffer(hmath_tensor_buffer_callback_fn function,void *userdata,void *pointer,void *argument,void **out,hmath_math_error *error) {
    hmath_value *input=NULL,*result=NULL;
    int status=callback_input(argument,&input,error);
    if(!status){
        status=function(pointer,input,userdata,&result,error);
        status=callback_result(status,result,out,error);
    }
    hmath_value_release(input);
    return status;
}
hmath_status hmath_tensor_object_prototype(hmath_context *ctx,const hmath_value *value,hmath_value **out){const hmath_value *args[]={value};return invoke(ctx,"__prototype",args,1,out);}
hmath_status hmath_tensor_object_graph_prototype(hmath_context *ctx,const hmath_value *value,hmath_value **out){const hmath_value *args[]={value};return invoke(ctx,"__graph_prototype",args,1,out);}
hmath_status hmath_tensor_object_mutable_prototype(hmath_context *ctx,const hmath_value *value,hmath_value **out){const hmath_value *args[]={value};return invoke(ctx,"__mutable_prototype",args,1,out);}
hmath_status hmath_tensor_object_equal_instance(hmath_context *ctx,const hmath_value *a,const hmath_value *b,hmath_value **out){const hmath_value *args[]={a,b};return invoke(ctx,"__equal",args,2,out);}
hmath_status hmath_tensor_object_full_typed(hmath_context *ctx,const hmath_value *type,const hmath_value *shape,const hmath_value *fill,hmath_value **out){const hmath_value *args[]={type,shape,fill};return invoke(ctx,"__full_typed",args,3,out);}
/* BEGIN GENERATED */
hmath_status hmath_tensor_object_row_major_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "RowMajor", NULL, 0, out);
}

hmath_status hmath_tensor_object_column_major_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "ColumnMajor", NULL, 0, out);
}

hmath_status hmath_tensor_object_strided_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "Strided", NULL, 0, out);
}

hmath_status hmath_tensor_object_cpu_create(
    hmath_context *context,
    hmath_value **out) {
    return invoke(context, "CPU", NULL, 0, out);
}

hmath_status hmath_tensor_object_tensor(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *shape,
    const hmath_value *xs,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {element_type, shape, xs};
    return invoke(context, "tensor", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_tensor_column_major(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *shape,
    const hmath_value *xs,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {element_type, shape, xs};
    return invoke(context, "tensorColumnMajor", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_tensor_full(
    hmath_context *context,
    const hmath_value *shape,
    const hmath_value *fill_value,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {shape, fill_value};
    return invoke(context, "tensorFull", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_tensor_zeros(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *shape,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {element_type, shape};
    return invoke(context, "tensorZeros", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_tensor_ones(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *shape,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {element_type, shape};
    return invoke(context, "tensorOnes", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_tensor_arange(
    hmath_context *context,
    const hmath_value *start,
    const hmath_value *end,
    const hmath_value *step,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {start, end, step};
    return invoke(context, "tensorArange", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_tensor_linspace(
    hmath_context *context,
    const hmath_value *start,
    const hmath_value *end,
    const hmath_value *count,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {start, end, count};
    return invoke(context, "tensorLinspace", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_tensor_logspace(
    hmath_context *context,
    const hmath_value *base,
    const hmath_value *start,
    const hmath_value *end,
    const hmath_value *count,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {base, start, end, count};
    return invoke(context, "tensorLogspace", hm_arguments, 4, out);
}

hmath_status hmath_tensor_object_tensor_random(
    hmath_context *context,
    const hmath_value *seed,
    const hmath_value *shape,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {seed, shape};
    return invoke(context, "tensorRandom", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_tensor_values(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "tensorValues", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_tensor_shape(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "tensorShape", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_tensor_strides(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "tensorStrides", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_tensor_offset(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "tensorOffset", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_tensor_d_type(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "tensorDType", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_tensor_device(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "tensorDevice", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_tensor_layout(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "tensorLayout", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_numel(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "numel", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_is_contiguous(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "isContiguous", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_shape_size(
    hmath_context *context,
    const hmath_value *shape,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {shape};
    return invoke(context, "shapeSize", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_infer_broadcast(
    hmath_context *context,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {left, right};
    return invoke(context, "inferBroadcast", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_contiguous(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "contiguous", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_index_tensor(
    hmath_context *context,
    const hmath_value *input_tensor,
    const hmath_value *index,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor, index};
    return invoke(context, "indexTensor", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_slice_tensor(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *start,
    const hmath_value *count,
    const hmath_value *step,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axis, start, count, step, input_tensor};
    return invoke(context, "sliceTensor", hm_arguments, 5, out);
}

hmath_status hmath_tensor_object_fancy_index(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *indices,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axis, indices, input_tensor};
    return invoke(context, "fancyIndex", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_gather(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *indices,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axis, indices, input_tensor};
    return invoke(context, "gather", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_boolean_index(
    hmath_context *context,
    const hmath_value *mask,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {mask, input_tensor};
    return invoke(context, "booleanIndex", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_scatter(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *indices,
    const hmath_value *updates,
    const hmath_value *target,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axis, indices, updates, target};
    return invoke(context, "scatter", hm_arguments, 4, out);
}

hmath_status hmath_tensor_object_scatter_add(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *indices,
    const hmath_value *updates,
    const hmath_value *target,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axis, indices, updates, target};
    return invoke(context, "scatterAdd", hm_arguments, 4, out);
}

hmath_status hmath_tensor_object_reshape_tensor(
    hmath_context *context,
    const hmath_value *shape,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {shape, input_tensor};
    return invoke(context, "reshapeTensor", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_flatten_tensor(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "flattenTensor", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_squeeze(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "squeeze", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_unsqueeze(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axis, input_tensor};
    return invoke(context, "unsqueeze", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_expand(
    hmath_context *context,
    const hmath_value *shape,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {shape, input_tensor};
    return invoke(context, "expand", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_permute(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axes, input_tensor};
    return invoke(context, "permute", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_transpose_tensor(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "transposeTensor", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_move_axis(
    hmath_context *context,
    const hmath_value *from_axis,
    const hmath_value *to_axis,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {from_axis, to_axis, input_tensor};
    return invoke(context, "moveAxis", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_swap_axes(
    hmath_context *context,
    const hmath_value *from_axis,
    const hmath_value *to_axis,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {from_axis, to_axis, input_tensor};
    return invoke(context, "swapAxes", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_broadcast_to(
    hmath_context *context,
    const hmath_value *shape,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {shape, input_tensor};
    return invoke(context, "broadcastTo", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_repeat_tensor(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *count,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axis, count, input_tensor};
    return invoke(context, "repeatTensor", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_tile(
    hmath_context *context,
    const hmath_value *counts,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {counts, input_tensor};
    return invoke(context, "tile", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_concatenate(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *axis,
    const hmath_value *inputs,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {element_type, axis, inputs};
    return invoke(context, "concatenate", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_stack(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *axis,
    const hmath_value *inputs,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {element_type, axis, inputs};
    return invoke(context, "stack", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_split_tensor(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *segments,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axis, segments, input_tensor};
    return invoke(context, "splitTensor", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_chunk_tensor(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *count,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axis, count, input_tensor};
    return invoke(context, "chunkTensor", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_pad_tensor(
    hmath_context *context,
    const hmath_value *padding,
    const hmath_value *fill_value,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {padding, fill_value, input_tensor};
    return invoke(context, "padTensor", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_roll(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *shift,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axis, shift, input_tensor};
    return invoke(context, "roll", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_flip_tensor(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axis, input_tensor};
    return invoke(context, "flipTensor", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_rotate(
    hmath_context *context,
    const hmath_value *first,
    const hmath_value *second,
    const hmath_value *turns,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {first, second, turns, input_tensor};
    return invoke(context, "rotate", hm_arguments, 4, out);
}

hmath_status hmath_tensor_object_sort_tensor(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "sortTensor", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_unique(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "unique", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_argsort(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "argsort", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_topk(
    hmath_context *context,
    const hmath_value *count,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {count, input_tensor};
    return invoke(context, "topk", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_nonzero(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "nonzero", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_where_tensor(
    hmath_context *context,
    const hmath_value *mask,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {mask, left, right};
    return invoke(context, "whereTensor", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_masked_fill(
    hmath_context *context,
    const hmath_value *mask,
    const hmath_value *fill_value,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {mask, fill_value, input_tensor};
    return invoke(context, "maskedFill", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_masked_select(
    hmath_context *context,
    const hmath_value *mask,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {mask, input_tensor};
    return invoke(context, "maskedSelect", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_map_tensor(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *cb,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {element_type, cb, input_tensor};
    return invoke(context, "mapTensor", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_zip_tensor(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *cb,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {element_type, cb, left, right};
    return invoke(context, "zipTensor", hm_arguments, 4, out);
}

hmath_status hmath_tensor_object_tensor_add(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {a, b};
    return invoke(context, "tensorAdd", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_tensor_subtract(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {a, b};
    return invoke(context, "tensorSubtract", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_tensor_multiply(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {a, b};
    return invoke(context, "tensorMultiply", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_tensor_divide(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {a, b};
    return invoke(context, "tensorDivide", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_tensor_equal(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {a, b};
    return invoke(context, "tensorEqual", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_tensor_less(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {a, b};
    return invoke(context, "tensorLess", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_tensor_and(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {a, b};
    return invoke(context, "tensorAnd", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_tensor_or(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {a, b};
    return invoke(context, "tensorOr", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_tensor_not(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "tensorNot", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_promote_tensor(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {element_type, input_tensor};
    return invoke(context, "promoteTensor", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_sum_axes(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *keep_dimensions,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axes, keep_dimensions, input_tensor};
    return invoke(context, "sumAxes", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_product_axes(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *keep_dimensions,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axes, keep_dimensions, input_tensor};
    return invoke(context, "productAxes", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_mean_axes(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *keep_dimensions,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axes, keep_dimensions, input_tensor};
    return invoke(context, "meanAxes", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_variance_axes(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *keep_dimensions,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axes, keep_dimensions, input_tensor};
    return invoke(context, "varianceAxes", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_norm_axes(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *keep_dimensions,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axes, keep_dimensions, input_tensor};
    return invoke(context, "normAxes", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_min_axes(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *keep_dimensions,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axes, keep_dimensions, input_tensor};
    return invoke(context, "minAxes", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_max_axes(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *keep_dimensions,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axes, keep_dimensions, input_tensor};
    return invoke(context, "maxAxes", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_argmin(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "argmin", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_argmax(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "argmax", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_cumulative_sum(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axis, input_tensor};
    return invoke(context, "cumulativeSum", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_cumulative_product(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axis, input_tensor};
    return invoke(context, "cumulativeProduct", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_tensordot(
    hmath_context *context,
    const hmath_value *left_axes,
    const hmath_value *right_axes,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {left_axes, right_axes, left, right};
    return invoke(context, "tensordot", hm_arguments, 4, out);
}

hmath_status hmath_tensor_object_einsum(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *labels,
    const hmath_value *output_labels,
    const hmath_value *inputs,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {element_type, labels, output_labels, inputs};
    return invoke(context, "einsum", hm_arguments, 4, out);
}

hmath_status hmath_tensor_object_batched_matmul(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {a, b};
    return invoke(context, "batchedMatmul", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_tensor_kronecker(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {a, b};
    return invoke(context, "tensorKronecker", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_serialize_tensor(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "serializeTensor", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_deserialize_tensor(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *text,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {element_type, text};
    return invoke(context, "deserializeTensor", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_input_graph(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "inputGraph", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_map_graph(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *cb,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {element_type, cb, input_tensor};
    return invoke(context, "mapGraph", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_zip_graph(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *cb,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {element_type, cb, left, right};
    return invoke(context, "zipGraph", hm_arguments, 4, out);
}

hmath_status hmath_tensor_object_evaluate_graph(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "evaluateGraph", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_new_mutable(
    hmath_context *context,
    const hmath_value *shape,
    const hmath_value *fill_value,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {shape, fill_value};
    return invoke(context, "newMutable", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_thaw_tensor(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "thawTensor", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_freeze_tensor(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "freezeTensor", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_mutable_shape(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "mutableShape", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_read_mutable(
    hmath_context *context,
    const hmath_value *input_tensor,
    const hmath_value *index,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor, index};
    return invoke(context, "readMutable", hm_arguments, 2, out);
}

hmath_status hmath_tensor_object_write_mutable(
    hmath_context *context,
    const hmath_value *input_tensor,
    const hmath_value *index,
    const hmath_value *fill_value,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor, index, fill_value};
    return invoke(context, "writeMutable", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_modify_mutable(
    hmath_context *context,
    const hmath_value *input_tensor,
    const hmath_value *index,
    const hmath_value *cb,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor, index, cb};
    return invoke(context, "modifyMutable", hm_arguments, 3, out);
}

hmath_status hmath_tensor_object_slice_mutable(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *start,
    const hmath_value *count,
    const hmath_value *step,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {axis, start, count, step, input_tensor};
    return invoke(context, "sliceMutable", hm_arguments, 5, out);
}

hmath_status hmath_tensor_object_transpose_mutable(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor};
    return invoke(context, "transposeMutable", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_mutable_alignment(
    hmath_context *context,
    const hmath_value *element_type,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {element_type};
    return invoke(context, "mutableAlignment", hm_arguments, 1, out);
}

hmath_status hmath_tensor_object_with_mutable_buffer(
    hmath_context *context,
    const hmath_value *input_tensor,
    const hmath_value *cb,
    hmath_value **out) {
    const hmath_value *hm_arguments[] = {input_tensor, cb};
    return invoke(context, "withMutableBuffer", hm_arguments, 2, out);
}
/* END GENERATED */
