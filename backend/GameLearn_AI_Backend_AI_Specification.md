# GameLearn AI — Backend, AI & Adaptive Intelligence Implementation Specification

**A Smart Adaptive Learning Adventure**
Problem Statement: AIS-01 | Category: Adaptive Intelligence System | Domain: Edutainment
Owner: **Member 2 — Backend + AI** | Companion to: *GameLearn AI Frontend UI/UX & Implementation Specification*

> This document uses the same placeholder API IDs introduced in the Frontend Specification (§11 of that document) so both members build against one consistent list. Every ID remains `[TBD]` until a formal API Contract document is signed off — **this spec does not itself constitute that contract**, it defines how the backend implements it.

---

## 1. Document Purpose

This is Member 2's single source of truth for building the Spring Boot backend, the adaptive-intelligence engine, the Gemini integration, and the gamification engine — without guessing architecture, without inventing endpoints, and without letting Gemini make application decisions it shouldn't.

---

## 2. Project Context

Same as the Frontend Specification §2: mobile Flutter app, initial subjects (Programming, Computer Networks, DBMS, OS, Data Structures), extensible to new subjects without core architecture changes.

---

## 3. Backend Responsibilities

**Spring Boot IS responsible for:** authentication, authorization, validation, business logic, API contracts, learner data, quiz evaluation, gamification calculations, adaptive decisions, AI orchestration, database access, security, error handling.

**Spring Boot must NOT:** let Gemini modify the database directly, let Gemini control auth/security, put business logic in controllers, expose entities directly, or blindly trust AI output.

**Gemini is responsible only for:** generating content — explanations, hints, learning-path text, questions, tutor responses. It never decides *what should happen next* — that's the adaptive engine's job (see §18, §31).

---

## 4. System Architecture

```
Flutter Mobile App
        │  HTTPS / REST / JSON
        ▼
┌─────────────────────────────────────┐
│            SPRING BOOT API           │
│  Authentication · User Management    │
│  Learning · Assessment · Quiz        │
│  Progress · Gamification             │
│  Adaptive Intelligence               │
│  AI Orchestration                    │
└───────────────┬───────────────────────┘
        ┌────────┼────────┐
        ▼        ▼         ▼
      MySQL    Gemini   ML Service (optional)
```

**Critical rule:** the backend never blindly delegates decisions to Gemini.

```
Student → Spring Boot → Student Context → Adaptive Engine → Decision
   → Gemini (only if content generation is needed) → Validate AI Output
   → Persist Result → Flutter
```

---

## 5. Technology Stack

| Layer | Technology |
|---|---|
| Backend | Java + Spring Boot (Spring Web, Spring Data JPA, Spring Security, Bean Validation) |
| API Docs | OpenAPI / Swagger |
| Migrations | Flyway (if approved) |
| Database | MySQL |
| AI | Gemini API |
| Optional ML | Python + Scikit-learn, called via internal REST |
| Testing | JUnit, Mockito, Spring Boot Test, MockMvc, Testcontainers where appropriate |

Only add a dependency if it has a clear, justified purpose.

---

## 6. Architecture Principles

1. Backend is the **single authoritative business-logic layer** — Flutter never computes XP, difficulty, or recommendations; Gemini never decides them either.
2. **Adaptive Engine decides WHAT happens next. Gemini generates WHAT content looks like.** These two responsibilities are never merged (see §18).
3. Deterministic logic is preferred over AI calls wherever a rule can decide reliably (see §33) — this keeps cost, latency, and behavior predictable.
4. Every AI response is validated before it touches the database or the client (see §31–33).
5. No frontend-facing behavior is invented independently of the API Contract; unresolved items are marked `[TBD]`.

---

## 7. Package Structure

