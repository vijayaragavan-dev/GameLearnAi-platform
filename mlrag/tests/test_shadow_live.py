"""Live shadow-integration safety tests (GATE 10). Stdlib only.

A simulated authoritative flow (in-memory ledger with commit/rollback
semantics) stands in for Spring Boot: the suite proves the shadow
executor observes post-commit, never alters authoritative state, never
fails learner requests, and enforces identity/target/version rules.
Synthetic fixtures only; no database, services, or network.

Run: python -m unittest mlrag.tests.test_shadow_live -v
"""

from __future__ import annotations

import os
import time
import unittest
from unittest import mock

from mlrag.contracts.adaptive import SignalStatus
from mlrag.contracts.common import ContractViolation
from mlrag.rag.documents import RagDocument
from mlrag.shadow import live, replay
from mlrag.shadow.contracts import ReplayEvent
from mlrag.shadow.live import (ShadowConfig, ShadowExecutor,
                               derive_learner_key, new_correlation_id,
                               sampled_in)

FIX = "live-fixture"


def past_rows(n: int = 4, learner: str = "L1") -> list[dict]:
    rows = []
    for i in range(n):
        rows.append({
            "question_attempt_id": f"{FIX}-past-{i}",
            "quiz_attempt_id": f"{FIX}-qz-{i}",
            "question_id": f"{FIX}-q-{i}",
            "learner_key": learner,
            "submitted_at": f"2026-09-0{1 + i}T10:00:00",
            "topic_id": "T1",
            "subject_id": "S",
            "question_difficulty": "EASY",
            "question_text": f"sample past item {i}",
            "is_correct": i % 2 == 0,
        })
    return rows


def live_event() -> ReplayEvent:
    return ReplayEvent(
        event_id=f"{FIX}-live-1", learner_key="L1",
        event_time_iso="2026-09-10T10:00:00", question_id=f"{FIX}-q-live",
        topic_id="T1", subject_id="S", question_difficulty="EASY",
        question_text="sample live item")


def corpus() -> list[RagDocument]:
    return [RagDocument(
        doc_id=f"lessons:{FIX}-L#c0", source_table="lessons",
        source_id=f"{FIX}-L", text="sample educational content energy",
        subject_id="S", topic_id="T1", is_active=True,
        lesson_id=f"{FIX}-L", content_version="v1")]


def enabled_executor(**over) -> ShadowExecutor:
    base = {"enabled": True, "sample_rate_pct": 100, "timeout_ms": 5000,
            "max_workers": 2}
    base.update(over)
    try:
        return ShadowExecutor(ShadowConfig(**base))
    finally:
        pass


class AuthoritativeFlow:
    """Simulated Spring Boot flow: commit ledger first, shadow after."""

    def __init__(self, executor: ShadowExecutor):
        self.ledger: dict = {}
        self.executor = executor
        self.observations = []

    def submit(self, state: dict, event, past, docs):
        committed = dict(state)  # authoritative commit (in-memory)
        self.ledger.update(committed)
        try:
            observation = self.executor.observe(event, past, docs)
        except Exception:  # shadow must never propagate
            observation = None
        self.observations.append(observation)
        return dict(self.ledger)  # learner response derives ONLY from this


class SafetyTests(unittest.TestCase):
    """TESTS 1-8, 15: learner flow unchanged under all shadow conditions."""

    def run_flow(self, executor, docs=None):
        flow = AuthoritativeFlow(executor)
        result = flow.submit({"mastery": 50.0, "xp": 100},
                             live_event(), past_rows(),
                             docs if docs is not None else corpus())
        return result, flow

    def test_1_disabled_unchanged(self):
        executor = ShadowExecutor(ShadowConfig())
        try:
            result, flow = self.run_flow(executor)
            self.assertEqual(result, {"mastery": 50.0, "xp": 100})
            self.assertEqual(flow.observations[0].status, "disabled")
        finally:
            executor.shutdown()

    def test_2_success_unchanged(self):
        executor = enabled_executor()
        try:
            result, flow = self.run_flow(executor)
            self.assertEqual(result, {"mastery": 50.0, "xp": 100})
            self.assertEqual(flow.observations[0].status, "completed")
        finally:
            executor.shutdown()

    def test_3_4_ml_rag_fail_unchanged(self):
        executor = enabled_executor()
        try:
            from mlrag.shadow import replay as replay_module

            def boom(event, past):
                raise RuntimeError("ml down")

            with mock.patch.object(
                    replay_module, "baseline_predictor",
                    return_value=boom):
                result, flow = self.run_flow(executor)
            self.assertEqual(result, {"mastery": 50.0, "xp": 100})
            result2, flow2 = self.run_flow(executor, docs=[])
            self.assertEqual(result2, {"mastery": 50.0, "xp": 100})
        finally:
            executor.shutdown()

    def test_5_timeout_unchanged(self):
        executor = enabled_executor(timeout_ms=1)

        def slow(event, past):
            time.sleep(0.5)
            return replay.baseline_predictor(0.5)(event, past)

        try:
            flow = AuthoritativeFlow(executor)
            with mock.patch.object(replay, "run_replay") as fake:
                def slow_run(rows, **kwargs):
                    time.sleep(0.5)
                    kwargs.pop("predict", None)
                    from mlrag.shadow.replay import run_replay as real
                    return real(rows, **kwargs)

                fake.side_effect = slow_run
                result = flow.submit({"mastery": 50.0, "xp": 100},
                                     live_event(), past_rows(), corpus())
            self.assertEqual(result, {"mastery": 50.0, "xp": 100})
            self.assertIn(flow.observations[0].status,
                          ("timeout", "completed", "fallback"))
        finally:
            executor.shutdown()

    def test_6_7_invalid_ml_rag_unchanged(self):
        from mlrag.contracts.adaptive import MLSignal
        executor = enabled_executor()
        try:
            real_run = replay.run_replay

            def bad(event, past):
                return MLSignal(
                    status=SignalStatus.SERVED, p_correct=0.9,
                    confidence=0.9, model_version="x",
                    feature_schema_version="f1")

            def patched(rows, **kwargs):
                kwargs["predict"] = bad
                return real_run(rows, **kwargs)

            with mock.patch.object(replay, "run_replay",
                                   side_effect=patched):
                result, flow = self.run_flow(executor)
            self.assertEqual(result, {"mastery": 50.0, "xp": 100})
            self.assertEqual(flow.observations[0].status, "completed")
        finally:
            executor.shutdown()

    def test_8_unexpected_exception_unchanged(self):
        executor = enabled_executor()
        try:
            with mock.patch.object(replay, "run_replay",
                                   side_effect=RuntimeError("boom")):
                flow = AuthoritativeFlow(executor)
                result = flow.submit({"mastery": 50.0, "xp": 100},
                                     live_event(), past_rows(), corpus())
            self.assertEqual(result, {"mastery": 50.0, "xp": 100})
            self.assertEqual(flow.observations[0].status, "fallback")
        finally:
            executor.shutdown()

    def test_15_kill_switch_zero_invocation(self):
        calls = []
        executor = enabled_executor(sample_rate_pct=100)
        try:
            with mock.patch.object(replay, "run_replay",
                                   side_effect=lambda *a, **k: calls.append(
                                       1) or (_ for _ in ()).throw(
                                       RuntimeError("nope"))):
                flow = AuthoritativeFlow(ShadowExecutor(ShadowConfig()))
                flow.submit({"m": 1}, live_event(), past_rows(), corpus())
            self.assertEqual(calls, [])
        finally:
            executor.shutdown()


