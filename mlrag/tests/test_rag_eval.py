"""RAG retrieval-evaluation tests (GATE 7). Standard library only.

Metric math uses hand-computed fixtures; parser tests use labeled
mini-SQL strings.  Nothing here touches a database or presents fixture
numbers as corpus evidence.

Run: python -m unittest mlrag.tests.test_rag_eval -v
"""

from __future__ import annotations

import unittest

from mlrag.rag import evaluate as metrics
from mlrag.rag import retrieval, seed_parse

FIX = "eval-fixture"


def corpus() -> list:
    from mlrag.rag.documents import RagDocument
    texts = {
        "a": "photosynthesis light energy leaves",
        "b": "photosynthesis carbon fixation roots",
        "c": "mitosis cell division stages",
    }
    return [RagDocument(
        doc_id=f"lessons:{FIX}-{key}#c0", source_table="lessons",
        source_id=f"{FIX}-{key}", text=text, subject_id=f"{FIX}-s",
        topic_id=f"{FIX}-t", is_active=True,
        content_version="v1") for key, text in texts.items()]


class MetricMathTest(unittest.TestCase):
    """Areas 1-4: recall/precision/MRR math + invalid behavior."""

    def test_recall_at_k(self):
        self.assertAlmostEqual(
            metrics.recall_at_k(["a", "b", "c"], {"b", "c"}, 2), 0.5)
        self.assertAlmostEqual(
            metrics.recall_at_k(["a", "b", "c"], {"b", "c"}, 3), 1.0)

    def test_precision_at_k(self):
        self.assertAlmostEqual(
            metrics.precision_at_k(["a", "b", "c"], {"b"}, 2), 0.5)
        self.assertAlmostEqual(
            metrics.precision_at_k(["a"], {"a"}, 5), 0.2)

    def test_reciprocal_rank(self):
        self.assertAlmostEqual(
            metrics.reciprocal_rank(["a", "b"], {"b"}), 0.5)
        self.assertEqual(
            metrics.reciprocal_rank(["a"], {"zzz"}), 0.0)

    def test_empty_relevance_is_unavailable_not_zero(self):
        self.assertIsNone(metrics.recall_at_k(["a"], set(), 3))
        self.assertIsNone(metrics.precision_at_k(["a"], set(), 3))
        self.assertIsNone(metrics.reciprocal_rank(["a"], set()))

    def test_invalid_k_rejected(self):
        with self.assertRaises(ValueError):
            metrics.recall_at_k(["a"], {"a"}, 0)

    def test_mean_ignores_unavailable(self):
        self.assertAlmostEqual(
            metrics.mean_or_none([0.5, None, 1.0]), 0.75)
        self.assertIsNone(metrics.mean_or_none([None, None]))
        self.assertIsNone(metrics.mean_or_none([]))


class RankingDeterminismTest(unittest.TestCase):
    """Areas 5, 17: deterministic ranking on fixed inputs."""

    def test_identical_rankings(self):
        engine = retrieval.LexicalRetriever()
        first = engine.retrieve(
            retrieval.RagQuery(query="photosynthesis",
                               subject_id=f"{FIX}-s"),
            corpus(), request_id="q")
        second = engine.retrieve(
            retrieval.RagQuery(query="photosynthesis",
                               subject_id=f"{FIX}-s"),
            corpus(), request_id="q")
        self.assertEqual(first, second)
        self.assertTrue(first.served)
        self.assertEqual(first.chunks[0].chunk_id,
                         f"lessons:{FIX}-a#c0")


class ScopeEvalTest(unittest.TestCase):
    """Areas 6-10, 16: scope behavior inside evaluation."""

    def test_no_unscoped_leak_in_rankings(self):
        engine = retrieval.LexicalRetriever()
        response = engine.retrieve(
            retrieval.RagQuery(query="photosynthesis",
                               subject_id="other-subject"),
            corpus(), request_id="q")
        self.assertFalse(response.served)
        self.assertEqual(response.chunks, ())

    def test_inactive_filtered_before_scoring(self):
        from mlrag.rag.documents import RagDocument
        hidden = RagDocument(
            doc_id=f"lessons:{FIX}-h#c0", source_table="lessons",
            source_id=f"{FIX}-h",
            text="photosynthesis photosynthesis photosynthesis",
            subject_id=f"{FIX}-s", topic_id=f"{FIX}-t",
            is_active=False, content_version="v1")
        response = retrieval.LexicalRetriever().retrieve(
            retrieval.RagQuery(query="photosynthesis",
                               subject_id=f"{FIX}-s"),
            [hidden], request_id="q")
        self.assertFalse(response.served)


class SeedParserTest(unittest.TestCase):
    """Parser correctness on labeled mini-SQL (never live data)."""

    MINI_SQL = (
        "-- a comment\n"
        "INSERT INTO questions (id, topic_id, question_text, difficulty, "
        "is_active, updated_at) "
        "SELECT 'q1', 't1', 'What is -- not a comment?', 'EASY', TRUE, "
        "CURRENT_TIMESTAMP FROM DUAL WHERE NOT EXISTS (SELECT 1);")

    VALUES_SQL = (
        "INSERT INTO topics (id, subject_id, name, is_active) VALUES "
        "('t1', 's1', 'It''s here', TRUE), ('t2', 's1', 'Plain', FALSE);")

    def test_select_line_with_comment_like_text(self):
        parsed = seed_parse.parse_seed_sql(self.MINI_SQL)
        row = parsed["questions"][0]
        self.assertEqual(row["question_text"], "What is -- not a comment?")
        self.assertIs(row["is_active"], True)
        self.assertIsNone(row["updated_at"])

    def test_values_tuples_with_escaped_quote(self):
        parsed = seed_parse.parse_seed_sql(self.VALUES_SQL)
        self.assertEqual(len(parsed["topics"]), 2)
        self.assertEqual(parsed["topics"][0]["name"], "It's here")
        self.assertIs(parsed["topics"][1]["is_active"], False)

    def test_unapproved_tables_ignored(self):
        parsed = seed_parse.parse_seed_sql(
            "INSERT INTO quiz_attempts (id) SELECT 'x' FROM DUAL;")
        self.assertEqual(parsed, {})

    def test_malformed_literal_fails_loudly(self):
        with self.assertRaises(ValueError):
            seed_parse.parse_seed_sql(
                "INSERT INTO topics (id) SELECT BOGUS_LITERAL FROM DUAL;")


class DuplicateUtilTest(unittest.TestCase):
    """Area 15: duplicate grouping helper behavior."""

    def test_normalization_groups(self):
        import re

        def normalize(text: str) -> str:
            return re.sub(r"\s+", " ", text.lower()).strip()

        self.assertEqual(normalize("  Photosynthesis\nLight "),
                         normalize("photosynthesis light"))


if __name__ == "__main__":
    unittest.main()
