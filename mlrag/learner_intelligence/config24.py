"""Frozen Gate 24 configuration (no tuning grid exists).

Challenger E: a deliberately CONSTRAINED random forest on the frozen
31-column f1 matrix.  Justification for this family at n≈60:

* tiny data → shallow trees (max_depth=3) + large leaves
  (min_samples_leaf=5, min_samples_split=10) curb variance; bagging
  averages residual noise instead of memorizing 52 training rows
* mixed numeric/one-hot matrix → trees need no scaling assumptions
  beyond the frozen preprocessor (reused unchanged)
* interpretability → impurity importances for engineering review
* CPU trivial (64 shallow trees, n_jobs=1); deterministic with a pinned
  seed (bootstrap is the only randomness; random_state=42 + n_jobs=1
  fixes it — verified by refit-identical test)
* max_features="sqrt" decorrelates trees on a 31-column matrix where
  most columns are sparse one-hots

Rejected without trial: deep nets / transformers / LLMs / RL
(absurd sample complexity at n=60); gradient boosting (sequential
fitting amplifies overfit on 14 training negatives; RF bagging is the
conservative choice); larger forests/deeper trees (variance without
evidence).

ONE configuration only.  Any change defines a new experiment.
"""

from __future__ import annotations

#: Experimental challenger identity (explicitly NOT production).
MODEL_ID = "rf-pcorrect-g24"
MODEL_VERSION = "0.1.0-gate24exp"

#: Pinned data contracts consumed by this gate (unchanged from Gate 19).
FEATURE_VERSION = "f1"
DATASET_VERSION = "d1"

#: Single frozen forest configuration (no search space).
N_ESTIMATORS = 64
MAX_DEPTH = 3
MIN_SAMPLES_SPLIT = 10
MIN_SAMPLES_LEAF = 5
MAX_FEATURES = "sqrt"
RANDOM_STATE = 42
N_JOBS = 1

#: Cold-start bands.  `cold` reuses the existing f1 `is_cold_start`
#: flag (zero strictly-past attempts — structural, not a threshold).
#: `sufficient_history` reuses the frozen Gate-5 bar (≥10 attempts per
#: learner); `limited_history` is everything in between.  No new
#: arbitrary thresholds are introduced.
SUFFICIENT_HISTORY_MIN = 10

#: Numerical tolerance for refit-identical reproducibility checks.
NUMERICAL_TOLERANCE = 1e-9

#: Minimum training evidence that could justify fitting a recalibrator.
#: Current data (≈52 train rows, ≈14 negatives) is far below this, so
#: recalibration is declined by rule (see calibration24).
RECALIBRATION_MIN_TRAIN_N = 200
RECALIBRATION_MIN_CLASS_N = 50

#: Serving inference deadline (seconds) for the bounded-score wrapper.
SERVE_TIMEOUT_S = 2.0

__all__ = [
    "DATASET_VERSION",
    "FEATURE_VERSION",
    "MAX_DEPTH",
    "MAX_FEATURES",
    "MIN_SAMPLES_LEAF",
    "MIN_SAMPLES_SPLIT",
    "MODEL_ID",
    "MODEL_VERSION",
    "NUMERICAL_TOLERANCE",
    "N_ESTIMATORS",
    "N_JOBS",
    "RANDOM_STATE",
    "RECALIBRATION_MIN_CLASS_N",
    "RECALIBRATION_MIN_TRAIN_N",
    "SERVE_TIMEOUT_S",
    "SUFFICIENT_HISTORY_MIN",
]
