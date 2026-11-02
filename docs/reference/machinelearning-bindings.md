# Machine-learning bindings

`from hmath import machinelearning` exposes the original dense CPU estimators. `Dataset` is a list of finite Double observation rows. No estimator, preprocessing rule, seed, stopping rule, feature ordering or class tie order is substituted. Fit preprocessing inside each training fold; successful fitting preserves the source residual, completed iterations and convergence flag rather than implying an optimum was reached.

C includes `hmath_machinelearning.h`; values follow the [owned structured protocol](values.md). All inputs are borrowed for a synchronous call; outputs transfer one reference and stay untouched on failure. Original MathError/status11 retains full constructor/payload. Immutable owners support independent readers holding their own references; final shutdown is BUSY while owners exist. Python supports close()/context managers.

`fitted(result)` returns an independently owned model/payload. `fit_iterations`, `fit_residual`, and `fit_converged` preserve the original diagnostics. Generic Fit payloads retain their structure and native precision. Search callbacks receive `(configuration, Fold)` as two positional arguments and return a Double loss; original mathematical failures remain checked Left errors, while unexpected Python exceptions rethrow after native cleanup. Retained callback owners travel with returned objects.

Categorical encoders retain actual native Ord/Eq dictionaries, including exact integers/rationals, typed FP32/64, bounded integers, Bool/String, recursive collection labels and supported native domain types. No labels become Double approximations or text keys. Explicit `prototype=` is required when collection/optional element types cannot be inferred; it is a type example, never a training label. Empty input failures retain the original source error. Existing encoders retain their learned native label type for every subsequent operation.

## `average`

`machinelearning.average()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Linkage
```

```c
hmath_status hmath_ml_average(hmath_context *context, hmath_value **out);
```

## `complete`

`machinelearning.complete()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Linkage
```

```c
hmath_status hmath_ml_complete(hmath_context *context, hmath_value **out);
```

## `merge`

`machinelearning.merge(count, count2, number, count3)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Int -> Int -> Double -> Int -> Merge
```

```c
hmath_status hmath_ml_merge(hmath_context *context, const hmath_value *count, const hmath_value *count2, const hmath_value *number, const hmath_value *count3, hmath_value **out);
```

## `single`

`machinelearning.single()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Linkage
```

```c
hmath_status hmath_ml_single(hmath_context *context, hmath_value **out);
```

## `ward`

`machinelearning.ward()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Linkage
```

```c
hmath_status hmath_ml_ward(hmath_context *context, hmath_value **out);
```

## `affinity_propagation`

`machinelearning.affinity_propagation(ml_config, number, number2, dataset)`

 The preference is the common diagonal similarity; damping is in [0.5,1). Stops only after exemplar identities remain unchanged for ten iterations. 

```haskell
MLConfig -> Double -> Double -> Dataset -> Either MathError (Fit [Int])
```

```c
hmath_status hmath_ml_affinity_propagation(hmath_context *context, const hmath_value *ml_config, const hmath_value *number, const hmath_value *number2, const hmath_value *dataset, hmath_value **out);
```

## `cluster_centers`

`machinelearning.cluster_centers(cluster_model)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
ClusterModel -> Dataset
```

```c
hmath_status hmath_ml_cluster_centers(hmath_context *context, const hmath_value *cluster_model, hmath_value **out);
```

## `cut_hierarchy`

`machinelearning.cut_hierarchy(count, count2, values)`

Validate the entire hierarchy and return k cluster labels in original observation order.

```haskell
Int -> Int -> [Merge] -> Either MathError [Int]
```

```c
hmath_status hmath_ml_cut_hierarchy(hmath_context *context, const hmath_value *count, const hmath_value *count2, const hmath_value *values, hmath_value **out);
```

## `dbscan`

`machinelearning.dbscan(number, count, dataset)`

Density expansion using a positive Euclidean radius; minimumPoints includes the observation itself.

```haskell
Double -> Int -> Dataset -> Either MathError [Int]
```

```c
hmath_status hmath_ml_dbscan(hmath_context *context, const hmath_value *number, const hmath_value *count, const hmath_value *dataset, hmath_value **out);
```

## `extract_optics`

`machinelearning.extract_optics(number, values)`

Extract DBSCAN-style labels at epsilon from a checked OPTICS ordering; noise is -1.

```haskell
Double -> [(Int, Maybe Double, Maybe Double)] -> Either MathError [Int]
```

```c
hmath_status hmath_ml_extract_optics(hmath_context *context, const hmath_value *number, const hmath_value *values, hmath_value **out);
```

## `fit_gaussian_mixture`

`machinelearning.fit_gaussian_mixture(ml_config, count, number, dataset)`

Full-covariance EM initialized by k-means++; positive ridge is added at each covariance update. Collapsed component mass fails.

```haskell
MLConfig -> Int -> Double -> Dataset -> Either MathError (Fit GaussianMixture)
```

```c
hmath_status hmath_ml_fit_gaussian_mixture(hmath_context *context, const hmath_value *ml_config, const hmath_value *count, const hmath_value *number, const hmath_value *dataset, hmath_value **out);
```

## `hierarchical`

`machinelearning.hierarchical(linkage, dataset)`

Agglomerate the closest active clusters to produce all n-1 linkage rows.

```haskell
Linkage -> Dataset -> Either MathError [Merge]
```

```c
hmath_status hmath_ml_hierarchical(hmath_context *context, const hmath_value *linkage, const hmath_value *dataset, hmath_value **out);
```

## `k_means`

`machinelearning.k_means(ml_config, count, dataset)`

Seeded random-center Lloyd iteration; residual is total center displacement.

```haskell
MLConfig -> Int -> Dataset -> Either MathError (Fit ClusterModel)
```

```c
hmath_status hmath_ml_k_means(hmath_context *context, const hmath_value *ml_config, const hmath_value *count, const hmath_value *dataset, hmath_value **out);
```

## `k_means_plus_plus`

`machinelearning.k_means_plus_plus(ml_config, count, dataset)`

D-squared k-means++ initialization followed by Lloyd center updates.

```haskell
MLConfig -> Int -> Dataset -> Either MathError (Fit ClusterModel)
```

```c
hmath_status hmath_ml_k_means_plus_plus(hmath_context *context, const hmath_value *ml_config, const hmath_value *count, const hmath_value *dataset, hmath_value **out);
```

## `k_medoids`

`machinelearning.k_medoids(ml_config, count, dataset)`

PAM exhaustive medoid swaps. Return original row indices; residual is the objective decrease.

```haskell
MLConfig -> Int -> Dataset -> Either MathError (Fit [Int])
```

```c
hmath_status hmath_ml_k_medoids(hmath_context *context, const hmath_value *ml_config, const hmath_value *count, const hmath_value *dataset, hmath_value **out);
```

## `left_cluster`

`machinelearning.left_cluster(merge)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Merge -> Int
```

```c
hmath_status hmath_ml_left_cluster(hmath_context *context, const hmath_value *merge, hmath_value **out);
```

## `mean_shift`

`machinelearning.mean_shift(ml_config, number, dataset)`

