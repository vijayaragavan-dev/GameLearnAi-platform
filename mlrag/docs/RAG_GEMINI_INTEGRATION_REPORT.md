# RAG ↔ Gemini AI Tutor Integration Report (Gate 23)

> FINAL VERDICT: **PASS**. The existing Gemini AI Tutor is now a real,
> grounded, secure RAG-powered assistant over the validated Gate 22
> retrieval stack. No fake AI/RAG, no fabricated metrics, no schema or
> contract breakage, all suites green.

## 1. Objective

Connect the Gate 22 pretrained-HF retrieval system (stopping at the
evidence-bundle boundary) to the existing Gemini AI Tutor
(`POST /api/v1/ai/tutor`), end-to-end, preserving authentication,
authorization, validation, rate limiting, audit, API contract,
AdaptiveEngine, quiz scoring, database, and UX.

## 2. Preflight state

* Branch `MlRag`, log `8f440bd docs: update phase 11 project report`.
* Protected baseline preserved: 6 modified backend files + 7 untracked
  backend files + `backend/effective-pom.txt` + untracked `mlrag/`
  (identical before/after; see §24). Nested `backend/.git` working
  copy untouched (no commits, resets, or restores anywhere).
* Verified pins before work: corpus 413 chunks /
  `451ddef72317…f2b9`; model `all-MiniLM-L6-v2` @ `1110a243…4d41`,
  384d; embedding `be77f766…2c6`; index `glr-hf-index-v1`; mlrag 559/559.

## 3. Existing architecture (as found)

* `AiTutorController.ask` → `AiTutorService.ask(principal.id(), request)`:
  auth → disabled gate → server-authoritative focus resolution
  (`TutorContextBuilder`: explicit topic > subject > pointers > GENERIC,
  unknown/inactive/cross-subject refs 400) → sanitization/caps →
  deterministic policy refusal → prompt budget (12k) → rate limit
  (20/hr/user) → Gemini (1 retry, 15 s deadline) → strict JSON/schema/
  safety validation → `AiTutorResponse(answer, refused, degraded,
  context)`; counts-only `ai_interactions` audit; stateless; no
  mastery/recommendation/progression mutation.
* Versioned prompt `ai-tutor-v1.0` with `<<< >>>` untrusted blocks and
  `>+`-collapsing sanitizer; output validator rejects prompt-leak,
  secret, injection-artifact and control payloads.
* `GeminiClient` seam (Mockito-replaceable); `HttpGeminiClient`
  (RestClient + timeouts); `AiProperties` env-driven config.

## 4. Integration architecture

```
Spring Boot (auth, focus, validation, rate limit, audit)
  │  POST /retrieve {request_id, query, subject_id, topic_id?, unit_id?, top_k}
  │  Authorization: Bearer <RAG_SIDECAR_TOKEN>   (localhost only)
  ▼
Python sidecar mlrag/serving/rag_sidecar.py (stdlib http.server)
  │  Gate 22: HFEmbedder (pinned) → scope-first cosine → evidence bundle
  ▼
Spring RagGroundingService (re-validate scope/citations, render delimited block)
  │  promptText += <<<RAG_EVIDENCE ... >>>   (budget-capped, sanitized)
  ▼
Existing GeminiClient → existing TutorOutputValidator → citation allowlist gate
  ▼
Existing AiTutorResponse contract (unchanged shape)
```

* No new database, no vector DB, no queue, no Docker/K8s, no new LLM,
  no new embedding model. One new blocking localhost call with
  1 s connect / 5 s read timeouts, single attempt (no retry storms).
* RAG flag `gamelearn.ai.rag.enabled` defaults **false**: disabled path
  is byte-identical legacy behavior (proven by the untouched legacy
  test expectations still passing).

## 5. Files modified

Backend (additive only):
* `config/AiProperties.java` — new nested `Rag` props (enabled,
  baseUrl, serviceToken, timeouts, topK, evidenceBudgetChars).
* `service/AiTutorService.java` — constructor + `RagGroundingService`;
  grounding phase after rate limit; `promptVersion` threading;
  `TUTOR_RAG_*` / `TUTOR_CITATION_UNGROUNDED` categories; citation
  gate; counts-only RAG audit keys. No ordering, validation, retry,
  refusal, or response-shape change.
* `ai/rag/{RagException,RagEvidence,RagEvidenceClient,
  RagGroundingService}.java` — new.
* `resources/application.yml` — `gamelearn.ai.rag` defaults
  (enabled:false). `backend/.env.example` — `RAG_SIDECAR_*`
  placeholders (no values).
* Tests: `ai/rag/{RagEvidenceClientTest,RagGroundingServiceTest}.java`,
  `controller/{AiTutorRagFlowTest,AiTutorRagDownTest}.java` — new.

