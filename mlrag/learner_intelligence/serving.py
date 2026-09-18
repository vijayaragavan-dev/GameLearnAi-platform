"""Prediction-service contract: bounded signal or explicit fallback.

The AdaptiveEngine stays authoritative.  This module is the ONLY path by
which an ML probability may reach it, and it returns one of:

* ``Prediction`` — probability + full validity metadata, ONLY when every
  gate passes (eligible artifact, version/fingerprint match, sufficient
  history, valid range)
* ``Fallback`` — machine reason code telling the engine to use existing
  deterministic behavior

Reason codes (stable strings, auditable): ``model_unavailable``,
``model_not_eligible``, ``feature_mismatch``, ``stale_model``,
``corrupt_model``, ``cold_start``, ``insufficient_history``,
``malformed_prediction``, ``timeout``, ``invalid_request``.

History bands reuse frozen evidence, not new thresholds:
``is_cold_start`` (structural zero-history flag) and the Gate-5
``SUFFICIENT_HISTORY_MIN`` (≥10) bar.  Client-supplied predictions are
never accepted — the only ``probability`` that can reach the engine is
computed server-side from a gated artifact in this process.

Timeouts: ``score_with_deadline`` bounds inference wall-clock via a
worker thread; expiry yields ``timeout`` fallback.  Identity: the
contract takes an opaque ``learner_ref`` supplied by the authoritative
caller (future Spring wiring derives it from authentication); raw user
IDs, topics, and difficulties are validated as non-empty strings but
are NEVER used to select model files or bypass gates.
"""

from __future__ import annotations

import concurrent.futures
import math
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable

from ..contracts.common import ContractViolation
from . import artifact as artifact_mod
from . import config24


@dataclass(frozen=True)
class Prediction:
    probability: float
    model_id: str
    model_version: str
    feature_version: str
    dataset_fingerprint: str
    artifact_fingerprint: str
    cold_start: bool
    history_count: int
    latency_ms: float


@dataclass(frozen=True)
class Fallback:
    reason: str
    detail: str = ""


@dataclass(frozen=True)
class ServingRequest:
    """Validated scoring request (server-derived values only)."""

    learner_ref: str
    topic_id: str
    difficulty: str
    history_count: int
    is_cold_start: bool
    feature_row: dict

    def __post_init__(self) -> None:
        for name in ("learner_ref", "topic_id", "difficulty"):
            value = getattr(self, name)
            if not isinstance(value, str) or not value.strip():
                raise ContractViolation(f"{name} must be a non-empty string")
        if str(self.difficulty) not in ("EASY", "MEDIUM", "HARD"):
            raise ContractViolation(
                f"unknown difficulty {self.difficulty!r}")
        if not isinstance(self.history_count, int) or self.history_count < 0:
            raise ContractViolation("history_count must be a non-negative int")
        if not isinstance(self.feature_row, dict) or not self.feature_row:
            raise ContractViolation("feature_row must be a non-empty mapping")


def _load_or_fallback(path: Path, expected: dict) -> dict | Fallback:
    if not Path(path).exists():
        return Fallback(reason="model_unavailable",
                        detail="artifact file absent")
    try:
        return artifact_mod.load_for_serving(
            path,
            expected_model_id=expected["model_id"],
            expected_model_version=expected["model_version"],
            expected_feature_version=expected["feature_version"],
            expected_dataset_fingerprint=expected["dataset_fingerprint"],
        )
    except artifact_mod.StaleModel as exc:
        return Fallback(reason="stale_model", detail=str(exc))
    except artifact_mod.CorruptModel as exc:
        return Fallback(reason="corrupt_model", detail=str(exc))
    except artifact_mod.ModelNotEligible as exc:
        return Fallback(reason="model_not_eligible", detail=str(exc))
    except ContractViolation as exc:
        return Fallback(reason="feature_mismatch", detail=str(exc))
    except Exception as exc:
        return Fallback(reason="model_unavailable", detail=type(exc).__name__)


