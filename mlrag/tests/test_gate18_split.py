"""Gate 18: deterministic split, temporal/user isolation, leakage probes."""

from __future__ import annotations

import inspect
import unittest

from mlrag.contracts.common import ContractViolation
from mlrag.dataset.build import build_dataset
from mlrag.dataset.contract import TARGET_COLUMN
from mlrag.dataset.split import (
    STRATEGY,
    TRAIN_FRAC,
    VAL_FRAC,
    apply_assignment,
    assign_splits,
)
from mlrag.feature_pipeline.builder import build_feature_table
from mlrag.feature_pipeline.contract import FEATURE_COLUMNS

from . import gate17_fixtures as fx


def labeled(n=12, learners=4, **kw):
    outs = [
        fx.outcome(
            f"qa{i:02d}", f"qz{i % 3}", learner=f"learner_{i % learners}",
            at=fx.at_days(i), correct=bool((i + 1) % 2), **kw
        )
        for i in range(n)
    ]
    build = build_feature_table(fx.tables(outs))
    assert not build["rejections"], build["rejections"]
    dataset = build_dataset(build["rows"])
    split = assign_splits(dataset["rows"])
    return dataset, split, apply_assignment(dataset["rows"],
                                            split["assignment"])


class SplitMechanismTest(unittest.TestCase):
    def test_strategy_and_fractions(self):
        self.assertEqual(STRATEGY, "user_aware_time_aware")
        self.assertEqual((TRAIN_FRAC, VAL_FRAC), (0.70, 0.15))

    def test_every_row_labeled_valid_split(self):
        dataset, split, rows = labeled()
        self.assertEqual(len(split["assignment"]), len(dataset["rows"]))
        for row in rows:
            self.assertIn(row["split"], ("train", "validation", "test"))
        from mlrag.dataset.quality import split_audit
        audit = split_audit(rows, split["metadata"])
        self.assertTrue(audit["split_pass"])
        self.assertEqual(audit["unlabeled_row_count"], 0)

    def test_user_isolation_absolute(self):
        _, split, rows = labeled(n=12, learners=4)
        seen: dict[str, set[str]] = {}
        for row in rows:
            seen.setdefault(row["learner_key"], set()).add(row["split"])
        for learner, splits in seen.items():
            self.assertEqual(len(splits), 1, learner)
        # Learner-level map agrees with row-level map.
        for row in rows:
            self.assertEqual(split["learner_split"][row["learner_key"]],
                             row["split"])

    def test_first_activity_order_preserved(self):
        _, split, _ = labeled(n=12, learners=4)
        self.assertTrue(
            split["metadata"]["learner_first_activity_order_preserved"]
        )

    def test_same_T_siblings_colocated(self):
        outs = [
            fx.outcome("qaA", "qz1", learner="learner_9", at=fx.BASE,
                       correct=True),
            fx.outcome("qaB", "qz1", learner="learner_9", at=fx.BASE,
                       correct=False),
            fx.outcome("qaC", "qz2", learner="learner_9", at=fx.at_days(1),
                       correct=True),
        ] + [
            fx.outcome(f"qa{i:02d}", f"qz{i}", learner="learner_8",
                       at=fx.at_days(2 + i), correct=bool(i % 2))
            for i in range(4)
        ]
        build = build_feature_table(fx.tables(outs))
        dataset = build_dataset(build["rows"])
        split = assign_splits(dataset["rows"])
        rows = apply_assignment(dataset["rows"], split["assignment"])
        siblings = {r["split"] for r in rows
                    if r["question_attempt_id"] in ("qaA", "qaB")}
        self.assertEqual(len(siblings), 1)

    def test_deterministic_repeated_calls(self):
        dataset, first, _ = labeled()
        second = assign_splits(dataset["rows"])
        self.assertEqual(first["assignment"], second["assignment"])
        self.assertEqual(first["metadata"], second["metadata"])

    def test_no_randomness_in_split_module(self):
        import mlrag.dataset.split as split_module
        source = inspect.getsource(split_module)
        self.assertNotIn("import random", source)
        self.assertNotIn("random.", source)
        self.assertNotIn("np.random", source)

    def test_targets_do_not_influence_assignment(self):
        outs = [
            fx.outcome(f"qa{i:02d}", f"qz{i % 2}", learner=f"learner_{i % 3}",
                       at=fx.at_days(i), correct=True)
            for i in range(9)
        ]
        build = build_feature_table(fx.tables(outs))
        dataset = build_dataset(build["rows"])
        before = assign_splits(dataset["rows"])["assignment"]
        flipped = [{**r, TARGET_COLUMN: 1 - r[TARGET_COLUMN]}
                   for r in dataset["rows"]]
        after = assign_splits(flipped)["assignment"]
        self.assertEqual(before, after)

    def test_future_rows_do_not_change_prefix_X(self):
        prefix = [
            fx.outcome(f"qa{i:02d}", "qz0", learner="learner_0",
                       at=fx.at_days(i), correct=bool(i % 2))
            for i in range(4)
        ]
        build = build_feature_table(fx.tables(prefix))
        first = build_dataset(build["rows"])
        extended = prefix + [
            fx.outcome("qaF", "qzF", learner="learner_Z",
                       at=fx.at_days(99), correct=True)
        ]
        build2 = build_feature_table(fx.tables(extended))
        second = build_dataset(build2["rows"])
        first_x = {r["row_id"]: r["features"] for r in first["rows"]}
        second_x = {r["row_id"]: r["features"] for r in second["rows"]}
        for row_id, features in first_x.items():
            # Future rows cannot alter already-built feature vectors.
            self.assertEqual(features, second_x[row_id])
        # Split assignment is a pure deterministic function of its input.
        self.assertEqual(
            assign_splits(second["rows"])["assignment"],
            assign_splits(second["rows"])["assignment"],
        )

    def test_temporal_overlap_reported_not_forced(self):
        # Interleaved learners: train learner active after a val learner
        # starts -> overlap must be REPORTED, rows must NOT be dropped.
        outs = [
            fx.outcome("qa00", "qz0", learner="learner_A",
                       at=fx.at_days(0), correct=True),
            fx.outcome("qa01", "qz0", learner="learner_B",
                       at=fx.at_days(1), correct=False),
            fx.outcome("qa02", "qz0", learner="learner_A",
                       at=fx.at_days(10), correct=True),
        ] + [
            fx.outcome(f"qa{i:02d}", "qz0", learner=f"learner_C{i}",
                       at=fx.at_days(2 + i), correct=bool(i % 2))
            for i in range(3, 12)
        ]
        build = build_feature_table(fx.tables(outs))
        dataset = build_dataset(build["rows"])
        split = assign_splits(dataset["rows"])
        rows = apply_assignment(dataset["rows"], split["assignment"])
        # No rows lost, every row labeled.
        self.assertEqual(len(rows), len(dataset["rows"]))
        self.assertIn("overlap_train_validation", split["metadata"])

    def test_split_policy_record_conforms(self):
        _, split, _ = labeled(n=12, learners=4)
        policy = split["metadata"]["split_policy"]
        if policy["constructed"]:
            self.assertEqual(policy["strategy"], "user_aware_time_aware")
            self.assertTrue(policy["user_isolation"])
            self.assertLess(policy["training_end_iso"],
                            policy["validation_end_iso"])
        else:
            self.assertIn("reason", policy)

    def test_invalid_fractions_rejected(self):
        dataset, _, _ = labeled(n=6, learners=2)
        with self.assertRaises(ContractViolation):
            assign_splits(dataset["rows"], train_frac=0.0)
        with self.assertRaises(ContractViolation):
            assign_splits(dataset["rows"], train_frac=0.8, val_frac=0.2)

    def test_empty_split_honesty(self):
        # Tiny input: mechanism still runs; usability verdicts say NO.
        dataset, split, rows = labeled(n=3, learners=3)
        self.assertEqual(len(rows), 3)
        usable = [split["metadata"]["per_split"][n]["usable"]
                  for n in ("train", "validation", "test")]
        self.assertFalse(all(usable))
        self.assertFalse(split["metadata"]["all_splits_usable"])


