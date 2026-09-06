import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/user_facing_error.dart';
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
import '../providers/avatar_providers.dart';
import '../widgets/avatar_visual.dart';

class CharacterDetailScreen extends ConsumerStatefulWidget {
  const CharacterDetailScreen({super.key, required this.avatarId});

  final String avatarId;

  @override
  ConsumerState<CharacterDetailScreen> createState() => _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends ConsumerState<CharacterDetailScreen> {
  bool _isProcessing = false;

  AvatarCollectionItem? _findItem(AvatarCollection collection) {
    try {
      return collection.items.firstWhere((e) => e.id == widget.avatarId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _purchase(AvatarCollectionItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('UNLOCK ${item.displayName.toUpperCase()}?', style: const TextStyle(fontFamily: AppTypography.displayFamily, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.creditCost} Credits', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.xp)),
            const SizedBox(height: 8),
            Text('Your balance: ${item.creditsAvailable} Credits', style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppLightColors.textSecondary)),
            Text('After purchase: ${item.creditsAvailable - (item.creditCost ?? 0)} Credits', style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppLightColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('UNLOCK'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isProcessing = true);
    try {
      await ref.read(avatarCollectionProvider.notifier).purchase(item.id);
      if (!mounted) return;
      _showCelebration(item);
    } catch (e) {
      if (!mounted) return;
      final err = describeError(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.message)));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _claim(AvatarCollectionItem item) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(avatarCollectionProvider.notifier).claim(item.id);
      if (!mounted) return;
      _showCelebration(item);
    } catch (e) {
      if (!mounted) return;
      final err = describeError(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.message)));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _equip(AvatarCollectionItem item) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(profileAvatarProvider.notifier).equip(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.displayName} equipped!'), backgroundColor: AppColors.success));
    } catch (e) {
      if (!mounted) return;
      final err = describeError(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.message)));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showCelebration(AvatarCollectionItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('UNLOCKED!', style: TextStyle(fontFamily: AppTypography.displayFamily, fontWeight: FontWeight.w800, color: AppColors.xp)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarVisual(assetKey: item.assetKey, displayName: item.displayName, rarity: item.rarity, size: 80, showGlow: true, showRarityBadge: true),
            const SizedBox(height: 12),
            Text(item.displayName, style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 18, fontWeight: FontWeight.w800)),
            Text(item.rarity.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.primary)),
            const SizedBox(height: 8),
            const Text('New character added to your collection', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CONTINUE')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _equip(item);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('EQUIP NOW'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final collectionState = ref.watch(avatarCollectionProvider);
    final collection = collectionState.data;
    final item = collection != null ? _findItem(collection) : null;

    if (collectionState.showLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('CHARACTER')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (collectionState.error != null && item == null) {
      final err = describeError(collectionState.error!);
      return Scaffold(
        appBar: AppBar(title: const Text('CHARACTER')),
        body: ErrorState(title: err.title, message: err.message, onRetry: () => ref.read(avatarCollectionProvider.notifier).refresh()),
      );
    }

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('CHARACTER')),
        body: ErrorState(title: 'CHARACTER NOT FOUND', message: 'This character does not exist.', onRetry: () => context.pop()),
      );
    }

    final isOwned = item.owned;
    final isEquipped = item.equipped;
    final isLocked = item.state == AvatarState.locked;
    final isPurchasable = item.state == AvatarState.purchasable;
    final isInsufficient = item.state == AvatarState.insufficientCredits;
    final isClaimable = item.state == AvatarState.eligibleToClaim;

