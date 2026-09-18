# GATE 4 — Offline P(correct) Feasibility Experiment

> Status: experiment **constructed, unit-tested, and code-verified**.
> Live-database execution is **BLOCKED by a credential/instance mismatch**
> (evidence below); no metrics below are presented as measured unless the
> re-run fills them in. Nothing here is production-ready. No model
> artifact was persisted. No dataset was extracted.

## 1. Objective

Offline feasibility/baseline evaluation of P(correct | pre-attempt
information) per `mlrag/docs/GATE_3_ML_DESIGN.md`. Advisory only; the
deterministic AdaptiveEngine remains authoritative; no integration exists.

## 2. Data source

- MySQL `gamelearn` on `127.0.0.1:3306`, dedicated `gamelearn_ro`
  account (SELECT-only grant), via `MLRAG_DB_*` environment variables.
- Credentials: env-only, never hardcoded/printed/logged; connection
  refused unless `CURRENT_USER()` contains `gamelearn_ro` (`db.py`).
- Expected snapshot (externally measured): 40 users, 5 active learners,
  14 quiz attempts → 56 question attempts (39/17), 5 active days
  2026-08-26–2026-09-04, response times 56/56 NULL.

## 3. Data snapshot / time

Snapshot descriptor (computed at run time, no PII): row count, min/max
`submitted_at`, SHA-256 over ordered `(question_attempt_id, label)` pairs.
Recorded as `data_snapshot_id` in the results payload. (Pending live run.)

## 4. Feature schema (`f1`, 11 columns)

`hist_accuracy, recent_accuracy_k5, topic_hist_accuracy,
prev_mastery_score, days_since_last_attempt` (numeric, train-fold median
fill) + `is_cold_start, topic_has_exposure, q_diff_medium, q_diff_hard,
z_diff_medium, z_diff_hard` (flags/one-hots). Missing numerics carry
explicit missingness flags; nothing is forward-filled; cold rows keep
NULLs until the median-fill stage (medians fit on train folds only).

## 5. Leakage rules (enforced in code, tested)

Strict `< T` history (`T` = target quiz `submitted_at`); target row
excluded; future rows excluded; same-quiz siblings excluded (shared T);
state tables qualify only with stored timestamps `< T`; blocklisted names
(`is_correct`, `selected_answer`, post-image mastery/recommendation,
scores, timings, game skill fields, `future_*`) rejected by
`leakage.validate_feature_names`; feature frame asserted leak-free in
`LeakagePreventionTest`.

## 6. Dataset construction

`extract.py`: three SELECT-only statements with explicit columns (no
email/password/name/profile columns — asserted by `PrivacyTest`);
joins `question_attempts → quiz_attempts (user_id) → questions →
topics → subjects` and `→ quizzes` via FKs; chronological order;
`user_id` hashed at extraction to surrogate `learner_key`
(SHA-256, domain-separated, truncated) — raw IDs never leave the module.
`features.build_rows` implements the GATE 3 §7 algorithm deterministically.

## 7. Split strategy

Leave-one-learner-out CV (5 folds; test rows keep full-past `< T`
features; fitting uses train folds only) + temporal holdout (train days
1–3, validate day 4, test day 5, derived from observed dates). Random-row
splits forbidden. Baselines re-fit per fold (train-fold rates, never the
69.64% whole-dataset figure).

## 8. Baseline definitions

- **A:** train-fold global rate.
- **B:** learner prior accuracy at T; fallback to A when no history
  (all LOLO test rows for the held-out learner, by construction).
- **C:** topic prior accuracy (min 2 obs); fallback chain
  topic → learner → global.
- All obey point-in-time rules (tested).

## 9. Logistic regression definition

`logreg-pcorrect-v1`, v`0.1.0-exp`: L2 C=1.0, lbfgs, max_iter=1000,
fixed seed; StandardScaler fit on train; serves only rows with ≥3 priors
(`MIN_HISTORY_FOR_SERVICE`), else deterministic fallback value with
`served_by_model=False`. Probabilities validated finite ∈ [0,1].

## 10. Evaluation metrics

Primary log loss + Brier; accuracy secondary; ROC/PR-AUC only when both
classes have ≥2 samples in the evaluated set (else `null` =
unavailable); 5-bin calibration table on pooled out-of-fold predictions.
No acceptance thresholds (unjustifiable at n=56).

## 11. Cold-start behavior

States cold (0 priors) / sparse (1–2) / sufficient (≥3). Model serves
only sufficient rows; all other rows get fallback + reason. With 35/40
learners at zero history, fallback is the dominant path by design; the
experiment never claims personalization without history.

## 12. Actual measured results

**BLOCKED — not yet measured.** Live execution failed at connection with
`pymysql.err.OperationalError: (1045, "Access denied for user
'gamelearn_ro'@'localhost' (using password: YES)")`. Zero statements
executed (the identity assertion runs first; nothing was queried,
extracted, or written). To fill this section, resolve the credential or
instance mismatch, then run:

```
python -m mlrag.experiment.run_experiment
```

which prints and stores (under `mlrag/artifacts/gate4_results.json`)
the aggregate-only payload: counts, empirical rate, LOLO per-fold +
pooled metrics, temporal metrics, calibration, library versions,
snapshot ID, `deployment_ready: false`. Expected shape when green:
56 rows / 5 learners; served-by-model coverage ≈ rows with ≥3 priors;
rank metrics valid only on mixed folds.

## 13. Limitations

Tiny data (56/5/5d): all estimates high-variance feasibility signals.
HARD outcomes = 0 (excluded), MEDIUM = 4 (EASY-dominated). No timing, game
skill, rec-ranking, or retention claims. No thresholds, no selection, no
deployment decision follows. No model artifact persisted (inappropriate at
this size; evaluation records versions instead).

## 14. Deployment suitability

**NOT suitable for deployment.** This gate authorizes offline analysis
only. Any production use would require a later gate with orders of
magnitude more history, calibrated thresholds, integration contracts,
and owner approval — none of which exist.
