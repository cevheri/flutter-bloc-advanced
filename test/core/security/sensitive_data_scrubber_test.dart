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

  group('maskSecrets', () {
    test('masks the value of a credential member of JSON, a string or a number', () {
      expect(
        maskSecrets('body: {"login":"admin","newPassword" : "p\\"ss","otp":493817,"remember":true}'),
        'body: {"login":"admin","newPassword" : "[REDACTED]","otp":[REDACTED],"remember":true}',
      );
    });

    test('masks the value of a credential name=value pair', () {
      expect(
        maskSecrets('GET /cb?state=x&access_token=at-0a1b&code=7 refresh_token=rt-9f8e'),
        'GET /cb?state=[REDACTED]&access_token=[REDACTED]&code=[REDACTED] refresh_token=[REDACTED]',
      );
    });

    test('masks the credentials of a Bearer authorization and every JWT', () {
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhYmMifQ.signaturepart';

      expect(
        maskSecrets('Authorization: bearer at-0a1b2c3d, saw $jwt'),
        'Authorization: bearer [REDACTED], saw [REDACTED_JWT]',
      );
    });

    test('keeps a value that is already masked', () {
      const masked = 'access_token=[REDACTED_JWT] {"id_token":"[REDACTED_JWT]"} Bearer [REDACTED_JWT]';

      expect(maskSecrets(masked), masked);
    });

    test('keeps text without a credential in a known shape as it is', () {
      const text = 'token: eyJh…VyZQ, password changed, GET /users?page=0&size=20 {"count":2}';

      expect(maskSecrets(text), text);
    });

    // AppLogger runs every printed line through this, and an error line can carry a whole HTTP error body.
    test('masks a credential after a long run of characters without a slow scan', () {
      final input = '${'"a1":' * 20000} "password":"x"';

      expect(maskSecrets(input), '${'"a1":' * 20000} "password":"[REDACTED]"');
    });
  });

  group('maskEmails', () {
    test('masks an email in a route path', () {
      expect(maskEmails('/login-otp-verify/jane.doe@example.com'), '/login-otp-verify/[REDACTED_EMAIL]');
    });

    test('masks an email whose @ is percent-encoded', () {
      expect(maskEmails('email=jane.doe%40example.com&next=%2Fhome'), 'email=[REDACTED_EMAIL]&next=%2Fhome');
    });

    test('masks percent-encoded characters in the local part', () {
      expect(maskEmails('email=jane%2Btag%40example.com'), 'email=[REDACTED_EMAIL]');
    });

    test('masks every email when several appear', () {
      expect(maskEmails('to=a@example.com, cc=b@example.org'), 'to=[REDACTED_EMAIL], cc=[REDACTED_EMAIL]');
    });

    test('leaves content without an email untouched', () {
      const input = 'https://app.example/login-otp-verify?step=2#top';
      expect(maskEmails(input), input);
    });

    // AppLogger runs every printed line through maskEmails, and an error line can carry a whole HTTP error body. An
    // unbounded local part made the scan quadratic in a long run of local-part characters, so this line took minutes.
    test('masks an email after a long run of local-part characters without a slow scan', () {
      final input = '${'a1' * 50000} jane.doe@example.com';

      expect(maskEmails(input), '${'a1' * 50000} [REDACTED_EMAIL]');
    });

    test('masks the last 64 characters of a longer local part, the RFC 5321 limit', () {
      final local = 'x' * 70;

      expect(maskEmails('$local@example.com'), '${'x' * 6}[REDACTED_EMAIL]');
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

  group('maskHeaders', () {
    test('masks Authorization / Cookie / Set-Cookie case-insensitively and keeps the header', () {
      final result = maskHeaders({
        'Authorization': 'Bearer token',
        'cookie': 'sid=abc',
        'Set-Cookie': 'sid=abc',
        'Accept': 'application/json',
      });
      expect(result, {
        'Authorization': '[REDACTED]',
        'cookie': '[REDACTED]',
        'Set-Cookie': '[REDACTED]',
        'Accept': 'application/json',
      });
    });
  });

  group('scrubBodyText', () {
    test('masks the credentials of a JSON string', () {
      expect(
        scrubBodyText('{\n  "id_token": "a.b.c",\n  "refresh_token": "opaque"\n}'),
        '{"id_token":"[REDACTED]","refresh_token":"[REDACTED]"}',
      );
    });

    test('keeps a JSON string without a credential as it is, formatting included', () {
      const body = '{\n  "login": "admin",\n  "authorities": ["ROLE_ADMIN"]\n}';

      expect(scrubBodyText(body), body);
    });

    test('masks the credentials of a Map body and prints it as a Map', () {
      expect(scrubBodyText({'username': 'admin', 'password': 'S3cret!pw'}), '{username: admin, password: [REDACTED]}');
    });

    // A server-driven form chooses the keys of its fields, so the key of a password field may name no credential.
    test('masks the values of the sensitive keys the caller names, compared whole and lower-cased', () {
      expect(
        scrubBodyText({'login': 'admin', 'pin': 'S3cret!pw', 'pinned': true}, sensitiveKeys: {'PIN'}),
        '{login: admin, pin: [REDACTED], pinned: true}',
      );
      expect(scrubBodyText('{"pin":"S3cret!pw"}', sensitiveKeys: {'pin'}), '{"pin":"[REDACTED]"}');
    });
  });

  group('scrubBodyKeys', () {
    test('masks the values of password / otp / token / refreshToken / secret keys (case-insensitive substring)', () {
      final result = scrubBodyKeys({
        'username': 'alice',
        'password': 'p@ss',
        'OTP': 123456,
        'accessToken': 'xxx',
        'refreshToken': 'yyy',
        'clientSecret': 'zzz',
        'note': 'kept',
      });
      expect(result, {
        'username': 'alice',
        'password': '[REDACTED]',
        'OTP': '[REDACTED]',
        'accessToken': '[REDACTED]',
        'refreshToken': '[REDACTED]',
        'clientSecret': '[REDACTED]',
        'note': 'kept',
      });
    });

    // Regression: only top-level keys were read, so a credential nested in an object or a list was kept.
    test('masks a credential at any depth and keeps a null one as null', () {
      final result = scrubBodyKeys({
        'user': {'login': 'alice', 'newPassword': 'p@ss'},
        'sessions': [
          {'id': 1, 'refresh_token': 'yyy'},
        ],
        'tokens': {'access': 'xxx'},
        'currentPassword': null,
      });
      expect(result, {
        'user': {'login': 'alice', 'newPassword': '[REDACTED]'},
        'sessions': [
          {'id': 1, 'refresh_token': '[REDACTED]'},
        ],
        'tokens': '[REDACTED]',
        'currentPassword': null,
      });
    });

    test('non-Map body is returned untouched', () {
      expect(scrubBodyKeys('plain string'), 'plain string');
      expect(scrubBodyKeys(null), isNull);
    });
  });

  group('scrubErrorBody', () {
    test('masks the value a validation error repeats, under rejectedValue, input or value', () {
      const body =
          '{"errors":[{"field":"email","rejectedValue":"x@y"},{"loc":["body","pin"],"input":"1234"},'
          '{"path":"code","value":"9876"}]}';

      expect(
        scrubErrorBody(body),
        '{"errors":[{"field":"email","rejectedValue":"[REDACTED]"},{"loc":["body","pin"],"input":"[REDACTED]"},'
        '{"path":"code","value":"[REDACTED]"}]}',
      );
    });

    test('masks a credential the request sent wherever the body repeats it', () {
      final text = scrubErrorBody(
        '{"status":401,"detail":"OTP 493817 expired","hint":{"lastCode":493817}}',
        requestBody: {'email': 'a@b.c', 'otp': '493817'},
      );

      expect(text, '{"status":401,"detail":"OTP [REDACTED] expired","hint":{"lastCode":"[REDACTED]"}}');
    });

    test('masks a credential of the request in a body that is not JSON', () {
      expect(
        scrubErrorBody('Password S3cret!pw is too weak', requestBody: '{"username":"admin","password":"S3cret!pw"}'),
        'Password [REDACTED] is too weak',
      );
    });

    test('masks a value of the request under a sensitive key the caller names wherever the body repeats it', () {
      expect(
        scrubErrorBody(
          '{"detail":"PIN S3cret!pw was used before","pin":"S3cret!pw"}',
          requestBody: {'login': 'admin', 'pin': 'S3cret!pw'},
          sensitiveKeys: {'pin'},
        ),
        '{"detail":"PIN [REDACTED] was used before","pin":"[REDACTED]"}',
      );
    });

    test('masks a JWT in the body', () {
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhYmMifQ.signaturepart';

      expect(scrubErrorBody('token $jwt was revoked'), 'token [REDACTED_JWT] was revoked');
    });

    test('keeps a body without a credential as it is', () {
      const body = '{"status": 404, "path": "/api/admin/users/alice", "value_count": 2}';

      expect(scrubErrorBody(body, requestBody: {'login': 'alice'}), body);
      expect(scrubErrorBody(null), '');
    });
  });

  group('exact OIDC keys', () {
    test('masks the code, state and session_state of a redirect query and keeps the other pairs', () {
      final text = maskSecrets('redirect?code=abc123XYZ&state=st4te999&session_state=ss1&iss=x');

      expect(text, isNot(contains('abc123XYZ')));
      expect(text, isNot(contains('st4te999')));
      expect(text, isNot(contains('ss1')));
      expect(text, contains('iss=x'));
    });

    test('masks the code, state, nonce and code_verifier members of JSON', () {
      final text = maskSecrets('{"code":"abc123XYZ","state":"st4te999","nonce":"n0nce","code_verifier":"v3rif"}');

      for (final value in ['abc123XYZ', 'st4te999', 'n0nce', 'v3rif']) {
        expect(text, isNot(contains(value)));
      }
    });

    test('masks a key that matches whole, in any case, and keeps a key that only contains one', () {
      final result = scrubBodyKeys({
        'code': 'c1',
        'State': 's1',
        'nonce': 'n1',
        'statusCode': 401,
        'countryCode': 'TR',
        'stateName': 'x',
        'errorCode': 'E1',
      });

      expect(result, {
        'code': '[REDACTED]',
        'State': '[REDACTED]',
        'nonce': '[REDACTED]',
        'statusCode': 401,
        'countryCode': 'TR',
        'stateName': 'x',
        'errorCode': 'E1',
      });
    });
  });
}
