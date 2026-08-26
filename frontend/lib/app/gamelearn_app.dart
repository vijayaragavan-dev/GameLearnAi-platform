import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class GameLearnApp extends ConsumerWidget {
  const GameLearnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'GameLearn AI',
      debugShowCheckedModeBanner: false,
      theme: buildGameLearnTheme(),
      routerConfig: router,
    );
  }
}
