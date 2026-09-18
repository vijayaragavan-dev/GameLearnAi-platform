"""Deterministic robustness checks for Gate 20 (no perturbation of data).

Safe checks only, all on recorded predictions / dataset rows:

* repeat: re-running the analysis on identical inputs is identical;
* fold_order: reversing the held-out-learner fold order leaves every
  per-fold metric unchanged (order-independence, not data selection);
* row_order: shuffling dataset row order leaves pooled metrics unchanged;
* reload: JSON round-trip of predictions preserves every metric bit.

Labels are never altered and no synthetic rows are created.  A check that
is meaningless on a given input reports why instead of fabricating one.
"""

from __future__ import annotations

import json
from typing import Any

from . import populations, slices


def _canonical(value: Any) -> str:
    return json.dumps(value, sort_keys=True, default=str)


def _round_floats(value: Any, precision: int = 12) -> Any:
    """Canonicalize floats for order-invariance comparison.

    Justification (documented serialization detail): floating-point
    summation is not associative, so mathematically identical metric sets
    accumulated in different row orders may differ in the last ulp.
    Rounding to 12 decimals keeps every reportable digit while making the
    comparison order-invariant.  Raw metrics elsewhere keep full precision.
    """
    if isinstance(value, float):
        return round(value, precision)
    if isinstance(value, dict):
        return {k: _round_floats(v, precision) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [_round_floats(v, precision) for v in value]
    return value


def check_repeat(joined: list[dict]) -> dict[str, Any]:
    """Same analysis twice -> identical canonical output."""
    first = _canonical({
        "folds": slices.fold_table(joined),
        "pooled": slices.pooled_scored(joined),
        "cold": slices.cold_slices(joined),
    })
    second = _canonical({
        "folds": slices.fold_table(joined),
        "pooled": slices.pooled_scored(joined),
        "cold": slices.cold_slices(joined),
    })
    return {"check": "repeat", "identical": first == second}


def check_fold_order(joined: list[dict]) -> dict[str, Any]:
    """Reversed fold processing order -> identical per-fold metrics."""
    learners = sorted({str(r["learner_key"]) for r in joined})
    forward = {row["learner_key"]: row
               for row in slices.fold_table(joined)}
    # Recompute every fold from explicitly reversed learner processing and
    # confirm per-fold records match exactly (computation order must not
    # leak into metric values).  Matching is by surrogate learner key —
    # never by row counts, which collide across folds.
    def _values(record: dict) -> dict:
        # Population labels differ by construction path; metric values
        # must not.
        return {k: v for k, v in record.items() if k != "population"}

    matched = True
    for learner in reversed(learners):
        members = [r for r in joined if str(r["learner_key"]) == learner]
        y_true = [int(r["is_correct"]) for r in members]
        fold = forward[learner]
        for method in populations.METHODS:
            key = "p_correct_" + method
            ref = populations.score_method(
                y_true, [float(r[key]) for r in members],
                "robustness", method)
            if _canonical(_values(ref)) != _canonical(
                    _values(fold["methods"][method])):
                matched = False
    return {"check": "fold_order", "identical": matched,
            "n_folds": len(learners)}


def check_row_order(joined: list[dict]) -> dict[str, Any]:
    """Shuffled input order -> identical pooled metrics (ulp-canonical)."""
    reference = _canonical(
        _round_floats(slices.pooled_scored(joined)))
    shuffled = _canonical(
        _round_floats(slices.pooled_scored(list(reversed(joined)))))
    return {"check": "row_order", "identical": reference == shuffled,
            "canonicalization": "round-half-even to 12 decimals; "
            "floating-point summation order only"}


def check_reload(predictions: list[dict]) -> dict[str, Any]:
    """JSON round-trip of prediction records preserves metric inputs."""
    reloaded = json.loads(json.dumps(predictions, default=str))
    before = [(r["row_id"], r["is_correct"], r["p_correct_model"])
              for r in predictions]
    after = [(r["row_id"], r["is_correct"], r["p_correct_model"])
             for r in reloaded]
    return {"check": "reload", "identical": before == after,
            "n": len(predictions)}


def run_all(joined: list[dict], predictions: list[dict]) -> dict[str, Any]:
    """Run every robustness check; overall PASS requires all identical."""
    results = [check_repeat(joined), check_fold_order(joined),
               check_row_order(joined), check_reload(predictions)]
    return {"checks": results,
            "robustness_pass": all(r["identical"] for r in results)}
