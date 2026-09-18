"""Baselines A/B/C with deterministic fallbacks (GATE 3 §10).

All baselines obey point-in-time rules: fitting uses train rows only;
per-row history uses rows with event time < T (any partition — the past
is the past).  Fallback chain: topic -> learner -> global train rate.
"""

from __future__ import annotations


def fit_global_rate(train_rows: list[dict]) -> float:
    if not train_rows:
        raise ValueError("cannot fit baseline on empty training set")
    return sum(1 for r in train_rows if r["label"]) / len(train_rows)


def _learner_history(rows: list[dict], learner_key: str, before_iso: str,
                     topic_id: str | None = None) -> list[dict]:
    items = [
        r for r in rows
        if r["learner_key"] == learner_key and r["submitted_at"] < before_iso
    ]
    if topic_id is not None:
        items = [r for r in items if r["topic_id"] == topic_id]
    return items


def _rate(items: list[dict], fallback: float) -> float:
    if not items:
        return fallback
    return sum(1 for r in items if r["label"]) / len(items)


def predict_a(global_rate: float) -> float:
    return global_rate


def predict_b(context_rows: list[dict], row: dict, global_rate: float) -> float:
    hist = _learner_history(context_rows, row["learner_key"],
                            row["submitted_at"])
    return _rate(hist, global_rate)


def predict_c(context_rows: list[dict], row: dict, global_rate: float,
              min_topic_history: int = 2) -> float:
    topic_hist = _learner_history(context_rows, row["learner_key"],
                                  row["submitted_at"], row["topic_id"])
    if len(topic_hist) >= min_topic_history:
        return _rate(topic_hist, global_rate)
    return predict_b(context_rows, row, global_rate)
