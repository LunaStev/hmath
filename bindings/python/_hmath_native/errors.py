# SPDX-License-Identifier: MPL-2.0
"""Original Haskell MathError constructors for checked callbacks."""

from ._math_error import MathError, MathErrorKind

__all__ = [
    "DomainError",
    "ElementCountMismatch",
    "ElementCountOverflow",
    "IndexOutOfBounds",
    "InnerDimensionMismatch",
    "InvalidArgument",
    "InvalidTolerance",
    "MathError",
    "MathErrorKind",
    "NearSingularMatrix",
    "NegativeDimensions",
    "NonConvergence",
    "NonFiniteMatrixEntry",
    "NonFiniteResult",
    "NonFiniteVectorEntry",
    "NonSquareMatrix",
    "NotPositiveDefinite",
    "RankDeficient",
    "RightHandSideMismatch",
    "ShapeMismatch",
    "SingularMatrix",
    "SliceOutOfBounds",
    "VectorLengthMismatch",
]


def NegativeDimensions(shape):
    return MathError(MathErrorKind.NEGATIVE_DIMENSIONS, shape)


def ElementCountOverflow(shape):
    return MathError(MathErrorKind.ELEMENT_COUNT_OVERFLOW, shape)


def ElementCountMismatch(expected, actual):
    return MathError(MathErrorKind.ELEMENT_COUNT_MISMATCH, (expected, actual))


def ShapeMismatch(left, right):
    return MathError(MathErrorKind.SHAPE_MISMATCH, (*left, *right))


def InnerDimensionMismatch(left_columns, right_rows):
    return MathError(MathErrorKind.INNER_DIMENSION_MISMATCH, (left_columns, right_rows))


def IndexOutOfBounds(shape, index):
    return MathError(MathErrorKind.INDEX_OUT_OF_BOUNDS, (*shape, *index))


def SliceOutOfBounds(shape, start, extent):
    return MathError(MathErrorKind.SLICE_OUT_OF_BOUNDS, (*shape, *start, *extent))


def VectorLengthMismatch(expected, actual):
    return MathError(MathErrorKind.VECTOR_LENGTH_MISMATCH, (expected, actual))


def NonSquareMatrix(shape):
    return MathError(MathErrorKind.NON_SQUARE_MATRIX, shape)


def InvalidTolerance():
    return MathError(MathErrorKind.INVALID_TOLERANCE)


def SingularMatrix(index):
    return MathError(MathErrorKind.SINGULAR_MATRIX, (index,))


def NearSingularMatrix(index):
    return MathError(MathErrorKind.NEAR_SINGULAR_MATRIX, (index,))


def NonFiniteMatrixEntry(index):
    return MathError(MathErrorKind.NON_FINITE_MATRIX_ENTRY, index)


def NonFiniteVectorEntry(index):
    return MathError(MathErrorKind.NON_FINITE_VECTOR_ENTRY, (index,))


def NonFiniteResult():
    return MathError(MathErrorKind.NON_FINITE_RESULT)


def RightHandSideMismatch(expected, actual):
    return MathError(MathErrorKind.RIGHT_HAND_SIDE_MISMATCH, (expected, actual))


def DomainError(message):
    return MathError(MathErrorKind.DOMAIN_ERROR, message=message)


def InvalidArgument(message):
    return MathError(MathErrorKind.INVALID_ARGUMENT, message=message)


def NonConvergence(algorithm, iterations):
    return MathError(MathErrorKind.NON_CONVERGENCE, (iterations,), algorithm)


def RankDeficient(rank):
    return MathError(MathErrorKind.RANK_DEFICIENT, (rank,))


def NotPositiveDefinite(index):
    return MathError(MathErrorKind.NOT_POSITIVE_DEFINITE, (index,))
