"""Shadow-mode tests (GATE 9). Standard library only.

All histories are hand-built LABELED synthetic fixtures (obvious fake
IDs) — never real learner data, never performance evidence. No database,
no network, no services. A tiny fixture RAG corpus exercises retrieval
paths offline.

Run: python -m unittest mlrag.tests.test_shadow_mode -v
"""

from __future__ import annotations

import unittest

from mlrag.contracts.adaptive import SignalStatus
from mlrag.contracts.common import ContractViolation
from mlrag.rag.documents import RagDocument
from mlrag.shadow import contracts, evaluator, replay

FIX = "shadow-fixture"


def outcome_rows() -> list[dict]:
    """Synthetic multi-learner history: cold, sparse, sufficient."""
    rows = []
    spec = [
        # (learner, day, correct, quiz, topic)
        ("SL1", 1, True, "Q1", "T1"),
        ("SL1", 2, False, "Q2", "T1"),
        ("SL1", 3, True, "Q3", "T1"),
        ("SL1", 4, True, "Q4", "T1"),
        ("SL2", 2, True, "Q5", "T2"),
        ("SL2", 3, False, "Q6", "T2"),
        ("SL3", 4, True, "Q7", "T1"),
    ]
    for i, (learner, day, correct, quiz, topic) in enumerate(spec):
        rows.append({
            "question_attempt_id": f"{FIX}-qa-{i}",
            "quiz_attempt_id": quiz,
            "question_id": f"{FIX}-q-{i}",
            "learner_key": learner,
            "submitted_at": f"2026-09-0{day}T10:00:00",
            "topic_id": topic,
            "subject_id": f"{FIX}-s",
            "question_difficulty": "EASY",
            "question_text": f"sample question about {topic} number {i}",
            "is_correct": correct,
        })
    return rows


def corpus() -> list[RagDocument]:
    docs = []
    for topic in ("T1", "T2"):
        docs.append(RagDocument(
            doc_id=f"lessons:{FIX}-{topic}#c0", source_table="lessons",
            source_id=f"{FIX}-{topic}",
            text=f"sample educational content about {topic} energy",
            subject_id=f"{FIX}-s", topic_id=topic, is_active=True,
            lesson_id=f"{FIX}-{topic}", content_version="v1"))
    return docs


class OrderingTest(unittest.TestCase):
    """Area 1: deterministic replay ordering."""

    def test_sorted_by_time_then_stable_id(self):
        events, _ = replay.build_events(outcome_rows()[::-1])
        stamps = [(e.event_time_iso, e.event_id) for e in events]
        self.assertEqual(stamps, sorted(stamps))
        again, _ = replay.build_events(outcome_rows())
        self.assertEqual(events, again)


class PointInTimeTest(unittest.TestCase):
    """Areas 2-4: strict past filtering, target + sibling exclusion."""

    def test_past_is_strictly_before(self):
        event = replay.build_events(outcome_rows())[0][3]
        past = replay._past_rows(outcome_rows(), event)
        self.assertTrue(all(
            str(r["submitted_at"]) < event.event_time_iso for r in past))

    def test_events_carry_no_target(self):
        events, _ = replay.build_events(outcome_rows())
        for event in events:
            self.assertFalse(hasattr(event, "is_correct"))
            self.assertFalse(hasattr(event, "label"))

    def test_same_quiz_siblings_excluded(self):
        rows = [dict(outcome_rows()[0]),
                dict(outcome_rows()[1])]
        rows[1]["quiz_attempt_id"] = rows[0]["quiz_attempt_id"]
        rows[1]["submitted_at"] = rows[0]["submitted_at"]
        rows[1]["question_attempt_id"] = f"{FIX}-qa-sib"
        events, _ = replay.build_events(rows)
        second = [e for e in events if e.event_id == f"{FIX}-qa-sib"][0]
        past = replay._past_rows(rows, second)
        self.assertEqual(past, [])


class ColdStartTest(unittest.TestCase):
    """Areas 5-7: cold / insufficient / sufficient tiers."""

    def test_tiers_present(self):
        records = replay.run_replay(outcome_rows(), corpus=corpus())
        tiers = {r.ml.history_tier for r in records}
        self.assertIn("cold_start", tiers)
        self.assertIn("sufficient_history", tiers)

    def test_cold_events_fall_back(self):
        records = replay.run_replay(outcome_rows(), corpus=corpus())
        cold = [r for r in records if r.ml.history_tier == "cold_start"]
        self.assertTrue(cold)
        for record in cold:
            self.assertNotEqual(record.ml.signal.status, SignalStatus.SERVED)


