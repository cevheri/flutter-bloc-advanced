import 'package:flutter_bloc_advance/core/security/safe_redirect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('safeReturnPath', () {
    String? check(String? candidate) => safeReturnPath(candidate, loginPath: '/login');

    test('keeps a local path with a query and a fragment', () {
      expect(check('/user?tab=2#x'), '/user?tab=2#x');
    });

    test('drops what safeRedirectTarget drops', () {
      expect(check(null), isNull);
      expect(check(''), isNull);
      expect(check('user'), isNull);
      expect(check('//evil.example'), isNull);
      expect(check(r'/\evil'), isNull);
      expect(check('https://evil.example/x'), isNull);
    });

    test('drops a path with a control character', () {
      expect(check('/a\u0007b'), isNull);
      expect(check('/a\u0000b'), isNull);
      expect(check('/a\u001fb'), isNull);
      expect(check('/a\u007fb'), isNull);
      expect(check('/a\nb'), isNull);
    });

    test('drops the login route and anything under it', () {
      expect(check('/login'), isNull);
      expect(check('/login/x'), isNull);
      expect(check('/login?returnUrl=%2Fuser'), isNull);
      expect(check('/login#x'), isNull);
    });

    test('keeps a path that only starts with the login route name', () {
      expect(check('/login-help'), '/login-help');
    });

    test('keeps a path of exactly 1024 bytes and drops one of 1025', () {
      final exact = '/${'a' * 1023}';
      expect(check(exact), exact);
      expect(check('/${'a' * 1024}'), isNull);
    });

    // The cap is in UTF-8 bytes, not characters: `ğ` is two bytes.
    test('counts UTF-8 bytes, not characters', () {
      // 514 characters, 1027 bytes.
      expect(check('/${'ğ' * 513}'), isNull);
      // 401 characters, 801 bytes, so under the cap.
      final short = '/${'ğ' * 400}';
      expect(check(short), short);
    });
  });
}
