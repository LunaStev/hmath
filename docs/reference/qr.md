# QR contracts (Haskell)

`HMath.Matrix.QR` provides column-pivoted Householder QR, full-column-rank
least-squares solves, and ridge regression. The interface is Haskell-only.
For a complete executable fitting example, see [least squares](../guides/least-squares.md).

## Shapes and factorization

For an $m\times n$ input matrix, `QR a` is opaque and contains factors
satisfying

$$
A[:,p]=Q R,\qquad Q\in\mathbb{R}^{m\times m},\quad
R\in\mathbb{R}^{m\times n}.
$$

`p` lists zero-based **original** column indices in pivoted order. `Q` is
square, not an economy-size factor. `R` is upper trapezoidal. The factorization
records deficient rank; the least-squares solve rejects it. Matrix construction
uses the separate checked [Matrix API](haskell.md).

## Factorization

### `qrDecompose`

```haskell
qrDecompose :: (RealFloat a) => Matrix a -> Either MathError (QR a)
```

Compute column-pivoted Householder QR with the default relative rank tolerance.

#### Parameters

| Argument | Type | Meaning |
| --- | --- | --- |
| `a` | `Matrix a` | Finite m-by-n matrix; rectangular and zero-sized shapes are allowed. |

#### Returns

`Right factors`, containing square `Q`, trapezoidal `R`, column permutation,
and numerical rank. The default tolerance is `max(m,n) * machineEpsilon`
for the input's `RealFloat` type. This estimates numerical rank rather than
requiring exact-zero pivots.

#### Errors

Non-finite matrix entries return `Left (NonFiniteMatrixEntry (row, column))`.
Non-finite intermediate data can return `Left (NonFiniteVectorEntry index)`;
that index may describe a flattened working array rather than the original input.
Checked matrix-allocation shape/size failures propagate. A deficient rank
alone does not fail this factorization.

#### See also

