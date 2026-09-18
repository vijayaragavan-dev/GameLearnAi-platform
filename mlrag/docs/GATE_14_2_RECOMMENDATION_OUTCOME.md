# GATE 14.2 — Recommendation Outcome v1 (OBSERVATIONAL DERIVATION)

> Pure read-only derivation from authoritative attempts. No writes, no
> persistence, no API, no migration. Language discipline enforced in
> code and docs: "post-recommendation outcome / observed association" —
> never "causal effect".

## 1. Objective

Determine whether measurable learner improvement followed a
recommendation, as observed association only.

## 2. Existing Recommendation Semantics (verified, not reinterpreted)

ACTIVE = current rec per (user,topic) (max one by policy);
CONSUMED = superseded by a newer rec (`AdaptiveLearningService:140-141`,
the SOLE write site) — never learner action, never success; EXPIRED =
no write site in main code (dead status, treated as inert). consumed_at
= supersede instant. No accepted/started/completed/success state exists.

## 3. Existing Mastery Semantics

`topic_mastery` is ONE row per (user,topic) UPDATED in place
(`persistMastery`), stamped `last_assessed_at` per submission. There is
NO mastery history table — pre/post mastery cannot be read from rows.
v1 therefore derives pre/post from authoritative attempt outcomes
(correct/total with submitted_at), reusing `AdaptiveEngine.accuracy`
(HALF_UP, scale 2). Engine calculation logic untouched.

## 4. V1 Outcome Definition

For rec R(user U, topic T, generated G): pre = attempts with
`submittedAt < G` (strict); post = `G < submittedAt ≤ nextG` where
nextG = next rec instant for (U,T), unbounded if none. Both sides need
≥1 COMPLETED attempt or the outcome is INSUFFICIENT_DATA (never
zero-filled). Delta = postAcc − preAcc; bands reuse engine
`TREND_DELTA` ±5.00: ≥+5 IMPROVED, ≤−5 DECLINED, else
NO_MEASURABLE_IMPROVEMENT. Same-instant duplicates → AMBIGUOUS.
NULL topic → INSUFFICIENT_DATA (TOPIC_NULL).

## 5. Derivation Logic

`RecommendationOutcomeService.deriveOutcome(userId, recId)`
(`@Transactional(readOnly=true)`): load → FORBIDDEN on ownership
mismatch / NOT_FOUND on unknown id → topic/sibling/window resolution →
single batched attempt load (`findCompletedForOutcome`: fetch-join
quiz+topic, ordered ASC, no N+1) → split → aggregate → categorize →
`RecommendationOutcome` record (unpersisted). New code: 1 service, 1
DTO record (+nested Category enum), 2 additive repository methods.

## 6–8. Point-in-Time / Topic / Learner Isolation

Strict `isBefore/isAfter` both sides; equal instants excluded (the
triggering attempt at nextG belongs to the old window only, never the
new pre-baseline — exactly-once attribution). Topic filter in-query;
NULL topic unattributable. userId explicit server-side; cross-learner
access throws FORBIDDEN (tested).

## 9. Multiple Recommendations

Post window bounded by the next rec instant for (U,T); latest rec
unbounded. Same-instant rows → AMBIGUOUS. Lifecycle untouched.

## 10. Consumed vs Success

Status is recorded in output, never mapped to outcome. CONSUMED recs
derive purely from attempt evidence (tested insufficient-without-post).

## 11. Outcome Taxonomy

IMPROVED / NO_MEASURABLE_IMPROVEMENT / DECLINED / INSUFFICIENT_DATA /
AMBIGUOUS — bands borrowed from engine semantics, documented as such.

## 12–13. Missing Data / Ambiguity

Missing pre → NO_PRE_BASELINE; missing post → NO_POST_OBSERVATION;
nulls preserved (no zero substitution); ambiguous cases named, never
split or fabricated.

## 14. Causality Limitation

Improvement may come from other lessons/quizzes/study/recs/exposure.
v1 reports observed association with `detail=OBSERVED_ASSOCIATION`.

## 15. ML Leakage Rules

Outcome rows carry `evaluatedAt` (= derivation instant). Future ML use
requires `outcome_timestamp < prediction_T`; valid only as evaluation
labels or temporally-valid training labels. Current Gate 4 numerics
untouched; no retraining; no promotion claim.

## 16. Security

Principal-derived IDs, FORBIDDEN on mismatch, no PII beyond IDs,
read-only transaction, no logging of learner payloads.

## 17. Performance

Two indexed reads (user/topic ordered recs; completed attempts with
fetch joins); no N+1 (verified by fetch-join queries); in-memory
linear scan over bounded windows. No index added (existing
user/topic/time FK indexes cover); no migration.

## 18. Tests

16/16 green (`RecommendationOutcomeServiceTest`): improvement,
no-change, decline, missing pre/post, topic isolation, learner
FORBIDDEN, unknown id, NULL topic, consumed≠success, supersede
bounding, same-instant ambiguity, strict ordering, future exclusion,
duplicate aggregation, write-nothing assertion.

## 19. Historical Data Policy

Derivation works on all history as-is; NULL-topic/legacy rows yield
INSUFFICIENT, never fabricated outcomes. No backfill, no rewrite.

## 20. Future Extensions

Explicit outcome events, lesson/path engagement joins, rec-ranking
labels (all later gates, all additive). Current DTO already carries
`evaluatedAt` + counts for that evolution.

## 21. Gate 14.2 Decision

**PASS** — observational v1 derived from authoritative data; taxonomy
honest; isolation enforced; zero behavior/schema/API change; 16 new
tests green; full regression pending below (recorded in gate report).
