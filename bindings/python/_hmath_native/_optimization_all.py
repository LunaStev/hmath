# SPDX-License-Identifier: MPL-2.0
"""Original Haskell optimization functions with records and checked callbacks."""

import ctypes as C
import threading
import weakref
from dataclasses import dataclass
from typing import Callable as _Callable

from . import _value as v
from ._math_error import Wire, fill
from ._numeric import _int

P, Z = C.c_void_p, C.c_size_t
# This file's catalog is generated into a Python module for wheel installations.
from ._optimization_catalog import CATALOG

_SPEC = {entry["name"]: entry for entry in CATALOG}
_pending = threading.local()

# Source type aliases use Python return values; raise hmath.errors.MathError
# to supply the original Either's Left branch from a checked callback.
Objective = _Callable[[list[float]], float]
Gradient = _Callable[[list[float]], list[float]]
Hessian = _Callable[[list[float]], list[list[float]]]
ResidualFunction = Gradient
JacobianFunction = Hessian


@dataclass(frozen=True)
class OptimizeOptions:
    max_iterations: int = 1000
    max_evaluations: int = 20000
    tolerance: float = 1e-8
    learning_rate: float = 0.01


@dataclass(frozen=True)
class OptimizeResult:
    point: list
    value: float
    gradient_norm: float
    iterations: int
    evaluations: int
    converged: bool


@dataclass(frozen=True)
class LPResult:
    point: list
    value: float
    basis: list
    iterations: int


@dataclass(frozen=True)
class EarlyStopping:
    best_score: object = None
    stale_steps: int = 0
    stopped: bool = False


@dataclass(frozen=True)
class _Constructor:
    name: str
    arguments: tuple = ()


class LearningRate(_Constructor):
    pass


class ScalarMethod(_Constructor):
    pass


class QuasiNewton(_Constructor):
    pass


class NewtonMethod(_Constructor):
    pass


class LeastSquaresLoss(_Constructor):
    pass


class Constraint(_Constructor):
    pass


class PenaltyMethod(_Constructor):
    pass


class GlobalMethod(_Constructor):
    pass


class LineSearch(_Constructor):
    pass


class _CallbackOwner:
    def __init__(self, function, role, scalar_input=False):
        self.function, self.role, self.scalar_input = function, role, scalar_input
        self.buffers = {}
        self.callback = None


_CALLBACK = C.CFUNCTYPE(C.c_int, P, P, C.POINTER(P), C.POINTER(Wire))


def _callback(function, role, scalar_input=False):
    if isinstance(function, v.Value):
        return function.clone()
    if not callable(function):
        raise TypeError("optimization callback must be callable")
    owner = _CallbackOwner(function, role, scalar_input)
    reference = weakref.proxy(owner)

    @_CALLBACK
    def bridge(argument, userdata, out, error):
        buffers = []
        reference.buffers[threading.get_ident()] = buffers
        try:
            value = v.decode(v.borrow(argument))
            if reference.scalar_input:
                value = value[0]
            result = (
                reference.function(*value)
                if reference.role == 3
                else reference.function(value)
            )
            encoded = _typed(
                result, ("Double", "Vector", "Matrix", "Vector", "Bool")[reference.role]
            )
            try:
                with encoded._lock:
                    v.api("hmath_value_retain", None, P)(encoded._ptr)
                    out[0] = encoded._ptr
            finally:
                encoded.close()
            return 0
        except BaseException as exception:  # noqa: BLE001 - contain all exceptions at the C boundary
            try:
                if fill(error, exception, buffers):
                    return 11
                _pending.exception = exception
                message = str(exception).encode("utf-8", "surrogatepass")
                buffer = C.create_string_buffer(message)
                buffers.append(buffer)
                error.contents.kind = 0
                error.contents.message = C.cast(buffer, P)
                error.contents.message_length = len(message)
                status = getattr(exception, "status", 6)
                return status if isinstance(status, int) and status != 11 else 6
            except BaseException:  # noqa: BLE001 - contain failures in exception transport
                # Even an exception's __str__ or error-buffer allocation may
                # fail. Preserve the original exception and return a status.
                _pending.exception = exception
                return 6

    owner.callback = bridge
    result = v.Value._adopt(owners=[owner])
    import hmath

    hmath.initialize()
    hmath._check(
        v.api(
            "hmath_optimization_callback",
            C.c_int,
            P,
            C.c_int,
            _CALLBACK,
            P,
            C.POINTER(P),
        )(None, role, bridge, None, C.byref(result._ptr))
    )
    return result


