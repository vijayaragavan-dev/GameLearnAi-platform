# GameLearn AI — Central API Contract

---

## 1. Document Metadata

| Field | Value |
|---|---|
| Document name | GameLearn_AI_API_Contract.md |
| Version | 1.4.0 |
| Status | **APPROVED — OWNER SIGNED OFF through v1.4.0** (dashboard amendment signed 2026-08-24; AI Tutor amendment signed 2026-08-24) |
| Owner | Project Owner |
| Implementation Owner | Member 2 — Backend + AI |
| Authority | This document IS the central API Contract referenced by GameLearn_AI_Backend_AI_Specification.md (§10, §11, §42), GameLearn_AI_Database_Specification.md (§36) and GameLearn_AI_Learning_Path_AI_Specification.md (§34). Endpoint definitions are no longer `[TBD]` |
| Scope rule | This contract documents the ALREADY-IMPLEMENTED Phase 2–5 surface, PATH-002, GAM-001..003 (v1.1.0), the THREE approved assessment operations ASMT-001..003 (v1.2.0), the DASHBOARD read endpoint DASH-001 (v1.3.0 — implemented in Phase 9B), and the conversational AI TUTOR endpoint AI-001 (v1.4.0, owner-approved 2026-08-24 — behavior defined by GameLearn_AI_AI_Tutor_Specification.md v1.0.0 APPROVED; implementation is Phase 10B). No unrelated endpoints are invented; future features amend this document before implementation |
| Companion documents | Backend + AI Specification · Database Specification v1.0 · Adaptive Engine Specification v1.0.0 · Learning Path AI Specification v1.1.0 · Gamification Specification v1.0.0 APPROVED · Assessment Specification v1.0.0 APPROVED · Dashboard Specification v1.0.0 APPROVED (behavioral authority for DASH-001) · AI Tutor Specification v1.0.0 APPROVED (behavioral authority for AI-001) |

---

## 2. General Conventions (as actually implemented — verified against Phase 2–5 code)

### 2.1 Transport & naming

| Convention | Value |
|---|---|
| Base path | `/api/v1` |
| Protocol | HTTPS (production); HTTP allowed on localhost dev profiles |
| Content type | `application/json` |
| Field naming | lowerCamelCase JSON (Jackson default of the implemented DTO records) |
| Timestamps | ISO-8601 UTC strings (`Instant` serialization) |
| IDs | UUID strings (CHAR(36) storage per Database Specification §3) |
| Docs | Swagger UI at `/swagger-ui/index.html`, OpenAPI JSON at `/v3/api-docs` (springdoc annotations on controllers are part of the contract surface) |

### 2.2 Authentication (implemented, Phase 2)

| Rule | Detail |
|---|---|
| Scheme | Bearer JWT — header `Authorization: Bearer <token>` |
| Token issuance | `POST /api/v1/auth/login`; HS256, `JWT_SECRET` env (min 32 chars, fail-fast) |
| Identity resolution | Server-side ONLY: token validated, account loaded, `ACTIVE` status enforced; services receive `AuthenticatedUser(id, email, displayName)` from SecurityContext |
| Forbidden | Client-supplied user IDs are NEVER accepted as authority for ownership decisions on ANY endpoint |
| Public endpoints | Exactly: `AUTH-001`, `AUTH-002` (+ health/info actuator). Everything else requires authentication |
| Sessions/CSRF | Stateless; CSRF disabled (token-based mobile API) |

### 2.3 SUCCESS response envelope — ACTUAL ADOPTED FORMAT

The implemented backend does **NOT** use a `{success,message,data,timestamp}` wrapper. Controllers return DTO records / lists directly (verified: `LearningPathController`, `AuthController`, `QuizController`, etc.). This plain-DTO format is the binding envelope:

```json
{ ...DTO fields... }
```
or, for list endpoints:
```json
[ { ...DTO... }, { ...DTO... } ]
```

The alternative envelope proposed (never adopted) in Backend + AI Spec §10 is hereby RETIRED — that section explicitly deferred to "the format actually established"; this is it. Any future endpoint introducing a different envelope would violate this contract.

### 2.4 ERROR response envelope — ACTUAL ADOPTED FORMAT

Every failed request returns the uniform, safe `ErrorResponse` structure (implemented since Phase 2):

```json
{
  "timestamp": "2026-08-23T12:00:00Z",
  "status": 404,
  "errorCode": "RESOURCE_NOT_FOUND",
  "message": "Learning path not found",
  "path": "/api/v1/learning-path/11111111-1111-1111-1111-111111111101",
  "requestId": "b7c9d1e0-4f2a-4c3e-9a51-77f2b0d3e8a1",
  "fieldErrors": { "regenerate": "must be a boolean" }
}
```

