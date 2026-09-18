# GATE 13 — Data & Learning-Signal Gap Analysis (DESIGN/AUDIT ONLY)

> No collection implemented, no schema changed, no code changed. Every
> claim below cites the committed schema/code or marks UNKNOWN. Measured
> values come only from prior read-only gates; nothing is re-measured
> from live data here.

## 1. Executive Summary

The system is **label-rich but signal-thin**: correctness/score labels
are authoritative and complete (56/56), while the behavioral signals
that would let ML beat deterministic baselines (think time, per-topic
repetition depth, recommendation outcomes, lesson/path engagement) are
absent or degenerate. Current HOLD is a data problem, not an algorithm
problem. Three P0 collection items (per-question timing, recommendation
outcome linkage, lesson/path engagement) plus organic data growth are
the complete path forward; everything else is P1 or lower. Eight
signal families must never be used (post-image state, untrusted game
skill, degenerate durations, PII/surveillance).

## 2. Current Data Inventory (selected signals; full table in §21)

| Signal | Source table.column | Type / gran. | TS | Authority | Missingness | Use | Leakage |
|---|---|---|---|---|---|---|---|
| question correctness | question_attempts.is_correct | bool / QUESTION | created_at | server | 0 (NOT NULL) | label | TARGET — never feature |
| selected answer | question_attempts.selected_answer | varchar NULL / QUESTION | created_at | client input | nullable (unanswered) | analysis only | POST (known at submit) |
| response time | question_attempts.response_time_seconds | int NULL / QUESTION | — | unwritten | 100% NULL (zero write sites) | none today | N/A (absent) |
| quiz score | quiz_attempts.score | decimal / QUIZ | submitted_at | server | 0 | label | TARGET |
| quiz duration | quiz_attempts.duration_seconds | int / QUIZ | submitted_at | server delta | 0 but degenerate (~0s) | none | UNSAFE (not think time) |
| difficulty at attempt | quiz_attempts.difficulty_at_attempt | enum / QUIZ | submitted_at | server (quiz copy) | 0 | feature | SAFE |
| question difficulty | questions.difficulty | enum / QUESTION | static | curated | 0 | feature/prior | SAFE |
| quiz difficulty | quizzes.difficulty | enum / QUIZ | static | curated | 0 | feature | SAFE |
| attempt counts | topic_mastery.attempt_count | int / TOPIC | last_assessed_at | server | 0 | feature iff pre-image | SAFE WHEN LAGGED |
| mastery score/level/trend/recent | topic_mastery.* | decimal/enum / TOPIC | last_assessed_at | server | 0 | feature iff pre-image | POST-IMAGE otherwise |
| recommendation | recommendations.* (no outcome col) | mixed / TOPIC | generated/consumed_at | server | 0 | prior-ACTIVE only | current row = POST |
| progress %/status/activity | progress.* | mixed / TOPIC | last_activity_at | server | nullable completed | ambiguous (see §12) | MIXED |
| path/nodes | learning_paths(_nodes).* | mixed / PATH | created_at | server | 0 | structural only | SAFE (no outcome yet) |
| game result fields | game_results.{game_type,completed,score,duration,best_combo,xp,played_at} | mixed / GAME | played_at | client-claimed + server xp/ts | 0 | engagement only | UNSAFE for skill |
| game difficulty/topic/correctness | — (not persisted) | — | — | — | 100% absent | none | N/A |
| XP/level | learner_profiles.total_xp/current_level; xp_transactions.* | int / USER | created_at | server | 0 | outcome/confounder | POST (derived from target) |
| streak/achievements | streaks.*; user_achievements.unlocked_at | mixed / USER | dates | server | 0 | engagement | POST/weak |
| subject/topic/quiz/question IDs | FK chain | uuid / all | static | server | 0 | keys/grouping | SAFE (not value features) |
| timestamps | submitted/generated/assessed/played/created | instant | — | server | 0 | recency/gaps | SAFE |

Observed coverage (prior read-only gates): 56 attempts (39/17, 69.64%),
5 learners, 5 days, HARD 0, recs 14 (5 consumed), timing 56/56 NULL.

