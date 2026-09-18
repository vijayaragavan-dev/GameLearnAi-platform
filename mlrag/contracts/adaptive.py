"""Adaptive-intelligence design contracts (GATE 8, DESIGN ONLY).

Typed boundary between advisory ML/RAG signals and the authoritative
deterministic AdaptiveEngine.  These contracts carry information and
enforce bounds — they never touch MySQL, call APIs or Gemini, load
models, retrieve documents, or make production decisions.

Iron rule encoded here: on any conflict between an advisory signal and
the engine's deterministic rule, THE ENGINE WINS (see resolve_conflict).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum

from mlrag.contracts.common import ContractViolation

#: Reason codes owned by the existing AdaptiveEngine (mirror of the Java
#: constants; the engine may extend this set — advisors must tolerate that).
ENGINE_REASON_CODES = frozenset({
    "FIRST_ATTEMPT_BASELINE_SET",
    "BEGINNER_NEEDS_FOUNDATIONS",
    "RECENT_DECLINE_REMEDIATION",
    "STRONG_PERFORMANCE_INCREASES_DIFFICULTY",
    "DEVELOPING_KEEP_PRACTICING",
    "PROFICIENT_CONFIRM_WITH_QUIZ",
    "MASTERED_ADVANCE_CHALLENGE",
})

#: Cold-start tiers (GATE 4 minimum-history concept).
MIN_HISTORY_FOR_SIGNAL = 3


class SignalStatus(str, Enum):
    SERVED = "served"
    FALLBACK_COLD_START = "fallback_cold_start"
    FALLBACK_SPARSE_HISTORY = "fallback_sparse_history"
    FALLBACK_UNAVAILABLE = "fallback_unavailable"
    FALLBACK_LOW_CONFIDENCE = "fallback_low_confidence"
    FALLBACK_TIMEOUT = "fallback_timeout"
    FALLBACK_INVALID = "fallback_invalid"


class HistoryTier(str, Enum):
    COLD_START = "cold_start"
    SPARSE_HISTORY = "sparse_history"
    SUFFICIENT_HISTORY = "sufficient_history"


def classify_history(n_priors: int,
                     minimum: int = MIN_HISTORY_FOR_SIGNAL) -> HistoryTier:
    """Deterministic cold-start classification (no ML involved)."""
    if n_priors < 0:
        raise ContractViolation("n_priors must be >= 0")
    if n_priors == 0:
        return HistoryTier.COLD_START
    if n_priors < minimum:
        return HistoryTier.SPARSE_HISTORY
    return HistoryTier.SUFFICIENT_HISTORY


def _probability(value: float | None, name: str) -> None:
    if value is None:
        raise ContractViolation(f"{name} is required when served")
    if not isinstance(value, float) or not 0.0 <= value <= 1.0:
        raise ContractViolation(f"{name} must be a float in [0,1]")


@dataclass(frozen=True)
class MLSignal:
    """Bounded advisory prediction.  A prediction, never a decision."""

    status: SignalStatus
    p_correct: float | None = None
    confidence: float | None = None
    model_version: str = ""
    feature_schema_version: str = ""
    fallback_reason: str = ""

    def __post_init__(self) -> None:
        if self.status == SignalStatus.SERVED:
            _probability(self.p_correct, "p_correct")
            _probability(self.confidence, "confidence")
            if not self.model_version.strip():
                raise ContractViolation("model_version is required")
            if not self.feature_schema_version.strip():
                raise ContractViolation(
                    "feature_schema_version is required")
        else:
            if self.p_correct is not None:
                raise ContractViolation(
                    "fallback signals must not carry predictions")
            if not self.fallback_reason.strip():
                raise ContractViolation(
                    "fallback signals require a fallback_reason")


@dataclass(frozen=True)
class RAGEvidence:
    """Grounded retrieval supporting (never deciding) adaptation."""

    status: SignalStatus
    citations: tuple[str, ...] = ()
    subject_id: str = ""
    topic_id: str | None = None
    retriever_version: str = ""
    grounding_valid: bool = False
    fallback_reason: str = ""

    def __post_init__(self) -> None:
        if self.status == SignalStatus.SERVED:
            if not self.citations:
                raise ContractViolation(
                    "served evidence requires citations")
            if not self.subject_id.strip():
                raise ContractViolation("subject scope is required")
            if not self.retriever_version.strip():
                raise ContractViolation("retriever_version is required")
            if not self.grounding_valid:
                raise ContractViolation(
                    "served evidence requires valid grounding")
        elif not self.fallback_reason.strip():
            raise ContractViolation(
                "fallback evidence requires a fallback_reason")


@dataclass(frozen=True)
class DifficultySignal:
    """Advisory difficulty hint.  The engine clamps it to policy."""

    suggested: str  # EASY | MEDIUM | HARD (advisory spelling)
    basis: str  # why: e.g. "p_correct=0.82 on MEDIUM history"
    status: SignalStatus = SignalStatus.SERVED

    def __post_init__(self) -> None:
        if self.suggested not in ("EASY", "MEDIUM", "HARD"):
            raise ContractViolation(
                f"unknown difficulty suggestion: {self.suggested!r}")
        if not self.basis.strip():
            raise ContractViolation("difficulty signal requires a basis")


@dataclass(frozen=True)
class AdvisoryBundle:
    """Everything the decision layer may consider for one learner-topic."""

    learner_key: str
    topic_id: str
    ml: MLSignal
    rag: RAGEvidence
    engine_snapshot_level: str  # read-only mastery level, informational
    engine_snapshot_trend: str  # read-only trend, informational
    difficulty_hint: DifficultySignal | None = None
    created_at_iso: str = ""

    def __post_init__(self) -> None:
        if not self.learner_key.strip() or not self.topic_id.strip():
            raise ContractViolation("learner_key and topic_id are required")
        if not self.created_at_iso.strip():
            raise ContractViolation("created_at_iso is required")


@dataclass(frozen=True)
class EngineDecision:
    """Record of the AUTHORITATIVE engine outcome (written by Spring)."""

    reason_code: str
    mastery_level: str
    trend: str
    next_difficulty: str
    activity: str
    priority: int
    signals_consumed: tuple[str, ...] = ()
    signals_ignored: tuple[str, ...] = ()
    fallback_applied: bool = False

    def __post_init__(self) -> None:
        if not self.reason_code.strip():
            raise ContractViolation("engine reason_code is required")
        if self.reason_code not in ENGINE_REASON_CODES:
            raise ContractViolation(
                f"unknown engine reason code: {self.reason_code!r}")


def resolve_conflict(decision: EngineDecision,
                     ignored: tuple[str, ...]) -> EngineDecision:
    """Encode AdaptiveEngine-wins: advisory disagreement is recorded as
    ignored; the engine's fields are returned byte-identical otherwise."""
    return EngineDecision(
        reason_code=decision.reason_code,
        mastery_level=decision.mastery_level,
        trend=decision.trend,
        next_difficulty=decision.next_difficulty,
        activity=decision.activity,
        priority=decision.priority,
        signals_consumed=decision.signals_consumed,
        signals_ignored=tuple(decision.signals_ignored) + tuple(ignored),
        fallback_applied=decision.fallback_applied,
    )


