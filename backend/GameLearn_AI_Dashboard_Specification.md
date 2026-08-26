# GameLearn AI â€” Dashboard Specification (DASH)

---

## 1. Document Metadata

| Field | Value |
|---|---|
| Document name | GameLearn_AI_Dashboard_Specification.md |
| Version | 1.0.0 |
| Status | **APPROVED â€” READY FOR IMPLEMENTATION** (owner sign-off 2026-08-24; D1â€“D3 and the completion-metrics ruling approved exactly as documented â€” see Â§28â€“Â§30) |
| Owner approval | 2026-08-24 â€” D1 (learning-path selection) Â· D2 (recentActivity v1 scope) Â· D3 (assessedSubjects projection) Â· RATIFIED: completion metrics UNAVAILABLE/DEFERRED |
| Owner | Project Owner |
| Implementation Owner | Member 2 â€” Backend + AI |
| Implementation phase | Phase 9B â€” Dashboard (only after approval) |
| Related API ID | **DASH-001** â€” `GET /api/v1/dashboard` (API Contract Â§3; behavior defined here, transport amended in API Contract v1.3.0) |
| Authority chain | Database Spec v1.0 â†’ Backend+AI Spec â†’ Adaptive Engine Spec v1.0.0 â†’ Learning Path AI Spec v1.1.0 â†’ Gamification Spec v1.0.0 â†’ Assessment Spec v1.0.0 â†’ API Contract v1.2.0 â†’ THIS document |
| Verified baseline | Phases 0â€“8 complete; 266 tests / 0 failures / 0 errors / 8 skipped / BUILD SUCCESS; migrations V1â€“V11 applied |
| Gemini dependency | **NONE.** The Dashboard performs zero network calls, zero AI calls, zero mutations |
| Schema changes required | **NONE** (see Â§24 â€” zero tables, zero columns, zero enums, zero migrations) |

This document defines ONLY the read-model/aggregation surface of the learner
Dashboard. It fills the deferred DASH-001 row of the central API Contract. It
must not be read as overriding any approved specification; every displayed
value is traced to an already-approved source (master traceability table, Â§8).

Normative language: MUST / MUST NOT / MAY in RFC 2119 spirit. Labels follow
the Assessment Specification classification vocabulary:

* **DEFINED â€” APPROVED SPEC**: dictated by an already-approved specification.
* **DEFINED â€” CONTRACT**: dictated by API Contract conventions.
* **DEFINED â€” DB SPEC**: dictated by Database Specification / V1â€“V11 schema.
* **DEFINED â€” CONVENTION**: dictated by an implemented, regression-locked
  convention of Phases 0â€“8 (evidence cited, not silently extended).
* **PROPOSAL â€” OWNER APPROVAL**: concrete rule proposed here; becomes
  normative upon owner approval of this document.
* **TBD â€” REQUIRES OWNER DECISION**: cannot be derived from any authority.

---

## 2. Purpose

The Dashboard is the learner's home screen: one authenticated request that
answers *"where do I stand and what should I do next?"* by aggregating the
learner's own already-persisted state across the five owned domains
(learner profile, adaptive state, gamification, assessment, learning path).

It exists because the alternative â€” Flutter calling USER-001 + GAM-001 +
GAM-002 + GAM-003 + PATH-001 + PROG-001 on every app launch â€” multiplies
round-trips and forces the client to reassemble cross-domain state without
server-side ordering guarantees. DASH-001 provides that assembly once,
server-side, with deterministic ordering and bounded payloads.

## 3. Scope

### 3.1 In scope

| Area | Status |
|---|---|
| One read-only aggregation endpoint (DASH-001) | DEFINED here |
| Field-level source mapping for every response value | DEFINED (Â§8) |
| Empty-state / new-learner / partially-initialized behavior | DEFINED (Â§11â€“Â§13) |
| Deterministic ordering + collection bounds | DEFINED (Â§14â€“Â§15) |
| Security & authorization model | DEFINED (Â§17â€“Â§18) |
| Error contract (existing registry only) | DEFINED (Â§19) |
| Performance constraints | DEFINED (Â§20) |
| Test matrix | DEFINED (Â§29) |
| API Contract amendment v1.3.0 | PREPARED (Â§22) |

### 3.2 Out of scope (NON-GOALS)

- Any mutation of any kind (see Â§6 boundary matrix).
- Any new endpoint beyond DASH-001 (`/dashboard/{userId}`, `/dashboard/admin`,
  `/dashboard/summary`, `/dashboard/analytics` are FORBIDDEN â€” no approved
  requirement exists for them).
- Any new mathematics: mastery formula, thresholds, trend, difficulty,
  recommendation priority, next-action logic, XP, levels, unlocks, streak
  arithmetic, assessment scoring are OWNED elsewhere and consumed verbatim.
- Completion-percentage derivation (explicitly unavailable â€” see Â§10.4).
- A unified cross-domain activity-event model (deliberately not invented;
  see Â§10.7 and owner decision D2).
- Caching, ETags, pagination, websockets, push notifications.
- Admin/teacher analytics surfaces.
- Any schema change, migration, enum addition, or configuration property.

## 4. Architecture Position

```
Flutter (home screen)
        â”‚  GET /api/v1/dashboard  (Bearer JWT)
        â–¼
DashboardController  (thin â€” no logic)
        â–¼
DashboardService  (@Transactional(readOnly = true))
        â”‚  reads ONLY
        â–¼
Existing repositories â”€â”€â–º learners' own persisted state:
   learner_profiles Â· topic_mastery Â· recommendations Â· achievements Â·
   user_achievements Â· streaks Â· quiz_attempts Â· learning_paths Â·
   learning_path_nodes Â· subjects Â· topics
        â–¼
DashboardResponse (plain DTO record)
```

The Dashboard sits beside USER-001/GAM-001..003/PATH-001 as ANOTHER consumer
of the same state. It introduces no writer, no scheduler, no cache, and no
domain logic. Where an approved endpoint already exposes a value, the
Dashboard exposes the SAME value with the SAME derivation (e.g., gamification
fields equal GAM-001 outputs computed from the same columns by the same
rules).

## 5. Domain Ownership (who owns what the Dashboard displays)

| Displayed concern | Sole owner domain | Owning specification | Dashboard role |
|---|---|---|---|
| `overall_mastery`, `current_subject_id`, `current_topic_id` | Adaptive Engine (refresh) / Assessment (baseline subset) | Adaptive Â§19; Assessment Â§15 | display only |
| mastery_score, mastery_level, current_difficulty, trend, attempt_count | Adaptive Engine | Adaptive Â§7â€“Â§10 | display only |
| Recommendations (activity, difficulty, priority, reason, status lifecycle) | Adaptive Engine | Adaptive Â§14 | display only, approved ordering |
| XP amounts, ledger, level model T(n)=50(nâˆ’1)n, MAX_LEVEL 50 | Gamification | Gamification Â§4, Â§6 | display only |
| Achievement catalog, unlock rows, unlock timestamps | Gamification | Gamification Â§7 | display only |
| Streak day/increment/reset/timezone semantics | Gamification | Gamification Â§8, Â§10 | display only |
| Placement baselines, R-GUARD lineage, assessed/not-assessed semantics | Assessment | Assessment Â§11, Â§14 | display only |
| Learning path content, node sequence, gates, statuses, lifecycle | Learning Path AI | AI-LP Â§9, Â§30â€“Â§32 | display only |
| Account identity (display_name) | Auth (Phase 2) | Backend Â§8 | display only |

**Binding rule:** the Dashboard MUST NOT recalculate any owned value. Where a
value exists pre-computed, it is copied verbatim into the response. Where a
display-only aggregate is needed (e.g., "how many MASTERED topics"), it is a
COUNT over stored rows using approved enum values â€” arithmetic on counts, not
on mastery semantics. Every such aggregate is enumerated in Â§8 with its exact
definition.

## 6. Mutation Boundary (normative prohibition matrix)

DASH-001 MUST NOT:

