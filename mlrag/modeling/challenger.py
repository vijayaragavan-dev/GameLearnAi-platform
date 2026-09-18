"""The ONE first challenger: L2 logistic regression on f1 (GATE 19).

Frozen configuration from :mod:`mlrag.modeling.config` (C=1.0, lbfgs,
max_iter=1000, random_state=42).  No tuning, no alternatives, no families.

* ``fit`` reads training rows only (features via the fitted
  preprocessor, labels from ``is_correct``).  Single-class training
  input raises loudly instead of producing a degenerate model.
* ``predict_proba`` returns one validated ``p_correct`` per row;
  non-finite or out-of-[0,1] values raise (never shipped).
* Coverage: every row carrying a valid f1 vector is served (cold-start
  rows included — NULLs flow through the documented train-median path);
  coverage accounting lives in the experiment layer.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Any

from sklearn.linear_model import LogisticRegression

from ..contracts.common import ContractViolation
from . import config, preprocessing


@dataclass
class ChallengerBundle:
    """Fitted preprocessor + model + train rate.  Experimental only."""

    preprocessor: preprocessing.FittedPreprocessor
    model: LogisticRegression
    train_rate: float
    model_id: str = config.MODEL_ID
    model_version: str = config.MODEL_VERSION

    def coefficient_record(self) -> dict[str, Any]:
        """JSON-safe model parameters (no data, no PII, no labels)."""
        return {
            "model_id": self.model_id,
            "model_version": self.model_version,
            "feature_version": config.FEATURE_VERSION,
            "dataset_version": config.DATASET_VERSION,
            "solver": config.SOLVER,
            "C": config.C_VALUE,
            "max_iter": config.MAX_ITER,
            "matrix_columns": list(config.MATRIX_COLUMNS),
            "coefficients": [float(v) for v in self.model.coef_[0]],
            "intercept": float(self.model.intercept_[0]),
            "n_iter": [int(v) for v in self.model.n_iter_],
            "train_rate": self.train_rate,
        }


def fit(train_rows: list[dict]) -> ChallengerBundle:
    """Fit preprocessing + logistic regression on training rows only."""
    from .baselines import fit_global_rate

    if not train_rows:
        raise ContractViolation("cannot fit challenger on zero rows")
    labels = []
    for row in train_rows:
        target = row.get("is_correct")
        if target not in (0, 1) or isinstance(target, bool):
            raise ContractViolation(
                f"training target must be 0/1, got {target!r}")
        labels.append(int(target))
    if len(set(labels)) < 2:
        raise ContractViolation(
            "cannot fit challenger on single-class training data")
    preprocessor = preprocessing.fit(train_rows)
    matrix = preprocessor.transform(train_rows)
    model = LogisticRegression(
        C=config.C_VALUE,
        solver=config.SOLVER,
        max_iter=config.MAX_ITER,
        random_state=config.RANDOM_STATE,
    )
    model.fit(matrix, labels)
    return ChallengerBundle(
        preprocessor=preprocessor,
        model=model,
        train_rate=fit_global_rate(train_rows),
    )


def predict_proba(bundle: ChallengerBundle,
                  rows: list[dict]) -> list[float]:
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
