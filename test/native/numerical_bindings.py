# SPDX-License-Identifier: MPL-2.0
"""Callback containment, exact payloads and independent numerical owners."""

import sys
import unittest
from fractions import Fraction
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "bindings/python"))
import hmath
from hmath import calculus as c
from hmath import matrix as m
from hmath import ode


class BrokenMessage(Exception):
    def __str__(self):
        raise RuntimeError("exception formatting must remain outside the C callback")


class NumericalContracts(unittest.TestCase):
    def test_generic_estimate_keeps_exact_payload_and_independent_matrix(self):
        original = m.from_list(
            1, 2, [Fraction(1, 10**5000 + 1), 10**5000], dtype="rational"
        )
        estimate = c.estimate(original, -0.0, 7)
        original.close()
        result = c.estimate_value(estimate)
        estimate.close()
        self.assertEqual(result.to_list(), [Fraction(1, 10**5000 + 1), 10**5000])
        result.close()
        with c.estimate((None, "x\0α\ud800", Fraction(7, 13)), 0.1, 4) as estimate:
            self.assertEqual(
                c.estimate_value(estimate), (None, "x\0α\ud800", Fraction(7, 13))
            )

    def test_callback_can_reenter_and_close_original_method(self):
        method = c.central()
        calls = []

        def function(x):
            method.close()
            calls.append(x)
            return hmath.add(x * x, 0)

        self.assertAlmostEqual(c.derivative(method, 0.001, function, 3), 6, places=10)
        self.assertTrue(calls)
        with self.assertRaises(ValueError):
            _ = method.info

    def test_unexpected_exception_identity_and_broken_formatter(self):
        original = BrokenMessage()
        with c.central() as method:

            def function(_):
                raise original

            with self.assertRaises(BrokenMessage) as caught:
                c.derivative(method, 0.001, function, 3)
        self.assertIs(caught.exception, original)

    def test_structured_math_error_preserves_full_text(self):
        message = "payload\0α\ud800" * 1000
        error = hmath.errors.NonConvergence(message, 17)
        with c.central() as method:

            def function(_):
                raise error

            with self.assertRaises(hmath.HMathError) as caught:
                c.derivative(method, 0.001, function, 3)
        self.assertEqual(caught.exception.math_error.details, (17,))
        self.assertEqual(caught.exception.math_error.message, message)

    def test_caught_reentrant_callback_failure_does_not_poison_outer_call(self):
        from _hmath_native._numerical_base import _callback

        original = BrokenMessage()
        active = []
        holder = []
        with c.central() as method:

            def function(x):
                if active:
                    raise original
                active.append(True)
                try:
                    with self.assertRaises(BrokenMessage) as caught:
                        c.derivative(method, 0.001, holder[0], 0)
                    self.assertIs(caught.exception, original)
                finally:
                    active.clear()
                return x * x

            native = _callback(function, ["Double"])
            holder.append(native)
            try:
                self.assertAlmostEqual(
                    c.derivative(method, 0.001, native, 3), 6, places=10
                )
            finally:
                holder.clear()
                native.close()

    def test_trajectory_is_forced_before_callback_scope_ends(self):
        calls = []
        with ode.rk4() as method, ode.default_ode_options() as options:

            def rhs(time, values):
                calls.append(time)
                return [-x for x in values]

            trajectory = ode.solve_ivp(method, options, 4, rhs, 0, 1, [1])
        before = len(calls)
        states = ode.trajectory_states(trajectory)
        trajectory.close()
        self.assertEqual(len(calls), before)
        self.assertEqual(len(states), 5)
        self.assertAlmostEqual(states[-1][0], 0.3678942, places=6)


if __name__ == "__main__":
    unittest.main()
