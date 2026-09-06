# GameLearnAI — Leaderboard + Character Gamification Specification

**Project:** GameLearnAI — Smart Adaptive Learning Adventure (AIS-01 / Edutainment)
**Phase:** SPECIFICATION / ARCHITECTURE — Leaderboard + Character Progression Ecosystem
**Status:** `SPECIFICATION ONLY — DO NOT IMPLEMENT` (authoritative blueprint for all later phases)
**Version:** 1.0.0 — 2026-09-06
**Source authority inspected:** `backend/` (Spring Boot 3.5.16 / Java 21 / MySQL 8 / Flyway V1–V16), `frontend/` (Flutter 3.9 / Riverpod / go_router), existing specs `GameLearn_AI_Database_Specification.md v1.0`, `GameLearn_AI_Gamification_Specification.md v1.0.0 APPROVED`, `GameLearn_AI_API_Contract.md v1.4.0 APPROVED`, plus live entities/migrations/Flutter theme/widgets
**Branch baseline:** `main` @ `8c29942`
**Document path:** `frontend/docs/LEADERBOARD_CHARACTER_GAMIFICATION_SPEC.md` (canonical; if the team prefers `backend/` docs, mirror this file there — the content is product-canonical, not layer-canonical)

> **CRITICAL ACCURACY RULE:** Every reference to an *existing* backend field/entity/API names the actual implementation (`src/main/java/com/gamelearn/...`, `src/main/resources/db/migration/*.sql`, `frontend/lib/...`). Anything that does **NOT** currently exist is explicitly flagged `NOT CURRENTLY AVAILABLE — NEW IMPLEMENTATION REQUIRED` and placed in §§15–16.

**Required deliverable coverage (Part Z §28 — all 28 present):**
1. Product vision (§1)  2. Gamification loop (§2)  3. Overall leaderboard specification (§3)  4. Subject leaderboard specification (§4)  5. Ranking algorithm (§3.2, §4.2, §18)  6. Tie-breaking (§3.2, §4.2)  7. Character system (§7)  8. Character rarity (§7.2)  9. XP/currency economy (§8)  10. 70%+ syllabus unlock system (§10)  11. Avatar purchase rules (§11)  12. Avatar equip rules (§13)  13. Profile integration (§12)  14. Dashboard integration (§19.4)  15. Database model (§15)  16. API contracts (§16)  17. Security (§17)  18. Privacy (§17.6)  19. Anti-cheat (§17.1–17.5)  20. Performance (§18)  21. Responsive UI (§19)  22. Animation (§20)  23. Edge cases (§22)  24. Testing strategy (§24)  25. Implementation roadmap (§23)  26. Product-balance safeguards (§25)  27. Explicit assumptions (§26)  28. Open decisions (§27)

---

## 1. Product Vision

GameLearnAI is **not** an LMS with a leaderboard bolted on. It is a **polished game ecosystem where learning IS the gameplay**. The leaderboard and character system complete the ecosystem — they give every learner a visible identity, a meaningful collection to pursue, and a fair competitive context that rewards *learning quality*, not grinding.

```
LEARN → PLAY → EARN → UNLOCK → COMPETE → MASTER → PRESTIGE → LEARN (loop)
```

**Core promise:** A student who studies honestly always progresses faster than a student who farms. The rarest cosmetics signal mastery, not money or grind time. Competition is opt-in, positive, private-by-default, and never humiliating.

**Non-goals (explicitly excluded):**
- Pay-to-win, real-money purchases, loot boxes, gacha gambling, or paid XP boosts.
- Algorithmic addiction loops (infinite scroll, variable-ratio rewards, shaming notifications).
- Public shaming of low performers — every leaderboard has positive framing (§4, §17).

---

## 2. Gamification Loop — Normative Core Loop

```
LEARN surface         PLAY surface              EARN                UNLOCK             COMPETE               MASTER              PRESTIGE
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
Lesson / Topic /      14 games (Quiz Battle,   XP + Credits        Avatars by:        Overall +             Topic mastery       Legendary /
Quiz / Assessment     Memory Match, Drag &     (server-derived,    credits OR         subject               (BEGINNER→           Mastery
                      Drop, Speed Run, Debug   atomic with         thresholds,        leaderboards +        MASTERED),          avatars +
                      Arena, Unlock the Code,  game/quiz TX)       never by           nearby players +      streaks,           collection
                      … 14 total)                                  client claim       personal best         achievements       completion
                                                                     ↓                                          ↓                    ↓
                                                              Level T(n)=50(n-1)n   Rank movement +       Overall mastery    Next-season
                                                              + streak bonus        XP-to-next-rank         milestones         carryover
```

**Design axiom:** The backend is authoritative for every value in the loop (§21). Flutter displays server-derived numbers only; it never computes rank, XP, mastery, or unlock eligibility.

---

## 3. Overall Leaderboard Specification — Part A

### 3.1 Ranking metric — RECOMMENDATION

**Primary ranked key = `learner_profiles.total_xp` (lifetime, server-authoritative).**

*Why not a derived `leaderboard_score` in v1:* the existing Gamification Spec already bounds XP per attempt to `0..25` (+10 base + ≤15 performance, plus capped milestone/achievement bonuses), clamps `total_xp` at `Integer.MAX_VALUE`, and stores every award as an immutable `xp_transactions` row. Inventing a parallel score that weights XP, mastery, and streak would (a) duplicate authoritative fields, (b) require owner-amended formulas that do not exist yet, and (c) obscure the single source of truth students already understand ("XP is progress"). A separate score is deferred to **v2 Season** (§3.7) where it would be expressed as a *seasonal ledger slice*, not a competing lifetime metric.

**Display enrichment (not rank):** each row shows derived context — `current_level` (via `T(n)`), `overall_mastery`, `current_streak_days`, `equipped_avatar` — so a high-XP player who never masters topics *looks* different from a balanced master, without breaking rank determinism.

**Rejected alternative documented:** ranking by `overall_mastery` average alone would penalize new learners (few topics ⇒ unstable average) and is undefined for 0-topic users; ranking by raw score sum would be gameable by replaying trivial games. Both are NOT USED as primary keys.

### 3.2 Ordering, tie-breaking, pagination, recalculation

| Decision | Rule (normative) |
|---|---|
| **Order** | `ORDER BY total_xp DESC, tie_break ASC, user_id ASC` — `tie_break` is the *earliest* timestamp among: (1) `learner_profiles.created_at`, (2) `xp_transactions.created_at` of the `MAX(total_xp)` row — queried as `MIN(created_at) WHERE user_id`. The user who reached the tied XP first ranks higher. `user_id ASC` is the final deterministic tie salt (never visible to users). |
| **Recalculation mode** | **Live materialized on read, cached warm.** There is NO batch cron that "recalculates rank nightly." Rank is a `COUNT(*) WHERE total_xp > :me` + tie window query (§17) over an indexed column. A short-TTL cache (§17) fronts it for dashboard fast-path. |
| **Pagination** | `GET ?page=1&size=20` (1-indexed, max `size=50`, default 20). `page`/`size` are the only paging knobs — no cursor needed because ranking is total-order and offset performance is acceptable under §17 indexes. Response carries `totalPlayers`, `totalPages`, `currentPage`. |
| **Top-N display** | Dedicated `top` slice: first 3 rendered as podium (§5), next 7 as compact list on full leaderboard screen. API flag `includeTop=true` merges `top(10)` + nearby window in one call to avoid two round-trips. |
| **User's own rank** | Always returned, even when outside the requested page, as `me: { rank, xp, level, deltaToNext, totalXpToNext }`. Never requires the client to scan pages. |
| **Nearby competitors** | `nearby: [ .. ]` — 2 above + `me` + 2 below (5-window, 5 when near edges it expands downward/upward). Uses the same ordering. |
| **Rank movement** | `rankDelta = previousRank - currentRank` where `previousRank` is the rank at `last_snapshot_at` (a new column, see §15) or `null` on first participation. Positive = climbed, negative = dropped, `null` = new entrant. Stored per user and updated on XP-change transactions. Frontend shows `↑ 2 / ↓ 1 / — / NEW`. |
| **Personal best** | `bestRank = MIN(rank_ever_achieved)` persisted in `user_leaderboard_stats` (§15). Celebrated only upward (§10). |
| **Deleted / blocked / inactive / new users** | Excluded unless explicitly included: `WHERE users.status='ACTIVE'` (§15) and `total_xp > 0` OR the caller's own row (so a 0-XP new user still sees `me: rank = N+1, XP 0`). No anonymized tombstones leak. Empty states handled in §5.9. |

### 3.3 Privacy & display (§16 binding)

Leaderboard row exposes ONLY: `displayName` (or `alias`), `equippedAvatar` (id + asset key), `currentLevel`, `totalXp`, `streakDays` (optional public flag), `subjectFocusIcon` (optional). Never email, `password_hash`, `user.id` raw beyond pagination internal.

Anonymous mode: `leaderboard_visibility = { PUBLIC, ALIAS, PRIVATE }` (see §16). `PRIVATE` users do not appear in others' `top`/`nearby`, but still receive `me` privately. `ALIAS` shows a user-chosen alias ( ≤24 chars, profanity-filtered) + avatar.

---

## 4. Subject Leaderboard Specification — Part B

Example concept (never fabricated):
```
GLOBAL:        #7     12,840 XP
PROGRAMMING:   #12      840 subject-XP
MATHEMATICS:    #4    1,120 subject-XP
PHYSICS:       #21      210 subject-XP
```

### 4.1 Subject metric — `subject_xp` (primary), `subject_mastery_avg` (enrichment)

`subject_xp` is the **sum of XP whose originating activity topic belongs to that subject**. Unlike global `total_xp`, it requires a lineage. Because `xp_transactions.reference_type/reference_id` already supports `QUIZ_ATTEMPT`, `GAME_RESULT`, and `ACHIEVEMENT`, the award path already knows the topic (via `quiz_attempts.quiz_id→quizzes.topic_id→topics.subject_id` and `game_results.game_type + topicId` — game results already carry `game_type`, topic lineage will be stored at submission time, see §15.3). Summation is server-side, never client-supplied.

Fallback when lineage is absent (old rows predating the new column): that transaction contributes to `total_xp` but not to any subject slice — the subject leaderboard transparently notes "Subject XP counts from <migration-date> onward" rather than inventing history.

**Enrichment columns** per subject: `subject_mastery_avg = AVG(topic_mastery.mastery_score WHERE topics.subject_id AND user_id)` and `topics_mastered_count` (mastery_level='MASTERED'). These are *display*, not rank keys — avoids penalizing breadth vs depth arbitrarily.

### 4.2 Ordering & tie rules (mirrors §3)

`ORDER BY subject_xp DESC, subject_tie_break ASC, user_id ASC` where `subject_tie_break = MIN(xp_transactions.created_at) WHERE subject_xp contribution`.

### 4.3 Eligibility gates (anti-empty-leaderboard noise)

| Gate | Rule |
|---|---|
| **Minimum activity** | User appears on a subject board only if `subject_xp > 0` OR `topics_assessed >= 1` in that subject (via `topic_mastery` rows). Users with 0 signal in that subject are omitted from *that* subject board but remain on other subjects/global. |
| **Inactive users** | Same `users.status='ACTIVE'` filter as §3. Stale subject XP never decays in v1 (decay would need an owner decision; documented as deferred pod v2). |
| **“Enrolled in multiple subjects”** | There is no enrollment table in the current schema — subjects are browsed, not subscribed. A user implicitly participates in every subject where they have any `topic_mastery`, `progress`, or `xp` lineage. No subscription ceremony, no `subject_switching` state machine. If an enrollment concept is added later, the same `subject_xp` key still governs rank. |
| **Subject with no activity** | Empty state: illustration + "Be the first champion of <Subject>" + CTA to Take Assessment / Play. Not an error (§5.9). |
| **Subject completion** | When `syllabusCompletion >= 100%` per §8, the subject badge upgrades to `MASTERED` and the subject row gets a gold rim — no rank bonus. |

### 4.4 Dependency on existing Subject/Topic/LearningPath structures

`subjects` (already seeded with 5, extendable without schema change) and `topics(subject_id, display_order, difficulty, is_active)` are the canonical subject topology. Adding a subject is a row + topics, never a schema change. Subject leaderboards read `subjects.is_active = true` subset only.

---

## 5. Ranking UX — Part C (Premium Game Interface)

> **ANTI-PATTERN FORBIDDEN:** No `<table>` of numbers. Every leaderboard is a **Champions Arena** — the same visual language as the existing `FeaturedSurface`, `GameIdentitySurface`, `MasteryOrb`, `XPBar`, and `StreakChip` from `dashboard_screen.dart` / `progression_widgets.dart` / `game_surfaces.dart`.

### 5.1 Anatomy (full-screen "Champions Arena")

