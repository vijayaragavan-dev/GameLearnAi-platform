"""Gate 17: point-in-time builder semantics, validation, and determinism."""

from __future__ import annotations

import unittest
from datetime import timedelta

from mlrag.contracts.common import ContractViolation
from mlrag.feature_pipeline.builder import build_feature_table
from mlrag.feature_pipeline.contract import FEATURE_VERSION

from . import gate17_fixtures as fx


class ColdStartTest(unittest.TestCase):
    def test_first_attempt_all_history_null(self):
        result = build_feature_table(
            fx.tables([fx.outcome("qa1", "qz1", at=fx.BASE, correct=True)])
        )
        self.assertEqual(len(result["rows"]), 1)
        row = result["rows"][0]
        feats = row["features"]
        self.assertIsNone(feats["hist_accuracy"])
        self.assertIsNone(feats["recent_accuracy_k5"])
        self.assertEqual(feats["prior_attempt_count"], 0)
        self.assertEqual(feats["prior_correct_count"], 0)
        self.assertEqual(feats["prior_total_count"], 0)
        self.assertIsNone(feats["topic_hist_accuracy"])
        self.assertIsNone(feats["prev_mastery_score"])
        self.assertIsNone(feats["prev_mastery_level"])
        self.assertIsNone(feats["prev_recent_accuracy"])
        self.assertIsNone(feats["prev_trend"])
        self.assertIsNone(feats["prev_difficulty"])
        self.assertFalse(feats["topic_has_exposure"])
        self.assertIsNone(feats["days_since_last_attempt"])
        self.assertEqual(feats["attempt_sequence_index"], 0)
        self.assertTrue(feats["is_cold_start"])
        self.assertIsNone(feats["prev_response_time_norm"])
        self.assertFalse(feats["timing_known"])
        self.assertEqual(row["is_correct"], 1)
        self.assertEqual(row["feature_version"], FEATURE_VERSION)
        self.assertTrue(row["data_version"])
        self.assertFalse(row["provenance"]["mastery_preimage_found"])

    def test_target_zero_mapping(self):
        result = build_feature_table(
            fx.tables([fx.outcome("qa1", "qz1", at=fx.BASE, correct=False)])
        )
        self.assertEqual(result["rows"][0]["is_correct"], 0)


class HistoryAggregationTest(unittest.TestCase):
    def _three_row_tables(self):
        outcomes = [
            fx.outcome("qa1", "qz1", at=fx.at_days(0), correct=True),
            fx.outcome("qa2", "qz1", at=fx.at_days(0), correct=False),
            fx.outcome("qa3", "qz2", at=fx.at_days(2), correct=True),
        ]
        return fx.tables(outcomes)

    def test_current_row_excluded_from_aggregates(self):
        result = build_feature_table(self._three_row_tables())
        by_id = {r["question_attempt_id"]: r for r in result["rows"]}
        # qa1: no priors.
        self.assertTrue(by_id["qa1"]["features"]["is_cold_start"])
        # qa2 shares T with qa1 -> sibling excluded -> still cold.
        self.assertTrue(by_id["qa2"]["features"]["is_cold_start"])
        self.assertEqual(by_id["qa2"]["features"]["prior_total_count"], 0)
        # qa3 sees qa1+qa2 only (not itself).
        feats = by_id["qa3"]["features"]
        self.assertEqual(feats["prior_total_count"], 2)
        self.assertEqual(feats["prior_correct_count"], 1)
        self.assertAlmostEqual(feats["hist_accuracy"], 0.5)
        self.assertAlmostEqual(feats["recent_accuracy_k5"], 0.5)
        self.assertEqual(feats["prior_attempt_count"], 1)  # one prior quiz
        self.assertEqual(feats["attempt_sequence_index"], 2)
        self.assertFalse(feats["is_cold_start"])
        self.assertAlmostEqual(feats["days_since_last_attempt"], 2.0)

    def test_recent_k5_window(self):
        outcomes = [
            fx.outcome(f"qa{i}", f"qz{i}", at=fx.at_days(i),
                       correct=(i % 2 == 0))
            for i in range(8)
        ]
        result = build_feature_table(fx.tables(outcomes))
        last = [r for r in result["rows"]
                if r["question_attempt_id"] == "qa7"][0]
        feats = last["features"]
        # Priors qa0..qa6: 4 correct of 7.
        self.assertAlmostEqual(feats["hist_accuracy"], 4 / 7)
        # Last five priors qa2..qa6: correct, False, True, False, True = 3/5.
        self.assertAlmostEqual(feats["recent_accuracy_k5"], 3 / 5)
        self.assertEqual(feats["prior_total_count"], 7)
        self.assertEqual(feats["attempt_sequence_index"], 7)

    def test_topic_filtering(self):
        outcomes = [
            fx.outcome("qa1", "qz1", at=fx.at_days(0), correct=True,
                       topic="topic_T1"),
            fx.outcome("qa2", "qz1", at=fx.at_days(1), correct=False,
                       topic="topic_T2"),
            fx.outcome("qa3", "qz2", at=fx.at_days(2), correct=False,
                       topic="topic_T1"),
        ]
        result = build_feature_table(fx.tables(outcomes))
        by_id = {r["question_attempt_id"]: r for r in result["rows"]}
        self.assertAlmostEqual(
            by_id["qa3"]["features"]["topic_hist_accuracy"], 1.0
        )
        self.assertTrue(by_id["qa3"]["features"]["topic_has_exposure"])
        self.assertFalse(by_id["qa2"]["features"]["topic_has_exposure"])
        self.assertIsNone(by_id["qa2"]["features"]["topic_hist_accuracy"])

    def test_deterministic_tie_ordering(self):
        rows = [
            fx.outcome("qaB", "qz1", at=fx.BASE, correct=True),
            fx.outcome("qaA", "qz1", at=fx.BASE, correct=False),
        ]
        first = build_feature_table(fx.tables(list(rows)))["rows"]
        second = build_feature_table(fx.tables(list(reversed(rows))))["rows"]
        self.assertEqual(
            [r["question_attempt_id"] for r in first],
            [r["question_attempt_id"] for r in second],
        )
        self.assertEqual(first, second)


