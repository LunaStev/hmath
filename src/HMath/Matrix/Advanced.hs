-- SPDX-License-Identifier: MPL-2.0

{- | Matrix constructors, products, spaces, and matrix functions. Spectral
functions are Double precision. The simple log/sqrt entries use symmetric
spectral algorithms; General variants accept nonsymmetric invertible real
matrices off the nonpositive-real spectral branch cut, with finite budgets.
Exponential uses scaling and squaring.
-}
module HMath.Matrix.Advanced (
    generateMatrix,
    triangularMatrix,
    symmetricMatrix,
    hermitianMatrix,
    permutationMatrix,
    blockMatrix,
    bandedMatrix,
    conjugateTranspose,
    zipMatrixWith,
    batchedMultiply,
    kronecker,
    khatriRao,
    matrixPower,
    trace,
    matrixNorm1,
    matrixNormInfinity,
    frobeniusNorm,
    spectralNorm,
    pseudoinverse,
    complexPseudoinverse,
    matrixRank,
    conditionNumber,
    nullSpace,
    columnSpace,
    rowSpace,
    changeCoordinates,
    matrixExp,
    matrixLog,
    matrixSqrt,
    matrixLogGeneral,
    matrixSqrtGeneral,
    polar,
) where

import Control.Monad (foldM)
import Data.Complex (Complex ((:+)), conjugate, imagPart, realPart)
import Data.List (sort)
import HMath.Error
import HMath.Matrix
import HMath.Matrix.Internal
import HMath.Matrix.LAPACK
import HMath.Matrix.LU (inverse, solve)
import Prelude hiding (log, sqrt)
import qualified Prelude as P

generateMatrix :: Int -> Int -> (Int -> Int -> a) -> Either MathError (Matrix a)
generateMatrix = build
triangularMatrix :: (Num a) => Bool -> Matrix a -> Either MathError (Matrix a)
triangularMatrix lower a = build r c (\i j -> if (lower && j <= i) || (not lower && j >= i) then get a i j else 0)
  where
    (r, c) = shape a
symmetricMatrix :: (Fractional a) => Matrix a -> Either MathError (Matrix a)
symmetricMatrix a
    | r /= c = Left (NonSquareMatrix (r, c))
    | otherwise = build r c (\i j -> (get a i j + get a j i) / 2)
  where
    (r, c) = shape a
hermitianMatrix :: (RealFloat a) => Matrix (Complex a) -> Either MathError (Matrix (Complex a))
hermitianMatrix a
    | r /= c = Left (NonSquareMatrix (r, c))
    | otherwise = build r c (\i j -> (get a i j + conjugate (get a j i)) / 2)
  where
    (r, c) = shape a
permutationMatrix :: (Num a) => [Int] -> Either MathError (Matrix a)
permutationMatrix p
    | sort p /= [0 .. n - 1] = Left (InvalidArgument "permutationMatrix: indices must be a permutation")
    | otherwise = build n n (\i j -> if p !! i == j then 1 else 0)
  where
    n = length p
blockMatrix :: [[Matrix a]] -> Either MathError (Matrix a)
blockMatrix [] = fromListChecked 0 0 []
blockMatrix blocks
    | any ((/= n) . length) blocks = Left (InvalidArgument "blockMatrix: ragged block grid")
    | n == 0 = fromListChecked 0 0 []
    | any (\row -> any ((/= fst (shape (row !! 0))) . fst . shape) row) blocks =
        Left (InvalidArgument "blockMatrix: inconsistent block-row heights")
    | any (\j -> any ((/= snd (shape ((blocks !! 0) !! j))) . snd . shape . (!! j)) blocks) [0 .. n - 1] =
        Left (InvalidArgument "blockMatrix: inconsistent block-column widths")
    | totalR > toInteger (maxBound :: Int) || totalC > toInteger (maxBound :: Int) =
        Left (InvalidArgument "blockMatrix: shape overflow")
    | otherwise =
        fromListChecked
            (fromInteger totalR)
            (fromInteger totalC)
            ( concat
                [ concat [concat [entries block !! i | block <- row] | i <- [0 .. fst (shape (row !! 0)) - 1]]
                | row <- blocks
                ]
            )
  where
    n = length (blocks !! 0)
    totalR = sum [toInteger (fst (shape (row !! 0))) | row <- blocks]
    totalC = sum [toInteger (snd (shape b)) | b <- blocks !! 0]