def _sequence(values, hint, tuple_=False):
    encoded = []
    try:
        for value in values:
            encoded.append(_typed(value, hint))
        return v.encode(tuple(encoded) if tuple_ else encoded)
    finally:
        for value in encoded:
            value.close()


def _legacy_state(value):
    from .optimization import OptimizerState

    if not isinstance(value, OptimizerState):
        raise TypeError("expected OptimizerState")
    result = v.Value._adopt()
    import hmath

    with value._lock:
        if not value._ptr:
            raise ValueError("optimizer state is closed")
        hmath._check(
            v.api("hmath_optimization_state_import", C.c_int, P, P, C.POINTER(P))(
                None, value._ptr, C.byref(result._ptr)
            )
        )
    return result


def _typed(value, hint):
    if isinstance(value, v.Value):
        return value.clone()
    if isinstance(value, _Constructor):
        return _raw(value.name, *value.arguments)
    if hint == "Double":
        return v.scalar(value, "float64")
    if hint == "Int":
        return v._create("hmath_value_index", [C.c_ssize_t], [_int(value)])
    if hint == "Bool":
        if not isinstance(value, bool):
            raise TypeError("expected Bool")
        return v.encode(value)
    if hint == "Word64":
        return v.scalar(value, "uint64")
    if hint == "Vector":
        return _sequence(value, "Double")
    if hint == "Matrix":
        return _sequence(value, "Vector")
    if hint == "Indices":
        return _sequence(value, "Int")
    if hint == "Blocks":
        return _sequence(value, "Indices")
    if hint == "GenericMatrix":
        return v.encode([list(row) for row in value])
    if hint == "Bounds":
        rows = []
        try:
            for pair in value:
                pair = tuple(pair)
                if len(pair) != 2:
                    raise ValueError("bounds require lower/upper pairs")
                rows.append(_sequence(pair, "Double", True))
            return v.encode(rows)
        finally:
            for row in rows:
                row.close()
    if hint == "MaybeDouble":
        return v.encode(None) if value is None else v.scalar(value, "float64")
    if hint in (
        "Objective",
        "Gradient",
        "Hessian",
        "Prox",
        "Monitor",
        "ScalarObjective",
    ):
        return _callback(
            value,
            {
                "Objective": 0,
                "ScalarObjective": 0,
                "Gradient": 1,
                "Hessian": 2,
                "Prox": 3,
                "Monitor": 4,
            }[hint],
            hint == "ScalarObjective",
        )
    if hint in ("Gradients", "Objectives", "Constraints"):
        return _sequence(
            value,
            {
                "Gradients": "Gradient",
                "Objectives": "Objective",
                "Constraints": "Constraint",
            }[hint],
        )
    if hint == "State":
        return _legacy_state(value)
    if hint == "GradientMethod":
        from .optimization import GradientMethod

        method = GradientMethod(value)
        names = [
            "GradientDescent",
            "Momentum",
            "Nesterov",
            "AdaGrad",
            "RMSProp",
            "AdaDelta",
            "Adam",
            "AdamW",
            "AMSGrad",
            "AdaMax",
            "Nadam",
            "RAdam",
        ]
        return _raw(names[int(method)])
    if isinstance(value, OptimizeOptions):
        return _raw(
            "OptimizeOptions",
            value.max_iterations,
            value.max_evaluations,
            value.tolerance,
            value.learning_rate,
        )
    if isinstance(value, OptimizeResult):
        return _raw(
            "OptimizeResult",
            value.point,
            value.value,
            value.gradient_norm,
            value.iterations,
            value.evaluations,
            value.converged,
        )
    if isinstance(value, LPResult):
        return _raw("LPResult", value.point, value.value, value.basis, value.iterations)
    if isinstance(value, EarlyStopping):
        return _raw("EarlyStopping", value.best_score, value.stale_steps, value.stopped)
    return v.encode(value)


def _raw(name, *arguments):
    spec = _SPEC[name]
    if len(arguments) != len(spec["arguments"]):
        raise TypeError(f"{name} requires {len(spec['arguments'])} arguments")
    values = []
    try:
        for value, hint in zip(arguments, spec["arguments"]):
            values.append(_typed(value, hint))
        return v.invoke(spec["c"], *values)
    except BaseException:  # cleanups then rethrow original Python callback exception
        if getattr(_pending, "exception", None) is not None:
            error = _pending.exception
            del _pending.exception
            raise error
        raise
    finally:
        for value in values:
            value.close()


