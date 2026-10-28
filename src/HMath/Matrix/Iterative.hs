-- SPDX-License-Identifier: MPL-2.0

{- | Bounded reference iterative solvers for dense real matrices. Every returned
result is checked against the original residual. Square methods stop when
||b-Ax|| <= atol + rtol*||b||. Least-squares methods may also stop when
||A^T(b-Ax)|| <= atol + rtol*||A^T b||. Full Krylov bases are retained in
GMRES, MINRES and LSMR; these emphasize transparent mathematics over storage.
Nonfinite arithmetic, breakdown and exhausted budgets return structured errors.
-}
module HMath.Matrix.Iterative (
    IterativeOptions (..),
    defaultIterativeOptions,
    IterativeResult (..),
    Preconditioner,
    applyPreconditioner,
    identityPreconditioner,
    jacobiPreconditioner,
    blockJacobiPreconditioner,
    ilu0Preconditioner,
    ic0Preconditioner,
    conjugateGradient,
    preconditionedCG,
    gmres,
    minres,
    bicg,
    bicgstab,
    lsqr,
    lsmr,
    jacobiSolve,
    gaussSeidelSolve,
    sorSolve,
    iterativeRefinement,
) where

import Control.Monad (foldM)
import HMath.Error (MathError (..))
import HMath.Matrix (Matrix, fromListChecked, shape, transposeMatrix)
import HMath.Matrix.Internal (dotV, entries, finiteMatrix, finiteValues, stableNorm)
import HMath.Matrix.LU (luDecomposeWithTolerance, solveLU)
import HMath.Matrix.QR (leastSquares)

{- | Absolute and relative residual tolerances and maximum iterations. A zero
budget succeeds only when the supplied initial guess already meets tolerance.
-}
data IterativeOptions a = IterativeOptions
    { absoluteTolerance :: a
    -- ^ Finite nonnegative absolute residual tolerance.
    , relativeTolerance :: a
    -- ^ Finite nonnegative relative residual tolerance.
    , maximumIterations :: Int
    -- ^ Nonnegative maximum iteration count.
    }
    deriving (Eq, Show)

-- | 1000 iterations, zero absolute tolerance and relative tolerance 1e-10.
defaultIterativeOptions :: (Fractional a) => IterativeOptions a
defaultIterativeOptions = IterativeOptions 0 1e-10 1000

-- | Converged state with norms evaluated from the original matrix and rhs.
data IterativeResult a = IterativeResult
    { iterativeSolution :: [a]
    -- ^ Solution in original variable order.
    , iterativeIterations :: Int
    -- ^ Number of completed updates.
    , iterativeResidualNorm :: a
    -- ^ Euclidean norm of b-Ax.
    , iterativeNormalResidualNorm :: a
    -- ^ Euclidean norm of A^T(b-Ax), useful for inconsistent least squares.
    }
    deriving (Eq, Show)

-- | A checked inverse action M^-1; constructors retain their input dimension.
newtype Preconditioner a = Preconditioner ([a] -> Either MathError [a])

-- | Apply an inverse action; wrong vector lengths and nonfinite values fail.
applyPreconditioner :: Preconditioner a -> [a] -> Either MathError [a]
applyPreconditioner (Preconditioner f) = f

-- | Identity inverse action in a nonnegative dimension.
identityPreconditioner :: (RealFloat a) => Int -> Either MathError (Preconditioner a)
identityPreconditioner n
    | n < 0 = Left (InvalidArgument "negative preconditioner dimension")
    | otherwise = Right (Preconditioner (\xs -> validateVector n xs >> Right xs))

-- | Inverse diagonal preconditioner. Every diagonal entry must be nonzero.
jacobiPreconditioner :: (RealFloat a) => Matrix a -> Either MathError (Preconditioner a)
jacobiPreconditioner matrix = do
    n <- squareFinite matrix
    let rows = entries matrix; diagonal = [value rows i i | i <- [0 .. n - 1]]
    checkPivots diagonal
    pure
        ( Preconditioner
            ( \xs -> do
                validateVector n xs
                let scaled = zipWith (/) xs diagonal
                finiteValues scaled
                pure scaled
            )
        )

{- | Block Jacobi from contiguous positive block sizes summing to the dimension.
Each diagonal block is factored with pivoted LU; off-block entries are ignored.
-}
blockJacobiPreconditioner ::
    (RealFloat a) => [Int] -> Matrix a -> Either MathError (Preconditioner a)
