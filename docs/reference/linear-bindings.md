# Linear algebra bindings

All operations below call the original Haskell functions. Generic coefficients support standard Float/Double/Integer/Rational/Complex and bounded integral instances where the source constraints permit. No automatic dtype promotion occurs. RealFloat-only operations retain Float/Double; optional native LAPACK routines retain their original Double/ComplexDouble types and explicit unavailable-provider failures.

## `vector.vector`

Wrap a list as an immutable dynamic vector without numeric validation. The list order is preserved. Example: vectorValues (vector [1,2]) == [1,2].

Original signature: `[a] -> Vector a`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_vector(hmath_context *context, const hmath_value *prototype, const hmath_value *values1, hmath_value **out);
```

## `vector.vector_values`

Extract the immutable list of vector values in order; no shape conversion or numeric validation occurs.

Original signature: `Vector a -> [a]`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_vector_values(hmath_context *context, const hmath_value *prototype, const hmath_value *vector1, hmath_value **out);
```

## `vector.vector_dimension`

Return the number of coordinates in a dynamic vector. Empty vectors have dimension zero.

Original signature: `Vector a -> Int`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_vector_dimension(hmath_context *context, const hmath_value *prototype, const hmath_value *vector1, hmath_value **out);
```

## `vector.fixed_vector`

Construct a vector whose list length equals the type-level KnownNat size. A mismatch returns Left InvalidArgument. For example, fixedVector `3 requires exactly three values.

Original signature: `[a] -> Either MathError (FixedVector n a)`. Original constraints: `(KnownNat n)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_fixed_vector(hmath_context *context, const hmath_value *prototype, const hmath_value *index1, const hmath_value *values2, hmath_value **out);
```

## `vector.fixed_values`

Extract the ordered coordinates of a type-indexed vector; its length is the type-level size.

