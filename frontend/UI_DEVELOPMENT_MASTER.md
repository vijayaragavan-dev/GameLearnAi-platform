# GameLearnAI — UI Development Master Contract

> **Scope:** `frontend/` only — preparation for Antigravity-driven visual redesign.
> **Baseline commit:** `56bf1c166ee085a943e8effced54b63e43728cd1` — `checkpoint: save current GameLearnAI state before frontend redesign`
> **Repository:** `vijayaragavan-dev/GameLearnAi-platform`
> **Status:** Checkpoint PASS — this document is the shared contract. No application code was modified to produce it.
> **Authority:** Actual codebase under `frontend/lib/` is the source of truth. Do not invent architecture.

---

## 1. Product Vision

### What GameLearnAI Is
- **AI-powered** — Nova AI Tutor (AI-001) + Learning Path generation (PATH-002) + Adaptive Engine.
- **Gamified** — XP, levels, streaks, achievements, 14 games, progress rings, unlocks.
- **Student-focused** — syllabi as adventure trails, not admin tables.
- **Interactive** — play-to-learn loops: LEARN → PLAY → PROGRESS → REWARD → UNLOCK → MASTER.
- **Premium** — futuristic game HUD, not a CRUD LMS.
- **Game-oriented** — 14 distinct game identities share engines but feel distinct.
- **Personalized** — DASH-001 dashboard aggregates 10 sections; assessment baselines drive per-topic mastery/difficulty; recommendations are server-bounded (≤3).

### Target Feeling
**RPG + futuristic game HUD + AI learning companion + premium education platform.**

Think: command center, starfield trails, level badges, XP arcs, Nova companion, trophy room, world maps — rendered with the polish of a shipped game, the readability of a premium education product.

### What It Must NOT Look Like
- generic LMS / CRUD dashboard / ordinary quiz app / admin panel / generic SaaS dashboard
- Default Material scaffolds with no identity
- Childish cartoon, neon overload, gradient-everywhere

### Visual Direction
A single reference image defines the target quality bar: **dark near-black foundation, purple primary, cyan accents, gold XP, glass panels, subtle glow, rounded 20px cards, responsive command-center hierarchy.** Do not copy another product's brand verbatim — translate its *quality* (density, contrast, motion, information hierarchy) into GameLearn's own tokens (`AppColors`, `AppLightColors`, `AppStyles`, `AppGradients`, `AppShadows`, `AppMotion`).

---

## 2. Existing Baseline — UI-0 to UI-5 PASS

These phases are **complete and verified on `main`**. Future work enhances them, never rebuilds them.

| Phase | Name | Verdict | Evidence |
|-------|------|---------|----------|
| **UI-0** | Audit & Stabilization | **PASS** | `frontend/ui_upgrade_plan.md:1` (347 lines) — full read-only audit of ~95 Dart files, router, theme, responsive, dashboard, subjects, path, assessment, games, game-result, gamification, API contracts, audio, mobile/LAN. Protected baseline identified. |
| **UI-1** | Design System + Responsiveness Foundation | **PASS** | `frontend/lib/core/theme/app_colors.dart:1`, `app_theme.dart:1`, `app_typography.dart:1`, `app_styles.dart:1`, `app_breakpoints.dart:1`, `app_motion.dart:1`, `shared/widgets/responsive_layout.dart:1` (ResponsiveCenter/AdaptiveGrid/SafeRow), `features/shell/shell_screen.dart:1` (NavigationRail ≥600, bottom bar <600, constrained 1120). Build: `flutter analyze` 0 errors, `flutter build web` succeeds (per `report.txt`). |
| **UI-2** | Theme (Dark/Light/System) | **PASS** | `app_theme.dart:12` `buildGameLearnDarkTheme()` + `app_theme.dart:157` `buildGameLearnLightTheme()`, `app_colors.dart:19` `AppColors` (dark) + `AppLightColors` (light), `core/theme/theme_controller.dart:1` `themeControllerProvider`, `gamelearn_app.dart:18` `theme/themeMode` wiring, `features/profile/presentation/settings_screen.dart:1` toggle + persistence. Dark is flagship; light is intentional white/slate, same brand accents. |
| **UI-3** | Gamified Home (Dashboard) | **PASS** | `features/dashboard/presentation/dashboard_screen.dart:1` (1933 lines) — hero Level/XP/Streak, Continue Learning, Journey/Progress, Subjects, Daily Quests, Game Zone, Achievements/Streak; `dashboard_provider.dart:1` + `dashboard_models.dart:1`; order matches LEARN→PLAY mandate; no fake data; `AdaptiveGrid`, `ResponsiveCenter` used. |
| **UI-4** | Worlds & Syllabus | **PASS** | `features/subjects/presentation/subjects_screen.dart:1` (430 lines) + `subject_grouping.dart:1` (heuristic grouping), `features/learning/path/presentation/path_map_screen.dart:1` + `path_provider.dart:1` + `learning/data/content_repository.dart:1`, `features/learning/topic/presentation/topic_detail_screen.dart:1` + `features/learning/lesson/presentation/lesson_screen.dart:1`. Path is backend-driven `LearningNode` trail (CustomPaint starfield), responsive LayoutBuilder. |
| **UI-5** | Personalized Path & Assessment | **PASS** | `features/challenge/assessment/presentation/assessment_intro_screen.dart:1`, `assessment_run_screen.dart:1`, `assessment_result_screen.dart:1`, `assessment_provider.dart:1`, `challenge/data/assessment_repository.dart:1`. Flow `Intro → Run → Submit (201/409) → Result → View Path → PathMap` — bug `View my path → home` fixed to `Routes.path(subjectId)`. Verified by `test/ui5_personalized_path_regression_test.dart:1` (381 lines). |

