import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart';
import '../../../core/error/user_facing_error.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/cinematic_surfaces.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/nova_companion.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../data/study_lab_repository.dart';
import '../domain/study_document.dart';
import '../domain/study_tutor.dart';
import 'widgets/document_card.dart';
import 'widgets/source_citation_card.dart';

/// DOCUMENT-GROUNDED NOVA TUTOR (RAG-FE-3 UI foundation).
///
/// Nova remains the ONE assistant: this screen associates the existing
/// Nova Tutor experience with one study document. Conversation state is
/// local; asking calls [StudyLabRepository.askDocumentQuestion], which
/// reports [TutorUnavailable] until the MlRag service lands — NEVER a
/// fabricated answer. Grounded indicators and sources render ONLY from
/// backend-supplied metadata ([DocumentChatMessage.grounded]).
class DocumentTutorScreen extends ConsumerStatefulWidget {
  const DocumentTutorScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentTutorScreen> createState() =>
      _DocumentTutorScreenState();
}

class _DocumentTutorScreenState extends ConsumerState<DocumentTutorScreen> {
  static const int _maxQuestionChars = 2000;

  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();

  late Future<StudyDocument?> _docFuture;
  final List<DocumentChatMessage> _messages = [];
  bool _pending = false;
  String? _error;
  String? _notice;
  String? _lastQuestion;

