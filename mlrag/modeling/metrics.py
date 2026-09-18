"""Evaluation metrics for Gate 19 (Gate-16 conventions, d1 rows).

* Primary: log loss.  Co-primary: Brier score.  Accuracy is reported but
  never decides.  ROC/PR-AUC only when mathematically valid (>= 2
  positives AND >= 2 negatives); otherwise NOT COMPUTABLE (None).
* Empty populations and single-class populations yield NOT COMPUTABLE
  (None with an explicit reason) — never a manufactured number.
* Calibration: fixed 5-bin table plus bias summary; no recalibration.
* Comparison rule (pre-registered): the challenger must STRICTLY beat
  every baseline (A, B, C) on BOTH log loss and Brier.  Any None on
  either side is ``improves=None`` (insufficient evidence), never a win.
"""

from __future__ import annotations

from typing import Any

from sklearn.metrics import (accuracy_score, brier_score_loss, log_loss,
                             precision_recall_curve, roc_auc_score, auc)

#: Sentinel text used wherever a metric is honestly unavailable.
NOT_COMPUTABLE = "NOT COMPUTABLE"

CALIBRATION_BINS = 5
MIN_BIN_N = 10


def _labels(rows: list[dict]) -> list[int]:
    return [int(r["is_correct"]) for r in rows]


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


def score_set(y_true: list[int], probs: list[float],
              population: str = "") -> dict[str, Any]:
    """Score one prediction set.  Empty input -> all NOT COMPUTABLE."""
    if not y_true:
        return {
            "population": population,
            "n": 0,
            "n_positive": 0,
            "positive_rate": None,
            "log_loss": None,
            "brier": None,
            "accuracy": None,
            "roc_auc": None,
            "pr_auc": None,
            "reason": "empty evaluation population: NOT COMPUTABLE",
        }
    return {
        "population": population,
        "n": len(y_true),
        "n_positive": sum(y_true),
        "positive_rate": sum(y_true) / len(y_true),
        "log_loss": float(log_loss(y_true, probs, labels=[0, 1])),
        "brier": float(brier_score_loss(y_true, probs)),
        "accuracy": float(accuracy_score(
            y_true, [1 if p >= 0.5 else 0 for p in probs])),
        "roc_auc": _auc_if_valid(y_true, probs),
        "pr_auc": _pr_auc_if_valid(y_true, probs),
        "reason": None,
    }


def score_rows(rows: list[dict], probs: list[float],
               population: str = "") -> dict[str, Any]:
    """Score dataset rows against a parallel probability list."""
    if len(rows) != len(probs):
        raise ValueError("rows and probs must align")
    return score_set(_labels(rows), list(probs), population=population)


def calibration_table(y_true: list[int], probs: list[float],
                      bins: int = CALIBRATION_BINS) -> list[dict]:
    """Fixed-width probability bins (deterministic, no fitting)."""
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


def summarize_calibration(table: list[dict]) -> dict[str, Any]:
    """Bias summary over a calibration table (no recalibration)."""
    total = sum(b["n"] for b in table)
    counted = sum(b["n"] for b in table if b["n"])
    weighted_p = sum(b["mean_p"] * b["n"] for b in table
                     if b["n"] and b["mean_p"] is not None)
    weighted_y = sum(b["mean_y"] * b["n"] for b in table
                     if b["n"] and b["mean_y"] is not None)
    bias = (weighted_p - weighted_y) / counted if counted else None
    bins = []
    for entry in table:
        deviation = (None if entry["n"] == 0 or entry["mean_p"] is None
                     or entry["mean_y"] is None
                     else entry["mean_p"] - entry["mean_y"])
        bins.append({
            "bin": entry["bin"],
            "n": entry["n"],
            "deviation": deviation,
            "sufficient_n": entry["n"] >= MIN_BIN_N,
        })
    measurable = [b["deviation"] for b in bins if b["deviation"] is not None]
    return {
        "total_n": total,
        "overall_bias": bias,
        "worst_bin_deviation": (max(measurable, key=abs)
                                if measurable else None),
        "sufficient_sample": total >= MIN_BIN_N,
        "bins": bins,
        "note": "statistically weak below calibration minimums; "
                "no recalibration performed",
    }


def compare_vs_baselines(scored: dict[str, dict]) -> dict[str, Any]:
    """Challenger ('model') vs A/B/C on log loss + Brier (strict, None-safe).

    Returns per-metric deltas plus the pre-registered primary verdict:
    ``beats_all`` is True only when the challenger strictly beats every
    baseline on BOTH log loss and Brier with measured evidence.
    """
    result: dict[str, Any] = {}
    for metric in ("log_loss", "brier"):
        model_value = scored["model"].get(metric)
        per_baseline: dict[str, dict] = {}
        for base in ("A", "B", "C"):
            base_value = scored[base].get(metric)
            if model_value is None or base_value is None:
                per_baseline[base] = {
                    "model": model_value,
                    "baseline": base_value,
                    "delta": None,
                    "improves": None,
                    "evidence": "insufficient_evidence",
                }
                continue
            delta = model_value - base_value  # lower-is-better
            per_baseline[base] = {
                "model": model_value,
                "baseline": base_value,
                "delta": delta,
                "improves": delta < 0,
                "evidence": "measured",
            }
        verdicts = [v["improves"] for v in per_baseline.values()]
        overall = (all(verdicts) if all(v is not None for v in verdicts)
                   else None)
        result[metric] = {"vs_baselines": per_baseline,
                          "improves_over_all": overall}
    beats = result["log_loss"]["improves_over_all"] and \
        result["brier"]["improves_over_all"]
    result["beats_all"] = beats  # True / False / None(insufficient evidence)
    result["verdict"] = (
        "CHALLENGER BEATS BASELINES" if beats is True
        else "CHALLENGER DOES NOT BEAT BASELINES" if beats is False
        else "NOT COMPUTABLE: insufficient evidence"
    )
    return result
