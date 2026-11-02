# Typed tensors, graphs and mutable buffers

`from hmath import tensor` exposes the original `HMath.Tensor` and
`HMath.Tensor.Mutable` APIs. C and C++ include `hmath_tensor_bindings.h` and use
shared owned `hmath_value` handles. Shapes, element strides, offsets, layouts,
copy/view choices, explicit dtype conversion, errors and arithmetic follow the
original functions.

```python
from hmath import tensor

with tensor.tensor([2, 2], [1, 2, 3, 4], dtype="float32") as source:
    with tensor.transpose_tensor(source) as view:
        print(view.shape, view.strides, view.values)
    with tensor.sum_axes([0], False, source) as sums:
        assert sums.values == [4.0, 6.0]
```

The Python `tensor.Tensor` owner retains the original boxed Haskell tensor.
`tensor.TensorDouble` is the same native object returned by the Image API's
`to_tensor`; it interchanges without reconstructing values. The buffer kernels
behind the top-level `hmath.Tensor` have their own buffer-oriented API.

## Elements and type selection

Constructors take `dtype="float64"` by default. Available standard elements are
`float32`, `float64`, `integer`, `rational`, `complex64`, `complex128`, signed and
unsigned fixed-width integers, `intp`, `uintp`, `bool`, `string`. Exact integers
and rational fractions do not pass through floating-point intermediates. A
boxed original `Numeric.Dual` or Quaternion coefficient can select its complete
nested coefficient type as a prototype. Structural providers retain their
actual original type, such as `API.Algebra.Exact`, without inventing a Num
instance.

There is no automatic promotion between differently typed tensor operands.
`promote_tensor(dtype, tensor)` invokes the original explicit Real→Fractional
conversion. Operations require their original class instances: Integer has no
Fractional division, Complex has no Ord sorting, and Rational has no RealFloat
norm. Such unavailable specializations return `HMATH_UNSUPPORTED`; they are
never computed through Double as a fallback. Standard numerical dtypes retain
original fixed-width wraparound during arithmetic; input conversion checks
whether a supplied Python integer fits the selected bounded representation.

`tensor_full` infers a type from its fill value when `dtype` is omitted.
`new_mutable` defaults to `float64`. List operations infer the first tensor's
type, or use the explicit `dtype`; an empty list defaults to `float64` where a
type is otherwise undetermined. `einsum([], "", [], dtype=...)` therefore keeps
the original type-selected scalar-product identity.

`tensor.element_type` / `element_type(tensor)` returns an owned prototype. For a
structural element this is a type token, retaining its actual codec and original
instance dictionaries. Supply it as `dtype` to construct matching arrays,
map outputs or scalar fills; release the token afterward. Structural scalar
values must be constructed by their original provider. Numerical methods remain
unavailable when that source type has no Num instance.

## Shapes, storage and inspection

Scalars have shape `[]` and one element; zero axes retain their dimensions and
have no elements. Dimensions use Haskell Int. Original nonnegative shape,
element-count and Int-overflow checks remain in force. These APIs do not impose
the legacy byte-buffer ABI's rank-eight or one-million-element caps.

`Tensor.shape`, `.strides`, `.offset`, `.layout`, `.device`, `.numel`,
`.is_contiguous`, `.type_name` and `.values` call the original accessors.
Strides/offsets count **elements**, including negative reversed strides and zero
broadcast strides. Values are copied in logical row-major order. `type_name` is
the original Haskell diagnostic type name; `dtype` is the standard scalar dtype
name where one exists. Generic numeric tensors permit NaN/Inf according to their
original numeric type; checked consumers such as neural layers retain their own
finite-value requirements.

`tensor_column_major` accepts column-major storage order. Views retain original
backing arrays after a parent owner closes. `contiguous` copies logical values
into row-major storage; reshape uses the original view/copy rules. Tensor
comparison calls the original Eq instance, including its NaN behavior. The
layout enums are `Layout.ROW_MAJOR`, `COLUMN_MAJOR`, `STRIDED`; `Device.CPU` is the
original supported device.

## Scalar callbacks and deferred graphs

```python
with tensor.tensor([2], [2, 3], dtype="float32") as values:
    with tensor.input_graph(values) as leaf:
        with tensor.map_graph(lambda x: x*x, leaf) as deferred:
            with tensor.evaluate_graph(deferred) as result:
                assert result.values == [4.0, 9.0]
```

`map_tensor` / `zip_tensor` accept scalar functions; `map_graph` / `zip_graph`
compose deferred functions and preserve original broadcast validation and
fusion. Graph construction does not call the function or allocate its output
array. Evaluation runs the original graph evaluator.

Numeric callback arguments are borrowed typed `NumericValue` objects: their
arithmetic operators and methods such as `.sin()` use the original element
instance, preserving Float computation. Bool and String inputs use ordinary
Python values. Copy `.value` or clone a typed scalar to retain a numeric input
past callback return. An optional `dtype` selects the output type; its default
is the first input's type. A callback can return a typed scalar of that type or
a representable ordinary value. Different typed outputs require explicit type
selection.

