import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/models/avatar_models.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_surfaces.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../avatar/providers/avatar_providers.dart';
import '../widgets/avatar_visual.dart';

class CharacterCollectionScreen extends ConsumerStatefulWidget {
  const CharacterCollectionScreen({super.key});

  @override
  ConsumerState<CharacterCollectionScreen> createState() => _CharacterCollectionScreenState();
}

class _CharacterCollectionScreenState extends ConsumerState<CharacterCollectionScreen> {
  String _filter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final collectionAsync = ref.watch(avatarCollectionProvider);
    final collection = collectionAsync.data;
    final error = collectionAsync.error;
    final isLoading = collectionAsync.showLoading;

    final items = collection?.items ?? [];
    final filtered = _applyFilter(items, _filter);
    final ownedCount = items.where((e) => e.owned).length;
    final total = items.length;

    // Next unlock: cheapest purchasable or next claimable
    final nextUnlock = _findNextUnlock(items, collection?.creditsAvailable ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CHARACTER COLLECTION'),
        actions: [
          if (collection != null) Center(child: Padding(padding: const EdgeInsets.only(right: 12), child: CreditsPill(credits: collection.creditsAvailable))),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AtmosphericBackground()),
          if (isDark) ...[
            Positioned(top: -30, right: -20, child: GlowOrb(color: AppColors.primary, size: 200, opacity: 0.06)),
          ],
          RefreshIndicator(
            color: AppColors.primaryBright,
            backgroundColor: isDark ? AppColors.surfaceElevated : Colors.white,
            onRefresh: () async => ref.read(avatarCollectionProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: AppGutters.pagePadding(context), vertical: 12),
                  sliver: SliverList.list(
                    children: [
                      ResponsiveCenter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Progress header
                            _CollectionHeader(ownedCount: ownedCount, total: total, credits: collection?.creditsAvailable ?? 0),
                            const SizedBox(height: 12),
                            // Next unlock
                            if (nextUnlock != null) ...[
                              _NextUnlockCard(item: nextUnlock, creditsAvailable: collection?.creditsAvailable ?? 0),
                              const SizedBox(height: 16),
                            ] else if (ownedCount == total && total > 0) ...[
                              _CompletedCard(),
                              const SizedBox(height: 16),
                            ],
                            // Filters
                            _FilterChips(selected: _filter, onSelect: (v) => setState(() => _filter = v)),
                            const SizedBox(height: 12),
                            // Content
                            if (isLoading && collection == null)
                              const _SkeletonGrid()
                            else if (error != null && collection == null)
                              ErrorState(
                                title: 'COLLECTION UNAVAILABLE',
                                message: 'We couldn\'t load your characters.',
                                onRetry: () => ref.read(avatarCollectionProvider.notifier).refresh(),
                              )
                            else if (filtered.isEmpty)
                              _EmptyFilterState(filter: _filter)
                            else ...[
                              _CharacterGrid(items: filtered),
                              if (error != null && collection != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.warning.withValues(alpha: 0.3))),
                                    child: Row(children: [const Icon(Icons.cloud_off_rounded, size: 14, color: AppColors.warning), const SizedBox(width: 8), Expanded(child: Text('Showing last snapshot — offline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)))]),
                                  ),
                                ),
                            ],
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
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

  List<AvatarCollectionItem> _applyFilter(List<AvatarCollectionItem> items, String filter) {
    return switch (filter) {
      'OWNED' => items.where((e) => e.owned).toList(),
      'LOCKED' => items.where((e) => !e.owned && !e.eligible).toList(),
      'AVAILABLE' => items.where((e) => !e.owned && e.eligible).toList(),
      _ => items,
    };
  }

  AvatarCollectionItem? _findNextUnlock(List<AvatarCollectionItem> items, int credits) {
    // Prefer cheapest purchasable, then next claimable
    final purchasable = items.where((e) => e.state == AvatarState.purchasable).toList()
      ..sort((a, b) => (a.creditCost ?? 999999).compareTo(b.creditCost ?? 999999));
    if (purchasable.isNotEmpty) return purchasable.first;
    final claimable = items.where((e) => e.state == AvatarState.eligibleToClaim).toList();
    if (claimable.isNotEmpty) return claimable.first;
    // Next insufficient with smallest deficit
    final insufficient = items.where((e) => e.state == AvatarState.insufficientCredits).toList()
      ..sort((a, b) => (a.creditsShort ?? 999999).compareTo(b.creditsShort ?? 999999));
    if (insufficient.isNotEmpty) return insufficient.first;
    // Next locked with fewest requirements
    final locked = items.where((e) => e.state == AvatarState.locked).toList()
      ..sort((a, b) => a.requirements.length.compareTo(b.requirements.length));
    return locked.isEmpty ? null : locked.first;
  }
}

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({required this.ownedCount, required this.total, required this.credits});
  final int ownedCount;
  final int total;
  final int credits;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FeaturedSurface(
      accent: AppColors.primary,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHARACTER COLLECTION', style: AppTypography.overline(context).copyWith(color: AppColors.primaryBright)),
                const SizedBox(height: 4),
                Text('$ownedCount / $total OWNED', style: AppTypography.hero(context, size: 20)),
                const SizedBox(height: 4),
                Text('Collect by learning — every character is earned, never bought with real money.', style: AppTypography.caption(context)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CreditsPill(credits: credits),
        ],
      ),
    );
  }
}

class _NextUnlockCard extends StatelessWidget {
  const _NextUnlockCard({required this.item, required this.creditsAvailable});
  final AvatarCollectionItem item;
  final int creditsAvailable;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPurchasable = item.state == AvatarState.purchasable || item.state == AvatarState.insufficientCredits;
    return GameChallengeSurface(
      accent: isPurchasable ? AppColors.xp : AppColors.primary,
      title: 'NEXT UNLOCK',
      icon: Icons.lock_open_rounded,
      child: Row(
        children: [
          AvatarVisual(assetKey: item.assetKey, displayName: item.displayName, rarity: item.rarity, size: 56, showGlow: item.rarity.toLowerCase() == 'legendary'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.displayName.toUpperCase(), style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 14, fontWeight: FontWeight.w800)),
                Text(item.rarity.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.primary)),
                const SizedBox(height: 4),
                if (isPurchasable)
                  Text(item.creditCost != null ? '${item.creditCost} Credits • You have $creditsAvailable' : 'Free to claim', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary))
                else
                  Text(item.requirements.isNotEmpty ? '${item.requirements.first.type}: ${item.requirements.first.required}' : 'Keep learning to unlock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
                if (item.creditsShort != null && item.creditsShort! > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${item.creditsShort} Credits remaining', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.xp)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => context.push('/profile/characters/${item.id}'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            child: Text(item.state == AvatarState.insufficientCredits ? 'VIEW' : 'VIEW', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.xp.withValues(alpha: 0.15), Theme.of(context).colorScheme.surface]), borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.xp.withValues(alpha: 0.3))),
      child: Row(children: [const Icon(Icons.emoji_events_rounded, color: AppColors.xp), const SizedBox(width: 8), Expanded(child: Text('Collection complete — you own every champion!', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.xp)))]),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) {
    const filters = ['ALL', 'OWNED', 'AVAILABLE', 'LOCKED'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: selected == f ? Colors.white : null)),
                selected: selected == f,
                onSelected: (_) => onSelect(f),
                selectedColor: AppColors.primary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                side: BorderSide(color: selected == f ? AppColors.primary : (Theme.of(context).brightness == Brightness.dark ? AppColors.border : AppLightColors.border)),
              ),
            ),
        ],
      ),
    );
  }
}

