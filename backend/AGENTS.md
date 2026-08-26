# AGENTS.md — GameLearn AI Backend

Instructions for AI coding agents (OpenCode) working in this repository.

## Project

Smart Adaptive Learning Adventure (AIS-01 · Edutainment). This repo is the **Java Spring Boot backend** only; the Flutter client is a separate project.

| Concern    | Choice |
|------------|--------|
| Language   | Java 21 (LTS) |
| Framework  | Spring Boot 3.5.16 |
| Build      | Maven (`./mvnw` wrapper included, no local Maven needed) |
| Database   | MySQL 8, schema owned **exclusively by Flyway** (`src/main/resources/db/migration`, V1–V11) |
| API docs   | springdoc-openapi → Swagger UI + `/v3/api-docs` at runtime |
| Auth       | JWT bearer (`jjwt`), filter under `com.gamelearn.auth` |
| Tests      | JUnit 5, Mockito, MockMvc, H2 (always), Testcontainers MySQL (skips if Docker is down) |

## Key directories

- `src/main/java/com/gamelearn/` — layering rule: `controller → service → repository → entity`. Controllers stay thin; responses use DTO records from `dto/`, never JPA entities.
- `src/main/resources/db/migration/` — Flyway migrations. Never edit an applied migration; add a new `V{n}__*.sql`.
- `GameLearn_AI_*.md` — authoritative specs: API contract, database schema, adaptive engine, assessment, gamification, learning-path AI.
- `.env` — real config (gitignored). `.env.example` is a placeholder template only.

## Commands

```bash
set -a; source .env; set +a   # load env vars first
./mvnw spring-boot:run        # run app on :8080
./mvnw test                   # unit tests (H2)
./mvnw verify                 # full build incl. Testcontainers tests (needs Docker)
```

## MCP usage strategy

Configured in `opencode.json` (project-level). Use selectively — never invoke every server for every task.

### context7 (documentation research)
Use before implementing against any framework/library API (Spring Boot, springdoc, jjwt, Flyway…): resolve the library ID with `resolve-library-id`, then fetch current docs with `query-docs`. Never invent APIs from memory when the installed version may differ. Check the actual version in `pom.xml` first.

### playwright (browser automation)
Use to actually verify behavior instead of assuming it works: navigate pages, take accessibility snapshots, read console errors and network requests. The backend serves Swagger UI on `http://localhost:8080/swagger-ui/index.html` (currently behind auth) and OpenAPI JSON at `/v3/api-docs`. For authenticated flows, log in via the API first or use Playwright to drive the login form.

### mysql (database inspection — READ-ONLY)
Connects as dedicated user `gamelearn_ro` (SELECT-only grant, password stored in Windows user env var `GAMELEARN_MCP_RO_PASSWORD`, never in this repo). Two tools:
- `search_objects` — list tables / describe columns, indexes, foreign keys (call with no args for table list).
- `execute_sql` — safe SELECT queries (row cap 1000, 30 s timeout).

Rules: inspect schema before writing SQL; use for debugging persistence issues and validating data. All writes go through the application/Flyway — never attempt data changes via MCP (the session blocks them anyway). Any intentional write operation requires explicit human approval and must not run through this read-only channel.

## Security rules

- Never print, log, commit, or copy secret values (JWT_SECRET, DB_PASSWORD, GEMINI_API_KEY, MCP credentials). Reference them as `{env:VAR}` in configs.
- `.mcp-setup/` contains local setup tooling and is gitignored — do not commit it.
- If a secret ever appears in tracked files, flag it immediately and require rotation.

## Verification requirements

Before declaring any task complete:
1. `./mvnw test` passes (or targeted test class).
2. For REST changes: verify contract matches `GameLearn_AI_API_Contract.md` and check live response shapes via Swagger/OpenAPI JSON.
3. For UI-visible or endpoint behavior changes: confirm with Playwright where practical.
4. For persistence changes: inspect affected tables via mysql MCP after running the app/migrations.

## Git workflow

- Never commit or push without explicit instruction.
- Do not stage secrets; review diffs before committing.
