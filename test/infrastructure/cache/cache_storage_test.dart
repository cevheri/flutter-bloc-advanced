import 'package:flutter_bloc_advance/infrastructure/cache/cache_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CachePolicy', () {
    test('should have exactly four values', () {
      expect(CachePolicy.values.length, 4);
    });

    test('should contain networkFirst', () {
      expect(CachePolicy.values, contains(CachePolicy.networkFirst));
    });

    test('should contain cacheFirst', () {
      expect(CachePolicy.values, contains(CachePolicy.cacheFirst));
    });

    test('should contain networkOnly', () {
      expect(CachePolicy.values, contains(CachePolicy.networkOnly));
    });

    test('should contain cacheOnly', () {
      expect(CachePolicy.values, contains(CachePolicy.cacheOnly));
    });

    test('should have correct index ordering', () {
      expect(CachePolicy.networkFirst.index, 0);
      expect(CachePolicy.cacheFirst.index, 1);
      expect(CachePolicy.networkOnly.index, 2);
      expect(CachePolicy.cacheOnly.index, 3);
    });
  });

  group('CacheEntry', () {
    group('constructor', () {
      test('should create instance with required fields', () {
        final now = DateTime.now();
        final entry = CacheEntry(key: 'test_key', data: '{"value": "hello"}', createdAt: now);

        expect(entry.key, 'test_key');
        expect(entry.data, '{"value": "hello"}');
        expect(entry.createdAt, now);
        expect(entry.expiresAt, isNull);
      });

      test('should create instance with optional expiresAt', () {
        final now = DateTime.now();
        final expiry = now.add(const Duration(minutes: 5));
        final entry = CacheEntry(key: 'test_key', data: 'data', createdAt: now, expiresAt: expiry);

        expect(entry.expiresAt, expiry);
      });
    });

    group('isExpired', () {
      test('should return false when expiresAt is null', () {
        final entry = CacheEntry(key: 'test_key', data: 'data', createdAt: DateTime.now());

        expect(entry.isExpired, isFalse);
      });

      test('should return false when expiresAt is in the future', () {
        final entry = CacheEntry(
          key: 'test_key',
          data: 'data',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        expect(entry.isExpired, isFalse);
      });

      test('should return true when expiresAt is in the past', () {
        final entry = CacheEntry(
          key: 'test_key',
          data: 'data',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        expect(entry.isExpired, isTrue);
      });
    });

    group('isValid', () {
      test('should return true when expiresAt is null (no expiry)', () {
        final entry = CacheEntry(key: 'test_key', data: 'data', createdAt: DateTime.now());

        expect(entry.isValid, isTrue);
      });

      test('should return true when expiresAt is in the future', () {
        final entry = CacheEntry(
          key: 'test_key',
          data: 'data',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        expect(entry.isValid, isTrue);
      });

      test('should return false when expiresAt is in the past', () {
        final entry = CacheEntry(
          key: 'test_key',
          data: 'data',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        expect(entry.isValid, isFalse);
      });

      test('isValid should be the inverse of isExpired', () {
        final validEntry = CacheEntry(
          key: 'valid',
          data: 'data',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        final expiredEntry = CacheEntry(
          key: 'expired',
          data: 'data',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        final noExpiryEntry = CacheEntry(key: 'no_expiry', data: 'data', createdAt: DateTime.now());

        expect(validEntry.isValid, !validEntry.isExpired);
        expect(expiredEntry.isValid, !expiredEntry.isExpired);
        expect(noExpiryEntry.isValid, !noExpiryEntry.isExpired);
      });
    });

    group('edge cases', () {
      test('should handle empty data string', () {
        final entry = CacheEntry(key: 'empty', data: '', createdAt: DateTime.now());

        expect(entry.data, '');
        expect(entry.isValid, isTrue);
      });

      test('should handle empty key string', () {
        final entry = CacheEntry(key: '', data: 'data', createdAt: DateTime.now());

        expect(entry.key, '');
      });

      test('should handle large data payload', () {
        final largeData = 'x' * 10000;
        final entry = CacheEntry(key: 'large', data: largeData, createdAt: DateTime.now());

        expect(entry.data.length, 10000);
        expect(entry.isValid, isTrue);
      });
    });
  });

  group('ICacheStorage', () {
    test('should be an abstract class that can be implemented', () {
      // Verify that ICacheStorage defines the expected interface methods
      // by creating a mock implementation
      final storage = _TestCacheStorage();
      expect(storage, isA<ICacheStorage>());
    });
  });
}

/// Minimal concrete implementation to verify the interface contract.
class _TestCacheStorage implements ICacheStorage {
  @override
  Future<CacheEntry?> read(String key) async => null;

  @override
  Future<void> write(String key, String data, {Duration? ttl}) async {}

  @override
  Future<void> remove(String key) async {}

  @override
  Future<void> clear() async {}
}
