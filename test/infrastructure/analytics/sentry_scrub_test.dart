import 'package:flutter_bloc_advance/infrastructure/analytics/sentry_scrub.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

SentryEvent _eventWithHeaders(Map<String, String> headers) => SentryEvent(request: SentryRequest(headers: headers));

SentryEvent _eventWithBody(Object? body) => SentryEvent(request: SentryRequest(data: body));

SentryEvent _eventWithMessage(String message) => SentryEvent(message: SentryMessage(message));

SentryEvent _eventWithExceptionValue(String value) {
  return SentryEvent(
    exceptions: [SentryException(type: 'TestException', value: value)],
  );
}

void main() {
  group('sentryBeforeSend — header scrubbing', () {
    test('removes Authorization header (case-insensitive)', () {
      final result = sentryBeforeSend(
        _eventWithHeaders({'Authorization': 'Bearer token', 'Accept': 'application/json'}),
      );
      expect(result.request?.headers.containsKey('Authorization'), isFalse);
      expect(result.request?.headers['Accept'], 'application/json');
    });

    test('removes lowercase authorization', () {
      final result = sentryBeforeSend(_eventWithHeaders({'authorization': 'Bearer x', 'X-Other': 'y'}));
      expect(result.request?.headers.containsKey('authorization'), isFalse);
      expect(result.request?.headers['X-Other'], 'y');
    });

    test('removes Cookie and Set-Cookie headers', () {
      final result = sentryBeforeSend(_eventWithHeaders({'Cookie': 'sid=abc', 'Set-Cookie': 'sid=abc', 'X-K': 'v'}));
      expect(result.request?.headers.containsKey('Cookie'), isFalse);
      expect(result.request?.headers.containsKey('Set-Cookie'), isFalse);
      expect(result.request?.headers['X-K'], 'v');
    });
  });

  group('sentryBeforeSend — body scrubbing (Map shape)', () {
    test('drops password, otp, token, refreshToken keys', () {
      final body = {
        'username': 'alice',
        'password': 'p@ss',
        'otp': '123456',
        'token': 'xxx',
        'refreshToken': 'yyy',
        'note': 'kept',
      };
      final result = sentryBeforeSend(_eventWithBody(body));
      final data = Map<String, dynamic>.from(result.request!.data as Map);
      expect(data.containsKey('password'), isFalse);
      expect(data.containsKey('otp'), isFalse);
      expect(data.containsKey('token'), isFalse);
      expect(data.containsKey('refreshToken'), isFalse);
      expect(data['username'], 'alice');
      expect(data['note'], 'kept');
    });

    test('key match is case-insensitive', () {
      final body = {'Password': 'a', 'OTP': 'b', 'newPassword': 'c'};
      final result = sentryBeforeSend(_eventWithBody(body));
      final data = Map<String, dynamic>.from(result.request!.data as Map);
      expect(data.containsKey('Password'), isFalse);
      expect(data.containsKey('OTP'), isFalse);
      expect(data.containsKey('newPassword'), isFalse);
    });

    test('non-Map body is left untouched', () {
      final result = sentryBeforeSend(_eventWithBody('plain string body'));
      expect(result.request?.data, 'plain string body');
    });
  });

  group('sentryBeforeSend — JWT masking', () {
    const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhYmMifQ.signaturepart';

    test('masks a JWT-shaped token inside an exception value', () {
      final result = sentryBeforeSend(_eventWithExceptionValue('Failed with token=$jwt — try again'));
      final value = result.exceptions?.first.value ?? '';
      expect(value.contains(jwt), isFalse, reason: 'raw JWT must not appear');
      expect(value.contains('[REDACTED_JWT]'), isTrue);
    });

    test('masks JWT in event.message', () {
      final result = sentryBeforeSend(_eventWithMessage('Token rotated: $jwt'));
      final formatted = result.message?.formatted ?? '';
      expect(formatted.contains(jwt), isFalse);
      expect(formatted.contains('[REDACTED_JWT]'), isTrue);
    });

    test('leaves non-JWT content untouched', () {
      final result = sentryBeforeSend(_eventWithExceptionValue('Server returned 500 with body {"error":"oops"}'));
      expect(result.exceptions?.first.value, 'Server returned 500 with body {"error":"oops"}');
    });
  });

  group('sentryBeforeSend — passthroughs', () {
    test('event with no request or exception passes through unchanged', () {
      final event = SentryEvent(message: SentryMessage('Plain note'));
      final result = sentryBeforeSend(event);
      expect(result.message?.formatted, 'Plain note');
    });
  });
}
