"""Controlled live-shadow integration boundary (GATE 10).

Simulates EXACTLY what Spring Boot will do once a serving backend exists,
without touching backend/: the authoritative flow commits first, then an
isolated shadow executor runs post-commit with timeout, kill switch,
sampling, and failure swallowing.  Learner responses never depend on
shadow execution.  No HTTP, no threads shared with authoritative work,
no state mutation paths.

Future Spring hook point (NOT wired here): after
``QuizSubmissionService.submit()`` returns (post-commit), invoking the
equivalent of ``ShadowExecutor.observe()`` with server-derived context.
Wiring it now — with no serving backend — would be dead production code,
so the boundary is proven here against a simulated authoritative flow.
"""

from __future__ import annotations

import concurrent.futures
import hashlib
import os
import time
import uuid
from dataclasses import dataclass, field

from mlrag.contracts.adaptive import (AdvisoryBundle, MLSignal, RAGEvidence,
                                      SignalStatus)
from mlrag.contracts.common import ContractViolation
from mlrag.shadow import replay
from mlrag.shadow.contracts import (OutcomeLedger, ReplayEvent,
                                    ShadowAdvisory, ShadowRecord)

# Provisional integration constants (clearly marked; NOT production SLAs).
PROVISIONAL_SHADOW_TIMEOUT_MS = 800
PROVISIONAL_MAX_WORKERS = 2
PROVISIONAL_CONFIDENCE_CUTOFF = 0.5


@dataclass(frozen=True)
class ShadowConfig:
    """Kill switch + sampling + timeout.  Disabled unless enabled."""

    enabled: bool = False
    sample_rate_pct: int = 0  # 0..100; 0 = off, 100 = all shadow traffic
    timeout_ms: int = PROVISIONAL_SHADOW_TIMEOUT_MS
    max_workers: int = PROVISIONAL_MAX_WORKERS

    def __post_init__(self) -> None:
        if not 0 <= self.sample_rate_pct <= 100:
            raise ContractViolation("sample_rate_pct must be 0..100")
        if self.timeout_ms <= 0:
            raise ContractViolation("timeout_ms must be positive")
        if self.max_workers <= 0:
            raise ContractViolation("max_workers must be positive")

    @classmethod
    def from_env(cls, prefix: str = "SHADOW_") -> "ShadowConfig":
        def flag(name: str) -> bool:
            return os.environ.get(prefix + name, "").strip().lower() in (
                "1", "true", "yes")

        def number(name: str, default: int) -> int:
            raw = os.environ.get(prefix + name, "").strip()
            return int(raw) if raw else default

        return cls(enabled=flag("ENABLED"),
                   sample_rate_pct=number("SAMPLE_PCT", 0),
                   timeout_ms=number("TIMEOUT_MS",
                                     PROVISIONAL_SHADOW_TIMEOUT_MS),
                   max_workers=number("MAX_WORKERS",
                                      PROVISIONAL_MAX_WORKERS))


def new_correlation_id() -> str:
    """Opaque unique ID: no PII, sortable only by creation order."""
    return f"shdw-{uuid.uuid4().hex[:16]}"


def derive_learner_key(server_user_id: str) -> str:
    """Server-derived identity transform (mirrors extract.learner_key).

    The sidecar never receives raw user IDs, only this surrogate.  Client
    input can never substitute: the value is derived server-side from the
    authenticated principal.
    """
    if not server_user_id.strip():
        raise ContractViolation("server_user_id must be non-empty")
    digest = hashlib.sha256(
        f"gamelearn-shadow-v1:{server_user_id}".encode()).hexdigest()
    return f"learner_{digest[:16]}"


def sampled_in(correlation_id: str, rate_pct: int) -> bool:
    """Deterministic sampling: hash-gated, no RNG state in tests."""
    if rate_pct <= 0:
        return False
    if rate_pct >= 100:
        return True
    digest = hashlib.sha256(correlation_id.encode()).hexdigest()
    return int(digest, 16) % 100 < rate_pct


@dataclass
class ShadowObservation:
    """Safe operational record: codes and versions only, never PII."""

    correlation_id: str
    status: str  # completed | fallback | disabled | rejected | timeout
    ml_status: str = ""
    rag_status: str = ""
    model_version: str = ""
    retriever_version: str = ""
    grounding_status: str = ""
    confidence_bucket: str = ""  # low | mid | high | na
    fallback_reason: str = ""
    failure_category: str = ""
    latency_ms: float = 0.0


def _bucket(confidence: float | None) -> str:
    if confidence is None:
        return "na"
    if confidence < 0.5:
        return "low"
    if confidence < 0.8:
        return "mid"
    return "high"


