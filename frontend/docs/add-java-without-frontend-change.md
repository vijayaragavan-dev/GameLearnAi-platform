# How to Add Java (or Any Core CS Subject) — Without a Frontend Change

**GameLearn AI — Core CS Subject Universe Expansion (Phase 2)**
Version: 1.0 · Date: 2026-08-27 · Authority: Frontend Future Development Blueprint v1.0.0 §11–§13, §42 Phase 2

## 1. The Rule

> **Adding a subject is backend content configuration. It is never frontend application code.**

The Flutter client is subject-agnostic. It never branches on `if (subject.name == "Java")`, never creates `JavaScreen`, `JavaRepository`, `JavaRoute`, `JavaProvider`, `JavaCard`, or any per-subject business logic. Every learning behavior (mastery, difficulty, recommendations, XP, streaks, achievements, path gating) is backend-authoritative and rendered verbatim.

If you can add Java without changing `frontend/lib/`, the architecture is correct.

---

## 2. Current End-to-End Architecture (What Already Exists)

```
Backend (MySQL + Spring Boot)                          Flutter (generic)
--------------------------                             -----------------
subjects table  ─┐
topics           │                                      SubjectsScreen
lessons          ├─ GET /api/v1/subjects (SUBJ-001) ─→  Subject model
quizzes          │   plain DTO list, ordered by          (id, name, description,
questions        │   displayOrder, bearer JWT              iconKey, displayOrder)
                 │                                      ↓
                 │                               PressableWorldCard (single
                 │                               generic widget, tint =
                 │                               displayOrder % 5 decorative)
                 │                                      ↓
                 │                               Tap world ─→ GoRouter
                 │                               /path/:subjectId?name=
                 │                               (ID authoritative,
                 │                                name presentation-only)
                 │                                      ↓
                 │                               PATH-001 / PATH-002
                 │                               → Adventure Maps (generic nodes)
                 │                               → TopicDetail (TOPIC-001)
                 │                               → Lesson (LESSON-001)
                 │                               → Quiz (QUIZ-001/002)
                 │                               → QuizResult (adaptive block
                 │                                 verbatim: masteryLevel,
                 │                                 trend, nextDifficulty,
                 │                                 recommendedActivity, reasonCode)
                 │                               → Recommendations,
                 │                                 Mastery, Streak, XP/Level
                 │                                 Achievements, Tutor (AI-001)
                 │                                 Progress, Dashboard (DASH-001)
```

**Layer rule:** `UI → Provider/Notifier → Repository → ApiClient → Spring Boot → DTO → MySQL/Gemini`. No repository touches widgets, no controller logic in widgets.

---

## 3. What Adding "Java" Actually Requires (Backend Only)

Assume the product goal is to make **Java** a new world alongside Programming, DBMS, OS, Networks, Data Structures.

### 3.1 Backend content — the only work

1. **Database (no migration needed — existing V1-V13 tables):**
   ```sql
   -- via Flyway migration or seeder (pattern: backend V11-V13)
   INSERT INTO subjects (id, name, description, icon_key, display_order, is_active)
   VALUES ('<uuid-java>', 'Java', 'Master object-oriented Java from syntax to concurrency', 'subject_programming', 6, true);

   INSERT INTO topics (id, subject_id, name, description, difficulty, display_order, is_active)
   VALUES ('<uuid>', '<uuid-java>', 'Classes & Objects', '...', 'EASY', 1, true),
          ('<uuid>', '<uuid-java>', 'Inheritance & Polymorphism', '...', 'MEDIUM', 2, true);

   INSERT INTO lessons (id, topic_id, title, content, summary, difficulty, source_type)
   VALUES (...);

   INSERT INTO quizzes (id, topic_id, title, description, difficulty, time_limit_seconds, question_count)
   VALUES (...);

   INSERT INTO questions (id, quiz_id, question_text, options, difficulty) ...;
   -- plus quiz_questions linking, topics already cover display_order
   ```

2. **No API change.** `GET /api/v1/subjects` automatically returns the new row ordered by `displayOrder`. No new endpoint, no `GET /subjects?category=`.

