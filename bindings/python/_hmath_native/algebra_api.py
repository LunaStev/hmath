# SPDX-License-Identifier: MPL-2.0
# Generated original algebra interface.
from ._algebra_base import initialize, invoke
from ._foundation_base import FoundationValue, register


class Exact(FoundationValue):
    """Original HMath.API.Algebra.Exact owner."""

    _source_type = "HMath.API.Algebra.Exact"

    def __init__(self, argument1, *, dtype=None):
        initialize(
            self,
            "hmath_algebra_api_new_exact",
            [["Rational"]],
            [argument1],
            "value",
            dtype,
        )

    @property
    def value(self):
        return get_exact(self)

    @property
    def element_type(self):
        return exact_element_type()


register("HMath.API.Algebra.Exact", Exact)


def horner(argument1, argument2, *, dtype=None):
    "Coefficients are highest degree first; an empty polynomial is zero."
    return invoke(
        "hmath_algebra_api_horner",
        [["list", ["a"]], ["a"]],
        [argument1, argument2],
        "api",
        dtype,
    )


def inner_product(argument1, argument2, *, dtype=None):
    "Return sum(conjugate a[i] * b[i]) using the Scalar and Ring operations. Equal list lengths are required; mismatch returns VectorLengthMismatch. Empty lists give the ring zero; instance arithmetic controls precision/overflow."
    return invoke(
        "hmath_algebra_api_inner_product",
        [["list", ["a"]], ["list", ["a"]]],
        [argument1, argument2],
        "api",
        dtype,
    )


def get_exact(argument1):
    "Read the original immutable public field; no numerical conversion is performed."
    return invoke("hmath_algebra_api_get_exact", [["Exact"]], [argument1], "value")


def zero(*, dtype=None):
    "Additive identity of this ring."
    return invoke("hmath_algebra_api_zero", [], [], "api", dtype)


def one(*, dtype=None):
    "Multiplicative identity of this ring."
    return invoke("hmath_algebra_api_one", [], [], "api", dtype)


def plus(argument1, argument2, *, dtype=None):
    "Add two ring elements; exact instances obey ring laws and IEEE instances retain host rounding."
    return invoke(
        "hmath_algebra_api_plus", [["a"], ["a"]], [argument1, argument2], "api", dtype
    )


def times(argument1, argument2, *, dtype=None):
    "Multiply two ring elements using the instance arithmetic."
    return invoke(
        "hmath_algebra_api_times", [["a"], ["a"]], [argument1, argument2], "api", dtype
    )


def negative(argument1, *, dtype=None):
    "Return the additive inverse of a ring element."
    return invoke("hmath_algebra_api_negative", [["a"]], [argument1], "api", dtype)


def integer(argument1, *, dtype=None):
    "Embed an unbounded Integer into the domain; instance representation/rounding rules apply."
    return invoke("hmath_algebra_api_integer", [["Integer"]], [argument1], "api", dtype)


def invert(argument1, *, dtype=None):
    "Return multiplicative inverse of a nonzero domain element, or Left MathError for zero/invalid/nonrepresentable inverse."
    return invoke("hmath_algebra_api_invert", [["a"]], [argument1], "api", dtype)


def conjugate_scalar(argument1, *, dtype=None):
    "Return scalar conjugate; real/exact instances use identity and complex instances conjugate imaginary components."
    return invoke(
        "hmath_algebra_api_conjugate_scalar", [["a"]], [argument1], "api", dtype
    )


def machine_epsilon(*, dtype=None):
    "Given a type proxy, return floating precision epsilon as Double (2^-52 for Double,2^-23 for Float)."
    return invoke("hmath_algebra_api_machine_epsilon", [], [], "api", dtype)


def finite_scalar(argument1, *, dtype=None):
    "Test whether all real/complex components are finite for this instance."
    return invoke("hmath_algebra_api_finite_scalar", [["a"]], [argument1], "api", dtype)


def rational(argument1, *, dtype=None):
    "Convert exact Rational into the domain, returning Left MathError if it cannot be represented under the instance contract."
    return invoke(
        "hmath_algebra_api_rational", [["Rational"]], [argument1], "api", dtype
    )


def matrix_dimensions(argument1):
    "Return logical (rows,columns) of a matrix-like container."
    return invoke(
        "hmath_algebra_api_matrix_dimensions", [["Matrix", ["a"]]], [argument1], "value"
    )


def matrix_elements(argument1):
    "Return matrix elements in logical row-major order."
    return invoke(
        "hmath_algebra_api_matrix_elements", [["Matrix", ["a"]]], [argument1], "value"
    )


def matrix_construct(argument1, argument2, argument3, *, dtype=None):
    "Given rows,columns,flat row-major elements, construct a matrix-like value or return checked shape/count failure."
    return invoke(
        "hmath_algebra_api_matrix_construct",
        [["Int"], ["Int"], ["list", ["a"]]],
        [argument1, argument2, argument3],
        "typed",
        dtype,
    )