class MasteryPreimageTest(unittest.TestCase):
    def test_preimage_used_when_strictly_before(self):
        outcomes = [fx.outcome("qa1", "qz1", at=fx.at_days(2), correct=True)]
        mastery = [fx.mastery(at=fx.at_days(1), score=82.5, recent=60.0,
                              level="DEVELOPING", trend="IMPROVING",
                              difficulty="HARD")]
        result = build_feature_table(fx.tables(outcomes, mastery))
        feats = result["rows"][0]["features"]
        self.assertAlmostEqual(feats["prev_mastery_score"], 82.5)
        self.assertEqual(feats["prev_mastery_level"], "DEVELOPING")
        self.assertAlmostEqual(feats["prev_recent_accuracy"], 0.6)
        self.assertEqual(feats["prev_trend"], "IMPROVING")
        self.assertEqual(feats["prev_difficulty"], "HARD")
        self.assertTrue(
            result["rows"][0]["provenance"]["mastery_preimage_found"]
        )

    def test_post_image_at_equal_timestamp_excluded(self):
        outcomes = [fx.outcome("qa1", "qz1", at=fx.at_days(1), correct=True)]
        mastery = [fx.mastery(at=fx.at_days(1), score=99.0)]
        result = build_feature_table(fx.tables(outcomes, mastery))
        feats = result["rows"][0]["features"]
        self.assertIsNone(feats["prev_mastery_score"])
        self.assertIsNone(feats["prev_mastery_level"])
        self.assertIsNone(feats["prev_recent_accuracy"])
        self.assertFalse(
            result["rows"][0]["provenance"]["mastery_preimage_found"]
        )

    def test_future_mastery_ignored_for_earlier_target(self):
        outcomes = [
            fx.outcome("qa1", "qz1", at=fx.at_days(0), correct=True),
            fx.outcome("qa2", "qz2", at=fx.at_days(5), correct=True),
        ]
        mastery = [fx.mastery(at=fx.at_days(5), score=95.0)]
        result = build_feature_table(fx.tables(outcomes, mastery))
        by_id = {r["question_attempt_id"]: r for r in result["rows"]}
        self.assertIsNone(by_id["qa1"]["features"]["prev_mastery_score"])
        self.assertIsNone(by_id["qa2"]["features"]["prev_mastery_score"])

    def test_invalid_preimage_scale_rejects_loudly(self):
        outcomes = [fx.outcome("qa1", "qz1", at=fx.at_days(2))]
        mastery = [fx.mastery(at=fx.at_days(1), score=150.0)]
        result = build_feature_table(fx.tables(outcomes, mastery))
        self.assertEqual(result["rows"], [])
        self.assertEqual(len(result["rejections"]), 1)
        self.assertIn("invalid_mastery_preimage_score",
                      result["rejections"][0]["reason"])

    def test_invalid_preimage_tokens_reject_loudly(self):
        outcomes = [fx.outcome("qa1", "qz1", at=fx.at_days(2))]
        for bad in ({"level": "GRANDMASTER"}, {"trend": "SOARING"},
                    {"difficulty": "NIGHTMARE"}):
            mastery = [fx.mastery(at=fx.at_days(1), **bad)]
            result = build_feature_table(fx.tables(outcomes, mastery))
            self.assertEqual(result["rows"], [], bad)
            self.assertEqual(len(result["rejections"]), 1)


