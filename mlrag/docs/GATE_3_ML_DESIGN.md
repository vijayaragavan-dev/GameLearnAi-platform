# GATE 3 — First ML Capability Design: P(correct) Baseline Experiment

> Status: **DESIGN ONLY**. No model trained, no dataset extracted, no MySQL
> connection, no inference, no integration, no migration, no dependency.
> Existing `mlrag/` contracts are reused unchanged; this document is the only
> new artifact. Deterministic `AdaptiveEngine` remains authoritative.

## 1. Purpose

Design a small, interpretable, leakage-safe baseline experiment for one
capability: **predict the probability that a learner answers the next
question correctly**, given only information available before the attempt.
The output is strictly advisory to Spring Boot's deterministic
`AdaptiveEngine`. Nothing here authorizes mastery, difficulty,
recommendation, XP, scoring, progression, or correctness decisions.

## 2. Current data evidence (measured, read-only)

- Learners: 40 total; **5** with quiz attempts; 35 with zero attempts.
- Attempts: 14 quiz attempts → **56 question attempts** (39 correct, 17
  incorrect; 69.64% overall — a dataset observation, never a baked constant).
- Catalog: 234 questions / 73 question-backed topics / 11 subjects.
- Outcomes by question difficulty: EASY 52, MEDIUM 4, **HARD 0**.
- Span: 2026-08-26 → 2026-09-04, **5 active days**.
- Timing: `response_time_seconds` 56/56 NULL (unusable); `duration_seconds`
  degenerate (excluded).
- Learner depth (question attempts): 35×0, 2×{2–5}, 1×{6–10}, 1×{11–20},
  1×{21–50}.
- Learner-topic pairs: 9 total; 9 with ≥2 obs, 9 with ≥3 obs, **1 with ≥5**.
- Recommendations: 14 rows (5 learners, 5 topics; 9 active, 5 consumed) —
  rec-ranking ML **not** data-ready (no outcome join volume).
- Consequence: HARD-difficulty modeling, response-time modeling,
  recommendation ranking, deep learning / RL / complex knowledge tracing
  are **not justified**. This gate designs a feasibility/baseline
  evaluation, not a production model evaluation.

## 3. Prediction unit

One row = **one learner-question opportunity immediately BEFORE the
learner submits the answer**.

- **Entity/key:** `(learner_id, question_id, quiz_attempt_id)` — one row
  per `question_attempts` row; learner identity derived exclusively via
  `question_attempts.quiz_attempt_id → quiz_attempts.id →
  quiz_attempts.user_id` (`question_attempts` has no `user_id`).
- **Prediction timestamp T:** the target quiz attempt's `submitted_at`.
  (Closest recorded pre-submit instant; server-written, monotonic per quiz
  flow.) Features may use only records with timestamp **strictly < T**.
- **Learner context cutoff:** all learner history with event time < T;
  sibling questions in the same quiz share `submitted_at` and are
  **excluded** (same-T exclusion, §7).
- **Question context:** `questions{id, topic_id, difficulty}`,
  `topics{subject_id}`, `quizzes{id, difficulty}` via valid FKs only.
- **Target label:** `question_attempts.is_correct` (boolean, server-computed).

## 4. Label

`is_correct` — set server-side by exact-match evaluation
(`QuizSubmissionService`; null/unanswered counts as incorrect). Unambiguous,
binary, present on all 56 rows. `quiz_attempts.score` is a secondary
attempt-level label only (contains the target question's outcome; never a
feature for that question).

## 5. Feature specification table

All features are aggregates over history with event time **strictly < T**.
Transforms are deterministic; missing history → NULL (cold-start path, §13),
never imputed with future data, never zero-filled as "observed".

