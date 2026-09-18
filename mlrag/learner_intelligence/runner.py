"""Gate 24 evaluation runner: the two leakage-safe protocols for any candidate.

Reuses Gate 18/19 primitives without duplicating them:

* splits: ``dataset.split.assign_splits`` + ``apply_assignment``,
  labels ``train``/``validation``/``test`` (test empty → NOT COMPUTABLE)
* LOLO folds: whole-learner holdout, per-fold refit, strict ``<T``
  baseline context (Gate-16 precedent, same as Gate 19)
* metrics: ``modeling.metrics`` (score_set, calibration_table,
  summarize_calibration, compare_vs_baselines) — the pre-registered
  strict rule (beat A AND B AND C on log loss AND Brier) applies to
  every candidate identically
* baselines A/B/C: ``modeling.baselines`` unchanged

Slices reported per population: cold/non-cold (``is_cold_start``),
history bands (0 / 1–9 / ≥10 strictly-past attempts of the same
learner — bands reuse the frozen ≥10 bar, not new thresholds),
difficulty groups, and per-topic groups (small-n flagged insufficient).
No sensitive attributes exist in f1 and none are constructed here.
"""

from __future__ import annotations

from typing import Any, Callable

from ..contracts.common import ContractViolation
from ..modeling import baselines, metrics
from . import challenger_rf

METHODS = ("A", "B", "C", "model")


def _past_count(context_rows: list[dict], row: dict) -> int:
    return sum(
        1 for r in context_rows
        if str(r["learner_key"]) == str(row["learner_key"])
        and str(r["predicted_at"]) < str(row["predicted_at"])
    )


def _history_band(context_rows: list[dict], row: dict) -> str:
    n = _past_count(context_rows, row)
    if n == 0:
        return "h0_cold"
    if n < 10:
        return "h1_9_limited"
    return "h10_plus_sufficient"


def _predict_all(predict_model: Callable[[list[dict]], list[float]],
                 context_rows: list[dict], eval_rows: list[dict],
                 train_rate: float) -> dict[str, list[float]]:
    out: dict[str, list[float]] = {"A": [], "B": [], "C": []}
    for row in eval_rows:
        out["A"].append(baselines.predict_a(train_rate))
        out["B"].append(baselines.predict_b(context_rows, row, train_rate))
        out["C"].append(baselines.predict_c(context_rows, row, train_rate))
    out["model"] = list(predict_model(eval_rows))
    return out


def _score_population(rows: list[dict], probs: dict[str, list[float]],
                      context_rows: list[dict],
                      population: str) -> dict[str, Any]:
    y_true = [int(r["is_correct"]) for r in rows]
    scored = {m: metrics.score_set(y_true, list(probs[m]),
                                   population=f"{population}:{m}")
              for m in METHODS}

    def _slice(indices: list[int], name: str) -> dict:
        sub_y = [y_true[i] for i in indices]
        return {
            m: metrics.score_set(sub_y, [list(probs[m])[i] for i in indices],
                                 population=f"{population}:{name}:{m}")
            for m in METHODS
        }

    cold_idx = [i for i, r in enumerate(rows)
                if r["features"].get("is_cold_start") is True]
    warm_idx = [i for i in range(len(rows)) if i not in set(cold_idx)]
    slices: dict[str, Any] = {
        "cold": _slice(cold_idx, "cold"),
        "non_cold": _slice(warm_idx, "non_cold"),
    }
    bands: dict[str, list[int]] = {}
    for i, r in enumerate(rows):
        bands.setdefault(_history_band(context_rows, r), []).append(i)
    slices["history_bands"] = {
        band: {"n": len(idx), **_slice(idx, f"band_{band}")}
        for band, idx in sorted(bands.items())
    }
    difficulties: dict[str, list[int]] = {}
    for i, r in enumerate(rows):
        difficulties.setdefault(str(r["features"].get("question_difficulty")),
                                []).append(i)
    slices["difficulty"] = {
        level: {"n": len(idx), **_slice(idx, f"diff_{level}")}
        for level, idx in sorted(difficulties.items())
    }
    topics: dict[str, list[int]] = {}
    for i, r in enumerate(rows):
        topics.setdefault(str(r.get("topic_id")), []).append(i)
    slices["topic"] = {
        topic: {"n": len(idx), **_slice(idx, f"topic_{topic[-4:]}")}
        for topic, idx in sorted(topics.items())
    }

    comparison = metrics.compare_vs_baselines(scored)
    calibration = metrics.summarize_calibration(
        metrics.calibration_table(y_true, list(probs["model"])))
    coverage = {
        m: {"served": len(probs[m]), "population": len(rows),
            "coverage_rate": (len(probs[m]) / len(rows)) if rows else None}
        for m in METHODS
    }
    return {
        "population": population,
        "n": len(rows),
        "cold_rows": len(cold_idx),
        "non_cold_rows": len(warm_idx),
        "coverage": coverage,
        "scored": scored,
        "slices": slices,
        "comparison": comparison,
        "calibration_model": calibration,
    }


