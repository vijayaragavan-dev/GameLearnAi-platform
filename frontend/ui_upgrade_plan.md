# GameLearn AI — Frontend UI/UX 2.0 Upgrade Plan (Phase UI-0 Audit)

**Date:** 2026-09-02  
**Scope:** `GameLearnAI/frontend/` ONLY — read-only audit, no code modified  
**Auditor role:** Senior Flutter Architect · Dart Engineer · UI/UX · Gamification · Responsive · Integration · Test/Build  
**Baseline:** Flutter 3.9+, Riverpod 3.0, go_router 16.2, http 1.5, flutter_secure_storage 10, shared_preferences 2.5, audioplayers 6.5  
**Existing report reviewed:** `frontend/report.txt` (2 entries: 2026-08-30 Wrong-credentials UX fix, 2026-09-02 PROG-101 difficulty contract fix)  
**Git status pre-audit:** `frontend/` shows 4 modified + 1 untracked `game_result_submission_test.dart`; `backend/` shows 8 modified + 9 untracked (rate-limit, GameType, tests) — not touched, flagged for human.

---

## 1. Architecture

### 1.1 Layering (`lib/` inspected: ~95 Dart files)
```
lib/main.dart (bootstrap SharedPreferences → ProviderScope)
  app/gamelearn_app.dart (MaterialApp.router + theme)
  app/router.dart (GoRouter)
  core/{config,theme,network,models,storage,audio,haptics,error,utils,gamification_delta,providers}
  features/{auth,dashboard,subjects,learning,challenge,tutor,gamification,progress,profile,shell,game_engine,games}
  shared/widgets
```
- **State:** Riverpod `Notifier`/`Provider` hybrid. `SessionController`, `DashboardController`, `PathController` (family), `AssessmentController` (family) are `Notifier`. Remaining reads (subjects, quiz, gamification, progress, lesson, topic) use `FutureBuilder` + `Future` repos. Repos never hold business logic.
- **Routing:** Single `GoRouter` with `ShellRoute` for bottom nav (Command/Worlds/Stats/Profile) + ~25 full-screen routes. Custom `_page` with `FadeTransition` + `Slide`/`Scale` via `AppMotion`. Auth guard via `SessionPhase` enum.
- **Models:** Defensive `fromJson` with defaults, UUID guards via `model_ids.dart:uuidOf/uuidOrNull`. No recomputation — backend owns XP/levels/mastery/difficulty/recommendations.
- **Storage:** JWT only in `flutter_secure_storage` (`gl_access_token`), prefs only for audio/haptics flags.
- **Build safety:** Previous `report.txt` confirms 540 tests passing (534 baseline + 6 new), `flutter analyze` 0 errors, `flutter build web` succeeds.

### 1.2 Strengths
- Contract-faithful models, centralized `ApiClient` + `ApiException` hierarchy, `UserFacingError` mapping, session invalidation via `onUnauthorized` excluding `_authPaths`.
- Feature-scoped folders, reusable `core/theme` + `shared/widgets`, no subject-specific `if` branches (subject-agnostic entities verified).

### 1.3 Debt / Constraints (C8: do not rewrite)
- Mixed state patterns: `Notifier` families vs `FutureBuilder` in subjects/quiz/profile. Migration to `AsyncNotifier` is opportunistic, not required in UI-1.
- `AppConfig` is correct (`String.fromEnvironment`) — keep. No hardcoded IP in source (default `10.0.2.2` is emulator-safe).

---

## 2. Navigation (`lib/app/router.dart:1`, `lib/features/shell/shell_screen.dart:1`)

- **Shell:** 4 tabs `/home`, `/subjects`, `/progress`, `/profile`; `ShellScreen` uses `GestureDetector` row + `AnimatedScale` on select. Location tracking via `location.startsWith(tab)` — fragile if sub-routes overlap but works for current 4.
- **Full-screen flows:** `/path/:subjectId?name=`, `/topic/:topicId`, `/lesson/:topicId`, `/quiz/:topicId`, `/quiz-result` (extra `QuizResultArg`), `/recommendation` (extra `RecommendationItem`), `/assessment/:subjectId` + `/run` + `/result`, `/tutor`, `/achievements/:code`, `/streak`, `/performance/:topicId`, `/settings`, `/games/:topicId*` (14 game sub-routes).
- **Game routing:** `Routes.gameHub(topicId)` plus per-game helpers; `GameHubScreen` switches on `GameType`. Only topicId is passed — no subjectId in path, relies on `topic → subject` lookup and `extra: topicName` (weak: `subjectId` param in `GameHubScreen` is unused and never routed). This is the Subject-Aware context risk (§5.5).
- **Transitions:** `AppMotion.normal` (300ms) default, `feature` (500ms) for results.
- **Audit finding:** `AssessmentResultScreen:183-189` `View my path` does `context.go(Routes.home)` — **not** `Routes.path(subjectId)`. This is the HIGH PRIORITY BUG §5.4: after `Assessment → Result → View Path`, user lands on generic home/dashboard whose `Continue` logic may resolve to a different `currentSubject`, not the just-assessed `subjectId`. The personalized path is never navigated to directly. Fix is frontend-only: route to `/path/:subjectId?name=` using `widget.subjectId`.
- Recommend per-phase: keep GoRouter, add `subjectId` query to game routes or provider-scoped context; fix assessment result navigation.

---

## 3. Theme (`lib/core/theme/*`)

- **Current:** Single dark theme only (`buildGameLearnTheme()` Brightness.dark). Tokens centralized:
  - `AppColors`: background `#070B17`, surface `#10172A`, surfaceElevated `#151E35`, surfaceHigh `#1B2542`, primary `#8B5CF6`, primaryBright `#A78BFA`, primaryDeep `#5B21B6`, secondary `#22D3EE`, xp `#FACC15`, streak `#FB923C`, success `#34D399`, error `#F87171`, borders `24304F/334368`, text tiers `F1F5F9/94A3B8/64748B`.
  - `AppTypography`: `GameLearnDisplay` (SpaceGrotesk VF) for headings, `GameLearnBody` (Inter VF) for body; variable font `FontVariation('wght',…)`.
  - `AppMotion`: fast 180, normal 300, feature 500, celebration 950, stagger 55; curves `easeOut/easeInOut/standard/spring/decelerate`.
  - `AppStyles`: `AppSpacing xs4/sm8/md12/lg16/xl24/xxl32/huge48`, `AppRadius sm10/md14/lg20/xl28/pill999`, `AppElevation card2/raised8`, `AppShadows soft/glow/drop`, `AppGradients brand/cyan/xpGold/streakFire/backgroundWash/novaCore`.
