"""Offline-only model promotion policy (GATE 5, TASK 6).

A future production candidate may be promoted ONLY if every requirement
below holds on measured evidence.  Numeric bars are PROVISIONAL
engineering criteria — clearly labeled, requiring validation on larger
data before any production use.  This module promotes nothing by itself;
``assess`` returns a verdict structure for review.
"""

from __future__ import annotations

from dataclasses import dataclass, field

# PROVISIONAL engineering criteria (require later validation; NOT
# production thresholds).  Current data (5 learners / 56 rows / 5 days)
# fails nearly all of them by design.
PROVISIONAL_MIN_LEARNERS = 50
PROVISIONAL_MIN_ROWS = 5000
PROVISIONAL_MIN_ACTIVE_DATES = 60
PROVISIONAL_MIN_PER_LEARNER = 10
PROVISIONAL_MIN_CALIBRATION_N = 200
PROVISIONAL_MAX_ABS_BIAS = 0.05


@dataclass(frozen=True)
class PromotionEvidence:
    """Measured facts feeding the policy (no model objects)."""

    n_learners: int
    n_rows: int
    n_active_dates: int
    min_per_learner: int
    both_classes: bool
    lolo_stable: bool  # candidate beats baselines in (nearly) all folds
    temporal_stable: bool  # holds on validation AND test partitions
    beats_baselines_pooled: bool  # pooled log loss + Brier vs A/B/C
    calibration_n: int
    calibration_bias: float | None
    reproducible: bool  # seeded, deterministic rebuild verified
    leakage_free: bool  # contract + leakage tests green
    cold_start_safe: bool  # gate enforced, fallback reasoned


@dataclass(frozen=True)
class PromotionVerdict:
    promotable: bool
    reasons: tuple[str, ...] = field(default_factory=tuple)


def assess(evidence: PromotionEvidence) -> PromotionVerdict:
    """Apply the policy.  Any single failure blocks promotion."""
    blockers: list[str] = []
    if evidence.n_learners < PROVISIONAL_MIN_LEARNERS:
        blockers.append(
            f"learner population {evidence.n_learners} < provisional "
            f"{PROVISIONAL_MIN_LEARNERS}")
    if evidence.n_rows < PROVISIONAL_MIN_ROWS:
        blockers.append(
            f"attempt count {evidence.n_rows} < provisional "
            f"{PROVISIONAL_MIN_ROWS}")
    if evidence.n_active_dates < PROVISIONAL_MIN_ACTIVE_DATES:
        blockers.append("temporal coverage below provisional minimum")
    if evidence.min_per_learner < PROVISIONAL_MIN_PER_LEARNER:
        blockers.append("per-learner history below provisional minimum")
    if not evidence.both_classes:
        blockers.append("single-class data")
    if not evidence.lolo_stable:
        blockers.append("learner-held-out performance not stable")
    if not evidence.temporal_stable:
        blockers.append("temporal performance not stable")
    if not evidence.beats_baselines_pooled:
        blockers.append("no pooled improvement over deterministic baselines")
    if evidence.calibration_n < PROVISIONAL_MIN_CALIBRATION_N:
        blockers.append("calibration sample below provisional minimum")
    if (evidence.calibration_bias is None
            or abs(evidence.calibration_bias) > PROVISIONAL_MAX_ABS_BIAS):
        blockers.append("calibration quality unproven")
    if not evidence.reproducible:
        blockers.append("reproducibility unverified")
    if not evidence.leakage_free:
        blockers.append("leakage checks failing")
    if not evidence.cold_start_safe:
        blockers.append("cold-start behavior unsafe")
    return PromotionVerdict(promotable=not blockers, reasons=tuple(blockers))
