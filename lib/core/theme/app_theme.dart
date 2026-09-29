import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Global GameLearn AI themes — dark (original futuristic) + genuine light.
///
/// Both derive from the same semantic tokens (AppColors for dark accents,
/// AppLightColors for light surfaces/text). No per-screen random colors.
ThemeData buildGameLearnTheme() => buildGameLearnLightTheme();

ThemeData buildGameLearnDarkTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: AppTypography.bodyFamily,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnColor,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textOnColor,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.textOnColor,
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: AppTypography.bodyFamily,
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        fontFamily: AppTypography.displayFamily,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.25),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? AppColors.primaryBright
              : AppColors.textTertiary,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 22,
          color: states.contains(WidgetState.selected)
              ? AppColors.primaryBright
              : AppColors.textTertiary,
        ),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: Color(0x2E8B5CF6),
      selectedIconTheme: IconThemeData(
        size: 22,
        color: AppColors.primaryBright,
      ),
      unselectedIconTheme: IconThemeData(
        size: 22,
        color: AppColors.textTertiary,
      ),
      selectedLabelTextStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.primaryBright,
      ),
      unselectedLabelTextStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      shadowColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.textTertiary),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.6),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: const TextStyle(color: AppColors.textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primaryBright;
        return AppColors.textTertiary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary.withValues(alpha: 0.35);
        }
        return AppColors.surfaceHigh;
      }),
    ),
  );
}

ThemeData buildGameLearnLightTheme() {
  final base = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    fontFamily: AppTypography.bodyFamily,
    scaffoldBackgroundColor: AppLightColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppLightColors.textOnColor,
      secondary: AppColors.secondary,
      onSecondary: AppLightColors.textOnColor,
      surface: AppLightColors.surface,
      onSurface: AppLightColors.textPrimary,
      error: AppColors.error,
      onError: AppLightColors.textOnColor,
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: AppTypography.bodyFamily,
      bodyColor: AppLightColors.textPrimary,
      displayColor: AppLightColors.textPrimary,
    ),
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        fontFamily: AppTypography.displayFamily,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppLightColors.textPrimary,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: AppLightColors.textPrimary),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppLightColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppLightColors.textTertiary,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 22,
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppLightColors.textTertiary,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppLightColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.10),
      selectedIconTheme: const IconThemeData(
        size: 22,
        color: AppColors.primary,
      ),
      unselectedIconTheme: const IconThemeData(
        size: 22,
        color: AppLightColors.textTertiary,
      ),
      selectedLabelTextStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.primary,
      ),
      unselectedLabelTextStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppLightColors.textTertiary,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppLightColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppLightColors.border, width: 2.5),
      ),
      shadowColor: AppLightColors.border,
    ),
    dividerTheme:
        const DividerThemeData(color: AppLightColors.border, thickness: 1.5),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppLightColors.surface,
      hintStyle: const TextStyle(color: AppLightColors.textTertiary),
      labelStyle: const TextStyle(color: AppLightColors.textSecondary, fontWeight: FontWeight.w700),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppLightColors.border, width: 2.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppLightColors.border, width: 2.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppLightColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppLightColors.border, width: 2.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppLightColors.textPrimary,
      contentTextStyle: const TextStyle(color: AppLightColors.textOnColor),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return const Color(0xFF94A3B8);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary.withValues(alpha: 0.28);
        }
        return AppLightColors.surfaceHigh;
      }),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.secondary,
    ),
  );
}
