# GATE 20 — Evaluation + Calibration (EVALUATION GATE, NO TUNING, NO PROMOTION)

> Evaluation: PASS (trustworthy evidence). Challenger: DOES NOT BEAT the
> strongest frozen baseline. Calibration evidence: INSUFFICIENT. Data
> readiness: NOT READY. MODEL PROMOTION: NO. No tuning, no retraining with
> altered config, no synthetic data, no integration. MySQL read-only. No
> commits or pushes. Backend zero-delta vs pre-gate baseline.

## 1. Executive summary

Gate 20 independently re-evaluates the frozen Gate 19 experiment
(`logreg-pcorrect-g19 0.1.0-gate19exp`, d1/f1, 60 rows / 6 learners) and
finds its negative result trustworthy: pooled LOLO log loss 7.4846 and
Brier 0.2818 lose to the strongest frozen baseline C (0.5591 / 0.1951);
the challenger never predicts the negative class (positive prediction
rate 1.0), concentrates 73% of mass at p >= 0.8 with minimum p 0.75, puts
ALL 17 errors at p >= 0.8 (overconfidence verified: bias +0.1915), and
collapses on the single large mixed fold (ll 15.60). Calibration evidence
is INSUFFICIENT (60 rows, 2 of 5 bins occupied, 200-row bar unmet).
Engineering validity is PASS; statistical evidence for any production
claim is absent. Promotion: 9 blockers, NOT promotable.

## 2. Gate 19 artifact verification

PASS. `gate19_experiment.json` + `gate19_model.json` present and parse;
model `logreg-pcorrect-g19 0.1.0-gate19exp`, feature f1, dataset d1;
recorded fingerprint `d770dc35…` matches the live Gate 18 rebuild (no
silent regeneration); recorded split assignment matches live on all 60
rows (0 mismatches); challenger config byte-identical to frozen
(lbfgs/C=1.0/max_iter=1000/random_state=42, 31 columns; tuning-construct
source scan clean); both artifacts safety-scanned with 0 hits.

## 3. Evaluation protocol

Reused unaltered: Gate 18 split (train 52 → fit; validation 8 → score;
test 0 → NOT COMPUTABLE) and Gate-16 LOLO (6 learner folds, per-fold
refit, strict `<T` all-past baseline context, preprocessing/model fits on
fold-train only). Gate 20 performs NO refits of its own — it re-scores the
60 recorded out-of-fold predictions and the split populations, then slices
by joined d1 context (topic, difficulty, cold flag).

## 4. Dataset statistics

60 rows / 6 learners / 5 topics / 5 quizzes / 20 questions / 6 active
dates; 43 pos / 17 neg (0.7167); cold-start 24; timing/mastery history
0%; difficulties EASY 56 / MEDIUM 4 / HARD 0; attempts/learner 4–28.

## 5. Baseline results

Pooled LOLO: A ll 0.8379 / brier 0.2745 / acc 0.7167 / roc 0.1936; B ll
0.5645 / brier 0.1978 / acc 0.6833 / roc 0.6532; C ll 0.5591 / brier
0.1951 / acc 0.6833 / roc 0.6833 → strongest baseline = C on both
primaries. Validation (n=8, all cold): A=B=C ll 0.6881 / brier 0.2456.
Single-class folds (5 of 6): ROC NOT COMPUTABLE, honestly reported.

## 6. Challenger results

Pooled: ll 7.4846, brier 0.2818, acc 0.7167 (= majority rate), roc 0.2702,
pr 0.6678, mean p 0.9082 vs observed 0.7167, positive prediction rate
1.0 (never predicts class 0). Validation: ll 0.8992 / brier 0.3043.
Cold slice ll 0.6518 (≈ C 0.6502); non-cold slice ll 12.0398 (C 0.4983).

## 7. Baseline vs challenger comparison

Pre-registered rule (strictly beat A+B+C on pooled ll AND Brier):
deltas +6.65…+6.93 (ll), +0.007…+0.087 (brier), all `improves: false` →
CHALLENGER DOES NOT BEAT BASELINES (pooled and validation). Absolute and
relative gaps reported per baseline in the artifact; accuracy never decides.

## 8. Fold-level robustness

fold_01 (4/4): model 0.249 < C 0.362 beats=True · fold_02 (12/12): 0.149 vs
0.146 beats=False · fold_03 (4/4): 0.249 vs 0.362 True · fold_04 (8/8):
0.167 vs 0.198 True · fold_05 (4, 1 pos): 1.810 vs 1.112 False · fold_06
(28, 14/14): 15.597 vs 0.817 False. Best fold_04, worst fold_06 (largest
error concentration: the only large mixed learner). No learner removed;
failures averaged nowhere — pooled verdict stands on all rows.

## 9. Cold-start analysis

