import '../../../core/models/content_models.dart';
import '../../../core/network/api_client.dart';
import 'realm_models.dart';

/// REALM-001 read API. Single HTTP owner for realms; widgets consume
/// state via providers/FutureBuilders, never HTTP directly.
/// Failures surface as [ApiException] (401/404/offline handled by the
/// existing app-wide patterns).
class RealmRepository {
  RealmRepository(this._client);

  final ApiClient _client;

  /// GET /api/v1/realms — active realms in backend display order.
  Future<List<BackendRealm>> realms() async {
    final list = await _client.getList('/api/v1/realms');
    return list
        .whereType<Map<String, dynamic>>()
        .map(BackendRealm.fromJson)
        .toList(growable: false);
  }

  /// GET /api/v1/realms/{key} — 404 for unknown/inactive keys.
  Future<BackendRealm> realm(String realmKey) async =>
      BackendRealm.fromJson(await _client.getJson('/api/v1/realms/$realmKey'));

  /// GET /api/v1/realms/{key}/subjects — active subjects of the realm.
  Future<List<Subject>> subjectsForRealm(String realmKey) async {
    final list = await _client.getList('/api/v1/realms/$realmKey/subjects');
    return list
        .whereType<Map<String, dynamic>>()
        .map(Subject.fromJson)
        .toList(growable: false);
  }
}
