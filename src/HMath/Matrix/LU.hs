-- SPDX-License-Identifier: MPL-2.0

-- | Dense real LU factorization with partial row pivoting. This pure reference
-- implementation accepts 'RealFloat' scalars (including 'Float' and 'Double').
-- It reuses the existing row-major 'Matrix' API and requires no native backend.
--
-- The factors satisfy @P A = L U@. Pivot acceptance uses the largest absolute
-- entry of the original matrix as a fixed scale. The default relative tolerance
-- is @n * epsilon@, where epsilon is the gap above one for the scalar type.
-- This is a pivot-size policy, not a condition-number estimate or an accuracy
-- guarantee. Use 'luDecomposeWithTolerance' to select a different policy.
--
-- All coefficients and right-hand sides must be finite. Arithmetic producing
-- NaN or infinity returns 'NonFiniteResult'; finite rounding and underflow
-- follow the scalar type. Existing generic matrix arithmetic is unchanged.
module HMath.Matrix.LU
    ( LU
    , luDecompose
    , luDecomposeWithTolerance
    , luLower
    , luUpper
    , luPermutation
    , solveLU
    , solveMatrixLU
    , solve
    , solveMatrix
    , determinantLU
    , determinant
    , inverse
    ) where

import Control.Monad (foldM)
import qualified Data.List as List
import HMath.Error (MathError(..))
import HMath.Matrix
    ( Matrix, fromListChecked, identityChecked, shape, toList )

-- | An immutable, reusable factorization. Its constructor is hidden so solves
-- can rely on square, finite factors with nonzero pivots and a valid permutation.
data LU a = LU (Matrix a) (Matrix a) [Int] Bool
    deriving (Eq, Show)

-- | Unit lower-triangular factor.
luLower :: LU a -> Matrix a
luLower (LU lower _ _ _) = lower

-- | Upper-triangular factor.
luUpper :: LU a -> Matrix a
luUpper (LU _ upper _ _) = upper

-- | Final zero-based row order: row @i@ of @P A@ is row
-- @luPermutation factors !! i@ of @A@. This is not a sequence of swap indices.
luPermutation :: LU a -> [Int]
luPermutation (LU _ _ permutation _) = permutation

-- | Factor a square matrix using the default relative pivot tolerance.
-- A @0 x 0@ matrix has a successful empty factorization.
luDecompose :: RealFloat a => Matrix a -> Either MathError (LU a)
luDecompose matrix = luDecomposeWithTolerance tolerance matrix
    where
        n = fst (shape matrix)
        prototype = case toList matrix of
            value : _ -> value
            [] -> 0
        tolerance = fromIntegral n * encodeFloat 1 (1 - floatDigits prototype)

-- | Factor with a finite, nonnegative relative tolerance. A zero tolerance
-- accepts every nonzero pivot. For positive tolerance, a nonzero pivot is
-- rejected when @abs pivot / maxAbsInput <= tolerance@. Exactly zero pivots
-- return 'SingularMatrix'; small nonzero pivots return 'NearSingularMatrix'.
--
-- Validation order is square shape, tolerance, all coefficient finiteness,
-- then elimination. Thus a nonfinite entry cannot be hidden by an earlier
-- singular pivot. Row swaps include the previously computed L multipliers.
luDecomposeWithTolerance
    :: RealFloat a => a -> Matrix a -> Either MathError (LU a)
