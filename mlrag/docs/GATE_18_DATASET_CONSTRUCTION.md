# GATE 18 — Dataset Construction and Dataset Quality (IMPLEMENTATION GATE)

> Status: PASS (engineering). Data readiness: NOT READY (expected; see §14).
> No model trained, tuned, promoted, or integrated. No synthetic data.
> MySQL read-only (SELECT only). No commits or pushes. Backend untouched
> (zero delta vs pre-gate `git status`/`git diff --stat` baseline).

## 1. Implementation summary

New sidecar package `mlrag/dataset/` consumes Gate 17 feature rows from
`mlrag/feature_pipeline/` (authoritative; never duplicated, never the old
`mlrag/experiment/` code) and produces a deterministic, versioned dataset
(`dataset_version = d1` over frozen `feature_version = f1`): one row per
eligible question attempt, exact 19-column X, target `is_correct` stored
beside X, NULLs preserved with no imputation, deterministic
`user_aware_time_aware` splitting (whole learners, first-activity ordered,
no RNG), full quality/missingness/target/identity audits, PII-free live
artifact, and Gate-5 readiness evaluation (thresholds unmodified).

## 2. Files created/modified

Created (all inside `mlrag/`; zero backend/frontend/config/schema changes):

- `mlrag/dataset/__init__.py` — package boundary docs
- `mlrag/dataset/contract.py` — d1 contract: versions, `derive_row_id`
  (`datarow_<sha12(domain + question_attempt_id)>`), exact row schema,
  prohibited-content lists, `validate_dataset_row`, artifact scan
- `mlrag/dataset/build.py` — construction from Gate 17 rows (quarantined
  post-attempt scores dropped, explicit rejections) + deterministic
  `fingerprint_dataset` (sha256 over canonical versions + ordered rows)
- `mlrag/dataset/split.py` — deterministic learner-grouped time-ordered
  split (70/15/15, first learner pinned to train), overlap reporting,
  per-split usability verdicts, `SplitPolicy` reuse from
  `mlrag.contracts.evaluation`
- `mlrag/dataset/quality.py` — audit, missingness, target, identity, PII
  scan, Gate-5 readiness (bars frozen)
- `mlrag/dataset/snapshot.py` — live runner reusing Gate 17 read-only
  extraction/builder; prints PII-free summary; `--out` writes artifact
- `mlrag/tests/test_gate18_dataset.py` (22 tests), `mlrag/tests/test_gate18_split.py`
  (15 tests)
- `mlrag/artifacts/gate18_dataset.json` — 60-row PII-free live dataset
  (safety scan: 0 hits)

Modified: none outside `mlrag/`. No existing test modified.

## 3. Dataset contract

`dataset_version = d1`, `feature_version = f1`, `target = is_correct`.
Row keys (exact set, enforced): `row_id`, `learner_key` (surrogate),
`topic_id`, `subject_id`, `question_id`, `quiz_id`, `quiz_attempt_id`,
`question_attempt_id`, `feature_version`, `dataset_version`,
`data_version`, `predicted_at`, `features` (exactly the 19 f1 columns),
`is_correct` (0/1), `split`. Target never in X (structural + blocklist
checks). Prohibited from rows and artifacts: post-attempt scores/answers,
game/XP/streak/progress fields, emails, passwords, JWTs, raw `user_id`,
`selected_answer`, `duration_seconds`, `response_time_seconds`.

## 4. Dataset construction methodology

Consume validated Gate 17 rows → re-sort `(predicted_at,
quiz_attempt_id, question_attempt_id)` → derive `row_id` → validate each
row (failures become explicit rejections with reasons, never silent drops)
→ fingerprint. Gate 17 `provenance.quarantined_post_attempt` (quiz scores)
is deliberately NOT carried: persisted datasets contain zero post-attempt
values. NULLs preserved feature-for-feature (tested); known zeros
(`prior_*_count == 0`) and `is_cold_start`/`timing_known` stay explicit.

## 5. Dataset split methodology

`user_aware_time_aware`: learners ordered by `(first predicted_at,
learner_key)`; whole learners assigned to earliest unfilled split
(train 70% / validation 15% / test remainder; first learner pinned to
train); cutoffs `training_end_iso`/`validation_end_iso` derived as split
maxima; a real `SplitPolicy` is constructed when cutoffs exist and are
ordered. No RNG anywhere (source-scanned by test). Targets never read
(flip-all-targets test leaves assignment unchanged). Same-T siblings
co-located via user isolation (tested). Row-level train/val time overlap is
REPORTED, not forced — forcing it would split learners or drop rows (both
forbidden); user isolation takes precedence and the usability verdict
accounts for overlap. Fixed usability rule per split: ≥10 rows, ≥2
learners, both classes, no overlap with an earlier split.

## 6. Data quality statistics (live, N=60)