## 3. Signal Granularity

USER (XP/level/streak/achievements — slow-moving outcomes, confounders
at question grain) · SESSION (not modeled: no session entity exists) ·
QUIZ (score/duration/difficulty — attempt labels + context) · QUESTION
ATTEMPT (correctness — the primary label; timings absent) · TOPIC
(mastery/attempt counts/recs — modeling grain for knowledge) ·
SUBJECT (catalog context, isolation boundary) · LESSON (content exists,
15 rows; completion NOT recorded) · LEARNING PATH (structure exists,
node-completion behavior NOT recorded) · GAME (self-reported events,
no skill grain) · RECOMMENDATION (generated/consumed present, success
absent) · ENGAGEMENT (plays/counts/dates — correlates, rarely causes).
Grain matters because aggregating upward leaks (quiz score contains the
target question) and downward invents precision (user XP ≠ topic skill).

## 4. Temporal Availability

BEFORE: IDs, difficulties (catalogue), prior mastery/counts/recent/
trend/difficulty, prior ACTIVE recs, timestamps/gaps of past events.
AFTER ONLY: correctness, score, selected answer, post-image mastery/
recs/progress, XP/level deltas, streak updates, achievements, game XP.
BOTH (with care): topic/quiz catalogues (static), streak *existence*
(prior value pre, updated value post — never mix). UNKNOWN: lesson
completion, abandonment, engagement depth (no columns at all).

## 5. Existing ML Feature Audit (f1, 11 modeled + history keys)

| Feature | Source | Status |
|---|---|---|
| hist_accuracy, recent_accuracy_k5, topic_hist_accuracy | attempt lineage, strict `< T` | STRONG (when history exists) / SPARSE today |
| prev_mastery_score | topic_mastery pre-image | STRONG but SPARSEST (audited All-NaN cause) |
| days_since_last_attempt | timestamp gaps | MEDIUM (5-day span limits meaning) |
| is_cold_start, topic_has_exposure | derived flags | RELIABLE (structural) |
| q/z_diff_medium/hard | catalogue one-hots | WEAK today (HARD 0 obs; MEDIUM 4) |
| IDs (user/topic/question/quiz) | FKs | grouping keys, excluded as values (memorization risk) |
| prev_trend, prior_rec_activity | pre-image state | RELIABLE definitionally, thin data |

No feature is POTENTIALLY LEAKY under the enforced `< T` + sibling
rules (proven by 28-area leakage suite + post-run audit). Weakness is
coverage, not correctness.

## 6. Missing Signal Analysis (16 candidates)

1. **Response time** — matters (effort/fluency/mastery proxy); not
   derivable (all NULL, never written); new collection required; ML
   HIGH, adaptive MEDIUM; complexity LOW (server timestamps);
   privacy LOW; leakage LOW if server-measured pre-submit. **P0.**
2. **Attempt timing (per-question think time)** — same as (1); needs
   client timestamps + server validation. **P0 (with 1).**
3. **Repeated attempts** — exists as rows (distinct-attempt design);
   usable now for learning curves. **P1 (analysis, no collection).**
4. **Recommendation exposure** — exists (ACTIVE rows, generated_at).
   Usable now. **P1.**
5. **Recommendation consumption** — exists (consumed_at). Partially usable.
   **P1.**
6. **Lesson completion** — absent entirely; needs event capture; HIGH
   adaptive value (path progression signal). **P1.**
7. **Path-node completion** — schema has status/completed_at on progress
   + node linkage, but population semantics unverified/probe-only;
   needs product definition before ML use. **P1 (define first).**
8. **Content engagement** (views, dwell) — absent; MEDIUM value, HIGHER
   privacy cost; collect minimally or not at all. **P2.**
9. **Difficulty transitions** — derivable from difficulty_at_attempt
   sequences now. **P1 (analysis).**
10. **Topic practice behavior** — derivable from attempt lineage now.
    **P1 (analysis).**
11. **Quiz abandonment** — NOT measurable (no started-without-submit
    marker; started_at==submitted_at degenerately). Needs start-event
    capture. **P2.**
12. **Game performance** — exists but untrusted/engagement-only. **P3
    for skill; P2 as engagement.**
