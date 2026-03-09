import 'package:flutter/material.dart';

/// Typography tokens that can be mapped to ThemeData.textTheme.
class AppTypography {
  AppTypography._();

  /// Returns a text theme tuned for readability with Poppins font and tight letter-spacing.
  static TextTheme textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
      ),
      displaySmall: base.displaySmall?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
      headlineLarge: base.headlineLarge?.copyWith(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w600, letterSpacing: -0.25),
      titleMedium: base.titleMedium?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w500, letterSpacing: -0.15),
      titleSmall: base.titleSmall?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: 'Poppins', height: 1.5),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: 'Poppins', height: 1.5),
      bodySmall: base.bodySmall?.copyWith(fontFamily: 'Poppins', height: 1.5),
      labelLarge: base.labelLarge?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
      labelMedium: base.labelMedium?.copyWith(fontFamily: 'Poppins'),
      labelSmall: base.labelSmall?.copyWith(fontFamily: 'Poppins'),
    );
  }
}
