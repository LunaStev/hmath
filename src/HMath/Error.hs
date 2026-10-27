-- SPDX-License-Identifier: MPL-2.0

-- | Errors shared by the checked linear algebra APIs. Shapes and indices are
-- @(rows, columns)@ pairs. Generic matrix/vector arithmetic follows its numeric
-- type; the LU APIs additionally check finite inputs and arithmetic results.
module HMath.Error (MathError(..)) where

-- | A failed input contract or LU numerical check.
data MathError
    = NegativeDimensions (Int, Int)
      -- ^ A requested shape contains a negative dimension.
    | ElementCountOverflow (Int, Int)
      -- ^ A shape's element count exceeds @maxBound :: Int@.
    | ElementCountMismatch Int Int
      -- ^ Expected element count, then actual element count.
    | ShapeMismatch (Int, Int) (Int, Int)
      -- ^ Left and right shapes differ for an elementwise operation.
    | InnerDimensionMismatch Int Int
      -- ^ Left column count and right row count differ for multiplication.
    | IndexOutOfBounds (Int, Int) (Int, Int)
      -- ^ Matrix shape, then the invalid zero-based index.
    | SliceOutOfBounds (Int, Int) (Int, Int) (Int, Int)
      -- ^ Matrix shape, slice start, and slice extent.
    | VectorLengthMismatch Int Int
      -- ^ Left and right finite-list lengths differ.
    | NonSquareMatrix (Int, Int)
      -- ^ A factorization requires equal row and column counts.
    | InvalidTolerance
      -- ^ A relative pivot tolerance is negative, NaN, or infinite.
    | SingularMatrix Int
      -- ^ An exactly zero pivot, at the given zero-based elimination step.
    | NearSingularMatrix Int
      -- ^ A nonzero pivot is at or below the relative tolerance threshold.
    | NonFiniteMatrixEntry (Int, Int)
      -- ^ The first NaN or infinite matrix entry, in row-major order.
    | NonFiniteVectorEntry Int
      -- ^ The first NaN or infinite vector entry, by zero-based index.
    | NonFiniteResult
      -- ^ LU arithmetic produced a NaN or infinity, including overflow.
    | RightHandSideMismatch Int Int
      -- ^ Expected right-hand-side row count, then actual row count.
    deriving (Eq, Show)