3. **No frontend-relevant behavior change.** Assessment (ASMT-001) will deliver K=3 per active topic for Java, baseline mastery will be created as `topic_mastery` rows with `current_difficulty=EASY, attempt_count=1, trend=INSUFFICIENT_DATA`, learning path generation (PATH-002) will read that mastery, quiz submissions will update mastery per Adaptive Engine §10, recommendations will be produced, gamification will award XP/streak/achievements — all via existing generic services (`AdaptiveLearningService`, `GamificationService`, `AiTutorService`).

### 3.2 What it does NOT require (this is the test)

| Must NOT create | Why |
|---|---|
| `lib/features/java/` folder | Subjects are generic |
| `JavaScreen` / `JavaCard` / `ProgrammingCard` | One `PressableWorldCard` handles all |
| `JavaRepository` / `JavaProvider` | `ContentRepository` + `IntelligenceRepository` already cover SUBJ-001, TOPIC-001, LESSON-001, PATH-001/002, QUIZ-001/002, DASH-001 via IDs |
| `GoRoute(path: '/java')` | Route is `/path/:subjectId` — ID-driven, not name-driven |
| `if (subject.name == 'Java')` | Subject identity never controls behavior; only IDs/statuses/enums from backend |
| New model field for Java | Models are contract-faithful (`Subject.fromJson` parses `id/name/description/iconKey/isActive/displayOrder` only) |
| New theme token for Java | Tint is `displayOrder % 5 → primary/secondary/success/warning/streak` decorative, not behavioral |

If a code review finds `== "Java"` in behavioral logic, it is a defect to be refactored into generic status/ID logic.

---

## 4. Reuse Checklist (per subject, generic)

| Screen/Flow | Generic? | Evidence |
|---|---|---|
| SubjectsScreen catalog | Yes | `FutureBuilder<List<Subject>>` over `contentRepo.subjects()`; no hardcoded list |
| World card | Yes | Single `PressableWorldCard` with `SubjectGlyph(iconKey)` fallback to generic atom |
| Subject → Path navigation | Yes | `_enter(subject)` → `Routes.path(subject.id)?name=…` |
| Path map | Yes | `pathProvider(subjectId)` family; nodes rendered by `status` (LOCKED/AVAILABLE…), not subject name |
| Topic → Lesson → Quiz | Yes | `Routes.topic(topicId)`, `Routes.lesson(topicId)`, `Routes.quiz(topicId)` — topic-scoped only |
| Dashboard | Yes | `dashboardProvider` DASH-001 ten sections; sections use `subjectId/topicId` keys |
| Tutor | Yes | `askTutor(question, topicId/subjectId)` focus resolution `topicId > subjectId > profile > GENERIC` |

---

## 5. Category Grouping — Presentation-Only Today

**Current SUBJ-001 contract (`GameLearn_AI_API_Contract.md` v1.4.0) does NOT guarantee a `category` field.** `Subject.fromJson` parses `id/name/description/iconKey/isActive/displayOrder` only.

Therefore Phase 2 category grouping is **client-presentational scaffolding**, not backend-authoritative:

- Implementation: single isolated resolver `lib/features/subjects/presentation/subject_grouping.dart` exposes `SubjectGrouping.categoryOf(Subject) → String` via case-insensitive name/description/iconKey heuristic and helpers `deriveChips` / `filter`.
- Usage: `SubjectsScreen` builds chip row `All + derived present categories` via `deriveChips(subjects)` and filters the already-loaded list via `SubjectGrouping.filter(subjects, selected)` — **no `GET /subjects?category=` request is sent**.
- Fallback: When `subjects.category` arrives in a future additive `SUBJ-001` response, only `subject_grouping.dart` changes to read `json['category'] ?? heuristic`; `SubjectsScreen` architecture is untouched.

**Do not confuse this with backend-powered search/discovery.** Those are Phase 7 (`POST /subjects/discover`, `GET /subjects?search=&category=` per blueprint §41 R1/R3, §14) and are explicitly not implemented.

---

## 6. Dashboard Recently Learned / Mastered / New — Honest Backend Mapping

All three are derived **only** from fields that actually exist in DASH-001 (`frontend/lib/core/models/dashboard_models.dart`):

