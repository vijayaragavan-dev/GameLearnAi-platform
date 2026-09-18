"""Offline retrieval evaluation runner (GATE 7).

Reads the repo's Flyway seed SQL (real curricular content, no learner
data, no database, no credentials, no network), ingests documents,
derives auto-labeled queries, scores the lexical baseline, analyzes
duplicates, and writes aggregates to
mlrag/artifacts/gate7_results.json.  Deterministic: repeated runs
produce identical rankings (asserted in-process).
"""

from __future__ import annotations

import json
import re
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
SEED_DIR = REPO_ROOT / "backend" / "src" / "main" / "resources" \
    / "db" / "migration"
SEED_FILES = ("V11__seed_initial_subjects.sql",
              "V12__seed_programming_demo_content.sql",
              "V14__seed_remaining_subjects_demo_content.sql",
              "V22__add_subject_worlds_batch1.sql",
              "V24__seed_new_subjects_syllabus.sql",
              "V27__seed_new_subjects_game_questions.sql",
              "V28__seed_new_subjects_round2_questions.sql")
ARTIFACT_PATH = (Path(__file__).resolve().parent.parent
                 / "artifacts" / "gate7_results.json")

KS = (1, 3, 5, 10)


def _normalize(text: str) -> str:
    return re.sub(r"\s+", " ", text.lower()).strip()


def main() -> dict:
    from mlrag.rag import evaluate as metrics
    from mlrag.rag import eval_queries, ingest, retrieval, seed_parse

    parsed = seed_parse.parse_seed_files(
        [str(SEED_DIR / name) for name in SEED_FILES])
    topics = {str(t["id"]): t for t in parsed.get("topics", [])}
    subjects = {str(s["id"]): s for s in parsed.get("subjects", [])}

    for table in ("lessons", "questions"):
        for row in parsed.get(table, []):
            topic = topics.get(str(row.get("topic_id")), {})
            row.setdefault("subject_id", topic.get("subject_id"))
            row.setdefault("unit_id", topic.get("unit_id"))
    for table in ("lessons", "questions", "topics"):
        for row in parsed.get(table, []):
            row["updated_at"] = row.get("updated_at") or "seed"

    all_documents = []
    ingest_stats: dict[str, dict] = {}
    for table in ("lessons", "questions", "topics"):
        result = ingest.ingest_records(parsed.get(table, []),
                                       source_table=table)
        all_documents.extend(result.documents)
        stats = result.stats
        ingest_stats[table] = {
            "documents": stats.documents,
            "skipped_inactive": stats.skipped_inactive,
            "rejected": stats.rejected,
            "rejection_reasons": sorted(set(stats.rejection_reasons))[:10],
        }

    queries = eval_queries.derive_queries(parsed, all_documents)
    engine = retrieval.LexicalRetriever()

    # Duplicate analysis over question stems + explanations.
    seen: dict[str, list[str]] = {}
    for row in parsed.get("questions", []):
        for field in ("question_text", "explanation"):
            value = row.get(field)
            if isinstance(value, str) and value.strip():
                seen.setdefault(_normalize(value), []).append(
                    f"{row['id']}:{field}")
    duplicate_groups = sorted(
        [sorted(v) for v in seen.values() if len(v) > 1])
    cross_topic_dupes = 0
    by_question = {str(r["id"]): r for r in parsed.get("questions", [])}
    for group in duplicate_groups:
        group_topics = {str(by_question[g.split(":")[0]]["topic_id"])
                        for g in group if g.split(":")[0] in by_question}
        if len(group_topics) > 1:
            cross_topic_dupes += 1

    per_query: list[dict] = []
    started = time.perf_counter()
    for item in queries:
        request = retrieval.RagQuery(
            query=item.text, subject_id=item.subject_id,
            topic_id=None, unit_id=None, top_k=10)
        # Subject scope (broad candidate set); relevance is topic-graded.
        response = engine.retrieve(
            request, all_documents, request_id=item.query_id)
        ranked = [c.chunk_id for c in response.chunks]
        for chunk in response.chunks:  # scope audit: never foreign
            assert chunk.subject_id == item.subject_id, chunk.chunk_id
        per_query.append({
            "query_id": item.query_id,
            "mode": item.mode,
            "served": response.served,
            "ranked": ranked,
            "relevant": sorted(item.relevant_doc_ids),
            "recall": {f"@{k}": metrics.recall_at_k(
                ranked, item.relevant_doc_ids, k) for k in KS},
            "precision": {f"@{k}": metrics.precision_at_k(
                ranked, item.relevant_doc_ids, k) for k in KS},
            "mrr": metrics.reciprocal_rank(ranked, item.relevant_doc_ids),
        })
    elapsed_ms = (time.perf_counter() - started) * 1000.0

    # Determinism: identical rankings on a second pass.
    for item, first in zip(queries, per_query):
        again = engine.retrieve(
            retrieval.RagQuery(query=item.text,
                               subject_id=item.subject_id, top_k=10),
            all_documents, request_id=item.query_id + ":rerun")
        assert [c.chunk_id for c in again.chunks] == first["ranked"]

    def aggregate(mode: str | None) -> dict:
        subset = [q for q in per_query
                  if mode is None or q["mode"] == mode]
        out: dict = {"n_queries": len(subset),
                     "served_rate": (sum(1 for q in subset if q["served"])
                                     / len(subset)) if subset else None}
        for metric in ("recall", "precision"):
            for k in KS:
                out[f"{metric}@{k}"] = metrics.mean_or_none(
                    [q[metric][f"@{k}"] for q in subset])
        out["mrr"] = metrics.mean_or_none([q["mrr"] for q in subset])
        return out

    summary = {
        "experiment": "rag_retrieval_lexical_baseline",
        "corpus_source": "flyway seed SQL (offline, no database)",
        "seed_files": list(SEED_FILES),
        "catalog_counts": {t: len(parsed.get(t, [])) for t in
                           ("subjects", "units", "topics", "lessons",
                            "questions")},
        "ingest_stats": ingest_stats,
        "n_documents": len(all_documents),
        "n_queries": len(queries),
        "queries_by_mode": {m: sum(1 for q in per_query if q["mode"] == m)
                            for m in ("stem_to_topic",
                                      "explanation_to_siblings",
                                      "summary_to_lesson")},
        "overall": aggregate(None),
        "by_mode": {m: aggregate(m) for m in
                    ("stem_to_topic", "explanation_to_siblings",
                     "summary_to_lesson")},
        "duplicates": {
            "exact_text_groups": len(duplicate_groups),
            "cross_topic_groups": cross_topic_dupes,
            "largest_group": max((len(g) for g in duplicate_groups),
                                 default=0),
        },
        "retrieval_ms_total": round(elapsed_ms, 1),
        "retrieval_ms_per_query": (round(elapsed_ms / len(per_query), 2)
                                   if per_query else None),
        "determinism_rerun_identical": True,
        "scope_violations": 0,
        "relevance_method": "automatically derived from authorship "
                            "(weak labels, NOT human judgments)",
        "deployment_ready": False,
    }
    ARTIFACT_PATH.parent.mkdir(parents=True, exist_ok=True)
    ARTIFACT_PATH.write_text(json.dumps(summary, indent=2),
                             encoding="utf-8")
    print(json.dumps(summary, indent=2))
    return summary


if __name__ == "__main__":
    main()