| # | Prohibited operation | Reason |
|---|---|---|
| X1 | modify `topic_mastery.*` (any column) | Adaptive-owned |
| X2 | modify `learner_profiles.overall_mastery` / `current_*` | Adaptive/Assessment-owned |
| X3 | insert/update/delete `recommendations` (including status flips to CONSUMED/EXPIRED) | Adaptive-owned; opening the Dashboard is NOT consumption (Adaptive Â§14 ties consumption to the submission pipeline only) |
| X4 | call Gemini or any HTTP client | no AI involvement whatsoever |
| X5 | write `xp_transactions`, `user_achievements`, `streaks`, or `learner_profiles.total_xp/current_level` | Gamification-owned |
| X6 | create assessment records or modify baselines | Assessment-owned |
| X7 | create/archive/generate learning paths; invoke PATH-002 logic | AI-LP-owned; absence of a path is a valid display state, never auto-generated |
| X8 | submit/evaluate quizzes; grade anything | Quiz pipeline-owned |
| X9 | write `progress` rows | no approved producer exists (Adaptive Â§13) |
| X10 | write `ai_interactions` rows | audit rows exist only for AI attempts (AI-LP Â§36); Dashboard makes none |

Compliance is test-enforced (DASH-TEST-023..027) and grep-verifiable: the
dashboard package contains no save/delete calls and no HTTP/AI client imports.

## 7. Request Contract (DASH-001)

| Aspect | Value | Class |
|---|---|---|
| Method & path | `GET /api/v1/dashboard` | DEFINED â€” CONTRACT (fixed API ID row; no other dashboard endpoint is authorized) |
| Auth | Bearer JWT, mandatory | DEFINED â€” CONTRACT |
| Identity | Server-side only: `AuthenticatedUser(id, email, displayName)` from SecurityContext (JwtAuthenticationFilter, DB-confirmed ACTIVE account) | DEFINED â€” CONVENTION (Phase 2) |
| Path params | none | DEFINED â€” CONTRACT |
| Query params | none accepted; any that are sent are IGNORED (no client-controlled userId can ever exist) | DEFINED â€” CONTRACT (Â§2.2 identity rule) |
| Request body | none; a body on GET is ignored | DEFINED â€” CONTRACT |
| Success | `200` + DashboardResponse (plain-DTO envelope, API Contract Â§2.3) | DEFINED â€” CONTRACT |
| Idempotency | naturally idempotent read; repeated calls return equivalent snapshots | DEFINED â€” CONVENTION |
| Transaction | single `@Transactional(readOnly = true)` service method | DEFINED â€” CONVENTION (mirrors GAM-001..003 reads) |
| Security config | NO change to `PUBLIC_ENDPOINTS`; `/api/v1/dashboard` is covered by `anyRequest().authenticated()` | DEFINED â€” CONVENTION (SecurityConfig, Phase 2) |

There is deliberately no variant of this endpoint that accepts a user
identifier: cross-user access is structurally impossible (Â§18).

## 8. Response Structure & Field Traceability (master table)

Finalized structure (after review of authoritative documents and the
implemented DTO conventions â€” plain records, lowerCamelCase, `Instant`
timestamps, string enums):

```
DashboardResponse
â”œâ”€â”€ learner          LearnerOverview          (always present)
â”œâ”€â”€ currentSubject   CurrentSubjectView|null  (null when profile has no current subject)
â”œâ”€â”€ mastery          MasterySummary           (always present)
â”œâ”€â”€ gamification     GamificationView         (always present)
â”œâ”€â”€ streak           StreakView               (always present)
â”œâ”€â”€ achievements     AchievementsView         (always present)
â”œâ”€â”€ recommendations  List<RecommendationItem> (always present; may be empty)
â”œâ”€â”€ learningPath     LearningPathCard|null    (null when no eligible ACTIVE path)
â”œâ”€â”€ assessment       AssessmentView           (always present)
â””â”€â”€ recentActivity   RecentActivityView       (always present)
```

Rules:

- ALL ten top-level keys are ALWAYS serialized (Jackson default includes
  nulls for success DTOs â€” matches GAM-001 behavior where
  `nextLevelThresholdXp: null` appears at max level). Absence of data is
  expressed as `null` / `[]`, NEVER as a missing key and NEVER as an error.
- No JPA entity is ever serialized (DB Spec Â§37). Nested identifiers use the
  established `xxxId` naming of UserResponse/LearningPathResponse.
- String enums reproduce the stored VARCHAR values exactly
  (e.g., `"PROFICIENT"`, `"REMEDIATION"`, `"ACTIVE"`).

### 8.1 `learner` â€” LearnerOverview

Purpose: identity greeting + headline mastery + resume pointers.

