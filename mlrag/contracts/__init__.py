"""Typed contract surfaces for the ML/RAG sidecar (GATE 1)."""

from .common import (
    ContractViolation,
    Difficulty,
    ModelVersion,
    PredictionTarget,
    TraceContext,
)
from .evaluation import (
    APPROVED_LABELS,
    CLASSIFICATION_METRICS,
    RANKING_METRICS,
    REGRESSION_METRICS,
    REQUIRED_BASELINES,
    BaselineRequirement,
    DatasetUnit,
    EvalSpec,
    LabelDefinition,
    SplitPolicy,
)
from .leakage import (
    POST_ATTEMPT_BLOCKLIST,
    PRE_ATTEMPT_ALLOWLIST,
    validate_feature_mapping,
    validate_feature_names,
)
from .predictor import (
    PreAttemptFeatures,
    PredictionRequest,
    PredictionResponse,
    PredictorPort,
)
from .retriever import (
    APPROVED_SOURCE_TABLES,
    RetrievedChunk,
    RetrievalRequest,
    RetrievalResponse,
    RetrieverPort,
    ScopeFilter,
)

__all__ = [
    "APPROVED_LABELS",
    "APPROVED_SOURCE_TABLES",
    "CLASSIFICATION_METRICS",
    "POST_ATTEMPT_BLOCKLIST",
    "PRE_ATTEMPT_ALLOWLIST",
    "RANKING_METRICS",
    "REGRESSION_METRICS",
    "REQUIRED_BASELINES",
    "BaselineRequirement",
    "ContractViolation",
    "DatasetUnit",
    "Difficulty",
    "EvalSpec",
    "LabelDefinition",
    "ModelVersion",
    "PreAttemptFeatures",
    "PredictionRequest",
    "PredictionResponse",
    "PredictionTarget",
    "RetrievedChunk",
    "RetrievalRequest",
    "RetrievalResponse",
    "RetrieverPort",
    "PredictorPort",
    "ScopeFilter",
    "SplitPolicy",
    "TraceContext",
    "validate_feature_mapping",
    "validate_feature_names",
]