  @override
  void initState() {
    super.initState();
    _docFuture = ref.read(studyLabRepoProvider).documentById(widget.documentId);
    ref.read(audioManagerProvider).playContext(MusicContext.tutor);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
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

  /// Explicit send only: empty input never sends, pending never doubles.
  Future<void> _send() async {
    final question = _input.text.trim();
    if (question.isEmpty || _pending) return;
    if (question.length > _maxQuestionChars) {
      setState(() {
        _error =
            'Questions are limited to $_maxQuestionChars characters.';
      });
      return;
    }
    FocusScope.of(context).unfocus();
    ref.read(audioManagerProvider).play(Sfx.buttonConfirm);
    _ask(question, clearInput: true);
  }

  /// Retry re-runs the last real repository call (never duplicates the
  /// learner bubble, never invents an answer).
  Future<void> _retry() async {
    final question = _lastQuestion;
    if (question == null || question.isEmpty || _pending) return;
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    _ask(question, clearInput: false);
  }

  Future<void> _ask(String question, {required bool clearInput}) async {
    setState(() {
      if (clearInput) {
        _messages.add(
          DocumentChatMessage(role: ChatRole.learner, text: question),
        );
        _input.clear();
      }
      _pending = true;
      _error = null;
      _notice = null;
      _lastQuestion = question;
    });
    _scrollDown();
    try {
      final result = await ref
          .read(studyLabRepoProvider)
          .askDocumentQuestion(
            documentId: widget.documentId,
            question: question,
          );
      if (!mounted) return;
      setState(() {
        _pending = false;
        switch (result) {
          case TutorAnswer(:final text, :final sources, :final grounded):
            _messages.add(
              DocumentChatMessage(
                role: ChatRole.nova,
                text: text,
                sources: sources,
                grounded: grounded,
              ),
            );
          case TutorNoAnswer(:final message):
            _messages.add(
              DocumentChatMessage(role: ChatRole.nova, text: message),
            );
          case TutorUnavailable(:final message):
            _notice = message;
          case TutorFailure(:final message):
            _notice = message;
        }
      });
      _scrollDown();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _pending = false;
        _notice = describeError(e).message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pending = false;
        _notice = "Nova couldn't answer right now.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.canPop() ? context.pop() : null,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const NovaCompanion(size: 34, mood: NovaMood.idle),
            const SizedBox(width: 10),
            Expanded(
              child: FutureBuilder<StudyDocument?>(
                future: _docFuture,
                builder: (context, snap) {
                  final title = snap.data?.title;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NOVA TUTOR',
                        style: TextStyle(fontSize: 14.5, letterSpacing: 1),
                      ),
                      Text(
                        title == null
                            ? 'AI Study Lab'
                            : 'Studying: $title',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        semanticsLabel: title == null
                            ? 'Nova Tutor'
                            : 'Nova Tutor. Studying document $title',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppLightColors.textSecondary,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AtmosphericBackground()),
          SafeArea(
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: FutureBuilder<StudyDocument?>(
                future: _docFuture,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done &&
                      !snap.hasData) {
                    return const CinematicLoading(
                      message: 'Opening Nova Tutor...',
                    );
                  }
                  if (snap.hasError) {
                    final err = describeError(snap.error!);
                    return ErrorState(
                      title: err.title,
                      message: err.message,
                      onRetry: () => setState(() {
                        _docFuture = ref
                            .read(studyLabRepoProvider)
                            .documentById(widget.documentId);
                      }),
                    );
                  }
                  final doc = snap.data;
                  if (doc == null) {
                    return EmptyState(
                      icon: Icons.psychology_rounded,
                      title: 'Document unavailable',
                      message:
                          'Nova needs a document to ground this conversation '
                          'and none is available right now.',
                      action: SecondaryGameButton(
                        label: 'Back to Study Lab',
                        icon: Icons.science_rounded,
                        expanded: false,
                        onTap: () => context.go(Routes.aiStudyLab),
                      ),
                    );
                  }
                  return _ConversationColumn(
                    document: doc,
                    messages: _messages,
                    pending: _pending,
                    error: _error,
                    notice: _notice,
                    input: _input,
                    scroll: _scroll,
                    focus: _focus,
                    onSend: _send,
                    onRetry: _retry,
                    onSuggest: (prompt) {
                      ref.read(audioManagerProvider).play(Sfx.buttonTap);
                      // Suggestions populate the composer only: no backend
                      // exists to answer, so nothing is ever auto-sent.
                      setState(() {
                        _input.text = prompt;
                        _error = null;
                      });
                      _focus.requestFocus();
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationColumn extends StatelessWidget {
  const _ConversationColumn({
    required this.document,
    required this.messages,
    required this.pending,
    required this.error,
    required this.notice,
    required this.input,
    required this.scroll,
    required this.focus,
    required this.onSend,
    required this.onRetry,
    required this.onSuggest,
  });

  final StudyDocument document;
  final List<DocumentChatMessage> messages;
  final bool pending;
  final String? error;
  final String? notice;
  final TextEditingController input;
  final ScrollController scroll;
  final FocusNode focus;
  final VoidCallback onSend;
  final VoidCallback onRetry;
  final ValueChanged<String> onSuggest;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // ── DOCUMENT CONTEXT STRIP ──
        // Association (which document), never a grounding claim.
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppGutters.pagePadding(context),
            8,
            AppGutters.pagePadding(context),
            0,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceElevated.withValues(alpha: 0.7)
                  : AppLightColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.30),
              ),
            ),
            child: Row(
              children: [
                DocumentTypeIcon(
                  fileType: document.fileType,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        semanticsLabel:
                            'Conversation document ${document.title}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'DOCUMENT CONTEXT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.secondary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    color: AppColors.secondary.withValues(
                      alpha: isDark ? 0.12 : 0.08,
                    ),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.psychology_rounded,
                        size: 12,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'NOVA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ResponsiveCenter(
            child: ListView.builder(
              controller: scroll,
              padding: EdgeInsets.fromLTRB(
                AppGutters.pagePadding(context),
                12,
                AppGutters.pagePadding(context),
                12,
              ),
              itemCount:
                  messages.length + (pending ? 1 : 0) + (messages.isEmpty &&
                      !pending
                  ? 1
                  : 0),
              itemBuilder: (context, i) {
                if (messages.isEmpty &&
                    !pending &&
                    i == messages.length) {
                  return _SuggestionsBlock(onSuggest: onSuggest);
                }
                if (i == messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: _ThinkingRow(),
                    ),
                  );
                }
                final m = messages[i];
                return _ChatBubble(key: ValueKey('msg-$i'), message: m);
              },
            ),
          ),
        ),
        if (notice != null)
          _ServiceNotice(message: notice!, onRetry: onRetry),
        if (error != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                    error!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _Composer(
          input: input,
          focus: focus,
          pending: pending,
          onSend: onSend,
        ),
      ],
    );
  }
}

/// Honest system notice (service states, NOT Nova speech): unavailable
/// or failure with a real retry operation.
class _ServiceNotice extends StatelessWidget {
  const _ServiceNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceElevated.withValues(alpha: 0.85)
            : AppLightColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const NovaCompanion(size: 30, mood: NovaMood.idle),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark
                    ? AppColors.textSecondary
                    : AppLightColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GameChip(
            label: 'RETRY',
            icon: Icons.refresh_rounded,
            color: AppColors.secondary,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}

/// Nova thinking row: companion + label + framework spinner. No custom
/// controllers (nothing to dispose, no page-wide animation).
class _ThinkingRow extends StatelessWidget {
  const _ThinkingRow();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Nova is thinking',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NovaCompanion(size: 30, mood: NovaMood.thinking),
          const SizedBox(width: 10),
          Text(
            'Nova is thinking…',
            style: TextStyle(
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              color: isDark
                  ? AppColors.textSecondary
                  : AppLightColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Message bubble mirroring the Nova Tutor visual language: learner
/// right/primary, Nova left/secondary-tinted, with grounded pill +
/// source cards rendered ONLY from message metadata.
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({super.key, required this.message});

  final DocumentChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final m = message;
    final isLearner = m.isLearner;
    return Semantics(
      label: isLearner ? 'Your message' : 'Nova response',
      child: Align(
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
            color: isLearner
                ? AppColors.primaryDeep.withValues(alpha: 0.75)
                : (isDark ? AppColors.surfaceElevated : AppLightColors.surface),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadius.lg),
              topRight: const Radius.circular(AppRadius.lg),
              bottomLeft: Radius.circular(isLearner ? AppRadius.lg : 6),
              bottomRight: Radius.circular(isLearner ? 6 : AppRadius.lg),
            ),
            border: Border.all(
              color: isLearner
                  ? Colors.transparent
                  : AppColors.secondary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                m.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isLearner
                      ? Colors.white
                      : (isDark
                            ? AppColors.textPrimary
                            : AppLightColors.textPrimary),
                ),
              ),
              // Grounded indicator: backend metadata ONLY. The label
              // flexes instead of overflowing on narrow screens.
              if (!isLearner && m.grounded) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Grounded in this document',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppLightColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (!isLearner && m.sources.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Sources',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: isDark
                        ? AppColors.textTertiary
                        : AppLightColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 6),
                for (final src in m.sources) ...[
                  SourceCitationCard(source: src),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty-conversation suggestions: populate the composer ONLY.
/// Responses come exclusively from a real backend implementation.
class _SuggestionsBlock extends StatelessWidget {
  const _SuggestionsBlock({required this.onSuggest});

  final ValueChanged<String> onSuggest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const NovaCompanion(size: 34, mood: NovaMood.encouraging),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask Nova anything about this document.',
                      style: AppTypography.h3(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nova will use the document as context when answering.',
                      style: AppTypography.bodySecondary(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const NeonSectionHeader(
            icon: Icons.bolt_rounded,
            title: 'Suggested questions',
            subtitle: 'Tap to fill the composer',
            accent: AppColors.secondary,
          ),
          const SizedBox(height: 10),
            Builder(
              builder: (context) {
                final w = MediaQuery.sizeOf(context).width;
                final cols = w >= 1024 ? 4 : (w >= 600 ? 3 : 2);
                // Fixed card height (~112) derived from the live cell
                // width: multi-line labels never clip on 320px, and
                // wide layouts stay compact instead of stretching tall.
                // Width accounts for ResponsiveCenter's max-width cap.
                final gridW =
                    (w < AppBreakpoints.maxContentWidth
                            ? w
                            : AppBreakpoints.maxContentWidth) -
                        AppGutters.pagePadding(context) * 2;
                final ratio =
                    ((gridW - 10 * (cols - 1)) / cols) / 112;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: ratio,
                  ),
                itemCount: documentTutorSuggestions.length,
                itemBuilder: (context, i) {
                  final label = documentTutorSuggestions[i];
                  return Pressable(
                    onTap: () => onSuggest(label),
                    semanticsLabel: 'Fill composer with: $label',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark(context)
                            ? AppColors.surfaceElevated.withValues(alpha: 0.8)
                            : AppLightColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: AppColors.secondary.withValues(
                            alpha: isDark(context) ? 0.45 : 0.35,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 22,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

/// Premium composer dock mirroring the Nova Tutor pattern: multiline,
/// char-bounded, keyboard-safe, send disabled while pending or empty.
class _Composer extends StatefulWidget {
  const _Composer({
    required this.input,
    required this.focus,
    required this.pending,
    required this.onSend,
  });

  final TextEditingController input;
  final FocusNode focus;
  final bool pending;
  final VoidCallback onSend;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  @override
  void initState() {
    super.initState();
    widget.input.addListener(_onText);
  }

  @override
  void didUpdateWidget(covariant _Composer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.input != widget.input) {
      oldWidget.input.removeListener(_onText);
      widget.input.addListener(_onText);
    }
  }

  @override
  void dispose() {
    widget.input.removeListener(_onText);
    super.dispose();
  }

  void _onText() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSend =
        !widget.pending && widget.input.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceElevated.withValues(alpha: 0.92)
              : AppLightColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.secondary.withValues(
              alpha: isDark ? 0.45 : 0.35,
            ),
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: widget.input,
                focusNode: widget.focus,
                maxLines: 4,
                minLines: 1,
                maxLength:
                    _DocumentTutorScreenState._maxQuestionChars,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => widget.onSend(),
                enabled: !widget.pending,
                style: TextStyle(
                  fontFamily: AppTypography.bodyFamily,
                  fontSize: 14.5,
                  color: isDark
                      ? AppColors.textPrimary
                      : AppLightColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask Nova about this document...',
                  counterText: '',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceElevated
                      : AppLightColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.border
                          : AppLightColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.border
                          : AppLightColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(
                      color: AppColors.secondary,
                      width: 1.4,
                    ),
                  ),
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.textTertiary
                        : AppLightColors.textTertiary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              label: 'Send message',
              button: true,
              enabled: canSend,
              child: InkWell(
                onTap: canSend ? widget.onSend : null,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: canSend
                        ? LinearGradient(
                            colors: [
                              AppColors.secondary.withValues(alpha: 0.85),
                              AppColors.secondary,
                            ],
                          )
                        : null,
                    color: canSend
                        ? null
                        : (isDark
                              ? AppColors.lockedSurface
                              : AppLightColors.lockedSurface),
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    size: 22,
                    color: canSend
                        ? Colors.white
                        : (isDark
                              ? AppColors.textDisabled
                              : AppLightColors.textDisabled),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
