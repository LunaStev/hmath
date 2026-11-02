# SPDX-License-Identifier: MPL-2.0
"""Graph ownership, derivative identities, tensor rules and native error contracts."""

import gc
import math
import os
import sys
import unittest
import weakref
from concurrent.futures import ThreadPoolExecutor
from fractions import Fraction
from pathlib import Path

if os.environ.get("HMATH_LIBRARY"):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "bindings/python"))
import hmath
from _hmath_native import autodiff as ad


class AutodiffBindings(unittest.TestCase):
    def test_reverse_and_higher_order(self):
        objective = lambda xs: xs[0] ** 2 + xs[0] * xs[1]
        self.assertEqual(ad.value_and_gradient(objective, [3, 4]), (21, [10, 3]))
        self.assertEqual(ad.gradient(objective, [3, 4]), [10, 3])
        self.assertEqual(ad.hessian(objective, [3, 4]), [[2, 1], [1, 0]])
        self.assertEqual(ad.hvp(objective, [3, 4], [2, -1]), [3, 2])
        self.assertLess(ad.gradient_check(1e-05, objective, [3, 4]), 1e-08)
        self.assertEqual(
            ad.complex_gradient(lambda x: x[0] ** 2 + x[1] ** 2, 3 + 4j), 3 + 4j
        )
        vector = lambda x: [x[0] * x[1], x[0] + x[1]]
        self.assertEqual(ad.jacobian(vector, [2, 3]), [[3, 2], [1, 1]])
        self.assertEqual(ad.jvp(vector, [2, 3], [1, 2]), [7, 3])
        self.assertEqual(ad.vjp(vector, [2, 3], [1, 2]), [5, 4])
        self.assertEqual(ad.jacobian(lambda _: [], [2, 3]), [])
        self.assertEqual(ad.jacobian(lambda _: [1, 2], []), [[], []])
        self.assertEqual(ad.hessian(lambda _: 5, []), [])

    def test_reusable_graph_and_handle_lifetime(self):
        x = ad.variable(0)
        expression = x * x + 1
        graph = ad.compile_graph(1, expression)
        x.close()
        expression.close()
        try:
            self.assertEqual(graph.evaluate([3]), 10)
            self.assertEqual(graph.evaluate([4]), 17)
            with self.assertRaises(hmath.HMathError) as error:
                hmath.shutdown()
            self.assertEqual(error.exception.status, 9)
            with self.assertRaises(hmath.HMathError) as error:
                graph.evaluate([])
            self.assertEqual(str(error.exception), "VectorLengthMismatch 1 0")
        finally:
            graph.close()
        with self.assertRaises(ValueError):
            graph.evaluate([1])
        graph.close()

    def test_forward_native_dual(self):
        self.assertEqual(ad.forward(lambda x: x * x * x, 3), (27, 27))
        self.assertEqual(
            ad.forward_jvp(lambda x: [x[0] * x[1]], [2, 3], [1, 2]), ([6], [7])
        )
        called = []
        with self.assertRaises(hmath.HMathError) as error:
            ad.forward_jvp(lambda x: called.append(x) or x, [2, 3], [1])
        self.assertEqual(called, [])
        self.assertEqual(str(error.exception), "VectorLengthMismatch 2 1")
        with ad.Dual(1, 2) as dual:
            self.assertEqual(ad.primal(dual), 1)
            self.assertEqual(ad.tangent(dual), 2)
        with ad.Dual(math.inf, math.nan) as dual:
            self.assertEqual(dual.primal, math.inf)
            self.assertTrue(math.isnan(dual.tangent))

    def test_explicit_gradient_state(self):
        with (
            ad.zero_gradients(2) as initial,
            ad.accumulate_gradients(initial, [3, 4]) as updated,
        ):
            self.assertEqual(initial.accumulated_gradient, [0, 0])
            self.assertEqual(updated.accumulated_gradient, [3, 4])
            with ad.gradient_hook(lambda xs: [-x for x in xs], updated) as changed:
                self.assertEqual(changed.accumulated_gradient, [-3, -4])
            with ad.reset_gradients(updated) as reset:
                self.assertEqual(reset.accumulated_gradient, [0, 0])
            with self.assertRaises(hmath.HMathError) as error:
                ad.gradient_hook(lambda _: [1], updated)
            self.assertEqual(str(error.exception), "VectorLengthMismatch 2 1")
        self.assertEqual(ad.clip_gradient(2, [3, 4]), [1.2000000000000002, 1.6])
        with ad.GradientState([math.nan]) as state:
            self.assertTrue(math.isnan(state.accumulated_gradient[0]))
            with ad.reset_gradients(state) as reset:
                self.assertEqual(reset.accumulated_gradient, [0])
        with self.assertRaises(hmath.HMathError) as error:
            ad.zero_gradients(-1)
        self.assertEqual(
            str(error.exception), 'InvalidArgument "negative gradient size"'
        )

    def test_tensor_rules(self):

        def objective(values):
            with ad.ad_tensor([2, 2], values) as tensor:
                self.assertEqual(ad.ad_shape(tensor), (2, 2))
                cells = ad.ad_values(tensor)
                try:
                    with (
                        ad.ad_tensor([2, 2], cells) as copied,
                        ad.ad_matmul(tensor, copied) as squared,
                    ):
                        return ad.ad_sum(squared)
                finally:
                    for cell in cells:
                        cell.close()

        self.assertEqual(ad.gradient(objective, [1, 2, 3, 4]), [7, 11, 9, 13])

        def broadcast(values):
            with (
                ad.ad_tensor([1], values) as tensor,
                ad.ad_broadcast([2, 3], tensor) as expanded,
            ):
                return ad.ad_sum(expanded)

        self.assertEqual(ad.gradient(broadcast, [2]), [6])

        def contract(values):
            with (
                ad.ad_tensor([2], values) as tensor,
                ad.ad_contract([0], [0], tensor, tensor) as product,
            ):
                return ad.ad_sum(product)

        self.assertEqual(ad.gradient(contract, [2, 3]), [4, 6])
        self.assertEqual(
            ad.gradient(
                lambda xs: ad.ad_sum(
                    ad.ad_multiply(ad.ad_tensor([2], xs), ad.ad_tensor([2], xs))
                ),
                [2, 3],
            ),
            [4, 6],
        )

    def test_detach_and_symbolic_derivative(self):
        self.assertEqual(ad.gradient(lambda x: x[0] + ad.detach(x[0] * x[0]), [3]), [1])
        self.assertEqual(ad.gradient(lambda x: ad.stop_gradient(x[0]), [3]), [0])
        with (
            ad.variable(0) as x,
            ad.differentiate(0, x**3) as derivative,
            ad.compile_graph(1, derivative) as graph,
        ):
            self.assertEqual(graph.evaluate([2]), 12)

    def test_symbolic_optimizer_step(self):
        with ad.variable(0) as x:
            points = ad.differentiable_step(0.1, lambda xs: xs[0] ** 2, [x])
            try:
                self.assertEqual(ad.gradient(points[0], [3]), [0.8])
                next_points = ad.differentiable_step(0.1, lambda xs: xs[0] ** 2, points)
                try:
                    self.assertAlmostEqual(ad.gradient(next_points[0], [3])[0], 0.64)
                finally:
                    for point in next_points:
                        point.close()
            finally:
                for point in points:
                    point.close()

    def test_original_validation_conditions(self):
        with self.assertRaises(hmath.HMathError) as error:
            ad.compile_graph(0, ad.constant(float("nan")))
        self.assertEqual(str(error.exception), "NonFiniteResult")
        with self.assertRaises(hmath.HMathError) as error:
            ad.compile_graph(0, ad.variable(-1))
        self.assertEqual(str(error.exception), 'InvalidArgument "graph input index"')
        with self.assertRaises(hmath.HMathError) as error:
            ad.gradient_check(0, lambda x: x[0], [1])
        self.assertEqual(str(error.exception), "InvalidTolerance")
        with self.assertRaises(hmath.HMathError) as error:
            ad.jvp(lambda x: x, [1], [1, 2])
        self.assertEqual(str(error.exception), "VectorLengthMismatch 1 2")

    def test_nested_forward(self):
        with ad.Dual(3, 1) as seed:
            value, derivative = ad.forward(lambda x: x * x * x, seed)
            with value, derivative:
                self.assertEqual((value.primal, value.tangent), (27, 27))
                self.assertEqual((derivative.primal, derivative.tangent), (27, 18))
        with ad.Dual(ad.Dual(3, 1), ad.Dual(1, 0)) as seed:
            self.assertEqual(seed.depth, 2)
            with seed * seed * seed as result, result.tangent as first:
                self.assertEqual(first.tangent, 18)
        with (
            ad.Dual(1, 0) as left,
            ad.Dual(ad.Dual(1, 0), ad.Dual(0, 0)) as right,
            self.assertRaises(TypeError),
        ):
            _ = left + right

    def test_forward_scalar_specializations(self):
        self.assertEqual(
            ad.forward(lambda x: x + 1, 16777216, dtype="float32"), (16777216, 1)
        )
        self.assertEqual(ad.forward(lambda x: x + 1, 16777216), (16777217, 1))
        large = 10**5000
        self.assertEqual(
            ad.forward(lambda x: x * x, large, dtype="integer"),
            (large * large, 2 * large),
        )
        self.assertEqual(
            ad.forward(lambda x: 1 / x, Fraction(2, 3), dtype="rational"),
            (Fraction(3, 2), Fraction(-9, 4)),
        )
        for dtype in ["float32", "integer", "rational"]:
            with ad.Dual(3, 1, dtype=dtype) as seed:
                value, derivative = ad.forward(lambda x: x * x * x, seed)
                with value, derivative:
                    self.assertEqual((value.primal, value.tangent), (27, 27))
                    self.assertEqual((derivative.primal, derivative.tangent), (27, 18))
                    self.assertEqual(value.dtype, dtype)
        with self.assertRaises(hmath.HMathError) as error:
            ad.forward(lambda x: 1 / x, 3, dtype="integer")
        self.assertIn("no Fractional instance", str(error.exception))
        with self.assertRaises(hmath.HMathError) as error:
            ad.forward(ad.exp, Fraction(1, 2), dtype="rational")
        self.assertIn("no Floating instance", str(error.exception))

    def test_all_coefficient_leaves_and_original_class_dictionaries(self):
        from hmath import numeric_types as numeric

        for dtype in [
            "int8",
            "int16",
            "int32",
            "int64",
            "uint8",
            "uint16",
            "uint32",
            "uint64",
            "intp",
            "uintp",
        ]:
            with self.subTest(dtype=dtype):
                self.assertEqual(ad.forward(lambda x: x * x, 3, dtype=dtype), (9, 6))
                with self.assertRaises(hmath.HMathError) as error:
                    ad.forward(lambda x: 1 / x, 3, dtype=dtype)
                self.assertIn("no Fractional instance", str(error.exception))
        self.assertEqual(ad.forward(lambda x: x * x, 120, dtype="int8"), (64, -16))
        for dtype in ["complex64", "complex128"]:
            with ad.Dual(1 + 2j, 1, dtype=dtype) as value:
                result = value * value
                with result:
                    self.assertEqual((result.primal, result.tangent), (-3 + 4j, 2 + 4j))
                with self.assertRaises(hmath.HMathError) as error:
                    _ = value < 0
                self.assertIn("no Ord instance", str(error.exception))
        with (
            numeric.number(1.0000001, "float32") as primal_value,
            numeric.number(1, "float32") as tangent_value,
            numeric.dual(primal_value, tangent_value, boxed=True) as leaf,
            ad.Dual(leaf, 1) as value,
            ad.Dual(value, value) as nested,
            nested.element_type as prototype,
        ):
            self.assertEqual(value.dtype, "numeric.dual")
            self.assertEqual(nested.depth, 2)
            self.assertEqual(prototype.info[:2], (1, 20))
            with self.assertRaises(hmath.HMathError) as error:
                _ = value < 0
            self.assertIn("no Ord instance", str(error.exception))
            output, derivative = ad.forward(lambda x: x * x * x, nested)
            with output, derivative, output.primal as first, first.primal as scalar:
                self.assertEqual(scalar.info[:2], (1, 20))
                with scalar.primal as real:
                    self.assertEqual(real.value, 1.0000003576278687)
        with (
            numeric.number(1, "float32") as one,
            numeric.quaternion(one, one, one, one, boxed=True) as leaf,
            ad.Dual(leaf, 1) as value,
        ):
            self.assertEqual(value.dtype, "numeric.quaternion")
            with self.assertRaises(hmath.HMathError) as error:
                ad.exp(value)
            self.assertIn("no Floating instance", str(error.exception))
        with self.assertRaises((OverflowError, hmath.HMathError)):
            ad.Dual(128, 1, dtype="int8")

    def test_forward_comparisons(self):
        self.assertEqual(ad.forward(lambda x: -x if x < 0 else x * x, -2), (2, -1))
        with ad.Dual(1, 1) as left, ad.Dual(1, 2) as right:
            self.assertFalse(left == right)
            self.assertTrue(left <= right)
            self.assertTrue(left >= right)
            self.assertFalse(left < right)
        self.assertEqual(ad.forward(lambda x: x + 1 if x == 0 else x * x, 0), (0, 0))

    def test_custom_rules_and_laziness(self):
        cube = lambda xs: ad.custom_operation(
            lambda values: (values[0] ** 3, [3 * values[0] ** 2]), xs
        )
        self.assertEqual(ad.value_and_gradient(cube, [2]), (8, [12]))
        with self.assertRaises(hmath.HMathError) as error:
            ad.hessian(cube, [2])
        self.assertEqual(
            str(error.exception),
            'InvalidArgument "custom rules support first order; provide a symbolic operation for higher orders"',
        )
        with (
            ad.variable(0) as x,
            ad.custom_operation(lambda values: (values[0], []), [x]) as expression,
        ):
            with ad.compile_graph(1, expression) as graph:
                self.assertEqual(graph.evaluate([2]), 2)
            with self.assertRaises(hmath.HMathError) as error:
                ad.gradient(expression, [2])
            self.assertEqual(str(error.exception), "VectorLengthMismatch 1 0")
        derivative_calls = []

        def derivative(value):
            derivative_calls.append(value)
            raise ValueError("custom derivative failed")

        with (
            ad.variable(0) as x,
            ad.custom_unary(lambda value: value * value, derivative, x) as expression,
        ):
            with ad.compile_graph(1, expression) as graph:
                self.assertEqual(graph.evaluate([3]), 9)
                self.assertEqual(derivative_calls, [])
            with self.assertRaisesRegex(ValueError, "custom derivative failed"):
                ad.gradient(expression, [3])
            self.assertEqual(derivative_calls, [3])

    def test_checkpoint_callback_lifetime(self):
        x = ad.variable(0)
        expression = ad.checkpoint(
            lambda inputs: ad.custom_unary(
                lambda value: value * value, lambda value: 2 * value, inputs[0]
            ),
            [x],
        )
        owner = weakref.ref(expression._keepers[-1])
        graph = ad.compile_graph(1, expression)
        expression.close()
        x.close()
        gc.collect()
        self.assertIsNotNone(owner())
        self.assertEqual(graph.evaluate([3]), 9)
        self.assertEqual(graph.evaluate([4]), 16)
        graph.close()
        gc.collect()
        self.assertIsNone(owner())
        self.assertEqual(
            ad.gradient(lambda xs: ad.checkpoint(lambda ys: ys[0] * ys[0], xs), [3]),
            [6],
        )

        def invalid_builder(_):
            raise ValueError("checkpoint builder failed")

        with self.assertRaisesRegex(ValueError, "checkpoint builder failed"):
            ad.gradient(lambda xs: ad.checkpoint(invalid_builder, xs), [2])

    def test_shared_graph_threads(self):
        with (
            ad.compile_graph(2, ad.variable(0) * ad.variable(1)) as graph,
            ThreadPoolExecutor(max_workers=4) as executor,
        ):
            self.assertEqual(
                list(executor.map(lambda n: graph.evaluate([n, n + 1]), range(16))),
                [n * (n + 1) for n in range(16)],
            )


if __name__ == "__main__":
    unittest.main(argv=[__file__])
