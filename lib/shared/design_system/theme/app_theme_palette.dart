import 'package:flutter/material.dart';

/// Enum for different theme palettes
enum AppThemePalette {
  classic('Classic', 'Neutral zinc — clean and minimal'),
  nature('Nature', 'Sage green — calm and organic'),
  sunset('Sunset', 'Warm stone — rich and inviting');

  const AppThemePalette(this.title, this.description);
  final String title;
  final String description;

  /// Get the seed color for this palette
  Color get seedColor {
    switch (this) {
      case AppThemePalette.classic:
        return const Color(0xFF18181B); // Zinc 900
      case AppThemePalette.nature:
        return const Color(0xFF1A1D1A); // Sage 900
      case AppThemePalette.sunset:
        return const Color(0xFF1C1917); // Stone 900
    }
  }

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

  /// Get a preview color for the palette
  Color get previewColor {
    switch (this) {
      case AppThemePalette.classic:
        return const Color(0xFF71717A); // Zinc 500
      case AppThemePalette.nature:
        return const Color(0xFF5F7A64); // Sage green
      case AppThemePalette.sunset:
        return const Color(0xFFC2410C); // Orange 700
    }
  }
}
