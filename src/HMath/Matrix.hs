-- SPDX-License-Identifier: MPL-2.0

-- | Dense matrices with finite, row-major storage and zero-based indices.
--
-- The constructor is hidden so the stored element count always agrees with the
-- shape. Zero rows and zero columns are valid and retain their shape. Checked
-- operations describe invalid inputs with 'MathError'; the corresponding
-- 'Maybe' operations retain the original failure convention.
module HMath.Matrix
    ( Matrix
    , fromList
    , fromListChecked
    , toList
    , shape
    , zeroMatrix
    , zeroMatrixChecked
    , diagonal
    , diagonalChecked
    , at
    , atChecked
    , sliceMatrix
    , sliceMatrixChecked
    , reshape
    , reshapeChecked
    , addMatrix
    , addMatrixChecked
    , subtractMatrix
    , subtractMatrixChecked
    , hadamard
    , hadamardChecked
    , scaleMatrix
    , multiply
    , multiplyChecked
    , transposeMatrix
    , identity
    , identityChecked
    ) where

import Data.List (transpose)
import HMath.Error (MathError(..))

-- | An abstract dense matrix with explicit dimensions and flat row-major
-- storage. Empty shapes require no list of empty rows. 'Show' displays the
-- internal representation for inspection; it is not a serialization format.
data Matrix a = Matrix Int Int [a]
    deriving (Eq, Show)

-- | Construct a matrix from a finite list in row-major order. Negative shapes,
-- shapes whose element count exceeds @maxBound :: Int@, and incorrect list
-- lengths fail.
fromList :: Int -> Int -> [a] -> Maybe (Matrix a)
fromList rows cols = toMaybe . fromListChecked rows cols

-- | Checked 'fromList'. The shape is validated before inspecting the list.
fromListChecked :: Int -> Int -> [a] -> Either MathError (Matrix a)
fromListChecked rows cols values = do
    expected <- elementCount rows cols
    let actual = length values
    if expected == actual
        then Right (Matrix rows cols values)
        else Left (ElementCountMismatch expected actual)

-- | Return all elements in row-major order.
toList :: Matrix a -> [a]
toList (Matrix _ _ values) = values

-- | Return @(rows, columns)@, including either dimension of an empty matrix.
shape :: Matrix a -> (Int, Int)
shape (Matrix rows cols _) = (rows, cols)

-- | Construct a matrix filled with zeros, subject to the same shape checks as
-- 'fromList'.
zeroMatrix :: Num a => Int -> Int -> Maybe (Matrix a)
zeroMatrix rows cols = toMaybe (zeroMatrixChecked rows cols)

-- | Checked 'zeroMatrix'.
zeroMatrixChecked :: Num a => Int -> Int -> Either MathError (Matrix a)
zeroMatrixChecked rows cols = do
    count <- elementCount rows cols
    Right (Matrix rows cols (replicate count 0))

-- | Construct a square matrix with the finite input list on its diagonal and
-- zeros elsewhere. An empty list produces a @0 x 0@ matrix.
diagonal :: Num a => [a] -> Maybe (Matrix a)
diagonal = toMaybe . diagonalChecked

-- | Checked 'diagonal'. Rejects a square shape whose element count overflows.
diagonalChecked :: Num a => [a] -> Either MathError (Matrix a)
diagonalChecked values = do
    let n = length values
    _ <- elementCount n n
    Right (Matrix n n (concatMap (diagonalRow n) (zip [0..] values)))

-- | Look up an element using zero-based row and column indices.
at :: Matrix a -> Int -> Int -> Maybe a
at matrix row col = toMaybe (atChecked matrix row col)

-- | Checked 'at'. Empty matrices have no valid element indices.
atChecked :: Matrix a -> Int -> Int -> Either MathError a
atChecked (Matrix rows cols values) row col
    | row < 0 || col < 0 || row >= rows || col >= cols = invalid
    | otherwise = case drop (row * cols + col) values of
        value : _ -> Right value
        [] -> invalid
    where
        invalid = Left (IndexOutOfBounds (rows, cols) (row, col))

-- | Extract a slice given its @(startRow, startColumn)@ and
-- @(rowCount, columnCount)@. Extents must be nonnegative and contained within
-- the matrix. A zero extent may start at the corresponding shape endpoint.
sliceMatrix :: (Int, Int) -> (Int, Int) -> Matrix a -> Maybe (Matrix a)
sliceMatrix start extent = toMaybe . sliceMatrixChecked start extent

-- | Checked 'sliceMatrix'. Extent shapes are validated before bounds; bounds
-- checks avoid adding the start and extent, which could overflow.
sliceMatrixChecked
    :: (Int, Int) -> (Int, Int) -> Matrix a -> Either MathError (Matrix a)
sliceMatrixChecked start@(startRow, startCol) extent@(height, width)
        (Matrix rows cols values) = do
    count <- elementCount height width
    if startRow < 0 || startCol < 0 || startRow > rows || startCol > cols
            || height > rows - startRow || width > cols - startCol
        then Left (SliceOutOfBounds (rows, cols) start extent)
        else Right (Matrix height width (sliceValues count))
    where
        sliceValues 0 = []
        sliceValues _ = concatMap (take width . drop startCol)
            (take height (drop startRow (chunks cols values)))

-- | Change the shape while preserving row-major element order. The new shape
-- must contain exactly the same number of elements.
reshape :: Int -> Int -> Matrix a -> Maybe (Matrix a)
reshape rows cols = toMaybe . reshapeChecked rows cols

