"""Deterministic learner-aware + time-aware dataset splitting (GATE 18).

Mechanism (``user_aware_time_aware`` vocabulary, reused from
``mlrag.contracts.evaluation.SplitPolicy`` — random row splits are
prohibited):

1. Order learners by ``(first predicted_at, learner_key)`` — fully
   deterministic, no RNG, targets never consulted.
2. Walk learners in that order, assigning each learner WHOLE to the
   earliest split whose row target is unmet: ``train`` (70% of rows),
   then ``validation`` (15%), remainder ``test``.  The first learner is
   always assigned to ``train`` so degenerate inputs cannot silently
   empty it.
3. Derive ``training_end_iso`` / ``validation_end_iso`` (max ``predicted_at``
   per split) and per-split temporal ranges for audit.

Guarantees:

* user isolation is absolute — no learner ever spans two splits
  (same-T quiz siblings are therefore always co-located);
* split assignment never reads ``is_correct`` (proven by test: flipping
  all targets leaves every assignment unchanged);
* every dataset row keeps the features Gate 17 built with strict ``< T``
  semantics, so no future information can enter an earlier training row
  through X regardless of split placement;
* global temporal non-overlap between splits is REPORTED (overlap flags),
  not forced — forcing it would require splitting learners (forbidden)
  or discarding rows (forbidden).  User isolation takes precedence; the
  per-split usability verdict accounts for overlap.

Usability (fixed rule, reported per split): a split is statistically
usable iff it holds >= 10 rows AND >= 2 learners AND both target classes
AND its time range does not overlap an earlier split's range.  Tiny live
data is expected to fail this — ENGINEERING PASS is then distinguished
from DATA READINESS, never faked by re-tuning fractions.
"""

from __future__ import annotations

from typing import Any

from ..contracts.common import ContractViolation
from ..contracts.evaluation import SplitPolicy
from .contract import DATASET_VERSION, SPLIT_NAMES

STRATEGY = "user_aware_time_aware"
TRAIN_FRAC = 0.70
VAL_FRAC = 0.15

#: Minimum bar for a split to count as statistically usable.
MIN_SPLIT_ROWS = 10
MIN_SPLIT_LEARNERS = 2


def _learner_order(rows: list[dict]) -> list[str]:
    first_seen: dict[str, str] = {}
    for row in rows:
        key = str(row["learner_key"])
        stamp = str(row["predicted_at"])
        if key not in first_seen or stamp < first_seen[key]:
            first_seen[key] = stamp
    return sorted(first_seen, key=lambda k: (first_seen[k], k))


def assign_splits(
    rows: list[dict],
    train_frac: float = TRAIN_FRAC,
    val_frac: float = VAL_FRAC,
) -> dict[str, Any]:
    """Assign every dataset row to train/validation/test deterministically."""
    if not 0.0 < train_frac < 1.0 or not 0.0 <= val_frac < 1.0:
        raise ContractViolation("split fractions must satisfy 0 < train < 1")
    if train_frac + val_frac >= 1.0:
        raise ContractViolation("train + validation fractions must be < 1")
    total = len(rows)
    train_target = int(total * train_frac)
    val_target = int(total * val_frac)

    by_learner: dict[str, list[dict]] = {}
    for row in rows:
        by_learner.setdefault(str(row["learner_key"]), []).append(row)

    assignment: dict[str, str] = {}
    learner_split: dict[str, str] = {}
    train_rows = 0
    val_rows = 0
    for position, learner in enumerate(_learner_order(rows)):
        members = by_learner[learner]
        if position == 0:
            split = "train"
        elif train_rows < train_target:
            split = "train"
        elif val_rows < val_target:
            split = "validation"
        else:
            split = "test"
        learner_split[learner] = split
        for row in members:
            assignment[str(row["row_id"])] = split
        if split == "train":
            train_rows += len(members)
        elif split == "validation":
            val_rows += len(members)

    metadata = describe_split(rows, assignment, learner_split)
    metadata.update(
        {
            "strategy": STRATEGY,
            "train_frac": train_frac,
            "val_frac": val_frac,
            "test_frac": 1.0 - train_frac - val_frac,
            "train_target_rows": train_target,
            "validation_target_rows": val_target,
            "dataset_version": DATASET_VERSION,
        }
    )
    return {"assignment": assignment, "learner_split": learner_split,
            "metadata": metadata}


