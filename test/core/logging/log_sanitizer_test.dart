import 'package:flutter_bloc_advance/core/logging/log_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('maskToken', () {
    test('returns <empty> for null', () {
      expect(maskToken(null), '<empty>');
    });

    test('returns <empty> for empty string', () {
      expect(maskToken(''), '<empty>');
    });

    test('returns <redacted> for tokens shorter than 8 chars', () {
      expect(maskToken('a'), '<redacted>');
      expect(maskToken('1234567'), '<redacted>');
    });

    test('masks the middle of an 8-char token', () {
      expect(maskToken('12345678'), '1234…5678');
    });

    test('masks a realistic JWT', () {
      const jwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.signature';
      final masked = maskToken(jwt);
      expect(masked, startsWith('eyJh'));
      expect(masked, endsWith('ture'));
      expect(masked.contains('payload'), isFalse);
      expect(masked.contains('signature'), isFalse);
    });
  });
}
