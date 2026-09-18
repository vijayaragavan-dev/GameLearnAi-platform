"""Production-grade RAG corpus ingestion (GATE 21).

Educational knowledge only, grounded in the authoritative MySQL catalogue
(subjects / units / topics / lessons / questions).  This package builds a
deterministic, versioned, scope-aware, provenance-preserving corpus on top
of the compatible Gate 6 primitives in :mod:`mlrag.rag` — document shapes,
chunking policy, active filtering, and the trust boundary are reused, never
duplicated or silently changed.

Stages:

1. :mod:`mlrag.corpus.contract` — corpus/document/chunk/ingestion
   versions, approved sources, forbidden tables/columns, chunk policy
   (reused sizes), chunk-record schema validation.
2. :mod:`mlrag.corpus.normalize` — deterministic normalization (NFC,
   line endings, blank-line collapsing) with separate original/normalized
   SHA-256 hashes.  Meaning is never rewritten.
3. :mod:`mlrag.corpus.screening` — ingestion-time suspicious-content
   classification (reason codes + quarantine verdicts, never silent
   deletion) and PII/secret scanning.
4. :mod:`mlrag.corpus.build` — extraction-shape input -> validated chunk
   records: scope-integrity enforcement, duplicate detection/reporting
   (never silent merging), quarantine routing, corpus fingerprint, source
   snapshot metadata for staleness detection.
5. :mod:`mlrag.corpus.snapshot` — live read-only runner producing the
   PII-free corpus artifact.

Learner state never enters the corpus.  No embeddings, no vector store,
no retrieval, no LLM calls, no web content in this gate.
"""

from .contract import (
    CHUNK_VERSION,
    CORPUS_VERSION,
    DOCUMENT_VERSION,
    INGESTION_VERSION,
)

__all__ = [
    "CHUNK_VERSION",
    "CORPUS_VERSION",
    "DOCUMENT_VERSION",
    "INGESTION_VERSION",
]
