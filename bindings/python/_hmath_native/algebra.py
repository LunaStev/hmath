# SPDX-License-Identifier: MPL-2.0
# Generated original algebra interface.
from ._algebra_base import initialize, invoke
from ._foundation_base import FoundationValue, register


class Additive(FoundationValue):
    """Original HMath.Algebra.Additive owner."""

    _source_type = "HMath.Algebra.Additive"

    def __init__(self, argument1, *, dtype=None):
        initialize(
            self, "hmath_algebra_core_new_additive", [["a"]], [argument1], "old", dtype
        )

    @property
    def value(self):
        return get_additive(self)


register("HMath.Algebra.Additive", Additive)


class Modular(FoundationValue):
    """Original HMath.Algebra.Modular owner."""

    _source_type = "HMath.Algebra.Modular"


register("HMath.Algebra.Modular", Modular)


class FiniteField(FoundationValue):
    """Original HMath.Algebra.FiniteField owner."""

    _source_type = "HMath.Algebra.FiniteField"


register("HMath.Algebra.FiniteField", FiniteField)


class FieldElement(FoundationValue):
    """Original HMath.Algebra.FieldElement owner."""

    _source_type = "HMath.Algebra.FieldElement"


register("HMath.Algebra.FieldElement", FieldElement)


def linear_combination(argument1, argument2, *, dtype=None):
    "Checked linear combination. Supply the zero vector explicitly so the empty combination retains its dimension."
    return invoke(
        "hmath_algebra_core_linear_combination",
        [["v"], ["list", ["tuple", ["s"], ["v"]]]],
        [argument1, argument2],
        "module",
        dtype,
    )


def semiring_laws(argument1, *, dtype=None):
    "Exhaustive semiring identities on the supplied finite sample. This is a test utility, not a proof for types with an infinite carrier."
    return invoke(
        "hmath_algebra_core_semiring_laws", [["list", ["a"]]], [argument1], "old", dtype
    )


def ring_laws(argument1, *, dtype=None):
    "Semiring laws plus additive inverses on a finite sample."
    return invoke(
        "hmath_algebra_core_ring_laws", [["list", ["a"]]], [argument1], "old", dtype
    )


def field_laws(argument1, *, dtype=None):
    "Ring laws, commutative multiplication and nonzero inverses."
    return invoke(
        "hmath_algebra_core_field_laws", [["list", ["a"]]], [argument1], "old", dtype
    )


def group_laws(argument1, *, dtype=None):
    "Group identities on a finite sample."
    return invoke(
        "hmath_algebra_core_group_laws", [["list", ["a"]]], [argument1], "old", dtype
    )


def module_laws(argument1, argument2, *, dtype=None):
    "Check module scalar identity, composition, and both distributive laws. Vectors in the sample must belong to the same runtime space."
    return invoke(
        "hmath_algebra_core_module_laws",
        [["list", ["s"]], ["list", ["v"]]],
        [argument1, argument2],
        "module",
        dtype,
    )


def modular(argument1, argument2):
    "Construct a residue, requiring m>1; arbitrary signed values are reduced."
    return invoke(
        "hmath_algebra_core_modular",
        [["Integer"], ["Integer"]],
        [argument1, argument2],
        "value",
    )


def modular_value(argument1):
    "Canonical value in [0,m)."
    return invoke(
        "hmath_algebra_core_modular_value", [["Modular"]], [argument1], "value"
    )


def modular_modulus(argument1):
    "Modulus greater than one."
    return invoke(
        "hmath_algebra_core_modular_modulus", [["Modular"]], [argument1], "value"
    )


def add_modular(argument1, argument2):
    "Checked residue addition."
    return invoke(
        "hmath_algebra_core_add_modular",
        [["Modular"], ["Modular"]],
        [argument1, argument2],
        "value",
    )


def subtract_modular(argument1, argument2):
    "Checked residue subtraction."
    return invoke(
        "hmath_algebra_core_subtract_modular",
        [["Modular"], ["Modular"]],
        [argument1, argument2],
        "value",
    )


def multiply_modular(argument1, argument2):
    "Checked residue multiplication."
    return invoke(
        "hmath_algebra_core_multiply_modular",
        [["Modular"], ["Modular"]],
        [argument1, argument2],
        "value",
    )


def inverse_modular(argument1):
    "Invert a unit; zero and nonunits are domain errors."
    return invoke(
        "hmath_algebra_core_inverse_modular", [["Modular"]], [argument1], "value"
    )