def score(request: ServingRequest, artifact_path: Path, expected: dict,
          predict_fn: Callable[[dict], float] | None = None) -> Prediction | Fallback:
    """Score one request: Prediction only if every gate passes.

    Gate order is deliberate: request-validity and history sufficiency
    are decided BEFORE touching the artifact, so cold/limited-history
    learners get the informative baseline reason without model I/O.
    """
    started = time.perf_counter()
    if request.is_cold_start or request.history_count == 0:
        return Fallback(reason="cold_start",
                        detail="no strictly-past attempts: baseline path")
    if request.history_count < config24.SUFFICIENT_HISTORY_MIN:
        return Fallback(
            reason="insufficient_history",
            detail=(f"history_count={request.history_count} < "
                    f"{config24.SUFFICIENT_HISTORY_MIN}: baseline path"))
    record = _load_or_fallback(artifact_path, expected)
    if isinstance(record, Fallback):
        return record
    if predict_fn is None:
        return Fallback(reason="model_unavailable",
                        detail="no inference function bound")
    try:
        probability = float(predict_fn(request.feature_row))
    except Exception as exc:
        return Fallback(reason="malformed_prediction",
                        detail=f"inference raised {type(exc).__name__}")
    if not math.isfinite(probability) or not 0.0 <= probability <= 1.0:
        return Fallback(reason="malformed_prediction",
                        detail=f"probability out of range: {probability!r}")
    return Prediction(
        probability=probability,
        model_id=record["model_id"],
        model_version=record["model_version"],
        feature_version=record["feature_version"],
        dataset_fingerprint=record["dataset_fingerprint"],
        artifact_fingerprint=record["artifact_fingerprint"],
        cold_start=False,
        history_count=request.history_count,
        latency_ms=round((time.perf_counter() - started) * 1000.0, 3),
    )


def score_with_deadline(request: ServingRequest, artifact_path: Path,
                        expected: dict,
                        predict_fn: Callable[[dict], float] | None = None,
                        timeout_s: float = config24.SERVE_TIMEOUT_S
                        ) -> Prediction | Fallback:
    """Bounded variant: inference exceeding ``timeout_s`` falls back."""
    with concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:
        future = pool.submit(score, request, artifact_path, expected,
                             predict_fn)
        try:
            return future.result(timeout=timeout_s)
        except concurrent.futures.TimeoutError:
            return Fallback(reason="timeout",
                            detail=f"inference exceeded {timeout_s}s")


def history_band(history_count: int, is_cold_start: bool) -> str:
    """Review helper mapping counts to the frozen bands."""
    if is_cold_start or history_count == 0:
        return "cold"
    if history_count < config24.SUFFICIENT_HISTORY_MIN:
        return "limited"
    return "sufficient"


def preprocessor_from_record(record: dict):
    """Rebuild the fitted preprocessor from artifact stats (no refit).

    Proves the persisted stats round-trip exactly; the future eligible
    serving path binds this preprocessor with the promotion-run fitted
    model.  Raises CorruptModel when stats are absent or malformed.
    """
    from ..modeling import config as g19_config
    from ..modeling import preprocessing as g19_preprocessing

    stats = record.get("preprocessing_fitted")
    if not isinstance(stats, dict):
        raise artifact_mod.CorruptModel("artifact lacks fitted stats")
    try:
        names = list(g19_config.NUMERIC_COLUMNS)
        medians = tuple(float(stats["medians"][name]) for name in names)
        means = tuple(float(stats["means"][name]) for name in names)
        scales = tuple(float(stats["scales"][name]) for name in names)
        return g19_preprocessing.FittedPreprocessor(
            medians=medians,
            means=means,
            scales=scales,
            median_fallback_columns=tuple(
                stats["median_fallback_columns"]),
            n_train_rows=int(stats["n_train_rows"]),
        )
    except (KeyError, TypeError, ValueError) as exc:
        raise artifact_mod.CorruptModel(
            f"malformed fitted stats: {exc}") from exc