**Test / Build baseline on `56bf1c1`:**
- **Tests:** 34 Dart files under `frontend/test/` — `test/ui5_*`, `test/ui6_subject_aware_games_test.dart:1` (222 lines), `test/game_engine/*` (timer/combo/scoring/content_mapper), `test/models/*`, `test/platform/polish_test.dart:1`, `test/widgets/screens_test.dart:1`, etc. Baseline 540 tests passing post-Gate1 (per `ui_upgrade_plan.md:27`); `flutter test` is the gate — do not fabricate counts, run it.
- **Analyze:** `analysis_options.yaml:1` (`flutter_lints` strict-casts, avoid_print, etc.) — `flutter analyze` 0 blocking errors on baseline.
- **Build:** `flutter build web` succeeds; `pubspec.yaml:6` env `>=3.9.0`, deps `flutter_riverpod 3.0`, `go_router 16.2`, `http 1.5`, `flutter_secure_storage 10`, `shared_preferences 2.5`, `audioplayers 6.5`; fonts `GameLearnDisplay` (SpaceGrotesk VF) + `GameLearnBody` (Inter VF); assets `assets/audio/`.

---

## 3. Current Architecture (Actual `frontend/lib/`)

```
lib/main.dart                          // bootstrap: SharedPreferences → ProviderScope override
  app/gamelearn_app.dart               // MaterialApp.router + light/dark ThemeData + ThemeMode
  app/router.dart                      // single GoRouter: ShellRoute (4 tabs) + ~28 full-screen routes, _page transitions, redirect by SessionPhase
  core/
    config/app_config.dart             // String.fromEnvironment API_BASE_URL (10.0.2.2 default), envName
    theme/{app_colors,app_theme,app_typography,app_styles,app_breakpoints,app_motion,theme_controller}
    network/{api_client,api_exception} // bearer injection, timeouts, ErrorResponse → ApiException hierarchy
    models/{auth,content,dashboard,quiz,assessment,gamification,tutor,model_ids}
    storage/token_storage.dart         // flutter_secure_storage gl_access_token
    providers.dart                     // sharedPreferencesProvider, sessionTokenProvider, apiClientProvider, *Repo providers, audio/haptics
    audio/audio_manager.dart + haptics/haptics.dart
    error/user_facing_error.dart       // describeError → Nova messages
    utils/formatters.dart + gamification_delta.dart
  features/
    auth/{data/auth_repository, presentation/{splash,login,register,onboarding}, providers/session_controller}
    dashboard/{providers/dashboard_provider, presentation/dashboard_screen}
    subjects/presentation/{subjects_screen,subject_grouping}
    learning/{data/content_repository, path/{providers/path_provider, presentation/path_map_screen}, topic/presentation/topic_detail_screen, lesson/presentation/lesson_screen}
    challenge/{data/{quiz_repository,assessment_repository}, quiz/presentation/{quiz_screen,quiz_result_screen}, assessment/{providers/assessment_provider, presentation/{intro,run,result}}, recommendation/presentation/recommendation_screen}
    tutor/{data/intelligence_repository, presentation/tutor_screen}
    gamification/{data/gamification_repository, models/game_result_models, providers/{persistent_game_result,game_result_submitter,game_results_provider}, presentation/{achievements_screen,badge_detail_screen,streak_screen}}
    progress/presentation/{progress_screen,topic_performance_screen}
    profile/presentation/{profile_screen,settings_screen}
    shell/shell_screen                 // responsive chrome
    game_engine/{models/game_models, engine/{game_timer,game_scoring,game_combo}, utils/{game_content_mapper,difficulty_utils}, widgets/{game_scaffold,game_hud,polished_game_hud,game_result_screen}, audio/game_sound_controller}
    games/{hub/presentation/game_hub_screen, quiz_battle,memory_match,drag_drop,speed_run,debug_arena,unlock_code,concept_builder,sequence_master,target_challenge,mystery_case,boss_battle,puzzle_arena,connectivity_lab,snake_and_ladder/presentation/*_screen}
  shared/widgets/{responsive_layout,achievement_icon,badges,celebrations,feedback,game_button,game_card,nova_companion,quiz_option,recommendation_card,stat_card,xp_bar}
```

