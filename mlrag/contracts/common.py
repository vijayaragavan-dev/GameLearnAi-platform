"""Shared value types for the ML/RAG sidecar contracts (GATE 1).

Standard library only.  All contract dataclasses are frozen: interfaces must
never become a mutation path for learner state.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class ContractViolation(ValueError):
    """Raised when a request/response violates a sidecar contract."""


class Difficulty(str, Enum):
    """Mirrors the backend Difficulty enum (EASY/MEDIUM/HARD)."""

    EASY = "EASY"
    MEDIUM = "MEDIUM"
    HARD = "HARD"


class PredictionTarget(str, Enum):
    """Future supervised targets.  Placeholders only — no model exists."""

    CORRECTNESS = "correctness"  # P(question_attempt.is_correct); primary
    MASTERY_SCORE = "mastery_score"  # mastery estimation (future)
    DIFFICULTY_SUITABILITY = "difficulty_suitability"  # difficulty signal (future)
    RECOMMENDATION_RANK = "recommendation_rank"  # ranking score (future)


@dataclass(frozen=True)
class ModelVersion:
    """Identifies which model produced a prediction (or was expected to)."""

    model_name: str
    model_version: str
    data_snapshot_id: str = ""

    def __post_init__(self) -> None:
        if not self.model_name.strip():
            raise ContractViolation("model_name must be non-empty")
        if not self.model_version.strip():
            raise ContractViolation("model_version must be non-empty")


@dataclass(frozen=True)
class TraceContext:
    """Correlates a sidecar call with the backend request (X-Request-ID)."""

    request_id: str

    def __post_init__(self) -> None:
        if not self.request_id.strip():
            raise ContractViolation("request_id must be non-empty")
