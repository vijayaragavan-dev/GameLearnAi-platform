"""Gate 19: single frozen challenger configuration and output contract."""

from __future__ import annotations

import math
import unittest

from mlrag.contracts.common import ContractViolation
from mlrag.modeling import challenger, config

from . import gate19_fixtures as fx


class ChallengerConfigTest(unittest.TestCase):
    def test_single_frozen_configuration(self):
        self.assertEqual((config.MODEL_ID, config.MODEL_VERSION),
                         ("logreg-pcorrect-g19", "0.1.0-gate19exp"))
        self.assertEqual((config.SOLVER, config.C_VALUE,
                          config.MAX_ITER, config.RANDOM_STATE),
                         ("lbfgs", 1.0, 1000, 42))
        self.assertEqual((config.FEATURE_VERSION, config.DATASET_VERSION),
                         ("f1", "d1"))
        self.assertEqual(config.PRIMARY_METRIC, "log_loss")
        self.assertEqual(config.CO_PRIMARY_METRIC, "brier")


class ChallengerFitPredictTest(unittest.TestCase):
    def test_fit_predict_valid_probabilities(self):
        train = fx.ladder(n=10, learners=2)
        bundle = challenger.fit(train)
        probs = challenger.predict_proba(bundle, train)
        self.assertEqual(len(probs), len(train))
        for prob in probs:
            self.assertIsInstance(prob, float)
            self.assertTrue(math.isfinite(prob))
            self.assertGreaterEqual(prob, 0.0)
            self.assertLessEqual(prob, 1.0)

    def test_deterministic_refit(self):
        train = fx.ladder(n=10, learners=2)
        first = challenger.predict_proba(challenger.fit(train), train)
        second = challenger.predict_proba(challenger.fit(train), train)
        self.assertEqual(first, second)

    def test_single_class_train_raises_loudly(self):
        single = [fx.d1_row(f"S{i}", correct=1) for i in range(4)]
        with self.assertRaises(ContractViolation):
            challenger.fit(single)

    def test_empty_train_raises_loudly(self):
        with self.assertRaises(ContractViolation):
            challenger.fit([])

    def test_empty_predict_returns_empty(self):
        bundle = challenger.fit(fx.ladder(n=6, learners=2))
        self.assertEqual(challenger.predict_proba(bundle, []), [])

    def test_coefficient_record_has_versions_no_pii(self):
        bundle = challenger.fit(fx.ladder(n=8, learners=2))
        record = bundle.coefficient_record()
        self.assertEqual(record["model_id"], "logreg-pcorrect-g19")
        self.assertEqual(record["feature_version"], "f1")
        self.assertEqual(record["dataset_version"], "d1")
        self.assertEqual(len(record["coefficients"]), 31)
        text = str(record)
        for banned in ("learner_", "user", "password", "selected_answer"):
            self.assertNotIn(banned, text)

    def test_real_path_rows_trainable(self):
        labeled, _ = fx.real_path_labeled(n=12, learners=3)
        train = [r for r in labeled if r["split"] == "train"]
        self.assertTrue(train)
        bundle = challenger.fit(train)
        probs = challenger.predict_proba(bundle, labeled)
        self.assertEqual(len(probs), len(labeled))


if __name__ == "__main__":
    unittest.main()