```
[ AtmosphericBackground + GlowOrb(primary 0.10) + secondary 0.06 — same tokens as dashboard ]
┌─ SEGMENTED CONTROL ────────────────────────────────┐
│  GLOBAL  ·  Programming  ·  DBMS  ·  …subject chips (scrollable)  │
└───────────────────────────────────────────────────┘
┌─ PODIUM (top 3) ───────────────────────────────────┐
│  #2 (silver)    #1 (gold, elevated, FeaturedSurface gold)    #3 (bronze)  │
│  [Avatar 64]   [Avatar 84 + crown]               [Avatar 64]                │
│  Name  Lv     Name  Lv   (truncate 18 chars)      Name  Lv                  │
│  XP            XP                                 XP                         │
│  MasteryOrb 12% etc — muted 32dp                                                │
└────────────────────────────────────────────────────────────────────────────┘
┌─ RANK LIST (4..N) ────────────────────────────────┐
│  #4  [Avatar 40]  Name          Lv 12  11,430 XP  Mastery 42%  ↑2            │
│  #5  [Avatar 40]  Name          Lv 11   9,210 XP  Mastery 88%  —             │
│  … compact PlayerCard per row (highlighted row for me)                       │
└────────────────────────────────────────────────────────────────────────────┘
┌─ YOUR STATION (sticky bottom sheet / pinned card) ───────────────────────────┐
│  YOU  #17  7,820 XP   Lv 18   180 XP TO #16  [mini XPBar → next rank]        │
│  [View full arena]  [Share — disabled in v1, reserved]                      │
└────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Player card spec

| Field | Source | Rendering |
|---|---|---|
| `rank` | §3 ordering | Large display number (Space Grotesk 800, 28pt podium / 16pt list). Gold/silver/bronze gradient for top 3; neutral otherwise. |
| `avatar` | `equipped_avatar.assetKey` (see §12) | Circular 40–84dp with `border: avatarRarityColor` (Common=slate, Rare=cyan, Epic=purple, Legendary=gold per §7). Locked fallback: initial letter in `AppGradients.brand` (same as `ProfileScreen` today). |
| `level` + `XP` | `learner_profiles.current_level / total_xp` | `LevelBadge(level)` + `Formatters.count(totalXp)` (reuse existing `levelBadge` + `Formatters`). |
| `mastery` | `overall_mastery` (global) or `subject_mastery_avg` (subject view) | `MasteryOrb(fraction, 32–40dp, animate:false)` muted variant — no glow, so list stays scannable. |
| `streak` | `streaks.current_streak_days` | `StreakChip(days)` only when `days >= 2` (avoid noise for 0/1). |
| `movement` | `rankDelta` | `↑` green (success), `↓` muted (textTertiary), `—` stable, `NEW` cyan pill for first appearance. Narrated via `Semantics(label: 'rank moved up 2')`. |

### 5.3 Progress toward next rank (never fabricated — §U)

`xpToNext = (totalXp of rank_{n-1}) - myTotalXp + 1` — derived from the *actual* leaderboard rows the API returned for `nearby`/`top`. When the user is #1, state is `PEAK` ("Peak mastery — you outrank everyone"). When the API cannot determine the next row (e.g., filtered board), show `—` rather than inventing a number.

Dashboard compact variant: `180 XP TO #16` + `XPBar(xpToNextLevel)` already exists — the leaderboard variant mirrors it but for *rank gap*.

### 5.4 State coverage (all required)

