# SPDX-License-Identifier: MPL-2.0
"""Compare optimization bindings with independent direct original Haskell calls."""

import argparse
import os
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PRELUDE = r"""import qualified HMath.Optimization.Common as C
import HMath.Optimization.Common (LearningRate(..))
import qualified HMath.Optimization.FirstOrder as F
import qualified HMath.Optimization.Local as L
import qualified HMath.Optimization.Constrained as K
import qualified HMath.Optimization.Global as G
import HMath.Error
import GHC.Float (castDoubleToWord64)
import Data.List (intercalate)
f x = Right (sum (map (\v -> v*v) x))
g x = Right (map (2*) x)
h x = Right [[if i==j then 2 else 0 | j<-[1..length x]] | i<-[1..length x]]
o = C.OptimizeOptions 400 40000 1e-7 0.25
short = C.OptimizeOptions 3 10000 1e-7 0.25
r = fmap (\v -> C.optPoint v ++ [C.optValue v,C.optGradientNorm v,fromIntegral(C.optIterations v),fromIntegral(C.optEvaluations v),if C.optConverged v then 1 else 0])
lp = fmap (\v -> K.lpPoint v ++ [K.lpValue v,fromIntegral(K.lpIterations v)] ++ map fromIntegral(K.lpBasis v))
s = fmap (:[])
u = fmap (const [])
stop = fmap (\v -> maybe [0,0] (\x -> [1,x]) (C.bestScore v) ++ [fromIntegral(C.staleSteps v),if C.stopped v then 1 else 0])
ls = fmap (\(a,y,x,n) -> x++[y,a,fromIntegral n])
stateStep method = do
 (x,state)<-F.stochasticGradient method 0.1 [g,g] [1,-2]
 (next,_)<-F.optimizerStep method 0.1 state x [0.3,-0.4]
 Right (x++next)
emit :: Either MathError [Double] -> IO ()
emit (Left e) = putStrLn ("E:"++show e)
emit (Right values) = putStrLn ("R:"++intercalate "," (map (show . castDoubleToWord64) values))
main = sequence_ [
"""


