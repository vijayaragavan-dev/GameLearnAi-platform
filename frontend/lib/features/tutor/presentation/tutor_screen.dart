import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../core/audio/typing_sound_controller.dart';
import '../../../core/error/user_facing_error.dart';
import '../../../core/intelligence/learner_intelligence.dart';
import '../../../core/models/tutor_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/neo_brutalism.dart';
import '../../../shared/widgets/adaptive_next_action.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/cinematic_scenery.dart';
import '../../../shared/widgets/cinematic_surfaces.dart';
import '../../../shared/widgets/game_surfaces.dart';
import '../../../shared/widgets/nova_companion.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../subjects/domain/canonical_worlds.dart' show WorldCatalog;
import '../../subjects/domain/world_context.dart' show subjectByIdProvider;

/// NOVA TUTOR - conversational AI learning companion backed by AI-001.
/// Stateless v1: the client holds a bounded window (<=8 messages, <=1000
/// chars each) and sends it with every request per the approved contract.
class TutorScreen extends ConsumerStatefulWidget {
  const TutorScreen({super.key, this.initialSubjectId, this.initialTopicId, this.initialTopicName, this.initialFocus});

  final String? initialSubjectId;
  final String? initialTopicId;
  final String? initialTopicName;
  final String? initialFocus;

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();
  late final TypingSoundController _typingController;

  final List<_Bubble> _messages = [];
  bool _sending = false;
  String? _error;
  static const int _maxWindowMessages = 8; // approved bound
  static const int _maxQuestionChars = 2000;

  @override
  void initState() {
    super.initState();
    _typingController = TypingSoundController(audioManager: ref.read(audioManagerProvider));
    ref.read(audioManagerProvider).playContext(MusicContext.tutor);
    _messages.add(
      const _Bubble(
        role: 'TUTOR',
        text:
            'Hey, I am Nova. Ask me anything about your current topic - I explain, '
            'hint and encourage. I never hand out quiz answers.',
      ),
    );
  }

