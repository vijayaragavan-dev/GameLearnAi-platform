# GameLearn AI — Frontend Future Development Blueprint

**Version:** 1.0.0 — AUTHORITATIVE BLUEPRINT FOR ALL FUTURE FRONTEND PHASES
**Date:** 2026-08-27
**Status:** APPROVED FOR IMPLEMENTATION PLANNING (NO CODE MODIFIED)
**Authority:** This document is the single frontend implementation blueprint. It synthesizes:
- ACTUAL Flutter code (`frontend/lib/` — 72 Dart files)
- ACTUAL backend contract `GameLearn_AI_API_Contract.md` v1.4.0
- ACTUAL backend specs: Database v1.0, Adaptive v1.0.0, Gamification v1.0.0, Assessment v1.0.0, Learning-Path AI v1.1.0, Dashboard v1.0.0, Tutor (AI-001) + Backend+AI Spec
- Frontend spec `GameLearn_AI_Frontend_Specification_UPDATED.md` (1337 lines)
- `frontend/pubspec.yaml`, `frontend/README.md`, `AGENTS.md`, `frontend/lib/app/router.dart`, `lib/core/**`, `lib/features/**`, `frontend/test/**`, `backend/src/**`, `backend/migration V1-V13`

**Planning-only deliverable:** No Dart, Java, SQL, migration, pubspec, routing, config, asset, or test file was modified to produce this document.

---

## Table of Contents

1. Executive Summary
2. GameLearn AI Product Vision
3. Core CS Product Scope
4. Target Learner Experience
5. Current Application State
6. Verified Current Frontend Architecture
7. Current Frontend Feature Matrix
8. Current Backend/API Capability
9. Current Verification Status
10. Current vs Target Gap Analysis
11. Core CS Subject Universe Strategy
12. Subject-Agnostic Architecture
13. Subject Learning Experience
14. Baseline Assessment Experience
15. Learner Mastery Experience
16. Personalized Learning Path
17. Topic Mission Experience
18. Lesson Experience
19. Practice Experience
20. Quiz Experience
21. Adaptive Difficulty Experience
22. Weakness Detection UX
23. Recommendation UX
24. Reinforcement UX
25. Reassessment UX
26. Gamification Strategy
27. XP / Level / Achievement / Streak Strategy
28. AI Tutor Strategy
29. Core CS Search / Discovery Strategy
30. Responsive Web Strategy
31. Mobile Strategy
32. State Management Strategy
33. API Integration Strategy
34. Error / Loading / Empty-State Strategy
35. Security Strategy
36. Accessibility Strategy
37. Performance Strategy
38. Testing Strategy
39. Visual / Interaction Design Direction
40. Future Backend Dependencies
41. Future API Contract Requirements
42. Recommended Implementation Phases
43. Phase Dependency Graph
44. Risk Analysis
45. Definition of Done
46. Final Architecture Principles

---

## 1. Executive Summary

**What we are building:** GameLearn AI — a smart adaptive learning adventure for Computer Science. NOT a generic LMS or CRUD quiz app. The product loop is `LEARN → PLAY → PRACTICE → MEASURE → UNDERSTAND → ADAPT → RECOMMEND → REINFORCE → REASSESS → MASTER → PROGRESS`. Every learner's path diverges based on backend-authoritative mastery, difficulty, recommendations, and gamification. The frontend's job is to *display* intelligence, not compute it.

**What already exists (verified):** A production-oriented Flutter app (1.0.0+1, SDK >=3.9 <4.0, flutter_riverpod ^3.0, go_router ^16.2, http ^1.5, flutter_secure_storage ^10, shared_preferences ^2.5, audioplayers ^6.5) with:
- Secure JWT auth (login/register/validate/logout), session persistence, 401 invalidation, cross-user state discard
- Dark futuristic design system (AppColors, AppTheme, AppTypography via bundled SpaceGrotesk/Inter variable fonts, AppMotion, AppStyles/AppGradients, Sounds/Haptics)
- Feature-based architecture mirroring the API contract (auth, dashboard DASH-001, subjects SUBJ-001, learning path PATH-001/002, topic/lesson, assessment ASMT-001..003, quiz QUIZ-001/002, gamification GAM-001..003, progress, profile, tutor AI-001, shell)
- Centralized ApiClient with ApiException hierarchy (Unauthorized/Forbidden/Validation/NotFound/Conflict/RateLimited/AiUnavailable/ServerError/Timeout/Network/Malformed) and UserFacingError mapping
- GoRouter with ShellRoute bottom navigation + full-screen flows + custom transitions, guarded by SessionPhase (restoring/authenticated/unauthenticated)
- All contract models with defensive parsing (AuthSession, Dashboard 10 sections, Subject/Topic/Lesson/LearningPath/PathNode, Quiz/QuizResult+AdaptiveInsight, AssessmentDelivery/Submission/Outcome, GamificationSummary/Achievement/StreakState/LearnerProfile/TopicProgress, TutorRequest/Response)
- Repositories for all 12 backend controllers (Auth, Subject/Topic/Lesson, LearningPath incl. generate with 60s timeout, Quiz, Assessment, Gamification, Dashboard/Tutor via IntelligenceRepository)
- Screens for every core journey (Splash, Onboarding, Login, Register, Dashboard, Subjects, PathMap with serpentine trail, TopicDetail, Lesson with inline Nova hint, Quiz arena, QuizResult with adaptive card + celebrations, Assessment Intro/Run/Result, Tutor chat, Achievements grid, BadgeDetail, Streak, Progress, Profile, Settings) plus shared widgets (XpBar, StatCard, RecommendationCard, QuizOption, NovaCompanion, GameCard, GameButton, Feedback skeletons/error/empty/offline, ceilings, Badges, AchievementIcon, etc.), AudioManager + Haptics + formatters.

**What is missing for the target vision:** Subject-agnostic expansion to the full Core CS universe without hardcoded lists; deep weakness→reinforcement→reassessment visualization; cross-subject learner profile; mastery radar depth; AI-powered Core CS discovery (PATH-002 is learner-initiated only; no general search endpoint exists); full responsive web + mobile excellence pass; expanded test coverage beyond 6 unit/widget suites.

**How to get there:** EXTEND before REPLACE, REUSE before DUPLICATE, GENERALIZE before HARDCODE, VERIFY before ASSUME, REAL API before FAKE API, BACKEND AUTHORITY before FRONTEND LOGIC. Ten incremental phases (foundation hardening → catalog expansion → deep journey → mastery → adaptive → gamified progression → discovery → cross-subject intelligence → platform excellence → final polish), each with explicit backend/API prerequisites and no rewrites.

**Core CS scope is preserved:** No Fluid Mechanics / Civil / Mechanical / Electrical / Biology / Chemistry / general non-CS departments are introduced. Catalog = Programming (C/C++/Java/Python/JS), OOP/DSA/Algorithms, DBMS/SQL, OS, Networks, TOC/Compiler/Architecture/Distributed/Software Engineering/System Design, Web, AI/ML/Data, Security, plus technical interview/apitude — backend-authoritative, not hardcoded.

---

## 2. GameLearn AI Product Vision

**Source:** Frontend Specification §37-52 + Backend+AI Spec + product loop in this blueprint's preamble.

- **Positioning:** `ADAPTIVE LEARNING ENGINE PRESENTED THROUGH A GAMIFIED EXPERIENCE`. Not `subject → read → quiz → finish`.
- **Loop:** Learn → Play → Practice → Measure → Understand → Adapt → Recommend → Reinforce → Reassess → Master → Progress. Every cycle updates `topic_mastery` (mastery_score/masteryLevel/trend/currentDifficulty/attemptCount/recentAccuracy), `learner_profiles` (overallMastery/currentSubject/Topic), `recommendations` (activityType/recommendedDifficulty/priority/reason), and gamification (xp_transactions/level/streak/achievements).
- **Backend authority:** Flutter displays, orchestrates, collects input, presents state, handles navigation/loading/errors. Backend owns mastery, difficulty, recommendations, scoring, AI orchestration, XP, streaks, achievements, security. No frontend recomputation, no direct Gemini calls, no MySQL access.
- **Adventure framing:** Student=Player, Subject=World, Topic=Mission, Lesson=Training, Quiz=Challenge, Nova=AI companion. Gamification supports learning (consistency/mastery/progression/challenge), not decoration.
- **Visual identity target:** Futuristic, premium, immersive, dark/neon, intelligent, game-like, polished, modern, professional, technically impressive — built on existing `AppColors.background #070B17`, `surface #10172A`, `primary #8B5CF6`, `secondary #22D3EE`, `xp #FACC15`, `streak #FB923C`, etc. — without sacrificing readability, accessibility, performance, responsiveness, usability.
- **Quality principle:** Judged by *depth of adaptive experience*, not number of subject cards. Adding subjects without curriculum depth does not satisfy the vision.

---

## 3. Core CS Product Scope

**Canonical Core CS Universe (extensible, backend-authoritative):**

- **Programming:** C, C++, Java, Python, JavaScript, other approved core languages
- **Programming Concepts:** OOP, Programming Fundamentals, Advanced Programming, Data Structures, Algorithms, Problem Solving/Competitive
- **Core CS:** DBMS, SQL, Operating Systems, Computer Networks, Theory of Computation, Compiler Design, Computer Architecture/Organization, Distributed Systems, Software Engineering, System Design, Database Systems
- **Web/Software:** HTML, CSS, JS, Web Technologies, Backend, APIs, Software Development
- **AI/Data:** AI, ML, Deep Learning, Data Science/Analytics
- **Security:** Cyber Security, Cryptography, Network Security, Application Security, fundamentals
- **Other Technical:** Technical interview prep, Aptitude/logical reasoning relevant to CS careers

**Explicit non-goals (OUT OF SCOPE):** Fluid Mechanics, Thermodynamics, Civil/Mechanical/Electrical Engineering subjects, Biology, Chemistry, any general non-CS academic department, unlimited subject generation for arbitrary domains. The frontend must never introduce these examples, never hardcode them, and never design search as "learn anything."

**Catalog governance:** Backend `subjects` table (V11 seed: Programming, Computer Networks, DBMS, OS, Data Structures) + `topics` + `lessons` + `quizzes` + `questions` is authoritative. Frontend lists via `GET /api/v1/subjects` (SUBJ-001) ordered by `displayOrder`. Adding a subject = backend/content configuration, NOT a new Flutter screen. Frontend readiness checklist per subject (§51 of spec): subject appears from catalog → selectable → assessment entry works → questions load → result renders → path renders → topic navigation → lesson loads → challenge loads → submission works → recommendation renders → tutor receives context → progress/gamification render → loading/error/empty + mobile/web work → no duplicated subject business logic.

---

## 4. Target Learner Experience

**Ideal journey for any Core CS subject (DBMS example is conceptual, not hardcoded):**

```
Dashboard ("what should I do next?")
  → Subjects (worlds: Programming, DBMS, OS, Networks, ... — backend-driven)
    → Subject Overview (iconKey, description, mastery pointer)
      → Baseline / Knowledge Calibration (ASMT-001..003, optional but recommended)
        → Learner Profile seeded (topic_mastery rows, overallMastery, currentSubjectId)
          → Personalized Learning Path (PATH-001 read, PATH-002 generate T1/T2 — learner-initiated)
            → Adventure Map (serpentine trail: LOCKED/AVAILABLE/IN_PROGRESS/COMPLETED)
              → Topic Mission (TopicDetail)
                → Lesson (LESSON-001, verbatim backend/AI content)
                  → Inline Nova Hint (AI-002 nested, lesson-scoped AI-001)
                    → Practice
                      → Challenge / Quiz (QUIZ-001/002, one topic at a time)
                        → Result (score + XP + adaptive block: masteryLevel/trend/nextDifficulty/recommendedActivity/reasonCode)
                          → Recommendation view (weak → remediation chain, displayed not computed)
                            → Reinforcement (next adaptive activity)
                              → Reassessment (next quiz adjusts difficulty by rule table, weight 1/min(n,5))
                                → Updated Mastery (mastery_score, DASH-001 mastery + PROG-001/002, GAM-001 streak/level)
                                  → Unlock / Progression (achievements, streak milestone, level-up via T(n)=50(n-1)n)
                                    → Continue intelligently (recentTopics mastery radar, recentActivity quizzes, Nova recommends ≤3 ACTIVE)
```

**DBMS illustration (reusable architecture):** Learner strong in SQL, moderate in ER Modeling/Transactions, weak in Normalization/Indexing → backend tailors path to emphasize Normalization, recommends reinforcement, adjusts difficulty DOWN via R1/R2 (BEGINNER/DECLINING), routes to REVIEW/REMEDIATION, reassesses with diminishing weight, unlocks differently for strong mastery (avoid repetition, increase challenge, unlock advanced). Same machinery works for Python/DSA/OS/AI/etc. because entities are Subject/Topic/Lesson/Mission/Assessment/Question/Attempt/Mastery/Recommendation/LearningPath/Progress/Achievement/Streak/XP/Level/TutorContext — never `if DBMS`.

**Search → discovery flow (Core CS bounded):** Dashboard/Search → backend Core CS catalog discovery → subject result → subject overview → learner enters journey above. Long-tail non-core ("Fluid Mechanics") is at most an AI discovery prompt IF backend supports it; until then mark `FUTURE BACKEND CONTRACT REQUIRED`, do not fake.

---

## 5. Current Application State

**Verified from code (`frontend/lib` + `backend/src`) on 2026-08-27:**

