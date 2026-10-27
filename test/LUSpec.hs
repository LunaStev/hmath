-- SPDX-License-Identifier: MPL-2.0

module LUSpec (luTests) where

import HMath

-- Expected systems and 2x2 determinants below use direct coordinate formulas,
-- rather than HMath multiplication or another call to the solver under test.
luTests :: [(String, Bool)]
luTests =
    [ ("LU factors reconstruct a pivoted matrix", reconstructs 1e-12 pivoted)
    , ("LU swaps earlier lower-factor multipliers with their rows", laterPivotFactors)
    , ("LU lower and upper factors have triangular structure", factorStructure)
    , ("LU permutation records final original row indices", permutationCase)
    , ("LU factors reconstruct all 496 invertible small 2x2 matrices", all (reconstructs 1e-12) smallInvertible)
    , ("LU solves independently constructed small integer systems", all smallSystemCase smallInvertible)
    , ("LU determinant agrees with every small 2x2 coordinate formula", all smallDeterminantCase smallMatrices)
    , ("LU inverse agrees with the independent 2x2 inverse formula", all smallInverseCase smallInvertible)
    , ("LU vector solve recovers a known 3x3 solution", vectorResult [1, -2, -2] (solve normal [1, -2, 0]))
    , ("LU factorization is reusable for independent right-hand sides", reusedFactor)
    , ("LU matrix solve preserves row-major multiple right-hand sides", matrixRightHandSides)
    , ("LU convenience matrix solve recovers independently known columns", matrixResult (3, 2) [1, -2, 2, 0, -1, 3] (solveMatrix pivoted rhsMatrix))
    , ("LU inverse has both left and right identity residuals", inverseResiduals)
    , ("LU determinant accounts for odd row swaps", scalarResult (-1) (determinant (matrix 2 2 [0, 1, 1, 0])))
    , ("LU determinant accounts for even row swaps", scalarResult (-4) (determinant pivoted))
    , ("LU determinant handles negative diagonal entries", scalarResult 24 (determinant (matrix 3 3 [-2, 0, 0, 0, -3, 0, 0, 0, 4])))
    , ("LU solves scalar systems", vectorResult [3] (solve (matrix 1 1 [4]) [12]))
    , ("LU inverse handles scalar matrices", matrixResult (1, 1) [0.25] (inverse (matrix 1 1 [4])))
    , ("LU supports Float decomposition and reconstruction", reconstructs 2e-5 (floatMatrix 3 3 [1, 1, 0, 3, 1, 1, 2, 4, 1]))
    , ("LU supports Float vector solves", floatSolve)
    , ("LU supports Float determinant and inverse", floatDeterminantInverse)
    , ("LU empty decomposition has empty factors and permutation", emptyFactors)
    , ("LU empty determinant is one", determinant empty == Right 1)
    , ("LU empty vector solve returns an empty vector", solve empty [] == Right [])
    , ("LU empty inverse retains 0x0 shape", inverse empty == Right empty)
    , ("LU empty matrix solve retains zero-row column count", emptyMatrixSolve)
    , ("LU empty matrix solve preserves maxBound columns promptly", hugeEmptyMatrixSolve)
    , ("LU zero-column right-hand sides preserve their row count", zeroColumnMatrixSolve)
    , ("LU rejects nonsquare coefficients before inspecting values", isError (NonSquareMatrix (1, 2)) (luDecompose (matrix 1 2 [nan, infinity])))
    , ("LU rejects nonsquare shape before invalid tolerance", isError (NonSquareMatrix (0, 2)) (luDecomposeWithTolerance (-1) (matrix 0 2 [])))
    , ("LU rejects negative tolerance", isError InvalidTolerance (luDecomposeWithTolerance (-1) normal))
    , ("LU rejects NaN and infinite tolerances", all (\t -> isError InvalidTolerance (luDecomposeWithTolerance t normal)) [nan, infinity, negate infinity])
    , ("LU validates tolerance even for empty coefficients", isError InvalidTolerance (luDecomposeWithTolerance nan empty))
    , ("LU validates tolerance before coefficient finiteness", isError InvalidTolerance (luDecomposeWithTolerance (-1) (matrix 1 1 [nan])))
    , ("LU accepts finite large tolerances with relative threshold semantics", isError (NearSingularMatrix 0) (luDecomposeWithTolerance 2 (matrix 1 1 [1])))
    , ("LU rejects NaN at its row-major coefficient coordinate", isError (NonFiniteMatrixEntry (1, 0)) (luDecompose (matrix 2 2 [1, 0, nan, 1])))
    , ("LU rejects both signs of infinite coefficients", all (\x -> isError (NonFiniteMatrixEntry (0, 1)) (luDecompose (matrix 2 2 [1, x, 0, 1]))) [infinity, negate infinity])
    , ("LU scans all coefficients before classifying a zero pivot", isError (NonFiniteMatrixEntry (0, 1)) (luDecompose (matrix 2 2 [0, nan, 0, 1])))
    , ("LU reports the first exact zero pivot", isError (SingularMatrix 0) (luDecompose (matrix 2 2 [0, 1, 0, 2])))
    , ("LU reports an exact zero pivot after elimination", isError (SingularMatrix 1) (luDecompose singular))
    , ("LU determinant maps exact singularity to zero", determinant singular == Right 0)
    , ("LU all-zero coefficients fail at the first exact pivot", isError (SingularMatrix 0) (luDecompose (matrix 2 2 [0, 0, 0, 0])))
    , ("LU determinant preserves nonfinite input errors before singularity", isError (NonFiniteMatrixEntry (0, 1)) (determinant (matrix 2 2 [0, nan, 0, 1])))
    , ("LU inverse and solve reject exact singularity", isError (SingularMatrix 1) (inverse singular) && isError (SingularMatrix 1) (solve singular [1, 2]))
    , ("LU default Double tolerance rejects a small relative pivot", isError (NearSingularMatrix 1) (luDecompose nearlySingular))
    , ("LU default tolerance scales with the matrix order", defaultToleranceBoundary)
    , ("LU determinant retains near-singular failures", isError (NearSingularMatrix 1) (determinant nearlySingular))
    , ("LU explicit tolerance includes equality at the threshold", isError (NearSingularMatrix 1) (luDecomposeWithTolerance 0.25 (matrix 2 2 [1, 0, 0, 0.25])))
    , ("LU explicit tolerance permits pivots strictly above threshold", succeeds (luDecomposeWithTolerance 0.249 (matrix 2 2 [1, 0, 0, 0.25])))
    , ("LU zero tolerance admits nonzero small relative pivots", exactOnlyTolerance)
    , ("LU zero tolerance accepts nonzero pivots whose relative ratio underflows", underflowedRatio)
    , ("LU negative zero tolerance retains exact-zero-only semantics", succeeds (luDecomposeWithTolerance (-0.0) nearlySingular))
    , ("LU zero tolerance still rejects an exact zero pivot", isError (SingularMatrix 1) (luDecomposeWithTolerance 0 singular))
    , ("LU relative threshold is invariant under coefficient scaling", relativeScaling)
    , ("LU default tolerance follows Float precision", floatTolerance)
    , ("LU checks vector right-hand-side length before finiteness", vectorLengthBeforeFiniteness)
    , ("LU reports the first nonfinite vector right-hand-side index", nonfiniteVector)
    , ("LU checks matrix right-hand-side rows before finiteness", matrixShapeBeforeFiniteness)
    , ("LU reports the row-major nonfinite matrix right-hand-side coordinate", nonfiniteMatrix)
    , ("LU convenience solve validates coefficients before its right-hand side", isError (SingularMatrix 1) (solve singular [nan]))
    , ("LU convenience matrix solve validates coefficients before its right-hand side", isError (SingularMatrix 1) (solveMatrix singular (matrix 1 1 [nan])))
    , ("LU detects nonfinite elimination results", isError NonFiniteResult (luDecompose (matrix 2 2 [1e308, 1e308, -1e308, 1e308])))
    , ("LU detects nonfinite backward solve results", isError NonFiniteResult (solve (matrix 1 1 [1e-308]) [10]))
    , ("LU detects nonfinite forward solve results", isError NonFiniteResult (solve (matrix 2 2 [1, 0, 1, 1]) [-1e308, 1e308]))
    , ("LU detects nonfinite matrix solve results", isError NonFiniteResult (solveMatrix (matrix 1 1 [1e-308]) (matrix 1 2 [1, 10])))
    , ("LU detects determinant overflow", isError NonFiniteResult (determinant (matrix 2 2 [1e200, 0, 0, 1e200])))
    , ("LU determinant avoids overflow of balanced finite products", balancedDeterminant [1e200, 1e200, 1e-200, 1e-200] 1)
    , ("LU determinant avoids underflow of balanced finite products", balancedDeterminant [1e-200, 1e-200, 1e200, 1e200] 1)
    , ("LU balanced determinant retains the diagonal sign", balancedDeterminant [-1e200, 1e200, 1e-200, 1e-200] (-1))
    ]

