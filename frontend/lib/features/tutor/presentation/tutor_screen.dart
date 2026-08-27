import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../core/error/user_facing_error.dart';
import '../../../core/models/tutor_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/nova_companion.dart';

/// NOVA TUTOR - conversational AI learning companion backed by AI-001.
/// Stateless v1: the client holds a bounded window (<=8 messages, <=1000
/// chars each) and sends it with every request per the approved contract.
class TutorScreen extends ConsumerStatefulWidget {
  const TutorScreen({super.key});

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();

  final List<_Bubble> _messages = [];
  bool _sending = false;
  String? _error;
  static const int _maxWindowMessages = 8; // approved bound
  static const int _maxQuestionChars = 2000;

  @override
  void initState() {
    super.initState();
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
      setState(() {
        _sending = false;
        _error = describeError(e).message;
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : null,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 0,
        title: const Row(
          children: [
            NovaCompanion(size: 34, mood: NovaMood.idle),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOVA TUTOR',
                  style: TextStyle(fontSize: 14.5, letterSpacing: 1),
                ),
                Text(
                  'AI learning companion',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Column(
            children: [
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
                      // Nova companion starter prompts (real sends, AI-001).
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in const [
                              'Explain this topic in simple words',
                              'Give me a hint, no spoilers',
                              'Show me a quick example',
                            ])
                              _SuggestionChip(
                                label: s,
                                onTap: () {
                                  _input.text = s;
                                  _send();
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
                        enabled: !_sending,
                        style: const TextStyle(
                          fontFamily: AppTypography.bodyFamily,
                          fontSize: 14.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask Nova about your topic...',
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.surfaceElevated,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: const BorderSide(
                              color: AppColors.secondary,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _SendButton(onTap: _send, busy: _sending),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
    label: Text(
      label,
      style: const TextStyle(
        fontSize: 12.5,
        color: AppColors.secondary,
        fontWeight: FontWeight.w600,
      ),
    ),
    backgroundColor: AppColors.secondary.withValues(alpha: 0.08),
    side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.35)),
    onPressed: onTap,
  );
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.bubble});

  final _Bubble bubble;

  @override
  Widget build(BuildContext context) {
    final isLearner = bubble.role == 'LEARNER';
    return Align(
      alignment: isLearner ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: !isLearner
            ? const EdgeInsets.fromLTRB(12, 12, 14, 12)
            : const EdgeInsets.fromLTRB(14, 11, 14, 11),
        decoration: BoxDecoration(
          gradient: isLearner
              ? null
              : LinearGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.1),
                    AppColors.surfaceElevated,
                  ],
                ),
          color: isLearner
              ? AppColors.primaryDeep.withValues(alpha: 0.75)
              : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(isLearner ? AppRadius.lg : 6),
            bottomRight: Radius.circular(isLearner ? 6 : AppRadius.lg),
          ),
          border: Border.all(
            color: isLearner
                ? Colors.transparent
                : (bubble.refused || bubble.degraded
                      ? AppColors.warning.withValues(alpha: 0.4)
                      : AppColors.secondary.withValues(alpha: 0.3)),
          ),
        ),
        child: !isLearner
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const NovaCompanion(size: 26, mood: NovaMood.speaking),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      bubble.text,
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFamily,
                        fontSize: 13.8,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              )
            : Text(
                bubble.text,
                style: const TextStyle(
                  fontFamily: AppTypography.bodyFamily,
                  fontSize: 13.8,
                  height: 1.45,
                  color: Colors.white,
                ),
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: busy ? null : onTap,
    child: Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: busy
            ? null
            : const LinearGradient(
                colors: [AppColors.secondaryDeep, AppColors.secondary],
              ),
        color: busy ? AppColors.surfaceHigh : null,
      ),
      child: busy
          ? const Padding(
              padding: EdgeInsets.all(13),
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          : const Icon(
              Icons.send_rounded,
              size: 19,
              color: AppColors.textOnColor,
            ),
    ),
  );
}
