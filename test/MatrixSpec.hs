-- SPDX-License-Identifier: MPL-2.0

module MatrixSpec (matrixTests) where

import HMath

-- Integer fixtures keep the algebraic properties exact, including the empty
-- shapes that cannot be distinguished from their element lists alone.
matrixTests :: [(String, Bool)]
matrixTests =
    [ ("matrix construction preserves every small rectangular shape", all constructionCase smallShapes)
    , ("matrix construction rejects every small incorrect element count", all countMismatchCase smallShapes)
    , ("matrix transpose matches a coordinate model", all transposeCase smallShapes)
    , ("matrix transpose is an involution for empty and nonempty shapes", all transposeInvolutionCase smallShapes)
    , ("matrix indexing matches every valid small coordinate", all indexingCase validCoordinates)
    , ("matrix indexing rejects negative and endpoint coordinates", all invalidIndexCase invalidCoordinates)
    , ("matrix slices match all 400 valid small rectangles", all sliceCase validSlices)
    , ("matrix reshape preserves row-major order for every compatible small shape", all reshapeCase compatibleReshapes)
    , ("matrix reshape rejects incompatible element counts", all reshapeMismatchCase incompatibleReshapes)
    , ("matrix addition, subtraction, Hadamard product and scale preserve shape and values", all elementwiseCase smallShapes)
    , ("matrix elementwise operations reject every small shape mismatch", all shapeMismatchCase mismatchedShapes)
    , ("matrix additive identities include zero-row and zero-column shapes", all additiveIdentityCase smallShapes)
    , ("matrix addition is associative", all additionAssociativityCase smallShapes)
    , ("matrix multiplication matches 64 independent coordinate sums", all multiplyCase dimensionTriples)
    , ("matrix multiplication rejects every small inner-dimension mismatch", all innerMismatchCase mismatchedInnerDimensions)
    , ("matrix multiplication has left and right identities for all small shapes", all multiplicativeIdentityCase smallShapes)
    , ("matrix multiplication is associative for 256 compatible shape chains", all multiplicationAssociativityCase dimensionQuadruples)
    , ("matrix multiplication distributes over addition", all distributivityCase dimensionTriples)
    , ("matrix product transpose reverses the factors", all productTransposeCase dimensionTriples)
    , ("matrix zero constructor preserves all small shapes", all zeroCase smallShapes)
    , ("matrix identity constructor matches every small diagonal", all identityCase smallDimensions)
    , ("matrix diagonal constructor preserves row-major order", all diagonalCase [[], [7], [2, -3], [1, 0, -2 :: Integer]])
    , ("matrix 2x0 multiplied by 0x3 yields six zeros", explicitZeroInnerProduct)
    , ("matrix row-major slice selects the requested rectangle", rowMajorSlice)
    , ("matrix row-major reshape reorders no values", rowMajorReshape)
    , ("matrix checked construction reports negative rows", fromListChecked (-1) 2 ([] :: [Integer]) == Left (NegativeDimensions (-1, 2)))
    , ("matrix checked construction reports negative columns", fromListChecked 2 (-1) ([] :: [Integer]) == Left (NegativeDimensions (2, -1)))
    , ("matrix construction checks dimensions before touching values", fromListChecked (-1) 0 unavailableValues == Left (NegativeDimensions (-1, 0)))
    , ("matrix construction detects element-count overflow before touching values", fromListChecked maxBound 2 unavailableValues == Left (ElementCountOverflow (maxBound, 2)))
    , ("matrix construction detects overflow in either dimension order", fromListChecked 2 maxBound unavailableValues == Left (ElementCountOverflow (2, maxBound)))
    , ("matrix construction reports too few elements", fromListChecked 2 2 [1, 2, 3 :: Integer] == Left (ElementCountMismatch 4 3))
    , ("matrix construction reports too many elements", fromListChecked 1 2 [1, 2, 3 :: Integer] == Left (ElementCountMismatch 2 3))
    , ("matrix construction rejects data for zero-area shape", fromListChecked 2 0 [1 :: Integer] == Left (ElementCountMismatch 0 1))
    , ("matrix legacy construction maps checked failures to Nothing", fromList maxBound 2 unavailableValues == Nothing && fromList (-1) 0 unavailableValues == Nothing)
    , ("matrix checked zero constructor reports invalid dimensions", zeroMatrixChecked (-1) 2 == (Left (NegativeDimensions (-1, 2)) :: Either MathError (Matrix Integer)))
    , ("matrix checked zero constructor rejects product overflow", zeroMatrixChecked maxBound 2 == (Left (ElementCountOverflow (maxBound, 2)) :: Either MathError (Matrix Integer)))
    , ("matrix legacy zero constructor maps checked failures to Nothing", (zeroMatrix (-1) 2 :: Maybe (Matrix Integer)) == Nothing && zeroMatrix maxBound 2 == (Nothing :: Maybe (Matrix Integer)))
    , ("matrix checked identity reports invalid dimensions", identityChecked (-1) == (Left (NegativeDimensions (-1, -1)) :: Either MathError (Matrix Integer)))
    , ("matrix checked identity rejects product overflow", identityChecked maxBound == (Left (ElementCountOverflow (maxBound, maxBound)) :: Either MathError (Matrix Integer)))
    , ("matrix legacy identity maps checked failures to Nothing", (identity (-1) :: Maybe (Matrix Integer)) == Nothing && identity maxBound == (Nothing :: Maybe (Matrix Integer)))
    , ("matrix checked reshape reports negative dimensions", reshapeChecked (-1) 0 empty == Left (NegativeDimensions (-1, 0)))
    , ("matrix checked reshape detects product overflow before element mismatch", reshapeChecked maxBound 2 empty == Left (ElementCountOverflow (maxBound, 2)))
    , ("matrix checked slice reports negative extents", sliceMatrixChecked (0, 0) (-1, 0) sample == Left (NegativeDimensions (-1, 0)))
    , ("matrix checked slice detects extent product overflow", sliceMatrixChecked (0, 0) (maxBound, 2) sample == Left (ElementCountOverflow (maxBound, 2)))
    , ("matrix checked slice reports negative start coordinates", sliceMatrixChecked (-1, 0) (1, 1) sample == Left (SliceOutOfBounds (2, 3) (-1, 0) (1, 1)))
    , ("matrix checked slice rejects excessive row extent", sliceMatrixChecked (1, 0) (2, 1) sample == Left (SliceOutOfBounds (2, 3) (1, 0) (2, 1)))
    , ("matrix checked slice rejects excessive column extent", sliceMatrixChecked (0, 2) (1, 2) sample == Left (SliceOutOfBounds (2, 3) (0, 2) (1, 2)))
    , ("matrix checked slice rejects empty slices outside the shape", sliceMatrixChecked (3, 0) (0, 0) sample == Left (SliceOutOfBounds (2, 3) (3, 0) (0, 0)))
    , ("matrix legacy slice maps checked failures to Nothing", sliceMatrix (0, 0) (-1, 0) sample == Nothing && sliceMatrix (-1, 0) (1, 1) sample == Nothing)
    , ("matrix legacy reshape maps checked failures to Nothing", reshape (-1) 0 empty == Nothing && reshape maxBound 2 empty == Nothing)
    , ("matrix maxBound-by-zero shape stays empty and transposes promptly", hugeEmptyCase maxBound 0)
    , ("matrix zero-by-maxBound shape stays empty and transposes promptly", hugeEmptyCase 0 maxBound)
    , ("matrix huge empty shapes reshape without allocating phantom rows", hugeReshape)
    , ("matrix huge empty shapes support endpoint slices", hugeEndpointSlices)
    , ("matrix slice rejects row-end overflow without wrapping", sliceMatrixChecked (maxBound, 0) (1, 0) hugeRows == Left (SliceOutOfBounds (maxBound, 0) (maxBound, 0) (1, 0)))
    , ("matrix slice rejects column-end overflow without wrapping", sliceMatrixChecked (0, maxBound) (0, 1) hugeColumns == Left (SliceOutOfBounds (0, maxBound) (0, maxBound) (0, 1)))
    , ("matrix slice rejects maxBound starts beyond a small shape", sliceMatrixChecked (maxBound, 0) (1, 0) sample == Left (SliceOutOfBounds (2, 3) (maxBound, 0) (1, 0)))
    , ("matrix huge empty indexing fails before touching elements", atChecked hugeRows 0 0 == Left (IndexOutOfBounds (maxBound, 0) (0, 0)) && atChecked hugeColumns 0 0 == Left (IndexOutOfBounds (0, maxBound) (0, 0)))
    , ("matrix multiplication rejects overflowing output dimensions", multiplyChecked hugeRows hugeColumns == Left (ElementCountOverflow (maxBound, maxBound)))
    , ("matrix legacy multiplication maps output overflow to Nothing", multiply hugeRows hugeColumns == Nothing)
    , ("matrix huge empty elementwise operations and products preserve shape", hugeEmptyOperations)
    ]

