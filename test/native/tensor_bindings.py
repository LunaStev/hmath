# SPDX-License-Identifier: MPL-2.0
"""Original typed tensors, lazy graph callbacks and actual pinned mutable contracts."""

import ctypes as C
import gc
import math
import unittest
import weakref
from fractions import Fraction

import hmath
from _hmath_native import _tensor_core as t
from _hmath_native import _value as v
from _hmath_native import autodiff as ad
from _hmath_native import numeric_types as n
from _hmath_native._autodiff_value import export_value, import_value
from hmath import errors


class TensorContracts(unittest.TestCase):
    def test_supported_element_types_roundtrip_without_promotion(self):
        cases = [
            ("float64", [1.25, -2]),
            ("float32", [1.25, -2]),
            ("integer", [10**100, -3]),
            ("rational", [Fraction(1, 3), Fraction(2, 7)]),
            ("complex128", [1 + 2j, -3 + 4j]),
            ("complex64", [1 + 2j, -3 + 4j]),
            ("int8", [-128, 127]),
            ("uint64", [0, 2**64 - 1]),
            ("bool", [True, False]),
            ("string", ["λ\x00\ud800", "𝄞"]),
        ]
        for dtype, values in cases:
            with (
                self.subTest(dtype=dtype),
                t.tensor([2], values, dtype=dtype) as tensor,
            ):
                self.assertEqual(tensor.values, values)
                text = t.serialize_tensor(tensor)
                with t.deserialize_tensor(text, dtype=dtype) as restored:
                    self.assertEqual(tensor, restored)

    def test_column_major_reverse_and_broadcast_views_keep_metadata(self):
        original = t.tensor_column_major([2, 2], [1, 2, 3, 4], dtype="float32")
        self.assertEqual(original.values, [1, 3, 2, 4])
        self.assertEqual(original.strides, [1, 2])
        self.assertEqual(original.layout, t.ColumnMajor)
        view = t.slice_tensor(1, 1, 2, -1, original)
        original.close()
        with view:
            self.assertEqual(view.values, [3, 1, 4, 2])
            self.assertEqual(view.strides, [1, -2])
            self.assertEqual(view.offset, 2)
            with (
                t.broadcast_to([3, 2, 2], view) as broadcast,
                t.contiguous(broadcast) as copy,
            ):
                self.assertEqual(broadcast.strides, [0, 1, -2])
                self.assertEqual(copy.values, view.values * 3)
                self.assertTrue(copy.is_contiguous)

    def test_original_rank_and_shape_rules_do_not_inherit_legacy_caps(self):
        with t.tensor([0] + [2] * 100, [], dtype="float32") as empty:
            self.assertEqual(len(empty.shape), 101)
            self.assertEqual(empty.numel, 0)
        with t.tensor([], [7], dtype="integer") as scalar:
            self.assertEqual(t.index_tensor(scalar, []), 7)
            with t.nonzero(scalar) as indices:
                self.assertEqual(indices.shape, [1, 0])
        with self.assertRaises(hmath.HMathError) as caught:
            t.tensor([0, -1], [], dtype="integer")
        self.assertEqual(
            caught.exception.math_error.kind, errors.MathErrorKind.INVALID_ARGUMENT
        )
        with self.assertRaises(hmath.HMathError):
            t.new_mutable([2 ** (C.sizeof(C.c_ssize_t) * 8 - 1) - 1], 0)

    def test_original_class_requirements_are_rejected_without_casts(self):
        with (
            t.tensor([1], [1], dtype="integer") as integer,
            t.tensor([1], [1], dtype="complex128") as complex_tensor,
            t.tensor([1], [True], dtype="bool") as logical,
        ):
            calls = [
                lambda: t.tensor_divide(integer, integer),
                lambda: t.thaw_tensor(integer),
                lambda: t.norm_axes([0], False, integer),
                lambda: t.sort_tensor(complex_tensor),
                lambda: t.tensor_add(logical, logical),
            ]
            for call in calls:
                with self.assertRaises(hmath.HMathError) as caught:
                    call()
                self.assertEqual(caught.exception.status, 10)

    def test_explicit_promotion_and_original_fixed_width_arithmetic(self):
        with (
            t.tensor([1], [1.0000001], dtype="float32") as single,
            t.tensor([1], [1], dtype="float64") as double,
        ):
            with self.assertRaises(hmath.HMathError):
                t.tensor_add(single, double)
            with t.promote_tensor("float64", single) as promoted:
                self.assertEqual(promoted.values, single.values)
        with (
            t.tensor([1], [127], dtype="int8") as maximum,
            t.tensor_ones([1], dtype="int8") as one,
            t.tensor_add(maximum, one) as wrapped,
        ):
            self.assertEqual(wrapped.values, [-128])
        with self.assertRaises((OverflowError, ValueError, hmath.HMathError)):
            t.tensor([1], [128], dtype="int8")

    def test_masks_gather_scatter_and_duplicate_updates(self):
        with (
            t.tensor([3], [1, 2, 3], dtype="integer") as original,
            t.tensor([3], [True, False, True], dtype="bool") as mask,
        ):
            with t.masked_select(mask, original) as selected:
                self.assertEqual(selected.values, [1, 3])
            with t.masked_fill(mask, 7, original) as filled:
                self.assertEqual(filled.values, [7, 2, 7])
            with t.gather(0, [2, 0, 2], original) as gathered:
                self.assertEqual(gathered.values, [3, 1, 3])
            with t.tensor([2], [4, 5], dtype="integer") as updates:
                with t.scatter(0, [1, 1], updates, original) as last:
                    self.assertEqual(last.values, [1, 5, 3])
                with t.scatter_add(0, [1, 1], updates, original) as added:
                    self.assertEqual(added.values, [1, 11, 3])
            self.assertEqual(original.values, [1, 2, 3])

    def test_typed_callback_arithmetic_and_borrowed_scalar_lifetime(self):
        seen = []

        def cube(value):
            seen.append(value)
            return value * value * value

        with (
            t.tensor([1], [1.0000001], dtype="float32") as tensor,
            t.map_tensor(cube, tensor) as result,
        ):
            self.assertEqual(result.dtype, "float32")
            self.assertEqual(result.values, [1.0000003576278687])
        with self.assertRaises(ValueError):
            _ = seen[0].info
        with (
            t.tensor([1], ["λ"], dtype="string") as tensor,
            t.map_tensor(str.upper, tensor) as result,
        ):
            self.assertEqual(result.values, ["Λ"])
        with (
            t.tensor([2], [1, 0], dtype="integer") as tensor,
            t.map_tensor(lambda x: x == 0, tensor, dtype="bool") as result,
        ):
            self.assertEqual(result.values, [False, True])

    def test_numeric_dual_tensor_preserves_original_forward_fields(self):
        with (
            v.scalar(3, "float32") as primal,
            v.scalar(1, "float32") as tangent,
            n.dual(primal, tangent, boxed=True) as dual,
        ):
            with (
                t.tensor([1], [dual], dtype=dual) as tensor,
                t.map_tensor(lambda x: x * x, tensor) as result,
            ):
                fields = result.values
                try:
                    with fields[0].primal as p, fields[0].tangent as q:
                        self.assertEqual(p.value, 9)
                        self.assertEqual(q.value, 6)
                        self.assertEqual(p.dtype, "float32")
                finally:
                    for value in fields:
                        value.close()
            with self.assertRaises(hmath.HMathError) as caught:
                t.deserialize_tensor("([],[])", dtype=dual)
            self.assertEqual(caught.exception.status, 10)

    def test_lazy_graph_transitive_owners_and_reentrant_close(self):
        calls = []

        class Square:
            def __call__(self, value):
                calls.append(1)
                return value * value

        function = Square()
        reference = weakref.ref(function)
        tensor = t.tensor([2], [2, 3], dtype="float32")
        leaf = t.input_graph(tensor)
        graph = t.map_graph(function, leaf)
        del function
        tensor.close()
        leaf.close()
        gc.collect()
        self.assertEqual(calls, [])
        self.assertIsNotNone(reference())
        with graph.evaluate() as result:
            self.assertEqual(result.values, [4, 9])
        graph.close()
        gc.collect()
        self.assertIsNone(reference())
        holder = {}

        def close_during_call(value):
            holder["graph"].close()
            return value + 1

        with t.tensor([1], [2]) as tensor, t.input_graph(tensor) as leaf:
            holder["graph"] = t.map_graph(close_during_call, leaf)
            with holder["graph"].evaluate() as result:
                self.assertEqual(result.values, [3])
        self.assertEqual(calls, [1, 1])

    def test_callback_error_payload_and_exception_identity(self):
        with t.tensor([1], [2], dtype="float32") as tensor:

            def fail(_):
                raise errors.DomainError("λ\x00" + "long" * 1000)

            with self.assertRaises(hmath.HMathError) as caught:
                t.map_tensor(fail, tensor)
            self.assertEqual(
                caught.exception.math_error.message, "λ\x00" + "long" * 1000
            )
            exception = KeyboardInterrupt("stop")

            def interrupt(_):
                raise exception

            with self.assertRaises(KeyboardInterrupt) as caught:
                t.map_tensor(interrupt, tensor)
            self.assertIs(caught.exception, exception)

    def test_mutable_views_share_storage_and_freeze_is_a_copy(self):
        with (
            t.new_mutable([2, 2], 0, dtype="float32") as original,
            t.slice_mutable(1, 1, 2, -1, original) as reversed_view,
            t.transpose_mutable(reversed_view) as transposed,
        ):
            t.write_mutable(transposed, [0, 1], 7)
            self.assertEqual(t.read_mutable(original, [1, 1]), 7)
            with t.freeze_tensor(transposed) as copied:
                t.write_mutable(original, [1, 1], 9)
                self.assertEqual(copied.values, [0, 7, 0, 0])
            with self.assertRaises(hmath.HMathError):
                t.write_mutable(original, [2, 0], 4)
            self.assertEqual(t.read_mutable(original, [1, 1]), 9)

    def test_borrowed_buffer_is_actual_strided_storage_and_scoped(self):
        saved = []
        with (
            t.new_mutable([3], 1, dtype="float32") as original,
            t.slice_mutable(0, 2, 3, -1, original) as reversed_view,
        ):

            def update(buffer):
                saved.append(buffer)
                self.assertEqual(buffer.strides, [-1])
                self.assertEqual(buffer.itemsize, C.sizeof(C.c_float))
                buffer.pointer[buffer.strides[0]] = 7
                return buffer.shape

            self.assertEqual(t.with_mutable_buffer(reversed_view, update), [3])
            self.assertEqual(t.read_mutable(original, [1]), 7)
        with self.assertRaises(ValueError):
            _ = saved[0].pointer
        with t.new_mutable([2], True, dtype="bool") as logical:

            def change_boolean(buffer):
                self.assertEqual(buffer.itemsize, C.sizeof(C.c_int))
                self.assertEqual(buffer.alignment, t.mutable_alignment("bool"))
                buffer.pointer[0] = 0

            t.with_mutable_buffer(logical, change_boolean)
            with logical.freeze() as frozen:
                self.assertEqual(frozen.values, [False, True])

    def test_nan_policy_matches_generic_source_and_eq(self):
        with t.tensor([1], [float("nan")]) as tensor:
            self.assertFalse(tensor == tensor)  # noqa: PLR0124 - source Eq on NaN is non-reflexive
            with t.map_tensor(lambda x: x * x, tensor) as result:
                self.assertTrue(math.isnan(result.values[0]))

    def test_original_autodiff_dual_interchange_retains_nesting_and_order(self):
        with (
            ad.Dual(Fraction(2, 3), Fraction(1, 7), dtype="rational") as original,
            import_value(original) as value,
            export_value(value) as restored,
        ):
            self.assertEqual(value.info[0], 289)
            self.assertEqual(restored.primal, Fraction(2, 3))
            self.assertEqual(restored.tangent, Fraction(1, 7))
        with (
            ad.Dual(3, 1, dtype="float32") as inner,
            ad.Dual(inner, inner) as nested,
            import_value(nested) as value,
            export_value(value) as restored,
            restored.primal as primal,
        ):
            self.assertEqual(primal.primal, 3)

    def test_structural_exact_keeps_original_instances(self):
        from hmath import algebra_api as algebra
        from hmath import shape

        with (
            algebra.Exact(Fraction(1, 3)) as third,
            algebra.tensor_construct([2], [third, third]) as original,
            original.element_type as dtype,
        ):
            self.assertEqual(original.dtype_code, 18)
            self.assertEqual(dtype.info[0], 294)
            with t.tensor_full([3], third, dtype=dtype) as filled:
                values = filled.values
                try:
                    self.assertEqual(
                        [value.value for value in values], [Fraction(1, 3)] * 3
                    )
                finally:
                    for value in values:
                        value.close()
            with (
                shape.static_tensor([2], original) as static,
                shape.dynamic_tensor(static) as dynamic,
            ):
                self.assertEqual(dynamic.type_name, "Exact")
                self.assertEqual(dynamic.shape, [2])
            with t.sort_tensor(original) as sorted_values:
                values = sorted_values.values
                try:
                    self.assertEqual(
                        [value.value for value in values], [Fraction(1, 3)] * 2
                    )
                finally:
                    for value in values:
                        value.close()
            with self.assertRaises(hmath.HMathError) as error:
                t.tensor_add(original, original)
            self.assertEqual(error.exception.status, 10)

    def test_zz_every_temporary_owner_releases_runtime(self):
        gc.collect()
        hmath.shutdown()


if __name__ == "__main__":
    unittest.main()
