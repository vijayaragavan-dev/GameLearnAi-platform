"""Gate 24 tests: constrained forest challenger contract.

Synthetic fixture rows only (labeled, via gate19_fixtures); never real
learner data, never training artifacts.  No database.
"""

from __future__ import annotations

import unittest

from mlrag.contracts.common import ContractViolation
from mlrag.learner_intelligence import challenger_rf, config24
from mlrag.modeling import config as g19_config

from . import gate19_fixtures as fx


class ForestConfigTest(unittest.TestCase):
    def test_frozen_constrained_values(self):
        self.assertEqual((config24.N_ESTIMATORS, config24.MAX_DEPTH,
                          config24.MIN_SAMPLES_SPLIT,
                          config24.MIN_SAMPLES_LEAF), (64, 3, 10, 5))
        self.assertEqual(config24.MAX_FEATURES, "sqrt")
        self.assertEqual((config24.RANDOM_STATE, config24.N_JOBS), (42, 1))
        self.assertEqual(config24.MODEL_ID, "rf-pcorrect-g24")
        self.assertEqual((config24.FEATURE_VERSION,
                          config24.DATASET_VERSION), ("f1", "d1"))

    def test_cold_start_bands_reuse_frozen_evidence(self):
        self.assertEqual(config24.SUFFICIENT_HISTORY_MIN, 10)


class ForestFitPredictTest(unittest.TestCase):
    def test_fit_predict_range_and_count(self):
        rows = fx.ladder(n=12, learners=3)
        bundle = challenger_rf.fit(rows)
        probs = challenger_rf.predict_proba(bundle, rows)
        self.assertEqual(len(probs), len(rows))
        for prob in probs:
            self.assertGreaterEqual(prob, 0.0)
            self.assertLessEqual(prob, 1.0)

    def test_empty_predict_returns_empty(self):
        bundle = challenger_rf.fit(fx.ladder(n=12, learners=3))
        self.assertEqual(challenger_rf.predict_proba(bundle, []), [])

    def test_empty_train_raises(self):
        with self.assertRaises(ContractViolation):
            challenger_rf.fit([])

    def test_single_class_train_raises(self):
        rows = fx.ladder(n=8, learners=2)
        for row in rows:
            row["is_correct"] = 1
        with self.assertRaises(ContractViolation):
            challenger_rf.fit(rows)

    def test_invalid_target_raises(self):
        rows = fx.ladder(n=8, learners=2)
        rows[0]["is_correct"] = 2
        with self.assertRaises(ContractViolation):
            challenger_rf.fit(rows)

    def test_deterministic_refit_identical(self):
        import numpy as np
        rows = fx.ladder(n=16, learners=3)
        first = challenger_rf.fit(rows)
        second = challenger_rf.fit(rows)
        p_first = np.asarray(challenger_rf.predict_proba(first, rows))
        p_second = np.asarray(challenger_rf.predict_proba(second, rows))
        self.assertLessEqual(float(np.abs(p_first - p_second).max()),
                             config24.NUMERICAL_TOLERANCE)

    def test_importances_aligned_and_summing(self):
        # NOTE: fx.ladder rows share identical X (alternating labels), so
        # no split is possible there; real pipeline features vary.
        labeled, _ = fx.real_path_labeled(n=24, learners=3)
        bundle = challenger_rf.fit(labeled)
        ranked = challenger_rf.importances(bundle)
        self.assertEqual(len(ranked), len(g19_config.MATRIX_COLUMNS))
        self.assertEqual({r["column"] for r in ranked},
                         set(g19_config.MATRIX_COLUMNS))
        self.assertAlmostEqual(sum(r["importance"] for r in ranked), 1.0,
                               places=9)
        ordered = [r["importance"] for r in ranked]
        self.assertEqual(ordered, sorted(ordered, reverse=True))

    def test_parameter_record_json_safe(self):
        import json
        rows = fx.ladder(n=12, learners=3)
        bundle = challenger_rf.fit(rows)
        record = bundle.parameter_record()
        json.dumps(record, sort_keys=True)
        self.assertEqual(record["model_id"], config24.MODEL_ID)
        self.assertEqual(len(record["feature_importances"]),
                         len(g19_config.MATRIX_COLUMNS))


if __name__ == "__main__":
    unittest.main()
