# SPDX-License-Identifier: MPL-2.0
"""Direct original-source oracle for all linear-domain functions/records."""

import argparse
import importlib
import json
import os
import subprocess
import sys
import tempfile
from fractions import Fraction
from pathlib import Path

from check_polynomial_equivalence import HASKELL, bits, close
from generate_linear_bindings import MODULES, generic_entry, hs_type, signatures, snake

ROOT = Path(__file__).resolve().parent.parent


def normalize(value, precision, modules):
    from _hmath_native._linear_base import LinearValue
    from _hmath_native._matrix_base import LU, QR, Matrix

    if isinstance(value, LinearValue):
        module, name = value.source_type.rsplit(".", 1)
        target = modules[module]
        if name == "Vector":
            fields = target.vector_values(value)
        elif name == "FixedVector":
            fields = target.fixed_values(value)
        elif name == "SparseVector":
            fields = target.sparse_vector_values(value)
        elif name == "Sparse":
            fields = (target.sparse_shape(value), target.sparse_entries(value))
        elif name == "SparseTensor":
            fields = (
                target.sparse_tensor_shape(value),
                target.sparse_tensor_entries(value),
            )
        elif name == "SparseLU":
            fields = (
                target.sparse_lu_lower(value),
                target.sparse_lu_upper(value),
                target.sparse_lu_permutation(value),
            )
        elif name == "SparseQR":
            fields = target.sparse_qr_upper(value)
        elif name == "Preconditioner":
            fields = target.apply_preconditioner(value, [1, 1])
        elif name == "Backend":
            fields = target.backend_info(value)
        else:
            fields = value.parts
        try:
            return value.source_type + "(" + normalize(fields, precision, modules) + ")"
        finally:
            close(fields)
    if isinstance(value, Matrix):
        r, c = value.shape
        return (
            f"M{r}:{c}["
            + ",".join(normalize(x, precision, modules) for x in value.to_list())
            + "]"
        )
    if isinstance(value, LU):
        target = modules["HMath.Matrix.Decomposition"]
        from _hmath_native import matrix as m

        fields = (m.lu_lower(value), m.lu_upper(value), m.lu_permutation(value))
        try:
            return "LU(" + normalize(fields, precision, modules) + ")"
        finally:
            close(fields)
    if isinstance(value, QR):
        from _hmath_native import matrix as m

        fields = (
            m.qr_q(value),
            m.qr_r(value),
            m.qr_permutation(value),
            m.qr_rank(value),
        )
        try:
            return "QR(" + normalize(fields, precision, modules) + ")"
        finally:
            close(fields)
    if value is None:
        return "N"
    if isinstance(value, str):
        return "L[" + ",".join("I" + str(ord(x)) for x in value) + "]"
    if isinstance(value, bool):
        return "B1" if value else "B0"
    if isinstance(value, Fraction):
        return f"R{value.numerator}/{value.denominator}"
    if isinstance(value, int):
        return "I" + str(value)
    if isinstance(value, float):
        return f"F{precision}:" + str(bits(value, precision))
    if isinstance(value, complex):
        return (
            f"C{precision}:"
            + str(bits(value.real, precision))
            + ":"
            + str(bits(value.imag, precision))
        )
    if isinstance(value, (list, tuple)):
        return (
            ("T[" if isinstance(value, tuple) else "L[")
            + ",".join(normalize(x, precision, modules) for x in value)
            + "]"
        )
    raise TypeError(type(value))


