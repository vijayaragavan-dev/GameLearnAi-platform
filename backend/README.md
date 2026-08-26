# GameLearn AI — Backend

Smart Adaptive Learning Adventure (AIS-01 · Edutainment · Flutter + Java Spring Boot + MySQL + Gemini).

**Current status: PHASE 7 COMPLETE — Gamification Engine (XP · Levels · Achievements · Streaks)**
(built on Phases 0–6: foundation, database/persistence, authentication, core learning API,
assessment/quiz system, adaptive learning engine v1.0.0, learning-path AI + Gemini).
Remaining future phases: dashboard, assessment endpoints (ASMT), AI tutor, analytics, deployment.

## Technology stack

| Concern    | Choice                                             |
|------------|----------------------------------------------------|
| Language   | Java 21 (LTS, Temurin)                             |
| Framework  | Spring Boot 3.5.16                                 |
| Build      | Maven 3.9+ (`./mvnw` wrapper included)             |
| Database   | MySQL 8                                            |
| Migrations | Flyway                                             |
| API docs   | springdoc-openapi (Swagger UI)                     |
| Tests      | JUnit 5, Mockito (via spring-boot-starter-test), MockMvc, Testcontainers (MySQL), H2 |

Spring Boot 3.5.16 was chosen as the final, fully-patched release of the mature
3.5 line: maximum stability and documentation coverage for a hackathon team,
full Java 21 support, and a clean upgrade path to Boot 4 later because the
dependency surface stays minimal.

## Package architecture

```
com.gamelearn
├── auth/           JWT service, authentication filter, security JSON handlers
├── config/         CORS, OpenAPI, security baseline
├── controller/     REST controllers (thin)
├── dto/            Request/response records (never JPA entities)
├── logging/        request correlation ID filter (MDC)
├── exception/      ApiException hierarchy, ErrorResponse, GlobalExceptionHandler
├── entity/         JPA entities for all 20 approved tables (+ enums/)
├── repository/     Spring Data JPA repositories (one per entity)
└── service/        AuthService (registration/login/validation)

Planned for later phases (do not create empty packages):
adaptive/{analyzer,mastery,difficulty,recommendation}/
ai/{gemini,prompts,parser,validation}/
gamification/{xp,level,achievement,streak}/ security-review util/
```

Layering rule for all future code: `Controller → Service → Repository → Entity → MySQL`.
Controllers stay thin, business logic lives in services, REST responses use DTOs,
Flutter never touches MySQL or Gemini directly, and AI output is always validated
before persistence.

## Prerequisites

- JDK 21 (Temurin recommended)
- Docker Desktop (optional — enables the real-MySQL integration tests; without it those tests skip automatically)
- MySQL Server 8 (for running the app locally)

## Required environment variables

Copy `.env.example` to `.env` and fill in values. **Never commit `.env`.**

| Variable                  | Used by            | Phase 2 status                          |
|---------------------------|--------------------|------------------------------------------|
| `SPRING_PROFILES_ACTIVE`  | app                | `dev` default                            |
| `DB_URL`                  | dev/prod profiles  | required at runtime                      |
| `DB_USERNAME`             | dev/prod profiles  | required at runtime                      |
| `DB_PASSWORD`             | dev/prod profiles  | required at runtime                      |
| `CORS_ALLOWED_ORIGINS`    | all profiles       | comma-separated origin list              |
| `JWT_SECRET`              | auth (Phase 2)     | **required**, min 32 chars, fails fast   |
| `JWT_EXPIRATION_MINUTES`  | auth (Phase 2)     | optional, default `60`                   |
| `GEMINI_API_KEY`          | future AI phase    | placeholder only                         |
| `GEMINI_MODEL`            | future AI phase    | placeholder only                         |

Loading examples:

```bash
# Git Bash / Linux / macOS
set -a; source .env; set +a

# PowerShell
Get-Content .env | ForEach-Object { $n,$v = $_ -split '=',2; [Environment]::SetEnvironmentVariable($n,$v,'Process') }
```

IntelliJ: Run Configuration → Environment variables → paste the file content via the macro dialog.

## MySQL setup (local development)

```sql
CREATE DATABASE gamelearn CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'gamelearn'@'localhost' IDENTIFIED BY '<your-password>';
GRANT ALL PRIVILEGES ON gamelearn.* TO 'gamelearn'@'localhost';
FLUSH PRIVILEGES;
```

Then in `.env`: `DB_URL=jdbc:mysql://localhost:3306/gamelearn`, plus your username/password.

