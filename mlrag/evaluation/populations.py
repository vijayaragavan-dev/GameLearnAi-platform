"""Extended metric sets for Gate 20 populations (pooled + fold-level).

Beyond the Gate 19 scored set, every (population, method) record carries:

* log loss, Brier score, ROC-AUC (None unless >= 2 positives AND >= 2
  negatives — reported NOT COMPUTABLE, never manufactured), accuracy;
* positive prediction rate (fraction with p >= 0.5);
* mean predicted probability;
* observed positive rate.

``score_population`` returns the full record for one row set; empty input
yields NOT COMPUTABLE throughout with an explicit reason.
"""

from __future__ import annotations

from typing import Any

from sklearn.metrics import (accuracy_score, brier_score_loss, log_loss,
                             precision_recall_curve, roc_auc_score, auc)

METHODS = ("A", "B", "C", "model")
NOT_COMPUTABLE = "NOT COMPUTABLE"
POSITIVE_THRESHOLD = 0.5


def _auc(y_true: list[int], probs: list[float]) -> float | None:
    if sum(y_true) < 2 or len(y_true) - sum(y_true) < 2:
        return None
    try:
        return float(roc_auc_score(y_true, probs))
    except ValueError:
        return None


def _pr_auc(y_true: list[int], probs: list[float]) -> float | None:
    if sum(y_true) < 2 or len(y_true) - sum(y_true) < 2:
        return None
    try:
        precision, recall, _ = precision_recall_curve(y_true, probs)
        return float(auc(recall, precision))
    except ValueError:
        return None


def score_method(y_true: list[int], probs: list[float],
                 population: str, method: str) -> dict[str, Any]:
    """Extended metric record for one method on one population."""
    record: dict[str, Any] = {
        "population": f"{population}:{method}",
        "n": len(y_true),
        "n_positive": sum(y_true),
        "n_negative": len(y_true) - sum(y_true),
    }
    if not y_true:
        record.update({
            "observed_positive_rate": None,
            "mean_predicted_probability": None,
            "positive_prediction_rate": None,
            "log_loss": None,
            "brier": None,
            "accuracy": None,
            "roc_auc": None,
            "pr_auc": None,
            "reason": f"empty evaluation population: {NOT_COMPUTABLE}",
        })
        return record
    predicted = [1 if p >= POSITIVE_THRESHOLD else 0 for p in probs]
    record.update({
        "observed_positive_rate": sum(y_true) / len(y_true),
        "mean_predicted_probability": sum(probs) / len(probs),
        "positive_prediction_rate": sum(predicted) / len(predicted),
        "log_loss": float(log_loss(y_true, probs, labels=[0, 1])),
        "brier": float(brier_score_loss(y_true, probs)),
        "accuracy": float(accuracy_score(y_true, predicted)),
        "roc_auc": _auc(y_true, probs),
        "pr_auc": _pr_auc(y_true, probs),
        "reason": None,
    })
    return record


def score_population(rows: list[dict], probs: dict[str, list[float]],
                     population: str) -> dict[str, Any]:
    """Score all four methods on one row set (parallel probability lists)."""
    y_true = [int(r["is_correct"]) for r in rows]
    return {
        "population": population,
        "n": len(rows),
        "methods": {
            method: score_method(y_true, list(probs[method]), population,
                                 method)
            for method in METHODS
        },
    }
