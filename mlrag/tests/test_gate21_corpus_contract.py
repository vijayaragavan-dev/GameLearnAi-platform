"""Gate 21: corpus versions, extraction-query audit, chunk schema."""

from __future__ import annotations

import re
import unittest

from mlrag.corpus import contract
from mlrag.corpus.contract import (
    CHUNK_RECORD_KEYS,
    CHUNK_SOURCE_TABLES,
    CHUNK_VERSION,
    CORPUS_VERSION,
    DOCUMENT_VERSION,
    FORBIDDEN_COLUMNS,
    FORBIDDEN_SOURCE_TABLES,
    INGESTION_VERSION,
    validate_chunk_record,
)
from mlrag.rag import chunking, documents, extract_corpus

from . import gate21_fixtures as fx


class VersionPinTest(unittest.TestCase):
    def test_versions_pinned(self):
        self.assertEqual(CORPUS_VERSION, "c1")
        self.assertEqual(DOCUMENT_VERSION, "doc-v1")
        self.assertEqual(CHUNK_VERSION, "chunk-v1")
        self.assertEqual(INGESTION_VERSION, "ingest-v1")

    def test_chunk_policy_reused_not_redefined(self):
        self.assertEqual(chunking.DEFAULT_MAX_CHARS, 1500)
        self.assertEqual(documents.MAX_TEXT_CHARS, 8000)

    def test_chunk_sources(self):
        self.assertEqual(CHUNK_SOURCE_TABLES,
                         {"lessons", "topics", "questions"})
        self.assertIn("subjects", contract.SCOPE_SOURCE_TABLES)
        self.assertIn("units", contract.SCOPE_SOURCE_TABLES)


class ExtractionAuditTest(unittest.TestCase):
    def test_corpus_queries_select_only(self):
        for sql in extract_corpus.CORPUS_QUERIES:
            statement = sql.strip().rstrip(";").strip()
            self.assertTrue(statement.upper().startswith("SELECT"))
            self.assertNotIn(";", statement)
            upper = statement.upper()
            for keyword in ("INSERT", "UPDATE", "DELETE", "ALTER", "DROP",
                            "TRUNCATE", "CREATE", "REPLACE", "MERGE"):
                self.assertIsNone(
                    re.search(r"\b" + keyword + r"\b", upper),
                    f"{keyword} in corpus SQL")

    def test_no_learner_tables_queried(self):
        blob = "\n".join(extract_corpus.CORPUS_QUERIES).lower()
        for table in FORBIDDEN_SOURCE_TABLES:
            self.assertNotIn(table, blob, table)

    def test_no_forbidden_columns_selected(self):
        blob = "\n".join(extract_corpus.CORPUS_QUERIES)
        for column in FORBIDDEN_COLUMNS:
            self.assertIsNone(
                re.search(r"\b" + re.escape(column) + r"\b", blob,
                          re.IGNORECASE),
                column)

    def test_correct_answer_never_selected(self):
        blob = "\n".join(extract_corpus.CORPUS_QUERIES)
        self.assertNotIn("correct_answer", blob)


class ChunkSchemaTest(unittest.TestCase):
    def _record(self, **over):
        record = {
            "chunk_id": "lessons:abc#c0",
            "document_id": "lessons:abc",
            "source_table": "lessons",
            "source_id": "abc",
            "subject_id": "s1",
            "unit_id": "u1",
            "topic_id": "t1",
            "lesson_id": "abc",
            "question_id": None,
            "difficulty": "EASY",
            "content_version": "2026-01-01T00:00:00",
            "title": "T",
            "source_type": "CURATED",
            "is_active": True,
            "text": "Some text.",
            "text_hash": "h1",
            "source_hash": "h2",
            "corpus_version": "c1",
            "document_version": "doc-v1",
            "chunk_version": "chunk-v1",
            "ingestion_version": "ingest-v1",
            "citation": "lessons:abc#c0",
            "quarantine": {"status": "clean", "reason_codes": []},
            "scope": {"subject_id": "s1", "unit_id": "u1",
                      "topic_id": "t1", "lesson_id": "abc"},
        }
        record.update(over)
        return record

    def test_valid_record_passes(self):
        validate_chunk_record(self._record())

    def test_exact_key_set(self):
        self.assertEqual(len(CHUNK_RECORD_KEYS), 24)
        record = self._record()
        del record["citation"]
        with self.assertRaises(Exception):
            validate_chunk_record(record)

    def test_inactive_chunk_rejected(self):
        with self.assertRaises(Exception):
            validate_chunk_record(self._record(is_active=False))

    def test_scope_mismatch_rejected(self):
        record = self._record()
        record["scope"] = dict(record["scope"], topic_id="other")
        with self.assertRaises(Exception):
            validate_chunk_record(record)

    def test_quarantine_rules(self):
        with self.assertRaises(Exception):
            validate_chunk_record(self._record(quarantine={
                "status": "clean", "reason_codes": ["x"]}))
        with self.assertRaises(Exception):
            validate_chunk_record(self._record(quarantine={
                "status": "review_quarantined", "reason_codes": []}))

    def test_unapproved_source_rejected(self):
        with self.assertRaises(Exception):
            validate_chunk_record(self._record(source_table="quizzes"))


if __name__ == "__main__":
    unittest.main()