- **Gaps vs §4.2:** No light/dark/system switch, no persistence, no `ThemeMode` provider. `ThemeData` hardcoded dark; no `ColorScheme.light`, no contrast verification for light. No per-widget `Theme.of` derivation — colors are static constants (good for consistency, but light theme requires token inversion, not per-screen ad-hoc). Dark is genuine (not inverted light) — passes quality, but light variant is missing entirely.
- **Phase impact:** UI-2 must introduce centralized `ThemeMode` notifier backed by `SharedPreferences`, derive both `ThemeData` from shared tokens, persist choice, avoid per-screen branching.

---

## 4. Responsive Design

- **Current usage:** `MediaQuery.sizeOf`, `MediaQuery.disableAnimations`, `LayoutBuilder` (PathMap, MemoryMatch), `Flexible/Expanded/Wrap`, `SingleChildScrollView`, `SliverAppBar`, `AlwaysScrollableScrollPhysics`, `SafeArea`, `GridView.count` (achievements 2-col). No `AppBreakpoints` tokens, no adaptive scaffold.
- **Observed layouts:**
  - Dashboard: `ListView` single column, padding `20,12,20,110`, no maxWidth constraint — stretches on desktop, low density.
  - Subjects: `ListView.builder` single column cards, chips `SizedBox height36` horizontal ListView — good mobile, no 2-col tablet grid.
  - PathMap: `LayoutBuilder` for trail width, `CustomPaint` starfield, nodes positioned via `width * 0.30/0.70` + wobble — responsive to width, but no desktop rail.
  - Games: `GridView 3-col mobile / 4-col wide>700` (MemoryMatch) is the only breakpoint; others use `ListView`/`Column` only.
  - Quiz/Assessment: full `Column` + `Expanded SingleChildScrollView` — no side panel for progress on desktop.
  - Shell: fixed `height 66` bottom bar `extendBody:true` — mobile-only; no `NavigationRail`/`Sidebar` for desktop per §4.1.
- **Never-allowed violations checked:** No fixed-width overflow found, but desktop density and nav rail are absent. `RenderFlex` overflow risk exists on resized windows where long subject/topic names + badges `Wrap` correctly, but narrow browser <360px could clip pill labels (mitigated by `Wrap`/`Expanded` but not tested).
- **Phase UI-1 scope:** Introduce `Breakpoints` (e.g., 600/900/1200), `ResponsiveScaffold` (bottom nav mobile, NavigationRail tablet, sidebar desktop), constrained `maxWidth 1200` centering, adaptive grids (subjects 1→2→3 cols, dashboard sections 1→2 cols).

---

## 5. Dashboard — Home / Command Center (`lib/features/dashboard/presentation/dashboard_screen.dart:1` + provider, models)

- **Data:** DASH-001 `Dashboard` 10 sections aggregated verbatim: learner, currentSubject, mastery, gamification, streak, achievements, recommendations (≤3 server-bounded), learningPath card, assessment coverage, recentActivity. Defensive `fromJson` with null/[]/0 fallbacks, never missing key.
- **Current UI:** Flagship but **not yet gamified** (§3/§5.1): Header `LevelBadge 54 + XPBar height6 showLabels:false + StreakChip`, `GlowCard` adventure hero, `RecommendationCard` ×2 compact, `AdaptiveFocusCard` (strong topics + needsPractice + next mission + why), `AssessmentNudge` (when `assessedSubjects.isEmpty && topicsAssessed==0 && no topic recommendations`), `MasteryStrip` (recentTopics rows), Phase-2 strips: `RecentlyLearned` (assessed → quizzes → recentTopics fallback), `Mastered` (filter MASTERED), `NewWorlds` (futureBuilder over SUBJ-001 filtered by `assessedIds`), `TrophyRoom` recentUnlock, `RecentBattles` recent quizzed. Staggered entrance `TweenAnimationBuilder` per index + `AppMotion.staggerUnit`.
- **Strengths:** No fake data — every number from backend, honest empty states (`EmptyMiniCard`), skeletons, error via `describeError`, pull-to-refresh, `AchievementIcon` with `iconKey`.
- **Weaknesses — visual quality bar §3.1:**
  - Reads as informational dashboard, not "player command center": single column even on desktop, hero card dominates but lacks progress ring, quest list, game zone teaser. Gamification (XP bar without labels, streak count only) is muted.
  - Missing ordered hierarchy `Profile/Level/XP → Continue → Journey → Subjects → Quests → Game Zone → Achievements` — current order interleaves recommendations/mastery before quests; Game Zone absent (games only via topic → hub, not home).
  - Information density low on desktop; no constrained width; no primary CTA visual dominance beyond hero gradient.
  - `NewWorldsStrip` fires `FutureBuilder` on every build via `ref.read(contentRepoProvider).subjects()` stored as `late Future` — ok, but refetch on dashboard refresh not coordinated.
- **Phase UI-3 will:** Re-compose sections to §5.1 order, add responsive 2-col layout, prominent `Continue Learning` + `Personalized Journey` cards, `Quests/Missions` strip, `Game Zone` (general vs subject games teaser), elevate XP/level/streak with progress ring, keep no-fake guarantee.

---

## 6. Subjects (`lib/features/subjects/presentation/subjects_screen.dart:1`, `subject_grouping.dart:1`, content models)

