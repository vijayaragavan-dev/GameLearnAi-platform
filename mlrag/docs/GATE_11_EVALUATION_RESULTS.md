# GATE 11 — Evaluation Results

> REAL-HISTORY OFFLINE EVALUATION ONLY. NO PRODUCTION PROMOTION.
> Live-DB section: BLOCKED (no read-only channel in this session).
> Framework-validation section: measured on labeled synthetic fixtures.

## DATA

- Real-history events/learners/dates: BLOCKED — `run_live_evaluation`
  raises `ContractViolation` (missing MLRAG_DB_*) before any connection;
  verified by test, zero statements executed, nothing invented.
- Framework fixture: 7 events, 2 learners, 4 active dates (synthetic).

## HISTORY (fixture)

cold 2, served 1 (MIN_HISTORY=3), fallback remainder; tier
`feasibility_only`.

## MODEL (fixture)

logreg-pcorrect-v1 / 0.1.0-exp / f1. Served-row log loss 0.585 vs
A 0.611 / B,C 10.65 (tiny-fixture arithmetic, not evidence).
Temporal feasible on fixture (train/valid/test split by date).

## BASELINES

A/B/C scored on identical served rows via shared helpers; parity tested.

## CALIBRATION

Valid shape, insufficient sample on fixture (bins < MIN_BIN_N flagged).

## RAG (fixture corpus)

2 topics, both grounded, 0 empty, 0 scope violations, 0 grounding
failures; weak topic-membership labels only.

## SAFETY

28-area suite green: read-only guards, no-creds-in-code, hashing,
target/sibling/future separation, tiers, model/baseline parity, split
validity, calibration shape, invalid-metric None, RAG scope/grounding/
inactive, 12 failure fallbacks, advisory separation, determinism,
aggregate-only output, no promotion.

## PROMOTION

Gate 5 policy on fixture: NOT promotable (population, volume, temporal,
history, stability, calibration bars fail). Real data: INSUFFICIENT
EVIDENCE (access blocked). Final: **NOT PROMOTABLE. NO PRODUCTION
PROMOTION.** Stage remains STAGE_1.
