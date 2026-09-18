# GATE 19 — Baselines + First ML Challenger (EXPERIMENTAL, NO PROMOTION)

> Status: PASS (experimental evidence). Data readiness: NOT READY.
> Verdicts: CHALLENGER DOES NOT BEAT BASELINES (validation + pooled LOLO).
> Per the critical interpretation rule this honest negative result is NOT an
> implementation failure — no tuning was attempted, none is permitted.
> MODEL PROMOTION: NO. PRODUCTION READINESS: NO. ADAPTIVE ENGINE
> INTEGRATION: NO. MySQL read-only. No commits or pushes. Backend zero-delta.

## 1. Implementation summary

New sidecar package `mlrag/modeling/` implements the first experimental ML
layer on the authoritative Gate 17 (`mlrag/feature_pipeline/`) → Gate 18
(`mlrag/dataset/`, d1/f1) path: three frozen baselines (A train-majority, B
learner-history, C deterministic topic→learner→global chain, all strict
`predicted_at < T`), ONE L2 logistic-regression challenger
(C=1.0/lbfgs/max_iter=1000/random_state=42, no tuning), leakage-safe
train-only preprocessing (medians + scaler + fixed one-hot order, 31
columns), two honest protocols (required Gate 18 split; Gate-16 LOLO as the
experiment-only protocol), pre-registered primary comparison (pooled log
loss + Brier, must strictly beat A/B/C), 5-bin calibration, cold slices,
coverage accounting, reproducibility ×2, and PII-free artifacts. 56 new
tests; 390/390 green; backend untouched.

## 2. Files created/modified

Created under `mlrag/` only: `modeling/__init__.py`, `config.py` (frozen
single config + 31-column spec), `preprocessing.py` (train-only fit),
`baselines.py` (A/B/C on d1 rows), `challenger.py` (fit/predict_proba with
output validation), `metrics.py` (score_set, calibration, beats-all rule),
`experiment.py` (split + LOLO protocols, prediction records, cold slices),
`snapshot.py` (live read-only runner); `tests/gate19_fixtures.py`,
`test_gate19_preprocessing.py`, `test_gate19_baselines.py`,
`test_gate19_challenger.py`, `test_gate19_experiment.py`,
`test_gate19_leakage.py`; `artifacts/gate19_experiment.json` (57,454 B),
`artifacts/gate19_model.json` (1,807 B); this report. Modified: nothing
outside `mlrag/`; no existing test modified.

## 3. Dataset/source contract used

Gate 18 d1 rows (`dataset_version = d1`, `feature_version = f1`, 60 live
rows / 6 learners, fingerprint
`d770dc35138d2d87ae0d4a910f91e54e42e6f03e4540029a9a7ddc1c07195241`).
Model input is exactly the 19 frozen f1 features; IDs used only for
grouping/splitting/evaluation, never as predictive values. Banned inputs
(selected_answer, scores, post-attempt mastery, future/XP/streak/game/
progress/duration_seconds, raw IDs, PII) never enter the pipeline —
structurally absent from extraction upward.

## 4. Baseline A methodology

Train-fold positive rate, one frozen number per experiment (live split
protocol: 38/52 = 0.7308). Validation/test labels never read. Deterministic.

## 5. Baseline B methodology

Learner historical accuracy over strictly-past rows of the same learner
(`predicted_at < T`, any split — Gate-16 precedent), train-rate fallback
when no past exists. Current target never included (tested by flip probe).

## 6. Baseline C methodology

Deterministic topic→learner→global chain: learner-topic history rate when
≥2 past topic rows exist, else B, else train rate. This is the existing
Gate-16 experimental deterministic adapter, re-expressed on d1 rows and
verified point-in-time-safe. No verified Python adapter of the Java
AdaptiveEngine exists (it emits difficulty/mastery decisions, not
P(correct)); porting/inventing one is forbidden, so no backend change was
or is needed — the frozen experimental chain stands, documented here.

## 7. Challenger model methodology

Single L2 LogisticRegression(C=1.0, lbfgs, max_iter=1000, random_state=42)
on the 31-column matrix. `fit` reads train rows only; single-class/empty
training raises loudly. `predict_proba` validates finite [0,1] (raises
otherwise). Serves every valid row (cold included via documented
train-median path); coverage reported, not assumed.

## 8. Feature preprocessing

Train-only medians (all-NULL train column → documented 0.0 fallback:
prev_mastery_score, prev_recent_accuracy, prev_response_time_norm live),
train-only StandardScaler, fixed one-hot order (NULL categorical →
all-zero), booleans as-is. Live train medians: hist 0.625, recent-k5 0.8,
prior_attempt 1.0, prior_correct 4.0, prior_total 4.0, topic_hist 0.5,
gap 0.00076, seq 4.0. Every rule documented in `imputation_report`; no
silent zero-filling of semantic NULLs at the dataset layer.

## 9. Split/evaluation protocol

Required: Gate 18 split unaltered (train 52/4 learners → fit; validation
8/2 → score; test 0 → NOT COMPUTABLE, never fabricated). Experiment-only:
Gate-16 LOLO, 6 folds, per-fold refit, pooled out-of-fold comparison.
Baselines use all-past strict-`<T` context (precedent + deployment-honest);
preprocessing/model fits read fold-train only. Cold vs non-cold slices on
every scored population; coverage 1.0 for all methods everywhere.

## 10. Training configuration

`logreg-pcorrect-g19` `0.1.0-gate19exp`, solver lbfgs, C=1.0, max_iter=1000,
random_state=42, 31 matrix columns (frozen order), experiment id
`g19-exp-d1f1-d770dc35138d` (data-derived, no wall-clock). No grid, no
search, no refits beyond the protocol-mandated per-fold fits.

