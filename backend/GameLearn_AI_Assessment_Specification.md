# GameLearn AI — Assessment Specification (ASMT)

---

## 1. Document Control

| Field | Value |
|---|---|
| Document name | GameLearn_AI_Assessment_Specification.md |
| Version | 1.0.0 |
| Status | **APPROVED — READY FOR IMPLEMENTATION** (owner sign-off 2026-08-24; decisions A1–A12, C1, C2 approved exactly as documented — see §23/§26) |
| Owner | Project Owner |
| Implementation Owner | Member 2 — Backend + AI |
| Implementation phase | Phase 8B — Assessment Engine (ASMT-001..003), only after approval |
| Authority chain | Database Spec v1.0 → Backend+AI Spec §11/§15 → Adaptive Spec v1.0.0 → Learning-Path AI Spec v1.1.0 → Gamification Spec v1.0.0 → API Contract v1.1.0 → THIS document |

### 1.1 Purpose

Single source of truth for subject-level placement assessment:
`ASMT-001` (fetch), `ASMT-002` (submit/evaluate), `ASMT-003` (result).
Fills the deferred rows of API Contract §3 and operationalizes Backend+AI
Specification §15 ("Assessment Engine") without modifying any approved
document.

### 1.2 Scope

IN SCOPE: cold-start placement per subject; deterministic question
delivery; server-side evaluation; per-topic baseline initialization using
APPROVED Adaptive mathematics; profile refresh subset; derived result read;
contract amendment proposal.

OUT OF SCOPE: AI-generated assessment questions (requires an AI micro-spec);
pass/fail certification; reassessment scheduling; dashboards; any schema
change; any Gamification event; any modification of approved mathematics.

### 1.3 Changelog

| Version | Change |
|---|---|
| 1.0.0 | Initial PROPOSED draft (Phase 8A). Full model, contracts, integration rules, test matrix, edge cases, decision register A1–A12 |
| **1.0.0 — APPROVAL** | **Owner approved the specification exactly as documented:** A1 curated-question reuse · A2 K=3 deterministic selection · A3 initial difficulty EASY (no bands) · A3b no pass/fail · A4 attempt_count=1 lineage · A5 R-GUARD 409 protection · A6 no recommendations during assessment · A7 zero gamification events · A8 SUBJECT_PLACEMENT type · A9 derived result model · A10 empty-catalog 404 · A11 ASMT-002 returns 201 · A12 normative ASMT-003 shape. C1 ratified: learner_profiles.current_level/total_xp and all gamification tables are EXCLUSIVELY Gamification-owned — assessment never writes them. C2 ratified: recommendations remain Adaptive-owned. Status → APPROVED — READY FOR IMPLEMENTATION. API Contract concurrently amended to v1.2.0 adding ASMT-001..003. No normative rule altered by approval |

### 1.4 Classification vocabulary (normative for this document)

Every significant decision carries exactly one label:

* **DEFINED — APPROVED SPEC**: dictated by an already-approved specification.
* **DEFINED — CONTRACT**: dictated by API Contract v1.1.0 conventions.
* **DEFINED — DB SPEC**: dictated by Database Specification / V1–V11 schema.
* **DEFINED — CONVENTION**: dictated by an implemented, regression-locked
  convention of Phases 0–7 (evidence, not silently extended).
* **PROPOSAL — OWNER APPROVAL**: concrete rule proposed here; becomes
  normative upon owner approval of this document.
* **TBD — REQUIRES OWNER DECISION**: cannot be derived from any authority;
  implementation is BLOCKED until resolved.

OWNER RATIFICATION (2026-08-24): every PROPOSAL/TBD below that carries an
A-register or C-reference has been APPROVED AS DOCUMENTED; those labels are
retained for traceability and read as "APPROVED (owner, 2026-08-24)".

---

## 2. Assessment Purpose

【DEFINED — APPROVED SPEC (Backend §15, §262)】 Assessment exists to solve the
cold-start problem: before a learner answers ANY real quiz for a subject,
the personalized pipeline has no mastery evidence — PATH-002 would fall back
to a generic SYSTEM path and Adaptive would initialize everything at first-
attempt accuracy (T01). The assessment produces that first evidence
deliberately, per topic, in ONE sitting.

Differences from normal quizzes (QUIZ-001/002):

| Aspect | Quiz (approved) | Assessment (this spec) |
|---|---|---|
| Scope | single topic | whole ACTIVE subject (multi-topic) |
| Trigger | learner practices anytime | placement baseline, guarded once-per-subject-lineage |
| Writes | attempts + Adaptive state + recommendation + gamification | per-topic mastery baselines + profile refresh subset ONLY |
| Gamification | XP/streak/achievements | none in v1 (§12) |
| Adaptation afterwards | full T02+ update loop | none — subsequent quizzes use approved T02 normally |

