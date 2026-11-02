# SPDX-License-Identifier: MPL-2.0
"""Structured callback failures remain lossless across AD and tensor boundaries."""

import gc
import os
import sys
import unittest
from pathlib import Path

if os.environ.get("HMATH_LIBRARY"):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "bindings/python"))
import hmath
from _hmath_native import _tensor_core as tensor
from _hmath_native import autodiff as ad
from _hmath_native._expression_error import ErrorKind, ExprError, SourcePos
from _hmath_native._interchange_error import InterchangeError, InterchangeErrorKind
from _hmath_native._math_error import _ARITY, MathError, MathErrorKind


def fail(error):
    raise error


class CallbackErrors(unittest.TestCase):
    def test_all_original_math_error_constructors(self):
        for kind in MathErrorKind:
            details = tuple(range(-_ARITY[kind], 0))
            message = "full\0payload\ud800한글" + "x" * 6000
            original = MathError(kind, details, message if kind in (17, 18, 19) else "")
            with (
                self.subTest(kind=kind),
                ad.variable(0) as x,
                ad.custom_operation(
                    lambda _, original=original: fail(original), [x]
                ) as expr,
            ):
                with self.assertRaises(hmath.HMathError) as caught:
                    ad.value_and_gradient(expr, [2])
                actual = caught.exception.math_error
                self.assertEqual(caught.exception.status, 11)
                self.assertEqual(
                    (actual.kind, actual.details, actual.message),
                    (original.kind, original.details, original.message),
                )

    def test_domain_errors_cross_rule_unary_checkpoint_and_tensor(self):
        payload = "domain\0한글\udfff" + "z" * 4096
        originals = [
            ExprError(ErrorKind.SYNTAX_ERROR, SourcePos(-7, 22, 103), payload),
            InterchangeError(InterchangeErrorKind.IO_ERROR, payload),
        ]
        for original in originals:
            for route in ("rule", "unary", "checkpoint", "tensor"):
                with self.subTest(error=type(original).__name__, route=route):
                    with self.assertRaises(hmath.HMathError) as caught:
                        if route == "tensor":
                            with tensor.tensor([1], [2]) as base:
                                tensor.map_tensor(
                                    lambda _, original=original: fail(original), base
                                )
                        else:
                            with ad.variable(0) as x:
                                if route == "rule":
                                    expr = ad.custom_operation(
                                        lambda _, original=original: fail(original), [x]
                                    )
                                elif route == "unary":
                                    expr = ad.custom_unary(
                                        lambda _, original=original: fail(original),
                                        lambda _: 0,
                                        x,
                                    )
                                else:
                                    expr = ad.checkpoint(
                                        lambda _, original=original: fail(original), [x]
                                    )
                                with expr:
                                    ad.value_and_gradient(expr, [2])
                    if isinstance(original, ExprError):
                        self.assertEqual(caught.exception.status, 12)
                        self.assertEqual(caught.exception.expression_error, original)
                    else:
                        self.assertEqual(caught.exception.status, 13)
                        self.assertEqual(caught.exception.interchange_error, original)

    def test_malformed_math_error_details_never_narrow(self):
        original = MathError(MathErrorKind.SINGULAR_MATRIX, [1])
        original.details = (1 << 200,)
        with (
            ad.variable(0) as x,
            ad.custom_operation(
                lambda _, original=original: fail(original), [x]
            ) as expr,
            self.assertRaises(OverflowError),
        ):
            ad.gradient(expr, [2])
        with self.assertRaises(OverflowError):
            MathError(MathErrorKind.NON_CONVERGENCE, [1 << 200], "budget")

    def test_unexpected_base_exception_and_checkpoint_cleanup(self):
        original = KeyboardInterrupt("original identity")
        for route in ("rule", "checkpoint"):
            with self.subTest(route=route):
                with ad.variable(0) as x:
                    expr = (
                        ad.custom_operation(
                            lambda _, original=original: fail(original), [x]
                        )
                        if route == "rule"
                        else ad.checkpoint(
                            lambda _, original=original: fail(original), [x]
                        )
                    )
                    with expr:
                        with self.assertRaises(KeyboardInterrupt) as caught:
                            ad.gradient(expr, [2])
                        self.assertIs(caught.exception, original)
                original.__traceback__ = None
        gc.collect()


if __name__ == "__main__":
    unittest.main(argv=[__file__])
