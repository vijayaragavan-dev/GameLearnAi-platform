"""Frozen Gate 19 experimental configuration (no tuning grid exists).

Challenger: L2 Logistic Regression on exactly the 19 frozen f1 features,
with the Gate-16-approved hyperparameters (C=1.0, lbfgs, max_iter=1000,
random_state=42 — carried over from the Gate-16 experimental design, now
applied to the 19-column d1 schema instead of the retired 11-column one).
ONE configuration only.  Any change here defines a new experiment, never a
silent edit.

Matrix-column specification (31 columns, fixed order):

* NUMERIC (11, standardized with train-only mean/scale):
  hist_accuracy, recent_accuracy_k5, prior_attempt_count,
  prior_correct_count, prior_total_count, topic_hist_accuracy,
  prev_mastery_score, prev_recent_accuracy, days_since_last_attempt,
  attempt_sequence_index, prev_response_time_norm
* BOOL (3, carried as 0.0/1.0, never missing per contract):
  topic_has_exposure, is_cold_start, timing_known
* ONE-HOT (17, fixed allowlist order; NULL categorical -> all-zero):
  question_difficulty x [EASY, MEDIUM, HARD],
  quiz_difficulty x [EASY, MEDIUM, HARD],
  prev_difficulty x [EASY, MEDIUM, HARD],
  prev_mastery_level x [BEGINNER, DEVELOPING, PROFICIENT, MASTERED],
  prev_trend x [IMPROVING, STABLE, DECLINING, INSUFFICIENT_DATA]

Imputation rules (all statistics TRAIN-only; documented, never silent):

* nullable numerics -> train-fold median; a train column that is entirely
  NULL falls back to 0.0 (deterministic, recorded per column);
* booleans are contract-guaranteed present (no rule needed);
* NULL categoricals encode as the all-zero one-hot vector (missingness
  stays visible to the model as the absence of every level).
"""

from __future__ import annotations

#: Experimental challenger identity (explicitly NOT production).
MODEL_ID = "logreg-pcorrect-g19"
MODEL_VERSION = "0.1.0-gate19exp"

#: Pinned data contracts consumed by this gate.
FEATURE_VERSION = "f1"
DATASET_VERSION = "d1"

#: Single frozen solver configuration (no search space).
SOLVER = "lbfgs"
C_VALUE = 1.0
MAX_ITER = 1000
RANDOM_STATE = 42

#: Fixed matrix layout.
NUMERIC_COLUMNS = (
    "hist_accuracy",
    "recent_accuracy_k5",
    "prior_attempt_count",
    "prior_correct_count",
    "prior_total_count",
    "topic_hist_accuracy",
    "prev_mastery_score",
    "prev_recent_accuracy",
    "days_since_last_attempt",
    "attempt_sequence_index",
    "prev_response_time_norm",
)

BOOL_COLUMNS = (
    "topic_has_exposure",
    "is_cold_start",
    "timing_known",
)

ONE_HOT_SPEC: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("question_difficulty", ("EASY", "MEDIUM", "HARD")),
    ("quiz_difficulty", ("EASY", "MEDIUM", "HARD")),
    ("prev_difficulty", ("EASY", "MEDIUM", "HARD")),
    (
        "prev_mastery_level",
        ("BEGINNER", "DEVELOPING", "PROFICIENT", "MASTERED"),
    ),
    (
        "prev_trend",
        ("IMPROVING", "STABLE", "DECLINING", "INSUFFICIENT_DATA"),
    ),
)

#: Flat matrix column names in transform order (31 total).
MATRIX_COLUMNS: tuple[str, ...] = (
    tuple(f"num__{c}" for c in NUMERIC_COLUMNS)
    + tuple(f"bool__{c}" for c in BOOL_COLUMNS)
    + tuple(
        f"oh__{name}__{level}"
        for name, levels in ONE_HOT_SPEC
        for level in levels
    )
)

#: Primary comparison metric (pre-registered; Gate-16 promotion contract:
#: pooled log loss + Brier vs A/B/C; accuracy reported, never decides).
PRIMARY_METRIC = "log_loss"
CO_PRIMARY_METRIC = "brier"
