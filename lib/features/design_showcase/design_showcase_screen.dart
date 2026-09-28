import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_depth.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/game_visual_identity.dart';
import '../../core/theme/subject_visual_identity.dart';
import '../../core/theme/theme_controller.dart';
import '../../features/game_engine/models/game_models.dart';
import '../../shared/widgets/app_backgrounds.dart';
import '../../shared/widgets/asset_placeholder.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/game_button.dart';
import '../../shared/widgets/game_card.dart';
import '../../shared/widgets/game_surfaces.dart';
import '../../shared/widgets/nova_companion.dart';
import '../../shared/widgets/premium_buttons.dart';
import '../../shared/widgets/progress_indicators.dart';
import '../../shared/widgets/progression_widgets.dart';
import '../../shared/widgets/responsive_layout.dart';

/// INTERNAL DESIGN SHOWCASE — validates the Phase 1 visual foundation.
///
/// NOT accessible from production navigation.
/// Route: /design-showcase (development only).
/// Safe to keep in codebase — does not appear in user-facing nav.
///
/// To access during development, navigate directly to the route.
class DesignShowcaseScreen extends ConsumerStatefulWidget {
  const DesignShowcaseScreen({super.key});

  @override
  ConsumerState<DesignShowcaseScreen> createState() =>
      _DesignShowcaseScreenState();
}