| State | Spec |
|---|---|
| **Loading** | `SkeletonList(itemCount: 6, itemHeight: 72)` (already used in `ProfileScreen`) + shimmer via `AppMotion.fade`. No partial podium flash. |
| **Error** | `ErrorState(title, message, onRetry)` (existing). Backend envelope is `ErrorResponse{status, errorCode, message, path, requestId}`. Leaderboard's "stale" banner (see §16) is informational, not an error. |
| **Empty — no participants** | Illustration (trophy outline) + "No champions yet — be the first!" + CTA `Start adventure`. No 404. |
| **Empty — filtered subject** | "No champions in <Subject> yet" — same CTA but deep-links to that subject's assessment/path (`/path/<id>`). |
| **Single participant** | Podium collapses to single gold card (#1) + your-station shows YOU #1 PEAK. |
| **Tied users** | Same `total_xp` shown, distinct ranks (`#4` and `#5`) per tie-break, tiny `=` badge on the lower tied row ("Tied on XP — ranked by earliest milestone"). |
| **Offline** | Cached last-success body (Riverpod + `shared_preferences`, TTL §17) rendered with banner `Offline — showing snapshot from <time-ago>`. Your-station still shows cached `me`. No write attempts queued offline (ranking never accepts client XP). |
| **Current-user highlighting** | Row `border: AppColors.primary 1.5 + glow 0.14` + `background: primary 0.08 wash` (`FocusedSurface` pattern). Also pinned in `YOUR STATION` so the user never scroll-hunts. |

### 5.5 Responsive, theme, accessibility (§19)

- **Breakpoints:** reuse `AppBreakpoints` (compact <600, medium 600–900, expanded 900–1200, wide ≥1200) + `AppGutters.pagePadding`. Full spec in §19.1.
- **Dark / Light / System:** tokens from `AppColors` / `AppLightColors` + `buildGameLearnDarkTheme()` / `buildGameLearnLightTheme()` — no per-screen color invention. See §19.2.
- **A11y:** Every card `Semantics(label: 'Rank 4, Alex, Level 12, 11,430 XP, mastery 42 percent')`; podiums `heading` level; rank deltas narrated; animations gated by `MediaQuery.disableAnimations`.

---

## 6. Motivation & Game Design — Part D (Healthy Incentives)

### 6.1 Included positive mechanisms (all server-verified, rate-limited, non-monetized)

| Mechanism | Trigger | Caps / guardrails |
|---|---|---|
| **Rank progression** | `rankDelta > 0` after any XP-earning transaction | Banner only on *meaningful* climb (≥1 rank, debounced by 30s so rapid quiz submits don't spam). |
| **Personal best** | `rank < bestRank` | One-shot confetti (§9) + persistent badge in profile "Peak rank #<n>". No negative notification on drop. |
| **XP toward next rank** | Computed live from real rows | Shown as positive encouragement only — never "You're falling behind!" (§4). |
| **Rank-up celebration** | Same transaction as XP award | Reuses `RewardSurface` + `AppMotion.celebration` (950ms); respects `reducedMotion`. |
| **Weekly / seasonal progress** | Season slice (see §3.7) `seasonXp` + `seasonBestRank` | Resets do not erase lifetime progress (§Y). Seasonal board is *additive*, not replacement. |
| **Achievement & mastery milestones** | Existing `achievements` (6) + new **avatar milestones** (§7–§8) | One-time each, DB-unique, never repeatable (§7). |
| **Character unlocks** | §7–§10 | Highest-motivation lever (§E). Legendary requires mastery, not grind (§H). |
| **Learning streaks** | Existing `streaks` (already capped: milestones 3/7/14/30) | Natural reset only (Gamification Spec approved), no pay-to-restore. |
| **Challenge milestones** | `Boss Battle` / `Puzzle Arena` completions tracked via `game_results` + syllabus % | Threshold-gated (§8), not repetition-gated. |

### 6.2 Explicitly FORBIDDEN (normative)

- Public shaming of low ranks (no "Bottom 3", no global broadcast of drops).
- Punitive loss of XP/level for poor performance (XP never subtracts — Gamification Spec §4.2).
- Excessive pushes — max 1 rank-change notification per hour, batched.
- Pay-to-win, loot-box, or random paid reward (no such endpoint may exist — §16).
- Gambling-like "mystery avatar crates."
- Real-money gates on any progression or ranking item.

**Healthy framing language:** The leaderboard tagline is **"Climb by learning, not by grinding."** Every empty/loading/error string uses that vocabulary (not "crush your rivals").

---

## 7. Character / Avatar System — Part E (Original IP)

### 7.1 IP rule (binding)

All 24 launch characters are **original GameLearnAI IP** — names, lore, silhouettes, and palettes owned by the product. NO licensed/copyrighted characters, no Subway Surfers/Marvel/anime clones. The art system uses vector illustrations in brand palette families so legal risk is zero and theme recoloring (§19) stays cheap.

### 7.2 Rarity / tier ladder (5+1)

`avatars.rarity` enum (string-persisted per §2.5) — **NOT** the placeholder names from the prompt verbatim; these are the approved product values with color tokens:

| Tier | Code | Visual purpose | Availability | Unlock mechanism | Cost / Prestige | Shine |
|---|---|---|---|---|---|---|
| **Initiate** | `INITIATE` | Friendly starter, welcoming | All new users | **Granted at account creation** (first row in `user_avatars`) — 2 variants: `Nova Spark` (warm) + `Byte Scout` (cool). User picks during onboarding; can switch anytime. | Free, cosmetic only | Slate border |
| **Common** | `COMMON` | Expressive learners, daily motivation | Broad | **Credits purchase** (see §8) — threshold `total_xp ≥ 100` OR `level ≥ 2` (so a brand-new user cannot buy before proving first activity) | 800–1,500 Credits | White/slate |
| **Rare** | `RARE` | Subject-themed heroes | Moderate | **Credits purchase + mild learning gate**: `level ≥ 6` AND `topics_assessed ≥ 3` | 2,500–4,000 Credits | Cyan `AppColors.secondary` rim |
| **Epic** | `EPIC` | Mastery specialists | Scarce | **Learning threshold** (MODEL C — no purchase, see §8): `level ≥ 12` AND `syllabusCompletion ≥ 50%` in ANY subject AND `current_streak_days ≥ 7` | Not purchasable — prestige only | Purple `AppColors.primary` + soft glow |
| **Legendary** | `LEGENDARY` | Icons of mastery | Very scarce | **Compound mastery gate** (§8): `level ≥ 18` AND `syllabusCompletion ≥ 70%` (precise §8) in the character's *home subject* AND `bossBattlesCompleted ≥ 5` AND `current_streak_days ≥ 7` (or longest ≥14). Full matrix in §8.3. | Not purchasable — prestige only | Gold `AppColors.xp` + outer glow + crown accent |
| **Prestige** | `PRESTIGE` | Season / completion legends | Ultra-rare, limited | Post-100% syllabus OR seasonal #1 — awarded, never sold. Defer to v2 season spec. | Award-only | Animated gold-purple gradient (web/desktop only; static on mobile) |

**Counts (launch):** Initiate 2 + Common 7 + Rare 6 + Epic 5 + Legendary 4 = **24**. Balanced so every level band earns a visible collection win without overwhelming choice.

### 7.3 Per-tier definition checklist (normative template for each avatar row)

Each `avatars` row MUST document: `code`, `displayName`, `rarity`, `homeSubjectId?` (Epic/Legendary), `assetKey` (vector), `rarityColor`, `unlockType {AUTO_GRANTED, CREDIT_PURCHASE, MASTERY_THRESHOLD}`, `requirementJson` (machine-readable gate, see §8.2), `creditCost` (null for threshold tiers), `description` (lore, ≤120 chars), `isActive`, `displayOrder`.

Cosmetic-only invariant: rarity never affects gameplay power, XP multipliers, or rank. All tiers are **identity + motivation only** — stated in every store screen so learners never suspect pay-to-win.

### 7.4 Original character examples (illustrative, art to be produced)

| Code | Name | Tier | Home subject | Lore snippet |
|---|---|---|---|---|
| `initiates_spark` | Nova Spark | Initiate | — | "Curious, bright — your first companion." |
| `initiates_scout` | Byte Scout | Initiate | — | "Trail-ready explorer of new worlds." |
| `common_coder` | Lumen Coder | Common | — | "Types fast, learns faster." |
| `rare_net_ranger` | Net Ranger | Rare | Computer Networks | "Patrols the OSI layers." |
| `epic_algo_sage` | Algo Sage | Epic | Data Structures | "Sees patterns before they form." |
| `legendary_db_oracle` | Oracle of Data | Legendary | DBMS | "Demands 70% mastery of data realms." |

Actual codes/assets are defined in migration `V17__create_avatars.sql`; the table above is the *shape*, not a license to invent extra columns.

---

## 8. Character Economy — Part F (Analysis + Chosen Model)

### 8.1 Model comparison table (evaluated before decision)

| Model | Mechanism | Learning XP impact | Motivation effect | Competition fairness | Implementation cost |
|---|---|---|---|---|---|
| **A — Spend XP directly** | Deduct `total_xp` on purchase | **Destructive**: level can drop, rank drops, violates Gamification Spec invariant "level NEVER decreases" (§6.1) and breaks motivation (punishment for collecting) | Feels like a tax; learners hoard XP instead of engaging | Rank manipulable: buying cosmetics lowers competitive score | Low |
| **B — Earn XP → earn Credits (separate currency)** | Credits derived from XP events, spent independently | **Non-destructive**: `total_xp`/`current_level` immutable; Credits are the only spendable | Clean "learn → earn → spend" without regret; hoarding pressure removed | Rank unaffected by purchases — fair | Medium (new ledger) |
| **C — Threshold unlock (no spend)** | Avatar becomes ownable when `total_xp ≥ T` or `syllabusCompletion ≥ p`, claimed free | **Non-destructive**, but lacks a sink — no economy, collection completes too fast | Prestige is clear, but no ongoing credit chase for mid-tier | Fairest, but less economy play | Low |

### 8.2 RECOMMENDATION — Hybrid B+C (binding)

> **Common + Rare tiers → Model B (Credit purchase).**
> **Epic + Legendary + Prestige tiers → Model C (mastery-threshold claim, zero Credits involved).**

**Rationale:** This satisfies the user's request ("purchasable based on XP") without violating the Gamification Spec's monotonic-level guarantee. Mid-tier collection provides a *healthy, capped* spend sink; top-tier prestige remains unpurchasable so it can never be farmed or bought — it must be learned. The split also neatly maps to "Credits = engagement reward, Legendary = mastery proof," which is the `LEARNING FIRST` axiom (§Y).

### 8.3 Credit economy rules (Model B)

| Rule | Value |
|---|---|
| **Source of Credits** | Derived deterministically at award time: `creditsEarned = floor( xpAwarded * 0.60 )` for every `xp_transactions` row (same TX that wrote XP). Achievement/streak/boss-bonus XP also converts. `0.60` is a compiled constant (mirrors Gamification Spec style); tuning requires a spec bump. |
| **Balance storage** | `user_credits.balance INT NOT NULL DEFAULT 0` (new table §15) — **not** `learner_profiles.total_xp`. Appended via `credit_ledger(id, user_id, amount, reason, reference_type, reference_id, created_at)` (append-only, auditable, mirrors `xp_transactions`). |
| **Spend** | `user_avatars` insert does: `UPDATE user_credits SET balance -= avatar.credit_cost` in the **same TX** as the unlock row. Balance check is `balance >= cost` under `SELECT ... FOR UPDATE` on `user_credits`. `CHECK (balance >= 0)` at DB. |
| **No negative Credits** | Allowed to reach 0, never negative. No debt. |
| **No real-money path** | No purchase endpoint accepts currency. Any future monetization requires a distinct owner spec amendment. |
| **No XP-credit exchange back** | Credits never convert to XP. One-way only (prevents XP inflation via credit loops). |

Trade-offs documented: Credits add one ledger + one balance column but prevent the destructive-level bug of Model A; the derivation multiplies writes per game/quiz TX by one ledger insert — acceptable under §17.

### 8.4 Why Model A is REJECTED (normative)

Model A would force `learner_profiles.total_xp -= cost`, violating Gamification Spec §4.2 ("XP decrease: FORBIDDEN") and §6.1 ("Levels can NEVER decrease"). The spec authorizer would need to amend the APPROVED gamification baseline — rejected for v1.

---

## 9. Learning-Based Character Unlocks — Part G

### 9.1 Threshold semantics (Epic / Legendary / Prestige only)

Each avatar's `requirementJson` (stored in `avatars.requirement_json JSON`) is evaluated **server-side** on every profile-relevant write (quiz submit, game result, path-node completion, assessment). Evaluation is cheap: it reads already-indexed rows (`learner_profiles`, `topic_mastery`, `progress`, `learning_path_nodes`, `game_results`, `streaks`, `user_achievements`) — no ad-hoc aggregation.

### 9.2 Gate dimensions (all Epic+ avatars use a subset; Legendary requires all that apply)

| Dimension | Column(s) read | Example rule | Notes |
|---|---|---|---|
| **Syllabus completion** | `§12` precise metric | `syllabusCompletion(homeSubjectId) >= 70` (Legendary) / `>= 50` (Epic) | The dominant long-term lever; not gameable by repetition (§12). |
| **Subject mastery avg** | `AVG(topic_mastery.mastery_score)` per subject | `subjectMasteryAvg(homeSubjectId) >= 62.00` (Legendary) | Ensures completion is not hollow; aligns with Adaptive thresholds. |
| **Level threshold** | `learner_profiles.current_level` via `level(total_xp)` | `level >= 18` (Legendary), `>= 12` (Epic) | Monotone T(n) — never decreases. |
| **Assessment requirement** | `topic_mastery.attempt_count` / `overall_mastery` subset | `topicsAssessedInSubject(homeSubjectId) >= 4` | Proves assessment-based mastery, not just path clicks. |
| **Game requirement** | `game_results WHERE game_type='BOSS_BATTLE' (or PUZZLE_ARENA) completed=true` | `bossBattlesCompleted >= 5` (Legendary) / `anyGameWins >= 10` (Epic) | Requires **Boss Battle** specifically for Legendary — the hardest game — so prestige maps to breadth. |
| **Streak requirement** | `streaks.current_streak_days / longest_streak_days` | `currentStreak >=7 OR longest >=14` | Habit signal, not grind — streak already capped per Gamification Spec. |
| **Achievement requirement** | `user_achievements JOIN achievements` | `hasAchievementCode('FIRST_MASTERED')` OR `topicMasteredCount >= 2` | Ties character identity to the existing achievement system. |
| **Global invariants** | `users.status='ACTIVE'` | Always checked | Suspended users cannot claim. |

### 9.3 Legendary example (full gate, from §7.2)

```
LEGENDARY — Oracle of Data (DBMS)
Requires ALL of:
  ✓ level >= 18
  ✓ DBMS syllabusCompletion >= 70%   (precise §12 definition)
  ✓ DBMS subjectMasteryAvg >= 62.00
  ✓ topicsAssessedInSubject(DBMS) >= 4
  ✓ bossBattlesCompleted >= 5
  ✓ (currentStreak >= 7 OR longest >= 14)
  ✓ hasAchievement('FIRST_MASTERED') OR masteredCount >= 2

LOCKED panel: requirement checklist per-row (✓/✗) + CTA "KEEP LEARNING → DBMS"
Claim action: POST …/avatar/{id}/claim  (see §16, no body)
Reward: inserts user_avatars row, no Credit cost, emits ACHIEVEMENT-like celebration
```

Every other Epic/Legendary avatar uses the **same shape** with `homeSubjectId` swapped and tier-lowered thresholds for Epic. The checklist UI always reads the same `requirementJson` the backend evaluated — no drift.

### 9.4 Using real backend data — invariant

No field in `requirementJson` is client-supplied; all comparators reference server tables. Any new dimension requires a spec bump before it can be persisted.

---

## 10. 70%+ Syllabus Rule — Part H (Precise Definition)

### 10.1 What “syllabus completion” MEANS (approved definition)

> **`syllabusCompletion(subjectId, userId)` = `completed_topics(subjectId, userId)` ÷ `total_active_topics(subjectId)` — both counts derived from `topics` + `progress` + `learning_path_nodes`, expressed as `DECIMAL(5,2)` percent 0.00–100.00, `HALF_UP` to 2dp (same rounding mandate as Gamification Spec).**

| Term | Precise derivation |
|---|---|
| **`total_active_topics(subjectId)`** | `COUNT(topics.id) WHERE topics.subject_id = subjectId AND topics.is_active = true` — single canonical subject topology. Inactive/legacy topics never count (so the denominator does not inflate with deprecated content). |
| **`completed_topics(subjectId, userId)`** | `COUNT(DISTINCT topics.id) WHERE topics.subject_id = subjectId AND topics.is_active=true AND EXISTS (progress row for (userId, topicId) WHERE progress.status='COMPLETED' AND progress.completion_percentage = 100.00)` — i.e., the learner's `progress` table explicitly marks the topic done. **NOT** "opened once", NOT "50% viewed", NOT "any attempt exists". |
| **When `progress` is absent but `learning_path_nodes` is COMPLETED** | The `ProgressService` already mirrors node completion into `progress` (the `learning_path_node_id` FK + status). So `progress` is sufficient as the single collector; querying both is redundant. If `progress` for a topic is missing, it counts as incomplete. |
| **Weighted vs unweighted** | **Unweighted v1** — every active topic counts equally. Weighted-by-difficulty/mastery variants are deferred (`open decision OD-1`). Equal weight keeps the 70% intuitive and mirrors `progress` existing semantics. |
| **Assessment-only topics** | If a topic has no path node but assessment established `topic_mastery` for it, `progress(status='COMPLETED')` can still be written by the assessment completion path (see `ASMT-002` aftermath in §15.6) — so mastery baselines that bypass the path still earn syllabus credit, preventing a dead-end where assessment learners can never reach 70%. |

**Why NOT the alternatives:** weighted-by-mastery would make Legendary require *mastering* 70% rather than *completing* 70% (too punitive for v1); `learning_path_nodes` alone is per-path and may not contain every topic; `progress` is the only existing per-user-per-topic completion ledger already in the spec.

### 10.2 Threshold application

- `≥ 70.00%` means eligible (inclusive, mirror of Gamification boundary inclusivity). 69.99% is **not** eligible — no rounding-up snap. Floating comparison uses `DECIMAL(5,2)` so 69.995 rounds to 70.00 before comparison.
- 100% is legal and expected for `PRESTIGE` tier; no overflow clause needed beyond the cap.
- The same metric backs subject-progress cards (`Journey` %) so the 70% Legendary bar and the dashboard progress bar **agree exactly** (both read `progress`, never two sources).

### 10.3 Persistence & indexing (§15, §17)

`progress(user_id, topic_id)` already indexes the numerator lookup; `topics(subject_id, is_active)` indexes the denominator. A helper DB function/view `user_subject_syllabus_completion(user_id, subject_id)` may be introduced, but the canonical computation stays in service code so tests can assert it directly.

---

## 11. Avatar Purchase System — Part I (States & Actions)

### 11.1 Canonical states (state machine per avatar per user)

```
                    ┌─ REQ_NOT_MET ───────────┐
                    │ (locked, checklist ✗)   │
                    │ CTA: Continue learning  │
                    └──────────┬──────────────┘
                               │ requirements met
                               ▼
PURCHASABLE ◄────────── THRESHOLD_REACHED / CREDITS_SUFFICIENT ?
 (Credit tiers)       (threshold tiers: becomes CLAIMABLE)       OWNED ──► EQUIPPED
  │ insufficient ─► INSUFFICIENT_CREDITS                          │           │
  │ balance    │ CTA: Play & earn                                 │           │
  └────────────┼──────────────────────────────────────────────────┘           │
               │ alreadyOwned ─► OWNED (idempotent GET retains owned)          │
               │ equippingLocked ─► REJECT 403 (server guard)                 │
```

**Exhaustive state vocabulary for UI/API:**

| State | Code | Avatar tier | Condition (server truth) | Primary CTA | Secondary |
|---|---|---|---|---|---|
| `LOCKED` | `REQUIREMENT_NOT_MET` | Any with unmet gate | At least one checklist predicate false | `Continue learning` → subject path | Detail sheet explains each ✗ |
| `INSUFFICIENT_CREDITS` | `INSUFFICIENT_CREDITS` | Common / Rare | Gate met, `balance < creditCost` | `Play to earn` (shows `creditCost - balance` deficit) | `View games` |
| `PURCHASABLE` | `PURCHASABLE` | Common / Rare | Gate met, `balance >= cost`, not yet owned | `Unlock — 1,500 Credits` (explicit cost) | Preview |
| `CLAIMABLE` | `PURCHASABLE` (threshold) | Epic / Legendary | All threshold predicates true, not yet owned | `Claim — free` | Lore |
| `OWNED` | `OWNED` | Any | Row exists in `user_avatars` | `Equip` (if not equipped) | `Preview` |
| `EQUIPPED` | `EQUIPPED` | Any owned | `user_profiles.equipped_avatar_id = avatarId` (see §13) | `Equipped ✓` | `Unequip` (returns to Initiate default) |
| `MAX_PROGRESS_REQUIRED` | Alias of `REQUIREMENT_NOT_MET` with highest-tier hint | Epic/Legendary | Indicates distance: e.g., `level 16 of 18` | Same as LOCKED | — |

Every error maps to a safe `ErrorResponse` with `errorCode` (§16): `INSUFFICIENT_CREDITS (402)`, `AVATAR_REQUIREMENTS_NOT_MET (403)`, `AVATAR_ALREADY_OWNED (409)`, `AVATAR_NOT_OWNED (403)` on equip, `RESOURCE_NOT_FOUND (404)`.

### 11.2 Store card spec

```
CYBER CODER (Rare)                                    [avatar art 72dp, tint cyan rim]
Cost: 1,500 Credits    Your Credits: 7,200   [Credit balance pill — server value only]
[Unlock]  (or)  INSUFFICIENT:  2,180 Credits remaining [progress bar to deficit]

— locked variant —
LEGENDARY AI MASTER   🔒   [desaturated art, lock overlay]
75% syllabus completion required   Current: 61% (from progress, not guessed)
Requirement checklist (✓/✗ per dimension) + [Continue learning → Programming]
```

**Clarity rule:** Every unavailable avatar MUST show *why* (checklist rows). Never a bare "Locked" without explanation.

---

## 12. Profile Integration — Part J

### 12.1 Profile screen architecture (extends existing `ProfileScreen`)

Existing `ProfileScreen` already shows: identity hero (initial-letter badge + Nova), progression `GameChallengeSurface`, `LevelBadge` + `XPBar`, `StatCard` quartet (TOTAL XP / STREAK / BADGES / MASTERY), longest-streak hint, and "What's next" nudges. The avatar collection slots into this **without replacing** anything — it becomes the *identity anchor* at the top and a new collection block before stats.

```
YOUR CHARACTER (replaces the lone initial-letter badge as hero, backward compatible)
┌─ Hero (full-width FeaturedSurface, accent = equippedAvatar.rarityColor) ───────┐
│  [Avatar art 96dp, rarity rim + subtle glow if Epic/Legendary]    [Nova mood]  │
│  NOVA SPARK — Initiate                                             (rarity pill)│
│  Vijay  •  vijay@example.com  (existing)                                        │
│  LEVEL 18  •  7,820 XP   [same pill — never moves]                              │
│  [Change character → opens Collection sheet]                                     │
└────────────────────────────────────────────────────────────────────────────────┘
Progression (existing GameChallengeSurface — unchanged)

CHARACTER COLLECTION (new, always below hero, above stats)
┌─ SectionHeader "Character collection"  (2/24 owned — counter) ─────────────────┐
│  AdaptiveGrid(compact:2, medium:3, expanded:4)  — each tile 96dp art            │
│  OWNED tiles: colored, tappable → [Equip] / [Equipped ✓]                        │
│  LOCKED tiles: desaturated + lock icon, tappable → requirement detail sheet     │
│  PURCHASABLE / CLAIMABLE tiles: tinted border + cost/claim pill                 │
└────────────────────────────────────────────────────────────────────────────────┘
NEXT UNLOCK (single predictive card, always visible when not 100% collected)
┌─ "Next unlock — Cyber Coder (Rare) — 2,180 Credits remaining"                  │
│  [linear deficit bar: balance / cost — server values]  [Play to earn]          │
└────────────────────────────────────────────────────────────────────────────────┘
Stats quartet, streak, badges, mastery (existing — unchanged)
```

### 12.2 States (all handled)

| Collection state | Display |
|---|---|
| **New user (2 Initiates owned, 22 locked)** | Hero shows chosen Initiate; grid shows 2 owned + 22 locked; Next unlock = cheapest Common (`800 Credits remaining` etc.). |
| **Mid collection** | Mix of owned/claimable/locked; filter chips `All • Owned • Purchasable • Locked` (tap to filter, never hides locked entirely). |
| **100% owned** | "Collection complete — you own every champion!" celebratory card + total Credits balance. Tiles all EQUIPPED/OWNED. |
| **Missing avatar asset** | Fallback to initial letter badge (same as heutige `ProfileScreen`) — never a broken image. Logged `AVATAR_ASSET_MISSING`. |
| **Backend failure** | `ErrorState` for that section only — hero falls back to existing initial-letter rendering so the profile still loads. |

---

## 13. Character Equipping — Part K

| Concern | Spec |
|---|---|
| **Current avatar** | `user_profiles.equipped_avatar_id CHAR(36) NULL FK avatars.id` (new column, see §15.7). `NULL` means "default Initiate" (the onboarding pick). Never mandatory. |
| **Owned set** | `user_avatars(user_id, avatar_id, acquired_at, acquisition_type {GRANTED,PURCHASED,THRESHOLD_CLAIM})` — `UNIQUE(user_id, avatar_id)` enforces one ownership. |
| **Equip action** | `POST /api/v1/profile/avatar` (see §16) body `{ avatarId: UUID }` — server validates `user_avatars` row exists and `users.status='ACTIVE'`. On success, `UPDATE user_profiles SET equipped_avatar_id=:id`. Any other value (including another user's avatar) ⇒ `403 AVATAR_NOT_OWNED`. |
| **Default avatar** | On registration, insert one `user_avatars` row for the onboarding-chosen Initiate + set `equipped_avatar_id` to it. If the user never picked, server picks `initiates_spark` deterministically. |
| **Persistence** | Single authoritative write (no client-side "equipped" cache that can drift). |
| **Optimistic UI** | Flutter MAY optimistically swap the avatar in the hero + dashboard immediately, but with a **concurrent rollback**: on `4xx/5xx`, revert + `SnackBar` with `ErrorResponse.message`. The `PROFILE_EQUIP` event never lands in an unconfirmed state across app restarts. |
| **Offline behavior** | Equip is **online-only**. Offline tap shows `Offline — connect to change your champion` (no queued equip, so no spoof window). |
| **Concurrent / race** | `UPDATE user_profiles` is serialized under `SELECT ... FOR UPDATE` on that profile row — same lock already held for XP writes — so equip races serialize. Last committed write wins; deterministic. |
| **Unequip** | `DELETE` semantics: `POST /api/v1/profile/avatar` with `{ avatarId: null }` ⇒ reset to `NULL` (default Initiate visual). Logged `AVATAR_UNEQUIPPED`. |

Server remains authoritative always — any client-side spoof (e.g., editing local `shared_preferences`) is overwritten by the next `/profile` read.

---

## 14. Leaderboard + Avatar Integration — Part L

| Concern | Rule |
|---|---|
| **Avatar data flow** | Leaderboard row's avatar comes from `user_profiles.equipped_avatar_id → avatars.assetKey / rarity` at response-build time. The leaderboard service does ONE `JOIN` (or batched `IN` fetch + map) so it never N+1s. |
| **Freshness** | When a user equips a new avatar while viewing the leaderboard, the next leaderboard fetch (pull-to-refresh or TTL wake) reflects it. No push/stream needed v1; a new-season spec may add SSE if desired. |
| **Caching** | Leaderboard response is cached keyed by `(segment, page, size, includeTop, aliasMode)` for a short TTL (§17); the avatar mapping is part of that cached payload. TTL is short enough (30–60s) that a stale avatar rim is a cosmetic edge, not a consistency violation. Per-user `me` slice is never cached across users — `me` is appended per caller after the shared top/nearby slice. |
| **Consistency** | `profile.equippedAvatar` and `leaderboard.me.avatar` MUST agree when fetched with the same principal in the same session — both read `user_profiles.equipped_avatar_id`. Stale dashboard avatar (cached separately by the Flutter `profile()` repo) revalidates on `didChangeAppLifecycleState(resumed)`. |
| **Default fallback** | `NULL` equipped ⇒ `initiates_spark` asset, slate rim, name derived server-side as "Nova Spark (default)". Never returns `null` avatar in API — always a valid asset key. |
| **Leaderboard avatar hygiene** | Leaderboard never exposes the full `user_avatars` collection — just the equipped one. Profile is the only surface that lists owned vs locked. |

---

## 15. Backend Database Design — Part M

### 15.1 Reuse vs new — principle (normative)

> **Reuse every existing gamification column/table before adding one. New schema is the *minimum* required to close the gaps the spec identifies.**

**Reused (no change):** `users`, `learner_profiles(total_xp, current_level, overall_mastery)`, `subjects`, `topics`, `learning_paths`, `learning_path_nodes`, `quizzes`, `questions`, `quiz_attempts`, `question_attempts`, `topic_mastery`, `progress(completion_percentage, status)`, `xp_transactions`, `achievements`, `user_achievements`, `streaks`, `game_results`, `ai_interactions`, and all `V1–V16` migrations.

**New (minimum):** 4 tables + 1 column addition (§15.3–15.8). Every new table uses `CHAR(36) PK`, `created_at/updated_at` UTC (per Database Spec §§3–4), and FKs to `users`.

### 15.2 `avatars` — catalog (global, seeded, immutable except for approved content adds)

```sql
-- NEW TABLE avatars — GameLearn original IP catalog (global content, not user-owned)
-- NOT CURRENTLY AVAILABLE — NEW IMPLEMENTATION REQUIRED
CREATE TABLE avatars (
    id                 CHAR(36)      NOT NULL,
    code               VARCHAR(80)   NOT NULL,             -- e.g. 'common_lumen_coder'
    display_name       VARCHAR(100)  NOT NULL,             -- 'Lumen Coder'
    description        VARCHAR(200)  NULL,                 -- lore ≤120 recommended
    rarity             VARCHAR(30)   NOT NULL,             -- INITIATE|COMMON|RARE|EPIC|LEGENDARY|PRESTIGE
    home_subject_id    CHAR(36)      NULL,                 -- FK subjects.id, only for EPIC/LEGENDARY
    asset_key          VARCHAR(120)  NOT NULL,             -- vector key, e.g. 'avatar_lumen_coder'
    rarity_color       VARCHAR(9)    NULL,                 -- '#8B5CF6' hex, derives from rarity token
    requirement_json   JSON          NULL,                 -- null for auto-granted/purchasable gates; object for thresholds
    credit_cost        INT           NULL,                 -- null for non-purchasable thresholds
    is_active          BOOLEAN       NOT NULL DEFAULT TRUE,
    display_order      INT           NOT NULL DEFAULT 0,
    created_at         TIMESTAMP     NOT NULL,
    updated_at         TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_avatars_code UNIQUE (code),
    CONSTRAINT fk_avatars__subjects FOREIGN KEY (home_subject_id) REFERENCES subjects (id),
    CONSTRAINT chk_avatars_rarity CHECK (rarity IN ('INITIATE','COMMON','RARE','EPIC','LEGENDARY','PRESTIGE')),
    CONSTRAINT chk_avatars_cost CHECK (credit_cost IS NULL OR credit_cost > 0)
);
CREATE INDEX idx_avatars_rarity ON avatars (rarity, display_order);
CREATE INDEX idx_avatars_subject ON avatars (home_subject_id);
```

`requirement_json` canonical shape for threshold tiers (validated at seed time; unknown field ⇒ seed rejected):
```json
{
  "levelMin": 18,
  "syllabusCompletionMin": 70.00,
  "syllabusSubjectId": "<subject uuid>",
  "subjectMasteryAvgMin": 62.00,
  "topicsAssessedMin": 4,
  "bossBattlesMin": 5,
  "streakCurrentMin": 7,
  "streakLongestMin": 14,
  "masteredCountMin": 2
}
```
Any key absence means "no gate for that dimension." Server validator enforces that EPIC/LEGENDARY rows include a non-null subset; COMMON/RARE rows keep `requirement_json = NULL` and rely on `credit_cost` + `levelMin` check in code.

### 15.3 Extended credit derivation (no new XP column, but one derived write path)

Credits are not a new column on `xp_transactions`. The existing `amount` + `XpEventType` is sufficient — the credit insert reads the same `amount`. No schema change beyond §15.4–15.5.

### 15.4 `user_credits` — per-user balance (1:1)

```sql
-- NEW TABLE user_credits — spendable Credits balance
-- NOT CURRENTLY AVAILABLE — NEW IMPLEMENTATION REQUIRED
CREATE TABLE user_credits (
    id         CHAR(36)  NOT NULL,
    user_id    CHAR(36)  NOT NULL,
    balance    INT       NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_user_credits_user UNIQUE (user_id),
    CONSTRAINT fk_user_credits__users FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT chk_user_credits_balance CHECK (balance >= 0)
);
```

### 15.5 `credit_ledger` — auditable Credit history (append-only, mirrors xp_transactions)

```sql
-- NEW TABLE credit_ledger — auditable Credits history (like xp_transactions)
-- NOT CURRENTLY AVAILABLE — NEW IMPLEMENTATION REQUIRED
CREATE TABLE credit_ledger (
    id             CHAR(36)     NOT NULL,
    user_id        CHAR(36)     NOT NULL,
    amount         INT          NOT NULL,          -- >0 earn, <0 spend, never 0
    reason         VARCHAR(50)  NOT NULL,          -- CREDIT_EARNED | CREDIT_SPENT
    reference_type VARCHAR(50)  NULL,              -- XP_TRANSACTION | AVATAR_PURCHASE etc.
    reference_id   CHAR(36)     NULL,              -- source row id
    description    VARCHAR(255) NULL,
    created_at     TIMESTAMP    NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_credit_ledger__users FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT chk_credit_ledger_amount CHECK (amount <> 0)
);
CREATE INDEX idx_credit_ledger_user_created ON credit_ledger (user_id, created_at);
CREATE INDEX idx_credit_ledger_user_ref ON credit_ledger (user_id, reference_type, reference_id);
```

### 15.6 `user_avatars` — ownership (user × avatar)

```sql
-- NEW TABLE user_avatars — ownership ledger (one-time per avatar)
-- NOT CURRENTLY AVAILABLE — NEW IMPLEMENTATION REQUIRED
CREATE TABLE user_avatars (
    id               CHAR(36)     NOT NULL,
    user_id          CHAR(36)     NOT NULL,
    avatar_id        CHAR(36)     NOT NULL,
    acquired_at      TIMESTAMP    NOT NULL,
    acquisition_type VARCHAR(30)  NOT NULL,        -- GRANTED | PURCHASED | THRESHOLD_CLAIM
    created_at       TIMESTAMP    NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_user_avatars_user_avatar UNIQUE (user_id, avatar_id),
    CONSTRAINT fk_user_avatars__users FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_user_avatars__avatars FOREIGN KEY (avatar_id) REFERENCES avatars (id),
    CONSTRAINT chk_user_avatars_type CHECK (acquisition_type IN ('GRANTED','PURCHASED','THRESHOLD_CLAIM'))
);
CREATE INDEX idx_user_avatars_user ON user_avatars (user_id, avatar_id);
CREATE INDEX idx_user_avatars_avatar ON user_avatars (avatar_id);
```

### 15.7 `user_profiles.equipped_avatar_id` — new column on the *existing* learner_profiles table

The current `LearnerProfile` entity (`learner_profiles`, Database Spec §8) has `current_subject_id` / `current_topic_id` but **no equipped avatar**. Adding a nullable FK is the smallest mutation:

```sql
-- NEW COLUMN — learner_profiles.equipped_avatar_id
-- NOT CURRENTLY AVAILABLE — NEW IMPLEMENTATION REQUIRED
ALTER TABLE learner_profiles
  ADD COLUMN equipped_avatar_id CHAR(36) NULL,
  ADD CONSTRAINT fk_learner_profiles__avatars FOREIGN KEY (equipped_avatar_id) REFERENCES avatars (id);
CREATE INDEX idx_learner_profiles_avatar ON learner_profiles (equipped_avatar_id);
```

JPA side: `@ManyToOne(fetch = LAZY) @JoinColumn(name = "equipped_avatar_id") private Avatar equippedAvatar;` — `Avatar` is a new entity mapping `avatars`.

### 15.8 Leaderboard stat helper — `user_leaderboard_stats` (optional materialization, recommended for movement + season)

If warm-cache is judged insufficient for `rankDelta` / `seasonXp`, add:

```sql
-- NEW TABLE user_leaderboard_stats — per-user leaderboard stat cache (optional v1)
-- NOT CURRENTLY AVAILABLE — NEW IMPLEMENTATION REQUIRED (deferrable to post-launch if warm cache proves sufficient)
CREATE TABLE user_leaderboard_stats (
    id                 CHAR(36)  NOT NULL,
    user_id            CHAR(36)  NOT NULL,
    best_rank          INT       NULL,            -- MIN rank ever
    last_rank          INT       NULL,            -- previous commited rank
    last_rank_at       TIMESTAMP NULL,
    season_xp          INT       NOT NULL DEFAULT 0,
    season_code        VARCHAR(20) NOT NULL DEFAULT 'LIFETIME', -- e.g. '2026-Q3'
    created_at         TIMESTAMP NOT NULL,
    updated_at         TIMESTAMP NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_user_leaderboard_stats_user_season UNIQUE (user_id, season_code),
    CONSTRAINT fk_user_leaderboard_stats__users FOREIGN KEY (user_id) REFERENCES users (id)
);
```

This is the **only** deferred table in the set — the spec marks it OPTIONAL v1 (see open decision OD-3). Leaderboard read queries work without it (they compute rank live); it only *accelerates* movement deltas and future season slices.

### 15.9 What is NOT needed (explicitly NOT added)

- No `leaderboard` or `subject_leaderboard` snapshot table that copies `total_xp` — the source rows already carry total XP, and a snapshot would create a second source of truth.
- No `user_subject_xp` materialization unless live join proves heavy (deferred OD-3).
- No second XP ledger — `xp_transactions` + `credit_ledger` are sufficient.
- No paid-currency table.

### 15.10 Flyway migration IDs

Existing history is `V1`–`V16`. The new migrations MUST be appended as:

```
V17__create_avatars.sql
V18__create_credit_and_avatar_ownership.sql
V19__add_equipped_avatar_to_learner_profiles.sql
V20__seed_avatars.sql              (or application seeder — see §15.11)
```

Never mutate an applied migration.

### 15.11 Seeding rule

Follow `GameLearn_AI_Gamification_Specification.md §8.6` precedent: the 24 avatars are best seeded by an **idempotent application seeder** ("insert if code absent, never overwrite") — not by Flyway DML that would force a schema-spec change if lore text changes. The seeder MUST be deterministic and never touch existing rows.

---

## 16. API Contract Design — Part N (Implementation-Ready REST)

> All new APIs follow the **actual adopted conventions** from `GameLearn_AI_API_Contract.md v1.4.0 §2.1–§2.4`: base `/api/v1`, Bearer JWT mandatory (except `AUTH-001/002`), plain-DTO envelope (no `{success,message,data,timestamp}` wrapper), uniform `ErrorResponse{timestamp,status,errorCode,message,path,requestId,fieldErrors}`, ownership = principal only (no client `userId`), status over `subjects`/`topics` already enforced. No new auth scheme.

### 16.1 Summary matrix (new IDs)

| API ID | Method | Path | Auth | New | Reuses tables | Status (post-spec) |
|---|---|---|---|---|---|---|
| **LB-001** | `GET` | `/api/v1/leaderboard/overall` | Bearer | NEW | `learner_profiles`, `users`, `streaks`, `avatars`, `progress` | SPECIFIED — PENDING APPROVAL/IMPLEMENTATION |
| **LB-002** | `GET` | `/api/v1/leaderboard/subject/{subjectId}` | Bearer | NEW | same + `subjects`, `topics`, `xp_transactions` lineage | SPECIFIED — PENDING |
| **AV-001** | `GET` | `/api/v1/avatars` | Bearer | NEW | `avatars` | SPECIFIED — PENDING |
| **AV-002** | `GET` | `/api/v1/avatars/me` | Bearer | NEW | `user_avatars`, `avatars`, `user_credits`, evaluation of §10 | SPECIFIED — PENDING |
| **AV-003** | `POST` | `/api/v1/avatars/{avatarId}/purchase` | Bearer | NEW | `avatars`, `user_credits`, `credit_ledger`, `user_avatars` | SPECIFIED — PENDING |
| **AV-004** | `POST` | `/api/v1/avatars/{avatarId}/claim` | Bearer | NEW | `avatars` threshold, `user_avatars` | SPECIFIED — PENDING |
| **PROF-003** | `GET` | `/api/v1/profile/avatar` | Bearer | NEW | `learner_profiles.equipped_avatar_id`, `avatars` | SPECIFIED — PENDING |
| **PROF-004** | `POST` | `/api/v1/profile/avatar` | Bearer | NEW | same + `user_avatars` | SPECIFIED — PENDING |
| **LB-003** | `GET` | `/api/v1/me/leaderboard-position` | Bearer | NEW (lightweight alt) | same as LB-001/002 | SPECIFIED — PENDING |

These paths are FINAL pending owner sign-off. `LB-003` is the compact dashboard widget endpoint (§23) so the dashboard does not pull the full leaderboard.

### 16.2 LB-001 — Overall leaderboard

```
GET /api/v1/leaderboard/overall?page=1&size=20&includeTop=true&aliasMode=ALIAS
Authorization: Bearer <token>
Accept: application/json
```

**Query params (binding):**

| Param | Type | Required | Bounds | Default | Notes |
|---|---|---|---|---|---|
| `page` | int | no | 1..1000 | 1 | 1-indexed |
| `size` | int | no | 1..50 | 20 | >50 ⇒ 400 MALFORMED_REQUEST |
| `includeTop` | bool | no | — | true | When true, body merges `top[10]` + requested page + `me` + `nearby` |
| `aliasMode` | enum | no | `RAW\|ALIAS\|ANONYMIZED` | `ALIAS` | Server enforces per-viewer's policy (§17); this hint only controls fallback naming when the viewer lacks a preferred setting |
| `season` | string | no | `LIFETIME` only in v1 | `LIFETIME` | Future seasons (`2026-Q3`) validated against `user_leaderboard_stats.season_code`; unknown ⇒ 400 |

**Response `200` (plain-DTO, NEVER a wrapper):**
```json
{
  "segment": "OVERALL",
  "season": "LIFETIME",
  "page": 1,
  "size": 20,
  "totalPlayers": 842,
  "totalPages": 43,
  "top": [
    { "rank": 1, "displayName": "Ava", "alias": null, "avatar": { "assetKey": "avatar_oracle", "rarity": "LEGENDARY" }, "level": 42, "totalXp": 42840, "streakDays": 28, "mastery": 88.4, "rankDelta": 1 },
    { "rank": 2, "displayName": "Mohan", "alias": "NetRanger", "avatar": { "assetKey": "avatar_net_ranger", "rarity": "RARE" }, "level": 40, "totalXp": 41920, "streakDays": 12, "mastery": 64.1, "rankDelta": -1 }
  ],
  "entries": [
    { "rank": 1, "displayName": "Ava", "avatar": { "assetKey": "avatar_oracle", "rarity": "LEGENDARY" }, "level": 42, "totalXp": 42840, "streakDays": 28, "mastery": 88.4, "isMe": false, "rankDelta": 1 }
  ],
  "me":   { "rank": 17, "displayName": "Vijay", "avatar": { "assetKey": "avatar_spark", "rarity": "INITIATE" }, "level": 18, "totalXp": 7820, "streakDays": 5, "mastery": 41.0, "xpToNextRank": 180, "nextRank": 16, "nextRankXp": 8000, "bestRank": 14, "rankDelta": 2 },
  "nearby": [
    { "rank": 15, "displayName": "Sara", "avatar": { "assetKey": "avatar_sage", "rarity": "EPIC" }, "level": 19, "totalXp": 8120, "streakDays": 0, "mastery": 72.0, "isMe": false, "rankDelta": null },
    { "rank": 16, "displayName": "Kenji", "avatar": { "assetKey": "avatar_coder", "rarity": "COMMON" }, "level": 19, "totalXp": 8000, "streakDays": 3, "mastery": 55.2, "isMe": false, "rankDelta": 0 },
    { "rank": 17, "displayName": "Vijay", "avatar": { "assetKey": "avatar_spark", "rarity": "INITIATE" }, "level": 18, "totalXp": 7820, "streakDays": 5, "mastery": 41.0, "isMe": true, "rankDelta": 2 },
    { "rank": 18, "displayName": "Lena",  "avatar": { "assetKey": "avatar_scout", "rarity": "INITIATE" }, "level": 17, "totalXp": 7640, "streakDays": 1, "mastery": 38.0, "isMe": false, "rankDelta": -2 }
  ],
  "generatedAt": "2026-09-06T09:00:00Z",
  "cacheTtlSeconds": 60
}
```
Notes: `entries` is the requested page slice. When `includeTop=false` and the page is e.g. `page=3`, `top` is omitted but `me` + `nearby` remain. `rankDelta=null` ⇒ new entrant / not enough history. `xpToNextRank = nextRankXp - totalXp` (null when #1 — "PEAK"). All display names respect privacy (§17). `generatedAt` + `cacheTtlSeconds` let Flutter render the "snapshot from <ago>" offline banner.

**Error codes:**

| HTTP | errorCode | When |
|---|---|---|
| 401 | `UNAUTHORIZED` | missing/invalid token, suspended user |
| 400 | `VALIDATION_FAILED` | `size>50`, non-integer `page`, unknown `season` |
| 409 | `DATA_CONFLICT` | concurrent rank write race loser (retry-safe) — extremely rare; caller retries |
| 500 | `INTERNAL_ERROR` | unexpected |
| Never | `404` | Empty leaderboard is 200 with `totalPlayers=0, top=[], entries=[], me={rank=1,…}` |

**Caching & rate limiting (normative):**

- Cache: `Cache-Control: private, max-age=60` + `X-Cache-Status: HIT|MISS`. Per-principal `me`/`nearby` slice bypasses shared cache (appended after shared slice). No `ETag` in v1.
- Rate limit: `LB` buckets — 30 req / user / minute (burst 10). Enforced in-memory per instance with `429 AI_RATE_LIMITED` reuse semantics (new code `RATE_LIMITED` if the registry prefers; either is contract-consistent). Count only successful 200s; 401s don't consume. Honest limitation: single-instance/in-JVM (mirrors PATH-002 §5.6 convention); multi-replica scales effective limit — owner decision if violated.

### 16.3 LB-002 — Subject leaderboard

```
GET /api/v1/leaderboard/subject/{subjectId}?page=1&size=20&includeTop=true
```

- `subjectId` — UUID, must reference `subjects.is_active=true` else `404 RESOURCE_NOT_FOUND` (mirrors `SUBJ-001`).
- Response shape IDENTICAL to LB-001 except `segment: "SUBJECT", subjectId, subjectName, metric: subjectXp` replaces `totalXp`, plus `subjectMasteryAvg`. Eligibility gates from §4.3 apply.

### 16.4 AV-001 — Avatar catalog

```
GET /api/v1/avatars?includeInactive=false
```

`200` JSON array of `avatars` where `is_active` filters. Shape:
```json
[
  { "id": "uuid", "code": "common_lumen_coder", "displayName": "Lumen Coder", "description": "Types fast…", "rarity": "COMMON", "homeSubjectId": null, "assetKey": "avatar_lumen_coder", "rarityColor": "#94A3B8", "requirement": null, "creditCost": 1200, "isActive": true, "displayOrder": 3 },
  { "id": "uuid", "code": "legendary_db_oracle", "displayName": "Oracle of Data", "rarity": "LEGENDARY", "homeSubjectId": "dbms-uuid", "assetKey": "avatar_oracle", "rarityColor": "#FACC15", "requirement": { "levelMin":18, "syllabusCompletionMin":70.0, "syllabusSubjectId":"dbms-uuid", "subjectMasteryAvgMin":62.0, "bossBattlesMin":5 }, "creditCost": null, "isActive": true, "displayOrder": 22 }
]
```
Unauthenticated `401`. No pagination (catalog ≤ dozens). No caching header mandate; Flutter may cache per-session.

### 16.5 AV-002 — My avatars (owned + unlock state per-user)

```
GET /api/v1/avatars/me
```

`200` (single DTO — canonical for profile):
```json
{
  "equippedAvatarId": "uuid-spark",
  "balance": 7200,
  "syllabusCompletion": { "DBMS": 61.0, "Programming": 84.2 },
  "items": [
    { "avatarId": "uuid-coder", "state": "PURCHASABLE", "owned": false, "creditCost": 1500, "balance": 7200, "deficit": 0, "requirements": null },
    { "avatarId": "uuid-oracle", "state": "REQUIREMENT_NOT_MET", "owned": false, "creditCost": null, "requirements": { "levelMin":18, "levelCurrent":16, "syllabusCompletionMin":70.0, "syllabusCurrent":61.0, "subjectMasteryAvgMin":62.0, "subjectMasteryCurrent":48.3, "bossBattlesMin":5, "bossBattlesCurrent":2, "achievements": { "required":"FIRST_MASTERED","have":false } }, "checklist": [ { "label":"Level 18", "met":false, "current":16, "required":18 }, { "label":"DBMS syllabus 70%", "met":false, "current":61.0, "required":70.0 } ] },
    { "avatarId": "uuid-spark", "state": "EQUIPPED", "owned": true, "acquiredAt": "2026-08-24T10:15:07Z", "acquisitionType": "GRANTED" }
  ]
}
```
`state` is the canonical §10 code. `checklist` is non-null for threshold tiers so the UI never second-guesses the backend.

### 16.6 AV-003 — Purchase (Credits spend)

```
POST /api/v1/avatars/{avatarId}/purchase
Authorization: Bearer <token>
Content-Type: application/json
Body: {}           (no field carries XP, Credits, or price — all server-derived)
```

**Validation (server, never client):** avatar exists & `is_active=true` & `credit_cost NOT NULL` & `level >= threshold(levelMin)` & `user_credits.balance >= credit_cost` & not already owned. If any gate fails → matching errorCode, **no side effects, no partial ledger row**.

**Success `201`:**
```json
{ "avatarId":"uuid", "acquiredAt":"2026-09-06T09:12:00Z", "acquisitionType":"PURCHASED", "newBalance":5700, "equippedAvatarId":"uuid" }
```
The row is also marked `equipped` only if the user's previous `equipped_avatar_id IS NULL` (i.e., first purchase doesn't auto-equip away a chosen Initiate). All writes in one TX: `user_avatars` insert + `credit_ledger (amount=-cost)` + `user_credits.balance -= cost`.

**Errors:** `401`, `404 RESOURCE_NOT_FOUND` (avatar unknown/inactive), `402 INSUFFICIENT_CREDITS` (body: `{ required:1500, balance:400, deficit:1100 }`), `403 AVATAR_REQUIREMENTS_NOT_MET` (checklist), `409 AVATAR_ALREADY_OWNED`.

**Idempotency:** re-POST of an already-owned avatar is `409`, not double-spend. A client `Idempotency-Key` header is optional v1; the uniqueness constraint is the safety net.

### 16.7 AV-004 — Claim (threshold unlock, Epic/Legendary)

```
POST /api/v1/avatars/{avatarId}/claim
Authorization: Bearer <token>
Body: {}
```

Identical validation but checks threshold JSON (§10) and `credit_cost IS NULL` expectation. `402` never returned (no cost). Success `201`:
```json
{ "avatarId":"uuid", "acquiredAt":"2026-09-06T09:13:00Z", "acquisitionType":"THRESHOLD_CLAIM" }
```
Single insert `user_avatars` — no Credits touch. Duplicate ⇒ `409`.

### 16.8 PROF-003 — Current equipped avatar

```
GET /api/v1/profile/avatar
```

`200`:
```json
{ "equippedAvatarId": "uuid-spark", "avatar": { "id":"uuid-spark","code":"initiates_spark","displayName":"Nova Spark","rarity":"INITIATE","assetKey":"avatar_spark","rarityColor":"#475569" }, "source": "EQUIPPED" }
```
When `NULL`, `equippedAvatarId` is `null` but `avatar` is the deterministic default (so Flutter never handles a null avatar shape).

### 16.9 PROF-004 — Equip / unequip

```
POST /api/v1/profile/avatar
Authorization: Bearer <token>
Content-Type: application/json
Body: { "avatarId": "uuid" }     // or { "avatarId": null } to reset to default
```

Validation: `avatarId` null ⇒ reset to `NULL` (always allowed). Non-null ⇒ row exists in `user_avatars` for this user ⇒ `UPDATE learner_profiles SET equipped_avatar_id=:id WHERE user_id=:me`. Otherwise `403 AVATAR_NOT_OWNED` (server never trusts a raw avatar id).

Success `200`:
```json
{ "equippedAvatarId":"uuid-coder", "avatar": { "id":"uuid-coder", "displayName":"Lumen Coder", "assetKey":"avatar_coder" } }
```

**Errors:** `401`, `400 MALFORMED_REQUEST` (bad UUID), `403 AVATAR_NOT_OWNED`, `404 RESOURCE_NOT_FOUND`.

### 16.10 LB-003 — Dashboard lightweight position (alternative to LB-001 for dash widget)

```
GET /api/v1/me/leaderboard-position?segment=OVERALL&subjectId=null
```

`200`:
```json
{ "segment":"OVERALL", "rank":17, "totalXp":7820, "level":18, "xpToNextRank":180, "nextRank":16, "bestRank":14, "totalPlayers":842, "top": [ { "rank":1,"displayName":"Ava","avatar":{"assetKey":"avatar_oracle"},"level":42,"totalXp":42840 } ] }
```
This is the **dashboard slot** so `DashboardProvider` does not fetch the full leaderboard (payload < 1 KB).

### 16.11 Contract consistency (API Contract Amendment checklist)

Upon owner approval, bump `GameLearn_AI_API_Contract.md` from `v1.4.0 → v1.5.0` and append rows `LB-001..003`, `AV-001..004`, `PROF-003/004` to the Surface Matrix, register codes `INSUFFICIENT_CREDITS`, `AVATAR_REQUIREMENTS_NOT_MET`, `AVATAR_ALREADY_OWNED`, `AVATAR_NOT_OWNED` (all `4xx` per registry), and re-affirm that no AI_* codes are involved (AI boundary untouched).

---

## 17. Security / Anti-Cheating — Part O (Critical) + Privacy — Part P

> Security follows the **proven precedents** in `GameLearn_AI_Gamification_Specification.md §§13/15` and `GameLearn_AI_API_Contract.md §2.2` — no new auth scheme, no invented token field.

### 17.1 Server authority (binding)

The server is authoritative for: `total_xp`, `current_level`, `subject_xp`, `syllabusCompletion`, `mastery`, `streaks`, `avatar ownership`, `equipped avatar`, `Credits balance`, `rank`, `bestRank`. The client submits ONLY: a quiz/game submission (existing flows), an avatar `avatarId` to claim/purchase/equip, and a leaderboard page request. There is no field in any `LB-*` or `AV-*` request body where a client can supply XP, rank, mastery, syllabus %, or ownership. Adding one would require a spec bump and explicit rejection rules.

### 17.2 Game/quiz result integrity (already enforced, reused verbatim)

- `QUIZ-002` (§9 pipeline) validates, recomputes accuracy with HALF_UP 2dp, persists `quiz_attempts` + `question_attempts`, then processes Adaptive + Gamification in the **same `@Transactional`** with pessimistic row locks (`streaks FOR UPDATE`, profile lock reuse). Any gamification exception rolls back the attempt.
- `GameResult` (`game_results`) carries `client_request_id UUID UNIQUE(user_id, client_request_id)` (`V15`), evaluated server-side XP capped (`amount ≤ 100` per event + `xpAwarded` derived, not client-supplied). Replaying the same `client_request_id` is a no-op (unique constraint → merge/no-op, not duplicate).
- There is **no endpoint that accepts a raw leaderboard score**. The only score that exists is server-derived.

### 17.3 Avatar authority

Every `AV-003/004` + `PROF-004` handler re-validates the gate against live tables *inside* the handling TX under `FOR UPDATE` on `user_credits` / `user_profiles`. A client that edits local `shared_preferences` or patches the app binary cannot appear as owning an avatar they never earned: the next `GET /avatars/me` / leaderboard fetch reveals the spoof, and any equip attempt for an unowned id is `403 AVATAR_NOT_OWNED`. The store screen disables `Unlock` when the server says `REQUIREMENT_NOT_MET` — but the server is the final gate (no TOCTOU).

### 17.4 Duplicate / replay protection

- Quiz/game XP: `UNIQUE(user_id, client_request_id)` + structural one-attempt-per-TX (§13).
- Avatar claims/purchases: `UNIQUE(user_id, avatar_id)` on `user_avatars` + `FOR UPDATE` on `user_credits` (so two concurrent purchases cannot both spend the same balance).
- Leaderboard reads are idempotent GETs by design; no replay risk.

### 17.5 Improbable-score & farming detection (practical, not over-engineered)

| Signal | Heuristic | Action (v1) |
|---|---|---|
| Single-event `amount > 100` | Hard cap already enforced at insert | Rejected, logged `GAM_CREDIT_ANOMALY` |
| Same-day burst (e.g., 40 quiz submits in 10 min) | Log only (legitimate cram sessions exist) | `WARN` log `LB_FARM_SUSPECT` — no auto-ban; owner may tighten to soft rate-limit in v2 |
| Repeated easiest quiz 50× | Mastery weighting already damps recommendation relevance; XP per attempt unchanged (documented accepted exposure in Gamification Spec §4.2) | Accept + document (§Y) |
| `total_xp` regression attempt | Query would need to show `xp_transactions` row with negative `amount` outside `credit_ledger` | Rejected at DB CHECK |

No heuristic auto-suspends a user in v1 — all suspicion is logged for manual review, matching the "do not over-engineer" mandate.

### 17.6 Privacy — Part P (binding)

**Display surface restriction:** Leaderboard JSON exposes ≤ `{displayName|alias, avatar.assetKey, level, xp, streakDays (if public), mastery}`. It never exposes `email`, `users.id` raw beyond internal pagination, `password_hash`, JWTs, `ai_interactions`, or `progress` details.

**Visibility controls** (`user_profiles.leaderboard_visibility` or dedicated `user_privacy_settings` column — whichever survives DB review):

| Mode | Value | Effect |
|---|---|---|
| `PUBLIC` | `PUBLIC` | Appears as `displayName` |
| `ALIAS` | `ALIAS` + `alias VARCHAR(24)` | Appears as chosen alias (sanitized at write: trimmed, profanity check, ≤24); empty alias ⇒ alias = "Champion #<rank>" never leaks real name |
| `PRIVATE` | `PRIVATE` | Excluded from others' `top`/`nearby`/`entries`; still fetchable as `me` by owner |

**Controls:** Settings screen toggle (deferred `USER-002` aligns here — the spec now *defines* the field so `USER-002` has a concrete target). Opting to `PRIVATE` takes effect within one cache TTL (≤60s).

**Data minimization:** Leaderboard queries add `WHERE users.status='ACTIVE' AND user_privacy.visibility != 'PRIVATE'` for the public slices. Search-by-name is NOT provided (prevents enumeration). Profile avatar change does not leak history.

---

## 18. Performance — Part Q (Growth-Ready)

> The dashboard leaderboard (LB-003) must render in **< 200 ms p95** on a DB with 100k users (projected hackathon + course scale) without starving quiz/assessment throughput.

### 18.1 Indexes (normative, additive to Database Spec §29)

```sql
-- Global leaderboard hot path
CREATE INDEX idx_learner_profiles_total_xp    ON learner_profiles (total_xp DESC, id ASC);
CREATE INDEX idx_users_status                 ON users (status);  -- if not already present

-- Per-subject eligibility join (if subject_xp computed by join, else covered by progress)
CREATE INDEX idx_progress_user_topic          ON progress (user_id, topic_id, status);
CREATE INDEX idx_topics_subject_active        ON topics (subject_id, is_active, id);
CREATE INDEX idx_topic_mastery_user_topic     ON topic_mastery (user_id, topic_id);

-- Avatar / credit hot TX
CREATE INDEX idx_user_avatars_user_avatar     ON user_avatars (user_id, avatar_id);
CREATE INDEX idx_user_credits_user            ON user_credits (user_id);
CREATE INDEX idx_credit_ledger_user_created   ON credit_ledger (user_id, created_at);
```

All other needed indexes already exist per §29: `xp_transactions(user_id, created_at)`, `game_results(user_id, game_type)`.

### 18.2 Ranking query shape (illustrative, MySQL 8)

```sql
-- Rank of caller :myId
SELECT COUNT(*) + 1 AS `rank`
FROM learner_profiles lp
JOIN users u ON u.id = lp.user_id
WHERE u.status='ACTIVE' AND lp.total_xp > (SELECT total_xp FROM learner_profiles WHERE user_id = :myId);

-- Page N slice (deterministic order, no filesort under the idx)
SELECT u.display_name, lp.total_xp, lp.current_level, s.current_streak_days,
       lp.equipped_avatar_id, /* + join to avatars */
FROM learner_profiles lp
JOIN users u ON u.id = lp.user_id
LEFT JOIN streaks s ON s.user_id = lp.user_id
LEFT JOIN avatars a ON a.id = lp.equipped_avatar_id
WHERE u.status='ACTIVE' AND /* + privacy filter */
ORDER BY lp.total_xp DESC, lp.created_at ASC, lp.id ASC
LIMIT :size OFFSET :offset;

-- Subject XP slice (computed from lineage if materialized, else live join)
-- The service decides live vs materialized based on measured p95; spec orders both.
```

`COUNT(*)` rank query is `O(log n)` under the descending `total_xp` index; it never scans the full table. `LIMIT/OFFSET` keeps the page slice small; `includeTop` is a second cheap `LIMIT 10`.

### 18.3 Caching strategy

| Layer | What | TTL | Invalidation |
|---|---|---|---|
| **MySQL query cache** | Not used (MySQL 8 QC removed) | — | — |
| **Application in-memory (Caffeine / ConcurrentHashMap)** | Shared `top(10)` + each `(segment, subjectId, page, size)` page slice (anonymous shape without per-user `me`) | **60s** (30s for top-3 to keep podium fresh) | Evict on any `xp_transactions` write that would change top-10 threshold (compare `total_xp` vs `top_10_min` under lock; miss is still correct) |
| **Per-user `me`/`nearby`** | Never cached across users; computed live with the caller lock — appended after shared slice | 0 (live) | — |
| **Flutter** | Last-success `LeaderboardSnapshot` in `shared_preferences` | `cacheTtlSeconds` from API | Shown with "snapshot from <ago>" banner when offline; overwritten on 200 |
| **Avatar catalog** | `GET /avatars` cached per-session in `GamificationRepository` | Session (until app restart) | Seeded content never changes mid-session |

**Dashboard fast path (§23):** `GET /me/leaderboard-position` uses a single rank lookup + `LIMIT 10` top-values — it never pulls `size=20` pages, so it stays < 50 ms server time even cold.

### 18.4 Do-nots

- No leaderboard query on every game frame / every dashboard poll — batch via TTL + `DashboardProvider.refresh()` only.
- No `SELECT *` — all ranking selects are covering indexes (explicit column list).
- Leaderboard must not block quiz-submit TX — it reads `learner_profiles` without locking (repeatable-read snapshot is sufficient for rank).

---

## 19. Responsive Flutter Design — Part S (+ Part R Dashboard Experience)

### 19.1 Breakpoint system (reuse verbatim — do not invent a second grid)

Reuses `frontend/lib/core/theme/app_breakpoints.dart` + `app_gutters.dart`:

| Width | Class | Nav | Content constraint | Leaderboard layout |
|---|---|---|---|---|
| `< 360` (extra-compact) | compact (narrow) | bottom bar | single column, gutters 16 | Podium stacked vertically (#1 → #2 → #3), rank list single col, avatar 48/64dp |
| `360–599` | compact | bottom bar | single column, gutters 20 | Same + champion station sticky bottom bar |
| `600–899` | medium | `NavigationRail` (collapsed) | 1–2 col, gutters 20 | Podium horizontal (2–1–3), rank list 2-col when density helps (optional), nearby sticky bottom |
| `900–1199` | expanded | `NavigationRail` + labels | 2–3 col, max 1120 | Podium wide, rank list 2-col via `AdaptiveGrid(medium:1, expanded:2)`, detail sheet as side panel |
| `1200–1439` | wide | extended rail | 3+ col, max 1200 | Same + dedicated "Your Station" as right rail panel instead of bottom sticky |
| `≥1440` | wide | extended rail | max 1200, centered `ResponsiveCenter` | Same; table never stretches — density capped, not width stretched |

All measurements match the existing `DashboardScreen` responsive contract.

### 19.2 Theme integration (reuse verbatim — no second design system)

| Token source | Role |
|---|---|
| `AppColors` / `AppLightColors` + `AppColorContext` extension | Backgrounds, surfaces, borders, text |
| `AppTypography` (Space Grotesk + Inter) | Display 28/34pt for rank, xpNumber 24, streakNumber, overline for segment chips |
| `app_styles.dart` (`AppRadius`, `AppShadows`, `AppGradients`, `AppGlows`) | Card radius (`AppRadius.lg 20`, `xl 28`), glows for Legendary/Epic rims |
| `game_visual_identity.dart` / `subject_visual_identity.dart` | Avatar rarity accents reuse `GameIdentitySurface(accent: rarityColor)` already in use |
| `app_theme.dart` (`buildGameLearnDarkTheme` / `buildGameLearnLightTheme`) + `theme_controller.dart` | Leaderboard respects `ThemeMode.system|dark|light` identically to dashboard |
| Existing primitives `FeaturedSurface`, `GameIdentitySurface`, `MasteryOrb`, `XPBar`, `StreakChip`, `LevelBadge`, `GameChallengeSurface`, `InteractiveSurface` | Building blocks — no new surface type |

System theme is followed automatically (same handler as `gamification_models.dart`).

### 19.3 Accessibility (normative)

- Rank deltas narrated: `Semantics(label: 'rank up 2')`; podium roles `heading`.
- All avatar tiles `tooltip: '<Name>, <rarity> champion'`.
- Keyboard / switch navigation: segment control + rank list are `FocusTraversalGroup`; Enter/Space actives.
- Animations gated by `AppMotion.reducedMotion(context)` (§9).

### 19.4 Dashboard compact experience — Part R (also the LB-003 spec reference)

The dashboard is **learning-first** — the leaderboard is a *widget*, never the page hero. It sits **after** "Trophy room" / "Streak" but **before** "Recently learned" — consistent with `DashboardScreen` hierarchy (see `_DashboardBody` order). Layout:

```
┌─ SectionHeader "Champions Arena" ┐
│  Segment chip row: GLOBAL [·] DBMS · Programming (scroll) │
│  Rank badge: YOU #17  •  180 XP to #16  [mini XPBar gap] │
│  Top-3 mini-strip: #1 Ava 42,840 · #2 Mohan 41,920 · #3 … (same avatars) │
│  [View full arena →]  (navigates to LB-001) │
└─────────────────────────────────┘
```

- Reads only `LB-003` (§16.10) so it loads in <50 ms and offloads pagination work from the dash.
- Empty single-participant and no-participants states handled (§5.4).
- No ranking overload text — a single line "Climb by learning, not by grinding." below the bar.

---

## 20. Animation / Celebration — Part T (Restrained, Performant, Motion-Safe)

Every animation respects `AppMotion.reducedMotion(context)` — if true, duration becomes `Duration.zero` (`AppMotion.durFor`). All animations keep frame cost to `Opacity` / `Transform.translate` / `ScaleTransition` (cheap) with no heavy `CustomPaint` except the `MasteryOrb` ring already approved.

| Event | Visual | Timing | Interaction | Theme handling |
|---|---|---|---|---|
| **Rank increase** | Row glow (`AppGlows.accent`) pulse + `↑ 2` slide-in from below + miniature `XPEarnedDisplay` count-up of the gap-closing XP | `celebration (950ms)` for glow, `fast (180ms)` for the `↑` chip slide; glow de-emphasizes to 0 in 1.2s | Tap the chip shows "You passed Sara! 8120 → 7820" tooltip; respects `reducedMotion` | Gold on dark uses `AppColors.xp`; light uses `AppColors.primary` wash, never hardcoded yellow |
| **New personal best** | Banner ("New peak — #14!") sliding from top of hero (Translate 18dp + Opacity) + subtle haptic (`Haptics.success()`) | `normal (300ms)` + `staggerUnit (55ms)` per row | Dismissible, auto-hides after 4s | Uses `RewardSurface` wash, same as dashboard hero |
| **Avatar unlock / purchase** | `RewardBadgeFrame(unlocked: true)` scale 0.93→1.0 (`AppMotion.spring`) + `Confetti` if Legendary (2-piece, 650ms, `Reward` curve) | Scale 220ms + glow 280ms; Legendary full 950ms | CTA `Equip now` appears beneath; confetti limited to 12 particles on mobile, 24 on expanded | Dark: gold glow; Light: purple wash + gold border |
| **Avatar equip** | Hero avatar crossfade (`FadeTransition 250ms`) + rarity rim color transition 300ms | 250–300ms total | Haptic `tap()` | Rim color animates via `AnimatedContainer(borderColor)` |
| **Legendary unlock** | Full-screen `FeaturedSurface(accent: xp)` scale-in 0.93→1.0 + `XPEarnedDisplay(large:true)` reveal + streak in background | `celebration 950ms` + `reward 1200ms` for multi-stage (title → art → stats) | Share disabled v1; `View leaderboard` secondary | Premium gradient `AppGradients.brand` + `xp` tint |
| **Achievement milestone tied to rank** | `ChallengeIndicator` progressFraction fill animates linearly 600ms | 600ms linear | — | Same as progression_widgets precedent |

**Guardrails:** no autoplay loops, no infinite bounce, no sound on background tab, no animation chaining beyond 2 stages, no particle effect on compact when `reducedMotion` or low-end GPU implied by `MediaQuery.disableAnimations`.

---

## 21. Data Consistency — Part U (Single Source of Truth)

| Field | Source of truth | Writer path | Reader(s) | Invariant |
|---|---|---|---|---|
| `total_xp` | `learner_profiles.total_xp` (materialized cache of `SUM(xp_transactions.amount)`) | Quiz-submit / game-result TX (`QUIZ-002`, `GameResult` submit) — same TX as `xp_transactions` insert + `total_xp += amount` under profile lock | `GET /gamification/summary`, `GET /dashboard`, `LB-001/002`, `PROFILE` | Frontend never sums `xp_transactions` itself; display always from `total_xp`. |
| `current_level` | `level(total_xp)` via `T(n)` (pure function) | Same TX: `current_level = level(new_total_xp)` after all XP of that pass (including achievement/streak bonuses) | Same | Guaranteed monotonic (Gamification Spec §6). |
| `subject_xp` | `SUM(xp_transactions WHERE lineage.subjectId = subjectId)` (live) | Same TX lineage writes | `LB-002`, subject cards | If materialized view added, it remains derived — no forked truth. |
| `syllabusCompletion` | `COUNT(progress WHERE status=COMPLETED) / COUNT(topics WHERE is_active)` (§10) | `ProgressService` mirrors node completion into `progress`; assessment may also write `progress` for its topics | `AV-002/003/004` gate, subject arc, dashboard Journey | Dashboard + avatar gates read same helper → values must byte-agree. |
| `overall_mastery` | `learner_profiles.overall_mastery = AVG(topic_mastery.mastery_score)` filtered to non-null — maintained by `AdaptiveLearningService` | Adaptive pipeline (phase 5) | `GET /profile`, `LB` enrichment | Gamification never touches it (Gamification Spec §3 invariant). |
| `streak` | `streaks(current, longest, last_learning_date, timezone='UTC' v1)` | Same TX as quiz/game (G4) | `GET /streak`, dashboard StreakChip, LB streak display | Same-day second submit = NO-OP (§8.2). |
| `avatar ownership` | `user_avatars` — one row per owned champion | `AV-003` (Credits), `AV-004` (threshold), `onboarding seeder` | `AV-002`, `GET /profile/avatar`, equip flow | `UNIQUE(user_id, avatar_id)` is the ground truth. |
| `equipped_avatar` | `learner_profiles.equipped_avatar_id` | `PROF-004` under `FOR UPDATE` | `GET /profile/avatar`, `LB-001/002` JOIN, dashboard hero | Leaderboard and profile MUST agree; no parallel store. |
| `Credits balance` | `user_credits.balance` + `credit_ledger` audit | Same TX as XP award (`floor(xp * 0.60)`) + `AV-003` spend | `AV-002`, purchase CTA deficit bar | Never negative; never real-money-sourced. |

**Consistency enforcement:** There is exactly **one correct leaderboard JSON per segment at any instant** (ordering + me + nearby) — two clients fetching the same `(segment, page)` at the same `generatedAt` get the same top/nearby slice (plus diverge only on `me`). Any stale-read contradiction self-heals on next TTL refresh.

---

## 22. Edge Cases — Part V (Explicit Behaviors)

| # | Case | Handling | Where |
|---|---|---|---|
| 1 | New user (0 XP, 0 topics) | Appears as `me: rank = totalPlayers` (or 1 if first), `top` shows other players; subject boards empty-per-subject message. Credits 0. Two Initiates auto-owned. | §3, §16 |
| 2 | Zero XP filter | `WHERE total_xp > 0` for public slices; caller's own row exempt (so a 0-XP user sees themselves, not invisible). | §3 |
| 3 | No leaderboard participants (before any award) | `totalPlayers=0`, `top=[]`, `me: rank=1, totalXp=0, bestRank=1` — no 404, no NaN. | §16 |
| 4 | One participant | Same as above with `top=[me]`, podium collapses to single gold card (§5). | §5 |
| 5 | Tied users (equal `total_xp`) | Distinct ranks by tie-break (§3.2); UI shows tie badge on lower row. `xpToNextRank` for ties is `1` when the above row is tied (minimal advance needed to break away). | §3, §5 |
| 6 | Deleted users (`users.status != ACTIVE`) | Excluded from public slices; if the caller was deleted, `401 UNAUTHORIZED` upstream (Phase 2 auth guard). | §15, §16 |
| 7 | Inactive / suspended users | Same as deleted — `status='SUSPENDED'` filtered (Security precedent). | §15 |
| 8 | Subject with no activity | Subject leaderboard `totalPlayers=0` + empty-state CTA per §5.4. Global leaderboard unaffected. | §5, §4 |
| 9 | User not enrolled in subject (no mastery/progress there) | Absent from that subject's slices (`subject_xp=0` ⇒ filtered); still ranked elsewhere. | §4 |
| 10 | Avatar already owned | `409 AVATAR_ALREADY_OWNED` on repeat purchase/claim; `GET /avatars/me` still shows `OWNED/EQUIPPED`. | §16 |
| 11 | Insufficient Credits | `402 INSUFFICIENT_CREDITS` body with `{required, balance, deficit}`. No ledger write. UI shows deficit bar. | §16 |
| 12 | Threshold gate exactly 70% (inclusive) | Eligible. Comparison is `completion >= 70.00` with `HALF_UP` 2dp rounding before check (§10). | §10 |
| 13 | 69.99% (and 69.995 → 70.00 edge) | `69.99` ⇒ not eligible. `69.995` rounds to `70.00` ⇒ eligible (HALF_UP). Implementation tests must pin this. | §10 |
| 14 | 100% syllabus completion | `PRESTIGE` tier claim path; collection "Complete!" banner. No overflow. | §7, §10 |
| 15 | Maximum level (50, T(50)=122,500) | Leaderboard `me.xpToNextRank = null`, state `PEAK`; still accumulates XP and may outrank others at 50. Credits keep converting. | §3, §16 |
| 16 | Missing avatar asset (deleted/unknown `assetKey`) | Render falls back to initial-letter badge `AppGradients.brand` (§12); log `AVATAR_ASSET_MISSING` WARN; never crash. | §5 |
| 17 | Backend failure (rank query / avatar gate) | Ranking section falls back to `ErrorState` (§5); profile falls back to initial-letter hero; no invented retry storm (exponential backoff 1s/2s/4s). | §5 |
| 18 | Network timeout (leaderboard fetch >5s) | Flutter timeout + `ErrorState(retry)`; stale cache renders underneath with offline banner if present. | §5 |
| 19 | Stale leaderboard (cache ahead of write) | `generatedAt + cacheTtlSeconds` tells Flutter how stale it is; discrepancy self-heals on TTL miss or manual pull. No 409 for readers. | §17 |
| 20 | Simultaneous XP updates (two quiz submits concurrent) | Serialized on `streaks FOR UPDATE` + `learner_profiles` lock (Gamification Spec §13.1). Both award, rank delta reflects both after commit. No lost update. | §15 |
| 21 | Duplicate game result submission (same `client_request_id`) | `UNIQUE(user_id, client_request_id)` merge/no-op (existing `V15` pattern) — no duplicate XP/credit, no duplicate ledger rows. | §15 |
| 22 | `lesson_completions` lag vs `progress` after path migration | `progress` is canonical (§10); if a code path writes nodes but not `progress`, that topic counts as incomplete until backfilled. Idempotent backfill script is an operational task, not schema. | §10 |
| 23 | Anonymous / alias collision (two users picked same alias) | Aliases need NOT be unique — multiple "Shadow" aliases can rank adjacent; disambiguated only by avatar + rank. | §17 |
| 24 | Clock rollback / future `last_learning_date` | Treat as same-day NO-OP (`GAM_STREAK_ANOMALY` log) per existing spec §8.1. Rank unaffected. | §15 |

---

## 23. Implementation Order — Part W (Roadmap, Dependency-Correct)

Each phase is **independently testable with contract tests already in the spec** — no "big bang."

| Phase | Title | Scope (backend unless noted → Flutter) | Gate to next phase |
|---|---|---|---|
| **L1** | **Schema + entities** | `V17` `avatars`, `V18` `user_credits` + `credit_ledger` + `user_avatars`, `V19` `equipped_avatar_id` FK, `V20`/`seeder` 24 rows, `Avatar`/`UserCredit`/`CreditLedger`/`UserAvatar` entities + repositories | `mvn verify` passes incl. `Flyway` + `H2` + FK/index assertions |
| **L2** | **Credits engine** | Hook into existing quiz/game completion TX: `creditsEarned = floor(xp*0.60)` → `credit_ledger` + `user_credits.balance` (lazy create), `FOR UPDATE` on `user_credits`; no leaderboard touch | Unit tests `Credits_01..08` below; no leaderboard query regression |
| **L3** | **Avatar ownership & equip APIs** | `AV-001..004`, `PROF-003/004`, threshold evaluator (`requirementJson` runner + `syllabusCompletion(subjectId)` helper per §10), seeder idempotency, global error codes `402/AVATAR_*` | API contract tests (AV-003/004 success + every 4xx in §16); equip idempotency |
| **L4** | **Leaderboard APIs** | `LB-001`, `LB-002`, `LB-003` ranking reads (indexes §17.1, `COUNT(*) > totalXp` rank, `ORDER BY total_xp DESC`, top/nearby synthesis, privacy filter, caching 60s) — reads only `learner_profiles.total_xp`/`progress`/`subjects` + `avatars` JOIN; no writes | LB ranking/tie/pagination/me/nearby tests (§23 matrix); cache bust on new award satisfies |
| **L5** | **Flutter — data + state layer** | `LeaderboardModels`, `AvatarModels`, `LeaderboardRepository`, `AvatarRepository`, Riverpod `leaderboardProvider` / `avatarCollectionProvider` / `dashboardLeaderboardProvider`, stale-cache + TTL banner | `HttpMock` unit tests for every `200/4xx` payload in §16 |
| **L6** | **Flutter — Avatar collection UI** | Collection grid, store states (`LOCKED`→`PURCHASABLE`→`OWNED`→`EQUIPPED`), requirement detail sheet, deficit bar, equip optimistic/rollback, `AvatarArt` fallback | Widget tests (all states §10–11, accessibility labels, asset fallback) |
| **L7** | **Flutter — Leaderboard UI** | `ChampionsArenaScreen` (podium, rank list, your station), segment chip filter, pull-to-refresh, `SkeletonList`/`ErrorState` reuse, podium responsiveness | Golden tests for 360/390/768/1024/1280/1440 per §19; motion-safe tests |
| **L8** | **Flutter — Profile & dashboard integration** | Profile hero refactor (§12), `NEXT UNLOCK` card, dashboard `Champions Arena` widget (§19.4, LB-003), `ShellScreen` tab awareness (no new tab for leaderboard — Leaderboard is a **full-screen feature route** like Path/Topic) | Integration tests (`go` → purchase → equip → leaderboard reflects new avatar) |
| **L9** | **Animations & motion** | Rank-up glow, Legendary reveal, `reducedMotion` gates, haptics, max 2-stage chaining (§9) | `flutter test --dart-define=reducedMotion` conformance |
| **L10** | **Security, privacy, perf hardening + v1 sign-off** | `FOR UPDATE` audit on avatar/credit TX, visibility settings storage (USER-002 link), index EXPLAIN regression, `LB` rate limit, penetration of forged-XP paths, offline-banner + cache-Tweaks | Full matrix green (§23–§24); owner sign-off → spec version `1.0.0 APPROVED` |

**Router decision (L8):** No new bottom tab. Leaderboard is `/arena?segment=OVERALL` (full-screen); the dashboard widget links out via `context.push('/arena')` + segment chips. Avatars live on the profile route — `/profile` *is* the collection page (so the 4-tab shell stays clean).

---

## 24. Test Strategy — Part X (Deterministic, IDs for Implementation)

### 24.1 Backend

**Unit — Credits engine**

| ID | Case | Expected |
|---|---|---|
| `CRED-01` | quiz perf XP 10 ⇒ `floor(10*0.6)=6` credits earned, ledger `CREDIT_EARNED` | `user_credits.balance` +6, `credit_ledger` 1 row |
| `CRED-02` | zero-perf quiz (10 XP only) ⇒ 6 | same |
| `CRED-03` | repeated attempt awards again | distinct ledger rows, balance sums |
| `CRED-04` | achievement bonus 20 XP ⇒ +12 credits (same factor) | derivation applies to every `xp_transactions` row |
| `CRED-05` | max-level extra awards still convert | levels never gate credits |
| `CRED-06` | purchase spend debits | `balance -= cost`, `CREDIT_SPENT` row, balance never negative |
| `CRED-07` | insufficient purchase | 402, zero ledger row, balance unchanged |
| `CRED-08` | duplicate purchase race | first commit wins, second 409, exactly one spend row |

**Unit — Avatar threshold evaluator**

| ID | Case | Expected |
|---|---|---|
| `AVT-01` | 69.99% syllabus ⇒ LAIR requirement not met | `REQUIREMENT_NOT_MET` with exact `syllabusCurrent=69.99` |
| `AVT-02` | 70.00% inclusive + all other gates ⇒ claimable | `CLAIMABLE` |
| `AVT-03` | 69.995% → rounds to 70.00 ⇒ claimable | HALF_UP 2dp applied before compare |
| `AVT-04` | assessment-only topic that still has no `progress` row ⇒ counts as incomplete | no credit until ProgressService writes `COMPLETED` |
| `AVT-05` | inactive topic excluded from denominator | `total_active` drops, % recomputes |
| `AVT-06` | `homeSubjectId` mismatch (user mastered another subject) | other subject's 70% irrelevant |

**Integration — Leaderboard ranking**

| ID | Case | Expected |
|---|---|---|
| `LB-01` | 5 users sorted `500, 400, 400(tie), 300, 0` | Ranks 1,2,3,4,5 with tie-badge on rank 3 |
| `LB-02` | tie earlier-created ranks higher | `created_at ASC` salting validated |
| `LB-03` | caller is #17 outside page 1 | `me` returned with `rank=17, xpToNextRank=180` (live rows) even though `entries` is page 1 |
| `LB-04` | nearby window at top-3 edge | expands downward (ranks 1..5) not off-by-one |
| `LB-05` | subject leaderboard filters `subject_xp>0` | users with 0 in that subject absent from that subject board |
| `LB-06` | private user not in others' `top` | filtered by visibility flag, but private caller still sees `me` |
| `LB-07` | pagination bounds (`size=51` ⇒ 400, `page=0` ⇒ 400) | validated per registry |
| `LB-08` | aliasMode sanitization | long alias trimmed, profanity-filtered |
| `LB-09` | dashboard LB-003 shape | payload <1 KB, single-rank + top-3 |

**Security**

| ID | Case | Expected |
|---|---|---|
| `SEC-LB-01` | `POST /leaderboard` with `{totalXp:99999}` | field does not exist ⇒ 400/ignored |
| `SEC-AV-01` | equip avatar not owned | 403 AVATAR_NOT_OWNED |
| `SEC-AV-02` | purchase with spoofed `creditCost` in body | body has no such field ⇒ ignored; server price governs |
| `SEC-AV-03` | directly `UPDATE learner_profiles.equipped_avatar_id` via invented endpoint | endpoint does not exist |
| `SEC-CR-01` | two concurrent purchases double-spending same balance | one 409 race loser |
| `SEC-RB-01` | leaderboard result does not leak email / `user.id` | assert DTO allowlist |

**DB migration**

| ID | Case | Expected |
|---|---|---|
| `MIG-01` | `V17..V19` apply idempotently on H2 + MySQL TC | clean `Flyway migrate` |
| `MIG-02` | duplicate FK/idempotency checks on `V18` `CHECK(balance>=0)` | inserted negative row rejected |
| `MIG-03` | avatar seeder rerun does not overwrite lore edits | "insert if code absent" holds |

### 24.2 Flutter

| Suite | IDs | Scope |
|---|---|---|
| Unit (repos/models) | `F-LEAD-01..06` | `LeaderboardSnapshot.fromJson` every `200/4xx` in §16, rank-gap math, `CreditsBalance` deficit bar math, `SyllabusCompletion` 69.99/70.00 parsing, `AvatarState` → CTA label mapping |
| Widget | `F-W-01..12` | ChampionsArena: podium, rank list, `YOUR STATION`, `LOCKED/OWNED/EQUIPPED` tiles, asset-fallback initial letter, `ErrorState` + retry, offline banner, `reducedMotion` suppresses stagger, `Semantics` labels per card |
| Responsive / theme | `F-R-01..08` | Golden/pixel tests at 360, 390, 768, 1024, 1280, 1440 in light+dark+system; no overflow; every card uses theme tokens (grep-no-raw-`Color(0xFF` except token file) |
| Integration | `F-I-01..03` | `purchase → equip → leaderboard avatar reflects` (mocked API), `rank-up banner` fires on mocked delta, `private` mode hides from sibling principal |
| Regression | `F-REG-01` | dashboard never pulls `LB-001` (assert LB-003 was called when dashboard mounted), no fabricated XP/rank numbers appear while loading |

Coverage target for new code: ≥ 80% branch on backend engines (credits, threshold, ranking); ≥ 70% on Flutter leaderboard/avatar widgets.

---

## 25. Product Balance — Part Y (Safeguards That Keep Learning First)

| Risk | Why it matters | Safeguard (already in spec, normative) | Residual exposure + owner decision |
|---|---|---|---|
| **Grinding easy games** | Replaying trivial Quiz Battle could inflate `total_xp` faster than deep learning | XP capped 25/attempt + no XP→level regression to "repair" grind; recommendation engine relevance is dampened by adaptive mastery weights (Gamification Spec §7.3 accepted-exposure G2) — grinding never improves `subjectMasteryAvg` or `syllabusCompletion` so Legendary stays unreachable | Low — accepted and documented (G2). Future tuning: diminish `QUIZ_PERFORMANCE` factor after N attempts on same topic (requires owner decision OD-4). |
| **XP farming via game spam** | Games already award `xpAwarded` server-side and one `credit` per award; loop could chase Credits for Common buys | Credits derive linearly (`floor(xp*0.6)`) with no bonus for spamming; `game_results` carries `duration_seconds` already so a future `minDuration` gate can be added without schema | Low |
| **Leaderboard manipulation** | Rank is valuable → incentive to forge submissions | Server-authoritative everywhere (§17); no writable leaderboard field; `client_request_id` uniqueness blocks replay awards; `FOR UPDATE` on credits blocks double-spend | None in v1 under honest single-instance |
| **Spending all progression on cosmetics** | Fear behind "spend XP" design | **Hybrid B+C removes it entirely:** threshold tiers cost 0, credit tiers cannot touch `total_xp`/`current_level`. A learner who buys every Common/Rare still has identical XP and rank as before — collection is orthogonal to mastery | None |
| **Unhealthy competition / anxiety** | Leaderboards can demotivate low performers | Positive-only language ("Climb by learning…", no "Bottom 3", rank drops never pushed, movement banners only on climbs ≥1, empty states use encouragement + learning CTA). `PRIVATE` opt-out removes anxiety entirely | Low |
| **Collection anxiety / completionism** | Showing 22 locked avatars may feel overwhelming | Collection groups by rarity + filter chips; the persistent `NEXT UNLOCK` single predicts the *closest* win, so scanning is optional. 100% completion badge celebrates the few — never harms the many | Low |

**Overarching axiom (testable):** An hour of real assessment/path progress (unlocking 50% syllabus of a new topic) must yield more *unlock progress* (toward Epic/Legendary) than an hour of repeating any game on a mastered topic. This holds under the current numbers because only `syllabusCompletion` + `subjectMasteryAvg` gate Legendary, and neither climbs through repetition.

---

## 26. Explicit Assumptions (Normative)

1. **Single-instance frontend–backend assumption** — Rate-limit, ranking-cache, and streak `LocalDate.now("UTC")` rely on single-clock/in-JVM enforcement, matching PATH-002 §5.6 honest limitation. Multi-replica would need a shared cache store — owner decision if reached.
2. **`progress` is canonical for syllabus** — Assumes `ProgressService` already mirrors `learning_path_nodes` statuses to `progress` (which it does today via `learningPathNode_id` links) and that assessment can write `progress COMPLETED` for its topics (§15.6 fallback).
3. **Subject with no topics** — Such a subject is *not* seeded as `is_active`; subject leaderboard would 200 with empty. Product will never publish an active subject with zero active topics.
4. **GameResult topic linkage exists** — `game_results` today stores `game_type` + implicit topic context via the path-referenced topic the game was launched from; the service that awards Credits persists the *origin topic_id* alongside the result so §4 lineage is joinable (the existing `GameResultRepository` widened minimally).
5. **No real-money currency exists or will be implied by UI** — Any monetization requires a distinct spec; the `credit_ledger` reason codes strictly exclude `PURCHASE_WITH_MONEY`.
6. **Max 24 avatars at v1** — Enough to feel collected, small enough that widget tests golden-cover every state without combinatorial explosion.

---

## 27. Open Decisions (Owner Sign-Off Required Before Implementation)

| ID | Question | Proposed answer in this spec | Impact if answered differently |
|---|---|---|---|
| **OD-1** | Should syllabus completion weight topic difficulty? (|EASY| < |HARD|) | **No in v1** — unweighted (§10). | Weighted would require a difficulty→weight table and mutate Legendary gates for the same effort. |
| **OD-2** | Exact Legendary 70% vs 75%? | **70%** (matches prompt phrasing; inclusive). | 75% would just swap the constant in `requirement_json`; no structural change. |
| **OD-3** | Live subject-XP join vs materialized `user_subject_stats` cache? | **Live join for v1**; materialize only if §17 benchmark exceeds 200 ms p95. Optional table in §15.8 is the approved deferrable fallback. | Materialization needs a background recompute job — new infra scope. |
| **OD-4** | Soft anti-grind: diminishing performance XP after N repeats on same topic? | **Deferred** — accepted exposure per G2 above. | Would touch `XpAward` formula constants — requires Gamification Spec bump downstream of v2 data. |
| **OD-5** | Avatar catalog source — Flyway DML vs application seeder? | **Application seeder (insert-if-code-absent)** following Gamification §8.6. | Flyway would lock lore edits to migration files. |
| **OD-6** | Season cadence (quarterly, monthly, None) for `season_xp`? | **Lifetime only in v1**; season code defaults to `LIFETIME` and `user_leaderboard_stats` row is stubbed. | Activating seasons requires LF bump `LB-*/season` + cron to rotate `season_code`. |
| **OD-7** | Alias profanity policy — which wordlist? | **Server-side blocklist + length 24** (implementation choice, not product-affecting). | No UI change regardless of list. |

---

## 28. Amendment / Approval Checklist (What Happens After This Document)

1. **Owner review:** every `OD-*` answered or explicitly deferred; `LB-001/002`, `AV-001..004`, `PROF-003/004`, `LB-003` paths + error codes approved.
2. **Spec version lock:** filename version bump to `v1.0.0 APPROVED — READY FOR IMPLEMENTATION` (same convention as `GameLearn_AI_Gamification_Specification.md` §24).
3. **API Contract amendment:** `GameLearn_AI_API_Contract.md v1.4.0 → v1.5.0` — surface matrix + error registry + change policy entry (the spec MUST NOT self-amend; it just documents what to amend).
4. **Roadmap scheduling:** Phases L1–L10 entered into the team's tracker; each phase's gate tests (IDs in §§23–24) become acceptance criteria for that PR.

---

## 29. Verification — Current-State Inspection Footnotes (so future audits know what was actually inspected, not claimed)

- Entities verified present today: `LearnerProfile(totalXp,currentLevel,overallMastery)`, `Subject/Topic`, `Progress(completionPercentage,status)`, `TopicMastery(masteryScore,masteryLevel,recentAccuracy,tred,attemptCount)`, `XpTransaction(amount,eventType,referenceType,referenceId)`, `GameResult(clientRequestId,gameType,score,durationSeconds,bestCombo,xpAwarded,playedAt)`, `Streak(currentStreakDays,longestStreakDays,lastLearningDate,timezone)`, `Achievement(code,rule_type,is_active,xp_reward)`, `UserAchievement`, `XpEventType`, `Recommendation`, `LearningPath/LearningPathNode`, plus `V1..V16` DDL — files listed in §§1/15 footnotes.
- Gamification invariants reused verbatim: `T(n)=50(n-1)n`, `MAX_LEVEL 50`, `QUIZ_COMPLETED +10` + `QUIZ_PERFORMANCE round(accuracy*0.15)`, `STREAK_BONUS {3→5,7→10,14→25,30→50}`, monotonic level, `UNIQUE(user_id, client_request_id)` on `game_results`, `UNIQUE(user_id, achievement_id)` on `user_achievements` — all from approved §Gamification.
- Flutter theme primitives reused: `AppColors/ AppLightColors`, `AppTypography`, `AppMotion(celebration/normal/fast, reducedMotion)`, `AppBreakpoints/AppGutters`, `FeaturedSurface/GameIdentitySurface/MasteryOrb/XPBar/StreakChip/LevelBadge/RewardsBadgeFrame/InteractiveSurface` — checked in `frontend/lib/core/theme/*` + `frontend/lib/shared/widgets/*`.
- Existing screens that this spec extends (not replaces): `ProfileScreen` (initial-letter hero + progression surface + stat quartet), `DashboardScreen` (`_HeroCard`, `_JourneySection`, `_SubjectsSection`, `AdaptiveGrid`, `SkeletonDashboard`), `GamificationRepository` (`GAM-001..003`, `profile()`, `submitGameResult`), `shell_screen.dart` + `router.dart` (4-tab shell, `/games/:topicId` hub covering the 14 games named in the prompt), `GameLearn_AI_Database_Specification.md §§3/4/8/22` and API conventions §§2.1–2.4 — so "existing infrastructure reused" is evidence-backed, not asserted.
- New entities/columns flagged exactly: `avatars`, `user_credits`, `credit_ledger`, `user_avatars`, `learner_profiles.equipped_avatar_id`, plus optional `user_leaderboard_stats` — all marked `NOT CURRENTLY AVAILABLE — NEW IMPLEMENTATION REQUIRED`.

---

*End of LEADERBOARD_CHARACTER_GAMIFICATION_SPEC.md — v1.0.0 SPECIFICATION — DO NOT IMPLEMENT*

**Next action:** owner review of §§27–28. Upon approval, begin at Phase L1 with no application-code edits elsewhere until gate L1 is merged.
