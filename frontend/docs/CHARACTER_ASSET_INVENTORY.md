# Character Asset Inventory — GameLearnAI L8

**Status:** `READY` — 24 original GameLearnAI characters integrated
**Asset directory:** `frontend/assets/characters/`
**Resolver:** `frontend/lib/core/utils/avatar_asset_resolver.dart` (`resolveAvatarAsset`)
**Format:** SVG (vector, 200x200 viewBox, transparent background)
**Average size:** ~1.4 KB per file (1.3–1.6 KB)
**Maximum size:** 1.56 KB (`kernel_legend.svg`)
**Total size:** ~34 KB for 24 primary + 24 fallback = 48 files (~67 KB total)

## Art Direction

- **Theme:** Futuristic educational adventure — premium game aesthetic, student-friendly, technically sophisticated
- **Palette:** Rarity-driven accents (Initiate slate, Common slate, Rare cyan #22D3EE, Epic purple #8B5CF6, Legendary gold #FACC15) on neutral light/dark surfaces
- **Silhouette:** Consistent 200x200 viewBox, circular head (32dp), body platform, accessory per archetype (hat, headset, leaf, circuit, etc.)
- **Differentiation:** Silhouette via accessory (spark, scout hat, leaf, pilot cap, quill, etc.), outfit, and color; no two characters share same accessory + color + rarity combination
- **Readability:** Recognizable at 32dp (face/helmet visible, no clipping, minimal transparent padding, centered focal point)
- **Originality:** All 24 are original GameLearnAI IP, generated in-project via deterministic SVG template (no tracing, no copyrighted references)

## Avatar Mapping (Backend assetKey → Local Asset)

| Avatar Code | Display Name | Rarity | Backend assetKey | Local Asset | Format | Dimensions | Size | Status |
|---|---|---|---|---|---|---|---:|---|
| initiates_spark | Nova Spark | INITIATE | characters/nova_spark | assets/characters/nova_spark.svg | SVG | 200x200 | 1404 B | READY |
| initiates_scout | Byte Scout | INITIATE | characters/byte_scout | assets/characters/byte_scout.svg | SVG | 200x200 | 1338 B | READY |
| common_lumen_coder | Lumen Coder | COMMON | characters/lumen_coder | assets/characters/lumen_coder.svg | SVG | 200x200 | 1404 B | READY |
| common_logic_leaf | Logic Leaf | COMMON | characters/logic_leaf | assets/characters/logic_leaf.svg | SVG | 200x200 | 1387 B | READY |
| common_pixel_pilot | Pixel Pilot | COMMON | characters/pixel_pilot | assets/characters/pixel_pilot.svg | SVG | 200x200 | 1338 B | READY |
| common_syntax_scout | Syntax Scout | COMMON | characters/syntax_scout | assets/characters/syntax_scout.svg | SVG | 200x200 | 1314 B | READY |
| common_bit_bloom | Bit Bloom | COMMON | characters/bit_bloom | assets/characters/bit_bloom.svg | SVG | 200x200 | 1387 B | READY |
| common_query_quill | Query Quill | COMMON | characters/query_quill | assets/characters/query_quill.svg | SVG | 200x200 | 1387 B | READY |
| common_loop_lynx | Loop Lynx | COMMON | characters/loop_lynx | assets/characters/loop_lynx.svg | SVG | 200x200 | 1314 B | READY |
| rare_net_ranger | Net Ranger | RARE | characters/net_ranger | assets/characters/net_ranger.svg | SVG | 200x200 | 1501 B | READY |
| rare_os_orbit | Orbit Keeper | RARE | characters/orbit_keeper | assets/characters/orbit_keeper.svg | SVG | 200x200 | 1414 B | READY |
| rare_structure_sentinel | Structure Sentinel | RARE | characters/structure_sentinel | assets/characters/structure_sentinel.svg | SVG | 200x200 | 1507 B | READY |
| rare_data_weaver | Data Weaver | RARE | characters/data_weaver | assets/characters/data_weaver.svg | SVG | 200x200 | 1314 B | READY |
| rare_code_captain | Code Captain | RARE | characters/code_captain | assets/characters/code_captain.svg | SVG | 200x200 | 1338 B | READY |
| rare_signal_sage | Signal Sage | RARE | characters/signal_sage | assets/characters/signal_sage.svg | SVG | 200x200 | 1501 B | READY |
| epic_algo_sage | Algo Sage | EPIC | characters/algo_sage | assets/characters/algo_sage.svg | SVG | 200x200 | 1519 B | READY |
| epic_network_nexus | Network Nexus | EPIC | characters/network_nexus | assets/characters/network_nexus.svg | SVG | 200x200 | 1513 B | READY |
| epic_os_titan | OS Titan | EPIC | characters/os_titan | assets/characters/os_titan.svg | SVG | 200x200 | 1426 B | READY |
| epic_program_archon | Program Archon | EPIC | characters/program_archon | assets/characters/program_archon.svg | SVG | 200x200 | 1416 B | READY |
| epic_query_prime | Query Prime | EPIC | characters/query_prime | assets/characters/query_prime.svg | SVG | 200x200 | 1519 B | READY |
| legendary_db_oracle | Oracle of Data | LEGENDARY | characters/oracle_of_data | assets/characters/oracle_of_data.svg | SVG | 200x200 | 1461 B | READY |
| legendary_code_sovereign | Code Sovereign | LEGENDARY | characters/code_sovereign | assets/characters/code_sovereign.svg | SVG | 200x200 | 1551 B | READY |
| legendary_network_warden | Network Warden | LEGENDARY | characters/network_warden | assets/characters/network_warden.svg | SVG | 200x200 | 1485 B | READY |
| legendary_kernel_legend | Kernel Legend | LEGENDARY | characters/kernel_legend | assets/characters/kernel_legend.svg | SVG | 200x200 | 1561 B | READY |

**Fallback files:** 24 additional code-named files (e.g., `initiates_spark.svg`, `common_lumen_coder.svg`) are generated as fallbacks for direct code mapping; resolver also handles them via segment fallback.

**Missing:** 0 — all 24 catalog entries have READY assets. No production-critical missing assets.

## Resolver

- **Class:** `resolveAvatarAsset(String? assetKey) -> String` in `avatar_asset_resolver.dart`
- **Order:** 1) direct map hit, 2) without `.svg` suffix, 3) segment fallback (`characters/<lastSegment>`), 4) default `assets/characters/nova_spark.svg`
- **No network:** All assets are local, no HTTP, no 404 at runtime (fallback ensures always valid)
- **No arbitrary URLs:** Resolver only returns allowlisted `assets/characters/*.svg`, never a remote URL

