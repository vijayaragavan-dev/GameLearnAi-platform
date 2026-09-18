"""Trustworthiness evaluation of the frozen Gate 19 experiment (GATE 20).

Evaluation only — no tuning, no retraining with altered configuration, no
promotion, no integration.  The Gate 19 baselines, challenger, dataset
(d1), features (f1), and protocols are reused unaltered; this package only
re-scores, slices, and characterizes their recorded predictions.

Stages:

1. :mod:`mlrag.evaluation.verify` — Gate 19 artifact verification
   (versions, fingerprint, split, frozen config, safety).
2. :mod:`mlrag.evaluation.populations` — extended metric sets (log loss,
   Brier, ROC-AUC, accuracy, positive prediction rate, mean predicted
   probability, observed rate) with pooled + fold-level reporting.
3. :mod:`mlrag.evaluation.slices` — fold, cold-start, difficulty, and
   topic slices from prediction records joined to d1 rows.
4. :mod:`mlrag.evaluation.calibration` — fixed-bin calibration, gaps,
   justified error, and the reliability verdict.
5. :mod:`mlrag.evaluation.uncertainty` — confidence distribution and
   high-confidence error concentration (no model changes).
6. :mod:`mlrag.evaluation.robustness` — deterministic repeat / reorder /
   reload checks.
7. :mod:`mlrag.evaluation.promotion_eval` — measured evidence against the
   existing promotion contract (reuses
   ``mlrag.experiment.promotion.assess``).
8. :mod:`mlrag.evaluation.snapshot` — live read-only runner.
"""

from .verify import (
    DATASET_VERSION,
    FEATURE_VERSION,
    MODEL_ID,
    MODEL_VERSION,
)

__all__ = [
    "DATASET_VERSION",
    "FEATURE_VERSION",
    "MODEL_ID",
    "MODEL_VERSION",
]