Field | JSON name | Java type | Source (column) | Derivation | Nullable | Class
---|---|---|---|---|---|---
Display name | `displayName` | String | `users.display_name` | verbatim | no | DEFINED â€” DB SPEC
Overall mastery | `overallMastery` | BigDecimal (2dp) | `learner_profiles.overall_mastery` | verbatim (mean of the learner's topic masteries, maintained by Adaptive Â§19 / Assessment Â§16 â€” Dashboard never recomputes) | no | DEFINED â€” APPROVED SPEC
Current subject pointer | `currentSubjectId` | UUID | `learner_profiles.current_subject_id` | verbatim | YES (null until first quiz or assessment) | DEFINED â€” APPROVED SPEC
Current topic pointer | `currentTopicId` | UUID | `learner_profiles.current_topic_id` | verbatim | YES (null until first processed quiz; ASMT never writes it â€” Assessment Â§14) | DEFINED â€” APPROVED SPEC

SECURITY: principal-scoped. Email, password hash, account status, IDs beyond
the above are NOT exposed (email minimization: USER-001 already offers it;
the Dashboard does not need it).

### 8.2 `currentSubject` â€” CurrentSubjectView (nullable)

Purpose: "continue where you left off" card.

Presence rule: non-null iff `learner_profiles.current_subject_id` is non-null
AND the referenced subject exists AND `subjects.is_active = true`; otherwise
`null` (Cases 6/7 â€” Â§13). Inactive-subject fallthrough to `null` prevents a
deactivated subject from being advertised.

Field | JSON name | Java type | Source | Nullable | Class
---|---|---|---|---|---|
Subject id | `id` | UUID | `subjects.id` (via profile pointer) | no | DEFINED â€” DB SPEC
Subject name | `name` | String | `subjects.name` | no | DEFINED â€” DB SPEC
Icon key | `iconKey` | String | `subjects.icon_key` | YES | DEFINED â€” DB SPEC
Current topic block | `currentTopic` | CurrentTopicView\|null | see below | YES | DEFINED â€” APPROVED SPEC

`currentTopic` (non-null iff `learner_profiles.current_topic_id` resolves to
an ACTIVE topic of THIS subject â€” Case 8 guard):

Field | JSON name | Source | Nullable
---|---|---|---
`topicId` | `topics.id` (via profile pointer) | no
`topicName` | `topics.name` | no
`difficulty` | `topics.difficulty` (EASY/MEDIUM/HARD verbatim) | no

Note: the profile's current-topic pointer may reference a topic whose row was
deactivated after the fact. Guard rule above yields `currentTopic: null`
while keeping the subject card; the raw pointer remains visible in
`learner.currentTopicId`.

### 8.3 `mastery` â€” MasterySummary

Purpose: at-a-glance coverage of the learner's per-topic mastery state.

Field | JSON name | Java type | Source | Exact derivation | Class
---|---|---|---|---|---
Topics assessed | `topicsAssessed` | int | `topic_mastery` rows of principal | `COUNT(*) WHERE user_id = :principal` | DEFINED â€” CONVENTION (row count; same input Gamification Â§7.1 COUNT predicate uses)
Topics mastered | `topicsMastered` | int | `topic_mastery.mastery_level` | `COUNT(*) WHERE user_id = :principal AND mastery_level = 'MASTERED'` | DEFINED â€” CONVENTION (approved enum value; Adaptive Â§8 defines what MASTERED means â€” Dashboard only counts)

`recentTopics` â€” JSON array `recentTopics`, max size **5**, element
`RecentTopicItem`:

Field | JSON name | Source (verbatim stored values)
---|---|---
`topicId` | `topic_mastery.topic_id`
`topicName` | `topics.name` (join)
`masteryScore` | `topic_mastery.mastery_score` (BigDecimal 2dp)
`masteryLevel` | `topic_mastery.mastery_level` (BEGINNER/DEVELOPING/PROFICIENT/MASTERED)
`currentDifficulty` | `topic_mastery.current_difficulty` (EASY/MEDIUM/HARD)
`trend` | `topic_mastery.trend` (IMPROVING/STABLE/DECLINING/INSUFFICIENT_DATA)
`lastAssessedAt` | `topic_mastery.last_assessed_at` (Instant, ISO-8601 UTC)

Ordering (deterministic): `last_assessed_at DESC NULLS LAST, topic_id ASC`.
Bound: 5 (Â§15). Empty when the learner has no mastery rows (new learner).

BOUNDARY: the Dashboard displays these values; it does NOT derive
`masteryLevel` from `masteryScore` itself, does not compute trends, and does
not rank "weak/strong" â€” such classifications remain Adaptive-owned
(Adaptive Â§8/Â§16; AI-LP Â§16/Â§17). Displaying a sorted list is presentation,
not pedagogy.

### 8.4 `gamification` â€” GamificationView

Purpose: XP/level headline. Values are byte-equivalent to the GAM-001 fields
computed from the same columns by the same approved rules (Gamification Â§6;
implemented `LevelEngine`).

Field | JSON name | Java type | Source | Nullable | Class
---|---|---|---|---|---
Total XP | `totalXp` | int | `learner_profiles.total_xp` | no | DEFINED â€” APPROVED SPEC
Current level | `currentLevel` | int | `learner_profiles.current_level` | no | DEFINED â€” APPROVED SPEC
Max level | `maxLevel` | int | constant 50 (`MAX_LEVEL`, Gamification Â§6.1) | no | DEFINED â€” APPROVED SPEC
Next threshold | `nextLevelThresholdXp` | Long | `T(currentLevel + 1)` per T(n)=50(nâˆ’1)n | **null at level 50** | DEFINED â€” APPROVED SPEC
XP to next level | `xpToNextLevel` | Integer | `max(0, threshold âˆ’ totalXp)` | **null at level 50** | DEFINED â€” APPROVED SPEC

Boundary compliance: at MAX_LEVEL 50 XP continues accumulating and remains
visible; level stays pinned; both next-level fields are `null` exactly as
approved for GAM-001 (Gamification Â§6.2, API Contract Â§5A.1). The Dashboard
does not invent a "prestige" or wrapped progress value.

### 8.5 `streak` â€” StreakView

Identical to the approved GAM-003 response shape and zero-state
(Gamification Â§8; API Contract Â§5A.1; implemented `StreakResponse`):

Field | JSON name | Java type | Source | Zero-state | Class
---|---|---|---|---|---
`currentStreakDays` | int | `streaks.current_streak_days` | 0 | DEFINED â€” APPROVED SPEC
`longestStreakDays` | int | `streaks.longest_streak_days` | 0 | DEFINED â€” APPROVED SPEC
`lastLearningDate` | LocalDate | `streaks.last_learning_date` | null | DEFINED â€” APPROVED SPEC
`timezone` | String | `streaks.timezone` (v1 always `"UTC"`) | `"UTC"` | DEFINED â€” APPROVED SPEC

Zero-state applies when no `streaks` row exists (never active). Timezone
semantics remain Gamification-owned (USER-002 is the designated future
input; Dashboard displays the stored value verbatim).

### 8.6 `achievements` â€” AchievementsView

Purpose: celebration + totals. The FULL catalog remains GAM-002's job; the
Dashboard carries the count and the most recent unlocks.

Field | JSON name | Java type | Source | Derivation | Class
---|---|---|---|---|---
Unlocked count | `unlockedCount` | long | `user_achievements` rows of principal | `COUNT(*) WHERE user_id = :principal` (same count GAM-001 exposes as `achievementCount`) | DEFINED â€” CONVENTION

`recentUnlocks` â€” JSON array, max size **5**, element `AchievementUnlockItem`,
ordered `unlocked_at DESC, achievement_id ASC`:

Field | JSON name | Source
---|---|---
`code` | `achievements.code`
`name` | `achievements.name`
`iconKey` | `achievements.icon_key`
`unlockedAt` | `user_achievements.unlocked_at` (Instant)

Empty array for a learner with zero unlocks. Locked achievements are NOT
listed here by design (catalog browsing = GAM-002); there is no "progress
toward locked achievement" concept in any approved specification and none is
invented.

### 8.7 `recommendations` â€” List\<RecommendationItem\>

Purpose: the Adaptive Engine's standing "what next" intents, surfaced
without mutation.

Selection: the principal's recommendations with `status = 'ACTIVE'`
ONLY. Ordering (deterministic, reuses the approved priority semantics and the
EXISTING repository finder
`findByUserIdAndStatusOrderByPriorityAscGeneratedAtDesc`): `priority ASC,
generated_at DESC, id ASC`. Bound: **3** (Â§15). The priority VALUES and their
meaning (lower = more urgent: REVIEW/REMEDIATION=1, PRACTICE=2, QUIZ=3,
ADVANCE=4) are Adaptive-owned (Adaptive Â§14/Â§23); the Dashboard merely sorts.

Element fields:

Field | JSON name | Java type | Source | Nullable | Class
---|---|---|---|---|---
`topicId` | UUID | `recommendations.topic_id` | YES (schema-nullable; Phase 5 always sets it â€” defensive null passthrough) | DEFINED â€” DB SPEC
`topicName` | String | `topics.name` (join; null when `topic_id` null) | YES | DEFINED â€” DB SPEC
`activityType` | String | `recommendations.activity_type` (CONTINUE_LESSON/PRACTICE/REVIEW/QUIZ/REMEDIATION/ADVANCE) | no | DEFINED â€” APPROVED SPEC
`recommendedDifficulty` | String | `recommendations.recommended_difficulty` | YES | DEFINED â€” DB SPEC
`priority` | int | `recommendations.priority` | no | DEFINED â€” APPROVED SPEC
`reason` | String | `recommendations.reason` (deterministic template text incl. reason code prefix â€” Adaptive Â§21) | YES | DEFINED â€” DB SPEC
`generatedAt` | Instant | `recommendations.generated_at` | no | DEFINED â€” DB SPEC

BOUNDARY: opening the Dashboard MUST NOT flip any recommendation to CONSUMED
(consumption happens exclusively in the quiz-submission pipeline, Adaptive
Â§14). An inactive/deactivated topic is still named (topics are never
deleted; `is_active=false` rows retain their name) â€” deactivation filtering
is a catalog-listing concern, not a history concern.

### 8.8 `learningPath` â€” LearningPathCard (nullable)

Purpose: the learner's active plan card.

Eligibility rule (**D1 â€” DEFINED, OWNER APPROVED 2026-08-24**):

1. If `learner_profiles.current_subject_id` is non-null AND an ACTIVE path
   exists for (principal, that subject): pick that path â€” latest
   `created_at DESC, id ASC` if several ACTIVE rows exist (schema permits
   multiple; AI-LP Â§9.1).
2. Else if any ACTIVE path exists for the principal in ANY subject: pick the
   most recent by `created_at DESC, id ASC`.
3. Else: `learningPath = null` (empty state â€” Â§11; NOTHING is generated, no
   PATH-002 logic runs, no ai_interactions row is written).

Element fields (mirror `LearningPathResponse`/`LearningNodeResponse`
shapes â€” AI-LP Â§35 â€” so Flutter renders the card with its existing path
components):

Field | JSON name | Source | Nullable
---|---|---|---
`id` | `learning_paths.id` | no
`subjectId` | `learning_paths.subject_id` | no
`subjectName` | `subjects.name` (join) | no
`title` | `learning_paths.title` | no
`status` | `learning_paths.status` (ACTIVE â€” eligibility guarantees it) | no
`generatedBy` | `learning_paths.generated_by` (AI/SYSTEM/HYBRID verbatim) | no
`createdAt` | `learning_paths.created_at` | no
`nodes` | array of `LearningNodeResponse`-shaped objects: `id, topicId, topicName, sequenceNumber, requiredMastery, status` from `learning_path_nodes` ordered `sequence_number ASC` | no (may be empty only if a path had zero nodes â€” impossible per AI-LP S5; defensive empty array)

Node count is inherently bounded (AI-LP D3: 3â€“10). No completion percentage
is derived from node statuses: status TRANSITIONS after creation are owned by
a future progression phase (AI-LP Â§3.2/Â§32) and today every non-first node is
still LOCKED â€” computing "% complete" from initial statuses would fabricate a
metric no specification defines (see Â§10.4).

### 8.9 `assessment` â€” AssessmentView

Purpose: placement-state visibility (which subjects already carry an
assessment baseline).

`assessedSubjects` â€” JSON array of `AssessedSubjectItem`, ordered
`display_order ASC, subject id ASC` (SUBJ-001 catalog ordering convention):

Field | JSON name | Source | Derivation | Class
---|---|---|---|---
`subjectId` | `subjects.id` | distinct subjects reachable from the principal's `topic_mastery` rows via `topic_mastery.topic_id â†’ topics.subject_id` | DEFINED â€” CONVENTION (exact R-GUARD lineage criterion, Assessment Â§11.4(a): baseline rows exist â‡” assessed)
`subjectName` | `subjects.name` | join | DEFINED â€” DB SPEC

Semantics: a subject appears here once ANY baseline lineage exists for it
(even a single assessed topic). This is precisely the "baseline mastery
available" state of the Assessment domain (ASMT-003 `assessed:true`
criterion), aggregated across subjects. The complementary states map cleanly:

