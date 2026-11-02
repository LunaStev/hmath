# Random streams, distributions and statistics

Every function calls the original Haskell implementation. RNG owners retain the complete immutable algorithm state, including buffered outputs. Seeds and generated words use exact Word64 transport. All seven generators, continuation/clone/split/serialization behavior, original distributions, model validation, sample ordering, diagnostics, resource budgets and error recovery are preserved. Values are owned and support `close()`/context management; results survive closing inputs. Generic sample elements preserve arbitrary typed Values rather than coercing through a numeric dtype.

Callbacks use the original argument order. Raising a `MathError` from a checked callback becomes the original source `Left`; the algorithm retains its original recovery behavior. Unexpected Python exceptions rethrow after native cleanup. Pure callbacks abort on failure. Keep C callbacks/userdata alive as long as any owner/derived closure can invoke them. No package import initializes global RNG state or consumes entropy.

## `random.clone_rng`

Copy an immutable state; the copy produces exactly the same future outputs.

Original signature: `RNG -> RNG`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.seed_rng`

Deterministically encode a 64-bit seed. Shift engines use SplitMix64 expansion; MT uses the low 32 bits and its standard initialization recurrence. PCG uses a fixed odd stream increment and an offset initial state. Counter engines use the seed as key; ChaCha expands it into a 256-bit simulation key.

Original signature: `Generator -> Word64 -> RNG`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.next_word64`

Produce one word and its successor state. Fixed-width arithmetic wraps modulo 2^32 or 2^64 as required by the algorithm.

Original signature: `RNG -> (Word64, RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.split_rng`

Create two deterministic child streams by hashing two successive parent words. The original immutable parent is unchanged; see the module-level non-overlap caveat.

Original signature: `RNG -> (RNG, RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.serialize_rng`

Serialize full state, including pending block output, with the versioned hmath-rng-1 prefix.

Original signature: `RNG -> String`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.restore_rng`

Parse a versioned full state and validate generator lengths, forbidden zero states, and MT word/index ranges.

Original signature: `String -> Either MathError RNG`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.uniform`

Uniform 53-bit real on [0,1), using the most significant random bits.

Original signature: `RNG -> (Double, RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.uniform_open`

Uniform 52-bit midpoint real on (0,1), safe as input to logarithms.

Original signature: `RNG -> (Double, RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.uniform_int`

Unbiased inclusive integer range using 64-bit rejection. Supports the complete machine Int range; rejects reversed bounds.

Original signature: `Int -> Int -> RNG -> Either MathError (Int, RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.sample_n`

Run a checked sampler sequentially, returning values and final state. Count must lie in [0,10000000].

Original signature: `Int -> (RNG -> Either MathError (a, RNG)) -> RNG -> Either MathError ([a], RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.box_muller`

Standard normal through the polar-coordinate Box--Muller transform, consuming two uniforms.

Original signature: `RNG -> (Double, RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.marsaglia_normal`

Standard normal through Marsaglia polar disk rejection, with 10000-proposal budget.

Original signature: `RNG -> Either MathError (Double, RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.ziggurat_normal`

Marsaglia--Tsang 128-layer Ziggurat normal generator. Horizontal rectangles have equal area; the base includes an exponentially proposed tail. Published normal cutoff/area constants: https://doi.org/10.18637/jss.v005.i08 Tables are generated by the area recurrence, not embedded implementation data.

Original signature: `RNG -> Either MathError (Double, RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.normal`

Normal sample with finite mean and strictly positive standard deviation. Arithmetic overflow returns NonFiniteResult.

Original signature: `Double -> Double -> RNG -> Either MathError (Double, RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.exponential`

Exponential sample parameterized by strictly positive rate, via an open-uniform logarithm.

Original signature: `Double -> RNG -> Either MathError (Double, RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.gamma`

Gamma shape/scale sample using Marsaglia--Tsang rejection and the shape-augmentation identity below shape one; 10000-proposal budget.

Original signature: `Double -> Double -> RNG -> Either MathError (Double, RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.beta`

Beta(a,b) as the ratio of independent gamma variates. Positive parameters required; unresolved underflow returns an error.

Original signature: `Double -> Double -> RNG -> Either MathError (Double, RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.poisson`

Poisson count by exponential-arrival inversion. Rate is in [0,100000], work is capped at one million arrivals.

Original signature: `Double -> RNG -> Either MathError (Int, RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.binomial`

Binomial count from n independent Bernoulli trials. n<=10000000 and p in [0,1].

