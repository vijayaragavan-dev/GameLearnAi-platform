"""Dataset construction from Gate 17 feature rows (GATE 18).

The dataset layer CONSUMES ``mlrag.feature_pipeline.builder`` output — it
never reimplements feature logic.  Construction guarantees:

* one dataset row per eligible Gate 17 question-attempt row;
* deterministic ordering by ``(predicted_at, quiz_attempt_id,
  question_attempt_id)`` (re-sorted defensively; Gate 17 rows already
  arrive in this order);
* deterministic ``row_id`` derivation (see
  :mod:`mlrag.dataset.contract`);
* exact frozen f1 feature set, NULLs preserved — no zero-filling, no
  imputation, no fabricated values;
* target ``is_correct`` stored beside ``features``, never inside it;
* Gate 17 ``provenance.quarantined_post_attempt`` (post-attempt scores)
  is NOT carried into the dataset — persisted datasets contain no
  post-attempt values at all;
* every row validated against the d1 contract (loud failure, never
  silently shipped or silently discarded — invalid rows become explicit
  rejections with reasons).

The dataset fingerprint is
``sha256(canonical-JSON({dataset_version, feature_version, data_version,
ordered rows})))``.  Same input rows produce the same version, ordering,
identities, statistics, and fingerprint.  No wall-clock, no randomness.
"""

from __future__ import annotations

import hashlib
import json
from typing import Any

from ..contracts.common import ContractViolation
from ..feature_pipeline.contract import FEATURE_VERSION, TARGET_COLUMN
from .contract import (
    DATASET_VERSION,
    UNASSIGNED,
    derive_row_id,
    validate_dataset_row,
)


def _canonical(value: Any) -> str:
    return json.dumps(value, sort_keys=True, default=str)


def dataset_row_from_feature_row(feature_row: dict) -> dict:
    """Convert one validated Gate 17 row into one d1 dataset row."""
    features = feature_row.get("features")
    if not isinstance(features, dict):
        raise ContractViolation("feature row must carry a 'features' mapping")
    row = {
        "row_id": derive_row_id(feature_row.get("question_attempt_id")),
        "learner_key": str(feature_row.get("learner_key")),
        "topic_id": str(feature_row.get("topic_id")),
        "subject_id": str(feature_row.get("subject_id")),
        "question_id": str(feature_row.get("question_id")),
        "quiz_id": str(feature_row.get("quiz_id")),
        "quiz_attempt_id": str(feature_row.get("quiz_attempt_id")),
        "question_attempt_id": str(feature_row.get("question_attempt_id")),
        "feature_version": str(feature_row.get("feature_version")),
        "dataset_version": DATASET_VERSION,
        "data_version": str(feature_row.get("data_version")),
        "predicted_at": str(feature_row.get("predicted_at")),
        "features": dict(features),
        TARGET_COLUMN: feature_row.get(TARGET_COLUMN),
        "split": UNASSIGNED,
    }
    validate_dataset_row(row)
    return row


def build_dataset(
    feature_rows: list[dict],
    data_version: str = "",
) -> dict[str, Any]:
    """Build a d1 dataset from Gate 17 feature rows.

    Returns ``{"dataset_version", "feature_version", "data_version",
    "fingerprint", "rows", "rejections"}``.  Invalid rows are collected
    as explicit rejections (never silently dropped); the dataset only
    contains fully validated rows.
    """
    ordered = sorted(
        (dict(r) for r in feature_rows),
        key=lambda r: (
            str(r.get("predicted_at")),
            str(r.get("quiz_attempt_id")),
            str(r.get("question_attempt_id")),
        ),
    )
    rows: list[dict] = []
    rejections: list[dict] = []
    for source in ordered:
        try:
            rows.append(dataset_row_from_feature_row(source))
        except ContractViolation as exc:
            rejections.append(
                {
                    "question_attempt_id": str(
                        source.get("question_attempt_id")
                    ),
                    "quiz_attempt_id": str(source.get("quiz_attempt_id")),
                    "learner_key": str(source.get("learner_key")),
                    "reason": f"dataset_validation:{exc}",
                }
            )
    resolved_data_version = data_version or (
        rows[0]["data_version"] if rows else "empty"
    )
    dataset = {
        "dataset_version": DATASET_VERSION,
        "feature_version": FEATURE_VERSION,
        "data_version": resolved_data_version,
        "rows": rows,
        "rejections": rejections,
    }
    dataset["fingerprint"] = fingerprint_dataset(dataset)
    return dataset


def fingerprint_dataset(dataset: dict[str, Any]) -> str:
    """Deterministic fingerprint over versions + ordered dataset rows."""
    payload = {
        "dataset_version": dataset.get("dataset_version"),
        "feature_version": dataset.get("feature_version"),
        "data_version": dataset.get("data_version"),
        "rows": dataset.get("rows", []),
    }
    return hashlib.sha256(_canonical(payload).encode("utf-8")).hexdigest()


def datasets_equal(first: dict[str, Any], second: dict[str, Any]) -> bool:
    """Canonical equality used for determinism / parity checks."""
    return _canonical(first) == _canonical(second)
