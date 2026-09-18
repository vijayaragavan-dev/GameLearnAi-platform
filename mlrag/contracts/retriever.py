"""Retriever port: contract for future RAG retrieval (GATE 1).

Abstraction ONLY.  No embeddings, no vector store, no chunking, no
ingestion, no semantic search are implemented or selected here — the
backend is chosen later after evaluation (GATE 7+).

Hard guarantees baked into the contract:
  * every request carries a subject/topic/unit scope (hard pre-filter);
  * served chunks must be active, versioned, and scope-matching
    (post-retrieval validation);
  * every chunk carries source metadata + citation;
  * retrieved content is DATA for grounding, never instructions.
"""

from __future__ import annotations

import abc
from dataclasses import dataclass

from .common import ContractViolation, Difficulty, TraceContext

#: Sources the future retriever may draw from (authoritative content only).
APPROVED_SOURCE_TABLES = frozenset(
    {"subjects", "units", "topics", "lessons", "questions"}
)

_MAX_QUERY_CHARS = 2000
_MAX_TOP_K = 50


@dataclass(frozen=True)
class ScopeFilter:
    """Hard scope for retrieval.  Subject anchor is mandatory."""

    subject_id: str
    topic_id: str | None = None
    unit_id: str | None = None
    active_only: bool = True
    content_version: str | None = None
    difficulty: Difficulty | None = None

    def __post_init__(self) -> None:
        if not self.subject_id.strip():
            raise ContractViolation("scope requires a subject_id")
        if not self.active_only:
            raise ContractViolation(
                "scope must keep active_only=True (inactive content "
                "must never be retrieved)"
            )


@dataclass(frozen=True)
class RetrievalRequest:
    """What Spring Boot will send the future retriever."""

    trace: TraceContext
    scope: ScopeFilter
    query: str
    top_k: int = 5
    source_tables: tuple[str, ...] = ()

    def __post_init__(self) -> None:
        if not self.query.strip():
            raise ContractViolation("query must be non-empty")
        if len(self.query) > _MAX_QUERY_CHARS:
            raise ContractViolation("query exceeds maximum length")
        if not 1 <= self.top_k <= _MAX_TOP_K:
            raise ContractViolation("top_k must be within 1..50")
        unknown = sorted(set(self.source_tables) - APPROVED_SOURCE_TABLES)
        if unknown:
            raise ContractViolation(
                "unapproved retrieval sources: " + ", ".join(unknown)
            )


@dataclass(frozen=True)
class RetrievedChunk:
    """One grounded, citable, scope-validated chunk."""

    chunk_id: str
    source_table: str
    source_id: str
    subject_id: str
    topic_id: str
    unit_id: str | None
    content_version: str
    is_active: bool
    text: str
    score: float
    citation: str
    difficulty: Difficulty | None = None

    def __post_init__(self) -> None:
        if self.source_table not in APPROVED_SOURCE_TABLES:
            raise ContractViolation(
                f"unapproved chunk source: {self.source_table}"
            )
        if not self.is_active:
            raise ContractViolation("retriever must not serve inactive chunks")
        for name in (
            "chunk_id",
            "source_id",
            "subject_id",
            "topic_id",
            "content_version",
            "text",
            "citation",
        ):
            if not getattr(self, name).strip():
                raise ContractViolation(f"{name} must be non-empty")


@dataclass(frozen=True)
class RetrievalResponse:
    """Scoped retrieval result, with post-retrieval scope validation."""

    request_id: str
    served: bool
    chunks: tuple[RetrievedChunk, ...] = ()
    retriever_version: str = ""
    empty_reason: str = ""

    def __post_init__(self) -> None:
        if not self.request_id.strip():
            raise ContractViolation("request_id must be non-empty")
        if self.served:
            if not self.retriever_version.strip():
                raise ContractViolation(
                    "served response requires retriever_version"
                )
            if not self.chunks:
                raise ContractViolation(
                    "served response must contain at least one chunk "
                    "(else use served=False with empty_reason)"
                )
        elif not self.empty_reason.strip():
            raise ContractViolation(
                "unserved response requires an empty_reason "
                "(safe degraded mode, never silent claims)"
            )

    def validate_against(self, scope: ScopeFilter) -> None:
        """Post-retrieval check: no cross-subject/topic leakage."""
        for chunk in self.chunks:
            if chunk.subject_id != scope.subject_id:
                raise ContractViolation(
                    f"cross-subject leakage: chunk {chunk.chunk_id}"
                )
            if scope.topic_id is not None and chunk.topic_id != scope.topic_id:
                raise ContractViolation(
                    f"cross-topic leakage: chunk {chunk.chunk_id}"
                )


class RetrieverPort(abc.ABC):
    """Abstract retriever.  A future vector backend implements this."""

    @property
    @abc.abstractmethod
    def retriever_version(self) -> str:
        """Version of the retrieval backend + index snapshot."""
        raise NotImplementedError

    @abc.abstractmethod
    def retrieve(self, request: RetrievalRequest) -> RetrievalResponse:
        """Return scoped, validated chunks.  Must not mutate learner state."""
        raise NotImplementedError
