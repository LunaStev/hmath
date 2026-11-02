# SPDX-License-Identifier: MPL-2.0
"""Compare full original tensor metadata/values and mutable results with Haskell."""

import argparse
import os
import struct
import subprocess
import sys
import tempfile
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = r"""{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeSynonymInstances #-}
import qualified HMath.Tensor as T
import qualified HMath.Tensor.Mutable as M
import qualified HMath.Error as E
import Data.Complex
import Data.Int
import Data.Word
import Data.Typeable(Typeable)
import Data.List(intercalate)
import Data.Char(ord,toUpper)
import Data.Ratio
import Foreign.Storable
import GHC.Float(castFloatToWord32,castDoubleToWord64)
class Enc a where enc::a->String
instance Enc Int where enc x="I"++show x
instance Enc Integer where enc x="I"++show x
instance Enc Int8 where enc x="I"++show x
instance Enc Word64 where enc x="I"++show x
instance Enc Bool where enc x=if x then "B1" else "B0"
instance Enc Double where enc x="F64:"++show(castDoubleToWord64 x)
instance Enc Float where enc x="F32:"++show(castFloatToWord32 x)
instance Enc Rational where enc x="R"++show(numerator x)++"/"++show(denominator x)
instance Enc a=>Enc(Complex a) where enc(x:+y)="C["++enc x++","++enc y++"]"
instance {-# OVERLAPPING #-} Enc String where enc x="U["++intercalate ","(map(show.ord)x)++"]"
instance {-# OVERLAPPABLE #-} Enc a=>Enc[a] where enc x="L["++intercalate ","(map enc x)++"]"
instance(Enc a,Enc b)=>Enc(a,b) where enc(a,b)="T["++enc a++","++enc b++"]"
instance Enc a=>Enc(Either E.MathError a) where enc(Left e)="ERR"++show e;enc(Right x)=enc x
instance Enc () where enc ()="N"
instance(Typeable a,Enc a)=>Enc(T.Tensor a) where
 enc t="Tensor["++enc(T.tensorDType t)++","++enc(T.tensorShape t)++","++enc(T.tensorStrides t)++","++enc(T.tensorOffset t)++","++show(T.tensorLayout t)++","++enc(T.tensorValues t)++"]"
checked=either(error.show)id
make dims xs=checked(T.tensor dims xs)
a=make[2,2][1.1,-2.3,3.7,4.2]::T.Tensor Double
b=make[2,1][10,20]::T.Tensor Double
x=make[3][1,2,3]::T.Tensor Double
u=make[2][4,5]::T.Tensor Double
mask=make[3][True,False,True]
f=make[1][1.0000001]::T.Tensor Float
q=make[2][1%3,2%7]::T.Tensor Rational
i=make[2][10^100,-3]::T.Tensor Integer
z=make[2][1:+2,(-3):+4]::T.Tensor(Complex Float)
text=make[2]["a","b"]
mu=do
 result<-M.newMutable[2,2](0::Float)
 case result of
  Left e->pure(enc(Left e::Either E.MathError(T.Tensor Float)))
  Right tensor->do
   let view=checked(M.sliceMutable 1 1 2 (-1) tensor)
   _<-M.writeMutable view[1,0]7
   _<-M.modifyMutable tensor[0,0](+2)
   M.freezeTensor(M.transposeMutable view)>>=pure.enc
buffer=do
 result<-M.newMutable[3](1::Float)
 case result of
  Left e->pure(enc(Left e::Either E.MathError(T.Tensor Float)))
  Right tensor->do
   let view=checked(M.sliceMutable 0 2 3 (-1)tensor)
   M.withMutableBuffer view(\pointer _ strides->pokeElemOff pointer(strides!!0)7)
   M.freezeTensor tensor>>=pure.enc
main=sequence_(map(>>=putStrLn)[CASES])
"""


def close(value):
    if isinstance(value, (list, tuple)):
        for item in value:
            close(item)
    elif hasattr(value, "close"):
        value.close()


