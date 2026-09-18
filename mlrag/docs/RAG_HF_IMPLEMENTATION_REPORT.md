# RAG + Pretrained Hugging Face Embeddings — Implementation Report (Gate 22)

> FINAL VERDICT: **PASS**. A real, secure, reproducible, measured
> pretrained-model semantic retrieval layer over the authoritative Gate 21
> corpus. No fake AI, no fabricated metrics, no backend/database changes,
> all 559 mlrag tests green.

## 1. Objective

Implement the production-grade RAG retrieval layer deferred by Gate 21 —
real pretrained Hugging Face embeddings, a persistent fingerprint-bound
index, scope-first semantic retrieval, deterministic evaluation against
the lexical baseline, and a grounding-ready evidence contract — without
breaking the existing application.

## 2. Preflight state (preserved)

* Branch `MlRag`; pre-existing modifications kept untouched: modified
  `backend/.env.example`, 3 modified backend sources, 7 untracked backend
  files, `backend/effective-pom.txt`, untracked `mlrag/`.
* No `git reset / clean / checkout -- . / commit / push` at any point.
* Gate 21 contracts reused, never duplicated: `validate_chunk_record`,
  Gate 6 `RagDocument` / `LexicalRetriever` / `apply_scope` /
  `evaluate` metrics / `safety` delimiters / `errors` taxonomy.
  `mlrag/rag/vectors.py` and `mlrag/rag/retrieval.py` NOT modified
  (all Gate 6 boundary tests still pass unmodified).

## 3. Corpus (source of truth)

* `mlrag/artifacts/gate21_corpus.json`: **413 serving chunks**
  (30 lesson sections + 234 questions + 149 topics), fingerprint
  `451ddef72317c230f7f59a873e7ec8595068ae5c0277dca6bac1b900a946f2b9`.
* Corpus NEVER mutated by this task (read-only loads; verified by
  `git status`: `gate21_corpus.json` unmodified).

## 4. Model candidates (evidence-based, 2026-09-15 via Hub API)

| Model | Rev (40-hex SHA) | Dim | Size | License | Prefix protocol | Selected? |
|---|---|---|---|---|---|---|
| sentence-transformers/all-MiniLM-L6-v2 | 1110a243fdf4706b3f48f1d95db1a4f5529b4d41 | 384 | ~22M / ~80MB | Apache-2.0 | none (symmetric) | **YES** |
| BAAI/bge-small-en-v1.5 | 5c38ec7c405ec4b44b94cc5a9bb96e735b38267a | 384 | ~33M / ~133MB | MIT | query instruction for full quality | no — equal dim at 1.6x size + asymmetric protocol risk |
| intfloat/e5-small-v2 | ffb93f3bd4047442299a41ebb6fa998a38507c52 | 384 | ~33M / ~118MB | MIT | MANDATORY query:/passage: | no — mandatory prefixes are a silent-quality-loss hazard |
| sentence-transformers/all-mpnet-base-v2 | e8c3b32edf5434bc2275fc9bab85f82640a19130 | 768 | ~109M / ~420MB | Apache-2.0 | none | no — 5x size/2x width, no measurable gain at 413 docs |

Hidden sizes verified from each repo's `config.json`; SHAs from
`huggingface_hub.model_info`. Only `config.json` metadata fetched for
non-selected candidates — no weights downloaded except the selection.

**Selected:** `sentence-transformers/all-MiniLM-L6-v2`
@ `1110a243fdf4706b3f48f1d95db1a4f5529b4d41`, dim **384**,
Apache-2.0, symmetric encoder (no prefix protocol = smallest bug
surface), ~91.6 MB on disk, CPU inference. Recorded in
`mlrag/embeddings/model_registry.py` (single selection enforced by test).

## 5. Dependencies (all pinned, CPU-only, justified in requirements.txt)

numpy 2.3.5, torch 2.10.0, transformers 5.2.0, tokenizers 0.22.2,
safetensors 0.7.0, huggingface-hub 1.4.1, sentence-transformers 5.5.1,
scikit-learn 1.8.0 (pre-existing), Python 3.13.7. No vector DB, no LLM
client, no GPU stack, no redundant embedding frameworks.

## 6. Architecture