| # | Feature | Source | Availability (point-in-time) | Transform | Leakage risk | Cold-start |
|---|---|---|---|---|---|---|
| F1 | `hist_q_attempts` | `question_attempts ⨝ quiz_attempts` (prior quizzes only) | count of rows with quiz `submitted_at < T` | count | None if T-exclusive | NULL → cold |
| F2 | `hist_correct` | same | count where `is_correct = true`, time < T | count | None if T-exclusive | NULL → cold |
| F3 | `hist_accuracy` | F2/F1 | rate; NULL when F1 = 0/NULL | rate | None (prior only) | NULL → cold |
| F4 | `hist_quiz_attempts` | `quiz_attempts` | count with `submitted_at < T` | count | None | NULL → cold |
| F5 | `recent_accuracy_k5` | same as F1, last ≤5 by time | rate over trailing window | rate | None; window ends < T | NULL if <1 prior |
| F6 | `recent_n` | same | window size actually used (0–5) | count | None | 0 → cold |
| F7 | `is_cold_start` | derived | 1 iff F1 IS NULL/0 | flag | None | definitional |
| F8 | `topic_prior_attempts` | F1 restricted to target `topic_id` | count | count | None | NULL → unseen topic |
| F9 | `topic_prior_correct` | F8 subset correct | count | count | None | NULL |
| F10 | `topic_hist_accuracy` | F9/F8 | rate; NULL when F8 = 0/NULL | rate | None | NULL → unseen topic |
| F11 | `topic_recent_accuracy_k3` | trailing ≤3 on topic | rate | rate | None | NULL |
| F12 | `topic_has_exposure` | F8 | 1 iff F8 > 0 | flag | None | 0 |
| F13 | `question_difficulty` | `questions.difficulty` | catalogue value (E/M/H) | one-hot (EASY vs else; see §21) | None (static) | always present |
| F14 | `quiz_difficulty` | `quizzes.difficulty` | catalogue value | one-hot | None (static) | always present |
| F15 | `subject_id`, `topic_id`, `question_id` | FK chain | identifiers | hashed ID / target-encoded **train-fold only**; default: excluded from linear model, kept for grouping/splits | ID-as-feature risks memorization — excluded from candidate v1 | n/a |
| F16 | `prev_mastery_score` | `topic_mastery` | latest row with `last_assessed_at < T` | value 0–100 | **High if mis-timed** — post-image (`=f(current outcome)`) is leakage; strict `< T` only | NULL → no prior mastery |
| F17 | `prev_attempt_count_tm` | same row | value | count | Same timing rule | NULL |
| F18 | `prev_recent_accuracy_tm` | same row | value | rate | Same timing rule (= label verbatim post-image) | NULL |
| F19 | `prev_trend` | same row | category | one-hot (4 levels) | Same timing rule | NULL |
| F20 | `prior_rec_activity` | `recommendations` | latest ACTIVE row with `generated_at < T` | category | Current-row (≥ T) is leakage | NULL |
| F21 | `days_since_last_attempt` | timestamps | T − max prior event time | float ≥ 0 | None | NULL → cold |

Explicitly **excluded**: `is_correct`, `selected_answer`, post-attempt
mastery/recommendation/XP, quiz score containing the target, target
response time, any same-quiz sibling outcome, future attempts /
recommendations / progress / game results, `duration_seconds`,
`response_time_seconds`, all `game_results.*` skill use.

## 6. Leakage rules

1. Strict inequality: history is `event_time < T`; `<=` is forbidden
   (siblings share T).
2. Same-quiz exclusion: no feature may aggregate other questions of the
   target quiz (identical `submitted_at`).
3. Pre-image only for state tables: `topic_mastery` /
   `recommendations` rows qualify iff their stored timestamp < T.
4. No target-derived columns: anything computed from the target
   `is_correct`, its quiz score, or post-submit state is a label, never a
   feature (`mlrag/contracts/leakage.py` blocklist enforces names).
5. Fold discipline: any encoding using outcomes (none in v1) must be fit
   on the train partition only.
6. Baselines obey 1–5 identically (a leaky baseline is a failed gate).

## 7. Point-in-time feature algorithm

```
for each question_attempt q (ordered by quiz.submitted_at, quiz id, question id):
    T  = q.quiz.submitted_at
    H  = all question_attempts of same learner with quiz.submitted_at < T
    S  = subset of H on q.topic_id
    M  = latest topic_mastery row for (learner, topic) with last_assessed_at < T
    R  = latest recommendations row for (learner[, topic]) with generated_at < T
    compute F1..F21 from (H, S, M, R, catalogue); NULL where undefined
    label = q.is_correct
```

