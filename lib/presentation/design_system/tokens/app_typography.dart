import 'package:flutter/material.dart';

/// Typography tokens that can be mapped to ThemeData.textTheme.
class AppTypography {
  AppTypography._();

  /// Returns a text theme slightly tuned for readability.
  static TextTheme textTheme(TextTheme base) {
    return base.copyWith(
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.3),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.3),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