Rules (binding): null fields omitted (`NON_NULL`); `requestId` echoes the MDC correlation ID (`X-Request-ID` request header honored, otherwise generated); NEVER contains stack traces, Gemini raw errors, API keys, credentials, prompts, or sensitive learner information — including for 401/403 raised inside the security filter chain.

### 2.5 Correlation & logging

Clients MAY send `X-Request-ID`; all log lines and error payloads carry it. Logs contain no secrets, tokens, passwords, or unnecessary private learner data.

---

## 3. API Surface Matrix

Status column: **IMPLEMENTED** (Phase 2–5, behavior frozen by existing tests) or **APPROVED — PENDING IMPLEMENTATION** (defined herein, not yet built).

| API ID | Method | Endpoint | Auth | Controller / Service (planned) | Status |
|---|---|---|---|---|---|
| AUTH-000 | GET | `/api/v1/auth/validate` | Bearer | AuthController / AuthService | IMPLEMENTED |
| AUTH-001 | POST | `/api/v1/auth/login` | Public | AuthController / AuthService | IMPLEMENTED |
| AUTH-002 | POST | `/api/v1/auth/register` | Public | AuthController / AuthService | IMPLEMENTED |
| AUTH-003 | POST | `/api/v1/auth/logout` | Bearer | AuthController / AuthService | IMPLEMENTED |
| SUBJ-001 | GET | `/api/v1/subjects` | Bearer | SubjectController / SubjectService | IMPLEMENTED |
| TOPIC-001 | GET | `/api/v1/topics/{topicId}` | Bearer | TopicController / TopicService | IMPLEMENTED |
| LESSON-001 | GET | `/api/v1/topics/{topicId}/lesson` | Bearer | LessonController / LessonService | IMPLEMENTED |
| PATH-001 | GET | `/api/v1/learning-path/{subjectId}` | Bearer | LearningPathController / LearningPathService | IMPLEMENTED |
| **PATH-002** | **POST** | **`/api/v1/learning-path/{subjectId}/generate`** | **Bearer** | LearningPathController / LearningPathService + AI-LP pipeline | **APPROVED — PENDING IMPLEMENTATION** |
| USER-001 | GET | `/api/v1/profile` | Bearer | ProfileController / ProfileService | IMPLEMENTED |
| PROG-001 | GET | `/api/v1/progress` | Bearer | ProgressController / ProgressService | IMPLEMENTED |
| PROG-002 | GET | `/api/v1/progress/{topicId}` | Bearer | ProgressController / ProgressService | IMPLEMENTED |
| QUIZ-001 | GET | `/api/v1/quiz/{topicId}` | Bearer | QuizController / QuizService | IMPLEMENTED |
| QUIZ-002 | POST | `/api/v1/quiz/{quizId}/submit` | Bearer | QuizController / QuizService (+Adaptive Engine) | IMPLEMENTED |
| GAM-001 | GET | `/api/v1/gamification/summary` | Bearer | GamificationController / GamificationService | APPROVED — PENDING IMPLEMENTATION |
| GAM-002 | GET | `/api/v1/achievements` | Bearer | GamificationController / GamificationService | APPROVED — PENDING IMPLEMENTATION |
| GAM-003 | GET | `/api/v1/streak` | Bearer | GamificationController / GamificationService | APPROVED — PENDING IMPLEMENTATION |
| DASH-001 | GET | `/api/v1/dashboard` | Bearer | DashboardController / DashboardService | APPROVED — PENDING IMPLEMENTATION (owner-approved 2026-08-24; behavioral authority: GameLearn_AI_Dashboard_Specification.md v1.0.0 APPROVED, §"5C"; implement in Phase 9B only) |
| ASMT-001 | GET | `/api/v1/assessment/{subjectId}` | Bearer | AssessmentController / AssessmentService | APPROVED — PENDING IMPLEMENTATION |
| ASMT-002 | POST | `/api/v1/assessment/{subjectId}/submit` | Bearer | AssessmentController / AssessmentService | APPROVED — PENDING IMPLEMENTATION |
| ASMT-003 | GET | `/api/v1/assessment/{subjectId}/result` | Bearer | AssessmentController / AssessmentService | APPROVED — PENDING IMPLEMENTATION |
| AI-001 | POST | `/api/v1/ai/tutor` | Bearer | AiTutorController / AiTutorService + AI-TUTOR pipeline | APPROVED — PENDING IMPLEMENTATION (owner-approved 2026-08-24; behavioral authority: GameLearn_AI_AI_Tutor_Specification.md v1.0.0 APPROVED, §"5D"; implement in Phase 10B only) |
| USER-002 | PUT/PATCH | `/api/v1/profile/settings` | Bearer | ProfileController / ProfileService | APPROVED ID — deferred to its phase (its timezone setting is the designated future input for streaks.timezone per Gamification Spec §10; NOT part of Phase 7) |