class SplitLeakageProbeTest(unittest.TestCase):
    def test_target_not_in_X_after_split(self):
        _, _, rows = labeled()
        for row in rows:
            self.assertEqual(set(row["features"].keys()),
                             set(FEATURE_COLUMNS))
            self.assertNotIn(TARGET_COLUMN, row["features"])

    def test_flipping_last_target_leaves_all_X_untouched(self):
        # Flipping ONLY the terminal row's label touches no prior, so every
        # feature vector must be byte-identical (current label never in X).
        # (Flipping a non-terminal label LEGITIMATELY changes later rows'
        # history aggregates — prior labels are admissible history.)
        def run(last_correct):
            outs = [
                fx.outcome(f"qa{i:02d}", f"qz{i}",
                           learner=f"learner_{i % 2}", at=fx.at_days(i),
                           correct=(True if i < 5 else last_correct))
                for i in range(6)
            ]
            build = build_feature_table(fx.tables(outs))
            dataset = build_dataset(build["rows"])
            rows = apply_assignment(
                dataset["rows"],
                assign_splits(dataset["rows"])["assignment"])
            return rows
        rows_true = run(True)
        rows_false = run(False)
        self.assertEqual([r["features"] for r in rows_true],
                         [r["features"] for r in rows_false])
        self.assertEqual([r[TARGET_COLUMN] for r in rows_true],
                         [1] * 5 + [1])
        self.assertEqual([r[TARGET_COLUMN] for r in rows_false],
                         [1] * 5 + [0])


if __name__ == "__main__":
    unittest.main()
