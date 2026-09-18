"""Minimal localhost RAG evidence sidecar (Gate 23).

Exposes the ALREADY-VALIDATED Gate 22 retrieval stack over a tiny
loopback HTTP boundary so Spring Boot can request scoped evidence
without duplicating retrieval logic:

    POST /retrieve  (Bearer service token)
    GET  /healthz   (unauthenticated operational pins only)

Design constraints (no over-engineering):

* standard library ONLY (http.server + json + hmac) — no FastAPI, no
  new dependencies, no vector DB, no GPU stack
* binds loopback by default; refuses non-loopback binds unless
  explicitly allowed via environment
* read-only: NO corpus/index write or rebuild endpoints exist
* loads the pinned model + verifies index binding at STARTUP; any
  failure exits non-zero instead of serving fake/degraded vectors
* request logs carry ids/counts/latency ONLY — never query text,
  never evidence text, never the service token

Environment:

* RAG_SIDECAR_PORT (default 8431)
* RAG_SIDECAR_HOST (default 127.0.0.1; non-loopback requires
  RAG_SIDECAR_ALLOW_NON_LOOPBACK=1)
* RAG_SIDECAR_TOKEN (REQUIRED — process exits without it)
* RAG_CORPUS_PATH / RAG_INDEX_PATH / RAG_MANIFEST_PATH (defaults point
  at the committed Gate 21/22 artifacts)
"""

from __future__ import annotations

import hashlib
import hmac
import json
import logging
import os
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO_ROOT))

from mlrag.contracts.common import ContractViolation  # noqa: E402
from mlrag.contracts.retriever import ScopeFilter  # noqa: E402
from mlrag.embeddings import model_registry  # noqa: E402
from mlrag.embeddings.hf_embedder import HFEmbedder, prepare_query_text  # noqa: E402
from mlrag.embeddings.pipeline import (DEFAULT_INDEX_PATH,  # noqa: E402
                                       DEFAULT_MANIFEST_PATH, load_artifact,
                                       load_gate21_chunks)
from mlrag.rag.errors import EmbeddingFailure, RagError  # noqa: E402
from mlrag.rag.retrieval import RagQuery  # noqa: E402
from mlrag.retrieval import evidence as evidence_mod  # noqa: E402
from mlrag.retrieval.corpus_adapter import corpus_to_documents  # noqa: E402
from mlrag.retrieval.semantic import SemanticRetriever  # noqa: E402

SIDECAR_VERSION = "rag-sidecar-v1"
MAX_BODY_BYTES = 32 * 1024
MAX_ID_CHARS = 128
DEFAULT_TOP_K = 5
MAX_TOP_K = 10

log = logging.getLogger("rag_sidecar")


class SidecarState:
    """Startup-verified retrieval stack (never partially initialized)."""

    def __init__(self, corpus_path: Path, index_path: Path,
                 manifest_path: Path) -> None:
        chunks, corpus_fp = load_gate21_chunks(corpus_path)
        documents = corpus_to_documents(chunks)
        embedder = HFEmbedder()
        # Warm the model now: startup succeeds only with a PROVEN
        # load+inference path, so the first request never pays load cost
        # and a broken model can never serve traffic.
        embedder.embed(["sidecar startup warmup"])
        retriever = SemanticRetriever.load(
            embedder,
            index_path=index_path,
            manifest_path=manifest_path,
            expected_corpus_fingerprint=corpus_fp,
        )
        self.documents = documents
        self.retriever = retriever
        self.corpus_fingerprint = corpus_fp
        with open(manifest_path, encoding="utf-8") as handle:
            manifest = json.load(handle)
        self.manifest = manifest

    def to_health(self) -> dict:
        return {
            "status": "ok",
            "sidecar_version": SIDECAR_VERSION,
            "model_id": model_registry.SELECTED_MODEL_ID,
            "model_revision": model_registry.SELECTED_MODEL_REVISION,
            "embedding_dimension": model_registry.EMBEDDING_DIMENSION,
            "similarity": model_registry.SIMILARITY_METRIC,
            "corpus_fingerprint": self.corpus_fingerprint,
            "embedding_fingerprint":
                self.manifest.get("embedding_fingerprint"),
            "index_format": model_registry.INDEX_FORMAT,
            "chunk_count": len(self.documents),
        }


