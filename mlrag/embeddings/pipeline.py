"""Deterministic embedding/index build pipeline (Gate 22).

Flow::

    Gate 21 corpus artifact (canonical JSON, 413 serving chunks)
        -> stable chunk ordering (sorted by chunk_id)
        -> forbidden-field audit (learner state must never be embedded)
        -> pinned HF embedding model (local CPU)
        -> L2-normalized float32 matrix, one row per chunk
        -> persistent artifact: .npz vectors + JSON manifest

Binding rule: the manifest records the exact Gate 21 corpus fingerprint.
Loading verifies the binding — a fingerprint mismatch raises
:class:`StaleEmbeddingArtifact` instead of silently serving stale vectors.
Corruption (shape/dtype/fingerprint mismatch) raises
:class:`CorruptEmbeddingArtifact`.  Neither failure ever fabricates vectors.
"""

from __future__ import annotations

import hashlib
import importlib.metadata
import json
import platform
import time
from datetime import datetime, timezone
from pathlib import Path

import numpy as np

from mlrag.contracts.common import ContractViolation
from mlrag.corpus.contract import FORBIDDEN_COLUMNS, validate_chunk_record
from mlrag.rag.errors import RagError

from . import hf_embedder, model_registry

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
DEFAULT_CORPUS_PATH = (REPO_ROOT / "mlrag" / "artifacts"
                       / "gate21_corpus.json")
DEFAULT_INDEX_PATH = (REPO_ROOT / "mlrag" / "artifacts"
                      / "gate22_hf_index.npz")
DEFAULT_MANIFEST_PATH = (REPO_ROOT / "mlrag" / "artifacts"
                         / "gate22_hf_index_manifest.json")


class StaleEmbeddingArtifact(RagError):
    """Index was built from a different corpus fingerprint.  Rebuild."""


class CorruptEmbeddingArtifact(RagError):
    """Index bytes fail integrity verification.  Rebuild."""


def _canonical(value: object) -> str:
    return json.dumps(value, sort_keys=True, ensure_ascii=False,
                      separators=(",", ":"))


