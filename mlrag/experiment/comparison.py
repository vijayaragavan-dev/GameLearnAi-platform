"""Model-vs-baseline comparison summary (GATE 5, TASK 4).

Deterministic deltas of the candidate against baselines A/B/C on one
scored row set (a fold or the pooled set).  Lower-is-better for log loss
and Brier; higher-is-better for ROC/PR-AUC.  Accuracy is reported but
never decides.  Any comparison involving an unavailable (None) metric is
``improves=None`` with reason ``insufficient_evidence`` — never a win.
"""

from __future__ import annotations

COMPARED_METRICS = ("log_loss", "brier", "roc_auc", "pr_auc")
LOWER_IS_BETTER = {"log_loss", "brier"}


def compare_methods(scored: dict[str, dict]) -> dict:
    """Compare 'model' against baselines A/B/C within one scored set."""
    methods = ("A", "B", "C")
    result: dict[str, dict] = {}
    for metric in COMPARED_METRICS:
        model_value = scored["model"].get(metric)
        per_baseline: dict[str, dict] = {}
        for base in methods:
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
            if metric in LOWER_IS_BETTER:
                delta = model_value - base_value
                improves = delta < 0
            else:
                delta = model_value - base_value
                improves = delta > 0
            per_baseline[base] = {
                "model": model_value,
                "baseline": base_value,
                "delta": delta,
                "improves": improves,
                "evidence": "measured",
            }
        verdicts = [v["improves"] for v in per_baseline.values()]
        if any(v is None for v in verdicts):
            overall: bool | None = None
        else:
            overall = all(verdicts)
        result[metric] = {"vs_baselines": per_baseline,
                          "improves_over_all": overall}
    return result
