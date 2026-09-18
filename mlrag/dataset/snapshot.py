"""Live dataset snapshot runner for Gate 18 verification (read-only).

Populate ``MLRAG_DB_HOST`` / ``MLRAG_DB_PORT`` / ``MLRAG_DB_DATABASE`` /
``MLRAG_DB_USERNAME`` / ``MLRAG_DB_PASSWORD`` in the process environment
from the project's existing local database configuration, then run::

    python -m mlrag.dataset.snapshot [--out PATH]

The runner performs zero writes.  It reuses the Gate 17 read-only
extraction and feature builder as the single source of truth, then runs
dataset construction, deterministic splitting, quality/missingness/target/
identity audits, artifact safety scan, and Gate-5 readiness evaluation.
It builds the dataset twice in-process (parity) and prints a PII-free JSON
summary to stdout.  ``--out PATH`` writes the full PII-free dataset
artifact (surrogate learner keys only; no post-attempt scores).
"""

from __future__ import annotations

import argparse
import json
import sys
import time
import tracemalloc
from typing import Any

from ..feature_pipeline.builder import build_feature_table
from ..feature_pipeline.extract import extract
from ..feature_pipeline.snapshot import connect_from_env
from .build import (
    build_dataset,
    datasets_equal,
    fingerprint_dataset,
)
from .contract import TARGET_COLUMN
from .quality import (
    artifact_safety_scan,
    audit_dataset,
    identity_audit,
    missingness_report,
    readiness_evaluation,
    split_audit,
)
from .split import apply_assignment, assign_splits


def run_dataset_snapshot(conn: Any) -> dict[str, Any]:
    """Extract (Gate 17) -> dataset -> split -> audits, with perf data."""
    tracemalloc.start()
    started = time.perf_counter()

    tables = extract(conn)
    table_counts = {name: len(rows) for name, rows in tables.items()}
    feature_build = build_feature_table(tables)

    dataset = build_dataset(
        feature_build["rows"],
        data_version=feature_build["data_version"],
    )
    split_result = assign_splits(dataset["rows"])
    labeled_rows = apply_assignment(
        dataset["rows"], split_result["assignment"]
    )
    labeled = {**dataset, "rows": labeled_rows}
    labeled["fingerprint"] = fingerprint_dataset(labeled)

    # Same-process determinism: rebuild from the same feature rows.
    repeat = build_dataset(
        feature_build["rows"],
        data_version=feature_build["data_version"],
    )
    repeat_labeled = apply_assignment(
        repeat["rows"], assign_splits(repeat["rows"])["assignment"]
    )
    repeat = {**repeat, "rows": repeat_labeled}
    repeat["fingerprint"] = fingerprint_dataset(repeat)

    audit = audit_dataset(labeled["rows"], labeled["rejections"])
    missing = missingness_report(labeled["rows"])
    identity = identity_audit(labeled["rows"])
    splits = split_audit(labeled["rows"], split_result["metadata"])
    readiness = readiness_evaluation(audit)

    elapsed_s = time.perf_counter() - started
    _, peak_bytes = tracemalloc.get_traced_memory()
    tracemalloc.stop()

    determinism = {
        "same_process_rebuild_equal": datasets_equal(labeled, repeat),
        "fingerprint": labeled["fingerprint"],
        "repeat_fingerprint": repeat["fingerprint"],
    }
    determinism["parity_pass"] = (
        determinism["same_process_rebuild_equal"]
        and labeled["fingerprint"] == repeat["fingerprint"]
    )

    return {
        "dataset_version": labeled["dataset_version"],
        "feature_version": labeled["feature_version"],
        "data_version": labeled["data_version"],
        "fingerprint": labeled["fingerprint"],
        "table_counts": table_counts,
        "feature_build_stats": feature_build["stats"],
        "dataset_rows": len(labeled["rows"]),
        "dataset_rejections": labeled["rejections"],
        "split_metadata": split_result["metadata"],
        "quality": audit,
        "missingness": missing,
        "identity": identity,
        "splits": splits,
        "readiness": readiness,
        "determinism": determinism,
        "performance": {
            "rows": len(labeled["rows"]),
            "elapsed_s": elapsed_s,
            "rows_per_sec": (
                len(labeled["rows"]) / elapsed_s if elapsed_s > 0 else 0.0
            ),
            "peak_bytes": peak_bytes,
        },
        "_rows": labeled["rows"],
    }


def summarize(result: dict[str, Any]) -> dict[str, Any]:
    """PII-free summary (learner keys aggregated to counts only)."""
    summary = {k: v for k, v in result.items() if not k.startswith("_")}
    quality = dict(summary["quality"])
    quality["attempts_per_learner"] = {
        f"learner_{i + 1}": c
        for i, c in enumerate(
            sorted(quality["attempts_per_learner"].values())
        )
    }
    quality["attempts_per_topic"] = dict(
        sorted(quality["attempts_per_topic"].items())
    )
    quality["rows_per_quiz"] = {
        f"quiz_{i + 1}": c
        for i, c in enumerate(sorted(quality["rows_per_quiz"].values()))
    }
    summary["quality"] = quality
    per_split = summary["split_metadata"].get("per_split", {})
    for name in per_split:
        per_split[name] = {
            k: v for k, v in per_split[name].items()
            if k != "learner_keys"
        }
    return summary


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Gate 18 live dataset")
    parser.add_argument(
        "--out", default="",
        help="optional path for the full PII-free dataset artifact (JSON)",
    )
    args = parser.parse_args(argv)
    conn = connect_from_env()
    try:
        result = run_dataset_snapshot(conn)
    finally:
        try:
            conn.close()
        except Exception:
            pass
    summary = summarize(result)
    if args.out:
        artifact = {
            "dataset_version": result["dataset_version"],
            "feature_version": result["feature_version"],
            "data_version": result["data_version"],
            "fingerprint": result["fingerprint"],
            "target_column": TARGET_COLUMN,
            "rows": result["_rows"],
            "rejections": result["dataset_rejections"],
            "split_metadata": result["split_metadata"],
        }
        serialized = json.dumps(artifact, sort_keys=True, default=str)
        safety = artifact_safety_scan(serialized)
        with open(args.out, "w", encoding="utf-8") as handle:
            handle.write(serialized)
        summary["artifact"] = args.out
        summary["artifact_safety"] = safety
        if not safety["safety_pass"]:
            json.dump(summary, sys.stdout, indent=2, default=str)
            sys.stdout.write("\n")
            return 3
    json.dump(summary, sys.stdout, indent=2, default=str)
    sys.stdout.write("\n")
    ok = result["determinism"]["parity_pass"] and result["splits"]["split_pass"]
    return 0 if ok else 2


if __name__ == "__main__":
    raise SystemExit(main())
