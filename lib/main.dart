import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/gamelearn_app.dart';
import 'core/config/app_config.dart';
import 'core/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Restore user-configured backend URL or initialize active ngrok tunnel
  final savedUrl = prefs.getString('custom_backend_url');
  if (savedUrl != null && savedUrl.trim().isNotEmpty) {
    if (savedUrl.contains('localhost') || savedUrl.contains('10.0.2.2')) {
      // Clear stale localhost override from previous testing
      await prefs.remove('custom_backend_url');
      AppConfig.setOverrideUrl(AppConfig.defaultRemoteUrl);
    } else {
      AppConfig.setOverrideUrl(savedUrl);
    }
  } else {
    AppConfig.setOverrideUrl(AppConfig.defaultRemoteUrl);
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const GameLearnApp(),
    ),
  );
}