class _DesignShowcaseScreenState extends ConsumerState<DesignShowcaseScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      body: Stack(
        children: [
          const AtmosphericBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                _buildTabBar(context),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _ColorsTab(),
                      _SurfacesTab(),
                      _ButtonsTab(),
                      _ProgressTab(),
                      _GameIdentityTab(),
                      _TypographyTab(),
                      _BackgroundsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(AppIcons.back, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DESIGN SHOWCASE', style: AppTypography.overline(context)),
                Text(
                  'Visual Foundation 2.0',
                  style: AppTypography.h3(context),
                ),
              ],
            ),
          ),
          // Theme toggle
          GestureDetector(
            onTap: () {
              final controller = ref.read(themeControllerProvider.notifier);
              final current = ref.read(themeControllerProvider);
              controller.set(
                current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                isDark ? AppIcons.themeLight : AppIcons.themeDark,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    const tabs = [
      'Colors', 'Surfaces', 'Buttons',
      'Progress', 'Games', 'Type', 'Bg'
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: context.surfaceColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: context.borderColor),
      ),
      child: TabBar(
        controller: _tabs,
        isScrollable: true,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: AppGradients.brand,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: context.textSecondaryColor,
        labelStyle: const TextStyle(
          fontFamily: 'GameLearnBody',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        tabs: tabs.map((t) => Tab(text: t, height: 36)).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COLORS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _ColorsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = [
      ('Primary', AppColors.primary),
      ('Primary Bright', AppColors.primaryBright),
      ('Primary Deep', AppColors.primaryDeep),
      ('Secondary', AppColors.secondary),
      ('Success', AppColors.success),
      ('Warning', AppColors.warning),
      ('Error', AppColors.error),
      ('XP Gold', AppColors.xp),
      ('Streak', AppColors.streak),
      ('Info', AppColors.info),
      ('Locked', AppColors.locked),
    ];

    return _ShowcaseScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Brand Accents'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: colors.map((c) => _ColorSwatch(c.$1, c.$2)).toList(),
          ),
          _SectionHeader('Surface Levels (Dark)'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ('Background', AppColors.background),
              ('BackgroundElevated', AppColors.backgroundElevated),
              ('Surface', AppColors.surface),
              ('SurfaceElevated', AppColors.surfaceElevated),
              ('SurfaceHigh', AppColors.surfaceHigh),
              ('SurfaceInteractive', AppColors.surfaceInteractive),
              ('SurfaceSelected', AppColors.surfaceSelected),
            ].map((c) => _ColorSwatch(c.$1, c.$2, size: 70)).toList(),
          ),
          _SectionHeader('Glow Colors'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ('Glow Primary', AppColors.glowPrimary),
              ('Glow Cyan', AppColors.glowSecondary),
              ('Glow XP', AppColors.glowXP),
              ('Glow Success', AppColors.glowSuccess),
            ].map((c) => _ColorSwatch(c.$1, c.$2)).toList(),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch(this.name, this.color, {this.size = 60});
  final String name;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.borderColor),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: size,
          child: Text(
            name,
            style: AppTypography.overline(context),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SURFACES TAB
// ─────────────────────────────────────────────────────────────────────────────
class _SurfacesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ShowcaseScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('GameCard Variants'),
          ...[
            GameCardVariant.standard,
            GameCardVariant.elevated,
            GameCardVariant.reward,
            GameCardVariant.success,
            GameCardVariant.featured,
            GameCardVariant.locked,
          ].map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GameCard(
                variant: v,
                child: Row(
                  children: [
                    Icon(Icons.layers_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      v.name.toUpperCase(),
                      style: AppTypography.label(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _SectionHeader('Depth System'),
          ...DepthLevel.values.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DepthContainer(
                level: l,
                padding: const EdgeInsets.all(14),
                accent: AppColors.primary,
                child: Text(
                  'DepthLevel.${l.name}',
                  style: AppTypography.bodySecondary(context),
                ),
              ),
            ),
          ),
          _SectionHeader('Featured Surface'),
          FeaturedSurface(
            child: Text(
              'Featured Surface — use for hero content',
              style: AppTypography.body(context),
            ),
          ),
          const SizedBox(height: 12),
          _SectionHeader('Game Identity Surface'),
          GameIdentitySurface(
            accent: AppColors.secondary,
            showGlow: true,
            child: Text(
              'Game Identity Surface — accent from GameVisualIdentity',
              style: AppTypography.body(context),
            ),
          ),
          const SizedBox(height: 12),
          _SectionHeader('Glass Card'),
          GlassCard(
            child: Text(
              'Glass Card — for hero sections over gradients',
              style: AppTypography.body(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUTTONS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _ButtonsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ShowcaseScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Primary'),
          PrimaryGameButton(label: 'Start Learning', onTap: () {}),
          const SizedBox(height: 10),
          PrimaryGameButton(label: 'Disabled', onTap: null),
          const SizedBox(height: 10),
          PrimaryGameButton(label: 'Loading', onTap: () {}, busy: true),
          _SectionHeader('Secondary'),
          SecondaryGameButton(label: 'View Details', onTap: () {}),
          _SectionHeader('Ghost'),
          GhostGameButton(label: 'Skip', onTap: () {}),
          _SectionHeader('Game Action'),
          GameActionButton(label: 'Play Now', onTap: () {}),
          _SectionHeader('Danger'),
          DangerGameButton(label: 'Delete Progress', onTap: () {}, icon: Icons.delete_rounded),
          _SectionHeader('Reward'),
          RewardButton(label: 'Claim XP', onTap: () {}),
          _SectionHeader('Icon Actions'),
          Row(
            children: [
              IconActionButton(
                icon: AppIcons.back,
                onTap: () {},
                semanticLabel: 'Back',
              ),
              const SizedBox(width: 12),
              IconActionButton(
                icon: AppIcons.settings,
                onTap: () {},
                semanticLabel: 'Settings',
                filled: true,
              ),
              const SizedBox(width: 12),
              IconActionButton(
                icon: AppIcons.share,
                onTap: () {},
                semanticLabel: 'Share',
                color: AppColors.secondary,
                filled: true,
              ),
            ],
          ),
          _SectionHeader('Chips'),
          Wrap(
            spacing: 8,
            children: [
              GameChip(label: 'Continue', onTap: () {}),
              GameChip(
                label: 'View Results',
                onTap: () {},
                icon: AppIcons.next,
                color: AppColors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ShowcaseScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Badges'),
          Wrap(
            spacing: 12,
            children: [
              XPBadge(xp: 250),
              StreakChip(days: 7),
              LevelBadge(level: 12),
              DifficultyBadge(difficulty: 'HARD'),
              DifficultyBadge(difficulty: 'MEDIUM'),
              DifficultyBadge(difficulty: 'EASY'),
            ],
          ),
          _SectionHeader('Status Pills'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: StatusKind.values
                .map((k) => StatusPill(kind: k))
                .toList(),
          ),
          _SectionHeader('State Chips'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ProgressionState.values
                .map((s) => StateChip(state: s))
                .toList(),
          ),
          _SectionHeader('Mastery Orbs'),
          Row(
            children: [
              MasteryOrb(fraction: 1.0, size: 64, animate: false),
              const SizedBox(width: 12),
              MasteryOrb(fraction: 0.72, size: 64, animate: false),
              const SizedBox(width: 12),
              MasteryOrb(fraction: 0.45, size: 64, animate: false),
              const SizedBox(width: 12),
              MasteryOrb(fraction: 0.15, size: 64, animate: false),
            ],
          ),
          _SectionHeader('Path Nodes'),
          Row(
            children: [
              PathNodeIndicator(status: 'COMPLETED', sequenceNumber: 1),
              const SizedBox(width: 12),
              PathNodeIndicator(status: 'IN_PROGRESS', sequenceNumber: 2),
              const SizedBox(width: 12),
              PathNodeIndicator(status: 'AVAILABLE', sequenceNumber: 3),
              const SizedBox(width: 12),
              PathNodeIndicator(status: 'LOCKED', sequenceNumber: 4),
            ],
          ),
          _SectionHeader('XP Display'),
          XPEarnedDisplay(xpEarned: 450, large: true, animate: false),
          const SizedBox(height: 10),
          XPEarnedDisplay(xpEarned: 125, animate: false),
          _SectionHeader('Progress Bars'),
          MasteryBar(mastery: 0.85),
          const SizedBox(height: 8),
          XPProgress(fraction: 0.62, animate: false),
          _SectionHeader('Reward Badge Frame'),
          Row(
            children: [
              RewardBadgeFrame(
                size: 72,
                child: Icon(AppIcons.achievement, size: 36, color: AppColors.xp),
              ),
              const SizedBox(width: 12),
              RewardBadgeFrame(
                size: 72,
                unlocked: false,
                child: Icon(AppIcons.locked, size: 36, color: AppColors.locked),
              ),
            ],
          ),
          _SectionHeader('Nova Companion'),
          Row(
            children: NovaMood.values
                .map((m) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          NovaCompanion(size: 48, mood: m),
                          const SizedBox(height: 4),
                          Text(m.name, style: AppTypography.overline(context)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GAME IDENTITY TAB
// ─────────────────────────────────────────────────────────────────────────────
class _GameIdentityTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ShowcaseScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Game Visual Identities (14 Games)'),
          ...GameType.values.map((type) {
            final identity = GameVisualRegistry.of(type);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GameIdentitySurface(
                accent: identity.accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: identity.gradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        identity.icon,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.displayName,
                            style: AppTypography.h3(context),
                          ),
                          Text(
                            identity.category.toUpperCase(),
                            style: AppTypography.overline(context),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: identity.accent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          _SectionHeader('Subject Visual Identities'),
          ...SubjectVisualRegistry.known.map((identity) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GameCard(
                child: Row(
                  children: [
                    SubjectIcon(iconKey: identity.iconKey, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            identity.displayName,
                            style: AppTypography.h3(context),
                          ),
                          Text(
                            identity.motif,
                            style: AppTypography.caption(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPOGRAPHY TAB
// ─────────────────────────────────────────────────────────────────────────────
class _TypographyTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ShowcaseScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Display Large', style: AppTypography.displayLarge(context, size: 32)),
          const SizedBox(height: 8),
          Text('Hero Style', style: AppTypography.hero(context)),
          const SizedBox(height: 8),
          Text('H1 Page Title', style: AppTypography.h1(context)),
          const SizedBox(height: 8),
          Text('Game Title', style: AppTypography.gameTitle(context)),
          const SizedBox(height: 8),
          Text('H2 Section Title', style: AppTypography.h2(context)),
          const SizedBox(height: 8),
          Text('H3 Card Title', style: AppTypography.h3(context)),
          const SizedBox(height: 8),
          Text('Body text — readable at all sizes.', style: AppTypography.body(context)),
          const SizedBox(height: 8),
          Text('Body Secondary — supporting detail.', style: AppTypography.bodySecondary(context)),
          const SizedBox(height: 8),
          Text('Body Emphasis', style: AppTypography.bodyEmphasis(context)),
          const SizedBox(height: 8),
          Text('Caption text', style: AppTypography.caption(context)),
          const SizedBox(height: 8),
          Text('LABEL TEXT', style: AppTypography.label(context)),
          const SizedBox(height: 8),
          Text('OVERLINE', style: AppTypography.overline(context)),
          const SizedBox(height: 16),
          _SectionHeader('Game Numbers'),
          Text('1250 XP', style: AppTypography.xpNumber(context, size: 36)),
          const SizedBox(height: 8),
          Text('Level 12', style: AppTypography.levelNumber(context, size: 28)),
          const SizedBox(height: 8),
          Text('7 Days', style: AppTypography.streakNumber(context, size: 28)),
          const SizedBox(height: 8),
          Text('9850', style: AppTypography.statNumber(context, size: 32, color: AppColors.success, glow: true)),
          const SizedBox(height: 8),
          Text('98%', style: AppTypography.metric(context, size: 40)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKGROUNDS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _BackgroundsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ShowcaseScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Glow Orbs'),
          Wrap(
            spacing: 12,
            children: [
              GlowOrb(color: AppColors.primary, size: 80, opacity: 0.4),
              GlowOrb(color: AppColors.secondary, size: 80, opacity: 0.4),
              GlowOrb(color: AppColors.xp, size: 80, opacity: 0.4),
              GlowOrb(color: AppColors.success, size: 80, opacity: 0.4),
              GlowOrb(color: AppColors.error, size: 80, opacity: 0.4),
            ],
          ),
          _SectionHeader('Gradient Wash'),
          GradientWash(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(16),
            child: Text(
              'GradientWash — default brand wash',
              style: AppTypography.body(context),
            ),
          ),
          const SizedBox(height: 12),
          GradientWash(
            gradient: AppGradients.success,
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(16),
            child: Text(
              'GradientWash — success gradient',
              style: AppTypography.body(context),
            ),
          ),
          _SectionHeader('Asset Placeholders'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AssetPlaceholder(
                icon: AppIcons.nova,
                label: 'Nova',
                size: const Size(80, 80),
              ),
              AssetPlaceholder(
                icon: Icons.public_rounded,
                label: 'World',
                color: AppColors.secondary,
                size: const Size(80, 80),
              ),
              AssetPlaceholder(
                icon: AppIcons.achievement,
                label: 'Badge',
                color: AppColors.xp,
                size: const Size(80, 80),
              ),
            ],
          ),
          _SectionHeader('Avatar Placeholders'),
          Row(
            children: [
              AvatarPlaceholder(initials: 'AK', size: 48),
              const SizedBox(width: 10),
              AvatarPlaceholder(initials: 'VR', size: 56),
              const SizedBox(width: 10),
              AvatarPlaceholder(size: 40),
            ],
          ),
          _SectionHeader('Challenge Indicators'),
          ChallengeIndicator(
            label: 'Complete 3 Quiz Battles',
            completed: false,
            progressFraction: 0.66,
          ),
          const SizedBox(height: 8),
          ChallengeIndicator(
            label: 'Reach 5-day streak',
            completed: true,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _ShowcaseScrollView extends StatelessWidget {
  const _ShowcaseScrollView({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: ResponsiveCenter(
        maxWidth: AppBreakpoints.maxContentWidth,
        padding: EdgeInsets.zero,
        child: child,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(
        children: [
          Text(title.toUpperCase(), style: AppTypography.overline(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: context.borderColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