def _invoke(name, *arguments):
    return v.decode(_raw(name, *arguments))


class _Function(v.Value):
    def __call__(self, *arguments):
        # A callback may close this function reentrantly. Hold an independent
        # native reference and callback-owner snapshot for the entire call.
        pinned = self.clone()
        role = pinned.info[2]
        hints = [["Vector"], ["Vector"], ["Vector"], ["Double", "Vector"], ["Result"]][
            role
        ]
        if len(arguments) != len(hints):
            pinned.close()
            raise TypeError("function argument count differs")
        values = []
        result = v.Value._adopt(owners=pinned._owners)
        import hmath

        try:
            for value, hint in zip(arguments, hints):
                values.append(_typed(value, hint))
            pointers = (P * len(values))(*(value._ptr for value in values))
            with pinned._lock:
                hmath._check(
                    v.api(
                        "hmath_optimization_function_apply",
                        C.c_int,
                        P,
                        P,
                        C.POINTER(P),
                        Z,
                        C.POINTER(P),
                    )(None, pinned._ptr, pointers, len(values), C.byref(result._ptr))
                )
            return v.decode(result)
        except BaseException:
            if getattr(_pending, "exception", None) is not None:
                error = _pending.exception
                del _pending.exception
                raise error
            raise
        finally:
            for value in values:
                value.close()
            result.close()
            pinned.close()


def _fields(value, names):
    try:
        return [_invoke(name, value) for name in names]
    finally:
        value.close()


def _decode_state(value):
    from .optimization import OptimizerState

    result = OptimizerState._adopt(P())
    import hmath

    try:
        with value._lock:
            hmath._check(
                v.api("hmath_optimization_state_export", C.c_int, P, P, C.POINTER(P))(
                    None, value._ptr, C.byref(result._ptr)
                )
            )
        return result
    finally:
        value.close()


v.register(
    20,
    lambda value: OptimizeOptions(
        *_fields(
            value,
            [
                "optMaxIterations",
                "optMaxEvaluations",
                "optTolerance",
                "optLearningRate",
            ],
        )
    ),
)
v.register(
    21,
    lambda value: OptimizeResult(
        *_fields(
            value,
            [
                "optPoint",
                "optValue",
                "optGradientNorm",
                "optIterations",
                "optEvaluations",
                "optConverged",
            ],
        )
    ),
)
v.register(
    22,
    lambda value: LPResult(
        *_fields(value, ["lpPoint", "lpValue", "lpBasis", "lpIterations"])
    ),
)
v.register(
    24,
    lambda value: EarlyStopping(
        *_fields(value, ["bestScore", "staleSteps", "stopped"])
    ),
)
v.register(34, _decode_state)
v.register(35, _Function)


def ConstantRate(rate):
    return LearningRate("ConstantRate", (rate,))


LearningRate.CONSTANT_RATE = staticmethod(ConstantRate)


def StepDecay(initial_rate, period, decay):
    return LearningRate("StepDecay", (initial_rate, period, decay))


LearningRate.STEP_DECAY = staticmethod(StepDecay)


def ExponentialDecay(initial_rate, decay):
    return LearningRate("ExponentialDecay", (initial_rate, decay))


LearningRate.EXPONENTIAL_DECAY = staticmethod(ExponentialDecay)


def CosineAnnealing(maximum, minimum, period):
    return LearningRate("CosineAnnealing", (maximum, minimum, period))


LearningRate.COSINE_ANNEALING = staticmethod(CosineAnnealing)


def Warmup(steps, base):
    return LearningRate("Warmup", (steps, base))


LearningRate.WARMUP = staticmethod(Warmup)

GoldenSection = ScalarMethod("GoldenSection")
ScalarMethod.GOLDEN_SECTION = GoldenSection

TernarySearch = ScalarMethod("TernarySearch")
ScalarMethod.TERNARY_SEARCH = TernarySearch

BrentSearch = ScalarMethod("BrentSearch")
ScalarMethod.BRENT_SEARCH = BrentSearch

BFGS = QuasiNewton("BFGS")
QuasiNewton.BFGS = BFGS


def LBFGS(memory):
    return QuasiNewton("LBFGS", (memory,))