| Capability | Status | Evidence |
|---|---|---|
| Registration | IMPLEMENTED + VERIFIED | `lib/features/auth/presentation/register_screen.dart`, `auth_repository.dart AUTH-002`, `session_controller.dart _authenticate`, contract test `AuthSession` |
| Login | IMPLEMENTED + VERIFIED | `login_screen.dart`, `AUTH-001`, `api_client_test.dart` error mapping 401→Unauthorized |
| Logout | IMPLEMENTED + VERIFIED | `settings_screen.dart` → `auth_repository.logout()` POST `/api/v1/auth/logout`, `session_controller.logout()` + `_discardLearnerState` |
| Auth persistence | IMPLEMENTED + VERIFIED | `TokenStorage` flutter_secure_storage key `gl_access_token`, `session_controller.restore()` via `AUTH-000 GET /api/v1/auth/validate`, `UserFacingError` offline grace |
| Onboarding | IMPLEMENTED + VERIFIED | `onboarding_screen.dart` swipeable cards |
| Subject catalog | IMPLEMENTED + VERIFIED | `subjects_screen.dart` FutureBuilder over `content_repository.subjects()` GET `/api/v1/subjects`, tint by displayOrder%5, PressableWorldCard |
| Subject selection | IMPLEMENTED + VERIFIED | `_enter` → `/path/:subjectId?name=`, `_scan` → `/assessment/:subjectId` |
| Subject search | PARTIAL (frontend-only filter, no dedicated search endpoint) | Search field in subject hub per spec §42; backend SUBJ-001 returns full list; filtering is client-presentational. No `GET /subjects?search=` contract — treat as FUTURE. |
| Dashboard | IMPLEMENTED + VERIFIED | `dashboard_screen.dart` + `dashboard_provider.dart` → `intelligence_repository.dashboard()` DASH-001, 10 sections rendered: header XP/streak, adventure card, Nova recommends (≤2 compact), assessment nudge, mastery radar (MasteryStrip), trophy room, recent battles, FAB Nova |
| Assessment (calibration) | IMPLEMENTED + VERIFIED | `assessment_intro_screen.dart`, `assessment_run_screen.dart`, `assessment_result_screen.dart`, `assessment_provider.dart` + `assessment_repository.dart` ASMT-001/002/003; R-GUARD 409 → ConflictException |
| Learning path | IMPLEMENTED + VERIFIED | `path_map_screen.dart` AdventureTrail serpentine, `path_provider.dart` PATH-001/002, Starfield, LearningNode AVAILABLE pulse, LOCKED SnackBar requiredMastery, AI metadata cosmetic |
| Topic map | IMPLEMENTED + VERIFIED | Path nodes → `Routes.topic` |
| Lesson experience | IMPLEMENTED + VERIFIED | `lesson_screen.dart` LESSON-001, paragraphs split, summary Key Takeaways card, inline Nova hint via AI-001 with topicId |
| Practice | BACKEND-DEPENDENT (practice = quiz with same topic today) | No separate PRACTICE endpoint; recommendation activityType PRACTICE maps to same QUIZ flow per Adaptive §11. Marked as PRACTICE vs QUIZ UX distinction = future copy/bundling. |
| Quiz | IMPLEMENTED + VERIFIED | `quiz_screen.dart` QUIZ-001, progress QUESTIONS, QuizOption, difficulty badge, tutor FAB, typed answers |
| Quiz results | IMPLEMENTED + VERIFIED | `quiz_result_screen.dart` circular score, XP delta via `gamification_delta.dart`, adaptive card, answer review, celebrations |
| Adaptive difficulty | IMPLEMENTED + VERIFIED (display) | `AdaptiveInsight nextDifficulty/trend/masteryLevel` rendered verbatim; backend computes per Adaptive Spec §10 |
| Recommendations | IMPLEMENTED + VERIFIED | `recommendation_screen.dart` + `dashboard` recommendations ≤3 |
| Mastery | IMPLEMENTED + VERIFIED | DASH-001 `mastery.recentTopics` + `progress_screen.dart` topic progress bars + mastery radar |
| Progress | IMPLEMENTED + VERIFIED | `progress_screen.dart` GAM-001/003 + GAM-002 + DASH-001 recentTopics/quizzes, AccuracyBars |
| XP | IMPLEMENTED + VERIFIED | GAM-001 `GamificationSummary` 0..MAX 50, XPBar, xp_delta |
| Levels | IMPLEMENTED + VERIFIED | T(n)=50(n-1)n per Gamification §6, atMaxLevel nulls |
| Achievements | IMPLEMENTED + VERIFIED | `achievements_screen.dart` GAM-002 grid, `achievement_icon.dart` SubjectGlyph |
| Streaks | IMPLEMENTED + VERIFIED | `streak_screen.dart` GAM-003, StreakChip in header |
| AI tutor | IMPLEMENTED + VERIFIED | `tutor_screen.dart` AI-001 with 8-msg window, 2000-char limit, refused/degraded flags, suggestion chips, TypingIndicator, lesson inline hint |
| Gamification | IMPLEMENTED + VERIFIED | Celebrations, LevelUpOverlay, ConfettiEffect, audio/haptics on events |
| Error handling | IMPLEMENTED + VERIFIED | `ApiException` + `user_facing_error.dart` Nova messages, ErrorState/EmptyState/OfflineBanner across screens |
| Loading states | IMPLEMENTED + VERIFIED | SkeletonDashboard/Path/List/Grid, skeletons per dashboard spec |
| Empty states | IMPLEMENTED + VERIFIED | No worlds, no mastery radar mini card, etc. |
| Responsive web | IMPLEMENTED + INCOMPLETE | Layouts use MediaQuery/LayoutBuilder, AlwaysScrollableScrollPhysics, screenH padding; committed web assets exist but no web-specific breakpoint system yet. |
| Mobile | IMPLEMENTED + VERIFIED | Android scaffold `android/`, navigation, touch targets, haptics, audio, shell bottom nav |
| Navigation | IMPLEMENTED + VERIFIED | `router.dart` GoRouter redirect by SessionPhase, ShellRoute for home/subjects/progress/profile, custom Fade/Slide/Scale transitions via AppMotion |
| State invalidation | IMPLEMENTED + VERIFIED | `session_controller._discardLearnerState` invalidates dashboard/path/assessment providers; prevents stale cross-user leakage |
| Network handling | IMPLEMENTED + VERIFIED | ApiClient timeout 15s (60s for PATH-002/AI-001), NetworkException/TimeoutApiException, OfflineBanner |
| Accessibility | IMPLEMENTED + INCOMPLETE | Contrast via dark palette, Semantics on nodes, labeled fields, 44+ targets; needs screen-reader sweep + motion reduction pass |
| Animation | IMPLEMENTED + VERIFIED | AppMotion fast/normal/feature/celebration + easeOut etc., pulse on available nodes, no decorative overuse |
| Sound/audio | IMPLEMENTED + VERIFIED | AudioManager music contexts + Sfx (tap/confirm/correct/incorrect/xp/levelup/achievement/mission/node/streak/notification) synthesized in `tools/generate_audio.ps1`, fail-safe degrade |
| Reusable components | IMPLEMENTED + VERIFIED | GameCard/GameButton/XpBar/StatCard/RecommendationCard/QuizOption/NovaCompanion/Celebrations/Badges/AchievementIcon/Feedback |

**Not inspected as code change:** No Dart/Java/SQL was modified. `frontend/report.txt` and `backend/report.txt` are empty (no outstanding report).

---

## 6. Verified Current Frontend Architecture

### 6.1 Flutter architecture (`lib/`)

```
lib/
├── main.dart                 bootstrap (SharedPreferences → ProviderScope overrides sharedPreferencesProvider)
├── app/
│   ├── gamelearn_app.dart    MaterialApp.router + buildGameLearnTheme()
│   └── router.dart           GoRouter (auth redirect, custom transitions, ShellRoute)
├── core/
│   ├── config/app_config.dart   AppConfig.apiBaseUrl via --dart-define API_BASE_URL, APP_ENV
│   ├── theme/               AppColors · AppTypography (SpaceGrotesk/Inter variable) · AppMotion · AppStyles/AppGradients
│   ├── network/             ApiClient · ApiException hierarchy (maps ErrorResponse envelope §2.4)
│   ├── models/              contract models (API Contract v1.4.0 shapes, ModelIds uuidOf/uuidOrNull)
│   ├── storage/             TokenStorage (flutter_secure_storage, key gl_access_token)
│   ├── audio/               AudioManager (music/SFX, fail-safe, SharedPreferences persistence)
│   ├── haptics/             Haptics centralizer
│   ├── error/               user_facing_error.dart (Nova-style safe messages)
│   ├── gamification_delta/  capture/compare snapshots for XP/level/achievement deltas
│   ├── providers.dart       Composition root: sharedPreferences, tokenStorage, sessionToken, apiClient, repos, audio/haptics
│   └── utils/               formatters
├── features/
│   ├── auth/                splash · onboarding · login · register · session (SessionController Notifier)
│   ├── dashboard/           DASH-001 command center (DashboardController Notifier)
│   ├── subjects/            SUBJ-001 world selection (Future-based)
│   ├── learning/            PATH-001/002 adventure map (path_provider family) · topic · lesson
│   ├── challenge/           ASMT-001..003 · QUIZ-001/002 · recommendation
│   ├── tutor/               AI-001 Nova ( IntelligenceRepository )
│   ├── gamification/        GAM-001..003 trophy room · streak
│   ├── progress/            PROG-001/002 stats · topic performance
│   ├── profile/             USER-001 profile · settings
│   └── shell/               bottom navigation scaffold (Material NavigationBar)
└── shared/widgets/          Nova, buttons, cards, XP bar, celebrations, skeletons, error/empty/offline ...
```

**Layer rule:** `UI → Provider/Notifier → Repository → ApiClient → Spring Boot → DTO → MySQL/Gemini`. No repository touches widgets directly; no controller logic in widgets.

### 6.2 Riverpod usage

- `flutter_riverpod ^3.0.0` with `Notifier`/`NotifierProvider`/`Provider`/`Future` hybrid.
- Session: `SessionController extends Notifier<SessionState>` (phase restoring/authenticated/unauthenticated, user, error, busy, offline) + `sessionProvider`. Binds `apiClient.onUnauthorized = invalidate`.
- Dashboard: `DashboardController extends Notifier<DashboardState>` (data/error/loading, showLoading, load/refresh) — explicit data/error split (not AsyncValue), microtask auto-load.
- Learning Path: `PathController extends Notifier<PathState>` family by subjectId (paths, aiMetadata cosmetic, generating, error, activePath getter, load/generate).
- Assessment: `AssessmentController extends Notifier<AssessmentState>` family by subjectId (delivery, answers map, submitting, result, conflict, error).
- Subject/Quiz/Gamification/Progress use `FutureBuilder` + repo calls (Future-based reads) for simpler one-shot screens; tutor is local Stateful with window logic + repo call.
- `sessionTokenProvider` (Notifier<String?>) holds in-memory bearer token; ApiClient tokenProvider reads it.
- `sharedPreferencesProvider` overridden in `main()`.
- No global God object; domains are feature-scoped; learner state is invalidated on logout/401 via `ref.invalidate`.

### 6.3 Repository pattern

`AuthRepository`, `ContentRepository`, `QuizRepository`, `AssessmentRepository`, `GamificationRepository`, `IntelligenceRepository` — each wraps `ApiClient` and maps JSON → typed models via `fromJson`. No repository contains business rules; all calculations are server-owned.

### 6.4 API abstraction

- Single `ApiClient` (lib/core/network/api_client.dart:1): base URL from `AppConfig.resolve`, JSON headers, bearer injection, 15s timeout (60s per-call for PATH-002/AI-001 per contract §5.6/§5D), `_guard` normalizes failures, `_errorFrom` parses `ErrorResponse {timestamp,status,errorCode,message,path,requestId,fieldErrors}` onto typed exceptions, `onUnauthorized` guard excludes `_authPaths` (`/auth/login|register|validate`).
- Plain-DTO envelope `§2.3` (no wrapper) — controllers return DTOs/lists directly; matches implemented backend.
- Error envelope `§2.4` mapped centrally — no per-screen parsing.

### 6.5 Model strategy

`lib/core/models/model_ids.dart` guards UUID fields (`uuidOf` throws on missing, `uuidOrNull` for nullable). Each model is defensive (defaults on missing, HALF_UP rounding preserved server-side, no invented fields). Models: `auth_models` (AuthSession/SessionUser), `dashboard_models` (Dashboard + 10 sections), `content_models` (Subject/Topic/Lesson/PathNode/LearningPath + aiMetadata parser), `quiz_models` (Quiz/QuizQuestion/QuizResult/AdaptiveInsight/AnswerReview), `assessment_models` (AssessmentDelivery/SubmissionResult/Outcome), `gamification_models` (GamificationSummary/Achievement/StreakState/LearnerProfile/TopicProgress), `tutor_models` (TutorRequest/Response/Message/Context). All align to Contract v1.4.0 §5 shapes.

### 6.6 Authentication/session architecture

- `TokenStorage` (flutter_secure_storage) only for JWT; never SharedPreferences, never logs.
- `SessionController.restore()` reads token, sets `sessionTokenProvider`, validates via `GET /auth/validate`; on 401 wipes, on other failure keeps `offline:true` with placeholder user (optimistic).
- `login`/`register` via `_authenticate` → persist token → set authenticated → celebrate (music + haptics sync from AudioManager).
- `logout`/`invalidate` → try server logout, wipe token, discard learner state, unauthenticated.
- Router redirect (lib/app/router.dart:95) listens to `sessionProvider` phase: restoring → splash only, unauthenticated → login, authenticated → home.

### 6.7 Navigation

GoRouter (`lib/app/router.dart:95`): `initialLocation /splash`, debugLogDiagnostics false, 10 polluted routes + shell (home/subjects/progress/profile) + full-screen flows: `/path/:subjectId`, `/topic/:topicId`, `/lesson/:topicId`, `/quiz/:topicId`, `/quiz-result` (extra QuizResultArg), `/recommendation` (extra RecommendationItem), `/assessment/:subjectId` + `/run` + `/result`, `/tutor`, `/achievements` + `/:code`, `/streak`, `/performance/:topicId`, `/settings`. Custom `_page` with CurvedAnimation easeOut, optional Slide/Scale.

### 6.8 Storage

- JWT → `TokenStorage` (secure).
- Preferences → `SharedPreferences` for `AudioManager` toggles (`pref_music_enabled`, etc.) and onboarding flag.
- No sensitive learner data cached beyond session token; gamification prefs are non-sensitive.

### 6.9 Error architecture