smallDimensions :: [Int]
smallDimensions = [0 .. 3]

smallShapes :: [(Int, Int)]
smallShapes = [(rows, cols) | rows <- smallDimensions, cols <- smallDimensions]

dimensionTriples :: [(Int, Int, Int)]
dimensionTriples = [(rows, inner, cols) | rows <- smallDimensions, inner <- smallDimensions, cols <- smallDimensions]

dimensionQuadruples :: [(Int, Int, Int, Int)]
dimensionQuadruples = [(a, b, c, d) | a <- smallDimensions, b <- smallDimensions, c <- smallDimensions, d <- smallDimensions]

fixtureValue :: Int -> Int -> Integer
fixtureValue salt index = toInteger ((index * 7 + salt * 3) `mod` 11 - 5)

fixture :: Int -> Int -> Int -> Matrix Integer
fixture rows cols salt = matrix rows cols [fixtureValue salt i | i <- [0 .. rows * cols - 1]]

matrix :: Int -> Int -> [Integer] -> Matrix Integer
matrix rows cols values =
    case fromListChecked rows cols values of
        Right result -> result
        Left err -> error ("Invalid matrix test fixture: " ++ show err)

empty, sample, hugeRows, hugeColumns :: Matrix Integer
empty = matrix 0 0 []
sample = matrix 2 3 [1 .. 6]
hugeRows = matrix maxBound 0 []
hugeColumns = matrix 0 maxBound []

