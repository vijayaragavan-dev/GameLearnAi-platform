"""Gate 24 tests: calibration assessment + decline rule + artifact gates.

Covers: ECE math, recalibration verdict boundaries, assess() statuses,
artifact round-trip/fingerprint/tamper/version/stale/eligibility
gates, and the REAL committed artifact (eligibility=false enforced).
"""

from __future__ import annotations

import copy
import json
import unittest
from pathlib import Path

from mlrag.learner_intelligence import artifact as artifact_mod
from mlrag.learner_intelligence import calibration24

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
MODEL_PATH = REPO_ROOT / "mlrag" / "artifacts" / "gate24_learner_model.json"


class EceTest(unittest.TestCase):
    def test_perfect_predictions_zero_ece(self):
        y = [1, 1, 0, 0]
        out = calibration24.expected_calibration_error(y, [1.0, 1.0, 0.0, 0.0])
        self.assertAlmostEqual(out["ece"], 0.0, places=9)

    def test_known_ece_value(self):
        # 2 in [0.6,0.8): mean_p .7, mean_y .5 -> .2*.5
        # 2 in [0.8,1.0]: mean_p .9, mean_y 1.0 -> .1*.5 ; ECE = .15
        out = calibration24.expected_calibration_error(
            [1, 0, 1, 1], [0.7, 0.7, 0.9, 0.9])
        self.assertAlmostEqual(out["ece"], 0.15, places=9)

    def test_empty_population_not_computable(self):
        out = calibration24.expected_calibration_error([], [])
        self.assertIsNone(out["ece"])
        self.assertIn("NOT COMPUTABLE", out["reason"])


class RecalibrationRuleTest(unittest.TestCase):
    def test_current_scale_declines(self):
        verdict = calibration24.recalibration_verdict(
            n_train=52, n_train_positives=38, n_train_negatives=14)
        self.assertEqual(verdict["status"], "INSUFFICIENT DATA")

    def test_sufficient_scale_eligible(self):
        verdict = calibration24.recalibration_verdict(
            n_train=500, n_train_positives=300, n_train_negatives=200)
        self.assertEqual(verdict["status"], "ELIGIBLE")

    def test_large_n_single_class_declines(self):
        verdict = calibration24.recalibration_verdict(
            n_train=500, n_train_positives=495, n_train_negatives=5)
        self.assertEqual(verdict["status"], "INSUFFICIENT DATA")

    def test_assess_statuses(self):
        declined = calibration24.assess(
            [1, 0, 1, 1], [0.7, 0.7, 0.9, 0.9], n_train=52,
            n_train_positives=38, n_train_negatives=14, population="t")
        self.assertEqual(declined["calibration_status"],
                         "ASSESSED_UNCALIBRATED")
        self.assertEqual(declined["bins_occupied"], 2)
        eligible = calibration24.assess(
            [1, 0], [0.7, 0.3], n_train=500, n_train_positives=300,
            n_train_negatives=200, population="t")
        self.assertEqual(eligible["calibration_status"],
                         "RECALIBRATION_ELIGIBLE")


def _minimal_record(**overrides):
    record = {
        "artifact_version": artifact_mod.ARTIFACT_VERSION,
        "model_id": "rf-pcorrect-g24",
        "model_version": "0.1.0-gate24exp",
        "model_family": "RandomForestClassifier",
        "model_config": {"n_estimators": 64},
        "feature_version": "f1",
        "dataset_version": "d1",
        "dataset_fingerprint": "fp-live",
        "data_version": "dv",
        "train_population": {"n_train": 52},
        "preprocessing": {},
        "preprocessing_fitted": {"medians": {}, "means": {},
                                 "scales": {},
                                 "median_fallback_columns": [],
                                 "n_train_rows": 52},
        "parameters": {},
        "evaluation_summary": {},
        "calibration_status": "ASSESSED_UNCALIBRATED",
        "production_eligibility": False,
        "promotion_blockers": ["rows"],
        "library_versions": {},
        "python_version": "3.13.7",
        "created_at_utc": "2026-09-15T00:00:00+00:00",
    }
    record.update(overrides)
    record["artifact_fingerprint"] = artifact_mod.fingerprint_record(record)
    return record


def _expected(fp="fp-live"):
    return {"model_id": "rf-pcorrect-g24",
            "model_version": "0.1.0-gate24exp",
            "feature_version": "f1",
            "dataset_fingerprint": fp}


