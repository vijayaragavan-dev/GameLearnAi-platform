"""Narrow retriever interface + deterministic offline retriever
(GATE 6, PHASE 5).

Scope filtering is a RETRIEVAL CONSTRAINT enforced in code before any
scoring: a chunk outside the requested subject/topic/unit/lesson scope is
never scored, never ranked, never returned.  Results reuse the existing
``contracts`` retrieval types (RetrievalResponse / RetrievedChunk) so the
future vector backend satisfies the same boundary without redesign.

The bundled ``LexicalRetriever`` scores with TF-IDF over the
scope-filtered candidate set (standard library only) with deterministic
tie-breaking.  It is the offline foundation baseline — not a claim that
lexical retrieval is sufficient at scale.
"""

from __future__ import annotations

import abc
import math
import re
from collections import Counter
from dataclasses import dataclass

from mlrag.contracts.common import ContractViolation
from mlrag.contracts.retriever import (RetrievalResponse, RetrievedChunk,
                                       ScopeFilter, TraceContext)

from .documents import RagDocument
from .errors import (EmptyCorpus, NoResults, RetrieverUnavailable,
                     ScopeViolation, degraded_response)

_TOKEN = re.compile(r"[a-z0-9]+")


def tokenize(text: str) -> list[str]:
    """Lowercase alphanumeric tokens (deterministic, language-neutral)."""
    return _TOKEN.findall(text.lower())


@dataclass(frozen=True)
class RagQuery:
    """Narrow retrieval request: text + hard scope + limit."""

    query: str
    subject_id: str
    topic_id: str | None = None
    unit_id: str | None = None
    lesson_id: str | None = None
    top_k: int = 5

    def __post_init__(self) -> None:
        if not self.query.strip():
            raise ContractViolation("query must be non-empty")
        if not self.subject_id.strip():
            raise ContractViolation("retrieval requires a subject scope")
        if not 1 <= self.top_k <= 50:
            raise ContractViolation("top_k must be within 1..50")


def apply_scope(documents: list[RagDocument], query: RagQuery
                ) -> list[RagDocument]:
    """Hard scope constraint.  Non-matching documents are eliminated."""
    kept = []
    for doc in documents:
        if not doc.is_active:
            continue
        if doc.subject_id != query.subject_id:
            continue
        if query.topic_id is not None and doc.topic_id != query.topic_id:
            continue
        if query.unit_id is not None and doc.unit_id != query.unit_id:
            continue
        if query.lesson_id is not None and doc.lesson_id != query.lesson_id:
            continue
        kept.append(doc)
    return kept


def _tf_idf_scores(query_terms: list[str],
                   candidates: list[RagDocument]) -> list[tuple[float, str]]:
    doc_tokens = [tokenize(doc.text) for doc in candidates]
    doc_freq: Counter[str] = Counter()
    for tokens in doc_tokens:
        doc_freq.update(set(tokens))
    total = len(candidates)
    scored = []
    for doc, tokens in zip(candidates, doc_tokens):
        counts = Counter(tokens)
        length = len(tokens) or 1
        score = 0.0
        for term in set(query_terms):
            if term not in doc_freq:
                continue
            idf = math.log((1 + total) / (1 + doc_freq[term])) + 1.0
            score += (counts[term] / length) * idf
        scored.append((score, doc.doc_id))
    scored.sort(key=lambda item: (-item[0], item[1]))
    return scored


class RagRetriever(abc.ABC):
    """Narrow retriever interface.  Backends differ; the boundary does not."""

    @property
    @abc.abstractmethod
    def version(self) -> str:
        raise NotImplementedError

    @abc.abstractmethod
    def retrieve(self, query: RagQuery, corpus: list[RagDocument],
                 *, request_id: str) -> RetrievalResponse:
        """Scoped retrieval.  Must never return out-of-scope content."""
        raise NotImplementedError


class LexicalRetriever(RagRetriever):
    """Deterministic TF-IDF retriever over the scoped subset (offline)."""

    @property
    def version(self) -> str:
        return "lexical-tfidf-0.1.0"

    def retrieve(self, query: RagQuery, corpus: list[RagDocument], *,
                 request_id: str) -> RetrievalResponse:
        if not request_id.strip():
            raise ContractViolation("request_id must be non-empty")
        if not corpus:
            return degraded_response(request_id, "empty_corpus",
                                     self.version)
        candidates = apply_scope(corpus, query)
        if not candidates:
            return degraded_response(request_id, "no_results_in_scope",
                                     self.version)
        terms = tokenize(query.query)
        if not terms:
            return degraded_response(request_id, "no_results_in_scope",
                                     self.version)
        ranked = _tf_idf_scores(terms, candidates)
        by_id = {doc.doc_id: doc for doc in candidates}
        chunks = []
        for score, doc_id in ranked[:query.top_k]:
            if score <= 0.0:
                continue
            doc = by_id[doc_id]
            if (doc.subject_id != query.subject_id
                    or (query.topic_id is not None
                        and doc.topic_id != query.topic_id)):
                raise ScopeViolation(f"scope breach avoided: {doc_id}")
            chunks.append(RetrievedChunk(
                chunk_id=doc.doc_id,
                source_table=doc.source_table,
                source_id=doc.source_id,
                subject_id=doc.subject_id,
                topic_id=doc.topic_id,
                unit_id=doc.unit_id,
                content_version=doc.content_version,
                is_active=True,
                text=doc.text,
                score=score,
                citation=doc.citation,
                difficulty=doc.difficulty,
            ))
        if not chunks:
            return degraded_response(request_id, "no_results_in_scope",
                                     self.version)
        response = RetrievalResponse(
            request_id=request_id, served=True, chunks=tuple(chunks),
            retriever_version=self.version)
        response.validate_against(ScopeFilter(
            subject_id=query.subject_id, topic_id=query.topic_id,
            unit_id=query.unit_id))
        return response


def unavailable_retriever(reason: str = "retriever_unavailable"):
    """Helper for failure-path tests: a retriever that cannot serve."""

    class _Down(RagRetriever):
        @property
        def version(self) -> str:
            return "down-0.0.0"

        def retrieve(self, query: RagQuery, corpus: list[RagDocument], *,
                     request_id: str) -> RetrievalResponse:
            raise RetrieverUnavailable(reason)

    return _Down()


__all__ = ["RagQuery", "RagRetriever", "LexicalRetriever",
           "unavailable_retriever", "apply_scope", "tokenize"]
