"""Challenger E: constrained random forest on f1 (GATE 24).

Frozen configuration from :mod:`mlrag.learner_intelligence.config24`.
Same bundle discipline as the Gate 19 LR challenger:

* ``fit`` reads training rows only (frozen train-only preprocessor,
  labels from ``is_correct``).  Single-class/empty training raises.
* ``predict_proba`` returns one validated ``p_correct`` per row.
* ``importances`` exposes impurity-based importances aligned to
  ``MATRIX_COLUMNS`` for engineering review (direction-free; no causal
  claims).
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from typing import Any

from sklearn.ensemble import RandomForestClassifier

from ..contracts.common import ContractViolation
from ..modeling import config as g19_config
from ..modeling import preprocessing
from . import config24


@dataclass
class ForestBundle:
    """Fitted preprocessor + forest + train rate.  Experimental only."""

    preprocessor: preprocessing.FittedPreprocessor
    model: RandomForestClassifier
    train_rate: float
    model_id: str = config24.MODEL_ID
    model_version: str = config24.MODEL_VERSION
    n_train_rows: int = 0
    train_positives: int = 0
    train_negatives: int = 0

    def parameter_record(self) -> dict[str, Any]:
        """JSON-safe model parameters (no data, no PII, no labels)."""
        return {
            "model_id": self.model_id,
            "model_version": self.model_version,
            "model_family": "RandomForestClassifier",
            "feature_version": config24.FEATURE_VERSION,
            "dataset_version": config24.DATASET_VERSION,
            "n_estimators": config24.N_ESTIMATORS,
            "max_depth": config24.MAX_DEPTH,
            "min_samples_split": config24.MIN_SAMPLES_SPLIT,
            "min_samples_leaf": config24.MIN_SAMPLES_LEAF,
            "max_features": config24.MAX_FEATURES,
            "random_state": config24.RANDOM_STATE,
            "n_jobs": config24.N_JOBS,
            "matrix_columns": list(g19_config.MATRIX_COLUMNS),
            "feature_importances": [float(v) for v in self.model.feature_importances_],
            "train_rate": self.train_rate,
            "n_train_rows": self.n_train_rows,
            "train_positives": self.train_positives,
            "train_negatives": self.train_negatives,
        }


def fit(train_rows: list[dict]) -> ForestBundle:
    """Fit preprocessing + constrained forest on training rows only."""
    from ..modeling.baselines import fit_global_rate

    if not train_rows:
        raise ContractViolation("cannot fit challenger on zero rows")
    labels = []
    for row in train_rows:
        target = row.get("is_correct")
        if target not in (0, 1) or isinstance(target, bool):
            raise ContractViolation(
                f"training target must be 0/1, got {target!r}")
        labels.append(int(target))
    positives = sum(labels)
    negatives = len(labels) - positives
    if positives < 2 or negatives < 2:
        # A forest needs both classes with room for bagged splits;
        # single-class (or single-negative) training raises loudly.
        raise ContractViolation(
            "cannot fit forest challenger without both classes present "
            f"(pos={positives}, neg={negatives})")
    preprocessor = preprocessing.fit(train_rows)
    matrix = preprocessor.transform(train_rows)
    model = RandomForestClassifier(
        n_estimators=config24.N_ESTIMATORS,
        max_depth=config24.MAX_DEPTH,
        min_samples_split=config24.MIN_SAMPLES_SPLIT,
        min_samples_leaf=config24.MIN_SAMPLES_LEAF,
        max_features=config24.MAX_FEATURES,
        random_state=config24.RANDOM_STATE,
        n_jobs=config24.N_JOBS,
    )
    model.fit(matrix, labels)
    return ForestBundle(
        preprocessor=preprocessor,
        model=model,
        train_rate=fit_global_rate(train_rows),
        n_train_rows=len(train_rows),
        train_positives=positives,
        train_negatives=negatives,
    )


def predict_proba(bundle: ForestBundle, rows: list[dict]) -> list[float]:
    """Validated p_correct for each row (finite, within [0,1])."""
    if not rows:
        return []
    matrix = bundle.preprocessor.transform(rows)
    raw = bundle.model.predict_proba(matrix)[:, 1]
    out: list[float] = []
    for prob in raw:
        value = float(prob)
        if not math.isfinite(value) or not 0.0 <= value <= 1.0:
            raise ContractViolation(f"invalid model probability: {prob!r}")
        out.append(value)
    return out


def importances(bundle: ForestBundle) -> list[dict]:
    """Per-column importances in MATRIX_COLUMNS order (review only)."""
    values = [float(v) for v in bundle.model.feature_importances_]
    ranked = sorted(
        ({"column": name, "importance": value}
         for name, value in zip(g19_config.MATRIX_COLUMNS, values)),
        key=lambda d: -d["importance"],
    )
    return ranked
