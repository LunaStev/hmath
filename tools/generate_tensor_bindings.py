# SPDX-License-Identifier: MPL-2.0
"""Generate named C adapters for original generic Tensor and pinned mutable APIs."""

import argparse
import ast
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def snake(name):
    return re.sub(
        r"([a-z0-9])([A-Z])", r"\1_\2", re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", name)
    ).lower()


def specifications():
    source = (ROOT / "src/HMath/FFI/TensorAll.hs").read_text()
    result = []
    mutable = {
        "newMutable",
        "thawTensor",
        "freezeTensor",
        "mutableShape",
        "readMutable",
        "writeMutable",
        "modifyMutable",
        "sliceMutable",
        "transposeMutable",
        "mutableAlignment",
        "withMutableBuffer",
    }
    output = {
        name: "Tensor"
        for name in [
            "tensor",
            "tensorColumnMajor",
            "contiguous",
            "tensorZeros",
            "tensorOnes",
            "tensorFull",
            "tensorArange",
            "tensorLinspace",
            "tensorLogspace",
            "sliceTensor",
            "fancyIndex",
            "booleanIndex",
            "gather",
            "scatter",
            "scatterAdd",
            "reshapeTensor",
            "flattenTensor",
            "squeeze",
            "unsqueeze",
            "expand",
            "permute",
            "transposeTensor",
            "moveAxis",
            "swapAxes",
            "broadcastTo",
            "repeatTensor",
            "tile",
            "concatenate",
            "stack",
            "padTensor",
            "roll",
            "flipTensor",
            "rotate",
            "sortTensor",
            "argsort",
            "unique",
            "nonzero",
            "whereTensor",
            "maskedFill",
            "maskedSelect",
            "mapTensor",
            "zipTensor",
            "tensorAdd",
            "tensorSubtract",
            "tensorMultiply",
            "tensorDivide",
            "tensorEqual",
            "tensorLess",
            "tensorAnd",
            "tensorOr",
            "tensorNot",
            "promoteTensor",
            "sumAxes",
            "meanAxes",
            "productAxes",
            "minAxes",
            "maxAxes",
            "varianceAxes",
            "normAxes",
            "cumulativeSum",
            "cumulativeProduct",
            "tensordot",
            "einsum",
            "batchedMatmul",
            "tensorKronecker",
            "deserializeTensor",
            "evaluateGraph",
            "freezeTensor",
        ]
    }
    output.update(
        {
            "tensorRandom": "(Tensor,Integer)",
            "tensorValues": "Elements",
            "tensorShape": "[Int]",
            "tensorStrides": "[Int]",
            "tensorOffset": "Int",
            "tensorDType": "String",
            "tensorDevice": "Device",
            "tensorLayout": "Layout",
            "isContiguous": "Bool",
            "numel": "Int",
            "shapeSize": "Int",
            "inferBroadcast": "[Int]",
            "indexTensor": "Element",
            "splitTensor": "[Tensor]",
            "chunkTensor": "[Tensor]",
            "topk": "(Tensor,Tensor)",
            "argmin": "Int",
            "argmax": "Int",
            "serializeTensor": "String",
            "inputGraph": "TensorGraph",
            "mapGraph": "TensorGraph",
            "zipGraph": "TensorGraph",
            "newMutable": "MutableTensor",
            "thawTensor": "MutableTensor",
            "mutableShape": "[Int]",
            "readMutable": "Element",
            "writeMutable": "Unit",
            "modifyMutable": "Unit",
            "sliceMutable": "MutableTensor",
            "transposeMutable": "MutableTensor",
            "withMutableBuffer": "Generic",
            "mutableAlignment": "Int",
            "RowMajor": "Layout",
            "ColumnMajor": "Layout",
            "Strided": "Layout",
            "CPU": "Device",
        }
    )
    for name, arguments in re.findall(r'\("([^"]+)",\[(.*?)\]\)', source):
        if name.startswith("__"):
            continue
        names = arguments.split(",") if arguments else []
        hints = []
        for param in names:
            hint = {
                "kind": "Prototype",
                "shape": "[Int]",
                "axis": "Int",
                "start": "Element",
                "end": "Element",
                "step": "Element",
                "base": "Element",
                "count": "Int",
                "xs": "Elements",
                "seed": "Integer",
                "index": "[Int]",
                "indices": "[Int]",
                "axes": "[Int]",
                "from": "Int",
                "to": "Int",
                "counts": "[Int]",
                "segments": "[Int]",
                "padding": "[(Int,Int)]",
                "shift": "Int",
                "first": "Int",
                "second": "Int",
                "turns": "Int",
                "keep": "Bool",
                "leftAxes": "[Int]",
                "rightAxes": "[Int]",
                "labels": "[String]",
                "outputLabels": "String",
                "text": "String",
                "mask": "Tensor",
                "cb": "Callback",
                "fill": "Element",
                "input": "Tensor",
                "left": "Tensor",
                "right": "Tensor",
                "a": "Tensor",
                "b": "Tensor",
                "inputs": "[Tensor]",
            }.get(param, "Tensor")
            if param in {"start", "step"} and name in {"sliceTensor", "sliceMutable"}:
                hint = "Int"
            if param == "input" and name in {"mapGraph", "zipGraph", "evaluateGraph"}:
                hint = "TensorGraph"
            if param in {"left", "right"} and name == "zipGraph":
                hint = "TensorGraph"
            if param == "input" and name in mutable - {"thawTensor"}:
                hint = "MutableTensor"
            if param == "cb" and name == "withMutableBuffer":
                hint = "BufferCallback"
            hints.append(hint)
        assert name in output, name
        result.append(
            {
                "module": "HMath.Tensor.Mutable" if name in mutable else "HMath.Tensor",
                "name": name,
                "python": ("tensor_dtype" if name == "tensorDType" else snake(name)),
                "c": "hmath_tensor_object_"
                + snake(name)
                + ("_create" if name[0].isupper() else ""),
                "arguments": list(zip(names, hints)),
                "result": output[name],
            }
        )
    return result