blockJacobiPreconditioner sizes matrix = do
    n <- squareFinite matrix
    if any (<= 0) sizes || sum (map toInteger sizes) /= toInteger n
        then Left (InvalidArgument "invalid block Jacobi partition")
        else do
            let offsets = scanl (+) 0 sizes; rows = entries matrix
            factors <-
                mapM
                    ( \(offset, k) ->
                        fromListChecked
                            k
                            k
                            [value rows (offset + i) (offset + j) | i <- [0 .. k - 1], j <- [0 .. k - 1]]
                            >>= luDecomposeWithTolerance 0
                    )
                    (zip offsets sizes)
            pure
                ( Preconditioner
                    ( \xs -> do
                        validateVector n xs
                        concat
                            <$> sequence
                                [ solveLU factor (take k (drop offset xs))
                                | (factor, offset, k) <- zip3 factors offsets sizes
                                ]
                    )
                )

{- | Incomplete LU with zero fill and no pivoting. The exact nonzero pattern of
A is retained, diagonal pivots are mandatory, and zero pivots fail explicitly.
-}
ilu0Preconditioner :: (RealFloat a) => Matrix a -> Either MathError (Preconditioner a)
ilu0Preconditioner matrix = do
    n <- squareFinite matrix
    let original = entries matrix
        active i j = i == j || value original i j /= 0
        update rows k = do
            let pivot = value rows k k
            if pivot == 0
                then Left (SingularMatrix k)
                else do
                    let lower =
                            [ [ if j == k && i > k && active i k then value rows i k / pivot else value rows i j | j <- [0 .. n - 1]
                              ]
                            | i <- [0 .. n - 1]
                            ]
                        next =
                            [ [ if i > k && j > k && active i k && active i j
                                    then value lower i j - value lower i k * value lower k j
                                    else value lower i j
                              | j <- [0 .. n - 1]
                              ]
                            | i <- [0 .. n - 1]
                            ]
                    finiteValues (concat next)
                    pure next
    packed <- foldM update original [0 .. n - 1]
    let lower =
            [ [if i == j then 1 else if i > j then value packed i j else 0 | j <- [0 .. n - 1]]
            | i <- [0 .. n - 1]
            ]
        upper = [[if i <= j then value packed i j else 0 | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
    pure (triangularPreconditioner lower upper)

{- | Incomplete Cholesky with zero fill for a symmetric positive-definite input.
Dropping can itself cause a nonpositive pivot; that reports NotPositiveDefinite.
-}
ic0Preconditioner :: (RealFloat a) => Matrix a -> Either MathError (Preconditioner a)
ic0Preconditioner matrix = do
    n <- symmetricFinite matrix
    let a = entries matrix
        initial = replicate n (replicate n 0)
        step rows (i, j)
            | i /= j && value a i j == 0 = Right rows
            | otherwise = do
                let partial = value a i j - sum [value rows i k * value rows j k | k <- [0 .. j - 1]]
                x <-
                    if i == j
                        then if partial <= 0 then Left (NotPositiveDefinite i) else Right (sqrt partial)
                        else
                            if value rows j j == 0
                                then Left (SingularMatrix j)
                                else Right (partial / value rows j j)
                finiteValues [x]
                pure (setValue i j x rows)
    lower <- foldM step initial [(i, j) | i <- [0 .. n - 1], j <- [0 .. i]]
    let upper = [[value lower j i | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
    pure (triangularPreconditioner lower upper)

triangularPreconditioner :: (RealFloat a) => [[a]] -> [[a]] -> Preconditioner a
triangularPreconditioner lower upper =
    Preconditioner
        ( \b -> do
            validateVector (length lower) b
            y <- triangularSolve True lower b
            triangularSolve False upper y
        )

triangularSolve :: (RealFloat a) => Bool -> [[a]] -> [a] -> Either MathError [a]
triangularSolve forward a b = foldM step (replicate n 0) order
  where
    n = length a
    order = if forward then [0 .. n - 1] else reverse [0 .. n - 1]
    step x i = do
        let pivot = value a i i
            js = if forward then [0 .. i - 1] else [i + 1 .. n - 1]
        if pivot == 0
            then Left (SingularMatrix i)
            else do
                let y = (vectorValue b i - sum [value a i j * vectorValue x j | j <- js]) / pivot
                finiteValues [y]
                pure (replaceAt i y x)

{- | Conjugate gradient for symmetric positive-definite matrices. Symmetry is
checked; nonpositive Krylov curvature rejects indefinite matrices encountered.
-}
conjugateGradient ::
    (RealFloat a) =>
    IterativeOptions a ->
    Matrix a ->
    [a] ->
    [a] ->
    Either MathError (IterativeResult a)
conjugateGradient options matrix b x = do
    preconditioner <- identityPreconditioner (fst (shape matrix))
    preconditionedCG options preconditioner matrix b x

{- | Preconditioned conjugate gradient. The inverse action must be SPD; a
nonpositive r^T M^-1 r or search curvature is reported as a domain error.
-}
preconditionedCG ::
    (RealFloat a) =>
    IterativeOptions a ->
    Preconditioner a ->
    Matrix a ->
    [a] ->
    [a] ->
    Either MathError (IterativeResult a)
preconditionedCG options preconditioner matrix b x0 = do
    _ <- symmetricFinite matrix
    validateProblem True options matrix b x0
    let r0 = residual matrix b x0
    if converged options b r0
        then result matrix b 0 x0
        else do
            z0 <- applyPreconditioner preconditioner r0
            let rho0 = dotV r0 z0
            if rho0 <= 0
                then Left (DomainError "PCG preconditioner is not positive definite")
                else go 0 x0 z0 rho0
  where
    go k x p rho
        | k == maximumIterations options = Left (NonConvergence "preconditioned CG" k)
        | otherwise = do
            let ap = matvec matrix p; curvature = dotV p ap
            if curvature <= 0
                then Left (NotPositiveDefinite k)
                else do
                    let alpha = rho / curvature
                        next = addV x (scaleV alpha p)
                        rnext = residual matrix b next
                    finiteValues next
                    if converged options b rnext
                        then result matrix b (k + 1) next
                        else do
                            z <- applyPreconditioner preconditioner rnext
                            let rhonew = dotV rnext z
                            if rhonew <= 0
                                then Left (DomainError "PCG preconditioner is not positive definite")
                                else go (k + 1) next (addV z (scaleV (rhonew / rho) p)) rhonew

{- | Restarted GMRES with modified Gram--Schmidt Arnoldi and a second
orthogonalization pass. Restart length must be positive; total iterations are
bounded by options. Each projected least-squares problem is solved by QR.
-}
gmres ::
    (RealFloat a) =>
    IterativeOptions a ->
    Int ->
    Matrix a ->
    [a] ->
    [a] ->
    Either MathError (IterativeResult a)
gmres options restart matrix b x0
    | restart <= 0 = Left (InvalidArgument "GMRES restart must be positive")
    | otherwise = do
        validateProblem True options matrix b x0
        outer 0 x0
  where
    n = fst (shape matrix)
    outer done x
        | converged options b r = result matrix b done x
        | done == maximumIterations options = Left (NonConvergence "GMRES" done)
        | otherwise = cycleStep done x (stableNorm r) [normalize r] [] 0
      where
        r = residual matrix b x
    cycleStep done base beta basis columns k = do
        let q = vectorAt k basis
            (h, w) = orthogonalize basis (matvec matrix q)
            nextNorm = stableNorm w
            column = h ++ [nextNorm]
            cols = columns ++ [column]
            width = k + 1
        hmatrix <-
            fromListChecked
                (width + 1)
                width
                [vectorValue col i | i <- [0 .. width], col <- cols]
        y <- leastSquares hmatrix (beta : replicate width 0)
        let x = addV base (combine basis y)
            nextDone = done + 1
        finiteValues x
        if converged options b (residual matrix b x)
            then result matrix b nextDone x
            else
                if nextDone == maximumIterations options
                    then Left (NonConvergence "GMRES" nextDone)
                    else
                        if nextNorm == 0
                            then Left (DomainError "GMRES invariant-subspace breakdown")
                            else
                                if width >= min restart n
                                    then outer nextDone x
                                    else cycleStep nextDone base beta (basis ++ [scaleV (1 / nextNorm) w]) cols width

{- | Minimum residual on the symmetric Lanczos Krylov space, including indefinite
systems. A full tridiagonal projected least-squares problem is solved by QR
each iteration (the mathematical MINRES objective, without short recurrences).
-}
minres ::
    (RealFloat a) =>
    IterativeOptions a ->
    Matrix a ->
    [a] ->
    [a] ->
    Either MathError (IterativeResult a)
minres options matrix b x0 = do
    _ <- symmetricFinite matrix
    validateProblem True options matrix b x0
    let r = residual matrix b x0
    if converged options b r
        then result matrix b 0 x0
        else loop 0 (stableNorm r) [normalize r] [] []
  where
    loop k beta0 basis alphas betas
        | k == maximumIterations options = Left (NonConvergence "MINRES" k)
        | otherwise = do
            let q = vectorAt k basis
                prior =
                    if k == 0
                        then replicate (length q) 0
                        else scaleV (vectorValue betas (k - 1)) (vectorAt (k - 1) basis)
                aq = subV (matvec matrix q) prior
                alpha = dotV q aq
                w = subV aq (scaleV alpha q)
                beta = stableNorm w
                as = alphas ++ [alpha]
                bs = betas ++ [beta]
                width = k + 1
                entry i j
                    | i == j = vectorValue as j
                    | i == j + 1 = vectorValue bs j
                    | j == i + 1 = vectorValue bs i
                    | otherwise = 0
            projected <-
                fromListChecked (width + 1) width [entry i j | i <- [0 .. width], j <- [0 .. width - 1]]
            y <- leastSquares projected (beta0 : replicate width 0)
            let x = addV x0 (combine basis y)
            finiteValues x
            if converged options b (residual matrix b x)
                then result matrix b width x
                else
                    if beta == 0
                        then Left (DomainError "MINRES invariant-subspace breakdown")
                        else loop width beta0 (basis ++ [scaleV (1 / beta) w]) as bs

{- | Bi-conjugate gradient for nonsymmetric square matrices; the initial shadow
residual equals the initial residual. Biorthogonality breakdown fails explicitly.
-}
bicg ::
    (RealFloat a) =>
    IterativeOptions a ->
    Matrix a ->
    [a] ->
    [a] ->
    Either MathError (IterativeResult a)
bicg options matrix b x0 = do
    validateProblem True options matrix b x0
    let r = residual matrix b x0
    if converged options b r
        then result matrix b 0 x0
        else go 0 x0 r r r r (dotV r r)
  where
    transposed = transposeMatrix matrix
    go k x r shadow p phat rho
        | k == maximumIterations options = Left (NonConvergence "BiCG" k)
        | rho == 0 = Left (DomainError "BiCG shadow breakdown")
        | otherwise = do
            let ap = matvec matrix p; atp = matvec transposed phat; denom = dotV phat ap
            if denom == 0
                then Left (DomainError "BiCG projection breakdown")
                else do
                    let alpha = rho / denom
                        xn = addV x (scaleV alpha p)
                        rn = subV r (scaleV alpha ap)
                        sn = subV shadow (scaleV alpha atp)
                        rhon = dotV sn rn
                    finiteValues (xn ++ rn ++ sn)
                    if converged options b (residual matrix b xn)
                        then result matrix b (k + 1) xn
                        else
                            go
                                (k + 1)
                                xn
                                rn
                                sn
                                (addV rn (scaleV (rhon / rho) p))
                                (addV sn (scaleV (rhon / rho) phat))
                                rhon

{- | Stabilized BiCG with a fixed initial shadow residual and a minimal-residual
omega step. Zero projection/omega denominators return explicit breakdown errors.
-}
bicgstab ::
    (RealFloat a) =>
    IterativeOptions a ->
    Matrix a ->
    [a] ->
    [a] ->
    Either MathError (IterativeResult a)
bicgstab options matrix b x0 = do
    validateProblem True options matrix b x0
    let r = residual matrix b x0; zeroV = replicate (length x0) 0
    if converged options b r then result matrix b 0 x0 else go r 0 x0 r zeroV zeroV 1 1 1
  where
    go shadow k x r p v rhoOld alphaOld omegaOld
        | k == maximumIterations options = Left (NonConvergence "BiCGSTAB" k)
        | otherwise = do
            let rho = dotV shadow r
            if rho == 0 || omegaOld == 0
                then Left (DomainError "BiCGSTAB shadow/omega breakdown")
                else do
                    let beta = (rho / rhoOld) * (alphaOld / omegaOld)
                        pn = addV r (scaleV beta (subV p (scaleV omegaOld v)))
                        vn = matvec matrix pn
                        denom = dotV shadow vn
                    if denom == 0
                        then Left (DomainError "BiCGSTAB projection breakdown")
                        else do
                            let alpha = rho / denom
                                s = subV r (scaleV alpha vn)
                                xa = addV x (scaleV alpha pn)
                            if converged options b (residual matrix b xa)
                                then result matrix b (k + 1) xa
                                else do
                                    let t = matvec matrix s; tt = dotV t t
                                    if tt == 0
                                        then Left (DomainError "BiCGSTAB residual breakdown")
                                        else do
                                            let omega = dotV t s / tt
                                                xn = addV xa (scaleV omega s)
                                                rn = subV s (scaleV omega t)
                                            finiteValues (xn ++ rn)
                                            if converged options b (residual matrix b xn)
                                                then result matrix b (k + 1) xn
                                                else go shadow (k + 1) xn rn pn vn rho alpha omega

{- | LSQR by Golub--Kahan bidiagonalization and plane-rotation recurrences.
Rectangular and rank-deficient systems are supported. The least-squares
stopping test uses the original normal residual as well as the true residual.
-}
lsqr ::
    (RealFloat a) =>
    IterativeOptions a ->
    Matrix a ->
    [a] ->
    [a] ->
    Either MathError (IterativeResult a)
lsqr options matrix b x0 = do
    validateProblem False options matrix b x0
    let r = residual matrix b x0
        beta = stableNorm r
        u = normalize r
        atU = matvec transposed u
        alpha = stableNorm atU
        v = normalize atU
    if leastConverged options matrix b r
        then result matrix b 0 x0
        else go 0 x0 u v v alpha beta alpha
  where
    transposed = transposeMatrix matrix
    go k x u v w alpha phibar rhobar
        | k == maximumIterations options = Left (NonConvergence "LSQR" k)
        | otherwise = do
            let unscaled = subV (matvec matrix v) (scaleV alpha u)
                beta = stableNorm unscaled
                un = normalize unscaled
                vscaled = subV (matvec transposed un) (scaleV beta v)
                alphan = stableNorm vscaled
                vn = normalize vscaled
                rho = stableNorm [rhobar, beta]
            if rho == 0
                then Left (DomainError "LSQR bidiagonal breakdown")
                else do
                    let c = rhobar / rho
                        s = beta / rho
                        theta = s * alphan
                        phi = c * phibar
                        xn = addV x (scaleV (phi / rho) w)
                        wn = subV vn (scaleV (theta / rho) w)
                    finiteValues (xn ++ wn)
                    if leastConverged options matrix b (residual matrix b xn)
                        then result matrix b (k + 1) xn
                        else go (k + 1) xn un vn wn alphan (s * phibar) (-c * alphan)

{- | LSMR's minimum-normal-residual Krylov objective using explicit Golub--Kahan
bases and QR on the projected tridiagonal normal operator. A^T A is never
formed. This full-basis reference version uses more storage than short-recurrence
implementations; it minimizes ||A^T(b-Ax)|| over the generated Krylov space.
-}
lsmr ::
    (RealFloat a) =>
    IterativeOptions a ->
    Matrix a ->
    [a] ->
    [a] ->
    Either MathError (IterativeResult a)
lsmr options matrix b x0 = do
    validateProblem False options matrix b x0
    let r = residual matrix b x0
        beta0 = stableNorm r
        u0 = normalize r
        vraw = matvec transposed u0
        alpha0 = stableNorm vraw
        v0 = normalize vraw
    if leastConverged options matrix b r
        then result matrix b 0 x0
        else loop 0 (alpha0 * beta0) u0 [v0] [alpha0] [beta0]
  where
    transposed = transposeMatrix matrix
    loop k gamma u basis alphas betas
        | k == maximumIterations options = Left (NonConvergence "LSMR" k)
        | otherwise = do
            let v = vectorAt k basis
                alpha = vectorValue alphas k
                rawU = subV (matvec matrix v) (scaleV alpha u)
                beta = stableNorm rawU
                un = normalize rawU
                rawV = subV (matvec transposed un) (scaleV beta v)
                alphan = stableNorm rawV
                vn = normalize rawV
                as = alphas ++ [alphan]
                bs = betas ++ [beta]
                width = k + 1
                entry i j
                    | i == j = vectorValue as j * vectorValue as j + vectorValue bs (j + 1) * vectorValue bs (j + 1)
                    | i == j + 1 = vectorValue bs (j + 1) * vectorValue as (j + 1)
                    | j == i + 1 = vectorValue as j * vectorValue bs j
                    | otherwise = 0
            projected <-
                fromListChecked (width + 1) width [entry i j | i <- [0 .. width], j <- [0 .. width - 1]]
            y <- leastSquares projected (gamma : replicate width 0)
            let x = addV x0 (combine basis y)
            finiteValues x
            if leastConverged options matrix b (residual matrix b x)
                then result matrix b width x
                else
                    if alphan == 0 || beta == 0
                        then Left (DomainError "LSMR invariant-subspace breakdown")
                        else loop width gamma un (basis ++ [vn]) as bs

{- | Simultaneous Jacobi stationary iteration. Convergence requires an appropriate
splitting (for example strict diagonal dominance); it is not assumed.
-}
jacobiSolve ::
    (RealFloat a) =>
    IterativeOptions a ->
    Matrix a ->
    [a] ->
    [a] ->
    Either MathError (IterativeResult a)
jacobiSolve = stationary False 1

-- | Forward Gauss--Seidel stationary iteration.
gaussSeidelSolve ::
    (RealFloat a) =>
    IterativeOptions a ->
    Matrix a ->
    [a] ->
    [a] ->
    Either MathError (IterativeResult a)
gaussSeidelSolve = stationary True 1

-- | Successive over-relaxation, requiring a finite relaxation 0<omega<2.
sorSolve ::
    (RealFloat a) =>
    IterativeOptions a ->
    a ->
    Matrix a ->
    [a] ->
    [a] ->
    Either MathError (IterativeResult a)
sorSolve options omega = stationary True omega options

stationary ::
    (RealFloat a) =>
    Bool ->
    a ->
    IterativeOptions a ->
    Matrix a ->
    [a] ->
    [a] ->
    Either MathError (IterativeResult a)
stationary sequential omega options matrix b x0
    | not (finite omega) || omega <= 0 || omega >= 2 =
        Left (InvalidArgument "SOR relaxation must lie in (0,2)")
    | otherwise = do
        validateProblem True options matrix b x0
        checkPivots [value a i i | i <- [0 .. n - 1]]
        go 0 x0
  where
    a = entries matrix
    n = length a
    go k x
        | converged options b (residual matrix b x) = result matrix b k x
        | k == maximumIterations options = Left (NonConvergence "stationary iteration" k)
        | otherwise = do
            let update acc i =
                    let use = if sequential then acc else x
                        rhs = vectorValue b i - sum [value a i j * vectorValue use j | j <- [0 .. n - 1], j /= i]
                        new = (1 - omega) * vectorValue x i + omega * rhs / value a i i
                     in replaceAt i new acc
                xn = foldl update x [0 .. n - 1]
            finiteValues xn
            go (k + 1) xn

{- | Residual-correction refinement using a reusable partial-pivoted LU.
Residuals and corrections use the scalar type's precision. This does not claim
mixed-precision accuracy; callers may provide an initial guess from any solver.
-}
iterativeRefinement ::
    (RealFloat a) =>
    IterativeOptions a ->
    Matrix a ->
    [a] ->
    [a] ->
    Either MathError (IterativeResult a)
iterativeRefinement options matrix b x0 = do
    validateProblem True options matrix b x0
    factors <- luDecomposeWithTolerance 0 matrix
    let go k x
            | converged options b (residual matrix b x) = result matrix b k x
            | k == maximumIterations options = Left (NonConvergence "iterative refinement" k)
            | otherwise = do
                correction <- solveLU factors (residual matrix b x)
                let xn = addV x correction
                finiteValues xn
                go (k + 1) xn
    go 0 x0

validateProblem ::
    (RealFloat a) =>
    Bool ->
    IterativeOptions a ->
    Matrix a ->
    [a] ->
    [a] ->
    Either MathError ()
validateProblem square options matrix b x = do
    if any (\v -> not (finite v) || v < 0) [absoluteTolerance options, relativeTolerance options]
        then Left InvalidTolerance
        else Right ()
    if maximumIterations options < 0
        then Left (InvalidArgument "negative iteration budget")
        else Right ()
    let (m, n) = shape matrix
    if square && m /= n then Left (NonSquareMatrix (m, n)) else Right ()
    finiteMatrix matrix
    validateVector m b
    validateVector n x

squareFinite :: (RealFloat a) => Matrix a -> Either MathError Int
squareFinite matrix = do
    let (m, n) = shape matrix
    if m /= n then Left (NonSquareMatrix (m, n)) else finiteMatrix matrix >> Right n

symmetricFinite :: (RealFloat a) => Matrix a -> Either MathError Int
symmetricFinite matrix = do
    n <- squareFinite matrix
    let a = entries matrix
    if and [value a i j == value a j i | i <- [0 .. n - 1], j <- [0 .. i - 1]]
        then Right n
        else Left (DomainError "symmetric solver requires an exactly symmetric matrix")

validateVector :: (RealFloat a) => Int -> [a] -> Either MathError ()
validateVector n xs
    | length xs /= n = Left (VectorLengthMismatch n (length xs))
    | otherwise = finiteValues xs

checkPivots :: (Eq a, Num a) => [a] -> Either MathError ()
checkPivots xs = case [i | (i, x) <- zip [0 ..] xs, x == 0] of
    i : _ -> Left (SingularMatrix i)
    [] -> Right ()

result :: (RealFloat a) => Matrix a -> [a] -> Int -> [a] -> Either MathError (IterativeResult a)
result matrix b k x = do
    finiteValues x
    let r = residual matrix b x
        normal = matvec (transposeMatrix matrix) r
        rn = stableNorm r
        an = stableNorm normal
    finiteValues r
    finiteValues normal
    if all finite [rn, an] then Right (IterativeResult x k rn an) else Left NonFiniteResult

converged :: (RealFloat a) => IterativeOptions a -> [a] -> [a] -> Bool
converged options b r =
    let norm = stableNorm r
        threshold = absoluteTolerance options + relativeTolerance options * stableNorm b
     in all finite r && all finite b && finite norm && finite threshold && norm <= threshold

leastConverged :: (RealFloat a) => IterativeOptions a -> Matrix a -> [a] -> [a] -> Bool
leastConverged options matrix b r =
    all finite r
        && ( converged options b r
                || converged options (matvec (transposeMatrix matrix) b) (matvec (transposeMatrix matrix) r)
           )

finite :: (RealFloat a) => a -> Bool
finite x = not (isNaN x || isInfinite x)

matvec :: (Num a) => Matrix a -> [a] -> [a]
matvec a x = map (`dotV` x) (entries a)

residual :: (Num a) => Matrix a -> [a] -> [a] -> [a]
residual a b x = subV b (matvec a x)

scaleV :: (Num a) => a -> [a] -> [a]
scaleV a = map (a *)

addV :: (Num a) => [a] -> [a] -> [a]
addV = zipWith (+)

subV :: (Num a) => [a] -> [a] -> [a]
subV = zipWith (-)

normalize :: (RealFloat a) => [a] -> [a]
normalize xs = let n = stableNorm xs in if n == 0 then map (const 0) xs else scaleV (1 / n) xs

combine :: (Num a) => [[a]] -> [a] -> [a]
combine basis ys = foldl addV (replicate dimension 0) (zipWith scaleV ys basis)
  where
    dimension = case basis of row : _ -> length row; [] -> 0

orthogonalize :: (RealFloat a) => [[a]] -> [a] -> ([a], [a])
orthogonalize basis w0 =
    let (hs, w) = pass w0; (correction, wn) = pass w
     in (zipWith (+) hs correction, wn)
  where
    pass w =
        foldl
            ( \(hs, current) q ->
                let h = dotV q current
                 in (hs ++ [h], subV current (scaleV h q))
            )
            ([], w)
            basis

vectorValue :: (Num a) => [a] -> Int -> a
vectorValue xs i = sum (take 1 (drop i xs))

vectorAt :: Int -> [[a]] -> [a]
vectorAt i rows = concat (take 1 (drop i rows))

value :: (Num a) => [[a]] -> Int -> Int -> a
value rows i j = vectorValue (vectorAt i rows) j

replaceAt :: Int -> a -> [a] -> [a]
replaceAt i x xs = take i xs ++ x : drop (i + 1) xs

setValue :: Int -> Int -> a -> [[a]] -> [[a]]
setValue i j x rows = replaceAt i (replaceAt j x (vectorAt i rows)) rows
