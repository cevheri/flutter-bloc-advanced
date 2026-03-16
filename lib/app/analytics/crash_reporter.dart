import 'package:flutter/foundation.dart';
import 'package:flutter_bloc_advance/core/analytics/analytics_service.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';

/// Sets up global error handlers for crash reporting.
///
/// Captures both Flutter framework errors and async/platform errors,
/// forwarding them to the [IAnalyticsService] for logging/reporting.
class CrashReporter {
  static final _log = AppLogger.getLogger('CrashReporter');

  /// Install global error handlers. Call once during app bootstrap.
  static void install(IAnalyticsService analytics) {
    // Flutter framework errors (widget build, layout, paint)
    FlutterError.onError = (details) {
      _log.error('FlutterError: {}', [details.exceptionAsString()]);
      analytics.logError(
        error: details.exception,
        stackTrace: details.stack,
        reason: 'FlutterError: ${details.library}',
      );

      // In debug mode, also print the default Flutter error output
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // Async errors, isolate errors, platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _log.error('PlatformError: {}', [error]);
      analytics.logError(error: error, stackTrace: stack, reason: 'PlatformDispatcher.onError');
      return true; // Mark as handled
    };

    _log.info('Crash reporter installed');
  }
}
