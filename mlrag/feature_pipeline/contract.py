"""Frozen feature contract for the Gate 17 point-in-time pipeline.

Feature version ``f1`` is FROZEN.  Any semantic change to a feature listed
here requires a new feature version — never a silent edit.

Feature groups (19 features total):

Learner (prior history, strictly before T):
    hist_accuracy, recent_accuracy_k5, prior_attempt_count,
    prior_correct_count, prior_total_count

Topic (pre-image mastery + prior topic history, strictly before T):
    topic_hist_accuracy, prev_mastery_score, prev_mastery_level,
    prev_recent_accuracy, prev_trend, prev_difficulty, topic_has_exposure

Question (catalogue difficulty known before T):
    question_difficulty, quiz_difficulty

Temporal (event gaps / ordering, strictly before T):
    days_since_last_attempt, attempt_sequence_index, is_cold_start

Behavior (prior validated think time only):
    prev_response_time_norm, timing_known

Target (SEPARATE from the feature vector, never a feature):
    is_correct  (1 iff question_attempts.is_correct is true, else 0)

Scale notes (authoritative backend semantics):
    * topic_mastery.mastery_score is stored 0..100 -> prev_mastery_score
      keeps the 0..100 scale (NULL when no pre-image exists).
    * topic_mastery.recent_accuracy is stored 0..100 (single-quiz accuracy
      written by AdaptiveLearningService.persistMastery) -> prev_recent_accuracy
      is converted to a 0..1 rate via /100 (NULL when no pre-image exists).
    * hist_accuracy / recent_accuracy_k5 / topic_hist_accuracy are 0..1 rates
      computed from prior eligible question attempts (NULL when empty).
"""

from __future__ import annotations

from ..contracts.common import ContractViolation

#: Frozen feature version implemented by this pipeline.
FEATURE_VERSION = "f1"

#: Target column name.  Must never appear in a feature vector.
TARGET_COLUMN = "is_correct"

#: How data_version values are formed (documented scheme, no wall-clock).
DATA_VERSION_SCHEME = (
    "snapshot:v1:counts+minmax_submitted_at+sha12(sorted eligible row ids)"
)

#: Frozen ordered feature groups.  Order here is the canonical X order.
FEATURE_GROUPS: dict[str, tuple[str, ...]] = {
    "learner": (
        "hist_accuracy",
        "recent_accuracy_k5",
        "prior_attempt_count",
        "prior_correct_count",
        "prior_total_count",
    ),
    "topic": (
        "topic_hist_accuracy",
        "prev_mastery_score",
        "prev_mastery_level",
        "prev_recent_accuracy",
        "prev_trend",
        "prev_difficulty",
        "topic_has_exposure",
    ),
    "question": (
        "question_difficulty",
        "quiz_difficulty",
    ),
    "temporal": (
        "days_since_last_attempt",
        "attempt_sequence_index",
        "is_cold_start",
    ),
    "behavior": (
        "prev_response_time_norm",
        "timing_known",
    ),
}

#: Canonical flattened feature order (19 columns).
FEATURE_COLUMNS: tuple[str, ...] = tuple(
    name for group in FEATURE_GROUPS.values() for name in group
)

#: Allowlisted catalogue difficulty values.  Anything else fails validation.
ALLOWED_DIFFICULTY = frozenset({"EASY", "MEDIUM", "HARD"})

#: Allowlisted pre-image mastery levels (mirrors backend MasteryLevel).
ALLOWED_MASTERY_LEVEL = frozenset(
    {"BEGINNER", "DEVELOPING", "PROFICIENT", "MASTERED"}
)

#: Allowlisted pre-image trends (mirrors backend MasteryTrend).
ALLOWED_TREND = frozenset(
    {"IMPROVING", "STABLE", "DECLINING", "INSUFFICIENT_DATA"}
)

