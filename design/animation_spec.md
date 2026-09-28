# GameLearnAI — Animation Spec (Motion Plan)

> **Tokens:** `frontend/lib/core/theme/app_motion.dart:1` — `fast 180 / normal 300 / feature 500 / celebration 950 / staggerUnit 55` + `easeOut / easeInOut / standard / spring / decelerate`.
> **Per-screen motion today:** `router.dart:118` `_page` + `shell_screen.dart:131` `AnimatedScale` + dashboard stagger + path pulse + game HUD timers.
> **Principle:** Every motion communicates a state change, interaction, progress, reward, or navigation — never decoration for its own sake. Honor `MediaQuery.disableAnimations`.

---

## 1. Global Motion Language

| Token | Value | Curve | When to Use | Never Use For |
|-------|-------|-------|-------------|---------------|
| `AppMotion.fast` | 180ms | `easeOut` / `decelerate` | Hover, press-release, chip select, pill tint swap, icon select, haptics tap | Full-page navigation, ring fill |
| `AppMotion.normal` | 300ms | `easeOut` / `standard` | Page transition (default `_page`), card enter stagger, slide 0.04–0.08, switch thumb | Celebration, confetti |
| `AppMotion.feature` | 500ms | `easeOut` / `standard` | Result ring fill (`quiz_result`, `assessment_result`, `game_result` 168px ring with scaleIn), feature sheet slide | Press, hover |
| `AppMotion.celebration` | 950ms | `decelerate` | Confetti fall, `LevelUpOverlay` rise+fade, achievement unlock pop — one per reward loop | Nav, list scroll |
| `AppMotion.staggerUnit` | 55ms | `easeOut` | Dashboard section entrance `TweenAnimationBuilder` per index + path node pulse offset | Any duration-critical path (time-boxed games) |

**Curves:**
- `easeOut` (cubic) — entrances, page slide.
- `easeInOut` — reversible progress (XP bar fill).
- `standard` (fastOutSlowIn) — Material-matched transitions.
- `spring` (`elasticOut`) — selected `AnimatedScale 1.0→1.12` on bottom-bar tab select (already in `shell_screen.dart:131`).
- `decelerate` — celebrations that fall/settle.

---

## 2. Motion by Concept

All motions are **planned, not yet implemented** beyond existing baselines — VIS-8 owns implementation. Durations below are **guidance**, token-mapped.

### 2.1 Page Transition

- **Trigger:** Route push/go (`_page` builder in `router.dart:118`).
- **Purpose:** Orient navigation — forward slide vs scale tells hierarchy.
- **Behavior:** `FadeTransition(opacity: curved)` + `SlideTransition(Tween 0.04–0.08 → 0.0)` default; topic/assessmentResult `scaleIn 0.93→1.0`; quiz/games `Offset(1,0)` horizontal (already implemented per route). `transitionDuration AppMotion.normal` (300) / `feature` (500) for results; `reverseTransitionDuration AppMotion.fast` (180).
- **Duration:** 180–500 (token-aligned).
- **A11y:** Honored `go_router` `NoTransitionPage` for `splash/onboarding` (no motion on restore) — keep; check `MediaQuery.disableAnimations` → jump-cut (0) if reduced motion.

### 2.2 Card Hover (Web/Desktop)

- **Trigger:** `MouseRegion` enter while `kIsWeb || expanded` — only where `AppBreakpoints.isWide/isExpanded` matters.
- **Purpose:** Affordance that card is pressable (`PressableWorldCard`, `_GameCard`, `RecommendationCard`).
- **Behavior:** `AnimatedContainer` shadow `soft→glow(primary α0.18)` 180ms + `AnimatedScale 1.0→1.02` `easeOut` — no translate, no rotation (avoid layout shift).
- **Duration:** `AppMotion.fast 180`.
- **A11y:** Hover is progressive enhancement — touch retains `AnimatedScale 0.97` press (see 2.3); no semantic change; if `disableAnimations`, skip scale/shadow, keep border tint swap (instant).

### 2.3 Card Press / Tap

- **Trigger:** `GestureDetector onTapDown` on any pressable card/button/tab.
- **Purpose:** Confirm press before haptics+action.
- **Behavior:** `AnimatedScale 0.97` on down, release `1.0` `spring` 180ms (subjects card already does `AnimatedScale 0.97`; bottom bar selected `1.12 spring` — unify: press is `0.97`, select is `1.12`).
- **Duration:** 180 `fast` (down `80ms` implicit) / `spring` on release.
- **A11y:** Pair with `hapticsProvider.tap()` where already wired (`shell_screen`, `quiz_option`, `dashboard continue`); no haptics if `pref_haptics_enabled == false`; focus ring on keyboard Tab.

### 2.4 XP Gain (Inline)

