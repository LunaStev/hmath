# SPDX-License-Identifier: MPL-2.0
"""Neural cross-domain ownership, immutable states and public interface contracts."""

import gc
import math
import os
import sys
import unittest
from pathlib import Path

if os.environ.get("HMATH_LIBRARY"):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "bindings/python"))
import hmath
from hmath import autodiff as ad
from hmath import deeplearning_core as core
from hmath import deeplearning_layers as layers
from hmath import deeplearning_metrics as metrics
from hmath import deeplearning_precision as precision
from hmath import random, tensor


def close(value):
    if isinstance(value, (list, tuple)):
        for item in value:
            close(item)
    elif hasattr(value, "close"):
        value.close()


class NeuralBindings(unittest.TestCase):
    def test_fixed_double_and_public_namespaces(self):
        self.assertEqual(core.activation(core.Sigmoid, 0), 0.5)
        with (
            tensor.tensor([1, 2], [1, 2]) as x,
            tensor.tensor([1, 2], [3, 4]) as w,
            layers.dense(x, w, [1]) as output,
        ):
            self.assertIsInstance(output, tensor.TensorDouble)
            self.assertEqual(output.values, [12])
        with (
            tensor.tensor([1, 2], [1, 2], dtype="float32") as x,
            tensor.tensor([1, 2], [3, 4]) as w,
            self.assertRaises(hmath.HMathError),
        ):
            layers.dense(x, w, [1])

    def test_explicit_full_rng_continuation(self):
        with (
            random.pcg32() as generator,
            random.seed_rng(generator, 42) as rng,
            tensor.tensor([1, 2, 3], list(range(6))) as x,
        ):
            original = rng.serialize()
            first = layers.spatial_dropout(layers.Training.TRAINING, 0.5, rng, x)
            second = layers.spatial_dropout(layers.Training.TRAINING, 0.5, rng, x)
            try:
                self.assertEqual(first[0].values, second[0].values)
                self.assertEqual(first[1].values, second[1].values)
                self.assertEqual(first[2].serialize(), second[2].serialize())
                self.assertNotEqual(first[2].serialize(), original)
                self.assertEqual(rng.serialize(), original)
                self.assertTrue(
                    all(
                        len(set(first[1].values[start : start + 3])) == 1
                        for start in (0, 3)
                    )
                )
            finally:
                close(first)
                close(second)
            inference = layers.dropout(layers.Inference, 0.9, rng, x)
            try:
                self.assertEqual(inference[0].values, x.values)
                self.assertEqual(inference[2].serialize(), original)
            finally:
                close(inference)

    def test_batch_norm_records_original_state_unchanged(self):
        state = layers.BatchNormState([0], [1], 0)
        with tensor.tensor([2, 1], [1, 3]) as x:
            output, updated = layers.batch_norm(
                layers.Training.TRAINING, 0.1, 1e-5, [1], [0], state, x
            )
            try:
                self.assertEqual(updated.batches_seen, 1)
                self.assertEqual(updated.running_mean, [0.2])
                self.assertEqual(updated.running_variance, [1.1])
                self.assertEqual(state, layers.BatchNormState([0], [1], 0))
                self.assertEqual(layers.running_mean(updated), updated.running_mean)
                self.assertEqual(
                    layers.running_variance(updated), updated.running_variance
                )
                self.assertEqual(layers.batches_seen(updated), 1)
            finally:
                output.close()

    def test_cache_independent_original_objects_and_capacity(self):
        cache = layers.empty_cache(2, 1, 1)
        with (
            tensor.tensor([2, 1], [1, 2]) as keys,
            tensor.tensor([2, 1], [3, 4]) as values,
        ):
            updated = layers.append_cache(cache, keys, values)
            empty = layers.cache_values(cache)
            try:
                self.assertEqual(empty[0].shape, [0, 1])
                self.assertEqual(empty[1].values, [])
            finally:
                close(empty)
            with self.assertRaises(hmath.HMathError):
                layers.append_cache(updated, keys, values)
        cache.close()
        extracted = layers.cache_values(updated)
        updated.close()
        try:
            self.assertEqual(extracted[0].values, [1, 2])
            self.assertEqual(extracted[1].values, [3, 4])
        finally:
            close(extracted)

    def test_quantized_fields_and_loss_scaler_transitions(self):
        with (
            tensor.tensor([2, 2], [-2, -1, 1, 2]) as x,
            precision.quantize(precision.Symmetric, 0, x) as quantized,
        ):
            self.assertEqual(quantized.values, precision.quantized_values(quantized))
            self.assertEqual(quantized.scales, precision.quantization_scales(quantized))
            self.assertEqual(
                quantized.zero_points, precision.quantization_zero_points(quantized)
            )
            self.assertEqual(quantized.zero_points, [0, 0])
            with precision.dequantize(quantized) as restored:
                self.assertEqual(restored.shape, [2, 2])
        initial = precision.initial_loss_scaler(128, 2)
        one = precision.update_loss_scaler(True, initial)
        two = precision.update_loss_scaler(True, one)
        failed = precision.update_loss_scaler(False, two)
        self.assertEqual(initial, precision.LossScaler(128, 2, 0))
        self.assertEqual(one, precision.LossScaler(128, 2, 1))
        self.assertEqual(two, precision.LossScaler(256, 2, 0))
        self.assertEqual(failed, precision.LossScaler(128, 2, 0))
        self.assertEqual(precision.unscale_gradients(initial, [math.inf]), (False, []))

    def test_original_graph_and_callback_owner_interchange(self):
        def objective(xs):
            with ad.custom_unary(
                lambda value: value * value, lambda value: 2 * value, xs[0]
            ) as square:
                return core.activation_expr(core.Sigmoid, square)

        value, gradient = ad.value_and_gradient(objective, [2])
        expected = core.activation(core.Sigmoid, 4)
        self.assertEqual(value, expected)
        self.assertEqual(gradient, [4 * expected * (1 - expected)])
        with ad.variable(0) as x, core.activation_expr(core.ReLU, x) as activated:
            self.assertEqual(ad.value_and_gradient(activated, [0]), (0, [0]))

    def test_attention_fully_masked_and_classification_diagnostics(self):
        with (
            tensor.tensor([1, 2], [1, 2]) as query,
            tensor.tensor([1, 2], [3, 4]) as key,
            tensor.tensor([1, 1], [9]) as value,
        ):
            output, weights = layers.scaled_dot_product_attention(
                query, key, value, [[False]], None
            )
            try:
                self.assertEqual(output.values, [0])
                self.assertEqual(weights.values, [0])
            finally:
                close((output, weights))
        result = metrics.classification_metrics(3, [0, 1, 1, 2], [0, 2, 1, 2])
        self.assertEqual(result.accuracy, 0.75)
        self.assertEqual(result.precision, [1, 1, 0.5])
        self.assertEqual(result.recall, [1, 0.5, 1])
        self.assertEqual(result.f1, [1, 2 / 3, 2 / 3])
        self.assertEqual(metrics.accuracy(result), 0.75)
        self.assertEqual(metrics.precision_by_class(result), result.precision)

    def test_original_errors_and_final_cleanup(self):
        with self.assertRaises(hmath.HMathError) as error:
            core.activation(core.ELU(0), 1)
        self.assertEqual(
            error.exception.math_error.message, "positive ELU alpha required"
        )
        self.assertEqual(core.activation(core.Sigmoid, 1000), 1)
        gc.collect()


if __name__ == "__main__":
    unittest.main(argv=[__file__])
