# SPDX-License-Identifier: MPL-2.0
"""Original checked shapes and genuine nominal KnownNat/KnownShape witnesses."""

from ._algebra_base import invoke
from ._foundation_base import FoundationValue, _invoke, register


class Shape(FoundationValue):
    """Original HMath.API.Shape.Shape owner."""

    _source_type = "HMath.API.Shape.Shape"

    @property
    def dimensions(self):
        return shape_dimensions(self)

    @property
    def elements(self):
        return shape_elements(self)


register("HMath.API.Shape.Shape", Shape)


class StaticMatrix(FoundationValue):
    """Original HMath.API.Shape.StaticMatrix owner."""

    _source_type = "HMath.API.Shape.StaticMatrix"


register("HMath.API.Shape.StaticMatrix", StaticMatrix)


class KnownShape:
    """Original recursive type-level natural-list witness interface."""

    @staticmethod
    def reflected_shape(dimensions):
        return reflected_shape(dimensions)


class StaticTensor(FoundationValue):
    """Original HMath.API.Shape.StaticTensor owner."""

    _source_type = "HMath.API.Shape.StaticTensor"


register("HMath.API.Shape.StaticTensor", StaticTensor)


class Coordinates(FoundationValue):
    """Original HMath.API.Shape.Coordinates owner."""

    _source_type = "HMath.API.Shape.Coordinates"

    @property
    def values(self):
        return coordinate_values(self)


register("HMath.API.Shape.Coordinates", Coordinates)


def shape_dimensions(shape):
    """Original HMath.API.Shape.shapeDimensions; borrowed inputs, owned result."""
    return _invoke("hmath_shape_shape_dimensions", [["Value"]], [shape])


def shape_elements(shape):
    """Original HMath.API.Shape.shapeElements; borrowed inputs, owned result."""
    return _invoke("hmath_shape_shape_elements", [["Value"]], [shape])


def make_shape(dimensions):
    """Original HMath.API.Shape.makeShape; borrowed inputs, owned result."""
    return _invoke("hmath_shape_make_shape", [["list", ["Int"]]], [dimensions])


def scalar_shape(shape):
    """Original HMath.API.Shape.ScalarShape; borrowed inputs, owned result."""
    return _invoke("hmath_shape_scalar_shape", [["Value"]], [shape])


def vector_shape(shape):
    """Original HMath.API.Shape.VectorShape; borrowed inputs, owned result."""
    return _invoke("hmath_shape_vector_shape", [["Value"]], [shape])


def matrix_shape(shape):
    """Original HMath.API.Shape.MatrixShape; borrowed inputs, owned result."""
    return _invoke("hmath_shape_matrix_shape", [["Value"]], [shape])


def static_matrix(rows, columns, matrix):
    """Original HMath.API.Shape.staticMatrix; borrowed inputs, owned result."""
    return _invoke(
        "hmath_shape_static_matrix",
        [["Integer"], ["Integer"], ["Value"]],
        [rows, columns, matrix],
    )


def dynamic_matrix(matrix):
    """Original HMath.API.Shape.dynamicMatrix; borrowed inputs, owned result."""
    return _invoke("hmath_shape_dynamic_matrix", [["Value"]], [matrix])


def static_multiply(left, right):
    """Original HMath.API.Shape.staticMultiply; borrowed inputs, owned result."""
    return _invoke("hmath_shape_static_multiply", [["Value"], ["Value"]], [left, right])


def static_transpose(matrix):
    """Original HMath.API.Shape.staticTranspose; borrowed inputs, owned result."""
    return _invoke("hmath_shape_static_transpose", [["Value"]], [matrix])


def reflected_shape(dimensions):
    """Original HMath.API.Shape.reflectedShape; borrowed inputs, owned result."""
    return _invoke("hmath_shape_reflected_shape", [["list", ["Integer"]]], [dimensions])


def static_tensor(dimensions, tensor):
    """Original HMath.API.Shape.staticTensor; borrowed inputs, owned result."""
    return _invoke(
        "hmath_shape_static_tensor",
        [["list", ["Integer"]], ["Value"]],
        [dimensions, tensor],
    )


def dynamic_tensor(tensor):
    """Original HMath.API.Shape.dynamicTensor; borrowed inputs, owned result."""
    return _invoke("hmath_shape_dynamic_tensor", [["Value"]], [tensor])


def coordinates(length, values, *, dtype=None):
    """Construct an original Coordinates n a with explicit nominal length."""
    return invoke(
        "hmath_shape_coordinates",
        [["Integer"], ["list", ["a"]]],
        [length, values],
        "typed",
        dtype,
    )


def coordinate_values(coordinates):
    """Original HMath.API.Shape.coordinateValues; borrowed inputs, owned result."""
    return _invoke("hmath_shape_coordinate_values", [["Value"]], [coordinates])


def coordinates_to_vector(coordinates):
    """Original HMath.API.Shape.coordinatesToVector; borrowed inputs, owned result."""
    return _invoke("hmath_shape_coordinates_to_vector", [["Value"]], [coordinates])


__all__ = [
    "Coordinates",
    "KnownShape",
    "Shape",
    "StaticMatrix",
    "StaticTensor",
    "coordinate_values",
    "coordinates",
    "coordinates_to_vector",
    "dynamic_matrix",
    "dynamic_tensor",
    "make_shape",
    "matrix_shape",
    "reflected_shape",
    "scalar_shape",
    "shape_dimensions",
    "shape_elements",
    "static_matrix",
    "static_multiply",
    "static_tensor",
    "static_transpose",
    "vector_shape",
]
