"""L2 logistic-regression candidate (GATE 3 §11) — the ONLY ML model.

Fixed configuration (C=1.0, lbfgs, documented); no tuning grid.  Missing
numerics are filled with TRAIN-fold medians (deterministic, stored in the
bundle); binary flags encode missingness explicitly.  Output probabilities
are validated finite and within [0,1]; violations raise.
"""

from __future__ import annotations

import math

import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler

from mlrag.contracts.common import ContractViolation

from .features import FEATURE_COLUMNS

MODEL_ID = "logreg-pcorrect-v1"
MODEL_VERSION = "0.1.0-exp"
FEATURE_SCHEMA_VERSION = "f1"
MIN_HISTORY_FOR_SERVICE = 3

NUMERIC_COLUMNS = (
    "hist_accuracy",
    "recent_accuracy_k5",
    "topic_hist_accuracy",
    "prev_mastery_score",
    "days_since_last_attempt",
)
FLAG_COLUMNS = (
    "is_cold_start",
    "topic_has_exposure",
    "q_diff_medium",
    "q_diff_hard",
    "z_diff_medium",
    "z_diff_hard",
)


def _matrix(rows: list[dict]) -> np.ndarray:
    return np.array(
        [
            [
                (r[col] if r[col] is not None else math.nan)
                if col in NUMERIC_COLUMNS
                else float(r[col])
                for col in FEATURE_COLUMNS
            ]
            for r in rows
        ],
        dtype=float,
    )


class Bundle:
    """Fitted preprocessing + model.  Never persisted in GATE 4."""

    def __init__(self, medians: np.ndarray, scaler: StandardScaler,
                 model: LogisticRegression, train_rate: float):
        self.medians = medians
        self.scaler = scaler
        self.model = model
        self.train_rate = train_rate

    def transform(self, rows: list[dict]) -> np.ndarray:
        matrix = _matrix(rows)
        numeric_idx = [FEATURE_COLUMNS.index(c) for c in NUMERIC_COLUMNS]
        for j in numeric_idx:
            column = matrix[:, j]
            column[np.isnan(column)] = self.medians[j]
        matrix[:, numeric_idx] = self.scaler.transform(matrix[:, numeric_idx])
        return matrix


def fit(train_rows: list[dict]) -> Bundle:
    from .baselines import fit_global_rate

    train_rate = fit_global_rate(train_rows)
    matrix = _matrix(train_rows)
    numeric_idx = [FEATURE_COLUMNS.index(c) for c in NUMERIC_COLUMNS]
    medians = np.nanmedian(matrix[:, numeric_idx], axis=0)
    medians = np.where(np.isnan(medians), 0.0, medians)
    filled = matrix.copy()
    for pos, j in enumerate(numeric_idx):
        column = filled[:, j]
        column[np.isnan(column)] = medians[pos]
    scaler = StandardScaler()
    filled[:, numeric_idx] = scaler.fit_transform(filled[:, numeric_idx])
    labels = np.array([1 if r["label"] else 0 for r in train_rows])
    model = LogisticRegression(C=1.0, solver="lbfgs", max_iter=1000,
                               random_state=42)
    model.fit(filled, labels)
    return Bundle(medians, scaler, model, train_rate)


def predict_proba(bundle: Bundle, rows: list[dict]) -> list[float]:
    probs = bundle.model.predict_proba(bundle.transform(rows))[:, 1]
    out: list[float] = []
    for prob in probs:
        value = float(prob)
        if not math.isfinite(value) or not 0.0 <= value <= 1.0:
            raise ContractViolation(f"invalid model probability: {prob!r}")
        out.append(value)
    return out


def served_by_model(row: dict) -> bool:
    """Cold-start gate: model serves only rows with sufficient priors."""
    return row["hist_attempts"] >= MIN_HISTORY_FOR_SERVICE
