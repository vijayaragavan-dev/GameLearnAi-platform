"""Gate 20: extended metric correctness and NOT COMPUTABLE handling."""

from __future__ import annotations

import unittest

from mlrag.evaluation import populations


class ExtendedMetricsTest(unittest.TestCase):
    def test_full_record_fields(self):
        record = populations.score_method([1, 0, 1, 1], [0.9, 0.1, 0.8, 0.4],
                                          "demo", "model")
        self.assertEqual((record["n"], record["n_positive"],
                          record["n_negative"]), (4, 3, 1))
        self.assertAlmostEqual(record["observed_positive_rate"], 0.75)
        self.assertAlmostEqual(record["mean_predicted_probability"], 0.55)
        # Predicted classes at threshold 0.5: [1, 0, 1, 0] -> rate 0.5.
        self.assertAlmostEqual(record["positive_prediction_rate"], 0.5)
        self.assertIsInstance(record["log_loss"], float)
        self.assertIsInstance(record["brier"], float)
        self.assertIsInstance(record["accuracy"], float)
        # 3 pos / 1 neg -> ROC NOT COMPUTABLE.
        self.assertIsNone(record["roc_auc"])
        self.assertIsNone(record["pr_auc"])
        self.assertIsNone(record["reason"])

    def test_auc_when_valid(self):
        record = populations.score_method([1, 1, 0, 0], [0.9, 0.8, 0.2, 0.1],
                                          "demo", "model")
        self.assertAlmostEqual(record["roc_auc"], 1.0)
        self.assertIsNotNone(record["pr_auc"])

    def test_single_class_roc_not_computable(self):
        record = populations.score_method([1, 1, 1], [0.7, 0.8, 0.9],
                                          "demo", "model")
        self.assertIsNone(record["roc_auc"])
        self.assertIsNotNone(record["log_loss"])
        self.assertIsNotNone(record["brier"])

    def test_empty_population_not_computable(self):
        record = populations.score_method([], [], "empty", "model")
        for name in ("observed_positive_rate",
                     "mean_predicted_probability",
                     "positive_prediction_rate", "log_loss", "brier",
                     "accuracy", "roc_auc", "pr_auc"):
            self.assertIsNone(record[name], name)
        self.assertIn("NOT COMPUTABLE", record["reason"])

    def test_score_population_covers_all_methods(self):
        rows = [{"is_correct": v} for v in (1, 0, 1, 0)]
        probs = {m: [0.6, 0.4, 0.7, 0.3] for m in ("A", "B", "C", "model")}
        result = populations.score_population(rows, probs, "demo")
        self.assertEqual(result["n"], 4)
        self.assertEqual(set(result["methods"]), {"A", "B", "C", "model"})


if __name__ == "__main__":
    unittest.main()
