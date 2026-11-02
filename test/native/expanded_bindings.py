# SPDX-License-Identifier: MPL-2.0
"""Native numeric transport and optimizer lifetime regression checks."""

import math
import os
import sys
import unittest
from concurrent.futures import ThreadPoolExecutor
from fractions import Fraction
from pathlib import Path

if os.environ.get("HMATH_LIBRARY"):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "bindings/python"))
import hmath
from hmath import basic, constants, optimization, scalar, statistics, trigonometry


class ExpandedBindings(unittest.TestCase):
    def test_original_numerical_contracts(self):
        self.assertEqual(scalar.prefix_sum([1, 2, 3]), [0, 1, 3, 6])
        self.assertEqual(scalar.prefix_sum([]), [0])
        self.assertEqual(scalar.cumulative_sum([]), [])
        self.assertEqual(scalar.integer_fraction(-1.5), (-1, -0.5))
        self.assertEqual(scalar.quotient_remainder(-7, 3), (-2, -1))
        self.assertEqual(scalar.euclidean_division(-7, 3), (-3, 2))
        self.assertEqual(scalar.bernoulli(4), Fraction(-1, 30))
        self.assertEqual(statistics.variance([1, 3]), 1)
        self.assertTrue(math.isnan(constants.nan()))
        self.assertTrue(math.isinf(scalar.add(float("inf"), 1)))
        self.assertEqual(basic.clamp(2, 1, 0), 2)  # original unchecked reversed bounds
        with self.assertRaises(hmath.HMathError) as error:
            scalar.clamp_checked(2, 1, 0)
        self.assertEqual(error.exception.status, 11)
        self.assertEqual(str(error.exception), 'DomainError "reversed clamp bounds"')
        with self.assertRaises(hmath.HMathError) as error:
            statistics.mean([])
        self.assertEqual(error.exception.status, 6)
        with self.assertRaises(OverflowError):
            scalar.round_digits(1 << 100, 1.0)
        with self.assertRaises(ValueError):
            scalar.add(1, 2, dtype="invalid")

    def test_exact_integer_transport(self):
        self.assertEqual(basic.factorial(2000), math.factorial(2000))
        value = 10**6000 + 12345
        self.assertEqual(scalar.positive_modulo(-value, value + 17), 17)

    def test_precision_and_signed_zero(self):
        self.assertEqual(scalar.add(16777216, 1, dtype="float32"), 16777216)
        self.assertEqual(scalar.add(16777216, 1), 16777217)
        self.assertEqual(math.copysign(1, scalar.integer_fraction(-0.0)[1]), -1)
        self.assertAlmostEqual(
            trigonometry.complex_sin(1 + 2j).real, math.sin(1) * math.cosh(2)
        )

    def test_thread_local_errors(self):
        def work(index):
            for _ in range(25):
                if index % 2:
                    self.assertEqual(scalar.hypot(3, 4), 5)
                else:
                    with self.assertRaises(hmath.HMathError) as error:
                        scalar.divide(1, 0)
                    self.assertEqual(
                        str(error.exception), 'DomainError "division by zero"'
                    )

        with ThreadPoolExecutor(max_workers=4) as pool:
            list(pool.map(work, range(8)))

    def test_optimizer_state_is_immutable(self):
        with optimization.initialize_optimizer(2) as state:
            for method in optimization.GradientMethod:
                left, left_state = optimization.optimizer_step(
                    method, 0.1, state, [1, 2], [2, -3]
                )
                right, right_state = optimization.optimizer_step(
                    method, 0.1, state, [1, 2], [2, -3]
                )
                try:
                    self.assertEqual(left, right)
                    with self.assertRaises(hmath.HMathError) as error:
                        hmath.shutdown()
                    self.assertEqual(error.exception.status, 9)
                finally:
                    left_state.close()
                    right_state.close()
            with self.assertRaises(hmath.HMathError) as error:
                optimization.optimizer_step(
                    optimization.GradientMethod.ADAM, 0, state, [1, 2], [2, 3]
                )
            self.assertEqual(
                str(error.exception), 'InvalidArgument "optimizer rate or state shape"'
            )
        with self.assertRaises(ValueError):
            optimization.optimizer_step(
                optimization.GradientMethod.ADAM, 0.1, state, [1, 2], [2, 3]
            )


if __name__ == "__main__":
    unittest.main(argv=[__file__])