- **Trigger:** `GameResultScreen` / `QuizResultScreen` receives `d.xpGained > 0` or `levelUp` from delta `capture/compare`.
- **Purpose:** Reward — XP is gold, not just a number.
- **Behavior:** XP card count `AnimatedCounter 500ms easeOut` from prev→next; gold `xpGold gradient` pulse `scale 1.0→1.04→1.0` 300ms coinciding with `Sfx.xpGain`; underlying `XPBar` fill `easeInOut 500ms`.
- **Duration:** Counter 500 (`feature`), bar fill 500, pulse 300 (`normal`) overlapped.
- **A11y:** `Semantics(label: '+42 XP')`; if `disableAnimations`, jump to final value, still announce.

### 2.5 Level Up (Modal Overlay)

- **Trigger:** `GameResultScreen d.leveledUpTo != null` / `QuizResultScreen` `delta.leveledUpTo`.
- **Purpose:** Milestone — bigger than XP gain.
- **Behavior:** `LevelUpOverlay` rises from bottom `Slide 0.25→0` + `Fade` 500ms `standard`, holds 800ms, then auto-dismiss `Fade 300`; `Sfx.levelUp`; sequential after confetti if perfect. Brand gradient badge scales `0.92→1.0 spring`.
- **Duration:** In 500 + hold 800 + out 300 ≈ 1600ms window (token: `celebration 950` is confetti, level-up is feature+hold).
- **A11y:** Overlay is `Semantics liveRegion` `Level up — Level 7`, focus returns to result CTA; `disableAnimations` → no rise, instant + haptics still.

### 2.6 Achievement Unlock (Toast / Banner)

- **Trigger:** `newAchievements.isNotEmpty` in result delta.
- **Purpose:** Trophy earned — distinct from level-up.
- **Behavior:** `AchievementUnlockOverlay` banner `Slide 0.08→0` + glow `AppShadows.glow(primary, α0.3)` 320ms `easeOut`; icon pop `scale 0.9→1.0 spring`; auto-dismiss after 2200ms or tap. Sequential after level-up if both.
- **Duration:** In 320 + hold 2200 + out 220.
- **A11y:** `Semantics(liveRegion: 'Achievement unlocked: <name>')`; reduced motion → instant banner.

### 2.7 Path Node Unlock

- **Trigger:** `LearningNode status` transitions `LOCKED → AVAILABLE` after quiz/mastery submission revalidation (`PathMapScreen` refresh).
- **Purpose:** Syllabi progression — trail advancement.
- **Behavior:** Node previously locked `lockedSurface` crossfades to `surface` 300ms + ring pulse `Scale 1.0→1.18→1.0` 500ms `decelerate` (path already pulses `AVAILABLE` ring — preserve but tokenize); `Sfx.nodeUnlock`; "YOU ARE HERE" pill `Slide 0.06→0` 300.
- **Duration:** Fade 300, pulse 500.
- **A11y:** Node `Semantics(selected: isAvailable)`; pulse suppressed if `disableAnimations`.

### 2.8 Victory

- **Trigger:** `GameResultScreen` performance `LEGENDARY/EXCELLENT` or perfect accuracy 1.0.
- **Purpose:** Apex reward.
- **Behavior:** `ConfettiEffect` fall 950ms `decelerate` (already present on perfect/xp) — confine to result screen top, not full scaffold; ring accent `success #34D399` brief `glow α0.45 26 blur` 320ms; `Sfx.missionComplete`.
- **Duration:** Confetti `celebration 950`, glow 320.
- **A11y:** Confetti `ExcludeSemantics` (decorative); provide textual `LEGENDARY — Perfect run` label.

### 2.9 Failure / Keep Trying

- **Trigger:** `GameResultScreen` `KEEP TRYING` / quiz `FAIR` band.
- **Purpose:** Encouraging retry — not punishing.
- **Behavior:** Ring remains `warning #FBBF24` (not error coral) unless truly failed; gentle shake `Translate -4→+4→0` 220ms `easeInOut` on stat row only (not ring) — one oscillation max; CTA `Play again` primary, `Continue` secondary.
- **Duration:** 220 (`fast`+).
- **A11y:** No auto-dismiss; focus defaults to `Play again`; reduced motion → no shake, keep color cue + copy.

### 2.10 Loading (Skeletons → Content)

- **Trigger:** `FutureBuilder` pending (`dashboardProvider`, `contentRepo.subjects()`, `gamificationRepo.achievements()`).
- **Purpose:** Perceived progress — not spinner everywhere.
- **Behavior:** `SkeletonCard 120` shimmer `easeInOut 1100ms` loop (already `SkeletonAchievementGrid`) — fade-out `Fade 220` replaced by `Fade+Slide 0.04` 300ms content in (stagger `55ms` per index on dashboard).
- **Duration:** Shimmer loop 1100 (not `AppMotion` token — ok as shimmer), content stagger `55`.
- **A11y:** Skeleton `Semantics(label: 'Loading…')` `hidden: true` for content; announce only on error/empty.

### 2.11 Nova Interaction

