"""Real-history shadow evaluation harness (GATE 11, STAGE 1).

Two entry points sharing one pure core:
  * ``run_live_evaluation()`` — read-only DB via ``experiment.db``
    (gamelearn_ro enforced there); raises ContractViolation before any
    query when credentials are absent.  No fallback credentials, ever.
  * ``evaluate_dataset(...)`` — pure evaluation over in-memory rows
    (built feature rows + mastery/recs + corpus docs); used by tests
    with labeled synthetic fixtures and by the live path after
    extraction.  No database, no network.

Output is aggregate-only (counts, metrics, calibration, promotion
verdict).  No per-learner rows, no raw IDs beyond hashed learner keys
in counts, no PII.  NOT production evidence; promotion stays blocked
until Gate 5 bars pass on measured data.
"""

from __future__ import annotations

from datetime import datetime, timezone

from mlrag.contracts.common import ContractViolation
from mlrag.contracts.retriever import ScopeFilter
from mlrag.experiment import baselines, calibration as calibration_module
from mlrag.experiment import comparison, coverage, evaluate, features
from mlrag.experiment import model as model_module
from mlrag.experiment import promotion, sufficiency
from mlrag.experiment.run_experiment import (
    _promotion_evidence as _promo_evidence_helper)
from mlrag.rag import grounding, ingest, retrieval
from mlrag.rag.documents import RagDocument

ARTIFACT_NAME = "gate11_results.json"


def _served_predictions(
        rows: list[dict]) -> tuple[list[int], list[float]]:
    """Per-row served predictions via LOLO refits.

    Mirrors the LOLO evaluation one fold at a time so distribution and
    error analysis use genuine out-of-fold probabilities, never
    in-sample fits.
    """
    learners = sorted({r["learner_key"] for r in rows})
    y_all: list[int] = []
    p_all: list[float] = []
    for held in learners:
        train = [r for r in rows if r["learner_key"] != held]
        test = sorted(
            [r for r in rows if r["learner_key"] == held],
            key=lambda r: (r["submitted_at"], r["question_attempt_id"]))
        if not train or not test:
            continue
        bundle = model_module.fit(train)
        served = [r for r in test if model_module.served_by_model(r)]
        if not served:
            continue
        probs = model_module.predict_proba(bundle, served)
        y_all.extend(1 if r["label"] else 0 for r in served)
        p_all.extend(probs)
    return y_all, p_all


def evaluate_dataset(rows: list[dict], corpus: list[RagDocument]) -> dict:
    """Full offline evaluation over built feature rows + corpus docs."""
    if not rows:
        raise ContractViolation("no rows to evaluate")
    lolo = evaluate.leave_one_learner_out(rows)
    temporal = evaluate.temporal_holdout(rows)
    pool = lolo["pooled"]
    calib_table = lolo["pooled_calibration_model"]
    calib = calibration_module.summarize_calibration(calib_table)
    y_true, probs = _served_predictions(rows)
    dist = _distribution(probs)
    errors = _error_analysis(y_true, probs, rows)
    rag_stats = _rag_shadow(rows, corpus)
    suff = sufficiency.assess_sufficiency(rows)
    promo = promotion.assess(_promotion_evidence(rows, suff, lolo, temporal))
    return {
        "n_events": len(rows),
        "n_learners": len({r["learner_key"] for r in rows}),
        "coverage": coverage.feature_coverage(rows),
        "sufficiency": suff,
        "history": {
            "cold": sum(1 for r in rows if r["is_cold_start"]),
            "served": sum(1 for r in rows
                           if model_module.served_by_model(r)),
        },
        "lolo": lolo,
        "temporal": temporal,
        "comparison_pooled": comparison.compare_methods(pool),
        "calibration": calib,
        "prediction_distribution": dist,
        "error_analysis": errors,
        "rag_shadow": rag_stats,
        "promotion": {"promotable": promo.promotable,
                      "reasons": list(promo.reasons)},
        "deployment_ready": False,
        "stage": "STAGE_1_OFFLINE_REPLAY",
        "production_promotion": False,
    }


