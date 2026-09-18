"""Gate 19: leakage-safe preprocessing tests (train-only statistics)."""

from __future__ import annotations

import unittest

import numpy as np

from mlrag.contracts.common import ContractViolation
from mlrag.modeling import config, preprocessing

from . import gate19_fixtures as fx


class PreprocessingContractTest(unittest.TestCase):
    def test_matrix_shape_and_column_order(self):
        rows = fx.ladder(n=6)
        fitted = preprocessing.fit(rows)
        matrix = fitted.transform(rows)
        self.assertEqual(matrix.shape, (6, 31))
        self.assertEqual(len(config.MATRIX_COLUMNS), 31)
        self.assertTrue(all(c.startswith("num__")
                            for c in config.MATRIX_COLUMNS[:11]))
        self.assertTrue(all(c.startswith("bool__")
                            for c in config.MATRIX_COLUMNS[11:14]))
        self.assertTrue(all(c.startswith("oh__")
                            for c in config.MATRIX_COLUMNS[14:]))

    def test_exact_19_columns_enforced(self):
        rows = fx.ladder(n=4)
        bad = dict(rows[0]["features"])
        del bad["hist_accuracy"]
        with self.assertRaises(ContractViolation):
            preprocessing.fit([{**rows[0], "features": bad}])

    def test_medians_come_from_train_only(self):
        train = [fx.d1_row(f"T{i}", hist_accuracy=0.1 * (i + 1))
                 for i in range(4)]
        fitted = preprocessing.fit(train)
        medians = dict(zip(config.NUMERIC_COLUMNS, fitted.medians))
        # Train-only median of [0.1, 0.2, 0.3, 0.4]; a held-out row with
        # value 1.0 would move it to 0.3 — fit sees passed rows only.
        self.assertAlmostEqual(medians["hist_accuracy"], 0.25)
        refit = preprocessing.fit(
            train + [fx.d1_row("V9", hist_accuracy=1.0)])
        refit_medians = dict(zip(config.NUMERIC_COLUMNS,
                                 refit.medians))
        self.assertAlmostEqual(refit_medians["hist_accuracy"], 0.3)
        self.assertEqual(fitted.n_train_rows, 4)
        self.assertEqual(refit.n_train_rows, 5)

    def test_all_null_train_column_falls_back_documented(self):
        rows = [fx.d1_row(f"N{i}", prev_mastery_score=None,
                          prev_recent_accuracy=None,
                          prev_response_time_norm=None,
                          prev_mastery_level=None, prev_trend=None,
                          prev_difficulty=None, timing_known=False)
                for i in range(4)]
        fitted = preprocessing.fit(rows)
        report = preprocessing.imputation_report(fitted)
        self.assertIn("prev_mastery_score",
                      report["median_fallback_0_columns"])
        matrix = fitted.transform(rows)
        self.assertTrue(np.all(np.isfinite(matrix)))

    def test_null_categorical_is_all_zero_vector(self):
        rows = [fx.d1_row("Z1", prev_mastery_level=None)]
        fitted = preprocessing.fit(fx.ladder(n=4))
        matrix = fitted.transform(rows)
        idx = [i for i, c in enumerate(config.MATRIX_COLUMNS)
               if c.startswith("oh__prev_mastery_level__")]
        self.assertEqual(matrix[0, idx].tolist(), [0.0] * 4)

    def test_transform_reads_no_labels(self):
        rows = fx.ladder(n=4)
        fitted = preprocessing.fit(rows)
        before = fitted.transform(rows)
        flipped = [{**r, "is_correct": 1 - r["is_correct"]} for r in rows]
        after = fitted.transform(flipped)
        np.testing.assert_array_equal(before, after)

    def test_deterministic(self):
        rows = fx.ladder(n=6)
        first = preprocessing.fit(rows).transform(rows)
        second = preprocessing.fit(rows).transform(rows)
        np.testing.assert_array_equal(first, second)

    def test_empty_fit_rejected(self):
        with self.assertRaises(ContractViolation):
            preprocessing.fit([])

    def test_imputation_report_documents_rules(self):
        fitted = preprocessing.fit(fx.ladder(n=4))
        report = preprocessing.imputation_report(fitted)
        self.assertIn("train-fold median", report["rule"])
        self.assertEqual(report["n_train_rows"], 4)
        self.assertEqual(len(report["medians"]), 11)


if __name__ == "__main__":
    unittest.main()
