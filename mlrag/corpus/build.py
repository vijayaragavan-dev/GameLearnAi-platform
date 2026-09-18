"""Corpus construction over Gate 6 ingestion primitives (GATE 21).

Consumes extraction-shaped tables (``lessons`` / ``questions`` / ``topics``
+ ``subjects`` / ``units`` for scope validation — the exact shape produced
by ``mlrag.rag.extract_corpus.fetch_corpus``) and produces validated
serving chunk records.  Per-record ingestion reuses
``mlrag.rag.ingest.ingest_lesson / ingest_question / ingest_topic``
unchanged (same active-before-chunking rule, same chunking policy, same
chunk IDs); this layer adds deterministic ordering, source hashing,
normalization, scope-integrity enforcement, duplicate detection/reporting,
quarantine routing, fingerprinting, and staleness metadata.

Loud-failure policy: malformed records, scope violations, and secret/PII
findings never enter the corpus silently — rejections carry machine
reason codes (counts + safe identifiers only), and secret findings abort
the run via :class:`ContractViolation`.
"""

from __future__ import annotations

import hashlib
import json
from typing import Any

from ..contracts.common import ContractViolation
from ..rag import ingest
from ..rag.errors import InactiveContentBlocked, InvalidDocument
from . import normalize, screening
from .contract import (
    CHUNK_SOURCE_TABLES,
    CHUNK_VERSION,
    CORPUS_VERSION,
    DOCUMENT_VERSION,
    FORBIDDEN_COLUMNS,
    INGESTION_VERSION,
    QUARANTINE_CLEAN,
    validate_chunk_record,
)

#: Educational content fields hashed as the original source representation.
SOURCE_CONTENT_FIELDS: dict[str, tuple[str, ...]] = {
    "lessons": ("id", "topic_id", "title", "content", "summary",
                "difficulty", "source_type", "updated_at"),
    "questions": ("id", "topic_id", "question_text", "options",
                  "explanation", "difficulty", "source_type", "updated_at"),
    "topics": ("id", "subject_id", "name", "description", "difficulty",
               "updated_at"),
}

_INGESTORS = {
    "lessons": ingest.ingest_lesson,
    "questions": ingest.ingest_question,
    "topics": ingest.ingest_topic,
}


def _canonical(value: Any) -> str:
    return json.dumps(value, sort_keys=True, default=str,
                      ensure_ascii=False)


def _safe_id(value: Any) -> str:
    return str(value) if value is not None else ""


def _reject(rejections: list[dict], table: str, record: dict,
            reason: str) -> None:
    rejections.append({
        "source_table": table,
        "source_id": _safe_id(record.get("id")),
        "reason": reason,
    })


def _resolve_scope(doc: Any, topics: dict[str, dict],
                   subjects: dict[str, dict]
                   ) -> dict[str, str | None]:
    """Cross-check chunk scope against authoritative catalogue maps."""
    topic = topics.get(str(doc.topic_id))
    if topic is None:
        raise InvalidDocument(
            f"scope_unknown_topic:{doc.topic_id}")
    if str(topic.get("subject_id")) != str(doc.subject_id):
        raise InvalidDocument(
            "scope_mismatch:topic_subject:"
            f"{topic.get('subject_id')}")
    if not topic.get("is_active", False):
        raise InvalidDocument("scope_inactive_topic")
    subject = subjects.get(str(doc.subject_id))
    if subject is None:
        raise InvalidDocument(
            f"scope_unknown_subject:{doc.subject_id}")
    if not subject.get("is_active", False):
        raise InvalidDocument("scope_inactive_subject")
    topic_unit = topic.get("unit_id")
    doc_unit = getattr(doc, "unit_id", None)
    if _safe_id(topic_unit) != _safe_id(doc_unit):
        raise InvalidDocument(
            f"scope_mismatch:topic_unit:{topic_unit}")
    # NOTE: record-vs-map agreement needs no separate check — the
    # ingestor copies the record's subject/unit/topic into the document,
    # so the doc-vs-authoritative-map comparisons above already reject
    # any corrupt join, stale copy, or tampering with precise codes.
    return {
        "subject_id": str(doc.subject_id),
        "unit_id": _safe_id(doc_unit) or None,
        "topic_id": str(doc.topic_id),
        "lesson_id": _safe_id(getattr(doc, "lesson_id", None)) or None,
    }


