# GATE 8 — Adaptive Intelligence Architecture (DESIGN ONLY)

> No integration, no endpoints, no model serving, no RAG wiring, no
> production change. Contracts in `mlrag/contracts/adaptive.py`; tests in
> `mlrag/tests/test_adaptive_design.py`. A future engineer implements
> Gates 9+ against this document without new architectural assumptions.

## 1. System responsibilities

| Component | Owns | MUST NEVER |
|---|---|---|
| Spring Boot | auth/JWT, identity, quiz grading, orchestration, persistence, transactions, Gemini calls, audit | expose learner state to clients; trust client-supplied mastery/predictions |
| ML Predictor | P(correct), confidence, sufficiency/version metadata | write mastery/difficulty/XP/recommendations/paths/scores; bypass rules |
| RAG Retriever | scoped educational chunks + citations + relevance | decide progression/mastery/difficulty; mutate state |
| Adaptive Decision Layer (new, future) | translate signals into bounded advisories | decide, persist, or override anything |
| Existing AdaptiveEngine | mastery/trend/difficulty/next-action/recommendation rules, cold start, bounds, reason codes | consume unvalidated signals |
| Gemini/LLM | tutor/path natural-language generation from validated context | determine/persist mastery, difficulty, XP, progression, recommendations |
| MySQL | sole learner-state + content source of truth | — (no second store, no duplicated tables) |

## 2. End-to-end data flow

1. **Learner action** (quiz submit) → Spring Boot. Owner: Spring.
   Validation: JWT + ownership. Failure: 401/403, no state change.
2. **Authoritative context**: Spring loads user, quiz, prior mastery
   (all server-side). Failure: safe error, no partial writes.
3. **ML feature/prediction request**: Spring builds `PreAttemptFeatures`
   (strict `< T`) → `PredictionRequest`. Validation: contract bounds.
   Failure/timeout → `FALLBACK_*` signal, deterministic path continues.
4. **ML prediction** → `MLSignal` (p, confidence, versions, status).
   Invalid (NaN/out-of-range/version mismatch) → rejected → fallback.
5. **RAG query construction**: Spring derives (subject/topic/unit,
   query) from the authoritative focus. Failure → `FALLBACK_UNAVAILABLE`.
6. **Scoped retrieval** → `RAGEvidence` (chunks + citations + grounding
   flag). Scope enforced in code; cross-scope/empty → degraded.
7. **Grounding validation** (`validate_grounded`): provenance + active +
   scope per chunk; failure → degraded, never ungrounded claims.
