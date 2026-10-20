import 'package:flutter/material.dart';

/// Enum for different theme palettes
enum AppThemePalette {
  classic('Classic', 'Neutral zinc — clean and minimal'),
  nature('Nature', 'Sage green — calm and organic'),
  sunset('Sunset', 'Warm stone — rich and inviting');

  const AppThemePalette(this.title, this.description);
  final String title;
  final String description;

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
