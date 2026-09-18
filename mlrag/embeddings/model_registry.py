"""Model registry for Gate 22: candidate evaluation + pinned selection.

Selection policy (evidence-based, recorded here — not popularity-based):

* semantic-search suitability for short/medium educational passages
* CPU/local-development feasibility (small parameter count, fast inference)
* symmetric encoding (no query/document prefix tricks that add bug surface)
* reproducible inference (deterministic pooling, pinned revision)
* acceptable license (Apache-2.0 / MIT only)
* stable Hugging Face provenance (established publisher, safetensors weights)

Candidate evidence was collected live from the Hugging Face Hub
(model SHAs resolved via ``huggingface_hub.model_info``; hidden sizes read
from each repo's ``config.json``) on the implementation machine.
Only ``config.json`` metadata was fetched for non-selected candidates —
no weights were downloaded for models that were not selected.
"""

from __future__ import annotations

#: Exact pinned selection.  Never "latest".
SELECTED_MODEL_ID = "sentence-transformers/all-MiniLM-L6-v2"
#: Full commit SHA of the selected model repo (resolved via Hub API).
SELECTED_MODEL_REVISION = "1110a243fdf4706b3f48f1d95db1a4f5529b4d41"

EMBEDDING_DIMENSION = 384
MODEL_LICENSE = "Apache-2.0"
NORMALIZE_EMBEDDINGS = True
SIMILARITY_METRIC = "cosine"
INDEX_FORMAT = "glr-hf-index-v1"
INDEX_VERSION = "1"
#: Two runs over the same corpus+model+config must agree within this bound
#: (max absolute element difference on float32 vectors).
NUMERICAL_TOLERANCE = 1e-6
#: Query text longer than this is deterministically truncated before
#: embedding (mirrors ``mlrag.contracts.retriever._MAX_QUERY_CHARS``).
MAX_QUERY_CHARS = 2000

CANDIDATES: tuple[dict[str, object], ...] = (
    {
        "model_id": "sentence-transformers/all-MiniLM-L6-v2",
        "revision": "1110a243fdf4706b3f48f1d95db1a4f5529b4d41",
        "embedding_dimension": 384,
        "approx_params": "~22M (~80MB safetensors)",
        "license": "Apache-2.0",
        "intended_task": "sentence similarity / semantic search "
                         "(symmetric encoder)",
        "query_document_encoding": "none required — same encoder, "
                                   "no prefixes",
        "cpu_feasible": True,
        "expected_memory": "~300MB RSS for model + 413x384 float32 index "
                           "(~0.6MB vectors)",
        "limitations": "384-dim ceiling on fine nuance; 256-token "
                       "truncation on very long passages; English-centric",
        "selected": True,
        "selection_reason": "Best fit for 413 short/medium educational "
                            "chunks: smallest footprint, fastest CPU "
                            "inference, no prefix protocol (smallest bug "
                            "surface), permissive Apache-2.0 license, "
                            "long-stable provenance.",
    },
    {
        "model_id": "BAAI/bge-small-en-v1.5",
        "revision": "5c38ec7c405ec4b44b94cc5a9bb96e735b38267a",
        "embedding_dimension": 384,
        "approx_params": "~33M (~133MB)",
        "license": "MIT",
        "intended_task": "retrieval / reranking / semantic search",
        "query_document_encoding": "asymmetric best practice needs the "
                                   "'Represent this sentence for searching "
                                   "relevant passages:' query instruction "
                                   "for full quality",
        "cpu_feasible": True,
        "expected_memory": "~450MB RSS for model",
        "limitations": "quality depends on instruction-prefix protocol; "
                       "larger than MiniLM with equal dimension; prefix "
                       "mismatch between query and document encoding is a "
                       "silent-quality-loss risk",
        "selected": False,
        "selection_reason": "Rejected: equal dimension at ~1.6x the size "
                            "with an asymmetric prefix protocol that adds "
                            "failure modes for no proven gain on this "
                            "corpus size.",
    },
    {
        "model_id": "intfloat/e5-small-v2",
        "revision": "ffb93f3bd4047442299a41ebb6fa998a38507c52",
        "embedding_dimension": 384,
        "approx_params": "~33M (~118MB)",
        "license": "MIT",
        "intended_task": "text embeddings / retrieval (contrastive)",
        "query_document_encoding": "REQUIRES 'query: ' / 'passage: ' "
                                   "prefixes — unprefixed use is "
                                   "off-distribution",
        "cpu_feasible": True,
        "expected_memory": "~420MB RSS for model",
        "limitations": "mandatory prefix protocol; silent degradation when "
                       "prefixes are omitted or mixed; no benefit over "
                       "symmetric encoders at 413 documents",
        "selected": False,
        "selection_reason": "Rejected: mandatory prefix protocol is an "
                            "unnecessary correctness hazard for this "
                            "pipeline; equal dimension at larger size.",
    },
    {
        "model_id": "sentence-transformers/all-mpnet-base-v2",
        "revision": "e8c3b32edf5434bc2275fc9bab85f82640a19130",
        "embedding_dimension": 768,
        "approx_params": "~109M (~420MB)",
        "license": "Apache-2.0",
        "intended_task": "sentence similarity / semantic search "
                         "(higher quality, symmetric)",
        "query_document_encoding": "none required — same encoder, "
                                   "no prefixes",
        "cpu_feasible": "marginal — ~5x the weights of MiniLM, "
                        "noticeably slower CPU encode",
        "expected_memory": "~1.2GB RSS for model + 2x index width",
        "limitations": "5x model size and 2x index width for a quality "
                       "delta that is unmeasurable at 413 short passages "
                       "without human relevance judgments",
        "selected": False,
        "selection_reason": "Rejected: 5x size / 2x dimension with no "
                            "evidence of measurable gain on this corpus; "
                            "violates the 'no unnecessary weight' rule. "
                            "Revisit only with measured recall gaps.",
    },
)

EXPECTED_GATE21_FINGERPRINT = (
    "451ddef72317c230f7f59a873e7ec8595068ae5c0277dca6bac1b900a946f2b9"
)
EXPECTED_GATE21_CHUNKS = 413


def selected_candidate() -> dict[str, object]:
    """Return the single selected candidate record."""
    for candidate in CANDIDATES:
        if candidate.get("selected") is True:
            return dict(candidate)
    raise AssertionError("registry must contain exactly one selection")


__all__ = [
    "CANDIDATES",
    "EMBEDDING_DIMENSION",
    "EXPECTED_GATE21_CHUNKS",
    "EXPECTED_GATE21_FINGERPRINT",
    "INDEX_FORMAT",
    "INDEX_VERSION",
    "MAX_QUERY_CHARS",
    "MODEL_LICENSE",
    "NORMALIZE_EMBEDDINGS",
    "NUMERICAL_TOLERANCE",
    "SELECTED_MODEL_ID",
    "SELECTED_MODEL_REVISION",
    "SIMILARITY_METRIC",
    "selected_candidate",
]
