# GameLearnAI — Component Inventory

> **Scope:** `frontend/lib/shared/widgets/*` + `frontend/lib/core/theme/*` + `features/*/presentation` reusable fragments.
> **Principle:** Inventories document what exists — VIS phases **enhance/reuse**, never silently duplicate.
> **Ownership:** See `UI_DEVELOPMENT_MASTER.md §5` — A = Game Experience owns visual components enhancement; B consumes.

---

## 1. Shared Widgets (`lib/shared/widgets/*` — 12 files)

Each row notes whether to enhance, reuse, or replacement-create later (VIS phase decides timing; this doc does not implement).

| File | Component(s) | Current Purpose | Reusable? | Future Visual Role | Ownership (Enhance) | Action |
|------|--------------|-----------------|-----------|--------------------|---------------------|--------|
| `responsive_layout.dart:1` | `ResponsiveCenter(maxWidth 1120)`, `ResponsiveInset`, `AdaptiveGrid(1→3 cols, Wrap)`, `SectionSpacing`, `ContentSurface`, `SafeRow`, `AppCardStyle(radius lg/xl)` | Constrain + density on tablet/desktop; prevent overflow | Yes — already used in dashboard/subjects/path/hub + polish_test | Canonical responsive primitive for every screen — add width-gated containment only (never duplicate) | A | **Reuse + Polish** — governors `pagePadding`/`columns` from `app_breakpoints.dart` |
| `game_card.dart:1` | `GameCard`, `WorldCard` variants | Pressable card base (gradient tint, glyph, SCAN pill) | Yes — subjects + hub | Single card language for world/game cards — polish gradient discipline (one tint per card) | A | **Enhance** — unify into token-driven `GameCard(type,color,emoji)` reuse, e.g., world vs game distinct via `AppGradients` |
| `game_button.dart:1` | `PrimaryGameButton`, secondary variants | CTA (full-width, brand gradient, haptics) | Yes — quiz/assessment/game result/dashboard continue | Primary CTA across Learn/Play loops; secondary outlined for "Return" | A | **Enhance** — states (loading/disabled) + 48dp min + haptics `AppMotion.fast` |
| `feedback.dart:1` | `ErrorState`, `EmptyState`, `SkeletonCard`, `SkeletonAchievementGrid`, `LoadingIndicator` | Truthful empty/loading/error (via `describeError`) | Yes — every repo `FutureBuilder` | Consistent empty/loading/error language — honest "coming soon" vs fabricating | A | **Reuse** — VIS phases inject per-section skeletons (mastery vs adventure) but base stays |
| `badges.dart:1` | `LevelBadge`, `StreakChip`, `DifficultyBadge`, `SubjectGlyph` | Gamified identity chips | Yes — dashboard header + profile + quiz/hub | Level circle `brand` gradient + glow, streak flame, difficulty EASY/MEDIUM/HARD tints | A | **Enhance** — lock `LevelBadge 54 header → 58 profile` sizes; difficulty tint tokens |
| `achievement_icon.dart:1` | `AchievementIcon(iconKey)` | IconKey-driven trophy icon (no free icon pick) | Yes — achievements + dashboard trophy room + badge detail | Single icon language for trophies — unlocked glow `AppShadows` | A | **Reuse** — ensure iconKey coverage, no new icon set without token |
| `celebrations.dart:1` | `ConfettiEffect`, `LevelUpOverlay`, `AchievementUnlockOverlay`, `AnimatedCounter` | Reward feedback | Yes — game_result + quiz_result | Celebration only on XP/level-up/perfect — never ambient | A | **Enhance** — durations `AppMotion.celebration 950ms`, respect `disableAnimations` |
| `xp_bar.dart:1` | `XPBar(height 6 / showLabels)` | XP progress | Yes — dashboard header (6, no labels) + profile (with labels) + progress | XP fill gold on `surfaceHigh` track — threshold via `nextLevelThresholdXp` | A | **Reuse** — profile `showLabels:true` vs header silent is intentional |
| `stat_card.dart:1` | `StatCard(label,value,icon)` | KPI card (Total XP, Streak, Badges, Mastery) | Yes — profile + progress | Quiet stat — no gradient; rely on `surface` + `border` + `label` typography | A | **Reuse** — keep 4-up grid `AdaptiveGrid` medium+ |
| `quiz_option.dart:1` | `QuizOption` | Selectable answer tile | Yes — quiz + assessment run | Tile border `border` → `primary 1.6` on select, `AnimatedScale` 0.97 press | B (consume) / A owns tile chrome | **Reuse + Polish** — no per-screen option duplications |
| `recommendation_card.dart:1` | `RecommendationCard`, `SectionHeader`, `DifficultyPill`, `PriorityPill` | Reco + priority + difficulty | Yes — dashboard recommendations + recommendation_screen | Reco card is the "quest" primitive — priority HIGH amber/coral, difficulty pill tints | B consumes, A owns card chrome | **Enhance** — quest strip in VIS-3 reuses this card, not new widget |
| `nova_companion.dart:1` | `NovaCompanion(mood idle/thinking/encouraging/celebrating/speaking)` | AI companion presence | Yes — subjects (Choose World tagline), dashboard, tutor, path hints | Glass `surfaceElevated` + `border` + `novaCore` radial — one glass per screen | B (Nova) / A owns glass token | **Reuse** — mood mapping is contract, not free illustration |

