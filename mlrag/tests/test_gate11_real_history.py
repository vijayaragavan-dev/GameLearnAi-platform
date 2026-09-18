"""Gate 11 real-history harness tests. Standard library + numpy/sklearn.

All histories are hand-built LABELED synthetic fixtures — never real
learner data.  The live-DB path is tested ONLY for its clean blocker
(no credentials present, no connection attempted, no fallback).
No database, no network, no services.

Run: python -m unittest mlrag.tests.test_gate11_real_history -v
"""

from __future__ import annotations

import os
import unittest
from unittest import mock

from mlrag.contracts.common import ContractViolation
from mlrag.rag.documents import RagDocument
from mlrag.shadow import real_history
from mlrag.shadow.real_history import evaluate_dataset

FIX = "gate11-fixture"


def synth_rows() -> list[dict]:
    import datetime
    rows = []
    spec = [
        ("GA", 1, True, "T1"), ("GA", 2, False, "T1"),
        ("GA", 3, True, "T1"), ("GA", 4, True, "T2"),
        ("GB", 2, True, "T2"), ("GB", 3, False, "T2"),
        ("GB", 4, True, "T1"),
    ]
    for i, (learner, day, correct, topic) in enumerate(spec):
        rows.append({
            "question_attempt_id": f"{FIX}-qa-{i}",
            "quiz_attempt_id": f"{FIX}-qz-{i}",
            "question_id": f"{FIX}-q-{i}",
            "learner_key": learner,
            "submitted_at": datetime.datetime(2026, 9, day, 10, 0, 0),
            "topic_id": topic,
            "subject_id": "S",
            "question_difficulty": "EASY",
            "quiz_difficulty": "EASY",
            "is_correct": correct,
        })
    return rows


def built_rows():
    from mlrag.experiment import features

    return features.build_rows(synth_rows(), [], [])


def fixture_corpus() -> list[RagDocument]:
    docs = []
    for topic in ("T1", "T2"):
        docs.append(RagDocument(
            doc_id=f"lessons:{FIX}-{topic}#c0", source_table="lessons",
            source_id=f"{FIX}-{topic}",
            text=f"sample educational content about {topic} energy",
            subject_id="S", topic_id=topic, is_active=True,
            lesson_id=f"{FIX}-{topic}", content_version="v1"))
    return docs


class ExtractionGuardTest(unittest.TestCase):
    """Area 1: read-only guard rejects writes without a database."""

    def test_write_statements_rejected(self):
        from mlrag.experiment import db

        for bad in ("INSERT INTO users VALUES (1)", "UPDATE users SET x=1",
                    "DELETE FROM users", "ALTER TABLE users ADD COLUMN x INT",
                    "DROP TABLE users", "TRUNCATE users"):
            with self.assertRaises(ContractViolation, msg=bad):
                db.run_select(object(), bad)

    def test_live_path_blocked_without_credentials(self):
        with mock.patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(ContractViolation):
                real_history.run_live_evaluation()


class PrivacyTest(unittest.TestCase):
    """Areas 2-3: no credentials in output, hashed learner keys."""

    def test_no_credentials_in_module(self):
        import pathlib

        source = pathlib.Path(
            __file__).parent.parent.joinpath(
                "shadow", "real_history.py").read_text(encoding="utf-8")
        lowered = source.lower()
        for token in ("password=", "passwd", "jdbc:mysql://", "secret"):
            self.assertNotIn(token, lowered)

    def test_learner_key_surrogate(self):
        from mlrag.experiment.extract import learner_key

        key = learner_key("some-user-id")
        self.assertTrue(key.startswith("learner_"))
        self.assertNotIn("some-user-id", key)