matrix :: Int -> Int -> [Double] -> Matrix Double
matrix = fixture

floatMatrix :: Int -> Int -> [Float] -> Matrix Float
floatMatrix = fixture

fixture :: Int -> Int -> [a] -> Matrix a
fixture rows cols values = case fromListChecked rows cols values of
    Right value -> value
    Left err -> error ("Invalid LU test fixture: " ++ show err)

normal, pivoted, singular, nearlySingular, empty, rhsMatrix :: Matrix Double
normal = matrix 3 3 [3, 2, -1, 2, -2, 4, -1, 0.5, -1]
pivoted = matrix 3 3 [1, 1, 0, 3, 1, 1, 2, 4, 1]
singular = matrix 2 2 [1, 2, 2, 4]
nearlySingular = matrix 2 2 [1, 0, 0, 1e-20]
empty = matrix 0 0 []
rhsMatrix = matrix 3 2 [3, -2, 4, -3, 9, -1]

nan, infinity :: Double
nan = 0 / 0
infinity = 1 / 0

isError :: MathError -> Either MathError a -> Bool
isError expected result = case result of
    Left actual -> actual == expected
    Right _ -> False

succeeds :: Either e a -> Bool
succeeds = either (const False) (const True)

close :: RealFloat a => a -> a -> a -> Bool
close tolerance expected actual =
    not (isNaN actual || isInfinite actual)
        && abs (expected - actual) <= tolerance * max 1 (max (abs expected) (abs actual))

