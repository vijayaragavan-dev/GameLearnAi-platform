import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/error/user_facing_error.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/cinematic_scenery.dart';
import '../../../shared/widgets/cinematic_surfaces.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/game_card.dart';
import '../../../shared/widgets/game_surfaces.dart';
import '../../../shared/widgets/nova_companion.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../subjects/domain/canonical_worlds.dart';
import '../data/realm_models.dart';
import '../domain/learning_realm.dart';

/// LEARNING REALMS — top-level domain selection, one layer above worlds.
///
/// Backend is authoritative for which realms exist and are active
/// (`GET /api/v1/realms`); the frontend catalog supplies presentation
/// metadata plus honest Coming Soon placeholders for realms the
/// backend does not list. No realm duplicates worlds: the Computer
/// Science card derives its world count from `WorldCatalog.all.length`
/// at build time. Coming Soon realms carry zero metrics.
class RealmsScreen extends ConsumerStatefulWidget {
  const RealmsScreen({super.key});

  @override
  ConsumerState<RealmsScreen> createState() => _RealmsScreenState();
}

class _RealmsScreenState extends ConsumerState<RealmsScreen> {
  late Future<List<BackendRealm>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(realmRepoProvider).realms();
  }

  void _retry() => setState(() {
    _future = ref.read(realmRepoProvider).realms();
  });

  void _openComputerScience(BuildContext context) {
    // The realm IS the existing world experience — no new route.
    context.go(Routes.subjects);
  }

  /// Single realm→experience decision point. World-backed realms resolve
  /// into the existing world flow; every other backend realm opens the
  /// generic realm landing (which renders subject content or an honest
  /// empty state). No realm knowledge leaks into widgets below this.
  void _openRealm(BuildContext context, ResolvedRealm realm) {
    if (realm.isWorldBased) {
      _openComputerScience(context);
      return;
    }
    context.push(Routes.realm(realm.backend.realmKey));
  }

  Future<void> _showComingSoon(BuildContext context, LearningRealm realm) {
    return showPremiumDialog<void>(
      context: context,
      builder: (dialogContext) => CinematicDialog(
        accent: realm.accent,
        title: Text('${realm.title} — Coming Soon'),
        content: Text(
          '${realm.title} is a future realm and has no lessons, progress or rankings yet. '
          'Computer Science is fully open — your XP, mastery and streaks live there.',
        ),
        actions: [
          PremiumDialogActions(
            primaryLabel: 'Explore Computer Science',
            onPrimary: () {
              Navigator.of(dialogContext).pop();
              _openComputerScience(context);
            },
            secondaryLabel: 'Not now',
            onSecondary: () => Navigator.of(dialogContext).pop(),
            accent: AppColors.primary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('LEARNING REALMS')),
      body: Stack(
        children: [
          const Positioned.fill(child: AtmosphericBackground()),
          if (isDark)
            const Positioned(
              top: -60,
              right: -40,
              child: GlowOrb(
                color: AppColors.primary,
                size: 260,
                opacity: 0.10,
              ),
            ),
          // Full-screen route outside the shell: no command dock renders
          // here, so only the system SafeArea inset + content spacing
          // apply (same convention as arena/character routes). No dock
          // metrics dependency by design.
          SafeArea(
            top: true,
            bottom: true,
            child: FutureBuilder<List<BackendRealm>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done &&
                    !snap.hasData) {
                  return const CinematicLoading(
                    message: 'Discovering realms...',
                  );
                }
                if (snap.hasError) {
                  final err = describeError(snap.error!);
                  return ErrorState(
                    title: err.title,
                    message: err.message,
                    onRetry: _retry,
                  );
                }
                final backend = snap.data ?? const <BackendRealm>[];
                if (backend.isEmpty) {
                  return const EmptyState(
                    icon: Icons.public_off_rounded,
                    title: 'No realms yet',
                    message:
                        'New learning realms are being prepared. Check back soon.',
                  );
                }
                // Backend owns existence/availability; the frontend catalog
                // supplies presentation. Backend-absent catalog entries
                // stay as honest Coming Soon placeholders (never content).
                final resolved = backend
                    .map(ResolvedRealm.resolve)
                    .toList(growable: false);
                final backendKeys =
                    backend.map((r) => r.realmKey).toSet();
                final coming = LearningRealmCatalog.all
                    .where((r) =>
                        r.isComingSoon && !backendKeys.contains(r.key))
                    .toList(growable: false);
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ResponsiveCenter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppGutters.pagePadding(context),
                        8,
                        AppGutters.pagePadding(context),
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── REALM HERO ──
                          CinematicHero(
                            accent: AppColors.primary,
                            badge: 'Realms',
                            badgeIcon: Icons.public_rounded,
                            scene: ScenePalette.violet,
                            sceneSeed: 42,
                            title: Text(
                              'LEARNING UNIVERSE',
                              style: AppTypography.hero(context, size: 26),
                            ),
                            subtitle: Row(
                              children: [
                                const NovaCompanion(
                                  size: 38,
                                  mood: NovaMood.encouraging,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'One universe, many realms. Explore Computer Science worlds and Aptitude skills.',
                                    style:
                                        AppTypography.bodySecondary(context),
                                  ),
                                ),
                              ],
                            ),
                            tagline: 'LEARN • EXPLORE\nMASTER • LEVEL UP',
                          ),
                          const SizedBox(height: 18),
                          // ── ACTIVE REALMS (backend-driven) ──
                          for (final realm in resolved) ...[
                            _ActiveRealmCard(
                              realm: realm,
                              worldCount: realm.isWorldBased
                                  ? WorldCatalog.all.length
                                  : null,
                              onEnter: () => _openRealm(context, realm),
                            ),
                            const SizedBox(height: 18),
                          ],
                          // ── COMING SOON ──
                          if (coming.isNotEmpty) ...[
                            const NeonSectionHeader(
                              icon: Icons.hourglass_empty_rounded,
                              title: 'Future realms',
                              subtitle: 'New horizons on the way',
                              accent: AppColors.secondary,
                            ),
                            const SizedBox(height: 12),
                            AdaptiveGrid(
                              compact: 1,
                              medium: 2,
                              expanded: 3,
                              wide: 3,
                              spacing: 12,
                              children: [
                                for (final realm in coming)
                                  _ComingSoonRealmCard(
                                    realm: realm,
                                    onTap: () =>
                                        _showComingSoon(context, realm),
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Featured active-realm card — gateway into a realm's experience.
/// For Computer Science the world count derives live from
/// [WorldCatalog]; other realms show no metrics (never fabricated).
/// Pass null [worldCount] to hide the metric row entirely.
class _ActiveRealmCard extends StatelessWidget {
  const _ActiveRealmCard({
    required this.realm,
    required this.worldCount,
    required this.onEnter,
  });

  final ResolvedRealm realm;
  final int? worldCount;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Pressable(
      onTap: onEnter,
      semanticsLabel: worldCount == null
          ? 'Enter realm ${realm.backend.name}'
          : 'Enter realm ${realm.backend.name}, $worldCount worlds available',
      child: FeaturedSurface(
        accent: realm.accent,
        scene: realm.scene,
        sceneSeed: seedForKey(realm.backend.realmKey),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.brand,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                      width: 1.4,
                    ),
                    boxShadow: AppShadows.glow(
                      realm.accent,
                      alpha: isDark ? 0.35 : 0.18,
                    ),
                  ),
                  child: Icon(
                    realm.icon,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        realm.backend.name.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        realm.visual?.tagline ?? 'A new learning frontier.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppLightColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(
                      alpha: isDark ? 0.14 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 13,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 2),
                      Text(
                        'OPEN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              realm.backend.description.isNotEmpty
                  ? realm.backend.description
                  : (realm.visual?.description ?? ''),
              style: AppTypography.bodySecondary(context),
            ),
            if (worldCount != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.public_rounded,
                    size: 15,
                    color: AppColors.primaryBright,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$worldCount worlds inside — progress, XP and streaks live here',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimary
                            : AppLightColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: realm.accent.withValues(
                      alpha: isDark ? 0.14 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: realm.accent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    // Data-driven structure identity derived from the
                    // realm's structure (SKILL-BASED, DOMAIN-BASED, …) —
                    // never hardcoded per realm.
                    _structureLabel(realm.structure),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: realm.accent,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            PrimaryGameButton(
              label: 'Enter realm',
              icon: Icons.arrow_forward_rounded,
              onTap: onEnter,
            ),
          ],
        ),
      ),
    );
  }
}

/// Human label for a realm's learning structure ("SKILL-BASED
/// LEARNING"). Derived from the enum name so new structures render
/// correctly without per-realm string mapping.
String _structureLabel(RealmLearningStructure structure) {
  final spaced = structure.name.replaceAllMapped(
    RegExp('[A-Z]'),
    (m) => '-${m.group(0)}',
  );
  return '${spaced.toUpperCase()} LEARNING';
}

/// Honest locked placeholder — attractive, clearly Coming Soon,
/// zero metrics, opens an informational dialog (never content).
class _ComingSoonRealmCard extends StatelessWidget {
  const _ComingSoonRealmCard({required this.realm, required this.onTap});

  final LearningRealm realm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Pressable(
      onTap: onTap,
      semanticsLabel:
          '${realm.title} realm, coming soon. Activate for details',
      child: GameCard(
        variant: GameCardVariant.locked,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: realm.accent.withValues(
                      alpha: isDark ? 0.14 : 0.10,
                    ),
                    border: Border.all(
                      color: realm.accent.withValues(alpha: 0.40),
                    ),
                  ),
                  child: Icon(
                    realm.icon,
                    size: 22,
                    color: realm.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        realm.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        realm.tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppLightColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: AppColors.locked,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                color: AppColors.locked.withValues(
                  alpha: isDark ? 0.12 : 0.08,
                ),
                border: Border.all(
                  color: AppColors.locked.withValues(alpha: 0.35),
                ),
              ),
              child: const Text(
                'COMING SOON',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: AppColors.locked,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