- **State:** Riverpod 3.0 — `Notifier` (`SessionController`, `DashboardController`, `PathController` family, `AssessmentController` family, `ThemeController`) + `Provider` for repos/config; remaining reads via `FutureBuilder` + repo `Future`s. Repos are thin, no business logic duplication.
- **Routing:** `GoRouter` `Provider<GoRouter>` with `refreshListenable` on `sessionProvider`; `ShellRoute` builder `ShellScreen(location, child)`; public routes `splash/onboarding/login/register`, shell tabs `home/subjects/progress/profile`, full-screen `/path/:subjectId`, `/topic/:topicId`, `/lesson/:topicId`, `/quiz/:topicId`, `/quiz-result` (extra `QuizResultArg`), `/recommendation` (extra `RecommendationItem`), `/assessment/:subjectId*`, `/tutor`, `/achievements*`, `/streak`, `/performance/:topicId`, `/settings`, `/games/:topicId` + 14 sub-routes via `Routes.*` helpers with `_withSubjectQuery`.
- **Repositories / API layer:** `ApiClient` base `AppConfig.apiBaseUrl`, `Accept: application/json`, bearer via `sessionTokenProvider`, 15s default / 60s for PATH-002 + AI-001, `onUnauthorized` excludes `_authPaths`, `_guard` maps exceptions, `_errorFrom` parses `ErrorResponse`. Repos: `AuthRepository` (login/register/logout/validate), `ContentRepository` (subjects/topic/lesson/learning-path/generate), `QuizRepository` (quizForTopic/submit), `AssessmentRepository` (get/submit/result), `GamificationRepository` (summary/achievements/streak/profile/progress/game-results), `IntelligenceRepository` (dashboard, ai/tutor).
- **Models:** Defensive `fromJson` with defaults, UUID guards `model_ids.dart:uuidOf/uuidOrNull`; backend owns XP/levels/mastery/difficulty/recommendations — frontend never recomputes.
- **Theme system:** `AppColors` (dark) + `AppLightColors` (light) semantic tokens; `buildGameLearnDarkTheme()` / `buildGameLearnLightTheme()` `ThemeData` (Material3, scaffold/surface/error, appBar, navigationBar/Rail, card, divider, inputDecoration, dialog, snackBar, switch); `AppTypography` (GameLearnDisplay/GameLearnBody variable fonts); `AppStyles` (spacing 4–48, radius 10–999, elevation, shadows soft/glow/drop, gradients brand/cyan/xpGold/streakFire/backgroundWash/novaCore); `AppMotion` (180/300/500/950 ms + stagger 55ms, curves easeOut/easeInOut/standard/spring/decelerate).
- **Responsive system:** `AppBreakpoints` (compact 600 / medium 900 / expanded 1200, maxContentWidth 1120, wide 1200, helpers `isCompact/isMedium/isExpanded/isWide/isRailVisible`, `AppGutters.pagePadding/columns`); `ResponsiveCenter`/`ResponsiveInset`/`AdaptiveGrid`/`SectionSpacing`/`ContentSurface`/`SafeRow` in `responsive_layout.dart:1`; `ShellScreen` rail ≥600, extended ≥1200.
- **Authentication:** `SessionPhase {restoring, unauthenticated, authenticated}` via `sessionProvider: SessionController`; JWT in `TokenStorage` (secure), `SessionToken` Notifier in-memory, `apiClientProvider.tokenProvider`, redirect guard in `router.dart:160`, `GET /auth/validate` on restore.
- **Gamification + Game-result:** `gamification_models.dart: Achievement/Streak/Summary`; `gamification_delta.dart: capture/compare`; `game_result_models.dart: GameResultSubmission` (`difficulty apiValue + clientRequestId + gameType + score/duration/bestCombo` → `POST /me/game-results` PROG-101 difficulty-aware, rate-limited), providers `persistent_game_result` + `game_result_submitter` (initState submit), widgets `LevelBadge`, `StreakChip`, `XPBar`, `DifficultyBadge`, `AchievementIcon`, `Celebrations` (confetti/level-up/achievement overlays).
- **Target baselines already passing:** Wrong-credentials message fix, PROG-101 difficulty contract, subject-agnostic entities, rate-limit transparent.

> **Explicit rule: DO NOT REBUILD THE FRONTEND.** Future VIS phases enhance existing files. Architecture, contracts, and state ownership stay as above.

---

## 4. Protected Architecture — Shared / Coordination-Required

These are **shared, load-bearing** — changes affect multiple features. Coordinate before touching.

| Area | Files | Why Protected | Coordination |
|------|-------|---------------|--------------|
| **App bootstrap** | `lib/app/gamelearn_app.dart:1`, `lib/main.dart:1` | ThemeMode wiring, ProviderScope overrides, router root | Owner: shared — PR must touch only one phase's concern |
| **Router** | `lib/app/router.dart:1` | 28+ routes, auth guard, transitions, `Routes.*` helpers, subject query propagation | Any route param addition (e.g., `?subjectId`) is cross-cutting — review with both owners |
| **Core providers** | `lib/core/providers.dart:1` | Repo bindings, `apiClientProvider`, `sharedPreferencesProvider`, `sessionTokenProvider` | No duplicate providers; preserve signatures |
| **Core theme** | `lib/core/theme/*` (6 files) | Single source for colors/typography/spacing/radius/shadows/gradients/motion/breakpoints | All visual work consumes tokens — no per-screen hard-coded colors |
| **Core network** | `lib/core/network/api_client.dart:1`, `api_exception.dart:1` | Auth headers, timeouts, error mapping | Preserve headers/auth/error — search usages first |
| **Core models** | `lib/core/models/*` (8 files) | Defensive `fromJson`, backend-owned fields | Preserve `fromJson`/`apiValue`/`uuidOf` — no recompute |
| **Core storage** | `lib/core/storage/token_storage.dart:1` | Secure token contract | — |
| **Error mapping** | `lib/core/error/user_facing_error.dart:1` | Nova user-facing messages | — |
| **Repositories** | `lib/features/*/data/*_repository.dart:1` (5 repos) | Method signatures define API contract | Preserve signatures/return types — no breaking change |
| **Providers** | `lib/features/*/providers/*` + `core/theme/theme_controller.dart:1` | Notifier families owned by one feature | Family key = subjectId/topicId — don't re-key |
| **Models (feature)** | `lib/features/gamification/models/game_result_models.dart:1`, `game_engine/models/game_models.dart:1` | Difficulty contract, GameConfig/GameResult | Gate1 difficulty preserved |
| **Shared widgets** | `lib/shared/widgets/*` (10 widgets) | Reusable across both owners — see Component Inventory | Enhance, don't duplicate |
| **Shell** | `lib/features/shell/shell_screen.dart:1` | Chrome for all shell tabs; responsive rail | Changes affect every tab |