Relationships: results are READ by Learning Path AI implicitly (PATH-002
builds learner context from the mastery/trend rows this assessment seeds —
no direct write to any learning-path structure); Adaptive Engine retains
EXCLUSIVE ownership of all mastery/difficulty/adaptation mathematics (this
spec reuses T01 verbatim, §11); Gemini has NO role in assessment scoring or
delivery (Backend §3 prohibition).

## 3. Assessment Types

No type taxonomy exists in any authoritative document (Database Spec defines
none; Backend §23 lists none). This specification therefore models exactly
ONE implicit behavior: subject placement.

**APPROVED (A8)**: Assessment v1 uses exactly ONE implicit type,
`SUBJECT_PLACEMENT`. No larger taxonomy or additional modes exist; adding
any requires a new specification plus a contract amendment.

## 4. Assessment Lifecycle

The approved schema has NO assessment-instance table (`quizzes.topic_id`
and `quiz_attempts.quiz_id` are NOT NULL — a multi-topic attempt cannot be
stored), so the lifecycle is deliberately STATELESS between fetch and submit:

```
FETCH   ASMT-001  stateless deterministic delivery (no writes)
SUBMIT  ASMT-002  ONE atomic transaction:
                  validate -> grade -> per-topic T01-mirror baselines
                  -> profile refresh subset -> COMMIT
RESULT  ASMT-003  stateless derivation from persisted baseline state
```

* There is no CREATED/IN_PROGRESS/EXPIRED/CANCELLED state machine: the only
  persisted states are the resulting baseline rows themselves.
  【DEFINED — DB SPEC constraint; introducing instance states would require a
  migration, which is not authorized】 If the owner later wants resumable
  sessions: would require BOTH an owner decision AND a DATABASE SPECIFICATION
GAP ruling (instance tables do not exist); not part of v1.
* Re-attempt/re-baseline: FORBIDDEN once any assessed lineage exists
  (guard rule R-GUARD, §11.4) — 【APPROVED (owner, 2026-08-24)】(A5).
* Failure at any point ⇒ nothing persists; the learner may retry the fetch
  and submit freely (idempotent-until-successful).

Every transition above is deterministic given (user, subject, catalog state).

## 5. ASMT-001 — Fetch Assessment

Path/method/auth are FIXED by Backend §11 and are restated here verbatim;
they become binding contract rows upon Contract amendment (§20).

| Aspect | Value | Class |
|---|---|---|
| Method/path | GET `/api/v1/assessment/{subjectId}` | DEFINED — APPROVED SPEC (§11 rows 183) |
| Auth | Bearer JWT; principal-derived; no body | DEFINED — CONTRACT |
| Path param | `subjectId` UUID of an ACTIVE subject; unknown/inactive ⇒ 404 RESOURCE_NOT_FOUND before any work | DEFINED — CONVENTION (mirrors PATH-002 pre-checks) |
| Selection | For every ACTIVE topic of the subject, ordered `display_order ASC, id ASC`, take up to K = **3** active MCQ questions ordered `created_at ASC, id ASC`; topics with zero active questions are skipped. K is a compiled constant (Gamification-style) | APPROVED (A1+A2) |
| Determinism | Pure function of catalog state — identical for repeated GETs absent catalog mutation | DEFINED — CONVENTION |
| Response 200 | `{ "subjectId", "questions": [ { "questionId", "topicId", "questionText", "options", "difficulty" } ] }` — NEVER correct answers/explanations (mirrors QUIZ-001 redaction) | DEFINED — CONVENTION |
| Empty catalog | Subject active but ZERO assessable questions across ALL topics ⇒ 404 RESOURCE_NOT_FOUND ("no assessable content") | APPROVED (A10) |
| Errors | 400 MALFORMED_REQUEST (bad UUID), 401 UNAUTHORIZED, 404 as above | DEFINED — CONTRACT registry |
| Transaction | read-only; no locks beyond consistent reads | DEFINED — CONVENTION |
| Idempotency | naturally idempotent read | DEFINED — CONVENTION |
| Database | reads `subjects`, `topics`, `questions`; writes NOTHING | DEFINED — DB SPEC |

## 6. ASMT-002 — Submit Assessment

