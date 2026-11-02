# SPDX-License-Identifier: MPL-2.0
"""Generate named adapters for the original Expression and Symbolic APIs."""

import argparse
import ast
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
S = []


def snake(name):
    return re.sub(
        r"([a-z0-9])([A-Z])", r"\1_\2", re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", name)
    ).lower()


def add(module, name, arguments, result, expression=None):
    S.append(
        {
            "module": "HMath." + module,
            "name": name,
            "arguments": arguments,
            "result": result,
            "expression": expression
            or ("E." if module == "Expression" else "S.") + name,
            "python": snake(name),
            "c": "hmath_"
            + snake(module)
            + "_"
            + snake(name)
            + ("_create" if name[0].isupper() else ""),
        }
    )


def e(name, args, result, expression=None):
    add("Expression", name, args, result, expression)


def s(name, args, result, expression=None):
    add("Symbolic", name, args, result, expression)


e("SourcePos", [("offset", "Int"), ("line", "Int"), ("column", "Int")], "SourcePos")
e("unknownPosition", [], "SourcePos")
for n in ["sourceOffset", "sourceLine", "sourceColumn"]:
    e(n, [("position", "SourcePos")], "Int")
for typ, names in {
    "UnaryOp": ["Negate"],
    "BinaryOp": ["Add", "Subtract", "Multiply", "Divide", "Power"],
    "NamedConstant": ["Pi", "Euler", "Tau"],
    "Precision": ["ExactRational", "Float64"],
    "ErrorKind": [
        "SyntaxError",
        "UnknownName",
        "TypeMismatch",
        "DomainFailure",
        "NonFinite",
        "StepLimit",
        "DepthLimit",
        "MemoryLimit",
        "InvalidLimits",
        "Unsupported",
    ],
    "Builtin": [
        "Sin",
        "Cos",
        "Tan",
        "Exp",
        "Log",
        "Sqrt",
        "Abs",
        "Signum",
        "Floor",
        "Ceiling",
        "Min",
        "Max",
        "Asin",
        "Acos",
        "Atan",
        "Sinh",
        "Cosh",
        "Tanh",
    ],
}.items():
    for name in names:
        e(name, [], typ)
e("Expr", [("position", "SourcePos"), ("node", "ExprNode")], "Expr")
e("expressionPosition", [("expression", "Expr")], "SourcePos")
e("expressionNode", [("expression", "Expr")], "ExprNode")
for name, args in [
    ("Literal", [("value", "Rational")]),
    ("Variable", [("name", "String")]),
    ("Constant", [("constant", "NamedConstant")]),
    ("Unary", [("operator", "UnaryOp"), ("child", "Expr")]),
    ("Binary", [("operator", "BinaryOp"), ("left", "Expr"), ("right", "Expr")]),
    ("Call", [("name", "String"), ("arguments", "[Expr]")]),
    ("Let", [("name", "String"), ("value", "Expr"), ("body", "Expr")]),
]:
    e(name, args, "ExprNode")
for name in ["literal", "variable", "constant", "unary", "binary", "call", "letIn"]:
    upper = {
        "literal": "Literal",
        "variable": "Variable",
        "constant": "Constant",
        "unary": "Unary",
        "binary": "Binary",
        "call": "Call",
        "letIn": "Let",
    }[name]
    spec = next(item for item in S if item["name"] == upper)
    e(name, spec["arguments"], "Expr")
limits = [
    ("maximum_steps", "Int"),
    ("maximum_depth", "Int"),
    ("maximum_nodes", "Int"),
    ("maximum_input_chars", "Int"),
    ("maximum_integer_bits", "Int"),
    ("maximum_cache_entries", "Int"),
]
e("Limits", limits, "Limits")
e("defaultLimits", [], "Limits")
for name in [
    "maximumSteps",
    "maximumDepth",
    "maximumNodes",
    "maximumInputChars",
    "maximumIntegerBits",
    "maximumCacheEntries",
]:
    e(name, [("limits", "Limits")], "Int")
e(
    "ExprError",
    [("kind", "ErrorKind"), ("position", "SourcePos"), ("message", "String")],
    "ExprError",
)
for name, out in [
    ("errorKind", "ErrorKind"),
    ("errorPosition", "SourcePos"),
    ("errorMessage", "String"),
]:
    e(name, [("error", "ExprError")], out)
