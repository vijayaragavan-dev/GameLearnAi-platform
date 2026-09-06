import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models/dashboard_models.dart';
import '../core/models/gamification_models.dart';
import '../core/theme/app_motion.dart';
import '../features/auth/providers/session_controller.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/challenge/assessment/presentation/assessment_intro_screen.dart';
import '../features/challenge/assessment/presentation/assessment_result_screen.dart';
import '../features/challenge/assessment/presentation/assessment_run_screen.dart';
import '../features/challenge/quiz/presentation/quiz_screen.dart';
import '../features/challenge/quiz/presentation/quiz_result_arg.dart';
import '../features/challenge/quiz/presentation/quiz_result_screen.dart';
import '../features/challenge/recommendation/presentation/recommendation_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/gamification/presentation/achievements_screen.dart';
import '../features/gamification/presentation/badge_detail_screen.dart';
import '../features/gamification/presentation/streak_screen.dart';
import '../features/learning/lesson/presentation/lesson_screen.dart';
import '../features/learning/path/presentation/path_map_screen.dart';
import '../features/learning/topic/presentation/topic_detail_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/settings_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/progress/presentation/topic_performance_screen.dart';
import '../features/shell/shell_screen.dart';
import '../features/subjects/presentation/subjects_screen.dart';
import '../features/tutor/presentation/tutor_screen.dart';
import '../features/games/hub/presentation/game_hub_screen.dart';
import '../features/games/quiz_battle/presentation/quiz_battle_screen.dart';
import '../features/games/memory_match/presentation/memory_match_screen.dart';
import '../features/games/drag_drop/presentation/drag_drop_screen.dart';
import '../features/games/speed_run/presentation/speed_run_screen.dart';
import '../features/games/debug_arena/presentation/debug_arena_screen.dart';
import '../features/games/unlock_code/presentation/unlock_code_screen.dart';
import '../features/games/concept_builder/presentation/concept_builder_screen.dart';
import '../features/games/sequence_master/presentation/sequence_master_screen.dart';
import '../features/games/target_challenge/presentation/target_challenge_screen.dart';
import '../features/games/mystery_case/presentation/mystery_case_screen.dart';
import '../features/games/boss_battle/presentation/boss_battle_screen.dart';
import '../features/games/puzzle_arena/presentation/puzzle_arena_screen.dart';
import '../features/games/connectivity_lab/presentation/connectivity_lab_screen.dart';
import '../features/games/snake_and_ladder/presentation/snake_and_ladder_screen.dart';
import '../features/design_showcase/design_showcase_screen.dart';
import '../features/leaderboard/presentation/champions_arena_screen.dart';

