"""Gate 17: frozen f1 contract, validation, and extraction-audit tests."""

from __future__ import annotations

import unittest

from mlrag.contracts.common import ContractViolation
from mlrag.feature_pipeline import contract
from mlrag.feature_pipeline.contract import (
    FEATURE_COLUMNS,
    FEATURE_GROUPS,
    FEATURE_VERSION,
    TARGET_COLUMN,
    validate_feature_row,
    validate_feature_vector,
)
from mlrag.feature_pipeline.extract import (
    FORBIDDEN_COLUMNS,
    QUERIES,
    learner_key,
    validate_read_only,
)

from . import gate17_fixtures as fx


def valid_vector(**overrides):
    vector = {
        "hist_accuracy": 0.5,
        "recent_accuracy_k5": 0.6,
        "prior_attempt_count": 2,
        "prior_correct_count": 3,
        "prior_total_count": 6,
        "topic_hist_accuracy": 0.5,
        "prev_mastery_score": 80.0,
        "prev_mastery_level": "PROFICIENT",
        "prev_recent_accuracy": 0.75,
        "prev_trend": "STABLE",
        "prev_difficulty": "MEDIUM",
        "topic_has_exposure": True,
        "question_difficulty": "EASY",
        "quiz_difficulty": "MEDIUM",
        "days_since_last_attempt": 1.5,
        "attempt_sequence_index": 6,
        "is_cold_start": False,
        "prev_response_time_norm": 42,
        "timing_known": True,
    }
    vector.update(overrides)
    return vector


def valid_cold_vector():
    return valid_vector(
        hist_accuracy=None,
        recent_accuracy_k5=None,
        prior_attempt_count=0,
        prior_correct_count=0,
        prior_total_count=0,
        topic_hist_accuracy=None,
        prev_mastery_score=None,
        prev_mastery_level=None,
        prev_recent_accuracy=None,
        prev_trend=None,
        prev_difficulty=None,
        topic_has_exposure=False,
        days_since_last_attempt=None,
        attempt_sequence_index=0,
        is_cold_start=True,
        prev_response_time_norm=None,
        timing_known=False,
    )


class FrozenContractTest(unittest.TestCase):
    def test_feature_version_frozen(self):
        self.assertEqual(FEATURE_VERSION, "f1")

    def test_target_column(self):
        self.assertEqual(TARGET_COLUMN, "is_correct")

    def test_exact_frozen_feature_set(self):
        expected = (
            "hist_accuracy",
            "recent_accuracy_k5",
            "prior_attempt_count",
            "prior_correct_count",
            "prior_total_count",
            "topic_hist_accuracy",
            "prev_mastery_score",
            "prev_mastery_level",
            "prev_recent_accuracy",
            "prev_trend",
            "prev_difficulty",
            "topic_has_exposure",
            "question_difficulty",
            "quiz_difficulty",
            "days_since_last_attempt",
            "attempt_sequence_index",
            "is_cold_start",
            "prev_response_time_norm",
            "timing_known",
        )
        self.assertEqual(FEATURE_COLUMNS, expected)
        self.assertEqual(len(FEATURE_COLUMNS), 19)
        flat = tuple(n for g in FEATURE_GROUPS.values() for n in g)
        self.assertEqual(flat, expected)
        self.assertEqual(
            set(FEATURE_GROUPS.keys()),
            {"learner", "topic", "question", "temporal", "behavior"},
        )

    def test_target_not_a_feature(self):
        self.assertNotIn(TARGET_COLUMN, FEATURE_COLUMNS)

    def test_blocklist_covers_target_and_grouping_keys(self):
        for name in (
            "is_correct",
            "selected_answer",
            "score",
            "duration_seconds",
            "response_time_seconds",
            "mastery_score",
            "user_id",
            "learner_key",
            "xp_awarded",
            "best_combo",
            "completion_percentage",
        ):
            self.assertIn(name, contract.LEAKAGE_BLOCKLIST, name)