Original signature: `Int -> Double -> RNG -> Either MathError (Int, RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.weighted`

Draw an index in proportion to finite nonnegative weights; max scaling handles subnormal or overflowing totals and zero weights are never selected.

Original signature: `[Double] -> RNG -> Either MathError (Int, RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.alias_table`

Build a Walker alias table from finite nonnegative weights with positive maximum; max scaling avoids overflow.

Original signature: `[Double] -> Either MathError AliasTable`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.alias_sample`

Draw an index from an already validated alias table, using one uniform integer and one uniform real.

Original signature: `AliasTable -> RNG -> Either MathError (Int, RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.shuffle`

Fisher--Yates permutation of list positions. This immutable list reference implementation costs quadratic time.

Original signature: `[a] -> RNG -> Either MathError ([a], RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.with_replacement`

Draw count values independently from a nonempty finite population, preserving duplicates.

Original signature: `Int -> [a] -> RNG -> Either MathError ([a], RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.without_replacement`

Uniform subset in shuffled order. Count cannot exceed population length; uniqueness is by position.

Original signature: `Int -> [a] -> RNG -> Either MathError ([a], RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.reservoir`

Algorithm R reservoir over a finite stream, retaining k positions uniformly without replacement.

Original signature: `Int -> [a] -> RNG -> Either MathError ([a], RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.stratified`

One uniform point per equal-width interval of [0,1), in increasing stratum order.

Original signature: `Int -> RNG -> Either MathError ([Double], RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.rejection`

Accept proposals with the supplied target/envelope probability in [0,1]; the first argument is a hard proposal budget.

Original signature: `Int -> (Double -> Double) -> (RNG -> Either MathError (Double, RNG)) -> RNG -> Either MathError (Double, RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.inverse_transform`

Apply a checked inverse CDF to an open uniform; propagates inverse-domain or nonconvergence errors.

Original signature: `(Double -> Either MathError Double) -> RNG -> Either MathError (Double, RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.metropolis_hastings`

Symmetric random-walk Metropolis in log density. Returned chain includes each post-proposal state. Non-finite log densities are rejected.

Original signature: `Int -> Double -> (Double -> Double) -> Double -> RNG -> Either MathError ([Double], RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.gibbs`

A full Gibbs sweep uses caller-supplied exact conditional samplers in coordinate order. Shape is checked after each conditional.

Original signature: `Int -> [([Double] -> RNG -> Either MathError (Double, RNG))] -> [Double] -> RNG -> Either MathError ([[Double]], RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.hamiltonian_monte_carlo`

Identity-mass HMC with Gaussian momentum, leapfrog count and positive step size, log density and its gradient. Returns post-Metropolis states; finite-gradient shapes are checked.

Original signature: `Int -> Int -> Double -> ([Double] -> Double) -> ([Double] -> [Double]) -> [Double] -> RNG -> Either MathError ([[Double]], RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.monte_carlo`

Uniform-[0,1] Monte Carlo integral and estimated standard error from at least two draws. This is a stochastic estimate, not a certified bound.

Original signature: `(Double -> Double) -> Int -> RNG -> Either MathError ((Double, Double), RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.latin_hypercube`

Random n-by-d Latin hypercube in [0,1), with a separate Fisher--Yates stratum permutation per axis; n>0 and 1<=d<=1024.

Original signature: `Int -> Int -> RNG -> Either MathError ([[Double]], RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.random_quality`

Mean, population variance, and lag-one correlation; descriptive quality diagnostics, not a cryptographic certification or a replacement for TestU01.

Original signature: `Int -> RNG -> Either MathError ((Double, Double, Double), RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.entropy_seed`

Read eight bytes from the operating system entropy device, little endian. IO exceptions are propagated; this deliberately has no time-based fallback.

Original signature: `IO Word64`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.pcg32`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.xoshiro256_star_star`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.xoroshiro128_plus`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.mt19937`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.philox4x32`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.threefry2x64`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `random.cha_cha20`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.validate_distribution`

Check finite parameters, support ordering, probability normalization, and declared per-family reference budgets.

Original signature: `Distribution -> Either MathError ()`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.log_density`

Log density or mass; zero probability is negative infinity, while an integrable endpoint singularity is positive infinity. Observations must be finite.

Original signature: `Distribution -> Double -> Either MathError Double`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.density`

Probability mass for discrete families or density for continuous families. At integrable density singularities the result can be positive infinity; outside support it is zero.

Original signature: `Distribution -> Double -> Either MathError Double`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.cdf`

P(X\<=x). Gamma/beta and classical transformed families use analytic special-function identities. Remaining finite-support continuous cases use 2048-panel Simpson integration; Skellam drops a tail beyond 14 standard deviations plus 20 counts.

Original signature: `Distribution -> Double -> Either MathError Double`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.survival`

P(X>x), using direct upper tails for normal, gamma, beta, t, F, binomial and Poisson to avoid cancellation. Other families use the CDF complement.

Original signature: `Distribution -> Double -> Either MathError Double`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.quantile`

Generalized inverse CDF, p in [0,1]; endpoints return mathematical support bounds, including infinities. Interior values use analytic transforms or bounded bracketing/bisection.

Original signature: `Distribution -> Double -> Either MathError Double`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.hazard`

Density divided by survival. For zero survival returns positive infinity by convention.

Original signature: `Distribution -> Double -> Either MathError Double`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.log_likelihood`

Sum of independent observation log probabilities. Impossible data produce negative infinity.

Original signature: `Distribution -> [Double] -> Either MathError Double`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.moments`

Mean and population variance. Infinite/nonexistent moments return a domain error rather than a numeric value that could be mistaken for a finite moment.

Original signature: `Distribution -> Either MathError (Double, Double)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.entropy`

Shannon or differential entropy in nats. Closed forms are used when available; other families use the documented expectation quadrature.

Original signature: `Distribution -> Either MathError Double`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.expectation`

Reference expectation under a distribution. Empirical/mixture cases are exact weighted sums; count families truncate at 1e-10 tail quantiles, continuous families use 4096 midpoint probability-space nodes. No certified quadrature error is claimed.

Original signature: `Distribution -> (Double -> Double) -> Either MathError Double`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.sample`

Draw a model sample and updated immutable RNG; specialized gamma/normal/count samplers are reused, with inverse-CDF sampling for remaining families.

Original signature: `Distribution -> R.RNG -> Either MathError (Double, R.RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.fit_normal`

Normal maximum-likelihood fit; variance divides by n. Constant data are rejected because this continuous family requires positive standard deviation.

Original signature: `[Double] -> Either MathError Distribution`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.fit_exponential`

Maximum-likelihood rate for nonnegative observations with strictly positive total.

Original signature: `[Double] -> Either MathError Distribution`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.fit_bernoulli`

Maximum-likelihood probability for nonempty binary observations.

Original signature: `[Double] -> Either MathError Distribution`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.fit_mle_grid`

Select the maximum-likelihood model from an explicit finite candidate grid; this is grid search, not continuous parameter optimization.

Original signature: `[Distribution] -> [Double] -> Either MathError Distribution`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.fit_map_grid`

Select the maximum log-likelihood plus caller-supplied log prior over a finite model grid. Log priors must be finite.

Original signature: `[Distribution] -> [Double] -> (Distribution -> Double) -> Either MathError Distribution`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.beta_bernoulli_update`

Conjugate Beta prior update from success/failure observations, returning posterior concentrations (alpha,beta).

Original signature: `Double -> Double -> [Bool] -> Either MathError (Double, Double)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.goodness_of_fit`

Two-sided one-sample Kolmogorov distance against a specified CDF. Returns the distance only; no discrete-null p-value is implied.

Original signature: `Distribution -> [Double] -> Either MathError Double`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.gaussian_kde`

Construct an equal-weight Gaussian kernel density with strictly positive bandwidth and finite nonempty observations.

Original signature: `Double -> [Double] -> Either MathError Distribution`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.multivariate_normal_log_density`

Log density for a finite mean/point and symmetric positive-definite covariance, validated by Cholesky.

Original signature: `[Double] -> Matrix Double -> [Double] -> Either MathError Double`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.sample_multivariate_normal`

Cholesky-transform independent standard normals; returns a vector and updated state.

Original signature: `[Double] -> Matrix Double -> R.RNG -> Either MathError ([Double], R.RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.wishart_log_density`

Wishart log density for real degrees of freedom nu>p-1 and positive-definite p-by-p scale and observation matrices.

Original signature: `Double -> Matrix Double -> Matrix Double -> Either MathError Double`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.sample_wishart`

Reference Wishart draw as the sum of nu Gaussian outer products; requires integer nu>=p and nu\<=100000.

Original signature: `Int -> Matrix Double -> R.RNG -> Either MathError (Matrix Double, R.RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.markov`

Validate and construct a row-stochastic matrix with 1..1024 states; row sums tolerate absolute error 1e-12.

Original signature: `[[Double]] -> Either MathError Markov`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.transition`

Advance a normalized state-probability row vector by one Markov step.

Original signature: `Markov -> [Double] -> Either MathError [Double]`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.stationary`

Stationary probabilities by damped power iteration, with caller iteration budget and positive residual tolerance. Reducible chains can have multiple stationary laws.

Original signature: `Int -> Double -> Markov -> Either MathError [Double]`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.hmm`

Validate initial probabilities, square transition matrix and equally sized categorical-emission rows.

Original signature: `[Double] -> [[Double]] -> [[Double]] -> Either MathError HMM`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.forward`

Scaled forward returns log likelihood, normalized alpha rows and per-time scaling constants. This avoids the product underflow of raw probability DP.

Original signature: `HMM -> [Int] -> Either MathError (Double, [[Double]], [Double])`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.backward`

Scaled backward messages using the same per-time normalizers as forward; terminal message is the all-ones vector.

Original signature: `HMM -> [Int] -> Either MathError [[Double]]`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.posterior_states`

Posterior state probabilities at each observation time from normalized alpha-beta products.

Original signature: `HMM -> [Int] -> Either MathError [[Double]]`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.viterbi`

Most likely state path and its joint log probability, via max-product dynamic programming in log space.

Original signature: `HMM -> [Int] -> Either MathError ([Int], Double)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.baum_welch`

Baum--Welch EM for one observation sequence, pseudocount>=0. Transition rows with zero expected occupancy retain their old row. Fixed iteration budget.

Original signature: `Int -> Double -> HMM -> [Int] -> Either MathError HMM`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.bernoulli`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.binomial`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.negative_binomial`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.geometric`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.hypergeometric`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.poisson`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.categorical`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.discrete_uniform`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.uniform`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.normal`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.log_normal`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.exponential`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.gamma`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.beta`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.chi_square`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.student_t`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.fisher_f`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.cauchy`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.laplace`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.logistic`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.weibull`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.pareto`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.rayleigh`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.maxwell`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.gumbel`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.generalized_extreme_value`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.beta_binomial`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.skellam`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.von_mises`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.triangular`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.truncated_normal`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.mixture`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.empirical`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `probability.new_gaussian_kde`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.covariance_matrix`

Covariance matrix for variables supplied as columns (each list is one variable). Boolean selects sample correction.

Original signature: `Bool -> [[Double]] -> Either MathError [[Double]]`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.partial_correlation`

Partial correlation of variable indices i,j conditional on every other supplied column, through the inverse sample covariance.

Original signature: `[[Double]] -> Int -> Int -> Either MathError Double`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.empty_streaming`

Zero-count Welford accumulator.

Original signature: `Streaming`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.update_streaming`

Add one finite observation by Welford recurrence; nonfinite arithmetic is rejected.

Original signature: `Streaming -> Double -> Either MathError Streaming`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.combine_streaming`

Chan parallel merge of two Welford accumulators; empty accumulators are identities.

Original signature: `Streaming -> Streaming -> Either MathError Streaming`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.streaming_result`

Return count, mean and variance; True uses n-1 correction and requires at least two samples.

Original signature: `Bool -> Streaming -> Either MathError (Integer, Double, Double)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.histogram_nd`

Histogram edges must increase strictly; intervals are [a,b), with the last interval closed on its right. Points outside any axis are excluded. Flattening is row-major, the last axis varies fastest. Weights need not sum to one.

Original signature: `[[Double]] -> [[Double]] -> [Double] -> Either MathError [Double]`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.mutual_information`

Mutual information in nats from a rectangular normalized joint-probability table.

Original signature: `[[Double]] -> Either MathError Double`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.bootstrap`

Seeded nonparametric resampling with replacement. Returns caller statistic for each replicate and final RNG state.

Original signature: `Int -> ([Double] -> Either MathError Double) -> [Double] -> R.RNG -> Either MathError ([Double], R.RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.jackknife`

Leave-one-out bias-corrected statistic and jackknife standard error; requires n>=2.

Original signature: `([Double] -> Either MathError Double) -> [Double] -> Either MathError (Double, Double)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.one_sample_t`

Two-sided one-sample Student t test against a finite null mean; assumes independent normal observations.

Original signature: `Double -> [Double] -> Either MathError TestResult`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.two_sample_t`

Two-sided pooled t test when True, Welch unequal-variance test when False; each group requires n>=2 and positive combined variation.

Original signature: `Bool -> [Double] -> [Double] -> Either MathError TestResult`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.paired_t`

Two-sided one-sample t test on paired differences; matching group lengths required.

Original signature: `[Double] -> [Double] -> Either MathError TestResult`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.z_test`

Two-sided one-sample normal z test with known strictly positive population standard deviation.

Original signature: `Double -> Double -> [Double] -> Either MathError TestResult`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.chi_square_test`

Pearson goodness-of-fit chi-square statistic for observed and positive expected counts; first argument is number of fitted nuisance parameters.

Original signature: `Int -> [Double] -> [Double] -> Either MathError TestResult`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.variance_f_test`

Two-sided normal-population variance-ratio F test, requiring positive sample variances.

Original signature: `[Double] -> [Double] -> Either MathError TestResult`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.anova`

One-way fixed-effects F test on independent normal groups with common variance; each group requires n>=2.

Original signature: `[[Double]] -> Either MathError TestResult`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.welch_anova`

Welch one-way heteroscedastic F test with Satterthwaite denominator degrees of freedom.

Original signature: `[[Double]] -> Either MathError TestResult`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.kruskal_wallis`

Tie-corrected Kruskal--Wallis H statistic with chi-square asymptotic calibration.

Original signature: `[[Double]] -> Either MathError TestResult`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.mann_whitney`

Mann--Whitney U for the first sample; two-sided tie-corrected normal approximation with continuity correction.

Original signature: `[Double] -> [Double] -> Either MathError TestResult`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.wilcoxon`

Wilcoxon signed-rank test for differences, dropping zeros and using average absolute tied ranks and continuity-corrected normal calibration.

Original signature: `[Double] -> Either MathError TestResult`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.kolmogorov_smirnov`

Two-sided KS statistic and asymptotic p value against a fully specified continuous distribution. A Jacobi theta transformation handles very small statistics. Fitting parameters from these observations invalidates this null calibration.

Original signature: `P.Distribution -> [Double] -> Either MathError TestResult`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.shapiro_wilk`

Royston's AS R94 coefficients and normal-tail approximation, n=3..5000, uncensored samples. Numerical constants are published statistical data. Reference: https://doi.org/10.2307/2986146

Original signature: `[Double] -> Either MathError TestResult`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.anderson_darling`

Anderson--Darling normality test after fitting the sample mean and unbiased sample standard deviation. The returned statistic is raw A²; Stephens' p-value approximation uses A²*(1+0.75/n+2.25/n²). For adjusted A²>13, the published approximation is outside its calibrated range and the extreme tail is reported as zero instead of extrapolating its quadratic back upward.

Original signature: `[Double] -> Either MathError TestResult`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.levene`

One-way ANOVA on absolute deviations; True chooses group medians (Brown--Forsythe), False chooses means.

Original signature: `Bool -> [[Double]] -> Either MathError TestResult`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.bartlett`

Bartlett homogeneity-of-variance test, appropriate for normal samples; positive group variances required.

Original signature: `[[Double]] -> Either MathError TestResult`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.fisher_exact`

Two-sided Fisher exact test on nonnegative 2-by-2 counts (a,b;c,d). Enumerates tables with mass no larger than the observed table.

Original signature: `Int -> Int -> Int -> Int -> Either MathError TestResult`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.permutation_test`

Seeded two-sided random-label permutation p value for a caller statistic, with the (b+1)/(B+1) correction.

Original signature: `Int -> ([Double] -> [Double] -> Either MathError Double) -> [Double] -> [Double] -> R.RNG -> Either MathError (TestResult, R.RNG)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.eta_squared`

One-way ANOVA explained sum of squares divided by total sum of squares.

Original signature: `[[Double]] -> Either MathError Double`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.grubbs`

Two-sided single-outlier Grubbs test, returning candidate index, G statistic and rejection decision at alpha; normality assumption required.

Original signature: `Double -> [Double] -> Either MathError (Int, Double, Bool)`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.masked`

Keep True-mask observations, then validate retained values. Excluded NaN/infinity do not contaminate results.

Original signature: `[Bool] -> [Double] -> Either MathError [Double]`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.test_statistic`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `TestResult -> field`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.p_value`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `TestResult -> field`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.degrees_of_freedom`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `TestResult -> field`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

## `statistics_advanced.TestResult`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Each C argument after `context` uses a borrowed Value in original source order; `out` owns one successful result and is untouched on error.