Gaussian-kernel mean shift from every training point; modes within bandwidth/2 are merged.

```haskell
MLConfig -> Double -> Dataset -> Either MathError (Fit ClusterModel)
```

```c
hmath_status hmath_ml_mean_shift(hmath_context *context, const hmath_value *ml_config, const hmath_value *number, const hmath_value *dataset, hmath_value **out);
```

## `merge_distance`

`machinelearning.merge_distance(merge)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Merge -> Double
```

```c
hmath_status hmath_ml_merge_distance(hmath_context *context, const hmath_value *merge, hmath_value **out);
```

## `merged_size`

`machinelearning.merged_size(merge)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Merge -> Int
```

```c
hmath_status hmath_ml_merged_size(hmath_context *context, const hmath_value *merge, hmath_value **out);
```

## `mini_batch_k_means`

`machinelearning.mini_batch_k_means(ml_config, count, count2, dataset)`

 Online center updates with per-cluster counts and seeded shuffled batches. One outer iteration consumes batchSize observations, cycling shuffled data. 

```haskell
MLConfig -> Int -> Int -> Dataset -> Either MathError (Fit ClusterModel)
```

```c
hmath_status hmath_ml_mini_batch_k_means(hmath_context *context, const hmath_value *ml_config, const hmath_value *count, const hmath_value *count2, const hmath_value *dataset, hmath_value **out);
```

## `mixture_covariances`

`machinelearning.mixture_covariances(gaussian_mixture)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
GaussianMixture -> [Dataset]
```

```c
hmath_status hmath_ml_mixture_covariances(hmath_context *context, const hmath_value *gaussian_mixture, hmath_value **out);
```

## `mixture_means`

`machinelearning.mixture_means(gaussian_mixture)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
GaussianMixture -> Dataset
```

```c
hmath_status hmath_ml_mixture_means(hmath_context *context, const hmath_value *gaussian_mixture, hmath_value **out);
```

## `mixture_responsibilities`

`machinelearning.mixture_responsibilities(gaussian_mixture, dataset)`

Compute normalized posterior component probabilities with log-sum-exp stabilization.

```haskell
GaussianMixture -> Dataset -> Either MathError Dataset
```

```c
hmath_status hmath_ml_mixture_responsibilities(hmath_context *context, const hmath_value *gaussian_mixture, const hmath_value *dataset, hmath_value **out);
```

## `mixture_weights`

`machinelearning.mixture_weights(gaussian_mixture)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
GaussianMixture -> [Double]
```

```c
hmath_status hmath_ml_mixture_weights(hmath_context *context, const hmath_value *gaussian_mixture, hmath_value **out);
```

## `optics`

`machinelearning.optics(number, count, dataset)`

 OPTICS (Ankerst et al., SIGMOD 1999): ordered point index, core distance, reachability distance. Undefined reachability starts each connected expansion. 

```haskell
Double -> Int -> Dataset -> Either MathError [(Int, Maybe Double, Maybe Double)]
```

```c
hmath_status hmath_ml_optics(hmath_context *context, const hmath_value *number, const hmath_value *count, const hmath_value *dataset, hmath_value **out);
```

## `predict_clusters`

`machinelearning.predict_clusters(cluster_model, dataset)`

Assign each row to its closest squared-Euclidean center; ties use the first center.

```haskell
ClusterModel -> Dataset -> Either MathError [Int]
```

```c
hmath_status hmath_ml_predict_clusters(hmath_context *context, const hmath_value *cluster_model, const hmath_value *dataset, hmath_value **out);
```

## `right_cluster`

`machinelearning.right_cluster(merge)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Merge -> Int
```

```c
hmath_status hmath_ml_right_cluster(hmath_context *context, const hmath_value *merge, hmath_value **out);
```

## `spectral_clustering`

`machinelearning.spectral_clustering(ml_config, count, number, dataset)`

Cluster row-normalized leading eigenvectors of the normalized Gaussian affinity matrix.

```haskell
MLConfig -> Int -> Double -> Dataset -> Either MathError (Fit [Int])
```

```c
hmath_status hmath_ml_spectral_clustering(hmath_context *context, const hmath_value *ml_config, const hmath_value *count, const hmath_value *number, const hmath_value *dataset, hmath_value **out);
```

## `canonical_correlations`

`machinelearning.canonical_correlations(cca)`

Singular values of the whitened cross-covariance, in descending order.

```haskell
CCA -> [Double]
```

```c
hmath_status hmath_ml_canonical_correlations(hmath_context *context, const hmath_value *cca, hmath_value **out);
```

## `classical_mds`

`machinelearning.classical_mds(count, dataset)`

 Classical metric MDS. Negative eigenvalues are omitted; requesting a dimension beyond positive rank fails instead of creating imaginary axes. 

```haskell
Int -> Dataset -> Either MathError Dataset
```

```c
hmath_status hmath_ml_classical_mds(hmath_context *context, const hmath_value *count, const hmath_value *dataset, hmath_value **out);
```

## `factor_loadings`

`machinelearning.factor_loadings(factor_analysis)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
FactorAnalysis -> Dataset
```

```c
hmath_status hmath_ml_factor_loadings(hmath_context *context, const hmath_value *factor_analysis, hmath_value **out);
```

## `factor_noise`

`machinelearning.factor_noise(factor_analysis)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
FactorAnalysis -> [Double]
```

```c
hmath_status hmath_ml_factor_noise(hmath_context *context, const hmath_value *factor_analysis, hmath_value **out);
```

## `finish_pca`

`machinelearning.finish_pca(count, incremental_pca)`

Extract principal axes from accumulated sample covariance; requires at least two observations.

```haskell
Int -> IncrementalPCA -> Either MathError PCA
```

```c
hmath_status hmath_ml_finish_pca(hmath_context *context, const hmath_value *count, const hmath_value *incremental_pca, hmath_value **out);
```

## `fit_cca`

`machinelearning.fit_cca(count, number, dataset, dataset2)`

Fit paired canonical directions with a strictly positive diagonal covariance ridge.

```haskell
Int -> Double -> Dataset -> Dataset -> Either MathError CCA
```

```c
hmath_status hmath_ml_fit_cca(hmath_context *context, const hmath_value *count, const hmath_value *number, const hmath_value *dataset, const hmath_value *dataset2, hmath_value **out);
```

## `fit_factor_analysis`

`machinelearning.fit_factor_analysis(ml_config, count, number, dataset)`

 Gaussian factor-analysis EM with diagonal noise floor. Unlike PCA, each observed feature has its own learned residual variance. 

```haskell
MLConfig -> Int -> Double -> Dataset -> Either MathError (Fit FactorAnalysis)
```

```c
hmath_status hmath_ml_fit_factor_analysis(hmath_context *context, const hmath_value *ml_config, const hmath_value *count, const hmath_value *number, const hmath_value *dataset, hmath_value **out);
```

## `fit_ica`

`machinelearning.fit_ica(ml_config, count, dataset)`

 Symmetric FastICA with tanh nonlinearity (Hyvarinen 1999), whitening by sample covariance. Convergence accounts for independent component signs. 

