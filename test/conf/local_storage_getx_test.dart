import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../test_utils.dart';
import 'local_storage_getx_test.mocks.dart';

@GenerateMocks([GetStorage])
void main() {
  group('AppLocalStorageGetX Tests', () {
    late GetStorageStrategy storage;
    late MockGetStorage mockPrefs;

    setUpAll(() async {
      await TestUtils().setupUnitTest();
    });

    setUp(() {
      // Given
      mockPrefs = MockGetStorage();
      storage = GetStorageStrategy();
      storage.setPreferencesInstance(mockPrefs);
    });

    test('save method should return true when successful', () async {
      // Given
      const key = 'test_key';
      const value = 'test_value';
      when(mockPrefs.write(key, value)).thenAnswer((_) => Future<void>.value());

      when(mockPrefs.remove(key)).thenAnswer((_) => Future<void>.value());

      when(mockPrefs.erase()).thenAnswer((_) => Future<void>.value());

      // When
      final result = await storage.save(key, value);

      // Then - Success
      expect(result, true);
      verify(mockPrefs.write(key, value)).called(1);
    });

    test('save method should return false when error occurs', () async {
      // Given
      const key = 'test_key';
      const value = 'test_value';
      when(mockPrefs.write(key, value)).thenThrow(Exception('Error'));

      // When
      final result = await storage.save(key, value);

      // Then - Failure
      expect(result, false);
      verify(mockPrefs.write(key, value)).called(1);
    });

    test('read method should return correct value', () async {
      // Given
      const key = 'test_key';
      const expectedValue = 'test_value';
      when(mockPrefs.read(key)).thenReturn(expectedValue);

      // When
      final result = await storage.read(key);

      // Then - Success
      expect(result, expectedValue);
      verify(mockPrefs.read(key)).called(1);
    });

    test('remove method should return true when successful', () async {
      // Given
      const key = 'test_key';
      when(mockPrefs.remove(key)).thenAnswer((_) async {});

      // When
      final result = await storage.remove(key);

      // Then - Success
      expect(result, true);
      verify(mockPrefs.remove(key)).called(1);
    });

    test('remove method should return true when fail', () async {
      // Given
      const key = 'test_key';
      when(mockPrefs.remove(key)).thenThrow(Exception('Error'));

      // When
      final result = await storage.remove(key);

      // Then - Failure
      expect(result, false);
      verify(mockPrefs.remove(key)).called(1);
    });

    test('clear method should call GetStorage.erase()', () async {
      // Given
      when(mockPrefs.erase()).thenAnswer((_) async {});

      // When
      await storage.clear();

      // Then - Success
      verify(mockPrefs.erase()).called(1);
    });
  });
}
