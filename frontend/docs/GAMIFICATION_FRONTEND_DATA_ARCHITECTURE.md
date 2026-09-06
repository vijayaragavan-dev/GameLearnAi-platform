# Gamification Frontend Data Architecture — L4

**Baseline:** `da71a4f` (L3 avatar/leaderboard backend)
**Phase:** L4 — Flutter data/state foundation (no UI)
**Status:** `DATA FOUNDATION ONLY — NO VISUAL UI`

## Overview

L4 introduces the shared Flutter data layer for the gamification ecosystem defined in `frontend/docs/LEADERBOARD_CHARACTER_GAMIFICATION_SPEC.md` and implemented by backend L2 (leaderboard) and L3 (avatar). All future UI phases (L5 Champions Arena, Avatar Collection, Profile) consume this layer. No visual screens are built in L4.

## Models

### Leaderboard — `lib/core/models/leaderboard_models.dart`

- `LeaderboardSegment` enum: `overall, subject` — maps to `segment` query param (`OVERALL`/`SUBJECT`).
- `AvatarRarity` enum with safe fallback `unknown` — `fromString` lower-cases and defaults to `unknown` for future backend values.
- `LeaderboardAvatar` — `assetKey`, `rarity` (with safe default `characters/nova_spark` / `initiate`).
- `LeaderboardEntry` — `rank`, `displayName`, `avatar`, `level`, `totalXp`, `subjectXp?`, `streakDays?`, `mastery?`, `isMe`, `rankDelta?`. All nullable fields remain nullable; missing `avatar` falls back to default Initiate.
- `LeaderboardResponse` — `segment`, `season`, `subjectId?`, `subjectName?`, `page`, `size`, `totalPlayers`, `totalPages`, `top[]`, `entries[]`, `me?`, `nearby[]`, `generatedAt?`, `cacheTtlSeconds?`. Parses `top/entries/nearby` via `whereType<Map>` so empty/missing arrays become `[]`.
- `LeaderboardPosition` — `segment`, `subjectId?`, `rank`, `totalXp`, `subjectXp?`, `level`, `xpToNextRank?`, `nextRank?`, `nextRankXp?`, `totalPlayers`, `avatar?`, `top[]`. `xpToNextRank` null when rank 1 (peak).

All factories use `as num?` → `?.toInt() ?? default` and `as String? ?? fallback` so malformed required fields produce a controlled error (missing `rank` → 0, but caller can treat as error), while optional fields safely become `null`.

### Avatar — `lib/core/models/avatar_models.dart`

- `AvatarState` enum: `locked, purchasable, insufficientCredits, eligibleToClaim, owned, equipped, unknown` — `fromString` maps backend strings (`LOCKED`/`REQUIREMENTS_NOT_MET` → `locked`, `PURCHASABLE`, `INSUFFICIENT_CREDITS`, `ELIGIBLE_TO_CLAIM`, `OWNED`, `EQUIPPED`) and falls back to `unknown`.
- `AvatarRequirementInfo` — optional `levelMin`, `syllabusCompletionMin`, `syllabusSubjectId`, `streakCurrentMin/Longest`, `bossBattlesMin`, `masteredCountMin`.
- `AvatarCatalogItem` — `id` (validated via `uuidOf`), `code`, `displayName`, `description`, `assetKey` (fallback `characters/nova_spark`), `rarity`, `creditCost?`, `isActive`, `displayOrder`, `requirement?`. Never exposes raw `requirement_json`.
- `RequirementCheck` — `type`, `required`, `current`, `satisfied`.
- `AvatarCollectionItem` — extends catalog with `owned`, `equipped`, `state`, `eligible`, `creditsRequired?`, `creditsAvailable`, `creditsShort?`, `requirements[]`.
- `AvatarCollection` — `creditsAvailable`, `equippedAvatarId?`, `equippedAvatar?`, `items[]`.
- `ProfileAvatar` — `equippedAvatarId?`, `avatar?`, `hasEquipped`, `assetKey`/`rarity` fallbacks to `characters/nova_spark` / `INITIATE`.

## Repositories

### Leaderboard — `lib/features/leaderboard/data/leaderboard_repository.dart`

Uses the single `ApiClient` (base URL from `AppConfig`, bearer token from `sessionTokenProvider`, 15s timeout). No second client.

- `overall({page,size,includeTop,season})` → `GET /api/v1/leaderboard/overall` with `page` (1..50), `size` (1..50), `includeTop` (bool as string), `season` (default `LIFETIME`). Validates via `assert` (debug) and relies on backend 400 for production.
- `subject(subjectId, {page,size,includeTop,season})` → `GET /api/v1/leaderboard/subject/{subjectId}` — asserts non-empty `subjectId`; never silently substitutes global XP.
- `myPosition({segment,subjectId})` → `GET /api/v1/me/leaderboard-position` with `segment` and optional `subjectId`.

