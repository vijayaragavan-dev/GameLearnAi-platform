# GATE 14.3 — Lesson & Learning-Path Engagement (ANALYZE → DOCUMENT → DEFER)

> No completion semantics exist in the product; therefore no completion
> telemetry is implemented. Nothing built, migrated, or modified except
> this document and guard tests. Derivable structure documented; all
> collection DEFERRED pending explicit product decisions.

## 1. Objective

Determine which lesson/path engagement signals are derivable, which
need collection, and which must wait for product semantics — without
inventing semantics.

## 2. Gate 13/14.0 Inputs

P0 lesson/path engagement (product-gated); progress semantics
unverified; rec-outcome join needs volume not columns; think-time path
in progress (Gate 14.1).

## 3. Existing Lesson Flow (verified)

`GET /api/v1/topics/{topicId}/lesson` → `LessonService.
getCanonicalLesson` (`@Transactional(readOnly=true)`) → canonical
active lesson DTO. No principal use, no writes, no events, no limiter
beyond auth. There is NO viewed/started/completed/abandoned/
progression event anywhere in backend or frontend (verified: no
completion endpoints among all 11 POST mappings; no frontend
completion calls — progress screens only GET `/api/v1/progress`).

## 4. Lesson Signal Inventory

viewed: TECHNICALLY OBSERVABLE (HTTP GET) but UNSAFE as learning
(anonymous-capable, cacheable, repeatable; viewing ≠ studying).
started/completed/abandoned/dwell/next-lesson: UNDEFINED (no events,
no columns, no product rule). Summary: zero authoritative lesson
signals exist.

## 5. Lesson Completion Semantics

**LESSON COMPLETION = PRODUCT SEMANTICS REQUIRED.** No explicit action,
status, progress write, transition, or required activity exists.
Candidates and why each fails today: GET-as-completion (UNSAFE —
caching/bots/reloads inflate); next-GET-as-completion (UNSAFE —
abandonment indistinguishable); quiz-submit-as-completion (WRONG GRAIN
— topic evidence, not lesson study). Required product decision:
define completion as (a) explicit learner action, (b) deterministic
rule (e.g., post-lesson assessment threshold), or (c) declared
out-of-scope — then collection follows.

## 6. Existing Learning-Path Flow (verified)

`GET /api/v1/learning-path/{subjectId}` (owned paths) +
`POST /{subjectId}/generate` (idempotent create-or-return). Nodes
written once (first AVAILABLE, rest LOCKED;
`LearningPathPersistenceService:77-111`); no transition, skip,
completion, or timing writes exist. Progress linkage unwritten
(`ProgressRepository` read-only in production).

## 7. Path Signal Inventory

Authoritative today: path existence/status, node order/sequence,
required_mastery, current AVAILABLE node (derivable: first AVAILABLE),
structural position. NOT authoritative: completed/next/skipped node,
transitions, timings, path completion. Frontend path-map renders
status chips from the same read model (display, not events).

## 8. Path Completion Semantics

**PATH NODE COMPLETION = PRODUCT SEMANTICS REQUIRED.** No endpoint,
status transition, or rule defines it. GET-node ≠ completed and
next-call ≠ completed (both unprovable from read-only flows).
Required product decisions: completion trigger, skip policy,
advancement authority (engine-owned), and whether completion writes
to nodes, progress, or an event record.

## 9. Derivable Signals (no schema, no collection)

Path structure per subject (existence, order, current AVAILABLE node,
required_mastery gates); lesson catalog linkage (canonical lesson per
topic); quiz/topic activity as topic-engagement proxy (already P1).
These are available to future features today via existing read APIs.

## 10. Signals Requiring Collection

Lesson view/completion + node transitions/completions — all gated on
§5/§8 product decisions. No columns, no events, no estimates until
then.

## 11. Signals Deferred

Everything in §10, plus dwell/abandonment/depth (surveillance-adjacent,
never without proven adaptive need), plus any progress-based feature
(semantics unverified).

## 12–16. Ownership / Point-in-Time / Privacy / Duplicates / Failure

Owner: backend service on read paths (server principal + server
timestamps); ML builder derives read-only. Point-in-time: view/
transition instants are pre-event facts once recorded (`event_time <
T`); completion of row N is POST for N. Privacy: IDs + timestamps
only; no dwell/keystroke/device/location. Duplicates: idempotent event
keys when collection lands (repeated GETs must never inflate).
Failure: capture degrades; lesson/path experience never depends on it.

## 17–19. Database / Backend / Frontend Impact

Today: NO SCHEMA CHANGE (nothing collectable without semantics). If
approved later: one narrow event record (user/topic/lesson/node,
event_type, server timestamp, idempotency key; indexes on
(user,time)+(topic,time)) OR product-defined progress writes — decision
belongs to the implementation gate, not this one. Backend: additive
service hooks on read paths. Frontend: view events ride existing calls;
completion needs one explicit product-defined action. Zero changes now.

## 20. ML Compatibility

Pre/post-event separation holds structurally (event timestamps vs T);
f1 schema contains no lesson/path completion names (guard-tested);
future features follow the same `< T` + leakage suite. No model/metric
changes; no performance claims.

## 21. AdaptiveEngine Relationship

Untouched and un-bypassable. Engagement may someday inform advisory
features; mastery/difficulty/recs/scoring/XP stay engine-owned
regardless of future event richness.

## 22. Test Plan (for the deferred implementation)

Valid/duplicate/replayed/foreign-user/unauthenticated events;
ordering; NULL handling; capture-failure survival; leakage (event of
row N excluded from row N features); regression; migration validation;
extraction parity. Written when semantics land — not now.

## 23. Implementation Decision

**OUTCOME B — DEFERRED, all collection.** Derivable structure (§9)
needs no code. Rationale: inventing completion telemetry without
product semantics would manufacture the exact surveillance-grade noise
Gate 13 forbids, while contributing zero trustworthy signal.

## 24. Gate 14.3 Decision

**PASS WITH CONDITIONS** — analysis complete and honest; deferral is
the correct engineering outcome; suites green; zero implementation.
Condition: lesson/path completion product decisions must precede any
Gate 14.4 collection work.
