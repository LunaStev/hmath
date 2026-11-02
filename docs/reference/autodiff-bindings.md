# Automatic differentiation bindings

These C and Python interfaces call `HMath.Autodiff`. They retain its checked
input domains, graph node budget, accumulation rules and derivative conventions.
Scalar expressions, compiled graphs, gradient states and symbolic tensors are
immutable Haskell values with independently owned references.

Include `hmath_autodiff.h` in C or C++; use `from hmath import autodiff as ad` in
Python. Numerical reverse-graph evaluation uses the original binary64 implementation.
`Dual`, `primal`, `tangent` and `forward` support arbitrary nesting over `Double`,
`Float`, `Integer` and `Rational` leaves. Float arithmetic stays Float; exact
leaves never pass through floating-point intermediates. Other generic leaf
instances remain pending and are not claimed by this page.

## Ownership and errors

Each returned C handle owns one reference. `hmath_ad_retain(value)` adds a
reference; `hmath_ad_release(value)` removes one. Both accept `NULL`. The caller
holds an input reference throughout a call, and never races final release with
use. Every live handle reserves the Haskell runtime: final shutdown returns
`HMATH_BUSY` until those references are released. Expressions/graphs retain their
Haskell dependencies independently; releasing a source expression does not
invalidate a compiled graph or derivative.

Python objects provide idempotent `close()` and `with` blocks. Their destructor
is a fallback. A closed object rejects use with `ValueError`. Operations pin
input references during calls, including reentrant callbacks. Sharing immutable
objects across threads is supported; caller output buffers must be independent.

C arrays are borrowed for the call. Outputs must not overlap inputs or each
other. Output capacity is measured in elements, not bytes. Insufficient capacity
returns `HMATH_BOUNDS_ERROR`; outputs remain untouched on failure. A `NULL`
context disables cancellation; otherwise cancellation is checked before entry.
An in-flight Haskell operation is not asynchronously interrupted.

Original `Left MathError` values become `HMATH_MATH_ERROR` in C and `HMathError`
with `status == 11` in Python. The error message retains the original constructor
and payload. Pure Haskell exceptions become status 6. Invalid native pointers,
wrong handle kinds, buffer capacities and allocation failures are binding errors.
No extra finite check is added to unchecked Dual arithmetic or the raw
`GradientState` constructor.

## Scalar expressions and graphs

| Python | C | Contract |
| --- | --- | --- |
| `variable(index)` | `hmath_ad_variable` | Declare a zero-based graph input. The original `compileGraph` checks index validity, including negative indices. |
| `constant(value)` | `hmath_ad_constant` | Embed a `Double`; non-finite literals are rejected during graph compilation, not construction. |
| `compile_graph(input_count, expression)` | `hmath_ad_compile_graph` | Compile a reusable graph with exactly that many inputs. The C parameter named `index` is this input count. Original maximum is one million scalar nodes. |
| `evaluate_graph(graph, values)` / `graph.evaluate(values)` | `hmath_ad_evaluate_graph` | Re-evaluate with exactly the declared number of finite inputs. |
| `differentiate(index, expression)` | `hmath_ad_differentiate` | Construct a symbolic derivative. Opaque custom rules retain their original higher-order rejection. |
| `detach(expression)` | `hmath_ad_unary` with `HMATH_AD_DETACH` | Preserve the primal while dropping reverse edges. |
| `stop_gradient(expression)` | `hmath_ad_unary` with `HMATH_AD_STOP_GRADIENT` | Original `stopGradient` alias. |

Python `Expr` implements `+`, `-`, `*`, `/`, `**`, unary `-` and `abs` through
original Haskell instances. Scalar literals are converted to native constants.
C uses `hmath_ad_binary` and `hmath_ad_unary` with the enums in the header.
Python unary helpers are `negate`, `absolute`, `sign`, `reciprocal`, `exp`, `log`,
`sqrt`, `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `sinh`, `cosh`, `tanh`,
`asinh`, `acosh` and `atanh`. These also operate on `Dual` values where the
corresponding Haskell instance exists. Dual comparisons use the original Eq/Ord
instances: equality includes both fields, while ordering compares primal fields
only, recursively. This intentionally preserves their distinction when two
Dual values have equal primals but different tangents.

```python
from hmath import autodiff as ad

