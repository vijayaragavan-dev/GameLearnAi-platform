# GameLearnAI — Visual Design System

> **Source of truth:** `frontend/lib/core/theme/*` + `frontend/lib/shared/widgets/*` — tokens below are the existing implemented values, not aspirations. Future polish stays within these tokens.
> **Companion:** `frontend/UI_DEVELOPMENT_MASTER.md` (ownership, roadmap, constraints).

---

## 1. Design Principle

**Premium + futuristic + game-like + readable.**

- Dark near-black foundation, purple/cyan brand, gold XP — identity is already premium; polish means *restraint*: one glow per surface, not glow everywhere.
- Rounded 20px cards, 14px inputs, 28px dialogs, pill badges — consistent radius language (`AppRadius`).
- Typography: Space Grotesk (display) + Inter (body) variable fonts — headings tight (-0.5 tracking), body 1.45 line height for readability.
- Motion communicates state, never décor-only (see `animation_spec.md`).
- **Avoid:** excessive neon, excessive gradients, visual clutter, per-screen color inventions. Every color outside `AppColors`/`AppLightColors` is a defect.

---

## 2. Color System

### 2.1 Foundations

| Token | Dark | Light | Usage |
|-------|------|-------|-------|
| `background` | `AppColors.background #070B17` | `AppLightColors.background #F1F5F9` | Scaffold |
| `surface` | `AppColors.surface #10172A` | `AppLightColors.surface #FFFFFF` | Cards, bars |
| `surfaceElevated` | `AppColors.surfaceElevated #151E35` | `AppLightColors.surfaceElevated #FFFFFF` | Dialogs, sheets |
| `surfaceHigh` | `AppColors.surfaceHigh #1B2542` | `AppLightColors.surfaceHigh #E2E8F0` | SnackBars, chips, switches off |
| `border` | `AppColors.border #24304F` | `AppLightColors.border #E2E8F0` | 1px strokes |
| `borderStrong` | `AppColors.borderStrong #334368` | `AppLightColors.borderStrong #CBD5E1` | Emphasis strokes |
| `scrim` | `AppColors.scrim #D9060A14` | `AppLightColors.scrim #590F172A` | Overlays |

**Rule:** Prefer `Theme.of(context).colorScheme.surface/scaffoldBackgroundColor + dividerColor` in screens; `AppColors` for accents only.

### 2.2 Brand & Semantic Accents (shared dark+light)

| Token | Value | Meaning |
|-------|-------|---------|
| `primary` | `AppColors.primary #8B5CF6` electric purple | Primary CTA, selected rail/bar, focused border |
| `primaryBright` | `AppColors.primaryBright #A78BFA` | Selected icon on dark, highlight |
| `primaryDeep` | `AppColors.primaryDeep #5B21B6` | Gradient start, LevelBadge |
| `secondary` | `AppColors.secondary #22D3EE` cyan | Nova, secondary actions |
| `secondaryDeep` | `AppColors.secondaryDeep #0E7490` | Cyan gradient start |
| `success` | `AppColors.success #34D399` emerald | Mastery, completed, correct |
| `warning` | `AppColors.warning #FBBF24` amber | In-progress, caution |
| `error` | `AppColors.error #F87171` coral | Failure, danger, field errors |
| `xp` | `AppColors.xp #FACC15` gold | XP gains, gold gradients |
| `streak` | `AppColors.streak #FB923C` orange | Streak fire, streak chip |
| `locked` | `AppColors.locked #475569` dark / `AppLightColors.locked #94A3B8` light | Locked nodes, disabled |
| `lockedSurface` | `AppColors.lockedSurface #1E293B` / `AppLightColors.lockedSurface #E2E8F0` | Locked card bg |
| `textPrimary` | `F1F5F9` dark / `0F172A` light | Headings, primary body |
| `textSecondary` | `94A3B8` / `334155` | Secondary copy, labels |
| `textTertiary` | `64748B` both | Captions, unselected nav |
| `textOnColor` | `0B1020` dark / `FFFFFF` light | On primary/secondary |

### 2.3 Backgrounds, Surfaces, Elevation

- **Backgrounds:** `AppGradients.backgroundWash` (`#0B1226 → #070B17`) for dashboard hero wash only — never full-page repeated gradients.
- **Surfaces:** `surface` for cards, `surfaceElevated` for dialogs/bottom sheets, `surfaceHigh` for snackBar/switch off — no ad-hoc greys.
- **Elevated surfaces:** `CardThemeData(color: surface, elevation: 0, side: border, radius 20)` — elevation is 0 by intent; glow/shadow replaces material elevation.

### 2.4 Borders, Shadows, Glow, Elevation, Gradients

**Borders:** 1px `border` (card), `borderStrong` (emphasis), `primary α0.18` (rail learn hint), `primary α0.12–0.25` (rail indicators). Radius via `AppRadius`: `sm 10 / md 14 / lg 20 / xl 28 / pill 999`.

