# GameLearnAI ML/RAG Sidecar — Architecture (GATE 1: contracts only)

> Status: **specification, not implementation**. No model, no embeddings, no
> vector store, no training, no inference server, no Spring/Flutter
> integration, no migration exists here. Anything that claims otherwise is
> out of scope for this gate.

## 1. Rule

**Spring Boot owns the truth. ML advises. Gemini generates. RAG grounds.**

Spring Boot stays authoritative for: auth/JWT, learner identity, quiz
evaluation and scoring, mastery persistence, the deterministic
`AdaptiveEngine`, recommendation persistence, XP/gamification, progression,
learning-path rules, Gemini Tutor/Path integration, security, transactions,
final decisions. The sidecar must never write learner state.

## 2. Layout (standard library only — see `requirements.txt`)

```
mlrag/
  README.md               this specification
  requirements.txt        intentionally dependency-free (comments only)
  config.py               SidecarConfig: env-driven, disabled by default
  contracts/
    common.py             Difficulty, PredictionTarget, ModelVersion,
                          TraceContext, ContractViolation
    predictor.py          PreAttemptFeatures / PredictionRequest /
                          PredictionResponse / PredictorPort
    retriever.py          ScopeFilter / RetrievalRequest / RetrievedChunk /
                          RetrievalResponse / RetrieverPort
    leakage.py            pre-attempt allowlist, post-attempt blocklist,
                          validators (GATE 0.5 provenance rules as code)
    evaluation.py         DatasetUnit, LabelDefinition, SplitPolicy,
                          BaselineRequirement, EvalSpec, metric placeholders
  tests/
    test_contracts.py     unittest suite (no external services)
```

Run: `python -m unittest discover -s mlrag/tests -v` from the repo root.

## 3. Predictor boundary

Future input is **pre-attempt only**: identity/context keys (`user_key`,
`subject/topic/question/quiz_id`, optional `unit_id`), catalogue
difficulties, and the **prior** learner snapshot (`prior_attempt_count`,
`prev_mastery_score/level`, `prev_recent_accuracy`, `prev_trend`,
`prev_difficulty`, prior recommendation, history counts, `predicted_at_iso`).
Cold-start learners omit history (nulls, count 0) — never fabricated.

Future output: `p_correct` in 0..1, optional `confidence` and
`difficulty_suitability`, mandatory `ModelVersion`, and an explicit
`served_by_model` flag. `served_by_model=False` **must** carry a
`fallback_reason` and **must not** carry a prediction — the contract
rejects fabricated signals. `PredictorPort.supports()` is the
minimum-history gate; below it the backend uses deterministic rules.

## 4. Retriever boundary

Requests carry a mandatory `ScopeFilter` (`subject_id` required,
`active_only` locked True) plus `query`, `top_k` (1..50), and an allowlist
of source tables (`subjects/units/topics/lessons/questions`). Responses
carry `RetrievedChunk`s with `source_table/source_id`, subject/topic/unit,
`content_version`, `is_active=True`, `text`, `score`, and a non-empty
`citation`. `validate_against(scope)` enforces post-retrieval
no-cross-subject/topic checks. Unserved responses require `empty_reason`
(degraded mode, never silent claims). No backend is selected here.

## 5. Data flow (future, not wired)

```
Flutter -> Spring Boot (/api/v1, JWT) -> quiz/adaptive/Gemini (unchanged)
   Spring Boot --PredictionRequest--> PredictorPort (signal back, advisory)
   Spring Boot --RetrievalRequest---> RetrieverPort (chunks back, grounding)
   Spring Boot decides, persists, audits (authority unchanged)
```

Future wire concerns (conceptual only): server-derived identity, minimal
context, timeouts (`predict_timeout_ms`/`retrieve_timeout_ms`), model and
retriever versions, `request_id` tracing, failure handling. No endpoint,
no FastAPI, no contract change to `/api/v1` in this gate.

## 6. Leakage rules (enforced by `leakage.py`, tested)

| Safe pre-attempt feature | Blocked post-attempt/untrusted field |
|---|---|
| prior mastery/attempts/recent/trend/difficulty | post-image `topic_mastery.*`, current recommendation row |
| prior ACTIVE recommendation | current `score`/`correct_count`, `is_correct`, `selected_answer` |
| question/quiz difficulty, IDs, history counts | `response_time_seconds` (NULL), `duration_seconds` (degenerate) |
| timestamps, order, time gaps | `game_results.*` skill fields, any `future_*` |

Dataset unit: `question_attempt` primary (`is_correct` label),
`quiz_attempt` secondary (`score` label). Splits must be
`user_aware_time_aware` with ordered periods and user isolation — random
row splits are rejected by the contract. Every experiment needs baselines
(`majority_class`, `recent_accuracy`, `deterministic_adaptive`), named
metrics (accuracy/precision/recall/F1/ROC-AUC/PR-AUC/log-loss/calibration/
Brier; P@K/R@K/NDCG/MRR; MAE/RMSE), seed, code version, data snapshot, and
a cold-start policy. Model families are **not** selected here.

## 7. Adaptive Engine boundary

ML signals (`p_correct`, `confidence`, ranking/difficulty hints) enter as
advisory inputs, clamped to the deterministic ladder and gated by
cold-start rules. ML must never: change/persist mastery, XP, achievements,
correctness, scores, recommendations; bypass difficulty bounds, thresholds,
cold-start or progression rules; override identity/authorization; alter
transaction ordering. `ML = SIGNAL PROVIDER; AdaptiveEngine = AUTHORITY.`

## 8. RAG boundary and security

Corpus (future): active, versioned rows of subjects/units/topics/lessons/
questions(+explanations) — no invented content. Retrieval: pre-filter by
scope metadata, post-validate scope match, cite every span, degrade (not
hallucinate) on empty/failed retrieval. Retrieved content is DATA, never
instructions: treat corpus like untrusted input (caps, delimiters, refusal
checks, mirroring the existing Tutor validators); inactive/deprecated rows
are never served; per-learner isolation is enforced server-side.

## 9. Restrictions honored in this gate

No response-time feature pipeline and no V29 timing migration (timing data
is NULL/deenerate); non-quiz `game_results` stay engagement-only, never
skill labels; no second learner/mastery/progress/recommendation store;
MySQL remains the source of truth; no Flyway migration of any kind.

## 10. Failure mode

Sidecar/model/RAG unavailable, empty/invalid/timeout/malformed responses
→ deterministic backend behavior applies (existing quiz evaluation,
AdaptiveEngine, fallback paths, Tutor 503/degraded semantics). ML/RAG
failure must never break core evaluation or persistence.

## 11. Future phases (not started)

GATE 2 data readiness → GATE 3 ML foundation (features/jobs/harness) →
GATE 4–6 signals → GATE 7–8 retrieval → GATE 9 grounded Tutor →
GATE 10 orchestration → GATE 11+ APIs/frontend/eval/security/regression.
Each phase needs its own evaluation justification before adding a
dependency or a backend.