def tensor_dimensions(argument1):
    "Return tensor-like dimensions in axis order; [] denotes scalar."
    return invoke(
        "hmath_algebra_api_tensor_dimensions", [["Tensor", ["a"]]], [argument1], "value"
    )


def tensor_elements(argument1):
    "Return tensor-like elements in logical row-major coordinate order."
    return invoke(
        "hmath_algebra_api_tensor_elements", [["Tensor", ["a"]]], [argument1], "value"
    )


def tensor_construct(argument1, argument2, *, dtype=None):
    "Given dimensions then flat values, construct a tensor-like value or return shape/count failure."
    return invoke(
        "hmath_algebra_api_tensor_construct",
        [["list", ["Int"]], ["list", ["a"]]],
        [argument1, argument2],
        "typed",
        dtype,
    )


def vector_plus(argument1, argument2, *, dtype=None):
    "Add identically shaped vector-space values, returning checked dimension errors on mismatch."
    return invoke(
        "hmath_algebra_api_vector_plus",
        [["Vector", ["a"]], ["Vector", ["a"]]],
        [argument1, argument2],
        "typed",
        dtype,
    )


def vector_scale(argument1, argument2, *, dtype=None):
    "Given scalar then vector-space value, return its coordinatewise scalar multiple."
    return invoke(
        "hmath_algebra_api_vector_scale",
        [["a"], ["Vector", ["a"]]],
        [argument1, argument2],
        "typed",
        dtype,
    )


def differential(argument1):
    "Extract associated differential; the Dual instance returns its tangent component."
    return invoke(
        "hmath_algebra_api_differential", [["Dual", ["a"]]], [argument1], "value"
    )


class Ring:
    """Original HMath.API.Algebra.Ring interface; methods select supported source instances."""

    zero = staticmethod(zero)
    one = staticmethod(one)
    plus = staticmethod(plus)
    times = staticmethod(times)
    negative = staticmethod(negative)
    integer = staticmethod(integer)


class Field:
    """Original HMath.API.Algebra.Field interface; methods select supported source instances."""

    invert = staticmethod(invert)


class Scalar:
    """Original HMath.API.Algebra.Scalar interface; methods select supported source instances."""

    conjugate_scalar = staticmethod(conjugate_scalar)


class FloatingPoint:
    """Original HMath.API.Algebra.FloatingPoint interface; methods select supported source instances."""

    machine_epsilon = staticmethod(machine_epsilon)
    finite_scalar = staticmethod(finite_scalar)


class Numeric:
    """Original HMath.API.Algebra.Numeric interface; methods select supported source instances."""

    rational = staticmethod(rational)


class MatrixLike:
    """Original HMath.API.Algebra.MatrixLike interface; methods select supported source instances."""

    matrix_dimensions = staticmethod(matrix_dimensions)
    matrix_elements = staticmethod(matrix_elements)
    matrix_construct = staticmethod(matrix_construct)


class TensorLike:
    """Original HMath.API.Algebra.TensorLike interface; methods select supported source instances."""

    tensor_dimensions = staticmethod(tensor_dimensions)
    tensor_elements = staticmethod(tensor_elements)
    tensor_construct = staticmethod(tensor_construct)


class VectorSpace:
    """Original HMath.API.Algebra.VectorSpace interface; methods select supported source instances."""

    vector_plus = staticmethod(vector_plus)
    vector_scale = staticmethod(vector_scale)


class Differentiable:
    """Original HMath.API.Algebra.Differentiable interface; methods select supported source instances."""

    differential = staticmethod(differential)


class Differential:
    """Original HMath.API.Algebra.Differential interface; methods select supported source instances."""

    pass


def exact_element_type():
    """Typed structural Exact element prototype for ordinary Tensor/Vector APIs."""
    from ._value import decode
    from ._value import invoke as native_invoke

    return decode(native_invoke("hmath_algebra_api_exact_element_type"))


__all__ = [
    "Differentiable",
    "Differential",
    "Exact",
    "Field",
    "FloatingPoint",
    "MatrixLike",
    "Numeric",
    "Ring",
    "Scalar",
    "TensorLike",
    "VectorSpace",
    "conjugate_scalar",
    "differential",
    "exact_element_type",
    "finite_scalar",
    "get_exact",
    "horner",
    "inner_product",
    "integer",
    "invert",
    "machine_epsilon",
    "matrix_construct",
    "matrix_dimensions",
    "matrix_elements",
    "negative",
    "one",
    "plus",
    "rational",
    "tensor_construct",
    "tensor_dimensions",
    "tensor_elements",
    "times",
    "vector_plus",
    "vector_scale",
    "zero",
]
