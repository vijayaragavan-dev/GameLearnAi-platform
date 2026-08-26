# GameLearn AI — Gamification Specification (GAM)

---

## 1. Document Metadata

| Field | Value |
|---|---|
| Document name | GameLearn_AI_Gamification_Specification.md |
| Version | 1.0.0 |
| Status | **APPROVED — READY FOR IMPLEMENTATION** (owner sign-off 2026-08-24; D1–D9 approved exactly as documented — see §23/§24) |
| Owner | Project Owner |
| Implementation Owner | Member 2 — Backend + AI |
| Implementation phase | Phase 7 — Gamification Engine (XP · Levels · Achievements · Streaks) |
| Authority dependencies | GameLearn_AI_Database_Specification.md v1.0 APPROVED (schema authority, §22–§25) · GameLearn_AI_Backend_AI_Specification.md §22 (engine architecture authority) · GameLearn_AI_Adaptive_Engine_Specification.md v1.0.0 APPROVED (transaction/locking precedent, §15/§18/§19) · GameLearn_AI_API_Contract.md v1.0.0 APPROVED (change policy) · Phase 4–6 implementation (integration surface) |
| Gemini dependency | **NONE** — gamification is fully deterministic and server-derived. Gemini can never influence it (§12). |
| Schema changes required | **NONE** (see §5 and decision D10) |

### 1.1 Purpose

Single source of truth for all deterministic gamification behaviour: XP
accounting, level progression, achievement unlocking, and learning streaks.
This document fills the `[TBD — GAMIFICATION DECISION]` /
`[TBD — GAMIFICATION SPECIFICATION]` markers declared in Backend + AI Spec
§22 and the deferral notes of Database Spec §22/§25, exactly as the Adaptive
Engine Specification filled the `[TBD — ADAPTIVE ENGINE DECISION]` markers.

### 1.2 Scope

**IN SCOPE (Phase 7):**
- XP ledger writes for quiz submissions (`QUIZ_COMPLETED`,
  `QUIZ_PERFORMANCE`) and engine-internal events (`ACHIEVEMENT_UNLOCKED`,
  `STREAK_BONUS`).
- `learner_profiles.current_level` / `total_xp` maintenance.
- Achievement evaluation over server-authoritative state, one-time unlocks,
  reward XP.
- Daily learning streak maintenance (current, longest, milestones).
- Integration into the existing QUIZ-002 submission transaction.
- Proposed (non-binding) read API amendment for owner review.

**OUT OF SCOPE (not authorized by this document):**
- Any schema change, migration, new table, or new column.
- Lesson-completion XP (`LESSON_COMPLETED` has no producer while Adaptive
  D8 progress derivation remains deferred — RESERVED, see §7.1).
- XP/streak events from learning-path generation (§11).
- Client-facing mutation endpoints (no endpoint may award anything).
- Notifications/push, badges rendering, leaderboards (never specified —
  would require an owner-initiated specification).
- ML-driven personalization (mirrors Adaptive §25 posture).
- Runtime-configurable constants (forbidden — mirrors Adaptive §23).

### 1.3 Terminology