| Aspect | Value | Class |
|---|---|---|
| Method/path | POST `/api/v1/assessment/{subjectId}/submit` | DEFINED — APPROVED SPEC (§11 row 184) |
| Auth | Bearer JWT; principal = the assessed learner; no userId field may exist | DEFINED — CONTRACT |
| Request | `{ "answers": [ { "questionId": UUID, "selectedAnswer": string ≤255 } ] }`; duplicates rejected; empty rejected | DEFINED — CONVENTION (mirrors QUIZ-002 validation) |
| Validation | every answered `questionId` MUST belong to the CURRENT deterministic selection for this subject (recomputed identically); violations ⇒ 400 MALFORMED_REQUEST; unanswered selection questions are graded INCORRECT (Adaptive §6 rule reused) | DEFINED — CONVENTION + PROPOSAL (selection-recompute rule, A1 corollary) |
| Grading | per-question boolean correctness (trimmed string equality, mirroring Phase 4); overall accuracy and per-topic accuracy = correct÷total×100 HALF_UP scale-2 over THAT scope | DEFINED — CONVENTION (Phase 4 scoring rule reused verbatim) |
| Guard R-GUARD | refuse when assessed lineage exists (§11.4): any prior `topic_mastery` row for these topics OR any quiz_attempt whose quiz belongs to this subject ⇒ 409 DATA_CONFLICT ("assessment baseline already established") | APPROVED (A5) |
| Success | `201` + result body (§7 shape) | APPROVED (A11) |
| Errors | 400 / 401 / 404 (subject inactive/unknown, or selection empty) / 409 R-GUARD / 500 | DEFINED — CONTRACT registry; no new codes |
| Transaction | ONE atomic transaction (§16) | DEFINED — CONVENTION (Adaptive §19 precedent) |
| Idempotency | successful submit establishes the guard; a REPLAYED identical request ⇒ 409 (never double-writes) | APPROVED (A5) |

Purpose classification: submission+evaluation+analysis+persistence in one
operation 【DEFINED — APPROVED SPEC (§15 flow compressed into one endpoint;
separate analyze/result endpoints do not exist in §11)】.

## 7. ASMT-003 — Result

| Aspect | Value | Class |
|---|---|---|
| Method/path | GET `/api/v1/assessment/{subjectId}/result` | DEFINED — APPROVED SPEC (§11 row 185) |
| Semantics | DERIVED read of the persisted baseline state for this subject's topics — no separate result store exists or will be created (A9) | APPROVED (A9) |
| Response 200 | `{ "subjectId", "assessed", "overallMastery", "topics": [ { "topicId", "topicName", "masteryScore", "masteryLevel", "currentDifficulty" } ] }` mirroring persisted `topic_mastery` triplets; topics never assessed are OMITTED while `assessed:false` variants return `topics: []` | APPROVED (A12) |
| Not-assessed case | learner exists but no baseline rows for the subject ⇒ `200 { subjectId, assessed: false, overallMastery: <profile mean>, topics: [] }` (NOT 404 — absence of an assessment is a valid queryable state) | APPROVED (A12) |
| Errors | 400/401/500 only | DEFINED — CONTRACT |
| Ownership | principal-scoped; cross-user impossible (no identifier parameter) | DEFINED — CONTRACT |

## 8. Assessment Scoring

| Rule | Value | Class |
|---|---|---|
| Question correctness | trimmed string equality vs `correct_answer` (server-side only) | DEFINED — CONVENTION (Phase 4) |
| Unanswered | counted INCORRECT | DEFINED — APPROVED SPEC (Adaptive §6) |
| Overall accuracy | round_half_up_2(correct ÷ answered-scope × 100) where answered-scope = current deterministic selection size | DEFINED — CONVENTION |
| Per-topic accuracy | same formula restricted to that topic's selected questions | DEFINED — CONVENTION (approved corollary) |
| Partial credit | NONE (binary per question) | DEFINED — CONVENTION |
| Pass/fail | NOT MODELED — Assessment v1 is a placement/baseline mechanism, not a certification examination | APPROVED (A3b) |
| Score bounds | 0.00–100.00 inclusive, scale ≤2 | DEFINED — CONVENTION |
| Persistence | per-topic via `topic_mastery` baselines (§11); overall via `learner_profiles.overall_mastery`; NO separate score table (none exists; §14) | DEFINED — DB SPEC + PROPOSAL |
| Normalization | NONE across subjects/topics | DEFINED — CONVENTION (no authority suggests it) |
| Rounding | HALF_UP at scale 2, identical to Adaptive §6 | DEFINED — APPROVED SPEC |

## 9. Cutoff Rules

Investigated ALL authoritative documents: NO approved cutoff/threshold maps
assessment accuracy to anything (the only approved numeric thresholds are
Adaptive mastery states 40/70/90 and trend ±5.00 — they govern POST-quiz
states, not assessment entry decisions).