def _string_field(body: dict, name: str, *, required: bool) -> str | None:
    value = body.get(name)
    if value is None:
        if required:
            raise ContractViolation(f"{name} is required")
        return None
    if not isinstance(value, str) or not value.strip():
        if not required:
            return None  # blank optional scope == absent scope
        raise ContractViolation(f"{name} must be a non-empty string")
    if len(value) > MAX_ID_CHARS and name != "query":
        raise ContractViolation(f"{name} exceeds maximum length")
    return value.strip()


def _difficulty_field(body: dict) -> str | None:
    value = body.get("difficulty")
    if value is None:
        return None
    if value not in ("EASY", "MEDIUM", "HARD"):
        raise ContractViolation("difficulty must be EASY, MEDIUM or HARD")
    return value


def handle_retrieve(state: SidecarState, body: dict) -> tuple[int, dict]:
    """Serve one retrieval as an evidence bundle (or explicit degraded)."""
    from mlrag.contracts.common import Difficulty
    request_id = _string_field(body, "request_id", required=True)
    raw_query = _string_field(body, "query", required=True)
    subject_id = _string_field(body, "subject_id", required=True)
    topic_id = _string_field(body, "topic_id", required=False)
    unit_id = _string_field(body, "unit_id", required=False)
    difficulty_raw = _difficulty_field(body)
    top_k = body.get("top_k", DEFAULT_TOP_K)
    if not isinstance(top_k, int) or not 1 <= top_k <= MAX_TOP_K:
        raise ContractViolation("top_k must be an integer within 1..10")

    started = time.perf_counter()
    query = RagQuery(query=prepare_query_text(raw_query),
                     subject_id=subject_id, topic_id=topic_id,
                     unit_id=unit_id, top_k=top_k)
    if difficulty_raw is not None:
        from mlrag.retrieval.semantic import SemanticQuery
        query = SemanticQuery(query=query.query, subject_id=subject_id,
                              topic_id=topic_id, unit_id=unit_id,
                              top_k=top_k,
                              difficulty=Difficulty(difficulty_raw))
    response = state.retriever.retrieve(
        query, state.documents, request_id=request_id or "sidecar")
    latency_ms = round((time.perf_counter() - started) * 1000.0, 2)
    outcome = "served" if response.served else response.empty_reason
    log.info(json.dumps({
        "request_id": request_id, "outcome": outcome,
        "chunks": len(response.chunks),
        "subject_id": subject_id, "topic_id": topic_id,
        "latency_ms": latency_ms,
        "model": model_registry.SELECTED_MODEL_ID,
        "corpus_fp8": state.corpus_fingerprint[:8],
    }))
    if not response.served:
        return 200, {
            "served": False,
            "request_id": request_id,
            "empty_reason": response.empty_reason,
            "retriever_version": response.retriever_version,
            "corpus_fingerprint": state.corpus_fingerprint,
            "chunks": [],
            "latency_ms": latency_ms,
        }
    bundle = evidence_mod.build_evidence_bundle(
        response, ScopeFilter(subject_id=subject_id, topic_id=topic_id,
                              unit_id=unit_id),
        corpus_fingerprint=state.corpus_fingerprint,
        retriever_version=response.retriever_version)
    payload_chunks = []
    for item in bundle["chunks"]:
        # Server-side bundle carries delimited text; the HTTP payload
        # carries raw text + citation (Spring applies the SAME delimiter
        # policy via sanitizeUntrusted before prompt assembly).
        source = next(d for d in state.documents
                      if d.doc_id == item["chunk_id"])
        payload_chunks.append({
            "chunk_id": item["chunk_id"],
            "citation": item["citation"],
            "source_table": item["source_table"],
            "source_id": item["source_id"],
            "subject_id": item["subject_id"],
            "topic_id": item["topic_id"],
            "unit_id": item["unit_id"],
            "content_version": item["content_version"],
            "difficulty": item["difficulty"],
            "score": item["score"],
            "text": source.text,
        })
    return 200, {
        "served": True,
        "request_id": request_id,
        "empty_reason": "",
        "retriever_version": response.retriever_version,
        "corpus_fingerprint": state.corpus_fingerprint,
        "citations": bundle["citations"],
        "chunks": payload_chunks,
        "latency_ms": latency_ms,
    }