| Term | Meaning |
|---|---|
| **Learning activity** | One successfully processed COMPLETED quiz attempt (the only approved producer in v1; §8). |
| **Learning day** | Calendar date (local to the learner's streak timezone, §10) of a learning activity. |
| **XP event** | One row in `xp_transactions`; immutable ledger entry. |
| **Base award** | The `QUIZ_COMPLETED` flat component. |
| **Performance award** | The `QUIZ_PERFORMANCE` accuracy-scaled component. |
| **Milestone** | Exact streak length at which a one-shot `STREAK_BONUS` fires. |
| **Unlock** | Insertion of a `user_achievements` row (one-time, DB-enforced). |

Normative language: MUST / MUST NOT / MAY as in RFC 2119 spirit. Every
"DESIGN DECISION (owner-approvable)" label below follows the Adaptive
Engine Specification §30 convention: chosen here so the document is
implementable verbatim upon approval; approval makes it normative.

---

## 2. Source Documents Cross-Reference

| Input consumed | From | Used for |
|---|---|---|
| Tables `xp_transactions`, `achievements`, `user_achievements`, `streaks` | DB Spec §22–§25 (+ V9 migration) | §5 mapping |
| `learner_profiles.total_xp`, `.current_level` | DB Spec §8 (+ V4) | §6/§7 persistence targets |
| Enum `XpEventType` {LESSON_COMPLETED, QUIZ_COMPLETED, QUIZ_PERFORMANCE, ACHIEVEMENT_UNLOCKED, STREAK_BONUS} | DB Spec §22 / code | §4.1 — used verbatim, never altered |
| Single-transaction QUIZ-002 + pessimistic locking + structural idempotency | Adaptive Spec §15/§18/§19 | §9 integration, §13 concurrency, §14 failure model |
| "Never log passwords/JWT/API keys…" | Backend §32 | §16 observability |
| Plain-DTO envelope + error registry + contract change policy | API Contract §2/§4/§1 | §12 API proposal framing |

No contradiction was found between this design and any authoritative
document (verification notes in §21).

---

## 3. Engine Overview

```
POST /api/v1/quiz/{quizId}/submit   (existing @Transactional boundary)
        |
        v
[Phase 4] validate -> persist attempts (UNCOMMITTED)
        |
        v
[Phase 5] AdaptiveLearningService.processSubmission(...)
          mastery -> trend -> difficulty -> action -> recommendation
          -> profile refresh (mastery-side fields ONLY)
        |
        v
[Phase 7 - NEW, same transaction]
          G1 XP ledger (base + performance)      ref = attemptId
          G2 profile.total_xp += awarded; level recalc (profile row
             already row-locked by adaptive refresh in THIS tx)
          G3 achievement evaluation (reads committed+in-tx state)
                 -> unlock rows + ACHIEVEMENT_UNLOCKED xp rows
          G4 streak update (PESSIMISTIC_WRITE on streaks row)
                 -> milestone STREAK_BONUS xp row
        |
        v
     COMMIT   (all-or-nothing; any failure rolls back EVERYTHING)
```

Invariant (normative): gamification NEVER runs outside an approved host
transaction, NEVER issues network I/O, and NEVER mutates any adaptive-owned
column (mastery_score, mastery_level, trend, current_difficulty,
recommendations.*, recent_accuracy, overall_mastery).

---

## 4. XP ENGINE

### 4.1 Event-type registry (uses approved enum verbatim)

| XpEventType | Producer in v1 | Status |
|---|---|---|
| `QUIZ_COMPLETED` | Quiz submission pipeline (G1) | ACTIVE |
| `QUIZ_PERFORMANCE` | Quiz submission pipeline (G1) | ACTIVE |
| `ACHIEVEMENT_UNLOCKED` | Achievement engine (G3) | ACTIVE |
| `STREAK_BONUS` | Streak engine (G4) | ACTIVE |
| `LESSON_COMPLETED` | **NONE — RESERVED.** No producer exists while Adaptive D8 (lesson/completion tracking) is deferred. Emitting it is forbidden until a lesson-tracking specification is approved. | RESERVED |

### 4.2 Award rules (DESIGN DECISION — owner-approvable; register D1)

| Component | Formula (integer XP) | Range |
|---|---|---|
| `QUIZ_COMPLETED` | constant **+10** per processed COMPLETED attempt | 10 |
| `QUIZ_PERFORMANCE` | `round_half_up_2(accuracy × 0.15)` truncated to integer (it is already 2dp) | 0…15 |
| `STREAK_BONUS` | milestone map: 3 days→**+5**, 7→**+10**, 14→**+25**, 30→**+50** | per map |
| `ACHIEVEMENT_UNLOCKED` | `achievements.xp_reward` of the unlocked catalog entry | per catalog |

Rationale: the flat base rewards engagement independent of difficulty;
the performance component scales strictly with the SAME accuracy value the
Adaptive Engine already computed (single source of truth, recomputed nowhere);
0.15 caps the perfect bonus at +15 so grinding easy quizzes cannot outpace
meaningful progression. All constants are compiled-code immutable (Adaptive
§23 convention); changing any value requires a spec version bump.

- Success vs failure: awards fire ONLY for attempts that reach the adaptive
  pipeline (i.e., structurally valid COMPLETED submissions). ABANDONED or
  failed-validation submissions award NOTHING (they never enter the host
  transaction path).
- Partial scores: linearly rewarded through the performance component
  (accuracy is the sole input; no cliff effects).
- Perfect score: maximum performance award (15) plus any perfect-score
  achievement predicate — no additional hidden multiplier.
- Repeated attempts: every processed attempt earns again (mirrors Adaptive
  §7.4 "every COMPLETED attempt counts once; no retry penalty"). Anti-grind
  is delegated to mastery weighting (Adaptive §7.3), NOT to XP denial;
  documented accepted exposure (§18/G2 note).
- Duplicate events: impossible by construction — see §13.2 idempotency.
- XP decrease: FORBIDDEN. `amount` MUST be > 0 for every ledger row; no
  code path subtracts XP. Corrections are forward-only by spec amendment.
- Bounds/overflow: single-event `amount ≤ 100` (hard cap);
  `learner_profiles.total_xp` clamps at `Integer.MAX_VALUE` as a defensive
  invariant (unreachable in practice; mandated mirror of Adaptive §7.5).
  Representation: signed 32-bit integer, matching `INT` columns exactly.
- source/reference fields (normative): quiz-derived rows MUST set
  `reference_type='QUIZ_ATTEMPT'`, `reference_id=<quiz_attempts.id>`;
  achievement rows `reference_type='ACHIEVEMENT'`,
  `reference_id=<achievements.id>`; streak-bonus rows
  `reference_type='STREAK_MILESTONE'`, `reference_id=NULL`;
  `description` ≤255 chars, human-safe, no internal identifiers beyond the
  referenced entity's own UUID.
- Audit: every award IS a ledger row (self-auditing); no separate audit
  store is authorized.

### 4.3 Worked examples (arithmetic verified)

| # | Inputs | Computation | Ledger result |
|---|---|---|---|
| X1 | 8 correct / 12 total | acc = round_half_up_2(8÷12×100) = **66.67**; perf = round_half_up_2(66.67×0.15) = round(10.0005) = **10.00 → 10** | QUIZ_COMPLETED +10, QUIZ_PERFORMANCE +10 ⇒ **+20** |
| X2 | 20/20 | acc = 100.00; perf = 15.00 → **15** | +10, +15 ⇒ **+25** |
| X3 | 0/5 | acc = 0.00; perf = 0.00 → **0** | +10, +0 ⇒ **+10** |
| X4 | 1/3 | acc = round_half_up_2(33.333…) = 33.33; perf = round_half_up_2(5.00) = **5** (4.9995 → 5.00 HALF_UP) | +10, +5 ⇒ **+15** |
| X5 | streak reaches exactly 3 | milestone 3 → STREAK_BONUS **+5** | +10/+15 (quiz) +5 (bonus) ⇒ **+30** that day |

---

## 5. DATABASE MAPPING (no schema change — decision D10: DEFINED NONE REQUIRED)

| Spec concept | Approved structure | Notes |
|---|---|---|
| XP ledger | `xp_transactions(id CHAR(36), user_id FK, amount INT, event_type VARCHAR(50)↔XpEventType, reference_type VARCHAR(50), reference_id CHAR(36), description VARCHAR(255), created_at)` | ImmutableEntity; append-only; index (user_id, created_at) suffices for summary reads |
| Achievement catalog | `achievements(code UNIQUE, name, description TEXT, icon_key, rule_type VARCHAR(50), rule_config_json JSON, xp_reward INT, is_active)` | Seeded by migration-time data OR runtime seed — SEE §8.6 seeding decision |
| Unlocks (one-time) | `user_achievements(user_id, achievement_id, unlocked_at, UNIQUE(user_id,achievement_id))` | DB-enforced duplicate prevention |
| Streak state | `streaks(UNIQUE(user_id), current_streak_days INT, longest_streak_days INT, last_learning_date DATE NULL, timezone VARCHAR(64) NOT NULL)` | one row per user, created lazily on first activity |
| Totals / level | `learner_profiles.total_xp INT`, `.current_level INT DEFAULT 1` | updated only inside host TX (§9) |
| Identity | `users.id` principal | ownership root (§15) |

Why no dedup constraint is requested on `xp_transactions`: uniqueness of
awards is guaranteed STRUCTURALLY — gamification executes exactly once per
attempt because it shares the attempt-insert transaction (identical argument
to Adaptive §18 "structural exactly-once"). Adding a UNIQUE(event_type,
reference_id) index would be a Database Specification change for zero
required behaviour; recorded as unnecessary rather than deferred.

---

## 6. LEVEL ENGINE

### 6.1 Model (DESIGN DECISION — register D2)

- Cumulative quadratic thresholds: **T(n) = 50 × (n−1) × n** XP required to
  BE level n (lower-inclusive). Chosen over exponential growth because MVP
  award rates are small (≈10–35/attempt) and quadratic keeps early levels
  reachable while stretching later ones; arithmetic-growth increments
  (+100, +200, +300, …) stay human-readable.
- `level(xp)` = max n in 1..MAX_LEVEL with T(n) ≤ xp. Levels are DERIVED,
  never stored as independent truth: `learner_profiles.current_level` is a
  materialized cache of `level(total_xp)` recomputed after every award.
- Initial: level 1 at 0 XP (registration default matches column default).
- **Levels can NEVER decrease** — total_xp never decreases (§4.2) and T(n)
  is monotonic. Level-down logic MUST NOT exist.
- MAX_LEVEL = **50** (T(50) = 122,500). At cap, XP keeps accumulating and
  remains visible; level stays pinned at 50.
- Boundary rule: threshold values are INCLUSIVE lower bounds (70.00-style
  convention mirroring Adaptive §8 states).

### 6.2 Boundary table (first 10 levels + cap; formula extrapolates identically)

| XP RANGE | LEVEL | NEXT LEVEL REQUIREMENT (additional XP) |
|---|---|---|
| 0 – 99 | 1 | 100 − xp (e.g., @99 → 1) |
| 100 – 299 | 2 | 300 − xp (@100 → 200; @299 → 1) |
| 300 – 599 | 3 | 600 − xp |
| 600 – 999 | 4 | 1,000 − xp |
| 1,000 – 1,499 | 5 | 1,500 − xp |
| 1,500 – 2,099 | 6 | 2,100 − xp |
| 2,100 – 2,799 | 7 | 2,800 − xp |
| 2,800 – 3,599 | 8 | 3,600 − xp |
| 3,600 – 4,499 | 9 | 4,500 − xp |
| 4,500 – 5,399 | 10 | 5,400 − xp |
| … quadratic … | … | T(n+1) − xp |
| ≥ 122,500 | **50 (MAX)** | — (pinned; xpToNext = null) |

Worked transitions: xp 99 → L1; xp 100 → L2 (exact-threshold boundary UP);
xp 299 → L2; a perfect quiz later raises total_xp 299 → 324 ⇒ level =
level(324): T(3)=300 ≤ 324 < T(4)=600 ⇒ **L3**, xpToNext = 600 − 324 = 276.
Level-up detection: compare recomputed level vs pre-award cached
`current_level`; strictly greater ⇒ LEVEL_UP observable event (§16).

---

## 7. ACHIEVEMENT ENGINE

### 7.1 Rule semantics (mechanics DEFINED — register D4; catalog contents under D3)

Exactly four deterministic rule_types are authorized (VARCHAR values stored
verbatim in `achievements.rule_type`; anything else MUST be rejected at seed
time):

| rule_type | Predicate over server state | rule_config_json (single key) |
|---|---|---|
| `COUNT_QUIZ_ATTEMPTS` | count of quiz_attempts for user ≥ threshold | `{"threshold": <int>}` |
| `SINGLE_ATTEMPT_ACCURACY` | any processed attempt with accuracy = 100.00 (equality) | `{"threshold": 100}` fixed |
| `TOPIC_MASTERY_COUNT` | count of topic_mastery rows with mastery_level='MASTERED' ≥ threshold | `{"threshold": <int>}` |
| `STREAK_DAYS` | current_streak_days ≥ threshold evaluated immediately AFTER streak update (G4→G3 order swap NOT allowed; streak is updated first — see §9 ordering) | `{"threshold": <int>}` |

Malformed config (missing/non-integer/threshold<1) ⇒ seed-time rejection;
runtime encountering one ⇒ skip-and-log `GAM_ACH_CONFIG_INVALID` (fail-open
for THAT achievement only, never rolls back the quiz).

### 7.2 Unlock semantics

- One-time only. Repeat evaluation of satisfied predicates is harmless:
  `UNIQUE(user_id, achievement_id)` makes the second insert impossible; the
  engine treats constraint-violation as ALREADY-UNLOCKED and continues
  silently (deterministic, no rollback — §13.3).
- Reward XP: unlocking writes an `ACHIEVEMENT_UNLOCKED` ledger row with
  `amount = achievements.xp_reward` (which itself counts toward level —
  cascade within the same pass, applied BEFORE final level recalculation;
  see §9 ordering note O-2).
- Inactive catalog entries (`is_active=false`) are skipped entirely.
- Ordering: candidates evaluated in fixed deterministic order —
  `display: rule_type ASC, code ASC` — so concurrent/multi-unlock passes
  produce byte-identical ledger sequences.
- Evaluation timing: once per host transaction, AFTER adaptive processing
  and streak update (§9), using in-transaction state (counts include the
  just-inserted attempt rows).
- No repeatable/progress-tiered achievements in v1 (would require new
  columns — forbidden; future spec if wanted).

### 7.3 Proposed initial catalog (PROPOSAL — REQUIRES OWNER APPROVAL, register D3)

| code | name | rule_type | threshold | xp_reward | purpose |
|---|---|---|---|---|---|
| FIRST_QUIZ | First Steps | COUNT_QUIZ_ATTEMPTS | 1 | 20 | onboard the very first submission |
| TEN_QUIZZES | Persistent Learner | COUNT_QUIZ_ATTEMPTS | 10 | 50 | sustained practice |
| PERFECT_SCORE | Flawless Victory | SINGLE_ATTEMPT_ACCURACY | 100 | 30 | reward mastery-quality attempt |
| FIRST_MASTERED | Topic Mastered | TOPIC_MASTERY_COUNT | 1 | 40 | celebrate first MASTERED topic |
| STREAK_3 | Three-Day Rhythm | STREAK_DAYS | 3 | 20 | habit formation |
| STREAK_7 | Week Warrior | STREAK_DAYS | 7 | 60 | habit consolidation |

Every entry maps 1:1 onto approved columns; nothing requires schema change.
Owner may edit codes/values freely — mechanics are unaffected.

Seeding mechanism (DEFINED): catalog rows are inserted by the Phase 7
implementation via an idempotent seeder (insert-if-code-absent) executed at
startup — NOT by Flyway migration (Database Spec assigns seed authority for
subjects to V11; extending Flyway seeds would be a DB-spec change). Seeder
MUST be deterministic and never update existing rows.

---

## 8. STREAK ENGINE

### 8.1 Definitions (register D5: DEFINED; D6/D7: see §10)

- **Learning activity (v1):** exactly one successfully processed quiz
  submission (same producer set as XP base award). Learning-path generation
  is NOT an activity (§11). Lesson completion is RESERVED pending Adaptive
  D8.
- **Learning day:** `LocalDate` of the activity timestamp in the learner's
  streak timezone (column `streaks.timezone`). v1 timezone policy: the
  value is FIXED to `"UTC"` at row creation (see §10 — no approved client
  field supplies a zone yet; USER-002 is deferred). All v1 arithmetic is
  therefore UTC calendar-day arithmetic; the column and algorithms are
  written zone-aware so a future profile setting slots in WITHOUT schema
  or algorithm change.
- Minimum activity requirement per day: ONE activity marks the day active;
  multiple activities same day add nothing further (idempotent by date).
- Future-dated events: impossible server-side (activity time = now());
  defensively, if persisted `last_learning_date` > today (clock rollback),
  treat as SAME-DAY (no-op) and log `GAM_STREAK_ANOMALY`.

### 8.2 Update algorithm (executed once per host TX, G4)

```
today    = LocalDate.now(timezone)
last     = streaks.last_learning_date            -- may be NULL
if row absent:            create(current=1, longest=1, last=today, tz="UTC")
else if last == today:    NO-OP (all streak fields unchanged)
else if last == today-1:  current += 1; longest = max(longest, current); last = today
else (gap >= 2 days):     current = 1; longest unchanged; last = today
then: if current crossed EXACTLY onto a milestone {3,7,14,30}
        -> emit STREAK_BONUS once (§4.2 map)
```

- Longest streak never decreases. Reset sets current to 1 — it does NOT
  zero it (a returning learner's day still counts; recovery/repair beyond
  this natural reset is NOT offered in v1 — register D7 PROPOSED).
- Missed-day behaviour is fully determined by the gap branch (examples S4).
- Daylight saving: with UTC-fixed v1 policy, DST is unobservable. When a
  configurable zone arrives, `LocalDate.now(zone)` + date-difference
  arithmetic remain correct across DST because java.time compares calendar
  dates, not elapsed hours; a 23h/25h day still yields exactly one
  calendar date. Documented now so no future change is silent.
- Inactive users: no rows change; streaks simply decay via the gap rule on
  their next return.

### 8.3 Midnight / boundary examples (all UTC v1; timestamps ISO-8601)

| # | last_learning_date | Activity instant | today | Branch | Resulting state |
|---|---|---|---|---|---|
| S1 | NULL (first ever) | 2026-08-21T23:59:59Z | 08-21 | create | current=1 longest=1 |
| S2 | 2026-08-21 | 2026-08-22T00:00:01Z | 08-22 | consecutive | current=2 |
| S3 | 2026-08-21 | 2026-08-21T23:59:59.999Z | 08-21 | same-day NO-OP | unchanged (second submit same day) |
| S4 | 2026-08-21 | 2026-08-23T09:00:00Z | 08-23 | gap=2 → RESET | current=1, longest kept |
| S5 | 2026-08-21 | 2026-08-22T23:59:59Z AND 2026-08-23T00:00:01Z (two users or two submits straddling midnight) | 08-22 / 08-23 | first: consecutive→2; second: consecutive→3 (+milestone 3 → +5 XP) | demonstrates midnight crossing awards the NEW day, not both |
| S6 | 2026-08-30 | 2026-09-01T00:00:30Z (month boundary) | 09-01 | gap: 08-30→09-01 = 2 days → RESET | current=1 (month rollover is NOT special) |

---

## 9. QUIZ + GAMIFICATION INTEGRATION (register D8: DEFINED)

Answers to the ten mandated questions:

1. **XP awarded?** YES — base + performance components (§4.2), once per
   processed attempt.
2. **Streak updated?** YES — per §8.2, once per host transaction
   (second same-day submission = structural no-op).
3. **Achievements evaluated?** YES — once, after streak update, over
   in-transaction state.
4. **Level recalculated?** YES — after ALL XP of this pass (including
   achievement rewards and streak bonuses) is known. Ordering note O-2:
   final `total_xp` accumulation order is irrelevant to the sum; the level
   computation runs exactly once on the final total.
5. **Order (normative, inside the EXISTING transaction, after Adaptive
   completes):**
   `O-1` quiz XP rows (base, performance) →
   `O-2` achievement evaluation + unlock rows + reward XP rows →
   `O-3` streak update (+ milestone XP) →
   `O-4` total_xp accumulation + level recalc on the already-locked
   `learner_profiles` row → COMMIT.
   (Streak precedes achievements so `STREAK_DAYS` predicates observe the
   freshly updated value in the SAME pass; XP-sum independence is preserved
   because ledger rows are additive.)
6. **Same transaction?** YES — Option A (atomic). Justification: identical
   to the approved Adaptive integration precedent (Adaptive §15/§19:
   single invocation path, shared commit, shared rollback); it gives free
   structural idempotency (§13.2) and keeps `learner_profiles` under the
   lock ordering already established (mastery lock → profile lock). An
   independent post-commit process was CONSIDERED AND REJECTED (recorded
   alternative, mirroring Adaptive §7.3 style): it would orphan awards on
   crash, require a brand-new delivery/retry subsystem, break the
   no-new-infrastructure rule, and duplicate idempotency machinery the
   transaction already provides.
7. **Gamification failure ⇒ quiz submission rollback?** YES — any
   exception propagates: quiz rows, adaptive mutations, and all
   gamification writes roll back together (DB Spec §30 atomicity; Adaptive
   §19 T19 pattern). The client receives the standard error envelope.
8. **Can gamification be retried safely?** YES — the client resubmits the
   quiz; a NEW attempt id is created and processed once, end to end. There
   is no partial-state residue to clean up (rollback guarantees it).
9. **Duplicate processing prevention:** structural — one attempt ⇒ exactly
   one gamification pass, inside its own insert transaction (Adaptive §18
   argument restated normatively for gamification).
10. **Client-visible effect:** response body UNCHANGED except that nothing
    about gamification is added in Phase 7 backend work unless/until the
    API amendment (§12) is approved; the adaptive block stays byte-
    compatible (LP/Quiz contract stability guarantees preserved).

**Adaptive compatibility statement:** gamification READS
(`accuracy`, attempt counts, mastery states, streak outputs) and WRITES ONLY
its own tables + `learner_profiles.total_xp/current_level`. It cannot alter
the mastery formula, thresholds, trend algorithm, difficulty ladder,
recommendation priorities, or any adaptive output — those code paths are not
parameters of gamification. XP/levels/streaks NEVER feed back into adaptive
decisions (no such input exists in Adaptive §5 inputs catalogue; adding one
would require an Adaptive Spec amendment).

---

## 10. TIMEZONE POLICY (register D6)

- Storage: `streaks.timezone` VARCHAR(64), IANA zone id format
  (`ZoneId.of` parseable), written at row creation.
- v1 VALUE: always `"UTC"` — because no approved endpoint currently accepts
  a learner timezone (USER-002 deferred) and inventing a client field would
  violate the contract's no-invention rule.
- Change behavior (specified NOW for future-proofing, activation deferred):
  when a zone-setting feature is approved, the change applies from the NEXT
  activity; `last_learning_date` is interpreted in the NEW zone going
  forward; historical dates are never rewritten; a zone shift may cause at
  most one same-day/consecutive reclassification — acceptable and
  documented; no backfill.
- DST: covered by §8.3 reasoning (calendar-date arithmetic is DST-neutral).

---

## 11. LEARNING PATH AI COMPATIBILITY

- Path GENERATION (PATH-002, AI or SYSTEM) emits NO gamification events in
  v1: generating a plan is not evidenced learning, and AI-invoked generation
  would make XP rate-limit-gameable. Marked FUTURE — requires owner
  decision if ever desired.
- Gemini can NEVER award XP, unlock achievements, modify streaks, modify
  levels, or write any gamification row: gamification consumes ONLY
  server-computed values (attempt correctness, accuracy from Adaptive §6,
  counts, dates). There is no code path from any AI output validator to any
  gamification writer — stated as a grep-verifiable architectural invariant
  (mirrors Adaptive §20 item 7 style).
- LESSON_COMPLETED remains RESERVED (§4.1) until lesson tracking (Adaptive
  D8 successor) is approved.

---

## 12. API AMENDMENT PROPOSAL
### APPROVED BY OWNER (2026-08-24) — now normative via API Contract v1.1.0, which adds GAM-001/002/003 exactly as defined below. Implementation authorized by the separate Phase 7 prompt.

Proposed additions (contract would move from v1.0.0 → v1.1.0 upon approval;
plain-DTO envelope; Bearer mandatory; ownership = principal only; NO
client-supplied userId anywhere):

| ID | Method & Path | Response DTO (shape) | Notes |
|---|---|---|---|
| GAM-001 | GET `/api/v1/gamification/summary` | `{ "totalXp": int, "currentLevel": int, "maxLevel": 50, "nextLevelThresholdXp": int\|null, "xpToNextLevel": int\|null, "currentStreakDays": int, "longestStreakDays": int, "achievementCount": int }` | single aggregate; nulls when at max level; streak fields from own row (zeros if never active) |
| GAM-002 | GET `/api/v1/achievements` | JSON array: `[ { "code", "name", "description", "iconKey", "xpReward", "unlockedAt": ts\|null } ]` | full catalog, caller-scoped unlock timestamps; catalog is bounded (≤ dozens) → array, no pagination (consistent with SUBJ-001 precedent) |
| GAM-003 | GET `/api/v1/streak` | `{ "currentStreakDays", "longestStreakDays", "lastLearningDate": date\|null, "timezone": "UTC" }` | read-only view of §8 state |

- Status codes: 200 success; 401 UNAUTHORIZED (no/invalid token);
  everything else per registry — no new error codes required.
- Ownership rules: server derives user from principal (contract §2 identity
  rule); foreign access structurally impossible (no id parameter exists).
- Caching: NONE mandated; responses are cheap single-row aggregates.
  Any future caching/ETag addition requires its own contract amendment
  (default for v1: no caching headers).
- Mutation endpoints: NONE PROPOSED. XP/levels/streaks/achievements have no
  client-writable surface in v1.

---

## 13. CONCURRENCY

### 13.1 Locking strategy (conceptual; mirrors Adaptive §19 ordering)

- `streaks` row: `SELECT … FOR UPDATE` (PESSIMISTIC_WRITE) at step G4;
  created lazily under the same lock if absent. Two concurrent first-ever
  submissions serialize; second becomes same-day NO-OP.
- `learner_profiles`: ALREADY row-locked by the adaptive refresh earlier in
  the SAME transaction; gamification reuses that lock — it MUST NOT acquire
  profile locks in any other order (deadlock-freedom inherited from
  Adaptive §19).
- `xp_transactions` / `user_achievements`: append-only inserts; no read-
  modify-write races.
- Two simultaneous submissions (any quizzes, same user): serialized on
  mastery-row/profile locks upstream; streak no-op rule absorbs double-
  day credit; XP correctly doubles (two distinct attempts — legitimate).

### 13.2 Idempotency / replay

- Replay of an IDENTICAL submission request ⇒ NEW attempt row ⇒ processed
  exactly once ⇒ new legitimate award cycle (approved semantic, identical
  to Adaptive §18/Phase 4 behaviour). True duplicates are impossible.
- Replay protection at the HTTP layer is out of scope (no such mechanism
  exists in any approved doc; auth tokens remain short-lived).

### 13.3 Concurrent achievement evaluation

Two transactions satisfying the same predicate simultaneously: both attempt
unlock insert; the UNIQUE(user_id,achievement_id) constraint lets exactly
one succeed; the loser treats it as already-unlocked and proceeds
(deterministic continue). Reward XP is granted by the winner only.

### 13.4 Concurrent level calculation

Level is a pure function of total_xp computed while holding the profile row
lock inside the serialized transaction — concurrent calculations cannot
interleave; last-committed state is always self-consistent.

---

## 14. FAILURE AND TRANSACTION MODEL

| Scenario | Behaviour |
|---|---|
| SUCCESS | Single COMMIT covers quiz + adaptive + gamification writes. |
| PARTIAL FAILURE (any gamification exception) | FULL rollback of the host transaction (quiz rows included). No partial awards ever persist. |
| RETRY | Client resubmits → new attempt → clean full pipeline. No repair jobs exist or are needed. |
| DUPLICATE REQUEST | New attempt semantics (§13.2); same-day streak no-op prevents double day-credit. |
| CONCURRENT REQUEST | §13 locking; both may succeed independently if distinct days/attempts. |
| Achievement config invalid at runtime | Skip-that-achievement fail-open + WARN log (§7.1); transaction survives. |
| Streak row missing | Created lazily under lock (first-activity path). |
| Profile row missing | Impossible (registration creates it — Phase 2 guarantee); defensive abort with INTERNAL_ERROR if violated, rolling back. |

Chosen model: **A — atomic with quiz submission** (rationale in §9.6);
model B (post-commit independent) explicitly rejected and recorded.

---

## 15. SECURITY

- Ownership: every read/write keys off the authenticated principal; no
  endpoint accepts userId (§12 proposals included).
- Server-derived ONLY (normative, mirrors Adaptive §5 rejections): the
  client can never supply XP amount, event type, level, achievement code/
  unlock, streak count, activity date, timezone, or reward source. No such
  request fields exist; adding any would require contract amendment +
  explicit rejection rules.
- XP manipulation: impossible without a valid quiz submission passing Phase
  4 validation + Adaptive processing; amounts are constants/formulas, never
  inputs.
- Achievement manipulation: unlock predicates evaluate server state only;
  the only client lever is performing real learning activity.
- Streak manipulation: bounded by real submission timestamps (UTC server
  clock); no client date control; anomaly guard §8.1.
- Integer overflow: per-event cap 100 + defensive total clamp (§4.2).
- Malicious payloads: rejected upstream by existing Phase 4 validation
  before any gamification code executes; gamification adds no new attack
  surface.
- Audit: the ledger IS the audit trail (append-only, user-scoped,
  reference-linked); deletion is forbidden (ImmutableEntity).
- Secrets/logging: §16 rules apply; no new secret is introduced (feature
  needs NO configuration — constants are compiled).

---

## 16. OBSERVABILITY (structured logs; MDC requestId auto-present)

| Event (suggested slf4j names) | Payload (user-safe) |
|---|---|
| `GAM_XP_AWARDED` | eventType, amount, attemptId(reference) — never email |
| `GAM_LEVEL_UP` | from, to |
| `GAM_ACHIEVEMENT_UNLOCKED` | achievement code |
| `GAM_STREAK_UPDATED` | current, longest, milestoneHit?\|bool |
| `GAM_STREAK_ANOMALY` | observed last_date vs today (WARN) |
| `GAM_ACH_CONFIG_INVALID` | achievement code (WARN, fail-open marker) |

NEVER logged (Backend §32 binding): passwords, JWTs, API keys, emails or
other sensitive learner PII, full request bodies. Failure categories reuse
existing log conventions; no ai_interactions involvement (Gemini absent).

---

## 17. TEST MATRIX (deterministic; IDs for implementation phase)

**XP**
| ID | Case | Expected |
|---|---|---|
| XP-01 | first award 8/12 (ex.X1) | rows +10,+10; total +20 |
| XP-02 | repeated attempt same quiz | each processed attempt awards again |
| XP-03 | duplicate-event impossibility | two submits ⇒ two DISTINCT attempt ids ⇒ two award pairs (structural) |
| XP-04 | zero-score 0/5 | +10 only (perf 0) |
| XP-05 | perfect 20/20 | +25 |
| XP-06 | boundary accuracy 33.33 | perf = 5 (X4 rounding) |
| XP-07 | overflow guard | amount>100 impossible (compile-level); total clamp invariant holds |
| XP-08 | forced failure mid-pass | ZERO xp rows persist (rollback) |

**LEVELS**
| ID | Case | Expected |
|---|---|---|
| LVL-01 | registration | level=1, xp=0 |
| LVL-02 | xp lands exactly 100 | level=2 (inclusive boundary) |
| LVL-03 | xp 99 | level=1 |
| LVL-04 | xp 101 | level=2 |
| LVL-05 | level-up crossing 300 via one award | single-pass recompute correct |
| LVL-06 | xp ≥122,500 | level pinned 50; xpToNext=null |
| LVL-07 | monotonicity | level never decreases across random sequences |

**ACHIEVEMENTS**
| ID | Case | Expected |
|---|---|---|
| ACH-01 | predicate first satisfied | unlock + reward row + xp_reward ledger |
| ACH-02 | already unlocked | no second row, no extra xp (unique-constraint continue) |
| ACH-03 | duplicate concurrent unlock | exactly one winner (§13.3) |
| ACH-04 | multiple satisfied in one pass | deterministic order (rule_type,code), all unlocked |
| ACH-05 | threshold boundary (10th attempt) | unlocks AT count==threshold |
| ACH-06 | inactive achievement skipped | no evaluation |
| ACH-07 | invalid config | skipped + WARN; quiz unaffected |

**STREAKS**
| ID | Case | Expected |
|---|---|---|
| STR-01 | first activity | create row cur=1 long=1 (S1) |
| STR-02 | same-day repeats | no-op (S3) |
| STR-03 | consecutive day | cur=2 (S2) |
| STR-04 | missed day | reset cur=1, longest kept (S4) |
| STR-05 | midnight crossing | new-day credit once (S5) |
| STR-06 | month boundary | normal gap rule (S6) |
| STR-07 | milestone 3 | single STREAK_BONUS +5 |
| STR-08 | concurrent same-day submits | serialized; one day-credit |
| STR-09 | future/anomalous last date | same-day no-op + GAM_STREAK_ANOMALY |
| STR-10 | timezone column | always 'UTC' in v1; zone-aware math verified by unit test with non-UTC zone injected |

**INTEGRATION**
| ID | Case | Expected |
|---|---|---|
| INT-01 | full happy path | quiz+adaptive+gamification all committed, adaptive block unchanged |
| INT-02 | rollback injection (like T19) | zero rows anywhere |
| INT-03 | retry after failure | clean full reprocessing on new attempt |
| INT-04 | duplicate submission | two attempts, two passes, one streak-day |
| INT-05 | concurrent submissions | §13 guarantees hold |

**SECURITY**
| ID | Case | Expected |
|---|---|---|
| SEC-01 | unauthenticated access to proposed reads | 401 |
| SEC-02 | client injects xp/level fields | fields do not exist ⇒ MALFORMED/ignored; never trusted |
| SEC-03 | foreign-user resource shaping | no id params ⇒ structurally impossible |
| SEC-04 | replay identical body | treated as new attempt (documented semantic) |
| SEC-05 | malicious oversized payload | rejected upstream Phase 4 |
| SEC-06 | log scan | no PII/secrets in GAM_* lines |

---

## 18. EDGE-CASE REGISTER

| ID | Case | Disposition |
|---|---|---|
| G1 | first-ever activity | §8.2 create path |
| G2 | repeated same activity (grinding) | allowed; anti-grind owned by Adaptive weights; XP farming exposure ACCEPTED & documented (owner may tighten in v2) |
| G3 | perfect quiz | X2 |
| G4 | zero-score quiz | X3 (completion still counts as activity) |
| G5 | partial quiz | X1/X4 |
| G6 | simultaneous submissions | §13.1 |
| G7 | duplicate submission | §13.2 |
| G8 | midnight crossing | S5 |
| G9 | timezone change | §10 deferred-activation semantics |
| G10 | missed day | S4 reset |
| G11 | achievement already unlocked | ACH-02 |
| G12 | level boundary | LVL-02..04 |
| G13 | maximum level | LVL-06 |
| G14 | rollback | XP-08 / INT-02 |
| G15 | retry | INT-03 |
| G16 | invalid client reward attempt | SEC-02 |
| G17 | unauthorized user | SEC-01/03 |
| G18 | concurrent achievement unlock | ACH-03 |
| G19 | DST transition day | §8.3 note — unobservable under UTC v1 |
| G20 | clock rollback / future date | §8.1 anomaly guard |
| G21 | achievement deactivated between passes | ACH-06 skip |
| G22 | xp_reward=0 achievement | legal; unlock row without XP ledger row? — DEFINED: ledger row ALWAYS written with amount=xp_reward; amount MUST be >0 per §4.2 ⇒ catalog MUST keep xp_reward≥1 (seed validation rule) |

---

## 19. NUMERICAL VERIFICATION STATEMENT

All worked arithmetic in §4.3, §6.2, §8.3 was computed with the same
rounding rules the Adaptive Specification mandates (scale-2 HALF_UP) and
cross-checked by hand: 8÷12×100=66.666…→66.67; 66.67×0.15=10.0005→10.00;
33.333…→33.33; 33.33×0.15=4.9995→5.00 (HALF_UP away-from-zero at 2dp);
T(2)=100, T(3)=300, T(10)=4500, T(50)=122500. No contradictions between any
two examples. Implementation-phase tests MUST reproduce these exact values
(regression anchors).

---

## 20. OPEN DECISIONS SUMMARY → see §22 register

None hidden; every D-item carries an explicit status.

---

## 21. CONSISTENCY VALIDATION NOTES

- XpEventType usage maps 1:1 onto the approved enum; no new enum value
  requested; LESSON_COMPLETED reserved WITH justification (Adaptive D8).
- All four engines touch ONLY approved columns (§5 table) — verified against
  V9__create_gamification.sql and current entities.
- Transaction model reuses Adaptive §15/§18/§19 precedents without altering
  any adaptive mathematics; ordering appended strictly AFTER adaptive steps.
- API section is labeled PROPOSAL; contract file untouched by this document.
- README/backend docs make no gamification claims that conflict.
- Conflict protocol: if the owner amends any overlapping document later,
  Backend §42 conflict process applies — STOP and reconcile.

---

## 22. OWNER DECISION REGISTER

| ID | Decision | Status |
|---|---|---|
| D1 | XP values per event (§4.2 table) | **APPROVED AS PROPOSED (owner, 2026-08-24)** |
| D2 | Level thresholds/formula/cap (§6) | **APPROVED AS PROPOSED (owner, 2026-08-24)** |
| D3 | Achievement catalog contents (§7.3) | **APPROVED AS PROPOSED (owner, 2026-08-24)** |
| D4 | Achievement rule-type mechanics (§7.1) | **DEFINED + APPROVED** (catalog params fall under D3) |
| D5 | Learning-activity / learning-day definition (§8.1) | **DEFINED + APPROVED** (quiz-submission activity; calendar-day) |
| D6 | Timezone policy (§10) | **DEFINED + APPROVED for v1** (UTC-fixed, zone-aware code); learner-configurable zone deferred with USER-002 |
| D7 | Streak recovery policy (§8.2) | **APPROVED AS PROPOSED (owner, 2026-08-24)** (v1: natural reset only, no repair) |
| D8 | Quiz transaction integration model (§9) | **DEFINED + APPROVED** (Option A atomic; post-commit alternative formally rejected) |
| D9 | Gamification endpoints (§12) | **APPROVED AS PROPOSED (owner, 2026-08-24)** — GAM-001..003 added to API Contract v1.1.0 |
| D10 | Database requirement (§5) | **DEFINED — NONE REQUIRED** (no tables/columns/migrations; evidence documented) |
| D11 | Security policy (§15) | **DEFINED + APPROVED** (fully server-derived; no client-controlled reward surface; replay posture documented) |

No unresolved owner decisions remain.

---

## 23. CHANGELOG

| Version | Change |
|---|---|
| 1.0.0 | Initial PROPOSED draft: XP/level/achievement/streak engines, quiz-transaction integration, security/concurrency/failure models, API amendment proposal, test matrix, edge-case register, decision register D1–D11 |
| **1.0.0 — APPROVAL** | **Owner approved the specification for the hackathon MVP exactly as documented:** D1 XP values · D2 level model T(n)=50(n−1)n with MAX_LEVEL 50 · D3 six-entry starter catalog · D4 mechanics · D5 activity/day definitions · D6 v1 UTC timezone policy (zone-aware code preserved for future USER-002) · D7 recovery = natural reset only · D8 atomic in-transaction model O-1..O-4 · D9 read endpoints GAM-001/002/003. Status → APPROVED — READY FOR IMPLEMENTATION. Central API Contract concurrently amended to v1.1.0 adding GAM-001..003. No normative rule was altered by this approval |

---

## 24. OWNER APPROVAL SECTION

- [x] Owner approves D1 XP values as proposed — **APPROVED 2026-08-24**
- [x] Owner approves D2 level model as proposed — **APPROVED 2026-08-24**
- [x] Owner approves D3 achievement catalog as proposed — **APPROVED 2026-08-24**
- [x] Owner approves D7 streak recovery policy — **APPROVED 2026-08-24**
- [x] Owner approves D9 endpoints GAM-001..003 + API Contract bump to v1.1.0 — **APPROVED 2026-08-24**
- [x] Overall status change: PROPOSED → **APPROVED — READY FOR IMPLEMENTATION** — **owner sign-off received 2026-08-24**

*End of Specification — GameLearn AI Gamification (GAM) — Version 1.0.0 — APPROVED — READY FOR IMPLEMENTATION*
