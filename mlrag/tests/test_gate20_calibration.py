"""Gate 20: fixed-bin calibration, bias math, reliability verdict."""

from __future__ import annotations

import unittest

from mlrag.evaluation import calibration


class CalibrationBinTest(unittest.TestCase):
    def test_fixed_bins_never_optimized(self):
        table = calibration.fixed_bin_table([1, 0, 1, 0],
                                            [0.9, 0.1, 0.8, 0.3])
        self.assertEqual(len(table), 5)
        self.assertEqual([b["bin"] for b in table],
                         [[0.0, 0.2], [0.2, 0.4], [0.4, 0.6],
                          [0.6, 0.8], [0.8, 1.0]])
        occupied = [b for b in table if b["n"] > 0]
        self.assertEqual(len(occupied), 3)
        top = [b for b in table if b["bin"] == [0.8, 1.0]][0]
        self.assertEqual(top["n"], 2)
        self.assertAlmostEqual(top["mean_p"], 0.85)
        self.assertAlmostEqual(top["mean_y"], 1.0)
        self.assertAlmostEqual(top["gap"], -0.15)

    def test_boundary_probability_one(self):
        table = calibration.fixed_bin_table([1], [1.0])
        self.assertEqual(table[-1]["n"], 1)

    def test_bias_math(self):
        summary = calibration.summarize([1, 0, 1, 0], [0.9, 0.1, 0.8, 0.3],
                                        ["learner_A", "learner_B",
                                         "learner_A", "learner_B"])
        self.assertAlmostEqual(
            summary["overall_mean_predicted_probability"], 0.525)
        self.assertAlmostEqual(
            summary["overall_observed_positive_rate"], 0.5)
        self.assertAlmostEqual(summary["signed_bias"], 0.025)
        self.assertEqual(summary["total_n"], 4)
        self.assertEqual(summary["learners_represented"], 2)

    def test_empty_summary(self):
        summary = calibration.summarize([], [])
        self.assertEqual(summary["total_n"], 0)
        self.assertIsNone(summary["signed_bias"])
        self.assertEqual(summary["reliability"], "INSUFFICIENT")

    def test_reliability_insufficient_on_tiny_data(self):
        summary = calibration.summarize(
            [1, 0] * 30, [0.9] * 30 + [0.7] * 30,
            [f"learner_{i % 6}" for i in range(60)])
        # 60 rows < 200 minimum and only 2 of 5 bins occupied.
        self.assertEqual(summary["reliability"], "INSUFFICIENT")
        self.assertFalse(summary["gap_justified"])
        self.assertIsNotNone(summary["weighted_abs_gap"])

    def test_reliability_sufficient_rule(self):
        y_true = [i % 2 for i in range(240)]
        probs = [0.1, 0.3, 0.5, 0.7, 0.9] * 48
        learners = [f"learner_{i % 6}" for i in range(240)]
        summary = calibration.summarize(y_true, probs, learners)
        self.assertEqual(summary["reliability"], "SUFFICIENT")
        self.assertTrue(summary["gap_justified"])


if __name__ == "__main__":
    unittest.main()
