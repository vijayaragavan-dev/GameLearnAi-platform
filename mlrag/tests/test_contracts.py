"""Architecture-level contract tests for the ML/RAG sidecar (GATE 1).

Standard library only (unittest).  These tests verify contract SHAPE,
validation, and leakage separation.  They do NOT test any model, retrieval
backend, embedding, Gemini, or external service — none exists.

Run from the repository root::

    python -m unittest discover -s mlrag/tests -v
"""

from __future__ import annotations

import dataclasses
import os
import unittest
from unittest import mock

from mlrag import config as config_module
from mlrag.config import SidecarConfig
from mlrag.contracts import (
    ContractViolation,
    Difficulty,
    EvalSpec,
    ModelVersion,
    PreAttemptFeatures,
    PredictionRequest,
    PredictionResponse,
    PredictionTarget,
    RetrievedChunk,
    RetrievalRequest,
    RetrievalResponse,
    RetrieverPort,
    PredictorPort,
    ScopeFilter,
    SplitPolicy,
    TraceContext,
    validate_feature_names,
)


def make_features(**overrides) -> PreAttemptFeatures:
    base = {
        "user_key": "user-1",
        "subject_id": "subject-1",
        "topic_id": "topic-1",
        "question_id": "question-1",
        "quiz_id": "quiz-1",
        "question_difficulty": Difficulty.MEDIUM,
        "quiz_difficulty": Difficulty.MEDIUM,
        "prior_attempt_count": 3,
        "prior_correct_count": 7,
        "prior_total_count": 12,
        "prev_mastery_score": 58.33,
        "prev_recent_accuracy": 66.67,
        "prev_trend": "STABLE",
        "prev_difficulty": Difficulty.MEDIUM,
        "predicted_at_iso": "2026-09-13T00:00:00Z",
    }
    base.update(overrides)
    return PreAttemptFeatures(**base)


def make_scope(**overrides) -> ScopeFilter:
    base = {"subject_id": "subject-1", "topic_id": "topic-1"}
    base.update(overrides)
    return ScopeFilter(**base)


def make_chunk(scope_subject="subject-1", scope_topic="topic-1") -> RetrievedChunk:
    return RetrievedChunk(
        chunk_id="chunk-1",
        source_table="lessons",
        source_id="lesson-1",
        subject_id=scope_subject,
        topic_id=scope_topic,
        unit_id=None,
        content_version="v1",
        is_active=True,
        text="Photosynthesis converts light energy.",
        score=0.91,
        citation="lessons:lesson-1#v1",
    )


class PredictorContractTest(unittest.TestCase):
    def test_valid_features_instantiate(self):
        features = make_features()
        self.assertEqual(features.prior_attempt_count, 3)

    def test_cold_start_features_instantiate_without_history(self):
        features = make_features(
            prior_attempt_count=0,
            prior_correct_count=None,
            prior_total_count=None,
            prev_mastery_score=None,
            prev_recent_accuracy=None,
            prev_trend="INSUFFICIENT_DATA",
            prev_difficulty=None,
        )
        self.assertIsNone(features.prev_mastery_score)

    def test_missing_identity_rejected(self):
        with self.assertRaises(ContractViolation):
            make_features(user_key="  ")

    def test_negative_counts_rejected(self):
        with self.assertRaises(ContractViolation):
            make_features(prior_attempt_count=-1)

    def test_out_of_range_mastery_rejected(self):
        with self.assertRaises(ContractViolation):
            make_features(prev_mastery_score=100.01)

    def test_unknown_trend_rejected(self):
        with self.assertRaises(ContractViolation):
            make_features(prev_trend="SOARING")

    def test_valid_model_response(self):
        response = PredictionResponse(
            request_id="req-1",
            served_by_model=True,
            p_correct=0.72,
            confidence=0.8,
            model=ModelVersion(model_name="baseline", model_version="0.0.0"),
        )
        self.assertTrue(0.0 <= response.p_correct <= 1.0)

    def test_model_response_without_probability_rejected(self):
        with self.assertRaises(ContractViolation):
            PredictionResponse(request_id="req-1", served_by_model=True)

    def test_model_response_without_version_rejected(self):
        with self.assertRaises(ContractViolation):
            PredictionResponse(
                request_id="req-1", served_by_model=True, p_correct=0.5
            )

    def test_fallback_must_not_carry_prediction(self):
        with self.assertRaises(ContractViolation):
            PredictionResponse(
                request_id="req-1",
                served_by_model=False,
                p_correct=0.5,
                fallback_reason="cold_start",
            )

    def test_fallback_requires_reason(self):
        with self.assertRaises(ContractViolation):
            PredictionResponse(request_id="req-1", served_by_model=False)

    def test_valid_fallback(self):
        response = PredictionResponse(
            request_id="req-1",
            served_by_model=False,
            fallback_reason="insufficient_history",
        )
        self.assertIsNone(response.p_correct)

    def test_port_is_abstract(self):
        with self.assertRaises(TypeError):
            PredictorPort()  # type: ignore[abstract]

    def test_request_binds_trace_features_target(self):
        request = PredictionRequest(
            trace=TraceContext(request_id="req-9"),
            features=make_features(),
            target=PredictionTarget.CORRECTNESS,
        )
        self.assertEqual(request.trace.request_id, "req-9")


