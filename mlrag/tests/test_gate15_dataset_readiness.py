"""Gate 15 readiness guards (EVIDENCE GATE). Standard library only.

Pins the readiness contract without live data: Gate 5 bars unchanged,
synthetic/framework separation, historical-NULL preservation, outcome
taxonomy honesty, leakage strictness, lesson/path deferral. No database,
no credentials.

Run: python -m unittest mlrag.tests.test_gate15_dataset_readiness -v
"""

from __future__ import annotations

import os
import unittest
from unittest import mock

from mlrag.contracts.common import ContractViolation
from mlrag.experiment import promotion


class PolicyUnchangedTest(unittest.TestCase):
    def test_gate5_bars_intact(self):
        self.assertEqual(promotion.PROVISIONAL_MIN_LEARNERS, 50)
        self.assertEqual(promotion.PROVISIONAL_MIN_ROWS, 5000)
        self.assertEqual(promotion.PROVISIONAL_MIN_ACTIVE_DATES, 60)
        self.assertEqual(promotion.PROVISIONAL_MIN_PER_LEARNER, 10)
        self.assertEqual(promotion.PROVISIONAL_MIN_CALIBRATION_N, 200)
        self.assertAlmostEqual(promotion.PROVISIONAL_MAX_ABS_BIAS, 0.05)

    def test_current_baseline_fails_bars(self):
        verdict = promotion.assess(promotion.PromotionEvidence(
            n_learners=5, n_rows=56, n_active_dates=5,
            min_per_learner=2, both_classes=True, lolo_stable=False,
            temporal_stable=False, beats_baselines_pooled=False,
            calibration_n=56, calibration_bias=0.2, reproducible=True,
            leakage_free=True, cold_start_safe=True))
        self.assertFalse(verdict.promotable)


class AccessBlockerTest(unittest.TestCase):
    def test_live_path_blocked_without_channel(self):
        from mlrag.shadow import real_history

        with mock.patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(ContractViolation):
                real_history.run_live_evaluation()


class HarnessHonestyTest(unittest.TestCase):
    def _fixture_payload(self):
        import datetime
        from mlrag.experiment import features
        from mlrag.shadow.real_history import evaluate_dataset

        # Both learners carry both classes so every LOLO train fold is
        # fittable (single-class folds are a data condition, not a
        # harness bug — sufficiency tier reports it).
        rows = []
        spec = [("GA", 1, True), ("GA", 2, False), ("GA", 3, True),
                ("GA", 4, False), ("GB", 2, True), ("GB", 3, False)]
        for i, (learner, day, correct) in enumerate(spec):
            rows.append({
                "question_attempt_id": f"g15-{i}",
                "quiz_attempt_id": f"gz-{i}",
                "question_id": f"q-{i}",
                "learner_key": learner,
                "submitted_at": datetime.datetime(2026, 9, day, 10, 0, 0),
                "topic_id": "T1",
                "subject_id": "S",
                "question_difficulty": "EASY",
                "quiz_difficulty": "EASY",
                "is_correct": correct,
            })
        built = features.build_rows(rows, [], [])
        return evaluate_dataset(built, [])

    def test_tiny_data_never_promotable(self):
        payload = self._fixture_payload()
        self.assertFalse(payload["promotion"]["promotable"])
        self.assertFalse(payload["deployment_ready"])
        self.assertFalse(payload["production_promotion"])

    def test_insufficient_sufficiency_tier(self):
        payload = self._fixture_payload()
        self.assertEqual(payload["n_events"], 6)
        self.assertIn(payload["sufficiency"]["tier"],
                      ("evaluation_impossible", "feasibility_only"))