with ad.variable(0) as x:
    with ad.compile_graph(1, x * x + 1) as graph:
        assert graph.evaluate([3]) == 10
        assert graph.evaluate([4]) == 17
```

See the [original expression and compilation contracts](haskell/HMath-Autodiff.md#v:compileGraph).

## Reverse derivatives and products

Python builders are pure functions receiving a list of `Expr` inputs. They return
one expression for scalar objectives or a sequence for vector objectives. An
existing expression, or sequence of expressions, may be passed instead of a
builder. The C interface receives those explicit expression handles. A builder's
external Python side effects and evaluation count are not part of its mathematical
contract; build expressions only from the supplied inputs and deterministic rules.

| Python signature | C function | Returned result / C flat output layout |
| --- | --- | --- |
| `value_and_gradient(function, values)` | `hmath_ad_value_and_gradient` | `(value, gradient)` / `[value, gradient...]`, capacity `n+1`. Repeated input leaves accumulate. |
| `gradient(function, values)` | `hmath_ad_gradient` | Fresh length-`n` list; no ambient accumulation. |
| `hessian(function, values)` | `hmath_ad_hessian` | `n` rows of `n` symbolic second derivatives / row-major `n*n`. |
| `jacobian(function, values)` | `hmath_ad_jacobian` | `m` output-by-input rows / row-major `m*n`; empty outputs preserve shape. |
| `jvp(function, values, direction)` | `hmath_ad_jvp` | Jacobian times input direction, length `m`; original direction length/finite checks. |
| `vjp(function, values, direction)` | `hmath_ad_vjp` | Output cotangent times Jacobian, length `n`; direction length is `m`. |
| `hvp(function, values, direction)` | `hmath_ad_hvp` | Hessian times input direction, length `n`. |
| `gradient_check(step, function, values)` | `hmath_ad_gradient_check` | Maximum absolute discrepancy from central finite differences; positive finite `step` is required. |
| `complex_gradient(function, value)` | `hmath_ad_complex_gradient` | Complex Wirtinger derivative; the builder receives `[real, imaginary]`. C input/output are two real coordinates. The original convention divides real-coordinate derivatives by two. |
| `differentiable_step(rate, function, expressions)` | `hmath_ad_differentiable_step` | Updated symbolic expressions preserving outer derivatives. C returns a rank-one ADTensor; retrieve its owned expression references. |

Here `n` is input count and `m` is output expression count. Native result products
are checked for representable sizes before allocating/writing memory. The original
`MathError` values cover invalid lengths, non-finite values, invalid tolerances,
invalid graph indices and graph-budget exhaustion.

```python
from hmath import autodiff as ad

def objective(xs):
    x, y = xs
    return x * x + x * y