closeValues :: RealFloat a => a -> [a] -> [a] -> Bool
closeValues tolerance expected actual =
    length expected == length actual && and (zipWith (close tolerance) expected actual)

scalarResult :: Double -> Either MathError Double -> Bool
scalarResult expected = either (const False) (close 1e-11 expected)

vectorResult :: [Double] -> Either MathError [Double] -> Bool
vectorResult expected = either (const False) (closeValues 1e-11 expected)

matrixResult :: (Int, Int) -> [Double] -> Either MathError (Matrix Double) -> Bool
matrixResult dims expected result = case result of
    Right actual -> shape actual == dims && closeValues 1e-11 expected (toList actual)
    Left _ -> False

-- Reconstruct PA with a coordinate loop independent of HMath multiplication.
reconstructs :: RealFloat a => a -> Matrix a -> Bool
reconstructs tolerance coefficients = case luDecompose coefficients of
    Left _ -> False
    Right factors ->
        let (n, _) = shape coefficients
            permutation = luPermutation factors
            lower = toList (luLower factors)
            upper = toList (luUpper factors)
            original = toList coefficients
            reconstructed = [sum [lower !! (r * n + k) * upper !! (k * n + c) | k <- [0 .. n - 1]] | r <- [0 .. n - 1], c <- [0 .. n - 1]]
            permuted = [original !! (r * n + c) | r <- permutation, c <- [0 .. n - 1]]
        in shape (luLower factors) == (n, n)
            && shape (luUpper factors) == (n, n)
            && length permutation == n
            && all (\r -> length (filter (== r) permutation) == 1) [0 .. n - 1]
            && closeValues tolerance permuted reconstructed