**Rule:** Shared file changes require a single-owner PR that cites the other owner's features as `Co-reviewed`. If a phase can be done without touching shared files, prefer that.

---

## 5. Feature Ownership (File-Path Grounded)

No feature directory is owned by both developers. Shared widgets are enhanced by Developer A but consumed by both.

### DEVELOPER A — GAME EXPERIENCE
**Theme: Play, reward, motion, identity of the arcade.**

| Area | Primary Files |
|------|---------------|
| Shared visual components | `lib/shared/widgets/game_card.dart:1`, `game_button.dart:1`, `badges.dart:1`, `achievement_icon.dart:1`, `xp_bar.dart:1`, `celebrations.dart:1`, `stat_card.dart:1` (enhance-only) + `lib/features/shell/shell_screen.dart:1` (only when VIS-2 assigns shell to A) |
| Game Arena (hub) | `lib/features/games/hub/presentation/game_hub_screen.dart:1` |
| Game screens (14) | `lib/features/games/quiz_battle/presentation/quiz_battle_screen.dart:1`, `memory_match/memory_match_screen.dart:1`, `drag_drop/drag_drop_screen.dart:1`, `speed_run/speed_run_screen.dart:1`, `debug_arena/debug_arena_screen.dart:1`, `unlock_code/unlock_code_screen.dart:1`, `concept_builder/concept_builder_screen.dart:1`, `sequence_master/sequence_master_screen.dart:1`, `target_challenge/target_challenge_screen.dart:1`, `mystery_case/mystery_case_screen.dart:1`, `boss_battle/boss_battle_screen.dart:1`, `puzzle_arena/puzzle_arena_screen.dart:1`, `connectivity_lab/connectivity_lab_screen.dart:1`, `snake_and_ladder/snake_and_ladder_screen.dart:1` |
| Game engine presentation | `lib/features/game_engine/widgets/{game_scaffold.dart:1,game_hud.dart:1,polished_game_hud.dart:1,game_result_screen.dart:1}` + `lib/features/game_engine/audio/game_sound_controller.dart:1` + `lib/features/game_engine/engine/{game_timer,game_scoring,game_combo}.dart:1` (visual wrapper only — no logic rewrite) + `lib/features/game_engine/utils/game_content_mapper.dart:1` (presentation mapping) |
| XP/Rewards presentation | Celebration overlays in `game_result_screen.dart`, `lib/shared/widgets/xp_bar.dart`, `celebrations.dart`, `lib/core/gamification_delta.dart:1` |
| Achievements (game-related) | Visual treatment in `features/gamification/presentation/achievements_screen.dart:1` + `badge_detail_screen.dart:1` when VIS-6 assigns reward visuals to A |
| Animations & micro-interactions | `lib/core/theme/app_motion.dart:1`, `lib/shared/widgets/feedback.dart:1`, all game `Animated*` polish |
| Audio / game feedback | `lib/core/audio/audio_manager.dart:1` (Sfx/MusicContext hooks), `features/game_engine/audio/*` |

### DEVELOPER B — LEARNING EXPERIENCE
**Theme: Clarity, progression, personalization, calm.**

| Area | Primary Files |
|------|---------------|
| Dashboard (Command Center) | `lib/features/dashboard/presentation/dashboard_screen.dart:1` + `features/dashboard/providers/dashboard_provider.dart:1` |
| Worlds / Subjects | `lib/features/subjects/presentation/subjects_screen.dart:1` + `features/subjects/presentation/subject_grouping.dart:1` |
| Personalized Path | `lib/features/learning/path/presentation/path_map_screen.dart:1` + `features/learning/path/providers/path_provider.dart:1` + `lib/features/learning/topic/presentation/topic_detail_screen.dart:1` + `lib/features/learning/lesson/presentation/lesson_screen.dart:1` |
| Assessment result | `lib/features/challenge/assessment/presentation/assessment_result_screen.dart:1` (+ intro/run screens when path assessment owns) |
| Challenge (quiz) | `lib/features/challenge/quiz/presentation/{quiz_screen,quiz_result_screen,quiz_result_arg}.dart:1` + `features/challenge/recommendation/presentation/recommendation_screen.dart:1` |
| Nova AI Tutor | `lib/features/tutor/presentation/tutor_screen.dart:1` + `features/tutor/data/intelligence_repository.dart:1` |
| Profile + Settings | `lib/features/profile/presentation/{profile_screen,settings_screen}.dart:1` (theme toggle lives here, owned by B even though theming is shared) |
| Progress / Stats | `lib/features/progress/presentation/{progress_screen,topic_performance_screen}.dart:1` |
| Gamification (learning side) | `features/gamification/presentation/streak_screen.dart:1` (stats side); achievements *data* stays shared |

