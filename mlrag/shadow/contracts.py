"""Shadow-mode replay contracts (GATE 9, DESIGN + OFFLINE FRAMEWORK).

Separation rule enforced by structure: the predictor input contract
cannot carry the target.  Ground truth lives ONLY in OutcomeLedger /
AuthoritativeOutcome, which prediction and retrieval code never receives.
"""

from __future__ import annotations

from dataclasses import dataclass, field

from mlrag.contracts.adaptive import (AdvisoryBundle, DifficultySignal,
                                      MLSignal, RAGEvidence)
from mlrag.contracts.common import ContractViolation


@dataclass(frozen=True)
class ReplayEvent:
    """One historical learner-question opportunity, target-free.

    ``event_time_iso`` is the prediction instant T (the attempt's
    submitted_at).  No correctness, answer, score, or post-state here.
    """

    event_id: str
    learner_key: str
    event_time_iso: str
    question_id: str
    topic_id: str
    subject_id: str
    question_difficulty: str
    unit_id: str | None = None
    question_text: str | None = None  # presented stem: knowable pre-T
    replay_status: str = "pending"

    def __post_init__(self) -> None:
        for name in ("event_id", "learner_key", "event_time_iso",
                     "question_id", "topic_id", "subject_id"):
            if not getattr(self, name).strip():
                raise ContractViolation(f"{name} must be non-empty")
        if self.question_difficulty not in ("EASY", "MEDIUM", "HARD"):
            raise ContractViolation("question_difficulty must be E/M/H")
        forbidden = ("is_correct", "selected_answer", "score", "label",
                     "correct")
        for name in forbidden:
            if hasattr(self, name):
                raise ContractViolation(
                    f"ReplayEvent must not carry target field: {name}")


@dataclass(frozen=True)
class OutcomeLedger:
    """Ground truth holder.  Given to the evaluator ONLY, never to the
    predictor, retriever, or advisory builder."""

    outcomes: dict[str, bool] = field(default_factory=dict)

    def truth(self, event_id: str) -> bool:
        if event_id not in self.outcomes:
            raise ContractViolation(f"no ground truth for {event_id}")
        return self.outcomes[event_id]


@dataclass(frozen=True)
class ShadowMLResult:
    """Evaluated ML shadow output for one event (no state change)."""

    event_id: str
    signal: MLSignal
    history_tier: str  # cold_start | sparse_history | sufficient_history


@dataclass(frozen=True)
class ShadowRAGResult:
    """Evaluated RAG shadow output for one event (no state change)."""

    event_id: str
    evidence: RAGEvidence
    citations: tuple[str, ...] = ()
    n_candidates: int = 0


@dataclass(frozen=True)
class ShadowAdvisory:
    """Bounded advisory synthesis.  Advisory, never authoritative."""

    event_id: str
    bundle: AdvisoryBundle
    advisory_action: str  # e.g. PRACTICE | REVIEW | ADVANCE | FALLBACK
    reason: str
    fallback: bool = False

    def __post_init__(self) -> None:
        if not self.reason.strip():
            raise ContractViolation("advisory requires a reason")
        if self.advisory_action not in (
                "PRACTICE", "REVIEW", "REMEDIATE", "ADVANCE", "FALLBACK"):
            raise ContractViolation(
                f"unknown advisory action: {self.advisory_action!r}")


@dataclass(frozen=True)
class AuthoritativeOutcome:
    """What actually happened (grading truth + engine note).

    The deterministic engine cannot be re-invoked offline; where its exact
    historical decision is unavailable this is documented, never invented.
    """

    event_id: str
    is_correct: bool
    engine_replayed: bool = False
    engine_note: str = ("deterministic engine not re-invoked offline; "
                        "grading truth only")


@dataclass(frozen=True)
class ShadowRecord:
    """Complete offline shadow row: advisory + truth + evaluation state."""

    event: ReplayEvent
    ml: ShadowMLResult
    rag: ShadowRAGResult
    advisory: ShadowAdvisory
    outcome: AuthoritativeOutcome
    failure_injected: tuple[str, ...] = ()


__all__ = [
    "ReplayEvent",
    "OutcomeLedger",
    "ShadowMLResult",
    "ShadowRAGResult",
    "ShadowAdvisory",
    "AuthoritativeOutcome",
    "ShadowRecord",
]
