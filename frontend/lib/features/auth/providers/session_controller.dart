import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_manager.dart';
import '../../../core/error/user_facing_error.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../challenge/assessment/providers/assessment_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../learning/path/providers/path_provider.dart';

enum SessionPhase { restoring, authenticated, unauthenticated }

class SessionState {
  const SessionState({
    required this.phase,
    this.user,
    this.error,
    this.busy = false,
    this.offline = false,
  });

  final SessionPhase phase;
  final SessionUser? user;
  final UserFacingError? error;
  final bool busy;
  final bool offline;

  SessionState copyWith({
    SessionPhase? phase,
    SessionUser? user,
    bool clearUser = false,
    UserFacingError? error,
    bool clearError = false,
    bool? busy,
    bool? offline,
  }) => SessionState(
    phase: phase ?? this.phase,
    user: clearUser ? null : (user ?? this.user),
    error: clearError ? null : (error ?? this.error),
    busy: busy ?? this.busy,
    offline: offline ?? this.offline,
  );
}

/// Owns authentication lifecycle: secure token persistence, restore-on-boot,
/// login/registration and 401-driven invalidation.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionState(phase: SessionPhase.restoring);

  /// Hooks the API layer so any mid-session 401 invalidates the session.
  void bindUnauthorizedGuard() {
    ref.read(apiClientProvider).onUnauthorized = invalidate;
  }

  Future<void> restore() async {
    bindUnauthorizedGuard();
    if (state.phase != SessionPhase.restoring) return;
    final tokens = ref.read(tokenStorageProvider);
    final token = await tokens.read();
    if (token == null || token.isEmpty) {
      state = const SessionState(phase: SessionPhase.unauthenticated);
      return;
    }
    ref.read(sessionTokenProvider.notifier).set(token);
    try {
      final session = await ref.read(authRepoProvider).validate();
      _adopt(session);
    } on UnauthorizedException {
      await _wipe();
      state = const SessionState(phase: SessionPhase.unauthenticated);
    } catch (_) {
      // Cannot verify right now (offline/server down): keep the stored
      // identity optimistically; screens surface connectivity errors.
      state = const SessionState(
        phase: SessionPhase.authenticated,
        offline: true,
        user: SessionUser(id: '', email: '', displayName: 'Player'),
      );
    }
  }

  Future<bool> login(String email, String password) => _authenticate(() async {
    final session = await ref
        .read(authRepoProvider)
        .login(email.trim(), password);
    await _persist(session);
    return session;
  });

  Future<bool> register(String email, String password, String displayName) =>
      _authenticate(() async {
        final session = await ref
            .read(authRepoProvider)
            .register(email.trim(), password, displayName.trim());
        await _persist(session);
        return session;
      });

  Future<bool> _authenticate(Future<AuthSession> Function() action) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final session = await action();
      state = state.copyWith(
        phase: SessionPhase.authenticated,
        user: session.user,
        busy: false,
        offline: false,
      );
      _celebrateEnter();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        phase: SessionPhase.unauthenticated,
        busy: false,
        error: describeError(e),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        phase: SessionPhase.unauthenticated,
        busy: false,
        error: describeError(const NetworkException()),
      );
      return false;
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepoProvider);
    try {
      await repo.logout();
    } catch (_) {
      // Stateless server-side: discard locally regardless.
    }
    await _wipe();
    _discardLearnerState();
    state = const SessionState(phase: SessionPhase.unauthenticated);
  }

  /// Called by the API layer when any endpoint answers 401 mid-session.
  Future<void> invalidate() async {
    await _wipe();
    _discardLearnerState();
    state = const SessionState(phase: SessionPhase.unauthenticated);
  }

  void dismissError() => state = state.copyWith(clearError: true);

  void _adopt(AuthSession session) {
    ref.read(sessionTokenProvider.notifier).set(session.token);
    state = SessionState(phase: SessionPhase.authenticated, user: session.user);
    _celebrateEnter();
  }

  Future<void> _persist(AuthSession session) async {
    ref.read(sessionTokenProvider.notifier).set(session.token);
    await ref.read(tokenStorageProvider).write(session.token);
  }

  Future<void> _wipe() async {
    ref.read(sessionTokenProvider.notifier).set(null);
    await ref.read(tokenStorageProvider).clear();
  }

  /// Drops every learner-scoped cache so a subsequent login rebuilds from
  /// the NEW principal's backend state (dashboard, paths, assessments).
  /// Without this the non-autoDispose providers kept the previous session's
  /// data and login appeared unreliable.
  void _discardLearnerState() {
    ref.invalidate(dashboardProvider);
    ref.invalidate(pathProvider);
    ref.invalidate(assessmentProvider);
  }

  void _celebrateEnter() {
    final audio = ref.read(audioManagerProvider);
    audio.playContext(MusicContext.dashboard);
    final haptics = ref.read(hapticsProvider);
    haptics.enabled = audio.hapticsEnabled && haptics.enabled;
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

/// Convenience stream of 401 events for the router to react to. Implemented
/// as a listener in the app shell instead of a separate provider here.
