# SPDX-License-Identifier: MPL-2.0
"""Regression tests for documentation checks; no native runtime is required."""

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import check_api_docs as api
import check_docs_examples as examples


class ReferenceChecks(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.page = Path(self.directory.name) / "reference.md"
        self.name = "hmath.example"
        self.signature = "hmath.example(value, copy=True)"
        self.parameters = {self.name: ["value", "copy"]}
        self.signatures = {self.name: self.signature}
        self.defaults = {self.name: {"copy": "True"}}
        self.document = '''### `hmath.example(value, copy=True)`

<a id="hmath.example"></a>

Return an example value.

#### Parameters

| Name | Type / default | Description |
| --- | --- | --- |
| `value` | `float` | Input. |
| `copy` | `bool; default True` | Copy policy. |

#### Returns

`float`.

#### See Also

Related operations.

#### Notes

Example contract.

#### Examples

```python
assert 1 + 1 == 2
```
'''

    def check(self, document=None, kind="callable"):
        self.page.write_text(self.document if document is None else document)
        return api.check_entries(
            {self.name}, self.page, r"### `(hmath\.[\w.]+)",
            self.parameters, self.signatures, self.defaults,
            kinds={self.name: kind},
        )

    def test_callable(self):
        self.assertEqual(self.check(), 1)

    def test_missing_entry(self):
        with self.assertRaisesRegex(ValueError, "missing entries"):
            self.check("")

    def test_duplicate_entry(self):
        with self.assertRaisesRegex(ValueError, "duplicate entry"):
            self.check(self.document * 2)

    def test_unknown_entry(self):
        with self.assertRaisesRegex(ValueError, "unknown Python entries"):
            self.check(self.document + "\n### `hmath.unknown()`\n")

    def test_wrong_parameter_order(self):
        self.parameters[self.name].reverse()
        with self.assertRaisesRegex(ValueError, "parameter names/order"):
            self.check()

    def test_wrong_default(self):
        with self.assertRaisesRegex(ValueError, "default True"):
            self.check(self.document.replace("default True", "default False"))

    def test_wrong_heading_not_rescued_by_body(self):
        document = self.document.replace(self.signature, "hmath.example(value)")
        document += "\n" + self.signature + "\n"
        with self.assertRaisesRegex(ValueError, "signature differs"):
            self.check(document)

    def test_missing_anchor(self):
        with self.assertRaisesRegex(ValueError, "stable symbol anchor"):
            self.check(self.document.replace('<a id="hmath.example"></a>', ""))

    def test_out_of_order_sections(self):
        document = self.document.replace("#### Notes", "#### References")
        document = document.replace("#### Examples", "#### Notes")
        with self.assertRaisesRegex(ValueError, "out of order"):
            self.check(document)

    def test_duplicate_section(self):
        with self.assertRaisesRegex(ValueError, "duplicate sections"):
            self.check(self.document + "\n#### Notes\n\nRepeated.\n")

    def test_class_without_returns(self):
        document = self.document.replace("#### Returns", "#### Attributes")
        self.assertEqual(self.check(document, kind="class"), 1)

    def test_class_rejects_returns(self):
        document = self.document.replace(
            "#### See Also", "#### Attributes\n\n`value` : float\n\n#### See Also"
        )
        with self.assertRaisesRegex(ValueError, "not a callable result"):
            self.check(document, kind="class")

    def test_attribute_without_call_parentheses(self):
        self.parameters[self.name] = []
        self.signatures[self.name] = self.name
        self.defaults[self.name] = {}
        document = '''### `hmath.example`

<a id="hmath.example"></a>

Read a value.

#### Type

`float`.

#### See Also

Other attributes.
'''
        self.assertEqual(self.check(document, kind="attribute"), 1)
        with self.assertRaisesRegex(ValueError, "signature differs"):
            self.check(
                document.replace("`hmath.example`", "`hmath.example()`"), kind="attribute"
            )

    def test_legacy_c_wave_format_is_preserved(self):
        self.page.write_text(self.document.replace("#### See Also", "#### See also"))
        self.assertEqual(
            api.check_entries(
                {self.name}, self.page, r"### `(hmath\.[\w.]+)",
                self.parameters, self.signatures, self.defaults,
            ), 1,
        )

    def test_source_inventory_includes_attributes(self):
        kinds = api.python_kinds()
        for name in api.PYTHON_ATTRIBUTES:
            self.assertEqual(kinds[name], "attribute")
        self.assertEqual(kinds["hmath.Tensor"], "class")
        self.assertEqual(kinds["hmath.Tensor.shape"], "attribute")
        self.assertEqual(kinds["hmath.Tensor.dot"], "callable")
        self.assertNotIn("hmath.threading", kinds)
        self.assertNotIn("hmath.Tensor._live", kinds)

    def test_actual_python_reference(self):
        self.assertGreater(api.check_reference(python_only=True)["Python"], 0)


class ExampleChecks(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.page = Path(self.directory.name) / "examples.md"

    def check(self, text, **kwargs):
        self.page.write_text(text)
        return examples.check_page(self.page, **kwargs)

    def test_tutorial_keeps_page_namespace(self):
        text = "```python\nx = 3\n```\n\n```python\nassert x == 3\n```\n"
        self.assertEqual(self.check(text), 2)

    def test_inline_marker_does_not_change_tutorial_mode(self):
        text = "Describe `" + examples.INDEPENDENT + "` here.\n"
        text += "```python\nx = 3\n```\n```python\nassert x == 3\n```\n"
        self.assertEqual(self.check(text), 2)

    def test_reference_blocks_have_no_hidden_imports(self):
        text = examples.INDEPENDENT + "\n"
        text += "```python\nx = 3\n```\n```python\nassert x == 3\n```\n"
        with self.assertRaisesRegex(RuntimeError, "NameError"):
            self.check(text)

    def test_reference_blocks_have_separate_processes(self):
        text = examples.INDEPENDENT + '''
```python
import builtins
builtins.hmath_example_sentinel = True
```
```python
import builtins
assert not hasattr(builtins, "hmath_example_sentinel")
```
'''
        self.assertEqual(self.check(text), 2)

    def test_syntax_only_does_not_import_native_library(self):
        text = "```python\nimport nonexistent_documentation_test_module\n```\n"
        self.assertEqual(self.check(text, syntax_only=True), 1)
        with self.assertRaisesRegex(RuntimeError, "ModuleNotFoundError"):
            self.check(text)

    def test_failure_includes_markdown_location(self):
        with self.assertRaisesRegex(RuntimeError, r"examples\.md:4"):
            self.check("# Title\n\n```python\nassert False\n```\n")

    def test_syntax_error_uses_markdown_line(self):
        with self.assertRaises(SyntaxError) as caught:
            self.check("# Title\n\n```python\nif:\n```\n", syntax_only=True)
        self.assertEqual(caught.exception.lineno, 4)

    def test_timeout(self):
        with self.assertRaisesRegex(RuntimeError, "exceeded"):
            self.check("```python\nimport time\ntime.sleep(5)\n```\n", timeout=0.05)

    def test_early_success_exit_is_not_a_pass(self):
        with self.assertRaisesRegex(RuntimeError, "example failed"):
            self.check("```python\nraise SystemExit(0)\n```\n")

    def test_unclosed_fence(self):
        with self.assertRaisesRegex(ValueError, "unclosed Python"):
            self.check("```python\nassert True\n", syntax_only=True)

    def test_installed_version_mismatch(self):
        with patch.object(examples.importlib.metadata, "version", return_value="0.0.0"):
            with self.assertRaisesRegex(ValueError, "Expected hmath-python 1.0.2"):
                examples.check_installed_version("1.0.2")

    def test_installed_version_match(self):
        with patch.object(examples.importlib.metadata, "version", return_value="1.0.2"):
            examples.check_installed_version("1.0.2")


if __name__ == "__main__":
    unittest.main()
