import 'dart:convert';

import 'package:flutter_bloc_advance/core/security/security_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecurityUtils', () {
    group('hasToken', () {
      test('returns false for null', () {
        expect(SecurityUtils.hasToken(null), isFalse);
      });

      test('returns false for empty', () {
        expect(SecurityUtils.hasToken(''), isFalse);
      });

      test('returns true for non-empty', () {
        expect(SecurityUtils.hasToken('MOCK_TOKEN'), isTrue);
      });
    });

    group('isCurrentUserAdmin', () {
      test('returns false when roles is null', () {
        expect(SecurityUtils.isCurrentUserAdmin(null), isFalse);
      });

      test('returns true when roles contains ROLE_ADMIN', () {
        expect(SecurityUtils.isCurrentUserAdmin(['ROLE_ADMIN']), isTrue);
      });

      test('returns false when roles lacks ROLE_ADMIN', () {
        expect(SecurityUtils.isCurrentUserAdmin(['ROLE_USER']), isFalse);
      });
    });

    group('isTokenExpired', () {
      test('returns true for null', () {
        expect(SecurityUtils.isTokenExpired(null), isTrue);
      });

      test('returns true for empty', () {
        expect(SecurityUtils.isTokenExpired(''), isTrue);
      });

      test('returns true for malformed token (wrong segment count)', () {
        expect(SecurityUtils.isTokenExpired('invalid.token'), isTrue);
      });

      test('returns true for invalid base64 payload', () {
        expect(SecurityUtils.isTokenExpired('header.invalid_payload.signature'), isTrue);
      });

      test('returns true when exp claim is missing', () {
        final payload = base64Url.encode('{"sub":"test"}'.codeUnits);
        expect(SecurityUtils.isTokenExpired('header.$payload.signature'), isTrue);
      });

      test('returns true when exp is in the past', () {
        final past = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
        final payload = base64Url.encode('{"exp":$past}'.codeUnits);
        expect(SecurityUtils.isTokenExpired('header.$payload.signature'), isTrue);
      });

      test('returns false when exp is in the future', () {
        final future = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
        final payload = base64Url.encode('{"exp":$future}'.codeUnits);
        expect(SecurityUtils.isTokenExpired('header.$payload.signature'), isFalse);
      });
    });

    group('getTokenExpiration', () {
      test('returns null for invalid token', () {
        expect(SecurityUtils.getTokenExpiration('invalid'), isNull);
      });

      test('returns null for token without exp claim', () {
        final payload = base64Url.encode('{"sub":"test"}'.codeUnits);
        expect(SecurityUtils.getTokenExpiration('header.$payload.signature'), isNull);
      });

      test('returns DateTime for valid token', () {
        final future = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
        final payload = base64Url.encode('{"exp":$future}'.codeUnits);
        final result = SecurityUtils.getTokenExpiration('header.$payload.signature');
        expect(result, isNotNull);
        expect(result!.millisecondsSinceEpoch ~/ 1000, future);
      });
    });
  });
}