```
backend/gamelearn-api/
└── src/main/java/com/gamelearn/
    ├── config/                # app, security, CORS, Swagger config
    ├── security/              # JWT filter, auth provider
    ├── controller/             # REST endpoints — thin, no logic
    ├── dto/                    # request/response contracts
    ├── entity/                 # JPA entities
    ├── repository/             # Spring Data repositories
    ├── service/                 # business logic orchestration
    ├── adaptive/
    │   ├── analyzer/            # PerformanceAnalyzer
    │   ├── mastery/             # TopicMasteryService
    │   ├── difficulty/          # DifficultyEngine
    │   └── recommendation/      # RecommendationEngine, WeakTopicDetector
    ├── ai/
    │   ├── gemini/               # Gemini client
    │   ├── prompts/              # prompt builders
    │   ├── parser/                # structured-output parsing
    │   └── validation/            # AI response validators
    ├── gamification/
    │   ├── xp/
    │   ├── level/
    │   ├── achievement/
    │   └── streak/
    ├── exception/               # GlobalExceptionHandler + custom exceptions
    └── util/
resources/
├── application.yml
├── prompts/                     # versioned prompt templates
└── db/migration/                # Flyway scripts
```

Controllers → Services → Repositories → Entities → MySQL. Controllers never touch repositories or Gemini directly.

---

## 8. Authentication

```
Register → Validate → Hash password → Save user
Login → Validate credentials → Generate JWT
Flutter stores token securely → attaches to authenticated requests
Spring Security validates token on each request
```

- JWT-based auth via Spring Security.
- Passwords hashed (BCrypt or equivalent) — **never** stored or returned in plain text.
- Never store Gemini keys or DB credentials in the frontend.
- `AUTH-001` (login), `AUTH-002` (register), `AUTH-003` (logout), `AUTH-000` (token validation) — as introduced in the Frontend Spec's API matrix; exact request/response DTOs `[TBD — API CONTRACT REQUIRED]`.

---

## 9. Authorization

| Access Level | Endpoints |
|---|---|
| Public | `POST /auth/register`, `POST /auth/login` |
| Authenticated | `/dashboard`, `/learning-path`, `/quizzes/*/submit`, `/ai/tutor`, `/progress`, `/achievements`, `/profile`, etc. |
| Admin-only | Content management, subject management, achievement management `[TBD — confirm which roles are in MVP scope]` |

Only implement roles the Master Specification actually requires — don't pre-build an admin system speculatively.

---

## 10. API Architecture

- Versioned under `/api/v1/...`.
- One standardized response envelope, **only if approved by the central API Contract**:

```json
{ "success": true, "message": "Operation successful", "data": {}, "timestamp": "..." }
```
```json
{ "success": false, "message": "Validation failed", "errorCode": "VALIDATION_ERROR", "errors": [], "timestamp": "..." }
```

If the API Contract specifies a different envelope, that document wins — this is a default proposal, not a final decision.

---

## 11. API Contract Integration

Every endpoint the backend implements must correspond 1:1 to a row in the shared API Dependency Matrix (Frontend Spec §11). Reproduced here for backend implementation ownership:

