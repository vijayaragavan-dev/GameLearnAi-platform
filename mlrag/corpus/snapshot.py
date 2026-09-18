"""Live Gate 21 corpus snapshot runner (read-only MySQL).

Populate ``MLRAG_DB_HOST`` / ``MLRAG_DB_PORT`` / ``MLRAG_DB_DATABASE`` /
``MLRAG_DB_USERNAME`` / ``MLRAG_DB_PASSWORD`` in the process environment
from the project's existing local database configuration, then run::

    python -m mlrag.corpus.snapshot [--out PATH]

Zero writes.  Extraction reuses ``mlrag.rag.extract_corpus.fetch_corpus``
(guarded SELECT-only statements) over a caller-owned connection opened by
the shared Gate 17 connection helper; construction runs twice in-process
(idempotency) plus once over shuffled input order, and the canonical
artifact (PII-free serving chunks + quarantine records + rejections +
stats + versions + fingerprint + source snapshot) is safety-scanned before
writing.  Prints a JSON summary to stdout.
"""

from __future__ import annotations

import argparse
import json
import random
import sys
import time
import tracemalloc
from typing import Any

from ..feature_pipeline.snapshot import connect_from_env
from ..rag.extract_corpus import fetch_corpus
from . import screening
from .build import build_corpus

#: JSON key names that must never occur in a corpus artifact (matched as
#: quoted keys, never as free-text vocabulary).
FORBIDDEN_ARTIFACT_KEYS = (
    "user_id",
    "selected_answer",
    "correct_answer",
    "password",
    "password_hash",
    "jwt",
    "token",
    "secret",
    "api_key",
    "email",
    "quiz_score",
    "is_correct",
    "duration_seconds",
    "response_time_seconds",
    "mastery_score",
)


def scan_corpus_artifact(serialized: str) -> dict:
    """Precise artifact safety scan for free-text corpus content.

    Why not the coarse substring list: bare words such as "email" are
    legitimate curricular vocabulary (verified live: a requirements
    question whose options include "The system shall email invoices"),
    while true PII/secrets always match precise patterns.  This scan
    therefore enforces (a) email-address / JWT / secret-assignment /
    bearer patterns anywhere, and (b) forbidden identifiers as JSON
    keys.  Any hit fails the run loudly.
    """
    import json as _json
    import re as _re

    hits: list[str] = []
    for finding in screening.scan_secrets(serialized):
        hits.append(f"content-pattern:{finding}")
    try:
        parsed = _json.loads(serialized)
    except ValueError:
        return {"hits": ["artifact_not_json"], "safety_pass": False}
    seen: list[str] = []

    def _walk(node: object) -> None:
        if isinstance(node, dict):
            for key, value in node.items():
                if (isinstance(key, str)
                        and key.lower() in FORBIDDEN_ARTIFACT_KEYS):
                    seen.append(f"forbidden-key:{key}")
                _walk(value)
        elif isinstance(node, list):
            for item in node:
                _walk(item)

    _walk(parsed)
    hits.extend(sorted(set(seen)))
    return {"hits": hits, "safety_pass": not hits}


def _canonical(value: Any) -> str:
    return json.dumps(value, sort_keys=True, default=str,
                      ensure_ascii=False)


def _shuffled(tables: dict[str, list[dict]]) -> dict[str, list[dict]]:
    rng = random.Random(20260214)
    return {name: rng.sample(rows, len(rows)) if rows else []
            for name, rows in tables.items()}