```haskell
MLConfig -> Int -> Dataset -> Either MathError (Fit ICA)
```

```c
hmath_status hmath_ml_fit_ica(hmath_context *context, const hmath_value *ml_config, const hmath_value *count, const hmath_value *dataset, hmath_value **out);
```

## `fit_kernel_pca`

`machinelearning.fit_kernel_pca(count, kernel, dataset)`

Fit kernel principal axes; count must be smaller than n and within positive numerical rank.

```haskell
Int -> Kernel -> Dataset -> Either MathError KernelPCA
```

```c
hmath_status hmath_ml_fit_kernel_pca(hmath_context *context, const hmath_value *count, const hmath_value *kernel, const hmath_value *dataset, hmath_value **out);
```

## `fit_pca`

`machinelearning.fit_pca(count, dataset)`

Fit count principal axes from at least two observations; uses sample covariance (denominator n-1).

```haskell
Int -> Dataset -> Either MathError PCA
```

```c
hmath_status hmath_ml_fit_pca(hmath_context *context, const hmath_value *count, const hmath_value *dataset, hmath_value **out);
```

## `fit_pls`

`machinelearning.fit_pls(ml_config, count, dataset, dataset2)`

 PLS2 NIPALS with regression deflation; count cannot exceed the predictor rank. Inner fixed-point iteration obeys the supplied convergence budget. 

```haskell
MLConfig -> Int -> Dataset -> Dataset -> Either MathError (Fit PLS)
```

```c
hmath_status hmath_ml_fit_pls(hmath_context *context, const hmath_value *ml_config, const hmath_value *count, const hmath_value *dataset, const hmath_value *dataset2, hmath_value **out);
```

## `incremental_pca`

`machinelearning.incremental_pca(count)`

Create empty running covariance state for a positive feature dimension.

```haskell
Int -> Either MathError IncrementalPCA
```

```c
hmath_status hmath_ml_incremental_pca(hmath_context *context, const hmath_value *count, hmath_value **out);
```

## `inverse_pca`

`machinelearning.inverse_pca(pca, dataset)`

Reconstruct original features from retained scores and restore the training mean.

```haskell
PCA -> Dataset -> Either MathError Dataset
```

```c
hmath_status hmath_ml_inverse_pca(hmath_context *context, const hmath_value *pca, const hmath_value *dataset, hmath_value **out);
```

## `isomap`

`machinelearning.isomap(count, count2, dataset)`

Build a symmetric k-neighbor graph, compute geodesics, then metric MDS. Disconnected graphs fail.

```haskell
Int -> Int -> Dataset -> Either MathError Dataset
```

```c
hmath_status hmath_ml_isomap(hmath_context *context, const hmath_value *count, const hmath_value *count2, const hmath_value *dataset, hmath_value **out);
```

## `merge_pca`

`machinelearning.merge_pca(incremental_pca, incremental_pca2)`

Combine independent batch statistics with the between-mean scatter correction.

```haskell
IncrementalPCA -> IncrementalPCA -> Either MathError IncrementalPCA
```

```c
hmath_status hmath_ml_merge_pca(hmath_context *context, const hmath_value *incremental_pca, const hmath_value *incremental_pca2, hmath_value **out);
```

## `pca_components`

`machinelearning.pca_components(pca)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
PCA -> Dataset
```

```c
hmath_status hmath_ml_pca_components(hmath_context *context, const hmath_value *pca, hmath_value **out);
```

## `pca_mean`

`machinelearning.pca_mean(pca)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
PCA -> [Double]
```

```c
hmath_status hmath_ml_pca_mean(hmath_context *context, const hmath_value *pca, hmath_value **out);
```

## `pca_variances`

`machinelearning.pca_variances(pca)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
PCA -> [Double]
```

```c
hmath_status hmath_ml_pca_variances(hmath_context *context, const hmath_value *pca, hmath_value **out);
```

## `predict_pls`

`machinelearning.predict_pls(pls, dataset)`

Predict response rows using fitted PLS coefficients and training centers.

```haskell
PLS -> Dataset -> Either MathError Dataset
```

```c
hmath_status hmath_ml_predict_pls(hmath_context *context, const hmath_value *pls, const hmath_value *dataset, hmath_value **out);
```

## `random_projection`

`machinelearning.random_projection(ml_config, count, dataset)`

Seeded Gaussian projection with variance 1/dimension per coefficient. Returns transformed rows.

```haskell
MLConfig -> Int -> Dataset -> Either MathError Dataset
```

```c
hmath_status hmath_ml_random_projection(hmath_context *context, const hmath_value *ml_config, const hmath_value *count, const hmath_value *dataset, hmath_value **out);
```

## `transform_cca`

`machinelearning.transform_cca(cca, dataset, dataset2)`

Project paired query rows with fitted training centers and canonical directions.

```haskell
CCA -> Dataset -> Dataset -> Either MathError (Dataset, Dataset)
```

```c
hmath_status hmath_ml_transform_cca(hmath_context *context, const hmath_value *cca, const hmath_value *dataset, const hmath_value *dataset2, hmath_value **out);
```

## `transform_ica`

`machinelearning.transform_ica(ica, dataset)`

Apply the fitted centering and unmixing directions to new observations.

```haskell
ICA -> Dataset -> Either MathError Dataset
```

```c
hmath_status hmath_ml_transform_ica(hmath_context *context, const hmath_value *ica, const hmath_value *dataset, hmath_value **out);
```

## `transform_kernel_pca`

`machinelearning.transform_kernel_pca(kernel_pca, dataset)`

Center query kernels with training means before projection, without fitting query statistics.

```haskell
KernelPCA -> Dataset -> Either MathError Dataset
```

```c
hmath_status hmath_ml_transform_kernel_pca(hmath_context *context, const hmath_value *kernel_pca, const hmath_value *dataset, hmath_value **out);
```

## `transform_pca`

`machinelearning.transform_pca(pca, dataset)`

Center with the training mean and project onto retained axes; no whitening is applied.

```haskell
PCA -> Dataset -> Either MathError Dataset
```

```c
hmath_status hmath_ml_transform_pca(hmath_context *context, const hmath_value *pca, const hmath_value *dataset, hmath_value **out);
```

## `truncated_svd`

`machinelearning.truncated_svd(count, dataset)`

Return reduced (U, singular values, V-transpose) from LAPACK, keeping the largest count values.

```haskell
Int -> Dataset -> Either MathError (Dataset, [Double], Dataset)
```

```c
hmath_status hmath_ml_truncated_svd(hmath_context *context, const hmath_value *count, const hmath_value *dataset, hmath_value **out);
```

## `tsne`

`machinelearning.tsne(ml_config, count, number, dataset)`

Exact all-pairs t-SNE; perplexity must be strictly between one and n.

```haskell
MLConfig -> Int -> Double -> Dataset -> Either MathError (Fit Dataset)
```

```c
hmath_status hmath_ml_tsne(hmath_context *context, const hmath_value *ml_config, const hmath_value *count, const hmath_value *number, const hmath_value *dataset, hmath_value **out);
```

## `umap`

