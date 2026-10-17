import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart';
import '../../../core/error/user_facing_error.dart';
import '../../../core/models/gamification_models.dart';
import '../../../core/models/mascot_character.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/neo_brutalism.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/brutal_widgets.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/xp_bar.dart' show XPBar;
import '../../avatar/providers/active_mascot_provider.dart';
import '../../avatar/widgets/cartoon_mascot_view.dart';

/// USER-001 Player Profile with Comic Neo-Brutalism Theme.
/// Features a vibrant 2D cartoon learning mascot (Duolingo-style animated owl buddy Pip),
/// interactive speech bubbles, comic stats cards, and zero robot references.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Future<(LearnerProfile, GamificationSummary)> _future;

  @override
  void initState() {
    super.initState();
    ref.read(audioManagerProvider).playContext(MusicContext.menu);
    _reload();
  }

  void _reload() {
    setState(() {
      final repo = ref.read(gamificationRepoProvider);
      _future = () async {
        final profile = await repo.profile();
        final summary = await repo.summary();
        return (profile, summary);
      }();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvasColor = isDark ? const Color(0xFF151921) : const Color(0xFFF7F5EF);

    return Scaffold(
      backgroundColor: canvasColor,
      appBar: AppBar(
        backgroundColor: canvasColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'PLAYER PROFILE',
          style: TextStyle(
            fontFamily: AppTypography.displayFamily,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: isDark ? Colors.white : NeoBrutalColors.ink,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: BrutalPressable(
              onTap: () => context.push(Routes.settings),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2430) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF333D4F) : NeoBrutalColors.ink,
                    width: 2.0,
                  ),
                  boxShadow: isDark ? null : NeoBrutalShadows.hardSm,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.settings_outlined,
                  size: 20,
                  color: isDark ? Colors.white : NeoBrutalColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: NeoBrutalColors.cobaltBlue,
        backgroundColor: isDark ? const Color(0xFF1E2430) : Colors.white,
        onRefresh: () async => _reload(),
        child: FutureBuilder<(LearnerProfile, GamificationSummary)>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done && !snap.hasData) {
              return ListView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: const [SkeletonList(itemCount: 4, itemHeight: 110)],
              );
            }
            if (snap.hasError) {
              final err = describeError(snap.error!);
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [ErrorState(title: err.title, message: err.message, onRetry: _reload)],
              );
            }
            final (profile, summary) = snap.data!;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                ResponsiveCenter(
                  maxWidth: 680,
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 1. DUOLINGO-STYLE 2D CARTOON MASCOT HERO STAGE ──
                      _DuolingoMascotHeroStage(
                        profile: profile,
                        summary: summary,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),

                      // ── 2. OFFICIAL PLAYER PASS (COMIC ID CARD) ──
                      _PlayerIdentityCard(
                        profile: profile,
                        summary: summary,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),

                      // ── 3. TRIPLE POWER STATS ROW (STREAK, XP, BADGES) ──
                      _StatsTripleRow(
                        summary: summary,
                        profile: profile,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),

                      // ── 4. PROGRESSION & OVERALL MASTERY CARD ──
                      _ProgressionMasteryCard(
                        profile: profile,
                        summary: summary,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),

                      // ── 5. LEARNING BUDDY ROSTER & CUSTOMIZATION ──
                      _BuddyRosterShowcaseCard(
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),

                      // ── 6. QUICK NAVIGATION TILES (ACHIEVEMENTS & STREAK) ──
                      _QuickNavigationTiles(
                        summary: summary,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),

                      // ── 7. PREFERENCES & AUDIO CARD ──
                      _PreferencesCard(
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. DUOLINGO-STYLE 2D CARTOON MASCOT HERO STAGE
// ─────────────────────────────────────────────────────────────────────────────

class _DuolingoMascotHeroStage extends ConsumerStatefulWidget {
  const _DuolingoMascotHeroStage({
    required this.profile,
    required this.summary,
    required this.isDark,
  });

  final LearnerProfile profile;
  final GamificationSummary summary;
  final bool isDark;

  @override
  ConsumerState<_DuolingoMascotHeroStage> createState() => _DuolingoMascotHeroStageState();
}

class _DuolingoMascotHeroStageState extends ConsumerState<_DuolingoMascotHeroStage> {
  int _quoteIndex = 0;
  MascotMood? _tapMood;

  List<String> _getQuotes(MascotCharacter character) => [
        ...character.quotes,
        'Protect that ${widget.summary.currentStreakDays}-day streak, ${widget.profile.displayName}! A 5-minute quiz today keeps your mind razor-sharp! 🔥',
        'Level ${widget.profile.currentLevel} Brain Power! You\'re soaring high! Ready to tackle your next quest? ⚡',
        'Incredible! You\'ve collected ${Formatters.count(widget.profile.totalXp)} total XP! You are an unstoppable learner! 🏆',
        'Tap me anytime for good luck and a high-five! I\'m always cheering for you! 💚',
      ];

  void _onMascotTap(MascotCharacter character) {
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    setState(() {
      _quoteIndex = (_quoteIndex + 1) % _getQuotes(character).length;
      _tapMood = MascotMood.celebrating;
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _tapMood = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeMascot = ref.watch(activeMascotProvider);
    final character = activeMascot.character;
    final quotes = _getQuotes(character);
    final quoteText = quotes[_quoteIndex % quotes.length];
    final currentMood = _tapMood ?? activeMascot.mood;

    return BrutalCard(
      backgroundColor: widget.isDark ? const Color(0xFF1E2430) : Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: character.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: NeoBrutalColors.ink, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(character.emoji, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            character.species.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: AppTypography.displayFamily,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${character.name.toUpperCase()} • ${character.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: widget.isDark ? Colors.white70 : NeoBrutalColors.inkSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => context.push(Routes.adminCharacters),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: NeoBrutalColors.lemonYellow,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: NeoBrutalColors.ink, width: 1.5),
                    boxShadow: NeoBrutalShadows.hardXs,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🎨', style: TextStyle(fontSize: 11)),
                      SizedBox(width: 4),
                      Text(
                        'STUDIO / ADMIN',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: NeoBrutalColors.ink,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Interactive Stage: 2D Cartoon Mascot + Speech Bubble
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 420;

              final mascotWidget = Center(
                child: CartoonMascotView(
                  character: character,
                  accessory: activeMascot.accessory,
                  mood: currentMood,
                  size: isCompact ? 108 : 124,
                  onTap: () => _onMascotTap(character),
                ),
              );

              final speechBubbleWidget = GestureDetector(
                onTap: () => _onMascotTap(character),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF283040) : NeoBrutalColors.pastelBlue,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: NeoBrutalColors.ink, width: 2.0),
                    boxShadow: NeoBrutalShadows.hardSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: NeoBrutalColors.cobaltBlue),
                          const SizedBox(width: 6),
                          Text(
                            '${character.name.toUpperCase()} SAYS:',
                            style: TextStyle(
                              fontFamily: AppTypography.displayFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: widget.isDark ? const Color(0xFF93C5FD) : NeoBrutalColors.cobaltBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                        child: Text(
                          '"$quoteText"',
                          key: ValueKey<int>(_quoteIndex),
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFamily,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                            color: widget.isDark ? Colors.white : NeoBrutalColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: character.tags.map((t) => _ComicMicroTag(
                          label: t,
                          color: character.bellyColor,
                          textColor: character.secondaryColor,
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              );

              if (isCompact) {
                return Column(
                  children: [
                    mascotWidget,
                    const SizedBox(height: 12),
                    speechBubbleWidget,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  mascotWidget,
                  const SizedBox(width: 14),
                  Expanded(child: speechBubbleWidget),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. OFFICIAL PLAYER PASS (COMIC ID CARD)
// ─────────────────────────────────────────────────────────────────────────────

class _PlayerIdentityCard extends ConsumerWidget {
  const _PlayerIdentityCard({
    required this.profile,
    required this.summary,
    required this.isDark,
  });

  final LearnerProfile profile;
  final GamificationSummary summary;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMascot = ref.watch(activeMascotProvider);
    final handle = '@${profile.displayName.toLowerCase().replaceAll(' ', '')}';
    final atMax = summary.atMaxLevel;

    return BrutalCard(
      backgroundColor: isDark ? const Color(0xFF1E2430) : Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Ribbon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'OFFICIAL LEARNER PASS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: isDark ? Colors.white60 : NeoBrutalColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF10B981), width: 1.2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 7, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      'ACTIVE LEARNER',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF047857),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Avatar Frame & Player Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with Level Badge Ribbon
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: activeMascot.character.bellyColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: NeoBrutalColors.ink, width: 2.5),
                      boxShadow: NeoBrutalShadows.hardSm,
                    ),
                    alignment: Alignment.center,
                    child: CartoonMascotView(
                      character: activeMascot.character,
                      accessory: activeMascot.accessory,
                      mood: MascotMood.idle,
                      size: 56,
                      isAnimated: false,
                    ),
                  ),
                  Positioned(
                    bottom: -8,
                    left: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: NeoBrutalColors.lemonYellow,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: NeoBrutalColors.ink, width: 1.6),
                        boxShadow: NeoBrutalShadows.hardXs,
                      ),
                      child: Text(
                        'LVL ${profile.currentLevel}',
                        style: const TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: NeoBrutalColors.ink,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Name, Handle, Rank
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTypography.displayFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : NeoBrutalColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, size: 18, color: NeoBrutalColors.cobaltBlue),
                      ],
                    ),
                    Text(
                      handle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: NeoBrutalColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 14, color: NeoBrutalColors.cobaltBlue),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Ranked Scholar • Level ${profile.currentLevel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : NeoBrutalColors.inkSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Next Level XP Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'NEXT LEVEL EXP',
                style: TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: NeoBrutalColors.textMuted,
                ),
              ),
              Flexible(
                child: Text(
                  atMax
                      ? 'MAX LEVEL (${Formatters.count(profile.totalXp)} XP)'
                      : '${summary.xpToNextLevel ?? 0} XP TO GO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: NeoBrutalColors.cobaltBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          XPBar(
            currentLevel: profile.currentLevel,
            totalXp: profile.totalXp,
            xpToNextLevel: summary.xpToNextLevel,
            height: 11,
            showLabels: false,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. TRIPLE POWER STATS ROW (STREAK, XP, BADGES)
// ─────────────────────────────────────────────────────────────────────────────

class _StatsTripleRow extends StatelessWidget {
  const _StatsTripleRow({
    required this.summary,
    required this.profile,
    required this.isDark,
  });

  final GamificationSummary summary;
  final LearnerProfile profile;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Streak Card
        Expanded(
          child: BrutalPressable(
            onTap: () => context.push(Routes.streak),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2430) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: NeoBrutalColors.ink, width: 2.2),
                boxShadow: NeoBrutalShadows.hardSm,
              ),
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4E6),
                      shape: BoxShape.circle,
                      border: Border.all(color: NeoBrutalColors.ink, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🔥', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.currentStreakDays}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : NeoBrutalColors.ink,
                    ),
                  ),
                  const Text(
                    'DAY STREAK',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: NeoBrutalColors.errorRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Total XP Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2430) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NeoBrutalColors.ink, width: 2.2),
              boxShadow: NeoBrutalShadows.hardSm,
            ),
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    border: Border.all(color: NeoBrutalColors.ink, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: const Text('⭐', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.count(profile.totalXp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : NeoBrutalColors.ink,
                  ),
                ),
                const Text(
                  'TOTAL XP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Badges Card
        Expanded(
          child: BrutalPressable(
            onTap: () => context.push(Routes.achievements),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2430) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: NeoBrutalColors.ink, width: 2.2),
                boxShadow: NeoBrutalShadows.hardSm,
              ),
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E7FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: NeoBrutalColors.ink, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🏆', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.unlockedAchievements}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : NeoBrutalColors.ink,
                    ),
                  ),
                  const Text(
                    'BADGES',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: NeoBrutalColors.cobaltBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. PROGRESSION & OVERALL MASTERY CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressionMasteryCard extends StatelessWidget {
  const _ProgressionMasteryCard({
    required this.profile,
    required this.summary,
    required this.isDark,
  });

  final LearnerProfile profile;
  final GamificationSummary summary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final atMax = summary.atMaxLevel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoBrutalColors.cobaltBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeoBrutalColors.ink, width: 2.5),
        boxShadow: NeoBrutalShadows.hard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: NeoBrutalColors.ink, width: 1.8),
                      ),
                      child: const Icon(Icons.trending_up_rounded, size: 14, color: NeoBrutalColors.ink),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'PROGRESSION',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: NeoBrutalColors.ink, width: 1.5),
                ),
                child: Text(
                  atMax ? 'MAX LEVEL' : 'LVL ${profile.currentLevel} → ${profile.currentLevel + 1}',
                  style: const TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: NeoBrutalColors.cobaltBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              LevelBadge(level: profile.currentLevel, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OVERALL MASTERY',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Color(0xFFDCE9FF),
                      ),
                    ),
                    Text(
                      Formatters.percent(profile.overallMastery),
                      style: const TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!atMax && summary.xpToNextLevel != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚡ ${summary.xpToNextLevel} XP TO REACH LEVEL ${profile.currentLevel + 1}',
                style: const TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. LEARNING BUDDY ROSTER & CUSTOMIZATION (REPLACES ROBOT COMPLETELY)
// ─────────────────────────────────────────────────────────────────────────────

class _BuddyRosterShowcaseCard extends ConsumerWidget {
  const _BuddyRosterShowcaseCard({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMascot = ref.watch(activeMascotProvider);
    final character = activeMascot.character;
    final accessory = activeMascot.accessory;

    return BrutalCard(
      backgroundColor: isDark ? const Color(0xFF1E2430) : Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'LEARNING BUDDY ROSTER',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: isDark ? Colors.white60 : NeoBrutalColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push(Routes.adminCharacters),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: NeoBrutalColors.pastelBlue,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: NeoBrutalColors.ink, width: 1.2),
                  ),
                  child: const Text(
                    'STUDIO / ADMIN',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: NeoBrutalColors.cobaltBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Character Spotlight Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF283040) : const Color(0xFFFFFDF7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NeoBrutalColors.ink, width: 2.0),
              boxShadow: NeoBrutalShadows.hardSm,
            ),
            child: Row(
              children: [
                // Mini mascot portrait frame
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: character.bellyColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NeoBrutalColors.ink, width: 2.0),
                  ),
                  alignment: Alignment.center,
                  child: CartoonMascotView(
                    character: character,
                    accessory: accessory,
                    mood: MascotMood.idle,
                    size: 46,
                    isAnimated: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${character.name} the ${character.species}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : NeoBrutalColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        character.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (accessory != MascotAccessory.none)
                            _ComicMicroTag(
                              label: '${accessory.emoji} ${accessory.label}',
                              color: const Color(0xFFFEF3C7),
                              textColor: const Color(0xFF92400E),
                            ),
                          ...character.tags.map((t) => _ComicMicroTag(
                            label: t,
                            color: character.bellyColor,
                            textColor: character.secondaryColor,
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BrutalButton(
            text: 'MODIFY IN ADMIN STUDIO',
            icon: Icons.palette_outlined,
            backgroundColor: NeoBrutalColors.lemonYellow,
            textColor: NeoBrutalColors.ink,
            onPressed: () => context.push(Routes.adminCharacters),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. QUICK NAVIGATION TILES (ACHIEVEMENTS & STREAK)
// ─────────────────────────────────────────────────────────────────────────────

class _QuickNavigationTiles extends StatelessWidget {
  const _QuickNavigationTiles({
    required this.summary,
    required this.isDark,
  });

  final GamificationSummary summary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Trophy Vault
        Expanded(
          child: BrutalPressable(
            onTap: () => context.push(Routes.achievements),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2430) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: NeoBrutalColors.ink, width: 2.0),
                boxShadow: NeoBrutalShadows.hardSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🏆', style: TextStyle(fontSize: 18)),
                      Icon(Icons.arrow_forward_rounded, size: 15, color: NeoBrutalColors.ink),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'TROPHY VAULT',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : NeoBrutalColors.ink,
                    ),
                  ),
                  Text(
                    '${summary.unlockedAchievements} badges unlocked',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: NeoBrutalColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Streak Journey
        Expanded(
          child: BrutalPressable(
            onTap: () => context.push(Routes.streak),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2430) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: NeoBrutalColors.ink, width: 2.0),
                boxShadow: NeoBrutalShadows.hardSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🔥', style: TextStyle(fontSize: 18)),
                      Icon(Icons.arrow_forward_rounded, size: 15, color: NeoBrutalColors.ink),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'STREAK VAULT',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : NeoBrutalColors.ink,
                    ),
                  ),
                  Text(
                    '${summary.currentStreakDays} days on fire',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: NeoBrutalColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. PREFERENCES & SETTINGS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return BrutalCard(
      backgroundColor: isDark ? const Color(0xFF1E2430) : Colors.white,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SYSTEM & SETTINGS',
            style: TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: isDark ? Colors.white60 : NeoBrutalColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          BrutalPressable(
            onTap: () => context.push(Routes.settings),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF283040) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: NeoBrutalColors.ink, width: 2.0),
                boxShadow: isDark ? null : NeoBrutalShadows.hardXs,
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 20, color: NeoBrutalColors.ink),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Settings & Audio Options',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : NeoBrutalColors.ink,
                          ),
                        ),
                        const Text(
                          'Manage music, SFX, haptics and display theme',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: NeoBrutalColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 20, color: NeoBrutalColors.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DUOLINGO-STYLE 2D CARTOON MASCOT (PIP THE OWL)
// ─────────────────────────────────────────────────────────────────────────────

class _DuolingoCartoonMascot extends StatefulWidget {
  const _DuolingoCartoonMascot();

  final double size = 116;

  @override
  State<_DuolingoCartoonMascot> createState() => _DuolingoCartoonMascotState();
}

class _DuolingoCartoonMascotState extends State<_DuolingoCartoonMascot>
    with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _tapController;

  @override
  void initState() {
    super.initState();
    // Continuous idle breathing / floating bob
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // Tap celebration spring jump
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  void triggerCheer() {
    _tapController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _idleController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_idleController, _tapController]),
      builder: (context, _) {
        final idleVal = _idleController.value;
        final tapVal = _tapController.value;

        // Idle vertical float
        final bob = math.sin(idleVal * 2 * math.pi) * 3.5;
        // Left wing waving
        final wingAngle = math.sin(idleVal * 4 * math.pi) * 0.14;

        // Natural periodic blink: blinks when idleVal is near 0.50
        double blink = 0.0;
        if (idleVal > 0.46 && idleVal < 0.52) {
          blink = 1.0;
        }

        // Tap celebration jump and bounce
        double jump = 0.0;
        double scale = 1.0;
        bool isCheering = false;
        if (_tapController.isAnimating) {
          isCheering = true;
          jump = -math.sin(tapVal * math.pi) * 14.0;
          scale = 1.0 + math.sin(tapVal * math.pi) * 0.18;
          blink = 1.0; // Happy smiling eyes during jump!
        }

        return SizedBox(
          width: widget.size,
          height: widget.size * 1.08,
          child: CustomPaint(
            painter: _DuolingoMascotPainter(
              bobOffset: bob + jump,
              wingAngle: wingAngle,
              blinkValue: blink,
              cheerScale: scale,
              isCheering: isCheering,
            ),
          ),
        );
      },
    );
  }
}

/// Precise Vector Painter for the 2D Duolingo-style Owl Mascot.
/// Pure Flutter Canvas rendering with zero external image asset dependencies.
class _DuolingoMascotPainter extends CustomPainter {
  _DuolingoMascotPainter({
    required this.bobOffset,
    required this.wingAngle,
    required this.blinkValue,
    required this.cheerScale,
    required this.isCheering,
  });

  final double bobOffset;
  final double wingAngle;
  final double blinkValue;
  final double cheerScale;
  final bool isCheering;

  static const Color primaryColor = Color(0xFF58CC02); // Duolingo Emerald Green
  static const Color bellyColor = Color(0xFFE8FBE8);   // Soft Mint Cream
  static const Color beakColor = Color(0xFFF59E0B);    // Warm Amber
  static const Color feetColor = Color(0xFFEA580C);    // Vibrant Orange
  static const Color inkColor = Color(0xFF171923);     // Deep Universal Ink

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120.0;
    final cx = size.width / 2.0;

    final inkPaint = Paint()
      ..color = inkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bodyPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final bellyPaint = Paint()
      ..color = bellyColor
      ..style = PaintingStyle.fill;

    final beakPaint = Paint()
      ..color = beakColor
      ..style = PaintingStyle.fill;

    final feetPaint = Paint()
      ..color = feetColor
      ..style = PaintingStyle.fill;

    final capPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    final goldPaint = Paint()
      ..color = const Color(0xFFFFD43B)
      ..style = PaintingStyle.fill;

    final goldStroke = Paint()
      ..color = const Color(0xFFFFD43B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * s
      ..strokeCap = StrokeCap.round;

    final blushPaint = Paint()
      ..color = const Color(0xFFF472B6).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(0, bobOffset);

    if (cheerScale != 1.0) {
      canvas.translate(cx, size.height * 0.65);
      canvas.scale(cheerScale, 2.0 - cheerScale);
      canvas.translate(-cx, -size.height * 0.65);
    }

    // 0. Confetti sparkles when cheering
    if (isCheering) {
      _drawSparkle(canvas, Offset(cx - 42 * s, 16 * s), 7 * s, goldPaint);
      _drawSparkle(canvas, Offset(cx + 44 * s, 20 * s), 6 * s, Paint()..color = const Color(0xFF06B6D4));
      _drawSparkle(canvas, Offset(cx - 38 * s, 76 * s), 5 * s, goldPaint);
      _drawSparkle(canvas, Offset(cx + 40 * s, 74 * s), 5 * s, Paint()..color = const Color(0xFFEC4899));
    }

    // 1. Orange feet at bottom
    _drawFoot(canvas, Offset(cx - 20 * s, 102 * s), s, feetPaint, inkPaint);
    _drawFoot(canvas, Offset(cx + 20 * s, 102 * s), s, feetPaint, inkPaint);

    // 2. Ear / crest tufts on head
    // Left ear tuft
    final leftEar = Path()
      ..moveTo(cx - 28 * s, 34 * s)
      ..cubicTo(cx - 42 * s, 20 * s, cx - 40 * s, 8 * s, cx - 36 * s, 6 * s)
      ..cubicTo(cx - 30 * s, 6 * s, cx - 18 * s, 16 * s, cx - 14 * s, 24 * s)
      ..close();
    canvas.drawPath(leftEar, bodyPaint);
    canvas.drawPath(leftEar, inkPaint);

    // Right ear tuft
    final rightEar = Path()
      ..moveTo(cx + 14 * s, 24 * s)
      ..cubicTo(cx + 18 * s, 16 * s, cx + 30 * s, 6 * s, cx + 36 * s, 6 * s)
      ..cubicTo(cx + 40 * s, 8 * s, cx + 42 * s, 20 * s, cx + 28 * s, 34 * s)
      ..close();
    canvas.drawPath(rightEar, bodyPaint);
    canvas.drawPath(rightEar, inkPaint);

    // 3. Plump rounded body
    final body = Path()
      ..moveTo(cx, 22 * s)
      ..cubicTo(cx + 36 * s, 22 * s, cx + 46 * s, 42 * s, cx + 46 * s, 64 * s)
      ..cubicTo(cx + 48 * s, 86 * s, cx + 40 * s, 104 * s, cx, 104 * s)
      ..cubicTo(cx - 40 * s, 104 * s, cx - 48 * s, 86 * s, cx - 48 * s, 64 * s)
      ..cubicTo(cx - 46 * s, 42 * s, cx - 36 * s, 22 * s, cx, 22 * s)
      ..close();
    canvas.drawPath(body, bodyPaint);
    canvas.drawPath(body, inkPaint);

    // 4. Belly patch
    final bellyRect = Rect.fromCenter(center: Offset(cx, 74 * s), width: 52 * s, height: 44 * s);
    canvas.drawOval(bellyRect, bellyPaint);
    final thinInk = Paint()
      ..color = inkColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * s;
    canvas.drawOval(bellyRect, thinInk);

    // Chest feather chevron marks
    final chestMarkerPaint = Paint()
      ..color = const Color(0xFF65A30D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round;
    _drawChevron(canvas, Offset(cx, 66 * s), 4 * s, chestMarkerPaint);
    _drawChevron(canvas, Offset(cx - 10 * s, 76 * s), 3.5 * s, chestMarkerPaint);
    _drawChevron(canvas, Offset(cx + 10 * s, 76 * s), 3.5 * s, chestMarkerPaint);

    // 5. Right wing (folded along side)
    final rightWing = Path()
      ..moveTo(cx + 36 * s, 54 * s)
      ..cubicTo(cx + 52 * s, 62 * s, cx + 50 * s, 86 * s, cx + 32 * s, 88 * s)
      ..cubicTo(cx + 28 * s, 84 * s, cx + 32 * s, 64 * s, cx + 36 * s, 54 * s)
      ..close();
    canvas.drawPath(rightWing, bodyPaint);
    canvas.drawPath(rightWing, inkPaint);

    // 6. Left wing (waving hello)
    canvas.save();
    canvas.translate(cx - 36 * s, 58 * s);
    canvas.rotate(wingAngle);
    final leftWing = Path()
      ..moveTo(0, 0)
      ..cubicTo(-18 * s, -14 * s, -24 * s, 8 * s, -8 * s, 26 * s)
      ..cubicTo(4 * s, 26 * s, 6 * s, 10 * s, 0, 0)
      ..close();
    canvas.drawPath(leftWing, bodyPaint);
    canvas.drawPath(leftWing, inkPaint);
    canvas.restore();

    // 7. Rosy pink blushing cheeks
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 30 * s, 64 * s), width: 14 * s, height: 7 * s), blushPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 30 * s, 64 * s), width: 14 * s, height: 7 * s), blushPaint);

    // 8. Eyes (The hallmark expressive Duolingo eyes)
    final leftEyeCenter = Offset(cx - 16 * s, 50 * s);
    final rightEyeCenter = Offset(cx + 16 * s, 50 * s);
    final eyeRadius = 14.0 * s;

    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(leftEyeCenter, eyeRadius, whitePaint);
    canvas.drawCircle(leftEyeCenter, eyeRadius, inkPaint);
    canvas.drawCircle(rightEyeCenter, eyeRadius, whitePaint);
    canvas.drawCircle(rightEyeCenter, eyeRadius, inkPaint);

    final isBlinking = blinkValue > 0.4 || isCheering;
    if (isBlinking) {
      // Happy smiling closed crescents ^ ^
      final happyEyePaint = Paint()
        ..color = inkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8 * s
        ..strokeCap = StrokeCap.round;

      final leftArc = Path()
        ..moveTo(leftEyeCenter.dx - 8 * s, leftEyeCenter.dy + 2 * s)
        ..quadraticBezierTo(leftEyeCenter.dx, leftEyeCenter.dy - 7 * s, leftEyeCenter.dx + 8 * s, leftEyeCenter.dy + 2 * s);
      canvas.drawPath(leftArc, happyEyePaint);

      final rightArc = Path()
        ..moveTo(rightEyeCenter.dx - 8 * s, rightEyeCenter.dy + 2 * s)
        ..quadraticBezierTo(rightEyeCenter.dx, rightEyeCenter.dy - 7 * s, rightEyeCenter.dx + 8 * s, rightEyeCenter.dy + 2 * s);
      canvas.drawPath(rightArc, happyEyePaint);
    } else {
      // Open large black pupils
      final pupilRadius = 8.5 * s;
      final pupilPaint = Paint()..color = inkColor;
      canvas.drawCircle(leftEyeCenter, pupilRadius, pupilPaint);
      canvas.drawCircle(rightEyeCenter, pupilRadius, pupilPaint);

      // Large specular catchlight
      final bigShinePaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(leftEyeCenter.dx - 2.8 * s, leftEyeCenter.dy - 2.8 * s), 3.2 * s, bigShinePaint);
      canvas.drawCircle(Offset(rightEyeCenter.dx - 2.8 * s, rightEyeCenter.dy - 2.8 * s), 3.2 * s, bigShinePaint);

      // Small specular catchlight
      canvas.drawCircle(Offset(leftEyeCenter.dx + 3.0 * s, leftEyeCenter.dy + 3.0 * s), 1.5 * s, bigShinePaint);
      canvas.drawCircle(Offset(rightEyeCenter.dx + 3.0 * s, rightEyeCenter.dy + 3.0 * s), 1.5 * s, bigShinePaint);
    }

    // 9. Cute rounded beak
    final beak = Path()
      ..moveTo(cx - 7 * s, 54 * s)
      ..quadraticBezierTo(cx, 52 * s, cx + 7 * s, 54 * s)
      ..lineTo(cx, 67 * s)
      ..close();
    canvas.drawPath(beak, beakPaint);
    canvas.drawPath(beak, inkPaint);

    final beakHl = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 4 * s, 55 * s), Offset(cx + 4 * s, 55 * s), beakHl);

    // 10. Graduation Mortarboard Cap
    final capBase = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 22 * s), width: 28 * s, height: 8 * s),
      Radius.circular(4 * s),
    );
    canvas.drawRRect(capBase, capPaint);
    canvas.drawRRect(capBase, inkPaint);

    final capDiamond = Path()
      ..moveTo(cx, 8 * s)
      ..lineTo(cx + 32 * s, 16 * s)
      ..lineTo(cx, 24 * s)
      ..lineTo(cx - 32 * s, 16 * s)
      ..close();
    canvas.drawPath(capDiamond, capPaint);
    canvas.drawPath(capDiamond, inkPaint);

    // Gold button & swinging tassel
    canvas.drawCircle(Offset(cx, 16 * s), 3.0 * s, goldPaint);
    final tasselPath = Path()
      ..moveTo(cx, 16 * s)
      ..quadraticBezierTo(cx + 20 * s, 18 * s, cx + 26 * s, 28 * s);
    canvas.drawPath(tasselPath, goldStroke);

    final tasselFringe = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 26 * s, 32 * s), width: 6 * s, height: 8 * s),
      Radius.circular(2 * s),
    );
    canvas.drawRRect(tasselFringe, goldPaint);
    canvas.drawRRect(tasselFringe, inkPaint);

    canvas.restore();
  }

  void _drawFoot(Canvas canvas, Offset pos, double s, Paint fill, Paint stroke) {
    final foot = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: 20 * s, height: 9 * s),
      Radius.circular(5 * s),
    );
    canvas.drawRRect(foot, fill);
    canvas.drawRRect(foot, stroke);
  }

  void _drawChevron(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx - radius, center.dy + radius * 0.5)
      ..lineTo(center.dx, center.dy)
      ..lineTo(center.dx + radius, center.dy + radius * 0.5);
    canvas.drawPath(path, paint);
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DuolingoMascotPainter old) {
    return old.bobOffset != bobOffset ||
        old.wingAngle != wingAngle ||
        old.blinkValue != blinkValue ||
        old.cheerScale != cheerScale ||
        old.isCheering != isCheering;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE COMIC MICRO TAG
// ─────────────────────────────────────────────────────────────────────────────

class _ComicMicroTag extends StatelessWidget {
  const _ComicMicroTag({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: NeoBrutalColors.ink, width: 1.0),
        boxShadow: NeoBrutalShadows.hardXs,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTypography.displayFamily,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