def power_modular(argument1, argument2):
    "Integer power, with negative powers supported for units."
    return invoke(
        "hmath_algebra_core_power_modular",
        [["Modular"], ["Integer"]],
        [argument1, argument2],
        "value",
    )


def finite_field(argument1, argument2, argument3):
    "Construct GF(p^n) from an irreducible polynomial of positive degree. Primality is proven by trial division. Irreducibility uses successive Frobenius powers and polynomial gcds; n must not exceed the proof budget."
    return invoke(
        "hmath_algebra_core_finite_field",
        [["Int"], ["Integer"], ["list", ["Integer"]]],
        [argument1, argument2, argument3],
        "value",
    )


def prime_field(argument1, argument2):
    "Prime field GF(p), represented as F_p[x]/(x)."
    return invoke(
        "hmath_algebra_core_prime_field",
        [["Int"], ["Integer"]],
        [argument1, argument2],
        "value",
    )


def field_characteristic(argument1):
    "Prime characteristic p."
    return invoke(
        "hmath_algebra_core_field_characteristic",
        [["FiniteField"]],
        [argument1],
        "value",
    )


def field_degree(argument1):
    "Extension degree n."
    return invoke(
        "hmath_algebra_core_field_degree", [["FiniteField"]], [argument1], "value"
    )


def field_cardinality(argument1):
    "Exact carrier size p^n."
    return invoke(
        "hmath_algebra_core_field_cardinality", [["FiniteField"]], [argument1], "value"
    )


def field_modulus(argument1):
    "Ascending coefficients of the monic irreducible defining polynomial."
    return invoke(
        "hmath_algebra_core_field_modulus", [["FiniteField"]], [argument1], "value"
    )


def field_element(argument1, argument2):
    "Reduce an arbitrary integer polynomial into a finite field."
    return invoke(
        "hmath_algebra_core_field_element",
        [["FiniteField"], ["list", ["Integer"]]],
        [argument1, argument2],
        "value",
    )


def field_element_coefficients(argument1):
    "Canonical ascending residue coefficients (trailing zeros removed)."
    return invoke(
        "hmath_algebra_core_field_element_coefficients",
        [["FieldElement"]],
        [argument1],
        "value",
    )


def field_elements(argument1, argument2):
    "Enumerate the complete carrier, rejecting sizes above an explicit storage budget. Enumeration is coefficient-lexicographic and deterministic."
    return invoke(
        "hmath_algebra_core_field_elements",
        [["Int"], ["FiniteField"]],
        [argument1, argument2],
        "value",
    )


def add_field(argument1, argument2):
    "Addition; different defining fields are rejected even if isomorphic."
    return invoke(
        "hmath_algebra_core_add_field",
        [["FieldElement"], ["FieldElement"]],
        [argument1, argument2],
        "value",
    )


def negate_field(argument1):
    "Additive inverse in the same field."
    return invoke(
        "hmath_algebra_core_negate_field", [["FieldElement"]], [argument1], "value"
    )


def subtract_field(argument1, argument2):
    "Checked field subtraction."
    return invoke(
        "hmath_algebra_core_subtract_field",
        [["FieldElement"], ["FieldElement"]],
        [argument1, argument2],
        "value",
    )


def multiply_field(argument1, argument2):
    "Checked field multiplication, reduced modulo the defining polynomial."
    return invoke(
        "hmath_algebra_core_multiply_field",
        [["FieldElement"], ["FieldElement"]],
        [argument1, argument2],
        "value",
    )


def inverse_field_element(argument1):
    "Nonzero inverse via the finite-field identity a^(q-2)."
    return invoke(
        "hmath_algebra_core_inverse_field_element",
        [["FieldElement"]],
        [argument1],
        "value",
    )


def power_field(argument1, argument2):
    "Binary exponentiation, with inverses for negative exponents."
    return invoke(
        "hmath_algebra_core_power_field",
        [["FieldElement"], ["Integer"]],
        [argument1, argument2],
        "value",
    )


def finite_field_laws(argument1, argument2):
    "Exhaustive carrier checks for small fields, including distributivity, associativity, identities and every nonzero inverse. Budget bounds enumeration; the cubic law checks are intended for small validation fields."
    return invoke(
        "hmath_algebra_core_finite_field_laws",
        [["Int"], ["FiniteField"]],
        [argument1, argument2],
        "value",
    )


def get_additive(argument1, *, dtype=None):
    "Read the original immutable public field; no numerical conversion is performed."
    return invoke(
        "hmath_algebra_core_get_additive",
        [["Additive", ["a"]]],
        [argument1],
        "old",
        dtype,
    )


