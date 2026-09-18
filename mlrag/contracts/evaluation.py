"""Evaluation-harness specification as code (GATE 1).

Defines the STRUCTURE of future evaluation — dataset units, labels, split
policy, baselines, metric placeholders, reproducibility.  No training, no
data, no metric computation happens here.
"""

from __future__ import annotations

from dataclasses import dataclass

from .common import ContractViolation

#: Primary supervised unit first; attempt-level aggregates secondary.
PRIMARY_DATASET_UNIT = "question_attempt"


class DatasetUnit(str):
    """Dataset row granularity (string constants, kept open for extension)."""

    QUESTION_ATTEMPT = "question_attempt"
    QUIZ_ATTEMPT = "quiz_attempt"


#: Metric placeholders — names only; computed by the future harness.
CLASSIFICATION_METRICS = frozenset(
    {
        "accuracy",
        "precision",
        "recall",
        "f1",
        "roc_auc",
        "pr_auc",
        "log_loss",
        "brier_score",
        "calibration_error",
    }
)
RANKING_METRICS = frozenset(
    {"precision_at_k", "recall_at_k", "ndcg_at_k", "mrr"}
)
REGRESSION_METRICS = frozenset({"mae", "rmse", "calibration_error"})


@dataclass(frozen=True)
class LabelDefinition:
    """One supervised label, pinned to its authoritative source column."""

    name: str
    source_table: str
    source_column: str
    task_type: str  # e.g. "binary_classification"

    def __post_init__(self) -> None:
        for field_name in ("name", "source_table", "source_column", "task_type"):
            if not getattr(self, field_name).strip():
                raise ContractViolation(f"{field_name} must be non-empty")


#: Approved initial labels (authoritative quiz lineage only).
APPROVED_LABELS = (
    LabelDefinition(
        name="is_correct",
        source_table="question_attempts",
        source_column="is_correct",
        task_type="binary_classification",
    ),
    LabelDefinition(
        name="quiz_score",
        source_table="quiz_attempts",
        source_column="score",
        task_type="regression",
    ),
)


@dataclass(frozen=True)
class SplitPolicy:
    """Leakage-safe splitting: user-aware AND time-aware, always.

    Naive random row splits are prohibited as the primary strategy:
    attempts from one learner in both train and test inflate metrics.
    """

    strategy: str
    training_end_iso: str
    validation_end_iso: str
    user_isolation: bool = True
    min_history_attempts: int = 0

    def __post_init__(self) -> None:
        if self.strategy != "user_aware_time_aware":
            raise ContractViolation(
                "split strategy must be 'user_aware_time_aware' "
                "(random row splits leak learner identity)"
            )
        if not self.user_isolation:
            raise ContractViolation("user_isolation must stay enabled")
        if not self.training_end_iso.strip() or not self.validation_end_iso.strip():
            raise ContractViolation("split periods must be defined")
        if self.training_end_iso >= self.validation_end_iso:
            raise ContractViolation(
                "training period must end before validation period "
                "(temporal ordering)"
            )
        if self.min_history_attempts < 0:
            raise ContractViolation("min_history_attempts must be >= 0")


@dataclass(frozen=True)
class BaselineRequirement:
    """A deterministic baseline the candidate must be compared against."""

    name: str
    must_beat_metric: str

    def __post_init__(self) -> None:
        if not self.name.strip() or not self.must_beat_metric.strip():
            raise ContractViolation("baseline name and metric must be non-empty")


#: Baselines that must exist before any sophisticated model is accepted.
REQUIRED_BASELINES = (
    BaselineRequirement(name="majority_class", must_beat_metric="accuracy"),
    BaselineRequirement(name="recent_accuracy", must_beat_metric="log_loss"),
    BaselineRequirement(
        name="deterministic_adaptive", must_beat_metric="brier_score"
    ),
)


@dataclass(frozen=True)
class EvalSpec:
    """Complete, reproducible evaluation specification for one experiment."""

    dataset_unit: str
    labels: tuple[LabelDefinition, ...]
    split: SplitPolicy
    baselines: tuple[BaselineRequirement, ...]
    classification_metrics: frozenset[str] = frozenset({"accuracy", "log_loss"})
    ranking_metrics: frozenset[str] = frozenset()
    regression_metrics: frozenset[str] = frozenset()
    seed: int = 42
    code_version: str = ""
    data_snapshot_id: str = ""
    cold_start_policy: str = "deterministic_fallback_below_min_history"

    def __post_init__(self) -> None:
        if self.dataset_unit not in (
            DatasetUnit.QUESTION_ATTEMPT,
            DatasetUnit.QUIZ_ATTEMPT,
        ):
            raise ContractViolation(f"unknown dataset_unit: {self.dataset_unit}")
        if not self.labels:
            raise ContractViolation("at least one label is required")
        if not self.baselines:
            raise ContractViolation("baselines are required (no model without)")
        unknown = (
            set(self.classification_metrics) - CLASSIFICATION_METRICS
        ) | (set(self.ranking_metrics) - RANKING_METRICS) | (
            set(self.regression_metrics) - REGRESSION_METRICS
        )
        if unknown:
            raise ContractViolation("unknown metrics: " + ", ".join(sorted(unknown)))
        if not self.code_version.strip():
            raise ContractViolation("code_version is required (reproducibility)")
        if not self.data_snapshot_id.strip():
            raise ContractViolation(
                "data_snapshot_id is required (reproducibility)"
            )
        if not self.cold_start_policy.strip():
            raise ContractViolation("cold_start_policy is required")
