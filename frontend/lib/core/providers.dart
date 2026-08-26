import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio/audio_manager.dart';
import 'network/api_client.dart';
import 'storage/token_storage.dart';
import 'haptics/haptics.dart';
import 'config/app_config.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/learning/data/content_repository.dart';
import '../features/challenge/data/quiz_repository.dart';
import '../features/challenge/data/assessment_repository.dart';
import '../features/gamification/data/gamification_repository.dart';
import '../features/tutor/data/intelligence_repository.dart';

/// Overridden in main() once SharedPreferences loads.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override in bootstrap'),
);

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Live bearer token for the API client. Kept in memory only; persistence
/// goes through [TokenStorage].
class SessionToken extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? token) => state = token;
}

final sessionTokenProvider = NotifierProvider<SessionToken, String?>(
  SessionToken.new,
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  client.tokenProvider = () => ref.read(sessionTokenProvider) ?? '';
  ref.onDispose(client.dispose);
  return client;
});

// ---- Repositories -------------------------------------------------------

final authRepoProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final contentRepoProvider = Provider<ContentRepository>(
  (ref) => ContentRepository(ref.watch(apiClientProvider)),
);

final quizRepoProvider = Provider<QuizRepository>(
  (ref) => QuizRepository(ref.watch(apiClientProvider)),
);

final assessmentRepoProvider = Provider<AssessmentRepository>(
  (ref) => AssessmentRepository(ref.watch(apiClientProvider)),
);

final gamificationRepoProvider = Provider<GamificationRepository>(
  (ref) => GamificationRepository(ref.watch(apiClientProvider)),
);

final intelligenceRepoProvider = Provider<IntelligenceRepository>(
  (ref) => IntelligenceRepository(ref.watch(apiClientProvider)),
);

// ---- System services ----------------------------------------------------

final audioManagerProvider = Provider<AudioManager>(
  (ref) => AudioManager(prefs: ref.watch(sharedPreferencesProvider)),
);

final hapticsProvider = Provider<Haptics>((ref) => Haptics());

final appConfigInfoProvider = Provider<AppConfigInfo>(
  (ref) => const AppConfigInfo(
    baseUrl: AppConfig.apiBaseUrl,
    env: AppConfig.envName,
  ),
);

class AppConfigInfo {
  const AppConfigInfo({required this.baseUrl, required this.env});

  final String baseUrl;
  final String env;
}