**Elevation:** `AppElevation.card 2 / raised 8` — but `CardTheme.elevation 0`; elevation is expressed via `AppShadows`, not Material elevation.

**Shadows / Glow (`AppShadows`):**
- `soft(color, α0.35): blur 18 offset 0,6` — default card soft shadow (use sparingly; dark cards already feel elevated).
- `glow(color, α0.45): blur 26 spread 1` — brand circle (shell logo), level badge glow — one per screen max.
- `drop(): 0x66000000 blur 16 offset 0,8` — rarely, for bottom sheets.

**Gradients (`AppGradients`):**
- `brand #5B21B6→#8B5CF6` — LevelBadge, adventure hero, rail logo.
- `cyan #0E7490→#22D3EE` — Nova contexts.
- `xpGold #B45309→#FACC15` — XP cards, streak fire is separate.
- `streakFire #C2410C→#FB923C` — streak chip / fire contexts.
- `novaCore radial (secondary 0.95 → primary 0.55 → transparent)` — Nova core glow.

**Rules:**
- Max **one** brand gradient per card — no stacked gradients.
- Glow only for selected/focused/celebratory — not on every card.
- Light theme shadows are softer (`shadowColor 0x0F0F172A` in `app_theme.light` `CardTheme`).

---

## 3. Typography

> Families load via `pubspec.yaml: fonts` — `GameLearnDisplay` (SpaceGrotesk-VF.ttf) + `GameLearnBody` (Inter-VF.ttf). Variable font weight via `FontVariation('wght',…)`.

| Level | Token | Size | Weight | Tracking | Line Height | Usage |
|-------|-------|------|--------|----------|-------------|-------|
| **Display** | `AppTypography.display(size 34)` | 34 | 700 variable | -0.5 | 1.12 | Splash, hero numbers |
| **H1** | `AppTypography.h1` | 26 | 700 | -0.3 | — | Screen titles (TROPHY ROOM, COMMAND CENTER) |
| **H2** | `AppTypography.h2` | 20 | 700 | — | — | Section titles, card titles |
| **H3** | `AppTypography.h3` | 17 | 700 | — | — | Subsections, list headers |
| **Body** | `AppTypography.body` | 15 | — | — | 1.45 | Primary copy, topic descriptions |
| **Body secondary** | `AppTypography.bodySecondary` | 14 | — | — | 1.45 | Secondary copy, helper text |
| **Caption** | `AppTypography.caption` | 12.5 | 600 | 0.2 | 1.35 | Metadata, timestamps, pill counts |
| **Label** | `AppTypography.label` | 13 | 600 | 0.8 | — | Uppercase section kicker `COMMAND`, `WORLDS` |
| **Stat** | `AppTypography.monoNumber(size 16)` | 16 | 700 display | — | — | Scores, streak counts |
| **XP** | `AppGradients.xpGold` + `monoNumber` variant | 16–18 | 700+ | — | — | XP gains (gold tint) |
| **Level** | `LevelBadge` circle + `monoNumber` inverted | 18–20 | 800 | 1.2 | — | Level number on brand gradient |

**Hierarchy rules:**
- Dark/light color resolved via `Theme.brightness` inside each `AppTypography` helper — no manual `isDark ?` in call sites.
- AppBar title `17 / 700 / 0.2` (`app_theme.dart:44`), bottom bar label `9.5 / 700 / 1.4` uppercase — already intentional micro-typography, preserve.
- Responsive type scale is **not** viewport-scaled yet — keep 26/20/17 fixed; VIS-1 may introduce `MediaQuery` scale only if audited on 360 vs 1440 legibility.

---

## 4. Component Style

> Cross-reference `frontend/design/component_inventory.md` for file-level inventory.

### 4.1 Cards
- **Universal card:** `CardThemeData(color: surface, elevation 0, radius 20, side: border, shadow transparent)` — no per-card color; tint via `AppGradients` only on hero/level contexts.
- **Elevated / pressable:** `AnimatedScale 0.97 onDown` + `AnimatedContainer shadow soft` (subjects `PressableWorldCard`) — press feedback, not shadow on rest.
- **Locked card:** `AppColors.lockedSurface` bg + `locked` icon/text, dashed border variant for path nodes.

### 4.2 Buttons
- `PrimaryGameButton` (full width, brand gradient, haptics tap) — primary CTA.
- `Secondary` via `OutlinedButton` with `border` + `textSecondary`.
- **States:** `enabled` brand, `disabled` `lockedSurface/locked`, `loading` spinner replaces label; no ghost-only primary actions.

### 4.3 Chips / Badges
- `ChoiceChip` (subjects filter: height 36, rounded pill, selected `primary α0.12` + check).
- `DifficultyPill` (EASY emerald / MEDIUM amber / HARD coral tint) — `shared/widgets/recommendation_card.dart`.
- `PriorityPill` (HIGH/MEDIUM/LOW) — same location.
- `StreakChip` flame `FB923C` with `days DAY/S`.