| API ID | Method | Endpoint | Auth | Controller | Service |
|---|---|---|---|---|---|
| AUTH-000 | GET/POST | `/api/v1/auth/validate` [TBD] | No | AuthController | AuthService |
| AUTH-001 | POST | `/api/v1/auth/login` | No | AuthController | AuthService |
| AUTH-002 | POST | `/api/v1/auth/register` | No | AuthController | AuthService |
| AUTH-003 | POST | `/api/v1/auth/logout` | Yes | AuthController | AuthService |
| DASH-001 | GET | `/api/v1/dashboard` | Yes | DashboardController | DashboardService |
| SUBJ-001 | GET | `/api/v1/subjects` | Yes | SubjectController | SubjectService |
| ASMT-001 | GET | `/api/v1/assessment/{subjectId}` | Yes | AssessmentController | AssessmentService |
| ASMT-002 | POST | `/api/v1/assessment/{subjectId}/submit` | Yes | AssessmentController | AssessmentService |
| ASMT-003 | GET | `/api/v1/assessment/{subjectId}/result` | Yes | AssessmentController | AssessmentService |
| PATH-001 | GET | `/api/v1/learning-path/{subjectId}` | Yes | LearningPathController | LearningPathService |
| TOPIC-001 | GET | `/api/v1/topics/{topicId}` | Yes | LearningPathController | LearningPathService |
| LESSON-001 | GET | `/api/v1/topics/{topicId}/lesson` | Yes | LessonController | LessonService |
| QUIZ-001 | GET | `/api/v1/quiz/{topicId}` | Yes | QuizController | QuizService |
| QUIZ-002 | POST | `/api/v1/quiz/{quizId}/submit` | Yes | QuizController | QuizService, AdaptiveLearningService, GamificationService |
| AI-001 | POST | `/api/v1/ai/tutor` | Yes | AiTutorController | AiTutorService |
| ACH-001 | GET | `/api/v1/achievements` | Yes | AchievementController | AchievementService |
| ACH-002 | GET | `/api/v1/achievements/{id}` | Yes | AchievementController | AchievementService |
| STREAK-001 | GET | `/api/v1/streak` | Yes | GamificationController | GamificationService |
| PROG-001 | GET | `/api/v1/progress` | Yes | ProgressController | ProgressService |
| PROG-002 | GET | `/api/v1/progress/{topicId}` | Yes | ProgressController | ProgressService |
| USER-001 | GET | `/api/v1/profile` | Yes | UserController | UserService |
| USER-002 | PUT/PATCH | `/api/v1/profile/settings` [TBD] | Yes | UserController | UserService |

All endpoint paths above are **proposed**, matching the Frontend Spec's placeholders — confirm against the final API Contract before implementation.

---

## 12. DTO Design

Never expose JPA entities over REST. Minimum DTO set:

```
RegisterRequest, LoginRequest, LoginResponse
UserResponse, DashboardResponse
AssessmentStartResponse, AssessmentSubmissionRequest, AssessmentResultResponse
LearningPathResponse, LearningNodeResponse
QuizResponse, QuizQuestionResponse, QuizSubmissionRequest, QuizResultResponse
ProgressResponse, AchievementResponse
AiTutorRequest, AiTutorResponse
RecommendationResponse
```

DTOs must match the central API Contract field-for-field — no undocumented fields required by the frontend (see §55 of testing).

---

## 13. Database Integration

```
Controller → Service → Repository → Entity → MySQL
```

Spring Data JPA + MySQL. No raw SQL/database logic in controllers. Multi-entity operations (e.g., quiz submission, §45) run inside `@Transactional` boundaries to avoid partial updates.

Initial conceptual entities — **fields TBD pending Database Specification**:

```
User, Subject, Topic, LearningPath, LearningPathNode, Lesson,
Quiz, Question, QuizQuestion, QuizAttempt, QuestionAttempt,
LearnerProfile, TopicMastery, Progress, Achievement, UserAchievement,
XpTransaction, Streak, AiInteraction, Recommendation
```
`[TBD — DATABASE SPECIFICATION REQUIRED]` for exact columns/relations.

---

## 14. Learner Profile

The learner profile is the backend's internal representation of learning state:

`user, currentLevel, currentSubject, overallMastery, topicMastery[], recentPerformance, weakTopics[], strongTopics[], difficultyHistory, learningProgress, streak, xp`

Only the subset relevant to a given screen is exposed via DTOs (e.g., Dashboard response) — internal profile detail is never dumped wholesale to the client.

---

## 15. Assessment Engine

```
Subject selected → Generate/retrieve assessment → Deliver questions
→ Receive answers → Evaluate → Topic-level analysis
→ Initialize/update learner profile → Determine starting difficulty
→ Generate initial recommendation → Persist result
```

Backed by `ASMT-001` (fetch), `ASMT-002` (submit/evaluate), `ASMT-003` (result). Evaluation and level-setting happen entirely server-side — the frontend never grades itself.

---

## 16. Performance Analysis

Do not rely on total score alone. Consider: accuracy, topic-level accuracy, recency, number of attempts, difficulty at time of attempt, correct-streaks, wrong-answer patterns, time taken (if collected). Exact weighting/feature set: `[TBD — ADAPTIVE ENGINE DECISION]`.

---

## 17. Topic Mastery

