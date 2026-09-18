"""Gate 20: fold/cold/difficulty/topic slice correctness."""

from __future__ import annotations

import unittest

from mlrag.evaluation import slices
from mlrag.modeling import experiment as exp19
from mlrag.tests import gate19_fixtures as fx19


def joined(n=12, learners=3):
    labeled, ds = fx19.real_path_labeled(n=n, learners=learners)
    result = exp19.run_experiment(labeled, ds["fingerprint"])
    return slices.join_predictions(
        labeled, result["lolo_protocol"]["predictions"])


class JoinTest(unittest.TestCase):
    def test_join_attaches_context(self):
        rows = joined()
        self.assertEqual(len(rows), 12)
        for record in rows:
            for key in ("topic_id", "question_difficulty", "row_is_cold",
                        "p_correct_A", "p_correct_model"):
                self.assertIn(key, record)

    def test_join_drops_unmatched(self):
        rows = joined()
        extra = [dict(rows[0], row_id="datarow_missing")]
        self.assertEqual(len(slices.join_predictions([], extra)), 0)


class FoldTableTest(unittest.TestCase):
    def test_folds_cover_all_rows(self):
        rows = joined()
        table = slices.fold_table(rows)
        self.assertEqual(len(table), 3)
        self.assertEqual(sum(f["n"] for f in table), 12)
        for fold in table:
            self.assertIn(fold["fold"], ("fold_01", "fold_02", "fold_03"))
            self.assertEqual(set(fold["methods"]), {"A", "B", "C", "model"})
            self.assertIn(fold["challenger_beats_strongest"], (True, False))

    def test_single_class_fold_flags_roc(self):
        single = [dict(r, is_correct=1) for r in joined()]
        table = slices.fold_table(single)
        for fold in table:
            self.assertFalse(fold["roc_computable"])
            for method in ("A", "B", "C", "model"):
                self.assertIsNone(
                    fold["methods"][method]["roc_auc"])


class SliceTest(unittest.TestCase):
    def test_cold_slices_partition(self):
        rows = joined()
        result = slices.cold_slices(rows)
        self.assertEqual(result["cold"]["n"] + result["non_cold"]["n"], 12)
        self.assertTrue(result["cold"]["statistically_weak"])

    def test_difficulty_zero_coverage_visible(self):
        rows = joined()
        result = slices.difficulty_slices(rows)
        self.assertEqual(set(result), {"EASY", "MEDIUM", "HARD"})
        self.assertEqual(result["EASY"]["n"], 12)
        for level in ("MEDIUM", "HARD"):
            self.assertTrue(result[level]["zero_coverage"])
            self.assertIsNone(
                result[level]["methods"]["model"]["log_loss"])

    def test_topic_slices_with_deltas(self):
        rows = joined()
        result = slices.topic_slices(rows)
        self.assertEqual(sum(v["n"] for v in result.values()), 12)
        for label, info in result.items():
            self.assertTrue(label.startswith("topic_"))
            self.assertIn("challenger_delta_log_loss", info)
            self.assertTrue(info["insufficient"])

    def test_pooled_matches_row_count(self):
        rows = joined()
        pooled = slices.pooled_scored(rows)
        self.assertEqual(pooled["n"], 12)


if __name__ == "__main__":
    unittest.main()
