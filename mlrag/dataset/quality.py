"""Data-quality audit, missingness, target, identity, and readiness (GATE 18).

All functions are deterministic and side-effect free.  Missing values are
reported with semantic meaning preserved:

* genuinely unknown / structurally unavailable -> NULL (never imputed here);
* known zero stays a numeric zero (e.g. ``prior_*_count == 0``);
* cold start is an explicit boolean (``is_cold_start``), not inferred.

Gate-5 readiness thresholds are evaluated UNMODIFIED (50 learners, 5000
rows, 60 days, >= 10 observations per learner, 200 calibration
observations, bias <= 0.05).  The bias proxy available without a model is
``abs(positive_rate - 0.5)``; true calibration bias needs a model and is
reported as unevaluable in this gate.
"""

from __future__ import annotations

from datetime import datetime
from typing import Any

from ..feature_pipeline.contract import FEATURE_COLUMNS
from .contract import TARGET_COLUMN, scan_prohibited_content
from .split import SPLIT_NAMES

#: Gate-5 readiness bars (frozen; evaluated, never altered here).
READINESS_LEARNERS = 50
READINESS_ROWS = 5000
READINESS_DAYS = 60
READINESS_MIN_PER_LEARNER = 10
READINESS_CALIBRATION_ROWS = 200
READINESS_MAX_BIAS = 0.05

#: Features singled out for missingness attention (§5).
FOCUS_FEATURES = (
    "prev_mastery_score",
    "prev_mastery_level",
    "prev_recent_accuracy",
    "prev_trend",
    "prev_difficulty",
    "prev_response_time_norm",
    "timing_known",
    "days_since_last_attempt",
)


def _parse_stamp(value: object) -> datetime | None:
    if not isinstance(value, str) or not value.strip():
        return None
    try:
        return datetime.fromisoformat(value.strip().replace("Z", "+00:00"))
    except ValueError:
        return None


def audit_dataset(
    rows: list[dict],
    rejections: list[dict] | None = None,
) -> dict[str, Any]:
    """Full §4 data-quality audit over validated dataset rows."""
    rejections = rejections or []
    targets = [r.get(TARGET_COLUMN) for r in rows]
    positives = sum(1 for t in targets if t == 1)
    negatives = sum(1 for t in targets if t == 0)
    invalid_targets = [
        str(r.get("row_id")) for r in rows if t_not01(r.get(TARGET_COLUMN))
    ]
    learners = sorted({str(r["learner_key"]) for r in rows})
    per_learner = {
        learner: sum(1 for r in rows if str(r["learner_key"]) == learner)
        for learner in learners
    }
    per_topic: dict[str, int] = {}
    for r in rows:
        per_topic[str(r["topic_id"])] = per_topic.get(str(r["topic_id"]), 0) + 1
    per_quiz: dict[str, int] = {}
    for r in rows:
        per_quiz[str(r["quiz_id"])] = per_quiz.get(str(r["quiz_id"]), 0) + 1
    stamps = sorted(str(r["predicted_at"]) for r in rows)
    cold = sum(1 for r in rows if r["features"].get("is_cold_start") is True)
    timing = sum(1 for r in rows if r["features"].get("timing_known") is True)
    preimage = sum(
        1 for r in rows if r["features"].get("prev_mastery_score") is not None
    )
    qdiff: dict[str, int] = {}
    zdiff: dict[str, int] = {}
    for r in rows:
        qdiff[str(r["features"].get("question_difficulty"))] = (
            qdiff.get(str(r["features"].get("question_difficulty")), 0) + 1
        )
        zdiff[str(r["features"].get("quiz_difficulty"))] = (
            zdiff.get(str(r["features"].get("quiz_difficulty")), 0) + 1
        )
    reasons: dict[str, int] = {}
    for rej in rejections:
        key = str(rej.get("reason", "unknown")).split(":")[0]
        reasons[key] = reasons.get(key, 0) + 1
    n = len(rows)
    return {
        "total_rows": n,
        "unique_learners": len(learners),
        "unique_topics": len(per_topic),
        "unique_quizzes": len(per_quiz),
        "unique_questions": len({str(r["question_id"]) for r in rows}),
        "earliest_predicted_at": stamps[0] if stamps else None,
        "latest_predicted_at": stamps[-1] if stamps else None,
        "positive_count": positives,
        "negative_count": negatives,
        "positive_rate": (positives / n) if n else None,
        "negative_rate": (negatives / n) if n else None,
        "invalid_target_rows": invalid_targets,
        "cold_start_count": cold,
        "cold_start_rate": (cold / n) if n else None,
        "timing_known_count": timing,
        "timing_known_rate": (timing / n) if n else None,
        "mastery_preimage_count": preimage,
        "mastery_preimage_rate": (preimage / n) if n else None,
        "question_difficulty_distribution": qdiff,
        "quiz_difficulty_distribution": zdiff,
        "attempts_per_learner": per_learner,
        "attempts_per_topic": per_topic,
        "rows_per_quiz": per_quiz,
        "invalid_row_count": len(invalid_targets),
        "rejected_row_count": len(rejections),
        "rejection_reasons": reasons,
    }


def t_not01(value: object) -> bool:
    return value not in (0, 1) or isinstance(value, bool)