13. **Game topic linkage** — absent (no columns). Requires
    server-validated linkage per game. **P2 (gated per game).**
14. **Game correctness linkage** — absent. Same gate as 13. **P2.**
15. **Improvement trend** — derivable (recent vs prior accuracy) now.
    **P1 (analysis).**
16. **Time since previous attempt** — exists (F-gap feature).
    Implemented. **Done.**

## 7. Response-Time Analysis

Column exists (`question_attempts.response_time_seconds`, nullable);
population 0% (56/56 NULL); zero write sites in current code (only the
entity setter definition); therefore neither server- nor client-derived
today — unwritten. Trustworthiness N/A. Historical reconstruction
IMPOSSIBLE (do not invent). Future safe design: server records
question-presented and answer-received instants (authoritative clock),
stores per-question seconds at submit, validates bounds (0..quiz limit),
never trusts client durations; keep NULL-able with explicit unknown
semantics. **P0.**

## 8. Quiz Duration Analysis

Verified in code (`QuizSubmissionService.java:114,127,141`):
`startedAt=Instant.now()` … `submittedAt=Instant.now()` inside one
`submit()` call → `duration_seconds` ≈ server execution delta (≈0s),
NOT learner think time. Non-null but semantically void → **UNSUITABLE
for ML** (exclude-listed; using it would train on server speed).

## 9. Game Signal Analysis

Persisted: game_type, completed, score, duration_seconds, best_combo
(all client-claimed, range-checked only), xp_awarded + played_at
(server). Request difficulty scales XP then is discarded
(`GameResultService.java:146-154,206`). Absent: subject/topic/
difficulty/correctness columns, per-question detail, server validation
against authoritative content. Classification: engagement SAFE;
adaptive signal INSUFFICIENT; mastery NOT SAFE (all 12 non-quiz games).
Quiz-family games (quiz_battle, speed_run) already contribute through
authoritative QUIZ-002 submission — confirmed by code path, the only
legitimate game→skill route. No retrofit without per-game
server-validated topic+difficulty+correctness.

## 10. Recommendation Signal Analysis

Present: generated_at (exposure), ACTIVE/CONSUMED status + consumed_at
(consumption), topic/activity/difficulty/priority/reason. Absent: any
outcome/success column. Rule: generated ≠ consumed ≠ successful.
Minimum future signal for "did it help": post-recommendation mastery
delta on the recommended topic within a bounded window (computable from
existing tables once volume exists — no schema needed for v1), later
optionally an explicit outcome event. Until then, rec-ranking ML stays
NOT READY.

## 11. Mastery Analysis

topic_mastery rows carry score/level/difficulty/attempt_count/
recent_accuracy/trend + last_assessed_at, written atomically with each
submission (assessment path initializes T01-mirror). Pre-event mastery
(full row with last_assessed_at < T) is reconstructible for every
attempt → safe lagged feature (current f1 use, audited). Post-event
values equal/contain the target → never features. Engine owns all
writes; ML only reads pre-images.

## 12. Progress Analysis

progress = per-(user,topic[,node]) completion_percentage/status/
last_activity_at/completed_at. Classification: AMBIGUOUS/INSUFFICIENT —
population semantics unverified in this gate (probe-only writes in
tests; product write sites need a dedicated audit before ML use).
Pre-event snapshots would be usable once semantics are pinned; until
then: do not model on progress. No new semantics introduced here.

## 13. Learning-Path Analysis

Structure (paths/nodes/sequence/required_mastery/status) exists and is
safe as eligibility context (catalog-like). Behavior (node completion
order/timing/current pointer) is not reliably populated → no outcome
modeling on paths yet. Rule: paths constrain candidates; never serve as
labels until completion semantics are verified.

## 14. Engagement Analysis

Streaks/XP/achievements/plays/counts: legitimate ENGAGEMENT signals and
product outcomes; as ML inputs they are mostly POST-event or
confounders (XP derives from the very scores being predicted). Allowed:
prior values as coarse activity priors (low weight, documented). Never:
current values as features. Never feed every engagement variable in —
each needs a causal story (prior activity → preparedness), else it is
a confounder.

