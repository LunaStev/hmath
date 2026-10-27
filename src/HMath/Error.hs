-- SPDX-License-Identifier: MPL-2.0

-- | Validation errors shared by the checked, finite-list linear algebra APIs.
-- Shapes and indices are @(rows, columns)@ pairs. These errors describe input
-- contracts; arithmetic follows the chosen numeric type and does not trap its
-- overflow, non-finite values, or exceptions.
module HMath.Error (MathError(..)) where

-- | A failed shape, element-count, or bounds check.
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
    deriving (Eq, Show)
