"""Live-snapshot runner for Gate 17 verification (read-only).

Usage (PowerShell; secrets stay in-process, never logged, never stored):
populate ``MLRAG_DB_HOST`` / ``MLRAG_DB_PORT`` / ``MLRAG_DB_DATABASE`` /
``MLRAG_DB_USERNAME`` / ``MLRAG_DB_PASSWORD`` in the process environment
from the project's existing local database configuration, then run::

    python -m mlrag.feature_pipeline.snapshot

The runner performs zero writes: it issues only the pipeline's validated
SELECT statements, builds the feature table twice (parity), measures
elapsed time, and prints a JSON summary to stdout.  An optional
``--out PATH`` writes the full machine-readable feature rows (PII-free:
surrogate learner keys only) for Gate 18 dataset generation.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import tracemalloc
from typing import Any

from ..contracts.common import ContractViolation
from .builder import build_feature_table
from .extract import extract


def _require_env(name: str) -> str:
    value = os.environ.get(name)
    if value is None or not value.strip():
        raise ContractViolation(f"missing required environment variable: {name}")
    return value.strip()


def connect_from_env() -> Any:
    """Open a MySQL connection from MLRAG_DB_* env vars (caller-owned creds)."""
    try:
        import pymysql
        import pymysql.cursors
    except ImportError as exc:
        raise ContractViolation(
            "pymysql is required for live snapshots"
        ) from exc
    host = os.environ.get("MLRAG_DB_HOST", "127.0.0.1").strip() or "127.0.0.1"
    port = int((os.environ.get("MLRAG_DB_PORT", "3306") or "3306").strip())
    database = _require_env("MLRAG_DB_DATABASE")
    username = _require_env("MLRAG_DB_USERNAME")
    password = _require_env("MLRAG_DB_PASSWORD")
    return pymysql.connect(
        host=host,
        port=port,
        user=username,
        password=password,
        database=database,
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
        read_timeout=30,
        write_timeout=30,
        autocommit=True,
    )


def run_snapshot(conn: Any) -> dict[str, Any]:
    """Extract + build once; return rows/rejections/stats with perf data."""
    tracemalloc.start()
    started = time.perf_counter()
    tables = extract(conn)
    table_counts = {name: len(rows) for name, rows in tables.items()}
    result = build_feature_table(tables)
    elapsed_s = time.perf_counter() - started
    _, peak_bytes = tracemalloc.get_traced_memory()
    tracemalloc.stop()
    result["table_counts"] = table_counts
    result["performance"] = {
        "rows": len(result["rows"]),
        "elapsed_s": elapsed_s,
        "avg_ms_per_row": (
            (elapsed_s / len(result["rows"]) * 1000.0)
            if result["rows"]
            else 0.0
        ),
        "peak_bytes": peak_bytes,
    }
    return result


def rows_equal(first: list[dict], second: list[dict]) -> dict[str, Any]:
    """Deterministic parity comparison of two builds (canonical JSON)."""
    def canonical(rows: list[dict]) -> str:
        return json.dumps(rows, sort_keys=True, default=str)
    same_count = len(first) == len(second)
    same_values = canonical(first) == canonical(second)
    order_a = [r["question_attempt_id"] for r in first]
    order_b = [r["question_attempt_id"] for r in second]
    return {
        "same_row_count": same_count,
        "same_ordering": order_a == order_b,
        "same_feature_values": same_values,
        "parity_pass": same_count and same_values and order_a == order_b,
    }


def summarize(result: dict[str, Any], parity: dict[str, Any]) -> dict[str, Any]:
    """PII-free summary for the Gate 17 report."""
    return {
        "table_counts": result["table_counts"],
        "data_version": result["data_version"],
        "stats": result["stats"],
        "performance": result["performance"],
        "parity": parity,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Gate 17 live snapshot")
    parser.add_argument(
        "--out", default="",
        help="optional path for full PII-free feature rows (JSON)",
    )
    args = parser.parse_args(argv)
    conn = connect_from_env()
    try:
        first = run_snapshot(conn)
        second_tables = extract(conn)
        second = build_feature_table(second_tables)
    finally:
        try:
            conn.close()
        except Exception:
            pass
    parity = rows_equal(first["rows"], second["rows"])
    summary = summarize(first, parity)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as handle:
            json.dump(
                {
                    "data_version": first["data_version"],
                    "rows": first["rows"],
                    "rejections": first["rejections"],
                },
                handle,
                default=str,
            )
        summary["artifact"] = args.out
    json.dump(summary, sys.stdout, indent=2, default=str)
    sys.stdout.write("\n")
    return 0 if parity["parity_pass"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