def _expected_kwargs(fp="fp-live"):
    return {"expected_model_id": "rf-pcorrect-g24",
            "expected_model_version": "0.1.0-gate24exp",
            "expected_feature_version": "f1",
            "expected_dataset_fingerprint": fp}


class ArtifactGateTest(unittest.TestCase):
    def test_roundtrip_and_fingerprint(self):
        import tempfile
        record = _minimal_record()
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "m.json"
            artifact_mod.write_artifact(record, path)
            loaded = artifact_mod.read_artifact(path)
        self.assertEqual(loaded["artifact_fingerprint"],
                         record["artifact_fingerprint"])

    def test_tampered_bytes_rejected(self):
        import tempfile
        record = _minimal_record()
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "m.json"
            artifact_mod.write_artifact(record, path)
            text = path.read_text(encoding="utf-8").replace(
                "rf-pcorrect-g24", "rf-pcorrect-g25", 1)
            path.write_text(text, encoding="utf-8")
            with self.assertRaises(artifact_mod.CorruptModel):
                artifact_mod.read_artifact(path)

    def test_missing_keys_rejected(self):
        import tempfile
        record = _minimal_record()
        del record["parameters"]
        record["artifact_fingerprint"] = artifact_mod.fingerprint_record(
            record)
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "m.json"
            path.write_text(json.dumps(record), encoding="utf-8")
            with self.assertRaises(artifact_mod.CorruptModel):
                artifact_mod.read_artifact(path)

    def test_model_id_mismatch_rejected(self):
        import tempfile
        record = _minimal_record()
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "m.json"
            artifact_mod.write_artifact(record, path)
            expected = _expected_kwargs()
            expected["expected_model_id"] = "other-model"
            with self.assertRaises(artifact_mod.CorruptModel):
                artifact_mod.load_for_serving(path, **expected)

    def test_feature_mismatch_rejected(self):
        import tempfile
        record = _minimal_record()
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "m.json"
            artifact_mod.write_artifact(record, path)
            expected = _expected_kwargs()
            expected["expected_feature_version"] = "f2"
            with self.assertRaises(artifact_mod.CorruptModel):
                artifact_mod.load_for_serving(path, **expected)

    def test_stale_fingerprint_rejected(self):
        import tempfile
        record = _minimal_record()
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "m.json"
            artifact_mod.write_artifact(record, path)
            with self.assertRaises(artifact_mod.StaleModel):
                artifact_mod.load_for_serving(
                    path, **_expected_kwargs(fp="fp-new"))

    def test_ineligible_model_never_servable(self):
        import tempfile
        record = _minimal_record(production_eligibility=False)
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "m.json"
            artifact_mod.write_artifact(record, path)
            with self.assertRaises(artifact_mod.ModelNotEligible):
                artifact_mod.load_for_serving(path, **_expected_kwargs())

    def test_eligible_model_loads(self):
        import tempfile
        record = _minimal_record(production_eligibility=True)
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "m.json"
            artifact_mod.write_artifact(record, path)
            loaded = artifact_mod.load_for_serving(path, **_expected_kwargs())
        self.assertEqual(loaded["model_id"], "rf-pcorrect-g24")

    def test_real_artifact_is_valid_but_not_eligible(self):
        record = artifact_mod.read_artifact(MODEL_PATH)
        self.assertEqual(record["model_id"], "rf-pcorrect-g24")
        self.assertEqual(record["feature_version"], "f1")
        self.assertFalse(record["production_eligibility"])
        self.assertTrue(record["promotion_blockers"])
        with self.assertRaises(artifact_mod.ModelNotEligible):
            artifact_mod.load_for_serving(
                MODEL_PATH,
                expected_model_id="rf-pcorrect-g24",
                expected_model_version="0.1.0-gate24exp",
                expected_feature_version="f1",
                expected_dataset_fingerprint=record["dataset_fingerprint"])

    def test_real_artifact_fingerprint_self_consistent(self):
        record = json.loads(MODEL_PATH.read_text(encoding="utf-8"))
        self.assertEqual(artifact_mod.fingerprint_record(record),
                         record["artifact_fingerprint"])
        copy_record = copy.deepcopy(record)
        copy_record["train_population"]["n_train"] = 9999
        self.assertNotEqual(artifact_mod.fingerprint_record(copy_record),
                            record["artifact_fingerprint"])


if __name__ == "__main__":
    unittest.main()
