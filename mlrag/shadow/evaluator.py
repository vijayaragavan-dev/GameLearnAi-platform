"""Shadow replay evaluator (GATE 9, SECTION 11/15).

Aggregates ShadowRecords into framework-validation evidence: cold/
served/fallback tallies, ML metrics vs baselines (served rows only),
RAG grounding stats, advisory/outcome comparison categories, failure
 tallies, and determinism checks.  All metrics reuse the experiment
metric helpers (None stays None).  Nothing here is production evidence.
"""

from __future__ import annotations

from mlrag.experiment import baselines, evaluate

from .contracts import ShadowRecord


def _served_probs(records: list[ShadowRecord],
                  field: str) -> tuple[list[int], list[float]]:
    pairs = [(1 if r.outcome.is_correct else 0, getattr(r.ml.signal, field))
             for r in records
             if r.ml.signal.status.value == "served" and
             getattr(r.ml.signal, field) is not None]
    return [p[0] for p in pairs], [p[1] for p in pairs]


def summarize(records: list[ShadowRecord]) -> dict:
    """Aggregate one replay pass.  Deterministic; no I/O."""
    learners = sorted({r.event.learner_key for r in records})
    tiers = {"cold_start": 0, "sparse_history": 0, "sufficient_history": 0}
    for record in records:
        tiers[record.ml.history_tier] = tiers.get(
            record.ml.history_tier, 0) + 1
    served = [r for r in records
              if r.ml.signal.status.value == "served"]
    fallback = [r for r in records
                if r.ml.signal.status.value != "served"]
    fallback_reasons: dict[str, int] = {}
    for record in fallback:
        reason = record.ml.signal.fallback_reason or "unknown"
        fallback_reasons[reason] = fallback_reasons.get(reason, 0) + 1

    y_true, probs = _served_probs(records, "p_correct")
    ml_metrics = evaluate.score_set(y_true, probs) if y_true else {
        "n": 0, "n_positive": 0, "log_loss": None, "brier": None,
        "accuracy": None, "roc_auc": None, "pr_auc": None}

    # Baselines scored on the SAME served rows, same point-in-time rule.
    # Context preserves replay order, so positional alignment is exact.
    served_idx = [i for i, r in enumerate(records)
                  if r.ml.signal.status.value == "served"]
    context = [{"learner_key": r.event.learner_key,
                "submitted_at": r.event.event_time_iso,
                "topic_id": r.event.topic_id,
                "label": r.outcome.is_correct} for r in records]
    if served_idx:
        train_rate = (sum(1 for c in context if c["label"])
                      / len(context)) if context else 0.0
        served_rows = [context[i] for i in served_idx]
        b_probs = [baselines.predict_b(context, row, train_rate)
                   for row in served_rows]
        c_probs = [baselines.predict_c(context, row, train_rate)
                   for row in served_rows]
        y_served = [1 if r["label"] else 0 for r in served_rows]
        baseline_metrics = {
            "B": evaluate.score_set(y_served, b_probs),
            "C": evaluate.score_set(y_served, c_probs),
        }
    else:
        baseline_metrics = {"B": None, "C": None}

    categories: dict[str, int] = {
        "ml_supported": 0, "ml_misleading": 0, "ml_fallback": 0,
        "rag_grounded": 0, "rag_empty": 0, "rag_failed": 0,
    }
    for record in records:
        if record.ml.signal.status.value == "served":
            predicted = (record.ml.signal.p_correct or 0.0) >= 0.5
            if predicted == record.outcome.is_correct:
                categories["ml_supported"] += 1
            else:
                categories["ml_misleading"] += 1
        else:
            categories["ml_fallback"] += 1
        rag_status = record.rag.evidence.status.value
        if rag_status == "served":
            categories["rag_grounded"] += 1
        elif "simulated rag" in (record.rag.evidence.fallback_reason or "") \
                or "failure" in (record.rag.evidence.fallback_reason or ""):
            categories["rag_failed"] += 1
        else:
            categories["rag_empty"] += 1

    # Defense-in-depth invariant: served evidence must always carry
    # citations (enforced at construction; any count here is a defect).
    rag_scope_violations = sum(
        1 for r in records
        if r.rag.evidence.status.value == "served"
        and not r.rag.evidence.citations)
    grounding_failures = sum(
        1 for r in records
        if "ground" in (r.rag.evidence.fallback_reason or "").lower()
        or "citation" in (r.rag.evidence.fallback_reason or "").lower()
        or "scope_mismatch" in (r.rag.evidence.fallback_reason or ""))

    return {
        "n_events": len(records),
        "n_learners": len(learners),
        "tiers": tiers,
        "served_ml": len(served),
        "fallback_ml": len(fallback),
        "fallback_reasons": fallback_reasons,
        "ml_metrics_served_only": ml_metrics,
        "baseline_metrics_served_only": baseline_metrics,
        "categories": categories,
        "rag_scope_violations": rag_scope_violations,
        "rag_grounding_failures": grounding_failures,
        "failure_injected": sorted({f for r in records
                                    for f in r.failure_injected}),
    }


def determinism_check(run_once, run_twice) -> bool:
    """Two passes over identical input must produce identical records."""
    first = run_once()
    second = run_twice()
    return first == second


__all__ = ["summarize", "determinism_check"]
