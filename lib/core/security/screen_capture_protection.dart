import 'package:flutter/foundation.dart';
import 'package:screen_protector/screen_protector.dart';

import 'package:flutter_bloc_advance/core/logging/app_logger.dart';

/// Opt-in screen capture protection for sensitive screens.
///
/// Android: blocks screenshots and renders a black surface in the recent-apps
/// switcher (`FLAG_SECURE`).
/// iOS: cannot block screenshots (no public API); overlays a blurred view on
/// `applicationWillResignActive` so the task-switcher snapshot is blank.
/// Web / Desktop: no-op.
class ScreenCaptureProtection {
  ScreenCaptureProtection._();

  static final _log = AppLogger.getLogger('ScreenCaptureProtection');
  static bool _enabled = false;

  /// Test seam — flip to true to simulate a web platform without a kIsWeb const.
  @visibleForTesting
  static bool debugWebOverride = false;

  /// Whether protection is currently active.
  static bool get isEnabled => _enabled;

  /// Activates protection on Android (block) and iOS (task-switcher blur).
  /// Idempotent; second call while already enabled is a no-op. No-op on web.
  static Future<void> enable() async {
    if (_enabled) return;
    if (_isWeb) return;
    try {
      await ScreenProtector.protectDataLeakageOn();
      await ScreenProtector.protectDataLeakageWithBlur();
    } catch (e, st) {
      _log.warn('enable() — plugin call failed: {}\n{}', [e, st]);
    }
    _enabled = true;
  }

  /// Deactivates protection. Idempotent. No-op on web.
  static Future<void> disable() async {
    if (!_enabled) return;
    if (_isWeb) return;
    try {
      await ScreenProtector.protectDataLeakageOff();
      await ScreenProtector.protectDataLeakageWithBlurOff();
    } catch (e, st) {
      _log.warn('disable() — plugin call failed: {}\n{}', [e, st]);
    }
    _enabled = false;
  }

  static bool get _isWeb => debugWebOverride || kIsWeb;

  @visibleForTesting
  static void resetForTesting() {
    _enabled = false;
    debugWebOverride = false;
  }
}