8. **Adaptive Decision Layer**: bundles `AdvisoryBundle` (signals +
   read-only engine snapshot) → bounded advisory (e.g. "reinforcement
   candidate", difficulty hint with basis). No persistence.
9. **Existing AdaptiveEngine** applies mastery/trend/ladder/threshold
   rules → `EngineDecision` (reason code + consumed/ignored ledger).
   **Conflict rule: engine wins; disagreement recorded as ignored.**
10. **Spring persistence** (same transaction discipline as today) →
    next interaction → authoritative outcome (`is_correct`) feeds future
    features (feedback, §12).

## 3. ML signals

`MLSignal{status, p_correct∈[0,1], confidence∈[0,1], model_version≠∅,
feature_schema_version≠∅ | fallback_reason≠∅}`. Served requires all
present and finite; fallback carries no prediction. Optional
`DifficultySignal{suggested∈{EASY,MEDIUM,HARD}, basis≠∅}` (advisory
spelling only) and ranking scores (see §9). No production thresholds are
invented: serving gates (`MIN_HISTORY_FOR_SIGNAL=3`) are configurable
and provisional pending Gate 9+ evaluation. **Prediction ≠ decision.**

## 4. RAG signals

`RAGEvidence{status, citations≠∅, subject_id≠∅, topic/unit?, 
retriever_version≠∅, grounding_valid=true | fallback_reason}`. Answers
"what educational information is relevant?" — never "what should mastery
be?". Mandatory subject scope; optional topic/unit/lesson narrowing;
inactive rejected; unapproved sources rejected; no-match/unavailable →
degraded. TF-IDF remains the retriever (Gate 7); no embedding migration
designed here.

## 5. Adaptive Decision Layer (future, bounded translator)

```
MLSignal (p=0.82) + RAGEvidence (remediation chunk, cited)
        ↓ bounded transformation (no state access)
Advisory: "reinforcement candidate C (eligible, basis recorded)"
        ↓
AdaptiveEngine rules (mastery/trend/ladder/thresholds)
        ↓
Authoritative decision + reason code (persisted by Spring)
```

Forbidden paths: ML→DB write, RAG→progression decision, any bypass of
§6. The layer is stateless and prompt-free.

## 6. AdaptiveEngine authority (existing rules, architectural level)

Verified in `backend/.../adaptive/AdaptiveEngine.java`: pure
`decide(PreviousState, accuracy, attemptCount, quizDifficulty)` →
`Decision(previous, mastery, level, trend, nextDifficulty, activity,
priority, reasonCode)`; BigDecimal scale-2 HALF_UP; 7 reason codes;
mastery/trend/difficulty/next-action/recommendation/cold-start/bounds/
persistence all owned by engine + services. ML/RAG influence arrives ONLY
as consumed advisory inputs (e.g. a validated hint the ladder clamps, a
cited chunk attached to a remediation action) — recorded in
`signals_consumed`, disagreements in `signals_ignored`. Engine wins,
always, by construction (`resolve_conflict`).

## 7. Cold start

`classify_history(n)`: 0 → COLD_START, <3 → SPARSE, else SUFFICIENT.
Cold/sparse/unavailable/low-confidence → `FALLBACK_*` → deterministic
engine path (FIRST_ATTEMPT_BASELINE_SET etc.). A low-confidence model
can never become authoritative: unserved signals carry no values to
misuse. No ML validity claimed for cold users.

## 8. Declining learner / remediation

Engine trend DECLINING → authoritative remediation action
(RECENT_DECLINE_REMEDIATION) → RAG retrieves grounded same-topic
explanations/practice (cited) → ML optionally scores candidate content
(sufficient history only) → decision layer ranks advisory candidates →
engine/business rules pick the final action. RAG = content support, ML =
ranking support, engine = decision. Worked shape is encoded in
`AdvisoryBundle` + `RankedCandidate` + `resolve_conflict`.

## 9. Content ranking (bounded interface)

`candidate → eligibility filter (active, scope, difficulty-band,
prerequisites) → RAG relevance → ML signal → deterministic constraints →
rank_candidates() → engine decision → persistence`. `rank_candidates`
orders eligible-first, score-desc, ID tie-break; rank ≠ decision ≠
persistence (separate steps, separate owners). No unjustified scoring
formula: score composition is a Gate 9+ evaluation item; the interface
only fixes ordering semantics and eligibility-first invariants.

## 10. Difficulty adaptation

ML emits `DifficultySignal` (suggestion + basis). Spring/engine validate
against current difficulty, mastery, trend, accuracy, cold-start rules,
min/max bounds, ladder policy; the final EASY/MEDIUM/HARD comes from the
deterministic layer only. ML can never set difficulty, skip ladder
steps, or override bounds.

## 11. RAG + learning path

Per candidate node/topic: retrieve scoped active content + citations →
attach ML prediction if history suffices → apply eligibility rules →
rank → engine decides. RAG/ML never mutate `learning_paths(_nodes)`;
path persistence stays in `LearningPathPersistenceService` semantics.

## 12. Feedback loop

prediction → attempt → authoritative server grading → `is_correct`
ground truth → state update → future pre-attempt features. Ground truth
is ALWAYS the server-computed outcome, never a model output — otherwise
predictions would train on themselves (feedback contamination). Shadow
records (`ShadowRecord`) hold advisory + decision + later outcome
separately until grading fills the truth.

## 13. Leakage / feedback prevention

Allowed pre-submit: prior snapshots, history aggregates (`< T`),
catalogue difficulties/IDs, prior ACTIVE recommendation, validated
advisory signals about the past. Forbidden: target outcome, same-quiz
siblings, post-image mastery/recommendations/scores, future rows,
model-generated signals fed back as features, RAG content as labels,
repeated-prediction echo. Enforced by `leakage.py` validators,
feature-builder `< T` discipline, and contract tests.

## 14. Failure modes

ML down/timeout/invalid/low-confidence, RAG down/timeout/empty/
grounding-failure/bad-citation/inactive/scope-mismatch, or both down →
`FALLBACK_*` + reason → deterministic engine experience. Never:
failure → ungrounded AI text → arbitrary adaptation. Every failure is
typed (`errors.py`, `SignalStatus`) and auditable.

## 15. Security

Principal + identity stay in Spring Boot (JWT, server-derived IDs);
sidecar receives minimum necessary fields (surrogate keys, counts —
never passwords, JWTs, PII); no direct client→ML/RAG path; no
client-supplied mastery/predictions trusted; RAG quarantine
(`safety.py`); provenance + scope enforcement; bounded payloads,
timeouts, rate limits (future integration); audit rows (versions,
status, grounding, outcome, fallback reason, latency, failure class).

## 16. API boundary (concepts, not endpoints)

ML request `{learner_key, topic/question context, feature_schema_version,
point-in-time ts, features}` → response `{p, confidence, model_version,
schema_version, status}`. RAG request `{subject, topic?, unit?, lesson?,
query, top_k}` → response `{chunks, citations, relevance, version,
grounding status}`. Advisory `{ml, rag evidence, bounded suggestion,
reason, confidence}`. No HTTP clients/servers implemented here.

## 17. Versioning

`feature_schema_version` (f1…), `model_version` (+ `model_id`,
data-snapshot, code version), `retriever_version` (+ corpus snapshot),
adaptive decision contract version. Compatibility rule: serving rejects
unknown/stale versions and schema mismatches (fail closed to fallback).

## 18. Observability / audit (conceptual, no new tables)

Log per decision: model/retriever versions, signal status, confidence
bucket, grounding status, engine reason code + outcome, fallback reason,
latency, failure class — counts and codes only, no PII, no prompts.

## 19. Test strategy (pre-integration requirements)

Unit: bounds, versions, cold tiers, fallbacks, invalid ML/RAG payloads,
ranking separation, frozen contracts. Integration (future): Spring→ML,
Spring→RAG, layer→engine, conflict-wins. Security: principal isolation,
scope mismatch, injection quarantine, client manipulation. ML: temporal
leakage, learner splits, calibration, baselines. RAG: Recall/Precision/
MRR, scope violations, inactive docs, grounding failures. Regression:
full backend + frontend suites; deterministic behavior identical with
ML/RAG unavailable.

## 20. Production-readiness gates (all DESIGNED, none passed)

Data sufficiency, model quality, baseline superiority, calibration,
cold-start safety, RAG relevance, grounding, security, latency, fallback,
contract compatibility, engine regression, observability, rollback,
shadow-mode validation. Statuses: DESIGNED (this doc) — IMPLEMENTED /
EVALUATED / PRODUCTION READY all pending future gates.

## 21. Shadow mode (preferred first integration)

ML predicts + RAG retrieves on live traffic; engine keeps deciding;
nothing affects learner state; predictions vs `is_correct` outcomes are
compared; quality, calibration, fallback, and audit paths measured.
Promotion requires shadow evidence, never offline metrics alone.

## 22. Architecture diagram

```
Learner
  ↓ quiz attempt
Spring Boot (auth/JWT, grading, orchestration, persistence, audit)
  ├── authoritative learner context (server-side only)
  ├── ML Predictor ──→ MLSignal (bounded, versioned, fallback-safe)
  ├── RAG Retriever ─→ RAGEvidence (scoped, cited, grounded)
  └── Adaptive Decision Layer ──→ bounded advisory bundle
          ↓ (advisory only, consumed/ignored ledger)
Existing AdaptiveEngine (mastery/trend/difficulty/action/recs/rules)
          ↓ authoritative EngineDecision + reason code
MySQL persistence (sole source of truth)
          ↓ learner experience
future feedback (is_correct → features; never model outputs)
Gemini/LLM (side path): tutor/path TEXT generation from validated
context only — NO line to mastery/difficulty/XP/progression/recs.
```

## 23. Decision record

- Option A sidecar retained; MySQL source of truth; AdaptiveEngine
  authoritative; ML advisory; RAG grounded retrieval; TF-IDF current
  retriever; embeddings/vector DB deferred; no RL; no duplicate learner
  state; no production integration at Gate 8; shadow mode preferred;
  current data limitations (n=56/5 learners, timing NULL, HARD absent,
  rec outcomes absent) remain production blockers.