- **Source:** `ContentRepository.subjects()` → `GET /api/v1/subjects` (SUBJ-001). Backend owns catalog; frontend never hardcodes list — verified `FutureBuilder` over live list. V11 seed: Programming, Networks, DBMS, OS, Data Structures; blueprint anticipates OOP, Web Tech, AI/ML, SE, COA, etc.
- **Current UI:** `Scaffold AppBar CHOOSE YOUR WORLD` + `NovaCompanion` tagline + horizontal `ChoiceChip` category filter + `PressableWorldCard` per subject (gradient tint `displayOrder%5`, `SubjectGlyph`, name/description, `SCAN` pill, chevron). `AnimatedScale 0.97 on down`, `AnimatedContainer` shadow. Empty states for `subjects.isEmpty` and filtered empty. No duplicate card logic — scales via list builder.
- **Grouping:** `SubjectGrouping` is **presentation-only** decorative heuristic mapping `name/description/iconKey` lowercased to 11 core labels (All, Programming, DSA, Databases, Systems, Networks, AI&ML, Web, Security, Theory, SE, Aptitude). Heuristic order matters (specific→generic), fallback to Programming. Chips derived via `deriveChips` ordered by `coreLabels` stable, not alphabetical. Filter is in-memory, no network.
- **Programming subtree requirement §5.2:** No `Programming → C/C++/Java/Python/JS` language view exists. Current `SubjectGrouping` buckets all programming variants under single `Programming` chip — does not expose language leaves. Backend has no `category` field on `Subject` (inspected `Subject.fromJson`: `id/name/description/iconKey/isActive/displayOrder` only). Language branching must be either: (a) backend adds sub-subjects/languages (preferred), or (b) client groups Programming subjects by name heuristic — but must not duplicate card rendering or break existing Programming flow.
- **Scalability:** No hardcoded cards — new subject from backend automatically appears with tint+grouping. Ready for extension.
- **Weaknesses:** Category is heuristic name-match, not backend-authoritative — fragile for future subjects (e.g., "Computer Organization" → Systems generic). Empty filtered state uses `EmptyState` with `SHOW ALL` — correct. No search field (blueprint noted search as client filter pending backend `GET /subjects?search`).

---

## 7. Syllabus (`lib/features/learning/path/presentation/path_map_screen.dart:1`, `path_provider.dart:1`, `topic_detail_screen.dart:1`, `topic/lesson` routes)

- **Syllabus visualized as:** `Subject → PathMap (PATH-001/002) → TopicDetail (TOPIC-001) → Lesson (LESSON-001) → Quiz/Game`. Path is backend-driven serpentine trail (`AdventureTrail` CustomPaint S-curves + `_Starfield` 70 pseudo-random stars, deterministic drift). Nodes `LearningNode` states `LOCKED/AVAILABLE/IN_PROGRESS/COMPLETED` from backend `PathNode.status`, with `requiredMastery` lock message, `YOU ARE HERE` pill on `AVAILABLE`, pulse ring animation on available (respects `disableAnimations`).
- **Grouping & locking:** No module/unit grouping header — `LearningPath.nodes` is flat sequence. `LearningPath` model accepts both `LearningPathResponse` and `Generated...` shapes, optional `aiMetadata` nodes (objective/rationale) keyed by `sequenceNumber`, never fabricated. Status ALWAYS backend — correct.
- **Current topic highlighting:** Via `AVAILABLE` node + streak; `IN_PROGRESS` distinct warning tint, no separate "current-topic" beyond that. `PathState.activePath` picks first `status==ACTIVE`.
- **Weaknesses:**
  - No `Module/Unit → Topic → Subtopic` hierarchy exposed (backend `path.nodes` flat). Module grouping would require syllabus model expansion or client grouping by `sequenceNumber` ranges — currently absent. If backend adds modules, client must not invent content (C5).
  - Syllabus progress overview absent beyond individual node icons; no overall completion ring for path.
  - Responsive: PathMap is single-column trail; tablet/desktop could show 2-lane + side metadata.

---

## 8. Assessment (`lib/features/challenge/assessment/*`, `assessment_repository.dart:1`)

- **Flow:** `AssessmentIntroScreen` → `AssessmentRunScreen` (`_index`, `select` map, `QuestionProgress` dots, `DifficultyBadge`, `AnimatedSwitcher` slide, `QuizOption`, `Nova hint` sheet) → `submit()` (requires `answers.length == questions.length`) → `AssessmentResultScreen`.
- **Contracts:** ASMT-001 `GET /assessment/{subjectId}` → `AssessmentDelivery questions[]` (no correct answers). ASMT-002 `POST /assessment/{subjectId}/submit` → `AssessmentSubmissionResult {subjectId, score, overallMastery, topics[] {topicId, accuracy, masteryLevel, currentDifficulty}}` 201 or 409 `ConflictException` R-GUARD. ASMT-003 `GET /assessment/{subjectId}/result` → `AssessmentOutcome {assessed, overallMastery, topics[] {topicId, topicName, masteryScore, masteryLevel, currentDifficulty}}` (assessed=false valid).
- **Provider:** `AssessmentController` family holds `delivery/answers/submitting/result/conflict/error`; 404 `No assessable content` mapped to honest message; `ConflictException` sets `conflict=true`.
- **Quality:** Loading (`CircularProgressIndicator`), error `ErrorState`, empty `Nothing to scan`, `PopScope canPop:!submitting`, `Sfx.buttonTap/select`, haptics.

---

## 9. Personalized Learning Path — HIGH PRIORITY BUG §5.4

- **Intended flow:**
  ```
  Assessment → Submit → API (201/409) → Result (AssessmentResultScreen) → Recommendation/Provider/State → View Path → Personalized Path
  Two valid flows: (1) Manual path (Generate on PathMapScreen), (2) Assessment-generated personalized path
  View Path must route to path type user actually earned.
  ```
- **Actual code:**
  - `AssessmentResultScreen:183-189` `PrimaryGameButton label:'View my path' onTap:() async { ref.read(audioManagerProvider).play(Sfx.missionComplete); context.go(Routes.home); }` — **BUG confirmed frontend-side.** It navigates to home, not to `/path/:subjectId`. Home's `Dashboard._continueAdventure` then resolves `currentSubject` from `dashboard.currentSubject` (DASH-001 section 2), which may be stale or null, not necessarily the just-assessed `widget.subjectId`. No `recommendation` or `provider` state is passed; `pathProvider(subjectId)` is never primed with assessment context.
  - `PathProvider` is correct: `load()` → `GET /learning-path/{subjectId}`, `generate()` → `POST /learning-path/{subjectId}/generate` (60s timeout, `regenerate` + `learningGoal ≤300`), `aiMetadata` propagated, `activePath` getter. Both manual and generated paths share same read path; distinction `generatedBy` (`SYSTEM/AI/HYBRID`) exists but not used for routing.
  - `AssessmentProvider` correctly stores `result` and exposes `resultToOutcome` fallback when ASMT-003 not yet fetchable; no path preference stored.