class TimingTest(unittest.TestCase):
    def test_most_recent_valid_prior_used(self):
        outcomes = [
            fx.outcome("qa1", "qz1", at=fx.at_days(0), response_time=30),
            fx.outcome("qa2", "qz2", at=fx.at_days(1), response_time=None),
            fx.outcome("qa3", "qz3", at=fx.at_days(2), response_time=90),
        ]
        result = build_feature_table(fx.tables(outcomes))
        by_id = {r["question_attempt_id"]: r for r in result["rows"]}
        self.assertFalse(by_id["qa1"]["features"]["timing_known"])
        self.assertTrue(by_id["qa2"]["features"]["timing_known"])
        self.assertEqual(
            by_id["qa2"]["features"]["prev_response_time_norm"], 30
        )
        # qa3 sees the most recent valid prior (qa1's 30; qa2 missing).
        self.assertEqual(
            by_id["qa3"]["features"]["prev_response_time_norm"], 30
        )

    def test_current_row_timing_never_used_for_itself(self):
        outcomes = [
            fx.outcome("qa1", "qz1", at=fx.at_days(0), response_time=999),
        ]
        result = build_feature_table(fx.tables(outcomes))
        feats = result["rows"][0]["features"]
        self.assertFalse(feats["timing_known"])
        self.assertIsNone(feats["prev_response_time_norm"])

    def test_negative_timing_treated_as_missing(self):
        outcomes = [
            fx.outcome("qa1", "qz1", at=fx.at_days(0), response_time=-5),
            fx.outcome("qa2", "qz2", at=fx.at_days(1)),
        ]
        result = build_feature_table(fx.tables(outcomes))
        by_id = {r["question_attempt_id"]: r for r in result["rows"]}
        self.assertFalse(by_id["qa2"]["features"]["timing_known"])


class EligibilityTest(unittest.TestCase):
    def test_incomplete_attempts_rejected(self):
        outcomes = [
            fx.outcome("qa1", "qz1", at=fx.BASE, status="IN_PROGRESS"),
            fx.outcome("qa2", "qz2", at=fx.BASE, status="ABANDONED"),
        ]
        result = build_feature_table(fx.tables(outcomes))
        self.assertEqual(result["rows"], [])
        self.assertEqual(len(result["rejections"]), 2)

    def test_missing_submitted_at_rejected(self):
        row = fx.outcome("qa1", "qz1", correct=True)
        row["submitted_at"] = None
        result = build_feature_table(fx.tables([row]))
        self.assertEqual(result["rows"], [])
        self.assertIn("missing_submitted_at",
                      result["rejections"][0]["reason"])

    def test_invalid_difficulty_rejects_loudly(self):
        bad_q = fx.outcome("qa1", "qz1", at=fx.BASE, question_diff="EXPERT")
        result = build_feature_table(fx.tables([bad_q]))
        self.assertEqual(result["rows"], [])
        self.assertIn("invalid_question_difficulty",
                      result["rejections"][0]["reason"])
        bad_z = fx.outcome("qa2", "qz2", at=fx.BASE, quiz_diff="easy")
        result = build_feature_table(fx.tables([bad_z]))
        self.assertEqual(result["rows"], [])
        self.assertIn("invalid_quiz_difficulty",
                      result["rejections"][0]["reason"])

    def test_difficulties_pass_through_verbatim(self):
        row = fx.outcome("qa1", "qz1", at=fx.BASE, question_diff="HARD",
                         quiz_diff="EASY")
        result = build_feature_table(fx.tables([row]))
        feats = result["rows"][0]["features"]
        self.assertEqual(feats["question_difficulty"], "HARD")
        self.assertEqual(feats["quiz_difficulty"], "EASY")


class DeterminismTest(unittest.TestCase):
    def test_repeated_builds_identical(self):
        outcomes = [
            fx.outcome(f"qa{i}", f"qz{i % 3}", at=fx.BASE + timedelta(hours=i),
                       correct=(i % 3 != 0),
                       response_time=(10 + i) if i % 2 else None)
            for i in range(12)
        ]
        tables = fx.tables(
            outcomes,
            [fx.mastery(at=fx.BASE + timedelta(hours=2))],
            [fx.recommendation(at=fx.BASE + timedelta(hours=1))],
        )
        first = build_feature_table(tables)
        second = build_feature_table(tables)
        self.assertEqual(first["rows"], second["rows"])
        self.assertEqual(
            first["data_version"], second["data_version"]
        )

    def test_input_order_does_not_matter(self):
        outcomes = [
            fx.outcome(f"qa{i}", f"qz{i}", at=fx.at_days(i % 4),
                       correct=bool(i % 2))
            for i in range(10)
        ]
        forward = build_feature_table(fx.tables(list(outcomes)))["rows"]
        backward = build_feature_table(
            fx.tables(list(reversed(outcomes))))["rows"]
        self.assertEqual(forward, backward)

    def test_data_version_deterministic_no_wallclock(self):
        outcomes = [fx.outcome("qa1", "qz1", at=fx.BASE)]
        first = build_feature_table(fx.tables(outcomes))["data_version"]
        second = build_feature_table(fx.tables(outcomes))["data_version"]
        self.assertEqual(first, second)
        self.assertNotIn("2026-09-14", first.replace(fx.BASE.isoformat(), ""))


if __name__ == "__main__":
    unittest.main()