def encode(value, t, dtype=None):
    def enc(x, code=None):
        return encode(x, t, code)

    if value is None:
        return "N"
    if isinstance(value, bool):
        return "B1" if value else "B0"
    if isinstance(value, int):
        return "I" + str(value)
    if isinstance(value, Fraction):
        return f"R{value.numerator}/{value.denominator}"
    if isinstance(value, float):
        single = dtype in (1, 5)
        return ("F32:" if single else "F64:") + str(
            struct.unpack(
                "=I" if single else "=Q", struct.pack("=f" if single else "=d", value)
            )[0]
        )
    if isinstance(value, complex):
        return "C[" + enc(value.real, dtype) + "," + enc(value.imag, dtype) + "]"
    if isinstance(value, str):
        return "U[" + ",".join(str(ord(c)) for c in value) + "]"
    if isinstance(value, t.Tensor):
        layout = {0: "RowMajor", 1: "ColumnMajor", 2: "Strided"}[value.layout]
        return (
            "Tensor["
            + enc(value.type_name)
            + ","
            + enc(value.shape)
            + ","
            + enc(value.strides)
            + ","
            + enc(value.offset)
            + ","
            + layout
            + ","
            + enc(value.values, value.dtype_code)
            + "]"
        )
    if isinstance(value, (list, tuple)):
        return (
            ("T[" if isinstance(value, tuple) else "L[")
            + ",".join(enc(x, dtype) for x in value)
            + "]"
        )
    raise TypeError(type(value))


