"""Offline RAG foundation (GATE 6). Deterministic, provenance-preserving,
scope-safe retrieval groundwork. No vector database, no embeddings service,
no LLM calls, no production wiring. Spring Boot remains authoritative."""

from . import (chunking, documents, errors, extract_corpus, grounding,
               ingest, retrieval, safety, vectors)

__all__ = ["chunking", "documents", "errors", "extract_corpus",
           "grounding", "ingest", "retrieval", "safety", "vectors"]