bandedMatrix :: (Num a) => Int -> Int -> [(Int, [a])] -> Either MathError (Matrix a)
bandedMatrix r c diagonals
    | r < 0 || c < 0 = Left (NegativeDimensions (r, c))
    | toInteger r * toInteger c > toInteger (maxBound :: Int) = Left (ElementCountOverflow (r, c))
    | any (\(k, xs) -> toInteger (length xs) /= diagonalLength k) diagonals =
        Left (InvalidArgument "bandedMatrix: diagonal length mismatch")
    | otherwise =
        build
            r
            c
            ( \i j -> sum [xs !! fromInteger (toInteger i - max 0 (-toInteger k)) | (k, xs) <- diagonals, j - i == k]
            )
  where
    diagonalLength k = max 0 (min (toInteger r) (toInteger c - toInteger k) - max 0 (-toInteger k))

conjugateTranspose :: (RealFloat a) => Matrix (Complex a) -> Matrix (Complex a)
conjugateTranspose = mapEntries conjugate . transposeMatrix
zipMatrixWith :: (a -> b -> c) -> Matrix a -> Matrix b -> Either MathError (Matrix c)
zipMatrixWith f a b
    | shape a /= shape b = Left (ShapeMismatch (shape a) (shape b))
    | otherwise = fromListChecked r c (zipWith f (toList a) (toList b))
  where
    (r, c) = shape a
batchedMultiply :: (Num a) => [Matrix a] -> [Matrix a] -> Either MathError [Matrix a]
batchedMultiply as bs
    | length as /= length bs = Left (VectorLengthMismatch (length as) (length bs))
    | otherwise = sequence (zipWith multiplyChecked as bs)
kronecker :: (Num a) => Matrix a -> Matrix a -> Either MathError (Matrix a)
kronecker a b
    | rows > toInteger (maxBound :: Int) || cols > toInteger (maxBound :: Int) =
        Left (InvalidArgument "kronecker: dimension overflow")
    | otherwise =
        build
            (fromInteger rows)
            (fromInteger cols)
            (\i j -> get a (i `div` br) (j `div` bc) * get b (i `mod` br) (j `mod` bc))
  where
    (ar, ac) = shape a
    (br, bc) = shape b
    rows = toInteger ar * toInteger br
    cols = toInteger ac * toInteger bc
khatriRao :: (Num a) => Matrix a -> Matrix a -> Either MathError (Matrix a)
khatriRao a b
    | ac /= bc = Left (InnerDimensionMismatch ac bc)
    | toInteger ar * toInteger br > toInteger (maxBound :: Int) =
        Left (InvalidArgument "khatriRao: dimension overflow")
    | otherwise = build (ar * br) ac (\i j -> get a (i `div` br) j * get b (i `mod` br) j)
  where
    (ar, ac) = shape a; (br, bc) = shape b
matrixPower :: (RealFloat a) => Integer -> Matrix a -> Either MathError (Matrix a)
matrixPower power a
    | r /= c = Left (NonSquareMatrix (r, c))
    | power < 0 = inverse a >>= matrixPower (-power)
    | otherwise = do i <- identityChecked r; go power a i
  where
    (r, c) = shape a
    go 0 _ result = Right result
    go k base result = do
        next <- if odd k then multiplyChecked result base else Right result
        if k == 1 then Right next else do squared <- multiplyChecked base base; go (k `div` 2) squared next
trace :: (Num a) => Matrix a -> Either MathError a
trace a
    | r /= c = Left (NonSquareMatrix (r, c))
    | otherwise = Right (sum [get a i i | i <- [0 .. r - 1]])
  where
    (r, c) = shape a
matrixNorm1 :: (Ord a, Num a) => Matrix a -> a
matrixNorm1 a = maximum (0 : [sum [abs (get a i j) | i <- [0 .. r - 1]] | j <- [0 .. c - 1]])
  where
    (r, c) = shape a
matrixNormInfinity :: (Ord a, Num a) => Matrix a -> a
matrixNormInfinity a
    | null (toList a) = 0
    | otherwise = maximum (0 : map (sum . map abs) (entries a))
