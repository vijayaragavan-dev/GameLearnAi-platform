# Learner Intelligence / Adaptive ML Layer — Implementation Report (Gate 24)

> FINAL VERDICT: **PASS (implementation) — MODEL STATUS: NOT-READY**.
> A real, leakage-safe learner-intelligence pipeline is complete:
> candidates honestly evaluated, calibration assessed, versioned artifact
> built with promotion explicitly denied, and a fallback-enforcing
> serving contract proven by tests. The deterministic AdaptiveEngine
> remains the sole authority; no experimental probability can reach it.

## 1. Objective

Answer "P(correct | learner, topic, difficulty, history)" as a bounded
ML SIGNAL — never a decision — under the architecture
learner data → leakage-safe features → validated signal →
deterministic AdaptiveEngine → authoritative mastery/difficulty/
recommendation. Without forcing a model into production.

## 2. Current data snapshot (live, read-only, 2026-09-15)

60 eligible rows / 6 learners / 5 topics / 5 quizzes / 20 questions /
2026-08-26T07:41 → 2026-09-14T06:07 (18.93 days) / 43 pos / 17 neg
(0.7167). Cold-start rows 24; timing_known 0; mastery pre-image 0;
EASY 56 / MEDIUM 4 / HARD 0; attempts/learner {4,4,4,8,12,28}.
**Zero growth since Gate 18**: live rebuild fingerprint
`d770dc35138d2d87ae0d4a910f91e54e42e6f03e4540029a9a7ddc1c07195241`
identical, parity True. No synthetic rows created, ever.

## 3. Existing feature pipeline (reused, not duplicated)

Gate 17 `feature_pipeline/` (SELECT-only, explicit columns, surrogate
`learner_key`, forbidden columns never selected) → Gate 18 `dataset/`
(d1 over frozen f1: 19 features — accuracy histories, attempt counts,
topic accuracy, mastery pre-image, trend/difficulty categoricals,
exposure/cold/timing flags, difficulties, sequence index).
Verified f1 contents: NO game/XP/streak/progress/chosen-answer/
PII/sensitive attributes — correctness labels only via `is_correct`.
NULL preserved (`prev_mastery_*` 100% NULL by schema design,
`prev_response_time_norm` 100% NULL); NULL = unknown, never zero-filled
at the dataset layer (train-median imputation lives in the frozen
train-only preprocessor with documented 0.0 fallback, recorded per
column).

## 4. Dataset fingerprint

d1/f1, `d770dc35…715241`, `data_version =
snapshot-v1:qa60:qz15:lr6:2026-08-26T07:41:44:2026-09-14T06:07:18:
shab7db1508d17b`. Split (Gate 18 policy, reused unaltered): train 52
rows / 4 learners (usable), validation 8 / 2 (unusable: <10 rows +
train overlap), test 0 (empty, NOT COMPUTABLE — never fabricated).

## 5. Split strategy

`user_aware_time_aware` (whole learners, first-activity ordered, first
learner pinned to train, no RNG) + Gate-16 LOLO (6 folds, per-fold
refit, strict `<T` baseline context, preprocessing/model fits on
fold-train only). No random 80/20, no shuffling, no learner overlap.
Reused via `dataset.split` + `modeling` primitives.

## 6. Baselines (frozen, re-measured live)

Pooled LOLO (n=60): A (train rate) ll 0.8379 / brier 0.2745 / acc
0.7167 / roc 0.19; B (learner history) 0.5645 / 0.1978 / 0.6833 /
0.653; **C (topic→learner→global chain) 0.5591 / 0.1951 / 0.6833 /
0.683 — strongest on both primaries**. Validation (n=8, all cold):
A=B=C 0.6881 / 0.2456. Single-class folds report roc None (NOT
COMPUTABLE).

## 7. Candidate models

* D `logreg-pcorrect-g19` (existing challenger, lbfgs/C=1.0/1000/seed
  42 — re-run, not re-tuned).
* E `rf-pcorrect-g24` 0.1.0-gate24exp (ONE new challenger):
  RandomForest(64 trees, depth ≤3, min_split 10, min_leaf 5,
  max_features sqrt, seed 42, n_jobs 1). Justified: shallow +
  large-leaf + bagging curb variance at n≈52 train; no scaling
  assumptions; impurity importances for review; deterministic;
  CPU-trivial. Rejected without trial: deep nets/transformers/LLMs/RL
  (sample complexity absurd at n=60), GBM (sequential overfit risk on
  14 negatives), deeper/wider forests (variance without evidence).
  RAG embeddings deliberately NOT used for tabular prediction (§8
  policy honored).

## 8. Selected model

**E (RF)** by the pre-registered rule (lower pooled log loss: 0.9936
vs 7.4846). Selection ≠ promotion: E still loses to baseline C on
both primaries (see §12). Exact config in §7 +
`mlrag/learner_intelligence/config24.py` (no tuning grid exists).