def cases(opt):
    """Independent language expressions: no adapter-derived expected outputs."""
    o = opt.OptimizeOptions(400, 40000, 1e-7, 0.25)
    short = opt.OptimizeOptions(3, 10000, 1e-7, 0.25)
    f = lambda x: sum(v * v for v in x)
    g = lambda x: [2 * v for v in x]
    h = lambda x: [
        [2.0 if i == j else 0.0 for j in range(len(x))] for i in range(len(x))
    ]
    result = []

    def add(name, hs, function):
        result.append((name, hs, function))

    def state_step(method):
        point, state = opt.stochastic_gradient(method, 0.1, [g, g], [1, -2])
        with state:
            next_point, next_state = opt.optimizer_step(
                method, 0.1, state, point, [0.3, -0.4]
            )
            next_state.close()
            return point + next_point

    def options():
        value = opt.default_optimize_options()
        return [
            value.max_iterations,
            value.max_evaluations,
            value.tolerance,
            value.learning_rate,
        ]

    add(
        "defaults",
        "Right [fromIntegral(C.optMaxIterations C.defaultOptimizeOptions),fromIntegral(C.optMaxEvaluations C.defaultOptimizeOptions),C.optTolerance C.defaultOptimizeOptions,C.optLearningRate C.defaultOptimizeOptions]",
        options,
    )
    schedules = [
        ("ConstantRate 0.2", opt.ConstantRate(0.2)),
        ("StepDecay 0.2 3 0.5", opt.StepDecay(0.2, 3, 0.5)),
        ("ExponentialDecay 0.2 0.9", opt.ExponentialDecay(0.2, 0.9)),
        ("CosineAnnealing 0.2 0.01 8", opt.CosineAnnealing(0.2, 0.01, 8)),
        ("Warmup 4 (ConstantRate 0.2)", opt.Warmup(4, opt.ConstantRate(0.2))),
    ]
    for hs, schedule in schedules:
        add(
            "schedule " + hs,
            "mapM (C.learningRate (" + hs + ")) [0,2,5,9]",
            lambda schedule=schedule: [
                opt.learning_rate(schedule, k) for k in [0, 2, 5, 9]
            ],
        )
    add(
        "early stop",
        "stop (C.earlyStopping 2 0.01 2 (C.EarlyStopping (Just 1) 1 False))",
        lambda: opt.early_stopping(2, 0.01, 2, opt.EarlyStopping(1, 1, False)),
    )
    add(
        "checked point", "u (C.checkedPoint [1,-2])", lambda: opt.checked_point([1, -2])
    )
    add("checked options", "u (C.checkedOptions o)", lambda: opt.checked_options(o))
    add(
        "checked value",
        "s (C.checkedValue f [2,-3])",
        lambda: opt.checked_value(f, [2, -3]),
    )
    add(
        "checked gradient",
        "C.checkedGradient g [2,-3]",
        lambda: opt.checked_gradient(g, [2, -3]),
    )
    add("budget", "u (C.checkBudget o 40000)", lambda: opt.check_budget(o, 40000))
    add(
        "dense solve",
        "C.solveDense [[2,1],[1,3]] [5,7]",
        lambda: opt.solve_dense([[2, 1], [1, 3]], [5, 7]),
    )
    add(
        "ragged multiply",
        "Right (concat (C.matMul [[1,2],[3]] [[4],[5,6]]))",
        lambda: [v for row in opt.mat_mul([[1, 2], [3]], [[4], [5, 6]]) for v in row],
    )
    add(
        "result",
        "r (C.result 3 8 False f g [2,-3])",
        lambda: opt.result(3, 8, False, f, g, [2, -3]),
    )
    for method in ["Armijo", "StrongWolfe"]:
        add(
            "line search " + method,
            "ls (C.lineSearch C." + method + " 100 f g [1] [-2] 1 [2])",
            lambda method=method: sum_line(
                opt.line_search(getattr(opt, method), 100, f, g, [1], [-2], 1, [2])
            ),
        )
    methods = [
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
    for method, enum in zip(methods, opt.GradientMethod):
        add(
            "monitor " + method,
            "r (F.minimizeGradientWithCallback (\\v -> Right (C.optIterations v < 2)) F."
            + method
            + " o f g [1,-2])",
            lambda enum=enum: opt.minimize_gradient_with_callback(
                lambda v: v.iterations < 2, enum, o, f, g, [1, -2]
            ),
        )
        add(
            "stochastic " + method,
            "stateStep F." + method,
            lambda enum=enum: state_step(enum),
        )
    add(
        "gradient",
        "r (F.minimizeGradient F.GradientDescent o f g [1,-2])",
        lambda: opt.minimize_gradient(
            opt.GradientMethod.GRADIENT_DESCENT, o, f, g, [1, -2]
        ),
    )
    add(
        "mini batch",
        "F.miniBatchGradient [g,Right . map (3*)] [1,-2]",
        lambda: invoke_close(
            opt.mini_batch_gradient([g, lambda x: [3 * v for v in x]]), [1, -2]
        ),
    )
    add(
        "projected",
        "r (F.projectedGradient o f g (Right . map (max 0)) [1,-2])",
        lambda: opt.projected_gradient(
            o, f, g, lambda x: [max(0, v) for v in x], [1, -2]
        ),
    )
    add(
        "proximal",
        "r (F.proximalGradient o f g (\\_ -> Right) [1,-2])",
        lambda: opt.proximal_gradient(o, f, g, lambda rate, x: x, [1, -2]),
    )
    add(
        "fista",
        "r (F.fista o f g (\\_ -> Right) [1,-2])",
        lambda: opt.fista(o, f, g, lambda rate, x: x, [1, -2]),
    )
    add(
        "coordinate",
        "r (F.coordinateDescent [[1],[0]] o f g [1,-2])",
        lambda: opt.coordinate_descent([[1], [0]], o, f, g, [1, -2]),
    )
    for method in ["GoldenSection", "TernarySearch", "BrentSearch"]:
        add(
            "scalar " + method,
            "r (L.minimizeScalar L." + method + " o (\\x -> Right (x*x)) (-2) 3)",
            lambda method=method: opt.minimize_scalar(
                getattr(opt, method), o, lambda x: x * x, -2, 3
            ),
        )
    for hs, method in [
        ("BFGS", opt.BFGS),
        ("LBFGS 3", opt.LBFGS(3)),
        ("DFP", opt.DFP),
        ("SR1", opt.SR1),
    ]:
        add(
            "quasi " + hs,
            "r (L.minimizeQuasiNewton (L." + hs + ") o f g [1,-2])",
            lambda method=method: opt.minimize_quasi_newton(method, o, f, g, [1, -2]),
        )
    for hs, method in [
        ("Newton", opt.Newton),
        ("NewtonCG", opt.NewtonCG),
        ("TrustRegion 0.5", opt.TrustRegion(0.5)),
        ("Dogleg 0.5", opt.Dogleg(0.5)),
    ]:
        add(
            "newton " + hs,
            "r (L.minimizeNewton (L." + hs + ") o f g h [1,-2])",
            lambda method=method: opt.minimize_newton(method, o, f, g, h, [1, -2]),
        )
    add(
        "cg",
        "r (L.nonlinearCG o f g [1,-2])",
        lambda: opt.nonlinear_cg(o, f, g, [1, -2]),
    )
    for hs, loss in [
        ("SquaredLoss", opt.SquaredLoss),
        ("HuberLoss 0.5", opt.HuberLoss(0.5)),
        ("CauchyLoss 0.5", opt.CauchyLoss(0.5)),
        ("SoftL1 0.5", opt.SoftL1(0.5)),
    ]:
        add(
            "least squares " + hs,
            "r (L.leastSquares (L."
            + hs
            + ") 0.01 o Right (\\_ -> Right [[1,0],[0,1]]) [1,-2])",
            lambda loss=loss: opt.least_squares(
                loss, 0.01, o, lambda x: x, lambda x: [[1, 0], [0, 1]], [1, -2]
            ),
        )
    add(
        "nelder mead",
        "r (L.nelderMead o f [1,-2])",
        lambda: opt.nelder_mead(o, f, [1, -2]),
    )
    add("powell", "r (L.powell 0.5 o f [1,-2])", lambda: opt.powell(0.5, o, f, [1, -2]))
    equality = opt.Equality(lambda x: x[0], lambda x: [1])
    inequality = opt.LessEqual(lambda x: x[0] - 2, lambda x: [1])
    add(
        "feasibility",
        "s (K.feasibility [K.Equality (Right . head) (const (Right [1])),K.LessEqual (\\x -> Right (head x-2)) (const (Right [1]))] [3])",
        lambda: opt.feasibility([equality, inequality], [3]),
    )
    for method in [
        "QuadraticPenalty",
        "LogBarrier",
        "InteriorPoint",
        "AugmentedLagrangian",
    ]:
        add(
            "constrained " + method,
            "r (K.constrainedMinimize K." + method + " o f g [] [1])",
            lambda method=method: opt.constrained_minimize(
                getattr(opt, method), o, f, g, [], [1]
            ),
        )
    add(
        "lp",
        "lp (K.linearProgramming 100 1e-9 [-1] [[1]] [2])",
        lambda: opt.linear_programming(100, 1e-9, [-1], [[1]], [2]),
    )
    add(
        "revised simplex",
        "lp (K.revisedSimplex 100 1e-9 [-1,0] [[1,1]] [2] [1])",
        lambda: opt.revised_simplex(100, 1e-9, [-1, 0], [[1, 1]], [2], [1]),
    )
    add(
        "qp",
        "r (K.quadraticProgramming 100 1e-9 [[2]] [-4] [[1]] [1])",
        lambda: opt.quadratic_programming(100, 1e-9, [[2]], [-4], [[1]], [1]),
    )
    add("slsqp", "r (K.slsqp o f g h [] [1])", lambda: opt.slsqp(o, f, g, h, [], [1]))
    add("cobyla", "r (K.cobyla 0.5 o f [] [1])", lambda: opt.cobyla(0.5, o, f, [], [1]))
    add(
        "weighted objective",
        "s (K.weightedObjective [0.25,0.75] [f,Right . sum] [1,2])",
        lambda: invoke_close(opt.weighted_objective([0.25, 0.75], [f, sum]), [1, 2]),
    )
    add(
        "pareto",
        "fmap (map fromIntegral) (K.paretoFront [[1,2],[2,1],[3,3],[1,2]])",
        lambda: opt.pareto_front([[1, 2], [2, 1], [3, 3], [1, 2]]),
    )
    for method in [
        "SimulatedAnnealing",
        "DifferentialEvolution",
        "GeneticAlgorithm",
        "ParticleSwarm",
        "CMAES",
    ]:
        add(
            "global " + method,
            "r (G.globalMinimize G."
            + method
            + " 4 18446744073709551615 short [(-2,2),(-3,3)] f)",
            lambda method=method: opt.global_minimize(
                getattr(opt, method), 4, 2**64 - 1, short, [(-2, 2), (-3, 3)], f
            ),
        )
    add(
        "basin hopping",
        "r (G.basinHopping 91 1 2 o [(-2,2)] f [1])",
        lambda: opt.basin_hopping(91, 1, 2, o, [(-2, 2)], f, [1]),
    )
    invalid = [
        (
            "bad options",
            "u (C.checkedOptions (o{C.optMaxIterations=0}))",
            lambda: opt.checked_options(opt.OptimizeOptions(0, 100, 1e-7, 0.25)),
        ),
        (
            "budget error",
            "u (C.checkBudget o 40001)",
            lambda: opt.check_budget(o, 40001),
        ),
        (
            "bad gradient",
            "C.checkedGradient (const (Right [])) [1]",
            lambda: opt.checked_gradient(lambda x: [], [1]),
        ),
        (
            "bad point",
            "u (C.checkedPoint [0/0])",
            lambda: opt.checked_point([float("nan")]),
        ),
        (
            "invalid LBFGS",
            "r (L.minimizeQuasiNewton (L.LBFGS 0) o f g [1])",
            lambda: opt.minimize_quasi_newton(opt.LBFGS(0), o, f, g, [1]),
        ),
        (
            "empty batch",
            "F.miniBatchGradient [] [1]",
            lambda: invoke_close(opt.mini_batch_gradient([]), [1]),
        ),
        (
            "unbounded LP",
            "lp (K.linearProgramming 100 1e-9 [-1] [[-1]] [0])",
            lambda: opt.linear_programming(100, 1e-9, [-1], [[-1]], [0]),
        ),
    ]
    for name, hs, fn in invalid:
        add(name, hs, fn)
    return result


def invoke_close(function, *args):
    with function:
        return function(*args)


def sum_line(value):
    rate, y, point, count = value
    return point + [y, rate, count]


def flatten(value):
    from _hmath_native import optimization as opt

    if value is None:
        return []
    if isinstance(value, opt.OptimizeResult):
        return value.point + [
            value.value,
            value.gradient_norm,
            value.iterations,
            value.evaluations,
            value.converged,
        ]
    if isinstance(value, opt.LPResult):
        return value.point + [value.value, value.iterations] + value.basis
    if isinstance(value, opt.EarlyStopping):
        return ([0, 0] if value.best_score is None else [1, value.best_score]) + [
            value.stale_steps,
            value.stopped,
        ]
    if isinstance(value, (list, tuple)):
        return list(value)
    return [value]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", required=True, type=Path)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(args.library.resolve())
    os.environ["HMATH_BACKEND"] = "pure"
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    from _hmath_native import optimization as opt

    selected = cases(opt)
    with tempfile.TemporaryDirectory(prefix="hmath-opt-oracle-") as temporary:
        path = Path(temporary)
        source = path / "Main.hs"
        source.write_text(
            PRELUDE + ",\n".join(" emit (" + hs + ")" for _, hs, _ in selected) + "]\n"
        )
        subprocess.run(
            [
                "ghc",
                "-XHaskell2010",
                "-O1",
                "-i" + str(ROOT / "src"),
                "-I" + str(ROOT / "include"),
                "-outputdir",
                temporary,
                str(source),
                str(ROOT / "cbits/backend.c"),
                "-ldl",
                "-o",
                str(path / "oracle"),
            ],
            check=True,
            stdout=subprocess.DEVNULL,
        )
        expected = subprocess.check_output(
            [str(path / "oracle")], text=True
        ).splitlines()
    for (name, _, call), reference in zip(selected, expected, strict=True):
        try:
            output = flatten(call())
            bits = [
                str(struct.unpack("=Q", struct.pack("=d", float(v)))[0]) for v in output
            ]
            actual = "R:" + ",".join(bits)
        except hmath.HMathError as error:
            if error.math_error is None:
                raise
            actual = "E:" + str(error.math_error)
        if actual != reference:
            raise AssertionError(f"{name}: binding {actual}, original {reference}")
    print(
        f"Optimization equivalence: {len(selected)} independent original Haskell operation sequences match (binary64 bits, complete diagnostics and errors)."
    )


if __name__ == "__main__":
    main()
