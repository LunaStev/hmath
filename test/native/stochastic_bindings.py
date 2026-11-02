# SPDX-License-Identifier: MPL-2.0
"""Complete immutable stream continuation, arbitrary elements and checked callbacks."""

import gc
import sys
import weakref
from fractions import Fraction
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "bindings/python"))
import hmath
from _hmath_native import matrix_advanced
from _hmath_native import probability_values as p
from _hmath_native import random_values as r
from _hmath_native import statistics_values as s
from _hmath_native._linear_base import _callback
from _hmath_native._math_error import MathError, MathErrorKind

for factory in [
    r.pcg32,
    r.xoshiro256_star_star,
    r.xoroshiro128_plus,
    r.mt19937,
    r.philox4x32,
    r.threefry2x64,
    r.cha_cha20,
]:
    with factory() as generator:
        state = r.seed_rng(generator, 2**64 - 1)
    word, partial = r.next_word64(state)
    assert isinstance(word, int) and 0 <= word < 2**64 and partial != state
    serialized = r.serialize_rng(partial)
    restored = r.restore_rng(serialized)
    clone = r.clone_rng(partial)
    assert restored == clone == partial
    first, next1 = r.next_word64(restored)
    second, next2 = r.next_word64(clone)
    assert first == second and next1 == next2
    for value in [state, partial, restored, clone, next1, next2]:
        value.close()
with r.pcg32() as generator:
    state = r.seed_rng(generator, 42)
objects = [
    None,
    True,
    10**6000 + 3,
    Fraction(10**5000 + 1, 7),
    "a\0α🙂\ud800",
    ("x", [1, 2]),
]
shuffled, end = r.shuffle(objects, state)
assert all(
    any(item == candidate for candidate in objects) for item in shuffled
) and len(shuffled) == len(objects)
end.close()
samples, end = r.sample_n(3, lambda rng: ("payload\0α", r.clone_rng(rng)), state)
assert samples == ["payload\0α"] * 3 and end == state
end.close()
calls = []
message = "checked\0α🙂\ud800"


def failing_inverse(x):
    calls.append(x)
    raise MathError(MathErrorKind.NON_CONVERGENCE, (11,), message)


try:
    r.inverse_transform(failing_inverse, state)
except hmath.HMathError as error:
    assert error.math_error.kind == MathErrorKind.NON_CONVERGENCE
    assert error.math_error.details == (11,) and error.math_error.message == message
else:
    raise AssertionError("checked callback Left was swallowed")
assert len(calls) == 1


# Pure callback failure aborts instead of becoming a fabricated successful value.
def bad_ratio(_x):
    raise MathError(MathErrorKind.DOMAIN_ERROR, (), message)


try:
    r.rejection(3, bad_ratio, lambda rng: r.uniform(rng), state)
except hmath.HMathError as error:
    assert error.math_error.message == message
else:
    raise AssertionError("pure callback error was swallowed")
with p.new_gaussian_kde(-1, [1, 2]) as raw:
    assert raw.parts == ("GaussianKDE", (-1.0, [1.0, 2.0]))
try:
    p.gaussian_kde(-1, [1, 2])
except hmath.HMathError:
    pass
else:
    raise AssertionError("checked KDE constructor stopped validating")
# Streaming state and statistical records retain Integer counts/source fields.
stream = s.empty_streaming()
for value in [1.0, 2.0, 3.0, 4.0]:
    updated = s.update_streaming(stream, value)
    stream.close()
    stream = updated
assert s.streaming_result(False, stream) == (4, 2.5, 1.25)
stream.close()
with s.TestResult(1.5, 0.25, [2.0]) as result:
    assert (
        result.test_statistic == 1.5
        and result.p_value == 0.25
        and result.degrees_of_freedom == [2.0]
    )


# A generic callback can return a newly-created callback with Python userdata.
# It stays callable after the sampler frame is gone, then releases that userdata.
class Userdata:
    pass


references = []


def callback_sample(rng):
    userdata = Userdata()
    references.append(weakref.ref(userdata))

    def operation(row, column):
        assert userdata is not None
        return float(row + column)

    return _callback(operation, ["a"], "float64"), r.clone_rng(rng)


functions, continuation = r.sample_n(1, callback_sample, state)
gc.collect()
assert references[0]() is not None
with matrix_advanced.generate_matrix(1, 2, functions[0]) as matrix:
    assert matrix.to_list() == [0.0, 1.0]
functions[0].close()
continuation.close()
del functions
gc.collect()
assert references[0]() is None
state.close()
print(
    "Stochastic all7continuations/bufferedrestore/Word64/exactelements/checked-purecallbacks/constructors/streaming contracts passed"
)
