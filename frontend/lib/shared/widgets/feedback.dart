import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_typography.dart';

/// Shimmering placeholder block.
class SkeletonBlock extends StatefulWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.md,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.feature)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * t, 0),
              end: Alignment(0 + 2 * t, 0),
              colors: [
                AppColors.surfaceHigh.withValues(alpha: 0.55),
                AppColors.borderStrong.withValues(alpha: 0.75),
                AppColors.surfaceHigh.withValues(alpha: 0.55),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Card-shaped loading placeholder.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SkeletonBlock(width: 44, height: 44, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(
                    width: MediaQuery.sizeOf(context).width * 0.4,
                    height: 14,
                  ),
                  const SizedBox(height: 8),
                  const SkeletonBlock(width: 90, height: 10),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const SkeletonBlock(height: 34),
      ],
    ),
  );
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.itemCount = 3, this.itemHeight = 120});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      itemCount,
      (_) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: SkeletonCard(height: itemHeight),
      ),
    ),
  );
}

/// Dashboard-shaped skeleton honoring the DASH-001 section layout.
class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const SkeletonBlock(width: 56, height: 56, radius: 28),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(
                  width: MediaQuery.sizeOf(context).width * 0.45,
                  height: 18,
                ),
                const SizedBox(height: 8),
                const SkeletonBlock(width: 110, height: 12),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SkeletonCard(height: 130),
        const SizedBox(height: 16),
        const SkeletonCard(height: 150),
        const SizedBox(height: 16),
        const SkeletonCard(height: 90),
      ],
    );
  }
}

class SkeletonPath extends StatelessWidget {
  const SkeletonPath({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        4,
        (i) => Padding(
          padding: EdgeInsets.symmetric(
            vertical: 26,
            horizontal: 40 + (i % 2) * 60,
          ),
          child: const SkeletonBlock(width: 72, height: 72, radius: 36),
        ),
      ),
    ),
  );
}

class SkeletonAchievementGrid extends StatelessWidget {
  const SkeletonAchievementGrid({super.key});

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 14,
    crossAxisSpacing: 14,
    childAspectRatio: 0.95,
    children: List.generate(6, (_) => const SkeletonCard()),
  );
}

/// Full-screen centered error state with Nova and optional retry.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NovaErrorOrb(),
          const SizedBox(height: 20),
          Text(
            title,
            style: AppTypography.h2(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTypography.bodySecondary(context),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('TRY AGAIN'),
            ),
          ],
        ],
      ),
    ),
  );
}

// Local import-free mini orb for the error state to avoid circular imports.
class NovaErrorOrb extends StatelessWidget {
  const NovaErrorOrb({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.error.withValues(alpha: 0.15),
      border: Border.all(color: AppColors.error.withValues(alpha: 0.6)),
      boxShadow: [
        BoxShadow(
          color: AppColors.error.withValues(alpha: 0.25),
          blurRadius: 24,
        ),
      ],
    ),
    child: const Icon(Icons.auto_awesome, color: AppColors.error, size: 26),
  );
}

/// Empty state with icon + message.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(icon, color: AppColors.primaryBright, size: 28),
          ),
          const SizedBox(height: 18),
          Text(title, style: AppTypography.h2(context)),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTypography.bodySecondary(context),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}

/// Slim connectivity banner pinned above content when offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.warning.withValues(alpha: 0.14),
    child: SafeArea(
      top: false,
      bottom: false,
      child: InkWell(
        onTap: onRetry,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 15,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "You're offline - showing cached state",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onRetry,
                child: const Text(
                  'RETRY',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Compact inline empty note used inside cards/sections.
class EmptyMiniCard extends StatelessWidget {
  const EmptyMiniCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
    ),
  );
}
