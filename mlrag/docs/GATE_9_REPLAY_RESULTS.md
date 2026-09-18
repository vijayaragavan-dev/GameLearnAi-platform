# GATE 9 — Replay Results (OFFLINE HISTORICAL REPLAY ONLY)

> Framework-validation run on a hand-built synthetic fixture (10 events,
> 3 learners, 2 topics — labeled synthetic, never learner data). These
> numbers prove the replay machinery works. They are NOT production
> evidence, NOT model validation, NOT RAG quality claims.

## 1. Dataset source

Synthetic fixture defined inline at evaluation time (no DB, no files,
no PII): learner A (6 events, mixed outcomes), B (3), C (1 cold);
2-topic fixture corpus (2 documents). Purpose: exercise cold/sparse/
sufficient paths, fallback, grounding, and determinism end to end.

## 2. Measured framework output

- Events 10, learners 3; tiers cold 3 / sparse 4 / sufficient 3.
- Served ML 7, fallback ML 3 (`no prior history` × 3 — all cold rows).
- Served-row metrics: log_loss 10.726 (extreme: tiny fixture with
  confident misses), Brier 0.441, accuracy 0.571, ROC-AUC 0.167,
  PR-AUC 0.494 — reported, not interpreted.
- Baselines B/C identical to ML here **by construction** (the replay
  default predictor IS Baseline-B; this validates the comparison
  harness, not any model).
- Categories: ml_supported 4, ml_misleading 3, ml_fallback 3;
  rag_grounded 10, rag_empty 0, rag_failed 0.
- Scope violations 0; grounding failures 0.
- Deterministic rerun: identical (`RERUN-EQUAL: True`).
- Failure-mode matrix (unit tests): all 6 ML modes + 6 RAG modes fall
  back/degrade with reasons; tampered citations and foreign subjects
  rejected; no ungrounded content ever served.

## 3. What this proves / does not prove

Proves: ordering, point-in-time discipline, target/ledger separation,
cold gating, fallback coverage, scope + grounding enforcement,
determinism, aggregate safety. Does NOT prove: model quality, RAG
quality on real queries, calibration, production readiness — the
fixture is too small and synthetic by design.

## 4. Limitations

Synthetic histories only; default predictor is a baseline (logreg bundle
wiring is a future integration task); engine decisions not re-invoked
(documented); RAG corpus is 2 fixture docs; live shadow architecture
documented but not built.

## 5. Status

Offline replay framework VALIDATED. Live shadow integration NOT started.
No state mutated at any point (in-memory only). Deployment: NO.
