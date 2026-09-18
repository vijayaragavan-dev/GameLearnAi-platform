# GATE 14.0 — Safe Learning-Signal Implementation Design (DESIGN ONLY)

> Nothing built, migrated, or modified. All class/method/line claims
> verified read-only on the current tree. New work, if approved, is
> additive and kill-switched; existing behavior must survive NULLs.

## 1. Executive Summary

Three of five P0/P1 tracks need NO schema change (derivations +
rec-outcome join design); think-time needs one NULLABLE column +
validated write path; lesson/path engagement needs product-gated event
capture (smallest viable: lesson-view + node-transition records or a
narrow event table — decision owned by Gate 14.1+). Two load-bearing
corrections to prior gate language: (a) `CONSUMED` recommendations are
system-superseded, never learner-consumed (`AdaptiveLearningService.
java:140-141` is the sole write site); (b) `progress` rows are never
written by any service (repository is read-only in production code) —
progress semantics must be defined before any ML use.

## 2. Gate 13 Inputs

P0: think time, rec-outcome linkage, lesson/path engagement. P1:
six derivation-only analyses. Tiers, priority table, NEVER lists, and
Gate 5 re-evaluation bars apply unchanged.

## 3. Signal-by-Signal Analysis

| Signal | Derivable now? | Needs collection? |
|---|---|---|
| think time | NO (column exists, zero writes, 100% NULL) | YES — server timestamps + 1 column |
| rec outcome | PARTIAL (exposure + supersede timestamps exist; success needs join design, then volume) | NO schema (v1 join); event only later |
| lesson engagement | NO (LessonService read-only; no view/completion records) | YES — product-gated events |
| path engagement | NO (nodes set AVAILABLE/LOCKED once at creation; no transitions; progress unwritten) | YES — define semantics first |
| P1 six | YES — attempt curves, transitions, practice, trend, exposure/consumption, counts | NO |

## 4. Derivable vs Collectable

Derivable (code-only, future analysis): repeated-attempt curves,
difficulty_at_attempt sequences, topic practice histories,
recent-vs-prior trend, rec exposure/consumption timelines, per-topic
counts. Collectable (needs writes): per-question think time,
lesson-view/completion, node transitions, abandonment markers (P2),
validated game linkage (P2, per-game).

## 5. Think-Time Design

Schema: `question_attempts.response_time_seconds` EXISTS (nullable
INT) — no new column strictly required; if audit prefers explicitness,
no migration is still the default. Entity `QuestionAttempt` already
carries the field + setter; zero call sites today. Request flow:
`QuizSubmissionRequest{answers[{questionId, selectedAnswer}]}` carries
NO timing — client supplies nothing (verified DTO lines 16-29).
Controller `QuizController` → `QuizSubmissionService.submit()` sets
`startedAt=submittedAt=now()` (lines 114,127,139-141) — the degenerate
duration source. Safest future design: server records quiz-delivery
instant per (user, quiz) at QUIZ-001 (short-lived server store, NOT a
learner table); at QUIZ-002 computes per-answer elapsed from delivery
to submit receipt, validates 0 ≤ t ≤ quiz limit, writes
`response_time_seconds`, NULL on any anomaly; client MAY send
advisory per-question durations that are logged-but-never-trusted
(until a later gate proves client/server agreement). Historical values:
never invented; column stays NULL for old rows. Event time =
submit-receipt instant (< T for the NEXT attempt; the current row's own
timing is POST for its own outcome — usable only for subsequent rows).

## 6. Recommendation Outcome Design

Current truth: ACTIVE rows (exposure, generated_at) + CONSUMED rows
where consumed_at == supersede instant (system action, NOT learner
action). Missing states: accepted/started/completed/success — none
exist. Minimum for "did it help": v1 = join recommended topic →
later topic_mastery delta within a bounded window (existing tables,
zero schema; needs volume, not columns). v2 (later): explicit outcome
event only if v1 proves insufficient. No new state recommended now.

## 7. Lesson Engagement Design

Today: lessons are read-only content delivery; the system knows
NOTHING about opens/starts/completions/abandonment/dwell/next-lesson.
Derivable: nothing. Minimum viable (product-gated): lesson-view event
(user, topic/lesson, server timestamp) + completion marker (explicit
learner action or deterministic rule, product decision required).
Adaptive value must gate scope: recommend view+completion only, never
dwell/keystroke surveillance. Collection owner: backend service on the
lesson-read path; validator: server principal + timestamp bounds.

## 8. Learning-Path Engagement Design

Authoritative today: path/node creation (ACTIVE/ARCHIVED paths;
AVAILABLE first node, LOCKED rest — `LearningPathPersistenceService.
java:77-111`), sequence, required_mastery. Derivable: current node
(first AVAILABLE), node order, structural progression state. NOT
derivable: completions, transitions, timings (no post-creation writes
exist; progress linkage unwritten). Rule: do not invent semantics —
node-completion meaning (who marks, when, what advances) is a product
decision that must precede any event or ML use.

## 9. P1 Signal Analysis

All six derive from committed tables with existing columns, no writes:
attempt sequences (quiz_attempts ordered), difficulty transitions
(difficulty_at_attempt ordered), topic practice (question_attempts ⨝
questions), trend deltas (recent vs prior accuracy), rec timelines
(generated/consumed_at), per-topic counts. Prefer these derived
features over any duplicated telemetry — no persisted copies.

