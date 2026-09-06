import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamelearn_app/core/models/leaderboard_models.dart';
import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/network/api_exception.dart';
import 'package:gamelearn_app/features/leaderboard/data/leaderboard_repository.dart';
import 'package:gamelearn_app/features/leaderboard/providers/leaderboard_providers.dart';
import 'package:gamelearn_app/core/providers.dart';

class FakeLeaderboardRepo extends LeaderboardRepository {
  FakeLeaderboardRepo() : super(ApiClient());
  int overallCalls = 0;
  int subjectCalls = 0;
  int positionCalls = 0;
  LeaderboardResponse? overallResponse;
  LeaderboardResponse? subjectResponse;
  LeaderboardPosition? positionResponse;
  Object? throwError;

  @override
  Future<LeaderboardResponse> overall({int page = 1, int size = 20, bool includeTop = true, String season = 'LIFETIME'}) async {
    overallCalls++;
    if (throwError != null) throw throwError!;
    return overallResponse ?? LeaderboardResponse(
      segment: 'OVERALL', season: 'LIFETIME', page: page, size: size,
      totalPlayers: 1, totalPages: 1, top: [], entries: [], nearby: [], me: null,
    );
  }

  @override
  Future<LeaderboardResponse> subject(String subjectId, {int page = 1, int size = 20, bool includeTop = true, String season = 'LIFETIME'}) async {
    subjectCalls++;
    if (subjectId.isEmpty) throw ArgumentError('subjectId required');
    if (throwError != null) throw throwError!;
    return subjectResponse ?? LeaderboardResponse(
      segment: 'SUBJECT', season: 'LIFETIME', subjectId: subjectId, page: page, size: size,
      totalPlayers: 1, totalPages: 1, top: [], entries: [], nearby: [], me: null,
    );
  }

  @override
  Future<LeaderboardPosition> myPosition({String segment = 'OVERALL', String? subjectId}) async {
    positionCalls++;
    if (throwError != null) throw throwError!;
    return positionResponse ?? LeaderboardPosition(
      segment: segment, rank: 1, totalXp: 100, level: 1, totalPlayers: 1, top: [],
    );
  }
}

void main() {
  group('Leaderboard providers', () {
    test('F-PROV-01 leaderboard loading', () async {
      final fake = FakeLeaderboardRepo();
      final container = ProviderContainer(overrides: [
        leaderboardRepoProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);
      final sub = container.listen(overallLeaderboardProvider, (_, __) {});
      expect(container.read(overallLeaderboardProvider).loading, true);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      sub.close();
    });

    test('F-PROV-02 leaderboard success', () async {
      final fake = FakeLeaderboardRepo();
      fake.overallResponse = LeaderboardResponse(
        segment: 'OVERALL', season: 'LIFETIME', page: 1, size: 20,
        totalPlayers: 2, totalPages: 1,
        top: [LeaderboardEntry(rank: 1, displayName: 'A', avatar: LeaderboardAvatar(assetKey: 'a', rarity: AvatarRarity.common), level: 2, totalXp: 1000)],
        entries: [LeaderboardEntry(rank: 1, displayName: 'A', avatar: LeaderboardAvatar(assetKey: 'a', rarity: AvatarRarity.common), level: 2, totalXp: 1000)],
        nearby: [], me: LeaderboardEntry(rank: 1, displayName: 'Me', avatar: LeaderboardAvatar(assetKey: 'c', rarity: AvatarRarity.initiate), level: 1, totalXp: 100, isMe: true),
      );
      final container = ProviderContainer(overrides: [
        leaderboardRepoProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(overallLeaderboardProvider.notifier);
      await notifier.load();
      final state = container.read(overallLeaderboardProvider);
      expect(state.data?.totalPlayers, 2);
      expect(state.error, isNull);
    });

    test('F-PROV-03 leaderboard error', () async {
      final fake = FakeLeaderboardRepo()..throwError = const ServerErrorException('fail');
      final container = ProviderContainer(overrides: [
        leaderboardRepoProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(overallLeaderboardProvider.notifier);
      await notifier.load();
      final state = container.read(overallLeaderboardProvider);
      expect(state.error, isA<ServerErrorException>());
    });

    test('F-PROV-04 subject null does not make invalid API call', () async {
      final fake = FakeLeaderboardRepo();
      final container = ProviderContainer(overrides: [
        leaderboardRepoProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);
      // selectedSubjectId is null initially, so subjectLeaderboard should error without calling repo
      await expectLater(
        container.read(subjectLeaderboardProvider.future),
        throwsA(isA<ArgumentError>()),
      );
      expect(fake.subjectCalls, 0);
    });
  });
}
