import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Material 3 themes for both Space moods.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
        brightness: Brightness.light,
        background: AppColors.paper,
        surface: AppColors.surfaceLight,
        ink: AppColors.ink,
        muted: AppColors.mutedLight,
        line: AppColors.lineLight,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        background: AppColors.night,
        surface: AppColors.surfaceDark,
        ink: AppColors.inkDark,
        muted: AppColors.mutedDark,
        line: AppColors.lineDark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color ink,
    required Color muted,
    required Color line,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.ember,
      brightness: brightness,
      surface: surface,
      onSurface: ink,
      primary: AppColors.ember,
      error: AppColors.danger,
    );
    final text = AppTypography.textTheme(ink, muted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineMedium,
        iconTheme: IconThemeData(color: ink, size: 22),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? Colors.black.withValues(alpha: 0.035)
            : Colors.white.withValues(alpha: 0.05),
        hintStyle: text.bodyMedium?.copyWith(color: muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.ember, width: 1.2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: brightness == Brightness.light ? AppColors.paper : AppColors.night,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
