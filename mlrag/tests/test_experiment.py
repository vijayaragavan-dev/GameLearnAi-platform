"""Experiment tests (GATE 4).  Standard library + numpy/sklearn only.

All learner-like rows below are hand-built SYNTHETIC fixtures for unit
testing (a few rows with obvious fake IDs) — never real learner data, never
a training dataset.  No database connection is opened by these tests.
Database safety is tested via query-guard inspection, never via live writes.

Run: python -m unittest mlrag.tests.test_experiment -v
"""

from __future__ import annotations

import os
import re
import unittest
from unittest import mock

from mlrag.contracts.common import ContractViolation
from mlrag.experiment import baselines, db, evaluate, extract, features, model

SYNTHETIC_TAG = "synthetic-unit-fixture"


def synth_qa(attempt_no: int, correct: bool, day: int,
             learner: str = "L1", topic: str = "T1",
             quiz: str | None = None) -> dict:
    """One SYNTHETIC outcome row shaped like an extracted record."""
    quiz_id = quiz or f"QZ-{learner}-{day}"
    stamp = f"2026-09-0{day}T10:00:00"
    return {
        "question_attempt_id": f"{SYNTHETIC_TAG}-qa-{attempt_no}",
        "quiz_attempt_id": quiz_id,
        "question_id": f"{SYNTHETIC_TAG}-q-{attempt_no}",
        "is_correct": correct,
        "learner_key": learner,
        "topic_id": topic,
        "subject_id": "S1",
        "question_difficulty": "EASY",
        "quiz_difficulty": "EASY",
        "difficulty_at_attempt": "EASY",
        "submitted_at": __import__("datetime").datetime.fromisoformat(stamp),
    }


def synth_mastery(learner: str, topic: str, day: int, score: float) -> dict:
    return {
        "learner_key": learner,
        "topic_id": topic,
        "mastery_score": score,
        "mastery_level": "DEVELOPING",
        "current_difficulty": "EASY",
        "attempt_count": 1,
        "recent_accuracy": score,
        "trend": "STABLE",
        "last_assessed_at": __import__("datetime").datetime.fromisoformat(
            f"2026-09-0{day}T09:00:00"),
    }


def synth_rec(learner: str, topic: str, day: int,
              activity: str = "PRACTICE") -> dict:
    return {
        "learner_key": learner,
        "topic_id": topic,
        "activity_type": activity,
        "recommended_difficulty": "EASY",
        "status": "ACTIVE",
        "generated_at": __import__("datetime").datetime.fromisoformat(
            f"2026-09-0{day}T08:00:00"),
    }


def history_fixture() -> list[dict]:
    # L1: day1 wrong, day2 right, day3 right (same topic); L2: one row.
    return [
        synth_qa(1, False, 1, "L1", "T1", quiz="Q1"),
        synth_qa(2, True, 2, "L1", "T1", quiz="Q2"),
        synth_qa(3, True, 3, "L1", "T1", quiz="Q3"),
        synth_qa(4, True, 1, "L2", "T9", quiz="Q9"),
    ]


