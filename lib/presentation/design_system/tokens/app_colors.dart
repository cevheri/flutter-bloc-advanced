import 'package:flutter/material.dart';

/// Design tokens for colors used across the application.
/// Rooted in Material 3 and built from a single seed to ensure consistency.
class AppColors {
  AppColors._();

  /// Brand seed color to generate dynamic color schemes.
  static const Color seed = Colors.blueGrey;

  /// Optional semantic colors if needed outside ColorScheme.
  static const Color success = Color(0xFF2E7D32); // M3 green tone
  static const Color warning = Color(0xFFED6C02); // M3 orange tone
  static const Color error = Color(0xFFB3261E); // M3 error baseline

  /// Neutral greys for surfaces if needed ad hoc.
  static const Color neutral05 = Color(0xFFF7F8F9);
  static const Color neutral10 = Color(0xFFEDEFF1);
  static const Color neutral20 = Color(0xFFD8DDE1);
  static const Color neutral30 = Color(0xFFC3CAD1);
  static const Color neutral40 = Color(0xFFAEB7C1);
  static const Color neutral50 = Color(0xFF99A4AF);
}
