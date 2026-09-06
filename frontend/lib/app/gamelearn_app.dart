import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import 'router.dart';

class GameLearnApp extends ConsumerStatefulWidget {
  const GameLearnApp({super.key});

  @override
  ConsumerState<GameLearnApp> createState() => _GameLearnAppState();
}

class _GameLearnAppState extends ConsumerState<GameLearnApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final audio = ref.read(audioManagerProvider);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      audio.pauseForBackground();
    } else if (state == AppLifecycleState.resumed) {
      audio.resumeFromBackground();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeControllerProvider);
    return MaterialApp.router(
      title: 'GameLearn AI',
      debugShowCheckedModeBanner: false,
      theme: buildGameLearnLightTheme(),
      darkTheme: buildGameLearnDarkTheme(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