class LeakageContractTest(unittest.TestCase):
    """Areas 4-7: target separation, strict past, future + sibling."""

    def test_target_separation_in_builtin(self):
        rows = built_rows()
        for row in rows:
            self.assertIn("label", row)  # evaluation-side only
        from mlrag.shadow import replay

        events, _ = replay.build_events(synth_rows())
        for event in events:
            self.assertFalse(hasattr(event, "is_correct"))

    def test_strict_timestamp_rule(self):
        from mlrag.shadow import replay

        events, _ = replay.build_events(synth_rows())
        for event in events:
            past = replay._past_rows(synth_rows(), event)
            self.assertTrue(all(
                str(r["submitted_at"]) < event.event_time_iso
                for r in past))

    def test_future_excluded(self):
        from mlrag.shadow import replay

        rows = synth_rows()
        events, _ = replay.build_events(rows)
        # Ordered by (submitted_at, question_attempt_id): the last event
        # is GB day-4; its past must be GB days 2-3 only.
        last = events[-1]
        self.assertEqual(last.event_id, f"{FIX}-qa-6")
        past = replay._past_rows(rows, last)
        self.assertEqual(
            [r["question_attempt_id"] for r in past],
            [f"{FIX}-qa-4", f"{FIX}-qa-5"])

    def test_sibling_exclusion(self):
        from mlrag.shadow import replay

        rows = [dict(synth_rows()[0]), dict(synth_rows()[1])]
        rows[1]["quiz_attempt_id"] = rows[0]["quiz_attempt_id"]
        rows[1]["submitted_at"] = rows[0]["submitted_at"]
        rows[1]["question_attempt_id"] = f"{FIX}-qa-sib"
        events, _ = replay.build_events(rows)
        sib = [e for e in events if e.event_id == f"{FIX}-qa-sib"][0]
        self.assertEqual(replay._past_rows(rows, sib), [])


class ColdStartTest(unittest.TestCase):
    """Areas 8-9: cold/insufficient classification on built rows."""

    def test_tiers(self):
        from mlrag.experiment import model as model_module

        rows = built_rows()
        cold = [r for r in rows if r["is_cold_start"]]
        served = [r for r in rows
                  if model_module.served_by_model(r)]
        self.assertTrue(cold)
        self.assertTrue(served)
        self.assertEqual(len(cold) + len([r for r in rows
                                          if not r["is_cold_start"]]),
                         len(rows))


class ModelContractTest(unittest.TestCase):
    """Areas 10-12: actual model output/version/schema validation."""

    def test_model_output_valid(self):
        from mlrag.experiment import model as model_module

        rows = built_rows()
        bundle = model_module.fit(rows)
        for prob in model_module.predict_proba(bundle, rows):
            self.assertGreaterEqual(prob, 0.0)
            self.assertLessEqual(prob, 1.0)
        self.assertEqual(model_module.MODEL_ID, "logreg-pcorrect-v1")
        self.assertEqual(model_module.FEATURE_SCHEMA_VERSION, "f1")

    def test_baseline_parity(self):
        from mlrag.experiment import baselines

        rows = built_rows()
        rate = baselines.fit_global_rate(rows)
        row = [r for r in rows if not r["is_cold_start"]][0]
        value = baselines.predict_b(rows, row, rate)
        self.assertGreaterEqual(value, 0.0)
        self.assertLessEqual(value, 1.0)


class SplitValidityTest(unittest.TestCase):
    """Areas 13-15: split policy objects enforce learner+time rules."""

    def test_temporal_split_contract(self):
        from mlrag.contracts.evaluation import SplitPolicy

        with self.assertRaises(ContractViolation):
            SplitPolicy(strategy="random_row",
                        training_end_iso="2026-01-01T00:00:00Z",
                        validation_end_iso="2026-02-01T00:00:00Z")
        policy = SplitPolicy(
            strategy="user_aware_time_aware",
            training_end_iso="2026-01-01T00:00:00Z",
            validation_end_iso="2026-02-01T00:00:00Z")
        self.assertTrue(policy.user_isolation)

    def test_learner_aware_folds(self):
        from mlrag.experiment import evaluate

        rows = built_rows()
        result = evaluate.leave_one_learner_out(rows)
        self.assertEqual(result["n_folds"], 2)
        for fold in result["folds"]:
            self.assertGreater(fold["n_train"], 0)
            self.assertGreater(fold["n_test"], 0)