Deferred rows keep their historical IDs and paths exactly as listed in Backend + AI Spec §11; their detailed contracts are written when their owning specifications exist. Nothing in this contract authorizes implementing them early. Legacy gamification identifiers ACH-001/002 and STREAK-001 are SUPERSEDED on the read side by the approved GAM-001..003 above (Gamification Specification v1.0.0 §12, owner-approved 2026-08-24); any future gamification MUTATION surface would still require its own amendment — none is authorized.

---

## 4. Error Code Registry

Existing implemented codes (enum `ErrorCode`) remain authoritative for their semantics; AI-specific codes extend the same registry (same enum, same envelope). Where the owner decision list used a different label for an equivalent meaning, the EXISTING code wins (no duplicate semantics).

| Code | HTTP | Meaning | Origin |
|---|---|---|---|
| VALIDATION_FAILED | 400 | Request body/params failed bean/schema validation (≡ owner-listed `VALIDATION_ERROR`) | IMPLEMENTED |
| MALFORMED_REQUEST | 400 | Request is syntactically unusable (bad JSON, bad UUID) | IMPLEMENTED |
| UNAUTHORIZED | 401 | Missing/invalid/expired token, suspended account (≡ `UNAUTHORIZED`) | IMPLEMENTED |
| FORBIDDEN | 403 | Authenticated but not permitted (≡ `FORBIDDEN`) | IMPLEMENTED |
| RESOURCE_NOT_FOUND | 404 | Unknown/inactive subject/topic/quiz/path (≡ `NOT_FOUND`) | IMPLEMENTED |
| METHOD_NOT_ALLOWED | 405 | Wrong HTTP method | IMPLEMENTED |
| UNSUPPORTED_MEDIA_TYPE | 415 | Non-JSON body where JSON required | IMPLEMENTED |
| DATA_CONFLICT | 409 | Business conflict (≡ `CONFLICT`; e.g., concurrent generation race loser — retry-safe) | IMPLEMENTED |
| INTERNAL_ERROR | 500 | Unexpected server failure (≡ `INTERNAL_ERROR`) | IMPLEMENTED |
| AI_RATE_LIMITED | 429 | PATH-002 generation refused: user exceeded the approved Gemini-backed rate limit; NO Gemini call made; retry-after guidance in message | NEW — approved with PATH-002 |
| AI_SERVICE_UNAVAILABLE | 503 | Gemini/provider unreachable or unusable after the approved policy — REACHABLE for AI-001 since v1.4.0 (owner-approved 2026-08-24: the Tutor has no deterministic fallback answer, so provider-side failures surface as this safe envelope; precise causes live only in ai_interactions). For PATH-002 it remains RESERVED (the SYSTEM fallback path keeps it unreachable there) | APPROVED with AI-TUTOR v1.4.0 for AI-001; RESERVED for other surfaces |
| AI_GENERATION_FAILED | 503 | RESERVED — pipeline failure with no deliverable path (fallback impossible). Current design makes this reachable only if the deterministic builder itself fails | NEW — reserved |
| AI_OUTPUT_INVALID | 422 | RESERVED — semantic/business rejection surfaced INSTEAD of fallback would require an owner policy change; current approved policy falls back silently instead | NEW — reserved |
| AI_CONTENT_REJECTED | 422 | RESERVED — content-safety rejection surfaced instead of fallback (as above) | NEW — reserved |

Note on HTTP 422: the implemented backend does NOT use 422 today; semantic validation failures are 400-class. The two 422 codes above are therefore RESERVED placeholders whose activation requires a visible, documented behavior change — they must not silently replace the fallback-first policy.

Error responses NEVER expose: stack traces, Gemini raw errors/responses, API keys, database details, internal prompts, sensitive learner data.

---

## 5. PATH-002 — Learner-Initiated AI Learning-Path Generation

**Owner-approved via this contract; full behavioral authority: GameLearn_AI_Learning_Path_AI_Specification v1.0.0 (AI-LP).**

| Aspect | Value |
|---|---|
| API ID | PATH-002 |
| Method | `POST` |
| Endpoint | `/api/v1/learning-path/{subjectId}/generate` |
| Auth | Bearer JWT (mandatory) |
| Authorization | Authenticated learner acting on OWN paths only; principal from SecurityContext determines the user; `userId` is NEVER accepted from the client |
| Path parameter | `subjectId` — UUID of an ACTIVE subject (unknown/inactive ⇒ 404 `RESOURCE_NOT_FOUND`, BEFORE any AI work) |
| Request body | Optional JSON object (absent body = `{}`): `{ "regenerate": false, "learningGoal": "optional learner goal" }` |
| — regenerate | boolean, default `false` |
| — learningGoal | optional string ≤300 chars; omitted/null/blank ⇒ generation proceeds on verified learner context alone; UNTRUSTED INPUT (§9) |
| Rejected request fields | Any attempt to supply `userId`, mastery/trend/difficulty/recommendation values, or authoritative topic selections is ignored or rejected (400) — the backend constructs learner context itself |

