"""Shared fixtures for Gate 22 tests (labeled fixtures only, no DB)."""

from __future__ import annotations

from pathlib import Path

from mlrag.rag.documents import RagDocument

FIX = "g22-fixture"

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
CORPUS_PATH = REPO_ROOT / "mlrag" / "artifacts" / "gate21_corpus.json"
INDEX_PATH = REPO_ROOT / "mlrag" / "artifacts" / "gate22_hf_index.npz"
MANIFEST_PATH = (REPO_ROOT / "mlrag" / "artifacts"
                 / "gate22_hf_index_manifest.json")
DATASET_PATH = (REPO_ROOT / "mlrag" / "evaluation"
                / "gate22_hf_eval_dataset.json")
RESULTS_PATH = (REPO_ROOT / "mlrag" / "artifacts"
                / "gate22_hf_retrieval_results.json")

_embedder = None


def get_embedder():
    """Process-wide shared REAL embedder (model loads once)."""
    global _embedder
    if _embedder is None:
        from mlrag.embeddings.hf_embedder import HFEmbedder
        _embedder = HFEmbedder()
    return _embedder


def fixture_doc(index: int, subject: str = f"{FIX}-s1",
                topic: str = f"{FIX}-t1", text: str = "sample content",
                active: bool = True, **over) -> RagDocument:
    kwargs = {
        "doc_id": f"lessons:{FIX}-l{index}#c0",
        "source_table": "lessons",
        "source_id": f"{FIX}-l{index}",
        "text": text,
        "subject_id": subject,
        "topic_id": topic,
        "is_active": active,
        "unit_id": f"{FIX}-u1",
        "lesson_id": f"{FIX}-l{index}",
        "content_version": "2026-01-01T00:00:00",
    }
    kwargs.update(over)
    return RagDocument(**kwargs)


def fixture_corpus() -> list[RagDocument]:
    """Three distinct-topic docs across two subjects (deterministic)."""
    return [
        fixture_doc(1, text="Photosynthesis converts light energy into "
                            "chemical energy in plant leaves using "
                            "chlorophyll."),
        fixture_doc(2, topic=f"{FIX}-t2",
                    text="Routers forward packets by longest-prefix match "
                         "against a routing table of network prefixes."),
        fixture_doc(3, subject=f"{FIX}-s2", topic=f"{FIX}-t9",
                    text="Mitochondria produce cellular energy currency in "
                         "animal cells through respiration."),
    ]


def fixture_retriever(min_score: float = 0.20):
    """SemanticRetriever over the fixture corpus with REAL embeddings."""
    from mlrag.retrieval.semantic import SemanticRetriever, build_memory_index
    docs = fixture_corpus()
    matrix, ids = build_memory_index([d.doc_id for d in docs],
                                     [d.text for d in docs], get_embedder())
    return SemanticRetriever(matrix, ids,
                             {"embedding_fingerprint": "fixture",
                              "corpus_fingerprint": "fixture"},
                             get_embedder(), min_score=min_score), docs