class Fixtures:
    def __init__(self, modules, types, dtype):
        self.modules = modules
        self.types = types
        self.dtype = dtype
        self.owned = []
        self.hstype = {
            "float32": "Float",
            "float64": "Double",
            "rational": "Rational",
            "integer": "Integer",
            "complex128": "Complex Double",
            "complex64": "Complex Float",
        }[dtype]

    def own(self, value, expression):
        if hasattr(value, "close"):
            self.owned.append(value)
        return value, expression

    def type(self, spec):
        return (
            hs_type(spec, self.types)
            .replace("(a)", "(" + self.hstype + ")")
            .replace("(b)", "(" + self.hstype + ")")
            .replace("(c)", "(" + self.hstype + ")")
        )

    def coefficient(self, value=0.0001):
        if self.dtype == "integer":
            value = int(value)
        elif self.dtype == "rational":
            value = Fraction(str(value))
        elif self.dtype.startswith("complex"):
            value = complex(value)
        return value, (
            "(" + str(value.numerator) + "%" + str(value.denominator) + ")"
        ) if isinstance(value, Fraction) else "(" + str(value.real) + " :+ " + str(
            value.imag
        ) + ")" if isinstance(value, complex) else str(value)

    def matrix(self, coefficient=None):
        from _hmath_native import matrix as m

        coefficient = coefficient or ["a"]
        dtype = {"Double": "float64", "Rational": "rational"}.get(
            coefficient[0], self.dtype
        )
        if coefficient[0] == "Complex":
            dtype = (
                "complex64"
                if coefficient[1] == ["Float"]
                or coefficient[1] == ["a"]
                and self.dtype == "float32"
                else "complex128"
            )
        value = m.from_list_checked(2, 2, [2, 0, 0, 3], dtype=dtype)
        hstype = {
            "float32": "Float",
            "float64": "Double",
            "rational": "Rational",
            "integer": "Integer",
            "complex128": "Complex Double",
            "complex64": "Complex Float",
        }[dtype]
        return self.own(
            value,
            "(right(M.fromListChecked 2 2 [2,0,0,3]) :: M.Matrix (" + hstype + "))",
        )

    def object(self, name):
        typ = self.types[name]
        module = self.modules[typ["module"]]
        alias = typ["alias"]
        generic = "a" in typ["params"]

        def invoke(fn, args, expr):
            value = getattr(module, fn)(
                *args, **({"dtype": self.dtype} if generic else {})
            )
            return self.own(
                value,
                "("
                + expr
                + " :: "
                + (
                    "V.FixedVector 2 (" + self.hstype + ")"
                    if name == "FixedVector"
                    else alias
                    + "."
                    + name
                    + (" (" + self.hstype + ")" if generic else "")
                )
                + ")",
            )

        if name == "Vector":
            return invoke("vector", [[1, 2, 3]], "V.vector [1,2,3]")
        if name == "FixedVector":
            return invoke("fixed_vector", [2, [1, 2]], "right(V.fixedVector @2 [1,2])")
        if name == "SparseVector":
            return invoke(
                "sparse_vector",
                [3, [(0, 1), (2, 2)]],
                "right(V.sparseVector 3 [(0,1),(2,2)])",
            )
        if name == "Sparse":
            return invoke(
                "sparse",
                [2, 2, [(0, 0, 2), (1, 1, 3)]],
                "right(S.sparse 2 2 [(0,0,2),(1,1,3)])",
            )
        if name == "SparseTensor":
            return invoke(
                "sparse_tensor",
                [[2, 2], [([0, 0], 2), ([1, 1], 3)]],
                "right(S.sparseTensor [2,2] [([0,0],2),([1,1],3)])",
            )
        if name in ("SparseFormat", "SparseLU", "SparseQR"):
            value, hs = self.object("Sparse")
            fn, expr = {
                "SparseFormat": ("to_csr", "S.toCSR " + hs),
                "SparseLU": ("sparse_lu", "right(S.sparseLU 0 " + hs + ")"),
                "SparseQR": ("sparse_qr", "right(S.sparseQR " + hs + ")"),
            }[name]
            args = [0, value] if name == "SparseLU" else [value]
            return invoke(fn, args, expr)
        if name == "Preconditioner":
            return invoke(
                "identity_preconditioner", [2], "right(I.identityPreconditioner 2)"
            )
        if name == "Backend":
            return invoke("pure_backend", [], "B.pureBackend")
        if name in ("Provider", "IntegerABI", "BackendLayout", "Transpose"):
            fn, hs = {
                "Provider": ("pure", "B.Pure"),
                "IntegerABI": ("lp64", "B.LP64"),
                "BackendLayout": ("row_major", "B.RowMajor"),
                "Transpose": ("no_transpose", "B.NoTranspose"),
            }[name]
            return invoke(fn, [], hs)
        if name == "BackendRequest":
            return invoke("auto_backend", [], "B.AutoBackend")
        if name == "IterativeOptions":
            return self.own(
                module.IterativeOptions(0.0001, 0.0001, 12, dtype=self.dtype),
                "(I.IterativeOptions 0.0001 0.0001 12 :: I.IterativeOptions ("
                + self.hstype
                + "))",
            )
        if name == "SparseSpectralOptions":
            return self.own(
                module.SparseSpectralOptions(
                    0.0001, 0.0001, 12, 100000, dtype=self.dtype
                ),
                "(P.SparseSpectralOptions 0.0001 0.0001 12 100000 :: P.SparseSpectralOptions ("
                + self.hstype
                + "))",
            )
        fields = json.loads(
            (ROOT / "bindings/schema/linear-functions.json").read_text()
        )["fields"][name]
        values = []
        expressions = []
        for field, spec in fields:
            value, expression = self.argument(spec, name, len(values), field)
            values.append(value)
            expressions.append(expression)
        constructor = getattr(module, name)
        value = constructor(*values, **({"dtype": self.dtype} if generic else {}))
        return self.own(
            value,
            "("
            + alias
            + "."
            + name
            + " "
            + " ".join("(" + x + ")" for x in expressions)
            + " :: "
            + alias
            + "."
            + name
            + (" (" + self.hstype + ")" if generic else "")
            + ")",
        )

    def argument(self, spec, name, index, field=""):
        head, *args = spec
        if head in self.types:
            return self.object(head)
        if head == "Matrix":
            return self.matrix(args[0])
        if head == "a":
            return self.coefficient(
                0.0001
                if any(x in field.lower() for x in ["tolerance", "residual"])
                or "tol" in name.lower()
                else 0.25
            )
        if head == "Double":
            return 0.25, "(0.25::Double)"
        if head == "Rational":
            return Fraction(1, 4), "(1%4)"
        if head == "Integer":
            return 2, "2"
        if head == "Int":
            value = (
                50 if "iteration" in field.lower() or "limit" in field.lower() else 2
            )
            return value, str(value)
        if head == "Bool":
            return False, "False"
        if head == "String":
            return "test", '"test"'
        if head == "Complex":
            return complex(0.25, 0), "(0.25:+0)"
        if head == "Maybe":
            return None, "Nothing"
        if head == "tuple":
            values = []
            expressions = []
            for i, child in enumerate(args):
                value, expression = self.argument(child, name, i, field)
                values.append(value)
                expressions.append(expression)
            return tuple(values), "(" + ",".join(expressions) + ")"
        if head == "list":
            child = args[0]
            if child == ["Int"]:
                value = (
                    [0, 1, 2]
                    if name in ("CSR", "CSC", "BSR") and index == 2
                    else [1, 0]
                    if name == "permutationMatrix"
                    else [1, 1]
                    if name == "blockJacobiPreconditioner"
                    else [0, 1]
                    if name in ("CSR", "CSC", "BSR", "ELLPACK")
                    else [2, 2]
                )
                return value, str(value)
            if child == ["a"]:
                values = (
                    [1, 2, 3]
                    if name in ("vector", "sparseVectorValues")
                    else [1, 1, 1, 1]
                    if name == "matrixFromLayout"
                    else [1, 1]
                )
                return values, str(values)
            if child == ["Double"]:
                return [1.0, 1.0], "[1,1]"
            if child == ["Rational"]:
                return [Fraction(2), Fraction(3)], "[2,3]"
            value, expression = self.argument(child, name, index, field)
            return [value], "[" + expression + "]"
        if head == "function":
            if name == "generateMatrix":
                return (
                    lambda row, column: row + column,
                    "(\\row column -> fromIntegral(row+column))",
                )
            if name == "zipMatrixWith":
                return lambda a, b: a + b, "(+)"
        raise ValueError((name, index, spec))


