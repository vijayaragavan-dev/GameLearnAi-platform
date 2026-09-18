# GATE 10 — Controlled Shadow Integration (boundary proven, nothing wired)

> Shadow mechanics are implemented and tested in `mlrag/shadow/live.py`
> against a simulated authoritative flow. NO backend file changed, NO
> hook wired (wiring without a serving backend would be dead production
> code), NO HTTP service, NO learner impact possible.

## 1–3. Architecture, boundary, why safe

Inspected: `mlrag/{contracts,experiment,rag,shadow}`, backend
`QuizSubmissionService.submit()` (`@Transactional`, lines 83–174: saves
attempts → `processSubmission` → gamification → response). Chosen hook
(documented, not wired): **after `submit()` returns (post-commit)**,
observing server-derived context. Safe because: (a) nothing in the
transaction changes — no new repository call inside it; (b) shadow runs
in an isolated bounded pool, never on the request path; (c) all shadow
failures map to statuses, never exceptions; (d) kill switch defaults
OFF; (e) no HTTP boundary exists to secure/operate. Alternative (real
HTTP server) rejected per gate rules: unjustified infrastructure with no
serving model behind it.

## 4–6. Request, principal isolation, point-in-time

Shadow request = `ReplayEvent` (IDs + difficulties + presented stem;
structurally target-free) + past rows. Identity: `derive_learner_key()`
SHA-256 surrogate from the server principal; client IDs never accepted
(tested). Features obey strict `< T` via the Gate 9 replay path;
correctness travels only in the offline ledger, never live.

## 7–10. Execution, timeout, failure, transaction isolation

Post-commit async observation (simulated: ledger commit → `observe()`).
Provisional 800ms timeout (`future.result`), pool of 2, sampling gate;
timeout → `timeout` status, learner response already committed and
returned conceptually. Failure map: 6 ML modes + 6 RAG modes + executor
faults → fallback/degraded statuses. No shared transaction (shadow holds
no repository, no connection); no distributed transaction; shadow
persistence does not exist.

## 11–13. ML/RAG/advisory integration + engine authority

ML: baseline predictor behind `PredictFn`, version-checked (`-shadow-`
marker, provisional), confidence-gated. RAG: lexical TF-IDF, scope/
active/provenance enforced, citations validated by set membership.
Advisory synthesized but never forwarded to any engine. Authority proof:
`resolve_conflict` keeps engine fields byte-identical (tested); the
simulated flow derives learner responses solely from the committed
ledger under every failure/disagreement/attack scenario (15 safety
tests).

## 14–17. Leakage, versions, kill switch, sampling

Target/future exclusion structural (tests 11–12); versions mandatory,
mismatches rejected (tests 13–14); `ShadowConfig{enabled=false default,
sample_pct 0..100, timeout, workers}` + env loader; deterministic
hash sampling with forced 0/100 in tests.

## 18–19. Observability, latency

`ShadowObservation{correlation_id, status, versions, grounding,
confidence bucket, fallback/failure, latency_ms}` — codes only, no PII
(tested), no secrets. Latency measured per observation; no SLA claimed.

## 20. Test strategy → 16 live tests

All 15 required scenarios pass (disabled/success/ML-fail/RAG-fail/
timeout/invalid/exception/disagreement/identity/target/future/versions/
kill-switch) plus config/sampling/correlation/observability tests.

## 21–23. Limitations, no promotion, regression

Limits: simulated (not Spring) flow; provisional constants unvalidated
at scale; pool clogging under persistent slowness relies on operator
kill switch; no shadow persistence (future Gate 11+ decision, migration
required — STOP then). Backend suite re-run below; `deployment_ready`
false; promotion: NO.
