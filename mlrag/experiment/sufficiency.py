"""Data-sufficiency checks (GATE 5, TASK 2).

Facts about whether an evaluation can run at all, whether it can only
yield feasibility evidence, or whether the data tier could support a
production-candidate evaluation.  This module judges DATA volume only —
never model quality, never production readiness of any artifact.
"""

from __future__ import annotations

TIER_IMPOSSIBLE = "evaluation_impossible"
TIER_FEASIBILITY = "feasibility_only"
TIER_CANDIDATE_DATA = "production_candidate_data"


def assess_sufficiency(rows: list[dict]) -> dict:
    """Aggregate facts + tier for one built row set.  Deterministic."""
    n_rows = len(rows)
    learners = sorted({r["learner_key"] for r in rows})
    positives = sum(1 for r in rows if r["label"])
    negatives = n_rows - positives
    dates = sorted({r["submitted_at"][:10] for r in rows})
    per_learner = [sum(1 for r in rows if r["learner_key"] == key)
                   for key in learners]
    served = sum(1 for r in rows if r["hist_attempts"] >= 3)
    facts = {
        "n_rows": n_rows,
        "n_learners": len(learners),
        "n_positive": positives,
        "n_negative": negatives,
        "both_classes": positives > 0 and negatives > 0,
        "n_active_dates": len(dates),
        "min_per_learner": min(per_learner) if per_learner else 0,
        "max_per_learner": max(per_learner) if per_learner else 0,
        "served_rows": served,
    }
    reasons: list[str] = []
    if n_rows < 2:
        reasons.append("fewer than 2 observations")
    if len(learners) < 2:
        reasons.append("fewer than 2 learners (no held-out evaluation)")
    if not facts["both_classes"]:
        reasons.append("single-class data (no discrimination to measure)")
    if len(dates) < 2:
        reasons.append("fewer than 2 active dates (no temporal split)")
    if reasons:
        tier = TIER_IMPOSSIBLE
    else:
        tier = TIER_FEASIBILITY
    return {"facts": facts, "tier": tier, "blockers": reasons}