QuasiNewton.LBFGS = staticmethod(LBFGS)

DFP = QuasiNewton("DFP")
QuasiNewton.DFP = DFP

SR1 = QuasiNewton("SR1")
QuasiNewton.SR1 = SR1

Newton = NewtonMethod("Newton")
NewtonMethod.NEWTON = Newton

NewtonCG = NewtonMethod("NewtonCG")
NewtonMethod.NEWTON_CG = NewtonCG


def TrustRegion(radius):
    return NewtonMethod("TrustRegion", (radius,))


NewtonMethod.TRUST_REGION = staticmethod(TrustRegion)


def Dogleg(radius):
    return NewtonMethod("Dogleg", (radius,))


NewtonMethod.DOGLEG = staticmethod(Dogleg)

SquaredLoss = LeastSquaresLoss("SquaredLoss")
LeastSquaresLoss.SQUARED_LOSS = SquaredLoss


def HuberLoss(scale):
    return LeastSquaresLoss("HuberLoss", (scale,))


LeastSquaresLoss.HUBER_LOSS = staticmethod(HuberLoss)


def CauchyLoss(scale):
    return LeastSquaresLoss("CauchyLoss", (scale,))


LeastSquaresLoss.CAUCHY_LOSS = staticmethod(CauchyLoss)


def SoftL1(scale):
    return LeastSquaresLoss("SoftL1", (scale,))


LeastSquaresLoss.SOFT_L1 = staticmethod(SoftL1)


def Equality(objective, gradient):
    return Constraint("Equality", (objective, gradient))


Constraint.EQUALITY = staticmethod(Equality)


def LessEqual(objective, gradient):
    return Constraint("LessEqual", (objective, gradient))


Constraint.LESS_EQUAL = staticmethod(LessEqual)

QuadraticPenalty = PenaltyMethod("QuadraticPenalty")
PenaltyMethod.QUADRATIC_PENALTY = QuadraticPenalty

LogBarrier = PenaltyMethod("LogBarrier")
PenaltyMethod.LOG_BARRIER = LogBarrier

InteriorPoint = PenaltyMethod("InteriorPoint")
PenaltyMethod.INTERIOR_POINT = InteriorPoint

AugmentedLagrangian = PenaltyMethod("AugmentedLagrangian")
PenaltyMethod.AUGMENTED_LAGRANGIAN = AugmentedLagrangian

SimulatedAnnealing = GlobalMethod("SimulatedAnnealing")
GlobalMethod.SIMULATED_ANNEALING = SimulatedAnnealing

DifferentialEvolution = GlobalMethod("DifferentialEvolution")
GlobalMethod.DIFFERENTIAL_EVOLUTION = DifferentialEvolution

GeneticAlgorithm = GlobalMethod("GeneticAlgorithm")
GlobalMethod.GENETIC_ALGORITHM = GeneticAlgorithm

ParticleSwarm = GlobalMethod("ParticleSwarm")
GlobalMethod.PARTICLE_SWARM = ParticleSwarm

CMAES = GlobalMethod("CMAES")
GlobalMethod.CMAES = CMAES

Armijo = LineSearch("Armijo")
LineSearch.ARMIJO = Armijo

StrongWolfe = LineSearch("StrongWolfe")
LineSearch.STRONG_WOLFE = StrongWolfe


def default_optimize_options():
    """Call HMath.Optimization.Common.defaultOptimizeOptions with original contracts."""
    return _invoke("defaultOptimizeOptions")


def checked_options(options):
    """Call HMath.Optimization.Common.checkedOptions with original contracts."""
    return _invoke("checkedOptions", options)


def checked_point(point):
    """Call HMath.Optimization.Common.checkedPoint with original contracts."""
    return _invoke("checkedPoint", point)


def checked_value(objective, point):
    """Call HMath.Optimization.Common.checkedValue with original contracts."""
    return _invoke("checkedValue", objective, point)


def checked_gradient(gradient, point):
    """Call HMath.Optimization.Common.checkedGradient with original contracts."""
    return _invoke("checkedGradient", gradient, point)


def check_budget(options, evaluations):
    """Call HMath.Optimization.Common.checkBudget with original contracts."""
    return _invoke("checkBudget", options, evaluations)


def dot(left, right):
    """Call HMath.Optimization.Common.dot with original contracts."""
    return _invoke("dot", left, right)


