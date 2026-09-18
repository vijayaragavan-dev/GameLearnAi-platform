"""Read-only corpus extraction over content tables (GATE 6, PHASE 11).

SELECT-only statements with explicit columns executed through the guarded
``experiment.db.run_select`` (statement validation, read-only account).
Content tables carry no PII (curricular text only).  Used for offline
corpus counts and future deterministic ingestion input — never for
learner data, never for writes.
"""

from __future__ import annotations

from typing import Any

LESSONS_SQL = """
SELECT l.id, l.topic_id, t.subject_id, t.unit_id, l.title, l.content,
       l.summary, l.difficulty, l.source_type, l.is_active, l.updated_at
  FROM lessons l
  JOIN topics t ON t.id = l.topic_id
 ORDER BY l.id
"""

QUESTIONS_SQL = """
SELECT q.id, q.topic_id, t.subject_id, t.unit_id, q.question_text,
       q.options_json AS options, q.explanation, q.difficulty,
       q.source_type, q.is_active, q.updated_at
  FROM questions q
  JOIN topics t ON t.id = q.topic_id
 ORDER BY q.id
"""

TOPICS_SQL = """
SELECT t.id, t.subject_id, t.unit_id, t.name, t.description,
       t.difficulty, t.is_active, t.updated_at
  FROM topics t
 ORDER BY t.id
"""

SUBJECTS_SQL = """
SELECT s.id, s.name, s.description, s.is_active
  FROM subjects s
 ORDER BY s.display_order, s.id
"""

UNITS_SQL = """
SELECT u.id, u.subject_id, u.name, u.description, u.is_active
  FROM units u
 ORDER BY u.subject_id, u.display_order, u.id
"""

#: All corpus extraction statements (audited for SELECT-only).
CORPUS_QUERIES = (
    LESSONS_SQL,
    QUESTIONS_SQL,
    TOPICS_SQL,
    SUBJECTS_SQL,
    UNITS_SQL,
)

COUNT_QUERIES = {
    "subjects": "SELECT COUNT(*) AS n FROM subjects",
    "subjects_active": "SELECT COUNT(*) AS n FROM subjects WHERE is_active = 1",
    "units": "SELECT COUNT(*) AS n FROM units",
    "topics": "SELECT COUNT(*) AS n FROM topics",
    "topics_active": "SELECT COUNT(*) AS n FROM topics WHERE is_active = 1",
    "lessons": "SELECT COUNT(*) AS n FROM lessons",
    "lessons_active": "SELECT COUNT(*) AS n FROM lessons WHERE is_active = 1",
    "questions": "SELECT COUNT(*) AS n FROM questions",
    "questions_active": "SELECT COUNT(*) AS n FROM questions WHERE is_active = 1",
    "questions_with_explanation":
        "SELECT COUNT(*) AS n FROM questions "
        "WHERE explanation IS NOT NULL AND explanation <> ''",
}


def fetch_corpus(conn: Any) -> dict[str, list[dict]]:
    """Fetch content rows for offline ingestion input (read-only)."""
    from mlrag.experiment import db

    return {
        "lessons": db.run_select(conn, LESSONS_SQL),
        "questions": db.run_select(conn, QUESTIONS_SQL),
        "topics": db.run_select(conn, TOPICS_SQL),
        "subjects": db.run_select(conn, SUBJECTS_SQL),
        "units": db.run_select(conn, UNITS_SQL),
    }


def count_corpus(conn: Any) -> dict[str, int]:
    """Aggregate content counts only (no text, no PII — none exists here)."""
    from mlrag.experiment import db

    return {name: int(db.run_select(conn, sql)[0]["n"])
            for name, sql in COUNT_QUERIES.items()}