class StubPredictor(PredictorPort):
    """Minimal future-implementation shape (no model inside)."""

    @property
    def model_version(self) -> ModelVersion:
        return ModelVersion(model_name="stub", model_version="0.0.0-test")

    def supports(self, features: PreAttemptFeatures) -> bool:
        return features.prior_attempt_count >= 2

    def predict(self, request: PredictionRequest) -> PredictionResponse:
        if not self.supports(request.features):
            return PredictionResponse(
                request_id=request.trace.request_id,
                served_by_model=False,
                fallback_reason="insufficient_history",
            )
        return PredictionResponse(
            request_id=request.trace.request_id,
            served_by_model=True,
            p_correct=0.5,
            model=self.model_version,
        )


class PredictorPortTest(unittest.TestCase):
    def test_future_implementation_shape(self):
        stub = StubPredictor()
        cold = PredictionRequest(
            trace=TraceContext(request_id="r-cold"), features=make_features(
                prior_attempt_count=0
            ),
        )
        self.assertFalse(stub.predict(cold).served_by_model)
        warm = PredictionRequest(
            trace=TraceContext(request_id="r-warm"),
            features=make_features(prior_attempt_count=5),
        )
        served = stub.predict(warm)
        self.assertTrue(served.served_by_model)
        self.assertEqual(served.model.model_name, "stub")


class RetrieverContractTest(unittest.TestCase):
    def test_scope_requires_subject(self):
        with self.assertRaises(ContractViolation):
            ScopeFilter(subject_id=" ")

    def test_scope_rejects_inactive_serving(self):
        with self.assertRaises(ContractViolation):
            ScopeFilter(subject_id="s", active_only=False)

    def test_request_validation(self):
        request = RetrievalRequest(
            trace=TraceContext(request_id="r-1"),
            scope=make_scope(),
            query="what is photosynthesis?",
            top_k=5,
            source_tables=("lessons",),
        )
        self.assertEqual(request.top_k, 5)

    def test_empty_query_rejected(self):
        with self.assertRaises(ContractViolation):
            RetrievalRequest(
                trace=TraceContext(request_id="r-1"),
                scope=make_scope(),
                query="  ",
            )

    def test_top_k_bounds_rejected(self):
        with self.assertRaises(ContractViolation):
            RetrievalRequest(
                trace=TraceContext(request_id="r-1"),
                scope=make_scope(),
                query="q",
                top_k=0,
            )

    def test_unapproved_source_rejected(self):
        with self.assertRaises(ContractViolation):
            RetrievalRequest(
                trace=TraceContext(request_id="r-1"),
                scope=make_scope(),
                query="q",
                source_tables=("user_uploads",),
            )

    def test_chunk_scope_validation_passes(self):
        response = RetrievalResponse(
            request_id="r-1",
            served=True,
            chunks=(make_chunk(),),
            retriever_version="none-0.0.0",
        )
        response.validate_against(make_scope())  # must not raise

    def test_chunk_cross_subject_rejected(self):
        response = RetrievalResponse(
            request_id="r-1",
            served=True,
            chunks=(make_chunk(scope_subject="subject-9"),),
            retriever_version="none-0.0.0",
        )
        with self.assertRaises(ContractViolation):
            response.validate_against(make_scope())

    def test_chunk_cross_topic_rejected(self):
        response = RetrievalResponse(
            request_id="r-1",
            served=True,
            chunks=(make_chunk(scope_topic="topic-9"),),
            retriever_version="none-0.0.0",
        )
        with self.assertRaises(ContractViolation):
            response.validate_against(make_scope())

    def test_inactive_chunk_rejected(self):
        with self.assertRaises(ContractViolation):
            RetrievedChunk(
                chunk_id="c",
                source_table="lessons",
                source_id="l",
                subject_id="s",
                topic_id="t",
                unit_id=None,
                content_version="v1",
                is_active=False,
                text="x",
                score=0.1,
                citation="lessons:l#v1",
            )

    def test_unserved_requires_empty_reason(self):
        with self.assertRaises(ContractViolation):
            RetrievalResponse(request_id="r-1", served=False)
        response = RetrievalResponse(
            request_id="r-1", served=False, empty_reason="no_chunks"
        )
        self.assertEqual(response.empty_reason, "no_chunks")

    def test_port_is_abstract(self):
        with self.assertRaises(TypeError):
            RetrieverPort()  # type: ignore[abstract]