**Note on `haptics` / `audio` / `motion` (core, not shared/widgets, but component-level):**

| File | Component | Purpose | Reusable | Role | Ownership | Action |
|------|-----------|---------|----------|------|-----------|--------|
| `core/theme/app_colors.dart:1` | `AppColors` + `AppLightColors` | Semantic palette (dark/light) | Yes — all screens | Single palette source | A (system) | **Preserve** — never add `Color(0x…)` outside it |
| `core/theme/app_theme.dart:1` | `buildGameLearnDarkTheme()` + `buildGameLearnLightTheme()` | Material3 ThemeData (card/radius/border/shadow/input/dialog) | Yes | ThemeMode wiring | A | **Preserve** — VIS-1 may polish tokens, not rebuild |
| `core/theme/app_typography.dart:1` | `AppTypography.{display,h1,h2,h3,body,bodySecondary,caption,label,monoNumber}` | Display SpaceGrotesk + body Inter variable fonts | Yes | Typescale, dark/light color inside helper | A | **Preserve** — headings tight tracking, body 1.45 |
| `core/theme/app_styles.dart:1` | `AppSpacing`, `AppLayout`, `AppRadius`, `AppElevation`, `AppShadows{soft,glow,drop}`, `AppGradients{brand,cyan,xpGold,streakFire,backgroundWash,novaCore}` | Spacing/radius/shadow/gradient tokens | Yes | Single spacing/radius/shadow language | A | **Preserve** — VIS-1 polishes within scale |
| `core/theme/app_motion.dart:1` | `AppMotion{fast 180, normal 300, feature 500, celebration 950, stagger 55; curves easeOut/easeInOut/standard/spring/decelerate}` | Motion tokens | Yes | Every animation maps here | A | **Preserve** — no raw `Duration(…)` outside |
| `core/theme/app_breakpoints.dart:1` | `AppBreakpoints{compact 600, medium 900, expanded 1200, max 1120}`, `AppGutters{pagePadding, columns}` | Responsive tokens + helpers | Yes | Breakpoints for rail/grid/insets | A | **Preserve** — VIS-2 consumes |
| `core/haptics/haptics.dart:1` | `Haptics.tap/select/notification` | Tactile feedback | Yes | Every CTA + nav + correct/incorrect | A | **Reuse** — wired in shell + game + quiz |
| `core/audio/audio_manager.dart:1` | `AudioManager(Sfx/MusicContext)` + `GameSoundController` | Audio hooks, persistent toggles | Yes | SFX `buttonTap/correct/incorrect/xpGain/levelUp…` + Music `menu/dashboard/adventure/quiz/celebration/tutor` | A | **Preserve** — VIS-9 verifies all hooks, never crashes (`_platformBroken`) |

---

## 2. Feature-Level Shared Fragments (Present but Reuse-Candidate)

These are not yet in `shared/widgets` but are reuse patterns — document for deduplication.