### 4.4 Progress Bars & Rings
- **XPBar:** `height 6` (header) vs `showLabels:true` (profile) — `shared/widgets/xp_bar.dart:1`; gold fill on `surfaceHigh` track.
- **Progress ring:** Accuracy ring `TweenAnimationBuilder 168px 950ms` (`game_result_screen`, `quiz_result_screen`, `assessment_result`) — emerald/cyan/gold thresholds, not per-screen invented colors.
- **Mastery strip:** `MasteryStrip` rows with per-topic mastery level, capped progress.

### 4.5 Game Cards / World Cards / Achievement Cards
- **World card:** `PressableWorldCard` gradient tint `displayOrder%5` + `SubjectGlyph` + name/description + `SCAN` pill — already gamified, polish means constrained shadow/gradient discipline.
- **Game card:** `_GameCard` in `game_hub_screen` — color per `GameType`, emoji + category (`_categoryFor`) + chips MEDIUM/Timed/Combo/XP — enhance hue/emoji binding, not redesign layout.
- **Achievement card:** Grid `2 cols` (`achievements_screen`) — unlocked glow, locked `locked/lockedSurface` dark; icon via `AchievementIcon(iconKey)`.

### 4.6 Success / Failure / Empty States
- **Success:** `SuccessState` / `Celebrations` (confetti on perfect, level-up overlay) — green `34D399` check, gold XP, not red.
- **Failure:** `ErrorState(title,message,onRetry)` + `describeError(err)` Nova copy — coral accent, honest retry.
- **Empty:** `EmptyMiniCard` / `EmptyState("No subjects"/"No trophies")` — no fabricated placeholder scores.
- **Locked:** Path `LOCKED` node with `requiredMastery` lock message; `scope: SubjectsScreen EmptyState SHOW ALL`.

### 4.7 Glass Panels / AI / Nova Cards
- **Nova companion:** `NovaCompanion` moods `idle/thinking/encouraging/celebrating/speaking`; glass is `surface α` + `border` + `novaCore` radial — not opaque.
- **AI generation panel:** `PathMap` `aiMetadata` (objective/rationale) keyed by `sequenceNumber` — `surfaceElevated` + `secondary α0.08` hint.
- **Glass rule:** One glass panel per screen max; treat as `surface α0.7 + blur` conceptually, rendered as `surfaceElevated` + border today (no `BackdropFilter` unless audited for web performance).

### 4.8 Surfaces for Dark vs Light

| Surface | Dark | Light | Note |
|---------|------|-------|------|
| On dark bg | `surface` cards pop on `#070B17` | — | flagship |
| On light bg | — | `surface #FFFFFF` cards pop on `#F1F5F9` | genuine light — not inverted dark |
| Dividers | `AppColors.border` | `AppLightColors.border` | via `dividerColor` |
| Nav bar | `AppColors.surface` + `border` top stroke | `AppLightColors.surface` + `border` | shell handled |
| Input fill | `AppColors.surface` | `AppLightColors.surface` | same `InputDecorationTheme` radius 14 |

---

## 5. Tailwind / Spacing / Radius

From `AppStyles` — **do not invent new values, pick from this scale:**

- **Spacing:** `xs 4 / sm 8 / md 12 / lg 16 / xl 24 / xxl 32 / huge 48`; `screenH horizontal 20` / `pagePaddingCompact 20 / Medium 24 / Expanded 32`.
- **Radius:** `sm 10 / md 14 / lg 20 / xl 28 / pill 999` — cards `lg 20`, dialogs `xl 28`, inputs `md 14`, chips `pill`.
- **Content widths:** `maxContentWidth 1120 / wide 1200 / rail 80 / railExtended 256`.

---

## 6. Iconography

- Bottom bar / rail: `Icons.dashboard_outlined/rounded`, `public_*`, `insights_*`, `person_*` pairs — selected `primaryBright` (dark) / `primary` (light), unselected `textTertiary`.
- Content: `SubjectGlyph` + `AchievementIcon(iconKey)` — iconKey-driven, not per-screen free icon choice.
- Rule: One icon language — rounded fill when selected, outlined when unselected; no mixing `Cupertino`/`Material` without token decision.

---

## 7. Anti-Patterns to Avoid

- No hardcoded `Color(0x...)` outside `app_colors.dart` — lint via `grep "Color(0x" lib/features`.
- No new gradient beyond `AppGradients` without adding it as a token first and reviewing on both themes.
- No `elevation: 4+` — use `AppShadows` and keep `elevation 0` on cards.
- No pill label without `Wrap` — overflow on 360.
- No animated decoration that doesn't map to a state change (see `animation_spec.md`).