**Ownership guardrails:**
- Router is shared — either owner may add a query param, but the other must be reviewer.
- `lib/shared/widgets/feedback.dart:1`, `responsive_layout.dart:1` are shared — enhance via Developer A's card/system work, consume read-only by B.
- `lib/core/theme/*` is shared — B's theme settings consume it, A's card visuals consume it, neither hard-codes colors outside tokens.
- No file is double-owned for visual changes; if an overlap is unavoidable (e.g., `game_result_screen.dart` rewards vs `dashboard` quests), the VIS phase's `Owner` decides and the other reviews.

---

## 6. Git Collaboration

### Branching
- **`main` is stable integration.** Never develop directly on `main`.
- Recommended per-phase branches (phase suffix prevents collisions):
  - Developer A: `frontend/member-a-vis1`, `frontend/member-a-vis2`, … (`frontend/member-a-<phase>` from task)
  - Developer B: `frontend/member-b-vis1`, `frontend/member-b-vis2`, …
- One branch per VIS phase per developer. Delete after merge is optional.

### Prohibited Git
Never use (per task + checkpoint rules):
`git reset --hard`, `git reset --merge`, `git clean -fd`, `git clean -fdx`, `git checkout .`, `git restore .`, `git push --force`, `git push -f`, `git rebase`, `git filter-branch`, `git filter-repo`, `git init` — and never recreate the repo, never force-push, never rewrite history.

### Before Starting a Phase
```powershell
git fetch origin
git branch --show-current
git status --short
git log --oneline -5
# update branch safely — no merge/rebase without approval if diverged
git diff --stat
```

### After a Phase
```powershell
flutter analyze
flutter test
flutter build web
git status --short
git diff --stat
git diff --cached --stat   # review before commit
git add <explicit files>   # never git add . blindly
git commit -m "vis-<N>: <scope> — <what>"
git push                   # normal push, no --force
# open GitHub Pull Request → review → merge to main
```

### PR Discipline
- One VIS phase per PR.
- PR must list: objective, files changed, prohibited-changes check, `flutter analyze/test/build web` results.
- Require review from the other member if shared files touched.
- No overwriting another developer's work — fetch + inspect before push.

---

## 7. Visual Roadmap — VIS-0 to VIS-10

> **UI-0..UI-5 = COMPLETED** (see §2). **VIS-0 onward = planned.** Each future Antigravity invocation implements exactly ONE phase.

### Phase Template (applies to every VIS)
- **Objective:** why this phase exists
- **Owner:** A or B
- **Dependencies:** phases/files that must be stable first
- **Files / Feature Area:** allowed mutation scope (others are prohibited)
- **Deliverables:** concrete artifacts (not vague "polish")
- **Prohibited Changes:** what must NOT be touched in this phase
- **Validation:** `flutter analyze` + `flutter test` + `flutter build web` + visual checks + responsive checks + report.txt entry

---

#### VIS-0 — Design Contract
- **Objective:** Freeze quality bar, ownership, Git rules, data-truth, responsive/theme/accessibility gates before any pixel changes.
- **Owner:** Shared (this document + `frontend/design/*`)
- **Dependencies:** Baseline `56bf1c1` committed; `frontend/ui_upgrade_plan.md:1` reviewed
- **Files:** `frontend/UI_DEVELOPMENT_MASTER.md` (this file), `frontend/design/visual_design_system.md`, `frontend/design/screen_inventory.md`, `frontend/design/component_inventory.md`, `frontend/design/animation_spec.md` — **only these 5**
- **Deliverables:** This contract + 4 design docs; no code
- **Prohibited:** Any Dart/Java/API/routing/provider/model/logic/deps change
- **Validation:** `git status --short` shows only the 5 docs; architecture understood YES; no app code modified

#### VIS-1 — Premium Visual Foundation
- **Objective:** Single premium design language — no per-screen ad-hoc colors; all surfaces read as GameLearn.
- **Owner:** A (visual system) + B reviews theme consumption
- **Dependencies:** VIS-0
- **Files:** `lib/core/theme/app_colors.dart`, `app_theme.dart`, `app_typography.dart`, `app_styles.dart`, `lib/shared/widgets/{game_card,game_button,badges,xp_bar,stat_card,feedback}.dart` (enhance tokens, not logic)
- **Deliverables:** Token polish (shadows/glow/borders/gradients governed), card/button/badge/progress primitives that both owners will reuse
- **Prohibited:** Repo/provider/model/API changes; game logic; adding deps; new routes
- **Validation:** `flutter analyze` 0 errors; all shell + dashboard + subjects + path + game hub use only tokens (grep for raw `Color(0x` outside theme fails)