laterPivotFactors :: Bool
laterPivotFactors = case luDecompose pivoted of
    Left _ -> False
    Right factors ->
        closeValues 1e-12 [1, 0, 0, 2 / 3, 1, 0, 1 / 3, 1 / 5, 1] (toList (luLower factors))
        && closeValues 1e-12 [3, 1, 1, 0, 10 / 3, 1 / 3, 0, 0, -2 / 5] (toList (luUpper factors))

factorStructure :: Bool
factorStructure = case luDecompose normal of
    Left _ -> False
    Right factors ->
        let lower = toList (luLower factors)
            upper = toList (luUpper factors)
        in and [lower !! (r * 3 + c) == 0 | r <- [0 .. 2], c <- [r + 1 .. 2]]
            && and [lower !! (r * 3 + r) == 1 | r <- [0 .. 2]]
            && and [upper !! (r * 3 + c) == 0 | r <- [0 .. 2], c <- [0 .. r - 1]]

permutationCase :: Bool
permutationCase = case luDecompose pivoted of
    Right factors -> luPermutation factors == [1, 2, 0]
    Left _ -> False

smallMatrices, smallInvertible :: [Matrix Double]
smallMatrices = [matrix 2 2 [a, b, c, d] | a <- [-2 .. 2], b <- [-2 .. 2], c <- [-2 .. 2], d <- [-2 .. 2]]
smallInvertible = filter ((/= 0) . determinant2) smallMatrices

determinant2 :: Matrix Double -> Double
determinant2 value = case toList value of
    [a, b, c, d] -> a * d - b * c
    _ -> error "The independent determinant fixture requires 2x2 coefficients"

smallDeterminantCase :: Matrix Double -> Bool
smallDeterminantCase value = scalarResult (determinant2 value) (determinant value)

smallSystemCase :: Matrix Double -> Bool
smallSystemCase coefficients = case toList coefficients of
    [a, b, c, d] -> all (\solution -> case solution of
        [x, y] -> vectorResult solution (solve coefficients [a * x + b * y, c * x + d * y])
        _ -> False) [[-2, 3], [0, 0], [1, -1]]
    _ -> False

smallInverseCase :: Matrix Double -> Bool
smallInverseCase coefficients = case toList coefficients of
    [a, b, c, d] ->
        let det = a * d - b * c
        in matrixResult (2, 2) (map (/ det) [d, -b, -c, a]) (inverse coefficients)
    _ -> False

reusedFactor :: Bool
reusedFactor = case luDecompose pivoted of
    Left _ -> False
    Right factors -> vectorResult [1, 2, -1] (solveLU factors [3, 4, 9])
        && vectorResult [-2, 0, 3] (solveLU factors [-2, -3, -1])
        && scalarResult (-4) (determinantLU factors)

matrixRightHandSides :: Bool
matrixRightHandSides = case luDecompose pivoted of
    Left _ -> False
    Right factors -> matrixResult (3, 2) [1, -2, 2, 0, -1, 3] (solveMatrixLU factors rhsMatrix)

inverseResiduals :: Bool
inverseResiduals = case inverse normal of
    Left _ -> False
    Right inv ->
        let coefficients = toList normal
            values = toList inv
            productValues left right = [sum [left !! (r * 3 + k) * right !! (k * 3 + c) | k <- [0 .. 2]] | r <- [0 .. 2], c <- [0 .. 2]]
            unit = [1, 0, 0, 0, 1, 0, 0, 0, 1]
        in closeValues 1e-11 unit (productValues coefficients values)
            && closeValues 1e-11 unit (productValues values coefficients)

floatSolve :: Bool
floatSolve = case solve (floatMatrix 3 3 [3, 2, -1, 2, -2, 4, -1, 0.5, -1]) [1, -2, 0] of
    Right result -> closeValues 2e-5 [1, -2, -2] result
    Left _ -> False

floatDeterminantInverse :: Bool
floatDeterminantInverse =
    let value = floatMatrix 2 2 [0, 2, 1, 3]
    in case (determinant value, inverse value) of
        (Right det, Right inv) -> close 2e-5 (-2) det && closeValues 2e-5 [-1.5, 1, 0.5, 0] (toList inv)
        _ -> False

emptyFactors :: Bool
emptyFactors = case luDecompose empty of
    Left _ -> False
    Right factors -> luLower factors == empty && luUpper factors == empty
        && null (luPermutation factors) && determinantLU factors == Right 1

