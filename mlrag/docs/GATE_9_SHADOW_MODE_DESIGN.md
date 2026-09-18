# GATE 9 — Safe Shadow Mode: Design + Offline Replay (DESIGN ONLY)

> Advisory predictions and retrieval may be *observed* offline; they never
> touch learner state. Engine authority absolute. No live integration,
> no endpoints, no serving, no production change.

## 1. Shadow mode definition

SHADOW PREDICTION (p/confidence/version, possibly fallback) and SHADOW
ADVISORY (bounded synthesis: PRACTICE/REVIEW/REMEDIATE/ADVANCE/FALLBACK +
reason) are computed from pre-T data and compared with outcomes. REAL
DECISION (mastery/difficulty/recommendation/XP/paths) stays exclusively
with the deterministic engine + Spring persistence. Shadow outputs change
nothing: no mastery/difficulty/recommendation/XP/path writes.

## 2. Architecture

```
Historical event (T = submitted_at)
  ↓  target-free ReplayEvent + OutcomeLedger (targets quarantined)
Point-in-time context (strict < T, same-ID ordered)
  ↓
Shadow ML (baseline predictor; ledger never passed) → ShadowMLResult
Shadow RAG (pre-T scope/query; LexicalRetriever) → ShadowRAGResult
  ↓
Shadow advisory (bounded, reasoned, fallback-aware)
  ↓            ↘ (evaluator only)
Engine path untouched     Actual outcome (grading truth)
  ↓
Comparison aggregates (no state mutation anywhere)
```

## 3–4. Point-in-time replay + event contract

`ReplayEvent{event_id, learner_key, event_time_iso=T, question_id,
topic_id, subject_id, difficulty, unit?, stem?}` — structurally incapable
of carrying targets (unknown kwargs are TypeErrors). Past = same learner,
`timestamp < T` (strict; same-quiz siblings share T and are excluded).
`OutcomeLedger{event_id → bool}` goes to the evaluator only. No PII
(surrogate keys; aggregates in output).

## 5–7. Shadow ML / RAG / advisory contracts

`ShadowMLResult{signal: MLSignal, history_tier}` — p/confidence ∈ [0,1],
versions present when served, fallback + reason otherwise; malformed →
`FALLBACK_INVALID`. `ShadowRAGResult{evidence: RAGEvidence, citations,
n_candidates}` — RAG built from pre-T scope + presented stem only (never
answer/correctness/future state); scope/active/provenance enforced, reuse
of Gate 6/7 contracts. `ShadowAdvisory{action ∈ 5 values, reason,
fallback}` — explicitly ≠ decision, never persisted.

## 8. Engine authority in replay

The engine is NOT re-invoked offline (documented limitation, not a second
algorithm): `AuthoritativeOutcome{is_correct, engine_replayed=False}`.
Comparison is advisory-vs-grading-truth (supported/misleading/fallback),
never advisory-vs-engine-decision. Disagreement is never scored as model
failure — it measures signal usefulness, fallback frequency, and data
needs.

## 9–10. Replay engine + data sources

`replay.run_replay(rows, predict, retriever, corpus, ml_mode, rag_mode)`:
deterministic sort → per-event past → validated signal → scoped
retrieval → advisory synthesis → truth retention. No database (operates
on already-available row dicts or fixtures), no credentials, no learner
DB, no writes of any kind.

## 11–12. ML evaluation + cold start

Served-row metrics (log loss/Brier/accuracy; AUC conditional via shared
helpers) + same-row baselines B/C; tiers cold/sparse/sufficient
(`MIN_HISTORY_FOR_SIGNAL=3`); cold/sparse → fallback counted, never
personalized. Small-data honesty preserved (None stays None).

## 13–14. Failure simulation

`ml_mode`: normal/unavailable/timeout/invalid/low_confidence/
version_mismatch → deterministic fallback (incl. provisional 0.5
confidence cutoff). `rag_mode`: normal/empty/unavailable/
scope_mismatch/inactive/bad_citation/grounding_failure → degraded
evidence; tampered citations fail set-membership validation; foreign
subjects fail scope validation. Failures never yield arbitrary
adaptation or ungrounded content.

## 15. Comparison categories

`ml_supported / ml_misleading / ml_fallback / rag_grounded / rag_empty /
rag_failed` — for signal usefulness and fallback-frequency analysis,
not for declaring winners.

## 16–17. Leakage audit + feedback safety

Tests prove: future exclusion, same-T determinism, target-free events,
pre-image state only, no future recommendations, sibling exclusion, no
model-output-as-feature (single-pass purity + rerun equality), ledger
never passed to predictors. Replay cannot alter history, so ground truth
is incorruptible: no self-training, predictions never re-enter inputs.

## 18. RAG-in-replay evaluation

Success/empty rates, scope violations (must be 0), grounding failures,
citation presence; Recall/Precision/MRR only where labels exist (fixture
runs: structural checks, not quality claims). No human scores invented.

## 19. Shadow record

`ShadowRecord{event, ml, rag, advisory, outcome, failure_injected}` —
in-memory/deterministic-output only; no DB tables, no migrations. Maps
to Gate 8 `ShadowRecord` (bundle + decision + outcome) for future live use.

## 20. Privacy

Surrogate keys, aggregate summaries, no PII/secrets/connection strings
in outputs. Lechecked by test (`AggregateSafetyTest`).

## 21. Live shadow design (documented, NOT built)

Spring request → authoritative flow continues untouched → async
non-blocking shadow call (sampled, timeout-bounded, circuit-broken) →
sidecar → audit/metrics store → DISCARDED for decisions. Shadow failure
never fails the learner request. Requires: correlation IDs, principal
isolation, sampling policy, latency budgets, kill switch (see §23),
observability — all future integration work, none implemented here.

## 22. Promotion criteria

OFFLINE REPLAY → LIVE SHADOW requires: replay determinism + leakage
proofs (this gate), baselines parity, fallback coverage, grounding
cleanliness, security review. LIVE SHADOW → ADVISORY PRODUCTION
additionally requires: Gate 5 provisional bars on live-scale data,
shadow-vs-outcome superiority over baselines, calibration, latency
budgets, rollback drills. Unspecified numbers remain TO BE ESTABLISHED
FROM FUTURE EVIDENCE.

## 23. Rollback

Single-flag kill switch per surface (ML, RAG, advisory) defaulting to
the deterministic engine path; login/quiz/grading/mastery/recs/
gamification never depend on sidecar availability. Fallback is always
the existing deterministic system.
