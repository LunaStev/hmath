# Original algebra interfaces

The two source modules define different classes and instances. Their functions remain separate. Prototypes select the actual original type, without adding arithmetic instances or converting through Double. `Exact` wraps Rational and deliberately has no Num instance. Old Algebra supports Integer/Rational/Polynomial rings, Rational fields, Additive groups and Integer/Rational list modules. API.Algebra supports Integer/Rational/Float/Double/Complex Double/Exact; Field excludes Integer and FloatingPoint is Float/Double/Complex Double. Source errors, modular ring identity, finite-field proof budgets and checked inversion are unchanged. Values own references and support close/context management.

## `algebra.linear_combination`

Checked linear combination. Supply the zero vector explicitly so the empty combination retains its dimension.

Original signature: `v -> [(s, v)] -> Either MathError v`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.semiring_laws`

Exhaustive semiring identities on the supplied finite sample. This is a test utility, not a proof for types with an infinite carrier.

Original signature: `[a] -> [(String, Bool)]`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.ring_laws`

Semiring laws plus additive inverses on a finite sample.

Original signature: `[a] -> [(String, Bool)]`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.field_laws`

Ring laws, commutative multiplication and nonzero inverses.

Original signature: `[a] -> [(String, Bool)]`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.group_laws`

Group identities on a finite sample.

Original signature: `[a] -> [(String, Bool)]`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.module_laws`

Check module scalar identity, composition, and both distributive laws. Vectors in the sample must belong to the same runtime space.

Original signature: `[s] -> [v] -> [(String, Bool)]`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.modular`

Construct a residue, requiring m>1; arbitrary signed values are reduced.

Original signature: `Integer -> Integer -> Either MathError Modular`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.modular_value`

Canonical value in [0,m).

Original signature: `Modular -> Integer`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.modular_modulus`

Modulus greater than one.

Original signature: `Modular -> Integer`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.add_modular`

Checked residue addition.

Original signature: `Modular -> Modular -> Either MathError Modular`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.subtract_modular`

Checked residue subtraction.

Original signature: `Modular -> Modular -> Either MathError Modular`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.multiply_modular`

Checked residue multiplication.

Original signature: `Modular -> Modular -> Either MathError Modular`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.inverse_modular`

Invert a unit; zero and nonunits are domain errors.

Original signature: `Modular -> Either MathError Modular`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.power_modular`

Integer power, with negative powers supported for units.

Original signature: `Modular -> Integer -> Either MathError Modular`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.finite_field`

Construct GF(p^n) from an irreducible polynomial of positive degree. Primality is proven by trial division. Irreducibility uses successive Frobenius powers and polynomial gcds; n must not exceed the proof budget.

Original signature: `Int -> Integer -> [Integer] -> Either MathError FiniteField`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.prime_field`

Prime field GF(p), represented as F_p[x]/(x).

Original signature: `Int -> Integer -> Either MathError FiniteField`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.field_characteristic`

Prime characteristic p.

Original signature: `FiniteField -> Integer`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.field_degree`

Extension degree n.

Original signature: `FiniteField -> Int`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.field_cardinality`

Exact carrier size p^n.

Original signature: `FiniteField -> Integer`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.field_modulus`

Ascending coefficients of the monic irreducible defining polynomial.

Original signature: `FiniteField -> [Integer]`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.field_element`

Reduce an arbitrary integer polynomial into a finite field.

Original signature: `FiniteField -> [Integer] -> FieldElement`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.field_element_coefficients`

Canonical ascending residue coefficients (trailing zeros removed).

Original signature: `FieldElement -> [Integer]`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.field_elements`

Enumerate the complete carrier, rejecting sizes above an explicit storage budget. Enumeration is coefficient-lexicographic and deterministic.

Original signature: `Int -> FiniteField -> Either MathError [FieldElement]`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.add_field`

Addition; different defining fields are rejected even if isomorphic.

Original signature: `FieldElement -> FieldElement -> Either MathError FieldElement`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.negate_field`

Additive inverse in the same field.

Original signature: `FieldElement -> FieldElement`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.subtract_field`

Checked field subtraction.

Original signature: `FieldElement -> FieldElement -> Either MathError FieldElement`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.multiply_field`

Checked field multiplication, reduced modulo the defining polynomial.

Original signature: `FieldElement -> FieldElement -> Either MathError FieldElement`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.inverse_field_element`

Nonzero inverse via the finite-field identity a^(q-2).

Original signature: `FieldElement -> Either MathError FieldElement`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.power_field`