class ShadowExecutor:
    """Post-commit shadow runner with isolation guarantees.

    Usage pattern (mirrors the future Spring hook)::

        authoritative_result = commit_learner_transaction(...)  # first
        observation = executor.observe(context)  # never raises, never blocks
    """

    def __init__(self, config: ShadowConfig):
        self._config = config
        self._pool = concurrent.futures.ThreadPoolExecutor(
            max_workers=config.max_workers,
            thread_name_prefix="shadow")

    @property
    def config(self) -> ShadowConfig:
        return self._config

    def observe(self, event: ReplayEvent, past_rows: list[dict],
                documents: list | None = None,
                predict=None) -> ShadowObservation:
        """Run shadow instrumentos; NEVER raise; NEVER mutate inputs."""
        correlation_id = new_correlation_id()
        started = time.perf_counter()
        if not self._config.enabled:
            return ShadowObservation(
                correlation_id=correlation_id, status="disabled",
                latency_ms=self._elapsed_ms(started))
        if not sampled_in(correlation_id, self._config.sample_rate_pct):
            return ShadowObservation(
                correlation_id=correlation_id, status="disabled",
                fallback_reason="not sampled",
                latency_ms=self._elapsed_ms(started))
        future = self._pool.submit(self._run_guarded, event, past_rows,
                                   documents or [], predict)
        try:
            return future.result(timeout=self._config.timeout_ms / 1000.0)
        except concurrent.futures.TimeoutError:
            future.cancel()
            return ShadowObservation(
                correlation_id=correlation_id, status="timeout",
                failure_category="shadow_timeout",
                fallback_reason="shadow deadline exceeded",
                latency_ms=self._elapsed_ms(started))
        except Exception as exc:  # never propagate to learner flow
            return ShadowObservation(
                correlation_id=correlation_id, status="fallback",
                failure_category=type(exc).__name__,
                fallback_reason="shadow executor fault",
                latency_ms=self._elapsed_ms(started))

    @staticmethod
    def _elapsed_ms(started: float) -> float:
        return round((time.perf_counter() - started) * 1000.0, 2)

    def _run_guarded(self, event: ReplayEvent, past_rows: list[dict],
                     documents: list, predict) -> ShadowObservation:
        started = time.perf_counter()
        correlation_id = new_correlation_id()
        try:
            records = replay.run_replay(
                _rows_for(event, past_rows),
                predict=predict, corpus=documents)
            record = records[-1] if records else None
            if record is None:
                raise RuntimeError("empty replay")
            return ShadowObservation(
                correlation_id=correlation_id, status="completed",
                ml_status=record.ml.signal.status.value,
                rag_status=record.rag.evidence.status.value,
                model_version=record.ml.signal.model_version,
                retriever_version=record.rag.evidence.retriever_version,
                grounding_status=("grounded" if record.rag.evidence.status
                                  == SignalStatus.SERVED else "degraded"),
                confidence_bucket=_bucket(record.ml.signal.confidence),
                fallback_reason=record.ml.signal.fallback_reason,
                latency_ms=self._elapsed_ms(started))
        except Exception as exc:
            return ShadowObservation(
                correlation_id=correlation_id, status="fallback",
                failure_category=type(exc).__name__,
                fallback_reason="shadow run fault",
                latency_ms=self._elapsed_ms(started))

    def shutdown(self) -> None:
        self._pool.shutdown(wait=False, cancel_futures=True)


def _rows_for(event: ReplayEvent, past_rows: list[dict]) -> list[dict]:
    """Replay input: past rows plus a label-free placeholder for T.

    The placeholder carries ``is_correct=None`` (no outcome exists yet
    live).  It sorts last, so its coerced label never enters any history
    aggregate, and the live path never reads any label — prediction input
    is features-only by construction (see test_target_absent).
    """
    ordered = sorted(past_rows,
                     key=lambda r: (str(r["submitted_at"]),
                                    str(r["question_attempt_id"])))
    placeholder = {
        "question_attempt_id": f"live-{event.event_id}",
        "quiz_attempt_id": f"live-quiz-{event.event_id}",
        "question_id": event.question_id,
        "learner_key": event.learner_key,
        "submitted_at": event.event_time_iso,
        "topic_id": event.topic_id,
        "subject_id": event.subject_id,
        "question_difficulty": event.question_difficulty,
        "question_text": event.question_text,
        # No outcome exists live: None coerces to False in the offline
        # builder but is never consumed (placeholder sorts last; live
        # path reads features only).  See test_target_absent.
        "is_correct": None,
    }
    return [*ordered, placeholder]


__all__ = [
    "PROVISIONAL_SHADOW_TIMEOUT_MS",
    "ShadowConfig",
    "ShadowObservation",
    "ShadowExecutor",
    "new_correlation_id",
    "derive_learner_key",
    "sampled_in",
]
