"""Gate 19 experimental protocols (no tuning, no selection).

Protocol 1 — Gate 18 split (required): fit baselines + challenger on the
train split; score validation and test splits as labeled by Gate 18.  An
empty split scores as NOT COMPUTABLE; the split is never reshaped.

Protocol 2 — Gate-16 leave-one-learner-out (experiment-only, honestly
executable here): one fold per learner; per fold, fit on the other
learners and predict the held-out learner.  Baseline history context is
every row with ``predicted_at < T`` (the past at time T — Gate-16
precedent); preprocessing/model fits read the fold-train only.  Pooled
out-of-fold predictions feed the pre-registered primary comparison
(pooled log loss + Brier, challenger vs each of A/B/C).

Cold-start slices: every scored population is additionally split into
cold vs non-cold rows (``is_cold_start``) with independent metrics;
coverage (served/scored rows) is reported per method per population —
the challenger and all baselines serve every valid row by construction.

Prediction records carry the model output contract: model_version,
feature_version, dataset_version, p_correct, row_id identity,
predicted_at timestamp, experiment identifier.
"""

from __future__ import annotations

from typing import Any

from ..contracts.common import ContractViolation
from . import baselines, challenger, config, metrics, preprocessing


def _experiment_id(data_fingerprint: str) -> str:
    return f"g19-exp-d1f1-{data_fingerprint[:12]}"


def _predict_all(bundle: challenger.ChallengerBundle,
                 context_rows: list[dict], eval_rows: list[dict],
                 train_rate: float) -> dict[str, list[float]]:
    out: dict[str, list[float]] = {"A": [], "B": [], "C": [], "model": []}
    for row in eval_rows:
        out["A"].append(baselines.predict_a(train_rate))
        out["B"].append(baselines.predict_b(context_rows, row, train_rate))
        out["C"].append(baselines.predict_c(context_rows, row, train_rate))
    out["model"] = challenger.predict_proba(bundle, eval_rows)
    return out


def _prediction_records(experiment_id: str, data_fingerprint: str,
                        rows: list[dict],
                        probs: dict[str, list[float]]) -> list[dict]:
    records = []
    for i, row in enumerate(rows):
        record = {
            "experiment_id": experiment_id,
            "row_id": str(row["row_id"]),
            "learner_key": str(row["learner_key"]),
            "predicted_at": str(row["predicted_at"]),
            "split": str(row.get("split")),
            "is_correct": int(row["is_correct"]),
            "is_cold_start": bool(row["features"]["is_cold_start"]),
            "model_version": config.MODEL_VERSION,
            "model_id": config.MODEL_ID,
            "feature_version": config.FEATURE_VERSION,
            "dataset_version": config.DATASET_VERSION,
            "data_fingerprint": data_fingerprint,
        }
        for method in ("A", "B", "C", "model"):
            record[f"p_correct_{method}"] = float(probs[method][i])
        records.append(record)
    return records


def _score_population(rows: list[dict], probs: dict[str, list[float]],
                      population: str) -> dict[str, Any]:
    y_true = [int(r["is_correct"]) for r in rows]
    scored = {m: metrics.score_set(y_true, list(probs[m]),
                                   population=f"{population}:{m}")
              for m in ("A", "B", "C", "model")}
    cold_idx = [i for i, r in enumerate(rows)
                if r["features"]["is_cold_start"] is True]
    warm_idx = [i for i, r in enumerate(rows)
                if r["features"]["is_cold_start"] is not True]
    slices = {}
    for name, idx in (("cold", cold_idx), ("non_cold", warm_idx)):
        sub_y = [y_true[i] for i in idx]
        slices[name] = {
            m: metrics.score_set(sub_y, [list(probs[m])[i] for i in idx],
                                 population=f"{population}:{name}:{m}")
            for m in ("A", "B", "C", "model")
        }
    comparison = metrics.compare_vs_baselines(scored)
    calibration = metrics.summarize_calibration(
        metrics.calibration_table(y_true, list(probs["model"])))
    coverage = {
        m: {"served": len(probs[m]), "population": len(rows),
            "coverage_rate": (len(probs[m]) / len(rows)) if rows else None}
        for m in ("A", "B", "C", "model")
    }
    return {
        "population": population,
        "n": len(rows),
        "cold_rows": len(cold_idx),
        "non_cold_rows": len(warm_idx),
        "coverage": coverage,
        "scored": scored,
        "cold_slices": slices,
        "comparison": comparison,
        "calibration_model": calibration,
    }


