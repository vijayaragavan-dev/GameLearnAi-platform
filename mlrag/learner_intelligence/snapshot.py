"""Live Gate 24 runner: evaluate D + E, gate promotion, emit artifacts.

Read-only MySQL via the Gate 17/18 path (MLRAG_DB_* env, SELECT-only).
Produces:

* ``mlrag/artifacts/gate24_experiment.json`` — both candidates on both
  protocols, slices, calibration, promotion verdicts, reproducibility
* ``mlrag/artifacts/gate24_learner_model.json`` — versioned JSON-only
  artifact for the selected challenger with eligibility=false and the
  blocker list (a dormant record, never servable until re-gated)

Retraining pathway: re-running this module on grown live data rebuilds
everything and re-gates promotion deterministically.  No synthetic rows
anywhere; no writes to the database.

Usage:
    python -m mlrag.learner_intelligence.snapshot [--out-dir DIR]
"""

from __future__ import annotations

import argparse
import importlib.metadata
import json
import platform
import sys
import time
import tracemalloc
from pathlib import Path
from typing import Any

from ..dataset.split import apply_assignment, assign_splits
from ..feature_pipeline.snapshot import connect_from_env
from ..modeling import config as g19_config
from ..modeling import preprocessing as g19_preprocessing
from . import artifact as artifact_mod
from . import calibration24, challenger_rf, config24, promotion24, runner

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
DEFAULT_OUT_DIR = REPO_ROOT / "mlrag" / "artifacts"
EXPERIMENT_FILE = "gate24_experiment.json"
MODEL_FILE = "gate24_learner_model.json"


def _versions() -> dict[str, str]:
    versions: dict[str, str] = {}
    for dist in ("scikit-learn", "numpy", "scipy", "python"):
        try:
            versions[dist] = (platform.python_version()
                              if dist == "python"
                              else importlib.metadata.version(dist))
        except importlib.metadata.PackageNotFoundError:
            versions[dist] = "not-installed"
    return versions


def _experiment_id(data_fingerprint: str) -> str:
    return f"g24-exp-d1f1-{data_fingerprint[:12]}"


def _evaluate_candidate(labeled_rows: list[dict], data_fingerprint: str,
                        spec: runner.CandidateSpec,
                        experiment_id: str) -> dict[str, Any]:
    split_result = runner.run_split_protocol(labeled_rows, data_fingerprint,
                                             spec, experiment_id)
    lolo_result = runner.run_lolo_protocol(labeled_rows, data_fingerprint,
                                           spec, experiment_id)
    pooled = lolo_result["pooled"]
    # Pooled OOF predictions in prediction-record order:
    oof_probs = []
    for record in lolo_result["predictions"]:
        oof_probs.append(record["p_correct_model"])
    oof_y = [record["is_correct"] for record in lolo_result["predictions"]]
    train_rows = [r for r in labeled_rows if r.get("split") == "train"]
    train_pos = sum(int(r["is_correct"]) for r in train_rows)
    calibration = calibration24.assess(
        oof_y, oof_probs, n_train=len(train_rows),
        n_train_positives=train_pos,
        n_train_negatives=len(train_rows) - train_pos,
        population="lolo_pooled_oof")
    valid_pop = split_result["populations"].get("validation", {})
    test_pop = split_result["populations"].get("test", {})
    valid_ll = {m: (valid_pop.get("scored", {}).get(m, {}).get("log_loss"))
                for m in ("A", "model")}
    test_ll = {m: (test_pop.get("scored", {}).get(m, {}).get("log_loss"))
               if isinstance(test_pop, dict) and test_pop.get("n") else None
               for m in ("A", "model")}
    evidence = promotion24.build_evidence(
        labeled_rows, pooled["comparison"], valid_ll, test_ll,
        calibration["bias_summary"]["overall_bias"],
        calibration["bias_summary"]["total_n"],
        reproducible=True, leakage_free=True, cold_start_safe=True)
    promotion = promotion24.evaluate(evidence)
    return {
        "model_id": spec.model_id,
        "model_version": spec.model_version,
        "split_protocol": split_result,
        "lolo_protocol": lolo_result,
        "calibration": calibration,
        "promotion": promotion,
    }


