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
  ///
  /// [forwardToAnalytics] controls whether uncaught errors are forwarded to
  /// [analytics]. Set it to `false` when the Sentry SDK is active: Sentry
  /// installs its own `FlutterError.onError` / `PlatformDispatcher.onError`
  /// integrations that both capture the error AND chain to the handler
  /// installed here. Forwarding to the Sentry-backed analytics in that case
  /// reports every crash twice. With forwarding off, this reporter keeps doing
  /// local logging and Sentry remains the single uncaught-error sink.
  static void install(IAnalyticsService analytics, {bool forwardToAnalytics = true}) {
    // Flutter framework errors (widget build, layout, paint)
    FlutterError.onError = (details) {
      _log.error('FlutterError: {}', [details.exceptionAsString()]);
      if (forwardToAnalytics) {
        analytics.logError(
          error: details.exception,
          stackTrace: details.stack,
          reason: 'FlutterError: ${details.library}',
        );
      }

      // In debug mode, also print the default Flutter error output
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // Async errors, isolate errors, platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _log.error('PlatformError: {}', [error]);
      if (forwardToAnalytics) {
        analytics.logError(error: error, stackTrace: stack, reason: 'PlatformDispatcher.onError');
      }
      return true; // Mark as handled
    };

    _log.info('Crash reporter installed (forwardToAnalytics={})', [forwardToAnalytics]);
  }
}