def run_split_protocol(labeled_rows: list[dict],
                       data_fingerprint: str) -> dict[str, Any]:
    """Protocol 1: Gate 18 split, unaltered.  Empty split -> NOT COMPUTABLE."""
    experiment_id = _experiment_id(data_fingerprint)
    train = [r for r in labeled_rows if r.get("split") == "train"]
    if not train:
        raise ContractViolation("split protocol requires a non-empty train")
    train_rate = baselines.fit_global_rate(train)
    bundle = challenger.fit(train)
    result: dict[str, Any] = {
        "protocol": "gate18_split",
        "experiment_id": experiment_id,
        "n_train": len(train),
        "train_rate": train_rate,
        "imputation": preprocessing.imputation_report(
            bundle.preprocessor),
        "populations": {},
        "predictions": [],
    }
    for name in ("validation", "test"):
        part = [r for r in labeled_rows if r.get("split") == name]
        if not part:
            result["populations"][name] = {
                "population": name,
                "n": 0,
                "reason": "empty split: NOT COMPUTABLE (never fabricated)",
            }
            continue
        probs = _predict_all(bundle, labeled_rows, part, train_rate)
        result["populations"][name] = _score_population(part, probs, name)
        result["predictions"].extend(
            _prediction_records(experiment_id, data_fingerprint, part,
                                probs))
    return result


def run_lolo_protocol(all_rows: list[dict],
                      data_fingerprint: str) -> dict[str, Any]:
    """Protocol 2: Gate-16 leave-one-learner-out with pooled comparison."""
    experiment_id = _experiment_id(data_fingerprint)
    learners = sorted({str(r["learner_key"]) for r in all_rows})
    if len(learners) < 2:
        raise ContractViolation("LOLO requires >= 2 learners")
    folds = []
    pooled: dict[str, list] = {"y": [], "A": [], "B": [],
                               "C": [], "model": []}
    pooled_rows: list[dict] = []
    predictions = []
    for held in learners:
        fold_train = [r for r in all_rows if str(r["learner_key"]) != held]
        fold_test = sorted(
            [r for r in all_rows if str(r["learner_key"]) == held],
            key=lambda r: (str(r["predicted_at"]),
                           str(r["quiz_attempt_id"]),
                           str(r["question_attempt_id"])),
        )
        fold_rate = baselines.fit_global_rate(fold_train)
        bundle = challenger.fit(fold_train)
        probs = _predict_all(bundle, all_rows, fold_test, fold_rate)
        y_true = [int(r["is_correct"]) for r in fold_test]
        folds.append({
            "held_out_learner": held,
            "n_train": len(fold_train),
            "n_test": len(fold_test),
            "train_rate": fold_rate,
            "scored": {
                m: metrics.score_set(
                    y_true, list(probs[m]),
                    population=f"lolo:{held}:{m}") for m in
                ("A", "B", "C", "model")},
        })
        pooled["y"].extend(y_true)
        for method in ("A", "B", "C", "model"):
            pooled[method].extend(probs[method])
        pooled_rows.extend(fold_test)
        predictions.extend(
            _prediction_records(experiment_id, data_fingerprint, fold_test,
                                probs))
    pooled_pop = _score_population(
        pooled_rows,
        {m: pooled[m] for m in ("A", "B", "C", "model")},
        "lolo_pooled")
    return {
        "protocol": "leave_one_learner_out",
        "experiment_id": experiment_id,
        "n_folds": len(folds),
        "n_total": len(all_rows),
        "folds": folds,
        "pooled": pooled_pop,
        "predictions": predictions,
    }


def run_experiment(labeled_rows: list[dict],
                   data_fingerprint: str) -> dict[str, Any]:
    """Run both protocols; return the combined experimental record."""
    split_result = run_split_protocol(labeled_rows, data_fingerprint)
    lolo_result = run_lolo_protocol(labeled_rows, data_fingerprint)
    return {
        "experiment_id": _experiment_id(data_fingerprint),
        "model_id": config.MODEL_ID,
        "model_version": config.MODEL_VERSION,
        "feature_version": config.FEATURE_VERSION,
        "dataset_version": config.DATASET_VERSION,
        "data_fingerprint": data_fingerprint,
        "solver_config": {
            "solver": config.SOLVER,
            "C": config.C_VALUE,
            "max_iter": config.MAX_ITER,
            "random_state": config.RANDOM_STATE,
            "matrix_columns": list(config.MATRIX_COLUMNS),
        },
        "baselines": baselines.describe(),
        "primary_metric": config.PRIMARY_METRIC,
        "co_primary_metric": config.CO_PRIMARY_METRIC,
        "split_protocol": split_result,
        "lolo_protocol": lolo_result,
    }