RESOLVED BY OWNER APPROVAL (2026-08-24):

* Baseline `current_difficulty` = **EASY** for every initialized topic.
  No accuracy bands are defined for v1 (A3).
* There is NO pass/fail certification or cutoff in Assessment v1 (A3b);
  the assessment unconditionally completes as a baseline mechanism.

## 10. Topic Analysis

Ownership boundary (normative):

* Assessment computes ONLY raw per-topic accuracy over its own delivered
  questions and materializes it as T01-shaped baseline rows.
* Weak/strong classification, trends, difficulty changes, next-action,
  recommendations: EXCLUSIVELY the Adaptive Engine, driven by subsequent
  REAL quiz submissions through the approved pipeline. Assessment output is
  ordinary `topic_mastery` input state — indistinguishable downstream from
  T01-initialized state, which is precisely why no Adaptive rule needs
  changing.
* Subject-level analysis = mean of baseline mastery scores, written to
  `learner_profiles.overall_mastery` (same aggregation as the approved
  profile refresh).

## 11. Adaptive Engine Integration

### 11.1 Data flow (single direction)

Assessment → writes T01-shaped `topic_mastery` rows + profile subset →
later REAL quizzes flow through the UNMODIFIED approved pipeline (T02+)
→ recommendations/paths consume the state. Assessment never calls
AdaptiveLearningService.processSubmission (that path is quiz-attempt-keyed
by design).

### 11.2 Baseline row construction (per assessed topic)