## 11. Baseline results

Validation (n=8, all cold → A=B=C=train rate): ll 0.6881, brier 0.2456,
acc 0.625, roc_auc 0.5, pr_auc 0.8125. Pooled LOLO (n=60): A ll 0.8379 /
brier 0.2745 / acc 0.7167 / roc 0.1936; B ll 0.5645 / brier 0.1978 / acc
0.6833 / roc 0.6532; C ll 0.5591 / brier 0.1951 / acc 0.6833 / roc 0.6833
(strongest baseline on both primaries). Test split: NOT COMPUTABLE (n=0).
Single-class folds report roc_auc None (NOT COMPUTABLE), never invented.

## 12. Challenger results

Validation: ll 0.8992, brier 0.3043, acc 0.625, roc 0.5, pr 0.8125.
Pooled LOLO: ll 7.4846, brier 0.2818, acc 0.7167, roc 0.2702, pr 0.6678 —
wrecked by overconfident errors on the held-out 28-row learner (fold ll
15.60) and the 4-row minority fold (1.81); cold slice ll 0.6518 / brier
0.2019 vs non-cold ll 12.04 / brier 0.3351.

## 13. Baseline vs challenger comparison

Pre-registered rule (pooled log loss + Brier, strictly beat A AND B AND C):
validation ll delta +0.2111 / brier +0.0588 (all `improves: false`);
pooled ll delta +6.65..+6.93 / brier +0.0073..+0.0867 (all false).
Verdict (both populations): CHALLENGER DOES NOT BEAT BASELINES. No tuning
attempted — forbidden.

## 14. Calibration analysis

Pooled challenger, 5 fixed bins: all 60 predictions in [0.6,0.8) (n=16,
dev −0.231) and [0.8,1.0] (n=44, dev +0.345); lower bins empty; overall
bias +0.1915 (overconfident); worst-bin +0.345. Labeled statistically weak;
no recalibration performed (out of scope). Validation (n=8): single
occupied bin, bias +0.2645, weak.

## 15. Leakage test results

12/12 PASS: target-not-in-X, no post-attempt data, train-only transform
fit, val/test labels unused, learner grouping (LOLO folds), Gate 18 split
reused unaltered, no random row splitting (source-scanned), no ID-as-feature
(matrix columns scanned), no PII in model artifact, current-answer/score
flip probes, future-row probes, deterministic training (refit-identical,
lbfgs + random_state=42 documented; solver is non-stochastic on fixed data).

## 16. Reproducibility results

Same experiment twice in-process: canonical-identical (PASS). Independent
process: byte-identical experiment artifact (57,454 B) and model artifact
(1,807 B) (PASS). Same dataset fingerprint, split, schema, config,
predictions, metrics. No hidden nondeterminism.

## 17. Model artifact/security audit

`gate19_model.json`: versions, solver config, 31 coefficients + intercept,
n_iter, train_rate, data fingerprint, experimental status — no data, labels,
IDs, or PII. Safety scans (email/JWT/password/token/user_id/answers/
secrets): experiment artifact 0 hits, model artifact 0 hits → PASS.

## 18. Live data statistics

60 rows / 6 learners / 5 topics / 5 quizzes / 20 questions; 43 pos / 17 neg
(0.7167); cold-start 24 (all 8 validation rows cold); timing_known 0;
mastery pre-image 0; train 52 (38/14), validation 8 (5/3), test 0.
DB counts after run identical (43/15/60/53/0/15) — data unchanged.

## 19. Data readiness evaluation (bars unmodified)

50 learners: 6 FAIL · 5000 rows: 60 FAIL · 60 days: 18.93 FAIL · ≥10/learner:
min 4 FAIL · 200 calibration rows: 60 FAIL · bias ≤0.05: 0.2167 FAIL →
DATA READINESS: NOT READY. Experimental training authorized anyway; no
promotion authorized.

## 20. Performance

60 rows: total ~3.15 s, fit+first-protocol ~0.70 s, peak ~598 KB. No
optimization.

## 21. Full test suite results

`python -m pytest mlrag/tests`: 390 passed, 0 failed, 0 errors (334
pre-existing incl. all Gate 17/18 tests + 56 new). No existing test modified.

## 22. Backend protection result

Pre- vs post-gate `git status --short` / `git diff --stat`: zero delta. No
backend/frontend/Spring/AdaptiveEngine/.env/Flyway/schema/data changes.
SELECT-only validated path; only new `mlrag/` files.

## 23. Known limitations

Tiny single-topic EASY-heavy data; empty test split; all-cold validation;
100% NULL mastery/timing history; hard 0/1 history rates make baseline log
losses spiky; logreg overconfident out-of-fold; calibration degenerate;
single fixed config by design.

## 24. Promotion decision

MODEL PROMOTION: NO. PRODUCTION READINESS: NO. ADAPTIVE ENGINE
INTEGRATION: NO — Gate 19 is experimentation only; the challenger lost to
the strongest baseline and data readiness is NOT READY on all six bars.

## 25. Final verdict

BASELINES IMPLEMENTED: YES
CHALLENGER IMPLEMENTED: YES
LEAKAGE TESTS: PASS
EVALUATION: PASS (honest negative result; test split NOT COMPUTABLE)
DETERMINISM: PASS
ARTIFACT SAFETY: PASS
BACKEND PROTECTED: YES
DATA READINESS: NOT READY
MODEL PROMOTION: NO
GATE 19: PASS