def _sha256_hex(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def library_versions() -> dict[str, str]:
    """Record exact runtime library versions for reproducibility."""
    versions: dict[str, str] = {}
    for dist in ("sentence-transformers", "transformers", "torch", "numpy",
                 "tokenizers", "safetensors", "huggingface-hub",
                 "scikit-learn"):
        try:
            versions[dist] = importlib.metadata.version(dist)
        except importlib.metadata.PackageNotFoundError:
            versions[dist] = "not-installed"
    versions["python"] = platform.python_version()
    return versions


def load_gate21_chunks(corpus_path: Path = DEFAULT_CORPUS_PATH
                       ) -> tuple[list[dict], str]:
    """Load + validate the authoritative Gate 21 serving chunks.

    Returns ``(chunks_sorted_by_chunk_id, corpus_fingerprint)``.
    The Gate 21 artifact is never mutated; validation reuses the
    existing ``validate_chunk_record`` contract plus a forbidden-key
    audit so learner-state fields can never enter the embedding path.
    """
    raw = json.loads(Path(corpus_path).read_text(encoding="utf-8"))
    fingerprint = raw.get("fingerprint")
    chunks = raw.get("chunks")
    if not isinstance(fingerprint, str) or not fingerprint.strip():
        raise ContractViolation(
            f"corpus artifact {corpus_path} carries no fingerprint")
    if not isinstance(chunks, list) or not chunks:
        raise ContractViolation(
            f"corpus artifact {corpus_path} carries no chunks")
    for record in chunks:
        validate_chunk_record(record)
        leaked = sorted(set(record.keys()) & set(FORBIDDEN_COLUMNS))
        if leaked:
            raise ContractViolation(
                "forbidden learner-state keys in corpus record "
                f"{record.get('chunk_id')}: " + ",".join(leaked))
        if record.get("is_active") is not True:
            raise ContractViolation(
                f"inactive chunk in serving corpus: {record.get('chunk_id')}")
    ordered = sorted(chunks, key=lambda c: c["chunk_id"])
    ids = [c["chunk_id"] for c in ordered]
    if len(set(ids)) != len(ids):
        raise ContractViolation("duplicate chunk_id in serving corpus")
    return ordered, fingerprint


def config_fingerprint(versions: dict[str, str]) -> str:
    """Fingerprint of everything that must be fixed for reproducibility."""
    payload = {
        "model_id": model_registry.SELECTED_MODEL_ID,
        "model_revision": model_registry.SELECTED_MODEL_REVISION,
        "embedding_dimension": model_registry.EMBEDDING_DIMENSION,
        "normalize": model_registry.NORMALIZE_EMBEDDINGS,
        "similarity": model_registry.SIMILARITY_METRIC,
        "index_format": model_registry.INDEX_FORMAT,
        "index_version": model_registry.INDEX_VERSION,
        "max_query_chars": model_registry.MAX_QUERY_CHARS,
        "library_versions": versions,
    }
    return _sha256_hex(_canonical(payload).encode("utf-8"))


def embedding_fingerprint(matrix: np.ndarray) -> str:
    """Fingerprint over raw float32 bytes in stable chunk order."""
    contiguous = np.ascontiguousarray(matrix, dtype=np.float32)
    return _sha256_hex(contiguous.tobytes())


def build_artifact(
    corpus_path: Path = DEFAULT_CORPUS_PATH,
    index_path: Path = DEFAULT_INDEX_PATH,
    manifest_path: Path = DEFAULT_MANIFEST_PATH,
    *,
    batch_size: int = 32,
    embedder: hf_embedder.HFEmbedder | None = None,
) -> dict:
    """Embed the full Gate 21 corpus and persist index + manifest."""
    started = time.perf_counter()
    chunks, corpus_fp = load_gate21_chunks(corpus_path)
    own_embedder = embedder if embedder is not None else hf_embedder.HFEmbedder(
        batch_size=batch_size)
    if (own_embedder.model_id != model_registry.SELECTED_MODEL_ID
            or own_embedder.model_revision
            != model_registry.SELECTED_MODEL_REVISION):
        raise ContractViolation(
            "embedding pipeline requires the pinned registry model; "
            f"got {own_embedder.model_id}@{own_embedder.model_revision[:12]}")

    texts = [c["text"] for c in chunks]
    encode_started = time.perf_counter()
    rows = own_embedder.embed(texts)
    encode_ms = (time.perf_counter() - encode_started) * 1000.0
    matrix = np.asarray(rows, dtype=np.float32)
    if matrix.shape != (len(chunks), model_registry.EMBEDDING_DIMENSION):
        raise CorruptEmbeddingArtifact(
            f"unexpected embedding matrix shape {matrix.shape}")
    norms = np.linalg.norm(matrix, axis=1)
    if not bool(((norms > 1e-6) & (norms < 1e6)).all()):
        raise CorruptEmbeddingArtifact("embedding norms out of range")

    versions = library_versions()
    manifest = {
        "artifact": "gate22_hf_semantic_index",
        "index_format": model_registry.INDEX_FORMAT,
        "index_version": model_registry.INDEX_VERSION,
        "model_id": model_registry.SELECTED_MODEL_ID,
        "model_revision": model_registry.SELECTED_MODEL_REVISION,
        "model_license": model_registry.MODEL_LICENSE,
        "embedding_dimension": model_registry.EMBEDDING_DIMENSION,
        "normalize_embeddings": model_registry.NORMALIZE_EMBEDDINGS,
        "similarity_metric": model_registry.SIMILARITY_METRIC,
        "embedder_version": own_embedder.version,
        "corpus_artifact": str(corpus_path),
        "corpus_fingerprint": corpus_fp,
        "corpus_size": len(chunks),
        "chunk_ids_sha256": _sha256_hex(
            _canonical([c["chunk_id"] for c in chunks]).encode("utf-8")),
        "embedding_fingerprint": embedding_fingerprint(matrix),
        "config_fingerprint": config_fingerprint(versions),
        "library_versions": versions,
        "numerical_tolerance": model_registry.NUMERICAL_TOLERANCE,
        "created_at_utc": datetime.now(timezone.utc).isoformat(),
        "build_ms_total": round((time.perf_counter() - started) * 1000.0, 1),
        "encode_ms": round(encode_ms, 1),
    }

    chunk_ids = [c["chunk_id"] for c in chunks]
    width = max(64, max(len(i) for i in chunk_ids))
    index_path.parent.mkdir(parents=True, exist_ok=True)
    np.savez_compressed(
        index_path,
        embeddings=np.ascontiguousarray(matrix, dtype=np.float32),
        chunk_ids=np.asarray(chunk_ids, dtype=f"<U{width}"),
        format=np.asarray([model_registry.INDEX_FORMAT]),
    )
    manifest["index_bytes"] = int(index_path.stat().st_size)
    manifest_path.write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")
    manifest["manifest_path"] = str(manifest_path)
    manifest["index_path"] = str(index_path)
    return manifest


def load_artifact(
    index_path: Path = DEFAULT_INDEX_PATH,
    manifest_path: Path = DEFAULT_MANIFEST_PATH,
    *,
    expected_corpus_fingerprint: str | None = None,
) -> tuple[np.ndarray, list[str], dict]:
    """Load + verify the persistent index.

    Verifies format pin, shape/dtype, chunk-id binding, and the embedding
    fingerprint.  When ``expected_corpus_fingerprint`` is given (normally
    read from the live Gate 21 artifact), a mismatch raises
    :class:`StaleEmbeddingArtifact` — stale vectors are never served.
    """
    if not index_path.exists():
        raise CorruptEmbeddingArtifact(
            f"index missing at {index_path}: rebuild required")
    if not manifest_path.exists():
        raise CorruptEmbeddingArtifact(
            f"index manifest missing at {manifest_path}: rebuild required")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("index_format") != model_registry.INDEX_FORMAT:
        raise CorruptEmbeddingArtifact(
            f"unknown index format {manifest.get('index_format')!r}")
    if manifest.get("model_id") != model_registry.SELECTED_MODEL_ID:
        raise CorruptEmbeddingArtifact(
            f"index built with unexpected model {manifest.get('model_id')!r}")
    if manifest.get("model_revision") != model_registry.SELECTED_MODEL_REVISION:
        raise CorruptEmbeddingArtifact("index model revision mismatch")
    if manifest.get("embedding_dimension") != model_registry.EMBEDDING_DIMENSION:
        raise CorruptEmbeddingArtifact("index dimension mismatch")
    if (expected_corpus_fingerprint is not None
            and manifest.get("corpus_fingerprint")
            != expected_corpus_fingerprint):
        raise StaleEmbeddingArtifact(
            "corpus fingerprint changed "
            f"(index={str(manifest.get('corpus_fingerprint'))[:12]} "
            f"live={expected_corpus_fingerprint[:12]}): rebuild required")
    try:
        with np.load(index_path, allow_pickle=False) as data:
            matrix = np.asarray(data["embeddings"], dtype=np.float32)
            chunk_ids = [str(i) for i in data["chunk_ids"].tolist()]
            fmt = str(np.asarray(data["format"]).flatten()[0])
    except Exception as exc:
        raise CorruptEmbeddingArtifact(
            f"index unreadable: {exc}") from exc
    if fmt != model_registry.INDEX_FORMAT:
        raise CorruptEmbeddingArtifact(f"index payload format {fmt!r}")
    if matrix.shape != (len(chunk_ids), model_registry.EMBEDDING_DIMENSION):
        raise CorruptEmbeddingArtifact(
            f"index shape {matrix.shape} vs {len(chunk_ids)} ids")
    if embedding_fingerprint(matrix) != manifest.get("embedding_fingerprint"):
        raise CorruptEmbeddingArtifact("index embedding bytes changed")
    if (_sha256_hex(_canonical(chunk_ids).encode("utf-8"))
            != manifest.get("chunk_ids_sha256")):
        raise CorruptEmbeddingArtifact("index chunk-id binding broken")
    return matrix, chunk_ids, manifest


def verify_binding_against_live_corpus(
    manifest: dict,
    corpus_path: Path = DEFAULT_CORPUS_PATH,
) -> dict:
    """Compare a manifest's corpus fingerprint to the live artifact."""
    raw = json.loads(Path(corpus_path).read_text(encoding="utf-8"))
    live_fp = raw.get("fingerprint")
    bound = manifest.get("corpus_fingerprint") == live_fp
    return {"bound": bound, "index_fp": manifest.get("corpus_fingerprint"),
            "live_fp": live_fp}


__all__ = [
    "CorruptEmbeddingArtifact",
    "StaleEmbeddingArtifact",
    "build_artifact",
    "config_fingerprint",
    "embedding_fingerprint",
    "library_versions",
    "load_artifact",
    "load_gate21_chunks",
    "verify_binding_against_live_corpus",
]
