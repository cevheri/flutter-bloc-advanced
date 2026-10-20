import 'package:flutter/material.dart';

/// Enum for different theme palettes. Their names and descriptions are in the ARB files, see ThemeSelectionDialog.
enum AppThemePalette {
  classic,
  nature,
  sunset;

  /// Get the icon for this palette
  IconData get icon {
    switch (this) {
      case AppThemePalette.classic:
        return Icons.palette_outlined;
      case AppThemePalette.nature:
        return Icons.eco_outlined;
      case AppThemePalette.sunset:
        return Icons.wb_sunny_outlined;
    }
  }
}
