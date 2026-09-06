/// Centralized resolver for avatar assetKeys to local assets.
/// Maps backend assetKey (e.g., "characters/nova_spark") to
/// local asset path (e.g., "assets/characters/nova_spark.svg").
/// No remote URLs, no network dependency.

const String _kDefaultAsset = 'assets/characters/nova_spark.svg';

const Map<String, String> _kAssetMap = {
  'characters/nova_spark': 'assets/characters/nova_spark.svg',
  'characters/byte_scout': 'assets/characters/byte_scout.svg',
  'characters/lumen_coder': 'assets/characters/lumen_coder.svg',
  'characters/logic_leaf': 'assets/characters/logic_leaf.svg',
  'characters/pixel_pilot': 'assets/characters/pixel_pilot.svg',
  'characters/syntax_scout': 'assets/characters/syntax_scout.svg',
  'characters/bit_bloom': 'assets/characters/bit_bloom.svg',
  'characters/query_quill': 'assets/characters/query_quill.svg',
  'characters/loop_lynx': 'assets/characters/loop_lynx.svg',
  'characters/net_ranger': 'assets/characters/net_ranger.svg',
  'characters/orbit_keeper': 'assets/characters/orbit_keeper.svg',
  'characters/structure_sentinel': 'assets/characters/structure_sentinel.svg',
  'characters/data_weaver': 'assets/characters/data_weaver.svg',
  'characters/code_captain': 'assets/characters/code_captain.svg',
  'characters/signal_sage': 'assets/characters/signal_sage.svg',
  'characters/algo_sage': 'assets/characters/algo_sage.svg',
  'characters/network_nexus': 'assets/characters/network_nexus.svg',
  'characters/os_titan': 'assets/characters/os_titan.svg',
  'characters/program_archon': 'assets/characters/program_archon.svg',
  'characters/query_prime': 'assets/characters/query_prime.svg',
  'characters/oracle_of_data': 'assets/characters/oracle_of_data.svg',
  'characters/code_sovereign': 'assets/characters/code_sovereign.svg',
  'characters/network_warden': 'assets/characters/network_warden.svg',
  'characters/kernel_legend': 'assets/characters/kernel_legend.svg',
  // Fallback code-named variants
  'characters/initiates_spark': 'assets/characters/nova_spark.svg',
  'characters/initiates_scout': 'assets/characters/byte_scout.svg',
};

String resolveAvatarAsset(String? assetKey) {
  if (assetKey == null || assetKey.trim().isEmpty) return _kDefaultAsset;
  final normalized = assetKey.trim();
  // Direct match
  if (_kAssetMap.containsKey(normalized)) return _kAssetMap[normalized]!;
  // Try with .svg suffix stripped
  final withoutSuffix = normalized.replaceAll(RegExp(r'\.svg$'), '');
  if (_kAssetMap.containsKey(withoutSuffix)) return _kAssetMap[withoutSuffix]!;
  // Try code-named fallback: e.g., "common_lumen_coder" -> not in map, fallback to default
  // Check if any key ends with the last segment
  final segment = normalized.split('/').last;
  for (final entry in _kAssetMap.entries) {
    if (entry.key.endsWith('/$segment')) return entry.value;
    if (entry.key == 'characters/$segment') return entry.value;
  }
  return _kDefaultAsset;
}

bool isKnownAvatarAsset(String assetKey) {
  return _kAssetMap.containsKey(assetKey.trim());
}

List<String> get allKnownAvatarAssets => _kAssetMap.values.toSet().toList();
