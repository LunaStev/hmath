# Structured values and ownership

`hmath_value.h` represents exact scalars, lists, tuples and original Haskell
objects used by the structured C APIs. Each domain header declares named
operations with the original argument order. The mathematical implementation
remains in Haskell.

## Lifetime

Every successful output owns one reference. Release it with
`hmath_value_release`; retain an additional reference with `hmath_value_retain`.
Releasing a null pointer is allowed. Inputs are borrowed for the duration of a
synchronous call. A returned object or container holds its Haskell values
independently of the input handles, so input handles can then be released.

Each live handle keeps the runtime active. Release all handles before the final
`hmath_shutdown`. Immutable values may be shared between concurrent calls when
each caller keeps a reference alive. Output locations must be independent;
releasing the final reference concurrently with a call using that handle is
invalid. Context cancellation and limits follow the individual domain contract.

Python domain objects provide `close()` and context managers. Ordinary scalar,
list and tuple results are converted to Python values. Objects returned inside
containers retain independent native references.

## Value kinds

`hmath_value_info(value, &kind, &dtype, &count)` queries metadata without
changing the last-error state. All three output pointers are required. A dtype
of `-1` means the object has no scalar coefficient type. `count` is logical
length; interpretation for an opaque object is specified by its domain.

| Kind | Representation |
| --- | --- |
| 0 | `Nothing`, represented by Python `None` |
| 1 | Typed scalar coefficient |
| 2 | Haskell `Int`, represented with `ptrdiff_t` |
| 3 | Boolean |
| 4 | List |
| 5 | Tuple, including `()` |
| 6–8 | Polynomial, power series, rational function |
| 9 | Dense matrix |
| 10 | Haskell `String` |
| Other | Opaque object declared by its domain header |

`Maybe a` uses kind 0 for `Nothing` and the value's own representation for
`Just`. Tuple/list shape remains significant: an empty list, unit tuple and
`Nothing` are distinct values. Consult the specific function's contract where
an interface uses unit only to signal success.

## Construct scalars

Every constructor takes `hmath_context *context` first and
`hmath_value **out` last. A null context selects the default execution context.
On failure, the output pointer is unchanged.

| Constructor | Input and coefficient type |
| --- | --- |
| `hmath_value_f32` | `float`, binary32 |
| `hmath_value_f64` | `double`, binary64 |
| `hmath_value_complex_f32` | Real and imaginary `float`, `Complex Float` |
| `hmath_value_complex_f64` | Real and imaginary `double`, `Complex Double` |
| `hmath_value_integer` | Signed decimal ASCII, arbitrary-precision `Integer` |
| `hmath_value_integral` | Integral dtype plus signed decimal ASCII; rejects values outside that type |
| `hmath_value_rational` | Decimal numerator and nonzero denominator; exact normalized `Rational` |
| `hmath_value_index` | `ptrdiff_t`, Haskell `Int` |
| `hmath_value_boolean` | C integer, zero false and nonzero true |
| `hmath_value_none` | No payload, `Nothing` |

Coefficient enums distinguish binary32/binary64, complex64/complex128,
arbitrary `Integer`, exact `Rational`, signed and unsigned 8/16/32/64-bit
integers and native-width `Int`/`Word`. A domain operation determines which
original Haskell instances it supports. It rejects mismatched types rather
than silently choosing a different mathematical domain.

Binary constructors preserve the selected floating representation, including
signed zero and NaN/Inf. The called mathematical function applies its original
finite-input policy. Exact constructors never convert through floating point.

## Construct and inspect containers

`hmath_value_list` and `hmath_value_tuple` take an array of borrowed
`const hmath_value *` items and a `size_t` count. The resulting container owns
the contained Haskell values independently of those item handles. A null array
is permitted only when count is zero.

`hmath_value_item(context, sequence, index, out)` accepts a list or tuple and
returns an independently owned item. Indices are zero-based Haskell `Int`
values; out-of-range indices fail.

```c
#include <hmath_value.h>

/* After hmath_init has succeeded: build an exact pair (1/3, 2/7). */
hmath_value *a = NULL, *b = NULL, *pair = NULL;
hmath_status status = hmath_value_rational(NULL, "1", "3", &a);
if (status == HMATH_OK)
    status = hmath_value_rational(NULL, "2", "7", &b);
if (status == HMATH_OK) {
    const hmath_value *items[] = {a, b};
    status = hmath_value_tuple(NULL, items, 2, &pair);
}
hmath_value_release(a);
hmath_value_release(b);
/* pair remains valid here if status == HMATH_OK. */
hmath_value_release(pair);
```

## Read scalars and strings

All getters borrow their input. Required output addresses must be nonnull.
They reject an incompatible kind or dtype and preserve outputs on failure.

| Getter | Result |
| --- | --- |
| `hmath_value_get_f32` | Real and imaginary `float`; accepts binary32 or complex64 |
| `hmath_value_get_f64` | Real and imaginary `double`; accepts binary64 or complex128 |
| `hmath_value_get_exact` | Two owned decimal strings, numerator and denominator; integers use denominator `1` |
| `hmath_value_get_index` | `ptrdiff_t` from kind 2 |
| `hmath_value_get_boolean` | C integer Boolean from kind 3 |
| `hmath_value_get_text` | Unicode codepoints from kind 10 into a caller-owned buffer |

Both floating outputs are required; real inputs produce imaginary zero. Free
each string from `hmath_value_get_exact` with `hmath_value_string_free`, which
also accepts null. These strings use their own allocation and remain valid
after the input handle is released.

`hmath_value_text` takes `uint32_t` Unicode codepoints and their explicit count.
This preserves every Haskell `Char`, including embedded NUL and surrogate
codepoints, without normalization. For `hmath_value_get_text`, obtain the count
with `hmath_value_info`, then provide that many elements. An undersized buffer
fails without changing its contents. String length counts codepoints, not
UTF-8 bytes.

## Errors

Each operation returns `hmath_status`. Representation errors, allocation
failure, cancellation and runtime lifecycle errors use the C ABI status codes.
A checked Haskell `Left MathError` returns `HMATH_MATH_ERROR` (11), with its
original constructor and payload available through `hmath_last_math_error` in
`hmath_error.h`. Read the payload before another operation changes the thread's
last error.

Python raises `HMathError`; its `math_error` field contains the structured
Haskell error when status is 11. Unexpected Python exceptions in callbacks are
retained and re-raised after native cleanup. Domain documentation specifies
whether a callback may return a recoverable mathematical error and whether an
operation can retain that callback.
