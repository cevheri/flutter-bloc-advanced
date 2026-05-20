import 'package:flutter_bloc_advance/app/dev_console/tabs/storage_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StorageTab.isSensitiveKey (#62)', () {
    test('flags storage keys containing "token" — including refreshToken', () {
      expect(StorageTab.isSensitiveKey('jwtToken'), isTrue);
      expect(StorageTab.isSensitiveKey('refreshToken'), isTrue);
      expect(StorageTab.isSensitiveKey('accessToken'), isTrue);
    });

    test('flags storage keys containing "secret" / "password" / "apikey"', () {
      expect(StorageTab.isSensitiveKey('clientSecret'), isTrue);
      expect(StorageTab.isSensitiveKey('userPassword'), isTrue);
      expect(StorageTab.isSensitiveKey('xApiKey'), isTrue);
      expect(StorageTab.isSensitiveKey('api_key'), isTrue);
    });

    test('match is case-insensitive', () {
      expect(StorageTab.isSensitiveKey('USER_TOKEN'), isTrue);
      expect(StorageTab.isSensitiveKey('Password'), isTrue);
    });

    test('non-sensitive keys are not flagged', () {
      expect(StorageTab.isSensitiveKey('username'), isFalse);
      expect(StorageTab.isSensitiveKey('language'), isFalse);
      expect(StorageTab.isSensitiveKey('theme'), isFalse);
      expect(StorageTab.isSensitiveKey('roles'), isFalse);
    });
  });
}