frobeniusNorm :: (RealFloat a) => Matrix a -> a
frobeniusNorm = stableNorm . toList
spectralNorm :: Matrix Double -> Either MathError Double
spectralNorm a = maximum . (0 :) . singularValues <$> svd a
validTol :: Double -> Either MathError ()
validTol t
    | t < 0 || isNaN t || isInfinite t = Left InvalidTolerance
    | otherwise = Right ()
matrixRank :: Double -> Matrix Double -> Either MathError Int
matrixRank tol a = do
    validTol tol
    f <- svd a
    let s = singularValues f; biggest = maximum (0 : s)
    Right (length [x | x <- s, x > 0, tol == 0 || x / biggest > tol])
pseudoinverse :: Double -> Matrix Double -> Either MathError (Matrix Double)
pseudoinverse tol a = do
    validTol tol
    f <- svd a
    let s = singularValues f; biggest = maximum (0 : s); k = length s
    d <- diagonalChecked [if x > 0 && (tol == 0 || x / biggest > tol) then 1 / x else 0 | x <- s]
    utd <- multiplyChecked d (transposeMatrix (svdU f))
    result <- multiplyChecked (transposeMatrix (svdVT f)) utd
    if k == 0
        then zeroMatrixChecked (snd (shape a)) (fst (shape a))
        else finiteMatrix result >> Right result
conditionNumber :: Matrix Double -> Either MathError Double
conditionNumber a = do
    f <- svd a
    case singularValues f of
        [] -> Right 1
        xs -> Right (if minimum xs == 0 then 1 / 0 else maximum xs / minimum xs)
columnSpace :: Double -> Matrix Double -> Either MathError (Matrix Double)
columnSpace tol a = do rank <- matrixRank tol a; f <- svd a; sliceMatrixChecked (0, 0) (fst (shape a), rank) (svdU f)
rowSpace :: Double -> Matrix Double -> Either MathError (Matrix Double)
rowSpace tol a = columnSpace tol (transposeMatrix a)
nullSpace :: Double -> Matrix Double -> Either MathError (Matrix Double)
nullSpace tol a = do
    validTol tol
    f <- fullSVD a
    rank <- matrixRank tol a
    let n = snd (shape a)
    sliceMatrixChecked (0, rank) (n, n - rank) (transposeMatrix (svdVT f))
changeCoordinates :: (RealFloat a) => Matrix a -> Matrix a -> [a] -> Either MathError [a]
changeCoordinates source target coordinates = do
    rhs <- fromListChecked (length coordinates) 1 coordinates
    physical <- multiplyChecked source rhs
    solve target (toList physical)
matrixExp :: (RealFloat a) => a -> Int -> Matrix a -> Either MathError (Matrix a)
matrixExp tol budget a
    | r /= c = Left (NonSquareMatrix (r, c))
    | tol <= 0 || isNaN tol || isInfinite tol = Left InvalidTolerance
    | budget < 1 = Left (InvalidArgument "matrixExp: positive iteration budget required")
    | otherwise = do
        finiteMatrix a
        let norm = matrixNorm1 a
        if isNaN norm || isInfinite norm
            then Left NonFiniteResult
            else do
                let scaling = max 0 (if norm <= 0.5 then 0 else ceiling (P.logBase 2 norm) + 1 :: Int)
                    small = scaleMatrix (encodeFloat 1 (-scaling)) a
                i <- identityChecked r
                result <- series small 1 i i
                foldM (\x _ -> multiplyChecked x x >>= checked) result [1 .. scaling]
  where
    (r, c) = shape a
    checked x = finiteMatrix x >> Right x
    series small k term total
        | k > budget = Left (NonConvergence "matrixExp" budget)
        | otherwise = do
            productTerm <- multiplyChecked term small
            let next = scaleMatrix (1 / fromIntegral k) productTerm
            totalNext <- addMatrixChecked total next >>= checked
            if matrixNorm1 next <= tol * max 1 (matrixNorm1 totalNext)
                then Right totalNext
                else series small (k + 1) next totalNext
symmetricSpectral ::
    (Double -> Either MathError Double) -> Matrix Double -> Either MathError (Matrix Double)
