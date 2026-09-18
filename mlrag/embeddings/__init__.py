"""Pretrained Hugging Face embedding layer for GameLearnAI RAG (Gate 22).

Provenance rule (non-negotiable):

* GameLearnAI educational content (Gate 21 corpus) is the source of truth.
* Hugging Face supplies the pretrained embedding model ONLY.
* The model never supplies content, citations, scope, or policy.

Contents:

* ``model_registry`` — candidate evaluation + the single pinned selection.
* ``hf_embedder`` — deterministic local ``sentence-transformers`` adapter
  implementing the existing ``mlrag.rag.vectors.Embedder`` interface
  (``mlrag/rag/vectors.py`` is intentionally NOT modified, so Gate 6
  boundary tests keep passing).
* ``pipeline`` — deterministic corpus -> embedding artifact builder with
  corpus-fingerprint binding and stale/corrupt artifact detection.
"""
