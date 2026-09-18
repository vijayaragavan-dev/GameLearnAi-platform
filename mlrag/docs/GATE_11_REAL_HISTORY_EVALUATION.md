# GATE 11 — Real-History Shadow Evaluation (DESIGN + HARNESS)

> STAGE 1 offline replay. The live-DB path (`run_live_evaluation`) is
> implemented but BLOCKED in this session (no read-only channel);
> the framework is fully validated on labeled synthetic fixtures.
> NOT production evidence. NO PRODUCTION PROMOTION.

## 1. Objective

Answer whether the actual logreg model gives useful, calibrated,
non-leaking predictions on real history — once data access exists —
and whether anything justifies advisory influence. A blocked or
negative answer is acceptable.

## 2–4. Data source / snapshot / features

Live path: `gamelearn_ro` SELECT-only via `experiment.db` (identity
asserted, env-only creds) → `extract` (explicit columns, hashed
`learner_key`) → `features.build_rows` (unchanged f1 schema, strict
`< T`, sibling exclusion). Snapshot descriptor + row/learner/date
coverage recorded; missingness via `coverage.feature_coverage`.

## 5–6. Point-in-time methodology + leakage prevention

Per event at T: history = same learner, `timestamp < T` (strict; `<=`
forbidden); target quarantined in `OutcomeLedger`/evaluator truth,
never in predictor input; same-quiz siblings share T and are excluded;
post-image mastery/recommendations/scores excluded (pre-image `< T`
only); model outputs never re-enter features (single-pass purity +
rerun equality). Proven by 28-area leakage tests.

## 7–10. Model identity, baselines, temporal/learner-aware eval

Model unchanged: `logreg-pcorrect-v1` v`0.1.0-exp`, f1, C=1.0 lbfgs,
train-fold medians, LOLO-CV + temporal holdout (existing pipeline
reused verbatim). Baselines A/B/C redefined nowhere; scored on the
same served rows. Temporal cutoffs derived from observed dates;
single-date data reports TEMPORAL INSUFFICIENT. LOLO folds reported
valid/skipped with reasons; invalid folds never averaged.

## 11–14. Cold start, calibration, distribution, errors

Tiers via `MIN_HISTORY_FOR_SERVICE=3`; cold/sparse rows fall back and
are counted, never served. Calibration via Gate 5 summaries; bins
below `MIN_BIN_N` flagged; tiny samples → INSUFFICIENT_EVIDENCE.
Distribution reports min/max/mean/median + extreme (<0.05/>0.95)
counts to catch overconfidence/degeneracy. Error categories aggregate
(false-confident, missed correct/incorrect, cold/sparse fallback).

## 15–16. RAG + advisory shadow

Lexical TF-IDF only (Gate 7 preserved); per-topic retrieval with scope,
active, provenance, grounding checks; weak topic-membership labels
(not human judgments). Advisory synthesized but never applied; engine
not re-invoked offline (documented limitation, not a second algorithm).

## 17–18. Failure testing + feedback protection

All 12 Gate 9 failure modes re-exercised through the harness (tests);
no state mutation possible (no writers exist); no online learning; no
retraining on predictions; rerun equality proves no feedback path.

## 19. Reproducibility

Deterministic ordering `(submitted_at, question_attempt_id)` imposed;
snapshot ID + versions recorded; rerun verified identical in tests.
DB row-ordering risk neutralized by explicit sorting.

## 20. Security/privacy

Env-only creds (never printed/logged/hardcoded); explicit-column
SELECTs (no passwords/emails/profiles/tokens); hashed learner keys;
aggregate-only artifacts; `test_gate11` asserts no credential strings
in code and no PII patterns in payloads.

## 21. Promotion policy evaluation

Gate 5 `promotion.assess` reused unchanged — no new standard, no
invented thresholds. Every requirement reported PASS/FAIL (provisional
bars labeled as such).

## 22. Limitations

Live data access blocked this session; fixture runs validate machinery
only; n=56 known data still too small for production claims; HARD
absent; timing NULL; rec outcomes incomplete; temporal weakness +
overconfidence already recorded.

## 23. Final decision

**NOT PROMOTABLE — PROMOTION BLOCKED** (insufficient evidence by
construction until live data flows; current known data already fails
Gate 5 bars). NO PRODUCTION PROMOTION. Stage stays STAGE_1.
