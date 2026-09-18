"""Strict prediction-time (``< T``) feature construction for f1 (GATE 17).

Prediction-time semantics
-------------------------
For every target question-attempt row occurring at time ``T`` (its quiz's
``submitted_at``), ONLY information strictly before ``T`` may be used:

* catalogue metadata known before T (question difficulty; the quiz's
  ``difficulty_at_attempt`` snapshot written at submission time);
* previous eligible attempts of the same learner with ``submitted_at < T``;
* the topic-mastery row for (learner, topic) ONLY when its stored
  ``last_assessed_at`` is strictly before T (see pre-image methodology);
* prior recommendation metadata (provenance counts only — recommendations
  are never features in f1);
* prior validated ``response_time_seconds`` values (most recent valid prior).

Forbidden (never read, never carried into X): current correctness, selected
answers, current score, post-submission mastery/recommendation rows,
XP/streaks, future attempts, same-submission siblings (they share T, hence
are excluded by the strict ``< T`` filter by construction),
``duration_seconds``, game skill claims, and any timestamp ``>= T``.

Mastery pre-image methodology
-----------------------------
``topic_mastery`` is updated IN PLACE: one row per (learner, topic) whose
``last_assessed_at`` always equals the latest quiz ``submitted_at`` on that
topic.  No historical snapshots exist, so:

* a stored row qualifies as a pre-image for target T IFF
  ``last_assessed_at`` is non-NULL and strictly ``< T``.  Such a row can only
  depend on attempts submitted at or before its ``last_assessed_at`` — all
  strictly before T — so its ``mastery_score / mastery_level /
  recent_accuracy / trend / current_difficulty`` are admissible as
  ``prev_*`` features;
* otherwise (post-image of the target's own quiz, i.e. ``last_assessed_at``
  equal to T, or a NULL timestamp) the pre-image is NOT defensible and all
  ``prev_*`` mastery fields are NULL (missing stays missing — never
  zero-filled, never forward-filled, never replayed);
* pre-image scale violations (score outside 0..100, recent/100 outside 0..1,
  unknown level/trend/difficulty tokens) REJECT the target row loudly
  instead of being coerced.

The immediate-predecessor state overwritten by the target's own submission
is therefore systematically NULL; this information loss is inherent to the
in-place schema and is reported as mastery-missing coverage, not patched.

Determinism
-----------
Eligible rows are sorted by ``(submitted_at, quiz_attempt_id,
question_attempt_id)``; ties share the same strict-prior set (same
``attempt_sequence_index``) and are ordered by the same stable identifiers
in the output.  Repeated builds over the same snapshot yield identical rows.
"""

from __future__ import annotations

import hashlib
from datetime import datetime, timezone
from typing import Any

from ..contracts.common import ContractViolation
from .contract import (
    ALLOWED_DIFFICULTY,
    ALLOWED_MASTERY_LEVEL,
    ALLOWED_TREND,
    FEATURE_VERSION,
    TARGET_COLUMN,
    validate_feature_row,
)

COMPLETED = "COMPLETED"
RECENT_K = 5


def _to_datetime(value: Any) -> datetime | None:
    if value is None:
        return None
    if isinstance(value, datetime):
        parsed = value
    elif isinstance(value, str) and value.strip():
        text = value.strip().replace("Z", "+00:00")
        try:
            parsed = datetime.fromisoformat(text)
        except ValueError:
            return None
    else:
        return None
    if parsed.tzinfo is not None:
        parsed = parsed.astimezone(timezone.utc).replace(tzinfo=None)
    return parsed


def _to_float(value: Any) -> float | None:
    if value is None:
        return None
    if isinstance(value, bool):
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _valid_response_time(value: Any) -> int | None:
    """A prior think-time value is usable iff it is a non-null int >= 0.

    Negative values are treated as missing (never written by the
    server-authoritative ThinkTimeService, which only persists ``0 <=
    elapsed <= cap``); they never reject a row.  Zero is a valid
    same-second submission.
    """
    if value is None or isinstance(value, bool):
        return None
    try:
        number = int(value)
    except (TypeError, ValueError):
        return None
    if isinstance(value, float) and not value.is_integer():
        return None
    return number if number >= 0 else None