Binary exponentiation, with inverses for negative exponents.

Original signature: `FieldElement -> Integer -> Either MathError FieldElement`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.finite_field_laws`

Exhaustive carrier checks for small fields, including distributivity, associativity, identities and every nonzero inverse. Budget bounds enumeration; the cubic law checks are intended for small validation fields.

Original signature: `Int -> FiniteField -> Either MathError [(String, Bool)]`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.get_additive`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Additive -> field`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.Additive`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.horner`

Coefficients are highest degree first; an empty polynomial is zero.

Original signature: `[a] -> a -> a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.inner_product`

Return sum(conjugate a[i] * b[i]) using the Scalar and Ring operations. Equal list lengths are required; mismatch returns VectorLengthMismatch. Empty lists give the ring zero; instance arithmetic controls precision/overflow.

Original signature: `[a] -> [a] -> Either MathError a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.get_exact`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Exact -> field`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.Exact`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.zero`

Additive identity.

Original signature: `a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.one`

Multiplicative identity.

Original signature: `a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.plus`

Semiring addition.

Original signature: `a -> a -> a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.times`

Semiring multiplication.

Original signature: `a -> a -> a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.negate_ring`

Additive inverse.

Original signature: `a -> a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.inverse_field`

Multiplicative inverse; zero returns a domain error.

Original signature: `a -> Either MathError a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.group_identity`

Group identity.

Original signature: `a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.group_combine`

Group operation, not necessarily commutative.

Original signature: `a -> a -> a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.group_inverse`

Two-sided inverse.

Original signature: `a -> a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.module_scale`

Scalar action.

Original signature: `scalar -> vector -> vector`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra.module_add`

Addition, rejecting incompatible runtime shapes.

Original signature: `vector -> vector -> Either MathError vector`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.zero`

Additive identity of this ring.

Original signature: `a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.one`

Multiplicative identity of this ring.

Original signature: `a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.plus`

Add two ring elements; exact instances obey ring laws and IEEE instances retain host rounding.

Original signature: `a -> a -> a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.times`

Multiply two ring elements using the instance arithmetic.

Original signature: `a -> a -> a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.negative`

Return the additive inverse of a ring element.

Original signature: `a -> a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.integer`

Embed an unbounded Integer into the domain; instance representation/rounding rules apply.

Original signature: `Integer -> a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.invert`

Return multiplicative inverse of a nonzero domain element, or Left MathError for zero/invalid/nonrepresentable inverse.

Original signature: `a -> Either MathError a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.conjugate_scalar`

Return scalar conjugate; real/exact instances use identity and complex instances conjugate imaginary components.

Original signature: `a -> a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.machine_epsilon`

Given a type proxy, return floating precision epsilon as Double (2^-52 for Double,2^-23 for Float).

Original signature: `proxy a -> Double`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.finite_scalar`

Test whether all real/complex components are finite for this instance.

Original signature: `a -> Bool`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.rational`

Convert exact Rational into the domain, returning Left MathError if it cannot be represented under the instance contract.

Original signature: `Rational -> Either MathError a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.matrix_dimensions`

Return logical (rows,columns) of a matrix-like container.

Original signature: `m a -> (Int, Int)`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.matrix_elements`

Return matrix elements in logical row-major order.

Original signature: `m a -> [a]`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.matrix_construct`

Given rows,columns,flat row-major elements, construct a matrix-like value or return checked shape/count failure.

Original signature: `Int -> Int -> [a] -> Either MathError (m a)`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.tensor_dimensions`

Return tensor-like dimensions in axis order; [] denotes scalar.

Original signature: `t a -> [Int]`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.tensor_elements`

Return tensor-like elements in logical row-major coordinate order.

Original signature: `t a -> [a]`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.tensor_construct`

Given dimensions then flat values, construct a tensor-like value or return shape/count failure.

Original signature: `[Int] -> [a] -> Either MathError (t a)`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.vector_plus`

Add identically shaped vector-space values, returning checked dimension errors on mismatch.

Original signature: `(Num a) => v a -> v a -> Either MathError (v a)`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.vector_scale`

Given scalar then vector-space value, return its coordinatewise scalar multiple.

Original signature: `(Num a) => a -> v a -> v a`. The first C Value is a prototype; Python accepts `dtype=` or infers a typed argument. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

## `algebra_api.differential`

Extract associated differential; the Dual instance returns its tangent component.

Original signature: `a -> Differential a`. Borrowed source-order arguments; owned successful output; failure leaves the output untouched.