## 15. Data Quality

Labels (correctness/score): HIGH (server-computed, complete).
Difficulties/catalogue: HIGH. Pre-image mastery: MEDIUM (correct but
sparse). Timestamps: MEDIUM (ordering fine; same-T siblings need
exclusion discipline). Durations: LOW (semantically void). Response
times: absent (not LOW — nonexistent). Game skill fields: LOW
(untrusted). Rec outcomes: absent. Coverage overall: LOW (56 rows).
Bias note: 69.6% positive + EASY-heavy + 5 learners — any model inherits
these biases; report, don't correct, at this size.

## 16. Learning Value

VERY HIGH: per-question think time (effort/flux signal nothing else
captures), rec-outcome linkage (closes the adaptive loop). HIGH:
repeated-attempt curves, difficulty-transition responses, lesson/path
completion (ground progression in behavior). MEDIUM: abandonment,
engagement depth, game linkage (niche or costly). LOW: raw durations,
XP-as-feature, achievements-as-feature (post-event echoes). UNKNOWN:
anything requiring population scale (transfer, forgetting curves).

## 17. Privacy

Timing/attempt/curriculum signals: LOW risk (learning behavior,
already first-party). Engagement depth/dwell: MEDIUM (minimize:
aggregate or skip). PII (passwords, tokens, email, precise location,
keystrokes, device data): NEVER — no ML value, violates minimization;
the system needs surrogate keys + counts + curriculum IDs only.
Retention: raw per-question timings age out to aggregates; audit rows
keep counts, never payloads.

## 18. Leakage Risk

SAFE: catalogue data, IDs-as-keys, pre-image state, prior aggregates.
SAFE WHEN LAGGED: mastery, attempt counts, recent accuracy, trend,
recommendation state, XP/streak priors. POST-EVENT ONLY: correctness,
score, selections, post-image anything, current rec row, XP/level
deltas, achievements, game XP. HIGH RISK: quiz score as a feature for
its own questions, duration-as-think-time, game-score-as-skill,
rec-generated-as-success. UNKNOWN: progress semantics (quarantined
until verified).

## 19. Future Data Collection Design (P0 only sketched; nothing built)

(a) Per-question timing: event=question presented/answered;
fields=question_attempt_id, presented_at, answered_at (server clock),
response_seconds (validated 0..limit); captured at submit within the
existing transaction; retention raw 90d→aggregates; ML=effort feature;
adaptive=confidence/fluency signal; leakage-safe by construction
(pre-submit instants). (b) Recommendation outcome: no new event v1 —
join rec (generated_at, topic) → later mastery delta in-window
(design; needs volume). (c) Lesson/path engagement: lesson-view +
node-transition events with server timestamps (product-gated).

## 20. Minimum Viable Learning Dataset

TIER 1 ESSENTIAL: authoritative correctness/score labels (have) +
pre-image mastery/counts (have) + per-question think time (collect) +
rec→outcome joinability (have tables, need volume) + attempt timestamps
(have). TIER 2 HIGH VALUE: lesson/node completion events, difficulty-
transition histories, abandonment markers, per-game validated linkage.
TIER 3 OPTIONAL: engagement depth, streak-context priors, content dwell
aggregates. TIER 4 DO NOT COLLECT: PII/credentials/tokens, keystrokes,
location, device data, raw client durations, surveillance telemetry.

## 21. Signal Priority Table

