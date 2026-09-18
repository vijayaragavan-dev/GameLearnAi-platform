# GATE 7 — RAG Retrieval Evaluation (offline only)

> Lexical TF-IDF baseline measured on the real seed corpus (offline SQL
> parse — no database, no credentials, no network). Auto-derived weak
> relevance only; nothing here is a human judgment or a production claim.

## A. Corpus used

413 documents ingested from 7 Flyway seed files (deterministic
`seed_parse.py` handling SELECT-line + multi-row VALUES forms, incl.
multi-line literals): 30 lesson sections/summaries (15 lessons), 234
question items, 149 topic descriptions. Catalog verified exact:
11 subjects / 29 units / 149 topics / 15 lessons / 234 questions.
Ingest: 0 inactive-skipped, 0 rejected.

## B/C. Query + relevance methodology

483 auto-derived queries, weak authorship labels (NOT human judgments):
`stem_to_topic` (234: stem → all same-topic docs, own included),
`explanation_to_siblings` (234: explanation first sentence → same-topic
siblings, own chunk excluded), `summary_to_lesson` (15: summary → lesson
sections).

## D–G. Measured results (subject-scoped candidates)

| Slice | n | R@1 | R@3 | R@5 | R@10 | P@1 | MRR |
|---|---|---|---|---|---|---|---|
| overall | 483 | 0.108 | 0.327 | 0.472 | 0.616 | 0.484 | 0.666 |
| stem_to_topic | 234 | 0.223 | 0.433 | 0.543 | 0.681 | 1.000 | 1.000 |
| explanation_to_siblings | 234 | 0.000 | 0.242 | 0.380 | 0.527 | 0.000 | 0.362 |
| summary_to_lesson | 15 | 0.000 | 0.000 | 0.800 | 1.000 | 0.000 | 0.203 |

served_rate 1.0 (empty rate 0). Single-rank metrics reported only where
defined; no metric fabricated.

## H/I. Scope + grounding

0 scope violations across 483 + rerun queries (asserted in-run);
inactive docs never scored; provenance/citations intact on every served
chunk (contract suite). Enforcement is code-level (`apply_scope` +
post-rank `validate_against`), never prompt-level.

## J. Duplicates

0 exact-text groups (normalized stems/explanations); 0 cross-topic
groups. No metric distortion; deduplication deferred (nothing to merge).

## K. Failure/degraded

Empty corpus → `empty_corpus`; no-match/inactive-only → `no_results_in_scope`;
malformed query/scope rejected; down retriever/embedding/vector-store map
to explicit reason codes with zero content. All covered by tests.

## L. Determinism/latency

Rerun rankings byte-identical (`determinism_rerun_identical: true`,
asserted in-run). 2.44 ms/query on a dev machine — capacity observation
only, no production claim.

## M/N. Lexical decision

**C — INSUFFICIENT EVIDENCE for a semantic decision; lexical preserved.**
For: topic discrimination is strong where it matters for grounding
(stem queries: P@1 1.0, MRR 1.0; 100% served; scope-safe). Against
sufficiency claims: sibling retrieval from generic explanation fragments
is weak (R@1 0.0, MRR 0.36 — verified by spot check: best lexical match
is the excluded own chunk, rank 1 falls to cross-topic vocabulary
overlap). That weakness is real but measured on weak authorship labels;
semantic embeddings are NOT justified until: (1) human relevance
judgments or a production query log exist, (2) the weakness reproduces
on that evidence. No embedding library installed, no vector DB created,
no prototype built — Phase 11 conditions unmet.

## O/Q. Dependencies / regression

Zero new dependencies (stdlib). Full suite green (see final report);
GATE 3/4/5 suites untouched and passing; experiment numerics untouched;
no backend/frontend/schema/API/AdaptiveEngine/credential changes.

## P/R. Tests / limitations

`test_rag_eval.py` (14 tests: metric math, invalid-metric None behavior,
determinism, scope, inactive, parser fixtures incl. comment-like text and
escaped quotes, duplicate helper). Limits: weak labels only; no human
judgments; no learner-query distribution; no semantic comparison;
dev-machine timing only.

## S. Verdict

**GATE 7: PASS (conditional C)** — methodologically defensible offline
evaluation, scope/provenance safe, deterministic, tested, isolated.
Semantic retrieval explicitly NOT authorized on current evidence.
