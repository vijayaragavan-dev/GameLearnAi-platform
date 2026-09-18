"""Offline replay engine (GATE 9, SECTION 9).

Deterministic event-ordered replay over historical outcome rows:
sort by (event time, stable ID) -> per-event strict-past context ->
shadow ML prediction -> shadow RAG request -> advisory synthesis ->
ground-truth retention for evaluation ONLY.

Structural guarantees:
  * predictor and retriever receive past-only inputs; the ledger
    (targets) is never passed to them;
  * same-timestamp rows are ordered by stable ID and never see each other
    (strict <T, same-quiz siblings excluded by construction);
  * failure injection converts to deterministic fallback, never to
    arbitrary decisions;
  * repeated runs over identical input produce identical records.
"""

from __future__ import annotations

from collections.abc import Callable, Sequence

from mlrag.contracts.adaptive import (AdvisoryBundle, DifficultySignal,
                                      MLSignal, RAGEvidence, SignalStatus,
                                      classify_history)
from mlrag.contracts.common import ContractViolation
from mlrag.rag.retrieval import LexicalRetriever, RagQuery, RagRetriever

from .contracts import (AuthoritativeOutcome, OutcomeLedger, ReplayEvent,
                        ShadowAdvisory, ShadowMLResult, ShadowRAGResult,
                        ShadowRecord)

LOW_CONFIDENCE_CUTOFF = 0.5  # provisional; below -> fallback


def build_events(outcome_rows: list[dict]) -> tuple[list[ReplayEvent],
                                                    OutcomeLedger]:
    """Split raw historical rows into target-free events + truth ledger.

    Input rows use the experiment extraction shape (must include
    ``is_correct``); output events never do.
    """
    for key in ("question_attempt_id", "learner_key", "submitted_at",
                "question_id", "topic_id", "subject_id", "is_correct"):
        missing = [i for i, r in enumerate(outcome_rows) if key not in r]
        if missing:
            raise ContractViolation(f"rows missing {key}: {missing[:3]}")
    ordered = sorted(outcome_rows, key=lambda r: (
        str(r["submitted_at"]), str(r["question_attempt_id"])))
    events: list[ReplayEvent] = []
    truths: dict[str, bool] = {}
    for row in ordered:
        event_id = str(row["question_attempt_id"])
        stored = row.get("question_difficulty") or "EASY"
        events.append(ReplayEvent(
            event_id=event_id,
            learner_key=str(row["learner_key"]),
            event_time_iso=str(row["submitted_at"]),
            question_id=str(row["question_id"]),
            topic_id=str(row["topic_id"]),
            subject_id=str(row["subject_id"]),
            question_difficulty=(str(stored).upper()
                                 if str(stored).upper() in
                                 ("EASY", "MEDIUM", "HARD") else "EASY"),
            unit_id=(str(row["unit_id"]) if row.get("unit_id") else None),
            question_text=(str(row["question_text"])
                           if row.get("question_text") else None),
        ))
        truths[event_id] = bool(row["is_correct"])
    return events, OutcomeLedger(outcomes=truths)


def _past_rows(all_rows: list[dict], event: ReplayEvent) -> list[dict]:
    """Strictly-past rows of the same learner (timestamp < T)."""
    return [r for r in all_rows
            if str(r["learner_key"]) == event.learner_key
            and str(r["submitted_at"]) < event.event_time_iso]


PredictFn = Callable[[ReplayEvent, list[dict]], MLSignal]
"""Predictor input: target-free event + strictly-past rows. No ledger."""


def baseline_predictor(train_rate: float):
    """Baseline-B shadow predictor: learner prior accuracy, else fallback."""

    def predict(event: ReplayEvent, past: list[dict]) -> MLSignal:
        if not past:
            return MLSignal(status=SignalStatus.FALLBACK_COLD_START,
                            fallback_reason="no prior history")
        rate = (sum(1 for r in past if r.get("is_correct"))
                / len(past))
        return MLSignal(status=SignalStatus.SERVED, p_correct=rate,
                        confidence=0.5, model_version="baseline-b-shadow",
                        feature_schema_version="f1")

    return predict


def _validate_signal(signal: MLSignal) -> MLSignal:
    """Runner-side validation: malformed predictions become fallback."""
    try:
        if signal.status == SignalStatus.SERVED:
            if signal.p_correct is None or not 0.0 <= signal.p_correct <= 1.0:
                raise ContractViolation("bad probability")
            if signal.confidence is None or not (
                    0.0 <= signal.confidence <= 1.0):
                raise ContractViolation("bad confidence")
            if "shadow" not in signal.model_version:
                raise ContractViolation("foreign model version")
            if signal.confidence < LOW_CONFIDENCE_CUTOFF:
                return MLSignal(
                    status=SignalStatus.FALLBACK_LOW_CONFIDENCE,
                    fallback_reason="confidence below provisional cutoff")
        return signal
    except ContractViolation:
        return MLSignal(status=SignalStatus.FALLBACK_INVALID,
                        fallback_reason="malformed predictor output")


