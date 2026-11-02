# SPDX-License-Identifier: MPL-2.0
"""Positioned AST, exact arithmetic, symbolic conditions and error contracts."""

import dataclasses
import gc
import unittest
from fractions import Fraction

import hmath
from _hmath_native import expression as e
from _hmath_native import symbolic as s
from _hmath_native._expression_error import last_expression_error
from _hmath_native._math_error import last_math_error


def close(value):
    if isinstance(value, (list, tuple)):
        for item in value:
            close(item)
    elif dataclasses.is_dataclass(value):
        for field in dataclasses.fields(value):
            close(getattr(value, field.name))
    elif hasattr(value, "close"):
        value.close()


class ExpressionContracts(unittest.TestCase):
    def setUp(self):
        self.limits = e.default_limits()
        self.registry = e.default_registry()
        self.options = s.default_symbolic_options()

    def tearDown(self):
        close(self.options)
        close(self.registry)

    def test_original_defaults_and_all_limit_selectors(self):
        self.assertEqual(self.limits, e.Limits())
        for name in [
            "maximum_steps",
            "maximum_depth",
            "maximum_nodes",
            "maximum_input_chars",
            "maximum_integer_bits",
            "maximum_cache_entries",
        ]:
            self.assertEqual(getattr(e, name)(self.limits), getattr(self.limits, name))
        self.assertEqual(e.unknown_position(), e.SourcePos(0, 0, 0))

    def test_source_positions_full_ast_and_original_equality(self):
        position = e.SourcePos(-3, 9, 12)
        with (
            e.Literal(Fraction(2, 3)) as node,
            e.Expr(position, node) as located,
            e.literal(Fraction(2, 3)) as generated,
        ):
            self.assertEqual(located.position, position)
            self.assertEqual(located, generated)
            with located.node as retrieved:
                self.assertEqual(retrieved.fields, (0, Fraction(2, 3)))
                self.assertEqual(retrieved, node)
            self.assertEqual(e.source_offset(position), -3)
            self.assertEqual(e.source_line(position), 9)
            self.assertEqual(e.source_column(position), 12)
        with (
            e.parse_expression(self.limits, "x +\n 2*y") as parsed,
            parsed.node as root,
        ):
            fields = root.fields
            try:
                self.assertEqual(fields[:2], (4, e.Add))
                self.assertEqual(fields[2].position, e.SourcePos(0, 1, 1))
                self.assertEqual(fields[3].position, e.SourcePos(5, 2, 2))
            finally:
                close(fields)

    def test_exact_and_float_tags_and_unreferenced_bindings(self):
        with e.parse_expression(self.limits, "let a = x+1 in a*a") as expression:
            exact = e.evaluate_expression(
                self.limits,
                e.ExactRational,
                self.registry,
                {"x": e.ExactValue(Fraction(2, 3))},
                expression,
            )
            self.assertEqual(exact, e.ExactValue(Fraction(25, 9)))
            approximate = e.evaluate_expression(
                self.limits,
                e.Float64,
                self.registry,
                {"x": e.FloatValue(2)},
                expression,
            )
            self.assertEqual(approximate, e.FloatValue(9))
        self.assertEqual(
            e.evaluate_text(
                self.limits,
                e.ExactRational,
                self.registry,
                {"unused": e.FloatValue(float("nan"))},
                "1",
            ),
            e.ExactValue(Fraction(1)),
        )
        self.assertEqual(
            e.evaluate_text(
                self.limits,
                e.ExactRational,
                self.registry,
                [("x", e.ExactValue(1)), ("x", e.ExactValue(2))],
                "x",
            ),
            e.ExactValue(Fraction(2)),
        )

    def test_closed_registry_aliases_and_compiled_revalidation(self):
        with (
            e.empty_registry() as empty,
            e.register_function("squared_root", e.Sqrt, empty) as registry,
        ):
            self.assertEqual(e.allowed_functions(registry), ["squared_root"])
            with (
                e.parse_expression(self.limits, "squared_root(4)") as expression,
                e.compile_expression(self.limits, expression) as compiled,
            ):
                self.assertEqual(
                    e.evaluate_compiled(
                        self.limits, e.ExactRational, registry, {}, compiled
                    ),
                    e.ExactValue(Fraction(2)),
                )
                with self.assertRaises(hmath.HMathError) as caught:
                    e.evaluate_compiled(
                        self.limits, e.ExactRational, empty, {}, compiled
                    )
                self.assertEqual(caught.exception.expression_error.kind, e.UnknownName)

    def test_immutable_cache_and_serialization(self):
        with e.empty_expression_cache() as empty:
            compiled, populated = e.cached_expression(self.limits, "x*x+x*x", empty)
            try:
                self.assertEqual(e.cache_size(empty), 0)
                self.assertEqual(e.cache_size(populated), 1)
                self.assertEqual(e.compiled_node_count(compiled), 3)
                again, next_cache = e.cached_expression(
                    self.limits, "x*x+x*x", populated
                )
                close((again, next_cache))
            finally:
                close((compiled, populated))
        with e.parse_expression(self.limits, "let x = 2//3 in x^2") as original:
            text = e.serialize_expression(self.limits, original)
            with e.deserialize_expression(self.limits, text) as restored:
                self.assertEqual(original, restored)
                self.assertEqual(
                    e.expression_hash(self.limits, original),
                    e.expression_hash(self.limits, restored),
                )
                self.assertEqual(restored.position, e.unknown_position())

    def test_all_ten_original_error_kinds_and_query_lifetime(self):

        def parse(source, **limits):
            return e.parse_expression(
                dataclasses.replace(self.limits, **limits), source
            )

        cases = [
            (e.SyntaxError, lambda: parse(")")),
            (
                e.UnknownName,
                lambda: e.evaluate_text(
                    self.limits, e.ExactRational, self.registry, {}, "missing"
                ),
            ),
            (
                e.TypeMismatch,
                lambda: e.evaluate_text(
                    self.limits, e.ExactRational, self.registry, {}, "sin(1)"
                ),
            ),
            (
                e.DomainFailure,
                lambda: e.evaluate_text(
                    self.limits, e.ExactRational, self.registry, {}, "1/0"
                ),
            ),
            (
                e.NonFinite,
                lambda: e.evaluate_text(
                    self.limits,
                    e.Float64,
                    self.registry,
                    {"x": e.FloatValue(float("inf"))},
                    "x",
                ),
            ),
            (e.StepLimit, lambda: parse("1", maximum_steps=1)),
            (e.DepthLimit, lambda: parse("1", maximum_depth=1)),
            (e.MemoryLimit, lambda: parse("12", maximum_input_chars=1)),
            (
                e.InvalidLimits,
                lambda: e.validate_limits(
                    dataclasses.replace(self.limits, maximum_steps=0)
                ),
            ),
            (e.Unsupported, lambda: self.integrate_unsupported()),
        ]
        for expected, call in cases:
            with self.subTest(kind=expected):
                with self.assertRaises(hmath.HMathError) as caught:
                    call()
                error = caught.exception
                self.assertEqual(error.status, 12)
                self.assertEqual(error.expression_error.kind, expected)
                self.assertIsNone(error.math_error)
                self.assertIsNone(last_math_error(hmath._lib))
                self.assertEqual(
                    last_expression_error(hmath._lib), error.expression_error
                )
                e.validate_limits(self.limits)
                self.assertIsNone(last_expression_error(hmath._lib))

    def integrate_unsupported(self):
        with e.parse_expression(self.limits, "exp(x^2)") as expression:
            return s.integrate_basic(self.options, "x", expression)

    def test_long_unicode_error_and_lossless_error_record_fields(self):
        name = "λ" * 3000
        with self.assertRaises(hmath.HMathError) as caught:
            e.evaluate_text(self.limits, e.ExactRational, self.registry, {}, name)
        self.assertEqual(
            caught.exception.expression_error.message, "unknown variable: " + name
        )
        payload = "λ\x00𝄞\ud800\udfff" * 3000
        original = e.ExprError(e.Unsupported, e.SourcePos(-4, 2, 3), payload)
        self.assertEqual(e.error_kind(original), e.Unsupported)
        self.assertEqual(e.error_position(original), original.position)
        self.assertEqual(e.error_message(original), payload)

    def test_assumptions_preserve_domain_conditions(self):
        with (
            e.parse_expression(self.limits, "x/x") as expression,
            s.assumptions([("x", [s.NonZero])]) as assumptions,
        ):
            without = s.simplify(self.options, expression)
            with_assumptions = s.simplify(
                s.SymbolicOptions(self.limits, assumptions), expression
            )
            try:
                self.assertEqual(e.pretty_expression(without), "(x/x)")
                self.assertEqual(e.pretty_expression(with_assumptions), "1")
                self.assertFalse(
                    s.proves(self.options.assumptions, s.NonZero, expression)
                )
            finally:
                close((without, with_assumptions))
        with self.assertRaises(hmath.HMathError) as caught:
            s.assumptions([("x", [s.Positive, s.NonPositive])])
        self.assertEqual(caught.exception.expression_error.kind, e.DomainFailure)

    def test_guarded_eigenvalues_preserve_explicit_conditions(self):
        with (
            e.variable("a") as a,
            e.literal(0) as zero,
            e.literal(1) as one,
            s.symbolic_matrix(self.options, [[zero, one], [a, zero]]) as matrix,
        ):
            guarded = s.symbolic_eigenvalues(self.options, matrix)
            try:
                self.assertEqual(len(guarded.value), 2)
                self.assertEqual(len(guarded.conditions), 1)
                self.assertEqual(guarded.conditions[0][1], s.NonNegative)
                copied = s.required_conditions(guarded)
                close(copied)
                roots = s.guarded_value(guarded)
                self.assertEqual(len(roots), 2)
                close(roots)
            finally:
                close(guarded)

    def test_patterns_repeated_wildcards_and_capture_avoiding_substitution(self):
        with (
            s.Any("a") as any_a,
            s.BinaryPattern(e.Add, any_a, any_a) as pattern,
            e.parse_expression(self.limits, "x+x") as equal,
            e.parse_expression(self.limits, "x+y") as unequal,
        ):
            match = s.match_pattern(self.limits, pattern, equal)
            self.assertEqual(match[0][0], "a")
            close(match)
            self.assertIsNone(s.match_pattern(self.limits, pattern, unequal))
        with (
            e.parse_expression(self.limits, "let y = 2 in x+y") as expression,
            e.variable("y") as y,
            s.substitute(self.limits, [("x", y)], expression) as substituted,
        ):
            self.assertEqual(e.free_variables(substituted), ["y"])
            self.assertEqual(
                e.evaluate_expression(
                    self.limits,
                    e.ExactRational,
                    self.registry,
                    {"y": e.ExactValue(3)},
                    substituted,
                ),
                e.ExactValue(5),
            )

    def test_formal_series_polynomial_and_linear_solution_interop(self):
        with e.parse_expression(self.limits, "x^2-1") as expression:
            with s.to_polynomial(self.options, "x", expression) as polynomial:
                self.assertEqual(polynomial.dtype, "rational")
                self.assertEqual(
                    polynomial.coefficients, [Fraction(-1), Fraction(0), Fraction(1)]
                )
                with (
                    s.from_polynomial("x", polynomial) as restored,
                    s.simplify(self.options, restored) as simplified,
                ):
                    self.assertEqual(
                        e.evaluate_expression(
                            self.limits,
                            e.ExactRational,
                            self.registry,
                            {"x": e.ExactValue(3)},
                            simplified,
                        ),
                        e.ExactValue(8),
                    )
            with (
                s.formal_power_series(
                    self.options, [Fraction(1), Fraction(2)]
                ) as series,
                s.reciprocal_formal_series(self.options, series) as reciprocal,
            ):
                self.assertEqual(reciprocal.coefficients, [Fraction(1), Fraction(-2)])
        with e.variable("x") as x, e.literal(2) as two:
            solution = s.solve_linear_equations(self.options, ["x", "y"], [(x, two)])
            try:
                self.assertEqual(solution.name, "ParametricSolution")
                self.assertEqual(solution.arguments[1], ["y"])
                self.assertEqual(solution.arguments[0][0][0], "x")
            finally:
                close(solution)

    def test_zz_runtime_shutdown_releases_all_owners(self):
        close(self.options)
        close(self.registry)
        gc.collect()
        hmath.shutdown()


if __name__ == "__main__":
    unittest.main()
