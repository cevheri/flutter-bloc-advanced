import 'package:flutter_bloc_advance/core/analytics/analytics_service.dart';
import 'package:flutter_bloc_advance/core/analytics/log_analytics_service.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LogAnalyticsService service;

  setUpAll(() {
    AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
  });

  setUp(() {
    service = LogAnalyticsService();
  });

  group('LogAnalyticsService', () {
    test('implements IAnalyticsService', () {
      expect(service, isA<IAnalyticsService>());
    });

    group('logScreenView', () {
      test('does not throw with screenName only', () {
        expect(() => service.logScreenView(screenName: 'HomeScreen'), returnsNormally);
      });

      test('does not throw with screenName and screenClass', () {
        expect(() => service.logScreenView(screenName: 'HomeScreen', screenClass: 'HomePage'), returnsNormally);
      });

      test('does not throw with empty screenName', () {
        expect(() => service.logScreenView(screenName: ''), returnsNormally);
      });
    });

    group('logEvent', () {
      test('does not throw with name only', () {
        expect(() => service.logEvent(name: 'button_click'), returnsNormally);
      });

      test('does not throw with name and parameters', () {
        expect(
          () => service.logEvent(name: 'button_click', parameters: {'button_id': 'submit', 'count': 1}),
          returnsNormally,
        );
      });

      test('does not throw with null parameters', () {
        expect(() => service.logEvent(name: 'event', parameters: null), returnsNormally);
      });

      test('does not throw with empty parameters', () {
        expect(() => service.logEvent(name: 'event', parameters: {}), returnsNormally);
      });
    });

    group('logUserAction', () {
      test('does not throw with action only', () {
        expect(() => service.logUserAction(action: 'tap'), returnsNormally);
      });

      test('does not throw with action and target', () {
        expect(() => service.logUserAction(action: 'tap', target: 'login_button'), returnsNormally);
      });

      test('does not throw with all parameters', () {
        expect(
          () => service.logUserAction(action: 'tap', target: 'login_button', parameters: {'page': 'login'}),
          returnsNormally,
        );
      });

      test('does not throw with null target and null parameters', () {
        expect(() => service.logUserAction(action: 'tap', target: null, parameters: null), returnsNormally);
      });
    });

    group('setUserId', () {
      test('does not throw with a valid userId', () {
        expect(() => service.setUserId('user-123'), returnsNormally);
      });

      test('does not throw with null userId', () {
        expect(() => service.setUserId(null), returnsNormally);
      });

      test('does not throw with empty userId', () {
        expect(() => service.setUserId(''), returnsNormally);
      });
    });

    group('setUserProperty', () {
      test('does not throw with name and value', () {
        expect(() => service.setUserProperty(name: 'role', value: 'admin'), returnsNormally);
      });

      test('does not throw with null value', () {
        expect(() => service.setUserProperty(name: 'role', value: null), returnsNormally);
      });

      test('does not throw with empty name', () {
        expect(() => service.setUserProperty(name: '', value: 'admin'), returnsNormally);
      });
    });

    group('logError', () {
      test('does not throw with error only', () {
        expect(() => service.logError(error: Exception('test error')), returnsNormally);
      });

      test('does not throw with error and reason', () {
        expect(() => service.logError(error: Exception('test error'), reason: 'network failure'), returnsNormally);
      });

      test('does not throw with error and stackTrace', () {
        final stackTrace = StackTrace.current;
        expect(() => service.logError(error: Exception('test error'), stackTrace: stackTrace), returnsNormally);
      });

      test('does not throw with all parameters', () {
        final stackTrace = StackTrace.current;
        expect(
          () => service.logError(error: Exception('test error'), stackTrace: stackTrace, reason: 'network failure'),
          returnsNormally,
        );
      });

      test('does not throw with string error', () {
        expect(() => service.logError(error: 'simple string error'), returnsNormally);
      });

      test('does not throw with null stackTrace and null reason', () {
        expect(() => service.logError(error: 'error', stackTrace: null, reason: null), returnsNormally);
      });
    });
  });
}