Original signature: `FixedVector n a -> [a]`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_fixed_values(hmath_context *context, const hmath_value *prototype, const hmath_value *fixed_vector1, hmath_value **out);
```

## `vector.sparse_vector`

Given nonnegative dimension and (zero-based index,value) entries, sum duplicate indices and remove explicit zeros. Reject out-of-range indices or negative dimension.

Original signature: `Int -> [(Int, a)] -> Either MathError (SparseVector a)`. Original constraints: `(Eq a, Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_sparse_vector(hmath_context *context, const hmath_value *prototype, const hmath_value *index1, const hmath_value *values2, hmath_value **out);
```

## `vector.sparse_vector_values`

Expand a sparse vector to a dense list of its declared dimension, filling absent entries with zero.

Original signature: `SparseVector a -> [a]`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_sparse_vector_values(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_vector1, hmath_value **out);
```

## `vector.vector_slice`

Given start, count, then vector, return the half-open slice [start,start+count). Reject negative or out-of-range bounds; an empty end slice is valid.

Original signature: `Int -> Int -> Vector a -> Either MathError (Vector a)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_vector_slice(hmath_context *context, const hmath_value *prototype, const hmath_value *index1, const hmath_value *index2, const hmath_value *vector3, hmath_value **out);
```

## `vector.vector_concat`

Concatenate a list of vectors in order. Return Left InvalidArgument if the combined dimension would overflow Int; an empty list gives an empty vector.

Original signature: `[Vector a] -> Either MathError (Vector a)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_vector_concat(hmath_context *context, const hmath_value *prototype, const hmath_value *values1, hmath_value **out);
```

## `vector.vector_add`

Add corresponding values of equally sized vectors, returning a new vector. Unequal dimensions return VectorLengthMismatch. Generic Num arithmetic is unchecked.

Original signature: `Vector a -> Vector a -> Either MathError (Vector a)`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_vector_add(hmath_context *context, const hmath_value *prototype, const hmath_value *vector1, const hmath_value *vector2, hmath_value **out);
```

## `vector.vector_subtract`

Subtract corresponding right-hand coordinates from left-hand coordinates. Unequal dimensions return VectorLengthMismatch; Num arithmetic is unchecked.

Original signature: `Vector a -> Vector a -> Either MathError (Vector a)`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_vector_subtract(hmath_context *context, const hmath_value *prototype, const hmath_value *vector1, const hmath_value *vector2, hmath_value **out);
```

## `vector.vector_scale`

Given scalar then vector, multiply every coordinate by the scalar. Return a new vector, retaining the original dimension and Num arithmetic behavior.

Original signature: `a -> Vector a -> Vector a`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_vector_scale(hmath_context *context, const hmath_value *prototype, const hmath_value *scalar1, const hmath_value *vector2, hmath_value **out);
```

## `vector.vector_dot`

Sum coordinatewise products of equally sized vectors. Empty vectors give zero; unequal dimensions return VectorLengthMismatch. No floating-point finiteness check is added.

Original signature: `Vector a -> Vector a -> Either MathError a`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_vector_dot(hmath_context *context, const hmath_value *prototype, const hmath_value *vector1, const hmath_value *vector2, hmath_value **out);
```

## `vector.cross`

Compute the right-handed cross product of two three-dimensional vectors. Any other dimension returns Left InvalidArgument.

Original signature: `Vector a -> Vector a -> Either MathError (Vector a)`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_cross(hmath_context *context, const hmath_value *prototype, const hmath_value *vector1, const hmath_value *vector2, hmath_value **out);
```

## `vector.outer`

Return the matrix of pairwise products a[i]*b[j], with shape (dimension a,dimension b). Matrix construction can return shape/count errors.

Original signature: `Vector a -> Vector a -> Either MathError (Matrix a)`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_outer(hmath_context *context, const hmath_value *prototype, const hmath_value *vector1, const hmath_value *vector2, hmath_value **out);
```

## `vector.triple`

Given a,b,c, compute scalar triple product a dot (b cross c). All three vectors must have dimension three; dimension errors propagate.

Original signature: `Vector a -> Vector a -> Vector a -> Either MathError a`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_triple(hmath_context *context, const hmath_value *prototype, const hmath_value *vector1, const hmath_value *vector2, const hmath_value *vector3, hmath_value **out);
```

## `vector.norm0`

Count nonzero coordinates, returning Int. This is the usual sparsity count rather than a norm satisfying homogeneity.

Original signature: `Vector a -> Int`. Original constraints: `(Eq a, Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_norm0(hmath_context *context, const hmath_value *prototype, const hmath_value *vector1, hmath_value **out);
```

## `vector.norm1`

Sum absolute coordinate values. Empty vector returns zero; arithmetic follows the chosen Num type.

Original signature: `Vector a -> a`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_norm1(hmath_context *context, const hmath_value *prototype, const hmath_value *vector1, hmath_value **out);
```

## `vector.norm2`

Compute Euclidean length using a scaled stable norm to reduce intermediate overflow/underflow. Empty vector returns zero; the result itself is not wrapped in Either.

Original signature: `Vector a -> a`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_norm2(hmath_context *context, const hmath_value *prototype, const hmath_value *vector1, hmath_value **out);
```

## `vector.norm_infinity`

Return maximum absolute coordinate, or zero for an empty vector. NaN coordinates propagate rather than being silently discarded.

Original signature: `Vector a -> a`. Original constraints: `(Ord a, Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_norm_infinity(hmath_context *context, const hmath_value *prototype, const hmath_value *vector1, hmath_value **out);
```

## `vector.norm_p`

Given positive exponent p then finite vector, compute the scaled p-norm. Positive infinity selects normInfinity. NaN/nonpositive p or non-finite coordinates fail; p\<1 is accepted as a quasi-norm.

Original signature: `a -> Vector a -> Either MathError a`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_norm_p(hmath_context *context, const hmath_value *prototype, const hmath_value *scalar1, const hmath_value *vector2, hmath_value **out);
```

## `vector.normalize_vector`

Return a unit-length vector in the same direction. Reject non-finite coordinates, zero norm, or non-finite resulting norm. Empty input is a zero vector and fails.

Original signature: `Vector a -> Either MathError (Vector a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_normalize_vector(hmath_context *context, const hmath_value *prototype, const hmath_value *vector1, hmath_value **out);
```

## `vector.project`

Given a then b, return the projection of a onto b. Dimensions must agree and b must have nonzero finite norm; non-finite input/result fails.

Original signature: `Vector a -> Vector a -> Either MathError (Vector a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_project(hmath_context *context, const hmath_value *prototype, const hmath_value *vector1, const hmath_value *vector2, hmath_value **out);
```

## `vector.reflect`

Given incident vector then surface normal, return incident minus twice its projection onto the normal. The normal is normalized internally; invalid dimensions, zero normal, or non-finite values fail.

Original signature: `Vector a -> Vector a -> Either MathError (Vector a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_reflect(hmath_context *context, const hmath_value *prototype, const hmath_value *vector1, const hmath_value *vector2, hmath_value **out);
```

## `vector.refract`

Given positive finite refractive-index ratio, incident vector, then normal, return the refracted unit-direction expression. Normalize both inputs; reject invalid dimensions, zero vectors, non-finite values, or total internal reflection.

Original signature: `a -> Vector a -> Vector a -> Either MathError (Vector a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_refract(hmath_context *context, const hmath_value *prototype, const hmath_value *scalar1, const hmath_value *vector2, const hmath_value *vector3, hmath_value **out);
```

## `vector.distance`

Return Euclidean distance between equal-sized finite vectors. Dimension mismatch and non-finite input/intermediate/result return Left MathError.

Original signature: `Vector a -> Vector a -> Either MathError a`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_distance(hmath_context *context, const hmath_value *prototype, const hmath_value *vector1, const hmath_value *vector2, hmath_value **out);
```

## `vector.cosine_similarity`

Return normalized dot product clamped to [-1,1]. Equal dimensions and nonzero finite vectors are required; validation errors propagate.

Original signature: `Vector a -> Vector a -> Either MathError a`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_cosine_similarity(hmath_context *context, const hmath_value *prototype, const hmath_value *vector1, const hmath_value *vector2, hmath_value **out);
```

## `vector.angle`

Return the angle in radians, acos of cosineSimilarity, between two nonzero finite equally sized vectors. Invalid dimensions or zero/non-finite vectors fail.

Original signature: `Vector a -> Vector a -> Either MathError a`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_angle(hmath_context *context, const hmath_value *prototype, const hmath_value *vector1, const hmath_value *vector2, hmath_value **out);
```

## `vector.gram_schmidt`

Given finite nonnegative relative tolerance then vectors, perform two-pass modified Gram-Schmidt, returning an orthonormal basis in input order. Reject unequal dimensions, zero/dependent vectors (RankDeficient), invalid tolerance, or non-finite data.

Original signature: `a -> [Vector a] -> Either MathError [Vector a]`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_vector_gram_schmidt(hmath_context *context, const hmath_value *prototype, const hmath_value *scalar1, const hmath_value *values2, hmath_value **out);
```

## `matrix_advanced.generate_matrix`

Given row count, column count, then zero-based (row,column) generator, construct a row-major matrix. Negative dimensions or Int-size element product overflow return Left MathError.

Original signature: `Int -> Int -> (Int -> Int -> a) -> Either MathError (Matrix a)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_generate_matrix(hmath_context *context, const hmath_value *prototype, const hmath_value *index1, const hmath_value *index2, const hmath_value *function3, hmath_value **out);
```

## `matrix_advanced.triangular_matrix`

Given lower flag then matrix, preserve entries on/below the diagonal if True, on/above if False, and zero the rest. Rectangular matrices are allowed; return checked construction result.

Original signature: `Bool -> Matrix a -> Either MathError (Matrix a)`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_triangular_matrix(hmath_context *context, const hmath_value *prototype, const hmath_value *flag1, const hmath_value *matrix2, hmath_value **out);
```

## `matrix_advanced.symmetric_matrix`

Return (A+transpose(A))/2 for a square matrix. Non-square input returns NonSquareMatrix; arithmetic follows Fractional.

Original signature: `Matrix a -> Either MathError (Matrix a)`. Original constraints: `(Fractional a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_symmetric_matrix(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, hmath_value **out);
```

## `matrix_advanced.hermitian_matrix`

Return (A+conjugateTranspose(A))/2 for a square complex matrix. Non-square input fails; this symmetrizes rather than merely asserting the original is Hermitian.

Original signature: `Matrix (Complex a) -> Either MathError (Matrix (Complex a))`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_hermitian_matrix(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, hmath_value **out);
```

## `matrix_advanced.permutation_matrix`

Given a permutation p of [0..n-1], construct n-by-n P with P[i,p[i]]=1. Duplicate, missing, or out-of-range indices return Left InvalidArgument.

Original signature: `[Int] -> Either MathError (Matrix a)`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_permutation_matrix(hmath_context *context, const hmath_value *prototype, const hmath_value *values1, hmath_value **out);
```

## `matrix_advanced.block_matrix`

Assemble a rectangular grid of matrix blocks. Require equal heights within each block row and equal widths within each block column. Ragged grids or total-size overflow fail; empty grids yield a 0-by-0 matrix.

Original signature: `[[Matrix a]] -> Either MathError (Matrix a)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_block_matrix(hmath_context *context, const hmath_value *prototype, const hmath_value *values1, hmath_value **out);
```

## `matrix_advanced.banded_matrix`

Given rows, columns, then (diagonal offset,values) pairs, construct a matrix with zeros elsewhere. Offset k means column-row=k. Each list must match that diagonal's length; duplicates add. Invalid dimensions/counts fail.

Original signature: `Int -> Int -> [(Int, [a])] -> Either MathError (Matrix a)`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_banded_matrix(hmath_context *context, const hmath_value *prototype, const hmath_value *index1, const hmath_value *index2, const hmath_value *values3, hmath_value **out);
```

## `matrix_advanced.conjugate_transpose`

Transpose a complex matrix and conjugate every entry, exchanging its row/column dimensions.

Original signature: `Matrix (Complex a) -> Matrix (Complex a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_conjugate_transpose(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, hmath_value **out);
```

## `matrix_advanced.zip_matrix_with`

Given elementwise function and two identically shaped matrices, apply it to corresponding entries and return a new matrix. Mismatched shapes return ShapeMismatch.

Original signature: `(a -> b -> c) -> Matrix a -> Matrix b -> Either MathError (Matrix c)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_zip_matrix_with(hmath_context *context, const hmath_value *prototype, const hmath_value *function1, const hmath_value *matrix2, const hmath_value *matrix3, hmath_value **out);
```

## `matrix_advanced.batched_multiply`

Multiply pairs of matrices from equally long lists, preserving batch order. Different batch lengths or any checked multiplication failure return Left MathError.

Original signature: `[Matrix a] -> [Matrix a] -> Either MathError [Matrix a]`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_batched_multiply(hmath_context *context, const hmath_value *prototype, const hmath_value *values1, const hmath_value *values2, hmath_value **out);
```

## `matrix_advanced.kronecker`

Return the block Kronecker product of matrices A and B, of shape (Arows*Brows,Acols*Bcols). Reject dimension/element-count overflow.

Original signature: `Matrix a -> Matrix a -> Either MathError (Matrix a)`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_kronecker(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, const hmath_value *matrix2, hmath_value **out);
```

## `matrix_advanced.khatri_rao`

Return columnwise Kronecker product, requiring equal column counts. Shape is (Arows*Brows,columns); mismatched columns or dimension overflow fail.

Original signature: `Matrix a -> Matrix a -> Either MathError (Matrix a)`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_khatri_rao(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, const hmath_value *matrix2, hmath_value **out);
```

## `matrix_advanced.matrix_power`

Given Integer exponent then square real matrix, compute power by squaring. Zero yields identity; negative exponent inverts first. Non-square/singular input or multiplication errors propagate.

Original signature: `Integer -> Matrix a -> Either MathError (Matrix a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_matrix_power(hmath_context *context, const hmath_value *prototype, const hmath_value *integer1, const hmath_value *matrix2, hmath_value **out);
```

## `matrix_advanced.trace`

Return sum of main diagonal of a square matrix; non-square input returns NonSquareMatrix. A 0-by-0 matrix has trace zero.

Original signature: `Matrix a -> Either MathError a`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_trace(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, hmath_value **out);
```

## `matrix_advanced.matrix_norm1`

Return maximum absolute column sum (induced one norm). Empty dimensions give zero; no finiteness check is added.

Original signature: `Matrix a -> a`. Original constraints: `(Ord a, Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_matrix_norm1(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, hmath_value **out);
```

## `matrix_advanced.matrix_norm_infinity`

Return maximum absolute row sum (induced infinity norm). A matrix with no elements gives zero.

Original signature: `Matrix a -> a`. Original constraints: `(Ord a, Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_matrix_norm_infinity(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, hmath_value **out);
```

## `matrix_advanced.frobenius_norm`

Return scaled Euclidean norm of all entries, reducing intermediate overflow; empty matrix norm is zero. No Either result is added.

Original signature: `Matrix a -> a`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_frobenius_norm(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, hmath_value **out);
```

## `matrix_advanced.spectral_norm`

Return largest singular value via SVD, or zero for an empty singular spectrum. Invalid input/backend decomposition failures return Left MathError.

Original signature: `Matrix Double -> Either MathError Double`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_spectral_norm(hmath_context *context, const hmath_value *matrix1, hmath_value **out);
```

## `matrix_advanced.matrix_rank`

Given finite nonnegative relative tolerance then matrix, count positive singular values whose ratio to the largest exceeds tolerance. Zero tolerance counts all positive singular values. Invalid tolerance or SVD failure propagates.

Original signature: `Double -> Matrix Double -> Either MathError Int`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_matrix_rank(hmath_context *context, const hmath_value *double1, const hmath_value *matrix2, hmath_value **out);
```

## `matrix_advanced.pseudoinverse`

Given relative singular-value tolerance then m-by-n matrix, return n-by-m Moore-Penrose pseudoinverse via thresholded SVD. Rectangular/rank-deficient inputs are supported; invalid tolerance or numeric/decomposition failures propagate.

Original signature: `Double -> Matrix Double -> Either MathError (Matrix Double)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_pseudoinverse(hmath_context *context, const hmath_value *double1, const hmath_value *matrix2, hmath_value **out);
```

## `matrix_advanced.condition_number`

Return largest/smallest singular-value ratio; singular matrices yield positive infinity, empty spectrum yields 1. Input/SVD failures return Left MathError.

Original signature: `Matrix Double -> Either MathError Double`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_condition_number(hmath_context *context, const hmath_value *matrix1, hmath_value **out);
```

## `matrix_advanced.column_space`

Given relative SVD rank tolerance then matrix, return columns of left singular vectors spanning its numerical column space. Invalid tolerance/decomposition errors propagate.

Original signature: `Double -> Matrix Double -> Either MathError (Matrix Double)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_column_space(hmath_context *context, const hmath_value *double1, const hmath_value *matrix2, hmath_value **out);
```

## `matrix_advanced.row_space`

Given relative rank tolerance then matrix, return a column basis for its row space by applying columnSpace to its transpose.

Original signature: `Double -> Matrix Double -> Either MathError (Matrix Double)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_row_space(hmath_context *context, const hmath_value *double1, const hmath_value *matrix2, hmath_value **out);
```

## `matrix_advanced.null_space`

Given relative singular-value tolerance then m-by-n matrix, return an n-by-(n-rank) basis for its numerical right null space using full SVD. Invalid tolerance/decomposition failures propagate.

Original signature: `Double -> Matrix Double -> Either MathError (Matrix Double)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_null_space(hmath_context *context, const hmath_value *double1, const hmath_value *matrix2, hmath_value **out);
```

## `matrix_advanced.change_coordinates`

Given source basis matrix, target square basis matrix, then source coordinate list, map to physical coordinates and solve in target basis. Shape mismatch, singular target, and checked solve errors propagate.

Original signature: `Matrix a -> Matrix a -> [a] -> Either MathError [a]`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_change_coordinates(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, const hmath_value *matrix2, const hmath_value *values3, hmath_value **out);
```

## `matrix_advanced.matrix_exp`

Given positive finite tolerance, positive iteration budget, then square finite matrix, approximate exp(A) by scaling, Taylor series and squaring. Return NonConvergence on exhausted series budget; input/shape/numerical failures propagate.

Original signature: `a -> Int -> Matrix a -> Either MathError (Matrix a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_matrix_exp(hmath_context *context, const hmath_value *prototype, const hmath_value *scalar1, const hmath_value *index2, const hmath_value *matrix3, hmath_value **out);
```

## `matrix_advanced.matrix_log`

Compute principal real matrix logarithm of a symmetric positive-definite Double matrix using symmetric eigendecomposition. Reject non-square/asymmetric matrices, nonpositive spectrum, non-real decomposition, or numeric failure.

Original signature: `Matrix Double -> Either MathError (Matrix Double)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_matrix_log(hmath_context *context, const hmath_value *matrix1, hmath_value **out);
```

## `matrix_advanced.matrix_sqrt`

Compute symmetric positive-semidefinite matrix square root by spectral decomposition; tolerate eigenvalues down to -1e-12 and clamp them to zero. Invalid shape/symmetry/spectrum or decomposition failure returns Left MathError.

Original signature: `Matrix Double -> Either MathError (Matrix Double)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_matrix_sqrt(hmath_context *context, const hmath_value *matrix1, hmath_value **out);
```

## `matrix_advanced.polar`

Return (U,P) from SVD so A=U*P, with P positive semidefinite; rectangular input uses the thin polar factors. Validation/decomposition/multiplication errors propagate.

Original signature: `Matrix Double -> Either MathError (Matrix Double, Matrix Double)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_polar(hmath_context *context, const hmath_value *matrix1, hmath_value **out);
```

## `matrix_advanced.complex_pseudoinverse`

Complex128 Moore-Penrose pseudoinverse, thresholded relative to the largest singular value. Both rectangular and rank-deficient inputs are supported.

Original signature: `Double -> Matrix (Complex Double) -> Either MathError (Matrix (Complex Double))`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_complex_pseudoinverse(hmath_context *context, const hmath_value *double1, const hmath_value *matrix2, hmath_value **out);
```

## `matrix_advanced.matrix_sqrt_general`

Principal square root for invertible real matrices whose spectra avoid the nonpositive real axis. This nonsymmetric reference method uses scaled Denman-Beavers iteration with private inverse solves. The budget bounds the number of coupled iterations; failure to meet the reconstruction tolerance returns NonConvergence. Ill-conditioned inverse steps may report a LU error. The existing matrixSqrt additionally handles symmetric singular PSD inputs.

Original signature: `Double -> Int -> Matrix Double -> Either MathError (Matrix Double)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_matrix_sqrt_general(hmath_context *context, const hmath_value *double1, const hmath_value *index2, const hmath_value *matrix3, hmath_value **out);
```

## `matrix_advanced.matrix_log_general`

Real principal matrix logarithm on the same spectral domain as matrixSqrtGeneral. Inverse scaling by successive principal square roots makes the Mercator series converge in matrix 1-norm. The budget bounds each phase: root reductions, each inner Denman-Beavers solve, series terms, and the final exponential reconstruction check. There is no unbounded convergence loop.

Original signature: `Double -> Int -> Matrix Double -> Either MathError (Matrix Double)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_matrix_advanced_matrix_log_general(hmath_context *context, const hmath_value *double1, const hmath_value *index2, const hmath_value *matrix3, hmath_value **out);
```

## `decomposition.gaussian_elimination`

Given finite nonnegative relative tolerance then finite matrix, return normalized row-echelon form and zero-based pivot columns. Partial row pivoting skips pivots below tolerance times the global entry scale. Invalid tolerance/non-finite arithmetic fails.

Original signature: `a -> Matrix a -> Either MathError (Matrix a, [Int])`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_gaussian_elimination(hmath_context *context, const hmath_value *prototype, const hmath_value *scalar1, const hmath_value *matrix2, hmath_value **out);
```

## `decomposition.gauss_jordan`

Given relative tolerance then finite matrix, return reduced row-echelon form and zero-based pivot columns using row pivoting. Invalid tolerance/non-finite arithmetic fails.

Original signature: `a -> Matrix a -> Either MathError (Matrix a, [Int])`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_gauss_jordan(hmath_context *context, const hmath_value *prototype, const hmath_value *scalar1, const hmath_value *matrix2, hmath_value **out);
```

## `decomposition.cholesky`

Factor a finite symmetric positive-definite matrix as L*transpose(L), returning lower-triangular L. Non-square/asymmetric/non-finite input or a nonpositive diagonal pivot returns Left MathError.

Original signature: `Matrix a -> Either MathError (Matrix a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_cholesky(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, hmath_value **out);
```

## `decomposition.ldlt`

Factor a finite symmetric matrix as L*diag(d)*transpose(L), returning unit lower L and diagonal list d. This unpivoted method requires nonzero scalar pivots; it can reject invertible indefinite matrices needing block pivots.

Original signature: `Matrix a -> Either MathError (Matrix a, [a])`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_ldlt(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, hmath_value **out);
```

## `decomposition.givens_qr`

Factor finite m-by-n matrix as Q*R using Givens rotations, returning square m-by-m Q and m-by-n R without column pivoting. Non-finite input/intermediate results fail.

Original signature: `Matrix a -> Either MathError (Matrix a, Matrix a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_givens_qr(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, hmath_value **out);
```

## `decomposition.bidiagonalize`

Reduce a finite rectangular matrix to bidiagonal form with orthogonal factors, returning Bidiagonal fields. Input/numeric validation errors propagate; inspect the factor types and module reconstruction example.

Original signature: `Matrix a -> Either MathError (Bidiagonal a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_bidiagonalize(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, hmath_value **out);
```

## `decomposition.tridiagonalize`

Reduce a symmetric finite square matrix to `(Q,T)`, satisfying `A = Q * T * transpose Q` with tridiagonal `T`. Non-square/asymmetric input or numerical failure returns Left MathError.

Original signature: `Matrix Double -> Either MathError (Matrix Double, Matrix Double)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_tridiagonalize(hmath_context *context, const hmath_value *matrix1, hmath_value **out);
```

## `decomposition.power_iteration`

Given positive finite tolerance,positive budget,square finite matrix,then nonzero starting vector, estimate a dominant eigenpair. Return Iteration with value/vector/residual/count; invalid dimensions/options, non-finite arithmetic or exhausted budget fails.

Original signature: `a -> Int -> Matrix a -> [a] -> Either MathError (Iteration a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_power_iteration(hmath_context *context, const hmath_value *prototype, const hmath_value *scalar1, const hmath_value *index2, const hmath_value *matrix3, const hmath_value *values4, hmath_value **out);
```

## `decomposition.inverse_iteration`

Given tolerance,budget,shift,square matrix,then starting vector, estimate an eigenpair near shift by repeated shifted solves. Require valid finite inputs and nonzero start; singular shifted systems or convergence/numerical failures return Left MathError.

Original signature: `a -> Int -> a -> Matrix a -> [a] -> Either MathError (Iteration a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_inverse_iteration(hmath_context *context, const hmath_value *prototype, const hmath_value *scalar1, const hmath_value *index2, const hmath_value *scalar3, const hmath_value *matrix4, const hmath_value *values5, hmath_value **out);
```

## `decomposition.rayleigh_iteration`

Given tolerance,budget,square matrix,then nonzero initial vector, refine an eigenpair with Rayleigh-quotient shifts. Shape/options, singular shifted solves or convergence/numerical failures return Left MathError.

Original signature: `a -> Int -> Matrix a -> [a] -> Either MathError (Iteration a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_rayleigh_iteration(hmath_context *context, const hmath_value *prototype, const hmath_value *scalar1, const hmath_value *index2, const hmath_value *matrix3, const hmath_value *values4, hmath_value **out);
```

## `decomposition.arnoldi`

Given positive finite tolerance,requested basis size,square matrix,then nonzero initial vector, build Arnoldi basis/projection. Require 1\<=requested\<=matrix order. Invalid input or numerical failures return Left MathError; exact Krylov breakdown terminates the basis.

Original signature: `a -> Int -> Matrix a -> [a] -> Either MathError (Arnoldi a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_arnoldi(hmath_context *context, const hmath_value *prototype, const hmath_value *scalar1, const hmath_value *index2, const hmath_value *matrix3, const hmath_value *values4, hmath_value **out);
```

## `decomposition.lanczos`

Symmetric Lanczos with the three-term recurrence and two full reorthogonalization passes. Small correction coefficients are retained in H so the projection residual remains meaningful after floating-point rounding.

Original signature: `a -> Int -> Matrix a -> [a] -> Either MathError (Arnoldi a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_lanczos(hmath_context *context, const hmath_value *prototype, const hmath_value *scalar1, const hmath_value *index2, const hmath_value *matrix3, const hmath_value *values4, hmath_value **out);
```

## `decomposition.qr_iteration`

Given positive finite tolerance,positive budget,then finite square matrix, iterate QR to return `(Q,T)`: accumulated orthogonal vectors and the resulting iterate. Invalid options/shape or failure to converge within budget returns Left MathError.

Original signature: `a -> Int -> Matrix a -> Either MathError (Matrix a, Matrix a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_qr_iteration(hmath_context *context, const hmath_value *prototype, const hmath_value *scalar1, const hmath_value *index2, const hmath_value *matrix3, hmath_value **out);
```

## `decomposition.jordan_chains`

Verify supplied Jordan chains against A and lambda and construct J and P. Computing a Jordan structure from floating input is ill posed; the caller supplies chain vectors ordered eigenvector first. A P = P J is checked. This API never pretends a Schur form is a Jordan form.

Original signature: `a -> Matrix a -> [(a, [[a]])] -> Either MathError (Matrix a, Matrix a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_jordan_chains(hmath_context *context, const hmath_value *prototype, const hmath_value *scalar1, const hmath_value *matrix2, const hmath_value *values3, hmath_value **out);
```

## `decomposition.jordan_form`

Exact Jordan construction over Rational with a caller-provided complete set of distinct rational eigenvalues (multiplicities are inferred). Unlike floating Jordan algorithms this never uses a tolerance to decide structure. Nullspaces of successive (A-lambda I) powers construct generalized chains. An incomplete/nonrational spectrum is rejected rather than approximated.

Original signature: `Matrix Rational -> [Rational] -> Either MathError (Matrix Rational, Matrix Rational)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_jordan_form(hmath_context *context, const hmath_value *matrix1, const hmath_value *values2, hmath_value **out);
```

## `decomposition.bidiagonal_u`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Bidiagonal -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_bidiagonal_u(hmath_context *context, const hmath_value *prototype, const hmath_value *bidiagonal1, hmath_value **out);
```

## `decomposition.bidiagonal_b`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Bidiagonal -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_bidiagonal_b(hmath_context *context, const hmath_value *prototype, const hmath_value *bidiagonal1, hmath_value **out);
```

## `decomposition.bidiagonal_v`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Bidiagonal -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_bidiagonal_v(hmath_context *context, const hmath_value *prototype, const hmath_value *bidiagonal1, hmath_value **out);
```

## `decomposition.Bidiagonal`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_decomposition_new_bidiagonal(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, const hmath_value *matrix2, const hmath_value *matrix3, hmath_value **out);
```

## `decomposition.iteration_value`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Iteration -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_iteration_value(hmath_context *context, const hmath_value *prototype, const hmath_value *iteration1, hmath_value **out);
```

## `decomposition.iteration_vector`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Iteration -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_iteration_vector(hmath_context *context, const hmath_value *prototype, const hmath_value *iteration1, hmath_value **out);
```

## `decomposition.iteration_residual`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Iteration -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_iteration_residual(hmath_context *context, const hmath_value *prototype, const hmath_value *iteration1, hmath_value **out);
```

## `decomposition.iteration_count`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Iteration -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_iteration_count(hmath_context *context, const hmath_value *prototype, const hmath_value *iteration1, hmath_value **out);
```

## `decomposition.Iteration`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_decomposition_new_iteration(hmath_context *context, const hmath_value *prototype, const hmath_value *scalar1, const hmath_value *values2, const hmath_value *scalar3, const hmath_value *index4, hmath_value **out);
```

## `decomposition.arnoldi_basis`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Arnoldi -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_arnoldi_basis(hmath_context *context, const hmath_value *prototype, const hmath_value *arnoldi1, hmath_value **out);
```

## `decomposition.arnoldi_hessenberg`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Arnoldi -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_decomposition_arnoldi_hessenberg(hmath_context *context, const hmath_value *prototype, const hmath_value *arnoldi1, hmath_value **out);
```

## `decomposition.Arnoldi`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_decomposition_new_arnoldi(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, const hmath_value *matrix2, hmath_value **out);
```

## `iterative.default_iterative_options`

1000 iterations, zero absolute tolerance and relative tolerance 1e-10.

Original signature: `IterativeOptions a`. Original constraints: `(Fractional a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_default_iterative_options(hmath_context *context, const hmath_value *prototype, hmath_value **out);
```

## `iterative.apply_preconditioner`

Apply an inverse action; wrong vector lengths and nonfinite values fail.

Original signature: `Preconditioner a -> [a] -> Either MathError [a]`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_apply_preconditioner(hmath_context *context, const hmath_value *prototype, const hmath_value *preconditioner1, const hmath_value *values2, hmath_value **out);
```

## `iterative.identity_preconditioner`

Identity inverse action in a nonnegative dimension.

Original signature: `Int -> Either MathError (Preconditioner a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_identity_preconditioner(hmath_context *context, const hmath_value *prototype, const hmath_value *index1, hmath_value **out);
```

## `iterative.jacobi_preconditioner`

Inverse diagonal preconditioner. Every diagonal entry must be nonzero.

Original signature: `Matrix a -> Either MathError (Preconditioner a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_jacobi_preconditioner(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, hmath_value **out);
```

## `iterative.block_jacobi_preconditioner`

Block Jacobi from contiguous positive block sizes summing to the dimension. Each diagonal block is factored with pivoted LU; off-block entries are ignored.

Original signature: `[Int] -> Matrix a -> Either MathError (Preconditioner a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_block_jacobi_preconditioner(hmath_context *context, const hmath_value *prototype, const hmath_value *values1, const hmath_value *matrix2, hmath_value **out);
```

## `iterative.ilu0_preconditioner`

Incomplete LU with zero fill and no pivoting. The exact nonzero pattern of A is retained, diagonal pivots are mandatory, and zero pivots fail explicitly.

Original signature: `Matrix a -> Either MathError (Preconditioner a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_ilu0_preconditioner(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, hmath_value **out);
```

## `iterative.ic0_preconditioner`

Incomplete Cholesky with zero fill for a symmetric positive-definite input. Dropping can itself cause a nonpositive pivot; that reports NotPositiveDefinite.

Original signature: `Matrix a -> Either MathError (Preconditioner a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_ic0_preconditioner(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, hmath_value **out);
```

## `iterative.conjugate_gradient`

Conjugate gradient for symmetric positive-definite matrices. Symmetry is checked; nonpositive Krylov curvature rejects indefinite matrices encountered.

Original signature: `IterativeOptions a -> Matrix a -> [a] -> [a] -> Either MathError (IterativeResult a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_conjugate_gradient(hmath_context *context, const hmath_value *prototype, const hmath_value *iterative_options1, const hmath_value *matrix2, const hmath_value *values3, const hmath_value *values4, hmath_value **out);
```

## `iterative.preconditioned_cg`

Preconditioned conjugate gradient. The inverse action must be SPD; a nonpositive r^T M^-1 r or search curvature is reported as a domain error.

Original signature: `IterativeOptions a -> Preconditioner a -> Matrix a -> [a] -> [a] -> Either MathError (IterativeResult a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_preconditioned_cg(hmath_context *context, const hmath_value *prototype, const hmath_value *iterative_options1, const hmath_value *preconditioner2, const hmath_value *matrix3, const hmath_value *values4, const hmath_value *values5, hmath_value **out);
```

## `iterative.gmres`

Restarted GMRES with modified Gram--Schmidt Arnoldi and a second orthogonalization pass. Restart length must be positive; total iterations are bounded by options. Each projected least-squares problem is solved by QR.

Original signature: `IterativeOptions a -> Int -> Matrix a -> [a] -> [a] -> Either MathError (IterativeResult a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_gmres(hmath_context *context, const hmath_value *prototype, const hmath_value *iterative_options1, const hmath_value *index2, const hmath_value *matrix3, const hmath_value *values4, const hmath_value *values5, hmath_value **out);
```

## `iterative.minres`

Minimum residual on the symmetric Lanczos Krylov space, including indefinite systems. A full tridiagonal projected least-squares problem is solved by QR each iteration (the mathematical MINRES objective, without short recurrences).

Original signature: `IterativeOptions a -> Matrix a -> [a] -> [a] -> Either MathError (IterativeResult a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_minres(hmath_context *context, const hmath_value *prototype, const hmath_value *iterative_options1, const hmath_value *matrix2, const hmath_value *values3, const hmath_value *values4, hmath_value **out);
```

## `iterative.bicg`

Bi-conjugate gradient for nonsymmetric square matrices; the initial shadow residual equals the initial residual. Biorthogonality breakdown fails explicitly.

Original signature: `IterativeOptions a -> Matrix a -> [a] -> [a] -> Either MathError (IterativeResult a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_bicg(hmath_context *context, const hmath_value *prototype, const hmath_value *iterative_options1, const hmath_value *matrix2, const hmath_value *values3, const hmath_value *values4, hmath_value **out);
```

## `iterative.bicgstab`

Stabilized BiCG with a fixed initial shadow residual and a minimal-residual omega step. Zero projection/omega denominators return explicit breakdown errors.

Original signature: `IterativeOptions a -> Matrix a -> [a] -> [a] -> Either MathError (IterativeResult a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_bicgstab(hmath_context *context, const hmath_value *prototype, const hmath_value *iterative_options1, const hmath_value *matrix2, const hmath_value *values3, const hmath_value *values4, hmath_value **out);
```

## `iterative.lsqr`

LSQR by Golub--Kahan bidiagonalization and plane-rotation recurrences. Rectangular and rank-deficient systems are supported. The least-squares stopping test uses the original normal residual as well as the true residual.

Original signature: `IterativeOptions a -> Matrix a -> [a] -> [a] -> Either MathError (IterativeResult a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_lsqr(hmath_context *context, const hmath_value *prototype, const hmath_value *iterative_options1, const hmath_value *matrix2, const hmath_value *values3, const hmath_value *values4, hmath_value **out);
```

## `iterative.lsmr`

LSMR's minimum-normal-residual Krylov objective using explicit Golub--Kahan bases and QR on the projected tridiagonal normal operator. A^T A is never formed. This full-basis reference version uses more storage than short-recurrence implementations; it minimizes ||A^T(b-Ax)|| over the generated Krylov space.

Original signature: `IterativeOptions a -> Matrix a -> [a] -> [a] -> Either MathError (IterativeResult a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_lsmr(hmath_context *context, const hmath_value *prototype, const hmath_value *iterative_options1, const hmath_value *matrix2, const hmath_value *values3, const hmath_value *values4, hmath_value **out);
```

## `iterative.jacobi_solve`

Simultaneous Jacobi stationary iteration. Convergence requires an appropriate splitting (for example strict diagonal dominance); it is not assumed.

Original signature: `IterativeOptions a -> Matrix a -> [a] -> [a] -> Either MathError (IterativeResult a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_jacobi_solve(hmath_context *context, const hmath_value *prototype, const hmath_value *iterative_options1, const hmath_value *matrix2, const hmath_value *values3, const hmath_value *values4, hmath_value **out);
```

## `iterative.gauss_seidel_solve`

Forward Gauss--Seidel stationary iteration.

Original signature: `IterativeOptions a -> Matrix a -> [a] -> [a] -> Either MathError (IterativeResult a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_gauss_seidel_solve(hmath_context *context, const hmath_value *prototype, const hmath_value *iterative_options1, const hmath_value *matrix2, const hmath_value *values3, const hmath_value *values4, hmath_value **out);
```

## `iterative.sor_solve`

Successive over-relaxation, requiring a finite relaxation 0<omega<2.

Original signature: `IterativeOptions a -> a -> Matrix a -> [a] -> [a] -> Either MathError (IterativeResult a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_sor_solve(hmath_context *context, const hmath_value *prototype, const hmath_value *iterative_options1, const hmath_value *scalar2, const hmath_value *matrix3, const hmath_value *values4, const hmath_value *values5, hmath_value **out);
```

## `iterative.iterative_refinement`

Residual-correction refinement using a reusable partial-pivoted LU. Residuals and corrections use the scalar type's precision. This does not claim mixed-precision accuracy; callers may provide an initial guess from any solver.

Original signature: `IterativeOptions a -> Matrix a -> [a] -> [a] -> Either MathError (IterativeResult a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_iterative_refinement(hmath_context *context, const hmath_value *prototype, const hmath_value *iterative_options1, const hmath_value *matrix2, const hmath_value *values3, const hmath_value *values4, hmath_value **out);
```

## `iterative.absolute_tolerance`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `IterativeOptions -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_absolute_tolerance(hmath_context *context, const hmath_value *prototype, const hmath_value *iterative_options1, hmath_value **out);
```

## `iterative.relative_tolerance`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `IterativeOptions -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_relative_tolerance(hmath_context *context, const hmath_value *prototype, const hmath_value *iterative_options1, hmath_value **out);
```

## `iterative.maximum_iterations`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `IterativeOptions -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_maximum_iterations(hmath_context *context, const hmath_value *prototype, const hmath_value *iterative_options1, hmath_value **out);
```

## `iterative.IterativeOptions`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_iterative_new_iterative_options(hmath_context *context, const hmath_value *prototype, const hmath_value *scalar1, const hmath_value *scalar2, const hmath_value *index3, hmath_value **out);
```

## `iterative.iterative_solution`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `IterativeResult -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_iterative_solution(hmath_context *context, const hmath_value *prototype, const hmath_value *iterative_result1, hmath_value **out);
```

## `iterative.iterative_iterations`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `IterativeResult -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_iterative_iterations(hmath_context *context, const hmath_value *prototype, const hmath_value *iterative_result1, hmath_value **out);
```

## `iterative.iterative_residual_norm`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `IterativeResult -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_iterative_residual_norm(hmath_context *context, const hmath_value *prototype, const hmath_value *iterative_result1, hmath_value **out);
```

## `iterative.iterative_normal_residual_norm`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `IterativeResult -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_iterative_iterative_normal_residual_norm(hmath_context *context, const hmath_value *prototype, const hmath_value *iterative_result1, hmath_value **out);
```

## `iterative.IterativeResult`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_iterative_new_iterative_result(hmath_context *context, const hmath_value *prototype, const hmath_value *values1, const hmath_value *index2, const hmath_value *scalar3, const hmath_value *scalar4, hmath_value **out);
```

## `lapack.svd`

Compute thin real SVD A=U*diag(s)*VT via LAPACK, with descending nonnegative singular values and k=min(m,n). Return m-by-k U and k-by-n VT. Invalid input, unavailable backend, allocation bounds or LAPACK failure returns Left MathError.

Original signature: `Matrix Double -> Either MathError SVD`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_svd(hmath_context *context, const hmath_value *matrix1, hmath_value **out);
```

## `lapack.full_svd`

Full square U and V^T, including null-space completion.

Original signature: `Matrix Double -> Either MathError SVD`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_full_svd(hmath_context *context, const hmath_value *matrix1, hmath_value **out);
```

## `lapack.truncated_svd`

Given retained rank k then real matrix, compute thin SVD and retain its first k components. Reject k outside the available rank dimensions; decomposition failures propagate.

Original signature: `Int -> Matrix Double -> Either MathError SVD`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_truncated_svd(hmath_context *context, const hmath_value *index1, const hmath_value *matrix2, hmath_value **out);
```

## `lapack.randomized_svd`

Randomized range finder with an explicit seed, oversampling, and power iterations, followed by a small deterministic SVD. The Gaussian test matrix uses Box-Muller on a local LCG, so results are reproducible, not cryptographic.

Original signature: `Int -> Int -> Int -> Integer -> Matrix Double -> Either MathError SVD`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_randomized_svd(hmath_context *context, const hmath_value *index1, const hmath_value *index2, const hmath_value *index3, const hmath_value *integer4, const hmath_value *matrix5, hmath_value **out);
```

## `lapack.eigen`

Compute complex eigenvalues and right eigenvectors of a finite real square matrix via LAPACK. Complex-conjugate pairs are decoded into complex columns. Invalid shape/backend/numeric failures return Left MathError.

Original signature: `Matrix Double -> Either MathError Eigen`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_eigen(hmath_context *context, const hmath_value *matrix1, hmath_value **out);
```

## `lapack.symmetric_eigen`

Real symmetric eigensolver with orthonormal columns, sorted ascending.

Original signature: `Matrix Double -> Either MathError Eigen`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_symmetric_eigen(hmath_context *context, const hmath_value *matrix1, hmath_value **out);
```

## `lapack.generalized_eigen`

Given equally sized square matrices A,B, compute generalized alpha/beta eigenvalue representation and right eigenvectors. Retain alpha/beta to represent infinite eigenvalues safely; invalid input or LAPACK failure propagates.

Original signature: `Matrix Double -> Matrix Double -> Either MathError GeneralizedEigen`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_generalized_eigen(hmath_context *context, const hmath_value *matrix1, const hmath_value *matrix2, hmath_value **out);
```

## `lapack.schur`

Compute real Schur form A=Q*T*transpose(Q), returning orthogonal Q, quasi-upper-triangular T and complex eigenvalues. Require finite square input and available LAPACK; failures return Left MathError.

Original signature: `Matrix Double -> Either MathError Schur`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_schur(hmath_context *context, const hmath_value *matrix1, hmath_value **out);
```

## `lapack.qz`

Compute generalized real Schur factors for a finite square matrix pair A,B, retaining Q,Z,S,T and alpha/beta eigenvalues. Shape/backend/LAPACK errors return Left MathError.

Original signature: `Matrix Double -> Matrix Double -> Either MathError QZ`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_qz(hmath_context *context, const hmath_value *matrix1, const hmath_value *matrix2, hmath_value **out);
```

## `lapack.hessenberg`

Reduce finite real square A to upper Hessenberg H with orthogonal Q, satisfying A=Q*H*transpose(Q). Invalid shape or backend/decomposition failures propagate.

Original signature: `Matrix Double -> Either MathError Hessenberg`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_hessenberg(hmath_context *context, const hmath_value *matrix1, hmath_value **out);
```

## `lapack.balance`

Balance a real square matrix by diagonal scaling, returning the balanced matrix and scales needed to interpret its basis. Invalid finite-input/shape checks or LAPACK failures return Left MathError.

Original signature: `Matrix Double -> Either MathError Balance`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_balance(hmath_context *context, const hmath_value *matrix1, hmath_value **out);
```

## `lapack.complex_svd`

Compute thin complex SVD with conjugate-transposed right factor VT and real nonnegative singular values. Require finite complex entries and available LAPACK. Invalid storage sizes/backend/decomposition fails.

Original signature: `Matrix (Complex Double) -> Either MathError ComplexSVD`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_complex_svd(hmath_context *context, const hmath_value *matrix1, hmath_value **out);
```

## `lapack.complex_eigen`

Compute complex eigenvalues and right eigenvectors of a finite complex square matrix via LAPACK. Invalid shape, backend availability, bounds or decomposition errors return Left MathError.

Original signature: `Matrix (Complex Double) -> Either MathError Eigen`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_complex_eigen(hmath_context *context, const hmath_value *matrix1, hmath_value **out);
```

## `lapack.svd_u`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `SVD -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_svd_u(hmath_context *context, const hmath_value *svd1, hmath_value **out);
```

## `lapack.singular_values`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `SVD -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_singular_values(hmath_context *context, const hmath_value *svd1, hmath_value **out);
```

## `lapack.svd_vt`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `SVD -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_svd_vt(hmath_context *context, const hmath_value *svd1, hmath_value **out);
```

## `lapack.SVD`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_lapack_new_svd(hmath_context *context, const hmath_value *matrix1, const hmath_value *values2, const hmath_value *matrix3, hmath_value **out);
```

## `lapack.eigenvalues`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Eigen -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_eigenvalues(hmath_context *context, const hmath_value *eigen1, hmath_value **out);
```

## `lapack.eigenvectors`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Eigen -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_eigenvectors(hmath_context *context, const hmath_value *eigen1, hmath_value **out);
```

## `lapack.Eigen`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_lapack_new_eigen(hmath_context *context, const hmath_value *values1, const hmath_value *matrix2, hmath_value **out);
```

## `lapack.eigen_alpha`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `GeneralizedEigen -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_eigen_alpha(hmath_context *context, const hmath_value *generalized_eigen1, hmath_value **out);
```

## `lapack.eigen_beta`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `GeneralizedEigen -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_eigen_beta(hmath_context *context, const hmath_value *generalized_eigen1, hmath_value **out);
```

## `lapack.generalized_eigenvectors`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `GeneralizedEigen -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_generalized_eigenvectors(hmath_context *context, const hmath_value *generalized_eigen1, hmath_value **out);
```

## `lapack.GeneralizedEigen`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_lapack_new_generalized_eigen(hmath_context *context, const hmath_value *values1, const hmath_value *values2, const hmath_value *matrix3, hmath_value **out);
```

## `lapack.schur_q`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Schur -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_schur_q(hmath_context *context, const hmath_value *schur1, hmath_value **out);
```

## `lapack.schur_t`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Schur -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_schur_t(hmath_context *context, const hmath_value *schur1, hmath_value **out);
```

## `lapack.schur_eigenvalues`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Schur -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_schur_eigenvalues(hmath_context *context, const hmath_value *schur1, hmath_value **out);
```

## `lapack.Schur`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_lapack_new_schur(hmath_context *context, const hmath_value *matrix1, const hmath_value *matrix2, const hmath_value *values3, hmath_value **out);
```

## `lapack.qz_q`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `QZ -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_qz_q(hmath_context *context, const hmath_value *qz1, hmath_value **out);
```

## `lapack.qz_z`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `QZ -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_qz_z(hmath_context *context, const hmath_value *qz1, hmath_value **out);
```

## `lapack.qz_s`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `QZ -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_qz_s(hmath_context *context, const hmath_value *qz1, hmath_value **out);
```

## `lapack.qz_t`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `QZ -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_qz_t(hmath_context *context, const hmath_value *qz1, hmath_value **out);
```

## `lapack.qz_alpha`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `QZ -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_qz_alpha(hmath_context *context, const hmath_value *qz1, hmath_value **out);
```

## `lapack.qz_beta`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `QZ -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_qz_beta(hmath_context *context, const hmath_value *qz1, hmath_value **out);
```

## `lapack.QZ`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_lapack_new_qz(hmath_context *context, const hmath_value *matrix1, const hmath_value *matrix2, const hmath_value *matrix3, const hmath_value *matrix4, const hmath_value *values5, const hmath_value *values6, hmath_value **out);
```

## `lapack.hessenberg_q`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Hessenberg -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_hessenberg_q(hmath_context *context, const hmath_value *hessenberg1, hmath_value **out);
```

## `lapack.hessenberg_h`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Hessenberg -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_hessenberg_h(hmath_context *context, const hmath_value *hessenberg1, hmath_value **out);
```

## `lapack.Hessenberg`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_lapack_new_hessenberg(hmath_context *context, const hmath_value *matrix1, const hmath_value *matrix2, hmath_value **out);
```

## `lapack.balanced_matrix`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Balance -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_balanced_matrix(hmath_context *context, const hmath_value *balance1, hmath_value **out);
```

## `lapack.balance_scales`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Balance -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_balance_scales(hmath_context *context, const hmath_value *balance1, hmath_value **out);
```

## `lapack.Balance`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_lapack_new_balance(hmath_context *context, const hmath_value *matrix1, const hmath_value *values2, hmath_value **out);
```

## `lapack.complex_u`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `ComplexSVD -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_complex_u(hmath_context *context, const hmath_value *complex_svd1, hmath_value **out);
```

## `lapack.complex_singular_values`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `ComplexSVD -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_complex_singular_values(hmath_context *context, const hmath_value *complex_svd1, hmath_value **out);
```

## `lapack.complex_vt`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `ComplexSVD -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_lapack_complex_vt(hmath_context *context, const hmath_value *complex_svd1, hmath_value **out);
```

## `lapack.ComplexSVD`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_lapack_new_complex_svd(hmath_context *context, const hmath_value *matrix1, const hmath_value *values2, const hmath_value *matrix3, hmath_value **out);
```

## `sparse.sparse`

Given rows,columns,then (row,column,value) entries, validate coordinates, sum duplicates and remove explicit zeros. Return canonical ordered sparse storage; invalid shape/indices or size overflow fail.

Original signature: `Int -> Int -> [(Int, Int, a)] -> Either MathError (Sparse a)`. Original constraints: `(Eq a, Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse(hmath_context *context, const hmath_value *prototype, const hmath_value *index1, const hmath_value *index2, const hmath_value *values3, hmath_value **out);
```

## `sparse.sparse_shape`

Return declared (row count,column count), including empty dimensions.

Original signature: `Sparse a -> (Int, Int)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_shape(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse1, hmath_value **out);
```

## `sparse.sparse_entries`

Return canonical nonzero (row,column,value) triples in ascending coordinate order.

Original signature: `Sparse a -> [(Int, Int, a)]`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_entries(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse1, hmath_value **out);
```

## `sparse.nonzeros`

Return stored nonzero count after duplicate coalescing and zero removal.

Original signature: `Sparse a -> Int`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_nonzeros(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse1, hmath_value **out);
```

## `sparse.from_format`

Validate COO/CSR/CSC/DIA/BSR/ELLPACK dimensions, pointers/indices and values, then construct canonical sparse storage. Invalid layout or coordinates return Left MathError.

Original signature: `SparseFormat a -> Either MathError (Sparse a)`. Original constraints: `(Eq a, Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_from_format(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_format1, hmath_value **out);
```

## `sparse.to_coo`

Return coordinate-list SparseFormat with explicit row/column/value arrays, preserving canonical nonzeros.

Original signature: `Sparse a -> SparseFormat a`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_to_coo(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse1, hmath_value **out);
```

## `sparse.to_csr`

Return compressed sparse row format with row offsets, column indices and nonzero values.

Original signature: `Sparse a -> SparseFormat a`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_to_csr(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse1, hmath_value **out);
```

## `sparse.to_csc`

Return compressed sparse column format with column offsets, row indices and values.

Original signature: `Sparse a -> SparseFormat a`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_to_csc(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse1, hmath_value **out);
```

## `sparse.to_dia`

Return diagonal sparse format; absent positions in represented diagonals are padded with zero.

Original signature: `Sparse a -> SparseFormat a`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_to_dia(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse1, hmath_value **out);
```

## `sparse.to_bsr`

Given positive block rows,block columns,then sparse matrix, build block-sparse-row format with zero padding within edge blocks. Invalid block dimensions or size overflow fails.

Original signature: `Int -> Int -> Sparse a -> Either MathError (SparseFormat a)`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_to_bsr(hmath_context *context, const hmath_value *prototype, const hmath_value *index1, const hmath_value *index2, const hmath_value *sparse3, hmath_value **out);
```

## `sparse.to_ellpack`

Return ELLPACK padded row storage, using row width equal to maximum nonzeros per row. Invalid/overflowing storage dimensions fail.

Original signature: `Sparse a -> Either MathError (SparseFormat a)`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_to_ellpack(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse1, hmath_value **out);
```

## `sparse.sparse_to_dense`

Return a dense Matrix with the same dimensions and zeros for missing entries. Checked dense element-count overflow can fail.

Original signature: `Sparse a -> Either MathError (Matrix a)`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_to_dense(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse1, hmath_value **out);
```

## `sparse.dense_to_sparse`

Convert a dense matrix to canonical sparse storage, discarding exact zeros and preserving dimensions.

Original signature: `Matrix a -> Sparse a`. Original constraints: `(Eq a, Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_dense_to_sparse(hmath_context *context, const hmath_value *prototype, const hmath_value *matrix1, hmath_value **out);
```

## `sparse.sparse_transpose`

Exchange row/column coordinates and dimensions without changing values, returning canonical sparse order.

Original signature: `Sparse a -> Sparse a`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_transpose(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse1, hmath_value **out);
```

## `sparse.sparse_add`

Add equal-shaped sparse matrices, coalescing entries and dropping resulting zeros. Shape mismatch or checked construction errors fail.

Original signature: `Sparse a -> Sparse a -> Either MathError (Sparse a)`. Original constraints: `(Eq a, Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_add(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse1, const hmath_value *sparse2, hmath_value **out);
```

## `sparse.sparse_subtract`

Subtract right sparse values from left for equal shapes; coalesce and remove zeros. Shape mismatch fails.

Original signature: `Sparse a -> Sparse a -> Either MathError (Sparse a)`. Original constraints: `(Eq a, Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_subtract(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse1, const hmath_value *sparse2, hmath_value **out);
```

## `sparse.spmv`

Given sparse matrix then dense vector, return matrix-vector product. Vector length must equal column count; mismatch returns Left MathError.

Original signature: `Sparse a -> [a] -> Either MathError [a]`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_spmv(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse1, const hmath_value *values2, hmath_value **out);
```

## `sparse.spmm`

Multiply compatible sparse matrices using sparse row contributions. Inner-dimension mismatch or output construction errors return Left MathError.

Original signature: `Sparse a -> Sparse a -> Either MathError (Sparse a)`. Original constraints: `(Eq a, Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_spmm(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse1, const hmath_value *sparse2, hmath_value **out);
```

## `sparse.sparse_kronecker`

Return sparse Kronecker product, multiplying row/column dimensions and nonzero pairs. Dimension/product overflow fails.

Original signature: `Sparse a -> Sparse a -> Either MathError (Sparse a)`. Original constraints: `(Eq a, Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_kronecker(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse1, const hmath_value *sparse2, hmath_value **out);
```

## `sparse.sparse_triangular_solve`

Given lower Bool,square finite sparse matrix,then RHS list, solve by forward/back substitution. Require correct triangular structure and matching RHS length; zero diagonal pivots or non-finite arithmetic fail.

Original signature: `Bool -> Sparse a -> [a] -> Either MathError [a]`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_triangular_solve(hmath_context *context, const hmath_value *prototype, const hmath_value *flag1, const hmath_value *sparse2, const hmath_value *values3, hmath_value **out);
```

## `sparse.sparse_diagonal_solve`

Given diagonal square sparse matrix then RHS, divide by each diagonal pivot. Off-diagonal entries, shape mismatch, zero pivots or non-finite data fail.

Original signature: `Sparse a -> [a] -> Either MathError [a]`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_diagonal_solve(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse1, const hmath_value *values2, hmath_value **out);
```

## `sparse.sparse_lu_lower`

Extract unit lower-triangular sparse factor from a SparseLU result.

Original signature: `SparseLU a -> Sparse a`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_lu_lower(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_lu1, hmath_value **out);
```

## `sparse.sparse_lu_upper`

Extract upper-triangular sparse factor from a SparseLU result.

Original signature: `SparseLU a -> Sparse a`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_lu_upper(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_lu1, hmath_value **out);
```

## `sparse.sparse_lu_permutation`

Return LU row permutation in pivoted order, for reconstructing P*A=L*U.

Original signature: `SparseLU a -> [Int]`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_lu_permutation(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_lu1, hmath_value **out);
```

## `sparse.sparse_lu`

Given finite nonnegative relative pivot tolerance then square finite sparse matrix, compute sparse LU with row pivoting. Invalid tolerance/input, zero/near-singular pivots or numerical failure returns Left MathError.

Original signature: `a -> Sparse a -> Either MathError (SparseLU a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_lu(hmath_context *context, const hmath_value *prototype, const hmath_value *scalar1, const hmath_value *sparse2, hmath_value **out);
```

## `sparse.sparse_solve_lu`

Given sparse LU factors then RHS list, apply row permutation and triangular solves. Dimension mismatch, singularity or non-finite input/result fails.

Original signature: `SparseLU a -> [a] -> Either MathError [a]`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_solve_lu(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_lu1, const hmath_value *values2, hmath_value **out);
```

## `sparse.sparse_cholesky`

Factor a symmetric positive-definite finite sparse matrix into a lower sparse factor. Invalid shape/symmetry, nonpositive pivots or numerical failure returns Left MathError.

Original signature: `Sparse a -> Either MathError (Sparse a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_cholesky(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse1, hmath_value **out);
```

## `sparse.sparse_qr_upper`

Extract upper-triangular/trapezoidal sparse R from a sparse QR factorization.

Original signature: `SparseQR a -> Sparse a`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_qr_upper(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_qr1, hmath_value **out);
```

## `sparse.sparse_qr`

Given finite nonnegative tolerance then sparse matrix, compute its checked sparse QR factors. Invalid tolerance, input or numerical failure returns Left MathError.

Original signature: `Sparse a -> Either MathError (SparseQR a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_qr(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse1, hmath_value **out);
```

## `sparse.sparse_qr_apply_qt`

Given sparse QR factors then compatible RHS list, apply transpose(Q) without constructing dense Q. Invalid length or non-finite arithmetic fails.

Original signature: `SparseQR a -> [a] -> Either MathError [a]`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_qr_apply_qt(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_qr1, const hmath_value *values2, hmath_value **out);
```

## `sparse.sparse_graph`

For a square sparse matrix, return one adjacency row per vertex with stored (column,value) neighbors. Non-square matrix returns Left MathError.

Original signature: `Sparse a -> Either MathError [(Int, [(Int, a)])]`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_graph(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse1, hmath_value **out);
```

## `sparse.sparse_storage_bytes`

Logical payload bytes: two machine-width indices and caller-provided scalar width per nonzero. Runtime Map node overhead is implementation dependent.

Original signature: `Int -> Sparse a -> Either MathError Integer`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_storage_bytes(hmath_context *context, const hmath_value *prototype, const hmath_value *index1, const hmath_value *sparse2, hmath_value **out);
```

## `sparse.sparse_tensor`

Given dimensions then (coordinate-list,value) entries, validate rank/bounds, sum duplicate coordinates and remove zeros. Invalid shape/indices return Left MathError.

Original signature: `[Int] -> [([Int], a)] -> Either MathError (SparseTensor a)`. Original constraints: `(Eq a, Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_tensor(hmath_context *context, const hmath_value *prototype, const hmath_value *values1, const hmath_value *values2, hmath_value **out);
```

## `sparse.sparse_tensor_shape`

Return axis dimensions of a sparse tensor; [] denotes a scalar.

Original signature: `SparseTensor a -> [Int]`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_tensor_shape(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_tensor1, hmath_value **out);
```

## `sparse.sparse_tensor_entries`

Return canonical nonzero (coordinate list,value) pairs in lexicographic coordinate order.

Original signature: `SparseTensor a -> [([Int], a)]`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_tensor_entries(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_tensor1, hmath_value **out);
```

## `sparse.sparse_tensor_lookup`

Given sparse tensor then full zero-based coordinates, return stored value or zero. Wrong rank or out-of-range indices fail.

Original signature: `SparseTensor a -> [Int] -> Either MathError a`. Original constraints: `(Num a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_tensor_lookup(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_tensor1, const hmath_value *values2, hmath_value **out);
```

## `sparse.sparse_eigen_reference`

Small-problem spectral reference backend. The caller explicitly authorizes a dense element budget; oversized matrices fail before generating zeros. This is not a scalable sparse eigensolver/SVD and never silently densifies.

Original signature: `Integer -> Sparse Double -> Either MathError Eigen`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_eigen_reference(hmath_context *context, const hmath_value *integer1, const hmath_value *sparse2, hmath_value **out);
```

## `sparse.sparse_svd_reference`

Given explicit dense-byte budget then sparse Double matrix, densify only if within budget and run checked dense SVD. This is a reference fallback, not a sparse iterative SVD; budget/backend/numeric errors fail.

Original signature: `Integer -> Sparse Double -> Either MathError SVD`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_sparse_svd_reference(hmath_context *context, const hmath_value *integer1, const hmath_value *sparse2, hmath_value **out);
```

## `sparse.coo`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_sparse_new_coo(hmath_context *context, const hmath_value *prototype, const hmath_value *index1, const hmath_value *index2, const hmath_value *values3, hmath_value **out);
```

## `sparse.csr`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_sparse_new_csr(hmath_context *context, const hmath_value *prototype, const hmath_value *index1, const hmath_value *index2, const hmath_value *values3, const hmath_value *values4, const hmath_value *values5, hmath_value **out);
```

## `sparse.csc`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_sparse_new_csc(hmath_context *context, const hmath_value *prototype, const hmath_value *index1, const hmath_value *index2, const hmath_value *values3, const hmath_value *values4, const hmath_value *values5, hmath_value **out);
```

## `sparse.dia`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_sparse_new_dia(hmath_context *context, const hmath_value *prototype, const hmath_value *index1, const hmath_value *index2, const hmath_value *values3, hmath_value **out);
```

## `sparse.bsr`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_sparse_new_bsr(hmath_context *context, const hmath_value *prototype, const hmath_value *index1, const hmath_value *index2, const hmath_value *index3, const hmath_value *index4, const hmath_value *values5, const hmath_value *values6, const hmath_value *values7, hmath_value **out);
```

## `sparse.ellpack`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_sparse_new_ellpack(hmath_context *context, const hmath_value *prototype, const hmath_value *index1, const hmath_value *index2, const hmath_value *index3, const hmath_value *values4, const hmath_value *values5, hmath_value **out);
```

## `sparse_spectral.default_sparse_spectral_options`

Absolute tolerance 1e-12, relative tolerance 1e-10, 1000 iterations per pair and a workspace limit of ten million scalar elements.

Original signature: `SparseSpectralOptions a`. Original constraints: `(Fractional a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_spectral_default_sparse_spectral_options(hmath_context *context, const hmath_value *prototype, hmath_value **out);
```

## `sparse_spectral.sparse_dominant_eigen`

Symmetric power iteration targeting the eigenvalue of largest magnitude. Exact symmetry and finite input are required. The caller supplies a nonzero finite initial vector; its projection onto the desired eigenspace must be nonzero. An initial eigenvector can converge with a zero budget. Equal opposite dominant eigenvalues may cause non-convergence. Returned residuals do not prove that the converged eigenvalue is the largest when the initial projection is zero.

Original signature: `SparseSpectralOptions a -> Sparse a -> [a] -> Either MathError (SparseEigenResult a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_spectral_sparse_dominant_eigen(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_spectral_options1, const hmath_value *sparse2, const hmath_value *values3, hmath_value **out);
```

## `sparse_spectral.sparse_truncated_svd`

Truncated SVD by two-sided power iteration and two-pass orthogonal deflation. The seed initializes a local deterministic stream, with no global RNG state. Both original singular residuals must meet the configured tolerance. The algorithm targets descending singular values if starting vectors have nonzero projection and the successive singular values are separated; it does not claim a certified rank or ordering when these power-method assumptions fail. Exact null images report RankDeficient, rather than inventing zero singular vectors. Small positive singular values may be returned within tolerance; requesting more vectors than the numerical rank can also exhaust the budget. k=0 returns empty factors, including for empty/zero inputs.

Original signature: `SparseSpectralOptions a -> Int -> Integer -> Sparse a -> Either MathError (SparseSVD a)`. Original constraints: `(RealFloat a)`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_spectral_sparse_truncated_svd(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_spectral_options1, const hmath_value *index2, const hmath_value *integer3, const hmath_value *sparse4, hmath_value **out);
```

## `sparse_spectral.sparse_absolute_tolerance`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `SparseSpectralOptions -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_spectral_sparse_absolute_tolerance(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_spectral_options1, hmath_value **out);
```

## `sparse_spectral.sparse_relative_tolerance`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `SparseSpectralOptions -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_spectral_sparse_relative_tolerance(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_spectral_options1, hmath_value **out);
```

## `sparse_spectral.sparse_iteration_limit`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `SparseSpectralOptions -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_spectral_sparse_iteration_limit(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_spectral_options1, hmath_value **out);
```

## `sparse_spectral.sparse_workspace_limit`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `SparseSpectralOptions -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_spectral_sparse_workspace_limit(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_spectral_options1, hmath_value **out);
```

## `sparse_spectral.SparseSpectralOptions`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_sparse_spectral_new_sparse_spectral_options(hmath_context *context, const hmath_value *prototype, const hmath_value *scalar1, const hmath_value *scalar2, const hmath_value *index3, const hmath_value *integer4, hmath_value **out);
```

## `sparse_spectral.sparse_eigenvalue`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `SparseEigenResult -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_spectral_sparse_eigenvalue(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_eigen_result1, hmath_value **out);
```

## `sparse_spectral.sparse_eigenvector`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `SparseEigenResult -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_spectral_sparse_eigenvector(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_eigen_result1, hmath_value **out);
```

## `sparse_spectral.sparse_eigen_residual`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `SparseEigenResult -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_spectral_sparse_eigen_residual(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_eigen_result1, hmath_value **out);
```

## `sparse_spectral.sparse_eigen_iterations`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `SparseEigenResult -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_spectral_sparse_eigen_iterations(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_eigen_result1, hmath_value **out);
```

## `sparse_spectral.SparseEigenResult`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_sparse_spectral_new_sparse_eigen_result(hmath_context *context, const hmath_value *prototype, const hmath_value *scalar1, const hmath_value *values2, const hmath_value *scalar3, const hmath_value *index4, hmath_value **out);
```

## `sparse_spectral.sparse_singular_values`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `SparseSVD -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_spectral_sparse_singular_values(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_svd1, hmath_value **out);
```

## `sparse_spectral.sparse_left_vectors`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `SparseSVD -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_spectral_sparse_left_vectors(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_svd1, hmath_value **out);
```

## `sparse_spectral.sparse_right_vectors`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `SparseSVD -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_spectral_sparse_right_vectors(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_svd1, hmath_value **out);
```

## `sparse_spectral.sparse_singular_residuals`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `SparseSVD -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_spectral_sparse_singular_residuals(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_svd1, hmath_value **out);
```

## `sparse_spectral.sparse_singular_iterations`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `SparseSVD -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_sparse_spectral_sparse_singular_iterations(hmath_context *context, const hmath_value *prototype, const hmath_value *sparse_svd1, hmath_value **out);
```

## `sparse_spectral.SparseSVD`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_sparse_spectral_new_sparse_svd(hmath_context *context, const hmath_value *prototype, const hmath_value *values1, const hmath_value *values2, const hmath_value *values3, const hmath_value *values4, const hmath_value *values5, hmath_value **out);
```

## `backend.backend_info`

Provider identity is immutable for the lifetime of a handle.

Original signature: `Backend -> BackendInfo`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_backend_info(hmath_context *context, const hmath_value *backend1, hmath_value **out);
```

## `backend.pure_backend`

Construct the deterministic reference backend without dynamically loading BLAS. Its lifetime is garbage-collected; selected numeric reference decomposition limits still apply.

Original signature: `Backend`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_pure_backend(hmath_context *context, hmath_value **out);
```

## `backend.lapack_available`

Availability of the once-initialized independent LAPACKE loader.

Original signature: `IO Bool`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_lapack_available(hmath_context *context, hmath_value **out);
```

## `backend.select_backend`

Given AutoBackend or explicit provider/integer-ABI/library request, select a reference or native BLAS backend in IO. Auto honors HMATH_BACKEND, HMATH_BLAS_PROVIDER, HMATH_BLAS_INTEGER_BITS and HMATH_BLAS_LIBRARY; unknown settings or unavailable explicit providers fail. Keep the Backend alive while calling it.

Original signature: `BackendRequest -> IO (Either MathError Backend)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_select_backend(hmath_context *context, const hmath_value *backend_request1, hmath_value **out);
```

## `backend.set_backend_threads`

Positive thread count; Pure supports one thread. Accelerate has no supported runtime setter and returns an explicit error. No implicit global restoration.

Original signature: `Backend -> Int -> IO (Either MathError ())`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_set_backend_threads(hmath_context *context, const hmath_value *backend1, const hmath_value *index2, hmath_value **out);
```

## `backend.lapack_status`

Convert the LAPACK convention without losing the distinction between an invalid argument and failed numerical convergence. For factorization pivots callers may instead map a positive code to SingularMatrix (info - 1).

Original signature: `String -> Int -> Either MathError ()`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_lapack_status(hmath_context *context, const hmath_value *text1, const hmath_value *index2, hmath_value **out);
```

## `backend.matrix_from_layout`

Layout conversion is a checked, explicit copy; zero shapes retain rank.

Original signature: `BackendLayout -> Int -> Int -> [a] -> Either MathError (M.Matrix a)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_matrix_from_layout(hmath_context *context, const hmath_value *prototype, const hmath_value *backend_layout1, const hmath_value *index2, const hmath_value *index3, const hmath_value *values4, hmath_value **out);
```

## `backend.matrix_to_layout`

Given RowMajor/ColumnMajor layout then Matrix, return values in that physical order without changing the logical matrix.

Original signature: `BackendLayout -> M.Matrix a -> [a]`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_matrix_to_layout(hmath_context *context, const hmath_value *prototype, const hmath_value *backend_layout1, const hmath_value *matrix2, hmath_value **out);
```

## `backend.axpy`

Given backend,alpha,x,y, return alpha*x+y as a new Double list. Require equal lengths, finite inputs/result and provider-supported integer extents; validation/provider failures return Left MathError in IO.

Original signature: `Backend -> Double -> [Double] -> [Double] -> IO (Either MathError [Double])`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_axpy(hmath_context *context, const hmath_value *backend1, const hmath_value *double2, const hmath_value *values3, const hmath_value *values4, hmath_value **out);
```

## `backend.dot`

Real inner product. Finite input and output; accumulation can overflow even when exact cancellation would produce a finite mathematical result.

Original signature: `Backend -> [Double] -> [Double] -> IO (Either MathError Double)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_dot(hmath_context *context, const hmath_value *backend1, const hmath_value *values2, const hmath_value *values3, hmath_value **out);
```

## `backend.nrm2`

Given backend then finite Double vector, return Euclidean norm through the selected provider or reference path. Empty input gives zero; invalid/non-finite output or provider bounds fail in IO.

Original signature: `Backend -> [Double] -> IO (Either MathError Double)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_nrm2(hmath_context *context, const hmath_value *backend1, const hmath_value *values2, hmath_value **out);
```

## `backend.gemv`

y := alpha op(A) x + beta y. Finite inputs are checked even for zero alpha.

Original signature: `Backend -> Transpose -> Double -> M.Matrix Double -> [Double] -> Double -> [Double] -> IO (Either MathError [Double])`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_gemv(hmath_context *context, const hmath_value *backend1, const hmath_value *transpose2, const hmath_value *double3, const hmath_value *matrix4, const hmath_value *values5, const hmath_value *double6, const hmath_value *values7, hmath_value **out);
```

## `backend.gemm`

C := alpha op(A) op(B) + beta C. Matrices and output must have compatible shapes; all zero-dimensional cases use the reference arithmetic.

Original signature: `Backend -> Transpose -> Transpose -> Double -> M.Matrix Double -> M.Matrix Double -> Double -> M.Matrix Double -> IO (Either MathError (M.Matrix Double))`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_gemm(hmath_context *context, const hmath_value *backend1, const hmath_value *transpose2, const hmath_value *transpose3, const hmath_value *double4, const hmath_value *matrix5, const hmath_value *matrix6, const hmath_value *double7, const hmath_value *matrix8, hmath_value **out);
```

## `backend.complex_gemm`

Given backend,transpose A,transpose B,alpha,A,B,beta,C, return alpha*op(A)*op(B)+beta*C as a new complex matrix. Validate compatible dimensions, finite components and provider integer/allocation bounds.

Original signature: `Backend -> Transpose -> Transpose -> Complex Double -> M.Matrix (Complex Double) -> M.Matrix (Complex Double) -> Complex Double -> M.Matrix (Complex Double) -> IO (Either MathError (M.Matrix (Complex Double)))`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_complex_gemm(hmath_context *context, const hmath_value *backend1, const hmath_value *transpose2, const hmath_value *transpose3, const hmath_value *complex4, const hmath_value *matrix5, const hmath_value *matrix6, const hmath_value *complex7, const hmath_value *matrix8, hmath_value **out);
```

## `backend.complex_axpy`

Given backend,complex alpha,x,y, compute alpha*x+y, requiring equal lengths and finite real/imaginary components. Return a new list or checked shape/provider/numeric error in IO.

Original signature: `Backend -> Complex Double -> [Complex Double] -> [Complex Double] -> IO (Either MathError [Complex Double])`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_complex_axpy(hmath_context *context, const hmath_value *backend1, const hmath_value *complex2, const hmath_value *values3, const hmath_value *values4, hmath_value **out);
```

## `backend.complex_dot`

Set the Boolean to True for the Hermitian dot product (conjugate x).

Original signature: `Backend -> Bool -> [Complex Double] -> [Complex Double] -> IO (Either MathError (Complex Double))`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_complex_dot(hmath_context *context, const hmath_value *backend1, const hmath_value *flag2, const hmath_value *values3, const hmath_value *values4, hmath_value **out);
```

## `backend.complex_nrm2`

Given backend then complex vector, return real Euclidean norm of all real/imaginary components. Non-finite input/output or provider extent errors return Left MathError in IO.

Original signature: `Backend -> [Complex Double] -> IO (Either MathError Double)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_complex_nrm2(hmath_context *context, const hmath_value *backend1, const hmath_value *values2, hmath_value **out);
```

## `backend.complex_gemv`

Given backend,transpose selector,alpha,A,x,beta,y, return alpha*op(A)*x+beta*y as a new complex list. ConjugateTranspose conjugates matrix values; dimensions, finite values and provider bounds are checked.

Original signature: `Backend -> Transpose -> Complex Double -> M.Matrix (Complex Double) -> [Complex Double] -> Complex Double -> [Complex Double] -> IO (Either MathError [Complex Double])`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_complex_gemv(hmath_context *context, const hmath_value *backend1, const hmath_value *transpose2, const hmath_value *complex3, const hmath_value *matrix4, const hmath_value *values5, const hmath_value *complex6, const hmath_value *values7, hmath_value **out);
```

## `backend.batched_gemm`

Uniform scalar/transpose options, independently checked matrix triples. Earlier calls may execute before a later invalid item; no input is mutated.

Original signature: `Backend -> Transpose -> Transpose -> Double -> Double -> [(M.Matrix Double, M.Matrix Double, M.Matrix Double)] -> IO (Either MathError [M.Matrix Double])`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_batched_gemm(hmath_context *context, const hmath_value *backend1, const hmath_value *transpose2, const hmath_value *transpose3, const hmath_value *double4, const hmath_value *double5, const hmath_value *values6, hmath_value **out);
```

## `backend.strided_batched_gemm`

Row-major batches of A(m,k) and B(k,n). Strides count elements, may include padding, and may be zero for broadcast. Extents are checked with Integer before slicing; output batches are contiguous m*n matrices. No implicit transposes.

Original signature: `Backend -> Int -> Int -> Int -> Int -> Int -> [Double] -> Int -> [Double] -> IO (Either MathError [M.Matrix Double])`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_strided_batched_gemm(hmath_context *context, const hmath_value *backend1, const hmath_value *index2, const hmath_value *index3, const hmath_value *index4, const hmath_value *index5, const hmath_value *index6, const hmath_value *values7, const hmath_value *index8, const hmath_value *values9, hmath_value **out);
```

## `backend.backend_lu`

Given backend then real matrix, compute checked column-independent LU using the reference pivoted LU implementation. The backend argument does not change this routine's provider. Shape/pivot/numeric failures propagate.

Original signature: `Backend -> M.Matrix Double -> Either MathError (LU.LU Double)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_backend_lu(hmath_context *context, const hmath_value *backend1, const hmath_value *matrix2, hmath_value **out);
```

## `backend.backend_qr`

Given backend then real matrix, compute reference column-pivoted Householder QR; selection does not change this routine's provider. Validation/numeric errors propagate.

Original signature: `Backend -> M.Matrix Double -> Either MathError (QR.QR Double)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_backend_qr(hmath_context *context, const hmath_value *backend1, const hmath_value *matrix2, hmath_value **out);
```

## `backend.backend_solve`

Given backend,square real matrix,then RHS list, solve via reference LU for Pure or the independent LAPACKE solve bridge for a native backend. Invalid dimensions, unavailable solver, singularity or non-finite arithmetic returns Left MathError.

Original signature: `Backend -> M.Matrix Double -> [Double] -> Either MathError [Double]`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_backend_solve(hmath_context *context, const hmath_value *backend1, const hmath_value *matrix2, const hmath_value *values3, hmath_value **out);
```

## `backend.backend_cholesky`

Given backend then finite symmetric positive-definite matrix, return reference lower Cholesky factor. Invalid shape/symmetry/pivots/numeric results fail; provider selection is not used by this wrapper.

Original signature: `Backend -> M.Matrix Double -> Either MathError (M.Matrix Double)`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_backend_cholesky(hmath_context *context, const hmath_value *backend1, const hmath_value *matrix2, hmath_value **out);
```

## `backend.backend_least_squares`

Given backend,design matrix,then RHS list, solve using reference pivoted QR. Require compatible overdetermined/full-rank input; shape/rank/numeric failures propagate.

Original signature: `Backend -> M.Matrix Double -> [Double] -> Either MathError [Double]`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_backend_least_squares(hmath_context *context, const hmath_value *backend1, const hmath_value *matrix2, const hmath_value *values3, hmath_value **out);
```

## `backend.backend_svd`

Given backend then finite real matrix, use bounded pure reference SVD for Pure or LAPACK thin SVD for native selection. Return factors or checked shape/budget/provider/convergence errors.

Original signature: `Backend -> M.Matrix Double -> Either MathError L.SVD`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_backend_svd(hmath_context *context, const hmath_value *backend1, const hmath_value *matrix2, hmath_value **out);
```

## `backend.backend_symmetric_eigen`

Given backend then finite symmetric square matrix, use bounded cyclic-Jacobi reference solver for Pure or LAPACK otherwise. Return eigenvalues/vectors or input/provider/convergence errors.

Original signature: `Backend -> M.Matrix Double -> Either MathError L.Eigen`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_backend_symmetric_eigen(hmath_context *context, const hmath_value *backend1, const hmath_value *matrix2, hmath_value **out);
```

## `backend.pure_symmetric_eigen`

Cyclic Jacobi symmetric eigensolver, at most 100 sweeps, ascending eigenvalues. Scaled input avoids squared-norm overflow. This reference path is limited to order 128 and reports nonconvergence rather than returning an unchecked factor.

Original signature: `M.Matrix Double -> Either MathError L.Eigen`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_pure_symmetric_eigen(hmath_context *context, const hmath_value *matrix1, hmath_value **out);
```

## `backend.pure_svd`

Thin real SVD by one-sided Jacobi orthogonalization, at most 100 sweeps, dimensions <=128. Unlike a normal-equation SVD it does not form A^T A. A deterministic orthogonal completion supplies zero-singular-value columns.

Original signature: `M.Matrix Double -> Either MathError L.SVD`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_pure_svd(hmath_context *context, const hmath_value *matrix1, hmath_value **out);
```

## `backend.pure`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_backend_new_pure(hmath_context *context, hmath_value **out);
```

## `backend.open_blas`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_backend_new_open_blas(hmath_context *context, hmath_value **out);
```

## `backend.blis`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_backend_new_blis(hmath_context *context, hmath_value **out);
```

## `backend.one_mkl`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_backend_new_one_mkl(hmath_context *context, hmath_value **out);
```

## `backend.accelerate`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_backend_new_accelerate(hmath_context *context, hmath_value **out);
```

## `backend.lp64`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_backend_new_lp64(hmath_context *context, hmath_value **out);
```

## `backend.ilp64`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_backend_new_ilp64(hmath_context *context, hmath_value **out);
```

## `backend.auto_backend`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_backend_new_auto_backend(hmath_context *context, hmath_value **out);
```

## `backend.require_backend`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_backend_new_require_backend(hmath_context *context, const hmath_value *provider1, const hmath_value *integer_abi2, const hmath_value *maybe3, hmath_value **out);
```

## `backend.selected_provider`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `BackendInfo -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_selected_provider(hmath_context *context, const hmath_value *backend_info1, hmath_value **out);
```

## `backend.selected_integer_abi`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `BackendInfo -> field`. Original constraints: `none`. Return the original function result and original Either/Maybe failure convention.

```c
hmath_status hmath_linear_backend_selected_integer_abi(hmath_context *context, const hmath_value *backend_info1, hmath_value **out);
```

## `backend.BackendInfo`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_backend_new_backend_info(hmath_context *context, const hmath_value *provider1, const hmath_value *integer_abi2, hmath_value **out);
```

## `backend.row_major`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_backend_new_row_major(hmath_context *context, hmath_value **out);
```

## `backend.column_major`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_backend_new_column_major(hmath_context *context, hmath_value **out);
```

## `backend.no_transpose`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_backend_new_no_transpose(hmath_context *context, hmath_value **out);
```

## `backend.Transpose`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_backend_new_transpose(hmath_context *context, hmath_value **out);
```

## `backend.conjugate_transpose`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Original constraints: `none`. Construct the original public record/variant without inventing validation.

```c
hmath_status hmath_linear_backend_new_conjugate_transpose(hmath_context *context, hmath_value **out);
```