| Approved assessment state | Dashboard expression |
|---|---|
| not completed (no lineage anywhere) | `assessedSubjects: []` |
| completed for subject S | S present in `assessedSubjects` |

The Dashboard does NOT distinguish "assessed via ASMT-002" from "lineage
established by first quiz": both write the same `topic_mastery` state by
design (Assessment Â§10: indistinguishable downstream), so no additional
distinction is possible without inventing new state. Correct answers,
question contents, scores-per-assessment and accuracy histories are NEVER
exposed (none are stored; Assessment Â§14 â€” no result store exists).

### 8.10 `recentActivity` â€” RecentActivityView

Evaluated against every approved data source (task mandate Â§"RECENT
ACTIVITY"):

| Candidate source | Verdict |
|---|---|
| `quiz_attempts` (COMPLETED) | USABLE â€” single-table event stream with native timestamp `submitted_at` |
| `xp_transactions` | usable but REDUNDANT with quiz/achievement/streak sources; mixing types creates a cross-domain ordering question no specification answers |
| `user_achievements` (unlock moments) | usable but heterogeneous ordering vs quizzes = undefined semantic |
| streak events | NOT an event log â€” milestone bonuses live inside `xp_transactions`; no standalone stream |
| lesson completions | IMPOSSIBLE â€” no producer exists (LESSON_COMPLETED RESERVED; Adaptive D8 deferred) |
| assessment submissions | NOT STORED as events (stateless; Assessment Â§4) |

Decision (owner decision **D2**): v1 ships a SINGLE-SOURCE feed â€” recent
completed quizzes â€” which requires NO cross-domain ordering invention, plus
an explicit refusal to build a unified activity model until an owner rules
on its semantics (future decision).

`quizzes` â€” JSON array, max size **5**, ordered `submitted_at DESC,
quiz_attempt id ASC`, element `RecentQuizItem`:

Field | JSON name | Java type | Source | Nullable
---|---|---|---|---
`quizAttemptId` | UUID | `quiz_attempts.id` | no
`topicId` | UUID | `quiz_attempts.quiz_id â†’ quizzes.topic_id` | no
`topicName` | String | `topics.name` (join) | no
`score` | BigDecimal 2dp | `quiz_attempts.score` | no
`correctCount` | int | `quiz_attempts.correct_count` | no
`totalQuestions` | int | `quiz_attempts.total_questions` | no
`submittedAt` | Instant | `quiz_attempts.submitted_at` | no (COMPLETED filter guarantees it; defensive nulls-last ordering retained)

Only `status = 'COMPLETED'` attempts are listed (IN_PROGRESS/ABANDONED are
excluded â€” consistent with Adaptive Â§6.2 evidence semantics). ABANDONED
attempts are therefore invisible here BY DESIGN.

## 9. Mandatory vs Optional Sections

| Section | Presence | Empty representation |
|---|---|---|
| learner, mastery, gamification, streak, achievements, recommendations, assessment, recentActivity | ALWAYS present | counts 0 / arrays `[]` |
| currentSubject | nullable object | `null` |
| learningPath | nullable object | `null` |

A Dashboard response is NEVER an error merely because optional learner data
is absent (Â§11).

## 10. Derived-Value Rules (complete enumeration)

Every value that is not a verbatim column copy:

| # | Derived value | Exact rule | Why legal |
|---|---|---|---|
| V1 | `nextLevelThresholdXp` / `xpToNextLevel` | T(n)=50(nâˆ’1)n; null at 50 | approved Gamification Â§6; identical to GAM-001 |
| V2 | `topicsAssessed` | COUNT of principal's topic_mastery rows | row counting, no mastery math |
| V3 | `topicsMastered` | COUNT where mastery_level='MASTERED' | approved enum value as filter |
| V4 | `unlockedCount` | COUNT of principal's user_achievement rows | identical to GAM-001 `achievementCount` |
| V5 | ordering of `recentTopics` / `recentUnlocks` / `quizzes` / `recommendations` | fixed deterministic sort keys (Â§8.3/Â§8.6/Â§8.7/Â§8.10) | presentation ordering over stored timestamps/priorities |
| V6 | `learningPath` selection | D1 rule | owner decision (this document) |
| V7 | `assessedSubjects` projection | DISTINCT subject via topic_mastery lineage | R-GUARD criterion reused verbatim |
| V8 | `currentSubject`/`currentTopic` resolution + active guards | pointer dereference with is_active guard | safety, no semantics change |

NOT derived (deliberately): completion percentages, weak/strong
classifications, readiness scores, activity streak projections, "days since
last quiz", health scores, notification flags. None has an approved
definition; each would be invented mathematics.

### 10.4 Progress boundary â€” explicit unavailability ruling

`progress.completion_percentage` has NO approved derivation (Adaptive Â§13
DEFERRED; no producer writes `progress` rows in Phases 1â€“8). Therefore the
Dashboard exposes **NO progress section and NO completion metric of any
kind**. Learning-progress visibility is carried by: mastery counts (Â§8.3),
path node statuses (Â§8.8), and assessment coverage (Â§8.9) â€” all approved
state. When a future specification defines completion semantics, a Dashboard
amendment may add them; until then any percentage here would be fabricated.
Marked: **completion metrics UNAVAILABLE/DEFERRED â€” REQUIRES FUTURE OWNER
SPECIFICATION (successor of Adaptive D8)**.
**RATIFIED (owner, 2026-08-24):** no completion percentage, lesson/topic/
course completion metric, or progress formula may be introduced by the
Dashboard until such a specification exists.

### 10.7 Unified activity feed â€” explicit non-invention ruling

A merged cross-type feed (quizzes + unlocks + streak milestones + future
lessons) requires an ordering/semantic decision across heterogeneous events
that no approved document supplies. It is NOT built. Recorded as future
owner decision space (D2 context). The single-source quiz feed (Â§8.10) needs
no such decision.

## 11. New-Learner Behavior (zero state â€” normative example)

Registration atomically creates `users` + `learner_profiles` (Phase 2
guarantee; profile row missing otherwise â‡’ 500 INTERNAL_ERROR, mirroring
GAM-001's defensive posture). Everything else starts absent. Exact response:
see Â§23.1. Properties:

| Value | New-learner state |
|---|---|
| learner.displayName | registration value |
| learner.overallMastery | `0.00` (column default) |
| learner.currentSubjectId / currentTopicId | `null` / `null` |
| currentSubject | `null` |
| mastery.topicsAssessed / topicsMastered / recentTopics | `0` / `0` / `[]` |
| gamification | totalXp `0`, currentLevel `1`, maxLevel `50`, nextThreshold `100`, xpToNext `100` |
| streak | `{0, 0, null, "UTC"}` |
| achievements.unlockedCount / recentUnlocks | `0` / `[]` |
| recommendations | `[]` |
| learningPath | `null` (never auto-generated â€” X7) |
| assessment.assessedSubjects | `[]` |
| recentActivity.quizzes | `[]` |

HTTP status: `200`. The Dashboard MUST NOT fail (500) because optional data
is absent; absence IS the valid zero state (mirrors GAM Â§12 zero-state rule).

## 12. Post-Assessment / Post-Quiz Behavior (informational)

- After ASMT-002: baseline `topic_mastery` rows exist (EASY / INSUFFICIENT_DATA /
  attempt_count 1), `learner_profiles.overall_mastery > 0`,
  `current_subject_id` set, `current_topic_id` STILL null (Assessment Â§14),
  zero recommendations (A6), zero XP/streak events (A7). Dashboard reflects
  exactly that â€” see Â§23.3.
- After QUIZ-002 submissions: mastery/trend/difficulty values evolve by
  approved formulas; ACTIVE recommendations appear (one per touched topic);
  XP/streaks/achievements evolve; `current_topic_id`/`current_subject_id`
  point at the last processed quiz's topic (Adaptive Â§19). Dashboard displays
  the results verbatim.

## 13. Partially Initialized Learner â€” Deterministic Behavior Matrix

| Case | State | Dashboard behavior |
|---|---|---|
| 1 | Assessment completed, no quiz afterwards | mastery counts > 0 with baseline rows; `recentTopics` shows EASY/INSUFFICIENT_DATA entries; `recommendations: []`; `recentActivity.quizzes: []`; `streak` zero-state; `currentTopic` null (pointer unset) |
| 2 | Quiz activity exists, no ACTIVE recommendation | possible transiently only if all recommendations were superseded/consumed without replacement â€” impossible under Adaptive Â§14 supersede+insert (every processed attempt leaves exactly one ACTIVE per touched topic); defensively `[]` |
| 3 | Gamification exists, no learning path | gamification/streak/achievements populated; `learningPath: null` |
| 4 | Learning path exists, no recent quiz | `learningPath` card rendered; `recentActivity.quizzes: []`; `recommendations: []` (paths never generate recommendations) |
| 5 | Some topics have mastery, others not | `recentTopics` lists only existing rows; counts reflect existing rows; unassessed topics are simply absent (no zero-rows fabricated) |
| 6 | Subject has no active topics | `currentSubject` guard: subject inactive OR (if active but empty) still renders name/icon; `learningPath` falls through D1 step 2 (no ACTIVE path can exist for an empty subject â€” AI-LP LP26 blocks generation) |
| 7 | `current_subject_id` IS null | `currentSubject: null`; `learningPath` D1 step 2 (any-ACTIVE fallback) still applies; `learner.currentSubjectId: null` |
| 8 | Current subject set, `current_topic_id` null | subject card renders; `currentTopic: null` (typical post-assessment state) |

## 14. Ordering Rules (complete register)

| Collection | Order | Tie-break | Source of keys |
|---|---|---|---|
| recommendations | `priority ASC` | `generated_at DESC`, then `id ASC` | approved priority semantics (Adaptive Â§14) |
| mastery.recentTopics | `last_assessed_at DESC` (nulls last) | `topic_id ASC` | stored timestamps |
| achievements.recentUnlocks | `unlocked_at DESC` | `achievement_id ASC` | stored timestamps |
| recentActivity.quizzes | `submitted_at DESC` (nulls last) | `quiz_attempt id ASC` | stored timestamps |
| learningPath.nodes | `sequence_number ASC` | â€” (unique per path) | schema constraint |
| assessment.assessedSubjects | `display_order ASC` | `subject id ASC` | SUBJ-001 catalog convention |

All orderings are TOTAL (no ambiguity) and stable across repeated calls on
unchanged data (test DASH-TEST-021).

## 15. Collection Limits

| Collection | Limit | Rationale |
|---|---|---|
| recommendations | 3 | home-screen "next steps" strip; full list remains available via future need â€” Adaptive keeps â‰¤1 ACTIVE per touched topic, so 3 covers 3 concurrently-active topics |
| mastery.recentTopics | 5 | glanceable strip |
| achievements.recentUnlocks | 5 | glanceable strip; catalog = GAM-002 |
| recentActivity.quizzes | 5 | glanceable strip |
| learningPath.nodes | unbounded field, inherently â‰¤10 | AI-LP D3 hard cap |

Limits are compiled constants in the dashboard implementation (Gamification/
Adaptive constant-class convention; NOT runtime-configurable â€” no silent
drift).

## 16. Visibility Rules â€” What Flutter May and May NOT See

EXPOSED: only the fields of Â§8 â€” the learner's own aggregates and stored
display values, including machine-readable reason strings of recommendations
(already learner-facing via QUIZ-002's adaptive block, Adaptive Â§26).

MUST NEVER be exposed (each violates an approved rule):

| Forbidden | Rule violated |
|---|---|
| password hash, account status, email | Backend Â§32/DB Â§7 (email excluded by minimization even though USER-001 shows it) |
| JWTs, API keys, DB credentials, env values | Backend Â§33 |
| Gemini internals: prompts, model names, latency, raw responses, prompt versions | AI-LP Â§19/Â§35.2 |
| `ai_interactions` rows or counts | AI-LP audit is internal |
| another learner's ANYTHING | principal scoping (Â§18) |
| correct answers / explanations of any question | QUIZ-001 redaction; Assessment Â§5 |
| internal rule configs (`rule_config_json`) | Gamification Â§7 â€” mechanics are server-side |
| XP award internals beyond ledger-derived aggregates (none exposed anyway) | Gamification Â§15 |
| completion percentages (undefined) | Â§10.4 |
| `progress` rows (no approved producer; empty by construction) | Â§10.4 |

## 17. Authentication & Authorization

- Anonymous request â‡’ `401 UNAUTHORIZED` via the standard safe error envelope
  produced by `RestAuthenticationEntryPoint` (Phase 2; verified convention).
- Suspended/expired-token/account-not-ACTIVE â‡’ same `401` (filter behavior).
- There is no role model (Phase 2 has none); every authenticated principal
  may read exactly their own dashboard. `403 FORBIDDEN` is therefore
  unreachable for DASH-001 and reserved.
- Authorization = implicit ownership: EVERY repository access filters by
  `principal.id()`. No code path accepts a user identifier from the wire.
  Cross-user leakage is structurally impossible and proven by tests
  (DASH-TEST-003, two-user fixtures both directions).

## 18. Security Review Checklist

| Check | Verdict |
|---|---|
| No client-controllable identity/scoping parameter | PASS (no parameters exist) |
| Repository queries principal-scoped | PASS (mandated; test-enforced) |
| SQL injection | PASS (Spring Data derived/parameterized only) |
| Secret/PII leakage in response | PASS (Â§16 allowlist) |
| Secret/PII leakage in logs | PASS (log only requestId + section-count summary; never emails/display names/values) |
| Information disclosure via error messages | PASS (registry envelope; Â§19) |
| Enumeration | PASS (no resource identifiers in the request; nothing to enumerate) |
| IDOR | PASS (no identifier accepted) |
| Mass assignment | PASS (no request body) |
| New attack surface added | NONE (read-only, parameterless) |

## 19. Error Contract

Uses the EXISTING registry exclusively (API Contract Â§4). NO new codes.

| Situation | HTTP | errorCode | Notes |
|---|---|---|---|
| Missing/invalid/expired token, suspended account | 401 | UNAUTHORIZED | standard entry-point envelope |
| Unexpected internal failure | 500 | INTERNAL_ERROR | full response withheld; safe envelope; requestId correlates logs |
| Wrong method (e.g., POST /api/v1/dashboard) | 405 | METHOD_NOT_ALLOWED | framework mapping |
| Unsupported media type | 415 | UNSUPPORTED_MEDIA_TYPE | framework mapping (body ignored, but kept for registry completeness) |

Explicitly NOT reachable and therefore NOT returned:

- `400 VALIDATION_FAILED` / `MALFORMED_REQUEST` â€” no parameters/body exist to validate.
- `404 RESOURCE_NOT_FOUND` â€” the dashboard of an authenticated principal
  always exists (profile guaranteed by registration; optional domains degrade
  to empty states, Â§11/Â§13). A missing PROFILE row is a data invariant
  violation â‡’ 500 (defensive, mirrors GAM-001).
- `409 DATA_CONFLICT` â€” read-only endpoint.
- All `AI_*` codes â€” no AI involvement (X4).

Error envelope example (Â§23.7). `fieldErrors` always absent for DASH-001.

## 20. Performance

Constraints (v1, honest to the project's single-instance hackathon scale):

| Rule | Value |
|---|---|
| Transaction | one `@Transactional(readOnly = true)` |
| Query budget | â‰¤ ~12 targeted SELECTs per request (profile, user, subject+topic pointers, mastery rows(+join names), recommendations(+names), active paths+nodes(+names), unlock join, streak, attempt page, distinct assessed subjects) |
| N+1 | forbidden â€” topic/subject names resolved via join-fetch or batched IN queries, not lazy per-row lookups (test DASH-TEST-028 asserts bounded query count) |
| Result bounds | Â§15 limits; payload typically < 10 KB |
| External calls | ZERO network I/O of any kind (grep-verifiable: no HTTP/AI clients in dashboard code) |
| Locks | none (consistent reads suffice; no `findWithLock` in the dashboard path) |
| Indexes | served entirely by existing indexes (DB Spec Â§29: topic_mastery(user_id,topic_id), recommendations(user_id,status), xp/user_achievement(user_id,â€¦), quiz_attempts(user_id,submitted_at), learning_paths(user_id,subject_id)) â€” no new index required |
| Caching | NONE mandated (not part of the approved architecture). Recorded as a FUTURE optimization requiring its own contract amendment if ever wanted |
| Target latency | soft target p95 < 300 ms on local dev hardware; informational, not SLA |

## 21. Database Mapping Summary

READ-ONLY access to: `users`, `learner_profiles`, `subjects`, `topics`,
`topic_mastery`, `recommendations`, `achievements`, `user_achievements`,
`streaks`, `quiz_attempts`, `quizzes`, `learning_paths`,
`learning_path_nodes`. WRITE access to: NOTHING.

**DATABASE COMPATIBILITY: PASS â€” zero new tables, zero new columns, zero new
enums, zero migrations.** Implementation may ADD Spring Data DERIVED finder
methods (e.g., paged/ordered attempt lookup, distinct-subject projection) â€”
these are code, not schema. No native SQL, no views, no stored procedures.

Enum usage: existing values only, compared as strings; NO enum created or
altered.

## 22. API Contract Amendment (v1.3.0 â€” prepared, Â§"5C")

Prepared concurrently with this specification in
GameLearn_AI_API_Contract.md:

- Â§3 matrix row DASH-001: status â†’ **APPROVED â€” PENDING IMPLEMENTATION**
  (behavioral authority: this document).
- New Â§5C: binding request/response/error summary + pointer to this
  specification as full behavioral authority (pattern of Â§5A/Â§5B).
- Amendment history entry 1.3.0. All other rows untouched.

Owner approval of this specification (2026-08-24) makes the v1.3.0
amendment EFFECTIVE; DASH-001 status is APPROVED â€” PENDING IMPLEMENTATION
(Phase 9B).

Observed (NOT fixed here, out of Phase 9A mandate): the Â§3 status column
still reads "APPROVED â€” PENDING IMPLEMENTATION" for GAM-001..003 and
ASMT-001..003 although Phases 7â€“8 are implemented and regression-green; the
owner may refresh those labels in a housekeeping amendment. No normative
text depends on the stale labels.

## 23. JSON Examples (normative shapes)

### 23.1 New learner (zero state)

```json
{
  "learner": {
    "displayName": "Alex",
    "overallMastery": 0.00,
    "currentSubjectId": null,
    "currentTopicId": null
  },
  "currentSubject": null,
  "mastery": {
    "topicsAssessed": 0,
    "topicsMastered": 0,
    "recentTopics": []
  },
  "gamification": {
    "totalXp": 0,
    "currentLevel": 1,
    "maxLevel": 50,
    "nextLevelThresholdXp": 100,
    "xpToNextLevel": 100
  },
  "streak": {
    "currentStreakDays": 0,
    "longestStreakDays": 0,
    "lastLearningDate": null,
    "timezone": "UTC"
  },
  "achievements": {
    "unlockedCount": 0,
    "recentUnlocks": []
  },
  "recommendations": [],
  "learningPath": null,
  "assessment": { "assessedSubjects": [] },
  "recentActivity": { "quizzes": [] }
}
```

### 23.2 Fully active learner

```json
{
  "learner": {
    "displayName": "Alex",
    "overallMastery": 61.11,
    "currentSubjectId": "11111111-1111-1111-1111-111111111101",
    "currentTopicId": "22222222-1111-1111-1111-111111111101"
  },
  "currentSubject": {
    "id": "11111111-1111-1111-1111-111111111101",
    "name": "Programming",
    "iconKey": "subject_programming",
    "currentTopic": {
      "topicId": "22222222-1111-1111-1111-111111111101",
      "topicName": "Variables & Types",
      "difficulty": "EASY"
    }
  },
  "mastery": {
    "topicsAssessed": 3,
    "topicsMastered": 1,
    "recentTopics": [
      { "topicId": "22222222-â€¦-01", "topicName": "Variables & Types",
        "masteryScore": 61.11, "masteryLevel": "DEVELOPING",
        "currentDifficulty": "MEDIUM", "trend": "DECLINING",
        "lastAssessedAt": "2026-08-24T09:12:44Z" },
      { "topicId": "22222222-â€¦-02", "topicName": "Control Flow",
        "masteryScore": 91.67, "masteryLevel": "MASTERED",
        "currentDifficulty": "HARD", "trend": "IMPROVING",
        "lastAssessedAt": "2026-08-23T18:02:10Z" }
    ]
  },
  "gamification": {
    "totalXp": 325,
    "currentLevel": 3,
    "maxLevel": 50,
    "nextLevelThresholdXp": 600,
    "xpToNextLevel": 276
  },
  "streak": {
    "currentStreakDays": 3,
    "longestStreakDays": 5,
    "lastLearningDate": "2026-08-24",
    "timezone": "UTC"
  },
  "achievements": {
    "unlockedCount": 2,
    "recentUnlocks": [
      { "code": "STREAK_3", "name": "Three-Day Rhythm",
        "iconKey": "ach_streak_3", "unlockedAt": "2026-08-24T09:12:45Z" },
      { "code": "FIRST_QUIZ", "name": "First Steps",
        "iconKey": "ach_first_quiz", "unlockedAt": "2026-08-20T17:41:03Z" }
    ]
  },
  "recommendations": [
    { "topicId": "22222222-â€¦-01", "topicName": "Variables & Types",
      "activityType": "REMEDIATION", "recommendedDifficulty": "EASY",
      "priority": 1,
      "reason": "RECENT_DECLINE_REMEDIATION: Recent results dropped â€” targeted remediation for Variables & Types.",
      "generatedAt": "2026-08-24T09:12:45Z" },
    { "topicId": "22222222-â€¦-02", "topicName": "Control Flow",
      "activityType": "ADVANCE", "recommendedDifficulty": "HARD",
      "priority": 4,
      "reason": "MASTERED_ADVANCE_CHALLENGE: Topic mastered â€” ready for a bigger challenge.",
      "generatedAt": "2026-08-23T18:02:11Z" }
  ],
  "learningPath": {
    "id": "0b6f1a2b-â€¦",
    "subjectId": "11111111-â€¦-101",
    "subjectName": "Programming",
    "title": "Programming Foundations Sprint",
    "status": "ACTIVE",
    "generatedBy": "AI",
    "createdAt": "2026-08-21T10:00:00Z",
    "nodes": [
      { "id": "node-1", "topicId": "22222222-â€¦-01",
        "topicName": "Variables & Types", "sequenceNumber": 1,
        "requiredMastery": 0.00, "status": "AVAILABLE" },
      { "id": "node-2", "topicId": "22222222-â€¦-02",
        "topicName": "Control Flow", "sequenceNumber": 2,
        "requiredMastery": 40.00, "status": "LOCKED" }
    ]
  },
  "assessment": {
    "assessedSubjects": [
      { "subjectId": "11111111-â€¦-101", "subjectName": "Programming" }
    ]
  },
  "recentActivity": {
    "quizzes": [
      { "quizAttemptId": "aaa-â€¦", "topicId": "22222222-â€¦-01",
        "topicName": "Variables & Types", "score": 33.33,
        "correctCount": 1, "totalQuestions": 3,
        "submittedAt": "2026-08-24T09:12:44Z" },
      { "quizAttemptId": "bbb-â€¦", "topicId": "22222222-â€¦-02",
        "topicName": "Control Flow", "score": 100.00,
        "correctCount": 4, "totalQuestions": 4,
        "submittedAt": "2026-08-23T18:02:10Z" }
    ]
  }
}
```

(UUIDs abbreviated with `â€¦` for readability only; real payloads carry full
UUID strings.)

### 23.3 Partially initialized learner (assessment completed, no quiz yet â€” Case 1/8)

```json
{
  "learner": {
    "displayName": "Alex",
    "overallMastery": 66.67,
    "currentSubjectId": "11111111-â€¦-102",
    "currentTopicId": null
  },
  "currentSubject": {
    "id": "11111111-â€¦-102",
    "name": "Computer Networks",
    "iconKey": "subject_networks",
    "currentTopic": null
  },
  "mastery": {
    "topicsAssessed": 2,
    "topicsMastered": 1,
    "recentTopics": [
      { "topicId": "t-a", "topicName": "OSI Model",
        "masteryScore": 100.00, "masteryLevel": "MASTERED",
        "currentDifficulty": "EASY", "trend": "INSUFFICIENT_DATA",
        "lastAssessedAt": "2026-08-24T08:00:00Z" },
      { "topicId": "t-b", "topicName": "IP Addressing",
        "masteryScore": 33.33, "masteryLevel": "BEGINNER",
        "currentDifficulty": "EASY", "trend": "INSUFFICIENT_DATA",
        "lastAssessedAt": "2026-08-24T08:00:00Z" }
    ]
  },
  "gamification": { "totalXp": 0, "currentLevel": 1, "maxLevel": 50,
    "nextLevelThresholdXp": 100, "xpToNextLevel": 100 },
  "streak": { "currentStreakDays": 0, "longestStreakDays": 0,
    "lastLearningDate": null, "timezone": "UTC" },
  "achievements": { "unlockedCount": 0, "recentUnlocks": [] },
  "recommendations": [],
  "learningPath": null,
  "assessment": { "assessedSubjects": [
      { "subjectId": "11111111-â€¦-102", "subjectName": "Computer Networks" } ] },
  "recentActivity": { "quizzes": [] }
}
```

### 23.4 No active learning path

Identical to any state above with `"learningPath": null` (e.g., Â§23.3).
Nothing else changes; no generation occurs.

### 23.5 No recommendations

`"recommendations": []` (typical: pre-first-quiz, or Case 2 defensive).
Everything else unaffected.

### 23.6 Maximum-level learner (level 50)

```json
"gamification": {
  "totalXp": 130000,
  "currentLevel": 50,
  "maxLevel": 50,
  "nextLevelThresholdXp": null,
  "xpToNextLevel": null
}
```

XP keeps accumulating (130000 â‰¥ T(50)=122500); both next-level fields are
`null`; all other sections normal. (Full response = Â§23.2 with this block.)

### 23.7 Error envelopes

401 (anonymous):

```json
{
  "timestamp": "2026-08-24T12:00:00Z",
  "status": 401,
  "errorCode": "UNAUTHORIZED",
  "message": "Authentication required",
  "path": "/api/v1/dashboard",
  "requestId": "b7c9d1e0-4f2a-4c3e-9a51-77f2b0d3e8a1"
}
```

500 (unexpected; safe envelope):

```json
{
  "timestamp": "2026-08-24T12:00:00Z",
  "status": 500,
  "errorCode": "INTERNAL_ERROR",
  "message": "An unexpected internal error occurred",
  "path": "/api/v1/dashboard",
  "requestId": "0f3eâ€¦"
}
```

## 24. Compatibility Verdicts

| Document | Verdict | Evidence |
|---|---|---|
| Database Specification | **COMPATIBLE â€” PASS** | Â§21: read-only over existing tables/columns/enums/indexes; zero DDL |
| Backend + AI Specification | COMPATIBLE â€” PASS | Â§11 fixed the DASH-001 id/path/auth row; Â§12 lists DashboardResponse as planned DTO; thin-controller/DTO/entity rules honored |
| Adaptive Engine Specification | **COMPATIBLE â€” PASS** | consumes stored outputs verbatim; no formula/threshold/priority touched; recommendation display honors Â§14 semantics without mutation; D8 deferral respected (Â§10.4) |
| Learning Path AI Specification | COMPATIBLE â€” PASS | displays caller-owned ACTIVE paths only; no generation/regeneration/archival; aiMetadata NOT surfaced (it exists only on the generation response, never persisted â€” Â§35.2); node shape mirrors LearningNodeResponse |
| Gamification Specification | **COMPATIBLE â€” PASS** | GAM-field parity incl. max-level nulls; zero-state parity; no award/streak/level logic duplicated or triggered |
| Assessment Specification | COMPATIBLE â€” PASS | assessed-lineage criterion reused verbatim (R-GUARD Â§11.4(a)); no reassessment trigger, no score exposure, A6/A7 respected |
| API Contract v1.2.0 | COMPATIBLE â€” PASS | additive v1.3.0 amendment prepared; plain-DTO envelope; error registry unchanged; no breaking change to any existing row |

CONTRACT/SPECIFICATION CONFLICTS DISCOVERED: **NONE.** (Observation only:
stale Â§3 status labels for implemented GAM/ASMT rows â€” Â§22; non-normative.)

## 25. Test Matrix (implementation phase 9B â€” specified NOW, written THEN)

Legend: setup describes seeded fixture state; all MockMvc/integration tests
run against H2 with the standard security test conventions of Phases 2â€“8.
Persistence column = assertions on database state AFTER the call.

| ID | Setup | Action / Input | Expected | Persistence |
|---|---|---|---|---|
| DASH-TEST-001 | registered learner, valid token | GET /api/v1/dashboard | 200; body matches Â§23 shapes; all ten keys present | zero writes |
| DASH-TEST-002 | â€” | GET without token | 401 UNAUTHORIZED envelope (Â§23.7) | zero writes |
| DASH-TEST-003 | two learners A,B with distinct data | A requests; then B requests | each sees ONLY own displayName/mastery/xp/path; A's ids never in B's body and vice versa | zero writes |
| DASH-TEST-004 | brand-new learner (no activity) | GET | exact Â§23.1 zero state; 200 | zero writes |
| DASH-TEST-005 | ASMT-002 completed (baselines exist) | GET | mastery rows reflected (EASY/INSUFFICIENT_DATA); overallMastery = profile mean; assessedSubjects contains subject; recommendations/quizzes empty | zero writes |
| DASH-TEST-006 | â‰¥1 COMPLETED quiz attempt | GET | recentActivity.quizzes[0] equals newest attempt (score/topic/timestamp); attempt visible | zero writes |
| DASH-TEST-007 | mastery rows with mixed scores/levels | GET | recentTopics values byte-equal stored columns (no recomputation) | zero writes |
| DASH-TEST-008 | mastery rows incl. HARD/MEDIUM/EASY difficulties | GET | currentDifficulty echoed verbatim per topic | zero writes |
| DASH-TEST-009 | XP awarded (ledger + profile totals) | GET | gamification block equals GAM-001 computation for same state | zero writes |
| DASH-TEST-010 | totalXp â‰¥ 122500 (force level 50) | GET | currentLevel 50, maxLevel 50, nextLevelThresholdXp null, xpToNextLevel null, totalXp intact | zero writes |
| DASH-TEST-011 | streak row {cur 3, longest 5, date, UTC} | GET | streak block mirrors row; zero-state learner gets {0,0,null,"UTC"} | zero writes |
| DASH-TEST-012 | 2 unlocks + locked catalog entries | GET | unlockedCount 2; recentUnlocks newest-first; locked entries ABSENT | zero writes |
| DASH-TEST-013 | 2+ ACTIVE recommendations (priorities 1,4) | GET | ordered priority ASC; fields verbatim incl. reason strings | zero writes |
| DASH-TEST-014 | ACTIVE path for current subject (+nodes) | GET | learningPath card = that path; nodes sequence ASC; subjectName joined | zero writes |
| DASH-TEST-015 | no ACTIVE path (archived/completed only) | GET | learningPath null; archived paths never resurrected | zero writes |
| DASH-TEST-016 | no ACTIVE recommendations (fresh learner) | GET | recommendations [] | zero writes |
| DASH-TEST-017 | partial state (Cases 1â€“8 fixtures) | GET | per-case behavior exactly as Â§13 matrix | zero writes |
| DASH-TEST-018 | learner with mastery in 2 subjects | GET | assessedSubjects lists both; catalog order (display_order, id) | zero writes |
| DASH-TEST-019 | current_subject_id null | GET | currentSubject null; learner.currentSubjectId null; rest populated normally | zero writes |
| DASH-TEST-020 | current subject inactive (is_active=false flipped) | GET | currentSubject null (guard) | zero writes |
| DASH-TEST-021 | identical data, two consecutive calls | GET Ã—2 | bodies identical (deterministic ordering) | zero writes |
| DASH-TEST-022 | 6+ recommendations/topics/attempts seeded | GET | collections capped at Â§15 limits (3/5/5/5) | zero writes |
| DASH-TEST-023 | state-rich learner | GET, then diff ALL adaptive tables | topic_mastery/learner_profiles(mastery-side)/recommendations byte-identical | NO adaptive mutation |
| DASH-TEST-024 | same | diff gamification tables | xp_transactions/user_achievements/streaks/profile xp+level identical | NO gamification mutation |
| DASH-TEST-025 | same | diff recommendations | statuses still ACTIVE; consumed_at unchanged | NO recommendation mutation |
| DASH-TEST-026 | same | diff learning-path tables | learning_paths/nodes identical | NO path mutation |
| DASH-TEST-027 | GeminiClient fake wired (counts invocations) | GET | ZERO invocations; zero ai_interactions rows | NO AI activity |
| DASH-TEST-028 | query-count instrumentation (datasource proxy/Hibernate statistics) | GET | SELECT count â‰¤ budget (Â§20); no N+1 growth when seeding 3Ã— more data | â€” |
| DASH-TEST-029 | rich fixture | GET; assert EVERY field of Â§8 | exact JSON names/types/nullability; unknown-field scan both ways | â€” |
| DASH-TEST-030 | force RuntimeException in service | GET | 500 INTERNAL_ERROR safe envelope; requestId present; no stack/internal detail | rollback-safe (read-only tx) |
| DASH-TEST-031 | expired/garbled token | GET | 401 (not 500) | â€” |
| DASH-TEST-032 | POST/PUT/DELETE /api/v1/dashboard | request | 405 METHOD_NOT_ALLOWED | â€” |
| DASH-TEST-033 | attempt with status ABANDONED / IN_PROGRESS | GET | excluded from recentActivity | zero writes |
| DASH-TEST-034 | recommendation whose topic_id is NULL (defensive fixture) | GET | element present with topicId/topicName null; ordering intact | zero writes |
| DASH-TEST-035 | suspended account token (post-issue suspension) | GET | 401 | â€” |
| DASH-TEST-036 | Swagger/OpenAPI snapshot | GET /v3/api-docs | DASH-001 documented with response schema; no extra dashboard routes | â€” |

Additional cases beyond the mandated 30: DASH-TEST-031..036 (token classes,
method guard, attempt-status filter, defensive null topic, suspension,
OpenAPI surface). Acceptance for Phase 9B = DASH-TEST-001..036 green +
FULL Phase 0â€“8 regression green (â‰¥266 tests).

## 26. Edge Cases Register

| ID | Case | Disposition |
|---|---|---|
| E1 | profile row missing (invariant violation) | 500 INTERNAL_ERROR (defensive; mirrors GAM-001) |
| E2 | multiple ACTIVE paths same subject | D1 picks latest created_at, id ASC; others untouched |
| E3 | path with deactivated topic in nodes | node still rendered (history preserved; topics never deleted); topicName from stored row |
| E4 | recommendation referencing deactivated topic | rendered with stored name (Â§8.7 note) |
| E5 | last_assessed_at null (defensive; producers always set it) | sorts last; value null in JSON |
| E6 | clock skew / future submitted_at | ordered by stored value verbatim; no clamping invented |
| E7 | very large catalogs (many subjects/topics) | bounds Â§15 + query budget hold; no pagination needed at MVP scale |
| E8 | learner with hundreds of attempts | recentActivity capped at 5; DB index (user_id, submitted_at) serves the slice |
| E9 | concurrent dashboard reads during a quiz submission | read-only MVCC snapshot; no locks; sees pre- or post-commit state consistently |
| E10 | Unicode/emoji display names | passed through verbatim (UTF-8 JSON) |
| E11 | achievement catalog empty (seeder not yet run) | unlockedCount 0, recentUnlocks []; not an error |
| E12 | HYBRID generatedBy encountered (reserved value) | displayed verbatim if ever present; no special-casing |

## 27. Acceptance Criteria (Phase 9B definition of done)

- [ ] DASH-001 implemented exactly per Â§7â€“Â§8, Â§14â€“Â§15, Â§19 (thin controller, readOnly service, DTO records).
- [ ] All Â§8 field names/types/nullabilities match this document (DASH-TEST-029).
- [ ] Zero mutation paths (grep + DASH-TEST-023..027).
- [ ] Zero external/AI calls (grep + DASH-TEST-027).
- [ ] Principal-scoped queries only; no identifier parameter exists (DASH-TEST-003).
- [ ] DASH-TEST-001..036 green; full Phase 0â€“8 regression green.
- [ ] Swagger annotations present (tag, security requirement, operation summaries â€” controller convention).
- [ ] No schema change; no new configuration property; no new dependency.
- [ ] OpenAPI JSON matches the amended API Contract v1.3.0 Â§5C.
- [ ] Logs contain requestId + counts only (Â§18).

## 28. Open Decisions Register

| ID | Decision | Status |
|---|---|---|
| D1 | Active learning-path selection rule for the card (Â§8.8: current-subject-first, then most-recent ACTIVE, else null) | **APPROVED AS PROPOSED (owner, 2026-08-24)** â€” presentation-only; no generation/archival/mutation/PATH-002/Gemini |
| D2 | Unified cross-domain activity feed (rejected for v1; single-source recent-quizzes feed shipped instead) | **APPROVED AS PROPOSED (owner, 2026-08-24)** â€” completed-quiz-only feed, max 5, spec ordering; no lesson/streak/achievement/XP/future event types; unified feed deferred to a future specification |
| D3 | Assessment visibility granularity (assessedSubjects projection chosen over per-subject status flags) | **APPROVED AS PROPOSED (owner, 2026-08-24)** â€” subjectId + subjectName per R-GUARD lineage; no separate assessment-status algorithm |

No unresolved owner decisions remain. Every remaining behavior is DEFINED by
the authority chain (labels in Â§8).

### Decision details (required format)

**D1 â€” learningPath selection**
QUESTION: Which single ACTIVE path represents the learner on the dashboard?
CURRENT SPECIFICATION STATE: paths are per-(user,subject); no approved
global "current path" concept exists anywhere (PATH-001 is per-subject).
RESOLUTION: **APPROVED (owner, 2026-08-24)** â€” current-subject-first, then
most-recent ACTIVE (created_at DESC, id ASC), else null (Â§8.8).
RATIONALE: honors the learner's latest demonstrated focus (profile pointer),
deterministic, never fabricates, zero cost.
IMPACT: none on other endpoints; purely presentational selection.

**D2 â€” recentActivity scope**
QUESTION: Should the dashboard merge quizzes, unlocks, streak milestones
(and future lessons) into one feed?
CURRENT SPECIFICATION STATE: no unified activity model/ordering exists in
any approved document; lesson events have no producer.
RESOLUTION: **APPROVED (owner, 2026-08-24)** â€” v1 = recent completed
quizzes only (Â§8.10); unified feed deferred to a future owner-specified
decision.
RATIONALE: avoids inventing cross-domain ordering semantics; single-source
feed is fully defined today.
IMPACT: none; extension is additive (new array alongside `quizzes`) if ever
approved.

**D3 â€” assessment visibility**
QUESTION: How should placement state appear globally (ASMT-003 is
per-subject)?
CURRENT SPECIFICATION STATE: assessed â‡” baseline lineage exists
(R-GUARD criterion); no global view is defined.
RESOLUTION: **APPROVED (owner, 2026-08-24)** â€” projected `assessedSubjects`
list (Â§8.9).
RATIONALE: exact reuse of the approved lineage criterion; deterministic;
bounded by the seed catalog.
IMPACT: none on ASMT endpoints.

## 29. Changelog

| Version | Change |
|---|---|
| 1.0.0 | Initial PROPOSED draft: full read-model definition of DASH-001 (sections, field traceability, boundaries, empty/partial/new-learner matrices, ordering, bounds, security, errors, performance, DB mapping, six JSON examples, 36-case test matrix, owner decisions D1â€“D3, API Contract v1.3.0 amendment prepared) |
| **1.0.0 â€” APPROVAL** | **Owner approved the specification exactly as documented (2026-08-24):** D1 learning-path selection rule (presentation-only; current-subject-first â†’ most-recent ACTIVE â†’ null) Â· D2 recentActivity v1 scope (completed quizzes only, max 5, spec ordering; unified feed deferred) Â· D3 assessedSubjects projection (R-GUARD lineage; no separate status algorithm) Â· RATIFIED: completion metrics remain UNAVAILABLE until an approved successor of Adaptive D8. Status â†’ APPROVED â€” READY FOR IMPLEMENTATION. API Contract concurrently amended to v1.3.0 (DASH-001 binding). No normative rule altered by this approval. Implementation authorized ONLY by the separate Phase 9B prompt |

## 30. Approval Section

- [x] Owner approves D1 (learningPath selection rule) â€” **APPROVED 2026-08-24**
- [x] Owner approves D2 (recentActivity v1 scope; unified feed deferred) â€” **APPROVED 2026-08-24**
- [x] Owner approves D3 (assessment visibility projection) â€” **APPROVED 2026-08-24**
- [x] Owner ratifies Â§10.4 ruling (completion metrics UNAVAILABLE until a successor of Adaptive D8 exists) â€” **RATIFIED 2026-08-24**
- [x] Overall status change: PROPOSED â†’ **APPROVED â€” READY FOR IMPLEMENTATION** â€” owner sign-off received **2026-08-24**

The API Contract v1.3.0 amendment is EFFECTIVE. Phase 9B implementation is
authorized ONLY by a dedicated Phase 9B prompt and MUST follow Â§27.

---

*End of Specification â€” GameLearn AI Dashboard (DASH) â€” v1.0.0 â€” APPROVED â€” READY FOR IMPLEMENTATION*