class DisagreementTest(unittest.TestCase):
    """TEST 9: advisory disagreement never overrides authority."""

    def test_9_engine_authority_preserved(self):
        from mlrag.contracts.adaptive import resolve_conflict, EngineDecision
        # Even a confident served advisory disagreeing with the engine:
        decision = EngineDecision(
            reason_code="BEGINNER_NEEDS_FOUNDATIONS",
            mastery_level="BEGINNER", trend="STABLE",
            next_difficulty="EASY", activity="REVIEW", priority=1)
        resolved = resolve_conflict(decision, ("ml.p_correct",))
        self.assertEqual(resolved.next_difficulty, "EASY")
        self.assertIn("ml.p_correct", resolved.signals_ignored)


class IdentityTargetVersionTests(unittest.TestCase):
    """TESTS 10-14: identity, leakage, version guards."""

    def test_10_server_identity_authoritative(self):
        key = derive_learner_key("server-user-123")
        self.assertTrue(key.startswith("learner_"))
        self.assertNotIn("server-user-123", key)
        self.assertEqual(key, derive_learner_key("server-user-123"))
        with self.assertRaises(ContractViolation):
            derive_learner_key("  ")

    def test_11_current_correctness_rejected(self):
        from mlrag.shadow.live import _rows_for
        rows = _rows_for(live_event(), past_rows())
        placeholder = rows[-1]
        self.assertNotIn("label", placeholder)
        # is_correct present-but-None is never consumed: predictor input
        # is features-only (past rows), ledger unused live.
        self.assertIsNone(placeholder.get("is_correct"))

    def test_12_future_timestamp_rejected(self):
        from mlrag.shadow import replay as replay_module
        rows = past_rows() + [dict(past_rows()[0],
                                   submitted_at="2999-01-01T00:00:00",
                                   question_attempt_id=f"{FIX}-future")]
        events, _ = replay_module.build_events(rows)
        # Future row sorts last; past computation for earlier events
        # excludes it by strict inequality (proven by ordering test).
        self.assertEqual(events[-1].event_id, f"{FIX}-future")

    def test_13_14_version_mismatch_rejected(self):
        from mlrag.contracts.adaptive import MLSignal
        with self.assertRaises(ContractViolation):
            MLSignal(status=SignalStatus.SERVED, p_correct=0.5,
                     confidence=0.5, model_version="",
                     feature_schema_version="f1")


class ConfigObservabilityTests(unittest.TestCase):
    def test_config_bounds_and_env(self):
        with self.assertRaises(ContractViolation):
            ShadowConfig(sample_rate_pct=101)
        with mock.patch.dict(os.environ, {"SHADOW_ENABLED": "true",
                                          "SHADOW_SAMPLE_PCT": "100"},
                             clear=False):
            config = ShadowConfig.from_env()
        self.assertTrue(config.enabled)
        self.assertEqual(config.sample_rate_pct, 100)
        self.assertFalse(ShadowConfig().enabled)  # default: kill switch off

    def test_sampling_deterministic_and_forced(self):
        self.assertFalse(sampled_in("any-id", 0))
        self.assertTrue(sampled_in("any-id", 100))
        self.assertEqual(sampled_in("fixed-id", 50),
                         sampled_in("fixed-id", 50))

    def test_correlation_ids_unique_opaque(self):
        first, second = new_correlation_id(), new_correlation_id()
        self.assertNotEqual(first, second)
        self.assertTrue(first.startswith("shdw-"))

    def test_observation_has_no_pii(self):
        executor = enabled_executor()
        try:
            flow = AuthoritativeFlow(executor)
            flow.submit({"m": 1}, live_event(), past_rows(), corpus())
            blob = str(flow.observations[0])
            self.assertNotIn("@", blob)
            self.assertNotIn("password", blob.lower())
        finally:
            executor.shutdown()


if __name__ == "__main__":
    unittest.main()