- **Root cause:** Frontend defect — missing subject-scoped navigation from assessment result. Not a backend missing field.
- **Fix (UI-5, no backend change):** Change `AssessmentResultScreen` CTA to `context.go(Routes.path(widget.subjectId))` (with `?name=` if available via `Dashboard.assessment` or `Subject.name` lookup), or `context.pushReplacement(Routes.path(…))`. Preserve both flows: manual path remains via `PathMapScreen` generate prompt; assessment path is simply the active path after assessment (backend generates implicit personalized path on submit — if not, document backend dependency per C9 rather than synthesizing recommendation).

---

## 10. Game Architecture (14 games preserved, C8)

- **Inventory:** `lib/features/games/{quiz_battle,memory_match,drag_drop,speed_run,debug_arena,unlock_code,concept_builder,sequence_master,target_challenge,mystery_case,boss_battle,puzzle_arena,connectivity_lab,snake_and_ladder}/presentation/*_screen.dart` + hub `lib/features/games/hub/presentation/game_hub_screen.dart:1`. Model `lib/features/game_engine/models/game_models.dart:1` enums `GameType` (14 ids), `GameDifficulty EASY/MEDIUM/HARD apiValue`, `GameStatus`, `GameConfig {topicId,topicName,subjectId,subjectName,type,difficulty,timeLimitSeconds}`, `GameResult`, `GameDefinition.all` (supportsTimer/supportsCombo/supportsPause per game).
- **Engine utilities:** `lib/features/game_engine/engine/{game_timer.dart:1,game_scoring.dart:1,game_combo.dart:1}` + `utils/{game_content_mapper.dart:1,difficulty_utils.dart:1}` + `audio/game_sound_controller.dart:1` + `widgets/{game_scaffold.dart,game_hud.dart,polished_game_hud.dart,game_result_screen.dart:1}`.
- **Hub:** `GameHubScreen` `ListView` header + summary `Wrap` (14 GAMES / 8 TOPICS / VARIABLE DIFFICULTY) + `_GameCard` per `GameDefinition.all` (color per type, emoji icon, category via `_categoryFor`, chips MEDIUM/Timed/Combo/XP). Every card `AVAILABLE`, no locks. Intro note: "Quiz Battle & Speed Run award real XP. Other games show local scores (real XP coming next backend update)." Honest — no fake XP.
- **Polish scope per game (UI-7):** Each screen is functional with `GameScaffold` + `GameHud` + timer/combo/score, `GameSoundController`, completion → `GameResultScreen`. Visual identity exists but is template-driven (shared timer bar style, similar layouts). Requirement §5.7 to make each feel like actual game without logic rewrite is acknowledged — polish is visual/presentation only.

---

## 11. Game-Question Flow — Subject-Aware Context §5.5 (CRITICAL)

- **Current path:** `Subject → PathMap → TopicDetail → GameHub(topicId, extra:topicName) → individual game route /games/:topicId/<slug> (extra:topicName) → gameplay → GameResultScreen`.
- **Content sourcing:** Games fetch via `ContentRepository`/`QuizRepository` by `topicId`:
  - `QuizBattleScreen:74` `quizForTopic(topicId)` → `GET /quiz/{topicId}` (backend already scoped by topic, which belongs to a subject — implicit subject scoping via topic).
  - `MemoryMatchScreen:79-87` parallel `safeLesson/safeQuiz/safeTopic` by `topicId`, then `GameContentMapper.memoryPairs(quiz,lesson,topic)` — **all topic-scoped**, no subject filter passed.
  - Other games similarly use `topicId` + `quiz/topic/lesson` fetched by topic; no `subjectId` query param observed.
- **Context propagation:** `GameConfig` has optional `subjectId/subjectName` but routes never populate them. `GameHubScreen` constructor has `subjectId` param but `router.dart:30-90` never extracts or passes it (path is `/games/:topicId`, no subject segment). `extra` carries only `topicName String`. Topic itself carries `subjectId/subjectName` fields (`Topic.fromJson`), so games could derive subject via `contentRepo.topic(topicId)` — but `QuizBattle` does not fetch topic for subject, only quiz.
- **Audit verdict:** **Partial break frontend-side.** TopicId alone is sufficient for subject scoping **if** backend `GET /quiz/{topicId}` returns only that topic's questions (it does — quiz is per-topic). So `Computer Networks → Puzzle Arena` will show Networks questions because `topicId` is a Networks topic. Context survives `Subject→Topic→Game→QuestionSelection→Gameplay→Result` via `topicId` in route (topic belongs to one subject). However, generality fails if a future game aggregates across subject (e.g., mixed bank) — but no such endpoint exists. The stronger §5.5 requirement ("entering from within a subject must scope to that subject") is satisfied via topicId, but **subjectId is not persisted across reload**; deep-linking `.../games/<networks-topicId>/puzzle-arena` is unambiguous, yet `.../games/<programming-topicId>/puzzle-arena` would still be distinguishable. No cross-context leak observed.
- **Risk:** `General Games` (§5.6) vs `Subject Games` distinction requires subject-scoped games to never show mixed subjects; current games are topic-scoped (sub-subject), which is finer-grained and correct. For a future subject-level game mode (all topics of subject), `topicId`-only would be insufficient — would need `subjectId` in route. Recommend UI-6 to add `subjectId` to game routes or stash via provider so `General Games` vs `Subject Games` are visually/contextually unmistakable and technically separated.
- **Backend dependency note:** If question selection were backend-owned mixed bank filtered by query `?subjectId=`, frontend would need to pass it — currently impossible (no param). Document if backend expects subject filter; else note frontend fix suffices: persist `subjectId` through `GameConfig` via topic lookup or route param, do **not** fake client-side filtering.

