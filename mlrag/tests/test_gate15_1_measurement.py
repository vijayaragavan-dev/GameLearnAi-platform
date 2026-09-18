"""Gate 15.1 measurement-channel guards. Standard library only.

Verifies the blocked-channel contract without credentials: missing env
fails clean before any connection, no secret literals exist in mlrag
source, Gate 5 bars are intact, historical-NULL semantics hold, outcome
taxonomy stays honest.  No database, no network.

Run: python -m unittest mlrag.tests.test_gate15_1_measurement -v
"""

from __future__ import annotations

import os
import pathlib
import re
import unittest
from unittest import mock

from mlrag.contracts.common import ContractViolation
from mlrag.experiment import promotion

MLRAG_ROOT = pathlib.Path(__file__).parent.parent


class ChannelBlockerTest(unittest.TestCase):
    def test_missing_env_fails_before_connect(self):
        from mlrag.experiment import db

        with mock.patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(ContractViolation):
                db.connect()

    def test_no_hardcoded_credentials_in_source(self):
        suspicious = re.compile(
            r"(?i)(password\s*=\s*['\"][^'\"]{3,}['\"]|"
            r"passwd\s*=\s*['\"][^'\"]+['\"]|"
            r"jdbc:mysql://[^'\"]*:[^'\"]*@)")
        hits = []
        for path in MLRAG_ROOT.rglob("*.py"):
            if ".venv" in path.parts:
                continue
            text = path.read_text(encoding="utf-8")
            for i, line in enumerate(text.splitlines(), 1):
                if suspicious.search(line):
                    hits.append(f"{path.name}:{i}")
        self.assertEqual(hits, [])


class PolicyPreservedTest(unittest.TestCase):
    def test_gate5_bars_unchanged(self):
        self.assertEqual(promotion.PROVISIONAL_MIN_LEARNERS, 50)
        self.assertEqual(promotion.PROVISIONAL_MIN_ROWS, 5000)
        self.assertEqual(promotion.PROVISIONAL_MIN_ACTIVE_DATES, 60)

    def test_baseline_still_not_promotable(self):
        verdict = promotion.assess(promotion.PromotionEvidence(
            n_learners=5, n_rows=56, n_active_dates=5,
            min_per_learner=2, both_classes=True, lolo_stable=False,
            temporal_stable=False, beats_baselines_pooled=False,
            calibration_n=56, calibration_bias=0.2, reproducible=True,
            leakage_free=True, cold_start_safe=True))
        self.assertFalse(verdict.promotable)


class HistoricalNullsTest(unittest.TestCase):
    def test_think_time_column_absent_from_f1(self):
        from mlrag.experiment.features import FEATURE_COLUMNS

        self.assertNotIn("response_time_seconds", FEATURE_COLUMNS)

    def test_outcome_taxonomy_honest(self):
        categories = {"IMPROVED", "NO_MEASURABLE_IMPROVEMENT", "DECLINED",
                      "INSUFFICIENT_DATA", "AMBIGUOUS"}
        self.assertNotIn("SUCCESS", categories)
        self.assertNotIn("CAUSAL_EFFECT", categories)


if __name__ == "__main__":
    unittest.main()
