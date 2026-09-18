"""Gate 24 tests: serving contract, fallback gates, e2e scenarios.

No database.  The fixture-eligible artifact is a hand-built TEST-ONLY
record (never from training, never near real data) used solely to prove
the serving machinery; the REAL committed artifact is asserted dormant.
Covers scenarios 1–6 and fallback reasons end to end.
"""

from __future__ import annotations

import json
import tempfile
import time
import unittest
from pathlib import Path

from mlrag.contracts.common import ContractViolation
from mlrag.learner_intelligence import artifact as artifact_mod
from mlrag.learner_intelligence import config24, serving
from mlrag.learner_intelligence.serving import (
    Fallback,
    Prediction,
    ServingRequest,
)

from .test_gate24_calibration_artifact import _expected, _minimal_record

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
MODEL_PATH = REPO_ROOT / "mlrag" / "artifacts" / "gate24_learner_model.json"


def _fixture_eligible(tmp: str) -> tuple[Path, dict]:
    """TEST-ONLY eligible record (synthetic, isolated from training)."""
    record = _minimal_record(production_eligibility=True,
                             dataset_fingerprint="fp-fixture")
    path = Path(tmp) / "eligible.json"
    artifact_mod.write_artifact(record, path)
    expected = _expected(fp="fp-fixture")
    return path, expected


def _request(**over):
    base = {"learner_ref": "learner-test-1", "topic_id": "topic-T1",
            "difficulty": "EASY", "history_count": 12,
            "is_cold_start": False, "feature_row": {"f": 1.0}}
    base.update(over)
    return ServingRequest(**base)


class RequestValidationTest(unittest.TestCase):
    def test_blank_identity_rejected(self):
        with self.assertRaises(ContractViolation):
            _request(learner_ref="  ")

    def test_bad_difficulty_rejected(self):
        with self.assertRaises(ContractViolation):
            _request(difficulty="IMPOSSIBLE")

    def test_negative_history_rejected(self):
        with self.assertRaises(ContractViolation):
            _request(history_count=-1)

    def test_empty_feature_row_rejected(self):
        with self.assertRaises(ContractViolation):
            _request(feature_row={})


