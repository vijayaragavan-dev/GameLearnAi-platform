"""Versioned dataset contract for Gate 18 (``d1`` over frozen ``f1``).

Dataset version ``d1`` is PINNED to Gate 17 feature version ``f1``.  Any
semantic change to the dataset layout, the row-identity derivation, the
split mechanism, or the underlying feature semantics requires a new
dataset version — never a silent edit.

A dataset row contains:

* ``row_id`` — deterministic identity, derived as
  ``datarow_<sha12("gamelearn-mlrag-dataset-v1" + question_attempt_id)>``.
  The source ``question_attempt_id`` is a catalogue UUID (not PII); the
  domain-separated hash keeps dataset identity stable and opaque.  Raw
  learner IDs (``user_id``) NEVER appear anywhere.
* grouping / ordering keys: ``learner_key`` (surrogate, for splitting),
  ``predicted_at`` (ISO ``submitted_at``, for temporal evaluation),
  ``topic_id`` / ``subject_id`` / ``question_id`` / ``quiz_id`` /
  ``quiz_attempt_id`` / ``question_attempt_id`` (catalogue UUIDs, not PII).
* ``features`` — EXACTLY the 19 frozen f1 columns, NULLs preserved, never
  zero-filled, never imputed.
* ``is_correct`` — the target, 0/1, stored BESIDE ``features``, never
  inside it.
* ``split`` — one of ``train`` / ``validation`` / ``test`` / ``unassigned``.
* ``feature_version`` / ``dataset_version`` / ``data_version`` on every row.

Prohibited from dataset rows AND persisted artifacts: target-in-X,
post-attempt scores/answers, future fields, game skill fields, progress
fields, XP/streaks, emails, passwords, JWTs/tokens, raw ``user_id``,
``selected_answer``, ``duration_seconds``, ``response_time_seconds``.
"""

from __future__ import annotations

import hashlib
import re

from ..contracts.common import ContractViolation
from ..feature_pipeline.contract import (
    FEATURE_COLUMNS,
    FEATURE_VERSION,
    LEAKAGE_BLOCKLIST,
    TARGET_COLUMN,
    validate_feature_row,
)

#: Pinned dataset version for this layout + split mechanism + f1 semantics.
DATASET_VERSION = "d1"

#: Domain separator for deterministic row-identity derivation.
ROW_ID_DOMAIN = "gamelearn-mlrag-dataset-v1"

#: Dataset split names.  ``unassigned`` is terminal-only for rows built
#: without a split step; persisted datasets must not contain it.
SPLIT_NAMES = ("train", "validation", "test")
UNASSIGNED = "unassigned"

#: Keys of one dataset row (exact set, enforced by validation).
DATASET_ROW_KEYS = frozenset(
    {
        "row_id",
        "learner_key",
        "topic_id",
        "subject_id",
        "question_id",
        "quiz_id",
        "quiz_attempt_id",
        "question_attempt_id",
        "feature_version",
        "dataset_version",
        "data_version",
        "predicted_at",
        "features",
        TARGET_COLUMN,
        "split",
    }
)

#: Substrings/patterns that must never occur in a persisted dataset
#: artifact (case-insensitive key scan + content-pattern scan).
PROHIBITED_KEY_SUBSTRINGS = (
    "password",
    "jwt",
    "token",
    "secret",
    "email",
    "user_id",
    "selected_answer",
    "quiz_score",
    "correct_answer",
    "duration_seconds",
    "response_time_seconds",
    "best_combo",
    "xp_awarded",
    "game_score",
)

#: Content patterns scanned in serialized artifacts (PII / credentials).
PROHIBITED_CONTENT_PATTERNS = (
    r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}",  # email address
    r"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+",  # JWT
    r"(?i)password_hash",
    r"(?i)bearer\s+[A-Za-z0-9._~-]+",
)


def derive_row_id(question_attempt_id: object) -> str:
    """Derive the deterministic dataset row identity for one attempt."""
    digest = hashlib.sha256(
        f"{ROW_ID_DOMAIN}:{question_attempt_id}".encode("utf-8")
    ).hexdigest()[:12]
    return f"datarow_{digest}"


def validate_dataset_row(row: dict) -> None:
    """Validate one d1 dataset row.  Raises ContractViolation on breach."""
    if set(row.keys()) != DATASET_ROW_KEYS:
        missing = sorted(DATASET_ROW_KEYS - set(row.keys()))
        extra = sorted(set(row.keys()) - DATASET_ROW_KEYS)
        raise ContractViolation(
            f"d1 schema breach: missing={missing} extra={extra}"
        )
    if row.get("dataset_version") != DATASET_VERSION:
        raise ContractViolation(
            f"dataset_version must be {DATASET_VERSION!r}, "
            f"got {row.get('dataset_version')!r}"
        )
    if row.get("feature_version") != FEATURE_VERSION:
        raise ContractViolation(
            f"feature_version must be {FEATURE_VERSION!r}, "
            f"got {row.get('feature_version')!r}"
        )
    if not row.get("data_version"):
        raise ContractViolation("data_version must be non-empty")
    if not row.get("predicted_at"):
        raise ContractViolation("predicted_at must be non-empty")
    expected_id = derive_row_id(row.get("question_attempt_id"))
    if row.get("row_id") != expected_id:
        raise ContractViolation(
            f"row_id {row.get('row_id')!r} does not derive from "
            f"question_attempt_id {row.get('question_attempt_id')!r}"
        )
    if not str(row.get("learner_key", "")).startswith("learner_"):
        raise ContractViolation("learner_key must be a surrogate learner_* key")
    if row.get("split") not in SPLIT_NAMES + (UNASSIGNED,):
        raise ContractViolation(f"unknown split: {row.get('split')!r}")
    target = row.get(TARGET_COLUMN)
    if target not in (0, 1) or isinstance(target, bool):
        raise ContractViolation(f"{TARGET_COLUMN} must be 0 or 1, got {target!r}")
    features = row.get("features")
    if not isinstance(features, dict):
        raise ContractViolation("row must carry a 'features' mapping")
    if set(features.keys()) != set(FEATURE_COLUMNS):
        raise ContractViolation(
            "dataset X must be exactly the 19 frozen f1 columns, got "
            + ",".join(sorted(features.keys()))
        )
    leaked = sorted(set(features.keys()) & LEAKAGE_BLOCKLIST)
    if leaked:
        raise ContractViolation(
            "target/post-attempt fields in dataset X: " + ", ".join(leaked)
        )
    # Reuse the Gate 17 row validator for range/type/consistency rules on
    # the (feature_version, data_version, predicted_at, features, target)
    # projection — single source of truth for f1 value semantics.
    validate_feature_row(
        {
            "feature_version": row["feature_version"],
            "data_version": row["data_version"],
            "predicted_at": row["predicted_at"],
            "features": features,
            TARGET_COLUMN: target,
        }
    )


def scan_prohibited_content(serialized: str) -> list[str]:
    """Return hit descriptions for prohibited content in an artifact string."""
    hits: list[str] = []
    lowered = serialized.lower()
    for fragment in PROHIBITED_KEY_SUBSTRINGS:
        if fragment in lowered:
            hits.append(f"prohibited-substring:{fragment}")
    for pattern in PROHIBITED_CONTENT_PATTERNS:
        match = re.search(pattern, serialized)
        if match:
            hits.append(f"prohibited-pattern:{pattern}:{match.group(0)[:24]}")
    return hits
