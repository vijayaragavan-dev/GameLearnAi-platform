"""Live Gate 20 evaluation runner (read-only MySQL, evaluation only).

Populate ``MLRAG_DB_HOST`` / ``MLRAG_DB_PORT`` / ``MLRAG_DB_DATABASE`` /
``MLRAG_DB_USERNAME`` / ``MLRAG_DB_PASSWORD`` in the process environment
from the project's existing local database configuration, then run::

    python -m mlrag.evaluation.snapshot [--out PATH]

Zero writes, zero tuning, zero promotion.  Flow: Gate 18 dataset snapshot
-> Gate 19 experiment (frozen) -> fingerprint cross-checks (live vs live
vs recorded Gate 19 artifacts; any drift fails loudly) -> Gate 19
artifact verification -> deep analysis (pooled, folds, cold, difficulty,
topic, calibration, uncertainty, robustness, promotion, readiness) ->
analysis repeated for reproducibility.  Prints a PII-free JSON summary
(folds labeled ``fold_01…`` with counts only); ``--out`` writes the full
evaluation artifact (surrogate keys only, safety-scanned).
"""

from __future__ import annotations

import argparse
import json
import sys
import time
import tracemalloc
from typing import Any

from ..contracts.common import ContractViolation
from ..dataset.contract import scan_prohibited_content
from ..dataset.snapshot import connect_from_env, run_dataset_snapshot
from ..modeling.snapshot import run_gate19
from . import (calibration, populations, promotion_eval, robustness,
               slices, uncertainty, verify)


def analyze(labeled_rows: list[dict], experiment: dict[str, Any],
            dataset_snapshot: dict[str, Any]) -> dict[str, Any]:
    """Pure deep analysis of one frozen experiment + labeled rows."""
    lolo = experiment["lolo_protocol"]
    split = experiment["split_protocol"]
    joined = slices.join_predictions(labeled_rows, lolo["predictions"])
    if len(joined) != len(labeled_rows):
        raise ContractViolation(
            f"prediction join incomplete: {len(joined)}/{len(labeled_rows)}")
    model_probs = [float(r["p_correct_model"]) for r in joined]
    y_true = [int(r["is_correct"]) for r in joined]
    learners = [str(r["learner_key"]) for r in joined]

    pooled = slices.pooled_scored(joined)
    folds = slices.fold_table(joined)
    not_computable_folds = sorted(
        f["fold"] for f in folds if not f["roc_computable"])
    cal = calibration.summarize(y_true, model_probs, learners)
    unc = uncertainty.describe(model_probs, y_true)
    robust = robustness.run_all(joined, lolo["predictions"])

    split_summary = {}
    for name, pop in split["populations"].items():
        if pop.get("n"):
            split_summary[name] = {
                "n": pop["n"],
                "methods": {
                    m: {"log_loss": pop["scored"][m].get("log_loss")}
                    for m in ("A", "B", "C", "model")},
            }
        else:
            split_summary[name] = {"n": 0, "methods": {}}
    evidence = promotion_eval.build_evidence(
        labeled_rows, lolo["pooled"]["comparison"], split_summary,
        lolo["pooled"]["calibration_model"].get("overall_bias")
        if isinstance(lolo["pooled"].get("calibration_model"), dict)
        else cal["signed_bias"],
        cal["total_n"])
    promotion = promotion_eval.evaluate(evidence)

    strongest = min(
        (pooled["methods"][m].get("log_loss"), m) for m in ("A", "B", "C")
        if pooled["methods"][m].get("log_loss") is not None)
    model_ll = pooled["methods"]["model"].get("log_loss")
    model_br = pooled["methods"]["model"].get("brier")
    comparison = {
        "strongest_baseline": strongest[1],
        "strongest_log_loss": strongest[0],
        "challenger_log_loss": model_ll,
        "challenger_brier": model_br,
        "delta_log_loss": (model_ll - strongest[0]
                           if model_ll is not None else None),
        "verdict": lolo["pooled"]["comparison"]["verdict"],
    }
    return {
        "experiment_id": experiment["experiment_id"],
        "model_id": experiment["model_id"],
        "model_version": experiment["model_version"],
        "feature_version": experiment["feature_version"],
        "dataset_version": experiment["dataset_version"],
        "data_fingerprint": experiment["data_fingerprint"],
        "dataset_snapshot": {
            "dataset_rows": len(labeled_rows),
            "data_version": dataset_snapshot.get("data_version"),
            "readiness": dataset_snapshot.get("readiness"),
        },
        "pooled": pooled,
        "folds": folds,
        "not_computable_folds": not_computable_folds,
        "n_folds": len(folds),
        "cold": slices.cold_slices(joined),
        "difficulty": slices.difficulty_slices(joined),
        "topics": slices.topic_slices(joined),
        "calibration": cal,
        "uncertainty": unc,
        "robustness": robust,
        "comparison": comparison,
        "promotion": promotion,
    }