e("validateLimits", [("limits", "Limits")], "Unit")
e("validateExpression", [("limits", "Limits"), ("expression", "Expr")], "Unit")
e("parseExpression", [("limits", "Limits"), ("source", "String")], "Expr")
e("prettyExpression", [("expression", "Expr")], "String")
e("freeVariables", [("expression", "Expr")], "[String]")
e("ExactValue", [("value", "Rational")], "ExpressionValue")
e("FloatValue", [("value", "Double")], "ExpressionValue")
e("defaultRegistry", [], "Registry")
e("emptyRegistry", [], "Registry")
e(
    "registerFunction",
    [("name", "String"), ("builtin", "Builtin"), ("registry", "Registry")],
    "Registry",
)
e("allowedFunctions", [("registry", "Registry")], "[String]")
for name, last, out in [
    ("typeCheckExpression", ("expression", "Expr"), "Precision"),
    ("evaluateExpression", ("expression", "Expr"), "ExpressionValue"),
    ("evaluateText", ("source", "String"), "ExpressionValue"),
    ("evaluateCompiled", ("compiled", "Compiled"), "ExpressionValue"),
]:
    e(
        name,
        [
            ("limits", "Limits"),
            ("precision", "Precision"),
            ("registry", "Registry"),
            ("bindings", "Bindings"),
            last,
        ],
        out,
    )
e("compileExpression", [("limits", "Limits"), ("expression", "Expr")], "Compiled")
e("compiledNodeCount", [("compiled", "Compiled")], "Int")
e(
    "optimizeExpression",
    [("limits", "Limits"), ("precision", "Precision"), ("expression", "Expr")],
    "Expr",
)
e("emptyExpressionCache", [], "ExpressionCache")
e("cacheSize", [("cache", "ExpressionCache")], "Int")
e(
    "cachedExpression",
    [("limits", "Limits"), ("source", "String"), ("cache", "ExpressionCache")],
    "(Compiled,ExpressionCache)",
)
e("formatScientific", [("digits", "Int"), ("value", "ExpressionValue")], "String")
e("formatRadix", [("radix", "Int"), ("value", "ExpressionValue")], "String")
e("serializeExpression", [("limits", "Limits"), ("expression", "Expr")], "String")
e("deserializeExpression", [("limits", "Limits"), ("serialized", "String")], "Expr")
e("expressionHash", [("limits", "Limits"), ("expression", "Expr")], "Word64")
for typ, names in {
    "Property": [
        "Real",
        "NonZero",
        "Positive",
        "NonNegative",
        "Integral",
        "Negative",
        "NonPositive",
    ],
    "Direction": ["FromLeft", "FromRight", "TwoSided"],
    "RelationOp": ["Equal", "NotEqual", "Less", "LessEqual", "Greater", "GreaterEqual"],
}.items():
    for name in names:
        s(name, [], typ)
s("assumptions", [("entries", "[(String,[Property])]")], "Assumptions")
s("noAssumptions", [], "Assumptions")
s(
    "proves",
    [("assumptions", "Assumptions"), ("property", "Property"), ("expression", "Expr")],
    "Bool",
)
s(
    "SymbolicOptions",
    [("limits", "Limits"), ("assumptions", "Assumptions")],
    "SymbolicOptions",
)
s("defaultSymbolicOptions", [], "SymbolicOptions")
s("symbolicLimits", [("options", "SymbolicOptions")], "Limits")
s("symbolicAssumptions", [("options", "SymbolicOptions")], "Assumptions")
for name in [
    "normalize",
    "simplify",
    "expand",
    "collectTerms",
    "trigonometricSimplify",
    "logarithmicSimplify",
]:
    s(name, [("options", "SymbolicOptions"), ("expression", "Expr")], "Expr")
for name, out in [
    ("factorPolynomial", "PolynomialFactorization"),
    ("rationalSimplify", "Expr"),
    ("differentiate", "Expr"),
    ("integrateBasic", "Expr"),
    ("toPolynomial", "Polynomial"),
    ("exactPolynomialRoots", "([(Rational,Int)],Expr)"),
    ("numericalPolynomialRoots", "[Complex]"),
]:
    s(
        name,
        [
            ("options", "SymbolicOptions"),
            ("variable", "String"),
            ("expression", "Expr"),
        ],
        out,
    )