symmetricSpectral f a
    | r /= c = Left (NonSquareMatrix (r, c))
    | any
        (\(x, y) -> abs (x - y) > 1e-12 * max 1 (max (abs x) (abs y)))
        (zip (toList a) (toList (transposeMatrix a))) =
        Left (DomainError "spectral function: symmetric matrix required")
    | otherwise = do
        eig <- symmetricEigen a
        values <- traverse (f . realPart) (eigenvalues eig)
        if any ((> 1e-10) . abs . imagPart) (eigenvalues eig)
            then Left (DomainError "spectral function: nonreal spectrum")
            else do
                let q = mapEntries realPart (eigenvectors eig)
                d <- diagonalChecked values
                qd <- multiplyChecked q d
                result <- multiplyChecked qd (transposeMatrix q)
                finiteMatrix result >> Right result
  where
    (r, c) = shape a
matrixLog :: Matrix Double -> Either MathError (Matrix Double)
matrixLog =
    symmetricSpectral
        ( \x ->
            if x <= 0
                then Left (DomainError "matrixLog: positive definite matrix required")
                else Right (P.log x)
        )
matrixSqrt :: Matrix Double -> Either MathError (Matrix Double)
matrixSqrt =
    symmetricSpectral
        ( \x ->
            if x < -1e-12
                then Left (DomainError "matrixSqrt: positive semidefinite matrix required")
                else Right (P.sqrt (max 0 x))
        )
polar :: Matrix Double -> Either MathError (Matrix Double, Matrix Double)
polar a = do
    f <- svd a
    u <- multiplyChecked (svdU f) (svdVT f)
    d <- diagonalChecked (singularValues f)
    vd <- multiplyChecked (transposeMatrix (svdVT f)) d
    p <- multiplyChecked vd (svdVT f)
    Right (u, p)

{- | Complex128 Moore-Penrose pseudoinverse, thresholded relative to the largest
singular value. Both rectangular and rank-deficient inputs are supported.
-}
complexPseudoinverse ::
    Double -> Matrix (Complex Double) -> Either MathError (Matrix (Complex Double))
complexPseudoinverse tol a = do
    validTol tol
    f <- complexSVD a
    let values = complexSingularValues f; biggest = maximum (0 : values)
    d <-
        diagonalChecked [if x > 0 && (tol == 0 || x / biggest > tol) then (1 / x) :+ 0 else 0 | x <- values]
    du <- multiplyChecked d (conjugateTranspose (complexU f))
    result <- multiplyChecked (conjugateTranspose (complexVT f)) du
    finiteValues (concatMap (\z -> [realPart z, imagPart z]) (toList result))
    Right result

{- | Principal square root for invertible real matrices whose spectra avoid
the nonpositive real axis. This nonsymmetric reference method uses scaled
Denman-Beavers iteration with private inverse solves. The budget bounds the
number of coupled iterations; failure to meet the reconstruction tolerance
returns NonConvergence. Ill-conditioned inverse steps may report a LU error.
The existing matrixSqrt additionally handles symmetric singular PSD inputs.
-}
matrixSqrtGeneral :: Double -> Int -> Matrix Double -> Either MathError (Matrix Double)
matrixSqrtGeneral tolerance budget a = do
    generalConfiguration tolerance budget
    principalDomain a
    squareRootCore tolerance budget a

{- | Real principal matrix logarithm on the same spectral domain as
matrixSqrtGeneral. Inverse scaling by successive principal square roots makes
the Mercator series converge in matrix 1-norm. The budget bounds each phase:
root reductions, each inner Denman-Beavers solve, series terms, and the final
exponential reconstruction check. There is no unbounded convergence loop.
-}
matrixLogGeneral :: Double -> Int -> Matrix Double -> Either MathError (Matrix Double)
matrixLogGeneral tolerance budget a = do
    generalConfiguration tolerance budget
    principalDomain a
    ident <- identityChecked n
    if n == 0
        then Right a
        else do
            (scaled, rootCount) <- reduce ident 0 a
            delta <- subtractMatrixChecked scaled ident
            logarithm <- series delta 1 delta (scaleMatrix 0 delta)
            let result = mapEntries (scaleFloat rootCount) logarithm
            finiteMatrix result
            reconstructed <- matrixExp (min 1e-14 (tolerance / 16)) budget result
            residual <- relativeMatrixResidual reconstructed a
            if residual <= tolerance
                then Right result
                else Left (NonConvergence "matrixLogGeneral: exponential residual" budget)
  where
    n = fst (shape a)
    innerTolerance = min 1e-14 (tolerance / 32)
    reduce ident k current = do
        delta <- subtractMatrixChecked current ident
        let distanceFromIdentity = matrixNorm1 delta
        if isNaN distanceFromIdentity || isInfinite distanceFromIdentity
            then Left NonFiniteResult
            else
                if distanceFromIdentity <= 0.5
                    then Right (current, k)
                    else
                        if k >= budget
                            then Left (NonConvergence "matrixLogGeneral: inverse scaling" budget)
                            else squareRootCore innerTolerance budget current >>= reduce ident (k + 1)
    series delta k power total
        | k > budget = Left (NonConvergence "matrixLogGeneral: Mercator series" budget)
        | otherwise = do
            let coefficient = (if odd k then 1 else -1) / fromIntegral k
                term = scaleMatrix coefficient power
            next <- addMatrixChecked total term
            finiteMatrix next
            let termNorm = matrixNorm1 term
            if isNaN termNorm || isInfinite termNorm
                then Left NonFiniteResult
                else
                    if termNorm <= innerTolerance * max 1 (matrixNorm1 next)
                        then Right next
                        else do
                            nextPower <- multiplyChecked power delta
                            finiteMatrix nextPower
                            series delta (k + 1) nextPower next

