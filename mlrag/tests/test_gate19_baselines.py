"""Gate 19: frozen baseline A/B/C semantics and point-in-time tests."""

from __future__ import annotations

import unittest
from datetime import timedelta

from mlrag.modeling import baselines

from . import gate19_fixtures as fx


def history(outcomes):
    """outcomes: list of (learner, day_offset, topic, correct)."""
    rows = []
    for i, (learner, day, topic, correct) in enumerate(outcomes):
        rows.append(fx.d1_row(
            f"H{i:02d}", learner=learner, topic=topic,
            at=fx.BASE + timedelta(days=day), correct=correct))
    return rows


class BaselineATest(unittest.TestCase):
    def test_majority_is_train_rate(self):
        rows = history([("learner_A", 0, "topic_T1", 1),
                        ("learner_A", 1, "topic_T1", 1),
                        ("learner_A", 2, "topic_T1", 0),
                        ("learner_B", 0, "topic_T1", 0)])
        self.assertAlmostEqual(baselines.fit_global_rate(rows), 0.5)
        self.assertAlmostEqual(baselines.predict_a(0.5), 0.5)

    def test_empty_train_raises(self):
        with self.assertRaises(ValueError):
            baselines.fit_global_rate([])

    def test_val_labels_never_used(self):
        train = history([("learner_A", 0, "topic_T1", 1),
                         ("learner_A", 1, "topic_T1", 0)])
        rate = baselines.fit_global_rate(train)
        self.assertAlmostEqual(baselines.predict_a(rate), 0.5)


class BaselineBTest(unittest.TestCase):
    def test_learner_history_strict_past(self):
        rows = history([("learner_A", 0, "topic_T1", 1),
                        ("learner_A", 1, "topic_T2", 1),
                        ("learner_A", 2, "topic_T1", 0)])
        target = rows[2]
        self.assertAlmostEqual(
            baselines.predict_b(rows, target, 0.25), 1.0)

    def test_current_target_excluded(self):
        rows = history([("learner_A", 0, "topic_T1", 0),
                        ("learner_A", 1, "topic_T1", 0)])
        target = rows[1]
        # Only day-0 (incorrect) is past; current incorrect excluded
        # would give 0.0 either way — use a positive current instead.
        positive_now = dict(target)
        positive_now["is_correct"] = 1
        self.assertAlmostEqual(
            baselines.predict_b(rows, positive_now, 0.9), 0.0)

    def test_future_rows_excluded(self):
        rows = history([("learner_A", 0, "topic_T1", 0),
                        ("learner_A", 5, "topic_T1", 1)])
        target = rows[0]
        self.assertAlmostEqual(
            baselines.predict_b(rows, target, 0.9), 0.9)

    def test_other_learners_ignored(self):
        rows = history([("learner_A", 0, "topic_T1", 0),
                        ("learner_B", 0, "topic_T1", 1),
                        ("learner_B", 1, "topic_T1", 1)])
        target = [r for r in rows if r["learner_key"] == "learner_B"][-1]
        self.assertAlmostEqual(
            baselines.predict_b(rows, target, 0.0), 1.0)

    def test_no_past_falls_back_to_train_rate(self):
        rows = history([("learner_A", 0, "topic_T1", 1)])
        self.assertAlmostEqual(
            baselines.predict_b(rows, rows[0], 0.33), 0.33)


class BaselineCTest(unittest.TestCase):
    def test_topic_history_used_when_sufficient(self):
        rows = history([("learner_A", 0, "topic_T1", 1),
                        ("learner_A", 1, "topic_T1", 0),
                        ("learner_A", 2, "topic_T2", 1),
                        ("learner_A", 3, "topic_T1", 0)])
        target = rows[3]
        # Two past topic rows: 1 correct / 2.
        self.assertAlmostEqual(
            baselines.predict_c(rows, target, 0.0), 0.5)

    def test_falls_back_to_learner_history(self):
        rows = history([("learner_A", 0, "topic_T1", 1),
                        ("learner_A", 1, "topic_T2", 0),
                        ("learner_A", 2, "topic_T1", 0)])
        target = rows[2]
        # Only one past topic row -> B: learner past = 1/2.
        self.assertAlmostEqual(
            baselines.predict_c(rows, target, 0.0), 0.5)

    def test_falls_back_to_train_rate(self):
        rows = history([("learner_A", 0, "topic_T1", 1)])
        self.assertAlmostEqual(
            baselines.predict_c(rows, rows[0], 0.77), 0.77)

    def test_registry_documents_all_three(self):
        described = baselines.describe()
        self.assertEqual(set(described), {"A", "B", "C"})


if __name__ == "__main__":
    unittest.main()