def add(left, right):
    """Call HMath.Optimization.Common.add with original contracts."""
    return _invoke("add", left, right)


def sub(left, right):
    """Call HMath.Optimization.Common.sub with original contracts."""
    return _invoke("sub", left, right)


def outer(left, right):
    """Call HMath.Optimization.Common.outer with original contracts."""
    return _invoke("outer", left, right)


def norm(values):
    """Call HMath.Optimization.Common.norm with original contracts."""
    return _invoke("norm", values)


def scale(factor, values):
    """Call HMath.Optimization.Common.scale with original contracts."""
    return _invoke("scale", factor, values)


def identity(dimension):
    """Call HMath.Optimization.Common.identity with original contracts."""
    return _invoke("identity", dimension)


def mat_vec(matrix, vector):
    """Call HMath.Optimization.Common.matVec with original contracts."""
    return _invoke("matVec", matrix, vector)


def mat_mul(left, right):
    """Call HMath.Optimization.Common.matMul with original contracts."""
    return _invoke("matMul", left, right)


def transpose(rows):
    """Call HMath.Optimization.Common.transpose with original contracts."""
    return _invoke("transpose", rows)


def solve_dense(matrix, rhs):
    """Call HMath.Optimization.Common.solveDense with original contracts."""
    return _invoke("solveDense", matrix, rhs)


def result(iterations, evaluations, converged, objective, gradient, point):
    """Call HMath.Optimization.Common.result with original contracts."""
    return _invoke(
        "result", iterations, evaluations, converged, objective, gradient, point
    )


def learning_rate(schedule, step):
    """Call HMath.Optimization.Common.learningRate with original contracts."""
    return _invoke("learningRate", schedule, step)


def early_stopping(patience, min_delta, value, state):
    """Call HMath.Optimization.Common.earlyStopping with original contracts."""
    return _invoke("earlyStopping", patience, min_delta, value, state)


def line_search(
    method, budget, objective, gradient, point, direction, value, point_gradient
):
    """Call HMath.Optimization.Common.lineSearch with original contracts."""
    return _invoke(
        "lineSearch",
        method,
        budget,
        objective,
        gradient,
        point,
        direction,
        value,
        point_gradient,
    )


def opt_max_iterations(value):
    """Call HMath.Optimization.Common.optMaxIterations with original contracts."""
    return _invoke("optMaxIterations", value)


def opt_max_evaluations(value):
    """Call HMath.Optimization.Common.optMaxEvaluations with original contracts."""
    return _invoke("optMaxEvaluations", value)


def opt_tolerance(value):
    """Call HMath.Optimization.Common.optTolerance with original contracts."""
    return _invoke("optTolerance", value)


def opt_learning_rate(value):
    """Call HMath.Optimization.Common.optLearningRate with original contracts."""
    return _invoke("optLearningRate", value)


def opt_point(value):
    """Call HMath.Optimization.Common.optPoint with original contracts."""
    return _invoke("optPoint", value)


def opt_value(value):
    """Call HMath.Optimization.Common.optValue with original contracts."""
    return _invoke("optValue", value)


def opt_gradient_norm(value):
    """Call HMath.Optimization.Common.optGradientNorm with original contracts."""
    return _invoke("optGradientNorm", value)


def opt_iterations(value):
    """Call HMath.Optimization.Common.optIterations with original contracts."""
    return _invoke("optIterations", value)


def opt_evaluations(value):
    """Call HMath.Optimization.Common.optEvaluations with original contracts."""
    return _invoke("optEvaluations", value)


def opt_converged(value):
    """Call HMath.Optimization.Common.optConverged with original contracts."""
    return _invoke("optConverged", value)


def best_score(value):
    """Call HMath.Optimization.Common.bestScore with original contracts."""
    return _invoke("bestScore", value)


def stale_steps(value):
    """Call HMath.Optimization.Common.staleSteps with original contracts."""
    return _invoke("staleSteps", value)


def stopped(value):
    """Call HMath.Optimization.Common.stopped with original contracts."""
    return _invoke("stopped", value)


def minimize_gradient(method, options, objective, gradient, initial):
    """Call HMath.Optimization.FirstOrder.minimizeGradient with original contracts."""
    return _invoke("minimizeGradient", method, options, objective, gradient, initial)


