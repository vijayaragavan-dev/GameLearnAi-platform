"""Predictor port: contract between Spring Boot and future ML models (GATE 1).

The Predictor is a SIGNAL PROVIDER ONLY.  It must never modify learner
state — no mastery writes, no XP, no recommendations, no scoring.  Spring
Boot's deterministic AdaptiveEngine remains the authority and consumes
predictions as advisory inputs (clamped to difficulty bounds, gated by
cold-start rules).

No model is implemented here: this file defines the typed boundary a model
must satisfy later without redesigning the application side.
"""

from __future__ import annotations

import abc
from dataclasses import dataclass

from . import leakage
from .common import (
    ContractViolation,
    Difficulty,
    ModelVersion,
    PredictionTarget,
    TraceContext,
)

#: Allowed values for the previous-trend feature (mirrors backend enum).
_ALLOWED_TRENDS = frozenset(
    {"IMPROVING", "DECLINING", "STABLE", "INSUFFICIENT_DATA"}
)


@dataclass(frozen=True)
class PreAttemptFeatures:
    """Leak-free feature snapshot for ONE prediction at time T_pred.

    Every field is knowable BEFORE the learner submits the current item:
    identity/context keys, catalogue difficulties, and the PRIOR learner
    state snapshot (rows with last_assessed_at < T_pred).  History counts
    are nullable for cold-start learners (no fabricated history).
    """

    user_key: str
    subject_id: str
    topic_id: str
    question_id: str
    quiz_id: str
    question_difficulty: Difficulty
    quiz_difficulty: Difficulty
    prior_attempt_count: int
    prior_correct_count: int | None = None
    prior_total_count: int | None = None
    prev_mastery_score: float | None = None
    prev_mastery_level: str | None = None
    prev_recent_accuracy: float | None = None
    prev_trend: str | None = None
    prev_difficulty: Difficulty | None = None
    prior_recommendation_activity: str | None = None
    prior_recommendation_difficulty: Difficulty | None = None
    unit_id: str | None = None
    predicted_at_iso: str = ""

    def __post_init__(self) -> None:
        for name in (
            "user_key",
            "subject_id",
            "topic_id",
            "question_id",
            "quiz_id",
        ):
            if not getattr(self, name).strip():
                raise ContractViolation(f"{name} must be non-empty")
        if self.prior_attempt_count < 0:
            raise ContractViolation("prior_attempt_count must be >= 0")
        for name in ("prior_correct_count", "prior_total_count"):
            value = getattr(self, name)
            if value is not None and value < 0:
                raise ContractViolation(f"{name} must be >= 0")
        for name in ("prev_mastery_score", "prev_recent_accuracy"):
            value = getattr(self, name)
            if value is not None and not 0.0 <= value <= 100.0:
                raise ContractViolation(f"{name} must be within 0..100")
        if self.prev_trend is not None and self.prev_trend not in _ALLOWED_TRENDS:
            raise ContractViolation(f"prev_trend unknown: {self.prev_trend}")
        if not self.predicted_at_iso.strip():
            raise ContractViolation("predicted_at_iso must be non-empty")
        # Structural guarantee: none of our own field names may be a
        # post-attempt label.  Fails fast if the contract ever drifts.
        leakage.validate_feature_names(
            (f.name for f in self.__dataclass_fields__.values()), strict=True
        )


@dataclass(frozen=True)
class PredictionRequest:
    """What Spring Boot will send the sidecar (server-derived identity)."""

    trace: TraceContext
    features: PreAttemptFeatures
    target: PredictionTarget = PredictionTarget.CORRECTNESS


@dataclass(frozen=True)
class PredictionResponse:
    """What the sidecar returns.  No learner-state mutation, ever.

    ``served_by_model=False`` with a ``fallback_reason`` is the REQUIRED
    cold-start/unavailable answer (deterministic backend rules apply).
    A response claiming model service MUST carry a valid probability and
    model version; fabricating either is a contract violation.
    """

    request_id: str
    served_by_model: bool
    p_correct: float | None = None
    confidence: float | None = None
    difficulty_suitability: float | None = None
    model: ModelVersion | None = None
    fallback_reason: str = ""

    def __post_init__(self) -> None:
        if not self.request_id.strip():
            raise ContractViolation("request_id must be non-empty")
        if self.served_by_model:
            if self.p_correct is None or not 0.0 <= self.p_correct <= 1.0:
                raise ContractViolation(
                    "model-served response requires p_correct in 0..1"
                )
            if self.model is None:
                raise ContractViolation(
                    "model-served response requires model version"
                )
            if self.confidence is not None and not 0.0 <= self.confidence <= 1.0:
                raise ContractViolation("confidence must be within 0..1")
        else:
            if self.p_correct is not None:
                raise ContractViolation(
                    "fallback response must not carry a prediction "
                    "(no fabricated signals)"
                )
            if not self.fallback_reason.strip():
                raise ContractViolation(
                    "fallback response requires a fallback_reason"
                )
        if self.difficulty_suitability is not None and not (
            0.0 <= self.difficulty_suitability <= 1.0
        ):
            raise ContractViolation("difficulty_suitability must be within 0..1")


class PredictorPort(abc.ABC):
    """Abstract predictor.  Future models implement this; nothing else may."""

    @property
    @abc.abstractmethod
    def model_version(self) -> ModelVersion:
        """Version of the model behind this port."""
        raise NotImplementedError

    @abc.abstractmethod
    def supports(self, features: PreAttemptFeatures) -> bool:
        """Minimum-history / cold-start gate.  False -> caller uses fallback."""
        raise NotImplementedError

    @abc.abstractmethod
    def predict(self, request: PredictionRequest) -> PredictionResponse:
        """Return a prediction signal.  Must not mutate learner state."""
        raise NotImplementedError
