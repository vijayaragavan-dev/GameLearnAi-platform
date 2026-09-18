"""Auto-derived evaluation queries (GATE 7, PHASE 3).

Relevance here is established from authorship, not human judgment:
a query derived from source row R is relevant to chunks built from R
(and, where stated, R's same-topic siblings).  These labels are WEAK —
they measure topic discrimination and self-consistency of the lexical
baseline, never user-perceived quality.  They must never be presented
as human relevance judgments.
"""

from __future__ import annotations

from dataclasses import dataclass

from .documents import RagDocument


@dataclass(frozen=True)
class EvalQuery:
    """One evaluation case with provenance, not a user query."""

    query_id: str
    mode: str  # stem_to_topic | explanation_to_siblings | summary_to_lesson
    text: str
    subject_id: str
    topic_id: str
    unit_id: str | None
    relevant_doc_ids: frozenset[str]
    notes: str


def _first_sentence(text: str) -> str:
    for sep in (". ", ".\n", "? ", "! "):
        if sep in text:
            return text.split(sep)[0] + sep.strip()
    return text.strip()


def derive_queries(records: dict[str, list[dict]],
                   documents: list[RagDocument]) -> list[EvalQuery]:
    """Derive evaluation queries from parsed seed records + built docs."""
    by_source: dict[tuple[str, str], list[RagDocument]] = {}
    for document in documents:
        by_source.setdefault(
            (document.source_table, document.source_id), []).append(document)
    by_topic: dict[str, list[RagDocument]] = {}
    for document in documents:
        by_topic.setdefault(document.topic_id, []).append(document)

    queries: list[EvalQuery] = []
    for record in records.get("questions", []):
        question_id = str(record["id"])
        own = [d.doc_id for d in
               by_source.get(("questions", question_id), [])]
        if not own:
            continue
        siblings = [d.doc_id for d in by_topic.get(str(record["topic_id"]), [])
                    if d.doc_id not in own]
        stem = str(record.get("question_text") or "").strip()
        if stem:
            queries.append(EvalQuery(
                query_id=f"stem:{question_id}", mode="stem_to_topic",
                text=stem, subject_id=str(record["subject_id"]),
                topic_id=str(record["topic_id"]),
                unit_id=record.get("unit_id"),
                relevant_doc_ids=frozenset(
                    d.doc_id for d in by_topic[str(record["topic_id"])]),
                notes="stem retrieves its own topic (own chunk included)"))
        explanation = record.get("explanation")
        if isinstance(explanation, str) and explanation.strip() and siblings:
            queries.append(EvalQuery(
                query_id=f"expl:{question_id}",
                mode="explanation_to_siblings",
                text=_first_sentence(explanation),
                subject_id=str(record["subject_id"]),
                topic_id=str(record["topic_id"]),
                unit_id=record.get("unit_id"),
                relevant_doc_ids=frozenset(siblings),
                notes="explanation retrieves same-topic siblings (own excluded)"))
    for record in records.get("lessons", []):
        lesson_id = str(record["id"])
        sections = [d.doc_id for d in
                    by_source.get(("lessons", lesson_id), [])
                    if ":summary" not in d.doc_id]
        summary = record.get("summary")
        if (isinstance(summary, str) and summary.strip() and sections):
            queries.append(EvalQuery(
                query_id=f"summ:{lesson_id}", mode="summary_to_lesson",
                text=_first_sentence(summary),
                subject_id=str(record["subject_id"]),
                topic_id=str(record["topic_id"]),
                unit_id=record.get("unit_id"),
                relevant_doc_ids=frozenset(sections),
                notes="summary retrieves its lesson sections"))
    queries.sort(key=lambda q: q.query_id)
    return queries
