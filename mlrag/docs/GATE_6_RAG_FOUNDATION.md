# GATE 6 — RAG Foundation (offline only)

> Deterministic, provenance-preserving, scope-safe retrieval groundwork.
> No vector database, no embeddings service, no LLM calls, no production
> wiring. Spring Boot remains authoritative; MySQL remains source of truth.

## 1. Corpus sources (verified read-only from entities + migrations)

| Source | Entity fields used | Active flag | Version proxy |
|---|---|---|---|
| `lessons` | title, content (LONGTEXT), summary, difficulty, source_type | `is_active` | `updated_at` ISO |
| `questions` | question_text, options_json, explanation, difficulty, source_type | `is_active` | `updated_at` ISO |
| `topics` | name, description, difficulty | `is_active` | `updated_at` ISO |
| `subjects`/`units` | name, description | `is_active` | scope labels only (no topic link → not retrievable chunks) |

Relationships: subject → units → topics; topic → lessons/questions;
quiz → topic (quizzes excluded from corpus: assessment instruments, not
explanatory content). No explicit content-version column exists anywhere
(documented as unavailable; `updated_at` used, else `"unversioned"`).
Content tables carry no PII. Quality limits: only 15 lessons seeded;
topic descriptions may be absent (counted as unusable, never invented);
5 legacy topics deactivated (correctly excluded); near-duplicate risk
across round-1/round-2 game questions (same topic, distinct rows — kept
with distinct provenance, deduplication explicitly deferred).

## 2. Catalog counts (seed-migration evidence; live-DB validation deferred —
no read-only channel in this session)

Subjects 11 (all active assumed pending live check), units 29, topics
149 (5 legacy inactive → ~144 active), lessons 15, quizzes 73 (excluded),
questions 234. Estimated retrievable documents: ~15 lesson sections +
~234 question items + topics-with-descriptions (counted at ingestion;
absent descriptions rejected, not fabricated).

## 3. Document/chunk contract

`RagDocument` (frozen): `doc_id = {table}:{id}#c{index}` embedding its own
provenance (constructor rejects forged IDs); required subject/topic/text/
active/version; optional unit/lesson/question/difficulty/title/type;
`MAX_TEXT_CHARS=8000`; `citation` property (`table:id#cN`).
Chunking: paragraph packing to 1500 chars, sentence-aware long-split,
stable order, zero character loss, context line from source title only.

## 4. Retrieval contract + scope proof

`RagQuery{query, subject_id!, topic_id?, unit_id?, lesson_id?, top_k}` →
`RagRetriever.retrieve()` → existing `RetrievalResponse` (served +
chunks | degraded + `empty_reason`). `apply_scope()` eliminates
non-matching/inactive documents BEFORE scoring; per-chunk scope
re-assertion plus `validate_against()` after ranking. Proven by tests:
mixed-scope corpora return only in-scope chunks at all four levels;
cross-scope queries degrade (`no_results_in_scope`) instead of leaking.

## 5. Provenance/grounding

`validate_grounded()` admits only approved-source, active, scope-matching
chunks with non-empty ID + citation; anything else raises
(`GroundingFailure`/`ScopeViolation`) for the future answer layer to
degrade on. Citations travel on every chunk.

## 6. Safety boundary

Retrieved text is DATA: `prepare_context_span()` quarantines
instruction-override patterns (fixed reviewable list) then wraps spans in
`<<<RETRIEVED-DATA-BEGIN/END>>>` with control chars stripped. Scope lives
in code, never in prompts.

## 7. Failure behavior

Typed errors (`EmptyCorpus`, `NoResults`, inactive/malformed quarantine,
retriever/embedding/vector-store unavailability) map to explicit
`empty_reason` codes via `degraded_response()` — never silent, never
ungrounded content presented as retrieved. `Embedder`/`VectorStore` are
abstract-only.

## 8. Dependencies / vector-store decision

Zero new dependencies (stdlib only). **Decision: deferred,
provider-neutral** (`vectors.BACKEND_DECISION`): foundation corpus is
small, scoped, and served deterministically by the TF-IDF baseline; no
audit evidence justifies vector infrastructure in this gate. A backend
later implements `Embedder`/`VectorStore` without touching the boundary.

## 9. Tests

`test_rag.py`: **32/32 pass**, covering all 20 required areas with labeled
fixtures (contract, metadata, chunking determinism/losslessness, active
filter, rejection, 4 scope levels, cross-scope degraded, empty,
retriever/embedding/vector failures, grounding, citations, injection
boundary, ingestion determinism, SELECT-only corpus queries, no write
path). Full suite regression below.

## 10. Limitations

Lexical TF-IDF is a foundation baseline, not a recall claim; no
re-ranking, no semantic search, no answer generation; duplicate handling
deferred; live corpus counts/quality pending a read-only channel;
subject/unit prose not retrievable (scope labels only).

## 11. Verdict

**GATE 6: PASS** — deterministic, provenance-preserving, scope-safe,
tested (32 new + full-suite green), isolated to `mlrag/`. No backend,
frontend, schema, API, AdaptiveEngine, credential, commit, or push
involved. Deployment/integration explicitly NOT authorized.
