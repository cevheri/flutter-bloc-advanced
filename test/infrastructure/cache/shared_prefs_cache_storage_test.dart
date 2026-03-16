import 'dart:convert';

import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/shared_prefs_cache_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SharedPrefsCacheStorage storage;

  setUpAll(() {
    AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
  });

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    storage = SharedPrefsCacheStorage();
  });

  group('SharedPrefsCacheStorage', () {
    group('write()', () {
      test('should write data without TTL', () async {
        await storage.write('test_key', '{"value": "hello"}');

        final entry = await storage.read('test_key');
        expect(entry, isNotNull);
        expect(entry!.data, '{"value": "hello"}');
        expect(entry.key, 'test_key');
        expect(entry.expiresAt, isNull);
      });

      test('should write data with TTL', () async {
        await storage.write('ttl_key', 'data_with_ttl', ttl: const Duration(minutes: 10));

        final entry = await storage.read('ttl_key');
        expect(entry, isNotNull);
        expect(entry!.data, 'data_with_ttl');
        expect(entry.expiresAt, isNotNull);
      });

      test('should overwrite existing entry with same key', () async {
        await storage.write('overwrite_key', 'original_data');
        await storage.write('overwrite_key', 'updated_data');

        final entry = await storage.read('overwrite_key');
        expect(entry, isNotNull);
        expect(entry!.data, 'updated_data');
      });

      test('should store createdAt timestamp', () async {
        final before = DateTime.now();
        await storage.write('time_key', 'data');
        final after = DateTime.now();

        final entry = await storage.read('time_key');
        expect(entry, isNotNull);
        expect(entry!.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(entry.createdAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });
    });

    group('read()', () {
      test('should return null for non-existent key', () async {
        final entry = await storage.read('non_existent_key');
        expect(entry, isNull);
      });

      test('should return valid entry for existing key', () async {
        await storage.write('existing_key', 'existing_data');

        final entry = await storage.read('existing_key');
        expect(entry, isNotNull);
        expect(entry!.key, 'existing_key');
        expect(entry.data, 'existing_data');
      });

      test('should return null for expired entry and auto-clean it', () async {
        // Manually write an expired entry using the internal prefix
        final prefs = await SharedPreferences.getInstance();
        final json = {
          'data': 'expired_data',
          'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'expiresAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        };
        await prefs.setString('_cache_expired_key', jsonEncode(json));

        final entry = await storage.read('expired_key');
        expect(entry, isNull);

        // Verify the expired entry was removed (auto-clean)
        final rawValue = prefs.getString('_cache_expired_key');
        expect(rawValue, isNull);
      });

      test('should return valid entry that has not expired', () async {
        await storage.write('valid_ttl_key', 'valid_data', ttl: const Duration(hours: 1));

        final entry = await storage.read('valid_ttl_key');
        expect(entry, isNotNull);
        expect(entry!.data, 'valid_data');
        expect(entry.isValid, isTrue);
      });

      test('should handle corrupted cache data gracefully', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('_cache_corrupted_key', 'not-valid-json');

        final entry = await storage.read('corrupted_key');
        expect(entry, isNull);
      });

      test('should handle entry without expiresAt field', () async {
        final prefs = await SharedPreferences.getInstance();
        final json = {'data': 'no_expiry_data', 'createdAt': DateTime.now().toIso8601String()};
        await prefs.setString('_cache_no_expiry', jsonEncode(json));

        final entry = await storage.read('no_expiry');
        expect(entry, isNotNull);
        expect(entry!.data, 'no_expiry_data');
        expect(entry.expiresAt, isNull);
        expect(entry.isValid, isTrue);
      });
    });

    group('remove()', () {
      test('should remove existing entry', () async {
        await storage.write('remove_key', 'data_to_remove');

        await storage.remove('remove_key');

        final entry = await storage.read('remove_key');
        expect(entry, isNull);
      });

      test('should not throw when removing non-existent key', () async {
        await expectLater(storage.remove('non_existent_key'), completes);
      });
    });

    group('clear()', () {
      test('should remove all cache entries', () async {
        await storage.write('key1', 'data1');
        await storage.write('key2', 'data2');
        await storage.write('key3', 'data3');

        await storage.clear();

        expect(await storage.read('key1'), isNull);
        expect(await storage.read('key2'), isNull);
        expect(await storage.read('key3'), isNull);
      });

      test('should not remove non-cache SharedPreferences keys', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('non_cache_key', 'should_survive');

        await storage.write('cache_key', 'cache_data');
        await storage.clear();

        expect(prefs.getString('non_cache_key'), 'should_survive');
      });

      test('should complete without error when cache is already empty', () async {
        await expectLater(storage.clear(), completes);
      });
    });

    group('TTL expiry', () {
      test('should return entry when TTL has not expired', () async {
        await storage.write('ttl_valid', 'valid_data', ttl: const Duration(hours: 1));

        final entry = await storage.read('ttl_valid');
        expect(entry, isNotNull);
        expect(entry!.isValid, isTrue);
        expect(entry.isExpired, isFalse);
      });

      test('should return null when TTL has expired', () async {
        // Directly insert an entry that is already expired
        final prefs = await SharedPreferences.getInstance();
        final json = {
          'data': 'old_data',
          'createdAt': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
          'expiresAt': DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
        };
        await prefs.setString('_cache_ttl_expired', jsonEncode(json));

        final entry = await storage.read('ttl_expired');
        expect(entry, isNull);
      });

      test('should return entry when no TTL is set (never expires)', () async {
        await storage.write('no_ttl', 'forever_data');

        final entry = await storage.read('no_ttl');
        expect(entry, isNotNull);
        expect(entry!.expiresAt, isNull);
        expect(entry.isValid, isTrue);
      });
    });

    group('key prefixing', () {
      test('should use _cache_ prefix for stored keys', () async {
        await storage.write('my_key', 'my_data');

        final prefs = await SharedPreferences.getInstance();
        final rawValue = prefs.getString('_cache_my_key');
        expect(rawValue, isNotNull);

        final decoded = jsonDecode(rawValue!) as Map<String, dynamic>;
        expect(decoded['data'], 'my_data');
      });

      test('should not find keys without the prefix', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('my_key', 'raw_data');

        final entry = await storage.read('my_key');
        // This should be null because the key lacks the _cache_ prefix
        // when read constructs the prefixed key it looks for _cache_my_key
        expect(entry, isNull);
      });
    });

    group('count()', () {
      test('should return 0 when empty', () async {
        final result = await storage.count();
        expect(result, 0);
      });

      test('should return correct count after writes', () async {
        await storage.write('key1', 'data1');
        await storage.write('key2', 'data2');
        await storage.write('key3', 'data3');

        final result = await storage.count();
        expect(result, 3);
      });

      test('should return 0 after clear', () async {
        await storage.write('key1', 'data1');
        await storage.write('key2', 'data2');

        await storage.clear();

        final result = await storage.count();
        expect(result, 0);
      });

      test('should not count non-cache keys', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('non_cache_key', 'should_not_count');

        await storage.write('cache_key', 'data');

        final result = await storage.count();
        expect(result, 1);
      });
    });

    group('singleton instance', () {
      test('should return the same instance', () {
        final a = SharedPrefsCacheStorage.instance;
        final b = SharedPrefsCacheStorage.instance;
        expect(identical(a, b), isTrue);
      });
    });

    group('edge cases', () {
      test('should handle empty string data', () async {
        await storage.write('empty_data_key', '');

        final entry = await storage.read('empty_data_key');
        expect(entry, isNotNull);
        expect(entry!.data, '');
      });

      test('should handle special characters in key', () async {
        await storage.write('key/with/slashes', 'data');

        final entry = await storage.read('key/with/slashes');
        expect(entry, isNotNull);
        expect(entry!.data, 'data');
      });

      test('should handle JSON string data', () async {
        final jsonData = jsonEncode({
          'nested': {
            'value': 42,
            'list': [1, 2, 3],
          },
        });
        await storage.write('json_key', jsonData);

        final entry = await storage.read('json_key');
        expect(entry, isNotNull);
        expect(entry!.data, jsonData);
      });
    });
  });
}