### 5.1 Behavior matrix

| Scenario | Behavior | Result |
|---|---|---|
| `regenerate=false`, ACTIVE path exists (user+subject) | **IDEMPOTENT RETURN**: return existing ACTIVE path unchanged. NO Gemini call, NO rate-limit consumption, NO writes | `200` + persisted path |
| `regenerate=false`, no ACTIVE path | Full pipeline: validate subject → build learner context (Adaptive Engine state, READ-ONLY) → prompt build → Gemini → parse → schema → safety → business validation → atomic persist (path+nodes+audit) → return | `201` + new ACTIVE path (`generatedBy=AI`, or `SYSTEM` if fallback was used after AI failure — still `201`: a usable path was created) |
| `regenerate=true`, any prior state | Generate + FULLY validate the NEW candidate FIRST (old path untouched and serving throughout); then ONE transaction: archive old ACTIVE → persist new ACTIVE → COMMIT | `201` + new ACTIVE path |
| Regeneration with Gemini/parse/safety/business/persistence failure | NOTHING changes: old ACTIVE path REMAINS ACTIVE and usable (rollback restores it) | Per failure class below |

### 5.2 Status codes

| Code | When |
|---|---|
| `200` | Existing ACTIVE path returned (normal idempotent request) |
| `201` | New learning path created — first generation OR regeneration replacement (project-wide convention: every successful creation of a resource returns 201, matching AUTH-002/QUIZ-002; regeneration creates a new path row, hence 201) |
| `400` | Malformed body / invalid types / oversized learningGoal |
| `401` | Unauthenticated |
| `403` | Authenticated but unauthorized (reserved; ownership violations are structurally impossible by query scoping) |
| `404` | Subject unknown or inactive (checked before any AI/rate-limit consumption) |
| `409` | Concurrent generation race loser (retry-safe; the winner's result governs) |
| `422` | RESERVED AI validation codes (§4) — not returned under the approved fallback-first policy |
| `429` | `AI_RATE_LIMITED` — Gemini-backed limit exhausted; idempotent returns are NEVER limited |
| `500` | Unexpected internal failure (nothing persisted except audit per AI-LP §30.2) |
| `503` | RESERVED `AI_SERVICE_UNAVAILABLE` / `AI_GENERATION_FAILED` (only reachable if fallback itself fails — documented edge) |

### 5.3 Success response — PERSISTED portion (both 200 and 201)

Plain-DTO envelope (§2.3), shape consistent with PATH-001 entries plus creation timestamps:

```json
{
  "id": "0b6f…-uuid",
  "subjectId": "11111111-1111-1111-1111-111111111101",
  "title": "Programming Foundations Sprint",
  "description": "A plan tuned to your current mastery profile.",
  "status": "ACTIVE",
  "generatedBy": "AI",
  "createdAt": "2026-08-23T12:00:00Z",
  "updatedAt": "2026-08-23T12:00:00Z",
  "nodes": [
    {
      "id": "uuid",
      "topicId": "uuid",
      "topicName": "Variables & Types",
      "sequenceNumber": 1,
      "requiredMastery": 0.00,
      "status": "AVAILABLE"
    },
    {
      "id": "uuid",
      "topicId": "uuid",
      "topicName": "Control Flow",
      "sequenceNumber": 2,
      "requiredMastery": 40.00,
      "status": "LOCKED"
    }
  ]
}
```

Field authority: ALL fields map 1:1 to existing columns of `learning_paths` / `learning_path_nodes` (Database Specification §12/§13). Enum values exactly: status ∈ ACTIVE/COMPLETED/ARCHIVED; generatedBy ∈ SYSTEM/AI/HYBRID (PATH-002 writes only AI or SYSTEM); node.status initial values AVAILABLE (first node) / LOCKED (rest). `createdAt`/`updatedAt` are additive relative to today's `LearningPathResponse` — the implementation DTO extends accordingly for PATH-002 (PATH-001 remains byte-compatible until separately amended).

### 5.4 NON-PERSISTED AI display metadata (optional)

```json
{
  "...persisted fields as above...": "",
  "aiMetadata": {
    "nodes": [
      { "sequenceNumber": 1, "objective": "Declare and use typed variables.", "rationale": "Foundational — no assessment history yet." }
    ]
  }
}
```

Binding rules (owner-approved): present ONLY on the generation response that produced it; NEVER persisted; NEVER fabricated — if no valid AI metadata exists (fallback paths always), the field is OMITTED entirely; contents restricted to `objective` / `rationale`; MUST NEVER contain prompts, system instructions, API keys, internal database/security/implementation information, model names, latency, or raw model responses. Flutter treats it as cosmetic and optional.

### 5.5 Idempotency & regeneration summary (normative, mirrors AI-LP §29)

1. Normal request + ACTIVE exists ⇒ return it; zero cost; zero rate consumption.
2. Regeneration validates the replacement COMPLETELY before touching stored state; archive-old + persist-new commit atomically.
3. Every failure class during regeneration leaves the old ACTIVE path intact.
4. ARCHIVED paths remain as history; PATH-001 continues returning them (caller-owned), clearly labeled `"status": "ARCHIVED"`.

### 5.6 Rate limiting

| Rule | Value |
|---|---|
| Limit | 10 Gemini-backed PATH-002 generations per authenticated user per rolling hour |
| Exempt | Idempotent returns (200) — they perform NO Gemini call and consume NO slot |
| Counts | First generations AND regenerations that reach Gemini (including retries inside one logical request = one slot); requests refused before Gemini (404 subject, malformed body) consume nothing |
| Configuration | `gamelearn.ai.learning-path.rate-limit.max-requests-per-hour=10`, `...window-minutes=60` — no magic numbers |
| Exceeded | `429 AI_RATE_LIMITED`, no Gemini call, no audit row required |
| Honest limitation | Enforcement is single-instance/in-JVM. Multi-replica deployments multiply the effective limit; scaling requires revisiting this section with an owner decision. NO Redis/Kafka/distributed store authorized |

### 5.7 Adaptive Engine boundary

PATH-002 READS mastery/masteryLevel/trend/recommendedActivity/recommendedDifficulty/current learner state. It MUST NOT modify Adaptive Engine rules, tables, or outputs; Gemini output can never alter them (schema contains no such fields — AI-LP §10).

### 5.8 Fallback & AI audit

On Gemini failure after the approved retry policy (AI-LP §27): deterministic SYSTEM fallback (AI-LP §28) runs through the SAME business validation before persistence; during regeneration, fallback failure also leaves the old ACTIVE path unchanged. Every actual Gemini attempt writes one sanitized `ai_interactions` row: `interaction_type=LEARNING_PATH`, statuses SUCCESS/FAILED/FALLBACK/REJECTED, model name, prompt version, sanitized context/response, latency, error code — never secrets (AI-LP §36/§37).

### 5.9 Database contract

Uses EXISTING tables only: `learning_paths`, `learning_path_nodes`, `subjects`, `topics`, `topic_mastery`, `learner_profiles`, `ai_interactions`. **No migration and no new column is authorized by this contract.** `generated_by`: AI (validated Gemini path) / SYSTEM (deterministic fallback). No invalid AI output may ever be persisted.

---

## 5A. GAM-001..003 — Gamification Read Endpoints (v1.1.0 amendment)

**Owner-approved 2026-08-24; full behavioral authority: GameLearn_AI_Gamification_Specification v1.0.0 APPROVED (§4–§11).** All three are READ-ONLY, principal-scoped, plain-DTO envelope (§2.3), standard ErrorResponse on failure (§2.4). No request body of any kind is accepted; no client-supplied `userId` exists; no mutation surface is authorized; no pagination (bounded catalog); no caching headers mandated.

| Aspect | GAM-001 | GAM-002 | GAM-003 |
|---|---|---|---|
| Method & path | GET `/api/v1/gamification/summary` | GET `/api/v1/achievements` | GET `/api/v1/streak` |
| Auth | Bearer JWT (mandatory) | Bearer JWT (mandatory) | Bearer JWT (mandatory) |
| Authorization | Authenticated learner; state derived exclusively from the SecurityContext principal | same | same |

### 5A.1 Response shapes (binding)

GAM-001 — `200`:
```json
{
  "totalXp": 325,
  "currentLevel": 3,
  "maxLevel": 50,
  "nextLevelThresholdXp": 600,
  "xpToNextLevel": 276,
  "currentStreakDays": 3,
  "longestStreakDays": 5,
  "achievementCount": 2
}
```
`nextLevelThresholdXp` / `xpToNextLevel` are `null` at MAX_LEVEL 50 (XP keeps accumulating; level pinned).

GAM-002 — `200`, JSON array over the FULL catalog (`unlockedAt: null` = locked):
```json
[
  { "code": "FIRST_QUIZ", "name": "First Steps", "description": "Complete your first quiz.",
    "iconKey": "ach_first_quiz", "xpReward": 20, "unlockedAt": "2026-08-24T10:15:07Z" },
  { "code": "WEEK_WARRIOR", "name": "Week Warrior", "description": "Maintain a 7-day learning streak.",
    "iconKey": "ach_week_warrior", "xpReward": 60, "unlockedAt": null }
]
```

GAM-003 — `200`:
```json
{ "currentStreakDays": 3, "longestStreakDays": 5,
  "lastLearningDate": "2026-08-24", "timezone": "UTC" }
```

### 5A.2 Status codes & errors

`200` success · `401 UNAUTHORIZED` (missing/invalid/expired token or suspended account). No other error code is reachable: there are no path/body parameters to validate, resources cannot be absent (state derives from the principal's own rows; pre-Phase-7 zero-state returns zeros/nulls per Gamification Spec §12), and the endpoints perform no writes. Any unexpected failure uses `500 INTERNAL_ERROR`.

### 5A.3 Data authority & boundaries

All values are SERVER-DERIVED (Gamification Spec §15): clients can never supply XP, levels, unlocks, streak counts, dates, or timezones. Reads touch ONLY existing tables (`learner_profiles`, `xp_transactions`, `achievements`, `user_achievements`, `streaks`) — **no migration, no new column**. These endpoints expose NO adaptive internals beyond what QUIZ-002 already surfaces, and never prompts/model data.

---

## 5B. ASMT-001..003 — Assessment Endpoints (v1.2.0 amendment)

**Owner-approved 2026-08-24; full behavioral authority: GameLearn_AI_Assessment_Specification v1.0.0 APPROVED (sections 4–19).** Subject-level cold-start placement: stateless deterministic delivery of curated questions across a subject's active topics, server-side evaluation, per-topic T01-mirror mastery baselines, profile subset refresh — all inside ONE atomic transaction. No Gemini involvement; NO schema change (existing tables only); no recommendation/gamification writes (A6/A7).

| Aspect | ASMT-001 | ASMT-002 | ASMT-003 |
|---|---|---|---|
| Method & path | GET `/api/v1/assessment/{subjectId}` | POST `/api/v1/assessment/{subjectId}/submit` | GET `/api/v1/assessment/{subjectId}/result` |
| Auth | Bearer JWT (mandatory) | Bearer JWT (mandatory) | Bearer JWT (mandatory) |
| Authorization | Principal-scoped learner; subject must exist and be ACTIVE | same + R-GUARD lineage check | principal-scoped derived read |
| Request body | none | `{ "answers": [ { "questionId": UUID, "selectedAnswer": string } ] }` | none |

### 5B.1 Response shapes (binding)

ASMT-001 — `200`:
```json
{ "subjectId": "…101",
  "questions": [
    { "questionId": "uuid-q1", "topicId": "uuid-t1",
      "questionText": "Which keyword declares a constant?",
      "options": ["const","let","var"], "difficulty": "EASY" } ] }
```
Correct answers/explanations are NEVER included.

ASMT-002 — `201`:
```json
{ "subjectId": "…101", "score": 100.00, "overallMastery": 100.00,
  "topics": [
    { "topicId": "uuid-t1", "accuracy": 100.00,
      "masteryLevel": "MASTERED", "currentDifficulty": "EASY" } ] }
```

ASMT-003 — `200`:
```json
{ "subjectId": "…101", "assessed": true, "overallMastery": 75.00,
  "topics": [
    { "topicId": "uuid-t1", "topicName": "Variables",
      "masteryScore": 75.00, "masteryLevel": "PROFICIENT",
      "currentDifficulty": "EASY" } ] }
```
Not-assessed learner: `200 { subjectId, assessed: false, overallMastery: <profile mean>, topics: [] }`.

### 5B.2 Status codes & errors

ASMT-001: `200` · 400 MALFORMED_REQUEST · 401 · 404 RESOURCE_NOT_FOUND (unknown/inactive subject OR zero assessable content — A10).
ASMT-002: `201` · 400 VALIDATION_FAILED/MALFORMED_REQUEST (duplicate answers, foreign/stale questionId, empty answers) · 401 · 404 · **409 DATA_CONFLICT** (R-GUARD: baseline lineage already established — retry-safe, nothing written) · 500.
ASMT-003: `200` · 400 · 401 · 500.
No new error codes; registry unchanged. Reserved AI_* codes untouched (no Gemini).

### 5B.3 Data authority & boundaries

All values server-derived: clients control ONLY selectedAnswer strings. Baselines reuse approved Adaptive T01/stateOf mathematics verbatim (attempt_count=1 per A4; current_difficulty=EASY per A3). R-GUARD preserves single-lineage integrity of the adaptive update mathematics (A5). ZERO writes to quiz_attempts/question_attempt/recommendation/xp/achievement/streak/current_level tables (C1/A6/A7). Tables touched: READ subjects/topics/questions; WRITE topic_mastery(create-only)/learner_profiles(overall_mastery,current_subject_id).

---

## 5C. DASH-001 — Learner Dashboard Read Endpoint (v1.3.0 amendment)

**OWNER-APPROVED 2026-08-24; full behavioral authority: GameLearn_AI_Dashboard_Specification v1.0.0 APPROVED.** Single read-only aggregation surface over the authenticated learner's own persisted state (profile, mastery, gamification, streak, achievements, recommendations, learning path, assessment coverage, recent quiz activity). READ-MODEL ONLY: zero writes, zero Gemini/AI involvement, zero schema change; opening the dashboard never mutates adaptive/gamification/recommendation/learning-path state.

| Aspect | Value |
|---|---|
| API ID | DASH-001 |
| Method & path | `GET /api/v1/dashboard` |
| Auth | Bearer JWT (mandatory); anonymous ⇒ `401 UNAUTHORIZED` |
| Identity | Server-side only (SecurityContext principal); NO path/query/body parameters of any kind — client-supplied userId is structurally impossible |
| Request body / params | none (anything sent is ignored) |
| Response | `200` + plain-DTO envelope (§2.3) with ten ALWAYS-present top-level sections: `learner`, `currentSubject`(nullable), `mastery`, `gamification`, `streak`, `achievements`, `recommendations` (≤3), `learningPath`(nullable), `assessment`, `recentActivity`; exact field names/types/nullability/ordering/bounds per Dashboard Specification §8, §14, §15 |
| Empty states | missing optional data degrades to `null` / `[]` / zeros — NEVER an error (new-learner zero state fully specified) |
| Status codes | `200` success · `401` UNAUTHORIZED · `405` METHOD_NOT_ALLOWED · `415` UNSUPPORTED_MEDIA_TYPE · `500` INTERNAL_ERROR. Nothing else is reachable: no 400 (nothing to validate), no 404 (the principal's dashboard always exists), no AI_* codes |
| Data authority | READ-ONLY over existing tables (`users`, `learner_profiles`, `subjects`, `topics`, `topic_mastery`, `recommendations`, `achievements`, `user_achievements`, `streaks`, `quiz_attempts`, `quizzes`, `learning_paths`, `learning_path_nodes`); every displayed value traced to an approved source in Dashboard Specification §8; gamification fields byte-equivalent to GAM-001 semantics incl. max-level nulls; no completion percentages (undefined by approved specs) |

Normative examples (new learner, active learner, partial states, max level, errors): Dashboard Specification §23.

---

## 5D. AI-001 — Conversational AI Tutor Endpoint (v1.4.0 amendment)

**OWNER-APPROVED 2026-08-24; full behavioral authority: GameLearn_AI_AI_Tutor_Specification v1.0.0 APPROVED.** Single conversational generation surface: a learner-authored question plus optional subject/topic focus and a bounded client-held history window are answered by Gemini under layered prompt-security controls. The Tutor EXPLAINS; it never DIRECTS and never MUTATES — zero writes outside sanitized `ai_interactions` (type=TUTOR) audit metadata; conversation content is NEVER persisted (stateless v1, OT-1).

| Aspect | Value |
|---|---|
| API ID | AI-001 |
| Method & path | `POST /api/v1/ai/tutor` |
| Auth | Bearer JWT (mandatory); anonymous/invalid/expired/suspended ⇒ `401 UNAUTHORIZED` |
| Identity | Server-side only (SecurityContext principal); NO client-controlled userId anywhere |
| Request body | `{ "question": string ≤2000 chars (required), "subjectId"?: UUID, "topicId"?: UUID, "conversation"?: [{role: LEARNER\|TUTOR, content ≤1000}] ≤8 messages }` — optional refs validated against the ACTIVE catalog (unknown/inactive/cross-subject ⇒ `400 VALIDATION_FAILED` with fieldErrors) BEFORE quota or Gemini contact; client-supplied authoritative learning values rejected |
| Focus resolution | topicId > subjectId > profile current-topic pointer > current-subject pointer > GENERIC mode (deterministic; inactive pointers fall through, never error) |
| Response | `200` plain-DTO envelope `{ "answer": ≤4000 chars, "refused": bool, "degraded": bool, "context": {subjectId?, topicId?, subjectName?, topicName?} }`; `refused=true` = deterministic policy refusal (no Gemini call); `degraded=true` = deterministic template because Gemini output failed safety/schema scans |
| Status codes | `200` success · `400` VALIDATION_FAILED / MALFORMED_REQUEST · `401` UNAUTHORIZED · `405` METHOD_NOT_ALLOWED · `415` UNSUPPORTED_MEDIA_TYPE · `429` AI_RATE_LIMITED · `503` AI_SERVICE_UNAVAILABLE (ACTIVATED for AI-001 per OT-3: transient failures after one approved retry, permanent provider faults, malformed/schema-invalid output, feature disabled) · `500` INTERNAL_ERROR. The 422 codes remain RESERVED and unreachable |
| Rate limit | DEDICATED tutor bucket: 20 Gemini-backed requests/user/rolling 60 minutes (OT-4). Validation-rejected and refusal-class requests do NOT consume; failed attempts DO; internal retries do not double-consume; NO idempotency (every POST is fresh); single-instance/in-JVM limitation documented (D10 inheritance) |
| Data authority | READ-ONLY over the principal's own state via the closed allowlist TC1–TC6 (subject/topic names + difficulty, focused-topic mastery row, overallMastery, currentLevel). MUST NOT consume: recommendations, learning paths/nodes/aiMetadata, raw attempts/answers, XP/streaks/achievements, progress rows, identity fields, other learners' anything. ZERO mutations to adaptive/gamification/assessment/learning-path/dashboard state |
| Persistence | NONE of question/history/answer content (Database Spec §26 privacy rule; OT-1). Audit: one `ai_interactions` row per accepted request, type=TUTOR, sanitized counts/categories only (Tutor Specification §16); no retention period (OT-8 deferred) |

Normative details (prompt architecture, security threat model, failure taxonomy, test matrix): AI Tutor Specification §§8–16, 24–25.

---

## 6. Existing Endpoints Referenced (stability guarantees)

PATH-002 introduces NO breaking change:

- `PATH-001 GET /api/v1/learning-path/{subjectId}` — unchanged contract; once paths exist it returns them (including AI/SYSTEM-generated ones) exactly as implemented, caller-owned only.
- `QUIZ-002` adaptive response block (Adaptive Engine Spec §26) — unaffected.
- All auth/profile/progress endpoints — unaffected.

## 7. Frontend (Flutter) Compatibility Summary

Everything Flutter needs, nothing it shouldn't know:

| Flutter knows | Flutter never needs |
|---|---|
| Endpoint, method, headers, JWT handling | Gemini existence or APIs |
| Request body (`regenerate`, `learningGoal`) | Prompts, system instructions |
| Exact success/error JSON shapes | Database schema, entity internals |
| Status codes + errorCode registry | Adaptive formulas or thresholds |
| Idempotency (200 vs 201) and regeneration safety guarantees | Retry/backoff internals, rate-limit window mechanics beyond the 429 signal |
| `aiMetadata` is optional cosmetic data | Raw model responses |

## 8. Cross-Document Consistency Statement

Verified chain — Database Specification → Backend + AI Specification → Adaptive Engine Specification → THIS CONTRACT → Learning Path AI Specification → Gamification Specification v1.0.0 → Assessment Specification v1.0.0: field names, enum values, ownership rules, status semantics, idempotency, regeneration safety, rate limits, fallback, audit behaviors, the gamification award/level/streak models, and the assessment placement/baseline model agree across all seven documents. PATH-002 and GAM-001..003 conflict with nothing; Backend + AI Spec §42's conflict process remains the remedy for any future discrepancy.

## 9. Amendment History

| Version | Change |
|---|---|
| 1.0.0 | Initial owner-signed contract: Phase 2–5 implemented surface + PATH-002 definition (AI-LP) |
| 1.1.0 | **Gamification amendment (owner-approved 2026-08-24):** added GAM-001 `GET /api/v1/gamification/summary`, GAM-002 `GET /api/v1/achievements`, GAM-003 `GET /api/v1/streak` as APPROVED — PENDING IMPLEMENTATION (§5A), per GameLearn_AI_Gamification_Specification v1.0.0 §12. Read-only; additive; no breaking change to any existing row; legacy ACH-001/002 & STREAK-001 read-side superseded; USER-002 remains deferred |
| 1.2.0 | **Assessment amendment (owner-approved 2026-08-24):** added ASMT-001 `GET /api/v1/assessment/{subjectId}`, ASMT-002 `POST /api/v1/assessment/{subjectId}/submit`, ASMT-003 `GET /api/v1/assessment/{subjectId}/result` as APPROVED — PENDING IMPLEMENTATION (§5B), per GameLearn_AI_Assessment_Specification v1.0.0 (decisions A1–A12, C1, C2). Additive; zero schema change; zero Gemini involvement; legacy combined ASMT deferred row superseded |
| 1.3.0 | **Dashboard amendment (OWNER-APPROVED 2026-08-24):** DASH-001 row status → APPROVED — PENDING IMPLEMENTATION; added §5C defining the read-only dashboard surface per GameLearn_AI_Dashboard_Specification v1.0.0 APPROVED (owner decisions D1–D3 approved as documented; completion metrics ratified UNAVAILABLE). Additive; no existing row altered; zero schema change; zero AI involvement |
| 1.4.0 | **AI Tutor amendment (OWNER-APPROVED 2026-08-24):** AI-001 row status → APPROVED — PENDING IMPLEMENTATION; added §5D defining the conversational tutor surface per GameLearn_AI_AI_Tutor_Specification v1.0.0 APPROVED (decisions OT-1..OT-7 approved as documented; OT-8/OT-9 deferred). AI_SERVICE_UNAVAILABLE becomes REACHABLE for AI-001 only (no-fallback ruling); remains RESERVED for PATH-002. Additive; no existing row altered; zero schema change; conversation content never persisted |

---

*End of Contract — GameLearn_AI_API_Contract.md — Version 1.4.0 — APPROVED — OWNER SIGNED OFF*