Edge behavior: first-ever attempt → all history NULL, `is_cold_start=1`,
M/R NULL; first-on-topic → F8–F12 NULL/0, learner-level may exist;
first-in-difficulty → difficulty one-hots still defined (static);
sparse history → trailing windows shrink (`recent_n` records actual size);
ties in timestamps across quizzes → deterministic tie-break
`(submitted_at, quiz_attempt_id, question_id)` with strict `< T` preserved.

## 8. Dataset construction

Reproducible builder (future implementation, tested then): join
`question_attempts → quiz_attempts (user_id) → quiz_questions/quizzes →
questions → topics → subjects` via FKs only; left-join pre-image state
(M/R per §7); emit deterministic columns `[F1..F21 (minus modelled
subset), is_correct, learner_key, topic_id, question_id, quiz_id,
submitted_at]` ordered by `(learner, submitted_at, quiz, question)`;
**no learner PII** (surrogate `learner_key`, no emails/names/IDs); column
contract pinned as feature-schema version (e.g. `f1`). No extraction in
this gate.

## 9. Split/evaluation strategy

Naive random-row splits are **forbidden** (repeated learner history leaks
across folds). Required shape: user-aware + time-aware.

Given n=56 / 5 learners / 5 days, conventional train/validate/test is
statistically unreliable — the experiment is therefore a
**feasibility/baseline evaluation**:

- **Primary:** leave-one-learner-out CV (5 folds; each fold trains on
  4 learners, tests on the held-out learner's time-ordered rows).
  Measures cross-learner generalization; per-fold test rows ≈ 2–21.
- **Secondary:** temporal holdout — train on days 1–3, validate day 4,
  test day 5 (sizes depend on daily counts; folds with a single class
  report rank metrics as undefined, never interpolated).
- Within-learner rows stay time-ordered; no shuffling across time.
- Baselines are re-fit per fold (global rate = **train-fold** rate, never
  the 69.64% whole-dataset figure).

## 10. Baselines

- **A — global rate:** predict train-fold empirical P(correct); fallback
  reference for everything.
- **B — learner history:** learner's prior accuracy (F3); fallback to A
  when no history (cold start).
- **C — topic-conditioned:** topic prior accuracy (F10); fallback chain
  topic → learner (B) → global (A) as history thins.
- All three obey §6; all three are re-fit per evaluation fold.

## 11. Candidate ML model

**L2-regularized logistic regression** on a small fixed feature set
(F3, F5, F10/F12, F13–F14 one-hots, F16, F21; ≤8 columns) with
standardization fit on train folds. Rationale: interpretable
coefficients, calibrated probabilities, appropriate for n=56. No trees,
no boosting, no neural nets, no BKT/DKT/RL — unjustified at this size
(§21). Hyperparameter: single fixed C (documented), no tuning grid that
the data cannot support.

## 12. Metrics

Primary: **log loss** and **Brier score** (proper scoring rules, defined
per-row even for tiny folds). **Calibration** via coarse bins as a
diagnostic plot/table, not a pass/fail number. **Accuracy secondary only**
(69.6% majority baseline makes it misleading). **ROC-AUC / PR-AUC only
when mathematically valid** (both classes present in the test fold with
≥2 positives and ≥2 negatives); otherwise reported as `undefined`, never
imputed. No acceptance thresholds are set — none are justifiable at n=56.

## 13. Cold-start policy

States: `cold_start` (0 priors; 35/40 learners today), `sparse` (1–5),
`sufficient` (6+, experiment parameter, default min 3 prior outcomes for
model service). Model serves (`served_by_model=True`) only in
`sufficient`; otherwise `served_by_model=False` + reason
(`cold_start`/`sparse_history`) and the deterministic AdaptiveEngine path
applies unchanged. Baselines B/C degrade gracefully through their
fallback chains for analysis, but fallback never fabricates a model
signal.

## 14. Output contract

`PredictionResponse{request_id, served_by_model, p_correct ∈ [0,1],
confidence?, difficulty_suitability?, model{model_name, model_version,
data_snapshot_id}, fallback_reason?}`. Spring Boot validation (future
integration): reject NaN/±Inf, `p` outside [0,1], missing/unknown
`model_version` (allowlist), `request_id` mismatch, stale snapshot
(mismatch vs expected `data_snapshot_id`), oversized payloads, over-time
responses. Rejection → deterministic fallback, plus audit row.

## 15. AdaptiveEngine boundary

Python sidecar → prediction signal → Spring Boot → deterministic
`AdaptiveEngine` → authoritative decision. ML **cannot**: write/persist
mastery, write recommendations, alter difficulty outside ladder bounds,
bypass cold-start rules or deterministic thresholds, change scoring, XP,
achievements, progression, correctness, transaction order, identity, or
authorization. `ML = SIGNAL PROVIDER; AdaptiveEngine = AUTHORITY.`
Integration itself is NOT built in any GATE 3 work.

## 16. Versioning

Every prediction and experiment carries: `model_id` (e.g.
`logreg-pcorrect-v1`), `model_version` (semver), `feature_schema_version`
(`f1` = §5 table), `training_data_snapshot_id` (row count + time range +
content hash — no PII), `code_version` (sidecar commit), `eval_metadata`
(fold scheme, seed, metrics config), `created_at`. Unknown or stale
versions are rejected by contract.

## 17. Failure/fallback

Sidecar down / model missing / timeout / invalid response / feature-build
failure / unknown version / insufficient history → `served_by_model=False`
with reason → deterministic backend behavior (current quiz evaluation,
AdaptiveEngine, Tutor 503/degraded semantics where applicable). Failure
must never break evaluation/persistence, never retry-storm (bounded
timeouts, single retry max per existing Gemini discipline), and every
rejection is auditable.

## 18. Security

Server-to-server calls only (no public model endpoint); service
authentication (secret/reviewer-approved mechanism at integration time —
none introduced here); caller learner scope enforced by Spring Boot (no
arbitrary `user_id` lookup); no PII in features, logs, artifacts, or
versions (surrogate keys, counts only); no secrets in source (env-only,
see `mlrag/config.py`); bounded payload sizes; strict input validation;
timeouts + rate limits; audit rows for served/rejected predictions. No
model endpoint may expose learner data.

## 19. Test plan (future implementation tests)

1. Point-in-time correctness (hand-built histories with known answers).
2. Same-quiz sibling exclusion. 3. Strict `< T` boundary (equal timestamps
   excluded). 4. Leakage scanners (blocklist names absent from feature
   frames). 5. Chronological ordering determinism. 6. Cold-start/sparse/
   sufficient transitions. 7. Repeated-learner handling. 8. Baseline
   parity (hand-computed A/B/C). 9. Output validation (NaN/Inf/range/
   version/stale rejections). 10. Unavailable/timeout → fallback.
11. User-scope isolation (no cross-learner rows). 12. Determinism
   (byte-identical rebuilds). 13. Contract suite (`mlrag/tests`) stays green.

## 20. GATE 3 acceptance criteria

PASS requires ALL: (1) prediction unit defined pre-submit with
`user_id`-via-join; (2) label unambiguous (`is_correct`); (3) every
feature has source/availability/transform/leakage/cold-start spec and
uses strict `< T` + sibling exclusion; (4) split is user-aware +
time-aware, random-row explicitly forbidden, tiny-data limits stated;
(5) baselines A/B/C defined with fallback chains; (6) candidate is
logistic regression with justification, no complex model; (7) metrics per
§12 with validity conditions, no invented thresholds; (8) cold-start
states + fallback explicit, AdaptiveEngine authoritative; (9) output
contract with Spring-side rejection rules; (10) versioning complete;
(11) failure/fallback matrix complete; (12) security boundary complete;
(13) test plan covers §19; (14) zero production-code/schema/frontend
changes, zero data access, zero dependencies, zero commits.

## 21. Explicit limitations (dataset-size caused)

- n=56 rows / 5 learners / 5 days: all estimates are high-variance
  feasibility signals; no production claim is possible.
- HARD outcomes = 0 → HARD excluded from difficulty conditioning;
  MEDIUM = 4 → difficulty effects estimated essentially on EASY; F13
  collapses to EASY-vs-rest in v1.
- 9 learner-topic pairs, only 1 with ≥5 obs → topic-level learning curves
  are illustrative, not conclusive.
- 35/40 learners cold → personalization evidence is minimal; cold-start
  fallback is the dominant path by design.
- Response time (all NULL), game skill labels, rec-ranking, retention:
  excluded with prejudice until data exists.
- No thresholds, no model selection, no deployment decision can follow
  from this gate — it authorizes experiment construction only.
