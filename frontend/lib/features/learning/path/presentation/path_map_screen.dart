import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../../core/models/content_models.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/nova_companion.dart';
import '../providers/path_provider.dart';

/// The adventure map: a curved serpentine trail of mission nodes.
/// Node status ALWAYS comes from the backend (PATH-001/002).
class PathMapScreen extends ConsumerStatefulWidget {
  const PathMapScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  final String subjectId;
  final String subjectName;

  @override
  ConsumerState<PathMapScreen> createState() => _PathMapScreenState();
}

class _PathMapScreenState extends ConsumerState<PathMapScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(audioManagerProvider).playContext(MusicContext.adventure);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pathProvider(widget.subjectId).notifier).load();
    });
  }

  void _openTopic(PathNode node) {
    if (node.status == 'LOCKED') {
      ref.read(hapticsProvider).error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${node.topicName}" unlocks at ${node.requiredMastery.toStringAsFixed(0)}% mastery. Keep conquering missions!',
          ),
        ),
      );
      return;
    }
    ref.read(audioManagerProvider).play(Sfx.buttonConfirm);
    ref.read(hapticsProvider).select();
    context.push(Routes.topic(node.topicId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pathProvider(widget.subjectId));
    return Scaffold(
      body: Stack(
        children: [
          const _Starfield(),
          SafeArea(
            child: Column(
              children: [
                _PathHeader(
                  subjectName: widget.subjectName,
                  subjectId: widget.subjectId,
                  onBack: () => context.canPop()
                      ? context.pop()
                      : context.go(Routes.home),
                ),
                Expanded(child: _buildBody(state)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(PathState state) {
    if (state.showLoading) {
      return const Center(child: SkeletonPath());
    }
    if (state.generating && state.activePath == null) {
      return const _GeneratingPanel();
    }
    if (state.error != null && state.activePath == null) {
      return ErrorState(
        title: 'Path unavailable',
        message: state.error!,
        onRetry: () => ref.read(pathProvider(widget.subjectId).notifier).load(),
      );
    }
    final path = state.activePath;
    if (path == null) {
      return _GeneratePrompt(state: state, subjectId: widget.subjectId);
    }
    return RefreshIndicator(
      color: AppColors.primaryBright,
      backgroundColor: AppColors.surfaceElevated,
      onRefresh: () => ref.read(pathProvider(widget.subjectId).notifier).load(),
      child: AdventureTrail(
        path: path,
        aiMetadata: state.aiMetadata,
        onNodeTap: _openTopic,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ambient starfield backdrop for the adventure environment.
class _Starfield extends StatefulWidget {
  const _Starfield();

  @override
  State<_Starfield> createState() => _StarfieldState();
}

class _StarfieldState extends State<_Starfield>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      if (_c.isAnimating) _c.stop();
    } else {
      if (!_c.isAnimating) _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      return const CustomPaint(
        painter: _StarfieldPainter(t: 0),
        size: Size.infinite,
      );
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _StarfieldPainter(t: _c.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  const _StarfieldPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Deterministic pseudo-random star layout (no flicker between frames).
    const starCount = 70;
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < starCount; i++) {
      final seed = i * 97.13;
      final x = ((seed * 7.31) % 1000) / 1000 * size.width;
      final baseY = ((seed * 3.77) % 1000) / 1000 * size.height;
      final drift = (t * size.height * 0.15 + seed * 2.0) % size.height;
      final y = (baseY + drift) % size.height;
      final phase = (math.sin((t + seed % 1) * math.pi * 2) + 1) / 2;
      paint.color = Colors.white.withValues(alpha: 0.08 + 0.22 * phase);
      canvas.drawCircle(Offset(x, y), 1.1, paint);
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter oldDelegate) => oldDelegate.t != t;
}

// ---------------------------------------------------------------------------
// Header.
class _PathHeader extends StatelessWidget {
  const _PathHeader({
    required this.subjectName,
    required this.onBack,
    required this.subjectId,
  });

  final String subjectName;
  final String subjectId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 20, 6),
    child: Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        Expanded(
          child: Text(
            subjectName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Knowledge scan',
          onPressed: () => context.push(Routes.assessmentIntro(subjectId)),
          icon: const Icon(Icons.radar_rounded, size: 20),
        ),
        IconButton(
          tooltip: 'Ask Nova',
          onPressed: () => context.push(Routes.tutor),
          icon: const Icon(Icons.auto_awesome_rounded, size: 20),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Serpentine trail.
class AdventureTrail extends StatelessWidget {
  const AdventureTrail({
    super.key,
    required this.path,
    required this.aiMetadata,
    required this.onNodeTap,
  });

  final LearningPath path;
  final Map<int, ({String objective, String rationale})> aiMetadata;
  final void Function(PathNode) onNodeTap;

  static const double _slotHeight = 160;
  static const double _nodeSize = 76;

  Offset _centerFor(int index, double width) {
    final lane = width * (index.isEven ? 0.30 : 0.70);
    final wobble = math.sin(index * 1.7) * width * 0.08;
    return Offset(lane + wobble, _slotHeight * index + _slotHeight / 2);
  }

  double _captionWidth(double width) => (width * 0.38).clamp(130.0, 280.0);

  @override
  Widget build(BuildContext context) {
    final nodes = path.nodes;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = _slotHeight * nodes.length + 80;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: SizedBox(
            height: height,
            width: width,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: Size(width, height),
                  painter: _TrailPainter(
                    centers: List.generate(
                      nodes.length,
                      (i) => _centerFor(i, width),
                    ),
                  ),
                ),
                for (var i = 0; i < nodes.length; i++)
                  Positioned.fromRect(
                    rect: Rect.fromCenter(
                      center: _centerFor(i, width),
                      width: _nodeSize,
                      height: _nodeSize,
                    ),
                    child: LearningNode(
                      node: nodes[i],
                      metadata: aiMetadata[nodes[i].sequenceNumber],
                      onTap: () => onNodeTap(nodes[i]),
                    ),
                  ),
                // Sequence labels beside nodes.
                for (var i = 0; i < nodes.length; i++)
                  Positioned(
                    left: _centerFor(i, width).dx < width / 2
                        ? _centerFor(i, width).dx + _nodeSize / 2 + 10
                        : null,
                    right: _centerFor(i, width).dx >= width / 2
                        ? width - _centerFor(i, width).dx + _nodeSize / 2 + 10
                        : null,
                    top: _centerFor(i, width).dy - 18,
                    width: _captionWidth(width),
                    child: Align(
                      alignment: _centerFor(i, width).dx < width / 2
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: _NodeCaption(
                        node: nodes[i],
                        metadata: aiMetadata[nodes[i].sequenceNumber],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrailPainter extends CustomPainter {
  const _TrailPainter({required this.centers});

  final List<Offset> centers;

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.isEmpty) return;
    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primaryDeep, AppColors.primary, AppColors.secondary],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = AppColors.primary.withValues(alpha: 0.12)
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(centers.first.dx, centers.first.dy);
    for (var i = 1; i < centers.length; i++) {
      final a = centers[i - 1];
      final b = centers[i];
      // S-curve between consecutive nodes.
      final midY = (a.dy + b.dy) / 2;
      path.cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
    }
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, trailPaint);

    // Directional chevrons along the path.
    final chevron = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = Colors.white.withValues(alpha: 0.35);
    for (var i = 1; i < centers.length; i++) {
      final a = centers[i - 1];
      final b = centers[i];
      final t = 0.5;
      final mx = a.dx + (b.dx - a.dx) * t;
      final my = a.dy + (b.dy - a.dy) * t;
      final dir = (b.dx - a.dx).sign;
      final tip = Offset(mx + dir * 6, my);
      canvas.drawPath(
        Path()
          ..moveTo(mx - dir * 3, my - 5)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(mx - dir * 3, my + 5),
        chevron,
      );
    }
  }

  @override
  bool shouldRepaint(_TrailPainter oldDelegate) =>
      oldDelegate.centers.length != centers.length;
}

// ---------------------------------------------------------------------------
// A single mission node.
class LearningNode extends StatefulWidget {
  const LearningNode({
    super.key,
    required this.node,
    required this.onTap,
    this.metadata,
  });

  final PathNode node;
  final VoidCallback onTap;
  final ({String objective, String rationale})? metadata;

  @override
  State<LearningNode> createState() => _LearningNodeState();
}

class _LearningNodeState extends State<LearningNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    // Do NOT query MediaQuery here — context is not attached to an
    // InheritedWidget tree yet (would throw
    // dependOnInheritedWidgetOfExactType<MediaQuery> before initState
    // completed). Pulse gating is handled in didChangeDependencies.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      if (_pulse.isAnimating) _pulse.stop();
    } else {
      if (widget.node.status == 'AVAILABLE' && !_pulse.isAnimating) {
        _pulse.repeat();
      }
    }
  }

  @override
  void didUpdateWidget(LearningNode old) {
    super.didUpdateWidget(old);
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      _pulse.stop();
      return;
    }
    if (widget.node.status == 'AVAILABLE') {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color get tint => switch (widget.node.status) {
    'COMPLETED' => AppColors.success,
    'IN_PROGRESS' => AppColors.warning,
    'AVAILABLE' => AppColors.primaryBright,
    _ => AppColors.locked,
  };

  IconData get icon => switch (widget.node.status) {
    'COMPLETED' => Icons.check_rounded,
    'IN_PROGRESS' => Icons.play_arrow_rounded,
    'AVAILABLE' => Icons.bolt_rounded,
    _ => Icons.lock_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      label: '${node.topicName}, ${_stateLabel(node.status)}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.9 : 1,
          duration: reduce ? Duration.zero : AppMotion.fast,
          curve: AppMotion.easeOut,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final ring = node.status == 'AVAILABLE' && !reduce
                  ? _pulse.value
                  : 0.0;
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: tint.withValues(
                        alpha: node.status == 'LOCKED'
                            ? 0.0
                            : (reduce
                                  ? 0.35
                                  : 0.45 + 0.25 * math.sin(ring * math.pi * 2)),
                      ),
                      blurRadius: 26,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _RingPainter(ring: ring, tint: tint),
                  child: Container(
                    margin: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: node.status == 'LOCKED'
                            ? [
                                AppColors.lockedSurface,
                                AppColors.lockedSurface.withValues(alpha: 0.7),
                              ]
                            : [
                                tint.withValues(alpha: 0.85),
                                tint.withValues(alpha: 0.4),
                              ],
                      ),
                      border: Border.all(color: tint, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 28,
                      color: node.status == 'LOCKED'
                          ? AppColors.textTertiary
                          : Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static String _stateLabel(String status) => switch (status) {
    'COMPLETED' => 'completed',
    'IN_PROGRESS' => 'in progress',
    'AVAILABLE' => 'available now',
    _ => 'locked',
  };
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.ring, required this.tint});

  final double ring;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    if (ring <= 0.01 || ring >= 0.99) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * (1 - ring)
      ..color = tint.withValues(alpha: 0.65 * (1 - ring));
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 * (1 + ring * 0.35),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.ring != ring || oldDelegate.tint != tint;
}

class _NodeCaption extends StatelessWidget {
  const _NodeCaption({required this.node, this.metadata});

  final PathNode node;
  final ({String objective, String rationale})? metadata;

  @override
  Widget build(BuildContext context) {
    final label = EnumPresentationExt.nodeStatus(node.status);
    final isCurrent = node.status == 'AVAILABLE';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCurrent)
          // Locator for the signature map: answers "where am I?" at a
          // glance. Purely presentational - status itself is backend-owned.
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.5),
              ),
            ),
            child: const Text(
              'YOU ARE HERE',
              style: TextStyle(
                fontSize: 8.5,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
                color: AppColors.secondary,
              ),
            ),
          ),
        Text(
          node.topicName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.25,
            color: node.status == 'LOCKED'
                ? AppColors.textTertiary
                : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              switch (node.status) {
                'COMPLETED' => Icons.check_circle_outline_rounded,
                'IN_PROGRESS' => Icons.change_history_rounded,
                'AVAILABLE' => Icons.flash_on_rounded,
                _ => Icons.lock_outline_rounded,
              },
              size: 11,
              color: node.status == 'LOCKED'
                  ? AppColors.textTertiary
                  : AppColors.secondary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Generation prompt when no ACTIVE path exists.
class _GeneratePrompt extends ConsumerWidget {
  const _GeneratePrompt({required this.state, required this.subjectId});

  final PathState state;
  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalController = TextEditingController();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NovaCompanion(
              size: 84,
              mood: state.generating ? NovaMood.thinking : NovaMood.encouraging,
            ),
            const SizedBox(height: 24),
            const Text(
              'Forge your path',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontSize: 23,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'The AI Game Master will chart a mission sequence tuned to your mastery profile.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: goalController,
              maxLength: 300,
              minLines: 1,
              maxLines: 3,
              enabled: !state.generating,
              decoration: const InputDecoration(
                labelText: 'Optional goal (max 300 chars)',
                hintText: 'e.g. "I want to master subnetting"',
                counterText: '',
              ),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 10),
              Text(
                state.error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryGameButton(
              label: state.generating ? 'Charting...' : 'Generate path',
              icon: Icons.auto_fix_high_rounded,
              busy: state.generating,
              onTap: () async {
                FocusScope.of(context).unfocus();
                ref.read(audioManagerProvider).play(Sfx.buttonConfirm);
                final ok = await ref
                    .read(pathProvider(subjectId).notifier)
                    .generate(learningGoal: goalController.text.trim());
                if (ok && context.mounted) {
                  ref.read(audioManagerProvider).play(Sfx.missionComplete);
                  ref.read(hapticsProvider).celebrate();
                } else {
                  ref.read(audioManagerProvider).play(Sfx.incorrect);
                }
              },
            ),
            const SizedBox(height: 10),
            SecondaryGameButton(
              label: 'Take knowledge scan first',
              icon: Icons.radar_rounded,
              expanded: true,
              onTap: () => context.push(Routes.assessmentIntro(subjectId)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Generating overlay panel.
class _GeneratingPanel extends StatelessWidget {
  const _GeneratingPanel();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NovaCompanion(size: 96, mood: NovaMood.thinking),
          SizedBox(height: 24),
          Text(
            'NOVA IS CHARTING YOUR PATH...',
            style: TextStyle(
              letterSpacing: 2.5,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
            ),
          ),
          SizedBox(height: 18),
          SizedBox(width: 120, child: LinearProgressIndicator(minHeight: 3)),
          SizedBox(height: 40),
          SkeletonPath(),
        ],
      ),
    );
  }
}

abstract final class EnumPresentationExt {
  static String nodeStatus(String status) => switch (status) {
    'COMPLETED' => 'Completed',
    'IN_PROGRESS' => 'In progress',
    'AVAILABLE' => 'Available',
    _ => 'Locked',
  };
}
