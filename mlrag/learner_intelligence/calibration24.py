"""Calibration assessment + principled recalibration rule (Gate 24).

* Assessment reuses ``modeling.metrics`` (fixed 5-bin table + bias) and
  adds Expected Calibration Error (ECE): sum over occupied bins of
  |mean_p − mean_y| × (n / N).  ECE is reported, never optimized.
* Recalibration rule: fitting Platt/isotonic on the current train
  population (≈52 rows, ≈14 negatives) would overfit the calibrator to
  noise.  The rule therefore DECLINES recalibration unless
  train_n ≥ 200 AND minority-class train_n ≥ 50
  (``RECALIBRATION_MIN_*`` in config24 — sized so each class can fill
  multiple calibration bins, not a marketing number).  Decline is
  recorded as ``CALIBRATION STATUS = INSUFFICIENT DATA``, which is a
  valid measurement outcome, never a silent skip.
* No calibrator is ever fit on validation/test data.
"""

from __future__ import annotations

from typing import Any

from ..modeling import metrics
from . import config24


def expected_calibration_error(y_true: list[int], probs: list[float],
                               bins: int = 5) -> dict[str, Any]:
    """ECE over fixed-width bins (deterministic, no fitting)."""
    table = metrics.calibration_table(y_true, probs, bins=bins)
    total = sum(b["n"] for b in table)
    if not total:
        return {"ece": None, "bins": table,
                "reason": "empty population: NOT COMPUTABLE"}
    ece = 0.0
    for entry in table:
        if entry["n"] and entry["mean_p"] is not None \
                and entry["mean_y"] is not None:
            ece += abs(entry["mean_p"] - entry["mean_y"]) * entry["n"] / total
    return {"ece": ece, "bins": table, "n": total}


def recalibration_verdict(n_train: int, n_train_positives: int,
                          n_train_negatives: int) -> dict[str, Any]:
    """Apply the decline rule to measured training evidence."""
    eligible = (
        n_train >= config24.RECALIBRATION_MIN_TRAIN_N
        and min(n_train_positives, n_train_negatives)
        >= config24.RECALIBRATION_MIN_CLASS_N
    )
    if eligible:
        return {
            "status": "ELIGIBLE",
            "detail": "training evidence meets the recalibration minimums; "
                      "a calibrator may be fit on train data only and "
                      "validated separately in a future gate.",
        }
    return {
        "status": "INSUFFICIENT DATA",
        "detail": (
            f"train n={n_train} (need "
            f"{config24.RECALIBRATION_MIN_TRAIN_N}), minority class "
            f"n={min(n_train_positives, n_train_negatives)} (need "
            f"{config24.RECALIBRATION_MIN_CLASS_N}): recalibration "
            "declined — fitting on this population would overfit the "
            "calibrator. Challenger probabilities stay uncalibrated and "
            "are reported as such."
        ),
    }


def assess(y_true: list[int], probs: list[float], *,
           n_train: int, n_train_positives: int,
           n_train_negatives: int,
           population: str = "") -> dict[str, Any]:
    """Full calibration assessment for one scored population."""
    table = metrics.calibration_table(y_true, probs)
    summary = metrics.summarize_calibration(table)
    ece = expected_calibration_error(y_true, probs)
    verdict = recalibration_verdict(n_train, n_train_positives,
                                    n_train_negatives)
    occupied = sum(1 for b in table if b["n"])
    return {
        "population": population,
        "reliability_table": table,
        "bias_summary": summary,
        "ece": ece["ece"],
        "bins_occupied": occupied,
        "recalibration": verdict,
        "calibration_status": (
            "ASSESSED_UNCALIBRATED" if verdict["status"] == "INSUFFICIENT DATA"
            else "RECALIBRATION_ELIGIBLE"
        ),
    }