def run_replay(outcome_rows: list[dict],
               predict: PredictFn | None = None,
               retriever: RagRetriever | None = None,
               corpus: Sequence | None = None,
               ml_mode: str = "normal",
               rag_mode: str = "normal") -> list[ShadowRecord]:
    """Execute one deterministic replay pass over historical rows.

    ml_mode: normal | unavailable | timeout | invalid | low_confidence |
        version_mismatch.  rag_mode: normal | empty | unavailable |
        scope_mismatch | inactive | bad_citation | grounding_failure.
    """
    if ml_mode not in ("normal", "unavailable", "timeout", "invalid",
                       "low_confidence", "version_mismatch"):
        raise ContractViolation(f"unknown ml_mode: {ml_mode}")
    if rag_mode not in ("normal", "empty", "unavailable", "scope_mismatch",
                        "inactive", "bad_citation", "grounding_failure"):
        raise ContractViolation(f"unknown rag_mode: {rag_mode}")
    events, ledger = build_events(outcome_rows)
    engine = retriever or LexicalRetriever()
    documents = list(corpus or [])
    if rag_mode == "empty":
        documents = []
    records: list[ShadowRecord] = []
    failures: tuple[str, ...] = tuple(
        f for f in (f"ml:{ml_mode}" if ml_mode != "normal" else None,
                    f"rag:{rag_mode}" if rag_mode != "normal" else None)
        if f)
    for event in events:
        past = _past_rows(outcome_rows, event)
        tier = classify_history(len(past)).value
        if ml_mode in ("unavailable", "timeout"):
            signal = MLSignal(
                status=SignalStatus.FALLBACK_UNAVAILABLE,
                fallback_reason=f"simulated ml {ml_mode}")
        elif ml_mode == "invalid":
            try:
                signal = _validate_signal(MLSignal(
                    status=SignalStatus.SERVED, p_correct=float("nan"),
                    confidence=0.5, model_version="baseline-b-shadow",
                    feature_schema_version="f1"))
            except ContractViolation:
                signal = MLSignal(
                    status=SignalStatus.FALLBACK_INVALID,
                    fallback_reason="malformed predictor output")
        elif ml_mode == "low_confidence":
            signal = _validate_signal(MLSignal(
                status=SignalStatus.SERVED, p_correct=0.6, confidence=0.1,
                model_version="baseline-b-shadow",
                feature_schema_version="f1"))
        elif ml_mode == "version_mismatch":
            signal = _validate_signal(MLSignal(
                status=SignalStatus.SERVED, p_correct=0.6, confidence=0.7,
                model_version="foreign-model-v9",
                feature_schema_version="f1"))
        else:
            fn = predict or baseline_predictor(0.5)
            signal = _validate_signal(fn(event, past))
        ml_result = ShadowMLResult(event_id=event.event_id, signal=signal,
                                   history_tier=tier)

        rag_request = RagQuery(
            query=event.question_text or event.question_id,
            subject_id=("foreign-subject" if rag_mode == "scope_mismatch"
                        else event.subject_id),
            topic_id=(None if rag_mode == "scope_mismatch"
                      else event.topic_id),
            top_k=3)
        chunks: list = []
        citations: tuple[str, ...] = ()
        try:
            if rag_mode == "unavailable":
                raise _RagDown("simulated retriever outage")
            response = engine.retrieve(
                rag_request, documents, request_id=event.event_id)
            chunks = list(response.chunks)
            if rag_mode == "inactive":
                chunks = []
            citations = tuple(c.citation for c in chunks)
            if rag_mode == "bad_citation" and citations:
                citations = ("tampered::citation",)
            # Grounding requires citations to match actually retrieved
            # chunks — tampered handles can never validate.
            valid_citations = {c.citation for c in chunks}
            scope_clean = all(c.subject_id == event.subject_id
                              for c in chunks)
            grounding_ok = (bool(chunks) and all(citations)
                            and set(citations) <= valid_citations
                            and scope_clean)
            if rag_mode == "grounding_failure":
                grounding_ok = False
            if not chunks or not grounding_ok:
                reason = "scope_mismatch" if chunks and not scope_clean else (
                    f"simulated rag {rag_mode}" if rag_mode != "normal"
                    else "no grounded chunks")
                evidence = RAGEvidence(
                    status=SignalStatus.FALLBACK_UNAVAILABLE,
                    fallback_reason=reason)
            else:
                evidence = RAGEvidence(
                    status=SignalStatus.SERVED, citations=citations,
                    subject_id=event.subject_id, topic_id=event.topic_id,
                    retriever_version=engine.version, grounding_valid=True)
        except Exception:
            evidence = RAGEvidence(
                status=SignalStatus.FALLBACK_UNAVAILABLE,
                fallback_reason="retriever failure")
        rag_result = ShadowRAGResult(
            event_id=event.event_id, evidence=evidence, citations=citations,
            n_candidates=len(documents))

        served_ml = signal.status == SignalStatus.SERVED
        served_rag = evidence.status == SignalStatus.SERVED
        if served_ml and served_rag:
            action, reason = "REVIEW", "prediction + grounded evidence"
        elif served_ml:
            action, reason = "PRACTICE", "prediction only"
        elif served_rag:
            action, reason = "REVIEW", "grounded evidence only"
        else:
            action, reason = "FALLBACK", "deterministic engine path"
        advisory = ShadowAdvisory(
            event_id=event.event_id,
            bundle=AdvisoryBundle(
                learner_key=event.learner_key, topic_id=event.topic_id,
                ml=signal, rag=evidence,
                engine_snapshot_level="UNKNOWN",
                engine_snapshot_trend="UNKNOWN",
                created_at_iso=event.event_time_iso),
            advisory_action=action, reason=reason,
            fallback=not (served_ml or served_rag))
        records.append(ShadowRecord(
            event=event, ml=ml_result, rag=rag_result, advisory=advisory,
            outcome=AuthoritativeOutcome(
                event_id=event.event_id,
                is_correct=ledger.truth(event.event_id)),
            failure_injected=failures))
    return records


class _RagDown(Exception):
    """Local simulated outage (never a production path)."""