emptyMatrixSolve, hugeEmptyMatrixSolve, zeroColumnMatrixSolve :: Bool
emptyMatrixSolve = solveMatrix empty (matrix 0 4 []) == Right (matrix 0 4 [])
hugeEmptyMatrixSolve = solveMatrix empty (matrix 0 maxBound []) == Right (matrix 0 maxBound [])
zeroColumnMatrixSolve = solveMatrix normal (matrix 3 0 []) == Right (matrix 3 0 [])

exactOnlyTolerance :: Bool
exactOnlyTolerance = case luDecomposeWithTolerance 0 nearlySingular of
    Left _ -> False
    Right factors ->
        vectorResult [2, 3] (solveLU factors [2, 3e-20])
        && case determinantLU factors of
            Right value -> value /= 0 && abs (value / 1e-20 - 1) < 1e-12
            Left _ -> False

defaultToleranceBoundary :: Bool
defaultToleranceBoundary =
    let epsilon = encodeFloat 1 (1 - floatDigits (0 :: Double))
    in isError (NearSingularMatrix 1) (luDecompose (matrix 2 2 [1, 0, 0, 2 * epsilon]))
        && succeeds (luDecompose (matrix 2 2 [1, 0, 0, 3 * epsilon]))

underflowedRatio :: Bool
underflowedRatio = case luDecomposeWithTolerance 0 (matrix 2 2 [1e300, 0, 0, 1e-300]) of
    Left _ -> False
    Right factors -> vectorResult [1, 1] (solveLU factors [1e300, 1e-300])
        && scalarResult 1 (determinantLU factors)

relativeScaling :: Bool
relativeScaling = all (\inputScale -> isError (NearSingularMatrix 1)
    (luDecomposeWithTolerance 1e-6 (matrix 2 2 [inputScale, 0, 0, inputScale * 1e-8]))) [1e-100, 1, 1e100]

floatTolerance :: Bool
floatTolerance = isError (NearSingularMatrix 1) (luDecompose (floatMatrix 2 2 [1, 0, 0, 1e-8]))
    && succeeds (luDecompose (matrix 2 2 [1, 0, 0, 1e-8]))

vectorLengthBeforeFiniteness :: Bool
vectorLengthBeforeFiniteness = case luDecompose normal of
    Left _ -> False
    Right factors -> isError (VectorLengthMismatch 3 1) (solveLU factors [nan])
        && isError (VectorLengthMismatch 3 4) (solveLU factors [1, 2, 3, infinity])

nonfiniteVector :: Bool
nonfiniteVector = case luDecompose normal of
    Left _ -> False
    Right factors -> isError (NonFiniteVectorEntry 1) (solveLU factors [1, nan, infinity])
        && isError (NonFiniteVectorEntry 2) (solveLU factors [1, 2, negate infinity])

matrixShapeBeforeFiniteness :: Bool
matrixShapeBeforeFiniteness = case luDecompose normal of
    Left _ -> False
    Right factors -> isError (RightHandSideMismatch 3 1) (solveMatrixLU factors (matrix 1 2 [nan, infinity]))
        && isError (RightHandSideMismatch 3 0) (solveMatrixLU factors (matrix 0 maxBound []))

nonfiniteMatrix :: Bool
nonfiniteMatrix = case luDecompose normal of
    Left _ -> False
    Right factors -> isError (NonFiniteMatrixEntry (1, 1)) (solveMatrixLU factors (matrix 3 2 [1, 2, 3, nan, infinity, 6]))
        && isError (NonFiniteMatrixEntry (2, 0)) (solveMatrixLU factors (matrix 3 1 [1, 2, negate infinity]))

balancedDeterminant :: [Double] -> Double -> Bool
balancedDeterminant values expected =
    let n = length values
        coefficients = matrix n n [if r == c then values !! r else 0 | r <- [0 .. n - 1], c <- [0 .. n - 1]]
    in case luDecomposeWithTolerance 0 coefficients >>= determinantLU of
        Right actual -> close 1e-12 expected actual
        Left _ -> False
