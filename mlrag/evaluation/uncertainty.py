"""Prediction-confidence characterization (GATE 20 §11, no tuning).

Describes where the frozen challenger's probability mass sits and whether
errors concentrate at high confidence.  Read-only analysis of recorded
predictions — the model is never modified.
"""

from __future__ import annotations

from typing import Any

HIGH_CONFIDENCE = 0.8
VERY_HIGH_CONFIDENCE = 0.9
LOW_CONFIDENCE = 0.2


def describe(probs: list[float], y_true: list[int]) -> dict[str, Any]:
    """Distribution + high-confidence error concentration."""
    n = len(probs)
    if not n:
        return {"n": 0, "note": "empty prediction set"}
    flags = {
        "frac_ge_08": sum(1 for p in probs if p >= HIGH_CONFIDENCE) / n,
        "frac_ge_09": sum(1 for p in probs
                           if p >= VERY_HIGH_CONFIDENCE) / n,
        "frac_le_02": sum(1 for p in probs if p <= LOW_CONFIDENCE) / n,
    }
    errors = [i for i in range(n)
              if (1 if probs[i] >= 0.5 else 0) != y_true[i]]
    high_conf_errors = [i for i in errors if probs[i] >= HIGH_CONFIDENCE]
    return {
        "n": n,
        "min_p": min(probs),
        "max_p": max(probs),
        "mean_p": sum(probs) / n,
        **flags,
        "n_errors": len(errors),
        "error_rate": len(errors) / n,
        "n_high_confidence_errors": len(high_conf_errors),
        "high_confidence_error_share": (
            len(high_conf_errors) / len(errors) if errors else None),
        "excessively_confident_errors": bool(
            errors and len(high_conf_errors) / len(errors) > 0.5),
    }