Python retains callback references transitively while derived handles can use
them. C function pointers/userdata must remain alive for that same lifetime.
Callbacks are synchronous and may reenter HMath. A checked callback failure uses
the [shared callback wire](errors.md#checked-callbacks): statuses 11, 12, 13
preserve full MathError, ExprError or InterchangeError payloads. Unexpected
Python exceptions abort and are re-raised after native temporary cleanup.

## Mutable tensors and borrowed storage

`new_mutable`, `thaw_tensor`, `read_mutable`, `write_mutable`, `modify_mutable`,
`slice_mutable`, `transpose_mutable`, `freeze_tensor` call the original IO APIs.
Pinned storage is shared by views; freeze/thaw copy, so later writes do not alter
an immutable frozen result. Callers synchronize concurrent writes. Mutable types
require an original Storable instance: standard Float/Double, complex,
fixed-width integers and Bool qualify; Integer/Rational and numeric towers do
not gain one through conversion. Structural providers may expose an existing
Storable instance.

```python
with tensor.new_mutable([3], 0, dtype="float32") as values:
    def fill(buffer):
        assert buffer.itemsize == 4
        buffer.pointer[0] = 7
        return buffer.shape

    assert tensor.with_mutable_buffer(values, fill) == [3]
    with tensor.freeze_tensor(values) as frozen:
        assert frozen.values == [7.0, 0.0, 0.0]
```

`with_mutable_buffer` holds the original ForeignPtr alive for the callback.
`BorrowedBuffer` provides logical `shape`, signed element `strides`, actual
Storable `itemsize`/`alignment` and a scoped typed ctypes `pointer`. Honor strides
and extents, and do not retain a pointer or use it after return. Accessing the
wrapper's pointer afterward raises ValueError. Bool uses the source Storable
Bool representation (CInt-sized on supported builds), independent of
Interchange Bool8's one-byte wire format; dtype16 never determines byte size by
itself. C receives the same pointer and metadata tuple
`(prototype, shape, strides, itemsize, alignment)`. The callback may return any
representable shared Value.

## C ownership and representations

Original immutable Double tensors use Value kind161, other typed tensors270,
graphs271, mutable views272, callback closures273 and structural type tokens294.
Every output owns one reference; use `hmath_value_release`. All live handles
reserve the runtime. Final shutdown returns BUSY until references and active
calls are gone. Inputs are borrowed for each call; do not race a final release
with its use. Public output pointer storage remains untouched on failure.
Mutable writes have the original operation's effects and synchronization rules.

C prototypes select an element type using an exact typed scalar, Boolean,
String or structural token; they are type witnesses, rather than fill values.
Use `hmath_tensor_object_callback` for scalar functions and
`hmath_tensor_object_buffer_callback` for borrowed-buffer functions. A successful
callback transfers one owned Value result. Scalar inputs are borrowed tuples;
retain a borrowed object before returning it. Structured errors use
`hmath_callback_error` and length-delimited strings. The additive
`hmath_tensor_object_full_typed` supplies a structural type token to original
`tensorFull` without requiring Num. All numerical algorithms remain the original
Haskell implementations.

## Function reference

Signatures below show Python argument order, including language-level dtype
selection. C wrappers follow original source argument order with an explicit
prototype where a source polymorphic type cannot be inferred. C `context` is
first, owned `Value **out` last. Details link to the original
[Tensor](haskell/HMath-Tensor.md) and
[mutable Tensor](haskell/HMath-Tensor-Mutable.md) references.

### HMath.Tensor

| Python callable/constructor | Result | C wrapper |
| --- | --- | --- |
| `RowMajor` | `Layout` | `hmath_tensor_object_row_major_create` |
| `ColumnMajor` | `Layout` | `hmath_tensor_object_column_major_create` |
| `Strided` | `Layout` | `hmath_tensor_object_strided_create` |
| `CPU` | `Device` | `hmath_tensor_object_cpu_create` |
| `tensor(shape, values, *, dtype='float64')` | `Tensor` | `hmath_tensor_object_tensor` |
| `tensor_column_major(shape, values, *, dtype='float64')` | `Tensor` | `hmath_tensor_object_tensor_column_major` |
| `tensor_full(shape, value, *, dtype=None)` | `Tensor` | `hmath_tensor_object_tensor_full` |
| `tensor_zeros(shape, *, dtype='float64')` | `Tensor` | `hmath_tensor_object_tensor_zeros` |
| `tensor_ones(shape, *, dtype='float64')` | `Tensor` | `hmath_tensor_object_tensor_ones` |
| `tensor_arange(start, end, step, *, dtype='float64')` | `Tensor` | `hmath_tensor_object_tensor_arange` |
| `tensor_linspace(start, end, count, *, dtype='float64')` | `Tensor` | `hmath_tensor_object_tensor_linspace` |
| `tensor_logspace(base, start, end, count, *, dtype='float64')` | `Tensor` | `hmath_tensor_object_tensor_logspace` |
| `tensor_random(seed, shape)` | `(Tensor,Integer)` | `hmath_tensor_object_tensor_random` |
| `tensor_values(tensor)` | `Elements` | `hmath_tensor_object_tensor_values` |
| `tensor_shape(tensor)` | `[Int]` | `hmath_tensor_object_tensor_shape` |
| `tensor_strides(tensor)` | `[Int]` | `hmath_tensor_object_tensor_strides` |
| `tensor_offset(tensor)` | `Int` | `hmath_tensor_object_tensor_offset` |
| `tensor_dtype(tensor)` | `String` | `hmath_tensor_object_tensor_d_type` |
| `tensor_device(tensor)` | `Device` | `hmath_tensor_object_tensor_device` |
| `tensor_layout(tensor)` | `Layout` | `hmath_tensor_object_tensor_layout` |
| `numel(tensor)` | `Int` | `hmath_tensor_object_numel` |
| `is_contiguous(tensor)` | `Bool` | `hmath_tensor_object_is_contiguous` |
| `shape_size(shape)` | `Int` | `hmath_tensor_object_shape_size` |
| `infer_broadcast(left, right)` | `[Int]` | `hmath_tensor_object_infer_broadcast` |
| `contiguous(tensor)` | `Tensor` | `hmath_tensor_object_contiguous` |
| `index_tensor(tensor, coordinates)` | `Element` | `hmath_tensor_object_index_tensor` |
| `slice_tensor(axis, start, count, step, tensor)` | `Tensor` | `hmath_tensor_object_slice_tensor` |
| `fancy_index(axis, indices, tensor)` | `Tensor` | `hmath_tensor_object_fancy_index` |
| `gather(axis, indices, tensor)` | `Tensor` | `hmath_tensor_object_gather` |
| `boolean_index(mask, tensor)` | `Tensor` | `hmath_tensor_object_boolean_index` |
| `scatter(axis, indices, updates, target)` | `Tensor` | `hmath_tensor_object_scatter` |
| `scatter_add(axis, indices, updates, target)` | `Tensor` | `hmath_tensor_object_scatter_add` |
| `reshape_tensor(shape, tensor)` | `Tensor` | `hmath_tensor_object_reshape_tensor` |
| `flatten_tensor(tensor)` | `Tensor` | `hmath_tensor_object_flatten_tensor` |
| `squeeze(tensor)` | `Tensor` | `hmath_tensor_object_squeeze` |
| `unsqueeze(axis, tensor)` | `Tensor` | `hmath_tensor_object_unsqueeze` |
| `expand(shape, tensor)` | `Tensor` | `hmath_tensor_object_expand` |
| `permute(axes, tensor)` | `Tensor` | `hmath_tensor_object_permute` |
| `transpose_tensor(tensor)` | `Tensor` | `hmath_tensor_object_transpose_tensor` |
| `move_axis(from_axis, to_axis, tensor)` | `Tensor` | `hmath_tensor_object_move_axis` |
| `swap_axes(from_axis, to_axis, tensor)` | `Tensor` | `hmath_tensor_object_swap_axes` |
| `broadcast_to(shape, tensor)` | `Tensor` | `hmath_tensor_object_broadcast_to` |
| `repeat_tensor(axis, count, tensor)` | `Tensor` | `hmath_tensor_object_repeat_tensor` |
| `tile(counts, tensor)` | `Tensor` | `hmath_tensor_object_tile` |
| `concatenate(axis, tensors, *, dtype=None)` | `Tensor` | `hmath_tensor_object_concatenate` |
| `stack(axis, tensors, *, dtype=None)` | `Tensor` | `hmath_tensor_object_stack` |
| `split_tensor(axis, segments, tensor)` | `[Tensor]` | `hmath_tensor_object_split_tensor` |
| `chunk_tensor(axis, count, tensor)` | `[Tensor]` | `hmath_tensor_object_chunk_tensor` |
| `pad_tensor(padding, value, tensor)` | `Tensor` | `hmath_tensor_object_pad_tensor` |
| `roll(axis, shift, tensor)` | `Tensor` | `hmath_tensor_object_roll` |
| `flip_tensor(axis, tensor)` | `Tensor` | `hmath_tensor_object_flip_tensor` |
| `rotate(first, second, turns, tensor)` | `Tensor` | `hmath_tensor_object_rotate` |
| `sort_tensor(tensor)` | `Tensor` | `hmath_tensor_object_sort_tensor` |
| `unique(tensor)` | `Tensor` | `hmath_tensor_object_unique` |
| `argsort(tensor)` | `Tensor` | `hmath_tensor_object_argsort` |
| `topk(count, tensor)` | `(Tensor,Tensor)` | `hmath_tensor_object_topk` |
| `nonzero(tensor)` | `Tensor` | `hmath_tensor_object_nonzero` |
| `where_tensor(mask, left, right)` | `Tensor` | `hmath_tensor_object_where_tensor` |
| `masked_fill(mask, value, tensor)` | `Tensor` | `hmath_tensor_object_masked_fill` |
| `masked_select(mask, tensor)` | `Tensor` | `hmath_tensor_object_masked_select` |
| `map_tensor(function, tensor, *, dtype=None)` | `Tensor` | `hmath_tensor_object_map_tensor` |
| `zip_tensor(function, left, right, *, dtype=None)` | `Tensor` | `hmath_tensor_object_zip_tensor` |
| `tensor_add(a, b)` | `Tensor` | `hmath_tensor_object_tensor_add` |
| `tensor_subtract(a, b)` | `Tensor` | `hmath_tensor_object_tensor_subtract` |
| `tensor_multiply(a, b)` | `Tensor` | `hmath_tensor_object_tensor_multiply` |
| `tensor_divide(a, b)` | `Tensor` | `hmath_tensor_object_tensor_divide` |
| `tensor_equal(a, b)` | `Tensor` | `hmath_tensor_object_tensor_equal` |
| `tensor_less(a, b)` | `Tensor` | `hmath_tensor_object_tensor_less` |
| `tensor_and(a, b)` | `Tensor` | `hmath_tensor_object_tensor_and` |
| `tensor_or(a, b)` | `Tensor` | `hmath_tensor_object_tensor_or` |
| `tensor_not(tensor)` | `Tensor` | `hmath_tensor_object_tensor_not` |
| `promote_tensor(dtype, tensor)` | `Tensor` | `hmath_tensor_object_promote_tensor` |
| `sum_axes(axes, keep_dimensions, tensor)` | `Tensor` | `hmath_tensor_object_sum_axes` |
| `product_axes(axes, keep_dimensions, tensor)` | `Tensor` | `hmath_tensor_object_product_axes` |
| `mean_axes(axes, keep_dimensions, tensor)` | `Tensor` | `hmath_tensor_object_mean_axes` |
| `variance_axes(axes, keep_dimensions, tensor)` | `Tensor` | `hmath_tensor_object_variance_axes` |
| `norm_axes(axes, keep_dimensions, tensor)` | `Tensor` | `hmath_tensor_object_norm_axes` |
| `min_axes(axes, keep_dimensions, tensor)` | `Tensor` | `hmath_tensor_object_min_axes` |
| `max_axes(axes, keep_dimensions, tensor)` | `Tensor` | `hmath_tensor_object_max_axes` |
| `argmin(tensor)` | `Int` | `hmath_tensor_object_argmin` |
| `argmax(tensor)` | `Int` | `hmath_tensor_object_argmax` |
| `cumulative_sum(axis, tensor)` | `Tensor` | `hmath_tensor_object_cumulative_sum` |
| `cumulative_product(axis, tensor)` | `Tensor` | `hmath_tensor_object_cumulative_product` |
| `tensordot(left_axes, right_axes, left, right)` | `Tensor` | `hmath_tensor_object_tensordot` |
| `einsum(labels, output, tensors, *, dtype=None)` | `Tensor` | `hmath_tensor_object_einsum` |
| `batched_matmul(a, b)` | `Tensor` | `hmath_tensor_object_batched_matmul` |
| `tensor_kronecker(a, b)` | `Tensor` | `hmath_tensor_object_tensor_kronecker` |
| `serialize_tensor(tensor)` | `String` | `hmath_tensor_object_serialize_tensor` |
| `deserialize_tensor(source, *, dtype='float64')` | `Tensor` | `hmath_tensor_object_deserialize_tensor` |
| `input_graph(tensor)` | `TensorGraph` | `hmath_tensor_object_input_graph` |
| `map_graph(function, graph, *, dtype=None)` | `TensorGraph` | `hmath_tensor_object_map_graph` |
| `zip_graph(function, left, right, *, dtype=None)` | `TensorGraph` | `hmath_tensor_object_zip_graph` |
| `evaluate_graph(tensor)` | `Tensor` | `hmath_tensor_object_evaluate_graph` |

#### `tensor(shape, values, *, dtype='float64')`

Given shape then flat row-major values, construct an immutable CPU tensor. Require exactly the shape product values; invalid dimensions/count return Left MathError. Generic values are not validated for finiteness.

#### `tensor_column_major(shape, values, *, dtype='float64')`

Given shape then values in column-major storage order, construct a column-major CPU tensor. Validate shape/count as tensor; logical tensorValues still traverses row-major coordinates.

#### `tensor_full(shape, value, *, dtype=None)`

Given shape then fill value, construct an immutable row-major tensor with every element equal to that value. Invalid/overflowing shape fails.

#### `tensor_zeros(shape, *, dtype='float64')`

Construct a row-major tensor of zeros with the supplied shape. Invalid dimensions or element-product overflow return Left MathError.

#### `tensor_ones(shape, *, dtype='float64')`

Construct a row-major tensor of ones with the supplied shape. Scalars contain one 1; zero axes contain no values.

#### `tensor_arange(start, end, step, *, dtype='float64')`

Given finite start, exclusive stop, and nonzero finite step, construct a rank-one arithmetic progression. A step pointing away from stop yields empty output. Reject invalid inputs or Int-size count overflow.

#### `tensor_linspace(start, end, count, *, dtype='float64')`

Given start, stop, then nonnegative count, return a rank-one evenly spaced sequence including both endpoints when count>=2. Count zero gives empty, count one gives start. Negative count fails; generic arithmetic is unchecked.

#### `tensor_logspace(base, start, end, count, *, dtype='float64')`

Given base, starting exponent, ending exponent, then count, return base raised to tensorLinspace exponents. Negative count fails; Floating domain/overflow behavior follows the element type.

#### `tensor_random(seed, shape)`

Explicit deterministic LCG seed. Values are uniform in [0,1); the returned seed continues the stream, and does not access global mutable generator state.

#### `tensor_values(tensor)`

Return logical values in row-major coordinate order, honoring strides/offsets rather than exposing raw backing storage.

#### `tensor_shape(tensor)`

Return dimensions in axis order. Scalar shape is []; empty axes are retained.

#### `tensor_strides(tensor)`

Return signed element strides for each axis. These describe shared views; they are not byte offsets and can be zero (broadcast) or negative (reverse slices).

#### `tensor_offset(tensor)`

Return backing-array offset in elements of the logical coordinate origin. Combine with tensorStrides for view indexing.

#### `tensor_dtype(tensor)`

Return the Typeable element type name as a String. This is diagnostic metadata, not an implicit conversion or stable external dtype code.

#### `tensor_device(tensor)`

Return CPU, the supported device for this Haskell tensor implementation.

#### `tensor_layout(tensor)`

Classify canonical row-major strides first, then column-major, otherwise Strided. Ambiguous single-axis layouts are classified RowMajor.

#### `numel(tensor)`

Return logical element count (product of shape), including one for scalars and zero for any empty axis.

#### `is_contiguous(tensor)`

Test whether stored strides exactly match canonical row-major strides for this shape. Offset does not prevent a contiguous view; column-major layouts generally return False.

#### `shape_size(shape)`

Validate nonnegative dimensions and return their product as Int. Scalar [] has one element; a zero axis gives zero. Negative dimensions or an Int-overflowing product return Left InvalidArgument. Haskell tensors do not inherit the C ABI's smaller rank/element caps.

#### `infer_broadcast(left, right)`

Given two shapes, align trailing dimensions; equal sizes or a size-one dimension are compatible. Return the broadcasted shape after nonnegative/Int-size validation; incompatible dimensions fail.

#### `contiguous(tensor)`

Copy logical values into a new canonical row-major tensor of the same shape. Return checked construction result; existing views remain unchanged.

#### `index_tensor(tensor, coordinates)`

Given tensor then complete zero-based coordinate list, return the element. Wrong coordinate rank or out-of-range index returns Left InvalidArgument.

#### `slice_tensor(axis, start, count, step, tensor)`

Given axis,start,count,nonzero step,then tensor, return a zero-copy strided view. Negative steps are supported with valid reachable coordinates. Invalid axis/extent, stride overflow or backing bounds return Left MathError.

#### `fancy_index(axis, indices, tensor)`

Given axis then index list then tensor, copy selected positions along that axis in index-list order, retaining duplicates. Invalid axis/indices or output-size overflow fail.

#### `gather(axis, indices, tensor)`

Alias of fancyIndex: given axis, zero-based index list, then tensor, copy those axis positions. Invalid axis/indices fail; index-list order and duplicates are preserved.

#### `boolean_index(mask, tensor)`

Given an identically shaped Bool mask then tensor, return a rank-one tensor of values whose mask is True, in logical row-major order. Mask mismatch fails; alias of maskedSelect.

#### `scatter(axis, indices, updates, target)`

Given axis,index list,update tensor,then target, return a new target-shaped tensor with updates written to selected positions. Update shape replaces that axis with index-list length; invalid shape/indices fail. Repeated indices use the last update in traversal order.

#### `scatter_add(axis, indices, updates, target)`

Given axis,indices,updates,target, return a new target with updates added at selected coordinates. Duplicate indices accumulate; update shape and indices follow scatter validation.

#### `reshape_tensor(shape, tensor)`

Given new dimensions then tensor, preserve logical element order with unchanged count. Contiguous input yields a shared view; non-contiguous input is copied. Invalid dimensions/count fail; no -1 inference.

#### `flatten_tensor(tensor)`

Reshape to rank one with numel entries in logical row-major order. Shares contiguous storage and copies non-contiguous input; checked reshape errors propagate.

#### `squeeze(tensor)`

Remove every length-one axis as a shared view, preserving storage and logical values. A single-element all-one shape becomes scalar [].

#### `unsqueeze(axis, tensor)`

Given insertion axis in [0,rank] then tensor, insert a length-one dimension as a shared view. Out-of-range axis returns Left InvalidArgument.

#### `expand(shape, tensor)`

Alias of broadcastTo: expand singleton dimensions to a requested compatible target shape without copying values. Invalid broadcast shapes fail.

#### `permute(axes, tensor)`

Given a permutation of all zero-based axes then tensor, return a zero-copy view with shape/strides reordered. Missing, duplicate or invalid axes fail.

#### `transpose_tensor(tensor)`

Reverse every axis of a tensor as a shared view. For rank two this exchanges rows/columns; it is not restricted to matrices.

#### `move_axis(from_axis, to_axis, tensor)`

Given source axis,destination axis,then tensor, move one axis while preserving the order of others. Both axes must identify existing dimensions; invalid axes fail.

#### `swap_axes(from_axis, to_axis, tensor)`

Given two existing axes then tensor, exchange their dimensions/strides in a shared view. Invalid axes return Left MathError.

#### `broadcast_to(shape, tensor)`

Given target shape then tensor, return a shared zero-stride view where existing/trailing size-one axes can expand. Target must be exactly a valid broadcast destination; incompatible/overflowing shapes fail.

#### `repeat_tensor(axis, count, tensor)`

Given axis,repetition count,then tensor, repeat each individual axis position consecutively. Nonnegative count is required; zero yields an empty axis. Invalid axis/count or size overflow fails.

#### `tile(counts, tensor)`

Given one nonnegative repetition count per existing axis then tensor, tile whole axis contents into repeated blocks. Rank mismatch, negative repetitions or resulting size overflow fail.

#### `concatenate(axis, tensors, *, dtype=None)`

Given existing axis then nonempty tensor list, copy tensors end-to-end along that axis. All other dimensions must match; empty list, axis/shape mismatch or size overflow fails.

#### `stack(axis, tensors, *, dtype=None)`

Given insertion axis then nonempty list of equally shaped tensors, insert that axis and concatenate along it. Invalid insertion axis or incompatible input shapes fail.

#### `split_tensor(axis, segments, tensor)`

Given axis,nonnegative segment sizes,then tensor, return shared slices partitioning that axis exactly. Sizes must sum to the axis length; invalid axis/partition fails.

#### `chunk_tensor(axis, count, tensor)`

Given axis,positive chunk count,then tensor, split into exactly that many near-equal shared slices; earlier chunks get the remainder. Empty chunks are allowed if chunks exceed axis size. Invalid axis/count fails.

#### `pad_tensor(padding, value, tensor)`

Given (before,after) nonnegative padding for every axis,fill value,then tensor, copy into a padded output. Rank mismatch, negative padding or output-size overflow fails.

#### `roll(axis, shift, tensor)`

Given axis,signed shift,then tensor, cyclically shift elements along the axis, preserving shape. Positive shifts move values toward larger indices. Invalid axis fails; the output is copied.

#### `flip_tensor(axis, tensor)`

Given axis then tensor, reverse that axis using a negative-stride shared slice. Invalid axis returns Left MathError.

#### `rotate(first, second, turns, tensor)`

Given two distinct axes,integer quarter-turn count,then tensor, repeatedly swap axes and flip the first. Turns are reduced modulo four; invalid/equal axes fail.

#### `sort_tensor(tensor)`

Flatten logical values and return a rank-one tensor sorted ascending under Ord. Original shape is not preserved.

#### `unique(tensor)`

Return sorted distinct logical values as a rank-one tensor. Input shape/order are not preserved.

#### `argsort(tensor)`

Flatten logical values and return a rank-one tensor of stable zero-based ascending-sort indices. Ties preserve original order.

#### `topk(count, tensor)`

Given k in [0,numel] then tensor, return rank-one (values,flat indices) for k largest values in descending order. Equal values use reverse stable-sort order. Invalid k fails.

#### `nonzero(tensor)`

Return a count-by-rank tensor of zero-based coordinates of nonzero elements in row-major traversal order. For a nonzero scalar the shape is [1,0].

#### `where_tensor(mask, left, right)`

Given Bool mask,yes tensor,no tensor, broadcast all three shapes and select yes/no values elementwise. Incompatible/overflowing broadcast shapes return Left MathError.

#### `masked_fill(mask, value, tensor)`

Given broadcastable mask,fill value,then tensor, return a copied result with True positions replaced. Incompatible mask broadcast or output construction fails.

#### `masked_select(mask, tensor)`

Given mask then identically shaped tensor, return a rank-one copy of True-selected values in row-major order. Shape mismatch returns Left InvalidArgument.

#### `map_tensor(function, tensor, *, dtype=None)`

Apply scalar arithmetic, comparisons, logic, or elementary functions such as `sin`, `exp`, and `log` to each logical element. A contiguous output is created; scalar numeric domain/overflow behavior follows the supplied function.

#### `zip_tensor(function, left, right, *, dtype=None)`

Given binary element function then two tensors, broadcast compatible shapes and return a new contiguous result. Shape/size failures return Left MathError; function evaluation/domain errors follow the supplied function.

#### `tensor_add(a, b)`

Given two tensors, broadcast compatible shapes and add corresponding values, returning a new contiguous tensor. Incompatible/overflowing broadcast shapes return Left MathError.

#### `tensor_subtract(a, b)`

Given two tensors, broadcast compatible shapes and subtract right values from left, returning a new contiguous tensor. Incompatible/overflowing broadcast shapes return Left MathError.

#### `tensor_multiply(a, b)`

Given two tensors, broadcast compatible shapes and multiply corresponding values, returning a new contiguous tensor. Incompatible/overflowing broadcast shapes return Left MathError.

#### `tensor_divide(a, b)`

Given two tensors, broadcast compatible shapes and divide left values by right, returning a new contiguous tensor. Incompatible/overflowing broadcast shapes return Left MathError. Division-by-zero/non-finite behavior follows Fractional; it is not additionally checked.

#### `tensor_equal(a, b)`

Given two tensors, broadcast compatible shapes and compare corresponding values for equality, returning a new contiguous tensor. Incompatible/overflowing broadcast shapes return Left MathError.

#### `tensor_less(a, b)`

Given two tensors, broadcast compatible shapes and compare corresponding values with (\<), returning a new contiguous tensor. Incompatible/overflowing broadcast shapes return Left MathError.

#### `tensor_and(a, b)`

Given two tensors, broadcast compatible shapes and combine Bool values with logical AND, returning a new contiguous tensor. Incompatible/overflowing broadcast shapes return Left MathError.

#### `tensor_or(a, b)`

Given two tensors, broadcast compatible shapes and combine Bool values with logical OR, returning a new contiguous tensor. Incompatible/overflowing broadcast shapes return Left MathError.

#### `tensor_not(tensor)`

Negate each Bool element, returning a new contiguous tensor of the same shape. No broadcast or ownership mutation occurs.

#### `promote_tensor(dtype, tensor)`

Explicitly convert each Real element through exact Rational to the destination Fractional type, preserving shape. Destination rounding/overflow follows its conversion; no implicit promotion occurs elsewhere.

#### `sum_axes(axes, keep_dimensions, tensor)`

Given unique zero-based axis list,keep-dimensions Bool,then tensor, reduce those axes by sum. True retains reduced dimensions as size one; False removes them. Invalid/duplicate axes fail. Empty reduced groups use zero.

#### `product_axes(axes, keep_dimensions, tensor)`

Given unique zero-based axis list,keep-dimensions Bool,then tensor, reduce those axes by product. True retains reduced dimensions as size one; False removes them. Invalid/duplicate axes fail. Empty reduced groups use one.

#### `mean_axes(axes, keep_dimensions, tensor)`

Given unique zero-based axis list,keep-dimensions Bool,then tensor, reduce those axes by arithmetic mean. True retains reduced dimensions as size one; False removes them. Invalid/duplicate axes fail. Nonempty output with an empty reduced group fails.

#### `variance_axes(axes, keep_dimensions, tensor)`

Given unique zero-based axis list,keep-dimensions Bool,then tensor, reduce those axes by population variance (dividing by group size). True retains reduced dimensions as size one; False removes them. Invalid/duplicate axes fail. Empty reduced groups fail as meanAxes.

#### `norm_axes(axes, keep_dimensions, tensor)`

Given unique zero-based axis list,keep-dimensions Bool,then tensor, reduce those axes by scaled Euclidean norm. True retains reduced dimensions as size one; False removes them. Invalid/duplicate axes fail. Empty groups have norm zero; IEEE NaN/infinity propagate.

#### `min_axes(axes, keep_dimensions, tensor)`

Given unique zero-based axis list,keep-dimensions Bool,then tensor, reduce those axes by minimum. True retains reduced dimensions as size one; False removes them. Invalid/duplicate axes fail. Empty reduced groups fail.

#### `max_axes(axes, keep_dimensions, tensor)`

Given unique zero-based axis list,keep-dimensions Bool,then tensor, reduce those axes by maximum. True retains reduced dimensions as size one; False removes them. Invalid/duplicate axes fail. Empty reduced groups fail.

#### `argmin(tensor)`

Return first zero-based flat row-major index of a minimum logical element. Empty input returns Left DomainError.

#### `argmax(tensor)`

Return first zero-based flat row-major index of a maximum logical element. Empty input returns Left DomainError.

#### `cumulative_sum(axis, tensor)`

Given existing axis then tensor, return inclusive running sums along that axis, preserving shape. Invalid axis fails; arithmetic follows Num.

#### `cumulative_product(axis, tensor)`

Given existing axis then tensor, return inclusive running products along that axis, preserving shape. Invalid axis fails; arithmetic follows Num.

#### `tensordot(left_axes, right_axes, left, right)`

Given contraction axes for the first tensor,axes for the second,then both tensors, sum products over matched axis pairs. Noncontracted left axes precede right axes in the output. Reject duplicate/out-of-range axes or mismatched contraction dimensions.

#### `einsum(labels, output, tensors, *, dtype=None)`

Explicit Einstein notation; each operand has one label per axis. Repeated labels select diagonals; absent output labels are summed. Ellipses are not accepted: callers express batch labels explicitly, preventing ambiguity.

#### `batched_matmul(a, b)`

Multiply tensors on their final two dimensions and broadcast leading batch dimensions. Require rank>=2 and matching inner dimensions; incompatible broadcast or size overflow fails. Generic Num arithmetic is unchanged.

#### `tensor_kronecker(a, b)`

Return multidimensional Kronecker product, left-padding the lower-rank shape with ones and multiplying corresponding axis sizes. Invalid/overflowing resulting dimensions fail.

#### `serialize_tensor(tensor)`

Serialize (shape,logical row-major values) using Haskell Show. Storage strides/offsets are not retained; the encoding requires a compatible Read instance for round-trip.

#### `deserialize_tensor(source, *, dtype='float64')`

Read a complete Haskell (shape,values) encoding, permitting only trailing whitespace, and validate shape/count. Malformed input or invalid dimensions/count returns Left MathError.

#### `input_graph(tensor)`

Wrap an immutable tensor as a lazy TensorGraph leaf, retaining its backing storage without evaluating a new output array.

#### `map_graph(function, graph, *, dtype=None)`

Given element function then graph, compose a lazy element transform, preserving shape. No output tensor is allocated until evaluateGraph.

#### `zip_graph(function, left, right, *, dtype=None)`

Given binary function then two graphs, validate broadcast shapes and return a fused lazy graph. Incompatible shapes return Left MathError before evaluation.

#### `evaluate_graph(tensor)`

Evaluate a lazy graph into one contiguous row-major tensor. Adjacent map/zip operations are fused; scalar evaluation behavior follows supplied functions and checked output shape errors propagate.

### HMath.Tensor.Mutable

| Python callable/constructor | Result | C wrapper |
| --- | --- | --- |
| `new_mutable(shape, value, *, dtype='float64')` | `MutableTensor` | `hmath_tensor_object_new_mutable` |
| `thaw_tensor(tensor)` | `MutableTensor` | `hmath_tensor_object_thaw_tensor` |
| `freeze_tensor(tensor)` | `Tensor` | `hmath_tensor_object_freeze_tensor` |
| `mutable_shape(tensor)` | `[Int]` | `hmath_tensor_object_mutable_shape` |
| `read_mutable(tensor, coordinates)` | `Element` | `hmath_tensor_object_read_mutable` |
| `write_mutable(tensor, coordinates, value)` | `Unit` | `hmath_tensor_object_write_mutable` |
| `modify_mutable(tensor, coordinates, function)` | `Unit` | `hmath_tensor_object_modify_mutable` |
| `slice_mutable(axis, start, count, step, tensor)` | `MutableTensor` | `hmath_tensor_object_slice_mutable` |
| `transpose_mutable(tensor)` | `MutableTensor` | `hmath_tensor_object_transpose_mutable` |
| `mutable_alignment(dtype)` | `Int` | `hmath_tensor_object_mutable_alignment` |
| `with_mutable_buffer(tensor, function)` | `Generic` | `hmath_tensor_object_with_mutable_buffer` |

#### `new_mutable(shape, value, *, dtype='float64')`

Given checked dimensions then fill value, allocate pinned row-major storage filled with that value. Shape/byte-size overflow returns Left MathError; allocation errors remain IO exceptions. Empty tensors are valid.

#### `thaw_tensor(tensor)`

Copy logical immutable tensor values to new contiguous pinned mutable storage. Byte-size overflow returns Left InvalidArgument; allocation failures remain IO exceptions. The source stays unchanged.

#### `freeze_tensor(tensor)`

Copy current logical view values into a new immutable tensor in row-major order. Return checked tensor construction errors; later mutable writes do not affect the result.

#### `mutable_shape(tensor)`

Return current mutable-view dimensions in axis order. Slices/transposes can change the view shape while sharing storage.

#### `read_mutable(tensor, coordinates)`

Given a mutable view then full zero-based coordinate list, read one element through the view strides. Wrong rank or out-of-range coordinates return Left InvalidArgument. Callers synchronize concurrent writes.

#### `write_mutable(tensor, coordinates, value)`

Given a mutable view, full coordinate list, then value, update that storage element. Invalid coordinates return Left InvalidArgument without writing; synchronize concurrent access externally.

#### `modify_mutable(tensor, coordinates, function)`

Given view, coordinates, then transformation, read and replace an element. Invalid coordinates fail. This read-modify-write is not atomic across threads; callers provide synchronization.

#### `slice_mutable(axis, start, count, step, tensor)`

Given axis, start, count, nonzero step, then view, return a zero-copy mutable slice retaining shared ForeignPtr ownership. Negative steps are supported if all reached indices stay in bounds. Invalid extent/axis or stride overflow fails.

#### `transpose_mutable(tensor)`

Reverse the order of all shape axes and strides, returning a zero-copy mutable view. For rank two this is a matrix transpose; storage ownership remains shared.

#### `mutable_alignment(dtype)`

Given a type Proxy, return the Storable ABI alignment in bytes. This reports the element type requirement, not a user-selectable alignment.

#### `with_mutable_buffer(tensor, function)`

The pointer is valid only during the callback. Shape/strides describe views; callbacks must honor their extents and may not retain the borrowed pointer.
