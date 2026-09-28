import '../../../core/models/avatar_models.dart';
import '../../../core/network/api_client.dart';

class AvatarRepository {
  AvatarRepository(this._client);

  final ApiClient _client;

  Future<List<AvatarCatalogItem>> catalog() async {
    final list = await _client.getList('/api/v1/avatars');
    return list.whereType<Map<String, dynamic>>().map(AvatarCatalogItem.fromJson).toList(growable: false);
  }

  Future<AvatarCollection> collection() async {
    final json = await _client.getJson('/api/v1/avatars/me');
    return AvatarCollection.fromJson(json);
  }

  Future<AvatarCollection> purchase(String avatarId) async {
    final json = await _client.postJson('/api/v1/avatars/$avatarId/purchase', <String, dynamic>{});
    // POST returns collection after purchase (per L3 contract)
    if (json.isEmpty) return collection();
    // Some backends return collection directly; if it looks like a collection, parse it
    if (json.containsKey('items')) return AvatarCollection.fromJson(json);
    return collection();
  }

  Future<AvatarCollection> claim(String avatarId) async {
    final json = await _client.postJson('/api/v1/avatars/$avatarId/claim', <String, dynamic>{});
    if (json.isEmpty) return collection();
    if (json.containsKey('items')) return AvatarCollection.fromJson(json);
    return collection();
  }

  Future<ProfileAvatar> equipped() async {
    final json = await _client.getJson('/api/v1/profile/avatar');
    return ProfileAvatar.fromJson(json);
  }

  Future<ProfileAvatar> equip(String? avatarId) async {
    final body = <String, dynamic>{'avatarId': avatarId};
    final json = await _client.postJson('/api/v1/profile/avatar', body);
    return ProfileAvatar.fromJson(json);
  }

  Future<ProfileAvatar> unequip() => equip(null);
}