def minimize_gradient_with_callback(
    monitor, method, options, objective, gradient, initial
):
    """Call HMath.Optimization.FirstOrder.minimizeGradientWithCallback with original contracts."""
    return _invoke(
        "minimizeGradientWithCallback",
        monitor,
        method,
        options,
        objective,
        gradient,
        initial,
    )


def stochastic_gradient(method, rate, gradients, initial):
    """Call HMath.Optimization.FirstOrder.stochasticGradient with original contracts."""
    return _invoke("stochasticGradient", method, rate, gradients, initial)


def mini_batch_gradient(gradients):
    """Call HMath.Optimization.FirstOrder.miniBatchGradient with original contracts."""
    return _invoke("miniBatchGradient", gradients)


def projected_gradient(options, objective, gradient, project, initial):
    """Call HMath.Optimization.FirstOrder.projectedGradient with original contracts."""
    return _invoke("projectedGradient", options, objective, gradient, project, initial)


def proximal_gradient(options, objective, gradient, prox, initial):
    """Call HMath.Optimization.FirstOrder.proximalGradient with original contracts."""
    return _invoke("proximalGradient", options, objective, gradient, prox, initial)


def fista(options, objective, gradient, prox, initial):
    """Call HMath.Optimization.FirstOrder.fista with original contracts."""
    return _invoke("fista", options, objective, gradient, prox, initial)


def coordinate_descent(blocks, options, objective, gradient, initial):
    """Call HMath.Optimization.FirstOrder.coordinateDescent with original contracts."""
    return _invoke("coordinateDescent", blocks, options, objective, gradient, initial)


def minimize_scalar(method, options, objective, lower, upper):
    """Call HMath.Optimization.Local.minimizeScalar with original contracts."""
    return _invoke("minimizeScalar", method, options, objective, lower, upper)


def minimize_quasi_newton(method, options, objective, gradient, initial):
    """Call HMath.Optimization.Local.minimizeQuasiNewton with original contracts."""
    return _invoke("minimizeQuasiNewton", method, options, objective, gradient, initial)


def minimize_newton(method, options, objective, gradient, hessian, initial):
    """Call HMath.Optimization.Local.minimizeNewton with original contracts."""
    return _invoke(
        "minimizeNewton", method, options, objective, gradient, hessian, initial
    )


def nonlinear_cg(options, objective, gradient, initial):
    """Call HMath.Optimization.Local.nonlinearCG with original contracts."""
    return _invoke("nonlinearCG", options, objective, gradient, initial)


def least_squares(loss, damping, options, residual, jacobian, initial):
    """Call HMath.Optimization.Local.leastSquares with original contracts."""
    return _invoke("leastSquares", loss, damping, options, residual, jacobian, initial)


def nelder_mead(options, objective, initial):
    """Call HMath.Optimization.Local.nelderMead with original contracts."""
    return _invoke("nelderMead", options, objective, initial)


def powell(initial_step, options, objective, initial):
    """Call HMath.Optimization.Local.powell with original contracts."""
    return _invoke("powell", initial_step, options, objective, initial)


def feasibility(constraints, point):
    """Call HMath.Optimization.Constrained.feasibility with original contracts."""
    return _invoke("feasibility", constraints, point)


def constrained_minimize(method, options, objective, gradient, constraints, initial):
    """Call HMath.Optimization.Constrained.constrainedMinimize with original contracts."""
    return _invoke(
        "constrainedMinimize",
        method,
        options,
        objective,
        gradient,
        constraints,
        initial,
    )


def linear_programming(budget, tolerance, cost, matrix, rhs):
    """Call HMath.Optimization.Constrained.linearProgramming with original contracts."""
    return _invoke("linearProgramming", budget, tolerance, cost, matrix, rhs)


def revised_simplex(budget, tolerance, cost, matrix, rhs, basis):
    """Call HMath.Optimization.Constrained.revisedSimplex with original contracts."""
    return _invoke("revisedSimplex", budget, tolerance, cost, matrix, rhs, basis)


def quadratic_programming(budget, tolerance, hessian, cost, matrix, rhs):
    """Call HMath.Optimization.Constrained.quadraticProgramming with original contracts."""
    return _invoke(
        "quadraticProgramming", budget, tolerance, hessian, cost, matrix, rhs
    )


def slsqp(options, objective, gradient, hessian, constraints, initial):
    """Call HMath.Optimization.Constrained.slsqp with original contracts."""
    return _invoke("slsqp", options, objective, gradient, hessian, constraints, initial)


