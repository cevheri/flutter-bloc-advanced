import 'package:flutter/material.dart';

/// Enum for different theme palettes
enum AppThemePalette {
  classic('Classic', 'Modern blue-grey theme'),
  nature('Nature', 'Fresh teal and ocean tones'),
  sunset('Sunset', 'Warm orange and purple tones');

  const AppThemePalette(this.title, this.description);
  final String title;
  final String description;

  /// Get the seed color for this palette
  Color get seedColor {
    switch (this) {
      case AppThemePalette.classic:
        return const Color(0xFF546E7A); // Blue Grey
      case AppThemePalette.nature:
        return const Color(0xFF00838F); // Teal
      case AppThemePalette.sunset:
        return const Color(0xFFFF7043); // Deep Orange
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
        return const Color(0xFF78909C);
      case AppThemePalette.nature:
        return const Color(0xFF26A69A);
      case AppThemePalette.sunset:
        return const Color(0xFFFF8A65);
    }
  }
}