def run_gate20(conn: Any) -> dict[str, Any]:
    """Full Gate 20 live run with in-process reproducibility."""
    started = time.perf_counter()
    dataset_snapshot = run_dataset_snapshot(conn)
    labeled = dataset_snapshot["_rows"]
    live_fingerprint = dataset_snapshot["fingerprint"]

    gate19 = run_gate19(conn)
    if gate19["dataset_fingerprint"] != live_fingerprint:
        raise ContractViolation(
            "Gate 19 rerun fingerprint differs from dataset snapshot "
            "(silent regeneration suspected)")
    experiment = gate19["experiment"]

    config_check = verify.verify_config_frozen()
    assignment = {str(r["row_id"]): str(r["split"]) for r in labeled}
    artifact_check = verify.verify_artifacts(live_fingerprint, assignment)

    tracemalloc.start()
    first = analyze(labeled, experiment, dataset_snapshot)
    second = analyze(labeled, experiment, dataset_snapshot)
    _, peak_bytes = tracemalloc.get_traced_memory()
    tracemalloc.stop()

    def _canonical(value: Any) -> str:
        return json.dumps(value, sort_keys=True, default=str)

    evaluation_repro = {
        "repeat_analysis_identical": _canonical(first) == _canonical(second),
    }
    evaluation_repro["parity_pass"] = (
        evaluation_repro["repeat_analysis_identical"]
        and gate19["reproducibility"]["parity_pass"]
        and dataset_snapshot["determinism"]["parity_pass"])
    elapsed = time.perf_counter() - started
    return {
        "analysis": first,
        "verification": {**config_check, **artifact_check},
        "gate19_reproducibility": gate19["reproducibility"],
        "dataset_determinism": dataset_snapshot["determinism"],
        "evaluation_reproducibility": evaluation_repro,
        "performance": {
            "rows": len(labeled),
            "folds": len(first["folds"]),
            "elapsed_s": elapsed,
            "peak_bytes": peak_bytes,
        },
    }


def summarize(result: dict[str, Any]) -> dict[str, Any]:
    """PII-free summary (surrogate learner keys stripped to fold labels)."""
    analysis = json.loads(json.dumps(result["analysis"], default=str))
    for fold in analysis["folds"]:
        fold.pop("learner_key", None)
    verification = dict(result["verification"])
    verification.pop("split_match_rows", None)
    return {
        "experiment_id": analysis["experiment_id"],
        "model_id": analysis["model_id"],
        "model_version": analysis["model_version"],
        "feature_version": analysis["feature_version"],
        "dataset_version": analysis["dataset_version"],
        "data_fingerprint": analysis["data_fingerprint"],
        "pooled": analysis["pooled"],
        "folds": analysis["folds"],
        "not_computable_folds": analysis["not_computable_folds"],
        "cold": analysis["cold"],
        "difficulty": analysis["difficulty"],
        "topics": analysis["topics"],
        "calibration": analysis["calibration"],
        "uncertainty": analysis["uncertainty"],
        "robustness": analysis["robustness"],
        "comparison": analysis["comparison"],
        "promotion": analysis["promotion"],
        "dataset_snapshot": analysis["dataset_snapshot"],
        "verification": verification,
        "evaluation_reproducibility": result["evaluation_reproducibility"],
        "performance": result["performance"],
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Gate 20 live evaluation")
    parser.add_argument("--out", default="",
                        help="evaluation artifact path (JSON)")
    args = parser.parse_args(argv)
    conn = connect_from_env()
    try:
        result = run_gate20(conn)
    finally:
        try:
            conn.close()
        except Exception:
            pass
    summary = summarize(result)
    ok = (result["evaluation_reproducibility"]["parity_pass"]
          and result["analysis"]["robustness"]["robustness_pass"])
    if args.out:
        serialized = json.dumps(result["analysis"], sort_keys=True,
                                default=str)
        hits = scan_prohibited_content(serialized)
        safety = {"bytes": len(serialized), "hits": hits,
                  "safety_pass": not hits}
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