## 9. Model configuration

As §7. Matrix: frozen 31 columns (11 standardized numerics, 3 bools,
17 fixed one-hots, NULL categorical → all-zero). Train-only medians +
StandardScaler, fitted per fold-train only.

## 10. Preprocessing

Reused `modeling.preprocessing` unchanged (fit/transform/
imputation_report). Live train medians documented in the experiment
artifact; all-NULL train columns fall back to 0.0 deterministically
and are recorded (prev_mastery_*, prev_response_time_norm live).
Preprocessing determinism covered by refit-identical checks.

## 11. Training

Per-fold-train fits only (6 LOLO + 1 split-train per candidate);
single-class training raises loudly (tested). Full run: 40.1 s,
peak 2.39 MB. RF fit on 52 rows: 144 ms.

## 12. Evaluation (honest numbers, same protocol for all)

| Pooled LOLO (n=60) | ll | brier | acc | roc |
|---|---|---|---|---|
| A | 0.8379 | 0.2745 | 0.7167 | 0.19 |
| B | 0.5645 | 0.1978 | 0.6833 | 0.653 |
| C | **0.5591** | **0.1951** | 0.6833 | 0.683 |
| D (LR) | 7.4846 | 0.2818 | 0.7167 | 0.270 |
| E (RF) | 0.9936 | 0.2720 | 0.7167 | 0.215 |

Validation (n=8): D 0.8992/0.3043, E 0.8027/0.2823 vs A/B/C
0.6881/0.2456. Test: NOT COMPUTABLE (n=0). Pre-registered rule
(strictly beat A+B+C on ll AND Brier): **both challengers DO NOT
BEAT BASELINES** (E deltas vs C: ll +0.43, brier +0.077). D reproduces
Gate 19 to 3 decimals (reproduction confirmed). E avoids D's
overconfident blowup (worst fold contained) but ranks worse than
chance (roc 0.215) — reported, not hidden. Accuracy never decides.

## 13. Calibration

Pooled OOF, fixed 5 bins: E occupies 2 bins, ECE **0.2899**, bias
**+0.1576** (overconfident); D: ECE 0.3146, bias +0.1915.
Recalibration rule (train n≥200 AND minority class ≥50): current
52/14 → **declined → CALIBRATION STATUS = INSUFFICIENT DATA**
(recorded, not faked; no calibrator fit on valid/test).

## 14. Cold-start behavior

Bands reuse frozen evidence: cold = `is_cold_start`/0 past attempts →
baseline path; limited = 1–9 → baseline path; sufficient = ≥10
(Gate-5 bar) → eligible for signal IF all other gates pass (none do
today). Measured: cold slice participates in all populations;
coverage 1.0 everywhere. No overconfident personalized predictions
for history-less learners — enforced in code (`cold_start` /
`insufficient_history` fallbacks, tested).

## 15. Robustness

Refit-identical (max abs diff ≤1e-9: PASS); fold-level losses
reported per learner (no failure averaged away); row-order
determinism inherited from frozen pipeline; live rerun reproduces
Gate 19 D numbers exactly. Slices: history bands, difficulties (HARD
n=0 → zero coverage reported), per-topic (n<10 flagged
insufficient). No sensitive attributes exist or are constructed.

## 16. Explainability

RF importances (review only, no causal claims): prior_attempt_count
0.1745, prior_total_count 0.1665, attempt_sequence_index 0.1643,
days_since_last_attempt 0.1486, topic_has_exposure 0.1003,
recent_accuracy_k5 0.0874, prior_correct_count 0.0804, hist_accuracy
0.0599. Tenure/recency/exposure structure dominates; sparse
mastery/timing one-hots contribute ~0 (expected: 100% NULL live).
Educationally coherent as correlational structure.

## 17. Production eligibility

**NOT-READY** (both candidates, 9 blockers each): 6 learners/50,
60/5000 rows, 18.93/60 days, min-per-learner 4/10, LOLO-unstable,
temporal-unstable (empty test split makes this structurally
unachievable today), no pooled improvement, calibration n 60/200,
bias unproven. `model_promotion: NO`. No tuning was or will be used
to move these numbers — only real data growth.

## 18. Artifact integrity

`mlrag/artifacts/gate24_learner_model.json` (11,990 B, fp
self-consistent, safety scan 0 hits): versions, config, f1/d1,
dataset fingerprint, data version, train population, imputation
report + full fitted stats (medians/means/scales/fallbacks),
parameters (importances/train rate/class counts), evaluation
summary, calibration status, eligibility=false, blockers, library +
Python versions, timestamp. JSON-only (no pickle → no code-execution
surface). Loader refuses: unparsable/missing keys/fingerprint
tamper/version mismatch (CorruptModel), fingerprint drift
(StaleModel), eligibility≠true (ModelNotEligible). Verified by tests
including the real artifact (valid-but-dormant).