`machinelearning.umap(ml_config, count, count2, number, number2, dataset)`

 Exact full fuzzy-set cross entropy, caller supplies fitted curve a,b. Local connectivity rho is the first positive neighbor distance. This dense reference resolves every repulsive pair instead of sampling negatives. 

```haskell
MLConfig -> Int -> Int -> Double -> Double -> Dataset -> Either MathError (Fit Dataset)
```

```c
hmath_status hmath_ml_umap(hmath_context *context, const hmath_value *ml_config, const hmath_value *count, const hmath_value *count2, const hmath_value *number, const hmath_value *number2, const hmath_value *dataset, hmath_value **out);
```

## `update_pca`

`machinelearning.update_pca(incremental_pca, dataset)`

Merge observations by Welford updates. Empty batches preserve the previous state.

```haskell
IncrementalPCA -> Dataset -> Either MathError IncrementalPCA
```

```c
hmath_status hmath_ml_update_pca(hmath_context *context, const hmath_value *incremental_pca, const hmath_value *dataset, hmath_value **out);
```

## `fit`

`machinelearning.fit(value, count, number, flag)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
a -> Int -> Double -> Bool -> Fit a
```

```c
hmath_status hmath_ml_fit(hmath_context *context, const hmath_value *value, const hmath_value *count, const hmath_value *number, const hmath_value *flag, hmath_value **out);
```

## `ml_config`

`machinelearning.ml_config(count, number, number2, seed)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Int -> Double -> Double -> Word64 -> MLConfig
```

```c
hmath_status hmath_ml_ml_config(hmath_context *context, const hmath_value *count, const hmath_value *number, const hmath_value *number2, const hmath_value *seed, hmath_value **out);
```

## `default_ml_config`

`machinelearning.default_ml_config()`

500 iterations, absolute residual tolerance 1e-8, rate 0.05, PCG seed 42.

```haskell
MLConfig
```

```c
hmath_status hmath_ml_default_ml_config(hmath_context *context, hmath_value **out);
```

## `fit_converged`

`machinelearning.fit_converged(fit)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Fit a -> Bool
```

```c
hmath_status hmath_ml_fit_converged(hmath_context *context, const hmath_value *fit, hmath_value **out);
```

## `fit_iterations`

`machinelearning.fit_iterations(fit)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Fit a -> Int
```

```c
hmath_status hmath_ml_fit_iterations(hmath_context *context, const hmath_value *fit, hmath_value **out);
```

## `fit_residual`

`machinelearning.fit_residual(fit)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Fit a -> Double
```

```c
hmath_status hmath_ml_fit_residual(hmath_context *context, const hmath_value *fit, hmath_value **out);
```

## `fitted`

`machinelearning.fitted(fit)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Fit a -> a
```

```c
hmath_status hmath_ml_fitted(hmath_context *context, const hmath_value *fit, hmath_value **out);
```

## `ml_iterations`

`machinelearning.ml_iterations(ml_config)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
MLConfig -> Int
```

```c
hmath_status hmath_ml_ml_iterations(hmath_context *context, const hmath_value *ml_config, hmath_value **out);
```

## `ml_rate`

`machinelearning.ml_rate(ml_config)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
MLConfig -> Double
```

```c
hmath_status hmath_ml_ml_rate(hmath_context *context, const hmath_value *ml_config, hmath_value **out);
```

## `ml_seed`

`machinelearning.ml_seed(ml_config)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
MLConfig -> Word64
```

```c
hmath_status hmath_ml_ml_seed(hmath_context *context, const hmath_value *ml_config, hmath_value **out);
```

## `ml_tolerance`

`machinelearning.ml_tolerance(ml_config)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
MLConfig -> Double
```

```c
hmath_status hmath_ml_ml_tolerance(hmath_context *context, const hmath_value *ml_config, hmath_value **out);
```

## `ball_tree`

`machinelearning.ball_tree()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
IndexKind
```

```c
hmath_status hmath_ml_ball_tree(hmath_context *context, hmath_value **out);
```

## `kd_tree`

`machinelearning.kd_tree()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
IndexKind
```

```c
hmath_status hmath_ml_kd_tree(hmath_context *context, hmath_value **out);
```

## `neighbor_result`

`machinelearning.neighbor_result(values, count, flag)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
[(Int, Double)] -> Int -> Bool -> NeighborResult
```

```c
hmath_status hmath_ml_neighbor_result(hmath_context *context, const hmath_value *values, const hmath_value *count, const hmath_value *flag, hmath_value **out);
```

## `build_index`

`machinelearning.build_index(index_kind, count, dataset)`

Build an exact search tree with at most leafSize observations per leaf.

```haskell
IndexKind -> Int -> Dataset -> Either MathError SpatialIndex
```

```c
hmath_status hmath_ml_build_index(hmath_context *context, const hmath_value *index_kind, const hmath_value *count, const hmath_value *dataset, hmath_value **out);
```

## `build_lsh`

`machinelearning.build_lsh(seed, count, count2, number, dataset)`

Build tables with projections scalar hashes each and positive bucket width. Storage budget is explicit.

```haskell
Word64 -> Int -> Int -> Double -> Dataset -> Either MathError LSH
```

```c
hmath_status hmath_ml_build_lsh(hmath_context *context, const hmath_value *seed, const hmath_value *count, const hmath_value *count2, const hmath_value *number, const hmath_value *dataset, hmath_value **out);
```

## `decision_one_class_svm`

`machinelearning.decision_one_class_svm(one_class_svm, dataset)`

Return signed novelty margins: positive indicates an inlier under the fitted kernel boundary.

```haskell
OneClassSVM -> Dataset -> Either MathError [Double]
```

```c
hmath_status hmath_ml_decision_one_class_svm(hmath_context *context, const hmath_value *one_class_svm, const hmath_value *dataset, hmath_value **out);
```

## `exhaustive`

`machinelearning.exhaustive(neighbor_result)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
NeighborResult -> Bool
```

```c
hmath_status hmath_ml_exhaustive(hmath_context *context, const hmath_value *neighbor_result, hmath_value **out);
```

## `fit_isolation_forest`

`machinelearning.fit_isolation_forest(seed, count, count2, dataset)`

Seeded independent isolation trees using subsamples of 2..2048 observations.

```haskell
Word64 -> Int -> Int -> Dataset -> Either MathError IsolationForest
```

```c
hmath_status hmath_ml_fit_isolation_forest(hmath_context *context, const hmath_value *seed, const hmath_value *count, const hmath_value *count2, const hmath_value *dataset, hmath_value **out);
```

## `fit_one_class_svm`

`machinelearning.fit_one_class_svm(ml_config, kernel, number, dataset)`

 nu-SVM dual coordinate descent: sum alpha=1, 0<=alpha<=1/(nu*n). The reported gap is the pairwise box-constrained KKT violation. 

```haskell
MLConfig -> Kernel -> Double -> Dataset -> Either MathError (Fit OneClassSVM)
```

```c
hmath_status hmath_ml_fit_one_class_svm(hmath_context *context, const hmath_value *ml_config, const hmath_value *kernel, const hmath_value *number, const hmath_value *dataset, hmath_value **out);
```

