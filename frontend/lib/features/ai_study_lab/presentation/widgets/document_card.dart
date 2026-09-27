import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/pressable.dart';
import '../../domain/study_document.dart';

/// File-type glyph in a tinted circle. Icons only — no emoji, no assets.
class DocumentTypeIcon extends StatelessWidget {
  const DocumentTypeIcon({super.key, required this.fileType, this.size = 44});

  final DocumentFileType fileType;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.secondary.withValues(alpha: isDark ? 0.14 : 0.10),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.40),
        ),
      ),
      child: Icon(
        fileType.icon,
        size: size * 0.5,
        color: AppColors.secondary,
        semanticLabel: '${fileType.extensionLabel} document',
      ),
    );
  }
}

/// Honest lifecycle pill. Every state has a distinct label AND icon —
/// state is never conveyed by color alone.
class DocumentStatusBadge extends StatelessWidget {
  const DocumentStatusBadge({super.key, required this.status});

  final DocumentStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (Color color, IconData icon, String label) = switch (status) {
      DocumentStatus.ready => (
        AppColors.success,
        Icons.check_circle_rounded,
        'READY',
      ),
      DocumentStatus.processing => (
        AppColors.secondary,
        Icons.hourglass_top_rounded,
        'PROCESSING',
      ),
      DocumentStatus.failed => (
        AppColors.error,
        Icons.error_outline_rounded,
        'FAILED',
      ),
      DocumentStatus.unavailable => (
        isDark ? AppColors.locked : AppLightColors.locked,
        Icons.cloud_off_rounded,
        'UNAVAILABLE',
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Learning-progress bar. Rendered ONLY when [fraction] is real
/// (0..1 from the service); callers must pass null otherwise.
class DocumentProgressBar extends StatelessWidget {
  const DocumentProgressBar({super.key, required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Learning progress ${(fraction * 100).round()} percent',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: LinearProgressIndicator(
          value: fraction.clamp(0.0, 1.0),
          minHeight: 6,
          backgroundColor: isDark
              ? AppColors.surfaceElevated
              : AppLightColors.surface,
          valueColor: const AlwaysStoppedAnimation<Color>(
            AppColors.secondary,
          ),
        ),
      ),
    );
  }
}

/// Topic-count chip. Renders the real count when known, otherwise an
/// honest "No topics yet" placeholder — never an invented number.
class DocumentTopicChip extends StatelessWidget {
  const DocumentTopicChip({super.key, this.topicCount});

  final int? topicCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.tag_rounded, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          topicCount == null ? 'No topics yet' : '$topicCount topics',
          style: TextStyle(fontSize: 11.5, color: color),
        ),
      ],
    );
  }
}

/// Reusable study-document card.
///
/// [onOpen] is null for documents that cannot be opened yet
/// (processing): the card renders non-interactive with honest status
/// instead of navigating. [onRetry] offers a parent-owned reload for
/// failed documents; without it, failed cards show the failure message
/// with no fake retry endpoint.
class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.document,
    this.onOpen,
    this.onMenu,
    this.onRetry,
  });

  final StudyDocument document;
  final VoidCallback? onOpen;
  final VoidCallback? onMenu;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doc = document;
    final openable = onOpen != null;
    return Pressable(
      onTap: onOpen,
      semanticsLabel:
          'Document ${doc.title}, ${doc.fileType.extensionLabel}, ${doc.status.name}'
          '${openable ? '' : ', not openable yet'}',
      child: GameCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DocumentTypeIcon(fileType: doc.fileType),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${doc.fileType.extensionLabel} document',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppLightColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onMenu != null)
                  IconButton(
                    tooltip: 'Document actions',
                    onPressed: onMenu,
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                DocumentStatusBadge(status: doc.status),
                const SizedBox(width: 8),
                if (doc.lastStudiedLabel != null)
                  Expanded(
                    child: Text(
                      doc.lastStudiedLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textTertiary
                            : AppLightColors.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
            if (doc.progressFraction != null) ...[
              const SizedBox(height: 10),
              DocumentProgressBar(fraction: doc.progressFraction!),
            ],
            if (doc.status == DocumentStatus.failed) ...[
              const SizedBox(height: 10),
              Text(
                doc.failureMessage ?? 'Processing hit a snag.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppLightColors.textSecondary,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GameChip(
                    label: 'RETRY',
                    icon: Icons.refresh_rounded,
                    color: AppColors.secondary,
                    onTap: onRetry!,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 10),
            DocumentTopicChip(topicCount: doc.topicCount),
          ],
        ),
      ),
    );
  }
}