Python (new, stdlib-only): `mlrag/serving/{__init__,rag_sidecar}.py`,
`mlrag/tests/test_gate23_sidecar.py`.

Untouched: AdaptiveEngine, quiz scoring, auth, `TutorContextBuilder`,
`TutorPromptBuilder`, versioned prompt templates, response DTOs,
migrations (V1–V28), Flutter.

## 6. RAG flow

Authenticated ask → focus → sanitize → refusal → budget → rate limit →
`ground()`: sidecar retrieve with **server-derived** subject/topic/unit
IDs → bundle re-validation → delimited budget-capped block appended →
prompt re-budgeted → Gemini → output validation → citation allowlist →
respond. GENERIC focus (no subject) cannot scope → explicit
insufficient-evidence degraded answer, no RAG call, no Gemini call.

## 7. HF model details

Unchanged from Gate 22: `sentence-transformers/all-MiniLM-L6-v2` @
`1110a243fdf4706b3f48f1d95db1a4f5529b4d41`, 384d L2-normalized, local
CPU. Sidecar verifies model load + inference (warmup embed) and index
binding at startup; failure exits non-zero. No retraining, no second
model, no downloads beyond the pinned snapshot.

## 8. Evidence-bundle flow

Sidecar returns scoped chunks (id, citation, provenance, score, text)
or explicit `served:false + empty_reason` over HTTP 200. Spring
re-validates (subject/topic match, citation allowlist shape, non-empty
text) and renders `<<<RAG_EVIDENCE … >>>` with per-chunk
`[citation | score]` lines plus grounding rules, all via
`sanitizeUntrusted` (forged `>>>` destroyed), highest-score-first
within `evidenceBudgetChars` (default 4000).

## 9. Gemini grounding strategy

Evidence is framed as DATA in the existing `<<< >>>` untrusted-block
convention the system prompt already commands the model never to obey;
rules require answering ONLY from evidence, exact-citation citation,
and explicit "I don't know" on gaps. Prompt version recorded as
`ai-tutor-v1.0+rag-v1` when grounded (base version otherwise).
Gemini keeps zero authority over mastery/difficulty/progression/
recommendations/XP/scoring/authorization (no such inputs or outputs
exist in the flow).

## 10. Citation strategy

Citations originate only from Gate 21 lineage (`table:id#cN`),
allowlisted in `RagGroundingService`. Post-validation
`verifyCitations` rejects any answer token shaped like a citation that
was not supplied → deterministic degraded template + `REJECTED` audit
(`TUTOR_CITATION_UNGROUNDED`). No response-DTO change: validated
citations travel inline in `answer`.

## 11. Scope enforcement

Order preserved end-to-end: sidecar scope-filter → semantic rank →
top-K (Gate 22, untouched) → Spring re-validation (whole bundle fails
on one out-of-scope chunk). Scope IDs come from `TutorContext`
(DB-validated UUIDs); query text is never parsed for IDs. Malicious
"search all subjects / topic 999999" inputs cannot widen scope
(tested at unit + HTTP levels).

## 12. Prompt-injection defense

12-query battery at the sidecar (override, impersonation, scope-bypass,
secret/SQL/XSS, repetition, Unicode) stays scoped or degrades;
poisoned chunk served as flagged delimited DATA; model echoing poison
is rejected by the existing injection-artifact validator → degraded
(RAG-06 proves this end-to-end). Retrieved text can neither alter
system instructions nor escape `<<<RAG_EVIDENCE >>>`.

## 13. Learner-data isolation

Corpus remains educational-only (no rebuild, no write endpoints,
runtime read-only). Learner context (mastery etc.) stays in the
existing `LEARNER_CONTEXT` block, separate from evidence. Sidecar
request logs: ids/counts/latency only — never query/evidence text
(asserted by test). Audit rows gain only `grounded`, `ragChunks`,
`ragLatencyMs`.

## 14. Failure handling

| Condition | Behavior |
|---|---|
| RAG down / timeout / corrupt bundle / invalid evidence | 503 `AI_SERVICE_UNAVAILABLE` + FAILED audit; Gemini never called |
| No evidence / GENERIC / over-budget | 200 `degraded:true` template + REJECTED audit; Gemini never called |
| Gemini failure | existing 503 path, unchanged |
| Fabricated citation / unsafe output | 200 `degraded:true` template + REJECTED audit |

No ungrounded silent fallback exists on the RAG-enabled path.

## 15. Timeout behavior

RAG: 1 s connect / 5 s read (configurable), single attempt, inside the
existing 15 s tutor deadline and after quota admission — no thread
exhaustion (same blocking-call pattern as Gemini), no retries, no
cascades. Verified: closed-port call fails fast to 503 (RAG-08);
slow-stub trips the read timeout (unit).

## 16. API compatibility

