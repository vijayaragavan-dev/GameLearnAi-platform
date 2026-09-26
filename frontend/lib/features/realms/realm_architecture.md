# Realm Capability & Content Architecture (Phase 2)

> Status: foundation only. Only `worldBased` (Computer Science) is
> implemented. Every other structure value is a planned capability —
> honest metadata with zero content behind it. No backend, API, or
> game-engine changes were made for this document.

## 1. Layer order (additive — nothing below was rewritten)

```text
LearningRealm / LearningRealmCatalog   (NEW — this phase)
  └─ RealmLearningStructure            (NEW — declaration only)
        ├─ worldBased → WorldCatalog (EXISTING, authoritative, 11 worlds)
        ├─ skillBased → PLANNED (Aptitude, Verbal & English)
        ├─ technologyBased → PLANNED (Full Stack Development)
        └─ domainBased → PLANNED (AI & Data, Cyber Security)
WorldDefinition / WorldSyllabus / WorldContext / WorldContentGate
Topic / Lesson / Quiz / Assessment (backend DTOs, unchanged)
GameContentRequest {scope, worldId?, subjectId?, topicId?, difficulty}
14 game mechanics (unchanged) → GameResult → progression (unchanged)
```

## 2. What is common vs realm-specific (traced, not invented)

| Concern | Common (platform) | Realm-specific |
|---|---|---|
| Game mechanics (14 games) | YES — consume topicId-keyed content | no per-realm game forks |
| Content request shape | YES — `GameContentRequest` unchanged | `worldId` attribution only meaningful for `worldBased` |
| Content isolation | `GameContentScope` + `WorldContentGate` unchanged | world isolation applies to CS only |
| XP / streak / achievements / leaderboard | YES — single systems | NEVER per-realm variants |
| Mastery thresholds (80/60/40) + per-topic scores | YES — unchanged | topic identity stays backend UUIDs |
| Learner intelligence / recommendations | YES — Dashboard-driven, unchanged | future realms must supply topicId-keyed performance |
| Syllabus / catalog | — | CS: `WorldCatalog`; others: future source |
| Visual identity | tokens shared | per-realm icon/accent/scene |

## 3. The reuse seam (already exists — verified, not built)

`GameContentRequest.fromRoute` degrades unknown subjects to the
global scope instead of isolating into a wrong world. A future
realm therefore enters the game platform through the SAME request
shape: backend `subjectId`/`topicId` + difficulty, with `worldId`
absent. The 14 games need no forks: they consume topic-keyed
payloads, never world internals. **No game code was touched to
establish this; it is documented here as the verified seam.**

Game availability itself stays backend-driven: `SubjectGameCompat`
(subject, gameType, active) is authoritative and clients must never
infer compatibility. A future realm therefore needs backend compat
rows — never a frontend availability matrix. The Phase 4 screen
guard (`RealmsScreen._openRealm`: only `isWorldBased` realms resolve
into content, anything else falls through to an honest dialog) is
the single realm→experience decision point preventing wrong-content
navigation.

## 4. RealmLearningStructure — why it exists

Without it, future realms would be forced into fake "Worlds" to
reuse the platform. The enum is the smallest extension point that
prevents that: each realm declares its organization; only
`worldBased` resolves to an implementation (`LearningRealm.isWorldBased`
guards this — non-world structures MUST NOT be treated as worlds).

Deliberately NOT modeled (speculative — see §7): per-realm game
lists, per-realm progression, per-realm content-source contracts.

## 5. Backend evolution (DOCUMENTED ONLY — nothing requested)

When Aptitude (or any realm) ships, the backend will need a
realm-aware content scope (today: subject/topic UUIDs + world
heuristics). Frontend assumption until then: unknown subjects
degrade to global scope (existing behavior). No realm fields were
added, requested, or assumed.

## 5b. Phase 3 content-contract design (required backend support)

Read-only backend inspection (Phase 3) confirms: `Subject` carries
only name/description/iconKey/active/displayOrder. There is NO
realm field, NO domain/category field, and NO non-CS content
source. Consequently NO non-CS realm was selected for
implementation — fabricating one would violate data integrity.

Smallest real contract that would unblock ONE future realm
(documented here so backend can evolve without frontend guesswork):

1. **Realm identity on content**: either a `realm_key` column on
   `subjects` (stable machine-readable values matching `RealmId.key`,
   e.g. `APTITUDE`) or a dedicated `realms` table + FK. Frontend
   needs it surfaced on the existing subject DTO — no new endpoint
   required for read paths.
2. **Realm-scoped topic/question reads**: existing
   `GET /topics/{id}`, `GET /quiz/{topicId}`, lesson endpoints
   already accept backend UUIDs, so the ONLY new requirement is
   that such UUIDs exist for the new realm's content. No new
   endpoint shapes are required for games to function.
3. **Result/progression identity**: existing game-result,
   XP/mastery/achievement contracts already key on backend IDs
   and MUST stay realm-agnostic (no `AptitudeXP`).

Frontend adapter boundary (prepared, Phase 4): `RealmsScreen._openRealm`
is the single realm→experience decision point — `isWorldBased`
resolves into the existing world flow, anything else falls through
to an honest dialog. When (1)–(2) land, a realm-scoped content
adapter plugs in BESIDE (never inside) the world adapters, keyed
off `RealmLearningStructure`, and unknown structures keep falling
through safely. No provider/route/game changes are needed for that
step beyond the adapter itself.

## 6. Non-goals (intentionally not built)

Realm providers/repositories/controllers, cross-realm
recommendations, generic mastery migration, content DTOs, game
forks, per-realm XP, backend contracts, migrations, dependencies.

## 7. Extension rule for future phases

Append-only enums (`RealmId`, `RealmLearningStructure`); new
structures MUST NOT alter `worldBased` handling; content sources
arrive with their backend contract, never as fabricated frontend
data. UI for a new realm may only unlock when `availability ==
active` AND its structure has an implementation.
