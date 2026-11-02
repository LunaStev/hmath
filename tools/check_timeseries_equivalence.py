# SPDX-License-Identifier: MPL-2.0
"""Independent original-Haskell oracle for the complete TimeSeries adapter."""

import argparse
import json
import os
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

from generate_graph_bindings import snake, split_top
from generate_timeseries_bindings import TYPES

ROOT = Path(__file__).resolve().parent.parent
HASKELL = r"""{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeSynonymInstances #-}
import qualified HMath.TimeSeries as T
import qualified HMath.Signal as S
import qualified HMath.Optimization.Common as O
import qualified HMath.Error as E
import Data.Char(ord)
import Data.List(intercalate)
import GHC.Float(castDoubleToWord64)
class Encode a where enc :: a -> String
instance Encode Int where enc x="I"++show x
instance Encode Double where enc x="F"++show(castDoubleToWord64 x)
instance Encode Bool where enc x=if x then "B1" else "B0"
instance {-# OVERLAPPING #-} Encode String where enc x="S"++show(map ord x)
instance {-# OVERLAPPABLE #-} Encode a => Encode [a] where enc xs="L["++intercalate "," (map enc xs)++"]"
instance Encode a => Encode (Maybe a) where enc Nothing="N"; enc(Just x)=enc x
instance(Encode a,Encode b) => Encode(a,b) where enc(a,b)="T["++enc a++","++enc b++"]"
instance(Encode a,Encode b,Encode c) => Encode(a,b,c) where enc(a,b,c)="T["++enc a++","++enc b++","++enc c++"]"
INSTANCES
ok :: Encode a => Either E.MathError a -> String
ok=either (("E"++).show) enc
right(Right x)=x
right(Left e)=error(show e)
xs=[2,1,4,3,6,5,8,7,10,9,12,11] :: [Double]
options=O.OptimizeOptions 100 300 1e-8 0.01
series=right(T.series [(0,Just 1),(1,Nothing),(2,Just 3)])
complete=right(T.regularSeries 0 1 (map Just xs))
alignment=T.Outer
fill=T.LinearFill
resampling=T.BinMean
rolling=T.MovingMean
dtw=right(T.dynamicTimeWarping 2 xs xs)
deterministic=T.Level
metric=T.MAE
stationarity=T.Stationarity 3 [(0.05,2)] 12 "null"
arima=right(T.fitARIMA options 0 0 0 xs)
ar=right(T.fitAR 1 xs)
decomposition=right(T.decompose 2 xs)
order=T.SARIMAOrder 0 0 0 0 0 0 1
config=T.defaultSTLConfig 2
smoothing=T.Simple 0.5
var=right(T.fitVAR 1 (map (:[]) xs))
gaussian=right(S.gaussianState [0] [[1]])
main=mapM_ putStrLn [EXPRESSIONS]
"""


def close(value):
    if hasattr(value, "close"):
        value.close()
    elif isinstance(value, (tuple, list)):
        for item in value:
            close(item)


def encode(value, ts):
    from _hmath_native._value import Value

    if value is None:
        return "N"
    if isinstance(value, bool):
        return "B1" if value else "B0"
    if isinstance(value, int):
        return "I" + str(value)
    if isinstance(value, float):
        return "F" + str(struct.unpack("!Q", struct.pack("!d", value))[0])
    if isinstance(value, str):
        return "S" + json.dumps(list(map(ord, value)), separators=(",", ":"))
    if isinstance(value, Value):
        return "O" + encode(ts.describe(value), ts)
    if isinstance(value, (tuple, list)):
        return (
            ("T[" if isinstance(value, tuple) else "L[")
            + ",".join(encode(item, ts) for item in value)
            + "]"
        )
    raise TypeError(type(value))


