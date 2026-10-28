# Solve least-squares problems in Haskell

Use `HMath.Matrix.QR.leastSquares` to fit coefficients when there are at
least as many observations as coefficients and the design matrix has full
column rank. This guide requires the Haskell source environment described
in [building from source](build.md); the Python wrapper does not expose QR.

## Fit a line

Fit $y = c_0 + c_1 t$ to the observations $(0,1)$, $(1,3)$, $(2,5)$.
Each row of the design matrix is `[1, t]`. Solve

$$
\min_c \|A c-y\|_2^2,\qquad
A=\begin{bmatrix}1&0\\1&1\\1&2\end{bmatrix},\quad
y=\begin{bmatrix}1\\3\\5\end{bmatrix}.
$$

```haskell
import qualified HMath.Matrix as Matrix
import qualified HMath.Matrix.QR as QR

main :: IO ()
main = case Matrix.fromListChecked 3 2 [1, 0, 1, 1, 1, 2 :: Double]
            >>= (\a -> QR.leastSquares a [1, 3, 5]) of
    Left err -> fail (show err)
    Right coefficients -> do
        let close a b = abs (a - b) <= 1e-10
        if length coefficients == 2 && and (zipWith close coefficients [1, 2])
            then putStrLn "intercept=1, slope=2"
            else fail ("Unexpected coefficients: " ++ show coefficients)
```

The expected output is `intercept=1, slope=2`. The assertion compares with
a tolerance because QR uses floating-point arithmetic.

## Choose factorization or direct solve

| Need | Operation |
| --- | --- |
| One right-hand side | `leastSquares a b` |
| Several RHS columns | `leastSquaresMatrix a b` |
| Reuse one factorization | `qrDecompose a`, then `solveQR` or `solveMatrixQR` |
| Inspect column rank | `qrRank factors` and `qrPermutation factors` |
| Add a squared-coefficient penalty | `ridgeSolve lambda a b` |

QR uses column pivoting, so the factorization describes reordered columns.
The solve functions return coefficients in the **original** column order.
HMath uses augmented QR for ridge regression and does not form normal
equations. The intercept is penalized too if it is a column of the supplied
design matrix; no column receives an automatic exemption.

## Handle failure

Underdetermined systems and rank-deficient design matrices are rejected by
the QR least-squares solve. Wrong RHS length, invalid tolerance, non-finite
data, and non-finite arithmetic also have checked failures. Inspect `Left`
instead of substituting a zero coefficient vector.

For the exact signatures, defaults, matrix shapes, rank threshold, and error
constructors, see [QR contracts](../reference/qr.md). A small residual alone
does not establish a small coefficient error; see
[conditioning](../explanation/numerical-conventions.md#residual-conditioning-and-rank).