```
Topic → Mastery Score → Beginner / Developing / Proficient / Mastered
```

Must define, before implementation:
- Initialization rule (e.g., from assessment result)
- Update rule (per quiz attempt)
- Decay rule, if any (time-based forgetting) — `[TBD]`
- How it feeds the Recommendation Engine (§20)

Do not hard-code thresholds without documenting and validating them against real test data.

---

## 18. Adaptive Learning Engine

```
adaptive/
├── PerformanceAnalyzer
├── TopicMasteryService
├── WeakTopicDetector
├── DifficultyEngine
└── RecommendationEngine
```

**Flow:**

```
Quiz Result → Performance Analyzer → Topic Mastery Update
   → Weak Topic Detection → Difficulty Engine
   → Recommendation Engine → Next Activity
```

**Structured output (indicative, confirm against API Contract):**

```json
{
  "recommendedDifficulty": "MEDIUM",
  "topic": "IP Addressing",
  "activityType": "PRACTICE",
  "reason": "Recent performance indicates this topic needs reinforcement"
}
```

This is the payload the Frontend Spec's Quiz Result / Next Recommendation screens render directly (§10, §16 of the Frontend Spec) — field names must match exactly once finalized.

---

## 19. Difficulty Engine

Levels: `EASY / MEDIUM / HARD`.

```
Strong performance   → increase difficulty
Stable performance    → maintain difficulty
Weak performance      → reduce difficulty / recommend remediation
```

**Do not** implement a naive `if score > 80 → HARD` rule. The engine must weigh: current difficulty, topic, historical performance, number of attempts, recent trend. Exact algorithm: `[TBD — ADAPTIVE ENGINE DECISION]`, but the interface (inputs → output difficulty) must be fixed early so it's testable (see §54's deterministic test cases).

---

## 20. Weak Topic Detection

Signals: low accuracy, repeated incorrect answers, low mastery, multiple failed attempts, declining recent trend.

```
Weak Topic → Remedial Recommendation → AI Explanation → Practice → Reassessment
```

---

## 21. Recommendation Engine

Answers: *"What should this learner do next?"* — continue lesson, practice weak topic, take quiz, review previous topic, increase difficulty, move to next topic.

Priority order (subject to finalization): (1) learning dependency, (2) topic mastery, (3) recent performance, (4) current difficulty, (5) learning progress, (6) user goal if applicable. Exact ranking algorithm: `[TBD — ADAPTIVE ENGINE DECISION]`.

---

## 22. Gamification Engine

Backend is authoritative for XP, level, achievement unlocks, streak, and reward. Frontend only displays results (Frontend Spec §17).

### XP System
```
Activity → Reward Rule → XP Transaction → User XP total → Level Calculation
```
Use an **XP transaction history** (`XpTransaction` entity), not silent mutation of a running total — this keeps XP auditable/traceable. Exact per-activity values: `[TBD — GAMIFICATION DECISION]`.

### Level System
```
Total XP → Level Formula/Thresholds → Current Level → Progress to Next Level
```
Exact thresholds: `[TBD — GAMIFICATION SPECIFICATION]`.

### Achievement System
Deterministic, testable rules, e.g.: first challenge completed, first path completed, 7-day streak, 10 challenges completed, topic mastery achieved.
```
Event → Achievement Engine → Check Rules → Unlock → Create UserAchievement → Notify
```

### Streak System
Must explicitly define: what counts as a "learning day," increment rule, reset rule, whether missed days are recoverable, timezone handling. Do not leave this ambiguous — mark unresolved parts `[TBD — GAMIFICATION DECISION]`.

---

## 23. Generative AI Architecture (Gemini)

```
Spring Boot → Prepare Context → Build Structured Prompt → Gemini API
   → Receive Response → Validate Response → Parse Structured Data
   → Business Validation → Persist if required → Return to Flutter
```