def cases(ts, opt):
    xs = [2.0, 1.0, 4.0, 3.0, 6.0, 5.0, 8.0, 7.0, 10.0, 9.0, 12.0, 11.0]
    options = opt.OptimizeOptions(100, 300, 1e-8, 0.01)
    owners = {
        "series": ts.series([(0, 1), (1, None), (2, 3)]),
        "complete": ts.regular_series(0, 1, xs),
        "alignment": ts.outer(),
        "fill": ts.linear_fill(),
        "resampling": ts.bin_mean(),
        "rolling": ts.moving_mean(),
        "dtw": ts.dynamic_time_warping(2, xs, xs),
        "deterministic": ts.level(),
        "metric": ts.mae(),
        "stationarity": ts.stationarity(3, [(0.05, 2)], 12, "null"),
        "arima": ts.fit_arima(options, 0, 0, 0, xs),
        "ar": ts.fit_ar(1, xs),
        "decomposition": ts.decompose(2, xs),
        "order": ts.sarima_order(0, 0, 0, 0, 0, 0, 1),
        "config": ts.default_stl_config(2),
        "smoothing": ts.simple(0.5),
        "var": ts.fit_var(1, [[x] for x in xs]),
        "gaussian": ts.gaussian_state([0], [[1]]),
    }
    keys = dict(
        zip(
            TYPES,
            [
                "series",
                "alignment",
                "fill",
                "resampling",
                "rolling",
                "dtw",
                "deterministic",
                "metric",
                "stationarity",
                "arima",
                "ar",
                "decomposition",
                "order",
                "config",
                "smoothing",
                "var",
                "gaussian",
            ],
        )
    )
    defaults = {
        "Int": (2, "2"),
        "Double": (0.5, "0.5"),
        "Bool": (False, "False"),
        "String": ("null", '"null"'),
        "[Double]": (xs, "xs"),
        "[[Double]]": ([[1.0]], "[[1]]"),
        "[Maybe Double]": ([1, None, 3], "[Just 1,Nothing,Just 3]"),
        "[(Double, Maybe Double)]": (
            [(0, 1), (1, None), (2, 3)],
            "[(0,Just 1),(1,Nothing),(2,Just 3)]",
        ),
        "[(Int, Int)]": ([(0, 0), (1, 1)], "[(0,0),(1,1)]"),
        "[(Double, Double)]": ([(0.05, 2)], "[(0.05,2)]"),
        "OptimizeOptions": (options, "options"),
    }
    overrides = {
        "fitARIMA": ([options, 0, 0, 0, xs], ["options", "0", "0", "0", "xs"]),
        "fitARMA": ([options, 0, 0, xs], ["options", "0", "0", "xs"]),
        "fitMA": ([options, 0, xs], ["options", "0", "xs"]),
        "fitAR": ([1, xs], ["1", "xs"]),
        "fitVAR": ([1, [[x] for x in xs]], ["1", "(map (:[]) xs)"]),
        "gaussianState": ([[0], [[1]]], ["[0]", "[[1]]"]),
        "seriesValues": ([owners["complete"]], ["complete"]),
        "regularSeries": ([0, 1, [1, None, 3]], ["0", "1", "[Just 1,Nothing,Just 3]"]),
    }
    entries = json.loads(
        (ROOT / "bindings/schema/timeseries-functions.json").read_text()
    )["functions"]
    result = []
    for entry in entries:
        name = entry["name"]
        if name in overrides:
            arguments, expressions = overrides[name]
        else:
            arguments, expressions = [], []
            for typ in split_top(entry["signature"], "->")[:-1]:
                if typ in keys:
                    key = keys[typ]
                    arguments.append(owners[key])
                    expressions.append(key)
                else:
                    value, expression = defaults[typ]
                    arguments.append(value)
                    expressions.append(expression)
        qualified = "S" if entry["module"] == "HMath.Signal" else "T"
        call = qualified + "." + name + " " + " ".join(expressions)
        checked = split_top(entry["signature"], "->")[-1].startswith("Either MathError")
        result.append(
            (snake(name), arguments, ("ok (" if checked else "enc (") + call + ")")
        )
    result += [
        ("series_values", [owners["series"]], "ok(T.seriesValues series)"),
        ("series", [[(1, 2), (0, 3)]], "ok(T.series [(1,Just 2),(0,Just 3)])"),
        ("regular_series", [0, 0, []], "ok(T.regularSeries 0 0 [])"),
        ("forecast_ar", [-1, owners["ar"]], "ok(T.forecastAR (-1) ar)"),
        (
            "fit_sarima",
            [options, owners["order"], [1, 2]],
            "ok(T.fitSARIMA options order [1,2])",
        ),
        ("rolling", [owners["rolling"], 0, xs], "ok(T.rolling rolling 0 xs)"),
        ("gaussian_state", [[0], [[-1]]], "ok(S.gaussianState [0] [[-1]])"),
    ]
    return result, owners


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(Path(args.library).resolve())
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath

    ts = hmath.timeseries
    fixtures, owners = cases(ts, hmath.optimization)
    try:
        instances = "\n".join(
            "instance Encode "
            + ("S." if module == "HMath.Signal" else "T.")
            + name
            + ' where enc x="O"++enc(show x)'
            for name, (module, _) in TYPES.items()
        )
        source = HASKELL.replace("INSTANCES", instances).replace(
            "EXPRESSIONS", ",\n    ".join(case[2] for case in fixtures)
        )
        with tempfile.TemporaryDirectory(
            prefix="hmath-timeseries-oracle-"
        ) as directory:
            path = Path(directory) / "Main.hs"
            path.write_text(source)
            executable = Path(directory) / "oracle"
            process = subprocess.run(
                [
                    "ghc",
                    "-XHaskell2010",
                    "-O1",
                    "-isrc",
                    "-Iinclude",
                    "-outputdir",
                    directory,
                    str(path),
                    "cbits/backend.c",
                    *(["-ldl"] if sys.platform.startswith("linux") else []),
                    "-o",
                    str(executable),
                ],
                cwd=ROOT,
                capture_output=True,
                text=True,
                check=False,
            )
            if process.returncode:
                raise RuntimeError(process.stderr)
            expected = subprocess.check_output(
                [str(executable)], text=True
            ).splitlines()
        actual = []
        for name, arguments, _ in fixtures:
            try:
                value = getattr(ts, name)(*arguments)
            except hmath.HMathError as error:
                actual.append("E" + str(error.math_error or error))
            else:
                try:
                    actual.append(encode(value, ts))
                finally:
                    close(value)
        failures = [
            (i, fixtures[i][0], want, got)
            for i, (want, got) in enumerate(zip(expected, actual))
            if want != got
        ]
        if len(actual) != len(expected) or failures:
            raise AssertionError(f"TimeSeries oracle mismatches: {failures[:8]}")
        print(
            f"TimeSeries direct Haskell equivalence: {len(actual)} cases, all101 named adapters"
        )
    finally:
        for owner in owners.values():
            owner.close()


if __name__ == "__main__":
    main()