/// Route builder helpers keep navigation strings in one place.
abstract final class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';

  static const home = '/home';
  static const subjects = '/subjects';
  static const progress = '/progress';
  static const profile = '/profile';
  static const tutor = '/tutor';
  static const achievements = '/achievements';
  static const streak = '/streak';
  static const settings = '/settings';
  static const arena = '/arena';
  // DEV ONLY — not in production nav
  static const designShowcase = '/design-showcase';

  static String path(String subjectId) => '/path/$subjectId';
  static String topic(String topicId) => '/topic/$topicId';
  static String lesson(String topicId) => '/lesson/$topicId';
  static String quiz(String topicId) => '/quiz/$topicId';
  static String assessmentIntro(String subjectId) => '/assessment/$subjectId';
  static String assessmentRun(String subjectId) => '/assessment/$subjectId/run';
  static String assessmentResult(String subjectId) =>
      '/assessment/$subjectId/result';
  static String badge(String code) => '/achievements/$code';
  static String topicPerformance(String topicId) => '/performance/$topicId';
  static String _withSubjectQuery(String base, String? subjectId, String? subjectName) {
    final q = <String>[];
    if (subjectId != null && subjectId.isNotEmpty) q.add('subjectId=${Uri.encodeComponent(subjectId)}');
    if (subjectName != null && subjectName.isNotEmpty) q.add('subjectName=${Uri.encodeComponent(subjectName)}');
    return q.isEmpty ? base : '$base?${q.join('&')}';
  }

  static String gameHub(String topicId, {String? subjectId, String? subjectName}) =>
      _withSubjectQuery('/games/$topicId', subjectId, subjectName);
  static String quizBattle(String topicId, {String? subjectId, String? subjectName}) =>
      _withSubjectQuery('/games/$topicId/quiz-battle', subjectId, subjectName);
  static String memoryMatch(String topicId, {String? subjectId, String? subjectName}) =>
      _withSubjectQuery('/games/$topicId/memory', subjectId, subjectName);
  static String dragDrop(String topicId, {String? subjectId, String? subjectName}) =>
      _withSubjectQuery('/games/$topicId/drag-drop', subjectId, subjectName);
  static String speedRun(String topicId, {String? subjectId, String? subjectName}) =>
      _withSubjectQuery('/games/$topicId/speed-run', subjectId, subjectName);
  static String debugArena(String topicId, {String? subjectId, String? subjectName}) =>
      _withSubjectQuery('/games/$topicId/debug-arena', subjectId, subjectName);
  static String unlockCode(String topicId, {String? subjectId, String? subjectName}) =>
      _withSubjectQuery('/games/$topicId/unlock-code', subjectId, subjectName);
  static String conceptBuilder(String topicId, {String? subjectId, String? subjectName}) =>
      _withSubjectQuery('/games/$topicId/concept-builder', subjectId, subjectName);
  static String sequenceMaster(String topicId, {String? subjectId, String? subjectName}) =>
      _withSubjectQuery('/games/$topicId/sequence-master', subjectId, subjectName);
  static String targetChallenge(String topicId, {String? subjectId, String? subjectName}) =>
      _withSubjectQuery('/games/$topicId/target-challenge', subjectId, subjectName);
  static String mysteryCase(String topicId, {String? subjectId, String? subjectName}) =>
      _withSubjectQuery('/games/$topicId/mystery-case', subjectId, subjectName);
  static String bossBattle(String topicId, {String? subjectId, String? subjectName}) =>
      _withSubjectQuery('/games/$topicId/boss-battle', subjectId, subjectName);
  static String puzzleArena(String topicId, {String? subjectId, String? subjectName}) =>
      _withSubjectQuery('/games/$topicId/puzzle-arena', subjectId, subjectName);
  static String connectivityLab(String topicId, {String? subjectId, String? subjectName}) =>
      _withSubjectQuery('/games/$topicId/connectivity-lab', subjectId, subjectName);
  static String snakeAndLadder(String topicId, {String? subjectId, String? subjectName}) =>
      _withSubjectQuery('/games/$topicId/snake-and-ladder', subjectId, subjectName);

  static bool _isPublic(String location) =>
      location == splash || location == onboarding;
}