| Signal | Existing/Missing | Value | Leakage | Privacy | Complexity | Priority |
|---|---|---|---|---|---|---|
| per-question think time | Missing | VERY HIGH | LOW (server) | LOW | LOW | P0 |
| rec→mastery outcome join | Missing volume | VERY HIGH | LOW (design) | LOW | LOW | P0 |
| lesson/path completion events | Missing | HIGH | LOW | LOW | MEDIUM | P0* (*product-gated) |
| repeated-attempt curves | Existing | HIGH | SAFE | LOW | LOW (analysis) | P1 |
| difficulty transitions | Existing | HIGH | SAFE | LOW | LOW (analysis) | P1 |
| topic practice behavior | Existing | HIGH | SAFE | LOW | LOW (analysis) | P1 |
| improvement trend | Existing | MEDIUM | SAFE | LOW | LOW (analysis) | P1 |
| rec exposure/consumption | Existing | MEDIUM | SAFE (prior only) | LOW | LOW | P1 |
| abandonment markers | Missing | MEDIUM | LOW | LOW | MEDIUM | P2 |
| engagement depth | Missing | MEDIUM | LOW | MEDIUM | MEDIUM | P2 |
| validated game linkage | Missing | MEDIUM | MEDIUM | LOW | HIGH | P2 |
| XP/streak as features | Existing | LOW | HIGH if current | LOW | LOW | P3 (priors only) |
| raw durations | Existing | LOW | HIGH (void) | LOW | — | P3 (exclude) |
| game skill labels | Missing/untrusted | LOW | HIGH | LOW | HIGH | P3 (exclude) |
| PII/surveillance | — | NONE | — | HIGH | — | P3 (never) |

## 22. Signals Not to Collect

Passwords/tokens/emails/location/keystrokes/device data/raw client
durations: zero adaptive value, violate minimization, expand breach
blast radius, and (for client durations) are gameable. GameLearnAI
adapts on *what the learner knows*, not *who they are or how they
type* — surveillance telemetry would poison trust and the model
(client-controlled inputs become attack surfaces, not signals).

## 23. ML Feature Roadmap

CURRENT (f1, frozen): history/recent/topic accuracies, prev mastery,
time gaps, cold/exposure flags, difficulty one-hots. NEXT (on P0
arrival): think-time + think-time-vs-topic-norm, rec-outcome delta
features, lesson-completion priors. LATER (needs population):
forgetting-curve terms, cross-topic transfer, difficulty-response
slopes. DEFERRED: game-skill embeddings, engagement-depth factors,
anything requiring N≫100 learners.

## 24. Data Growth Plan

Growth comes only from real product use: quiz/question attempts (labels
+ histories), assessment baselines, rec exposures → consumptions →
mastery deltas, lesson/path engagement once captured, validated game
outcomes per linked game. No synthetic rows ever counted as evidence;
no artificial learners; backfill NOTHING historically (NULLs stay
NULL — imputation is a modeling-time, train-fold-only operation, never
a data rewrite).

## 25. Model Re-evaluation Trigger

Per Gate 5 provisional bars (referenced, not reinvented): ≥50 learners,
≥5000 attempts, ≥60 active dates, ≥10 per-learner depth, both classes,
plus new-signal coverage (think-time populated, rec-outcome pairs
sufficient for ranking eval). Below ALL bars: no re-tune, no
re-selection — the current logreg-vs-baselines verdict stands.

## 26. RAG Relationship

Learner data answers WHAT the learner needs (mastery gaps, trends);
the corpus answers WHAT knowledge addresses it (lessons/explanations).
Never merge: no learner IDs, histories, or PII in RAG documents;
retrieval scope may *use* the learner's topic as a filter key but must
never *store* learner state. Corpus growth (more lessons/explanations)
is independent of learner-data growth.

## 27. AdaptiveEngine Relationship

Signals → ML advisory → Decision Layer → AdaptiveEngine → authoritative
decision → persistence. Collection adds evidence to the first arrow
only; it never reorders, bypasses, or rewrites the chain. Engine rules,
thresholds, and cold-start defaults remain the final word regardless of
how rich the signals become.

## 28. Final Recommendations

1. Collect P0 think-time + lesson/path engagement (product-gated),
   nothing else new. 2. Mine existing lineage now (P1 analyses need no
   collection). 3. Treat rec-outcome join as the loop-closing metric and
   grow it organically. 4. Quarantine progress semantics until verified.
   5. Never touch game-mastery, durations-as-signal, PII/surveillance.
   6. Re-evaluate only at Gate 5 bars. 7. Keep NULLs NULL historically.

## 29. Gate 13 Decision

**PASS** — inventory complete, gaps named, leakage/privacy analyzed,
P0/P1/P2/P3 set, minimum dataset defined, roadmap/trigger set, zero
implementation (doc + guard tests only), suites green.