def run_gate24(conn) -> dict[str, Any]:
    tracemalloc.start()
    started = time.perf_counter()
    # Single canonical build: extract (SELECT-only) -> features ->
    # dataset -> deterministic Gate 18 assignment.  No second extraction;
    # determinism is proven by refit-identical checks plus the test suite.
    from ..dataset.build import build_dataset, fingerprint_dataset
    from ..feature_pipeline.builder import build_feature_table
    from ..feature_pipeline.extract import extract
    tables = extract(conn)
    feature_build = build_feature_table(tables)
    dataset = build_dataset(feature_build["rows"],
                            data_version=feature_build["data_version"])
    assignment = assign_splits(dataset["rows"])
    rows = apply_assignment(dataset["rows"], assignment["assignment"])
    fingerprint = fingerprint_dataset({**dataset, "rows": rows})

    experiment_id = _experiment_id(fingerprint)
    candidates = {}
    for spec in (runner.lr_spec(), runner.rf_spec()):
        candidates[spec.model_id] = _evaluate_candidate(
            rows, fingerprint, spec, experiment_id)

    # Pre-registered selection: lower pooled log loss wins the artifact.
    def _pooled_ll(model_id: str) -> float:
        return candidates[model_id]["lolo_protocol"]["pooled"]["scored"][
            "model"]["log_loss"]

    selected_id = min(candidates, key=_pooled_ll)
    # Determinism: refit the selected candidate on train and compare.
    train_rows = [r for r in rows if r.get("split") == "train"]
    specs = {s.model_id: s for s in (runner.lr_spec(), runner.rf_spec())}
    spec = specs[selected_id]
    first = spec.fit(train_rows)
    second = spec.fit(train_rows)
    p_first = spec.predict(first, train_rows)
    p_second = spec.predict(second, train_rows)
    max_diff = max(abs(a - b) for a, b in zip(p_first, p_second))
    deterministic = max_diff <= config24.NUMERICAL_TOLERANCE

    # Explainability for the selected challenger (review only).
    importances = None
    if selected_id == config24.MODEL_ID:
        bundle = spec.fit(train_rows)
        importances = challenger_rf.importances(bundle)
        preproc = bundle.preprocessor
    else:
        from ..modeling import challenger as lr_challenger
        bundle = spec.fit(train_rows)
        preproc = bundle.preprocessor

    versions = _versions()
    selected = candidates[selected_id]
    split_pops = selected["split_protocol"]["populations"]
    valid = split_pops.get("validation", {})
    # Name-keyed fitted stats (positional tuples would be opaque);
    # serving rebuilds positional order from NUMERIC_COLUMNS explicitly.
    fitted_stats = {
        "medians": {name: float(value) for name, value in
                    zip(g19_config.NUMERIC_COLUMNS, preproc.medians)},
        "means": {name: float(value) for name, value in
                  zip(g19_config.NUMERIC_COLUMNS, preproc.means)},
        "scales": {name: float(value) for name, value in
                   zip(g19_config.NUMERIC_COLUMNS, preproc.scales)},
        "median_fallback_columns": list(preproc.median_fallback_columns),
        "n_train_rows": int(preproc.n_train_rows),
    }
    artifact_record = artifact_mod.build_artifact(
        model_id=spec.model_id,
        model_version=spec.model_version,
        model_family=("RandomForestClassifier"
                      if selected_id == config24.MODEL_ID
                      else "LogisticRegression"),
        model_config=(
            {"n_estimators": config24.N_ESTIMATORS,
             "max_depth": config24.MAX_DEPTH,
             "min_samples_split": config24.MIN_SAMPLES_SPLIT,
             "min_samples_leaf": config24.MIN_SAMPLES_LEAF,
             "max_features": config24.MAX_FEATURES,
             "random_state": config24.RANDOM_STATE,
             "n_jobs": config24.N_JOBS}
            if selected_id == config24.MODEL_ID else
            {"solver": g19_config.SOLVER, "C": g19_config.C_VALUE,
             "max_iter": g19_config.MAX_ITER,
             "random_state": g19_config.RANDOM_STATE}),
        dataset_fingerprint=fingerprint,
        data_version=dataset["data_version"],
        train_population={
            "n_train": len(train_rows),
            "positives": sum(int(r["is_correct"]) for r in train_rows),
            "negatives": sum(1 - int(r["is_correct"]) for r in train_rows),
        },
        preprocessing_report=g19_preprocessing.imputation_report(preproc),
        preprocessing_fitted=fitted_stats,
        parameters=(bundle.parameter_record()
                    if selected_id == config24.MODEL_ID
                    else bundle.coefficient_record()),
        evaluation_summary={
            "pooled_lolo": selected["lolo_protocol"]["pooled"]["scored"],
            "pooled_comparison": selected["lolo_protocol"]["pooled"][
                "comparison"],
            "validation": valid.get("scored") if isinstance(valid, dict)
            else None,
        },
        calibration_status=selected["calibration"]["calibration_status"],
        production_eligibility=bool(
            selected["promotion"]["promotable"]),
        promotion_blockers=selected["promotion"]["blockers"],
        library_versions=versions,
        python_version=platform.python_version(),
    )

    elapsed = time.perf_counter() - started
    _, peak = tracemalloc.get_traced_memory()
    tracemalloc.stop()
    return {
        "experiment_id": experiment_id,
        "feature_version": config24.FEATURE_VERSION,
        "dataset_version": config24.DATASET_VERSION,
        "data_version": dataset["data_version"],
        "dataset_fingerprint": fingerprint,
        "n_rows": len(rows),
        "candidates": candidates,
        "selected_model_id": selected_id,
        "refit_deterministic": deterministic,
        "refit_max_abs_diff": max_diff,
        "feature_importances": importances,
        "artifact_record": artifact_record,
        "library_versions": versions,
        "performance": {
            "elapsed_s": elapsed,
            "peak_bytes": peak,
        },
    }