## `knn_classify`

`machinelearning.knn_classify(count, spatial_index, values, dataset)`

Majority vote among k exact neighbors; targets follow original training row order.

```haskell
Int -> SpatialIndex -> [Int] -> Dataset -> Either MathError [Int]
```

```c
hmath_status hmath_ml_knn_classify(hmath_context *context, const hmath_value *count, const hmath_value *spatial_index, const hmath_value *values, const hmath_value *dataset, hmath_value **out);
```

## `knn_regress`

`machinelearning.knn_regress(count, spatial_index, values, dataset)`

Average the k exact nearest training responses for each query row.

```haskell
Int -> SpatialIndex -> [Double] -> Dataset -> Either MathError [Double]
```

```c
hmath_status hmath_ml_knn_regress(hmath_context *context, const hmath_value *count, const hmath_value *spatial_index, const hmath_value *values, const hmath_value *dataset, hmath_value **out);
```

## `local_outlier_factor`

`machinelearning.local_outlier_factor(count, dataset)`

 Training-set LOF with ties included at the kth neighbor distance. Identical neighborhoods have LOF 1, including the infinite-density 0/0 limiting case. 

```haskell
Int -> Dataset -> Either MathError [Double]
```

```c
hmath_status hmath_ml_local_outlier_factor(hmath_context *context, const hmath_value *count, const hmath_value *dataset, hmath_value **out);
```

## `nearest_neighbors`

`machinelearning.nearest_neighbors(count, count2, spatial_index, values)`

 maxLeaves is a query work budget. A False exhaustive flag means unexplored nodes might improve the result. Even approximate results have exact distances. 

```haskell
Int -> Int -> SpatialIndex -> [Double] -> Either MathError NeighborResult
```

```c
hmath_status hmath_ml_nearest_neighbors(hmath_context *context, const hmath_value *count, const hmath_value *count2, const hmath_value *spatial_index, const hmath_value *values, hmath_value **out);
```

## `neighbors`

`machinelearning.neighbors(neighbor_result)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
NeighborResult -> [(Int, Double)]
```

```c
hmath_status hmath_ml_neighbors(hmath_context *context, const hmath_value *neighbor_result, hmath_value **out);
```

## `query_lsh`

`machinelearning.query_lsh(count, lsh, values)`

Rank matching-bucket candidates by exact distance; may return fewer than k results, including none.

```haskell
Int -> LSH -> [Double] -> Either MathError [(Int, Double)]
```

```c
hmath_status hmath_ml_query_lsh(hmath_context *context, const hmath_value *count, const hmath_value *lsh, const hmath_value *values, hmath_value **out);
```

## `score_isolation_forest`

`machinelearning.score_isolation_forest(isolation_forest, dataset)`

Return 2^(-mean corrected path length / expected random-tree path length); larger means more anomalous.

```haskell
IsolationForest -> Dataset -> Either MathError [Double]
```

```c
hmath_status hmath_ml_score_isolation_forest(hmath_context *context, const hmath_value *isolation_forest, const hmath_value *dataset, hmath_value **out);
```

## `visited_leaves`

`machinelearning.visited_leaves(neighbor_result)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
NeighborResult -> Int
```

```c
hmath_status hmath_ml_visited_leaves(hmath_context *context, const hmath_value *neighbor_result, hmath_value **out);
```

## `box_cox`

`machinelearning.box_cox(number)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Double -> PowerTransform
```

```c
hmath_status hmath_ml_box_cox(hmath_context *context, const hmath_value *number, hmath_value **out);
```

## `constant_impute`

`machinelearning.constant_impute(number)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Double -> Imputation
```

```c
hmath_status hmath_ml_constant_impute(hmath_context *context, const hmath_value *number, hmath_value **out);
```

## `fold`

`machinelearning.fold(values, values2)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
[Int] -> [Int] -> Fold
```

```c
hmath_status hmath_ml_fold(hmath_context *context, const hmath_value *values, const hmath_value *values2, hmath_value **out);
```

## `mean_impute`

`machinelearning.mean_impute()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Imputation
```

```c
hmath_status hmath_ml_mean_impute(hmath_context *context, hmath_value **out);
```

## `median_impute`

`machinelearning.median_impute()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Imputation
```

```c
hmath_status hmath_ml_median_impute(hmath_context *context, hmath_value **out);
```

## `min_max`

`machinelearning.min_max()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Scaling
```

```c
hmath_status hmath_ml_min_max(hmath_context *context, hmath_value **out);
```

## `reject_unknown`

`machinelearning.reject_unknown()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
UnknownCategory
```

```c
hmath_status hmath_ml_reject_unknown(hmath_context *context, hmath_value **out);
```

## `robust_scale`

`machinelearning.robust_scale()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Scaling
```

```c
hmath_status hmath_ml_robust_scale(hmath_context *context, hmath_value **out);
```

## `standardize`

`machinelearning.standardize()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Scaling
```

```c
hmath_status hmath_ml_standardize(hmath_context *context, hmath_value **out);
```

## `yeo_johnson`

`machinelearning.yeo_johnson(number)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Double -> PowerTransform
```

```c
hmath_status hmath_ml_yeo_johnson(hmath_context *context, const hmath_value *number, hmath_value **out);
```

## `zero_unknown`

`machinelearning.zero_unknown()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
UnknownCategory
```

```c
hmath_status hmath_ml_zero_unknown(hmath_context *context, hmath_value **out);
```

## `fit_encoder`

`machinelearning.fit_encoder(values, *, prototype=None)`

Learn sorted category levels from a nonempty training label vector.

```haskell
Ord a => [a] -> Either MathError (Encoder a)
```

```c
hmath_status hmath_ml_fit_encoder(hmath_context *context, const hmath_value *values, const hmath_value *prototype, hmath_value **out);
```

## `fit_imputer`

`machinelearning.fit_imputer(imputation, dataset)`

Treat NaN as missing and reject infinities. All-missing columns require ConstantImpute.

```haskell
Imputation -> Dataset -> Either MathError Imputer
```

```c
hmath_status hmath_ml_fit_imputer(hmath_context *context, const hmath_value *imputation, const hmath_value *dataset, hmath_value **out);
```

## `fit_quantile_transformer`

`machinelearning.fit_quantile_transformer(dataset)`

Fit empirical feature quantiles using training rows only.

```haskell
Dataset -> Either MathError QuantileTransformer
```

```c
hmath_status hmath_ml_fit_quantile_transformer(hmath_context *context, const hmath_value *dataset, hmath_value **out);
```

## `fit_scaler`

`machinelearning.fit_scaler(scaling, dataset)`

Estimate one center and scale per training feature. Empty/ragged or nonfinite data fail.

```haskell
Scaling -> Dataset -> Either MathError Scaler
```

```c
hmath_status hmath_ml_fit_scaler(hmath_context *context, const hmath_value *scaling, const hmath_value *dataset, hmath_value **out);
```

## `grid_search`

`machinelearning.grid_search(values, values2, function)`

 Minimize a user-supplied validation loss, evaluated independently for every candidate/fold. The callback receives only the split indices, so it can fit preprocessing/model state inside each fold. Ties preserve candidate order. 