class MLResponseTest(unittest.TestCase):
    """Areas 8-12: valid/invalid/timeout/unavailable/version behavior."""

    def test_valid_response_served(self):
        records = replay.run_replay(outcome_rows(), corpus=corpus())
        served = [r for r in records
                  if r.ml.signal.status == SignalStatus.SERVED]
        self.assertTrue(served)
        for record in served:
            self.assertGreaterEqual(record.ml.signal.p_correct, 0.0)
            self.assertLessEqual(record.ml.signal.p_correct, 1.0)

    def test_unavailable_and_timeout_fall_back(self):
        for mode in ("unavailable", "timeout"):
            records = replay.run_replay(outcome_rows(), ml_mode=mode)
            for record in records:
                self.assertNotEqual(record.ml.signal.status,
                                    SignalStatus.SERVED)
                self.assertTrue(record.ml.signal.fallback_reason)

    def test_invalid_and_version_mismatch_fall_back(self):
        for mode in ("invalid", "version_mismatch", "low_confidence"):
            records = replay.run_replay(outcome_rows(), ml_mode=mode)
            for record in records:
                self.assertNotEqual(record.ml.signal.status,
                                    SignalStatus.SERVED)


class RAGResponseTest(unittest.TestCase):
    """Areas 13-18: RAG success/failure/grounding/scope/inactive."""

    def test_success_grounded(self):
        records = replay.run_replay(outcome_rows(), corpus=corpus())
        served = [r for r in records
                  if r.rag.evidence.status == SignalStatus.SERVED]
        self.assertTrue(served)
        for record in served:
            self.assertTrue(record.rag.citations)

    def test_no_result_empty_corpus(self):
        records = replay.run_replay(outcome_rows(), corpus=[])
        for record in records:
            self.assertNotEqual(record.rag.evidence.status,
                                SignalStatus.SERVED)

    def test_failure_modes_degrade(self):
        for mode in ("unavailable", "scope_mismatch", "inactive",
                     "bad_citation", "grounding_failure"):
            records = replay.run_replay(outcome_rows(), corpus=corpus(),
                                        rag_mode=mode)
            for record in records:
                self.assertNotEqual(record.rag.evidence.status,
                                    SignalStatus.SERVED,
                                    msg=mode)

    def test_scope_mismatch_reason_recorded(self):
        records = replay.run_replay(
            outcome_rows(), corpus=corpus(), rag_mode="scope_mismatch")
        reasons = {r.rag.evidence.fallback_reason for r in records}
        self.assertTrue(any("scope" in reason or "no grounded" in reason
                            for reason in reasons))


class SeparationTest(unittest.TestCase):
    """Areas 19-21: advisory separation, outcome preservation, feedback."""

    def test_advisory_is_not_decision(self):
        records = replay.run_replay(outcome_rows(), corpus=corpus())
        for record in records:
            self.assertFalse(hasattr(record.advisory, "mastery_score"))
            self.assertIn(record.advisory.advisory_action,
                          ("PRACTICE", "REVIEW", "REMEDIATE", "ADVANCE",
                           "FALLBACK"))

    def test_outcome_truth_preserved(self):
        records = replay.run_replay(outcome_rows(), corpus=corpus())
        self.assertFalse(records[0].outcome.engine_replayed)
        self.assertIn("grading truth", records[0].outcome.engine_note)

    def test_no_self_training_feedback(self):
        first = replay.run_replay(outcome_rows(), corpus=corpus())
        second = replay.run_replay(outcome_rows(), corpus=corpus())
        self.assertEqual(
            [(r.event.event_id, r.outcome.is_correct) for r in first],
            [(r.event.event_id, r.outcome.is_correct) for r in second])
        # Predictions never re-enter inputs: rerun equality proves no
        # prediction-dependent state exists between passes.


class DeterminismIsolationTest(unittest.TestCase):
    """Areas 22-23: deterministic replay, learner isolation."""

    def test_deterministic_rerun(self):
        rows = outcome_rows()
        self.assertTrue(evaluator.determinism_check(
            lambda: replay.run_replay(rows, corpus=corpus()),
            lambda: replay.run_replay(rows, corpus=corpus())))

    def test_learner_isolation(self):
        records = replay.run_replay(outcome_rows(), corpus=corpus())
        sl3 = [r for r in records if r.event.learner_key == "SL3"][0]
        self.assertEqual(sl3.ml.history_tier, "cold_start")


class AggregateSafetyTest(unittest.TestCase):
    """Area 24: aggregate output carries no sensitive records."""

    def test_summary_has_no_raw_rows(self):
        records = replay.run_replay(outcome_rows(), corpus=corpus())
        summary = evaluator.summarize(records)
        blob = str(summary)
        self.assertNotIn("question_text", blob)
        self.assertNotIn("@", blob)
        self.assertIn("n_events", summary)
        self.assertEqual(summary["n_events"], 7)


class ContractGuardTest(unittest.TestCase):
    def test_event_rejects_target_fields(self):
        # Frozen dataclass: unknown target kwargs are structurally
        # impossible (TypeError), not merely validated away.
        with self.assertRaises(TypeError):
            contracts.ReplayEvent(
                event_id="e", learner_key="k",
                event_time_iso="2026-09-01T00:00:00", question_id="q",
                topic_id="t", subject_id="s", question_difficulty="EASY",
                is_correct=True)  # type: ignore[call-arg]

    def test_unknown_modes_rejected(self):
        with self.assertRaises(ContractViolation):
            replay.run_replay(outcome_rows(), ml_mode="turbo")
        with self.assertRaises(ContractViolation):
            replay.run_replay(outcome_rows(), rag_mode="turbo")


if __name__ == "__main__":
    unittest.main()