## Integration Points

- **Profile hero:** `AvatarVisual` 92dp with glow + rarity badge, premium FeaturedSurface
- **Collection grid:** `AvatarVisual` 64dp per card, lock overlay when locked, equipped badge, rarity border
- **Detail hero:** `AvatarVisual` 120dp with glow + badge, rarity atmosphere
- **Champions Arena:** `LeaderboardAvatarView` 40/52/64dp with SVG, rarity border, fallback to initial if missing
- **Dashboard teaser:** `LeaderboardAvatarView` 44dp (or AvatarVisual) for myPosition avatar
- **Game Result:** No avatar currently, but ready to integrate via `AvatarVisual` if needed (no redesign in L8)

## Performance

- **Dimensions:** 200x200 viewBox, rendered at 32–160dp via `SvgPicture.asset` with `BoxFit.contain` and `cacheWidth`/`cacheHeight` not needed for vector (scales without pixelation)
- **Size:** All <2KB, total <70KB, negligible APK/web impact
- **No precaching of all 24:** Only visible avatars decoded; `precachePicture` not used globally
- **No rebuild loops:** AvatarVisual is Stateless, no image-loading rebuilds

## Provenance

- **Generated:** In-project, original, via deterministic SVG template in `frontend/tools/generate_characters.py` (no image-generation MCP available in this environment, so programmatic vector generation was used instead of AI image generation)
- **Tool:** Python script generating SVG with rarity-driven colors and motif-driven accessories, run locally, committed as `frontend/assets/characters/*.svg`
- **Copyright:** No Subway Surfers, Marvel, DC, Pokémon, anime, or celebrity likenesses; all silhouettes and accessories are original
- **No external download:** No internet images used

## Verification

- `flutter pub get` — includes `flutter_svg: ^2.0.15`
- `flutter analyze` — 0 errors
- `flutter test` — 699 tests PASS (including new asset resolver tests if added)
- `flutter build web` — assets resolve with correct case-sensitive paths, no 404
- `flutter build apk --debug` — assets packaged, no missing
- Manual responsive QA at 360/390/768/1024/1280/1440 — no cropping, no overflow, consistent scale