```haskell
[p] -> [Fold] -> (p -> Fold -> Either MathError Double) -> Either MathError (p, Double)
```

```c
hmath_status hmath_ml_grid_search(hmath_context *context, const hmath_value *values, const hmath_value *values2, const hmath_value *function, hmath_value **out);
```

## `impute`

`machinelearning.impute(imputer, dataset)`

Replace NaN with fitted training values while preserving observed entries and row order.

```haskell
Imputer -> Dataset -> Either MathError Dataset
```

```c
hmath_status hmath_ml_impute(hmath_context *context, const hmath_value *imputer, const hmath_value *dataset, hmath_value **out);
```

## `inverse_power_transform`

`machinelearning.inverse_power_transform(power_transform, dataset)`

Invert the selected power, rejecting values outside the transform range.

```haskell
PowerTransform -> Dataset -> Either MathError Dataset
```

```c
hmath_status hmath_ml_inverse_power_transform(hmath_context *context, const hmath_value *power_transform, const hmath_value *dataset, hmath_value **out);
```

## `inverse_quantile_transform`

`machinelearning.inverse_quantile_transform(quantile_transformer, dataset)`

Interpolate training order statistics at probabilities in [0,1].

```haskell
QuantileTransformer -> Dataset -> Either MathError Dataset
```

```c
hmath_status hmath_ml_inverse_quantile_transform(hmath_context *context, const hmath_value *quantile_transformer, const hmath_value *dataset, hmath_value **out);
```

## `inverse_transform`

`machinelearning.inverse_transform(scaler, dataset)`

Undo a fitted affine scaler, including its constant-feature convention.

```haskell
Scaler -> Dataset -> Either MathError Dataset
```

```c
hmath_status hmath_ml_inverse_transform(hmath_context *context, const hmath_value *scaler, const hmath_value *dataset, hmath_value **out);
```

## `k_fold`

`machinelearning.k_fold(seed, count, count2)`

Partition n shuffled indices into k nonempty validation folds; each row is held out exactly once.

```haskell
Word64 -> Int -> Int -> Either MathError [Fold]
```

```c
hmath_status hmath_ml_k_fold(hmath_context *context, const hmath_value *seed, const hmath_value *count, const hmath_value *count2, hmath_value **out);
```

## `label_decode`

`machinelearning.label_decode(encoder, values)`

Recover categories from checked integer codes.

```haskell
Encoder a -> [Int] -> Either MathError [a]
```

```c
hmath_status hmath_ml_label_decode(hmath_context *context, const hmath_value *encoder, const hmath_value *values, hmath_value **out);
```

## `label_encode`

`machinelearning.label_encode(encoder, values)`

Map known categories to zero-based codes; unseen categories fail.

```haskell
Eq a => Encoder a -> [a] -> Either MathError [Int]
```

```c
hmath_status hmath_ml_label_encode(hmath_context *context, const hmath_value *encoder, const hmath_value *values, hmath_value **out);
```

## `one_hot_encode`

`machinelearning.one_hot_encode(unknown_category, encoder, values)`

Emit one column per sorted training category under the explicit unknown-category policy.

```haskell
Eq a => UnknownCategory -> Encoder a -> [a] -> Either MathError Dataset
```

```c
hmath_status hmath_ml_one_hot_encode(hmath_context *context, const hmath_value *unknown_category, const hmath_value *encoder, const hmath_value *values, hmath_value **out);
```

## `power_transform`

`machinelearning.power_transform(power_transform, dataset)`

Apply the selected power to features. Box-Cox requires positive values; Yeo-Johnson allows signs.

```haskell
PowerTransform -> Dataset -> Either MathError Dataset
```

```c
hmath_status hmath_ml_power_transform(hmath_context *context, const hmath_value *power_transform, const hmath_value *dataset, hmath_value **out);
```

## `quantile_transform`

`machinelearning.quantile_transform(quantile_transformer, dataset)`

Map values to [0,1]. Ties use their average rank and values outside training extrema clamp.

```haskell
QuantileTransformer -> Dataset -> Either MathError Dataset
```

```c
hmath_status hmath_ml_quantile_transform(hmath_context *context, const hmath_value *quantile_transformer, const hmath_value *dataset, hmath_value **out);
```

## `random_search`

`machinelearning.random_search(seed, count, values, values2, function)`

Sample count distinct candidates from a finite set, then evaluate the supplied folds. Lower loss wins.

```haskell
Word64 -> Int -> [p] -> [Fold] -> (p -> Fold -> Either MathError Double) -> Either MathError (p, Double)
```

```c
hmath_status hmath_ml_random_search(hmath_context *context, const hmath_value *seed, const hmath_value *count, const hmath_value *values, const hmath_value *values2, const hmath_value *function, hmath_value **out);
```

## `stratified_k_fold`

`machinelearning.stratified_k_fold(seed, count, values, *, prototype=None)`

Round-robin each shuffled class across k folds. Every class needs at least k observations.

```haskell
Ord a => Word64 -> Int -> [a] -> Either MathError [Fold]
```

```c
hmath_status hmath_ml_stratified_k_fold(hmath_context *context, const hmath_value *seed, const hmath_value *count, const hmath_value *values, const hmath_value *prototype, hmath_value **out);
```

## `train_test_split`

`machinelearning.train_test_split(seed, number, count)`

Seeded split of n row indices. The fraction denotes test rows, rounded and clamped to [1,n-1].

```haskell
Word64 -> Double -> Int -> Either MathError Fold
```

```c
hmath_status hmath_ml_train_test_split(hmath_context *context, const hmath_value *seed, const hmath_value *number, const hmath_value *count, hmath_value **out);
```

## `training_indices`

`machinelearning.training_indices(fold)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Fold -> [Int]
```

```c
hmath_status hmath_ml_training_indices(hmath_context *context, const hmath_value *fold, hmath_value **out);
```

## `transform`

`machinelearning.transform(scaler, dataset)`

Apply training centers/scales to rows with the original feature count; no state is updated.

```haskell
Scaler -> Dataset -> Either MathError Dataset
```

```c
hmath_status hmath_ml_transform(hmath_context *context, const hmath_value *scaler, const hmath_value *dataset, hmath_value **out);
```

## `validation_indices`

`machinelearning.validation_indices(fold)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Fold -> [Int]
```

```c
hmath_status hmath_ml_validation_indices(hmath_context *context, const hmath_value *fold, hmath_value **out);
```

## `bernoulli_bayes`

`machinelearning.bernoulli_bayes()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
BayesFamily
```

```c
hmath_status hmath_ml_bernoulli_bayes(hmath_context *context, hmath_value **out);
```

## `binomial_logit`

`machinelearning.binomial_logit()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
GLMFamily
```

```c
hmath_status hmath_ml_binomial_logit(hmath_context *context, hmath_value **out);
```

## `elastic_net`

`machinelearning.elastic_net(number, number2)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Double -> Double -> Penalty
```

```c
hmath_status hmath_ml_elastic_net(hmath_context *context, const hmath_value *number, const hmath_value *number2, hmath_value **out);
```

