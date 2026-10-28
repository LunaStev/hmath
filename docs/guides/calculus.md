# Differentiate and integrate in Haskell

Use `HMath.Calculus` for checked finite differences and numerical quadrature
of `Double` callbacks. Callbacks must terminate and be side-effect free.
These operations are Haskell APIs; they are not Python tensor methods.

## Use an explicit step and panel count

Estimate the derivative of $x^2$ at 3 and its integral from 0 to 1:

```haskell
import qualified HMath.Calculus as Calculus

main :: IO ()
main = do
    let derivative = Calculus.derivative Calculus.Central 1e-5 (\x -> x*x) 3
        integral = Calculus.integrateComposite Calculus.Simpson 100 (\x -> x*x) 0 1
        expect expected result = case result of
            Left err -> fail (show err)
            Right actual ->
                if abs (actual - expected) <= 1e-8
                    then pure ()
                    else fail ("Unexpected estimate: " ++ show actual)
    expect 6 derivative
    expect (1/3) integral
    putStrLn "derivative and integral checks passed"
```

The expected output is `derivative and integral checks passed`.
The differentiation step must be positive, finite, and representable at
the evaluation point. Making it arbitrarily small can worsen cancellation.
Simpson's panel count must be positive and even; `ThreeEighths` requires a
multiple of three. A fixed-panel calculation does not return an error bound.

## Request adaptive refinement

```haskell
import qualified HMath.Calculus as Calculus

main :: IO ()
main = case Calculus.adaptiveIntegrate Calculus.defaultTolerance (\x -> x*x) 0 1 of
    Left err -> fail (show err)
    Right report -> do
        if abs (Calculus.estimateValue report - 1/3) <= 1e-9
            && Calculus.estimateError report >= 0
            && Calculus.evaluations report <= 100000
            then putStrLn "adaptive integration check passed"
            else fail (show report)
```

The default adaptive tolerance uses `1e-10` absolute, `1e-8` relative, and
100,000 evaluations. Its stopping target is
$\max(\mathrm{absoluteTolerance},\ \mathrm{relativeTolerance}\,|\mathrm{estimateValue}|)$.
Absolute tolerance must be positive; relative tolerance must be nonnegative;
both must be finite. A nonempty interval needs at least 15 evaluations.

If refinement cannot meet the target within the budget, the adaptive
integrator returns `Left (NonConvergence ...)`. Non-finite sampled values
also fail. `estimateError` is an estimate from the approximation rule,
not a rigorous bound for arbitrary callbacks. Inspect the full
[Calculus API](../reference/haskell.md) and
[numerical conventions](../explanation/numerical-conventions.md).
