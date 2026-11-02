# SPDX-License-Identifier: MPL-2.0
"""Compare native AD bindings with independent direct calls to HMath.Autodiff."""

import argparse
import os
import struct
import subprocess
import sys
import tempfile
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = r"""import qualified HMath.Autodiff as A
import Data.Complex
import Data.List (intercalate)
import GHC.Float (castDoubleToWord64,float2Double)
import Data.Ratio (numerator,denominator,(%))
checked = either (error . show) id
objective [x,y] = x*x+x*y
objective _ = error "arity"
vector [x,y] = [x*y,x+y]
vector _ = error "arity"
emit = putStrLn . intercalate "," . map (show . castDoubleToWord64)
main = do
 let (value,g) = checked (A.valueAndGradient objective [3,4])
 emit (value:g)
 emit (checked (A.gradient objective [3,4]))
 emit (concat (checked (A.hessian objective [3,4])))
 emit (concat (checked (A.jacobian vector [2,3])))
 emit (checked (A.jvp vector [2,3] [1,2]))
 emit (checked (A.vjp vector [2,3] [1,2]))
 emit (checked (A.hvp objective [3,4] [2,-1]))
 emit [checked (A.gradientCheck 1e-5 objective [3,4])]
 let z = checked (A.complexGradient (\[x,y] -> x*x+y*y) (3:+4))
 emit [realPart z,imagPart z]
 let (p,t) = A.forward (\x -> x*x*x) (3::Double)
 emit [p,t]
 let (ps,ts) = checked (A.forwardJVP (\[x,y] -> [x*y]) [2,3] [1,2])
 emit (ps++ts)
 let state=checked (A.zeroGradients 2)
 let accumulated=checked (A.accumulateGradients state [3,4])
 emit (A.accumulatedGradient accumulated)
 emit (A.accumulatedGradient (A.resetGradients accumulated))
 emit (A.accumulatedGradient (checked (A.gradientHook (Right . map negate) accumulated)))
 emit (checked (A.clipGradient 2 [3,4]))
 emit (checked (A.gradient (\xs -> let m=checked (A.adTensor [2,2] xs) in A.adSum (checked (A.adMatmul m m))) [1,2,3,4]))
 emit (checked (A.gradient (\xs -> let m=checked (A.adTensor [1] xs) in A.adSum (checked (A.adBroadcast [2,3] m))) [2]))
 emit (checked (A.gradient (\xs -> let m=checked (A.adTensor [2] xs) in A.adSum (checked (A.adContract [0] [0] m m))) [2,3]))
 let point=A.variable 0
 let next=checked (A.differentiableStep 0.1 (\[x] -> x*x) [point])
 case next of { [point] -> emit (checked (A.gradient (const point) [3])); _ -> error "step arity" }
 let rule [x] = Right (x*x*x,[3*x*x])
 let (cv,cg) = checked (A.valueAndGradient (\xs -> A.customOperation rule xs) [2])
 emit (cv:cg)
 let (uv,ug) = checked (A.valueAndGradient (\[x] -> A.customUnary (\v -> v*v*v) (\v -> 3*v*v) x) [2])
 emit (uv:ug)
 let (pv,pg) = checked (A.valueAndGradient (\xs -> A.checkpoint (\[x] -> x*x) xs) [3])
 emit (pv:pg)
 let (nv,ng) = checked (A.valueAndGradient (\xs -> A.checkpoint (\[x] -> A.customUnary (\v -> v*v) (\v -> 2*v) x) xs) [3])
 emit (nv:ng)
 let (nestedValue,nestedDerivative) = A.forward (\x -> x*x*x) (A.Dual (3::Double) 1)
 emit [A.primal nestedValue,A.tangent nestedValue,A.primal nestedDerivative,A.tangent nestedDerivative]
 let (floatValue,floatDerivative) = A.forward (\x -> x*x*x) (1.0000001::Float)
 emit [float2Double floatValue,float2Double floatDerivative]
 let (integerValue,integerDerivative) = A.forward (\x -> x*x) (10^100::Integer)
 putStrLn ("E:" ++ intercalate "," (map show [integerValue,integerDerivative]))
 let (ratioValue,ratioDerivative) = A.forward recip (2%3::Rational)
 putStrLn ("E:" ++ intercalate "," (map show [numerator ratioValue,denominator ratioValue,numerator ratioDerivative,denominator ratioDerivative]))
 let (branchValue,branchDerivative) = A.forward (\x -> if x < 0 then negate x else x*x) (-2::Double)
 emit [branchValue,branchDerivative]
"""


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", required=True, type=Path)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(args.library.resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    from _hmath_native import autodiff as ad

    with tempfile.TemporaryDirectory(prefix="hmath-ad-oracle-") as temporary:
        path = Path(temporary)
        source = path / "Main.hs"
        source.write_text(SOURCE)
        subprocess.run(
            [
                "ghc",
                "-O1",
                "-i" + str(ROOT / "src"),
                "-outputdir",
                temporary,
                str(source),
                "-o",
                str(path / "oracle"),
            ],
            check=True,
            stdout=subprocess.DEVNULL,
        )
        expected = subprocess.check_output(
            [str(path / "oracle")], text=True
        ).splitlines()

    def objective(xs):
        x, y = xs
        return x * x + x * y

    def vector(xs):
        x, y = xs
        return [x * y, x + y]

    value, g = ad.value_and_gradient(objective, [3, 4])
    actual = [
        [value, *g],
        ad.gradient(objective, [3, 4]),
        [value for row in ad.hessian(objective, [3, 4]) for value in row],
        [value for row in ad.jacobian(vector, [2, 3]) for value in row],
        ad.jvp(vector, [2, 3], [1, 2]),
        ad.vjp(vector, [2, 3], [1, 2]),
        ad.hvp(objective, [3, 4], [2, -1]),
        [ad.gradient_check(1e-5, objective, [3, 4])],
    ]
    z = ad.complex_gradient(lambda xs: xs[0] * xs[0] + xs[1] * xs[1], 3 + 4j)
    actual.append([z.real, z.imag])
    actual.append(list(ad.forward(lambda x: x * x * x, 3)))
    ps, ts = ad.forward_jvp(lambda xs: [xs[0] * xs[1]], [2, 3], [1, 2])
    actual.append(ps + ts)
    with (
        ad.zero_gradients(2) as state,
        ad.accumulate_gradients(state, [3, 4]) as accumulated,
    ):
        actual.append(accumulated.accumulated_gradient)
        with ad.reset_gradients(accumulated) as reset:
            actual.append(reset.accumulated_gradient)
        with ad.gradient_hook(lambda xs: [-x for x in xs], accumulated) as changed:
            actual.append(changed.accumulated_gradient)
    actual.append(ad.clip_gradient(2, [3, 4]))

    def matmul(xs):
        with (
            ad.ad_tensor([2, 2], xs) as tensor,
            ad.ad_matmul(tensor, tensor) as product,
        ):
            return ad.ad_sum(product)

    actual.append(ad.gradient(matmul, [1, 2, 3, 4]))

    def broadcast(xs):
        with (
            ad.ad_tensor([1], xs) as tensor,
            ad.ad_broadcast([2, 3], tensor) as product,
        ):
            return ad.ad_sum(product)

    actual.append(ad.gradient(broadcast, [2]))

    def contract(xs):
        with (
            ad.ad_tensor([2], xs) as tensor,
            ad.ad_contract([0], [0], tensor, tensor) as product,
        ):
            return ad.ad_sum(product)

    actual.append(ad.gradient(contract, [2, 3]))
    with ad.variable(0) as point:
        updated = ad.differentiable_step(0.1, lambda xs: xs[0] * xs[0], [point])
        try:
            actual.append(ad.gradient(updated[0], [3]))
        finally:
            for value in updated:
                value.close()
    for objective, point in [
        (
            lambda xs: ad.custom_operation(
                lambda values: (values[0] ** 3, [3 * values[0] ** 2]), xs
            ),
            [2],
        ),
        (
            lambda xs: ad.custom_unary(lambda x: x * x * x, lambda x: 3 * x * x, xs[0]),
            [2],
        ),
        (lambda xs: ad.checkpoint(lambda ys: ys[0] * ys[0], xs), [3]),
        (
            lambda xs: ad.checkpoint(
                lambda ys: ad.custom_unary(lambda x: x * x, lambda x: 2 * x, ys[0]), xs
            ),
            [3],
        ),
    ]:
        value, derivatives = ad.value_and_gradient(objective, point)
        actual.append([value, *derivatives])
    with ad.Dual(3, 1) as seed:
        value, derivative = ad.forward(lambda x: x * x * x, seed)
        with value, derivative:
            actual.append(
                [value.primal, value.tangent, derivative.primal, derivative.tangent]
            )
    actual.append(list(ad.forward(lambda x: x * x * x, 1.0000001, dtype="float32")))
    actual.append(
        ("exact", list(ad.forward(lambda x: x * x, 10**100, dtype="integer")))
    )
    value, derivative = ad.forward(lambda x: 1 / x, Fraction(2, 3), dtype="rational")
    actual.append(
        (
            "exact",
            [
                value.numerator,
                value.denominator,
                derivative.numerator,
                derivative.denominator,
            ],
        )
    )
    actual.append(list(ad.forward(lambda x: -x if x < 0 else x * x, -2)))
    assert len(actual) == len(expected)
    for index, (result, reference) in enumerate(zip(actual, expected)):
        if isinstance(result, tuple) and result[0] == "exact":
            encoded = "E:" + ",".join(map(str, result[1]))
        else:
            encoded = ",".join(
                str(struct.unpack("!Q", struct.pack("!d", value))[0])
                for value in result
            )
        assert encoded == reference, (index, result, encoded, reference)
    print(
        f"{len(actual)} AD operation sequences match direct Haskell evaluation bit for bit."
    )


if __name__ == "__main__":
    main()
