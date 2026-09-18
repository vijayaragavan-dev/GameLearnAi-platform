# GATE 5 — ML Hardening & Evaluation (offline only)

> Hardens the GATE 4 feasibility experiment for future data growth. No
> production integration, no new model, no thresholds-as-claims, no
> deployment. `deployment_ready` remains `false`.

## 1. What changed (mlrag/ only)

- `experiment/coverage.py` (new): per-column total/non-null/missing/
  coverage_pct for any row set. Read-only introspection; values untouched.
- `experiment/sufficiency.py` (new): facts (rows, learners, classes,
  dates, per-learner min/max, served rows) + tier
  (`evaluation_impossible` / `feasibility_only`) + blockers.
- `experiment/comparison.py` (new): model-vs-A/B/C deltas for log loss,
  Brier, ROC/PR-AUC; `improves=None` + `insufficient_evidence` whenever a
  side is unavailable. Accuracy never decides.
- `experiment/calibration.py` (new): overall bias/direction, worst-bin
  deviation, per-bin sufficiency (`MIN_BIN_N=10`); no recalibration.
- `experiment/promotion.py` (new): offline-only `PromotionPolicy` with
  PROVISIONAL bars (50 learners / 5000 rows / 60 days / 10 per-learner /
  200 calibration N / 0.05 bias) + `assess()` — any single failure blocks.
  Current data fails nearly all bars by design.
- `experiment/run_experiment.py` (additive only): payload gains
  `coverage`, `sufficiency`, `comparison_pooled_lolo`,
  `calibration_summary`, `promotion`. All GATE 4 keys byte-identical in
  meaning; numerics pipeline untouched.
- `tests/test_gate5.py` (new, 18 tests).

## 2. What did NOT change

Features, imputation (train-fold medians, All-NaN → 0.0 fallback
preserved exactly), model (L2 logreg, fixed config), baselines A/B/C,
splits (LOLO + temporal), point-in-time/sibling/target rules, contracts,
backend, frontend, schema. No dependency added. No credentials handled.

## 3. Evidence

- Full suite: **88/88 pass** (43 contract + 27 experiment + 18 gate5).
- Coverage on current data shape: flags 100%, history-backed numerics
  partial (cold rows), `prev_mastery_score` sparsest — consistent with the
  investigated All-NaN finding (expected sparse-data behavior).
- Sufficiency on current data: tier `feasibility_only` (never production).
- Comparison discipline: single-class folds keep `roc_auc`/`pr_auc` null;
  logreg did not beat the strongest baseline (unchanged conclusion).
- Promotion on current data: NOT promotable (volume, stability,
  calibration bars all fail).

## 4. Preserved limitations

Response time NULL, duration degenerate, HARD absent, game skill linkage
absent, rec-ranking outcome data absent, n=56/5 learners/5 days —
feasibility evidence only. Service contract unchanged: ML is advisory;
AdaptiveEngine owns mastery/difficulty/recommendations/XP/scoring.

## 5. Acceptance

Hardening implemented, tested, deterministic; evaluation semantics
preserved; no production integration; no prohibited artifact. **GATE 5:
PASS (offline hardening complete; deployment NOT authorized).**