unavailableValues :: [Integer]
unavailableValues = error "Invalid matrix dimensions must be checked before elements are inspected"

isMatrix :: (Int, Int) -> [Integer] -> Either MathError (Matrix Integer) -> Bool
isMatrix expectedShape expectedValues result =
    case result of
        Right value -> shape value == expectedShape && toList value == expectedValues
        Left _ -> False

asMaybe :: Either e a -> Maybe a
asMaybe = either (const Nothing) Just

constructionCase :: (Int, Int) -> Bool
constructionCase dims@(rows, cols) =
    let values = [0 .. toInteger (rows * cols) - 1]
        result = fromListChecked rows cols values
    in isMatrix dims values result && fromList rows cols values == asMaybe result

countMismatchCase :: (Int, Int) -> Bool
countMismatchCase (rows, cols) =
    let expected = rows * cols
        tooMany = replicate (expected + 1) (1 :: Integer)
        extraResult = fromListChecked rows cols tooMany
        tooFew = replicate (expected - 1) (1 :: Integer)
        missingResult = fromListChecked rows cols tooFew
    in extraResult == Left (ElementCountMismatch expected (expected + 1))
        && fromList rows cols tooMany == Nothing
        && (expected == 0 || (missingResult == Left (ElementCountMismatch expected (expected - 1)) && fromList rows cols tooFew == Nothing))

