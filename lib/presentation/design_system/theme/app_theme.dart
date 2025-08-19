import 'package:flutter/material.dart';

import '../tokens/app_typography.dart';
import 'app_theme_palette.dart';
import 'theme_colors.dart';

/// Application theme builder that centralizes Material 3 configuration.
class AppTheme {
  AppTheme._();

  static ThemeData light([AppThemePalette palette = AppThemePalette.classic]) {
    final colorScheme = ThemeColors.getColorScheme(palette, Brightness.light);
    return _themeData(colorScheme);
  }

  static ThemeData dark([AppThemePalette palette = AppThemePalette.classic]) {
    final colorScheme = ThemeColors.getColorScheme(palette, Brightness.dark);
    return _themeData(colorScheme);
  }

  static ThemeData _themeData(ColorScheme colorScheme) {
    final base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: colorScheme.brightness,
      fontFamily: 'Poppins', // Poppins fontunu varsayılan font olarak ayarla
    );
    final textTheme = AppTypography.textTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontFamily: 'Poppins', color: colorScheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: false,
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontFamily: 'Poppins'),
        helperStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontFamily: 'Poppins'),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withAlpha(179), fontFamily: 'Poppins'),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface, fontFamily: 'Poppins'),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontFamily: 'Poppins'),
        contentTextStyle: textTheme.bodyMedium?.copyWith(fontFamily: 'Poppins'),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurface,
        textColor: colorScheme.onSurface,
        selectedColor: colorScheme.primary,
        titleTextStyle: textTheme.bodyLarge?.copyWith(fontFamily: 'Poppins'),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(fontFamily: 'Poppins'),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge?.copyWith(fontFamily: 'Poppins'),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge?.copyWith(fontFamily: 'Poppins'),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge?.copyWith(fontFamily: 'Poppins'),
        ),
      ),
      cardTheme: CardThemeData(
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
