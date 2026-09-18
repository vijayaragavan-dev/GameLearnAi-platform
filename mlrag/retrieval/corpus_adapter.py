"""Gate 21 chunk-record -> RagDocument adapter (Gate 22).

Reuses the Gate 21 contracts without duplicating ingestion logic: every
serving chunk record already carries exactly the fields the Gate 6
``RagDocument`` contract requires.  This adapter is a mechanical field
mapping (plus difficulty-enum parsing) used by evaluation and serving
code so both retrievers rank the SAME authoritative documents.
"""

from __future__ import annotations

from mlrag.contracts.common import ContractViolation, Difficulty
from mlrag.rag.documents import RagDocument


def chunk_record_to_document(record: dict) -> RagDocument:
    """Map one validated Gate 21 serving chunk to a ``RagDocument``."""
    difficulty = None
    if record.get("difficulty") is not None:
        try:
            difficulty = Difficulty(str(record["difficulty"]))
        except ValueError as exc:
            raise ContractViolation(
                f"unknown difficulty {record.get('difficulty')!r}") from exc
    return RagDocument(
        doc_id=str(record["chunk_id"]),
        source_table=str(record["source_table"]),
        source_id=str(record["source_id"]),
        text=str(record["text"]),
        subject_id=str(record["subject_id"]),
        topic_id=str(record["topic_id"]),
        is_active=bool(record.get("is_active", False)),
        unit_id=(str(record["unit_id"])
                 if record.get("unit_id") is not None else None),
        lesson_id=(str(record["lesson_id"])
                   if record.get("lesson_id") is not None else None),
        question_id=(str(record["question_id"])
                     if record.get("question_id") is not None else None),
        difficulty=difficulty,
        content_version=str(record.get("content_version", "unversioned")),
        title=record.get("title"),
        source_type=record.get("source_type"),
    )


def corpus_to_documents(chunks: list[dict]) -> list[RagDocument]:
    """Map serving chunks to documents in stable chunk_id order."""
    return [chunk_record_to_document(c)
            for c in sorted(chunks, key=lambda c: c["chunk_id"])]


__all__ = ["chunk_record_to_document", "corpus_to_documents"]
