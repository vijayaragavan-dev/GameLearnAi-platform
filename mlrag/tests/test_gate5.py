"""Gate 5 hardening tests (coverage, sufficiency, comparison, calibration,
promotion).  Standard library + numpy/sklearn only.  All learner-like rows
are hand-built SYNTHETIC fixtures — never real learner data.  No database,
no network, no services.

Run: python -m unittest mlrag.tests.test_gate5 -v
"""

from __future__ import annotations

import unittest

from mlrag.experiment import (baselines, calibration, comparison, coverage,
                              evaluate, features, model, promotion,
                              sufficiency)
from mlrag.experiment.run_experiment import _beats_all, _promotion_evidence


def synth_row(learner: str, day: int, correct: bool, attempt_no: int,
              topic: str = "T1") -> dict:
    import datetime
    return {
        "question_attempt_id": f"syn-{attempt_no}",
        "quiz_attempt_id": f"syn-qz-{attempt_no}",
        "question_id": f"syn-q-{attempt_no}",
        "is_correct": correct,
        "learner_key": learner,
        "topic_id": topic,
        "subject_id": "S1",
        "question_difficulty": "EASY",
        "quiz_difficulty": "EASY",
        "difficulty_at_attempt": "EASY",
        "submitted_at": datetime.datetime(2026, 9, day, 10, 0, 0),
    }


def two_learner_rows() -> list[dict]:
    rows = []
    n = 0
    for learner in ("LA", "LB"):
        for day in (1, 2, 3, 4):
            n += 1
            rows.append(synth_row(learner, day, (n % 3) != 0, n))
    return features.build_rows(rows, [], [])


class CoverageTest(unittest.TestCase):
    def test_reports_counts_and_percentages(self):
        rows = two_learner_rows()
        report = coverage.feature_coverage(rows)
        self.assertEqual(report["n_rows"], 8)
        cold = report["columns"]["hist_accuracy"]
        self.assertEqual(cold["total"], 8)
        self.assertEqual(cold["non_null"] + cold["missing"], 8)
        self.assertAlmostEqual(
            cold["coverage_pct"], 100.0 * cold["non_null"] / 8)
        # Flags are always present; history-backed numerics are not.
        self.assertEqual(
            report["columns"]["is_cold_start"]["coverage_pct"], 100.0)
        self.assertLess(
            report["columns"]["hist_accuracy"]["coverage_pct"], 100.0)

    def test_empty_row_set(self):
        report = coverage.feature_coverage([])
        self.assertEqual(report["n_rows"], 0)
        self.assertEqual(report["columns"]["hist_accuracy"]["coverage_pct"],
                         0.0)

    def test_no_values_changed(self):
        rows = two_learner_rows()
        before = [dict(r) for r in rows]
        coverage.feature_coverage(rows)
        self.assertEqual(rows, before)


class SufficiencyTest(unittest.TestCase):
    def test_feasibility_tier(self):
        result = sufficiency.assess_sufficiency(two_learner_rows())
        self.assertEqual(result["tier"], sufficiency.TIER_FEASIBILITY)
        self.assertEqual(result["blockers"], [])
        self.assertEqual(result["facts"]["n_learners"], 2)
        self.assertTrue(result["facts"]["both_classes"])

    def test_impossible_single_learner(self):
        rows = features.build_rows(
            [synth_row("LONE", 1, True, 1), synth_row("LONE", 2, False, 2)],
            [], [])
        result = sufficiency.assess_sufficiency(rows)
        self.assertEqual(result["tier"], sufficiency.TIER_IMPOSSIBLE)
        self.assertTrue(any("learner" in b for b in result["blockers"]))

    def test_impossible_single_class(self):
        rows = features.build_rows(
            [synth_row("LA", 1, True, 1), synth_row("LB", 2, True, 2)], [], [])
        result = sufficiency.assess_sufficiency(rows)
        self.assertEqual(result["tier"], sufficiency.TIER_IMPOSSIBLE)

    def test_impossible_single_day(self):
        rows = features.build_rows(
            [synth_row("LA", 1, True, 1), synth_row("LB", 1, False, 2)], [], [])
        result = sufficiency.assess_sufficiency(rows)
        self.assertEqual(result["tier"], sufficiency.TIER_IMPOSSIBLE)


