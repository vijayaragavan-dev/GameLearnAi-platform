"""Slice analyses for Gate 20: folds, cold-start, difficulty, topics.

Inputs are Gate 19 prediction records joined to d1 rows by ``row_id``
(nothing is refit, relabeled, or re-split here).  Topic identifiers use a
shortened safe form (``topic_…<last4>``) — catalogue UUIDs are not PII, but
short forms keep reports readable; full IDs remain in the dataset
artifact.  Learner keys are NEVER printed; folds are labeled
``fold_01…`` in deterministic held-out-learner order with row counts only.
Slices with no rows report zero coverage explicitly; single-class slices
report ROC-AUC as NOT COMPUTABLE.
"""

from __future__ import annotations

from typing import Any

from .populations import METHODS, score_method, score_population

DIFFICULTIES = ("EASY", "MEDIUM", "HARD")


def short_topic(topic_id: str) -> str:
    """Safe, non-PII short topic label for reports.

    Catalogue UUIDs shorten to their last 4 hex chars; already-short
    (e.g. fixture) identifiers pass through unchanged.
    """
    token = str(topic_id)
    if not token:
        return "topic_unknown"
    if token.startswith("topic_"):
        return token
    compact = token.replace("-", "")
    if len(compact) <= 12:
        return f"topic_{token}"
    return f"topic_..{compact[-4:]}"


def join_predictions(labeled_rows: list[dict],
                     predictions: list[dict]) -> list[dict]:
    """Attach d1 row context (topic, difficulty, cold flag) to records."""
    by_id = {str(r["row_id"]): r for r in labeled_rows}
    joined = []
    for record in predictions:
        row = by_id.get(str(record["row_id"]))
        if row is None:
            continue
        joined.append({**record,
                       "topic_id": str(row["topic_id"]),
                       "question_difficulty": str(
                           row["features"]["question_difficulty"]),
                       "row_is_cold": bool(
                           row["features"]["is_cold_start"])})
    return joined


def _method_probs(records: list[dict]) -> dict[str, list[float]]:
    out: dict[str, list[float]] = {}
    for method in METHODS:
        key = "p_correct_" + method
        out[method] = [float(record[key]) for record in records]
    return out


def _labels(records: list[dict]) -> list[int]:
    return [int(r["is_correct"]) for r in records]


def fold_table(joined: list[dict]) -> list[dict]:
    """One row per held-out learner fold (deterministic order)."""
    learners = sorted({str(r["learner_key"]) for r in joined})
    table = []
    for position, learner in enumerate(learners, start=1):
        members = [r for r in joined if str(r["learner_key"]) == learner]
        y_true = _labels(members)
        probs = _method_probs(members)
        per_method = {
            m: score_method(y_true, probs[m], f"fold_{position:02d}", m)
            for m in METHODS
        }
        strongest = _strongest_baseline(per_method)
        beats = (per_method["model"].get("log_loss") is not None
                 and strongest is not None
                 and per_method["model"]["log_loss"] is not None
                 and per_method["model"]["log_loss"] < strongest)
        table.append({
            "fold": f"fold_{position:02d}",
            # Surrogate grouping key only (Gate 19 artifacts already
            # record held-out learners this way; never a raw user ID).
            "learner_key": learner,
            "n": len(members),
            "n_positive": sum(y_true),
            "n_negative": len(members) - sum(y_true),
            "methods": per_method,
            "strongest_baseline_log_loss": strongest,
            "challenger_beats_strongest": beats
            if per_method["model"].get("log_loss") is not None else None,
            "roc_computable": sum(y_true) >= 2
            and len(members) - sum(y_true) >= 2,
        })
    return table


def _strongest_baseline(per_method: dict[str, dict]) -> float | None:
    values = [per_method[m].get("log_loss") for m in ("A", "B", "C")]
    valid = [v for v in values if v is not None]
    return min(valid) if valid else None


def cold_slices(joined: list[dict]) -> dict[str, Any]:
    """Cold vs non-cold performance (weak slices labeled honestly)."""
    out = {}
    for name, members in (
            ("cold", [r for r in joined if r["row_is_cold"]]),
            ("non_cold", [r for r in joined if not r["row_is_cold"]])):
        y_true = _labels(members)
        probs = _method_probs(members)
        out[name] = {
            "n": len(members),
            "n_positive": sum(y_true),
            "n_negative": len(members) - sum(y_true),
            "statistically_weak": len(members) < 10,
            "methods": {
                m: score_method(y_true, probs[m], f"cold_slice:{name}", m)
                for m in METHODS
            },
        }
    return out


def difficulty_slices(joined: list[dict]) -> dict[str, Any]:
    """Per-difficulty performance; zero-observation levels stay visible."""
    out = {}
    for level in DIFFICULTIES:
        members = [r for r in joined if r["question_difficulty"] == level]
        y_true = _labels(members)
        probs = _method_probs(members)
        observed_acc = (sum(1 for r in members if int(r["is_correct"]) == 1)
                        / len(members)) if members else None
        out[level] = {
            "n": len(members),
            "n_positive": sum(y_true),
            "n_negative": len(members) - sum(y_true),
            "observed_accuracy": observed_acc,
            "zero_coverage": not members,
            "methods": {
                m: score_method(y_true, probs[m],
                                f"difficulty:{level}", m)
                for m in METHODS
            },
        }
    return out


def topic_slices(joined: list[dict]) -> dict[str, Any]:
    """Per-topic performance with challenger deltas vs strongest baseline."""
    by_topic: dict[str, list[dict]] = {}
    for record in joined:
        by_topic.setdefault(short_topic(record["topic_id"]), []).append(
            record)
    out = {}
    for label in sorted(by_topic):
        members = by_topic[label]
        y_true = _labels(members)
        probs = _method_probs(members)
        per_method = {
            m: score_method(y_true, probs[m], f"topic:{label}", m)
            for m in METHODS
        }
        strongest = _strongest_baseline(per_method)
        model_ll = per_method["model"].get("log_loss")
        out[label] = {
            "n": len(members),
            "positive_rate": (sum(y_true) / len(members)) if members else None,
            "insufficient": len(members) < 10,
            "methods": per_method,
            "strongest_baseline_log_loss": strongest,
            "challenger_delta_log_loss": (
                None if model_ll is None or strongest is None
                else model_ll - strongest),
        }
    return out


def pooled_scored(joined: list[dict]) -> dict[str, Any]:
    """Pooled extended metrics over all joined prediction records."""
    return score_population(
        [{"is_correct": r["is_correct"]} for r in joined],
        _method_probs(joined), "gate20_pooled")
