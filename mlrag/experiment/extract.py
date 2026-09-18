"""Read-only dataset extraction (GATE 4).

Every query is SELECT-only with explicit columns.  No email, password,
name, or profile column is ever selected.  Learner identity is the raw
``quiz_attempts.user_id`` here and is hashed to a surrogate
``learner_key`` (SHA-256, domain-separated, truncated) before leaving
this module — raw user IDs never reach features, artifacts, or logs.
"""

from __future__ import annotations

import hashlib
from typing import Any

from . import db

_HASH_DOMAIN = "gamelearn-mlrag-learner-v1"


def learner_key(user_id: Any) -> str:
    """Deterministic, non-reversible surrogate for grouping/splitting."""
    digest = hashlib.sha256(f"{_HASH_DOMAIN}:{user_id}".encode("utf-8")).hexdigest()
    return f"learner_{digest[:16]}"


QUESTION_OUTCOMES_SQL = """
SELECT qa.id AS question_attempt_id,
       qa.quiz_attempt_id,
       qa.question_id,
       qa.is_correct,
       qa.created_at AS qa_created_at,
       a.user_id,
       a.quiz_id,
       a.score AS quiz_score,
       a.correct_count AS quiz_correct,
       a.total_questions AS quiz_total,
       a.difficulty_at_attempt,
       a.submitted_at,
       a.status AS attempt_status,
       q.topic_id,
       q.difficulty AS question_difficulty,
       t.subject_id,
       qz.difficulty AS quiz_difficulty
  FROM question_attempts qa
  JOIN quiz_attempts a ON a.id = qa.quiz_attempt_id
  JOIN questions q ON q.id = qa.question_id
  JOIN topics t ON t.id = q.topic_id
  JOIN quizzes qz ON qz.id = a.quiz_id
 ORDER BY a.submitted_at, a.id, qa.id
"""

MASTERY_SNAPSHOT_SQL = """
SELECT user_id, topic_id, mastery_score, mastery_level,
       current_difficulty, attempt_count, recent_accuracy, trend,
       last_assessed_at
  FROM topic_mastery
"""

RECOMMENDATION_SNAPSHOT_SQL = """
SELECT user_id, topic_id, activity_type, recommended_difficulty,
       status, generated_at
  FROM recommendations
"""

#: All production extraction statements (audited by tests for SELECT-only).
QUERIES = (
    QUESTION_OUTCOMES_SQL,
    MASTERY_SNAPSHOT_SQL,
    RECOMMENDATION_SNAPSHOT_SQL,
)


def extract(conn: Any) -> dict[str, list[dict]]:
    """Run the extraction; attach surrogate learner keys; return table rows."""
    outcomes = db.run_select(conn, QUESTION_OUTCOMES_SQL)
    mastery = db.run_select(conn, MASTERY_SNAPSHOT_SQL)
    recommendations = db.run_select(conn, RECOMMENDATION_SNAPSHOT_SQL)
    for row in outcomes:
        row["learner_key"] = learner_key(row.pop("user_id"))
    for table in (mastery, recommendations):
        for row in table:
            row["learner_key"] = learner_key(row.pop("user_id"))
    return {
        "outcomes": outcomes,
        "mastery": mastery,
        "recommendations": recommendations,
    }