### AI Use Cases
| ID | Use Case |
|---|---|
| AI-LP | Personalized learning path generation |
| AI-QG | Quiz/question generation |
| AI-LE | Lesson/explanation generation |
| AI-HINT | Hint generation |
| AI-001 | AI Tutor (matches Frontend Spec's `AI-001` conversational endpoint) |
| AI-REC | Recommendation support content (not the decision itself) |

Each of these needs its own micro-spec (prompt, input context, output schema, validation rules) before implementation — not fully defined here; treat as `[TBD — AI SPECIFICATION REQUIRED]` per use case until written.

### AI Learning Path Generation
Input context: subject, goal, learner level, topic mastery, weak/strong topics, completed topics, desired duration (if supported). Backend validates: required fields present, valid topic relationships, valid difficulty values, content completeness, safe output. Never persist raw model output without validation.

### AI Quiz Generation
Gemini may generate question, options, correct answer, explanation, difficulty, topic. Backend validates: exact required option count, valid correct-answer reference, valid difficulty enum, valid topic reference, no missing fields.

### AI Tutor
```
Flutter → AI-001 → Spring Boot → retrieve learner context → build prompt
   → Gemini → validate response → return answer
```
Context may include current subject/topic, learner level, current difficulty, recent weak topics, relevant content. **Never expose hidden system prompts to the user** — matches Frontend Spec §15's rule.

---

## 24. AI Prompt Architecture

Prompts are version-controlled application assets, not inline strings scattered through Java classes.

```
resources/prompts/
├── learning-path/
├── quiz/
├── tutor/
├── explanation/
└── recommendation/
```

Each prompt file documents: version, purpose, input variables, output schema, validation rules, example input, example output.

```
Prompt Template = System Instruction + Learner Context + Task + Output Schema → Gemini
```

Never depend on free-form responses when structured data is required — always specify an explicit output schema.

---

## 25. AI Response Validation

```
Schema Validation → Business Validation → Content Validation → Accept / Reject
```

If invalid: retry if appropriate, attempt a controlled repair, otherwise return a safe fallback. Always log technical failure details server-side; never expose internal AI failure details to the end user.

---

## 26. AI Failure Handling

Gemini may time out, return malformed data, be unavailable, return incomplete content, or hit rate limits. Backend must degrade gracefully:

```
AI unavailable → fall back to existing approved content → learning continues
```

The app must never become unusable purely because Gemini is temporarily down.

---

## 27. AI Cost / Performance Control

Prefer deterministic backend logic wherever it's reliable. Do **not** ask Gemini decision questions like *"should difficulty increase?"* — that's the Difficulty Engine's job (§19). Call Gemini only for generation once a decision is already made:

```
Adaptive Engine decides: Difficulty=HARD, Topic=Routing
        ↓
Gemini generates: HARD Routing challenge content
        ↓
Backend validates → persists → returns
```

This is the **AI + Adaptive Engine boundary** and is a non-negotiable architectural rule: Adaptive Engine decides *what* happens next; Gemini generates *what content* is shown.

---

## 28. Optional ML Layer

Not mandatory unless approved for MVP. If included:

```
MySQL Learner Data → Python ML Service → Prediction → Spring Boot → Adaptive Engine
```

Potential tasks: performance prediction, difficulty recommendation, topic-mastery prediction, learner clustering. Communication via a defined internal API, e.g. `POST /predict/performance [TBD]`. Only add if it provides measurable benefit over deterministic rules — not for technology-count's sake.

---

## 29. Security

- Password hashing, JWT auth, authorization checks on every protected endpoint.
- Input validation on every DTO — **never trust frontend validation alone** (§30).
- SQL injection protection via ORM/parameterized queries only.
- HTTPS enforced in production; CORS explicitly configured per environment (never `Allow-Origin: *` in production).
- Rate limiting on expensive AI endpoints where appropriate.
- Secrets via environment variables only — never hard-coded (§34).
- No stack traces or internal error detail returned to the client.

---

## 30. Input Validation

All incoming data validated server-side regardless of client-side checks already done. Examples:

- **Email:** required, valid format.
- **Password:** required, minimum length per contract.
- **Quiz submission:** valid quiz ID, valid question IDs, valid answer format, user must own the attempt.
- **AI Tutor message:** non-empty, max length, valid authenticated user.

---

## 31. Error Handling

Centralized via `GlobalExceptionHandler`, covering: validation errors, authentication errors, authorization errors, not-found, conflict, business-rule violations, AI service failures, database failures, unexpected server errors. Never expose stack traces to the mobile client — map every exception type to a safe, consistent error response (mirrors the frontend's `ApiException` hierarchy in Frontend Spec §19).

---

## 32. Logging

Structured logs should capture: request correlation ID, API operation, error category, AI request status, DB failures, key adaptive-engine decisions.

**Never log:** passwords, JWT tokens, API keys, unnecessary sensitive user data, full private tutor conversations (unless explicitly required and handled safely).

---

## 33. Configuration Management

No hard-coded secrets. Use environment variables, e.g.:

```
DB_URL, DB_USERNAME, DB_PASSWORD
JWT_SECRET
GEMINI_API_KEY, GEMINI_MODEL
```

Exact variable names finalized in the deployment spec. Provide a `.env.example` with placeholders only — never real values.

---

## 34. Testing Strategy

| Type | Covers |
|---|---|
| Unit | Business logic, difficulty engine, XP/level calculations, achievement rules, recommendation logic, validators |
| Controller/API | Valid/invalid requests, auth, authorization, response structure, status codes |
| Repository | Key database behavior |
| Integration | API → Service → Database, full round trip |
| AI Testing | Valid response, missing field, malformed JSON, invalid difficulty/topic, empty response, timeout, API failure, rate limit, unsafe content — **AI is never treated as deterministic** |
| Adaptive Engine | Deterministic input/output cases, e.g. MEDIUM difficulty + strong recent performance + high mastery → expect HARD/increase; MEDIUM + weak performance + low mastery → expect reduce/remediation. Also test boundary values, repeated failure/success, conflicting signals, new learner (no data), insufficient data. |
| Contract Testing | Backend response exactly matches API Contract: field names, types, status codes, error format — no undocumented fields required by the frontend |

---

## 35. Integration Testing Scenario (Primary E2E)

```
Register → Login → Select Subject → Assessment → Learner Profile
   → Learning Path → Lesson → Quiz → Quiz Submission
   → Performance Analysis → Adaptive Decision → Recommendation
   → XP → Achievement → Progress Update → Dashboard
```

This is the canonical end-to-end scenario both members test against.

---

## 36. Transactional Consistency

Multi-entity operations run inside transactions. Example — quiz submission:

```
Evaluate Quiz → Save Attempt → Update Topic Mastery → Update Progress
   → Calculate XP → Create XP Transaction → Check Achievement
   → Update Streak → Create Recommendation
```

If any critical step fails, the operation rolls back rather than leaving partially-updated learner state.

---

## 37. API ↔ Database ↔ AI Traceability

Every major feature should be traceable end to end for debugging:

```
API → Controller → Service → Database → Adaptive Engine → AI (if required) → Response
```

---

## 38. Deployment

```
Flutter Mobile → APK / App Build
Spring Boot     → Render [TBD — confirm hosting]
MySQL           → Railway [TBD — confirm hosting]
Gemini          → Google AI API
```

Environment separation via `application-dev.yml`, `application-test.yml`, `application-prod.yml`. Never commit production credentials. Observability via Spring Boot Actuator kept lightweight — do not over-engineer monitoring for a hackathon timeline.

---

## 39. Development Phases

1. **Foundation** — Spring Boot, Maven, config, package structure, DB connection, exception handling
2. **Security** — Registration, Login, JWT, Authorization
3. **User & Dashboard** — User APIs, Dashboard API, Profile
4. **Subjects & Assessment** — Subjects, Assessment, Learner Profile
5. **Learning Path** — APIs, AI generation, persistence, validation
6. **Lessons & Quiz** — Lessons, Questions, Quiz, Submission, Evaluation
7. **Adaptive Intelligence** — Performance analysis, topic mastery, weak-topic detection, difficulty engine, recommendation engine
8. **Gamification** — XP, Levels, Achievements, Streak
9. **AI Tutor** — Context construction, Gemini integration, response validation, conversation handling
10. **Analytics** — Progress, Performance, Topic mastery
11. **Testing** — Unit, API, Integration, AI, Adaptive engine
12. **Deployment** — Environment config, production DB, backend deployment, monitoring, final integration

---

## 40. Backend Definition of Done

- [ ] Requirement implemented [ ] API Contract implemented [ ] DTOs implemented
- [ ] Validation implemented [ ] Business logic implemented [ ] Database interaction implemented
- [ ] Error handling implemented [ ] Security checked
- [ ] Unit / API / Integration tests written and passing
- [ ] Swagger updated [ ] Frontend mock/client tested
- [ ] No compilation/runtime errors [ ] Logs reviewed [ ] Code reviewed

**AI features additionally require:**
- [ ] Prompt versioned [ ] Structured output defined [ ] Response validation implemented
- [ ] Failure handling implemented [ ] Retry/fallback strategy defined [ ] AI test cases completed

---

## 41. Frontend Integration Rules

- Both members build against the **same** API IDs (§11 table here = Frontend Spec §11 table).
- Request/response field names, types, auth requirements, and error structures must match exactly on both sides.
- Backend must remain consumable by Member 1's mock-data strategy (Frontend Spec §30) — mock JSON must mirror real responses field-for-field.
- Swagger/OpenAPI docs kept in sync with the actual contract at all times.

---

## 42. Contract Conflict Resolution

If backend implementation and frontend expectation disagree, do **not** silently patch either side. Log it explicitly:

```
CONTRACT CONFLICT
API ID: QUIZ-002
Expected (Frontend): xpEarned
Actual (Backend): experiencePoints
Status: BLOCKED
Required Action: Resolve against API Contract
```

Resolution order: **API Contract updated → Backend updated → Frontend updated → Tests updated → synchronized.**

---

## 43. Backend Developer Rules (Member 2)

1. Follow the Master Specification, API Contract, and Database Specification.
2. Never invent frontend-facing APIs without documenting them.
3. Never expose database entities directly; always use DTOs.
4. Never expose secrets (DB creds, JWT secret, Gemini key) anywhere client-reachable.
5. Never put business logic in controllers.
6. Never allow Flutter to call Gemini directly — orchestration only through Spring Boot.
7. Validate every AI response before persisting or returning it.
8. Keep all adaptive decisions in the backend, not in prompts to Gemini.
9. Write tests before declaring a feature complete.
10. Update Swagger whenever an API changes.
11. Never silently change an API contract — use the conflict-resolution process (§42).
12. Keep modules maintainable; do not over-engineer for a hackathon timeline.
13. Prefer deterministic logic over AI calls wherever a rule suffices (§27).
14. Keep AI prompts version-controlled under `resources/prompts/`.
15. Handle AI failures gracefully — the app must degrade, not break (§26).
16. Ensure every completed feature is actually consumable by the Flutter frontend before marking it done.

---

## 44. Open Questions / TBD Items

- Final API Contract — all endpoint paths, request/response DTOs in §11 are **placeholders**.
- Database Specification — entity fields/relationships listed in §13 are conceptual only.
- Standard response envelope (§10) — pending API Contract confirmation.
- Admin role scope (§9) — confirm what's actually in MVP.
- Difficulty Engine and Recommendation Engine exact algorithms (§19, §21) — architecture/interfaces are fixed here, weighting is not.
- XP values per activity and level thresholds (§22) — `[TBD — GAMIFICATION SPECIFICATION]`.
- Streak rules — learning-day definition, timezone handling, recovery policy (§22).
- Individual AI use-case specs (learning path, quiz gen, hints, tutor, recommendation support) — each needs its own prompt/schema spec (§23).
- Optional ML layer — include only if approved for MVP (§28).
- Hosting targets for Spring Boot/MySQL (§38) — tentative (Render/Railway), needs confirmation.

Anything above must stay explicitly `[TBD]` in code/PRs until the corresponding spec is finalized — no silent architectural decisions.

---

*End of Specification.*