    return Scaffold(
      appBar: AppBar(title: Text(item.displayName.toUpperCase())),
      body: Stack(
        children: [
          const Positioned.fill(child: AtmosphericBackground()),
          if (isDark) Positioned(top: -20, right: -10, child: GlowOrb(color: AppColors.primary, size: 180, opacity: 0.06)),
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(AppGutters.pagePadding(context), 12, AppGutters.pagePadding(context), 100),
            child: ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Large character
                  FeaturedSurface(
                    accent: _rarityColor(item.rarity, isDark),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        AvatarVisual(assetKey: item.assetKey, displayName: item.displayName, rarity: item.rarity, size: 120, showGlow: true, showRarityBadge: true),
                        const SizedBox(height: 12),
                        Text(item.displayName.toUpperCase(), style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 20, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                        Text(item.rarity.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: _rarityColor(item.rarity, isDark))),
                        const SizedBox(height: 8),
                        Text(item.description, style: AppTypography.bodySecondary(context), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        if (isEquipped)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success), const SizedBox(width: 6), const Text('EQUIPPED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success))]),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Credits / price
                  if (item.creditCost != null) ...[
                    GameChallengeSurface(
                      accent: AppColors.xp,
                      title: 'CREDITS',
                      icon: Icons.diamond_rounded,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${item.creditCost} Credits', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.xp)),
                                Text('You have ${item.creditsAvailable} Credits', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
                                if (item.creditsShort != null && item.creditsShort! > 0) Text('${item.creditsShort} more needed', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          CreditsPill(credits: item.creditsAvailable),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Requirements checklist
                  if (item.requirements.isNotEmpty) ...[
                    Text('REQUIREMENTS', style: AppTypography.overline(context)),
                    const SizedBox(height: 8),
                    ...item.requirements.map((r) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: r.satisfied ? AppColors.success.withValues(alpha: 0.08) : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: r.satisfied ? AppColors.success.withValues(alpha: 0.3) : (isDark ? AppColors.border : AppLightColors.border)),
                          ),
                          child: Row(
                            children: [
                              Icon(r.satisfied ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 16, color: r.satisfied ? AppColors.success : AppColors.locked),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.type, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)),
                                    Text('Required: ${r.required} • Current: ${r.current}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
                                  ],
                                ),
                              ),
                              if (r.satisfied) const Icon(Icons.check_rounded, size: 14, color: AppColors.success),
                            ],
                          ),
                        )),
                    const SizedBox(height: 12),
                  ],
                  // Action button
                  if (_isProcessing)
                    const Center(child: CircularProgressIndicator())
                  else if (isEquipped)
                    FilledButton(
                      onPressed: null,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)),
                      child: const Text('EQUIPPED ✓', style: TextStyle(fontWeight: FontWeight.w800)),
                    )
                  else if (isOwned)
                    FilledButton(
                      onPressed: () => _equip(item),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(48)),
                      child: const Text('EQUIP', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                    )
                  else if (isPurchasable)
                    FilledButton(
                      onPressed: () => _purchase(item),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.xp, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(48)),
                      child: Text('UNLOCK FOR ${item.creditCost} CREDITS', style: const TextStyle(fontWeight: FontWeight.w800)),
                    )
                  else if (isInsufficient)
                    FilledButton(
                      onPressed: null,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.warning, minimumSize: const Size.fromHeight(48)),
                      child: Text('${item.creditsShort} CREDITS NEEDED', style: const TextStyle(fontWeight: FontWeight.w800)),
                    )
                  else if (isClaimable)
                    FilledButton(
                      onPressed: () => _claim(item),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.success, minimumSize: const Size.fromHeight(48)),
                      child: const Text('CLAIM CHARACTER', style: TextStyle(fontWeight: FontWeight.w800)),
                    )
                  else if (isLocked)
                    Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.locked.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.locked.withValues(alpha: 0.3))),
                          child: Column(children: [const Icon(Icons.lock_rounded, color: AppColors.locked), const SizedBox(height: 4), const Text('LOCKED', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.locked)), Text('Keep learning to unlock', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary))]),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => context.go('/subjects'),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(48)),
                          child: const Text('CONTINUE LEARNING'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  // Back to collection
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                    child: const Text('BACK TO COLLECTION'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _rarityColor(String r, bool isDark) {
    return switch (r.toLowerCase()) {
      'legendary' || 'prestige' => AppColors.xp,
      'epic' => AppColors.primary,
      'rare' => AppColors.secondary,
      _ => AppColors.locked,
    };
  }
}
