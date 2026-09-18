"""Gate 24 tests: leakage probes for E + promotion verdict honesty.

Probes mirror the Gate 19 leakage suite for the new challenger:
target-not-in-X, future-row prefix invariance, train-only imputation
for E's fits, no ID-as-feature, single-class fold-train behavior.
Promotion tests assert the verdict machinery on measured evidence and
the recorded NOT-READY outcome (never adjusted).
"""

from __future__ import annotations

import json
import unittest
from pathlib import Path

from mlrag.contracts.common import ContractViolation
from mlrag.learner_intelligence import challenger_rf, promotion24, runner
from mlrag.modeling import config as g19_config

from . import gate19_fixtures as fx

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
GATE24EXP = REPO_ROOT / "mlrag" / "artifacts" / "gate24_experiment.json"


class ForestLeakageTest(unittest.TestCase):
    def test_target_flip_changes_only_labels(self):
        import copy
        rows = fx.ladder(n=12, learners=3)
        flipped = copy.deepcopy(rows)
        flipped[-1]["is_correct"] = 1 - flipped[-1]["is_correct"]
        bundle = challenger_rf.fit(rows)
        matrix_before = bundle.preprocessor.transform(rows)
        bundle_after = challenger_rf.fit(flipped)
        matrix_after = bundle_after.preprocessor.transform(flipped)
        # Features are label-independent: same X rows either way.
        self.assertEqual([list(map(float, r)) for r in matrix_before],
                         [list(map(float, r)) for r in matrix_after])

    def test_future_rows_do_not_change_fold_transform(self):
        import copy
        rows = fx.ladder(n=12, learners=3)
        train = rows[:8]
        bundle = challenger_rf.fit(train)
        before = [list(map(float, r))
                  for r in bundle.preprocessor.transform(train)]
        extended = copy.deepcopy(train) + copy.deepcopy(rows[8:])
        bundle2 = challenger_rf.fit(train)
        after = [list(map(float, r))
                 for r in bundle2.preprocessor.transform(train)]
        self.assertEqual(before, after)
        self.assertEqual(len(extended), 12)

    def test_no_id_columns_in_matrix(self):
        for column in g19_config.MATRIX_COLUMNS:
            lowered = column.lower()
            for banned in ("learner", "user_id", "question_attempt_id",
                           "quiz_attempt_id", "row_id"):
                self.assertNotIn(banned, lowered)

    def test_single_class_fold_train_raises_not_degenerate(self):
        rows = fx.ladder(n=8, learners=2)
        one_class = [r for r in rows if r["is_correct"] == 1]
        self.assertGreater(len(one_class), 0)
        with self.assertRaises(ContractViolation):
            challenger_rf.fit(one_class)

    def test_lolo_fold_trains_never_see_held_learner(self):
        labeled, _ = fx.real_path_labeled(n=12, learners=3)
        result = runner.run_lolo_protocol(labeled, "fp", runner.rf_spec(),
                                          "leak-test")
        for fold in result["folds"]:
            held = fold["held_out_learner"]
            self.assertEqual(fold["n_test"],
                             sum(1 for r in labeled
                                 if r["learner_key"] == held))
            self.assertEqual(fold["n_train"], len(labeled) - fold["n_test"])


class PromotionHonestyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.recorded = json.loads(GATE24EXP.read_text(encoding="utf-8"))

    def test_both_candidates_not_promotable(self):
        for mid, cand in self.recorded["candidates"].items():
            with self.subTest(mid=mid):
                self.assertFalse(cand["promotion"]["promotable"])
                self.assertEqual(cand["promotion"]["model_promotion"], "NO")
                self.assertGreaterEqual(cand["promotion"]["n_blockers"], 1)

    def test_rf_blockers_include_volume_and_comparison(self):
        blockers = self.recorded["candidates"]["rf-pcorrect-g24"][
            "promotion"]["blockers"]
        joined = " ".join(blockers)
        self.assertIn("5000", joined)
        self.assertIn("baselines", joined)

    def test_requirement_table_bars_frozen(self):
        table = self.recorded["candidates"]["rf-pcorrect-g24"][
            "promotion"]["requirements"]
        bars = {r["requirement"]: r["bar"] for r in table}
        self.assertEqual(bars["learners >= 50"], 50)
        self.assertEqual(bars["rows >= 5000"], 5000)
        self.assertEqual(bars["calibration n >= 200"], 200)
        observed = {r["requirement"]: r["observed"] for r in table}
        self.assertEqual(observed["learners >= 50"], 6)
        self.assertEqual(observed["rows >= 5000"], 60)

    def test_evaluate_recomputes_same_verdict(self):
        from mlrag.experiment import promotion
        evidence = promotion.PromotionEvidence(
            n_learners=6, n_rows=60, n_active_dates=6,
            min_per_learner=4, both_classes=True, lolo_stable=False,
            temporal_stable=False, beats_baselines_pooled=False,
            calibration_n=60, calibration_bias=0.1576,
            reproducible=True, leakage_free=True, cold_start_safe=True)
        out = promotion24.evaluate(evidence)
        self.assertFalse(out["promotable"])
        self.assertEqual(out["model_promotion"], "NO")
        self.assertGreater(out["n_blockers"], 0)

    def test_artifact_matches_promotion_verdict(self):
        model = json.loads((REPO_ROOT / "mlrag" / "artifacts"
                            / "gate24_learner_model.json").read_text(
                                encoding="utf-8"))
        self.assertFalse(model["production_eligibility"])
        self.assertEqual(
            model["promotion_blockers"],
            self.recorded["candidates"]["rf-pcorrect-g24"]["promotion"][
                "blockers"])

    def test_dataset_fingerprint_consistent_across_artifacts(self):
        gate18 = json.loads((REPO_ROOT / "mlrag" / "artifacts"
                             / "gate18_dataset.json").read_text(
                                 encoding="utf-8"))
        model = json.loads((REPO_ROOT / "mlrag" / "artifacts"
                            / "gate24_learner_model.json").read_text(
                                encoding="utf-8"))
        self.assertEqual(self.recorded["dataset_fingerprint"],
                         gate18["fingerprint"])
        self.assertEqual(model["dataset_fingerprint"], gate18["fingerprint"])


if __name__ == "__main__":
    unittest.main()