assert ad.value_and_gradient(objective, [3, 4]) == (21, [10, 3])
assert ad.hessian(objective, [3, 4]) == [[2, 1], [1, 0]]
assert ad.hvp(objective, [3, 4], [2, -1]) == [3, 2]
```

See [reverse differentiation](haskell/HMath-Autodiff.md#v:valueAndGradient),
[Jacobian](haskell/HMath-Autodiff.md#v:jacobian),
[Hessian](haskell/HMath-Autodiff.md#v:hessian),
and [differentiable steps](haskell/HMath-Autodiff.md#v:differentiableStep).

## Dual forward mode

`Dual(value, tangent, dtype=None)` uses the original `Dual` numeric instances.
The default leaf type is `Double`; nested values inherit the component type.
Supported explicit choices are:

| Python dtype | Original Haskell leaf | C constructor | Available classes |
| --- | --- | --- | --- |
| `"float64"` | `Double` | `hmath_ad_dual_create` | Num, Fractional, Floating, Eq, Ord |
| `"float32"` | `Float` | `hmath_ad_dual_create_f32` | Num, Fractional, Floating, Eq, Ord |
| `"integer"` | `Integer` | `hmath_ad_dual_create_integer` | Num, Eq, Ord |
| `"rational"` | `Rational` | `hmath_ad_dual_create_rational` | Num, Fractional, Eq, Ord |
| `"complex64"`, `"complex128"` | `Complex Float`, `Complex Double` | shared Value export + `hmath_ad_dual_nested` | Num, Fractional, Floating, Eq |
| `"int8"` … `"int64"`, `"intp"` | Signed bounded integers / native Int | shared Value export + `hmath_ad_dual_nested` | Num, Eq, Ord |
| `"uint8"` … `"uint64"`, `"uintp"` | Unsigned bounded integers / native Word | shared Value export + `hmath_ad_dual_nested` | Num, Eq, Ord |
| Typed NumericValue prototype | Original Numeric.Dual towers or Quaternion Float/Double | shared Value export + `hmath_ad_dual_nested` | Original leaf dictionaries only |

Unsupported class operations reject the request, such as Integer division or
Rational exp; they never silently convert to Double. `dual.dtype` reports the
leaf type and `dual.depth` reports nesting depth. Components may themselves be
Dual values of the same scalar type/depth.
Numeric literals are embedded at that depth/type with zero tangents, following the
original Num instance. Mixing already constructed incompatible depths is a
`TypeError`, corresponding to incompatible Haskell types.
`primal(dual)` / `dual.primal` and `tangent(dual)` / `dual.tangent` extract their
respective components. C constructs a dual with `hmath_ad_dual_create` and copies
`[primal, tangent]` through `hmath_ad_values_copy` for flat Dual values. For
nested values, `hmath_ad_dual_nested` constructs the next level and
`hmath_ad_dual_parts` returns two independently owned component handles.
`hmath_ad_dual_depth` reports nesting depth; scalar component handles have depth
zero. Flat Double/Float leaves support their compatible floating copy view.
Python unwraps standard scalar leaves to floats, complex values, exact integers
or fractions
and returns Dual objects for nested components. Integer/Rational constructors use
signed decimal strings, with separate rational numerator/denominator strings.
The compatible Integer/Rational component accessor is `hmath_ad_scalar_text`;
free both returned
strings with `hmath_ad_string_free`. Python exposes those leaves as arbitrary
precision `int` and `fractions.Fraction`, including beyond Python's decimal
conversion digit cap. Integer/Rational and other typed coefficient handles have
no implicit Double copy view. For every coefficient type,
`hmath_ad_value_import` converts a depth-zero component handle to a shared typed
Value; query/extract it with the shared Value API. Conversely, create a typed
shared coefficient Value, export it with `hmath_ad_value_export`, then pass
matching component handles to `hmath_ad_dual_nested`. Both conversions preserve
original scalar types and exact payloads.

A boxed `hmath.numeric_types.NumericValue` can select the complete original
coefficient type, including nested Numeric.Dual and Quaternion components.
`Dual.element_type` returns an independently owned scalar prototype; it retains
the entire coefficient witness. `dtype` reports primitive names or
`"numeric.dual"` / `"numeric.quaternion"` for those structured leaves. The
prototype, rather than that diagnostic string, selects a structured type.
Original Numeric.Dual has no Ord dictionary; Quaternion has Num but no
Fractional/Floating dictionary. The binding rejects those unavailable operations
without assigning new instances. AD.Dual may be nested over any supported leaf;
its Eq and available Ord continue to use the original instances. Bounded
arithmetic wraps according to the original Haskell type; constructor input
conversion rejects out-of-range Python integers.

`forward(function, value, dtype=None)` seeds a native dual with tangent one, applies the
builder using original Dual arithmetic, and returns `(primal, derivative)`.
C callers compose the same sequence using the dual constructor, native operators
and component extraction. Unchecked non-finite behavior is retained.

`forward_jvp(function, values, direction)` returns `(primals, tangents)` using the
original checked vector API. Input length and finite checks precede builder
execution. C callers can first invoke `hmath_ad_forward_jvp_result` with zero
outputs to perform those checks, then build their dual outputs with the input
values/direction, and invoke it again to extract checked output components.
The C result layout is `[primals..., tangents...]` with capacity `2*m`.

```python
from hmath import autodiff as ad