transposeCase :: (Int, Int) -> Bool
transposeCase (rows, cols) =
    let actual = transposeMatrix (fixture rows cols 1)
        expected = [fixtureValue 1 (r * cols + c) | c <- [0 .. cols - 1], r <- [0 .. rows - 1]]
    in shape actual == (cols, rows) && toList actual == expected

transposeInvolutionCase :: (Int, Int) -> Bool
transposeInvolutionCase (rows, cols) =
    let value = fixture rows cols 1
    in transposeMatrix (transposeMatrix value) == value

validCoordinates :: [(Int, Int, Int, Int)]
validCoordinates = [(rows, cols, r, c) | (rows, cols) <- smallShapes, r <- [0 .. rows - 1], c <- [0 .. cols - 1]]

indexingCase :: (Int, Int, Int, Int) -> Bool
indexingCase (rows, cols, r, c) =
    let value = fixture rows cols 2
        expected = fixtureValue 2 (r * cols + c)
    in atChecked value r c == Right expected && at value r c == Just expected

invalidCoordinates :: [(Int, Int, Int, Int)]
invalidCoordinates = [(rows, cols, r, c) | (rows, cols) <- smallShapes, (r, c) <- [(-1, 0), (0, -1), (rows, 0), (0, cols), (maxBound, maxBound)]]

invalidIndexCase :: (Int, Int, Int, Int) -> Bool
invalidIndexCase (rows, cols, r, c) =
    let value = fixture rows cols 2
    in atChecked value r c == Left (IndexOutOfBounds (rows, cols) (r, c)) && at value r c == Nothing

validSlices :: [(Int, Int, Int, Int, Int, Int)]
validSlices =
    [(rows, cols, r, c, height, width)
    | (rows, cols) <- smallShapes
    , r <- [0 .. rows]
    , c <- [0 .. cols]
    , height <- [0 .. rows - r]
    , width <- [0 .. cols - c]
    ]

sliceCase :: (Int, Int, Int, Int, Int, Int) -> Bool
sliceCase (rows, cols, r, c, height, width) =
    let value = fixture rows cols 3
        result = sliceMatrixChecked (r, c) (height, width) value
        expected = [fixtureValue 3 (y * cols + x) | y <- [r .. r + height - 1], x <- [c .. c + width - 1]]
    in isMatrix (height, width) expected result && sliceMatrix (r, c) (height, width) value == asMaybe result

compatibleReshapes, incompatibleReshapes :: [(Int, Int, Int, Int)]
compatibleReshapes = [(r, c, rows, cols) | (r, c) <- smallShapes, (rows, cols) <- smallShapes, r * c == rows * cols]
incompatibleReshapes = [(r, c, rows, cols) | (r, c) <- smallShapes, (rows, cols) <- smallShapes, r * c /= rows * cols]

reshapeCase :: (Int, Int, Int, Int) -> Bool
reshapeCase (r, c, rows, cols) =
    let value = fixture r c 4
        result = reshapeChecked rows cols value
    in isMatrix (rows, cols) (toList value) result && reshape rows cols value == asMaybe result

reshapeMismatchCase :: (Int, Int, Int, Int) -> Bool
reshapeMismatchCase (r, c, rows, cols) =
    let value = fixture r c 4
    in reshapeChecked rows cols value == Left (ElementCountMismatch (rows * cols) (r * c)) && reshape rows cols value == Nothing

elementwiseCase :: (Int, Int) -> Bool
elementwiseCase dims@(rows, cols) =
    let a = fixture rows cols 1
        b = fixture rows cols 2
        av = toList a
        bv = toList b
        added = addMatrixChecked a b
        subtracted = subtractMatrixChecked a b
        multiplied = hadamardChecked a b
        scaled = scaleMatrix (-3) a
    in isMatrix dims (zipWith (+) av bv) added
        && isMatrix dims (zipWith (-) av bv) subtracted
        && isMatrix dims (zipWith (*) av bv) multiplied
        && shape scaled == dims && toList scaled == map ((-3) *) av
        && addMatrix a b == asMaybe added
        && subtractMatrix a b == asMaybe subtracted
        && hadamard a b == asMaybe multiplied