[`qrDecomposeWithTolerance`](#qrdecomposewithtolerance),
[`qrRank`](#factor-inspection), [`solveQR`](#solveqr),
[executable example](../guides/least-squares.md#fit-a-line).

### `qrDecomposeWithTolerance`

```haskell
qrDecomposeWithTolerance :: (RealFloat a) => a -> Matrix a -> Either MathError (QR a)
```

Select the relative pivot threshold explicitly.

#### Parameters

| Argument | Type | Meaning |
| --- | --- | --- |
| `tol` | `a` | Finite nonnegative relative rank tolerance. |
| `a` | `Matrix a` | Finite m-by-n matrix. |

#### Returns

The same factors as `qrDecompose`, with rank determined from diagonal pivots.
Let $s=\max_i |R_{ii}|$. A pivot counts when it is nonzero and either
`tol == 0` or $|R_{ii}|/s>\mathrm{tol}$. Zero tolerance counts every nonzero
pivot; it does not remove roundoff.

#### Errors

`Left InvalidTolerance` for a negative, NaN, or infinite tolerance, plus the
finite-input/result and checked matrix errors of `qrDecompose`.

#### See also

[`qrDecompose`](#qrdecompose),
[rank and conditioning](../explanation/numerical-conventions.md#residual-conditioning-and-rank).

## Factor inspection

These accessors take one `QR a`, allocate no new factorization, and return
the stored component directly. Their signatures have no checked error result.

| Signature | Returns |
| --- | --- |
| `qrQ :: QR a -> Matrix a` | Square m-by-m orthogonal factor. |
| `qrR :: QR a -> Matrix a` | Upper-trapezoidal m-by-n factor in pivoted column order. |
| `qrPermutation :: QR a -> [Int]` | n original column indices in pivoted order. |
| `qrRank :: QR a -> Int` | Numerical rank selected by the relative tolerance. |

## Apply an orthogonal factor

| Signature | Parameters | Returns / errors |
| --- | --- | --- |
| `applyQ :: (Num a) => QR a -> Matrix a -> Either MathError (Matrix a)` | Factors, then m-by-k matrix. | `Right (Q * matrix)`, shape m-by-k; checked dimension/size failures propagate. |
| `applyQT :: (Num a) => QR a -> Matrix a -> Either MathError (Matrix a)` | Factors, then m-by-k matrix. | `Right (transpose Q * matrix)`, shape m-by-k; checked dimension/size failures propagate. |

These operations have a generic `Num` constraint. They do not add a
universal finite-result guarantee to the selected numeric type.

## Least-squares solves

### `solveQR`

```haskell
solveQR :: (RealFloat a) => QR a -> [a] -> Either MathError [a]
```

Solve $\min_x\|Ax-b\|_2^2$ using an existing factorization.

#### Parameters

| Argument | Type | Meaning |
| --- | --- | --- |
| `f` | `QR a` | Factors of an m-by-n matrix, with m ≥ n and numerical rank n. |
| `b` | `[a]` | Exactly m finite right-hand-side values. |

#### Returns

`Right x` with n coefficients in the original, unpermuted column order.
The result for n = 0 is an empty list when the RHS shape is compatible.

#### Errors

- `InvalidArgument` for an underdetermined system.
- `RightHandSideMismatch expected actual` for the wrong RHS length.
- `RankDeficient rank` if the factorization has fewer than n independent columns.
- Non-finite matrix/vector/result and checked matrix errors propagate.

#### See also

[`leastSquares`](#leastsquares), [`solveMatrixQR`](#multiple-right-hand-sides),
[factor once for several solves](../guides/least-squares.md#choose-factorization-or-direct-solve).

### `leastSquares`

```haskell
leastSquares :: (RealFloat a) => Matrix a -> [a] -> Either MathError [a]
```

Factor and solve in one operation.

#### Parameters

| Argument | Type | Meaning |
| --- | --- | --- |
| `a` | `Matrix a` | Finite m-by-n design, with m ≥ n and full numerical column rank. |
| `b` | `[a]` | m finite observations. |

#### Returns

The n coefficients from `qrDecompose a` followed by `solveQR factors b`.
An intercept column must be supplied explicitly; none is inserted automatically.

#### Errors

The union of factorization and `solveQR` failures. There is no minimum-norm
fallback for underdetermined or deficient-rank input.

#### See also

[`solveQR`](#solveqr), [`ridgeSolve`](#ridgesolve),
[fit a line](../guides/least-squares.md#fit-a-line).

### Multiple right-hand sides

| Signature | Parameters | Returns / errors |
| --- | --- | --- |
| `leastSquaresMatrix :: (RealFloat a) => Matrix a -> Matrix a -> Either MathError (Matrix a)` | m-by-n design, then m-by-k RHS matrix. | n-by-k coefficients; factorization and solve errors propagate. |
| `solveMatrixQR :: (RealFloat a) => QR a -> Matrix a -> Either MathError (Matrix a)` | Full-column-rank factors, then finite m-by-k RHS. | n-by-k coefficients in original column order; same m ≥ n, rank, shape and numerical checks as `solveQR`. |

Compatible zero-column RHS matrices return n-by-0 results. Rank and dimension
checks still apply before the empty result is produced.

## Ridge regression

### `ridgeSolve`

```haskell
ridgeSolve :: (RealFloat a) => a -> Matrix a -> [a] -> Either MathError [a]
```

Minimize a squared residual plus a squared-coefficient penalty:

$$
\min_x\left(\|Ax-b\|_2^2+\lambda\|x\|_2^2\right).
$$

#### Parameters

| Argument | Type | Meaning |
| --- | --- | --- |
| `lambda` | `a` | Finite nonnegative penalty coefficient. |
| `a` | `Matrix a` | Finite m-by-n design. |
| `b` | `[a]` | m finite RHS values. |

#### Returns

n coefficients in original column order. For positive lambda, the solver
uses augmented QR with design `[A; sqrt(lambda)*I]` and RHS `[b; 0]`.
Every supplied coefficient, including an intercept column, is penalized.
Zero lambda delegates to ordinary least squares and retains its requirements.

#### Errors

`DomainError` for negative/non-finite lambda, plus RHS, augmented-shape,
rank, and numerical errors from the checked construction/factorization/solve.
Positive lambda does not establish an unconditional finite-precision success guarantee.

#### See also

[`leastSquares`](#leastsquares), [`ridgeSolveMatrix`](#ridgesolvematrix),
[least-squares guide](../guides/least-squares.md).

### `ridgeSolveMatrix`

```haskell
ridgeSolveMatrix :: (RealFloat a) => a -> Matrix a -> Matrix a -> Either MathError (Matrix a)
```

#### Parameters

| Argument | Type | Meaning |
| --- | --- | --- |
| `lambda` | `a` | Finite nonnegative coefficient applied to every RHS column. |
| `a` | `Matrix a` | Finite m-by-n design. |
| `b` | `Matrix a` | Finite m-by-k RHS matrix. |

#### Returns

An n-by-k coefficient matrix, using the same augmented QR and column ordering
as `ridgeSolve`.

#### Errors

The same validation and numerical failures as `ridgeSolve`, with a matrix
RHS row-count check. Zero lambda delegates to `leastSquaresMatrix`.

#### See also

[`ridgeSolve`](#ridgesolve), [`leastSquaresMatrix`](#multiple-right-hand-sides).

## Numerical notes and references

Column pivoting supports rank estimation but does not replace a condition
number analysis. The reported rank and residual depend on floating-point
scale and the selected tolerance. The implementation uses Householder
reflections; it does not form $A^T A$ for these solves.

- [Full module declarations](haskell.md): all public Haskell modules and generated signatures.
- [Numerical conventions](../explanation/numerical-conventions.md): residuals and accuracy.
- [GSL QR documentation](https://www.gnu.org/software/gsl/doc/html/linalg.html#qr-decomposition): mathematical background; GSL-specific storage and API rules do not define HMath's interface.