class Handler(BaseHTTPRequestHandler):
    state: SidecarState | None = None
    token_hash: bytes = b""

    def log_message(self, format, *args):  # quiet; we log JSON lines
        return

    def _send(self, status: int, payload: dict) -> None:
        raw = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def _authorized(self) -> bool:
        header = self.headers.get("Authorization", "")
        if not header.startswith("Bearer "):
            return False
        presented = header[len("Bearer "):].strip().encode("utf-8")
        expected = hashlib.sha256(self.token_hash).digest()
        # NOTE: token_hash stores sha256(token); compare digests.
        given = hashlib.sha256(presented).digest()
        return hmac.compare_digest(given, expected)

    def do_GET(self) -> None:
        if urlparse(self.path).path == "/healthz":
            state = type(self).state
            if state is None:
                self._send(503, {"status": "degraded",
                                 "reason": "not_initialized"})
                return
            self._send(200, state.to_health())
            return
        self._send(404, {"error": "not_found"})

    def do_POST(self) -> None:
        if urlparse(self.path).path != "/retrieve":
            self._send(404, {"error": "not_found"})
            return
        if not self._authorized():
            self._send(401, {"error": "unauthorized"})
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            length = 0
        if length <= 0 or length > MAX_BODY_BYTES:
            self._send(400, {"error": "invalid_content_length"})
            return
        try:
            body = json.loads(self.rfile.read(length).decode("utf-8"))
        except Exception:
            self._send(400, {"error": "malformed_json"})
            return
        if not isinstance(body, dict):
            self._send(400, {"error": "malformed_json"})
            return
        try:
            state = type(self).state
            if state is None:
                self._send(503, {"error": "retrieval_unavailable"})
                return
            status, payload = handle_retrieve(state, body)
            self._send(status, payload)
        except ContractViolation as exc:
            self._send(400, {"error": "invalid_request", "detail": str(exc)})
        except (EmbeddingFailure, RagError) as exc:
            log.warning("retrieval backend failure: %s", type(exc).__name__)
            self._send(503, {"error": "retrieval_unavailable"})
        except Exception:  # never leak internals; never fabricate evidence
            log.exception("unexpected retrieval failure")
            self._send(503, {"error": "retrieval_unavailable"})

    def do_PUT(self):  # no write endpoints exist, by design
        self._send(404, {"error": "not_found"})

    def do_DELETE(self):
        self._send(404, {"error": "not_found"})

    def do_PATCH(self):
        self._send(404, {"error": "not_found"})


def build_server() -> tuple[ThreadingHTTPServer, str]:
    host = os.environ.get("RAG_SIDECAR_HOST", "127.0.0.1")
    allow_remote = os.environ.get(
        "RAG_SIDECAR_ALLOW_NON_LOOPBACK", "0").strip() == "1"
    if host not in ("127.0.0.1", "localhost", "::1") and not allow_remote:
        print("refusing non-loopback bind without "
              "RAG_SIDECAR_ALLOW_NON_LOOPBACK=1", file=sys.stderr)
        sys.exit(2)
    token = os.environ.get("RAG_SIDECAR_TOKEN", "")
    if not token.strip():
        print("RAG_SIDECAR_TOKEN is required", file=sys.stderr)
        sys.exit(2)
    port = int(os.environ.get("RAG_SIDECAR_PORT", "8431"))
    corpus = Path(os.environ.get(
        "RAG_CORPUS_PATH", str(REPO_ROOT / "mlrag" / "artifacts"
                               / "gate21_corpus.json")))
    index = Path(os.environ.get(
        "RAG_INDEX_PATH", str(REPO_ROOT / "mlrag" / "artifacts"
                              / "gate22_hf_index.npz")))
    manifest = Path(os.environ.get(
        "RAG_MANIFEST_PATH", str(REPO_ROOT / "mlrag" / "artifacts"
                                 / "gate22_hf_index_manifest.json")))
    try:
        state = SidecarState(corpus, index, manifest)
    except Exception as exc:
        print(f"sidecar startup verification failed: {exc}", file=sys.stderr)
        sys.exit(1)
    Handler.state = state
    Handler.token_hash = token.strip().encode("utf-8")
    server = ThreadingHTTPServer((host, port), Handler)
    return server, f"http://{host}:{server.server_address[1]}"


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    server, base = build_server()
    health = Handler.state.to_health() if Handler.state else {}
    log.info(json.dumps({"event": "sidecar_ready", "base": base, **health}))
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
