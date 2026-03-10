import 'package:flutter/material.dart';
import 'app_theme_palette.dart';

/// Theme colors for different palettes — shadcn/ui inspired neutral aesthetics.
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

  /// Classic "Zinc" — neutral grey, near-black primary
  static ColorScheme _getClassicColorScheme(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const ColorScheme.light(
        primary: Color(0xFF18181B), // Zinc 900
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFF4F4F5), // Zinc 100
        onPrimaryContainer: Color(0xFF18181B), // Zinc 900
        secondary: Color(0xFF71717A), // Zinc 500
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFF4F4F5), // Zinc 100
        onSecondaryContainer: Color(0xFF27272A), // Zinc 800
        tertiary: Color(0xFFA1A1AA), // Zinc 400
        onTertiary: Color(0xFF18181B), // Zinc 900
        tertiaryContainer: Color(0xFFF4F4F5), // Zinc 100
        onTertiaryContainer: Color(0xFF27272A), // Zinc 800
        error: Color(0xFFDC2626), // Red 600
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFEE2E2), // Red 100
        onErrorContainer: Color(0xFF991B1B), // Red 800
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF09090B), // Zinc 950
        surfaceContainerHighest: Color(0xFFF4F4F5), // Zinc 100
        onSurfaceVariant: Color(0xFF71717A), // Zinc 500
        outline: Color(0xFFE4E4E7), // Zinc 200
        outlineVariant: Color(0xFFF4F4F5), // Zinc 100
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFF18181B), // Zinc 900
        onInverseSurface: Color(0xFFFAFAFA), // Zinc 50
        inversePrimary: Color(0xFFD4D4D8), // Zinc 300
        surfaceTint: Color(0xFF18181B), // Zinc 900
      );
    } else {
      return const ColorScheme.dark(
        primary: Color(0xFFFAFAFA), // Zinc 50
        onPrimary: Color(0xFF09090B), // Zinc 950
        primaryContainer: Color(0xFF27272A), // Zinc 800
        onPrimaryContainer: Color(0xFFFAFAFA), // Zinc 50
        secondary: Color(0xFFA1A1AA), // Zinc 400
        onSecondary: Color(0xFF09090B), // Zinc 950
        secondaryContainer: Color(0xFF27272A), // Zinc 800
        onSecondaryContainer: Color(0xFFF4F4F5), // Zinc 100
        tertiary: Color(0xFF71717A), // Zinc 500
        onTertiary: Color(0xFFFAFAFA), // Zinc 50
        tertiaryContainer: Color(0xFF27272A), // Zinc 800
        onTertiaryContainer: Color(0xFFF4F4F5), // Zinc 100
        error: Color(0xFFF87171), // Red 400
        onError: Color(0xFF09090B), // Zinc 950
        errorContainer: Color(0xFF7F1D1D), // Red 900
        onErrorContainer: Color(0xFFFECACA), // Red 200
        surface: Color(0xFF09090B), // Zinc 950
        onSurface: Color(0xFFFAFAFA), // Zinc 50
        surfaceContainerHighest: Color(0xFF27272A), // Zinc 800
        onSurfaceVariant: Color(0xFFA1A1AA), // Zinc 400
        outline: Color(0xFF27272A), // Zinc 800
        outlineVariant: Color(0xFF18181B), // Zinc 900
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFFFAFAFA), // Zinc 50
        onInverseSurface: Color(0xFF09090B), // Zinc 950
        inversePrimary: Color(0xFF52525B), // Zinc 600
        surfaceTint: Color(0xFFFAFAFA), // Zinc 50
      );
    }
  }

  /// Nature "Sage" — green-tinted neutral
  static ColorScheme _getNatureColorScheme(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const ColorScheme.light(
        primary: Color(0xFF1A1D1A), // Sage 900
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFF0F4F0), // Sage 100
        onPrimaryContainer: Color(0xFF1A1D1A), // Sage 900
        secondary: Color(0xFF5F7A64), // Sage green accent
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFE8F0E8), // Sage 50
        onSecondaryContainer: Color(0xFF1A1D1A), // Sage 900
        tertiary: Color(0xFF8BA68F), // Sage 400
        onTertiary: Color(0xFF1A1D1A), // Sage 900
        tertiaryContainer: Color(0xFFF0F4F0), // Sage 100
        onTertiaryContainer: Color(0xFF2A302B), // Sage 800
        error: Color(0xFFDC2626), // Red 600
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFEE2E2), // Red 100
        onErrorContainer: Color(0xFF991B1B), // Red 800
        surface: Color(0xFFFCFDFC),
        onSurface: Color(0xFF0D0F0D), // Sage 950
        surfaceContainerHighest: Color(0xFFF0F4F0), // Sage 100
        onSurfaceVariant: Color(0xFF6B7C6E), // Sage 500
        outline: Color(0xFFDAE2DB), // Sage 200
        outlineVariant: Color(0xFFF0F4F0), // Sage 100
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFF1A1D1A), // Sage 900
        onInverseSurface: Color(0xFFF5F8F5), // Sage 50
        inversePrimary: Color(0xFFB8CBB9), // Sage 300
        surfaceTint: Color(0xFF1A1D1A), // Sage 900
      );
    } else {
      return const ColorScheme.dark(
        primary: Color(0xFFF5F8F5), // Sage 50
        onPrimary: Color(0xFF0D0F0D), // Sage 950
        primaryContainer: Color(0xFF2A302B), // Sage 800
        onPrimaryContainer: Color(0xFFF5F8F5), // Sage 50
        secondary: Color(0xFF8BA68F), // Sage green accent
        onSecondary: Color(0xFF0D0F0D), // Sage 950
        secondaryContainer: Color(0xFF2A302B), // Sage 800
        onSecondaryContainer: Color(0xFFF0F4F0), // Sage 100
        tertiary: Color(0xFF6B7C6E), // Sage 500
        onTertiary: Color(0xFFF5F8F5), // Sage 50
        tertiaryContainer: Color(0xFF2A302B), // Sage 800
        onTertiaryContainer: Color(0xFFF0F4F0), // Sage 100
        error: Color(0xFFF87171), // Red 400
        onError: Color(0xFF0D0F0D), // Sage 950
        errorContainer: Color(0xFF7F1D1D), // Red 900
        onErrorContainer: Color(0xFFFECACA), // Red 200
        surface: Color(0xFF0D0F0D), // Sage 950
        onSurface: Color(0xFFF5F8F5), // Sage 50
        surfaceContainerHighest: Color(0xFF2A302B), // Sage 800
        onSurfaceVariant: Color(0xFF8BA68F), // Sage 400
        outline: Color(0xFF2A302B), // Sage 800
        outlineVariant: Color(0xFF1A1D1A), // Sage 900
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFFF5F8F5), // Sage 50
        onInverseSurface: Color(0xFF0D0F0D), // Sage 950
        inversePrimary: Color(0xFF5F7A64), // Sage 600
        surfaceTint: Color(0xFFF5F8F5), // Sage 50
      );
    }
  }

  /// Sunset "Stone" — warm-tinted neutral with orange accent
  static ColorScheme _getSunsetColorScheme(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const ColorScheme.light(
        primary: Color(0xFF1C1917), // Stone 900
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFF5F5F4), // Stone 100
        onPrimaryContainer: Color(0xFF1C1917), // Stone 900
        secondary: Color(0xFFC2410C), // Orange 700 warm accent
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFFFF7ED), // Orange 50
        onSecondaryContainer: Color(0xFF7C2D12), // Orange 900
        tertiary: Color(0xFFA8A29E), // Stone 400
        onTertiary: Color(0xFF1C1917), // Stone 900
        tertiaryContainer: Color(0xFFF5F5F4), // Stone 100
        onTertiaryContainer: Color(0xFF292524), // Stone 800
        error: Color(0xFFDC2626), // Red 600
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFEE2E2), // Red 100
        onErrorContainer: Color(0xFF991B1B), // Red 800
        surface: Color(0xFFFAFAF9), // Stone 50
        onSurface: Color(0xFF0C0A09), // Stone 950
        surfaceContainerHighest: Color(0xFFF5F5F4), // Stone 100
        onSurfaceVariant: Color(0xFF78716C), // Stone 500
        outline: Color(0xFFE7E5E4), // Stone 200
        outlineVariant: Color(0xFFF5F5F4), // Stone 100
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFF1C1917), // Stone 900
        onInverseSurface: Color(0xFFFAFAF9), // Stone 50
        inversePrimary: Color(0xFFD6D3D1), // Stone 300
        surfaceTint: Color(0xFF1C1917), // Stone 900
      );
    } else {
      return const ColorScheme.dark(
        primary: Color(0xFFFAFAF9), // Stone 50
        onPrimary: Color(0xFF0C0A09), // Stone 950
        primaryContainer: Color(0xFF292524), // Stone 800
        onPrimaryContainer: Color(0xFFFAFAF9), // Stone 50
        secondary: Color(0xFFFB923C), // Orange 400 warm accent
        onSecondary: Color(0xFF0C0A09), // Stone 950
        secondaryContainer: Color(0xFF292524), // Stone 800
        onSecondaryContainer: Color(0xFFFED7AA), // Orange 200
        tertiary: Color(0xFF78716C), // Stone 500
        onTertiary: Color(0xFFFAFAF9), // Stone 50
        tertiaryContainer: Color(0xFF292524), // Stone 800
        onTertiaryContainer: Color(0xFFF5F5F4), // Stone 100
        error: Color(0xFFF87171), // Red 400
        onError: Color(0xFF0C0A09), // Stone 950
        errorContainer: Color(0xFF7F1D1D), // Red 900
        onErrorContainer: Color(0xFFFECACA), // Red 200
        surface: Color(0xFF0C0A09), // Stone 950
        onSurface: Color(0xFFFAFAF9), // Stone 50
        surfaceContainerHighest: Color(0xFF292524), // Stone 800
        onSurfaceVariant: Color(0xFFA8A29E), // Stone 400
        outline: Color(0xFF292524), // Stone 800
        outlineVariant: Color(0xFF1C1917), // Stone 900
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFFFAFAF9), // Stone 50
        onInverseSurface: Color(0xFF0C0A09), // Stone 950
        inversePrimary: Color(0xFF57534E), // Stone 600
        surfaceTint: Color(0xFFFAFAF9), // Stone 50
      );
    }
  }
}