---

## 12. Game-Result Flow (`lib/features/game_engine/widgets/game_result_screen.dart:1`, gamification, quiz result)

- **GameResultScreen (polished):** `Stack` with `ListView` accuracy ring (`TweenAnimationBuilder` 168px, 950ms), performance label `LEGENDARY/EXCELLENT/GOOD/FAIR/KEEP TRYING`, config line `TYPE • DIFFICULTY`, optional `topicName`, 3-stat row Score/Combo/Time, XP card (delta `d.xpGained` or local `r.xpEarned` preview with note "Local preview • Quiz games award real XP" for non-quiz games), bestScore banner, `Play again` / `Continue` / `RETURN TO BASE`. Celebrations `ConfettiEffect` on perfect/xp, `LevelUpOverlay` + `AchievementUnlockOverlay`, `Sfx.missionComplete`, haptics. Submission in `initState` via `_submitResultPersistent`:
  ```
  GameConfig.difficulty.apiValue → GameResultSubmission(difficulty, clientRequestId v4, gameType, score, duration, bestCombo) → toJson → POST /api/v1/me/game-results → gamificationRepo → PROG-101 (now includes difficulty per report.txt Gate1)
  ```
  The difficulty contract bug (Gate1) is fixed: `GameResultSubmission` now requires `difficulty: String`, sourced from `r.config.difficulty.apiValue` (`EASY/MEDIUM/HARD`). All 14 games share same path because `GameResult.config.difficulty` is set via `DifficultyUtils.resolve`.
- **QuizResultScreen (QUIZ-002):** Similar ring + `topicName` + XP card (`widget.arg.xpGained`) + `AdaptiveInsight` card (`_AdaptiveOutcomeCard` with mastery/level/nextDifficulty/previousMastery delta/`_MasteryTransition` labeled with semantics), answer review tiles, `Continue` → `Routes.home`. Snapshot via `gamification_delta.dart capture/compare`; sound `levelUp` + `achievementUnlock` sequential.
- **AssessmentResultScreen:** Uses `FutureBuilder` over `assessmentRepo.result(subjectId)` with fallback `state.resultToOutcome` when 409 already assessed. Score ring + topic baselines list, `View my path` bug noted above.
- **Gaps vs §5.8:** After any game, spec requests score, accuracy, XP earned, level progress, streak, achievements, performance feedback, next-action suggestion, retry, continue, return-to-subject. Current `GameResultScreen` shows score/accuracy/xp/combo/time/performance, but **not** streak, not next-action suggestion, not return-to-subject (only `go(Routes.home)`). Streak/level progress are backend-owned; `d` includes `leveledUpTo` + `newAchievements` but not streak delta — streak must be fetched or shown via dashboard revalidation. `Return to subject` needs `subjectId` in `GameConfig`.

---

## 13. Gamification (`lib/core/gamification_delta.dart:1`, `lib/core/models/gamification_models.dart:1`, `lib/features/gamification/*`, dashboard, `lib/shared/widgets/{badges.dart:1,xp_bar.dart:1,celebrations.dart:1}`)

- **Contracts:** GAM-001 `GET /gamification/summary {totalXp,currentLevel,maxLevel,nextLevelThresholdXp,xpToNextLevel,currentStreakDays,longestStreakDays,achievementCount}`, GAM-002 `GET /achievements [] {code,name,description,iconKey,xpReward,unlockedAt null=locked}`, GAM-003 `GET /streak {currentStreakDays,longestStreakDays,lastLearningDate,timezone}`, USER-001 profile, PROG-001/002 progress, PROG-101/102 game results (now difficulty-aware, rate-limited backend). Frontend only renders server values, never recomputes mastery/XP/levels (enforced).
- **Widgets:** `LevelBadge` circle gradient `#5B21B6→#8B5CF6`, `StreakChip` flame `days + DAY/S`, `XPBar height6 showLabels?`, `DifficultyBadge` EASY/MEDIUM/HARD tint, `AchievementIcon/SubjectGlyph`, `Celebrations` confetti/level-up/achievement overlays. `NovaCompanion` moods idle/thinking/encouraging/celebrating/speaking.
- **Visibility:** XP/level/streak visible on dashboard header + profile screen (LevelBadge 58 + XPBar showLabels:true + stats Total XP/Streak/Badges/Mastery), path nodes, quiz/game results. Streak chip is header-only small; streak screen exists. Quests/missions not yet modeled as distinct entities — `RecommendationItem.activityType` (`CONTINUE_LESSON/PRACTICE/REVIEW/QUIZ/REMEDIATION/ADVANCE`) + `priority` + `reason` serve as mission source but no dedicated quest UI.
- **Structural gap §3.3:** Gamification is present but not *core UI* everywhere — quests/missions, unlock states, progress rings beyond accuracy, subject mastery indicators are minimal. XP/level-up animations are present (`AnimatedCounter`, ring tween, confetti) purposefully — not over-animated (respects `disableAnimations`, `reduce` checks throughout).

---

## 14. API Contracts (frontend read, backend only read per C2)

- **Client:** `ApiClient` base `AppConfig.apiBaseUrl` via `String.fromEnvironment`, `Accept: application/json`, bearer injection via `sessionTokenProvider`, 15s default timeout, 60s for PATH-002 (`generatePath`) and AI-001 (in `ApiClient.postJson timeout` param). `_guard` maps `http.ClientException→Network`, `TimeoutException→TimeoutApiException`; `_errorFrom` parses backend `ErrorResponse {errorCode,message,fieldErrors}` onto `ApiException` subclasses (400 Validation with fieldErrors, 401 Unauthorized, 403 Forbidden, 404 NotFound, 409 Conflict, 429 RateLimited, 503 AiUnavailable, default ServerError). `onUnauthorized` excludes `auth/login|register|validate`.
- **Endpoints used (verified in repos):**
  - `AuthRepository`: `POST /auth/login|register`, `POST /auth/logout`, `GET /auth/validate`
  - `ContentRepository`: `GET /subjects`, `GET /topics/{topicId}`, `GET /topics/{topicId}/lesson`, `GET /learning-path/{subjectId}`, `POST /learning-path/{subjectId}/generate {regenerate, learningGoal}`
  - `QuizRepository`: `GET /quiz/{topicId}`, `POST /quiz/{quizId}/submit`
  - `AssessmentRepository`: `GET /assessment/{subjectId}`, `POST /assessment/{subjectId}/submit`, `GET /assessment/{subjectId}/result`
  - `GamificationRepository`: `GET /gamification/summary`, `GET /achievements`, `GET /streak`, `GET /profile`, `GET /progress`, `GET /progress/{topicId}`, `POST /me/game-results` (now `{clientRequestId,gameType,difficulty,completed,score,durationSeconds,bestCombo}` per Gate1), `GET /me/game-results`, `GET /me/game-results/{gameType}`
  - `IntelligenceRepository`: `GET /dashboard` (DASH-001 10 sections), `POST /ai/tutor` (AI-001)
