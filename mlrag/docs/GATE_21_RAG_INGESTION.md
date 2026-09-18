# GATE 21 — Production-Grade RAG Corpus Ingestion (NO TUNING, NO PROMOTION, NO INTEGRATION)

> Verdict: GATE 21 PASS. Live corpus: 413 serving chunks (30 lesson
> sections + 234 question items + 149 topic descriptions), fingerprint
> `451ddef7…`, idempotent, PII-free, deterministically reproducible.
> No embeddings, no vector store, no retrieval, no LLM calls, no web
> content, no backend/frontend/schema/data changes, no commits or pushes.

## 1. Executive summary

Gate 21 establishes the authoritative educational ingestion pipeline in
new package `mlrag/corpus/`, built strictly on top of the compatible Gate
6 primitives (`documents`, `chunking`, `ingest`, `extract_corpus`,
`safety`, `errors`, retriever/grounding contracts — reused, never
duplicated, never weakened). Live MySQL (read-only) yields exactly the
Gate 16 historical shape: 413 serving chunks from 403 examined records (5
inactive topics excluded pre-chunking, 0 rejected, 0 quarantined, 0
duplicates). Every chunk carries deterministic identity, dual SHA-256
hashes, full scope metadata, citation lineage, quarantine verdict, and
pinned versions (c1/doc-v1/chunk-v1/ingest-v1 over per-source
`content_version`). Poisoning/PII screening is deterministic with reason
codes; one coarse-scan finding was investigated to a benign curricular
vocabulary hit and resolved by switching to a precise artifact scan with
the evidence documented, not by redacting content. 64 new tests (+7
subtests); full suite 483 green including all Gate 17–20 regressions.

## 2. Pre-gate repository state

Baseline captured (`gate21_baseline_status/diffstat/backenddiff.txt`):
6 modified backend files + 7 untracked backend files + untracked `mlrag/`
— all pre-existing owner work, protected untouched. Pre-gate suite:
422/422 green. Live DB pre-gate: subjects 11/11, units 29/29, topics
154 (149 active), lessons 15/15, questions 234/234 (all explained).

## 3. Existing RAG implementation audit

Found and reused: `documents.RagDocument` (frozen, provenance-embedding
IDs, MAX_TEXT_CHARS=8000), `chunking` (1500-char paragraph packing,
sentence-aware long split, zero loss), `ingest_records/ingest_lesson/
ingest_question/ingest_topic` (active-before-chunking, loud rejections),
`extract_corpus` (SELECT-only, explicit columns, already excludes
`correct_answer`), `safety` (DATA delimiters + override quarantine),
`errors` taxonomy, `grounding`, retriever contract (scope-first,
active-only), `vectors` (embeddings deferred — respected, nothing added),
`seed_parse`/`run_eval` conventions. Deliberately NOT reused where
incompatible: nothing — all ingestion primitives verified compatible.
`retrieval.py` (Gate 22 territory) untouched.

## 4. Corpus source contract

Chunk sources: lessons / topics / questions. Scope-label + integrity
sources: subjects / units (no topic linkage → cannot satisfy topic scope,
per established Gate 6 decision). Excluded deliberately: quizzes
(assessment instruments), all learner-state/secret tables (19 forbidden
tables), 24 forbidden columns (answers, keys, scores, mastery, XP, PII,
telemetry). Question chunks carry stem + options + explanation only —
`correct_answer` never selected, never persisted (audited in SQL + tests).

## 5. Trust boundary

Corpus text is DATA, never instructions. Ingestion performs no prompt
construction, tool calls, URL fetches, code/filesystem/DB operations, and
no LLM trust decisions (active/authorized/scoped verdicts are
deterministic code). Screening only classifies + routes; quarantined text
stays inert data with reason codes.

## 6. Files created/modified

Created under `mlrag/` only: `corpus/{__init__,contract,normalize,
screening,build,snapshot}.py`; `tests/{gate21_fixtures,
test_gate21_corpus_contract,test_gate21_corpus_normalize,
test_gate21_corpus_screening,test_gate21_corpus_build,
test_gate21_corpus_security}.py`; `artifacts/gate21_corpus.json`
(567,647 chars, canonical); this report. Modified: nothing outside
`mlrag/`; no existing file modified.

## 7. Source extraction methodology

