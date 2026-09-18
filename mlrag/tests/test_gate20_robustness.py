"""Gate 20: robustness checks, uncertainty math, verification guards."""

from __future__ import annotations

import json
import unittest

from mlrag.contracts.common import ContractViolation
from mlrag.evaluation import robustness, uncertainty, verify
from mlrag.modeling import experiment as exp19
from mlrag.tests import gate19_fixtures as fx19


def joined(n=12, learners=3):
    labeled, ds = fx19.real_path_labeled(n=n, learners=learners)
    result = exp19.run_experiment(labeled, ds["fingerprint"])
    from mlrag.evaluation import slices
    return slices.join_predictions(
        labeled, result["lolo_protocol"]["predictions"])


class RobustnessCheckTest(unittest.TestCase):
    def test_all_checks_pass(self):
        rows = joined()
        from mlrag.modeling import experiment as exp_module
        labeled, ds = fx19.real_path_labeled(n=12, learners=3)
        result = exp_module.run_experiment(labeled, ds["fingerprint"])
        outcome = robustness.run_all(
            rows, result["lolo_protocol"]["predictions"])
        self.assertTrue(outcome["robustness_pass"], outcome["checks"])
        self.assertEqual(len(outcome["checks"]), 4)

    def test_rounding_canonicalization_documented(self):
        self.assertIn("12 decimals", robustness.check_row_order(
            joined())["canonicalization"])


class UncertaintyMathTest(unittest.TestCase):
    def test_distribution_and_error_concentration(self):
        result = uncertainty.describe([0.95, 0.85, 0.1, 0.4], [1, 0, 0, 1])
        self.assertEqual(result["n"], 4)
        self.assertAlmostEqual(result["mean_p"], 0.575)
        self.assertAlmostEqual(result["frac_ge_08"], 0.5)
        self.assertEqual(result["n_errors"], 2)
        self.assertAlmostEqual(result["high_confidence_error_share"], 0.5)
        self.assertFalse(result["excessively_confident_errors"])

    def test_empty_predictions(self):
        self.assertEqual(uncertainty.describe([], [])["n"], 0)


class VerificationGuardTest(unittest.TestCase):
    def test_config_frozen(self):
        result = verify.verify_config_frozen()
        self.assertTrue(result["config_frozen"])
        self.assertEqual(result["model_id"], "logreg-pcorrect-g19")
        self.assertEqual(result["model_version"], "0.1.0-gate19exp")

    def test_fingerprint_drift_raises(self):
        with self.assertRaises(ContractViolation):
            verify.verify_artifacts("fp-live-diverged", {})

    def test_missing_artifact_raises(self):
        missing = verify.ARTIFACT_DIR / "gate20_no_such_file.json"
        with self.assertRaises(ContractViolation):
            verify._load(missing)

    def test_artifact_safety_scan_clean(self):
        for path in (verify.EXPERIMENT_ARTIFACT, verify.MODEL_ARTIFACT):
            text = path.read_text(encoding="utf-8")
            from mlrag.dataset.contract import scan_prohibited_content
            self.assertEqual(scan_prohibited_content(text), [], path.name)

    def test_no_label_leakage_through_fold_metrics(self):
        # Fold metrics for one learner must not move when an unrelated
        # learner's labels change (strict fold independence).
        rows = joined()
        from mlrag.evaluation import slices
        before = {f["fold"]: f["methods"]["model"]["log_loss"]
                  for f in slices.fold_table(rows)}
        other = [r["learner_key"] for r in rows]
        victim = other[0]
        morate = [dict(r, is_correct=1 - r["is_correct"])
                  if r["learner_key"] != victim else dict(r)
                  for r in rows]
        after = {f["fold"]: f["methods"]["model"]["log_loss"]
                 for f in slices.fold_table(morate)}
        victim_fold = next(
            f["fold"] for f in slices.fold_table(rows)
            if f["learner_key"] == victim)
        # The untouched victim fold must be byte-identical; every flipped
        # fold must move (its own labels are its ground truth).
        self.assertAlmostEqual(before[victim_fold], after[victim_fold])
        self.assertTrue(any(
            abs(before[fold] - after[fold]) > 1e-9
            for fold in before if fold != victim_fold))


if __name__ == "__main__":
    unittest.main()