def cobyla(initial_radius, options, objective, constraints, initial):
    """Call HMath.Optimization.Constrained.cobyla with original contracts."""
    return _invoke("cobyla", initial_radius, options, objective, constraints, initial)


def weighted_objective(weights, objectives):
    """Call HMath.Optimization.Constrained.weightedObjective with original contracts."""
    return _invoke("weightedObjective", weights, objectives)


def pareto_front(points):
    """Call HMath.Optimization.Constrained.paretoFront with original contracts."""
    return _invoke("paretoFront", points)


def lp_point(value):
    """Call HMath.Optimization.Constrained.lpPoint with original contracts."""
    return _invoke("lpPoint", value)


def lp_value(value):
    """Call HMath.Optimization.Constrained.lpValue with original contracts."""
    return _invoke("lpValue", value)


def lp_basis(value):
    """Call HMath.Optimization.Constrained.lpBasis with original contracts."""
    return _invoke("lpBasis", value)


def lp_iterations(value):
    """Call HMath.Optimization.Constrained.lpIterations with original contracts."""
    return _invoke("lpIterations", value)


def global_minimize(method, population_size, seed, options, bounds, objective):
    """Call HMath.Optimization.Global.globalMinimize with original contracts."""
    return _invoke(
        "globalMinimize", method, population_size, seed, options, bounds, objective
    )


def basin_hopping(seed, temperature, hops, options, bounds, objective, initial):
    """Call HMath.Optimization.Global.basinHopping with original contracts."""
    return _invoke(
        "basinHopping", seed, temperature, hops, options, bounds, objective, initial
    )


__all__ = [
    "BFGS",
    "CMAES",
    "DFP",
    "LBFGS",
    "SR1",
    "Armijo",
    "AugmentedLagrangian",
    "BrentSearch",
    "CauchyLoss",
    "ConstantRate",
    "Constraint",
    "CosineAnnealing",
    "DifferentialEvolution",
    "Dogleg",
    "EarlyStopping",
    "Equality",
    "ExponentialDecay",
    "GeneticAlgorithm",
    "GlobalMethod",
    "GoldenSection",
    "Gradient",
    "Hessian",
    "HuberLoss",
    "InteriorPoint",
    "JacobianFunction",
    "LPResult",
    "LearningRate",
    "LeastSquaresLoss",
    "LessEqual",
    "LineSearch",
    "LogBarrier",
    "Newton",
    "NewtonCG",
    "NewtonMethod",
    "Objective",
    "OptimizeOptions",
    "OptimizeResult",
    "ParticleSwarm",
    "PenaltyMethod",
    "QuadraticPenalty",
    "QuasiNewton",
    "ResidualFunction",
    "ScalarMethod",
    "SimulatedAnnealing",
    "SoftL1",
    "SquaredLoss",
    "StepDecay",
    "StrongWolfe",
    "TernarySearch",
    "TrustRegion",
    "Warmup",
    "add",
    "basin_hopping",
    "best_score",
    "check_budget",
    "checked_gradient",
    "checked_options",
    "checked_point",
    "checked_value",
    "cobyla",
    "constrained_minimize",
    "coordinate_descent",
    "default_optimize_options",
    "dot",
    "early_stopping",
    "feasibility",
    "fista",
    "global_minimize",
    "identity",
    "learning_rate",
    "least_squares",
    "line_search",
    "linear_programming",
    "lp_basis",
    "lp_iterations",
    "lp_point",
    "lp_value",
    "mat_mul",
    "mat_vec",
    "mini_batch_gradient",
    "minimize_gradient",
    "minimize_gradient_with_callback",
    "minimize_newton",
    "minimize_quasi_newton",
    "minimize_scalar",
    "nelder_mead",
    "nonlinear_cg",
    "norm",
    "opt_converged",
    "opt_evaluations",
    "opt_gradient_norm",
    "opt_iterations",
    "opt_learning_rate",
    "opt_max_evaluations",
    "opt_max_iterations",
    "opt_point",
    "opt_tolerance",
    "opt_value",
    "outer",
    "pareto_front",
    "powell",
    "projected_gradient",
    "proximal_gradient",
    "quadratic_programming",
    "result",
    "revised_simplex",
    "scale",
    "slsqp",
    "solve_dense",
    "stale_steps",
    "stochastic_gradient",
    "stopped",
    "sub",
    "transpose",
    "weighted_objective",
]