CustomTransitionPage<void> _page({
  required Widget child,
  required GoRouterState state,
  Offset begin = const Offset(0, 0.04),
  Duration? duration,
  bool scaleIn = false,
}) => CustomTransitionPage<void>(
  key: state.pageKey,
  child: child,
  transitionDuration: duration ?? AppMotion.normal,
  reverseTransitionDuration: AppMotion.fast,
  transitionsBuilder: (context, animation, secondary, child) {
    final curved = CurvedAnimation(parent: animation, curve: AppMotion.easeOut);
    Widget content = FadeTransition(opacity: curved, child: child);
    if (scaleIn) {
      content = ScaleTransition(
        scale: Tween(begin: 0.93, end: 1.0).animate(curved),
        child: content,
      );
    } else if (begin != Offset.zero) {
      content = SlideTransition(
        position: Tween(begin: begin, end: Offset.zero).animate(curved),
        child: content,
      );
    }
    return content;
  },
);

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final Provider<GoRouter> routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  ref.listen(sessionProvider, (prev, next) => refreshNotifier.notify());
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: false,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final location = state.uri.path;
      final publicOrAuth =
          Routes._isPublic(location) ||
          location == Routes.login ||
          location == Routes.register;

      switch (session.phase) {
        case SessionPhase.restoring:
          return location == Routes.splash ? null : Routes.splash;
        case SessionPhase.unauthenticated:
          if (publicOrAuth) return null;
          return Routes.login;
        case SessionPhase.authenticated:
          if (location == Routes.splash ||
              location == Routes.onboarding ||
              location == Routes.login ||
              location == Routes.register) {
            return Routes.home;
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        pageBuilder: (_, s) =>
            const NoTransitionPage<void>(child: SplashScreen()),
      ),
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (_, s) =>
            const NoTransitionPage<void>(child: OnboardingScreen()),
      ),
      GoRoute(
        path: Routes.login,
        pageBuilder: (_, s) => _page(child: const LoginScreen(), state: s),
      ),
      GoRoute(
        path: Routes.register,
        pageBuilder: (_, s) => _page(child: const RegisterScreen(), state: s),
      ),

      // ---- Authenticated shell with bottom navigation ---------------------
      ShellRoute(
        builder: (context, state, child) =>
            ShellScreen(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            pageBuilder: (_, s) =>
                _page(child: const DashboardScreen(), state: s),
          ),
          GoRoute(
            path: Routes.subjects,
            pageBuilder: (_, s) =>
                _page(child: const SubjectsScreen(), state: s),
          ),
          GoRoute(
            path: Routes.progress,
            pageBuilder: (_, s) =>
                _page(child: const ProgressScreen(), state: s),
          ),
          GoRoute(
            path: Routes.profile,
            pageBuilder: (_, s) =>
                _page(child: const ProfileScreen(), state: s),
          ),
        ],
      ),

      // ---- Full-screen feature flows --------------------------------------
      GoRoute(
        path: '/path/:subjectId',
        pageBuilder: (_, s) => _page(
          child: PathMapScreen(
            subjectId: s.pathParameters['subjectId']!,
            subjectName: s.uri.queryParameters['name'] ?? '',
          ),
          state: s,
          begin: const Offset(0, 0.06),
        ),
      ),
      GoRoute(
        path: '/topic/:topicId',
        pageBuilder: (_, s) => _page(
          child: TopicDetailScreen(topicId: s.pathParameters['topicId']!),
          state: s,
          begin: const Offset(0, 0.05),
          scaleIn: true,
        ),
      ),
      GoRoute(
        path: '/lesson/:topicId',
        pageBuilder: (_, s) => _page(
          child: LessonScreen(topicId: s.pathParameters['topicId']!),
          state: s,
          begin: const Offset(0, 0.08),
        ),
      ),
      GoRoute(
        path: '/quiz/:topicId',
        pageBuilder: (_, s) => _page(
          child: QuizScreen(topicId: s.pathParameters['topicId']!),
          state: s,
          begin: const Offset(1, 0),
        ),
      ),
      GoRoute(
        path: '/quiz-result',
        pageBuilder: (_, s) => _page(
          child: QuizResultScreen(arg: s.extra! as QuizResultArg),
          state: s,
          duration: AppMotion.feature,
          scaleIn: true,
        ),
      ),
      GoRoute(
        path: '/recommendation',
        pageBuilder: (_, s) => _page(
          child: RecommendationScreen(item: s.extra! as RecommendationItem),
          state: s,
          begin: const Offset(1, 0),
        ),
      ),
      GoRoute(
        path: '/assessment/:subjectId',
        pageBuilder: (_, s) => _page(
          child: AssessmentIntroScreen(
            subjectId: s.pathParameters['subjectId']!,
          ),
          state: s,
        ),
      ),
      GoRoute(
        path: '/assessment/:subjectId/run',
        pageBuilder: (_, s) => _page(
          child: AssessmentRunScreen(subjectId: s.pathParameters['subjectId']!),
          state: s,
          begin: const Offset(1, 0),
        ),
      ),
      GoRoute(
        path: '/assessment/:subjectId/result',
        pageBuilder: (_, s) => _page(
          child: AssessmentResultScreen(
            subjectId: s.pathParameters['subjectId']!,
          ),
          state: s,
          duration: AppMotion.feature,
          scaleIn: true,
        ),
      ),
      GoRoute(
        path: Routes.tutor,
        pageBuilder: (_, s) => _page(child: const TutorScreen(), state: s),
      ),
      GoRoute(
        path: Routes.achievements,
        pageBuilder: (_, s) =>
            _page(child: const AchievementsScreen(), state: s),
      ),
      GoRoute(
        path: '/achievements/:code',
        pageBuilder: (_, s) => _page(
          child: BadgeDetailScreen(achievement: s.extra! as Achievement),
          state: s,
          scaleIn: true,
        ),
      ),
      GoRoute(
        path: Routes.streak,
        pageBuilder: (_, s) => _page(child: const StreakScreen(), state: s),
      ),
      GoRoute(
        path: '/performance/:topicId',
        pageBuilder: (_, s) => _page(
          child: TopicPerformanceScreen(topicId: s.pathParameters['topicId']!),
          state: s,
        ),
      ),
      GoRoute(
        path: Routes.settings,
        pageBuilder: (_, s) => _page(child: const SettingsScreen(), state: s),
      ),
      // DEV ONLY — design showcase, not in production nav
      GoRoute(
        path: Routes.designShowcase,
        pageBuilder: (_, s) =>
            _page(child: const DesignShowcaseScreen(), state: s),
      ),

      // ---- Game Arena -------------------------------------------------------
      GoRoute(
        path: '/games/:topicId',
        pageBuilder: (_, s) => _page(
          child: GameHubScreen(
            topicId: s.pathParameters['topicId']!,
            topicName: s.extra is String ? s.extra as String : null,
            subjectId: s.uri.queryParameters['subjectId'],
            subjectName: s.uri.queryParameters['subjectName'],
          ),
          state: s,
          begin: const Offset(0, 0.06),
        ),
      ),
      GoRoute(
        path: '/games/:topicId/quiz-battle',
        pageBuilder: (_, s) => _page(
          child: QuizBattleScreen(
            topicId: s.pathParameters['topicId']!,
            topicName: s.extra is String ? s.extra as String : null,
            subjectId: s.uri.queryParameters['subjectId'],
            subjectName: s.uri.queryParameters['subjectName'],
          ),
          state: s,
          begin: const Offset(1, 0),
        ),
      ),
      GoRoute(
        path: '/games/:topicId/memory',
        pageBuilder: (_, s) => _page(
          child: MemoryMatchScreen(
            topicId: s.pathParameters['topicId']!,
            topicName: s.extra is String ? s.extra as String : null,
            subjectId: s.uri.queryParameters['subjectId'],
            subjectName: s.uri.queryParameters['subjectName'],
          ),
          state: s,
          begin: const Offset(1, 0),
        ),
      ),
      GoRoute(
        path: '/games/:topicId/drag-drop',
        pageBuilder: (_, s) => _page(
          child: DragDropScreen(
            topicId: s.pathParameters['topicId']!,
            topicName: s.extra is String ? s.extra as String : null,
            subjectId: s.uri.queryParameters['subjectId'],
            subjectName: s.uri.queryParameters['subjectName'],
          ),
          state: s,
          begin: const Offset(1, 0),
        ),
      ),
      GoRoute(
        path: '/games/:topicId/speed-run',
        pageBuilder: (_, s) => _page(
          child: SpeedRunScreen(
            topicId: s.pathParameters['topicId']!,
            topicName: s.extra is String ? s.extra as String : null,
            subjectId: s.uri.queryParameters['subjectId'],
            subjectName: s.uri.queryParameters['subjectName'],
          ),
          state: s,
          begin: const Offset(1, 0),
        ),
      ),
      GoRoute(
        path: '/games/:topicId/debug-arena',
        pageBuilder: (_, s) => _page(
          child: DebugArenaScreen(
            topicId: s.pathParameters['topicId']!,
            topicName: s.extra is String ? s.extra as String : null,
            subjectId: s.uri.queryParameters['subjectId'],
            subjectName: s.uri.queryParameters['subjectName'],
          ),
          state: s,
          begin: const Offset(1, 0),
        ),
      ),
      GoRoute(
        path: '/games/:topicId/unlock-code',
        pageBuilder: (_, s) => _page(
          child: UnlockCodeScreen(
            topicId: s.pathParameters['topicId']!,
            topicName: s.extra is String ? s.extra as String : null,
            subjectId: s.uri.queryParameters['subjectId'],
            subjectName: s.uri.queryParameters['subjectName'],
          ),
          state: s,
          begin: const Offset(1, 0),
        ),
      ),
      GoRoute(
        path: '/games/:topicId/concept-builder',
        pageBuilder: (_, s) => _page(
          child: ConceptBuilderScreen(
            topicId: s.pathParameters['topicId']!,
            topicName: s.extra is String ? s.extra as String : null,
            subjectId: s.uri.queryParameters['subjectId'],
            subjectName: s.uri.queryParameters['subjectName'],
          ),
          state: s,
          begin: const Offset(1, 0),
        ),
      ),
      GoRoute(
        path: '/games/:topicId/sequence-master',
        pageBuilder: (_, s) => _page(
          child: SequenceMasterScreen(
            topicId: s.pathParameters['topicId']!,
            topicName: s.extra is String ? s.extra as String : null,
            subjectId: s.uri.queryParameters['subjectId'],
            subjectName: s.uri.queryParameters['subjectName'],
          ),
          state: s,
          begin: const Offset(1, 0),
        ),
      ),
      GoRoute(
        path: '/games/:topicId/target-challenge',
        pageBuilder: (_, s) => _page(
          child: TargetChallengeScreen(
            topicId: s.pathParameters['topicId']!,
            topicName: s.extra is String ? s.extra as String : null,
            subjectId: s.uri.queryParameters['subjectId'],
            subjectName: s.uri.queryParameters['subjectName'],
          ),
          state: s,
          begin: const Offset(1, 0),
        ),
      ),
      GoRoute(
        path: '/games/:topicId/mystery-case',
        pageBuilder: (_, s) => _page(
          child: MysteryCaseScreen(
            topicId: s.pathParameters['topicId']!,
            topicName: s.extra is String ? s.extra as String : null,
            subjectId: s.uri.queryParameters['subjectId'],
            subjectName: s.uri.queryParameters['subjectName'],
          ),
          state: s,
          begin: const Offset(1, 0),
        ),
      ),
      GoRoute(
        path: '/games/:topicId/boss-battle',
        pageBuilder: (_, s) => _page(
          child: BossBattleScreen(
            topicId: s.pathParameters['topicId']!,
            topicName: s.extra is String ? s.extra as String : null,
            subjectId: s.uri.queryParameters['subjectId'],
            subjectName: s.uri.queryParameters['subjectName'],
          ),
          state: s,
          begin: const Offset(1, 0),
        ),
      ),
      GoRoute(
        path: '/games/:topicId/puzzle-arena',
        pageBuilder: (_, s) => _page(
          child: PuzzleArenaScreen(
            topicId: s.pathParameters['topicId']!,
            topicName: s.extra is String ? s.extra as String : null,
            subjectId: s.uri.queryParameters['subjectId'],
            subjectName: s.uri.queryParameters['subjectName'],
          ),
          state: s,
          begin: const Offset(1, 0),
        ),
      ),
      GoRoute(
        path: '/games/:topicId/connectivity-lab',
        pageBuilder: (_, s) => _page(
          child: ConnectivityLabScreen(
            topicId: s.pathParameters['topicId']!,
            topicName: s.extra is String ? s.extra as String : null,
            subjectId: s.uri.queryParameters['subjectId'],
            subjectName: s.uri.queryParameters['subjectName'],
          ),
          state: s,
          begin: const Offset(1, 0),
        ),
      ),
      GoRoute(
        path: '/games/:topicId/snake-and-ladder',
        pageBuilder: (_, s) => _page(
          child: SnakeAndLadderScreen(
            topicId: s.pathParameters['topicId']!,
            topicName: s.extra is String ? s.extra as String : null,
            subjectId: s.uri.queryParameters['subjectId'],
            subjectName: s.uri.queryParameters['subjectName'],
          ),
          state: s,
          begin: const Offset(1, 0),
        ),
      ),
      GoRoute(
        path: Routes.arena,
        pageBuilder: (_, s) => _page(
          child: ChampionsArenaScreen(initialSubjectId: s.uri.queryParameters['subjectId']),
          state: s,
          begin: const Offset(0, 0.06),
        ),
      ),
    ],
  );
});
