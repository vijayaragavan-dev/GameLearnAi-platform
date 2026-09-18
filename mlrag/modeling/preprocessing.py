"""Leakage-safe preprocessing for the 19-column f1 schema (GATE 19).

Rules enforced here, not by convention:

* every statistic (medians, means, scales) is fitted on TRAINING rows
  only — validation/test rows and labels are never read during ``fit``;
* ``transform`` is a pure function of the fitted statistics plus one row's
  own pre-attempt features (no cross-row reads, no label reads);
* input rows must carry exactly the 19 frozen f1 columns (Gate 17
  ``validate_feature_vector`` is the gatekeeper — a single source of
  truth for value semantics);
* output column order is the frozen :data:`config.MATRIX_COLUMNS` order.
"""

from __future__ import annotations

import math
import warnings
from dataclasses import dataclass, field
from typing import Any

import numpy as np

from ..contracts.common import ContractViolation
from ..feature_pipeline.contract import FEATURE_COLUMNS, validate_feature_vector
from . import config


def _as_float(value: Any) -> float:
    if value is None or isinstance(value, bool):
        return math.nan
    try:
        return float(value)
    except (TypeError, ValueError) as exc:
        raise ContractViolation(f"non-numeric value in matrix: {value!r}") from exc


@dataclass
class FittedPreprocessor:
    """Train-fitted transformers.  Immutable after :func:`fit`."""

    medians: tuple[float, ...]
    means: tuple[float, ...]
    scales: tuple[float, ...]
    median_fallback_columns: tuple[str, ...] = ()
    n_train_rows: int = 0

    def transform(self, feature_rows: list[dict]) -> np.ndarray:
        """Map validated f1 rows to the frozen 31-column matrix."""
        matrix = np.empty((len(feature_rows), len(config.MATRIX_COLUMNS)),
                          dtype=float)
        for i, row in enumerate(feature_rows):
            features = row["features"] if "features" in row else row
            validate_feature_vector(features)
            matrix[i, :] = _encode_row(features, self)
        return matrix


def _encode_row(features: dict, fitted: FittedPreprocessor) -> list[float]:
    values: list[float] = []
    for pos, name in enumerate(config.NUMERIC_COLUMNS):
        raw = _as_float(features.get(name))
        filled = fitted.medians[pos] if math.isnan(raw) else raw
        values.append((filled - fitted.means[pos]) / fitted.scales[pos])
    for name in config.BOOL_COLUMNS:
        flag = features.get(name)
        if not isinstance(flag, bool):
            raise ContractViolation(f"{name} must be a boolean")
        values.append(1.0 if flag else 0.0)
    for name, levels in config.ONE_HOT_SPEC:
        token = features.get(name)
        for level in levels:
            values.append(1.0 if token == level else 0.0)
    return values


def fit(train_rows: list[dict]) -> FittedPreprocessor:
    """Fit preprocessing on training rows only.  Reads no labels."""
    if not train_rows:
        raise ContractViolation("cannot fit preprocessing on zero rows")
    raw = np.empty((len(train_rows), len(config.NUMERIC_COLUMNS)),
                   dtype=float)
    for i, row in enumerate(train_rows):
        features = row["features"] if "features" in row else row
        validate_feature_vector(features)
        for pos, name in enumerate(config.NUMERIC_COLUMNS):
            raw[i, pos] = _as_float(features.get(name))
    medians: list[float] = []
    fallback: list[str] = []
    for pos, name in enumerate(config.NUMERIC_COLUMNS):
        column = raw[:, pos]
        with warnings.catch_warnings():
            # All-NULL train columns are expected (mastery/timing gaps);
            # the NaN median below routes to the documented 0.0 fallback.
            warnings.simplefilter("ignore", RuntimeWarning)
            median = float(np.nanmedian(column))
        if math.isnan(median):
            median = 0.0  # documented fallback: train column entirely NULL
            fallback.append(name)
        medians.append(median)
    filled = raw.copy()
    for pos in range(len(config.NUMERIC_COLUMNS)):
        column = filled[:, pos]
        column[np.isnan(column)] = medians[pos]
    means = tuple(float(v) for v in filled.mean(axis=0))
    stds = tuple(float(v) for v in filled.std(axis=0))
    scales = tuple(s if s > 0.0 else 1.0 for s in stds)
    return FittedPreprocessor(
        medians=tuple(medians),
        means=means,
        scales=scales,
        median_fallback_columns=tuple(fallback),
        n_train_rows=len(train_rows),
    )


def imputation_report(fitted: FittedPreprocessor) -> dict[str, Any]:
    """Human-readable record of every train-derived imputation rule."""
    return {
        "rule": "nullable numerics -> train-fold median",
        "medians": dict(zip(config.NUMERIC_COLUMNS, fitted.medians)),
        "median_fallback_0_columns": list(fitted.median_fallback_columns),
        "categorical_null_rule": "all-zero one-hot vector",
        "scaler": {
            "means": dict(zip(config.NUMERIC_COLUMNS, fitted.means)),
            "scales": dict(zip(config.NUMERIC_COLUMNS, fitted.scales)),
        },
        "n_train_rows": fitted.n_train_rows,
    }