s(
    "PolynomialFactorization",
    [("leading", "Rational"), ("terms", "[(Expr,Int)]")],
    "PolynomialFactorization",
)
s("factorLeading", [("factorization", "PolynomialFactorization")], "Rational")
s("factorTerms", [("factorization", "PolynomialFactorization")], "[(Expr,Int)]")
s(
    "substitute",
    [("limits", "Limits"), ("bindings", "[(String,Expr)]"), ("expression", "Expr")],
    "Expr",
)
for name, args in [
    ("Any", [("name", "String")]),
    ("Exactly", [("expression", "Expr")]),
    ("UnaryPattern", [("operator", "UnaryOp"), ("child", "Pattern")]),
    (
        "BinaryPattern",
        [("operator", "BinaryOp"), ("left", "Pattern"), ("right", "Pattern")],
    ),
    ("CallPattern", [("name", "String"), ("arguments", "[Pattern]")]),
]:
    s(name, args, "Pattern")
s(
    "matchPattern",
    [("limits", "Limits"), ("pattern", "Pattern"), ("expression", "Expr")],
    "Maybe[(String,Expr)]",
)
s(
    "RewriteRule",
    [
        ("pattern", "Pattern"),
        ("replacement", "Expr"),
        ("requirements", "[(String,Property)]"),
    ],
    "RewriteRule",
)
for name, out in [
    ("rewritePattern", "Pattern"),
    ("rewriteReplacement", "Expr"),
    ("rewriteRequirements", "[(String,Property)]"),
]:
    s(name, [("rule", "RewriteRule")], out)
s(
    "applyRewrite",
    [("options", "SymbolicOptions"), ("rule", "RewriteRule"), ("expression", "Expr")],
    "Expr",
)
for name, last, out in [
    ("gradient", "Expr", "[Expr]"),
    ("hessian", "Expr", "[[Expr]]"),
    ("jacobian", "[Expr]", "[[Expr]]"),
]:
    s(
        name,
        [
            ("options", "SymbolicOptions"),
            ("variables", "[String]"),
            ("expression" if last == "Expr" else "expressions", last),
        ],
        out,
    )
s(
    "integrateByParts",
    [
        ("options", "SymbolicOptions"),
        ("variable", "String"),
        ("u", "Expr"),
        ("dv", "Expr"),
    ],
    "Expr",
)
s(
    "integrateSubstitution",
    [
        ("options", "SymbolicOptions"),
        ("variable", "String"),
        ("temporary", "String"),
        ("inner", "Expr"),
        ("outer", "Expr"),
        ("integrand", "Expr"),
    ],
    "Expr",
)
s(
    "integrateRational",
    [
        ("options", "SymbolicOptions"),
        ("variable", "String"),
        ("numerator", "Expr"),
        ("denominator", "Expr"),
    ],
    "Expr",
)
s("FiniteLimit", [("value", "Rational")], "LimitResult")
for name in ["PositiveInfinity", "NegativeInfinity", "DoesNotExist"]:
    s(name, [], "LimitResult")
s(
    "symbolicLimit",
    [
        ("options", "SymbolicOptions"),
        ("variable", "String"),
        ("center", "Rational"),
        ("direction", "Direction"),
        ("expression", "Expr"),
    ],
    "LimitResult",
)
s(
    "Series",
    [("center", "Rational"), ("minimum_power", "Int"), ("terms", "[Expr]")],
    "Series",
)
for name, out in [
    ("seriesCenter", "Rational"),
    ("seriesMinimumPower", "Int"),
    ("seriesTerms", "[Expr]"),
]:
    s(name, [("series", "Series")], out)
for name in ["taylorSeries", "laurentSeries"]:
    s(
        name,
        [
            ("options", "SymbolicOptions"),
            ("variable", "String"),
            ("center", "Rational"),
            ("order", "Int"),
            ("expression", "Expr"),
        ],
        "Series",
    )
