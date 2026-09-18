# GATE 15.1 — Live Data Measurement (LIVE, READ-ONLY, 2026-09-13)

> ## Execution record — 2026-09-13T16:17:02Z (live measurement SUCCEEDED)
>
> Channel RESTORED in this session via the specified `MLRAG_DB_*` variables.
> Naming note (no source change): this session carries `MLRAG_DB_NAME` /
> `MLRAG_DB_USER`, while `mlrag/experiment/db.py:70-78` requires
> `MLRAG_DB_DATABASE` / `MLRAG_DB_USERNAME`. The measurement harness aliased
> the two names in process memory only (`os.environ`, no file edit, no
> credential output) and then reused `db.connect()` / `db.run_select()`
> unchanged, including the `gamelearn_ro` identity assertion and the
> SELECT-only statement guard. Prior blocked-run records are superseded by
> the live evidence below; nothing below is fabricated, estimated, or
> carried forward except where explicitly labeled HISTORICAL or
> CARRIED-FORWARD.
>
> Previous blocked-run notes (kept for audit, no longer operative):
> earlier sessions reported all `MLRAG_DB_*` absent from the agent process
> scope and could execute zero queries.

## 1. Objective

Restore the read-only measurement channel and refresh aggregate evidence.
Outcome: channel RESTORED → measurement LIVE → decision NOT READY (data).
No implementation, no fabrication, no credentials handled.

## 2. Read-Only Channel Status

**READ-ONLY CHANNEL RESTORED — LIVE MEASUREMENT EXECUTED.**
`experiment/db.py` guards enforced end-to-end: credentials from process
`MLRAG_DB_*` env only; identity asserted to `gamelearn_ro`; every
statement passed the SELECT/SHOW-only single-statement guard with
dangerous keywords rejected. Zero writes issued; no credential, token,
email, name, or password column ever selected.

## 3. Database Identity Verification

LIVE, without credentials (values never read or printed):

- `SELECT DATABASE(), CURRENT_USER()` → `gamelearn` / `gamelearn_ro@127.0.0.1`.
- `SHOW GRANTS` → `GRANT USAGE ON *.*` + `GRANT SELECT ON gamelearn.*`
  (SELECT-only; no INSERT/UPDATE/DELETE/ALTER/DROP/CREATE present).
- Any deviation would have aborted measurement; none observed.

## 4. Current Real Dataset (LIVE)

| Metric (LIVE) | Value |
|---|---|
| users | 40 |
| quiz_attempts | 14 (all COMPLETED) |
| learners with quiz attempts | 5 |
| question_attempts | 56 |
| correct / incorrect | 39 / 17 |
| overall accuracy | 69.64% |
| learners with question attempts | 5 |
| earliest / latest question-attempt `created_at` | 2026-08-26 07:41:44 / 2026-09-04 13:22:12 |
| earliest / latest quiz `submitted_at` | 2026-08-26 07:41:44 / 2026-09-04 13:22:12 |
| active dates (both grains) | 5 |

## 5. Growth Since Gate 4 (LIVE vs HISTORICAL BASELINE)

HISTORICAL BASELINE (Gate 4-era): 56 attempts / 5 learners / 5 days /
39-17 (69.64%) / timing 0% non-null.
LIVE (this run): identical on every volume cell — **growth +0 attempts,
+0 learners, +0 days**. The dataset is unchanged since the baseline;
accumulation has not yet begun. (Additivity assumption from Gate 15
stands but is untested by new rows: zero new rows observed.)

## 6. Think-Time Coverage (LIVE)

`question_attempts.response_time_seconds`: total 56 / non-null **0** /
NULL 56 / coverage **0.0%**. No min/max/avg (empty non-null set);
negatives 0; zeros 0. Historical NULL rows unaltered (no writes exist
in this gate). Think-time collection remains code-ready, evidence-empty.

## 7. Recommendation Outcome Coverage (LIVE derivation, Gate 14.2 semantics)

Lifecycle (status, LIVE): 14 recommendations / 5 learners /
ACTIVE 9 / CONSUMED 5 / EXPIRED 0 / topic-NULL 0 /
generated 2026-08-26–2026-09-04. CONSUMED = superseded by a newer rec,
never learner success (semantics preserved).

Outcome derivation (LIVE, Python mirror of
`RecommendationOutcomeService.deriveOutcome`: sibling window
`(G, nextG]`, strict pre `< G`, COMPLETED attempts only, ±5.00pp bands,
observed-association language): IMPROVED **1** /
NO_MEASURABLE_IMPROVEMENT **0** / DECLINED **3** /
INSUFFICIENT_DATA **10** (NO_PRE_BASELINE 9, NO_POST_OBSERVATION 1) /
AMBIGUOUS **0**. INSUFFICIENT is missing-evidence, never a negative
outcome; association is never claimed as causation.

## 8–11. Temporal / Diversity / Difficulty / Topic Coverage (LIVE)

- Temporal: 5 active dates over 2026-08-26–2026-09-04 (span 10 calendar days).
- Difficulty catalog (LIVE): questions EASY 88 / MEDIUM 131 / HARD 15;
  quizzes EASY 26 / MEDIUM 42 / HARD 5. Observed attempts: EASY 52 /
  MEDIUM 4 / **HARD 0** — still zero HARD exposure.
