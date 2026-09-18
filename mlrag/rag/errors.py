"""RAG failure taxonomy (GATE 6, PHASE 9).

Every failure mode maps to an explicit degraded reason code consumed as
``RetrievalResponse(served=False, empty_reason=...)``.  The pipeline never
returns ungrounded educational content as if it were retrieved.
"""

from __future__ import annotations

from mlrag.contracts.common import ContractViolation
from mlrag.contracts.retriever import RetrievalResponse


class RagError(Exception):
    """Base class for all RAG-foundation failures."""


class EmptyCorpus(RagError):
    """No documents available to the retriever at all."""


class NoResults(RagError):
    """Corpus exists but nothing matches the (scoped) query."""


class InvalidDocument(RagError):
    """A source record failed document validation (rejected, counted)."""


class InactiveContentBlocked(RagError):
    """Inactive/deprecated content was offered for retrieval and refused."""


class RetrieverUnavailable(RagError):
    """The retrieval backend cannot serve (offline/failure path)."""


class EmbeddingFailure(RagError):
    """Embedding backend failed (future vector path only)."""


class VectorStoreFailure(RagError):
    """Vector-store backend failed (future vector path only)."""


class MalformedDocument(RagError):
    """A document violates the contract at serve time (never served)."""


class GroundingFailure(RagError):
    """A context cannot be treated as grounded (provenance/scope gap)."""


class InstructionOverrideBlocked(RagError):
    """Retrieved text attempted to act as instructions; quarantined."""


class ScopeViolation(RagError):
    """A chunk outside the requested hard scope reached validation."""


_EMPTY_REASONS: dict[type, str] = {
    EmptyCorpus: "empty_corpus",
    NoResults: "no_results_in_scope",
    RetrieverUnavailable: "retriever_unavailable",
    EmbeddingFailure: "embedding_failure",
    VectorStoreFailure: "vector_store_failure",
}


def to_empty_reason(error: Exception) -> str:
    """Map a failure to its degraded reason code (unknown -> safe default)."""
    for kind, code in _EMPTY_REASONS.items():
        if isinstance(error, kind):
            return code
    if isinstance(error, RagError):
        return "rag_failure"
    if isinstance(error, ContractViolation):
        return "contract_violation"
    return "internal_failure"


def degraded_response(request_id: str, reason: str,
                      retriever_version: str = "rag-foundation-0.1.0") -> RetrievalResponse:
    """Explicit degraded outcome.  Never carries content."""
    return RetrievalResponse(
        request_id=request_id,
        served=False,
        chunks=(),
        retriever_version=retriever_version,
        empty_reason=reason,
    )