s(
    "maclaurinSeries",
    [
        ("options", "SymbolicOptions"),
        ("variable", "String"),
        ("order", "Int"),
        ("expression", "Expr"),
    ],
    "Series",
)
s(
    "formalPowerSeries",
    [("options", "SymbolicOptions"), ("coefficients", "[Rational]")],
    "PowerSeries",
)
s(
    "multiplyFormalSeries",
    [("options", "SymbolicOptions"), ("left", "PowerSeries"), ("right", "PowerSeries")],
    "PowerSeries",
)
s(
    "reciprocalFormalSeries",
    [("options", "SymbolicOptions"), ("series", "PowerSeries")],
    "PowerSeries",
)
s("fromPolynomial", [("variable", "String"), ("polynomial", "Polynomial")], "Expr")
s(
    "Relation",
    [("operator", "RelationOp"), ("left", "Expr"), ("right", "Expr")],
    "Relation",
)
s("Truth", [("value", "Bool")], "RelationResult")
s("Unresolved", [("relation", "Relation")], "RelationResult")
s(
    "simplifyRelation",
    [("options", "SymbolicOptions"), ("relation", "Relation")],
    "RelationResult",
)
s(
    "solveLinearInequality",
    [("options", "SymbolicOptions"), ("variable", "String"), ("relation", "Relation")],
    "RelationResult",
)
s("Inconsistent", [], "LinearSolution")
s(
    "ParametricSolution",
    [("bindings", "[(String,Expr)]"), ("free_variables", "[String]")],
    "LinearSolution",
)
s(
    "solveLinearEquations",
    [
        ("options", "SymbolicOptions"),
        ("variables", "[String]"),
        ("equations", "[(Expr,Expr)]"),
    ],
    "LinearSolution",
)
s(
    "symbolicMatrix",
    [("options", "SymbolicOptions"), ("rows", "[[Expr]]")],
    "SymbolicMatrix",
)
s("matrixExpressions", [("matrix", "SymbolicMatrix")], "[[Expr]]")
for name in ["matrixAdd", "matrixMultiply"]:
    s(
        name,
        [
            ("options", "SymbolicOptions"),
            ("left", "SymbolicMatrix"),
            ("right", "SymbolicMatrix"),
        ],
        "SymbolicMatrix",
    )
s(
    "symbolicDeterminant",
    [("options", "SymbolicOptions"), ("matrix", "SymbolicMatrix")],
    "Expr",
)
s(
    "Guarded",
    [("value", "Generic"), ("conditions", "[(Expr,Property)]")],
    "Guarded",
    "(S.Guarded :: Value -> [(E.Expr,S.Property)] -> S.Guarded Value)",
)
s(
    "guardedValue",
    [("guarded", "Guarded")],
    "Generic",
    "(S.guardedValue :: S.Guarded Value -> Value)",
)
s(
    "requiredConditions",
    [("guarded", "Guarded")],
    "[(Expr,Property)]",
    "(S.requiredConditions :: S.Guarded Value -> [(E.Expr,S.Property)])",
)
s(
    "symbolicEigenvalues",
    [("options", "SymbolicOptions"), ("matrix", "SymbolicMatrix")],
    "Guarded[Expr]",
)
s(
    "numericalSubstitution",
    [
        ("options", "SymbolicOptions"),
        ("precision", "Precision"),
        ("bindings", "[(String,ExpressionValue)]"),
        ("expression", "Expr"),
    ],
    "ExpressionValue",
)
for name in ["toLaTeX", "toMathML"]:
    s(name, [("limits", "Limits"), ("expression", "Expr")], "String")


for _entry in S:
    if _entry["name"] == "errorKind":
        _entry["c"] += "_get"