-- | Checked 'reshape'. Validate the target shape before comparing counts.
reshapeChecked :: Int -> Int -> Matrix a -> Either MathError (Matrix a)
reshapeChecked rows cols (Matrix oldRows oldCols values) = do
    expected <- elementCount rows cols
    let actual = oldRows * oldCols
    if expected == actual
        then Right (Matrix rows cols values)
        else Left (ElementCountMismatch expected actual)

-- | Add matrices with equal shapes.
addMatrix :: Num a => Matrix a -> Matrix a -> Maybe (Matrix a)
addMatrix a b = toMaybe (addMatrixChecked a b)

-- | Checked 'addMatrix'.
addMatrixChecked :: Num a => Matrix a -> Matrix a -> Either MathError (Matrix a)
addMatrixChecked = zipMatrixChecked (+)

-- | Subtract matrices with equal shapes.
subtractMatrix :: Num a => Matrix a -> Matrix a -> Maybe (Matrix a)
subtractMatrix a b = toMaybe (subtractMatrixChecked a b)

-- | Checked 'subtractMatrix'.
subtractMatrixChecked
    :: Num a => Matrix a -> Matrix a -> Either MathError (Matrix a)
subtractMatrixChecked = zipMatrixChecked (-)

-- | Multiply corresponding elements of matrices with equal shapes.
hadamard :: Num a => Matrix a -> Matrix a -> Maybe (Matrix a)
hadamard a b = toMaybe (hadamardChecked a b)

-- | Checked 'hadamard'.
hadamardChecked :: Num a => Matrix a -> Matrix a -> Either MathError (Matrix a)
hadamardChecked = zipMatrixChecked (*)

-- | Multiply every element by the scalar, preserving the shape.
scaleMatrix :: Num a => a -> Matrix a -> Matrix a
scaleMatrix scalar (Matrix rows cols values) =
    Matrix rows cols (map (scalar *) values)

-- | Swap rows and columns. This preserves zero dimensions, so transposing
-- twice returns the original matrix even when one dimension is zero.
transposeMatrix :: Matrix a -> Matrix a
transposeMatrix (Matrix rows cols values)
    | rows == 0 || cols == 0 = Matrix cols rows []
    | otherwise = Matrix cols rows (concat (transpose (chunks cols values)))

-- | Matrix product when the left column count equals the right row count and
-- the output element count fits in 'Int'. A product with zero inner dimension
-- contains zeros, with the full output shape preserved.
multiply :: Num a => Matrix a -> Matrix a -> Maybe (Matrix a)
multiply a b = toMaybe (multiplyChecked a b)

-- | Checked 'multiply'. Inner dimensions are checked before the output shape.
multiplyChecked :: Num a => Matrix a -> Matrix a -> Either MathError (Matrix a)
multiplyChecked (Matrix r1 c1 a) (Matrix r2 c2 b)
    | c1 /= r2 = Left (InnerDimensionMismatch c1 r2)
    | otherwise = do
        count <- elementCount r1 c2
        Right (Matrix r1 c2 (result count))
    where
        -- Empty outputs and zero inner dimensions must not enumerate empty
        -- input rows; their dimension may be as large as maxBound :: Int.
        result 0 = []
        result count
            | c1 == 0 = replicate count 0
            | otherwise =
                [ sum (zipWith (*) row col)
                | row <- chunks c1 a
                , col <- columns
                ]
        columns = transpose (chunks c2 b)

-- | Construct a square identity matrix of nonnegative order. The element
-- count must fit in 'Int'.
identity :: Num a => Int -> Maybe (Matrix a)
identity = toMaybe . identityChecked

-- | Checked 'identity'.
identityChecked :: Num a => Int -> Either MathError (Matrix a)
identityChecked n = do
    _ <- elementCount n n
    Right (Matrix n n (concatMap (\i -> diagonalRow n (i, 1)) [0..n - 1]))

-- Validate with unbounded arithmetic before any Int multiplication or storage
-- allocation. Every constructor and shape-changing operation uses this gate.
elementCount :: Int -> Int -> Either MathError Int
elementCount rows cols
    | rows < 0 || cols < 0 = Left (NegativeDimensions (rows, cols))
    | count > toInteger (maxBound :: Int) =
        Left (ElementCountOverflow (rows, cols))
    | otherwise = Right (fromInteger count)
    where
        count = toInteger rows * toInteger cols

zipMatrixChecked
    :: (a -> b -> c) -> Matrix a -> Matrix b -> Either MathError (Matrix c)
zipMatrixChecked operation (Matrix r1 c1 a) (Matrix r2 c2 b)
    | r1 /= r2 || c1 /= c2 = Left (ShapeMismatch (r1, c1) (r2, c2))
    | otherwise = Right (Matrix r1 c1 (zipWith operation a b))

diagonalRow :: Num a => Int -> (Int, a) -> [a]
diagonalRow n (index, value) =
    replicate index 0 ++ value : replicate (n - index - 1) 0

-- Only positive widths are needed for stored elements. Handling zero here
-- explicitly also prevents a non-consuming recursion for empty shapes.
chunks :: Int -> [a] -> [[a]]
chunks width values
    | width <= 0 = []
    | otherwise = case values of
        [] -> []
        _ -> let (row, rest) = splitAt width values
             in row : chunks width rest

toMaybe :: Either e a -> Maybe a
toMaybe = either (const Nothing) Just