Schema note: Hibernate runs with `ddl-auto=none`; Flyway owns all schema evolution
(`src/main/resources/db/migration`). The full Phase 1 schema (20 tables from
`GameLearn_AI_Database_Specification.md`) is created by migrations V2–V11;
V11 seeds the five initial subjects with deterministic reserved UUIDs
(`11111111-…-01..05`). UUIDs are stored as `CHAR(36)` and bound by Hibernate
as CHAR via `hibernate.type.preferred_uuid_jdbc_type=char`.

## How to run

```bash
set -a; source .env; set +a   # load env vars first
./mvnw spring-boot:run        # uses SPRING_PROFILES_ACTIVE (default: dev)
```

The backend listens on port `8080` (override with `SERVER_PORT` if occupied).

## Authentication (Phase 2)

JWT bearer authentication, versioned under `/api/v1`:

| API ID   | Method + Path              | Auth          | Notes                                             |
|----------|----------------------------|---------------|---------------------------------------------------|
| AUTH-002 | `POST /api/v1/auth/register` | public        | 201; creates user **and** learner profile atomically |
| AUTH-001 | `POST /api/v1/auth/login`    | public        | 200; failures are always a generic 401            |
| AUTH-000 | `GET  /api/v1/auth/validate` | bearer token  | 200 identity view or 401                          |
| AUTH-003 | `POST /api/v1/auth/logout`   | bearer token  | 204; stateless — clients discard the token        |

- Passwords: BCrypt hashes in `users.password_hash`; never returned, never logged.
- Tokens: HS256 JWT signed with `JWT_SECRET` (env, min 32 chars — startup fails fast otherwise).
  Claims carry only user id/email/display name; expiry and issuer are verified on every request.
- Identity propagation: the filter validates the signature, then loads the account and enforces
  `ACTIVE` status — suspended/deleted accounts cannot use outstanding tokens. Services take the
  caller from `SecurityContext`, never from request parameters.
- No refresh tokens: not part of the approved specification.
- Rate limiting is a documented hardening item for a later phase.

## Core learning API (Phase 3)

All endpoints require the `Authorization: Bearer <token>` header. Identity always comes
from the token — client-supplied user ids are ignored for ownership decisions.

| API ID   | Method + Path                        | Response (camelCase JSON)                          | Status codes |
|----------|--------------------------------------|----------------------------------------------------|--------------|
| SUBJ-001 | `GET /api/v1/subjects`               | `[{id,name,description,iconKey,isActive,displayOrder}]` — active only, ordered by `displayOrder` | 200 |
| TOPIC-001| `GET /api/v1/topics/{topicId}`       | `{id,subjectId,subjectName,name,description,difficulty,displayOrder}` | 200 / 404 / 400 |
| LESSON-001| `GET /api/v1/topics/{topicId}/lesson`| `{id,topicId,title,content,summary,difficulty,sourceType}` — canonical oldest active lesson | 200 / 404 / 400 |
| PATH-001 | `GET /api/v1/learning-path/{subjectId}` | `[{id,subjectId,title,description,status,generatedBy,nodes:[{id,topicId,topicName,sequenceNumber,requiredMastery,status}]}]` — caller-owned only; empty list when none exist yet | 200 / 404 / 401 |
| USER-001 | `GET /api/v1/profile`                | `{id,email,displayName,currentLevel,totalXp,overallMastery,currentSubjectId,currentTopicId}` — read-only | 200 / 401 |
| PROG-001 | `GET /api/v1/progress`               | `[{id,topicId,learningPathNodeId,completionPercentage,status,lastActivityAt,completedAt}]` newest first | 200 / 401 |
| PROG-002 | `GET /api/v1/progress/{topicId}`     | single progress record                             | 200 / 404 / 401 |

Notes: inactive subjects/topics are hidden from learners (404). Learning paths and
progress are read-only until the assessment/adaptive phases create them. Timestamps are
ISO-8601 UTC strings.

## Quiz API (Phase 4)

| API ID   | Method + Path                        | Request / Response                                                                                                 | Status codes |
|----------|--------------------------------------|--------------------------------------------------------------------------------------------------------------------|--------------|
| QUIZ-001 | `GET /api/v1/quiz/{topicId}`         | → `{id,topicId,title,description,difficulty,timeLimitSeconds,questionCount,questions:[{id,questionText,options,difficulty}]}` — **never** includes correct answers/explanations | 200 / 404 / 400 |
| QUIZ-002 | `POST /api/v1/quiz/{quizId}/submit`  | `{answers:[{questionId,selectedAnswer}]}` → `{attemptId,quizId,status,score,correctCount,totalQuestions,durationSeconds,results:[{questionId,selectedAnswer,isCorrect,correctAnswer,explanation}]}` | 201 / 400 / 401 / 404 |