def run_corpus_snapshot(conn: Any) -> dict[str, Any]:
    """Extract (read-only) -> build x2 + shuffled -> artifact payload."""
    tracemalloc.start()
    started = time.perf_counter()

    tables = fetch_corpus(conn)
    table_counts = {name: len(rows) for name, rows in tables.items()}
    first = build_corpus(tables)
    second = build_corpus(tables)
    shuffled = build_corpus(_shuffled(tables))

    elapsed_s = time.perf_counter() - started
    _, peak_bytes = tracemalloc.get_traced_memory()
    tracemalloc.stop()

    idempotent = (
        _canonical({k: first[k] for k in
                    ("chunks", "fingerprint", "counts")})
        == _canonical({k: second[k] for k in
                       ("chunks", "fingerprint", "counts")}))
    order_stable = (
        first["fingerprint"] == shuffled["fingerprint"]
        and _canonical(first["chunks"]) == _canonical(shuffled["chunks"]))
    total_chunks = (len(first["chunks"]) + len(first["quarantined"])
                    + len(first["rejections"]))
    return {
        "corpus": first,
        "table_counts": table_counts,
        "idempotency": {
            "same_process_rebuild_identical": idempotent,
            "shuffled_input_identical": order_stable,
            "repeat_fingerprint": second["fingerprint"],
            "shuffled_fingerprint": shuffled["fingerprint"],
            "parity_pass": idempotent and order_stable,
        },
        "performance": {
            "source_rows": total_chunks,
            "serving_chunks": len(first["chunks"]),
            "elapsed_s": elapsed_s,
            "chunks_per_sec": (len(first["chunks"]) / elapsed_s
                               if elapsed_s > 0 else 0.0),
            "peak_bytes": peak_bytes,
        },
    }


def summarize(result: dict[str, Any]) -> dict[str, Any]:
    """PII-free summary (chunk texts abbreviated to hashes + lengths)."""
    corpus = result["corpus"]
    slim_chunks = [
        {k: c[k] for k in
         ("chunk_id", "source_table", "source_id", "text_hash",
          "quarantine", "citation")}
        for c in corpus["chunks"][:5]
    ]
    return {
        "corpus_version": corpus["corpus_version"],
        "document_version": corpus["document_version"],
        "chunk_version": corpus["chunk_version"],
        "ingestion_version": corpus["ingestion_version"],
        "fingerprint": corpus["fingerprint"],
        "table_counts": result["table_counts"],
        "counts": corpus["counts"],
        "stats": corpus["stats"],
        "duplicates": corpus["duplicates"],
        "rejections": corpus["rejections"],
        "quarantined": [
            {"chunk_id": c["chunk_id"],
             "reason_codes": c["quarantine"]["reason_codes"]}
            for c in corpus["quarantined"]
        ],
        "sample_chunks": slim_chunks,
        "source_snapshot": corpus["source_snapshot"],
        "idempotency": result["idempotency"],
        "performance": result["performance"],
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Gate 21 live corpus")
    parser.add_argument("--out", default="",
                        help="PII-free corpus artifact path (JSON)")
    args = parser.parse_args(argv)
    conn = connect_from_env()
    try:
        result = run_corpus_snapshot(conn)
    finally:
        try:
            conn.close()
        except Exception:
            pass
    summary = summarize(result)
    ok = result["idempotency"]["parity_pass"]
    if args.out:
        payload = {
            "corpus_version": result["corpus"]["corpus_version"],
            "document_version": result["corpus"]["document_version"],
            "chunk_version": result["corpus"]["chunk_version"],
            "ingestion_version": result["corpus"]["ingestion_version"],
            "fingerprint": result["corpus"]["fingerprint"],
            "chunks": result["corpus"]["chunks"],
            "quarantined": result["corpus"]["quarantined"],
            "rejections": result["corpus"]["rejections"],
            "duplicates": result["corpus"]["duplicates"],
            "counts": result["corpus"]["counts"],
            "stats": result["corpus"]["stats"],
            "source_snapshot": result["corpus"]["source_snapshot"],
        }
        serialized = _canonical(payload)
        safety = scan_corpus_artifact(serialized)
        safety["bytes"] = len(serialized)
        with open(args.out, "w", encoding="utf-8") as handle:
            handle.write(serialized)
        summary["artifact"] = args.out
        summary["artifact_safety"] = safety
        ok = ok and safety["safety_pass"]
    json.dump(summary, sys.stdout, indent=2, default=str)
    sys.stdout.write("\n")
    return 0 if ok else 2


if __name__ == "__main__":
    raise SystemExit(main())
