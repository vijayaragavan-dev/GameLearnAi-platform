"""Gate 21: deterministic normalization and hashing."""

from __future__ import annotations

import unittest

from mlrag.corpus import normalize


class NormalizationTest(unittest.TestCase):
    def test_same_input_same_output(self):
        text = "  Halves make a whole.  \n\nQuarters too.  "
        self.assertEqual(normalize.normalize_text(text),
                         normalize.normalize_text(text))

    def test_line_endings_normalize(self):
        self.assertEqual(normalize.normalize_text("a\r\n\r\nb"),
                         normalize.normalize_text("a\n\nb"))

    def test_trailing_whitespace_stripped(self):
        # Trailing whitespace stripped per line; leading indentation is
        # preserved (may carry meaning in educational content).
        self.assertEqual(normalize.normalize_text("a   \n   b   "),
                         "a\n   b")

    def test_blank_runs_collapse(self):
        # Runs of 3+ blank lines collapse to exactly 2 blank lines.
        self.assertEqual(normalize.normalize_text("a\n\n\n\n\nb"),
                         "a\n\n\nb")
        self.assertEqual(normalize.normalize_text("a\n\n\n\nb"),
                         "a\n\n\nb")
        # A single paragraph break is untouched.
        self.assertEqual(normalize.normalize_text("a\n\nb"), "a\n\nb")

    def test_meaning_preserved(self):
        text = "Two halves make a whole."
        self.assertIn("Two halves make a whole.",
                      normalize.normalize_text(text))

    def test_unicode_nfc_safe(self):
        decomposed = "cafe\u0301"
        self.assertEqual(normalize.normalize_text(decomposed), "caf\u00e9")

    def test_hashes_distinguish_original_vs_normalized(self):
        raw = "  spaced\r\n\r\ntext  "
        norm = normalize.normalize_text(raw)
        self.assertNotEqual(
            normalize.sha256_hex(raw), normalize.sha256_hex(norm))
        self.assertEqual(len(normalize.sha256_hex(raw)), 64)

    def test_source_hash_stable_and_sensitive(self):
        fields = {"id": "x", "title": "T", "content": "C"}
        first = normalize.source_hash("lessons", fields)
        self.assertEqual(first, normalize.source_hash("lessons", fields))
        changed = normalize.source_hash(
            "lessons", {**fields, "content": "D"})
        self.assertNotEqual(first, changed)
        other_table = normalize.source_hash("topics", fields)
        self.assertNotEqual(first, other_table)


if __name__ == "__main__":
    unittest.main()