* `mlrag/embeddings/hf_embedder.py` — `HFEmbedder` implements the
  existing `vectors.Embedder` interface: pinned id+revision, local CPU
  only (`trust_remote_code=False`, `eval()` + `no_grad`), L2-normalized
  output, dimension cross-checked (384). Load/inference failure raises
  `EmbeddingFailure` — never random/hash/lexical fallback.
* `mlrag/embeddings/pipeline.py` — deterministic build: stable
  chunk_id order, forbidden-key audit per record (active-only enforced),
  one embedding per chunk, float32 matrix + `.npz` + JSON manifest.
* **Index design (deliberately lightweight):** `glr-hf-index-v1` =
  `gate22_hf_index.npz` (normalized 413×384 matrix + chunk ids) plus
  `gate22_hf_index_manifest.json` (model pin, corpus/embedding/config
  fingerprints, library versions, timestamp). Metadata stays
  authoritative in the Gate 21 artifact — never duplicated into the
  index. No external vector DB: evaluated as unjustified at 413 docs
  (numpy dot-product over the scoped subset is microseconds).
* `mlrag/retrieval/semantic.py` — `SemanticRetriever` on the same
  `RagRetriever` boundary as lexical: **scope filter FIRST**
  (subject/topic/unit/lesson + optional difficulty, inactive dropped),
  then cosine rank over scoped candidates only, deterministic
  (-score, chunk_id) order, top-K, `min_score=0.20` floor, post-hoc
  `validate_against` scope check. Below-floor/empty outcomes degrade
  explicitly (`insufficient_evidence`, `no_results_in_scope`,
  `empty_corpus`, `index_stale_for_scope`) — never ungrounded content.
* `mlrag/retrieval/corpus_adapter.py` — mechanical Gate 21 record →
  `RagDocument` mapping (both retrievers rank identical documents).
* `mlrag/retrieval/evidence.py` — grounding-ready bundle: delimited
  DATA spans, stable citations, scope, scores, corpus fingerprint;
  instruction-shaped spans stay servable data + flagged (never obeyed,
  never silently dropped); `build_gemini_context` renders the
  cite-only prompt section.

## 7. Provenance / citations

Every served chunk carries `chunk_id`, `source_table/source_id`,
`content_version`, full scope, and the verbatim Gate 21 `citation`
(`table:id#cN`, never invented). Measured citation correctness: **1.0**.

## 8. Security controls

* Retrieved text = DATA (`<<<RETRIEVED-DATA-BEGIN/END>>>`, control
  chars stripped); scope comes only from typed query fields — query
  text cannot forge metadata, widen scope, or request hidden fields
  (tested with topic/subject ids embedded in hostile queries).
* Query bounds: empty rejected (`ContractViolation`), >2000 chars
  deterministically truncated, Unicode/code/SQL safe.
* Secret hygiene: precise scans (email-address/JWT/secret-assign/
  bearer/private-key) over all new code + artifacts → **0 hits**.
  No PII/learner-state keys enter embeddings (structural key audit).
* Failure policy: model unavailable → `EmbeddingFailure`; missing/
  corrupt index → `CorruptEmbeddingArtifact`; fingerprint drift →
  `StaleEmbeddingArtifact`; no evidence → `insufficient_evidence`.
  All explicit, all tested, zero silent fallbacks.

## 9. Adversarial tests (all pass)

12-query injection battery (override/system-impersonation/scope-bypass/
secret-reveal/SQL/XSS/repetition/Unicode) stays in-scope or degrades;
poisoned chunk (`Ignore previous instructions…`) served as flagged
delimited data and quoted — not obeyed — by the Gemini context builder.

## 10. Evaluation methodology

Deterministic 40-case set (`gate22_hf_eval_dataset.json`, all labeled
synthetic, never learner data): 30 extractive probes (title + lead
sentence, stride-sampled 8 lessons / 12 questions / 10 topics) + 10
hand-authored paraphrase probes grounded in their target chunks.
Single-relevant-id weak labels; subject-scope retrieval, top_k=10.
Metrics reuse `mlrag.rag.evaluate` (no duplicated logic). No splits,
no training, no randomness.

## 11. Results (measured, `gate22_hf_retrieval_results.json`)