def zero(*, dtype=None):
    "Additive identity."
    return invoke("hmath_algebra_core_zero", [], [], "old", dtype)


def one(*, dtype=None):
    "Multiplicative identity."
    return invoke("hmath_algebra_core_one", [], [], "old", dtype)


def plus(argument1, argument2, *, dtype=None):
    "Semiring addition."
    return invoke(
        "hmath_algebra_core_plus", [["a"], ["a"]], [argument1, argument2], "old", dtype
    )


def times(argument1, argument2, *, dtype=None):
    "Semiring multiplication."
    return invoke(
        "hmath_algebra_core_times", [["a"], ["a"]], [argument1, argument2], "old", dtype
    )


def negate_ring(argument1, *, dtype=None):
    "Additive inverse."
    return invoke("hmath_algebra_core_negate_ring", [["a"]], [argument1], "old", dtype)


def inverse_field(argument1, *, dtype=None):
    "Multiplicative inverse; zero returns a domain error."
    return invoke(
        "hmath_algebra_core_inverse_field", [["a"]], [argument1], "old", dtype
    )


def group_identity(*, dtype=None):
    "Group identity."
    return invoke("hmath_algebra_core_group_identity", [], [], "old", dtype)


def group_combine(argument1, argument2, *, dtype=None):
    "Group operation, not necessarily commutative."
    return invoke(
        "hmath_algebra_core_group_combine",
        [["Additive", ["a"]], ["Additive", ["a"]]],
        [argument1, argument2],
        "old",
        dtype,
    )


def group_inverse(argument1, *, dtype=None):
    "Two-sided inverse."
    return invoke(
        "hmath_algebra_core_group_inverse",
        [["Additive", ["a"]]],
        [argument1],
        "old",
        dtype,
    )


def module_scale(argument1, argument2, *, dtype=None):
    "Scalar action."
    return invoke(
        "hmath_algebra_core_module_scale",
        [["a"], ["list", ["a"]]],
        [argument1, argument2],
        "module",
        dtype,
    )


def module_add(argument1, argument2, *, dtype=None):
    "Addition, rejecting incompatible runtime shapes."
    return invoke(
        "hmath_algebra_core_module_add",
        [["list", ["a"]], ["list", ["a"]]],
        [argument1, argument2],
        "module",
        dtype,
    )


class Semiring:
    """Original HMath.Algebra.Semiring interface; methods select supported source instances."""

    zero = staticmethod(zero)
    one = staticmethod(one)
    plus = staticmethod(plus)
    times = staticmethod(times)


class Ring:
    """Original HMath.Algebra.Ring interface; methods select supported source instances."""

    negate_ring = staticmethod(negate_ring)


class Field:
    """Original HMath.Algebra.Field interface; methods select supported source instances."""

    inverse_field = staticmethod(inverse_field)


class Group:
    """Original HMath.Algebra.Group interface; methods select supported source instances."""

    group_identity = staticmethod(group_identity)
    group_combine = staticmethod(group_combine)
    group_inverse = staticmethod(group_inverse)


class Module:
    """Original HMath.Algebra.Module interface; methods select supported source instances."""

    module_scale = staticmethod(module_scale)
    module_add = staticmethod(module_add)


class VectorSpace:
    """Original HMath.Algebra.VectorSpace interface; methods select supported source instances."""

    pass


__all__ = [
    "Additive",
    "Field",
    "FieldElement",
    "FiniteField",
    "Group",
    "Modular",
    "Module",
    "Ring",
    "Semiring",
    "VectorSpace",
    "add_field",
    "add_modular",
    "field_cardinality",
    "field_characteristic",
    "field_degree",
    "field_element",
    "field_element_coefficients",
    "field_elements",
    "field_laws",
    "field_modulus",
    "finite_field",
    "finite_field_laws",
    "get_additive",
    "group_combine",
    "group_identity",
    "group_inverse",
    "group_laws",
    "inverse_field",
    "inverse_field_element",
    "inverse_modular",
    "linear_combination",
    "modular",
    "modular_modulus",
    "modular_value",
    "module_add",
    "module_laws",
    "module_scale",
    "multiply_field",
    "multiply_modular",
    "negate_field",
    "negate_ring",
    "one",
    "plus",
    "power_field",
    "power_modular",
    "prime_field",
    "ring_laws",
    "semiring_laws",
    "subtract_field",
    "subtract_modular",
    "times",
    "zero",
]