class _CharacterGrid extends StatelessWidget {
  const _CharacterGrid({required this.items});
  final List<AvatarCollectionItem> items;
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final crossAxisCount = w >= AppBreakpoints.expanded ? 4 : (w >= AppBreakpoints.compact ? 3 : 2);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _CharacterCard(item: items[index], index: index),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.item, required this.index});
  final AvatarCollectionItem item;
  final int index;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduce = AppMotion.reducedMotion(context);
    final isLocked = item.state == AvatarState.locked;
    final isOwned = item.owned;
    final borderColor = switch (item.rarity.toLowerCase()) {
      'legendary' || 'prestige' => AppColors.xp,
      'epic' => AppColors.primary,
      'rare' => AppColors.secondary,
      _ => isDark ? AppColors.border : AppLightColors.border,
    };
    Widget card = Semantics(
      label: '${item.displayName}, ${item.rarity}, ${item.state.name}',
      button: true,
      child: GestureDetector(
        onTap: () => context.push('/profile/characters/${item.id}'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: isOwned ? borderColor.withValues(alpha: 0.6) : (isDark ? AppColors.border : AppLightColors.border), width: isOwned ? 1.5 : 1),
            boxShadow: isOwned && isDark ? [BoxShadow(color: borderColor.withValues(alpha: 0.12), blurRadius: 12)] : null,
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: isLocked ? 0.45 : 1,
                    child: AvatarVisual(assetKey: item.assetKey, displayName: item.displayName, rarity: item.rarity, size: 64, showGlow: item.rarity.toLowerCase() == 'legendary' && isOwned),
                  ),
                  if (isLocked)
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.35)),
                      child: const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
                    ),
                  if (item.equipped)
                    Positioned(
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white, width: 1)),
                        child: const Text('EQUIPPED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.6)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(item.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)),
              Text(item.rarity.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: borderColor)),
              const SizedBox(height: 6),
              _StatePill(state: item.state, creditCost: item.creditCost, creditsShort: item.creditsShort),
            ],
          ),
        ),
      ),
    );
    if (reduce) return card;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.fast + Duration(milliseconds: index * 20),
      curve: AppMotion.easeOut,
      builder: (context, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child)),
      child: card,
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.state, this.creditCost, this.creditsShort});
  final AvatarState state;
  final int? creditCost;
  final int? creditsShort;
  @override
  Widget build(BuildContext context) {
    final (String label, Color color, Color bg) = switch (state) {
      AvatarState.equipped => ('EQUIPPED', AppColors.success, AppColors.success.withValues(alpha: 0.12)),
      AvatarState.owned => ('OWNED', AppColors.primary, AppColors.primary.withValues(alpha: 0.12)),
      AvatarState.purchasable => ('${creditCost ?? ''} CREDITS', AppColors.xp, AppColors.xp.withValues(alpha: 0.12)),
      AvatarState.insufficientCredits => ('${creditsShort ?? ''} NEEDED', AppColors.warning, AppColors.warning.withValues(alpha: 0.12)),
      AvatarState.eligibleToClaim => ('CLAIM FREE', AppColors.success, AppColors.success.withValues(alpha: 0.12)),
      AvatarState.locked => ('LOCKED', AppColors.locked, AppColors.locked.withValues(alpha: 0.1)),
      AvatarState.unknown => ('UNKNOWN', AppColors.locked, AppColors.locked.withValues(alpha: 0.1)),
    };
    if (state == AvatarState.locked && creditCost == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: color)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: color)),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.78),
      itemCount: 6,
      itemBuilder: (_, __) => Container(decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.border : AppLightColors.border))),
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState({required this.filter});
  final String filter;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.border : AppLightColors.border)),
      child: Column(children: [Icon(Icons.filter_list_off_rounded, size: 32, color: AppColors.textTertiary), const SizedBox(height: 8), Text('No $filter characters', style: AppTypography.h3(context)), Text('Try another filter.', style: AppTypography.bodySecondary(context))]),
    );
  }
}
