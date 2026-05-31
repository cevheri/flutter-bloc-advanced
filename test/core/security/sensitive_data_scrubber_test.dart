import 'package:flutter_bloc_advance/core/security/sensitive_data_scrubber.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('maskJwts', () {
    const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhYmMifQ.signaturepart';

    test('masks a JWT-shaped token embedded in a string', () {
      final result = maskJwts('Authorization failed for token=$jwt end');
      expect(result.contains(jwt), isFalse);
      expect(result.contains('[REDACTED_JWT]'), isTrue);
    });

    test('leaves non-JWT content untouched', () {
      const input = 'Server returned 500 with body {"error":"oops"}';
      expect(maskJwts(input), input);
    });

    test('masks every JWT when several appear', () {
      final result = maskJwts('a=$jwt b=$jwt');
      expect(result.contains(jwt), isFalse);
      expect('[REDACTED_JWT]'.allMatches(result).length, 2);
    });
  });

  group('scrubHeaders', () {
    test('drops Authorization / Cookie / Set-Cookie case-insensitively', () {
      final result = scrubHeaders({
        'Authorization': 'Bearer token',
        'cookie': 'sid=abc',
        'Set-Cookie': 'sid=abc',
        'Accept': 'application/json',
      });
      expect(result.containsKey('Authorization'), isFalse);
      expect(result.containsKey('cookie'), isFalse);
      expect(result.containsKey('Set-Cookie'), isFalse);
      expect(result['Accept'], 'application/json');
    });

    test('keeps all non-sensitive headers', () {
      final result = scrubHeaders({'Accept': 'application/json', 'X-Trace': 'abc'});
      expect(result.length, 2);
    });
  });

  group('scrubBodyKeys', () {
    test('drops password / otp / token / refreshToken keys (case-insensitive substring)', () {
      final result = scrubBodyKeys({
        'username': 'alice',
        'password': 'p@ss',
        'OTP': '123456',
        'accessToken': 'xxx',
        'refreshToken': 'yyy',
        'note': 'kept',
      });
      final data = Map<String, dynamic>.from(result! as Map);
      expect(data.containsKey('password'), isFalse);
      expect(data.containsKey('OTP'), isFalse);
      expect(data.containsKey('accessToken'), isFalse);
      expect(data.containsKey('refreshToken'), isFalse);
      expect(data['username'], 'alice');
      expect(data['note'], 'kept');
    });

    test('non-Map body is returned untouched', () {
      expect(scrubBodyKeys('plain string'), 'plain string');
      expect(scrubBodyKeys(null), isNull);
    });
  });
}