def _record_to_chunk(table: str, record: dict, doc: Any,
                     scope: dict[str, str | None]) -> dict:
    fields = {name: record.get(name)
              for name in SOURCE_CONTENT_FIELDS[table]}
    original_hash = normalize.source_hash(table, fields)
    normalized = normalize.normalize_text(doc.text)
    if not normalized:
        raise InvalidDocument("empty_content:after_normalization")
    findings = screening.scan_secrets(normalized)
    if findings:
        raise ContractViolation(
            f"secret/PII finding in {table}:{doc.source_id} "
            f"({findings[0].split(':')[0]}): ingestion STOPPED")
    verdict = screening.screen_text(normalized)
    text_hash = normalize.sha256_hex(normalized)
    document_id = f"{table}:{doc.source_id}"
    chunk = {
        "chunk_id": doc.doc_id,
        "document_id": document_id,
        "source_table": table,
        "source_id": str(doc.source_id),
        "subject_id": str(doc.subject_id),
        "unit_id": scope["unit_id"],
        "topic_id": str(doc.topic_id),
        "lesson_id": _safe_id(getattr(doc, "lesson_id", None)) or None,
        "question_id": _safe_id(getattr(doc, "question_id", None)) or None,
        "difficulty": (doc.difficulty.value
                       if doc.difficulty is not None else None),
        "content_version": str(doc.content_version),
        "title": doc.title,
        "source_type": doc.source_type,
        "is_active": True,
        "text": normalized,
        "text_hash": text_hash,
        "source_hash": original_hash,
        "corpus_version": CORPUS_VERSION,
        "document_version": DOCUMENT_VERSION,
        "chunk_version": CHUNK_VERSION,
        "ingestion_version": INGESTION_VERSION,
        "citation": doc.citation,
        "quarantine": {"status": verdict["status"],
                       "reason_codes": list(verdict["reason_codes"])},
        "scope": scope,
    }
    validate_chunk_record(chunk)
    return chunk


def _fingerprint(serving: list[dict], counts: dict) -> str:
    payload = {
        "corpus_version": CORPUS_VERSION,
        "document_version": DOCUMENT_VERSION,
        "chunk_version": CHUNK_VERSION,
        "ingestion_version": INGESTION_VERSION,
        "chunks": [
            {"chunk_id": c["chunk_id"], "text_hash": c["text_hash"],
             "source_table": c["source_table"],
             "source_id": c["source_id"],
             "subject_id": c["subject_id"], "unit_id": c["unit_id"],
             "topic_id": c["topic_id"], "lesson_id": c["lesson_id"],
             "question_id": c["question_id"],
             "difficulty": c["difficulty"],
             "content_version": c["content_version"],
             "is_active": c["is_active"]}
            for c in sorted(serving, key=lambda c: c["chunk_id"])
        ],
        "counts": counts,
    }
    return hashlib.sha256(
        _canonical(payload).encode("utf-8")).hexdigest()


def source_snapshot(tables: dict[str, list[dict]]) -> dict:
    """Deterministic source metadata for staleness detection (no content)."""
    meta = {}
    for table in ("subjects", "units", "topics", "lessons", "questions"):
        rows = tables.get(table, [])
        stamps = sorted(str(r.get("updated_at"))
                        for r in rows if r.get("updated_at") is not None)
        # Identity covers active state too: an active->inactive flip
        # must register as a source change for staleness detection.
        identities = sorted(
            f"{r.get('id')}:{r.get('updated_at')}:{r.get('is_active')}"
            for r in rows)
        meta[table] = {
            "count": len(rows),
            "max_updated_at": stamps[-1] if stamps else None,
            "snapshot_hash": normalize.sha256_hex(
                f"{table}\n" + "\n".join(identities)),
        }
    return meta


def is_stale(artifact_snapshot: dict, fresh_snapshot: dict) -> dict:
    """Compare source snapshots; stale content is never silently current."""
    if artifact_snapshot == fresh_snapshot:
        return {"stale": False, "reason": "source snapshot identical"}
    diffs = sorted(
        table for table in fresh_snapshot
        if artifact_snapshot.get(table) != fresh_snapshot.get(table))
    return {"stale": True,
            "reason": f"source snapshot differs on: {', '.join(diffs)}"}


def _audit_extraction_shape(tables: dict[str, list[dict]]) -> None:
    """Refuse forbidden tables/columns before any ingestion work."""
    for table in tables:
        if table in ("users", "quiz_attempts", "question_attempts",
                     "topic_mastery", "progress", "recommendations",
                     "xp_transactions", "game_results", "ai_interactions"):
            raise ContractViolation(
                f"forbidden learner-state table in corpus input: {table}")
    for table, rows in tables.items():
        for row in rows:
            leaked = sorted(set(row.keys()) & FORBIDDEN_COLUMNS)
            if leaked:
                raise ContractViolation(
                    f"forbidden columns in {table} input: "
                    + ", ".join(leaked))


