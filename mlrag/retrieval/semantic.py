"""Pretrained-embedding semantic retriever (Gate 22).

Narrow retrieval interface, same boundary as the lexical foundation:

    query
      -> query embedding (SAME pinned HF model as the index)
      -> hard candidate scope filtering (subject/topic/unit/lesson +
         difficulty, BEFORE any scoring)
      -> cosine ranking over the scoped candidates only
      -> top-K
      -> citation/provenance validation
      -> result (or explicit insufficient-evidence degraded state)

Security properties:

* scope comes ONLY from the typed ``RagQuery`` fields — query TEXT can
  never widen scope, forge metadata, or request hidden fields
* inactive documents are eliminated before scoring (never ranked)
* index rows for documents absent from the supplied corpus are ignored;
  corpus documents absent from the index are unscorable and skipped
  (stale content is never fabricated)
* low-similarity result sets degrade to ``insufficient_evidence``
  instead of returning ungrounded claims
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np

from mlrag.contracts.common import ContractViolation, Difficulty
from mlrag.contracts.retriever import (RetrievalResponse, RetrievedChunk,
                                       ScopeFilter)
from mlrag.embeddings import hf_embedder, model_registry
from mlrag.embeddings.pipeline import (DEFAULT_INDEX_PATH,
                                       DEFAULT_MANIFEST_PATH,
                                       load_artifact)
from mlrag.rag.documents import RagDocument
from mlrag.rag.errors import EmbeddingFailure, degraded_response
from mlrag.rag.retrieval import RagQuery, RagRetriever, apply_scope

#: Default cosine floor below which results are declared insufficient
#: evidence instead of served (tuned against the Gate 22 eval set; see the
#: implementation report for the measurement trail).
DEFAULT_MIN_SCORE = 0.20


@dataclass(frozen=True)
class SemanticQuery(RagQuery):
    """Scoped retrieval request with optional difficulty narrowing."""

    difficulty: Difficulty | None = None


def build_memory_index(doc_ids: list[str], texts: list[str],
                       embedder: hf_embedder.HFEmbedder
                       ) -> tuple[np.ndarray, list[str]]:
    """Embed a small document set with the REAL model (tests/fixtures).

    Never random, never hashed — the same pinned model as production,
    only over a smaller input set.  Output rows are L2-normalized
    float32 in input order.
    """
    if len(doc_ids) != len(texts):
        raise ContractViolation("doc_ids/texts length mismatch")
    if len(set(doc_ids)) != len(doc_ids):
        raise ContractViolation("doc_ids must be unique")
    rows = embedder.embed(texts)
    matrix = np.asarray(rows, dtype=np.float32)
    norms = np.linalg.norm(matrix, axis=1, keepdims=True)
    matrix = matrix / np.maximum(norms, 1e-12)
    return np.ascontiguousarray(matrix, dtype=np.float32), list(doc_ids)


class SemanticRetriever(RagRetriever):
    """Cosine retriever over the pinned HF embedding index (offline)."""

    def __init__(
        self,
        matrix: np.ndarray,
        chunk_ids: list[str],
        manifest: dict,
        embedder: hf_embedder.HFEmbedder,
        *,
        min_score: float = DEFAULT_MIN_SCORE,
    ) -> None:
        if matrix.shape[0] != len(chunk_ids):
            raise ContractViolation("index matrix/ids length mismatch")
        if matrix.shape[1] != model_registry.EMBEDDING_DIMENSION:
            raise ContractViolation(
                f"index dimension {matrix.shape[1]} != registry "
                f"{model_registry.EMBEDDING_DIMENSION}")
        if not -1.0 <= min_score <= 1.0:
            raise ContractViolation("min_score must be within [-1, 1]")
        if (embedder.model_id != model_registry.SELECTED_MODEL_ID
                or embedder.model_revision
                != model_registry.SELECTED_MODEL_REVISION):
            raise ContractViolation(
                "semantic retrieval requires the pinned registry model")
        self._matrix = np.ascontiguousarray(matrix, dtype=np.float32)
        self._ids = list(chunk_ids)
        self._row = {doc_id: i for i, doc_id in enumerate(self._ids)}
        self._manifest = dict(manifest)
        self._embedder = embedder
        self._min_score = float(min_score)

    @classmethod
    def load(cls, embedder: hf_embedder.HFEmbedder | None = None, *,
             min_score: float = DEFAULT_MIN_SCORE,
             index_path: Path = DEFAULT_INDEX_PATH,
             manifest_path: Path = DEFAULT_MANIFEST_PATH,
             expected_corpus_fingerprint: str | None = None,
             ) -> "SemanticRetriever":
        """Load + verify the persistent index (binding enforced)."""
        matrix, chunk_ids, manifest = load_artifact(
            index_path, manifest_path,
            expected_corpus_fingerprint=expected_corpus_fingerprint)
        return cls(matrix, chunk_ids, manifest,
                   embedder or hf_embedder.HFEmbedder(), min_score=min_score)

    @property
    def version(self) -> str:
        idx = str(self._manifest.get("embedding_fingerprint", ""))[:12]
        rev = model_registry.SELECTED_MODEL_REVISION[:12]
        return f"hf-semantic-{model_registry.SELECTED_MODEL_ID}@{rev}-idx{idx}"

    @property
    def min_score(self) -> float:
        return self._min_score

    @property
    def corpus_fingerprint(self) -> str:
        return str(self._manifest.get("corpus_fingerprint", ""))

    def _scoped_candidates(self, query: RagQuery,
                           corpus: list[RagDocument]) -> list[RagDocument]:
        candidates = apply_scope(corpus, query)
        difficulty = getattr(query, "difficulty", None)
        if difficulty is not None:
            candidates = [d for d in candidates
                          if d.difficulty == difficulty]
        return [d for d in candidates if d.is_active]

    def retrieve(self, query: RagQuery, corpus: list[RagDocument], *,
                 request_id: str) -> RetrievalResponse:
        if not request_id.strip():
            raise ContractViolation("request_id must be non-empty")
        if not corpus:
            return degraded_response(request_id, "empty_corpus",
                                     self.version)
        candidates = self._scoped_candidates(query, corpus)
        if not candidates:
            return degraded_response(request_id, "no_results_in_scope",
                                     self.version)
        try:
            query_vector = np.asarray(
                self._embedder.embed_query(query.query), dtype=np.float32)
        except ContractViolation:
            raise
        except EmbeddingFailure:
            raise
        except Exception as exc:
            raise EmbeddingFailure(
                f"query embedding failed: {exc}") from exc

        norm = float(np.linalg.norm(query_vector))
        if norm < 1e-12:
            return degraded_response(request_id, "insufficient_evidence",
                                     self.version)
        query_vector = query_vector / norm

        rows: list[int] = []
        docs: list[RagDocument] = []
        for doc in candidates:
            row = self._row.get(doc.doc_id)
            if row is None:
                continue  # unscorable (not in index) — skipped, never faked
            rows.append(row)
            docs.append(doc)
        if not docs:
            return degraded_response(request_id, "index_stale_for_scope",
                                     self.version)

        scores = self._matrix[np.asarray(rows)] @ query_vector
        ranked = sorted(zip(scores.tolist(), docs),
                        key=lambda item: (-item[0], item[1].doc_id))
        chunks: list[RetrievedChunk] = []
        for score, doc in ranked[:query.top_k]:
            if float(score) < self._min_score:
                continue
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
                score=float(score),
                citation=doc.citation,
                difficulty=doc.difficulty,
            ))
        if not chunks:
            return degraded_response(request_id, "insufficient_evidence",
                                     self.version)
        response = RetrievalResponse(
            request_id=request_id, served=True, chunks=tuple(chunks),
            retriever_version=self.version)
        response.validate_against(ScopeFilter(
            subject_id=query.subject_id, topic_id=query.topic_id,
            unit_id=query.unit_id))
        return response


__all__ = ["DEFAULT_MIN_SCORE", "SemanticQuery", "SemanticRetriever",
           "build_memory_index"]
