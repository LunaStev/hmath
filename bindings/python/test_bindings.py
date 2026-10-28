# SPDX-License-Identifier: MPL-2.0
import asyncio
import gc
import threading
import weakref

import hmath
import hmath_cffi
import numpy as np

for api in (hmath, hmath_cffi):
    assert api.add(2, 3) == 5
    with api.Tensor([1, 2, 3, 4], (2, 2)) as a:
        assert a.sum() == 10 and a.dot(a) == 30
        with a @ a as product:
            assert product.values() == [7, 10, 15, 22]
        with a + a as result:
            assert result.values() == [2, 4, 6, 8]
    try:
        a.sum()
        raise AssertionError("use after close accepted")
    except RuntimeError:
        pass
    try:
        api.Tensor([1], (2,))
        raise AssertionError("invalid shape accepted")
    except RuntimeError:
        pass
    with api.Tensor([3], ()) as scalar:
        assert scalar.sum() == 3
source = np.arange(12, dtype=np.float64).reshape(3, 4)
source.setflags(write=False)
with hmath.Tensor.from_numpy(source[:, ::2], copy=False) as a:
    assert a.shape == (3, 2) and a.sum() == 30
    view = a.numpy(copy=False)
    assert np.shares_memory(source, view) and not view.flags.writeable
assert np.array_equal(view, source[:, ::2])
del view
with hmath.Tensor([1, 2, 3]) as t:
    view = t.numpy(copy=False)
assert list(view) == [1, 2, 3]
del view
gc.collect()
failures = []


def worker():
    try:
        for _ in range(100):
            with hmath.Tensor([1, 2, 3]) as t:
                assert t.sum() == 6
    except (RuntimeError, AssertionError) as error:
        failures.append(error)


threads = [threading.Thread(target=worker) for _ in range(4)]
for t in threads:
    t.start()
for t in threads:
    t.join()
assert not failures, failures

# A derived base view must keep both the native ref and borrowed NumPy owner.
source = np.array([1.0, 2.0, 3.0, 4.0])
source.setflags(write=False)
source_ref = weakref.ref(source)
tensor = hmath.Tensor.from_numpy(source, copy=False)
view = tensor.numpy(copy=False)
derived = np.asarray(view.base)
tensor.close()
del tensor, source, view
gc.collect()
assert source_ref() is not None
assert list(derived) == [1, 2, 3, 4]
del derived
gc.collect()
assert source_ref() is None


async def async_calls():
    def task():
        with hmath.Tensor([1, 2, 3, 4], (2, 2)) as tensor:
            return tensor.sum()

    assert (
        await asyncio.gather(*(asyncio.to_thread(task) for _ in range(16))) == [10] * 16
    )


asyncio.run(async_calls())

print("Python ctypes/cffi/NumPy ownership, errors, shapes, threads and asyncio passed")
