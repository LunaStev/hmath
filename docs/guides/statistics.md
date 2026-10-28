# Summarize data in Haskell

Use `HMath.Statistics` for basic descriptive statistics over finite,
nonempty lists. These legacy pure functions return a number directly and
raise a pure error on an empty list. Validate that precondition before calling.
The Python binding currently exposes tensor reductions rather than these APIs.

## Compute a population summary

```haskell
import qualified HMath.Statistics as Statistics

main :: IO ()
main = do
    let samples = [1, 3 :: Double]
    if null samples then fail "A summary needs at least one observation" else pure ()
    if Statistics.mean samples == 2
        && Statistics.variance samples == 1
        && Statistics.standardDeviation samples == 1
        && Statistics.median samples == 2
        then putStrLn "mean=2, population variance=1, median=2"
        else fail "Unexpected summary"
```

The expected output is `mean=2, population variance=1, median=2`.
These particular results are exactly representable; general floating-point
data needs approximate comparison.

## Interpret the denominator

`variance` computes population variance:

$$
\mu=\frac{1}{n}\sum_{i=1}^{n}x_i,\qquad
\mathrm{variance}(x)=\frac{1}{n}\sum_{i=1}^{n}(x_i-\mu)^2.
$$

It divides by $n$, not $n-1$. Do not label this result an unbiased sample
variance. `standardDeviation` is the square root of that population variance.
For even-length input, `median` averages the two central sorted values.

These generic functions do not provide a universal overflow or numerical
stability guarantee. Use the [Statistics API](../reference/haskell.md) for
signatures and [numerical conventions](../explanation/numerical-conventions.md)
for interpreting finite arithmetic and error behavior.