Rows 60; learners 6; topics 5; quizzes 5; questions 20;
2026-08-26T07:41:44 → 2026-09-14T06:07:18 (18.93 days);
positives 43 / negatives 17 (0.7167 / 0.2833); invalid targets 0;
cold-start 24 (0.40); timing_known 0; mastery pre-image 0;
question difficulty EASY 56 / MEDIUM 4 (quiz identical);
attempts/learner {4,4,4,8,12,28}; invalid rows 0; rejected 0 (no reasons).
Split: train 52 rows / 4 learners (usable), validation 8 / 2 (unusable:
<10 rows + overlaps train), test 0 / 0 (empty, honestly reported).
Learner first-activity order preserved: true. Train/val row overlap:
true (reported). `SplitPolicy` constructed: true
(train_end 2026-09-04 < val_end 2026-09-14, user_isolation true).

## 7. Missingness statistics (live, N=60)

`hist_accuracy`/`recent_accuracy_k5`/`days_since_last_attempt`: 24 NULL
(0.40, cold-start); `topic_hist_accuracy`: 40 NULL (0.667);
`prev_mastery_*` (5 fields): 60 NULL (1.0 — in-place mastery destroys
pre-images; honest NULL+flag per Gate 17 §4); `prev_response_time_norm`:
60 NULL (1.0 — no usable prior timing); counts/flags/difficulties/sequence:
0 NULL. Semantics preserved: NULL = unknown/structurally unavailable;
known zeros and cold-start flags explicit; no imputation.

## 8. Target distribution

`is_correct`: 43 ones, 17 zeros; rates 0.7167/0.2833; invalid values: none.
Independence probe (test): flipping only the terminal row's label leaves
ALL feature vectors byte-identical; X key-set equals frozen f1 on every
row; target absent from X on every row.

## 9. Duplicate/identity audit

60 rows / 60 unique `row_id`s / 0 duplicate identities / 0 duplicate
question-attempt ids / 0 exact-duplicate rows → identity PASS. Artifact
safety scan (email/JWT/password/token/user_id/selected_answer/score
patterns): 0 hits → safety PASS (72,266 bytes).

## 10. Versioning/fingerprint results

`dataset_version = d1`, `feature_version = f1`,
`data_version = snapshot-v1:qa60:qz15:lr6:2026-08-26T07:41:44:2026-09-14T06:07:18:shab7db1508d17b`,
fingerprint `d770dc35138d2d87ae0d4a910f91e54e42e6f03e4540029a9a7ddc1c07195241`
(sha256 over canonical versions + ordered rows; no wall-clock, no UUIDs).

## 11. Determinism/reproducibility results

A. Same-process rebuild: identical (PASS). B. Independent-process rerun:
same fingerprint + byte-identical artifact (PASS). C. Shuffled source
input: identical dataset (PASS). Row ordering, identities, statistics,
version, fingerprint all stable.

## 12. Leakage/split test results

37 new tests PASS: target-not-in-X (structural + flip probes),
future-timestamp discipline (prefix X byte-identical with/without future
rows), user-isolation absoluteness, first-activity ordering, same-T
co-location, deterministic/no-RNG splitting, NULL preservation, empty-split
honesty, PII/prohibited-content detection, contract + version consistency.
All 65 Gate 17 tests still PASS unmodified.

## 13. Live snapshot results

`python -m mlrag.dataset.snapshot --out mlrag/artifacts/gate18_dataset.json`
against current MySQL (read-only): 60/60 rows built, 0 rejections,
in-process parity PASS, artifact safety PASS. No PII (counts-only learner
reporting in stdout summary).

## 14. Data readiness evaluation (Gate-5 bars, unmodified)

learners ≥50: 6 FAIL · rows ≥5000: 60 FAIL · span ≥60d: 18.93 FAIL ·
min/learner ≥10: 4 FAIL · calibration rows ≥200: 60 FAIL ·
bias ≤0.05: 0.2167 FAIL (|pos_rate−0.5| proxy; true calibration needs a
model). DATASET ENGINEERING: PASS. DATA READINESS: NOT READY (expected).

## 15. Performance

60 rows in ~0.056 s → ~1,056 rows/s; peak ~598 KB (tracemalloc, includes
extraction). No optimization needed.

## 16. Test suite results

`python -m pytest mlrag/tests`: **334 passed, 0 failed, 0 errors**
(297 pre-existing + 37 new). No existing test modified.

## 17. Backend protection result

Pre-gate vs post-gate `git status --short` and `git diff --stat`:
**zero delta**. No backend source/config, no `.env`/`.env.example`, no
Flyway, no frontend, no schema, no DB writes (SELECT-only validated path).

## 18. Known limitations

- Mastery pre-image structurally 0% (in-place schema); timing history 0%;
  difficulty concentrated EASY; single-topic quizzes; 6 active learners.
- Validation split (8 rows, overlaps train) and test split (empty) are
  statistically unusable — mechanism correct, data insufficient.
- Bias bar uses a no-model proxy; calibration proper needs a later gate.
- MySQL TIMESTAMP is second-precision (equal-second ties share prior sets).

## 19. Final verdict

DATASET PIPELINE IMPLEMENTED: YES
DATASET CONTRACT: PASS
DATA QUALITY: PASS
LEAKAGE/SPLIT TESTS: PASS
DETERMINISM: PASS
LIVE SNAPSHOT: PASS
BACKEND PROTECTED: YES
DATA READINESS: NOT READY
GATE 18: PASS
