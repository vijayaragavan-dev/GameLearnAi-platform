"""Gate 18: dataset contract, construction, fingerprint, and quality tests."""

from __future__ import annotations

import json
import unittest

from mlrag.contracts.common import ContractViolation
from mlrag.dataset.build import (
    build_dataset,
    dataset_row_from_feature_row,
    datasets_equal,
    fingerprint_dataset,
)
from mlrag.dataset.contract import (
    DATASET_VERSION,
    SPLIT_NAMES,
    UNASSIGNED,
    TARGET_COLUMN,
    derive_row_id,
    scan_prohibited_content,
    validate_dataset_row,
)
from mlrag.dataset.quality import (
    artifact_safety_scan,
    audit_dataset,
    identity_audit,
    missingness_report,
    readiness_evaluation,
)
from mlrag.dataset.split import apply_assignment, assign_splits
from mlrag.feature_pipeline.builder import build_feature_table
from mlrag.feature_pipeline.contract import FEATURE_COLUMNS, FEATURE_VERSION

from . import gate17_fixtures as fx


def source_rows(n=9, learners=3):
    return [
        fx.outcome(
            f"qa{i:02d}", f"qz{i % 2}", learner=f"learner_{i % learners}",
            topic=f"topic_T{i % 2}", at=fx.at_days(i),
            correct=bool(i % 2), response_time=10 + i if i % 3 else None,
        )
        for i in range(n)
    ]


def feature_rows(**kw):
    tables = fx.tables(source_rows(**kw))
    build = build_feature_table(tables)
    assert not build["rejections"], build["rejections"]
    return build


class DatasetContractTest(unittest.TestCase):
    def test_versions_pinned(self):
        self.assertEqual(DATASET_VERSION, "d1")
        self.assertEqual(FEATURE_VERSION, "f1")
        self.assertEqual(TARGET_COLUMN, "is_correct")

    def test_row_id_derivation_documented_and_stable(self):
        first = derive_row_id("attempt-uuid-1")
        self.assertEqual(first, derive_row_id("attempt-uuid-1"))
        self.assertNotEqual(first, derive_row_id("attempt-uuid-2"))
        self.assertTrue(first.startswith("datarow_"))
        self.assertNotIn("attempt-uuid-1", first)

    def test_row_id_mismatch_rejected(self):
        build = feature_rows()
        dataset = build_dataset(build["rows"])
        bad = dict(dataset["rows"][0])
        bad["row_id"] = "datarow_deadbeefcafe"
        with self.assertRaises(ContractViolation):
            validate_dataset_row(bad)

    def test_raw_learner_id_rejected(self):
        build = feature_rows()
        dataset = build_dataset(build["rows"])
        bad = dict(dataset["rows"][0])
        bad["learner_key"] = "raw-user-uuid"
        with self.assertRaises(ContractViolation):
            validate_dataset_row(bad)

    def test_exact_schema_enforced(self):
        build = feature_rows()
        dataset = build_dataset(build["rows"])
        row = dict(dataset["rows"][0])
        del row["split"]
        with self.assertRaises(ContractViolation):
            validate_dataset_row(row)
        row = dict(dataset["rows"][0])
        row["extra"] = 1
        with self.assertRaises(ContractViolation):
            validate_dataset_row(row)

    def test_split_names(self):
        self.assertEqual(SPLIT_NAMES, ("train", "validation", "test"))
        build = feature_rows()
        dataset = build_dataset(build["rows"])
        for row in dataset["rows"]:
            self.assertEqual(row["split"], UNASSIGNED)


class DatasetBuildTest(unittest.TestCase):
    def test_one_row_per_eligible_attempt(self):
        build = feature_rows(n=9)
        dataset = build_dataset(build["rows"])
        self.assertEqual(len(dataset["rows"]), 9)
        self.assertEqual(dataset["rejections"], [])
        attempt_ids = sorted(r["question_attempt_id"] for r in dataset["rows"])
        self.assertEqual(attempt_ids, [f"qa{i:02d}" for i in range(9)])

    def test_exact_f1_feature_set_and_target_separation(self):
        build = feature_rows(n=6)
        dataset = build_dataset(build["rows"])
        for row in dataset["rows"]:
            self.assertEqual(set(row["features"].keys()),
                             set(FEATURE_COLUMNS))
            self.assertNotIn(TARGET_COLUMN, row["features"])
            self.assertIn(row[TARGET_COLUMN], (0, 1))
            validate_dataset_row(row)

    def test_nulls_preserved_no_imputation(self):
        build = feature_rows(n=6)
        dataset = build_dataset(build["rows"])
        source = {r["question_attempt_id"]: r["features"]
                  for r in build["rows"]}
        nulls = [r for r in dataset["rows"]
                 if r["features"]["hist_accuracy"] is None]
        self.assertTrue(nulls, "cold-start NULLs must survive construction")
        # Feature-for-feature identity with the Gate 17 source: no fills,
        # no coercions, no invented values.
        for row in dataset["rows"]:
            self.assertEqual(row["features"],
                             source[row["question_attempt_id"]])
        # Prior counts are KNOWN zeros, not missing — preserved as 0.
        cold = [r for r in dataset["rows"]
                if r["features"]["is_cold_start"]]
        self.assertTrue(cold)
        for row in cold:
            self.assertEqual(row["features"]["prior_total_count"], 0)

    def test_quarantined_post_attempt_scores_dropped(self):
        build = feature_rows(n=4)
        dataset = build_dataset(build["rows"])
        text = json.dumps(dataset["rows"], sort_keys=True, default=str)
        self.assertNotIn("quarantined_post_attempt", text)
        self.assertNotIn("quiz_score", text)

    def test_deterministic_ordering(self):
        build = feature_rows(n=9)
        dataset = build_dataset(build["rows"])
        keys = [(r["predicted_at"], r["quiz_attempt_id"],
                 r["question_attempt_id"]) for r in dataset["rows"]]
        self.assertEqual(keys, sorted(keys))

    def test_fingerprint_stable_and_sensitive(self):
        build = feature_rows(n=6)
        first = build_dataset(build["rows"])
        second = build_dataset(build["rows"])
        self.assertEqual(first["fingerprint"], second["fingerprint"])
        self.assertTrue(datasets_equal(first, second))
        mutated = build_dataset(build["rows"])
        mutated["rows"][0]["features"]["prior_total_count"] += 0
        self.assertTrue(datasets_equal(first, mutated))
        tampered = json.loads(json.dumps(first))
        tampered["rows"][0]["is_correct"] ^= 1
        self.assertNotEqual(first["fingerprint"],
                            fingerprint_dataset(tampered))

    def test_rebuild_twice_identical(self):
        build = feature_rows(n=9)
        first = build_dataset(build["rows"])
        second = build_dataset(build["rows"])
        self.assertTrue(datasets_equal(first, second))

    def test_shuffled_source_input_identical(self):
        build = feature_rows(n=12)
        forward = build_dataset(build["rows"])
        backward = build_dataset(list(reversed(build["rows"])))
        self.assertTrue(datasets_equal(forward, backward))

    def test_invalid_feature_row_becomes_explicit_rejection(self):
        build = feature_rows(n=4)
        tampered = [dict(r) for r in build["rows"]]
        tampered[0]["features"] = dict(tampered[0]["features"])
        tampered[0]["features"]["hist_accuracy"] = 7.0
        dataset = build_dataset(tampered)
        self.assertEqual(len(dataset["rows"]), 3)
        self.assertEqual(len(dataset["rejections"]), 1)
        self.assertIn("dataset_validation",
                      dataset["rejections"][0]["reason"])

    def test_single_row_conversion(self):
        build = feature_rows(n=1)
        row = dataset_row_from_feature_row(build["rows"][0])
        self.assertEqual(row["row_id"],
                         derive_row_id(row["question_attempt_id"]))


