"""Deterministic local Hugging Face embedder (Gate 22).

Implements the existing ``mlrag.rag.vectors.Embedder`` interface with a
pinned ``sentence-transformers`` model running locally on CPU:

* model identifier AND full commit revision are pinned — never "latest"
* local inference only — no hosted inference API on the retrieval path
* ``eval`` mode + ``torch.no_grad`` + fixed batching for reproducibility
* L2-normalized output so cosine similarity is a plain dot product
* any load/inference failure raises :class:`EmbeddingFailure` explicitly —
  there is deliberately NO fallback to random vectors, hash vectors, or
  lexical scores (see NO FAKE AI policy)
"""

from __future__ import annotations

from typing import Sequence

from mlrag.contracts.common import ContractViolation
from mlrag.rag.errors import EmbeddingFailure
from mlrag.rag.vectors import Embedder

from . import model_registry


def prepare_query_text(query: str) -> str:
    """Validate + deterministically bound untrusted query text.

    The query is treated as a search string only — never parsed for
    instructions, scope, or metadata.  Overlong input is truncated to
    ``MAX_QUERY_CHARS`` (documented, deterministic); empty/whitespace
    input is rejected loudly.
    """
    if not isinstance(query, str):
        raise ContractViolation("query must be a string")
    cleaned = query.strip()
    if not cleaned:
        raise ContractViolation("query must be non-empty")
    if len(cleaned) > model_registry.MAX_QUERY_CHARS:
        cleaned = cleaned[: model_registry.MAX_QUERY_CHARS]
    return cleaned


class HFEmbedder(Embedder):
    """Pinned local sentence-transformer embedder (CPU, normalized)."""

    def __init__(
        self,
        model_id: str = model_registry.SELECTED_MODEL_ID,
        revision: str = model_registry.SELECTED_MODEL_REVISION,
        *,
        device: str = "cpu",
        batch_size: int = 32,
        normalize: bool = model_registry.NORMALIZE_EMBEDDINGS,
    ) -> None:
        if not model_id.strip():
            raise ContractViolation("model_id must be non-empty")
        if not revision.strip():
            raise ContractViolation("model revision must be pinned "
                                    "(got empty revision)")
        if device.strip().lower() != "cpu":
            raise ContractViolation(
                "Gate 22 runs local CPU inference only "
                f"(got device={device!r})")
        if batch_size <= 0:
            raise ContractViolation("batch_size must be positive")
        self._model_id = model_id
        self._revision = revision
        self._device = "cpu"
        self._batch_size = batch_size
        self._normalize = bool(normalize)
        self._model: object | None = None
        self._actual_dim: int | None = None

    @property
    def model_id(self) -> str:
        return self._model_id

    @property
    def model_revision(self) -> str:
        return self._revision

    @property
    def dimension(self) -> int:
        if self._actual_dim is None:
            self._load()
        assert self._actual_dim is not None
        return self._actual_dim

    @property
    def version(self) -> str:
        short = self._revision[:12]
        norm = "norm" if self._normalize else "raw"
        return (f"hf-{self._model_id}@{short}"
                f"-dim{model_registry.EMBEDDING_DIMENSION}-{norm}-cosine")

    def _load(self) -> None:
        if self._model is not None:
            return
        try:
            import torch
            from sentence_transformers import SentenceTransformer
        except Exception as exc:
            raise EmbeddingFailure(
                "embedding dependencies unavailable "
                "(sentence-transformers/torch required): "
                f"{exc}") from exc
        try:
            torch.manual_seed(0)
            model = SentenceTransformer(
                self._model_id,
                revision=self._revision,
                device=self._device,
                trust_remote_code=False,
            )
            model.eval()
        except Exception as exc:
            raise EmbeddingFailure(
                f"pretrained model load failed: {self._model_id}@"
                f"{self._revision[:12]}: {exc}") from exc
        get_dim = getattr(model, "get_embedding_dimension",
                            getattr(model, "get_sentence_embedding_dimension"))
        actual_dim = int(get_dim())
        if actual_dim != model_registry.EMBEDDING_DIMENSION:
            raise EmbeddingFailure(
                f"embedding dimension mismatch: model reports "
                f"{actual_dim}, registry pins "
                f"{model_registry.EMBEDDING_DIMENSION}")
        self._model = model
        self._actual_dim = actual_dim

    def embed(self, texts: Sequence[str]) -> list[list[float]]:
        """Embed texts deterministically.  One vector per input, in order."""
        items = list(texts)
        if not items:
            raise ContractViolation("embed requires at least one text")
        for text in items:
            if not isinstance(text, str) or not text.strip():
                raise ContractViolation(
                    "embed inputs must be non-empty strings")
        self._load()
        assert self._model is not None
        try:
            import torch
            import numpy as np

            with torch.no_grad():
                vectors = self._model.encode(
                    items,
                    batch_size=self._batch_size,
                    show_progress_bar=False,
                    convert_to_numpy=True,
                    normalize_embeddings=self._normalize,
                )
            matrix = np.asarray(vectors, dtype=np.float64)
        except EmbeddingFailure:
            raise
        except Exception as exc:
            raise EmbeddingFailure(f"embedding inference failed: {exc}"
                                   ) from exc
        if matrix.shape != (len(items), model_registry.EMBEDDING_DIMENSION):
            raise EmbeddingFailure(
                f"unexpected embedding shape {matrix.shape}")
        if not bool((matrix == matrix).all()):
            raise EmbeddingFailure("embedding produced NaN values")
        return matrix.astype(float).tolist()

    def embed_query(self, query: str) -> list[float]:
        """Embed a single untrusted query string (validated + bounded)."""
        return self.embed([prepare_query_text(query)])[0]


__all__ = ["HFEmbedder", "prepare_query_text"]