luDecomposeWithTolerance tolerance matrix
    | rows /= cols = Left (NonSquareMatrix (rows, cols))
    | not (finite tolerance) || tolerance < 0 = Left InvalidTolerance
    | otherwise = do
        validateMatrix matrix
        factor 0 (chunks cols values) [0 .. rows - 1] False
    where
        (rows, cols) = shape matrix
        values = toList matrix
        scale = List.foldl' (\largest value -> max largest (abs value)) 0 values

        factor k packed permutation oddSwaps
            | k == rows = do
                lower <- fromListChecked rows rows (concat lowerRows)
                upper <- fromListChecked rows rows (concat upperRows)
                Right (LU lower upper permutation oddSwaps)
            | otherwise = do
                let (finished, candidates) = splitAt k packed
                    offset = pivotOffset k candidates
                    swapped = swapRows 0 offset candidates
                case swapped of
                    [] -> Left (SingularMatrix k)
                    pivotRow : otherRows -> do
                        let pivot = pivotRow !! k
                        if pivot == 0
                            then Left (SingularMatrix k)
                            else if tolerance > 0 && abs pivot / scale <= tolerance
                                then Left (NearSingularMatrix k)
                                else do
                                    remaining <- traverse (eliminate k pivotRow) otherRows
                                    factor (k + 1) (finished ++ pivotRow : remaining)
                                        (swapRows k (k + offset) permutation)
                                        (oddSwaps /= (offset /= 0))
            where
                lowerRows = zipWith lowerRow [0 ..] packed
                upperRows = zipWith upperRow [0 ..] packed
                lowerRow i row = take i row ++ 1 : replicate (rows - i - 1) 0
                upperRow i row = replicate i 0 ++ drop i row

        eliminate k pivotRow row = do
            multiplier <- checked (row !! k / (pivotRow !! k))
            let update (value, pivotValue) = do
                    productValue <- checked (multiplier * pivotValue)
                    checked (value - productValue)
            trailing <- traverse update (zip (drop (k + 1) row) (drop (k + 1) pivotRow))
            Right (take k row ++ multiplier : trailing)

-- | Solve @A x = b@ using an existing factorization. The RHS must be a finite
-- list; its length is checked before its values. Each solve preserves the
-- factorization for reuse.
solveLU :: RealFloat a => LU a -> [a] -> Either MathError [a]
solveLU factors values
    | actual /= n = Left (VectorLengthMismatch n actual)
    | otherwise = do
        validateVector values
        rhs <- fromListChecked n 1 values
        toList <$> solveMatrixLU factors rhs
    where
        n = fst (shape (luLower factors))
        actual = length values

-- | Solve @A X = B@ for any number of right-hand-side columns. Check the RHS
-- row count before its values. An @n x 0@ RHS and an empty @0 x m@ system retain
-- their exact shapes, without enumerating empty columns.
solveMatrixLU
    :: RealFloat a => LU a -> Matrix a -> Either MathError (Matrix a)
solveMatrixLU factors rhs
    | actualRows /= n = Left (RightHandSideMismatch n actualRows)
    | otherwise = do
        validateMatrix rhs
        if n == 0 || columns == 0
            then Right rhs
            else do
                intermediate <- forward lowerRows permuted []
                solution <- foldM backward [] (reverse (zip upperRows intermediate))
                fromListChecked n columns (concat solution)
    where
        n = fst (shape (luLower factors))
        (actualRows, columns) = shape rhs
        lowerRows = chunks n (toList (luLower factors))
        upperRows = chunks n (toList (luUpper factors))
        rhsRows = chunks columns (toList rhs)
        permuted = map (rhsRows !!) (luPermutation factors)

        forward [] [] known = Right known
        forward (row : remaining) (b : bs) known = do
            value <- subtractRows b (zip (take (length known) row) known)
            forward remaining bs (known ++ [value])
        -- Only internal lists derived from the same validated square order
        -- reach this branch; no user-provided dimensions can reach it.
        forward _ _ _ = Left (RightHandSideMismatch n actualRows)

        backward known (row, b) = do
            let i = n - length known - 1
            value <- subtractRows b (zip (drop (i + 1) row) known)
            result <- traverse (checked . (/ (row !! i))) value
            Right (result : known)

-- | Factor @A@ with the default tolerance and solve @A x = b@. Matrix
-- validation and factorization precede RHS validation. For repeated solves or
-- a custom tolerance, use 'luDecomposeWithTolerance' and 'solveLU'.
solve :: RealFloat a => Matrix a -> [a] -> Either MathError [a]
solve matrix rhs = luDecompose matrix >>= (`solveLU` rhs)

