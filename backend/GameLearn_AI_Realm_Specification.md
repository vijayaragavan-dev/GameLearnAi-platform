# GameLearn AI - Realm Specification (REALM-001)

Learning-realm foundation: Computer Science realm + first non-CS realm
(Aptitude). Additive only — no existing contract, table, or behavior
was modified to produce it.

## 1. Model

- `realms` table: `id` (CHAR36 UUID PK), `realm_key` (unique, UPPER_SNAKE,
  immutable), `name`, `description`, `icon_key`, `is_active`,
  `display_order`, timestamps. Entity: `com.gamelearn.entity.Realm`.
- `subjects.realm_id`: nullable FK → `realms(id)`. Nullable for migration
  safety; V30 backfills every pre-existing subject to Computer Science.
  New realm-scoped content MUST set an explicit realm.
- Seed rows: `COMPUTER_SCIENCE` (`0a0a…0a01`), `APTITUDE` (`0a0a…0a02`).
  No other realm rows exist in the database. Verbal/FullStack/AI-Data/
  Cyber remain frontend-only honest placeholders.

## 2. Subject → Realm ownership

- Realm 1 — * Subject. Backend-authoritative; never inferred from
  names/icons (frontend keeps its own heuristic mapping for display
  only, which this contract does not depend on).
- Realm is derivable for results/analytics via subject joins. Result
  rows carry no realm columns by design (progression stays global).

## 3. API (all under existing JWT policy — no security change)

- `GET /api/v1/realms` → active realms ordered by display_order.
- `GET /api/v1/realms/{realmKey}` → single active realm; unknown or
  inactive keys → 404 `RESOURCE_NOT_FOUND`. Key lookup is
  case-insensitive.
- `GET /api/v1/realms/{realmKey}/subjects` → active subjects of the
  realm ordered by display_order (existing `SubjectResponse` shape).
- Additive change: `SubjectResponse` gains nullable `realmKey`
  (legacy rows: null only if never backfilled; all seeded rows carry
  one). All other fields and semantics unchanged.

## 4. Migration chain (new files only, V29–V33)

- V29: `realms` table + `subjects.realm_id` FK + index.
- V30: seed both realms + backfill all NULL `realm_id` to CS.
  Existing UUIDs/content untouched; only the backfill column changes.
- V31: Aptitude subject (`5555…01`, display_order 100) + 2 units
  (Arithmetic, Reasoning) + 6 skill topics.
- V32: 18 curated MCQs (3 per topic, verified answers).
- V33: compat rows `quiz_battle` + `speed_run` only (QUESTION-kind
  games runnable on pure MCQ; nothing else exposed).

## 5. Game compatibility

`SubjectGameCompat` remains authoritative; clients never infer.
Aptitude exposes exactly `quiz_battle` and `speed_run`. Unsupported
combinations keep existing behavior (400 `VALIDATION_FAILED` from
game-content, unchanged code path).

## 6. Result / XP / mastery compatibility

`POST /api/v1/me/game-results` is subject-agnostic (200 by existing
contract); XP/levels/streak/achievements accrue globally with zero
code changes. Mastery continues per-topic via existing flows.

## 7. Future extension model

New realm = `realms` row + subjects/topics/questions + compat rows
(same 5-step migration shape). Structures beyond world-backed content
need no platform changes until a realm requires non-UUID content
identity — at which point extend, never migrate, the world system.
Frontend `RealmLearningStructure` declares intent; backend owns truth.

## 8. Intentionally not implemented

Realm mutation/admin endpoints, per-realm XP/mastery, cross-realm
recommendations, tutor realm context changes, RAG/embedding changes.