class LeakageContractTest(unittest.TestCase):
    def test_safe_names_accepted(self):
        names = validate_feature_names(
            ["prev_mastery_score", "quiz_difficulty", "topic_id"]
        )
        self.assertEqual(len(names), 3)

    def test_post_attempt_names_rejected(self):
        for blocked in (
            "score",
            "is_correct",
            "recent_accuracy",
            "mastery_score",
            "selected_answer",
            "recommendation_current",
            "response_time_seconds",
            "duration_seconds",
            "game_score",
        ):
            with self.assertRaises(
                ContractViolation, msg=f"blocked field accepted: {blocked}"
            ):
                validate_feature_names(["topic_id", blocked])

    def test_strict_mode_rejects_unknown(self):
        with self.assertRaises(ContractViolation):
            validate_feature_names(["topic_id", "mystery_signal"], strict=True)

    def test_contract_field_names_are_leak_free(self):
        field_names = [
            f.name for f in dataclasses.fields(PreAttemptFeatures)
        ]
        validate_feature_names(field_names, strict=True)


class NoMutationTest(unittest.TestCase):
    def test_contracts_are_frozen(self):
        features = make_features()
        with self.assertRaises(dataclasses.FrozenInstanceError):
            features.prior_attempt_count = 99  # type: ignore[misc]
        scope = make_scope()
        with self.assertRaises(dataclasses.FrozenInstanceError):
            scope.subject_id = "other"  # type: ignore[misc]


def make_eval_spec(**overrides) -> EvalSpec:
    base = {
        "dataset_unit": "question_attempt",
        "labels": (
            __import__(
                "mlrag.contracts.evaluation", fromlist=["LabelDefinition"]
            ).LabelDefinition(
                name="is_correct",
                source_table="question_attempts",
                source_column="is_correct",
                task_type="binary_classification",
            ),
        ),
        "split": SplitPolicy(
            strategy="user_aware_time_aware",
            training_end_iso="2026-06-01T00:00:00Z",
            validation_end_iso="2026-07-01T00:00:00Z",
            user_isolation=True,
            min_history_attempts=2,
        ),
        "baselines": (
            __import__(
                "mlrag.contracts.evaluation", fromlist=["BaselineRequirement"]
            ).BaselineRequirement(
                name="recent_accuracy", must_beat_metric="log_loss"
            ),
        ),
        "code_version": "mlrag-0.1.0-gate1",
        "data_snapshot_id": "snapshot-001",
    }
    base.update(overrides)
    return EvalSpec(**base)


class EvaluationContractTest(unittest.TestCase):
    def test_valid_spec(self):
        spec = make_eval_spec()
        self.assertEqual(spec.dataset_unit, "question_attempt")

    def test_random_split_rejected(self):
        with self.assertRaises(ContractViolation):
            SplitPolicy(
                strategy="random_row",
                training_end_iso="2026-06-01T00:00:00Z",
                validation_end_iso="2026-07-01T00:00:00Z",
            )

    def test_user_isolation_required(self):
        with self.assertRaises(ContractViolation):
            SplitPolicy(
                strategy="user_aware_time_aware",
                training_end_iso="2026-06-01T00:00:00Z",
                validation_end_iso="2026-07-01T00:00:00Z",
                user_isolation=False,
            )

    def test_inverted_periods_rejected(self):
        with self.assertRaises(ContractViolation):
            SplitPolicy(
                strategy="user_aware_time_aware",
                training_end_iso="2026-07-01T00:00:00Z",
                validation_end_iso="2026-06-01T00:00:00Z",
            )

    def test_unknown_metric_rejected(self):
        with self.assertRaises(ContractViolation):
            make_eval_spec(classification_metrics=frozenset({"vibes"}))

    def test_baselines_required(self):
        with self.assertRaises(ContractViolation):
            make_eval_spec(baselines=())

    def test_reproducibility_fields_required(self):
        with self.assertRaises(ContractViolation):
            make_eval_spec(code_version=" ")
        with self.assertRaises(ContractViolation):
            make_eval_spec(data_snapshot_id="")


class ConfigBoundaryTest(unittest.TestCase):
    def test_defaults_disabled_and_secret_free(self):
        cfg = SidecarConfig()
        self.assertFalse(cfg.enabled)
        for value in (
            cfg.model_version_expected,
            cfg.log_level,
        ):
            self.assertNotIn("sk-", value)
            self.assertNotIn("key", value.lower())

    def test_from_env_reads_prefixed_values(self):
        with mock.patch.dict(
            os.environ,
            {
                "MLRAG_ENABLED": "true",
                "MLRAG_MAX_TOP_K": "7",
                "MLRAG_LOG_LEVEL": "warning",
            },
            clear=False,
        ):
            cfg = SidecarConfig.from_env()
        self.assertTrue(cfg.enabled)
        self.assertEqual(cfg.max_top_k, 7)
        self.assertEqual(cfg.log_level, "WARNING")

    def test_invalid_values_rejected(self):
        with self.assertRaises(ContractViolation):
            SidecarConfig(predict_timeout_ms=0)
        with self.assertRaises(ContractViolation):
            SidecarConfig(max_top_k=51)
        with self.assertRaises(ContractViolation):
            SidecarConfig(log_level="VERBOSE")

    def test_config_is_frozen(self):
        cfg = SidecarConfig()
        with self.assertRaises(dataclasses.FrozenInstanceError):
            cfg.enabled = True  # type: ignore[misc]


if __name__ == "__main__":
    unittest.main()
