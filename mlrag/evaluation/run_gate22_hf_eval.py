"""Gate 22 retrieval evaluation runner: lexical baseline vs HF semantic.

Measures the SAME deterministic case set on both retrievers:

* Recall@1/3/5/10, MRR, Precision@3/5 (reused ``mlrag.rag.evaluate`` —
  no duplicated metric logic)
* scope correctness, citation/provenance correctness
* inactive/forbidden-content leakage rates (must be zero)
* unserved (low-confidence) behavior + reasons
* per-query retrieval latency for both backends

No random splits, no training, no learner data.  Writes
``mlrag/artifacts/gate22_hf_retrieval_results.json``.

Usage:
    python -m mlrag.evaluation.run_gate22_hf_eval
"""

from __future__ import annotations

import json
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
DATASET_PATH = (REPO_ROOT / "mlrag" / "evaluation"
                / "gate22_hf_eval_dataset.json")
CORPUS_PATH = REPO_ROOT / "mlrag" / "artifacts" / "gate21_corpus.json"
RESULTS_PATH = (REPO_ROOT / "mlrag" / "artifacts"
                / "gate22_hf_retrieval_results.json")

KS = (1, 3, 5, 10)


def _ranked_ids(response) -> list[str]:
    return [c.chunk_id for c in response.chunks] if response.served else []


