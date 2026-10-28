-- SPDX-License-Identifier: MPL-2.0

{- | Errors shared by the checked linear algebra APIs. Shapes and indices are
@(rows, columns)@ pairs. Generic matrix/vector arithmetic follows its numeric
type; the LU APIs additionally check finite inputs and arithmetic results.
-}
module HMath.Error (MathError (..)) where

-- | A failed input contract or LU numerical check.
data MathError
    = -- | A requested shape contains a negative dimension.
      NegativeDimensions (Int, Int)
    | -- | A shape's element count exceeds @maxBound :: Int@.
      ElementCountOverflow (Int, Int)
    | -- | Expected element count, then actual element count.
      ElementCountMismatch Int Int
    | -- | Left and right shapes differ for an elementwise operation.
      ShapeMismatch (Int, Int) (Int, Int)
    | -- | Left column count and right row count differ for multiplication.
      InnerDimensionMismatch Int Int
    | -- | Matrix shape, then the invalid zero-based index.
      IndexOutOfBounds (Int, Int) (Int, Int)
    | -- | Matrix shape, slice start, and slice extent.
      SliceOutOfBounds (Int, Int) (Int, Int) (Int, Int)
    | -- | Left and right finite-list lengths differ.
      VectorLengthMismatch Int Int
    | -- | A factorization requires equal row and column counts.
      NonSquareMatrix (Int, Int)
    | -- | A relative pivot tolerance is negative, NaN, or infinite.
      InvalidTolerance
    | -- | An exactly zero pivot, at the given zero-based elimination step.
      SingularMatrix Int
    | -- | A nonzero pivot is at or below the relative tolerance threshold.
      NearSingularMatrix Int
    | -- | The first NaN or infinite matrix entry, in row-major order.
      NonFiniteMatrixEntry (Int, Int)
    | -- | The first NaN or infinite vector entry, by zero-based index.
      NonFiniteVectorEntry Int
    | -- | LU arithmetic produced a NaN or infinity, including overflow.
      NonFiniteResult
    | -- | Expected right-hand-side row count, then actual row count.
      RightHandSideMismatch Int Int
    | -- | An operation's mathematical input domain was violated.
      DomainError String
    | -- | A configuration, shape, or index argument is invalid.
      InvalidArgument String
    | -- | Algorithm name and exhausted iteration or evaluation budget.
      NonConvergence String Int
    | -- | Estimated numerical rank is insufficient for the requested solve.
      RankDeficient Int
    | -- | A Cholesky pivot is not strictly positive, at a zero-based index.
      NotPositiveDefinite Int
    deriving (Eq, Show)