### Avatar — `lib/features/avatar/data/avatar_repository.dart`

- `catalog()` → `GET /api/v1/avatars` → `List<AvatarCatalogItem>`
- `collection()` → `GET /api/v1/avatars/me` → `AvatarCollection`
- `purchase(avatarId)` → `POST /api/v1/avatars/{id}/purchase` with empty JSON body; expects `AvatarCollection` response (or empty → re-fetches collection). Auth identity from session, no `userId` param.
- `claim(avatarId)` → `POST /api/v1/avatars/{id}/claim` — same.
- `equipped()` → `GET /api/v1/profile/avatar` → `ProfileAvatar` (null equipped → default).
- `equip(avatarId)` → `POST /api/v1/profile/avatar` with `{"avatarId": avatarId}` (null for unequip).

All methods use `ApiClient.getJson/getList/postJson` which adds `Authorization: Bearer` from `sessionTokenProvider`.

## Providers

All providers use the existing Riverpod 3 architecture (`flutter_riverpod` + `legacy` for `StateProvider`). No second state system.

### Core — `lib/core/providers.dart`

- `leaderboardRepoProvider` and `avatarRepoProvider` added as `Provider<LeaderboardRepository>` / `Provider<AvatarRepository>` that watch `apiClientProvider`. No new API client.

### Leaderboard — `lib/features/leaderboard/providers/leaderboard_providers.dart`

- `OverallLeaderboardController extends Notifier<LeaderboardState>` + `overallLeaderboardProvider` — `build` microtasks `load()`, `load()`/`refresh()` set `loading:true, clearError`, fetch via `leaderboardRepoProvider.overall`, publish `LeaderboardState(data)` or `copyWith(error)`. Never calls network from `build` directly.
- `selectedSubjectIdProvider = StateProvider<String?>` — holds the UI's current subject selection (null = no subject).
- `subjectLeaderboardProvider = FutureProvider<LeaderboardResponse>` — watches `selectedSubjectIdProvider`; if null/empty throws `ArgumentError` (mapped to error state, no invalid API call), else delegates to `repo.subject(subjectId)`.
- `MyPositionController extends Notifier<MyPositionState>` + `myPositionProvider` — `loadOverall()` / `loadSubject(subjectId)` and `refresh` variants. `dashboardLeaderboardProvider` is an alias to the same controller (lightweight, uses `myPosition` not full leaderboard).

### Avatar — `lib/features/avatar/providers/avatar_providers.dart`

- `avatarCatalogProvider = FutureProvider<List<AvatarCatalogItem>>` — watches `avatarRepoProvider`, calls `catalog()`, cached longer than user-state.
- `AvatarCollectionController extends Notifier<AvatarCollectionState>` + `avatarCollectionProvider` — `load()`/`refresh()` fetch `collection()`, `purchase(avatarId)` and `claim(avatarId)` set `loading:true`, call repo, on success publish new `AvatarCollectionState(data: updated)` and `invalidate(profileAvatarProvider)`; on failure preserve previous `data`, set `error`, `rethrow` so UI can show mapped error without fabricating ownership.
- `ProfileAvatarController extends Notifier<ProfileAvatarState>` + `profileAvatarProvider` — `load()` fetches `equipped()`, `equip(avatarId)` posts and on success publishes `ProfileAvatarState(data: updated)` and invalidates `avatarCollectionProvider` (to reflect `equipped` flag).

## Endpoint Mapping

| Repository method | HTTP | Path | Query/Body |
|---|---|---|---|
| `overall` | GET | `/api/v1/leaderboard/overall` | `page, size, includeTop, season` |
| `subject` | GET | `/api/v1/leaderboard/subject/{id}` | same |
| `myPosition` | GET | `/api/v1/me/leaderboard-position` | `segment, subjectId?` |
| `catalog` | GET | `/api/v1/avatars` | — |
| `collection` | GET | `/api/v1/avatars/me` | — |
| `purchase` | POST | `/api/v1/avatars/{id}/purchase` | `{}` |
| `claim` | POST | `/api/v1/avatars/{id}/claim` | `{}` |
| `equipped` | GET | `/api/v1/profile/avatar` | — |
| `equip` | POST | `/api/v1/profile/avatar` | `{"avatarId": string|null}` |

All use `AppConfig.resolve(path, query:)` so `API_BASE_URL` remains environment-driven (no hardcoded `localhost`).

## Invalidation Rules

- After `purchase`/`claim` → `avatarCollectionProvider` gets new data, `profileAvatarProvider` invalidated (equipped may change if purchase auto-equips).
- After `equip`/`unequip` → `profileAvatarProvider` gets new data, `avatarCollectionProvider` invalidated (to update `equipped` flag).
- After `submitGameResult` (existing flow) — no automatic leaderboard fetch; UI can `ref.invalidate(overallLeaderboardProvider)` or `myPositionProvider` on demand.
- Subject selection change → `selectedSubjectIdProvider` update triggers `subjectLeaderboardProvider` recompute.