mismatchedShapes :: [(Int, Int, Int, Int)]
mismatchedShapes = [(r1, c1, r2, c2) | (r1, c1) <- smallShapes, (r2, c2) <- smallShapes, (r1, c1) /= (r2, c2)]

shapeMismatchCase :: (Int, Int, Int, Int) -> Bool
shapeMismatchCase (r1, c1, r2, c2) =
    let a = fixture r1 c1 1
        b = fixture r2 c2 2
        expected = Left (ShapeMismatch (r1, c1) (r2, c2))
    in addMatrixChecked a b == expected
        && subtractMatrixChecked a b == expected
        && hadamardChecked a b == expected
        && addMatrix a b == Nothing && subtractMatrix a b == Nothing && hadamard a b == Nothing

additiveIdentityCase :: (Int, Int) -> Bool
additiveIdentityCase (rows, cols) =
    let value = fixture rows cols 1
        zero = matrix rows cols (replicate (rows * cols) 0)
    in addMatrixChecked value zero == Right value
        && addMatrixChecked zero value == Right value
        && subtractMatrixChecked value value == Right zero
        && hadamardChecked value zero == Right zero

additionAssociativityCase :: (Int, Int) -> Bool
additionAssociativityCase (rows, cols) =
    let a = fixture rows cols 1
        b = fixture rows cols 2
        c = fixture rows cols 3
        left = addMatrixChecked a b >>= (`addMatrixChecked` c)
        right = addMatrixChecked b c >>= addMatrixChecked a
    in left == right

multiplyCase :: (Int, Int, Int) -> Bool
multiplyCase (rows, inner, cols) =
    let a = fixture rows inner 1
        b = fixture inner cols 2
        result = multiplyChecked a b
        expected = [sum [fixtureValue 1 (r * inner + k) * fixtureValue 2 (k * cols + c) | k <- [0 .. inner - 1]] | r <- [0 .. rows - 1], c <- [0 .. cols - 1]]
    in isMatrix (rows, cols) expected result && multiply a b == asMaybe result

mismatchedInnerDimensions :: [(Int, Int, Int, Int)]
mismatchedInnerDimensions = [(r1, c1, r2, c2) | (r1, c1) <- smallShapes, (r2, c2) <- smallShapes, c1 /= r2]

innerMismatchCase :: (Int, Int, Int, Int) -> Bool
innerMismatchCase (r1, c1, r2, c2) =
    let a = fixture r1 c1 1
        b = fixture r2 c2 2
    in multiplyChecked a b == Left (InnerDimensionMismatch c1 r2) && multiply a b == Nothing

multiplicativeIdentityCase :: (Int, Int) -> Bool
multiplicativeIdentityCase (rows, cols) =
    let value = fixture rows cols 1
        left = identityChecked rows >>= (`multiplyChecked` value)
        right = identityChecked cols >>= multiplyChecked value
    in left == Right value && right == Right value

multiplicationAssociativityCase :: (Int, Int, Int, Int) -> Bool
multiplicationAssociativityCase (aRows, shared1, shared2, cCols) =
    let a = fixture aRows shared1 1
        b = fixture shared1 shared2 2
        c = fixture shared2 cCols 3
        left = multiplyChecked a b >>= (`multiplyChecked` c)
        right = multiplyChecked b c >>= multiplyChecked a
    in left == right

distributivityCase :: (Int, Int, Int) -> Bool
distributivityCase (rows, inner, cols) =
    let a = fixture rows inner 1
        b = fixture rows inner 2
        c = fixture inner cols 3
        d = fixture inner cols 4
        leftSum = addMatrixChecked a b >>= (`multiplyChecked` c)
        leftProducts = do
            ac <- multiplyChecked a c
            bc <- multiplyChecked b c
            addMatrixChecked ac bc
        rightSum = addMatrixChecked c d >>= multiplyChecked a
        rightProducts = do
            ac <- multiplyChecked a c
            ad <- multiplyChecked a d
            addMatrixChecked ac ad
    in leftSum == leftProducts && rightSum == rightProducts