- Learner depth (LIVE question attempts per learner): min 4 / max 28 /
  mean 11.2 / median 8; ≥2: 5/5, ≥5: 3/5, ≥10: 2/5. Full-population
  buckets (40 users): 0:35 / 1:0 / 2–4:2 / 5–9:1 / 10–20:1 / 21–50:1.
  Quiz attempts per learner: {3, 7, 1, 1, 2}.
- Topic/subject exposure (LIVE): 9 learner-topic pairs (all repeated,
  sizes 4–24, mean 6.2); 5 distinct topics / 3 distinct subjects with
  attempts. Catalog ≠ exposure separation preserved.

## 12. ML Feature Coverage

f1 schema unchanged (no feature-code diffs since Gate 11; this gate
touches no source). Live build: 56 rows / 5 learners, served (≥3 priors)
36 rows; tier `feasibility_only`. Missingness characterization stands
(history-backed numerics partial, prev_mastery sparsest). No retraining,
no schema change in this gate.

## 13. Leakage Verification

Re-verified by code + green suites (no ML file modified in this gate):
strict `< T`, sibling exclusion, future exclusion, target/ledger
separation, outcome-as-label-only, think-time row-N rule, surrogate
identities. Live re-evaluation below reused the identical pipeline
(extract → build_rows → LOLO + temporal → A/B/C → calibration). No
defect; nothing fixed.

## 14. Gate 5 Assessment (LIVE vs unchanged provisional bars)

| Bar | LIVE | Verdict | Gap |
|---|---|---|---|
| 50 learners | 5 | NOT MET | −45 |
| 5000 rows | 56 | NOT MET | −4,944 |
| 60 days | 5 | NOT MET | −55 |
| 10/learner (min) | 4 (2/5 ≥ 10) | NOT MET | 3/5 learners short |
| 200 calibration N | 56 | NOT MET | −144 |
| ≤0.05 bias | +0.153 (live cal.) | NOT MET | overconfident |

**0 of 6 bars met.** Bars unmodified.

## 15. ML Re-evaluation (LIVE, in-memory, same methodology/contracts)

Reran live 2026-09-13T16:17Z via existing modules only (no artifact
overwrite — `mlrag/artifacts/gate4_results.json` untouched; no promotion):

- Pooled LOLO (n=56): model log_loss 0.856 / Brier 0.274 / acc 0.696 /
  ROC-AUC **0.376** / PR-AUC 0.724.
- Baselines same served rows: A 0.858/0.290/ROC 0.213; B 0.580/0.207/ROC
  0.624; C 0.574/0.204/ROC 0.657. Model beats A on ll/Brier only and
  **loses to B/C on every pooled metric** (ll/Brier/ROC/PR).
- Calibration (56): overall bias **+0.153 overconfident**, worst-bin
  +0.273; bins <0.6 empty.
- Temporal holdout feasible but trivial (train 48 / valid 4 / test 4;
  rank metrics null on n=4 single-class partitions).
- Sufficiency tier: `feasibility_only` (no blockers to *running*, all
  blockers to *trusting*). Promotion policy: **deployment_ready=false**,
  unchanged. The model remains a feasibility signal, not a candidate.

## 16–17. RAG / Lesson-Path Relationship (CARRIED-FORWARD + LIVE context)

RAG metrics NOT re-measured (no safe rerun triggered by zero learner-data
growth; lexical system untouched by design): CARRIED-FORWARD Gate 7/11 —
413 documents / 483 weak-label queries / R@1 0.108 / R@10 0.616 / P@1
0.484 / MRR 0.666 / 0 scope violations / 0 human relevance judgments.

Lesson/path (LIVE): lessons 15; learning_paths 40 (ACTIVE 39, ARCHIVED 1);
path_nodes 153 (AVAILABLE 40, LOCKED 113); progress rows 0. No
viewed/started/completed/abandoned event table exists — completion is
NOT inferable from GET/read flows per Gate 14.3; no telemetry created.
Learner-data growth alone promotes neither RAG nor lesson/path.

## 18. Real vs Synthetic Separation

Enforced: extraction read committed live rows only; live payload
fidelity confirmed (56-row snapshot reproduces the Gate 4 baseline
exactly); fixtures validate frameworks only. Zero synthetic rows in
live metrics.

## 19. Remaining Evidence (for the next gate)

Sustained organic accumulation to all six §14 bars, plus think-time
non-null coverage on post-14.1 traffic, plus rec-outcome derivable pairs
beyond today's 4/14, plus refreshed calibration with bias ≤0.05, plus
HARD/difficulty spread and temporal span. Then and only then Gate 16.

## 20. Gate 15.1 Decision

**NOT READY (measured, channel restored).** Live data is real but
identical to the failing baseline (0/6 Gate 5 bars; model loses to B/C;
think-time 0%; HARD 0; outcomes 10/14 insufficient). The project remains
in legitimate real-data accumulation. Gate 16 requires §19 evidence —
NOT merely a working connection.