def build_corpus(tables: dict[str, list[dict]]) -> dict[str, Any]:
    """Build the validated corpus from extraction-shaped tables."""
    _audit_extraction_shape(tables)
    subjects = {str(r.get("id")): r for r in tables.get("subjects", [])}
    topics = {str(r.get("id")): r for r in tables.get("topics", [])}

    examined = sum(len(tables.get(t, [])) for t in CHUNK_SOURCE_TABLES)
    chunks: list[dict] = []
    rejections: list[dict] = []
    skipped_inactive = 0
    rejection_reasons: dict[str, int] = {}

    def _count(reason: str) -> None:
        key = reason.split(":")[0]
        rejection_reasons[key] = rejection_reasons.get(key, 0) + 1

    for table in sorted(CHUNK_SOURCE_TABLES):
        ingestor = _INGESTORS[table]
        ordered = sorted(tables.get(table, []),
                         key=lambda r: str(r.get("id")))
        for record in ordered:
            try:
                docs = ingestor(record)
            except InactiveContentBlocked:
                skipped_inactive += 1
                continue
            except InvalidDocument as exc:
                _reject(rejections, table, record, str(exc))
                _count(str(exc))
                continue
            for doc in docs:
                try:
                    scope = _resolve_scope(doc, topics, subjects)
                    chunks.append(_record_to_chunk(table, record, doc,
                                                  scope))
                except InvalidDocument as exc:
                    _reject(rejections, table, record, str(exc))
                    _count(str(exc))
                except ContractViolation:
                    raise

    # Duplicate detection: exact chunk identity (keep first, drop rest,
    # reported); normalized-content duplicates across distinct sources
    # (keep ALL — distinct legitimate sources, provenance preserved).
    seen_ids: dict[str, dict] = {}
    identity_dupes = 0
    unique: list[dict] = []
    for chunk in sorted(chunks, key=lambda c: c["chunk_id"]):
        if chunk["chunk_id"] in seen_ids:
            identity_dupes += 1
            continue
        seen_ids[chunk["chunk_id"]] = chunk
        unique.append(chunk)
    by_content: dict[str, list[str]] = {}
    for chunk in unique:
        by_content.setdefault(chunk["text_hash"], []).append(
            chunk["chunk_id"])
    content_dupe_groups = sorted(
        [sorted(ids) for ids in by_content.values() if len(ids) > 1])

    quarantined = [c for c in unique
                   if c["quarantine"]["status"] != "clean"]
    serving = sorted(
        (c for c in unique if c["quarantine"]["status"] == "clean"),
        key=lambda c: c["chunk_id"])
    quarantine_reasons: dict[str, int] = {}
    for chunk in quarantined:
        for code in chunk["quarantine"]["reason_codes"]:
            quarantine_reasons[code] = quarantine_reasons.get(code, 0) + 1

    counts = {
        "examined": examined,
        "chunks_built": len(chunks),
        "unique_chunks": len(unique),
        "serving_chunks": len(serving),
        "quarantined_chunks": len(quarantined),
        "exact_identity_duplicates": identity_dupes,
        "content_duplicate_groups": len(content_dupe_groups),
        "rejected": len(rejections),
        "skipped_inactive": skipped_inactive,
    }
    fingerprint = _fingerprint(serving, counts)
    stats = _statistics(serving, quarantined, counts, rejections,
                        rejection_reasons, quarantine_reasons,
                        content_dupe_groups)
    return {
        "corpus_version": CORPUS_VERSION,
        "document_version": DOCUMENT_VERSION,
        "chunk_version": CHUNK_VERSION,
        "ingestion_version": INGESTION_VERSION,
        "chunks": serving,
        "quarantined": quarantined,
        "rejections": rejections,
        "duplicates": {
            "exact_identity_duplicates_dropped": identity_dupes,
            "content_duplicate_groups": content_dupe_groups,
            "rationale": ("identity duplicates: same source identity "
                          "ingested twice — first retained, rest dropped, "
                          "all reported; content duplicates: identical "
                          "normalized text from DISTINCT sources — all "
                          "retained with full provenance, never merged"),
        },
        "counts": counts,
        "stats": stats,
        "fingerprint": fingerprint,
        "source_snapshot": source_snapshot(tables),
    }


def _statistics(serving: list[dict], quarantined: list[dict],
                counts: dict, rejections: list[dict],
                rejection_reasons: dict, quarantine_reasons: dict,
                content_dupe_groups: list[list[str]]) -> dict:
    def _hist(rows: list[dict], key: str) -> dict:
        hist: dict[str, int] = {}
        for row in rows:
            hist[str(row.get(key))] = hist.get(str(row.get(key)), 0) + 1
        return dict(sorted(hist.items()))

    return {
        "active_documents": len(serving),
        "inactive_excluded": counts["skipped_inactive"],
        "documents_by_source_type": _hist(serving, "source_table"),
        "chunks": len(serving),
        "chunks_by_source_type": _hist(serving, "source_table"),
        "chunks_by_subject": _hist(serving, "subject_id"),
        "chunks_by_topic": _hist(serving, "topic_id"),
        "chunks_by_unit": _hist(serving, "unit_id"),
        "chunks_by_lesson": _hist(
            [c for c in serving if c.get("lesson_id")], "lesson_id"),
        "difficulty_distribution": _hist(serving, "difficulty"),
        "empty_content_count": 0,
        "exact_identity_duplicates": counts["exact_identity_duplicates"],
        "content_duplicate_groups": len(content_dupe_groups),
        "largest_content_duplicate_group": max(
            (len(g) for g in content_dupe_groups), default=0),
        "suspicious_content_count": len(quarantined),
        "quarantined_count": len(quarantined),
        "quarantine_reasons": quarantine_reasons,
        "rejected_count": len(rejections),
        "rejection_reasons": rejection_reasons,
        "corpus_version": CORPUS_VERSION,
    }
