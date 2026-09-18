"""Calibration analysis for the frozen challenger (GATE 20 §9-10).

Fixed 5-bin table (edges at multiples of 0.2 — never optimized on
results).  Per bin: count, mean predicted probability, observed accuracy,
signed gap.  The weighted absolute gap (ECE-style) is reported only with
an explicit justification flag; with ~60 rows concentrated in two bins it
is labeled statistically weak, never production-grade.

Reliability verdict (fixed rule, reported, never tuned):

* CALIBRATION EVIDENCE = SUFFICIENT only when total n >= 200 AND at least
  4 of 5 bins are occupied AND every occupied bin holds >= 10 rows AND
  rows span >= 3 learners;
* otherwise INSUFFICIENT (a valid, expected result at this data volume).
"""

from __future__ import annotations

from typing import Any

CALIBRATION_BINS = 5
MIN_TOTAL_N = 200
MIN_OCCUPIED_BINS = 4
MIN_BIN_N = 10
MIN_LEARNERS = 3


def fixed_bin_table(y_true: list[int], probs: list[float],
                    bins: int = CALIBRATION_BINS) -> list[dict]:
    """Deterministic fixed-width bins (no fitting, no optimization)."""
    edges = [i / bins for i in range(bins + 1)]
    table = []
    for lower, upper in zip(edges[:-1], edges[1:]):
        idx = [i for i, p in enumerate(probs)
               if (lower <= p < upper) or (upper == 1.0 and p == 1.0)]
        if not idx:
            table.append({"bin": [lower, upper], "n": 0,
                          "mean_p": None, "mean_y": None, "gap": None})
        else:
            mean_p = sum(probs[i] for i in idx) / len(idx)
            mean_y = sum(y_true[i] for i in idx) / len(idx)
            table.append({"bin": [lower, upper], "n": len(idx),
                          "mean_p": mean_p, "mean_y": mean_y,
                          "gap": mean_p - mean_y})
    return table


def summarize(y_true: list[int], probs: list[float],
              learner_keys: list[str] | None = None) -> dict[str, Any]:
    """Calibration summary with signed bias and reliability verdict."""
    table = fixed_bin_table(y_true, probs)
    n = len(y_true)
    mean_p = (sum(probs) / n) if n else None
    observed = (sum(y_true) / n) if n else None
    bias = ((mean_p - observed)
            if (n and mean_p is not None and observed is not None)
            else None)
    occupied = [b for b in table if b["n"] > 0]
    weighted_abs_gap = (
        sum(abs(b["gap"]) * b["n"] for b in occupied) / n if n else None)
    learners = len(set(learner_keys)) if learner_keys else 0
    sufficient = bool(
        n >= MIN_TOTAL_N
        and len(occupied) >= MIN_OCCUPIED_BINS
        and all(b["n"] >= MIN_BIN_N for b in occupied)
        and learners >= MIN_LEARNERS)
    return {
        "total_n": n,
        "bins": table,
        "occupied_bins": len(occupied),
        "overall_mean_predicted_probability": mean_p,
        "overall_observed_positive_rate": observed,
        "signed_bias": bias,
        "weighted_abs_gap": weighted_abs_gap,
        "gap_justified": sufficient,
        "learners_represented": learners,
        "reliability": ("SUFFICIENT" if sufficient else "INSUFFICIENT"),
        "note": ("fixed 0.2-width bins, never optimized; INSUFFICIENT is "
                 "the expected, valid result at ~60 rows"),
    }