| Column | Value | Source of authority |
|---|---|---|
| mastery_score | topic accuracy | T01 formula semantics (init = first accuracy) — reused VERBATIM, no modification of approved math |
| mastery_level | stateOf(mastery_score) — approved boundaries 40/70/90 | DEFINED — APPROVED SPEC (Adaptive §8) |
| current_difficulty | **EASY** for every initialized topic | APPROVED (A3) |
| attempt_count | **1** (mirrors T01 lineage: the learner's next real quiz updates via approved T02 weight ½) | APPROVED (A4) |
| recent_accuracy | topic accuracy | T01 mirror |
| trend | INSUFFICIENT_DATA | DEFINED — APPROVED SPEC (Adaptive §9 n==1) |
| last_assessed_at | submitted_at | DEFINED — CONVENTION |

### 11.3 No duplication of Adaptive mathematics

Only T01/stateOf constants are REUSED (imported, not copied). T02–T06,
trend deltas beyond INSUFFICIENT_DATA, difficulty ladder steps, next-action
rules are untouched and continue to run exclusively inside the quiz pipeline.

### 11.4 Lineage guard R-GUARD

Before writing, the transaction asserts BOTH:
(a) zero existing `topic_mastery` rows for this user across the assessed
topic set; (b) zero `quiz_attempts` joined to quizzes of this subject for
this user. Any hit ⇒ 409 DATA_CONFLICT (retry-safe, state unchanged).
This preserves single-lineage integrity of the approved update mathematics.
【APPROVED (owner, 2026-08-24)】(A5)

### 11.5 What assessment does NOT do

Creates no quiz_attempt/question_attempt rows (schema cannot host a multi-
topic attempt — §14); generates no recommendations in v1 (see §13/conflict
C2); awards nothing (§12); never invokes Gemini.

## 12. Gamification Integration

NONE in v1. The approved XpEventType enum contains no assessment value;
adding one requires an ENUM + Gamification-Spec amendment (explicitly out
of scope). Consequently:

* No XP, no achievement progress, no streak day, no level change originates
  from ASMT-002. `GamificationService.awardForQuizSubmission` remains wired
  exclusively to QUIZ-002; Phase 8B MUST NOT wire it into assessment.
* Streak days remain defined by processed quiz submissions only
  (Gamification §8.1) — an assessment is not a streak activity.
* XP/achievement/streak events for assessments are NOT authorized in v1
  (A7). If ever wanted: a new XpEventType value plus a Gamification-Spec
  version bump through a future amendment.

## 13. Learning Path Integration

Indirect and automatic only: seeded baselines make the NEXT PATH-002 call
produce an AI-personalized path (learner context now non-empty). Assessment
writes nothing to `learning_paths`/`learning_path_nodes` and emits no LP
events. Gemini never sees assessment answers and never scores them
(Backend §3; AI-LP redaction rules). CONFLICT C2 recorded (§25): Backend
§15 flow mentions "Generate initial recommendation"; Adaptive single-writer
ownership says recommendations originate from processed submissions
(Adaptive §14). RECOMMENDED resolution: v1 skips recommendation generation;
the first REAL quiz produces it naturally. **APPROVED (A6/C2)**: Option A
(skip in v1) stands; Option B would require an Adaptive-Spec amendment and
is NOT authorized by this document.

## 14. Database Mapping (zero schema change)

| Concern | Tables/columns | Mode |
|---|---|---|
| Subject/topic/question sourcing | `subjects(is_active)`, `topics(subject_id,is_active,display_order)`, `questions(topic_id,is_active,question_type='MCQ',options_json,…)` | READ |
| Per-topic baseline | `topic_mastery(mastery_score,mastery_level,current_difficulty,attempt_count,recent_accuracy,trend,last_assessed_at)` UNIQUE(user_id,topic_id) | WRITE (create-only under R-GUARD) |
| Profile subset | `learner_profiles.overall_mastery`, `.current_subject_id` | WRITE |
| Result derivation | same baseline rows + `topics.name` | READ |
| Explicitly NOT written | `quiz_attempts`,`question_attempts`,`quizzes`,`progress`,`recommendations`,`xp_transactions`,`user_achievements`,`streaks`,`learning_paths*`,`ai_interactions`,`users.*`,`learner_profiles.current_level/current_topic_id` | — |

Schema sufficiency verdict: SUFFICIENT for the stateless model. A persistent
assessment-instance/answer-evidence model would be a **DATABASE
SPECIFICATION GAP — REQUIRES OWNER DECISION** (not proposed; unnecessary
for v1).

Enum usage: `MasteryLevel`/`Difficulty` values reused verbatim; NO enum is
created or altered.

## 15. Profile / Difficulty Write Targets (single-owner matrix)

| State | Sole owner | Assessment may write? |
|---|---|---|
| topic_mastery.mastery_score/level/trend (baseline creation only) | Adaptive mathematics (T01 mirror) | YES — create-only, pre-first-quiz, under R-GUARD |
| topic_mastery.current_difficulty | Adaptive ladder (post-quiz) | YES at baseline creation — value per A3 decision |
| recommendations | Adaptive pipeline (submissions) | NO in v1 (A6) |
| learner_profiles.overall_mastery / current_subject_id | Adaptive refresh (quizzes) / THIS spec (baseline creation) | YES — same aggregation, inside same TX |
| learner_profiles.current_topic_id | Adaptive/profile-refresh + path flows | NO |
| learner_profiles.current_level / total_xp | Gamification (XP-level) | **NEVER** — resolves conflict C1 (§25): assessment starting difficulty NEVER touches the XP level |
| xp/achievements/streaks | Gamification | NO |

Rule: two engines never independently write the same cell; where Adaptive
owns the mathematics, assessment only seeds its INPUT rows once, before the
adaptive loop begins.

## 16. Transaction Model

ONE `@Transactional` method for ASMT-002:

1. Load+validate subject/questions selection (reads).
2. Acquire `LearnerProfile.findWithLock(user)` FIRST — serialization anchor
   for concurrent submissions of the SAME user (established pattern).
3. Re-check R-GUARD inside the lock (race loser ⇒ 409, commit-nothing).
4. Grade; create baseline rows (create-if-absent; concurrent creators
   serialize on the profile anchor taken in step 2 — matches Adaptive §19
   anchor technique; no new lock hierarchy is introduced).
5. Refresh `overall_mastery` (mean of baselines) + `current_subject_id`.
6. COMMIT. Any exception ⇒ full rollback (nothing persisted).

ASMT-001/003: read-only transactions.

Ordering relative to other engines: assessment PRECEDES the adaptive loop
chronologically (it seeds its input) and shares NO transaction with quiz
submissions or gamification. No ordering conflicts exist because the write
sets are disjoint (§15) and the only shared row (profile) uses the
established lock.

## 17. Concurrency

| Scenario | Outcome |
|---|---|
| Two simultaneous ASMT-002 (same user/subject) | Both serialize on the profile anchor; winner writes baselines; loser's R-GUARD re-check fails ⇒ 409. Exactly-once baseline. |
| Duplicate (sequential) submit | Same 409 via R-GUARD. |
| Retry after timeout/crash | Prior TX rolled back ⇒ clean full retry. |
| ASMT-001 fetched twice | Identical payload unless catalog mutated (edge E17). |
| Concurrent ASMT-002 + first real QUIZ-002 on same topic | Serialized by existing locks; whichever commits first wins lineage; the other's guard/checks yield 409 (assessment) or normal T02 (quiz). No lost updates, no deadlock (uniform mastery→profile order inherited). |
| Same learner, different subjects | Independent baselines; no interaction. |

## 18. Security

* Authentication mandatory on all three endpoints; anonymous ⇒ 401
  (anyRequest.authenticated covers new paths).
* Principal is the sole identity; requests carry NO userId/ownership fields;
  cross-user access structurally impossible.
* Client controls ONLY `selectedAnswer` strings; correctness, score,
  baselines, difficulty, mastery, profile fields are server-computed.
  Anti-cheating surface equals Phase 4 (identical equality grading).
* Replay: guarded by R-GUARD 409 (never double-writes).
* Enumeration: unknown/inactive subject uniformly 404 (mirrors PATH-002).
* Responses never contain correct answers/explanations, prompts, internal
  identifiers beyond topic/question UUIDs the learner must reference, or
  another user's data. Logs carry requestId + counts/codes only — no
  answer contents, no PII beyond existing conventions (Backend §32).

## 19. Error Model

REUSES the existing registry exclusively — NO new codes proposed:

| Situation | Code / HTTP |
|---|---|
| Bad UUID / malformed JSON / duplicate answers / foreign questionId | MALFORMED_REQUEST·400 / VALIDATION_FAILED·400 |
| Anonymous | UNAUTHORIZED·401 |
| Unknown/inactive subject · zero assessable questions (A10) | RESOURCE_NOT_FOUND·404 |
| R-GUARD lineage exists | DATA_CONFLICT·409 |
| Unexpected failure (full rollback) | INTERNAL_ERROR·500 |

Reserved codes (AI_*) remain untouched — assessment never involves Gemini.

## 20. API CONTRACT AMENDMENT (v1.2.0)
### APPROVED BY OWNER (2026-08-24): Contract amended to v1.2.0 adding ASMT-001..003 exactly as specified below; implementation authorized by the separate Phase 8B prompt.

Add three rows to §3 (after GAM-003, replacing the deferred ASMT row):

| ID | Method & Path | Auth | Status after amendment |
|---|---|---|---|
| ASMT-001 | GET `/api/v1/assessment/{subjectId}` | Bearer | APPROVED — PENDING IMPLEMENTATION |
| ASMT-002 | POST `/api/v1/assessment/{subjectId}/submit` | Bearer | APPROVED — PENDING IMPLEMENTATION |
| ASMT-003 | GET `/api/v1/assessment/{subjectId}/result` | Bearer | APPROVED — PENDING IMPLEMENTATION |

Detailed behavior: sections 5–7 above (normative once approved).
Status codes: ASMT-001 200/400/401/404; ASMT-002 201/400/401/404/409/500;
ASMT-003 200/400/401/500.

Examples:

ASMT-001 200:
```json
{ "subjectId": "11111111-1111-1111-1111-111111111101",
  "questions": [
    { "questionId": "uuid-q1", "topicId": "uuid-t1",
      "questionText": "Which keyword declares a constant?",
      "options": ["const","let","var"], "difficulty": "EASY" },
    { "questionId": "uuid-q2", "topicId": "uuid-t2",
      "questionText": "Which structure is LIFO?", "options": ["stack","queue"],
      "difficulty": "EASY" }
  ] }
```

ASMT-002 request:
```json
{ "answers": [ { "questionId": "uuid-q1", "selectedAnswer": "const" },
               { "questionId": "uuid-q2", "selectedAnswer": "queue" } ] }
```

ASMT-002 201:
```json
{ "subjectId": "…101", "score": 100.00,
  "overallMastery": 100.00,
  "topics": [
    { "topicId": "uuid-t1", "accuracy": 100.00, "masteryLevel": "MASTERED",
      "currentDifficulty": "EASY" },
    { "topicId": "uuid-t2", "accuracy": 100.00, "masteryLevel": "MASTERED",
      "currentDifficulty": "EASY" } ] }
```
(`currentDifficulty` value shown per A3 recommended default.)

ASMT-003 200 (after one real quiz lowered mastery to 75):
```json
{ "subjectId": "…101", "assessed": true, "overallMastery": 75.00,
  "topics": [
    { "topicId": "uuid-t1", "topicName": "Variables",
      "masteryScore": 75.00, "masteryLevel": "PROFICIENT",
      "currentDifficulty": "EASY" } ] }
```
Normative element shape: `{ topicId, topicName, masteryScore, masteryLevel,
currentDifficulty }` — the LIVE persisted triplet (not a frozen assessment
snapshot; no separate accuracy field exists in storage).

Compatibility: purely additive; no existing endpoint/row affected; Flutter
section below inherits shapes verbatim.

## 21. Flutter Compatibility

* All three: Bearer header; JSON; standard ErrorResponse envelope on
  failure; loading → success/failure mapping trivial (single round-trips).
* ASMT-001 drives a dynamic multi-section form grouped by `topicId`
  (grouping is client-side presentation only).
* ASMT-002 is fire-and-persist: on 201 the app can navigate straight to
  PATH-002 generation (baselines ready). On 409 the UI shows
  "assessment already completed" and links to the existing path.
* ASMT-003 powers result/history screens and doubles as the
  "already assessed?" probe (`assessed:false`).
* No polling, no websockets, no pagination anywhere.

## 22. Test Matrix (implementation phase 8B — NOT written now)

| ID | Setup | Input | Expected | Persistence |
|---|---|---|---|---|
| ASMT-TEST-001 | subject+2 topics×3 questions | ASMT-001 | 200; 6 questions grouped; no answer leakage | none |
| -002 | inactive/unknown subject | ASMT-001/002/003 | 404 uniform | none |
| -003 | zero active questions | ASMT-001/002 | 404 | none |
| -004 | happy partial 4/6 | ASMT-002 | 201; score 66.67; per-topic accuracies 100/33.33; baselines T01-shaped | 2 mastery rows; profile mean 66.67; current_subject set |
| -005 | all correct | ASMT-002 | MASTERED everywhere; total 100 | as above |
| -006 | all wrong/unanswered mix | ASMT-002 | 0.00 rows; still COMPLETES (no cutoff) | rows exist |
| -007 | rounding boundary 1/3 | ASMT-002 | 33.33 | scale-2 stored |
| -008 | duplicate answer ids | ASMT-002 | 400 MALFORMED_REQUEST | none |
| -009 | foreign questionId | ASMT-002 | 400 | none |
| -010 | stale id (valid question outside selection) | ASMT-002 | 400 | none |
| -011 | unanswered subset | ASMT-002 | graded incorrect | baselines include it |
| -012 | replay after success | ASMT-002 | 409 DATA_CONFLICT | unchanged |
| -013 | concurrent double-submit | parallel | one 201 one 409; single baseline set | unique rows |
| -014 | prior real quiz exists (lineage) | ASMT-002 | 409 | nothing |
| -015 | rollback injection mid-TX | forced save failure | zero rows everywhere | clean |
| -016 | retry after rollback | fresh submit | full success | as -004 |
| -017 | STREAK_DAYS/Gamification isolation | any submit | zero xp/streak/achievement rows | proves §12 |
| -018 | current_level immunity | any submit | profiles.current_level unchanged | resolves C1 |
| -019 | recommendations untouched | any submit | zero recommendation rows | A6 default |
| -020 | ASMT-003 assessed view | after -004 | mirrored baseline triplets | — |
| -021 | ASMT-003 not-assessed view | fresh user | assessed=false, topics=[] | — |
| -022 | anonymous all endpoints | no token | 401 ×3 | — |
| -023 | cross-user isolation | two users | independent results | — |
| -024 | malformed UUID/JSON | bad path/body | 400 | — |
| -025 | topic skipped (no questions) | ASMT-001/002/003 | excluded everywhere consistently | — |
| -026 | single-question subject | minimal catalog | works end-to-end | — |
| -027 | determinism | two ASMT-001 calls | byte-identical | — |
| -028 | inactive QUESTION filtered | disabled one | excluded from selection | — |
| -029 | max-size guard | huge catalog | exactly K per topic | — |
| -030 | summary invariant | after -004 | ledger-free; overall == mean(baselines) | — |
| -031 | adaptive coexistence | baseline then real quiz | quiz follows T02 (n=2 weight ½) | lineage intact |
| -032 | PATH-002 personalization | baseline then generate | AI path consumes baselines (or SYSTEM fallback unchanged) | — |

## 23. Edge Cases

E1 zero questions → covered (-003). E2 single question (-026). E3 all
correct (-005). E4 all incorrect (-006). E5 mixed (-004). E6 unanswered
(-011). E7 duplicate answers (-008). E8 invalid question id (-009/-010).
E9 wrong-subject question (-009 family). E10/E11 inactive subject/question
(-002/-028). E12/E13 duplicate+concurrent submission (-012/-013).
E14 timeout retry (-016). E15 partial request (-024). E16 unauthorized
(-022). E17 catalog mutation between fetch & submit ⇒ selection recompute
makes changed ids FOREIGN ⇒ 400 (documented consequence of statelessness).
E18 max/min size (-029/-026). E19 baseline-vs-real-quiz interleaving
(-031). E20 huge subject (K-cap -029).

## 24. Security Review (specification level)

No client-controlled scoring/ownership/adaptive-state/gamification ✓
(no such request fields). No privilege escalation (single principal scope)
✓. Information leakage: correct answers never leave the server pre-submit;
result payloads expose only the learner's own aggregates ✓. Logging:
counts, codes, requestId only ✓. TLS/TOKEN handling inherited unchanged ✓.

## 25. Compatibility Review

| Document | Verdict |
|---|---|
| Database Spec | COMPATIBLE (read/write map in §14; zero DDL) |
| Backend+AI §11/§15 | COMPATIBLE except C1/C2 below (both routed to owner) |
| Adaptive Spec v1.0.0 | COMPATIBLE — T01/stateOf reused verbatim; no rule modified; single-lineage preserved via R-GUARD |
| Learning-Path AI v1.1.0 | COMPATIBLE — indirect data benefit only; no writer added |
| Gamification v1.0.0 | COMPATIBLE — zero events; award wiring untouched |
| API Contract v1.1.0 | COMPATIBLE — amendment proposal only (§20) |

CONFLICTS requiring owner attention (NOT silently resolved):
C1 `learner_profiles.current_level` dual-semantics risk (assessment
starting difficulty vs XP level) — RESOLVED NORMATIVELY HERE as
"assessment NEVER writes current_level", pending owner ratification
(supersedes the ambiguous Backend §15 phrase "level-setting", which shall
be read as ADAPTIVE-difficulty-setting).
C2 "Generate initial recommendation" (§15) vs Adaptive single-writer
ownership — v1 skips; Option B requires Adaptive amendment (A6).

## 26. Open Decision Register

| ID | Decision | Evidence status | Proposed option | Owner required | Impact if unresolved |
|---|---|---|---|---|---|
| A1 | Reuse curated questions (stateless deterministic selection) | Only schema-compatible source | Approve §5 selection | **APPROVED (2026-08-24)** | resolved |
| A2 | Questions per topic K=3 | none | Constant 3 | **APPROVED (K=3, 2026-08-24)** | resolved |
| A3 | Baseline current_difficulty value + cutoff bands | no approved cutoff | EASY; no bands | **APPROVED (EASY, no bands, 2026-08-24)** | resolved |
| A4 | attempt_count=1 lineage semantics | T01 mirror rationale | approve 1 | **APPROVED (=1, 2026-08-24)** | resolved |
| A5 | R-GUARD once-per-lineage + 409 | protects approved math | approve | **APPROVED (2026-08-24)** | resolved |
| A6 | Recommendations authorship during assessment | conflict C2 | skip in v1 | **APPROVED (skip, 2026-08-24)** | resolved |
| A7 | Gamification events for assessment | enum lacks value | none in v1 | **APPROVED (none, 2026-08-24)** | resolved |
| A8 | Type taxonomy | none exists | single implicit placement (`SUBJECT_PLACEMENT`) | **APPROVED (2026-08-24)** | resolved |
| A9 | ASMT-003 derived (no result store) | schema | approve derived | **APPROVED (2026-08-24)** | resolved |
| A10 | Empty-catalog 404 | convention mirror | approve | **APPROVED (2026-08-24)** | resolved |
| A11 | 201 status for ASMT-002 | creation convention | approve | **APPROVED (2026-08-24)** | resolved |
| A12 | Final ASMT-003 element shape (normative simplification §7) | schema-driven | approve | **APPROVED (2026-08-24)** | resolved |
| C1 | current_level/total_xp + gamification tables EXCLUSIVELY Gamification-owned; assessment starting difficulty targets adaptive difficulty only | Backend §15 ambiguity vs Gamification §6 | normative prohibition embedded (§15) | **RATIFIED (2026-08-24)** | resolved |
| C2 | Recommendations authorship during assessment | Adaptive §14 single-writer | skip in v1 | **RATIFIED (2026-08-24)** | resolved |

## 27. Implementation Boundary (Phase 8B, post-approval)

MAY implement: controller/service/repository-read additions for §5–§7;
baseline writer per §11; tests ASMT-TEST-001..032; swagger annotations;
README section. MAY amend Contract to v1.2.0 per §20 (after approval).
MUST NOT: add migrations/columns/enums; touch Adaptive/Gamification/LP
code paths beyond importing approved pure helpers; wire Gemini; implement
USER-002/dashboard/analytics; add mutation endpoints beyond ASMT-002.

## 28. Versioning

Version 1.0.0 · Status PROPOSED — REQUIRES OWNER APPROVAL · Approval via
§24-checkbox sign-off equivalent in the owner decision register (A1–A12)
· Any post-approval normative change ⇒ 1.x.0 bump + changelog row.

---

*End of Specification — GameLearn AI Assessment (ASMT) — v1.0.0 — APPROVED — READY FOR IMPLEMENTATION*