class ValidationTest(unittest.TestCase):
    def test_valid_vectors_pass(self):
        validate_feature_vector(valid_vector())
        validate_feature_vector(valid_cold_vector())

    def test_frozen_key_set_enforced(self):
        vector = valid_vector()
        del vector["hist_accuracy"]
        with self.assertRaises(ContractViolation):
            validate_feature_vector(vector)
        vector = valid_vector()
        vector["extra_feature"] = 1.0
        with self.assertRaises(ContractViolation):
            validate_feature_vector(vector)

    def test_rate_ranges(self):
        for name in (
            "hist_accuracy",
            "recent_accuracy_k5",
            "topic_hist_accuracy",
            "prev_recent_accuracy",
        ):
            with self.assertRaises(ContractViolation, msg=name):
                validate_feature_vector(valid_vector(**{name: 1.5}))
            with self.assertRaises(ContractViolation, msg=name):
                validate_feature_vector(valid_vector(**{name: -0.1}))

    def test_mastery_score_range(self):
        with self.assertRaises(ContractViolation):
            validate_feature_vector(valid_vector(prev_mastery_score=100.5))
        with self.assertRaises(ContractViolation):
            validate_feature_vector(valid_vector(prev_mastery_score=-1.0))

    def test_prior_counts_nonnegative_ints(self):
        for name in (
            "prior_attempt_count",
            "prior_correct_count",
            "prior_total_count",
        ):
            with self.assertRaises(ContractViolation, msg=name):
                validate_feature_vector(valid_vector(**{name: -1}))
            with self.assertRaises(ContractViolation, msg=name):
                validate_feature_vector(valid_vector(**{name: None}))

    def test_gap_and_sequence(self):
        with self.assertRaises(ContractViolation):
            validate_feature_vector(valid_vector(days_since_last_attempt=-2.0))
        with self.assertRaises(ContractViolation):
            validate_feature_vector(valid_vector(attempt_sequence_index=-1))

    def test_booleans_strict(self):
        with self.assertRaises(ContractViolation):
            validate_feature_vector(valid_vector(is_cold_start=0))
        with self.assertRaises(ContractViolation):
            validate_feature_vector(valid_vector(timing_known=1))

    def test_timing_consistency(self):
        with self.assertRaises(ContractViolation):
            validate_feature_vector(
                valid_vector(timing_known=False, prev_response_time_norm=5)
            )
        with self.assertRaises(ContractViolation):
            validate_feature_vector(
                valid_vector(timing_known=True, prev_response_time_norm=None)
            )
        with self.assertRaises(ContractViolation):
            validate_feature_vector(
                valid_vector(prev_response_time_norm=-3)
            )

    def test_difficulty_allowlist(self):
        with self.assertRaises(ContractViolation):
            validate_feature_vector(valid_vector(question_difficulty="easy"))
        with self.assertRaises(ContractViolation):
            validate_feature_vector(valid_vector(quiz_difficulty="EXTREME"))
        with self.assertRaises(ContractViolation):
            validate_feature_vector(valid_vector(quiz_difficulty=None))

    def test_mastery_token_allowlists(self):
        with self.assertRaises(ContractViolation):
            validate_feature_vector(valid_vector(prev_mastery_level="EXPERT"))
        with self.assertRaises(ContractViolation):
            validate_feature_vector(valid_vector(prev_trend="UP"))
        with self.assertRaises(ContractViolation):
            validate_feature_vector(valid_vector(prev_difficulty="HARD2"))

    def test_cold_start_consistency(self):
        with self.assertRaises(ContractViolation):
            validate_feature_vector(valid_cold_vector() | {"is_cold_start": False})
        with self.assertRaises(ContractViolation):
            validate_feature_vector(valid_cold_vector() | {"hist_accuracy": 0.0})
        with self.assertRaises(ContractViolation):
            validate_feature_vector(valid_vector(is_cold_start=True))
        with self.assertRaises(ContractViolation):
            validate_feature_vector(
                valid_vector(prior_total_count=4, hist_accuracy=None)
            )

    def test_row_validation(self):
        row = {
            "feature_version": "f1",
            "data_version": "snapshot-v1:test",
            "predicted_at": "2026-09-01T12:00:00",
            "features": valid_cold_vector(),
            "is_correct": 0,
        }
        validate_feature_row(row)
        with self.assertRaises(ContractViolation):
            validate_feature_row({**row, "feature_version": "f2"})
        with self.assertRaises(ContractViolation):
            validate_feature_row({**row, "is_correct": True})
        with self.assertRaises(ContractViolation):
            validate_feature_row({**row, "is_correct": 2})


class ExtractionAuditTest(unittest.TestCase):
    def test_all_queries_read_only(self):
        for sql in QUERIES:
            validate_read_only(sql)

    def test_forbidden_columns_absent_from_sql(self):
        for sql in QUERIES:
            lowered = sql.lower()
            for column in FORBIDDEN_COLUMNS:
                self.assertNotIn(column, lowered, f"{column} in SQL")

    def test_no_pii_columns_selected(self):
        for sql in QUERIES:
            lowered = sql.lower()
            for column in ("users", "email", "password", "game_results", "progress"):
                # 'users'/'progress' may not appear as tables at all.
                self.assertNotIn(column, lowered, f"{column} in SQL")

    def test_writes_rejected(self):
        with self.assertRaises(ContractViolation):
            validate_read_only("UPDATE topic_mastery SET mastery_score=1")
        with self.assertRaises(ContractViolation):
            validate_read_only("SELECT a; DELETE FROMADMIN a")
        with self.assertRaises(ContractViolation):
            validate_read_only(
                "SELECT email FROM users WHERE response_time_seconds > 1"
            )

    def test_learner_key_surrogate(self):
        first = learner_key("user-uuid-1")
        self.assertEqual(first, learner_key("user-uuid-1"))
        self.assertNotEqual(first, learner_key("user-uuid-2"))
        self.assertNotIn("user-uuid-1", first)
        self.assertTrue(first.startswith("learner_"))

    def test_cold_start_fixture_row_validates(self):
        # End-to-end shape guard: builder output for one cold row validates.
        from mlrag.feature_pipeline.builder import build_feature_table

        result = build_feature_table(
            fx.tables([fx.outcome("qa1", "qz1", at=fx.BASE, correct=True)])
        )
        self.assertEqual(len(result["rows"]), 1)
        validate_feature_row(result["rows"][0])


if __name__ == "__main__":
    unittest.main()