#### VIS-2 — App Shell & Navigation
- **Objective:** Navigation chrome feels premium and adaptive — compact bottom bar, medium NavigationRail, wide extended rail, constrained content reads well at 360/390/768/1024/1280/1440.
- **Owner:** A
- **Dependencies:** VIS-1
- **Files:** `lib/features/shell/shell_screen.dart:1`, `lib/shared/widgets/responsive_layout.dart:1`, `lib/core/theme/app_breakpoints.dart:1`
- **Deliverables:** Polished `_BottomBar`/`_Rail` (brand glow, selected indicator, haptics), shell content constraint (1120/1200), no overflow on resize
- **Prohibited:** Route changes, auth, dashboard/subjects/path/game logic
- **Validation:** Manual resize 360→1440 no RenderFlex overflow; `flutter analyze/test/build web` pass

#### VIS-3 — Dashboard Command Center
- **Objective:** Dashboard reads as **player command center**, not informational list — ordered: Profile/Level/XP → Continue → Journey → Subjects → Quests → Game Zone → Achievements. Demo-ready density.
- **Owner:** B
- **Dependencies:** VIS-1, VIS-2
- **Files:** `lib/features/dashboard/presentation/dashboard_screen.dart:1`, `lib/shared/widgets/recommendation_card.dart:1`, `lib/shared/widgets/nova_companion.dart:1` (dashboard usage)
- **Deliverables:** Hierarchy reorder, prominent Continue CTA, Journey/Progress polish, Quests strip, Game Zone teaser (General vs Subject teaser), Achievements/Streak polish — all real data (no fabricated XP/mastery)
- **Prohibited:** `dashboard_models.dart` recompute, repo changes, fake XP/mastery/streak, new API fields
- **Validation:** Dashboard renders truthfully with empty states when backend data absent; responsive 1→2 cols; `flutter test` includes `ui5`/`ui6` still pass

#### VIS-4 — Worlds & Learning Journey
- **Objective:** Subject discovery scales without hardcoded cards; language subtree for Programming (C/C++/Java/Python/JS) exposed without breaking Programming flow; syllabus trail shows Module grouping + lock/available/current/progress clearly.
- **Owner:** B
- **Dependencies:** VIS-1..VIS-3
- **Files:** `lib/features/subjects/presentation/subjects_screen.dart:1`, `features/subjects/presentation/subject_grouping.dart:1`, `lib/features/learning/path/presentation/path_map_screen.dart:1`, `lib/features/learning/topic/presentation/topic_detail_screen.dart:1`, `lib/features/learning/lesson/presentation/lesson_screen.dart:1`
- **Deliverables:** Adaptive subject grid (1→2→3 cols), Programming subtree (presentation-only grouping if backend adds field later), path trail module headers + completion ring + current highlight, responsive trail
- **Prohibited:** Hardcoding subject list, duplicating card rendering, inventing syllabus content, backend schema changes for visual purposes
- **Validation:** New subject from backend appears automatically; Programming languages visible without breaking generic Programming; no fake progress; responsive path trail

#### VIS-5 — Game Arena
- **Objective:** Hub + 14 game cards feel like an arcade — visual identity per game, clear difficulty/timed/combo/XP cues, subject context preserved, `General Games` vs `Subject Games` distinct.
- **Owner:** A
- **Dependencies:** VIS-1, VIS-2 (hub needs shell)
- **Files:** `lib/features/games/hub/presentation/game_hub_screen.dart:1`, `lib/features/game_engine/models/game_models.dart:1` (populate `GameConfig.subjectId` via topic lookup or route query — presentation only), `lib/app/router.dart:1` (add `?subjectId` query pass-through, backward compatible)
- **Deliverables:** Polished hub with General vs Subject sections, per-game color/emoji/category polish, honest "real XP vs local preview" note, subject-aware deep links
- **Prohibited:** Client-side question filtering that fakes backend ownership; new game endpoints; changing `GameType` enum
- **Validation:** Entering from Networks subject scopes to Networks topics (topicId-scoped, verified by `ui6_subject_aware_games_test.dart`); General Games vs Subject Games visually unmistakable

#### VIS-6 — Game Result & Rewards
- **Objective:** Every game ends with a satisfying reward loop: score/accuracy/XP, level progress, streak, achievements, performance feedback (`LEGENDARY…KEEP TRYING`), next-action suggestion, Retry / Continue / Return-to-subject.
- **Owner:** A
- **Dependencies:** VIS-5
- **Files:** `lib/features/game_engine/widgets/game_result_screen.dart:1`, `lib/features/gamification/presentation/achievements_screen.dart:1` + `badge_detail_screen.dart:1` (visual side), `lib/shared/widgets/celebrations.dart:1`, `lib/shared/widgets/xp_bar.dart:1`
- **Deliverables:** Polished accuracy ring, stat row, XP card (delta vs local preview), bestScore banner, streak/next-action (truthful empty when unavailable), `Return to subject` using `GameConfig.subjectId`
- **Prohibited:** Fabricating XP/streak/achievements; changing `game_result_submitter` contract (`difficulty` already gate-fixed)
- **Validation:** Quiz games award real XP via repo; non-quiz show honest local preview; no fake `d.xpGained`; celebrations respect `disableAnimations`