#: Fields that MUST NEVER appear in a feature vector.  Covers the Gate 17
#: leakage checklist: current labels, post-images, future state, game skill
#: fields, degenerate timing, progress, and grouping identifiers used as
#: values.
LEAKAGE_BLOCKLIST = frozenset(
    {
        # Current-attempt labels / answers.
        "is_correct",
        "selected_answer",
        "correct_answer",
        "explanation",
        # Current-quiz post-attempt outcomes.
        "score",
        "quiz_score",
        "correct_count",
        "quiz_correct",
        "total_questions",
        "quiz_total",
        # Post-image mastery (current row of topic_mastery).
        "mastery_score",
        "mastery_score_current",
        "mastery_level_current",
        "recent_accuracy",
        "recent_accuracy_current",
        "trend_current",
        "attempt_count_current",
        "current_difficulty",
        "last_assessed_at",
        # Post-image / current recommendation state.
        "recommendation_current",
        "recommended_difficulty_current",
        "recommendation_reason_current",
        "activity_type",
        "recommended_difficulty",
        "reason",
        "status",
        "consumed_at",
        # Future state.
        "future_accuracy",
        "future_mastery",
        "future_outcome",
        "future_response_time",
        # Degenerate / forbidden timing.
        "response_time_seconds",
        "duration_seconds",
        # Game skill claims (engagement at most, never skill features).
        "game_score",
        "game_difficulty",
        "game_topic_id",
        "game_completed",
        "best_combo",
        "xp_awarded",
        # Progress leakage.
        "completion_percentage",
        "progress_status",
        # Gamification post-state.
        "xp",
        "streak",
        "level",
        # Grouping identifiers must not be value features.
        "user_id",
        "learner_key",
        # The target itself.
        TARGET_COLUMN,
    }
)

#: Provenance / key columns allowed alongside X (never model inputs).
META_COLUMNS = frozenset(
    {
        "learner_key",
        "topic_id",
        "subject_id",
        "question_id",
        "quiz_id",
        "quiz_attempt_id",
        "question_attempt_id",
        "feature_version",
        "data_version",
        "predicted_at",
        TARGET_COLUMN,
    }
)


def _require_bool(name: str, value: object) -> None:
    if not isinstance(value, bool):
        raise ContractViolation(f"{name} must be a boolean, got {value!r}")