| Backend | R@1 | R@3 | R@5 | R@10 | MRR | Served | p50 latency |
|---|---|---|---|---|---|---|---|
| lexical-tfidf-0.1.0 | 0.750 | 0.850 | 0.975 | 1.000 | 0.831 | 40/40 | ~3 ms |
| hf-semantic (MiniLM-L6-v2) | **0.850** | **0.950** | **1.000** | **1.000** | **0.899** | 40/40 | ~120 ms (query encode ~63 ms) |

By mode (semantic vs lexical R@1): lesson-lead 0.75/0.625,
question-stem 1.0/0.833, topic-lead 1.0/1.0, paraphrase 0.6/0.5 —
semantic ≥ lexical in every mode; largest gap where wording differs
(paraphrase), as theory predicts. Scope correctness 1.0, citation 1.0,
inactive leakage 0.0, forbidden leakage 0.0. **Hybrid NOT implemented:**
semantic already leads on all metrics with R@10=1.0 both — no evidence
to justify hybrid complexity.

## 12. Performance / size

Corpus encode 74.0 s (413 chunks, CPU), index build 74.2 s total;
index 590,439 B; manifest 1,435 B; dataset 36,144 B; results 101,621 B;
model snapshot 91.6 MB; serving process working set ≈ 500 MB
(single-sample, model loaded). Rank step over scoped subset is
sub-millisecond numpy; latency is one query encode.

## 13. Reproducibility

Same corpus+model+config → identical vectors (re-run max abs diff
**0.0**, tolerance 1e-6); manifest carries corpus fingerprint
`451ddef7…`, embedding fingerprint `be77f766…`, config fingerprint
`c5b70a2c…`, chunk binding `b9354cca…`; stale/corrupt artifacts refuse
to load (tested). Deterministic retrieval asserted by repeated-run test.

## 14. Known limitations

* Weak single-target relevance: same-lesson content/summary siblings
  can outrank each other (observed once); graded relevance is future work.
* `min_score=0.20` tuned on this 40-case set; re-tune with human
  judgments before production gating.
* MiniLM 256-token truncation on very long chunks; English-centric.
* Subjects/units staleness caveat inherited from Gate 21.
* Gemini integration stops at the clean evidence-bundle interface —
  deliberate: no backend changes were required or made.

## 15. Integration / protection

* Gemini integration: contract ready (`build_evidence_bundle`,
  `build_gemini_context`), end-to-end wiring intentionally NOT done.
* Backend modified: **NO**. Database modified: **NO** (no migrations,
  no schema, SELECT-only heritage untouched). AdaptiveEngine, quiz
  scoring, auth, mastery, XP, recommendations: untouched.

## 16. Test results

* Pre-existing mlrag suite: **486 passed**, 0 failed (no regressions).
* New Gate 22 tests: **73 passed + 23 subtests**, 0 failed
  (`test_gate22_hf_config` / `test_gate22_hf_retrieval` /
  `test_gate22_hf_security_eval` + `gate22_helpers`).
* Total mlrag: **559 passed**. Backend tests not run (backend untouched).

## 17. Files created / modified

Created under `mlrag/` only: `embeddings/{__init__,model_registry,
hf_embedder,pipeline}.py`; `retrieval/{__init__,corpus_adapter,
semantic,evidence}.py`; `evaluation/{build_gate22_eval_dataset,
run_gate22_hf_eval}.py`; `evaluation/gate22_hf_eval_dataset.json`;
`artifacts/{gate22_hf_index.npz,gate22_hf_index_manifest.json,
gate22_hf_retrieval_results.json}`; `tests/{gate22_helpers,
test_gate22_hf_config,test_gate22_hf_retrieval,
test_gate22_hf_security_eval}.py`; this report. Modified:
`mlrag/requirements.txt` (GATE 22 justification + pins only).
`mlrag/rag/*`, Gate 21 code, backend, frontend, migrations: unmodified.

## 18. Final verdict

**PASS** — real pinned pretrained HF embeddings serve the Gate 21
corpus through a fingerprint-bound persistent index; scope-first
retrieval preserves provenance/citations; adversarial, leakage, and
reproducibility suites pass; semantic retrieval measurably leads the
lexical baseline (R@1 +0.10, MRR +0.068) with zero fabricated metrics
and zero application breakage.
