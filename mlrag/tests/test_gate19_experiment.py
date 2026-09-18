"""Gate 19: metrics, comparison rule, calibration, and protocols."""

from __future__ import annotations

import unittest

from mlrag.contracts.common import ContractViolation
from mlrag.modeling import experiment, metrics

from . import gate19_fixtures as fx


class ScoreSetTest(unittest.TestCase):
    def test_valid_population(self):
        scored = metrics.score_set([1, 0, 1, 1], [0.9, 0.1, 0.8, 0.4],
                                   population="demo")
        self.assertEqual((scored["n"], scored["n_positive"]), (4, 3))
        self.assertAlmostEqual(scored["positive_rate"], 0.75)
        for name in ("log_loss", "brier", "accuracy"):
            self.assertIsInstance(scored[name], float)
        # 3 positives but only 1 negative -> AUC NOT COMPUTABLE.
        self.assertIsNone(scored["roc_auc"])
        self.assertIsNone(scored["pr_auc"])

    def test_auc_available_with_enough_classes(self):
        scored = metrics.score_set([1, 1, 0, 0], [0.9, 0.8, 0.2, 0.1])
        self.assertAlmostEqual(scored["roc_auc"], 1.0)

    def test_empty_population_not_computable(self):
        scored = metrics.score_set([], [], population="empty")
        for name in ("log_loss", "brier", "accuracy", "roc_auc",
                     "pr_auc", "positive_rate"):
            self.assertIsNone(scored[name])
        self.assertIn("NOT COMPUTABLE", scored["reason"])

    def test_misaligned_rows_rejected(self):
        with self.assertRaises(ValueError):
            metrics.score_rows(fx.ladder(n=3), [0.5, 0.5])


class ComparisonRuleTest(unittest.TestCase):
    def _scored(self, model_ll, model_br, base_ll=0.7, base_br=0.25):
        return {
            name: {"log_loss": base_ll, "brier": base_br}
            for name in ("A", "B", "C")
        } | {"model": {"log_loss": model_ll, "brier": model_br}}

    def test_beats_all_requires_both_metrics(self):
        result = metrics.compare_vs_baselines(self._scored(0.6, 0.2))
        self.assertTrue(result["beats_all"])
        self.assertEqual(result["verdict"], "CHALLENGER BEATS BASELINES")

    def test_losing_one_metric_is_not_a_win(self):
        result = metrics.compare_vs_baselines(self._scored(0.6, 0.3))
        self.assertFalse(result["beats_all"])
        self.assertEqual(result["verdict"],
                         "CHALLENGER DOES NOT BEAT BASELINES")

    def test_none_is_never_a_win(self):
        scored = self._scored(0.6, 0.2)
        scored["B"] = {"log_loss": None, "brier": None}
        result = metrics.compare_vs_baselines(scored)
        self.assertIsNone(result["beats_all"])
        self.assertIn("NOT COMPUTABLE", result["verdict"])


class CalibrationTest(unittest.TestCase):
    def test_table_shape_and_summary(self):
        table = metrics.calibration_table([1, 0, 1, 0],
                                          [0.9, 0.1, 0.8, 0.3])
        self.assertEqual(len(table), 5)
        summary = metrics.summarize_calibration(table)
        self.assertEqual(summary["total_n"], 4)
        self.assertFalse(summary["sufficient_sample"])
        self.assertIsNotNone(summary["overall_bias"])

    def test_empty_table_summary(self):
        summary = metrics.summarize_calibration(
            metrics.calibration_table([], []))
        self.assertEqual(summary["total_n"], 0)
        self.assertIsNone(summary["overall_bias"])


class ProtocolTest(unittest.TestCase):
    def test_split_protocol_empty_test_not_computable(self):
        labeled, _ = fx.real_path_labeled(n=12, learners=3)
        for row in labeled:
            if row["split"] == "test":
                row["split"] = "validation"
        self.assertTrue(any(r["split"] == "train" for r in labeled))
        result = experiment.run_split_protocol(labeled, "fp-test-123")
        self.assertEqual(result["populations"]["test"]["n"], 0)
        self.assertIn("NOT COMPUTABLE",
                      result["populations"]["test"]["reason"])
        self.assertTrue(result["experiment_id"].startswith("g19-exp-d1f1-"))

    def test_split_protocol_empty_train_raises(self):
        labeled, _ = fx.real_path_labeled(n=6, learners=2)
        for row in labeled:
            row["split"] = "validation"
        with self.assertRaises(ContractViolation):
            experiment.run_split_protocol(labeled, "fp-test-123")

    def test_lolo_protocol_structure(self):
        labeled, _ = fx.real_path_labeled(n=12, learners=3)
        result = experiment.run_lolo_protocol(labeled, "fp-test-abc")
        self.assertEqual(result["n_folds"], 3)
        self.assertEqual(result["pooled"]["n"], 12)
        verdict = result["pooled"]["comparison"]["verdict"]
        self.assertIn(verdict, ("CHALLENGER BEATS BASELINES",
                                "CHALLENGER DOES NOT BEAT BASELINES",
                                "NOT COMPUTABLE: insufficient evidence"))
        # Cold slices exist for every scored population.
        self.assertEqual(set(result["pooled"]["cold_slices"]),
                         {"cold", "non_cold"})

    def test_lolo_needs_two_learners(self):
        rows = [fx.d1_row(f"O{i}", learner="learner_only", correct=i % 2)
                for i in range(4)]
        with self.assertRaises(ContractViolation):
            experiment.run_lolo_protocol(rows, "fp-x")

    def test_prediction_records_carry_output_contract(self):
        labeled, _ = fx.real_path_labeled(n=9, learners=3)
        result = experiment.run_experiment(labeled, "fp-contract-1")
        records = (result["split_protocol"]["predictions"]
                   + result["lolo_protocol"]["predictions"])
        self.assertTrue(records)
        for record in records:
            for key in ("experiment_id", "row_id", "predicted_at",
                        "model_version", "feature_version",
                        "dataset_version", "p_correct_model"):
                self.assertIn(key, record)
            self.assertGreaterEqual(record["p_correct_model"], 0.0)
            self.assertLessEqual(record["p_correct_model"], 1.0)

    def test_full_experiment_record(self):
        labeled, _ = fx.real_path_labeled(n=9, learners=3)
        result = experiment.run_experiment(labeled, "fp-full-1")
        self.assertEqual(result["model_id"], "logreg-pcorrect-g19")
        self.assertEqual(result["primary_metric"], "log_loss")
        self.assertIn("solver_config", result)
        self.assertIn("baselines", result)


if __name__ == "__main__":
    unittest.main()