def _rate(correct: int, total: int) -> float | None:
    if total <= 0:
        return None
    return correct / total


def compute_data_version(eligible: list[dict]) -> str:
    """Deterministic snapshot id from eligible rows only (no wall-clock)."""
    ids = sorted(str(r["question_attempt_id"]) for r in eligible)
    stamps = [r["_T"] for r in eligible]
    lo = min(stamps).isoformat() if stamps else "empty"
    hi = max(stamps).isoformat() if stamps else "empty"
    digest = hashlib.sha256("|".join(ids).encode("utf-8")).hexdigest()[:12]
    quizzes = len({str(r["quiz_attempt_id"]) for r in eligible})
    learners = len({str(r["learner_key"]) for r in eligible})
    return (
        f"snapshot-v1:qa{len(ids)}:qz{quizzes}:lr{learners}:{lo}:{hi}:sha{digest}"
    )


def _reject(
    rejections: list[dict], row: dict[str, Any], reason: str
) -> None:
    rejections.append(
        {
            "question_attempt_id": str(row.get("question_attempt_id")),
            "quiz_attempt_id": str(row.get("quiz_attempt_id")),
            "learner_key": str(row.get("learner_key")),
            "reason": reason,
        }
    )


def build_feature_table(
    tables: dict[str, list[dict]],
) -> dict[str, Any]:
    """Build f1 rows with strict ``< T`` semantics.

    Returns ``{"rows", "rejections", "data_version", "stats"}``.  Raises
    ContractViolation if a built row fails post-build validation (loud bug
    signal — never silently shipped).
    """
    outcomes = tables.get("outcomes", [])
    mastery = tables.get("mastery", [])
    recommendations = tables.get("recommendations", [])

    eligible: list[dict[str, Any]] = []
    rejections: list[dict] = []
    for raw in outcomes:
        row = dict(raw)
        status = row.get("attempt_status")
        moment = _to_datetime(row.get("submitted_at"))
        if status != COMPLETED:
            _reject(rejections, row, f"incomplete_attempt:{status}")
            continue
        if moment is None:
            _reject(rejections, row, "missing_submitted_at")
            continue
        question_diff = row.get("question_difficulty")
        if question_diff not in ALLOWED_DIFFICULTY:
            _reject(
                rejections, row,
                f"invalid_question_difficulty:{question_diff!r}",
            )
            continue
        quiz_diff = row.get("difficulty_at_attempt")
        if quiz_diff not in ALLOWED_DIFFICULTY:
            _reject(
                rejections, row, f"invalid_quiz_difficulty:{quiz_diff!r}"
            )
            continue
        row["_T"] = moment
        eligible.append(row)

    eligible.sort(
        key=lambda r: (
            r["_T"],
            str(r["quiz_attempt_id"]),
            str(r["question_attempt_id"]),
        )
    )

    data_version = compute_data_version(eligible)

    mastery_by_lt: dict[tuple[str, str], list[dict]] = {}
    for mrow in mastery:
        assessed = _to_datetime(mrow.get("last_assessed_at"))
        if assessed is None:
            continue
        key = (str(mrow["learner_key"]), str(mrow["topic_id"]))
        mastery_by_lt.setdefault(key, []).append({**mrow, "_A": assessed})
    for rows in mastery_by_lt.values():
        rows.sort(key=lambda r: r["_A"])

    recs_by_learner: dict[str, list[dict]] = {}
    for rrow in recommendations:
        generated = _to_datetime(rrow.get("generated_at"))
        if generated is None:
            continue
        recs_by_learner.setdefault(str(rrow["learner_key"]), []).append(
            {**rrow, "_G": generated}
        )
    for rows in recs_by_learner.values():
        rows.sort(key=lambda r: r["_G"])

    by_learner: dict[str, list[dict]] = {}
    for row in eligible:
        by_learner.setdefault(str(row["learner_key"]), []).append(row)

    rows: list[dict] = []
    for learner_key, items in by_learner.items():
        seen: list[dict] = []
        for row in items:
            target_time: datetime = row["_T"]
            # STRICT < T: same-submission siblings share T and are excluded
            # by construction; equal-T cross-quiz rows are excluded too.
            past = [r for r in seen if r["_T"] < target_time]
            past_topic = [
                r
                for r in past
                if str(r["topic_id"]) == str(row["topic_id"])
            ]

            prior_total = len(past)
            prior_correct = sum(1 for r in past if r["is_correct"])
            prior_quizzes = len({str(r["quiz_attempt_id"]) for r in past})
            topic_correct = sum(1 for r in past_topic if r["is_correct"])

            recent = past[-RECENT_K:]
            recent_correct = sum(1 for r in recent if r["is_correct"])

            pre_candidates = [
                m
                for m in mastery_by_lt.get(
                    (learner_key, str(row["topic_id"])), []
                )
                if m["_A"] < target_time
            ]
            pre_image = pre_candidates[-1] if pre_candidates else None

            prev_mastery_score: float | None = None
            prev_mastery_level: str | None = None
            prev_recent_accuracy: float | None = None
            prev_trend: str | None = None
            prev_difficulty: str | None = None
            pre_image_at: str | None = None
            if pre_image is not None:
                score = _to_float(pre_image.get("mastery_score"))
                if score is None or not 0.0 <= score <= 100.0:
                    _reject(
                        rejections, row,
                        f"invalid_mastery_preimage_score:{pre_image.get('mastery_score')!r}",
                    )
                    seen.append(row)
                    continue
                recent_raw = _to_float(pre_image.get("recent_accuracy"))
                recent_rate = (
                    recent_raw / 100.0 if recent_raw is not None else None
                )
                if recent_rate is None or not 0.0 <= recent_rate <= 1.0:
                    _reject(
                        rejections, row,
                        f"invalid_mastery_preimage_recent:{pre_image.get('recent_accuracy')!r}",
                    )
                    seen.append(row)
                    continue
                level = pre_image.get("mastery_level")
                trend = pre_image.get("trend")
                cur_diff = pre_image.get("current_difficulty")
                if level not in ALLOWED_MASTERY_LEVEL:
                    _reject(rejections, row, f"invalid_mastery_level:{level!r}")
                    seen.append(row)
                    continue
                if trend not in ALLOWED_TREND:
                    _reject(rejections, row, f"invalid_mastery_trend:{trend!r}")
                    seen.append(row)
                    continue
                if cur_diff not in ALLOWED_DIFFICULTY:
                    _reject(
                        rejections, row, f"invalid_mastery_difficulty:{cur_diff!r}"
                    )
                    seen.append(row)
                    continue
                prev_mastery_score = score
                prev_mastery_level = str(level)
                prev_recent_accuracy = recent_rate
                prev_trend = str(trend)
                prev_difficulty = str(cur_diff)
                pre_image_at = pre_image["_A"].isoformat()

            if past:
                last_time = max(r["_T"] for r in past)
                gap_days: float | None = (
                    target_time - last_time
                ).total_seconds() / 86400.0
            else:
                gap_days = None

            prior_rt: int | None = None
            for prior in reversed(past):
                candidate = _valid_response_time(
                    prior.get("response_time_seconds")
                )
                if candidate is not None:
                    prior_rt = candidate
                    break

            prior_recs = [
                r
                for r in recs_by_learner.get(learner_key, [])
                if r["_G"] < target_time
            ]

            features = {
                "hist_accuracy": _rate(prior_correct, prior_total),
                "recent_accuracy_k5": _rate(recent_correct, len(recent)),
                "prior_attempt_count": prior_quizzes,
                "prior_correct_count": prior_correct,
                "prior_total_count": prior_total,
                "topic_hist_accuracy": _rate(topic_correct, len(past_topic)),
                "prev_mastery_score": prev_mastery_score,
                "prev_mastery_level": prev_mastery_level,
                "prev_recent_accuracy": prev_recent_accuracy,
                "prev_trend": prev_trend,
                "prev_difficulty": prev_difficulty,
                "topic_has_exposure": len(past_topic) > 0,
                "question_difficulty": str(row["question_difficulty"]),
                "quiz_difficulty": str(row["difficulty_at_attempt"]),
                "days_since_last_attempt": gap_days,
                "attempt_sequence_index": prior_total,
                "is_cold_start": prior_total == 0,
                "prev_response_time_norm": prior_rt,
                "timing_known": prior_rt is not None,
            }

            target = 1 if row["is_correct"] else 0
            built = {
                "learner_key": learner_key,
                "topic_id": str(row["topic_id"]),
                "subject_id": str(row["subject_id"]),
                "question_id": str(row["question_id"]),
                "quiz_id": str(row["quiz_id"]),
                "quiz_attempt_id": str(row["quiz_attempt_id"]),
                "question_attempt_id": str(row["question_attempt_id"]),
                "feature_version": FEATURE_VERSION,
                "data_version": data_version,
                "predicted_at": target_time.isoformat(),
                "features": features,
                TARGET_COLUMN: target,
                "provenance": {
                    "prediction_time_source": "quiz_attempts.submitted_at",
                    "eligible_prior_rows": prior_total,
                    "eligible_prior_topic_rows": len(past_topic),
                    "eligible_prior_quizzes": prior_quizzes,
                    "mastery_preimage_found": pre_image is not None,
                    "mastery_preimage_last_assessed_at": pre_image_at,
                    "prior_recommendation_rows": len(prior_recs),
                    "quiz_catalogue_difficulty": (
                        str(row["quiz_catalogue_difficulty"])
                        if row.get("quiz_catalogue_difficulty") is not None
                        else None
                    ),
                    "quiz_difficulty_matches_catalogue": (
                        str(row.get("difficulty_at_attempt"))
                        == str(row.get("quiz_catalogue_difficulty"))
                    ),
                    # Quarantined post-attempt values: observed for audit,
                    # NEVER features (asserted by leakage tests).
                    "quarantined_post_attempt": {
                        "quiz_score": _to_float(row.get("quiz_score")),
                        "quiz_correct_count": row.get("quiz_correct_count"),
                        "quiz_total_questions": row.get(
                            "quiz_total_questions"
                        ),
                    },
                },
            }
            try:
                validate_feature_row(built)
            except ContractViolation as exc:
                raise ContractViolation(
                    f"post-build validation failed for "
                    f"{built['question_attempt_id']}: {exc}"
                ) from exc
            rows.append(built)
            seen.append(row)

    rows.sort(
        key=lambda r: (
            r["predicted_at"],
            r["quiz_attempt_id"],
            r["question_attempt_id"],
        )
    )

    stats = _summarize(rows, rejections)
    return {
        "rows": rows,
        "rejections": rejections,
        "data_version": data_version,
        "stats": stats,
    }


def _summarize(rows: list[dict], rejections: list[dict]) -> dict[str, Any]:
    reasons: dict[str, int] = {}
    for rej in rejections:
        reasons[rej["reason"].split(":")[0]] = (
            reasons.get(rej["reason"].split(":")[0], 0) + 1
        )
    targets = [r[TARGET_COLUMN] for r in rows]
    return {
        "eligible_rows": len(rows) + len(rejections),
        "transformed_rows": len(rows),
        "rejected_rows": len(rejections),
        "rejection_reasons": reasons,
        "cold_start_rows": sum(
            1 for r in rows if r["features"]["is_cold_start"]
        ),
        "timing_known_rows": sum(
            1 for r in rows if r["features"]["timing_known"]
        ),
        "timing_missing_rows": sum(
            1 for r in rows if not r["features"]["timing_known"]
        ),
        "mastery_preimage_rows": sum(
            1 for r in rows if r["provenance"]["mastery_preimage_found"]
        ),
        "mastery_missing_rows": sum(
            1 for r in rows if not r["provenance"]["mastery_preimage_found"]
        ),
        "target_ones": sum(1 for t in targets if t == 1),
        "target_zeros": sum(1 for t in targets if t == 0),
    }
