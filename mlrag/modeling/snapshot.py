"""Live Gate 19 experiment runner (read-only MySQL, experimental only).

Populate ``MLRAG_DB_HOST`` / ``MLRAG_DB_PORT`` / ``MLRAG_DB_DATABASE`` /
``MLRAG_DB_USERNAME`` / ``MLRAG_DB_PASSWORD`` in the process environment
from the project's existing local database configuration, then run::

    python -m mlrag.modeling.snapshot [--out PATH] [--model-out PATH]

Zero writes.  Dataset construction/splitting reuse the Gate 18 runner as
the single source of truth; the experiment (split + LOLO protocols) runs
twice for reproducibility.  Prints a PII-free JSON summary (learner keys
aggregated to counts).  ``--out`` writes the full experiment artifact and
``--model-out`` the experimental model artifact; both are safety-scanned
(emails, passwords, JWTs, raw user IDs, selected answers, secrets) and the
run fails loudly on any hit.  Nothing produced here is production-ready.
"""

from __future__ import annotations

import argparse
import json
import sys
import time
import tracemalloc
from typing import Any

from ..dataset.contract import scan_prohibited_content
from ..dataset.snapshot import connect_from_env, run_dataset_snapshot
from . import baselines, challenger, config, experiment


def _scan(serialized: str) -> dict[str, Any]:
    hits = scan_prohibited_content(serialized)
    return {"bytes": len(serialized), "hits": hits,
            "safety_pass": not hits}


def run_gate19(conn: Any) -> dict[str, Any]:
    """Full Gate 19 live run: dataset -> experiment x2 -> artifacts."""
    started = time.perf_counter()

    dataset_result = run_dataset_snapshot(conn)
    labeled = dataset_result["_rows"]
    fingerprint = dataset_result["fingerprint"]
    dataset_peak = int(
        dataset_result.get("performance", {}).get("peak_bytes") or 0)

    # Fresh trace for the experiment phase: the Gate 18 runner stops its
    # own trace on return, so an outer trace would read zeros.
    tracemalloc.start()

    fit_started = time.perf_counter()
    first = experiment.run_experiment(labeled, fingerprint)
    fit_elapsed = time.perf_counter() - fit_started

    second = experiment.run_experiment(labeled, fingerprint)

    # Experimental model artifact: refit on the Gate 18 train split only.
    train = [r for r in labeled if r.get("split") == "train"]
    bundle = challenger.fit(train)
    model_artifact = {
        **bundle.coefficient_record(),
        "data_fingerprint": fingerprint,
        "experiment_id": first["experiment_id"],
        "status": "experimental — NOT production-ready, NOT promoted",
    }

    total_elapsed = time.perf_counter() - started
    _, experiment_peak = tracemalloc.get_traced_memory()
    tracemalloc.stop()
    peak_bytes = max(dataset_peak, int(experiment_peak))

    first_canonical = json.dumps(first, sort_keys=True, default=str)
    second_canonical = json.dumps(second, sort_keys=True, default=str)
    reproducibility = {
        "repeat_predictions_identical": first_canonical == second_canonical,
        "repeat_experiment_id": second["experiment_id"],
    }
    reproducibility["parity_pass"] = (
        reproducibility["repeat_predictions_identical"]
        and second["experiment_id"] == first["experiment_id"]
    )

    return {
        "experiment": first,
        "reproducibility": reproducibility,
        "model_artifact": model_artifact,
        "dataset_fingerprint": fingerprint,
        "dataset_rows": len(labeled),
        "performance": {
            "rows": len(labeled),
            "total_elapsed_s": total_elapsed,
            "fit_and_first_protocol_s": fit_elapsed,
            "peak_bytes": peak_bytes,
        },
    }


def summarize(result: dict[str, Any]) -> dict[str, Any]:
    """PII-free summary: predictions collapsed to metric records."""
    exp = result["experiment"]
    slim_protocols = {}
    for key in ("split_protocol", "lolo_protocol"):
        proto = dict(exp[key])
        proto.pop("predictions", None)
        slim_protocols[key] = proto
    return {
        "experiment_id": exp["experiment_id"],
        "model_id": exp["model_id"],
        "model_version": exp["model_version"],
        "feature_version": exp["feature_version"],
        "dataset_version": exp["dataset_version"],
        "data_fingerprint": exp["data_fingerprint"],
        "primary_metric": exp["primary_metric"],
        "co_primary_metric": exp["co_primary_metric"],
        "protocols": slim_protocols,
        "reproducibility": result["reproducibility"],
        "model_coefficients_n": len(
            result["model_artifact"]["coefficients"]),
        "dataset_rows": result["dataset_rows"],
        "performance": result["performance"],
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Gate 19 live experiment")
    parser.add_argument("--out", default="",
                        help="experiment artifact path (JSON)")
    parser.add_argument("--model-out", default="",
                        help="experimental model artifact path (JSON)")
    args = parser.parse_args(argv)
    conn = connect_from_env()
    try:
        result = run_gate19(conn)
    finally:
        try:
            conn.close()
        except Exception:
            pass
    summary = summarize(result)
    ok = result["reproducibility"]["parity_pass"]
    if args.out:
        serialized = json.dumps(result["experiment"], sort_keys=True,
                                default=str)
        safety = _scan(serialized)
        with open(args.out, "w", encoding="utf-8") as handle:
            handle.write(serialized)
        summary["artifact"] = args.out
        summary["artifact_safety"] = safety
        ok = ok and safety["safety_pass"]
    if args.model_out:
        serialized_model = json.dumps(result["model_artifact"],
                                      sort_keys=True, default=str)
        model_safety = _scan(serialized_model)
        with open(args.model_out, "w", encoding="utf-8") as handle:
            handle.write(serialized_model)
        summary["model_artifact"] = args.model_out
        summary["model_safety"] = model_safety
        ok = ok and model_safety["safety_pass"]
    json.dump(summary, sys.stdout, indent=2, default=str)
    sys.stdout.write("\n")
    return 0 if ok else 2


if __name__ == "__main__":
    raise SystemExit(main())