## `gaussian_bayes`

`machinelearning.gaussian_bayes()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
BayesFamily
```

```c
hmath_status hmath_ml_gaussian_bayes(hmath_context *context, hmath_value **out);
```

## `lasso`

`machinelearning.lasso(number)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Double -> Penalty
```

```c
hmath_status hmath_ml_lasso(hmath_context *context, const hmath_value *number, hmath_value **out);
```

## `linear_kernel`

`machinelearning.linear_kernel()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Kernel
```

```c
hmath_status hmath_ml_linear_kernel(hmath_context *context, hmath_value **out);
```

## `multinomial_bayes`

`machinelearning.multinomial_bayes()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
BayesFamily
```

```c
hmath_status hmath_ml_multinomial_bayes(hmath_context *context, hmath_value **out);
```

## `ordinary`

`machinelearning.ordinary()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Penalty
```

```c
hmath_status hmath_ml_ordinary(hmath_context *context, hmath_value **out);
```

## `poisson_log`

`machinelearning.poisson_log()`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
GLMFamily
```

```c
hmath_status hmath_ml_poisson_log(hmath_context *context, hmath_value **out);
```

## `polynomial_kernel`

`machinelearning.polynomial_kernel(count, number, number2)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Int -> Double -> Double -> Kernel
```

```c
hmath_status hmath_ml_polynomial_kernel(hmath_context *context, const hmath_value *count, const hmath_value *number, const hmath_value *number2, hmath_value **out);
```

## `rbf_kernel`

`machinelearning.rbf_kernel(number)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Double -> Kernel
```

```c
hmath_status hmath_ml_rbf_kernel(hmath_context *context, const hmath_value *number, hmath_value **out);
```

## `ridge`

`machinelearning.ridge(number)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
Double -> Penalty
```

```c
hmath_status hmath_ml_ridge(hmath_context *context, const hmath_value *number, hmath_value **out);
```

## `bayesian_covariance`

`machinelearning.bayesian_covariance(bayesian_linear)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
BayesianLinear -> Dataset
```

```c
hmath_status hmath_ml_bayesian_covariance(hmath_context *context, const hmath_value *bayesian_linear, hmath_value **out);
```

## `bayesian_mean`

`machinelearning.bayesian_mean(bayesian_linear)`

Construct or inspect the original immutable record; field order follows the source signature.

```haskell
BayesianLinear -> LinearModel
```

```c
hmath_status hmath_ml_bayesian_mean(hmath_context *context, const hmath_value *bayesian_linear, hmath_value **out);
```

## `coefficients`

`machinelearning.coefficients(linear_model)`

Intercept followed by slopes in input feature order.

```haskell
LinearModel -> [Double]
```

```c
hmath_status hmath_ml_coefficients(hmath_context *context, const hmath_value *linear_model, hmath_value **out);
```

## `decision_svm`

`machinelearning.decision_svm(svm, dataset)`

Return signed kernel margins; zero is the fitted decision boundary.

```haskell
SVM -> Dataset -> Either MathError [Double]
```

```c
hmath_status hmath_ml_decision_svm(hmath_context *context, const hmath_value *svm, const hmath_value *dataset, hmath_value **out);
```

## `fit_bayesian`

`machinelearning.fit_bayesian(number, number2, dataset, values)`

 Isotropic zero-mean Gaussian prior, observation precision beta. Unlike frequentist ridge the prior also regularizes the intercept. 

```haskell
Double -> Double -> Dataset -> [Double] -> Either MathError BayesianLinear
```

```c
hmath_status hmath_ml_fit_bayesian(hmath_context *context, const hmath_value *number, const hmath_value *number2, const hmath_value *dataset, const hmath_value *values, hmath_value **out);
```

## `fit_discriminant`

`machinelearning.fit_discriminant(flag, number, dataset, values)`

 False = pooled covariance LDA; True = class covariance QDA. A positive diagonal ridge makes singular/constant-feature data explicitly regularized. 

```haskell
Bool -> Double -> Dataset -> [Int] -> Either MathError Discriminant
```

```c
hmath_status hmath_ml_fit_discriminant(hmath_context *context, const hmath_value *flag, const hmath_value *number, const hmath_value *dataset, const hmath_value *values, hmath_value **out);
```

## `fit_glm`

`machinelearning.fit_glm(ml_config, glm_family, number, dataset, values)`

Damped Newton/IRLS with nonnegative slope ridge. Residual is the penalized likelihood gradient norm.

```haskell
MLConfig -> GLMFamily -> Double -> Dataset -> [Double] -> Either MathError (Fit GLM)
```

```c
hmath_status hmath_ml_fit_glm(hmath_context *context, const hmath_value *ml_config, const hmath_value *glm_family, const hmath_value *number, const hmath_value *dataset, const hmath_value *values, hmath_value **out);
```

## `fit_gp_classifier`

`machinelearning.fit_gp_classifier(ml_config, kernel, dataset, values)`

Newton mode fitting for 0/1 labels. A 1e-10 diagonal jitter stabilizes the prior covariance.

```haskell
MLConfig -> Kernel -> Dataset -> [Double] -> Either MathError (Fit GPClassifier)
```

```c
hmath_status hmath_ml_fit_gp_classifier(hmath_context *context, const hmath_value *ml_config, const hmath_value *kernel, const hmath_value *dataset, const hmath_value *values, hmath_value **out);
```

## `fit_gaussian_process`

`machinelearning.fit_gaussian_process(kernel, number, dataset, values)`

Fit a GP with strictly positive observation-noise variance and a checked PSD kernel.

```haskell
Kernel -> Double -> Dataset -> [Double] -> Either MathError GaussianProcess
```

```c
hmath_status hmath_ml_fit_gaussian_process(hmath_context *context, const hmath_value *kernel, const hmath_value *number, const hmath_value *dataset, const hmath_value *values, hmath_value **out);
```

## `fit_linear`

`machinelearning.fit_linear(ml_config, penalty, dataset, values)`

Fit affine least squares or coordinate-descent elastic net. Ordinary/ridge use an SVD minimum-norm solve; iterative residual is coefficient displacement.

```haskell
MLConfig -> Penalty -> Dataset -> [Double] -> Either MathError (Fit LinearModel)
```

```c
hmath_status hmath_ml_fit_linear(hmath_context *context, const hmath_value *ml_config, const hmath_value *penalty, const hmath_value *dataset, const hmath_value *values, hmath_value **out);
```

## `fit_multinomial`

`machinelearning.fit_multinomial(ml_config, number, dataset, values)`

Fit all class logits by full-batch gradient descent with slope ridge. Residual is weight displacement.

```haskell
MLConfig -> Double -> Dataset -> [Int] -> Either MathError (Fit MultinomialModel)
```

```c
hmath_status hmath_ml_fit_multinomial(hmath_context *context, const hmath_value *ml_config, const hmath_value *number, const hmath_value *dataset, const hmath_value *values, hmath_value **out);
```

## `fit_naive_bayes`

`machinelearning.fit_naive_bayes(bayes_family, number, dataset, values)`

Fit class likelihoods. Smoothing is a variance floor for Gaussian and a pseudocount otherwise.

```haskell
BayesFamily -> Double -> Dataset -> [Int] -> Either MathError NaiveBayes
```

```c
hmath_status hmath_ml_fit_naive_bayes(hmath_context *context, const hmath_value *bayes_family, const hmath_value *number, const hmath_value *dataset, const hmath_value *values, hmath_value **out);
```

## `fit_robust`

`machinelearning.fit_robust(ml_config, number, dataset, values)`

Huber IRLS with fixed positive residual threshold, including intercept.

```haskell
MLConfig -> Double -> Dataset -> [Double] -> Either MathError (Fit LinearModel)
```

```c
hmath_status hmath_ml_fit_robust(hmath_context *context, const hmath_value *ml_config, const hmath_value *number, const hmath_value *dataset, const hmath_value *values, hmath_value **out);
```

## `fit_svm`

`machinelearning.fit_svm(ml_config, kernel, number, dataset, values)`

 Deterministic two-coordinate SMO for binary labels -1/+1. The reported residual is the largest box-constrained dual KKT violation. 

```haskell
MLConfig -> Kernel -> Double -> Dataset -> [Double] -> Either MathError (Fit SVM)
```

```c
hmath_status hmath_ml_fit_svm(hmath_context *context, const hmath_value *ml_config, const hmath_value *kernel, const hmath_value *number, const hmath_value *dataset, const hmath_value *values, hmath_value **out);
```

## `fit_weighted`

`machinelearning.fit_weighted(dataset, values, values2)`

Fit affine least squares with nonnegative observation weights. Zero-weight rows contribute no error.

```haskell
Dataset -> [Double] -> [Double] -> Either MathError LinearModel
```

```c
hmath_status hmath_ml_fit_weighted(hmath_context *context, const hmath_value *dataset, const hmath_value *values, const hmath_value *values2, hmath_value **out);
```

## `kernel`

`machinelearning.kernel(kernel, values, values2)`

Evaluate a checked PSD kernel on equal-length finite feature vectors.

```haskell
Kernel -> [Double] -> [Double] -> Either MathError Double
```

```c
hmath_status hmath_ml_kernel(hmath_context *context, const hmath_value *kernel, const hmath_value *values, const hmath_value *values2, hmath_value **out);
```

## `polynomial_features`

`machinelearning.polynomial_features(count, values)`

Build univariate columns x, x^2, ..., x^degree; the regression intercept supplies the constant.

```haskell
Int -> [Double] -> Either MathError Dataset
```

```c
hmath_status hmath_ml_polynomial_features(hmath_context *context, const hmath_value *count, const hmath_value *values, hmath_value **out);
```

## `predict_discriminant`

`machinelearning.predict_discriminant(discriminant, dataset)`

Classify with Gaussian discriminant log likelihoods using training covariance state.

```haskell
Discriminant -> Dataset -> Either MathError [Int]
```

```c
hmath_status hmath_ml_predict_discriminant(hmath_context *context, const hmath_value *discriminant, const hmath_value *dataset, hmath_value **out);
```

## `predict_glm`

`machinelearning.predict_glm(glm, dataset)`

Return conditional means: probabilities for BinomialLogit, positive rates for PoissonLog.

```haskell
GLM -> Dataset -> Either MathError [Double]
```

```c
hmath_status hmath_ml_predict_glm(hmath_context *context, const hmath_value *glm, const hmath_value *dataset, hmath_value **out);
```

## `predict_gp_classifier`

`machinelearning.predict_gp_classifier(gp_classifier, dataset)`

Approximate class-one probabilities using the logistic Gaussian variance correction.

```haskell
GPClassifier -> Dataset -> Either MathError [Double]
```

```c
hmath_status hmath_ml_predict_gp_classifier(hmath_context *context, const hmath_value *gp_classifier, const hmath_value *dataset, hmath_value **out);
```

## `predict_gaussian_process`

`machinelearning.predict_gaussian_process(gaussian_process, dataset)`

Return posterior latent-function (mean, variance), excluding observation noise.

```haskell
GaussianProcess -> Dataset -> Either MathError [(Double, Double)]
```

```c
hmath_status hmath_ml_predict_gaussian_process(hmath_context *context, const hmath_value *gaussian_process, const hmath_value *dataset, hmath_value **out);
```

## `predict_linear`

`machinelearning.predict_linear(linear_model, dataset)`

Predict one finite response per query row using the fitted intercept and slopes.

```haskell
LinearModel -> Dataset -> Either MathError [Double]
```

```c
hmath_status hmath_ml_predict_linear(hmath_context *context, const hmath_value *linear_model, const hmath_value *dataset, hmath_value **out);
```

## `predict_multinomial`

`machinelearning.predict_multinomial(multinomial_model, dataset)`

Return sorted (original label, probability) pairs for each observation.

```haskell
MultinomialModel -> Dataset -> Either MathError [[(Int, Double)]]
```

```c
hmath_status hmath_ml_predict_multinomial(hmath_context *context, const hmath_value *multinomial_model, const hmath_value *dataset, hmath_value **out);
```

## `predict_naive_bayes`

`machinelearning.predict_naive_bayes(naive_bayes, dataset)`

Select the class with greatest log posterior; preserve the original integer labels.

```haskell
NaiveBayes -> Dataset -> Either MathError [Int]
```

```c
hmath_status hmath_ml_predict_naive_bayes(hmath_context *context, const hmath_value *naive_bayes, const hmath_value *dataset, hmath_value **out);
```

## `predict_svm`

`machinelearning.predict_svm(svm, dataset)`

Classify margins as -1 or +1, with zero assigned +1.

```haskell
SVM -> Dataset -> Either MathError [Double]
```

```c
hmath_status hmath_ml_predict_svm(hmath_context *context, const hmath_value *svm, const hmath_value *dataset, hmath_value **out);
```

## `recursive_coefficients`

`machinelearning.recursive_coefficients(recursive_ls)`

Current intercept and slopes; updating creates a new state.

```haskell
RecursiveLS -> [Double]
```

```c
hmath_status hmath_ml_recursive_coefficients(hmath_context *context, const hmath_value *recursive_ls, hmath_value **out);
```

## `recursive_ls`

`machinelearning.recursive_ls(count, number, number2)`

 Initial inverse information delta I; forgetting factor in (0,1]. Input dimension excludes the automatically supplied intercept. 

```haskell
Int -> Double -> Double -> Either MathError RecursiveLS
```

```c
hmath_status hmath_ml_recursive_ls(hmath_context *context, const hmath_value *count, const hmath_value *number, const hmath_value *number2, hmath_value **out);
```

## `update_recursive_ls`

`machinelearning.update_recursive_ls(recursive_ls, values, number)`

Assimilate one feature row/response using the matrix inversion lemma. Reject lost definiteness.

```haskell
RecursiveLS -> [Double] -> Double -> Either MathError RecursiveLS
```

```c
hmath_status hmath_ml_update_recursive_ls(hmath_context *context, const hmath_value *recursive_ls, const hmath_value *values, const hmath_value *number, hmath_value **out);
```