assert ad.forward(lambda x: x * x * x, 3) == (27, 27)
assert ad.forward(lambda x: x+1, 16777216, dtype="float32") == (16777216, 1)
assert ad.forward(lambda x: x*x, 10**100, dtype="integer") == (10**200, 2*10**100)
with ad.Dual(3, 1) as seed:
    value, derivative = ad.forward(lambda x: x*x*x, seed)
    with value, derivative:
        assert (derivative.primal, derivative.tangent) == (27, 18)
assert ad.forward_jvp(lambda xs: [xs[0] * xs[1]], [2, 3], [1, 2]) == ([6], [7])
```

See [forward mode](haskell/HMath-Autodiff.md#v:forward).

## Explicit gradient state

| Python | C | Meaning |
| --- | --- | --- |
| `GradientState(values)` | `hmath_ad_gradient_state_create` | Original raw constructor; stores the supplied list without extra validation. |
| `zero_gradients(count)` | `hmath_ad_zero_gradients` | Create zeros; negative count retains the original `InvalidArgument`. |
| `state.accumulated_gradient` | `hmath_ad_values_copy` | Copy the retained gradient list. |
| `accumulate_gradients(state, values)` | `hmath_ad_accumulate_gradients` | Return a new state with a checked, same-length finite sum. Original state is unchanged. |
| `reset_gradients(state)` | `hmath_ad_reset_gradients` | New zeros of the original length. |
| `gradient_hook(function, state)` | `hmath_ad_gradient_hook_result` | Apply a checked transformation; changed length and non-finite output are rejected. In C retrieve state values, apply the caller's hook, then pass the transformed values to the result adapter. |
| `clip_gradient(limit, values)` | `hmath_ad_clip_gradient` | Clip Euclidean norm without overflowing the norm calculation. C returns a gradient-list handle to copy/release. Positive finite limit is required. |

See [gradient accumulation](haskell/HMath-Autodiff.md#v:GradientState).

## Symbolic tensors

`ADTensor(shape, values)` / `ad_tensor(shape, values)` call the original checked
`adTensor`; values are expressions in logical row-major order. C uses
`hmath_ad_tensor_create`. Shape product must match expression count, with original
negative-dimension, broadcast and contraction failures preserved.

| Python | C | Meaning |
| --- | --- | --- |
| `ad_shape(tensor)` / `tensor.shape` | `hmath_ad_shape_copy` | Dimensions; Python returns a tuple, C uses `ptrdiff_t` array. |
| `ad_values(tensor)` / `tensor.values` | `hmath_ad_tensor_values` | Logical expression list. Every returned C expression reference is owned. |
| `ad_broadcast(shape, tensor)` | `hmath_ad_broadcast` | Original checked broadcasting; reverse contributions sum over repeats. |
| `ad_add(left, right)` / `left + right` | `hmath_ad_tensor_add` | Broadcasted symbolic addition. |
| `ad_multiply(left, right)` / `left * right` | `hmath_ad_tensor_multiply` | Broadcasted symbolic elementwise product. |
| `ad_matmul(left, right)` / `left @ right` | `hmath_ad_matmul` | Original symbolic batched matrix multiplication. |
| `ad_contract(left_axes, right_axes, left, right)` | `hmath_ad_contract` | Contraction preserving uncontracted axis order. |
| `ad_sum(tensor)` | `hmath_ad_sum` | Symbolic scalar sum. |

`hmath_ad_metadata` reports value count and rank before allocating getter buffers.
These tensors retain the original scalar-expression expansion; this binding does
not claim a new tensor-kernel AD engine or change the existing graph budget.
See [original tensor rules](haskell/HMath-Autodiff.md#t:ADTensor).

## Custom rules and checkpoints

`custom_operation(rule, expressions)` calls original `customOperation`. The rule
receives numerical values and returns `(value, partial_derivatives)`. The original
reverse evaluator checks derivative arity and finite values. Value-only compiled
graph evaluation retains its original behavior, including not validating unused
partial-derivative arity. Python materializes the returned derivative sequence
when invoking the foreign callback.

`custom_unary(function, derivative, expression)` calls original `customUnary`
with separate native callbacks. Evaluating only the graph value does not call the
derivative. Custom rules retain their first-order limitation: symbolic higher
orders return the original `InvalidArgument`.

`checkpoint(builder, expressions)` stores the original graph-building recipe.
The recipe is replayed by Haskell during evaluation/backpropagation. Its inputs
are local symbolic expressions, not concrete floating-point values. Builder
results may contain nested custom rules or checkpoints.

Python keeps callbacks and their referenced data alive transitively through
arithmetic, tensor, derivative and compiled-graph handles, including expressions
created by checkpoint replay. Python exceptions are caught at the callback
boundary and rethrown after native cleanup. An existing `HMathError` retains its
status and message. Callback-created expressions are retained conservatively
until all owning checkpoint/derived handles are released.

The additive C entries `hmath_ad_custom_operation_checked`,
`hmath_ad_custom_unary_checked` and `hmath_ad_checkpoint_checked` use the
`hmath_callback_error` wire from `hmath_callback.h`. This preserves all 21
original MathError constructors and complete message payloads, including NUL,
Unicode and long strings. Returning status11 from a custom rule supplies an
actual `Left MathError` to the original evaluator. Positioned expression errors
(status12) and interchange errors (status13) retain their structured fields.
Python selects these entries when available; raise `hmath.errors.MathError`,
`hmath.expression.ExprError` or an interchange error from a callback to preserve
that domain value. Unexpected Python exceptions rethrow after native cleanup.

C callback function pointers, userdata and error payload storage must remain
live until all derived handles are released. Callbacks are synchronous and may
reenter HMath; return an error status rather than throwing across C. Error
payload memory must remain valid until the invoking native call returns. The
legacy string-only callback entries remain ABI compatible; use the checked
entries for lossless structured failures. Every callback-created Expr returned
from checkpoint replay is independently retained for its derived graph's life.

C custom-rule callbacks receive writable partial capacity equal to argument
count and separately report actual partial count. Never write beyond capacity.
A checkpoint builder receives borrowed expression handles and returns one owned
expression reference; retain an input before returning that same input. The
header contains the complete callback signatures.

```python
from hmath import autodiff as ad

assert ad.value_and_gradient(
    lambda xs: ad.custom_unary(lambda x: x**3, lambda x: 3*x*x, xs[0]),
    [2],
) == (8, [12])
assert ad.value_and_gradient(
    lambda xs: ad.checkpoint(lambda ys: ys[0]*ys[0], xs),
    [2],
) == (4, [4])
```

See [custom rules](haskell/HMath-Autodiff.md#v:customOperation) and
[checkpoints](haskell/HMath-Autodiff.md#v:checkpoint).

## Shared object interchange

`hmath_ad_value_import` converts an owned legacy Expr/ADTensor/Dual handle into
an independently owned shared Value, and `hmath_ad_value_export` converts back.
No expression is reparsed or reconstructed mathematically. Python performs this
conversion automatically for neural and generic APIs, retaining callback owners
through the converted value and every derived result. Value287 is original Expr,
288 is original ADTensor and289 is original Autodiff.Dual. Numeric.Dual remains
a distinct original type; these owners are never silently exchanged.