class PointInTimeTest(unittest.TestCase):
    """Areas 1-6: point-in-time correctness, exclusions, ordering."""

    def test_target_excluded_from_own_features(self):
        rows = features.build_rows(history_fixture(), [], [])
        third = [r for r in rows if r["question_attempt_id"].endswith("-qa-3")][0]
        # Two strictly-past rows: 0/1 then 1/1 -> accuracy 0.5.
        self.assertEqual(third["hist_attempts"], 2)
        self.assertAlmostEqual(third["hist_accuracy"], 0.5)

    def test_future_rows_never_contribute(self):
        rows = features.build_rows(history_fixture(), [], [])
        first = [r for r in rows if r["question_attempt_id"].endswith("-qa-1")][0]
        self.assertEqual(first["hist_attempts"], 0)
        self.assertIsNone(first["hist_accuracy"])
        self.assertEqual(first["is_cold_start"], 1)

    def test_same_quiz_siblings_excluded(self):
        same_quiz = [
            synth_qa(1, True, 2, "L1", "T1", quiz="QSAME"),
            synth_qa(2, False, 2, "L1", "T1", quiz="QSAME"),
        ]
        rows = features.build_rows(same_quiz, [], [])
        for row in rows:
            # Siblings share submitted_at -> strictly-past set is empty.
            self.assertEqual(row["hist_attempts"], 0)

    def test_chronological_ordering_deterministic(self):
        first = features.build_rows(history_fixture(), [], [])
        shuffled = history_fixture()[::-1]
        second = features.build_rows(shuffled, [], [])
        self.assertEqual(first, second)

    def test_learner_topic_history(self):
        rows = features.build_rows(history_fixture(), [], [])
        third = [r for r in rows if r["question_attempt_id"].endswith("-qa-3")][0]
        self.assertEqual(third["topic_prior_attempts"], 2)
        self.assertAlmostEqual(third["topic_hist_accuracy"], 0.5)
        self.assertEqual(third["topic_has_exposure"], 1)
        other = [r for r in rows if r["question_attempt_id"].endswith("-qa-4")][0]
        self.assertEqual(other["topic_has_exposure"], 0)

    def test_pre_image_state_only(self):
        mastery = [synth_mastery("L1", "T1", 1, 40.0),
                   synth_mastery("L1", "T1", 5, 99.0)]  # day5 = future
        rows = features.build_rows(history_fixture(), mastery, [])
        third = [r for r in rows if r["question_attempt_id"].endswith("-qa-3")][0]
        self.assertAlmostEqual(third["prev_mastery_score"], 40.0)

    def test_pre_image_recommendation_only(self):
        recs = [synth_rec("L1", "T1", 1),
                synth_rec("L1", "T1", 5, activity="ADVANCE")]
        rows = features.build_rows(history_fixture(), [], recs)
        by_qa = {r["question_attempt_id"][-4:]: r for r in rows}
        # Day-1 08:00 rec is legitimately visible from the day-1 10:00
        # attempt onward; the day-5 rec must never surface (all stay
        # PRACTICE, never ADVANCE).
        for suffix in ("qa-1", "qa-2", "qa-3"):
            self.assertEqual(by_qa[suffix]["prior_rec_activity"], "PRACTICE")
        other = [r for r in rows if r["question_attempt_id"].endswith("-qa-4")][0]
        self.assertIsNone(other["prior_rec_activity"])