generalConfiguration :: Double -> Int -> Either MathError ()
generalConfiguration tolerance budget
    | tolerance <= 0 || isNaN tolerance || isInfinite tolerance = Left InvalidTolerance
    | budget < 1 = Left (InvalidArgument "general matrix function: positive iteration budget required")
    | otherwise = Right ()
principalDomain :: Matrix Double -> Either MathError ()
principalDomain a = do
    spectrum <- eigen a
    if any (\value -> imagPart value == 0 && realPart value <= 0) (eigenvalues spectrum)
        then
            Left
                ( DomainError
                    "principal real matrix function: invertible matrix with no nonpositive-real-axis eigenvalues required"
                )
        else Right ()

squareRootCore :: Double -> Int -> Matrix Double -> Either MathError (Matrix Double)
squareRootCore tolerance budget a
    | n == 0 = Right a
    | isNaN inputNorm || isInfinite inputNorm = Left NonFiniteResult
    | inputNorm == 0 = Left (DomainError "matrixSqrtGeneral: invertible matrix required")
    | otherwise = do
        let scaling = floor (P.logBase 4 inputNorm) :: Int
            scaled = mapEntries (scaleFloat (-2 * scaling)) a
        finiteMatrix scaled
        ident <- identityChecked n
        root <- iterateRoot scaled 0 scaled ident
        let result = mapEntries (scaleFloat scaling) root
        finiteMatrix result
        squaredResult <- multiplyChecked result result
        residual <- relativeMatrixResidual squaredResult a
        if residual <= max tolerance (32 * epsilon (0 :: Double))
            then Right result
            else Left (NonConvergence "matrixSqrtGeneral: reconstruction residual" budget)
  where
    n = fst (shape a)
    inputNorm = matrixNorm1 a
    iterateRoot target k y z = do
        squared <- multiplyChecked y y
        residual <- relativeMatrixResidual squared target
        if residual <= tolerance
            then Right y
            else
                if k >= budget
                    then Left (NonConvergence "matrixSqrtGeneral: Denman-Beavers" budget)
                    else do
                        inverseZ <- inverse z
                        inverseY <- inverse y
                        nextY <- scaleMatrix 0.5 <$> addMatrixChecked y inverseZ
                        nextZ <- scaleMatrix 0.5 <$> addMatrixChecked z inverseY
                        finiteMatrix nextY
                        finiteMatrix nextZ
                        iterateRoot target (k + 1) nextY nextZ

-- Divide entries before subtraction to avoid overflowing a finite residual
-- when two very large finite matrices have opposite-signed coefficients.
relativeMatrixResidual :: Matrix Double -> Matrix Double -> Either MathError Double
relativeMatrixResidual actual expected = do
    finiteMatrix actual
    finiteMatrix expected
    let scale = max 1 (maximum (0 : map abs (toList expected)))
    delta <- zipMatrixWith (\x y -> x / scale - y / scale) actual expected
    let numerator = matrixNorm1 delta
        denominator = max (1 / scale) (matrixNorm1 (mapEntries (/ scale) expected))
        residual = numerator / denominator
    if isNaN residual || isInfinite residual then Left NonFiniteResult else Right residual
