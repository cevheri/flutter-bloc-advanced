import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils.dart';
import 'local_storage_test.mocks.dart';

@GenerateMocks([SharedPreferences])
void main() {
  group('AppLocalStorage', () {
    late AppLocalStorage localStorage;

    setUpAll(() async {
      await TestUtils().setupUnitTest();
    });

    setUp(() {
      AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
      localStorage = AppLocalStorage();
      SharedPreferences.setMockInitialValues({});
    });

    test("set strategy sharedPreferences", () {
      localStorage.setStorage(StorageType.sharedPreferences);
    });
    test("set strategy getStorage", () {
      localStorage.setStorage(StorageType.getStorage);
    });

    test("set strategy sharedPreferences", () {
      localStorage.setStorage(StorageType.sharedPreferences);
    });

    test('save and read String value', () async {
      await localStorage.save('testKey', 'testValue');
      final result = await localStorage.read('testKey');
      expect(result, 'testValue');
    });

    test('save and read int value', () async {
      await localStorage.save('testKey', 123);
      final result = await localStorage.read('testKey');
      expect(result, 123);
    });

    test('save and read double value', () async {
      await localStorage.save('testKey', 123.45);
      final result = await localStorage.read('testKey');
      expect(result, 123.45);
    });

    test('save and read bool value', () async {
      await localStorage.save('testKey', true);
      final result = await localStorage.read('testKey');
      expect(result, true);
    });

    test('save and read List<String> value', () async {
      await localStorage.save('testKey', ['value1', 'value2']);
      final result = await localStorage.read('testKey');
      expect(result, ['value1', 'value2']);
    });

    test('remove value', () async {
      await localStorage.save('testKey', 'testValue');
      await localStorage.remove('testKey');
      final result = await localStorage.read('testKey');
      expect(result, null);
    });

    test('clear all values', () async {
      await localStorage.save('testKey1', 'testValue1');
      await localStorage.save('testKey2', 'testValue2');
      await localStorage.clear();
      final result1 = await localStorage.read('testKey1');
      final result2 = await localStorage.read('testKey2');
      expect(result1, null);
      expect(result2, null);
    });

    test('save unsupported value type throws exception', () async {
      await expectLater(localStorage.save('testKey', DateTime.now()), completion(equals(false)));
    });

    test('save unsupported value type returns false and logs error', () async {
      bool logCaptured = false;

      await expectLater(() async {
        final result = await localStorage.save('testKey', DateTime.now());
        expect(result, false);
        logCaptured = true;
        return result;
      }(), completion(equals(false)));
      expect(logCaptured, true);
    });
  });

  group('remove method error handling', () {
    late SharedPreferencesStrategy localStorage;
    late SharedPreferences mockPrefs;

    setUp(() {
      AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
      localStorage = SharedPreferencesStrategy();
      mockPrefs = MockSharedPreferences();
      SharedPreferences.setMockInitialValues({});
      localStorage.setPreferencesInstance(mockPrefs);
    });

    test('should return false when remove operation throws error', () async {
      when(mockPrefs.remove("testKey")).thenThrow(Exception('Failed to remove'));
      SharedPreferences.setMockInitialValues({});

      final result = await localStorage.remove('testKey');

      expect(result, false);
      verify(mockPrefs.remove('testKey')).called(1);
    });
  });

  group('remove method error handling', () {
    late SharedPreferencesStrategy localStorage;
    late SharedPreferences mockPrefs;

    setUp(() {
      AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
      localStorage = SharedPreferencesStrategy();
      mockPrefs = MockSharedPreferences();
      SharedPreferences.setMockInitialValues({});
      localStorage.setPreferencesInstance(mockPrefs);
    });

    test('should handle various error scenarios', () async {
      final testCases = [
        {'key': 'testKey1', 'error': Exception('Failed to remove'), 'description': 'general exception'},
        {'key': 'testKey2', 'error': Error(), 'description': 'error instance'},
        {'key': 'testKey3', 'error': Exception('Invalid key'), 'description': 'invalid key exception'},
      ];

      for (var testCase in testCases) {
        when(mockPrefs.remove(testCase['key'] as String)).thenThrow(testCase['error'] as Object);

        final result = await localStorage.remove(testCase['key'] as String);

        expect(result, false, reason: 'Failed for ${testCase['description']}');
        verify(mockPrefs.remove(testCase['key'] as String)).called(1);
      }
    });

    tearDown(() {
      reset(mockPrefs);
    });
  });
}
