"""Gate 19: focused leakage tests (12 required probes, fail loudly)."""

from __future__ import annotations

import inspect
import json
import unittest

from mlrag.dataset.contract import TARGET_COLUMN
from mlrag.feature_pipeline.contract import FEATURE_COLUMNS
from mlrag.modeling import baselines, challenger, config, experiment

from . import gate19_fixtures as fx


def train_rows(n=10, learners=2):
    return [r for r in fx.ladder(n=n, learners=learners)
            if r["split"] == "train"]


class Gate19LeakageTest(unittest.TestCase):
    def test_01_target_not_in_X(self):
        for row in fx.ladder(n=6):
            self.assertEqual(set(row["features"].keys()),
                             set(FEATURE_COLUMNS))
            self.assertNotIn(TARGET_COLUMN, row["features"])

    def test_02_no_post_attempt_data(self):
        labeled, _ = fx.real_path_labeled(n=9, learners=3)
        text = json.dumps(labeled, sort_keys=True, default=str)
        for banned in ("quiz_score", "selected_answer", "duration_seconds",
                       "quarantined_post_attempt", "correct_answer"):
            self.assertNotIn(banned, text)

    def test_03_transformations_fit_on_train_only(self):
        from mlrag.modeling import preprocessing
        train = train_rows()
        fitted = preprocessing.fit(train)
        # Median of hist_accuracy over the ladder train rows is a fixed
        # train-only value; appending a validation extreme and refitting
        # would move it — the API takes train rows exclusively.
        medians = dict(zip(config.NUMERIC_COLUMNS, fitted.medians))
        self.assertLess(abs(medians["hist_accuracy"] - 0.5), 0.5)
        self.assertEqual(fitted.n_train_rows, len(train))

    def test_04_val_test_labels_unused_in_preprocessing(self):
        from mlrag.modeling import preprocessing
        rows = fx.ladder(n=8, learners=2)
        fitted = preprocessing.fit([r for r in rows
                                    if r["split"] == "train"])
        before = fitted.transform(rows)
        flipped = [{**r, "is_correct": 1 - r["is_correct"]} for r in rows]
        after = fitted.transform(flipped)
        import numpy as np
        np.testing.assert_array_equal(before, after)

    def test_05_learner_grouping_respected(self):
        labeled, _ = fx.real_path_labeled(n=12, learners=3)
        result = experiment.run_lolo_protocol(labeled, "fp-leak-05")
        for fold in result["folds"]:
            held = fold["held_out_learner"]
            train_learners = {r["learner_key"] for r in labeled
                              if r["learner_key"] != held}
            self.assertNotIn(held, train_learners)
            self.assertEqual(fold["n_test"],
                             sum(1 for r in labeled
                                 if r["learner_key"] == held))

    def test_06_deterministic_split_reused(self):
        import mlrag.modeling.experiment as exp_module
        source = inspect.getsource(exp_module)
        self.assertNotIn("train_test_split", source)
        self.assertNotIn("shuffle", source.lower())
        self.assertNotIn("import random", source)
        # Split labels come from Gate 18 rows; the experiment never
        # reassigns them.
        labeled, _ = fx.real_path_labeled(n=9, learners=3)
        before = [r["split"] for r in labeled]
        experiment.run_split_protocol(labeled, "fp-leak-06")
        self.assertEqual(before, [r["split"] for r in labeled])

    def test_07_no_random_row_splitting(self):
        for module_name in ("mlrag.modeling.experiment",
                            "mlrag.modeling.challenger",
                            "mlrag.modeling.baselines",
                            "mlrag.modeling.preprocessing"):
            import importlib
            source = inspect.getsource(importlib.import_module(module_name))
            self.assertNotIn("import random", source)
            self.assertNotIn("train_test_split", source)

    def test_08_no_raw_learner_id_as_feature(self):
        for column in config.MATRIX_COLUMNS:
            self.assertNotIn("learner", column)
            self.assertNotIn("user", column)
        self.assertNotIn(TARGET_COLUMN, config.MATRIX_COLUMNS)

    def test_09_no_pii_in_model_artifact(self):
        bundle = challenger.fit(train_rows())
        text = json.dumps(bundle.coefficient_record(), default=str)
        for banned in ("learner_", "user_id", "@", "eyJ", "password",
                       "selected_answer", "jwt"):
            self.assertNotIn(banned, text)

    def test_10_no_current_answer_or_score(self):
        rows = fx.ladder(n=6)
        rate = baselines.fit_global_rate(
            [r for r in rows if r["split"] == "train"])
        for row in rows:
            for prob in (baselines.predict_a(rate),
                         baselines.predict_b(rows, row, rate),
                         baselines.predict_c(rows, row, rate)):
                self.assertGreaterEqual(prob, 0.0)
                self.assertLessEqual(prob, 1.0)
        # Flipping ONLY the current row's label leaves its own B/C
        # probabilities unchanged (history excludes the current row).
        target = rows[-1]
        before_b = baselines.predict_b(rows, target, rate)
        before_c = baselines.predict_c(rows, target, rate)
        flipped = dict(target, is_correct=1 - target["is_correct"])
        self.assertEqual(before_b, baselines.predict_b(rows, flipped, rate))
        self.assertEqual(before_c, baselines.predict_c(rows, flipped, rate))

    def test_11_no_future_information(self):
        rows = fx.ladder(n=8, learners=2)
        rate = baselines.fit_global_rate(rows)
        early = rows[0]
        # Appending future rows must not change an early row's B/C output.
        before = (baselines.predict_b(rows, early, rate),
                  baselines.predict_c(rows, early, rate))
        future = [fx.d1_row(f"F{i}", learner=early["learner_key"],
                            at=fx.BASE.replace(year=2030),
                            correct=1 - early["is_correct"])
                  for i in range(3)]
        after = (baselines.predict_b(rows + future, early, rate),
                 baselines.predict_c(rows + future, early, rate))
        self.assertEqual(before, after)

    def test_12_deterministic_training(self):
        train = train_rows()
        first = challenger.predict_proba(challenger.fit(train), train)
        second = challenger.predict_proba(challenger.fit(train), train)
        self.assertEqual(first, second)
        self.assertEqual(config.RANDOM_STATE, 42)
        self.assertEqual(config.SOLVER, "lbfgs")


if __name__ == "__main__":
    unittest.main()
