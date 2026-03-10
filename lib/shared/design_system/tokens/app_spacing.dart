import 'package:flutter/material.dart';

/// 4/8-based spacing scale for consistent paddings and gaps.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double xxxxl = 48.0;
  static const double xxxxxl = 64.0;

  /// Form max-width constraints for responsive layouts.
  static const double formMaxWidthSm = 200.0;
  static const double formMaxWidthMd = 400.0;
  static const double formMaxWidthLg = 600.0;
  static const double formMaxWidthXl = 800.0;

  /// Percentage-based sizing helpers.
  static double heightPercent(BuildContext context, double fraction) => MediaQuery.of(context).size.height * fraction;
  static double widthPercent(BuildContext context, double fraction) => MediaQuery.of(context).size.width * fraction;
}