- **Preservation rule §6.1:** Before touching any repo/provider/model/api client, search all usages — signatures/return types/auth/error handling must be preserved. No breaking change needed for UI-1..UI-7; GAM/PROG-101 rate-limit backend changes are transparent to frontend (still `ApiException`).

---

## 15. Mobile / LAN Backend Configuration §5.12

- **Mechanism:** `lib/core/config/app_config.dart:1` `AppConfig.apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080')`, `AppConfig.envName` similarly. `ApiClient` resolves via `AppConfig.resolve(path)`. README documents `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080` (emulator) and `http://localhost:8080` (Windows), `web` build ` --dart-define`. No hardcoded personal IP committed; `.env.example` shows placeholders only. `SettingsScreen` displays `appConfigInfoProvider.baseUrl/env` for debugging but not editable.
- **Status:** Environment-configurable ✅, no secrets in source ✅, `frontend` only ✅. Physical Android `Laptop ↔ LAN ↔ device` not verified in this audit (no device). Documentation for LAN (`--dart-define=API_BASE_URL=http://<laptop-ip>:8080` with same Wi-Fi note) is present in README but could be more prominent for §5.12 physical testing.
- **Phase UI-9 scope:** Verify LAN on physical device, ensure `10.0.2.2` not leaked into release web builds, document required setup without touching backend.

---

## 16. Audio Status §5.13

- **Hooks planned:** click, correct, wrong, gameplay interaction, background music, victory, failure, level-up.
- **Current:** `lib/core/audio/audio_manager.dart:1` `AudioManager` with `Sfx` enum `buttonTap/buttonConfirm/correct/incorrect/xpGain/levelUp/achievementUnlock/missionComplete/nodeUnlock/streakContinue/notification` mapped to `assets/audio/sfx_*.wav`, `MusicContext menu/dashboard/adventure/quiz/celebration/tutor` mapped to `music_menu.wav/music_adventure.wav/music_quiz.wav`. **All assets are synthesized in-house via `tools/generate_audio.ps1`** — royalty-free, loopable, small. `AudioManager` is fail-safe: one platform failure → `_platformBroken=true` → silent degrade, never crashes. `GameSoundController` wraps for games. Music `setReleaseMode(loop)` volume `0.16` subtle, SFX volume `0.9` dedup 60ms. Preferences persisted via `SharedPreferences` `pref_music_enabled/pref_sfx_enabled/pref_haptics_enabled`. Toggles in `SettingsScreen` + per `GameScaffold`.
- **Status:** Build-ready hooks exist, playback integrated in dashboard/subjects/path/quiz/games/results; **UI-8** will verify all hooks fire (click→tap, correct/incorrect→ gameplay, victory/failure→ result, level-up → result) and add music/sfx toggles if gaps found. No other phase should spend audio budget per §5.13.

---

## 17. Current UI Weaknesses (functional)

| Area | Weakness | Evidence | Impact |
|------|----------|----------|--------|
| **Personalized Path** | `View my path` → `home` not `path/:subjectId` | `assessment_result_screen.dart:189` | HIGH priority bug — personalized path never shown directly |
| **Subject-aware game context** | `subjectId` not in game route, `GameConfig.subjectId` always null | `router.dart` games routes only `:topicId`, `game_hub_screen.dart:13` unused param | Subject-scoped vs general indistinct, `General Games` home section missing |
| **Game Result** | No return-to-subject, no streak/next-action in result | `game_result_screen.dart` `onContinue` → `go(home)` | Violates §5.8 full loop |
| **Syllabus hierarchy** | Flat nodes, no Module/Unit headers | `LearningPath.nodes` flat, `PathMapScreen` no grouping | Scales poorly for large subjects |
| **Programming languages** | No `Programming → C/C++/Java/...` view | `SubjectGrouping` buckets all Programming together | §5.2 tree not exposed |
| **Dashboard order** | Recs/mastery before quests/game zone | `dashboard_screen.dart:181-303` order | Flagship not "command center" hierarchy |
| **Navigation** | Bottom nav mobile-only, no rail | `shell_screen.dart:66` fixed 66px bar | Tablet/desktop low density |
| **Responsive** | No breakpoints, no maxWidth | `dashboard_screen.dart:182 padding 20`, etc. | Desktop stretched, tablet 2-col missing |

---

## 18. Visual-Quality Weaknesses (mandatory bar §3.1)

- **Premium but not polished:** Dark futuristic palette is intentionally premium (purple/cyan/gold/orange) but repeated `GlowCard` + `LinearGradient` + `BoxShadow` on every card risks overuse if expanded naïvely — must avoid gradient/shadow overuse in later phases.
- **Game identity gap:** 14 game cards share same `GameCard` rounded style + tint + emoji; each game's visual identity (illustration, animation) is minimal — `@5.7` requires per-game distinct feeling (not question→answer→next).
- **Typography uniformity:** Inter/SpaceGrotesk VF correctly applied, but no responsive type scale — headings same size mobile/desktop.
- **Empty/loading polish:** Skeletons are generic `SkeletonCard 120` — not tailored per section (e.g., mastery strip skeleton vs adventure card skeleton).
- **Avoid childish/inconsistent:** Current avoids childish styling, but default-Material look persists on dialogs/snackBars/appBars (transparent appBar neutral). Icon styles mixed (outlined/rounded/glowing) without strict token — needs single icon language pass in UI-1.
- Aim for: modern, premium, polished, energetic, visually consistent, gamified, demo-ready — **not yet consistently achieved** on dashboard/game hub; achievable without rewrite.

