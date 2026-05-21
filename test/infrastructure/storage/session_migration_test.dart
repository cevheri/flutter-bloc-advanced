import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_utils.dart';

class _MemorySecureStorage implements ISecureStorage {
  _MemorySecureStorage({this.failOnWrite = false, this.silentlyDropWrites = false});
  final Map<String, String> _store = {};
  final bool failOnWrite;

  /// Simulates a misbehaving adapter that returns successfully but never
  /// persists the value — exercises the read-after-write verification path.
  final bool silentlyDropWrites;
  @override
  Future<String?> read(String key) async => _store[key];
  @override
  Future<void> write(String key, String value) async {
    if (failOnWrite) throw StateError('boom');
    if (silentlyDropWrites) return;
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

  group('runSessionMigration', () {
    test('migrates jwtToken and refreshToken from local to secure', () async {
      await local.save('jwtToken', 'JWT_VALUE');
      await local.save('refreshToken', 'REFRESH_VALUE');

      await runSessionMigration(secureStorage: secure, localStorage: local);

      expect(await secure.read('jwtToken'), 'JWT_VALUE');
      expect(await secure.read('refreshToken'), 'REFRESH_VALUE');
      expect(await local.read('jwtToken'), isNull);
      expect(await local.read('refreshToken'), isNull);
    });

    test('preserves the secure value across runs (idempotent for secure side)', () async {
      // Secure-storage value is never overwritten once migrated. The
      // "cleans up lingering plaintext" test below covers what happens
      // to a stale SharedPreferences copy in this same scenario —
      // they're two halves of the same idempotency guarantee.
      await secure.write('jwtToken', 'ALREADY_MIGRATED');

      await runSessionMigration(secureStorage: secure, localStorage: local);

      expect(await secure.read('jwtToken'), 'ALREADY_MIGRATED');
      expect(await local.read('jwtToken'), isNull);
    });

    test('is a no-op when there is nothing to migrate', () async {
      await runSessionMigration(secureStorage: secure, localStorage: local);

      expect(await secure.read('jwtToken'), isNull);
      expect(await secure.read('refreshToken'), isNull);
    });

    test('does not throw when secure write fails', () async {
      final flaky = _MemorySecureStorage(failOnWrite: true);
      await local.save('jwtToken', 'JWT_VALUE');

      await runSessionMigration(secureStorage: flaky, localStorage: local);

      expect(await local.read('jwtToken'), 'JWT_VALUE');
    });

    test('retains legacy key when secure write silently fails to persist', () async {
      // Simulates a misbehaving adapter that returns without throwing but
      // drops the write. The read-after-write check should catch this and
      // leave the legacy SharedPreferences value intact so the user is not
      // logged out.
      final silent = _MemorySecureStorage(silentlyDropWrites: true);
      await local.save('jwtToken', 'JWT_VALUE');

      await runSessionMigration(secureStorage: silent, localStorage: local);

      expect(await silent.read('jwtToken'), isNull);
      expect(await local.read('jwtToken'), 'JWT_VALUE');
    });

    test('cleans up lingering plaintext when secure already has the value', () async {
      // Simulates an interrupted prior migration: token is in secure
      // storage, but a plaintext copy still lingers in SharedPreferences.
      // The migration must clean up the leftover even though early-return
      // would otherwise skip it — defeating the migration's whole point.
      await secure.write('jwtToken', 'ALREADY_MIGRATED');
      await local.save('jwtToken', 'STALE_PLAINTEXT');

      await runSessionMigration(secureStorage: secure, localStorage: local);

      expect(await secure.read('jwtToken'), 'ALREADY_MIGRATED', reason: 'secure value untouched');
      expect(await local.read('jwtToken'), isNull, reason: 'lingering plaintext cleaned up');
    });

    test('warns when SharedPreferences refuses to remove the legacy key', () async {
      // localStorage.remove returns false → secure side already has the
      // migrated value, but the plaintext leftover in SharedPreferences
      // is exactly what the migration is meant to eliminate. We must
      // surface this rather than log a misleading success.
      final flakyLocal = _RefuseRemoveLocalStorage(real: local, refuseKey: 'jwtToken');
      final secure = _MemorySecureStorage();
      await local.save('jwtToken', 'JWT_VALUE');

      await runSessionMigration(secureStorage: secure, localStorage: flakyLocal);

      expect(await secure.read('jwtToken'), 'JWT_VALUE', reason: 'secure write succeeded');
      // The legacy key is still there because remove returned false;
      // operators see a warn-level log so the leftover can be cleaned up.
      expect(await local.read('jwtToken'), 'JWT_VALUE');
    });
  });
}

/// AppLocalStorage decorator that refuses to remove a specific key
/// (returns false without throwing). Mirrors a SharedPreferences
/// platform refusal.
class _RefuseRemoveLocalStorage implements AppLocalStorage {
  _RefuseRemoveLocalStorage({required AppLocalStorage real, required this.refuseKey}) : _real = real;
  final AppLocalStorage _real;
  final String refuseKey;
  @override
  Future<bool> save(String key, dynamic value) => _real.save(key, value);
  @override
  Future<dynamic> read(String key) => _real.read(key);
  @override
  Future<bool> remove(String key) async => key == refuseKey ? false : _real.remove(key);
  @override
  Future<void> clear() => _real.clear();
  @override
  void setPreferencesInstance(SharedPreferences prefs) => _real.setPreferencesInstance(prefs);
}