#### VIS-7 — Nova AI Tutor
- **Objective:** Nova feels like a resident AI companion — glass panel, streaming dots, bounded chat, encouraging tone, never leaks quiz answers, clearly premium.
- **Owner:** B
- **Dependencies:** VIS-1, VIS-2
- **Files:** `lib/features/tutor/presentation/tutor_screen.dart:1`, `lib/shared/widgets/nova_companion.dart:1`, `lib/core/models/tutor_models.dart:1` (read-only)
- **Deliverables:** Polished conversation glass panel, message bubbles, input bar, empty/error/rate-limit states, `Sfx` + haptics polish
- **Prohibited:** Changing AI-001 contract (`tutor_models`), inventing tutor endpoints, expanding message window beyond 8/2000
- **Validation:** Tutor honors bounded window (≤8, ≤2000 chars), honest empty/loading/error, no quiz-answer leakage, `flutter analyze` clean

#### VIS-8 — Motion & Micro-interactions
- **Objective:** Motion communicates state — no decoration-only animation. Page transitions, card hover/press, XP gain, level-up, path unlock, victory/failure are purposeful and accessible.
- **Owner:** A
- **Dependencies:** VIS-1..VIS-7 (motion wraps existing visuals)
- **Files:** `lib/core/theme/app_motion.dart:1`, `lib/shared/widgets/feedback.dart:1`, `lib/core/haptics/haptics.dart:1`, per-screen `Animated*` wrappers
- **Deliverables:** Page transition curve/duration governance, card press scale, stagger units, celebration durations, reduced-motion respect (`disableAnimations` checks)
- **Prohibited:** Adding heavy animation packages; ignoring reduced-motion
- **Validation:** Motion respects `AppMotion` tokens; `MediaQuery.disableAnimations` disables or reduces; no jank on web build

#### VIS-9 — Audio & Game Feedback
- **Objective:** Every hook is wired and verified: click, correct, wrong, gameplay tick, victory/failure, level-up, streak — with mute that persists and never crashes.
- **Owner:** A
- **Dependencies:** VIS-5..VIS-8
- **Files:** `lib/core/audio/audio_manager.dart:1`, `lib/features/game_engine/audio/game_sound_controller.dart:1`, per-game SFX triggers, `features/profile/presentation/settings_screen.dart:1` (audio toggles)
- **Deliverables:** All `Sfx.*` + `MusicContext.*` fire correctly, `pref_music_enabled/pref_sfx_enabled/pref_haptics_enabled` persisted, fail-safe `_platformBroken` silent degrade, small synthesized WAVs only
- **Prohibited:** Royalty-encumbered assets, large audio bloat, adding deps for audio
- **Validation:** Toggle music/SFX off persists; one platform failure never crashes app; `flutter build web` size sane

#### VIS-10 — Final Integration & QA
- **Objective:** Integration pass — no regressions, truthful data, responsive at 6 breakpoints, dark/light/system, a11y, docs, report completeness.
- **Owner:** Shared (both PR reviewers)
- **Dependencies:** VIS-1..VIS-9
- **Files:** No new visual scope — regressions only. Verifies every VIS deliverable.
- **Deliverables:** `flutter analyze` 0 errors, `flutter test` all pass, `flutter build web` succeeds, manual QA at 360/390/768/1024/1280/1440, contrast + focus + semantics checks, `report.txt` completeness, GitHub PRs merged
- **Prohibited:** New visual changes beyond regression fixes; any destructive Git
- **Validation:** 16 acceptance criteria in `frontend/ui_upgrade_plan.md:7.1` hold; dashboard still honest empty states; games preserve `subjectId` context; XP never fabricated

---

## 8. Design Target

**Quality bar:** premium · polished · interactive · game-like · modern · responsive · consistent

Visually communicates:

> **LEARN → PLAY → PROGRESS → REWARD → UNLOCK → MASTER**

Every screen should advance that loop — lesson leads to quiz/game, game yields XP/progress, progress unlocks next node/achievement.

---

## 9. Data Truth (Non-Negotiable)

Future UI **must never fabricate:**

- XP, progress, mastery, streak, achievements, quests, scores, completed topics, unlocked content.

**Rules:**
- Render only server values: `GamificationSummary`, `Achievement.unlockedAt`, `Dashboard.*`, `LearningNode.status`, `AssessmentOutcome.masteryLevel`, `GameResultSubmission` response, `Progress` mastery.
- When real data is absent, show **truthful** empty / unavailable / coming-soon states (`EmptyMiniCard`, `ErrorState`, `SkeletonCard`, honest "Local preview • Quiz games award real XP" note).
- Do not modify backend merely for visual purposes. If a visual needs a field that doesn't exist (e.g., `Subject.category`, module grouping, streak delta in game result), log it as a **Frontend Dependency** in `report.txt` and render a graceful fallback — do not invent.
- Rate limits (`429`) and `409 Conflict` (already assessed) are honest states, not errors to hide.

---

## 10. Responsive

**Preserve** the existing responsive system — enhance, never discard.

- **Tokens:** `AppBreakpoints.compact 600 / medium 900 / expanded 1200`, `maxContentWidth 1120`, `wide 1200` (`app_breakpoints.dart:14`); `AppGutters.pagePadding` (20/24/32) + `columns(compact:1→wide:3)`, `AppLayout.maxContentWidth/railWidth/railExtendedWidth`.
- **Primitives:** `ResponsiveCenter`, `ResponsiveInset`, `AdaptiveGrid`, `SectionSpacing`, `ContentSurface`, `SafeRow` (`responsive_layout.dart:1`).

**Target widths to verify per phase:**

