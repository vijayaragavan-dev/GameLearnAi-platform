import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/feedback.dart';
import '../../../../shared/widgets/game_button.dart';

/// Honest empty state for world-scoped game content.
///
/// Shown when a WORLD arena game has no content attributed to the requested
/// world. Never substitutes another world's content, never fabricates.
/// The global arena (mixed content) remains playable from the dashboard.
class WorldScopeEmpty extends StatelessWidget {
  const WorldScopeEmpty({
    super.key,
    required this.worldName,
    required this.gameName,
  });

  final String worldName;
  final String gameName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(gameName.toUpperCase())),
      body: EmptyState(
        icon: Icons.hourglass_empty_rounded,
        title: 'No $worldName challenges yet',
        message:
            '$gameName has no $worldName content in this build. Backend content for this world is still being prepared — nothing from another world is substituted.',
        action: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SecondaryGameButton(
              label: 'BACK TO ARENA',
              icon: Icons.arrow_back_rounded,
              onTap: () => context.canPop()
                  ? context.pop()
                  : context.go('/subjects'),
            ),
          ],
        ),
      ),
    );
  }
}