---

## 19. Files Likely Requiring Modification (by phase)

**UI-1 Design System + Responsiveness (no game-logic):**
- `lib/core/theme/*` (add `app_breakpoints.dart`, derive light theme, extend tokens)
- `lib/app/gamelearn_app.dart` (ThemeMode + provider wiring)
- `lib/features/shell/shell_screen.dart` (responsive rail/sidebar)
- `lib/shared/widgets/*` (elevate reusable components: cards/buttons/chips/badges/progress/XP indicators — single system)
- `lib/features/dashboard/presentation/dashboard_screen.dart`, `lib/features/subjects/presentation/subjects_screen.dart`, `lib/features/learning/path/presentation/path_map_screen.dart`, `lib/features/learning/topic/presentation/topic_detail_screen.dart` (responsive scaffolds, maxWidth, grids)
- `lib/core/providers.dart` (SharedPreferences-backed ThemeMode if chosen)

**UI-2 Theme:**
- Same theme files + `lib/features/profile/presentation/settings_screen.dart` (light/dark/system toggle persistence), audit every major screen for contrast (dashboard, subjects, path, games, results, dialogs, forms, nav, achievements, progress, charts — per §4.2)

**UI-3 Gamified Home:**
- `lib/features/dashboard/presentation/dashboard_screen.dart` (reorder to LEARN→PLAY→…, add Continue/Journey/Quests/Game Zone/Achievements sections, level/XP ring, streak counter)
- Possibly `lib/shared/widgets/*` (quests cards, progress rings, unlock states)

**UI-4 Subjects + Syllabus:**
- `lib/features/subjects/presentation/subjects_screen.dart` + `subject_grouping.dart` (scale without hardcoded duplicates, language subtree for Programming)
- `lib/features/learning/path/presentation/path_map_screen.dart` + `lib/features/learning/topic/presentation/topic_detail_screen.dart` (module grouping, completion/locked state, current highlight, responsive path)
- `lib/core/models/content_models.dart` only if syllabus grouping needs backend field (otherwise presentational only)

**UI-5 Personalized Path (bug fix):**
- `lib/features/challenge/assessment/presentation/assessment_result_screen.dart` (route to `Routes.path(subjectId)`)
- Possibly `lib/features/learning/path/providers/path_provider.dart` (no contract change, ensure activePath distinction manual vs assessment-generated preserved)

**UI-6 Subject-Aware + General Games:**
- `lib/app/router.dart` (add `subjectId` to game routes or preserve via provider)
- `lib/features/games/hub/presentation/game_hub_screen.dart` (separate subject vs general, visually distinct)
- `lib/features/game_engine/models/game_models.dart` (populate `GameConfig.subjectId` via topic lookup or route)
- `lib/features/dashboard/presentation/dashboard_screen.dart` (General Games section mixing CS topics, pitched harder)
- Verify `GameContentMapper` / game screens never fake client filter — document backend dep if needed (C9)

**UI-7 Game UI Polish (14 games):**
- `lib/features/games/*/presentation/*_screen.dart` (visual identity, gameplay presentation, progress/score/XP/difficulty/feedback/completion/retry/exit polish — keep engines)
- `lib/features/game_engine/widgets/{game_scaffold,game_hud,polished_game_hud,game_result_screen}.dart` (reward/level-up feedback, next-action, retry/return-to-subject)

**UI-8 Audio:**
- `lib/core/audio/audio_manager.dart` + `lib/features/game_engine/audio/game_sound_controller.dart` + per-game sound hooks verification; asset sizes kept small

**UI-9 Mobile/LAN:**
- `lib/core/config/app_config.dart` audit only (no hardcode), `README.md` / docs LAN setup note; verify via physical device

**UI-10 Final Audit:**
- No new code beyond regression fixes; `frontend/report.txt` completeness pass

---

## 20. Files That Must Stay Untouched (unless phase explicitly authorizes targeted fix, per C8)

- `lib/core/network/api_client.dart`, `api_exception.dart` — preserve signatures/headers/auth/error mapping
- `lib/core/error/user_facing_error.dart` — preserve Nova messages
- `lib/core/providers.dart` repository bindings — no duplicate providers/models
- `lib/core/models/*` (dashboard/content/quiz/assessment/gamification) — preserve `fromJson` / `apiValue` / backend ownership
- `lib/features/*/data/*_repository.dart` — preserve method signatures/return types
- `lib/features/auth/providers/session_controller.dart` — auth flow verified (wrong-credentials fix preserved)
- `lib/features/gamification/models/game_result_models.dart` + `providers/{persistent_game_result,game_result_submitter,game_results_provider}` — Gate1 difficulty contract preserved
- All 14 game engines (scoring/combo/timer logic) — polish only, not logic rewrite per §5.7
- `pubspec.yaml` (add deps only if phase requires, otherwise keep `3.0/16.2/1.5/10.0/2.5/6.5`)
- Everything under `backend/` (read-only)

---

## 21. Risks