def validate_feature_vector(features: dict) -> None:
    """Validate one f1 feature vector.  Raises ContractViolation on any breach.

    Checks: exact frozen key set, no blocklisted names, range/type rules,
    nullable-missing policy (missing stays None — never zero-filled here),
    difficulty allowlists.
    """
    if set(features.keys()) != set(FEATURE_COLUMNS):
        missing = sorted(set(FEATURE_COLUMNS) - set(features.keys()))
        extra = sorted(set(features.keys()) - set(FEATURE_COLUMNS))
        raise ContractViolation(
            f"f1 schema breach: missing={missing} extra={extra}"
        )
    leaked = sorted(set(features.keys()) & LEAKAGE_BLOCKLIST)
    if leaked:
        raise ContractViolation(
            "leakage blocklist violation in feature vector: "
            + ", ".join(leaked)
        )

    def rate(name: str) -> None:
        value = features[name]
        if value is None:
            return
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            raise ContractViolation(f"{name} must be a 0..1 rate or NULL")
        if not 0.0 <= float(value) <= 1.0:
            raise ContractViolation(f"{name} must be within 0..1, got {value!r}")

    for name in (
        "hist_accuracy",
        "recent_accuracy_k5",
        "topic_hist_accuracy",
        "prev_recent_accuracy",
    ):
        rate(name)

    mastery = features["prev_mastery_score"]
    if mastery is not None:
        if (
            isinstance(mastery, bool)
            or not isinstance(mastery, (int, float))
            or not 0.0 <= float(mastery) <= 100.0
        ):
            raise ContractViolation(
                f"prev_mastery_score must be within 0..100 or NULL, got {mastery!r}"
            )

    for name in ("prior_attempt_count", "prior_correct_count", "prior_total_count"):
        value = features[name]
        if (
            value is None
            or isinstance(value, bool)
            or not isinstance(value, int)
            or value < 0
        ):
            raise ContractViolation(f"{name} must be an int >= 0, got {value!r}")

    gap = features["days_since_last_attempt"]
    if gap is not None:
        if isinstance(gap, bool) or not isinstance(gap, (int, float)) or float(gap) < 0:
            raise ContractViolation(
                f"days_since_last_attempt must be >= 0 or NULL, got {gap!r}"
            )

    seq = features["attempt_sequence_index"]
    if isinstance(seq, bool) or not isinstance(seq, int) or seq < 0:
        raise ContractViolation(
            f"attempt_sequence_index must be an int >= 0, got {seq!r}"
        )

    _require_bool("is_cold_start", features["is_cold_start"])
    _require_bool("timing_known", features["timing_known"])

    rt_norm = features["prev_response_time_norm"]
    if rt_norm is not None:
        if (
            isinstance(rt_norm, bool)
            or not isinstance(rt_norm, (int, float))
            or float(rt_norm) < 0
        ):
            raise ContractViolation(
                f"prev_response_time_norm must be >= 0 or NULL, got {rt_norm!r}"
            )
    if not features["timing_known"] and rt_norm is not None:
        raise ContractViolation("timing_known=False requires prev_response_time_norm=NULL")
    if features["timing_known"] and rt_norm is None:
        raise ContractViolation("timing_known=True requires prev_response_time_norm present")

    for name in ("question_difficulty", "quiz_difficulty"):
        if features[name] not in ALLOWED_DIFFICULTY:
            raise ContractViolation(
                f"{name} must be one of {sorted(ALLOWED_DIFFICULTY)}, "
                f"got {features[name]!r}"
            )

    level = features["prev_mastery_level"]
    if level is not None and level not in ALLOWED_MASTERY_LEVEL:
        raise ContractViolation(f"prev_mastery_level unknown: {level!r}")
    trend = features["prev_trend"]
    if trend is not None and trend not in ALLOWED_TREND:
        raise ContractViolation(f"prev_trend unknown: {trend!r}")
    prev_diff = features["prev_difficulty"]
    if prev_diff is not None and prev_diff not in ALLOWED_DIFFICULTY:
        raise ContractViolation(f"prev_difficulty unknown: {prev_diff!r}")

    # Cross-field consistency: empty history implies cold start + NULL rates.
    if features["prior_total_count"] == 0:
        if features["is_cold_start"] is not True:
            raise ContractViolation("empty history requires is_cold_start=True")
        for name in ("hist_accuracy", "recent_accuracy_k5"):
            if features[name] is not None:
                raise ContractViolation(f"{name} must be NULL with empty history")
    else:
        if features["is_cold_start"] is not False:
            raise ContractViolation("non-empty history requires is_cold_start=False")
        if features["hist_accuracy"] is None:
            raise ContractViolation("hist_accuracy must be present with history")


def validate_feature_row(row: dict) -> None:
    """Validate a full output row (keys + X + target + provenance)."""
    if row.get("feature_version") != FEATURE_VERSION:
        raise ContractViolation(
            f"feature_version must be {FEATURE_VERSION!r}, "
            f"got {row.get('feature_version')!r}"
        )
    if not row.get("data_version"):
        raise ContractViolation("data_version must be non-empty")
    if not row.get("predicted_at"):
        raise ContractViolation("predicted_at must be non-empty")
    target = row.get(TARGET_COLUMN)
    if target not in (0, 1) or isinstance(target, bool):
        raise ContractViolation(f"{TARGET_COLUMN} must be 0 or 1, got {target!r}")
    features = row.get("features")
    if not isinstance(features, dict):
        raise ContractViolation("row must carry a 'features' mapping")
    validate_feature_vector(features)