class CandidateSpec:
    """Fit/predict contract for one candidate (D or E)."""

    def __init__(self, model_id: str, model_version: str,
                 fit_fn: Callable[[list[dict]], Any],
                 predict_fn: Callable[[Any, list[dict]], list[float]]) -> None:
        self.model_id = model_id
        self.model_version = model_version
        self._fit = fit_fn
        self._predict = predict_fn

    def fit(self, train_rows: list[dict]) -> Any:
        return self._fit(train_rows)

    def predict(self, bundle: Any, rows: list[dict]) -> list[float]:
        return list(self._predict(bundle, rows))


def lr_spec() -> CandidateSpec:
    from ..modeling import challenger
    from ..modeling import config as g19_config
    return CandidateSpec(g19_config.MODEL_ID, g19_config.MODEL_VERSION,
                         challenger.fit, challenger.predict_proba)


def rf_spec() -> CandidateSpec:
    from . import config24
    return CandidateSpec(config24.MODEL_ID, config24.MODEL_VERSION,
                         challenger_rf.fit, challenger_rf.predict_proba)


def run_split_protocol(labeled_rows: list[dict], data_fingerprint: str,
                       spec: CandidateSpec, experiment_id: str) -> dict:
    train = [r for r in labeled_rows if r.get("split") == "train"]
    if not train:
        raise ContractViolation("split protocol requires a non-empty train")
    train_rate = baselines.fit_global_rate(train)
    bundle = spec.fit(train)
    result: dict[str, Any] = {
        "protocol": "gate18_split",
        "experiment_id": experiment_id,
        "model_id": spec.model_id,
        "model_version": spec.model_version,
        "n_train": len(train),
        "train_rate": train_rate,
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
        probs = _predict_all(lambda rows: spec.predict(bundle, rows),
                             labeled_rows, part, train_rate)
        result["populations"][name] = _score_population(
            part, probs, labeled_rows, name)
        for i, row in enumerate(part):
            record = {
                "experiment_id": experiment_id,
                "row_id": str(row["row_id"]),
                "learner_key": str(row["learner_key"]),
                "predicted_at": str(row["predicted_at"]),
                "split": str(row.get("split")),
                "is_correct": int(row["is_correct"]),
                "is_cold_start": bool(row["features"]["is_cold_start"]),
                "model_version": spec.model_version,
                "model_id": spec.model_id,
                "data_fingerprint": data_fingerprint,
            }
            for method in METHODS:
                record[f"p_correct_{method}"] = float(probs[method][i])
            result["predictions"].append(record)
    return result


def run_lolo_protocol(all_rows: list[dict], data_fingerprint: str,
                      spec: CandidateSpec, experiment_id: str) -> dict:
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
        bundle = spec.fit(fold_train)
        probs = _predict_all(lambda rows, b=bundle: spec.predict(b, rows),
                             all_rows, fold_test, fold_rate)
        y_true = [int(r["is_correct"]) for r in fold_test]
        folds.append({
            "held_out_learner": held,
            "n_train": len(fold_train),
            "n_test": len(fold_test),
            "train_rate": fold_rate,
            "scored": {
                m: metrics.score_set(
                    y_true, list(probs[m]),
                    population=f"lolo:{held}:{m}") for m in METHODS},
        })
        pooled["y"].extend(y_true)
        for method in METHODS:
            pooled[method].extend(probs[method])
        pooled_rows.extend(fold_test)
        for i, row in enumerate(fold_test):
            record = {
                "experiment_id": experiment_id,
                "row_id": str(row["row_id"]),
                "learner_key": str(row["learner_key"]),
                "predicted_at": str(row["predicted_at"]),
                "split": str(row.get("split")),
                "is_correct": int(row["is_correct"]),
                "is_cold_start": bool(row["features"]["is_cold_start"]),
                "model_version": spec.model_version,
                "model_id": spec.model_id,
                "data_fingerprint": data_fingerprint,
            }
            for method in METHODS:
                record[f"p_correct_{method}"] = float(probs[method][i])
            predictions.append(record)
    pooled_pop = _score_population(
        pooled_rows,
        {m: pooled[m] for m in METHODS},
        pooled_rows,
        "lolo_pooled")
    return {
        "protocol": "leave_one_learner_out",
        "experiment_id": experiment_id,
        "model_id": spec.model_id,
        "model_version": spec.model_version,
        "n_folds": len(folds),
        "n_total": len(all_rows),
        "folds": folds,
        "pooled": pooled_pop,
        "predictions": predictions,
    }