  @override
  void dispose() {
    _typingController.dispose();
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<TutorMessage> buildWindow() {
    // Last N messages mapped to LEARNER/TUTOR roles.
    return [
      for (final m in _messages.skip(
        _messages.length > _maxWindowMessages
            ? _messages.length - _maxWindowMessages
            : 0,
      ))
        TutorMessage(role: m.role, content: m.text),
    ];
  }

  List<String> _contextualPrompts() {
    try {
      final dash = ref.read(dashboardProvider).data;
      if (dash != null) {
        final intel = AdaptiveEngine.fromDashboard(dash);
        if (intel.weakTopics.isNotEmpty) {
          final t = intel.weakTopics.first.topicName;
          return ['Explain $t simply', 'Give me a hint for $t', 'Help me revise $t'];
        }
        if (intel.strongTopics.isNotEmpty) {
          final t = intel.strongTopics.first.topicName;
          return ['Give me a harder example for $t', 'Challenge me on $t', 'Show my next steps for $t'];
        }
        if (!intel.insufficientData) {
          return const ['Explain this topic in simple words', 'Give me a hint, no spoilers', 'Show me a quick example'];
        }
      }
    } catch (_) {}
    final focus = widget.initialTopicName ?? widget.initialFocus;
    if (focus != null && focus.isNotEmpty) {
      return ['Explain $focus simply', 'Why did I get $focus wrong?', 'Give me a practice question for $focus'];
    }
    return const ['Explain this topic in simple words', 'Give me a hint, no spoilers', 'Show me a quick example'];
  }

  Future<void> _send() async {
    final question = _input.text.trim();
    if (question.isEmpty || _sending) return;
    if (question.length > _maxQuestionChars) {
      setState(
        () =>
            _error = 'Questions are limited to $_maxQuestionChars characters.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    ref.read(audioManagerProvider).play(Sfx.buttonConfirm);

    setState(() {
      _messages.add(_Bubble(role: 'LEARNER', text: question));
      _sending = true;
      _error = null;
      _input.clear();
    });
    _scrollDown();

    try {
      final response = await ref
          .read(intelligenceRepoProvider)
          .askTutor(
            TutorRequest(question: question, conversation: buildWindow()),
          );
      if (!mounted) return;
      setState(() {
        _messages.add(
          _Bubble(
            role: 'TUTOR',
            text: response.answer,
            refused: response.refused,
            degraded: response.degraded,
          ),
        );
        _sending = false;
      });
      ref.read(hapticsProvider).tap();
      if (!response.refused && !response.degraded) {
        ref.read(audioManagerProvider).play(Sfx.notification);
      }
      _scrollDown();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = describeError(e).message;
      });
      ref.read(audioManagerProvider).play(Sfx.incorrect);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Nova is briefly unavailable — please try again.';
      });
      ref.read(audioManagerProvider).play(Sfx.incorrect);
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: AppMotion.normal,
          curve: AppMotion.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? null : NeoBrutalColors.cream,
      appBar: AppBar(
        backgroundColor: isDark ? null : NeoBrutalColors.cream,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => context.canPop() ? context.pop() : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.border : NeoBrutalColors.ink,
                  width: isDark ? 1 : 2,
                ),
                boxShadow: isDark
                    ? null
                    : const [
                        BoxShadow(
                          color: NeoBrutalColors.ink,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
        ),
        bottom: isDark
            ? null
            : const PreferredSize(
                preferredSize: Size.fromHeight(2.5),
                child: Divider(
                  height: 2.5,
                  thickness: 2.5,
                  color: NeoBrutalColors.ink,
                ),
              ),
        titleSpacing: 0,
        title: Row(
          children: [
            const NovaCompanion(size: 34, mood: NovaMood.idle),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STUDY BUDDY',
                  style: TextStyle(
                    fontFamily: NeoBrutalTypography.displayFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isDark ? AppColors.textPrimary : NeoBrutalColors.ink,
                  ),
                ),
                Text(
                  'Your smart learning assistant',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppLightColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: NeoBrutalColors.tutorCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.border : NeoBrutalColors.ink,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: NeoBrutalColors.cobaltBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ONLINE',
                      style: TextStyle(
                        fontFamily: NeoBrutalTypography.displayFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.textPrimary : NeoBrutalColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (isDark) const Positioned.fill(child: AtmosphericBackground()),
          SafeArea(
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                children: [
                  // ── Cinematic Nova header — the reference's Nova focal
                  // point: real robot art, identity, tagline. Static (no
                  // animation) and free of world-scope language so the
                  // global-tutor honesty contract holds.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: FeaturedSurface(
                      accent: AppColors.secondary,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      scene: ScenePalette.abyss,
                      sceneSeed: 8,
                      child: Row(
                        children: [
                          const NovaAvatar(size: 64),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STUDY BUDDY',
                                  style: TextStyle(
                                    fontFamily: AppTypography.displayFamily,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: isDark
                                        ? AppColors.textPrimary
                                        : AppLightColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Your AI learning companion',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textSecondary
                                        : AppLightColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Ask · Explore · Learn · Level Up!',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.4,
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Contextual personalization card (A7) — visible when topic/subject or intelligence available
                  _TutorContextPanel(
                    initialTopicName: widget.initialTopicName,
                    initialSubjectId: widget.initialSubjectId,
                    initialFocus: widget.initialFocus,
                  ),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount:
                      _messages.length +
                      (_sending ? 1 : 0) +
                      (_messages.length <= 1 && !_sending ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (_messages.length <= 1 &&
                        !_sending &&
                        i == _messages.length) {
                      // Contextual starter prompts (A7) — weak/strong/insufficient aware.
                      // Presented as the reference SUGGESTED ACTIONS 2×2 grid;
                      // tapping still fills the input and sends (behavior kept).
                      final prompts = _contextualPrompts();
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const NeonSectionHeader(
                              icon: Icons.bolt_rounded,
                              title: 'Suggested actions',
                              subtitle: 'Pick what you need!',
                              accent: AppColors.secondary,
                            ),
                            const SizedBox(height: 10),
                            Builder(
                              builder: (context) {
                                // Adaptive columns keep suggestion cards
                                // compact on wide screens: a fixed 2-col
                                // grid stretches cards to ~330px tall on
                                // desktop while mobile stays 2-col.
                                final w =
                                    MediaQuery.sizeOf(context).width;
                                final cols = w >= 1024
                                    ? 4
                                    : (w >= 600 ? 3 : 2);
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: cols,
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 10,
                                        childAspectRatio: 1.5,
                                      ),
                                  itemCount: prompts.length.clamp(0, 4),
                                  itemBuilder: (context, pi) {
                                    final s = prompts[pi];
                                    return _SuggestedActionCard(
                                      label: s,
                                      icon: _suggestionIcon(pi, s),
                                      accent: _suggestionAccent(pi),
                                      onTap: () {
                                        _input.text = s;
                                        _send();
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }
                    if (i == _messages.length) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.all(14),
                          child: TypingIndicator(),
                        ),
                      );
                    }
                    final m = _messages[i];
                    return _MessageTile(bubble: m);
                  },
                ),
              ),
              if (_error != null)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 15,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceElevated.withValues(alpha: 0.92)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? AppColors.secondary.withValues(alpha: 0.45)
                          : NeoBrutalColors.ink,
                      width: isDark ? 1.0 : 2.5,
                    ),
                    boxShadow: isDark
                        ? [
                            BoxShadow(
                              color: AppColors.secondary.withValues(
                                alpha: 0.18,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : NeoBrutalShadows.hard,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          focusNode: _focus,
                          maxLines: 4,
                          minLines: 1,
                          maxLength: _maxQuestionChars,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          onChanged: (v) => _typingController.onChanged(v),
                          enabled: !_sending,
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFamily,
                            fontSize: 14.5,
                            color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: "Ask a question about what you're learning...",
                            counterText: '',
                            filled: true,
                            fillColor: isDark
                                ? AppColors.surfaceElevated
                                : const Color(0xFFF4F3F8),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark ? AppColors.border : NeoBrutalColors.ink,
                                width: isDark ? 1 : 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark ? AppColors.border : NeoBrutalColors.ink,
                                width: isDark ? 1 : 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark ? AppColors.secondary : NeoBrutalColors.cobaltBlue,
                                width: 2,
                              ),
                            ),
                            hintStyle: TextStyle(
                              color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SendButton(onTap: _send, busy: _sending),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ],
    ));
  }
}

class _Bubble {
  const _Bubble({
    required this.role,
    required this.text,
    this.refused = false,
    this.degraded = false,
  });

  final String role; // LEARNER | TUTOR
  final String text;
  final bool refused;
  final bool degraded;
}

/// Icon mapping for the Suggested Actions grid — keyword-driven, falls back
/// by position. Decorative only; the label text carries the meaning.
IconData _suggestionIcon(int index, String label) {
  final l = label.toLowerCase();
  if (l.contains('hint')) return Icons.lightbulb_outline_rounded;
  if (l.contains('example')) return Icons.code_rounded;
  if (l.contains('practice') || l.contains('question') || l.contains('challenge')) {
    return Icons.track_changes_rounded;
  }
  if (l.contains('explain') || l.contains('simple')) return Icons.article_outlined;
  if (l.contains('revise') || l.contains('wrong')) return Icons.refresh_rounded;
  if (l.contains('harder') || l.contains('next steps')) return Icons.trending_up_rounded;
  return const [
    Icons.article_outlined,
    Icons.lightbulb_outline_rounded,
    Icons.code_rounded,
    Icons.track_changes_rounded,
  ][index % 4];
}

Color _suggestionAccent(int index) => const [
  AppColors.success,
  AppColors.primary,
  AppColors.secondary,
  AppColors.xp,
][index % 4];

/// Suggested-action grid card — same send-on-tap behavior as the former
/// chips, in the reference 2×2 card language.
class _SuggestedActionCard extends StatelessWidget {
  const _SuggestedActionCard({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: 'Ask Nova: $label',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceElevated.withValues(alpha: 0.8)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? accent.withValues(alpha: 0.45)
                  : NeoBrutalColors.ink,
              width: isDark ? 1.0 : 2.0,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: NeoBrutalColors.ink,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: accent),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: NeoBrutalTypography.displayFamily,
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimary
                      : NeoBrutalColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.bubble});

  final _Bubble bubble;

  @override
  Widget build(BuildContext context) {
    final isLearner = bubble.role == 'LEARNER';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLearner) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
          ),
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primaryDeep.withValues(alpha: 0.85)
                : NeoBrutalColors.cobaltBlue,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
              topRight: Radius.zero,
            ),
            border: Border.all(
              color: isDark ? Colors.transparent : NeoBrutalColors.ink,
              width: isDark ? 1.0 : 2.5,
            ),
            boxShadow: isDark
                ? null
                : const [
                    BoxShadow(
                      color: NeoBrutalColors.ink,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: Text(
            bubble.text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(top: 2, right: 10),
              decoration: BoxDecoration(
                color: NeoBrutalColors.tutorCyan,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.border : NeoBrutalColors.ink,
                  width: isDark ? 1 : 2,
                ),
                boxShadow: isDark
                    ? null
                    : const [
                        BoxShadow(
                          color: NeoBrutalColors.ink,
                          offset: Offset(1.5, 1.5),
                          blurRadius: 0,
                        ),
                      ],
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 20,
                color: NeoBrutalColors.ink,
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceElevated : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    topLeft: Radius.zero,
                  ),
                  border: Border.all(
                    color: isDark
                        ? (bubble.refused || bubble.degraded
                            ? AppColors.warning
                            : AppColors.border)
                        : NeoBrutalColors.ink,
                    width: isDark ? 1.0 : 2.5,
                  ),
                  boxShadow: isDark ? null : NeoBrutalShadows.hard,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: NeoBrutalColors.tutorCyan.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.border : NeoBrutalColors.ink,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_stories_rounded,
                            size: 12,
                            color: NeoBrutalColors.cobaltBlue,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'NOVA MENTOR',
                            style: TextStyle(
                              fontFamily: NeoBrutalTypography.displayFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : NeoBrutalColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      bubble.text,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? AppColors.textPrimary
                            : NeoBrutalColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary,
              ),
            ),
        ],
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Opacity(
                opacity: (((_c.value * 3 - i) % 3) / 2).clamp(0.25, 1.0),
                child: Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onTap, required this.busy});

  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: busy ? 'Sending' : 'Send message',
      child: GestureDetector(
        onTap: busy ? null : onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: busy
                ? (isDark ? AppColors.surfaceHigh : AppLightColors.surfaceHigh)
                : (isDark ? AppColors.primary : NeoBrutalColors.cobaltBlue),
            border: Border.all(
              color: isDark ? AppColors.border : NeoBrutalColors.ink,
              width: isDark ? 1 : 2.5,
            ),
            boxShadow: isDark
                ? null
                : const [
                    BoxShadow(
                      color: NeoBrutalColors.ink,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}

class _TutorContextPanel extends ConsumerWidget {
  const _TutorContextPanel({this.initialSubjectId, this.initialTopicId, this.initialTopicName, this.initialFocus});
  final String? initialSubjectId;
  final String? initialTopicId;
  final String? initialTopicName;
  final String? initialFocus;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Prefer query context, fallback to intelligence
    if (initialTopicName != null && initialTopicName!.isNotEmpty) {
      // World chip: resolve the backend subject to its canonical world so
      // the tutor's scope is visible (never color-only, never fabricated —
      // absent when the subject is unknown).
      final subject = ref.watch(subjectByIdProvider(initialSubjectId));
      final world = subject == null
          ? null
          : WorldCatalog.resolveSubject(subject);
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark ? AppColors.border : NeoBrutalColors.ink,
            width: isDark ? 1 : 2,
          ),
          boxShadow: isDark
              ? null
              : const [
                  BoxShadow(
                    color: NeoBrutalColors.ink,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.secondary.withValues(alpha: 0.14)), child: const Icon(Icons.psychology_rounded, size: 16, color: AppColors.secondary)), const SizedBox(width: 8), Text('LEARNING FOCUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.secondary)), const Spacer(), if (initialFocus != null) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)), child: Text(initialFocus!.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.warning)))]),
          if (world != null) ...[
            const SizedBox(height: 8),
            Semantics(
              label: 'Tutor scope: ${world.displayName} world',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: world.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: world.accent.withValues(alpha: 0.35)),
                ),
                child: Text(
                  '${world.displayName.toUpperCase()} • WORLD',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: world.accent),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(initialTopicName!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)),
          if (initialSubjectId != null) Text('Topic • Tap a quick prompt below to start', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
        ]),
      );
    }
    // Try intelligence
    try {
      final dash = ref.watch(dashboardProvider).data;
      if (dash != null) {
        final intel = AdaptiveEngine.fromDashboard(dash);
        if (intel.insufficientData) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isDark ? AppColors.border : NeoBrutalColors.ink,
                width: isDark ? 1 : 2,
              ),
              boxShadow: isDark
                  ? null
                  : const [
                      BoxShadow(
                        color: NeoBrutalColors.ink,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
            ),
            child: Row(children: [const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.secondary), const SizedBox(width: 8), Expanded(child: Text('Build your learning profile by completing a few activities.', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)))]),
          );
        }
        final weak = intel.weakTopics.isNotEmpty ? intel.weakTopics.first : null;
        final mastery = intel.overallMastery;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isDark ? [AppColors.secondary.withValues(alpha: 0.10), AppColors.surfaceElevated] : [AppColors.secondary.withValues(alpha: 0.06), AppLightColors.surface]), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.secondary.withValues(alpha: 0.22))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.secondary), const SizedBox(width: 6), Text('LEARNING FOCUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.secondary)), const Spacer(), MasteryBadge(score: mastery)]),
            const SizedBox(height: 8),
            if (weak != null) ...[
              Text(weak.topicName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)),
              Text('Mastery ${weak.masteryScore.round()}% • ${weak.trend.isEmpty ? 'needs practice' : weak.trend.toLowerCase()} • Next: ${intel.nextDifficulty}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
            ] else ...[
              Text('${mastery.round()}% Mastery • ${intel.trend.replaceAll('_', ' ')}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary)),
              Text('Next: ${intel.nextDifficulty} • ${intel.topicsAssessed} topics assessed', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
            ],
            if (intel.revisionQueue.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Recommended: Practice ${intel.revisionQueue.first.topicName}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
          ]),
        );
      }
    } catch (_) {}
    return const SizedBox.shrink();
  }
}
