"""Grounding contract (GATE 6, PHASE 7).

A context counts as grounded ONLY if every supporting chunk carries
valid provenance (approved source, verbatim source ID, scope-matching
subject/topic) and a non-empty citation.  Anything else raises
GroundingFailure — the future answer layer must degrade instead of
presenting unsupported educational claims.
"""

from __future__ import annotations

from dataclasses import dataclass

from mlrag.contracts.retriever import RetrievedChunk, ScopeFilter

from .documents import APPROVED_SOURCE_TABLES
from .errors import GroundingFailure, ScopeViolation


@dataclass(frozen=True)
class GroundedContext:
    """A validated, citable retrieval context for answer generation."""

    request_id: str
    chunks: tuple[RetrievedChunk, ...]
    citations: tuple[str, ...]


def validate_grounded(chunks: list[RetrievedChunk], scope: ScopeFilter, *,
                      request_id: str) -> GroundedContext:
    """Assert provenance + scope for every chunk; quarantine the rest."""
    if not chunks:
        raise GroundingFailure("empty context cannot ground an answer")
    for chunk in chunks:
        if chunk.source_table not in APPROVED_SOURCE_TABLES:
            raise GroundingFailure(
                f"unapproved source: {chunk.source_table}")
        if not chunk.source_id.strip() or not chunk.citation.strip():
            raise GroundingFailure("chunk missing source ID or citation")
        if not chunk.is_active:
            raise GroundingFailure("inactive chunk cannot ground an answer")
        if chunk.subject_id != scope.subject_id:
            raise ScopeViolation(
                f"cross-subject chunk: {chunk.chunk_id}")
        if (scope.topic_id is not None
                and chunk.topic_id != scope.topic_id):
            raise ScopeViolation(
                f"cross-topic chunk: {chunk.chunk_id}")
    return GroundedContext(
        request_id=request_id,
        chunks=tuple(chunks),
        citations=tuple(chunk.citation for chunk in chunks),
    )
