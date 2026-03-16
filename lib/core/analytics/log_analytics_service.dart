import 'package:flutter_bloc_advance/core/analytics/analytics_service.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';

/// Default analytics implementation that logs events via [AppLogger].
///
/// Requires no external SDK — works out of the box for development and
/// as a reference for production providers.
class LogAnalyticsService implements IAnalyticsService {
  static final _log = AppLogger.getLogger('Analytics');

  @override
  void logScreenView({required String screenName, String? screenClass}) {
    _log.info('screen_view: {} (class: {})', [screenName, screenClass ?? '-']);
  }

  @override
  void logEvent({required String name, Map<String, dynamic>? parameters}) {
    _log.info('event: {} params: {}', [name, parameters ?? {}]);
  }

  @override
  void logUserAction({required String action, String? target, Map<String, dynamic>? parameters}) {
    _log.info('user_action: {} target: {} params: {}', [action, target ?? '-', parameters ?? {}]);
  }

  @override
  void setUserId(String? userId) {
    _log.info('set_user_id: {}', [userId ?? 'null']);
  }

  @override
  void setUserProperty({required String name, required String? value}) {
    _log.info('set_user_property: {} = {}', [name, value ?? 'null']);
  }

  @override
  void logError({required Object error, StackTrace? stackTrace, String? reason}) {
    _log.error('non_fatal_error: {} reason: {}', [error, reason ?? '-']);
    if (stackTrace != null) {
      _log.error('stack_trace: {}', [stackTrace.toString().split('\n').take(5).join('\n')]);
    }
  }
}