class MetricValidityTest(unittest.TestCase):
    """Areas 16-17: calibration + invalid-metric None behavior."""

    def test_calibration_summary_shape(self):
        from mlrag.experiment import calibration as calibration_module
        from mlrag.experiment import evaluate

        table = evaluate.calibration_table([1, 0], [0.8, 0.3])
        summary = calibration_module.summarize_calibration(table)
        self.assertIn("overall_bias", summary)
        self.assertIn("bins", summary)

    def test_invalid_metric_none(self):
        from mlrag.experiment import evaluate

        scored = evaluate.score_set([1, 1, 1], [0.7, 0.8, 0.6])
        self.assertIsNone(scored["roc_auc"])
        self.assertIsNone(scored["pr_auc"])


class RAGSafetyTest(unittest.TestCase):
    """Areas 18-20: scope, grounding, inactive rejection (fixtures)."""

    def test_scope_and_grounding(self):
        from mlrag.rag import grounding, retrieval
        from mlrag.contracts.retriever import ScopeFilter

        engine = retrieval.LexicalRetriever()
        response = engine.retrieve(
            retrieval.RagQuery(query="energy", subject_id="S",
                               topic_id="T1"),
            fixture_corpus(), request_id="t")
        self.assertTrue(response.served)
        context = grounding.validate_grounded(
            list(response.chunks), ScopeFilter(subject_id="S",
                                              topic_id="T1"),
            request_id="t")
        self.assertTrue(context.citations)

    def test_inactive_rejected(self):
        from mlrag.rag import ingest

        result = ingest.ingest_records(
            [{"id": "x", "topic_id": "T1", "subject_id": "S",
              "name": "N", "description": "d", "is_active": False}],
            source_table="topics")
        self.assertEqual(result.documents, [])


class FailureSafetyTest(unittest.TestCase):
    """Areas 21-22: failure fallback + advisory separation."""

    def test_ml_failure_modes(self):
        from mlrag.shadow import replay

        rows = synth_rows()
        for mode in ("unavailable", "timeout", "invalid",
                     "low_confidence", "version_mismatch"):
            records = replay.run_replay(rows, ml_mode=mode)
            for record in records:
                self.assertNotEqual(record.ml.signal.status.value,
                                    "served", msg=mode)

    def test_rag_failure_modes(self):
        from mlrag.shadow import replay

        rows = synth_rows()
        for mode in ("unavailable", "empty", "scope_mismatch", "inactive",
                     "bad_citation", "grounding_failure"):
            records = replay.run_replay(rows, corpus=fixture_corpus(),
                                        rag_mode=mode)
            for record in records:
                self.assertNotEqual(record.rag.evidence.status.value,
                                    "served", msg=mode)

    def test_advisory_is_not_decision(self):
        from mlrag.shadow import replay

        records = replay.run_replay(synth_rows(), corpus=fixture_corpus())
        for record in records:
            self.assertFalse(hasattr(record.advisory, "mastery_score"))


class ReplayIntegrityTest(unittest.TestCase):
    """Areas 23-28: feedback purity, determinism, aggregates, promotion."""

    def test_no_feedback_contamination(self):
        from mlrag.shadow import evaluator, replay

        rows = synth_rows()
        first = replay.run_replay(rows, corpus=fixture_corpus())
        second = replay.run_replay(rows, corpus=fixture_corpus())
        self.assertTrue(evaluator.determinism_check(lambda: first,
                                                   lambda: second))

    def test_deterministic_payload(self):
        first = evaluate_dataset_shim()
        second = evaluate_dataset_shim()
        self.assertEqual(first["n_events"], second["n_events"])
        self.assertEqual(first["promotion"], second["promotion"])

    def test_aggregate_only(self):
        payload = evaluate_dataset_shim()
        blob = str(payload)
        self.assertNotIn("@", blob)
        self.assertNotIn("password", blob.lower())
        self.assertIn("n_events", payload)

    def test_no_production_promotion(self):
        payload = evaluate_dataset_shim()
        self.assertFalse(payload["deployment_ready"])
        self.assertFalse(payload["production_promotion"])
        self.assertFalse(payload["promotion"]["promotable"])


def evaluate_dataset_shim():
    from mlrag.experiment import features
    from mlrag.shadow.real_history import evaluate_dataset

    rows = features.build_rows(synth_rows(), [], [])
    return evaluate_dataset(rows, fixture_corpus())


if __name__ == "__main__":
    unittest.main()
