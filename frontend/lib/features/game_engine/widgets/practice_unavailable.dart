import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_button.dart';

/// Truthful unavailable state for a topic that serves lessons but has no
/// playable quiz (backend QUIZ-001 answers 404).
///
/// Generic by construction: it triggers on a missing quiz for ANY topic and
/// carries only route-level IDs — no subject/topic names are hardcoded, no
/// future availability is promised, and no practice content is fabricated.
/// Alternative actions reuse existing navigation (lesson + AI Tutor).
class PracticeUnavailable extends StatelessWidget {
  const PracticeUnavailable({
    super.key,
    required this.topicId,
    this.subjectId,
    this.topicName,
  });

  final String topicId;
  final String? subjectId;
  final String? topicName;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.school_outlined,
      title: 'Practice unavailable',
      message:
          'This topic offers lessons. There are no playable practice questions for it.',
      action: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryGameButton(
            label: 'Return to lesson',
            icon: Icons.menu_book_rounded,
            onTap: () => context.push(Routes.lesson(topicId)),
          ),
          const SizedBox(height: 10),
          SecondaryGameButton(
            label: 'Ask Nova',
            icon: Icons.psychology_rounded,
            onTap: () => context.push(
              Routes.tutorWithContext(
                subjectId: subjectId,
                topicId: topicId,
                topicName: topicName,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