| Fragment | Current File(s) | Purpose | Reusable? | Future Role | Ownership | Action |
|----------|-----------------|---------|-----------|-------------|-----------|--------|
| `GameScaffold` + `PolishedGameHud` / `GameHud` | `features/game_engine/widgets/game_scaffold.dart:1`, `game_hud.dart:1`, `polished_game_hud.dart:1` | Safe insets + HUD (timer, score, combo, pause) common to 14 games | Yes (A) | Single game chrome — HUD stays same across game identities; only board identity differs | A | **Preserve chrome, polish visuals** — no logic rewrite |
| `GameResultScreen` | `features/game_engine/widgets/game_result_screen.dart:1` | Shared result + reward + submit `POST /me/game-results` | Yes (A) | End-of-game reward loop (ring/stat row/XP/celebrations/next) | A | **Enhance visuals** — reuse, do not fork per game |
| `AdaptiveGrid / ResponsiveCenter` usage | Already listed as shared — feature files duplicate inline `LayoutBuilder` in older screens (`PathMap`, `MemoryMatch`) | Inline breakpoint logic | Partial | Inline `LayoutBuilder width*0.30` is feature-specific; migrate to `AppBreakpoints` helpers when touching VIS-4/VIS-5 | Respective owners | **Reuse tokens** — replace inline thresholds with `AppBreakpoints` on next VIS touch |
| `Recommendation strip` pattern | `dashboard_screen.dart: sections — RecommendationCard ×2 + AdaptiveFocus / MasteryStrip` | Quests/missions strip on dashboard | Yes (B) | Dashboard quests strip (VIS-3) reuses `RecommendationCard` — not new "QuestCard" | B | **Reuse** — no new quest widget unless `RecommendationItem` proves insufficient |
| `Skeleton` variants | `feedback.dart SkeletonCard` + inline `SkeletonAchievementGrid` variants | Per-section loading placeholders | Yes | Dashboard hero vs mastery vs trophy skeletons should share base `SkeletonCard 120` | A | **Reuse** — VIS prefers one skeleton base, height overrides per section |

---

## 3. Inventory Completeness Check

- `lib/shared/widgets/*` **fully listed** (12 files) — no hidden widgets (verified `glob lib/shared/widgets/*`).
- `lib/core/theme/*` **fully listed** (6 files + controller).
- Feature-level reusable fragments are patterns extracted from `dashboard_screen`, `path_map_screen`, `game_hub_screen`, `game_engine/widgets` — not separate widget files today; listing them prevents divergence.
- No `frontend/lib/shared/` beyond `widgets` — correct (no hidden `lib/shared/models` duplication).

---

## 4. Per-Component Action Matrix

| Action | Components | Rationale |
|--------|------------|-----------|
| **Reuse as-is (no visual change until VIS owns it)** | `XPBar`, `AchievementIcon`, `QuizOption`, `feedback` base, `haptics`, `audio_manager` wiring, `responsive_layout` primitives | Already token-correct; VIS phases will polish in ownership phase |
| **Enhance in VIS-1 (design system)** | `game_card` (world/game unified), `game_button` states, `badges` difficulty tints, `celebrations` duration/curve governance, `app_colors/app_theme/app_styles/app_typography` (within scale), `app_motion`, `app_breakpoints` | Foundation before per-feature polish — single design language |
| **Enhance in VIS-2 (shell)** | `ResponsiveCenter/AdaptiveGrid/ShellScreen` rail behavior + constraint | Shell owns responsive density — isolated |
| **Enhance in VIS-3 (dashboard)** | `RecommendationCard` (as Quest card), `NovaCompanion` dashboard usage, `StatCard` streak/home placement | Dashboard reuses shared cards — no new card invention |
| **Enhance in VIS-5/VIS-6 (game arena/result)** | `GameCard` game-specific hue/emoji binding, `GameScaffold/GameHud/GameResultScreen`, `Celebrations`, `XPBar` XP card | Game identity without engine rewrite |
| **Create only if proven missing** | A true `QuestCard` distinct from `RecommendationCard`, a true `GlassPanel` distinct from current `surfaceElevated + border`, a desktop `MasteryRadar` | Must cite backend/UX gap in `animation_spec` or `visual_design_system` first — never create pre-emptively |

**Rule:** If a VIS phase can consume an existing widget, it must. A new widget requires a `Frontend Dependency` note + `UI_DEVELOPMENT_MASTER.md` shared-file review.

---

## 5. Do Not Implement

This document is **documentation only**. No widget file is modified, no new shared widget is created until its VIS phase. The next step is `animation_spec.md` (motion plan), not implementation.
