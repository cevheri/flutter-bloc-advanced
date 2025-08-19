import 'package:flutter/material.dart';
import 'app_theme_palette.dart';

/// Theme colors for different palettes
class ThemeColors {
  ThemeColors._();

  /// Get color scheme for a specific palette and brightness
  static ColorScheme getColorScheme(AppThemePalette palette, Brightness brightness) {
    switch (palette) {
      case AppThemePalette.classic:
        return _getClassicColorScheme(brightness);
      case AppThemePalette.nature:
        return _getNatureColorScheme(brightness);
      case AppThemePalette.sunset:
        return _getSunsetColorScheme(brightness);
    }
  }

  /// Classic theme - Blue Grey palette
  static ColorScheme _getClassicColorScheme(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const ColorScheme.light(
        primary: Color(0xFF546E7A), // Blue Grey 600
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFCFD8DC), // Blue Grey 100
        onPrimaryContainer: Color(0xFF263238), // Blue Grey 900
        secondary: Color(0xFF78909C), // Blue Grey 400
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFECEFF1), // Blue Grey 50
        onSecondaryContainer: Color(0xFF37474F), // Blue Grey 800
        tertiary: Color(0xFF90A4AE), // Blue Grey 300
        onTertiary: Color(0xFF263238), // Blue Grey 900
        tertiaryContainer: Color(0xFFF5F5F5), // Grey 100
        onTertiaryContainer: Color(0xFF37474F), // Blue Grey 800
        error: Color(0xFFB3261E), // Material 3 error
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFF9DEDC), // Material 3 error container
        onErrorContainer: Color(0xFF410E0B), // Material 3 on error container
        surface: Color(0xFFFFFBFE), // Material 3 surface
        onSurface: Color(0xFF1C1B1F), // Material 3 on surface
        surfaceContainerHighest: Color(0xFFE7E0EC), // Material 3 surface container highest
        onSurfaceVariant: Color(0xFF49454F), // Material 3 on surface variant
        outline: Color(0xFF79747E), // Material 3 outline
        outlineVariant: Color(0xFFCAC4D0), // Material 3 outline variant
        shadow: Color(0xFF000000), // Material 3 shadow
        scrim: Color(0xFF000000), // Material 3 scrim
        inverseSurface: Color(0xFF313033), // Material 3 inverse surface
        onInverseSurface: Color(0xFFF4EFF4), // Material 3 on inverse surface
        inversePrimary: Color(0xFFB0BEC5), // Blue Grey 200
        surfaceTint: Color(0xFF546E7A), // Blue Grey 600
      );
    } else {
      return const ColorScheme.dark(
        primary: Color(0xFFB0BEC5), // Blue Grey 200
        onPrimary: Color(0xFF263238), // Blue Grey 900
        primaryContainer: Color(0xFF37474F), // Blue Grey 800
        onPrimaryContainer: Color(0xFFCFD8DC), // Blue Grey 100
        secondary: Color(0xFF90A4AE), // Blue Grey 300
        onSecondary: Color(0xFF263238), // Blue Grey 900
        secondaryContainer: Color(0xFF455A64), // Blue Grey 700
        onSecondaryContainer: Color(0xFFECEFF1), // Blue Grey 50
        tertiary: Color(0xFF78909C), // Blue Grey 400
        onTertiary: Color(0xFF263238), // Blue Grey 900
        tertiaryContainer: Color(0xFF37474F), // Blue Grey 800
        onTertiaryContainer: Color(0xFFF5F5F5), // Grey 100
        error: Color(0xFFF2B8B5), // Material 3 error dark
        onError: Color(0xFF601410), // Material 3 on error dark
        errorContainer: Color(0xFF8C1D18), // Material 3 error container dark
        onErrorContainer: Color(0xFFF9DEDC), // Material 3 on error container dark
        surface: Color(0xFF1C1B1F), // Material 3 surface dark
        onSurface: Color(0xFFE6E1E5), // Material 3 on surface dark
        surfaceContainerHighest: Color(0xFF49454F), // Material 3 surface container highest dark
        onSurfaceVariant: Color(0xFFCAC4D0), // Material 3 on surface variant dark
        outline: Color(0xFF938F99), // Material 3 outline dark
        outlineVariant: Color(0xFF49454F), // Material 3 outline variant dark
        shadow: Color(0xFF000000), // Material 3 shadow dark
        scrim: Color(0xFF000000), // Material 3 scrim dark
        inverseSurface: Color(0xFFE6E1E5), // Material 3 inverse surface dark
        onInverseSurface: Color(0xFF313033), // Material 3 on inverse surface dark
        inversePrimary: Color(0xFF546E7A), // Blue Grey 600
        surfaceTint: Color(0xFFB0BEC5), // Blue Grey 200
      );
    }
  }

  /// Nature theme - Teal palette
  static ColorScheme _getNatureColorScheme(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const ColorScheme.light(
        primary: Color(0xFF00838F), // Teal 600
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFB2EBF2), // Teal 100
        onPrimaryContainer: Color(0xFF004D52), // Teal 900
        secondary: Color(0xFF26A69A), // Teal 400
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFE0F2F1), // Teal 50
        onSecondaryContainer: Color(0xFF004D52), // Teal 900
        tertiary: Color(0xFF4DB6AC), // Teal 300
        onTertiary: Color(0xFF004D52), // Teal 900
        tertiaryContainer: Color(0xFFF0F9F8), // Very light teal tint
        onTertiaryContainer: Color(0xFF004D52), // Teal 900
        error: Color(0xFFB3261E), // Material 3 error
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFF9DEDC), // Material 3 error container
        onErrorContainer: Color(0xFF410E0B), // Material 3 on error container
        surface: Color(0xFFFAFDFD), // Very light teal tint
        onSurface: Color(0xFF1C1B1F), // Material 3 on surface
        surfaceContainerHighest: Color(0xFFE0F2F1), // Teal 50
        onSurfaceVariant: Color(0xFF004D52), // Teal 900
        outline: Color(0xFF00838F), // Teal 600
        outlineVariant: Color(0xFFB2EBF2), // Teal 100
        shadow: Color(0xFF000000), // Material 3 shadow
        scrim: Color(0xFF000000), // Material 3 scrim
        inverseSurface: Color(0xFF313033), // Material 3 inverse surface
        onInverseSurface: Color(0xFFF4EFF4), // Material 3 on inverse surface
        inversePrimary: Color(0xFF80DEEA), // Teal 200
        surfaceTint: Color(0xFF00838F), // Teal 600
      );
    } else {
      return const ColorScheme.dark(
        primary: Color(0xFF80DEEA), // Teal 200
        onPrimary: Color(0xFF004D52), // Teal 900
        primaryContainer: Color(0xFF00695C), // Teal 800
        onPrimaryContainer: Color(0xFFB2EBF2), // Teal 100
        secondary: Color(0xFF4DB6AC), // Teal 300
        onSecondary: Color(0xFF004D52), // Teal 900
        secondaryContainer: Color(0xFF00796B), // Teal 700
        onSecondaryContainer: Color(0xFFE0F2F1), // Teal 50
        tertiary: Color(0xFF26A69A), // Teal 400
        onTertiary: Color(0xFF004D52), // Teal 900
        tertiaryContainer: Color(0xFF00695C), // Teal 800
        onTertiaryContainer: Color(0xFFF0F9F8), // Very light teal tint
        error: Color(0xFFF2B8B5), // Material 3 error dark
        onError: Color(0xFF601410), // Material 3 on error dark
        errorContainer: Color(0xFF8C1D18), // Material 3 error container dark
        onErrorContainer: Color(0xFFF9DEDC), // Material 3 on error container dark
        surface: Color(0xFF0A1414), // Very dark teal tint
        onSurface: Color(0xFFE6E1E5), // Material 3 on surface dark
        surfaceContainerHighest: Color(0xFF00695C), // Teal 800
        onSurfaceVariant: Color(0xFFB2EBF2), // Teal 100
        outline: Color(0xFF26A69A), // Teal 400
        outlineVariant: Color(0xFF00695C), // Teal 800
        shadow: Color(0xFF000000), // Material 3 shadow dark
        scrim: Color(0xFF000000), // Material 3 scrim dark
        inverseSurface: Color(0xFFE6E1E5), // Material 3 inverse surface dark
        onInverseSurface: Color(0xFF313033), // Material 3 on inverse surface dark
        inversePrimary: Color(0xFF00838F), // Teal 600
        surfaceTint: Color(0xFF80DEEA), // Teal 200
      );
    }
  }

  /// Sunset theme - Orange/Deep Orange palette
  static ColorScheme _getSunsetColorScheme(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const ColorScheme.light(
        primary: Color(0xFFFF7043), // Deep Orange 400
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFFFCCBC), // Deep Orange 100
        onPrimaryContainer: Color(0xFFBF360C), // Deep Orange 900
        secondary: Color(0xFFFF8A65), // Deep Orange 300
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFFFF3E0), // Orange 50
        onSecondaryContainer: Color(0xFFE65100), // Orange 900
        tertiary: Color(0xFFFFAB91), // Deep Orange 200
        onTertiary: Color(0xFFBF360C), // Deep Orange 900
        tertiaryContainer: Color(0xFFFFF8E1), // Amber 50
        onTertiaryContainer: Color(0xFFE65100), // Orange 900
        error: Color(0xFFB3261E), // Material 3 error
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFF9DEDC), // Material 3 error container
        onErrorContainer: Color(0xFF410E0B), // Material 3 on error container
        surface: Color(0xFFFFFBFE), // Material 3 surface with warm tint
        onSurface: Color(0xFF1C1B1F), // Material 3 on surface
        surfaceContainerHighest: Color(0xFFFFF3E0), // Orange 50
        onSurfaceVariant: Color(0xFFE65100), // Orange 900
        outline: Color(0xFFFF7043), // Deep Orange 400
        outlineVariant: Color(0xFFFFCCBC), // Deep Orange 100
        shadow: Color(0xFF000000), // Material 3 shadow
        scrim: Color(0xFF000000), // Material 3 scrim
        inverseSurface: Color(0xFF313033), // Material 3 inverse surface
        onInverseSurface: Color(0xFFF4EFF4), // Material 3 on inverse surface
        inversePrimary: Color(0xFFFFAB91), // Deep Orange 200
        surfaceTint: Color(0xFFFF7043), // Deep Orange 400
      );
    } else {
      return const ColorScheme.dark(
        primary: Color(0xFFFFAB91), // Deep Orange 200
        onPrimary: Color(0xFFBF360C), // Deep Orange 900
        primaryContainer: Color(0xFFE64A19), // Deep Orange 800
        onPrimaryContainer: Color(0xFFFFCCBC), // Deep Orange 100
        secondary: Color(0xFFFF8A65), // Deep Orange 300
        onSecondary: Color(0xFFBF360C), // Deep Orange 900
        secondaryContainer: Color(0xFFD84315), // Deep Orange 700
        onSecondaryContainer: Color(0xFFFFF3E0), // Orange 50
        tertiary: Color(0xFFFF7043), // Deep Orange 400
        onTertiary: Color(0xFFBF360C), // Deep Orange 900
        tertiaryContainer: Color(0xFFE64A19), // Deep Orange 800
        onTertiaryContainer: Color(0xFFFFF8E1), // Amber 50
        error: Color(0xFFF2B8B5), // Material 3 error dark
        onError: Color(0xFF601410), // Material 3 on error dark
        errorContainer: Color(0xFF8C1D18), // Material 3 error container dark
        onErrorContainer: Color(0xFFF9DEDC), // Material 3 on error container dark
        surface: Color(0xFF1C1B1F), // Material 3 surface dark
        onSurface: Color(0xFFE6E1E5), // Material 3 on surface dark
        surfaceContainerHighest: Color(0xFFE65100), // Orange 900
        onSurfaceVariant: Color(0xFFFFCCBC), // Deep Orange 100
        outline: Color(0xFFFF8A65), // Deep Orange 300
        outlineVariant: Color(0xFFE64A19), // Deep Orange 800
        shadow: Color(0xFF000000), // Material 3 shadow dark
        scrim: Color(0xFF000000), // Material 3 scrim dark
        inverseSurface: Color(0xFFE6E1E5), // Material 3 inverse surface dark
        onInverseSurface: Color(0xFF313033), // Material 3 on inverse surface dark
        inversePrimary: Color(0xFFFF7043), // Deep Orange 400
        surfaceTint: Color(0xFFFFAB91), // Deep Orange 200
      );
    }
  }
}