productTransposeCase :: (Int, Int, Int) -> Bool
productTransposeCase (rows, inner, cols) =
    let a = fixture rows inner 1
        b = fixture inner cols 2
    in fmap transposeMatrix (multiplyChecked a b) == multiplyChecked (transposeMatrix b) (transposeMatrix a)

zeroCase :: (Int, Int) -> Bool
zeroCase dims@(rows, cols) =
    let result = zeroMatrixChecked rows cols :: Either MathError (Matrix Integer)
    in isMatrix dims (replicate (rows * cols) 0) result && zeroMatrix rows cols == asMaybe result

identityCase :: Int -> Bool
identityCase size =
    let result = identityChecked size :: Either MathError (Matrix Integer)
        expected = [if r == c then 1 else 0 | r <- [0 .. size - 1], c <- [0 .. size - 1]]
    in isMatrix (size, size) expected result && identity size == asMaybe result

diagonalCase :: [Integer] -> Bool
diagonalCase values =
    let size = length values
        result = diagonalChecked values
        expected = [if r == c then values !! r else 0 | r <- [0 .. size - 1], c <- [0 .. size - 1]]
    in isMatrix (size, size) expected result && diagonal values == asMaybe result

explicitZeroInnerProduct :: Bool
explicitZeroInnerProduct = isMatrix (2, 3) (replicate 6 0) (multiplyChecked (matrix 2 0 []) (matrix 0 3 []))

rowMajorSlice :: Bool
rowMajorSlice = isMatrix (2, 2) [6, 7, 10, 11] (sliceMatrixChecked (1, 1) (2, 2) (matrix 3 4 [1 .. 12]))

rowMajorReshape :: Bool
rowMajorReshape = isMatrix (3, 2) [1 .. 6] (reshapeChecked 3 2 sample)

hugeEmptyCase :: Int -> Int -> Bool
hugeEmptyCase rows cols =
    let value = matrix rows cols []
        transposed = transposeMatrix value
    in shape value == (rows, cols) && null (toList value)
        && shape transposed == (cols, rows) && null (toList transposed)
        && transposeMatrix transposed == value
        && zeroMatrixChecked rows cols == Right value

hugeReshape :: Bool
hugeReshape = reshapeChecked 0 maxBound hugeRows == Right hugeColumns
    && reshapeChecked maxBound 0 hugeColumns == Right hugeRows
    && reshapeChecked 0 0 hugeRows == Right empty

hugeEndpointSlices :: Bool
hugeEndpointSlices = sliceMatrixChecked (maxBound, 0) (0, 0) hugeRows == Right empty
    && sliceMatrixChecked (0, maxBound) (0, 0) hugeColumns == Right empty
    && sliceMatrixChecked (0, 0) (maxBound, 0) hugeRows == Right hugeRows
    && sliceMatrixChecked (0, 0) (0, maxBound) hugeColumns == Right hugeColumns
    && sliceMatrixChecked (maxBound - 1, 0) (1, 0) hugeRows == Right (matrix 1 0 [])
    && sliceMatrixChecked (0, maxBound - 1) (0, 1) hugeColumns == Right (matrix 0 1 [])

hugeEmptyOperations :: Bool
hugeEmptyOperations = all check [hugeRows, hugeColumns]
    && multiplyChecked hugeRows empty == Right hugeRows
    && multiplyChecked empty hugeColumns == Right hugeColumns
    && multiplyChecked hugeColumns hugeRows == Right empty
    where
        check value = addMatrixChecked value value == Right value
            && subtractMatrixChecked value value == Right value
            && hadamardChecked value value == Right value
            && scaleMatrix 3 value == value