## 10. Data Ownership

CLIENT: selected answers, advisory timings (untrusted). BACKEND:
grading, timestamps, validation, mastery/rec/XP writes, event capture.
DATABASE: sole record (no ML store). ML FEATURE BUILDER: read-only
derivation from committed rows. Client is NEVER authoritative for
correctness, mastery, rec success, outcomes, XP, or scoring.

## 11. Point-in-Time Contract

Pre-event ML feature condition: `event_time < T` where T = current
attempt submit-receipt. Think-time of row N is POST for row N, PRE for
rows > N. Rec-outcome deltas use only post-rec, pre-next-attempt
windows. Delivery instants and view events are pre-event facts once
recorded. Anything stamped ≥ T for the current target is excluded.

## 12. Historical Availability

HISTORICALLY AVAILABLE: labels, difficulties, IDs, timestamps,
mastery pre-images, rec exposure/supersede. PARTIAL: progress structure
(schema without populated behavior). NOT AVAILABLE: think times,
lesson/path engagement, abandonment, validated game linkage, rec
success. Unavailable stays NULL historically — future-only collection
marked as such.

## 13. Database Impact (IF approved; nothing created now)

Think-time v1: NO SCHEMA CHANGE (existing nullable column). Lesson/path
events (if approved): one narrow `learning_events`-style table OR
columns on progress — decision deferred to implementation gate with:
UUID PK, user/topic/lesson/node FKs, event_type, server timestamp,
minimal payload; indexes on (user, timestamp) + (topic, timestamp); no
uniqueness beyond idempotency keys IF needed. Rec outcome v1: NO SCHEMA
CHANGE. Everything else: NO SCHEMA CHANGE REQUIRED.

## 14. Backend Impact (additive sketches, NOT applied)

Think-time: `QuizService` (record delivery instant, short-lived store),
`QuizSubmissionService.submit` (+validated write to existing setter),
`QuizSubmissionRequest` (+optional advisory timings, validated/ignored),
`QuestionAttempt` (unchanged). Rec-join: analysis code only (mlrag).
Lesson/path: new service methods on read paths + event persistence
(product-gated). Each change: server-principal enforcement, bounds
validation, dedicated tests; no existing method signature changes.

## 15. Frontend Impact

Think-time v1: NONE required (server delivery→submit interval suffices;
per-question granularity is a later refinement). Advisory per-question
durations (optional, untrusted): additive DTO fields only. Lesson/path:
view events ride existing read calls; completion needs one explicit
client action (product decision). Nothing authoritative ever moves
client-side.

## 16. Security

Threats: forged durations (mitigated: server clock authoritative,
bounds-checked, NULL-on-anomaly), replay/duplicates (idempotency via
existing attempt semantics; events keyed, duplicates ignored),
forged timestamps (server stamps only), telemetry flooding (rate-limit
read paths if events added), privacy (no PII beyond surrogate keys;
raw timings age to aggregates), authorization (principal-derived
ownership on every write; cross-user writes impossible by construction).

## 17. Performance

Think-time: one INT write per question row inside the existing submit
transaction (negligible amplification); no new index strictly needed
(covered by attempt PK/FK access). Lesson/path events: one row per view
— gate with sampling/aggregation if volume concerns arise; index
(user, timestamp). No high-volume telemetry without proven need.

## 18. Failure Handling

Delivery-store miss → timing NULL (not zero, not estimated). Invalid
advisory durations → ignored + logged count. Event-write failure →
must not fail the learner request (degraded capture, error audit).
NULL timings flow through existing cold/median machinery (f1 handles
missingness by design).

## 19. Rollback

Kill switches: think-time write flag, event-capture flag (default off
until proven). DB: nullable additive columns/events are inert when
unused; no rollback migration strictly needed (document retention
instead). API: additive optional fields preserve compatibility. NULL
behavior: identical to today (median/cold paths). Learner flows
continue exactly when signals are absent.

## 20. Test Plan (to be written at implementation)

Valid/missing/malformed timings; tampered/duplicate/replayed advisory
payloads; cross-user submit rejection; timestamp ordering (delivery <
submit); point-in-time leakage (timing of row N absent from row N
features); full existing regression; migration validation on real
MySQL (Testcontainers); H2 parity; ML extraction parity (new column
flows through builder as nullable numeric).

## 21. Implementation Order

14.1 think-time (server delivery→submit write path; no client changes).
14.2 rec-outcome join design validation on grown data (analysis only).
14.3 lesson/path engagement events (product-gated; semantics first).
14.4 derived P1 features into f-next schema (analysis code only).
14.5 validation hardening + re-evaluation at Gate 5 bars. Order follows
evidence strength per euro of risk: server-only first, product-gated
second, analysis always.

## 22. Explicit Non-Goals

No client-authoritative durations; no historical backfill; no
surveillance telemetry; no game-mastery linkage; no progress-semantics
invention; no vector/embedding work; no model changes; no threshold
invention; no production promotion.

## 23. Gate 14.0 Decision

**PASS (design complete; nothing implemented).** Think-time is
implementable server-side with no schema change; rec-outcome needs
volume, not columns; lesson/path need product semantics before events.
Two prior-gate wordings corrected (§1). Awaiting approval before 14.1.
