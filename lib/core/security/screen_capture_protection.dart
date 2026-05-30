import 'package:flutter/foundation.dart';
import 'package:screen_protector/screen_protector.dart';

import 'package:flutter_bloc_advance/core/logging/app_logger.dart';

/// Opt-in screen capture protection for sensitive screens.
///
/// Android: blocks screenshots and renders a black surface in the recent-apps
/// switcher (`FLAG_SECURE`).
/// iOS: cannot block screenshots (no public API); overlays a blurred view on
/// `applicationWillResignActive` so the task-switcher snapshot is blurred.
/// Web / Desktop: no-op (unsupported platforms).
///
/// Protection is reference-counted: it stays engaged while any caller holds a
/// lease (via [enable]) and is only disengaged once the last lease is released
/// (via [disable]). This keeps nested protected routes safe — popping an inner
/// protected screen will not turn protection off while an outer one is still
/// mounted.
class ScreenCaptureProtection {
  ScreenCaptureProtection._();

  static final _log = AppLogger.getLogger('ScreenCaptureProtection');

  /// Number of active protection leases. Protection is engaged while > 0.
  static int _leases = 0;

  /// Test seam — flip to true to simulate a web platform without a kIsWeb const.
  @visibleForTesting
  static bool debugWebOverride = false;

  /// Whether protection is currently active (at least one active lease).
  static bool get isEnabled => _leases > 0;

  /// Acquires a protection lease. The first lease engages platform protection
  /// on Android (block) and iOS (task-switcher blur); subsequent leases only
  /// bump the reference count. No-op on unsupported platforms (web/desktop).
  static Future<void> enable() async {
    if (!_isSupported) return;
    // Increment before awaiting so concurrent callers cannot both trigger the
    // initial plugin engagement (re-entrancy-safe idempotency).
    final wasInactive = _leases == 0;
    _leases++;
    if (!wasInactive) return;
    try {
      await ScreenProtector.protectDataLeakageOn();
      await ScreenProtector.protectDataLeakageWithBlur();
    } catch (e, st) {
      _log.warn('enable() — plugin call failed: {}\n{}', [e, st]);
    }
  }

  /// Releases a protection lease. Platform protection is disengaged only when
  /// the last lease is released. No-op on unsupported platforms (web/desktop)
  /// and when no lease is held.
  static Future<void> disable() async {
    if (!_isSupported) return;
    if (_leases == 0) return;
    _leases--;
    if (_leases > 0) return;
    try {
      await ScreenProtector.protectDataLeakageOff();
      await ScreenProtector.protectDataLeakageWithBlurOff();
    } catch (e, st) {
      _log.warn('disable() — plugin call failed: {}\n{}', [e, st]);
    }
  }

  /// Only Android and iOS support the underlying plugin; web and desktop are
  /// explicit no-ops so [isEnabled] never reports a false positive there.
  static bool get _isSupported {
    if (debugWebOverride || kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  @visibleForTesting
  static void resetForTesting() {
    _leases = 0;
    debugWebOverride = false;
  }
}
