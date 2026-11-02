# SPDX-License-Identifier: MPL-2.0
"""Optimization contracts beyond direct source equivalence.

Set HMATH_LIBRARY to the built native library and PYTHONPATH=bindings/python.
"""

import ctypes as C
import gc
import threading
import unittest
import weakref
from concurrent.futures import ThreadPoolExecutor

import hmath
from _hmath_native import _math_error as wire
from _hmath_native import _value as value
from hmath import errors
from hmath import optimization as opt


def raise_error(error):
    def function(_):
        raise error

    return function


class OptimizationContracts(unittest.TestCase):
    def setUp(self):
        hmath.initialize()

    def test_all_math_error_constructors_roundtrip(self):
        payload = ("한국어\x00𝄞\ud800\udfff" * 3000) + "tail"
        cases = [
            errors.NegativeDimensions((-2, 3)),
            errors.ElementCountOverflow((2, 3)),
            errors.ElementCountMismatch(5, 6),
            errors.ShapeMismatch((1, 2), (3, 4)),
            errors.InnerDimensionMismatch(5, 6),
            errors.IndexOutOfBounds((1, 2), (3, 4)),
            errors.SliceOutOfBounds((1, 2), (3, 4), (5, 6)),
            errors.VectorLengthMismatch(5, 6),
            errors.NonSquareMatrix((2, 3)),
            errors.InvalidTolerance(),
            errors.SingularMatrix(2),
            errors.NearSingularMatrix(3),
            errors.NonFiniteMatrixEntry((2, 3)),
            errors.NonFiniteVectorEntry(4),
            errors.NonFiniteResult(),
            errors.RightHandSideMismatch(5, 6),
            errors.DomainError(payload),
            errors.InvalidArgument(payload),
            errors.NonConvergence(payload, -3),
            errors.RankDeficient(2),
            errors.NotPositiveDefinite(3),
        ]
        for expected in cases:
            with self.subTest(kind=expected.kind):
                with self.assertRaises(hmath.HMathError) as caught:
                    opt.checked_value(raise_error(expected), [1])
                actual = caught.exception.math_error
                self.assertEqual(caught.exception.status, 11)
                self.assertEqual(actual.kind, expected.kind)
                self.assertEqual(actual.details, expected.details)
                self.assertEqual(actual.message, expected.message)
                # Querying does not consume or clear the complete payload.
                self.assertEqual(
                    wire.last_math_error(hmath._lib).message, expected.message
                )
                self.assertEqual(opt.checked_value(lambda x: 2.0, [1]), 2.0)
                self.assertIsNone(wire.last_math_error(hmath._lib))

    def test_error_state_is_thread_local(self):
        barrier = threading.Barrier(3)

        def run(index):
            expected = errors.DomainError(f"thread {index}\x00tail")
            with self.assertRaises(hmath.HMathError):
                opt.checked_value(raise_error(expected), [1])
            barrier.wait()
            actual = wire.last_math_error(hmath._lib)
            barrier.wait()
            opt.checked_value(lambda x: 1, [1])
            return actual.message

        with ThreadPoolExecutor(max_workers=3) as pool:
            self.assertEqual(
                list(pool.map(run, range(3))), [f"thread {i}\x00tail" for i in range(3)]
            )

    def test_recoverable_callback_math_error_stays_left(self):
        # The original feasible barrier backtracking retries DomainError. A
        # globally thrown callback error would abort at its first rejected step.
        rejected = []

        def objective(x):
            if x[0] <= 0:
                rejected.append(x[0])
                raise errors.DomainError("outside objective domain")
            return x[0] * x[0]

        options = opt.OptimizeOptions(200, 50000, 1e-5, 0.25)
        result = opt.constrained_minimize(
            opt.LogBarrier,
            options,
            objective,
            lambda x: [2 * x[0]],
            [opt.LessEqual(lambda x: -x[0], lambda x: [-1])],
            [1],
        )
        self.assertTrue(rejected)
        self.assertTrue(result.converged)
        self.assertGreater(result.point[0], 0)

    def test_unexpected_exception_is_identical_after_cleanup(self):
        for exception in [KeyboardInterrupt("stop"), ValueError("failure")]:
            with self.assertRaises(type(exception)) as caught:
                opt.checked_value(raise_error(exception), [1])
            self.assertIs(caught.exception, exception)
            self.assertEqual(opt.checked_value(lambda x: 1, [1]), 1)

    def test_exception_string_failure_cannot_escape_callback(self):
        class BrokenException(Exception):
            def __str__(self):
                raise RuntimeError("no message")

        exception = BrokenException()
        with self.assertRaises(BrokenException) as caught:
            opt.checked_value(raise_error(exception), [1])
        self.assertIs(caught.exception, exception)

    def test_callback_result_checks_preserve_source_conditions(self):
        cases = [
            (
                lambda: opt.checked_value(lambda x: float("nan"), [1]),
                errors.NonFiniteResult(),
            ),
            (
                lambda: opt.checked_gradient(lambda x: [], [1]),
                errors.VectorLengthMismatch(1, 0),
            ),
            (
                lambda: opt.checked_gradient(lambda x: [float("inf")], [1]),
                errors.NonFiniteResult(),
            ),
        ]
        for call, expected in cases:
            with self.subTest(kind=expected.kind):
                with self.assertRaises(hmath.HMathError) as caught:
                    call()
                self.assertEqual(caught.exception.math_error.kind, expected.kind)
                self.assertEqual(caught.exception.math_error.details, expected.details)

    def test_monitor_stops_and_preserves_diagnostics(self):
        observed = []

        def monitor(result):
            observed.append(result)
            return False

        result = opt.minimize_gradient_with_callback(
            monitor,
            opt.GradientMethod.ADAM,
            opt.OptimizeOptions(),
            lambda x: x[0] ** 2,
            lambda x: [2 * x[0]],
            [3],
        )
        self.assertEqual(result, opt.OptimizeResult([3.0], 9.0, 6.0, 0, 2, False))
        self.assertEqual(observed, [result])

    def test_transitive_callback_ownership_and_reentrant_close(self):
        class Gradient:
            def __call__(self, point):
                return [2 * v for v in point]

        callback = Gradient()
        reference = weakref.ref(callback)
        function = opt.mini_batch_gradient([callback])
        del callback
        gc.collect()
        self.assertIsNotNone(reference())
        self.assertEqual(function([3]), [6])
        function.close()
        gc.collect()
        self.assertIsNone(reference())
        holder = {}

        def reentrant(point):
            holder["function"].close()
            return point

        holder["function"] = opt.mini_batch_gradient([reentrant])
        self.assertEqual(holder["function"]([3]), [3])
        with self.assertRaises(ValueError):
            holder["function"]([3])

    def test_zz_lifetime_blocks_shutdown_and_releases(self):
        function = opt.weighted_objective([1], [sum])
        with self.assertRaises(hmath.HMathError) as caught:
            hmath.shutdown()
        self.assertEqual(caught.exception.status, 9)
        function.close()
        # Other modules may retain nothing, and every failed callback above
        # must have cleaned up its temporary Values and runtime reservations.
        gc.collect()
        hmath.shutdown()

    def test_generic_transpose_preserves_exact_values_and_ragged_rows(self):
        from fractions import Fraction

        self.assertEqual(
            opt.transpose([[10**100, Fraction(2, 3)], [None]]),
            [[10**100, None], [Fraction(2, 3)]],
        )

    def test_word64_seed_is_checked_without_float_conversion(self):
        options = opt.OptimizeOptions(1, 100, 1e-7, 0.1)
        args = (
            opt.DifferentialEvolution,
            4,
            2**64 - 1,
            options,
            [(-1, 1)],
            lambda x: x[0] ** 2,
        )
        self.assertEqual(opt.global_minimize(*args), opt.global_minimize(*args))
        for seed in [-1, 2**64]:
            with self.assertRaises((OverflowError, ValueError, hmath.HMathError)):
                opt.global_minimize(
                    opt.DifferentialEvolution,
                    4,
                    seed,
                    options,
                    [(-1, 1)],
                    lambda x: x[0] ** 2,
                )

    def test_failure_does_not_publish_output(self):
        # Named C wrappers share the transactional output guarantee.
        output = C.c_void_p(0x1234)
        hmath.initialize()
        status = value.api(
            "hmath_optimization_checked_point",
            C.c_int,
            C.c_void_p,
            C.c_void_p,
            C.POINTER(C.c_void_p),
        )(None, None, C.byref(output))
        self.assertEqual(status, 1)
        self.assertEqual(output.value, 0x1234)


if __name__ == "__main__":
    unittest.main()