def oracle_instances(types, fields, entries):
    out = [
        'instance E () where enc ()="N"\ninstance E Char where enc x="I"++show(ord x)\nright :: Either EError.MathError a -> a\nright=either(error.show) id\n'
    ]
    for name, typ in types.items():
        alias = typ["alias"]
        generic = "a" in typ["params"]
        ctx = (
            "(E a"
            + (
                ",RealFloat a"
                if name == "Preconditioner"
                else ",Num a"
                if name == "SparseVector"
                else ""
            )
            + ") => "
            if generic
            else ""
        )
        target = (
            "V.FixedVector n a"
            if name == "FixedVector"
            else alias + "." + name + (" a" if generic else "")
        )
        out.append(
            "instance "
            + ctx
            + "E ("
            + target
            + ') where\n    enc value="'
            + typ["module"]
            + "."
            + name
            + '("++('
        )
        if name == "Vector":
            expr = "enc(V.vectorValues value)"
        elif name == "FixedVector":
            expr = "enc(V.fixedValues value)"
        elif name == "SparseVector":
            expr = "enc(V.sparseVectorValues value)"
        elif name == "Sparse":
            expr = "enc(S.sparseShape value,S.sparseEntries value)"
        elif name == "SparseTensor":
            expr = "enc(S.sparseTensorShape value,S.sparseTensorEntries value)"
        elif name == "SparseLU":
            expr = "enc(S.sparseLULower value,S.sparseLUUpper value,S.sparseLUPermutation value)"
        elif name == "SparseQR":
            expr = "enc(S.sparseQRUpper value)"
        elif name == "Preconditioner":
            expr = "ok(I.applyPreconditioner value [1,1])"
        elif name == "Backend":
            expr = "enc(B.backendInfo value)"
        else:
            constructors = [
                e for e in entries if e["constructor"] and e["result"][0] == name
            ]
            parts = []
            for entry in constructors:
                variables = ["p" + str(i) for i in range(len(entry["args"]))]
                # Encode public variant fields as the same (constructor, tuple) transport.
                encoded = (
                    '"T["++enc("'
                    + entry["name"]
                    + '")++",T["++intercalate "," ['
                    + ",".join("enc " + v for v in variables)
                    + ']++"]]"'
                )
                parts.append(
                    alias
                    + "."
                    + entry["name"]
                    + " "
                    + " ".join(variables)
                    + " -> "
                    + encoded
                )
            expr = "case value of {" + ";".join(parts) + "}"
        out.append(expr + ')++")"\n')
    out.append(
        'instance E(LU.LU Double) where enc value="LU("++enc(LU.luLower value,LU.luUpper value,LU.luPermutation value)++")"\n'
    )
    out.append(
        'instance E(QR.QR Double) where enc value="QR("++enc(QR.qrQ value,QR.qrR value,QR.qrPermutation value,QR.qrRank value)++")"\n'
    )
    out.append(
        'instance(E a,E b,E c,E d)=>E(a,b,c,d) where enc(a,b,c,d)="T["++intercalate "," [enc a,enc b,enc c,enc d]++"]"\n'
    )
    return "".join(out)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--library", required=True)
    args = parser.parse_args()
    os.environ["HMATH_LIBRARY"] = str(Path(args.library).resolve())
    os.environ["HMATH_BACKEND"] = "pure"
    sys.path.insert(0, str(ROOT / "bindings/python"))
    import hmath

    entries, types, fields, _missing = signatures()
    modules = {
        m: importlib.import_module("_hmath_native." + ns)
        for m, (_alias, ns) in MODULES.items()
    }
    fixtures = []
    expressions = []
    owners = []
    for entry in entries:
        for dtype, precision in (
            [("float32", 32), ("float64", 64)]
            if generic_entry(entry)
            else [("float64", 64)]
        ):
            factory = Fixtures(modules, types, dtype)
            arguments = []
            hsargs = []
            specs = entry["args"]
            if entry["name"] == "fixedVector":
                specs = [["Int"], ["list", ["a"]]]
            try:
                for index, spec in enumerate(specs):
                    value, expression = factory.argument(spec, entry["name"], index)
                    arguments.append(value)
                    hsargs.append(expression)
            except BaseException:
                for owner in factory.owned:
                    owner.close()
                raise
            name = (
                entry["name"]
                if entry["constructor"] and entry["name"] in types
                else snake(entry["name"])
            )
            function = getattr(modules[entry["module"]], name)
            expression = (
                MODULES[entry["module"]][0]
                + "."
                + entry["name"]
                + " "
                + " ".join("(" + x + ")" for x in hsargs)
            )
            if entry["name"] == "fixedVector":
                expression = "V.fixedVector @2 (" + hsargs[1] + ")"
            signature = factory.type(entry["result"])
            expression = "(" + expression + " :: " + signature + ")"
            if entry["name"] == "fixedVector":
                expression = (
                    "(V.fixedVector @2 ("
                    + hsargs[1]
                    + ") :: Either EError.MathError(V.FixedVector 2 ("
                    + factory.hstype
                    + ")))"
                )
            if entry["name"] == "fixedValues":
                signature = None
            result_spec = entry["result"]
            if result_spec[0] == "IO":
                expression = (
                    expression
                    + " >>= putStrLn . "
                    + ("ok" if result_spec[1][0] == "Either" else "enc")
                )
            else:
                expression = (
                    "putStrLn ("
                    + ("ok" if result_spec[0] == "Either" else "enc")
                    + " "
                    + expression
                    + ")"
                )
            fixtures.append(
                (
                    function,
                    arguments,
                    {"dtype": dtype} if generic_entry(entry) else {},
                    precision,
                    entry["module"] + "." + entry["name"],
                )
            )
            expressions.append(expression)
            owners.extend(factory.owned)
    try:
        imports = (
            "import System.IO (hSetBuffering,stdout,stderr,BufferMode(..),hPutStrLn)\nimport Data.Char(ord)\nimport qualified HMath.Error as EError\nimport qualified HMath.Error as E\nimport qualified HMath.Matrix.LU as LU\nimport qualified HMath.Matrix.QR as QR\n"
            + "".join(
                "import qualified " + m + " as " + a + "\n"
                for m, (a, _ns) in MODULES.items()
            )
        )
        source = HASKELL.replace(
            "import Data.Complex", imports + "import Data.Complex"
        ).split("main=mapM_ putStrLn")[0]
        source = (
            "{-# LANGUAGE DataKinds #-}\n{-# LANGUAGE TypeApplications #-}\n"
            + source
            + oracle_instances(types, fields, entries)
            + "\nmain=do\n    hSetBuffering stdout LineBuffering\n    hSetBuffering stderr LineBuffering\n    sequence_\n        [ "
            + "\n        , ".join(
                '(hPutStrLn stderr "'
                + str(i)
                + " "
                + fixtures[i][-1]
                + '") >> ('
                + expression
                + ")"
                for i, expression in enumerate(expressions)
            )
            + "\n        ]\n"
        )
        with tempfile.TemporaryDirectory(prefix="hmath-linear-oracle-") as directory:
            path = Path(directory) / "Main.hs"
            path.write_text(source)
            shim = Path(directory) / "libhmath_oracle_backend.so"
            subprocess.run(
                [
                    "cc",
                    "-shared",
                    "-fPIC",
                    "-std=c11",
                    "-Iinclude",
                    "cbits/backend.c",
                    "-ldl",
                    "-lm",
                    "-o",
                    str(shim),
                ],
                cwd=ROOT,
                check=True,
                capture_output=True,
            )
            result = subprocess.run(
                [
                    "runghc",
                    "-isrc",
                    "-L" + directory,
                    "-lhmath_oracle_backend",
                    str(path),
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=False,
            )
            if result.returncode:
                Path("/tmp/hmath-linear-oracle-failed.hs").write_text(source)
                raise RuntimeError(result.stderr[-10000:])
            expected = result.stdout.splitlines()
        actual = []
        for function, arguments, kwargs, precision, name in fixtures:
            try:
                value = function(*arguments, **kwargs)
            except hmath.HMathError as error:
                actual.append("E" + str(error.math_error or error))
            else:
                try:
                    actual.append(
                        "N" if value is None else normalize(value, precision, modules)
                    )
                finally:
                    close(value)
        failures = [
            (fixtures[i][-1], expected[i], actual[i])
            for i in range(min(len(expected), len(actual)))
            if expected[i] != actual[i]
        ]
        if failures or len(expected) != len(actual):
            raise AssertionError(f"{len(failures)} mismatches: {failures[:15]}")
        print(
            f"Linear direct Haskell equivalence: {len(actual)} cases;270public operations/constructors,284source symbols"
        )
    finally:
        for owner in owners:
            owner.close()


if __name__ == "__main__":
    main()
