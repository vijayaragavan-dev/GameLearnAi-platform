"""Offline ingestion boundary (GATE 6, PHASE 4).

Pure functions: authoritative record dicts -> validated RagDocuments.
This module never touches MySQL (no imports from experiment.db), never
writes application data, preserves source IDs verbatim, and rejects
invalid/inactive records while counting them.  Deterministic re-runs:
inputs are processed in stable (source_table, source_id) order.
"""

from __future__ import annotations

from dataclasses import dataclass, field

from mlrag.contracts.common import Difficulty

from .chunking import DEFAULT_MAX_CHARS, chunk_document_fields
from .documents import RagDocument
from .errors import InactiveContentBlocked, InvalidDocument


@dataclass
class IngestStats:
    """Deterministic counts for one ingestion pass (no content stored)."""

    documents: int = 0
    skipped_inactive: int = 0
    rejected: int = 0
    rejection_reasons: list[str] = field(default_factory=list)


@dataclass
class IngestResult:
    documents: list[RagDocument]
    stats: IngestStats


def _require_str(record: dict, key: str, *, allow_empty: bool = False) -> str:
    value = record.get(key)
    if not isinstance(value, str) or (not allow_empty and not value.strip()):
        raise InvalidDocument(f"record missing required text field: {key}")
    return value


def _require_id(record: dict, key: str) -> str:
    value = record.get(key)
    if value is None or (isinstance(value, str) and not value.strip()):
        raise InvalidDocument(f"record missing required id field: {key}")
    return str(value)


def _difficulty_of(record: dict) -> Difficulty | None:
    raw = record.get("difficulty")
    if raw is None:
        return None
    try:
        return Difficulty(str(raw).upper())
    except ValueError as exc:
        raise InvalidDocument(f"unknown difficulty: {raw!r}") from exc


def _version_of(record: dict) -> str:
    updated = record.get("updated_at")
    if updated is None:
        return "unversioned"
    return str(updated)


def _context_line(*parts: str | None) -> str | None:
    named = [p.strip() for p in parts if p and p.strip()]
    return " | ".join(named) if named else None


def ingest_lesson(record: dict, *, max_chars: int = DEFAULT_MAX_CHARS
                  ) -> list[RagDocument]:
    """Lesson content + summary -> section chunks.  Inactive -> []."""
    if not record.get("is_active", False):
        raise InactiveContentBlocked("lessons:" + str(record.get("id")))
    lesson_id = _require_id(record, "id")
    topic_id = _require_id(record, "topic_id")
    subject_id = _require_id(record, "subject_id")
    title = _require_str(record, "title")
    content = _require_str(record, "content")
    docs = chunk_document_fields(
        source_table="lessons", source_id=lesson_id,
        subject_id=subject_id, topic_id=topic_id, text=content,
        is_active=True, unit_id=record.get("unit_id"),
        lesson_id=lesson_id, difficulty=_difficulty_of(record),
        content_version=_version_of(record), title=title,
        source_type=record.get("source_type"),
        context_line=_context_line(title), max_chars=max_chars)
    summary = record.get("summary")
    if isinstance(summary, str) and summary.strip():
        docs.extend(chunk_document_fields(
            source_table="lessons", source_id=f"{lesson_id}:summary",
            subject_id=subject_id, topic_id=topic_id, text=summary.strip(),
            is_active=True, unit_id=record.get("unit_id"),
            lesson_id=lesson_id, difficulty=_difficulty_of(record),
            content_version=_version_of(record), title=f"{title} (summary)",
            source_type=record.get("source_type"),
            context_line=_context_line(title), max_chars=max_chars))
    return docs


def ingest_question(record: dict, *, max_chars: int = DEFAULT_MAX_CHARS
                    ) -> list[RagDocument]:
    """Question + options + explanation -> one item chunk.  Inactive -> []."""
    if not record.get("is_active", False):
        raise InactiveContentBlocked("questions:" + str(record.get("id")))
    question_id = _require_id(record, "id")
    topic_id = _require_id(record, "topic_id")
    subject_id = _require_id(record, "subject_id")
    stem = _require_str(record, "question_text")
    lines = [f"Question: {stem.strip()}"]
    options = record.get("options")
    if isinstance(options, str) and options.strip():
        lines.append(f"Options: {options.strip()}")
    explanation = record.get("explanation")
    if isinstance(explanation, str) and explanation.strip():
        lines.append(f"Explanation: {explanation.strip()}")
    return chunk_document_fields(
        source_table="questions", source_id=question_id,
        subject_id=subject_id, topic_id=topic_id,
        text="\n".join(lines), is_active=True,
        unit_id=record.get("unit_id"), question_id=question_id,
        difficulty=_difficulty_of(record),
        content_version=_version_of(record),
        source_type=record.get("source_type"),
        context_line=None, max_chars=max_chars)


def ingest_topic(record: dict, *, max_chars: int = DEFAULT_MAX_CHARS
                 ) -> list[RagDocument]:
    """Topic description -> chunk (skipped when description is absent)."""
    if not record.get("is_active", False):
        raise InactiveContentBlocked("topics:" + str(record.get("id")))
    topic_id = _require_id(record, "id")
    subject_id = _require_id(record, "subject_id")
    name = _require_str(record, "name")
    description = record.get("description")
    if not isinstance(description, str) or not description.strip():
        raise InvalidDocument(f"topic {topic_id} has no description text")
    return chunk_document_fields(
        source_table="topics", source_id=topic_id,
        subject_id=subject_id, topic_id=topic_id,
        text=description.strip(), is_active=True,
        unit_id=record.get("unit_id"), difficulty=_difficulty_of(record),
        content_version=_version_of(record),
        context_line=_context_line(name), max_chars=max_chars)


_INGESTORS = {
    "lessons": ingest_lesson,
    "questions": ingest_question,
    "topics": ingest_topic,
}


def ingest_records(records: list[dict], *, source_table: str,
                   max_chars: int = DEFAULT_MAX_CHARS) -> IngestResult:
    """Ingest one source table's records deterministically.

    Unknown tables, invalid records, and inactive rows are counted, never
    served.  Inactive rows are skipped (active-content filtering); invalid
    rows are rejected with reasons.  Re-running identical input yields
    identical documents in identical order.
    """
    ingestor = _INGESTORS.get(source_table)
    stats = IngestStats()
    if ingestor is None:
        stats.rejected = len(records)
        stats.rejection_reasons.append(
            f"unsupported source table: {source_table}")
        return IngestResult(documents=[], stats=stats)
    ordered = sorted(records, key=lambda r: str(r.get("id")))
    documents: list[RagDocument] = []
    for record in ordered:
        try:
            documents.extend(
                ingestor(record, max_chars=max_chars))
        except InactiveContentBlocked:
            stats.skipped_inactive += 1
        except InvalidDocument as exc:
            stats.rejected += 1
            stats.rejection_reasons.append(str(exc))
    stats.documents = len(documents)
    return IngestResult(documents=documents, stats=stats)