def describe_split(
    rows: list[dict],
    assignment: dict[str, str],
    learner_split: dict[str, str],
) -> dict[str, Any]:
    """Per-split ranges, overlap flags, usability verdicts, policy record."""
    per_split: dict[str, dict[str, Any]] = {}
    for name in SPLIT_NAMES:
        members = [r for r in rows if assignment.get(str(r["row_id"])) == name]
        learners = sorted({str(r["learner_key"]) for r in members})
        stamps = sorted(str(r["predicted_at"]) for r in members)
        positives = sum(1 for r in members if r.get("is_correct") == 1)
        per_split[name] = {
            "rows": len(members),
            "learners": len(learners),
            "learner_keys": learners,
            "min_predicted_at": stamps[0] if stamps else None,
            "max_predicted_at": stamps[-1] if stamps else None,
            "positives": positives,
            "negatives": len(members) - positives,
            "both_classes": positives > 0 and len(members) - positives > 0,
        }

    train_max = per_split["train"]["max_predicted_at"]
    val_min = per_split["validation"]["min_predicted_at"]
    val_max = per_split["validation"]["max_predicted_at"]
    test_min = per_split["test"]["min_predicted_at"]
    overlap_train_val = (
        train_max is not None and val_min is not None and train_max > val_min
    )
    overlap_val_test = (
        val_max is not None and test_min is not None and val_max > test_min
    )

    # Learner-granularity temporal ordering: every train learner's first
    # activity must precede every validation learner's first activity, and
    # likewise validation before test.  (Per-split learner lists are stored
    # alphabetically; ordering is checked on first-activity bounds, not on
    # list order.)
    learner_firsts: dict[str, str] = {}
    for row in rows:
        key = str(row["learner_key"])
        stamp = str(row["predicted_at"])
        if key not in learner_firsts or stamp < learner_firsts[key]:
            learner_firsts[key] = stamp
    bound: dict[str, tuple[str | None, str | None]] = {}
    for name in SPLIT_NAMES:
        firsts = sorted(learner_firsts[k]
                        for k in per_split[name]["learner_keys"])
        bound[name] = (firsts[0], firsts[-1]) if firsts else (None, None)
    ordered_ok = True
    for earlier, later in (("train", "validation"),
                           ("validation", "test")):
        early_max = bound[earlier][1]
        late_min = bound[later][0]
        if early_max is not None and late_min is not None:
            ordered_ok = ordered_ok and early_max <= late_min

    for name, earlier_overlap in (
        ("train", False),
        ("validation", overlap_train_val),
        ("test", overlap_val_test or overlap_train_val),
    ):
        info = per_split[name]
        # An empty split has no time range: overlap is undefined (usability
        # is already false via the row/learner bars), never flagged.
        info["overlaps_earlier_split"] = bool(
            earlier_overlap and info["rows"] > 0
        )
        info["usable"] = bool(
            info["rows"] >= MIN_SPLIT_ROWS
            and info["learners"] >= MIN_SPLIT_LEARNERS
            and info["both_classes"]
            and not earlier_overlap
        )

    policy_record = _policy_record(per_split)
    return {
        "per_split": per_split,
        "overlap_train_validation": overlap_train_val,
        "overlap_validation_test": overlap_val_test,
        "learner_first_activity_order_preserved": ordered_ok,
        "all_splits_usable": all(
            per_split[name]["usable"] for name in SPLIT_NAMES
        ),
        "split_policy": policy_record,
    }


def _policy_record(per_split: dict[str, dict[str, Any]]) -> dict[str, Any]:
    """Best-effort SplitPolicy construction reusing the Gate 1 contract."""
    train_end = per_split["train"]["max_predicted_at"]
    val_end = per_split["validation"]["max_predicted_at"]
    if train_end is None or val_end is None:
        return {
            "constructed": False,
            "reason": "empty train or validation split — no time cutoffs",
        }
    try:
        policy = SplitPolicy(
            strategy=STRATEGY,
            training_end_iso=train_end,
            validation_end_iso=val_end,
            user_isolation=True,
        )
    except ContractViolation as exc:
        return {"constructed": False, "reason": f"contract refused: {exc}"}
    return {
        "constructed": True,
        "strategy": policy.strategy,
        "training_end_iso": policy.training_end_iso,
        "validation_end_iso": policy.validation_end_iso,
        "user_isolation": policy.user_isolation,
    }


def apply_assignment(
    rows: list[dict], assignment: dict[str, str]
) -> list[dict]:
    """Return dataset rows with the ``split`` field populated."""
    labeled = []
    for row in rows:
        split = assignment.get(str(row["row_id"]))
        if split not in SPLIT_NAMES:
            raise ContractViolation(
                f"row {row['row_id']} has no valid split assignment"
            )
        labeled.append({**row, "split": split})
    return labeled