class DatasetQualityTest(unittest.TestCase):
    def test_audit_counts(self):
        build = feature_rows(n=9, learners=3)
        dataset = build_dataset(build["rows"])
        split = assign_splits(dataset["rows"])
        labeled = apply_assignment(dataset["rows"], split["assignment"])
        audit = audit_dataset(labeled, dataset["rejections"])
        self.assertEqual(audit["total_rows"], 9)
        self.assertEqual(audit["unique_learners"], 3)
        self.assertEqual(audit["unique_topics"], 2)
        self.assertEqual(
            audit["positive_count"] + audit["negative_count"], 9
        )
        self.assertAlmostEqual(
            audit["positive_rate"] + audit["negative_rate"], 1.0
        )
        self.assertEqual(audit["invalid_row_count"], 0)
        self.assertEqual(audit["rejected_row_count"], 0)
        self.assertEqual(sum(audit["attempts_per_learner"].values()), 9)

    def test_missingness_report_all_features(self):
        build = feature_rows(n=9, learners=3)
        dataset = build_dataset(build["rows"])
        report = missingness_report(dataset["rows"])
        self.assertEqual(set(report["per_feature"].keys()),
                         set(FEATURE_COLUMNS))
        for name, info in report["per_feature"].items():
            self.assertEqual(
                info["null_count"] + info["non_null_count"], 9, name
            )
        # Cold-start NULLs are expected on history-backed fields.
        self.assertGreater(
            report["per_feature"]["hist_accuracy"]["null_count"], 0
        )
        # Focus fields present.
        for name in ("prev_mastery_score", "prev_response_time_norm",
                     "timing_known", "days_since_last_attempt"):
            self.assertIn(name, report["focus_features"])

    def test_identity_audit_clean(self):
        build = feature_rows(n=9)
        dataset = build_dataset(build["rows"])
        identity = identity_audit(dataset["rows"])
        self.assertTrue(identity["identity_pass"])
        self.assertEqual(identity["duplicate_row_id_count"], 0)
        self.assertEqual(identity["exact_duplicate_row_count"], 0)

    def test_readiness_reports_not_ready_without_altering_bars(self):
        build = feature_rows(n=9, learners=3)
        dataset = build_dataset(build["rows"])
        audit = audit_dataset(dataset["rows"])
        readiness = readiness_evaluation(audit)
        self.assertEqual(readiness["data_readiness"], "NOT READY")
        bars = {k: v["required"] for k, v in
                readiness["criteria"].items()}
        self.assertEqual(
            bars,
            {"learners_ge_50": 50, "rows_ge_5000": 5000,
             "span_days_ge_60": 60, "min_per_learner_ge_10": 10,
             "calibration_rows_ge_200": 200, "bias_le_0_05": 0.05},
        )

    def test_prohibited_scan_detects_traps(self):
        self.assertTrue(scan_prohibited_content("contact a@b.com now"))
        self.assertTrue(scan_prohibited_content("eyJhbGciOiJIUzI1NiJ9."
                                               "cGF5bG9hZA."
                               "c2lnbmF0dXJl"))
        self.assertTrue(scan_prohibited_content('{"user_id": "x"}'))
        self.assertFalse(scan_prohibited_content('{"learner_key": '
                                                 '"learner_abc123"}'))

    def test_artifact_safety_scan(self):
        build = feature_rows(n=4)
        dataset = build_dataset(build["rows"])
        serialized = json.dumps(dataset, sort_keys=True, default=str)
        safety = artifact_safety_scan(serialized)
        self.assertTrue(safety["safety_pass"], safety["hits"])


if __name__ == "__main__":
    unittest.main()
