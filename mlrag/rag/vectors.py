"""Embedder / vector-store interfaces + backend decision (GATE 6, PHASE 6).

Decision: **deferred, provider-neutral**.  The foundation corpus is small
(hundreds of documents), scope-filtered, and served deterministically by
the lexical retriever.  No evidence in the corpus audit justifies vector
infrastructure in this gate, so no backend is selected, no client is
installed, and no vectors are produced.  When scale or recall evaluation
demands it, a backend implements these two interfaces — the retrieval
boundary (``retrieval.RagRetriever``) and all scope/grounding guarantees
stay unchanged.
"""

from __future__ import annotations

import abc

BACKEND_DECISION = "deferred-provider-neutral"


class Embedder(abc.ABC):
    """Future text->vector backend.  No implementation in this gate."""

    @property
    @abc.abstractmethod
    def dimension(self) -> int:
        raise NotImplementedError

    @property
    @abc.abstractmethod
    def version(self) -> str:
        raise NotImplementedError

    @abc.abstractmethod
    def embed(self, texts: list[str]) -> list[list[float]]:
        """Embed texts.  Must be deterministic for identical input."""
        raise NotImplementedError


class VectorStore(abc.ABC):
    """Future vector index.  Scope filtering stays a store-level constraint."""

    @property
    @abc.abstractmethod
    def version(self) -> str:
        raise NotImplementedError

    @abc.abstractmethod
    def upsert(self, vectors: list[list[float]],
               metadata: list[dict]) -> None:
        raise NotImplementedError

    @abc.abstractmethod
    def search(self, vector: list[float], scope: dict,
               top_k: int) -> list[tuple[str, float]]:
        """Return (doc_id, score) pairs restricted to ``scope`` first."""
        raise NotImplementedError