Live path reuses `extract_corpus.fetch_corpus` (guarded SELECT-only) over
the shared read-only connection helper. Pre-ingestion audit refuses
forbidden tables/columns loudly (`_audit_extraction_shape`). Records are
deterministically ordered by `(table, id)`; per-record ingestors reused
unchanged for exact record linkage.

## 8. Active/inactive filtering

`is_active` gating happens inside the reused ingestors BEFORE chunk
creation (InactiveContentBlocked → counted skip). Live: 5 inactive topics
excluded, 0 chunks from them. Transition detectable: deactivating a topic
changes the fingerprint and flips the source snapshot to stale (tested).

## 9. Provenance model

Per chunk: source_table/source_id (verbatim), subject/unit/topic/lesson/
question IDs, difficulty, content_version (updated_at ISO), title,
source_type, source_hash (original-field SHA-256) + text_hash
(normalized SHA-256), citation `table:id#cN`. Resolved against
authoritative subject/topic maps; unknown/inactive/mismatched scope
rejected with codes (`scope_unknown_topic/subject`,
`scope_mismatch:topic_subject/topic_unit`, `scope_inactive_*`).

## 10. Document identity/versioning

`document_id = {table}:{source_id}` (source identity);
`chunk_id = {table}:{source_id}#c{index}` (existing stable scheme kept).
Pinned: corpus c1, document doc-v1, chunk chunk-v1, ingestion ingest-v1,
plus per-source content_version. Content edits and `updated_at` bumps both
change hashes/fingerprint (tested); repeats are identical (tested).

## 11. Content normalization

NFC (never NFKC), CRLF→LF, per-line rstrip (leading indentation
preserved by policy), 3+-blank-line runs → exactly 2, overall strip. No
rewriting/paraphrase/LLM cleaning/correction/merging/invention. Original
vs normalized hashes always distinguishable (tested).

## 12. Duplicate handling

Exact chunk-identity duplicates: keep first, drop rest, report count
(rationale documented). Normalized-content duplicates across DISTINCT
sources: keep ALL with full provenance, report groups, never merge
(rationale documented). Live: 0 identity dupes, 0 content groups.

## 13. Chunking methodology

Reused unchanged: paragraph packing to 1500 chars, sentence-aware
long-paragraph split, hard-split fallback, stable order, zero character
loss, context line from source title only. Question+explanation stay in
one item chunk; lesson sections keep heading context. No size retuning.

## 14. Metadata/scope integrity

Every persisted chunk validated (`validate_chunk_record`, 24 exact keys):
active=true only, versions pinned, quarantine coherent, scope block
consistent with chunk fields, IDs prefix-consistent. Live: 11 subjects /
149 topics / 30 unit buckets (29 units + unscoped-topic bucket) / 15
lessons covered; difficulties EASY 146 / MEDIUM 226 / HARD 41.

## 15. Citation lineage

Every chunk yields `table:id#cN` plus title/section, full scope, and
content_version — never "AI generated". Provenance tests trace
chunk→document→source→scope→version with zero orphans.

## 16. Hashing/fingerprint

SHA-256 throughout (sole integrity hash; no weak hashes). Corpus
fingerprint over canonical versions + sorted serving-chunk tuples +
counts. Live fingerprint:
`451ddef72317c230f7f59a873e7ec8595068ae5c0277dca6bac1b900a946f2b9`.
Source snapshot (counts + max `updated_at` + id-stamped hash per table)
supports staleness detection (`is_stale`).

## 17. Idempotency

Same-process rebuild identical, shuffled-input rebuild identical
(fingerprints + canonical chunks), independent-process artifact
byte-identical (567,647 chars, sha `5f6c8247…`). No duplicate
accumulation by construction (identity-dedupe + deterministic IDs).

## 18. Poisoning/security checks

31-pattern fixed families (prompt_injection, instruction_hijack,
impersonation, credential_request, exfiltration, tool_invocation,
code_execution) → `review_quarantined` + codes, excluded from serving,
counted. Narrow multi-word shapes: "nervous system", "instruction
manual", "system of equations", "ecosystem" verified clean (bare
`system:` deliberately NOT a pattern). Live: 0 quarantined. No LLM, no
deletion, no execution path.

## 19. PII/secret audit