def outputs():
    entries = specifications()
    outputs = {
        ROOT / "bindings/schema/tensor.json": json.dumps(
            {"schema": 1, "functions": entries}, indent=2
        )
        + "\n",
        ROOT
        / "bindings/python/_hmath_native/_tensor_catalog.py": "# SPDX-License-Identifier: MPL-2.0\n# Generated by tools/generate_tensor_bindings.py.\nimport json\nCATALOG = json.loads("
        + repr(json.dumps(entries, separators=(",", ":")))
        + ")\n",
    }
    declarations = []
    definitions = []
    for item in entries:
        names = [arg for arg, _ in item["arguments"]]
        cname = {
            "from": "from_axis",
            "to": "to_axis",
            "keep": "keep_dimensions",
            "input": "input_tensor",
            "kind": "element_type",
            "fill": "fill_value",
            "leftAxes": "left_axes",
            "rightAxes": "right_axes",
            "outputLabels": "output_labels",
        }
        parameters = (
            ["hmath_context *context"]
            + ["const hmath_value *" + cname.get(name, name) for name in names]
            + ["hmath_value **out"]
        )
        signature = (
            "hmath_status " + item["c"] + "(\n    " + ",\n    ".join(parameters) + ")"
        )
        declarations.append(
            "/* "
            + item["module"]
            + "."
            + item["name"]
            + " -> "
            + item["result"]
            + ". */\nHMATH_API "
            + signature
            + ";\n"
        )
        definitions.append(
            signature
            + " {\n"
            + (
                "    const hmath_value *hm_arguments[] = {"
                + ", ".join(cname.get(name, name) for name in names)
                + "};\n"
                if names
                else ""
            )
            + '    return invoke(context, "'
            + item["name"]
            + '", '
            + ("hm_arguments" if names else "NULL")
            + ", "
            + str(len(names))
            + ", out);\n}\n"
        )
    for path, section in [
        (ROOT / "include/hmath_tensor_bindings.h", "\n".join(declarations)),
        (ROOT / "cbits/tensor_bindings.c", "\n".join(definitions)),
    ]:
        text = path.read_text()
        a = text.index("/* BEGIN GENERATED */") + len("/* BEGIN GENERATED */")
        b = text.index("/* END GENERATED */")
        outputs[path] = text[:a] + "\n" + section + text[b:]
    manual = {
        "tensor",
        "tensor_column_major",
        "tensor_zeros",
        "tensor_ones",
        "tensor_full",
        "tensor_arange",
        "tensor_linspace",
        "tensor_logspace",
        "concatenate",
        "stack",
        "einsum",
        "promote_tensor",
        "deserialize_tensor",
        "map_tensor",
        "zip_tensor",
        "map_graph",
        "zip_graph",
        "new_mutable",
        "modify_mutable",
        "mutable_alignment",
        "with_mutable_buffer",
    }
    declarations = []
    public = {
        "Tensor",
        "TensorDouble",
        "TensorGraph",
        "MutableTensor",
        "BorrowedBuffer",
        "element_type",
        "Layout",
        "Device",
        "RowMajor",
        "ColumnMajor",
        "Strided",
        "CPU",
    }
    parameter_names = {
        "input": "tensor",
        "inputs": "tensors",
        "index": "coordinates",
        "cb": "function",
        "keep": "keep_dimensions",
        "from": "from_axis",
        "to": "to_axis",
        "leftAxes": "left_axes",
        "rightAxes": "right_axes",
        "outputLabels": "output_labels",
        "xs": "values",
        "fill": "value",
    }
    for item in entries:
        if item["name"][0].isupper():
            continue
        name = item["python"]
        if name not in {"shape_size", "infer_broadcast"}:
            public.add(name)
        if name in manual:
            continue
        parameters = [
            parameter_names.get(param, param) for param, _ in item["arguments"]
        ]
        declarations.append(
            "def "
            + name
            + "("
            + ", ".join(parameters)
            + '):\n    """'
            + item["module"]
            + "."
            + item["name"]
            + ': original dtype and failure conditions."""\n    return _invoke('
            + repr(item["name"])
            + (", " + ", ".join(parameters) if parameters else "")
            + ")\n"
        )
    path = ROOT / "bindings/python/_hmath_native/_tensor_core.py"
    text = path.read_text()
    a = text.index("# BEGIN GENERATED") + len("# BEGIN GENERATED")
    b = text.index("# END GENERATED")
    outputs[path] = (
        text[:a]
        + "\n"
        + "\n".join(declarations)
        + "\n__all__ = "
        + repr(sorted(public, key=lambda name: (not name.isupper(), name)))
        + "\n"
        + text[b:]
    )
    return outputs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    for path, text in outputs().items():
        if args.check:
            same = (
                ast.dump(ast.parse(path.read_text())) == ast.dump(ast.parse(text))
                if path.suffix == ".py"
                else path.read_text() == text
            )
            if not same:
                raise SystemExit(str(path.relative_to(ROOT)) + " is stale")
        else:
            path.write_text(text)
    print(
        f"Tensor catalog: {len(specifications())} named original functions/constructors."
    )


if __name__ == "__main__":
    main()