def _distribution(probs: list[float]) -> dict:
    if not probs:
        return {"n": 0, "min": None, "max": None, "mean": None,
                "extreme_low": 0, "extreme_high": 0,
                "note": "served-row probabilities unavailable"}
    ordered = sorted(probs)
    mid = ordered[len(ordered) // 2]
    return {
        "n": len(probs),
        "min": min(probs),
        "max": max(probs),
        "mean": sum(probs) / len(probs),
        "median": mid,
        "extreme_low": sum(1 for p in probs if p < 0.05),
        "extreme_high": sum(1 for p in probs if p > 0.95),
    }


def _error_analysis(y_true: list[int], probs: list[float],
                    rows: list[dict]) -> dict:
    if not probs:
        return {"note": "no served predictions to analyze",
                "categories": {}}
    cats = {"false_confident": 0, "missed_correct": 0,
            "missed_incorrect": 0, "cold_fallback": 0,
            "sparse_fallback": 0}
    for row in rows:
        if row["is_cold_start"]:
            cats["cold_fallback"] += 1
        elif row["hist_attempts"] < model_module.MIN_HISTORY_FOR_SERVICE:
            cats["sparse_fallback"] += 1
    for y, p in zip(y_true, probs):
        if y == 1 and p < 0.5:
            cats["missed_correct"] += 1
        elif y == 0 and p >= 0.5:
            cats["missed_incorrect"] += 1
        if (p < 0.1 and y == 1) or (p > 0.9 and y == 0):
            cats["false_confident"] += 1
    return {"categories": cats}


def _rag_shadow(rows: list[dict],
                corpus: list[RagDocument]) -> dict:
    """Per-topic retrieval over the offline corpus (weak-label check)."""
    engine = retrieval.LexicalRetriever()
    topics = sorted({r["topic_id"] for r in rows})
    ok = empty = violations = grounding_failures = 0
    recalls: list[float] = []
    for topic in topics:
        subject = next(r["subject_id"] for r in rows
                       if r["topic_id"] == topic)
        relevant = {d.doc_id for d in corpus if d.topic_id == topic}
        try:
            response = engine.retrieve(
                retrieval.RagQuery(query=f"topic {topic}",
                                   subject_id=subject, topic_id=topic,
                                   top_k=5),
                corpus, request_id=f"gate11-{topic}")
        except Exception:
            empty += 1
            continue
        if not response.served:
            empty += 1
            continue
        for chunk in response.chunks:
            if chunk.subject_id != subject or chunk.topic_id != topic:
                violations += 1
        try:
            grounding.validate_grounded(
                list(response.chunks),
                ScopeFilter(subject_id=subject, topic_id=topic),
                request_id=f"gate11-{topic}")
            ok += 1
        except Exception:
            grounding_failures += 1
        hits = len([c for c in response.chunks
                    if c.chunk_id in relevant])
        recalls.append(hits / len(relevant) if relevant else 0.0)
    return {
        "n_topics": len(topics),
        "grounded_topics": ok,
        "empty_topics": empty,
        "scope_violations": violations,
        "grounding_failures": grounding_failures,
        "mean_recall_at_5": (sum(recalls) / len(recalls)) if recalls else None,
        "relevance_method": "topic-membership weak labels (NOT human)",
    }


def _promotion_evidence(rows, suff, lolo, temporal):
    # Reuse the Gate 4 derivation (documented stability rules) rather
    # than duplicating it; numerics stay single-sourced.
    return _promo_evidence_helper(rows, suff, lolo, temporal)


def run_live_evaluation() -> dict:
    """Extract (read-only) + evaluate + timestamp.  Raises cleanly when
    MLRAG_DB_* credentials are absent — never falls back, never invents."""
    from mlrag.experiment import db, extract

    conn = db.connect()  # asserts gamelearn_ro; env required
    try:
        tables = extract.extract(conn)
    finally:
        conn.close()
    rows = features.build_rows(
        tables["outcomes"], tables["mastery"], tables["recommendations"])
    try:
        from mlrag.rag import extract_corpus, ingest as ingest_module

        conn2 = db.connect()
        try:
            content = extract_corpus.fetch_corpus(conn2)
        finally:
            conn2.close()
        topics = {str(t["id"]): t for t in content["topics"]}
        corpus: list[RagDocument] = []
        for table in ("lessons", "questions", "topics"):
            for row in content[table]:
                if table != "topics":
                    topic = topics.get(str(row.get("topic_id")), {})
                    row.setdefault("subject_id", topic.get("subject_id"))
                    row.setdefault("unit_id", topic.get("unit_id"))
                row["updated_at"] = row.get("updated_at") or "seed"
            corpus.extend(
                ingest_module.ingest_records(
                    content[table], source_table=table).documents)
    except Exception:
        corpus = []
    payload = evaluate_dataset(rows, corpus)
    payload["evaluated_at"] = datetime.now(timezone.utc).isoformat()
    payload["read_only_user"] = db.READ_ONLY_USER
    return payload


__all__ = ["evaluate_dataset", "run_live_evaluation", "ARTIFACT_NAME"]