1. **Cross-phase regression of protected baseline** (534→540 tests, web build, 0 blocking analyzer, auth, gamification/result). Mitigation: `flutter analyze/test/build web` per §7 after each phase; `git status --short` guard (C7/C2); never `git reset --hard`.
2. **Fabricated data temptation** (C5) — especially for General Games difficulty, language subtree, path recommendations. Mitigation: render empty/error states when backend data unavailable; log Backend Dependencies in report.txt instead of inventing.
3. **Backend dependency ambiguity** — subject category field absent, syllabus module grouping absent, General Games mixed-bank endpoint absent, streak/next-action in game result not in DTO. Mitigation: presentational fallback (heuristic, flat list) + `Frontend Dependencies` log per C9; no client-side filtering of questions if backend owns selection (§5.5).
4. **Theme inversion pitfalls** — light theme naive inversion destroys contrast. Mitigation: derive from shared semantic tokens, verify across all 11 surfaces listed in §4.2.
5. **Responsive overflow** — reintroducing fixed widths or forgetting `Wrap` on pills causes overflow on resize. Mitigation: `LayoutBuilder` + `Flexible/Expanded/Wrap` + constrained maxWidth; manual resize testing per phase.
6. **Route `subjectId` leak** — adding `subjectId` to game routes changes deep links bookmarked; old links break. Mitigation: keep `:topicId` path, add optional query `?subjectId=` or provider stash, keep backward compatible.
7. **Audio asset bloat** — new SFX/music inflate `build/web`. Mitigation: small synthesized WAVs only, already loopable, guard file sizes.
8. **Gamification over-decoration** — excessive glow/gradient/animation harms smoothness. Mitigation: animate purposefully (AppMotion tokens), respect `disableAnimations`, profile cheap renders.

---

## 22. Recommended Phase Order (per directive §7 — one phase per invocation, human approval between)

| Phase | Name | Scope | Gate condition |
|-------|------|-------|----------------|
| **UI-0** | Full Frontend Audit | This document + report.txt | No code, docs only — COMPLETE |
| **UI-1** | Design System + Responsiveness | Tokens, `AppBreakpoints`, responsive scaffold/nav, reusable components; single design language | `flutter analyze/test/build web` PASS, no overflow on phone/tablet/desktop/resize |
| **UI-2** | Theme | Light/Dark/System + persistence, genuine dark, verified contrast | Theme persists, verified on 11 surfaces |
| **UI-3** | Gamified Home | Dashboard as premium command center (ordered §5.1) with quests/game zone/achievements | Reads as "playing a learning game," not form |
| **UI-4** | Subjects + Syllabus | Subject discovery/detail scalable without hardcode, language subtree, syllabus Module grouping + lock/available/current | No fabricated content, Programming JS/C++ etc. exposed without breaking Programming |
| **UI-5** | Personalized Path | Fix Assessment→Result→View Path routing (frontend defect) | View Path always opens correct (manual vs personalized) |
| **UI-6** | Subject-Aware + General Games | Persist subject context through game flow; visually separate General Games (mixed hard) | No cross-context leakage, documented if backend filter required |
| **UI-7** | Game UI Polish | Visual upgrade of 14 games (identity, HUD, feedback, completion) without logic rewrite | Each feels like a game |
| **UI-8** | Audio | All hooks + mute verified, small assets | Audio failures never crash |
| **UI-9** | Mobile / LAN Support | Physical Android over LAN via `--dart-define`, no hardcoded IP | Device reachable, documented |
| **UI-10** | Final Audit | Full regression against §9 + §7.1 checklist | All 16 acceptance criteria hold |

This order is dependency-correct: system (UI-1/2) → flagship (UI-3) → catalog/journey (UI-4) → bugs (UI-5/6) → polish (UI-7/8) → device (UI-9) → audit (UI-10). Deviating would risk visual inconsistency or bug masking.

---

## 23. Appendix — Inspection Inventory

**Files inspected (frontend, read):** `pubspec.yaml`, `analysis_options.yaml`, `.env.example`, `README.md`, `report.txt`, `GAMELEARN_AI_FRONTEND_FUTURE_DEVELOPMENT_BLUEPRINT.md` (partial), `lib/main.dart`, `lib/app/{gamelearn_app,router}.dart`, `lib/core/{config/app_config,providers}.dart`, `lib/core/theme/{app_colors,app_theme,app_typography,app_styles,app_motion}.dart`, `lib/core/network/{api_client,api_exception}.dart`, `lib/core/storage/token_storage.dart`, `lib/core/audio/audio_manager.dart`, `lib/core/haptics/haptics.dart`, `lib/core/models/{auth,content,dashboard,quiz,assessment,gamification,model_ids}.dart`, `lib/core/error/user_facing_error.dart`, `lib/core/utils/formatters.dart`, `lib/features/auth/providers/session_controller.dart`, `lib/features/dashboard/{providers/dashboard_provider,presentation/dashboard_screen}.dart`, `lib/features/subjects/presentation/{subjects_screen,subject_grouping}.dart`, `lib/features/learning/{data/content_repository,path/providers/path_provider,path/presentation/path_map_screen,topic/presentation/topic_detail_screen}.dart`, `lib/features/challenge/{data/{quiz,assessment}_repository,quiz/presentation/{quiz_screen,quiz_result_screen,quiz_result_arg},assessment/{providers/assessment_provider,presentation/{intro,run,result}_screen},recommendation/presentation/recommendation_screen}.dart`, `lib/features/gamification/{data/gamification_repository,models/game_result_models,providers/*}.dart`, `lib/features/shell/shell_screen.dart`, `lib/features/game_engine/{models/game_models,widgets/{game_result_screen,game_scaffold,game_hud},engine/{game_timer,game_scoring,game_combo},utils/{game_content_mapper,difficulty_utils},audio/game_sound_controller}.dart`, `lib/features/games/hub/presentation/game_hub_screen.dart`, `lib/features/games/{quiz_battle,memory_match,...}/presentation/*_screen.dart` (2 full), `lib/shared/widgets/{feedback,game_card,game_button,badges,xp_bar,recommendation_card,...}.dart`, `lib/features/profile/presentation/{profile,settings}_screen.dart`, `lib/features/tutor/presentation/tutor_screen.dart` (referenced), `test/**` glob (32 files), `backend/src/main/java/...` controller/service/DTO listings (100). Not modified per C2/C10.

**Protected baseline re-verified via docs:** 540 tests passing post-Gate1 (was 534), analyzer 0 errors, web build succeeds, auth wrong-credentials fix intact, PROG-101 difficulty contract fixed.

**Command run for safety:** `git status --short` under `GameLearnAi/` — confirmed frontend changes only within intended untracked test file + 4 Gate1 files; backend changes present but **not modified by this audit** (read-only).

---

**Status:** UI-0 COMPLETE — `frontend/ui_upgrade_plan.md` produced, `frontend/report.txt` to be appended, no application code changed, stopped per C10 awaiting explicit approval before UI-1.