class ColdSparseTest(unittest.TestCase):
    """Areas 7-8: cold-start and sparse-history behavior."""

    def test_cold_start_row(self):
        rows = features.build_rows([synth_qa(1, True, 1)], [], [])
        self.assertEqual(rows[0]["is_cold_start"], 1)
        self.assertFalse(model.served_by_model(rows[0]))

    def test_sparse_row_not_served(self):
        rows = features.build_rows(history_fixture(), [], [])
        second = [r for r in rows if r["question_attempt_id"].endswith("-qa-2")][0]
        self.assertEqual(second["hist_attempts"], 1)
        self.assertFalse(model.served_by_model(second))

    def test_sufficient_row_served(self):
        many = [synth_qa(i, True, 1 + (i // 2), quiz=f"Q{i}")
                for i in range(1, 6)]
        rows = features.build_rows(many, [], [])
        self.assertTrue(model.served_by_model(rows[-1]))


class BaselineTest(unittest.TestCase):
    """Areas 9-11: baselines A/B/C with fallbacks."""

    def test_baseline_a_global_rate(self):
        rows = features.build_rows(history_fixture(), [], [])
        self.assertAlmostEqual(baselines.fit_global_rate(rows), 0.75)

    def test_baseline_b_personal_then_fallback(self):
        rows = features.build_rows(history_fixture(), [], [])
        rate = baselines.fit_global_rate(rows)
        third = [r for r in rows if r["question_attempt_id"].endswith("-qa-3")][0]
        self.assertAlmostEqual(
            baselines.predict_b(rows, third, rate), 0.5)
        cold = [r for r in rows if r["question_attempt_id"].endswith("-qa-1")][0]
        self.assertAlmostEqual(baselines.predict_b(rows, cold, rate), rate)

    def test_baseline_c_topic_chain(self):
        rows = features.build_rows(history_fixture(), [], [])
        rate = baselines.fit_global_rate(rows)
        third = [r for r in rows if r["question_attempt_id"].endswith("-qa-3")][0]
        self.assertAlmostEqual(
            baselines.predict_c(rows, third, rate,
                                min_topic_history=2), 0.5)
        # Below min history -> falls back to learner rate (0.0 for L2's peer).
        other = [r for r in rows if r["question_attempt_id"].endswith("-qa-4")][0]
        self.assertAlmostEqual(
            baselines.predict_c(rows, other, rate, min_topic_history=2),
            rate)


class ModelValidityTest(unittest.TestCase):
    """Areas 12-14: logistic regression output validity + determinism."""

    def _train_rows(self) -> list[dict]:
        data = []
        for i in range(1, 13):
            data.append(synth_qa(i, i % 2 == 0, 1 + (i % 3), quiz=f"QT{i}"))
        return features.build_rows(data, [], [])

    def test_output_probability_bounds(self):
        rows = self._train_rows()
        bundle = model.fit(rows)
        for prob in model.predict_proba(bundle, rows):
            self.assertGreaterEqual(prob, 0.0)
            self.assertLessEqual(prob, 1.0)

    def test_deterministic_repeated_execution(self):
        rows = self._train_rows()
        first = model.predict_proba(model.fit(rows), rows)
        second = model.predict_proba(model.fit(rows), rows)
        self.assertEqual(first, second)

    def test_model_metadata(self):
        self.assertTrue(model.MODEL_ID.startswith("logreg-"))
        self.assertEqual(model.FEATURE_SCHEMA_VERSION, "f1")


class LeakagePreventionTest(unittest.TestCase):
    """Area 15: feature frame contains no blocked names."""

    def test_feature_columns_leak_free(self):
        from mlrag.contracts.leakage import validate_feature_names
        # Non-strict: the meaningful gate is "no blocked names".  Strict
        # allowlist conformance belongs to the contract dataclass and is
        # covered by the contract suite.
        validate_feature_names(features.FEATURE_COLUMNS)

    def test_built_rows_have_no_label_leak_columns(self):
        rows = features.build_rows(history_fixture(), [], [])
        forbidden = {"is_correct", "selected_answer", "score",
                     "response_time_seconds", "duration_seconds"}
        for row in rows:
            self.assertTrue(forbidden.isdisjoint(row.keys()))


class ReadOnlyGuardTest(unittest.TestCase):
    """Area 16: read-only SQL enforcement without touching a database."""

    def test_all_extraction_queries_select_only(self):
        for query in extract.QUERIES:
            cleaned = query.strip().rstrip(";").strip().upper()
            self.assertTrue(cleaned.startswith("SELECT"), query[:60])
            self.assertNotIn(";", cleaned)
            # Word boundaries: created_at must not match CREATE, etc.
            for keyword in ("INSERT", "UPDATE", "DELETE", "ALTER", "DROP",
                            "TRUNCATE", "CREATE", "REPLACE", "MERGE",
                            "INTO OUTFILE", "INTO DUMPFILE"):
                self.assertIsNone(
                    re.search(r"\b" + keyword + r"\b", cleaned),
                    f"{keyword} in query",
                )

    def test_guard_rejects_write_statements(self):
        for bad in ("UPDATE users SET x=1", "DELETE FROM users",
                    "INSERT INTO t VALUES (1)", "SELECT 1; DROP TABLE users",
                    "CALL proc()", "SELECT * FROM t INTO OUTFILE '/tmp/x'"):
            with self.assertRaises(ContractViolation, msg=bad):
                db.run_select(object(), bad)

    def test_missing_config_rejected_without_connecting(self):
        with mock.patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(ContractViolation):
                db.connect()


class PrivacyTest(unittest.TestCase):
    """Area 17: no PII in extraction SQL or outputs."""

    def test_extraction_selects_no_pii_columns(self):
        blob = "\n".join(extract.QUERIES).lower()
        for column in ("email", "password", "display_name", "username",
                       "first_name", "last_name", "phone"):
            self.assertNotIn(column, blob)

    def test_learner_keys_are_hashed_surrogates(self):
        key_a = extract.learner_key("user-id-1")
        key_b = extract.learner_key("user-id-2")
        self.assertTrue(key_a.startswith("learner_"))
        self.assertNotIn("user-id-1", key_a)
        self.assertNotEqual(key_a, key_b)
        self.assertEqual(key_a, extract.learner_key("user-id-1"))

    def test_built_rows_carry_no_raw_identity(self):
        rows = features.build_rows(history_fixture(), [], [])
        blob = str(rows).lower()
        self.assertNotIn("user_id", blob)
        self.assertNotIn("@", blob)


class FailureFallbackTest(unittest.TestCase):
    """Areas 18-19: invalid config + model failure fallback."""

    def test_empty_training_set_rejected(self):
        with self.assertRaises(ValueError):
            model.fit([])

    def test_fallback_value_is_deterministic(self):
        rows = features.build_rows(history_fixture(), [], [])
        rate = baselines.fit_global_rate(rows)
        cold = [r for r in rows if r["question_attempt_id"].endswith("-qa-1")][0]
        self.assertEqual(baselines.predict_b(rows, cold, rate), rate)


class MetricValidityTest(unittest.TestCase):
    """Area 20: single-class folds report AUC as unavailable."""

    def test_single_class_fold_auc_undefined(self):
        y_true = [1, 1, 1]
        scored = evaluate.score_set(y_true, [0.7, 0.8, 0.6])
        self.assertIsNone(scored["roc_auc"])
        self.assertIsNone(scored["pr_auc"])
        self.assertIn("log_loss", scored)
        self.assertIn("brier", scored)


if __name__ == "__main__":
    unittest.main()
