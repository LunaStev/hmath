# SPDX-License-Identifier: MPL-2.0
"""Original Haskell first-order optimizer state and updates, in binary64."""

import ctypes as C
import threading
from enum import IntEnum

from ._numeric import _int


class GradientMethod(IntEnum):
    GRADIENT_DESCENT = 0
    MOMENTUM = 1
    NESTEROV = 2
    ADAGRAD = 3
    RMSPROP = 4
    ADADELTA = 5
    ADAM = 6
    ADAMW = 7
    AMSGRAD = 8
    ADAMAX = 9
    NADAM = 10
    RADAM = 11


def _api(name, *types):
    import hmath

    return C.CFUNCTYPE(C.c_int, *types)((name, hmath._lib))


class OptimizerState:
    """Immutable native state; close it explicitly or use a with statement.

    A live state prevents final runtime shutdown. Independent optimizer steps
    may share a state. A returned state does not modify or depend on its parent.
    """

    def __init__(self, dimension):
        import hmath

        self._lock, self._ptr = threading.RLock(), C.c_void_p()
        hmath.initialize()
        call = _api(
            "hmath_initialize_optimizer", C.c_void_p, C.c_ssize_t, C.POINTER(C.c_void_p)
        )
        hmath._check(call(None, _int(dimension), C.byref(self._ptr)))

    @classmethod
    def _adopt(cls, pointer):
        instance = object.__new__(cls)
        instance._lock, instance._ptr = threading.RLock(), pointer
        return instance

    def close(self):
        import hmath

        with self._lock:
            if self._ptr:
                C.CFUNCTYPE(None, C.c_void_p)(
                    ("hmath_optimizer_state_release", hmath._lib)
                )(self._ptr)
                self._ptr = C.c_void_p()

    def __enter__(self):
        with self._lock:
            if not self._ptr:
                raise ValueError("optimizer state is closed")
        return self

    def __exit__(self, *_):
        self.close()

    def __del__(self):
        if getattr(self, "_ptr", None):
            self.close()


def initialize_optimizer(dimension):
    """HMath.Optimization.FirstOrder.initializeOptimizer, with unchanged errors."""
    return OptimizerState(dimension)


def optimizer_step(method, rate, state, parameters, gradient):
    """Return (new_parameters, new_state) without modifying the original state.

    Calls Haskell optimizerStep directly. Its fixed beta1=.9, beta2=.999,
    epsilon=1e-8 and AdamW weight decay=.01 are preserved. This function does
    not evaluate a loss function or change the supplied gradient.
    """
    import hmath

    method = GradientMethod(method)
    if not isinstance(state, OptimizerState):
        raise TypeError("state must be an OptimizerState")
    parameters, gradient = tuple(parameters), tuple(gradient)
    xs = (C.c_double * len(parameters))(*parameters)
    gs = (C.c_double * len(gradient))(*gradient)
    result = (C.c_double * len(parameters))()
    # Allocate the Python owner before creating a native state so Python-side
    # allocation failures cannot leak a runtime reservation.
    next_state = OptimizerState._adopt(C.c_void_p())
    call = _api(
        "hmath_optimizer_step",
        C.c_void_p,
        C.c_int,
        C.c_double,
        C.c_void_p,
        C.POINTER(C.c_double),
        C.c_size_t,
        C.POINTER(C.c_double),
        C.c_size_t,
        C.POINTER(C.c_double),
        C.c_size_t,
        C.POINTER(C.c_void_p),
    )
    with state._lock:
        if not state._ptr:
            raise ValueError("optimizer state is closed")
        hmath._check(
            call(
                None,
                method,
                rate,
                state._ptr,
                xs,
                len(xs),
                gs,
                len(gs),
                result,
                len(result),
                C.byref(next_state._ptr),
            )
        )
    return list(result), next_state


# Extended original optimization API (records, methods, constraints, solvers and callbacks).
from ._optimization_all import *
