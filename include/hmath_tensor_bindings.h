/* SPDX-License-Identifier: MPL-2.0 */
#ifndef HMATH_TENSOR_BINDINGS_H
#define HMATH_TENSOR_BINDINGS_H
#include "hmath_value.h"
#include "hmath_error.h"
#include "hmath_callback.h"
#ifdef __cplusplus
extern "C" {
#endif
/* Actual original typed boxed tensors (Value161 Double,270 other element
 * witnesses), lazy TensorGraph271, pinned MutableTensor272. No legacy C tensor
 * rank/element cap is imposed; original shape and byte overflow checks apply.
 * Prototype scalars select element types explicitly; Bool and String permit
 * structural APIs, and numerical APIs require their original class instance. */
typedef enum hmath_tensor_layout_kind {
    HMATH_TENSOR_LAYOUT_ROW_MAJOR=0,
    HMATH_TENSOR_LAYOUT_COLUMN_MAJOR=1,
    HMATH_TENSOR_LAYOUT_STRIDED=2
} hmath_tensor_layout_kind;
typedef enum hmath_tensor_device_kind { HMATH_TENSOR_DEVICE_CPU=0 } hmath_tensor_device_kind;
/* Scalar arguments are a borrowed tuple of exact typed values. Successful
 * callbacks transfer one owned Value result. MathError wire fields live until
 * consumed. Function/userdata live until every derived lazy graph is released.
 * Callbacks are synchronous, may reenter HMath, and must not request shutdown. */
typedef hmath_status (*hmath_tensor_scalar_callback_fn)(const hmath_value *arguments,void *userdata,hmath_value **out,hmath_math_error *error);
/* Buffer pointer is valid only during the call; metadata=(prototype,shape,
 * signed element strides,Storable element byte size,Storable alignment).
 * Synchronize concurrent writes and honor actual shape/strides. Do not retain
 * pointer or access memory outside this view. Result may be any shared Value. */
typedef hmath_status (*hmath_tensor_buffer_callback_fn)(void *pointer,const hmath_value *metadata,void *userdata,hmath_value **out,hmath_math_error *error);
HMATH_API hmath_status hmath_tensor_object_callback(hmath_context *,hmath_tensor_scalar_callback_fn,void *,hmath_value **);
HMATH_API hmath_status hmath_tensor_object_buffer_callback(hmath_context *,hmath_tensor_buffer_callback_fn,void *,hmath_value **);
HMATH_API hmath_status hmath_tensor_object_prototype(hmath_context *,const hmath_value *,hmath_value **);
HMATH_API hmath_status hmath_tensor_object_graph_prototype(hmath_context *,const hmath_value *,hmath_value **);
HMATH_API hmath_status hmath_tensor_object_mutable_prototype(hmath_context *,const hmath_value *,hmath_value **);
HMATH_API hmath_status hmath_tensor_object_equal_instance(hmath_context *,const hmath_value *,const hmath_value *,hmath_value **);
/* Explicit type token permits structural scalar types whose provider has no
 * Num instance. This calls original tensorFull without numeric conversion. */
HMATH_API hmath_status hmath_tensor_object_full_typed(hmath_context *,const hmath_value *element_type,const hmath_value *shape,const hmath_value *fill,hmath_value **out);
/* BEGIN GENERATED */
/* HMath.Tensor.RowMajor -> Layout. */
HMATH_API hmath_status hmath_tensor_object_row_major_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.Tensor.ColumnMajor -> Layout. */
HMATH_API hmath_status hmath_tensor_object_column_major_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.Tensor.Strided -> Layout. */
HMATH_API hmath_status hmath_tensor_object_strided_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.Tensor.CPU -> Device. */
HMATH_API hmath_status hmath_tensor_object_cpu_create(
    hmath_context *context,
    hmath_value **out);

/* HMath.Tensor.tensor -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tensor(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *shape,
    const hmath_value *xs,
    hmath_value **out);

/* HMath.Tensor.tensorColumnMajor -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tensor_column_major(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *shape,
    const hmath_value *xs,
    hmath_value **out);

/* HMath.Tensor.tensorFull -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tensor_full(
    hmath_context *context,
    const hmath_value *shape,
    const hmath_value *fill_value,
    hmath_value **out);

/* HMath.Tensor.tensorZeros -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tensor_zeros(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *shape,
    hmath_value **out);

/* HMath.Tensor.tensorOnes -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tensor_ones(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *shape,
    hmath_value **out);

/* HMath.Tensor.tensorArange -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tensor_arange(
    hmath_context *context,
    const hmath_value *start,
    const hmath_value *end,
    const hmath_value *step,
    hmath_value **out);

/* HMath.Tensor.tensorLinspace -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tensor_linspace(
    hmath_context *context,
    const hmath_value *start,
    const hmath_value *end,
    const hmath_value *count,
    hmath_value **out);

/* HMath.Tensor.tensorLogspace -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tensor_logspace(
    hmath_context *context,
    const hmath_value *base,
    const hmath_value *start,
    const hmath_value *end,
    const hmath_value *count,
    hmath_value **out);

/* HMath.Tensor.tensorRandom -> (Tensor,Integer). */
HMATH_API hmath_status hmath_tensor_object_tensor_random(
    hmath_context *context,
    const hmath_value *seed,
    const hmath_value *shape,
    hmath_value **out);

/* HMath.Tensor.tensorValues -> Elements. */
HMATH_API hmath_status hmath_tensor_object_tensor_values(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.tensorShape -> [Int]. */
HMATH_API hmath_status hmath_tensor_object_tensor_shape(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.tensorStrides -> [Int]. */
HMATH_API hmath_status hmath_tensor_object_tensor_strides(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.tensorOffset -> Int. */
HMATH_API hmath_status hmath_tensor_object_tensor_offset(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.tensorDType -> String. */
HMATH_API hmath_status hmath_tensor_object_tensor_d_type(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.tensorDevice -> Device. */
HMATH_API hmath_status hmath_tensor_object_tensor_device(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.tensorLayout -> Layout. */
HMATH_API hmath_status hmath_tensor_object_tensor_layout(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.numel -> Int. */
HMATH_API hmath_status hmath_tensor_object_numel(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.isContiguous -> Bool. */
HMATH_API hmath_status hmath_tensor_object_is_contiguous(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.shapeSize -> Int. */
HMATH_API hmath_status hmath_tensor_object_shape_size(
    hmath_context *context,
    const hmath_value *shape,
    hmath_value **out);

/* HMath.Tensor.inferBroadcast -> [Int]. */
HMATH_API hmath_status hmath_tensor_object_infer_broadcast(
    hmath_context *context,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out);

/* HMath.Tensor.contiguous -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_contiguous(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.indexTensor -> Element. */
HMATH_API hmath_status hmath_tensor_object_index_tensor(
    hmath_context *context,
    const hmath_value *input_tensor,
    const hmath_value *index,
    hmath_value **out);

/* HMath.Tensor.sliceTensor -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_slice_tensor(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *start,
    const hmath_value *count,
    const hmath_value *step,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.fancyIndex -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_fancy_index(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *indices,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.gather -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_gather(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *indices,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.booleanIndex -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_boolean_index(
    hmath_context *context,
    const hmath_value *mask,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.scatter -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_scatter(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *indices,
    const hmath_value *updates,
    const hmath_value *target,
    hmath_value **out);

/* HMath.Tensor.scatterAdd -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_scatter_add(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *indices,
    const hmath_value *updates,
    const hmath_value *target,
    hmath_value **out);

/* HMath.Tensor.reshapeTensor -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_reshape_tensor(
    hmath_context *context,
    const hmath_value *shape,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.flattenTensor -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_flatten_tensor(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.squeeze -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_squeeze(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.unsqueeze -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_unsqueeze(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.expand -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_expand(
    hmath_context *context,
    const hmath_value *shape,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.permute -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_permute(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.transposeTensor -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_transpose_tensor(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.moveAxis -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_move_axis(
    hmath_context *context,
    const hmath_value *from_axis,
    const hmath_value *to_axis,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.swapAxes -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_swap_axes(
    hmath_context *context,
    const hmath_value *from_axis,
    const hmath_value *to_axis,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.broadcastTo -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_broadcast_to(
    hmath_context *context,
    const hmath_value *shape,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.repeatTensor -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_repeat_tensor(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *count,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.tile -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tile(
    hmath_context *context,
    const hmath_value *counts,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.concatenate -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_concatenate(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *axis,
    const hmath_value *inputs,
    hmath_value **out);

/* HMath.Tensor.stack -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_stack(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *axis,
    const hmath_value *inputs,
    hmath_value **out);

/* HMath.Tensor.splitTensor -> [Tensor]. */
HMATH_API hmath_status hmath_tensor_object_split_tensor(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *segments,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.chunkTensor -> [Tensor]. */
HMATH_API hmath_status hmath_tensor_object_chunk_tensor(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *count,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.padTensor -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_pad_tensor(
    hmath_context *context,
    const hmath_value *padding,
    const hmath_value *fill_value,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.roll -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_roll(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *shift,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.flipTensor -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_flip_tensor(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.rotate -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_rotate(
    hmath_context *context,
    const hmath_value *first,
    const hmath_value *second,
    const hmath_value *turns,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.sortTensor -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_sort_tensor(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.unique -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_unique(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.argsort -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_argsort(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.topk -> (Tensor,Tensor). */
HMATH_API hmath_status hmath_tensor_object_topk(
    hmath_context *context,
    const hmath_value *count,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.nonzero -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_nonzero(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.whereTensor -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_where_tensor(
    hmath_context *context,
    const hmath_value *mask,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out);

/* HMath.Tensor.maskedFill -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_masked_fill(
    hmath_context *context,
    const hmath_value *mask,
    const hmath_value *fill_value,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.maskedSelect -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_masked_select(
    hmath_context *context,
    const hmath_value *mask,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.mapTensor -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_map_tensor(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *cb,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.zipTensor -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_zip_tensor(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *cb,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out);

/* HMath.Tensor.tensorAdd -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tensor_add(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out);

/* HMath.Tensor.tensorSubtract -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tensor_subtract(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out);

/* HMath.Tensor.tensorMultiply -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tensor_multiply(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out);

/* HMath.Tensor.tensorDivide -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tensor_divide(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out);

/* HMath.Tensor.tensorEqual -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tensor_equal(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out);

/* HMath.Tensor.tensorLess -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tensor_less(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out);

/* HMath.Tensor.tensorAnd -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tensor_and(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out);

/* HMath.Tensor.tensorOr -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tensor_or(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out);

/* HMath.Tensor.tensorNot -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tensor_not(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.promoteTensor -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_promote_tensor(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.sumAxes -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_sum_axes(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *keep_dimensions,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.productAxes -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_product_axes(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *keep_dimensions,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.meanAxes -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_mean_axes(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *keep_dimensions,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.varianceAxes -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_variance_axes(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *keep_dimensions,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.normAxes -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_norm_axes(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *keep_dimensions,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.minAxes -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_min_axes(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *keep_dimensions,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.maxAxes -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_max_axes(
    hmath_context *context,
    const hmath_value *axes,
    const hmath_value *keep_dimensions,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.argmin -> Int. */
HMATH_API hmath_status hmath_tensor_object_argmin(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.argmax -> Int. */
HMATH_API hmath_status hmath_tensor_object_argmax(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.cumulativeSum -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_cumulative_sum(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.cumulativeProduct -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_cumulative_product(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.tensordot -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tensordot(
    hmath_context *context,
    const hmath_value *left_axes,
    const hmath_value *right_axes,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out);

/* HMath.Tensor.einsum -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_einsum(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *labels,
    const hmath_value *output_labels,
    const hmath_value *inputs,
    hmath_value **out);

/* HMath.Tensor.batchedMatmul -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_batched_matmul(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out);

/* HMath.Tensor.tensorKronecker -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_tensor_kronecker(
    hmath_context *context,
    const hmath_value *a,
    const hmath_value *b,
    hmath_value **out);

/* HMath.Tensor.serializeTensor -> String. */
HMATH_API hmath_status hmath_tensor_object_serialize_tensor(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.deserializeTensor -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_deserialize_tensor(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *text,
    hmath_value **out);

/* HMath.Tensor.inputGraph -> TensorGraph. */
HMATH_API hmath_status hmath_tensor_object_input_graph(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.mapGraph -> TensorGraph. */
HMATH_API hmath_status hmath_tensor_object_map_graph(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *cb,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.zipGraph -> TensorGraph. */
HMATH_API hmath_status hmath_tensor_object_zip_graph(
    hmath_context *context,
    const hmath_value *element_type,
    const hmath_value *cb,
    const hmath_value *left,
    const hmath_value *right,
    hmath_value **out);

/* HMath.Tensor.evaluateGraph -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_evaluate_graph(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.Mutable.newMutable -> MutableTensor. */
HMATH_API hmath_status hmath_tensor_object_new_mutable(
    hmath_context *context,
    const hmath_value *shape,
    const hmath_value *fill_value,
    hmath_value **out);

/* HMath.Tensor.Mutable.thawTensor -> MutableTensor. */
HMATH_API hmath_status hmath_tensor_object_thaw_tensor(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.Mutable.freezeTensor -> Tensor. */
HMATH_API hmath_status hmath_tensor_object_freeze_tensor(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.Mutable.mutableShape -> [Int]. */
HMATH_API hmath_status hmath_tensor_object_mutable_shape(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.Mutable.readMutable -> Element. */
HMATH_API hmath_status hmath_tensor_object_read_mutable(
    hmath_context *context,
    const hmath_value *input_tensor,
    const hmath_value *index,
    hmath_value **out);

/* HMath.Tensor.Mutable.writeMutable -> Unit. */
HMATH_API hmath_status hmath_tensor_object_write_mutable(
    hmath_context *context,
    const hmath_value *input_tensor,
    const hmath_value *index,
    const hmath_value *fill_value,
    hmath_value **out);

/* HMath.Tensor.Mutable.modifyMutable -> Unit. */
HMATH_API hmath_status hmath_tensor_object_modify_mutable(
    hmath_context *context,
    const hmath_value *input_tensor,
    const hmath_value *index,
    const hmath_value *cb,
    hmath_value **out);

/* HMath.Tensor.Mutable.sliceMutable -> MutableTensor. */
HMATH_API hmath_status hmath_tensor_object_slice_mutable(
    hmath_context *context,
    const hmath_value *axis,
    const hmath_value *start,
    const hmath_value *count,
    const hmath_value *step,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.Mutable.transposeMutable -> MutableTensor. */
HMATH_API hmath_status hmath_tensor_object_transpose_mutable(
    hmath_context *context,
    const hmath_value *input_tensor,
    hmath_value **out);

/* HMath.Tensor.Mutable.mutableAlignment -> Int. */
HMATH_API hmath_status hmath_tensor_object_mutable_alignment(
    hmath_context *context,
    const hmath_value *element_type,
    hmath_value **out);

/* HMath.Tensor.Mutable.withMutableBuffer -> Generic. */
HMATH_API hmath_status hmath_tensor_object_with_mutable_buffer(
    hmath_context *context,
    const hmath_value *input_tensor,
    const hmath_value *cb,
    hmath_value **out);
/* END GENERATED */
#ifdef __cplusplus
}
#endif
#endif