def cases(t):
    owned = []

    def keep(x):
        owned.append(x)
        return x

    def make(dims, values, dtype="float64"):
        return keep(t.tensor(dims, values, dtype=dtype))

    a = make([2, 2], [1.1, -2.3, 3.7, 4.2])
    b = make([2, 1], [10, 20])
    x = make([3], [1, 2, 3])
    u = make([2], [4, 5])
    mask = make([3], [True, False, True], "bool")
    f = make([1], [1.0000001], "float32")
    q = make([2], [Fraction(1, 3), Fraction(2, 7)], "rational")
    i = make([2], [10**100, -3], "integer")
    z = make([2], [1 + 2j, -3 + 4j], "complex64")
    text = make([2], ["a", "b"], "string")
    selected = []

    def add(name, hs, call, code=None):
        selected.append((name, "pure(enc(" + hs + "))", call, code))

    for hs, value in [
        ("a", a),
        ("f", f),
        ("q", q),
        ("i", i),
        ("z", z),
        ("text", text),
        ("mask", mask),
    ]:
        add("construct " + hs, hs, lambda value=value: value.clone().decode())
    add(
        "column major",
        "T.tensorColumnMajor[2,2][1,2,3,4::Float]",
        lambda: t.tensor_column_major([2, 2], [1, 2, 3, 4], dtype="float32"),
    )
    add("scalar", "T.tensor[][7::Integer]", lambda: t.tensor([], [7], dtype="integer"))
    add(
        "zero axis",
        "T.tensor[0,2][]::Either E.MathError(T.Tensor Float)",
        lambda: t.tensor([0, 2], [], dtype="float32"),
    )
    add(
        "zeros",
        "T.tensorZeros[2,2]::Either E.MathError(T.Tensor Rational)",
        lambda: t.tensor_zeros([2, 2], dtype="rational"),
    )
    add(
        "ones",
        "T.tensorOnes[2]::Either E.MathError(T.Tensor Int8)",
        lambda: t.tensor_ones([2], dtype="int8"),
    )
    add(
        "full",
        "T.tensorFull[2](2%3::Rational)",
        lambda: t.tensor_full([2], Fraction(2, 3), dtype="rational"),
    )
    add(
        "arange",
        "T.tensorArange(0.1::Float)1 0.2",
        lambda: t.tensor_arange(0.1, 1, 0.2, dtype="float32"),
    )
    add(
        "linspace",
        "T.tensorLinspace(1%3::Rational)(2%3)4",
        lambda: t.tensor_linspace(Fraction(1, 3), Fraction(2, 3), 4, dtype="rational"),
    )
    add(
        "logspace",
        "T.tensorLogspace(2::Float)(-1)2 5",
        lambda: t.tensor_logspace(2, -1, 2, 5, dtype="float32"),
    )
    add(
        "random",
        "T.tensorRandom(10^100+7)[2,2]",
        lambda: t.tensor_random(10**100 + 7, [2, 2]),
    )
    for source, py in [
        ("tensorShape", "tensor_shape"),
        ("tensorStrides", "tensor_strides"),
        ("tensorOffset", "tensor_offset"),
        ("tensorDType", "tensor_dtype"),
        ("isContiguous", "is_contiguous"),
        ("numel", "numel"),
    ]:
        add(source, "T." + source + " a", lambda py=py: getattr(t, py)(a))
    add("values", "T.tensorValues f", lambda: t.tensor_values(f), 1)
    add("size", "T.shapeSize[2,3,0]", lambda: t.shape_size([2, 3, 0]))
    add(
        "broadcast shape",
        "T.inferBroadcast[2,1][3]",
        lambda: t.infer_broadcast([2, 1], [3]),
    )
    add("index", "T.indexTensor a[1,0]", lambda: t.index_tensor(a, [1, 0]))
    add("slice", "T.sliceTensor 1 1 2 (-1) a", lambda: t.slice_tensor(1, 1, 2, -1, a))
    sliced = keep(t.slice_tensor(1, 1, 2, -1, a))
    add(
        "contiguous",
        "T.sliceTensor 1 1 2 (-1) a >>= T.contiguous",
        lambda: t.contiguous(sliced),
    )
    for source, py in [("fancyIndex", "fancy_index"), ("gather", "gather")]:
        add(
            source,
            "T." + source + " 0 [2,0,2] x",
            lambda py=py: getattr(t, py)(0, [2, 0, 2], x),
        )
    add("boolean index", "T.booleanIndex mask x", lambda: t.boolean_index(mask, x))
    for source, py in [("scatter", "scatter"), ("scatterAdd", "scatter_add")]:
        add(
            source,
            "T." + source + " 0 [1,1] u x",
            lambda py=py: getattr(t, py)(0, [1, 1], u, x),
        )
    add("reshape", "T.reshapeTensor[4]a", lambda: t.reshape_tensor([4], a))
    add("flatten", "T.flattenTensor a", lambda: t.flatten_tensor(a))
    for source, py, hs, params in [
        ("squeeze", "squeeze", "b", [b]),
        ("unsqueeze", "unsqueeze", "0 a", [0, a]),
        ("expand", "expand", "[3,2,2]a", [[3, 2, 2], a]),
        ("permute", "permute", "[1,0]a", [[1, 0], a]),
        ("transposeTensor", "transpose_tensor", "a", [a]),
        ("moveAxis", "move_axis", "0 1 a", [0, 1, a]),
        ("swapAxes", "swap_axes", "0 1 a", [0, 1, a]),
        ("broadcastTo", "broadcast_to", "[3,2,2]a", [[3, 2, 2], a]),
        ("repeatTensor", "repeat_tensor", "1 2 a", [1, 2, a]),
        ("tile", "tile", "[1,2]a", [[1, 2], a]),
        ("roll", "roll", "1 1 a", [1, 1, a]),
        ("flipTensor", "flip_tensor", "1 a", [1, a]),
        ("rotate", "rotate", "0 1 1 a", [0, 1, 1, a]),
    ]:
        add(
            source,
            "T." + source + " " + hs,
            lambda py=py, params=params: getattr(t, py)(*params),
        )
    for source, py in [("concatenate", "concatenate"), ("stack", "stack")]:
        add(source, "T." + source + " 0 [a,a]", lambda py=py: getattr(t, py)(0, [a, a]))
    add("split", "T.splitTensor 1 [1,1] a", lambda: t.split_tensor(1, [1, 1], a))
    add("chunk", "T.chunkTensor 0 2 a", lambda: t.chunk_tensor(0, 2, a))
    add(
        "padding",
        "T.padTensor[(1,0),(0,1)]9 a",
        lambda: t.pad_tensor([(1, 0), (0, 1)], 9, a),
    )
    for source, py in [
        ("sortTensor", "sort_tensor"),
        ("argsort", "argsort"),
        ("unique", "unique"),
        ("nonzero", "nonzero"),
    ]:
        add(source, "T." + source + " a", lambda py=py: getattr(t, py)(a))
    add("topk", "T.topk 2 a", lambda: t.topk(2, a))
    add(
        "where",
        "T.whereTensor mask x (make[3][7,8,9::Double])",
        lambda: t.where_tensor(mask, x, make([3], [7, 8, 9])),
    )
    add("masked fill", "T.maskedFill mask 7 x", lambda: t.masked_fill(mask, 7, x))
    add("masked select", "T.maskedSelect mask x", lambda: t.masked_select(mask, x))
    add(
        "map float32",
        r"T.mapTensor(\v->v*v*v)f",
        lambda: t.map_tensor(lambda v: v * v * v, f),
    )
    add(
        "map string",
        "T.mapTensor(map toUpper)text",
        lambda: t.map_tensor(str.upper, text),
    )
    add(
        "zip cross type",
        r"T.zipTensor(\v w->toRational v+w)f q",
        lambda: t.zip_tensor(
            lambda v, w: Fraction(v.value) + w.value, f, q, dtype="rational"
        ),
    )
    for source, py in [
        ("tensorAdd", "tensor_add"),
        ("tensorSubtract", "tensor_subtract"),
        ("tensorMultiply", "tensor_multiply"),
        ("tensorDivide", "tensor_divide"),
        ("tensorEqual", "tensor_equal"),
        ("tensorLess", "tensor_less"),
    ]:
        add(source, "T." + source + " a b", lambda py=py: getattr(t, py)(a, b))
    for source, py in [("tensorAnd", "tensor_and"), ("tensorOr", "tensor_or")]:
        add(
            source,
            "T." + source + " mask mask",
            lambda py=py: getattr(t, py)(mask, mask),
        )
    add("not", "T.tensorNot mask", lambda: t.tensor_not(mask))
    add(
        "promote",
        "T.promoteTensor f::T.Tensor Double",
        lambda: t.promote_tensor("float64", f),
    )
    for source, py in [
        ("sumAxes", "sum_axes"),
        ("meanAxes", "mean_axes"),
        ("productAxes", "product_axes"),
        ("minAxes", "min_axes"),
        ("maxAxes", "max_axes"),
        ("varianceAxes", "variance_axes"),
        ("normAxes", "norm_axes"),
    ]:
        add(
            source,
            "T." + source + "[0]True a",
            lambda py=py: getattr(t, py)([0], True, a),
        )
    for source, py in [("argmin", "argmin"), ("argmax", "argmax")]:
        add(source, "T." + source + " a", lambda py=py: getattr(t, py)(a))
    for source, py in [
        ("cumulativeSum", "cumulative_sum"),
        ("cumulativeProduct", "cumulative_product"),
    ]:
        add(source, "T." + source + " 1 a", lambda py=py: getattr(t, py)(1, a))
    add("tensordot", "T.tensordot[1][0]a a", lambda: t.tensordot([1], [0], a, a))
    add(
        "einsum",
        'T.einsum["ab","bc"]"ac"[a,a]',
        lambda: t.einsum(["ab", "bc"], "ac", [a, a]),
    )
    add(
        "einsum identity",
        'T.einsum[]""[]::Either E.MathError(T.Tensor Rational)',
        lambda: t.einsum([], "", [], dtype="rational"),
    )
    for source, py in [
        ("batchedMatmul", "batched_matmul"),
        ("tensorKronecker", "tensor_kronecker"),
    ]:
        add(source, "T." + source + " a a", lambda py=py: getattr(t, py)(a, a))
    add("serialize", "T.serializeTensor q", lambda: t.serialize_tensor(q))
    add(
        "deserialize",
        "T.deserializeTensor(T.serializeTensor q)::Either E.MathError(T.Tensor Rational)",
        lambda: t.deserialize_tensor(t.serialize_tensor(q), dtype="rational"),
    )
    leaf = keep(t.input_graph(f))
    mapped = keep(t.map_graph(lambda v: v * v, leaf))
    add(
        "graph map",
        r"T.evaluateGraph(T.mapGraph(\v->v*v)(T.inputGraph f))",
        lambda: t.evaluate_graph(mapped),
    )
    zipped = keep(t.zip_graph(lambda v, w: v + w, mapped, mapped))
    add(
        "graph zip",
        r"T.zipGraph(+)(T.mapGraph(\v->v*v)(T.inputGraph f))(T.mapGraph(\v->v*v)(T.inputGraph f)) >>= T.evaluateGraph",
        lambda: t.evaluate_graph(zipped),
    )

    def mutable():
        with (
            t.new_mutable([2, 2], 0, dtype="float32") as base,
            t.slice_mutable(1, 1, 2, -1, base) as view,
        ):
            t.write_mutable(view, [1, 0], 7)
            t.modify_mutable(base, [0, 0], lambda v: v + 2)
            with t.transpose_mutable(view) as transposed:
                return t.freeze_tensor(transposed)

    selected.append(("mutable view", "mu", mutable, None))

    def buffer():
        with (
            t.new_mutable([3], 1, dtype="float32") as base,
            t.slice_mutable(0, 2, 3, -1, base) as view,
        ):

            def update(raw):
                raw.pointer[raw.strides[0]] = 7

            t.with_mutable_buffer(view, update)
            return t.freeze_tensor(base)

    selected.append(("mutable buffer", "buffer", buffer, None))
    add("bad shape", "T.tensor[-1][1::Double]", lambda: t.tensor([-1], [1]))
    add("bad count", "T.tensor[2][1::Double]", lambda: t.tensor([2], [1]))
    add("bad slice", "T.sliceTensor 0 3 1 1 x", lambda: t.slice_tensor(0, 3, 1, 1, x))
    add("bad reshape", "T.reshapeTensor[5]a", lambda: t.reshape_tensor([5], a))
    add("bad axes", "T.sumAxes[0,0]False a", lambda: t.sum_axes([0, 0], False, a))
    return selected, owned


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", required=True, type=Path)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(args.library.resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath
    from _hmath_native import _tensor_core as t

    selected, owned = cases(t)
    try:
        with tempfile.TemporaryDirectory(prefix="hmath-tensor-oracle-") as temporary:
            path = Path(temporary)
            source = path / "Main.hs"
            source.write_text(
                SOURCE.replace(
                    "CASES", ",\n  ".join(expr for _, expr, _, _ in selected)
                )
            )
            subprocess.run(
                [
                    "ghc",
                    "-XHaskell2010",
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
        for (name, _, call, dtype), reference in zip(selected, expected, strict=True):
            value = None
            try:
                value = call()
                actual = encode(value, t, dtype)
            except hmath.HMathError as error:
                if error.math_error is None:
                    raise
                actual = "ERR" + str(error.math_error)
            finally:
                close(value)
            if actual != reference:
                raise AssertionError(f"{name}: native {actual}, original {reference}")
        print(
            f"Tensor equivalence: {len(selected)} independent original Haskell sequences match dtype/shape/strides/offset/layout, exact data and IEEE bits, mutable views and errors."
        )
    finally:
        close(owned)


if __name__ == "__main__":
    main()
