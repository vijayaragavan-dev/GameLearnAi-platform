"""Leakage-prevention rules for the ML/RAG sidecar (GATE 1).

Prediction time T_pred = BEFORE the learner submits the current quiz/item.
Anything computed from the current submission is a POST-attempt label and
must NEVER appear in a pre-attempt feature set.  Derived from the GATE 0.5
field-provenance audit (QuizSubmissionService, AdaptiveLearningService,
AssessmentService write sites).

SAFE (pre-attempt, known before T_pred):
  prior mastery snapshot, prior attempt count, prior recent accuracy,
  prior trend, prior difficulty, prior ACTIVE recommendation, question /
  quiz difficulty, subject/topic/question/quiz IDs, ordered prior history,
  timestamps and time gaps.

BLOCKED (post-attempt or untrusted — target leakage if used as features):
  post-image topic_mastery.*, current recommendation row, current score /
  correctness, selected answers, response_time_seconds (always NULL today),
  duration_seconds (degenerate server delta), game_results.* skill fields.
"""

from __future__ import annotations

from typing import Iterable, Mapping

from .common import ContractViolation

#: Logical feature names that are safe to use BEFORE the prediction target.
PRE_ATTEMPT_ALLOWLIST = frozenset(
    {
        "user_key",
        "subject_id",
        "topic_id",
        "unit_id",
        "question_id",
        "quiz_id",
        "question_difficulty",
        "quiz_difficulty",
        "prior_attempt_count",
        "prior_correct_count",
        "prior_total_count",
        "prev_mastery_score",
        "prev_mastery_level",
        "prev_recent_accuracy",
        "prev_trend",
        "prev_difficulty",
        "prior_recommendation_activity",
        "prior_recommendation_difficulty",
        "predicted_at_iso",
        "history_order",
        "days_since_last_attempt",
    }
)

#: Field names that MUST NOT appear in a pre-attempt feature set.
POST_ATTEMPT_BLOCKLIST = frozenset(
    {
        # Post-image topic_mastery (contain the current outcome).
        "mastery_score",
        "mastery_score_current",
        "recent_accuracy",
        "recent_accuracy_current",
        "trend_current",
        "attempt_count_current",
        "current_difficulty",
        "last_assessed_at",
        # Current recommendation row (derived from the current decision).
        "recommendation_current",
        "recommended_difficulty_current",
        "recommendation_reason_current",
        # Current attempt/question labels.
        "score",
        "correct_count",
        "is_correct",
        "selected_answer",
        "correct_answer",
        "explanation",
        # Degenerate / unavailable timing signals.
        "response_time_seconds",
        "duration_seconds",
        # Untrusted game skill signals (engagement at most, never labels).
        "game_score",
        "game_difficulty",
        "game_topic_id",
        "game_completed",
        "best_combo",
        "xp_awarded",
        # Anything explicitly from the future.
        "future_accuracy",
        "future_mastery",
        "future_outcome",
    }
)


def validate_feature_names(
    names: Iterable[str], *, strict: bool = False
) -> tuple[str, ...]:
    """Validate a pre-attempt feature-name collection.

    Always rejects blocklisted (post-attempt/untrusted) names.  With
    ``strict=True`` also rejects names outside the allowlist.  Returns the
    names as a tuple on success.
    """
    seen = tuple(names)
    leaked = sorted(set(seen) & POST_ATTEMPT_BLOCKLIST)
    if leaked:
        raise ContractViolation(
            "post-attempt/untrusted fields must not be features: "
            + ", ".join(leaked)
        )
    if strict:
        unknown = sorted(set(seen) - PRE_ATTEMPT_ALLOWLIST)
        if unknown:
            raise ContractViolation(
                "unknown feature names (strict mode): " + ", ".join(unknown)
            )
    return seen


def validate_feature_mapping(mapping: Mapping[str, object]) -> None:
    """Validate the keys of a feature mapping (non-strict)."""
    validate_feature_names(mapping.keys())