@dataclass(frozen=True)
class RankedCandidate:
    """One rankable content candidate.  Rank is NOT a decision."""

    content_id: str
    eligible: bool
    rank_score: float | None = None
    ineligibility_reasons: tuple[str, ...] = ()

    def __post_init__(self) -> None:
        if not self.content_id.strip():
            raise ContractViolation("content_id is required")
        if self.rank_score is not None and not 0.0 <= self.rank_score <= 1.0:
            raise ContractViolation("rank_score must be within [0,1]")
        if self.eligible and self.ineligibility_reasons:
            raise ContractViolation(
                "eligible candidates carry no ineligibility reasons")
        if not self.eligible and not self.ineligibility_reasons:
            raise ContractViolation(
                "ineligible candidates require reasons")


def rank_candidates(
        candidates: list[RankedCandidate]) -> list[RankedCandidate]:
    """Deterministic ordering: eligible first, score desc (None last),
    content_id tie-break.  Ordering ≠ decision ≠ persistence."""
    return sorted(
        candidates,
        key=lambda c: (not c.eligible,
                       -(c.rank_score if c.rank_score is not None else -1.0),
                       c.content_id),
    )


@dataclass(frozen=True)
class ShadowRecord:
    """Shadow-mode log row: advisory + authoritative outcome + later truth."""

    advisory: AdvisoryBundle
    decision: EngineDecision
    outcome_correct: bool | None = None  # filled only after grading

    def __post_init__(self) -> None:
        if self.outcome_correct is not None and not isinstance(
                self.outcome_correct, bool):
            raise ContractViolation("outcome_correct must be bool or None")


__all__ = [
    "ENGINE_REASON_CODES",
    "MIN_HISTORY_FOR_SIGNAL",
    "SignalStatus",
    "HistoryTier",
    "classify_history",
    "MLSignal",
    "RAGEvidence",
    "DifficultySignal",
    "AdvisoryBundle",
    "EngineDecision",
    "resolve_conflict",
    "RankedCandidate",
    "rank_candidates",
    "ShadowRecord",
]