- **Recently Learned:** `mastery.recentTopics` (≤5, ordered `last_assessed_at DESC`, fields `topicId/topicName/masteryScore/masteryLevel/currentDifficulty/trend`) and, as fallback, `recentActivity.quizzes` (≤5, `topicName/score/correctCount/submittedAt`). Shown as small `GameCard` rows linking to `Routes.topicPerformance(topicId)`. When both empty → honest `EmptyMiniCard("No recent learning yet — take a scan…")`. Mastery's bands (40/70/90), weights (1/min(n,5)), trends (±5) are never recomputed client-side.

- **Mastered:** Filtered `mastery.recentTopics.where(masteryLevel == 'MASTERED')`. Locked definition `MASTERED ≥90` is backend-owned per Adaptive Spec §10; Flutter only displays. When none → `EmptyMiniCard("No topics mastered yet…")`. `topicsMastered` count is global, not per-subject; the per-topic list is authoritative.

- **New worlds:** Client-presentational filter of the already-fetched `GET /subjects` catalog where `id NOT IN DASH-001 assessment.assessedSubjects[].subjectId`. Implemented as `FutureBuilder<List<Subject>>` inside `_NewWorldsStrip` (single fetch, cached in `initState`, no per-filter reload). When all worlds assessed → `EmptyMiniCard("All worlds started…")`; when catalog fetch fails → same honest empty. No `completion%` is invented (Dashboard Spec §10.4 ratified UNAVAILABLE).

If DASH-001 ever adds per-subject mastery history, only the source field changes; the section headers and card reuse remain.

---

## 7. Responsive & Deep-Link Guarantees

- **Responsive (Phase 2 scope is NOT full Phase 9):** Catalog keeps `ListView.builder` single column, `SingleChildScrollView` horizontal for chips (36dp tall, `AlwaysScrollableScrollPhysics`), `Flexible/Expanded/Wrap`, `TextOverflow.ellipsis` on `Text`, `maxLines: 1` on subject names. Golden/responsive widget tests at `360 / 768 / 1440` assert: catalog renders, chips render, selected chip state, multiple cards, long names (68+ chars) do not overflow, empty filtered state, no `tester.takeException()` at any width.

- **Deep link:** Route `GoRouter(path: '/path/:subjectId')` with `subjectName: uri.queryParameters['name'] ?? ''` keeps `subjectId` authoritative and `name` presentation-only. Tests assert: valid ID resolves, optional `?name=` does not break, `subjectId` drives `contentRepo.pathsForSubject(subjectId)` (captured via MockClient path segment), direct navigation + browser refresh works when `SessionPhase.authenticated`, unauthenticated redirects to `/login` (auth guard preserved), no `if (name == "Java")` mapping.

---

## 8. How to Verify the Architecture

1. **Add Java via backend seeder only** (see §3.1). No `flutter pub get` with new dependencies, no `frontend/lib/` change.
2. `flutter run --dart-define=API_BASE_URL=http://localhost:8080` → Subjects shows Java as a new world card (tint via `displayOrder % 5`).
3. Tap Java → Path map appears (serpentine trail, nodes). Take scan → Assessment delivers Java topics. Submit → baseline mastery appears. Generate path → nodes appear. Open topic → Lesson loads verbatim. Take challenge → Quiz loads. Submit → adaptive card shows `nextDifficulty/recommendedActivity` verbatim. Dashboard mastery radar includes Java topics. Tutor hint with `topicId` works.
4. **Regression:** `flutter analyze` / `flutter test` (including `test/subjects/catalog_responsive_test.dart` at 360/768/1440 and `test/router/deep_link_test.dart` for `/path/:subjectId?name=`) still pass. No `grep -r '== "Java"'` behavioral hit.

---

## 9. What Phase 2 Intentionally Does NOT Do

- Does not create `GET /subjects?search=&category=` server filtering (R1 future).
- Does not implement `POST /subjects/discover` AI discovery (R3 future, Phase 7).
- Does not call Gemini from Flutter.
- Does not recompute mastery/difficulty/recommendations/XP/streaks.
- Does not derive `completionPercentage`.
- Does not add per-subject screens/providers/repositories.
- Does not introduce `AppBreakpoints`/complete responsive redesign (Phase 9).
- Does not change backend Java, SQL, Flyway, API contract, or database schema.

Backend content configuration drives the universe. Flutter displays it. That is backend authority before frontend logic, and it is why adding Java costs zero frontend lines.