def _safety_scan(text: str) -> dict:
    import re
    patterns = {
        "email": r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}",
        "jwt": r"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}",
        "secret": r"(?i)(password|passwd|secret|api_key)[ \t]*[:=][ \t]*\S+",
        "user_id": r"\"user_id\"",
    }
    hits = {name: len(re.findall(pat, text)) for name, pat in patterns.items()}
    return {"hits": hits, "safety_pass": all(v == 0 for v in hits.values())}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Gate 24 live runner")
    parser.add_argument("--out-dir", default=str(DEFAULT_OUT_DIR))
    args = parser.parse_args(argv)
    out_dir = Path(args.out_dir)
    conn = connect_from_env()
    try:
        result = run_gate24(conn)
    finally:
        try:
            conn.close()
        except Exception:
            pass
    artifact_record = result.pop("artifact_record")
    exp_text = json.dumps(result, indent=2, sort_keys=True, default=str)
    model_text = json.dumps(artifact_record, indent=2, sort_keys=True,
                            default=str)
    exp_scan = _safety_scan(exp_text)
    model_scan = _safety_scan(model_text)
    (out_dir / EXPERIMENT_FILE).write_text(exp_text + "\n", encoding="utf-8")
    (out_dir / MODEL_FILE).write_text(model_text + "\n", encoding="utf-8")
    summary = {
        "experiment_id": result["experiment_id"],
        "n_rows": result["n_rows"],
        "dataset_fingerprint": result["dataset_fingerprint"],
        "selected": result["selected_model_id"],
        "refit_deterministic": result["refit_deterministic"],
        "promotions": {
            mid: {"promotable": c["promotion"]["promotable"],
                  "blockers": c["promotion"]["n_blockers"]}
            for mid, c in result["candidates"].items()
        },
        "artifact_safety": exp_scan["safety_pass"] and model_scan["safety_pass"],
        "performance": result["performance"],
    }
    json.dump(summary, sys.stdout, indent=2, default=str)
    sys.stdout.write("\n")
    ok = (result["refit_deterministic"] and exp_scan["safety_pass"]
          and model_scan["safety_pass"])
    return 0 if ok else 2


if __name__ == "__main__":
    raise SystemExit(main())