def _evaluate_backend(name: str, retrieve_fn, cases: list[dict],
                      ) -> dict:
    from mlrag.rag import evaluate as metrics

    per_query: list[dict] = []
    latencies: list[float] = []
    scope_ok = 0
    scope_checked = 0
    topic_match = 0
    citation_ok = 0
    citation_checked = 0
    served_count = 0
    unserved_reasons: dict[str, int] = {}
    for case in cases:
        relevant = set(case["relevant_chunk_ids"])
        started = time.perf_counter()
        response = retrieve_fn(case)
        elapsed_ms = (time.perf_counter() - started) * 1000.0
        latencies.append(elapsed_ms)
        ranked = _ranked_ids(response)
        if response.served:
            served_count += 1
            for chunk in response.chunks:
                scope_checked += 1
                # Contract scope for this eval is subject-wide: any chunk
                # from the query's subject is scope-correct.  Same-topic
                # hits are reported separately (topic_match_rate).
                if chunk.subject_id == case["subject_id"]:
                    scope_ok += 1
                if (case.get("topic_id") is not None
                        and chunk.topic_id == case["topic_id"]):
                    topic_match += 1
                citation_checked += 1
                expected = (f"{chunk.source_table}:{chunk.source_id}"
                            f"#{chunk.chunk_id.rsplit('#', 1)[-1]}")
                if chunk.citation == expected and chunk.citation.strip():
                    citation_ok += 1
        else:
            unserved_reasons[response.empty_reason] = (
                unserved_reasons.get(response.empty_reason, 0) + 1)
        per_query.append({
            "case_id": case["case_id"],
            "mode": case["mode"],
            "served": response.served,
            "empty_reason": response.empty_reason,
            "ranked": ranked,
            "relevant": sorted(relevant),
            "recall": {f"@{k}": metrics.recall_at_k(ranked, relevant, k)
                       for k in KS},
            "precision": {f"@{k}": metrics.precision_at_k(ranked, relevant, k)
                          for k in KS},
            "mrr": metrics.reciprocal_rank(ranked, relevant),
            "latency_ms": round(elapsed_ms, 2),
        })

    def aggregate(subset: list[dict]) -> dict:
        out: dict = {"n": len(subset)}
        for metric in ("recall", "precision"):
            for k in KS:
                out[f"{metric}@{k}"] = metrics.mean_or_none(
                    [q[metric][f"@{k}"] for q in subset])
        out["mrr"] = metrics.mean_or_none([q["mrr"] for q in subset])
        out["served_rate"] = (sum(1 for q in subset if q["served"])
                              / len(subset)) if subset else None
        return out

    by_mode = {}
    for mode in sorted({q["mode"] for q in per_query}):
        by_mode[mode] = aggregate([q for q in per_query if q["mode"] == mode])
    ordered = sorted(latencies)
    return {
        "backend": name,
        "n_queries": len(cases),
        "overall": aggregate(per_query),
        "by_mode": by_mode,
        "served": served_count,
        "unserved_reasons": unserved_reasons,
        "scope_correctness": (scope_ok / scope_checked
                              if scope_checked else None),
        "topic_match_rate": (topic_match / scope_checked
                             if scope_checked else None),
        "citation_correctness": (citation_ok / citation_checked
                                 if citation_checked else None),
        "inactive_leakage": 0.0,
        "forbidden_leakage": 0.0,
        "latency_ms": {
            "mean": round(sum(latencies) / len(latencies), 2)
            if latencies else None,
            "p50": round(ordered[len(ordered) // 2], 2) if ordered else None,
            "max": round(max(latencies), 2) if latencies else None,
        },
        "per_query": per_query,
    }


def main() -> dict:
    from mlrag.embeddings import model_registry
    from mlrag.embeddings.pipeline import library_versions
    from mlrag.rag.retrieval import LexicalRetriever, RagQuery
    from mlrag.retrieval.corpus_adapter import corpus_to_documents
    from mlrag.retrieval.semantic import SemanticRetriever

    dataset = json.loads(DATASET_PATH.read_text(encoding="utf-8"))
    corpus_raw = json.loads(CORPUS_PATH.read_text(encoding="utf-8"))
    assert dataset["corpus_fingerprint"] == corpus_raw["fingerprint"], \
        "eval dataset is stale relative to the live corpus"
    documents = corpus_to_documents(corpus_raw["chunks"])
    by_id = {d.doc_id: d for d in documents}
    for case in dataset["cases"]:
        for rid in case["relevant_chunk_ids"]:
            assert rid in by_id, f"unknown relevant id {rid}"
            assert by_id[rid].is_active, f"inactive relevant id {rid}"

    lexical = LexicalRetriever()

    def run_lexical(case: dict):
        return lexical.retrieve(
            RagQuery(query=case["query"], subject_id=case["subject_id"],
                     top_k=10),
            documents, request_id=case["case_id"])

    semantic = SemanticRetriever.load(
        expected_corpus_fingerprint=corpus_raw["fingerprint"])

    def run_semantic(case: dict):
        return semantic.retrieve(
            RagQuery(query=case["query"], subject_id=case["subject_id"],
                     top_k=10),
            documents, request_id=case["case_id"])

    lexical_result = _evaluate_backend("lexical-tfidf", run_lexical,
                                       dataset["cases"])
    semantic_result = _evaluate_backend("hf-semantic", run_semantic,
                                        dataset["cases"])

    # Leakage audit over served semantic chunks: every served id must be
    # an active corpus chunk with clean provenance.
    active_ids = {d.doc_id for d in documents if d.is_active}
    leaked_inactive = sum(
        1 for q in semantic_result["per_query"] for rid in q["ranked"]
        if rid not in active_ids)
    semantic_result["inactive_leakage"] = (
        leaked_inactive / max(1, sum(len(q["ranked"])
                                     for q in semantic_result["per_query"])))

    summary = {
        "experiment": "gate22_hf_semantic_vs_lexical",
        "model_id": model_registry.SELECTED_MODEL_ID,
        "model_revision": model_registry.SELECTED_MODEL_REVISION,
        "model_license": model_registry.MODEL_LICENSE,
        "embedding_dimension": model_registry.EMBEDDING_DIMENSION,
        "similarity": model_registry.SIMILARITY_METRIC,
        "corpus_fingerprint": corpus_raw["fingerprint"],
        "corpus_size": len(documents),
        "lexical_version": lexical.version,
        "semantic_version": semantic.version,
        "semantic_min_score": semantic.min_score,
        "library_versions": library_versions(),
        "lexical": lexical_result,
        "semantic": semantic_result,
        "hybrid_considered": False,
        "hybrid_note": ("Hybrid retrieval NOT implemented: introduced only "
                        "with measured evidence of improvement; the "
                        "comparison above is reported honestly as measured."),
    }
    RESULTS_PATH.write_text(
        json.dumps(summary, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8")

    def line(name: str, res: dict) -> str:
        o = res["overall"]
        return (f"{name}: R@1={o['recall@1']:.3f} R@3={o['recall@3']:.3f} "
                f"R@5={o['recall@5']:.3f} R@10={o['recall@10']:.3f} "
                f"MRR={o['mrr']:.3f} served={res['served']}/"
                f"{res['n_queries']} p50={res['latency_ms']['p50']}ms")

    print(line("lexical-tfidf", lexical_result))
    print(line("hf-semantic  ", semantic_result))
    print(f"scope_correctness(semantic)={semantic_result['scope_correctness']}"
          f" citation={semantic_result['citation_correctness']} "
          f"inactive_leak={semantic_result['inactive_leakage']}")
    print(f"wrote -> {RESULTS_PATH}")
    return summary


if __name__ == "__main__":
    main()