class FallbackGateTest(unittest.TestCase):
    def test_missing_artifact_unavailable(self):
        result = serving.score(_request(), Path("/no/such/model.json"),
                               _expected(), lambda row: 0.7)
        self.assertIsInstance(result, Fallback)
        self.assertEqual(result.reason, "model_unavailable")

    def test_real_artifact_forces_not_eligible(self):
        record = json.loads(MODEL_PATH.read_text(encoding="utf-8"))
        result = serving.score(
            _request(), MODEL_PATH,
            {"model_id": "rf-pcorrect-g24",
             "model_version": "0.1.0-gate24exp",
             "feature_version": "f1",
             "dataset_fingerprint": record["dataset_fingerprint"]},
            lambda row: 0.7)
        self.assertIsInstance(result, Fallback)
        self.assertEqual(result.reason, "model_not_eligible")

    def test_stale_fingerprint_fallback(self):
        with tempfile.TemporaryDirectory() as tmp:
            path, expected = _fixture_eligible(tmp)
            expected["dataset_fingerprint"] = "fp-drifted"
            result = serving.score(_request(), path, expected,
                                   lambda row: 0.7)
        self.assertEqual(result.reason, "stale_model")

    def test_corrupt_artifact_fallback(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "bad.json"
            path.write_text("{oops", encoding="utf-8")
            result = serving.score(_request(), path, _expected(),
                                   lambda row: 0.7)
        self.assertEqual(result.reason, "corrupt_model")

    def test_cold_start_fallback(self):
        with tempfile.TemporaryDirectory() as tmp:
            path, expected = _fixture_eligible(tmp)
            result = serving.score(
                _request(is_cold_start=True, history_count=0),
                path, expected, lambda row: 0.7)
        self.assertEqual(result.reason, "cold_start")

    def test_insufficient_history_fallback(self):
        with tempfile.TemporaryDirectory() as tmp:
            path, expected = _fixture_eligible(tmp)
            for count in (1, 5, 9):
                result = serving.score(
                    _request(history_count=count), path, expected,
                    lambda row: 0.7)
                self.assertEqual(result.reason, "insufficient_history",
                                 count)
            ok = serving.score(_request(history_count=10), path, expected,
                               lambda row: 0.7)
            self.assertIsInstance(ok, Prediction)

    def test_malformed_probability_fallback(self):
        with tempfile.TemporaryDirectory() as tmp:
            path, expected = _fixture_eligible(tmp)
            for bad in (1.5, -0.1, float("nan")):
                result = serving.score(_request(), path, expected,
                                       lambda row, b=bad: b)
                self.assertEqual(result.reason, "malformed_prediction")
            raising = serving.score(_request(), path, expected,
                                    lambda row: 1 / 0)
            self.assertEqual(raising.reason, "malformed_prediction")

    def test_unbound_predict_fn_fallback(self):
        with tempfile.TemporaryDirectory() as tmp:
            path, expected = _fixture_eligible(tmp)
            result = serving.score(_request(), path, expected, None)
        self.assertEqual(result.reason, "model_unavailable")

    def test_timeout_fallback(self):
        with tempfile.TemporaryDirectory() as tmp:
            path, expected = _fixture_eligible(tmp)

            def slow(row):
                time.sleep(5)
                return 0.7

            result = serving.score_with_deadline(
                _request(), path, expected, slow, timeout_s=0.2)
        self.assertEqual(result.reason, "timeout")

    def test_eligible_path_returns_bounded_prediction(self):
        with tempfile.TemporaryDirectory() as tmp:
            path, expected = _fixture_eligible(tmp)
            result = serving.score(_request(history_count=15), path,
                                   expected, lambda row: 0.7)
        self.assertIsInstance(result, Prediction)
        self.assertEqual(result.probability, 0.7)
        self.assertEqual(result.model_id, "rf-pcorrect-g24")
        self.assertEqual(result.feature_version, "f1")
        self.assertFalse(result.cold_start)
        self.assertEqual(result.history_count, 15)
        self.assertGreaterEqual(result.latency_ms, 0.0)

    def test_client_prediction_cannot_enter(self):
        # Scenario 5: a feature row smuggling predicted_probability is
        # ignored — score() has no probability input; only the bound
        # function output is used.
        with tempfile.TemporaryDirectory() as tmp:
            path, expected = _fixture_eligible(tmp)
            row = {"f": 1.0, "predicted_probability": 1.0}
            result = serving.score(_request(feature_row=row), path,
                                   expected, lambda r: 0.2)
        self.assertIsInstance(result, Prediction)
        self.assertEqual(result.probability, 0.2)

    def test_history_bands(self):
        self.assertEqual(serving.history_band(0, True), "cold")
        self.assertEqual(serving.history_band(0, False), "cold")
        self.assertEqual(serving.history_band(4, False), "limited")
        self.assertEqual(serving.history_band(10, False), "sufficient")

    def test_preprocessor_roundtrip_from_real_artifact(self):
        record = artifact_mod.read_artifact(MODEL_PATH)
        preproc = serving.preprocessor_from_record(record)
        self.assertEqual(preproc.n_train_rows, 52)
        self.assertEqual(len(preproc.medians), 11)

    def test_preprocessor_missing_stats_rejected(self):
        record = _minimal_record()
        del record["preprocessing_fitted"]
        with self.assertRaises(artifact_mod.CorruptModel):
            serving.preprocessor_from_record(record)


class ScenarioTest(unittest.TestCase):
    """End-to-end adaptive scenarios against the serving contract."""

    def _expected_real(self):
        record = json.loads(MODEL_PATH.read_text(encoding="utf-8"))
        return {"model_id": "rf-pcorrect-g24",
                "model_version": "0.1.0-gate24exp",
                "feature_version": "f1",
                "dataset_fingerprint": record["dataset_fingerprint"]}

    def test_scenario1_new_learner_deterministic(self):
        result = serving.score(
            _request(is_cold_start=True, history_count=0),
            MODEL_PATH, self._expected_real(), lambda row: 0.9)
        self.assertIsInstance(result, Fallback)
        self.assertEqual(result.reason, "cold_start")

    def test_scenario2_sufficient_history_still_gated(self):
        # Eligibility (not history) is the binding constraint today.
        result = serving.score(
            _request(history_count=28), MODEL_PATH,
            self._expected_real(), lambda row: 0.9)
        self.assertIsInstance(result, Fallback)
        self.assertEqual(result.reason, "model_not_eligible")

    def test_scenario3_model_unavailable_deterministic(self):
        result = serving.score(
            _request(history_count=28), Path("/no/such/model.json"),
            self._expected_real(), lambda row: 0.9)
        self.assertIsInstance(result, Fallback)

    def test_scenario4_stale_model_deterministic(self):
        expected = self._expected_real()
        expected["dataset_fingerprint"] = "drifted-fingerprint"
        result = serving.score(_request(history_count=28), MODEL_PATH,
                               expected, lambda row: 0.9)
        self.assertIsInstance(result, Fallback)
        self.assertEqual(result.reason, "stale_model")

    def test_scenario6_server_identity_wins(self):
        # No identity field on the serving path can select another
        # learner's model/parameters: score() binds one artifact and
        # one request; learner_ref is opaque metadata, never a lookup.
        with tempfile.TemporaryDirectory() as tmp:
            path, expected = _fixture_eligible(tmp)
            first = serving.score(_request(learner_ref="learner-A"),
                                  path, expected, lambda row: 0.7)
            second = serving.score(_request(learner_ref="learner-B"),
                                   path, expected, lambda row: 0.7)
        self.assertIsInstance(first, Prediction)
        self.assertIsInstance(second, Prediction)
        self.assertEqual(first.probability, second.probability)


if __name__ == "__main__":
    unittest.main()
