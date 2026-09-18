"""Promotion gate on frozen bars (Gate 24).

Reuses ``mlrag.experiment.promotion`` (bars + ``assess``) unaltered.
Evidence is measured from this gate's runner output:

* ``beats``: the candidate strictly beats A AND B AND C on pooled
  log loss AND Brier (pre-registered rule, identical to Gate 19)
* ``temporal``: beats baseline A on log loss on BOTH the validation
  split AND the test split — with an empty test split this is
  unachievable by construction (honestly reported, never worked
  around)
* calibration evidence: pooled OOF assessment (bias + n)
* reproducibility/leakage/cold-start flags: set ONLY when this gate's
  suites verify them (reproducibility ×2, leakage probes, cold slices)

Expected outcome on current data: NOT promotable — reported with the
blocker list, never adjusted.
"""

from __future__ import annotations

from typing import Any

from ..evaluation.promotion_eval import active_dates
from ..experiment import promotion


def build_evidence(labeled_rows: list[dict], pooled_comparison: dict,
                   valid_ll: dict[str, float | None],
                   test_ll: dict[str, float | None],
                   calibration_bias: float | None, calibration_n: int,
                   reproducible: bool, leakage_free: bool,
                   cold_start_safe: bool) -> promotion.PromotionEvidence:
    learners = sorted({str(r["learner_key"]) for r in labeled_rows})
    per_learner = [sum(1 for r in labeled_rows
                       if str(r["learner_key"]) == key) for key in learners]
    targets = [int(r["is_correct"]) for r in labeled_rows]
    beats = pooled_comparison.get("beats_all") is True
    temporal_ok = bool(
        valid_ll.get("model") is not None and valid_ll.get("A") is not None
        and test_ll.get("model") is not None and test_ll.get("A") is not None
        and valid_ll["model"] < valid_ll["A"]
        and test_ll["model"] < test_ll["A"])
    return promotion.PromotionEvidence(
        n_learners=len(learners),
        n_rows=len(labeled_rows),
        n_active_dates=len(active_dates([r["predicted_at"]
                                         for r in labeled_rows])),
        min_per_learner=min(per_learner) if per_learner else 0,
        both_classes=(0 in targets and 1 in targets),
        lolo_stable=beats,
        temporal_stable=temporal_ok,
        beats_baselines_pooled=beats,
        calibration_n=calibration_n,
        calibration_bias=calibration_bias,
        reproducible=reproducible,
        leakage_free=leakage_free,
        cold_start_safe=cold_start_safe,
    )


def requirement_table(
        evidence: promotion.PromotionEvidence) -> list[dict]:
    rows = [
        ("learners >= 50", evidence.n_learners,
         promotion.PROVISIONAL_MIN_LEARNERS),
        ("rows >= 5000", evidence.n_rows, promotion.PROVISIONAL_MIN_ROWS),
        ("active dates >= 60", evidence.n_active_dates,
         promotion.PROVISIONAL_MIN_ACTIVE_DATES),
        ("min per learner >= 10", evidence.min_per_learner,
         promotion.PROVISIONAL_MIN_PER_LEARNER),
        ("both classes", int(evidence.both_classes), 1),
        ("lolo stable (pooled ll+Brier beat A/B/C)",
         int(evidence.lolo_stable), 1),
        ("temporal stable (valid+test beat A on ll)",
         int(evidence.temporal_stable), 1),
        ("beats baselines pooled", int(evidence.beats_baselines_pooled), 1),
        ("calibration n >= 200", evidence.calibration_n,
         promotion.PROVISIONAL_MIN_CALIBRATION_N),
        ("calibration |bias| <= 0.05",
         (round(abs(evidence.calibration_bias), 4)
          if evidence.calibration_bias is not None else None),
         promotion.PROVISIONAL_MAX_ABS_BIAS),
        ("reproducible", int(evidence.reproducible), 1),
        ("leakage-free", int(evidence.leakage_free), 1),
        ("cold-start safe", int(evidence.cold_start_safe), 1),
    ]
    table = []
    for name, observed, bar in rows:
        if name.startswith("calibration |bias|"):
            passed = (evidence.calibration_bias is not None
                      and abs(evidence.calibration_bias) <= bar)
        elif name == "both classes":
            passed = bool(evidence.both_classes)
        else:
            passed = observed >= bar
        table.append({"requirement": name, "observed": observed,
                      "bar": bar, "pass": bool(passed)})
    return table


def evaluate(evidence: promotion.PromotionEvidence) -> dict[str, Any]:
    verdict = promotion.assess(evidence)
    return {
        "promotable": verdict.promotable,
        "blockers": list(verdict.reasons),
        "n_blockers": len(verdict.reasons),
        "requirements": requirement_table(evidence),
        "model_promotion": "YES" if verdict.promotable else "NO",
    }
