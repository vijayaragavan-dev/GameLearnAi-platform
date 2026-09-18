"""First experimental ML layer: frozen baselines + one challenger (GATE 19).

Experimental only — nothing here is production-ready, promoted, or
integrated with Spring Boot / AdaptiveEngine / MySQL writes.  Features come
exclusively from :mod:`mlrag.feature_pipeline` via the
:mod:`mlrag.dataset` d1 rows; no feature engineering is duplicated here and
the old ``mlrag.experiment`` 11-column schema is never used.

Stages:

1. :mod:`mlrag.modeling.config` — the single frozen challenger
   configuration and matrix-column specification (no tuning grid exists).
2. :mod:`mlrag.modeling.preprocessing` — leakage-safe transformers fitted
   on training rows only (train medians, train scaler, fixed one-hot
   order).
3. :mod:`mlrag.modeling.baselines` — frozen baselines A (train majority),
   B (learner history), C (deterministic topic→learner→global fallback
   chain), all strict ``predicted_at < T`` point-in-time.
4. :mod:`mlrag.modeling.challenger` — the one L2 logistic-regression
   challenger (Gate-16-approved hyperparameters, unchanged).
5. :mod:`mlrag.modeling.metrics` — log loss + Brier (primary), accuracy,
   ROC/PR-AUC when valid, 5-bin calibration, strict beats-all comparison.
6. :mod:`mlrag.modeling.experiment` — Gate 18 split protocol + Gate-16
   leave-one-learner-out protocol with pooled comparison and cold slices.
7. :mod:`mlrag.modeling.snapshot` — live read-only runner producing the
   experiment + model artifacts.
"""

from .config import (
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
