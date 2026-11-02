# SPDX-License-Identifier: MPL-2.0
"""Source budgets, exact instances, nominal shapes and retained callback owners."""

import gc
import struct
import sys
import weakref
from fractions import Fraction as Q
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "bindings/python"))
import hmath
from _hmath_native import algebra as a
from _hmath_native import algebra_api as p
from _hmath_native import algorithm_values as algorithms
from _hmath_native import combinatorics_values as combinatorics
from _hmath_native import convergence_values as c
from _hmath_native import data_structures as d
from _hmath_native import discrete_values as discrete
from _hmath_native import matrix_advanced, vector
from _hmath_native import shape_values as s
from _hmath_native._expression_error import ErrorKind, ExprError, SourcePos
from _hmath_native._interchange_error import InterchangeError, InterchangeErrorKind
from _hmath_native._linear_base import _callback
from _hmath_native._math_error import MathError, MathErrorKind

big = 10**6000 + 7
with d.fenwick([big, 2]) as original, d.fenwick_add(0, 3, original) as changed:
    assert d.fenwick_prefix(2, original) == big + 2
    assert d.fenwick_prefix(2, changed) == big + 5
assert algorithms.run_length_encode(["x\0α\ud800", "x\0α\ud800", "🙂"]) == [
    ("x\0α\ud800", 2),
    ("🙂", 1),
]
assert combinatorics.finite_differences([big, big + 1, big + 4]) == [
    [big, big + 1, big + 4],
    [1, 3],
    [2],
]
for operation in [
    lambda: combinatorics.subsets(1, [1, 2]),
    lambda: discrete.bit_set(-1, 0),
]:
    try:
        operation()
    except hmath.HMathError:
        pass
    else:
        raise AssertionError("original budget/dimension check was discarded")

with c.optional_type(0) as optional:
    with d.Heap([None, None], prototype=optional) as heap:
        first, next_heap = d.heap_pop(heap)
        assert first is None
        second, empty = d.heap_pop(next_heap)
        assert second is None and d.heap_pop(empty) is None
        next_heap.close()
        empty.close()
    assert d.next_greater([None, None], prototype=optional) == [None, None]
    with discrete.MultiSet([None, None], prototype=optional) as multi:
        assert discrete.multiset_entries(multi) == [(None, 2)]
    with (
        c.optional_type(optional) as nested,
        c.just(None) as just_none,
        d.heap_from_list([just_none, None], prototype=nested) as heap,
    ):
        value, next_heap = d.heap_pop(heap)
        assert value is None
        value, end = d.heap_pop(next_heap)
        assert isinstance(value, c.Just) and value.parts == ("Just", None)
        value.close()
        next_heap.close()
        end.close()
with c.right(None) as choice, c.result_maybe(choice) as present:
    assert present.parts == ("Just", None)
with c.from_maybe_error("error", None) as choice:
    assert choice.parts == ("Left", "error")

with p.Exact(Q(big, 7)) as x, p.Exact(Q(2, 5)) as y, p.plus(x, y) as z:
    assert z.value == Q(big, 7) + Q(2, 5)
    with p.horner([x, y], y) as h:
        assert h.value == Q(big, 7) * Q(2, 5) + Q(2, 5)
    with p.matrix_construct(1, 2, [x, y]) as matrix:
        assert matrix.dtype == "exact"
        values = matrix.to_list()
        assert [v.value for v in values] == [Q(big, 7), Q(2, 5)]
        for value in values:
            value.close()
    with (
        s.coordinates(2, [x, y], dtype=x) as coordinates,
        s.coordinates_to_vector(coordinates) as v,
    ):
        values = vector.vector_values(v)
        assert [value.value for value in values] == [Q(big, 7), Q(2, 5)]
        for value in values:
            value.close()
    with (
        p.tensor_construct([2], [x, y]) as tensor,
        s.static_tensor([2], tensor) as static,
        s.dynamic_tensor(static) as dynamic,
    ):
        values = p.tensor_elements(dynamic)
        assert [v.value for v in values] == [Q(big, 7), Q(2, 5)]
        for value in values:
            value.close()
    with x.element_type as element, vector.vector([x, y], dtype=element) as v:
        assert vector.vector_dimension(v) == 2
assert struct.pack("f", p.plus(16777216.0, 1.0, dtype="float32")) == struct.pack(
    "f", 16777216.0
)
assert p.plus(16777216.0, 1.0, dtype="float64") == 16777217.0
for operation in [
    lambda: a.plus(1.0, 2.0),
    lambda: p.invert(1),
    lambda: p.machine_epsilon(dtype="rational"),
]:
    try:
        operation()
    except hmath.HMathError as error:
        assert error.status == 10
    else:
        raise AssertionError("adapter invented an original typeclass instance")
