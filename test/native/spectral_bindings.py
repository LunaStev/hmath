# SPDX-License-Identifier: MPL-2.0
"""Borrowed FFT storage, original error atomicity and generic payload owners."""

import sys
import unittest
from fractions import Fraction
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "bindings/python"))
import hmath
import numpy as np
from hmath import fourier as f, matrix


class SpectralContracts(unittest.TestCase):
    def plan(self, n):
        with f.forward() as direction, f.automatic() as algorithm:
            return f.plan_fft(direction, algorithm, n)

    def test_in_place_matches_original_and_keeps_storage(self):
        samples = np.array([1 + 2j, 3 - 1j, 0, -2j], dtype=np.complex128)
        expected = f.fft(samples.tolist())
        address = samples.ctypes.data
        with self.plan(4) as plan:
            self.assertIsNone(f.fft_in_place(plan, samples))
        self.assertEqual(samples.ctypes.data, address)
        self.assertEqual(samples.tolist(), expected)

    def test_failure_leaves_storage_bits_unchanged(self):
        with self.plan(4) as plan:
            for samples in (
                np.array([1, 2], dtype=np.complex128),
                np.array([1, complex(float("nan"), 2), 3, 4], dtype=np.complex128),
                np.array([1, complex(float("inf"), 2), 3, 4], dtype=np.complex128),
            ):
                before = samples.tobytes()
                with self.assertRaises(hmath.HMathError) as caught:
                    f.fft_in_place(plan, samples)
                self.assertEqual(caught.exception.status, 11)
                self.assertIsNotNone(caught.exception.math_error)
                self.assertEqual(samples.tobytes(), before)

    def test_rejects_unsupported_buffers_without_mutation(self):
        readonly = np.ones(4, dtype=np.complex128)
        readonly.flags.writeable = False
        unaligned = np.ndarray(
            (4,), dtype=np.complex128, buffer=bytearray(65), offset=1
        )
        cases = (
            readonly,
            unaligned,
            np.ones(8, dtype=np.complex128)[::2],
            np.ones(4, dtype=np.complex64),
            np.ones((2, 2), dtype=np.complex128),
            np.ones(4, dtype=np.dtype(">c16")),
        )
        with self.plan(4) as plan:
            for samples in cases:
                before = samples.tobytes()
                with self.assertRaises(TypeError):
                    f.fft_in_place(plan, samples)
                self.assertEqual(samples.tobytes(), before)

    def test_generic_shift_keeps_exact_and_independent_matrix_payloads(self):
        with matrix.from_list(1, 1, [10**5000], dtype="integer") as original:
            shifted = f.fft_shift(
                [original, Fraction(1, 10**5000 + 1), "x\0α\ud800", None, True]
            )
        self.assertEqual(shifted[0:2], [None, True])
        owner = shifted[2]
        try:
            self.assertEqual(owner.to_list(), [10**5000])
            recovered = f.ifft_shift(shifted)
            try:
                self.assertEqual(recovered[0].to_list(), [10**5000])
                self.assertEqual(
                    recovered[1:], [Fraction(1, 10**5000 + 1), "x\0α\ud800", None, True]
                )
            finally:
                recovered[0].close()
        finally:
            owner.close()


if __name__ == "__main__":
    unittest.main()