def outputs():
    catalog = json.dumps({"schema": 1, "functions": S}, indent=2) + "\n"
    python = (
        "# SPDX-License-Identifier: MPL-2.0\n# Generated by tools/generate_expression_bindings.py.\nimport json\nCATALOG = json.loads("
        + repr(json.dumps(S, separators=(",", ":")))
        + ")\n"
    )
    native = []
    header = []
    dispatch = []
    for entry in S:
        arguments = (
            ["hmath_context *context"]
            + [
                "const hmath_value *" + (p + "_" if p == "operator" else p)
                for p, _ in entry["arguments"]
            ]
            + ["hmath_value **out"]
        )
        signature = "hmath_status " + entry["c"] + "(" + ", ".join(arguments) + ")"
        header.append(
            "/* "
            + entry["module"]
            + "."
            + entry["name"]
            + " -> "
            + entry["result"]
            + ". */\nHMATH_API "
            + signature
            + ";\n"
        )
        names = [p + "_" if p == "operator" else p for p, _ in entry["arguments"]]
        native.append(
            signature
            + " {\n"
            + (
                "    const hmath_value *hm_arguments[] = {" + ", ".join(names) + "};\n"
                if names
                else ""
            )
            + '    return invoke(context, "'
            + entry["module"]
            + "."
            + entry["name"]
            + '", '
            + ("hm_arguments" if names else "NULL")
            + ", "
            + str(len(names))
            + ", out);\n}\n"
        )
        dispatch.append(
            '    "'
            + entry["module"]
            + "."
            + entry["name"]
            + '" -> apply '
            + entry["expression"]
            + " arguments\n"
        )
    files = {
        ROOT / "bindings/schema/expression.json": catalog,
        ROOT / "bindings/python/_hmath_native/_expression_catalog.py": python,
    }
    for path, mark, end, section in [
        (
            ROOT / "cbits/expression.c",
            "/* BEGIN GENERATED */",
            "/* END GENERATED */",
            "\n".join(native),
        ),
        (
            ROOT / "include/hmath_expression.h",
            "/* BEGIN GENERATED */",
            "/* END GENERATED */",
            "\n".join(header),
        ),
        (
            ROOT / "src/HMath/FFI/Expression.hs",
            "-- BEGIN GENERATED",
            "-- END GENERATED",
            "".join(dispatch),
        ),
    ]:
        text = path.read_text()
        a = text.index(mark) + len(mark)
        b = text.index(end)
        files[path] = text[:a] + "\n" + section + text[b:]
    enums = {
        "UnaryOp",
        "BinaryOp",
        "NamedConstant",
        "Precision",
        "Builtin",
        "ErrorKind",
        "Property",
        "Direction",
        "RelationOp",
    }
    records = {
        "SourcePos",
        "Expr",
        "Limits",
        "ExprError",
        "ExactValue",
        "FloatValue",
        "SymbolicOptions",
        "PolynomialFactorization",
        "RewriteRule",
        "Series",
        "Relation",
        "Guarded",
    }
    tails = []
    exports = {
        "Expression": {
            "ExprNode",
            "Bindings",
            "Value",
            "Registry",
            "Compiled",
            "ExpressionCache",
            *enums.intersection(
                {
                    "UnaryOp",
                    "BinaryOp",
                    "NamedConstant",
                    "Precision",
                    "Builtin",
                    "ErrorKind",
                }
            ),
        },
        "Symbolic": {
            "Pattern",
            "Assumptions",
            "SymbolicMatrix",
            "LimitResult",
            "RelationResult",
            "LinearSolution",
            "Property",
            "Direction",
            "RelationOp",
        },
    }
    for entry in S:
        name = entry["name"]
        module = entry["module"].split(".")[-1]
        public = name if name[0].isupper() else entry["python"]
        exports[module].add(public)
        if name in records:
            continue
        if name[0].isupper() and entry["result"] in enums:
            tails.append(
                public + " = " + entry["result"] + "." + snake(name).upper() + "\n"
            )
            continue
        if name in [
            "PositiveInfinity",
            "NegativeInfinity",
            "DoesNotExist",
            "Inconsistent",
        ]:
            tails.append(public + " = " + entry["result"] + "(" + repr(name) + ")\n")
            continue
        params = ", ".join(param for param, _ in entry["arguments"])
        if name in ["FiniteLimit", "Truth", "Unresolved", "ParametricSolution"]:
            tupleargs = (
                "(" + params + ("," if len(entry["arguments"]) == 1 else "") + ")"
            )
            body = entry["result"] + "(" + repr(name) + "," + tupleargs + ")"
        else:
            body = (
                "_invoke("
                + repr(entry["module"] + "." + name)
                + (", " + params if params else "")
                + ")"
            )
        tails.append(
            "def "
            + public
            + "("
            + params
            + '):\n    """'
            + entry["module"]
            + "."
            + name
            + ': original semantics and checked errors."""\n    return '
            + body
            + "\n"
        )
    path = ROOT / "bindings/python/_hmath_native/_expression_base.py"
    text = path.read_text()
    a = text.index("# BEGIN GENERATED") + len("# BEGIN GENERATED")
    b = text.index("# END GENERATED")
    files[path] = text[:a] + "\n" + "\n".join(tails) + text[b:]
    for module, public in exports.items():
        extra = "from .expression import *\n" if module == "Symbolic" else ""
        files[ROOT / ("bindings/python/_hmath_native/" + module.lower() + ".py")] = (
            '# SPDX-License-Identifier: MPL-2.0\n"""Original HMath.'
            + module
            + ' public API."""\n'
            + "from ._expression_base import (\n"
            + "".join(
                "    " + name + ",\n"
                for name in sorted(
                    public, key=lambda name: (name[0].islower(), name.casefold())
                )
            )
            + ")\n"
            + extra
            + "\n__all__ = "
            + repr(
                sorted(
                    public | (exports["Expression"] if module == "Symbolic" else set()),
                )
            )
            + "\n"
        )
    return files


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    for path, text in outputs().items():
        if args.check:
            if (
                (ast.dump(ast.parse(path.read_text())) != ast.dump(ast.parse(text)))
                if path.suffix == ".py"
                else (path.read_text() != text)
            ):
                raise SystemExit(str(path.relative_to(ROOT)) + " is stale")
        else:
            path.write_text(text)
    print(
        f"Expression/Symbolic: {len(S)} named original constructor/function/selector dispatches."
    )


if __name__ == "__main__":
    main()
