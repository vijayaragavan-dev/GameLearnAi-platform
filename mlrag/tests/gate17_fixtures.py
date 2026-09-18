"""Shared synthetic fixtures for Gate 17 pipeline tests (no database)."""

from __future__ import annotations

from datetime import datetime, timedelta

BASE = datetime(2026, 9, 1, 12, 0, 0)


def outcome(
    qaid: str,
    qzaid: str,
    learner: str = "learner_A",
    topic: str = "topic_T1",
    question: str = "question_Q",
    quiz: str = "quiz_Z",
    subject: str = "subject_S",
    at: datetime | None = None,
    correct: bool = True,
    response_time: int | None = None,
    question_diff: str = "EASY",
    quiz_diff: str = "MEDIUM",
    catalogue_diff: str = "MEDIUM",
    status: str = "COMPLETED",
    **extra,
):
    row = {
        "question_attempt_id": qaid,
        "quiz_attempt_id": qzaid,
        "question_id": question,
        "is_correct": correct,
        "response_time_seconds": response_time,
        "qa_created_at": at or BASE,
        "learner_key": learner,
        "quiz_id": quiz,
        "quiz_score": 75.0,
        "quiz_correct_count": 3,
        "quiz_total_questions": 4,
        "difficulty_at_attempt": quiz_diff,
        "submitted_at": at or BASE,
        "attempt_status": status,
        "topic_id": topic,
        "question_difficulty": question_diff,
        "subject_id": subject,
        "quiz_catalogue_difficulty": catalogue_diff,
    }
    row.update(extra)
    return row


def mastery(
    learner: str = "learner_A",
    topic: str = "topic_T1",
    at: datetime | None = None,
    score: float = 80.0,
    level: str = "PROFICIENT",
    difficulty: str = "MEDIUM",
    recent: float = 75.0,
    trend: str = "STABLE",
):
    return {
        "learner_key": learner,
        "topic_id": topic,
        "mastery_score": score,
        "mastery_level": level,
        "current_difficulty": difficulty,
        "attempt_count": 3,
        "recent_accuracy": recent,
        "trend": trend,
        "last_assessed_at": at or BASE,
    }


def recommendation(
    learner: str = "learner_A",
    topic: str = "topic_T1",
    at: datetime | None = None,
):
    return {
        "learner_key": learner,
        "topic_id": topic,
        "activity_type": "PRACTICE",
        "recommended_difficulty": "MEDIUM",
        "status": "ACTIVE",
        "generated_at": at or BASE,
    }


def tables(
    outcomes: list[dict],
    mastery_rows: list[dict] | None = None,
    recs: list[dict] | None = None,
):
    return {
        "outcomes": outcomes,
        "mastery": mastery_rows or [],
        "recommendations": recs or [],
    }


def at_days(n: float) -> datetime:
    return BASE + timedelta(days=n)