No refresh loops: providers only fetch on `load()`/`refresh()` or when watched state changes; `build` never does `await` directly.

## State Model

- `LeaderboardState` / `SubjectLeaderboardState` / `MyPositionState` / `AvatarCollectionState` / `ProfileAvatarState` are all `{data?, error?, loading}` with `showLoading => loading && data==null`. `copyWith` preserves previous `data` on error so stale UI remains visible with error banner, not blank.
- `loading` true only while fetching; `error` holds the `ApiException` for mapping.
- `FutureProvider` for catalog/subject uses Riverpod's `AsyncValue` (loading/data/error) — UI can `when` over it.

## Authentication Integration

- `ApiClient.tokenProvider` reads `sessionTokenProvider` (in-memory bearer token, persisted via `TokenStorage`). Every repository call automatically adds `Authorization: Bearer`.
- On 401, `ApiClient` invokes `onUnauthorized` which is wired to `SessionController` to clear session and redirect to login. No second logout system.
- No repository stores credentials; no new storage.

## Error Mapping

`ApiClient._errorFrom` maps `ErrorResponse{status, errorCode, message}` to `ApiException` hierarchy:

- 400 → `ValidationException` (with `fieldErrors` if present)
- 401 → `UnauthorizedException`
- 402 → `InsufficientCreditsException` (new, for `INSUFFICIENT_CREDITS`)
- 403 → `RequirementsNotMetException` if `errorCode == AVATAR_REQUIREMENTS_NOT_MET` else `ForbiddenException`
- 404 → `NotFoundException`
- 409 → `ConflictException` (already owned, etc.)
- 429 → `RateLimitedException`
- 503 → `AiUnavailableException`
- else → `ServerErrorException`
- Network/timeout/malformed → `NetworkException`/`TimeoutApiException`/`MalformedResponseException`

Avatar-specific codes (`INSUFFICIENT_CREDITS`, `AVATAR_REQUIREMENTS_NOT_MET`, `AVATAR_ALREADY_OWNED` as 409) are distinguished via `errorCode` so UI can show "Not enough credits" vs "Keep learning" without showing raw JSON.

## Offline Behavior

- `ApiClient` throws `NetworkException`/`TimeoutApiException` on `ClientException`/`TimeoutException`.
- Providers catch and surface as `error`; previous `data` remains if present (stale cache), otherwise `showLoading` is false and UI shows `ErrorState` with retry.
- Mutations (`purchase`/`claim`/`equip`) never show success without server 2xx; they rethrow so UI stays in error state and does not fabricate ownership.

## Caching

- No persistent cache in L4. `FutureProvider` memoizes while watched; `Notifier` holds last `data` until `refresh`/`invalidate`.
- Catalog (`avatarCatalogProvider`) is implicitly longer-lived than collection (which is invalidated after mutations). Leaderboard `myPosition` is short-lived; full leaderboard is not cached across users (per-user `me` is never shared).
- No cross-user leakage: all user-specific providers derive identity from `sessionTokenProvider`, not from a global.

## Default Avatar

When `GET /profile/avatar` returns `{"equippedAvatarId": null, "avatar": null}` or `avatar` missing, `ProfileAvatar` falls back to `assetKey: 'characters/nova_spark'`, `rarity: 'INITIATE'` (the backend's default Initiate). Same fallback is used in `LeaderboardEntry` when `avatar` is null. No independent frontend default.

## Testing

- `test/leaderboard/leaderboard_models_test.dart` — F-LEAD-01..07
- `test/avatar/avatar_models_test.dart` — F-AV-01..06
- `test/leaderboard/leaderboard_repository_test.dart` — F-API-01..03, 10..11,13,14,16
- `test/avatar/avatar_repository_test.dart` — F-API-04..09,12..15
- `test/leaderboard/leaderboard_providers_test.dart` — F-PROV-01..04
- `test/avatar/avatar_providers_test.dart` — F-PROV-05..10

All tests use `ProviderContainer` overrides and `RecordingApiClient` fakes, never hit the network, never use fake XP/credits.

## Future UI Consumption (L5)

- Champions Arena will `watch(overallLeaderboardProvider)` and `watch(subjectLeaderboardProvider)` (after setting `selectedSubjectIdProvider`).
- Avatar Collection will `watch(avatarCollectionProvider)` for grid and `watch(avatarCatalogProvider)` for static catalog.
- Profile will `watch(profileAvatarProvider)` for hero.
- Dashboard widget will `watch(myPositionProvider)` (lightweight, not full leaderboard).

No UI is built in L4; these providers are ready for `ref.watch` in L5 screens.
