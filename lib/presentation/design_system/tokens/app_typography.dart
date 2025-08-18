import 'package:flutter/material.dart';

/// Typography tokens that can be mapped to ThemeData.textTheme.
class AppTypography {
  AppTypography._();

  /// Returns a text theme slightly tuned for readability with Poppins font.
  static TextTheme textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
      displayMedium: base.displayMedium?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
      displaySmall: base.displaySmall?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
      headlineLarge: base.headlineLarge?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
      headlineMedium: base.headlineMedium?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: 'Poppins', height: 1.3),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: 'Poppins', height: 1.3),
      bodySmall: base.bodySmall?.copyWith(fontFamily: 'Poppins', height: 1.3),
      labelLarge: base.labelLarge?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(fontFamily: 'Poppins'),
      labelSmall: base.labelSmall?.copyWith(fontFamily: 'Poppins'),
    );
  }
}
