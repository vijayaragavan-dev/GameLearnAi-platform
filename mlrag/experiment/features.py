"""Point-in-time feature builder implementing GATE 3 §5/§7 (F1–F21 subset).

For target row at time T (its quiz ``submitted_at``):
  * history = rows of the same learner with ``submitted_at`` STRICTLY < T;
  * same-quiz siblings share T and are therefore excluded by construction;
  * state tables qualify only with stored timestamps strictly < T;
  * missing history stays None (cold-start path), never zero-filled as
    observed and never forward-filled.

Deterministic: input rows are sorted by (submitted_at, quiz_attempt_id,
question_attempt_id); ties broken identically on every run.
"""

from __future__ import annotations

from datetime import datetime
from typing import Any

FEATURE_COLUMNS = (
    "hist_accuracy",
    "recent_accuracy_k5",
    "topic_hist_accuracy",
    "prev_mastery_score",
    "days_since_last_attempt",
    "is_cold_start",
    "topic_has_exposure",
    "q_diff_medium",
    "q_diff_hard",
    "z_diff_medium",
    "z_diff_hard",
)


def _is_easy(value: Any) -> bool:
    return str(value or "").upper() == "EASY"


def _one_hot(diff: Any) -> tuple[int, int]:
    upper = str(diff or "").upper()
    return (1 if upper == "MEDIUM" else 0, 1 if upper == "HARD" else 0)


def build_rows(
    outcomes: list[dict],
    mastery: list[dict],
    recommendations: list[dict],
) -> list[dict]:
    """Build one feature row per outcome, chronologically, leak-free."""
    ordered = sorted(
        outcomes,
        key=lambda r: (
            r["submitted_at"],
            str(r["quiz_attempt_id"]),
            str(r["question_attempt_id"]),
        ),
    )
    by_learner: dict[str, list[dict]] = {}
    for row in ordered:
        by_learner.setdefault(row["learner_key"], []).append(row)

    mastery_by_lt: dict[tuple[str, str], list[dict]] = {}
    for row in mastery:
        if row.get("last_assessed_at") is None:
            continue
        mastery_by_lt.setdefault(
            (row["learner_key"], str(row["topic_id"])), []
        ).append(row)
    for rows in mastery_by_lt.values():
        rows.sort(key=lambda r: r["last_assessed_at"])

    recs_by_l: dict[str, list[dict]] = {}
    for row in recommendations:
        if row.get("generated_at") is None:
            continue
        recs_by_l.setdefault(row["learner_key"], []).append(row)
    for rows in recs_by_l.values():
        rows.sort(key=lambda r: r["generated_at"])

    built: list[dict] = []
    for learner_key, rows in by_learner.items():
        seen: list[dict] = []  # strictly-past rows of this learner
        for row in rows:
            target_time: datetime = row["submitted_at"]
            past = [r for r in seen if r["submitted_at"] < target_time]
            past_topic = [
                r for r in past if str(r["topic_id"]) == str(row["topic_id"])
            ]

            def rate(items: list[dict]) -> float | None:
                if not items:
                    return None
                return sum(1 for r in items if r["is_correct"]) / len(items)

            hist_accuracy = rate(past)
            recent = past[-5:]
            recent_accuracy = rate(recent)
            topic_accuracy = rate(past_topic)

            prior_state = [
                m
                for m in mastery_by_lt.get(
                    (learner_key, str(row["topic_id"])), []
                )
                if m["last_assessed_at"] < target_time
            ]
            current_mastery = prior_state[-1] if prior_state else None

            prior_recs = [
                r
                for r in recs_by_l.get(learner_key, [])
                if r["generated_at"] < target_time
            ]
            current_rec = prior_recs[-1] if prior_recs else None

            if past:
                last_time = max(r["submitted_at"] for r in past)
                gap_days = (target_time - last_time).total_seconds() / 86400.0
            else:
                gap_days = None

            q_med, q_hard = _one_hot(row.get("question_difficulty"))
            z_med, z_hard = _one_hot(
                row.get("quiz_difficulty", row.get("difficulty_at_attempt"))
            )

            built.append(
                {
                    "learner_key": learner_key,
                    "question_attempt_id": str(row["question_attempt_id"]),
                    "quiz_attempt_id": str(row["quiz_attempt_id"]),
                    "question_id": str(row["question_id"]),
                    "topic_id": str(row["topic_id"]),
                    "subject_id": str(row["subject_id"]),
                    "submitted_at": target_time.isoformat(),
                    "label": bool(row["is_correct"]),
                    "hist_attempts": len(past),
                    "hist_accuracy": hist_accuracy,
                    "recent_accuracy_k5": recent_accuracy,
                    "recent_n": len(recent),
                    "is_cold_start": 1 if not past else 0,
                    "topic_prior_attempts": len(past_topic),
                    "topic_hist_accuracy": topic_accuracy,
                    "topic_has_exposure": 1 if past_topic else 0,
                    "prev_mastery_score": (
                        float(current_mastery["mastery_score"])
                        if current_mastery is not None
                        and current_mastery.get("mastery_score") is not None
                        else None
                    ),
                    "prev_trend": (
                        current_mastery.get("trend")
                        if current_mastery is not None
                        else None
                    ),
                    "prior_rec_activity": (
                        current_rec.get("activity_type")
                        if current_rec is not None
                        else None
                    ),
                    "days_since_last_attempt": gap_days,
                    "q_diff_medium": q_med,
                    "q_diff_hard": q_hard,
                    "z_diff_medium": z_med,
                    "z_diff_hard": z_hard,
                }
            )
            seen.append(row)
    built.sort(
        key=lambda r: (r["submitted_at"], r["quiz_attempt_id"],
                       r["question_attempt_id"])
    )
    return built
