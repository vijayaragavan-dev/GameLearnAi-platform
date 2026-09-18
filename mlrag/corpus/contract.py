"""Corpus contract for Gate 21 ingestion (versions, sources, schema).

Version dimensions (all pinned; any semantic change needs a new version):

* ``CORPUS_VERSION`` — the serving corpus layout produced here (``c1``).
* ``DOCUMENT_VERSION`` — the chunk-record schema below (``doc-v1``; named
  to avoid collision with the ML dataset ``d1``).
* ``CHUNK_VERSION`` — the chunking policy generation.  The policy itself
  (1500-char paragraph packing, sentence-aware long split, zero character
  loss) is REUSED from ``mlrag.rag.chunking`` unchanged, so this starts
  at ``chunk-v1`` referencing that exact policy.
* ``INGESTION_VERSION`` — this pipeline's code generation (``ingest-v1``).
* Per-source ``content_version`` (``updated_at`` ISO or ``"unversioned"``)
  is REUSED from the Gate 6 document contract unchanged.

Chunk sizes are NOT redefined here: ``MAX_TEXT_CHARS`` (8000) and
``DEFAULT_MAX_CHARS`` (1500) are imported from the existing modules —
single source of truth, no silent change.

Source policy (Gate 16 set, Gate 6 scope-label refinement kept):
retrievable chunks come ONLY from lessons / topics / questions.  Subjects
and units contribute scope labels + integrity validation, never chunks
(they carry no topic linkage, so they cannot satisfy the topic-scope
requirement).  Quizzes are assessment instruments, excluded deliberately.
"""

from __future__ import annotations

from ..contracts.common import ContractViolation
from ..rag.chunking import DEFAULT_MAX_CHARS
from ..rag.documents import MAX_TEXT_CHARS

#: Pinned versions for this gate.
CORPUS_VERSION = "c1"
DOCUMENT_VERSION = "doc-v1"
CHUNK_VERSION = "chunk-v1"
INGESTION_VERSION = "ingest-v1"

#: Tables that may yield retrievable chunks.
CHUNK_SOURCE_TABLES = frozenset({"lessons", "topics", "questions"})

#: Tables that contribute scope labels / integrity validation only.
SCOPE_SOURCE_TABLES = frozenset({"subjects", "units"})

#: Full approved educational source set (retriever contract vocabulary).
APPROVED_SOURCE_TABLES = CHUNK_SOURCE_TABLES | SCOPE_SOURCE_TABLES

#: Learner-state / secret tables that must never be corpus sources.
FORBIDDEN_SOURCE_TABLES = frozenset(
    {
        "users",
        "quiz_attempts",
        "question_attempts",
        "topic_mastery",
        "progress",
        "recommendations",
        "xp_transactions",
        "user_achievements",
        "achievements",
        "streaks",
        "game_results",
        "ai_interactions",
        "learner_profiles",
        "learning_paths",
        "learning_path_nodes",
        "credit_ledger",
        "user_credits",
        "avatars",
        "user_avatars",
    }
)

#: Columns/fields that must never be selected into, or appear in, corpus
#: records (learner answers, answer keys, secrets, PII, telemetry).
FORBIDDEN_COLUMNS = frozenset(
    {
        "email",
        "password_hash",
        "password",
        "display_name",
        "jwt",
        "token",
        "secret",
        "api_key",
        "selected_answer",
        "correct_answer",
        "is_correct",
        "score",
        "correct_count",
        "duration_seconds",
        "response_time_seconds",
        "mastery_score",
        "mastery_level",
        "recent_accuracy",
        "current_difficulty",
        "attempt_count",
        "trend",
        "completion_percentage",
        "xp_awarded",
        "best_combo",
        "user_id",
    }
)

#: Exact keys of one persisted serving chunk record.
CHUNK_RECORD_KEYS = frozenset(
    {
        "chunk_id",
        "document_id",
        "source_table",
        "source_id",
        "subject_id",
        "unit_id",
        "topic_id",
        "lesson_id",
        "question_id",
        "difficulty",
        "content_version",
        "title",
        "source_type",
        "is_active",
        "text",
        "text_hash",
        "source_hash",
        "corpus_version",
        "document_version",
        "chunk_version",
        "ingestion_version",
        "citation",
        "quarantine",
        "scope",
    }
)

#: Quarantine verdicts for suspicious content (never silent deletion).
QUARANTINE_CLEAN = "clean"
QUARANTINE_REVIEW = "review_quarantined"


def validate_chunk_record(record: dict) -> None:
    """Validate one persisted chunk record.  Raises on any breach."""
    if set(record.keys()) != CHUNK_RECORD_KEYS:
        missing = sorted(CHUNK_RECORD_KEYS - set(record.keys()))
        extra = sorted(set(record.keys()) - CHUNK_RECORD_KEYS)
        raise ContractViolation(
            f"chunk schema breach: missing={missing} extra={extra}")
    if record.get("source_table") not in CHUNK_SOURCE_TABLES:
        raise ContractViolation(
            f"unapproved chunk source: {record.get('source_table')!r}")
    for name in ("chunk_id", "document_id", "source_id", "subject_id",
                 "topic_id", "content_version", "text", "text_hash",
                 "source_hash", "citation"):
        value = record.get(name)
        if not isinstance(value, str) or not value.strip():
            raise ContractViolation(f"{name} must be a non-empty string")
    if record.get("is_active") is not True:
        raise ContractViolation(
            "serving corpus holds active chunks only "
            f"(got is_active={record.get('is_active')!r})")
    for name in ("corpus_version", "document_version", "chunk_version",
                 "ingestion_version"):
        if not isinstance(record.get(name), str) or not record[name].strip():
            raise ContractViolation(f"{name} must be a non-empty string")
    if record["corpus_version"] != CORPUS_VERSION:
        raise ContractViolation(
            f"corpus_version must be {CORPUS_VERSION!r}")
    expected_doc_prefix = f"{record['source_table']}:{record['source_id']}"
    if record["document_id"] != expected_doc_prefix:
        raise ContractViolation("document_id must be {table}:{source_id}")
    if not record["chunk_id"].startswith(expected_doc_prefix + "#"):
        raise ContractViolation("chunk_id must extend its document_id")
    quarantine = record.get("quarantine")
    if not isinstance(quarantine, dict):
        raise ContractViolation("quarantine must be a mapping")
    if quarantine.get("status") not in (QUARANTINE_CLEAN, QUARANTINE_REVIEW):
        raise ContractViolation(
            f"unknown quarantine status: {quarantine.get('status')!r}")
    if not isinstance(quarantine.get("reason_codes"), list):
        raise ContractViolation("quarantine reason_codes must be a list")
    if quarantine["status"] == QUARANTINE_CLEAN and quarantine["reason_codes"]:
        raise ContractViolation("clean chunks carry no reason codes")
    if (quarantine["status"] == QUARANTINE_REVIEW
            and not quarantine["reason_codes"]):
        raise ContractViolation("quarantined chunks require reason codes")
    scope = record.get("scope")
    if not isinstance(scope, dict):
        raise ContractViolation("scope must be a mapping")
    if scope.get("subject_id") != record["subject_id"]:
        raise ContractViolation("scope subject_id inconsistent with chunk")
    if scope.get("topic_id") != record["topic_id"]:
        raise ContractViolation("scope topic_id inconsistent with chunk")
