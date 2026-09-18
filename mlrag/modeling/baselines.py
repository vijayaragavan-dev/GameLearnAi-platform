"""Frozen baselines A/B/C on Gate 18 d1 rows (GATE 19).

Semantics carried over from the Gate-16 experimental design
(``mlrag.experiment.baselines``), re-expressed against d1 rows
(``learner_key`` / ``predicted_at`` / ``topic_id`` / ``is_correct``) —
the old 11-column row shape is never used.

* A — majority: the training-fold positive rate, one number for every
  row.  Validation/test labels are never read to compute it.
* B — learner history: the rate over strictly-past rows of the same
  learner (``predicted_at < T``, any split — the past is the past),
  falling back to the train rate when no past exists.  The current
  target is never included.
* C — deterministic adaptive-style fallback chain: learner-TOPIC history
  rate when >= ``MIN_TOPIC_HISTORY`` past topic rows exist, else B, else
  the train rate.  This is the existing experimental deterministic
  adapter (Gate-16 design), verified point-in-time-safe: it reads only
  past labels and the train rate, never the current target, never the
  future, and it does not touch or reimplement the Java AdaptiveEngine
  (which emits difficulty/mastery decisions, not P(correct), and therefore
  has no verified probability adapter — porting one would be invention,
  so the frozen experimental chain stands and no backend change is needed).

All three are deterministic pure functions of (context, row, train_rate).
"""

from __future__ import annotations

MIN_TOPIC_HISTORY = 2


def fit_global_rate(train_rows: list[dict]) -> float:
    """Training-fold positive rate.  Reads train labels only."""
    if not train_rows:
        raise ValueError("cannot fit baseline on empty training set")
    return sum(1 for r in train_rows if r["is_correct"] == 1) / len(train_rows)


def _past_rows(context_rows: list[dict], row: dict,
               topic_id: str | None = None) -> list[dict]:
    items = [
        r for r in context_rows
        if str(r["learner_key"]) == str(row["learner_key"])
        and str(r["predicted_at"]) < str(row["predicted_at"])
    ]
    if topic_id is not None:
        items = [r for r in items
                 if str(r["topic_id"]) == str(topic_id)]
    return items


def _rate(items: list[dict], fallback: float) -> float:
    if not items:
        return fallback
    return sum(1 for r in items if r["is_correct"] == 1) / len(items)


def predict_a(train_rate: float) -> float:
    """Baseline A: frozen train majority probability."""
    return float(train_rate)


def predict_b(context_rows: list[dict], row: dict,
              train_rate: float) -> float:
    """Baseline B: learner historical accuracy (strict past only)."""
    return _rate(_past_rows(context_rows, row), float(train_rate))


def predict_c(context_rows: list[dict], row: dict, train_rate: float,
              min_topic_history: int = MIN_TOPIC_HISTORY) -> float:
    """Baseline C: topic history (>=N) else learner history else train."""
    topic_hist = _past_rows(context_rows, row, str(row["topic_id"]))
    if len(topic_hist) >= min_topic_history:
        return _rate(topic_hist, float(train_rate))
    return predict_b(context_rows, row, train_rate)


def describe() -> dict:
    """Frozen baseline registry for experiment records."""
    return {
        "A": "majority: training-fold positive rate",
        "B": "learner history rate over strictly-past rows, "
             "train-rate fallback",
        "C": f"topic history rate when >={MIN_TOPIC_HISTORY} past topic "
             "rows, else B, else train rate (deterministic chain)",
    }