Cold (24 rows, 19 pos): model ll 0.6518 / brier 0.2019 / acc 0.7917 —
competitive with C (0.6502/0.2115). Non-cold (36 rows, 24 pos): model ll
12.0398 / brier 0.3351 vs C 0.4983/0.1841 — collapse localized to
history-carrying rows of the dominant learner. Coverage 1.0 all methods.

## 10. Difficulty analysis

EASY (56 rows, obs acc 0.696): model ll 8.0135. MEDIUM (4 rows, all
positive): model ll 0.0806. HARD: 0 rows — zero coverage reported, nothing
fabricated. All difficulty slices statistically weak (one adequate only by
count, still single-topic-heavy).

## 11. Topic analysis

Slices (short safe IDs): `topic_..2211` n=16 delta −0.127 (sole slice win,
insufficient n); `topic_..2212` n=32 delta +11.900 (adequate count, heavy
loss); `topic_..2213` n=4 +0.081; `topic_..2214` n=4 +8.413; `topic_..2232`
n=4 +0.699. No slice removed; small slices labeled insufficient; no
learner identity exposed.

## 12. Calibration analysis

Fixed 0.2-width bins, challenger, pooled n=60: [0.0,0.6) empty ×3;
[0.6,0.8) n=16 gap −0.231; [0.8,1.0] n=44 gap +0.345. Mean p 0.9082,
observed 0.7167, signed bias +0.1915 — independently verifies Gate 19's
≈+0.19 overconfidence; not hidden. Weighted abs gap 0.3146 computed but
flagged unjustified (see §13). No recalibration performed.

## 13. Calibration reliability

Rule (n ≥ 200 AND ≥4/5 bins occupied AND ≥10/bin AND ≥3 learners): 60
rows, 2 occupied bins → CALIBRATION EVIDENCE = INSUFFICIENT (valid,
expected). No production-grade calibration claimed.

## 14. Confidence/uncertainty analysis

Range [0.752, 1.0]; mean 0.908; ≥0.8: 73.3%; ≥0.9: 66.7%; ≤0.2: 0%.
17 errors / 17 at p ≥ 0.8 → high-confidence error share 1.0 →
excessively_confident_errors TRUE. The model is a confident majority
voter: it never emits p < 0.5 yet is wrong 28% of the time, always
confidently. Model unmodified.

## 15. Robustness/reproducibility checks

Repeat / fold-order / row-order (12dp-canonicalized: floating-point
summation order is the documented serialization detail) / JSON reload:
all identical → robustness PASS. Full analysis repeated in-process:
identical → PASS. Independent process: byte-identical 30,661 B artifact
→ PASS.

## 16. Data sufficiency

Gate-5 bars (frozen): learners 6/50 FAIL · rows 60/5000 FAIL · 6/60 days
FAIL · min/learner 4/10 FAIL · calibration 60/200 FAIL · bias 0.2167/0.05
(proxy; model-calibration proper unevaluable for readiness) FAIL →
DATA READINESS: NOT READY.

## 17. Promotion criteria evaluation

Reused `promotion.assess` on measured evidence: 9 blockers (volume ×4,
lolo-stable, temporal-stable, beats-pooled, calibration-n, calibration
bias); PASS only on both-classes, reproducible, leakage-free,
cold-start-safe. Promotable: False. MODEL PROMOTION: NO.

## 18. Security/artifact audit

`gate20_evaluation.json` (30,661 B) scanned: 0 hits → PASS. No PII/JWT/
secrets logged; stdout summary strips surrogate keys to fold labels.

## 19. Performance

60 rows × 6 folds: 11.52 s total, peak 379,275 B. No optimization.

## 20. Test results

`python -m pytest mlrag/tests`: 422 passed, 0 failed (390 pre-existing
incl. all Gate 17/18/19 suites + 32 new Gate 20 tests). No old test
modified.

## 21. Backend/database protection

Pre/post `git status --short` + `git diff --stat`: zero delta. No
backend/frontend/Spring/AdaptiveEngine/.env/Flyway/schema changes; DB
counts unchanged (SELECT-only); only new `mlrag/` files.

## 22. Known limitations

n=60, 6 learners, 1 dominant learner (28 rows), single-topic EASY-heavy,
empty test split, all-cold validation, 5 single-class folds, 100% NULL
mastery/timing history, 2 occupied calibration bins, ulp-level float
non-associativity (documented, canonicalized in one check).

## 23. Final decision

GATE 19 MODEL VERSION: logreg-pcorrect-g19 0.1.0-gate19exp
FEATURE VERSION: f1
DATASET VERSION: d1
EVALUATION: PASS
LEAKAGE: PASS
CALIBRATION: INSUFFICIENT EVIDENCE
ROBUSTNESS: PASS
REPRODUCIBILITY: PASS
ARTIFACT SAFETY: PASS
DATA READINESS: NOT READY
CHALLENGER BEATS STRONGEST BASELINE: NO
MODEL PROMOTION: NO
PRODUCTION READINESS: NO
ADAPTIVE ENGINE INTEGRATION: NO
BACKEND PROTECTED: YES
GATE 20: PASS
