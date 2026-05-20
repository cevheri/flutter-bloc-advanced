import 'package:flutter_bloc_advance/core/logging/log_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogSanitizer.maskToken', () {
    test('returns <empty> for null', () {
      expect(LogSanitizer.maskToken(null), '<empty>');
    });

    test('returns <empty> for empty string', () {
      expect(LogSanitizer.maskToken(''), '<empty>');
    });

    test('returns <redacted> for tokens shorter than 8 chars', () {
      expect(LogSanitizer.maskToken('a'), '<redacted>');
      expect(LogSanitizer.maskToken('1234567'), '<redacted>');
    });

    test('masks the middle of an 8-char token', () {
      expect(LogSanitizer.maskToken('12345678'), '1234…5678');
    });

    test('masks a realistic JWT', () {
      const jwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.signature';
      final masked = LogSanitizer.maskToken(jwt);
      expect(masked, startsWith('eyJh'));
      expect(masked, endsWith('ture'));
      expect(masked.contains('payload'), isFalse);
      expect(masked.contains('signature'), isFalse);
    });
  });
}