with a.modular(7, 3) as left, a.modular(5, 3) as right:
    try:
        a.add_modular(left, right)
    except hmath.HMathError as error:
        assert error.math_error.kind == MathErrorKind.DOMAIN_ERROR
    else:
        raise AssertionError("different runtime rings were silently combined")
assert s.reflected_shape([2**100, 0]) == [2**100, 0]
with (
    p.matrix_construct(2, 2, [1, 2, 3, 4]) as matrix,
    s.static_matrix(2, 2, matrix) as static,
    s.static_transpose(static) as transpose,
    s.static_multiply(static, transpose) as product,
    s.dynamic_matrix(product) as dynamic,
):
    assert dynamic.to_list() == [5, 11, 11, 25]
with (
    s.coordinates(2, ["α\0", "🙂\ud800"], dtype="string") as coordinates,
    s.coordinates_to_vector(coordinates) as v,
    vector.vector_slice(1, 1, v) as suffix,
):
    assert vector.vector_values(suffix) == ["🙂\ud800"]

with c.IterationOptions(8, 0.0, 0.0) as options:
    calls = []

    def step(state):
        calls.append(state)
        return (state[0] + 1, state[1] + 2)

    with c.iterate_until(
        options,
        step,
        lambda state: float(3 - state[0]),
        lambda old, new: old == new,
        (0, 5),
    ) as result:
        assert result.estimate == (3, 11) and len(calls) == 3
    message = "callback\0α🙂\ud800"
    failures = [
        MathError(MathErrorKind.NON_CONVERGENCE, (7,), message),
        ExprError(ErrorKind.TYPE_MISMATCH, SourcePos(19, 3, 5), message),
        InterchangeError(InterchangeErrorKind.INVALID_DATA, message),
    ]
    for failure in failures:

        def failing(_state, failure=failure):
            raise failure

        try:
            c.iterate_until(options, failing, lambda _x: 1.0, lambda _a, _b: False, 0)
        except hmath.HMathError as error:
            payload = (
                error.math_error or error.expression_error or error.interchange_error
            )
            assert vars(payload) == vars(failure)
        else:
            raise AssertionError("callback domain error payload was replaced")

    class BrokenMessage(Exception):
        def __str__(self):
            raise RuntimeError("broken formatter")

    unexpected = BrokenMessage()

    def unexpected_step(_state):
        raise unexpected

    try:
        c.iterate_until(
            options, unexpected_step, lambda _x: 1.0, lambda _a, _b: False, 0
        )
    except BrokenMessage as error:
        assert error is unexpected
    else:
        raise AssertionError("unexpected callback exception was swallowed")

    # A caught recursive callback error must not replace an unrelated later
    # source failure, and must not poison a successful outer invocation.
    active = False
    shared = None

    def reentrant_step(state):
        global active
        if active:
            raise unexpected
        active = True
        try:
            try:
                c.iterate_until(
                    options, shared, lambda _x: 1.0, lambda _a, _b: False, 0
                )
            except BrokenMessage:
                pass
        finally:
            active = False
        return state + 1

    shared = _callback(reentrant_step, ["a"], "integer")
    with (
        shared,
        c.iterate_until(
            options, shared, lambda x: float(2 - x), lambda _a, _b: False, 0
        ) as result,
    ):
        assert result.estimate == 2


class Userdata:
    pass


references = []


def return_function(_state):
    userdata = Userdata()
    references.append(weakref.ref(userdata))

    def operation(row, column):
        assert userdata is not None
        return float(row + column)

    return _callback(operation, ["a"], "float64")


with c.IterationOptions(1, 0.0, 0.0) as options:
    report = c.iterate_until(
        options,
        return_function,
        lambda state: 1.0 if state is None else 0.0,
        lambda _a, _b: False,
        None,
    )
function = report.estimate
report.close()
gc.collect()
assert references[0]() is not None
with matrix_advanced.generate_matrix(1, 2, function) as matrix:
    assert matrix.to_list() == [0.0, 1.0]
function.close()
gc.collect()
assert references[0]() is None
print(
    "Foundation exact/typedOrd/nestedMaybe/sourcebudgets/nominaltypes/Float32/cross-domain-errors/reentrant-callback/lifetime contracts passed"
)
