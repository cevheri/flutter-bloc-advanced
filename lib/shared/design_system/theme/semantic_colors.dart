import 'package:flutter/material.dart';

/// Semantic color extension for success/warning/info states beyond Material's error.
@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  const SemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  /// Light theme semantic colors (shared across all palettes).
  static const light = SemanticColors(
    success: Color(0xFF16A34A), // Green 600
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFDCFCE7), // Green 100
    onSuccessContainer: Color(0xFF14532D), // Green 900
    warning: Color(0xFFEAB308), // Yellow 500
    onWarning: Color(0xFF000000),
    warningContainer: Color(0xFFFEF9C3), // Yellow 100
    onWarningContainer: Color(0xFF713F12), // Yellow 900
    info: Color(0xFF2563EB), // Blue 600
    onInfo: Color(0xFFFFFFFF),
    infoContainer: Color(0xFFDBEAFE), // Blue 100
    onInfoContainer: Color(0xFF1E3A8A), // Blue 900
  );

  /// Dark theme semantic colors (shared across all palettes).
  static const dark = SemanticColors(
    success: Color(0xFF4ADE80), // Green 400
    onSuccess: Color(0xFF052E16), // Green 950
    successContainer: Color(0xFF166534), // Green 800
    onSuccessContainer: Color(0xFFBBF7D0), // Green 200
    warning: Color(0xFFFACC15), // Yellow 400
    onWarning: Color(0xFF000000),
    warningContainer: Color(0xFF854D0E), // Yellow 800
    onWarningContainer: Color(0xFFFEF08A), // Yellow 200
    info: Color(0xFF60A5FA), // Blue 400
    onInfo: Color(0xFF172554), // Blue 950
    infoContainer: Color(0xFF1E40AF), // Blue 800
    onInfoContainer: Color(0xFFBFDBFE), // Blue 200
  );

  @override
  SemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
  }) {
    return SemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
    );
  }

  @override
  SemanticColors lerp(covariant ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
    );
  }
}

/// Extension on [BuildContext] for convenient semantic color access.
extension SemanticColorsExtension on BuildContext {
  SemanticColors get semanticColors => Theme.of(this).extension<SemanticColors>()!;
}