def missingness_report(rows: list[dict]) -> dict[str, Any]:
    """NULL / non-NULL counts and rates for all 19 features."""
    n = len(rows)
    per_feature: dict[str, dict[str, Any]] = {}
    for name in FEATURE_COLUMNS:
        nulls = sum(1 for r in rows if r["features"].get(name) is None)
        per_feature[name] = {
            "null_count": nulls,
            "non_null_count": n - nulls,
            "null_rate": (nulls / n) if n else None,
        }
    cold_nulls = {
        name: per_feature[name]["null_count"]
        for name in ("hist_accuracy", "recent_accuracy_k5",
                     "topic_hist_accuracy", "days_since_last_attempt")
    }
    return {
        "total_rows": n,
        "per_feature": per_feature,
        "focus_features": {
            name: per_feature[name] for name in FOCUS_FEATURES
        },
        "cold_start_nullables": cold_nulls,
        "note": (
            "NULL = genuinely unknown or structurally unavailable "
            "(e.g. in-place mastery pre-image destroyed, no prior timing). "
            "Known zeros (prior counts == 0) and cold-start flags are "
            "explicit values, never NULL. No imputation applied."
        ),
    }


def identity_audit(rows: list[dict]) -> dict[str, Any]:
    """Duplicate / identity audit over deterministic row identities."""
    seen_ids: dict[str, int] = {}
    seen_attempts: dict[str, int] = {}
    for r in rows:
        seen_ids[str(r["row_id"])] = seen_ids.get(str(r["row_id"]), 0) + 1
        seen_attempts[str(r["question_attempt_id"])] = (
            seen_attempts.get(str(r["question_attempt_id"]), 0) + 1
        )
    dup_ids = sorted(k for k, c in seen_ids.items() if c > 1)
    dup_attempts = sorted(k for k, c in seen_attempts.items() if c > 1)
    exact: dict[str, int] = {}
    for r in rows:
        key = (
            str(r["learner_key"]), str(r["predicted_at"]),
            str(r["quiz_attempt_id"]), str(r["question_attempt_id"]),
        )
        flat = "|".join(key)
        exact[flat] = exact.get(flat, 0) + 1
    return {
        "row_count": len(rows),
        "unique_row_ids": len(seen_ids),
        "duplicate_row_id_count": len(dup_ids),
        "duplicate_row_ids": dup_ids,
        "duplicate_question_attempt_id_count": len(dup_attempts),
        "duplicate_question_attempt_ids": dup_attempts,
        "exact_duplicate_row_count": sum(c - 1 for c in exact.values()
                                         if c > 1),
        "identity_pass": not dup_ids and not dup_attempts,
    }


def artifact_safety_scan(serialized_artifact: str) -> dict[str, Any]:
    """Scan a serialized dataset artifact for prohibited content."""
    hits = scan_prohibited_content(serialized_artifact)
    return {
        "bytes": len(serialized_artifact),
        "hits": hits,
        "safety_pass": not hits,
    }


def split_audit(
    rows: list[dict], split_metadata: dict[str, Any]
) -> dict[str, Any]:
    """Row/learner counts and temporal ranges per split (§4 tail)."""
    per_split = split_metadata.get("per_split", {})
    summary: dict[str, dict[str, Any]] = {}
    for name in SPLIT_NAMES:
        info = per_split.get(name, {})
        summary[name] = {
            "rows": info.get("rows", 0),
            "learners": info.get("learners", 0),
            "min_predicted_at": info.get("min_predicted_at"),
            "max_predicted_at": info.get("max_predicted_at"),
            "positives": info.get("positives", 0),
            "negatives": info.get("negatives", 0),
            "usable": info.get("usable", False),
        }
    row_splits = {str(r["row_id"]): str(r.get("split")) for r in rows}
    unlabeled = sorted(rid for rid, s in row_splits.items()
                       if s not in SPLIT_NAMES)
    return {
        "per_split": summary,
        "unlabeled_row_count": len(unlabeled),
        "unlabeled_row_ids": unlabeled,
        "split_pass": not unlabeled,
    }


def readiness_evaluation(audit: dict[str, Any]) -> dict[str, Any]:
    """Evaluate Gate-5 bars UNMODIFIED; distinguish engineering/readiness."""
    n_learners = audit["unique_learners"]
    n_rows = audit["total_rows"]
    per_learner = audit["attempts_per_learner"] or {}
    min_depth = min(per_learner.values()) if per_learner else 0
    earliest = _parse_stamp(audit.get("earliest_predicted_at"))
    latest = _parse_stamp(audit.get("latest_predicted_at"))
    span_days = (
        (latest - earliest).total_seconds() / 86400.0
        if earliest and latest else 0.0
    )
    pos_rate = audit.get("positive_rate")
    bias = abs(pos_rate - 0.5) if pos_rate is not None else None
    criteria = {
        "learners_ge_50": {
            "observed": n_learners, "required": READINESS_LEARNERS,
            "pass": n_learners >= READINESS_LEARNERS,
        },
        "rows_ge_5000": {
            "observed": n_rows, "required": READINESS_ROWS,
            "pass": n_rows >= READINESS_ROWS,
        },
        "span_days_ge_60": {
            "observed": round(span_days, 2), "required": READINESS_DAYS,
            "pass": span_days >= READINESS_DAYS,
        },
        "min_per_learner_ge_10": {
            "observed": min_depth, "required": READINESS_MIN_PER_LEARNER,
            "pass": min_depth >= READINESS_MIN_PER_LEARNER,
        },
        "calibration_rows_ge_200": {
            "observed": n_rows, "required": READINESS_CALIBRATION_ROWS,
            "pass": n_rows >= READINESS_CALIBRATION_ROWS,
        },
        "bias_le_0_05": {
            "observed": round(bias, 4) if bias is not None else None,
            "required": READINESS_MAX_BIAS,
            "pass": bias is not None and bias <= READINESS_MAX_BIAS,
            "note": (
                "bias proxy = |positive_rate - 0.5| (no model in this "
                "gate); true calibration bias needs a model and is "
                "unevaluable here."
            ),
        },
    }
    return {
        "criteria": criteria,
        "data_readiness": (
            "READY" if all(c["pass"] for c in criteria.values())
            else "NOT READY"
        ),
    }
