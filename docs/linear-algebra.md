# Dense linear algebra

`HMath` re-exports the vector, matrix, and error APIs. They can also be imported independently from `HMath.Linear`, `HMath.Matrix`, and `HMath.Error`.

## Shapes and storage

Matrices store an explicit `(rows, columns)` shape and a flat, row-major list. The constructor is private. `fromListChecked` requires exactly `rows * columns` values; `toList` returns them in the same order. Inputs to list-based APIs must be finite.

Negative dimensions and element counts larger than `maxBound :: Int` are rejected before allocation or element-count validation. This is a representability check, not a promise that every representable matrix fits in memory. Arithmetic follows the selected numeric type; for example, `Int` arithmetic can overflow and floating-point results can be non-finite.

Zero dimensions are supported. `0×0`, `m×0`, and `0×n` retain distinct shapes even though all have empty storage. Transpose swaps both dimensions, and transposing twice restores the original matrix. Multiplying `m×0` by `0×n` produces an `m×n` zero matrix, subject to the same output-size check.

```haskell
import HMath

emptyProduct :: Either MathError ((Int, Int), [Integer])
emptyProduct = do
    a <- fromListChecked 2 0 []
    b <- fromListChecked 0 3 []
    result <- multiplyChecked a b
    pure (shape result, toList result)
-- Right ((2,3),[0,0,0,0,0,0])
```

## Checked operations and compatibility

Fallible matrix operations have an `Either MathError` variant ending in `Checked`. Their `Maybe` variants return `Nothing` for the same invalid inputs. Existing signatures of `fromList`, `identity`, `addMatrix`, `multiply`, `transposeMatrix`, `shape`, and `toList` are preserved. The derived `Show` output reflects the flat internal storage and is not a serialization format.

| Operation | Result or requirement |
| --- | --- |
| `fromListChecked rows cols values` | Exact row-major element count |
| `zeroMatrixChecked rows cols` | All-zero matrix |
| `identityChecked n` | Square identity, including `n = 0` |
| `diagonalChecked values` | Square matrix with the supplied diagonal and zeros elsewhere |
| `atChecked matrix row col` | Element at a zero-based index |
| `sliceMatrixChecked start extent matrix` | Rectangular slice with `(row, col)` start and `(rows, cols)` extent |
| `reshapeChecked rows cols matrix` | New shape with unchanged row-major element order and count |
| `addMatrixChecked`, `subtractMatrixChecked`, `hadamardChecked` | Equal shapes; Hadamard multiplies corresponding elements |
| `multiplyChecked left right` | Left column count equals right row count; output shape is representable |
| `scaleMatrix scalar matrix` | Scalar multiplication preserving shape |
| `transposeMatrix matrix` | Shape-preserving transpose, including empty dimensions |

An index must be strictly inside both dimensions. A slice's start and extent must fit inside each dimension. Zero-extent slices may start at the corresponding dimension's endpoint. Bounds checks do not add potentially overflowing indices and extents.

```haskell
matrixExample :: Either MathError ([Int], [Int])
matrixExample = do
    matrix <- fromListChecked 2 3 [1, 2, 3, 4, 5, 6]
    section <- sliceMatrixChecked (0, 1) (2, 2) matrix
    reshaped <- reshapeChecked 3 2 matrix
    pure (toList section, toList reshaped)
-- Right ([2,3,5,6],[1,2,3,4,5,6])
```

Errors distinguish negative dimensions, size overflow, element-count mismatch, incompatible shapes or inner dimensions, invalid indices, invalid slices, and unequal vector lengths. `ElementCountMismatch` carries expected then actual counts; bounds errors carry the source shape and requested coordinates. See `HMath.Error` and Haddock for constructor details.

## List-based vectors

`dotChecked`, `addChecked`, and `subtractChecked` require equal list lengths and otherwise return `VectorLengthMismatch leftLength rightLength`. Empty lists are valid: their dot product is zero and their sum/difference is empty. The legacy `dot` and `add` preserve their exception behavior for unequal lengths.

`magnitude`, `normalize`, and `scale` retain their existing behavior. Normalization returns a vector unchanged when its computed magnitude is zero, including the empty vector. No finite-value or arithmetic-overflow policy is added to the underlying numeric type.

```haskell
dotChecked [1, 2, 3 :: Int] [4, 5, 6]  -- Right 32
addChecked [1 :: Int] [2, 3]           -- Left (VectorLengthMismatch 1 2)
subtractChecked [1, 2 :: Int] [3, 4]    -- Right [-2,-2]
```

## Validation

Run the complete checked-API example from the source tree with `runghc -isrc examples/haskell/Main.hs`.

`cabal test hmath-tests --test-show-details=direct` runs the Haskell suite. `meson test -C builddir --print-errorlogs` runs that suite together with the C/Python integration tests. A Haskell assertion failure makes the Meson test fail.

The suite checks boundary errors and a bounded family of small rectangular matrices, including empty shapes, against independent arithmetic and indexing expectations. It also checks transpose involution, identity products, additive identities, and distributivity using exact integer arithmetic. These are correctness checks, not performance benchmarks or broad floating-point accuracy guarantees.
