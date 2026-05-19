import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppErrorCode', () {
    test('every enum value carries a non-empty namespaced key', () {
      for (final code in AppErrorCode.values) {
        expect(code.key, isNotEmpty);
        expect(code.key.contains('.'), isTrue, reason: '${code.name} key "${code.key}" must be namespaced');
      }
    });

    test('keys are unique', () {
      final keys = AppErrorCode.values.map((c) => c.key).toList();
      expect(keys.toSet().length, keys.length);
    });

    test('fromKey resolves known keys', () {
      expect(AppErrorCode.fromKey('auth.login_failed'), AppErrorCode.authLoginFailed);
      expect(AppErrorCode.fromKey('user.cannot_delete_admin'), AppErrorCode.userCannotDeleteAdmin);
    });

    test('fromKey returns null for unknown or null input', () {
      expect(AppErrorCode.fromKey(null), isNull);
      expect(AppErrorCode.fromKey('does.not.exist'), isNull);
    });
  });
}