-- | Factor @A@ with the default tolerance and solve @A X = B@.
solveMatrix :: RealFloat a => Matrix a -> Matrix a -> Either MathError (Matrix a)
solveMatrix matrix rhs = luDecompose matrix >>= (`solveMatrixLU` rhs)

-- | Determinant from the permutation sign and diagonal of U. The finite pivots
-- are multiplied exactly as rationals and rounded once to avoid intermediate
-- product overflow/underflow. An unrepresentable final result returns
-- 'NonFiniteResult'; final underflow may produce zero and does not imply
-- singularity. The empty determinant is one.
determinantLU :: RealFloat a => LU a -> Either MathError a
determinantLU (LU _ upper _ oddSwaps) = checked (fromRational signedProduct)
    where
        n = fst (shape upper)
        diagonal = zipWith (!!) (chunks n (toList upper)) [0 ..]
        productValue = product (map toRational diagonal)
        signedProduct = if oddSwaps then negate productValue else productValue

-- | Determinant using the default factorization policy. An exactly zero pivot
-- returns zero; near-singular and nonfinite failures are propagated. Use an
-- explicit factorization and 'determinantLU' to choose another tolerance.
determinant :: RealFloat a => Matrix a -> Either MathError a
determinant matrix = case luDecompose matrix of
    Left (SingularMatrix _) -> Right 0
    Left err -> Left err
    Right factors -> determinantLU factors

-- | Invert a nonsingular square matrix by solving against the identity. The
-- inverse of the @0 x 0@ matrix is @0 x 0@. For solving a system directly,
-- prefer 'solve' or 'solveMatrix' to explicitly forming the inverse.
inverse :: RealFloat a => Matrix a -> Either MathError (Matrix a)
inverse matrix = do
    factors <- luDecompose matrix
    unit <- identityChecked (fst (shape matrix))
    solveMatrixLU factors unit

subtractRows :: RealFloat a => [a] -> [(a, [a])] -> Either MathError [a]
subtractRows = foldM subtractRow
    where
        subtractRow current (coefficient, known) = traverse update (zip current known)
            where
                update (value, component) = do
                    productValue <- checked (coefficient * component)
                    checked (value - productValue)

validateMatrix :: RealFloat a => Matrix a -> Either MathError ()
validateMatrix matrix = go 0 (toList matrix)
    where
        columns = snd (shape matrix)
        go _ [] = Right ()
        go index (value : rest)
            | finite value = go (index + 1) rest
            | otherwise = Left (NonFiniteMatrixEntry (index `div` columns, index `mod` columns))

validateVector :: RealFloat a => [a] -> Either MathError ()
validateVector = go 0
    where
        go _ [] = Right ()
        go index (value : rest)
            | finite value = go (index + 1) rest
            | otherwise = Left (NonFiniteVectorEntry index)

finite :: RealFloat a => a -> Bool
finite value = not (isNaN value || isInfinite value)

checked :: RealFloat a => a -> Either MathError a
checked value
    | finite value = Right value
    | otherwise = Left NonFiniteResult

-- Select the first maximum to make equal-magnitude pivots deterministic.
pivotOffset :: RealFloat a => Int -> [[a]] -> Int
pivotOffset _ [] = 0
pivotOffset column (row : rows) = fst (List.foldl' choose (0, abs (row !! column)) candidates)
    where
        candidates = zip [1 ..] rows
        choose best@(_, largest) (index, candidate)
            | abs (candidate !! column) > largest = (index, abs (candidate !! column))
            | otherwise = best

swapRows :: Int -> Int -> [a] -> [a]
swapRows first second values
    | first == second = values
    | otherwise = zipWith replace [0 ..] values
    where
        firstValue = values !! first
        secondValue = values !! second
        replace index value
            | index == first = secondValue
            | index == second = firstValue
            | otherwise = value

chunks :: Int -> [a] -> [[a]]
chunks _ [] = []
chunks width values = let (row, rest) = splitAt width values in row : chunks width rest
