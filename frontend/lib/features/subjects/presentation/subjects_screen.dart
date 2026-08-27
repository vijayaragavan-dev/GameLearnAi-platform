import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../core/error/user_facing_error.dart';
import '../../../core/models/content_models.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/achievement_icon.dart' show SubjectGlyph;
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/nova_companion.dart';
import 'subject_grouping.dart';

/// SUBJ-001 world selection. Each subject is a "world" with its own tint.
class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  Future<List<Subject>>? _future;
  String _selectedCategory = SubjectGrouping.allLabel;

  @override
  void initState() {
    super.initState();
    ref.read(audioManagerProvider).playContext(MusicContext.adventure);
    _future = ref.read(contentRepoProvider).subjects();
  }

  void _reload() {
    setState(() {
      _future = ref.read(contentRepoProvider).subjects();
      _selectedCategory = SubjectGrouping.allLabel;
    });
  }

  void _selectCategory(String label) {
    if (_selectedCategory == label) return;
    ref.read(hapticsProvider).select();
    setState(() => _selectedCategory = label);
  }

  void _enter(Subject subject) {
    ref.read(audioManagerProvider).play(Sfx.nodeUnlock);
    ref.read(hapticsProvider).select();
    final name = Uri.encodeComponent(subject.name);
    context.go('/${Routes.path(subject.id).substring(1)}?name=$name');
  }

  void _scan(Subject subject) {
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    ref.read(hapticsProvider).select();
    context.push(Routes.assessmentIntro(subject.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CHOOSE YOUR WORLD')),
      body: RefreshIndicator(
        color: AppColors.primaryBright,
        backgroundColor: AppColors.surfaceElevated,
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<Subject>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done && !snap.hasData) {
              return ListView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: const [SkeletonList(itemCount: 4, itemHeight: 108)],
              );
            }
            if (snap.hasError) {
              final err = describeError(snap.error!);
              return ErrorState(
                title: err.title,
                message: err.message,
                onRetry: _reload,
              );
            }
            final subjects = snap.data ?? const <Subject>[];
            if (subjects.isEmpty) {
              return EmptyState(
                icon: Icons.public_off_rounded,
                title: 'No worlds yet',
                message: 'New worlds are being prepared. Check back soon.',
                action: OutlinedButton(
                  onPressed: _reload,
                  child: const Text('REFRESH'),
                ),
              );
            }
            final chips = SubjectGrouping.deriveChips(subjects);
            final filtered = SubjectGrouping.filter(
              subjects,
              _selectedCategory,
            );
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              itemCount: filtered.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        NovaCompanion(size: 38, mood: NovaMood.encouraging),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pick a world, Player. Your path adapts to you.',
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (index == 1) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _CategoryChips(
                      chips: chips,
                      selected: _selectedCategory,
                      onSelected: _selectCategory,
                    ),
                  );
                }
                if (filtered.isEmpty) {
                  // Only render once when filtered empty.
                  if (index == 2) {
                    return EmptyState(
                      icon: Icons.filter_list_off_rounded,
                      title: 'No worlds in this category',
                      message:
                          'No "$_selectedCategory" worlds found. Try another category or view all worlds.',
                      action: OutlinedButton(
                        onPressed: () => setState(
                          () => _selectedCategory = SubjectGrouping.allLabel,
                        ),
                        child: const Text('SHOW ALL'),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }
                final subject = filtered[index - 2];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: PressableWorldCard(
                    subject: subject,
                    onTap: () => _enter(subject),
                    onScan: () => _scan(subject),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class PressableWorldCard extends StatefulWidget {
  const PressableWorldCard({
    super.key,
    required this.subject,
    required this.onTap,
    required this.onScan,
  });

  final Subject subject;
  final VoidCallback onTap;
  final VoidCallback onScan;

  @override
  State<PressableWorldCard> createState() => _PressableWorldCardState();
}

class _PressableWorldCardState extends State<PressableWorldCard> {
  bool _down = false;

  Color get _tint => switch (widget.subject.displayOrder % 5) {
    0 => AppColors.primary,
    1 => AppColors.secondary,
    2 => AppColors.success,
    3 => AppColors.warning,
    _ => AppColors.streak,
  };

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      label: '${widget.subject.name} world, tap to enter, scan available',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _down ? 0.97 : 1,
            duration: reduce ? Duration.zero : AppMotion.fast,
            curve: AppMotion.easeOut,
            child: AnimatedContainer(
              duration: reduce ? Duration.zero : AppMotion.normal,
              curve: AppMotion.easeOut,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _tint.withValues(alpha: _down ? 0.2 : 0.13),
                    AppColors.surfaceElevated,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: _tint.withValues(alpha: _down ? 0.7 : 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _tint.withValues(alpha: _down ? 0.35 : 0.15),
                    blurRadius: _down ? 26 : 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SubjectGlyph(iconKey: widget.subject.iconKey, color: _tint),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subject.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subject.description.isNotEmpty
                              ? widget.subject.description
                              : 'Enter the ${widget.subject.name} world',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Semantics(
                    button: true,
                    label: 'Scan ${widget.subject.name} knowledge',
                    child: GestureDetector(
                      onTap: widget.onScan,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _tint.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _tint.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.radar_rounded, size: 13, color: _tint),
                            const SizedBox(width: 4),
                            Text(
                              'SCAN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: _tint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: _tint.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal category filter chips. Presentation-only; selection filters
/// the already-loaded catalog in-memory. No backend request.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.chips,
    required this.selected,
    required this.onSelected,
  });

  final List<String> chips;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = chips[i];
          final isSelected = label == selected;
          return Semantics(
            button: true,
            selected: isSelected,
            label:
                'Filter $label worlds, ${isSelected ? 'selected' : 'not selected'}',
            child: AnimatedContainer(
              duration: reduce ? Duration.zero : AppMotion.fast,
              curve: AppMotion.easeOut,
              child: ChoiceChip(
                label: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: isSelected
                        ? AppColors.textOnColor
                        : AppColors.textSecondary,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onSelected(label),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryBright
                      : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                showCheckmark: false,
              ),
            ),
          );
        },
      ),
    );
  }
}
