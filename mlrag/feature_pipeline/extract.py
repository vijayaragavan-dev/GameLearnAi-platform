"""Read-only extraction for the Gate 17 feature pipeline.

Safety properties (enforced, not conventional):

* Every statement is validated SELECT-only, single-statement, with dangerous
  keywords rejected — mirroring ``mlrag.experiment.db`` but decoupled so this
  pipeline never depends on the experiment module's read-only account check.
  (The live snapshot reuses the project's existing database configuration
  without duplicating secrets; the pipeline itself only ever issues SELECT.)
* Explicit column lists.  ``users`` (email / password_hash / display_name),
  ``game_results`` skill columns, ``progress``, XP, and streaks are NEVER
  selected — they cannot leak because they never enter the process.
* ``question_attempts.selected_answer`` is NEVER selected.
* ``quiz_attempts.duration_seconds`` is NEVER selected (degenerate server
  delta, forbidden as think time).
* Raw ``user_id`` values are hashed to surrogate ``learner_key`` values
  (SHA-256, domain-separated, truncated) at the boundary; raw IDs never
  reach features, artifacts, or logs.
* No secret is ever logged.  Connections are supplied by the caller.
"""

from __future__ import annotations

import hashlib
import re
from typing import Any, Sequence

from ..contracts.common import ContractViolation

_HASH_DOMAIN = "gamelearn-mlrag-learner-v1"

_READ_PREFIXES = ("SELECT", "SHOW", "DESCRIBE", "DESC", "EXPLAIN")
_FORBIDDEN_KEYWORDS = (
    "INSERT",
    "UPDATE",
    "DELETE",
    "ALTER",
    "DROP",
    "TRUNCATE",
    "CREATE",
    "REPLACE",
    "MERGE",
    "CALL ",
    "LOAD DATA",
    "GRANT",
    "REVOKE",
    "INTO OUTFILE",
    "INTO DUMPFILE",
    "HANDLER",
    "LOCK TABLES",
)

#: Columns that must never be selected by this pipeline.  Audited by tests:
#: every extraction statement is scanned for these as whole words.
FORBIDDEN_COLUMNS = frozenset(
    {
        "email",
        "password_hash",
        "display_name",
        "selected_answer",
        "duration_seconds",
        "best_combo",
        "xp_awarded",
        "game_score",
    }
)


def learner_key(user_id: Any) -> str:
    """Deterministic, non-reversible surrogate for grouping/splitting."""
    digest = hashlib.sha256(
        f"{_HASH_DOMAIN}:{user_id}".encode("utf-8")
    ).hexdigest()
    return f"learner_{digest[:16]}"


#: One row per question attempt joined to its quiz, question, topic,
#: subject, and quiz catalogue rows.  ``difficulty_at_attempt`` is the
#: authoritative at-T quiz difficulty snapshot (it equals the catalogue
#: value at submission time); ``quizzes.difficulty`` is carried only as
#: provenance to detect later catalogue changes.
QUESTION_OUTCOMES_SQL = """
SELECT qa.id AS question_attempt_id,
       qa.quiz_attempt_id,
       qa.question_id,
       qa.is_correct,
       qa.response_time_seconds,
       qa.created_at AS qa_created_at,
       a.user_id,
       a.quiz_id,
       a.score AS quiz_score,
       a.correct_count AS quiz_correct_count,
       a.total_questions AS quiz_total_questions,
       a.difficulty_at_attempt,
       a.submitted_at,
       a.status AS attempt_status,
       q.topic_id,
       q.difficulty AS question_difficulty,
       t.subject_id,
       qz.difficulty AS quiz_catalogue_difficulty
  FROM question_attempts qa
  JOIN quiz_attempts a ON a.id = qa.quiz_attempt_id
  JOIN questions q ON q.id = qa.question_id
  JOIN topics t ON t.id = q.topic_id
  JOIN quizzes qz ON qz.id = a.quiz_id
 ORDER BY a.submitted_at, a.id, qa.id
"""

#: Current (post-image) mastery rows.  The builder admits a row as a
#: pre-image feature ONLY when ``last_assessed_at`` is strictly before T.
MASTERY_SNAPSHOT_SQL = """
SELECT user_id, topic_id, mastery_score, mastery_level,
       current_difficulty, attempt_count, recent_accuracy, trend,
       last_assessed_at
  FROM topic_mastery
"""

#: Recommendation metadata for provenance only (counts of prior rows).
#: Never a feature input.
RECOMMENDATION_SNAPSHOT_SQL = """
SELECT user_id, topic_id, activity_type, recommended_difficulty,
       status, generated_at
  FROM recommendations
"""

#: All production extraction statements (audited by tests for SELECT-only
#: and forbidden-column absence).
QUERIES = (
    QUESTION_OUTCOMES_SQL,
    MASTERY_SNAPSHOT_SQL,
    RECOMMENDATION_SNAPSHOT_SQL,
)


def validate_read_only(sql: str) -> str:
    """Validate one statement is read-only; return the stripped statement."""
    statement = sql.strip().rstrip(";").strip()
    upper = statement.upper()
    if not upper.startswith(_READ_PREFIXES):
        raise ContractViolation("only read-only statements are allowed")
    if ";" in statement:
        raise ContractViolation("multi-statements are forbidden")
    for keyword in _FORBIDDEN_KEYWORDS:
        if re.search(r"\b" + keyword.strip() + r"\b", upper):
            raise ContractViolation(
                f"forbidden keyword in read-only query: {keyword.strip()}"
            )
    for column in FORBIDDEN_COLUMNS:
        if re.search(r"\b" + re.escape(column) + r"\b", statement, re.IGNORECASE):
            raise ContractViolation(
                f"forbidden column in extraction query: {column}"
            )
    return statement


def run_select(conn: Any, sql: str, params: Sequence[Any] | None = None) -> list[dict]:
    """Execute one validated read-only statement; return all rows."""
    statement = validate_read_only(sql)
    with conn.cursor() as cur:
        cur.execute(statement, params or ())
        return list(cur.fetchall())


def extract(conn: Any) -> dict[str, list[dict]]:
    """Run the extraction; attach surrogate learner keys; return tables.

    Raw ``user_id`` values are replaced by ``learner_key`` before return.
    """
    outcomes = run_select(conn, QUESTION_OUTCOMES_SQL)
    mastery = run_select(conn, MASTERY_SNAPSHOT_SQL)
    recommendations = run_select(conn, RECOMMENDATION_SNAPSHOT_SQL)
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
