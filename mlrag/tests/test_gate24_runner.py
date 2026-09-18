"""Gate 24 tests: runner mechanics + live-data regression.

Fixture rows (labeled synthetic) exercise protocol mechanics; the
committed Gate 18 dataset artifact (read-only, real) pins the honest
numbers: LR reproduces Gate 19 exactly and RF verdicts match the
recorded experiment.
"""

from __future__ import annotations

import json
import unittest
from pathlib import Path

from mlrag.contracts.common import ContractViolation
from mlrag.learner_intelligence import runner

from . import gate19_fixtures as fx

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
GATE18 = REPO_ROOT / "mlrag" / "artifacts" / "gate18_dataset.json"
GATE24EXP = REPO_ROOT / "mlrag" / "artifacts" / "gate24_experiment.json"


def _labeled_fixture():
    labeled, _ = fx.real_path_labeled(n=12, learners=3)
    return labeled


class RunnerMechanicsTest(unittest.TestCase):
    def test_split_protocol_empty_test_is_honest(self):
        labeled = _labeled_fixture()
        result = runner.run_split_protocol(labeled, "fp-test",
                                           runner.rf_spec(), "exp-test")
        self.assertEqual(result["populations"]["test"]["n"], 0)
        self.assertIn("NOT COMPUTABLE",
                      result["populations"]["test"]["reason"])
        self.assertIn("validation", result["populations"])

    def test_split_protocol_requires_train(self):
        with self.assertRaises(ContractViolation):
            runner.run_split_protocol([], "fp", runner.rf_spec(), "exp")

    def test_lolo_requires_two_learners(self):
        labeled = _labeled_fixture()
        single = [r for r in labeled if r["learner_key"] == "learner_0"]
        with self.assertRaises(ContractViolation):
            runner.run_lolo_protocol(single, "fp", runner.rf_spec(), "exp")

    def test_lolo_covers_every_row_once(self):
        labeled = _labeled_fixture()
        result = runner.run_lolo_protocol(labeled, "fp-test",
                                          runner.rf_spec(), "exp-test")
        self.assertEqual(result["n_total"], len(labeled))
        self.assertEqual(len(result["predictions"]), len(labeled))
        self.assertEqual(result["n_folds"], 3)

    def test_slices_present_with_history_bands(self):
        labeled = _labeled_fixture()
        result = runner.run_lolo_protocol(labeled, "fp-test",
                                          runner.rf_spec(), "exp-test")
        pooled = result["pooled"]
        for name in ("cold", "non_cold"):
            self.assertIn(name, pooled["slices"])
        self.assertIn("history_bands", pooled["slices"])
        self.assertIn("difficulty", pooled["slices"])
        self.assertIn("topic", pooled["slices"])
        for method in ("A", "B", "C", "model"):
            self.assertIn(method, pooled["scored"])
        self.assertIn(pooled["comparison"]["verdict"],
                      ("CHALLENGER BEATS BASELINES",
                       "CHALLENGER DOES NOT BEAT BASELINES",
                       "NOT COMPUTABLE: insufficient evidence"))

    def test_candidate_specs_identified(self):
        lr, rf = runner.lr_spec(), runner.rf_spec()
        self.assertEqual((lr.model_id, rf.model_id),
                         ("logreg-pcorrect-g19", "rf-pcorrect-g24"))


class LiveRegressionTest(unittest.TestCase):
    """Real committed data: numbers must match the recorded experiment."""

    @classmethod
    def setUpClass(cls):
        dataset = json.loads(GATE18.read_text(encoding="utf-8"))
        cls.rows = dataset["rows"]
        cls.recorded = json.loads(GATE24EXP.read_text(encoding="utf-8"))

    def test_lr_reproduces_gate19_exactly(self):
        result = runner.run_lolo_protocol(
            self.rows, self.recorded["dataset_fingerprint"],
            runner.lr_spec(), "reg-test")
        scored = result["pooled"]["scored"]["model"]
        self.assertAlmostEqual(scored["log_loss"], 7.4846, places=3)
        self.assertAlmostEqual(scored["brier"], 0.2818, places=3)

    def test_rf_pooled_matches_recorded(self):
        recorded = self.recorded["candidates"]["rf-pcorrect-g24"][
            "lolo_protocol"]["pooled"]["scored"]["model"]
        result = runner.run_lolo_protocol(
            self.rows, self.recorded["dataset_fingerprint"],
            runner.rf_spec(), "reg-test")
        scored = result["pooled"]["scored"]["model"]
        self.assertAlmostEqual(scored["log_loss"], recorded["log_loss"],
                               places=6)
        self.assertAlmostEqual(scored["brier"], recorded["brier"], places=6)

    def test_neither_candidate_beats_baseline_c(self):
        for mid in ("logreg-pcorrect-g19", "rf-pcorrect-g24"):
            pooled = self.recorded["candidates"][mid]["lolo_protocol"][
                "pooled"]
            model_ll = pooled["scored"]["model"]["log_loss"]
            c_ll = pooled["scored"]["C"]["log_loss"]
            model_b = pooled["scored"]["model"]["brier"]
            c_b = pooled["scored"]["C"]["brier"]
            self.assertGreater(model_ll, c_ll, mid)
            self.assertGreater(model_b, c_b, mid)
            self.assertEqual(pooled["comparison"]["verdict"],
                             "CHALLENGER DOES NOT BEAT BASELINES")


if __name__ == "__main__":
    unittest.main()