- **Trigger:** Tutor stream: user sends → TUTOR pending → chunks → done; also dashboard `NovaCompanion` mood swap on section change.
- **Purpose:** Nova feels resident, not static.
- **Behavior:** Pending dots `AnimatedOpacity` blink 3× 180ms cycle; bubble entry `Fade+Slide 0.04 220` per message; glass panel `novaCore` radial subtle drift 800ms `easeInOut` (keep very subtle — one drift, not loop).
- **Duration:** Dots cycle 180, bubble 220, drift 800.
- **A11y:** Input retains `FocusNode`; pending state `Semantics(liveRegion: 'Nova is thinking…')`; reduce motion → dots static, drift off.

### 2.12 Navigation (Shell Tab Reselect)

- **Trigger:** Bottom bar or rail tab selected (`shell_screen _BottomBar/_Rail onTap`).
- **Purpose:** Tab activation is distinct from card press.
- **Behavior:** Icon+label `AnimatedScale selected 1.12 spring 180ms` + indicator `primary α0.18/0.25` `AnimatedContainer 200` + `hapticsProvider.tap()` + `Sfx.buttonTap`.
- **Duration:** 180 + indicator 200.
- **A11y:** `Semantics(button:true, selected:, label:'<Name> tab')` already correct; keyboard: `onDestinationSelected` handles; reduced motion → scale off, indicator swap instant.

---

## 3. Booking Motion per Transition (Already Implemented in Router)

| Route | Transition | Duration | Curve | Note |
|-------|------------|----------|-------|------|
| `splash/onboarding` | `NoTransitionPage` | 0 | — | Restore phase — no motion |
| `login/register` | `Fade+Slide 0.04` | `normal 300` | `easeOut` | Default `_page` |
| `home/subjects/progress/profile` | `Fade+Slide 0.04` | `normal 300` | `easeOut` | Shell tabs — symmetric |
| `/path/:subjectId` | `Fade+Slide 0.06` | `normal 300` | `easeOut` | Trail entrance |
| `/topic/:topicId` | `Fade+Scale 0.93` | `normal 300` | `easeOut` | Detail pop |
| `/lesson/:topicId` | `Fade+Slide 0.08` | `normal 300` | `easeOut` | Reading |
| `/quiz/:topicId` | `Fade+Slide 1,0` (horizontal) | `normal 300` | `easeOut` | Forward push |
| `/quiz-result` | `Fade+Scale` | `feature 500` | `standard` | Celebratory result |
| `/assessment/:subjectId` `→/run →/result` | `Fade+Slide` → horizontal → `Fade+Scale 500` | 300→300→500 | `easeOut`→`easeOut`→`standard` | Scan flow |
| `/games/:topicId*` hub + games | `Fade+Slide 0.06` hub, horizontal `1,0` per game | `normal 300` | `easeOut` | Arcade forward |
| `/tutor` | `Fade+Slide 0.04` | `normal 300` | `easeOut` | Companion entry |
| `/achievements/:code`, `/streak`, `/settings` | `Fade+Scale / Fade+Slide 0.04` | `normal 300` | `easeOut` | Modals |

---

## 4. Accessibility & Reduced Motion

- **Global gate:** `MediaQuery.disableAnimations` (`MediaQuery.of(context).accessibleNavigation` is *not* the gate — correct gate is `disableAnimations` or `MediaQuery` `accessibleNavigation` plus explicit `AppMotion` guard) — path pulse, dashboard stagger, game HUD timers already check this (verify in VIS-8 audit).
- **When reduced motion is on:**
  - Skip `AnimatedScale` press/celebration scale; jump to final value.
  - Skip confetti drift; keep textual reward copy.
  - Skip card hover scale/shadow; keep border tint instant.
  - Page transition collapses to `Fade 120` or 0 — never Slide 0.08 (vertigo).
  - Timing-sensitive game engines (`game_timer`) remain accurate — motion never affects scoring.
- **Focus:** All animated cards retain `FocusNode` + visible focus border (`focusedBorder primary 1.6`); animation does not steal focus.
- **Contrast in motion:** Gold `#FACC15` on `surface #10172A` passes but animated gold pulse must keep `textPrimary` legible — no gold-on-gold text animation.
- **Target sizes stay ≥48dp** during scale — `0.97` press does not shrink hit area.

---

## 5. Spec Conformance Checklist (VIS-8 Gate)

VIS-8 reviewer must verify:

- [ ] `AppMotion` tokens consumed — no raw `Duration(…)` outside `app_motion.dart` except shimmer (documented).
- [ ] Reduced-motion branch tested on every concept above (device a11y toggle).
- [ ] No animation inflates `flutter build web` by importing a heavy package — use `Animated*`/`TweenAnimationBuilder` only.
- [ ] Celebration audio (`Sfx.xpGain/levelUp/achievementUnlock/missionComplete`) fires co-incident with visual, not before.
- [ ] `flutter analyze` 0, `flutter test` pass (motion-only change must not break `polish_test`/`ui5`/`ui6`), `flutter build web` succeeds.

---

## 6. Do Not Implement Yet

This spec is **documentation only**. VIS-8 implements these motions — no Dart file is changed by this document. Next is `git status` verification (docs-only), not code.
