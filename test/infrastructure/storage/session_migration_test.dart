import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_utils.dart';

class _MemorySecureStorage implements ISecureStorage {
  _MemorySecureStorage({this.failOnWrite = false});
  final Map<String, String> _store = {};
  final bool failOnWrite;
  @override
  Future<String?> read(String key) async => _store[key];
  @override
  Future<void> write(String key, String value) async {
    if (failOnWrite) throw StateError('boom');
    _store[key] = value;
  }

  @override
  Future<void> delete(String key) async => _store.remove(key);
  @override
  Future<void> deleteAll() async => _store.clear();
}

void main() {
  late AppLocalStorage local;
  late _MemorySecureStorage secure;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    local = AppLocalStorage();
    local.setPreferencesInstance(await SharedPreferences.getInstance());
    secure = _MemorySecureStorage();
  });

  tearDown(() async => TestUtils().tearDownUnitTest());

  group('SessionMigration.run', () {
    test('migrates jwtToken and refreshToken from local to secure', () async {
      await local.save('jwtToken', 'JWT_VALUE');
      await local.save('refreshToken', 'REFRESH_VALUE');

      await SessionMigration.run(secureStorage: secure, localStorage: local);

      expect(await secure.read('jwtToken'), 'JWT_VALUE');
      expect(await secure.read('refreshToken'), 'REFRESH_VALUE');
      expect(await local.read('jwtToken'), isNull);
      expect(await local.read('refreshToken'), isNull);
    });

    test('is a no-op when secure storage already has the value (idempotent)', () async {
      await secure.write('jwtToken', 'ALREADY_MIGRATED');
      await local.save('jwtToken', 'STALE');

      await SessionMigration.run(secureStorage: secure, localStorage: local);

      expect(await secure.read('jwtToken'), 'ALREADY_MIGRATED');
      expect(await local.read('jwtToken'), 'STALE');
    });

    test('is a no-op when there is nothing to migrate', () async {
      await SessionMigration.run(secureStorage: secure, localStorage: local);

      expect(await secure.read('jwtToken'), isNull);
      expect(await secure.read('refreshToken'), isNull);
    });

    test('does not throw when secure write fails', () async {
      final flaky = _MemorySecureStorage(failOnWrite: true);
      await local.save('jwtToken', 'JWT_VALUE');

      await SessionMigration.run(secureStorage: flaky, localStorage: local);

      expect(await local.read('jwtToken'), 'JWT_VALUE');
    });
  });
}