- The backend is the sole authority for correctness and score; client-supplied
  `score/isCorrect/status` fields are ignored.
- Scoring rule (documented default): `score = correctCount / totalQuestions × 100`
  at two decimals. Unanswered questions count as incorrect.
- Submission is atomic: attempt creation, per-question attempts and finalization commit
  together or not at all (spec §36). Each submission produces an independent attempt row,
  so double-taps can never corrupt state.
- Correct answers/explanations are revealed only inside the post-submission result.

## Gamification API (Phase 7)

Read-only state of the authenticated learner. All values are server-derived;
there are no mutation endpoints and no client-controllable reward fields
(authority: GameLearn_AI_Gamification_Specification.md v1.0.0 APPROVED,
API Contract v1.1.0 section 5A).

| API ID   | Method + Path                        | Response |
|----------|--------------------------------------|----------|
| GAM-001  | `GET /api/v1/gamification/summary`    | `{totalXp,currentLevel,maxLevel,nextLevelThresholdXp|null,xpToNextLevel|null,currentStreakDays,longestStreakDays,achievementCount}` — next-level fields null at max level 50 |
| GAM-002  | `GET /api/v1/achievements`            | `[{code,name,description,iconKey,xpReward,unlockedAt|null}]` — full active catalog, one entry per achievement |
| GAM-003  | `GET /api/v1/streak`                  | `{currentStreakDays,longestStreakDays,lastLearningDate|null,timezone}` — zero-state before the first activity |

- Every processed quiz submission awards `QUIZ_COMPLETED` (+10) plus a
  `QUIZ_PERFORMANCE` component of `round_half_up_2(score × 0.15)` (0–15),
  inside the same atomic transaction as the Adaptive Engine update.
- Learning streaks use calendar days in the learner's streak timezone
  (fixed to UTC until the profile-settings feature lands); missing two or
  more days resets the current streak; milestones at 3/7/14/30 days pay
  one-shot bonuses.
- Achievements unlock exactly once (DB-enforced); the six-entry starter
  catalog is seeded automatically at startup.

## Health & readiness

- `GET /actuator/health` → `{"status":"UP",...}`
- `GET /actuator/health/readiness`
- `GET /actuator/health/liveness`

Only `health` and `info` actuator endpoints are exposed; details/components are
hidden so no infrastructure information leaks.

## Swagger / OpenAPI

- Swagger UI: http://localhost:8080/swagger-ui/index.html
- OpenAPI JSON: http://localhost:8080/v3/api-docs

## How to test

```bash
./mvnw clean verify
```

- The main suite runs against H2 (MySQL-compatibility mode) — no external services needed.
  It covers repository CRUD, constraints, enum-as-string persistence, JSON columns,
  transaction rollback, and full authentication flows (register/login/validate/logout,
  token rejection, anti-enumeration, suspended-account enforcement).
- `MySqlIntegrationTest` additionally verifies the complete migration chain against a
  real MySQL 8 container via Testcontainers (all 20 tables, foreign keys, unique
  constraints, indexes, seed data, UUID/JSON behaviour); it skips automatically when
  Docker is unavailable.
- Why both: H2 keeps the suite fast and runnable everywhere; Testcontainers
  proves MySQL-specific behaviour where it matters.

## Development configuration

Profiles:

- `application.yml` — shared base (JPA safety flags, Flyway, actuator exposure, log pattern with correlation ID)
- `application-dev.yml` — local MySQL defaults, SQL logging, permissive localhost CORS pattern
- `application-test.yml` (test classpath) — H2 in-memory
- `application-prod.yml` — requires `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `CORS_ALLOWED_ORIGINS` from the environment (fails fast when missing)

CORS origins are configuration-driven (`gamelearn.cors.allowed-origins`).
Development may use `http://localhost:[*]` to allow any local Flutter web port.
**Wildcard `"*"` is rejected at startup in every profile.** Production must list
exact origins, e.g. `https://app.gamelearn.example`.

## Security & secret handling

- No credentials, keys, or tokens exist in the repository; `.gitignore` blocks `.env*`.
- Every error response is a safe JSON envelope (`ErrorResponse`) — never a stack trace,
  including 401/403 raised inside the security filter chain.
- Public endpoints are explicitly enumerated; everything else requires authentication.
- CSRF is disabled and sessions are stateless — appropriate for the token-based mobile API.
- Logs carry a request correlation ID (`X-Request-ID`) and contain no secrets, tokens or
  password material.