class ComparisonTest(unittest.TestCase):
    def _scored(self) -> dict:
        rows = two_learner_rows()
        rate = baselines.fit_global_rate(rows)
        probs = {
            key: [baselines.predict_b(rows, r, rate) for r in rows]
            for key in ("A", "B", "C")}
        bundle = model.fit(rows)
        probs["model"] = model.predict_proba(bundle, rows)
        y_true = [1 if r["label"] else 0 for r in rows]
        return {k: evaluate.score_set(y_true, v) for k, v in probs.items()}

    def test_structure_and_no_accuracy_decision(self):
        result = comparison.compare_methods(self._scored())
        self.assertEqual(set(result),
                         {"log_loss", "brier", "roc_auc", "pr_auc"})
        for metric, entry in result.items():
            self.assertIn("improves_over_all", entry)
            self.assertEqual(set(entry["vs_baselines"]), {"A", "B", "C"})

    def test_insufficient_evidence_when_metric_missing(self):
        scored = self._scored()
        scored["model"]["roc_auc"] = None
        result = comparison.compare_methods(scored)
        for base in ("A", "B", "C"):
            entry = result["roc_auc"]["vs_baselines"][base]
            self.assertIsNone(entry["improves"])
            self.assertEqual(entry["evidence"], "insufficient_evidence")
        self.assertIsNone(result["roc_auc"]["improves_over_all"])

    def test_delta_direction(self):
        scored = {"model": {"log_loss": 0.5, "brier": 0.2,
                            "roc_auc": 0.7, "pr_auc": 0.6},
                  "A": {"log_loss": 0.6, "brier": 0.25,
                        "roc_auc": 0.5, "pr_auc": 0.5},
                  "B": {"log_loss": 0.6, "brier": 0.25,
                        "roc_auc": 0.5, "pr_auc": 0.5},
                  "C": {"log_loss": 0.6, "brier": 0.25,
                        "roc_auc": 0.5, "pr_auc": 0.5}}
        result = comparison.compare_methods(scored)
        self.assertTrue(result["log_loss"]["improves_over_all"])
        self.assertTrue(result["roc_auc"]["improves_over_all"])


class CalibrationSummaryTest(unittest.TestCase):
    def test_bias_and_direction(self):
        table = evaluate.calibration_table(
            [1, 0, 0, 0], [0.9, 0.8, 0.7, 0.6])
        summary = calibration.summarize_calibration(table)
        self.assertEqual(summary["total_n"], 4)
        self.assertAlmostEqual(summary["overall_bias"], 0.5)
        self.assertEqual(summary["overall_direction"], "overconfident")
        self.assertFalse(summary["sufficient_sample"])

    def test_empty_bins_unknown(self):
        table = evaluate.calibration_table([1], [0.9])
        summary = calibration.summarize_calibration(table)
        empty = [b for b in summary["bins"] if b["n"] == 0]
        self.assertTrue(empty)
        self.assertTrue(all(b["direction"] == "unknown" for b in empty))


class PromotionPolicyTest(unittest.TestCase):
    def _evidence(self, **overrides) -> promotion.PromotionEvidence:
        base = {
            "n_learners": 60, "n_rows": 6000, "n_active_dates": 90,
            "min_per_learner": 20, "both_classes": True,
            "lolo_stable": True, "temporal_stable": True,
            "beats_baselines_pooled": True, "calibration_n": 500,
            "calibration_bias": 0.02, "reproducible": True,
            "leakage_free": True, "cold_start_safe": True,
        }
        base.update(overrides)
        return promotion.PromotionEvidence(**base)

    def test_promotable_when_all_requirements_met(self):
        verdict = promotion.assess(self._evidence())
        self.assertTrue(verdict.promotable)
        self.assertEqual(verdict.reasons, ())

    def test_tiny_data_blocked_with_reasons(self):
        verdict = promotion.assess(self._evidence(
            n_learners=5, n_rows=56, n_active_dates=5, min_per_learner=2,
            lolo_stable=False, temporal_stable=False,
            beats_baselines_pooled=False, calibration_n=56,
            calibration_bias=0.2))
        self.assertFalse(verdict.promotable)
        self.assertGreater(len(verdict.reasons), 5)

    def test_single_blocker_blocks(self):
        verdict = promotion.assess(self._evidence(leakage_free=False))
        self.assertFalse(verdict.promotable)
        self.assertTrue(any("leakage" in r for r in verdict.reasons))

    def test_thresholds_labeled_provisional(self):
        self.assertTrue(promotion.PROVISIONAL_MIN_LEARNERS > 5)
        self.assertTrue(promotion.PROVISIONAL_MIN_ROWS > 56)


class RunnerIntegrationTest(unittest.TestCase):
    def test_promotion_evidence_assembles(self):
        rows = two_learner_rows()
        lolo = evaluate.leave_one_learner_out(rows)
        temporal = evaluate.temporal_holdout(rows)
        suff = sufficiency.assess_sufficiency(rows)
        evidence = _promotion_evidence(rows, suff, lolo, temporal)
        self.assertEqual(evidence.n_rows, 8)
        verdict = promotion.assess(evidence)
        self.assertFalse(verdict.promotable)  # tiny synthetic data

    def test_beats_all_none_safe(self):
        pool = {"model": {"log_loss": None},
                "A": {"log_loss": 0.6}, "B": {"log_loss": 0.6},
                "C": {"log_loss": 0.6}}
        self.assertFalse(_beats_all(pool, "log_loss"))


if __name__ == "__main__":
    unittest.main()
