"""Adaptive-intelligence design-contract tests (GATE 8). Stdlib only.

Validates the advisory-vs-authoritative boundary in code: bounded
signals, version presence, fallback semantics, engine-wins conflicts,
cold-start tiers, ranking-vs-decision separation, frozen contracts.
No database, services, models, or production paths.

Run: python -m unittest mlrag.tests.test_adaptive_design -v
"""

from __future__ import annotations

import dataclasses
import unittest

from mlrag.contracts.adaptive import (
    AdvisoryBundle,
    DifficultySignal,
    EngineDecision,
    HistoryTier,
    MLSignal,
    RAGEvidence,
    RankedCandidate,
    ShadowRecord,
    SignalStatus,
    classify_history,
    rank_candidates,
    resolve_conflict,
)
from mlrag.contracts.common import ContractViolation


def ml_signal(**over) -> MLSignal:
    base = {"status": SignalStatus.SERVED, "p_correct": 0.82,
            "confidence": 0.7, "model_version": "logreg-pcorrect-v1",
            "feature_schema_version": "f1"}
    base.update(over)
    return MLSignal(**base)


def rag_evidence(**over) -> RAGEvidence:
    base = {"status": SignalStatus.SERVED,
            "citations": ("lessons:abc#c0",), "subject_id": "s1",
            "retriever_version": "lexical-tfidf-0.1.0",
            "grounding_valid": True}
    base.update(over)
    return RAGEvidence(**base)


def engine_decision(**over) -> EngineDecision:
    base = {"reason_code": "DEVELOPING_KEEP_PRACTICING",
            "mastery_level": "DEVELOPING", "trend": "STABLE",
            "next_difficulty": "MEDIUM", "activity": "PRACTICE", "priority": 2}
    base.update(over)
    return EngineDecision(**base)


class SignalBoundsTest(unittest.TestCase):
    def test_valid_served_signals(self):
        self.assertAlmostEqual(ml_signal().p_correct, 0.82)
        self.assertTrue(rag_evidence().grounding_valid)

    def test_probability_bounds_rejected(self):
        for bad in (-0.1, 1.1, float("nan"), float("inf")):
            with self.assertRaises(ContractViolation, msg=str(bad)):
                ml_signal(p_correct=bad)

    def test_versions_required_when_served(self):
        with self.assertRaises(ContractViolation):
            ml_signal(model_version="  ")
        with self.assertRaises(ContractViolation):
            ml_signal(feature_schema_version="")
        with self.assertRaises(ContractViolation):
            rag_evidence(retriever_version="")

    def test_fallback_carries_no_prediction(self):
        with self.assertRaises(ContractViolation):
            MLSignal(status=SignalStatus.FALLBACK_COLD_START,
                     p_correct=0.5, fallback_reason="cold")
        fallback = MLSignal(status=SignalStatus.FALLBACK_COLD_START,
                            fallback_reason="no history")
        self.assertIsNone(fallback.p_correct)
        with self.assertRaises(ContractViolation):
            MLSignal(status=SignalStatus.FALLBACK_TIMEOUT,
                     fallback_reason="  ")

    def test_rag_served_requires_grounding_and_citations(self):
        with self.assertRaises(ContractViolation):
            rag_evidence(grounding_valid=False)
        with self.assertRaises(ContractViolation):
            rag_evidence(citations=())
        with self.assertRaises(ContractViolation):
            rag_evidence(subject_id=" ")

    def test_difficulty_hint_spelling_and_basis(self):
        hint = DifficultySignal(suggested="MEDIUM", basis="p=0.82")
        self.assertEqual(hint.suggested, "MEDIUM")
        with self.assertRaises(ContractViolation):
            DifficultySignal(suggested="EXTREME", basis="x")
        with self.assertRaises(ContractViolation):
            DifficultySignal(suggested="EASY", basis="  ")


class ConflictRuleTest(unittest.TestCase):
    def test_engine_wins_records_ignored(self):
        decision = engine_decision(signals_consumed=("ml.p_correct",))
        resolved = resolve_conflict(decision, ("rag.evidence",))
        self.assertEqual(resolved.mastery_level, "DEVELOPING")
        self.assertEqual(resolved.next_difficulty, "MEDIUM")
        self.assertEqual(resolved.reason_code,
                         "DEVELOPING_KEEP_PRACTICING")
        self.assertEqual(resolved.signals_ignored, ("rag.evidence",))
        self.assertEqual(resolved.signals_consumed, ("ml.p_correct",))

    def test_unknown_reason_code_rejected(self):
        with self.assertRaises(ContractViolation):
            engine_decision(reason_code="ML_SAYS_ADVANCE")


class ColdStartTest(unittest.TestCase):
    def test_tiers(self):
        self.assertEqual(classify_history(0), HistoryTier.COLD_START)
        self.assertEqual(classify_history(2), HistoryTier.SPARSE_HISTORY)
        self.assertEqual(classify_history(3), HistoryTier.SUFFICIENT_HISTORY)
        with self.assertRaises(ContractViolation):
            classify_history(-1)


class RankingSeparationTest(unittest.TestCase):
    def test_eligible_first_score_desc_id_tiebreak(self):
        candidates = [
            RankedCandidate("c2", True, 0.5),
            RankedCandidate("c1", True, 0.5),
            RankedCandidate("c0", False, 0.9,
                            ineligibility_reasons=("inactive",)),
            RankedCandidate("c3", True, None),
        ]
        ordered = [c.content_id for c in rank_candidates(candidates)]
        self.assertEqual(ordered, ["c1", "c2", "c3", "c0"])

    def test_eligibility_rules(self):
        with self.assertRaises(ContractViolation):
            RankedCandidate("c", True, 0.5,
                            ineligibility_reasons=("x",))
        with self.assertRaises(ContractViolation):
            RankedCandidate("c", False, 0.5)
        with self.assertRaises(ContractViolation):
            RankedCandidate("c", True, 1.5)


class BundleShadowTest(unittest.TestCase):
    def test_bundle_binds_snapshot_as_informational(self):
        bundle = AdvisoryBundle(
            learner_key="learner_x", topic_id="t1", ml=ml_signal(),
            rag=rag_evidence(), engine_snapshot_level="DEVELOPING",
            engine_snapshot_trend="STABLE", created_at_iso="2026-09-13T00:00:00Z")
        self.assertEqual(bundle.engine_snapshot_level, "DEVELOPING")

    def test_shadow_record_outcome_optional(self):
        record = ShadowRecord(advisory=AdvisoryBundle(
            learner_key="k", topic_id="t", ml=ml_signal(),
            rag=rag_evidence(), engine_snapshot_level="L1",
            engine_snapshot_trend="S", created_at_iso="now"),
            decision=engine_decision())
        self.assertIsNone(record.outcome_correct)
        graded = ShadowRecord(advisory=record.advisory,
                              decision=record.decision, outcome_correct=True)
        self.assertTrue(graded.outcome_correct)

    def test_contracts_frozen(self):
        signal = ml_signal()
        with self.assertRaises(dataclasses.FrozenInstanceError):
            signal.p_correct = 0.1  # type: ignore[misc]


if __name__ == "__main__":
    unittest.main()
