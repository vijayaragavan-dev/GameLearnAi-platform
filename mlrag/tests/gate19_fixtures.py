"""Synthetic d1 dataset rows for Gate 19 tests (no database, no PII)."""

from __future__ import annotations

from datetime import datetime, timedelta

from mlrag.dataset.build import build_dataset
from mlrag.dataset.contract import derive_row_id, validate_dataset_row
from mlrag.dataset.split import apply_assignment, assign_splits
from mlrag.feature_pipeline.builder import build_feature_table

from . import gate17_fixtures as fx

BASE = datetime(2026, 9, 1, 12, 0, 0)


def valid_features(**overrides):
    features = {
        "hist_accuracy": 0.5,
        "recent_accuracy_k5": 0.6,
        "prior_attempt_count": 2,
        "prior_correct_count": 3,
        "prior_total_count": 6,
        "topic_hist_accuracy": 0.5,
        "prev_mastery_score": 80.0,
        "prev_mastery_level": "PROFICIENT",
        "prev_recent_accuracy": 0.75,
        "prev_trend": "STABLE",
        "prev_difficulty": "MEDIUM",
        "topic_has_exposure": True,
        "question_difficulty": "EASY",
        "quiz_difficulty": "MEDIUM",
        "days_since_last_attempt": 1.5,
        "attempt_sequence_index": 6,
        "is_cold_start": False,
        "prev_response_time_norm": 42,
        "timing_known": True,
    }
    features.update(overrides)
    return features


def d1_row(row_id_seed, learner="learner_A", topic="topic_T1",
           at=None, correct=1, split="train", **feature_overrides):
    attempt_id = f"attempt-{row_id_seed}"
    row = {
        "row_id": derive_row_id(attempt_id),
        "learner_key": learner,
        "topic_id": topic,
        "subject_id": "subject_S",
        "question_id": f"question-{row_id_seed}",
        "quiz_id": "quiz_Z",
        "quiz_attempt_id": f"qzattempt-{row_id_seed}",
        "question_attempt_id": attempt_id,
        "feature_version": "f1",
        "dataset_version": "d1",
        "data_version": "snapshot-v1:test",
        "predicted_at": (at or BASE).isoformat(),
        "features": valid_features(**feature_overrides),
        "is_correct": correct,
        "split": split,
    }
    validate_dataset_row(row)
    return row


def ladder(n=8, learners=2, start_correct=1):
    """Deterministic learners x time grid with alternating labels."""
    rows = []
    for i in range(n):
        rows.append(d1_row(
            f"L{i:02d}", learner=f"learner_{i % learners}",
            topic=f"topic_T{i % 2}", at=BASE + timedelta(hours=i),
            correct=(i + start_correct) % 2,
            split="train" if i < n - 2 else "validation",
        ))
    return rows


def real_path_labeled(n=12, learners=3, correct_fn=None):
    """End-to-end Gate 17 -> Gate 18 rows (integration fidelity).

    ``correct_fn`` maps row index -> bool; the default strictly alternates
    so every learner fold-train carries both classes.
    """
    decide = correct_fn or (lambda i: i % 2 == 0)
    outs = [
        fx.outcome(
            f"qa{i:02d}", f"qz{i % 2}", learner=f"learner_{i % learners}",
            topic=f"topic_T{i % 2}", at=fx.BASE + timedelta(hours=i),
            correct=bool(decide(i)),
        )
        for i in range(n)
    ]
    build = build_feature_table(fx.tables(outs))
    assert not build["rejections"], build["rejections"]
    dataset = build_dataset(build["rows"],
                            data_version=build["data_version"])
    split = assign_splits(dataset["rows"])
    labeled = apply_assignment(dataset["rows"], split["assignment"])
    return labeled, dataset
