import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/avatar_models.dart';
import '../../../core/providers.dart';

final avatarCatalogProvider = FutureProvider<List<AvatarCatalogItem>>((ref) async {
  final repo = ref.watch(avatarRepoProvider);
  return repo.catalog();
});

class AvatarCollectionState {
  const AvatarCollectionState({this.data, this.error, this.loading = false});

  final AvatarCollection? data;
  final Object? error;
  final bool loading;

  bool get showLoading => loading && data == null;

  AvatarCollectionState copyWith({
    AvatarCollection? data,
    bool clearData = false,
    Object? error,
    bool clearError = false,
    bool? loading,
  }) =>
      AvatarCollectionState(
        data: clearData ? null : (data ?? this.data),
        error: clearError ? null : (error ?? this.error),
        loading: loading ?? this.loading,
      );
}

class AvatarCollectionController extends Notifier<AvatarCollectionState> {
  @override
  AvatarCollectionState build() {
    Future<void>.microtask(() => load());
    return const AvatarCollectionState(loading: true);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final repo = ref.read(avatarRepoProvider);
      final data = await repo.collection();
      if (!ref.mounted) return;
      state = AvatarCollectionState(data: data);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final repo = ref.read(avatarRepoProvider);
      final fresh = await repo.collection();
      if (!ref.mounted) return;
      state = AvatarCollectionState(data: fresh);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> purchase(String avatarId) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final repo = ref.read(avatarRepoProvider);
      final updated = await repo.purchase(avatarId);
      if (!ref.mounted) return;
      state = AvatarCollectionState(data: updated);
      // also refresh profile avatar
      ref.invalidate(profileAvatarProvider);
    } catch (e) {
      if (!ref.mounted) return;
      // preserve previous data, surface error
      state = state.copyWith(loading: false, error: e);
      rethrow;
    }
  }

  Future<void> claim(String avatarId) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final repo = ref.read(avatarRepoProvider);
      final updated = await repo.claim(avatarId);
      if (!ref.mounted) return;
      state = AvatarCollectionState(data: updated);
      ref.invalidate(profileAvatarProvider);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, error: e);
      rethrow;
    }
  }
}

final avatarCollectionProvider = NotifierProvider<AvatarCollectionController, AvatarCollectionState>(AvatarCollectionController.new);

class ProfileAvatarState {
  const ProfileAvatarState({this.data, this.error, this.loading = false});
  final ProfileAvatar? data;
  final Object? error;
  final bool loading;
  bool get showLoading => loading && data == null;
}

class ProfileAvatarController extends Notifier<ProfileAvatarState> {
  @override
  ProfileAvatarState build() {
    Future<void>.microtask(() => load());
    return const ProfileAvatarState(loading: true);
  }

  Future<void> load() async {
    state = const ProfileAvatarState(loading: true);
    try {
      final repo = ref.read(avatarRepoProvider);
      final data = await repo.equipped();
      if (!ref.mounted) return;
      state = ProfileAvatarState(data: data);
    } catch (e) {
      if (!ref.mounted) return;
      state = ProfileAvatarState(error: e);
    }
  }

  Future<void> equip(String? avatarId) async {
    // do not optimistically update; wait for server confirmation
    state = ProfileAvatarState(data: state.data, loading: true);
    try {
      final repo = ref.read(avatarRepoProvider);
      final updated = await repo.equip(avatarId);
      if (!ref.mounted) return;
      state = ProfileAvatarState(data: updated);
      // refresh collection to reflect equipped change
      ref.invalidate(avatarCollectionProvider);
    } catch (e) {
      if (!ref.mounted) return;
      state = ProfileAvatarState(data: state.data, error: e);
      rethrow;
    }
  }

  Future<void> refresh() => load();
}

final profileAvatarProvider = NotifierProvider<ProfileAvatarController, ProfileAvatarState>(ProfileAvatarController.new);