Ingestion-time precise scans (email/JWT/secret-assignment/bearer) on every
chunk: ZERO hits live (any hit aborts the run). One coarse-scan finding
(`email` substring) was STOP-investigated to benign curricular vocabulary
— a requirements question with option "The system shall email invoices"
— and resolved by replacing the coarse list with a precise artifact scan
(email-address/JWT/secret/bearer patterns + forbidden JSON keys), with
this evidence trail instead of any redaction. Artifact scan: 0 hits.

## 20. Live corpus statistics

Tables: lessons 15, questions 234, topics 154, subjects 11, units 29.
Examined 403 → serving 413 (30 lesson sections [15 content + 15 summary]
+ 234 questions + 149 topics) — reproduces Gate 16's ~413/30/234/149
exactly (no forcing; counted live). Inactive excluded 5; rejected 0;
quarantined 0; identity dupes 0; content dupe groups 0; empty 0.

## 21. Reproducibility results

A. Same-process ×2 identical: PASS. B. Independent-process byte-identical
artifact: PASS. C. Shuffled input identical: PASS. Fingerprint stable
across all three; serialization canonical (`sort_keys`, UTF-8, no
timestamps in fingerprint inputs).

## 22. Inactive/stale-content tests

Inactive rows yield zero docs across all three tables; mixed sets exclude
precisely; transitions change fingerprint + snapshot-stale verdict;
identical snapshots not stale; stale artifacts detectable via
`is_stale` (never silently current). All fixture-based (no DB mutation).

## 23. Cross-scope tests

Topic↔subject, record↔unit, unknown/inactive topic/subject, invalid
difficulty, missing provenance all rejected with precise codes; legitimate
re-scoping follows the new topic's scope (tested, not blocked).

## 24. Forbidden-field tests

7-trap matrix (selected_answer/is_correct/score, correct_answer,
mastery/user_id, email, XP/streak, progress/timing, password) aborts the
run; forbidden table in input aborts; question chunks carry stem/options/
explanation keys only; artifact JSON has zero forbidden keys.

## 25. Chunk determinism tests

Same document → same chunks/IDs/hashes; shuffled documents → identical
output; repeat ingestion → no accumulation; provenance identical. (Plus
normalization determinism: endings/whitespace/NFC/original-vs-normalized.)

## 26. Performance

413 serving chunks: 11.67 s total (≈35 chunks/s; dominated by read-only
extraction of LONGTEXT), peak 79.3 MB tracemalloc (result buffers
included). Correctness prioritized; no optimization.

## 27. Full test results

`python -m pytest mlrag/tests`: 483 passed (+7 subtests), 0 failed —
422 pre-existing (all Gate 17/18/19/20 suites incl. 46 RAG tests) + 61 new
Gate 21 tests. No existing test modified. Zero new dependencies (stdlib
only: hashlib/json/re/unicodedata/random/time/tracemalloc/argparse).

## 28. Backend/database protection

Pre/post `git status --short` + `git diff --stat`: zero delta. No
backend/frontend/Spring/AdaptiveEngine/.env/Flyway changes; no schema or
data changes (counts re-verified identical; SELECT-only validated path);
only new `mlrag/` files.

## 29. Known limitations

Lexical-only foundation (no embeddings per deferred decision — Gate 22
concern); subjects/units extraction lacks `updated_at` (staleness for
those tables rests on count+id hash); 5 inactive legacy topics excluded by
design; zero live quarantine/duplicate cases observed (mechanisms proven
by fixtures); LONGTEXT extraction dominates runtime.

## 30. Gate 21 final verdict

CORPUS INGESTION IMPLEMENTED: YES
SOURCE EXTRACTION: PASS
ACTIVE/INACTIVE ENFORCEMENT: PASS
PROVENANCE INTEGRITY: PASS
DOCUMENT VERSIONING: PASS
CHUNKING: PASS
METADATA/SCOPE INTEGRITY: PASS
CITATION LINEAGE: PASS
CORPUS FINGERPRINT: PASS
IDEMPOTENCY: PASS
POISONING/INSTRUCTION SAFETY: PASS
PII/SECRET SAFETY: PASS
DETERMINISM: PASS
LIVE SNAPSHOT: PASS
ARTIFACT SAFETY: PASS
GATE 17 REGRESSION: PASS
GATE 18 REGRESSION: PASS
GATE 19 REGRESSION: PASS
GATE 20 REGRESSION: PASS
BACKEND PROTECTED: YES
DATABASE PROTECTED: YES
GATE 21: PASS
