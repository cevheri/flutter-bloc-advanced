import 'package:flutter_bloc_advance/core/analytics/analytics_service.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// [IAnalyticsService] implementation backed by the Sentry SDK.
///
/// Pre-condition: `SentryFlutter.init(...)` has already run with a
/// configured DSN. The bootstrap layer gates that on
/// `AppConfig.sentryDsn != null` and only swaps this service
/// in when the SDK is live; tests + non-prod builds keep
/// `LogAnalyticsService` so this file is not even constructed
/// without a DSN.
///
/// **PII contract.** Every outgoing event passes through
/// [sentryBeforeSend] (wired in the SDK init), which drops
/// Authorization / Cookie headers, redacts `password` / `otp` /
/// `token` / `refreshToken` body keys, and masks JWT-shaped strings
/// in exception values / message. See `sentry_scrub.dart` for the
/// pure scrubber implementation that backs this guarantee.
class SentryAnalyticsService implements IAnalyticsService {
  static final _log = AppLogger.getLogger('SentryAnalyticsService');

  @override
  void logError({required Object error, StackTrace? stackTrace, String? reason}) {
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: reason != null ? Hint.withMap({'reason': reason}) : null,
    );
  }

  @override
  void logEvent({required String name, Map<String, dynamic>? parameters}) {
    Sentry.addBreadcrumb(Breadcrumb(category: 'event', message: name, data: parameters));
  }

  @override
  void logScreenView({required String screenName, String? screenClass}) {
    Sentry.addBreadcrumb(Breadcrumb(category: 'navigation', message: screenName, data: {'screenClass': screenClass}));
  }

  @override
  void logUserAction({required String action, String? target, Map<String, dynamic>? parameters}) {
    Sentry.addBreadcrumb(Breadcrumb(category: 'ui.action', message: action, data: {'target': target, ...?parameters}));
  }

  @override
  void setUserId(String? userId) {
    Sentry.configureScope((scope) {
      if (userId == null) {
        scope.setUser(null);
      } else {
        scope.setUser(SentryUser(id: userId));
      }
    });
    _log.debug('setUserId: {}', [userId]);
  }

  @override
  void setUserProperty({required String name, required String? value}) {
    Sentry.configureScope((scope) {
      if (value == null) {
        scope.removeTag(name);
      } else {
        scope.setTag(name, value);
      }
    });
  }
}