| Width | Expectation |
|-------|-------------|
| **360** | Minimum phone — no overflow, pills wrap, text truncates honestly |
| **390** | Common phone — single column, 20px gutters |
| **768** | Tablet portrait — 1–2 cols, NavigationRail visible (≥600), 24px gutters |
| **1024** | Tablet landscape — 2–3 cols, rail + constrained 1120 |
| **1280** | Desktop — 3 cols, extended rail (≥1200), 32px gutters |
| **1440** | Wide desktop — same 3 cols but centered 1120/1200, not stretched |

**Expectations:**
- Mobile: bottom navigation 66dp, full-bleed content.
- Tablet: NavigationRail 80dp, constrained content, adaptive grids.
- Desktop: Extended rail 256dp, 2–3 col grids, higher density but same components.

**Guard:** No fixed widths that overflow; prefer `Flexible/Expanded/Wrap/LayoutBuilder`. Re-test resize after every phase.

---

## 11. Theme

**Preserve Dark / Light / System — Dark is flagship.** Light must be intentionally designed.

- **Dark:** `AppColors` (background `#070B17`, surface `#10172A`, elevated `#151E35`, high `#1B2542`, text `F1F5F9/94A3B8/64748B`, border `24304F/334368`, primary `#8B5CF6`, secondary `#22D3EE`, xp `#FACC15`, streak `#FB923C`, success `#34D399`, error `#F87171`).
- **Light:** `AppLightColors` (background `#F1F5F9`, surface `#FFFFFF`, high `#E2E8F0`, text `0F172A/334155/64748B`, border `E2E8F0/CBD5E1`, same accents).
- **Controller:** `theme_controller.dart: ThemeMode` + `SharedPreferences` persistence — consumed in `gamelearn_app.dart:14`.
- **Settings:** Toggle lives in `features/profile/presentation/settings_screen.dart:1` — System/Dark/Light.
- **Rule:** Screens prefer `Theme.of(context).colorScheme` / `isDark` adaptives over raw `AppColors` where surfaces/text are concerned; accents stay constant.

---

## 12. Accessibility

Document and verify per phase:

- **Semantic labels** — `Semantics(button:true, selected:, label:'<Tab> tab')` already in `shell_screen.dart:119`; every game/card/action needs same.
- **Contrast** — dark `F1F5F9` on `#070B17` and light `0F172A` on `FFFFFF` meet WCAG; purple `#8B5CF6` on dark passes, verify light chips.
- **Touch targets** — ≥48dp (bottom bar 66dp already); game tiles, chips, buttons must preserve; no 32dp tap targets.
- **Focus** — `FocusNode` where input (tutor), visible focus ring via `ThemeData`.
- **Keyboard** — web: Tab order through nav rail + cards + actions; tutor input `FocusNode`.
- **Reduced motion** — `AppMotion` durations/curves are tokens; every `Animated*`/`TweenAnimationBuilder` must check `MediaQuery.disableAnimations` or `AppMotion` guard (path pulse, dashboard stagger, game HUD already do).
- **Readable typography** — `AppTypography` `GameLearnDisplay` (SpaceGrotesk VF) + `GameLearnBody` (Inter VF) variable `wght`; `body` 15/1.45, `caption` 12.5/1.35, `label` 13/0.8 — preserve.

---

## 13. Antigravity Implementation Rules

Every future Antigravity task **must:**

1. Read `frontend/UI_DEVELOPMENT_MASTER.md` (this file).
2. Read relevant `frontend/design/*.md` docs.
3. Implement **exactly ONE** assigned VIS phase (e.g., `VIS-3` only).
4. Modify **only** assigned feature areas (see §5 + §7 phase scope).
5. Preserve architecture (see §3 + §4) — no rewrite.
6. Avoid backend changes (`backend/` is read-only).
7. Avoid inventing APIs — use existing repo methods only.
8. Avoid fake data — honest empty states (see §9).
9. Avoid destructive Git (see §6).
10. Reuse shared components (`shared/widgets/*`, `core/theme/*`) — no duplicates.
11. Run `flutter analyze` and report result.
12. Run `flutter test` and report result.
13. Run `flutter build web` and report result.
14. Report actual results (counts, errors, artifacts) — not "looks good".
15. Stop after the assigned phase — await human approval for next.

---

## 14. No Code Changes in This Run

Allowed changes in **this preparation run** were exactly:

- `frontend/UI_DEVELOPMENT_MASTER.md`
- `frontend/design/visual_design_system.md`
- `frontend/design/screen_inventory.md`
- `frontend/design/component_inventory.md`
- `frontend/design/animation_spec.md`

No Dart, Java, YAML, routing, provider, model, logic, or dependency was modified to produce this contract.

---

## 15. References

- `frontend/ui_upgrade_plan.md:1` — UI-0 audit (347 lines, dependency-correct phase order, 23 sections).
- `frontend/GAMELEARN_AI_FRONTEND_FUTURE_DEVELOPMENT_BLUEPRINT.md:1` + `GameLearn_AI_Frontend_Specification_UPDATED.md:1` — product specs (path, gamification, assessment, adaptive).
- `frontend/pubspec.yaml:1` — deps locked as above.
- `frontend/lib/app/router.dart:50` `Routes` + `lib/features/shell/shell_screen.dart:1` + `lib/core/theme/*` + `lib/shared/widgets/*` + `frontend/test/*` — ground truth cited per section.