## 19. AdaptiveEngine integration

Contract implemented, authority untransferred: `serving.score()`
returns `Prediction(probability + model/feature/dataset/artifact
versions, cold/history metadata, latency)` ONLY if artifact-eligible
AND version/fingerprint match AND sufficient history AND p∈[0,1]
finite; else explicit `Fallback(reason)` (cold_start,
insufficient_history, model_not_eligible, stale_model,
corrupt_model, model_unavailable, feature_mismatch,
malformed_prediction, timeout, invalid_request). The engine keeps
mastery bounds, floors/ceilings, progression, recommendation limits,
and cold-start handling; ML can only ever supply one bounded input.
**No backend changes made** — Spring wiring is designed (mirrors the
Gate 23 RAG service pattern: server-derived identity, validated
request, bounded call, deterministic fallback) and explicitly gated
on a future promotion event. No Java code was touched for an
ineligible model (no unnecessary infrastructure).

## 20. Fallback behavior

PASS (all paths tested, incl. 6 adaptive scenarios): new learner →
cold_start; sufficient-history → model_not_eligible (binding
constraint today); missing artifact → model_unavailable; drifted fp
→ stale_model; tampered → corrupt_model; raising/out-of-range
inference → malformed_prediction; slow inference → timeout;
smuggled `predicted_probability` ignored (no such input exists);
cross-learner identity cannot select parameters (opaque ref, single
bound artifact). Deterministic behavior continues in every case.

## 21. Security

Artifact/experiment/code scans (email/JWT/secret/private-key/
raw-ID/chosen-answer patterns): **0 hits**. Surrogate learner keys
only; counts-only reporting. No model-file selection from input (fixed
artifact path configured server-side in future wiring); no
filesystem exposure; no secrets in logs (no secrets exist in this
pipeline — DB credentials stay in-process env, never logged).

## 22. Test results

70 new Gate 24 tests pass (nonlinear contract, runner mechanics +
live regression, calibration math + rule, artifact gates, serving +
scenarios, leakage probes, promotion honesty). Full mlrag: **640
passed, 0 failed** (570 pre-existing incl. all RAG suites — RAG
regression PASS). Backend: **579 run, 0 failed** (8 pre-existing
Docker skips; backend unchanged). No existing test modified.

## 23. Performance

Experiment 40.1 s / 2.39 MB peak (60 rows × 7 fits × 2 candidates);
RF fit 144 ms (52 rows); inference 0.261 ms/row; serving gate
overhead microseconds; artifacts 233 KB + 12 KB. No optimization
needed at hackathon scale.

## 24. Database protection

Zero writes (SELECT-only validated path; DB counts unchanged);
no tables, no migrations (V1–V28 intact), no schema discussion
beyond reuse. Game results NOT used (no authoritative
topic/difficulty/correctness linkage for non-quiz games; quiz-family
correctness already flows via question_attempts). Response time used
only as nullable pre-image (NULL preserved, never zero-filled).

## 25. Backend changes

NONE. AdaptiveEngine, quiz scoring, auth, AI Tutor, RAG, Gemini,
DTOs, and contracts untouched.

## 26. Frontend changes

NONE.

## 27. Known limitations

n=60 single-snapshot data; EASY-heavy, single-topic-heavy; empty test
split; all-cold validation; 5 single-class LOLO folds (roc None);
100% NULL mastery/timing pre-images; 2 occupied calibration bins;
RF ranking below chance OOF; sibling-lesson relevance caveat
inherited from RAG eval (unrelated path). Serving binds the
promotion-run bundle in the future; the on-disk artifact is the
audit/gate record (documented, tested).

## 28. Future data requirements

Re-run `mlrag.learner_intelligence.snapshot` (the retraining
pathway) when live data grows; promotion re-gates automatically on
the FROZEN bars: ≥50 learners, ≥5000 rows, ≥60 active days, ≥10
min/learner, ≥200 calibration rows, |bias|≤0.05, strict pooled wins
over A/B/C on ll+Brier, temporal wins on non-empty valid+test, ECE
evidence, reproducibility, leakage-free, cold-start-safe. No fake
data may ever satisfy these. Recalibration unlocks at train n≥200
with minority class ≥50.

## 29. Final verdict

Implementation **PASS** — leakage-safe pipeline preserved and
extended, honest evaluation (D reproduces Gate 19; E improves on D
but loses to baseline C), calibration assessed with principled
decline, cold-start/fallback machinery proven, artifact valid and
dormant, AdaptiveEngine authoritative, no bypasses, no synthetic
data, 640 + 579 tests green, no schema/Git violations.
Model status: **NOT-READY** (9 blockers). Promotion: **NO**.
