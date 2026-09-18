"""Evaluation: leave-one-learner-out CV + temporal holdout (GATE 3 §9).

Metrics: log loss + Brier (primary), accuracy (secondary), ROC/PR-AUC only
when mathematically valid (both classes with >=2 positives and >=2
negatives), coarse calibration table.  Invalid metrics are reported as
None ("unavailable"), never fabricated.
"""

from __future__ import annotations

from sklearn.metrics import (accuracy_score, brier_score_loss, log_loss,
                             precision_recall_curve, roc_auc_score,
                             auc)

from . import baselines, model


def _labels(rows: list[dict]) -> list[int]:
    return [1 if r["label"] else 0 for r in rows]


def _auc_if_valid(y_true: list[int], probs: list[float]) -> float | None:
    positives = sum(y_true)
    negatives = len(y_true) - positives
    if positives < 2 or negatives < 2:
        return None
    try:
        return float(roc_auc_score(y_true, probs))
    except ValueError:
        return None


def _pr_auc_if_valid(y_true: list[int], probs: list[float]) -> float | None:
    positives = sum(y_true)
    negatives = len(y_true) - positives
    if positives < 2 or negatives < 2:
        return None
    try:
        precision, recall, _ = precision_recall_curve(y_true, probs)
        return float(auc(recall, precision))
    except ValueError:
        return None


def score_set(y_true: list[int], probs: list[float]) -> dict:
    return {
        "n": len(y_true),
        "n_positive": sum(y_true),
        "log_loss": float(log_loss(y_true, probs, labels=[0, 1])),
        "brier": float(brier_score_loss(y_true, probs)),
        "accuracy": float(accuracy_score(
            y_true, [1 if p >= 0.5 else 0 for p in probs])),
        "roc_auc": _auc_if_valid(y_true, probs),
        "pr_auc": _pr_auc_if_valid(y_true, probs),
    }


def calibration_table(y_true: list[int], probs: list[float],
                      bins: int = 5) -> list[dict]:
    edges = [i / bins for i in range(bins + 1)]
    table = []
    for lower, upper in zip(edges[:-1], edges[1:]):
        idx = [i for i, p in enumerate(probs)
               if (lower <= p < upper) or (upper == 1.0 and p == 1.0)]
        if not idx:
            table.append({"bin": [lower, upper], "n": 0,
                          "mean_p": None, "mean_y": None})
        else:
            table.append({
                "bin": [lower, upper],
                "n": len(idx),
                "mean_p": sum(probs[i] for i in idx) / len(idx),
                "mean_y": sum(y_true[i] for i in idx) / len(idx),
            })
    return table


def _predict_all(bundle, context_rows: list[dict], test_rows: list[dict],
                 train_rate: float) -> dict[str, list[float]]:
    out = {"A": [], "B": [], "C": [], "model": []}
    for row in test_rows:
        out["A"].append(baselines.predict_a(train_rate))
        out["B"].append(baselines.predict_b(context_rows, row, train_rate))
        out["C"].append(baselines.predict_c(context_rows, row, train_rate))
    served_idx = [i for i, r in enumerate(test_rows)
                  if model.served_by_model(r)]
    model_probs = model.predict_proba(
        bundle, [test_rows[i] for i in served_idx]) if served_idx else []
    it = iter(model_probs)
    for i, row in enumerate(test_rows):
        if model.served_by_model(row):
            out["model"].append(next(it))
        else:
            out["model"].append(train_rate)  # deterministic fallback value
    return out


def leave_one_learner_out(rows: list[dict]) -> dict:
    """One fold per learner; test rows keep full-past (time<T) features."""
    learners = sorted({r["learner_key"] for r in rows})
    folds = []
    pooled: dict[str, list] = {"y": [], "A": [], "B": [], "C": [], "model": []}
    for held in learners:
        train = [r for r in rows if r["learner_key"] != held]
        test = sorted(
            [r for r in rows if r["learner_key"] == held],
            key=lambda r: (r["submitted_at"], r["question_attempt_id"]),
        )
        train_rate = baselines.fit_global_rate(train)
        bundle = model.fit(train)
        # Context = every row (train + test-earlier): the past at time T.
        probs = _predict_all(bundle, rows, test, train_rate)
        y_true = _labels(test)
        folds.append({
            "held_out_learner": held,
            "n_train": len(train),
            "n_test": len(test),
            "served_by_model": sum(1 for r in test
                                   if model.served_by_model(r)),
            "A": score_set(y_true, probs["A"]),
            "B": score_set(y_true, probs["B"]),
            "C": score_set(y_true, probs["C"]),
            "model": score_set(y_true, probs["model"]),
        })
        pooled["y"].extend(y_true)
        for key in ("A", "B", "C", "model"):
            pooled[key].extend(probs[key])
    served_total = sum(f["served_by_model"] for f in folds)
    return {
        "scheme": "leave_one_learner_out",
        "n_folds": len(folds),
        "folds": folds,
        "pooled": {k: score_set(pooled["y"], pooled[k])
                   for k in ("A", "B", "C", "model")},
        "pooled_calibration_model": calibration_table(pooled["y"],
                                                      pooled["model"]),
        "served_by_model_total": served_total,
        "n_total": len(rows),
    }


def temporal_holdout(rows: list[dict]) -> dict:
    """Train on all but last two active dates; validate/test on those days."""
    dates = sorted({r["submitted_at"][:10] for r in rows})
    if len(dates) < 3:
        return {"scheme": "temporal_holdout", "feasible": False,
                "reason": "fewer than 3 active dates"}
    test_date, valid_date = dates[-1], dates[-2]
    train = [r for r in rows if r["submitted_at"][:10] < valid_date]
    valid = [r for r in rows if r["submitted_at"][:10] == valid_date]
    test = [r for r in rows if r["submitted_at"][:10] == test_date]
    if not train or not valid or not test:
        return {"scheme": "temporal_holdout", "feasible": False,
                "reason": "empty partition"}
    train_rate = baselines.fit_global_rate(train)
    bundle = model.fit(train)
    result: dict = {"scheme": "temporal_holdout", "feasible": True,
                    "train_date_end": valid_date, "valid_date": valid_date,
                    "test_date": test_date,
                    "n_train": len(train), "n_valid": len(valid),
                    "n_test": len(test)}
    for name, part in (("valid", valid), ("test", test)):
        probs = _predict_all(bundle, rows, part, train_rate)
        y_true = _labels(part)
        result[name] = {k: score_set(y_true, probs[k])
                        for k in ("A", "B", "C", "model")}
        result[f"{name}_served_by_model"] = sum(
            1 for r in part if model.served_by_model(r))
    return result
