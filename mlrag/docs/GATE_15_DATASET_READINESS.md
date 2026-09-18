# GATE 15 — Dataset Readiness (EVIDENCE GATE; LIVE MEASUREMENT BLOCKED)

> Read-only channel absent in this session (all MLRAG_DB_* unset;
> verified booleans only). NOTHING below is re-measured from live data.
> Last-known real baseline (Gate 4-era, explicitly dated, not refreshed):
> 56 attempts / 5 learners / 5 days / 39-17 (69.64%) / timing 0% /
> HARD 0 / recs exposure-only. All verdicts follow from that baseline
> plus unchanged code.

## 1. Executive Summary

**NOT READY.** No live re-measurement possible; last-known data fails
every Gate 5 volume bar by 1–2 orders of magnitude; think-time and
rec-outcome collection paths exist in code but their live coverage is
unobservable from here. Accumulation, not analysis, is the critical
path.

## 2. Current Real Dataset

LIVE DATA MEASUREMENT BLOCKED. Carried-forward baseline (Gate 4,
labeled as such, NOT re-measured): 56 question attempts, 5 learners,
5 active dates, 39 correct / 17 incorrect (69.64%), topics ≤9 active
pairs, subjects ≤11 catalog, difficulties EASY-heavy/MEDIUM 4/HARD 0,
per-learner depth max bucket 21–50 with 35/40 learners at zero (prior
full-population count), response times 56/56 NULL, recs 14 rows
exposure-only, mastery in-place (no snapshots), lesson/path engagement
absent.

## 3. Baseline Comparison

No growth measurable (no channel). Assumption for planning: baseline
unchanged. Any newly accumulated history is strictly additive
(append-only attempts/events; no rewrites by design).

## 4. Data Growth

UNMEASURED (blocked). Growth vectors, when observable: attempt/learner/
date/topic/difficulty counts, repeated-pair counts, think-time
non-null counts, rec-outcome derivable counts.

## 5. Think-Time Coverage

Unmeasurable live. Method defined for the re-measurement run:
`COUNT(*)`, `COUNT(response_time_seconds)`, coverage %, invalid
(`<0`), distribution — split historical-NULL (all pre-14.1 rows) vs
post-14.1 rows. Semantic limitation preserved: quiz-level dwell
attributed per row until per-question presentation events exist.

## 6. Recommendation Outcome Coverage

Unmeasurable live. Method: run `deriveOutcome` per rec; tally the five
categories. INSUFFICIENT_DATA is missing-evidence, never a negative
outcome; CONSUMED never success; causality never claimed.

## 7. ML Feature Coverage

f1 schema unchanged (verified: no feature-code diffs since Gate 11).
Missingness characterization stands (history-backed numerics partial,
prev_mastery sparsest). No retraining, no schema change in this gate.

## 8. Leakage Audit

Re-verified by code + green suites (no ML file modified since Gate 11):
strict `< T`, sibling exclusion, future exclusion, target/ledger
separation, outcome-as-label-only discipline, think-time row-N rule,
surrogate identities. No defect found; none fixed.

## 9. Data Quality

Completeness: labels complete; behavior thin. Consistency: server
timestamps authoritative. Duplicates: independent-attempt semantics
retained. Sparsity/difficulty/outcome imbalance: as baseline (biased,
reported, uncorrected). Timestamp quality: submit-receipt reliable;
delivery instants post-14.1 only.

## 10. Data Diversity

Per baseline: tiny learner/topic set dominates; difficulty concentrated
EASY; temporal span 5 days. No change claimable.

## 11. Baseline Comparability

A/B/C definitions frozen; served-row parity harness intact (tested);
comparison valid whenever data flows again.

## 12. Gate 5 Policy Assessment (provisional bars, unmodified)

50 learners: NOT MET (5). 5000 rows: NOT MET (56). 60 days: NOT MET
(5). 10/learner: NOT MET (majority ≤5). 200 calibration N: NOT MET
(56). ≤0.05 bias: NOT MET (top-bin +0.27). Zero bars met; promotion
requires all.

## 13. Existing ML Evidence (carried, not hidden)

Logreg loses to B/C pooled (ll/Brier/ROC); ROC 0.376 < random;
overconfident; deployment_ready=false. No new data justifies
re-evaluation: **NOT READY** stands.

## 14. Remaining Data Gaps

Volume (all bars), think-time coverage (unobserved), rec-outcome pairs
(unobserved), HARD/difficulty spread, temporal span, per-learner depth,
lesson/path semantics (product-gated), human RAG judgments.

## 15. Lesson/Path Condition

Unchanged from 14.3: product semantics required before collection;
missing telemetry is a product dependency, never a fabrication license.

## 16. RAG Relationship

Independent track: Gate 7 lexical standing, weak labels, no human
judgments. Learner-data growth does not promote RAG; relevance
evidence is the RAG gate, not row counts.

## 17. Shadow Readiness

Mechanics proven (Gates 9/10 tests); meaningful live shadow needs real
traffic volume + channel — neither present. Kill switches untouched.

## 18. Privacy

No new collection in this gate; P0 designs minimize to IDs+timestamps;
surveillance categories remain excluded (guard-tested).

## 19. Real vs Synthetic Separation

Fixtures validate frameworks only (test suites); real metrics contain
zero synthetic rows by construction (extraction reads committed rows;
guard test asserts the separation predicate on payload builders).

## 20. Required Future Accumulation

Real quizzes/assessments (labels+histories), think-time rows (post-14.1
traffic), rec exposures→consumptions→mastery deltas, lesson/path events
once product-defined, validated game outcomes per linked game. Organic
only; backfill nothing.

## 21. Re-evaluation Trigger

Gate 5 bars (referenced, not reinvented): all six met + think-time
coverage sufficient + rec-outcome pairs sufficient + refreshed
calibration. Below that: no re-tune, current verdicts stand.

## 22. Gate 15 Decision

**NOT READY** — blocked measurement + failed bars + unchanged negative
ML evidence. Next: GATE 16 re-evaluation ONLY when §21 conditions are
observably met.