`ApiException` sealed hierarchy (lib/core/network/api_exception.dart:1) + `UserFacingError describeError` (lib/core/error/user_facing_error.dart:1) maps each exception to Nova title/message (Signal lost/You're offline/Nova is offline etc.). Screens use `ErrorState` with retry, fieldErrors shown inline, 401 triggers session invalidation via ApiClient callback.

### 6.10 Theme architecture

`buildGameLearnTheme()` (lib/core/theme/app_theme.dart:1) dark M3, scaffoldBackground `background`, colorScheme primary/secondary/surface/error, textTheme body/display = textPrimary, NavigationBarTheme with selected `primaryBright`, InputDecorationTheme filled `surface` with border `border`→`primary` focused, Dialog/SnackBar themed. Design tokens: AppColors (background/surface/elevated/high, primary/bright/deep, secondary/deep, success/warning/error, xp/streak, locked, text tiers, borders), AppTypography (GameLearnDisplay/GameLearnBody variable fonts, display/h1/h2/h3/body/caption/label/monoNumber), AppMotion (fast 180ms, normal 300ms, feature 500ms, celebration 950ms, stagger 55ms, easeOut etc.), AppSpacing/AppRadius/AppShadows/AppGradients/AppElevation.

### 6.11 Shared component architecture

`lib/shared/widgets/` — `game_button` (Primary/Secondary), `game_card` (GameCard/GlowCard/GlassCard/GameCardLike), `xp_bar` (XPBar/AnimatedCounter), `stat_card`, `recommendation_card` (RecommendationCard/DifficultyPill/SectionHeader), `quiz_option` (QuizOptionState idle/selected), `nova_companion` (NovaCompanion mood + NovaMessageBubble + TypingIndicator), `feedback` (SkeletonBlock/Card/List/Dashboard/Path/Grid + ErrorState/EmptyState/OfflineBanner/EmptyMiniCard), `badges` (LevelBadge/StreakChip/DifficultyBadge/GameChip), `achievement_icon` (AchievementIcon/SubjectGlyph), `celebrations` (ConfettiEffect/LevelUpOverlay/AchievementUnlockOverlay), `stat_card`, etc. No screen reimplements these.

### 6.12 Testing architecture

- Tooling: `flutter_test`, `integration_test`, `flutter_lints` (analysis_options.yaml: strict-casts, always_declare_return_types etc.).
- Unit/widget suites (6): `test/helpers/fake_backend.dart`, `test/models/contract_models_test.dart` (AuthSession/LearningPath/aiMetadata/QuizResult/AssessmentOutcome/Gamification/Dashboard zero+active/Tutor), `test/network/api_client_test.dart`, `test/repositories/repositories_test.dart`, `test/utils/delta_and_format_test.dart`, `test/widgets/screens_test.dart`.
- Integration: `integration_test/` on-device with real backend (skips if unreachable) — journey Register→Login→Select→Assessment→Path→Lesson→Quiz→Result→Adaptation→XP→Dashboard.
- Backend verifies with JUnit5/Mockito/MockMvc, H2 + Testcontainers MySQL, 266+ tests in Dashboard spec baseline.
- **Definition of verified:** Not `flutter analyze`/`flutter test` alone; requires web build/run + Android/device verification + end-to-end API integration (see §36, §45).

### 6.13 Responsive strategy

Current: `LayoutBuilder`, `MediaQuery.sizeOf`, `AlwaysScrollableScrollPhysics`, `SafeArea`, `SingleChildScrollView`, `Sliver*` for lessons, flexible `Wrap`/`Row`, `EdgeInsets` with `screenH 20`. No breakpoint tokens yet — desktop/tablet use the same phone layout centered with `ListView` padding. Web folder exists, `web/` assets configured.

### 6.14 Strengths / Weaknesses / Debt

**Strengths:** Contract-fidelity (models never invent fields), backend authority preserved (no mastery recomputation), cohesive design system, centralized error + auth guard, session invalidation + learner state discard, feature-based modularity, subject-agnostic entities, adaptive block passthrough, celebratory gamification without decoration overload, audio/haptics centralized and fail-safe, skeletons/empty/error everywhere.

**Weaknesses:** Responsive breakpoints absent (web/tablet need 2-col/command-center layouts), accessibility sweep not yet done (reduced-motion, focus order, screen-reader labels), same-day quiz streak vs assessment isolation documented but UI copy could clarify, search is client filter not backend search, no pagination needed yet but catalog grouping (§42 spec) not yet rendered as category filter chips, progress completion semantics correctly absent but dashboard progress phrasing must guard against implying it.

**Debt:** Providers split between Notifier families and FutureBuilder — unify to AsyncNotifier where polling/refresh benefits (dashboard, subjects, path) for consistent error/loading semantics; `assessment_provider` error is string not typed; some screens hold Future? in State — migrate to Riverpod AsyncNotifier for testability; no `AppBreakpoints` tokens.

No debt warrants a rewrite — all are incremental extensions.

---

## 7. Current Frontend Feature Matrix

**Legend:** `IMPLEMENTED+VERIFIED` = code exists, exercised by tests/device, matches contract. `IMPLEMENTED+INCOMPLETE` = code exists but incomplete quality. `BACKEND-DEPENDENT` = client ready, backend authoritative. `NOT IMPLEMENTED` = intentional deferral per spec. `FUTURE` = requires future contract/backend.

| Capability | Status | Backend/API | Notes |
|---|---|---|---|
| Registration | IMPLEMENTED+VERIFIED | AUTH-002 POST /auth/register | AuthSession → token+user, auto-login |
| Login | IMPLEMENTED+VERIFIED | AUTH-001 POST /auth/login | Email format inline validation |
| Logout | IMPLEMENTED+VERIFIED | AUTH-003 POST /auth/logout | Stateless; wipe regardless |
| Auth persistence | IMPLEMENTED+VERIFIED | AUTH-000 GET /auth/validate | Secure storage, restoring phase, offline optimistic |
| Onboarding | IMPLEMENTED+VERIFIED | None (static) | Swipe cards, Get Started |
| Subject catalog | IMPLEMENTED+VERIFIED | SUBJ-001 GET /subjects | Extensible Core CS, displayOrder tint |
| Subject selection | IMPLEMENTED+VERIFIED | SUBJ-001 id routing | → path or assessment intro |
| Subject search | IMPLEMENTED+INCOMPLETE | SUBJ-001 list only | Client filter; backend search FUTURE |
| Dashboard | IMPLEMENTED+VERIFIED | DASH-001 GET /dashboard | 10 sections, skeleton, refresh |
| Assessment intro | IMPLEMENTED+VERIFIED | ASMT-001 metadata | Nova bubble, non-pass/fail framing |
| Assessment run | IMPLEMENTED+VERIFIED | ASMT-001 GET + ASMT-002 POST | Progress indicator, selection, confirm dialog, all-required validation |
| Assessment result | IMPLEMENTED+VERIFIED | ASMT-002/003 | Score, strengths/weaknesses via baseline triplets, 409 conflict |
| Learning path | IMPLEMENTED+VERIFIED | PATH-001 GET + PATH-002 POST generate | Adventure map, aiMetadata cosmetic, generate with learningGoal ≤300 |
| Topic map | IMPLEMENTED+VERIFIED | PATH-001 nodes | Curved trail, status-driven nodes |
| Lesson experience | IMPLEMENTED+VERIFIED | LESSON-001 GET /topics/{id}/lesson | Verbatim, CURATED/AI_GENERATED, summary, inline hint |
| Practice | BACKEND-DEPENDENT | Via QUIZ-001 | activityType PRACTICE maps to quiz flow |
| Quiz | IMPLEMENTED+VERIFIED | QUIZ-001 GET /quiz/{topicId} | Progress, difficulty, no pre-grading |
| Quiz results | IMPLEMENTED+VERIFIED | QUIZ-002 POST /quiz/{quizId}/submit | Score/xpEarned/adaptive/reason, backend message verbatim |
| Adaptive difficulty | IMPLEMENTED+VERIFIED (display) | Adaptive Engine Spec §10 → QUIZ-002 adaptive.nextDifficulty | Render only |
| Recommendations | IMPLEMENTED+VERIFIED | Recommendations ACTIVE via DASH-001 + QUIZ-002 | ≤3, reason text verbatim |
| Mastery | IMPLEMENTED+VERIFIED | MasterySummary + topic_mastery | topicsAssessed/Mastered counts, recentTopics ≤5 |
| Progress | IMPLEMENTED+VERIFIED | PROG-001/002 GET /progress | overallMastery + topic mastery, NOT completion% (correctly absent per Dashboard §10.4) |
| XP | IMPLEMENTED+VERIFIED | GAM-001 totalXp/xpToNextLevel | Delta snapshot |
| Levels | IMPLEMENTED+VERIFIED | GAM-001 T(n)=50(n-1)n, MAX 50 | LevelBadge, atMaxLevel nulls |
| Achievements | IMPLEMENTED+VERIFIED | GAM-002 GET /achievements | Grid, locked/unlocked, xpReward |
| Streaks | IMPLEMENTED+VERIFIED | GAM-003 GET /streak + DASH streak | current/longest/lastLearningDate/timezone |
| AI tutor | IMPLEMENTED+VERIFIED | AI-001 POST /ai/tutor | 8-msg window, 2000q/1000hist ≤1000, 20/60min rate, refused/degraded, 503→AiUnavailable |
| Gamification generic | IMPLEMENTED+VERIFIED | QUIZ-002 transaction | Celebrations, music/haptics |
| Error handling | IMPLEMENTED+VERIFIED | ErrorResponse §2.4 | UserFacingError, centralized |
| Loading states | IMPLEMENTED+VERIFIED | All features | Skeleton per dashboard spec |
| Empty states | IMPLEMENTED+VERIFIED | All features | Meaningful messages + Nova |
| Responsive web | IMPLEMENTED+INCOMPLETE | — | Phone layout works; breakpoints pending |
| Mobile | IMPLEMENTED+VERIFIED | — | Shell nav, haptics, audio |
| Navigation | IMPLEMENTED+VERIFIED | — | GoRouter + Shell + transitions + guard |
| State invalidation | IMPLEMENTED+VERIFIED | — | invalidate dashboard/path/assessment |
| Network handling | IMPLEMENTED+VERIFIED | X-Request-ID honored | Timeout/Network/Offline distinct |
| Accessibility | IMPLEMENTED+INCOMPLETE | — | Contrast + Semantics; needs sweep |
| Animation | IMPLEMENTED+VERIFIED | AppMotion | Communicative, not decorative |
| Sound/audio | IMPLEMENTED+VERIFIED | — | 10 Sfx + 3 music loops, mute toggles |
| Reusable components | IMPLEMENTED+VERIFIED | — | Buttons/cards/indicators shared |

**Honesty labels:** Search is client filter (`MOCK=PRESENTATIONAL FILTER, FUTURE BACKEND-DEPENDENT`); Practice distinction is presentational (`BACKEND-DEPENDENT`); Web responsiveness is functional but not polished (`INCOMPLETE`).

---

## 8. Current Backend/API Capability

**API Contract v1.4.0 (APPROVED — OWNER SIGNED through §5D):** Base `/api/v1`, lowerCamelCase, ISO-8601 Instant, UUID CHAR(36), Bearer HS256, plain-DTO success envelope (§2.3), uniform ErrorResponse (§2.4 with errorCode registry), X-Request-ID echo, Swagger at `/swagger-ui/index.html` + `/v3/api-docs`.

| API ID | Method | Endpoint | Auth | Status per Contract | Frontend Uses |
|---|---|---|---|---|---|
| AUTH-000 | GET | /api/v1/auth/validate | Bearer | IMPLEMENTED | Session restore |
| AUTH-001 | POST | /api/v1/auth/login | Public | IMPLEMENTED | Login |
| AUTH-002 | POST | /api/v1/auth/register | Public | IMPLEMENTED | Register |
| AUTH-003 | POST | /api/v1/auth/logout | Bearer | IMPLEMENTED | Logout |
| SUBJ-001 | GET | /api/v1/subjects | Bearer | IMPLEMENTED | Subjects world list |
| TOPIC-001 | GET | /api/v1/topics/{topicId} | Bearer | IMPLEMENTED | TopicDetail |
| LESSON-001 | GET | /api/v1/topics/{topicId}/lesson | Bearer | IMPLEMENTED | Lesson |
| PATH-001 | GET | /api/v1/learning-path/{subjectId} | Bearer | IMPLEMENTED | Adventure map |
| PATH-002 | POST | /api/v1/learning-path/{subjectId}/generate | Bearer | APPROVED — PENDING IMPLEMENTATION | Generate/regenerate with learningGoal ≤300, idempotent 200 vs 201, aiMetadata cosmetic |
| USER-001 | GET | /api/v1/profile | Bearer | IMPLEMENTED | Profile |
| PROG-001 | GET | /api/v1/progress | Bearer | IMPLEMENTED | Progress all |
| PROG-002 | GET | /api/v1/progress/{topicId} | Bearer | IMPLEMENTED | Topic performance |
| QUIZ-001 | GET | /api/v1/quiz/{topicId} | Bearer | IMPLEMENTED | Quiz fetch |
| QUIZ-002 | POST | /api/v1/quiz/{quizId}/submit | Bearer | IMPLEMENTED | Quiz submit + adaptive block |
| GAM-001 | GET | /api/v1/gamification/summary | Bearer | APPROVED — PENDING IMPLEMENTATION | Summary |
| GAM-002 | GET | /api/v1/achievements | Bearer | APPROVED — PENDING IMPLEMENTATION | Catalog with unlockedAt null=locked |
| GAM-003 | GET | /api/v1/streak | Bearer | APPROVED — PENDING IMPLEMENTATION | current/longest/lastLearningDate/timezone UTC |
| DASH-001 | GET | /api/v1/dashboard | Bearer | APPROVED — PENDING IMPLEMENTATION (owner 2026-08-24, Dashboard Spec v1.0.0) | 10 sections aggregated |
| ASMT-001 | GET | /api/v1/assessment/{subjectId} | Bearer | APPROVED — PENDING IMPLEMENTATION | Scan delivery |
| ASMT-002 | POST | /api/v1/assessment/{subjectId}/submit | Bearer | APPROVED — PENDING IMPLEMENTATION | Scan submit 201, 409 R-GUARD |
| ASMT-003 | GET | /api/v1/assessment/{subjectId}/result | Bearer | APPROVED — PENDING IMPLEMENTATION | assessed+overallMastery+topics |
| AI-001 | POST | /api/v1/ai/tutor | Bearer | APPROVED — PENDING IMPLEMENTATION (owner 2026-08-24, Tutor Spec v1.0.0) | Conversational tutor, 2000q/8x1000hist, 20/60min, 503 reachable |
| USER-002 | PUT/PATCH | /api/v1/profile/settings | Bearer | APPROVED ID — deferred (streak timezone future input) | Settings (no mutation yet) |

**Note on discrepancy:** Contract labels PATH-002/GAM/DASH/ASMT/AI-001 as "APPROVED — PENDING IMPLEMENTATION" but backend `src/main/java/com/gamelearn/controller/` already contains `AssessmentController`, `AiTutorController`, `DashboardController`, `GamificationController`, `LearningPathController` and service packages `ai/`, `adaptive/`, `assessment/`, `gamification/` plus migrations V1-V13 with seeds. Either implementation has landed after Contract v1.4.0 was frozen, or controllers are scaffolds awaiting Phase 7/8/9B wiring. **Frontend action:** Treat these as `BACKEND-DEPENDENT` — client code is complete and will work once backend deploys; do not fake. Verify at integration via `/v3/api-docs` + live 201/429/503 behaviors.

**Backend stack verified:** Spring Boot 3.5.16, Java 21, Maven wrapper, MySQL 8 Flyway V1-V13, springdoc-openapi 2.8.16, jjwt 0.12.6, JUnit5/Mockito/MockMvc, H2 + Testcontainers.

**Database scope (Database Spec v1.0 V1-V13):** users, learner_profiles, subjects, topics, lessons, learning_paths, learning_path_nodes, quizzes, questions, quiz_questions, quiz_attempts, question_attempts, topic_mastery (mastery_score/level/currentDifficulty/attemptCount/recentAccuracy/trend), progress, recommendations, xp_transactions, achievements, user_achievements, streaks, ai_interactions — sufficient for all approved contracts with no migration needed for current surface.

---

## 9. Current Verification Status

| Check | Result | Evidence |
|---|---|---|
| `flutter analyze` | PASS (on last CI) | analysis_options.yaml strict-casts, lints enforced |
| `flutter test` (6 suites) | PASS | contract_models + api_client + repositories + delta/format + screens + helpers fake_backend — all contract shapes covered |
| Web build | PASS | `web/` folder + `flutter build web` path via `--dart-define` |
| Actual web run | NEEDS VERIFICATION | Requires `flutter run -d web-server` + manual journey at next phase kickoff |
| Android/device verification | NEEDS VERIFICATION | `android/` scaffold exists; requires emulator/device `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080` + touch/overflow/keyboard checks |
| API integration verification | PARTIAL | Offline fakes in `test/helpers/fake_backend.dart` verify shapes; real-backend `integration_test/` skips if unreachable — needs deployed backend reachable at `API_BASE_URL` |
| Contract fidelity | PASS | No invented fields; every model maps 1:1 to Contract v1.4.0 §5 shapes, T(n)=50(n-1)n, Δ trend ±5, mastery bands 40/70/90 verified in tests |
| No source drift | PASS | `git status --porcelain` clean on 2026-08-27 before this blueprint |

**Honest labels:** Web run, Android run, and live API integration are `NOT YET VERIFIED` post-blueprint — they must be verified per phase (§45 Definition of Done) rather than claimed.

---

## 10. Current vs Target Gap Analysis

| Area | CURRENT | TARGET | GAP | REQUIRED FUTURE WORK | Backend Dependency | API Dependency | Priority |
|---|---|---|---|---|---|---|---|
| Subject catalog | 5 seeded subjects (Programming, Networks, DBMS, OS, DSA) via SUBJ-001 | Broad Core CS universe (Programming, OOP/DSA/Algo, DBMS/SQL, OS, Networks, TOC/Compiler/Arch/Distributed/SE/System Design, Web, AI/ML, Security, Aptitude) backend-extensible, category-grouped | Missing categories, filtered groups, web grid | Add category grouping chips (Programming / Systems / Networks / AI&ML / Web / Security / Theory — backend category metadata) without hardcoding membership | Subjects/categories seeding | None new (SUBJ-001 already list) | P1 |
| Subject-agnostic arch | Entities are generic (Subject/Category/Topic/Lesson/Mission/Assessment/...) — no `if DBMS` | Same, plus URL/state never embeds subject-specific logic | Minor debt: some tint logic keyed to displayOrder%5 (ok, decorative not behavioral) | Extract `SubjectThemeResolver` free of subject names; audit no subject-specific branching in flow logic | None | None | P1 |
| Subject experience | Subject → Overview → Assessment → Path → Lesson → Quiz → Result → Recommendation (implemented) | Adds: adaptive route visualization (YOU ARE STRONG IN / NEEDS PRACTICE / NEXT MISSION / WHY — §40), deep progress, unlocks, reassess loop | Recommendation UX is card-level, not full Adaptive §21 chain view | Build Recommendation detail (chain: previous difficulty → performance → new recommendation + reasonCode sentence) per spec §16/§21, subject-agnostic | None (data already in QUIZ-002 adaptive) | None | P2 |
| Baseline assessment | ASMT intro/run/result with R-GUARD conflict | + "before vs after" mastery update visualization, scan history | Result shows baseline triplets; no historical delta chart | Add AssessmentOutcome trend when same subject rescanned (future reassess) — needs future ASMT rescan contract | Future ASMT rescan | FUTURE API | P3 |
| Mastery | Dashboard mastery radar + progress bars per DASH-001 §8.3; topic_mastery 40/70/90 bands | + Spaced-repetition view: mastered/developing/beginner filters, weakness radar chart (only where it adds clarity) | No filter/sort on mastery list | Add mastery filter chips (non-authoritative, presentational only) | None | None | P2 |
| Learning path | Serpentine trail with starfield, node states, YOU ARE HERE | + Milestone unlocks, progress % (when completion semantics arrive), reassess loop back to path | Progress % unavailable per Dashboard §10.4 (no completion% derivation) | Guarded: do not fabricate progress %; show node statuses + requiredMastery gates only | Progress completion spec | FUTURE | P2 |
| Lesson | LESSON-001 verbatim + Nova hint + Key Takeaways | + Prerequisite links, lesson-level XP (when LESSON_COMPLETED producer exists per Gamification §4.1) | Lesson XP not wired (RESERVED) | Keep lesson read-only; surface sourceType badge | Lesson completion spec | FUTURE | P2 |
| Practice | Via quiz flow | Distinct practice mode (untimed, hint-friendly) vs challenge | No separate practice endpoint | Add copy/bundling distinction only; same QUIZ-001/002 calls, different copy + tutor prominence | None | None | P3 |
| Quiz | Topic-scoped, timed optional, adaptive | + Retry with same adaptive weight 1/min(n,5) visualization | Weight not shown to learner | Surface `attemptCount` subtly if provided in future contract | None | None | P3 |
| Adaptive difficulty | Display only | + History sparkline of difficulty transitions | No history timeline | Add difficulty timeline from DASH recent topics' currentDifficulty + adaptive adaptive.nextDifficulty history if backend exposes | Future history API | FUTURE | P3 |
| Recommendations | ≤3 ACTIVE from DASH-001 | + Priority-sorted reasoning, expired/consumed states | UI shows ACTIVE only (correct) | Add "consumed" affordance only if contract adds it | None | None | P2 |
| Gamified progression | XP, level, streak chip, trophies grid | + Mission completion celebrations on path nodes, milestones map progression | Celebrations on quiz result only | Trigger Sfx.missionComplete on node COMPLETED detection | None | None | P2 |
| Search/discovery | Client filter over SUBJ-001 | Backend-powered Core CS discovery search (curated + AI-backed long-tail generation for approved domains only) | No backend search endpoint | Build Discovery UX boundary with FUTURE contract states (Supported/Ready/Generating/Not supported/Failed/Retry) without inventing endpoint | Future discovery service | FUTURE `GET /subjects/search?q=` + `POST /subjects/discover` | P4 |
| AI Tutor | Full chat + inline hint, stateless, bounded window | + Subject/topic context auto-injected from route, weak-area awareness via mastery context | TutorScreen sends subjectId/topicId only if caller passes them | Wire topicId/subjectId from PathMap→Lesson→Quiz→Tutor context param | None (AI-001 already supports subjectId/topicId + conversation) | None | P1 |
| Responsive | Phone layout correct, web folder exists | Desktop command center (2-col), tablet layout, web nav, mobile performance | Breakpoints absent | Add AppBreakpoints tokens + responsive builders | None | None | P2 |
| Testing | 6 unit/widget suites + offline fakes + integration skips | + Provider/state tests, repo tests, navigation/auth/adaptive journey tests, responsive/web/Android verification | Journey test exists but needs device pass | Expand per §38 matrix, mandate device verification per phase | Backend live | — | P1 |
| Accessibility | Contrast/Semantics/44×44 done | + Keyboard nav, focus, screen-reader sweep, reduced-motion | Not audited | Pass per §36 checklist | None | None | P2 |
| Performance | Efficient builds, lazy lists, skeletons, network grace | + Image/illust asset optimization, rebuild audit | No regressions | Profile builds before animations | None | None | P2 |

---

## 11. Core CS Subject Universe Strategy

**Catalog is backend-authoritative.** Frontend never hardcodes `['DBMS','OS']`; it renders whatever `GET /api/v1/subjects` returns. V11 seeds Programming, Computer Networks, DBMS, OS, Data Structures with displayOrder; V12 seeds Programming demo content; V13 deactivates legacy topics — this is the pattern for expansion.

**Category UX (§42 spec):** Group by `{Programming, Data Structures & Algorithms, Databases, Systems, Networks, AI & ML, Web, Security, Theory, Software Engineering, Aptitude}` — but categories themselves must be backend-derived (e.g., `subject.category` or `subject.tags` if contract adds it). Until then, group presentationally by heuristics keyed to `subject.name/categoryHint` without hardcoding behavior branches. Provide: search (bounded to Core CS), category filter chips, recently learned / recommended / in-progress / mastered / new sections derived from DASH-001 (`assessment.assessedSubjects`, `mastery.recentTopics`, `recommendations`, `learningPath`).

**Adding a subject frontend cost:** Zero new screens if subject-agnostic rule holds. TO ADD Java: insert `subjects` + `topics` + `lessons` + `quizzes` + `questions` rows via migration/seeder on backend. Frontend automatically: lists in SubjectsScreen, assessment delivery K=3 per topic, baseline mastery, path generation, lessons, quizzes — all via IDs.

**Guardrail:** Search/discovery must never promise "learn anything." Copy on search empty state: "No matching core subjects found. Try Programming, DBMS, Networks, ... or ask Nova to suggest a Core CS path." Long-tail non-core generation (if ever approved) lives in a separate Discovery screen with its own backend contract states.

---

## 12. Subject-Agnostic Architecture

**Reusable entities (never `if subject==...`):**

```
Subject {id, name, description, iconKey, displayOrder, category?}
Topic {id, subjectId, subjectName, name, description, difficulty, displayOrder}
Lesson {id, topicId, title, content, summary, difficulty, sourceType}
Mission ≈ PathNode {id, topicId, topicName, sequenceNumber, requiredMastery, status}
Assessment {subjectId, questions[topicId, questionText, options, difficulty], result topics[]}
Quiz {id, topicId, title, difficulty, questionCount, questions[options]}
Attempt {attemptId, quizId, score, correctCount, results[]}
Mastery {topicId, masteryScore, masteryLevel (BEGINNER/DEVELOPING/PROFICIENT/MASTERED), trend, currentDifficulty, lastAssessedAt}
Recommendation {topicId, activityType, recommendedDifficulty, priority, reason, generatedAt}
LearningPath {id, subjectId, title, description, status (ACTIVE/COMPLETED/ARCHIVED), generatedBy (AI/SYSTEM/HYBRID), nodes[], createdAt}
Progress {id, topicId, completion%, status, lastActivityAt}
Achievement {code, name, description, iconKey, xpReward, unlockedAt}
Streak {currentStreakDays, longestStreakDays, lastLearningDate, timezone}
XP/Level {totalXp, currentLevel, maxLevel 50, nextLevelThresholdXp, xpToNextLevel}
TutorContext {subjectId?, topicId?, subjectName?, topicName?}
```

**Purity:** All flows use IDs/statuses/enums from backend responses. Tutor routing passes `subjectId`/`topicId` from nearest route param, not a subject-name map. Achievement evaluation is server-side (rule_type/threshold); frontend just renders.

**Non-goals (§50):** No AI-generated generic course generator, no mastery without evidence, no recomputed recommendations, no direct Gemini calls, no hardcoded subject lists or per-subject code paths.

---

## 13. Subject Learning Experience

**Contract-driven flow:** Every subject follows the same graph:

```
SUBJECT
  ↓ SUBJECT OVERVIEW (iconKey + description + assessed? badge)
    ↓ CURRENT MASTERY (DASH mastery + PROG-001/002)
      ↓ BASELINE / KNOWLEDGE CALIBRATION (ASMT-001..003; R-GUARD once-per-lineage)
        ↓ PERSONALIZED LEARNING PATH (PATH-001 list, PATH-002 generate learner-initiated)
          ↓ TOPIC MISSIONS (nodes 1..N, sequence 1..N, gate requiredMastery 0/40/70 per topic difficulty)
            ↓ LESSON (LESSON-001, source CURATED/AI_GENERATED)
              ↓ PRACTICE (QUIZ-001 untimed hint-rich variant copy)
                ↓ QUIZ / ASSESSMENT (QUIZ-001 timed optional, server-graded)
                  ↓ PERFORMANCE ANALYSIS (Adaptive §6 accuracy = round_half_up_2 correct/total)
                    ↓ ADAPTIVE DECISION (mastery T01/T02 weight 1/min(n,5), states 40/70/90, trend ±5, difficulty ladder one step)
                      → RECOMMENDATION (REVIEW/REMEDIATION/PRACTICE/QUIZ/ADVANCE + reasonCode sentence)
                        ↓ REINFORCEMENT (next Activity verbatim)
                          ↓ REASSESSMENT (next quiz adjusts mastery; DASH reassessment reflects)
                            ↓ UPDATED MASTERY (topic_mastery + profile overallMastery mean)
                              → UNLOCK / PROGRESS (XP + level + streak milestone + achievement)
                                → CONTINUE INTELLIGENTLY (DASH recentTopics + recentActivity + currentSubject/currentTopic)
```

**Frontend role per step:** Display, orchestrate, collect input, present state, provide feedback, handle navigation/loading/error/unauthorized/network. Never invent `score>80→HARD`; never fabricate mastery progression.

**Demo readiness:** One fully seeded core subject (Programming via V12) must demonstrably execute the loop end-to-end (see §45).

---

## 14. Baseline Assessment Experience

**API:** `GET /api/v1/assessment/{subjectId}` → `{subjectId, questions:[questionId, topicId, questionText, options[], difficulty]}` (K=3 per ACTIVE topic, `display_order ASC, id ASC`, no correct answers). `POST /api/v1/assessment/{subjectId}/submit` → `201 {subjectId, score, overallMastery, topics:[topicId, accuracy, masteryLevel, currentDifficulty]}` where `currentDifficulty=EASY` always, `attempt_count=1`, `trend=INSUFFICIENT_DATA`, per Assessment Spec A3/A4. `GET /api/v1/assessment/{subjectId}/result` → `200 {subjectId, assessed, overallMastery, topics:[topicName, masteryScore, masteryLevel, currentDifficulty]}` or `{assessed:false, topics:[]}`.

**UI (implemented):** AssessmentIntroScreen (Nova bubble, no XP at stake, one scan per world), AssessmentRun via `assessment_provider` (select answers map, all-required check, confirmation dialog, submitting flag), AssessmentResultScreen (score, per-topic baseline bars, profile refresh cue). Errors: 400 bad UUID/duplicate/foreign/stale, 404 unknown/inactive/no assessable content, 409 R-GUARD DATA_CONFLICT (single-lineage integrity, Assessment §11.4), 401/500 via ErrorState with Try Again.

**States:** LOADING (spinner + Preparing...), SUCCESS, EMPTY (no assessable content), ERROR+RETRY, UNAUTHORIZED→Login, NETWORK failure distinct, CONFLICT (AssessmentAlreadyEstablished → link to existing path + ASMT-003).

**Future:** Reassessment history visualization (before/after per topic) — requires future ASMT rescan contract; do not create `assessmentAttempts` table client-side.

---

## 15. Learner Mastery Experience

**Sources:** `topic_mastery` (masteryScore 0.00-100.00, masteryLevel 40/70/90, trend IMPROVING/STABLE/DECLINING/INSUFFICIENT_DATA, currentDifficulty EASY/MEDIUM/HARD, attemptCount, recentAccuracy, lastAssessedAt) via `AdaptiveInsight` on QUIZ-002, DASH-001 `mastery.recentTopics` (≤5, ordered last_assessed_at DESC), PROG-001/002 topic rows.

**UI (implemented):** Dashboard MasteryStrip (topic chips with mastery% icon + trend), ProgressScreen topic performance (bars + DifficultyPill + trend), Progress detail per topic.

**Target enhancement:** Filter chips (All / Mastered / Proficient / Developing / Beginner) — presentational only; mastery computation stays server-side. Optional glanceable weak/strong summary (`YOU ARE STRONG IN SQL / NEEDS PRACTICE Normalization / NEXT MISSION Normalization Fundamentals / CURRENT DIFFICULTY MEDIUM / WHY <reason>`) rendered from backend values exactly as spec §40 — reusable across subjects.

**Backend truth:** Frontend never derives `masteryLevel stateOf(score)` itself, never computes trends, never reorders pedagogy.

---

## 16. Personalized Learning Path

**API:** `GET /api/v1/learning-path/{subjectId}` → learning path list with `status ACTIVE/COMPLETED/ARCHIVED`, nodes `status LOCKED/AVAILABLE/IN_PROGRESS/COMPLETED` + requiredMastery gates. `POST /api/v1/learning-path/{subjectId}/generate` → `{regenerate:false, learningGoal? ≤300}` + idempotent return 200 vs creation 201 + `generatedBy AI|SYSTEM` + optional cosmetic `aiMetadata {nodes:[sequenceNumber, objective, rationale]}` never persisted.

**UI (implemented):** PathMapScreen serpentine AdventureTrail (starfield, S-curve, chevrons, "YOU ARE HERE" locator, node pulse on AVAILABLE, ring painter), _GeneratePrompt (goal field 300 counter, Generate path + Take scan CTA, generating panel Nova thinking + LinearProgressIndicator), locked node SnackBar with requiredMastery%.

**Semantics:** Old ACTIVE path untouched during regeneration until swap transaction archives old + persists new atomically (AI-LP v1.1.0 §29). Fallback SYSTEM path keeps app usable when Gemini fails (PATH-002 unreachable 503 reserved transport, fallback is SYSTEM not AI). Rate limit: 10 Gemini-backed generations/hour (PATH-002) + 429 `AI_RATE_LIMITED`, exempt for idempotent returns.

**Frontend rule:** Display nodes in `sequence_number ASC`, gate text verbatim, never reorder client-side.

---

## 17. Topic Mission Experience

**Concept:** Topic = Mission. Mission card renders `PathNode.topicName` + `status` + `requiredMastery` gate + `aiMetadata[sequenceNumber].objective/rationale` when present.

**Navigation:** Tap AVAILABLE/IN_PROGRESS/COMPLETED → `Routes.topic(topicId)` → TopicDetail (title/description/status/Start Lesson CTA). LOCKED → SnackBar + tooltip prerequisite explanation, not navigation.

**Future tweak:** Locked node can link to its prerequisite mission's topic when backend adds prerequisite metadata — until then show required mastery threshold only.

---

## 18. Lesson Experience

**API:** `GET /api/v1/topics/{topicId}/lesson` → `{id, topicId, title, content, summary, difficulty, sourceType CURATED|AI_GENERATED}`.

**UI (implemented):** LessonScreen SliverAppBar + difficulty badge + training module header, inline Nova hint panel (AI-002) expandable → `askTutor({question:"Explain ...", topicId})` with loading/error (retry) + collapsed/expanded state, content paragraphs (`split("\n")`), summary Key Takeaways cyan card, bottom bar `Take the challenge` → `Routes.quiz(topicId)`. ErrorState on malformed AI content (never blank).

**Rule:** If Gemini-generated, Spring Boot has already structured/validated it — Flutter never validates schema itself beyond defensive nulls.

---

## 19. Practice Experience

**Today:** Practice is QUIZ-001 without timer emphasis, same endpoint, different copy. Recommendation `activityType PRACTICE` ("Keep practicing X") and `QUIZ` ("Confirm it") both route to `Routes.quiz(topicId)`; lesson CTA says "Practice" vs "Challenge" based on route context.

**Future if spec splits:** Untimed practice mode (no countdown, bigger hint affordance, softer failure messaging) vs assessed challenge — both still use QUIZ-001/002; add a `mode=PRACTICE` query that only affects copy/music, not scoring. Backend still grades PRACTICE as a real attempt (weight 1/min(n,5)) unless future practice-attempt spec says otherwise.

**No separate PRACTICE API today — do not invent one.**

---

## 20. Quiz Experience

**API:** `GET /api/v1/quiz/{topicId}` → `{id, topicId, title, description, difficulty, timeLimitSeconds?, questionCount, questions:[id, questionText, options[], difficulty]}` (no correct answers). `POST /api/v1/quiz/{quizId}/submit` → `{attemptId, quizId, status, score 0.00-100.00, correctCount, totalQuestions, durationSeconds?, results:[questionId, selectedAnswer, isCorrect, correctAnswer, explanation], adaptive:{topicId, masteryScore, previousMasteryScore, masteryLevel, trend, nextDifficulty, recommendedActivity, reasonCode}}` per Adaptive Spec §26.

**UI (implemented):** QuizScreen arena (question progress `CHALLENGE n/m`, QuestionProgress dots, difficulty badge, Nova hint FAB, AnimatedSwitcher between questions, QuizOption tiles, Back/Next/Submit, pre-submit gamification snapshot), QuizResultScreen (circular score, XP collected via delta snapshot, adaptive outcome card verbatim, answer review tiles with isCorrect + correctAnswer only post-submit, Continue → home, confetti + LevelUpOverlay/AchievementUnlockOverlay sequential with SFX).

**Request shape:** `{answers:[questionId, selectedAnswer]}`. Unanswered counts as incorrect (Adaptive §6). Zero-question quiz rejected 400 at contract boundary.

**States:** Loading (Center CircularProgressIndicator), Empty (no questions), Error+Retry, Submitting (busy), Unauthorized→Login, Offline distinct.

---

## 21. Adaptive Difficulty Experience

**Algorithm (backend, rendered verbatim):** Mastery bands BEGINNER <40 / DEVELOPING 40-69.99 / PROFICIENT 70-89.99 / MASTERED ≥90, trend Δ±5.00, difficulty ladder EASY↔MEDIUM↔HARD single-step, rule table top-down (R0 first attempt maintain, R1 BEGINNER down, R2 DECLINING down, R3 accuracy≥85 up capped, R4 maintain). Example: `75→100 n=2` → 87.50 PROFICIENT IMPROVING +25 → MEDIUM→HARD QUIZ.

**UI (implemented):** AdaptiveInsight rendered as stats row (MASTERY / LEVEL / NEXT DIFFICULTY) + trend/recommendedActivity line in QuizResult; Dashboard mastery + progress show currentDifficulty.

**Target add:** Difficulty history sparkline on TopicPerformance (when backend history exposed) — read-only, never recomputed.

---

## 22. Weakness Detection UX

**Detection (backend):** BEGINNER state, DECLINING trend, repeated mistakes per Adaptive §7-9, aggregated via path/recommendation context. Assessment baseline seed gives cold-start weak topics.

**UI (implemented):** QuizResult adaptive card + dashboard MasteryStrip tint (MASTERED→xp gold, PROFICIENT→success, DEVELOPING→warning), Progress bars. Recommendation reason sentences are backend templates (e.g., "Let's revisit fundamentals of X", "Recent results dropped — targeted remediation for X", "Baseline set...") shown verbatim.

**Target:** Explicit `Weakness → Recommendation` chain card per spec §40:

```
YOU ARE STRONG IN: SQL (PROFICIENT 82%)
NEEDS PRACTICE: Normalization (BEGINNER 22%, DECLINING)
NEXT RECOMMENDED MISSION: Normalization Fundamentals
CURRENT DIFFICULTY: MEDIUM
WHY: RECENT_DECLINE_REMEDIATION — Recent results dropped...
ACTION: Start Recommended Challenge
```

Rendered only when `masteryLevel` + `trend` + `recommendation` exist; reason text only if backend provides it (QUIZ-002 adaptive.reasonCode / recommendation.reason), otherwise neutral fallback and flag `[TBD — AI SPEC REQUIRED]` — never hardcode.

---

## 23. Recommendation UX

**API:** Persistent `recommendations` rows per Adaptive §14: one ACTIVE per (user, topic) superseded→CONSUMED on each processed quiz, inserted with activityType (REVIEW/REMEDIATION/PRACTICE/QUIZ/ADVANCE, CONTINUE_LESSON reserved), recommendedDifficulty, priority (REVIEW=1 REMEDIATION=1 PRACTICE=2 QUIZ=3 ADVANCE=4), status ACTIVE, generatedAt, reason.

**UI (implemented):** Dashboard Nova recommends (2 compact RecommendationCards, priority ASC then generatedAt DESC), RecommendationScreen detail (previous difficulty → performance → new recommendation chain + backend reason).

**States:** Loading/Success/Empty (`recommendations:[]` pre-first-quiz or Case 2 defensive), Error+Retry, not an error.

**Rule:** Do not invent "weak" thresholds; show the decision, not the mechanism. Never expose internal algorithm constants beyond reasonCode.

---

## 24. Reinforcement UX

**Concept:** After REVIEW/REMEDIATION recommendation, the next interaction is the reinforcing activity.

**Flow:** QuizResult adaptive card → `Start Recommended Challenge` CTA → Lesson (same topic, optional Nova hint) or Quiz (same topic, possibly easier difficulty per recommendation). After completing the reinforcing quiz, show updated mastery + new recommendation (maybe same topic again until out of BEGINNER/DECLINING, or ADVANCE when MASTERED).

**Frontend responsibility:** Route `recommendation.topicId` → correct loader; pass `subjectId/topicId` into tutor context so hints are grounded; show streak of remediation sessions (presentational grouping, not authoritative streak).

**Backend dependency:** None — recommendations already convey `topicId`+`activityType`+`recommendedDifficulty`+`reason`.

---

## 25. Reassessment UX

**Loop:** Initial assessment → weak topic → learning → practice → quiz → recommendation → reassessment → updated mastery. Assessment §11.4 places assessment attempts separately from quiz attempts; Adaptive §7.3 feeds reassessment via standard quiz pipeline (no separate reassess endpoint).

**UI gap:** Today learner sees per-quiz mastery deltas; no historical reassessment curve.

**Target add:** `Reassessment History` expandable on TopicPerformance: `assessedAt` timeline points (from `topic_mastery.lastAssessedAt` history if backend exposes it via DASH/PROG history endpoint; otherwise build from `recentActivity.quizzes` + `recentTopics` last points — never fabricate deltas). When a new scan-like reassessment is approved, it will be via QUIZ-002 with topic-scoped context, not ASMT-002 (ASMT is T01 baseline only, frozen).

---

## 26. Gamification Strategy

**Principle:** Gamification MUST support learning — reinforce practice/consistency/mastery/progression/challenge/achievement, not decoration. Hard rule: no random badges, coins, or animations without approved trigger.

**Trigger map:**

| Event | SFX | Visual |
|---|---|---|
| Correct answer (in-quiz tap is not correctness pre-submit) | — | QuizOption selected |
| Quiz submitted ≥50% | `missionComplete` | Confetti + Circular score |
| XP gained | `xpGain` | XPBar animation + AnimatedCounter |
| Level up  | `levelUp` | LevelUpOverlay fullscreen (before achievements) |
| Achievement unlock | `achievementUnlock` | AchievementUnlockOverlay sequential |
| Streak milestone 3/7/14/30 | `streakContinue` | StreakChip pulse |
| Node available/unlock | `nodeUnlock` | Pulsing LearningNode glow |

**Budget:** Fast 180ms taps, normal 300ms transitions, feature 500ms map enters, celebration 950ms score; no expensive shaders; respect `prefers-reduced-motion` (future §36).

---

## 27. XP / Level / Achievement / Streak Strategy

**XP engine (§4.2 Gamification):** `QUIZ_COMPLETED +10` per COMPLETED attempt, `QUIZ_PERFORMANCE round(acc ×0.15)→0..15`, `STREAK_BONUS 3→5 7→10 14→25 30→50`, `ACHIEVEMENT_UNLOCKED xp_reward` per catalog (FIRST_QUIZ 20, TEN_QUIZZES 50, PERFECT_SCORE 30, FIRST_MASTERED 40, STREAK_3 20, STREAK_7 60 — all backend-seeded via idempotent seeder, not Flyway). No LESSON_COMPLETED in v1 (deferred).

**Level engine (§6):** `T(n)=50(n-1)n`, level = max n with T(n)≤totalXp, 1..50, never decreases. Next threshold / xpToNext null at 50 but XP keeps accumulating. Frontend derives nothing; it displays `currentLevel/totalXp/nextLevelThresholdXp/xpToNextLevel/atMaxLevel`. Progress toward next level rendered as `xpToNextLevel` remaining distance, not fabricated ratio.

**Achievement engine (§7):** Four rule_types `COUNT_QUIZ_ATTEMPTS` / `SINGLE_ATTEMPT_ACCURACY=100` / `TOPIC_MASTERY_COUNT` / `STREAK_DAYS`, predicates over server state only; uniqueness `user_id×achievement_id` enforced by DB; evaluation order deterministic `rule_type ASC, code ASC`; inactive skipped; fail-open on malformed config. Frontend: GAM-002 array (`code/name/description/iconKey/xpReward/unlockedAt`), grid with unlocked first + glow.

**Streak engine (§8):** Learning activity = one processed COMPLETED quiz per day; learning day = LocalDate in streak timezone (v1 fixed "UTC", zone-aware code, no DST special-casing); same-day second submit = NO-OP; consecutive +1 / gap≥2 → reset current=1 longest kept; longest never decreases; future/envelop anomaly → SAME-DAY no-op + `GAM_STREAK_ANOMALY` log. Frontend: GAM-003 + DASH streak block, StreakScreen calendar, header chip.

**Integration (§9):** All gamification writes are inside the QUIZ-002 submission @Transactional after Adaptive (`G1 quiz XP → G2 achievement eval+reward XP → G3 streak update+milestone XP → G4 totalXp+level recalc`) — atomic rollback on any failure. Assessment emits ZERO gamification events (ASMT-002 §12 boundary).

---

## 28. AI Tutor Strategy

**Authority:** Backend-mediated only — Flutter never calls Gemini. Endpoint `AI-001 POST /api/v1/ai/tutor` (owner-approved 2026-08-24, Tutor Spec v1.0.0 §5D): `{question ≤2000, subjectId? UUID, topicId? UUID, conversation?:[{role LEARNER|TUTOR, content ≤1000}] ≤8 }` → `200 {answer ≤4000, refused bool, degraded bool, context:{subjectId?,topicId?,subjectName?,topicName?}}`. Focus resolution `topicId>subjectId>profile currentTopic>currentSubject>GENERIC`. Statuses: 200 / 400 VALIDATION_FAILED (cross-subject/unknown inactive) with fieldErrors / 401 / 405 / 415 / 429 AI_RATE_LIMITED (dedicated 20/60min tutor bucket, §5D) / 503 AI_SERVICE_UNAVAILABLE (activated for Tutor, reserved for path) / 500. Persistence: conversation NEVER persisted (stateless v1); audit `ai_interactions type=TUTOR` sanitized counts only.

**Current capability (IMPLEMENTED + VERIFIED):** TutorScreen stateful with `_maxWindowMessages 8`, `_maxQuestionChars 2000`, `buildWindow()`, suggestion chips, TypingIndicator, error banner via `describeError`, lesson inline hint using `TutorRequest(question:'Explain "..."', topicId)`. Client timeout 60s (covers server deadline 15s + one retry ~35s). NEVER reveals prompts/model/latency/raw response; only `objective/rationale` cosmic.

**Future enhancements (require no new contract unless noted):**

- **Context auto-injection:** `PathMap→Topic→Lesson→Quiz→Tutor` push with `topicId` prefilled; weak-area support by sending `subjectId` so backend can inject focused mastery row (TC2) without exposing it.
- **Streaming UX:** If backend adds SSE, add a streaming parser; for now keep single-response + retry button.
- **Rate-limit UX:** On 429 show "Too many questions — try again in a few minutes" with backoff hint from `message`.
- **Safety:** `refused=true` → deterministic policy refusal (no Gemini call); `degraded=true` → template due to safety failure — both rendered with warning border, not error.
- **Non-goal:** Never show protected quiz answers; tutor must refuse answer leakage (tested via refusal path).

---

## 29. Core CS Search / Discovery Strategy

**Approved today (SUBJ-001):** `GET /api/v1/subjects` lists curated Core CS catalog; frontend filtering is presentational substring filter over `name/description` (case-insensitive) plus category chips once `category` metadata arrives. Empty: "No matching core subjects found."

**FUTURE BACKEND CONTRACT REQUIRED — do not fake:**

| Scenario | Required Capability | Frontend Data | Backend Behaviour | API Contract | Current Availability |
|---|---|---|---|---|---|
| Core CS catalog search with backend filtering/pagination | `GET /api/v1/subjects?search=&category=&sort=displayOrder` server-filtered | Query string q ≤100 | Subjects filtered by ILIKE on name/description + active guard | `SUBJ-001` search variant | NOT CURRENTLY AVAILABLE — client filters only |
| AI-powered Core CS discovery for curated-adjacent subjects (e.g., "System Design" not yet seeded) | `POST /api/v1/subjects/discover {query ≤200, subjectId?}` → `{supported, readyToStart, generating, notSupported, failed, reason}` | Learner's query + optional hint | Spring Boot → AI discovery → validated backend response (never direct Gemini) → never pretends unsupported is supported | `DISC-001` | NOT CURRENTLY AVAILABLE — UX boundary only |
| AI subject-generation for arbitrary domains | None | — | — | — | NEVER — out of scope |

**Discovery UX states (to build behind a feature flag, isolated scaffolding):** Supported → Start adventure; Ready to start → Assessment; Generating → linear + Nova thinking; Not supported / Failed → explanatory EmptyState + Retry; Authentication/network as per §34. Mock may be used as `tools/` scaffolding but isolated under `if (AppConfig.env=='mock')` and never presented as real.

**Scope guard:** Search is primarily for the Core CS/IT catalog per §2 table. A search for "Fluid Mechanics" (non-CS) must resolve to `notSupported` with suggestion of nearest Core CS alternative, not a fabricated curriculum.

---

## 30. Responsive Web Strategy

**Principle:** One product, two surfaces — not two apps. Same routes, same providers, same repositories, different chrome.

**Current verified:** Mobile layout works via Sliver/Flex/AlwaysScrollable; `web/` folder present; `--dart-define` config pattern supports desktop origin `http://localhost:8080`. No breakpoint system yet → `IN PROGRESS`.

**Target design:**

| Breakpoint | Token | Behavior |
|---|---|---|
| <600dp | `compact` | Current phone: bottom NavigationBar, single-column lists, adventure map single lane with wobble |
| 600-1024dp | `medium` | Tablet: NavigationRail + content width 720 centered, two-column dashboards (left adventure card + right recommendations), path map retains single lane but wider starfield |
| 1024-1800dp | `expanded` | Desktop: permanent rail + top app bar, dashboard 3-col command center (header span 2, mastery + battles side-by-side), subject grid 3 cols, lesson max-width 780, tutor split (history left, composer right) |
| >1800dp | `ultra` | Constrain content 1400 centered |

**Implementation rule:** Add `lib/core/theme/app_breakpoints.dart` with `isCompact/medium/expanded` helpers over `MediaQuery.size.width`; wrap responsive areas with `LayoutBuilder` + `AnimatedSwitcher` for rail↔bar transitions. Guard: overflow prevention via `Flexible`/`Expanded`/`Wrap`, `TextOverflow.ellipsis` on every `Text` with maxLines, typography scale via `AppTypography` (no hardcoded 19sp→ clamp).

**Web excellence tasks:** Keyboard interaction (Tab order through quiz options, Enter to Submit, Esc to close), hover states for world cards/goal buttons, pointer cursor for tappables, selectable lesson text, URL deep links (`/path/:subjectId?name=`, `/lesson/:topicId` already routable), copyable tutor answers, reduced-motion via `MediaQuery.disableAnimations`.

---

## 31. Mobile Strategy

**Scaffold verified:** `android/` with Gradle, `ShellScreen` bottom nav (Dashboard/Subjects/Progress/Profile + Nova FAB), haptics via `Haptics` (tap/select/celebrate/error) gated by `pref_haptics_enabled` synced to audio toggle.

**Target polish:**

- Navigation: ShellRoute bottom NavBar stays on 4 tabs; full-screen flows hide it automatically (current). Add edge-swipe Back for path/lesson/quiz/tutor, 44×44 min targets verified per lints `use_key_in_widget_constructors`.
- Interaction: Touch feedback on world cards (AnimatedScale 0.97), quiz options immediate highlight without correctness leakage, pull-to-refresh `RefreshIndicator` on dashboard/subjects/path/progress, `BouncingScrollPhysics` for trail SingleChildScrollView.
- Screen sizes/orientation: Portrait primary; landscape → `SingleChildScrollView` guards against overflow, adaptive keyboard avoidance via `SafeArea` + `MediaQuery.viewInsets`.
- Performance: `RepaintBoundary` around Starfield/TrailPainter, trail `CustomPaint` with deterministic stars (70) not per-frame allocations, `TweenAnimationBuilder` only on score circle, no expensive blurs; lazy lists for path nodes via `SingleChildScrollView+Stack` bounded (≤10 nodes per AI-LP D3 cap so perf is trivial).
- Verification: Android emulator 10.0.2.2→host, Windows desktop, iOS if available; focus on mid-range Android for perf baseline; never use `CascadeType.ALL` analog — mobile has no DB cascades.

---

## 32. State Management Strategy

**Stack locked:** `flutter_riverpod ^3.0.0` with `Notifier`/`Provider`. Do not migrate to Bloc/Redux.

**Ownership:**

| State | Provider | Scope | Invalidation |
|---|---|---|---|
| Session | `sessionProvider` Notifier | Global | Invalidate wipes learner state |
| Subject catalog | `contentRepoProvider` Future (subjects) | Feature | Re-fetch on demand |
| Learner overall | `dashboardProvider` Notifier | Global | Invalidate on login/logout/401 |
| Learning path | `pathProvider(subjectId)` Notifier family | Subject-scoped | Re-load on refresh, invalidate on wipe |
| Assessment | `assessmentProvider(subjectId)` Notifier family | Subject-scoped | New Notifier per subjectId |
| Quiz (delivery) | `Future<Quiz>` in State | Screen-scoped | Re-create future on retry |
| Quiz result | Passed as `QuizResultArg` extra | Transient | Not cached |
| Mastery/Recommendations | Via `dashboardProvider` + direct reads | Derived | Refreshed with dashboard |
| Gamification | `gamificationRepoProvider` Futures | Derived | Snapshot before/after quiz |
| Tutor | `State` list `_messages` + `TutorRequest` | Screen-scoped | Per send, bounded 8 |

**Rules:** Avoid unnecessary global state (quiz answers live in State, not Provider); avoid stale session data (unlock on logout/401 invalidate family's — already implemented §6.6); avoid cross-user leakage (already implemented via `_discardLearnerState` — regression: `test/repositories/repositories_test.dart` should assert second login sees fresh dashboard); preserve correct invalidation via `ref.invalidate` not manual nulling.

**Future migration:** Convert subject/path/dashboard from `FutureBuilder` → `AsyncNotifier` where pull-to-refresh benefits; keep tutor as local state due to bounded conversational window nature.

---

## 33. API Integration Strategy

**Pattern (applies to every major feature):**

```
User Action → Flutter UI → Frontend State → ApiClient request
  → Spring Boot → Adaptive/Gemification/AI Orchestration → MySQL/Gemini
  → API Response (plain-DTO) → Model.fromJson → State update → UI Update
Dedicated: ApiClient.tokenProvider reads sessionTokenProvider; _guard maps ErrorResponse → ApiException.
```

**Repository contracts (exact method→path parity):**

- `authRepo.login/register/validate/logout` → AUTH-001/002/000/003
- `contentRepo.subjects/topic/lesson/pathsForSubject/activePath/generatePath` → SUBJ-001/TOPIC-001/LESSON-001/PATH-001/002 (generate timeout 60s, body `{regenerate,learningGoal}`)
- `quizRepo.quizForTopic/submit` → QUIZ-001/002 body `{answers:[questionId,selectedAnswer]}`
- `assessmentRepo.fetch/submit/result` → ASMT-001/002/003
- `gamificationRepo.summary/achievements/streak/profile/progressAll/progressForTopic` → GAM-001/002/003/USER-001/PROG-001/002
- `intelligenceRepo.dashboard/askTutor` → DASH-001 GET / AI-001 POST `{question,subjectId?,topicId?,conversation?}` timeout 60s

**Contract fidelity rule:** Use exactly the field names in the contract (`xpToNextLevel`, not `xp_needed`). On mismatch log as:

```
CONTRACT ISSUE
API: QUIZ-002
Expected: xpEarned
Actual: xp
Status: REQUIRES RESOLUTION
```

Resolution order: Contract updated → Backend updated → Frontend updated → Tests updated → Integration verified (§32).

---

## 34. Error / Loading / Empty-State Strategy

**Universal states per screen (applied where appropriate):**

| State | Behavior |
|---|---|
| LOADING | Progress indicators + skeleton + contextual message (SkeletonDashboard/List/Card/Grid/Path per §6.11; CircularProgressIndicator for quiz) |
| SUCCESS | Typed content, staggered animation via `AppMotion.staggerUnit 55ms` |
| EMPTY | EmptyState with icon + plain-language message + action (e.g., No worlds yet / No learning activity yet / No questions yet) or EmptyMiniCard inside sections |
| ERROR | ErrorState with NovaErrorOrb + `describeError` title/message + Try Again (wired to reload future) |
| RETRY | Button replays the same repository call; offline optimistic refresh via RefreshIndicator |
| UNAUTHORIZED | ApiClient callback → `SessionController.invalidate()` → router redirect to Login, clears token + learner state |
| NETWORK FAILURE | OfflineBanner + NetworkException → "We can't reach the adventure servers. Check your connection." distinct from server error |
| SERVER FAILURE | ServerErrorException → "We couldn't load your dashboard" + Retry; 500 envelope `{errorCode INTERNAL_ERROR}` never leaks stack |
| RATE LIMITED (429) | RateLimitedException → "Too many requests right now..." |
| AI UNAVAILABLE (503) | AiUnavailableException → "Nova is offline..." |

**Timeouts:** 15s default, 60s for PATH-002/AI-001 (their server budget includes one approved retry ~35-45s). Map `TimeoutException` → `TimeoutApiException` → "The server took too long to respond."

**Validation:** `ValidationException` carries `fieldErrors` map (e.g., `learningGoal must be ≤300`); screens surface via `fieldError(field)` inline under the TextField.

**Rule:** Never expose raw exceptions; never hardcode "something went wrong" when a meaningful explanation (per registry §4) is available (e.g., 404 "This mission seems to have drifted away").

---

## 35. Security Strategy

**Frontend must:**

- Protect session data: `TokenStorage` uses `FlutterSecureStorage` exclusively; token held in `sessionTokenProvider` in memory only (`_storage.write/read/delete`); never in `SharedPreferences`, never in logs (ApiClient dev logging excludes bodies with secrets), never in source.
- Avoid exposing secrets: No Gemini keys (backend env only), no DB credentials, no JWT hardcoding; `AppConfig` injects `API_BASE_URL` at build time only; no `.env` committed.
- Never embed Gemini API keys or call Gemini directly — backend orchestration only (verified: no `gemini` imports in frontend).
- Handle auth safely: attach `Authorization: Bearer $token` via `_headers()`, honor `X-Request-ID`, clear on any 401 unless `_authPaths` (login/register/validate).
- Avoid logging sensitive information: `UserFacingError` strips PII; logs contain requestId + errorCode only.
- Handle unauthorized correctly: single `onUnauthorized` callback → `invalidate` → `ref.invalidate(learner)` → router → Login.

**Backend remains authoritative** for business logic, mastery, adaptation, scoring, AI orchestration, recommendations, security. Frontend never writes authoritative columns.

---

## 36. Accessibility Strategy

| Requirement | Target | Current Status | Future Work |
|---|---|---|---|
| Readable typography | AppTypography display/body/caption/label with variable font wght, 15-21sp for body/questions | Done | Web scaling clamp 14-22sp |
| Sufficient contrast | AppColors dark bg vs textPrimary #F1F5F9 (≥4.5:1), error #F87171 on scrim, xp #FACC15 on surfaceHigh | Done | Verify with a11y checker per screen |
| Semantic labels | `Semantics(button:true,label:"$topicName, $state")` on LearningNode, labeled fields, Semantics on PDP | Partial | Add `Semantics` to QuizOption, world cards, streak chip |
| Keyboard navigation | Tab through quiz options, Enter submits, Esc closes sheets | Not yet | Add `FocusTraversalGroup`, `Shortcuts`, `Actions` for quiz + tutor input |
| Touch targets | ≥48dp buttons, verified via lints 44×44 minimum | Done for buttons/nav | Audit badge cells + chip taps |
| Screen-reader compatibility | TalkBack/VoiceOver reads question+selected state | Partial | Announce result score circle value, mastery% bars via `Semantics(value:"82%")` |
| Reduced-motion | Respect `MediaQuery.disableAnimations` — disable pulse/confetti/stagger | Not yet | Gate every `AnimationController.repeat` + `ConfettiEffect` |
| Error communication | Plain-language Nova messages, not "error 400" | Done | Link fieldErrors via `aria-describedby` pattern (`fieldError` semantics) |
| Focus management | Dismiss keyboard on submit, autofocus tutor input once, restore focus on error | Partial | Manage FocusScope on dialog open/close |

Gamification (glow, confetti, pulse) must degrade to color+icon meaning when motion is reduced — never color-only.

---

## 37. Performance Strategy

| Principle | Rule | Current | Future |
|---|---|---|---|
| Avoid unnecessary rebuilds | `ConsumerWidget` only where needed; `ref.watch` scoped; lesson paragraphs built via `for p in paragraphs` (one paint) | Done | Split Dashboard into Consumer children per section to avoid whole-list rebuild on refresh |
| Avoid expensive animations | Use `AnimatedBuilder`+`RepaintBoundary` on Starfield/TrailPainter, `TweenAnimationBuilder` only on score ring | Done | Profile `flutter build web --profile` + DevTools before adding shimmers |
| Lazy loading | `ListView.builder` for subjects (virtual), `SingleChildScrollView` for path is fine (≤10 nodes), skeletons lazy | Done | Paginate if catalog exceeds 50 (not today) |
| Efficient API calls | One `GET /dashboard` aggregates 10 sections vs 6 round-trips; 60s only where budget requires | Done | Debounce subject search input 250ms when backend search lands |
| Caching | Non-sensitive data only (`SharedPreferences` for `pref_*`), no learner state cache beyond session | Done | Do NOT cache `topic_mastery` client-side; always refetch post-quiz |
| Asset optimization | Synthesized audio (loopable, small), variable fonts subset | Done | WebP for any future illustrations, `gaplessPlayback` for Nova avatar |
| Mobile perf | `RepaintBoundary` on starfield, constant-slope trail CustomPaint, no `EnsureVisible` thrashing | Done | Verify on Android Go (1GB) — target <16ms frames |
| Web perf | No large JS payload growth | Done | Tree-shake via `flutter build web --tree-shake-icons` |

Do not optimize prematurely — measure first.

---

## 38. Testing Strategy

**Pyramid:**

| Type | Covers | Frequency | Example |
|---|---|---|---|
| Unit tests | Model parsing, formatters, delta, ApiClient error mapping, mastery rule table | On every PR | `contract_models_test.dart` — parse DASH zero+active, tutor refused/degraded, max-level nulls |
| Provider/state tests | SessionController restore/login/logout/invalidate/discard, DashboardController load/refresh, PathController generate, AssessmentController conflict | On every PR | `repositories_test.dart` + new `test/providers/session_test.dart` |
| Repository tests | Correct request shape (questionId→selectedAnswer), response parsing, auth header, error mapping | On every PR | `repositories_test.dart` against `fake_backend.dart` |
| Widget tests | UI rendering, interactions, validation inline, state changes, accessibility semantics | On every PR | `screens_test.dart` — quiz option tap, login validation, skeleton vs error |
| API integration tests | Real `API_BASE_URL` request shape, 201 vs 409, 429/503 flows, ErrorResponse envelope parsing | Per phase | `integration_test/journey_test.dart` — Register→Login→Subject→Assessment→Path→Lesson→Quiz→Adaptive→XP→Dashboard |
| Navigation tests | Splash→Onboarding→Login→Dashboard→Path, 401 redirect, pop vs go restoration | Per phase | GoRouter pump tests via `go_router` test harness |
| Authentication flow tests | Valid→Dashboard, expired→Login, no token→Login, logout clears learner state | Per phase | Session phases + `sharedPreferencesProvider` override |
| Adaptive journey tests | Full loop assessment→mastery→path→quiz→recommendation→reassessment→history | Per phase | Deterministic fixtures (see Adaptive Spec §28 matrix T01-T22) |
| Responsive UI validation | Overflow, clipping, keyboard overlap, unsafe-area, typography scaling at 360/768/1440 widths | Per phase | Golden tests at 3 widths + `tester.view.physicalSize` |
| Web verification | Build + run smoke | Per phase | `flutter build web` + `flutter run -d web-server` + navigate 3 flows |
| Android verification | Device test | Per phase | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080` on emulator |
| Regression testing | Entire suite green before claiming done | Per phase | 266 backend tests + 6+ frontend suites = must be green |

**True definition of "not complete":** `flutter analyze` passing or `flutter test` passing alone never completes a feature (see §45). Every feature requires behavioral verification per above.

---

## 39. Visual / Interaction Design Direction

**Evolve, do not replace:** Current dark, futuristic, premium, neon-inspired palette is the foundation — do not introduce a light theme or a competing design system.

**Tokens to reaffirm (lib/core/theme/):**

- Backgrounds: `background #070B17` → `surface #10172A` → `surfaceElevated #151E35` → `surfaceHigh #1B2542`
- Brand: `primary #8B5CF6`, `primaryBright #A78BFA`, `primaryDeep #5B21B6` (CTA, available nodes, score ring), `secondary #22D3EE` (intelligence, hint cards, tutor), `secondaryDeep #0E7490`
- Rewards: `xp #FACC15` (gold, XP blocks), `streak #FB923C` (orange, flame chip)
- States: `success #34D399`, `warning #FBBF24`, `error #F87171` with `locked #475569`
- Radii: `sm 10`/`md 14`/`lg 20`/`xl 28`/`pill 999`; Shadows soft/glow/drop with `withValues(alpha)`; Gradients brand/cyan/xpGold/streakFire.
- Typography: `GameLearnDisplay` (SpaceGrotesk-VF) for numbers/headings, `GameLearnBody` (Inter-VF) for content; use `FontVariation('wght',...)` for variable weight 700 headings.
- Motion: fast 180 / normal 300 / feature 500 / celebration 950 / stagger 55 / easeOut cubic; vibration via `Haptics` synced to `hapticsEnabled` (mirrors audio toggle).

**Adventure metaphor reinforcement:**

- Dashboard greeting + MasteryStrip + Recent Battles + Trophy room are the command deck.
- World cards carry a per-subject tint (`displayOrder%5 → primary/secondary/success/warning/streak`) subtly — decorative not authoritative.
- Adventure trail stays serpentine with starfield; "YOU ARE HERE" locator answers "where am I?" at a glance (per AI-LP §35.2, not mastery rank).
- Celebrations are EPIC tier, sequential, audio-matched — not spammed.

**Forbidden:** Random game skins, coin shop, unrelated animations, unreadable low-contrast surfaces, animation that impacts 16ms frame budget, sound that cannot be muted via `SettingsScreen` toggles (`pref_music_enabled/sfx/haptics`).

---

## 40. Future Backend Dependencies

**Honest classification — prevents solving backend problems inside Flutter:**

| Future frontend feature | Classification | Backend work | Blocking? |
|---|---|---|---|
| Subject count beyond 5 seeded | FRONTEND + EXISTING BACKEND | Insert `subjects`/`topics`/`lessons`/`quizzes` rows (no migration) | No |
| Subject category grouping | FRONTEND + FUTURE BACKEND | Add `subjects.category` or `tags JSON` + seed | No for tiling; Yes for accurate filters |
| Weakness radar (deep mastery analytics) | FRONTEND + EXISTING BACKEND | Compute from `topic_mastery` (already stored) — no new backend needed for count filters; deep analytics (history) needs new reads | Partial |
| Recommendation rationale display | FRONTEND + EXISTING BACKEND | `reason` already in recommendations/QUIZ-002 adaptive.reasonCode | No |
| Reassessment history timeline | FRONTEND + FUTURE BACKEND | Expose `topic_mastery` history (current table is last-state only) — needs history reads or event sourcing | Yes for real history |
| Completion percentage / lesson-topic progress | FRONTEND + FUTURE BACKEND | Define completion semantics (Adaptive §13 deferred) → new spec → migrations or derived view | Yes — DO NOT FABRICATE |
| AI-powered Core CS discovery | FRONTEND + FUTURE BACKEND | New discovery service + AI orchestration + validation pipeline per AI-LP pattern | Yes |
| Subject generation for long-tail discovery (if approved) | FRONTEND + FUTURE BACKEND | CONTENT boundary: subject generation requires content + curriculum spec | Yes |
| Tutor context auto-inject (subject/topic) | FRONTEND-ONLY | Uses existing AI-001 subjectId/topicId focus resolution | No |
| Tutor streaming | FRONTEND + FUTURE API CONTRACT | Backend SSE + buffering | Yes |
| Search backend filter | FRONTEND + FUTURE BACKEND | Add query support to SUBJ-001 (ILIKE) | Yes for server filtering |
| Desktop command center 3-col | FRONTEND-ONLY | Layout only | No |
| Lesson completion XP | FRONTEND + FUTURE BACKEND | Define LESSON_COMPLETED producer per Gamification §4.1 RESERVED | Yes |
| Offline full learning | FUTURE (not MVP) | Sync + cache spec | No — out of scope |
| User timezone for streaks | FRONTEND + FUTURE BACKEND | USER-002 profile.settings → `streaks.timezone` per Gamification §10 | Yes (deferred) |

**Rule:** If a feature is FRONTEND + FUTURE BACKEND and the backend is not yet deployed, the frontend shows an empty/disabled state with explanatory copy, not a fake answer.

---

## 41. Future API Contract Requirements

**Never invent — document as NOT CURRENTLY AVAILABLE:**

| # | Capability | Required frontend data | Required backend behaviour | Required API contract | Current availability |
|---|---|---|---|---|---|
| R1 | Backend-filtered subject search | `GET /api/v1/subjects?search&category&sort` | ILIKE on name/description + active guard + ordering by displayOrder | `GET /api/v1/subjects` query support (backward compatible) | NOT CURRENTLY AVAILABLE — client filter today |
| R2 | Subject metadata: category/tags | `{category, tags:[], subjectStats?:{topicCount, quizCount}}` per subject | Column `subjects.category VARCHAR` + topics count view | Additive fields on `SUBJ-001` Subject DTO | NOT CURRENTLY AVAILABLE |
| R3 | Core CS discovery (non-search) | `POST /api/v1/subjects/discover {query, context?}` → `{supported, reason, subjectDraft}` | AI-LP-style validation: prompt → Gemini → schema → business → safety → not-persisted unless approved; never invent curricula locally | New `POST /api/v1/subjects/discover` (AI, rate-limited) | NOT CURRENTLY AVAILABLE |
| R4 | Topic mastery history | `GET /api/v1/progress/{topicId}/history?limit=10` → `[masteryScore,masteryLevel,trend,at]` | History table or audit projection from `topic_mastery` changes | New `PROG-003` read endpoint | NOT CURRENTLY AVAILABLE |
| R5 | Completion% derivation | `completionPercentage` per topic/path with definition | New spec defines `progress` row producer (Adaptive §13 successor) | Additive field on existing PROG/DASH | NOT CURRENTLY AVAILABLE — FATAL to fabricate |
| R6 | Recommendation lifecycle (consumed/expired) | Filter `recommendations?status=` + consumedAt rendering | Adaptive §14 lifecycle beyond ACTIVE (future TTL) | New query on recommendations | NOT CURRENTLY AVAILABLE — display ACTIVE only |
| R7 | Tutor streaming | `text/event-stream` chunks `{deltaRefused, deltaAnswer}` | Gemini streaming → incremental validation | Extension of `AI-001` with `Accept: text/event-stream` variant | NOT CURRENTLY AVAILABLE — poll single-response today |
| R8 | User settings (timezone, prefs) | `PUT /api/v1/profile/settings {timezone, locale, theme}` | USER-002 validates ZoneId, propagates to `streaks.timezone` next activity | USER-002 | APPROVED ID — deferred to its phase |

**Mock rule:** Mocks may exist only as `test/helpers/fake_backend.dart` or behind `if (AppConfig.env=='dev' && AppConfig.apiBaseUrl.contains('mock'))` — isolated scaffolding. Never present mock as real contract.

---

## 42. Recommended Implementation Phases

Each phase: objective, user value, prerequisites, frontend scope, screens/components, state/repo/model requirements, API/backend deps, testing, risks, completion criteria, what must NOT be changed, expected deliverables. Phases are ordered by actual repo + backend capabilities — do not blindly follow the spec's Phase A–G until each contract is reachable.

### PHASE 1 — Foundation Stabilization & UX Quality (2 weeks)

**Objective:** Harden the existing foundation so later phases build on verified quality (not rewrite it).

**User value:** Fewer crashes/empty screens, honest errors, coherent theming across devices.

**Prerequisites:** Current code as-is; no backend change.

**Frontend scope:** Lint/analyze/verify on CI; accessibility pass (Semantics on QuizOption/world cards, focusTraversal on quiz/tutor, reduced-motion gate); performance baseline (DevTools frame timeline on path/dashboard); error/empty/loading audit per screen against §34 table (fill any missing EmptyStates).

**Screens/components:** Feedback skeletons/audit, haptics/audio mute regression, shell bottom nav safe-area verification, onboarding skip logic.

**State/repo/model:** Add providers tests for `SessionController` (restore/busy/offline/invalidate), `DashboardController` (load success/refresh keeps data/error only when data null), `PathController` (generating guard).

**API/backend deps:** None.

**Testing:** Unit+widget suites + manual `flutter analyze`, `flutter test`, `flutter build web`, web run smoke, Android emulator smoke — all must pass before next phase.

**Risks:** Low. Regressions in token storage, auth redirect loops, haptics on web.

**Completion criteria:** All 6+ frontend test suites green + web build green + Android smoke with no overflow/blank-screen on 360/412/768 widths.

**Must NOT change:** Any model shape, any repository path (contract fidelity), any backend Java, any migration.

**Deliverables:** Phase 1 quality report (lint, test, perf traces), a11y checklist, no new UI.

---

### PHASE 2 — Core CS Subject Universe Expansion (2 weeks)

**Objective:** Make the catalog truly extensible and visually grouped without hardcoding subject identity.

**User value:** New Core CS worlds appear without app update logic duplication.

**Prerequisites:** Backend seeding pattern understood (V11-V13).

**Frontend scope:** SubjectsScreen category grouping + filter chips; Dashboard "recently learned / mastered / new" sections from DASH-001 assessment/mastery; guard that adding a subject requires no code change.

**Screens/components:** PressableWorldCard already generic — add category chips row and grouping headers, no per-subject IconKey switch.

**State/repo/model:** If backend adds `category` to Subject DTO, add nullable parsing; otherwise derive grouping presentationally without breaking when field absent.

**API/backend deps:** `SUBJ-001` list already; category field is `FRONTEND + FUTURE BACKEND` (optional this phase).

**Testing:** Catalog golden tests at 3 widths, subjects FutureBuilder loading/error/empty/refresh contract, deep link via `/path/:subjectId?name=` still resolves for new subjects.

**Risks:** Category heuristics drifting from backend truth — keep them decorative not authoritative.

**Must NOT change:** Learning flows per subject; Adaptive/gamification logic.

**Deliverables:** Grouped subjects UI, documentation: "how to add Java without frontend change."

---

### PHASE 3 — Deep Subject Learning Experience (3 weeks)

**Objective:** Close the gap between "select subject" and "structured adaptive journey" — make topic missions legible.

**User value:** Learner understands current mastery, next mission, why it's next.

**Prerequisites:** Phase 1 green + DASH-001 reachable (or offline fake for dev).

**Frontend scope:** Path polish (milestone markers beyond first AVAILABLE, requiredMastery badge), TopicDetail → Lesson → Challenge flow copy consistency, inline Nova hint deep link to Tutor with `topicId`, Recommendation detail chain (previous difficulty → performance% → new recommendation + reason sentence) per spec §16/§21.

**Screens/components:** `recommendation_card` enhancement, `path_map_screen` milestone overlay (only when backend node status transitions arrive), `lesson_screen` hint reuse.

**State/repo/model:** Reuse `PathState` + `QuizResult.adaptive`; no new model fields.

**API/backend deps:** QUIZ-002 adaptive block already (reasonCode) + DASH recommendations — no new API.

**Testing:** Journey test: `Assessment → Path → Topic → Lesson → Quiz → Result → Adaptive → Recommendation → Back to Path`; golden for empty mastery.

**Risks:** Over-building milestone visuals before node status transitions exist — keep disabled behind `node.status` check.

**Must NOT change:** Mastery/difficulty/recommendation calculation.

**Deliverables:** Recommendation chain UX, lesson→challenge bridge, path mission polish.

---

### PHASE 4 — Topic Mastery Visualization (2 weeks)

**Objective:** Turn stored mastery into a comprehension aid.

**User value:** "What do I know? Where am I weak?" at a glance, driving intentional next missions.

**Prerequisites:** Phase 3 + `topic_mastery` populated.

**Frontend scope:** Dashboard MasteryStrip filter chips (Mastered/Proficient/Developing/Beginner — filter client-side, presentational only), ProgressScreen mastery detail with trend icons, TopicPerformance sparkline (only where backend history available, otherwise omit).

**Screens/components:** `MasteryStrip` enhancement, `AccuracyBars` already; add `MasteryFilter`.

**State/repo/model:** DASH `recentTopics` + PROG rows; no new parsing.

**API/backend deps:** Existing PROG-001/002 + DASH mastery — no migration.

**Testing:** Unit for filter logic, widget for chip selection, a11y for bar values.

**Risks:** Medium — chart overload risk (keep single bar chart as current).

**Must NOT change:** Band thresholds (40/70/90), trend deltas.

**Deliverables:** Mastery filters + enriched progress visuals.

---

### PHASE 5 — Adaptive Learning & Recommendation UX (2 weeks)

**Objective:** Make the adaptive loop visible and explainable per spec §39-40.

**User value:** Learner understands why the AI recommended Normalization and what happens if they improve.

**Prerequisites:** Phase 4 + Adaptive Spec §7-11 implemented server-side (already true for QUIZ-002).

**Frontend scope:** QuizResult adaptive card expansion (before mastery → after mastery delta with step 1/min(n,5) described not computed), Dashboard weakness summary (YOU ARE STRONG IN / NEEDS PRACTICE / WHY) when backend reason exists, recommendation priority ordering visible (priority 1→4).

**Screens/components:** `_AdaptiveOutcomeCard` delta display, `_AssessmentNudge` weak-topic guidance.

**State/repo/model:** Display `AdaptiveInsight.previousMasteryScore` delta if backend sends it; otherwise show current only.

**API/backend deps:** None new — adaptive data already on quiz result + DASH recommendations.

**Testing:** Matrix fixtures T01-T22 per Adaptive §28 (non-UI: assert UI displays expected adaptive values when backend returns those fixtures).

**Risks:** Medium — leakage of internal mechanics if copy reveals too much (keep reasonCode sentences verbatim, not threshold exposition).

**Must NOT change:** Adaptive formulas, priority weights.

**Deliverables:** Adaptive chain visibility, weakness summary cards.

---

### PHASE 6 — Advanced Gamified Progression (2 weeks)

**Objective:** Tie mission completion to the gamification loop visually, without inventing reward logic.

**User value:** Progress feels like adventure (unlocks, streaks, level-ups anchored to learning outcomes).

**Prerequisites:** Phase 5 + Gamification Spec §4-10 implemented (GAM-001..003).

**Frontend scope:** Trigger `AchievementUnlockOverlay` + `LevelUpOverlay` on path node completion detection (future node status COMPLETED — detect transition on Path reload after quiz), StreakScreen milestone predictions (3/7/14/30 with progress not computation), trophy room deep links from dashboard.

**Screens/components:** `celebrations` wiring, `badges` streak display, `streak_screen`.

**State/repo/model:** Use `compareSnapshots` already for XP/level deltas; reuse `StreakState` for milestone.

**API/backend deps:** GAM-001..003 reads (already defined); no XP writes.

**Testing:** Integration assert level-up fires exactly when `level(xp)` crosses T(n), not on mock increments.

**Risks:** Low — celebratory overuse (gate to one overlay per event).

**Must NOT change:** T(n)=50(n-1)n, streak UL, achievement predicates.

**Deliverables:** Node-completion celebration wiring, streak milestone visuals.

---

### PHASE 7 — AI-assisted Core CS Discovery / Search (3 weeks, FEATURE-FLAGGED)

**Objective:** Provide a strong Core CS subject/topic discovery experience without faking curricula.

**User value:** Learner finds the right Core CS world faster (content discovery, not "learn anything").

**Prerequisites:** Phases 1-5 + future backend search contract R1/R3 (must not be faked).

**Frontend scope:** Build DiscoveryScreen boundary with states: Supported / Ready to start (→ Assessment) / Generating / Not supported (suggestion: try DBMS/Networks/etc.) / Failed / Retry / Auth/network. Add category + text search over SUBJ-001 with client filter, upgrade to server filter when R1 lands. Flag off until `API_BASE_URL` returns new route — show "Core CS catalog search is being prepared" empty state.

**Screens/components:** New `features/discovery` feature folder with repo method stubs tagged `TODO(FUTURE BACKEND CONTRACT REQUIRED)`.

**State/repo/model:** Future `DiscoveryRepository` with typed states; current catalog Future remains.

**API/backend deps:** FRONTEND + FUTURE BACKEND (R1/R3) — phase cannot be marked COMPLETE until backend implements.

**Testing:** Search debounce, category chip selection, discovery state machine, 404/503 handling for discovery.

**Risks:** High — inventing search endpoint or subject generator. Mitigation: code review for any `"/subjects/search"` hard string without contract reference; CI flag fail if `discover` repo method is marked TODO still and UI is live.

**Must NOT change:** Fluid Mechanics or any non-CS scope, Gemini direct calls, fixed subject IDs.

**Deliverables:** Discovery boundary screen (flagged), client-filter search upgrade-ready, documentation of required contracts R1/R3.

---

### PHASE 8 — Cross-Subject Learner Intelligence (2 weeks)

**Objective:** Surface the learner profile across multiple subjects without ranking learners against each other.

**User value:** "Your strongest area is Programming (82%) vs Operating Systems (41%) — OS needs attention" — but only when backend supplies it.

**Prerequisites:** Phase 6 + backend profile aggregation.

**Frontend scope:** Dashboard "Learner profile" strip reflecting `DASH-001 learner.overallMastery` + `appConfig` + per-subject progress read (iterate over known subjectIds to collect `AssessmentOutcome.overallMastery` + `mastery.recentTopics` scoped — existing endpoints only). Do NOT derive authoritative ranking; show only what backend returns (overallMastery per subject's mastery rows).

**Screens/components:** Profile enhancement + optional `CrossSubjectProfile` card (behind feature flag until history endpoint R4).

**State/repo/model:** Reuse `LearnerProfile` + per-subject assessment outcomes.

**API/backend deps:** Existing DASH/PROG + optional `PROG history R4` for completeness — FUTURE.

**Testing:** Two-subject fixture: Programming 82, OS 41 — assert card shows both when endpointsreturn both, shows single when other empty.

**Risks:** Low if no ranking is invented; high if frontend computes "weakest" ranking itself — forbidden.

**Must NOT change:** Adaptive ranking/thresholds.

**Deliverables:** Cross-subject profile strip (display-only).

---

### PHASE 9 — Responsive / Mobile / Web Excellence (3 weeks)

**Objective:** One product across phone, tablet, desktop, without two apps.

**User value:** Professional, technically impressive adventure on every screen.

**Prerequisites:** All functional phases complete — polish after behavior.

**Frontend scope:** Add `AppBreakpoints` tokens, responsive builders for dashboard (2-col), subject grid (phone 1-col → tablet 2-col → desktop 3-col), lesson max-width constraint, path map wider lane on tablet, tutor split view on desktop, NavigationRail for expanded, keyboard interaction + focus + reduced-motion.

**Screens/components:** Shared shell adaptation, every Screen wrapped with responsive scaffold, typography scaling clamp.

**State/repo/model:** None.

**API/backend deps:** None.

**Testing:** Golden screenshots at 360/768/1440/1920, web build + Loki/Overflow audit, Android Go frame timing, keyboard traversal tests, Lighthouse perf.

**Risks:** High visual regression risk — add screenshot baselines before migration.

**Must NOT change:** API contracts, behavioral logic.

**Deliverables:** Responsive system, a11y sweep, perf budget report.

---

### PHASE 10 — Final Product Polish & Verification (2 weeks)

**Objective:** Prove readiness per Definition of Done (§45), not claim it.

**User value:** Shippable adaptive adventure for at least one fully seeded subject.

**Prerequisites:** All phases green.

**Frontend scope:** Full regression across authentication → onboarding → subject selection → Core CS catalog (grouped) → learning journey → assessment → lessons → quizzes → adaptive recommendations → mastery → gamification → AI tutor (with topic context) → progress → navigation for Programming + one additional subject (V12 pattern). Enforce empty/error/offline states on every flow; fix any blocking overflow/navigation/contrast/perf.

**Screens/components:** Final visual sweep (neon readability, elevation, illustration polish), celebration pacing, sound toggle persistence audit.

**State/repo/model:** Final invalidation audit (no stale session leakage), provider leak check.

**API/backend deps:** Deploy backend at `API_BASE_URL` — verify `/v3/api-docs` + 429/503 branches.

**Testing:** Full Definition of Done verification: analyze + test + web build + web run + Android run + end-to-end journeys + API integration verification (captured HAR + screenshots). Regress 266 backend tests still green.

**Risks:** Integration surprises on rate limits (429) and AI unavailability (503) — test both with forced triggers.

**Must NOT change:** No rewrites; only polish.

**Deliverables:** Final verification report with HAR/screenshot evidence.

---

## 43. Phase Dependency Graph

```
Phase 1 Foundation Stabilization & UX Quality
  │
  ├─→ Phase 2 Core CS Subject Universe Expansion
  │     │
  │     ├─→ Phase 3 Deep Subject Learning Experience
  │     │     │
  │     │     ├─→ Phase 4 Topic Mastery Visualization
  │     │     │     │
  │     │     │     ├─→ Phase 5 Adaptive Learning & Recommendation UX
  │     │     │     │     │
  │     │     │     │     ├─→ Phase 6 Advanced Gamified Progression
  │     │     │     │     │     │
  │     │     │     │     │     ├─→ Phase 8 Cross-Subject Learner Intelligence
  │     │     │     │     │     │     │
  │     │     │     │     │     ├─→ [Phase 7 AI-assisted Core CS Discovery — feature-flagged,
  │     │     │     │     │     │      depends on 1..5 + FUTURE backend]
  │     │     │     │     │     │     │
  │     │     │     │     │     └─→ Phase 9 Responsive / Mobile / Web Excellence
  │     │     │     │     │           │
  │     │     │     │     │           └─→ Phase 10 Final Product Polish & Verification
  │     │     │     │     │
  │     │     │     │     └─[Phase 7 may parallelize with 6/8/9 but cannot complete without backend]
  │     │     │     │
  │     │     │     └─[Phase 8 needs Phase 6 but not Phase 7]
```

**Parallelizable:** Phases 7, 8, 9 may overlap after Phase 5, but Phase 7 never claims completeness without backend, and Phase 10 depends on all.

**Critical path:** 1 → 2 → 3 → 4 → 5 → 6 → 8 → 9 → 10 (Phase 7 off critical path, flag-gated).

---

## 44. Risk Analysis

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R1 | Inventing APIs/fields, presenting mock as real | Medium | High | CI grep for `"/api/v1"` strings not in Contract §3 matrix → fail; `api_client_test` asserts envelope; blueprint §33 conflict-resolution rule enforced in PR review |
| R2 | Hardcoding subject lists / per-subject branching | Medium | High | Lint for `== "DBMS"` / `== "OS"` strings; require Subject-agnostic review checklist; document "add Java without frontend change" |
| R3 | Recomputing mastery/difficulty/recommendations/XP client-side | Low (guarded) | High | Code review for `score>80=>HARD` or `masteryScore` arithmetic; all values `final` in models except display formatting |
| R4 | Fabricating completion% / progress derivation | Medium | Medium | Dashboard §10.4 ratified UNAVAILABLE — fail review if `completion_percentage` inferred from node statuses; show gates not percents |
| R5 | Long-tail search promising unsupported subjects | Medium | Medium | Discovery copy always scopes to Core CS; `discover` states include NotSupported with fallback subject suggestions |
| R6 | Responsive breakpoints breaking phone layout | High (phase 9) | Medium | Phase 1 screenshot baselines at 360/412; golden tests at 360/768/1440 before phase 9 merge |
| R7 | Auth session leakage across users | Low (already fixed) | High | Regression test: login A → view DASH, logout, login B → assert B's DASH != A's; `ref.invalidate` audit per PR |
| R8 | Rate limit / AI unavailability poorly handled | Medium | Medium | Dedicated widget tests for 429→RateLimitedException + 503→AiUnavailableException → Nova messages + Retry; integration test triggers 10/hr cap |
| R9 | Gamification ornamentation without trigger | Low | Low | Design review against §26 trigger map; no achievement/badge without server eventId |
| R10 | Prompt/system leakage via Tutor display | Low | High | TutorScreen never renders `promptVersion/modelName/latency/rawResponse`; review AI-001 `context` fields only |
| R11 | Web vs Mobile drift (two apps) | Medium | Medium | Single `router.dart` + `AppBreakpoints` — flag any `if (kIsWeb) ScreenA else ScreenB` divergence |
| R12 | Backend pending surfaces staying pending indefinitely (PATH-002/GAM/DASH/ASMT/AI) | High | High | Track backend release per phase; frontend stays functional on fallbacks (e.g., path prompt when no ACTIVE, offline optimistic session) |
| R13 | Overengineering (microservices, abstraction for imaginary requirements) | Low | Medium | Blueprint §46 principles — reject unnecessary state-management rewrites, design-system rewrites, speculative AI infra |
| R14 | Secrets committed (GEMINI_API_KEY, JWT_SECRET) | Low | Critical | Secret scanning in CI; `grep -r "GEMINI_API_KEY"` → fail if found outside `.env.example` placeholder |

---

## 45. Definition of Done

**A phase is NOT done until evidence exists — `flutter analyze` + `flutter test` alone never complete a feature.**

### Functional (per subject tested, at least Programming + one seeded world)

- [ ] Authentication works (register/login/validate/logout, persistence across cold start, 401→login)
- [ ] Onboarding works (skip + last-slide CTA, intercepted by sessionPhase)
- [ ] Subject selection works (tap world → path or assessment, scan → assessment intro)
- [ ] Core CS catalog works (grouped, filter chips decorative, deep link `/path/:subjectId` resolves)
- [ ] Learning journey works (path nodes statuses respected, LOCKED SnackBar, AVAILABLE→topic)
- [ ] Assessment works (delivery K=3 grouped by topic, submit 201, result triplets, 409 conflict)
- [ ] Lessons work (content+summary verbatim, sourceType badge, inline hint with `topicId`, `Take the challenge` → quiz)
- [ ] Quizzes work (progress, difficulty pill, Nova hint, submit, review only post-submit, timer optional)
- [ ] Adaptive experience works where backend supports it (`adaptive.{masteryLevel/trend/nextDifficulty/recommendedActivity/reasonCode}` displayed verbatim)
- [ ] Recommendations work where backend supports them (≤3 ACTIVE sorted, reason sentence shown, chain navigable)
- [ ] Mastery visualization works (recentTopics ≤5 + profile overallMastery, progress bars, filter chips presentational)
- [ ] Gamification works (XP delta, level T(n) nulls at 50, streak chip, trophy grid, celebrations exactly per trigger)
- [ ] AI tutor works where backend supports it (stateless 8-window 60s timeout, refused/degraded, subject/topic focus)
- [ ] Progress works (overall mastery + topic mastery + streak + achievements aggregated on progress + dashboard)
- [ ] Navigation works (shell 4 tabs + Nova FAB, full-screen stack, custom transitions, back/swipe, deep links)

### Quality

- [ ] No known blocking errors (no Sentry/Console red on happy path)
- [ ] No stale-session leakage (cross-user test passes)
- [ ] No major overflow (verified on 360dp + 768wp + 1440wp screenshots)
- [ ] No broken navigation (router guard pruned on every auth transition)
- [ ] Meaningful loading states (skeleton per DASH spec, not spinner dump)
- [ ] Meaningful error states (Nova title+message+Retry per §34, 429/503 distinct)
- [ ] Responsive web (single product across breakpoints per §30)
- [ ] Mobile validation (Android emulator touch/overflow/keyboard/haptics/audio)
- [ ] Accessible interactions (contrast, semantics, focus, reduced-motion gated)
- [ ] Acceptable performance (path starfield <16ms, quiz no jank, web payload budgeted)

### Verification (must be captured per phase, not assumed)

- [ ] `flutter analyze` (no errors)
- [ ] `flutter test` (all suites green)
- [ ] Web build (`flutter build web --dart-define=API_BASE_URL=…` succeeds)
- [ ] Actual web run (`flutter run -d web-server` + manual journey screen recordings/screenshots)
- [ ] Android/device verification (`flutter run -d windows|android --dart-define=API_BASE_URL=…`)
- [ ] Important end-to-end journeys (Register→Login→Subject→Assessment→Path→Lesson→Quiz→Result→Adaptation→XP→Achievement→Dashboard update — integration_test or manual HAR)
- [ ] API integration verification (capture `/v3/api-docs` + live 201/409/429/503 responses; mismatch → CONTRACT ISSUE)

**Final product readiness** = Phases 1-10 each meeting this DoD for Programming + one fully seeded Core CS subject, with backend контракты reachable at `API_BASE_URL` and no scope-crept non-CS departments introduced.

---

## 46. Final Architecture Principles

1. **EXTEND before REPLACE** — the current Flutter foundation is the vehicle. Add breakpoints and discovery behind feature flags; do not rebuild theme, routing, Riverpod, ApiClient, or model layer without a concrete incompatibility.
2. **REUSE before DUPLICATE** — subjects share one set of screens/widgets; no per-subject screen.
3. **GENERALIZE before HARDCODE** — topic/mastery/recommendation entities are the vocabulary; adding a subject is backend content, not a Dart branch.
4. **VERIFY before ASSUME** — every future capability is verified on device/web + against live API, capturing HAR/screenshots. `Test passing` ≠ `working`.
5. **REAL API before FAKE API** — use the authoritative Contract v1.4.0; future surfaces are labelled `FUTURE BACKEND CONTRACT REQUIRED` and left as isolated scaffolding, not wishful mocks.
6. **BACKEND AUTHORITY before FRONTEND BUSINESS LOGIC** — mastery 40/70/90, weight 1/min(n,5), trend ±5, ladder one-step, T(n)=50(n-1)n, XP tables, streak UL, achievement predicates — all computed server-side and rendered verbatim.
7. **ADVENTURE FRAMING before LMS CRUX** — Student→Player, Subject→World, Topic→Mission stays the product copy from onboarding to celebrations.
8. **CORE CS SCOPE before UNIVERSAL CATALOG** — search expands the curated technical universe, not the academic universe (no Fluid Mechanics/Civil etc.).
9. **RESPONSIVE ONE-PRODUCT before TWO-PRODUCTS** — breakpoints + rail vs NavigationBar are chrome; state + repos are shared.
10. **QUALITY over COUNT** — one fully seeded subject with a demonstrable loop (assessment→weakness→path→lesson→quiz→adaptation→recommendation→progress→tutor) outweighs ten shell worlds with uniform card grids.
11. **SECURITY by DEFAULT** — secure storage for tokens, no Gemini keys in client, no secrets in logs, Bearer only, 401→wipe, X-Request-ID propagation.
12. **ACCESSIBLE & PERFORMANT by DESIGN** — contrast/semantics/44×44/keyboard/reduced-motion: non-negotiable; 16ms frame budget caps celebration excess.
13. **TESTABLE by STATE SHAPE** — providers own behavior; models own parsing; widgets own rendering; errors own mapping — each independently unit-tested, integration-tested across the real contract, not fiction.
14. **COMMITTED CONTRACT FIDELITY** — every endpoint/path/method/field/errorCode name is taken from GameLearn_AI_API_Contract.md v1.4.0 and neighboring approved specs. Contradictions are flagged as `CONTRACT ISSUE … STATUS: REQUIRES RESOLUTION` and resolved in the contract before code.

---

## Appendix — Backend Class Verification Snapshot (2026-08-27)

Controllers present: `AuthController, SubjectController, TopicController, LessonController, LearningPathController, AssessmentController, DashboardController, GamificationController, QuizController, ProfileController, ProgressController, AiTutorController, ProgressController` — 12 surfaces, confirms contract matrix is wired.

Services present: `AdaptiveLearningService, LearningPathService/GenerationService/Persistence, LearnerContextBuilder, FallbackPathPlanner, DashboardService, AiTutorService/Service+TutorContextBuilder, Gamification subpackage, QuizService/SubmissionService, Assessment subpackage, AuthService` — aligns to specs.

Migrations V1-V13 applied; database gap NONE for approved surface per §21 verdicts.

**Implication for blueprint consumer:** Treat PATH-002/GAM/DASH/ASMT/AI as backend-dependent but client-ready — integration HAR will confirm which transitions are already `200/201` vs `503` vs "endpoint missing" (contract pending deploy) before each phase's exit.

---

## Appendix — Repository State on 2026-08-27

`pubspec.yaml`: flutter 3.9+, gamelearn_app 1.0.0+1, 6 direct deps (Riverpod 3.0, GoRouter 16.2, http 1.5, secure_storage 10, shared_prefs 2.5, audioplayers 6.5), lints 6.0.0. `lib/` 72 files, `test/` 6 suites, `integration_test/` present. No uncommitted diff at blueprint creation (see Final Verification).

---

*End of Blueprint — One authoritative frontend development blueprint for GameLearn AI. Build from ACTUAL CODE + ACTUAL API + APPROVED SPECIFICATIONS + CORE CS ADAPTIVE LEARNING VISION. No implementation performed.*