`AiTutorResponse` shape unchanged (4 keys asserted in RAG-01);
existing envelopes/error codes reused (`VALIDATION_FAILED`,
`AI_RATE_LIMITED`, `AI_SERVICE_UNAVAILABLE`); refusal/degraded
templates reused. Flutter untouched.

## 17. Audit/logging behavior

Counts-only design preserved; RAG adds `grounded/ragChunks/
ragLatencyMs` to `request_context_json` (additive keys; legacy rows
byte-identical). Full prompts/answers/questions/evidence/tokens never
logged or persisted. Sidecar stdout: JSON request lines without content.

## 18. Test strategy

UNIT: client mapping/parsing, grounding validation/rendering/citation
gate (Mockito + JDK stubs, no Spring). INTEGRATION: MockMvc full stack
with stub RAG sidecar + mocked Gemini (scope forwarding, evidence
attachment, injection, insufficient, hostile, poison, no-mutation).
E2E REAL retrieval: Python sidecar tests over the pinned model +
committed index (rank-1 known case, auth, validation, scope,
log-hygiene). No live Gemini quota consumed anywhere.

## 19. Test results

* Backend full suite: **579 run, 0 failures, 0 errors, 8 skipped**
  (pre-existing Docker-dependent skips) — includes 21 new RAG unit +
  8 new flow/down tests; all pre-existing AI Tutor tests pass.
* mlrag full suite: **570 passed, 0 failed** (559 Gate 22 + 11 new
  sidecar tests) — RAG regression PASS.
* Coverage of mandatory A–X: A✓ B✓ C✓(stub boundary + real-model
  sidecar tests) D✓ E✓ F✓ G✓ H✓ I✓ J✓ K✓ L✓ M✓ N✓ O✓(Gate 22 suite)
  P✓(Gate 22 suite) Q✓ R✓ S✓(usage asserted; existing limiter suite
  green) T✓ U✓ V✓ W✓ X✓.

## 20. Security results

Secret scan (precise email/JWT/secret-assign/bearer/private-key/sk/
Google-key patterns) over all 16 new/modified files: **0 hits**
(test tokens are `test-*` dummies; `.env.example` gains placeholders
only). Note: one password-shaped line in `backend/.env.example` predates
this task (visible in the preflight baseline diff), was not touched, and
is not propagated anywhere — flagged for owner rotation out-of-band.

## 21. Performance results

Warm sidecar `/retrieve` (6 samples, top_k=5): **51–109 ms**
(encode-dominated); localhost HTTP overhead **~7–9 ms** (one 136 ms
scheduling outlier observed); Java evidence render client-side is
sub-millisecond string work. External Gemini latency excluded
(quota-sensitive, labeled). No optimization performed; budgets fit
inside the 15 s tutor deadline with headroom.

## 22. RAG regression results

PASS: corpus fingerprint `451ddef7…` unchanged, embedding fingerprint
`be77f766…` unchanged, model revision unchanged, Gate 22 evaluation
artifacts untouched, full 570-test mlrag suite green, no retrieval
code modified (only a new serving wrapper reusing it).

## 23. Database protection

No schema change, no migration (V1–V28 intact, migration dir clean),
no new tables, zero RAG writes. `topic_mastery` and `recommendations`
row counts asserted unchanged across grounded asks; only standard
`ai_interactions` TUTOR rows (+1 per ask).

## 24. Backend protection

Diff review: only additive RAG files + `AiProperties`/`AiTutorService`
hooks + `application.yml`/`env.example` placeholders. Pre-existing
user modifications (QuizController, DTOs, `.env.example` values,
effective-pom, untracked services/tests) untouched; nested
`backend/.git` uncommitted and unaltered by this task. No commit/push.

## 25. Flutter protection

Untouched (`git status -- frontend` empty); response contract
unchanged so no client update required.

## 26. Known limitations

* RAG-enabled GENERIC (subject-less) asks degrade rather than answer
  from general knowledge — conservative by design; revisit with a
  cross-subject policy if product requires.
* `min_score=0.20` and `evidenceBudgetChars=4000` carry Gate 22 tuning;
  re-tune with human judgments before production gating.
* Single sidecar instance, no caching: fine for hackathon scale;
  horizontal/server redundancy is future work, not added complexity now.
* Real end-to-end Gemini grounding quality still needs quota-backed
  manual review; automated tests prove the plumbing and the guards.

## 27. Final verdict

**PASS** — real Gate 22 HF retrieval is integrated; the existing tutor
receives authoritative delimited evidence; injection is contained;
citations are allowlisted; scope filtering holds on both sides of the
boundary; inactive content cannot leak (active-only corpus +
re-validation); PII/secrets stay out; timeouts/failures are safe with
no silent ungrounded fallback; tutor security, API compatibility,
database, AdaptiveEngine, quiz logic, and Git state are preserved;
579 backend + 570 mlrag tests green with zero fabricated metrics.
