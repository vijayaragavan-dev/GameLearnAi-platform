"""Gate 17: leakage test suite (fails loudly on any point-in-time breach).

Each test injects a distinctive "trap" value that could only reach the
feature vector through a specific leak, then asserts absence.  All tests
use synthetic fixtures — no database required.
"""

from __future__ import annotations

import json
import unittest

from mlrag.feature_pipeline.builder import build_feature_table
from mlrag.feature_pipeline.contract import FEATURE_COLUMNS, LEAKAGE_BLOCKLIST

from . import gate17_fixtures as fx


def features_of(result, qaid):
    for row in result["rows"]:
        if row["question_attempt_id"] == qaid:
            return dict(row["features"])
    raise AssertionError(f"missing row {qaid}")


def row_of(result, qaid):
    for row in result["rows"]:
        if row["question_attempt_id"] == qaid:
            return row
    raise AssertionError(f"missing row {qaid}")


def flattened_text(mapping):
    return json.dumps(mapping, sort_keys=True, default=str)


class LeakageTest(unittest.TestCase):
    def test_01_current_correctness_not_in_features(self):
        base = [
            fx.outcome("qa1", "qz1", at=fx.at_days(0), correct=True),
            fx.outcome("qa2", "qz2", at=fx.at_days(1), correct=True),
        ]
        flipped = [
            fx.outcome("qa1", "qz1", at=fx.at_days(0), correct=True),
            fx.outcome("qa2", "qz2", at=fx.at_days(1), correct=False),
        ]
        before = features_of(build_feature_table(fx.tables(base)), "qa2")
        after = features_of(build_feature_table(fx.tables(flipped)), "qa2")
        self.assertEqual(before, after)

    def test_02_selected_answer_absent(self):
        tables = fx.tables([
            fx.outcome("qa1", "qz1", at=fx.at_days(0),
                       selected_answer="SUPER_SECRET_OPTION_B"),
            fx.outcome("qa2", "qz2", at=fx.at_days(1),
                       selected_answer="SUPER_SECRET_OPTION_B"),
        ])
        result = build_feature_table(tables)
        for row in result["rows"]:
            self.assertNotIn("SUPER_SECRET_OPTION_B",
                             flattened_text(row["features"]))
            self.assertNotIn("selected_answer", row["features"])

    def test_03_current_score_absent_from_features(self):
        low = fx.tables([
            fx.outcome("qa1", "qz1", at=fx.at_days(0)),
            fx.outcome("qa2", "qz2", at=fx.at_days(1)),
        ])
        high = fx.tables([
            fx.outcome("qa1", "qz1", at=fx.at_days(0), quiz_score=100.0,
                       quiz_correct_count=99, quiz_total_questions=99),
            fx.outcome("qa2", "qz2", at=fx.at_days(1), quiz_score=0.0,
                       quiz_correct_count=0, quiz_total_questions=99),
        ])
        self.assertEqual(
            features_of(build_feature_table(low), "qa2"),
            features_of(build_feature_table(high), "qa2"),
        )
        self.assertNotIn("quiz_score", features_of(
            build_feature_table(high), "qa2"))

    def test_04_post_image_mastery_absent(self):
        trap_time = fx.at_days(1)
        tables = fx.tables(
            [fx.outcome("qa1", "qz1", at=trap_time, correct=True)],
            [fx.mastery(at=trap_time, score=99.99, recent=99.99,
                        level="MASTERED", trend="IMPROVING")],
        )
        result = build_feature_table(tables)
        feats = features_of(result, "qa1")
        self.assertIsNone(feats["prev_mastery_score"])
        self.assertIsNone(feats["prev_mastery_level"])
        self.assertIsNone(feats["prev_recent_accuracy"])
        self.assertNotIn("99.99", flattened_text(feats))

    def test_05_post_image_recommendation_absent(self):
        trap_time = fx.at_days(1)
        tables = fx.tables(
            [fx.outcome("qa1", "qz1", at=trap_time)],
            [],
            [fx.recommendation(at=trap_time)],
        )
        result = build_feature_table(tables)
        for row in result["rows"]:
            for key in row["features"]:
                self.assertNotIn("recommend", key.lower())
        self.assertNotIn("PRACTICE",
                         flattened_text(result["rows"][0]["features"]))

    def test_06_future_attempts_absent(self):
        prefix = [
            fx.outcome("qa1", "qz1", at=fx.at_days(0), correct=True),
            fx.outcome("qa2", "qz2", at=fx.at_days(1), correct=False),
        ]
        extended = prefix + [
            fx.outcome("qaF", "qzF", at=fx.at_days(30), correct=True),
        ]
        before = build_feature_table(fx.tables(prefix))["rows"]
        after = build_feature_table(fx.tables(extended))["rows"]
        keep = [r for r in after
                if r["question_attempt_id"] in ("qa1", "qa2")]
        # data_version legitimately covers the snapshot's eligible rows, so
        # it changes; everything else (X, target, provenance) must not.
        self.assertNotEqual(before[0]["data_version"], keep[0]["data_version"])
        strip = lambda rows: [
            {k: v for k, v in r.items() if k != "data_version"}
            for r in rows
        ]
        self.assertEqual(strip(before), strip(keep))

    def test_07_same_timestamp_siblings_absent(self):
        tables = fx.tables([
            fx.outcome("qa1", "qz1", at=fx.BASE, correct=True),
            fx.outcome("qa2", "qz1", at=fx.BASE, correct=True),
            fx.outcome("qa3", "qz1", at=fx.BASE, correct=True),
        ])
        result = build_feature_table(tables)
        for row in result["rows"]:
            self.assertTrue(row["features"]["is_cold_start"])
            self.assertEqual(row["features"]["prior_total_count"], 0)

    def test_08_future_xp_absent(self):
        tables = fx.tables([
            fx.outcome("qa1", "qz1", at=fx.at_days(0), xp_awarded=7777),
            fx.outcome("qa2", "qz2", at=fx.at_days(1), xp_awarded=7777),
        ])
        result = build_feature_table(tables)
        for row in result["rows"]:
            self.assertNotIn("7777", flattened_text(row["features"]))
            self.assertNotIn("xp_awarded", row["features"])
            self.assertFalse(
                any(k.startswith("xp") for k in row["features"])
            )

    def test_09_future_streak_absent(self):
        tables = fx.tables([
            fx.outcome("qa1", "qz1", at=fx.at_days(0), streak_days=123,
                       current_streak=123),
            fx.outcome("qa2", "qz2", at=fx.at_days(1), streak_days=123,
                       current_streak=123),
        ])
        result = build_feature_table(tables)
        for row in result["rows"]:
            self.assertNotIn("123", flattened_text(row["features"]))
            for key in row["features"]:
                self.assertNotIn("streak", key)

    def test_10_current_recommendation_absent(self):
        # A recommendation generated exactly at T belongs to the current
        # submission's post-state and must not influence the row.
        trap_time = fx.at_days(1)
        without = fx.tables([fx.outcome("qa1", "qz1", at=trap_time)])
        with_rec = fx.tables(
            [fx.outcome("qa1", "qz1", at=trap_time)],
            [],
            [fx.recommendation(at=trap_time)],
        )
        self.assertEqual(
            features_of(build_feature_table(without), "qa1"),
            features_of(build_feature_table(with_rec), "qa1"),
        )

    def test_11_progress_absent(self):
        tables = fx.tables([
            fx.outcome("qa1", "qz1", at=fx.at_days(0),
                       completion_percentage=88.8, progress_status="DONE"),
            fx.outcome("qa2", "qz2", at=fx.at_days(1),
                       completion_percentage=88.8, progress_status="DONE"),
        ])
        result = build_feature_table(tables)
        for row in result["rows"]:
            text = flattened_text(row["features"])
            self.assertNotIn("88.8", text)
            self.assertNotIn("DONE", text)

    def test_12_game_skill_fields_absent(self):
        tables = fx.tables([
            fx.outcome("qa1", "qz1", at=fx.at_days(0), game_score=4242,
                       game_difficulty="HARD", best_combo=42,
                       game_completed=True),
            fx.outcome("qa2", "qz2", at=fx.at_days(1), game_score=4242,
                       game_difficulty="HARD", best_combo=42,
                       game_completed=True),
        ])
        result = build_feature_table(tables)
        for row in result["rows"]:
            text = flattened_text(row["features"])
            self.assertNotIn("4242", text)
            for banned in ("game_score", "game_difficulty", "game_topic_id",
                           "game_completed", "best_combo", "xp_awarded"):
                self.assertNotIn(banned, row["features"])

    def test_13_quiz_duration_seconds_excluded(self):
        tables = fx.tables([
            fx.outcome("qa1", "qz1", at=fx.at_days(0),
                       duration_seconds=3600),
            fx.outcome("qa2", "qz2", at=fx.at_days(1),
                       duration_seconds=3600),
        ])
        result = build_feature_table(tables)
        for row in result["rows"]:
            self.assertNotIn("duration_seconds", row["features"])
            self.assertNotIn("3600", flattened_text(row["features"]))

    def test_14_future_response_times_absent(self):
        tables = fx.tables([
            fx.outcome("qa1", "qz1", at=fx.at_days(0)),
            fx.outcome("qa2", "qz2", at=fx.at_days(1), response_time=5555),
        ])
        result = build_feature_table(tables)
        self.assertNotIn("5555",
                         flattened_text(features_of(result, "qa1")))
        self.assertFalse(features_of(result, "qa1")["timing_known"])

    def test_15_future_catalogue_changes_unused(self):
        # X must follow the at-attempt snapshot, not the live catalogue.
        tables = fx.tables([
            fx.outcome("qa1", "qz1", at=fx.at_days(0), quiz_diff="EASY",
                       catalogue_diff="HARD"),
        ])
        result = build_feature_table(tables)
        feats = features_of(result, "qa1")
        self.assertEqual(feats["quiz_difficulty"], "EASY")
        self.assertFalse(
            result["rows"][0]["provenance"]
            ["quiz_difficulty_matches_catalogue"]
        )

    def test_16_grouping_ids_not_value_features(self):
        tables = fx.tables([
            fx.outcome("qa1", "qz1", at=fx.at_days(0)),
            fx.outcome("qa2", "qz2", at=fx.at_days(1)),
        ])
        result = build_feature_table(tables)
        for row in result["rows"]:
            self.assertNotIn("learner_key", row["features"])
            self.assertNotIn("user_id", row["features"])
            self.assertNotIn(row["learner_key"],
                             flattened_text(row["features"]))

    def test_17_target_never_in_X(self):
        tables = fx.tables([
            fx.outcome("qa1", "qz1", at=fx.at_days(0), correct=True),
            fx.outcome("qa2", "qz2", at=fx.at_days(1), correct=False),
        ])
        result = build_feature_table(tables)
        for row in result["rows"]:
            self.assertEqual(set(row["features"].keys()),
                             set(FEATURE_COLUMNS))
            self.assertNotIn("is_correct", row["features"])

    def test_18_timestamps_after_T_excluded(self):
        # Later mastery must not backfill an earlier target.
        tables = fx.tables(
            [fx.outcome("qa1", "qz1", at=fx.at_days(0))],
            [fx.mastery(at=fx.at_days(10), score=91.0)],
        )
        result = build_feature_table(tables)
        self.assertIsNone(features_of(result, "qa1")["prev_mastery_score"])

    def test_19_current_row_excluded_from_aggregates(self):
        tables = fx.tables(
            [fx.outcome("qaSolo", "qzSolo", at=fx.at_days(3), correct=True)]
        )
        result = build_feature_table(tables)
        feats = features_of(result, "qaSolo")
        self.assertEqual(feats["prior_total_count"], 0)
        self.assertEqual(feats["prior_correct_count"], 0)
        self.assertEqual(feats["attempt_sequence_index"], 0)

    def test_20_strict_lt_not_lte(self):
        moment = fx.at_days(4)
        epsilon = fx.at_days(4)  # exactly equal -> excluded
        tables = fx.tables([
            fx.outcome("qaPrior", "qz0", at=fx.at_days(0), correct=True),
            fx.outcome("qaTie", "qz1", at=epsilon, correct=False),
            fx.outcome("qaTarget", "qz2", at=moment, correct=True),
        ])
        result = build_feature_table(tables)
        feats = features_of(result, "qaTarget")
        # Only qaPrior is strictly before T; the equal-T tie is excluded.
        self.assertEqual(feats["prior_total_count"], 1)
        self.assertAlmostEqual(feats["hist_accuracy"], 1.0)

    def test_blocklist_covers_all_forbidden_families(self):
        for name in (
            "selected_answer", "score", "mastery_score_current",
            "recommendation_current", "future_mastery", "duration_seconds",
            "response_time_seconds", "game_score", "completion_percentage",
            "is_correct", "user_id",
        ):
            self.assertIn(name, LEAKAGE_BLOCKLIST, name)


if __name__ == "__main__":
    unittest.main()
